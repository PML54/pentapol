"""Build printable models and the bilingual static site from Pentapol's pieces.

Requires reportlab, Pillow and PyMuPDF. Run from any directory with --repo PATH.
"""
import argparse
import html
import json
import re
from pathlib import Path

import fitz
from PIL import Image, ImageDraw, ImageFont
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas

SITE = Path(__file__).resolve().parents[1]
PUBLIC = SITE / 'public'
SHAPES = {
    'F': ['011', '110', '010'], 'I': ['1', '1', '1', '1', '1'],
    'L': ['10', '10', '10', '11'], 'P': ['11', '11', '10'],
    'N': ['10', '11', '01', '01'], 'T': ['111', '010', '010'],
    'U': ['101', '111'], 'V': ['100', '100', '111'],
    'W': ['100', '110', '011'], 'X': ['010', '111', '010'],
    'Y': ['01', '11', '01', '01'], 'Z': ['110', '010', '011'],
}


def normalize(cells):
    left = min(x for x, y in cells)
    top = min(y for x, y in cells)
    return tuple(sorted((x - left, y - top) for x, y in cells))


def orientations(cells):
    result = set()
    for reflected in (False, True):
        current = [(-x if reflected else x, y) for x, y in cells]
        for _ in range(4):
            result.add(normalize(current))
            current = [(-y, x) for x, y in current]
    return result


