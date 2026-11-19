import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/pro/paywall_config.dart';

Item _i(String id, String name, {DateTime? expiry, bool hidden = false}) => Item(
      id: id,
      isCustom: false,
      hidden: hidden,
      name: name,
      category: Cat.other,
      why: '',
      unit: 'stuks',
      recommended: 1,
      inHouse: true,
      expiryDate: expiry,
    );

String _d(DateTime d) => '${d.day}-${d.month}-${d.year}';

void main() {
  final now = DateTime(2026, 11, 19, 10);

  group('PaywallConfig', () {
    test('elke context heeft rijen, en elke rijsoort wordt ergens gebruikt', () {
      for (final c in PaywallContext.values) {
        expect(defaultPaywallConfig.rowsFor(c), isNotEmpty, reason: '$c');
      }
      final used = {for (final c in PaywallContext.values) ...defaultPaywallConfig.rowsFor(c)};
      expect(used, PaywallRowKind.values.toSet());
    });

    test('de volgorde en zichtbaarheid komen uit de config', () {
      const cfg = PaywallConfig(rows: {
        PaywallContext.vault: [PaywallRowKind.vaultUnlimited, PaywallRowKind.vaultUsage],
      }, showFreeBlock: false, showSupportLine: false);
      final c = buildPaywallContent(PaywallContext.vault, const PaywallData(vaultCount: 3), cfg);
      expect([for (final r in c.rows) r.kind], [PaywallRowKind.vaultUnlimited, PaywallRowKind.vaultUsage]);
      expect(c.showFreeBlock, isFalse);
      expect(c.showSupportLine, isFalse);
    });
  });

  group('buildPaywallContent', () {
    test('rijen zonder echte data vallen weg in plaats van een verzonnen waarde te tonen', () {
      final c = buildPaywallContent(PaywallContext.hacks, const PaywallData(), defaultPaywallConfig);
      expect([for (final r in c.rows) r.kind], [PaywallRowKind.hackSearch, PaywallRowKind.hackSafetyFree]);
    });

    test('hackcategorie toont maximaal drie echte titels', () {
      final c = buildPaywallContent(
        PaywallContext.hacks,
        const PaywallData(hackCount: 10, hackCategoryTitle: 'Water', hackCategoryTitles: ['a', 'b', 'c', 'd']),
        defaultPaywallConfig,
      );
      final row = c.rows.firstWhere((r) => r.kind == PaywallRowKind.hackCategory);
      expect(row.details, ['a', 'b', 'c']);
      expect(c.rows.first.text, S.paywallHackCount(10));
    });

    test('proefhacks in het gratis-blok volgen het aantal uit de data', () {
      String myths(int? n) => buildPaywallContent(PaywallContext.general, PaywallData(trialHackCount: n), defaultPaywallConfig).freeItems.last;
      expect(myths(2), S.paywallFreeMyths('twee'));
      expect(myths(3), S.paywallFreeMyths('drie'));
      expect(myths(null), S.paywallFreeMyths(null));
      expect(myths(0), S.paywallFreeMyths(null));
    });

    test('herinneringsvoorbeeld: echt item met datum en aantal dagen; neutraal als het item ontbreekt', () {
      final due = DateTime(2026, 12, 1);
      final c = buildPaywallContent(
        PaywallContext.reminders,
        PaywallData(reminderItemName: 'Waterflessen', reminderDue: due, leadDays: 1),
        defaultPaywallConfig,
        formatDate: _d,
      );
      expect(c.rows.first.text, S.paywallRemindExpiry('Waterflessen', '1-12-2026', '1 dag van tevoren'));
      final none = buildPaywallContent(PaywallContext.reminders, const PaywallData(), defaultPaywallConfig);
      expect(none.rows.first.text, S.paywallRemindNeutral);
      final blank = buildPaywallContent(
          PaywallContext.reminders, PaywallData(reminderItemName: '  ', reminderDue: due), defaultPaywallConfig);
      expect(blank.rows.first.text, S.paywallRemindNeutral);
    });

    test('dagen vooraf: nul, een en meer', () {
      expect(S.paywallRemindLead(0), 'op de dag zelf');
      expect(S.paywallRemindLead(1), '1 dag van tevoren');
      expect(S.paywallRemindLead(14), '14 dagen van tevoren');
    });
  });

  group('pickReminderExample', () {
    test('het item waarvoor je de herinnering zet gaat voor', () {
      final items = [_i('a', 'A', expiry: DateTime(2026, 11, 25)), _i('b', 'B', expiry: DateTime(2027, 1, 1))];
      expect(pickReminderExample(items, 'b', now)?.id, 'b');
    });

    test('anders het eerstvolgende item met datum, niet verborgen en niet verlopen', () {
      final items = [
        _i('oud', 'Oud', expiry: DateTime(2020, 1, 1)),
        _i('weg', 'Verborgen', expiry: DateTime(2026, 11, 20), hidden: true),
        _i('later', 'Later', expiry: DateTime(2027, 5, 1)),
        _i('eerst', 'Eerst', expiry: DateTime(2026, 12, 1)),
        _i('geen', 'Zonder datum'),
      ];
      expect(pickReminderExample(items, null, now)?.id, 'eerst');
      expect(pickReminderExample(items, 'geen', now)?.id, 'eerst'); // item zonder datum telt niet
    });

    test('vandaag telt nog mee; zonder echte items geen voorbeeld', () {
      expect(pickReminderExample([_i('v', 'V', expiry: DateTime(2026, 11, 19))], null, now)?.id, 'v');
      expect(pickReminderExample(const [], null, now), isNull);
      expect(pickReminderExample([_i('oud', 'Oud', expiry: DateTime(2020, 1, 1))], null, now), isNull);
    });
  });
}
