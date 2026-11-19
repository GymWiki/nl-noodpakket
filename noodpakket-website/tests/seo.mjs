// Controleert SEO/GEO-afspraken op dist/ en de config. Gebruik: node tests/seo.mjs
import fs from "node:fs";
import path from "node:path";
let bad = 0;
const err = (m) => { bad++; console.error("FAIL", m); };
const ok = (m) => console.log("ok  ", m);
const read = (f) => fs.readFileSync(f, "utf8");
const decode = (s) => s.replace(/&amp;/g, "&").replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, "<").replace(/&gt;/g, ">");
const text = (h) => decode(h.replace(/<(script|style)[\s\S]*?<\/\1>/g, " ").replace(/<[^>]+>/g, " ")).replace(/\s+/g, " ").trim();
const site = read("src/config/site.ts");
const SITE_URL = site.match(/SITE_URL = "([^"]+)"/)[1];
const definition = site.match(/definition:\s*\n?\s*"([^"]+)"/)[1];
const pages = fs.readdirSync("dist").filter((f) => f.endsWith(".html"));

// 1. Canonical = sitemap-URL; sitemap bevat alleen indexeerbare pagina's
const sm = [...read("dist/sitemap-0.xml").matchAll(/<loc>(.*?)<\/loc>/g)].map((m) => m[1]);
for (const f of pages) {
  const html = read(`dist/${f}`);
  const p = f === "index.html" ? "/" : "/" + f.replace(/\.html$/, "");
  const canon = html.match(/rel="canonical" href="(.*?)"/)?.[1];
  const expected = SITE_URL + (p === "/" ? "/" : p);
  if (canon !== expected) err(`${f}: canonical ${canon} != ${expected}`);
  const noindex = /<meta name="robots" content="[^"]*noindex/.test(html);
  if (noindex && sm.includes(expected)) err(`${f}: noindex-pagina staat in de sitemap`);
  if (!noindex && !sm.includes(expected)) err(`${f}: indexeerbare pagina ontbreekt in de sitemap`);
  if (p === "/" && noindex) err("home staat op noindex");
}
for (const u of sm) if (!u.startsWith(SITE_URL)) err(`sitemap-URL buiten de site: ${u}`);
ok(`canonicals en sitemap (${sm.length} URL's)`);

// 2. Definitiezin: home (zichtbaar), JSON-LD, llms.txt
const home = read("dist/index.html");
if (!text(home).includes(definition)) err("definitiezin niet zichtbaar op home");
if (!home.includes(JSON.stringify(definition).slice(1, -1))) err("definitiezin niet in MobileApplication JSON-LD");
if (!read("dist/llms.txt").includes(definition)) err("definitiezin niet in llms.txt");
ok("definitiezin gelijk op home, JSON-LD en llms.txt");

// 3. FAQ: JSON-LD komt één op één overeen met de zichtbare vragen en antwoorden
const faqHtml = read("dist/veelgestelde-vragen.html");
const ld = [...faqHtml.matchAll(/<script type="application\/ld\+json">(.*?)<\/script>/gs)].map((m) => JSON.parse(m[1])).find((j) => j["@type"] === "FAQPage");
const visible = [...faqHtml.matchAll(/<details[^>]*>\s*<summary[^>]*>([\s\S]*?)<\/summary>\s*<p[^>]*>([\s\S]*?)<\/p>/g)].map((m) => ({ q: decode(m[1].replace(/<[^>]+>/g, "")).replace(/\s+/g, " ").trim(), a: decode(m[2].replace(/<[^>]+>/g, "")).replace(/\s+/g, " ").trim() }));
if (!ld || ld.mainEntity.length !== visible.length) err(`FAQ: ${ld?.mainEntity.length} in JSON-LD, ${visible.length} zichtbaar`);
else ld.mainEntity.forEach((e, i) => { if (e.name !== visible[i].q || e.acceptedAnswer.text !== visible[i].a) err(`FAQ ${i + 1} wijkt af tussen JSON-LD en zichtbare tekst: "${visible[i].q}"`); });
ok(`FAQPage: ${visible.length} vragen komen overeen met de zichtbare tekst`);

// 4. Geen Review/aggregateRating zonder echte reviews
for (const f of pages) if (/aggregateRating|"Review"/.test(read(`dist/${f}`))) err(`${f}: Review/aggregateRating-markup gevonden`);
ok("geen Review/aggregateRating-markup");

// 5. robots.txt: Googlebot en alle genoemde bots toegestaan, sitemap-verwijzing, geen Disallow: /
const robots = read("dist/robots.txt");
for (const ua of ["*", "Googlebot", "Bingbot", "OAI-SearchBot", "ChatGPT-User", "GPTBot", "Claude-SearchBot", "Claude-User", "ClaudeBot", "PerplexityBot", "Perplexity-User", "CCBot", "Google-Extended", "Applebot-Extended"]) if (!new RegExp(`User-agent: ${ua.replace("*", "\\*")}\nAllow: /`).test(robots)) err(`robots.txt: ${ua} niet expliciet toegestaan`);
if (/^Disallow:\s*\/\s*$/m.test(robots)) err("robots.txt bevat een actieve 'Disallow: /'");
if (!robots.includes(`Sitemap: ${SITE_URL}/sitemap-index.xml`)) err("robots.txt mist de sitemap-verwijzing");
ok("robots.txt");

