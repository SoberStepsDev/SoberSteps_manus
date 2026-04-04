import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../l10n/strings.dart';
import '../services/analytics_service.dart';
import '../services/purchase_service.dart';

class PurchaseProvider extends ChangeNotifier {
  final AnalyticsService _analytics = AnalyticsService();

  bool _isPremium = false;
  String? _activeProductId;
  String _abVariant = 'A';
  DateTime? _installDate;

  List<Offering> _offerings = [];
  bool _offeringsLoading = false;
  String? _purchaseErrorKey;
  String? _restoreErrorKey;

  bool get isPremium => _isPremium;
  String? get purchaseErrorKey => _purchaseErrorKey;
  String? get restoreErrorKey => _restoreErrorKey;

  /// Alias for PRO / RevenueCat entitlement [AppConstants.revenueCatEntitlementId].
  bool get isPro => _isPremium;

  String get abVariant => _abVariant;
  List<Offering> get offerings => List.unmodifiable(_offerings);
  bool get offeringsLoading => _offeringsLoading;

  /// Packages from the first (current) offering, for paywall UI.
  List<Package> get paywallPackages {
    if (_offerings.isEmpty) return [];
    return List.unmodifiable(_offerings.first.availablePackages);
  }

  int get daysSinceInstall {
    if (_installDate == null) return 0;
    return DateTime.now().difference(_installDate!).inDays;
  }

  Future<void> init() async {
    await PurchaseService.initialize();
    try {
      final info = await PurchaseService.getCustomerInfo();
      _applyCustomerInfo(info);
    } on PlatformException {
      _isPremium = false;
    }
    await loadOfferings();
    await _loadShownUpsells();
    final prefs = await SharedPreferences.getInstance();
    _abVariant = prefs.getString('ab_variant') ?? 'A';
    final installStr = prefs.getString('install_date');
    if (installStr != null) {
      _installDate = DateTime.parse(installStr);
    } else {
      _installDate = DateTime.now();
      await prefs.setString('install_date', _installDate!.toIso8601String());
    }
    notifyListeners();
  }

  Future<void> loadOfferings() async {
    _offeringsLoading = true;
    notifyListeners();
    try {
      _offerings = await PurchaseService.getOfferings();
    } on PlatformException {
      _offerings = [];
    } finally {
      _offeringsLoading = false;
      notifyListeners();
    }
  }

  void _applyCustomerInfo(CustomerInfo info) {
    final ent = info.entitlements.all[AppConstants.revenueCatEntitlementId];
    _isPremium = ent?.isActive ?? false;
    _activeProductId = ent?.productIdentifier;
    if (_activeProductId != null) {
      SharedPreferences.getInstance().then((p) => p.setString('active_product_id', _activeProductId!));
    } else {
      SharedPreferences.getInstance().then((p) => p.remove('active_product_id'));
    }
  }

  /// Buy a store package. Returns true if entitlement active after flow.
  Future<bool> purchasePackage(Package package) async {
    _purchaseErrorKey = null;
    notifyListeners();
    try {
      await PurchaseService.purchasePackage(package);
      final info = await PurchaseService.getCustomerInfo();
      _applyCustomerInfo(info);
      if (_isPremium) {
        _analytics.track('purchase_success', {'plan': package.storeProduct.identifier});
      }
      notifyListeners();
      return _isPremium;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        notifyListeners();
        return false;
      }
      _purchaseErrorKey = code == PurchasesErrorCode.networkError
          ? 'purchaseErrorNetwork'
          : 'purchaseCouldNotComplete';
      notifyListeners();
      return false;
    }
  }

  Future<bool> restore() async {
    _restoreErrorKey = null;
    notifyListeners();
    try {
      final info = await PurchaseService.restorePurchases();
      _applyCustomerInfo(info);
      notifyListeners();
      return _isPremium;
    } on PlatformException {
      _restoreErrorKey = 'restoreCouldNotComplete';
      notifyListeners();
      return false;
    }
  }

  void clearPurchaseUiErrors() {
    _purchaseErrorKey = null;
    _restoreErrorKey = null;
    notifyListeners();
  }

  Future<void> refreshFromStore() async {
    try {
      final info = await PurchaseService.getCustomerInfo();
      _applyCustomerInfo(info);
    } on PlatformException {
      _isPremium = false;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!_isPremium) {
      _activeProductId = null;
      await prefs.remove('active_product_id');
    }
    notifyListeners();
  }

  String planDisplayLabel(BuildContext context) {
    if (!_isPremium) return S.t(context, 'planFree');
    final id = _activeProductId;
    if (id == AppConstants.monthlyProductId) return S.t(context, 'planMonthly');
    if (id == AppConstants.annualProductId) return S.t(context, 'planAnnual');
    if (id == AppConstants.lifetimeProductId) return S.t(context, 'planLifetime');
    if (id == AppConstants.familyProductId) return S.t(context, 'planFamily');
    return S.t(context, 'planPremiumActive');
  }

  // Persisted set of milestone days for which upsell was already shown.
  final Set<int> _shownUpsells = {};

  bool hasShownUpsell(int milestoneDays) => _shownUpsells.contains(milestoneDays);

  Future<void> markUpsellShown(int milestoneDays) async {
    if (_shownUpsells.contains(milestoneDays)) return;
    _shownUpsells.add(milestoneDays);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'shown_upsells',
      _shownUpsells.map((d) => d.toString()).toList(),
    );
  }

  Future<void> _loadShownUpsells() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('shown_upsells') ?? [];
    _shownUpsells.addAll(raw.map(int.parse));
  }
}
