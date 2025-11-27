# 🎯 La Mastercase dans Pentapol Tutorial

## 📖 Table des matières

1. [Qu'est-ce que la mastercase ?](#quest-ce-que-la-mastercase)
2. [Représentation visuelle](#représentation-visuelle)
3. [Système de coordonnées](#système-de-coordonnées)
4. [Dans les tutorials YAML](#dans-les-tutorials-yaml)
5. [Architecture technique](#architecture-technique)
6. [Exemples pratiques](#exemples-pratiques)
7. [Pièges courants](#pièges-courants)
8. [Déboguer les problèmes de mastercase](#déboguer-les-problèmes-de-mastercase)

---

## Qu'est-ce que la mastercase ?

La **mastercase** (case maître) est le **point de référence** d'une pièce placée sur le plateau. C'est :

### Rôle de la mastercase

1. **Point d'ancrage** : Position de référence de la pièce sur le plateau
2. **Centre de rotation** : Point fixe autour duquel la pièce pivote
3. **Centre de symétrie** : Axe de référence pour les transformations
4. **Identifiant de position** : Permet de localiser et sélectionner une pièce

### Représentation visuelle

- **Point rouge** sur le plateau dans l'interface Pentapol
- Toujours visible quand une pièce est sélectionnée
- Reste fixe lors des rotations géométriques

---

## Représentation visuelle

### Exemple : Pièce 6 (forme en L)
```
Position de base (position index 0) :

Dans la grille 5×5 interne :
     0   1   2   3   4
  0  ·   ·   ·   ·   ·
  1  ·   ·   ·   ·   ·
  2  ●   5   ·   ·   ·    ← Ligne Y=2
  3  ·   ·   ·   ·   ·
  4  ·   ·   5   5   5    ← Ligne Y=4

● = Mastercase (cellule 11, position locale (0, 2))
5 = Autres cellules de la pièce 6
```

### Sur le plateau (mastercase en (2, 4))
```
Plateau Pentapol (6×10) :
     0   1   2   3   4   5
  0  ·   ·   ·   ·   ·   ·
  1  ·   ·   ·   ·   ·   ·
  2  ·   ·   ·   ·   6   ·
  3  ·   ·   ·   ·   6   ·
  4  ·   ·   ●   6   6   ·    ← Mastercase en (2, 4)
  5  ·   ·   ·   ·   ·   ·
  ...

● = Mastercase (point rouge visible)
6 = Cellules de la pièce 6
```

---

## Système de coordonnées

### Coordonnées du plateau
```
     0   1   2   3   4   5
  0  ┌───┬───┬───┬───┬───┬───┐  ← HAUT
  1  ├───┼───┼───┼───┼───┼───┤
  2  ├───┼───┼───┼───┼───┼───┤
  3  ├───┼───┼───┼───┼───┼───┤
  4  ├───┼───┼───┼───┼───┼───┤
  5  ├───┼───┼───┼───┼───┼───┤
  6  ├───┼───┼───┼───┼───┼───┤
  7  ├───┼───┼───┼───┼───┼───┤
  8  ├───┼───┼───┼───┼───┼───┤
  9  └───┴───┴───┴───┴───┴───┘  ← BAS
     ↑                       ↑
   GAUCHE                 DROITE

- X : de 0 (gauche) à 5 (droite)
- Y : de 0 (haut) à 9 (bas)
- Origine (0,0) : Coin HAUT-GAUCHE
```

### Coordonnées internes d'une pièce

Chaque pièce a une grille interne 5×5 :
```
Cellule 1 = (0, 0)    Cellule 5 = (4, 0)
Cellule 6 = (0, 1)    Cellule 10 = (4, 1)
Cellule 11 = (0, 2)   Cellule 15 = (4, 2)
...
Cellule 21 = (0, 4)   Cellule 25 = (4, 4)

Formule de conversion :
  localX = (cellNum - 1) % 5
  localY = (cellNum - 1) ÷ 5  (division entière)
```

**Exemple pour cellule 11** :
```
localX = (11 - 1) % 5 = 10 % 5 = 0
localY = (11 - 1) ÷ 5 = 10 ÷ 5 = 2
→ (0, 2)
```

---

## Dans les tutorials YAML

### Placement avec mastercase
```yaml
# Placer la pièce avec sa mastercase en (2, 4)
- command: PLACE_SELECTED_PIECE_AT
  params:
    gridX: 2  # ← Position X de la mastercase
    gridY: 4  # ← Position Y de la mastercase
```

**Important** : `gridX` et `gridY` spécifient **la position de la mastercase**, pas du coin haut-gauche de la pièce !

### Sélection par la mastercase
```yaml
# Sélectionner en cliquant sur la mastercase
- command: SELECT_PIECE_ON_BOARD_AT
  params:
    x: 2  # Position de la mastercase
    y: 4
```

**Mais** : Vous pouvez aussi sélectionner en cliquant sur **n'importe quelle cellule** de la pièce :
```yaml
# Sélectionner en cliquant sur une autre cellule
- command: SELECT_PIECE_ON_BOARD_AT
  params:
    x: 3  # N'importe quelle cellule de la pièce
    y: 4  # Le système trouvera automatiquement la mastercase
```

### Rotation autour de la mastercase
```yaml
# La rotation se fait toujours autour de la mastercase
- command: ROTATE_AROUND_MASTER
  params:
    pieceNumber: 6
    quarterTurns: 1  # La pièce pivote autour de sa mastercase
```

**La mastercase reste FIXE** pendant la rotation. Seules les autres cellules bougent autour d'elle.

### Surligner la mastercase
```yaml
# Montrer visuellement où est la mastercase
- command: HIGHLIGHT_MASTERCASE
  params:
    x: 2  # Position de la mastercase à surligner
    y: 4
```

---

## Architecture technique

### Représentation interne
```dart
class PlacedPiece {
  final Pento piece;
  final int positionIndex;
  final int gridX;  // ← Position de L'ANCRE (pas la mastercase !)
  final int gridY;  // ← Position de L'ANCRE (pas la mastercase !)
}
```

**⚠️ IMPORTANT** : En interne, `gridX/gridY` stockent **l'ancre** (coin haut-gauche de la boîte 5×5), **PAS la mastercase** !

### Conversion mastercase ↔ ancre

Le système tutorial effectue automatiquement la conversion :
```dart
// Dans placeSelectedPieceForTutorial :

// 1. Trouver la mastercase locale
final mastercellNum = position.first;  // Première cellule = mastercase
final masterLocalX = (mastercellNum - 1) % 5;
final masterLocalY = (mastercellNum - 1) ~/ 5;

// 2. Convertir mastercase → ancre
final anchorX = mastercaseX - masterLocalX;
final anchorY = mastercaseY - masterLocalY;

// 3. Créer PlacedPiece avec l'ancre
final placedPiece = PlacedPiece(
  piece: piece,
  positionIndex: positionIndex,
  gridX: anchorX,  // ← Ancre stockée
  gridY: anchorY,  // ← Ancre stockée
);
```

### Calcul des cellules absolues
```dart
// Extension sur PlacedPiece
Iterable<Point> get absoluteCells sync* {
  final position = piece.positions[positionIndex];
  for (final cellNum in position) {
    final localX = (cellNum - 1) % 5;
    final localY = (cellNum - 1) ~/ 5;
    // Position absolue = ancre + offset local
    yield Point(gridX + localX, gridY + localY);
  }
}
```

**Note** : `gridX/gridY` sont l'ancre, donc la première cellule retournée est la mastercase !

---

## Exemples pratiques

### Exemple 1 : Placement simple

**Script YAML** :
```yaml
- command: SELECT_PIECE_FROM_SLIDER
  params:
    pieceNumber: 6

- command: PLACE_SELECTED_PIECE_AT
  params:
    gridX: 2  # Mastercase en (2, 4)
    gridY: 4
```

**Résultat** :
```
Plateau :
     0   1   2   3   4   5
  2  ·   ·   ·   ·   6   ·
  3  ·   ·   ·   ·   6   ·
  4  ·   ·   ●   6   6   ·  ← Point rouge en (2, 4)
  
● = Mastercase visible (point rouge)
```

**Logs** :
```
[TUTORIAL] Mastercase souhaitée: (2, 4)
[TUTORIAL] Mastercase locale: (0, 2)
[TUTORIAL] Ancre calculée: (2, 2)
[TUTORIAL] PlacedPiece absoluteCells: [(2, 4), (3, 4), (4, 2), (4, 3), (4, 4)]
```

La première cellule `(2, 4)` est bien la mastercase !

---

### Exemple 2 : Rotation autour de la mastercase

**Script YAML** :
```yaml
# Pièce déjà placée avec mastercase en (2, 4)
- command: SELECT_PIECE_ON_BOARD_AT
  params:
    x: 2
    y: 4

- command: SHOW_MESSAGE
  params:
    text: "La rotation va se faire autour du point rouge"

- command: ROTATE_AROUND_MASTER
  params:
    pieceNumber: 6
    quarterTurns: 1  # 90° horaire
```

**Avant rotation** :
```
     0   1   2   3   4   5
  2  ·   ·   ·   ·   6   ·
  3  ·   ·   ·   ·   6   ·
  4  ·   ·   ●   6   6   ·
```

**Après rotation 90° horaire** :
```
     0   1   2   3   4   5
  2  ·   ·   6   ·   ·   ·
  3  ·   ·   6   ·   ·   ·
  4  ·   ·   ●   6   6   ·
```

**La mastercase (●) reste en (2, 4) !** Les autres cellules ont pivoté autour.

**Logs** :
```
[GAME] 🔃 Rotation 90° horaire autour de (2, 4)
[GAME] 📍 Coordonnées avant rotation : [[2, 4], [3, 4], [4, 2], [4, 3], [4, 4]]
[GAME] 📍 Coordonnées après rotation : [[2, 4], [2, 3], [0, 2], [1, 2], [2, 2]]
[GAME] 🎯 Master case conservée : (2, 4) absolu
```

---

### Exemple 3 : Tutorial complet avec mastercase
```yaml
id: mastercase_demo
name: "Démo Mastercase"
description: "Comprendre le rôle de la mastercase"
difficulty: beginner
estimatedDuration: 60
tags:
  - mastercase
  - rotation

steps:
  - command: ENTER_TUTORIAL_MODE
  
  # 1. Placer une pièce
  - command: SHOW_MESSAGE
    params:
      text: "Plaçons la pièce 6 avec sa mastercase en (2, 4)"
      autoHideAfter: 3000
  
  - command: SELECT_PIECE_FROM_SLIDER
    params:
      pieceNumber: 6
  
  - command: HIGHLIGHT_CELL
    params:
      x: 2
      y: 4
      color: "red"
  
  - command: WAIT
    params:
      duration: 2000
  
  - command: PLACE_SELECTED_PIECE_AT
    params:
      gridX: 2
      gridY: 4
  
  - command: CLEAR_HIGHLIGHTS
  
  # 2. Expliquer la mastercase
  - command: SHOW_MESSAGE
    params:
      text: "Le point rouge que vous voyez est la MASTERCASE"
      autoHideAfter: 4000
  
  - command: WAIT
    params:
      duration: 4000
  
  - command: SHOW_MESSAGE
    params:
      text: "C'est le point de référence de la pièce"
      autoHideAfter: 3000
  
  - command: WAIT
    params:
      duration: 3000
  
  # 3. Sélectionner la pièce
  - command: SELECT_PIECE_ON_BOARD_AT
    params:
      x: 2
      y: 4
  
  - command: SHOW_MESSAGE
    params:
      text: "La rotation va se faire AUTOUR de ce point"
      autoHideAfter: 3000
  
  - command: WAIT
    params:
      duration: 3000
  
  # 4. Faire une rotation
  - command: ROTATE_AROUND_MASTER
    params:
      pieceNumber: 6
      quarterTurns: 1
      duration: 800
  
  - command: WAIT
    params:
      duration: 1000
  
  - command: SHOW_MESSAGE
    params:
      text: "Observez : la mastercase (point rouge) n'a PAS bougé !"
      autoHideAfter: 4000
  
  - command: WAIT
    params:
      duration: 4000
  
  # 5. Autre rotation
  - command: SHOW_MESSAGE
    params:
      text: "Encore une rotation..."
      autoHideAfter: 2000
  
  - command: WAIT
    params:
      duration: 2000
  
  - command: ROTATE_AROUND_MASTER
    params:
      pieceNumber: 6
      quarterTurns: 1
      duration: 800
  
  - command: WAIT
    params:
      duration: 1000
  
  - command: SHOW_MESSAGE
    params:
      text: "La mastercase reste toujours fixe en (2, 4) !"
      autoHideAfter: 4000
  
  - command: WAIT
    params:
      duration: 4000
  
  - command: CLEAR_MESSAGE
  
  - command: EXIT_TUTORIAL_MODE
```

---

## Pièges courants

### ❌ Piège 1 : Confondre mastercase et coin haut-gauche

**ERREUR** :
```dart
// Penser que gridX/gridY dans PlacedPiece = mastercase
final mastercaseX = placedPiece.gridX;  // ❌ C'est l'ancre !
```

**CORRECT** :
```dart
// Utiliser absoluteCells
final mastercase = placedPiece.absoluteCells.first;  // ✅ Première cellule
```

---

### ❌ Piège 2 : Sélectionner une case vide

**ERREUR** :
```yaml
# Pièce placée avec cellules en [(2,4), (3,4), (4,2), (4,3), (4,4)]
- command: SELECT_PIECE_ON_BOARD_AT
  params:
    x: 1  # ❌ Pas de pièce ici !
    y: 4
```

**Résultat** : `Bad state: Aucune pièce à la position (1, 4)`

**CORRECT** :
```yaml
# Sélectionner sur une cellule qui contient vraiment la pièce
- command: SELECT_PIECE_ON_BOARD_AT
  params:
    x: 2  # ✅ Cellule occupée par la pièce
    y: 4
```

---

### ❌ Piège 3 : Coordonnées négatives après rotation

**ERREUR** :
```yaml
# Placer près du bord gauche
- command: PLACE_SELECTED_PIECE_AT
  params:
    gridX: 0  # Trop près du bord !
    gridY: 4

# Rotation → certaines cellules sortent du plateau (x < 0)
- command: ROTATE_AROUND_MASTER
  params:
    pieceNumber: 6
    quarterTurns: 1
```

**CORRECT** :
```yaml
# Placer avec plus d'espace autour
- command: PLACE_SELECTED_PIECE_AT
  params:
    gridX: 2  # ✅ Espace suffisant
    gridY: 4
```

---

### ❌ Piège 4 : Oublier la sélection avant rotation

**ERREUR** :
```yaml
# Placer la pièce
- command: PLACE_SELECTED_PIECE_AT
  params:
    gridX: 2
    gridY: 4

# Rotation SANS sélectionner avant
- command: ROTATE_AROUND_MASTER  # ❌ Aucune pièce sélectionnée !
  params:
    pieceNumber: 6
    quarterTurns: 1
```

**CORRECT** :
```yaml
# Placer la pièce
- command: PLACE_SELECTED_PIECE_AT
  params:
    gridX: 2
    gridY: 4

# Sélectionner AVANT de faire pivoter
- command: SELECT_PIECE_ON_BOARD_AT
  params:
    x: 2
    y: 4

# Maintenant on peut pivoter
- command: ROTATE_AROUND_MASTER
  params:
    pieceNumber: 6
    quarterTurns: 1
```

---

## Déboguer les problèmes de mastercase

### Vérifier la position de la mastercase

**Ajoutez des logs dans votre script** :
```yaml
- command: PLACE_SELECTED_PIECE_AT
  params:
    gridX: 2
    gridY: 4

# Après placement, vérifiez les logs
```

**Cherchez dans les logs** :
```
[TUTORIAL] Mastercase souhaitée: (2, 4)
[TUTORIAL] Mastercase locale: (0, 2)
[TUTORIAL] Ancre calculée: (2, 2)
[TUTORIAL] PlacedPiece absoluteCells: [(2, 4), (3, 4), ...]
                                        ^^^^^^
                                        Première cellule = mastercase !
```

---

### Visualiser avec highlights

**Script de debug** :
```yaml
# Placer la pièce
- command: PLACE_SELECTED_PIECE_AT
  params:
    gridX: 2
    gridY: 4

# Surligner où devrait être la mastercase
- command: HIGHLIGHT_CELL
  params:
    x: 2
    y: 4
    color: "red"

- command: SHOW_MESSAGE
  params:
    text: "Le point rouge dans l'UI doit être sur la case rouge surlignée"

- command: WAIT
  params:
    duration: 5000
```

**Si le point rouge de la pièce n'est PAS sur la case rouge surlignée, il y a un problème !**

---

### Commande grep utile

**Pour voir comment les cellules sont calculées** :
```bash
grep -A 10 "absoluteCells" lib/providers/pentomino_game_state.dart
```

**Pour voir la conversion mastercase→ancre** :
```bash
grep -B 5 -A 15 "Conversion mastercase" lib/providers/pentomino_game_provider.dart
```

---

## Résumé technique

| Concept | Description | Valeur |
|---------|-------------|--------|
| **Mastercase** | Point de référence visible (point rouge) | Première cellule de `position[0]` |
| **Ancre** | Coin haut-gauche de la boîte 5×5 (stocké) | `PlacedPiece.gridX/gridY` |
| **Cellule locale** | Position dans la grille 5×5 interne | `(localX, localY)` calculé depuis `cellNum` |
| **Cellule absolue** | Position sur le plateau 6×10 | `ancre + offset local` |
| **Centre de rotation** | Point fixe lors des rotations | La mastercase |

---

## Formules clés

### Cellule locale → Coordonnées
```dart
localX = (cellNum - 1) % 5
localY = (cellNum - 1) ÷ 5  // division entière
```

### Mastercase → Ancre
```dart
anchorX = mastercaseX - masterLocalX
anchorY = mastercaseY - masterLocalY
```

### Ancre + offset → Cellule absolue
```dart
absoluteX = anchorX + localX
absoluteY = anchorY + localY
```

---

## Références

- **Code** : `lib/providers/pentomino_game_state.dart` (extension PlacedPiece)
- **Tutorial placement** : `lib/providers/pentomino_game_provider.dart` (placeSelectedPieceForTutorial)
- **Commandes YAML** : `TUTORIAL_COMMANDS.md`
- **Architecture** : `TUTORIAL_ARCHITECTURE.md`

---

**Document rédigé en Novembre 2025**

**Version** : 1.0

**Mastercase = Le cœur du système de référence Pentapol ! 🎯**