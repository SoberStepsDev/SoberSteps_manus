import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/purchase_provider.dart';
import '../l10n/strings.dart';

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

  static const _emoji = {3: '🔥', 7: '⭐', 30: '🏆', 90: '🧠'};

  static const _titleKeys = {
    3: 'milestoneUpsell3Title',
    7: 'milestoneUpsell7Title',
    30: 'milestoneUpsell30Title',
    90: 'milestoneUpsell90Title',
  };
  static const _bodyKeys = {
    3: 'milestoneUpsell3Body',
    7: 'milestoneUpsell7Body',
    30: 'milestoneUpsell30Body',
    90: 'milestoneUpsell90Body',
  };

  @override
  Widget build(BuildContext context) {
    final emoji = _emoji[milestoneDays];
    final titleKey = _titleKeys[milestoneDays];
    final bodyKey = _bodyKeys[milestoneDays];
    if (emoji == null || titleKey == null || bodyKey == null) return const SizedBox.shrink();

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
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            S.t(context, titleKey),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            S.t(context, bodyKey),
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
              child: Text(
                S.t(context, 'milestoneUpsellCta'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              S.t(context, 'cravingMaybeLater'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
