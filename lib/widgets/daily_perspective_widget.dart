import 'dart:math';
import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/philosophy_core.dart';

/// DailyPerspectiveWidget — "Uśmiech · Perspektywa · Droga"
/// Displays a daily rotating philosophy-aligned message on HomeScreen.
/// No network call — deterministic by day-of-year for zero latency.
class DailyPerspectiveWidget extends StatelessWidget {
  const DailyPerspectiveWidget({super.key});

  static const List<String> _perspectives = [
    'Ciekawe, co przyniesie ten dzień…',
    'Droga sama się tworzy pod Twoimi stopami.',
    '80% wystarczy — jesteś już tu.',
    'Uśmiech wobec nieznanego to odwaga.',
    'Nie ma mety — jest tylko droga.',
    'Każdy krok to cały krok.',
    'Patrz, jak daleko już jesteś.',
    'Jutro też będzie droga.',
    'Bycie tu jest wystarczające.',
    'Ciekawość jest silniejsza niż strach.',
    'Perspektywa zmienia wszystko.',
    'Wróciłeś do siebie — to wystarczy.',
    'Droga trwa dalej, nawet gdy stoisz.',
    'Uśmiech to nie zaprzeczenie — to wybór.',
    'Każdy oddech to nowy początek.',
  ];

  String get _todayPerspective {
    final dayOfYear = DateTime.now().difference(
      DateTime(DateTime.now().year, 1, 1),
    ).inDays;
    return PhilosophyCore.apply(
      _perspectives[dayOfYear % _perspectives.length],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.gold.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            '✦',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _todayPerspective,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
