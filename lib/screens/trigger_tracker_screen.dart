import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app/theme.dart';
import '../l10n/strings.dart';
import '../providers/journal_provider.dart';
import '../providers/purchase_provider.dart';

class TriggerTrackerScreen extends StatelessWidget {
  const TriggerTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalProvider>();
    final isPremium = context.watch<PurchaseProvider>().isPremium;
    final entries = journal.entries;

    // Count triggers
    final triggerCounts = <String, int>{};
    final moodByDay = <int, List<int>>{};
    final cravingByDay = <int, List<int>>{};

    for (final e in entries) {
      for (final t in e.triggers) {
        triggerCounts[t] = (triggerCounts[t] ?? 0) + 1;
      }
      final weekday = e.createdAt.weekday;
      moodByDay.putIfAbsent(weekday, () => []).add(e.mood);
      cravingByDay.putIfAbsent(weekday, () => []).add(e.cravingLevel);
    }

    final sortedTriggers = triggerCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'triggerAnalysis'))),
      body: entries.isEmpty
          ? Center(child: Text(S.t(context, 'doCheckinToSee'), style: const TextStyle(color: AppColors.textSecondary)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.t(context, 'yourTriggers'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  if (sortedTriggers.isEmpty)
                    Text(S.t(context, 'noTriggerData'), style: const TextStyle(color: AppColors.textSecondary))
                  else
                    ...sortedTriggers.map((e) => _TriggerBar(
                          label: S.t(context, 'trigger_${e.key}'),
                          count: e.value,
                          maxCount: sortedTriggers.first.value,
                        )),

                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: Text(S.t(context, 'cravingByWeekday'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                      if (!isPremium) const Icon(Icons.lock, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isPremium)
                    SizedBox(height: 200, child: _WeekChart(dataByDay: cravingByDay, maxVal: 10, color: AppColors.error))
                  else
                    _PremiumLock(
                      label: S.t(context, 'unlock30DayCharts'),
                      onTap: () => Navigator.pushNamed(context, '/paywall'),
                    ),

                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: Text(S.t(context, 'moodByWeekday'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                      if (!isPremium) const Icon(Icons.lock, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isPremium)
                    SizedBox(height: 200, child: _WeekChart(dataByDay: moodByDay, maxVal: 5, color: AppColors.primary))
                  else
                    _PremiumLock(
                      label: S.t(context, 'unlockMoodAnalysis'),
                      onTap: () => Navigator.pushNamed(context, '/paywall'),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _TriggerBar extends StatelessWidget {
  final String label;
  final int count;
  final int maxCount;

  const _TriggerBar({required this.label, required this.count, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              Text('$count×', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: count / maxCount,
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(Color.lerp(AppColors.gold, AppColors.error, count / maxCount)!),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  final Map<int, List<int>> dataByDay;
  final int maxVal;
  final Color color;

  const _WeekChart({required this.dataByDay, required this.maxVal, required this.color});

  static const _dayNames = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: maxVal.toDouble(),
        barGroups: List.generate(7, (i) {
          final vals = dataByDay[i + 1] ?? [];
          final avg = vals.isEmpty ? 0.0 : vals.reduce((a, b) => a + b) / vals.length;
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: avg, color: color, width: 20, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
          ]);
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, _) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_dayNames[val.toInt()], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ),
          )),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _PremiumLock extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PremiumLock({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, color: AppColors.gold, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.gold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
