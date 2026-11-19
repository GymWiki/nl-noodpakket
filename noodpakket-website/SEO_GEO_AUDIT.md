# SEO- en GEO-audit NL-Noodpakket

Gemeten op de lokale productiebuild (`dist/`) van de branch `claude/upbeat-keller-5nyng8`, 19 november 2026. Site-URL uit `src/config/site.ts`: `https://nl-noodpakketapp.nl`. Zie "Na de optimalisatie" onderaan voor de vergelijking.

## Wat ik niet kon meten (en waarom)

De bouwomgeving bereikt alleen npm. Daarom:
- **Live site:** `curl` met acht user-agents (Googlebot, GPTBot, OAI-SearchBot, ChatGPT-User, ClaudeBot, Claude-SearchBot, Claude-User, PerplexityBot) op `nl-noodpakketapp.nl`, `www.` en `nl-noodpakket.vercel.app` gaf overal `000` (de verbinding wordt door de proxy geweigerd). De web-fetch-tool kon de hosts niet resolven (DNS). **Statuscodes, redirects en robots.txt op de live site zijn dus niet gemeten.** Controleer ze met de lijst in `docs/SEO_LAUNCH_CHECKLIST.md`.
- **PageSpeed Insights / veldgegevens (CrUX):** niet bereikbaar, en echte veldmetingen bestaan pas na verkeer. Hieronder staan alleen laboratoriummetingen (Lighthouse).
- **Documentatie van aanbieders** (OpenAI, Google, Perplexity, Vercel) niet bereikbaar. Alleen de Anthropic-pagina over crawlers is gelezen (zie `robots.txt` en README).
- **Store-listings:** staan niet in de repo. De enige bron is het conceptje in de README van de app (sectie "Handmatig door jou").

## Bouwen en kwaliteit

| Controle | Resultaat |
|---|---|
| `astro check` | 0 fouten, 0 waarschuwingen, 0 hints |
| Productiebuild | zonder waarschuwingen, 8 pagina's |
| HTML-validatie (`tests/html.mjs`) | geen bevindingen |
| JSON-LD en meta (`tests/jsonld.mjs`) | geen bevindingen |
| Interne links (`tests/links.mjs`) | 23 gecontroleerd, 0 kapot |
| Externe links | **niet te controleren** (geen netwerk); `node tests/links.mjs --external` met netwerk |
| Playwright (360/768/1280 px, tekst 200%, axe, CSP) | geen bevindingen |

## Lighthouse mobiel (lab), voor

| Pagina | Prestaties | Toegankelijkheid | Best practices | SEO | LCP | TBT | CLS | Overdracht |
|---|---|---|---|---|---|---|---|---|
| / | 100 | 100 | 100 | 100 | 1,4 s | 0 ms | 0 | 527 KiB |
| /veelgestelde-vragen | 100 | 100 | 100 | 100 | 1,1 s | 0 ms | 0 | 449 KiB |
| /bronnen | 100 | 100 | 100 | 100 | 1,2 s | 0 ms | 0 | 490 KiB |
| /privacy | 100 | 100 | 100 | 100 | 1,1 s | 0 ms | 0 | 445 KiB |
| /voorwaarden | 100 | 100 | 100 | 100 | 1,1 s | 0 ms | 0 | 442 KiB |
| /wijzigingen | 100 | 100 | 100 | 100 | 1,1 s | 0 ms | 0 | 438 KiB |
| /contact | 100 | 100 | 100 | 100 | 1,1 s | 0 ms | 0 | 438 KiB |
| /404 | 100 | 100 | 100 | 66 | 1,1 s | 0 ms | 0 | 436 KiB |

Doelen voor Core Web Vitals (75e percentiel van echte gebruikers): LCP ≤ 2,5 s, INP ≤ 200 ms, CLS ≤ 0,1. Lighthouse is een laboratoriummeting met gesimuleerde throttling en vervangt geen veldmeting; INP is in het lab niet te meten (TBT is een indicatie). De 404 scoort 66 op SEO omdat het een HTTP 404 met `noindex` is: dat is bedoeld.

