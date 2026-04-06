import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../constants/app_constants.dart';

/// RevenueCat via [purchases_flutter]. Entitlement: [AppConstants.revenueCatEntitlementId].
class PurchaseService {
  PurchaseService._();

  static bool _configured = false;

  /// Set from [PurchaseProvider.init] before or after [initialize]; invoked on every RC customer info update.
  static void Function(CustomerInfo)? onCustomerInfoUpdated;

  static Future<void> initialize() async {
    if (_configured) return;
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }
    await Purchases.configure(PurchasesConfiguration(AppConstants.revenueCatApiKey));
    Purchases.addCustomerInfoUpdateListener((CustomerInfo info) {
      onCustomerInfoUpdated?.call(info);
    });
    _configured = true;
  }

  static bool _isProFromInfo(CustomerInfo info) =>
      info.entitlements.all[AppConstants.revenueCatEntitlementId]?.isActive ?? false;

  static Future<bool> isPro() async {
    final info = await Purchases.getCustomerInfo();
    return _isProFromInfo(info);
  }

  /// Completes when the store flow ends. On user cancel: returns with no throw.
  /// Other errors are rethrown.
  static Future<void> purchasePackage(Package package) async {
    try {
      // In purchases_flutter 9.x, use PurchaseParams.package named constructor
      await Purchases.purchase(PurchaseParams.package(package));
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
        return;
      }
      rethrow;
    }
  }

  static Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();

  static Future<List<Offering>> getOfferings() async {
    final offerings = await Purchases.getOfferings();
    final out = <Offering>[];
    final current = offerings.current;
    if (current != null) out.add(current);
    for (final e in offerings.all.entries) {
      if (current != null && e.key == current.identifier) continue;
      out.add(e.value);
    }
    return out;
  }

  static Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();
}
