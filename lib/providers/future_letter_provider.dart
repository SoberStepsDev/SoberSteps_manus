import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/future_letter.dart';
import '../constants/app_constants.dart';
import '../services/analytics_service.dart';

class FutureLetterProvider extends ChangeNotifier {
  final AnalyticsService _analytics = AnalyticsService();
  List<FutureLetter> _letters = [];
  FutureLetter? _pendingDelivery;
  bool _loading = false;

  List<FutureLetter> get letters => _letters;
  FutureLetter? get pendingDelivery => _pendingDelivery;
  bool get loading => _loading;

  Future<void> loadLetters() async {
    _loading = true;
    notifyListeners();
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      final data = await client
          .from('future_letters')
          .select()
          .eq('user_id', user.id)
          .order('deliver_at');
      _letters = (data as List).map((e) => FutureLetter.fromJson(e)).toList();
      _checkDelivery();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  void _checkDelivery() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final letter in _letters) {
      if (letter.deliveredAt == null && !letter.deliverAt.isAfter(today)) {
        _pendingDelivery = letter;
        return;
      }
    }
    _pendingDelivery = null;
  }

  void clearPendingDelivery() {
    _pendingDelivery = null;
    notifyListeners();
  }

  Future<String?> createLetter(String content, DateTime deliverAt) async {
    if (AppConstants.urlRegex.hasMatch(content)) return 'Linki są niedozwolone';
    if (content.length > AppConstants.maxNoteLength) return 'List jest za długi';

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return 'Zaloguj się';

    try {
      await client.from('future_letters').insert({
        'user_id': user.id,
        'content': content,
        'deliver_at': deliverAt.toIso8601String().split('T')[0],
      });
      final daysTilDelivery = deliverAt.difference(DateTime.now()).inDays;
      _analytics.track('letter_to_future_created', {'deliver_at_days': daysTilDelivery});
      await loadLetters();
      return null;
    } catch (e) {
      await _saveToOfflineQueue(content, deliverAt);
      return 'offline';
    }
  }

  Future<void> _saveToOfflineQueue(String content, DateTime deliverAt) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('pending_letters') ?? [];
    queue.add(jsonEncode({'content': content, 'deliver_at': deliverAt.toIso8601String()}));
    await prefs.setStringList('pending_letters', queue);
  }

  Future<void> syncPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('pending_letters') ?? [];
    if (queue.isEmpty) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    final synced = <int>[];
    for (var i = 0; i < queue.length; i++) {
      try {
        final data = jsonDecode(queue[i]);
        await client.from('future_letters').insert({
          'user_id': user.id,
          'content': data['content'],
          'deliver_at': data['deliver_at'].toString().split('T')[0],
        });
        synced.add(i);
      } catch (_) {}
    }
    for (final i in synced.reversed) {
      queue.removeAt(i);
    }
    await prefs.setStringList('pending_letters', queue);
    if (synced.isNotEmpty) await loadLetters();
  }
}
