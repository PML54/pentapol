# Définition des pièces et encodage par bits

## La grille 5×5 de référence

Chaque pentomino est défini sur une **grille de référence 5×5** de 25 cases numérotées de 1 à 25. La numérotation part du **haut gauche**, ligne par ligne de haut en bas :

```
Ligne 0 (haut)  :  1   2   3   4   5
Ligne 1         :  6   7   8   9  10
Ligne 2         : 11  12  13  14  15
Ligne 3         : 16  17  18  19  20
Ligne 4 (bas)   : 21  22  23  24  25
```

> La numérotation croît vers la droite et vers le bas. La case 1 est en **haut à gauche**, la case 25 en bas à droite. C'est la **convention écran** (y vers le bas), la même que celle des `cartesianCoords` et du plateau 6×10 — une seule convention dans tout le projet.
>
> Conversion : `x = (cellNum - 1) % 5`, `y = (cellNum - 1) ~/ 5`.

> **Correction (27/08/2026).** Ce paragraphe affirmait auparavant que la case 1 était en
> bas à gauche et que la numérotation croissait vers le haut. C'était faux, et cela
> contredisait la section « plateau 6×10 » du même document. Vérifié mécaniquement :
> pour les **63 orientations** de `pentominos.dart`, la conversion
> `(x, y) = ((c−1)%5, (c−1)~/5)` reproduit les `cartesianCoords` **63 fois sur 63** ;
> l'hypothèse « bas gauche » n'en reproduit qu'**1 sur 63** (la pièce X, symétrique,
> qui satisfait les deux).

Chaque pièce est définie par son `baseShape` : la liste des 5 numéros de cases occupées dans son orientation de référence.

**Exemple — pièce 1 (croix, forme X) :**
```
baseShape: [2, 6, 7, 8, 12]

. X .
X X X
. X .
```
Cases 6, 7, 8 forment la ligne centrale, cases 2 et 12 les extensions verticales.

---

## Le `bit6` : code unique 6 bits de chaque pièce

Chaque pièce reçoit un **code entier sur 6 bits** (`bit6`) qui lui est unique. Ce code est utilisé pour encoder les solutions du plateau 6×10 sous forme de BigInt compact.

| Pièce | ID | bit6 | binaire     | Orientations | Forme (depuis `baseShape`) |
|-------|----|------|-------------|--------------|----------------------------|
| X     |  1 |  7   | `0b000111`  | 1            | `.#.` / `###` / `.#.`      |
| P     |  2 | 11   | `0b001011`  | 8            | `##` / `##` / `.#`         |
| T     |  3 | 19   | `0b010011`  | 4            | `..#` / `###` / `..#`      |
| F     |  4 | 35   | `0b100011`  | 8            | `.##` / `##.` / `.#.`      |
| Y     |  5 | 13   | `0b001101`  | 8            | `.#` / `.#` / `##` / `.#`  |
| V     |  6 | 21   | `0b010101`  | 4            | `..#` / `..#` / `###`      |
| U     |  7 | 37   | `0b100101`  | 4            | `#.#` / `###`              |
| L     |  8 | 25   | `0b011001`  | 8            | `...#` / `####`            |
| N     |  9 | 41   | `0b101001`  | 8            | `..##` / `###.`            |
| Z     | 10 | 49   | `0b110001`  | 4            | `..#` / `###` / `#..`      |
| W     | 11 | 14   | `0b001110`  | 4            | `..#` / `.##` / `##.`      |
| I     | 12 | 22   | `0b010110`  | 2            | `#` / `#` / `#` / `#` / `#`|

> **Correction (analyse du 27/08/2026).** La colonne « Pièce » de ce tableau était fausse
> sur 7 lignes (ID 2, 4, 5, 6, 7, 10, 11). Les lettres ci-dessus sont reconstruites
> depuis les `baseShape` réels de `pentominos.dart`. Contrôle : la somme des
> orientations vaut 1+8+4+8+8+4+4+8+8+4+4+2 = **63**, nombre canonique de pentominos
> fixes — la table est cohérente. Les colonnes `ID`, `bit6`, `binaire` et
> `Orientations` étaient, elles, correctes et sont inchangées.
>
> ⚠️ La table de l'en-tête de `lib/services/solution_matcher.dart` porte une **troisième**
> version, également fausse, et n'a pas encore été corrigée.

Les codes bit6 vont de 7 à 49. Aucun code n'est 0 (réservé pour "case vide") ni ne dépasse 63 (6 bits max).

### Pourquoi 6 bits et pas 4 ou 5 ?

4 bits suffiraient à représenter 12 valeurs distinctes (1–12). Mais le choix de 6 bits n'est pas arbitraire : il repose sur une propriété algébrique qui rend le test de présence d'une pièce dans une solution **non ambigu par simple ET logique**.

**La propriété clé : tous les codes ont exactement 3 bits à 1 (poids de Hamming constant = 3).**

