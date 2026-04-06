import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../l10n/strings.dart';
import '../providers/purchase_provider.dart';

class PremiumWelcomeScreen extends StatefulWidget {
  const PremiumWelcomeScreen({super.key});

  @override
  State<PremiumWelcomeScreen> createState() => _PremiumWelcomeScreenState();
}

class _PremiumWelcomeScreenState extends State<PremiumWelcomeScreen> {
  static const _benefitKeys = <String>[
    'recoveryWelcomeBenefit1',
    'recoveryWelcomeBenefit2',
    'recoveryWelcomeBenefit3',
    'recoveryWelcomeBenefit4',
  ];

  final _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.read<PurchaseProvider>().isPremium) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _page = i),
          children: [
            _buildRecoveryPlusPage(context),
            _buildPage(
              icon: Icons.mail_rounded,
              color: AppColors.primary,
              titleKey: 'writeFirstLetter',
              subtitleKey: 'deliversOnDate',
              ctaLabelKey: 'writeLetter',
              ctaRoute: '/future-letter-write',
            ),
            _buildPage(
              icon: Icons.mic_rounded,
              color: AppColors.gold,
              titleKey: 'prepareVoiceDay30',
              subtitleKey: 'voiceAwaits',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryPlusPage(BuildContext context) {
    final plan = context.watch<PurchaseProvider>().planDisplayLabel(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 80, color: AppColors.gold)
              .animate()
              .scale(begin: const Offset(0.3, 0.3), duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            S.t(context, 'welcomeRecovery'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            plan,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(height: 28),
          for (var i = 0; i < _benefitKeys.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    S.t(context, _benefitKeys[i]),
                    style: const TextStyle(fontSize: 15, height: 1.35, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (i < _benefitKeys.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              child: Text(S.t(context, 'nextBtn')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required Color color,
    required String titleKey,
    required String subtitleKey,
    String? ctaLabelKey,
    String? ctaRoute,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color).animate().scale(begin: const Offset(0.3, 0.3), duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(S.t(context, titleKey), textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text(S.t(context, subtitleKey), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 48),
          if (ctaLabelKey != null && ctaRoute != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(context).pushNamed(ctaRoute),
                child: Text(S.t(context, ctaLabelKey)),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              child: Text(_page < 2 ? S.t(context, 'nextBtn') : S.t(context, 'letsGo')),
            ),
          ),
        ],
      ),
    );
  }
}
