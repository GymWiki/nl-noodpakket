// Maakt de logobestanden voor de site uit de twee aangeleverde SVG's (ingesloten bitmap 1024x1024).
// Gebruik: node scripts/prepare-logo.mjs <met-achtergrond.svg> <zonder-achtergrond.svg>
import sharp from "sharp";
import fs from "node:fs";
const [withBg, transparent] = process.argv.slice(2);
if (!withBg || !transparent) { console.error("Geef beide SVG's op"); process.exit(1); }
const render = (f) => sharp(fs.readFileSync(f), { density: 192 }).resize(1024, 1024, { fit: "contain", background: { r: 0, g: 0, b: 0, alpha: 0 } });
fs.mkdirSync("src/assets/logo", { recursive: true });
// Transparant, bijgesneden: header en footer (werkt op licht en donker thema)
const t = await render(transparent).png().toBuffer();
await sharp(t).trim().resize({ width: 640 }).webp({ quality: 90, alphaQuality: 95 }).toFile("src/assets/logo/logo-transparent.webp");
// Met achtergrond: favicon, Apple-icoon, OG-beeld en gestructureerde data
const b = await render(withBg).flatten({ background: "#ffffff" }).png().toBuffer();
await sharp(b).resize(512).png({ compressionLevel: 9, palette: false }).toFile("public/logo.png");
await sharp(b).resize(180).png().toFile("public/apple-touch-icon.png");
await sharp(b).resize(192).png().toFile("public/favicon-192.png");
await sharp(b).resize(32).png().toFile("public/favicon-32.png");
console.log("klaar");
