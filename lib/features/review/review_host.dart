import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../dashboard/dashboard_providers.dart';
import '../noodplan/plan_providers.dart';
import 'review_models.dart';
import 'review_policy.dart';
import 'review_providers.dart';

/// Ziet een overgang van "nee" naar "ja", en negeert de allereerste waarneming (de beginwaarde bij het laden telt niet
/// als succes: wie het doel al had, krijgt daar geen verzoek voor).
class MomentEdge {
  bool? _last;

  /// Geeft true bij een overgang van false naar true.
  bool update(bool value) {
    final prev = _last;
    _last = value;
    return prev == false && value;
  }
}

/// Zit om de hele app. Beslist WANNEER er gevraagd mag worden; de controller beslist OF (via het beleid).
///
///  - Detecteert twee van de succesmomenten (Paraatheid van 3 dagen of meer, noodplan volledig); het delen van het plan
///    wordt door de deelschermen gemeld (alleen een melding, nooit een verzoek).
///  - Wacht na een succesmoment tot de gebruiker op een rustig scherm is (het dashboard, zonder dialoog of blad), de app
///    op de voorgrond staat en er [ReviewConfig.calmDelay] voorbij is. Verlaat de gebruiker dat scherm, dan stopt de teller.
///  - Heeft geen UI en toont nooit iets zelf.
class ReviewHost extends ConsumerStatefulWidget {
  const ReviewHost({super.key, required this.child, required this.routeChanges, required this.location});

  final Widget child;

  /// Meldt dat de route is veranderd (bij go_router: `router.routerDelegate`).
  final Listenable routeChanges;

  /// De huidige route, bijvoorbeeld "/start".
  final String Function() location;

  @override
  ConsumerState<ReviewHost> createState() => _ReviewHostState();
}

class _ReviewHostState extends ConsumerState<ReviewHost> with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;
  final _readiness = MomentEdge();
  final _plan = MomentEdge();

  /// De beginwaarde is vastgelegd (pas zodra de gegevens geladen zijn). Een overgang telt pas daarna.
  bool _readinessSeeded = false, _planSeeded = false;

  late final _ctl = ref.read(reviewControllerProvider);
  late final _overlay = ref.read(reviewOverlayObserverProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final s = WidgetsBinding.instance.lifecycleState;
    _foreground = s == null || s == AppLifecycleState.resumed;
    widget.routeChanges.addListener(_schedule);
    _overlay.open.addListener(_schedule);
    _ctl.changes.addListener(_schedule);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_ctl.onAppStart());
      _trySeed();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.routeChanges.removeListener(_schedule);
    _overlay.open.removeListener(_schedule);
    _ctl.changes.removeListener(_schedule);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _schedule();
  }

  bool get _itemsLoaded => ref.read(allItemsProvider).hasValue && ref.read(settingsProvider).hasValue;
  bool get _planLoaded => ref.read(planProvider).hasValue;

  /// Legt de beginwaarden vast zodra de gegevens geladen zijn, zonder dit als succes te tellen. Zo geeft het laden van
  /// de app zelf nooit een succesmoment, en telt alleen een overgang daarna.
  void _trySeed() {
    if (!mounted) return;
    if (!_readinessSeeded && _itemsLoaded) {
      _readiness.update(ref.read(readinessProvider).goalReached);
      _readinessSeeded = true;
    }
    if (!_planSeeded && _planLoaded) {
      _plan.update(ref.read(planProgressProvider).isComplete);
      _planSeeded = true;
    }
  }

  void _onReadiness(bool reached) {
    if (!_readinessSeeded) return;
    if (_readiness.update(reached)) unawaited(_ctl.successOccurred(SuccessMoment.readiness3Days));
  }

  void _onPlan(bool complete) {
    if (!_planSeeded) return;
    if (_plan.update(complete)) unawaited(_ctl.successOccurred(SuccessMoment.planComplete));
  }

  ReviewContext _context() => reviewContextFor(widget.location(), overlayOpen: _overlay.open.value > 0);

  /// Beoordeelt de timing opnieuw: een teller alleen als alles rustig is.
  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!mounted || !_foreground || !_ctl.hasFreshMoment || _context() != ReviewContext.calm) return;
    _timer = Timer(_ctl.config.calmDelay, _fire);
  }

  Future<void> _fire() async {
    _timer = null;
    // Opnieuw controleren: de gebruiker kan intussen zijn weggegaan.
    if (!mounted || !_foreground) return;
    final ctx = _context();
    if (ctx != ReviewContext.calm) return;
    await _ctl.maybeRequest(ctx);
  }

  @override
  Widget build(BuildContext context) {
    // Eerst de beginwaarden (zodra de gegevens er zijn), dan de overgangen.
    ref.listen(allItemsProvider, (_, _) => _trySeed());
    ref.listen(settingsProvider, (_, _) => _trySeed());
    ref.listen(planProvider, (_, _) => _trySeed());
    ref.listen(readinessProvider, (_, next) => _onReadiness(next.goalReached));
    ref.listen(planProgressProvider, (_, next) => _onPlan(next.isComplete));
    return widget.child;
  }
}
