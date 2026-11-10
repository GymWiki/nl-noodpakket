import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/ui.dart';
import '../data/vault_controller.dart';

/// Verwijzing naar de documentenkluis. Verraadt alleen of er documenten in
/// staan, nooit wat er in zit.
class VaultLinkTile extends ConsumerWidget {
  const VaultLinkTile({super.key, this.title = S.vaultTitle, this.padding = EdgeInsets.zero});
  final String title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final has = ref.watch(vaultHasDocsProvider).value ?? false;
    return Padding(
      padding: padding,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.lock_outline),
        title: Text(title),
        subtitle: Text(has ? S.vaultHasDocs : S.vaultEntrySub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/kluis'),
      ),
    );
  }
}

/// Kaart op het tabblad Noodgevallen.
class VaultEntryCard extends StatelessWidget {
  const VaultEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SoftCard(
      onTap: () => context.push('/kluis'),
      child: Row(children: [
        const IconBadge(Icons.lock_outline),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(S.vaultTitle, style: t.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(S.vaultEntrySub,
                style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]),
        ),
        Icon(Icons.chevron_right_rounded, color: t.colorScheme.onSurfaceVariant),
      ]),
    );
  }
}
