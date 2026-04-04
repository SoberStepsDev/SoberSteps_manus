import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';


class SobrietyProvider extends ChangeNotifier {
  int _daysSober = 0;
  int _hoursSober = 0;
  int _streakDays = 0;
  DateTime? _sobrietyStartDate;
  int? _pendingMilestone;
  bool _loading = false;

  int get daysSober => _daysSober;
  int get hoursSober => _hoursSober;
  int get streakDays => _streakDays;
  DateTime? get sobrietyStartDate => _sobrietyStartDate;
  int? get pendingMilestone => _pendingMilestone;
  bool get loading => _loading;

  void clearPendingMilestone() {
    _pendingMilestone = null;
    notifyListeners();
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
    final cachedDays = prefs.getInt('cached_days_sober');
    _streakDays = prefs.getInt('cached_streak_days') ?? 0;
    if (dateStr != null) {
      _sobrietyStartDate = DateTime.parse(dateStr);
      _recalculate();
    } else if (cachedDays != null) {
      _daysSober = cachedDays;
    }
    notifyListeners();
  }

  Future<void> loadFromSupabase() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    _loading = true;
    notifyListeners();
    try {
      final days = await client.rpc('get_days_sober', params: {'p_user_id': user.id}) as int?;
      if (days != null) {
        _daysSober = days;
        // Fetch start date for hour-level precision
        final row = await client
            .from('profiles')
            .select('sobriety_start_date')
            .eq('id', user.id)
            .maybeSingle();
        if (row != null && row['sobriety_start_date'] != null) {
          _sobrietyStartDate = DateTime.parse(row['sobriety_start_date'] as String);
          _recalculate();
        }
        await _loadStreak(client, user.id);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('cached_days_sober', _daysSober);
        if (_sobrietyStartDate != null) {
          await prefs.setString('sobriety_start_date', _sobrietyStartDate!.toIso8601String());
        }
        _checkMilestone();
      }
    } catch (_) {
      // Offline: keep local values
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadStreak(SupabaseClient client, String userId) async {
    try {
      final rows = await client
          .from('journal_entries')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(60);
      final checkinDays = <String>{};
      for (final r in (rows as List)) {
        final dt = DateTime.parse(r['created_at'] as String).toLocal();
        checkinDays.add('${dt.year}-${dt.month}-${dt.day}');
      }
      int streak = 0;
      var day = DateTime.now();
      while (checkinDays.contains('${day.year}-${day.month}-${day.day}')) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      }
      _streakDays = streak;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_streak_days', streak);
    } catch (_) {}
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
    await prefs.remove('cached_streak_days');
    _streakDays = 0;
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
    if (AppConstants.milestoneDays.contains(_daysSober) &&
        _pendingMilestone != _daysSober) {
      _pendingMilestone = _daysSober;
    }
  }
}
