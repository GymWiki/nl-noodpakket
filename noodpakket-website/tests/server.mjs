// Eenvoudige statische server die dist/ serveert met cleanUrls en de headers uit vercel.json (alleen voor lokaal testen).
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const root = path.resolve("dist");
const cfg = JSON.parse(fs.readFileSync("vercel.json", "utf8"));
const types = { ".html": "text/html; charset=utf-8", ".css": "text/css", ".js": "text/javascript", ".svg": "image/svg+xml", ".png": "image/png", ".txt": "text/plain; charset=utf-8", ".xml": "application/xml", ".woff2": "font/woff2", ".woff": "font/woff" };

export function startServer(port = 4321) {
  const server = http.createServer((req, res) => {
    let p = decodeURIComponent(new URL(req.url, "http://x").pathname);
    let file = path.join(root, p);
    if (!path.extname(p)) file = p === "/" ? path.join(root, "index.html") : path.join(root, p + ".html");
    let status = 200;
    if (!file.startsWith(root) || !fs.existsSync(file)) { status = 404; file = path.join(root, "404.html"); }
    const headers = { "Content-Type": types[path.extname(file)] ?? "application/octet-stream" };
    for (const rule of cfg.headers) {
      if (rule.has) continue; // host-specifieke regels gelden niet op localhost
      const re = new RegExp("^" + rule.source + "$");
      if (re.test(p)) for (const h of rule.headers) headers[h.key] = h.value;
    }
    res.writeHead(status, headers);
    fs.createReadStream(file).pipe(res);
  });
  return new Promise((r) => server.listen(port, () => r(server)));
}

if (import.meta.url === `file://${process.argv[1]}`) {
  await startServer(Number(process.env.PORT ?? 4321));
  console.log("http://localhost:" + (process.env.PORT ?? 4321));
}
