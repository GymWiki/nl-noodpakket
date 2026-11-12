# Rampenzender-data vernieuwen

De app bevat de gegevens van de rampenzenders (FM en DAB+) als `assets/radio/rampenzenders.json`.
Die data is **leidend** en wordt in de app gebundeld. Er zijn geen netwerkaanroepen.

## Bestanden

| Bestand | Rol |
|---|---|
| `tool/rampenzenders_curated.json` | Met de hand gecontroleerde bronnen, omroepen, frequenties en koppelingen. **Dit bestand pas je aan.** |
| `tool/data/cbs_gebieden_2026.json` | Momentopname CBS-tabel 86247NED (gemeente, provincie, veiligheidsregio per 1 januari 2026). |
| `tool/generate_rampenzenders.dart` | Bouwt de JSON uit de twee bestanden hierboven en valideert het resultaat. |
| `tool/validate_rampenzenders.dart` | Controleert de JSON in `assets/radio/` (ook in de tests). |

## Vernieuwen

1. Controleer per omroep de bronpagina's (zie `sources` in het curated-bestand). Gebruik alleen officiële of gezaghebbende bronnen.
2. Pas `tool/rampenzenders_curated.json` aan en zet bij elke zending de bronnen (`sourceIds`) en `verification`.
   `meerdere-bronnen` vraagt minstens twee bronnen; anders gebruik je `enkele-bron`.
3. Zet `reviewed` op de datum van de controle.
4. Bij een gemeentelijke herindeling of een nieuwe CBS-tabel: `dart run tool/generate_rampenzenders.dart --refresh-cbs`.
   Pas daarna zo nodig de tabel-id (`86247NED`) en de bestandsnaam in `tool/generate_rampenzenders.dart` aan naar het nieuwe jaar.
5. Zonder CBS-vernieuwing: `dart run tool/generate_rampenzenders.dart`.
6. Valideer: `dart run tool/validate_rampenzenders.dart` en draai `flutter test test/rampenzender_test.dart`.

## Regels

- Twijfel je over een frequentie of regio? Laat die weg. Een gat is beter dan een foute waarde.
- Koppel een gemeente alleen aan een gebied (`areaLinks`) als een bron dat aantoont. Anders kiest de gebruiker zelf uit de lijst.
- FM-frequenties: 87.5 tot 108.0 MHz. DAB+-kanalen: 5A tot 13F.
- Een latere ondertekende content-update zonder app-release is mogelijk, omdat de app alleen dit ene JSON-bestand leest. Dat is nu bewust niet gebouwd.
