import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/philosophy_core.dart';

/// DailyPerspectiveWidget — "Uśmiech · Perspektywa · Droga"
///
/// 9 filozoficznych promptów z Fazy 11 (MirrorMind seed data).
/// Rotacja deterministyczna wg dnia roku — zero wywołań sieciowych.
/// Każdy prompt przechodzi przez [PhilosophyCore.apply] pipeline.
class DailyPerspectiveWidget extends StatelessWidget {
  const DailyPerspectiveWidget({super.key});

  /// 9 promptów z Fazy 11 — MirrorMind philosophical seeds
  static const List<String> _prompts = [
    // 1. Uśmiech — ciekawość zamiast imperatywu
    'Co byś zrobił dzisiaj, gdybyś wiedział, że 80% wystarczy?',
    // 2. Perspektywa — brak mety
    'Ciekawe, co się wydarzy, jeśli zostaniesz tu jeszcze jeden dzień…',
    // 3. Droga — nieskończona mapa
    'Droga sama się tworzy pod Twoimi stopami. Nie musisz jej planować.',
    // 4. Uśmiech — obserwacja zamiast walki
    'Możesz poobserwować tę myśl z ciekawością — nie musisz jej słuchać.',
    // 5. Perspektywa — bez linii końcowej
    'Patrz, jak daleko już jesteś. Nie ma mety — jest tylko droga.',
    // 6. Droga — powrót do siebie
    'Wróciłeś do siebie. To wystarczy na dziś.',
    // 7. Uśmiech — niedoskonałość jako krok
    'Może warto sprawdzić, co się stanie, jeśli pozwolisz sobie na 80%?',
    // 8. Perspektywa — zmiana perspektywy
    'Każdy krok, który robisz, jest już całym krokiem.',
    // 9. Droga — jutro też jest droga
    'Jutro też będzie droga. Dziś wystarczy być tu.',
  ];

  String get _todayPrompt {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return PhilosophyCore.apply(_prompts[dayOfYear % _prompts.length]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.10),
            AppColors.gold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '✦',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _todayPrompt,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                    height: 1.55,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
