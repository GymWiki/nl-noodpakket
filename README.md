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
