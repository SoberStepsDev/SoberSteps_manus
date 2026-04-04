import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';
import '../services/analytics_service.dart';
import '../services/mirror_mind_service.dart';
import '../services/notification_service.dart';

class JournalProvider extends ChangeNotifier {
  final AnalyticsService _analytics = AnalyticsService();
  List<JournalEntry> _entries = [];
  bool _loading = false;
  int _consecutiveCheckins = 0;
  String _searchQuery = '';

  List<JournalEntry> get entries => _entries;
  /// Check-ins whose note matches [searchQuery] (case-insensitive); offline-friendly client filter.
  List<JournalEntry> get filteredEntries {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _entries;
    return _entries
        .where((e) => (e.note ?? '').toLowerCase().contains(q))
        .toList();
  }

  String get searchQuery => _searchQuery;

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  bool get loading => _loading;
  int get consecutiveCheckins => _consecutiveCheckins;

  /// Load last 30 entries from SharedPreferences cache (instant, no network).
  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cached_journal_entries');
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _entries = list.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList();
      _calculateConsecutive();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadEntries() async {
    _loading = true;
    notifyListeners();
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      final data = await client
          .from('journal_entries')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(100);
      _entries = (data as List).map((e) => JournalEntry.fromJson(e)).toList();
      _calculateConsecutive();
      // Persist cache for offline use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_journal_entries',
        jsonEncode(_entries.take(30).map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<String?> saveCheckin({
    required int mood,
    required int cravingLevel,
    required List<String> triggers,
    String? note,
  }) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return 'Not logged in';

    try {
      final canCheckin = await client.rpc('check_checkin_rate_limit', params: {'p_user_id': user.id});
      if (canCheckin == false) return 'Już dziś wykonałeś check-in';
    } catch (_) {}

    final entry = JournalEntry(
      id: const Uuid().v4(),
      userId: user.id,
      mood: mood,
      cravingLevel: cravingLevel,
      triggers: triggers,
      note: note,
      createdAt: DateTime.now(),
    );

    try {
      await client.from('journal_entries').insert(entry.toJson());
      _entries.insert(0, entry);
      _calculateConsecutive();
      _analytics.track('checkin_completed', {
        'mood': mood,
        'craving_level': cravingLevel,
        'has_note': note != null && note.isNotEmpty,
      });
      // MirrorMind silent capture (craving≥7 triggers pattern capture)
      MirrorMindService().onCheckin(
        mood: mood,
        craving: cravingLevel,
        triggers: triggers,
      );
      // OneSignal custom tags for server-side segmentation (notify_users)
      NotificationService().setCheckinTags(
        daysSober: 0, // SobrietyProvider owns days_sober tag
        moodScore: mood,
        cravingScore: cravingLevel,
        streak: _consecutiveCheckins,
        isPro: false, // PurchaseProvider owns is_pro tag
      );
      notifyListeners();
      return null;
    } catch (e) {
      await _saveToOfflineQueue(entry);
      return 'offline';
    }
  }

  /// Delete a check-in by ID (best-effort, no offline queue for deletes).
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    try {
      await Supabase.instance.client
          .from('journal_entries')
          .delete()
          .eq('id', id);
    } catch (_) {}
  }

  /// Update note of an existing entry.
  Future<void> updateNote(String id, String note) async {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _entries[idx] = _entries[idx].copyWith(note: note);
    notifyListeners();
    try {
      await Supabase.instance.client
          .from('journal_entries')
          .update({'note': note})
          .eq('id', id);
    } catch (_) {}
  }

  Future<void> _saveToOfflineQueue(JournalEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('pending_checkins') ?? [];
    queue.add(jsonEncode(entry.toJson()));
    await prefs.setStringList('pending_checkins', queue);
  }

  Future<void> syncPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('pending_checkins') ?? [];
    if (queue.isEmpty) return;
    final client = Supabase.instance.client;
    final synced = <int>[];
    for (var i = 0; i < queue.length; i++) {
      try {
        await client.from('journal_entries').insert(jsonDecode(queue[i]));
        synced.add(i);
      } catch (_) {}
    }
    for (final i in synced.reversed) {
      queue.removeAt(i);
    }
    await prefs.setStringList('pending_checkins', queue);
    if (synced.isNotEmpty) await loadEntries();
  }

  void _calculateConsecutive() {
    _consecutiveCheckins = 0;
    final now = DateTime.now();
    for (var i = 0; i < _entries.length; i++) {
      final date = _entries[i].createdAt;
      final daysDiff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(date.year, date.month, date.day))
          .inDays;
      if (daysDiff == i) {
        _consecutiveCheckins++;
      } else {
        break;
      }
    }
  }
}
