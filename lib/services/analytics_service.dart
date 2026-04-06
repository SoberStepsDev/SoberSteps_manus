import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Analytics: [debugPrint] in all builds + Firebase Analytics when [Firebase] is initialized.
/// Event/parameter names and values are sanitized for GA4 limits; no free-form health text.
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
  static const eProGateCta = 'pro_gate_cta';
  static const ePremiumWelcomeViewed = 'premium_welcome_viewed';

  bool get _faReady => Firebase.apps.isNotEmpty;

  void setUserId(String userId) {
    _userId = userId;
    debugPrint('[Analytics] setUserId $userId');
    if (!_faReady) return;
    FirebaseAnalytics.instance
        .setUserId(id: userId)
        .catchError((Object e, StackTrace _) => debugPrint('[Analytics] FA setUserId: $e'));
  }

  void clearUser() {
    _userId = null;
    debugPrint('[Analytics] clearUser');
    if (!_faReady) return;
    FirebaseAnalytics.instance
        .setUserId(id: null)
        .catchError((Object e, StackTrace _) => debugPrint('[Analytics] FA clearUser: $e'));
  }

  void setUserProperties(Map<String, dynamic> props) {
    debugPrint('[Analytics] setUserProperties $props');
    if (!_faReady) return;
    for (final e in props.entries) {
      final name = _gaUserPropertyName(e.key);
      if (name == null) continue;
      final raw = e.value?.toString() ?? '';
      final value = raw.length > 36 ? raw.substring(0, 36) : raw;
      FirebaseAnalytics.instance
          .setUserProperty(name: name, value: value.isEmpty ? null : value)
          .catchError((Object err, StackTrace _) => debugPrint('[Analytics] FA setUserProperty: $err'));
    }
  }

  void track(String event, [Map<String, dynamic>? properties]) {
    final props = {...?properties};
    debugPrint('[Analytics] $event $props');
    if (!_faReady) return;
    final name = _gaEventName(event);
    final params = _gaParameters(props);
    FirebaseAnalytics.instance
        .logEvent(name: name, parameters: params)
        .catchError((Object e, StackTrace _) => debugPrint('[Analytics] FA logEvent: $e'));
  }

  /// Sends crash/feedback log to Supabase Edge Function crash-log-feedback.
  Future<void> logCrash(String message, {String? stack}) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'crash-log-feedback',
        body: {
          'message': message,
          'stack': stack,
          'user_id': _userId,
          'ts': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {}
  }

  static String _gaEventName(String raw) {
    var s = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (s.isEmpty) s = 'event';
    if (RegExp(r'^[0-9]').hasMatch(s)) s = 'e_$s';
    if (s.length > 40) s = s.substring(0, 40);
    return s;
  }

  static Map<String, Object>? _gaParameters(Map<String, dynamic> raw) {
    if (raw.isEmpty) return null;
    final out = <String, Object>{};
    var n = 0;
    for (final e in raw.entries) {
      if (n >= 25) break;
      final k = _gaParamKey(e.key);
      if (k == null) continue;
      final v = e.value;
      if (v == null) continue;
      if (v is num) {
        out[k] = v;
      } else if (v is bool) {
        out[k] = v ? 1 : 0;
      } else {
        final s = v.toString();
        out[k] = s.length > 100 ? s.substring(0, 100) : s;
      }
      n++;
    }
    return out.isEmpty ? null : out;
  }

  static String? _gaParamKey(String raw) {
    var s = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (s.isEmpty) return null;
    if (RegExp(r'^[0-9]').hasMatch(s)) s = 'p_$s';
    final lower = s.toLowerCase();
    if (lower.startsWith('firebase_') || lower.startsWith('google_') || lower.startsWith('ga_')) {
      return null;
    }
    if (s.length > 40) s = s.substring(0, 40);
    return s;
  }

  static String? _gaUserPropertyName(String raw) {
    var s = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (s.isEmpty) return null;
    if (RegExp(r'^[0-9]').hasMatch(s)) s = 'u_$s';
    if (s.length > 24) s = s.substring(0, 24);
    return s;
  }
}
