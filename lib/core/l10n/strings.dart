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

  // Mijn noodplan
  static const planTitle = 'Mijn noodplan';
  static String planCardSub(int done, int total) => '$done van $total onderdelen ingevuld';
  static const planCardStart = 'Maak in ongeveer 10 minuten je noodplan.';
  static const planBannerText = 'Maak je noodplan: wie, waar en hoe bereik je elkaar?';
  static const planBannerCta = 'Begin';
  static const planBannerDismiss = 'Niet nu';
  static const planOverviewIntro =
      'Een noodplan zijn afspraken met je huishouden: hoe bereik je elkaar, waar '
      'ontmoet je elkaar en wie heeft extra hulp nodig? Alles blijft op dit '
      'toestel tot je zelf deelt.';
  static const planSecHousehold = 'Huishouden';
  static const planSecContacts = 'Contacten';
  static const planSecPlaces = 'Verzamelplekken';
  static const planSecAgreements = 'Afspraken';
  static const planSecHome = 'Thuis';
  static const planSecCare = 'Zorg en bijzonderheden';
  static const planSecNeighbours = 'Buren en hulp';
  static const planStatusEmpty = 'Nog leeg';
  static const planStatusPartial = 'Gedeeltelijk';
  static const planStatusDone = 'Klaar';
  static const planStatusSkipped = 'Overgeslagen';
  static const planStartPlan = 'Begin met je plan';
  static const planContinue = 'Ga verder met je plan';
  static const planTalk = 'Bespreek met je huishouden';
  static const planShare = 'Deel mijn noodplan';
  static const planImport = 'Noodplan importeren';
  static const planConfirm = 'Alles klopt nog';
  static String planConfirmed(String d) => 'Laatst gecontroleerd: $d';
  static String planUpdated(String d) => 'Laatst gewijzigd: $d';
  static String planLastShared(String d) => 'Laatst gedeeld: $d';
  static const planChangedSinceShare =
      'Je plan is gewijzigd sinds je het deelde. Opnieuw delen?';
  static const planReshare = 'Opnieuw delen';
  static const planPrivacy = 'Alle gegevens staan alleen op dit toestel.';
  static const planReminder = 'Herinnering: klopt je noodplan nog?';
  static const planReminderSub = 'Elke 6 maanden een herinnering.';
  static const planOpenSection = 'Open';
  static const planLoadError = 'Je noodplan kon niet worden geladen.';

  // Wizard
  static const planWizardTitle = 'Noodplan maken';
  static String planStepOf(int i, int n) => 'Onderdeel $i van $n';
  static const planSkip = 'Sla over';
  static const planLater = 'Later afmaken';
  static const planPrev = 'Vorige';
  static const planNextStep = 'Volgende';
  static const planFinish = 'Afronden';
  static const planAutoSaved = 'Alles wordt automatisch opgeslagen.';
  static const planWhy = 'Waarom is dit belangrijk?';
  static const planAdd = 'Toevoegen';
  static const planEdit = 'Bewerken';
  static const planRemove = 'Verwijderen';
  static const planSaveDialog = 'Opslaan';
  static const planSuggestions = 'Voorstellen (tik om te gebruiken)';

  // Stap 1: huishouden
  static const planHhWhy =
      'Wie hoort er bij je huishouden en wie heeft extra hulp nodig? Zo kun je '
      'samen afspraken maken die voor iedereen werken.';
  static const planHhPrefilled =
      'We hebben je huishouden alvast ingevuld op basis van je instellingen. '
      'Pas gerust aan.';
  static const planHhName = 'Naam van je huishouden';
  static const planHhNameHint = 'Bijvoorbeeld: Familie De Vries';
  static const planAddPerson = 'Persoon toevoegen';
  static const planAddPet = 'Huisdier toevoegen';
  static const planMemberName = 'Naam';
  static const planMemberAge = 'Leeftijdscategorie';
  static const planNeedsHelp = 'Heeft hulp nodig bij vluchten of zelfredzaamheid';
  static const planMemberNotes = 'Opmerking (optioneel)';
  static const planPetLabel = 'huisdier';
  static const planNeedsHelpShort = 'extra hulp nodig';
  static const planAgeAdult = 'Volwassene';
  static const planAgeChild = 'Kind';
  static const planAgeBaby = 'Baby';
  static const planAgeSenior = 'Oudere';
  static String planDefaultName(String label, int n) => '$label $n';
  static const planDefaultPet = 'Huisdier';
  static const planNoMembers = 'Nog niemand toegevoegd.';

  // Stap 2: contacten
  static const planCtWhy =
      'Als je elkaar niet kunt bellen of ontmoeten, helpt het als iedereen weet '
      'wie je kunt waarschuwen. Denk aan familie in een andere stad: hoe blijf je '
      'in contact?';
  static const planRoleOutside = 'Contact buiten de regio';
  static const planRoleOutsideHint =
      'Een vast aanspreekpunt in een andere stad of regio. Iedereen uit je '
      'huishouden kan laten weten dat het goed gaat.';
  static const planRoleEmergency = 'Noodcontact';
  static const planRoleEmergencyHint =
      'Voeg minstens één, bij voorkeur twee noodcontacten toe.';
  static const planRoleNeighbour = 'Buurman of buurvrouw';
  static const planRoleDoctor = 'Huisarts';
  static const planRoleSchool = 'School, opvang of werk';
  static const planRoleVet = 'Dierenarts';
  static const planContactName = 'Naam';
  static const planContactRelation = 'Relatie (bijv. zus of buurman)';
  static const planContactPhone = 'Telefoonnummer';
  static const planPickContact = 'Kies uit contacten';
  static const planContactsDenied =
      'Geen toegang tot je contacten. Je kunt het nummer ook zelf invullen.';
  static const planContactNone = 'Nog geen contact toegevoegd.';
  static const planContactNumberOrName = 'Vul een naam of nummer in';
  static String planCallContact(String name) => 'Bel $name';

  // Stap 3: verzamelplekken
  static const planPlWhy =
      'Partner niet bereikbaar? Spreek van tevoren af waar jullie elkaar ontmoeten, '
      'voor drie situaties.';
  static const planPlaceHome = 'Buiten bij de woning (bij brand)';
  static const planPlaceNeighbourhood = 'In de buurt (als je wijk niet bereikbaar is)';
  static const planPlaceOutside = 'Buiten de regio (bij evacuatie)';
  static const planPlAddress = 'Adres of plek';
  static const planPlAddressHint = 'Bijvoorbeeld: bij de lantaarnpaal voor de deur';
  static const planPlNotes = 'Notitie (optioneel)';
  static const planOpenMap = 'Open in kaartenapp';
  static const planMapError = 'Kon de kaartenapp niet openen.';

  // Stap 4: afspraken
  static const planAgrWhy =
      'Wat doe je als niemand bereikbaar is? Een afspraak vooraf voorkomt discussie. '
      'Niemand hoeft alles zelf te doen: de één haalt de kinderen op, een ander gaat '
      'langs de buren.';
  static const planAgrCheckin = 'Vast check-in moment';
  static const planAgrKids = 'Wie haalt de kinderen op?';
  static const planAgrPets = 'Wie zorgt voor de huisdieren?';
  static const planAgrVulnerable =
      'Wie helpt familie of buren die extra hulp nodig hebben?';
  static const planAgrNoteLeft = 'Waar laat je een briefje achter?';
  static const planAgrInfoSource = 'Geen internet: waar vind je betrouwbare informatie?';
  static const planAgrOther = 'Overige afspraken';
  static const planAgrHint = 'Typ hier jullie afspraak';
  static const planSugCheckin = [
    'Elk heel uur een korte sms',
    'Elke ochtend en avond één bericht',
  ];
  static const planSugKids = [
    'De ouder die het dichtstbij is haalt ze op',
    'Een vaste buur of opa of oma haalt ze op',
  ];
  static const planSugPets = [
    'Wie thuis is zorgt voor de huisdieren',
    'We nemen de huisdieren mee',
  ];
  static const planSugVulnerable = ['We bellen elke dag', 'Een vast iemand gaat langs'];
  static const planSugNoteLeft = ['Op de keukentafel', 'Op de voordeur'];
  static const planSugInfoSource = [
    'Radio op batterijen: de regionale omroep',
    'Via de buren',
  ];

  // Stap 5: thuis
  static const planHomeWhy =
      'In het donker of bij stress weet je niet meer waar alles zit. Schrijf het '
      'op, zodat iedereen in huis het kan vinden. Past iets niet bij jouw woning? '
      'Typ "n.v.t.".';
  static const planLocNoodpakket = 'Noodpakket';
  static const planLocFirstAid = 'EHBO-set';
  static const planLocRadio = 'Radio op batterijen';
  static const planLocFlashlight = 'Zaklamp';
  static const planLocMeterkast = 'Meterkast';
  static const planLocWater = 'Hoofdkraan water';
  static const planLocGas = 'Gaskraan';
  static const planLocPower = 'Hoofdschakelaar stroom';
  static const planLocSmoke = 'Rookmelders';
  static const planLocEscape = 'Twee vluchtroutes per verdieping';
  static const planLocShelter = 'Schuilplek (bijv. hoogste verdieping)';
  static const planLocHint = 'Bijvoorbeeld: in de gangkast';
  static const planPhotoAdd = 'Foto toevoegen';
  static const planPhotoCamera = 'Foto maken';
  static const planPhotoGallery = 'Kies uit galerij';
  static const planPhotoRemove = 'Foto verwijderen';
  static const planPhotoError = 'De foto kon niet worden opgeslagen.';
  static const planPhotoLocal = "Foto's blijven op dit toestel tot je zelf deelt.";
  static const planToChecklist = 'Bekijk je noodpakket in de checklist';
  static String planNoodpakketAt(String where) => 'Je noodpakket ligt: $where';

  // Stap 6: zorg
  static const planCareWhy =
      'Optioneel. Zo weten anderen wat je nodig hebt als jij het niet kunt zeggen. '
      'Dit onderdeel wordt standaard niet gedeeld.';
  static const planCareMedication = 'Wie neemt welke medicatie?';
  static const planCareDevices = 'Hulpmiddelen of apparatuur die stroom nodig hebben';
  static const planCareDevicesTip =
      'Hoe krijg je de zorg die je nodig hebt als de stroom uitvalt? Bespreek dit '
      'met je zorgverlener en je netbeheerder.';
  static const planCareAllergies = 'Allergieën';
  static const planCareCaregiving = 'Mantelzorg en hulp';
  static const planCareDocuments = 'Waar liggen belangrijke documenten?';
  static const planCareNoSensitive =
      'Vul hier nooit je BSN, paspoort- of bankgegevens in. Schrijf alleen op waar '
      'je documenten liggen.';

  // Stap 7: buren
  static const planNbWhy =
      'Buren zijn vaak het dichtstbij. Bespreek wie jou kan helpen, wie jij helpt '
      'en wat je samen afspreekt.';
  static const planNbHelpMe = 'Wie kan jou helpen?';
  static const planNbIHelp = 'Wie help jij?';
  static const planNbDeals = 'Afspraken met buren';

  // Afronden
  static const planSummaryTitle = 'Je noodplan';
  static const planSummaryIntro =
      'Dit is hoe je document eruitziet. Je kunt elk onderdeel later nog aanpassen.';
  static const planSummaryEmpty =
      'Je plan is nog leeg. Dat is prima: begin met één onderdeel.';
  static const planStoredLocal =
      'Je gegevens staan alleen op dit toestel, tot je zelf deelt.';
  static const planFinishDone = 'Naar mijn noodplan';

  // Delen
  static const planShareTitle = 'Noodplan delen';
  static const planShareWarn =
      'Let op: in het document kunnen namen, telefoonnummers en adressen staan. '
      'Deel het alleen met mensen die je vertrouwt.';
  static const planShareChoose = 'Wat wil je delen?';
  static const planShareCareWarn = 'Bevat medische gegevens. Staat standaard uit.';
  static const planSharePhotos = "Foto's (alleen in het app-bestand)";
  static const planSharePdf = 'Deel als pdf';
  static const planShareText = 'Deel als tekst';
  static const planSharePrint = 'Afdrukken';
  static const planShareFile = 'Deel als app-bestand';
  static const planShareFileHint = 'Voor andere NL-Noodpakket-gebruikers (.json).';
  static const planShareError = 'Delen is niet gelukt.';

  // Importeren
  static const planImportTitle = 'Noodplan importeren';
  static String planImportFrom(String name) =>
      name.isEmpty ? 'Noodplan' : 'Noodplan "$name"';
  static String planImportContains(int people, int contacts) =>
      'Bevat $people personen en $contacts contacten.';
  static const planImportMerge = 'Samenvoegen (jouw invulling blijft staan)';
  static const planImportReplace = 'Vervangen (je huidige plan wordt gewist)';
  static const planImportInvalid = 'Dit bestand is geen geldig noodplan.';
  static const planImportTooNew =
      'Dit bestand komt uit een nieuwere versie van de app. Werk de app bij om het te openen.';
  static const planImportDone = 'Noodplan geïmporteerd';
  static const planImportReplaceConfirm =
      'Je huidige noodplan wordt vervangen door dit bestand. Dit kan niet ongedaan worden gemaakt.';

  // Samen plannen (gesprekskaarten, gebaseerd op denkvooruit.nl: noodplan en praat erover)
  static const planTalkTitle = 'Bespreek met je huishouden';
  static const planTalkIntro =
      'Eén vraag per kaart. Praat erover en vul het antwoord meteen in. '
      'Niemand hoeft alles zelf te doen.';
  static const planTalkStart = 'Start gesprek';
  static String planTalkCardOf(int i, int n) => 'Vraag $i van $n';
  static const planTalkAnswerHint = 'Typ hier jullie antwoord';
  static String planTalkSavedTo(String label) => 'Wordt opgeslagen bij: $label';
  static const planTalkDone = 'Jullie hebben alle vragen besproken.';
  static const planTalkQ1 =
      'Op je werk, telefoon werkt niet: wie haalt de kinderen op van school?';
  static const planTalkQ2 = 'Partner niet bereikbaar: waar ontmoeten jullie elkaar?';
  static const planTalkQ3 = 'Familie in een andere stad: hoe blijf je in contact?';
  static const planTalkQ4 =
      'Wie in onze omgeving heeft extra hulp nodig in een noodsituatie?';
  static const planTalkQ5 = 'Slecht ter been, lift werkt niet: hoe kom je naar buiten?';
  static const planTalkQ6 =
      'Afhankelijk van medische apparatuur: hoe krijg je de zorg die je nodig hebt?';
  static const planTalkQ7 = 'Geen internet: waar vind je betrouwbare informatie?';
  static const planTalkQ8 = 'Welke afspraken kunnen we met elkaar maken?';
  static const planTalkQ9 = 'Waar kunnen we elkaar mee helpen?';

  // Document (pdf en tekst)
  static String planDocTitle(String name) => 'Noodplan $name';
  static const planDocTitleNoName = 'Noodplan';
  static String planDocDate(String d) => 'Datum: $d';
  static String planDocVersion(int v) => 'Versie $v';
  static const planDoc112 = 'Levensgevaar: bel 112';
  static const planDocContacts = 'Contacten';
  static const planDocPlaces = 'Verzamelplekken';
  static const planDocAgreements = 'Afspraken';
  static const planDocHome = 'Thuis: waar vind je wat';
  static const planDocPersons = 'Per persoon';
  static const planDocCare = 'Zorg en bijzonderheden';
  static const planDocFirstHour = 'Eerste uur';
  static const planDocFooter =
      'Gemaakt met NL-Noodpakket. Deze app is niet van de overheid.';

  // Wiki-koppeling
  static const planWikiBlock = 'Jouw afspraken';
  static const planWikiEmpty = 'Nog niet ingevuld';
  static const planWikiFill = 'Vul dit in';
  static const planWikiEdit = 'Aanpassen';

  // Herinnering
  static const notifTitlePlan = 'Klopt je noodplan nog?';
  static const notifBodyPlan = 'Loop je noodplan even na en bevestig dat alles klopt.';

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
