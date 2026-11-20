import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../domain/expiry.dart';
import '../../domain/models.dart';
import '../noodhacks/hacks_models.dart';

/// Waar de paywall wordt geopend. Zelfde sheet, andere inhoud.
enum PaywallContext { general, hacks, reminders, vault }

/// Wat de gebruiker deed om de paywall te openen. Alleen een bewuste actie opent hem.
class PaywallRequest {
  const PaywallRequest.general()
      : context = PaywallContext.general,
        hackId = null,
        itemId = null,
        vaultCount = null;
  const PaywallRequest.hack(String this.hackId)
      : context = PaywallContext.hacks,
        itemId = null,
        vaultCount = null;
  const PaywallRequest.reminders({this.itemId})
      : context = PaywallContext.reminders,
        hackId = null,
        vaultCount = null;
  const PaywallRequest.vault({required int this.vaultCount})
      : context = PaywallContext.vault,
        hackId = null,
        itemId = null;

  final PaywallContext context;

  /// De aangetikte Pro-hack ([PaywallContext.hacks]).
  final String? hackId;

  /// Het item waarvoor de herinnering aan wordt gezet ([PaywallContext.reminders]); null = geen specifiek item.
  final String? itemId;

  /// Aantal documenten in de kluis ([PaywallContext.vault]).
  final int? vaultCount;
}

/// Een rij die in de sheet kan staan. De volgorde per context staat in [PaywallConfig].
enum PaywallRowKind {
  generalHacks,
  generalReminders,
  generalVault,
  hackCount,
  hackSearch,
  hackCategory,
  hackSafetyFree,
  reminderExample,
  reminderChoice,
  reminderOnDevice,
  vaultUsage,
  vaultKeep,
  vaultUnlimited,
}

/// Eén ding per release wijzigen en vergelijken via de winkelstatistieken (zie docs/PAYWALL_EXPERIMENTS.md):
/// welke rijen, in welke volgorde, en welke blokken zichtbaar zijn. De teksten zelf staan in `S`.
class PaywallConfig {
  const PaywallConfig({
    required this.rows,
    this.showFreeBlock = true,
    this.showSupportLine = true,
    this.familySharing = false,
  });

  final Map<PaywallContext, List<PaywallRowKind>> rows;

  /// Blok "Dit blijft altijd gratis".
  final bool showFreeBlock;

  /// Eén zin dat Pro de ontwikkeling betaalt.
  final bool showSupportLine;

  /// Alleen aan als Family Sharing voor het product is ingeschakeld in App Store Connect.
  final bool familySharing;

  List<PaywallRowKind> rowsFor(PaywallContext c) => rows[c] ?? const [];
}

/// Huidige opzet (release 2.1). Wijzig per release één onderdeel en noteer het in docs/PAYWALL_EXPERIMENTS.md.
const defaultPaywallConfig = PaywallConfig(
  rows: {
    PaywallContext.general: [
      PaywallRowKind.generalHacks,
      PaywallRowKind.generalReminders,
      PaywallRowKind.generalVault,
    ],
    PaywallContext.hacks: [
      PaywallRowKind.hackCount,
      PaywallRowKind.hackSearch,
      PaywallRowKind.hackCategory,
      PaywallRowKind.hackSafetyFree,
    ],
    PaywallContext.reminders: [
      PaywallRowKind.reminderExample,
      PaywallRowKind.reminderChoice,
      PaywallRowKind.reminderOnDevice,
    ],
    PaywallContext.vault: [
      PaywallRowKind.vaultUsage,
      PaywallRowKind.vaultKeep,
      PaywallRowKind.vaultUnlimited,
    ],
  },
);

/// Echte waarden uit de app. Alles is optioneel: ontbreekt iets, dan valt de rij weg of wordt hij neutraal.
class PaywallData {
  const PaywallData({
    this.hackCount,
    this.hackCategoryId,
    this.hackCategoryTitle,
    this.hackCategoryTitles = const [],
    this.trialHackCount,
    this.reminderItemName,
    this.reminderDue,
    this.reminderFromExpiry = true,
    this.leadDays = 30,
    this.vaultCount = 0,
  });

