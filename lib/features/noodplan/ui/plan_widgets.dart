import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../domain/plan_models.dart';

String sectionTitle(PlanSection s) => switch (s) {
      PlanSection.household => S.planSecHousehold,
      PlanSection.contacts => S.planSecContacts,
      PlanSection.places => S.planSecPlaces,
      PlanSection.agreements => S.planSecAgreements,
      PlanSection.home => S.planSecHome,
      PlanSection.care => S.planSecCare,
      PlanSection.neighbours => S.planSecNeighbours,
    };

IconData sectionIcon(PlanSection s) => switch (s) {
      PlanSection.household => Icons.groups_outlined,
      PlanSection.contacts => Icons.contacts_outlined,
      PlanSection.places => Icons.place_outlined,
      PlanSection.agreements => Icons.handshake_outlined,
      PlanSection.home => Icons.home_outlined,
      PlanSection.care => Icons.medical_services_outlined,
      PlanSection.neighbours => Icons.diversity_3_outlined,
    };

String statusLabel(SectionStatus s) => switch (s) {
      SectionStatus.empty => S.planStatusEmpty,
      SectionStatus.partial => S.planStatusPartial,
      SectionStatus.done => S.planStatusDone,
      SectionStatus.skipped => S.planStatusSkipped,
    };

IconData statusIcon(SectionStatus s) => switch (s) {
      SectionStatus.empty => Icons.radio_button_unchecked,
      SectionStatus.partial => Icons.timelapse,
      SectionStatus.done => Icons.check_circle,
      SectionStatus.skipped => Icons.remove_circle_outline,
    };

/// Tekstveld dat tijdens het typen automatisch opslaat (met korte vertraging)
/// en bij sluiten nog een keer opslaat. De beginwaarde wordt eenmalig overgenomen.
class AutoSaveField extends StatefulWidget {
  const AutoSaveField({
    super.key,
    required this.initial,
    required this.label,
    required this.onSave,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String initial, label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final void Function(String value) onSave;

  @override
  State<AutoSaveField> createState() => _AutoSaveFieldState();
}

class _AutoSaveFieldState extends State<AutoSaveField> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);
  Timer? _timer;
  String _saved = '';

  @override
  void initState() {
    super.initState();
    _saved = widget.initial;
  }

  void _flush() {
    _timer?.cancel();
    if (_c.text != _saved) {
      _saved = _c.text;
      widget.onSave(_c.text);
    }
  }

  @override
  void dispose() {
    _flush();
    _c.dispose();
    super.dispose();
  }

  /// Wordt gebruikt door suggestie-chips.
  void setText(String v) {
    _c.text = v;
    _c.selection = TextSelection.collapsed(offset: v.length);
    _flush();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      maxLines: widget.maxLines,
      minLines: widget.maxLines > 1 ? 2 : 1,
      keyboardType: widget.keyboardType ??
          (widget.maxLines > 1 ? TextInputType.multiline : TextInputType.text),
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
      onChanged: (_) {
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 500), _flush);
      },
      onTapOutside: (_) => _flush(),
    );
  }
}

/// AutoSaveField met suggestie-chips die de tekst vullen.
class SuggestedField extends StatefulWidget {
  const SuggestedField({
    super.key,
    required this.initial,
    required this.label,
    required this.onSave,
    this.suggestions = const [],
    this.hint,
    this.maxLines = 2,
  });
  final String initial, label;
  final String? hint;
  final List<String> suggestions;
  final int maxLines;
  final void Function(String) onSave;

  @override
  State<SuggestedField> createState() => _SuggestedFieldState();
}

class _SuggestedFieldState extends State<SuggestedField> {
  final _key = GlobalKey<_AutoSaveFieldState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSaveField(
          key: _key,
          initial: widget.initial,
          label: widget.label,
          hint: widget.hint,
          maxLines: widget.maxLines,
          onSave: widget.onSave,
        ),
        if (widget.suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Semantics(
            label: S.planSuggestions,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final s in widget.suggestions)
                  ActionChip(label: Text(s), onPressed: () => _key.currentState?.setText(s)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Uitleg "Waarom is dit belangrijk?" bovenaan elk onderdeel.
class WhyCard extends StatelessWidget {
  const WhyCard(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text(S.planWhy, style: t.textTheme.titleMedium)),
            const SizedBox(height: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class FieldGap extends StatelessWidget {
  const FieldGap({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(height: 16);
}
