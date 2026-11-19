// Snijdt het appscherm uit de store-afbeeldingen (921x2000, blauwe achtergrond met kop) en schrijft WebP.
// Gebruik: node scripts/crop-screenshots.mjs <bronmap met 1.webp..5.webp>
import sharp from "sharp";
import path from "node:path";
const src = process.argv[2];
if (!src) { console.error("Geef de bronmap op"); process.exit(1); }
const names = ["startscherm", "pakket", "stappenplan", "noodplan", "delen"];
const box = { left: 97, top: 343, width: 727, height: 1584 }; // binnenkant van de telefoonkaart
for (const [i, n] of names.entries()) {
  const out = path.join("src/assets/screenshots", `${n}.webp`);
  await sharp(path.join(src, `${i + 1}.webp`)).extract(box).webp({ quality: 90 }).toFile(out);
  console.log(out);
}
