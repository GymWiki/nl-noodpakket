import 'package:flutter/material.dart';

import '../../core/l10n/strings.dart';
import '../../domain/models.dart';

/// Huishoudsamenstelling bewerken; gedeeld door onboarding en instellingen.
class HouseholdForm extends StatelessWidget {
  const HouseholdForm({super.key, required this.value, required this.onChanged});
  final Household value;
  final ValueChanged<Household> onChanged;

  @override
  Widget build(BuildContext context) {
    final h = value;
    return Column(children: [
      _Stepper(S.hhAdults, h.adults, 1, (v) => onChanged(h.copyWith(adults: v))),
      _Stepper(S.hhChildren, h.children, 0, (v) => onChanged(h.copyWith(children: v))),
      _Stepper(S.hhBabies, h.babies, 0, (v) => onChanged(h.copyWith(babies: v))),
      _Stepper(S.hhSeniors, h.seniors, 0, (v) => onChanged(h.copyWith(seniors: v))),
      _Stepper(S.hhPets, h.pets, 0, (v) => onChanged(h.copyWith(pets: v))),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(S.hhMedication),
        subtitle: const Text(S.hhMedicationSub),
        value: h.usesMedication,
        onChanged: (v) => onChanged(h.copyWith(usesMedication: v)),
      ),
    ]);
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper(this.label, this.value, this.min, this.onChanged);
  final String label;
  final int value, min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: S.hhCount(label, value),
      child: Row(children: [
        Expanded(
            child: ExcludeSemantics(
                child:
                    Text(label, style: Theme.of(context).textTheme.titleMedium))),
        IconButton.filledTonal(
          tooltip: S.hhLess(label),
          iconSize: 28,
          constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 44,
          child: ExcludeSemantics(
            child: Text('$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        IconButton.filledTonal(
          tooltip: S.hhMore(label),
          iconSize: 28,
          constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          onPressed: value < 20 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ]),
    );
  }
}
