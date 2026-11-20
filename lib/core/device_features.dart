import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Welke hardware heeft dit toestel? Google Play toont de app ook op toestellen zonder camera of wifi (die features zijn
/// bewust niet verplicht in het manifest). Het scannen en het delen via QR moeten daar rustig melden dat ze niet kunnen; de
/// rest van de app blijft werken. Is het antwoord onbekend (een fout, of een ander platform dan Android), dan gaan we ervan
/// uit dat de hardware er is: de scanner- en netwerkfouten zelf vangen de rest op.
abstract class DeviceFeatures {
  /// Is er een camera (voor- of achterzijde)?
  Future<bool> hasCamera();

  /// Is er wifi-hardware? (Een toestel zonder wifi kan wel een ander lokaal netwerk hebben, bijvoorbeeld ethernet.)
  Future<bool> hasWifi();
}

class PlatformDeviceFeatures implements DeviceFeatures {
  PlatformDeviceFeatures({MethodChannel? channel, TargetPlatform? platform})
      : _channel = channel ?? const MethodChannel('nl.mijnnoodpakket/device'),
        _platform = platform;

  final MethodChannel _channel;
  final TargetPlatform? _platform;

  /// Systeemfeatures zoals Android ze noemt (PackageManager.hasSystemFeature).
  static const cameraFeature = 'android.hardware.camera.any';
  static const wifiFeature = 'android.hardware.wifi';

  Future<bool> _has(String feature) async {
    if ((_platform ?? defaultTargetPlatform) != TargetPlatform.android) return true;
    try {
      return await _channel.invokeMethod<bool>('hasSystemFeature', feature) ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<bool> hasCamera() => _has(cameraFeature);

  @override
  Future<bool> hasWifi() => _has(wifiFeature);
}

final deviceFeaturesProvider = Provider<DeviceFeatures>((ref) => PlatformDeviceFeatures());

final hasCameraProvider = FutureProvider<bool>((ref) => ref.watch(deviceFeaturesProvider).hasCamera());
