import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants/app_constants.dart';
import 'app/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/sobriety_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/milestone_provider.dart';
import 'providers/community_provider.dart';
import 'providers/future_letter_provider.dart';
import 'providers/three_am_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/return_to_self_provider.dart';
import 'providers/karma_provider.dart';
import 'providers/naomi_provider.dart';
import 'providers/wall_provider.dart';
import 'providers/accountability_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/premium_welcome_screen.dart';
import 'screens/three_am_screen.dart';
import 'screens/craving_surf_screen.dart';
import 'screens/milestones_screen.dart';
import 'screens/future_letter_write_screen.dart';
import 'screens/future_letter_list_screen.dart';
import 'screens/future_letter_read_by_id_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/about_creator_screen.dart';
import 'screens/disclaimer_screen.dart';
import 'screens/savings_health_screen.dart';
import 'screens/trigger_tracker_screen.dart';
import 'screens/lessons_screen.dart';
import 'screens/meetings_screen.dart';
import 'screens/accountability_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/return_to_self_screen.dart';
import 'screens/karma_mirror_screen.dart';
import 'screens/naomi_screen.dart';
import 'screens/wall_of_strength_screen.dart';
import 'screens/mirror_moment_screen.dart';
import 'screens/crash_log_screen.dart';
import 'screens/rts_diagnostic_screen.dart';
import 'services/notification_service.dart';
import 'services/crisis_detection_service.dart';
import 'services/crash_service.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      await Firebase.initializeApp();
      // Debug / `--dart-define=IS_DEVELOPMENT=true`: enable uploads (Crashlytics is off in debug by default).
      if (kDebugMode || AppConstants.isDevelopment) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      }
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      debugPrint('[Firebase] init failed: $e — continuing without Crashlytics');
    }

    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    
    await NotificationService().init();
    
    CrisisDetectionService().onCrisisDetected = () {
      debugPrint('[Crisis] Auto-detected — routing to 3 AM SOS');
    };

    runApp(const SoberStepsApp());
  }, (error, stack) {
    CrashService.recordError(error, stack);
  });
}

class SoberStepsApp extends StatefulWidget {
  const SoberStepsApp({super.key});

  @override
  State<SoberStepsApp> createState() => _SoberStepsAppState();
}

class _SoberStepsAppState extends State<SoberStepsApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleDeepUri(initial);
      _linkSub = _appLinks.uriLinkStream.listen(_handleDeepUri);
    } catch (_) {}
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  bool _hostMatches(String host) {
    final h = host.toLowerCase();
    final d = AppConstants.deepLinkDomain.toLowerCase();
    return h == d || h == 'www.$d';
  }

  void _handleDeepUri(Uri uri) {
    if (!_hostMatches(uri.host)) return;
    final nav = _navigatorKey.currentState;
    if (nav == null) return;
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.isEmpty) return;
    if (segs.length == 1 && segs[0] == 'checkin') {
      nav.pushNamed('/checkin');
      return;
    }
    if (segs.length == 2 && segs[0] == 'milestone') {
      final days = int.tryParse(segs[1]);
      if (days != null) {
        final ctx = _navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ctx.read<MilestoneProvider>().setDeepLinkMilestoneFocus(days);
        }
        nav.popUntil((route) {
          final n = route.settings.name;
          return n == '/home' || route.isFirst;
        });
        final ctx2 = _navigatorKey.currentContext;
        if (ctx2 != null && ctx2.mounted) {
          final topName = ModalRoute.of(ctx2)?.settings.name;
          if (topName != '/home') nav.pushNamed('/home');
        }
      }
      return;
    }
    if (segs.length == 2 && segs[0] == 'letter') {
      final id = segs[1];
      if (id.isNotEmpty) nav.pushNamed('/future-letter-read-by-id', arguments: id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SobrietyProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => MilestoneProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => FutureLetterProvider()),
        ChangeNotifierProvider(create: (_) => ThreeAmProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()..init()),
        ChangeNotifierProvider(create: (_) => ReturnToSelfProvider()),
        ChangeNotifierProvider(create: (_) => KarmaProvider()),
        ChangeNotifierProvider(create: (_) => NaomiProvider()),
        ChangeNotifierProvider(create: (_) => WallProvider()),
        ChangeNotifierProvider(create: (_) => AccountabilityProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, loc, _) => MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'SoberSteps',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          locale: loc.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('pl'),
            Locale('es'),
            Locale('fr'),
            Locale('ru'),
            Locale('nl'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/auth': (_) => const AuthScreen(),
            '/home': (_) => const HomeScreen(),
            '/checkin': (_) => const CheckinScreen(),
            '/paywall': (ctx) {
              final trigger =
                  ModalRoute.of(ctx)?.settings.arguments as String? ?? 'manual';
              return PaywallScreen(trigger: trigger);
            },
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
            '/return-to-self': (_) => ReturnToSelfScreen(),
            '/karma-mirror': (_) => const KarmaMirrorScreen(),
            '/naomi': (_) => const NaomiScreen(),
            '/wall-of-strength': (_) => const WallOfStrengthScreen(),
            '/mirror-moment': (_) => const MirrorMomentScreen(),
            '/crash-log': (_) => const CrashLogScreen(),
            '/rts-diagnostic': (_) => const RtsDiagnosticScreen(),
          },
        ),
      ),
    );
  }
}
