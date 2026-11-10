import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/strings.dart';

/// Opent alleen de telefoon-app met het nummer ingevuld; belt nooit automatisch.
Future<void> openDialer(BuildContext context, String number) async {
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await launchUrl(Uri(scheme: 'tel', path: number.replaceAll(' ', '')));
  } catch (_) {}
  if (!ok) messenger.showSnackBar(const SnackBar(content: Text(S.wikiCallError)));
}

/// Opent een bron in de externe browser.
Future<void> openExternal(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok) messenger.showSnackBar(const SnackBar(content: Text(S.wikiOpenLinkError)));
}
