import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/category_palette.dart';
import '../../../core/ui.dart';
import '../data/vault_controller.dart';

/// Verwijzing naar de documentenkluis. Verraadt alleen of er documenten in
/// staan, nooit wat er in zit.
class VaultLinkTile extends ConsumerWidget {
  const VaultLinkTile({
    super.key,
    this.title = S.vaultTitle,
    this.padding = EdgeInsets.zero,
  });
  final String title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final has = ref.watch(vaultHasDocsProvider).value ?? false;
    return Padding(
      padding: padding,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: IconBadge(Icons.lock_outline, size: 40, tint: menuTint(MenuItemKind.vault)),
        title: Text(title),
        subtitle: Text(has ? S.vaultHasDocs : S.vaultEntrySub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/kluis'),
      ),
    );
  }
}
