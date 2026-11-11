# Release readiness NL-Noodpakket 1.0.13 (build 13)

Onderzoek van 2026-11-11. Er is niets in de code, config of content gewijzigd en niets gecommit. Dit rapport is het enige nieuwe bestand.
Statussen: ✅ geslaagd (met bewijs) · ❌ mislukt · ⚠️ risico/twijfel · ➖ niet geverifieerd (met reden).

## 1. Verdict

**NO-GO in de huidige staat; GO MET VOORWAARDEN zodra de vier blockers hieronder zijn opgelost.**
De Android-build is technisch gezond (target API 36, 16 KB-uitlijning in orde, 394 tests groen, analyze schoon, R8 aan), maar de release-AAB is nu met de debug-sleutel getekend, er is nergens een privacybeleid (verplicht in beide stores), de iOS-build is niet gebouwd of getoetst, en het updatepad vanaf de bestaande live-app is niet vast te stellen. Daarnaast staan er twee inhoudelijke punten in de noodinformatie die vóór publicatie recht moeten (telefoonnummer-omschrijving en een bronvermelding).

## 2. Samenvattingstabel

_De aantallen zijn een indicatie op basis van de lijsten per sectie hieronder, niet een geautomatiseerde telling._

| Sectie | ✅ | ❌ | ⚠️ | ➖ |
|---|---|---|---|---|
| 1 Build en statische kwaliteit | 9 | 0 | 4 | 3 |
| 2 Versies, identiteit, updatepad | 4 | 1 | 2 | 3 |
| 3 Android | 11 | 0 | 3 | 3 |
| 4 iOS | 5 | 0 | 3 | 6 |
| 5 Store-compliance | 5 | 1 | 4 | 4 |
| 6 Inhoud en juistheid | 8 | 0 | 3 | 2 |
| 7 Runtime (emulator, API 36) | 6 | 0 | 2 | 8 |
| 8 Toegankelijkheid en prestaties | 3 | 0 | 3 | 4 |
| 9 Documentatie | 3 | 0 | 2 | 1 |

## 3. Bevindingen

### Blockers (moeten opgelost voor release)

**B1. Release is met de debug-sleutel getekend** ❌
- Waar: [android/app/build.gradle.kts](android/app/build.gradle.kts) regels 40 tot 59; geen `android/key.properties` aanwezig.
- Bewijs: `apksigner verify --print-certs` op de release-APK geeft `CN=Android Debug`. De gradle-regel valt zonder key.properties stilzwijgend terug op de debug-sleutel.
- Impact: Play Console weigert een AAB met een debug-sleutel; een onbedoeld debug-getekende upload kan niet meer worden hersteld als Play App Signing is geactiveerd met een andere sleutel.
- Fix-richting: `key.properties` en de upload-keystore van de bestaande listing plaatsen; build laten falen als `key.properties` ontbreekt in plaats van terug te vallen op debug.

**B2. Geen privacybeleid (URL en in de app)** ❌
- Bewijs: `grep -rniE "privacybeleid|privacy policy|privacyverklaring" lib README.md` geeft niets; ook Info-scherm en Instellingen verwijzen nergens naar een beleid.
- Bron: Google Play vereist een privacybeleid in de Play Console én in de app, ook als er geen persoonsgegevens worden gebruikt (User Data policy, support.google.com/googleplay/android-developer/answer/13316080, geraadpleegd 2026-11-11). Apple: privacybeleid-URL verplicht in App Store Connect en in de app (App Review Guidelines 5.1.1, samenvatting; gepubliceerd 'Last Updated October 16, 2026').
- Impact: afwijzing in beide stores.
- Fix-richting: korte openbare pagina (offline, geen tracking, kluis lokaal, betalingen via de store, back-ups blijven bij de gebruiker) en een regel "Privacybeleid" in Info of Instellingen die de URL opent.

