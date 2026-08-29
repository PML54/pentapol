# common/piece_interaction_mixin.dart

**Module:** common

## Fonctions

### stateWithDragging

Interaction avec les pièces — sélection, drag, preview, placement.

Le module fournit des adaptateurs d'écriture (`stateWith*`) : le mixin ne connaît
pas la forme de l'état, seulement le moyen d'y écrire. La **lecture**, elle, passe
par le contrat [PieceManipulationState] établi à l'étape 1 — c'est ce qui permet
à [clearPreview] d'interroger `state.previewX` sans connaître le type concret.

## Portée actuelle, et pourquoi elle est si étroite

Ce mixin n'héberge pour l'instant que [setDragging] et [clearPreview]. L'intérêt
n'est pas d'économiser huit lignes : c'est d'**établir le domicile** où les
familles lourdes — sélection, preview, placement — viendront s'installer, en
validant le mécanisme sur des méthodes dont l'échec serait immédiatement visible
et sans conséquence.

**[updatePreview] n'y est délibérément pas.** Les deux modules en ont des versions
de taille comparable (37 et 38 lignes) mais qui reposent sur des **algorithmes
différents** :

- le mode classique calcule la validité à la volée : position exacte, puis
recherche de la plus proche position valide, sinon preview rouge au curseur ;
- Pentoscope s'appuie sur `validPlacements`, une liste **pré-calculée** stockée
dans son état, que le mode classique n'a pas, et n'écrit jamais `isSnapped`.

Les unifier revient à choisir un comportement de snapping pour les deux modes.
C'est une décision de jeu, pas un refactor : elle rejoint `tryPlacePiece` dans les
familles à réconcilier, pas dans les gains faciles.
Retourne l'état courant avec le drapeau de drag mis à jour.

Implémentation typique : `state.copyWith(isDragging: isDragging)`.


```dart
S stateWithDragging(bool isDragging);
```

### stateWithPreviewCleared

Retourne l'état courant sans preview de placement.

Implémentation typique : `state.copyWith(clearPreview: true)`.


```dart
S stateWithPreviewCleared();
```

### setDragging

Signale le début ou la fin d'un drag.


```dart
void setDragging(bool value) {
```

### clearPreview

Efface la preview de placement.

La garde évite une écriture d'état — donc une reconstruction — quand il n'y a
rien à effacer. Le mode classique l'avait, Pentoscope non : ce dernier
reconstruisait à chaque appel, y compris à vide.


```dart
void clearPreview() {
```

