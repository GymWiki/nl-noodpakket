# NL-Noodpakket website

Statische marketing- en informatiesite voor de app NL-Noodpakket (nl-NL). Astro 7 (statische output, **0 KiB JavaScript**: het mobiele menu is een native HTML-popover), Tailwind CSS v4 (de ontwerptokens volgen de shadcn-variabelennamen), Lucide-iconen (`@lucide/astro`), zelf gehoste lettertypen via Fontsource.

> **Niet van de overheid.** Eigen merkstijl; geen logo's, lint, kleuren of lettertypen van de Rijksoverheid, NL-Alert of denkvooruit.nl.

## Starten

```bash
npm install
npm run dev        # ontwikkelserver
npm run build      # productiebuild naar dist/
npm run check      # astro check
```

Node ≥ 22.23.4 (`.node-version`, `engines`).

## Structuur

- `src/config/site.ts`: **alle** URL's, e-mailadres, bedrijfsgegevens, de definitiezin, datums en de functievlag `FEATURES`.
- `src/config/content.ts`: **één bron voor de tekst die op meerdere plekken terugkomt** (functies, gratis/Pro, "zo werkt het", wat de app niet doet, prijsomschrijving). Home, `llms.txt` en de structured data lezen hieruit. Houd dit gelijk aan de store-listings.
- `src/pages/`: home, `veelgestelde-vragen`, `bronnen`, `privacy`, `voorwaarden`, `wijzigingen`, `contact`, `404`, `llms.txt`, `robots.txt`, `og/[slug].png` (gegenereerd 1200×630).
- `src/content/wijzigingen/*.md`: één bestand per release (`version`, `date`, optioneel `title`). Nieuwe release = nieuw bestand.
- `src/data/faq.ts`: FAQ-inhoud voor pagina, home en FAQPage JSON-LD (`tests/seo.mjs` controleert dat markup en zichtbare tekst identiek zijn). `src/data/sources.ts`: bronnenlijst.
- `src/assets/screenshots/*.webp`: uitgesneden appschermen (zie `scripts/crop-screenshots.mjs`), getoond in `PhoneFrame.astro` (eigen CSS-telefoonkader) via Astro Image.

## Logo

Aangeleverd als twee SVG's (ingesloten bitmap). `scripts/prepare-logo.mjs <met-achtergrond.svg> <zonder-achtergrond.svg>` maakt de bestanden:
- **Zonder achtergrond** (`src/assets/logo/logo-transparent.webp`, bijgesneden): header en footer via `Logo.astro`. Werkt op het lichte en het donkere thema.
- **Met achtergrond** (wit vierkant): `public/logo.png` (JSON-LD `logo` en `image`, en het paneel in de OG-beelden), `public/favicon-32.png`, `favicon-192.png` en `apple-touch-icon.png` (die moeten een egale achtergrond hebben).
- Het logo in de header is decoratief (`alt=""`); de naam staat er als tekst naast.

## Bewuste keuzes

- **Geen JavaScript:** de pagina's leveren 0 JS-bestanden. Het mobiele menu is een native `popover` (sluit met Escape en de sluitknop). Een eerdere versie met een React-`Sheet` kostte ~295 KiB JavaScript op elke pagina; die is verwijderd samen met `@astrojs/react`, React, Radix en de shadcn-componenten. Heb je later interactie nodig, voeg dan `@astrojs/react` weer toe en laad een island met `client:visible`.
- De FAQ gebruikt native `<details>`: de antwoorden staan altijd in de HTML (beter voor zoekmachines en AI-assistenten, werkt zonder JS). De vragen zijn koppen (`h2` op de FAQ-pagina, `h3` op home) binnen de `summary`.
- Hero-animatie: een subtiele CSS-animatie (uit bij `prefers-reduced-motion`), geen Magic UI nodig.
- CSP in `vercel.json`: `script-src 'self'; style-src 'self'` (geen inline scripts of stijlen meer nodig).
- `html-validate`: regel `element-permitted-content` staat uit; verwijderen kan nu waarschijnlijk, omdat de `astro-island`-stijl niet meer wordt geplaatst (nog niet opnieuw beoordeeld).
- Het HTML-commentaar "jurist controleert dit" staat in de `.astro`-bronbestanden van privacy en voorwaarden en komt niet in de gebouwde HTML.

## SEO en GEO

GEO is geen apart trucje: wat telt is crawlbaar en indexeerbaar, eerlijke inhoud die de vraag beantwoordt, consistente informatie op alle plekken en echte vermeldingen door anderen. Daarom is er bewust **geen** AI-specifieke variant van pagina's, geen verborgen tekst, geen Markdown-kopieën, geen reviewmarkup zonder echte reviews en geen tracking.

