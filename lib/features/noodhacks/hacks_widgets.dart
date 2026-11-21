import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../../core/theme/category_palette.dart';
import '../../core/ui.dart';
import 'hacks_providers.dart';
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

/// Icoonbolletje van een hackcategorie. De mythes gebruiken het bestaande
/// waarschuwingspatroon (geen eigen categoriekleur).
class HackCategoryBadge extends StatelessWidget {
  const HackCategoryBadge(this.categoryId, {super.key, this.size = 36});
  final String categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final tint = hackTint(categoryId);
    return IconBadge(
      hackCategoryIconById(categoryId),
      size: size,
      tint: tint,
      background: tint == null ? c.errorContainer : null,
      foreground: tint == null ? c.onErrorContainer : null,
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
      leading: HackCategoryBadge(hack.categorie),
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
/// Na een aankoop opent de directe actie ("Open deze noodhack") de aangetikte hack.
Future<void> openHack(BuildContext context, WidgetRef ref, Hack h) async {
  if (hackLocked(h, pro: ref.read(proUnlockedProvider))) {
    final r = await showPaywall(context, request: PaywallRequest.hack(h.id));
    if (r == PaywallResult.action && context.mounted && ref.read(proUnlockedProvider)) {
      context.push('/hacks/${h.id}');
    }
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
            onPressed: () => showPaywall(context, request: PaywallRequest.hack(hack.id)),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text(S.hackProOnly),
          ),
        ],
      ),
    );
  }
}


String fmtTimer(int seconds) {
  final m = seconds ~/ 60, s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Aftellende timer voor één stap (bijvoorbeeld 10 minuten een brandwond koelen). Start pas na een tik; geen geluid
/// of melding op de achtergrond: het scherm blijft aan in de stap-voor-stap modus.
class StepTimer extends StatefulWidget {
  const StepTimer({super.key, required this.seconds});
  final int seconds;

  @override
  State<StepTimer> createState() => _StepTimerState();
}

class _StepTimerState extends State<StepTimer> {
  late int _left = widget.seconds;
  Timer? _t;

  bool get _running => _t != null;

  @override
  void didUpdateWidget(StepTimer old) {
    super.didUpdateWidget(old);
    if (old.seconds != widget.seconds) _reset();
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _start() {
    if (_left <= 0) _left = widget.seconds;
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        _t = null;
        HapticFeedback.mediumImpact();
        setState(() {});
      }
    });
    setState(() {});
  }

  void _pause() {
    _t?.cancel();
    setState(() => _t = null);
  }

  void _reset() {
    _t?.cancel();
    setState(() {
      _t = null;
      _left = widget.seconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final done = _left <= 0;
    return Semantics(
      container: true,
      liveRegion: done,
      label: done ? S.hacksTimerDone : S.hacksTimerLabel(fmtTimer(_left)),
      child: SoftCard(
        child: Row(children: [
          const Icon(Icons.timer_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(done ? S.hacksTimerDone : fmtTimer(_left),
                style: t.textTheme.headlineSmall, key: const Key('hack-timer-text')),
          ),
          if (!done)
            FilledButton.tonal(
              key: const Key('hack-timer-toggle'),
              onPressed: _running ? _pause : _start,
              child: Text(_running ? S.hacksTimerPause : S.hacksTimerStart),
            ),
          TextButton(key: const Key('hack-timer-reset'), onPressed: _reset, child: const Text(S.hacksTimerReset)),
        ]),
      ),
    );
  }
}
