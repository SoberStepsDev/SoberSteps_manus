import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../l10n/strings.dart';
import '../providers/sobriety_provider.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../constants/app_constants.dart';
import 'rts_diagnostic_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _emailController = TextEditingController();
  final _analytics = AnalyticsService();
  int _currentStep = 0;
  String? _substanceType;
  String? _addictionCategory; // 'substance', 'behavioral', 'return_to_self'
  bool _returnToSelfEnabled = false;
  bool _showReturnToSelfQuestion = false;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _analytics.track('onboarding_step_complete', {'step': _currentStep + 1});
    if (_currentStep < 4) {
      _pageController.nextPage(duration: 300.ms, curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (_addictionCategory != null) {
      await prefs.setString('addiction_category', _addictionCategory!);
    }
    await prefs.setBool('return_to_self_enabled', _returnToSelfEnabled);
    _analytics.track('onboarding_complete', {
      'substance_type': _substanceType,
      'addiction_category': _addictionCategory,
      'return_to_self': _returnToSelfEnabled,
    });
    if (mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final sobriety = context.watch<SobrietyProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(sobriety),
                  _buildStep2(),
                  _buildStep3(sobriety),
                  _buildStep4(),
                  _buildStep5(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: List.generate(5, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i <= _currentStep ? AppColors.primary : AppColors.surfaceLight,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1(SobrietyProvider sobriety) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/SoberStepsLogo.png',
            height: 64,
            width: 64,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.local_fire_department, size: 64, color: AppColors.gold),
          ),
          const SizedBox(height: 16),
          Text(
            '${sobriety.daysSober}',
            style: const TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w800,
              letterSpacing: -4,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.5, 0.5)),
          Text(S.t(context, 'days'), style: const TextStyle(fontSize: 24, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Icon(Icons.local_fire_department, size: 64, color: AppColors.gold)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms, color: AppColors.gold.withValues(alpha: 0.3)),
          const SizedBox(height: 48),
          Text(S.t(context, 'yourJourneyStarts'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                sobriety.setSobrietyStartDate(DateTime.now());
                _nextPage();
              },
              child: Text(S.t(context, 'startCounting')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    if (_showReturnToSelfQuestion) {
      return _buildReturnToSelfQuestion();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Text(S.t(context, 'whatDoYouWantToLeave'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 24),
            // --- Substancje psychoaktywne ---
            Text(S.t(context, 'onboardingSubstancesTitle'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1)),
            const SizedBox(height: 8),
            ...AppConstants.substanceTypes.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SubstanceCard(
                label: _localizedSubstanceLabel(context, e.key),
                icon: _iconForSubstance(e.key),
                selected: _substanceType == e.key,
                onTap: () => _selectAddiction('substance', e.key),
                compact: true,
              ),
            )),
            const SizedBox(height: 16),
            // --- Uzależnienia behawioralne ---
            Text(S.t(context, 'onboardingBehavioralTitle'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1)),
            const SizedBox(height: 8),
            ...AppConstants.behavioralTypes.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SubstanceCard(
                label: _localizedBehavioralLabel(context, e.key),
                icon: _iconForBehavioral(e.key),
                selected: _substanceType == e.key,
                onTap: () => _selectAddiction('behavioral', e.key),
                compact: true,
              ),
            )),
            const SizedBox(height: 16),
            // --- Powrót do Siebie ---
            Text(S.t(context, 'onboardingReturnToSelfTitle'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1)),
            const SizedBox(height: 8),
            ...AppConstants.returnToSelfTypes.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _SubstanceCard(
                  label: _localizedReturnToSelfLabel(context, e.key),
                  icon: _iconForReturnToSelf(e.key),
                  selected: _substanceType == e.key,
                  onTap: () => _selectAddiction('return_to_self', e.key),
                  compact: true,
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnToSelfQuestion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.self_improvement, size: 64, color: AppColors.gold),
          const SizedBox(height: 24),
          Text(S.t(context, 'returnToSelfQuestion'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text(S.t(context, 'returnToSelfDesc'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                setState(() => _returnToSelfEnabled = true);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('return_to_self_enabled', true);
                await _openRtsDiagnosticThen(() {
                  if (!mounted) return;
                  setState(() => _showReturnToSelfQuestion = false);
                  _nextPage();
                });
              },
              child: Text(S.t(context, 'yesIWant')),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _returnToSelfEnabled = false;
                _showReturnToSelfQuestion = false;
              });
              _nextPage();
            },
            child: Text(S.t(context, 'notNow'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectAddiction(String category, String type) async {
    HapticFeedback.lightImpact();
    setState(() {
      _substanceType = type;
      _addictionCategory = category;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('substance_type', type);
    await prefs.setString('addiction_category', category);
    // If substance/behavioral → ask about Return to Self
    if (category != 'return_to_self') {
      setState(() => _showReturnToSelfQuestion = true);
    } else {
      setState(() => _returnToSelfEnabled = true);
      await prefs.setBool('return_to_self_enabled', true);
      await _openRtsDiagnosticThen(() {
        if (!mounted) return;
        _nextPage();
      });
    }
  }

  Future<void> _openRtsDiagnosticThen(VoidCallback afterPop) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const RtsDiagnosticScreen(),
      ),
    );
    if (!mounted) return;
    afterPop();
  }

  IconData _iconForSubstance(String key) {
    return switch (key) {
      'alcohol' => Icons.local_bar,
      'marijuana_thc' => Icons.grass,
      'cocaine' => Icons.flash_on,
      'heroin' => Icons.warning_amber,
      'crack' => Icons.warning_amber,
      'methamphetamine' => Icons.bolt,
      'opioids' => Icons.medication,
      _ => Icons.more_horiz,
    };
  }

  String _localizedSubstanceLabel(BuildContext context, String key) {
    final labelKey = switch (key) {
      'alcohol' => 'substAlcohol',
      'marijuana_thc' => 'substMarijuana',
      'cocaine' => 'substCocaine',
      'heroin' => 'substHeroin',
      'crack' => 'substCrack',
      'methamphetamine' => 'substMeth',
      'opioids' => 'substOpioids',
      _ => 'substOther',
    };
    return S.t(context, labelKey);
  }

  IconData _iconForBehavioral(String key) {
    return switch (key) {
      'gambling' => Icons.casino,
      'sex_pornography' => Icons.visibility_off,
      'social_media' => Icons.phone_android,
      'shopping' => Icons.shopping_bag,
      'gaming' => Icons.sports_esports,
      'workaholism' => Icons.work,
      _ => Icons.more_horiz,
    };
  }

  String _localizedBehavioralLabel(BuildContext context, String key) {
    final labelKey = switch (key) {
      'gambling' => 'behavGambling',
      'sex_pornography' => 'behavSexPorn',
      'social_media' => 'behavSocialMedia',
      'shopping' => 'behavShopping',
      'gaming' => 'behavGaming',
      'workaholism' => 'behavWork',
      _ => 'other',
    };
    return S.t(context, labelKey);
  }

  IconData _iconForReturnToSelf(String key) {
    return switch (key) {
      'self_hatred' => Icons.heart_broken,
      'perfectionism' => Icons.auto_awesome,
      'toxic_relationships' => Icons.people_outline,
      _ => Icons.self_improvement,
    };
  }

  String _localizedReturnToSelfLabel(BuildContext context, String key) {
    final labelKey = switch (key) {
      'self_hatred' => 'rtsSelfHatred',
      'perfectionism' => 'rtsPerfectionism',
      'toxic_relationships' => 'rtsToxicRel',
      _ => 'returnToSelf',
    };
    return S.t(context, labelKey);
  }

  Widget _buildStep3(SobrietyProvider sobriety) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(S.t(context, 'whenWasLastDay'),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Text(
            '${sobriety.daysSober} ${S.t(context, 'days')}',
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: AppColors.gold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(S.t(context, 'chooseDate')),
              onPressed: () async {
                HapticFeedback.lightImpact();
                final date = await showDatePicker(
                  context: context,
                  initialDate: sobriety.sobrietyStartDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  builder: (context, child) => Theme(
                    data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)),
                    child: child!,
                  ),
                );
                if (date != null) {
                  sobriety.setSobrietyStartDate(date);
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          TextButton(onPressed: _nextPage, child: Text('${S.t(context, 'next')} →', style: const TextStyle(color: AppColors.primary, fontSize: 18))),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mail_outline, size: 64, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(S.t(context, 'letterIn30Days'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: S.t(context, 'yourEmail')),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                final email = _emailController.text.trim();
                if (email.isNotEmpty) {
                  await context.read<AuthProvider>().insertEmailLead(email);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_email', email);
                }
                _nextPage();
              },
              child: Text(S.t(context, 'continue')),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: _nextPage, child: Text(S.t(context, 'skip'), style: const TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_active, size: 64, color: AppColors.gold),
          const SizedBox(height: 24),
          Text(S.t(context, 'notifyMilestones'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await NotificationService().requestPermission();
                _nextPage();
              },
              child: Text(S.t(context, 'yesNotify')),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _nextPage,
            child: Text(S.t(context, 'maybeLater'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _SubstanceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const _SubstanceCard({required this.label, required this.icon, required this.selected, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 12.0 : 24.0;
    final iconSize = compact ? 24.0 : 32.0;
    final fontSize = compact ? 15.0 : 18.0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.surfaceLight, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: iconSize, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
