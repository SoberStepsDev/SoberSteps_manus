import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

/// MarketingBridge — connects in-app events to marketing/analytics pipeline
class MarketingBridge {
  static final MarketingBridge _instance = MarketingBridge._();
  factory MarketingBridge() => _instance;
  MarketingBridge._();

  final _analytics = AnalyticsService();

  void sendSignal(String event, [Map<String, dynamic>? data]) {
    _analytics.track('marketing_$event', data);
    debugPrint('[MarketingBridge] $event ${data ?? ''}');
  }

  void onMilestoneReached(int days, String variant) {
    sendSignal('milestone_reached', {
      'days': days,
      'variant': variant,
    });
  }

  void onReflectionSubmitted(String variant) {
    sendSignal('reflection_submitted_variant_$variant');
  }

  void onCrisisDetected() {
    sendSignal('crisis_auto_detected');
  }

  void onPremiumConverted(String productId) {
    sendSignal('premium_converted', {'product': productId});
  }

  void onReturnToSelfCompleted(String type, int day) {
    sendSignal('return_to_self_completed', {'type': type, 'day': day});
  }
}
