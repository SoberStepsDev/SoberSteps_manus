import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  Future<void> init() async {
    final appId = AppConstants.oneSignalAppId;
    if (appId.isEmpty || appId == 'YOUR_ONESIGNAL_APP_ID') {
      debugPrint('[NotificationService] skipped — no ONESIGNAL_APP_ID');
      return;
    }
    OneSignal.initialize(appId);
    // Nie prosimy o zgodę przy starcie — robimy to przy onboardingu
    debugPrint('[NotificationService] initialized');
  }

  Future<bool> requestPermission() async {
    final appId = AppConstants.oneSignalAppId;
    if (appId.isEmpty || appId == 'YOUR_ONESIGNAL_APP_ID') return false;
    final accepted = await OneSignal.Notifications.requestPermission(true);
    debugPrint('[NotificationService] permission: $accepted');
    return accepted;
  }

  void setUserId(String userId) {
    OneSignal.login(userId);
    debugPrint('[NotificationService] login $userId');
  }

  void setUserData(Map<String, dynamic> data) {
    data.forEach((key, value) {
      OneSignal.User.addTagWithKey(key, value.toString());
    });
  }

  void logout() {
    OneSignal.logout();
    debugPrint('[NotificationService] logout');
  }
}
