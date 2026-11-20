import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'paywall_config.dart';
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

/// Welke opzet van de paywall gebruikt wordt. Overschrijfbaar in tests; per release één onderdeel wijzigen.
final paywallConfigProvider = Provider<PaywallConfig>((ref) => defaultPaywallConfig);

/// "Apple" of "Google", voor de zin "Betaling via ...".
final storeNameProvider = Provider<String>((ref) =>
    defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS ? 'Apple' : 'Google');

/// Alleen op Apple kan Family Sharing worden genoemd (en alleen als de config-vlag aan staat).
final storeIsAppleProvider = Provider<bool>((ref) => ref.watch(storeNameProvider) == 'Apple');

enum ProMessage { none, thanks, restored, nothingToRestore, cancelled, pending, unavailable, error }

/// Toestand van het ophalen van de winkelprijs. Nooit eeuwig "laden": na een time-out wordt het [unavailable].
enum PriceStatus { loading, ready, unavailable }

class ProState {
  const ProState({this.price, this.priceStatus = PriceStatus.loading, this.busy = false, this.message = ProMessage.none});
  final String? price;
  final PriceStatus priceStatus;
  final bool busy;
  final ProMessage message;

  ProState copyWith({String? price, PriceStatus? priceStatus, bool? busy, ProMessage? message}) => ProState(
      price: price ?? this.price,
      priceStatus: priceStatus ?? this.priceStatus,
      busy: busy ?? this.busy,
      message: message ?? this.message);
}

class ProController extends Notifier<ProState> {
  StreamSubscription<PurchaseOutcome>? _sub;
  Timer? _watchdog;

  /// Hoe lang we wachten op de winkel voordat de prijs als "niet beschikbaar" geldt.
  static const priceTimeout = Duration(seconds: 8);

  /// Als de winkel na een aankoopstart niets meldt, geven we de knoppen na deze tijd weer vrij.
  static const busyTimeout = Duration(seconds: 90);

  @override
  ProState build() {
    final svc = ref.watch(purchaseServiceProvider);
    _sub = svc.outcomes.listen(_onOutcome);
    ref.onDispose(() {
      _sub?.cancel();
      _watchdog?.cancel();
    });
    return const ProState();
  }

  void _stopWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
  }

  void _startWatchdog() {
    _stopWatchdog();
    _watchdog = Timer(busyTimeout, () {
      if (state.busy) state = state.copyWith(busy: false);
    });
  }

  Future<void> _save(Entitlement e) async {
    final repo = ref.read(settingsRepositoryProvider);
    for (final kv in e.toRaw().entries) {
      await repo.setRaw(kv.key, kv.value);
    }
  }

  Future<void> _onOutcome(PurchaseOutcome o) async {
    _stopWatchdog();
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
    state = state.copyWith(priceStatus: PriceStatus.loading);
    String? p;
    try {
      p = await ref.read(purchaseServiceProvider).loadPrice().timeout(priceTimeout, onTimeout: () => null);
    } catch (_) {
      p = null;
    }
    state = p != null
        ? state.copyWith(price: p, priceStatus: PriceStatus.ready)
        : state.copyWith(priceStatus: PriceStatus.unavailable);
  }

  Future<void> buy() async {
    state = state.copyWith(busy: true, message: ProMessage.none);
    _startWatchdog();
    final started = await ref.read(purchaseServiceProvider).buy();
    if (!started) {
      _stopWatchdog();
      state = state.copyWith(busy: false, message: ProMessage.unavailable);
    }
  }

  /// "Aankoop herstellen". Een stille controle ([silent]) toont geen melding.
  Future<void> restore({bool silent = false}) async {
    if (!silent) state = state.copyWith(busy: true, message: ProMessage.none);
    final r = await ref.read(purchaseServiceProvider).restore();
    _stopWatchdog();
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

/// Oude sleutel van de dashboardregel ("Niet nu"); die regel bestaat niet meer. De waarde telt nog mee bij de zachte
/// hints (zie pro_hint.dart): wie hem al wegklikte, krijgt de herinneringshint niet.
const proHintDismissedKey = 'pro_hint_dismissed';