def load_pieces(repo):
    source = (repo / 'lib/common/pentominos.dart').read_text()
    letter_block = source.split('const List<String> pentominoLetters = [')[1].split('];')[0]
    letters = re.findall(r"'([A-Z])'", letter_block)
    settings = (repo / 'lib/models/app_settings.dart').read_text()
    classic = settings.split('Color _getClassicColor')[1].split('Color _getPastelColor')[0]
    assert 'colors[pieceId % colors.length]' in classic, 'Recheck the palette indexing'
    palette = re.findall(r'Color\(0xFF([0-9A-F]{6})\)', classic)
    assert len(letters) == len(palette) == 12
    bases = re.findall(r'id:\s*(\d+),.*?baseShape:\s*\[([^]]+)\]', source, re.S)
    assert len(bases) == 12
    pieces = {}
    for number, base in bases:
        number = int(number)
        letter = letters[number - 1]
        cells = [(x, y) for y, row in enumerate(SHAPES[letter]) for x, value in enumerate(row) if value == '1']
        stored = [((int(n) - 1) % 5, (int(n) - 1) // 5) for n in base.split(',') if n.strip()]
        assert len(cells) == 5 and normalize(stored) in orientations(cells), letter
        pieces[letter] = {'id': number, 'cells': cells, 'color': '#' + palette[number % 12]}
    assert len({min(orientations(p['cells'])) for p in pieces.values()}) == 12
    # Verify the first challenge against an explicit, completely filled 3 x 5 board.
    solution = ['VLLLL', 'VLPPP', 'VVVPP']
    assert [pieces[k]['id'] for k in ('L', 'P', 'V')] == [8, 2, 6]
    for letter in ('L', 'P', 'V'):
        covered = [(x, y) for y, row in enumerate(solution) for x, value in enumerate(row) if value == letter]
        assert normalize(covered) in orientations(pieces[letter]['cells'])
    return pieces


def make_pdf(lang, pieces):
    path = PUBLIC / 'downloads' / f'pentapol-cardboard-{lang}.pdf'
    c = canvas.Canvas(str(path), pagesize=A4, invariant=1)
    c.setTitle('Fabrique ton Pentapol' if lang == 'fr' else 'Make your own Pentapol')
    c.setAuthor('Pentapol')

    def text(x, y, value, size=10, bold=False):
        c.setFillColorRGB(.12, .15, .18)
        c.setFont('Helvetica-Bold' if bold else 'Helvetica', size)
        assert c.stringWidth(value, c._fontname, size) <= (210 - x - 10) * mm, value
        c.drawString(x * mm, (297 - y) * mm, value)

    def line(x, y, a, b):
        c.line(x * mm, (297 - y) * mm, a * mm, (297 - b) * mm)

    def piece(letter, x, y):
        p = pieces[letter]
        cells = set(p['cells'])
        text(x, y - 4, str(p['id']), 12, True)
        c.setFillColor(p['color'])
        for i, j in cells:
            c.rect((x + 20 * i) * mm, (297 - y - 20 * (j + 1)) * mm, 20 * mm, 20 * mm, fill=1, stroke=0)
        for i, j in cells:
            for dx, dy, edge in [(0, -1, (0, 0, 1, 0)), (1, 0, (1, 0, 1, 1)), (0, 1, (0, 1, 1, 1)), (-1, 0, (0, 0, 0, 1))]:
                inner = (i + dx, j + dy) in cells
                c.setStrokeColorRGB(*((.98, .98, .98) if inner else (.1, .1, .1)))
                c.setLineWidth(.35 if inner else 1.2)
                a, b, d, e = edge
                line(x + 20 * (i + a), y + 20 * (j + b), x + 20 * (i + d), y + 20 * (j + e))

    for page, letters in enumerate([list(SHAPES)[:6], list(SHAPES)[6:]]):
        text(15, 17, 'FABRIQUE TON PENTAPOL' if lang == 'fr' else 'MAKE YOUR OWN PENTAPOL', 19, True)
        text(15, 26, COPY[lang]['cardboardSlogan'], 12)
        for k, letter in enumerate(letters):
            y = (55 if k < 3 else 175) if page == 0 else (45 if k < 3 else 120)
            piece(letter, 15 + 65 * (k % 3), y)
        if page == 0:
            text(15, 265, 'Colle les feuilles sur du carton fin, puis découpe les contours noirs.' if lang == 'fr' else 'Glue the sheets onto thin cardboard, then cut along the black outlines.')
            text(15, 272, 'Garde les cinq carrés de chaque pièce attachés. Fais-toi aider si besoin.' if lang == 'fr' else 'Keep all five squares connected. Ask an adult for help if needed.')
        else:
            text(15, 211, 'PREMIER DÉFI - Utilise les pièces 8, 2 et 6.' if lang == 'fr' else 'FIRST CHALLENGE - Use pieces 8, 2 and 6.', 11, True)
            c.setStrokeColorRGB(.3, .3, .3)
            c.setLineWidth(.5)
            for i in range(6):
                line(15 + 20 * i, 218, 15 + 20 * i, 278)
            for j in range(4):
                line(15, 218 + 20 * j, 115, 218 + 20 * j)
            instructions = ['Remplis le rectangle.', 'Tu peux tourner', 'et retourner les pièces.', 'Aucun trou,', 'aucune superposition.'] if lang == 'fr' else ['Fill the rectangle.', 'You can rotate', 'and flip the pieces.', 'Leave no gaps', 'or overlaps.']
            for y, value in zip([232, 242, 248, 260, 266], instructions):
                text(124, y, value)
        text(15, 290, 'A4 - Imprimer à 100 % / taille réelle - Un carré mesure 2 cm.' if lang == 'fr' else 'A4 - Print at 100% / actual size - Each square measures 2 cm.', 9)
        text(185, 290, f'{page + 1}/2', 9)
        c.showPage()
    c.save()
    document = fitz.open(path)
    assert len(document) == 2
    for page in document:
        assert abs(page.rect.width - A4[0]) < .01 and abs(page.rect.height - A4[1]) < .01
        for block in page.get_text('blocks'):
            assert page.rect.contains(fitz.Rect(block[:4])), block
    return path


def make_preview(pieces):
    scale = 3
    image = Image.new('RGBA', (600 * scale, 670 * scale))
    draw = ImageDraw.Draw(image)
    # Font is supplied by Pillow, avoiding system-specific paths.
    font = ImageFont.load_default(size=18 * scale)
    for index, letter in enumerate(SHAPES):
        piece = pieces[letter]
        cells = piece['cells']
        column, row = index % 4, index // 4
        width = max(x for x, y in cells) + 1
        height = max(y for x, y in cells) + 1
        size = 32
        left = column * 150 + (150 - width * size) / 2
        top = row * 220 + 30 + (160 - height * size) / 2
        for x, y in cells:
            x0, y0 = (left + x * size) * scale, (top + y * size) * scale
            draw.rectangle((x0, y0, x0 + size * scale, y0 + size * scale), fill=piece['color'], outline='#ffffff', width=2)
        draw.text(((column * 150 + 75) * scale, (row * 220 + 202) * scale), str(piece['id']), font=font, anchor='mm', fill='#172e42')
    image.resize((900, 1005), Image.Resampling.LANCZOS).save(PUBLIC / 'assets/pieces.png')


def make_page(lang):
    copy = COPY[lang]
    fr = lang == 'fr'
    route = 'fr/fabriquer' if fr else 'en/make'
    other = '/en/make/' if fr else '/fr/fabriquer/'
    escape = html.escape
    steps = ''.join(f'<li>{escape(copy[key])}</li>' for key in ['cardboardStepPrint', 'cardboardStepGlue', 'cardboardStepCut', 'cardboardStepPlay', 'cardboardStepInvent'])
    content = f'''<!doctype html>
<html lang="{lang}">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{escape(copy['cardboardTitle'])} · Pentapol</title>
<meta name="description" content="{escape(copy['cardboardIntro'])}">
<link rel="alternate" hreflang="fr" href="/fr/fabriquer/">
<link rel="alternate" hreflang="en" href="/en/make/">
<link rel="stylesheet" href="/assets/style.css">
</head>
<body>
<a class="skip" href="#main">{'Aller au contenu' if fr else 'Skip to content'}</a>
<header class="shell"><a class="brand" href="/">Pentapol</a>
<nav aria-label="{'Langue' if fr else 'Language'}"><a href="/fr/fabriquer/" lang="fr" {'aria-current="page"' if fr else ''}>Français</a><a href="/en/make/" lang="en" {'' if fr else 'aria-current="page"'}>English</a></nav></header>
<main id="main">
<section class="hero shell">
<div class="intro"><h1>{escape(copy['cardboardSlogan'])}</h1>
<p class="lead">{escape(copy['cardboardTitle'])}.</p><p>{escape(copy['cardboardIntro'])}</p>
<a class="download" href="/downloads/pentapol-cardboard-{lang}.pdf" download>{escape(copy['cardboardDownload'])}</a>
<p class="print-note">{'PDF en français · 2 pages A4 · Impression à 100 %' if fr else 'English PDF · 2 A4 pages · Print at 100%'}</p></div>
<figure><img src="/assets/pieces.png" width="900" height="1005" alt="{'Les douze pièces de Pentapol, avec leurs couleurs et leurs numéros officiels.' if fr else 'All twelve Pentapol pieces, with their official colours and numbers.'}"></figure>
</section>
<section class="workshop"><div class="shell workshop-layout">
<aside><h2>{escape(copy['cardboardMaterialsTitle'])}</h2><p>{escape(copy['cardboardMaterials'])}</p><p class="adult">{escape(copy['cardboardAdultHelp'])}</p></aside>
<div><h2>{'À toi de fabriquer !' if fr else 'Time to make it!'}</h2><ol>{steps}</ol></div>
</div></section>
<section class="shell challenge"><div><h2>{'Ton premier défi' if fr else 'Your first challenge'}</h2><p>{'Trois pièces, quinze cases. Place les pièces 8, 2 et 6 dans le rectangle. Tu peux les tourner et les retourner.' if fr else 'Three pieces, fifteen squares. Fit pieces 8, 2 and 6 into the rectangle. You can rotate and flip them.'}</p><p>{'Le plateau à la bonne échelle est sur la deuxième page du PDF.' if fr else 'The correctly sized board is on the second page of the PDF.'}</p></div>
<div class="board" role="img" aria-label="{'Grille vide de trois lignes et cinq colonnes.' if fr else 'Empty board with three rows and five columns.'}">{'<span></span>' * 15}</div>
</section>
</main><footer class="shell"><span>Pentapol</span><a href="{other}" lang="{'en' if fr else 'fr'}">{'Read in English' if fr else 'Lire en français'}</a></footer>
</body></html>'''
    directory = PUBLIC / route
    directory.mkdir(parents=True, exist_ok=True)
    (directory / 'index.html').write_text(content)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--repo', type=Path, default=SITE.parent)
    args = parser.parse_args()
    COPY = {lang: json.loads((args.repo / f'lib/l10n/app_{lang}.arb').read_text()) for lang in ('fr', 'en')}
    (PUBLIC / 'downloads').mkdir(parents=True, exist_ok=True)
    (PUBLIC / 'assets').mkdir(parents=True, exist_ok=True)
    pieces = load_pieces(args.repo)
    for language in ('fr', 'en'):
        print(make_pdf(language, pieces))
        make_page(language)
    make_preview(pieces)
    print('Verified 12 unique pentominoes, official numbering/colours and the 3 x 5 solution.')
