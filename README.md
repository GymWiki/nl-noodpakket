# NL-Noodpakket

Rustige, offline-first app waarmee Nederlandse huishoudens stap voor stap een persoonlijk noodpakket samenstellen en onderhouden. Gebaseerd op de campagne [denkvooruit.nl](https://www.denkvooruit.nl/). **De app is niet van de overheid** en dat staat zichtbaar in de app (Info, Onboarding, Instellingen).

- Android `applicationId` / iOS bundle ID: `com.mycompany.mijnnoodpakket`
- Versie: `1.0.13+13` (vorige release: 1.0.12, versionCode 12), zie `pubspec.yaml`
- Geen backend, account, analytics of tracking. Alle data blijft op het toestel.

## Stack en keuzes

| Onderdeel | Keuze |
|---|---|
| UI | Flutter, Material 3, alleen nl-NL |
| State | Riverpod |
| Navigatie | go_router (bottom navigation via `StatefulShellRoute`) |
| Opslag | **Drift (SQLite)**, zie onder |
| Notificaties | flutter_local_notifications + timezone (Europe/Amsterdam) |
| Back-up | JSON via share_plus (export) en file_picker (import) |

**Waarom Drift en niet Isar?** Isar wordt niet meer actief onderhouden. Drift is actief onderhouden, heeft getypeerde queries, reactieve streams (`watch()`) en een uitgewerkt migratiemodel (`schemaVersion` + `onUpgrade`), en SQLite is voor dit kleine, relationele datamodel ruim voldoende. Migraties staan vanaf dag 1 klaar in `lib/data/db/database.dart` (nu `schemaVersion = 1`).

### Versiebeperkingen (bewust gepind)

- `drift`/`drift_dev` `2.30.x` + `sqlite3_flutter_libs 0.5.x`: nieuwere drift-versies botsen met de `meta`-versie van de Flutter SDK en gebruiken sqlite3 v3 (andere native-setup).
- `image 4.8.0` (`dependency_overrides`): `image 4.11` past niet bij `archive 4.0.9` (dat vastzit via `flutter_launcher_icons`) en breekt `flutter test` zodra `pdf`/`printing` erbij komen.
- `build_runner 2.10.4`: nieuwere versies falen met "dart compile does not support build hooks" zodra de dependency-boom pakketten met build hooks bevat.

## Mappenstructuur

```
lib/
  main.dart, app.dart        opstart, router, thema, herplannen van herinneringen
  core/                      l10n/strings.dart, thema, providers, notificatieservice, formatters
  domain/                    modellen, hoeveelheidsberekening, houdbaarheidslogica (puur Dart)
  data/                      db (Drift), seed (standaardlijst), repositories
  features/
    checklist/ items/ expiry/ settings/ info/ onboarding/
test/                        unit-, repository- en widget-tests
```

Domeinmodellen (`lib/domain`) zijn los van de database-modellen (`lib/data/db`); de repositories assembleren `Item`s uit seed-data + opgeslagen staat + huishouden.

### Datamodel

- `ItemRows`: één rij per aangepast standaarditem (afgevinkt, verborgen, hoeveelheden, datums, notities) en per eigen item (`isCustom`, naam, categorie, eenheid, uitleg). Standaarditems zonder rij hebben de standaardstaat, dus verborgen/gewijzigd is altijd herstelbaar en de seed wordt nooit "gewist".
- `SettingRows`: sleutel/waarde (huishouden, herinneringen, thema, onboarding).
- Seed: `lib/data/seed/seed_items.dart`. Per item: categorie, uitleg, houdbaarheidsadvies, eenheid en per-persoon-factoren.

### Hoeveelheden

`aanbevolen = base + Σ(factor × aantal)` per persoonstype, naar boven afgerond, minimaal 1 (`lib/domain/quantity.dart`). Items voor baby's, kinderen, huisdieren en medicatie verschijnen alleen als het huishouden die heeft. De gebruiker kan de doelhoeveelheid per item overschrijven.

Richtlijnen uit de seed, gecontroleerd tegen denkvooruit.nl (gelezen 2026-11-10): 72 uur overbruggen, 3 liter water p.p.p.d., contant geld €70 per volwassene en €30 per kind, controle elk half jaar, buiten koken, waterdichte tas, huisdieren 50 ml water per kg per dag. Jodiumtabletten stonden op de gelezen pagina's niet vermeld; het item blijft er als puur informatief item in (neem ze alleen op instructie van de overheid). Controleer de PDF's op denkvooruit.nl nog eens voor je publiceert.

### Herinneringen

- Per item: houdbaarheidsdatum of controle-interval (laatste controle + maanden).
- Standaard 30 dagen vooraf (instelbaar), 09:00 lokale tijd; optioneel een halfjaarlijkse "check je noodpakket"-melding.
- Bij elke app-start en elke relevante wijziging worden alle meldingen opnieuw gepland (`NoodpakketApp._reschedule`); daarnaast herplant de boot-receiver na een herstart.
- Inexact gepland: **geen** exact-alarm-permissie nodig.
- Toestemming wordt pas gevraagd bij het eerste item met datum/interval of bij het aanzetten van de halfjaarlijkse herinnering, niet bij de eerste start.

## Bouwen en testen

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # alleen na wijzigingen in database.dart
flutter analyze
flutter test
flutter run
```

## Release

1. **Versie**: verhoog `version: X.Y.Z+N` in `pubspec.yaml`; het buildnummer `N` moet hoger zijn dan wat live staat (nu 13 > 12).
2. **Android-signing**: maak `android/key.properties` (staat in `.gitignore`):

   ```
   storeFile=../upload-keystore.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

   Gebruik de upload-sleutel die bij de bestaande Play-listing hoort. Zonder dit bestand wordt met de debug-sleutel getekend (alleen voor lokaal testen, Play weigert dat).
3. `flutter build appbundle --release` (Android), `flutter build ipa --release` (iOS, op een Mac met de juiste provisioning voor `com.mycompany.mijnnoodpakket`).
4. **Store-listing**: de bestaande screenshots (map `NL_Noodpakket 1.0/Store`) tonen de oude app en moeten worden vervangen. Werk ook beschrijving, privacy-/datasafety-formulier (geen data verzameld, geen tracking) en de "niet van de overheid"-vermelding bij.

## Icoon en splash

`assets/icon` en `assets/splash` bevatten placeholders. Vervang ze (zie `assets/README.md`) en draai `dart run flutter_launcher_icons` en `dart run flutter_native_splash:create`.

## Meer talen

Alle UI-tekst staat in `lib/core/l10n/strings.dart` (klasse `S`); widgets bevatten geen eigen tekst. De seed-teksten staan in `seed_items.dart`. Voor een tweede taal: migreer `S` naar ARB/gen-l10n en verplaats de seed-teksten naar sleutels.

## Toegankelijkheid

Grote tikdoelen (+ stappers van 56 dp), `Semantics`-labels voor checklist, voortgang, huishoudensteppers en datums, respect voor systeemtekstgrootte (geen vaste hoogtes), contrastrijk thema; alarmkleur alleen voor verlopen items. Test voor release met TalkBack/VoiceOver en tekstgrootte 200%.

## Noodgevallen-wiki

Offline tabblad "Noodgevallen" met per noodsituatie een rustig stappenplan.

- **Inhoud**: `assets/wiki/noodgevallen.json` (schemaversie 1). Per noodgeval: `id`, `categorie`, `titel`, `icoon`, `trefwoorden`, `intro`, `stappenNu`, `stappenDaarna`, `bel112Als`, `voorbereidenItemIds` (ids uit de seed-checklist), `contacten`, `bronnen` en `lastReviewed`. Daarnaast `eersteUur` (de Eerste-uur kaart) en `categories`. De UI-teksten staan in `lib/core/l10n/strings.dart`; de wiki-inhoud staat alleen in de JSON.
- **Validatie**: `test/wiki_data_test.dart` controleert unieke id's, minstens 1 stap, verplichte velden, https-bronnen, nummers en dat elk `voorbereidenItemId` in de seed bestaat. Draai de test na elke wijziging aan de JSON.
- **Opslag**: alleen favorieten en stapvoortgang (sleutel/waarde in `SettingRows`, komt dus mee in de JSON-back-up). Geen netwerk, geen eigen tabel.
- **Schermen**: overzicht (zoeken, Bel 112, Eerste-uur kaart, favorieten, categorieën), detail, stap-voor-stap (scherm blijft aan via `wakelock_plus`, schakelbaar naar lijst) en een "Handig bij"-regel in het itemdetail van de checklist.
- **Bel 112** opent alleen de telefoon-app (`tel:`), er wordt nooit automatisch gebeld.
- **Meterkastkaart** (PDF, afdrukken/opslaan/delen via het systeem-printmenu): Eerste-uur kaart + 5 stappenplannen (`meterkastPlanIds` in `wiki_pdf.dart`). Gebruikt Roboto uit `assets/fonts` (Apache 2.0).

### Inhoudelijke werkwijze

Elk stappenplan is gecontroleerd tegen officiële bronnen (denkvooruit.nl, KNMI, RIVM, rijksoverheid.nl, NVWA, brandweer.nl, Liander/Enexis, nl-alert.nl) op 2026-11-10. **Stappen zonder officiële bron zijn weggelaten**, ook als ze algemeen bekend zijn. Er staan alleen nummers in die letterlijk op een officiële pagina staan (0800-9009, 0900-0904, 0900-8844, 0800-7000, 0800-1508).

Bewust niet opgenomen omdat er geen officieel advies kon worden gevonden of de bron niet leesbaar was: reanimatie (borstcompressies), ernstige bloeding, verslikking, evacuatie als apart stappenplan, gifwolk als apart plan (staat nu onder "Sirene of NL-Alert"), zonnestorm en afgebroken stroomkabels. Vul die aan zodra je de officiële tekst (Rode Kruis, Reanimatieraad, Hartstichting) zelf hebt gecontroleerd.

## Mijn noodplan

Begeleide flow (7 onderdelen + samenvatting) waarmee een huishouden afspraken vastlegt, plus een deelbaar document. Alles lokaal; er verlaat niets het toestel tot de gebruiker zelf deelt.

- **Onderdelen**: Huishouden, Contacten, Verzamelplekken, Afspraken, Thuis (met optionele foto's), Zorg en bijzonderheden (optioneel), Buren en hulp. Overslaan en "Later afmaken" kunnen altijd; alles wordt automatisch opgeslagen (met korte vertraging en nog een keer bij het verlaten van een scherm).
- **Voortgang** (`plan_progress.dart`): per onderdeel leeg / gedeeltelijk / klaar / overgeslagen. Overgeslagen telt als afgehandeld. "Klaar" betekent: huishouden = alle leden hebben een naam; contacten = een contact buiten de regio én minstens één noodcontact; verzamelplekken = alle drie ingevuld; afspraken = de relevante afspraken (kinderen, huisdieren en hulpbehoevenden alleen als ze in het plan voorkomen); thuis = de kernlocaties (noodpakket, meterkast, water, gas, stroom, vluchtroutes); buren = 2 van 3 velden.
- **Ingangen**: kaart bovenaan het tabblad Noodgevallen, wegklikbare banner in de checklist (zolang er geen plan is), blok "Jouw afspraken" in de wiki-detailschermen (koppelingen in `plan_links.dart`) en de locatie van het noodpakket bovenaan de checklist.
- **Samen plannen**: 9 gesprekskaarten met de vragen letterlijk uit de noodplan- en praat-erover-pagina's van denkvooruit.nl; het antwoord wordt direct in het plan opgeslagen.
- **Document**: A4-pdf (Roboto uit `assets/fonts`), korte tekstsamenvatting, afdrukken en een app-bestand (`.json`, `app: nl-noodpakket-plan`, `schemaVersion: 1`). Per onderdeel in/uit te schakelen; zorg en foto's staan standaard uit; foto's gaan alleen mee in het app-bestand. Importeren toont eerst een voorbeeld en kiest samenvoegen (eigen invulling blijft) of vervangen; ongeldige en nieuwere bestanden worden geweigerd. Het plan zit ook in de algemene back-up (zonder foto's) en wordt gewist door "Alles resetten".
- **Versiebeheer**: "laatst gewijzigd", "laatst gedeeld" en "laatst gecontroleerd"; na een wijziging sinds het delen verschijnt "Opnieuw delen?". De Meterkastkaart in de wiki gebruikt het plan als dat er is.
- **Herinnering**: "Klopt je noodplan nog?" 6 maanden na de laatste bevestiging (knop "Alles klopt nog") of wijziging, 10:00. De meldingstoestemming wordt pas gevraagd als de herinnering wordt aangezet (overzicht of Instellingen).
- **Database**: schemaVersion 2 met zes nieuwe tabellen (`PlanMembers`, `PlanContacts`, `PlanPlaces`, `PlanAgreements`, `PlanLocations`, `PlanMeta`); migratie en migratietest staan in `database.dart` en `test/plan_domain_test.dart`.
- **Toestemmingen**: contacten (`READ_CONTACTS` op Android) worden pas gevraagd bij "Kies uit contacten"; handmatig invullen werkt altijd. Camera/galerij pas bij "Foto toevoegen". Vul voor de Play-listing de verklaring voor de contactenpermissie in (alleen-lezen, op verzoek van de gebruiker, nergens opgeslagen of verstuurd).
- **Bronnen**: `denkvooruit.nl/bereid-je-voor/noodplan` en `/praat-erover` (gelezen op 2026-11-10). Het uitgebreide noodplan en de noodkaart (PDF's) waren niet leesbaar.

## Documentenkluis

Plek voor kopieën van belangrijke documenten (paspoort, polissen, medische gegevens, ...), versleuteld op het toestel en ontgrendeld met biometrie of een kluis-PIN. 100% lokaal: geen cloud, account, analytics of crash-logging. In de app staat zichtbaar: *"Dit zijn eigen kopieën. De kluis is geen officieel identiteitsbewijs, geen DigiD en vervangt het origineel niet."*

### Cryptografie en sleutelbeheer (`lib/features/kluis/crypto`)

- **Envelope-encryptie**: één willekeurige datasleutel (DK, 256 bit) versleutelt elk bestand en de metadata met **AES-256-GCM** (pakket `cryptography`, uniek willekeurig 96-bit nonce per bestand, tag 128 bit). De bestands-id zit als AAD in de authenticatie, zodat bestanden niet kunnen worden omgewisseld. Er is geen eigen crypto geschreven.
- **DK wordt drie keer onafhankelijk gewrapt** (`vault.json`): (a) door een sleutel uit de kluis-PIN via **Argon2id** (19 MiB, 2 iteraties, 1 lane = OWASP-minimum, parameters staan in de header), (b) door de **herstelcode** (160 bit, HKDF-SHA256), (c) door een **hardware-sleutel met biometrie**: Android Keystore (`AndroidOptions.biometric`, `requireBiometricsPerOperation`, alleen sterke biometrie) en iOS Keychain (`biometryCurrentSet`), via `flutter_secure_storage`.
- **Biometrie gewijzigd** (sleutel ongeldig): de PIN wordt gevraagd en de DK wordt opnieuw aan een nieuwe hardwaresleutel gewrapt. Biometrie uit of niet beschikbaar: alleen PIN.
- **Metadata** (titels, types, personen, notities, verloopdatums) staat als één versleutelde blob (`meta`); miniaturen zijn aparte versleutelde bestanden. Bestandsnamen zijn UUID's zonder extensie. Schrijven gaat atomair (tmp + rename), bij ontgrendelen worden verweesde bestanden opgeruimd.
- **PIN**: minimaal 6 cijfers (maximaal 16), geen makkelijke patronen (111111, 123456, 121212, ...). **Wachttijd** na foute pogingen: 5 fouten = 30 s, daarna 1 min, 5 min, 15 min, 1 uur.
- **Sleutelmateriaal in het geheugen** wordt na gebruik met nullen overschreven (`zero`). Dart garandeert dat niet volledig (garbage collector), het is best effort.
- **Back-up** (`.noodkluis`, `vault_backup.dart`): wachtwoord (min. 10 tekens) -> Argon2id (32 MiB, 3 iteraties) -> AES-256-GCM per record, met header en volgnummer als AAD en een eindrecord met het aantal. Omwisselen, weglaten, afkappen, een verkeerd wachtwoord en een te nieuw bestand worden gedetecteerd; een mislukte import rolt alle geschreven bestanden terug. Importeren: eerst voorbeeld, dan samenvoegen of vervangen.

### Keuze van pakketten (gecontroleerd op 2026-11-10)

| Doel | Gekozen | Waarom / afgevallen |
|---|---|---|
| Crypto | `cryptography` 2.9 | Gevestigd, pure Dart, AES-GCM, Argon2id, HKDF. Argon2id draait in een isolate. |
| Sleutel + biometrie | `flutter_secure_storage` 11.2 (+ `local_auth` voor beschikbaarheid) | Actief onderhouden (sept. 2026), ondersteunt Keystore per-operatie biometrie en Keychain `biometryCurrentSet`. `biometric_storage` is afgevallen: v5 mist een Android-namespace (bouwt niet met AGP 8) en v6 vereist een nieuwere Flutter. |
| Scannen | `cunning_document_scanner` 3.1 | ML Kit (Android) en VisionKit (iOS) met randdetectie en bijsnijden. De plugin schrijft scans naar app-specifieke opslag; de app leest ze en overschrijft + verwijdert ze direct, en roept `cleanCache()` aan. |
| Afbeeldingen | `image` (4.8.0, gepind) + `image_picker`, `file_picker` | Verkleinen naar max. 2400 px, JPEG-kwaliteit 85 (leesbaarheid gaat voor grootte); miniatuur 320 px. |
| Pdf-weergave | `printing` (`Printing.raster`) | `pdfrx` (in-memory) is afgevallen: het downloaden van PDFium tijdens de build lukte niet. Op Android schrijft `printing` de pdf heel even naar een cachebestand en verwijdert het direct na het openen (zie "niet gedekt"). |
| Schermbeveiliging | eigen native code (`MainActivity.kt`, `AppDelegate.swift`) | `screen_protector` bouwt niet (JVM-target-conflict). |
| Watermerk | `dart:ui` (Canvas) | Diagonale, herhaalde tekst met Nederlandse tekens; resultaat wordt JPEG. |

`dependency_overrides` bevat alleen `image: 4.8.0` (zie hierboven).

### Veiligheidsmaatregelen op het toestel

- **Geen leesbaar bestand op schijf**: de viewer ontsleutelt in het geheugen. Delen schrijft onvermijdelijk een tijdelijk bestand in een app-privémap (`vault_tmp`), dat direct na het delen wordt overschreven en verwijderd (als Android niet meldt wat er met het bestand gebeurt: na 90 seconden). Bij elke start worden restanten opgeruimd, ook tijdelijke bestanden van een onderbroken actie.
- **Schermbeveiliging**: Android `FLAG_SECURE` op alle kluisschermen (screenshots, schermopname en recents-preview geblokkeerd); iOS toont een dekkende laag in de app-switcher en bij schermopname.
- **Back-ups uitsluiten**: Android `dataExtractionRules` + `fullBackupContent` sluiten `vault/` en `vault_tmp/` uit van cloud-back-up en apparaatoverdracht; iOS zet `isExcludedFromBackup` op de kluismap. De Keychain-sleutel heeft toegangsniveau "passcode, alleen dit toestel". De eigen versleutelde export is de enige back-up.
- **Automatisch vergrendelen**: direct (standaard) / 1 min / 5 min na naar de achtergrond gaan, en na 5 minuten inactiviteit in de app. Camera, bestandskiezer en deelmenu worden als "externe actie" behandeld, zodat een lopende actie niet verloren gaat.
- **Meldingen** zijn neutraal ("Een document in je kluis verloopt binnenkort."), zonder titel, naam of nummer. Buiten de kluis staan alleen: *of* er documenten zijn en de anonieme herinneringstijden. De notificatietoestemming wordt pas gevraagd bij het eerste document met een verloopdatum.
- **Geen documentnummers**: de app vraagt er nergens om; voor documenten alleen titel, type, persoon, verloopdatum en notitie.
- Geen klembord, geen logs of analytics met documentinhoud.

### Bedreigingsmodel

**Gedekt**
- *Gevonden of gestolen toestel*: documenten, miniaturen en metadata zijn versleuteld; de sleutel zit achter PIN (Argon2id) of een hardware-biometrische sleutel. Oplopende wachttijd tegen raden via de app.
- *Malware zonder root*: de app-sandbox beschermt de bestanden; er staat geen leesbare inhoud op schijf; screenshots en schermopname worden geblokkeerd.
- *Per ongeluk delen*: expliciete waarschuwing, watermerk met doel en datum voor identiteitsdocumenten, tip om het BSN af te dekken, tijdelijk bestand wordt overschreven.
- *Verloren telefoon / nieuw toestel*: versleutelde back-up + herstelcode.

**Niet gedekt (bewust of onvermijdelijk)**
- Een toestel met root of jailbreak, malware met rootrechten, een gecompromitteerd besturingssysteem of toegankelijkheidsdiensten die het scherm uitlezen (FLAG_SECURE houdt die niet tegen), keyloggers.
- *Offline raden van de PIN* door iemand met een volledige kopie van het bestandssysteem: een PIN van 6 cijfers heeft maar 1 miljoen mogelijkheden. De wachttijd werkt alleen in de app (de teller staat in een gewoon bestand). Gebruik daarom een langere PIN (tot 16 cijfers) en bewaar de herstelcode apart.
- Wie PIN of herstelcode vergeet **en** geen back-up heeft, kan niets herstellen. Dat is bedoeld.
- Geheugen: nullen schrijven is best effort; bij een live geheugendump kan inhoud zichtbaar zijn. Overschrijven van bestanden is op flashgeheugen geen garantie (wear leveling).
- Op Android schrijft `printing` voor pdf-weergave kort een cachebestand (direct ontkoppeld na het openen); HEIC-bestanden die niet te comprimeren zijn blijven origineel en zonder miniatuur bewaard.
- De ontvanger van een gedeeld bestand kan het verder verspreiden.
- *Een zwak back-upwachtwoord* maakt het `.noodkluis`-bestand kwetsbaar voor raden.
- De bestaande (niet-kluis) gegevens van de app, zoals het noodplan, vallen niet onder de kluis.

### Privacylabels

- **Google Play, Data safety**: *"Geen gegevens verzameld of gedeeld"*; alle gegevens blijven op het toestel. Toestemmingen: camera (alleen voor de ingebouwde scanner op toestellen zonder Google Play-services), contacten lezen (alleen bij "Kies uit contacten" in het noodplan), meldingen, biometrie. Verklaar de contactenpermissie in de Play Console.
- **App Store, privacy**: *"Data Not Collected"*. Info.plist-teksten staan er: `NSFaceIDUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSContactsUsageDescription`. Beantwoord de exportvraag over versleuteling (de app gebruikt standaard-AES voor lokale opslag en een eigen bestandsformaat) en overweeg `ITSAppUsesNonExemptEncryption` in te stellen.

### Nog handmatig te testen

Alles hierboven is getest op unit-, widget- en bestandsniveau, maar **niet op een echt toestel**: biometrie (Android Keystore en iOS Keychain/Face ID, inclusief wijzigen van vingerafdrukken), de documentscanner, FLAG_SECURE en de iOS-overlay, pdf-weergave, het deelmenu en de back-uprules. Test op zowel Android als iOS, met en zonder schermvergrendeling.

## Ontwerp ("Rustig helder")

- **Navigatie**: vijf tabs: *Start* (dashboard, standaard), *Pakket* (checklist en "Vervangen" als segment), *Noodgevallen* (wiki en noodhacks), *Mijn plan* (noodplan, gesprekskaarten, documentenkluis) en *Meer* (onderhoud, info, instellingen). Diepe links (`/plan`, `/kluis`, `/checklist?tab=vervangen`, `/wiki/:id`) en meldingsroutes blijven werken.
- **Kleur** (`lib/core/theme.dart`): diep blauw als anker, saliegroen voor "in huis", warm zand als zacht accent; rood alleen voor verlopen. Licht en donker zijn samen ontworpen; tekst haalt WCAG AA (primair 4,5:1 of beter).
- **Vorm en ritme**: grote afgeronde vlakken (20 dp) met een subtiele lijn in plaats van schaduwen, 4/8-dp-ritme, tikdoelen van minimaal 48 dp, ronde afvinkvakjes.
- **Typografie**: één lettertype (Roboto, meegeleverd), grote koppen, 17 sp lopende tekst, schaalt mee met de systeemtekstgrootte.
- **Componenten** (`lib/core/ui.dart`): `SoftCard`, `IconBadge`, `ProgressRing`, `SectionHeader`, `PageTitle`. Alle schermen (ook wizard, kluis en formulieren) erven het thema.
- **Beweging**: korte, rustige overgangen (Android fade-forwards, iOS Cupertino); de voortgangsring animeert niet als "animaties verminderen" aan staat.

## Noodhacks

Praktische tips voor als het noodpakket op of ontoereikend is, binnen het tabblad Noodgevallen (kaarten "Mijn pakket is op" en "Noodhacks"). Overzicht met zoeken en labelfilter, detail met materialen, stappen, waarschuwingen, bron en controledatum, stappenplan (één stap per scherm, waarschuwingen eerst), "Wat heb ik in huis?" (materiaalchips, onthouden op dit toestel), "Mijn pakket is op" (volgorde: water, warmte, hygiëne, eten, hulp zoeken) en een sectie Gevaarlijke mythes.

- **Inhoud**: `assets/wiki/noodhacks.json` (schemaVersion 1): categorieën, vaste materialenlijst en hacks (`label`: veilig / letop / nooit, `materialen`, `stappen`, `waarschuwingen`, `reden` + `alternatiefIds` bij "nooit", `bronnen`, `bronType`, `lastReviewed`, koppelingen naar wiki-noodgevallen en checklist-items). Labels tonen altijd icoon én tekst.
- **Validatie** (`test/hacks_data_test.dart`): unieke id's, minstens 1 stap, materiaal-, checklist- en wiki-id's bestaan, elke "nooit"-hack heeft een reden, een veilig alternatief en hoort bij de mythes, elke hack heeft een https-bron. De test bewaakt ook de kerncijfers (koken 3 minuten, bleek 5% tot 9% en 30 minuten) en dat onbewezen onderwerpen er niet in zitten.
- **Koppelingen**: blok "Als je pakket op is" in de wiki-detailschermen (Stroomstoring, Uitval water, Uitval gas/verwarming, Strenge kou, Overstroming) en "Handige hacks" in het itemdetail van de checklist.

### Wat is gecontroleerd en wat is weggelaten (2026-11-11)

Elke hack is vergeleken met officiële of gezaghebbende bronnen (Denk Vooruit, Voedingscentrum, Brandweer, Vitens, Waternet, CDC, EPA). **Stappen zonder bron zijn weggelaten.** Weggelaten omdat er geen onderbouwing kon worden gevonden: hooikist en thermoskoken, blik au bain-marie, gasslang-advies, regenwater en gesmolten sneeuw, zand-houtskoolfilter, noodtoilet, riool/wc afsluiten, bleek mengen met andere middelen, generator, kaarsenkachel, hete baksteen, thuisbatterij, telefoon-batterijtips, kruik en lagen kleding, de categorie Gezondheid (onderkoeling, ORS, noodverband; het Rode Kruis was niet bereikbaar). Afwijkingen: koken is **3 minuten** (Nederlandse drinkwaterbedrijven; CDC noemt 1 minuut); een barbecue mag **niet op een balkon** (Brandweer); koolmonoxide-slachtoffers zijn volgens de Brandweer gemiddeld **5 tot 10 per jaar**; de koelkastgrens is 7 °C (en 10 °C voor weggooien) volgens het Voedingscentrum.

**Bleek**: alleen een statische instructie (CDC en EPA: onparfumeerde bleek van 5% tot 9%, 2 druppels ≈ 0,1 ml per liter, dubbel bij troebel water, 30 minuten wachten, chloorlucht controleren) met een etiketwaarschuwing en "koken is veiliger". Er is **geen rekenhulpmiddel** gebouwd: er is geen officiële Nederlandse bron voor de concentratie van Nederlandse bleek, en de bronnen geven geen tabel buiten 5% tot 9% (CDC) of 6% en 8,25% (EPA).

## Dashboard "Start"

In één blik: hoe voorbereid is het huishouden en wat is de logische volgende stap. Alles komt uit de bestaande opslag (checklist, huishouden, noodplan, kluis); er is geen aparte database en dus **geen schemawijziging of migratie**. Voorkeuren staan als sleutel/waarde in de bestaande instellingentabel (`dash_later`, `dash_dismissed`, `nlalert_done`, `maint_done`, `maint_anchor`, `maint_remind`, `simpleStart`).

- **Kaartenregistry** (`lib/features/dashboard/dashboard_cards.dart`): elke kaart heeft `id`, `priority`, `isVisible(state)` en `build`. Maximaal zes kaarten naast de smalle noodbalk; wat het laagst staat valt af. Elke kaart leest zijn eigen provider (`dashboard_providers.dart`), afgeleid van de bestaande repositories.
- **Volgorde**: noodbalk (Bel 112 opent alleen de telefoon-app, Eerste uur), Paraatheid, Volgende stap (of "Alles op orde"), Binnenkort vervangen, Nu relevant, Noodplan en Kluis, Onderhoud, Huishouden. Er is geen noodmodus in de app, dus die knop is er niet.
- **Paraatheid** (`domain/readiness.dart`, puur en getest): doel 3 dagen (72 uur). Water: liters gedeeld door 3 liter per persoon per dag. Eten: maaltijden gedeeld door 3 maaltijden per persoon per dag (**eigen afspraak van de app**, Denk Vooruit geeft geen maaltijdenrichtlijn). Het resultaat is het **minimum** van water en eten. Alleen ingevulde hoeveelheden tellen, afgevinkt zonder hoeveelheid telt niet, verlopen items tellen niet mee, het weergegeven getal is afgerond naar beneden en nooit hoger dan 3. Leeg: "Begin met je pakket" (nooit een rode 0). "Hoe is dit berekend?" legt het uit.
- **Prioriteit en dekking per seed-item** (`seed_items.dart`): *kritiek* = water, eten, medicatie, radio, zaklamp, powerbank, babyvoeding, luiers; *belangrijk* = onder meer huisdiervoer, blikopener, kooktoestel, batterijen, kabels, telefoonnummers, dekens, warme kleding, EHBO, pijnstillers, toiletpapier, doekjes, zeep, contant geld, ID-kopieën, recepten, tandenborstel, hoofdlamp, rook- en CO-melder; de rest *aanvullend*. Alleen water (`coverage: water`, liters) en eten (`coverage: food`, maaltijden) tellen mee voor dagen; de compleetheid weegt 3/2/1.
- **Volgende stap** (`domain/suggestions.dart`): vaste volgorde: huishouden onvolledig, NL-Alert controleren, water, verlopen of bijna verlopen, noodplan (nieuw, afmaken of langer dan 6 maanden niet bekeken), kluis (leeg of ID-kopieën open), overige ontbrekende items op prioriteit, onderhoud. Maximaal 3 op het dashboard, "Toon alles" toont de rest. "Later" verbergt 7 dagen, "Niet relevant" blijft verborgen tot "Verborgen suggesties herstellen" in Instellingen.
- **Nu relevant** (`domain/seasonal.dart`): alleen wat een bron onderbouwt. De week voor het NL-Alert-testbericht (eerste maandag van juni en december, rond 12.00 uur, nl-alert.nl) en de wintermaanden december tot en met februari (Brandweer: CO-melder en veilig stoken in de wintermaanden) met links naar de wiki-stappenplannen *CO-vergiftiging* en *Kou en gladheid*. Voor hitte, storm en hoogwater noemt geen officiële bron een kalenderperiode (KNMI-codes hangen aan het weer), dus daar is bewust geen datumkaart voor.
- **NL-Alert controleren**: de uitleg bevat alleen algemene feiten van nl-alert.nl (gratis, geen aanmelding, toestel aan en bereik, halfjaarlijkse test) en een link. **Er staan bewust geen menupaden per telefoonmerk in**: die verschillen per toestel en zijn niet bevestigd.
- **Onderhoud** (`domain/maintenance.dart`): rookmelder (elke maand, Brandweer), pakketcontrole (elk half jaar, Denk Vooruit), powerbank (elk half jaar) en batterijen (elk jaar); die laatste twee zijn **eigen voorstellen van de app**, geen officieel advies. "Gedaan" zet de volgende datum; nieuwe gebruikers krijgen pas na het eerste interval een openstaande taak. Herinneringen staan standaard uit; toestemming voor meldingen wordt pas gevraagd als je er zelf een aanzet. Meldingstekst is neutraal.
- **Eenvoudige start** (Instellingen, standaard uit): vier grote knoppen: Pakket, Noodgevallen, Mijn plan, Bel 112.
- **Toegankelijkheid**: getest op 200% tekstgrootte zonder overflow, Semantics-labels op de noodbalk, ring en kaarten, tikdoelen van 48 dp, de navigatiebalk begrenst zijn eigen tekstschaal op 130%.
- **Tests**: `test/dashboard_domain_test.dart` (paraatheid, suggesties, seizoen, onderhoud, voorkeuren), `test/dashboard_widget_test.dart` (volledige data, leeg, één kaart, alles op orde, 200% tekst, Semantics, Eenvoudige start, navigatie en tabs, diepe links).

## NL-Noodpakket Pro (eenmalig, geen abonnement)

Eén niet-verbruikbare aankoop (`pro_unlock`), geen account. De prijs komt altijd uit `ProductDetails` van de store en staat nergens in de code (een test bewaakt dat).

**Pro ontgrendelt drie dingen** (`lib/features/pro/pro_models.dart`, `ProCatalog` is de enige plek die dat bepaalt):
1. **Noodhacks**: de details (materialen, stappen, waarschuwingen, stappenplan) en de details uit "Wat heb ik in huis?". Overzicht, titels, categorieën, labels, zoeken, alle *Gevaarlijke mythes* en twee proefhacks (`"freePreview": true` in `noodhacks.json`: *Water koken* en *Eten in koelkast en vriezer bij stroomuitval*, dat laatste is onze "voedsel bewaren zonder koeling") blijven gratis. Een Pro-hack zonder Pro opent de paywall (niet blokkerend); een directe link toont alleen titel, label en een uitnodiging.
2. **Vervangherinneringen**: per item met houdbaarheidsdatum de schakelaar "Herinner mij vóór het verloopt" (keuze in `remind_items`). Zonder Pro opent aanzetten de paywall en wordt niets opgeslagen. Met Pro vraagt de app pas bij het aanzetten om meldingstoestemming. Verlies van Pro annuleert alleen deze meldingen; de keuze blijft bewaard. Noodplan-, onderhouds-, kluisverloop- en halfjaarlijkse pakketmeldingen staan los van Pro.
3. **Onbeperkt documenten in de kluis** (`vaultFreeLimit = 3`, gerekend in documenten). Alleen "Document toevoegen" bij de 4e is gegate. Bekijken, delen, exporteren, importeren (back-up terugzetten) en verwijderen nooit; bij verlies van Pro blijft alles staan. De teller "n van 3 gratis documenten" is rustig, zonder alarmkleur.

**Altijd gratis**: checklist, eigen items, houdbaarheidsoverzicht en dashboardkaart, wiki met alle stappenplannen en Eerste-uur kaart, noodplan (delen, back-up, export), kluis tot 3 documenten met alle kluisfuncties, overige herinneringen.

**Techniek**: `PurchaseService` (mockbaar; `StorePurchaseService` gebruikt `in_app_purchase`), `Entitlement` (lokale cache in de instellingentabel, werkt offline). Aankopen worden bevestigd (`completePurchase`). Het recht wordt pas ingetrokken als de store op **twee verschillende dagen** bereikbaar was en de aankoop niet meer terugkwam (terugbetaling); een trage of mislukte controle haalt niets weg. Een stille controle bij het opstarten gebeurt alleen op Android; op iOS is "Aankoop herstellen" altijd een eigen keuze. Pro-poorten bestaan alleen op de plekken in `test/pro_protection_test.dart`; die test bewaakt dat wiki, noodplan, checklist, houdbaarheid en alle kluisfuncties behalve toevoegen van een 4e document nooit een poort krijgen.

**Bestaande gebruikers**: de nieuwe app (herbouw) heeft nergens een eerdere Pro-regeling; houdbaarheidsmeldingen waren hier voor iedereen aan. Wat de live-app uit de Play Store/App Store deed, is vanuit deze repo niet betrouwbaar vast te stellen (de oude projectmap is bewust niet geopend, en er is geen oude data of vlag in deze code). Er is daarom **geen `legacyReminders`-recht gebouwd**. Opties: (a) laat het zo en communiceer dat herinneringen Pro zijn; (b) als de live-app al houdbaarheidsmeldingen had, voeg dan voor die installaties een eenmalige migratie toe die `remind_items` vult en een `legacy_reminders`-vlag zet, zodra we weten hoe de oude app zijn data bewaart.

**Controle van de actuele regels** (2026-11-11, officiële documentatie): Google Play: een eenmalige aankoop moet binnen 3 dagen worden bevestigd, anders volgt automatisch terugbetaling; wacht bij "pending" met toekennen tot de status gekocht is (de app doet dat); de pagina geeft geen apart herstelverhaal, alleen opnieuw opvragen van aankopen. App Store (3.1.1): digitale ontgrendeling via in-app aankoop en een herstelmogelijkheid; Family Sharing komt niet in de richtlijnen voor, dat stel je in App Store Connect in. Android 13+: `POST_NOTIFICATIONS` is een runtime-toestemming die het best in context wordt gevraagd; de app vraagt hem alleen bij het aanzetten van een herinnering. Niet apart nagelopen: de nieuwe "one-time products"-indeling in de Play Console en of `in_app_purchase_android 0.5.0` daar iets van merkt; test dat bij de eerste echte aankoop.

### Handmatig door jou
- Product `pro_unlock` (niet-verbruikbaar) aanmaken of aanpassen in Google Play Console en App Store Connect, prijs €3,99, Family Sharing waar gewenst. Test met een licentietester en een sandbox-account.
- Store-beschrijving: "Checklist, alle noodgevallen-stappenplannen, noodplan en noodmodus blijven gratis, en je documentenkluis tot 3 documenten. Pro (eenmalig) ontgrendelt de noodhacks, automatische herinneringen voor items die aan vervanging toe zijn en onbeperkt documenten." Let op: **noodmodus en voorleesmodus bestaan nog niet in de app**; noem ze pas in de store zodra ze er zijn. Controleer dat screenshots geen Pro-onderdelen (noodhack-stappenplannen, herinneringen, meer dan 3 documenten) als gratis tonen.
- Op een echt toestel testen: kopen, annuleren, herstellen, herinstalleren, notificaties (ook toestemming weigeren) en de 4e kluisdocument-flow.

## Categoriekleuren

`lib/core/theme/category_palette.dart`: één tonale familie. Alleen het icoonbolletje (en in detailschermen een dunne accentlijn) krijgt kleur; kaarten, achtergronden en tekst blijven neutraal, en iconen en tekst dragen altijd de betekenis. Alle gekleurde tinten delen per thema dezelfde verzadiging en helderheid (alleen de hue verschilt). Rood en oranje komen er nooit in voor: die zijn gereserveerd voor 112, verlopen, waarschuwingen en "Doe dit nooit".

Tinten: voorzieningen en water blauw, natuur en hygiëne teal, brand en gevaarlijke stoffen en licht/warmte/koken zacht oker, gezondheid roze, veiligheid violet, noodplan groen, kluis en documenten indigo, informatie en energie blauwgrijs, instellingen en overig grijs, eten bewaren lime (enige uitbreiding), onderhoud teal. De mythes gebruiken het bestaande waarschuwingspatroon (geen eigen tint). Eigen checklistcategorieën blijven grijs.

Bewaakt door `test/category_palette_test.dart` (icoon op bolletje minstens 4,5:1 terwijl 3:1 de eis is, accentlijn minstens 3:1, tekst minstens 4,5:1, gelijke helderheid en verzadiging, geen rood of oranje, elke categorie heeft een tint) en `test/category_golden_test.dart` (screenshots in `test/goldens/`, licht, donker, 200% en protanopie/deuteranopie; regenereer met `flutter test --update-goldens`). Noodplan en Kluis staan alleen in de tab *Mijn plan*; de kaarten in Noodgevallen zijn weggehaald.

## Privacybeleid en voorwaarden (GitHub Pages)

De pagina's staan in `docs/` (`index.html`, `privacy.html`, `terms.html`, `style.css`) en worden met GitHub Pages gepubliceerd. De app linkt ernaar onder Meer, Informatie, Juridisch (`lib/core/legal.dart`).

Eenmalig instellen (dit kon ik niet zelf: er is geen `gh`-CLI of remote in deze omgeving):
1. Maak een **publieke** repository `nl-noodpakket` onder het account `GymWiki` en push dit project (`git remote add origin https://github.com/GymWiki/nl-noodpakket.git`, `git push -u origin master`).
2. Repository, Settings, Pages: Source "Deploy from a branch", branch `master`, map `/docs`.
3. Na een minuut zijn de pagina's bereikbaar op `https://gymwiki.github.io/nl-noodpakket/privacy.html` en `.../terms.html`. Controleer beide URL's in een browser.
4. Heet de repository of het account anders, pas dan alleen `legalBaseUrl` in `lib/core/legal.dart` aan (en de GitHub-Issues-links in `docs/`). `test/legal_test.dart` bewaakt dat de links, bestanden en toestemmingen kloppen.
5. Vul dezelfde privacy-URL in Play Console (App-inhoud, Privacybeleid) en App Store Connect (App-informatie).

Let op: de teksten zijn zorgvuldig opgesteld naar wat de app doet, maar niet juridisch getoetst. Laat ze zo nodig controleren. De pagina's noemen geen e-mailadres; contact loopt via GitHub Issues.

## Release-controles (na de audit van 2026-11-11)

- **Signing**: `flutter build appbundle --release` faalt bewust zonder `android/key.properties`. Een release-APK voor lokaal testen mag nog met de debug-sleutel. Controleer na het bouwen met `apksigner verify --print-certs` dat het certificaat niet `Android Debug` is.
- **Obfuscatie (optioneel)**: `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols` en bewaar `build/symbols` voor crashrapporten.
- **iOS**: `ios/Runner/PrivacyInfo.xcprivacy` (geen tracking, geen verzamelde data) staat in het Xcode-project, maar is op Windows niet gebouwd. Bouw op een Mac met Xcode 26 en bekijk het privacyrapport (Product, Archive, Generate Privacy Report). `ITSAppUsesNonExemptEncryption` is **bewust niet** ingevuld: de kluis gebruikt versleuteling en de exportverklaring is jouw juridische keuze. Vul in Info.plist `false` in als je vindt dat je onder de vrijstelling valt, of beantwoord de vraag in App Store Connect.
- **Licenties**: Meer, Informatie, Open-sourcelicenties (`showLicensePage`).
- **Nog open**: het updatepad vanaf de live-app is niet vast te stellen vanuit deze repo; test de update met de oude release. Zie `RELEASE_READINESS.md`.

