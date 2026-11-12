import '../../rampenzender/rampenzender_providers.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../kluis/data/vault_controller.dart';
import '../../kluis/ui/secure_screen.dart';
import '../../noodplan/plan_providers.dart';
import '../data/shared_plan_store.dart';
import '../deel_services.dart';
import '../protocol/channel.dart';
import '../protocol/sender.dart';
import '../protocol/session_payload.dart';
import 'share_setup_screen.dart';

String shareErrorText(ShareError e) => switch (e) {
      ShareError.timeout => S.deelFailedTimeout,
      ShareError.badHandshake => S.deelFailedHandshake,
      ShareError.badFrame || ShareError.badMessage => S.deelFailedBad,
      ShareError.tooLarge => S.deelFailedTooLarge,
      ShareError.hashMismatch => S.deelFailedHash,
      ShareError.unsupported => S.deelFailedUnsupported,
      ShareError.denied => S.deelDenied,
      ShareError.aborted => S.deelAborted,
      ShareError.closed => S.deelFailedClosed,
    };

String fmtBytes(int n) {
  if (n < 1024) return '$n B';
  if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(0)} kB';
  return '${(n / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
}

enum _Phase { preparing, noNetwork, waiting, peer, sending, done, failed, expired, background }

/// QR-scherm van de afzender. Alleen bereikbaar via [ShareLaunch] (na authenticatie).
class ShareQrScreen extends ConsumerStatefulWidget {
  const ShareQrScreen({super.key, required this.launch});
  final ShareLaunch? launch;

  @override
  ConsumerState<ShareQrScreen> createState() => _ShareQrScreenState();
}

