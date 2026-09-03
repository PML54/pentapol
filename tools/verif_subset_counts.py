#!/usr/bin/env python3
# Controle de l'asset livre assets/data/subset_counts.bin par enumeration independante.
#
# Ce que REFERENCE_TIRAGES.md section 3 verifiait : l'enumeration hors depot.
# Ce que ce script verifie : le FICHIER EMBARQUE dans l'app, contre un backtracking
# refait a partir des seules formes de lib/common/pentominos.dart. Motif : CLAUDE.md
# invariant 2 (findAllSolutions rend une liste tronquee sans le signaler a l'expiration)
# rendrait un tirage soluble mais lent indiscernable d'un tirage insoluble.
#
# Duree : environ 70 s. Usage : python3 tools/verif_subset_counts.py
import struct, os, itertools, re, time
from collections import defaultdict

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

d = open(REPO + '/assets/data/subset_counts.bin', 'rb').read()
n = len(d) // 2
vals = struct.unpack('<%dH' % n, d[:n * 2])
table = defaultdict(int)
for m, v in enumerate(vals):
    if v > 0: table[bin(m).count('1')] += 1

SRC = open(REPO + '/lib/common/pentominos.dart').read()
pieces = {}
for b in SRC.split('  Pento(')[1:]:
    mid = re.search(r'id:\s*(\d+),', b); mno = re.search(r'numOrientations:\s*(\d+),', b)
    if not mid or not mno: continue
    pid, no = int(mid.group(1)), int(mno.group(1))
    nums = [int(x) for x in re.findall(r'-?\d+', b[b.index('cartesianCoords:'):])][:no * 10]
    pieces[pid] = [[(nums[k*10+2*i], nums[k*10+2*i+1]) for i in range(5)] for k in range(no)]
assert len(pieces) == 12, len(pieces)

def norm(c):
    mx, my = min(p[0] for p in c), min(p[1] for p in c)
    return frozenset((x - mx, y - my) for x, y in c)

SHAPES = {pid: {norm(o) for o in os_} for pid, os_ in pieces.items()}

def solvable(ids, W, H):
    place = {}
    for pid in ids:
        lst = []
        for s in SHAPES[pid]:
            w = max(x for x, y in s) + 1; h = max(y for x, y in s) + 1
            for ax in range(W - w + 1):
                for ay in range(H - h + 1):
                    lst.append(frozenset((x + ax, y + ay) for x, y in s))
        place[pid] = lst
    order = [(y, x) for y in range(H) for x in range(W)]
    def rec(rem, occ):
        if not rem: return True
        for y, x in order:
            if (x, y) not in occ: t = (x, y); break
        for pid in rem:
            for cells in place[pid]:
                if t in cells and not (cells & occ):
                    if rec([p for p in rem if p != pid], occ | cells): return True
        return False
    return rec(list(ids), frozenset())

print(f"{'pieces':>7} {'plateau':>9} {'masques':>8} {'solubles':>9} {'asset':>7} {'accord':>7} {'sec':>6}")
grand = 0; ok_all = True
for k in range(3, 11):
    W, H = (k, 5) if k < 5 else (5, 5) if k == 5 else (5, k)
    t0 = time.time(); cnt = 0
    for ids in itertools.combinations(range(1, 13), k):
        if solvable(list(ids), W, H): cnt += 1
    grand += cnt
    ok = cnt == table[k]; ok_all &= ok
    print(f"{k:7} {W}x{H:<7} {len(list(itertools.combinations(range(1,13),k))):8} "
          f"{cnt:9} {table[k]:7} {'OUI' if ok else 'NON':>7} {time.time()-t0:6.1f}")
print(f"\nTOTAL enumere : {grand}   asset : {sum(table[k] for k in range(3,11))}")
print("RESULTAT :", "l'asset est conforme" if ok_all and grand == 996 else "ECART — NE PAS PUBLIER")

# controle du 6x10, par la taille de l'asset (360 bits = 45 octets par solution)
b6 = os.path.getsize(REPO + '/assets/data/solutions_6x10_normalisees.bin')
print(f"6x10 : {b6} octets / 45 = {b6/45:.0f} formes canoniques, x4 = {int(b6/45)*4}")
