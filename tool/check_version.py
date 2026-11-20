#!/usr/bin/env python3
"""Voorcontrole: het versienummer in pubspec.yaml moet hoger zijn dan de laatst vrijgegeven versie.

Voorkomt App Store Connect-fouten 90062 ("moet hoger zijn dan de eerder goedgekeurde versie") en 90186
("pre-release train is gesloten"). Werk store/last_released_version.txt bij na elke release.

    python3 tool/check_version.py            (vanuit de projectmap)
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')


def parse(v):
    m = re.fullmatch(r'(\d+)\.(\d+)\.(\d+)', v.strip())
    return tuple(int(x) for x in m.groups()) if m else None


def check(pubspec_text, last_released_text):
    """Geeft (versie, bouwnummer, fouten)."""
    errors = []
    m = re.search(r'^version:\s*(\S+?)(?:\+(\d+))?\s*$', pubspec_text, re.M)
    if not m:
        return None, None, ["pubspec.yaml: geen regel 'version: X.Y.Z+N' gevonden."]
    version, build = m.group(1), m.group(2)
    new, last = parse(version), parse(last_released_text)
    if new is None:
        errors.append("pubspec.yaml: versie '%s' heeft niet de vorm X.Y.Z (bijvoorbeeld 2.0.0)." % version)
    if last is None:
        errors.append("store/last_released_version.txt: '%s' heeft niet de vorm X.Y.Z (bijvoorbeeld 1.0.15)." % last_released_text.strip())
    if build is None:
        errors.append("pubspec.yaml: bouwnummer ontbreekt (verwacht 'version: X.Y.Z+N').")
    if new and last and new <= last:
        errors.append(
            "Versie %s in pubspec.yaml is niet hoger dan de laatst vrijgegeven versie %s (store/last_released_version.txt). "
            "App Store Connect weigert dit met fout 90062/90186. Verhoog de versie in pubspec.yaml, "
            "bijvoorbeeld naar 2.0.0, of werk het bestand bij als je het verkeerd had bijgehouden." % (version, last_released_text.strip()))
    return version, build, errors


def main():
    pub = open(os.path.join(ROOT, 'pubspec.yaml'), encoding='utf-8').read()
    last = open(os.path.join(ROOT, 'store', 'last_released_version.txt'), encoding='utf-8').read()
    version, build, errors = check(pub, last)
    if errors:
        for e in errors:
            print('::error::' + e)
        return 1
    print('Versie %s (build %s) is hoger dan de laatst vrijgegeven versie %s.' % (version, build, last.strip()))
    return 0


if __name__ == '__main__':
    sys.exit(main())
