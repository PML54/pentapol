# Pavages du 5x5 par 5 pentominos distincts, et unicité du complément quand on
# retire k pièces. Écrit par cowork, 2026-10-09.
# Usage : python3 -I tools/verif/unicite_5x5.py   (attendu : 856 pavages, 45 tirages)
import itertools
from collections import Counter
P = {
 'F':["011","110","010"],'I':["1","1","1","1","1"],'L':["10","10","10","11"],
 'N':["01","01","11","10"],'P':["11","11","10"],'T':["111","010","010"],
 'U':["101","111"],'V':["100","100","111"],'W':["100","110","011"],
 'X':["010","111","010"],'Y':["01","11","01","01"],'Z':["110","010","011"]}
def cells(g): return frozenset((r,c) for r,row in enumerate(g) for c,ch in enumerate(row) if ch=='1')
def norm(s):
    mr=min(r for r,c in s); mc=min(c for r,c in s)
    return frozenset((r-mr,c-mc) for r,c in s)
def orients(s):
    out={norm(s)}; fr=[norm(s)]
    while fr:
        x=fr.pop()
        for t in (norm({(c,-r) for r,c in x}), norm({(r,-c) for r,c in x})):
            if t not in out: out.add(t); fr.append(t)
    return out
N=5; W=N
PL={}
for n,g in P.items():
    ms=set()
    for o in orients(cells(g)):
        h=max(r for r,c in o)+1; w=max(c for r,c in o)+1
        for dr in range(N-h+1):
            for dc in range(N-w+1):
                ms.add(sum(1<<((r+dr)*W+c+dc) for r,c in o))
    PL[n]=sorted(ms)
FULL=(1<<(N*N))-1
names=list(P)
def tilings_region(region, pieceset):
    res=[]
    def rec(reg, avail, acc):
        if reg==0:
            if not avail: res.append(tuple(acc))
            return
        low=reg & -reg
        for n in list(avail):
            for m in PL[n]:
                if m & low and m & ~reg==0:
                    acc.append((n,m)); rec(reg & ~m, avail-{n}, acc); acc.pop()
    rec(region, frozenset(pieceset), [])
    return res
all_t=[]
def rec(reg, used, acc):
    if reg==0:
        if len(acc)==5: all_t.append(tuple(acc))
        return
    if len(acc)==5: return
    low=reg & -reg
    for n in names:
        if n in used: continue
        for m in PL[n]:
            if m & low and m & ~reg==0:
                acc.append((n,m)); rec(reg & ~m, used|{n}, acc); acc.pop()
rec(FULL, frozenset(), [])
draws=Counter(frozenset(n for n,_ in t) for t in all_t)
print("pavages (avec symétries):",len(all_t)," tirages distincts:",len(draws))
cache={}
def count(region, S):
    k=(region,S)
    if k not in cache: cache[k]=len(tilings_region(region,S))
    return cache[k]
byk=Counter(); tilings_with=Counter(); total_by_k=Counter()
for t in all_t:
    pcs=[n for n,_ in t]; msk={n:m for n,m in t}
    okk=set()
    for k in range(1,6):
        for S in itertools.combinations(pcs,k):
            reg=sum(msk[n] for n in S)
            total_by_k[k]+=1
            if count(reg,frozenset(S))==1:
                byk[k]+=1; okk.add(k)
    for k in okk: tilings_with[k]+=1
print("k  cas(unique)/cas(total)   pavages avec au moins un retrait unique")
for k in range(1,6):
    print(k, byk[k],"/",total_by_k[k], "  ", tilings_with[k],"/",len(all_t))