**Bevinding P1 (prestaties):** elke pagina laadt ~295 KiB JavaScript (`client` 205 + `MobileMenu` 77 + `react-dom` 13 KiB) alleen voor het mobiele menu. Op een kale pagina is dat meer dan 65% van de overdracht (lettertypen 76 KiB, CSS 41 KiB). Dat is "onnodige JavaScript" en schaadt vooral trage telefoons.

## Per pagina

| Pagina | Title (tekens) | Description | H1 | OG | Afbeeldingen | Interne links in `main` | Binnenkomende links | Woorden | JSON-LD |
|---|---|---|---|---|---|---|---|---|---|
| `/404` | 36 | 70 | 1 | 5/5 | 2 (0 zonder alt) | 4 | 0 | 24 | Organization, BreadcrumbList |
| `/bronnen` | 41 | 137 | 1 | 5/5 | 2 (0 zonder alt) | 2 | 7 | 724 | Organization, BreadcrumbList |
| `/contact` | 34 | 126 | 1 | 5/5 | 2 (0 zonder alt) | 2 | 7 | 94 | Organization, BreadcrumbList |
| `/` | 55 | 137 | 1 | 5/5 | 9 (0 zonder alt) | 3 | 7 | 646 | Organization, MobileApplication |
| `/privacy` | 29 | 139 | 1 | 5/5 | 2 (0 zonder alt) | 4 | 7 | 1228 | Organization, BreadcrumbList |
| `/veelgestelde-vragen` | 54 | 143 | 1 | 5/5 | 2 (0 zonder alt) | 3 | 7 | 471 | Organization, BreadcrumbList, FAQPage |
| `/voorwaarden` | 35 | 133 | 1 | 5/5 | 2 (0 zonder alt) | 4 | 7 | 766 | Organization, BreadcrumbList |
| `/wijzigingen` | 38 | 116 | 1 | 5/5 | 2 (0 zonder alt) | 2 | 7 | 128 | Organization, BreadcrumbList |

Alle pagina's: `lang="nl-NL"`, canonical aanwezig, Twitter-kaart, OG-beeld 1200×630 aanwezig, geen orphan pages behalve de bewust niet gelinkte 404.

Bevindingen:
- **P2 Interne links:** de homepage heeft maar 3 interne links in de inhoud (FAQ, privacybeleid, bronnen). Wijzigingen, voorwaarden en contact worden alleen via header en footer bereikt. FAQ en bronnen verwijzen niet naar privacy en elkaar met beschrijvende ankers.
- **P3 Kopstructuur:** de FAQ-pagina heeft alleen H1 en een H2 voor de overheidsverklaring; de vragen zijn geen koppen. Op de homepage staat een H3 "Zo ziet de app eruit" die alleen voor schermlezers zichtbaar is.
- **P4 Sitemap:** geen `lastmod`. Voor pagina's met een bijgehouden datum (home, FAQ, bronnen, privacy, voorwaarden, wijzigingen) is die betrouwbaar beschikbaar.
- **P5 robots.txt:** alleen `User-agent: *` en de sitemap. Geen expliciete regels per bot en geen documentatie van de afweging training versus zoeken.
- **P6 Structured data:** MobileApplication, Organization, BreadcrumbList en FAQPage zijn aanwezig. Ontbreekt: WebSite, `sameAs`/`installUrl` naar de store-pagina's.
- **P7 Eén bron voor tekst:** de definitiezin staat in `site.ts`, maar de functielijst, de gratis/Pro-omschrijving en het stappenplan "hoe werkt het" staan verspreid door `index.astro` en `llms.txt.ts`. Risico op afwijkende formuleringen.
- **P8 Inhoud:** de homepage legt de intentie uit (wie, wat, wat niet), maar beantwoordt "hoe werkt het" en "wanneer gebruik ik dit" niet in een paar korte alinea's.

## Crawling en indexering (analyse van de code)

