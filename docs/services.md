# SERVICES — Documentation de `lib/services/`

> **Écrit le 2026-08-27 à partir des sources.** Le fichier précédent portant ce nom
> était un doublon octet pour octet de `models.md` (même somme MD5) : la documentation
> des services n'existait pas. Celle-ci la remplace. `models.md` a depuis été supprimé
> — il reste récupérable dans l'historique git.

`lib/services/` contient quatre fichiers, qui forment la chaîne de traitement des
solutions du plateau 6×10 — du fichier binaire jusqu'au compteur affiché à l'écran.

```
assets/data/solutions_6x10_normalisees.bin
        │
        │  pentapol_solutions_loader.dart      dépaquetage 6 bits → List<BigInt>
        ▼
      2339 solutions canoniques
        │
        │  solution_matcher.dart               expansion ×4 → 9356, matching, décodage
        ▼
      9356 solutions en mémoire
        ▲
        │  plateau_solution_counter.dart       extension sur Plateau : masques + comptage
        │
   état du plateau de jeu

   pentomino_solver.dart                       backtracking — INACTIF dans l'app
```

---

## `pentapol_solutions_loader.dart` — 66 lignes

Chargement et dépaquetage du fichier binaire des solutions canoniques.

### API publique

```dart
Future<List<BigInt>> loadNormalizedSolutionsAsBigInt()
```

Charge `assets/data/solutions_6x10_normalisees.bin` et retourne les **2339** solutions
canoniques sous forme de `BigInt` de 360 bits.

### Format lu

- 45 octets par solution (60 cases × 6 bits = 360 bits, multiple exact de 8)
- bits lus du **poids fort au poids faible**, case 0 en tête
- la taille du fichier doit être un multiple de 45, sinon `StateError`

### Importé par

`providers/solutions_provider.dart` uniquement.

---

## `solution_matcher.dart` — 787 lignes

Cœur du mode classique. Expose un **singleton global** `solutionMatcher`.

### `SolutionMatcher`

| Membre | Rôle |
|---|---|
| `initWithBigIntSolutions(List<BigInt>)` | reçoit les 2339 canoniques, génère les 4 variantes de chacune → 9356. Idempotent : un second appel est ignoré. |
| `totalSolutions` | 9356 une fois initialisé, 0 sinon |
| `allSolutions` | liste immuable des 9356 `BigInt` |
| `countCompatibleFromBigInts(pieces, mask)` | nombre de solutions compatibles |
| `getCompatibleSolutionsFromBigInts(pieces, mask)` | les `BigInt` compatibles |
| `getCompatibleSolutionIndices(pieces, mask)` | leurs indices (0–9355) |
| `findSolutionIndex(BigInt)` | indice d'une solution complète exacte, −1 sinon |
| `getSolutionByIndex(int)` | une solution par son indice, `null` hors bornes |
| `solutionToPlacedPieces(BigInt)` | reconstruit les 12 `PlacedPiece` |
| `getPlacedPiecesByIndex(int)` | raccourci des deux précédentes |

### Le test de compatibilité

```dart
(solution & maskBits) == piecesBits
```

Une seule opération sur 360 bits remplace 60 comparaisons de cases. `mask` porte
`0x3F` sur chaque case occupée, ce qui efface de la solution tout ce que le joueur n'a
pas encore posé — c'est ce qui rend le test valable sur un plateau partiel.

Le balayage est **linéaire sur les 9356**, sans index ni sortie anticipée.

### Les 4 variantes et la numérotation

```
index = canonicalIndex × 4 + variantType

variantType  0 : identité      2 : miroir horizontal
             1 : rotation 180° 3 : miroir vertical
```

`SolutionInfo(index)` expose `canonicalIndex` (= `index ~/ 4`), `variantType`
(= `index % 4`) et `variantName` en français.

L'expansion ×4 est exacte : **aucune** solution du 6×10 n'est symétrique, donc
2339 × 4 = 9356 sans collision (vérifié par exécution).

### Reconstruction `BigInt` → `PlacedPiece`

Décodage en 60 codes, regroupement par `bit6` (donc par pièce), puis pour chaque
groupe : coin haut-gauche du rectangle englobant → `gridX, gridY`, et comparaison des
cases normalisées aux `cartesianCoords` → `positionIndex`.

