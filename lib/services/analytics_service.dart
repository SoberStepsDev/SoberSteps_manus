import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  void track(String event, [Map<String, dynamic>? properties]) {
    debugPrint('[Analytics] $event ${properties ?? ''}');
  }

  void setUserId(String userId) {
    debugPrint('[Analytics] setUserId $userId');
  }
}
