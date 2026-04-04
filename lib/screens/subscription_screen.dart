import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/theme.dart';
import '../l10n/strings.dart';
import '../providers/purchase_provider.dart';

/// Subscription management: store-backed plan display, restore, platform management URLs.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchase = context.watch<PurchaseProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(S.t(context, 'subscriptionTitle')),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            S.t(context, 'subscriptionCurrentPlan'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            purchase.planDisplayLabel(context),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              await purchase.restore();
              if (!context.mounted) return;
              final rk = purchase.restoreErrorKey;
              if (rk != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.t(context, rk))),
                );
                purchase.clearPurchaseUiErrors();
              } else if (purchase.isPremium) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.t(context, 'restorePurchasesDone'))),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.t(context, 'restoreNoEntitlementFound'))),
                );
              }
            },
            child: Text(S.t(context, 'restorePurchases')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              final url = Platform.isIOS
                  ? 'https://apps.apple.com/account/subscriptions'
                  : 'https://play.google.com/store/account/subscriptions';
              _openUrl(url);
            },
            child: Text(S.t(context, 'manageSubscription')),
          ),
          const SizedBox(height: 24),
          Text(
            S.t(context, 'cancelSubscriptionInfo'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              final url = Platform.isIOS
                  ? 'https://apps.apple.com/account/subscriptions'
                  : 'https://play.google.com/store/account/subscriptions';
              _openUrl(url);
            },
            child: Text(S.t(context, 'openSubscriptionSettings')),
          ),
        ],
      ),
    );
  }
}
