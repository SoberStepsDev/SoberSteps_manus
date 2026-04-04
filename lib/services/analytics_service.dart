import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin analytics wrapper.
/// In development: prints to console.
/// In production: swap debugPrint calls for Firebase Analytics / Amplitude SDK.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  String? _userId;

  // ─── Event constants ──────────────────────────────────────────────────────────────────────────────
  static const eOnboardingStart = 'onboarding_start';
  static const eOnboardingStepComplete = 'onboarding_step_complete';
  static const eOnboardingComplete = 'onboarding_complete';
  static const eEmailGateSubmitted = 'email_gate_submitted';
  static const eReturnToSelfOpened = 'return_to_self_opened';
  static const eReturnToSelfTrackSelected = 'return_to_self_track_selected';
  static const eSignUp = 'sign_up';
  static const eSignIn = 'sign_in';
  static const eSignOut = 'sign_out';
  static const ePasswordReset = 'password_reset_requested';
  static const eMagicLinkSent = 'magic_link_sent';
  static const eGoogleSignIn = 'google_sign_in';
  static const eAppleSignIn = 'apple_sign_in';
  static const eEmailPasswordSignUp = 'email_password_signup';
  static const eEmailPasswordSignIn = 'email_password_signin';
  static const eCheckinCompleted = 'checkin_completed';
  static const eCheckinSkipped = 'checkin_skipped';
  static const eSelfCompassionFilterShown = 'self_compassion_filter_shown';
  static const eSelfCompassionFilterProceeded = 'self_compassion_filter_proceeded';
  static const eMilestoneCelebrate = 'milestone_celebrate';
  static const eMilestoneShare = 'milestone_share';
  static const eMilestoneUpsellShown = 'milestone_upsell_shown';
  static const ePaywallView = 'paywall_view';
  static const ePurchaseSuccess = 'purchase_success';
  static const ePurchaseRestore = 'purchase_restore';
  static const ePurchaseFailed = 'purchase_failed';
  static const eTrialStarted = 'trial_started';
  static const eCommunityPostCreated = 'community_post_created';
  static const eCommunityPostFlagged = 'community_post_flagged';
  static const eCommunityPostLiked = 'community_post_liked';
  static const eThreeAmWallPosted = 'three_am_wall_posted';
  static const eThreeAmWallResolved = 'three_am_wall_resolved';
  static const eCravingSurfStarted = 'craving_surf_started';
  static const eCravingSurfCompleted = 'craving_surf_completed';
  static const eCravingSurfAbandoned = 'craving_surf_abandoned';
  static const eSoundscapePreviewStarted = 'soundscape_preview_started';
  static const eLetterCreated = 'letter_to_future_created';
  static const eLetterDelivered = 'letter_delivered';
  static const eLetterDeleted = 'letter_deleted';
  static const eNaomiOpened = 'naomi_opened';
  static const eNaomiMessageSent = 'naomi_message_sent';
  static const eNaomiResponseReceived = 'naomi_response_received';
  static const eSelfCompassionOpened = 'self_compassion_opened';
  static const eInnerCriticLogged = 'inner_critic_logged';
  static const eExperimentStarted = 'experiment_started';
  static const eExperimentCompleted = 'experiment_completed';
  static const eXMarkerChecked = 'x_marker_checked';
  static const eMirrorMindCardTapped = 'mirror_mind_card_tapped';
  static const eAbVariant = 'ab_variant';
  static const eCrashLogOpened = 'crash_log_opened';
  static const eCrashLogSaved = 'crash_log_saved';
  static const eWallOfStrengthOpened = 'wall_of_strength_opened';
  static const eProfileOpened = 'profile_opened';

  // ─── Core methods ──────────────────────────────────────────────────────────────────────────────

  void setUserId(String userId) {
    _userId = userId;
    debugPrint('[Analytics] setUserId $userId');
    // TODO(launch): FirebaseAnalytics.instance.setUserId(id: userId);
  }

  void clearUser() {
    _userId = null;
    debugPrint('[Analytics] clearUser');
    // TODO(launch): FirebaseAnalytics.instance.setUserId(id: null);
  }

  void setUserProperties(Map<String, dynamic> props) {
    debugPrint('[Analytics] setUserProperties $props');
    // TODO(launch): FirebaseAnalytics.instance.setUserProperty(...);
  }

  void track(String event, [Map<String, dynamic>? properties]) {
    final props = {...?properties, if (_userId != null) 'user_id': _userId};
    debugPrint('[Analytics] $event $props');
    // TODO(launch): FirebaseAnalytics.instance.logEvent(name: event, parameters: props);
  }

  /// Sends crash/feedback log to Supabase Edge Function crash-log-feedback.
  Future<void> logCrash(String message, {String? stack}) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'crash-log-feedback',
        body: {
          'message': message,
          if (stack != null) 'stack': stack,
          if (_userId != null) 'user_id': _userId,
          'ts': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {}
  }
}
