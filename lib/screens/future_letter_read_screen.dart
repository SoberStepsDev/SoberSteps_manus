import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';
import '../models/future_letter.dart';
import '../l10n/strings.dart';
import '../formatting/locale_dates.dart';
import '../services/encryption_service.dart';

class FutureLetterReadScreen extends StatefulWidget {
  final FutureLetter letter;
  const FutureLetterReadScreen({super.key, required this.letter});

  @override
  State<FutureLetterReadScreen> createState() => _FutureLetterReadScreenState();
}

class _FutureLetterReadScreenState extends State<FutureLetterReadScreen> {
  String? _decryptedContent;

  @override
  void initState() {
    super.initState();
    EncryptionService().decrypt(widget.letter.content).then((v) {
      if (mounted) setState(() => _decryptedContent = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'letterFromSelf'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.mail_rounded, size: 64, color: AppColors.gold)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(begin: const Offset(0.5, 0.5)),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: _decryptedContent == null
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        _decryptedContent!,
                        style: const TextStyle(fontSize: 18, height: 1.6, color: AppColors.textPrimary),
                      ),
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
              const SizedBox(height: 24),
              Text(
                S.t(context, 'letterWrittenOn').replaceAll('{date}', LocaleDates.yMd(context, widget.letter.createdAt)),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
