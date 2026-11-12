# Drukte-audit en rustig ontwerp

Doel: de app visueel rustiger maken zonder functies, routes, data, deeplinks of notificatieroutes te wijzigen.
Basis voor "voor": commit `fcfe5f5`. Resultaat: commits `396ed9f` tot en met `555f7be` plus de laatste commit van deze audit.

## Hoe is gemeten (en wat niet)

- **Emulator:** Android 16, 1080 x 2400 px op dichtheid 480, dus 360 x 800 dp. Tekstschaal 1,0, licht thema.
- **Screenshots voor (`docs/ui-calm/before/`):** de vijf tabbladen, van boven naar beneden.
- **Screenshots na (`docs/ui-calm/after/`):** dezelfde vijf tabbladen plus itemdetail, Noodgeval-detail, Noodhacks, Noodplan, Instellingen en Rampenzender.
- **Niet gemaakt:** screenshots van de staten "leeg", donker thema en tekstschaal 2,0, en "voor"-screenshots van de subschermen. Die zijn afgedekt met tests (zie onderaan), niet met afbeeldingen.
- **Cijfers:**
  - Blokken en tikbare elementen zijn geteld op de screenshots (tabbladen) of in de code (subschermen).
  - "Kaarten" en "lettergroottes" komen uit de broncode: aantal `SoftCard`/`Card`, en aantal verschillende `textTheme`-rollen plus losse `fontSize`-waarden per schermbestand. Dat zijn indicaties, geen pixelmetingen; bij Start zijn dashboardkaarten en scherm samen geteld.

## Rangschikking van druk naar rustig (voor de ingreep)

| # | Scherm | Diagnose (voor) |
|---|---|---|
| 1 | Noodgevallen (tab) | Vijf ingangskaarten (Eerste uur, Mijn pakket is op, Noodhacks, Rampenzender, Meterkastkaart) plus een omrande kaart per categorie (5). Ongeveer 12 gelijkwaardige blokken. |
| 2 | Start (tab) | Zeven kaarten, tot drie suggesties met elk een knop en menu, twee tegels naast elkaar, kaart in kaart. |
| 3 | Noodplan-overzicht | Voortgangskaart, hoofdknop, zeven losse rijen, vier knoppen, schakelaar, drie datumregels en een privacyregel. |
| 4 | Rampenzender-resultaat | Negen kaarten, vier uitlegblokken onder elkaar, disclaimer, bron- en meldknop. |
| 5 | Noodhacks-overzicht en -detail | Gekleurde waarschuwingskaart, twee grote actiekaarten, chips over twee rijen, onderaan bronnen en twee disclaimers. |
| 6 | Pakket (tab) | Voortgangskaart, zoekveld en vier filterchips die over twee rijen lopen. |
| 7 | Itemdetail | Lange rij velden zonder indeling. |
| 8 | Instellingen | Alles als losse rijen zonder groepen, plus een disclaimer. |
| 9 | Kluis-overzicht | Gekleurde waarschuwingskaart, zoekveld, twee keuzelijsten, drie lijsten waarin dezelfde documenten kunnen staan. |
| 10 | Meer en Mijn plan | Eén omrande kaart per rij. |

## Gedeelde componenten en tokens (`lib/core/calm.dart`)

- **Tokens (`Space`):** 16 dp schermmarge, 24 dp tussen secties, 12 dp binnen groepen, 8 dp strak, 640 dp maximale inhoudsbreedte. `Gap.page` is nu 16 dp (was 20).
- **`ScreenScaffold`:** vaste marges, één kolom, gecentreerd op brede schermen.
- **`CalmSection`:** kop plus inhoud met vaste ruimte (24 dp boven, 8 dp onder).
- **`CalmListGroup`:** één tonaal vlak met dunne scheidingslijnen in plaats van een kaart per rij.
- **`StatusRow`:** rij met pictogram, titel, bijschrift en pijltje, minimaal 56 dp, met Semantics.
- **`ExpandableSection`:** inklapbare sectie ("Toon meer"), nooit voor veiligheidsinformatie.
- **`PrimaryActionBar`:** balk met één primaire actie. Gebouwd en getest op compilatie, maar nog niet toegepast op een scherm.
- **`SoftCard`:** heeft geen rand meer; het onderscheid komt van een tonaal vlak.

## Wat is er per scherm veranderd

Cijfers: voor, dan na.