| Onderdeel | Staat |
|---|---|
| robots.txt | wordt gegenereerd uit `SITE_URL`; staat alles toe, verwijst naar `sitemap-index.xml` |
| Sitemap | `sitemap-index.xml` en `sitemap-0.xml`: 7 URL's, de 404 staat er terecht niet in, geen `lastmod` |
| Canonical | per pagina uit `SITE_URL` + pad; geen hard-gecodeerd domein in code (alleen in config) |
| http naar https | doet Vercel automatisch (niet live getest) |
| www naar apex | in Vercel ingesteld op 307 (tijdelijk); **moet 308 zijn**. Bevestigd in de Vercel-API: apex serveert, `www` verwijst door |
| Slash-gedrag | `trailingSlash: "never"`, `cleanUrls: true`, `build.format: "file"`; `/privacy/` hoort naar `/privacy` te gaan (Vercel); niet live getest |
| Dubbele URL's | `/index.html` en `/privacy.html` worden door `cleanUrls` doorverwezen naar de schone URL |
| 404 | eigen pagina, `noindex`, HTTP 404 (alleen lokaal getest) |
| Previews niet indexeerbaar | `vercel.json` zet `X-Robots-Tag: noindex, nofollow` op elke `*.vercel.app`-host (ook het productie-alias, bedoeld); lokaal kan dat niet worden getest en live niet vanuit deze omgeving. Controle: `curl -I https://nl-noodpakket.vercel.app` |
| Productie indexeerbaar | geen `noindex` in de HTML (`robotsMeta` leeg), geen X-Robots-Tag op het eigen domein |

## AI-crawlers en firewall

Live niet getest (zie boven). **Controlelijst voor jou in het Vercel-dashboard** (ik wijzig geen accountinstellingen): Project, Firewall.
1. Staat "Bot Protection" (challenge) uit of op "log"? Een challenge kan crawlers blokkeren.
2. Staat de managed ruleset voor **AI-bots** (indien aanwezig) op "deny"? Dan worden AI-crawlers geweigerd. Zet op "log" of "bypass" als je gevonden wilt worden.
3. Staat er een eigen regel die op user-agent of land blokkeert?
4. Test na livegang met `curl -sI -A "Mozilla/5.0 (compatible; GPTBot/1.0)" https://nl-noodpakketapp.nl/` per bot; verwacht overal `200`.
5. Let op: ik kon de huidige Vercel-documentatie hierover niet lezen; de namen en standaardwaarden van deze instellingen kunnen zijn gewijzigd.

## Consistentie met de store-listings

De volledige listing staat niet in de repo. Vergelijking met het enige beschikbare concept (README van de app, regel 310):

| Onderdeel | README-concept (store) | Site |
|---|---|---|
| Naam | NL-Noodpakket | NL-Noodpakket |
| Gratis | checklist, alle noodgevallen-stappenplannen, noodplan, **noodmodus**, kluis tot 3 documenten | checklist, houdbaarheidsoverzicht, alle stappenplannen, noodplan, **noodmodus**, kluis tot 3 documenten |
| Pro | eenmalig; noodhacks, "automatische herinneringen voor items die aan vervanging toe zijn", onbeperkt documenten | eenmalig, geen abonnement; noodhacks, vervangherinneringen, onbeperkt documenten |
| Prijs | README: €3,99 (App Store/Play tonen de prijs) | site noemt bewust geen prijs |
| Definitiezin | niet in de repo | in `site.ts` (identiek aan de zin uit de opdracht) |
| Contact in de app-teksten | `docs/privacy.html` en `docs/terms.html` in de app-repo noemen een GitHub-issue | site: e-mailadres |

**Afwijking A1 (belangrijk):** de app-README zegt twee keer dat de **noodmodus nog niet in de app bestaat**; de code bevat hem ook niet. De site, `llms.txt` en het eerste changelog-item noemen hem wel. Dat is een bewering die niet is onderbouwd en die AI-assistenten kunnen overnemen. Zie `FEATURES.noodmodus` in `site.ts`.
**Afwijking A2:** de privacy- en voorwaardenpagina's op GitHub Pages (`docs/`) hebben een ander contactkanaal dan de site. Als de winkels naar die pagina's verwijzen, zijn er twee versies van het beleid.


---

# Na de optimalisatie

Zelfde metingen, zelfde omgeving (lokale productiebuild, Lighthouse mobiel, 19 november 2026). Lighthouse is een laboratoriummeting met ruis van enkele punten per run; echte veldmetingen (CrUX) komen pas na verkeer beschikbaar en INP is in het lab niet te meten.

## Lighthouse mobiel, na