class _ShareQrScreenState extends ConsumerState<ShareQrScreen> with WidgetsBindingObserver {
  _Phase _phase = _Phase.preparing;
  ShareSenderSession? _session;
  StreamSubscription<SenderEvent>? _sub;
  Timer? _tick;
  Duration _left = ShareLimits.connectWindow;
  String _qr = '', _code = '', _device = '', _error = '', _summary = '';
  int _done = 0, _total = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.launch == null) {
      // Zonder authenticatie nooit een QR tonen.
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? context.pop() : null);
      return;
    }
    unawaited(_keepAwake(true));
    unawaited(_begin());
  }

  Future<void> _keepAwake(bool on) async {
    try {
      on ? await WakelockPlus.enable() : await WakelockPlus.disable();
    } catch (_) {}
  }

  Future<void> _begin() async {
    final addr = await ref.read(addressFinderProvider).find();
    if (!mounted) return;
    if (addr == null) {
      setState(() => _phase = _Phase.noNetwork);
      return;
    }
    try {
      final offer = await buildOffer(
        repo: ref.read(planRepositoryProvider),
        vault: ref.read(vaultProvider),
        ctl: ref.read(vaultProvider.notifier),
        draft: widget.launch!.draft,
        radioGm: ref.read(radioPrefsProvider).gm,
      );
      final s = await ref.read(senderStarterProvider)(offer, addr);
      if (!mounted) {
        await s.cancel();
        return;
      }
      _session = s;
      _sub = s.events.listen(_onEvent);
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        final end = s.expiresAt;
        if (end == null || !mounted || _phase != _Phase.waiting) return;
        setState(() => _left = end.difference(DateTime.now()).isNegative ? Duration.zero : end.difference(DateTime.now()));
      });
      setState(() {
        _qr = s.qrData;
        _phase = _Phase.waiting;
      });
    } on ShareOfferException {
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _error = S.deelNothingChosen;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _error = S.deelFailedClosed;
        });
      }
    }
  }

  void _onEvent(SenderEvent e) {
    if (!mounted) return;
    setState(() {
      switch (e) {
        case SenderPeer():
          _phase = _Phase.peer;
          _code = e.code;
          _device = e.deviceName;
        case SenderProgress():
          _phase = _Phase.sending;
          _done = e.doneBytes;
          _total = e.totalBytes;
        case SenderFinished():
          _phase = _Phase.done;
          final what = e.planSent
              ? (e.documents > 0 ? S.whatPlanDocs(e.documents) : S.whatPlan)
              : S.whatDocs(e.documents);
          _summary = what;
          unawaited(ref.read(settingsRepositoryProvider).setRaw(
                ShareLog.key,
                ShareLog(at: DateTime.now(), device: _device, what: what).encode(),
              ));
        case SenderFailed():
          _phase = _Phase.failed;
          _error = shareErrorText(e.error);
        case SenderExpired():
          _phase = _Phase.expired;
        case SenderCancelled():
          break;
      }
    });
    if (e is SenderFinished || e is SenderFailed || e is SenderExpired) {
      unawaited(_keepAwake(false));
      _tick?.cancel();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // De sessie breekt netjes af als de app naar de achtergrond gaat.
    if ((s == AppLifecycleState.paused || s == AppLifecycleState.hidden) &&
        (_phase == _Phase.waiting || _phase == _Phase.peer || _phase == _Phase.sending)) {
      unawaited(_session?.cancel());
      _tick?.cancel();
      if (mounted) setState(() => _phase = _Phase.background);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _sub?.cancel();
    unawaited(_session?.cancel());
    unawaited(_keepAwake(false));
    super.dispose();
  }

  Future<void> _cancel() async {
    await _session?.cancel();
    if (mounted) context.pop();
  }

  String _mmss(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final body = switch (_phase) {
      _Phase.preparing => const Center(child: CircularProgressIndicator()),
      _Phase.noNetwork => _msg(S.deelNoNetwork, icon: Icons.wifi_off_rounded),
      _Phase.background => _msg(S.deelBackgrounded, icon: Icons.pause_circle_outline_rounded),
      _Phase.expired => _msg(S.deelExpired, icon: Icons.timer_off_outlined),
      _Phase.failed => _msg(_error, icon: Icons.error_outline_rounded),
      _Phase.done => _msg('${S.deelDone}\n$_summary', icon: Icons.check_circle_outline_rounded, positive: true),
      _Phase.waiting => ListView(padding: Gap.page, children: [
          Text(S.deelQrHelp, style: t.textTheme.bodyLarge),
          const SizedBox(height: Gap.l),
          Center(
            child: Semantics(
              label: S.deelQrLabel,
              image: true,
              child: Container(
                color: Colors.white, // altijd wit voor de leesbaarheid, ook in donker thema
                padding: const EdgeInsets.all(16),
                child: QrImageView(key: ValueKey('qr:$_qr'), data: _qr, size: 260, backgroundColor: Colors.white, version: QrVersions.auto),
              ),
            ),
          ),
          const SizedBox(height: Gap.m),
          Center(child: Text(S.deelCountdown(_mmss(_left)), style: t.textTheme.titleMedium)),
          const SizedBox(height: 4),
          Center(child: Text(S.deelWaiting, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant))),
        ]),
      _Phase.peer => ListView(padding: Gap.page, children: [
          Semantics(header: true, child: Text(S.deelVerifyTitle, style: t.textTheme.headlineSmall)),
          const SizedBox(height: Gap.m),
          Text(S.deelVerifyBody(_device), style: t.textTheme.bodyLarge),
          const SizedBox(height: Gap.l),
          Center(
            child: Semantics(
              label: '${S.deelVerifyTitle} ${_code.split('').join(' ')}',
              child: ExcludeSemantics(
                child: Text(_code, style: t.textTheme.displayMedium?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: Gap.l),
          FilledButton(
            onPressed: () => _session?.approve(),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            child: const Text(S.deelAllow),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _session?.deny(),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            child: const Text(S.deelDeny),
          ),
        ]),
      _Phase.sending => ListView(padding: Gap.page, children: [
          Text(S.deelSending, style: t.textTheme.titleLarge),
          const SizedBox(height: Gap.m),
          LinearProgressIndicator(value: _total == 0 ? null : _done / _total, minHeight: 8, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 8),
          Text(S.deelProgress(fmtBytes(_done), fmtBytes(_total)), style: t.textTheme.bodyMedium),
        ]),
    };

    final finished = _phase == _Phase.done || _phase == _Phase.failed || _phase == _Phase.expired || _phase == _Phase.background || _phase == _Phase.noNetwork;
    return SecureScreen(
      child: PopScope(
        canPop: finished || _phase == _Phase.preparing,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_cancel());
        },
        child: Scaffold(
          appBar: AppBar(title: const Text(S.deelQrTitle), automaticallyImplyLeading: false),
          body: SafeArea(child: body),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: OutlinedButton(
                onPressed: _cancel,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text(finished ? S.deelDocsDone : S.deelCancel),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _msg(String text, {required IconData icon, bool positive = false}) => Center(
        child: Padding(
          padding: Gap.page,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: positive ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: Gap.m),
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          ]),
        ),
      );
}
