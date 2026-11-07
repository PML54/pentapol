"""Extrait les 856 pavages 5×5 du corpus livré, sans solveur ni génération live.
Usage : python3 tools/generate_discovery_boards.py (depuis la racine du dépôt).
"""
import re
import struct
from collections import Counter
from pathlib import Path

source = Path('lib/common/pentominos.dart').read_text()
ids = {
    int(code): int(piece)
    for piece, code in re.findall(r'Pento\(\s*id:\s*(\d+).*?bit6:\s*(\d+)', source, re.S)
}
assert len(ids) == 12
counts = struct.unpack('<4096H', Path('assets/data/subset_counts.bin').read_bytes())
blob = Path('assets/data/solutions_corpus.bin').read_bytes()
boards = []
masks = set()
offset = 0
for mask, count in enumerate(counts):
    size = mask.bit_count()
    if not 3 <= size <= 10:
        continue
    if size == 5 and count:
        masks.add(mask)
        for index in range(count):
            cells = [ids[code] for code in blob[offset + index * 25:offset + (index + 1) * 25]]
            assert len(cells) == 25
            assert len(set(cells)) == 5
            assert set(Counter(cells).values()) == {5}
            assert sum(1 << (piece - 1) for piece in set(cells)) == mask
            boards.append(''.join(format(piece, 'x') for piece in cells))
    offset += count * 5 * size
assert offset == len(blob), 'Corpus tronqué ou compteurs incompatibles'
assert len(boards) == len(set(boards)) == 856
assert len(masks) == 45
output = Path('lib/pentoscope/home/discovery_boards_data.dart')
output.write_text(
    '// Modified: 2026-10-28 08:05 — extraire les pavages 5×5 du corpus pour la découverte.\n'
    '// lib/pentoscope/home/discovery_boards_data.dart\n'
    '// GÉNÉRÉ par tools/generate_discovery_boards.py — ne pas modifier à la main.\n'
    '// 856 pavages / 45 tirages ; 25 identifiants hexadécimaux, rangés par ligne.\n'
    'const List<String> kDiscoveryBoards5x5 = [\n'
    + ''.join(f"  '{board}',\n" for board in boards)
    + '];\n'
)
print(f'{len(boards)} pavages 5×5, {len(masks)} tirages vérifiés : {output}')
