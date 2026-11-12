import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/legal.dart';
import '../../../core/dialer.dart';
import '../../../core/theme.dart';
import '../../../core/ui.dart';
import '../data/rampenzender_models.dart';
import '../rampenzender_providers.dart';
import '../rampenzender_strings.dart';
import 'rampenzender_widgets.dart';

/// Adres van de openbare meldingenlijst. Bewust geen e-mailadres: de melding gaat via GitHub Issues,
/// zoals ook in het privacybeleid staat.
const radioReportBase = '$issuesUrl/new';

/// Meldlink met alleen gemeente, omroep en getoonde frequentie voorgevuld. Wordt alleen op initiatief
/// van de gebruiker geopend; de app verstuurt zelf niets.
Uri radioReportUri(RadioResult r, DateTime checked) {
  final freq = r.hasRegional
      ? [for (final a in r.areas) '${a.area}: ${a.fm.map(fmtMHz).join(' / ')}'].join('; ')
      : 'geen gecontroleerde frequentie';
  return Uri.parse(radioReportBase).replace(queryParameters: {
    'title': RZ.reportTitle(r.region.name),
    'body': RZ.reportBody(r.region.name, r.broadcaster?.name ?? '-', freq, DateFormat('d MMMM yyyy', 'nl_NL').format(checked)),
  });
}

/// Noodgevallen > Rampenzender in jouw regio.
class RampenzenderScreen extends ConsumerWidget {
  const RampenzenderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(radioDataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(RZ.title)),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text(S.wikiLoadError)),
        data: (d) => const _Body(),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final res = ref.watch(radioResultProvider);
    final prefs = ref.watch(radioPrefsProvider);
    final data = ref.watch(radioDataProvider).value!;
    if (res == null) {
      return ListView(padding: Gap.page, children: [
        const PageTitle(RZ.title, subtitle: RZ.intro),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: () => context.push('/rampenzender/kies'),
          icon: const Icon(Icons.search_rounded),
          label: const Text(RZ.pickTitle),
        ),
        const SizedBox(height: Gap.s),
        Text(RZ.pickNoLocation, style: t.textTheme.bodyMedium),
        const SizedBox(height: Gap.l),
        const _NationalCard(),
        const SizedBox(height: Gap.m),
        const _Explain(),
      ]);
    }

    final b = res.broadcaster;
    final chosen = prefs.area == null ? null : res.areas.where((a) => a.id == prefs.area).firstOrNull;
    final others = [for (final a in res.areas) if (a != chosen) a];

    return ListView(padding: Gap.page, children: [
      const PageTitle(RZ.title),
      SoftCard(
        child: Row(children: [
          const IconBadge(Icons.place_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                  b == null ? res.region.name : RZ.forMunicipality(res.region.name, b.name),
                  style: t.textTheme.titleMedium),
            ),
          ),
        ]),
      ),
      const SizedBox(height: Gap.m),
      if (!res.hasRegional) ...[
        SoftCard(
          color: t.colorScheme.tertiaryContainer,
          borderColor: Colors.transparent,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, child: Text(RZ.noDataTitle, style: t.textTheme.titleMedium)),
            const SizedBox(height: 6),
            Text(RZ.noData(b?.website.replaceFirst('https://', '')), style: t.textTheme.bodyLarge),
          ]),
        ),
        const SizedBox(height: Gap.m),
      ] else ...[
        SectionHeader(RZ.regionalHeading, padding: const EdgeInsets.only(bottom: Gap.s)),
        if (res.mustChoose && chosen == null)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.s),
            child: SoftCard(
              color: t.colorScheme.tertiaryContainer,
              borderColor: Colors.transparent,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(header: true, child: Text(RZ.chooseHeading, style: t.textTheme.titleMedium)),
                const SizedBox(height: 4),
                Text(RZ.chooseIntro, style: t.textTheme.bodyLarge),
              ]),
            ),
          ),
        if (chosen != null) ...[
          SoftCard(
              child: StationBlock(
                  name: b!.stationName,
                  area: chosen.area,
                  badge: RZ.myAreaChosen,
                  fm: chosen.fm,
                  dab: chosen.dab)),
          if (others.isNotEmpty) ...[
            SectionHeader(RZ.otherAreas, padding: const EdgeInsets.only(top: Gap.m, bottom: Gap.s)),
          ],
        ],
        for (final a in (chosen == null ? res.areas : others)) ...[
          SoftCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              StationBlock(
                name: res.areas.length > 1 ? RZ.livingIn(a.area) : b!.stationName,
                area: res.areas.length > 1 ? b!.stationName : a.area,
                fm: a.fm,
                dab: a.dab,
              ),
              if (a.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(a.notes, style: t.textTheme.bodyMedium),
              ],
              if (res.mustChoose) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => ref.read(radioActionsProvider).chooseArea(a.id),
                  child: const Text(RZ.myArea),
                ),
              ],
            ]),
          ),
          const SizedBox(height: Gap.s),
        ],
        if (chosen != null)
          TextButton(
              onPressed: () => ref.read(radioActionsProvider).chooseArea(null),
              child: const Text(RZ.unchoose)),
        const SizedBox(height: Gap.s),
      ],
      const _NationalCard(),
      const SizedBox(height: Gap.m),
      const _Explain(),
      const SizedBox(height: Gap.m),
      _DoneButton(done: prefs.radioSet),
      const SizedBox(height: Gap.m),
      SoftCard(
        onTap: () => context.push('/rampenzender/kies'),
        child: Row(children: [
          const IconBadge(Icons.edit_location_alt_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(RZ.change, style: t.textTheme.titleSmall?.copyWith(fontSize: 16))),
          const Icon(Icons.chevron_right_rounded),
        ]),
      ),
      const SizedBox(height: Gap.m),
      _Footer(res: res, data: data),
    ]);
  }
}

