import { HtmlValidate } from "html-validate";
import fs from "node:fs";
const hv = new HtmlValidate(JSON.parse(fs.readFileSync(".htmlvalidate.json", "utf8")));
let bad = 0;
for (const f of fs.readdirSync("dist").filter((f) => f.endsWith(".html"))) {
  const r = await hv.validateFile(`dist/${f}`);
  for (const res of r.results) for (const m of res.messages) { bad++; console.error(`${f}:${m.line}:${m.column} ${m.ruleId} ${m.message}`); }
}
console.log(bad ? `${bad} HTML-bevindingen` : "HTML OK");
process.exit(bad ? 1 : 0);
