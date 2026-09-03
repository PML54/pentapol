# Référence — isométries : coût, minimum, et chiralité des tirages

> Établi le 2026-09-03 par calcul direct sur `lib/common/pentominos.dart` et
> `lib/pentoscope/home/home_tirages_data.dart`. Pendant de `REFERENCE_TIRAGES.md`, pour tout
> ce qui touche aux **orientations** plutôt qu'aux tirages.
>
> **Rejouable** : `python3 tools/verif_isometries.py`. Aucun nombre de ce fichier n'est une
> estimation ; tous sortent de ce script.

---

## 1. Vocabulaire

Une **isométrie** est une transformation qui conserve les distances. Le groupe des isométries
du plan contient les translations, les rotations et les réflexions. Dans Pentapol, « isométrie »
désigne par convention interne les seuls éléments du **groupe diédral D₄** — les quatre
rotations et les quatre réflexions qui fixent le centre de la pièce ; les translations sont
comptées à part dans `translationCount`. Écrire « isométries hors translations » lorsqu'il faut
lever l'ambiguïté ; ne jamais écrire « isométries hors transformations », qui n'a pas de sens.

---

## 2. Le groupe engendré par les quatre boutons

La barre d'isométries offre quatre actions, et c'est **elles** qui définissent le coût, pas le
groupe abstrait : `applyIsometryRotationCW`, `applyIsometryRotationTW`, `applyIsometrySymmetryH`,
`applyIsometrySymmetryV`.

Distance = plus court chemin dans le graphe de Cayley de D₄ engendré par ces quatre générateurs.

**Diamètre : 2.** Toute orientation d'une pièce est atteignable en **au plus deux appuis**, quelle
que soit la pièce et quelle que soit l'orientation de départ.

### Coût moyen d'une pièce prise seule
Orientation de départ uniforme, orientation cible imposée :

| Pièce | Orientations | Coût moyen | Coût max |
|---|---|---|---|
| X | 1 | 0,00 | 0 |
| I | 2 | 0,50 | 1 |
| T, U | 4 | 0,75 | 1 |
| V, W, Z | 4 | 1,00 | 2 |
| P, F, Y, L, N | 8 | 1,25 | 2 |

Somme des coûts moyens sur les douze pièces : **11,25** — c'est l'ordre de grandeur du 6×10
*avant* tout choix de solution.

### Les quatre boutons sont redondants en algèbre, pas en ergonomie

Deux générateurs suffisent à engendrer D₄ — une rotation et une symétrie. Les deux rotations
seules n'atteignent que les quatre rotations (sous-groupe cyclique C₄) ; les deux symétries
seules n'engendrent que le groupe de Klein d'ordre 4. Mesuré sur la pièce P :

| Boutons | Diamètre | Coût moyen |
|---|---|---|
| r₊ r₋ sH sV (les quatre actuels) | **2** | **1,25** |
| r₊ r₋ sH | 3 | 1,50 |
| r₊ sH sV | 3 | 1,50 |
| r₊ sH (minimum algébrique) | 3 | 1,75 |
| r₊ r₋ | — | n'atteint pas les réflexions |
| sH sV | — | n'atteint pas les rotations d'ordre 4 |

Toutes pièces confondues, les quatre boutons donnent un coût moyen de **0,94** contre 1,06 dès
qu'on en retire un. Chaque bouton paie donc sa place à l'écran : le quatrième n'ajoute aucune
transformation nouvelle, il raccourcit les chemins.

### La primitive existe déjà dans le dépôt

`Pento.minIsometriesToReach(startPos, endPos)` (`lib/common/pentominos.dart` l. 795) fait
exactement ce BFS, sur ces quatre mêmes générateurs. Elle est **orpheline depuis le
2026-08-30** (PLAN_BILAN §3, son appelant était le score de fin de partie retiré) et conservée
à dessein. Ce n'est donc pas la distance qu'il faut écrire, seulement l'agrégation : somme sur
les pièces, minimum sur les solutions.

**Contrôle croisé recommandé** (côté CLI) : un test-oracle sur `minIsometriesToReach`, même
forme que `test/pentomino_letters_test.dart` — l'oracle doit être **indépendant du code testé
et exécutable par `flutter test`**, donc écrit en Dart dans le fichier de test, pas emprunté au
script Python.

