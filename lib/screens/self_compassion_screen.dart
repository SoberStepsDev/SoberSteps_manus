import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../constants/app_constants.dart';
import '../providers/purchase_provider.dart';
import '../l10n/strings.dart';

/// SelfCompassionScreen — Return to Self module (Faza 14)
/// 5 CBT cards:
///   1. Inner Critic Log
///   2. Self-Experiments
///   3. Compassion Letter (Future Letters bridge)
///   4. X-Marker (Daily Self Acts)
///   5. Perfectionism (PRO only)
class SelfCompassionScreen extends StatelessWidget {
  const SelfCompassionScreen({super.key});

  static const List<_Card> _cards = [
    _Card(
      id: 'inner_critic',
      icon: '🪞',
      titleKey: 'scMenuInnerCriticTitle',
      subtitleKey: 'scMenuInnerCriticSub',
      route: '/inner-critic-log',
      proOnly: false,
    ),
    _Card(
      id: 'self_experiments',
      icon: '🧪',
      titleKey: 'scMenuExperimentTitle',
      subtitleKey: 'scMenuExperimentSub',
      route: '/experiment',
      proOnly: false,
    ),
    _Card(
      id: 'compassion_letter',
      icon: '✉️',
      titleKey: 'scMenuLetterTitle',
      subtitleKey: 'scMenuLetterSub',
      route: '/future-letter-write',
      proOnly: false,
    ),
    _Card(
      id: 'daily_self_acts',
      icon: '✕',
      titleKey: 'scMenuXMarkerTitle',
      subtitleKey: 'scMenuXMarkerSub',
      route: '/x-marker',
      proOnly: false,
    ),
    _Card(
      id: 'krytyk_patterns',
      icon: '🔒',
      titleKey: 'scMenuPatternsTitle',
      subtitleKey: 'scMenuPatternsSub',
      route: '/krytyk-patterns',
      proOnly: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<PurchaseProvider>().isPro;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.t(context, 'returnToSelf')),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Philosophy tagline
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              AppConstants.philosophyTagline,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          ..._cards.map((card) => _CardTile(
                card: card,
                isPro: isPro,
              )),
        ],
      ),
    );
  }
}

class _Card {
  final String id;
  final String icon;
  final String titleKey;
  final String subtitleKey;
  final String route;
  final bool proOnly;
  const _Card({
    required this.id,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.route,
    required this.proOnly,
  });
}

class _CardTile extends StatelessWidget {
  final _Card card;
  final bool isPro;
  const _CardTile({required this.card, required this.isPro});

  @override
  Widget build(BuildContext context) {
    final locked = card.proOnly && !isPro;
    return GestureDetector(
      onTap: () {
        if (locked) {
          Navigator.pushNamed(context, '/paywall');
        } else {
          Navigator.pushNamed(context, card.route,
              arguments: card.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: locked
                ? AppColors.textSecondary.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Text(card.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.t(context, card.titleKey),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: locked
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.t(context, card.subtitleKey),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (locked)
              const Icon(Icons.lock_outline,
                  color: AppColors.gold, size: 20)
            else
              Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
