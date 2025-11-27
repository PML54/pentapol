# Langage "Scratch Pentapol" – Spécification & Mapping vers le code

## 1. Vocabulaire standard Pentapol

- **Slider**
    - Bandeau contenant de **1 à 12 pièces** disponibles.
    - Peut défiler (tourner).
    - Les pièces du slider **ne sont pas** sur le plateau.

- **Plateau**
    - Grille **6 × 10** : `x` ∈ [0..5], `y` ∈ [0..9].
    - C’est la zone de jeu où l’on pose les pièces.

- **Pièce**
    - Identifiée par un **numéro** : `pieceNumber` (1 à 12).
    - A plusieurs **positions** : `positions[]` (rotations + symétries).

- **Oricase**
    - Définie pour une **pièce posée et non sélectionnée**.
    - C’est la case de la pièce sur le plateau qui a :
        - le **plus grand Y** (la plus basse),
        - et, parmi celles-là, le **plus petit X** (la plus à gauche).

- **Mastercase**
    - Quand une **case d’une pièce est sélectionnée**, elle devient la mastercase.
    - La mastercase remplace l’oricase comme **pivot**.
    - **Règle** : on ne peut faire **rotation / symétrie / translation tutorielle** que sur une pièce qui a une mastercase.

---

## 2. Catégories de commandes Scratch-Pentapol

1. **Contrôle / temps**
2. **Messages**
3. **Gestion de partie**
4. **Sélection / contexte**
5. **Placement / suppression / undo**
6. **Preview (fantômes)**
7. **Manipulation de pièces (mouvement)**
8. **Mastercase**
9. **Transformations autour de la mastercase**

Pour chaque commande :
- **Scratch** : nom de bloc
- **Description** : ce qu’il fait conceptuellement
- **Équivalent Pentapol** : méthode ou concept dans `PentominoGameNotifier` / `PentominoGameState` (quand il existe)

---

## 3. Contrôle / temps

### 3.1. `WAIT(durationMs)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `WAIT(durationMs)` |
| **Description** | Met en pause l’exécution du script de démo pendant `durationMs` millisecondes. |
| **Équivalent Pentapol** | Aucun direct : c’est géré par le **moteur de tutoriel** (ex. `Future.delayed`). |

---

## 4. Messages

### 4.1. `SHOW_MESSAGE("texte")`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `SHOW_MESSAGE("texte")` |
| **Description** | Affiche `texte` dans le bandeau de tutoriel en bas de l’écran. |
| **Équivalent Pentapol** | Propriété dans `TutorialState.currentMessage` (à afficher dans `PentominoGameScreen`). |

### 4.2. `CLEAR_MESSAGE()`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `CLEAR_MESSAGE()` |
| **Description** | Efface le message affiché dans le bandeau. |
| **Équivalent Pentapol** | `TutorialState.currentMessage = null`. |

---

## 5. Gestion de partie

### 5.1. `RESET_GAME()`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `RESET_GAME()` |
| **Description** | Réinitialise complètement la partie (plateau vide, pièces à nouveau disponibles). |
| **Équivalent Pentapol** | `PentominoGameNotifier.reset()` |

---

## 6. Sélection / contexte

### 6.1. `SELECT_PIECE_FROM_SLIDER(pieceNumber)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `SELECT_PIECE_FROM_SLIDER(pieceNumber)` |
| **Description** | Simule un tap sur une pièce du slider : la pièce devient la pièce sélectionnée (`selectedPiece`). |
| **Équivalent Pentapol** | `PentominoGameNotifier.selectPiece(Pento)` (ou logique équivalente). |

---

### 6.2. `SELECT_PIECE_ON_BOARD_AT(x, y)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `SELECT_PIECE_ON_BOARD_AT(x, y)` |
| **Description** | Sélectionne la pièce posée qui occupe la case `(x, y)` sur le plateau. Définit aussi la case cliquée comme **mastercase**. |
| **Équivalent Pentapol** | `PentominoGameNotifier.selectPlacedPiece(placedPiece, tapCell)` (en retrouvant `placedPiece` par `(x, y)`). |