| Scherm | Wijziging | Blokken / tikbare elementen | Kaarten (code) | Lettergroottes (code) |
|---|---|---|---|---|
| **Start** | Eén "Volgende stap" (rest achter "Toon alles"). Rampenzender, Noodplan, Kluis en Huishouden samen als één lijst "Meer overzicht". Paraatheid compacter (ring 96 naar 80 dp). Disclaimer één keer, klein. | 7 blokken naar 4; ongeveer 16 naar 12 tikbare elementen op het hele scherm | 9 naar 7 | 11 naar 11 |
| **Pakket** | Filterchips in één zijwaarts scrollende rij (was twee rijen), voortgangskaart kleiner, marges naar tokens. Segment Lijst/Vervangen, zoeken en alle items zijn behouden. | Chips-rijen 2 naar 1 | 2 naar 2 | 4 naar 4 |
| **Noodgevallen (tab)** | Eerste-uur kaart blijft prominent. Categorieën als één lijst (geen teller, geen kaart per categorie). Mijn pakket is op, Noodhacks, Rampenzender en Meterkastkaart samen onderaan als "Extra hulp". 112, zoeken en de regel blijven bovenaan. | ongeveer 12 blokken naar 5 | 8 naar 2 | 8 naar 6 |
| **Noodgeval-detail** | "Nu doen" en "Bel 112 als…" blijven open. "Daarna", "Voorbereiden" en "Bronnen" (met controledatum) zijn inklapbaar. De regel "Bij levensgevaar bel je 112" blijft onderaan. | 3 inklapbare secties | 0 naar 0 | 4 naar 4 |
| **Itemdetail** | Drie blokken: Status, Herinnering en uitklapbaar "Meer" (notities, kluislink, eigen uitleg). "Waarom is dit belangrijk?" blijft zichtbaar en compact bovenaan. | 3 blokken | 1 naar 0 | **2 naar 4 (verslechterd)** |
| **Noodhacks overzicht** | Waarschuwing als rustige regel (niet meer als gekleurde kaart). Twee actiekaarten als één lijst. Chips in één rij. Categorieën als lijst. Overheidsdisclaimer weg (blijft bij Noodgevallen). | Chips-rijen 2 naar 1 | 3 naar 0 | 3 naar 1 |
| **Hack-detail** | Bronnen en controledatum inklapbaar. Waarschuwingen en het label ✅/⚠️/⛔ blijven zichtbaar. Alternatieven als lijst. | 1 inklapbare sectie | 3 naar 2 | 7 naar 7 |
| **Mijn plan (tab)** | Noodplan, Gesprek, Kluis en "Delen met een ander toestel" in één lijst. Delen en scannen zitten in één blad (zie "één tik dieper"). | 5 kaarten naar 1 lijst | 1 naar 0 | 3 naar 1 |
| **Noodplan-overzicht** | Zeven onderdelen als één lijst. Acties (gesprek, delen, bevestigen, importeren, herinnering) als één lijst in plaats van vier knoppen. Datumregels klein. | 5 knoppen naar 1 lijst | 3 naar 3 | 2 naar 3 |
| **Kluis-overzicht** | Waarschuwing als rustige regel. Filters (type, eigenaar) onder een inklapbare sectie "Filter" (open zodra een filter actief is). Documentlijst als één vlak. | 2 keuzelijsten naar 1 inklapbare sectie | 2 naar 1 | 5 naar 5 |
| **Rampenzender** | "Zo stel je je radio in" en de tip blijven zichtbaar. "Waarom deze zender" en het radio-advies staan onder "Meer uitleg". Overheidsdisclaimer weg. De frequenties, "Ik heb mijn radio ingesteld" en "Klopt dit niet?" zijn ongewijzigd. | 4 uitlegblokken naar 2 + 1 inklapbaar | 9 naar 9 | 8 naar 8 |
| **Meer** | Drie rijen in één lijst. | 3 kaarten naar 1 lijst | 1 naar 0 | 3 naar 1 |
| **Instellingen** | Groepen met kopjes, vlak in plaats van losse rijen. Pro is één rij met "Aankoop herstellen" er direct onder. Onomkeerbare "Alles resetten" staat apart onderaan. Disclaimer weg (blijft bij Meer en Informatie). | 5 groepen | 0 naar 0 | 2 naar 2 |
| **Paywall** | Eerst wat je krijgt, dan de koop-knop, daarna "Dit blijft altijd gratis" inklapbaar. Eén primaire knop. | lijst van 5 gratis-regels ingeklapt | n.v.t. | n.v.t. |
| **Informatie en onboarding** | Disclaimer als rustige tekst in plaats van een gekleurde kaart. Onboarding blijft één vraag per scherm. | n.v.t. | n.v.t. | n.v.t. |

## Eerlijke tekortkomingen

