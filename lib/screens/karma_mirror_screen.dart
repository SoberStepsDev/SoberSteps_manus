import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../l10n/strings.dart';
import '../models/return_to_self.dart';
import '../providers/karma_provider.dart';
import '../services/analytics_service.dart';

/// Karma Mirror — `/karma-mirror` → evening question from [KarmaProvider.todayQuestionIndex]
/// + `karmaEveningQ*` keys in [strings.dart]; answers saved to `return_to_self_karma`.
class KarmaMirrorScreen extends StatefulWidget {
  const KarmaMirrorScreen({super.key});

  @override
  State<KarmaMirrorScreen> createState() => _KarmaMirrorScreenState();
}

class _KarmaMirrorScreenState extends State<KarmaMirrorScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<KarmaProvider>().loadEntries();
      AnalyticsService().track('karma_mirror_opened');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _qKey(int i) => 'karmaEveningQ$i';

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t(context, 'karmaWriteFirst'))),
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      await context.read<KarmaProvider>().saveAnswer(text);
      if (!mounted) return;
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t(context, 'karmaThanks'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t(context, 'karmaError'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final karma = context.watch<KarmaProvider>();
    final idx = karma.todayQuestionIndex;
    final question = S.t(context, _qKey(idx));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(S.t(context, 'karmaMirror')),
      ),
      body: karma.loading && karma.entries.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                  Text(
                    S.t(context, 'eveningQuestion'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.t(context, 'karmaMirrorDesc'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLines: 5,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: S.t(context, 'karmaHint'),
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(S.t(context, 'karmaLeave')),
                    ),
                  ),
                  if (karma.entries.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      S.t(context, 'karmaLookBack'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...karma.entries.map((e) => _KarmaHistoryTile(entry: e, karma: karma)),
                  ],
                  ],
                ),
              ),
    );
  }
}

class _KarmaHistoryTile extends StatelessWidget {
  final KarmaEntry entry;
  final KarmaProvider karma;

  const _KarmaHistoryTile({required this.entry, required this.karma});

  @override
  Widget build(BuildContext context) {
    final enc = entry.answerEncrypted;
    if (enc == null || enc.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder<String>(
        future: karma.decryptAnswer(enc),
        builder: (context, snap) {
          final text = snap.data ?? '…';
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.timestamp.year}-${entry.timestamp.month.toString().padLeft(2, '0')}-${entry.timestamp.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
