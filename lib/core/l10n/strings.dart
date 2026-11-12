/// Alle UI-teksten (nl-NL). Voor een andere taal: maak een tweede klasse met
/// dezelfde leden of migreer naar ARB/gen-l10n; widgets bevatten geen eigen tekst.
class S {
  S._();

  static const appName = 'NL-Noodpakket';
  static const disclaimer =
      'Deze app vertegenwoordigt de Nederlandse overheid niet en is niet door '
      'officiële instanties gemaakt.';

  // Navigatie
  static const navHome = 'Start';
  static const navMore = 'Meer';
  static const segList = 'Lijst';
  static const segReplace = 'Vervangen';

  // Start (dashboard)
  static const homeTitle = 'Rustig voorbereiden';
  static const homeSub = 'Stap voor stap een noodpakket voor jouw huishouden.';
  static String homeReady(int pct) => '$pct%';
  static const homeToPacket = 'Naar je pakket';
  static const homeNext = 'Volgende stappen';
  static const homeFirstHour = 'Eerste uur';
  static const homeStepPlan = 'Maak je noodplan';
  static const homeStepPlanSub = 'Afspraken met je huishouden, in ongeveer 10 minuten.';
  static String homeStepExpiring(int n) =>
      n == 1 ? '1 ding om te vervangen of te controleren' : '$n dingen om te vervangen of te controleren';
  static const homeStepExpiringSub = 'Bekijk wat binnenkort verloopt.';
  static String homeStepCategory(String name) => 'Vul "$name" aan';
  static String homeStepCategorySub(int done, int total) => '$done van $total in huis';
  static const homeStepVault = 'Bewaar kopieën van je documenten';
  static const homeStepVaultSub = 'Versleuteld op dit toestel, met biometrie.';
  static const homeAllGood = 'Alles staat op orde';
  static const homeAllGoodSub = 'Controleer je pakket elk half jaar.';

  // Meer
  static const moreTitle = 'Meer';
  static const moreInfoSub = 'Waarom een noodpakket, tips en denkvooruit.nl';
  static const moreSettingsSub = 'Huishouden, herinneringen, thema en back-up';

  static const navChecklist = 'Pakket';
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
  /// Zichtbaar label van de tab (kort, past in de balk). Wissel hier gerust naar 'Nood'.
  static const navEmergencies = 'Wat nu?';
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

  // Documentenkluis
  static const vaultTitle = 'Documentenkluis';
  static const vaultDisclaimer =
      'Dit zijn eigen kopieën. De kluis is geen officieel identiteitsbewijs, geen '
      'DigiD en vervangt het origineel niet.';
  static const vaultEntrySub = 'Kopieën van belangrijke documenten, versleuteld op dit toestel.';
  static const vaultOpen = 'Open documentenkluis';
  static const vaultMakeBackup = 'Maak back-up';
  static const vaultNoodmapOpen = 'Noodmap openen';
  static const vaultHasDocs = 'Er staan documenten in je kluis.';
  static const vaultLinkSub = 'Open de documentenkluis';
  static const vaultSecureLabel = 'Beveiligd scherm';

  // Instellen
  static const vaultIntro1Title = 'Je documenten veilig op je toestel';
  static const vaultIntro1Body =
      'Bewaar kopieën van bijvoorbeeld je paspoort, polissen en medische gegevens. '
      'Alles wordt versleuteld op dit toestel opgeslagen en blijft daar. Geen account, geen cloud.';
  static const vaultIntro2Title = 'Zo blijft het veilig';
  static const vaultIntro2Body =
      'Je ontgrendelt de kluis met je vingerafdruk of gezicht, of met je kluis-PIN. '
      'Vergeet je je PIN, dan heb je de herstelcode nodig. Zonder beide zijn de '
      'documenten onherstelbaar weg.';
  static const vaultHaveBackup =
      'Heb je al een back-up? Stel eerst een PIN in en zet daarna je back-up terug.';
  static const vaultPinTitle = 'Kies een kluis-PIN';
  static const vaultPinBody =
      'Minimaal 6 cijfers. Kies een PIN die je kunt onthouden, maar niet je '
      'pincode of geboortedatum. Een langere PIN is veiliger.';
  static const vaultPinLabel = 'Kluis-PIN';
  static const vaultPinConfirmTitle = 'Herhaal je PIN';
  static const vaultPinMismatch = 'De PIN\'s komen niet overeen. Probeer het opnieuw.';
  static const vaultPinTooShort = 'Gebruik minimaal 6 cijfers.';
  static const vaultPinWeak = 'Deze PIN is makkelijk te raden. Kies een andere.';
  static const vaultBioTitle = 'Ontgrendelen met vingerafdruk of gezicht';
  static const vaultBioBody =
      'Dan hoef je niet elke keer je PIN in te voeren. Je PIN blijft altijd beschikbaar.';
  static const vaultBioActivate = 'Activeer';
  static const vaultBioSkip = 'Nu niet';
  static const vaultBioNotAvailable =
      'Op dit toestel is geen biometrie ingesteld. Je gebruikt alleen je PIN.';
  static const vaultNoLockscreen =
      'Tip: stel een schermvergrendeling in op je toestel voor extra veiligheid. '
      'Je kluis-PIN is nu je enige beveiliging.';
  static const vaultBioPromptTitle = 'Kluis ontgrendelen';
  static const vaultBioPromptSubtitle = 'Bevestig met je vingerafdruk of gezicht';
  static const vaultBioUsePin = 'Gebruik PIN';
  static const vaultRecoveryTitle = 'Je herstelcode';
  static const vaultRecoveryBody =
      'Schrijf deze code op papier en bewaar hem op een veilige plek, apart van je '
      'toestel. Hij wordt maar één keer getoond. Kopiëren is bewust uitgeschakeld.';
  static const vaultRecoveryWarning =
      'Vergeet je je PIN én je herstelcode, dan zijn je documenten onherstelbaar weg. '
      'Wij kunnen ze niet herstellen.';
  static const vaultRecoveryWritten = 'Ik heb de herstelcode op papier bewaard';
  static String vaultRecoveryVerifyPrompt(int group) =>
      'Controle: vul groep $group van je herstelcode in.';
  static const vaultRecoveryVerifyHint = '4 tekens';
  static const vaultRecoveryVerifyWrong = 'Dat klopt niet. Kijk nog eens naar je notitie.';
  static const vaultRecoveryDone = 'Klaar';
  static const vaultSetupBusy = 'Kluis wordt ingericht…';
  static const vaultSetupError = 'De kluis kon niet worden ingericht. Probeer het opnieuw.';
  static const vaultContinue = 'Doorgaan';

