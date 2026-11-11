import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'pro_models.dart';
import 'purchase_service.dart';

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final s = StorePurchaseService();
  ref.onDispose(s.dispose);
  return s;
});

/// Lokale cache van het Pro-recht (instellingentabel); werkt offline.
final entitlementProvider = Provider<Entitlement>((ref) => Entitlement.fromRaw(
    ref.watch(settingsProvider.select((s) => s.value?.raw)) ?? const {}));

final proUnlockedProvider = Provider<bool>((ref) => ref.watch(entitlementProvider).unlocked);

enum ProMessage { none, thanks, restored, nothingToRestore, cancelled, pending, unavailable, error }

class ProState {
  const ProState({this.price, this.busy = false, this.message = ProMessage.none});
  final String? price;
  final bool busy;
  final ProMessage message;

  ProState copyWith({String? price, bool? busy, ProMessage? message}) =>
      ProState(price: price ?? this.price, busy: busy ?? this.busy, message: message ?? this.message);
}

class ProController extends Notifier<ProState> {
  StreamSubscription<PurchaseOutcome>? _sub;

  @override
  ProState build() {
    final svc = ref.watch(purchaseServiceProvider);
    _sub = svc.outcomes.listen(_onOutcome);
    ref.onDispose(() => _sub?.cancel());
    return const ProState();
  }

  Future<void> _save(Entitlement e) async {
    final repo = ref.read(settingsRepositoryProvider);
    for (final kv in e.toRaw().entries) {
      await repo.setRaw(kv.key, kv.value);
    }
  }

  Future<void> _onOutcome(PurchaseOutcome o) async {
    switch (o) {
      case PurchaseOutcome.purchased:
      case PurchaseOutcome.restored:
        await _save(ref.read(entitlementProvider).grant());
        state = state.copyWith(busy: false, message: o == PurchaseOutcome.purchased ? ProMessage.thanks : ProMessage.restored);
      case PurchaseOutcome.cancelled:
        state = state.copyWith(busy: false, message: ProMessage.cancelled);
      case PurchaseOutcome.pending:
        state = state.copyWith(busy: false, message: ProMessage.pending);
      case PurchaseOutcome.error:
        state = state.copyWith(busy: false, message: ProMessage.error);
    }
  }

  /// Haalt de winkelprijs op. Doet verder niets: geen popups, geen netwerk bij opstarten zonder reden.
  Future<void> loadPrice() async {
    final p = await ref.read(purchaseServiceProvider).loadPrice();
    if (p != null) state = state.copyWith(price: p);
  }

  Future<void> buy() async {
    state = state.copyWith(busy: true, message: ProMessage.none);
    final started = await ref.read(purchaseServiceProvider).buy();
    if (!started) state = state.copyWith(busy: false, message: ProMessage.unavailable);
  }

  /// "Aankoop herstellen". Een stille controle ([silent]) toont geen melding.
  Future<void> restore({bool silent = false}) async {
    if (!silent) state = state.copyWith(busy: true, message: ProMessage.none);
    final r = await ref.read(purchaseServiceProvider).restore();
    final next = ref.read(entitlementProvider).applyRestore(reachable: r.reachable, owns: r.owns, now: DateTime.now());
    await _save(next);
    if (silent) return;
    state = state.copyWith(
      busy: false,
      message: !r.reachable
          ? ProMessage.unavailable
          : r.owns
              ? ProMessage.restored
              : ProMessage.nothingToRestore,
    );
  }

  void clearMessage() => state = state.copyWith(message: ProMessage.none);
}

final proControllerProvider = NotifierProvider<ProController, ProState>(ProController.new);

/// "Niet nu" bij de rustige Pro-regel op het dashboard.
const proHintDismissedKey = 'pro_hint_dismissed';

final proHintDismissedProvider = Provider<bool>((ref) =>
    ref.watch(settingsProvider.select((s) => s.value?.raw[proHintDismissedKey])) == 'true');
