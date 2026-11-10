import 'dart:io' show File, Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/dialer.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../domain/plan_models.dart';
import '../domain/plan_share.dart';
import '../plan_providers.dart';
import '../../kluis/ui/vault_link.dart';
import 'contact_picker.dart';
import 'plan_widgets.dart';

// ------------------------------------------------------------------ stap 1

class HouseholdStep extends ConsumerStatefulWidget {
  const HouseholdStep({super.key, required this.plan});
  final Plan plan;

  @override
  ConsumerState<HouseholdStep> createState() => _HouseholdStepState();
}

class _HouseholdStepState extends ConsumerState<HouseholdStep> {
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    if (widget.plan.members.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final h = (await ref.read(settingsProvider.future)).household;
        if (!mounted) return;
        await ref.read(planRepositoryProvider).prefillMembers(
              h,
              personName: (g, n) => S.planDefaultName(ageGroupLabel(g), n),
              petName: S.planDefaultPet,
            );
        if (mounted) setState(() => _prefilled = true);
      });
    }
  }

  Future<void> _edit(PlanMember? m, {required bool pet}) async {
    final result = await showDialog<PlanMember>(
      context: context,
      builder: (_) => _MemberDialog(member: m ?? PlanMember(isPet: pet)),
    );
    if (result == null) return;
    final repo = ref.read(planRepositoryProvider);
    m == null ? await repo.addMember(result) : await repo.updateMember(result);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final repo = ref.read(planRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WhyCard(S.planHhWhy),
        if (_prefilled && plan.members.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(S.planHhPrefilled),
        ],
        const FieldGap(),
        AutoSaveField(
          initial: plan.householdName,
          label: S.planHhName,
          hint: S.planHhNameHint,
          onSave: repo.setHouseholdName,
        ),
        const FieldGap(),
        if (plan.members.isEmpty) const Text(S.planNoMembers),
        for (final m in plan.members)
          Card(
            child: ListTile(
              minVerticalPadding: 12,
              leading: Icon(m.isPet ? Icons.pets : Icons.person_outline),
              title: Text(m.name.isEmpty ? '—' : m.name),
              subtitle: Text([
                m.isPet ? S.planPetLabel : ageGroupLabel(m.ageGroup),
                if (m.needsHelp) S.planNeedsHelpShort,
              ].join(' · ')),
              trailing: IconButton(
                tooltip: S.planRemove,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => repo.deleteMember(m.id),
              ),
              onTap: () => _edit(m, pet: m.isPet),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: () => _edit(null, pet: false),
            icon: const Icon(Icons.person_add_alt),
            label: const Text(S.planAddPerson),
          ),
          OutlinedButton.icon(
            onPressed: () => _edit(null, pet: true),
            icon: const Icon(Icons.pets),
            label: const Text(S.planAddPet),
          ),
        ]),
      ],
    );
  }
}

class _MemberDialog extends StatefulWidget {
  const _MemberDialog({required this.member});
  final PlanMember member;
  @override
  State<_MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<_MemberDialog> {
  late final _name = TextEditingController(text: widget.member.name);
  late final _notes = TextEditingController(text: widget.member.notes);
  late String _age = widget.member.ageGroup;
  late bool _help = widget.member.needsHelp;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.member.isPet;
    return AlertDialog(
      title: Text(pet ? S.planAddPet : S.planAddPerson),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: S.planMemberName),
          ),
          if (!pet) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _age,
              decoration: const InputDecoration(labelText: S.planMemberAge),
              items: [
                for (final g in const ['adult', 'senior', 'child', 'baby'])
                  DropdownMenuItem(value: g, child: Text(ageGroupLabel(g))),
              ],
              onChanged: (v) => setState(() => _age = v ?? 'adult'),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(S.planNeedsHelp),
            value: _help,
            onChanged: (v) => setState(() => _help = v),
          ),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: S.planMemberNotes),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(S.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            widget.member.copyWith(
              name: _name.text.trim(),
              ageGroup: _age,
              needsHelp: _help,
              notes: _notes.text.trim(),
            ),
          ),
          child: const Text(S.planSaveDialog),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ stap 2

class ContactsStep extends ConsumerWidget {
  const ContactsStep({super.key, required this.plan});
  final Plan plan;

