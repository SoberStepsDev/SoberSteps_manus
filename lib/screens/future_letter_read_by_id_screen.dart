import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../l10n/strings.dart';
import '../models/future_letter.dart';
import '../providers/future_letter_provider.dart';
import 'future_letter_read_screen.dart';

/// Loads a letter by id (e.g. deep link) then shows [FutureLetterReadScreen].
class FutureLetterReadByIdScreen extends StatefulWidget {
  final String letterId;

  const FutureLetterReadByIdScreen({super.key, required this.letterId});

  @override
  State<FutureLetterReadByIdScreen> createState() => _FutureLetterReadByIdScreenState();
}

class _FutureLetterReadByIdScreenState extends State<FutureLetterReadByIdScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FutureLetterProvider>().loadLetters();
    });
  }

  static FutureLetter? _findLetter(List<FutureLetter> letters, String id) {
    for (final l in letters) {
      if (l.id == id) return l;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FutureLetterProvider>();
    final found = _findLetter(provider.letters, widget.letterId);

    if (provider.loading && found == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(S.t(context, 'letterFromSelf'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (found == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(S.t(context, 'letterFromSelf'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              S.t(context, 'letterNotFound'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return FutureLetterReadScreen(letter: found);
  }
}