  // Ontgrendelen
  static const vaultLockedTitle = 'Kluis vergrendeld';
  static const vaultLockedBody = 'Ontgrendel om je documenten te bekijken.';
  static const vaultUnlockBio = 'Ontgrendel met biometrie';
  static const vaultUnlock = 'Ontgrendelen';
  static const vaultWrongPin = 'Onjuiste PIN.';
  static String vaultLockedOut(String wait) =>
      'Te veel pogingen. Probeer het opnieuw over $wait.';
  static const vaultForgotPin = 'PIN vergeten?';
  static const vaultRecoveryEnterTitle = 'Herstelcode invoeren';
  static const vaultRecoveryEnterHint = 'Herstelcode';
  static const vaultRecoveryWrong = 'Deze herstelcode klopt niet.';
  static const vaultNewPinTitle = 'Kies een nieuwe PIN';
  static const vaultBioFailed = 'Ontgrendelen met biometrie is niet gelukt. Gebruik je PIN.';
  static const vaultBioChanged =
      'Je biometrie is gewijzigd. Voer je PIN in om hem opnieuw te koppelen.';
  static const vaultUnlockError = 'Ontgrendelen mislukt. Probeer het opnieuw.';
  static const vaultLockNow = 'Vergrendel nu';

  // Overzicht
  static const vaultEmpty = 'Je kluis is leeg. Voeg je eerste document toe.';
  static const vaultAddDocument = 'Document toevoegen';
  static const vaultSearchHint = 'Zoek op titel';
  static const vaultFilterAllTypes = 'Alle types';
  static const vaultFilterEveryone = 'Iedereen';
  static const vaultNoodmap = 'Noodmap';
  static const vaultNoodmapSub = 'Documenten die je bij evacuatie als eerste nodig hebt.';
  static const vaultAllDocs = 'Alle documenten';
  static const vaultExpiringSoon = 'Binnenkort verlopen';
  static String vaultPagesCount(int n) => n == 1 ? '1 pagina' : '$n pagina\'s';
  static const vaultViewGrid = 'Toon als raster';
  static const vaultViewList = 'Toon als lijst';
  static const vaultNoResults = 'Geen documenten gevonden.';
  static const vaultLoadError = 'De kluis kon niet worden geladen.';
  static const vaultSettings = 'Kluis-instellingen';
  static const vaultExpired = 'Verlopen';
  static String vaultExpiresOn(String d) => 'Verloopt op $d';
  static String vaultExpiredOn(String d) => 'Verlopen op $d';

  // Toevoegen
  static const vaultAddTitle = 'Document toevoegen';
  static const vaultEditTitle = 'Document bewerken';
  static const vaultSourceScan = 'Scannen met de camera';
  static const vaultSourceGallery = 'Foto kiezen uit galerij';
  static const vaultSourceFile = 'Bestand kiezen (pdf, jpg, png, heic)';
  static const vaultPages = 'Pagina\'s';
  static const vaultAddPage = 'Pagina toevoegen';
  static const vaultRemovePage = 'Pagina verwijderen';
  static String vaultPageLabel(int n) => 'Pagina $n';
  static const vaultFieldTitle = 'Titel';
  static const vaultFieldType = 'Type';
  static const vaultFieldOwner = 'Van wie';
  static const vaultFieldOwnerFree = 'Of typ een naam';
  static const vaultFieldExpiry = 'Verloopdatum (optioneel)';
  static const vaultFieldNote = 'Notitie (optioneel)';
  static const vaultFieldNoodmap = 'Zet in de Noodmap';
  static const vaultNoNumbers =
      'Je hoeft geen documentnummers in te vullen. De scan zelf is genoeg.';
  static const vaultNewType = 'Nieuw type…';
  static const vaultNewTypeName = 'Naam van het type';
  static const vaultNewTypeIdentity = 'Dit is een identiteitsdocument';
  static const vaultTitleRequired = 'Geef het document een titel.';
  static const vaultPagesRequired = 'Voeg minstens één pagina toe.';
  static const vaultSaving = 'Versleutelen en opslaan…';
  static const vaultSave = 'Opslaan';
  static const vaultCameraDenied = 'Geen toegang tot de camera. Je kunt ook een foto of bestand kiezen.';
  static const vaultScanError = 'Scannen is niet gelukt.';
  static const vaultUnsupportedFile = 'Dit bestandstype wordt niet ondersteund.';
  static const vaultFileTooBig = 'Dit bestand is te groot (maximaal 50 MB).';
  static const vaultImageFallback =
      'Deze afbeelding kon niet worden gecomprimeerd en is origineel bewaard.';
  static const vaultSaveError = 'Opslaan is niet gelukt. Er is niets gewijzigd.';
  static const vaultClearExpiry = 'Datum wissen';
  static const vaultPickDate = 'Kies datum';