**B3. Updatepad van de live-app niet vast te stellen** ➖ → behandeld als blocker
- De vorige versie is bewust niet onderzocht (afspraak: sleutelbestanden in `NL_Noodpakket 1.0` niet openen; ik heb niets uit die map gelezen).
- Bekend: de nieuwe app gebruikt `noodpakket.sqlite` in de documentenmap, schemaVersion 2, met een geteste migratie v1 naar v2 ([test/plan_domain_test.dart](test/plan_domain_test.dart) groep "migratie v1 -> v2", geslaagd). Onbekend: of de live-app dezelfde bestandsnaam, schema en applicationId gebruikt.
- Risico: andere opslag betekent dat gebruikers na de update met een lege app beginnen (dataverlies); dezelfde bestandsnaam met afwijkend schema kan een crash geven.
- Aanname over versies: live is 1.0.12 (code 12), build is 1.0.13+13, applicationId/bundle ID `com.mycompany.mijnnoodpakket` (uit eerdere opdracht; niet uit de stores gelezen).
- Test die jij moet doen: oude release installeren, data aanmaken, dan deze AAB eroverheen installeren (`adb install -r`), en controleren op crash en dataverlies.
- Gevolg van de keuze om geen `legacyReminders`-recht te bouwen: bestaande gebruikers verliezen de gratis vervangherinneringen (nu Pro) en de keuze "herinner mij" moet per item opnieuw worden gezet. Vermeld dit in de release notes.

**B4. iOS-build niet gebouwd en niet getoetst** ➖ → behandeld als blocker
- Omgeving is Windows; `flutter build ipa` kan hier niet. Er staat geen `ios/Podfile` in de repo (wordt op de Mac gegenereerd). Ontbreekt: `PrivacyInfo.xcprivacy` in de app (⚠️ zie M2) en `ITSAppUsesNonExemptEncryption` (⚠️ zie M3).
- Bron: sinds 2026-04-28 moet met Xcode 26 en de iOS 26 SDK worden gebouwd; sinds 2026-09-09 moeten uploads iOS 13 of hoger als minimum hebben (developer.apple.com/news/upcoming-requirements, 2026-11-11). Het deployment target is 13.0 (`project.pbxproj`).
- Fix-richting: bouwen en archiveren op een Mac met Xcode 26, `pod install` laten slagen (pluginminima voor iOS ➖), en de runtime-flows op een iPhone doorlopen.

### Majors (sterk aanbevolen)

**M1. Telefoonnummer "DigiHulplijn 0800-1508" wordt verkeerd omschreven** ⚠️
- Waar: [assets/wiki/noodgevallen.json](assets/wiki/noodgevallen.json) regels 103 en 107 (noodgeval uitval-telecom).
- Bewijs: het nummer staat op de Denk Vooruit-pagina (`...risicos-in-nederland/cybercriminaliteit`, zelf opgehaald). Daar is de DigiHulplijn bedoeld voor hulp bij inloggen in twee stappen en dergelijke. De app zegt "Heb je hulp nodig na online oplichting of hacking?".
- Impact: gebruiker belt een lijn die dat niet afhandelt.
- Fix-richting: tekst aanpassen naar het doel dat de bron noemt, of het nummer weghalen.

