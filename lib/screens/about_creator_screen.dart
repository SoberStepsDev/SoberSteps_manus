import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../l10n/strings.dart';

class AboutCreatorScreen extends StatelessWidget {
  const AboutCreatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'aboutCreatorTitle'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.t(context, 'aboutCreatorHeading'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              S.t(context, 'aboutCreatorBody'),
              style: const TextStyle(fontSize: 15, height: 1.7, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Text(
              S.t(context, 'smilePath'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}
