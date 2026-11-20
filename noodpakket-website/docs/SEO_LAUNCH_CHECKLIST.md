# SEO-lanceringschecklist (wat jij zelf moet doen)

Dit kan ik niet voor je doen: ze vragen een account of toegang tot jouw systemen. Vink af en noteer de datum.

## 1. Domein en redirects (Vercel)

- [ ] `nl-noodpakketapp.nl` serveert de site, `www.nl-noodpakketapp.nl` verwijst door naar het hoofddomein met **308 Permanent Redirect** (nu staat de www-redirect op 307).
- [ ] `https://nl-noodpakketapp.nl/`, `/robots.txt`, `/sitemap-index.xml` en `/llms.txt` geven `200`; `http://` gaat naar `https://`; `/privacy/` (met slash) gaat naar `/privacy`.
- [ ] Controleer in het Vercel-dashboard onder Firewall dat bot-bescherming of een AI-botregel crawlers niet blokkeert (zie `SEO_GEO_AUDIT.md`).
- [ ] Test met user-agents (verwacht overal `200`):
  `curl -sI -A "Mozilla/5.0 (compatible; Googlebot/2.1)" https://nl-noodpakketapp.nl/` en dezelfde opdracht met `GPTBot`, `OAI-SearchBot`, `ChatGPT-User`, `ClaudeBot`, `Claude-SearchBot`, `Claude-User` en `PerplexityBot`.
- [ ] Controleer dat een previewdeploy `X-Robots-Tag: noindex, nofollow` heeft (`curl -I https://<preview>.vercel.app`) en het eigen domein niet.

## 2. Google Search Console en Bing Webmaster Tools

- [ ] Search Console: voeg een **domeineigenschap** toe (`nl-noodpakketapp.nl`) en verifieer met een DNS-TXT-record bij je domeinregistrar.
- [ ] Dien `https://nl-noodpakketapp.nl/sitemap-index.xml` in en controleer onder Sitemaps dat alle 7 URL's zijn gevonden.
- [ ] Gebruik URL-inspectie voor `/`, `/veelgestelde-vragen` en `/bronnen`: "Indexering aanvragen".
- [ ] Bing Webmaster Tools: importeer de site uit Search Console (of verifieer via DNS) en dien dezelfde sitemap in. Bing voedt ook Copilot en andere diensten.
- [ ] Zet e-mailmeldingen aan voor indexeringsproblemen.

## 3. App Store Connect en Google Play Console

- [ ] **Ondersteunings-URL (support):** `https://nl-noodpakketapp.nl/contact`
- [ ] **Marketing-URL / website:** `https://nl-noodpakketapp.nl/`
- [ ] **Privacybeleid-URL:** `https://nl-noodpakketapp.nl/privacy` (nu verwijzen de winkels mogelijk naar de GitHub Pages-versie in `docs/`; zet er één versie neer)
- [ ] Gebruiksvoorwaarden (indien gevraagd): `https://nl-noodpakketapp.nl/voorwaarden`
- [ ] Gebruik in beide winkels dezelfde definitiezin als op de site (`src/config/site.ts`), dezelfde naam "NL-Noodpakket" en dezelfde gratis/Pro-omschrijving (`src/config/content.ts`).
- [ ] Noem de **noodmodus** alleen in de listing en op de site als hij in de gepubliceerde app zit (nu staat hij nog niet in de app-code).
- [ ] Zet in beide listings de vermelding "niet van de overheid".

## 4. Consistente bedrijfsgegevens

- [ ] Zelfde naam (GymWiki), KVK-nummer (97351911), vestigingsplaats (Zwolle) en e-mailadres op: de site, App Store Connect, Play Console, het KVK-register, Google Bedrijfsprofiel (alleen als je een publiek adres hebt; geen privéadres) en sociale profielen.
- [ ] Gebruik een **zakelijk** e-mailadres op je eigen domein als dat kan (nu `gymwiki25@gmail.com`).
- [ ] Voeg `sameAs`-links in de structured data pas toe als zulke bedrijfsprofielen echt bestaan (`src/lib/seo.ts`).

## 5. Echte vermeldingen (geen betaalde links)

- [ ] Maak een lijst van Nederlandse sites, blogs en nieuwsbrieven die over zelfredzaamheid, noodvoorbereiding, gezinnen of apps schrijven.
- [ ] Stuur een korte, eerlijke e-mail met wat de app is en wat niet, de store-link en een aanbod voor vragen. Vraag niet om een link, bied geen betaling of cadeau voor een positieve tekst.
- [ ] Meld de app bij relevante, gratis app-overzichten en catalogi waar je zelf een vermelding kunt plaatsen, zonder dat dit een betaalde link is.
- [ ] Noteer vermeldingen en datum; controleer of de naam en omschrijving kloppen.

## 6. Eerlijke reviewverzoeken

- [ ] Vraag in de app om een review na een succesmoment (bijvoorbeeld nadat iemand een noodplan heeft afgemaakt of gedeeld), niet bij het openen, en met de systeemfunctie van iOS/Android.
- [ ] Beloon reviews niet, stuur niet op een score en gebruik geen nepaccounts.
- [ ] Zet geen `aggregateRating`/`Review`-markup op de site zolang er geen echte, zichtbare reviews op de pagina staan.

## 7. Na 2 tot 4 weken controleren

- [ ] Search Console, Pagina's: staan alle 7 pagina's als "Geïndexeerd"? Zijn er uitgesloten pagina's of fouten?
- [ ] Prestaties, Zoekopdrachten: welke zoekopdrachten leveren vertoningen en klikken op? Vul `docs/seo-keywords.md` aan met echte gegevens.
- [ ] Core Web Vitals (veldgegevens): LCP ≤ 2,5 s, INP ≤ 200 ms, CLS ≤ 0,1 op het 75e percentiel. Veldgegevens verschijnen pas na voldoende verkeer.
- [ ] Draai `docs/GEO_MONITORING.md` voor het eerst en herhaal maandelijks.
- [ ] Draai `node tests/seo.mjs`, `tests/e2e.mjs` en `tests/lighthouse.mjs` opnieuw na elke inhoudelijke wijziging.
