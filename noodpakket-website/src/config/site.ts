/**
 * Eén centraal configbestand. Alles wat nog moet worden ingevuld staat als TODO
 * (zie ook de checklist in README.md).
 */

// TODO: definitieve domeinnaam invullen (zonder slash aan het eind).
export const SITE_URL = "https://noodpakket.example";

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
  appStore: "https://apps.apple.com/nl/app/nl-noodpakket/id6757681584", // niet verifieerbaar vanuit de bouwomgeving: controleren
  // TODO: Google Play-link invullen zodra de app live staat.
  // Voorbeeld: https://play.google.com/store/apps/details?id=nl.example.app
  googlePlay: "" as string,
} as const;

export const COMPANY = {
  provider: "GymWiki",
  // TODO: bevestigen dat deze bedrijfsgegevens kloppen.
  kvk: "97351911",
  city: "Zwolle",
  // TODO: definitief supportadres invullen (geen privéadres).
  email: "support@noodpakket.example",
  /** Zolang true toont de site 'nog in te vullen'-markeringen bij het e-mailadres. */
  emailIsPlaceholder: true,
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

export const NAV = [
  { href: "/", label: "Home" },
  { href: "/veelgestelde-vragen", label: "Veelgestelde vragen" },
  { href: "/bronnen", label: "Bronnen" },
  { href: "/wijzigingen", label: "Wijzigingen" },
  { href: "/contact", label: "Contact" },
] as const;

export const LEGAL_NAV = [
  { href: "/privacy", label: "Privacybeleid" },
  { href: "/voorwaarden", label: "Voorwaarden" },
] as const;

export const GOV_STATEMENT =
  "NL-Noodpakket is een onafhankelijke app en website. Wij vertegenwoordigen de Nederlandse overheid niet en zijn niet gemaakt door of in opdracht van de overheid, NL-Alert of Denk Vooruit. Namen van instanties noemen we alleen om de herkomst van informatie aan te geven.";
