# SEO- en GEO-audit NL-Noodpakket

Gemeten op de lokale productiebuild (`dist/`) van de branch `claude/upbeat-keller-5nyng8`, 19 november 2026. Site-URL uit `src/config/site.ts`: `https://nl-noodpakketapp.nl`. Zie onderaan "Na de optimalisatie" voor de vergelijking.

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
