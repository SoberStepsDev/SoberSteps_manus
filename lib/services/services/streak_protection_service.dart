import 'package:shared_preferences/shared_preferences.dart';

class StreakProtectionService {
  StreakProtectionService._();

  static String _monthKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

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
}
