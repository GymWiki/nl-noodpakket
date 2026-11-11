import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'pro_models.dart';

enum PurchaseOutcome { purchased, restored, cancelled, pending, error }

class RestoreResult {
  const RestoreResult({required this.reachable, required this.owns});
  final bool reachable, owns;
}

/// Dunne laag om de store; mockbaar in tests.
abstract class PurchaseService {
  /// Uitkomsten van de store, ook die van buiten de app om (bijv. een
  /// betaling die later wordt goedgekeurd).
  Stream<PurchaseOutcome> get outcomes;

  /// Prijs zoals de store die toont (nooit hardcoded); null als niet beschikbaar.
  Future<String?> loadPrice();

  /// Start de aankoop; false als de store niet beschikbaar is.
  Future<bool> buy();

  Future<RestoreResult> restore();

  Future<void> dispose();
}

class StorePurchaseService implements PurchaseService {
  StorePurchaseService([InAppPurchase? iap]) : _iapOverride = iap;

  final InAppPurchase? _iapOverride;
  InAppPurchase get _iap => _iapOverride ?? InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _out = StreamController<PurchaseOutcome>.broadcast();
  ProductDetails? _product;

  @override
  Stream<PurchaseOutcome> get outcomes {
    _listen();
    return _out.stream;
  }

  void _listen() {
    _sub ??= _iap.purchaseStream.listen(_onUpdates, onError: (_) => _out.add(PurchaseOutcome.error));
  }

  Future<void> _onUpdates(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID != ProCatalog.productId) continue;
      try {
        // Bevestigen (acknowledge) is verplicht, anders wordt de aankoop op Android teruggedraaid.
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      } catch (_) {}
      _out.add(switch (p.status) {
        PurchaseStatus.purchased => PurchaseOutcome.purchased,
        PurchaseStatus.restored => PurchaseOutcome.restored,
        PurchaseStatus.pending => PurchaseOutcome.pending,
        PurchaseStatus.canceled => PurchaseOutcome.cancelled,
        PurchaseStatus.error => PurchaseOutcome.error,
      });
    }
  }

  @override
  Future<String?> loadPrice() async {
    try {
      if (!await _iap.isAvailable()) return null;
      final r = await _iap.queryProductDetails({ProCatalog.productId});
      _product = r.productDetails.isEmpty ? null : r.productDetails.first;
      return _product?.price;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> buy() async {
    _listen();
    if (_product == null) await loadPrice();
    final p = _product;
    if (p == null) return false;
    try {
      return await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p));
    } catch (_) {
      return false;
    }
  }

  @override
  Future<RestoreResult> restore() async {
    _listen();
    try {
      if (!await _iap.isAvailable()) return const RestoreResult(reachable: false, owns: false);
      final got = _out.stream
          .firstWhere((o) => o == PurchaseOutcome.restored || o == PurchaseOutcome.purchased)
          .timeout(const Duration(seconds: 6), onTimeout: () => PurchaseOutcome.error);
      await _iap.restorePurchases();
      final o = await got;
      return RestoreResult(reachable: true, owns: o != PurchaseOutcome.error);
    } catch (_) {
      return const RestoreResult(reachable: false, owns: false);
    }
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _out.close();
  }
}
