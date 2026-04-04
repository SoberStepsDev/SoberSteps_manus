import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// MirrorMindService — silent background data capture for future MirrorMind AI.
/// No UI. Called from existing providers via hooks.
/// Data stored in `mirror_entries` table (RLS: user-own only).
class MirrorMindService {
  MirrorMindService._();
  static final MirrorMindService instance = MirrorMindService._();

  final _supabase = Supabase.instance.client;

  bool get _isEnabled =>
      _supabase.auth.currentUser != null;

  /// Capture a single event silently. Never throws — fire and forget.
  Future<void> capture({
    required String eventType,
    required Map<String, dynamic> data,
  }) async {
    if (!_isEnabled) return;
    if (!AppConstants.mirrorCaptureEvents.contains(eventType)) return;
    try {
      await _supabase.from('mirror_entries').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'content': _buildContent(eventType, data),
        'entry_type': _mapEventToEntryType(eventType),
        'energy_level': data['mood'] as int? ?? data['energy'] as int?,
        'tags': [eventType],
      });
    } catch (_) {
      // Silent — never surface to user
    }
  }

  String _buildContent(String eventType, Map<String, dynamic> data) {
    switch (eventType) {
      case 'checkin_mood':
        return 'mood:${data['mood']},craving:${data['craving']}';
      case 'checkin_craving':
        return 'craving:${data['craving_level']},triggers:${data['triggers']}';
      case 'three_am_trigger':
        return 'trigger:${data['trigger_type']},hour:${DateTime.now().hour}';
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
