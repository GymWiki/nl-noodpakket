import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../crypto/vault_crypto.dart';
import '../crypto/vault_keys.dart';
import '../data/vault_controller.dart';
import '../domain/pin_rules.dart';
import 'pin_field.dart';
import 'vault_gate.dart';

enum _Stage { intro1, intro2, pin, confirm, bio, recovery, verify }

/// Eenmalig instellen: uitleg, PIN, biometrie, herstelcode (met controle).
class VaultSetupScreen extends ConsumerStatefulWidget {
  const VaultSetupScreen({super.key});

  @override
  ConsumerState<VaultSetupScreen> createState() => _VaultSetupScreenState();
}

class _VaultSetupScreenState extends ConsumerState<VaultSetupScreen> {
  _Stage _stage = _Stage.intro1;
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  final _verify = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _written = false;
  String? _code; // wordt alleen in het geheugen bewaard
  late final int _verifyGroup = Random.secure().nextInt(8); // 0..7

  @override
  void initState() {
    super.initState();
    // Houd dit scherm open totdat de herstelcode is bevestigd.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(setupActiveProvider.notifier).set(true));
  }

  @override
  void dispose() {
    _pin.dispose();
    _pin2.dispose();
    _verify.dispose();
    _code = null;
    super.dispose();
  }

  void _go(_Stage s) => setState(() {
        _stage = s;
        _error = null;
      });

  void _pinNext() {
    final p = _pin.text;
    if (!VaultKeyManager.isValidPin(p)) return setState(() => _error = S.vaultPinTooShort);
    if (isWeakPin(p)) return setState(() => _error = S.vaultPinWeak);
    _go(_Stage.confirm);
  }

  Future<void> _confirmNext() async {
    if (_pin2.text != _pin.text) {
      _pin2.clear();
      return setState(() => _error = S.vaultPinMismatch);
    }
    final bio = ref.read(vaultProvider).bioStatus;
    _go(_Stage.bio);
    if (bio != BiometricStatus.available) return; // toont uitleg en doorgaan
  }

