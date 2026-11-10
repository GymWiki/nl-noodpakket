import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/format.dart';
import '../../../core/l10n/strings.dart';
import '../../wiki/wiki_providers.dart';
import '../domain/plan_models.dart';
import '../domain/plan_share.dart';
import '../plan_providers.dart';
import 'plan_pdf.dart';
import 'plan_wizard_screen.dart' show PlanDocumentPreview;

class PlanShareScreen extends ConsumerStatefulWidget {
  const PlanShareScreen({super.key});

  @override
  ConsumerState<PlanShareScreen> createState() => _PlanShareScreenState();
}

class _PlanShareScreenState extends ConsumerState<PlanShareScreen> {
  // Zorg en foto's staan standaard uit.
  ShareOptions _o = const ShareOptions();
  bool _busy = false;

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(Future<bool> Function(Plan plan, int version) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final plan = await ref.read(planRepositoryProvider).load();
      final version = plan.sharedVersion + 1;
      final shared = await action(plan, version);
      if (shared) await ref.read(planRepositoryProvider).markShared(version);
    } catch (_) {
      if (mounted) _snack(S.planShareError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _pdf(Plan plan, int version) async {
    final wiki = await ref.read(wikiProvider.future);
    return buildPlanPdf(plan, _o, wiki: wiki, now: DateTime.now(), version: version);
  }

  Future<void> _sharePdf() => _run((plan, v) async {
        final bytes = await _pdf(plan, v);
        await Printing.sharePdf(
            bytes: bytes, filename: 'noodplan.pdf');
        return true;
      });

  Future<void> _print() => _run((plan, v) async {
        final bytes = await _pdf(plan, v);
        return Printing.layoutPdf(
            name: 'noodplan.pdf', onLayout: (_) async => bytes);
      });

  Future<void> _shareText() => _run((plan, v) async {
        final text = planSummaryText(plan, _o, DateTime.now());
        final r = await SharePlus.instance.share(ShareParams(
          text: text,
          subject: plan.householdName.trim().isEmpty
              ? S.planDocTitleNoName
              : S.planDocTitle(plan.householdName.trim()),
        ));
        return r.status != ShareResultStatus.dismissed;
      });

  Future<void> _shareFile() => _run((plan, v) async {
        final photos = _o.photos
            ? await ref.read(planRepositoryProvider).photosBase64(plan)
            : const <String, String>{};
        final json = planToJsonString(plan, _o, now: DateTime.now(), photos: photos);
        final dir = await getTemporaryDirectory();
        final file = File(p.join(dir.path, 'noodplan.json'));
        await file.writeAsString(json);
        final r = await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
        return r.status != ShareResultStatus.dismissed;
      });

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planProvider).value ?? const Plan();
    final t = Theme.of(context);

    Widget toggle(String title, bool value, ValueChanged<bool> on, {String? sub}) =>
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          subtitle: sub == null ? null : Text(sub),
          value: value,
          onChanged: on,
        );

    return Scaffold(
      appBar: AppBar(title: const Text(S.planShareTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            color: t.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, color: t.colorScheme.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(S.planShareWarn,
                      style: TextStyle(color: t.colorScheme.onTertiaryContainer)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(header: true, child: Text(S.planShareChoose, style: t.textTheme.titleMedium)),
          toggle(S.planSecHousehold, _o.persons, (v) => setState(() => _o = _o.copyWith(persons: v))),
          toggle(S.planSecContacts, _o.contacts, (v) => setState(() => _o = _o.copyWith(contacts: v))),
          toggle(S.planSecPlaces, _o.places, (v) => setState(() => _o = _o.copyWith(places: v))),
          toggle(S.planSecAgreements, _o.agreements, (v) => setState(() => _o = _o.copyWith(agreements: v))),
          toggle(S.planSecHome, _o.home, (v) => setState(() => _o = _o.copyWith(home: v))),
          toggle(S.planSecCare, _o.care, (v) => setState(() => _o = _o.copyWith(care: v)),
              sub: S.planShareCareWarn),
          toggle(S.planSharePhotos, _o.photos, (v) => setState(() => _o = _o.copyWith(photos: v))),
          const SizedBox(height: 8),
          PlanDocumentPreview(plan: plan, options: _o),
          const SizedBox(height: 16),
          if (_busy) const Center(child: CircularProgressIndicator()),
          FilledButton.icon(
            onPressed: _busy || !plan.hasContent ? null : _sharePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text(S.planSharePdf),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy || !plan.hasContent ? null : _shareText,
            icon: const Icon(Icons.chat_outlined),
            label: const Text(S.planShareText),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy || !plan.hasContent ? null : _print,
            icon: const Icon(Icons.print_outlined),
            label: const Text(S.planSharePrint),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy || !plan.hasContent ? null : _shareFile,
            icon: const Icon(Icons.file_present_outlined),
            label: const Text(S.planShareFile),
          ),
          const SizedBox(height: 4),
          Text(S.planShareFileHint,
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          if (plan.lastSharedAt != null) ...[
            const SizedBox(height: 16),
            Text(S.planLastShared(fmtDate(plan.lastSharedAt!))),
          ],
        ],
      ),
    );
  }
}
