import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/ui.dart';
import '../../kluis/data/vault_controller.dart';
import '../../noodplan/plan_providers.dart';
import '../deel_providers.dart';
import '../deel_services.dart';

/// Wordt als `extra` meegegeven aan het QR-scherm. Zonder deze token (dus zonder
/// geslaagde authenticatie) toont het QR-scherm nooit een code.
class ShareLaunch {
  const ShareLaunch(this.draft);
  final DeelDraft draft;
}

/// Kiest wat er gedeeld wordt, vraagt biometrie en opent daarna pas het QR-scherm.
class ShareSetupScreen extends ConsumerStatefulWidget {
  const ShareSetupScreen({super.key});

  @override
  ConsumerState<ShareSetupScreen> createState() => _ShareSetupScreenState();
}

class _ShareSetupScreenState extends ConsumerState<ShareSetupScreen> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final saved = await ref.read(settingsRepositoryProvider).getRaw('deel_naam');
      final plan = ref.read(planProvider).value;
      final start = (saved?.trim().isNotEmpty ?? false) ? saved! : (plan?.householdName.trim() ?? '');
      if (!mounted) return;
      _name.text = start;
      ref.read(deelDraftProvider.notifier).setName(start);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _say(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _start() async {
    final draft = ref.read(deelDraftProvider);
    final plan = ref.read(planProvider).value;
    final planChosen = draft.anythingPlan && (plan?.hasContent ?? false);
    if (!planChosen && draft.docIds.isEmpty) return _say(S.deelNothingChosen);
    if (draft.docIds.isNotEmpty && !ref.read(vaultProvider).unlocked) {
      _say(S.deelVaultLocked);
      context.push('/delen/documenten');
      return;
    }
    setState(() => _busy = true);
    // Altijd opnieuw bevestigen; nooit gecachet.
    final res = await ref.read(shareAuthProvider).authenticate(S.deelAuthReason);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (res) {
      case ShareAuthResult.ok:
        await ref.read(settingsRepositoryProvider).setRaw('deel_naam', draft.name.trim());
        if (mounted) context.push('/delen/qr', extra: ShareLaunch(draft));
      case ShareAuthResult.unavailable:
        _say(S.deelAuthUnavailable);
      case ShareAuthResult.failed:
        _say(S.deelAuthFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final draft = ref.watch(deelDraftProvider);
    final o = draft.options;
    final ctl = ref.read(deelDraftProvider.notifier);
    final plan = ref.watch(planProvider).value;
    final last = ref.watch(lastSharedProvider).value;

    Widget toggle(String label, bool v, ValueChanged<bool> on, {String? sub}) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: sub == null ? null : Text(sub),
          value: v,
          onChanged: on,
        );

    return Scaffold(
      appBar: AppBar(title: const Text(S.deelTitle)),
      body: SafeArea(
        child: ListView(
          padding: Gap.page,
          children: [
            Text(S.deelLocalNetworkNote, style: t.textTheme.bodyLarge),
            const SizedBox(height: Gap.m),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: S.deelYourName, hintText: S.deelYourNameHint),
              textCapitalization: TextCapitalization.words,
              maxLength: 40,
              onChanged: ctl.setName,
            ),
            SectionHeader(S.deelChooseTitle, padding: const EdgeInsets.only(top: Gap.m, bottom: Gap.s)),
            if (!(plan?.hasContent ?? false))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(S.deelNoPlanYet, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
              ),
            toggle(S.deelOptContacts, o.contacts, (v) => ctl.setOptions(o.copyWith(contacts: v))),
            toggle(S.deelOptPlaces, o.places, (v) => ctl.setOptions(o.copyWith(places: v))),
            toggle(S.deelOptAgreements, o.agreements, (v) => ctl.setOptions(o.copyWith(agreements: v))),
            toggle(S.deelOptHome, o.home, (v) => ctl.setOptions(o.copyWith(home: v, photos: v ? o.photos : false))),
            if (o.home) toggle(S.deelOptPhotos, o.photos, (v) => ctl.setOptions(o.copyWith(photos: v))),
            toggle(S.deelOptPersons, o.persons, (v) => ctl.setOptions(o.copyWith(persons: v))),
            toggle(S.deelOptCare, o.care, (v) => ctl.setOptions(o.copyWith(care: v)), sub: S.deelOptCareSub),
            SectionHeader(S.deelDocsTitle, padding: const EdgeInsets.only(top: Gap.m, bottom: Gap.s)),
            SoftCard(
              onTap: () => context.push('/delen/documenten'),
              semanticLabel: '${S.deelDocsChoose}. ${draft.docIds.isEmpty ? S.deelDocsNone : S.deelDocsCount(draft.docIds.length)}',
              child: Row(children: [
                const IconBadge(Icons.lock_outline),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(S.deelDocsChoose, style: t.textTheme.titleMedium),
                    Text(draft.docIds.isEmpty ? S.deelDocsNone : S.deelDocsCount(draft.docIds.length),
                        style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant),
              ]),
            ),
            const SizedBox(height: Gap.m),
            Text(S.deelLimits, style: t.textTheme.bodySmall),
            if (last != null) ...[
              const SizedBox(height: 8),
              Text(S.deelLast(DateFormat('d MMM yyyy', 'nl_NL').format(last.at), last.device, last.what),
                  style: t.textTheme.bodySmall),
            ],
            const SizedBox(height: Gap.l),
            FilledButton.icon(
              onPressed: _busy ? null : _start,
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text(S.deelStart),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
          ],
        ),
      ),
    );
  }
}
