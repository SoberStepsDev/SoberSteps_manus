import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../constants/app_constants.dart';
import '../providers/future_letter_provider.dart';
import '../l10n/strings.dart';

class FutureLetterWriteScreen extends StatefulWidget {
  const FutureLetterWriteScreen({super.key});

  @override
  State<FutureLetterWriteScreen> createState() => _FutureLetterWriteScreenState();
}

class _FutureLetterWriteScreenState extends State<FutureLetterWriteScreen> {
  final _contentController = TextEditingController();
  DateTime? _deliverAt;
  bool _saving = false;

  static const _presetKeys = ['preset1Month', 'preset3Months', 'preset6Months', 'preset1Year'];
  static const _presetDays = [30, 90, 180, 365];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'writeToFutureSelf'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.t(context, 'writeToFutureSelf'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              TextField(
                controller: _contentController,
                maxLength: AppConstants.maxNoteLength,
                maxLines: 8,
                decoration: InputDecoration(hintText: S.t(context, 'writeToSelfIn')),
              ),
              const SizedBox(height: 24),
              Text(S.t(context, 'whenToDeliver'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_presetKeys.length, (i) {
                  final label = S.t(context, _presetKeys[i]);
                  final days = _presetDays[i];
                  final date = DateTime.now().add(Duration(days: days));
                  final selected = _deliverAt != null &&
                      _deliverAt!.difference(date).inDays.abs() < 2;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.3),
                    backgroundColor: AppColors.surfaceLight,
                    labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary),
                    onSelected: (_) => setState(() => _deliverAt = date),
                  );
                }),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(S.t(context, 'sendLetter')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(context, 'writeSomething'))));
      return;
    }
    if (_deliverAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(context, 'pickDeliveryDate'))));
      return;
    }
    if (AppConstants.urlRegex.hasMatch(content)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(context, 'linksNotAllowed'))));
      return;
    }

    setState(() => _saving = true);
    final result = await context.read<FutureLetterProvider>().createLetter(content, _deliverAt!);
    setState(() => _saving = false);

    if (!mounted) return;
    if (result == 'offline') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(context, 'savedLocally'))));
      Navigator.pop(context);
    } else if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(context, 'letterSent'))));
      Navigator.pop(context);
    }
  }
}
