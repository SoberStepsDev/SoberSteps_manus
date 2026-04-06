import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lottie/lottie.dart';
import '../widgets/milestone_upsell_modal.dart';
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
          final prevDays = i > 0 ? MilestoneData.all[i - 1].days : 0;
          return _MilestoneCard(
            data: data,
            achieved: achieved,
            isNext: isNext,
            daysSober: daysSober,
            prevMilestoneDays: prevDays,
          );
        },
      ),
    );
  }

  /// Multi-step celebration sequence:
  /// 1. Przyciemnienie (barrierColor 0.92)
  /// 2. Zoom liczby (TweenAnimationBuilder, 600ms elasticOut)
  /// 3. Lottie confetti (800ms delay)
  /// 4. Karta filozoficzna (message + subMessage, fade 800ms)
  /// 5. TTS audio
  void _showCelebration(int days) {
    final data = MilestoneData.forDays(days);
    if (data == null) return;
    final isPremium = context.read<PurchaseProvider>().isPremium;
    context.read<MilestoneProvider>().recordMilestone(days);
    AnalyticsService().track('milestone_celebrate', {'days': days});
    HapticFeedback.heavyImpact();

    // Upsell modal for free users at trigger milestones (3/7/30/90)
    // Shown AFTER celebration dialog closes
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      MilestoneUpsellModal.maybeShow(context, days);
    });

    // TTS fires after 800ms (after zoom + confetti start)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      TtsService().speakMilestone(
        isPremium: isPremium,
        days: days,
        freeFallback: S.t(context, data.messageKey),
      );
    });

    showDialog(
      context: context,
      barrierColor: AppColors.background.withValues(alpha: 0.92),
      builder: (ctx) => _CelebrationDialog(data: data, isPremium: isPremium),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final MilestoneData data;
  final bool achieved;
  final bool isNext;
  final int daysSober;
  final int? prevMilestoneDays;

  const _MilestoneCard({
    required this.data,
    required this.achieved,
    required this.isNext,
    required this.daysSober,
    this.prevMilestoneDays,
  });

  @override
  Widget build(BuildContext context) {
    // Progress for the 'next' card
    double? progress;
    if (isNext) {
      final prev = prevMilestoneDays ?? 0;
      final range = data.days - prev;
      progress = range > 0 ? ((daysSober - prev) / range).clamp(0.0, 1.0) : 0.0;
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                data.emoji,
                style: TextStyle(
                  fontSize: 32,
                  color: achieved ? null : AppColors.textPrimary.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.t(context, data.titleKey),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: achieved ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (achieved)
                      Text(
                        S.t(context, 'milestoneViewpointReached'),
                        style: const TextStyle(color: AppColors.success, fontSize: 12),
                      )
                    else if (isNext)
                      Text(
                        S.t(context, 'milestoneAroundBend').replaceAll('{n}', '${data.days - daysSober}'),
                        style: const TextStyle(color: AppColors.primary, fontSize: 12),
                      )
                    else
                      Text(
                        S.t(context, 'locked'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (achieved)
                const Icon(Icons.check_circle, color: AppColors.gold)
              else if (!achieved && !isNext)
                const Icon(Icons.lock, color: AppColors.textSecondary, size: 20),
            ],
          ),
          // Progress bar for 'next' milestone
          if (isNext && progress != null) ...[  
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Celebration Dialog ────────────────────────────────────────────────────────────
class _CelebrationDialog extends StatefulWidget {
  final MilestoneData data;
  final bool isPremium;
  const _CelebrationDialog({required this.data, required this.isPremium});

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> {
  bool _showPhilosophy = false;

  @override
  void initState() {
    super.initState();
    // Karta filozoficzna pojawia się po 800ms (po zoom + confetti)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showPhilosophy = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Step 1: Zoom emoji
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.2, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Text(data.emoji, style: const TextStyle(fontSize: 72)),
            ),
            const SizedBox(height: 8),
            // Step 2: Animated days number
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: data.days),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Text(
                '$v',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                  height: 1,
                ),
              ),
            ),
            Text(
              S.t(context, data.titleKey),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // Step 3: Lottie confetti (network fallback: emoji burst)
            SizedBox(
              height: 80,
              child: Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_touohxv0.json',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text('🎉🎊✨', style: TextStyle(fontSize: 36)),
              ),
            ),
            // Step 4: Karta filozoficzna (fade in po 800ms)
            AnimatedOpacity(
              opacity: _showPhilosophy ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          S.t(context, data.messageKey),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          S.t(context, data.subKey),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (data.shareKey != null)
                  TextButton.icon(
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(S.t(context, 'quickShare')),
                    onPressed: () => Share.share(S.t(context, data.shareKey!)),
                  ),
                if (!widget.isPremium)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/paywall');
                    },
                    child: Text(
                      S.t(context, 'recoveryPlus'),
                      style: const TextStyle(color: AppColors.gold),
                    ),
                  ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(S.t(context, 'ok')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
