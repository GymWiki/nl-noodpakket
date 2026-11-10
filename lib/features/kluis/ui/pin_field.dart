import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Numeriek PIN-veld: verborgen invoer, geen suggesties, geen kopiëren.
class PinField extends StatelessWidget {
  const PinField({
    super.key,
    required this.controller,
    required this.label,
    this.onSubmitted,
    this.autofocus = false,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback? onSubmitted;
  final bool autofocus;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: true,
      obscuringCharacter: '●',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      enableSuggestions: false,
      autocorrect: false,
      enableInteractiveSelection: false,
      maxLength: 16,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 26, letterSpacing: 6),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        errorText: errorText,
      ),
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
    );
  }
}
