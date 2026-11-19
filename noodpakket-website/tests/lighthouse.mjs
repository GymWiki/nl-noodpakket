// Lighthouse (mobiel, standaardconfig) op alle pagina's. CHROME_PATH moet naar Chromium wijzen.
import { execFile } from "node:child_process";
import { promisify } from "node:util";
const run = promisify(execFile);
import fs from "node:fs";
import { startServer } from "./server.mjs";
import { PAGES, BASE } from "./pages.mjs";
const server = await startServer();
let low = 0;
fs.rmSync("lighthouse-rapporten", { recursive: true, force: true });
fs.mkdirSync("lighthouse-rapporten", { recursive: true });
for (const p of PAGES) {
  const out = `lighthouse-rapporten/${p === "/" ? "home" : p.slice(1)}.json`;
  for (let t = 0; t < 3 && !fs.existsSync(out); t++) try { await run("npx", ["lighthouse", BASE + p, "--quiet", "--output=json", `--output-path=${out}`, "--chrome-flags=--headless=new --no-sandbox", "--only-categories=performance,accessibility,best-practices,seo"], { env: { ...process.env, NO_PROXY: "localhost,127.0.0.1", no_proxy: "localhost,127.0.0.1" } }); } catch {}
  if (!fs.existsSync(out)) { console.error(p, "geen rapport"); low++; continue; }
  const j = JSON.parse(fs.readFileSync(out, "utf8"));
  const s = Object.fromEntries(Object.entries(j.categories).map(([k, v]) => [k, Math.round(v.score * 100)]));
  const bad = Object.values(s).some((v) => v < 95);
  if (bad) low++;
  console.log(p.padEnd(24), `perf ${s.performance} a11y ${s.accessibility} bp ${s["best-practices"]} seo ${s.seo}`, bad ? "  <-- onder 95" : "");
}
server.close();
process.exit(low ? 1 : 0);
