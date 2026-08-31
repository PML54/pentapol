# Référence — tirages solubles et nombre de solutions, tailles 5×n

> Établi le 2026-08-31 par énumération exhaustive indépendante (hors dépôt), en réponse à la
> demande de Paul : précalculer et afficher le nombre de solutions d'un tirage.
> **Ce fichier est le test d'acceptation** du générateur Dart à écrire : sa sortie doit
> reproduire ces nombres exactement. S'ils diffèrent, c'est le générateur qui a tort.

## 1. Principe

Le plateau est entièrement déterminé par le **nombre de pièces** : n pièces ⟹ rectangle 5×n
(3×5 pour n=3 … 10×5 pour n=10, la transposition ne change pas le compte). Un tirage est donc
un **sous-ensemble de pièces**, codable sur 12 bits. Une seule table indexée par ce masque
(0..4095) couvre toutes les tailles :

    nombreDeSolutions = table[masque]        // 0 ⟺ tirage insoluble
    taille du plateau = 5 × popcount(masque)

4096 entrées sur 16 bits (compte max observé 4664) = **8 Ko**. Sur 32 bits, 16 Ko.

### 1.1 Méthode — un seul parcours par plateau, jamais un par tirage

C'est le point à ne pas rater à l'implémentation. L'intuition naturelle est fausse : on ne
choisit **pas** un tirage, on ne compte **pas** ses solutions, on ne recommence **pas** avec le
tirage suivant. Ce serait 4 004 énumérations.

Le parcours ne choisit aucun tirage à l'avance. Il remplit la **case libre la plus basse** en
essayant toutes les pièces non encore utilisées, quelles qu'elles soient. Quand le plateau est
plein, on regarde quelles pièces ont servi — nécessairement n d'entre elles — et on incrémente
`table[masqueUtilisé]`. Les C(12,n) comptes tombent **d'un seul parcours**. Neuf parcours au
total (n ∈ 3…10, plus 12), pas 4 004.

**Pourquoi c'est plus rapide.** Deux tirages qui partagent leurs premières pièces posées
partagent le même début d'arbre de recherche ; l'énumération séparée le reparcourt à chaque
fois. Et l'écart grandit là où beaucoup de tirages sont insolubles : en 5×6, 924 tirages
possibles pour 172 solubles — l'approche « un par un » lance 752 recherches qui n'aboutissent à
rien, le parcours unique n'explore jamais un tirage qui ne se complète pas.

**Mesuré sur le 5×10** (Python naïf, sans élagage des régions isolées) : 8 tirages traités un
par un coûtent 2,4 s, soit ~20 s pour les 66 ; le parcours unique fait le même travail en
**4,1 s**. Facteur 5. Sur les huit plateaux 5×n : **11 s au total**. En Dart avec un élagage
correct, moins.

**Formulation exacte, qui n'est pas cosmétique.** 27 804 n'est pas *une somme de comptes* :
c'est **le nombre de pavages du 5×10 par dix pentominos distincts**, quantité qui existe sans
qu'on parle de tirages. La ventilation par tirage est une **partition** de cet ensemble — on
range chaque pavage dans la case du sous-ensemble qu'il utilise. Le découpage par tirage est
donc une conséquence du parcours, pas une hypothèse de départ. C'est exactement pourquoi le
calcul se fait naturellement en un passage.

## 2. Résultats

| n | plateau | tirages solubles | tirages possibles | solutions au total | min | max |
|---|---|---|---|---|---|---|
| 3 | 3×5 | **7** | 220 | 28 | 4 | 4 |
| 4 | 4×5 | **26** | 495 | 200 | 4 | 20 |
| 5 | 5×5 | **45** | 792 | 856 | 8 | 80 |
| 6 | 5×6 | **172** | 924 | 2 164 | 4 | 64 |
| 7 | 5×7 | **245** | 792 | 5 584 | 4 | 204 |
| 8 | 5×8 | **261** | 495 | 13 632 | 4 | 564 |
| 9 | 5×9 | **175** | 220 | 23 608 | 4 | 2 296 |
| 10 | 5×10 | **65** | 66 | 27 804 | 4 | 4 664 |
| | **total** | **996** | 4 004 | **73 876** | | |

## 3. Contrôles de validité

Trois vérifications indépendantes, toutes passées :

