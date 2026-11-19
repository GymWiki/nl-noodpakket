import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/calm.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme.dart';
import 'paywall_config.dart';
import 'paywall_sheet.dart';
import 'pro_models.dart';
import 'pro_providers.dart';

export 'paywall_config.dart' show PaywallRequest;
export 'paywall_sheet.dart' show PaywallResult, proMessageText, showPaywall;

/// Is [feature] beschikbaar? Zo niet: toon de rustige paywall (niet blokkerend), met de inhoud van [request].
/// Geeft terug of de functie daarna beschikbaar is.
Future<bool> requirePro(
  BuildContext context,
  WidgetRef ref,
  ProFeature feature, {
  PaywallRequest request = const PaywallRequest.general(),
}) async {
  if (ProCatalog.isAllowed(feature, pro: ref.read(proUnlockedProvider))) return true;
  await showPaywall(context, request: request);
  return ref.read(proUnlockedProvider);
}

/// Klein, rustig label. Nooit in een alarmkleur.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Text(S.proBadge,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.onPrimaryContainer)),
    );
  }
}

/// Sectie in Instellingen; "Aankoop herstellen" is altijd zichtbaar.
class ProSettingsSection extends ConsumerWidget {
  const ProSettingsSection({super.key});

  /// Algemene inhoud; de directe actie na de aankoop brengt je naar de noodhacks.
  Future<void> _open(BuildContext context) async {
    final r = await showPaywall(context);
    if (r == PaywallResult.action && context.mounted) context.push('/hacks');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final pro = ref.watch(proUnlockedProvider);
    final st = ref.watch(proControllerProvider);
    final msg = proMessageText(st.message);
    // Eén rustige rij voor Pro; "Aankoop herstellen" blijft altijd zichtbaar.
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: Space.section, bottom: Space.tight),
        child: Semantics(header: true, child: Text(S.proName, style: t.textTheme.titleMedium)),
      ),
      CalmListGroup(children: [
        StatusRow(
          title: pro ? S.proSettingsOn : S.proSettingsOff,
          subtitle: S.proSettingsSub,
          onTap: pro ? null : () => _open(context),
          trailing: pro ? null : Text(S.proSettingsMore, style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.primary)),
        ),
        ListTile(
          title: const Text(S.paywallRestore),
          enabled: !st.busy,
          onTap: st.busy ? null : () => ref.read(proControllerProvider.notifier).restore(),
        ),
      ]),
      if (msg != null) Padding(padding: const EdgeInsets.only(top: Space.tight), child: Text(msg, style: t.textTheme.bodyMedium)),
    ]);
  }
}
