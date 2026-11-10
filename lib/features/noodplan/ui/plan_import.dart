import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../domain/plan_share.dart';
import '../plan_providers.dart';

enum _ImportChoice { merge, replace }

/// Kiest een noodplan-bestand, toont eerst een voorbeeld en importeert daarna
/// (samenvoegen of vervangen). Ongeldige of te nieuwe bestanden worden geweigerd.
Future<void> startPlanImport(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String m) => messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['json']);
  final path = res.isEmpty ? null : res.first.path;
  if (path == null || !context.mounted) return;

  final ParsedPlanFile parsed;
  try {
    parsed = parsePlanFile(await File(path).readAsString());
  } on PlanFileException catch (e) {
    say(e.error == PlanFileError.tooNew ? S.planImportTooNew : S.planImportInvalid);
    return;
  } catch (_) {
    say(S.planImportInvalid);
    return;
  }
  if (!context.mounted) return;

  final choice = await showDialog<_ImportChoice>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(S.planImportFrom(parsed.plan.householdName)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(S.planImportContains(parsed.memberCount, parsed.contactCount)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pop(c, _ImportChoice.merge),
          child: const Text(S.planImportMerge),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.pop(c, _ImportChoice.replace),
          child: const Text(S.planImportReplace),
        ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text(S.cancel))],
    ),
  );
  if (choice == null || !context.mounted) return;

  final repo = ref.read(planRepositoryProvider);
  try {
    if (choice == _ImportChoice.replace) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text(S.planImportReplace),
          content: const Text(S.planImportReplaceConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(S.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text(S.confirm)),
          ],
        ),
      );
      if (ok != true) return;
      await repo.replaceAll(parsed.plan, photos: parsed.photos, keepMeta: false);
    } else {
      final own = await repo.load();
      await repo.replaceAll(mergePlans(own, parsed.plan), photos: parsed.photos);
    }
    say(S.planImportDone);
  } catch (_) {
    say(S.planImportInvalid);
  }
}
