# 📚 Liste des commandes Tutorial Pentapol

## 📐 Système de coordonnées

Le plateau Pentapol utilise ces coordonnées :
- **X** : de 0 (gauche) à 5 (droite)
- **Y** : de 0 (haut) à 9 (bas)
- **Origine (0,0)** : Coin HAUT-GAUCHE
```
     0   1   2   3   4   5
  0  ┌───┬───┬───┬───┬───┬───┐
  1  ├───┼───┼───┼───┼───┼───┤
  2  ├───┼───┼───┼───┼───┼───┤
  3  ├───┼───┼───┼───┼───┼───┤
  4  ├───┼───┼───┼───┼───┼───┤
  5  ├───┼───┼───┼───┼───┼───┤
  6  ├───┼───┼───┼───┼───┼───┤
  7  ├───┼───┼───┼───┼───┼───┤
  8  ├───┼───┼───┼───┼───┼───┤
  9  └───┴───┴───┴───┴───┴───┘
```

**Exemples de coordonnées :**
- `(0, 0)` = Coin haut-gauche
- `(5, 0)` = Coin haut-droite
- `(0, 9)` = Coin bas-gauche
- `(5, 9)` = Coin bas-droite
- `(2, 4)` = Centre du plateau

---

## 🎮 Contrôle

### WAIT
Attend un certain temps.
```yaml
- command: WAIT
  params:
    duration: 2000  # millisecondes (optionnel, défaut: 1000)
```

### REPEAT
Répète un bloc de commandes (à implémenter).
```yaml
- command: REPEAT
  params:
    count: 3
```

---

## 💬 Messages

### SHOW_MESSAGE
Affiche un message à l'utilisateur avec timeout optionnel.
```yaml
- command: SHOW_MESSAGE
  params:
    text: "Votre message ici"
    autoHideAfter: 3000  # optionnel, en ms (efface automatiquement le message)
```

**Exemples :**
```yaml
# Message qui reste jusqu'à CLEAR_MESSAGE
- command: SHOW_MESSAGE
  params:
    text: "Sélectionnez la pièce 5"

# Message qui disparaît automatiquement après 3 secondes
- command: SHOW_MESSAGE
  params:
    text: "Bravo !"
    autoHideAfter: 3000
```

### CLEAR_MESSAGE
Efface le message affiché.
```yaml
- command: CLEAR_MESSAGE
```

---

## 🎯 Mode Tutoriel

