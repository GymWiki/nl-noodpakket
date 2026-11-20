#!/usr/bin/env python3
"""Tests voor tool/iap_review_validate.py: python3 tool/test_iap_review.py"""
import os
import struct
import sys
import tempfile
import unittest
import zlib

sys.path.insert(0, os.path.dirname(__file__))
import iap_review_validate as v  # noqa: E402


def chunk(t, body):
    return struct.pack('>I', len(body)) + t + body + struct.pack('>I', zlib.crc32(t + body) & 0xFFFFFFFF)


def png(w, h, ctype=2, depth=8, phys=(2835, 2835, 1), trns=False, idat=True):
    """Kleine geldige PNG-structuur; de pixeldata is één lege regel (genoeg voor de headercontroles)."""
    out = v.SIGNATURE + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, depth, ctype, 0, 0, 0))
    if phys:
        out += chunk(b'pHYs', struct.pack('>IIB', *phys))
    if trns:
        out += chunk(b'tRNS', b'\x00')
    if idat:
        out += chunk(b'IDAT', zlib.compress(b'\x00' * 4))
    return out + chunk(b'IEND', b'')


class Validate(unittest.TestCase):
    def setUp(self):
        self.d = tempfile.mkdtemp()

    def write_all(self, **kw):
        for w, h in v.SIZES:
            open(os.path.join(self.d, v.name_for(w, h)), 'wb').write(png(w, h, **kw))

    def test_goed(self):
        self.write_all()
        bad, lines = v.validate(self.d)
        self.assertEqual(bad, 0, lines)

    def test_ontbrekend_bestand(self):
        self.write_all()
        os.remove(os.path.join(self.d, v.name_for(640, 920)))
        bad, lines = v.validate(self.d)
        self.assertEqual(bad, 1)
        self.assertIn('ontbreekt', lines[0])

    def test_verkeerde_afmeting(self):
        self.write_all()
        open(os.path.join(self.d, v.name_for(1320, 2868)), 'wb').write(png(1320, 2867))
        bad, lines = v.validate(self.d)
        self.assertTrue(any('verwacht 1320x2868' in l for l in lines))

    def test_alfakanaal_rgba(self):
        self.write_all(ctype=6)
        bad, lines = v.validate(self.d)
        self.assertTrue(any('RGBA' in l for l in lines))
        self.assertGreaterEqual(bad, 4)

    def test_grijs_met_alfa_palet_en_trns(self):
        for kw, text in [({'ctype': 4}, 'grijs met alfa'), ({'ctype': 3}, 'palet'), ({'trns': True}, 'tRNS'), ({'ctype': 0}, 'grijs')]:
            self.write_all(**kw)
            _, lines = v.validate(self.d)
            self.assertTrue(any(text in l for l in lines), (kw, lines))

    def test_16_bit_faalt(self):
        self.write_all(depth=16)
        _, lines = v.validate(self.d)
        self.assertTrue(any('bitdiepte 16' in l for l in lines))

    def test_resolutie_ontbreekt_of_is_niet_72_dpi(self):
        self.write_all(phys=None)
        _, lines = v.validate(self.d)
        self.assertTrue(any('pHYs ontbreekt' in l for l in lines))
        self.write_all(phys=(3780, 3780, 1))  # 96 dpi
        _, lines = v.validate(self.d)
        self.assertTrue(any('96.0' in l or '96.0 x 96.0 dpi' in l for l in lines), lines)
        self.write_all(phys=(2835, 2835, 0))  # eenheid onbekend
        _, lines = v.validate(self.d)
        self.assertTrue(any('eenheid' in l for l in lines))

    def test_72_dpi_in_beide_afrondingen_is_goed(self):
        for px in (2834, 2835):
            self.write_all(phys=(px, px, 1))
            bad, lines = v.validate(self.d)
            self.assertEqual(bad, 0, lines)

    def test_te_groot(self):
        self.write_all()
        big = png(640, 920) + b'\x00' * v.MAX_BYTES
        open(os.path.join(self.d, v.name_for(640, 920)), 'wb').write(big)
        _, lines = v.validate(self.d)
        self.assertTrue(any('5 MB' in l for l in lines))

    def test_geen_png_en_afgekapt(self):
        self.write_all()
        open(os.path.join(self.d, v.name_for(640, 920)), 'wb').write(b'not a png at all')
        open(os.path.join(self.d, v.name_for(1242, 2208)), 'wb').write(png(1242, 2208)[:40])
        _, lines = v.validate(self.d)
        self.assertTrue(any('geen PNG' in l for l in lines))
        self.assertTrue(any('afgekapt' in l or 'IEND' in l for l in lines))

    def test_exitcode(self):
        self.write_all()
        self.assertEqual(v.main(['x', self.d]), 0)
        self.write_all(ctype=6)
        self.assertEqual(v.main(['x', self.d]), 1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
