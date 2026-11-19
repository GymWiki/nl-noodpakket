# Zoekintenties en paginakoppeling

Doel: bij elke pagina één primaire intentie, zodat pagina's niet met elkaar concurreren. **Er zijn bewust geen zoekvolumes ingevuld**: die verzin ik niet. Na livegang komen echte zoekopdrachten, vertoningen en klikken uit Google Search Console (Prestaties, Zoekopdrachten); vul dit overzicht dan aan.

NL-Noodpakket is niet van de overheid en de site bevat geen noodadvies of stappenplannen. Intenties die om *advies* vragen worden daarom niet met eigen artikelen bediend, maar met een verwijzing naar de officiële bronnen.

| Pagina | Primaire intentie (wat zoekt iemand) | Secundaire intenties | Wat de pagina beantwoordt |
|---|---|---|---|
| `/` | "noodpakket app" (een app vinden om een noodpakket samen te stellen) | "noodplan maken app", "noodpakket checklist", "noodplan delen", "documentenkluis app", "app voor noodplan gezin" | Wat de app is (definitiezin), voor wie, hoe het werkt in drie stappen, welke functies, gratis versus Pro, privacy, wat de app niet doet |
| `/veelgestelde-vragen` | Korte feitelijke vragen over het noodpakket en de app: "hoe lang moet ik mezelf kunnen redden", "hoeveel water per persoon", "werkt de app offline", "is NL-Noodpakket van de overheid" | "kost de app geld", "verzamelt de app gegevens", "noodplan delen" | Directe antwoorden in dezelfde formulering als de listing, met verwijzing naar de bronnen |
| `/bronnen` | "waar komt de informatie vandaan" / vertrouwen en herkomst | "denkvooruit noodpakket bronnen" (navigeren naar de officiële bronnen) | Gegroepeerde links naar de officiële bronnen, met de verklaring dat de site niet van de overheid is |
| `/privacy` | Privacybeleid (voor de winkels en AVG-vragen) | "is NL-Noodpakket veilig", "noodplan gegevens delen" | Wat de app en de website wel en niet doen met gegevens |
| `/voorwaarden` | Gebruiksvoorwaarden (voor de winkels) | | Voorwaarden en disclaimers |
| `/wijzigingen` | "NL-Noodpakket nieuwe versie / wat is er nieuw" | | Releasehistorie |
| `/contact` | Support en bedrijfsgegevens | | E-mailadres, KVK, vestigingsplaats |

## Gevraagde zoekintenties en hoe ze worden bediend

| Zoekintentie | Bediend door | Opmerking |
|---|---|---|
| noodpakket app | `/` (titel, H1, definitiezin) | Primair. |
| noodplan maken app | `/` (sectie "Zo werkt het", functie "Noodplan delen") | Geen aparte pagina: geen dubbele inhoud met home. |
| noodpakket checklist | `/` (functie "Checklist met houdbaarheid") | De checklist zelf zit in de app; de site geeft geen lijst met adviezen. |
| stroomstoring voorbereiden app | `/` (functie "Stappenplannen voor meer dan 20 noodsituaties") en `/bronnen` | **Bewust geen eigen pagina.** Een pagina over "wat doe je bij een stroomstoring" is noodadvies; verwijs naar Denk Vooruit en de netbeheerders (staan op `/bronnen`). |
| noodplan delen | `/` (functie) en `/veelgestelde-vragen` ("Hoe deel ik mijn noodplan?") | Eén feitelijk antwoord, geen concurrerende tweede pagina. |
| documentenkluis app | `/` (functie "Documentenkluis met biometrie") en `/privacy` | |
| rampenzender frequentie | `/` (functie "Rampenzender per regio") en `/bronnen` (links naar de regionale omroepen) | **Bewust geen frequentietabel op de site**: die moet actueel en correct zijn en komt uit de officiële bronnen/de app. Overweeg dit pas als de gegevens centraal onderhouden worden. |
| hoeveel water per persoon noodpakket | `/veelgestelde-vragen` | Antwoord: richtlijn van 3 liter per persoon per dag; verwijzing naar de bron. |
| is NL-Noodpakket van de overheid | `/veelgestelde-vragen`, `/bronnen` en de overheidsverklaring op elke pagina | Merkvraag: eerlijk en eenduidig beantwoorden. |

## Regels tegen kannibalisatie

1. Eén definitiezin (`src/config/site.ts`), gebruikt op de homepage; andere pagina's herhalen die niet als hoofdtekst.
2. FAQ-antwoorden zijn kort en verwijzen naar de bron- of privacypagina in plaats van het onderwerp opnieuw uit te schrijven.
3. `/privacy` en `/voorwaarden` herhalen geen marketingtekst en andersom.
4. Nieuwe pagina's alleen als er een intentie is die geen bestaande pagina beter kan bedienen, en nooit als noodadvies.
