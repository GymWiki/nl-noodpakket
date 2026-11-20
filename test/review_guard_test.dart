import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/data/repositories/item_repository.dart';
import 'package:mijnnoodpakket/features/review/review_config.dart';

/// Bewaakt de regels rond het beoordelingsverzoek: alleen de systeemprompt van de winkel, nooit een eigen dialoog of een
/// knop die hem aanroept, nooit vooraf een vraag, geen analytics, en nooit in de uitgesloten contexten.
List<File> dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

String norm(String p) => p.replaceAll(r'\', '/');

void main() {
  final lib = dartFiles('lib');
  final review = dartFiles('lib/features/review');

  group('de systeemprompt van de winkel, nergens anders', () {
    test('alleen review_launcher.dart kent het pakket in_app_review', () {
      final users = [for (final f in lib) if (f.readAsStringSync().contains('in_app_review')) norm(f.path)];
      expect(users, ['lib/features/review/review_launcher.dart']);
    });

    test('alleen de controller roept requestReview aan (en de launcher definieert hem)', () {
      final callers = [
        for (final f in lib)
          if (RegExp(r'\.requestReview\(').hasMatch(f.readAsStringSync())) norm(f.path),
      ];
      expect(callers..sort(), ['lib/features/review/review_controller.dart', 'lib/features/review/review_launcher.dart']);
    });

    test('alleen de host vraagt de controller om een verzoek te doen (op een rustig moment)', () {
      final callers = [
        for (final f in lib)
          if (RegExp(r'\.maybeRequest\(').hasMatch(f.readAsStringSync())) norm(f.path),
      ];
      expect(callers, ['lib/features/review/review_host.dart']);
      final host = File('lib/features/review/review_host.dart').readAsStringSync();
      expect(host, contains('ReviewContext.calm'));
      expect(host, contains('AppLifecycleState.resumed'));
    });

    test('geen knop of rij roept de systeemprompt aan: de handmatige route kent de launcher niet', () {
      for (final name in ['review_link_row.dart', 'store_review_opener.dart']) {
        final src = File('lib/features/review/$name').readAsStringSync();
        expect(src.contains(RegExp(r'review_launcher|ReviewLauncher|reviewLauncherProvider|reviewControllerProvider|requestReview')), isFalse,
            reason: name);
      }
    });

    test('er is geen eigen dialoog, blad of venster in het beoordelingsverzoek', () {
      for (final f in review) {
        final src = f.readAsStringSync();
        expect(src.contains(RegExp(r'showDialog|AlertDialog|SimpleDialog|showCupertinoDialog|showModalBottomSheet|showBottomSheet|SnackBar\(')) &&
                !f.path.endsWith('review_link_row.dart'),
            isFalse,
            reason: f.path);
      }
    });

    test('geen debug-knoppen of testhulpen in de release-code van het verzoek', () {
      for (final f in review) {
        final src = f.readAsStringSync();
        expect(src.contains(RegExp(r'kDebugMode|assert\(|debugPrint|FloatingActionButton|ElevatedButton|FilledButton')), isFalse, reason: f.path);
      }
    });
  });

  group('nooit in een uitgesloten context', () {
    test('geen verzoek, host of systeem-API in wiki, noodplan, kluis, noodhacks, deel, rampenzender, checklist of Pro', () {
      const excluded = [
        'lib/features/wiki',
        'lib/features/noodplan',
        'lib/features/kluis',
        'lib/features/noodhacks',
        'lib/features/deel',
        'lib/features/rampenzender',
        'lib/features/checklist',
        'lib/features/pro',
        'lib/features/onboarding',
      ];
      for (final d in excluded) {
        for (final f in dartFiles(d)) {
          final src = f.readAsStringSync();
          expect(src.contains(RegExp(r'maybeRequest|requestReview|ReviewHost|InAppReview|in_app_review|reviewLauncherProvider|StoreReviewOpener')), isFalse,
              reason: f.path);
        }
      }
    });

    test('de deelschermen melden alleen een succesmoment (successOccurred), en alleen die twee bestanden', () {
      final callers = [
        for (final f in lib)
          if (f.readAsStringSync().contains('.successOccurred(') && !norm(f.path).startsWith('lib/features/review/')) norm(f.path),
      ];
      expect(callers..sort(), ['lib/features/deel/ui/share_qr_screen.dart', 'lib/features/noodplan/ui/plan_share_screen.dart']);
    });

    test('het beoordelingsverzoek raakt de Pro-regels en de paywall niet aan', () {
      for (final f in review) {
        expect(f.readAsStringSync().contains(RegExp(r'features/pro/|ProFeature|showPaywall|requirePro|proUnlockedProvider|PaywallRequest')), isFalse,
            reason: f.path);
      }
    });

    test('alleen een rustig dashboard mag: de host vraagt nergens zonder de contextcontrole', () {
      final host = File('lib/features/review/review_host.dart').readAsStringSync();
      expect(RegExp(r'_context\(\)\s*!=\s*ReviewContext\.calm').allMatches(host).length, greaterThanOrEqualTo(1));
      expect(host, contains('ctx != ReviewContext.calm'));
    });
  });

  group('teksten: geen vragen vooraf, geen beloning', () {
    final texts = [S.reviewRowTitle, S.reviewRowSub, S.reviewOffline, S.reviewOpenError];

    test('de enige tekst is de rustige regel; geen vraagteken, uitroepteken of hoofdletternadruk', () {
      for (final t in texts) {
        expect(t.contains('?'), isFalse, reason: t);
        expect(t.contains('!'), isFalse, reason: t);
        expect(RegExp(r'\b[A-ZÀ-Ý]{3,}\b').hasMatch(t), isFalse, reason: t);
      }
    });

    test('geen tevredenheidsvraag, geen filter op gevoel, geen beloning of druk', () {
      const banned = [
        'vind je', 'leuk', 'tevreden', 'bevalt', 'ervaring', 'sterren', 'vijf', 'cijfer', 'positief', 'goede beoordeling',
        'beloning', 'gratis', 'korting', 'cadeau', 'winnen', 'in ruil', 'als je', 'geef ons', 'steun ons', 'help ons',
      ];
      for (final t in texts) {
        for (final b in banned) {
          expect(t.toLowerCase().contains(b), isFalse, reason: '"$t" bevat "$b"');
        }
      }
    });

    test('de enige zin bij de rij is "Je beoordeling helpt andere mensen de app te vinden."', () {
      expect(S.reviewRowSub, 'Je beoordeling helpt andere mensen de app te vinden.');
      expect(S.reviewRowTitle, 'Beoordeel NL-Noodpakket');
    });
  });

  group('privacy: alleen lokaal, geen analytics', () {
    test('het beoordelingsverzoek doet geen eigen netwerkaanroepen (behalve de DNS-controle van de winkelnaam)', () {
      for (final f in review) {
        final src = f.readAsStringSync();
        expect(src.contains(RegExp(r'package:http|package:dio|HttpClient|Socket\.connect|WebSocket|Uri\.https|analytics|Analytics|firebase|Firebase')),
            isFalse,
            reason: f.path);
        if (src.contains('InternetAddress.lookup')) expect(norm(f.path), 'lib/features/review/store_review_opener.dart');
      }
    });

    test('de geschiedenis staat alleen in de lokale instellingentabel, onder één sleutel', () {
      final users = [
        for (final f in lib)
          if (f.readAsStringSync().contains('reviewHistoryKey')) norm(f.path),
      ];
      expect(users..sort(), ['lib/features/review/review_config.dart', 'lib/features/review/review_store.dart']);
    });

    test('de beoordelingsgeschiedenis is apparaatgebonden: niet in een back-up of export, en een import wist haar niet', () {
      // De JSON-back-up schrijft alle instellingenrijen weg; deze sleutel moet daar uitgesloten zijn.
      expect(deviceLocalSettingKeys, contains(reviewHistoryKey));
      final repo = File('lib/data/repositories/item_repository.dart').readAsStringSync();
      expect(repo, contains('deviceLocalSettingKeys.contains(s.key)'));
      expect(repo, contains('deviceLocalSettingKeys.contains(k)'));
    });
  });

  test('de pakketkeuze: in_app_review staat als gewone dependency, vastgezet in de lockfile', () {
    expect(File('pubspec.yaml').readAsStringSync(), contains('in_app_review:'));
    expect(File('pubspec.lock').readAsStringSync(), contains('name: in_app_review'));
  });
}
