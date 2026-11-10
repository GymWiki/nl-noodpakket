import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/l10n/strings.dart';
import '../crypto/vault_crypto.dart';
import '../data/vault_controller.dart';
import '../domain/vault_models.dart';

/// Ontsleutelde bytes van een bestand (alleen in het geheugen).
final vaultBytesProvider = FutureProvider.autoDispose.family<Uint8List, String>((ref, id) async {
  final bytes = await ref.read(vaultProvider.notifier).readFile(id);
  ref.onDispose(() => zero(bytes)); // wis de buffer zodra niemand hem meer gebruikt
  return bytes;
});

/// Filtert documenten op titel, type en persoon (pure functie, getest).
List<VaultDocument> filterVaultDocs(
  Iterable<VaultDocument> docs, {
  String query = '',
  String? typeId,
  String? owner,
}) {
  final q = query.trim().toLowerCase();
  final out = [
    for (final d in docs)
      if ((q.isEmpty || d.title.toLowerCase().contains(q)) &&
          (typeId == null || d.typeId == typeId) &&
          (owner == null || d.owner == owner))
        d,
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return out;
}

IconData iconForType(String typeId) => switch (typeId) {
      'passport' || 'idcard' || 'driving' || 'residence' => Icons.badge_outlined,
      'health_ins' || 'medication' || 'medical' || 'gp_pharmacy' => Icons.medical_services_outlined,
      'policy_home' || 'policy_car' || 'policy_liability' => Icons.policy_outlined,
      'pet' => Icons.pets,
      'ownership' => Icons.inventory_2_outlined,
      _ => Icons.description_outlined,
    };

/// Miniatuur (versleuteld opgeslagen) of een pictogram.
class VaultThumb extends ConsumerWidget {
  const VaultThumb({super.key, required this.doc, this.size = 56});
  final VaultDocument doc;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbId = doc.pages.isEmpty ? null : doc.pages.first.thumbId;
    final icon = Icon(iconForType(doc.typeId), size: size * 0.5);
    Widget box(Widget child) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: size,
            height: size,
            child: ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Center(child: child)),
          ),
        );
    if (thumbId == null) return ExcludeSemantics(child: box(icon));
    final bytes = ref.watch(vaultBytesProvider(thumbId));
    return ExcludeSemantics(
      child: box(bytes.when(
        data: (b) => Image.memory(b, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true,
            errorBuilder: (_, _, _) => icon),
        loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, _) => icon,
      )),
    );
  }
}

/// Rustige badge; alleen "verlopen" gebruikt de alarmkleur.
class DocExpiryBadge extends StatelessWidget {
  const DocExpiryBadge({super.key, required this.doc, this.soonDays = 90});
  final VaultDocument doc;
  final int soonDays;

  @override
  Widget build(BuildContext context) {
    final st = docExpiryStatus(doc, DateTime.now(), soonDays: soonDays);
    if (st == DocExpiry.none || st == DocExpiry.ok) return const SizedBox.shrink();
    final c = Theme.of(context).colorScheme;
    final expired = st == DocExpiry.expired;
    final text = expired ? S.vaultExpiredOn(fmtDate(doc.expiry!)) : S.vaultExpiresOn(fmtDate(doc.expiry!));
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: expired ? c.errorContainer : c.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: expired ? c.onErrorContainer : c.onTertiaryContainer,
          ),
        ),
      ),
    );
  }
}

String typeLabel(VaultMeta meta, String typeId) => meta.typeOf(typeId)?.label ?? S.vaultTypeOther;
