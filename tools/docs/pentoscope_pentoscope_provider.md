# pentoscope/pentoscope_provider.dart

**Module:** pentoscope

## Fonctions

### stateWithDragging

```dart
PentoscopeState stateWithDragging(bool isDragging) => state.copyWith(isDragging: isDragging);
```

### stateWithPreviewCleared

```dart
PentoscopeState stateWithPreviewCleared() => state.copyWith(clearPreview: true);
```

### stateWithElapsedSeconds

```dart
PentoscopeState stateWithElapsedSeconds(int elapsedSeconds) => state.copyWith(elapsedSeconds: elapsedSeconds);
```

### canPlacePiece

D'où viennent les réponses « solution » du puzzle courant. Posé à chaque
création de puzzle par _makeSolutionSource (seul site lisant size.table).
Défaut : solveur à la volée, tant qu'aucun puzzle n'est démarré.


```dart
bool canPlacePiece(Pento piece, int positionIndex, int gridX, int gridY) {
```

### applyIsometryRotationCW

```dart
TransformationResult applyIsometryRotationCW() {
```

### applyIsometryRotationTW

```dart
TransformationResult applyIsometryRotationTW() {
```

### applyIsometrySymmetryH

```dart
TransformationResult applyIsometrySymmetryH() {
```

### applyIsometrySymmetryV

```dart
TransformationResult applyIsometrySymmetryV() {
```

### build

```dart
PentoscopeState build() {
```

### TableSolutionSource

Choisit la source de solutions du puzzle : table pré-calculée si la taille
en porte une (chargée paresseusement, instance propre à Pentoscope), sinon
le solveur à la volée. **Seul site lisant `size.table`** (§4.2).


```dart
return TableSolutionSource(matcher, table);
```

### compatibleSolutions

Solutions complètes compatibles avec le plateau courant (pour le navigateur
de solutions). Le plateau reconstruit inclut la pièce sélectionnée (elle n'a
jamais quitté placedPieces sous stay + mask), donc pas d'`exclude:`. Vide pour
les tailles à la volée.


```dart
List<BigInt> compatibleSolutions() => _solutions.compatibleSolutions(_rebuildPlateau());
```

### calculateNote

Calcule la note de "non-triche" (0-20)
- 0 hints → 20/20
- ≥ nbPieces - 1 hints → 0/20
- Entre les deux → linéaire


```dart
int calculateNote() {
```

### applyHint

Applique un indice en plaçant une pièce du slider selon une solution possible


```dart
void applyHint() {
```

### cancelSelection

`(hasPossibleSolution, solutionsCount)` pour un plateau donné par ses pièces.

Temps 2 : un seul rebuild + un seul passage par la source du puzzle courant.
La table sait compter (count non-null, `has` = count > 0) — le compteur peut
donc passer au rouge, contrairement au court-circuit du temps 1 ; le solveur
à la volée ne compte pas (count null, `has` via canSolveFrom).


```dart
void cancelSelection() {
```

### cycleToNextOrientation

```dart
void cycleToNextOrientation() {
```

### removePlacedPiece

```dart
void removePlacedPiece(PlacedPiece placed) {
```

### reset

```dart
Future<void> reset() async {
```

### selectPiece

```dart
void selectPiece(Pento piece) {
```

### selectPlacedPiece

```dart
void selectPlacedPiece( PlacedPiece placed, int absoluteX, int absoluteY, ) {
```

### Point

```dart
return Point(x, y);
```

### setViewOrientation

À appeler depuis l'UI (board) quand l'orientation change.
Ne change aucune coordonnée: uniquement l'interprétation des actions
(ex: Sym H/V) en mode paysage.


```dart
void setViewOrientation(bool isLandscape) {
```

### startPuzzle

```dart
Future<void> startPuzzle( PentoscopeSize size, {
```

### startPuzzleFromSeed

🎮 Démarre un puzzle avec un seed et des pièces spécifiques (mode multiplayer)


```dart
Future<void> startPuzzleFromSeed( PentoscopeSize size, int seed, List<int> pieceIds, ) async {
```

### changeBoardSize

🔄 Change la taille du plateau (redémarre avec un nouveau puzzle)


```dart
Future<void> changeBoardSize(PentoscopeSize newSize) async {
```

### startPuzzle

```dart
await startPuzzle( newSize, difficulty: PentoscopeDifficulty.random, showSolution: false, );
```

### tryPlacePiece

💾 Sauvegarder le niveau terminé
Méthode publique pour obtenir les coordonnées brutes de la mastercase
Utile pour le widget board qui doit reconstruire les coordonnées de drag

Note: Cette méthode publique est différente de celle du mixin (qui prend des paramètres)


```dart
bool tryPlacePiece(int gridX, int gridY) {
```

### updatePreview

```dart
void updatePreview(int gridX, int gridY) {
```

### Point

```dart
return Point(x, y);
```

### Point

```dart
return Point(x, y);
```

### Point

```dart
return Point(x, y);
```

### Point

```dart
return Point(x, y);
```

### Point

```dart
return Point(x, y);
```

