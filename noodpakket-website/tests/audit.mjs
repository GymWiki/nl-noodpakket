// SEO-audit over dist/: per pagina metadata, koppen, afbeeldingen, links, JSON-LD, woorden, orphans, sitemap, robots.
// Gebruik: node tests/audit.mjs [uitvoer.json]
import fs from "node:fs";
const out = process.argv[2];
const pages = fs.readdirSync("dist").filter((f) => f.endsWith(".html")).map((f) => ({ file: f, path: f === "index.html" ? "/" : "/" + f.replace(/\.html$/, "") }));
const decode = (s) => s.replace(/&amp;/g, "&").replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, "<").replace(/&gt;/g, ">");
const strip = (h) => decode(h.replace(/<(script|style)[\s\S]*?<\/\1>/g, " ").replace(/<[^>]+>/g, " ")).replace(/\s+/g, " ").trim();
const res = {};
const inbound = Object.fromEntries(pages.map((p) => [p.path, new Set()]));
for (const p of pages) {
  const html = fs.readFileSync(`dist/${p.file}`, "utf8");
  const body = html.slice(html.indexOf("<body"));
  const main = (body.match(/<main[\s\S]*?<\/main>/) ?? [body])[0];
  const title = decode(html.match(/<title>(.*?)<\/title>/)?.[1] ?? "");
  const desc = decode(html.match(/<meta name="description" content="(.*?)"/)?.[1] ?? "");
  const headings = [...main.matchAll(/<h([1-4])[^>]*>([\s\S]*?)<\/h\1>/g)].map((m) => `h${m[1]} ${strip(m[2])}`);
  const imgs = [...html.matchAll(/<img\b[^>]*>/g)].map((m) => m[0]);
  const links = [...main.matchAll(/<a\b[^>]*href="(\/[^"#]*)[^"]*"[^>]*>/g)].map((m) => m[1]);
  for (const l of links) if (inbound[l === "" ? "/" : l] && l !== p.path) inbound[l].add(p.path);
  for (const m of html.matchAll(/<(?:header|footer)[\s\S]*?<\/(?:header|footer)>/g)) for (const l of m[0].matchAll(/href="(\/[^"#]*)"/g)) if (inbound[l[1]] && l[1] !== p.path) inbound[l[1]].add(p.path);
  const ld = [...html.matchAll(/<script type="application\/ld\+json">(.*?)<\/script>/gs)].map((m) => { try { return JSON.parse(m[1])["@type"]; } catch { return "INVALID"; } });
  res[p.path] = {
    title, titleLen: title.length, desc, descLen: desc.length,
    canonical: html.match(/rel="canonical" href="(.*?)"/)?.[1] ?? null,
    robotsMeta: html.match(/<meta name="robots" content="(.*?)"/)?.[1] ?? null,
    lang: html.match(/<html lang="(.*?)"/)?.[1] ?? null,
    h1: headings.filter((h) => h.startsWith("h1 ")).length, headings,
    og: ["og:title", "og:description", "og:image", "og:url", "og:locale"].filter((k) => html.includes(`property="${k}"`)).length + "/5",
    twitter: html.includes('name="twitter:card"'), ogImageSize: fs.existsSync(`dist${html.match(/og:image" content="https?:\/\/[^/]+(\/[^"]+)"/)?.[1] ?? "/x"}`),
    images: imgs.length, imgNoAlt: imgs.filter((i) => !/ alt[=\s>]/.test(i)).length,
    imgNoDims: imgs.filter((i) => !/ width="/.test(i) || !/ height="/.test(i)).length,
    lazyAboveFold: imgs.filter((i) => /loading="lazy"/.test(i)).length,
    internalLinks: new Set(links).size, words: strip(main).split(" ").length, jsonld: ld,
  };
}
for (const p of pages) res[p.path].inboundFrom = [...inbound[p.path]].length;
const sitemap = fs.readFileSync("dist/sitemap-0.xml", "utf8");
const sm = [...sitemap.matchAll(/<loc>(.*?)<\/loc>/g)].map((m) => m[1]);
const summary = {
  pages: pages.length, sitemapUrls: sm, sitemapHasLastmod: /<lastmod>/.test(sitemap), noindexInSitemap: sm.filter((u) => /\/404$/.test(u)),
  robotsTxt: fs.readFileSync("dist/robots.txt", "utf8"), llmsTxtBytes: fs.statSync("dist/llms.txt").size,
  orphans: pages.filter((p) => p.path !== "/" && res[p.path].inboundFrom === 0).map((p) => p.path),
};
const all = { summary, pages: res };
if (out) fs.writeFileSync(out, JSON.stringify(all, null, 2));
console.log(JSON.stringify(summary, null, 2));
for (const [k, v] of Object.entries(res)) console.log(k.padEnd(24), `title ${v.titleLen}`.padEnd(10), `desc ${v.descLen}`.padEnd(10), `h1 ${v.h1}`, `og ${v.og}`, `img ${v.images}/noalt ${v.imgNoAlt}/lazy ${v.lazyAboveFold}`, `links ${v.internalLinks}`, `inb ${v.inboundFrom}`, `words ${v.words}`, v.jsonld.join("+"), v.robotsMeta ?? "");
