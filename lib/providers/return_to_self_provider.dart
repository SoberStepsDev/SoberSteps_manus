import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/return_to_self.dart';
import '../services/encryption_service.dart';
import '../services/marketing_bridge.dart';

class ReturnToSelfProvider extends ChangeNotifier {
  List<ReturnToSelfProgress> _progress = [];
  ReturnToSelfStreak? _streak;
  List<ReturnToSelfProgress> get progress => _progress;
  ReturnToSelfStreak? get streak => _streak;
  bool _loading = false;
  bool get loading => _loading;

  final _enc = EncryptionService();
  final _supabase = Supabase.instance.client;

  Future<void> loadProgress() async {
    _loading = true;
    notifyListeners();
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) {
        _loading = false;
        notifyListeners();
        return;
      }

      final res = await _supabase
          .from('return_to_self_progress')
          .select()
          .eq('user_id', uid)
          .order('day');
      _progress = (res as List).map((e) => ReturnToSelfProgress.fromJson(e)).toList();

      final streakRes = await _supabase
          .from('return_to_self_streak')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      _streak = streakRes != null ? ReturnToSelfStreak.fromJson(streakRes) : null;
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> completeDay(ReturnToSelfType type, int day) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    await _supabase.from('return_to_self_progress').insert({
      'id': const Uuid().v4(),
      'user_id': uid,
      'type': type.name,
      'day': day,
      'completed': true,
    });

    MarketingBridge().onReturnToSelfCompleted(type.name, day);
    await loadProgress();
  }

  Future<void> savePathEntry(String progressId, String practiceType, String reflection) async {
    final encrypted = await _enc.encrypt(reflection);
    await _supabase.from('return_to_self_path_entries').insert({
      'id': const Uuid().v4(),
      'progress_id': progressId,
      'practice_type': practiceType,
      'reflection_encrypted': encrypted,
    });
  }

  Future<void> updateStreak() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    if (_streak == null) {
      await _supabase.from('return_to_self_streak').insert({
        'id': const Uuid().v4(),
        'user_id': uid,
        'streak_days': 1,
        'last_check': DateTime.now().toIso8601String(),
      });
    } else {
      final daysSinceLast = DateTime.now().difference(_streak!.lastCheck).inDays;
      final newStreak = daysSinceLast <= 1 ? _streak!.streakDays + 1 : 1;
      await _supabase
          .from('return_to_self_streak')
          .update({
            'streak_days': newStreak,
            'last_check': DateTime.now().toIso8601String(),
          })
          .eq('user_id', uid);
    }
    await loadProgress();
  }
}