class _NationalCard extends ConsumerWidget {
  const _NationalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(radioDataProvider).value!;
    final tx = d.nationalTx;
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(RZ.nationalHeading, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        StationBlock(name: d.national.name, fm: tx.fm, dab: tx.dab, fmNote: RZ.nationalFm),
      ]),
    );
  }
}

class _Explain extends StatelessWidget {
  const _Explain();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget block(String h, String body, IconData icon) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: t.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(header: true, child: Text(h, style: t.textTheme.titleSmall)),
                const SizedBox(height: 2),
                Text(body, style: t.textTheme.bodyLarge),
              ]),
            ),
          ]),
        );
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        block(RZ.whyHeading, RZ.why, Icons.help_outline_rounded),
        block(RZ.howHeading, '${RZ.howFm}\n\n${RZ.howDab}', Icons.tune_rounded),
        block(RZ.tipHeading, RZ.tip, Icons.star_outline_rounded),
        Consumer(builder: (context, ref, _) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            block(RZ.adviceHeading, RZ.advice, Icons.radio_outlined),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/checklist'),
                icon: const Icon(Icons.checklist_rounded),
                label: const Text(RZ.adviceLink),
              ),
            ),
          ]);
        }),
      ]),
    );
  }
}

class _DoneButton extends ConsumerWidget {
  const _DoneButton({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    if (done) {
      return SoftCard(
        color: t.colorScheme.secondaryContainer,
        borderColor: Colors.transparent,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.check_circle_rounded, color: t.colorScheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(RZ.markedDone,
                    style: t.textTheme.titleMedium?.copyWith(color: t.colorScheme.onSecondaryContainer)),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(RZ.markedDoneSub,
              style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.onSecondaryContainer)),
          TextButton(
              onPressed: () => ref.read(radioActionsProvider).setRadioReady(false),
              child: const Text(RZ.undo)),
        ]),
      );
    }
    return FilledButton.icon(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
      onPressed: () => ref.read(radioActionsProvider).setRadioReady(true),
      icon: const Icon(Icons.radio_button_checked_rounded),
      label: const Text(RZ.markDone, style: TextStyle(fontSize: 18)),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.res, required this.data});
  final RadioResult res;
  final RadioData data;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final date = DateFormat('d MMMM yyyy', 'nl_NL').format(res.checkedOn);
    final single = res.areas.any((a) => a.singleSource);
    final used = {for (final a in res.areas) ...a.sourceIds, ...res.nationalTx.sourceIds};
    final srcs = [for (final s in data.sources) if (used.contains(s.id)) s];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(RZ.checkedOn(date), style: t.textTheme.titleSmall),
      const SizedBox(height: 4),
      Text(RZ.frequenciesChange, style: t.textTheme.bodyMedium),
      if (single) ...[
        const SizedBox(height: 4),
        Text(RZ.singleSource, style: t.textTheme.bodyMedium),
      ],
      const SizedBox(height: Gap.s),
      Semantics(
        button: true,
        hint: RZ.reportHint,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => openExternal(context, radioReportUri(res, res.checkedOn).toString()),
          icon: const Icon(Icons.flag_outlined),
          label: const Text(RZ.report),
        ),
      ),
      const SizedBox(height: 4),
      Text(RZ.reportHint, style: t.textTheme.bodySmall),
      if (srcs.isNotEmpty) ...[
        const SizedBox(height: Gap.m),
        Theme(
          data: t.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(RZ.sourcesHeading),
            children: [
              for (final s in srcs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minVerticalPadding: 8,
                  title: Text(s.publisher),
                  subtitle: Text(s.title),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () => openExternal(context, s.url),
                ),
            ],
          ),
        ),
      ],
      const SizedBox(height: Gap.m),
      Text(S.disclaimer, style: t.textTheme.bodySmall),
    ]);
  }
}
