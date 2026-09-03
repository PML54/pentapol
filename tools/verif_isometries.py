#!/usr/bin/env python3
# Verification des isometries et de la resolubilite du niveau 1 (3x5).
# Ne suppose rien : relit lib/common/pentominos.dart et
# lib/pentoscope/home/home_tirages_data.dart, reenumere les pavages, et calcule
# la distance D4 engendree par les 4 boutons reels de la barre d'isometries.
# Voir docs/CAHIER_DES_CHARGES_V1.md sections 2.4, 2.5 et 10.
# Usage : python3 tools/verif_isometries.py   (depuis la racine du depot)
import os
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

import re, itertools, sys
from collections import defaultdict

SRC = open(REPO+'/lib/common/pentominos.dart').read()

# --- 1. parser les blocs Pento : id, numOrientations, cartesianCoords -------
blocks = SRC.split('  Pento(')[1:]
pieces = {}
for b in blocks:
    mid = re.search(r'id:\s*(\d+),', b)
    mno = re.search(r'numOrientations:\s*(\d+),', b)
    if not mid or not mno: continue
    pid, no = int(mid.group(1)), int(mno.group(1))
    start = b.index('cartesianCoords:')
    seg = b[start:]
    nums = [int(x) for x in re.findall(r'-?\d+', seg)]
    # 5 cellules x 2 coords x numOrientations
    need = no*10
    assert len(nums) >= need, (pid, len(nums), need)
    nums = nums[:need]
    orients = []
    for k in range(no):
        cells = [(nums[k*10+2*i], nums[k*10+2*i+1]) for i in range(5)]
        orients.append(cells)
    pieces[pid] = orients
assert len(pieces) == 12, len(pieces)

LETTERS = re.search(r'const List<String> pentominoLetters = \[(.*?)\];', SRC, re.S).group(1)
LETTERS = re.findall(r"'([A-Z])'", LETTERS)
letter = lambda pid: LETTERS[pid-1]

def norm(cells):
    mx, my = min(c[0] for c in cells), min(c[1] for c in cells)
    return frozenset((x-mx, y-my) for x, y in cells)

# --- 2. classes de rotation : orbites des orientations sous rotation 90 -----
def rot90(cells):  # (x,y) -> (-y,x)
    return norm([(-y, x) for x, y in cells])

rotclass = {}   # pid -> list[int] : index d'orientation -> id de classe
for pid, orients in pieces.items():
    shapes = [norm(o) for o in orients]
    idx = {s: i for i, s in enumerate(shapes)}
    cls = [-1]*len(shapes)
    c = 0
    for i, s in enumerate(shapes):
        if cls[i] != -1: continue
        cur, orbit = s, []
        for _ in range(4):
            if cur in idx: orbit.append(idx[cur])
            cur = rot90(cur)
        for j in orbit: cls[j] = c
        c += 1
    rotclass[pid] = cls

# --- 3. tirages de l'accueil (les 7 masques du 3x5) ------------------------
HS = open(REPO+'/lib/pentoscope/home/home_tirages_data.dart').read()
tirages = []
chunks = HS.split("HomeTirage('")[1:]
for ch in chunks:
    name = ch[:ch.index("'")]
    ids = [int(x) for x in re.findall(r'HomePiece\((\d+),', ch)]
    tirages.append((name, ids))
print('tirages lus :', [(n, ''.join(letter(i) for i in ids)) for n, ids in tirages])

# --- 4. enumeration COMPLETE des pavages du 3 large x 5 haut ---------------
W, H = 3, 5
def solve(ids):
    sols = []
    placements = defaultdict(list)  # pid -> (oidx, frozenset cells)
    for pid in ids:
        for oi, o in enumerate(pieces[pid]):
            s = norm(o)
            w = max(x for x, y in s)+1; h = max(y for x, y in s)+1
            for ax in range(W-w+1):
                for ay in range(H-h+1):
                    placements[pid].append((oi, frozenset((x+ax, y+ay) for x, y in s)))
    def rec(rem, occupied, chosen):
        if not rem:
            sols.append(dict(chosen)); return
        # case libre la plus haute-gauche
        target = min(((x, y) for y in range(H) for x in range(W) if (x, y) not in occupied),
                     key=lambda p: (p[1], p[0]))
        for pid in rem:
            for oi, cells in placements[pid]:
                if target in cells and not (cells & occupied):
                    chosen.append((pid, oi))
                    rec([p for p in rem if p != pid], occupied | cells, chosen)
                    chosen.pop()
    rec(list(ids), frozenset(), [])
    return sols

# --- 5. probabilite d'etre bloque sans miroir ------------------------------
print()
print(f"{'tirage':8} {'sols':>5} {'orient.init':>12} {'bloques':>9} {'P(bloque)':>10}")
tot_blocked = tot_all = 0
detail = []
for name, ids in tirages:
    sols = solve(ids)
    # classes de rotation requises, par solution
    req = [tuple(rotclass[pid][s[pid]] for pid in ids) for s in sols]
    reqset = set(req)
    combos = list(itertools.product(*[range(len(pieces[pid])) for pid in ids]))
    blocked = 0
    for c in combos:
        start = tuple(rotclass[ids[k]][c[k]] for k in range(len(ids)))
        if start not in reqset: blocked += 1
    tot_blocked += blocked; tot_all += len(combos)
    detail.append((name, len(sols), len(combos), blocked))
    print(f"{name:8} {len(sols):5} {len(combos):12} {blocked:9} {blocked/len(combos):9.1%}")
