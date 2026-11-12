import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/l10n/strings.dart';
import '../../rampenzender/rampenzender_strings.dart';
import '../../wiki/wiki_models.dart';
import '../domain/plan_models.dart';
import '../domain/plan_share.dart';

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

/// A4-pdf van het noodplan (1-2 pagina's, groot lettertype, hoog contrast).
/// Werkt ook met een leeg plan. Foto's worden niet in de pdf opgenomen.
Future<Uint8List> buildPlanPdf(
  Plan plan,
  ShareOptions o, {
  required WikiData wiki,
  required DateTime now,
  required int version,
  List<String> radioLines = const [],
}) async {
  // Roboto (Apache 2.0) uit de assets: ondersteunt tekens zoals ë.
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  final doc = pw.Document(title: S.planDocTitleNoName, author: S.appName);

  const base = 11.0;
  pw.TextStyle b(double size) => pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold);

  pw.Widget heading(String t) => pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 12, bottom: 4),
        padding: const pw.EdgeInsets.only(bottom: 2),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1.5))),
        child: pw.Text(t, style: b(14)),
      );

  pw.Widget line(String label, String value, {bool bigValue = false}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(text: '$label: ', style: b(base)),
            pw.TextSpan(text: value, style: bigValue ? b(14) : const pw.TextStyle(fontSize: base)),
          ]),
        ),
      );

  final name = plan.householdName.trim();
  final widgets = <pw.Widget>[
    pw.Text(name.isEmpty ? S.planDocTitleNoName : S.planDocTitle(name), style: b(24)),
    pw.SizedBox(height: 2),
    pw.Text('${S.planDocDate(_date(now))}  ·  ${S.planDocVersion(version)}'),
    pw.SizedBox(height: 8),
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 2.5)),
      child: pw.Text(S.planDoc112, style: b(20)),
    ),
  ];

  void section(String title, List<pw.Widget> children) {
    if (children.isEmpty) return;
    widgets
      ..add(heading(title))
      ..addAll(children);
  }

  if (o.contacts) {
    section(S.planDocContacts, [
      for (final c in plan.contacts)
        if (c.name.trim().isNotEmpty || c.phone.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Expanded(
                flex: 5,
                child: pw.Text(
                  '${contactRoleLabel(c.role)}: ${[c.name.trim(), if (c.relation.trim().isNotEmpty) '(${c.relation.trim()})'].where((e) => e.isNotEmpty).join(' ')}',
                ),
              ),
              pw.Expanded(flex: 3, child: pw.Text(c.phone.trim(), style: b(16))),
            ]),
          ),
    ]);
  }
  if (o.places) {
    section(S.planDocPlaces, [
      for (final k in PlanKeys.placeKinds)
        if (!(plan.place(k)?.isEmpty ?? true))
          line(placeLabel(k),
              [plan.place(k)!.address.trim(), plan.place(k)!.notes.trim()].where((e) => e.isNotEmpty).join(', ')),
    ]);
  }
  if (o.agreements) {
    section(S.planDocAgreements, [
      for (final k in [...PlanKeys.agreementKeys, ...PlanKeys.neighbourKeys])
        if (plan.agreement(k).isNotEmpty) line(agreementLabel(k), plan.agreement(k)),
    ]);
  }
  if (o.home) {
    section(S.planDocHome, [
      for (final k in PlanKeys.homeKeys)
        if (plan.locationText(k).isNotEmpty) line(locationLabel(k), plan.locationText(k)),
    ]);
  }
  if (o.persons) {
    section(S.planDocPersons, [
      for (final m in plan.members)
        if (m.name.trim().isNotEmpty)
          line(
            m.name.trim(),
            [
              m.isPet ? S.planPetLabel : ageGroupLabel(m.ageGroup),
              if (m.needsHelp) S.planNeedsHelpShort,
              if (m.notes.trim().isNotEmpty) m.notes.trim(),
            ].join(', '),
          ),
    ]);
  }
  if (o.care) {
    section(S.planDocCare, [
      if (plan.medication.trim().isNotEmpty) line(S.planCareMedication, plan.medication.trim()),
      if (plan.devices.trim().isNotEmpty) line(S.planCareDevices, plan.devices.trim()),
      if (plan.allergies.trim().isNotEmpty) line(S.planCareAllergies, plan.allergies.trim()),
      if (plan.caregiving.trim().isNotEmpty) line(S.planCareCaregiving, plan.caregiving.trim()),
      if (plan.documents.trim().isNotEmpty) line(S.planCareDocuments, plan.documents.trim()),
    ]);
  }

  // Rampenzender: de frequenties van de gekozen regio (alleen wat gecontroleerd is).
  section(RZ.planRadioLabel, [
    for (final l in radioLines) pw.Padding(padding: const pw.EdgeInsets.only(bottom: 3), child: pw.Text(l)),
  ]);

  // Verkleinde Eerste-uur kaart.
  final first = wiki.eersteUur;
  widgets
    ..add(heading(S.planDocFirstHour))
    ..add(pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        for (var i = 0; i < first.stappenNu.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text('${i + 1}. ${first.stappenNu[i]}', style: const pw.TextStyle(fontSize: 9)),
          ),
      ]),
    ));

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(34),
      theme: pw.ThemeData.withFont(base: regular, bold: bold).copyWith(
        defaultTextStyle: pw.TextStyle(font: regular, fontSize: base, color: PdfColors.black),
      ),
      footer: (ctx) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(S.planDocFooter, style: const pw.TextStyle(fontSize: 8.5)),
        pw.Text('${ctx.pageNumber}/${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8.5)),
      ]),
      build: (_) => widgets,
    ),
  );
  return doc.save();
}