  // Bekijken
  static const vaultViewerError = 'Dit bestand kan niet worden weergegeven.';
  static const vaultHeicNote = 'Dit bestandstype kan op dit toestel niet worden getoond. Je kunt het wel delen.';
  static String vaultPageOf(int i, int n) => 'Pagina $i van $n';
  static const vaultShare = 'Delen';
  static const vaultEdit = 'Bewerken';
  static const vaultDelete = 'Verwijderen';
  static const vaultDeleteTitle = 'Document verwijderen?';
  static const vaultDeleteBody = 'Dit document wordt definitief uit de kluis verwijderd.';
  static const vaultDocNotFound = 'Dit document bestaat niet meer.';

  // Delen
  static const vaultShareTitle = 'Dit document delen?';
  static const vaultShareWarn =
      'Het gedeelde bestand verlaat de kluis en is daarna niet meer beveiligd. '
      'Deel het alleen met mensen die je vertrouwt.';
  static const vaultWatermark = 'Voeg watermerk toe';
  static const vaultWatermarkPurpose = 'Doel (bijv. huurovereenkomst)';
  static const vaultWatermarkDate = 'Datum';
  static const vaultWatermarkTip =
      'Tip: dek je BSN af voordat je deelt. Het watermerk laat zien voor welk doel '
      'de kopie bedoeld is.';
  static const vaultShareConfirm = 'Delen';
  static const vaultShareError = 'Delen is niet gelukt.';
  static const vaultSharePdfNoWatermark =
      'Een watermerk kan alleen op afbeeldingen. Pdf-bestanden worden zonder watermerk gedeeld.';

  // Instellingen
  static const vaultBioSetting = 'Ontgrendelen met biometrie';
  static const vaultBioSettingOff = 'Biometrie is niet beschikbaar op dit toestel.';
  static const vaultChangePin = 'PIN wijzigen';
  static const vaultCurrentPin = 'Huidige PIN';
  static const vaultNewPin = 'Nieuwe PIN';
  static const vaultPinChanged = 'PIN gewijzigd';
  static const vaultAutoLock = 'Automatisch vergrendelen';
  static const vaultAutoLockNow = 'Direct';
  static const vaultAutoLock1 = 'Na 1 minuut';
  static const vaultAutoLock5 = 'Na 5 minuten';
  static const vaultAutoLockHint = 'Na het naar de achtergrond gaan van de app.';
  static const vaultReminders = 'Herinneringen voor verloopdatums';
  static String vaultReminderDays(int d) => d == 1 ? '1 dag' : '$d dagen';
  static const vaultRemindersSub = 'Hoe lang vooraf je een neutrale herinnering krijgt.';
  static const vaultWipe = 'Kluis wissen';
  static const vaultWipeSub = 'Wist alle documenten, miniaturen en sleutels.';
  static const vaultWipe1Title = 'Kluis wissen?';
  static const vaultWipe1Body =
      'Alle documenten, miniaturen en sleutels worden definitief gewist. Dit kan niet '
      'ongedaan worden gemaakt, ook niet met je herstelcode.';
  static const vaultWipe2Title = 'Weet je het zeker?';
  static const vaultWipe2Body = 'Dit is de laatste kans om te annuleren.';
  static const vaultWipeConfirm = 'Ja, alles wissen';
  static const vaultWiped = 'Kluis gewist';

  // Back-up
  static const vaultBackup = 'Back-up maken (.noodkluis)';
  static const vaultBackupRestore = 'Back-up terugzetten';
  static const vaultBackupInfo =
      'Een nieuw toestel of een verloren telefoon betekent dat deze back-up nodig is. '
      'Bewaar het bestand en het wachtwoord op een veilige plek, apart van elkaar. '
      'Zonder wachtwoord is de back-up onbruikbaar.';
  static const vaultBackupPassword = 'Back-upwachtwoord';
  static const vaultBackupPasswordRepeat = 'Herhaal wachtwoord';
  static const vaultBackupPasswordShort = 'Gebruik minimaal 10 tekens.';
  static const vaultBackupPasswordMismatch = 'De wachtwoorden komen niet overeen.';
  static const vaultBackupBusy = 'Back-up wordt versleuteld…';
  static const vaultBackupError = 'Back-up maken is niet gelukt.';
  static const vaultBackupEmpty = 'Er zijn nog geen documenten om te bewaren.';
  static const vaultRestorePassword = 'Wachtwoord van de back-up';
  static const vaultRestoreWrong = 'Onjuist wachtwoord of beschadigd bestand.';
  static const vaultRestoreTooNew =
      'Dit bestand komt uit een nieuwere versie van de app. Werk de app bij om het te openen.';
  static const vaultRestoreInvalid = 'Dit is geen geldig .noodkluis-bestand.';
  static String vaultRestorePreview(int n) =>
      n == 1 ? 'Deze back-up bevat 1 document.' : 'Deze back-up bevat $n documenten.';
  static const vaultRestoreMerge = 'Samenvoegen (bestaande documenten blijven)';
  static const vaultRestoreReplace = 'Vervangen (je huidige kluis wordt gewist)';
  static const vaultRestoreReplaceConfirm =
      'Je huidige documenten worden vervangen door de back-up. Dit kan niet ongedaan worden gemaakt.';
  static const vaultRestoreDone = 'Back-up teruggezet';
  static const vaultRestoreBusy = 'Back-up wordt gelezen…';

  // Notificaties (bewust neutraal: geen titels, namen of nummers)
  static const notifTitleVault = 'Documentenkluis';
  static const notifBodyVault = 'Een document in je kluis verloopt binnenkort.';