  Future<void> _edit(BuildContext context, WidgetRef ref, PlanContact c) async {
    final result = await showDialog<PlanContact>(
      context: context,
      builder: (_) => _ContactDialog(contact: c),
    );
    if (result == null) return;
    final repo = ref.read(planRepositoryProvider);
    c.id == 0 ? await repo.addContact(result) : await repo.updateContact(result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final repo = ref.read(planRepositoryProvider);
    final hints = {
      PlanKeys.roleOutside: S.planRoleOutsideHint,
      PlanKeys.roleEmergency: S.planRoleEmergencyHint,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WhyCard(S.planCtWhy),
        for (final role in PlanKeys.contactRoles) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 4),
            child: Semantics(
                header: true,
                child: Text(contactRoleLabel(role), style: t.textTheme.titleMedium)),
          ),
          if (hints[role] != null)
            Text(hints[role]!, style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
          for (final c in plan.contactsOf(role))
            ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 8,
              title: Text(c.name.isEmpty ? c.phone : c.name),
              subtitle: Text([if (c.relation.isNotEmpty) c.relation, if (c.name.isNotEmpty) c.phone]
                  .join(' · ')),
              onTap: () => _edit(context, ref, c),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (c.phone.isNotEmpty)
                  IconButton(
                    tooltip: S.planCallContact(c.name.isEmpty ? c.phone : c.name),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.call),
                    onPressed: () => openDialer(context, c.phone),
                  ),
                IconButton(
                  tooltip: S.planRemove,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => repo.deleteContact(c.id),
                ),
              ]),
            ),
          TextButton.icon(
            onPressed: () => _edit(context, ref, PlanContact(role: role)),
            icon: const Icon(Icons.add),
            label: const Text(S.planAdd),
          ),
        ],
      ],
    );
  }
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog({required this.contact});
  final PlanContact contact;
  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late final _name = TextEditingController(text: widget.contact.name);
  late final _relation = TextEditingController(text: widget.contact.relation);
  late final _phone = TextEditingController(text: widget.contact.phone);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final (result, c) = await pickPhoneContact();
    if (!mounted) return;
    if (result == PickResult.denied) {
      setState(() => _error = S.planContactsDenied);
      return;
    }
    if (c != null) {
      setState(() {
        _error = null;
        if (c.name.isNotEmpty) _name.text = c.name;
        if (c.phone.isNotEmpty) _phone.text = c.phone;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(contactRoleLabel(widget.contact.role)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.contacts_outlined),
            label: const Text(S.planPickContact),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: S.planContactName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _relation,
            decoration: const InputDecoration(labelText: S.planContactRelation),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: S.planContactPhone),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(S.cancel)),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty && _phone.text.trim().isEmpty) {
              setState(() => _error = S.planContactNumberOrName);
              return;
            }
            Navigator.pop(
              context,
              widget.contact.copyWith(
                name: _name.text.trim(),
                relation: _relation.text.trim(),
                phone: _phone.text.trim(),
              ),
            );
          },
          child: const Text(S.planSaveDialog),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ stap 3

class PlacesStep extends ConsumerWidget {
  const PlacesStep({super.key, required this.plan});
  final Plan plan;