---

### 6.3. `CANCEL_SELECTION()`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `CANCEL_SELECTION()` |
| **Description** | Annule la sélection actuelle, quitte le mode transformations. |
| **Équivalent Pentapol** | `PentominoGameNotifier.cancelSelection()` ou logique équivalente (`selectedPiece = null`, `selectedPlacedPiece = null`, `isIsometriesMode = false`). |

---

## 7. Placement / suppression / undo

### 7.1. `PLACE_SELECTED_PIECE_AT(gridX, gridY)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `PLACE_SELECTED_PIECE_AT(gridX, gridY)` |
| **Description** | Pose la pièce actuellement sélectionnée sur la case `(gridX, gridY)` du plateau (en respectant les règles : pas de chevauchement, dans la grille…). |
| **Équivalent Pentapol** | `PentominoGameNotifier.tryPlacePiece(gridX, gridY)` (utilise `selectedPiece` + mastercase/offset). |

---

### 7.2. `REMOVE_PIECE_AT(x, y)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `REMOVE_PIECE_AT(x, y)` |
| **Description** | Supprime la pièce posée qui occupe la case `(x, y)` sur le plateau. |
| **Équivalent Pentapol** | Trouver le `PlacedPiece` à `(x, y)` puis `PentominoGameNotifier.removePlacedPiece(placedPiece)`. |

> Variante possible : `REMOVE_PIECE(pieceNumber)` si tu veux cibler par numéro.

---

### 7.3. `UNDO_LAST_PLACEMENT()`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `UNDO_LAST_PLACEMENT()` |
| **Description** | Annule la **dernière pose** de pièce (comme un “Ctrl+Z” local au plateau). |
| **Équivalent Pentapol** | `PentominoGameNotifier.undoLastPlacement()` |

---

## 8. Preview (fantômes)

### 8.1. `SHOW_PREVIEW_AT(gridX, gridY)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `SHOW_PREVIEW_AT(gridX, gridY)` |
| **Description** | Affiche la position **prévisionnelle** (ghost) de la pièce sélectionnée si elle était posée en `(gridX, gridY)`. |
| **Équivalent Pentapol** | `PentominoGameNotifier.updatePreview(gridX, gridY)` |

---

### 8.2. `CLEAR_PREVIEW()`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `CLEAR_PREVIEW()` |
| **Description** | Efface le ghost de prévisualisation. |
| **Équivalent Pentapol** | `PentominoGameNotifier.clearPreview()` |

---

## 9. Manipulation de pièces (mouvement tutoriel)

Ces commandes manipulent une **pièce de démo** (ghost), pas forcément une pièce réelle du `PentominoGameState`. Elles sont surtout pour le **tutoriel animé**.

### 9.1. `SPAWN_FROM_SLIDER(pieceNumber, orientationIndex)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `SPAWN_FROM_SLIDER(pieceNumber, orientationIndex)` |
| **Description** | Fait apparaître une **pièce de démo** `pieceNumber` avec orientation `orientationIndex` à la position visuelle du slider. |
| **Équivalent Pentapol** | À implémenter dans la couche **Demo/Tutoriel** (pas d’équivalent direct dans le provider actuel). |

---

### 9.2. `MOVE_PIECE_BY(pieceNumber, dx, dy, durationMs)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `MOVE_PIECE_BY(pieceNumber, dx, dy, durationMs)` |
| **Description** | Translate la pièce de démo `pieceNumber` de `(dx, dy)` cases (translation de sa case pivot : oricase/mastercase) en `durationMs`. |
| **Équivalent Pentapol** | À implémenter dans le moteur de démo (`DemoPieceState.gridX/gridY` + animation) ; pas de méthode directe dans le provider. |

