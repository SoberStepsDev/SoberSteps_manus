import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';
import '../providers/naomi_provider.dart';
import '../providers/purchase_provider.dart';
import '../l10n/strings.dart';
import '../services/analytics_service.dart';

/// Philosophy applied: Naomi asks — never commands, never judges
class NaomiScreen extends StatefulWidget {
  const NaomiScreen({super.key});

  @override
  State<NaomiScreen> createState() => _NaomiScreenState();
}

class _NaomiScreenState extends State<NaomiScreen> {
  final _controller = TextEditingController();
  String? _feedback;
  Map<String, String>? _nextQuestion;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureProNaomi());
    AnalyticsService().track('naomi_opened');
  }

  void _ensureProNaomi() {
    if (!mounted) return;
    context.read<NaomiProvider>().loadEntries();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t(context, 'karmaWriteFirst'))),
      );
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    try {
      final naomi = context.read<NaomiProvider>();
      final q = naomi.todayQuestion;
      await naomi.saveAnswer(q['type']!, text);
      if (!mounted) return;
      final feedback = naomi.entries.isNotEmpty ? naomi.entries.first.feedback : null;
      final nextQ = naomi.todayQuestion;
      setState(() {
        _feedback = feedback ?? S.t(context, 'naomiFeedbackDefault');
        _nextQuestion = nextQ;
      });
    } catch (e) {
      if (!mounted) return;
      /// Philosophy applied: rate limit framed as full space, alternatives offered — no blame
      final msg = e is NaomiFeedbackRateLimitException
          ? S.t(context, 'naomiRateLimit')
          : S.t(context, 'karmaError');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final naomi = context.watch<NaomiProvider>();
    final isPro = context.watch<PurchaseProvider>().isPro;
    final question = naomi.todayQuestion;

    // PRO gate — Naomi requires active Recovery+ subscription
    if (!isPro) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(S.t(context, 'naomi')), backgroundColor: AppColors.background),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('\u{1F9E0}', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 16),
                Text(S.t(context, 'naomiProAvailableTitle'),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(S.t(context, 'naomiProAvailableSubtitle'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/paywall', arguments: 'naomi_gate'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(S.t(context, 'discoverRecoveryPlus'), style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.t(context, 'naomi')),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question['type']!.replaceAll('_', ' '),
                  style: const TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 20),
              Text(
                question['question']!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
              const SizedBox(height: 28),
              TextField(
                controller: _controller,
                maxLines: 5,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: S.t(context, 'naomiHint'),
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
              const SizedBox(height: 20),
              if (_feedback != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _feedback!,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                if (_nextQuestion != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.t(context, 'naomiNextQuestion'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _nextQuestion!['question']!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                ],
                const SizedBox(height: 20),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : (_feedback == null ? _submit : () => Navigator.pop(context)),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_feedback == null ? S.t(context, 'naomiLeave') : S.t(context, 'naomiBack')),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
