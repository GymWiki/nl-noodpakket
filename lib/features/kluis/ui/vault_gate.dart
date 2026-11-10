import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../data/vault_controller.dart';
import 'secure_screen.dart';
import 'vault_lock_screen.dart';
import 'vault_setup_screen.dart';

/// Houdt het instellen open totdat de herstelcode is bevestigd, ook al is de
/// kluis technisch al ontgrendeld.
class SetupActive extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final setupActiveProvider = NotifierProvider<SetupActive, bool>(SetupActive.new);

/// Omhult elk kluisscherm: beveiligd scherm, instellen of ontgrendelen indien
/// nodig, automatisch vergrendelen (achtergrond en inactiviteit).
class VaultGate extends ConsumerStatefulWidget {
  const VaultGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<VaultGate> createState() => _VaultGateState();
}

class _VaultGateState extends ConsumerState<VaultGate> with WidgetsBindingObserver {
  Timer? _idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _idle = Timer.periodic(
      const Duration(seconds: 20),
      (_) => ref.read(vaultProvider.notifier).checkIdle(),
    );
  }

  @override
  void dispose() {
    _idle?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    final c = ref.read(vaultProvider.notifier);
    // "inactive" komt ook voor bij systeemdialogen (biometrie, rechten); alleen
    // echt naar de achtergrond gaan telt.
    if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      c.onBackground();
    } else if (s == AppLifecycleState.resumed) {
      c.onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(vaultProvider);
    final setupActive = ref.watch(setupActiveProvider);

    Widget body;
    if (v.status == VaultStatus.loading) {
      body = Scaffold(
        appBar: AppBar(title: const Text(S.vaultTitle)),
        body: Center(
          child: v.loadError
              ? const Text(S.vaultLoadError)
              : const CircularProgressIndicator(semanticsLabel: S.loading),
        ),
      );
    } else if (v.status == VaultStatus.notSetUp || setupActive) {
      body = const VaultSetupScreen();
    } else if (v.status == VaultStatus.locked) {
      body = const VaultLockScreen();
    } else {
      body = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => ref.read(vaultProvider.notifier).touch(),
        child: widget.child,
      );
    }
    return SecureScreen(child: body);
  }
}