- **robots.txt** (`src/pages/robots.txt.ts`): alles toegestaan, per bot expliciet: zoek- en ophaalbots (Googlebot, Bingbot, Applebot, OAI-SearchBot, ChatGPT-User, Claude-SearchBot, Claude-User, PerplexityBot, Perplexity-User) en trainingsbots (GPTBot, ClaudeBot, CCBot, Google-Extended, Applebot-Extended), plus de sitemap. **Alleen training uitsluiten?** Zet `SPERR_TRAINING = true` in dat bestand; de zoek- en ophaalbots blijven dan toegestaan. Afweging: voor een gratis informatieve app is gevonden worden belangrijker dan training weren; uitsluiten haalt je niet uit AI-zoekresultaten, maar beperkt wel de eigen kennis van modellen. Botnamen: alleen Anthropic is geverifieerd (support.claude.com, 19-11-2026); de overige staan als "niet geverifieerd" in het bestand. Controleer ze periodiek bij OpenAI, Google, Perplexity en Apple.
- **Sitemap:** `@astrojs/sitemap`; `lastmod` alleen voor pagina's met een bijgehouden datum (`src/lib/sitemap.ts`); de 404 staat er niet in.
- **llms.txt:** blijft staan, kort en gelijk aan de site. Google Search negeert het bestand en AI-crawlers vragen het zelden op; verwacht er geen effect van.
- **Consistentie:** naam, definitiezin (`site.ts`) en functie-/prijsomschrijving (`content.ts`) komen uit één bron en worden gecontroleerd in `tests/seo.mjs`.
- **Structured data:** Organization (met `contactPoint`), WebSite (zonder zoekactie, want er is geen zoekfunctie), MobileApplication (met `installUrl` en `sameAs` naar de echte store-pagina's), BreadcrumbList en FAQPage. FAQ-rich results toont Google naar verluidt niet meer (niet kunnen verifiëren); de markup blijft staan omdat hij één op één overeenkomt met de zichtbare vragen en wordt verwijderd zodra dat niet meer zo is.
- Zie `SEO_GEO_AUDIT.md` (metingen voor en na), `docs/seo-keywords.md`, `docs/GEO_MONITORING.md` en `docs/SEO_LAUNCH_CHECKLIST.md`.

## Licenties (alles MIT, ISC of OFL)

| Onderdeel | Licentie |
|---|---|
| Astro, @astrojs/sitemap, @astrojs/check | MIT |
| Tailwind CSS, @tailwindcss/vite | MIT |
| Lucide (`@lucide/astro`) | ISC |
| Plus Jakarta Sans, Inter (Fontsource) | SIL OFL 1.1 |
| sharp | Apache-2.0 |
| Dev-only: satori, @resvg/resvg-js (OG-beelden) | MPL-2.0 (alleen buildtijd, niet uitgeleverd) |
| Dev-only: axe-core, html-validate, lighthouse | MPL-2.0 / MIT / Apache-2.0 |

Controleer licenties opnieuw bij elke nieuwe afhankelijkheid.

## Tests

Alles draait lokaal tegen `dist/` met een kleine server die de headers uit `vercel.json` toepast (`tests/server.mjs`).

```bash
npm run build && npm run check
node tests/html.mjs        # HTML-validatie
node tests/jsonld.mjs      # JSON-LD, title/description, canonical, OG, één h1
node tests/links.mjs --external   # interne links + externe links (extern vereist netwerk)
node tests/seo.mjs         # canonicals/sitemap, definitiezin, FAQ-markup = zichtbare tekst, robots, noindex op previews, geen JS, alt/afmetingen
node tests/audit.mjs [uitvoer.json]   # SEO-audit per pagina (titles, koppen, links, woorden, orphans)
NODE_PATH=<pad naar playwright> node tests/e2e.mjs   # 360/768/1280, licht+donker, tekst 200%, browserzoom, CSP, menu, axe
CHROME_PATH=<chromium> node tests/lighthouse.mjs     # Lighthouse mobiel, alle pagina's
```

## Store-badges

- **Apple:** `src/assets/badges/app-store.svg` is de officiële Nederlandse zwarte badge ("Download in de App Store") van Apple, ongewijzigd (48 px hoog, minimaal 40 px; vrije ruimte ¼ van de hoogte via de tussenruimte).
- **Google Play:** `src/assets/badges/google-play.svg` is de officiële Nederlandse badge ("Ontdek het op Google Play"), ongewijzigd aangeleverd. Niet aanpassen; volg Googles richtlijnen voor minimale grootte en vrije ruimte. Staat het bestand er niet, dan toont `DownloadButtons.astro` een neutrale tekstknop.

## Statistieken later toevoegen (niet gebouwd)

Er is bewust geen analytics. Wil je later cookieloze, privacyvriendelijke statistieken: kies een dienst zonder cookies en zonder persoonsgegevens (bijvoorbeeld Plausible, Umami of Vercel Web Analytics), voeg één scripttag toe in `BaseLayout.astro`, sta de scripthost toe in `script-src`/`connect-src` van de CSP in `vercel.json` én in `astro.config.mjs` (`security.csp`), werk het privacybeleid (sectie 9) bij en controleer of er dan alsnog een cookiebanner nodig is.

## Deployen op Vercel

Niet automatisch gedaan: geen accounts, projecten of tokens aangemaakt.

1. Zet de repo op GitHub en koppel die aan je Vercel-team (**Pro-team**, zie onder).
2. Vercel → Add New → Project → importeer de repo. Root Directory: `noodpakket-website`.
3. Framework preset: **Astro**. Build command: `npm run build`. Output directory: `dist`. (Geen adapter; de site is statisch.) Node-versie volgt `engines`.
4. Domein: Project → Settings → Domains → voeg het apex-domein en `www.` toe. Gebruik de DNS-waarden **precies zoals Vercel ze toont**. Stel `www` in als doorverwijzing naar het apex-domein (de doorverwijzing www naar apex stel je alleen hier in, niet in `vercel.json`: twee tegengestelde redirects geven een lus).
5. Vul de TODO's hieronder in en deploy opnieuw.
6. Controlelijst na livegang: HTTPS actief; `/sitemap-index.xml` en `/robots.txt` bereikbaar; `/llms.txt` bereikbaar; Lighthouse en JSON-LD (Rich Results Test) op de live URL; `www` verwijst naar apex; headers (securityheaders.com); de CSP geeft geen console-fouten; Search Console: sitemap indienen.

**Hobbyplan:** het Hobby-plan van Vercel is alleen voor niet-commercieel persoonlijk gebruik. Deze site hoort op een Pro-team.

**Previews niet indexeren:** Vercel zet naar verluidt standaard `noindex` op previewdeployments, maar dat kon vanuit de bouwomgeving niet in de actuele documentatie worden gecontroleerd. Daarom staat er in `vercel.json` ook een `X-Robots-Tag: noindex, nofollow` voor alle `*.vercel.app`-hosts. Controleer na de eerste preview met `curl -I`. Let op: staat het productiedomein óók op `*.vercel.app` alleen, dan wordt het dus niet geïndexeerd; zodra een eigen domein is gekoppeld is dat geen probleem.

**CSP:** Astro schrijft per pagina een `<meta>`-CSP met hashes voor eigen scripts en stijlen. De header in `vercel.json` staat daarom `'unsafe-inline'` toe voor script/style; de meta-CSP maakt het effectief strikt (beide moeten slagen). Getest met Playwright: geen CSP-overtredingen.

## Juridisch

`/privacy` en `/voorwaarden` zijn **concepten**. Een jurist moet ze controleren voordat de site live gaat (zie ook HTML-commentaar in `src/pages/privacy.astro` en `voorwaarden.astro`).

## TODO-checklist (nog in te vullen of te controleren)

- [x] **Domeinnaam**: `nl-noodpakketapp.nl` staat in `SITE_URL` en is gekoppeld in Vercel. Zet in Vercel (Settings, Domains) `www.nl-noodpakketapp.nl` op "Redirect to nl-noodpakketapp.nl" en het apex-domein op Production (nu staat het omgekeerd).
- [ ] **Bedrijfsgegevens bevestigen**: GymWiki, KVK 97351911, Zwolle.
- [ ] Store-links staan in `STORES` (site.ts); controleer dat beide live werken (niet te testen vanuit de bouwomgeving).
- [ ] **Noodmodus**: staat in de opdracht, maar niet in de app-code (v1.0.14) of de app-README. Zet `FEATURES.noodmodus` op `false` en pas `src/content/wijzigingen/1.0.14.md` aan als het onderdeel nog niet is gepubliceerd.
- [ ] **Wijzigingenlijst**: versienummer en releasedatum van het eerste item (`1.0.14.md`, nu 19 nov. 2026).
- [ ] **Bronnenlijst** bevestigen (afgeleid uit de app-JSON plus crisis.nl) en **alle externe links controleren** (`node tests/links.mjs --external` met netwerktoegang).
- [ ] **Juridische controle** privacy en voorwaarden. In-app privacytekst noemt nog een GitHub-issue als contact; de site gebruikt e-mail. Houd beide gelijk.
- [ ] Datums `lastUpdated` / `legalUpdated` in `site.ts` bijwerken bij inhoudelijke wijzigingen.
- [ ] Lighthouse en JSON-LD opnieuw op de live URL.
