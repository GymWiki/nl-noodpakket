import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/strings.dart';
import '../crypto/vault_crypto.dart';
import '../data/vault_controller.dart';
import '../data/vault_files.dart';
import '../domain/vault_models.dart';

String _today() {
  final n = DateTime.now();
  return '${n.day.toString().padLeft(2, '0')}-${n.month.toString().padLeft(2, '0')}-${n.year}';
}

/// Zet een diagonaal, herhaald watermerk over een afbeelding (zoals de overheid
/// adviseert bij kopieën van een ID). Geeft een JPEG terug.
Future<Uint8List> applyWatermark(Uint8List bytes, String text) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final w = image.width.toDouble(), h = image.height.toDouble();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
  canvas.drawImage(image, Offset.zero, Paint());

  final fontSize = max(w, h) / 26;
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: const Color(0x99C62828),
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        shadows: const [Shadow(color: Color(0x80FFFFFF), blurRadius: 2)],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final diag = sqrt(w * w + h * h);
  final stepX = painter.width + fontSize * 2;
  final stepY = fontSize * 3.4;
  canvas.save();
  canvas.translate(w / 2, h / 2);
  canvas.rotate(-0.5);
  var row = 0;
  for (var y = -diag; y < diag; y += stepY, row++) {
    final shift = row.isEven ? 0.0 : stepX / 2;
    for (var x = -diag; x < diag; x += stepX) {
      painter.paint(canvas, Offset(x + shift, y));
    }
  }
  canvas.restore();

  final picture = recorder.endRecording();
  final out = await picture.toImage(image.width, image.height);
  final data = await out.toByteData(format: ui.ImageByteFormat.rawRgba);
  final width = image.width, height = image.height;
  image.dispose();
  out.dispose();
  final rgba = data!.buffer.asUint8List();
  final jpg = await Isolate.run(() {
    final im = img.Image.fromBytes(width: width, height: height, bytes: rgba.buffer, numChannels: 4);
    return Uint8List.fromList(img.encodeJpg(im, quality: 88));
  });
  zero(rgba);
  return jpg;
}

class _ShareChoice {
  const _ShareChoice({required this.watermark, this.text = ''});
  final bool watermark;
  final String text;
}

/// Bewust delen: eerst een waarschuwing, bij identiteitsdocumenten een optioneel
/// watermerk, daarna het deelmenu. Het gedecodeerde tijdelijke bestand wordt
/// daarna overschreven en verwijderd.
Future<void> shareVaultDocument(BuildContext context, WidgetRef ref, VaultDocument doc) async {
  final ctl = ref.read(vaultProvider.notifier);
  final meta = ref.read(vaultProvider).meta;
  final identity = meta.typeOf(doc.typeId)?.identity ?? false;
  final messenger = ScaffoldMessenger.of(context);
  final hasImages = doc.pages.any((p) => !p.isPdf);

  final choice = await showDialog<_ShareChoice>(
    context: context,
    builder: (c) => _ShareDialog(identity: identity && hasImages, hasPdf: doc.pages.any((p) => p.isPdf)),
  );
  if (choice == null) return;

  final env = await ref.read(vaultEnvProvider.future);
  final dir = env.tmpDir;
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final written = <File>[];
  try {
    final files = <XFile>[];
    for (var i = 0; i < doc.pages.length; i++) {
      final page = doc.pages[i];
      var bytes = await ctl.readFile(page.fileId);
      var ext = page.isPdf ? 'pdf' : (page.mime == 'image/png' ? 'png' : (page.mime == 'image/heic' ? 'heic' : 'jpg'));
      if (choice.watermark && !page.isPdf && page.mime != 'image/heic') {
        final marked = await applyWatermark(bytes, choice.text);
        zero(bytes);
        bytes = marked;
        ext = 'jpg';
      }
      final f = File(p.join(dir.path, '${const Uuid().v4()}.$ext'));
      await f.writeAsBytes(bytes, flush: true);
      zero(bytes);
      written.add(f);
      files.add(XFile(f.path, mimeType: page.isPdf ? 'application/pdf' : (ext == 'png' ? 'image/png' : (ext == 'heic' ? 'image/heic' : 'image/jpeg'))));
    }
    final result = await ctl.external(() => SharePlus.instance.share(ShareParams(files: files)));
    // Android meldt niet altijd wat er met het bestand gebeurt; geef de
    // ontvangende app dan even tijd. Restanten worden ook bij de volgende start opgeruimd.
    final delay = result.status == ShareResultStatus.unavailable ? const Duration(seconds: 90) : Duration.zero;
    unawaited(Future<void>.delayed(delay, () async {
      for (final f in written) {
        await wipeFile(f);
      }
    }));
  } catch (_) {
    for (final f in written) {
      await wipeFile(f);
    }
    messenger.showSnackBar(const SnackBar(content: Text(S.vaultShareError)));
  }
}

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({required this.identity, required this.hasPdf});
  final bool identity, hasPdf;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  bool _mark = true;
  final _purpose = TextEditingController();
  final _date = TextEditingController(text: _today());

  @override
  void dispose() {
    _purpose.dispose();
    _date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(S.vaultShareTitle),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(S.vaultShareWarn),
          if (widget.identity) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(S.vaultWatermark),
              value: _mark,
              onChanged: (v) => setState(() => _mark = v),
            ),
            if (_mark) ...[
              TextField(
                controller: _purpose,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: S.vaultWatermarkPurpose),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(controller: _date, decoration: const InputDecoration(labelText: S.vaultWatermarkDate)),
            ],
            const SizedBox(height: 8),
            Text(S.vaultWatermarkTip, style: Theme.of(context).textTheme.bodySmall),
            if (widget.hasPdf)
              Text(S.vaultSharePdfNoWatermark, style: Theme.of(context).textTheme.bodySmall),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(S.cancel)),
        FilledButton(
          onPressed: widget.identity && _mark && _purpose.text.trim().isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    _ShareChoice(
                      watermark: widget.identity && _mark,
                      text: '${_purpose.text.trim()} ${_date.text.trim()}'.trim(),
                    ),
                  ),
          child: const Text(S.vaultShareConfirm),
        ),
      ],
    );
  }
}
