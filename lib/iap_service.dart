import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'app_state.dart';

/// Handles real in-app purchases (Android Play Store to start; iOS App
/// Store later). Wraps the `in_app_purchase` plugin: queries product
/// details for [kProductIds], listens to the purchase stream, credits
/// coins on success via AppState, and completes/acknowledges purchases.
///
/// IMPORTANT: these Product IDs are placeholders. They MUST exactly
/// match the Product IDs created in Play Console (Monetize > Products >
/// In-app products) or product queries will come back empty / purchases
/// will fail. Replace the strings below once the real IDs are created.
class IapService {
  IapService._internal();
  static final IapService instance = IapService._internal();

  static const String coins100 = 'coins_100';
  static const String coins550 = 'coins_550';
  static const String coins1200 = 'coins_1200';
  static const String coins3200 = 'coins_3200';
  static const String coins13000 = 'coins_13000';
  static const String premiumPack = 'premium_pack';

  static const Set<String> kProductIds = {
    coins100,
    coins550,
    coins1200,
    coins3200,
    coins13000,
    premiumPack,
  };

  /// How many coins each consumable product grants on success.
  /// premiumPack isn't a coin amount - handle its unlock separately
  /// wherever "premium" perks are checked (e.g. AppState.isPremium).
  static const Map<String, int> coinRewards = {
    coins100: 100,
    coins550: 550,
    coins1200: 1200,
    coins3200: 3200,
    coins13000: 13000,
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> products = [];
  bool isAvailable = false;
  bool isLoading = true;
  String? loadError;

  /// Called by the UI whenever purchase state changes (loading, products
  /// updated, purchase succeeded/failed) so it can rebuild.
  VoidCallback? onStateChanged;

  /// Called specifically when a purchase completes successfully, with
  /// the product id and coins granted (null for non-coin products like
  /// premiumPack) - handy for showing a snackbar/confirmation.
  void Function(String productId, int? coinsGranted)? onPurchaseSuccess;

  Future<void> init() async {
    isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      isLoading = false;
      loadError = 'Store not available on this device';
      onStateChanged?.call();
      return;
    }

    // Listen for purchase updates (including ones resumed after app
    // restart / interrupted purchases) as early as possible.
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        loadError = 'Purchase stream error: $error';
        onStateChanged?.call();
      },
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    isLoading = true;
    onStateChanged?.call();

    final response = await _iap.queryProductDetails(kProductIds);

    if (response.error != null) {
      loadError = response.error!.message;
    } else if (response.productDetails.isEmpty) {
      loadError =
      'No products found - check that Product IDs match Play Console exactly, and that the app has an active internal test release.';
    } else {
      products = response.productDetails;
      loadError = null;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: product IDs not found: ${response.notFoundIDs}');
    }

    isLoading = false;
    onStateChanged?.call();
  }

  /// Kicks off a purchase. For consumables (coin packs), pass
  /// consumable: true so it can be bought again. Result comes back
  /// asynchronously via the purchase stream (_handlePurchaseUpdates).
  Future<void> buy(ProductDetails product, {required bool consumable}) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    if (consumable) {
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
        // Show a spinner / "processing" state in the UI if needed.
          break;

        case PurchaseStatus.error:
          debugPrint('IAP purchase error: ${purchase.error}');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _grantReward(purchase.productID);
          break;

        case PurchaseStatus.canceled:
          break;
      }

      // Every purchase (success, error, or restored) must be completed,
      // or Play Store will refund it automatically.
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
    onStateChanged?.call();
  }

  void _grantReward(String productId) {
    final coinReward = coinRewards[productId];
    if (coinReward != null) {
      AppState.instance.addBonusCoins(coinReward);
    } else if (productId == premiumPack) {
      // TODO: flip a `isPremium` flag on AppState once premium perks
      // (e.g. remove ads, unlock all levels) are defined.
    }
    onPurchaseSuccess?.call(productId, coinReward);
  }

  void dispose() {
    _subscription?.cancel();
  }
}