  /// Aantal hacks in noodhacks.json.
  final int? hackCount;

  /// Categorie van de aangetikte hack en 2 tot 3 echte titels uit die categorie.
  final String? hackCategoryId, hackCategoryTitle;
  final List<String> hackCategoryTitles;

  /// Aantal gratis proefhacks (freePreview) in noodhacks.json.
  final int? trialHackCount;

  /// Het item voor het herinneringsvoorbeeld; null = geen echt item beschikbaar.
  final String? reminderItemName;
  final DateTime? reminderDue;
  final bool reminderFromExpiry;
  final int leadDays;

  final int vaultCount;
}

class PaywallRowData {
  const PaywallRowData(this.kind, this.text, {this.details = const [], this.categoryId});
  final PaywallRowKind kind;
  final String text;

  /// Hackcategorie voor icoon en tint ([PaywallRowKind.hackCategory]).
  final String? categoryId;

  /// Echte titels onder de rij (alleen bij [PaywallRowKind.hackCategory]).
  final List<String> details;
}

class PaywallContent {
  const PaywallContent({
    required this.context,
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.freeItems,
    required this.showFreeBlock,
    required this.showSupportLine,
    required this.familySharing,
  });

  final PaywallContext context;
  final String title, subtitle;
  final List<PaywallRowData> rows;
  final List<String> freeItems;
  final bool showFreeBlock, showSupportLine, familySharing;
}

String _count(int n) => switch (n) {
      1 => 'één',
      2 => 'twee',
      3 => 'drie',
      4 => 'vier',
      5 => 'vijf',
      _ => '$n',
    };

/// Bouwt de inhoud van de sheet. Zuiver (geen I/O), dus testbaar.
PaywallContent buildPaywallContent(PaywallContext ctx, PaywallData d, PaywallConfig cfg,
    {String Function(DateTime) formatDate = fmtDate}) {
  final (title, subtitle) = switch (ctx) {
    PaywallContext.general => (S.paywallTitle, S.paywallGeneralSub),
    PaywallContext.hacks => (S.paywallHacksTitle, S.paywallHacksSub),
    PaywallContext.reminders => (S.paywallRemindTitle, S.paywallRemindSub),
    PaywallContext.vault => (S.paywallVaultTitle, S.paywallVaultSub),
  };

  PaywallRowData? row(PaywallRowKind k) => switch (k) {
        PaywallRowKind.generalHacks => PaywallRowData(k, S.paywallGeneralHacks),
        PaywallRowKind.generalReminders => PaywallRowData(k, S.paywallGeneralReminders),
        PaywallRowKind.generalVault => PaywallRowData(k, S.paywallGeneralVault),
        PaywallRowKind.hackCount => d.hackCount == null || d.hackCount! <= 0
            ? null
            : PaywallRowData(k, S.paywallHackCount(d.hackCount!)),
        PaywallRowKind.hackSearch => PaywallRowData(k, S.paywallHackSearch),
        PaywallRowKind.hackCategory => d.hackCategoryTitle == null || d.hackCategoryTitles.isEmpty
            ? null
            : PaywallRowData(k, S.paywallHackCategory(d.hackCategoryTitle!),
                details: d.hackCategoryTitles.take(3).toList(), categoryId: d.hackCategoryId),
        PaywallRowKind.hackSafetyFree => PaywallRowData(k, S.paywallHackSafetyFree),
        PaywallRowKind.reminderExample => _reminderExample(d, formatDate),
        PaywallRowKind.reminderChoice => PaywallRowData(k, S.paywallRemindChoice),
        PaywallRowKind.reminderOnDevice => PaywallRowData(k, S.paywallRemindOnDevice),
        PaywallRowKind.vaultUsage => PaywallRowData(k, S.paywallVaultUsage(d.vaultCount)),
        PaywallRowKind.vaultKeep => PaywallRowData(k, S.paywallVaultKeep),
        PaywallRowKind.vaultUnlimited => PaywallRowData(k, S.paywallVaultUnlimited),
      };

  return PaywallContent(
    context: ctx,
    title: title,
    subtitle: subtitle,
    rows: [for (final k in cfg.rowsFor(ctx)) ?row(k)],
    freeItems: [
      S.paywallFreeChecklist,
      S.paywallFreeGuides,
      S.paywallFreeFirstHour,
      S.paywallFreePlan,
      S.paywallFreeVault,
      S.paywallFreeMyths(d.trialHackCount == null || d.trialHackCount! <= 0 ? null : _count(d.trialHackCount!)),
    ],
    showFreeBlock: cfg.showFreeBlock,
    showSupportLine: cfg.showSupportLine,
    familySharing: cfg.familySharing,
  );
}

