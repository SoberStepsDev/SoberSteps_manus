import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/theme.dart';
import '../widgets/pro_gate_widget.dart';
import '../services/analytics_service.dart';
import '../l10n/strings.dart';

/// KrytykPatternsScreen — PRO only.
/// Shows: hourly heatmap, 14-day trend, top 3 words from inner_critic_log.
class KrytykPatternsScreen extends StatefulWidget {
  const KrytykPatternsScreen({super.key});
  @override
  State<KrytykPatternsScreen> createState() => _KrytykPatternsScreenState();
}

class _KrytykPatternsScreenState extends State<KrytykPatternsScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    AnalyticsService().track(AnalyticsService.eSelfCompassionOpened, {'card': 'krytyk_patterns'});
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 14)).toIso8601String();
      final data = await Supabase.instance.client
          .from('inner_critic_log')
          .select()
          .eq('user_id', user.id)
          .gte('created_at', cutoff)
          .order('created_at', ascending: true);
      setState(() { _entries = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  // Hourly heatmap: count entries per hour of day
  List<int> get _hourlyCount {
    final counts = List<int>.filled(24, 0);
    for (final e in _entries) {
      final dt = DateTime.tryParse(e['created_at'] ?? '');
      if (dt != null) counts[dt.hour]++;
    }
    return counts;
  }

  // 14-day trend: count per day
  List<int> get _dailyCount {
    final counts = List<int>.filled(14, 0);
    final now = DateTime.now();
    for (final e in _entries) {
      final dt = DateTime.tryParse(e['created_at'] ?? '');
      if (dt == null) continue;
      final diff = now.difference(dt).inDays;
      if (diff >= 0 && diff < 14) counts[13 - diff]++;
    }
    return counts;
  }

  // Top 3 words (excluding stop words)
  List<MapEntry<String, int>> get _topWords {
    const stop = {'i', 'w', 'z', 'na', 'do', 'się', 'to', 'że', 'nie', 'a', 'o', 'jak', 'co', 'jest', 'już', 'tak', 'ale', 'bo', 'by', 'za', 'po', 'mi', 'mnie', 'mój', 'moje'};
    final freq = <String, int>{};
    for (final e in _entries) {
      final words = (e['content'] ?? '').toLowerCase().split(RegExp(r'[^a-ząćęłńóśźż]+'));
      for (final w in words) {
        if (w.length > 3 && !stop.contains(w)) freq[w] = (freq[w] ?? 0) + 1;
      }
    }
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(S.t(context, 'krytykPatternsTitle'), style: const TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ProGateWidget(
        trigger: 'krytyk_patterns',
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(S.t(context, 'krytykPatternsEmpty'), style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(S.t(context, 'krytykHourlyHeatmap')),
                        const SizedBox(height: 8),
                        _HourlyHeatmap(counts: _hourlyCount, tooltipTemplate: S.t(context, 'krytykHeatmapTooltip')),
                        const SizedBox(height: 24),
                        _SectionTitle(S.t(context, 'krytykTrend14Days')),
                        const SizedBox(height: 8),
                        _DailyTrend(counts: _dailyCount),
                        const SizedBox(height: 24),
                        _SectionTitle(S.t(context, 'krytykTop3Words')),
                        const SizedBox(height: 8),
                        ..._topWords.map((e) => _WordRow(word: e.key, count: e.value)),
                        if (_topWords.isEmpty) Text(S.t(context, 'krytykNotEnoughData'), style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8));
}

class _HourlyHeatmap extends StatelessWidget {
  final List<int> counts;
  final String tooltipTemplate;
  const _HourlyHeatmap({required this.counts, required this.tooltipTemplate});
  @override
  Widget build(BuildContext context) {
    final maxVal = counts.reduce((a, b) => a > b ? a : b).clamp(1, 999);
    return Wrap(
      spacing: 4, runSpacing: 4,
      children: List.generate(24, (h) {
        final intensity = counts[h] / maxVal;
        return Tooltip(
          message: tooltipTemplate.replaceAll('{hour}', '$h').replaceAll('{count}', '${counts[h]}'),
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1 + intensity * 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Text('$h', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9))),
          ),
        );
      }),
    );
  }
}

class _DailyTrend extends StatelessWidget {
  final List<int> counts;
  const _DailyTrend({required this.counts});
  @override
  Widget build(BuildContext context) {
    final maxVal = counts.reduce((a, b) => a > b ? a : b).clamp(1, 999).toDouble();
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(14, (i) {
          final h = (counts[i] / maxVal * 70).clamp(4.0, 70.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(height: h, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 2),
                  Text('${14 - i}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 8)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  final String word; final int count;
  const _WordRow({required this.word, required this.count});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Expanded(child: Text(word, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
      Text('$count ×', style: const TextStyle(color: AppColors.textSecondary)),
    ]),
  );
}
