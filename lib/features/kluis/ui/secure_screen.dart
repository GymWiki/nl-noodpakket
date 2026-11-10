import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('nl.mijnnoodpakket/secure');
int _refs = 0;

Future<void> _set(bool on) async {
  try {
    await _channel.invokeMethod('setSecure', on);
  } catch (_) {
    // Geen native kant (tests, desktop): negeren.
  }
}

/// Beveiligt het scherm zolang dit widget in de boom staat: Android FLAG_SECURE
/// (geen screenshots, schermopname of preview in recente apps) en op iOS een
/// dekkende laag in de app-switcher en bij schermopname.
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});
  final Widget child;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    if (_refs++ == 0) _set(true);
  }

  @override
  void dispose() {
    if (--_refs <= 0) {
      _refs = 0;
      _set(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
