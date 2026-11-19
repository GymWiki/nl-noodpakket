// Interne links tegen dist/; externe links met fetch (best effort: faalt zonder netwerk en wordt dan als 'niet verifieerbaar' gemeld).
import fs from "node:fs";
import path from "node:path";
const dist = path.resolve("dist");
const files = fs.readdirSync(dist).filter((f) => f.endsWith(".html"));
const internal = new Set(), external = new Set();
const ids = {};
for (const f of files) {
  const html = fs.readFileSync(path.join(dist, f), "utf8");
  ids["/" + (f === "index.html" ? "" : f.replace(/\.html$/, ""))] = new Set([...html.matchAll(/ id="([^"]+)"/g)].map((m) => m[1]));
  for (const m of html.matchAll(/(?:href|src)="([^"#][^"]*)(#[^"]*)?"/g)) {
    const u = m[1];
    if (/^https?:\/\//.test(u)) external.add(u); else if (u.startsWith("/")) internal.add(u + (m[2] ?? ""));
    else if (!/^(mailto:|tel:|data:)/.test(u)) console.warn("relatief:", f, u);
  }
  for (const m of html.matchAll(/href="(#[^"]+)"/g)) if (!ids["/" + (f === "index.html" ? "" : f.replace(/\.html$/, ""))].has(m[1].slice(1))) console.error(`${f}: anker ${m[1]} bestaat niet`);
}
let bad = 0;
for (const u of internal) {
  const [p, hash] = u.split("#");
  const target = p === "/" ? "index.html" : fs.existsSync(path.join(dist, p)) ? p : p + ".html";
  if (!fs.existsSync(path.join(dist, target))) { bad++; console.error("kapotte interne link:", u); continue; }
  if (hash && target.endsWith(".html")) { const html = fs.readFileSync(path.join(dist, target), "utf8"); if (!html.includes(`id="${hash}"`)) { bad++; console.error("anker mist:", u); } }
}
console.log(`${internal.size} interne links gecontroleerd, ${bad} kapot`);
if (process.argv.includes("--external")) {
  const res = { ok: [], broken: [], unreachable: [] };
  const list = [...external].filter((u) => !u.includes("noodpakket.example"));
  await Promise.all(list.map(async (u) => {
    try {
      const r = await fetch(u, { method: "GET", redirect: "follow", signal: AbortSignal.timeout(15000), headers: { "User-Agent": "Mozilla/5.0 linkcheck" } });
      (r.status < 400 ? res.ok : res.broken).push(`${r.status} ${u}`);
    } catch (e) { res.unreachable.push(`${u} (${e.cause?.code ?? e.message})`); }
  }));
  console.log(`extern: ${res.ok.length} ok, ${res.broken.length} fout, ${res.unreachable.length} niet bereikbaar`);
  res.broken.forEach((x) => console.error("  fout:", x));
  if (res.unreachable.length) console.warn("  niet verifieerbaar (netwerk):", res.unreachable.length, "links");
  if (process.argv.includes("--list")) res.unreachable.forEach((x) => console.log("  -", x));
  bad += res.broken.length;
}
process.exit(bad ? 1 : 0);