### ENTER_TUTORIAL_MODE
Entre en mode tutoriel (sauvegarde l'état du jeu).
```yaml
- command: ENTER_TUTORIAL_MODE
```

### EXIT_TUTORIAL_MODE
Sort du mode tutoriel et restaure l'état.
```yaml
- command: EXIT_TUTORIAL_MODE
  params:
    restore: true  # optionnel, défaut: true (restaure l'état sauvegardé)
```

### CANCEL_TUTORIAL
Annule le tutoriel immédiatement.
```yaml
- command: CANCEL_TUTORIAL
```

### RESET_GAME
Réinitialise le jeu (à implémenter).
```yaml
- command: RESET_GAME
```

---

## 📱 Slider de pièces

### SELECT_PIECE_FROM_SLIDER
Sélectionne une pièce depuis le slider.
```yaml
- command: SELECT_PIECE_FROM_SLIDER
  params:
    pieceNumber: 5  # ID de la pièce (1-12)
```

**IDs des pièces :** 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12

### HIGHLIGHT_PIECE_IN_SLIDER
Surligne une pièce dans le slider pour attirer l'attention.
```yaml
- command: HIGHLIGHT_PIECE_IN_SLIDER
  params:
    pieceNumber: 5
```

### CLEAR_SLIDER_HIGHLIGHT
Efface le surlignage du slider.
```yaml
- command: CLEAR_SLIDER_HIGHLIGHT
```

### SCROLL_SLIDER
Fait défiler le slider d'un certain nombre de positions.
```yaml
- command: SCROLL_SLIDER
  params:
    positions: 3  # nombre de positions (positif = droite, négatif = gauche)
```

### SCROLL_SLIDER_TO_PIECE
Centre le slider sur une pièce spécifique.
```yaml
- command: SCROLL_SLIDER_TO_PIECE
  params:
    pieceNumber: 5
```

### RESET_SLIDER_POSITION
Remet le slider à sa position initiale.
```yaml
- command: RESET_SLIDER_POSITION
```

---

## 🎲 Plateau - Sélection

### SELECT_PIECE_ON_BOARD_AT
Sélectionne une pièce déjà placée sur le plateau.
```yaml
- command: SELECT_PIECE_ON_BOARD_AT
  params:
    x: 3  # coordonnée X (0-5)
    y: 5  # coordonnée Y (0-9)
```

**Note :** La cellule (x, y) doit contenir une pièce placée.

### SELECT_PIECE_ON_BOARD_WITH_MASTERCASE
Sélectionne une pièce avec une mastercase spécifique.
```yaml
- command: SELECT_PIECE_ON_BOARD_WITH_MASTERCASE
  params:
    pieceNumber: 5
    mastercaseX: 2
    mastercaseY: 4
```

### HIGHLIGHT_PIECE_ON_BOARD
Surligne toutes les cellules d'une pièce sur le plateau.
```yaml
- command: HIGHLIGHT_PIECE_ON_BOARD
  params:
    pieceNumber: 5
```

### CANCEL_SELECTION
Annule la sélection en cours (pièce du slider ou du plateau).
```yaml
- command: CANCEL_SELECTION
```

---

## 📍 Plateau - Placement

### PLACE_SELECTED_PIECE_AT
Place la pièce actuellement sélectionnée sur le plateau.
```yaml
- command: PLACE_SELECTED_PIECE_AT
  params:
    gridX: 2  # position X de l'ancre (0-5)
    gridY: 4  # position Y de l'ancre (0-9)
```

**Important :** Une pièce doit être sélectionnée avant (via SELECT_PIECE_FROM_SLIDER).

### REMOVE_PIECE_AT
Retire une pièce du plateau.
```yaml
- command: REMOVE_PIECE_AT
  params:
    x: 2  # coordonnée X d'une cellule de la pièce
    y: 4  # coordonnée Y d'une cellule de la pièce
```

---

## 🟩 Highlights de cases

### HIGHLIGHT_CELL
Surligne une case spécifique.
```yaml
- command: HIGHLIGHT_CELL
  params:
    x: 2
    y: 4
    color: "green"  # yellow, green, blue, red, orange
```

### HIGHLIGHT_CELLS
Surligne plusieurs cases avec la même couleur.
```yaml
- command: HIGHLIGHT_CELLS
  params:
    cells:
      - x: 2
        y: 4
      - x: 3
        y: 4
      - x: 2
        y: 5
    color: "yellow"
```

### HIGHLIGHT_VALID_POSITIONS
Surligne toutes les positions valides pour placer une pièce.
```yaml
- command: HIGHLIGHT_VALID_POSITIONS
  params:
    pieceNumber: 5
    color: "green"
```

### CLEAR_HIGHLIGHTS
Efface tous les surlignages de cases.
```yaml
- command: CLEAR_HIGHLIGHTS
```

### HIGHLIGHT_MASTERCASE
Surligne la mastercase (point de référence) d'une pièce.
```yaml
- command: HIGHLIGHT_MASTERCASE
  params:
    x: 3
    y: 5
```

---

## 🔄 Transformations

### ROTATE_AROUND_MASTER
Fait pivoter une pièce sélectionnée autour de sa mastercase.
```yaml
- command: ROTATE_AROUND_MASTER
  params:
    pieceNumber: 5
    quarterTurns: 1    # 1 = 90° horaire, 2 = 180°, 3 = 270°, -1 = 90° anti-horaire
    duration: 500      # optionnel, durée animation en ms
```

**Note :** La pièce doit être sélectionnée et placée sur le plateau.

### SYMMETRY_AROUND_MASTER
Applique une symétrie à une pièce sélectionnée.
```yaml
- command: SYMMETRY_AROUND_MASTER
  params:
    pieceNumber: 5
    symmetryKind: "H"  # H = horizontale, V = verticale
    duration: 500      # optionnel, durée animation en ms
```

**Note :** La pièce doit être sélectionnée et placée sur le plateau.

---

## 📋 Structure d'un script tutorial
```yaml
# En-tête du tutorial
id: mon_tutoriel_unique
name: "Nom affiché du tutoriel"
description: "Description courte du tutoriel"
difficulty: beginner  # beginner, intermediate, advanced
estimatedDuration: 60  # durée estimée en secondes
tags:
  - introduction
  - placement
  - rotation

# Liste des étapes
steps:
  # Toujours commencer par entrer en mode tutoriel
  - command: ENTER_TUTORIAL_MODE
  
  # Premier message de bienvenue
  - command: SHOW_MESSAGE
    params:
      text: "Bienvenue dans ce tutoriel !"
      autoHideAfter: 3000
  
  - command: WAIT
    params:
      duration: 3000
  
  # Sélectionner une pièce
  - command: SCROLL_SLIDER_TO_PIECE
    params:
      pieceNumber: 5
  
  - command: HIGHLIGHT_PIECE_IN_SLIDER
    params:
      pieceNumber: 5
  
  - command: SHOW_MESSAGE
    params:
      text: "Sélectionnez cette pièce"
  
  - command: WAIT
    params:
      duration: 2000
  
  - command: SELECT_PIECE_FROM_SLIDER
    params:
      pieceNumber: 5
  
  - command: CLEAR_SLIDER_HIGHLIGHT
  
  # Placer la pièce
  - command: SHOW_MESSAGE
    params:
      text: "Plaçons-la ici"
  
  - command: HIGHLIGHT_CELL
    params:
      x: 2
      y: 4
      color: "green"
  
  - command: WAIT
    params:
      duration: 2000
  
  - command: PLACE_SELECTED_PIECE_AT
    params:
      gridX: 2
      gridY: 4
  
  - command: CLEAR_HIGHLIGHTS
  
  # Message de félicitations
  - command: SHOW_MESSAGE
    params:
      text: "Bravo ! 🎉"
      autoHideAfter: 3000
  
  - command: WAIT
    params:
      duration: 3000
  
  # Toujours terminer par sortir du mode tutoriel
  - command: EXIT_TUTORIAL_MODE
```

---

## 💡 Bonnes pratiques

### 1. Structure de base
- **Toujours commencer** par `ENTER_TUTORIAL_MODE`
- **Toujours terminer** par `EXIT_TUTORIAL_MODE`
- Utiliser des IDs uniques pour chaque tutorial

### 2. Rythme et timing
- Ajouter des `WAIT` entre les actions (1000-3000ms)
- Messages courts avec `autoHideAfter` pour ne pas surcharger
- Laisser le temps de voir les animations (500-1000ms)

### 3. Guidage visuel
- `HIGHLIGHT_CELL` pour montrer où agir
- `HIGHLIGHT_PIECE_IN_SLIDER` pour attirer l'attention
- `SCROLL_SLIDER_TO_PIECE` pour centrer sur la bonne pièce
- Toujours `CLEAR_HIGHLIGHTS` après usage

### 4. Messages
```yaml
# Court et persistant
- command: SHOW_MESSAGE
  params:
    text: "Sélectionnez la pièce 5"

# Court et disparaît automatiquement
- command: SHOW_MESSAGE
  params:
    text: "Bravo !"
    autoHideAfter: 2000
```

### 5. Séquence typique de placement
```yaml
# 1. Montrer la pièce dans le slider
- command: SCROLL_SLIDER_TO_PIECE
  params:
    pieceNumber: 5

- command: HIGHLIGHT_PIECE_IN_SLIDER
  params:
    pieceNumber: 5

# 2. Message explicatif
- command: SHOW_MESSAGE
  params:
    text: "Sélectionnons cette pièce"

- command: WAIT
  params:
    duration: 2000

# 3. Sélectionner
- command: SELECT_PIECE_FROM_SLIDER
  params:
    pieceNumber: 5

- command: CLEAR_SLIDER_HIGHLIGHT

# 4. Montrer où placer
- command: SHOW_MESSAGE
  params:
    text: "Plaçons-la ici"

- command: HIGHLIGHT_CELL
  params:
    x: 2
    y: 4
    color: "green"

- command: WAIT
  params:
    duration: 2000

# 5. Placer
- command: PLACE_SELECTED_PIECE_AT
  params:
    gridX: 2
    gridY: 4

- command: CLEAR_HIGHLIGHTS
```

### 6. Séquence typique de rotation
```yaml
# 1. Sélectionner la pièce sur le plateau
- command: SELECT_PIECE_ON_BOARD_AT
  params:
    x: 3  # une cellule de la pièce
    y: 5

# 2. Expliquer
- command: SHOW_MESSAGE
  params:
    text: "Observez la rotation autour du point rouge"

- command: WAIT
  params:
    duration: 2000

# 3. Faire pivoter
- command: ROTATE_AROUND_MASTER
  params:
    pieceNumber: 5
    quarterTurns: 1
    duration: 800

- command: WAIT
  params:
    duration: 1000
```

---

## 🚀 Exemples de tutorials complets

### Tutorial débutant : Placement simple
Voir `assets/tutorials/01_intro_basics.yaml`

### Tutorial test : Coordonnées
Voir `assets/tutorials/test_coords.yaml`

---

## 🔮 Phase 2 (à venir)

Commandes avancées en développement :
- **Conditions** : IF/ELSE basé sur l'état du jeu
- **Variables** : Stocker et manipuler des valeurs
- **Boucles** : FOR, WHILE avec conditions
- **Interactions** : WAIT_FOR_TAP, WAIT_FOR_PIECE_PLACED
- **Animations** : Transitions fluides, effets visuels
- **Audio** : Sons et musique pendant le tutorial

---

## 📞 Support

Pour toute question ou amélioration :
- Voir le code source dans `lib/tutorial/`
- Consulter les exemples dans `assets/tutorials/`
- Les logs commencent par `[TUTORIAL]`, `[INTERPRETER]`, `[PARSER]`

---

**Dernière mise à jour : Novembre 2025**