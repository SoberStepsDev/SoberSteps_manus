import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';


class SobrietyProvider extends ChangeNotifier {
  int _daysSober = 0;
  int _hoursSober = 0;
  DateTime? _sobrietyStartDate;
  int? _pendingMilestone;

  int get daysSober => _daysSober;
  int get hoursSober => _hoursSober;
  DateTime? get sobrietyStartDate => _sobrietyStartDate;
  int? get pendingMilestone => _pendingMilestone;

  void clearPendingMilestone() {
    _pendingMilestone = null;
  }

  int? get nextMilestone {
    for (final m in AppConstants.milestoneDays) {
      if (m > _daysSober) return m;
    }
    return null;
  }

  int get daysToNextMilestone => (nextMilestone ?? _daysSober) - _daysSober;

  double get progressToNextMilestone {
    final next = nextMilestone;
    if (next == null) return 1.0;
    final prevIdx = AppConstants.milestoneDays.indexOf(next) - 1;
    final prev = prevIdx >= 0 ? AppConstants.milestoneDays[prevIdx] : 0;
    final range = next - prev;
    if (range == 0) return 1.0;
    return ((_daysSober - prev) / range).clamp(0.0, 1.0);
  }

  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('sobriety_start_date');
    if (dateStr != null) {
      _sobrietyStartDate = DateTime.parse(dateStr);
      _recalculate();
      notifyListeners();
    }
  }

  Future<void> loadFromSupabase() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      final result = await client.rpc('get_days_sober', params: {'p_user_id': user.id});
      if (result != null) {
        _daysSober = result as int;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('cached_days_sober', _daysSober);
        _checkMilestone();
        notifyListeners();
      }
    } catch (_) {
      await loadFromLocal();
    }
  }

  Future<void> setSobrietyStartDate(DateTime date) async {
    _sobrietyStartDate = date;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sobriety_start_date', date.toIso8601String().split('T')[0]);
    _recalculate();
    notifyListeners();
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        await client.from('profiles').update({
          'sobriety_start_date': date.toIso8601String().split('T')[0],
        }).eq('id', user.id);
      }
    } catch (_) {}
  }

  Future<void> resetSobrietyDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_days_sober');
    await setSobrietyStartDate(DateTime.now());
  }

  void refresh() {
    _recalculate();
    notifyListeners();
  }

  void _recalculate() {
    if (_sobrietyStartDate == null) return;
    final now = DateTime.now();
    final diff = now.difference(_sobrietyStartDate!);
    _daysSober = diff.inDays;
    _hoursSober = diff.inHours % 24;
    _checkMilestone();
  }

  void _checkMilestone() {
    if (AppConstants.milestoneDays.contains(_daysSober)) {
      _pendingMilestone = _daysSober;
    }
  }
}
