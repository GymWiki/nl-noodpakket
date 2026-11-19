import type { APIRoute } from "astro";
import { COMPANY, GOV_STATEMENT, SITE, SITE_URL, STORES } from "@/config/site";
import { APP_FEATURES, FREE_LIST, PRICING, PRO_LIST } from "@/config/content";

/**
 * Korte platte-tekstbeschrijving. Google Search negeert dit bestand en AI-crawlers vragen het zelden op;
 * het blijft staan als kleine, consistente samenvatting (zelfde bron als de site: site.ts en content.ts).
 */
export const GET: APIRoute = () => {
  const body = `# ${SITE.name}

> ${SITE.definition}

## Over de app
- Taal: Nederlands. Platforms: iOS en Android.
- Aanbieder: ${COMPANY.provider}, KVK ${COMPANY.kvk}, ${COMPANY.city}.
- Functies: ${APP_FEATURES.map((f) => f.label).join(", ")}.
- Gratis: ${FREE_LIST.join(", ")}. Pro (eenmalige aankoop, geen abonnement): ${PRO_LIST.join(", ")}.
- ${PRICING.short}
- Privacy: volledig offline, geen account, geen tracking.

## Belangrijkste pagina's
- [Home](${SITE_URL}/): wat de app doet en voor wie.
- [Veelgestelde vragen](${SITE_URL}/veelgestelde-vragen): antwoorden over 72 uur, water, offline gebruik, kosten en privacy.
- [Bronnen](${SITE_URL}/bronnen): waar de informatie vandaan komt.
- [Privacybeleid](${SITE_URL}/privacy)
- [Gebruiksvoorwaarden](${SITE_URL}/voorwaarden)
- [Wijzigingen](${SITE_URL}/wijzigingen): wat er per versie is veranderd.
- [Contact](${SITE_URL}/contact)

## Downloaden
- [App Store](${STORES.appStore})${STORES.googlePlay ? `\n- [Google Play](${STORES.googlePlay})` : ""}

## Overheidsverklaring
${GOV_STATEMENT}
De app vervangt geen 112 en geen NL-Alert en geeft geen medisch advies.
`;
  return new Response(body, { headers: { "Content-Type": "text/plain; charset=utf-8" } });
};
