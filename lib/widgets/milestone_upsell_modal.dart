import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/purchase_provider.dart';

/// Upsell modal shown at milestone days [3, 7, 30, 90] for free users.
/// Call via [MilestoneUpsellModal.maybeShow].
class MilestoneUpsellModal extends StatelessWidget {
  final int milestoneDays;

  const MilestoneUpsellModal({super.key, required this.milestoneDays});

  /// Shows the modal if:
  /// - user is NOT premium
  /// - upsell for this milestone has NOT been shown before
  /// Marks as shown after displaying.
  static Future<void> maybeShow(BuildContext context, int milestoneDays) async {
    final purchase = context.read<PurchaseProvider>();
    if (purchase.isPro) return;
    if (purchase.hasShownUpsell(milestoneDays)) return;
    if (!_upsellDays.contains(milestoneDays)) return;

    await purchase.markUpsellShown(milestoneDays);

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MilestoneUpsellModal(milestoneDays: milestoneDays),
    );
  }

  static const _upsellDays = {3, 7, 30, 90};

  static const _copy = {
    3: (
      emoji: '🔥',
      title: 'Trzy dni. Coś się zaczyna.',
      body:
          'Recovery+ odblokuje Streak Protection — Twój postęp jest bezpieczny nawet gdy się pokniesz.',
    ),
    7: (
      emoji: '⭐',
      title: 'Tydzień. Czas na głębszy krok.',
      body:
          'Napisz list do siebie za 30 dni. Naomi AI będzie przy Tobie w trudnych chwilach.',
    ),
    30: (
      emoji: '🏆',
      title: 'Miesiąc. Zasługujesz na więcej.',
      body:
          'Odblokuj głos Naomi, listy do przyszłego siebie i pełny moduł samowspółczucia.',
    ),
    90: (
      emoji: '🧠',
      title: '90 dni zmienia mózg.',
      body:
          'Twój mózg się przebudował. Recovery+ da Ci narzędzia na kolejny etap drogi.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final c = _copy[milestoneDays];
    if (c == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(c.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            c.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            c.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(
                  '/paywall',
                  arguments: 'milestone_$milestoneDays',
                );
              },
              child: const Text(
                'Wypróbuj Recovery+ za darmo — 7 dni',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Może później',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
