import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/features/deel/protocol/channel.dart';
import 'package:mijnnoodpakket/features/deel/protocol/noise.dart';
import 'package:mijnnoodpakket/features/deel/protocol/receiver.dart';
import 'package:mijnnoodpakket/features/deel/protocol/sender.dart';
import 'package:mijnnoodpakket/features/deel/protocol/session_payload.dart';
import 'package:mijnnoodpakket/features/deel/protocol/transfer_models.dart';

Uint8List bytes(int n, [int seed = 1]) {
  final r = Random(seed);
  return Uint8List.fromList([for (var i = 0; i < n; i++) r.nextInt(256)]);
}

Future<void> until(bool Function() cond, {Duration timeout = const Duration(seconds: 8)}) async {
  final end = DateTime.now().add(timeout);
  while (!cond()) {
    if (DateTime.now().isAfter(end)) fail('time-out in test');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<OfferedPage> page(Uint8List data, {String? hash}) async =>
    OfferedPage(size: data.length, sha256: hash ?? await sha256Hex(data), read: () async => data);

class Rig {
  Rig(this.sender, this.sEvents);
  final ShareSenderSession sender;
  final List<SenderEvent> sEvents;
  ShareReceiverSession? receiver;
  final rEvents = <ReceiverEvent>[];
  final plans = <String>[];
  final docs = <ReceivedDocument>[];

  Future<void> connect(SessionPayload p, {bool failDoc = false}) async {
    receiver = await ShareReceiverSession.connect(
      p,
      deviceName: 'Pixel van Anna',
      onPlan: (json, m) async => plans.add(json),
      onDocument: (d) async {
        if (failDoc) throw StateError('kluis vol');
        docs.add(d);
      },
      idle: const Duration(seconds: 5),
    );
    receiver!.events.listen(rEvents.add);
  }

  T? sOf<T extends SenderEvent>() => sEvents.whereType<T>().firstOrNull;
  T? rOf<T extends ReceiverEvent>() => rEvents.whereType<T>().firstOrNull;
}

Future<Rig> rig(ShareOffer offer, {Duration window = const Duration(seconds: 20)}) async {
  final s = await ShareSenderSession.start(
    offer: offer,
    address: InternetAddress.loopbackIPv4,
    window: window,
    idle: const Duration(seconds: 5),
  );
  final events = <SenderEvent>[];
  s.events.listen(events.add);
  return Rig(s, events);
}

void main() {
  group('Noise NNpsk0: handshake', () {
    final psk = bytes(32, 7);
    final prologue = utf8.encode('proloog');

    Future<(NoiseTransport, NoiseTransport)> run({List<int>? pskB}) async {
      final a = NoiseHandshake.initiator(psk, prologue);
      final b = NoiseHandshake.responder(pskB ?? psk, prologue);
      await b.readMessage1(await a.writeMessage1());
      await a.readMessage2(await b.writeMessage2());
      return (await a.finish(), await b.finish());
    }

    test('beide kanten komen tot dezelfde code en kunnen elkaar versleuteld berichten sturen', () async {
      final (a, b) = await run();
      expect(await a.verificationCode(), await b.verificationCode());
      expect((await a.verificationCode()).length, 6);
      final ct = await a.send.encrypt(const [], utf8.encode('hallo'));
      expect(ct, isNot(contains(104))); // geen leesbare tekst
      expect(utf8.decode(await b.receive.decrypt(const [], ct)), 'hallo');
      final back = await b.send.encrypt(const [], utf8.encode('terug'));
      expect(utf8.decode(await a.receive.decrypt(const [], back)), 'terug');
    });

    test('verkeerd geheim faalt in bericht 1', () async {
      final a = NoiseHandshake.initiator(psk, prologue);
      final b = NoiseHandshake.responder(bytes(32, 9), prologue);
      expect(() async => b.readMessage1(await a.writeMessage1()), throwsA(isA<NoiseException>()));
    });

    test('andere sessie (prologue) faalt', () async {
      final a = NoiseHandshake.initiator(psk, prologue);
      final b = NoiseHandshake.responder(psk, utf8.encode('andere'));
      expect(() async => b.readMessage1(await a.writeMessage1()), throwsA(isA<NoiseException>()));
    });

    test('elke sessie krijgt andere sleutels en een andere code (verse sleutels)', () async {
      final codes = <String>{};
      final cts = <String>{};
      for (var i = 0; i < 5; i++) {
        final (a, _) = await run();
        codes.add(await a.verificationCode());
        cts.add(base64.encode(await a.send.encrypt(const [], [1, 2, 3])));
      }
      expect(cts.length, 5);
      expect(codes.length, greaterThan(1));
    });

    test('geknoeid, herhaald en verwisseld bericht worden geweigerd', () async {
      final (a, b) = await run();
      final m1 = await a.send.encrypt(const [], [1]);
      final m2 = await a.send.encrypt(const [], [2]);
      final tampered = Uint8List.fromList(m1)..[0] ^= 1;
      await expectLater(b.receive.decrypt(const [], tampered), throwsA(isA<NoiseException>()));
      // een mislukte poging verhoogt de teller niet: de echte m1 werkt nog
      expect(await b.receive.decrypt(const [], m1), [1]);
      // herhaling van m1 faalt (teller is verder)
      await expectLater(b.receive.decrypt(const [], m1), throwsA(isA<NoiseException>()));
      expect(await b.receive.decrypt(const [], m2), [2]);
      // volgorde omdraaien faalt
      final (c, d) = await run();
      final x = await c.send.encrypt(const [], [1]);
      final y = await c.send.encrypt(const [], [2]);
      await expectLater(d.receive.decrypt(const [], y), throwsA(isA<NoiseException>()));
      expect(await d.receive.decrypt(const [], x), [1]);
    });

    test('een afgekapt of verkeerd lang handshakebericht wordt geweigerd', () async {
      final a = NoiseHandshake.initiator(psk, prologue);
      final b = NoiseHandshake.responder(psk, prologue);
      final m1 = await a.writeMessage1();
      expect(() => b.readMessage1(m1.sublist(0, 40)), throwsA(isA<NoiseException>()));
    });
  });

  group('QR-inhoud', () {
    test('klein (ruim onder 200 bytes), bevat geen gegevens en wordt teruggelezen', () {
      final p = SessionPayload.create(host: '192.168.1.20', port: 51234);
      final s = p.encode();
      expect(utf8.encode(s).length, lessThan(120));
      final back = SessionPayload.tryParse(s)!;
      expect(back.host, '192.168.1.20');
      expect(back.port, 51234);
      expect(back.secret, p.secret);
      expect(back.sessionId, p.sessionId);
    });

    test('ongeldige of gevaarlijke inhoud wordt geweigerd', () {
      expect(SessionPayload.tryParse('https://example.com'), isNull);
      expect(SessionPayload.tryParse('nlnp1;8.8.8.8;80;AAAAAAAAAAA;${'A' * 43}'), isNull); // publiek adres
      expect(SessionPayload.tryParse('nlnp1;192.168.1.2;0;AAAAAAAAAAA;${'A' * 43}'), isNull);
      expect(SessionPayload.tryParse('nlnp9;192.168.1.2;80;x;y'), isNull);
      expect(SessionPayload.tryParse('nlnp1;192.168.1.2;80;kort;kort'), isNull);
      expect(SessionPayload.tryParse(''), isNull);
    });

    test('alleen privé-adressen mogen doel zijn', () {
      for (final h in ['10.0.0.5', '172.16.4.1', '192.168.0.9', '169.254.1.1']) {
        expect(isPrivateIPv4(h), isTrue, reason: h);
      }
      for (final h in ['8.8.8.8', '172.32.0.1', '1.2.3', 'example.com', '300.1.1.1']) {
        expect(isPrivateIPv4(h), isFalse, reason: h);
      }
    });
  });

  group('overdracht via loopback (beide kanten)', () {
    test('plan en documenten komen aan, byte voor byte, met dezelfde verificatiecode', () async {
      final doc1 = [bytes(5000, 1), bytes(100 * 1024 + 17, 2)]; // tweede pagina over meerdere chunks
      final doc2 = [bytes(1, 3)];
      final r = await rig(ShareOffer(
        senderName: 'Anna',
        planJson: '{"app":"x","v":1}',
        planId: 'plan-1',
        planVersion: 4,
        planSections: const ['contacts', 'places'],
        docs: [
          OfferedDocument(id: 'd1', title: 'Paspoort', typeId: 'passport', owner: 'Anna', pages: [for (final b in doc1) await page(b)]),
          OfferedDocument(id: 'd2', title: 'Polis', typeId: 'policy', pages: [for (final b in doc2) await page(b)]),
        ],
      ));
      await r.connect(SessionPayload.tryParse(r.sender.qrData)!);
      await until(() => r.sOf<SenderPeer>() != null && r.rOf<ReceiverCode>() != null);
      expect(r.sOf<SenderPeer>()!.code, r.rOf<ReceiverCode>()!.code);
      expect(r.sOf<SenderPeer>()!.deviceName, 'Pixel van Anna');
      r.sender.approve();
      await until(() => r.rOf<ReceiverManifest>() != null);
      final m = r.rOf<ReceiverManifest>()!.manifest;
      expect(m.planVersion, 4);
      expect(m.docs.map((d) => d.title), ['Paspoort', 'Polis']);
      r.receiver!.choose(const ReceiverSelection(plan: true, docIds: {'d1', 'd2'}));
      await until(() => r.rOf<ReceiverFinished>() != null && r.sOf<SenderFinished>() != null);
      expect(r.plans.single, '{"app":"x","v":1}');
      expect(r.docs.length, 2);
      expect(r.docs[0].pages[0], doc1[0]);
      expect(r.docs[0].pages[1], doc1[1]);
      expect(r.docs[1].pages.single, doc2[0]);
      expect(r.sOf<SenderFinished>()!.documents, 2);
    });

    test('de ontvanger kan een deel kiezen: alleen het plan, geen documenten', () async {
      final r = await rig(ShareOffer(
        senderName: 'Anna',
        planJson: '{"a":1}',
        planId: 'p',
        docs: [OfferedDocument(id: 'd1', title: 'ID', typeId: 'id', pages: [await page(bytes(10))])],
      ));
      await r.connect(SessionPayload.tryParse(r.sender.qrData)!);
      await until(() => r.sOf<SenderPeer>() != null);
      r.sender.approve();
      await until(() => r.rOf<ReceiverManifest>() != null);
      r.receiver!.choose(const ReceiverSelection(plan: true));
      await until(() => r.rOf<ReceiverFinished>() != null);
      expect(r.plans.length, 1);
      expect(r.docs, isEmpty);
    });

    test('niet toestaan: ontvanger krijgt niets, niets wordt opgeslagen', () async {
      final r = await rig(ShareOffer(senderName: 'A', planJson: '{}', planId: 'p'));
      await r.connect(SessionPayload.tryParse(r.sender.qrData)!);
      await until(() => r.sOf<SenderPeer>() != null);
      r.sender.deny();
      await until(() => r.rOf<ReceiverFailed>() != null);
      expect(r.rOf<ReceiverFailed>()!.error, ShareError.denied);
      expect(r.rOf<ReceiverManifest>(), isNull);
      expect(r.plans, isEmpty);
    });

    test('verkeerd QR-geheim: handshake faalt en de sessie wordt gesloten', () async {
      final r = await rig(ShareOffer(senderName: 'A', planJson: '{}', planId: 'p'));
      final good = SessionPayload.tryParse(r.sender.qrData)!;
      final bad = SessionPayload(host: good.host, port: good.port, sessionId: good.sessionId, secret: bytes(32, 99));
      await r.connect(bad);
      await until(() => r.rOf<ReceiverFailed>() != null);
      expect(r.rOf<ReceiverFailed>()!.error, ShareError.badHandshake);
      await until(() => r.sOf<SenderFailed>() != null);
      // de sessie is dicht: ook met het juiste geheim kan niemand meer verbinden
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(() => Socket.connect(good.host, good.port, timeout: const Duration(seconds: 1)), throwsA(anything));
    });

    test('verlopen sessie: server sluit en meldt "verlopen"', () async {
      final r = await rig(ShareOffer(senderName: 'A', planJson: '{}', planId: 'p'), window: const Duration(milliseconds: 300));
      final p = SessionPayload.tryParse(r.sender.qrData)!;
      await until(() => r.sOf<SenderExpired>() != null);
      await expectLater(Socket.connect(p.host, p.port, timeout: const Duration(seconds: 1)), throwsA(anything));
    });

    test('eenmalig: na een geslaagde overdracht is de QR niet meer te gebruiken', () async {
      final r = await rig(ShareOffer(senderName: 'A', planJson: '{}', planId: 'p'));
      final p = SessionPayload.tryParse(r.sender.qrData)!;
      await r.connect(p);
      await until(() => r.sOf<SenderPeer>() != null);
      r.sender.approve();
      await until(() => r.rOf<ReceiverManifest>() != null);
      r.receiver!.choose(const ReceiverSelection(plan: true));
      await until(() => r.sOf<SenderFinished>() != null);
      final r2 = Rig(r.sender, r.sEvents);
      await r2.connect(p);
      await until(() => r2.rOf<ReceiverFailed>() != null);
    });

    test('tweede toestel tijdens een lopende verbinding wordt geweigerd', () async {
      final r = await rig(ShareOffer(senderName: 'A', planJson: '{}', planId: 'p'));
      final p = SessionPayload.tryParse(r.sender.qrData)!;
      await r.connect(p);
      await until(() => r.sOf<SenderPeer>() != null);
      final other = Rig(r.sender, r.sEvents);
      await other.connect(p);
      await until(() => other.rOf<ReceiverFailed>() != null);
      // de eerste verbinding gaat gewoon door
      r.sender.approve();
      await until(() => r.rOf<ReceiverManifest>() != null);
      r.receiver!.choose(const ReceiverSelection(plan: true));
      await until(() => r.rOf<ReceiverFinished>() != null);
    });

    test('annuleren door de afzender: ontvanger krijgt een nette fout', () async {
      final r = await rig(ShareOffer(senderName: 'A', planJson: '{}', planId: 'p'));
      await r.connect(SessionPayload.tryParse(r.sender.qrData)!);
      await until(() => r.sOf<SenderPeer>() != null);
      await r.sender.cancel();
      await until(() => r.rOf<ReceiverFailed>() != null);
      expect(r.sOf<SenderCancelled>(), isNotNull);
    });

    test('hash komt niet overeen: document wordt niet opgeslagen', () async {
      final data = bytes(2000, 5);
      final r = await rig(ShareOffer(
        senderName: 'A',
        docs: [
          OfferedDocument(
            id: 'd1',
            title: 'Vals',
            typeId: 'x',
            // verwacht dat dit de hash van andere bytes is
            pages: [OfferedPage(size: data.length, sha256: await sha256Hex(bytes(2000, 6)), read: () async => data)],
          ),
        ],
      ));
      await r.connect(SessionPayload.tryParse(r.sender.qrData)!);
      await until(() => r.sOf<SenderPeer>() != null);
      r.sender.approve();
      await until(() => r.rOf<ReceiverManifest>() != null);
      r.receiver!.choose(const ReceiverSelection(docIds: {'d1'}));
      await until(() => r.rOf<ReceiverFailed>() != null);
      expect(r.rOf<ReceiverFailed>()!.error, ShareError.hashMismatch);
      expect(r.docs, isEmpty);
    });

    test('opslaan mislukt aan ontvangerkant: overdracht stopt netjes', () async {
      final r = await rig(ShareOffer(senderName: 'A', docs: [
        OfferedDocument(id: 'd1', title: 'A', typeId: 'x', pages: [await page(bytes(50))]),
        OfferedDocument(id: 'd2', title: 'B', typeId: 'x', pages: [await page(bytes(50, 2))]),
      ]));
      await r.connect(SessionPayload.tryParse(r.sender.qrData)!, failDoc: true);
      await until(() => r.sOf<SenderPeer>() != null);
      r.sender.approve();
      await until(() => r.rOf<ReceiverManifest>() != null);
      r.receiver!.choose(const ReceiverSelection(docIds: {'d1', 'd2'}));
      await until(() => r.rOf<ReceiverFailed>() != null && r.sOf<SenderFailed>() != null);
      expect(r.docs, isEmpty);
    });

    test('ontvanger annuleert in het voorbeeld: er wordt niets verstuurd', () async {
      final r = await rig(ShareOffer(senderName: 'A', planJson: '{}', planId: 'p'));
      await r.connect(SessionPayload.tryParse(r.sender.qrData)!);
      await until(() => r.sOf<SenderPeer>() != null);
      r.sender.approve();
      await until(() => r.rOf<ReceiverManifest>() != null);
      r.receiver!.choose(null);
      await until(() => r.sOf<SenderFailed>() != null);
      expect(r.plans, isEmpty);
    });
  });

  group('manifest als onbetrouwbare invoer', () {
    Map<String, dynamic> base() => {
          'schema': 1,
          'sender': 'Anna',
          'planId': 'p1',
          'planVersion': 1,
          'planBytes': 10,
          'planHash': 'a' * 64,
          'planSections': ['contacts'],
          'docs': [
            {'id': 'd1', 'title': 'Paspoort', 'type': 'passport', 'owner': '', 'sizes': [100], 'hashes': ['b' * 64]},
          ],
        };

    ShareError? err(Map<String, dynamic> j) {
      try {
        Manifest.parse(j);
        return null;
      } on ShareException catch (e) {
        return e.code;
      }
    }

    test('geldig manifest wordt gelezen', () => expect(err(base()), isNull));

    test('nieuwere schemaversie wordt netjes geweigerd', () {
      expect(err(base()..['schema'] = 2), ShareError.unsupported);
      expect(err(base()..['schema'] = 0), ShareError.badMessage);
    });

    test('te veel documenten, te veel pagina\'s, te grote pagina en te grote totalen', () {
      final many = base()..['docs'] = [for (var i = 0; i < 51; i++) {'id': 'd$i', 'title': 't', 'type': 'x', 'sizes': [1], 'hashes': ['b' * 64]}];
      expect(err(many), ShareError.tooLarge);
      final pages = base();
      (pages['docs'] as List)[0] = {'id': 'd', 'title': 't', 'type': 'x', 'sizes': List.filled(31, 1), 'hashes': List.filled(31, 'b' * 64)};
      expect(err(pages), ShareError.tooLarge);
      final big = base();
      (big['docs'] as List)[0]['sizes'] = [ShareLimits.maxPageBytes + 1];
      expect(err(big), ShareError.tooLarge);
      final total = base()..['docs'] = [for (var i = 0; i < 8; i++) {'id': 'd$i', 'title': 't', 'type': 'x', 'sizes': [ShareLimits.maxPageBytes], 'hashes': ['b' * 64]}];
      expect(err(total), ShareError.tooLarge);
      expect(err(base()..['planBytes'] = ShareLimits.maxPlanBytes + 1), ShareError.tooLarge);
    });

    test('ongeldige id\'s, hashes en te lange tekst worden geweigerd', () {
      final badId = base();
      (badId['docs'] as List)[0]['id'] = '../etc/passwd';
      expect(err(badId), ShareError.badMessage);
      final badHash = base();
      (badHash['docs'] as List)[0]['hashes'] = ['zz'];
      expect(err(badHash), ShareError.badMessage);
      final longTitle = base();
      (longTitle['docs'] as List)[0]['title'] = 'x' * 201;
      expect(err(longTitle), ShareError.tooLarge);
      final dup = base();
      (dup['docs'] as List).add({'id': 'd1', 'title': 't', 'type': 'x', 'sizes': [1], 'hashes': ['b' * 64]});
      expect(err(dup), ShareError.badMessage);
    });

    test('stuurtekens worden uit tekst gehaald', () {
      final j = base();
      (j['docs'] as List)[0]['title'] = 'Pas\u0000poort\n';
      expect(Manifest.parse(j).docs.single.title, 'Pas poort');
    });
  });

  test('de limieten zijn vastgelegd', () {
    expect(ShareLimits.maxDocuments, 50);
    expect(ShareLimits.maxPageBytes, 25 * 1024 * 1024);
    expect(ShareLimits.maxTotalBytes, 150 * 1024 * 1024);
    expect(ShareLimits.connectWindow, const Duration(minutes: 2));
    expect(ShareLimits.maxFrameBytes, 64 * 1024);
  });
}
