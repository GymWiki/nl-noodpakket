#!/usr/bin/env python3
"""Zet alleen de Release-configuratie van het target Runner op handmatige ondertekening.

Gebruik (in CI, op een kopie van de checkout, nooit lokaal committen):
    python3 tool/ios_signing_patch.py <team-id> <profielnaam> [project.pbxproj]

Debug en Profile blijven automatisch. De waarden komen uit het provisioning profile; geheimen
komen hier niet in voor.
"""
import re
import sys

PBX = 'ios/Runner.xcodeproj/project.pbxproj'


def block(text, ident, label):
    """Geeft (start, einde) van `ident /* label */ = { ... };` op het niveau van de sectie."""
    m = re.search(r'\n\t\t' + re.escape(ident) + r'(?: /\*[^*]*\*/)? = \{', text)
    if not m:
        raise SystemExit('niet gevonden: %s (%s)' % (ident, label))
    depth, i = 0, m.end() - 1
    while True:
        c = text[i]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return m.start(), i + 1
        i += 1


def patch(text, team, profile):
    # 1. Runner-target -> lijst met buildconfiguraties.
    t = re.search(r'([0-9A-F]{24}) /\* Runner \*/ = \{\s*isa = PBXNativeTarget;.*?buildConfigurationList = ([0-9A-F]{24})', text, re.S)
    if not t:
        raise SystemExit('target Runner niet gevonden')
    lst = t.group(2)
    s, e = block(text, lst, 'configuratielijst Runner')
    lst_text = text[s:e]
    rel = re.search(r'([0-9A-F]{24}) /\* Release \*/', lst_text)
    if not rel:
        raise SystemExit('Release-configuratie van Runner niet gevonden')
    # 2. Release-configuratie -> buildSettings.
    cs, ce = block(text, rel.group(1), 'Release Runner')
    cfg = text[cs:ce]
    b = re.search(r'buildSettings = \{(.*?)\n\t\t\t\};', cfg, re.S)
    if not b:
        raise SystemExit('buildSettings van Runner Release niet gevonden')
    body = b.group(1)
    body = re.sub(
        r'\n\t\t\t\t(CODE_SIGN_STYLE|DEVELOPMENT_TEAM|PROVISIONING_PROFILE_SPECIFIER|PROVISIONING_PROFILE|"?CODE_SIGN_IDENTITY(\[sdk=iphoneos\*\])?"?) = [^;]*;',
        '', body)
    safe = profile.replace('\\', '\\\\').replace('"', '\\"')
    add = ('\n\t\t\t\tCODE_SIGN_STYLE = Manual;'
           '\n\t\t\t\tDEVELOPMENT_TEAM = %s;'
           '\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "%s";'
           '\n\t\t\t\t"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";') % (team, safe)
    new_cfg = cfg[:b.start(1)] + body + add + cfg[b.end(1):]
    return text[:cs] + new_cfg + text[ce:]


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    team, profile = sys.argv[1], sys.argv[2]
    path = sys.argv[3] if len(sys.argv) > 3 else PBX
    with open(path, encoding='utf-8', newline='') as f:
        text = f.read()
    if not re.fullmatch(r'[0-9A-Z]{10}', team):
        raise SystemExit('team-id ziet er niet uit als een Apple team-id (10 tekens)')
    out = patch(text, team, profile)
    with open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(out)
    print('Runner Release staat nu op handmatige ondertekening (team %s).' % team)


if __name__ == '__main__':
    main()
