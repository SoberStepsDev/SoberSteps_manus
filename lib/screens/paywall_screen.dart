import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../app/theme.dart';
import '../constants/app_constants.dart';
import '../providers/purchase_provider.dart';
import '../l10n/strings.dart';
import '../services/analytics_service.dart';

class PaywallScreen extends StatefulWidget {
  final String trigger;
  const PaywallScreen({super.key, this.trigger = 'manual'});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Package? _selected;
  Timer? _fomoTimer;
  Duration _remaining = const Duration(hours: 23, minutes: 59, seconds: 59);
  final _analytics = AnalyticsService();

  static int _packageRank(Package a) {
    final id = a.storeProduct.identifier;
    if (id == AppConstants.annualProductId) return 0;
    if (id == AppConstants.monthlyProductId) return 1;
    if (id == AppConstants.familyProductId) return 2;
    if (id == AppConstants.lifetimeProductId) return 3;
    return 4;
  }

  bool _packageVisible(Package p, PurchaseProvider purchase) {
    if (p.storeProduct.identifier == AppConstants.lifetimeProductId) {
      return purchase.daysSinceInstall >= 90;
    }
    return true;
  }

  List<Package> _visiblePackages(PurchaseProvider purchase) {
    final list = purchase.paywallPackages.where((p) => _packageVisible(p, purchase)).toList();
    list.sort((a, b) => _packageRank(a).compareTo(_packageRank(b)));
    return list;
  }

  @override
  void initState() {
    super.initState();
    final purchase = context.read<PurchaseProvider>();
    _analytics.track('paywall_view', {'trigger': widget.trigger, 'ab_variant': purchase.abVariant});
    if (purchase.daysSinceInstall > 3) {
      _fomoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining.inSeconds > 0) {
          setState(() => _remaining -= const Duration(seconds: 1));
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await purchase.loadOfferings();
      if (!mounted) return;
      final pkgs = _visiblePackages(purchase);
      if (pkgs.isEmpty) return;
      setState(() {
        Package? annual;
        for (final p in pkgs) {
          if (p.storeProduct.identifier == AppConstants.annualProductId) {
            annual = p;
            break;
          }
        }
        _selected = annual ?? pkgs.first;
      });
    });
  }

  @override
  void dispose() {
    _fomoTimer?.cancel();
    super.dispose();
  }

  String _periodLabel(BuildContext context, Package p) {
    switch (p.packageType) {
      case PackageType.monthly:
        return S.t(context, 'subPeriodMonthly');
      case PackageType.annual:
        return S.t(context, 'subPeriodAnnual');
      case PackageType.weekly:
        return S.t(context, 'subPeriodWeekly');
      case PackageType.lifetime:
        return S.t(context, 'subPeriodLifetime');
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchase = context.watch<PurchaseProvider>();
    final pkgs = _visiblePackages(purchase);
    if (_selected != null && !pkgs.contains(_selected)) {
      _selected = pkgs.isNotEmpty ? pkgs.first : null;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Tooltip(
          message: S.t(context, 'cancel'),
          child: Semantics(
            label: S.t(context, 'cancel'),
            button: true,
            child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ),
        ),
      ),
      body: SafeArea(
        child: purchase.offeringsLoading && pkgs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(S.t(context, 'paywallLoadingOfferings'), style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildHeadline(context, purchase.abVariant),
                    const SizedBox(height: 24),
                    ..._buildBenefitCards(),
                    const SizedBox(height: 24),
                    _buildSocialProof(),
                    const SizedBox(height: 24),
                    if (pkgs.isEmpty)
                      Text(
                        S.t(context, 'paywallNoPlans'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      ...pkgs.map((p) {
                        final sel = _selected?.identifier == p.identifier;
                        final best = p.storeProduct.identifier == AppConstants.annualProductId;
                        final period = _periodLabel(context, p);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPlanCard(
                            context,
                            p,
                            selected: sel,
                            bestValue: best,
                            period: period,
                          ),
                        );
                      }),
                    if (purchase.daysSinceInstall > 3) ...[
                      const SizedBox(height: 16),
                      _buildFomoTimer(),
                    ],
                    const SizedBox(height: 24),
                    _buildCtaButton(context, purchase, pkgs),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await purchase.restore();
                        if (!context.mounted) return;
                        final rk = purchase.restoreErrorKey;
                        if (rk != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(S.t(context, rk))),
                          );
                          purchase.clearPurchaseUiErrors();
                        } else if (purchase.isPremium) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(S.t(context, 'restoreNoEntitlementFound'))),
                          );
                        }
                      },
                      child: Text(S.t(context, 'restorePurchases'), style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeadline(BuildContext context, String variant) {
    final texts = {
      'A': S.t(context, 'unlockFree7Days'),
      'B': S.t(context, 'paywallHeadlineB'),
      'C': S.t(context, 'paywallHeadlineC'),
    };
    return Text(
      texts[variant] ?? texts['A']!,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
    );
  }

  List<Widget> _buildBenefitCards() {
    final benefits = [
      (Icons.mic, S.t(context, 'paywallBenefit1')),
      (Icons.nightlight_round, S.t(context, 'paywallBenefit2')),
      (Icons.mail_outline, S.t(context, 'paywallBenefit3')),
      (Icons.shield, S.t(context, 'paywallBenefit4')),
    ];
    return benefits
        .map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(b.$1, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Text(b.$2, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15))),
                  ],
                ),
              ),
            ))
        .toList();
  }

  Widget _buildSocialProof() {
    return Text(
      S.t(context, 'paywallSocialProof'),
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    Package package, {
    required bool selected,
    required bool bestValue,
    required String period,
  }) {
    final sp = package.storeProduct;
    return GestureDetector(
      onTap: () => setState(() => _selected = package),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: bestValue ? AppColors.gold : (selected ? AppColors.primary : AppColors.surfaceLight),
            width: bestValue ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sp.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                      if (bestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            S.t(context, 'subscriptionBadgeBestValue'),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.background),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (period.isNotEmpty)
                    Text(period, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(sp.priceString, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: bestValue ? AppColors.gold : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFomoTimer() {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Text('${S.t(context, 'trialExpiresIn')} $h:$m:$s', style: const TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600));
  }

  Widget _buildCtaButton(BuildContext context, PurchaseProvider purchase, List<Package> pkgs) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppColors.gold,
        ),
        onPressed: _selected == null || pkgs.isEmpty
            ? null
            : () async {
                HapticFeedback.lightImpact();
                final pkg = _selected!;
                final success = await purchase.purchasePackage(pkg);
                if (!context.mounted) return;
                final err = purchase.purchaseErrorKey;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(context, err))));
                  purchase.clearPurchaseUiErrors();
                } else if (success) {
                  Navigator.of(context).pushReplacementNamed('/premium-welcome');
                }
              },
        child: Text(S.t(context, 'startFreeTrial'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
    ).animate(onPlay: (c) => c.repeat(period: 3000.ms)).shimmer(duration: 800.ms, color: AppColors.textPrimary.withValues(alpha: 0.3));
  }
}
