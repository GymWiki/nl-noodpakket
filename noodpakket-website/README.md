# NL-Noodpakket website

Statische marketing- en informatiesite voor de app NL-Noodpakket (nl-NL). Astro 7 (statische output, zero-JS standaard), Tailwind CSS v4, shadcn/ui (React-island alleen voor het mobiele menu), Lucide-iconen, zelf gehoste lettertypen via Fontsource.

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
- `src/pages/`: home, `veelgestelde-vragen`, `bronnen`, `privacy`, `voorwaarden`, `wijzigingen`, `contact`, `404`, `llms.txt`, `robots.txt`, `og/[slug].png` (gegenereerd 1200×630).
- `src/content/wijzigingen/*.md`: één bestand per release (`version`, `date`, optioneel `title`). Nieuwe release = nieuw bestand.
- `src/data/faq.ts`: FAQ-inhoud voor pagina, home en FAQPage JSON-LD. `src/data/sources.ts`: bronnenlijst.
- `src/assets/screenshots/*.webp`: uitgesneden appschermen (zie `scripts/crop-screenshots.mjs`), getoond in `PhoneFrame.astro` (eigen CSS-telefoonkader) via Astro Image.

## Bewuste keuzes

- De FAQ gebruikt native `<details>` in plaats van een React-accordion: de antwoorden staan dan altijd in de HTML (beter voor zoekmachines en AI-assistenten, werkt zonder JS). Radix rendert dichtgeklapte inhoud niet server-side.
- Hero-animatie: een subtiele CSS-animatie (uit bij `prefers-reduced-motion`), geen Magic UI nodig.
- Lucide: `@lucide/astro` voor statische iconen, `lucide-react` alleen in het menu-island.
- `shadcn init` genereerde imports van een npm-pakket `cn`; die zijn vervangen door `@/lib/utils` (clsx + tailwind-merge) en het pakket is verwijderd.
- `html-validate`: regel `element-permitted-content` staat uit omdat Astro zelf een `<style>` voor `astro-island` in de body zet.
- Het HTML-commentaar "jurist controleert dit" staat in de `.astro`-bronbestanden van privacy en voorwaarden en komt niet in de gebouwde HTML.

## Licenties (alles MIT, ISC of OFL)

