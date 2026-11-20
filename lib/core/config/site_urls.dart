/// Eén plek voor de URL's van de website van NL-Noodpakket.
///
/// Conventie: https, hoofddomein zonder www, paden zonder slash aan het eind
/// (alleen de homepage eindigt op "/"). Deze waarden moeten gelijk zijn aan
/// noodpakket-website/src/config/site.ts en STORE_URLS.md; het script
/// `node tool/check_site_urls.mjs` bewaakt dat. Gebruik nergens anders in de app
/// losse website-URL's.
const siteBaseUrl = 'https://nl-noodpakketapp.nl';

abstract final class SitePaths {
  static const home = '/';
  static const privacy = '/privacy';
  static const contact = '/contact';
  static const terms = '/voorwaarden';
  static const sources = '/bronnen';
  static const faq = '/veelgestelde-vragen';
  static const changes = '/wijzigingen';
}

/// Volledige URL bij een pad uit [SitePaths].
String siteUrl(String path) => '$siteBaseUrl$path';