**M2. Geen `PrivacyInfo.xcprivacy` in de app** ⚠️ ([ios/Runner](ios/Runner), bestand ontbreekt)
- Apple eist redenen voor "required reason"-API's in code, ook van SDK's (upcoming-requirements, 2026-11-11; de detailpagina's gaven alleen titels terug, dus de inhoud van de eis is deels ➖). Plugins leveren meestal een eigen manifest; de app-zelf-code gebruikt geen van die API's direct, maar dat is niet gebouwd en dus niet getoetst.
- Fix-richting: manifest toevoegen (geen tracking, geen verzamelde data) en na `flutter build ipa` het gegenereerde privacyrapport in Xcode bekijken.

**M3. Exportcompliance iOS** ⚠️: `ITSAppUsesNonExemptEncryption` ontbreekt in [ios/Runner/Info.plist](ios/Runner/Info.plist). De kluis gebruikt AES voor lokale opslag; zonder sleutel vraagt App Store Connect de vraag bij elke upload.

**M4. Bronvermelding voedselbewaring klopt niet met de bron** ⚠️
- Waar: hack `koelkast-stroomuitval` ([assets/wiki/noodhacks.json](assets/wiki/noodhacks.json)).
- Bewijs: de app noemt "ongeveer 4 uur", "48 uur" (volle vriezer) en "24 uur" (halfvolle vriezer) en 7 °C / 10 °C. De genoemde Voedingscentrum-pagina bevat geen uren, alleen de 10 °C-grens (zelf opgehaald via een subagent). De uren komen dus uit een andere bron of algemene kennis.
- Impact: voedselveiligheidsadvies zonder volledig kloppende bron; de app markeert de uren zelf als schatting.
- Fix-richting: bron voor de uren vinden en toevoegen (of de uren weglaten).

**M5. Geen licentiescherm** ⚠️: geen `showLicensePage`/`showAboutDialog` in `lib`. MIT/BSD/Apache-pakketten vragen om vermelding van licenties. Fix-richting: `showLicensePage` achter een regel in Info.

**M6. Pro en aankoop nooit tegen een echte store getest** ➖ (zie sectie 5 en 7): product `pro_unlock` bestaat (nog) niet in de consoles; de flow is alleen met een nepstore getest.

**M7. Verkeerde of onduidelijke naamgeving rond overheid** ⚠️: de app heet "NL-Noodpakket", is gebaseerd op denkvooruit.nl en gebruikt blauw/Rijks-achtige toon. De disclaimer "Deze app vertegenwoordigt de Nederlandse overheid niet..." staat zichtbaar onder elk hoofdscherm (gezien op emulator, zie 7) en bovenaan Noodhacks. Google verbiedt het suggereren van een overheidsband en "Official"-titels zonder recht (support.google.com/googleplay/android-developer/answer/9888374, 2026-11-11). Risico blijft de naam met landcode; zorg dat store-naam, korte beschrijving en screenshots de disclaimer tonen.

### Minors (later)

- **m1.** Release-AAB wordt niet geobfusceerd (`--obfuscate --split-debug-info` ongebruikt). R8-minify staat wel aan (`proguard.map` in de AAB).
- **m2.** `sqlite3_flutter_libs 0.5.30` is beëindigd ("0.6.0+eol" in `pub outdated`); werkt, maar op termijn migreren. Drift staat vast op 2.30 (2.35.4 beschikbaar) om een Flutter-conflict.
- **m3.** Tijdzone van meldingen staat hard op Europe/Amsterdam ([notification_service.dart](lib/core/notifications/notification_service.dart)); reizigers zien afwijkende tijden. Herplannen gebeurt bij app-start en wijzigingen, niet op een tijdzonewissel.
- **m4.** Cloud-back-up van Android bevat de database (noodplan met namen en contactgegevens); alleen de kluis is uitgesloten (zo bedoeld, vermeld het in Data safety niet als "gedeeld").
- **m5.** Navigatiebalk breekt "Noodgevallen" op 200% systeemtekst ("Noodgeva/llen") en de selectie-indicator wordt afgekapt (screenshot, zie 8). Niet functioneel kapot.
- **m6.** `assets/icon` en `assets/splash` zijn volgens [assets/README.md](assets/README.md) "placeholders gekopieerd uit het oude project". Bevestig dat dit het gewenste live-icoon is.
- **m7.** README zegt "flutter doctor" ok, maar `flutter doctor -v` meldt: Android-licenties niet geaccepteerd en Visual Studio onvolledig (irrelevant voor Android/iOS).
- **m8.** Er is geen `integration_test`-map; alleen unit- en widgettests.

## 4. Resultaten per sectie

### 1. Build en statische kwaliteit
- ✅ Flutter 3.38.5 (Dart 3.10.4, kanaal "user-branch" in FlutterFlow-map); `flutter pub get` slaagt.
- ✅ `flutter analyze`: "No issues found!"
- ✅ `flutter test`: 394 geslaagd, 0 mislukt (23 testbestanden), incl. `pro_protection_test.dart`, `category_palette_test.dart` en goldens.
- ✅ `flutter build appbundle --release` slaagt: `app-release.aab`, 55.432.538 bytes (52,9 MB), geen waarschuwingen behalve icon-tree-shaking-meldingen. Ook APK gebouwd en geïnstalleerd.
- ✅ R8: `BUNDLE-METADATA/.../proguard.map` aanwezig.
- ✅ Geen `kDebugMode`/`assert` in `lib`; geen `print`/`debugPrint`-aanroepen met data (`grep`).
- ✅ Geen TODO/FIXME/lorem in `lib`. ⚠️ TODO's in `build.gradle.kts` (key.properties) en `pubspec.yaml` (assets).
- ✅ Geen sleutels, keystores of `.env` in repo of git-geschiedenis (28 commits; `git log --diff-filter=A` toont alleen `lib/.../vault_keys.dart`, dat is code). `.gitignore` sluit `key.properties`, `*.jks`, `*.keystore` uit.
- ✅ Externe links in code: alleen `https://www.nl-alert.nl` en `https://www.denkvooruit.nl/`.
- ⚠️ `flutter pub outdated`: veel pakketten achter (o.a. `flutter_local_notifications 22.3.3` naar 23.0.1, `go_router` 17.5 naar 18.1, `drift` 2.30 naar 2.35, `image` overschreven op 4.8.0, `sqlite3_flutter_libs` eol). Geen scan op bekende kwetsbaarheden uitgevoerd (➖: geen hulpmiddel beschikbaar; controleer op pub.dev en osv.dev).
- ➖ Onderhoudsstatus per pakket (crypto: `cryptography`; biometrie: `local_auth`, `flutter_secure_storage`; `in_app_purchase`; `cunning_document_scanner`; `flutter_contacts`) niet gecontroleerd.
- ⚠️ Licentiescherm ontbreekt (M5).

### 2. Versies, identiteit en updatepad
- ✅ `pubspec.yaml`: `version: 1.0.13+13`; AAB-badging: `versionCode='13' versionName='1.0.13'`, `package: com.mycompany.mijnnoodpakket`.
- ✅ iOS: `PRODUCT_BUNDLE_IDENTIFIER = com.mycompany.mijnnoodpakket`; versies via `$(FLUTTER_BUILD_NAME/NUMBER)`.
- ❌ Release-signing: debug-sleutel (B1).
- ➖/⚠️ Hoger dan live: aanname live 12 (niet uit repo gelezen).
- ➖ Upgradepad (B3). ✅ Eigen migratietest v1→v2 slaagt.
- ⚠️ `legacyReminders` bewust niet gebouwd (jouw keuze); gevolg zie B3.

### 3. Android
- ✅ `targetSdkVersion 36`, `compileSdk 36` (aapt2 op APK). Bron: vanaf 31 aug 2026 moeten nieuwe apps en updates API 36 of hoger targeten (developer.android.com/google/play/requirements/target-sdk, 2026-11-11).
- ✅ 16 KB: alle 64-bit libs in de AAB hebben `p_align` van 16384 of 65536 (libapp, libflutter, libsqlite3, libdartjni voor arm64-v8a en x86_64). Bron: vanaf 2027-02-01 mogen updates zonder 16 KB-ondersteuning niet meer worden uitgebracht (developer.android.com/guide/practices/page-sizes, 2026-11-11).
- ✅ Billing Library 8.0.0 (`in_app_purchase_android 0.5.0/android/build.gradle`); eisen: versie 7 of hoger (deprecation-faq, 2026-11-11).
- ✅ Machtigingen (merged): POST_NOTIFICATIONS (alleen gevraagd bij instellen herinnering, code), RECEIVE_BOOT_COMPLETED (herplannen), USE_BIOMETRIC, CAMERA (scanner-fallback), READ_CONTACTS (alleen na "Kies uit contacten"), plus uit plugins: BILLING, INTERNET, ACCESS_NETWORK_STATE, VIBRATE, USE_FINGERPRINT. Geen exacte alarmen (bewust inexact). ⚠️ INTERNET staat in de merged manifest door pluginmanifesten; de app zelf heeft geen netwerkverkeer, behalve links openen in de browser.
- ✅ Alleen `MainActivity` is `exported`; ontvangers `exported=false`; `FlutterFragmentActivity` voor biometrie; FLAG_SECURE via kanaal `nl.mijnnoodpakket/secure` ([MainActivity.kt](android/app/src/main/kotlin/com/mycompany/mijnnoodpakket/MainActivity.kt)).
- ✅ Back-upregels sluiten `vault`, `vault_tmp` en `Pictures/` uit voor cloud-back-up en apparaatoverdracht (`data_extraction_rules.xml`, `backup_rules.xml`). ⚠️ database valt wel in back-up (m4).
- ✅ Adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`), Android 12-splash (`values-v31`, `android12splash.png`).
- ⚠️ Notificatiekanaal: één kanaal "reminders"; boot- en package-replaced-ontvanger aanwezig; gedrag onder Doze/batterij-optimalisatie niet getest ➖. Tijdzonewissel zie m3.
- ➖ `minSdk` niet afgelezen uit de APK (plugins vragen minimaal 21).
- ➖ 32-bit lib `armeabi-v7a` niet op alignment gecontroleerd (niet vereist).
- ➖ `network_security_config` ontbreekt; niet nodig zolang er geen http-verkeer is (cleartext standaard geblokkeerd bij targetSdk 36).

### 4. iOS (alleen statisch gelezen)
- ✅ Info.plist: `NSFaceIDUsageDescription`, `NSContactsUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` in goed Nederlands, niet overdreven; `LSApplicationQueriesSchemes: tel`; geen `UIBackgroundModes`.
- ✅ AppDelegate bevat de overlay voor de app-switcher en schermopname en `excludeFromBackup` voor de kluismap (gelezen; niet gebouwd of gedraaid ➖).
- ✅ App-icoon 1024×1024 zonder alfa (PNG kleurtype 2).
- ✅ Notificatiepermissie: iOS-initialisatie met `requestAlertPermission: false`; gevraagd bij instellen (code).
- ⚠️ Geen PrivacyInfo.xcprivacy (M2); ⚠️ geen `ITSAppUsesNonExemptEncryption` (M3); geen entitlements/capabilities in de repo (IAP-capability stel je in Xcode/Apple Developer in) ⚠️.
- ➖ Build, pods, Keychain-toegangsklasse, runtime: niet mogelijk op Windows.

### 5. Store-compliance en beleid
- ❌ Privacybeleid ontbreekt (B2).
- ✅ Disclaimer "vertegenwoordigt de Nederlandse overheid niet" zichtbaar op de hoofdschermen (emulator-tekst: Start, Noodgevallen, Mijn plan, Meer, Noodhacks). ⚠️ naamrisico (M7); store-assets niet aanwezig om te toetsen ➖.
- ⚠️ Medische inhoud (brandwond, hacks, bleek): Apple 1.4 (fysiek letsel) vraagt extra zorg en een herinnering aan professionele hulp; de app zegt "vervangt geen professionele hulp" op Noodgevallen en de hack-pagina. Google: Health apps-declaratie en een "geen medisch hulpmiddel"-disclaimer (support.google.com/googleplay/android-developer/answer/12261419, 2026-11-11); de pagina noemt geen noodsituatie-specifieke regel. Vul de declaratie in.
- Antwoorden voor Google Data safety (volgens code): geen gegevens verzameld, geen gegevens gedeeld; alles lokaal; betalingen via Google Play; geen advertenties, geen analytics. Apple App Privacy: "Data Not Collected" (op het toestel verwerkte data valt niet onder "verzameld", developer.apple.com/app-store/app-privacy-details, 2026-11-11). Leeftijdsclassificatie: geen geweld/gokken/gebruikersinhoud; stel in via de nieuwe vragenlijst (Apple heeft in 2026 de nieuwe leeftijdsindeling doorgevoerd; vragen niet apart bevestigd ➖).
- ✅ In-app aankoop volgens code: product `pro_unlock` niet-verbruikbaar, "Aankoop herstellen" altijd zichtbaar (paywall en Instellingen), prijs uit `ProductDetails`, geen hardcoded prijs (test grep op "3,99" in `lib`), `completePurchase` voor bevestiging (Google: 3 dagen; deze regel kon ik niet op een officiële pagina bevestigen ➖), geen aftellers of popups bij opstarten (paywall alleen op tik; gezien op emulator).
- ✅ Indeling Pro klopt met de beschermingstest ([test/pro_protection_test.dart](test/pro_protection_test.dart), 6 tests, groen): poorten alleen in de toegestane bestanden; wiki, noodplan, checklist, houdbaarheid en alle kluisfuncties behalve "4e document toevoegen" bevatten geen Pro-verwijzing; mythes en twee proefhacks (`water-koken`, `koelkast-stroomuitval`) gratis.
- ➖ Store-beschrijving, screenshots, feature graphic, support-URL zijn niet in de repo. Let op in de beschrijving: noodmodus en voorleesmodus bestaan niet in de app.
- ➖ Echte aankoop en terugbetaling niet getest.

### 6. Inhoud en juistheid (met officiële bronnen)
- ✅ Bronlinks: 49 unieke URL's uit `noodgevallen.json` en `noodhacks.json`; 47 geven HTTP 200 (HEAD). 2 geven 403 voor bots: `cdc.gov/water-emergency/about/index.html` en `politie.nl`; beide zijn via een subagent wel gelezen.
- ✅ Alle 25 hacks hebben een bron en `lastReviewed` 2026-11-11; alle 23 noodgevallen een bron en `lastReviewed` 2026-11-10. Geen †-markeringen meer.
- ✅ Bevestigd tegen de officiële pagina: Brandweer geen spoed 0900-0904; Nationaal Storingsnummer 0800-9009; politie 0900-8844; Meld Misdaad Anoniem 0800-7000; kookadvies 3 minuten (Vitens); 3 liter water per persoon per dag (Denk Vooruit noodpakket); brandwond 10 minuten koelen (Brandweer); bleek 5 tot 9 procent, 2 druppels per liter, dubbel bij troebel, 30 minuten wachten (CDC en EPA).
- ⚠️ DigiHulplijn-omschrijving (M1); ⚠️ koelkast-uren (M4).
- ⚠️ "Brandwond: minimaal 10 minuten" (app) tegenover "10 minuten" (Brandweer): app zegt "minimaal"; de bron niet. Klein verschil, bron-conform maken.
- ⚠️ Sirene-test "eerste maandag van de maand": Denk Vooruit zegt dat een sirene op een andere dag dan de eerste maandag gevaar betekent; de tijd "12.00 uur" staat niet op die pagina en de app noemt die tijd daar ook niet (ok). NL-Alert-testbericht "rond 12.00 uur, eerste maandag van juni en december" in het dashboard: eerder gecontroleerd tegen nl-alert.nl; in deze audit niet opnieuw opgehaald ➖.
- ✅ Gevaarlijke mythes-sectie aanwezig; labels Veilig / Let op / Doe dit nooit hebben icoon én tekst (golden-screenshot, test).
- ✅ Bleekdosering: alleen statische instructie met etiketcontrole; geen rekenhulp (zie README "Noodhacks").
- ✅ Paraatheidsberekening: minimum van water en eten, verlopen telt niet mee, 0 personen telt als 1; `test/dashboard_domain_test.dart` (30 tests) incl. lege invoer en grote huishoudens; op emulator met afgevinkt zonder hoeveelheid toont de app "Vul in hoeveel je hebt" in plaats van "0 van 3".
- ➖ Niet elke stap van alle 23 noodgevallen en 25 hacks opnieuw tegen de bron gelegd in deze audit (eerder werk per module, laatste controle 2026-11-10/11). Alleen de bovenstaande steekproef en nummers zijn nu opnieuw gecontroleerd.

### 7. Runtime (emulator API 36, release-build, gedaan)
- ✅ Koude start en kern: Start toont paraatheid, volgende stappen, noodplan/kluisstatus en huishouden (screenshots).
- ✅ **Offline** (vliegtuigmodus, wifi en data uit, `ping` geeft "Network is unreachable"): app opent, Start, Noodgevallen, Noodhacks en een hack-detail werken zonder fouten.
- ✅ Levenscyclus: `force-stop` en heropenen bewaart de afgevinkte items (5 procent compleet blijft).
- ✅ Paywall: opent als niet-blokkerend blad bij tik op een Pro-hack, "Niet nu" sluit zonder gevolg, offline toont de knop "Ontgrendel Pro" zonder prijs en met uitleg. Proefhack "Water koken" opent volledig zonder paywall.
- ✅ Meldingen: toestemmingsmoment zit in de schakelaar (code); niet op de emulator doorlopen ➖.
- ➖ Niet doorlopen op toestel: onboarding vanaf schone installatie, afvinken en eigen items, wizard noodplan en pdf-delen, kluis (instellen, biometrie, PIN-fallback, herstelcode, 4e document, export/import, auto-vergrendeling, FLAG_SECURE en recents-preview), back-up export/import, notificaties plannen en herplannen (reboot, update, datumwijziging), Pro-aankoop en herstellen, rotatie, tijdzone/datum wijzigen, lage opslag. Reden: tijdsbudget en biometrie/store niet beschikbaar op de emulator; de logica is wel gedekt door 394 unit- en widgettests.
- ➖ Kluis: geen leesbare restanten in app-mappen gecontroleerd op een toestel (`adb run-as` niet geprobeerd). Er zijn unit-tests voor de versleuteling en voor tijdelijke bestanden.
- ➖ Database: migratie vanaf de oudste schemaversie is alleen getest met een eigen v1-bestand in de test, niet met een echte oude installatie.
- De emulator is na de test teruggezet (lettergrootte 1,0, geen vliegtuigmodus, geen nachtstand).

### 8. Toegankelijkheid, UX en prestaties
- ✅ Tekstschaal 200%: Start, Noodgevallen en Pakket zonder overflow in widget- en goldentests; op de emulator geen afgekapte kernknoppen (zie m5).
- ✅ Contrast: eigen test voor categoriekleuren (icoon op bolletje minstens 4,5 tegen WCAG-eis 3, accentlijn 3 en tekst 4,5) in licht en donker; kleurenblindheid (protanopie en deuteranopie) bekeken: categorieën blijven herkenbaar aan icoon en titel.
- ✅ Semantics: labels op noodbalk, paraatheid, kaarten en tabs ("Tabblad 3 van 5", geverifieerd via de toegankelijkheidsboom op de emulator).
- ⚠️ TalkBack/VoiceOver niet daadwerkelijk afgeluisterd; alleen de toegankelijkheidsboom en tests ➖.
- ⚠️ Pakketlijst toont lange namen over meerdere regels; geen afkappen.
- ➖ Koude starttijd, jank, geheugen bij pdf/kluis, batterij, tablet/vouwtoestel, laag-eind: niet gemeten.
- ➖ Taalcontrole: alle zichtbare tekst staat in [lib/core/l10n/strings.dart](lib/core/l10n/strings.dart); geen volledige leesronde gedaan. Datum- en getalnotatie nl-NL (initialisatie in `main.dart`).

### 9. Documentatie en overdracht
- ✅ README bevat build-, test-, signing- en releasestappen (regels 76 tot 86), Pro-handmatige stappen en kluisbeveiliging.
- ➖ README niet volledig op tegenstrijdigheden nagelopen na de laatste tab- en Pro-wijzigingen.
- ⚠️ Geen changelog of Nederlandse release notes in de repo (concept hieronder).
- ✅ Handmatige acties staan hieronder.

## 5. Niet geverifieerd (zelf te doen)
1. iOS: bouwen, archiveren, uploaden naar TestFlight en doorlopen.
2. Updatepad vanaf de live-app (B3).
3. Kluis end-to-end op een echt toestel met biometrie: instellen, vergrendelen, herstelcode, export/import, 4e document.
4. Pro-aankoop, annuleren, herstellen en terugbetaling met een licentietester en een sandbox-account.
5. Meldingen: aanzetten, reboot, app-update, datum wijzigen, Doze, toestemming weigeren.
6. TalkBack en VoiceOver, tablet, laag-eind toestel, prestaties.
7. Overige inhoud: de 23 noodgevallen en 25 hacks volledig opnieuw tegen de bronnen leggen (steekproef is gedaan).
8. Kwetsbaarheden en onderhoudsstatus van de afzonderlijke pakketten.

## 6. Bronnen (opgehaald 2026-11-11)
- Google Play target API: https://developer.android.com/google/play/requirements/target-sdk (zonder datum; ©2026)
- 16 KB: https://developer.android.com/guide/practices/page-sizes
- Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- User Data en privacybeleid: https://support.google.com/googleplay/android-developer/answer/13316080
- Health apps: https://support.google.com/googleplay/android-developer/answer/12261419
- Impersonation: https://support.google.com/googleplay/android-developer/answer/9888374
- Developer verification: https://developer.android.com/developer-verification (beschermingen vanaf 2026-09-30 in vier landen, wereldwijd 2027)
- Billing Library: https://developer.android.com/google/play/billing/deprecation-faq (v7 sinds 2026-08-31, verlengd tot 2026-11-01; v8 uiterlijk 2027-08-31)
- Exacte alarmen: https://support.google.com/googleplay/android-developer/answer/13161072
- Apple eisen: https://developer.apple.com/news/upcoming-requirements/ (Xcode 26 sinds 2026-04-28; iOS 13-minimum sinds 2026-09-09)
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/ ("Last Updated: October 16, 2026"; sectie 1.4 letterlijk gelezen, 3.1.1/4.1/4.2/5.1.1 alleen als samenvatting)
- Apple App Privacy: https://developer.apple.com/app-store/app-privacy-details/
- Apple screenshots: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
- Inhoud: denkvooruit.nl (noodpakket, sirene, cybercriminaliteit, geen-stroom), brandweer.nl (contact, brandwonden), vitens.nl (kookadvies), voedingscentrum.nl, politie.nl, meldmisdaadanoniem.nl, EPA en CDC (bleek).
- Niet kunnen bevestigen: Google-eis dat eenmalige aankopen binnen 3 dagen worden bevestigd (stond niet op de opgehaalde pagina); Apple-appiconregels en privacymanifest-detailpagina's (alleen titels).

## 7. Handmatige acties voor jou
1. Upload-keystore van de bestaande listing neerzetten en `android/key.properties` maken (zie README); daarna `flutter build appbundle --release` en met `apksigner verify --print-certs` controleren dat het niet `Android Debug` is.
2. Privacybeleid schrijven en publiceren (publiek, geen PDF, niet geo-geblokkeerd); URL invullen in Play Console (Beleid, App-inhoud) en App Store Connect (App-informatie); regel in de app laten toevoegen.
3. Play Console: App-inhoud, Data safety (geen gegevens verzameld of gedeeld), Gezondheidsapps-declaratie, content rating, doelgroep, advertenties "nee".
4. App Store Connect: App Privacy "Data Not Collected", leeftijdsclassificatie (nieuwe vragenlijst), exportcompliance (AES lokaal), privacybeleid-URL, support-URL, reviewnotities.
5. Product `pro_unlock` (niet-verbruikbaar, €3,99) aanmaken in beide consoles; Family Sharing kiezen; licentietesters instellen.
6. Reviewnotities (NL/EN): "De app werkt volledig offline en bevat geen account of gegevensverzameling. Pro test je via een sandbox-/licentietester; de kluis gebruikt biometrie met PIN-fallback. De app is niet van de overheid; de disclaimer staat in beeld."
7. Op een Mac: Xcode 26, `pod install`, `flutter build ipa`, TestFlight.
8. Updatepad testen met de oude release erover (B3); besluiten over het gratis houden van bestaande herinneringen en dit in de release notes zetten.
9. Screenshots (Android en iPhone 6,9"-formaat 1320×2868 of vergelijkbaar volgens Apples lijst), feature graphic en beschrijving. Noem noodmodus en voorleesmodus niet; toon geen Pro-onderdelen als gratis.
10. Interne test- en gesloten testtrack in Play vóór productie; gefaseerde uitrol.

## 8. Concept release notes (Nederlands)
"Nieuw: een vernieuwd startscherm met je paraatheid in één blik, een Mijn plan-tab met noodplan en documentenkluis, noodhacks voor als je pakket op is, rustiger kleuren per onderwerp en vaste onderhoudsroutines. Eenmalige Pro-aankoop voor noodhacks, herinneringen en onbeperkt documenten. Alles werkt zonder internet."

## 9. Status na de fixes (2026-11-11, zelfde dag)

| Bevinding | Status |
|---|---|
| B1 debug-signing | Opgelost in de build: `bundleRelease` faalt zonder `key.properties` (geverifieerd). De keystore zelf moet jij neerzetten. |
| B2 privacybeleid | Pagina's staan in `docs/` en de app linkt ernaar. Nog te doen door jou: repo `GymWiki/nl-noodpakket` publiek maken, Pages op `/docs`, URL in beide consoles invullen. |
| B3 updatepad | Niet op te lossen vanuit de repo. Test de update met de oude release. |
| B4 iOS | `PrivacyInfo.xcprivacy` toegevoegd en in het Xcode-project geregistreerd (niet gebouwd). Mac-build en export-vraag blijven aan jou. |
| M1 DigiHulplijn | Tekst aangepast naar wat Denk Vooruit zegt (hulp bij inloggen in twee stappen en dergelijke). |
| M4 koelkast-uren | Ongedekte uren (4, 24, 48) verwijderd; alleen nog de drempels van het Voedingscentrum (7, 10 en 15 °C). |
| M5 licenties | Licentiescherm toegevoegd. |
| M6 Pro-test | Blijft open: product en sandbox-test. |
| M7 naamrisico | Blijft een keuze; disclaimer staat in app en op de pagina's. |
| Brandwond "minimaal" | Aangepast naar "10 minuten". |
| m5 nav-label | Navigatielabels schalen niet meer mee; "Noodgevallen" breekt niet meer af. |
| m1, m3, m4, m6, m7, m8 | Ongewijzigd (zie boven). |

