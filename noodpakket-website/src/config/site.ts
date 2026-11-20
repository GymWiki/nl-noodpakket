/**
 * Eén centraal configbestand. Alles wat nog moet worden ingevuld staat als TODO
 * (zie ook de checklist in README.md).
 */

// Domein: nl-noodpakketapp.nl (nog te koppelen in Vercel; tot die tijd draait de site op nl-noodpakket.vercel.app).
export const SITE_URL = "https://nl-noodpakketapp.nl";

export const SITE = {
  name: "NL-Noodpakket",
  locale: "nl-NL",
  /** Definitiezin: identiek aan de store-listings. */
  definition:
    "NL-Noodpakket is een app voor Nederlandse huishoudens die zich willen voorbereiden op een noodsituatie. De app helpt je stap voor stap een noodpakket samen te stellen, een noodplan te maken en beide bij te houden. Rustig, overzichtelijk en volledig offline.",
  tagline: "Rustig voorbereiden op een noodsituatie, helemaal offline.",
  /** Datum van de laatste inhoudelijke bijwerking van home, FAQ en bronnen (ISO). */
  lastUpdated: "2026-11-19",
  /** Datum laatste wijziging privacybeleid en voorwaarden (ISO). */
  legalUpdated: "2026-11-19",
  /** Huidige appversie volgens pubspec.yaml van de app. */
  appVersion: "1.0.14",
} as const;

export const STORES = {
  appStore: "https://apps.apple.com/nl/app/nl-noodpakket/id6757681584",
  googlePlay: "https://play.google.com/store/apps/details?id=com.mycompany.mijnnoodpakket&hl=nl",
} as const;

export const COMPANY = {
  provider: "GymWiki",
  // Bevestigd door de eigenaar op 19-11-2026.
  kvk: "97351911",
  city: "Zwolle",
  email: "gymwiki25@gmail.com",
  /** Zolang true toont de contactpagina een 'nog in te vullen'-markering bij het e-mailadres. */
  emailIsPlaceholder: false,
} as const;

/**
 * Functies die op de site worden genoemd. Zet een vlag op false als een onderdeel
 * nog niet in de gepubliceerde appversie zit; home, changelog-tekst en llms.txt volgen.
 * TODO: noodmodus staat in de opdracht, maar niet in de app-code (v1.0.14) of de app-README. Controleren.
 */
export const FEATURES = {
  noodmodus: true,
} as const;

export const REPO_URL = "https://github.com/GymWiki/nl-noodpakket";

/**
 * URL-conventie: https, hoofddomein zonder www, paden zonder slash aan het eind (alleen "/" voor home).
 * Deze paden moeten gelijk zijn aan lib/core/config/site_urls.dart (app) en STORE_URLS.md;
 * `node tool/check_site_urls.mjs` in de repo-root bewaakt dat.
 */
export const PATHS = {
  home: "/",
  privacy: "/privacy",
  contact: "/contact",
  terms: "/voorwaarden",
  sources: "/bronnen",
  faq: "/veelgestelde-vragen",
  changes: "/wijzigingen",
} as const;

export const NAV = [
  { href: PATHS.home, label: "Home" },
  { href: PATHS.faq, label: "Veelgestelde vragen" },
  { href: PATHS.sources, label: "Bronnen" },
  { href: PATHS.changes, label: "Wijzigingen" },
  { href: PATHS.contact, label: "Contact" },
] as const;

export const LEGAL_NAV = [
  { href: PATHS.privacy, label: "Privacybeleid" },
  { href: PATHS.terms, label: "Voorwaarden" },
] as const;

export const GOV_STATEMENT =
  "NL-Noodpakket is een onafhankelijke app en website. Wij vertegenwoordigen de Nederlandse overheid niet en zijn niet gemaakt door of in opdracht van de overheid, NL-Alert of Denk Vooruit. Namen van instanties noemen we alleen om de herkomst van informatie aan te geven.";
