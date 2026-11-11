import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
import 'hacks_models.dart';

String hackLabelText(HackLabel l) => switch (l) {
      HackLabel.veilig => S.hacksLabelSafe,
      HackLabel.letop => S.hacksLabelCaution,
      HackLabel.nooit => S.hacksLabelNever,
    };

IconData hackLabelIcon(HackLabel l) => switch (l) {
      HackLabel.veilig => Icons.check_circle_rounded,
      HackLabel.letop => Icons.warning_amber_rounded,
      HackLabel.nooit => Icons.block_rounded,
    };

/// Label met pictogram én tekst, zodat betekenis nooit alleen aan kleur hangt.
class HackLabelBadge extends StatelessWidget {
  const HackLabelBadge(this.label, {super.key});
  final HackLabel label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final (bg, fg) = switch (label) {
      HackLabel.veilig => (c.secondaryContainer, c.onSecondaryContainer),
      HackLabel.letop => (c.tertiaryContainer, c.onTertiaryContainer),
      HackLabel.nooit => (c.errorContainer, c.onErrorContainer),
    };
    return Semantics(
      label: hackLabelText(label),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(hackLabelIcon(label), size: 16, color: fg),
          const SizedBox(width: 6),
          Text(hackLabelText(label),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
        ]),
      ),
    );
  }
}

/// Rij in een lijst met noodhacks.
class HackTile extends StatelessWidget {
  const HackTile({super.key, required this.hack, this.trailing, this.subtitle});
  final Hack hack;
  final Widget? trailing;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(hack.titel),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          HackLabelBadge(hack.label),
          ?subtitle,
        ]),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push('/hacks/${hack.id}'),
    );
  }
}
