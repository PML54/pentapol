# Distances d'appuis d'isométrie (4 icônes : rot CW, rot CCW, miroir H, miroir V)
# entre orientations d'une même pièce. Écrit par cowork, 2026-10-09.
# Usage : python3 -I tools/verif/iso_distances.py
from collections import deque, Counter
P = {
 'F':["011","110","010"],'I':["1","1","1","1","1"],'L':["10","10","10","11"],
 'N':["01","01","11","10"],'P':["11","11","10"],'T':["111","010","010"],
 'U':["101","111"],'V':["100","100","111"],'W':["100","110","011"],
 'X':["010","111","010"],'Y':["01","11","01","01"],'Z':["110","010","011"]}
def cells(g): return frozenset((r,c) for r,row in enumerate(g) for c,ch in enumerate(row) if ch=='1')
def norm(s):
    mr=min(r for r,c in s); mc=min(c for r,c in s)
    return frozenset((r-mr,c-mc) for r,c in s)
def cw(s):  return norm({(c,-r) for r,c in s})
def ccw(s): return norm({(-c,r) for r,c in s})
def mh(s):  return norm({(r,-c) for r,c in s})
def mv(s):  return norm({(-r,c) for r,c in s})
OPS=[cw,ccw,mh,mv]
print("piece orient  paires(d0,d1,d2,d3+)  max")
for n,g in P.items():
    s0=norm(cells(g)); seen={s0}; q=deque([s0])
    while q:
        s=q.popleft()
        for f in OPS:
            t=f(s)
            if t not in seen: seen.add(t); q.append(t)
    O=list(seen); cnt=Counter()
    for a in O:
        d={a:0}; q=deque([a])
        while q:
            s=q.popleft()
            for f in OPS:
                t=f(s)
                if t not in d: d[t]=d[s]+1; q.append(t)
        for b in O: cnt[d[b]]+=1
    print(n,len(O),[cnt[i] for i in range(4)],max(cnt))
