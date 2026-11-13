import '../rampenzender/rampenzender_providers.dart';
import '../rampenzender/rampenzender_strings.dart';
import 'dart:convert';
import '../pro/pro_ui.dart';
import '../dashboard/dashboard_providers.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../noodplan/ui/plan_overview_screen.dart' show togglePlanReminder;
import '../../core/calm.dart';
import '../../core/theme/category_palette.dart';
import '../../core/theme.dart';
import 'household_form.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _version = '${i.version} (${i.buildNumber})');
    }).catchError((_) {});
  }

  Future<void> _update(AppSettings Function(AppSettings) f) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.save(f(await repo.load()));
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text(S.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(c, true), child: Text(action)),
          ],
        ),
      ) ??
      false;

  Future<void> _toggleSemiAnnual(AppSettings s, bool on) async {
    await _update((s) => s.copyWith(semiAnnual: on));
    if (!on) return;
    final granted = await ref.read(notificationServiceProvider).requestPermission();
    await _update((s) => s.copyWith(permissionAsked: true));
    if (!granted) _snack(S.notifDenied);
  }

  Future<void> _export() async {
    try {
      final json = await ref.read(itemRepositoryProvider).exportJson();
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'noodpakket-back-up.json'));
      await file.writeAsString(json);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (_) {
      _snack(S.exportFail);
    }
  }

  Future<void> _import() async {
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = res.isEmpty ? null : res.first.path;
    if (path == null || !mounted) return;
    final List<int> bytes;
    try {
      bytes = await File(path).readAsBytes();
    } catch (_) {
      _snack(S.importFail);
      return;
    }
    if (!await _confirm(S.importConfirmTitle, S.importConfirmBody, S.importData)) {
      return;
    }
    try {
      await ref.read(itemRepositoryProvider).importJson(utf8.decode(bytes));
      _snack(S.importOk);
    } catch (_) {
      _snack(S.importFail);
    }
  }

  Future<void> _restore() async {
    if (!await _confirm(
        S.restoreDefaultsTitle, S.restoreDefaultsBody, S.restore)) {
      return;
    }
    await ref.read(itemRepositoryProvider).restoreDefaults();
    _snack(S.restored);
  }

  Future<void> _reset() async {
    if (!await _confirm(S.resetAllTitle, S.resetAllBody, S.resetAll)) return;
    await ref.read(itemRepositoryProvider).resetAll();
    await ref.read(notificationServiceProvider).cancelAll();
    // onboarded valt terug op false: de router stuurt naar de onboarding.
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    final t = Theme.of(context);
    Widget header(String text) => Padding(
          padding: const EdgeInsets.only(top: Space.section, bottom: Space.tight),
          child: Semantics(header: true, child: Text(text, style: t.textTheme.titleMedium)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text(S.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Gap.xl),
        children: [
          header(S.setHousehold),
          HouseholdForm(
            value: s.household,
            onChanged: (h) => _update((s) => s.copyWith(household: h)),
          ),
          header(RZ.settingsRow),
          CalmListGroup(children: [
            Consumer(builder: (context, ref, _) {
              final r = ref.watch(radioResultProvider);
              return StatusRow(
                icon: Icons.radio_rounded,
                tint: menuTint(MenuItemKind.radio),
                title: r == null ? RZ.settingsNone : RZ.settingsValue(r.region.name),
                subtitle: r?.broadcaster?.name ?? RZ.entrySub,
                onTap: () => context.push('/rampenzender/kies'),
              );
            }),
          ]),
          header(S.setNotifications),
          Padding(
            padding: const EdgeInsets.only(bottom: Space.group),
            child: DropdownButtonFormField<int>(
              initialValue: s.leadDays,
              decoration: const InputDecoration(labelText: S.setLeadTime),
              items: [
                for (final d in {7, 14, 30, 60, s.leadDays}.toList()..sort())
                  DropdownMenuItem(value: d, child: Text(S.leadDays(d))),
              ],
              onChanged: (v) => v == null ? null : _update((s) => s.copyWith(leadDays: v)),
            ),
          ),
          CalmListGroup(children: [
            SwitchListTile(
              title: const Text(S.setSemiAnnual),
              subtitle: const Text(S.setSemiAnnualSub),
              value: s.semiAnnual,
              onChanged: (v) => _toggleSemiAnnual(s, v),
            ),
            SwitchListTile(
              title: const Text(S.planReminder),
              subtitle: const Text(S.planReminderSub),
              value: s.planReminder,
              onChanged: (v) => togglePlanReminder(context, ref, v),
            ),
          ]),
          const ProSettingsSection(),
          header(S.setDisplay),
          CalmListGroup(children: [
            SwitchListTile(
              title: const Text(S.simpleStartTitle),
              subtitle: const Text(S.simpleStartSub),
              value: s.simpleStart,
              onChanged: (v) => _update((s) => s.copyWith(simpleStart: v)),
            ),
            Builder(builder: (context) {
              final hidden = ref.watch(hiddenSuggestionCountProvider);
              return ListTile(
                title: const Text(S.restoreHidden),
                subtitle: Text(S.restoreHiddenSub(hidden)),
                enabled: hidden > 0,
                onTap: hidden == 0 ? null : () => ref.read(dashActionsProvider).restoreHidden(),
              );
            }),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: Space.group, bottom: Space.tight),
            child: Text(S.setTheme, style: t.textTheme.bodySmall),
          ),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text(S.themeSystem)),
              ButtonSegment(value: ThemeMode.light, label: Text(S.themeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(S.themeDark)),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (v) => _update((s) => s.copyWith(themeMode: v.first)),
          ),
          header(S.setData),
          CalmListGroup(children: [
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: const Text(S.exportData),
              subtitle: const Text(S.exportSub),
              onTap: _export,
            ),
            ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: const Text(S.importData),
              subtitle: const Text(S.importSub),
              onTap: _import,
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text(S.hiddenItems),
              onTap: () => context.push('/instellingen/verborgen'),
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text(S.restoreDefaults),
              subtitle: const Text(S.restoreDefaultsSub),
              onTap: _restore,
            ),
          ]),
          // Onomkeerbare actie staat apart, onderaan.
          const SizedBox(height: Space.section),
          CalmListGroup(children: [
            ListTile(
              leading: Icon(Icons.delete_outline, color: t.colorScheme.error),
              title: Text(S.resetAll, style: TextStyle(color: t.colorScheme.error)),
              subtitle: const Text(S.resetAllSub),
              onTap: _reset,
            ),
          ]),
          // De overheidsdisclaimer staat bij Meer en in Informatie; hier alleen de versie.
          if (_version.isNotEmpty) ...[
            const SizedBox(height: Space.section),
            Text(S.version(_version), style: t.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class HiddenItemsScreen extends ConsumerWidget {
  const HiddenItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(allItemsProvider).value?.where((i) => i.hidden).toList() ??
        const [];
    return Scaffold(
      appBar: AppBar(title: const Text(S.hiddenItems)),
      body: hidden.isEmpty
          ? const Center(child: Text(S.hiddenEmpty))
          : ListView(
              children: [
                for (final i in hidden)
                  ListTile(
                    title: Text(i.name),
                    trailing: TextButton(
                      onPressed: () =>
                          ref.read(itemRepositoryProvider).setHidden(i.id, false),
                      child: const Text(S.restore),
                    ),
                  ),
              ],
            ),
    );
  }
}
