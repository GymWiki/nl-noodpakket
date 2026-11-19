import type { APIRoute, GetStaticPaths } from "astro";
import fs from "node:fs";
import satori from "satori";
import { Resvg } from "@resvg/resvg-js";
import { SITE } from "@/config/site";

const PAGES: Record<string, { title: string; sub: string }> = {
  home: { title: "Rustig voorbereiden op een noodsituatie", sub: "Noodpakket en noodplan, volledig offline" },
  "veelgestelde-vragen": { title: "Veelgestelde vragen", sub: "Antwoorden over de app NL-Noodpakket" },
  bronnen: { title: "Bronnen", sub: "Waar de informatie vandaan komt" },
  privacy: { title: "Privacybeleid", sub: "Geen account, geen tracking" },
  voorwaarden: { title: "Gebruiksvoorwaarden", sub: "NL-Noodpakket" },
  wijzigingen: { title: "Wijzigingen", sub: "Wat is er nieuw per versie" },
  contact: { title: "Contact en support", sub: "NL-Noodpakket" },
  "404": { title: "Pagina niet gevonden", sub: "NL-Noodpakket" },
};

const logoUri = `data:image/png;base64,${fs.readFileSync("public/logo.png").toString("base64")}`;
const font = (file: string) => fs.readFileSync(`node_modules/@fontsource/plus-jakarta-sans/files/${file}`);

export const getStaticPaths: GetStaticPaths = () => Object.keys(PAGES).map((slug) => ({ params: { slug } }));

export const GET: APIRoute = async ({ params }) => {
  const page = PAGES[params.slug as string];
  const h = (type: string, style: Record<string, unknown>, children?: unknown) => ({ type, props: { style: { display: "flex", ...style }, children } });
  const tree = h("div", { width: 1200, height: 630, background: "#0b4a7f", color: "#fff", alignItems: "center", justifyContent: "space-between", padding: 64, gap: 40, boxSizing: "border-box", fontFamily: "Jakarta" }, [
    h("div", { flexDirection: "column", justifyContent: "space-between", height: 502, width: 640 }, [
      h("div", { fontSize: 36, fontWeight: 700 }, SITE.name),
      h("div", { flexDirection: "column", gap: 20 }, [
        h("div", { fontSize: 58, fontWeight: 800, lineHeight: 1.12, letterSpacing: -1.5 }, page.title),
        h("div", { fontSize: 28, color: "#cfe5f5" }, page.sub),
      ]),
      h("div", { fontSize: 24, color: "#cfe5f5" }, "Onafhankelijke app, niet van de overheid"),
    ]),
    { type: "div", props: { style: { display: "flex", background: "#ffffff", borderRadius: 44, padding: 16, flexShrink: 0 }, children: { type: "img", props: { src: logoUri, width: 340, height: 340 } } } },
  ]);
  const svg = await satori(tree as never, {
    width: 1200,
    height: 630,
    fonts: [
      { name: "Jakarta", data: font("plus-jakarta-sans-latin-700-normal.woff"), weight: 700, style: "normal" },
      { name: "Jakarta", data: font("plus-jakarta-sans-latin-800-normal.woff"), weight: 800, style: "normal" },
    ],
  });
  const png = new Resvg(svg, { fitTo: { mode: "width", value: 1200 } }).render().asPng();
  return new Response(new Uint8Array(png), { headers: { "Content-Type": "image/png" } });
};
