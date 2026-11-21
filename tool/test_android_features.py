#!/usr/bin/env python3
"""Tests voor tool/android_features_check.py: python3 tool/test_android_features.py"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import android_features_check as c  # noqa: E402

# Zoals de huidige (foute) build: portrait en wifi verplicht afgeleid, autofocus afgeleid uit CAMERA.
BAD = """package: name='com.mycompany.mijnnoodpakket' versionCode='21' versionName='2.0.1'
uses-permission: name='android.permission.CAMERA'
uses-permission: name='android.permission.ACCESS_WIFI_STATE'
uses-permission: name='android.permission.INTERNET'
uses-feature-not-required: name='android.hardware.camera'
uses-feature: name='android.hardware.touchscreen'
uses-implied-feature: name='android.hardware.camera.autofocus' reason='requested android.permission.CAMERA permission'
uses-implied-feature: name='android.hardware.wifi' reason='requested android.permission.ACCESS_WIFI_STATE permission'
uses-implied-feature: name='android.hardware.screen.portrait' reason='one or more activities have specified a portrait orientation'
uses-implied-feature: name='android.hardware.faketouch' reason='default feature for all apps'
"""

GOOD = """package: name='com.mycompany.mijnnoodpakket' versionCode='22' versionName='2.0.1'
uses-permission: name='android.permission.CAMERA'
uses-permission: name='android.permission.INTERNET'
uses-feature-not-required: name='android.hardware.camera'
uses-feature-not-required: name='android.hardware.camera.autofocus'
uses-feature-not-required: name='android.hardware.wifi'
uses-feature-not-required: name='android.hardware.screen.portrait'
uses-feature: name='android.hardware.touchscreen'
uses-implied-feature: name='android.hardware.faketouch' reason='default feature for all apps'
"""


class Check(unittest.TestCase):
    def test_goed_slaagt(self):
        self.assertEqual(c.problems(GOOD), [])

    def test_de_drie_bekende_fouten_worden_gevonden(self):
        names = [p.split(' ')[0] for p in c.problems(BAD)]
        self.assertEqual(names, ['android.hardware.camera.autofocus', 'android.hardware.screen.portrait', 'android.hardware.wifi'])

    def test_reden_staat_erbij(self):
        text = '\n'.join(c.problems(BAD))
        self.assertIn('ACCESS_WIFI_STATE', text)
        self.assertIn('portrait orientation', text)
        self.assertIn('CAMERA permission', text)

    def test_een_nieuwe_verplichte_feature_faalt(self):
        extra = GOOD + "uses-feature: name='android.hardware.bluetooth'\n"
        self.assertEqual(len(c.problems(extra)), 1)
        self.assertIn('bluetooth', c.problems(extra)[0])

    def test_optioneel_gemaakt_telt_niet(self):
        t = "uses-implied-feature: name='android.hardware.wifi' reason='x'\nuses-feature-not-required: name='android.hardware.wifi'\n"
        self.assertEqual(c.problems(t), [])

    def test_oudere_aapt_notatie(self):
        t = "uses-feature:'android.hardware.touchscreen'\nuses-feature:'android.hardware.location.gps'\nuses-implied-feature:'android.hardware.wifi','x'\n"
        names = [p.split(' ')[0] for p in c.problems(t)]
        self.assertEqual(names, ['android.hardware.location.gps', 'android.hardware.wifi'])

    def test_exitcode_en_onbekende_machtiging(self):
        import tempfile
        d = tempfile.mkdtemp()
        good = os.path.join(d, 'g.txt'); open(good, 'w').write(GOOD + "uses-permission: name='android.permission.RECORD_AUDIO'\n")
        bad = os.path.join(d, 'b.txt'); open(bad, 'w').write(BAD)
        self.assertEqual(c.main(['x', good]), 0)   # onbekende machtiging: alleen een waarschuwing
        self.assertEqual(c.main(['x', bad]), 1)
        self.assertEqual(c.main(['x']), 2)


if __name__ == '__main__':
    unittest.main(verbosity=2)
