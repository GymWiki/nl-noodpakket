import type { APIRoute } from "astro";
import { SITE_URL } from "@/config/site";

/**
 * Standaard: alles toestaan, voor zoekmachines en voor de zoek-, ophaal- en trainingsbots van AI-diensten.
 * Googlebot wordt nooit geblokkeerd.
 *
 * Bots en doel (stand 19-11-2026):
 *  - Anthropic (geverifieerd op support.claude.com, 19-11-2026): ClaudeBot = training, Claude-SearchBot = zoekindex, Claude-User = ophalen op verzoek van een gebruiker.
 *  - OpenAI: GPTBot = training, OAI-SearchBot = zoekindex, ChatGPT-User = ophalen op verzoek. NIET opnieuw geverifieerd op 19-11-2026 (documentatie onbereikbaar): controleer platform.openai.com/docs/bots.
 *  - Perplexity: PerplexityBot = zoekindex, Perplexity-User = ophalen op verzoek. NIET geverifieerd op 19-11-2026: controleer docs.perplexity.ai.
 *  - Google: Googlebot = zoeken; Google-Extended is een robots.txt-token (geen aparte crawler) dat gebruik voor Gemini-training en -grounding regelt. NIET geverifieerd op 19-11-2026.
 *  - Apple: Applebot = zoeken (Siri, Spotlight); Applebot-Extended is een token voor AI-training. CCBot = Common Crawl. NIET geverifieerd op 19-11-2026.
 *
 * ALTERNATIEF: alleen training uitsluiten, zoeken en ophalen blijven toegestaan. Zet SPERR_TRAINING op true.
 * Afweging: uitsluiten van training verkleint niet de kans om in antwoorden genoemd te worden via zoekbots, maar de
 * kennis van een model over NL-Noodpakket komt dan alleen uit bronnen die wel toegestaan zijn (store-pagina's, vermeldingen
 * van anderen). Voor een gratis informatieve app zonder verdienmodel in content is toestaan de standaard.
 */
const SPERR_TRAINING = false;

const SEARCH_AND_FETCH = ["Googlebot", "Bingbot", "Applebot", "OAI-SearchBot", "ChatGPT-User", "Claude-SearchBot", "Claude-User", "PerplexityBot", "Perplexity-User"];
const TRAINING = ["GPTBot", "ClaudeBot", "CCBot", "Google-Extended", "Applebot-Extended"];

export const GET: APIRoute = () => {
  const group = (ua: string, rule: string) => `User-agent: ${ua}\n${rule}\n`;
  const lines = [
    "# NL-Noodpakket: alles toestaan, ook AI-zoek- en ophaalbots. Zie src/pages/robots.txt.ts voor de afweging.",
    group("*", "Allow: /"),
    "# Zoek- en ophaalbots (komen alleen langs om pagina's te vinden of op verzoek van een gebruiker te lezen)",
    ...SEARCH_AND_FETCH.map((ua) => group(ua, "Allow: /")),
    `# Trainingsbots${SPERR_TRAINING ? " (uitgesloten)" : " (toegestaan)"}`,
    ...TRAINING.map((ua) => group(ua, SPERR_TRAINING ? "Disallow: /" : "Allow: /")),
    `Sitemap: ${SITE_URL}/sitemap-index.xml`,
    "",
  ];
  return new Response(lines.join("\n"), { headers: { "Content-Type": "text/plain; charset=utf-8" } });
};