  // Documenttypes
  static const vaultTypePassport = 'Paspoort';
  static const vaultTypeIdCard = 'Identiteitskaart';
  static const vaultTypeDriving = 'Rijbewijs';
  static const vaultTypeResidence = 'Verblijfs- of overige documenten';
  static const vaultTypeHealthIns = 'Zorgverzekering of zorgpas';
  static const vaultTypePolicyHome = 'Polis woning of inboedel';
  static const vaultTypePolicyCar = 'Polis auto';
  static const vaultTypePolicyLiability = 'Polis aansprakelijkheid';
  static const vaultTypeMedication = 'Medicatie en recepten';
  static const vaultTypeMedical = 'Medische gegevens of bloedgroepkaart';
  static const vaultTypeGp = 'Huisarts en apotheek';
  static const vaultTypePet = 'Dierenpaspoort of chipnummer';
  static const vaultTypeOwnership = "Eigendomsbewijzen en inventaris-foto's";
  static const vaultTypeOther = 'Overig';

  // Noodhacks
  static const hacksTitle = 'Noodhacks';
  static const hacksDisclaimer =
      'Dit zijn noodmaatregelen voor als normale voorzieningen ontbreken. Bij levensgevaar '
      'bel je 112. Deze app vertegenwoordigt de Nederlandse overheid niet.';
  static const hacksEntrySub = 'Praktische tips voor als je pakket op is.';
  static const hacksSearchHint = 'Zoek: water, koken, koelkast…';
  static const hacksFilterAll = 'Alles';
  static const hacksLabelSafe = 'Veilig';
  static const hacksLabelCaution = 'Let op';
  static const hacksLabelNever = 'Doe dit nooit';
  static const hacksNoResults = 'Geen noodhack gevonden. Probeer een ander woord.';
  static const hacksLoadError = 'De noodhacks konden niet worden geladen.';
  static const hacksNotFound = 'Deze noodhack bestaat niet.';
  static const hacksIntroOut = 'Mijn pakket is op';
  static const hacksIntroOutSub = 'Wat doe je eerst? In vijf stappen.';
  static const hacksHave = 'Wat heb ik in huis?';
  static const hacksHaveSub = 'Kies je spullen en zie wat daarmee kan.';
  static const hacksNeed = 'Wat heb je nodig';
  static const hacksSteps = 'Zo doe je het';
  static const hacksWarnings = 'Let op';
  static const hacksWhyNot = 'Waarom niet?';
  static const hacksInstead = 'Doe dit in plaats daarvan';
  static const hacksStart = 'Start stappenplan';
  static const hacksSources = 'Bronnen';
  static const hacksSourceOfficial = 'Bron: officiële Nederlandse bron.';
  static const hacksSourceGeneral = 'Bron: gezaghebbende algemene bron (internationaal). Nederlandse adviezen gaan voor.';
  static String hacksReviewed(String d) => 'Laatst gecontroleerd: $d';
  static const hacksYouHave = 'Heb je in huis';
  static const hacksNoMaterial = 'Geen speciale spullen nodig';
  static const hacksStepsList = 'Toon als lijst';
  static const hacksStepsOne = 'Eén stap per scherm';
  static const hacksReadFirst = 'Eerst lezen';
  static const hacksRelatedBlock = 'Als je pakket op is';
  static const hacksAllHacks = 'Alle noodhacks';
  static const hacksHandy = 'Handige hacks';
  static const hacksAddFav = 'Voeg toe aan favorieten';
  static const hacksRemoveFav = 'Verwijder uit favorieten';
  static const hacksFavorites = 'Favorieten';
  // "Wat heb ik in huis?"
  static const hacksHaveTitle = 'Wat heb ik in huis?';
  static const hacksHaveIntro = 'Tik aan wat je hebt. Je ziet welke noodhacks daarmee kunnen.';
  static const hacksHavePossible = 'Dit kan nu';
  static const hacksHaveAlmost = 'Bijna: er ontbreekt iets';
  static String hacksMissing(String what) => 'Je mist: $what';
  static const hacksHaveNone = 'Kies hierboven wat je hebt.';
  static const hacksHaveSaved = 'Je keuze wordt onthouden op dit toestel.';
  static const hacksHaveClear = 'Alles wissen';
  // "Mijn pakket is op"
  static const hacksOutTitle = 'Mijn pakket is op';
  static const hacksOutIntro =
      'Doe dit in volgorde. Water gaat voor, daarna warmte, hygiëne en eten. Zoek ook hulp bij anderen.';
  static const hacksOut1 = 'Water';
  static const hacksOut2 = 'Warmte';
  static const hacksOut3 = 'Toilet en hygiëne';
  static const hacksOut4 = 'Eten';
  static const hacksOut5 = 'Hulp zoeken';
  static const hacksOutHelp = [
    'Luister naar de regionale omroep op een radio op batterijen.',
    'Vraag je buren om hulp en bied hulp aan.',
    'Kijk op rijksoverheid.nl of vraag je gemeente of veiligheidsregio om informatie.',
    'Is er langer dan 24 uur geen kraanwater? Haal nooddrinkwater bij het distributiepunt van je gemeente.',
  ];
  static const hacksOutFirstHour = 'Eerste-uur kaart';

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
      'analyse en geen tracking, en werkt volledig offline. Delen met een ander '
      'toestel gebeurt rechtstreeks via hetzelfde wifi, zonder server.';
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

  // ---- Dashboard "Start" ----
  static const navPlan = 'Mijn plan';
  static const dashSub = 'Zo staat het ervoor.';
  static const dashCall112 = 'Bel 112';
  static const dashCall112Hint = 'Opent je telefoon-app met 112 ingevuld. Er wordt niet automatisch gebeld.';

