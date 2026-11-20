#!/usr/bin/env python3
"""Tests voor de iOS-CI-scripts (draaien zonder Mac): python3 tool/test_ios_scripts.py"""
import datetime
import hashlib
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import ios_profile_check as pc  # noqa: E402
import ios_export_options as eo  # noqa: E402
import ios_ipa_verify as iv  # noqa: E402
import ios_signing_patch as sp  # noqa: E402
import plistlib  # noqa: E402
import tempfile  # noqa: E402

BUNDLE = 'com.mycompany.mijnnoodpakket'
CERT = b'dit-is-een-nep-certificaat'
SHA = hashlib.sha1(CERT).hexdigest().upper()
FUTURE = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=100)


def profile(**kw):
    p = {
        'Name': 'NL Noodpakket AppStore', 'UUID': '11111111-2222-3333-4444-555555555555',
        'TeamIdentifier': ['ABCDE12345'], 'ExpirationDate': FUTURE, 'Platform': ['iOS'],
        'Entitlements': {'application-identifier': 'ABCDE12345.' + BUNDLE, 'get-task-allow': False},
        'DeveloperCertificates': [CERT],
    }
    p.update(kw)
    return p


IDENT = '  1) %s "Apple Distribution: Pieter (ABCDE12345)"\n     1 valid identities found\n' % SHA


class ProfileCheck(unittest.TestCase):
    def test_goed(self):
        r = pc.check(profile(), BUNDLE, IDENT)
        self.assertEqual(r['TEAM_ID'], 'ABCDE12345')
        self.assertEqual(r['CERT_SHA1'], SHA)

    def test_wildcard_dekt_bundle(self):
        p = profile()
        p['Entitlements']['application-identifier'] = 'ABCDE12345.*'
        pc.check(p, BUNDLE, IDENT)

    def expect_fail(self, p, ident=IDENT, bundle=BUNDLE):
        with self.assertRaises(SystemExit) as c:
            pc.check(p, bundle, ident)
        self.assertEqual(c.exception.code, 1)

    def test_verkeerd_bundle(self):
        self.expect_fail(profile(), bundle='com.ander.app')

    def test_verlopen(self):
        self.expect_fail(profile(ExpirationDate=datetime.datetime(2020, 1, 1, tzinfo=datetime.timezone.utc)))

    def test_adhoc_of_development(self):
        self.expect_fail(profile(ProvisionedDevices=['x']))

    def test_enterprise(self):
        self.expect_fail(profile(ProvisionsAllDevices=True))

    def test_debug(self):
        p = profile()
        p['Entitlements']['get-task-allow'] = True
        self.expect_fail(p)

    def test_certificaat_niet_in_profile(self):
        self.expect_fail(profile(DeveloperCertificates=[b'ander']))

    def test_geen_distributiecertificaat(self):
        self.expect_fail(profile(), ident='  1) %s "Apple Development: Pieter (ABCDE12345)"\n' % SHA)

    def test_team_certificaat_wijkt_af(self):
        self.expect_fail(profile(), ident='  1) %s "Apple Distribution: Pieter (ZZZZZ99999)"\n' % SHA)


class SigningPatch(unittest.TestCase):
    PBX = os.path.join(os.path.dirname(__file__), '..', 'ios', 'Runner.xcodeproj', 'project.pbxproj')

    def test_alleen_runner_release(self):
        text = open(self.PBX, encoding='utf-8', newline='').read()
        out = sp.patch(text, 'ABCDE12345', 'Mijn "Profiel"')
        self.assertEqual(out.count('CODE_SIGN_STYLE = Manual;'), 1)
        self.assertEqual(out.count('PROVISIONING_PROFILE_SPECIFIER'), 1)
        self.assertIn('PROVISIONING_PROFILE_SPECIFIER = "Mijn \\"Profiel\\"";', out)
        # Tweede keer draaien geeft hetzelfde resultaat (idempotent).
        self.assertEqual(sp.patch(out, 'ABCDE12345', 'Mijn "Profiel"'), out)
        # De test-target en Debug/Profile blijven onaangeroerd.
        self.assertEqual(out.count('CODE_SIGN_STYLE = Automatic;'), text.count('CODE_SIGN_STYLE = Automatic;'))


class ExportOptions(unittest.TestCase):
    def test_plist_is_geldig_en_bevat_de_koppeling(self):
        d = eo.options('ABCDE12345', BUNDLE, 'NL Noodpakket AppStore')
        with tempfile.NamedTemporaryFile(suffix='.plist', delete=False) as f:
            plistlib.dump(d, f)
        back = plistlib.load(open(f.name, 'rb'))
        os.unlink(f.name)
        self.assertEqual(back['method'], 'app-store-connect')
        self.assertEqual(back['signingStyle'], 'manual')
        self.assertEqual(back['provisioningProfiles'], {BUNDLE: 'NL Noodpakket AppStore'})
        self.assertTrue(back['uploadSymbols'])


class IpaVerify(unittest.TestCase):
    INFO = {'CFBundleIdentifier': BUNDLE, 'CFBundleShortVersionString': '1.0.14', 'CFBundleVersion': '14.7', 'MinimumOSVersion': '15.0'}
    EMB = {'Name': 'NL Noodpakket AppStore', 'Entitlements': {'application-identifier': 'ABCDE12345.' + BUNDLE}}
    CS = ('Identifier=%s' % BUNDLE) + chr(10) + 'Authority=Apple Distribution: Pieter (ABCDE12345)' + chr(10) + 'TeamIdentifier=ABCDE12345' + chr(10)

    def test_goed(self):
        _, errors = iv.verify(self.INFO, self.EMB, self.CS, BUNDLE, 'ABCDE12345', '1.0.14', '14.7')
        self.assertEqual(errors, [])

    def test_ios_14_is_te_laag(self):
        info = dict(self.INFO, MinimumOSVersion='14.0')
        _, errors = iv.verify(info, self.EMB, self.CS, BUNDLE, 'ABCDE12345', '1.0.14', '14.7')
        self.assertTrue(any('lager dan 15.0' in e for e in errors))

    def test_te_lage_ios_en_verkeerd_bouwnummer(self):
        info = dict(self.INFO, MinimumOSVersion='13.0', CFBundleVersion='1')
        _, errors = iv.verify(info, self.EMB, self.CS, BUNDLE, 'ABCDE12345', '1.0.14', '14.7')
        self.assertEqual(len(errors), 2)

    def test_development_handtekening(self):
        cs = self.CS.replace('Apple Distribution', 'Apple Development')
        _, errors = iv.verify(self.INFO, self.EMB, cs, BUNDLE, 'ABCDE12345', '1.0.14', '14.7')
        self.assertTrue(any('Apple Distribution' in e for e in errors))


if __name__ == '__main__':
    unittest.main(verbosity=2)