---

### 9.3. `FOLLOW_PATH(pieceNumber, path, totalDurationMs)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `FOLLOW_PATH(pieceNumber, path, totalDurationMs)` |
| **Description** | Déplace la pièce de démo le long d’un **chemin** de positions plateau pour la case pivot : `[(x0,y0), ..., (xn,yn)]`, avec une durée totale `totalDurationMs`. |
| **Équivalent Pentapol** | À implémenter dans le moteur de démo (interpolation + timeline). |

---

## 10. Mastercase

### 10.1. `SET_MASTERCASE_BY_ORICASE(pieceNumber)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `SET_MASTERCASE_BY_ORICASE(pieceNumber)` |
| **Description** | Calcule l’**oricase** de la pièce `pieceNumber` (Y max puis X min) et la définit comme **mastercase**. La pièce devient transformable. |
| **Équivalent Pentapol** | Logique interne à implémenter sur la représentation de la pièce de démo (et/ou sur `PlacedPiece` si tu veux l’utiliser en jeu). |

---

### 10.2. `SET_MASTERCASE_AT(pieceNumber, localIndex)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `SET_MASTERCASE_AT(pieceNumber, localIndex)` |
| **Description** | Définit la mastercase sur une case précise de la pièce, identifiée par `localIndex` (indice logique dans la définition de la pièce). |
| **Équivalent Pentapol** | Représentation à implémenter dans `DemoPieceState` (ou mapping avec `selectPlacedPiece` côté jeu réel). |

---

## 11. Transformations autour de la mastercase (mastercase obligatoire)

⚠️ Ces blocs **ne sont valides** que si une mastercase a été définie pour la pièce (`SET_MASTERCASE_*` ou sélection utilisateur).

### 11.1. `ROTATE_AROUND_MASTER(pieceNumber, quarterTurns, durationMs)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `ROTATE_AROUND_MASTER(pieceNumber, quarterTurns, durationMs)` |
| **Description** | Fait tourner la pièce `pieceNumber` de `quarterTurns` quarts de tour (±1, ±2…) **autour de sa mastercase**, qui reste sur la même case plateau. |
| **Équivalent Pentapol** | Côté jeu réel : `applyIsometryRotation()`, `applyIsometryRotationCW()`, `cycleToNextOrientation()` sur `selectedPlacedPiece` (pivot géré par ta mastercase). Côté démo : logique à implémenter sur `DemoPieceState.orientationIndex`. |

---

### 11.2. `SYMMETRY_AROUND_MASTER(pieceNumber, symmetryKind, durationMs)`

| Élément      | Détail |
|-------------|--------|
| **Scratch** | `SYMMETRY_AROUND_MASTER(pieceNumber, symmetryKind, durationMs)` |
| **Description** | Applique une symétrie **H** ou **V** autour de la mastercase de la pièce, qui reste fixée sur sa case plateau. |
| **Équivalent Pentapol** | Côté jeu réel : `applyIsometrySymmetryH()`, `applyIsometrySymmetryV()` sur `selectedPlacedPiece`. Côté démo : changement d’orientation dans `DemoPieceState`. |

---

## 12. Résumé

- Le **langage Scratch-Pentapol** couvre désormais :
    - les **messages**,
    - le **temps**,
    - la **gestion de partie**,
    - la **sélection** (slider & plateau),
    - le **placement / suppression / undo**,
    - le **preview**,
    - le **mouvement tutoriel** (chemin, vecteur),
    - la **mastercase**,
    - les **transformations** autour de la mastercase.

- La plupart des blocs ont un **équivalent direct** dans `PentominoGameNotifier`  
  (ou sont des couches au-dessus, côté démo).

- Tu peux :
    - écrire des **tutoriels** (scripts de démo),
    - créer des **exercices** (en ajoutant des blocs `EXPECT_*`),
    - laisser une **IA** générer des scripts à partir de questions du joueur.

```md