  static const dashReadyTitle = 'Paraatheid';
  static String dashReadyDays(String d) => 'ongeveer $d van de 3 dagen zelfredzaam';
  static const dashReadyEmpty = 'Begin met je pakket.';
  static const dashReadyEmptySub = 'Vink aan wat je al hebt.';
  static const dashReadyNeedQty =
      'Vul bij water en eten in hoeveel je hebt. Dan kunnen we het uitrekenen.';
  static const dashReadyGoal =
      'Doel bereikt: je hebt water en eten voor 3 dagen. Controleer af en toe de houdbaarheid.';
  static const dashReadyHow = 'Hoe is dit berekend?';
  static const dashReadyFill = 'Vul in hoeveel je hebt';
  static const moreOptions = 'Meer opties';
  static const setDisplay = 'Weergave';
  static const dashReadyEstimate = 'Dit is een schatting op basis van jouw invoer.';
  static const dashHowTitle = 'Zo rekenen we';
  static const dashHowGoal =
      'Doel: 72 uur (3 dagen) zelfredzaam, zoals Denk Vooruit adviseert.';
  static String dashHowWater(int persons, String liters, String days) =>
      'Water: $liters liter in huis, gedeeld door 3 liter per persoon per dag voor $persons ${persons == 1 ? 'persoon' : 'personen'}. Dat is $days dagen.';
  static String dashHowFood(int persons, String meals, String days) =>
      'Eten: $meals maaltijden in huis, gedeeld door 3 maaltijden per persoon per dag voor $persons ${persons == 1 ? 'persoon' : 'personen'}. Dat is $days dagen. Die 3 maaltijden per dag is een eigen afspraak van deze app.';
  static const dashHowMin = 'Het laagste van water en eten telt. Zonder water kom je niet verder met alleen eten, en andersom.';
  static const dashHowRules =
      'Alleen hoeveelheden die je invult tellen mee. Afgevinkt zonder hoeveelheid telt niet. Verlopen items tellen niet mee. Het aantal personen komt uit je huishouden.';
  static String dashHowExcluded(int n) =>
      n == 1 ? '1 verlopen item telt niet mee.' : '$n verlopen items tellen niet mee.';
  static const dashStepsTitle = 'Drie stappen van Denk Vooruit';
  static String dashStepPacket(int pct) => 'Noodpakket: $pct% compleet';
  static String dashStepPlan(int done, int total) => 'Noodplan: $done van $total onderdelen';
  static const dashStepPlanNone = 'Noodplan: nog niet gemaakt';
  static const dashStepTalk = 'Praat erover met je huishouden';

  static const dashNextTitle = 'Volgende stap';
  static const dashShowAll = 'Toon alles';
  static const dashLater = 'Later';
  static const dashNotRelevant = 'Niet relevant';
  static const dashLaterDone = 'We tonen dit over 7 dagen opnieuw.';
  static const dashNotRelevantDone = 'Verborgen. Je kunt dit herstellen bij Instellingen.';
  static const dashAllTitle = 'Alle suggesties';
  static const dashAllEmpty = 'Alles op orde. Er is nu niets te doen.';

  static const dashSugHouseholdT = 'Vul je huishouden aan';
  static const dashSugHouseholdS = 'Dan klopt het aantal liters en maaltijden.';
  static const dashSugHouseholdA = 'Aanpassen';
  static const dashSugNlAlertT = 'Controleer of je NL-Alert ontvangt';
  static const dashSugNlAlertS = 'Het kost een minuut.';
  static const dashSugNlAlertA = 'Bekijk hoe';
  static const dashSugWaterNoneT = 'Zet water in huis';
  static const dashSugWaterNoneS = 'Reken op 3 liter per persoon per dag.';
  static String dashSugWaterFewT(String d) => 'Je hebt water voor ongeveer $d dagen';
  static const dashSugWaterFewS = 'Doel: 3 dagen.';
  static const dashSugWaterA = 'Invullen';
  static String dashSugExpiredT(int n) =>
      n == 1 ? '1 ding is verlopen' : '$n dingen zijn verlopen';
  static String dashSugSoonT(int n) =>
      n == 1 ? '1 ding verloopt binnenkort' : '$n dingen verlopen binnenkort';
  static const dashSugExpiringS = 'Vervang of controleer het.';
  static const dashSugExpiringA = 'Bekijk';
  static const dashSugPlanNewT = 'Maak je noodplan';
  static const dashSugPlanNewS = 'Afspraken met je huishouden, in ongeveer 10 minuten.';
  static const dashSugPlanFinishT = 'Maak je noodplan af';
  static const dashSugPlanFinishS = 'Een paar onderdelen zijn nog leeg.';
  static const dashSugPlanStaleT = 'Controleer of je noodplan nog klopt';
  static const dashSugPlanStaleS = 'Je hebt het langer dan 6 maanden niet bekeken.';
  static const dashSugPlanA = 'Open noodplan';
  static const dashSugVaultT = 'Bewaar kopieën van je documenten';
  static const dashSugVaultS = 'Versleuteld op dit toestel.';
  static const dashSugVaultA = 'Open kluis';
  static String dashSugItemT(String name) => 'Zorg voor: $name';
  static const dashSugItemKritiek = 'Dit is belangrijk voor de eerste dagen.';
  static const dashSugItemBelangrijk = 'Een goede aanvulling op je pakket.';
  static const dashSugItemAanvullend = 'Als je er ruimte voor hebt.';
  static const dashSugItemA = 'Bekijk';
  static String dashSugMaintT(int n) =>
      n == 1 ? '1 onderhoudstaak staat klaar' : '$n onderhoudstaken staan klaar';
  static const dashSugMaintS = 'Bijvoorbeeld de rookmelder testen.';
  static const dashSugMaintA = 'Bekijk';