print()
print(f"TOTAL (tirage uniforme des 7) : {tot_blocked}/{tot_all} = {tot_blocked/tot_all:.1%}")

# --- 6. correction : le masque est tire UNIFORMEMENT parmi les 7 -----------
probs = [b/c for (_, _, c, b) in detail]
print(f"P(bloque) correcte, masque uniforme sur les 7 : {sum(probs)/len(probs):.1%}")

# --- 7. dans les cas bloques, combien de pieces peut-on quand meme poser ? --
print()
print("Cas bloques : nombre max de pieces posables sans miroir")
from collections import Counter
glob = Counter()
for name, ids in tirages:
    sols = solve(ids)
    req = set(tuple(rotclass[pid][s[pid]] for pid in ids) for s in sols)
    cnt = Counter()
    for c in itertools.product(*[range(len(pieces[pid])) for pid in ids]):
        start = tuple(rotclass[ids[k]][c[k]] for k in range(len(ids)))
        if start in req: continue
        # placements autorises : orientations de la classe de depart uniquement
        allowed = {}
        for k, pid in enumerate(ids):
            cl = start[k]; lst = []
            for oi, o in enumerate(pieces[pid]):
                if rotclass[pid][oi] != cl: continue
                s = norm(o); w = max(x for x,y in s)+1; h = max(y for x,y in s)+1
                for ax in range(W-w+1):
                    for ay in range(H-h+1):
                        lst.append(frozenset((x+ax,y+ay) for x,y in s))
            allowed[pid] = lst
        best = 0
        def rec2(rem, occ, n):
            global best
            best = max(best, n)
            if best == len(ids): return
            for pid in rem:
                for cells in allowed[pid]:
                    if not (cells & occ):
                        rec2([p for p in rem if p != pid], occ | cells, n+1)
        best = 0
        rec2(list(ids), frozenset(), 0)
        cnt[best] += 1
    glob += cnt
    print(f"  {name}: " + ", ".join(f"{k} piece(s) posables : {v}" for k, v in sorted(cnt.items())))
tot = sum(glob.values())
print("  TOTAL : " + ", ".join(f"{k} -> {v} ({v/tot:.0%})" for k, v in sorted(glob.items())))

# --- 8. distance D4 engendree par les 4 boutons + minimum d'isometries ------
from collections import deque
def r_cw(c):  return norm([( y, -x) for x, y in c])
def r_tw(c):  return norm([(-y,  x) for x, y in c])
def sym_h(c): return norm([(-x,  y) for x, y in c])
def sym_v(c): return norm([( x, -y) for x, y in c])
GEN = [r_cw, r_tw, sym_h, sym_v]

def dist_table(pid):
    shapes = [norm(o) for o in pieces[pid]]
    idx = {s: i for i, s in enumerate(shapes)}
    D = {}
    for src in range(len(shapes)):
        d = {src: 0}; q = deque([src])
        while q:
            u = q.popleft()
            for g in GEN:
                v = idx.get(g(shapes[u]))
                if v is not None and v not in d:
                    d[v] = d[u] + 1; q.append(v)
        D[src] = d
    return D

DT = {pid: dist_table(pid) for pid in pieces}
import statistics as st
print()
print("Diametre par piece (appuis max pour atteindre une orientation) :")
print("  " + ", ".join(f"{letter(p)}={max(max(v.values()) for v in DT[p].values())}"
                       for p in sorted(pieces)))
print()
print("Cout moyen d'une piece seule (depart uniforme, cible imposee) :")
for pid in sorted(pieces):
    vals = [DT[pid][s][t] for s in DT[pid] for t in DT[pid][s]]
    print(f"  {letter(pid)} ({len(pieces[pid])} orient.) : moyenne {st.mean(vals):.2f}, max {max(vals)}")
print()
print("NIVEAU 1 — minimum d'isometries pour resoudre")
print(f"{'tirage':8} {'min':>4} {'median':>7} {'max':>4}   distribution")
allmins = []
for name, ids in tirages:
    sols = solve(ids)
    mins = []
    for c in itertools.product(*[range(len(pieces[pid])) for pid in ids]):
        mins.append(min(sum(DT[ids[k]][c[k]].get(s[ids[k]], 99) for k in range(len(ids)))
                        for s in sols))
    allmins += mins
    cnt = Counter(mins)
    print(f"{name:8} {min(mins):4} {st.median(mins):7} {max(mins):4}   " +
          " ".join(f"{k}:{v}" for k, v in sorted(cnt.items())))
print(f"\nTOUS TIRAGES : mediane {st.median(allmins)}, moyenne {st.mean(allmins):.2f}, "
      f"max {max(allmins)}, minimum nul dans {allmins.count(0)}/{len(allmins)} cas")
