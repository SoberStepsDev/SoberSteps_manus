import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';
import '../providers/sobriety_provider.dart';
import '../providers/milestone_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/future_letter_provider.dart';
import '../providers/journal_provider.dart';
import '../screens/checkin_screen.dart';
import '../screens/three_am_screen.dart';
import '../screens/milestones_screen.dart';
import '../screens/community_screen.dart';
import '../screens/profile_screen.dart';
import '../models/future_letter.dart';
import '../screens/future_letter_read_screen.dart';
import '../l10n/strings.dart';
import '../widgets/daily_perspective_widget.dart';
import '../services/mirror_mind_service.dart';
import '../services/streak_protection_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _navIndex = 0;
  Timer? _timer;
  late final MilestoneProvider _milestoneProvider;

  List<Widget> _screens(int? milestoneFocus) => [
        const _HomeTab(),
        const CheckinScreen(),
        MilestonesScreen(
          key: ValueKey<int?>(milestoneFocus),
          focusMilestoneDays: milestoneFocus,
        ),
        const CommunityScreen(),
        const ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    _attachMilestoneListener();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      context.read<SobrietyProvider>().refresh();
    });
    _initData();
  }

  void _attachMilestoneListener() {
    _milestoneProvider = context.read<MilestoneProvider>();
    _milestoneProvider.addListener(_onMilestoneDeepLink);
    if (_milestoneProvider.deepLinkMilestoneFocusDays != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _navIndex = 2);
      });
    }
  }

  void _onMilestoneDeepLink() {
    if (!mounted) return;
    if (_milestoneProvider.deepLinkMilestoneFocusDays != null) {
      setState(() => _navIndex = 2);
    }
  }

  Future<void> _initData() async {
    final sobriety = context.read<SobrietyProvider>();
    await sobriety.loadFromLocal();
    if (!mounted) return;
    sobriety.loadFromSupabase();
    context.read<JournalProvider>().loadEntries();
    context.read<JournalProvider>().syncPendingData();
    context.read<FutureLetterProvider>().loadLetters();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SobrietyProvider>().loadFromSupabase();
      context.read<JournalProvider>().syncPendingData();
      context.read<FutureLetterProvider>().syncPendingData();
      MirrorMindService().syncPending();
    }
  }

  @override
  void dispose() {
    _milestoneProvider.removeListener(_onMilestoneDeepLink);
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final milestoneFocus =
        context.watch<MilestoneProvider>().deepLinkMilestoneFocusDays;
    final screens = _screens(milestoneFocus);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: KeyedSubtree(
            key: ValueKey<int>(_navIndex), child: screens[_navIndex]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) {
          HapticFeedback.lightImpact();
          setState(() => _navIndex = i);
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: S.t(context, 'home')),
          BottomNavigationBarItem(icon: const Icon(Icons.edit_note_rounded), label: S.t(context, 'journal')),
          BottomNavigationBarItem(icon: const Icon(Icons.emoji_events_rounded), label: S.t(context, 'milestones')),
          BottomNavigationBarItem(icon: const Icon(Icons.people_rounded), label: S.t(context, 'community')),
          BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: S.t(context, 'profile')),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _returnToSelfEnabled = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _returnToSelfEnabled = p.getBool('return_to_self_enabled') ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sobriety = context.watch<SobrietyProvider>();
    final purchase = context.watch<PurchaseProvider>();
    final letterProvider = context.watch<FutureLetterProvider>();
    final isNight = DateTime.now().hour >= 22 || DateTime.now().hour < 6;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final letter = letterProvider.pendingDelivery;
      if (letter != null) {
        letterProvider.clearPendingDelivery();
        _showLetterDialog(context, letter);
      }
    });

    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/SoberStepsLogo.png',
                    height: 48,
                    width: 48,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.shield_rounded,
                      size: 48,
                      color: purchase.isPremium ? AppColors.streakBlue : AppColors.textSecondary,
                    ),
                  ),
                ).animate(onPlay: (c) => purchase.isPremium ? c.repeat() : null).shimmer(
                      duration: 2000.ms,
                      color: purchase.isPremium ? AppColors.streakBlue.withValues(alpha: 0.3) : Colors.transparent,
                    ),
                const SizedBox(height: 24),
                // Animated days counter
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: sobriety.daysSober),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -4,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
                Text(
                  S.t(context, 'daysSober'),
                  style: const TextStyle(fontSize: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '+ ${sobriety.hoursSober}h',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                if (sobriety.streakDays > 0) ...[  
                  const SizedBox(height: 8),
                  _StreakBadge(streak: sobriety.streakDays),
                ],
                if (purchase.isPremium &&
                    (sobriety.streakAtRisk || sobriety.streakProtectionGraceActive)) ...[  
                  const SizedBox(height: 10),
                  const _StreakProtectionHomeRow(),
                ],
                const SizedBox(height: 24),
                _ProgressBar(progress: sobriety.progressToNextMilestone, daysToGo: sobriety.daysToNextMilestone, nextMilestone: sobriety.nextMilestone),
                const SizedBox(height: 16),
                _SavingsCard(days: sobriety.daysSober),
                const SizedBox(height: 16),
                _QuoteCard(),
                const SizedBox(height: 12),
                const DailyPerspectiveWidget(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(S.t(context, 'checkinNow')),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pushNamed('/checkin');
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _SosButton(isNight: isNight),
                if (_returnToSelfEnabled) ...[  
                  const SizedBox(height: 16),
                  _ReturnToSelfCard(),
                ],
                const SizedBox(height: 16),
                const _MirrorMindCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        if (isNight) Positioned.fill(child: IgnorePointer(child: Container(color: AppColors.nightOverlay))),
      ],
    );
  }

  void _showLetterDialog(BuildContext context, FutureLetter letter) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.t(context, 'letterFromSelfNotify')),
        content: Text(S.t(context, 'open')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(S.t(context, 'later'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => FutureLetterReadScreen(letter: letter)));
            },
            child: Text(S.t(context, 'openBtn')),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final int daysToGo;
  final int? nextMilestone;

  const _ProgressBar({required this.progress, required this.daysToGo, this.nextMilestone});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          nextMilestone != null ? '$daysToGo ${S.t(context, 'daysToMilestone')} $nextMilestone${S.t(context, 'dayMilestone')}' : S.t(context, 'allMilestonesDone'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return FutureBuilder<String>(
      future: rootBundle.loadString('assets/data/quotes.json'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final quotes = jsonDecode(snapshot.data!) as List;
        final idx = DateTime.now().day % quotes.length;
        final q = quotes[idx];
        final text = (lang == 'pl' && q['text_pl'] != null) ? q['text_pl'] as String : q['text'] as String;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '"$text"\n— ${q["author"]}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary.withValues(alpha: 0.85),
            ),
          ),
        );
      },
    );
  }
}

