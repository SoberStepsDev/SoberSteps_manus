import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app/theme.dart';
import '../providers/future_letter_provider.dart';
import '../models/future_letter.dart';
import 'future_letter_read_screen.dart';
import '../l10n/strings.dart';

class FutureLetterListScreen extends StatefulWidget {
  const FutureLetterListScreen({super.key});

  @override
  State<FutureLetterListScreen> createState() => _FutureLetterListScreenState();
}

class _FutureLetterListScreenState extends State<FutureLetterListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FutureLetterProvider>().loadLetters();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FutureLetterProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'yourLetters'))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.of(context).pushNamed('/future-letter-write'),
        child: const Icon(Icons.add),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.letters.isEmpty
              ? Center(child: Text(S.t(context, 'noLetters'), style: const TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.letters.length,
                  itemBuilder: (context, i) {
                    final letter = provider.letters[i];
                    return _LetterCard(letter: letter);
                  },
                ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  final FutureLetter letter;
  const _LetterCard({required this.letter});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    return GestureDetector(
      onTap: letter.isDelivered
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => FutureLetterReadScreen(letter: letter)))
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: letter.isDelivered ? AppColors.gold : AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Icon(
              letter.isDelivered ? Icons.mail : Icons.mail_outline,
              color: letter.isDelivered ? AppColors.gold : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    letter.isDelivered ? S.t(context, 'letterDelivered') : S.t(context, 'letterInTransit'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: letter.isDelivered ? AppColors.gold : AppColors.textPrimary,
                    ),
                  ),
                  Text('${S.t(context, 'delivery')} ${dateFormat.format(letter.deliverAt)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (letter.isDelivered) const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
