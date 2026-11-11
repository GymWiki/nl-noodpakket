import 'package:flutter/material.dart';
import '../pro/pro_providers.dart';
import '../pro/pro_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
class HackTile extends ConsumerWidget {
  const HackTile({super.key, required this.hack, this.trailing, this.subtitle});
  final Hack hack;
  final Widget? trailing;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = hackLocked(hack, pro: ref.watch(proUnlockedProvider));
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(hack.titel),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          HackLabelBadge(hack.label),
          if (locked) const ProBadge(),
          ?subtitle,
        ]),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: () => openHack(context, ref, hack),
    );
  }
}

/// Details van een hack zijn Pro, behalve proefhacks en mythes.
bool hackLocked(Hack h, {required bool pro}) => !h.isFree && !pro;

/// Opent de hack, of de (niet blokkerende) paywall als die Pro vereist.
void openHack(BuildContext context, WidgetRef ref, Hack h) {
  if (hackLocked(h, pro: ref.read(proUnlockedProvider))) {
    showPaywall(context);
  } else {
    context.push('/hacks/${h.id}');
  }
}


/// Wat je ziet als je een Pro-hack opent zonder Pro (bijv. via een directe link):
/// titel en label, en een rustige uitnodiging. Geen details.
class HackLockedView extends StatelessWidget {
  const HackLockedView({super.key, required this.hack});
  final Hack hack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(hack.titel, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Wrap(spacing: 8, children: [HackLabelBadge(hack.label), const ProBadge()]),
          const SizedBox(height: 12),
          Text(hack.titel, style: t.textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(S.hackProHint, style: t.textTheme.bodyLarge),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => showPaywall(context),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text(S.hackProOnly),
          ),
        ],
      ),
    );
  }
}
