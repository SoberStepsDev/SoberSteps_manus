import 'package:shared_preferences/shared_preferences.dart';

class StreakProtectionService {
  StreakProtectionService._();

  static const _graceDateKey = 'streak_protection_grace_date';

  static String _monthKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month}-${d.day}';

  static Future<int> usesThisMonth(SharedPreferences prefs) async {
    return prefs.getInt('streak_protection_${_monthKey()}') ?? 0;
  }

  static Future<bool> canUse(SharedPreferences prefs, bool isPro) async {
    if (!isPro) return false;
    return (await usesThisMonth(prefs)) < 2;
  }

  static Future<void> recordUse(SharedPreferences prefs) async {
    final k = 'streak_protection_${_monthKey()}';
    final u = prefs.getInt(k) ?? 0;
    await prefs.setInt(k, u + 1);
  }

  static Future<bool> hasActiveGraceToday(SharedPreferences prefs) async {
    final stored = prefs.getString(_graceDateKey);
    return stored != null && stored == _dayKey(DateTime.now());
  }

  static Future<void> clearGrace(SharedPreferences prefs) async {
    await prefs.remove(_graceDateKey);
  }

  /// PRO only: consumes one monthly use and marks today as covered for streak (no check-in yet).
  static Future<bool> tryActivate(SharedPreferences prefs, bool isPro) async {
    if (!await canUse(prefs, isPro)) return false;
    if (await hasActiveGraceToday(prefs)) return false;
    await recordUse(prefs);
    await prefs.setString(_graceDateKey, _dayKey(DateTime.now()));
    return true;
  }
}