1. **63 orientations fixes** au total pour les 12 pentominos (réflexions autorisées).
2. **5×12, les 12 pièces : 4 040 solutions** = 1 010 × 4, valeur classique connue. Même
   convention que le 6×10 de l'app : 2 339 × 4 = 9 356.
3. **Aucune solution invariante** par rotation 180° ni par réflexion, vérifié pour n = 3…8.

## 4. Piège à ne pas reproduire

Le facteur d'expansion n'est **pas 4 partout**. Le 5×5 est un **carré** : son groupe de symétrie
est d'ordre 8, pas 4 — tous ses comptes sont multiples de 8. Réutiliser tel quel le pipeline
« canonique × 4 » du 6×10 donnerait un résultat faux sur cette seule taille.
**Recommandation : stocker les solutions sans réduction** (voir §5), ce qui supprime la question.

## 5. Si l'on stocke aussi les solutions, pas seulement les comptes

Encodage bit6 sur les cases du plateau (5n cases × 6 bits) :

| n | solutions | octets/solution | poids |
|---|---|---|---|
| 3 | 28 | 12 | 0,3 Ko |
| 5 | 856 | 19 | 16 Ko |
| 7 | 5 584 | 27 | 151 Ko |
| 8 | 13 632 | 30 | 409 Ko |
| 9 | 23 608 | 34 | 803 Ko |
| 10 | 27 804 | 38 | 1,06 Mo |
| | | **total** | **≈ 2,5 Mo** |

Le corpus **entier** — toutes les solutions de tous les tirages de toutes les tailles — tient
donc en ~2,5 Mo non réduits. À comparer aux 105 Ko de `solutions_6x10_normalisees.bin`. C'est
embarquable sans discussion dans une app iOS, et cela rend le compteur décroissant en temps réel
disponible sur **toutes** les tailles, pas seulement le 6×10.

## 6. Constats produit, à lire avant de se réjouir

- **Le 3×5 contient 7 puzzles.** Sept, pas 220. Et chacun a exactement 4 solutions, soit **une
  seule** à symétrie près. Le 4×5 en contient 26, le 5×5 quarante-cinq.
- **Le 10×5 contient 65 puzzles** (65 des 66 tirages sont solubles). C'est le plafond de
  rejouabilité de cette taille, et il est atteint en quelques semaines de jeu.
- **Certaines pièces sont quasi absentes des petits plateaux.** Le X n'apparaît dans aucun
  tirage soluble en 3×5 ni en 4×5, et dans 2 des 45 tirages du 5×5. Le P apparaît dans les 7
  tirages du 3×5. Un joueur qui commence par les petites tailles ne rencontre pas le jeu complet.
- Total toutes tailles confondues : **996 puzzles distincts**. C'est fini, dénombrable, et
  connu d'avance — ce qui est précisément ce qui permet de l'afficher, mais aussi ce qui borne
  la durée de vie du mode.

## 7. Détail des petites tailles (pièces dans l'ordre Pentapol X P T F Y V U L N W Z I)

**5×10 — 65 tirages sur 66.** Il est plus parlant de raisonner sur les **deux pièces écartées**
(C(12,2) = 66). Le seul tirage impossible est celui qui écarte **P et F**. Le plus riche écarte
**X et W** : 4 664 pavages — sans surprise, X est le pentomino le plus contraignant et W presque
autant, les retirer libère tout ; quatre des cinq tirages les plus riches écartent le X. Le
minimum, 4 pavages — soit **un seul à symétrie près** — est atteint en écartant P et I, P et N,
P et Y, ou L et I. Moyenne : 428 pavages par tirage, pour un écart de 4 à 4 664.

**3×5 — 7 tirages, 4 solutions chacun :**
PFU, PUN, PVL, PVU, PYU, TYL, VLN

**4×5 — 26 tirages :**
PYLW 20 · PTVL 16 · FYUL 12 · PYVL 12 · FVUL 8 · PFUI 8 · PTVW 8 · PULN 8 · PUNI 8 · PVLI 8 ·
PVLZ 8 · PVUI 8 · PYUI 8 · TYLI 8 · VLNI 8 · VLNZ 8 · YVUL 8 · PFUL 4 · PFYU 4 · PTYL 4 ·
PVUZ 4 · PYLZ 4 · PYUL 4 · PYUN 4 · TFYL 4 · TYVN 4