  Future<void> _openMap(BuildContext context, String q) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Platform.isIOS
        ? Uri.https('maps.apple.com', '/', {'q': q})
        : Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': q});
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) messenger.showSnackBar(const SnackBar(content: Text(S.planMapError)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(planRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WhyCard(S.planPlWhy),
        for (final kind in PlanKeys.placeKinds) ...[
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Semantics(
              header: true,
              child: Text(placeLabel(kind), style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          AutoSaveField(
            initial: plan.place(kind)?.address ?? '',
            label: S.planPlAddress,
            hint: S.planPlAddressHint,
            onSave: (v) => repo.setPlace(kind, address: v),
          ),
          const SizedBox(height: 12),
          AutoSaveField(
            initial: plan.place(kind)?.notes ?? '',
            label: S.planPlNotes,
            onSave: (v) => repo.setPlace(kind, notes: v),
          ),
          if ((plan.place(kind)?.address ?? '').trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openMap(context, plan.place(kind)!.address),
                icon: const Icon(Icons.map_outlined),
                label: const Text(S.planOpenMap),
              ),
            ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------------ stap 4

class AgreementsStep extends ConsumerWidget {
  const AgreementsStep({super.key, required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(planRepositoryProvider);
    // Kinderen, huisdieren en hulpbehoevenden alleen tonen als ze er zijn (of al zijn ingevuld).
    bool show(String k) => switch (k) {
          PlanKeys.kids => plan.members.any((m) => m.isChild) || plan.agreement(k).isNotEmpty,
          PlanKeys.pets => plan.pets.isNotEmpty || plan.agreement(k).isNotEmpty,
          PlanKeys.vulnerable =>
            plan.members.any((m) => !m.isPet && m.needsHelp) || plan.agreement(k).isNotEmpty,
          _ => true,
        };
    final suggestions = {
      PlanKeys.checkin: S.planSugCheckin,
      PlanKeys.kids: S.planSugKids,
      PlanKeys.pets: S.planSugPets,
      PlanKeys.vulnerable: S.planSugVulnerable,
      PlanKeys.noteLeft: S.planSugNoteLeft,
      PlanKeys.infoSource: S.planSugInfoSource,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WhyCard(S.planAgrWhy),
        for (final k in PlanKeys.agreementKeys)
          if (show(k)) ...[
            const FieldGap(),
            const FieldGap(),
            SuggestedField(
              initial: plan.agreement(k),
              label: agreementLabel(k),
              hint: S.planAgrHint,
              suggestions: suggestions[k] ?? const [],
              onSave: (v) => repo.setAgreement(k, v),
            ),
          ],
      ],
    );
  }
}

// ------------------------------------------------------------------ stap 5

class HomeStep extends ConsumerWidget {
  const HomeStep({super.key, required this.plan});
  final Plan plan;

  Future<void> _pickPhoto(BuildContext context, WidgetRef ref, String key) async {
    final messenger = ScaffoldMessenger.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text(S.planPhotoCamera),
            onTap: () => Navigator.pop(c, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text(S.planPhotoGallery),
            onTap: () => Navigator.pop(c, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 1280, imageQuality: 75);
      if (x == null) return;
      await ref.read(planRepositoryProvider).setLocationPhoto(key, await x.readAsBytes());
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(S.planPhotoError)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(planRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WhyCard(S.planHomeWhy),
        for (final k in PlanKeys.homeKeys) ...[
          const FieldGap(),
          const FieldGap(),
          AutoSaveField(
            initial: plan.locationText(k),
            label: locationLabel(k),
            hint: S.planLocHint,
            onSave: (v) => repo.setLocation(k, v),
          ),
          if (k == PlanKeys.noodpakket)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push('/checklist'),
                icon: const Icon(Icons.checklist),
                label: const Text(S.planToChecklist),
              ),
            ),
          _PhotoRow(
            path: plan.locations[k]?.photoPath,
            label: locationLabel(k),
            onAdd: () => _pickPhoto(context, ref, k),
            onRemove: () => repo.removeLocationPhoto(k),
          ),
        ],
        const FieldGap(),
        const VaultLinkTile(),
        const FieldGap(),
        Text(S.planPhotoLocal,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({required this.path, required this.label, required this.onAdd, required this.onRemove});
  final String? path;
  final String label;
  final VoidCallback onAdd, onRemove;

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text(S.planPhotoAdd),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        Semantics(
          label: 'Foto: $label',
          image: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(path!), width: 96, height: 96, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                    width: 96, height: 96, child: Icon(Icons.broken_image_outlined))),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(onPressed: onAdd, child: const Text(S.planPhotoAdd)),
        TextButton(onPressed: onRemove, child: const Text(S.planPhotoRemove)),
      ]),
    );
  }
}

// ------------------------------------------------------------------ stap 6

class CareStep extends ConsumerWidget {
  const CareStep({super.key, required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(planRepositoryProvider);
    final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WhyCard(S.planCareWhy),
        const FieldGap(),
        AutoSaveField(
          initial: plan.medication,
          label: S.planCareMedication,
          maxLines: 3,
          onSave: (v) => repo.setCare(medication: v),
        ),
        const FieldGap(),
        AutoSaveField(
          initial: plan.devices,
          label: S.planCareDevices,
          maxLines: 3,
          onSave: (v) => repo.setCare(devices: v),
        ),
        const SizedBox(height: 4),
        Text(S.planCareDevicesTip, style: muted),
        const FieldGap(),
        AutoSaveField(
          initial: plan.allergies,
          label: S.planCareAllergies,
          maxLines: 2,
          onSave: (v) => repo.setCare(allergies: v),
        ),
        const FieldGap(),
        AutoSaveField(
          initial: plan.caregiving,
          label: S.planCareCaregiving,
          maxLines: 2,
          onSave: (v) => repo.setCare(caregiving: v),
        ),
        const FieldGap(),
        AutoSaveField(
          initial: plan.documents,
          label: S.planCareDocuments,
          maxLines: 2,
          onSave: (v) => repo.setCare(documents: v),
        ),
        const SizedBox(height: 4),
        Text(S.planCareNoSensitive, style: muted),
        const SizedBox(height: 8),
        const VaultLinkTile(),
      ],
    );
  }
}

// ------------------------------------------------------------------ stap 7

class NeighboursStep extends ConsumerWidget {
  const NeighboursStep({super.key, required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(planRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WhyCard(S.planNbWhy),
        for (final k in PlanKeys.neighbourKeys) ...[
          const FieldGap(),
          const FieldGap(),
          AutoSaveField(
            initial: plan.agreement(k),
            label: agreementLabel(k),
            hint: S.planAgrHint,
            maxLines: 3,
            onSave: (v) => repo.setAgreement(k, v),
          ),
        ],
      ],
    );
  }
}
