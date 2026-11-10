/// Alle UI-teksten (nl-NL). Voor een andere taal: maak een tweede klasse met
/// dezelfde leden of migreer naar ARB/gen-l10n; widgets bevatten geen eigen tekst.
class S {
  S._();

  static const appName = 'NL-Noodpakket';
  static const disclaimer =
      'Deze app vertegenwoordigt de Nederlandse overheid niet en is niet door '
      'officiële instanties gemaakt.';

  // Navigatie
  static const navChecklist = 'Checklist';
  static const navReplace = 'Vervangen';
  static const navInfo = 'Info';
  static const navSettings = 'Instellingen';

  // Algemeen
  static const save = 'Opslaan';
  static const cancel = 'Annuleren';
  static const delete = 'Verwijderen';
  static const next = 'Volgende';
  static const back = 'Terug';
  static const start = 'Aan de slag';
  static const retry = 'Opnieuw proberen';
  static const loading = 'Laden…';
  static const errorGeneric = 'Er ging iets mis. Probeer het opnieuw.';
  static const confirm = 'Bevestigen';
  static const none = 'Geen';

  // Noodgevallen-wiki
  static const navWiki = 'Noodgevallen';
  static const wikiTitle = 'Noodgevallen';
  static const wikiRule =
      'Bij levensgevaar bel je 112. Deze informatie vervangt geen professionele hulp.';
  static const wikiCall112 = 'Bel 112';
  static const wikiCall112Hint = 'Opent alleen de telefoon-app. Er wordt niet automatisch gebeld.';
  static const wikiSearchHint = 'Zoek: stroom, water, brand…';
  static const wikiFirstHourCta = 'Open de kaart';
  static const wikiFavorites = 'Favorieten';
  static const wikiAddFavorite = 'Voeg toe aan favorieten';
  static const wikiRemoveFavorite = 'Verwijder uit favorieten';
  static const wikiNoResults = 'Geen noodgeval gevonden. Probeer een ander woord.';
  static const wikiLoadError = 'De noodgevallen konden niet worden geladen.';
  static const wikiNotFound = 'Dit noodgeval bestaat niet.';
  static const wikiStartSteps = 'Start stappenplan';
  static const wikiResumeSteps = 'Ga verder met stappenplan';
  static const wikiNow = 'Nu doen';
  static const wikiAfter = 'Daarna';
  static const wikiCall112If = 'Bel 112 als…';
  static const wikiPrepare = 'Voorbereiden';
  static const wikiPrepareHave = 'In huis';
  static const wikiPrepareNeed = 'Nog nodig';
  static const wikiNumbers = 'Nuttige nummers';
  static const wikiSources = 'Bronnen';
  static String wikiReviewed(String date) => 'Laatst gecontroleerd: $date';
  static String wikiCallNumber(String label, String nr) => 'Bel $label: $nr';
  static const wikiStepsTitle = 'Stappenplan';
  static String wikiStepOf(int i, int n) => 'Stap $i van $n';
  static const wikiPrev = 'Vorige';
  static const wikiNext = 'Volgende';
  static const wikiFinish = 'Klaar';
  static const wikiDone = 'Gedaan';
  static const wikiViewList = 'Toon als lijst';
  static const wikiViewSteps = 'Toon één stap per scherm';
  static const wikiRestart = 'Opnieuw beginnen';
  static const wikiAllDone = 'Je hebt alle stappen doorlopen.';
  static const wikiHandy = 'Handig bij';
  static const wikiOpenLinkError = 'Kon de link niet openen.';
  static const wikiCallError = 'Kon de telefoon-app niet openen.';
  static const wikiPdfCard = 'Meterkastkaart (PDF)';
  static const wikiPdfCardSub = 'Deel of print de Eerste-uur kaart en 5 stappenplannen.';
  static const wikiPdfError = 'De kaart maken is niet gelukt.';
  static const wikiPdfTitle = 'Meterkastkaart: wat te doen bij een noodsituatie';

  // Categorieën
  static const catWater = 'Water en voeding';
  static const catInfo = 'Informatie en communicatie';
  static const catLight = 'Licht en warmte';
  static const catHealth = 'Gezondheid en hygiëne';
  static const catDocs = 'Documenten en geld';
  static const catOther = 'Overig';
  static const catCustom = 'Nieuwe categorie…';
  static const catCustomName = 'Naam van de categorie';

  // Onboarding
  static const obTitle1 = 'Stap voor stap een noodpakket';
  static const obBody1 =
      'Met deze app stel je rustig een noodpakket samen voor thuis en houd je '
      'bij wat er in huis is en wanneer iets vervangen moet worden. '
      'Gebaseerd op de campagne Denk Vooruit (denkvooruit.nl).';
  static const obTitle2 = 'Jouw huishouden';
  static const obBody2 =
      'Hiermee rekenen we uit hoeveel je nodig hebt. Je kunt dit later altijd '
      'aanpassen in Instellingen.';
  static const obTitle3 = 'Alles blijft op je toestel';
  static const obBody3 =
      'Geen account, geen tracking, geen internet nodig. Je gegevens verlaten '
      'je toestel niet. Herinneringen worden lokaal op je telefoon gepland.';