  static const dashExpiringTitle = 'Binnenkort vervangen';
  static const dashExpiringAll = 'Alles bekijken';
  static String dashExpiredOn(String d) => 'Verlopen op $d';
  static String dashDueOn(String d) => 'Vervangen vóór $d';

  static String dashSeasonNlAlertT(String d) => 'NL-Alert-testbericht op $d';
  static const dashSeasonNlAlertS =
      'Rond 12.00 uur. Zo weet je of je telefoon NL-Alert ontvangt.';
  static const dashSeasonNlAlertA = 'Meer informatie';
  static const dashSeasonWinterT = 'Nu relevant: winter';
  static const dashSeasonWinterS =
      'Koolmonoxide (CO) en kou. Lees de stappenplannen als je ze nog niet kent.';

  static const dashPlanCard = 'Noodplan';
  static const dashPlanNone = 'Nog niet gemaakt';
  static String dashPlanPart(int d, int t) => '$d van $t onderdelen';
  static const dashPlanDone = 'Compleet';
  static const dashPlanStale = 'Even nalopen';
  static const dashVaultCard = 'Kluis';
  static const dashVaultNone = 'Nog niets bewaard';
  static const dashVaultSome = 'Documenten bewaard';

  static const maintTitle = 'Onderhoud';
  static const maintSub = 'Kleine terugkerende controles. Je bepaalt zelf of je een herinnering wilt.';
  static const maintRookmelder = 'Rookmelder testen';
  static const maintPakket = 'Pakket controleren';
  static const maintPowerbank = 'Powerbank opladen';
  static const maintBatterijen = 'Batterijen controleren';
  static const maintEveryMonth = 'Elke maand';
  static const maintEveryHalfYear = 'Elk half jaar';
  static const maintEveryYear = 'Elk jaar';
  static String maintDue(String d) => 'Aan de beurt sinds $d';
  static String maintNext(String d) => 'Volgende keer: $d';
  static const maintDone = 'Gedaan';
  static const maintRemind = 'Herinnering';
  static const maintAll = 'Alle routines';
  static const notifTitleMaint = 'Onderhoud';
  static const notifBodyMaint = 'Er staat een onderhoudstaak voor je klaar.';

  static const dashHouseholdTitle = 'Jouw huishouden';
  static const dashHouseholdEdit = 'Aanpassen';

  static const dashAllGoodLine = 'Alles op orde. Controleer je pakket elk half jaar.';

  static const nlTitle = 'NL-Alert controleren';
  static const nlIntro =
      'NL-Alert is het waarschuwingssysteem van de overheid. Het stuurt een bericht naar telefoons in de buurt van een gevaar.';
  static const nlFact1 = 'Het is gratis en je hoeft je er niet voor aan te melden.';
  static const nlFact2 =
      'Je telefoon moet aanstaan en bereik hebben om een bericht te ontvangen.';
  static const nlFact3 =
      'Elk half jaar is er een testbericht, op de eerste maandag van juni en december, rond 12.00 uur.';
  static const nlFact4 =
      'Krijg je het testbericht niet? Op nl-alert.nl staat uitleg per telefoon over wat je kunt controleren.';
  static String nlNextTest(String d) => 'Het volgende testbericht is op $d.';
  static const nlOpenSite = 'Ga naar nl-alert.nl';
  static const nlDone = 'Gedaan';
  static const nlDoneNote = 'Gemarkeerd als gedaan.';

  static const simpleStartTitle = 'Eenvoudige start';
  static const simpleStartSub = 'Toon op Start vier grote knoppen in plaats van het dashboard.';
  static const restoreHidden = 'Verborgen suggesties herstellen';
  static String restoreHiddenSub(int n) =>
      n == 0 ? 'Er is niets verborgen.' : '$n verborgen. Tik om ze terug te zetten.';

  static const myPlanTitle = 'Mijn plan';
  static const myPlanSub = 'Afspraken en documenten.';
  static const myPlanTalkSub = 'Eén vraag per kaart, samen met je huishouden.';
  static const moreMaintSub = 'Rookmelder, powerbank en andere vaste controles';

  // ---- Pro ----
  static const proName = 'NL-Noodpakket Pro';
  static const proBadge = 'Pro';
  static const paywallTitle = 'NL-Noodpakket Pro';
  static const paywallGetTitle = 'Wat je erbij krijgt';
  static const paywallGet1 = 'Alle noodhacks: stappenplannen voor als je pakket op is, met "Wat heb ik in huis?"';
  static const paywallGet2 = 'Automatische herinneringen voor items die aan vervanging toe zijn';
  static const paywallGet3 = 'Onbeperkt documenten in de kluis';
  static const paywallFreeTitle = 'Dit blijft altijd gratis';
  static const paywallFree1 = 'Checklist en houdbaarheidsoverzicht';
  static const paywallFree2 = 'Alle noodgevallen-stappenplannen';
  static const paywallFree3 = 'Noodplan, ook delen en back-up';
  static const paywallFree4 = 'De kluis tot 3 documenten';
  static const paywallFree5 = 'De gevaarlijke mythes';
  static String paywallUnlock(String price) => 'Ontgrendel Pro, $price eenmalig';
  static const paywallUnlockNoPrice = 'Ontgrendel Pro';
  static const paywallNoSub = 'Geen abonnement. Eén keer betalen, geen account.';
  static const paywallHelp = 'Pro helpt de ontwikkeling van de app te betalen.';
  static const paywallRestore = 'Aankoop herstellen';
  static const paywallNotNow = 'Niet nu';
  static const paywallPriceLoading = 'De prijs komt uit de winkel van je toestel.';
  static const proMsgThanks = 'Bedankt! Pro is ontgrendeld.';
  static const proMsgRestored = 'Je aankoop is hersteld.';
  static const proMsgNothing = 'Er is geen aankoop gevonden om te herstellen.';
  static const proMsgCancelled = 'De aankoop is niet doorgegaan. Er is niets afgeschreven.';
  static const proMsgPending = 'Je betaling wordt nog verwerkt. Pro wordt ontgrendeld zodra die klaar is.';
  static const proMsgUnavailable = 'De winkel is nu niet bereikbaar. Probeer het later opnieuw.';
  static const proMsgError = 'Er ging iets mis. Probeer het later opnieuw.';
  static const proSettingsOn = 'Pro is ontgrendeld. Bedankt!';
  static const proSettingsOff = 'Je gebruikt de gratis versie.';
  static const proSettingsSub =
      'Eenmalige aankoop, geen abonnement. Pro ontgrendelt de noodhacks, herinneringen voor vervanging en onbeperkt documenten in de kluis.';
  static const proSettingsMore = 'Bekijk wat Pro is';

