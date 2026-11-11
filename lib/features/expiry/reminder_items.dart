import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../domain/expiry.dart';
import '../../domain/models.dart';
import '../pro/pro_models.dart';
import '../pro/pro_ui.dart';

/// Sleutel in de instellingentabel: id's van items met een vervangherinnering.
const remindItemsKey = 'remind_items';

Set<String> parseRemindItems(String? raw) {
  if (raw == null) return const {};
  try {
    return {for (final e in jsonDecode(raw) as List) e as String};
  } catch (_) {
    return const {};
  }
}

/// Items waarvoor meldingen worden gepland: alleen met Pro, alleen als de
/// gebruiker de schakelaar aanzette, en alleen met een vervangdatum. Zonder
/// Pro blijft de keuze bewaard, maar plannen we niets (geen data verwijderd).
List<Item> itemsToRemind(List<Item> items, Set<String> ids, {required bool pro}) {
  if (!ProCatalog.isAllowed(ProFeature.replacementReminders, pro: pro)) return const [];
  return [
    for (final i in items)
      if (ids.contains(i.id) && !i.hidden && dueDate(i) != null) i,
  ];
}

final reminderItemsProvider = Provider<Set<String>>((ref) => parseRemindItems(
    ref.watch(settingsProvider.select((s) => s.value?.raw[remindItemsKey]))));

/// Zet de herinnering voor één item aan of uit. Zonder Pro opent aanzetten de
/// paywall (er wordt dan niets opgeslagen). De meldingstoestemming wordt pas
/// gevraagd op het moment dat de gebruiker de schakelaar aanzet.
Future<void> toggleItemReminder(BuildContext context, WidgetRef ref, String id, bool on) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(settingsRepositoryProvider);
  final current = {...ref.read(reminderItemsProvider)};
  if (!on) {
    current.remove(id);
    await repo.setRaw(remindItemsKey, jsonEncode(current.toList()..sort()));
    return;
  }
  if (!await requirePro(context, ref, ProFeature.replacementReminders)) return;
  current.add(id);
  await repo.setRaw(remindItemsKey, jsonEncode(current.toList()..sort()));
  final granted = await ref.read(notificationServiceProvider).requestPermission();
  await repo.save((await repo.load()).copyWith(permissionAsked: true));
  if (!granted) messenger.showSnackBar(const SnackBar(content: Text(S.notifDenied)));
}
