import 'package:flutter/foundation.dart' show visibleForTesting;
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

/// Opent een URL in de externe browser. Apart zodat een test de browser kan vervangen.
Future<bool> startExternalUrl(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

typedef UrlStarter = Future<bool> Function(Uri uri);

/// Alleen voor tests: vervang de browser. Zet na afloop terug op [startExternalUrl].
@visibleForTesting
UrlStarter siteUrlStarter = startExternalUrl;

/// Opent een pagina van de website in de externe browser. Lukt dat niet, dan volgt
/// een rustige melding en gebeurt er verder niets (geen crash, geen andere netwerkaanroep).
Future<void> openSitePage(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await siteUrlStarter(Uri.parse(url));
  } catch (_) {}
  if (!ok) messenger.showSnackBar(const SnackBar(content: Text(S.legalNeedsInternet)));
}
