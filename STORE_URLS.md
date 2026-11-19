# URL's en gegevens voor App Store Connect en Play Console

Stand: 19 november 2026. Alles is afgeleid van `noodpakket-website/src/config/site.ts` en `lib/core/config/site_urls.dart`; `python3 tool/check_site_urls.py` controleert dat deze drie plekken, plus dit bestand, gelijk zijn.

**URL-conventie:** `https`, hoofddomein **zonder www**, paden **zonder slash aan het eind** (alleen de homepage eindigt op `/`). Kopieer de URL's precies zo. Elke URL antwoordt direct met 200 (`cleanUrls`); `www.` verwijst door naar het hoofddomein.

**Status:** ➖ = nog niet bevestigd live. De URL's zijn vanuit de bouwomgeving niet op te halen (DNS en proxy), dus ik heb ze niet kunnen controleren. Zie "Wat er nog ontbreekt" onderaan.

## Apple App Store Connect

| Veld | Plek in App Store Connect | Waarde | Status |
|---|---|---|---|
| Privacy Policy URL (verplicht) | App Privacy > Privacy Policy (in nieuwere versies ook onder App Information > Privacy Policy URL) | `https://nl-noodpakketapp.nl/privacy` | ➖ |
| Support URL (verplicht) | Versiepagina > Support URL | `https://nl-noodpakketapp.nl/contact` | ➖ |
| Marketing URL (optioneel) | Versiepagina > Marketing URL | `https://nl-noodpakketapp.nl/` | ➖ |
| License Agreement | App Information > License Agreement | Niets instellen: de standaard-EULA van Apple blijft gelden | n.v.t. |

## Google Play Console

| Veld | Plek in Play Console | Waarde | Status |
|---|---|---|---|
| Privacy policy (verplicht) | Policy and programs > App content > Privacy policy | `https://nl-noodpakketapp.nl/privacy` | ➖ |
| E-mailadres (verplicht) | Grow users > Store presence > Store settings > Store listing contact details > Email address | `gymwiki25@gmail.com` | n.v.t. (adres bevestigd door de eigenaar) |
| Website (optioneel) | Grow users > Store presence > Store settings > Store listing contact details > Website | `https://nl-noodpakketapp.nl/` | ➖ |

## Extra (geen winkelveld)

| Onderdeel | URL | Status |
|---|---|---|
| Voorwaarden (site en app) | `https://nl-noodpakketapp.nl/voorwaarden` | ➖ |
| Bronnen | `https://nl-noodpakketapp.nl/bronnen` | ➖ |

De app verwijst zelf naar deze pagina's onder Meer > Informatie > Over en juridisch.

## Bedrijfsgegevens (bevestigd door de eigenaar op 19-11-2026)

Aanbieder GymWiki, KVK 97351911, Zwolle. Supportadres `gymwiki25@gmail.com` (een Gmail-adres, geen adres op het eigen domein).

## Wat er nog ontbreekt voordat je kunt invullen

1. **Publiceren.** De nieuwe contactpagina (met "Hulp bij de app"), de aangepaste bronnenpagina en de app-wijzigingen staan op de branch `claude/upbeat-keller-5nyng8` en zijn nog niet gepusht, gemerged en gedeployed. Tot die tijd kan de live versie van `/contact` korter zijn.
2. **Live controleren** (➖ wordt ✅): open elke URL hierboven in een privévenster en controleer: laadt zonder inlog, https, direct 200, geen `noindex`. Test ook het adres met www ervoor (moet naar het hoofddomein gaan).
3. **`www`-redirect op 308** zetten in Vercel (Settings, Domains; nu 307).
4. **Juridische controle.** `/privacy` en `/voorwaarden` zijn conceptteksten. Beide winkels verwachten een bruikbaar privacybeleid; laat een jurist de tekst controleren voordat je de winkels indient.
5. **Bevestigen of je een adres op je eigen domein wilt** in plaats van het Gmail-adres (voor Play is het adres publiek zichtbaar in de listing).
6. **In de app:** een nieuwe appversie (met de links naar de website) moet nog worden gebouwd en ingediend; oudere versies verwijzen nog naar de GitHub Pages-versie van het privacybeleid. Overweeg om `docs/privacy.html` en `docs/terms.html` te laten verwijzen naar de website, zodat er één versie van het beleid bestaat.
