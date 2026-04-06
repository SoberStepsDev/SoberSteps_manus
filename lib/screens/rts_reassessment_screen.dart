import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../app/theme.dart';
import '../models/rts_diagnostic.dart';
import '../services/analytics_service.dart';
import '../l10n/strings.dart';

/// RTSReassessmentScreen — re-takes RTS diagnostic after 30 days.
/// Compares new score vs baseline, shows delta and insight.
/// Table: rts_scores (id, user_id, score, assessed_at)
class RTSReassessmentScreen extends StatefulWidget {
  const RTSReassessmentScreen({super.key});
  @override
  State<RTSReassessmentScreen> createState() => _RTSReassessmentScreenState();
}

class _RTSReassessmentScreenState extends State<RTSReassessmentScreen> {
  final _controller = PageController();
  final List<int?> _answers = List.filled(RtsDiagnostic.questions.length, null);
  int _page = 0;
  bool _showResult = false;
  int? _newScore;
  int? _baselineScore;
  RtsDiagnosticProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadBaseline();
    AnalyticsService().track('rts_reassessment_started');
  }

  Future<void> _loadBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    final b = prefs.getInt('rts_diagnostic_score');
    if (mounted) setState(() => _baselineScore = b);
  }

  void _selectOption(int qIndex, int optionIndex) {
    HapticFeedback.lightImpact();
    setState(() => _answers[qIndex] = optionIndex);
    if (qIndex < RtsDiagnostic.questions.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      setState(() => _page = qIndex + 1);
    } else {
      final filled = _answers.every((e) => e != null);
      if (!filled) return;
      final s = RtsDiagnostic.scoreAnswers(_answers.cast<int>());
      final profile = RtsDiagnostic.profileForScore(s);
      setState(() { _newScore = s; _profile = profile; _showResult = true; });
      _persist(s, profile);
      AnalyticsService().track('rts_reassessment_completed', {
        'new_score': s,
        'baseline_score': _baselineScore ?? 0,
        'delta': s - (_baselineScore ?? 0),
      });
    }
  }

  Future<void> _persist(int score, RtsDiagnosticProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rts_diagnostic_score', score);
    await prefs.setString('rts_diagnostic_profile', RtsDiagnostic.profileKey(profile));
    await prefs.setString('rts_reassessment_date', DateTime.now().toIso8601String());
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        await Supabase.instance.client.from('rts_scores').insert({
          'id': const Uuid().v4(),
          'user_id': uid,
          'score': score,
          'assessed_at': DateTime.now().toIso8601String(),
        });
        await Supabase.instance.client.from('profiles').update({
          'rts_diagnostic_score': score,
          'rts_diagnostic_profile': RtsDiagnostic.profileKey(profile),
        }).eq('id', uid);
      } catch (_) {}
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_showResult) return _buildResult();
    final questions = RtsDiagnostic.questions;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(S.t(context, 'rtsReassessmentTitle'), style: const TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_page + 1) / questions.length,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: questions.length,
        itemBuilder: (_, i) {
          final q = questions[i];
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1} / ${questions.length}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 16),
                Text(q.prompt, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4)),
                const SizedBox(height: 32),
                ...List.generate(q.options.length, (oi) => GestureDetector(
                  onTap: () => _selectOption(i, oi),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _answers[i] == oi ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _answers[i] == oi ? AppColors.primary : Colors.transparent),
                    ),
                    child: Text(q.options[oi], style: TextStyle(color: _answers[i] == oi ? AppColors.primary : AppColors.textPrimary, fontSize: 15)),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResult() {
    final delta = (_newScore ?? 0) - (_baselineScore ?? 0);
    final improved = delta > 0;
    final deltaStr = delta > 0 ? '+$delta' : '$delta';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(_profile != null ? RtsDiagnostic.profileEmoji(_profile!) : '🪞', style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(S.t(context, 'rtsScoreResult').replaceAll('{score}', '$_newScore').replaceAll('{max}', '${RtsDiagnostic.maxScore}'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (_baselineScore != null) ...[
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(S.t(context, 'rtsDeltaVsBaseline'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  Text(deltaStr, style: TextStyle(color: improved ? Colors.greenAccent : Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 4),
                _DeltaBar(baseline: _baselineScore!, current: _newScore ?? 0, max: RtsDiagnostic.maxScore),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                child: Text(_deltaInsight(context, delta), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(S.t(context, 'rtsBackToPath'), style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _deltaInsight(BuildContext context, int delta) {
    if (delta >= 5) return S.t(context, 'rtsInsightDelta5');
    if (delta > 0) return S.t(context, 'rtsInsightDeltaPos');
    if (delta == 0) return S.t(context, 'rtsInsightDelta0');
    return S.t(context, 'rtsInsightDeltaNeg');
  }
}

class _DeltaBar extends StatelessWidget {
  final int baseline; final int current; final int max;
  const _DeltaBar({required this.baseline, required this.current, required this.max});
  @override
  Widget build(BuildContext context) {
    final bPct = baseline / max;
    final cPct = current / max;
    return SizedBox(
      height: 12,
      child: Stack(children: [
        Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6))),
        FractionallySizedBox(widthFactor: bPct.clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(color: AppColors.textSecondary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(6)))),
        FractionallySizedBox(widthFactor: cPct.clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(color: current >= baseline ? Colors.greenAccent.withValues(alpha: 0.7) : Colors.redAccent.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)))),
      ]),
    );
  }
}
