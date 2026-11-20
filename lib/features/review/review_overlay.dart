import 'package:flutter/material.dart';

/// Houdt bij of er een dialoog, bottom sheet, menu of ander venster openstaat (alles wat een `PopupRoute` is, dus ook
/// de paywall en het bevestigingsscherm van een aankoop). Zolang dat zo is, vragen we niet om een beoordeling.
class ReviewOverlayObserver extends NavigatorObserver {
  /// Aantal openstaande vensters.
  final ValueNotifier<int> open = ValueNotifier(0);

  void _bump(Route<dynamic>? route, int delta) {
    if (route is PopupRoute) open.value = (open.value + delta).clamp(0, 1 << 20);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _bump(route, 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _bump(route, -1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _bump(route, -1);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _bump(oldRoute, -1);
    _bump(newRoute, 1);
  }
}
