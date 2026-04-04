import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/purchase_provider.dart';

/// Wraps [child] with a blur overlay when user is not PRO.
/// Tapping the overlay navigates to PaywallScreen with [trigger].
///
/// Usage:
/// ```dart
/// ProGateWidget(
///   trigger: 'self_compassion',
///   child: SelfCompassionScreen(),
/// )
/// ```
class ProGateWidget extends StatelessWidget {
  final Widget child;
  final String trigger;
  final String? label;

  const ProGateWidget({
    super.key,
    required this.child,
    this.trigger = 'pro_gate',
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<PurchaseProvider>().isPro;
    if (isPro) return child;

    return Stack(
      children: [
        // Blurred content underneath
        IgnorePointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: child,
          ),
        ),
        // Overlay CTA
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(
              '/paywall',
              arguments: trigger,
            ),
            child: Container(
              color: AppColors.background.withOpacity(0.55),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: AppColors.gold,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      label ?? 'Dostępne w Recovery+',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Odblokuj pełny dostęp',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pushNamed(
                        '/paywall',
                        arguments: trigger,
                      ),
                      child: const Text(
                        'Wypróbuj Recovery+ za darmo',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
