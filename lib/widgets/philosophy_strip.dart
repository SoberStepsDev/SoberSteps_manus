import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../l10n/strings.dart';

class PhilosophyStrip extends StatelessWidget {
  const PhilosophyStrip({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10, horizontal: 16),
      child: Text(
        S.t(context, 'smilePath'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          letterSpacing: 0.3,
          color: AppColors.textSecondary.withValues(alpha: 0.95),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
