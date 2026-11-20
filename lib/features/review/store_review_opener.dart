import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/store_urls.dart';
import '../../core/dialer.dart';

enum StoreReviewResult { opened, offline, failed }

/// Is er internet? Een DNS-opzoeking van de winkel zelf (er wordt niets verstuurd of gelezen).
typedef HostCheck = Future<bool> Function(String host);

Future<bool> hostReachable(String host) async {
  try {
    final r = await InternetAddress.lookup(host).timeout(const Duration(seconds: 3));
    return r.isNotEmpty && r.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// De handmatige route: opent de winkelpagina om een beoordeling te schrijven. Dit is een gewone link, geen systeemprompt
/// (de systeem-API wordt nooit via een knop aangeroepen). iOS: de echte App Store-pagina met `action=write-review`.
/// Android: de Play Store-pagina op basis van het pakket-id.
class StoreReviewOpener {
  StoreReviewOpener({UrlStarter? start, HostCheck? reachable, TargetPlatform? platform})
      : _start = start ?? startExternalUrl,
        _reachable = reachable ?? hostReachable,
        _platform = platform;

  final UrlStarter _start;
  final HostCheck _reachable;
  final TargetPlatform? _platform;

  TargetPlatform get platform => _platform ?? defaultTargetPlatform;

  Uri get url {
    final apple = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    return Uri.parse(apple ? appStoreReviewUrl : playStoreUrl);
  }

  /// Rustig: geen internet of niet te openen geeft een uitkomst terug, nooit een fout.
  Future<StoreReviewResult> open() async {
    final u = url;
    if (!await _reachable(u.host)) return StoreReviewResult.offline;
    try {
      return await _start(u) ? StoreReviewResult.opened : StoreReviewResult.failed;
    } catch (_) {
      return StoreReviewResult.failed;
    }
  }
}

final storeReviewOpenerProvider = Provider<StoreReviewOpener>((ref) => StoreReviewOpener());
