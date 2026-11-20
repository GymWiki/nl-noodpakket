import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calm.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/category_palette.dart';
import 'store_review_opener.dart';

/// "Beoordeel NL-Noodpakket" onder Meer > Informatie. Rustig, in de stijl van de andere rijen, met categorietint.
/// Opent de winkelpagina; roept nooit de systeemprompt aan. Geen beloning en geen tekst die om een goede beoordeling vraagt.
class ReviewLinkRow extends ConsumerWidget {
  const ReviewLinkRow({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final r = await ref.read(storeReviewOpenerProvider).open();
    final text = switch (r) {
      StoreReviewResult.opened => null,
      StoreReviewResult.offline => S.reviewOffline,
      StoreReviewResult.failed => S.reviewOpenError,
    };
    if (text != null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CalmListGroup(children: [
      StatusRow(
        icon: Icons.star_outline_rounded,
        tint: menuTint(MenuItemKind.review),
        title: S.reviewRowTitle,
        subtitle: S.reviewRowSub,
        trailing: const Icon(Icons.open_in_new_rounded),
        onTap: () => _open(context, ref),
        semanticLabel: '${S.reviewRowTitle}. ${S.reviewRowSub}',
      ),
    ]);
  }
}