- **Lettergroottes:**
  - Het ontwerpbudget van maximaal 3 per scherm is nog niet gehaald op Start, Noodgevallen, Hack-detail en Rampenzender.
  - Itemdetail is slechter geworden (2 naar 4) door de nieuwe sectiekoppen en het uitlegblok.
  - Dit is niet verder uitgewerkt.
- **Kaarten:** Rampenzender heeft nog 9 kaarten. De frequentieblokken zijn bewust apart gehouden omdat dit het kerngegeven is. Dat is mogelijk nog te druk.
- **Noodplan-overzicht:** de introtekst bovenaan is vijf regels. Ik heb de tekst niet gewijzigd.
- **Kleurgebruik:** de categoriekleuren zijn ongewijzigd. Een telling van het aantal verschillende kleuren per scherm is niet gedaan.
- **Niet aangepast, niet bekeken:**
  - Plan-wizard, plan-gesprek, plan-delen, plan-PDF.
  - Kluis-detail, kluis-toevoegen, kluis-instellingen, kluis-setup en kluis-vergrendeling.
  - De delen-schermen (instellen, documenten, QR, scannen, gedeeld plan).
  - Regio kiezen, Dashboard-subschermen (suggesties, onderhoud, NL-Alert) en stap-voor-stap voor Noodgevallen en hacks.
  - Redenen: de stap-voor-stap schermen zijn al één stap per scherm; de rest valt buiten de gelezen schermen.
  - Ze erven wel de nieuwe 16 dp marge en de randloze `SoftCard`.
- **`PrimaryActionBar`:** gebouwd, maar nergens toegepast.

## Functies die één tik dieper zitten

Gemeten vanaf het tabblad waar ze stonden.

| Functie | Voor | Na |
|---|---|---|
| Plan delen met een ander toestel (Mijn plan) | 1 tik | **2 tikken** (rij "Delen met een ander toestel", dan "Mijn plan delen") |
| Plan scannen (Mijn plan) | 1 tik | **2 tikken** (rij, dan "Scan een noodplan") |
| Waarom deze zender en radio-advies (Rampenzender) | zichtbaar | **1 tik** (Meer uitleg) |
| Daarna, Voorbereiden en Bronnen (Noodgeval-detail) | zichtbaar | **1 tik** (uitklappen) |
| Bronnen en controledatum (hack-detail) | zichtbaar | **1 tik** |
| Wat blijft gratis (paywall) | zichtbaar | **1 tik** |
| Filter op type of eigenaar (kluis) | zichtbaar | **1 tik** |
| Notities en kluislink (itemdetail) | zichtbaar | **1 tik** (Meer), tenzij notities al bestaan |
| Suggesties 2 en 3 (Start) | zichtbaar | **1 tik** ("Toon alles") |

Alles blijft binnen twee tikken vanaf het tabblad.

## Waar rust en veiligheid botsen

- **Bel 112, Eerste uur, "Bel 112 als…", "Nu doen", waarschuwingen en ✅/⚠️/⛔-labels:** nooit ingeklapt of verkleind. De test `calm_test.dart` controleert dit op 320 dp bij schaal 1,0 en 2,0.
- **Hack-waarschuwingen en de kluis-waarschuwing:** bleven in tekst volledig zichtbaar, maar zijn niet meer een gekleurde kaart (een tertiaire tint). Dat is rustiger, maar valt iets minder op. Dit is bewust gekozen omdat het pictogram en de tekst de betekenis dragen, niet de kleur.
- **"Waarom deze zender" (Rampenzender):** de spec vroeg dit zichtbaar te laten. Het staat nu onder "Meer uitleg". De frequenties, de instructie "Zo stel je je radio in" en de tip blijven zichtbaar. Zeg het als dit toch open moet staan.

## Tests en bewijs

- `test/calm_test.dart` (83 tests):
  - Bereikbaarheid van 18 functies in maximaal twee tikken, met doelschermen als stubs.
  - 112, Eerste-uur kaart, de regel op Noodgevallen en "Nu doen" / "Bel 112 als" blijven zichtbaar op 320 dp bij schaal 1,0 en 2,0.
  - Vijf hoofdschermen op 320, 360 en 411 dp, schaal 1,0 en 2,0, licht en donker, zonder overflow.
- Aangepaste bestaande tests: dashboard (één volgende stap), wiki, hacks, paywall, Rampenzender en de goldens (nieuwe layout).
- Niet in een test: de twee Instellingen-routes (verborgen items, regio kiezen), omdat het Instellingen-scherm in de testomgeving een platformplugin aanroept. Handmatig na te kijken.
- `flutter analyze` is schoon. Alle tests slagen.