// 6. Previews niet indexeerbaar, productie wel (vercel.json)
const v = JSON.parse(read("vercel.json"));
const rule = v.headers.find((h) => h.headers.some((x) => x.key === "X-Robots-Tag"));
const hostRe = new RegExp("^" + rule.has[0].value.replace("(?<host>", "(?<host>") + "$");
if (!hostRe.test("nl-noodpakket-git-x-team.vercel.app")) err("preview-host valt niet onder de noindex-regel");
if (hostRe.test(new URL(SITE_URL).host) || hostRe.test("www." + new URL(SITE_URL).host)) err("het eigen domein valt onder de noindex-regel");
if (v.headers.some((h) => !h.has && h.headers.some((x) => x.key === "X-Robots-Tag"))) err("X-Robots-Tag staat ook op productie");
ok("noindex alleen op *.vercel.app");

// 7. Geen hard-gecodeerd domein buiten de config
const host = new URL(SITE_URL).host;
const walk = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(path.join(d, e.name)) : [path.join(d, e.name)]));
for (const f of walk("src").filter((f) => /\.(astro|ts|md)$/.test(f))) if (read(f).includes(host) && !f.endsWith("config/site.ts")) err(`${f}: domein hard gecodeerd`);
ok("geen hard-gecodeerd domein in src/");

// 8. Geen JavaScript-bestanden uitgeleverd
const js = walk("dist").filter((f) => f.endsWith(".js"));
if (js.length) err(`${js.length} JS-bestand(en) in dist/: ${js.join(", ")}`);
ok("0 JavaScript-bestanden in dist/");

// 9. Alt-teksten, afmetingen
for (const f of pages) for (const img of read(`dist/${f}`).matchAll(/<img\b[^>]*>/g)) {
  if (!/ alt[=\s>]/.test(img[0])) err(`${f}: img zonder alt`);
  if (!/ width="/.test(img[0]) || !/ height="/.test(img[0])) err(`${f}: img zonder width/height`);
}
ok("alt en afmetingen op alle afbeeldingen");
// 10. URL-conventie: https, apex zonder www, geen slash aan het eind (behalve home), geen .html; elke interne link wijst naar een bestaande, schone URL
const bareHost = new URL(SITE_URL).host;
if (!SITE_URL.startsWith("https://") || bareHost.startsWith("www.") || SITE_URL.endsWith("/")) err(`SITE_URL ${SITE_URL} volgt de conventie niet (https, zonder www, zonder slash)`);
for (const f of pages) {
  const html = read(`dist/${f}`);
  for (const m of html.matchAll(/<(?:a|link)\b[^>]*\bhref="([^"]+)"/g)) {
    const u = m[1];
    if (/^(mailto:|tel:|#)/.test(u)) continue;
    const internal = u.startsWith("/") || u.startsWith(SITE_URL);
    if (!internal) { if (u.startsWith("http://")) err(`${f}: http-link ${u}`); continue; }
    const p = u.startsWith("/") ? u : u.slice(SITE_URL.length) || "/";
    const clean = p.split("#")[0];
    if (clean.startsWith("/_astro/") || /\.(png|svg|xml|txt|webp)$/.test(clean)) continue;
    if (clean !== "/" && clean.endsWith("/")) err(`${f}: interne link met slash aan het eind: ${u}`);
    if (/\.html$/.test(clean)) err(`${f}: interne link naar .html: ${u}`);
    if (u.startsWith(SITE_URL) && /^https:\/\/www\./.test(u)) err(`${f}: www-link ${u}`);
    const file = clean === "/" ? "dist/index.html" : `dist${clean}.html`;
    if (!fs.existsSync(file)) err(`${f}: link naar niet-bestaande pagina ${u}`);
  }
}
ok("URL-conventie (https, apex, geen slash, geen .html) en interne links");

// 11. Elke pagina uit de sitemap is gelinkt vanuit de footer (op elke pagina)
for (const f of pages) {
  const footer = read(`dist/${f}`).match(/<footer[\s\S]*?<\/footer>/)?.[0] ?? "";
  for (const u of sm) {
    const p = u.slice(SITE_URL.length) || "/";
    if (!footer.includes(`href="${p}"`)) err(`${f}: footer mist een link naar ${p}`);
  }
}
ok("footer linkt naar elke pagina uit de sitemap");

// 12. Eisen per pagina: één unieke title, unieke description, geen placeholders/lorem
const titles = new Map(), descs = new Map();
for (const f of pages) {
  const html = read(`dist/${f}`);
  const t = html.match(/<title>(.*?)<\/title>/)?.[1], d = html.match(/<meta name="description" content="(.*?)"/)?.[1];
  if (titles.has(t)) err(`title niet uniek: ${f} en ${titles.get(t)}`); titles.set(t, f);
  if (descs.has(d)) err(`description niet uniek: ${f} en ${descs.get(d)}`); descs.set(d, f);
  const vis = text(html);
  if (/lorem ipsum|\bTODO\b|noodpakket\.example|placeholder/i.test(vis)) err(`${f}: zichtbare placeholder of TODO in de tekst`);
}
ok("unieke title en description, geen zichtbare placeholders");

console.log(bad ? `${bad} bevindingen` : "SEO OK");
process.exit(bad ? 1 : 0);