```
 7  = 0b000111  → 3 bits à 1
11  = 0b001011  → 3 bits à 1
13  = 0b001101  → 3 bits à 1
... (idem pour les 12 codes)
```

Ce poids constant garantit : pour deux codes distincts `P` et `Q`, tous deux de poids 3,
il est **impossible** que `P & Q == P` ou `P & Q == Q`.

> Preuve : `P & Q == Q` signifierait que tous les bits de Q sont contenus dans P. Si P et Q ont tous les deux exactement 3 bits à 1, "Q contenu dans P" implique P = Q. Donc pour P ≠ Q, c'est impossible.

**Ce que ça permet :** pour tester si une pièce (code `P`) est présente dans un champ 6 bits d'une solution (`S`) :

```
S & P == 0   →  case vide, la pièce peut aller là
S & P == P   →  cette pièce exacte est présente (équivaut à S == P)
autre        →  une autre pièce occupe cette case
```

Le test `S & P == P` est **sans faux positif** : il ne peut jamais être vrai si une pièce différente occupe la case, car aucun code valide n'est un sous-ensemble d'un autre.

Avec des codes séquentiels sur 4 bits (poids variable), ce test serait ambigu. Par exemple :
```
pièce 3  = 0b0011
pièce 7  = 0b0111
0b0111 & 0b0011 == 0b0011  ←  faux positif : on "verrait" la pièce 3 là où il y a la pièce 7
```

**Pourquoi 6 bits minimum ?** Le raisonnement se fait en deux temps.

*Si on impose un poids constant de 3*, il faut `C(n, 3) ≥ 12`. Mais cet argument est
incomplet : il présuppose le poids constant. Un lecteur peut objecter qu'un code
**mixte** sur 5 bits (quelques codes de poids 2, quelques-uns de poids 3, en évitant
les inclusions à la main) pourrait suffire.

C'est le **théorème de Sperner** qui ferme cette porte : dans le treillis booléen `B_n`,
*aucune* antichaîne — uniforme ou mixte — ne dépasse `C(n, ⌊n/2⌋) `éléments.

| n bits | `C(n, 3)` | Borne de Sperner `C(n, ⌊n/2⌋)` — **toute** antichaîne | 12 codes possibles ? |
|--------|-----------|--------------------------------------------------------|----------------------|
| 4      | 4         | **6**                                                    | Non                  |
| 5      | 10        | **10**                                                   | Non                  |
| **6**  | **20**    | **20**                                                   | **Oui** (8 codes libres) |

6 bits est donc le minimum **absolu**, pas seulement le minimum à poids constant.
Voir `docs/ANALYSE_STOCKAGE_POSITIONS.md`, annexe « Fondement combinatoire », pour
l'énoncé complet, la preuve (inégalité LYM) et la liste des 8 codes libres.

*Nuance :* le poids constant est une condition **suffisante**, pas nécessaire. Une
famille de poids 4 (15 codes) ou de poids 2 (15 codes) marcherait aussi. Le poids 3
n'est pas obligatoire — c'est simplement la couche la plus large de `B₆` (20 codes),
donc celle qui laisse le plus de marge. Ce qui casse la propriété, c'est de **mélanger**
les poids : `0b001111 & 0b000111 == 0b000111` réintroduit un faux positif.

---

## Les orientations : numéros de cases dans l'ordre des cellules

Le champ `orientations` contient, pour chaque orientation de la pièce, la liste des 5 numéros de cases dans un **ordre stable** (identité des cellules A, B, C, D, E préservée). Cet ordre est utilisé pour le tracking de la mastercase lors des transformations isométriques.

**Exemple — pièce 12 (I, bâtonnet) :**
```dart
numOrientations: 2,
orientations: [
  [1, 6, 11, 16, 21],   // Vertical : colonne gauche, de haut en bas
  [5, 4,  3,  2,  1],   // Horizontal : ligne haute, de droite à gauche
],
```

Orientation 0 (vertical) sur la grille 5×5 :
```
X .  .  .  .
X .  .  .  .
X .  .  .  .
X .  .  .  .
X .  .  .  .
```
Cases 1, 6, 11, 16, 21 = colonne gauche entière (case 1 en haut).