  // Huishouden
  static const hhAdults = 'Volwassenen';
  static const hhChildren = 'Kinderen';
  static const hhBabies = "Baby's";
  static const hhSeniors = 'Ouderen';
  static const hhPets = 'Huisdieren';
  static const hhMedication = 'Gebruik je medicijnen?';
  static const hhMedicationSub = 'Dan tonen we ook medicatie-items.';
  static String hhCount(String label, int n) => '$label: $n';
  static String hhMore(String label) => '$label: meer';
  static String hhLess(String label) => '$label: minder';

  // Checklist
  static const checklistTitle = 'Mijn noodpakket';
  static const searchHint = 'Zoek in je lijst';
  static const filterAll = 'Alles';
  static const filterNeeded = 'Nog nodig';
  static const filterInHouse = 'In huis';
  static const filterExpiring = 'Bijna verlopen';
  static const addItem = 'Eigen item';
  static String progressTotal(int done, int total) =>
      '$done van $total spullen in huis';
  static String progressCategory(int done, int total) => '$done/$total';
  static const emptyFilter = 'Niets gevonden bij dit filter.';
  static const emptyList = 'Je lijst is nog leeg.';
  static const markInHouse = 'In huis';
  static const markNeeded = 'Nog nodig';
  static String itemSemantics(String name, bool inHouse, String qty) =>
      '$name, $qty, ${inHouse ? 'in huis' : 'nog nodig'}';
  static String quantityLine(String qty, String unit) => '$qty $unit';
  static const itemRestored = 'Item hersteld';
  static const itemHidden = 'Item verborgen';
  static const undo = 'Ongedaan maken';

  // Itemformulier
  static const itemDetail = 'Item';
  static const itemNew = 'Nieuw item';
  static const itemEdit = 'Item bewerken';
  static const fieldName = 'Naam';
  static const fieldCategory = 'Categorie';
  static const fieldUnit = 'Eenheid (bijv. stuks, liter)';
  static const fieldWhy = 'Waarom is dit belangrijk?';
  static const fieldWhyHint = 'Optioneel: eigen uitleg';
  static const fieldNotes = 'Notities';
  static const fieldInHouse = 'In huis';
  static const fieldRecommended = 'Aanbevolen hoeveelheid';
  static String recommendedValue(String qty, String unit) => '$qty $unit';
  static const fieldRecommendedAuto = 'Automatisch berekend voor jouw huishouden';
  static const fieldOverride = 'Eigen doelhoeveelheid (optioneel)';
  static const fieldHave = 'Aanwezig';
  static const fieldExpiry = 'Houdbaar tot';
  static const fieldExpiryNone = 'Geen datum';
  static const fieldInterval = 'Controleer elke';
  static const intervalNone = 'Niet herhalen';
  static String intervalMonths(int m) => switch (m) {
        1 => '1 maand',
        12 => '1 jaar',
        24 => '2 jaar',
        _ => '$m maanden',
      };
  static const pickDate = 'Kies datum';
  static const clearDate = 'Datum wissen';
  static const whyTitle = 'Waarom is dit belangrijk?';
  static const shelfAdviceTitle = 'Houdbaarheidsadvies';
  static const useAdvice = 'Gebruik dit advies';
  static const markChecked = 'Nu gecontroleerd';
  static String lastChecked(String date) => 'Laatst gecontroleerd: $date';
  static const hideItem = 'Verberg dit item';
  static const deleteItem = 'Verwijder dit item';
  static const deleteItemTitle = 'Item verwijderen?';
  static const deleteItemBody = 'Dit eigen item wordt definitief verwijderd.';
  static const requiredField = 'Vul een naam in';
  static const invalidNumber = 'Vul een geldig getal in';
  static const itemNotFound = 'Dit item bestaat niet meer.';

  // Vervangen
  static const replaceTitle = 'Binnenkort vervangen';
  static const replaceEmpty =
      'Nog niets om te vervangen. Voeg bij een item een houdbaarheidsdatum of '
      'controle-interval toe, dan verschijnt het hier.';
  static const expired = 'Verlopen';
  static const dueToday = 'Vandaag';
  static String dueIn(int days) => days == 1 ? 'Morgen' : 'Over $days dagen';
  static String expiredAgo(int days) =>
      days == 1 ? '1 dag verlopen' : '$days dagen verlopen';
  static const sectionExpired = 'Verlopen';
  static const sectionSoon = 'Binnenkort';
  static const sectionLater = 'Later';