class _SavingsCard extends StatelessWidget {
  final int days;
  const _SavingsCard({required this.days});

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).toString();
    final nf = NumberFormat.decimalPatternDigits(locale: loc, decimalDigits: 0);
    return FutureBuilder<double>(
      future: SharedPreferences.getInstance().then((p) => p.getDouble('daily_substance_cost') ?? 15.0),
      builder: (context, snap) {
        final daily = snap.data ?? 15.0;
        return GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/savings'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_rounded, color: AppColors.gold, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${nf.format(days * daily)} ${S.t(context, 'saved')}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(S.t(context, 'tapForHealth'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReturnToSelfCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pushNamed('/return-to-self');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.self_improvement, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.t(context, 'returnToSelf'), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(S.t(context, 'rtsPath30'), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── Streak Badge ────────────────────────────────────────────────────────────
class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.streakBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.streakBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: AppColors.streakBlue, size: 16),
          const SizedBox(width: 6),
          Text(
            '$streak ${streak == 1 ? 'dzień' : 'dni'} z rzędu',
            style: const TextStyle(
              color: AppColors.streakBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakProtectionHomeRow extends StatelessWidget {
  const _StreakProtectionHomeRow();

  @override
  Widget build(BuildContext context) {
    final sobriety = context.watch<SobrietyProvider>();
    final purchase = context.watch<PurchaseProvider>();

    if (sobriety.streakProtectionGraceActive) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                S.t(context, 'streakProtectionOn'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!sobriety.streakAtRisk) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      key: ValueKey<String>(
        '${sobriety.streakAtRisk}_${sobriety.streakProtectionGraceActive}_${sobriety.streakDays}_${purchase.isPremium}',
      ),
      future: SharedPreferences.getInstance().then(
        (p) => StreakProtectionService.canUse(p, purchase.isPremium),
      ),
      builder: (context, snap) {
        final canUse = snap.data ?? false;
        if (!canUse) {
          return Text(
            S.t(context, 'streakProtectionLimitReached'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          );
        }
        return OutlinedButton.icon(
          onPressed: () async {
            HapticFeedback.lightImpact();
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                content: Text(S.t(context, 'streakProtection')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(S.t(context, 'cancel')),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(S.t(context, 'streakProtectionActivate')),
                  ),
                ],
              ),
            );
            if (ok != true || !context.mounted) return;
            final prefs = await SharedPreferences.getInstance();
            final activated =
                await StreakProtectionService.tryActivate(prefs, purchase.isPremium);
            if (!context.mounted) return;
            if (activated) {
              await context.read<SobrietyProvider>().refreshStreak();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.t(context, 'streakProtectionOn'))),
              );
            }
          },
          icon: const Icon(Icons.shield_outlined, size: 18),
          label: Text(S.t(context, 'streakProtectionActivate')),
        );
      },
    );
  }
}

// ─── MirrorMind Coming Card ───────────────────────────────────────────────────
class _MirrorMindCard extends StatelessWidget {
  const _MirrorMindCard();

  void _showModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '🪞',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'MirrorMind',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Twoje wzorce. Twoja intuicja. Twoje odbicie.\n\nMirrorMind to AI, która uczy się Twojego rytmu trzeźwości — i mówi do Ciebie Twoim własnym językiem.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Dostępne Q3 2026',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showModal(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🪞', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MirrorMind',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Twoje odbicie AI — Coming Q3 2026',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Q3 2026',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }
}

class _SosButton extends StatelessWidget {
  final bool isNight;
  const _SosButton({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.sos_rounded),
        label: Text(S.t(context, 'threeAmSos')),
        style: ElevatedButton.styleFrom(
          backgroundColor: isNight ? AppColors.crisisRed : AppColors.crisisRed.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ThreeAmScreen()));
        },
      ),
    ).animate(onPlay: (c) => isNight ? c.repeat(reverse: true) : null).scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1.04, 1.04),
          duration: 1200.ms,
        );
  }
}
