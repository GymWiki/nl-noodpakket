#!/usr/bin/env python3
"""Maakt ExportOptions.plist voor een App Store-export met handmatige ondertekening.

    python3 tool/ios_export_options.py <team-id> <bundle-id> <profielnaam> <uitvoerbestand>

Methode `app-store-connect` (Xcode 15.3 en nieuwer; `app-store` is de verouderde naam).
"""
import plistlib
import sys


def options(team, bundle_id, profile_name):
    return {
        'method': 'app-store-connect',
        'destination': 'export',
        'teamID': team,
        'signingStyle': 'manual',
        'signingCertificate': 'Apple Distribution',
        'provisioningProfiles': {bundle_id: profile_name},
        'uploadSymbols': True,
        'manageAppVersionAndBuildNumber': False,
    }


def main():
    if len(sys.argv) != 5:
        raise SystemExit(__doc__)
    team, bundle_id, profile_name, out = sys.argv[1:]
    with open(out, 'wb') as f:
        plistlib.dump(options(team, bundle_id, profile_name), f)
    print('ExportOptions.plist geschreven (methode app-store-connect, team %s).' % team)


if __name__ == '__main__':
    main()