  static String vaultFreeCounter(int n) => '$n van 3 gratis documenten';
  static const vaultFreeCounterHint = 'Met Pro kun je er onbeperkt bewaren.';

  static const hackProHint = 'Dit stappenplan hoort bij Pro. Twee proefhacks en alle mythes zijn gratis.';
  static const hackProOnly = 'Details met Pro';

  static const remindSwitch = 'Herinner mij vóór het verloopt';
  static const remindSwitchSub = 'Een melding op je toestel voordat dit verloopt of vervangen moet worden.';
  static const remindProOnly = 'Herinneringen zijn een Pro-functie';
  static const remindProOnlySub =
      'Je overzicht en datums blijven werken. Met Pro plannen we de meldingen voor je.';
  static const dashRemindHint = 'Wil je een herinnering? Dat kan met Pro.';

  static String wikiSituations(int n) => n == 1 ? '1 situatie' : '$n situaties';

  static const legalTitle = 'Juridisch';
  static const legalPrivacy = 'Privacybeleid';
  static const legalTerms = 'Gebruiksvoorwaarden';
  static const legalLicenses = 'Open-sourcelicenties';
  static const legalOpensInBrowser = 'Opent in je browser. Dit is de enige keer dat de app internet gebruikt, en alleen als jij tikt.';

  // ---- Delen met een ander toestel (QR) ----
  static const deelTitle = 'Deel met een ander toestel';
  static const deelSub = 'Rechtstreeks via wifi, zonder server.';
  static const scanTitle = 'Scan een noodplan';
  static const scanSub = 'Neem een plan over van een ander toestel.';
  static const sharedWithMe = 'Gedeeld met mij';
  static String sharedFrom(String name) => 'van $name';
  static const sharedReadOnly = 'Alleen-lezen. Scan opnieuw om het bij te werken.';
  static String sharedVersionLine(int v, String date) => 'Versie $v, $date';
  static const sharedRemove = 'Verwijderen';
  static const sharedRemoveConfirm = 'Dit gedeelde plan van dit toestel verwijderen? Het plan bij de afzender blijft bestaan.';
  static const sharedUseAsOwn = 'Gebruik als mijn eigen plan';
  static const sharedUseAsOwnDone = 'Het plan is nu jouw eigen plan. Je kunt het aanpassen.';
  static const sharedOwnExists = 'Je hebt al een eigen plan. Daarom kan dit plan niet als jouw eigen plan worden gebruikt.';
  static const sharedCallHint = 'Tik op een nummer om de telefoon-app te openen. Er wordt nooit automatisch gebeld.';
  static String deelLast(String date, String device, String what) =>
      'Laatst gedeeld op $date met $device: $what';

  static const deelChooseTitle = 'Wat wil je delen?';
  static const deelYourName = 'Je naam, zichtbaar voor de ontvanger';
  static const deelYourNameHint = 'Bijvoorbeeld Anna';
  static const deelOptPersons = 'Per persoon';
  static const deelOptContacts = 'Contacten';
  static const deelOptPlaces = 'Verzamelplekken';
  static const deelOptAgreements = 'Afspraken';
  static const deelOptHome = 'Thuis';
  static const deelOptPhotos = 'Foto\'s bij Thuis meesturen';
  static const deelOptCare = 'Zorg en medisch';
  static const deelOptCareSub = 'Staat standaard uit. Deel dit alleen als de ontvanger dit echt nodig heeft.';
  static const deelDocsTitle = 'Documenten uit de kluis';
  static const deelDocsNone = 'Geen gekozen';
  static String deelDocsCount(int n) => n == 1 ? '1 document gekozen' : '$n documenten gekozen';
  static const deelDocsChoose = 'Kies documenten';
  static const deelDocsWarn =
      'Een kopie van een identiteitsbewijs op meer toestellen vergroot het risico. Je kunt dit niet terughalen. Deel alleen met toestemming van de persoon om wie het gaat.';
  static const deelDocsDone = 'Klaar';
  static const deelStart = 'Toon QR-code';
  static const deelNothingChosen = 'Kies eerst iets om te delen.';
  static const deelLimits = 'Limieten: maximaal 50 documenten, 25 MB per pagina en 150 MB in totaal.';
  static const deelNoPlanYet = 'Je hebt nog geen noodplan. Je kunt alleen documenten delen.';

  static const deelAuthReason = 'Bevestig dat jij dit bent om je noodplan te delen.';
  static const deelAuthFailed = 'Bevestigen is niet gelukt. Er is niets gedeeld.';
  static const deelAuthUnavailable =
      'Dit toestel heeft geen schermvergrendeling of biometrie ingesteld. Stel die eerst in om te kunnen delen.';
  static const deelVaultLocked = 'Ontgrendel eerst je kluis om documenten te delen.';

