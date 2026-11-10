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