| Pagina | Prestaties | Toegankelijkheid | Best practices | SEO | LCP | TBT | CLS | Overdracht (voor → na) |
|---|---|---|---|---|---|---|---|---|
| / | 100 | 100 | 100 | 100 | 1,2 s | 0 ms | 0 | 527 → 216 KiB |
| /veelgestelde-vragen | 100 | 100 | 100 | 100 | 0,9 s | 0 ms | 0 | 449 → 135 KiB |
| /bronnen | 99 | 100 | 100 | 100 | 2,0 s | 0 ms | 0 | 490 → 176 KiB |
| /privacy | 100 | 100 | 100 | 100 | 0,9 s | 0 ms | 0 | 445 → 131 KiB |
| /voorwaarden | 100 | 100 | 100 | 100 | 0,9 s | 0 ms | 0 | 442 → 128 KiB |
| /wijzigingen | 100 | 100 | 100 | 100 | 0,9 s | 0 ms | 0 | 438 → 124 KiB |
| /contact | 100 | 100 | 100 | 100 | 0,9 s | 0 ms | 0 | 438 → 124 KiB |
| /404 | 100 | 100 | 100 | 66 | 0,9 s | 0 ms | 0 | 436 → 122 KiB |

Elke pagina: alle vier de scores 99–100, behalve de 404 (SEO 66: HTTP 404 met `noindex`, bedoeld). Core Web Vitals in het lab: LCP 0,9–2,0 s (doel ≤ 2,5 s), CLS 0 (doel ≤ 0,1), TBT 0 ms. `/bronnen` meette in deze run 2,0 s LCP (lange tekstpagina, run-ruis); in de eerste meting was dat 1,2 s.

## Per pagina, na

| Pagina | Title | Description | H1 | Interne links in `main` | Binnenkomende links | Woorden | JSON-LD |
|---|---|---|---|---|---|---|---|
| `/404` | 36 | 70 | 1 | 4 | 0 | 24 | Organization, BreadcrumbList |
| `/bronnen` | 56 | 137 | 1 | 4 | 7 | 744 | Organization, BreadcrumbList |
| `/contact` | 34 | 126 | 1 | 3 | 7 | 104 | Organization, BreadcrumbList |
| `/` | 46 | 130 | 1 | 6 | 7 | 821 | Organization, WebSite, MobileApplication |
| `/privacy` | 29 | 139 | 1 | 4 | 7 | 1228 | Organization, BreadcrumbList |
| `/veelgestelde-vragen` | 54 | 139 | 1 | 4 | 7 | 484 | Organization, BreadcrumbList, FAQPage |
| `/voorwaarden` | 35 | 133 | 1 | 4 | 7 | 766 | Organization, BreadcrumbList |
| `/wijzigingen` | 38 | 116 | 1 | 2 | 7 | 128 | Organization, BreadcrumbList |

## Wat is opgelost