| Onderdeel | Licentie |
|---|---|
| Astro, @astrojs/react, @astrojs/sitemap, @astrojs/check | MIT |
| Tailwind CSS, @tailwindcss/vite, tw-animate-css | MIT |
| React, React DOM | MIT |
| shadcn/ui (code in `src/components/ui`), `shadcn` CLI, radix-ui | MIT |
| class-variance-authority, clsx, tailwind-merge | Apache-2.0 / MIT / MIT |
| Lucide (`@lucide/astro`, `lucide-react`) | ISC |
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
NODE_PATH=<pad naar playwright> node tests/e2e.mjs   # 360/768/1280, licht+donker, tekst 200%, browserzoom, CSP, menu, axe
CHROME_PATH=<chromium> node tests/lighthouse.mjs     # Lighthouse mobiel, alle pagina's
```

## Store-badges

- **Apple:** `src/assets/badges/app-store.svg` is de officiële zwarte "Download on the App Store"-badge van developer.apple.com, ongewijzigd (48 px hoog, minimaal 40 px; vrije ruimte ¼ van de hoogte via de tussenruimte). Apple levert ook een Nederlandse variant ("Download in de App Store"); download die via Apple Marketing Tools en vervang het bestand (zelfde naam). Alleen de woorden "Download in de" zijn vertaald, "App Store" blijft Engels.
- **Google Play:** `src/assets/badges/google-play.svg` is de officiële Nederlandse badge ("Ontdek het op Google Play"), ongewijzigd aangeleverd. Niet aanpassen; volg Googles richtlijnen voor minimale grootte en vrije ruimte. Staat het bestand er niet, dan toont `DownloadButtons.astro` een neutrale tekstknop.

## Statistieken later toevoegen (niet gebouwd)

Er is bewust geen analytics. Wil je later cookieloze, privacyvriendelijke statistieken: kies een dienst zonder cookies en zonder persoonsgegevens (bijvoorbeeld Plausible, Umami of Vercel Web Analytics), voeg één scripttag toe in `BaseLayout.astro`, sta de scripthost toe in `script-src`/`connect-src` van de CSP in `vercel.json` én in `astro.config.mjs` (`security.csp`), werk het privacybeleid (sectie 9) bij en controleer of er dan alsnog een cookiebanner nodig is.

## Deployen op Vercel

Niet automatisch gedaan: geen accounts, projecten of tokens aangemaakt.

1. Zet de repo op GitHub en koppel die aan je Vercel-team (**Pro-team**, zie onder).
2. Vercel → Add New → Project → importeer de repo. Root Directory: `noodpakket-website`.
3. Framework preset: **Astro**. Build command: `npm run build`. Output directory: `dist`. (Geen adapter; de site is statisch.) Node-versie volgt `engines`.
4. Domein: Project → Settings → Domains → voeg het apex-domein en `www.` toe. Gebruik de DNS-waarden **precies zoals Vercel ze toont**. Stel `www` in als doorverwijzing naar het apex-domein (de redirect staat ook in `vercel.json`; pas daar de hostnaam aan).
5. Vul de TODO's hieronder in en deploy opnieuw.
6. Controlelijst na livegang: HTTPS actief; `/sitemap-index.xml` en `/robots.txt` bereikbaar; `/llms.txt` bereikbaar; Lighthouse en JSON-LD (Rich Results Test) op de live URL; `www` verwijst naar apex; headers (securityheaders.com); de CSP geeft geen console-fouten; Search Console: sitemap indienen.

**Hobbyplan:** het Hobby-plan van Vercel is alleen voor niet-commercieel persoonlijk gebruik. Deze site hoort op een Pro-team.

**Previews niet indexeren:** Vercel zet naar verluidt standaard `noindex` op previewdeployments, maar dat kon vanuit de bouwomgeving niet in de actuele documentatie worden gecontroleerd. Daarom staat er in `vercel.json` ook een `X-Robots-Tag: noindex, nofollow` voor alle `*.vercel.app`-hosts. Controleer na de eerste preview met `curl -I`. Let op: staat het productiedomein óók op `*.vercel.app` alleen, dan wordt het dus niet geïndexeerd; zodra een eigen domein is gekoppeld is dat geen probleem.

**CSP:** Astro schrijft per pagina een `<meta>`-CSP met hashes voor eigen scripts en stijlen. De header in `vercel.json` staat daarom `'unsafe-inline'` toe voor script/style; de meta-CSP maakt het effectief strikt (beide moeten slagen). Getest met Playwright: geen CSP-overtredingen.

## Juridisch

`/privacy` en `/voorwaarden` zijn **concepten**. Een jurist moet ze controleren voordat de site live gaat (zie ook HTML-commentaar in `src/pages/privacy.astro` en `voorwaarden.astro`).

## TODO-checklist (nog in te vullen of te controleren)

- [x] **Domeinnaam**: `nl-noodpakketapp.nl` staat in `SITE_URL` en de www-redirect. Nog in Vercel koppelen (Settings, Domains, apex en www, DNS precies zoals Vercel toont).
- [ ] **Supportadres**: `COMPANY.email` in `site.ts`; daarna `emailIsPlaceholder` op `false`.
- [ ] **Bedrijfsgegevens bevestigen**: GymWiki, KVK 97351911, Zwolle.
- [ ] Store-links staan in `STORES` (site.ts); controleer dat beide live werken (niet te testen vanuit de bouwomgeving).
- [ ] Optioneel: de Nederlandse Apple-badge ("Download in de App Store") vervangen (zie Store-badges).
- [ ] **Noodmodus**: staat in de opdracht, maar niet in de app-code (v1.0.14) of de app-README. Zet `FEATURES.noodmodus` op `false` en pas `src/content/wijzigingen/1.0.14.md` aan als het onderdeel nog niet is gepubliceerd.
- [ ] **Wijzigingenlijst**: versienummer en releasedatum van het eerste item (`1.0.14.md`, nu 19 nov. 2026).
- [ ] **Bronnenlijst** bevestigen (afgeleid uit de app-JSON plus crisis.nl) en **alle externe links controleren** (`node tests/links.mjs --external` met netwerktoegang).
- [ ] **Juridische controle** privacy en voorwaarden. In-app privacytekst noemt nog een GitHub-issue als contact; de site gebruikt e-mail. Houd beide gelijk.
- [ ] Datums `lastUpdated` / `legalUpdated` in `site.ts` bijwerken bij inhoudelijke wijzigingen.
- [ ] Lighthouse en JSON-LD opnieuw op de live URL.
