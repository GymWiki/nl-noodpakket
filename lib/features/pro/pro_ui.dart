import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calm.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme.dart';
import 'pro_models.dart';
import 'pro_providers.dart';

/// Is [feature] beschikbaar? Zo niet: toon de rustige paywall (niet blokkerend).
/// Geeft terug of de functie daarna beschikbaar is.
Future<bool> requirePro(BuildContext context, WidgetRef ref, ProFeature feature) async {
  if (ProCatalog.isAllowed(feature, pro: ref.read(proUnlockedProvider))) return true;
  await showPaywall(context);
  return ref.read(proUnlockedProvider);
}

Future<void> showPaywall(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const PaywallSheet(),
    );

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

String? proMessageText(ProMessage m) => switch (m) {
      ProMessage.thanks => S.proMsgThanks,
      ProMessage.restored => S.proMsgRestored,
      ProMessage.nothingToRestore => S.proMsgNothing,
      ProMessage.cancelled => S.proMsgCancelled,
      ProMessage.pending => S.proMsgPending,
      ProMessage.unavailable => S.proMsgUnavailable,
      ProMessage.error => S.proMsgError,
      ProMessage.none => null,
    };

class PaywallSheet extends ConsumerStatefulWidget {
  const PaywallSheet({super.key});

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(proControllerProvider.notifier).loadPrice());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final st = ref.watch(proControllerProvider);
    final pro = ref.watch(proUnlockedProvider);
    final ctl = ref.read(proControllerProvider.notifier);
    final msg = proMessageText(st.message);

    // Na een geslaagde aankoop sluit het blad vanzelf.
    ref.listen(proUnlockedProvider, (prev, now) {
      if (now && prev == false && Navigator.of(context).canPop()) Navigator.of(context).pop();
    });

    Widget item(String text, Color color) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.check_rounded, size: 20, color: color)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: t.textTheme.bodyLarge)),
          ]),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.section),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: Text(S.paywallTitle, style: t.textTheme.headlineSmall)),
          const SizedBox(height: Space.group),
          Text(S.paywallGetTitle, style: t.textTheme.titleMedium),
          const SizedBox(height: Space.tight),
          item(S.paywallGet1, c.primary),
          item(S.paywallGet2, c.primary),
          item(S.paywallGet3, c.primary),
          const SizedBox(height: Space.tight),
          if (msg != null) ...[
            Text(msg, style: t.textTheme.bodyMedium),
            const SizedBox(height: Space.group),
          ],
          if (pro)
            Text(S.proSettingsOn, style: t.textTheme.titleSmall)
          else ...[
            FilledButton(
              onPressed: st.busy ? null : ctl.buy,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(st.price == null ? S.paywallUnlockNoPrice : S.paywallUnlock(st.price!),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 6),
            Center(child: Text(S.paywallNoSub, style: t.textTheme.bodySmall, textAlign: TextAlign.center)),
            if (st.price == null)
              Center(child: Text(S.paywallPriceLoading, style: t.textTheme.bodySmall, textAlign: TextAlign.center)),
          ],
          const SizedBox(height: Space.group),
          // Wat gratis blijft: kort, en uit te klappen.
          ExpandableSection(
            title: S.paywallFreeTitle,
            children: [
              item(S.paywallFree1, c.secondary),
              item(S.paywallFree2, c.secondary),
              item(S.paywallFree3, c.secondary),
              item(S.paywallFree4, c.secondary),
              item(S.paywallFree5, c.secondary),
              Text(S.paywallHelp, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
            TextButton(
              onPressed: st.busy ? null : () => ctl.restore(),
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text(S.paywallRestore),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text(S.paywallNotNow),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Sectie in Instellingen; "Aankoop herstellen" is altijd zichtbaar.
class ProSettingsSection extends ConsumerWidget {
  const ProSettingsSection({super.key});

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
          onTap: pro ? null : () => showPaywall(context),
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
