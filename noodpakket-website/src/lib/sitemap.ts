import fs from "node:fs";
import path from "node:path";
import { SITE } from "../config/site";

/** Nieuwste releasedatum uit src/content/wijzigingen/*.md (frontmatter `date`). */
function latestRelease(): string | undefined {
  const dir = path.resolve("src/content/wijzigingen");
  const dates = fs.readdirSync(dir).filter((f) => f.endsWith(".md")).map((f) => fs.readFileSync(path.join(dir, f), "utf8").match(/^date:\s*(\d{4}-\d{2}-\d{2})/m)?.[1]).filter(Boolean) as string[];
  return dates.sort().at(-1);
}

/** Betrouwbare lastmod per pad (alleen pagina's met een bijgehouden datum). */
export function lastmodFor(pathname: string): string | undefined {
  const p = pathname.replace(/\/$/, "") || "/";
  if (p === "/" || p === "/veelgestelde-vragen" || p === "/bronnen") return SITE.lastUpdated;
  if (p === "/privacy" || p === "/voorwaarden") return SITE.legalUpdated;
  if (p === "/wijzigingen") return latestRelease();
  return undefined; // /contact: geen datum bijgehouden
}
