import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../core/format.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../noodplan/plan_providers.dart';
import '../crypto/vault_crypto.dart';
import '../data/vault_controller.dart';
import '../data/vault_files.dart';
import '../data/vault_images.dart';
import '../domain/vault_models.dart';
import 'vault_widgets.dart';

class _Draft {
  _Draft(this.bytes, {this.thumb});
  final Uint8List bytes;
  final Uint8List? thumb;
  bool get isPdf => sniffMime(bytes) == 'application/pdf';
}

/// Document toevoegen of bewerken (scan, foto, bestand; meerdere pagina's).
class VaultAddScreen extends ConsumerStatefulWidget {
  const VaultAddScreen({super.key, this.docId});
  final String? docId;

  @override
  ConsumerState<VaultAddScreen> createState() => _VaultAddScreenState();
}

class _VaultAddScreenState extends ConsumerState<VaultAddScreen> {
  final _title = TextEditingController();
  final _ownerFree = TextEditingController();
  final _note = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _typeId = 'other';
  String _owner = '';
  DateTime? _expiry;
  bool _emergency = false;
  final _drafts = <_Draft>[];
  List<VaultPage> _existing = const [];
  final _removed = <String>{};
  VaultDocument? _doc;
  bool _loaded = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _ownerFree.dispose();
    _note.dispose();
    // Wis de ruwe bytes van nog niet opgeslagen pagina's.
    for (final d in _drafts) {
      zero(d.bytes);
    }
    super.dispose();
  }

  void _load(VaultDocument d) {
    _loaded = true;
    _doc = d;
    _title.text = d.title;
    _typeId = d.typeId;
    _owner = d.owner;
    _expiry = d.expiry;
    _note.text = d.note;
    _emergency = d.emergency;
    _existing = d.pages;
  }

  void _say(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  /// Verwijdert tijdelijke kopieën van de scanner/kiezer, maar nooit een
  /// origineel van de gebruiker (alleen bestanden in de cachemap).
  Future<void> _wipeIfTemp(String path) async {
    try {
      final tmp = (await getTemporaryDirectory()).path;
      final cache = (await getApplicationCacheDirectory()).path;
      if (path.startsWith(tmp) || path.startsWith(cache) || path.contains('/cache/')) {
        await wipeFile(File(path));
      }
    } catch (_) {}
  }

  Future<Uint8List?> _pdfThumb(Uint8List bytes) async {
    try {
      await for (final r in Printing.raster(bytes, pages: const [0], dpi: 48)) {
        final processed = await processImage(await r.toPng());
        return processed?.thumb;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _addBytes(Uint8List bytes) async {
    if (bytes.length > maxFileBytes) {
      _say(S.vaultFileTooBig);
      return;
    }
    final mime = sniffMime(bytes);
    if (mime == null) {
      _say(S.vaultUnsupportedFile);
      return;
    }
    final thumb = mime == 'application/pdf' ? await _pdfThumb(bytes) : null;
    if (mounted) setState(() => _drafts.add(_Draft(bytes, thumb: thumb)));
  }

  Future<void> _scan() async {
    final ctl = ref.read(vaultProvider.notifier);
    try {
      final result = await ctl.external(
        () => CunningDocumentScanner.scanDocuments(noOfPages: 12, scannerSource: ScannerSource.camera),
      );
      for (final path in result?.images ?? const <String>[]) {
        await _addBytes(await File(path).readAsBytes());
        await _wipeIfTemp(path);
      }
      await CunningDocumentScanner.cleanCache();
    } on CunningDocumentScannerException catch (e) {
      _say(e.code == 'permission_denied' ? S.vaultCameraDenied : S.vaultScanError);
    } catch (_) {
      _say(S.vaultScanError);
    }
  }

  Future<void> _gallery() async {
    final ctl = ref.read(vaultProvider.notifier);
    try {
      final picked = await ctl.external(() => ImagePicker().pickMultiImage());
      for (final x in picked) {
        await _addBytes(await x.readAsBytes());
        await _wipeIfTemp(x.path);
      }
    } catch (_) {
      _say(S.vaultScanError);
    }
  }

  Future<void> _file() async {
    final ctl = ref.read(vaultProvider.notifier);
    try {
      final res = await ctl.external(() => FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
          ));
      for (final f in res) {
        final path = f.path;
        if (path == null) continue;
        await _addBytes(await File(path).readAsBytes());
        await _wipeIfTemp(path);
      }
    } catch (_) {
      _say(S.vaultUnsupportedFile);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 40),
      locale: const Locale('nl', 'NL'),
    );
    if (d != null) setState(() => _expiry = DateTime(d.year, d.month, d.day));
  }

  Future<void> _newType() async {
    final name = TextEditingController();
    var identity = false;
    final t = await showDialog<VaultType>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          title: const Text(S.vaultNewType),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: S.vaultNewTypeName)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(S.vaultNewTypeIdentity),
              value: identity,
              onChanged: (v) => setS(() => identity = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text(S.cancel)),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                final created = await ref
                    .read(vaultProvider.notifier)
                    .addCustomType(name.text, identity: identity);
                if (c.mounted) Navigator.pop(c, created);
              },
              child: const Text(S.vaultSave),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    if (t != null) setState(() => _typeId = t.id);
  }

  Future<void> _askPermissionOnce() async {
    final repo = ref.read(settingsRepositoryProvider);
    final s = await repo.load();
    if (s.permissionAsked) return;
    await ref.read(notificationServiceProvider).requestPermission();
    await repo.save(s.copyWith(permissionAsked: true));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existing.length - _removed.length + _drafts.length == 0) {
      setState(() => _error = S.vaultPagesRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ctl = ref.read(vaultProvider.notifier);
    final owner = _ownerFree.text.trim().isNotEmpty ? _ownerFree.text.trim() : _owner;
    try {
      final pages = [for (final d in _drafts) NewPage(d.bytes, thumb: d.thumb)];
      if (_doc == null) {
        await ctl.addDocument(NewDocument(
          title: _title.text,
          typeId: _typeId,
          owner: owner,
          expiry: _expiry,
          note: _note.text,
          emergency: _emergency,
          pages: pages,
        ));
      } else {
        await ctl.updateDocument(
          _doc!.copyWith(
            title: _title.text.trim(),
            typeId: _typeId,
            owner: owner,
            expiry: _expiry,
            clearExpiry: _expiry == null,
            note: _note.text.trim(),
            emergency: _emergency,
          ),
          addPages: pages,
          removePageFileIds: _removed,
        );
      }
      if (_expiry != null) await _askPermissionOnce();
      if (mounted) context.pop();
    } on VaultTooBigException {
      _fail(S.vaultFileTooBig);
    } on VaultUnsupportedException {
      _fail(S.vaultUnsupportedFile);
    } catch (_) {
      _fail(S.vaultSaveError);
    }
  }

  void _fail(String m) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = m;
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(vaultProvider);
    if (widget.docId != null && !_loaded) {
      final d = v.meta.documents.where((d) => d.id == widget.docId).firstOrNull;
      if (d == null) {
        return Scaffold(appBar: AppBar(), body: const Center(child: Text(S.vaultDocNotFound)));
      }
      _load(d);
    }
    final t = Theme.of(context);
    final planNames = [
      for (final m in ref.watch(planProvider).value?.members ?? const []) if (!m.isPet && m.name.trim().isNotEmpty) m.name.trim(),
    ];
    final ownerChoices = <String>{...planNames, if (_owner.isNotEmpty) _owner}.toList();
    final types = v.meta.allTypes;

    return Scaffold(
      appBar: AppBar(title: Text(_doc == null ? S.vaultAddTitle : S.vaultEditTitle)),
      body: Stack(children: [
        Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Semantics(header: true, child: Text(S.vaultPages, style: t.textTheme.titleMedium)),
              const SizedBox(height: 8),
              SizedBox(
                height: 112,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final p in _existing.where((p) => !_removed.contains(p.fileId)))
                    _PageThumb(
                      label: S.vaultPageLabel(_existing.indexOf(p) + 1),
                      child: _ExistingThumb(page: p),
                      onRemove: () => setState(() => _removed.add(p.fileId)),
                    ),
                  for (var i = 0; i < _drafts.length; i++)
                    _PageThumb(
                      label: S.vaultPageLabel(_existing.length - _removed.length + i + 1),
                      child: _drafts[i].thumb != null
                          ? Image.memory(_drafts[i].thumb!, fit: BoxFit.cover)
                          : _drafts[i].isPdf
                              ? const Icon(Icons.picture_as_pdf_outlined, size: 40)
                              : Image.memory(_drafts[i].bytes, fit: BoxFit.cover, cacheWidth: 200,
                                  errorBuilder: (_, _, _) => const Icon(Icons.image_outlined, size: 40)),
                      onRemove: () => setState(() {
                        zero(_drafts[i].bytes);
                        _drafts.removeAt(i);
                      }),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(onPressed: _busy ? null : _scan, icon: const Icon(Icons.document_scanner_outlined), label: const Text(S.vaultSourceScan)),
                OutlinedButton.icon(onPressed: _busy ? null : _gallery, icon: const Icon(Icons.photo_library_outlined), label: const Text(S.vaultSourceGallery)),
                OutlinedButton.icon(onPressed: _busy ? null : _file, icon: const Icon(Icons.attach_file), label: const Text(S.vaultSourceFile)),
              ]),
              const SizedBox(height: 4),
              Text(S.vaultNoNumbers, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: S.vaultFieldTitle),
                validator: (s) => (s == null || s.trim().isEmpty) ? S.vaultTitleRequired : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: types.any((x) => x.id == _typeId) ? _typeId : 'other',
                isExpanded: true,
                decoration: const InputDecoration(labelText: S.vaultFieldType),
                items: [
                  for (final ty in types) DropdownMenuItem(value: ty.id, child: Text(ty.label, overflow: TextOverflow.ellipsis)),
                  const DropdownMenuItem(value: '__new__', child: Text(S.vaultNewType)),
                ],
                onChanged: (x) {
                  if (x == '__new__') {
                    _newType();
                  } else {
                    setState(() => _typeId = x ?? 'other');
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: ownerChoices.contains(_owner) ? _owner : '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: S.vaultFieldOwner),
                items: [
                  const DropdownMenuItem(value: '', child: Text('—')),
                  for (final o in ownerChoices) DropdownMenuItem(value: o, child: Text(o)),
                ],
                onChanged: (x) => setState(() => _owner = x ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerFree,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: S.vaultFieldOwnerFree),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(S.vaultFieldExpiry),
                subtitle: Text(_expiry == null ? '—' : fmtDate(_expiry!)),
                trailing: _expiry == null
                    ? const Icon(Icons.calendar_today_outlined)
                    : IconButton(
                        tooltip: S.vaultClearExpiry,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _expiry = null),
                      ),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _note,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: S.vaultFieldNote),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(S.vaultFieldNoodmap),
                value: _emergency,
                onChanged: (x) => setState(() => _emergency = x),
              ),
              if (_error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(_error!, style: TextStyle(color: t.colorScheme.error)),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text(S.vaultSave),
              ),
            ],
          ),
        ),
        if (_busy)
          ColoredBox(
            color: t.colorScheme.surface.withValues(alpha: 0.85),
            child: const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text(S.vaultSaving),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _PageThumb extends StatelessWidget {
  const _PageThumb({required this.child, required this.label, required this.onRemove});
  final Widget child;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(children: [
        Semantics(
          label: label,
          image: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 96, height: 112, child: ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Center(child: child))),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton.filledTonal(
            tooltip: '${S.vaultRemovePage}: $label',
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ),
      ]),
    );
  }
}

class _ExistingThumb extends ConsumerWidget {
  const _ExistingThumb({required this.page});
  final VaultPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = page.thumbId;
    if (id == null) return Icon(page.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined, size: 40);
    return ref.watch(vaultBytesProvider(id)).when(
          data: (b) => Image.memory(b, fit: BoxFit.cover),
          loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, _) => const Icon(Icons.broken_image_outlined),
        );
  }
}