**5×5 — 45 tirages :**
PYLWI 80 · PTVLI 64 · FYULI 48 · PYVLI 48 · FVULI 32 · PTVWI 32 · PULNI 32 · PVLZI 32 ·
VLNZI 32 · YVULI 32 · PYVLN 24 · PYVNW 24 · PFULI 16 · PFVUN 16 · PFYUI 16 · PTLNW 16 ·
PTYLI 16 · PULNZ 16 · PVUZI 16 · PYLWZ 16 · PYLZI 16 · PYULI 16 · PYUNI 16 · TFYLI 16 ·
TYVLW 16 · TYVNI 16 · FYULZ 8 · PFULW 8 · PFVLW 8 · PFYVL 8 · PTFYU 8 · PTULZ 8 · PTYLW 8 ·
PVULW 8 · PYLNW 8 · PYUNZ 8 · PYVLZ 8 · PYVUN 8 · PYVWZ 8 · TFYVN 8 · VULNZ 8 · XPFUL 8 ·
XPTUL 8 · YULNW 8 · YVULZ 8

---

## 8. Décisions du 2026-08-31 (validées par Paul)

Chantier découpé en deux temps. **A n'engage rien de B ; B réutilise l'asset de A.**

**A — table des comptes (certain, rien à mesurer).**
`tools/generate_subset_counts.dart` → `assets/data/subset_counts.bin`, 4096 × uint16 = 8 Ko.
Index = masque 12 bits, **bit (id − 1)** dans l'ordre `pentominos.dart` (X=1, P=2, T=3, F=4,
Y=5, V=6, U=7, L=8, N=9, W=10, Z=11, I=12). Le générateur fait **un parcours par plateau**
(n ∈ 3…10 plus 12), pas un par tirage, et **échoue** si ses totaux ne reproduisent pas le §2.
Conséquences côté app : le tirage devient un choix au hasard parmi les masques solubles
(distribution identique à l'actuel rejet successif), la boucle de tirage disparaît, la question
du délai d'expiration disparaît, la difficulté tombe d'elle-même, et `solutionCount` reste
**non nullable** — la modification `nullable()` de `CurrentGame.solutionCount` envisagée le
2026-08-31 au matin est **annulée**, il n'y a plus de changement de schéma.

**B — corpus complet (conditionnel, ~2,5 Mo).**
Supprime `LiveSolutionSource`, ne laisse qu'une seule implémentation de `SolutionSource`, et
**sort `PentoscopeSolver` de l'application livrée** (il ne reste que dans `tools/`) — donc sort
du runtime la troncature silencieuse de `maxSeconds = 30`. Subordonné à deux mesures (§9).

**Affichage.** Le compte est affiché **dans le dialogue de nouvelle partie**, au moment du
tirage, avec un bouton « autre tirage ». Raison : le compte n'est vrai qu'au tirage ; dès le
premier placement il est périmé, et un nombre périmé est pire qu'un nombre absent. Le compteur
de la barre reste ce qu'il est (décroissant, 6×10 seulement) jusqu'à B, qui le rend décroissant
partout. Coût assumé : le tirage passe du moment de la validation au moment du dialogue, donc
c'est le masque — non plus la seule taille — qui est transmis à la partie. Cette plomberie est
de toute façon nécessaire à B.

## 9. Protocole de mesure pour B

1. **Durée de génération.** Elle est mesurée **gratuitement par A** : le générateur chronomètre
   et imprime chaque plateau séparément. A et B font le même parcours, B écrit des octets en
   plus. Si A traite les neuf plateaux en secondes, B est un non-sujet. Si A met des heures,
   c'est l'élagage du solveur qu'il faut corriger avant d'élargir le périmètre — et non B qu'il
   faut abandonner. *(Repère : une énumération naïve sans élagage des régions isolées fait les
   huit plateaux 5×n en 11 s mais dépasse 5 min sur un 3×20. Le coût vient de la forme du
   plateau et de l'élagage, pas du nombre de solutions.)*
2. **Fluidité sur l'appareil.** Instrumenter `_solutionStatus` avec un `Stopwatch` sous
   `kDebugMode` (donc rien n'est livré), jouer un 6×10 complet, relever le **pire** temps par
   placement sur 9 356 solutions. Le 10×5 en aura 27 804, soit ×3. Seuil de décision : sous
   ~5 ms, B passe sans rien changer ; au-delà de ~10 ms, réécrire l'appariement en `Uint8List`
   (comparaison octet à octet, sans allocation) **avant** B — `BigInt` est boxé et coûteux, et
   c'est le mauvais outil pour un appariement de masques.
