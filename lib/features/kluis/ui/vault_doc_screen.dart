import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/format.dart';
import '../../../core/l10n/strings.dart';
import '../data/vault_controller.dart';
import '../domain/vault_models.dart';
import 'vault_share.dart';
import 'vault_widgets.dart';

/// Document bekijken: pagina's met zoomen, gegevens, delen, bewerken, verwijderen.
/// Afbeeldingen en pdf-pagina's worden alleen in het geheugen ontsleuteld.
class VaultDocScreen extends ConsumerStatefulWidget {
  const VaultDocScreen({super.key, required this.docId});
  final String docId;

  @override
  ConsumerState<VaultDocScreen> createState() => _VaultDocScreenState();
}

class _VaultDocScreenState extends ConsumerState<VaultDocScreen> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    // Gedecodeerde afbeeldingen niet in de cache laten staan.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    super.dispose();
  }

  Future<void> _delete(VaultDocument doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text(S.vaultDeleteTitle),
        content: const Text(S.vaultDeleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text(S.vaultDelete)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(vaultProvider.notifier).deleteDocument(doc.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(vaultProvider);
    final doc = v.meta.documents.where((d) => d.id == widget.docId).firstOrNull;
    if (doc == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text(S.vaultDocNotFound)));
    }
    final t = Theme.of(context);
    final info = [
      typeLabel(v.meta, doc.typeId),
      if (doc.owner.isNotEmpty) doc.owner,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: doc.emergency ? S.vaultFieldNoodmap : S.vaultNoodmap,
            icon: Icon(doc.emergency ? Icons.star : Icons.star_border),
            onPressed: () => ref.read(vaultProvider.notifier).toggleEmergency(doc.id),
          ),
          IconButton(
            tooltip: S.vaultShare,
            icon: const Icon(Icons.ios_share),
            onPressed: () => shareVaultDocument(context, ref, doc),
          ),
          PopupMenuButton<String>(
            onSelected: (x) {
              if (x == 'edit') context.push('/kluis/toevoegen?doc=${doc.id}');
              if (x == 'delete') _delete(doc);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text(S.vaultEdit)),
              PopupMenuItem(value: 'delete', child: Text(S.vaultDelete)),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: doc.pages.isEmpty
              ? const Center(child: Text(S.vaultViewerError))
              : PageView.builder(
                  controller: _page,
                  itemCount: doc.pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _PageView(page: doc.pages[i]),
                ),
        ),
        Material(
          color: t.colorScheme.surfaceContainerLow,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (doc.pages.length > 1)
                  Semantics(
                    liveRegion: true,
                    child: Text(S.vaultPageOf(_index + 1, doc.pages.length), style: t.textTheme.titleSmall),
                  ),
                Text(info, style: t.textTheme.bodyMedium),
                if (doc.expiry != null) ...[
                  const SizedBox(height: 4),
                  Text(S.vaultExpiresOn(fmtDate(doc.expiry!))),
                  const SizedBox(height: 4),
                  DocExpiryBadge(doc: doc),
                ],
                if (doc.note.isNotEmpty) ...[const SizedBox(height: 4), Text(doc.note)],
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PageView extends ConsumerWidget {
  const _PageView({required this.page});
  final VaultPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(vaultBytesProvider(page.fileId));
    return bytes.when(
      loading: () => const Center(child: CircularProgressIndicator(semanticsLabel: S.loading)),
      error: (_, _) => const Center(child: Text(S.vaultViewerError)),
      data: (b) => page.isPdf ? _PdfPages(bytes: b) : _ZoomImage(bytes: b),
    );
  }
}

class _ZoomImage extends StatelessWidget {
  const _ZoomImage({required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 6,
      child: Center(
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text(S.vaultHeicNote, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

/// Pdf-pagina's als afbeeldingen, in het geheugen gerenderd.
class _PdfPages extends StatefulWidget {
  const _PdfPages({required this.bytes});
  final Uint8List bytes;

  @override
  State<_PdfPages> createState() => _PdfPagesState();
}

class _PdfPagesState extends State<_PdfPages> {
  late final Future<List<Uint8List>> _pages = _render();

  Future<List<Uint8List>> _render() async {
    final out = <Uint8List>[];
    await for (final r in Printing.raster(widget.bytes, dpi: 110)) {
      out.add(await r.toPng());
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Uint8List>>(
      future: _pages,
      builder: (c, s) {
        if (s.hasError) return const Center(child: Text(S.vaultViewerError));
        if (!s.hasData) return const Center(child: CircularProgressIndicator(semanticsLabel: S.loading));
        return InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: ListView(children: [
            for (final p in s.data!)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Image.memory(p, fit: BoxFit.fitWidth)),
          ]),
        );
      },
    );
  }
}
