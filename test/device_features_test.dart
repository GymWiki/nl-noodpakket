import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/core/device_features.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('nl.mijnnoodpakket/device');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  PlatformDeviceFeatures android() => PlatformDeviceFeatures(platform: TargetPlatform.android);

  test('Android: de antwoorden van het systeem worden doorgegeven', () async {
    final asked = <Object?>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      asked.add(call.arguments);
      return false;
    });
    expect(await android().hasCamera(), isFalse);
    expect(await android().hasWifi(), isFalse);
    expect(asked, [PlatformDeviceFeatures.cameraFeature, PlatformDeviceFeatures.wifiFeature]);
  });

  test('een fout of ontbrekend kanaal geeft geen crash: we gaan ervan uit dat het kan', () async {
    expect(await android().hasCamera(), isTrue);
    messenger.setMockMethodCallHandler(channel, (call) async => throw PlatformException(code: 'x'));
    expect(await android().hasWifi(), isTrue);
  });

  test('andere platformen: altijd true, kanaal wordt niet gebruikt', () async {
    var called = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      called = true;
      return false;
    });
    final ios = PlatformDeviceFeatures(platform: TargetPlatform.iOS);
    expect(await ios.hasCamera(), isTrue);
    expect(called, isFalse);
  });
}