Oracle proposé : force brute sur les mots de longueur 0 à 3 des quatre boutons (le diamètre
étant 2, la longueur 3 couvre tout avec une marge). Pour chaque mot, appliquer les
transformations successivement à l'orientation de départ et retenir la longueur du plus court
mot qui atteint la cible. Quinze lignes, justes à la lecture, sans une ligne commune avec le
BFS. Comparer sur les 12 pièces et toutes les paires d'orientations : 12 × 8 × 8 = 768 cas au
plus. `tools/verif_isometries.py` reste un troisième avis, pas le juge.


---

## 3. Ce que compte `isometryCount` — vérifié dans le code

`_applyIsoUsingLookup` sort sur `if (!didChange)` **avant** d'incrémenter : un appui sans effet
(n'importe quel bouton sur le X, une symétrie sur le I) n'est pas compté. Les chemins
`TransformationResult.impossible` du cas « pièce posée » sortent eux aussi avant l'incrémentation.

**`isometryCount` compte donc les changements d'orientation effectifs** — exactement l'unité de
la distance du §2. Les deux sont directement comparables, sans conversion.

---

## 4. `minIso` et l'acuité isométrique — décision de Paul, 2026-09-03

### Définition retenue

`minIso` se calcule sur **le placement que le joueur a réellement complété**, pas sur
l'ensemble des solutions du puzzle :

```
minIso = Σ  d( orientation initiale de p dans le rack , orientation de p dans le placement posé )
        p ∈ pièces
```

**Raison de ce choix** (Paul) : l'objectif n°1 est de terminer le puzzle ; le score mesure
ensuite le **tâtonnement** du joueur sur le chemin qu'il a pris. On ne lui reproche pas de ne
pas avoir découvert un agencement moins coûteux qu'il ne pouvait pas voir — sur le 6×10,
comparer le coût de 9 356 solutions est hors de portée humaine.

C'est un minimum **exact et atteignable** : on peut toujours orienter une pièce dans le tiroir
avant de la poser, donc aucune contrainte de plateau n'impose une isométrie supplémentaire.

### Acuité isométrique

```
acuité = (minIso + 1) / (isometryCount + 1)
```

Le `+ 1` traite le seul cas dégénéré : `minIso` vaut 0 quand le rack tombe déjà orienté pour le
placement posé, et la forme brute `minIso / isometryCount` donnerait alors 0 % pour un geste de
trop comme pour cinquante, et `0/0` pour une partie sans aucune isométrie. Avec le `+ 1`, une
partie parfaite vaut 100 % dans tous les cas et les valeurs non dégénérées sont conservées
(10 pour 20 → 52 % au lieu de 50 %).

**L'acuité est la clé de tri** du classement, deuxième critère après les aides.

### Prérequis : rack identique pour tous

Le classement n'a de sens que si tous les joueurs d'un même défi partent des **mêmes
orientations initiales**. `startPuzzleFromSeed` le fait déjà (`Random(seed)`).
Réserve : Dart ne garantit pas formellement la stabilité de `Random(seed)` d'une version du SDK
à l'autre — pour un classement qui doit survivre à une montée de Flutter, tirer les orientations
avec un PRNG écrit dans le dépôt.

### Effet accepté, consigné pour qu'il ne surprenne personne

Le dénominateur dépend du placement posé, alors que le rack est commun. Deux joueurs d'un même
défi peuvent donc être classés dans l'ordre **inverse** de leur nombre de manipulations.
Exemple réel (configuration PVL, rack P=2 V=3 L=5, §5) :

| | Placement posé | `minIso` | Isométries faites | Acuité | Rang |
|---|---|---|---|---|---|
| Joueur A | 3 | 0 | **1** | 50 % | 2ᵉ |
| Joueur B | 1 | 6 | **6** | 100 % | 1ᵉʳ |

B a manipulé six fois, A une seule — et B passe devant. C'est cohérent avec ce que l'acuité
mesure (l'absence de gaspillage sur le chemin choisi) et non avec l'économie de gestes.
**Arbitrage de Paul, pris en connaissance de cet effet.** Ne pas le « corriger » sans lui.

### Implémentation — le corpus n'intervient pas

Une fois le plateau complété, on tient la grille finale. On y lit l'orientation de chaque pièce,
on somme les `Pento.minIsometriesToReach(orientation du rack, orientation posée)`, et c'est
tout. Aucune table de solutions n'est consultée, aucun minimum sur les placements alternatifs
n'est calculé. Coût : douze appels au plus, sur un BFS de huit nœuds.

### Deux réserves qui demeurent

1. **`minIso` dépend des quatre générateurs, pas du groupe.** Ajouter un bouton « demi-tour »
   change toutes les distances et rend les anciens records incomparables. Les générateurs
   doivent être figés avant la première publication d'un score, et versionnés si on y touche.
2. **`minIso` ne mesure pas la difficulté**, seulement la distance orientationnelle. Un puzzle
   à `minIso = 0` peut être coriace à agencer ; un `minIso = 6` peut être évident. Ne pas s'en
   servir pour ordonner les niveaux.

---

## 5. Mesures — niveau 1 (3×5, 3 pièces)

⚠️ Ce que mesure cette section est le **minimum absolu** — le plus petit coût sur *toutes* les
solutions du puzzle. Depuis la décision du 2026-09-03 (§4), ce n'est **pas** `minIso`, qui se
calcule sur le seul placement posé par le joueur. Le minimum absolu en est la **borne
inférieure** : `minIso ≥ minimum absolu`, avec égalité quand le joueur pose le placement le
moins coûteux. Ces chiffres restent l'ordre de grandeur de référence, et c'est à eux que se
comparent les seuils d'un objectif ou d'une médaille.

Sur les 7 configurations et **toutes** les orientations de départ possibles (1 664 cas) :

| Configuration | min | médiane | max | distribution |
|---|---|---|---|---|
| PFU, PUN, PYU, TYL | 0 | 2 | 4 | 0:4 1:40 2:124 3:72 4:16 |
| PVL, VLN | 0 | 2 | 3 | 0:4 1:40 2:132 3:80 |
| PVU | 0 | 2 | 3 | 0:4 1:32 2:68 3:24 |

**Tous tirages confondus : médiane 2, moyenne 2,16, maximum 4.**

Deux conséquences pour la conception d'un score ou d'une médaille :

- un **seuil absolu** du type « moins de 8 transformations » est franchi sans effort ici et
  n'a aucun rapport avec le 6×10 (§2, somme 11,25). Un objectif chiffré en valeur brute n'a pas
  de sens d'une taille à l'autre : le score est **relatif**, c'est l'acuité du §4 ;
- le minimum vaut **0 dans 28 cas sur 1 664** (1,7 %) : les pièces tombent parfois déjà bien
  orientées. Une médaille « zéro transformation » récompenserait le tirage, pas le joueur — la
  médaille se décerne sur l'**acuité à 100 %**, jamais sur un nombre brut d'isométries. C'est
  aussi ce cas qui impose le `+ 1` de la formule (§4).

---

## 6. Chiralité — la première ouverture

Six pentominos sont **chiraux** (F, L, N, P, Y, Z) : leur image miroir ne s'obtient par aucune
rotation. Les six autres (I, T, U, V, W, X) sont achiraux.

`startPuzzle` tire l'orientation de départ de chaque pièce **uniformément parmi toutes ses
orientations, réflexions comprises** (`random.nextInt(piece.numOrientations)`). Sur un plateau
3×5 dont la solution est unique à symétrie près, une pièce chirale servie du mauvais côté ne se
rattrape par aucune rotation.

Mesuré sur les 7 configurations du 3×5, masque tiré uniformément (`drawMask`) :

| Configuration | pièces chirales | cas insolubles sans miroir |
|---|---|---|
| PFU, PUN, PVL, PYU, TYL, VLN | 2 | **50 %** (128 / 256) |
| PVU | 1 | 0 % |

**Probabilité qu'une première partie soit insoluble sans le bouton miroir : 3/7 = 42,9 %.**

Et dans **100 % de ces cas bloqués, deux pièces sur trois se posent quand même** : le joueur
progresse, puis se retrouve devant une dernière pièce qui ne rentre nulle part, sans rien pour
lui dire pourquoi.

Aggravant, vérifié : `cycleToNextOrientation()` **n'a aucun appelant** dans `lib/` — c'est du
code mort. La barre d'isométries est le seul chemin existant vers une réflexion. Et cette barre
**remplace** la barre d'actions dans l'`AppBar`, seulement quand une pièce est sélectionnée
(`pentoscope_game_screen.dart` l. 252) : à l'ouverture, aucune icône de transformation n'est
visible.

---

## 7. Contrôle croisé obtenu au passage

Le script réénumère les pavages de chaque configuration du 3×5 sans lire aucune table : les
7 configurations ont **exactement 4 solutions chacune**, ce qui confirme indépendamment le
contrôle d'acceptation du `PLAN_ECRAN_ACCUEIL` §3 et la ligne n = 3 de `REFERENCE_TIRAGES.md` §2.
