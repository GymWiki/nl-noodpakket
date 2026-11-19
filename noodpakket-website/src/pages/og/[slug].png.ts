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

const font = (file: string) => fs.readFileSync(`node_modules/@fontsource/plus-jakarta-sans/files/${file}`);

export const getStaticPaths: GetStaticPaths = () => Object.keys(PAGES).map((slug) => ({ params: { slug } }));

export const GET: APIRoute = async ({ params }) => {
  const page = PAGES[params.slug as string];
  const h = (type: string, style: Record<string, unknown>, children?: unknown) => ({ type, props: { style: { display: "flex", ...style }, children } });
  const tree = h("div", { width: 1200, height: 630, background: "#0b4a7f", color: "#fff", flexDirection: "column", justifyContent: "space-between", padding: 80, fontFamily: "Jakarta" }, [
    h("div", { alignItems: "center", gap: 20, fontSize: 40, fontWeight: 700 }, [
      h("div", { width: 18, height: 18, borderRadius: 9, background: "#f0a35a" }),
      SITE.name,
    ]),
    h("div", { flexDirection: "column", gap: 24 }, [
      h("div", { fontSize: 76, fontWeight: 800, lineHeight: 1.1, letterSpacing: -2 }, page.title),
      h("div", { fontSize: 36, color: "#cfe5f5" }, page.sub),
    ]),
    h("div", { fontSize: 28, color: "#cfe5f5" }, "Onafhankelijke app, niet van de overheid"),
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
