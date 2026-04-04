import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/sobriety_provider.dart';
import '../providers/journal_provider.dart';
import '../l10n/strings.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  Widget build(BuildContext context) {
    final sobriety = context.watch<SobrietyProvider>();
    final journal = context.watch<JournalProvider>();
    final checkinsThisWeek = journal.entries.where((e) {
      final n = DateTime.now();
      final d = e.createdAt;
      return n.difference(d).inDays <= 7;
    }).length;
    const cravingSurfThisWeek = 0;
    final streakDays = journal.consecutiveCheckins;

    final goals = [
      _GoalItem(
        icon: Icons.edit_note_rounded,
        title: S.t(context, 'checkins'),
        current: checkinsThisWeek,
        target: 7,
        unit: S.t(context, 'days'),
      ),
      _GoalItem(
        icon: Icons.waves_rounded,
        title: S.t(context, 'cravingSurf'),
        current: cravingSurfThisWeek,
        target: 3,
        unit: S.t(context, 'sessions'),
      ),
      _GoalItem(
        icon: Icons.local_fire_department_rounded,
        title: S.t(context, 'streak'),
        current: streakDays,
        target: 7,
        unit: S.t(context, 'days'),
      ),
    ];

    final nextMilestone = sobriety.nextMilestone;
    final progress = nextMilestone != null ? sobriety.progressToNextMilestone : 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'goalsAndRewards'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (nextMilestone != null) ...[
            Text(S.t(context, 'nextMilestone'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, backgroundColor: AppColors.surfaceLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold)),
            const SizedBox(height: 8),
            Text('${sobriety.daysSober} / $nextMilestone ${S.t(context, 'days')}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 32),
          ],
          Text(S.t(context, 'weeklyGoals'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ...goals.map((g) => _GoalCard(
            icon: g.icon,
            title: g.title,
            current: g.current,
            target: g.target,
            unit: g.unit,
          )),
        ],
      ),
    );
  }
}

class _GoalItem {
  final IconData icon;
  final String title;
  final int current;
  final int target;
  final String unit;
  _GoalItem({required this.icon, required this.title, required this.current, required this.target, required this.unit});
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int current;
  final int target;
  final String unit;

  const _GoalCard({required this.icon, required this.title, required this.current, required this.target, required this.unit});

  @override
  Widget build(BuildContext context) {
    final done = current >= target;
    final pct = (current / target).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? AppColors.gold : AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: done ? AppColors.gold : AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: pct, backgroundColor: AppColors.surfaceLight, valueColor: AlwaysStoppedAnimation<Color>(done ? AppColors.gold : AppColors.primary)),
                const SizedBox(height: 4),
                Text('$current / $target $unit', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (done) const Icon(Icons.check_circle, color: AppColors.gold),
        ],
      ),
    );
  }
}
