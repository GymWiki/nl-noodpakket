import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme.dart';
import '../../../core/ui.dart';
import '../../kluis/data/vault_controller.dart';
import '../../kluis/ui/vault_widgets.dart';
import '../deel_services.dart';

/// Kluisdocumenten kiezen om te delen. Staat in de kluisbeveiliging (ontgrendelen).
/// Standaard staat niets aan.
class ShareDocsScreen extends ConsumerWidget {
  const ShareDocsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final meta = ref.watch(vaultProvider).meta;
    final chosen = ref.watch(deelDraftProvider).docIds;
    final ctl = ref.read(deelDraftProvider.notifier);
    final docs = [...meta.documents]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: const Text(S.deelDocsTitle)),
      body: SafeArea(
        child: ListView(
          padding: Gap.page,
          children: [
            SoftCard(
              color: c.tertiaryContainer,
              borderColor: Colors.transparent,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber_rounded, color: c.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(S.deelDocsWarn,
                      style: t.textTheme.bodyMedium?.copyWith(color: c.onTertiaryContainer, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: Gap.m),
            if (docs.isEmpty) Text(S.vaultEmpty, style: t.textTheme.bodyLarge),
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (var i = 0; i < docs.length; i++) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  CheckboxListTile(
                    value: chosen.contains(docs[i].id),
                    onChanged: (v) {
                      final next = {...chosen};
                      v == true ? next.add(docs[i].id) : next.remove(docs[i].id);
                      ctl.setDocs(next);
                    },
                    title: Text(docs[i].title),
                    subtitle: Text([
                      typeLabel(meta, docs[i].typeId),
                      if (docs[i].owner.isNotEmpty) docs[i].owner,
                      S.vaultPagesCount(docs[i].pages.length),
                    ].join(' · ')),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: Gap.l),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text('${S.deelDocsDone}${chosen.isEmpty ? '' : ' (${chosen.length})'}'),
            ),
          ],
        ),
      ),
    );
  }
}
