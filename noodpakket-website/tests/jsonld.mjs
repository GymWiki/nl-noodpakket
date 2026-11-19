// Controleert dat elk JSON-LD-blok parseert en de verplichte velden heeft.
import fs from "node:fs";
let bad = 0;
const err = (m) => { bad++; console.error(m); };
const titleMax = 70, descMax = 160;
for (const f of fs.readdirSync("dist").filter((f) => f.endsWith(".html"))) {
  const html = fs.readFileSync(`dist/${f}`, "utf8");
  const blocks = [...html.matchAll(/<script type="application\/ld\+json">(.*?)<\/script>/gs)].map((m) => m[1]);
  const types = [];
  for (const b of blocks) {
    let j; try { j = JSON.parse(b); } catch (e) { err(`${f}: ongeldige JSON-LD: ${e.message}`); continue; }
    if (j["@context"] !== "https://schema.org") err(`${f}: @context ontbreekt`);
    types.push(j["@type"]);
    if (j["@type"] === "MobileApplication") for (const k of ["name", "description", "applicationCategory", "operatingSystem", "inLanguage", "url"]) if (!j[k]) err(`${f}: MobileApplication.${k} ontbreekt`);
    if (j["@type"] === "FAQPage") { if (!j.mainEntity?.length) err(`${f}: FAQPage leeg`); for (const q of j.mainEntity) if (!q.name || !q.acceptedAnswer?.text) err(`${f}: FAQ-vraag onvolledig`); }
    if (j["@type"] === "BreadcrumbList") j.itemListElement.forEach((it, i) => { if (it.position !== i + 1 || !it.name || !it.item) err(`${f}: breadcrumb ${i} onvolledig`); });
    if (j["@type"] === "Organization" && !j.name) err(`${f}: Organization.name ontbreekt`);
  }
  if (!types.includes("Organization")) err(`${f}: Organization ontbreekt`);
  if (f === "index.html" && !types.includes("MobileApplication")) err("index: MobileApplication ontbreekt");
  if (f === "veelgestelde-vragen.html" && !types.includes("FAQPage")) err("faq: FAQPage ontbreekt");
  // meta-controles
  const title = html.match(/<title>(.*?)<\/title>/)?.[1] ?? "";
  const desc = html.match(/<meta name="description" content="(.*?)"/)?.[1] ?? "";
  if (title.length > titleMax || !title) err(`${f}: title ${title.length} tekens`);
  if (desc.length > descMax || !desc) err(`${f}: description ${desc.length} tekens`);
  for (const need of ['rel="canonical"', 'property="og:image"', 'name="twitter:card"', 'lang="nl-NL"']) if (!html.includes(need)) err(`${f}: ${need} ontbreekt`);
  const h1 = (html.match(/<h1[ >]/g) ?? []).length;
  if (h1 !== 1) err(`${f}: ${h1} h1-elementen`);
  console.log(`${f.padEnd(28)} title ${String(title.length).padStart(2)} desc ${String(desc.length).padStart(3)} jsonld [${types.join(", ")}]`);
}
console.log(bad ? `${bad} bevindingen` : "JSON-LD en meta OK");
process.exit(bad ? 1 : 0);
