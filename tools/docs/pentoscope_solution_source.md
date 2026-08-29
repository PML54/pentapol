# pentoscope/solution_source.dart

**Module:** pentoscope

## Fonctions

### hasSolutionFrom

Origine des réponses « solution » d'un puzzle. Un seul site le lit : `startPuzzle`.
Une solution reste-t-elle atteignable depuis ce plateau ?


```dart
bool hasSolutionFrom(Plateau plateau, List<Pento> remaining);
```

### compatibleSolutions

Combien de solutions complètes restent compatibles.
`null` quand la source ne sait pas compter — c'est le cas du solveur à la volée.
Une solution compatible (ses placements), pour l'indice. `null` s'il n'y en a plus.

[remaining] sert au solveur ; la table l'ignore (elle renvoie la solution complète,
à l'appelant de choisir une pièce non encore posée).
Les solutions complètes compatibles avec ce plateau, en BigInt (pour le
navigateur de solutions). Liste vide pour la source à la volée, qui ne les
énumère pas.


```dart
List<BigInt> compatibleSolutions(Plateau plateau);
```

### hasSolutionFrom

Grille `[y][x]` attendue par le solveur, construite depuis un plateau.
Source à la volée, au-dessus de [PentoscopeSolver]. Ne sait pas compter.


```dart
bool hasSolutionFrom(Plateau plateau, List<Pento> remaining) {
```

### compatibleSolutions

```dart
List<BigInt> compatibleSolutions(Plateau plateau) => const [];
```

### hasSolutionFrom

Source adossée à une table pré-calculée (rectangle complet), au-dessus d'un
[SolutionMatcher] **déjà chargé**. Sait compter ; sa disponibilité = compte > 0.
`(piecesBits, maskBits)` du plateau, dans le même ordre de cases que le `.bin`
(cellIndex = y·width + x, bits de poids fort en premier).


```dart
bool hasSolutionFrom(Plateau plateau, List<Pento> remaining) {
```

### compatibleSolutions

```dart
List<BigInt> compatibleSolutions(Plateau plateau) {
```

