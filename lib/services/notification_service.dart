import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static const _pushCountKey = 'daily_push_count';
  static const _pushDateKey = 'daily_push_date';
  static const int _maxDailyPush = 3;
  bool _initialized = false;

  // ─── Init ────────────────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final appId = AppConstants.oneSignalAppId;
    if (appId.isEmpty || appId == 'YOUR_ONESIGNAL_APP_ID') {
      debugPrint('[NotificationService] skipped — no ONESIGNAL_APP_ID');
      return;
    }
    await OneSignal.initialize(appId);
    _initialized = true;
    debugPrint('[NotificationService] initialized');
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    final accepted = await OneSignal.Notifications.requestPermission(true);
    debugPrint('[NotificationService] permission: $accepted');
    if (accepted) {
      await OneSignal.User.pushSubscription.optIn();
    }
    return accepted;
  }

  // ─── User binding ────────────────────────────────────────────────────────────────────

  void setUserId(String userId) {
    if (!_initialized) return;
    OneSignal.login(userId);
    debugPrint('[NotificationService] login $userId');
  }

  void logout() {
    if (!_initialized) return;
    OneSignal.logout();
    debugPrint('[NotificationService] logout');
  }

  // ─── Custom tags (server-side segmentation for notify_users) ──────────────────────

  /// Called after every check-in to keep OneSignal tags fresh.
  void setCheckinTags({
    required int daysSober,
    required int moodScore,
    required int cravingScore,
    required int streak,
    required bool isPro,
  }) {
    if (!_initialized) return;
    final tags = {
      'days_sober': daysSober.toString(),
      'mood_score': moodScore.toString(),
      'craving_score': cravingScore.toString(),
      'streak': streak.toString(),
      'is_pro': isPro ? '1' : '0',
      'last_checkin': DateTime.now().toIso8601String().split('T')[0],
    };
    tags.forEach((k, v) => OneSignal.User.addTagWithKey(k, v));
    debugPrint('[NotificationService] tags set: $tags');
  }

  /// Generic tag setter (used at login, onboarding, profile update).
  void setUserData(Map<String, dynamic> data) {
    if (!_initialized) return;
    data.forEach((key, value) {
      OneSignal.User.addTagWithKey(key, value.toString());
    });
  }

  // ─── Check-in reminder ───────────────────────────────────────────────────────────────────

  /// Schedules daily check-in reminder at [hour] (0–23, local time).
  /// Sets OneSignal tag `checkin_reminder_hour` — Edge Function notify_users
  /// reads this tag and sends push at the correct time.
  void scheduleCheckinReminder(int hour) {
    if (!_initialized) return;
    OneSignal.User.addTagWithKey('checkin_reminder_hour', hour.toString());
    debugPrint('[NotificationService] reminder scheduled at $hour:00');
  }

  void cancelCheckinReminder() {
    if (!_initialized) return;
    OneSignal.User.removeTag('checkin_reminder_hour');
    debugPrint('[NotificationService] reminder cancelled');
  }

  // ─── Rate limit: max 3 client-triggered pushes / day ─────────────────────────────

  Future<bool> canSendPush() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final storedDate = prefs.getString(_pushDateKey) ?? '';
    if (storedDate != today) {
      await prefs.setString(_pushDateKey, today);
      await prefs.setInt(_pushCountKey, 0);
    }
    final count = prefs.getInt(_pushCountKey) ?? 0;
    return count < _maxDailyPush;
  }

  Future<void> _incrementPushCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_pushCountKey) ?? 0;
    await prefs.setInt(_pushCountKey, count + 1);
  }

  // ─── 11 notification types (server-side via notify_users Edge Function) ───────────
  //
  // Type 1:  checkin_reminder   — daily at checkin_reminder_hour tag
  // Type 2:  milestone_reached  — triggered by milestone INSERT
  // Type 3:  three_am_support   — when 3AM post is resolved by community
  // Type 4:  letter_delivered   — when future letter deliver_at <= today
  // Type 5:  streak_at_risk     — no check-in for 22h (streak > 0)
  // Type 6:  streak_lost        — streak broken, compassionate message
  // Type 7:  community_reply    — when post gets first like
  // Type 8:  naomi_response     — when naomi-feedback Edge Function replies
  // Type 9:  weekly_reflection  — every Sunday at 18:00
  // Type 10: craving_surf_nudge — when craving_score >= 8 in last check-in
  // Type 11: ab_test_variant    — sent once per user for A/B experiment

  Future<void> sendLocalPush({
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    if (!await canSendPush()) {
      debugPrint('[NotificationService] rate limit reached (max $_maxDailyPush/day)');
      return;
    }
    await _incrementPushCount();
    // OneSignal SDK v5 does not support local push directly.
    // Delivery is handled by In-App Messages or Edge Function.
    debugPrint('[NotificationService] sendLocalPush: $title — $body');
  }
}