Orientation 1 (horizontal) :
```
X X  X  X  X
. .  .  .  .
. .  .  .  .
. .  .  .  .
. .  .  .  .
```
Cases 5, 4, 3, 2, 1 = **ligne du haut**, parcourue de droite à gauche (l'ordre des cellules est inversé pour la cohérence du tracking).

---

## Les `cartesianCoords` : coordonnées normalisées (x, y)

En parallèle des numéros de cases, chaque orientation est aussi décrite par ses **coordonnées cartésiennes normalisées**. Ces coordonnées sont utilisées pour :
- Calculer les transformations isométriques (rotation, symétrie)
- Placer la pièce sur le plateau de jeu
- Comparer deux formes géométriquement

**Convention d'axes :**
- `x` = colonne (0 = gauche)
- `y` = ligne (0 = haut, croît vers le bas — convention écran)

**Normalisation :** Les coordonnées sont toujours ramenées à l'origine : `min(x) = 0` et `min(y) = 0`.

**Exemple — pièce 12 (I) :**
```dart
cartesianCoords: [
  // Orientation 0 : vertical
  [[0,0], [0,1], [0,2], [0,3], [0,4]],
  // Orientation 1 : horizontal
  [[4,0], [3,0], [2,0], [1,0], [0,0]],
],
```

Orientation 0 : 5 cases dans la colonne 0, lignes 0 à 4 (bâtonnet vertical).
Orientation 1 : 5 cases dans la ligne 0, colonnes 4 à 0 (bâtonnet horizontal, ordre inversé pour garder la cohérence des cellules A→E).

---

## Les transformations isométriques

Les 4 isométries de base s'appliquent sur les `cartesianCoords` :

| Opération | Formule sur (x, y)  | Nom dans le code  |
|-----------|---------------------|-------------------|
| Rotation CW (horaire)        | `(x, y) → (-y, x)`  | `rotationCW`  |
| Rotation TW (anti-horaire)   | `(x, y) → (y, -x)`  | `rotationTW`  |
| Symétrie axe horizontal      | `(x, y) → (x, -y)`  | `symmetryH`   |
| Symétrie axe vertical        | `(x, y) → (-x, y)`  | `symmetryV`   |

> Note : les noms sont en repère écran (y vers le bas). Les formules mathématiques sont donc inversées par rapport au repère cartésien classique.

**Mécanisme de lookup :**
1. Appliquer la formule sur les 5 coordonnées de l'orientation courante
2. Normaliser et trier le résultat
3. Chercher dans `cartesianCoords` l'orientation dont l'ensemble de points correspond
4. Retourner l'index trouvé → nouvel `positionIndex`

Si la pièce est très symétrique (ex : X qui n'a qu'1 orientation), toutes les transformations renvoient l'index 0.

---

## Encodage BigInt des solutions (plateau 6×10)

Le plateau 6×10 contient **60 cases**, indexées de 0 à 59 :
```
index = y * 6 + x     (x : colonne 0–5, y : ligne 0–9)
```

Chaque solution est encodée en un **BigInt de 360 bits** (60 cases × 6 bits/case) :

```
Bits 354–359 : case index 0  (x=0, y=0, haut gauche)
Bits 348–353 : case index 1  (x=1, y=0)
...
Bits   0–5   : case index 59 (x=5, y=9, bas droite)
```

Formule du décalage :
```
shift = (59 - cellIndex) * 6
```

Chaque groupe de 6 bits contient :
- `0b000000` (= 0) : case vide
- Le `bit6` de la pièce qui occupe la case (7, 11, 19, 35, 13, 21, 37, 25, 41, 49, 14, 22)

**Structure d'un `BigIntPlateau` :**

```
pieces  : BigInt 360 bits — codes bit6 des pièces (0 si vide)
mask    : BigInt 360 bits — 0x3F (= 0b111111) par case occupée, 0 si vide
```

---

## Matching : vérifier si un état partiel est compatible avec une solution

Pour savoir si l'état actuel du plateau est compatible avec une solution de la base :

```
(solution & mask) == pieces
```

- `mask` sélectionne uniquement les cases déjà occupées
- On compare les codes bit6 des pièces posées avec ceux de la solution
- Si égaux sur toutes les cases occupées → la solution reste atteignable

Ce test s'effectue en une seule opération binaire sur des BigInt de 360 bits, ce qui permet de parcourir les 9 356 solutions très rapidement.

---

## Résumé : cycle de vie d'une pièce

```
1. Définition (pentominos.dart)
   └── baseShape      : 5 numéros de cases sur grille 5×5
   └── bit6           : code 6 bits unique (pour BigInt)
   └── orientations[] : liste des formes (numéros cases, ordre stable)
   └── cartesianCoords[]: coordonnées (x,y) normalisées par orientation

2. Jeu (placement)
   └── L'utilisateur sélectionne positionIndex (0..numOrientations-1)
   └── cartesianCoords[positionIndex] → positions relatives des 5 cases
   └── gridX, gridY (ancre) + coordonnées relatives → cases absolues sur plateau

3. Transformation isométrique
   └── Appliquer formule sur cartesianCoords[positionIndex]
   └── Normaliser + trier → chercher dans cartesianCoords
   └── Retourner nouvel positionIndex

4. Encodage solution
   └── Pour chaque case absolue occupée : cellIndex = y*6 + x
   └── shift = (59 - cellIndex) * 6
   └── pieces |= (bit6 << shift)
   └── mask   |= (0x3F << shift)
```
