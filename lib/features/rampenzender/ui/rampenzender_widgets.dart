import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/category_palette.dart';
import '../../../core/ui.dart';
import '../data/rampenzender_models.dart';
import '../rampenzender_providers.dart';
import '../rampenzender_strings.dart';

/// Grote FM-cijfers, door schermlezers voorgelezen als "negentig komma acht megahertz".
class FmBig extends StatelessWidget {
  const FmBig(this.mhz, {super.key});
  final double mhz;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Semantics(
      label: 'FM ${speakMHz(mhz)}',
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 8,
        children: [
          Text(fmtMHz(mhz),
              style: t.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(RZ.mhz, style: t.textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

/// Eén zender met FM (groot) en DAB+ (kanaal en naam).
class StationBlock extends StatelessWidget {
  const StationBlock({
    super.key,
    required this.name,
    required this.fm,
    required this.dab,
    this.fmNote,
    this.area,
    this.badge,
  });
  final String name;
  final List<double> fm;
  final DabInfo? dab;

  /// Tekst in plaats van cijfers (NPO Radio 1: frequentie kan per plek verschillen).
  final String? fmNote;
  final String? area;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (badge != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Semantics(
            label: badge,
            child: Chip(
              avatar: Icon(Icons.check_circle_rounded, size: 18, color: c.primary),
              label: Text(badge!),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      Semantics(header: true, child: Text(name, style: t.textTheme.titleLarge)),
      if (area != null) Text(area!, style: t.textTheme.bodyLarge?.copyWith(color: c.onSurfaceVariant)),
      const SizedBox(height: 10),
      if (fm.isNotEmpty) ...[
        Text(RZ.fmLabel, style: t.textTheme.labelLarge?.copyWith(color: c.onSurfaceVariant)),
        Wrap(spacing: 24, runSpacing: 4, children: [for (final f in fm) FmBig(f)]),
      ] else if (fmNote != null) ...[
        Text(RZ.fmLabel, style: t.textTheme.labelLarge?.copyWith(color: c.onSurfaceVariant)),
        Semantics(
            label: RZ.nationalFmSemantics,
            excludeSemantics: true,
            child: Text(fmNote!, style: t.textTheme.bodyLarge)),
      ],
      if (dab != null) ...[
        const SizedBox(height: 12),
        Text(RZ.dabLabel, style: t.textTheme.labelLarge?.copyWith(color: c.onSurfaceVariant)),
        Semantics(
          label: RZ.dabSemantics(speakDab(dab!.channel), dab!.searchName),
          excludeSemantics: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(RZ.dabChannel(dab!.channel),
                style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            Text(RZ.dabSearch(dab!.searchName), style: t.textTheme.bodyLarge),
          ]),
        ),
      ],
    ]);
  }
}

/// Eén regel "Stem je radio af op: [omroep] FM [x]" voor Eerste-uur kaart en noodbalk.
/// Gebruikt de opgeslagen regio. Zonder regio of zonder gecontroleerde data een rustige aanwijzing.
class RadioTuneLine extends ConsumerWidget {
  const RadioTuneLine({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final res = ref.watch(radioResultProvider);
    final c = t.colorScheme;
    final text = radioTuneText(res);
    return Semantics(
      button: true,
      label: '$text. ${RZ.tuneLineMore}',
      excludeSemantics: true,
      child: SoftCard(
        onTap: () => context.push('/rampenzender'),
        padding: const EdgeInsets.all(14),
        color: c.surfaceContainerLowest,
        child: Row(children: [
          const IconBadge(Icons.radio_rounded, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: t.textTheme.titleSmall?.copyWith(fontSize: 16))),
          const Icon(Icons.chevron_right_rounded),
        ]),
      ),
    );
  }
}

/// De zin voor Eerste-uur kaart en noodbalk. Zuivere functie, dus goed te testen.
String radioTuneText(RadioResult? res) {
  if (res == null) return RZ.tuneLineNoRegion;
  if (!res.hasRegional) return RZ.tuneLineNoData;
  final b = res.broadcaster!;
  if (res.areas.length == 1 && res.areas.first.fm.length == 1) {
    return RZ.tuneLine(b.stationName, fmtMHz(res.areas.first.fm.first));
  }
  // Meerdere gebieden of frequenties: nooit gokken, wijs door naar het scherm met de lijst.
  return '${RZ.tuneLineMore}: ${b.stationName}';
}

/// Kaart op het dashboard onder "Volgende stap", zolang de radio niet als ingesteld is aangevinkt.
class RadioDashCard extends ConsumerWidget {
  const RadioDashCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final res = ref.watch(radioResultProvider);
    final String sub;
    if (res == null) {
      sub = RZ.dashSub;
    } else {
      sub = radioTuneText(res);
    }
    return SoftCard(
      onTap: () => context.push('/rampenzender'),
      semanticLabel: '${RZ.dashTitle}. $sub',
      child: Row(children: [
        const IconBadge(Icons.radio_rounded),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(RZ.dashTitle, style: t.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(sub, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded),
      ]),
    );
  }
}

/// Ingang op het tabblad Noodgevallen: "Rampenzender in jouw regio".
class RadioEntryCard extends ConsumerWidget {
  const RadioEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final res = ref.watch(radioResultProvider);
    final done = ref.watch(radioPrefsProvider.select((p) => p.radioSet));
    final sub = res == null ? RZ.entrySub : '${res.region.name}${done ? ': ${RZ.markedDone.toLowerCase()}' : ''}';
    return SoftCard(
      onTap: () => context.push('/rampenzender'),
      semanticLabel: '${RZ.entryTitle}. $sub',
      child: Row(children: [
        const IconBadge(Icons.radio_rounded, tint: CategoryTint.blue),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(RZ.entryTitle, style: t.textTheme.titleSmall?.copyWith(fontSize: 16)),
            Text(sub, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded),
      ]),
    );
  }
}
