// Responsive-, CSP-, menu- en axe-test. Gebruik: NODE_PATH=<playwright> node tests/e2e.mjs
import { createRequire } from "node:module";
import fs from "node:fs";
import { startServer } from "./server.mjs";
import { PAGES, BASE } from "./pages.mjs";
const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const axeSource = fs.readFileSync("node_modules/axe-core/axe.min.js", "utf8");
const shots = process.env.SHOTS ?? "";
let failures = 0;
const fail = (m) => { failures++; console.error("FAIL", m); };

const server = await startServer();
const browser = await chromium.launch();
const sizes = [[360, 800], [768, 1024], [1280, 800]];

for (const scheme of ["light", "dark"]) {
  for (const [w, h] of sizes) {
    const ctx = await browser.newContext({ viewport: { width: w, height: h }, colorScheme: scheme });
    for (const p of PAGES) {
      const page = await ctx.newPage();
      const problems = [];
      page.on("console", (m) => { if (["error", "warning"].includes(m.type())) problems.push(m.text()); });
      page.on("pageerror", (e) => problems.push(String(e)));
      const resp = await page.goto(BASE + p, { waitUntil: "networkidle" });
      if (p !== "/404" && resp.status() !== 200) fail(`${p} status ${resp.status()}`);
      for (const zoom of [100, 200]) {
        await page.evaluate((z) => { document.documentElement.style.fontSize = z + "%"; }, zoom);
        const over = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
        if (over > 1) fail(`${p} @${w}px ${scheme} zoom${zoom}: horizontale scroll (+${over}px)`);
      }
      await page.evaluate(() => { document.documentElement.style.fontSize = ""; });
      if (problems.length) fail(`${p} @${w}px ${scheme}: console/CSP: ${problems.map((x) => x.slice(0, 160)).join(" | ")}`);
      // tikdoelen: zichtbare links/knoppen in header, footer en main kleiner dan 44px hoog
      if (scheme === "light") {
        const small = await page.evaluate(() => [...document.querySelectorAll("header a, header button, footer a, nav a, main a, main summary")].filter((e) => { const r = e.getBoundingClientRect(); const cs = getComputedStyle(e); return r.width > 0 && r.height > 0 && cs.display !== "inline" && r.height < 44; }).map((e) => `${e.textContent.trim().slice(0, 30)} (${Math.round(e.getBoundingClientRect().height)}px)`));
        if (small.length) console.warn(`WARN ${p} @${w}: kleine tikdoelen: ${small.join("; ")}`);
      }
      if (shots && scheme === "light") await page.screenshot({ path: `${shots}/${p === "/" ? "home" : p.slice(1)}-${w}.png`, fullPage: true });
      await page.close();
    }
    await ctx.close();
  }
}

// Browser-zoom 200% (viewport halveert in CSS-pixels; 1280 -> 640, 360 -> 320 = WCAG-reflow)
{
  for (const [w, h] of [[1280, 800], [768, 1024], [640, 800]]) {
    const ctx = await browser.newContext({ viewport: { width: Math.round(w / 2), height: h }, deviceScaleFactor: 2 });
    for (const p of PAGES) {
      const page = await ctx.newPage();
      await page.goto(BASE + p, { waitUntil: "networkidle" });
      const over = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
      if (over > 1) fail(`${p} browser-zoom 200% (${w}px -> ${Math.round(w / 2)}): horizontale scroll (+${over}px)`);
      await page.close();
    }
    await ctx.close();
  }
}

// Mobiel menu (native popover, zonder JavaScript)
{
  const ctx = await browser.newContext({ viewport: { width: 360, height: 800 } });
  const page = await ctx.newPage();
  await page.goto(BASE + "/", { waitUntil: "networkidle" });
  const link = page.locator("#mobiel-menu").getByRole("link", { name: "Bronnen" });
  if (await link.isVisible()) fail("menu: staat open zonder klik");
  await page.getByRole("button", { name: "Menu openen" }).click();
  if (!(await link.isVisible())) fail("menu: link Bronnen niet zichtbaar na openen");
  await page.keyboard.press("Escape");
  if (await link.isVisible()) fail("menu: sluit niet met Escape");
  await page.getByRole("button", { name: "Menu openen" }).click();
  await page.getByRole("button", { name: "Menu sluiten" }).click();
  if (await link.isVisible()) fail("menu: sluit niet met sluitknop");
  const js = await page.evaluate(() => performance.getEntriesByType("resource").filter((r) => r.initiatorType === "script").length);
  if (js) fail(`${js} scriptbestand(en) geladen; verwacht 0`);
  console.log("menu OK, scripts geladen:", js);
  await ctx.close();
}

// Axe (CSP omzeild alleen voor het injecteren van axe zelf)
for (const scheme of ["light", "dark"]) {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 }, colorScheme: scheme, bypassCSP: true });
  for (const p of PAGES) {
    const page = await ctx.newPage();
    await page.goto(BASE + p, { waitUntil: "networkidle" });
    await page.addScriptTag({ content: axeSource });
    const res = await page.evaluate(() => axe.run(document, { runOnly: { type: "tag", values: ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa", "best-practice"] } }));
    for (const v of res.violations) fail(`axe ${p} ${scheme}: ${v.id} (${v.impact}) ${v.nodes.slice(0, 3).map((n) => n.target.join(" ")).join(", ")}`);
    await page.close();
  }
  await ctx.close();
}
await browser.close();
server.close();
console.log(failures ? `${failures} bevindingen` : "e2e OK");
process.exit(failures ? 1 : 0);
