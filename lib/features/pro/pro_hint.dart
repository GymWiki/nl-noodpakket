import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calm.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import 'pro_providers.dart';

/// Zachte, niet-modale Pro-hints. Regels:
///  - nooit modaal en nooit op een veiligheidsscherm (wiki, Eerste-uur kaart, noodplan, mythes, noodhacks-waarschuwingen);
///  - alleen direct na een moment van echte waarde, door de gebruiker zelf veroorzaakt;
///  - maximaal één hint per sessie (het slot hieronder) en per scherm;
///  - met een kruisje (alleen nu verbergen) en "Niet meer tonen" (blijvend); we houden ons daaraan.
enum ProHint {
  /// Direct nadat de gebruiker een houdbaarheidsdatum invult: "Herinnering instellen? (Pro)".
  reminderAfterDate('reminder_after_date');

  const ProHint(this.id);
  final String id;
}

/// Sleutel in de instellingentabel: id's van hints die de gebruiker blijvend verborg (JSON-lijst).
const proHintsHiddenKey = 'pro_hints_hidden';

Set<String> parseHiddenHints(String? raw, {bool legacyDashboardDismissed = false}) {
  var out = <String>{};
  if (raw != null) {
    try {
      out = {for (final e in jsonDecode(raw) as List) e as String};
    } catch (_) {}
  }
  // De oude dashboardregel ("Niet nu") telt mee: wie die al wegklikte, krijgt deze hint niet.
  if (legacyDashboardDismissed) out.add(ProHint.reminderAfterDate.id);
  return out;
}

final hiddenProHintsProvider = Provider<Set<String>>((ref) {
  final raw = ref.watch(settingsProvider.select((s) => s.value?.raw[proHintsHiddenKey]));
  final legacy = ref.watch(settingsProvider.select((s) => s.value?.raw[proHintDismissedKey])) == 'true';
  return parseHiddenHints(raw, legacyDashboardDismissed: legacy);
});

/// Het ene hint-slot van deze sessie (de app-run). Wie het slot claimt, houdt het; geen ander scherm krijgt het
/// daarna nog in dezelfde sessie. Claimen mag alleen vanuit een gebruikersactie, nooit tijdens het opbouwen.
class ProHintSession extends Notifier<Object?> {
  @override
  Object? build() => null;

  bool claim(Object owner) {
    if (state == null) {
      state = owner;
      return true;
    }
    return identical(state, owner);
  }
}

final proHintSessionProvider = NotifierProvider<ProHintSession, Object?>(ProHintSession.new);

/// Blijvend verbergen ("Niet meer tonen").
Future<void> hideProHint(WidgetRef ref, ProHint hint) async {
  final hidden = {...ref.read(hiddenProHintsProvider), hint.id};
  await ref.read(settingsRepositoryProvider).setRaw(proHintsHiddenKey, jsonEncode(hidden.toList()..sort()));
}

/// Eén kleine inline-rij: de tekst opent de paywall (alleen na een tik), het kruisje sluit alleen nu,
/// "Niet meer tonen" verbergt de hint blijvend. Tikdoelen zijn minstens 48 dp; de rij past ook bij 200% tekst.
class ProHintRow extends StatelessWidget {
  const ProHintRow({super.key, required this.text, required this.onOpen, required this.onClose, required this.onHide});
  final String text;
  final VoidCallback onOpen, onClose, onHide;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    return Container(
      key: const Key('pro-hint'),
      margin: const EdgeInsets.symmetric(vertical: Space.tight),
      padding: const EdgeInsets.fromLTRB(Space.group, 4, 4, 4),
      decoration: BoxDecoration(
        color: c.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.control),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(Radii.control),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(alignment: Alignment.centerLeft, child: Text(text, style: t.textTheme.bodyLarge)),
              ),
            ),
          ),
          IconButton(
            key: const Key('pro-hint-close'),
            tooltip: S.proHintClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: onClose,
          ),
        ]),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('pro-hint-hide'),
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: onHide,
            child: const Text(S.proHintHide),
          ),
        ),
      ]),
    );
  }
}