| Bevinding | Oplossing | Resultaat |
|---|---|---|
| **P1** 295 KiB JavaScript op elke pagina (React voor het menu) | Mobiel menu als native HTML-`popover`; `@astrojs/react`, React, Radix en de shadcn-componenten verwijderd | **0 JS-bestanden** (`tests/seo.mjs`); overdracht per pagina ruim 300 KiB lager; CSP kan `script-src 'self'; style-src 'self'` zijn |
| **P2** Weinig interne links | Home verwijst naar bronnen, wijzigingen, privacy, voorwaarden, contact en FAQ met beschrijvende ankers; FAQ, bronnen en contact linken onderling; FAQ-antwoorden linken naar bronnen, privacy en prijzen | Home: 3 → 6 interne links in de inhoud; FAQ en bronnen: 3 en 2 → 4 |
| **P3** Kopstructuur | FAQ-vragen zijn koppen (`h2` op de FAQ-pagina, `h3` op home); de verborgen H3 "Zo ziet de app eruit" is een zichtbare H2 | Logische structuur; axe geeft geen bevindingen |
| **P4** Sitemap zonder `lastmod` | `lastmod` voor home, FAQ, bronnen, privacy, voorwaarden (bijgehouden datums) en wijzigingen (laatste release); niet voor contact (geen betrouwbare datum) | 6 van 7 URL's met `lastmod` |
| **P5** robots.txt | Expliciete regels per zoek-, ophaal- en trainingsbot, sitemap-verwijzing, schakelaar `SPERR_TRAINING`, afweging in de README, bronnen en "niet geverifieerd" per bot gedocumenteerd | Getest: Googlebot en alle genoemde bots toegestaan, geen `Disallow: /` |
| **P6** Structured data | WebSite toegevoegd (zonder zoekactie); MobileApplication met `installUrl`, `sameAs` (store-pagina's), `featureList`, `isAccessibleForFree`; Organization met `contactPoint` | Geldig JSON-LD; FAQPage-tekst komt één op één overeen met de zichtbare tekst (getest) |
| **P7** Eén bron voor tekst | `src/config/content.ts` (functies, gratis/Pro, stappen, wat de app niet doet, prijs); `llms.txt` en home lezen daaruit | `tests/seo.mjs` bewaakt de definitiezin op home, in JSON-LD en in `llms.txt` |
| **P8** Inhoud | Sectie "Zo werkt het" (drie stappen) en de nuance dat de app voor voorbereiding op een rustig moment is; titels en descriptions afgestemd op de zoekintentie (`docs/seo-keywords.md`) | Home 646 → 821 woorden |
| Orphan pages | geen (alleen de bewust ongelinkte 404) | |
| HTML-validatie | de uitzondering `element-permitted-content` kon weer aan | alle regels aan, geen bevindingen |

## Wat open blijft en waarom

| Punt | Reden |
|---|---|
| Live statuscodes, redirects, robots.txt en `noindex` op productie en previews | De bouwomgeving bereikt de live site niet (`curl` geeft `000`, DNS in de fetch-tool). Staat in `docs/SEO_LAUNCH_CHECKLIST.md` met de exacte `curl`-opdrachten. Wel getest: de `vercel.json`-regel voor `*.vercel.app` matcht previews en matcht het eigen domein niet (`tests/seo.mjs`) |
| `www`-redirect staat op 307 | Dashboardinstelling; moet 308 zijn (checklist) |
| Vercel Firewall / bot-bescherming | Alleen jij kunt het dashboard bekijken; controlelijst staat hierboven |
| Externe links | Geen netwerk: `node tests/links.mjs --external` na livegang |
| Botnamen van OpenAI, Google, Perplexity en Apple | Documentatie onbereikbaar; in `robots.txt.ts` gemarkeerd als "niet geverifieerd". Alleen Anthropic is gelezen (19-11-2026) |
| Dat Google sinds 7 mei 2026 geen FAQ-rich results meer toont | Niet verifieerbaar (documentatie onbereikbaar). De markup blijft omdat hij exact overeenkomt met de zichtbare tekst |
| Core Web Vitals-veldgegevens (INP, LCP, CLS bij echte gebruikers) | Bestaan pas na verkeer; zie Search Console na 2 tot 4 weken |
| **A1: noodmodus** staat op de site maar niet in de app (code en app-README) | Jouw beslissing: zet `FEATURES.noodmodus = false` in `site.ts` en pas het eerste changelog-item aan (`src/content/wijzigingen/1.0.14.md`), of publiceer eerst de functie |
| **A2: twee versies van privacy en voorwaarden** (GitHub Pages in `docs/` en de site) | Kies één URL voor de winkels (checklist, stap 3) |
| Volledige store-listings vergelijken | Niet in de repo; controleer definitiezin en gratis/Pro-omschrijving met `src/config/site.ts` en `content.ts` |

## Bewust niet gedaan

- Geen AI-specifieke pagina's, Markdown-kopieën, verborgen tekst voor bots, kunstmatig opgeknipte tekst of instructies aan AI in de pagina's (cloaking of nutteloos).
- Geen Review- of aggregateRating-markup (er zijn geen echte, zichtbare reviews); `tests/seo.mjs` bewaakt dat.
- Geen noodadvies-artikelen of stappenplannen op de site (ook niet voor "stroomstoring voorbereiden"): de site verwijst naar de officiële bronnen.
- Geen analytics of tracking; meten via Search Console en handmatige tests (`docs/GEO_MONITORING.md`).
- Geen extra werk aan `llms.txt`: het bestand blijft staan, kort en gelijk aan de site; er is geen effect te verwachten.
- Geen zoekvolumes verzonnen (`docs/seo-keywords.md`).
- Geen `sameAs`-links naar bedrijfsprofielen: er zijn er (voor zover bekend) geen.
- Geen Vercel-instellingen of accountinstellingen gewijzigd.
