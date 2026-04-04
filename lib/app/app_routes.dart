import 'package:flutter/material.dart';

import '../screens/about_creator_screen.dart';
import '../screens/accountability_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/auth_choice_screen.dart';
import '../screens/checkin_screen.dart';
import '../screens/community_screen.dart';
import '../screens/craving_surf_screen.dart';
import '../screens/disclaimer_screen.dart';
import '../screens/future_letter_list_screen.dart';
import '../screens/future_letter_read_by_id_screen.dart';
import '../screens/future_letter_write_screen.dart';
import '../screens/home_screen.dart';
import '../screens/karma_mirror_screen.dart';
import '../screens/lessons_screen.dart';
import '../screens/meetings_screen.dart';
import '../screens/milestones_screen.dart';
import '../screens/mirror_moment_screen.dart';
import '../screens/naomi_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/paywall_screen.dart';
import '../screens/premium_welcome_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../screens/return_to_self_screen.dart';
import '../screens/savings_health_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/three_am_screen.dart';
import '../screens/trigger_tracker_screen.dart';
import '../screens/wall_of_strength_screen.dart';
import '../screens/self_compassion_screen.dart';
import '../screens/krytyk_log_screen.dart';
import '../screens/experiment_screen.dart';
import '../screens/x_marker_screen.dart';
import '../screens/krytyk_patterns_screen.dart';
import '../screens/crash_log_screen.dart';
import '../screens/rts_diagnostic_screen.dart';

Map<String, WidgetBuilder> buildAppRoutes() {
  return {
    '/': (_) => const SplashScreen(),
    '/onboarding': (_) => const OnboardingScreen(),
    '/auth': (_) => const AuthScreen(),
    '/auth-choice': (_) => const AuthChoiceScreen(),
    '/home': (_) => const HomeScreen(),
    '/checkin': (_) => const CheckinScreen(),
    '/paywall': (_) => const PaywallScreen(),
    '/premium-welcome': (_) => const PremiumWelcomeScreen(),
    '/three-am': (_) => const ThreeAmScreen(),
    '/craving-surf': (_) => const CravingSurfScreen(),
    '/milestones': (ctx) {
      final d = ModalRoute.of(ctx)?.settings.arguments as int?;
      return MilestonesScreen(focusMilestoneDays: d);
    },
    '/future-letter-write': (_) => const FutureLetterWriteScreen(),
    '/future-letter-list': (_) => const FutureLetterListScreen(),
    '/future-letter-read-by-id': (ctx) {
      final id = ModalRoute.of(ctx)?.settings.arguments as String? ?? '';
      return FutureLetterReadByIdScreen(letterId: id);
    },
    '/community': (_) => const CommunityScreen(),
    '/profile': (_) => const ProfileScreen(),
    '/register': (_) => const RegisterScreen(),
    '/terms': (_) => const TermsScreen(),
    '/privacy': (_) => const PrivacyScreen(),
    '/subscription': (_) => const SubscriptionScreen(),
    '/about': (_) => const AboutCreatorScreen(),
    '/disclaimer': (_) => const DisclaimerScreen(),
    '/savings': (_) => const SavingsHealthScreen(),
    '/triggers': (_) => const TriggerTrackerScreen(),
    '/lessons': (_) => const LessonsScreen(),
    '/meetings': (_) => const MeetingsScreen(),
    '/accountability': (_) => const AccountabilityScreen(),
    '/notifications': (_) => const NotificationsScreen(),
    '/return-to-self': (_) => const ReturnToSelfScreen(),
    '/karma-mirror': (_) => const KarmaMirrorScreen(),
    '/naomi': (_) => const NaomiScreen(),
    '/wall-of-strength': (_) => const WallOfStrengthScreen(),
    '/mirror-moment': (_) => const MirrorMomentScreen(),
    '/self-compassion': (_) => const SelfCompassionScreen(),
    '/inner-critic-log': (_) => const KrytykLogScreen(),
    '/experiment': (_) => const ExperimentScreen(),
    '/x-marker': (_) => const XMarkerScreen(),
    '/krytyk-patterns': (_) => const KrytykPatternsScreen(),
    '/crash-log': (_) => const CrashLogScreen(),
    '/rts-diagnostic': (_) => const RtsDiagnosticScreen(),
  };
}
