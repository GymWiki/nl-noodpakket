import 'dart:async';

import 'package:mijnnoodpakket/features/pro/purchase_service.dart';

/// Mock van de storelaag voor tests.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({this.price = '€ 3,99', this.reachable = true, this.owns = false, this.canBuy = true});

  String? price;
  bool reachable, owns, canBuy;
  int buyCalls = 0, restoreCalls = 0;
  final _c = StreamController<PurchaseOutcome>.broadcast();

  /// Laat de store een uitkomst melden (aankoop, annulering, ...).
  void emit(PurchaseOutcome o) => _c.add(o);

  @override
  Stream<PurchaseOutcome> get outcomes => _c.stream;

  @override
  Future<String?> loadPrice() async => price;

  @override
  Future<bool> buy() async {
    buyCalls++;
    return canBuy;
  }

  @override
  Future<RestoreResult> restore() async {
    restoreCalls++;
    return RestoreResult(reachable: reachable, owns: owns);
  }

  @override
  Future<void> dispose() async => _c.close();
}
