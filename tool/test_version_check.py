#!/usr/bin/env python3
"""Tests voor tool/check_version.py: python3 tool/test_version_check.py"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import check_version as cv  # noqa: E402


class CheckVersion(unittest.TestCase):
    def test_hoger_slaagt(self):
        v, b, errors = cv.check('name: x\nversion: 2.0.0+20\n', '1.0.15\n')
        self.assertEqual((v, b, errors), ('2.0.0', '20', []))

    def test_gelijk_faalt(self):
        _, _, errors = cv.check('version: 1.0.15+15\n', '1.0.15\n')
        self.assertEqual(len(errors), 1)
        self.assertIn('niet hoger', errors[0])

    def test_lager_faalt_zoals_de_echte_fout(self):
        _, _, errors = cv.check('version: 1.0.14+14\n', '1.0.15\n')
        self.assertTrue(any('90062' in e for e in errors))

    def test_numeriek_vergelijken_niet_tekstueel(self):
        _, _, errors = cv.check('version: 1.0.9+9\n', '1.0.15\n')
        self.assertTrue(errors)
        _, _, errors = cv.check('version: 1.0.100+9\n', '1.0.15\n')
        self.assertEqual(errors, [])

    def test_ontbrekend_bouwnummer_en_slechte_versie(self):
        _, _, errors = cv.check('version: 2.0.0\n', '1.0.15\n')
        self.assertTrue(any('bouwnummer' in e for e in errors))
        _, _, errors = cv.check('version: 2.0\n', '1.0.15\n')
        self.assertTrue(any('X.Y.Z' in e for e in errors))

    def test_geen_versieregel(self):
        _, _, errors = cv.check('name: x\n', '1.0.15\n')
        self.assertEqual(len(errors), 1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