### Point

Calcule la position gridX,gridY pour maintenir la mastercase fixe lors d'une transformation


```dart
return Point(x, y);
```

### Point

```dart
return Point(originalPiece.gridX, originalPiece.gridY);
```

### Point

```dart
return Point(x, y);
```

### Point

```dart
return Point(newGridX, newGridY);
```

### calculateDefaultCell

Helper: calcule la mastercase par défaut (première cellule normalisée)

✅ Utilise maintenant la méthode du mixin


```dart
return calculateDefaultCell(piece, positionIndex);
```

### Point

Annule le mode "pièce placée en main" (sélection sur plateau) en
reconstruisant le plateau complet à partir des pièces placées.
À appeler avant de sélectionner une pièce du slider.
Calcule l'ancre voulue à partir du drag (doigt) en respectant
l'origine de translation (mastercase sélectionnée).
- Si pièce placée: vecteur = (doigt - masterAbs), ancre = originGrid + vecteur
- Sinon: ancre = doigt - mastercase normalisée


```dart
return Point(sp.gridX + dx, sp.gridY + dy);
```

### Point

```dart
return Point( dragGridX - state.selectedCellInPiece!.x, dragGridY - state.selectedCellInPiece!.y, );
```

### Point

```dart
return Point(dragGridX, dragGridY);
```

### Point

Cherche la position valide la plus proche autour de la mastercase
Retourne null si aucune position valide n'est trouvée dans un rayon raisonnable


```dart
return Point(x, y);
```

### remapSelectedCell

Trouve la position valide la plus proche du vecteur de translation
dragGridX/Y = position du doigt sur le plateau
Retourne la position d'ancre valide la plus proche du vecteur

✅ FIX: On cherche l'ancre la plus proche de l'ancre désirée
(calculée via le vecteur mastercase -> doigt)
Génère TOUS les placements possibles pour une pièce à une positionIndex donnée
Retourne une liste de Point (gridX, gridY) où la pièce peut être placée
Remapping de la cellule de référence lors d'une isométrie

✅ Utilise maintenant la méthode du mixin (même implémentation)


```dart
return remapSelectedCell( piece: piece, oldIndex: oldIndex, newIndex: newIndex, oldCell: oldCell, );
```

### PentoscopeState

État du jeu Pentoscope
Orientation "vue" (repère écran). Ne change pas la logique.
Sert à interpréter des actions (ex: Sym H/V) en paysage.


```dart
const PentoscopeState({
```

### PentoscopeState

```dart
return PentoscopeState( plateau: Plateau.allVisible(5, 5), showSolution: false, // ✅ NOUVEAU currentSolution: null, // ✅ NOUVEAU );
```

### canPlacePiece

```dart
bool canPlacePiece(Pento piece, int positionIndex, int gridX, int gridY) {
```

### copyWith

```dart
PentoscopeState copyWith({
```

### PentoscopeState

```dart
return PentoscopeState( viewOrientation: viewOrientation ?? this.viewOrientation, puzzle: puzzle ?? this.puzzle, plateau: plateau ?? this.plateau, availablePieces: availablePieces ?? this.availablePieces, placedPieces: placedPieces ?? this.placedPieces, selectedPiece: clearSelectedPiece ? null : (selectedPiece ?? this.selectedPiece), selectedPositionIndex: selectedPositionIndex ?? this.selectedPositionIndex, piecePositionIndices: piecePositionIndices ?? this.piecePositionIndices, selectedPlacedPiece: clearSelectedPlacedPiece ? null : (selectedPlacedPiece ?? this.selectedPlacedPiece), selectedCellInPiece: clearSelectedCellInPiece ? null : (selectedCellInPiece ?? this.selectedCellInPiece), selectedMasterAbs: clearSelectedMasterAbs ? null : (selectedMasterAbs ?? this.selectedMasterAbs), previewX: clearPreview ? null : (previewX ?? this.previewX), previewY: clearPreview ? null : (previewY ?? this.previewY), isPreviewValid: clearPreview ? false : (isPreviewValid ?? this.isPreviewValid), validPlacements: validPlacements ?? this.validPlacements, // ✨ NOUVEAU isComplete: isComplete ?? this.isComplete, isometryCount: isometryCount ?? this.isometryCount, translationCount: translationCount ?? this.translationCount, hintCount: hintCount ?? this.hintCount, deleteCount: deleteCount ?? this.deleteCount, isSnapped: isSnapped ?? this.isSnapped, isDragging: isDragging ?? this.isDragging, showSolution: showSolution ?? this.showSolution, // ✅ NOUVEAU currentSolution: currentSolution ?? this.currentSolution, // ✅ NOUVEAU hasPossibleSolution: hasPossibleSolution ?? this.hasPossibleSolution, // 💡 HINT solutionsCount: solutionsCount ?? this.solutionsCount, // 🔢 elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds, // ⏱️ Timer minIsometries: minIsometries ?? this.minIsometries, // 🏆 );
```

### getPiecePositionIndex

```dart
int getPiecePositionIndex(int pieceId) {
```

