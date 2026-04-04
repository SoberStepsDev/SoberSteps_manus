import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/theme.dart';
import '../l10n/strings.dart';
import '../models/rts_diagnostic.dart';

class RtsDiagnosticScreen extends StatefulWidget {
  const RtsDiagnosticScreen({super.key});

  @override
  State<RtsDiagnosticScreen> createState() => _RtsDiagnosticScreenState();
}

class _RtsDiagnosticScreenState extends State<RtsDiagnosticScreen> {
  final _controller = PageController();
  final List<int?> _answers = List.filled(RtsDiagnostic.questions.length, null);
  int _page = 0;
  bool _showResult = false;
  int? _score;
  RtsDiagnosticProfile? _profile;

  Future<void> _persist() async {
    if (_score == null || _profile == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rts_diagnostic_score', _score!);
    await prefs.setString('rts_diagnostic_profile', RtsDiagnostic.profileKey(_profile!));
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        await Supabase.instance.client.from('profiles').update({
          'rts_diagnostic_score': _score,
          'rts_diagnostic_profile': RtsDiagnostic.profileKey(_profile!),
        }).eq('id', uid);
      } catch (_) {}
    }
  }

  void _selectOption(int qIndex, int optionIndex) {
    HapticFeedback.lightImpact();
    setState(() => _answers[qIndex] = optionIndex);
    if (qIndex < RtsDiagnostic.questions.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      final filled = _answers.every((e) => e != null);
      if (!filled) return;
      final s = RtsDiagnostic.scoreAnswers(_answers.cast<int>());
      setState(() {
        _score = s;
        _profile = RtsDiagnostic.profileForScore(s);
        _showResult = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.t(context, 'rtsDiagnosticTitle')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _showResult && _profile != null
          ? _buildResult()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        '${_page + 1} / ${RtsDiagnostic.questions.length}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_page + 1) / RtsDiagnostic.questions.length,
                            minHeight: 4,
                            backgroundColor: AppColors.surfaceLight,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: RtsDiagnostic.questions.length,
                    itemBuilder: (context, i) {
                      final q = RtsDiagnostic.questions[i];
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              q.prompt,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ...List.generate(4, (j) {
                              final sel = _answers[i] == j;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: sel ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _selectOption(i, j),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 28,
                                            child: Text(
                                              String.fromCharCode(65 + j),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: sel ? AppColors.primary : AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              q.options[j],
                                              style: TextStyle(
                                                color: sel ? AppColors.textPrimary : AppColors.textSecondary,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResult() {
    final p = _profile!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              RtsDiagnostic.profileTitle(p),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: $_score / 30',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Text(
              RtsDiagnostic.profileBody(p),
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 15),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _persist();
                  if (mounted) Navigator.of(context).pop();
                },
                child: Text(S.t(context, 'continue')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
