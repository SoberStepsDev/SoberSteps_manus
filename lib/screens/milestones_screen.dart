import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';
import '../providers/milestone_provider.dart';
import '../l10n/strings.dart';
import '../providers/sobriety_provider.dart';
import '../providers/purchase_provider.dart';
import '../models/milestone.dart';
import '../services/analytics_service.dart';
import '../services/tts_service.dart';

class MilestonesScreen extends StatefulWidget {
  /// When set (e.g. deep link), scrolls this milestone into view after layout.
  final int? focusMilestoneDays;

  const MilestonesScreen({super.key, this.focusMilestoneDays});

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  final _scrollController = ScrollController();
  bool _didScrollFocus = false;

  @override
  void initState() {
    super.initState();
    context.read<MilestoneProvider>().loadMilestones();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeScrollToFocus() {
    final target = widget.focusMilestoneDays;
    if (target == null || _didScrollFocus) return;
    final idx = MilestoneData.all.indexWhere((d) => d.days == target);
    if (idx < 0) {
      context.read<MilestoneProvider>().clearDeepLinkMilestoneFocus();
      return;
    }
    _didScrollFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final offset = (idx * 120.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      // Allow a later deep link to the same day to scroll again.
      context.read<MilestoneProvider>().clearDeepLinkMilestoneFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final milestoneProvider = context.watch<MilestoneProvider>();
    final sobriety = context.watch<SobrietyProvider>();
    final daysSober = sobriety.daysSober;
    _maybeScrollToFocus();

    if (sobriety.pendingMilestone != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCelebration(sobriety.pendingMilestone!);
        sobriety.clearPendingMilestone();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(S.t(context, 'milestones')),
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: MilestoneData.all.length,
        itemBuilder: (context, i) {
          final data = MilestoneData.all[i];
          final achieved = milestoneProvider.isAchieved(data.days) || daysSober >= data.days;
          final isNext = !achieved && (i == 0 || daysSober >= MilestoneData.all[i - 1].days);
          return _MilestoneCard(data: data, achieved: achieved, isNext: isNext, daysSober: daysSober);
        },
      ),
    );
  }

  void _showCelebration(int days) {
    final data = MilestoneData.forDays(days);
    if (data == null) return;
    final isPremium = context.read<PurchaseProvider>().isPremium;
    context.read<MilestoneProvider>().recordMilestone(days);
    AnalyticsService().track('milestone_celebrate', {'days': days});
    TtsService().speakMilestone(
      isPremium: isPremium,
      days: days,
      freeFallback: data.message,
    );

    showDialog(
      context: context,
      barrierColor: AppColors.background.withValues(alpha: 0.85),
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data.emoji, style: const TextStyle(fontSize: 64))
                .animate()
                .scale(begin: const Offset(0.3, 0.3), end: const Offset(1.0, 1.0), duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text('${data.days} ${S.t(context, 'days')}!',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.gold)),
            const SizedBox(height: 8),
            Text(data.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: AppColors.textPrimary)),
            Text(data.subMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          if (data.shareText.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.share),
              label: Text(S.t(context, 'quickShare')),
              onPressed: () => Share.share(data.shareText),
            ),
          if (!isPremium)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/paywall');
              },
              child: Text(S.t(context, 'unlockRecoveryPlus'), style: const TextStyle(color: AppColors.gold)),
            ),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(S.t(context, 'ok'))),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final MilestoneData data;
  final bool achieved;
  final bool isNext;
  final int daysSober;

  const _MilestoneCard({required this.data, required this.achieved, required this.isNext, required this.daysSober});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achieved ? AppColors.gold : (isNext ? AppColors.primary : AppColors.surfaceLight),
          width: achieved ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(data.emoji, style: TextStyle(fontSize: 32, color: achieved ? null : AppColors.textPrimary.withValues(alpha: 0.3))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: achieved ? AppColors.gold : AppColors.textPrimary)),
                if (achieved)
                  Text(S.t(context, 'achieved'), style: const TextStyle(color: AppColors.success, fontSize: 12))
                else if (isNext)
                  Text('${data.days - daysSober} ${S.t(context, 'daysToGo')}', style: const TextStyle(color: AppColors.primary, fontSize: 12))
                else
                  Text(S.t(context, 'locked'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (achieved)
            const Icon(Icons.check_circle, color: AppColors.gold)
          else if (!achieved && !isNext)
            const Icon(Icons.lock, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}
