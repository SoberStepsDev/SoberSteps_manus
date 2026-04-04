import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// MirrorMindService — silent background data capture for future MirrorMind AI (Q3 2026).
/// No UI. Called from existing providers via hooks.
/// Data stored in `mirror_entries` table (RLS: user-own only).
/// Offline queue: pending events stored in SharedPreferences, synced on next online session.
class MirrorMindService {
  MirrorMindService._();
  static final MirrorMindService instance = MirrorMindService._();
  factory MirrorMindService() => instance;

  final _supabase = Supabase.instance.client;
  static const _queueKey = 'mirror_pending_queue';

  bool get _isEnabled => _supabase.auth.currentUser != null;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Alias for capture() — semantic name for direct moment logging.
  Future<void> logMoment({
    required String eventType,
    required Map<String, dynamic> data,
  }) => capture(eventType: eventType, data: data);

  /// Capture a single event silently. Queues offline if no auth/network.
  Future<void> capture({
    required String eventType,
    required Map<String, dynamic> data,
  }) async {
    if (!AppConstants.mirrorCaptureEvents.contains(eventType)) return;
    if (!_isEnabled) {
      await _enqueue(eventType, data);
      return;
    }
    try {
      await _supabase.from('mirror_entries').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'content': _buildContent(eventType, data),
        'entry_type': _mapEventToEntryType(eventType),
        'energy_level': data['mood'] as int? ?? data['energy'] as int?,
        'tags': [eventType],
      });
    } catch (_) {
      // Network error — queue for later sync
      await _enqueue(eventType, data);
    }
  }

  /// Sync pending offline queue to Supabase. Call on app resume or auth change.
  Future<void> syncPending() async {
    if (!_isEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_queueKey) ?? [];
    if (raw.isEmpty) return;

    final toSync = raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    final failed = <String>[];

    for (final item in toSync) {
      try {
        await _supabase.from('mirror_entries').insert({
          'user_id': _supabase.auth.currentUser!.id,
          'content': _buildContent(item['event_type'] as String, item['data'] as Map<String, dynamic>),
          'entry_type': _mapEventToEntryType(item['event_type'] as String),
          'energy_level': (item['data'] as Map<String, dynamic>)['mood'] as int?,
          'tags': [item['event_type']],
          'created_at': item['queued_at'] as String,
        });
      } catch (_) {
        failed.add(jsonEncode(item));
      }
    }

    await prefs.setStringList(_queueKey, failed);
  }

  /// Get recent mirror entries for MirrorMind preview (max 20).
  Future<List<Map<String, dynamic>>> getRecentEntries({int limit = 20}) async {
    if (!_isEnabled) return [];
    try {
      final res = await _supabase
          .from('mirror_entries')
          .select('id,entry_type,content,energy_level,tags,created_at')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  // ─── Hooks (called from providers) ────────────────────────────────────────

  /// Hook: after saveCheckin — fires when craving >= 7
  Future<void> onCheckin({required int mood, required int craving, List<String>? triggers}) async {
    if (craving >= 7) {
      await capture(eventType: 'checkin_craving', data: {
        'craving_level': craving,
        'mood': mood,
        'triggers': triggers?.join(',') ?? '',
      });
    }
    await capture(eventType: 'checkin_mood', data: {'mood': mood, 'craving': craving});
  }

  /// Hook: after 3AM Wall resolved
  Future<void> onThreeAmResolved({String? outcomeText}) async {
    await capture(eventType: 'three_am_trigger', data: {
      'trigger_type': 'resolved',
      'outcome': outcomeText ?? '',
      'hour': DateTime.now().hour,
    });
  }

  /// Hook: after milestone achieved
  Future<void> onMilestone({required int days}) async {
    await capture(eventType: 'milestone_reaction', data: {
      'days': days,
      'reaction': 'achieved',
    });
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  Future<void> _enqueue(String eventType, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_queueKey) ?? [];
      // Max 100 items in queue
      if (queue.length >= 100) queue.removeAt(0);
      queue.add(jsonEncode({
        'event_type': eventType,
        'data': data,
        'queued_at': DateTime.now().toIso8601String(),
      }));
      await prefs.setStringList(_queueKey, queue);
    } catch (_) {}
  }

  String _buildContent(String eventType, Map<String, dynamic> data) {
    switch (eventType) {
      case 'checkin_mood':
        return 'mood:${data['mood']},craving:${data['craving']}';
      case 'checkin_craving':
        return 'craving:${data['craving_level']},triggers:${data['triggers']}';
      case 'three_am_trigger':
        return 'trigger:${data['trigger_type']},hour:${data['hour']},outcome:${data['outcome']}';
      case 'craving_surf_completed':
        return 'duration:${data['duration_seconds']},outcome:${data['outcome']}';
      case 'journal_note_length':
        return 'length:${data['length']},has_note:${data['has_note']}';
      case 'milestone_reaction':
        return 'days:${data['days']},reaction:${data['reaction']}';
      case 'naomi_question_type':
        return 'type:${data['question_type']}';
      default:
        return data.toString();
    }
  }

  String _mapEventToEntryType(String eventType) {
    const map = {
      'checkin_mood': 'moment',
      'checkin_craving': 'pattern',
      'three_am_trigger': 'pattern',
      'craving_surf_completed': 'moment',
      'journal_note_length': 'pattern',
      'milestone_reaction': 'sync',
      'naomi_question_type': 'intuition',
    };
    return map[eventType] ?? 'moment';
  }
}