  // Info
  static const infoTitle = 'Informatie';
  static const infoWhyTitle = 'Waarom een noodpakket?';
  static const infoWhyBody =
      'Bij een langdurige stroomstoring, overstroming of andere noodsituatie '
      'kun je een tijd op jezelf zijn aangewezen. Het advies is om de eerste '
      'drie dagen (72 uur) zelf te kunnen overbruggen. Een goed voorbereid '
      'huishouden is rustiger en kan anderen helpen.';
  static const infoTipsTitle = 'Tips';
  static const infoTips = [
    'Bewaar je noodpakket op een goed bereikbare plek, bijvoorbeeld in een '
        'waterdichte rugzak of tas.',
    'Roteer je voorraad: gebruik wat bijna verloopt en vul het aan.',
    'Controleer je noodpakket elk half jaar op houdbaarheid en volledigheid.',
    'Bouw rustig op. Je hoeft niet alles in één keer te hebben.',
    'Bespreek met je huisgenoten waar alles ligt.',
  ];
  static const infoLinkTitle = 'Officiële informatie';
  static const infoLinkBody =
      'Voor actuele adviezen en uitleg kijk je op denkvooruit.nl.';
  static const infoLinkButton = 'Open denkvooruit.nl';
  static const infoLinkError = 'Kon de website niet openen.';
  static const infoPrivacyTitle = 'Jouw privacy';
  static const infoPrivacyBody =
      'Alle gegevens blijven op je toestel. De app heeft geen account, geen '
      'analyse en geen tracking, en werkt volledig offline.';
  static const infoDisclaimerTitle = 'Let op';

  // Instellingen
  static const settingsTitle = 'Instellingen';
  static const setHousehold = 'Huishouden';
  static const setNotifications = 'Herinneringen';
  static const setLeadTime = 'Herinner mij vooraf';
  static String leadDays(int d) => switch (d) {
        7 => '1 week',
        14 => '2 weken',
        30 => '30 dagen',
        60 => '2 maanden',
        _ => '$d dagen',
      };
  static const setSemiAnnual = 'Halfjaarlijkse controle';
  static const setSemiAnnualSub = 'Een herinnering: check je noodpakket.';
  static const notifDenied =
      'Meldingen staan uit voor deze app. Zet ze aan in de systeeminstellingen '
      'om herinneringen te ontvangen.';
  static const setTheme = 'Thema';
  static const themeSystem = 'Systeem';
  static const themeLight = 'Licht';
  static const themeDark = 'Donker';
  static const setData = 'Gegevens';
  static const exportData = 'Back-up maken (JSON)';
  static const exportSub = 'Deel of bewaar een bestand met al je gegevens.';
  static const importData = 'Back-up terugzetten';
  static const importSub = 'Vervangt alle huidige gegevens.';
  static const importConfirmTitle = 'Back-up terugzetten?';
  static const importConfirmBody =
      'Al je huidige gegevens worden vervangen door de back-up.';
  static const importOk = 'Back-up teruggezet';
  static const importFail = 'Dit bestand is geen geldige back-up.';
  static const exportFail = 'Back-up maken is niet gelukt.';
  static const restoreDefaults = 'Standaardlijst herstellen';
  static const restoreDefaultsSub =
      'Verborgen items terug en aanpassingen aan standaarditems wissen. '
      'Eigen items blijven bewaard.';
  static const restoreDefaultsTitle = 'Standaardlijst herstellen?';
  static const restoreDefaultsBody =
      'Aanpassingen aan standaarditems (afvinken, datums, notities) worden '
      'gewist. Je eigen items blijven staan.';
  static const restored = 'Standaardlijst hersteld';
  static const hiddenItems = 'Verborgen items';
  static const hiddenEmpty = 'Je hebt geen items verborgen.';
  static const restore = 'Herstel';
  static const resetAll = 'Alles resetten';
  static const resetAllSub = 'Wist alle gegevens en begint opnieuw.';
  static const resetAllTitle = 'Alles resetten?';
  static const resetAllBody =
      'Alle items, eigen items en instellingen worden definitief gewist. '
      'Dit kan niet ongedaan worden gemaakt.';
  static const about = 'Over deze app';
  static String version(String v) => 'Versie $v';

  // Notificaties
  static const notifChannelName = 'Herinneringen noodpakket';
  static const notifChannelDesc = 'Herinneringen over vervangen en controleren';
  static const notifTitleReplace = 'Binnenkort vervangen';
  static String notifBodyReplace(String name, String date) =>
      '$name is houdbaar tot $date.';
  static String notifBodyCheck(String name) => 'Tijd om $name te controleren.';
  static const notifTitleHalfYear = 'Check je noodpakket';
  static const notifBodyHalfYear =
      'Het is een half jaar geleden. Loop je noodpakket even na.';
}