/// Voorbeeld uit de eigen lijst van de gebruiker; zonder echt item een neutrale zin zonder voorbeeld.
PaywallRowData _reminderExample(PaywallData d, String Function(DateTime) formatDate) {
  final name = d.reminderItemName, due = d.reminderDue;
  if (name == null || name.trim().isEmpty || due == null) {
    return const PaywallRowData(PaywallRowKind.reminderExample, S.paywallRemindNeutral);
  }
  final lead = S.paywallRemindLead(d.leadDays);
  return PaywallRowData(
    PaywallRowKind.reminderExample,
    d.reminderFromExpiry
        ? S.paywallRemindExpiry(name.trim(), formatDate(due), lead)
        : S.paywallRemindReplace(name.trim(), formatDate(due), lead),
  );
}

// --- Echte data -> PaywallData -----------------------------------------------------------------

/// Hacks: aantal en proefhacks uit de data, plus categorie en 2 tot 3 titels bij de aangetikte hack.
/// Titels van Pro-hacks gaan voor (dat is wat Pro toevoegt); de aangetikte hack zelf telt niet mee.
PaywallData hackPaywallData(HackData? data, String? hackId) {
  if (data == null) return const PaywallData();
  final tapped = hackId == null ? null : data.hacks.where((h) => h.id == hackId).firstOrNull;
  String? catId, catTitle;
  var titles = <String>[];
  if (tapped != null) {
    catId = tapped.categorie;
    catTitle = data.categories.where((c) => c.id == catId).firstOrNull?.titel;
    final others = data.hacks.where((h) => h.categorie == catId && h.id != tapped.id).toList();
    final ordered = [...others.where((h) => !h.isFree), ...others.where((h) => h.isFree)];
    titles = [for (final h in ordered.take(3)) h.titel];
  }
  return PaywallData(
    hackCount: data.hacks.length,
    hackCategoryId: catId,
    hackCategoryTitle: catTitle,
    hackCategoryTitles: titles,
    trialHackCount: data.hacks.where((h) => h.freePreview).length,
  );
}

/// Herinneringen: het item waarvoor de herinnering wordt gezet, anders het eerstvolgende echte item met een datum.
/// Zonder echt item blijft het voorbeeld weg.
PaywallData reminderPaywallData(List<Item>? items, String? itemId, DateTime now, int leadDays,
    {int? trialHackCount}) {
  final item = pickReminderExample(items ?? const [], itemId, now);
  return PaywallData(
    reminderItemName: item?.name,
    reminderDue: item == null ? null : dueDate(item),
    reminderFromExpiry: item?.expiryDate != null,
    leadDays: leadDays,
    trialHackCount: trialHackCount,
  );
}

Item? pickReminderExample(List<Item> items, String? itemId, DateTime now) {
  if (itemId != null) {
    final own = items.where((i) => i.id == itemId && dueDate(i) != null).firstOrNull;
    if (own != null) return own;
  }
  final today = dateOnly(now);
  final upcoming = [
    for (final i in items)
      if (!i.hidden && dueDate(i) != null && !dueDate(i)!.isBefore(today)) i,
  ]..sort((a, b) => dueDate(a)!.compareTo(dueDate(b)!));
  return upcoming.firstOrNull;
}
