import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme.dart';
import '../../../core/ui.dart';
import '../../../core/providers.dart';
import '../../kluis/data/vault_controller.dart';
import '../../kluis/ui/vault_widgets.dart';
import '../../noodplan/domain/plan_share.dart';
import '../../noodplan/plan_providers.dart';
import '../deel_providers.dart';
import '../deel_services.dart';
import '../domain/shared_plan_logic.dart';
import '../protocol/receiver.dart';
import '../protocol/session_payload.dart';
import '../protocol/transfer_models.dart';
import 'share_qr_screen.dart' show fmtBytes, shareErrorText;

String sectionLabel(String s) => switch (s) {
      ShareSection.persons => S.secPersons,
      ShareSection.contacts => S.secContacts,
      ShareSection.places => S.secPlaces,
      ShareSection.agreements => S.secAgreements,
      ShareSection.home => S.secHome,
      ShareSection.care => S.secCare,
      _ => s,
    };

enum _Phase { scanning, connecting, verify, preview, receiving, done, failed }

/// Ontvanger: scannen, verbinden, code vergelijken, voorbeeld, kiezen en opslaan.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  _Phase _phase = _Phase.scanning;
  ShareReceiverSession? _session;
  StreamSubscription<ReceiverEvent>? _sub;
  String _code = '', _error = '', _invalid = '', _summary = '';
  Manifest? _manifest;
  SharedPlan? _existing;
  bool _takePlan = true, _saveOwn = false;
  final _docs = <String>{};
  int _done = 0, _total = 0;
  List<String> _changed = const [];

  @override
  void dispose() {
    _sub?.cancel();
    unawaited(_session?.cancel());
    super.dispose();
  }

  Future<void> _onCode(String raw) async {
    if (_phase != _Phase.scanning) return;
    final payload = SessionPayload.tryParse(raw);
    if (payload == null) {
      if (_invalid.isEmpty) setState(() => _invalid = S.scanInvalid);
      return;
    }
    setState(() {
      _phase = _Phase.connecting;
      _invalid = '';
    });
    final name = await deviceLabel(ref.read(settingsRepositoryProvider));
    try {
      final s = await ref.read(receiverConnectorProvider)(
        payload,
        deviceName: name,
        onPlan: _storePlan,
        onDocument: _storeDocument,
      );
      if (!mounted) {
        await s.cancel();
        return;
      }
      _session = s;
      _sub = s.events.listen(_onEvent);
    } catch (_) {
      if (mounted) setState(() => _fail(S.scanConnectFail));
    }
  }

  void _fail(String msg) {
    _phase = _Phase.failed;
    _error = msg;
  }

  Future<void> _onEvent(ReceiverEvent e) async {
    if (!mounted) return;
    switch (e) {
      case ReceiverCode():
        setState(() {
          _phase = _Phase.verify;
          _code = e.code;
        });
      case ReceiverManifest():
        final existing = e.manifest.hasPlan ? await ref.read(sharedPlanStoreProvider).get(e.manifest.planId) : null;
        if (!mounted) return;
        final rel = existing == null ? VersionRelation.newer : compareVersions(existing: existing.version, incoming: e.manifest.planVersion);
        final own = ref.read(planProvider).value?.hasContent ?? false;
        setState(() {
          _phase = _Phase.preview;
          _manifest = e.manifest;
          _existing = existing;
          _takePlan = e.manifest.hasPlan && rel == VersionRelation.newer;
          _saveOwn = false;
          _changed = existing == null ? const [] : changedSectionsByHash(existing.hashes, e.manifest.planSectionHashes);
          if (own) _saveOwn = false;
        });
      case ReceiverProgress():
        setState(() {
          _phase = _Phase.receiving;
          _done = e.doneBytes;
          _total = e.totalBytes;
        });
      case ReceiverFinished():
        final parts = [
          if (e.planStored) S.whatPlan,
          if (e.documents > 0) S.whatDocs(e.documents),
        ];
        setState(() {
          _phase = _Phase.done;
          _summary = S.doneStored(parts.join(' en '));
        });
      case ReceiverFailed():
        setState(() => _fail(shareErrorText(e.error)));
    }
  }

  // ---- opslaan (alleen na controle; nooit overschrijven of samenvoegen)

  Future<void> _storePlan(String json, Manifest m) async {
    final parsed = parsePlanFile(json);
    if (m.planId.isNotEmpty && parsed.planId.isNotEmpty && parsed.planId != m.planId) {
      throw const FormatException('planId komt niet overeen');
    }
    final ownEmpty = !(ref.read(planProvider).value?.hasContent ?? false);
    if (_saveOwn && ownEmpty) {
      await ref.read(planRepositoryProvider).replaceAll(parsed.plan, photos: parsed.photos);
      return;
    }
    await ref.read(sharedPlanStoreProvider).save(SharedPlan(
          planId: m.planId,
          fromName: m.senderName,
          version: m.planVersion,
          receivedAt: DateTime.now(),
          updatedAt: m.planUpdatedAt,
          sections: m.planSections,
          hashes: m.planSectionHashes,
          json: json,
        ));
  }

  Future<void> _storeDocument(ReceivedDocument d) async {
    await storeReceivedDocument(ref.read(vaultProvider), ref.read(vaultProvider.notifier), d);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final Widget body;
    switch (_phase) {
      case _Phase.scanning:
        body = Column(children: [
          Padding(
            padding: Gap.page,
            child: Text(S.scanHelp, style: t.textTheme.bodyLarge),
          ),
          if (_invalid.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(_invalid, style: t.textTheme.bodyMedium?.copyWith(color: c.error)),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.card),
                child: ref.watch(qrScannerBuilderProvider)(context, _onCode),
              ),
            ),
          ),
        ]);
      case _Phase.connecting:
        body = _center(const CircularProgressIndicator(), S.scanConnecting);
      case _Phase.verify:
        body = ListView(padding: Gap.page, children: [
          Semantics(header: true, child: Text(S.deelVerifyTitle, style: t.textTheme.headlineSmall)),
          const SizedBox(height: Gap.m),
          Text(S.deelVerifyBodyReceiver, style: t.textTheme.bodyLarge),
          const SizedBox(height: Gap.l),
          Center(
            child: Semantics(
              label: '${S.deelVerifyTitle} ${_code.split('').join(' ')}',
              child: ExcludeSemantics(
                child: Text(_code, style: t.textTheme.displayMedium?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: Gap.l),
          const Center(child: CircularProgressIndicator()),
        ]);
      case _Phase.preview:
        body = _preview(context);
      case _Phase.receiving:
        body = ListView(padding: Gap.page, children: [
          Text(S.deelReceiving, style: t.textTheme.titleLarge),
          const SizedBox(height: Gap.m),
          LinearProgressIndicator(value: _total == 0 ? null : _done / _total, minHeight: 8, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 8),
          Text(S.deelProgress(fmtBytes(_done), fmtBytes(_total)), style: t.textTheme.bodyMedium),
        ]);
      case _Phase.done:
        body = _center(Icon(Icons.check_circle_outline_rounded, size: 56, color: c.secondary), '${S.deelDone}\n$_summary');
      case _Phase.failed:
        body = _center(Icon(Icons.error_outline_rounded, size: 56, color: c.onSurfaceVariant), _error);
    }

    final finished = _phase == _Phase.done || _phase == _Phase.failed;
    return Scaffold(
      appBar: AppBar(title: const Text(S.scanTitle)),
      body: SafeArea(child: body),
      bottomNavigationBar: _phase == _Phase.preview
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: OutlinedButton(
                  onPressed: () async {
                    await _session?.cancel();
                    if (context.mounted) context.pop();
                  },
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(finished ? S.deelDocsDone : S.deelCancel),
                ),
              ),
            ),
    );
  }

  Widget _center(Widget top, String text) => Center(
        child: Padding(
          padding: Gap.page,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            top,
            const SizedBox(height: Gap.m),
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          ]),
        ),
      );

  Widget _preview(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final m = _manifest!;
    final vault = ref.watch(vaultProvider);
    final ownHasPlan = ref.watch(planProvider).value?.hasContent ?? false;
    final df = DateFormat('d MMM yyyy', 'nl_NL');
    final rel = _existing == null ? VersionRelation.newer : compareVersions(existing: _existing!.version, incoming: m.planVersion);
    final canTake = (_takePlan && m.hasPlan) || _docs.isNotEmpty;
    final date = m.planUpdatedAt == null ? '' : df.format(m.planUpdatedAt!.toLocal());

    return ListView(padding: Gap.page, children: [
      Semantics(header: true, child: Text(S.previewTitle, style: t.textTheme.headlineSmall)),
      const SizedBox(height: 4),
      Text(S.previewFrom(m.senderName.isEmpty ? '?' : m.senderName), style: t.textTheme.titleMedium),
      const SizedBox(height: Gap.m),
      if (m.hasPlan)
        SoftCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _takePlan,
              onChanged: rel == VersionRelation.newer ? (v) => setState(() => _takePlan = v ?? false) : null,
              title: Text(S.previewPlan(m.planVersion, date)),
            ),
            if (rel != VersionRelation.newer)
              Text(S.previewUpToDate, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant))
            else if (_existing != null) ...[
              Text(S.previewNewVersion(m.planVersion, date), style: t.textTheme.titleSmall),
              if (_changed.isNotEmpty)
                Text(S.previewChanged(_changed.map(sectionLabel).join(', ')), style: t.textTheme.bodyMedium),
            ],
            if (m.planSections.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(S.previewSections, style: t.textTheme.labelLarge),
              Text(m.planSections.map(sectionLabel).join(', '), style: t.textTheme.bodyMedium),
            ],
            if (_takePlan && _existing == null) ...[
              const SizedBox(height: 12),
              Text(S.previewSaveAs, style: t.textTheme.labelLarge),
              RadioGroup<bool>(
                groupValue: _saveOwn,
                onChanged: (v) => setState(() => _saveOwn = v ?? false),
                child: Column(children: [
                  const RadioListTile<bool>(contentPadding: EdgeInsets.zero, value: false, title: Text(S.previewSaveShared)),
                  if (!ownHasPlan) const RadioListTile<bool>(contentPadding: EdgeInsets.zero, value: true, title: Text(S.previewSaveOwn)),
                ]),
              ),
              if (ownHasPlan) Text(S.previewHaveOwn, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
            ],
          ]),
        )
      else
        Text(S.previewNoPlan, style: t.textTheme.bodyMedium),
      if (m.docs.isNotEmpty) ...[
        SectionHeader(S.previewDocs, padding: const EdgeInsets.only(top: Gap.m, bottom: Gap.s)),
        Text(S.previewPickDocs, style: t.textTheme.bodyMedium),
        const SizedBox(height: 8),
        if (vault.status == VaultStatus.notSetUp)
          _vaultNote(S.previewNoVault, S.previewSetUpVault)
        else if (!vault.unlocked)
          _vaultNote(S.previewVaultLocked, S.previewUnlockVault),
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < m.docs.length; i++) ...[
              if (i > 0) const Divider(indent: 16, endIndent: 16),
              CheckboxListTile(
                value: _docs.contains(m.docs[i].id),
                onChanged: vault.unlocked
                    ? (v) => setState(() => v == true ? _docs.add(m.docs[i].id) : _docs.remove(m.docs[i].id))
                    : null,
                title: Text(m.docs[i].title),
                subtitle: Text(S.previewDocLine(typeLabel(vault.meta, m.docs[i].typeId), fmtBytes(m.docs[i].totalBytes))),
              ),
            ],
          ]),
        ),
      ],
      const SizedBox(height: Gap.m),
      Text(S.previewWarnNoDelete, style: t.textTheme.bodySmall),
      const SizedBox(height: Gap.l),
      FilledButton(
        onPressed: canTake
            ? () => _session?.choose(ReceiverSelection(plan: _takePlan && m.hasPlan, docIds: {..._docs}))
            : null,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        child: Text(_existing != null && rel == VersionRelation.newer ? S.previewUpdate : S.previewTake),
      ),
      if (!canTake) Padding(padding: const EdgeInsets.only(top: 6), child: Text(S.previewNothingChosen, style: t.textTheme.bodySmall)),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () async {
          _session?.choose(null);
          if (mounted) context.pop();
        },
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: const Text(S.deelCancel),
      ),
    ]);
  }

  Widget _vaultNote(String text, String action) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SoftCard(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          borderColor: Colors.transparent,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer)),
            const SizedBox(height: 8),
            FilledButton.tonal(onPressed: () => context.push('/kluis'), child: Text(action)),
          ]),
        ),
      );
}