  Future<void> _finish({required bool withBio}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final c = ref.read(vaultProvider.notifier);
      _code = await c.external(() => c.setUp(pin: _pin.text, enableBiometrics: withBio));
      _pin.clear();
      _pin2.clear();
      if (!mounted) return;
      setState(() => _busy = false);
      _go(_Stage.recovery);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = S.vaultSetupError;
      });
    }
  }

  void _verifyNext() {
    final groups = formatRecoveryCode(_code ?? '').split(' ');
    final entered = _verify.text.replaceAll(' ', '').toUpperCase();
    if (entered != groups[_verifyGroup]) {
      return setState(() => _error = S.vaultRecoveryVerifyWrong);
    }
    _code = null;
    ref.read(setupActiveProvider.notifier).set(false);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final v = ref.watch(vaultProvider);

    Widget page({required IconData icon, required String title, required List<Widget> children}) =>
        ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(icon, size: 56, color: t.colorScheme.primary),
            const SizedBox(height: 16),
            Semantics(header: true, child: Text(title, style: t.textTheme.headlineMedium)),
            const SizedBox(height: 12),
            ...children,
          ],
        );

    Widget err() => _error == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(_error!, style: TextStyle(color: t.colorScheme.error)),
            ),
          );

    Widget footer(List<Widget> actions) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(children: actions),
        );

    late Widget body;
    late Widget bottom;

    switch (_stage) {
      case _Stage.intro1:
        body = page(icon: Icons.shield_outlined, title: S.vaultIntro1Title, children: [
          const Text(S.vaultIntro1Body),
          const SizedBox(height: 16),
          Text(S.vaultDisclaimer, style: t.textTheme.bodyMedium),
        ]);
        bottom = footer([
          const Spacer(),
          FilledButton(onPressed: () => _go(_Stage.intro2), child: const Text(S.next)),
        ]);
      case _Stage.intro2:
        body = page(icon: Icons.key_outlined, title: S.vaultIntro2Title, children: [
          const Text(S.vaultIntro2Body),
          const SizedBox(height: 16),
          Text(S.vaultHaveBackup, style: t.textTheme.bodyMedium),
        ]);
        bottom = footer([
          TextButton(onPressed: () => _go(_Stage.intro1), child: const Text(S.back)),
          const Spacer(),
          FilledButton(onPressed: () => _go(_Stage.pin), child: const Text(S.next)),
        ]);
      case _Stage.pin:
        body = page(icon: Icons.pin_outlined, title: S.vaultPinTitle, children: [
          const Text(S.vaultPinBody),
          const SizedBox(height: 16),
          PinField(controller: _pin, label: S.vaultPinLabel, autofocus: true, onSubmitted: _pinNext),
          err(),
        ]);
        bottom = footer([
          TextButton(onPressed: () => _go(_Stage.intro2), child: const Text(S.back)),
          const Spacer(),
          FilledButton(onPressed: _pinNext, child: const Text(S.next)),
        ]);
      case _Stage.confirm:
        body = page(icon: Icons.pin_outlined, title: S.vaultPinConfirmTitle, children: [
          PinField(controller: _pin2, label: S.vaultPinLabel, autofocus: true, onSubmitted: _confirmNext),
          err(),
        ]);
        bottom = footer([
          TextButton(
              onPressed: () {
                _pin2.clear();
                _go(_Stage.pin);
              },
              child: const Text(S.back)),
          const Spacer(),
          FilledButton(onPressed: _confirmNext, child: const Text(S.next)),
        ]);
      case _Stage.bio:
        final available = v.bioStatus == BiometricStatus.available;
        body = page(icon: Icons.fingerprint, title: S.vaultBioTitle, children: [
          if (available) const Text(S.vaultBioBody) else ...[
            const Text(S.vaultBioNotAvailable),
            const SizedBox(height: 12),
            Text(S.vaultNoLockscreen, style: t.textTheme.bodyMedium),
          ],
          err(),
          if (_busy) const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator(semanticsLabel: S.vaultSetupBusy)),
          ),
        ]);
        bottom = footer(available
            ? [
                TextButton(
                    onPressed: _busy ? null : () => _finish(withBio: false),
                    child: const Text(S.vaultBioSkip)),
                const Spacer(),
                FilledButton(
                    onPressed: _busy ? null : () => _finish(withBio: true),
                    child: const Text(S.vaultBioActivate)),
              ]
            : [
                const Spacer(),
                FilledButton(
                    onPressed: _busy ? null : () => _finish(withBio: false),
                    child: const Text(S.vaultContinue)),
              ]);
      case _Stage.recovery:
        final groups = formatRecoveryCode(_code ?? '').split(' ');
        body = page(icon: Icons.description_outlined, title: S.vaultRecoveryTitle, children: [
          const Text(S.vaultRecoveryBody),
          const SizedBox(height: 16),
          // Niet selecteerbaar: kopiëren naar het klembord is bewust uitgeschakeld.
          Semantics(
            label: groups.map((g) => g.split('').join(' ')).join(', '),
            excludeSemantics: true,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final g in groups)
                      Text(g,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: t.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(S.vaultRecoveryWarning,
                  style: TextStyle(color: t.colorScheme.onTertiaryContainer)),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _written,
            onChanged: (x) => setState(() => _written = x == true),
            title: const Text(S.vaultRecoveryWritten),
          ),
        ]);
        bottom = footer([
          const Spacer(),
          FilledButton(
              onPressed: _written ? () => _go(_Stage.verify) : null,
              child: const Text(S.vaultContinue)),
        ]);
      case _Stage.verify:
        body = page(icon: Icons.fact_check_outlined, title: S.vaultRecoveryTitle, children: [
          Text(S.vaultRecoveryVerifyPrompt(_verifyGroup + 1)),
          const SizedBox(height: 16),
          TextField(
            controller: _verify,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            enableInteractiveSelection: false,
            textCapitalization: TextCapitalization.characters,
            maxLength: 4,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 26, letterSpacing: 4),
            decoration: const InputDecoration(labelText: S.vaultRecoveryVerifyHint, counterText: ''),
            onSubmitted: (_) => _verifyNext(),
          ),
          err(),
        ]);
        bottom = footer([
          TextButton(onPressed: () => _go(_Stage.recovery), child: const Text(S.back)),
          const Spacer(),
          FilledButton(onPressed: _verifyNext, child: const Text(S.vaultRecoveryDone)),
        ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.vaultTitle),
        // Na het aanmaken van de kluis is terug niet meer zinvol.
        automaticallyImplyLeading: _stage.index < _Stage.recovery.index,
      ),
      body: SafeArea(child: Column(children: [Expanded(child: body), bottom])),
    );
  }
}
