#!/usr/bin/env python3
"""Controleert een provisioning profile en het geïmporteerde distributiecertificaat voor de App Store.

    python3 tool/ios_profile_check.py <profile.plist> <bundle-id> <identities.txt> [--env-out bestand]

- <profile.plist>: uitvoer van `security cms -D -i profile.mobileprovision`.
- <identities.txt>: uitvoer van `security find-identity -v -p codesigning <keychain>`.
Er wordt nooit een geheim geprint: alleen naam, team-id, bundle-id, vervaldatum en SHA-1 van certificaten.
Bij een fout: duidelijke melding "gevonden / verwacht" en exitcode 1.
"""
import datetime
import hashlib
import plistlib
import re
import sys


def fail(msg, found=None, expected=None):
    print('FOUT: ' + msg)
    if found is not None:
        print('  gevonden: ' + str(found))
    if expected is not None:
        print('  verwacht: ' + str(expected))
    sys.exit(1)


def check(profile, bundle_id, identities_text, now=None):
    now = now or datetime.datetime.now(datetime.timezone.utc)
    name = profile.get('Name', '')
    uuid = profile.get('UUID', '')
    teams = profile.get('TeamIdentifier') or []
    team = teams[0] if teams else ''
    ent = profile.get('Entitlements', {})
    app_id = ent.get('application-identifier', '')
    expires = profile.get('ExpirationDate')

    if not (name and uuid and team and app_id):
        fail('het provisioning profile mist naam, UUID, team of application-identifier',
             {'naam': bool(name), 'uuid': bool(uuid), 'team': bool(team), 'app-id': bool(app_id)})

    # 1. Bundle-id: exact of via wildcard gedekt.
    exact = '%s.%s' % (team, bundle_id)
    wildcard_ok = app_id.endswith('*') and exact.startswith(app_id[:-1])
    if app_id != exact and not wildcard_ok:
        fail('het profile hoort niet bij deze app', app_id, exact)

    # 2. Verloop.
    if expires is not None:
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=datetime.timezone.utc)
        if expires <= now:
            fail('het provisioning profile is verlopen', expires.date().isoformat(), 'een datum in de toekomst')

    # 3. App Store-distributieprofiel: geen apparaten, geen enterprise, geen debug.
    if profile.get('ProvisionedDevices'):
        fail('dit is een Development- of Ad Hoc-profile (bevat apparaten), geen App Store-profile',
             'ProvisionedDevices aanwezig', 'App Store Connect-distributieprofile')
    if profile.get('ProvisionsAllDevices'):
        fail('dit is een Enterprise-profile, geen App Store-profile', 'ProvisionsAllDevices', 'App Store')
    if ent.get('get-task-allow') is True:
        fail('dit profile staat debuggen toe (get-task-allow), dus is het geen distributieprofile',
             'get-task-allow = true', 'false')
    if profile.get('Platform') and 'iOS' not in profile['Platform']:
        fail('profile is niet voor iOS', profile['Platform'], 'iOS')

    # 4. Geïmporteerde identiteiten: Apple Distribution, team en SHA-1.
    idents = re.findall(r'\d+\) ([0-9A-F]{40}) "([^"]+)"', identities_text)
    dist = [(h, n) for h, n in idents if n.startswith('Apple Distribution') or n.startswith('iPhone Distribution')]
    if not dist:
        fail('geen Apple Distribution-certificaat gevonden in de keychain',
             [n.split(':')[0] for _, n in idents] or 'geen identiteiten', 'Apple Distribution: ... (TEAM)')
    in_profile = {hashlib.sha1(bytes(c)).hexdigest().upper() for c in profile.get('DeveloperCertificates', [])}
    match = [(h, n) for h, n in dist if h in in_profile]
    if not match:
        fail('het certificaat in de .p12 staat niet in het provisioning profile',
             'SHA-1 certificaat: ' + ', '.join(h for h, _ in dist),
             'een van: ' + (', '.join(sorted(in_profile)) or '(profile bevat geen certificaten)'))
    cert_hash, cert_name = match[0]
    m = re.search(r'\(([0-9A-Z]{10})\)\s*$', cert_name)
    if m and m.group(1) != team:
        fail('het team van het certificaat past niet bij het profile', m.group(1), team)

    return {
        'PROFILE_NAME': name,
        'PROFILE_UUID': uuid,
        'TEAM_ID': team,
        'CERT_SHA1': cert_hash,
        'CERT_COMMON_NAME': cert_name,
        'PROFILE_EXPIRES': expires.date().isoformat() if expires else 'onbekend',
    }


def main():
    args = [a for a in sys.argv[1:]]
    env_out = None
    if '--env-out' in args:
        i = args.index('--env-out')
        env_out = args[i + 1]
        del args[i:i + 2]
    if len(args) != 3:
        raise SystemExit(__doc__)
    with open(args[0], 'rb') as f:
        profile = plistlib.load(f)
    with open(args[2], encoding='utf-8', errors='replace') as f:
        idents = f.read()
    r = check(profile, args[1], idents)
    print('Profile: %s (UUID %s)' % (r['PROFILE_NAME'], r['PROFILE_UUID']))
    print('Team: %s | bundle-id: %s | verloopt: %s' % (r['TEAM_ID'], args[1], r['PROFILE_EXPIRES']))
    print('Certificaat: %s | SHA-1: %s' % (r['CERT_COMMON_NAME'], r['CERT_SHA1']))
    print('OK: App Store-profile, bundle-id, team en certificaat kloppen.')
    if env_out:
        with open(env_out, 'a', encoding='utf-8') as f:
            for k in ('PROFILE_NAME', 'PROFILE_UUID', 'TEAM_ID'):
                f.write('%s=%s\n' % (k, r[k]))


if __name__ == '__main__':
    main()
