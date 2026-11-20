#!/usr/bin/env python3
"""Controleert dat de basis-URL en de paden van de website overal gelijk zijn:

  - noodpakket-website/src/config/site.ts  (SITE_URL en PATHS)
  - lib/core/config/site_urls.dart         (siteBaseUrl en SitePaths)
  - STORE_URLS.md                          (URL's en supportadres voor de winkels)

Ook controleert het de URL-conventie (https, zonder www, geen slash aan het eind behalve home)
en dat de website geen www-redirect in vercel.json heeft die met de Vercel-domeininstelling kan botsen.
Gebruik: python3 tool/check_site_urls.py   (faalt met exitcode 1 bij een verschil)
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors: list[str] = []


def fail(msg: str) -> None:
    errors.append(msg)


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


# --- website ---
site_ts = read("noodpakket-website/src/config/site.ts")
m = re.search(r'export const SITE_URL = "([^"]+)"', site_ts)
web_base = m.group(1) if m else ""
if not web_base:
    fail("website: SITE_URL niet gevonden in site.ts")
paths_block = re.search(r"export const PATHS = \{(.*?)\}", site_ts, re.S)
web_paths = dict(re.findall(r'(\w+):\s*"([^"]+)"', paths_block.group(1))) if paths_block else {}
if not web_paths:
    fail("website: PATHS niet gevonden in site.ts")
web_email = (re.search(r'email:\s*"([^"]+)"', site_ts) or [None, ""])[1]

# --- app ---
dart = read("lib/core/config/site_urls.dart")
m = re.search(r"const siteBaseUrl = '([^']+)'", dart)
app_base = m.group(1) if m else ""
if not app_base:
    fail("app: siteBaseUrl niet gevonden in site_urls.dart")
app_paths = dict(re.findall(r"static const (\w+) = '([^']+)'", dart))
if not app_paths:
    fail("app: SitePaths niet gevonden in site_urls.dart")

# --- vergelijken ---
if web_base != app_base:
    fail(f"basis-URL verschilt: website {web_base!r} != app {app_base!r}")
if web_paths != app_paths:
    for k in sorted(set(web_paths) | set(app_paths)):
        if web_paths.get(k) != app_paths.get(k):
            fail(f"pad '{k}' verschilt: website {web_paths.get(k)!r} != app {app_paths.get(k)!r}")

# --- conventie ---
if not web_base.startswith("https://"):
    fail(f"basis-URL moet met https:// beginnen: {web_base}")
if re.match(r"https://www\.", web_base):
    fail(f"basis-URL mag geen www bevatten: {web_base}")
if web_base.endswith("/"):
    fail(f"basis-URL mag niet op / eindigen: {web_base}")
for k, p in web_paths.items():
    if not p.startswith("/"):
        fail(f"pad '{k}' moet met / beginnen: {p}")
    if k != "home" and p.endswith("/"):
        fail(f"pad '{k}' mag niet op / eindigen: {p}")
if web_paths.get("home") != "/":
    fail("pad 'home' moet '/' zijn")

# --- STORE_URLS.md ---
store = read("STORE_URLS.md")
canonical = {web_base + p for p in web_paths.values()}
found = set(re.findall(r"`(https?://[^`]+)`", store))
for u in sorted(found):
    if u not in canonical:
        fail(f"STORE_URLS.md bevat een URL die niet canoniek is: {u}")
for key in ("privacy", "contact", "home", "terms", "sources"):
    if web_paths.get(key) is not None and (web_base + web_paths[key]) not in found:
        fail(f"STORE_URLS.md mist de URL voor '{key}': {web_base + web_paths[key]}")
if web_email and f"`{web_email}`" not in store:
    fail(f"STORE_URLS.md noemt het supportadres uit site.ts niet: {web_email}")
for must in ("Privacy Policy URL", "Support URL", "Marketing URL", "License Agreement", "Privacy policy", "Store listing contact details"):
    if must not in store:
        fail(f"STORE_URLS.md mist het veld '{must}'")

# --- redirects: geen www-redirect in vercel.json (de Vercel-domeininstelling beslist) ---
vercel = json.loads(read("noodpakket-website/vercel.json"))
if vercel.get("redirects"):
    fail("vercel.json bevat redirects; de www-redirect hoort alleen in de Vercel-domeininstelling (anders kans op een lus)")
astro = read("noodpakket-website/astro.config.mjs")
if 'trailingSlash: "never"' not in astro:
    fail('astro.config.mjs: trailingSlash moet "never" zijn')
if vercel.get("trailingSlash") is not False or vercel.get("cleanUrls") is not True:
    fail("vercel.json: cleanUrls moet true en trailingSlash false zijn")

if errors:
    print("URL-controle MISLUKT:")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print(f"URL-controle OK: {web_base}, {len(web_paths)} paden, {len(found)} URL's in STORE_URLS.md")
