#!/usr/bin/env python3
"""Controleert dat de Android-build geen onbedoelde VERPLICHTE hardware-features heeft.

Google Play filtert toestellen op verplichte features en op features die het zelf afleidt ("implied") uit machtigingen en
activity-instellingen. Voorbeelden: de machtiging CAMERA impliceert camera en camera.autofocus, ACCESS_WIFI_STATE impliceert
wifi, en een activity met screenOrientation="portrait" impliceert screen.portrait. Dat sluit toestellen uit
("Required hardware feature declarations are restricting your app's availability").

    aapt2 dump badging app-release.apk > badging.txt
    python3 tool/android_features_check.py badging.txt

Telt als verplicht: elke regel `uses-feature` (zonder required=false) en elke regel `uses-implied-feature`. Toegestaan zijn alleen
android.hardware.touchscreen en android.hardware.faketouch (dat laatste is de standaard die Android bij een touchscreen afleidt).
Faalt (exitcode 1) met de oorzaak per feature. Machtigingen die we niet kennen worden alleen gemeld, niet afgekeurd.
"""
import re
import sys

ALLOWED_REQUIRED = {'android.hardware.touchscreen', 'android.hardware.faketouch'}

# Machtigingen die we bewust gebruiken. Een onbekende machtiging wordt gemeld (waarschuwing), niet afgekeurd.
KNOWN_PERMISSIONS = {
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.USE_BIOMETRIC',
    'android.permission.INTERNET',
    'android.permission.CAMERA',
    'android.permission.READ_CONTACTS',
    'android.permission.VIBRATE',
    'android.permission.WAKE_LOCK',
    'com.android.vending.BILLING',
}

_NAME = r"(?:name=)?'([^']+)'"


def parse(text):
    """Geeft (verplicht, optioneel, implied, permissies): verplicht en implied zijn dicts feature -> reden."""
    required, optional, implied, perms = {}, set(), {}, set()
    for line in text.splitlines():
        line = line.strip()
        m = re.match(r"uses-feature-not-required:\s*" + _NAME, line)
        if m:
            optional.add(m.group(1))
            continue
        m = re.match(r"uses-implied-feature:\s*" + _NAME + r"(?:,?\s*(?:reason=)?'([^']*)')?", line)
        if m:
            implied[m.group(1)] = m.group(2) or 'afgeleid'
            continue
        m = re.match(r"uses-feature:\s*" + _NAME, line)
        if m:
            required[m.group(1)] = 'verplicht gedeclareerd (uses-feature zonder android:required="false")'
            continue
        m = re.match(r"uses-permission(?:-sdk-23)?:\s*" + _NAME, line)
        if m:
            perms.add(m.group(1))
    return required, optional, implied, perms


def problems(text):
    """Geeft een lijst afwijkingen (leeg = goed)."""
    required, optional, implied, _ = parse(text)
    out = []
    for name, why in sorted({**implied, **required}.items()):
        if name in ALLOWED_REQUIRED or name in optional:
            continue
        out.append('%s is verplicht: %s' % (name, why))
    return out


def main(argv):
    if len(argv) < 2:
        print('gebruik: android_features_check.py badging.txt', file=sys.stderr)
        return 2
    text = open(argv[1], encoding='utf-8', errors='replace').read()
    required, optional, implied, perms = parse(text)
    print('Verplichte of afgeleide features (Google Play filtert hierop):')
    for name, why in sorted({**implied, **required}.items()):
        mark = 'toegestaan' if name in ALLOWED_REQUIRED else ('optioneel gemaakt' if name in optional else 'NIET TOEGESTAAN')
        print('  %-40s %-18s %s' % (name, mark, why))
    print('Optionele features (required=false):', ', '.join(sorted(optional)) or '-')
    unknown = sorted(p for p in perms if p not in KNOWN_PERMISSIONS)
    if unknown:
        print('Waarschuwing: machtigingen buiten de bekende lijst: ' + ', '.join(unknown))
    bad = problems(text)
    if bad:
        for b in bad:
            print('::error::' + b)
        print('\nDe build heeft %d onbedoelde verplichte feature(s). Maak ze optioneel met <uses-feature android:required="false"/> in '
              'android/app/src/main/AndroidManifest.xml (met tools:replace="android:required" als een plugin ze verplicht declareert), '
              'of haal de machtiging weg die ze impliceert.' % len(bad), file=sys.stderr)
        return 1
    print('\nGeen onbedoelde verplichte features.')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
