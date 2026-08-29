# pentoscope/pentoscope_generator.dart

**Module:** pentoscope

## Fonctions

### generate

Générateur de puzzles Pentoscope (lazy, sans table pré-calculée)
Court-circuit pour le rectangle complet 6×10 : tirage forcé des 12 pièces,
compte connu (9356), solutions laissées **vides** — elles seront branchées
au temps 2. Évite le chemin normal du générateur, qui sur 12 pièces donne un
tirage forcé, un compte partiel silencieux à l'expiration du timeout, et une
boucle infinie côté generateEasy (voir PLAN_6X10_DANS_PENTOSCOPE.md §3.1).
Génère un puzzle aléatoire pour une taille donnée
Boucle jusqu'à trouver une combinaison valide (avec 1+ solution)


```dart
Future<PentoscopePuzzle> generate(PentoscopeSize size) async {
```

### PentoscopePuzzle

```dart
return PentoscopePuzzle( size: size, pieceIds: pieceIds, solutionCount: result.solutionCount, solutions: result.solutions, );
```

### generateEasy

Génère un puzzle en favorisant ceux avec plus de solutions (faciles)
Boucle jusqu'à solutionCount >= threshold


```dart
Future<PentoscopePuzzle> generateEasy(PentoscopeSize size) async {
```

### PentoscopePuzzle

```dart
return PentoscopePuzzle( size: size, pieceIds: pieceIds, solutionCount: result.solutionCount, solutions: result.solutions, );
```

### generateHard

Génère un puzzle en favorisant ceux avec peu de solutions (durs)
Boucle jusqu'à solutionCount <= threshold


```dart
Future<PentoscopePuzzle> generateHard(PentoscopeSize size) async {
```

### PentoscopePuzzle

```dart
return PentoscopePuzzle( size: size, pieceIds: pieceIds, solutionCount: result.solutionCount, solutions: result.solutions, );
```

### generateFromSeed

Sélectionne N pièces aléatoires parmi les 12 disponibles
🎮 Génère un puzzle avec un seed et des pièces spécifiques (mode multiplayer)
Ne vérifie pas les solutions - on fait confiance aux paramètres fournis


```dart
Future<PentoscopePuzzle> generateFromSeed( PentoscopeSize size, int seed, List<int> pieceIds, ) async {
```

### PentoscopePuzzle

```dart
return PentoscopePuzzle( size: size, pieceIds: pieceIds, solutionCount: result.solutionCount, solutions: result.solutions, );
```

### PentoscopePuzzle

Configuration d'un puzzle Pentoscope
Noms des pièces (X, P, T, F, Y, V, U, L, N, W, Z, I)


```dart
const PentoscopePuzzle({
```

### toString

Description lisible
Retourne les noms des pièces du puzzle


```dart
String toString() => 'PentoscopePuzzle($description)';
```

### SolutionTable

Table de solutions pré-calculées d'un rectangle complet de pentominos.

Une seule valeur au temps 1 (le 6×10, seule table déjà générée). Les autres
rectangles complets (5×12, 4×15, 3×20) s'ajouteront avec leurs tables — voir
PLAN_6X10_DANS_PENTOSCOPE.md §5.


```dart
const SolutionTable(this.asset, this.width, this.height, this.canonicalCount);
```

### PentoscopeSize

Solutions à symétrie près, telles que stockées dans le .bin.
Après expansion identité / rot180 / miroirH / miroirV. Valide tant qu'aucune
solution n'est invariante par l'une des trois — vérifié à la génération.
Tailles de plateau disponibles (TRANSPOSÉES pour portrait)
Table de solutions pré-calculées, ou null si le puzzle est résolu à la volée.

N'est valide que si la configuration emploie **toutes** les pièces de la table
et qu'**aucune case n'est masquée** — voir PLAN_6X10_DANS_PENTOSCOPE.md §2.


```dart
const PentoscopeSize( this.dataIndex, this.width, this.height, this.numPieces, this.label, this.table, );
```

### PentoscopeStats

Statistiques (optionnel - pas vraiment utilisé en lazy mode)


```dart
const PentoscopeStats({
```

### toString

```dart
String toString() => '$description';
```

