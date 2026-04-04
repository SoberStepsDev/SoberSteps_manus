import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/purchase_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/strings.dart';

class AccountabilityScreen extends StatelessWidget {
  const AccountabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PurchaseProvider>().isPremium;
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;

    if (!isPremium) return _buildPremiumGate(context);
    if (!isLoggedIn) return _buildLoginGate(context);
    return _buildMain(context);
  }

  Widget _buildPremiumGate(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'accountabilityPartner'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_alt_rounded, size: 72, color: AppColors.gold),
              const SizedBox(height: 24),
              Text(S.t(context, 'accountabilityPartner'), textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Text(
                S.t(context, 'accountabilityIntro'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    _FeatureRow(icon: Icons.link, text: S.t(context, 'accountabilityFeaturePairing')),
                    const SizedBox(height: 12),
                    _FeatureRow(icon: Icons.sync, text: S.t(context, 'accountabilityFeatureStreak')),
                    const SizedBox(height: 12),
                    _FeatureRow(icon: Icons.chat_bubble_outline, text: S.t(context, 'accountabilityFeatureChat')),
                    const SizedBox(height: 12),
                    _FeatureRow(icon: Icons.notifications_active, text: S.t(context, 'accountabilityFeatureReminders')),
                    const SizedBox(height: 12),
                    _FeatureRow(icon: Icons.visibility, text: S.t(context, 'accountabilityFeatureMilestones')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                  onPressed: () => Navigator.pushNamed(context, '/paywall'),
                  child: Text(S.t(context, 'unlockWithRecovery')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginGate(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'accountabilityPartner'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(S.t(context, 'loginToUse'), style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/auth'), child: Text(S.t(context, 'login'))),
          ],
        ),
      ),
    );
  }

  Widget _buildMain(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'accountabilityPartner'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_alt_rounded, size: 72, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(S.t(context, 'noPartner'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text(S.t(context, 'inviteCodeOrFind'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: Text(S.t(context, 'invitePartner')),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.t(context, 'pairingComingSoon'))),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.search),
                  label: Text(S.t(context, 'findInCommunity')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.surfaceLight),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.t(context, 'matchingSoon'))),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
      ],
    );
  }
}