> Défaut connu : si aucune orientation ne correspond, `positionIndex` retombe
> silencieusement sur 0 — la pièce est reconstruite avec une **forme différente** de
> celle de la solution, sans erreur.

### Importé par

5 fichiers : les providers classique et Pentoscope MP, `plateau_solution_counter`,
`solutions_browser_screen`, `action_slider`.

---

## `plateau_solution_counter.dart` — 135 lignes

Extension sur `Plateau` qui fait le pont entre l'état de jeu et le matcher.

```dart
extension PlateauSolutionCounter on Plateau {
  int?       countPossibleSolutions()
  List<BigInt> getCompatibleSolutionsBigInt()
  List<int>  getCompatibleSolutionIndices()
  int        findExactSolutionIndex()
}
```

Chaque méthode reconstruit les deux masques `BigInt` depuis la grille, puis délègue au
singleton `solutionMatcher`.

### Contrat de retour

Toutes les erreurs sont **attrapées et converties** : `null` ou liste vide pour les
trois premières, `−1` pour la dernière. Aucune exception ne remonte à l'appelant.
C'est commode mais silencieux : un échec ressemble à un plateau sans solution.

### Deux limites à connaître

- **Plateau 6×10 uniquement.** Toute autre dimension lève un `StateError`, aussitôt
  attrapé → `null`.
- **Cases masquées non gérées.** `Plateau.getCell` peut renvoyer `-1` ; la méthode ne
  traite que `0` et `1..12`, et un `-1` produit un `StateError` attrapé → `null`.
  Latent tant que le mode classique n'utilise que `Plateau.allVisible`.

### Duplication à résorber

La classe privée `_PlateauBigIntMask` réimplémente, en moins complet, ce que fait déjà
`common/bigint_plateau.dart` — lequel est orphelin. La bonne abstraction existe et
n'est pas utilisée.

### Importé par

`classical/pentomino_game_provider.dart` et `screens/.../action_slider.dart`.

---

## `pentomino_solver.dart` — 840 lignes — ⚠ inactif dans l'application

Solveur par backtracking pour un plateau et un jeu de pièces quelconques.

### Statut

Son seul importateur dans `lib/` est `utils/solution_collector.dart`, **lui-même
orphelin**. Le solveur n'est donc atteint par aucun chemin d'exécution de l'app. Il
n'est utilisé que par l'outil hors-ligne `tools/generate_6x10_solutions.dart`.

À ne pas confondre avec `pentoscope/pentoscope_solver.dart`, classe **distincte et
bien vivante**, qui génère les puzzles Pentoscope.

### API

```dart
List<PlacementInfo>? findSolution(Plateau, List<Pento>)   // fonction libre
bool                 hasSolution(Plateau, List<Pento>)    // fonction libre

class PentominoSolver {
  PentominoSolver({required plateau, required pieces});
  factory PentominoSolver.fromIds({...});

  bool  backtrack();
  bool  areIsolatedRegionsValid();
  bool  canAnyAvailablePieceFitRegion(List<Point> region);
  int   findSmallestFreeCell();
  List<PlacementInfo>? findNext();
  Future<int>                      countAllSolutions({...});
  Future<List<List<PlacementInfo>>> findAllSolutions({...});
}

class PlacementInfo { pieceIndex, occupiedCells, ... }
```

### Réserve importante

Le fichier `tools/solutions_6x10_brutes.bin`, produit par cet outil, ne contenait que
**8175 des 9356** solutions — un sous-ensemble strict, sans solution étrangère. La
cause n'est pas élucidée : run interrompu, ou défaut de complétude de
`findAllSolutions`. **Vérifier que le solveur en trouve bien 9356 avant toute
régénération des solutions.**

---

## Ce qui n'est pas dans `lib/services/`

Deux composants qu'on s'attendrait à y trouver et qui vivent ailleurs :

- `common/bigint_plateau.dart` — représentation (pieces, mask) d'un plateau
- `pentoscope/pentoscope_solver.dart` — le solveur réellement utilisé par le jeu

## Voir aussi

- `docs/ANALYSE_STOCKAGE_POSITIONS.md` — analyse détaillée de l'encodage, défauts,
  vérifications exécutées, fondement combinatoire du code `bit6`
- `docs/PIECES_ENCODING.md` — définition des pièces et des isométries
- `docs/FONCTIONNEMENT.md` — documentation fonctionnelle de l'application
