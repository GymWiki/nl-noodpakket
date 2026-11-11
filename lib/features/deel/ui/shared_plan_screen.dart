import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/dialer.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/theme.dart';
import '../../../core/ui.dart';
import '../../noodplan/domain/plan_models.dart';
import '../../noodplan/domain/plan_share.dart';
import '../../noodplan/plan_providers.dart';
import '../deel_providers.dart';

/// Een plan dat met mij is gedeeld, alleen-lezen. Telefoonnummers openen alleen
/// de telefoon-app en bellen nooit automatisch.
class SharedPlanScreen extends ConsumerWidget {
  const SharedPlanScreen({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final list = ref.watch(sharedPlansProvider).value ?? const [];
    final shared = list.where((p) => p.planId == planId).firstOrNull;
    if (shared == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text(S.wikiNotFound)));
    }
    final Plan plan;
    final Map<String, String> photos;
    try {
      final parsed = shared.parsed;
      plan = parsed.plan;
      photos = parsed.photos;
    } catch (_) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text(S.errorGeneric)));
    }
    final own = ref.watch(planProvider).value;
    final df = DateFormat('d MMM yyyy', 'nl_NL');

    Widget section(String title, List<Widget> children) {
      if (children.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: Gap.m),
        child: SoftCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, child: Text(title, style: t.textTheme.titleMedium)),
            const SizedBox(height: 8),
            ...children,
          ]),
        ),
      );
    }

    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: t.textTheme.labelLarge?.copyWith(color: c.onSurfaceVariant)),
            Text(value, style: t.textTheme.bodyLarge),
          ]),
        );

    final contacts = [
      for (final p in plan.contacts)
        if (p.name.trim().isNotEmpty || p.phone.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(contactRoleLabel(p.role), style: t.textTheme.labelLarge?.copyWith(color: c.onSurfaceVariant)),
                  Text([p.name.trim(), if (p.relation.trim().isNotEmpty) '(${p.relation.trim()})'].where((e) => e.isNotEmpty).join(' '),
                      style: t.textTheme.bodyLarge),
                ]),
              ),
              if (p.phone.trim().isNotEmpty)
                TextButton.icon(
                  onPressed: () => openDialer(context, p.phone.trim()),
                  icon: const Icon(Icons.call_outlined),
                  label: Text(p.phone.trim()),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
            ]),
          ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(plan.householdName.trim().isEmpty ? S.sharedWithMe : plan.householdName.trim())),
      body: SafeArea(
        child: ListView(
          padding: Gap.page,
          children: [
            Text(S.sharedFrom(shared.fromName.isEmpty ? '?' : shared.fromName), style: t.textTheme.titleLarge),
            Text(S.sharedVersionLine(shared.version, df.format((shared.updatedAt ?? shared.receivedAt).toLocal())),
                style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(S.sharedReadOnly, style: t.textTheme.bodySmall),
            section(S.planDocContacts, contacts),
            section(S.planDocPlaces, [
              for (final k in PlanKeys.placeKinds)
                if (!(plan.place(k)?.isEmpty ?? true))
                  line(placeLabel(k), [plan.place(k)!.address.trim(), plan.place(k)!.notes.trim()].where((e) => e.isNotEmpty).join(', ')),
            ]),
            section(S.planDocAgreements, [
              for (final k in [...PlanKeys.agreementKeys, ...PlanKeys.neighbourKeys])
                if (plan.agreement(k).isNotEmpty) line(agreementLabel(k), plan.agreement(k)),
            ]),
            section(S.planDocHome, [
              for (final k in PlanKeys.homeKeys)
                if (plan.locationText(k).isNotEmpty)
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    line(locationLabel(k), plan.locationText(k)),
                    if (photos[k] != null) _Photo(photos[k]!),
                  ]),
            ]),
            section(S.planDocPersons, [
              for (final m in plan.members)
                if (m.name.trim().isNotEmpty)
                  line(m.isPet ? S.planPetLabel : ageGroupLabel(m.ageGroup), '${m.name.trim()}${m.needsHelp ? ', ${S.planNeedsHelpShort}' : ''}'),
            ]),
            section(S.planDocCare, [
              if (plan.medication.trim().isNotEmpty) line(S.planCareMedication, plan.medication.trim()),
              if (plan.devices.trim().isNotEmpty) line(S.planCareDevices, plan.devices.trim()),
              if (plan.allergies.trim().isNotEmpty) line(S.planCareAllergies, plan.allergies.trim()),
              if (plan.caregiving.trim().isNotEmpty) line(S.planCareCaregiving, plan.caregiving.trim()),
            ]),
            const SizedBox(height: 8),
            Text(S.sharedCallHint, style: t.textTheme.bodySmall),
            const SizedBox(height: Gap.l),
            if (!(own?.hasContent ?? false))
              FilledButton.tonal(
                onPressed: () async {
                  final m = ScaffoldMessenger.of(context);
                  await ref.read(planRepositoryProvider).replaceAll(plan, photos: photos);
                  m.showSnackBar(const SnackBar(content: Text(S.sharedUseAsOwnDone)));
                },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: const Text(S.sharedUseAsOwn),
              )
            else
              Text(S.sharedOwnExists, style: t.textTheme.bodySmall),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    content: const Text(S.sharedRemoveConfirm),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text(S.cancel)),
                      FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text(S.sharedRemove)),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(sharedPlanStoreProvider).remove(planId);
                  if (context.mounted) context.pop();
                }
              },
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text(S.sharedRemove),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo(this.b64);
  final String b64;

  @override
  Widget build(BuildContext context) {
    try {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(base64Decode(b64), height: 160, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
