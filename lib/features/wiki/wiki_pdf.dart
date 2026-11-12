import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart' show BuildContext, ScaffoldMessenger, SnackBar, Text;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../noodplan/domain/plan_models.dart';
import '../noodplan/domain/plan_share.dart';
import '../noodplan/ui/plan_pdf.dart';
import '../rampenzender/rampenzender_strings.dart';
import 'wiki_models.dart';

/// Stappenplannen op de meterkastkaart (de meest voorkomende thuis-situaties).
const meterkastPlanIds = [
  'stroomstoring',
  'brand-in-huis',
  'gaslucht',
  'sirene-nl-alert',
  'uitval-water',
];

/// Maakt de afdrukbare kaart (A4). Alleen inhoud uit de wiki-JSON, geen netwerk.
Future<Uint8List> buildMeterkastPdf(WikiData d, {List<String> radioLines = const []}) async {
  // Roboto (Apache 2.0) uit de assets: ondersteunt tekens zoals ë en €.
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  final doc = pw.Document(title: S.wikiPdfTitle, author: S.appName);
  final plans = [
    for (final id in meterkastPlanIds) ?d.byId(id),
  ];

  pw.Widget heading(String t, {double size = 16}) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(t,
            style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold)),
      );

  pw.Widget steps(List<String> list) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < list.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                      width: 18,
                      child: pw.Text('${i + 1}.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(child: pw.Text(list[i])),
                ],
              ),
            ),
        ],
      );

  pw.Widget plan(WikiEmergency e) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          heading(e.titel),
          pw.Text(e.intro),
          pw.SizedBox(height: 4),
          steps(e.alleStappen),
          for (final c in e.contacten)
            pw.Text('${c.label}: ${c.nummer}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      header: (_) => pw.Text(S.wikiPdfTitle,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      footer: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(S.wikiRule, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(S.disclaimer, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
              '${S.wikiReviewed(fmtDate(d.eersteUur.lastReviewed))}. '
              'Bron: denkvooruit.nl en andere officiële sites. '
              '${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
      build: (_) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
          child: pw.Text(S.wikiRule,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ),
        heading(d.eersteUur.titel, size: 18),
        steps(d.eersteUur.stappenNu),
        if (radioLines.isNotEmpty) ...[
          heading(RZ.planRadioLabel),
          for (final l in radioLines) pw.Padding(padding: const pw.EdgeInsets.only(bottom: 3), child: pw.Text(l)),
        ],
        for (final e in plans) plan(e),
      ],
    ),
  );
  return doc.save();
}

/// Opent het systeem-printmenu (afdrukken, opslaan als PDF of delen).
/// Is er een noodplan, dan is de meterkastkaart dat plan (met Eerste-uur kaart);
/// anders de standaardkaart met de belangrijkste stappenplannen.
Future<void> shareMeterkastCard(BuildContext context, WikiData d,
    {Plan? plan, List<String> radioLines = const []}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await Printing.layoutPdf(
      name: 'meterkastkaart.pdf',
      onLayout: (_) => plan != null && plan.hasContent
          ? buildPlanPdf(plan, const ShareOptions(),
              wiki: d, now: DateTime.now(), version: plan.sharedVersion + 1, radioLines: radioLines)
          : buildMeterkastPdf(d, radioLines: radioLines),
    );
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text(S.wikiPdfError)));
  }
}
