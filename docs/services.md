# SERVICES — Documentation de `lib/services/`

> **Écrit le 2026-08-27 à partir des sources.** Le fichier précédent portant ce nom
> était un doublon octet pour octet de `models.md` (même somme MD5) : la documentation
> des services n'existait pas. Celle-ci la remplace. `models.md` a depuis été supprimé
> — il reste récupérable dans l'historique git.

> **Révisé le 2026-08-30**, après la suppression du mode classique. Trois changements de
> fond : `plateau_solution_counter.dart` a été **supprimé**, `solution_matcher.dart` n'a
> plus de singleton global, et le chargeur est devenu paramétrable par table.

`lib/services/` contient **trois** fichiers, qui forment la chaîne de traitement des
solutions d'un rectangle complet — du fichier binaire jusqu'au compteur affiché à l'écran.

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
        │  pentoscope/solution_source.dart     TableSolutionSource : masques + comptage
        │                                      (vit hors de lib/services/)
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

`pentoscope/pentoscope_solutions_provider.dart` uniquement. Le chargeur prend désormais
le **chemin de l'asset en paramètre** : ses constantes `_boardCells = 60` et
`_bytesPerSolution = 45` ne dépendent pas de la forme du rectangle, seul le nom de fichier
changeait. C'est ce qui rendra les tables 5×12 et 4×15 possibles sans le toucher.

---

## `solution_matcher.dart` — 787 lignes

Cœur du traitement des solutions pré-calculées.

> ⚠️ **Le singleton global `solutionMatcher` a été supprimé** avec le mode classique
> (2026-08-29). La classe est instanciée par table, avec ses dimensions —
> `SolutionMatcher(width: table.width, height: table.height)` — via le
> `FutureProvider.family` `pentoscopeSolutionsProvider`.

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

`pentoscope/solution_source.dart`, `pentoscope/pentoscope_solutions_provider.dart`,
`pentoscope/screens/solutions_browser_screen.dart`.

---

## `plateau_solution_counter.dart` — **SUPPRIMÉ le 2026-08-29**

Cette extension sur `Plateau` construisait les deux masques `(pieces, mask)` et
interrogeait le singleton. Elle est partie avec le mode classique, son seul appelant.

Son remplaçant vit ailleurs : `TableSolutionSource._mask`
(`lib/pentoscope/solution_source.dart`), dimensionné par la table au lieu d'être figé
sur 6×10.

> Deux défauts partent avec elle, à ne pas réintroduire : un `try/catch` qui convertissait
> toute erreur en `null` après un `print` — un compteur absent à l'écran ne voulait donc
> pas dire « 0 solution » mais « quelque chose a échoué en silence » — et un refus
> explicite de tout format autre que 6×10.

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
cause **est élucidée depuis le 2026-08-29** : `maxSeconds` vaut 30, c'est un champ
`final` non paramétrable (l.23), et `findAllSolutions` fait un simple `return` à
l'expiration (l.470-475) après un `print`. L'appelant reçoit une liste **indistinguable**
d'une liste complète. Ce n'est donc pas un défaut de complétude du solveur.

Le fichier livré, lui, est bon : les 8175 brutes couvraient les **2339/2339** classes.

⚠️ **Avant toute génération de nouvelle table**, rendre `maxSeconds` paramétrable **et** la
troncature observable (signature `({solutions, truncated})`) — sinon les tables 5×12 et
4×15 seront tronquées de la même façon, en silence.
→ `docs/PLAN_6X10_DANS_PENTOSCOPE.md` §5.1.

---

## Ce qui n'est pas dans `lib/services/`

Deux composants qu'on s'attendrait à y trouver et qui vivent ailleurs :

- `common/bigint_plateau.dart` — représentation (pieces, mask) d'un plateau ; orpheline,
  et la mieux écrite des trois implémentations de ce couple
- `pentoscope/pentoscope_solver.dart` — le solveur réellement utilisé par le jeu
- `pentoscope/solution_source.dart` — l'interface qui choisit entre table et solveur

## Voir aussi

- `docs/ANALYSE_STOCKAGE_POSITIONS.md` — analyse détaillée de l'encodage, défauts,
  vérifications exécutées, fondement combinatoire du code `bit6`
- `docs/PIECES_ENCODING.md` — définition des pièces et des isométries
- `docs/FONCTIONNEMENT.md` — documentation fonctionnelle de l'application (absorbe
  l'ancien `PENTOSCOPE.md` depuis le 2026-08-31)