  static const deelQrTitle = 'Scan met het andere toestel';
  static const deelQrHelp =
      'Zet beide toestellen op hetzelfde wifi, of zet bij één toestel de hotspot aan en verbind het andere daarmee.';
  static String deelCountdown(String t) => 'Nog $t';
  static const deelCancel = 'Annuleren';
  static const deelNoNetwork =
      'Geen lokaal netwerk gevonden. Maak verbinding met wifi of zet een hotspot aan en probeer het opnieuw.';
  static const deelBackgrounded = 'De sessie is gestopt omdat de app naar de achtergrond ging. Begin opnieuw.';
  static const deelExpired = 'De code is verlopen. Begin opnieuw.';
  static const deelWaiting = 'Wachten op het andere toestel';
  static const deelQrLabel = 'QR-code om het andere toestel te laten verbinden';

  static const deelVerifyTitle = 'Komt deze code overeen?';
  static String deelVerifyBody(String device) =>
      '$device wil verbinden. Controleer dat dezelfde code op dat toestel staat.';
  static const deelVerifyBodyReceiver = 'Controleer dat dezelfde code op het andere toestel staat. Wacht tot daar op Toestaan is getikt.';
  static const deelAllow = 'Toestaan';
  static const deelDeny = 'Niet toestaan';
  static const deelSending = 'Versturen';
  static const deelReceiving = 'Ontvangen';
  static String deelProgress(String done, String total) => '$done van $total';
  static const deelDone = 'Klaar. Alles is overgedragen.';
  static const deelDenied = 'Het andere toestel is niet toegestaan. Er is niets gedeeld.';
  static const deelAborted = 'De overdracht is gestopt.';
  static const deelFailedTimeout = 'Verbinden of wachten duurde te lang. Controleer het wifi en probeer opnieuw.';
  static const deelFailedHandshake = 'Het andere toestel kon niet worden vertrouwd. Er is niets gedeeld. Begin opnieuw.';
  static const deelFailedBad = 'Er kwamen gegevens binnen die niet kloppen. Er is niets opgeslagen.';
  static const deelFailedTooLarge = 'Wat werd aangeboden is groter dan toegestaan. Er is niets opgeslagen.';
  static const deelFailedHash = 'Een bestand kwam beschadigd aan. Dat document is niet opgeslagen.';
  static const deelFailedUnsupported = 'Dit plan komt uit een nieuwere versie van de app. Werk de app bij en probeer opnieuw.';
  static const deelFailedClosed = 'De verbinding is verbroken. Er is niets (meer) opgeslagen van het lopende document.';

  static const scanHelpTitle = 'Scan de QR-code';
  static const scanHelp = 'Richt de camera op de QR-code op het andere toestel.';
  static const scanInvalid = 'Dit is geen geldige code voor NL-Noodpakket.';
  static const scanCameraDenied = 'Zonder cameratoestemming kun je geen code scannen. Je kunt dit aanzetten in de instellingen van je toestel.';
  static const scanConnecting = 'Verbinden';
  static const scanConnectFail =
      'Verbinden is niet gelukt. Staan beide toestellen op hetzelfde wifi of dezelfde hotspot? Sommige gastennetwerken laten dit niet toe.';

  static const previewTitle = 'Dit wordt aangeboden';
  static String previewFrom(String name) => 'Van $name';
  static String previewPlan(int v, String date) => 'Noodplan, versie $v van $date';
  static const previewNoPlan = 'Geen noodplan';
  static const previewSections = 'Onderdelen';
  static const secPersons = 'Personen';
  static const secContacts = 'Contacten';
  static const secPlaces = 'Verzamelplekken';
  static const secAgreements = 'Afspraken';
  static const secHome = 'Thuis';
  static const secCare = 'Zorg en medisch';
  static const previewDocs = 'Documenten';
  static const previewPickDocs = 'Kies welke documenten je overneemt. Standaard staat niets aan.';
  static const previewTake = 'Overnemen';
  static const previewSaveAs = 'Opslaan als';
  static const previewSaveShared = 'Gedeeld plan (alleen-lezen)';
  static const previewSaveOwn = 'Mijn eigen plan';
  static const previewHaveOwn = 'Je hebt al een eigen plan. Dat blijft ongemoeid; het wordt nooit overschreven of samengevoegd.';
  static const previewNoVault = 'Om documenten op te slaan moet je eerst je eigen kluis instellen. Zonder kluis worden de documenten overgeslagen.';
  static const previewVaultLocked = 'Ontgrendel je kluis om documenten te kunnen opslaan.';
  static const previewSetUpVault = 'Kluis instellen';
  static const previewUnlockVault = 'Kluis ontgrendelen';
  static const previewUpToDate = 'Je hebt al de nieuwste versie van dit plan.';
  static String previewNewVersion(int v, String date) => 'Nieuwe versie $v van $date. Bijwerken?';
  static String previewChanged(String list) => 'Gewijzigd: $list';
  static const previewUpdate = 'Bijwerken';
  static const previewNothingChosen = 'Kies minstens iets om over te nemen.';
  static String previewDocLine(String type, String size) => '$type, $size';
  static const previewWarnNoDelete = 'Er wordt niets verwijderd. Documenten die de afzender niet meer heeft, blijven bij jou staan.';
  static String doneStored(String what) => 'Opgeslagen: $what.';
  static const whatPlan = 'plan';
  static String whatPlanDocs(int n) => n == 1 ? 'plan en 1 document' : 'plan en $n documenten';
  static String whatDocs(int n) => n == 1 ? '1 document' : '$n documenten';
  static const deelLocalNetworkNote =
      'Delen gebeurt rechtstreeks tussen twee toestellen op hetzelfde lokale netwerk, zonder server. De QR-code bevat geen gegevens.';
}
