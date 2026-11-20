#!/usr/bin/env python3
"""Valideert de reviewscreenshots voor de in-app aankoop `pro_unlock` (App Store Connect > App Review Information).

    python3 tool/iap_review_validate.py [map]          (standaard store/out/iap-review)

Per bestand: exacte afmetingen, PNG, 8-bit RGB zonder alfakanaal (geen RGBA, grijs, palet of tRNS), 72 dpi (pHYs in
pixels per meter, 2835) en een bestandsgrootte onder 5 MB. Faalt (exitcode 1) bij elke afwijking of ontbrekend bestand.
Alleen de standaardbibliotheek, zodat het ook op de macOS-runner zonder installaties draait.
"""
import os
import struct
import sys

SIZES = [(640, 920), (1242, 2208), (1290, 2796), (1320, 2868)]
MAX_BYTES = 5 * 1000 * 1000  # "onder 5 MB", bewust de strengste lezing
DPI_72_PX_PER_METER = {2834, 2835}  # 72 / 0,0254 = 2834,6
SIGNATURE = b'\x89PNG\r\n\x1a\n'


def name_for(w, h):
    return 'pro_unlock_%dx%d.png' % (w, h)


def read_chunks(data):
    """Geeft [(type, data)] tot en met IEND, of gooit ValueError bij een kapot bestand."""
    if data[:8] != SIGNATURE:
        raise ValueError('geen PNG (signatuur klopt niet)')
    chunks, o = [], 8
    while o + 8 <= len(data):
        (length,) = struct.unpack('>I', data[o:o + 4])
        ctype = data[o + 4:o + 8].decode('latin-1')
        body = data[o + 8:o + 8 + length]
        if len(body) != length:
            raise ValueError('afgekapt bestand in chunk %s' % ctype)
        chunks.append((ctype, body))
        o += 12 + length
        if ctype == 'IEND':
            return chunks
    raise ValueError('IEND ontbreekt')


def check_file(path, width, height):
    """Geeft een lijst afwijkingen (leeg = goed)."""
    errors = []
    size = os.path.getsize(path)
    if size >= MAX_BYTES:
        errors.append('%d bytes is niet onder 5 MB' % size)
    try:
        chunks = read_chunks(open(path, 'rb').read())
    except ValueError as e:
        return errors + [str(e)]
    types = [c[0] for c in chunks]
    if types[0] != 'IHDR':
        return errors + ['eerste chunk is %s, verwacht IHDR' % types[0]]
    w, h, depth, ctype, comp, filt, interlace = struct.unpack('>IIBBBBB', chunks[0][1])
    if (w, h) != (width, height):
        errors.append('afmetingen %dx%d, verwacht %dx%d' % (w, h, width, height))
    if ctype != 2:
        names = {0: 'grijs', 3: 'palet', 4: 'grijs met alfa', 6: 'RGBA'}
        errors.append('kleurtype %d (%s), verwacht 2 (RGB)' % (ctype, names.get(ctype, 'onbekend')))
    if depth != 8:
        errors.append('bitdiepte %d, verwacht 8' % depth)
    if 'tRNS' in types:
        errors.append('tRNS-chunk aanwezig (transparantie)')
    if 'IDAT' not in types:
        errors.append('geen beelddata (IDAT)')
    phys = [c[1] for c in chunks if c[0] == 'pHYs']
    if not phys:
        errors.append('pHYs ontbreekt (resolutie niet gezet; verwacht 72 dpi)')
    else:
        x, y, unit = struct.unpack('>IIB', phys[0])
        if unit != 1:
            errors.append('pHYs-eenheid %d, verwacht 1 (meter)' % unit)
        elif x not in DPI_72_PX_PER_METER or y not in DPI_72_PX_PER_METER:
            errors.append('resolutie %.1f x %.1f dpi, verwacht 72 dpi' % (x * 0.0254, y * 0.0254))
    return errors


def validate(directory):
    """Geeft (aantal fouten, regels)."""
    lines, bad = [], 0
    for w, h in SIZES:
        path = os.path.join(directory, name_for(w, h))
        if not os.path.exists(path):
            lines.append('FOUT: %s ontbreekt' % name_for(w, h))
            bad += 1
            continue
        errs = check_file(path, w, h)
        if errs:
            bad += len(errs)
            lines += ['FOUT: %s: %s' % (name_for(w, h), e) for e in errs]
        else:
            lines.append('ok   %s  %dx%d  RGB zonder alfa  72 dpi  %d KB' % (name_for(w, h), w, h, os.path.getsize(path) // 1024))
    return bad, lines


def main(argv):
    directory = argv[1] if len(argv) > 1 else 'store/out/iap-review'
    bad, lines = validate(directory)
    print('\n'.join(lines))
    if bad:
        print('\nValidatie mislukt: %d afwijking(en).' % bad, file=sys.stderr)
        return 1
    print('\nValidatie geslaagd.')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
