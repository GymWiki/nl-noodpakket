#!/usr/bin/env python3
"""Controleert een gebouwde .ipa op de runner: ondertekening, bundle-id, team, versie en minimale iOS-versie.

    python3 tool/ios_ipa_verify.py <bestand.ipa> <bundle-id> <team-id> <versienaam> <buildnummer> [--summary bestand]

Gebruikt `unzip`, `codesign` en `security` (macOS). Print geen geheimen.
"""
import glob
import os
import plistlib
import re
import subprocess
import sys
import tempfile


def verify(info, embedded, codesign_text, bundle_id, team, version_name, build_number, min_ios=15.0):
    """Geeft (feiten, fouten). `info` = Info.plist, `embedded` = decoded embedded.mobileprovision."""
    errors = []
    facts = {
        'bundle-id': info.get('CFBundleIdentifier'),
        'versie': info.get('CFBundleShortVersionString'),
        'bouwnummer': info.get('CFBundleVersion'),
        'minimale iOS': info.get('MinimumOSVersion'),
        'team (codesign)': (re.search(r'TeamIdentifier=(\S+)', codesign_text) or [None, None])[1],
        'identifier (codesign)': (re.search(r'Identifier=(\S+)', codesign_text) or [None, None])[1],
        'profile': embedded.get('Name'),
        'app-id (profile)': embedded.get('Entitlements', {}).get('application-identifier'),
    }
    if facts['bundle-id'] != bundle_id:
        errors.append('bundle-id %r, verwacht %r' % (facts['bundle-id'], bundle_id))
    if facts['versie'] != version_name:
        errors.append('versie %r, verwacht %r' % (facts['versie'], version_name))
    if facts['bouwnummer'] != build_number:
        errors.append('bouwnummer %r, verwacht %r' % (facts['bouwnummer'], build_number))
    try:
        if float(facts['minimale iOS']) < min_ios:
            errors.append('minimale iOS %s is lager dan %s' % (facts['minimale iOS'], min_ios))
    except (TypeError, ValueError):
        errors.append('MinimumOSVersion ontbreekt in Info.plist')
    if facts['team (codesign)'] != team:
        errors.append('team volgens codesign %r, verwacht %r' % (facts['team (codesign)'], team))
    if 'Authority=Apple Distribution' not in codesign_text:
        errors.append('niet getekend met een Apple Distribution-certificaat')
    if facts['app-id (profile)'] != '%s.%s' % (team, bundle_id) and not str(facts['app-id (profile)']).endswith('.*'):
        errors.append('embedded profile hoort bij %r' % facts['app-id (profile)'])
    if embedded.get('ProvisionedDevices'):
        errors.append('embedded profile bevat apparaten (geen App Store-profile)')
    return facts, errors


def run(cmd, **kw):
    return subprocess.run(cmd, check=True, capture_output=True, text=True, **kw)


def main():
    args = sys.argv[1:]
    summary = None
    if '--summary' in args:
        i = args.index('--summary')
        summary = args[i + 1]
        del args[i:i + 2]
    if len(args) != 5:
        raise SystemExit(__doc__)
    ipa, bundle_id, team, version_name, build_number = args
    with tempfile.TemporaryDirectory() as tmp:
        run(['unzip', '-q', ipa, '-d', tmp])
        apps = glob.glob(os.path.join(tmp, 'Payload', '*.app'))
        if len(apps) != 1:
            raise SystemExit('FOUT: verwacht precies één .app in de IPA, gevonden: %d' % len(apps))
        app = apps[0]
        run(['codesign', '--verify', '--strict', '--deep', app])
        cs = subprocess.run(['codesign', '-dv', '--verbose=4', app], capture_output=True, text=True).stderr
        with open(os.path.join(app, 'Info.plist'), 'rb') as f:
            info = plistlib.load(f)
        decoded = run(['security', 'cms', '-D', '-i', os.path.join(app, 'embedded.mobileprovision')]).stdout
        embedded = plistlib.loads(decoded.encode('utf-8'))
    facts, errors = verify(info, embedded, cs, bundle_id, team, version_name, build_number)
    lines = ['| Controle | Waarde |', '|---|---|'] + ['| %s | `%s` |' % (k, v) for k, v in facts.items()]
    print('\n'.join('%s: %s' % (k, v) for k, v in facts.items()))
    if summary:
        with open(summary, 'a', encoding='utf-8') as f:
            f.write('### Gecontroleerde IPA\n' + '\n'.join(lines) + '\n')
    if errors:
        print('FOUT in de IPA:')
        for e in errors:
            print(' - ' + e)
        sys.exit(1)
    print('OK: IPA is geldig ondertekend en komt overeen met de verwachte waarden.')


if __name__ == '__main__':
    main()
