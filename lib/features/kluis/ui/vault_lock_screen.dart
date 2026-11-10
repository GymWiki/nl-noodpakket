import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../crypto/vault_keys.dart';
import '../data/vault_controller.dart';
import '../domain/pin_rules.dart';
import 'pin_field.dart';

/// Ontgrendelscherm: biometrie als standaard, PIN als alternatief.
class VaultLockScreen extends ConsumerStatefulWidget {
  const VaultLockScreen({super.key});

  @override
  ConsumerState<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends ConsumerState<VaultLockScreen> {
  final _pin = TextEditingController();
  String? _message;
  bool _busy = false;
  bool _triedBio = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoBio());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _autoBio() async {
    final v = ref.read(vaultProvider);
    if (_triedBio || !v.bioEnabled || v.bioStatus != BiometricStatus.available) return;
    _triedBio = true;
    await _bio();
  }

  Future<void> _bio() async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await ref.read(vaultProvider.notifier).external(
          () => ref.read(vaultProvider.notifier).unlockWithBiometrics(),
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = switch (r) {
        UnlockResult.needsPin => S.vaultBioChanged,
        UnlockResult.error => S.vaultBioFailed,
        _ => null,
      };
    });
  }

  Future<void> _submit() async {
    if (_busy || _pin.text.isEmpty) return;
    setState(() => _busy = true);
    final r = await ref.read(vaultProvider.notifier).unlockWithPin(_pin.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = switch (r) {
        UnlockResult.wrongPin => S.vaultWrongPin,
        UnlockResult.lockedOut => null,
        UnlockResult.error => S.vaultUnlockError,
        _ => null,
      };
    });
    _pin.clear();
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(vaultProvider);
    final t = Theme.of(context);
    final until = v.lockedUntil;
    final remaining = until?.difference(DateTime.now());
    final lockedOut = remaining != null && !remaining.isNegative && remaining > Duration.zero;
    final showBio = v.bioEnabled && v.bioStatus == BiometricStatus.available;

    return Scaffold(
      appBar: AppBar(title: const Text(S.vaultTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.lock_outline, size: 56, color: t.colorScheme.primary),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(S.vaultLockedTitle, style: t.textTheme.headlineMedium),
            ),
            const SizedBox(height: 8),
            const Text(S.vaultLockedBody),
            const SizedBox(height: 24),
            if (showBio)
              FilledButton.icon(
                onPressed: _busy ? null : _bio,
                icon: const Icon(Icons.fingerprint),
                label: const Text(S.vaultUnlockBio),
              ),
            if (showBio) const SizedBox(height: 16),
            PinField(
              controller: _pin,
              label: S.vaultPinLabel,
              onSubmitted: lockedOut ? null : _submit,
            ),
            const SizedBox(height: 8),
            if (lockedOut)
              Text(S.vaultLockedOut(formatWait(remaining)),
                  style: TextStyle(color: t.colorScheme.error),
                  semanticsLabel: S.vaultLockedOut(formatWait(remaining)))
            else if (_message != null)
              Semantics(
                liveRegion: true,
                child: Text(_message!, style: TextStyle(color: t.colorScheme.error)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy || lockedOut ? null : _submit,
              child: const Text(S.vaultUnlock),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const VaultRecoveryScreen()),
              ),
              child: const Text(S.vaultForgotPin),
            ),
            const SizedBox(height: 16),
            Text(S.vaultDisclaimer,
                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// PIN vergeten: herstelcode invoeren en een nieuwe PIN kiezen.
class VaultRecoveryScreen extends ConsumerStatefulWidget {
  const VaultRecoveryScreen({super.key});

  @override
  ConsumerState<VaultRecoveryScreen> createState() => _VaultRecoveryScreenState();
}

class _VaultRecoveryScreenState extends ConsumerState<VaultRecoveryScreen> {
  final _code = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _pin.dispose();
    _pin2.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final pin = _pin.text;
    if (!VaultKeyManager.isValidPin(pin)) {
      setState(() => _error = S.vaultPinTooShort);
      return;
    }
    if (isWeakPin(pin)) {
      setState(() => _error = S.vaultPinWeak);
      return;
    }
    if (pin != _pin2.text) {
      setState(() => _error = S.vaultPinMismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ref.read(vaultProvider.notifier).recoverWithCode(_code.text, pin);
    if (!mounted) return;
    if (r == UnlockResult.ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = r == UnlockResult.wrongPin ? S.vaultRecoveryWrong : S.vaultUnlockError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.vaultRecoveryEnterTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextField(
              controller: _code,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: S.vaultRecoveryEnterHint),
            ),
            const SizedBox(height: 24),
            Text(S.vaultNewPinTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            PinField(controller: _pin, label: S.vaultNewPin),
            const SizedBox(height: 12),
            PinField(controller: _pin2, label: S.vaultPinConfirmTitle),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _go,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(S.vaultUnlock),
            ),
          ],
        ),
      ),
    );
  }
}
