# 📚 CURSORDOC - Documentation Technique Pentapol

**Application de puzzles pentominos en Flutter**

**Date de création : 14 novembre 2025**  
**Dernière mise à jour : 1er décembre 2025**

---

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [Modèles de données](#modèles-de-données)
4. [Services](#services)
5. [Écrans](#écrans)
6. [Providers (Riverpod)](#providers-riverpod)
7. [Système de solutions](#système-de-solutions)
8. [Système de tutoriel](#système-de-tutoriel)
9. [Configuration](#configuration)
10. [Réorganisation complète](#réorganisation-complète)
11. [Index des fichiers](#index-des-fichiers)

---

## 🎯 Vue d'ensemble

Pentapol est une application Flutter permettant de :
- Créer et éditer des plateaux de pentominos (grille 6×10)
- Résoudre automatiquement les puzzles
- Jouer interactivement avec drag & drop
- Naviguer dans une base de 2339 solutions canoniques (9356 avec transformations)
- Jouer avec deux modes : **Mode Jeu** (placement de pièces) et **Mode Isométries** (transformations géométriques)
- **Apprendre avec des tutoriels interactifs** guidés par un système de scripting YAML
- **Jouer en mode Duel** : Affrontez un adversaire en temps réel pour compléter une solution

### Technologies principales
- **Flutter** : Framework UI
- **Riverpod** : Gestion d'état
- **Supabase** : Backend (mode Duel multijoueur)
- **BigInt** : Encodage solutions sur 360 bits (60 cases × 6 bits)
- **SQLite** : Base de données locale (via Drift)
- **YAML** : Scripts de tutoriel avec langage de commandes type Scratch

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # Point d'entrée, pré-chargement solutions
│   DATEMODIF: 11151556  CODELINE: 69
│
├── bootstrap.dart               # Init Supabase
│   DATEMODIF: -  CODELINE: 10
│
├── config/
│   └── game_icons_config.dart  # Configuration des icônes de jeu
│       DATEMODIF: 11231630  CODELINE: 139
│
├── models/                      # Modèles de données
│   ├── pentominos.dart         # 12 pièces avec toutes rotations
│   │   DATEMODIF: 11200721  CODELINE: 413
│   ├── plateau.dart            # Grille de jeu 6×10
│   │   DATEMODIF: 11191843  CODELINE: 77
│   ├── bigint_plateau.dart     # Plateau encodé en BigInt
│   │   DATEMODIF: 11150647  CODELINE: 95
│   ├── game_piece.dart         # Pièce interactive
│   │   DATEMODIF: 11150647  CODELINE: 74
│   ├── game.dart               # État complet d'une partie
│   │   DATEMODIF: 11150647  CODELINE: 120
│   ├── point.dart              # Coordonnées 2D
│   │   DATEMODIF: 11150647  CODELINE: 18
│   └── app_settings.dart       # Paramètres de l'application + Duel
│       DATEMODIF: 11290000  CODELINE: 348
│
├── database/                    # Base de données locale
│   ├── settings_database.dart  # Drift database pour settings
│   │   DATEMODIF: -  CODELINE: 56
│   └── settings_database.g.dart # Code généré
│
├── data/                        # Repositories
│   └── solution_database.dart  # Base de données solutions
│       DATEMODIF: -  CODELINE: 116
│
├── services/                    # Services
│   ├── solution_matcher.dart           # Comparaison solutions BigInt
│   │   DATEMODIF: 11230417  CODELINE: 167
│   ├── pentapol_solutions_loader.dart  # Chargement .bin → BigInt
│   │   DATEMODIF: -  CODELINE: 63
│   ├── plateau_solution_counter.dart   # Extension Plateau
│   │   DATEMODIF: -  CODELINE: 90
│   ├── pentomino_solver.dart          # Backtracking avec heuristiques
│   │   DATEMODIF: 11192114  CODELINE: 735
│   ├── isometry_transforms.dart       # Transformations géométriques
│   │   DATEMODIF: 11200617  CODELINE: 66
│   └── shape_recognizer.dart          # Reconnaissance de formes
│       DATEMODIF: 11200618  CODELINE: 60
│
├── providers/                   # Gestion d'état Riverpod
│   ├── pentomino_game_provider.dart   # Logique jeu unifié + tutorial
│   │   DATEMODIF: 11270851  CODELINE: 1578
│   ├── pentomino_game_state.dart      # État jeu
│   │   DATEMODIF: 11270850  CODELINE: 240
│   └── settings_provider.dart         # Paramètres utilisateur + Duel
│       DATEMODIF: 11290000  CODELINE: 190
│
├── screens/                     # Interfaces utilisateur
│   ├── home_screen.dart               # Menu principal
│   │   DATEMODIF: 12010100  CODELINE: 280
│   ├── pentomino_game_screen.dart     # Jeu interactif (orchestrateur)
│   │   DATEMODIF: 11280712  CODELINE: 322
│   │
│   ├── pentomino_game/                # Structure modulaire ✅
│   │   ├── utils/                     # Utilitaires
│   │   │   ├── game_constants.dart    # Constantes du jeu
│   │   │   │   DATEMODIF: 11180509  CODELINE: 27
│   │   │   ├── game_colors.dart       # Palette de couleurs
│   │   │   │   DATEMODIF: 11180612  CODELINE: 66
│   │   │   └── game_utils.dart        # Export centralisé
│   │   │       DATEMODIF: 11180611  CODELINE: 4
│   │   │
│   │   └── widgets/                   # Widgets modulaires
│   │       ├── shared/                # Partagés entre modes
│   │       │   ├── piece_renderer.dart          # Affichage pièce
│   │       │   │   DATEMODIF: 11191843  CODELINE: 108
│   │       │   ├── draggable_piece_widget.dart  # Drag & drop
│   │       │   │   DATEMODIF: 11240854  CODELINE: 134
│   │       │   ├── piece_border_calculator.dart # Bordures
│   │       │   │   DATEMODIF: 11191843  CODELINE: 88
│   │       │   ├── action_slider.dart           # Actions paysage
│   │       │   │   DATEMODIF: 11241645  CODELINE: 287
│   │       │   └── game_board.dart              # Plateau de jeu
│   │       │       DATEMODIF: 11261507  CODELINE: 388
│   │       │
│   │       └── game_mode/             # Mode jeu normal
│   │           └── piece_slider.dart  # Slider pièces
│   │               DATEMODIF: 11271509  CODELINE: 176
│   │
│   ├── solutions_browser_screen.dart  # Navigateur solutions
│   │   DATEMODIF: -  CODELINE: 402
│   ├── solutions_viewer_screen.dart   # Visualisation solutions
│   │   DATEMODIF: -  CODELINE: 197
│   ├── settings_screen.dart           # Paramètres
│   │   DATEMODIF: 11270936  CODELINE: 386
│   └── custom_colors_screen.dart      # Personnalisation couleurs
│       DATEMODIF: -  CODELINE: 144
│
├── duel/                        # 🎮 Mode Duel (NOUVEAU!)
│   ├── duel.dart                # Point d'entrée module
│   │
│   ├── models/                  # Modèles de données
│   │   ├── duel_state.dart      # État du duel
│   │   └── duel_player.dart     # Joueur
│   │
│   ├── providers/               # Provider Riverpod
│   │   └── duel_provider.dart   # Gestion état duel
│   │
│   ├── screens/                 # Écrans du mode Duel
│   │   ├── duel_create_screen.dart   # Créer une partie
│   │   │   DATEMODIF: 11290000  CODELINE: 150
│   │   ├── duel_join_screen.dart     # Rejoindre une partie
│   │   │   DATEMODIF: 11290000  CODELINE: 183
│   │   ├── duel_game_screen.dart     # Jeu en temps réel
│   │   │   DATEMODIF: 11290000  CODELINE: 986
│   │   ├── duel_waiting_screen.dart  # Attente adversaire
│   │   ├── duel_result_screen.dart   # Résultats
│   │   └── duel_lobby_screen.dart    # Lobby principal
│   │
│   ├── services/                # Services
│   │   └── duel_validator.dart  # Validation placements
│   │
│   └── widgets/                 # Widgets UI
│       ├── duel_countdown.dart  # Compte à rebours
│       ├── duel_player_card.dart # Carte joueur
│       └── duel_timer.dart      # Timer de partie
│
├── tutorial/                    # 🎓 Système de tutoriel (NOUVEAU!)
│   ├── tutorial.dart           # Point d'entrée module
│   │   DATEMODIF: 11251401  CODELINE: 16
│   │
│   ├── models/                 # Modèles de données
│   │   ├── scratch_command.dart      # Commande type Scratch
│   │   │   DATEMODIF: 11251401  CODELINE: 59
│   │   ├── tutorial_context.dart     # Contexte d'exécution
│   │   │   DATEMODIF: 11251436  CODELINE: 70
│   │   ├── tutorial_script.dart      # Script YAML parsé
│   │   │   DATEMODIF: 11271020  CODELINE: 94
│   │   └── tutorial_state.dart       # État tutoriel
│   │       DATEMODIF: 11271533  CODELINE: 93
│   │
│   ├── parser/                 # Parseur YAML
│   │   └── yaml_parser.dart   # Parse YAML → TutorialScript
│   │       DATEMODIF: 11280725  CODELINE: 180
│   │
│   ├── interpreter/            # Interpréteur de commandes
│   │   └── scratch_interpreter.dart  # Exécute les commandes
│   │       DATEMODIF: 11260400  CODELINE: 137
│   │
│   ├── commands/               # 29 commandes Phase 1 ✅
│   │   ├── commands.dart              # Export centralisé
│   │   │   DATEMODIF: 11280726  CODELINE: 20
│   │   ├── control_commands.dart      # WAIT, LOOP, IF, etc.
│   │   │   DATEMODIF: 11271033  CODELINE: 82
│   │   ├── message_commands.dart      # SHOW_MESSAGE, CLEAR_MESSAGE
│   │   │   DATEMODIF: 11261335  CODELINE: 52
│   │   ├── selection_commands.dart    # SELECT_PIECE, etc.
│   │   │   DATEMODIF: 11271027  CODELINE: 150
│   │   ├── placement_commands.dart    # PLACE_PIECE, REMOVE_PIECE
│   │   │   DATEMODIF: 11260521  CODELINE: 53
│   │   ├── transform_commands.dart    # ROTATE, MIRROR, etc.
│   │   │   DATEMODIF: 11271049  CODELINE: 138
│   │   ├── translate_command.dart     # TRANSLATE (déplacement animé)
│   │   │   DATEMODIF: 11280702  CODELINE: 204
│   │   ├── highlight_commands.dart    # HIGHLIGHT_CELL, etc.
│   │   │   DATEMODIF: 11280721  CODELINE: 208
│   │   ├── highlight_isometry_icon.dart # HIGHLIGHT_ISOMETRY_ICON
│   │   │   DATEMODIF: 11270953  CODELINE: 69
│   │   ├── board_selection_commands.dart # SELECT_PIECE_ON_BOARD
│   │   │   DATEMODIF: 11251649  CODELINE: 104
│   │   └── tutorial_mode_commands.dart # ENTER/EXIT_TUTORIAL_MODE
│   │       DATEMODIF: 11251434  CODELINE: 69
│   │
│   ├── providers/              # Provider Riverpod
│   │   └── tutorial_provider.dart    # Gestion état tutoriel
│   │       DATEMODIF: 11271551  CODELINE: 241
│   │
│   ├── widgets/                # Widgets UI
│   │   ├── tutorial_overlay.dart     # Overlay messages + highlights
│   │   │   DATEMODIF: 11280611  CODELINE: 159
│   │   ├── tutorial_controls.dart    # Contrôles play/pause/stop
│   │   │   DATEMODIF: 11271529  CODELINE: 204
│   │   └── highlighted_icon_button.dart # IconButton avec highlight
│   │       DATEMODIF: 11270853  CODELINE: 73
│   │
│   └── examples/               # Scripts d'exemple
│       └── 01_intro_basics.yaml      # Tutorial d'introduction
│
├── utils/                       # Utilitaires
│   ├── time_format.dart        # Formatage temps
│   │   DATEMODIF: -  CODELINE: 10
│   ├── pentomino_geometry.dart # Géométrie pentominos
│   │   DATEMODIF: -  CODELINE: 98
│   ├── piece_utils.dart        # Utilitaires pièces
│   │   DATEMODIF: 11191843  CODELINE: 202
│   ├── plateau_compressor.dart # Compression plateau
│   │   DATEMODIF: -  CODELINE: 155
│   ├── solution_collector.dart # Collection solutions
│   │   DATEMODIF: -  CODELINE: 100
│   └── solution_exporter.dart  # Export solutions
│       DATEMODIF: -  CODELINE: 150
│
└── tools/                       # Outils de génération
    └── generate_6x10_solutions.dart  # Générateur solutions
        DATEMODIF: -  CODELINE: 257
```

---

## 📦 Modèles de données

### 1. `pentominos.dart` - Les 12 pièces
**DATEMODIF:** 11200721 | **CODELINE:** 413

Définit les 12 pièces de pentomino avec toutes leurs rotations/symétries.

**Structure `Pento`** :
```dart
class Pento {
  final int id;              // 1-12
  final int size;            // Toujours 5 (pentomino)
  final int numPositions;    // 1-8 (selon symétries)
  final List<int> baseShape; // Forme de base (numéros 1-25 sur grille 5×5)
  final List<List<int>> positions; // Toutes rotations/symétries
  final int bit6;            // Code unique 6 bits (1-12)
}
```

**Ordre des pièces** (trié par nb de positions, pour optimiser le solver) :
- Pièce 1 : 1 position (croix symétrique)
- Pièce 12 : 2 positions (ligne droite)
- Pièces 3,6,7,10,11 : 4 positions
- Pièces 2,4,5,8,9 : 8 positions

---

### 2. `plateau.dart` - Grille de jeu
**DATEMODIF:** 11191843 | **CODELINE:** 77

Représente une grille 6×10 (ou dimension variable).

**Structure `Plateau`** :
```dart
class Plateau {
  final int width;   // 6
  final int height;  // 10
  List<List<int>> grid; // -1=caché, 0=libre, 1-12=pièce
  
  // Factories
  Plateau.empty(int w, int h);       // Tout caché
  Plateau.allVisible(int w, int h);  // Tout visible
  
  // Méthodes
  int getCell(int x, int y);
  void setCell(int x, int y, int value);
  Plateau copy();
  int get numVisibleCells;
  int get numFreeCells;
}
```

---

### 3. `bigint_plateau.dart` - Encodage BigInt
**DATEMODIF:** 11150647 | **CODELINE:** 95

Version optimisée du plateau encodée sur 360 bits (60 cases × 6 bits).

**Encodage** :
- Chaque case = 6 bits (codes 1-12 pour les pièces)
- Case 0 → bits 354-359
- Case 59 → bits 0-5
- Total : 360 bits (45 octets)

---

### 4. `app_settings.dart` - Paramètres application
**DATEMODIF:** 11290000 | **CODELINE:** 348

**Structure `AppSettings`** :
```dart
class AppSettings {
  final UISettings ui;           // Paramètres UI (couleurs, animations, etc.)
  final GameSettings game;       // Paramètres de jeu (difficulté, indices, etc.)
  final DuelSettings duel;       // Paramètres Duel (nom du joueur) 🆕
  
  // Méthodes
  AppSettings copyWith({...});
  Map<String, dynamic> toJson();
  factory AppSettings.fromJson(Map<String, dynamic> json);
}

class DuelSettings {
  final String? playerName;      // Nom du joueur sauvegardé
  
  DuelSettings copyWith({...});
  Map<String, dynamic> toJson();
  factory DuelSettings.fromJson(Map<String, dynamic> json);
}
```

---

## ⚙️ Services

### 1. `solution_matcher.dart` - Comparaison solutions BigInt
**DATEMODIF:** 11230417 | **CODELINE:** 167

Service central pour comparer un plateau avec les 2339 solutions canoniques.

**Transformations générées** :
Pour chaque solution canonique (2339), on génère 4 variantes :
1. Identité
2. Rotation 180°
3. Miroir horizontal
4. Miroir vertical

Total : 2339 × 4 = 9356 solutions

---

### 2. `pentomino_solver.dart` - Backtracking
**DATEMODIF:** 11192114 | **CODELINE:** 735

Algorithme de résolution par backtracking avec heuristiques avancées.

**Optimisations** :
1. **Timeout 30s** : Évite blocages infinis
2. **Détection zones isolées** : Élagage précoce
3. **Flood fill** : Détecte régions impossibles
4. **Ordre fixe des pièces** : Reproductibilité

---

### 3. `isometry_transforms.dart` - Transformations géométriques
**DATEMODIF:** 11200617 | **CODELINE:** 66

Service pour appliquer des transformations isométriques (rotation, miroir) sur le plateau.

**Fonctions principales** :
```dart
// Rotation 90° horaire
Plateau rotateClockwise(Plateau plateau);

// Rotation 90° anti-horaire
Plateau rotateCounterClockwise(Plateau plateau);

// Miroir horizontal
Plateau mirrorHorizontal(Plateau plateau);

// Miroir vertical
Plateau mirrorVertical(Plateau plateau);
```

---

## 📱 Écrans

### 1. `pentomino_game_screen.dart` - Jeu interactif (REFACTORÉ ✅)
**DATEMODIF:** 11280712 | **CODELINE:** 322

Interface de jeu complète avec **2 modes auto-détectés** + **intégration tutoriel** :

#### **Mode Jeu** (placement de pièces)
- ✅ Drag & drop des pièces depuis slider
- ✅ Rotation (double-tap ou bouton)
- ✅ Placement avec validation visuelle
- ✅ Déplacement pièces déjà placées
- ✅ Retrait pièce (long-press)
- ✅ Undo/Reset
- ✅ Haptic feedback
- ✅ Scroll infini dans slider
- ✅ Message victoire

#### **Mode Isométries** (transformations)
- ✅ Rotation horaire/anti-horaire
- ✅ Miroir horizontal/vertical
- ✅ Action slider en mode paysage
- ✅ Boutons d'action en mode portrait
- ✅ Détection automatique du mode selon sélection

#### **Mode Tutoriel** (guidage interactif) 🎓
- ✅ Overlay avec messages et highlights
- ✅ Contrôles play/pause/stop
- ✅ Barre de progression
- ✅ Sauvegarde/restauration état du jeu
- ✅ Highlights sur pièces, cellules et boutons
- ✅ Exécution pas-à-pas des scripts YAML

**Architecture modulaire** :
```dart
class PentominoGameScreen extends ConsumerStatefulWidget {
  // Orchestrateur principal (320 lignes)
  
  // Composants extraits :
  Widget _buildGameBoard();      // → GameBoard widget
  Widget _buildPieceSlider();    // → PieceSlider widget
  Widget _buildActionSlider();   // → ActionSlider widget
}
```

**Widgets extraits** :
- `GameBoard` : Plateau de jeu avec DragTarget (388 lignes)
- `PieceSlider` : Slider horizontal pièces (176 lignes)
- `ActionSlider` : Slider actions (287 lignes)
- `PieceRenderer` : Affichage pièce (108 lignes)
- `DraggablePieceWidget` : Gestion gestures (134 lignes)
- `PieceBorderCalculator` : Calcul bordures (88 lignes)

---

### 2. `settings_screen.dart` - Paramètres
**DATEMODIF:** 11270936 | **CODELINE:** 386

Écran de configuration de l'application.

**Fonctionnalités** :
- ✅ Afficher/masquer compteur de solutions
- ✅ Activer/désactiver haptic feedback
- ✅ Afficher/masquer numéros de pièces
- ✅ Personnaliser couleurs des pièces
- ✅ Réinitialiser paramètres
- ✅ **Lancer les tutoriels** 🎓

---

## 🔄 Providers (Riverpod)

### 1. `pentomino_game_provider.dart` - Logique jeu unifiée
**DATEMODIF:** 11270851 | **CODELINE:** 1578 ⚡

**Notifier** :
```dart
class PentominoGameNotifier extends Notifier<PentominoGameState> {
  // Gestion générale
  void reset();
  void undo();
  
  // Mode Jeu
  void selectPiece(int? pieceIndex);
  void selectPlacedPiece(int? index);
  void cycleOrientation();
  void tryPlacePiece(int gridX, int gridY);
  void removePlacedPiece(int index);
  void updatePreview(int? gridX, int? gridY);
  void clearPreview();
  
  // Mode Isométries
  void rotateClockwise();
  void rotateCounterClockwise();
  void mirrorHorizontal();
  void mirrorVertical();
  
  // 🎓 Mode Tutoriel (NOUVEAU!)
  void enterTutorialMode();
  void exitTutorialMode({bool restore = true});
  void setTutorialHighlights(Map<String, dynamic> highlights);
  void clearTutorialHighlights();
  void setTutorialMessage(String? message);
  
  // Utilitaires
  int? getPlacedPieceAt(int gridX, int gridY);
  bool canPlacePiece(int pieceIndex, int gridX, int gridY);
}
```

---

### 2. `pentomino_game_state.dart` - État jeu
**DATEMODIF:** 11270850 | **CODELINE:** 240

**Structure** :
```dart
class PentominoGameState {
  final Plateau plateau;
  final List<Pento> availablePieces;
  final List<PlacedPiece> placedPieces;
  
  // Mode Jeu
  final int? selectedPiece;
  final int? selectedPlacedPiece;
  final int selectedOrientation;
  final Map<int, int> pieceOrientations;
  final Point? referenceCellInPiece;
  final int? previewX, previewY;
  final bool isPreviewValid;
  
  // 🎓 Mode Tutoriel (NOUVEAU!)
  final bool isTutorialMode;
  final Map<String, dynamic> tutorialHighlights;
  final String? tutorialMessage;
  
  // Historique
  final List<PentominoGameState> history;
  
  factory PentominoGameState.initial();
  PentominoGameState copyWith({...});
  bool canPlacePiece(int pieceIndex, int gridX, int gridY);
  bool get isCompleted;
}
```

---

### 3. `tutorial_provider.dart` - Gestion tutoriels 🎓
**DATEMODIF:** 11271551 | **CODELINE:** 241

**Notifier** :
```dart
class TutorialNotifier extends Notifier<TutorialState> {
  // Chargement de scripts
  void loadScript(TutorialScript script);
  void unloadScript();
  
  // Exécution
  Future<void> start();
  void pause();
  void resume();
  void stop();
  
  // Navigation
  void nextStep();
  void previousStep();
  void goToStep(int step);
  
  // Utilitaires
  Future<TutorialScript?> loadScriptFromYaml(String yamlContent);
  Future<TutorialScript?> loadScriptFromAsset(String assetPath);
}
```

---

## 🎲 Système de solutions

### Architecture globale

```
┌─────────────────────────────────────────────────────────────┐
│                         DÉMARRAGE APP                        │
│                                                              │
│  1. loadNormalizedSolutionsAsBigInt()                       │
│     └─> Charge assets/data/solutions_6x10_normalisees.bin  │
│         └─> 2339 solutions canoniques (45 octets chacune)  │
│                                                              │
│  2. solutionMatcher.initWithBigIntSolutions(solutions)      │
│     └─> Génère 4 transformations par solution              │
│         ├─> Identité                                        │
│         ├─> Rotation 180°                                   │
│         ├─> Miroir horizontal                               │
│         └─> Miroir vertical                                 │
│     └─> Résultat : ~9356 solutions BigInt en mémoire       │
└─────────────────────────────────────────────────────────────┘
```

### Format BigInt (360 bits)

```
┌────────────────────────────────────────────────┐
│  Grille 6×10 = 60 cases                       │
│  Chaque case = 6 bits (codes 1-12)           │
│  Total = 60 × 6 = 360 bits                    │
│                                                │
│  Case 0  (y=0, x=0) → bits 354-359           │
│  Case 1  (y=0, x=1) → bits 348-353           │
│  ...                                           │
│  Case 59 (y=9, x=5) → bits 0-5               │
└────────────────────────────────────────────────┘
```

---

## 🎓 Système de tutoriel

### Vue d'ensemble

Le système de tutoriel est un **moteur de scripting interactif** inspiré de Scratch, permettant de créer des tutoriels guidés pour apprendre à utiliser Pentapol.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SYSTÈME DE TUTORIEL                       │
│                                                              │
│  1. Script YAML                                             │
│     └─> Fichier .yaml avec commandes type Scratch          │
│         └─> Exemple: 01_intro_basics.yaml                  │
│                                                              │
│  2. Parser YAML                                             │
│     └─> Convertit YAML → TutorialScript                    │
│         └─> Validation et parsing des commandes            │
│                                                              │
│  3. Interpréteur                                            │
│     └─> Exécute les commandes une par une                  │
│         └─> Gère l'état et le contexte                     │
│                                                              │
│  4. Commandes (28 Phase 1)                                  │
│     ├─> Contrôle: WAIT, LOOP, IF, GOTO                     │
│     ├─> Messages: SHOW_MESSAGE, CLEAR_MESSAGE              │
│     ├─> Sélection: SELECT_PIECE, SELECT_PLACED_PIECE       │
│     ├─> Placement: PLACE_PIECE, REMOVE_PIECE               │
│     ├─> Transformation: ROTATE, MIRROR                      │
│     ├─> Highlights: HIGHLIGHT_CELL, HIGHLIGHT_PIECE        │
│     └─> Mode: ENTER_TUTORIAL_MODE, EXIT_TUTORIAL_MODE      │
│                                                              │
│  5. UI Overlay                                              │
│     ├─> Messages flottants                                 │
│     ├─> Highlights visuels (cellules, pièces, boutons)     │
│     ├─> Contrôles (play/pause/stop)                        │
│     └─> Barre de progression                               │
└─────────────────────────────────────────────────────────────┘
```

### Format de script YAML

```yaml
id: intro_basics
name: "Introduction - Les bases"
description: "Découvrez comment placer votre première pièce"
difficulty: beginner
estimatedDuration: 120
tags:
  - introduction
  - placement

steps:
  - command: ENTER_TUTORIAL_MODE
  
  - command: SHOW_MESSAGE
    params:
      text: "Bienvenue dans Pentapol !"
  
  - command: WAIT
    params:
      duration: 2000
  
  - command: SELECT_PIECE_FROM_SLIDER
    params:
      pieceNumber: 5
  
  - command: PLACE_SELECTED_PIECE_AT
    params:
      gridX: 2
      gridY: 4
  
  - command: EXIT_TUTORIAL_MODE
    params:
      restore: true
```

### 29 Commandes Phase 1 ✅

#### **Contrôle de flux**
1. `WAIT` - Pause (durée en ms)
2. `LOOP` - Boucle (count + steps)
3. `IF` - Condition (condition + thenSteps + elseSteps)
4. `GOTO` - Saut à une étape

#### **Messages**
5. `SHOW_MESSAGE` - Afficher message
6. `CLEAR_MESSAGE` - Effacer message

#### **Sélection**
7. `SELECT_PIECE_FROM_SLIDER` - Sélectionner pièce dans slider
8. `DESELECT_PIECE` - Désélectionner pièce
9. `SELECT_PIECE_ON_BOARD_AT` - Sélectionner pièce placée
10. `DESELECT_PLACED_PIECE` - Désélectionner pièce placée
11. `SCROLL_SLIDER_TO_PIECE` - Scroller vers pièce

#### **Placement**
12. `PLACE_SELECTED_PIECE_AT` - Placer pièce sélectionnée
13. `REMOVE_PIECE_AT` - Retirer pièce à position
14. `REMOVE_SELECTED_PLACED_PIECE` - Retirer pièce sélectionnée

#### **Transformation**
15. `CYCLE_ORIENTATION` - Changer orientation
16. `ROTATE_CLOCKWISE` - Rotation horaire plateau
17. `ROTATE_COUNTER_CLOCKWISE` - Rotation anti-horaire plateau
18. `MIRROR_HORIZONTAL` - Miroir horizontal plateau
19. `MIRROR_VERTICAL` - Miroir vertical plateau
20. `ROTATE_AROUND_MASTER` - Rotation autour mastercase

#### **Translation** 🆕
21. `TRANSLATE` - Déplacer une pièce vers une nouvelle position (avec animation optionnelle)

#### **Highlights**
22. `HIGHLIGHT_CELL` - Highlight cellule
23. `HIGHLIGHT_PIECE_IN_SLIDER` - Highlight pièce slider
24. `HIGHLIGHT_PLACED_PIECE_AT` - Highlight pièce placée
25. `HIGHLIGHT_ISOMETRY_ICON` - Highlight icône isométrie
26. `CLEAR_HIGHLIGHTS` - Effacer highlights
27. `CLEAR_SLIDER_HIGHLIGHT` - Effacer highlight slider

#### **Mode tutoriel**
28. `ENTER_TUTORIAL_MODE` - Entrer en mode tutoriel
29. `EXIT_TUTORIAL_MODE` - Sortir du mode tutoriel

### Commande TRANSLATE (Nouvelle! 🆕)

La commande `TRANSLATE` permet de déplacer une pièce déjà placée vers une nouvelle position.

**Paramètres** :
- `pieceNumber` : Numéro de la pièce à déplacer (1-12)
- `toX`, `toY` : Position finale de la mastercase
- `duration` : Durée de l'animation en ms (défaut: 500)
- `animated` : Si `true`, anime le déplacement case par case (défaut: `false`)

**Modes** :
1. **Mode direct** (`animated: false`) : Saut instantané vers la position finale
2. **Mode animé** (`animated: true`) : Déplacement progressif case par case avec interpolation linéaire

**Exemple YAML** :
```yaml
# Translation directe
- command: TRANSLATE
  params:
    pieceNumber: 5
    toX: 3
    toY: 7
    duration: 800

# Translation animée (case par case)
- command: TRANSLATE
  params:
    pieceNumber: 5
    toX: 3
    toY: 7
    duration: 1500
    animated: true
```

**Algorithme d'animation** :
- Calcul de la distance de Manhattan (|dx| + |dy|)
- Interpolation linéaire pour un mouvement diagonal fluide
- Déplacement progressif avec préservation de l'orientation
- Durée répartie équitablement entre les étapes

### Widgets tutoriel

#### `TutorialOverlay`
**DATEMODIF:** 11280611 | **CODELINE:** 159

Overlay transparent qui affiche :
- Messages flottants avec animation
- Highlights sur cellules (couleur personnalisable)
- Highlights sur pièces dans slider
- Highlights sur boutons d'action

#### `TutorialControls`
**DATEMODIF:** 11271529 | **CODELINE:** 204

Barre de contrôle en bas de l'écran :
- Bouton Play/Pause
- Bouton Stop
- Barre de progression
- Compteur d'étapes (X / Y)
- Nom du script

#### `HighlightedIconButton`
**DATEMODIF:** 11270853 | **CODELINE:** 73

IconButton avec effet de highlight pulsant :
- Animation de pulsation
- Couleur personnalisable
- Utilisé pour guider l'utilisateur

### Exemple de tutoriel

Le fichier `01_intro_basics.yaml` est un tutoriel complet qui :
1. Entre en mode tutoriel
2. Présente le slider de pièces
3. Sélectionne la pièce n°5 (le T)
4. La place sur le plateau en (2, 4)
5. Démontre la rotation autour de la mastercase
6. Sort du mode tutoriel en restaurant l'état

---

## 🎮 Système de Duel

### Vue d'ensemble

Le système de Duel permet à deux joueurs de s'affronter en temps réel pour compléter une même solution de pentominos. Le premier joueur à placer toutes ses pièces correctement remporte la partie.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SYSTÈME DE DUEL                           │
│                                                              │
│  1. Création de partie                                      │
│     └─> Joueur 1 crée une room avec code unique (4 char)   │
│         └─> Nom sauvegardé dans SQLite (DuelSettings)      │
│                                                              │
│  2. Attente adversaire                                      │
│     └─> Affichage du code de la room                       │
│         └─> Écoute des connexions via Supabase             │
│                                                              │
│  3. Rejoindre une partie                                    │
│     └─> Joueur 2 entre le code de la room                  │
│         └─> Nom sauvegardé dans SQLite                     │
│                                                              │
│  4. Jeu en temps réel                                       │
│     ├─> Solution commune chargée depuis la base            │
│     ├─> Overlay guide avec la solution                     │
│     ├─> Validation des placements                          │
│     ├─> Synchronisation via Supabase Realtime              │
│     ├─> Hachures pour les pièces adversaires               │
│     ├─> Isométries sur pièces sélectionnées                │
│     └─> Timer de 3 minutes                                 │
│                                                              │
│  5. Résultats                                               │
│     └─> Affichage du gagnant et des scores                 │
└─────────────────────────────────────────────────────────────┘
```

### Fonctionnalités principales

#### **Création et gestion de parties**
- ✅ Code unique de 4 caractères (alphanumériques)
- ✅ Sauvegarde automatique du nom du joueur via SQLite
- ✅ Attente de l'adversaire avec affichage du code
- ✅ Annulation possible avant le début

#### **Jeu en temps réel**
- ✅ Solution commune affichée en overlay (guide atténué)
- ✅ Validation stricte des placements (position + orientation)
- ✅ Synchronisation instantanée via Supabase Realtime
- ✅ Distinction visuelle : pièces du joueur (éclatantes) vs adversaire (hachurées)
- ✅ Isométries complètes sur pièces sélectionnées (rotation, miroirs)
- ✅ Timer de 3 minutes avec changement de couleur (vert → orange → rouge)
- ✅ Compteur de pièces placées dans le titre

#### **Interface utilisateur**
- ✅ Slider infini avec toutes les pièces disponibles
- ✅ Drag & drop pour placer les pièces
- ✅ Double-tap sur une pièce = placement automatique
- ✅ Tap sur le guide = placement si pièce sélectionnée correspond
- ✅ Barre d'isométries visible quand une pièce est sélectionnée
- ✅ Haptic feedback pour toutes les interactions
- ✅ Messages d'erreur contextuels

### Écrans du mode Duel

#### 1. `duel_create_screen.dart` - Création de partie
**DATEMODIF:** 11290000 | **CODELINE:** 150

Permet au joueur 1 de créer une nouvelle partie :
- Champ de saisie du pseudo (sauvegardé dans SQLite)
- Affichage du dernier pseudo utilisé
- Validation (minimum 2 caractères)
- Création de la room avec code unique

#### 2. `duel_join_screen.dart` - Rejoindre une partie
**DATEMODIF:** 11290000 | **CODELINE:** 183

Permet au joueur 2 de rejoindre une partie existante :
- Champ de saisie du code (4 caractères, auto-majuscules)
- Champ de saisie du pseudo (sauvegardé dans SQLite)
- Validation et connexion à la room

#### 3. `duel_game_screen.dart` - Jeu en temps réel
**DATEMODIF:** 11290000 | **CODELINE:** 986

Interface de jeu complète avec :
- **Plateau de jeu** : Grille 6×10 avec overlay solution
- **Slider de pièces** : Scroll infini avec pièces disponibles
- **Barre d'isométries** : 4 boutons (rotation ↺↻, miroirs ↔↕)
- **Timer** : Compte à rebours de 3 minutes
- **Score** : Format "ADVERSAIRE = X • 1:20 • MOI = Y"

**Système de couleurs** :
- **Guide solution** : Couleurs atténuées (opacité 0.35)
- **Pièces placées (moi)** : Couleurs éclatantes + numéro blanc
- **Pièces placées (adversaire)** : Couleurs éclatantes + hachures diagonales + numéro blanc
- **Preview** : Couleur avec bordure verte (valide) ou orange (invalide)

**Validation des placements** :
```dart
DuelValidator.instance.validatePlacement(
  pieceId: pieceId,
  x: x,
  y: y,
  orientation: orientation,
);
```

Vérifie :
1. Position et orientation exactes par rapport à la solution
2. Pas de collision avec d'autres pièces
3. Pièce dans les limites du plateau

#### 4. `duel_waiting_screen.dart` - Attente adversaire

Affiche le code de la room en grand et attend la connexion du joueur 2.

#### 5. `duel_result_screen.dart` - Résultats

Affiche le gagnant, les scores finaux et permet de rejouer ou retourner au lobby.

### Services

#### `duel_validator.dart` - Validation des placements

Service singleton qui :
- Charge et décode la solution de référence
- Valide chaque placement (position + orientation)
- Détecte les collisions
- Vérifie les limites du plateau

**Méthodes principales** :
```dart
class DuelValidator {
  // Initialiser avec toutes les solutions
  void initialize(List<BigInt> allSolutions);
  
  // Charger une solution spécifique
  Future<bool> loadSolution(int solutionId);
  
  // Valider un placement
  ValidationResult validatePlacement({
    required int pieceId,
    required int x,
    required int y,
    required int orientation,
  });
}
```

### Providers

#### `duel_provider.dart` - Gestion de l'état

Provider Riverpod qui gère :
- Création et connexion aux rooms
- Synchronisation en temps réel via Supabase
- Placement des pièces
- Gestion du timer
- Détection de la fin de partie

**État `DuelState`** :
```dart
class DuelState {
  final String? roomCode;
  final int? solutionId;
  final DuelPlayer? localPlayer;
  final DuelPlayer? opponent;
  final List<DuelPlacedPiece> placedPieces;
  final DuelGameState gameState;
  final int? countdown;
  final int? timeRemaining;
  final int localScore;
  final int opponentScore;
  final String? errorMessage;
}
```

### Widgets

#### `duel_countdown.dart` - Compte à rebours

Affiche le compte à rebours avant le début de la partie (3, 2, 1, GO!).

#### `duel_player_card.dart` - Carte joueur

Affiche les informations d'un joueur (nom, score, statut).

#### `duel_timer.dart` - Timer de partie

Affiche le temps restant avec changement de couleur selon l'urgence.

### Intégration avec AppSettings

Le nom du joueur est sauvegardé dans `DuelSettings` :

```dart
// Sauvegarder le nom
await ref.read(settingsProvider.notifier).setDuelPlayerName(name);

// Récupérer le nom
final savedName = ref.read(settingsProvider).duel.playerName;
```

Cela permet de pré-remplir le champ de nom lors des prochaines parties.

### Flux de jeu complet

```
1. Joueur 1 crée une partie
   └─> Génération code unique (ex: AB12)
   └─> Attente sur DuelWaitingScreen

2. Joueur 2 rejoint avec le code
   └─> Connexion à la room
   └─> Transition vers DuelGameScreen pour les deux

3. Compte à rebours (3, 2, 1, GO!)
   └─> Chargement de la solution commune

4. Jeu en temps réel
   ├─> Placement des pièces
   ├─> Validation stricte
   ├─> Synchronisation instantanée
   └─> Timer de 3 minutes

5. Fin de partie (conditions)
   ├─> Un joueur complète toutes les pièces → Victoire
   ├─> Timer à 0 → Victoire du joueur avec le plus de pièces
   └─> Abandon → Victoire de l'adversaire

6. Écran de résultats
   └─> Affichage du gagnant et des scores
```

### Optimisations et bonnes pratiques

1. **Sauvegarde du nom** : Utilise SQLite via `SettingsProvider` pour persister le nom du joueur
2. **Validation stricte** : Chaque placement est validé côté client ET serveur
3. **Synchronisation temps réel** : Utilise Supabase Realtime pour la communication
4. **Distinction visuelle** : Hachures diagonales pour les pièces adversaires
5. **Guide solution** : Overlay atténué pour aider sans dévoiler complètement
6. **Isométries complètes** : Rotation et miroirs sur pièces sélectionnées
7. **Haptic feedback** : Retour tactile pour toutes les interactions importantes

---

## ⚙️ Configuration

### `main.dart` - Point d'entrée
**DATEMODIF:** 11151556 | **CODELINE:** 69

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Init Supabase (optionnel)
  try {
    await initSupabase();
  } catch (e) {
    debugPrint('⚠️ Erreur Supabase: $e');
  }
  
  // Pré-chargement solutions en arrière-plan
  Future.microtask(() async {
    final solutions = await loadNormalizedSolutionsAsBigInt();
    solutionMatcher.initWithBigIntSolutions(solutions);
    debugPrint('✅ ${solutionMatcher.totalSolutions} solutions');
  });
  
  runApp(const ProviderScope(child: MyApp()));
}
```

---

## 🔧 Réorganisation complète (Phase 1-2 terminée ✅)

### Objectif
Découper `pentomino_game_screen.dart` (1350+ lignes) en modules réutilisables et maintenables.

### Phase 1 : Utilitaires ✅ (18 nov 2025)
**Fichiers créés** :
- `game_constants.dart` - DATEMODIF: 11180509 | CODELINE: 27
- `game_colors.dart` - DATEMODIF: 11180612 | CODELINE: 66
- `game_utils.dart` - DATEMODIF: 11180611 | CODELINE: 4

### Phase 2 : Widgets ✅ (18-27 nov 2025)
**Fichiers créés** :
- `piece_renderer.dart` - DATEMODIF: 11191843 | CODELINE: 108
- `draggable_piece_widget.dart` - DATEMODIF: 11240854 | CODELINE: 134
- `piece_border_calculator.dart` - DATEMODIF: 11191843 | CODELINE: 88
- `action_slider.dart` - DATEMODIF: 11241645 | CODELINE: 287
- `game_board.dart` - DATEMODIF: 11261507 | CODELINE: 388
- `piece_slider.dart` - DATEMODIF: 11271509 | CODELINE: 176

### Phase 3 : Système de tutoriel ✅ (25-28 nov 2025) 🎓
**Module complet créé** :
- 29 commandes type Scratch (+ TRANSLATE 🆕)
- Parser YAML amélioré
- Interpréteur de commandes
- Provider Riverpod
- Widgets UI (overlay, contrôles, highlights)
- Script d'exemple

### Résultats
- **Avant** : 1350 lignes (monolithique)
- **Après** : 322 lignes (orchestrateur)
- **Gain** : -1028 lignes (-76%) 🎯
- **Imports** : Tous en absolu depuis `lib/`
- **Nouveau** : +2700 lignes de système de tutoriel

**Architecture finale** :
```
pentomino_game_screen.dart (322 lignes)
├── GameBoard (388 lignes)
├── PieceSlider (176 lignes) - Mode Jeu
├── ActionSlider (287 lignes) - Mode Isométries
├── TutorialOverlay (159 lignes) - Mode Tutoriel 🎓
└── Widgets partagés
    ├── PieceRenderer (108 lignes)
    ├── DraggablePieceWidget (134 lignes)
    └── PieceBorderCalculator (88 lignes)
```

### Améliorations apportées (28 nov 2025)
- ✅ **Détection automatique des modes** : Plus besoin de toggle manuel
- ✅ **Mode Isométries complet** : Rotation, miroirs avec UI adaptative
- ✅ **Extraction GameBoard** : Plateau de jeu complètement modulaire
- ✅ **Code ultra-propre** : Orchestrateur de 322 lignes seulement
- ✅ **Architecture scalable** : Facile d'ajouter de nouveaux modes
- ✅ **Système de tutoriel** : Moteur complet avec scripting YAML 🎓
- ✅ **Commande TRANSLATE** : Déplacement animé de pièces 🆕

---

## 📊 Index des fichiers

### Fichiers récemment modifiés (Novembre 2025)

| Fichier | DATEMODIF | CODELINE | Description |
|---------|-----------|----------|-------------|
| **DUEL** | | | |
| `duel_create_screen.dart` | 11290000 | 150 | Création de partie |
| `duel_join_screen.dart` | 11290000 | 183 | Rejoindre une partie |
| `duel_game_screen.dart` | 11290000 | 986 | Jeu en temps réel |
| `app_settings.dart` | 11290000 | 348 | Ajout DuelSettings |
| `settings_provider.dart` | 11290000 | 190 | Ajout setDuelPlayerName |
| **TUTORIEL** | | | |
| `commands.dart` | 11280726 | 20 | Export commandes |
| `yaml_parser.dart` | 11280725 | 180 | Parser YAML |
| `highlight_commands.dart` | 11280721 | 208 | Commandes highlights |
| `pentomino_game_screen.dart` | 11280712 | 322 | Orchestrateur + tutorial |
| `translate_command.dart` | 11280702 | 204 | Commande translation 🆕 |
| `tutorial_overlay.dart` | 11280611 | 159 | Overlay messages |
| `tutorial_provider.dart` | 11271551 | 241 | Provider tutoriel |
| `tutorial_state.dart` | 11271533 | 93 | État tutoriel |
| `tutorial_controls.dart` | 11271529 | 204 | Contrôles play/pause |
| `piece_slider.dart` | 11271509 | 176 | Slider pièces |
| `transform_commands.dart` | 11271049 | 138 | Commandes transformation |
| `control_commands.dart` | 11271033 | 82 | Commandes contrôle |
| `selection_commands.dart` | 11271027 | 150 | Commandes sélection |
| `tutorial_script.dart` | 11271020 | 94 | Script parsé |
| `highlight_isometry_icon.dart` | 11270953 | 69 | Highlight icône |
| `settings_screen.dart` | 11270936 | 386 | Écran paramètres |
| `highlighted_icon_button.dart` | 11270853 | 73 | IconButton highlight |
| `pentomino_game_provider.dart` | 11270851 | 1578 | Provider jeu + tutorial |
| `pentomino_game_state.dart` | 11270850 | 240 | État jeu + tutorial |
| **WIDGETS** | | | |
| `game_board.dart` | 11261507 | 388 | Plateau de jeu |
| `message_commands.dart` | 11261335 | 52 | Commandes messages |
| `placement_commands.dart` | 11260521 | 53 | Commandes placement |
| `scratch_interpreter.dart` | 11260400 | 137 | Interpréteur |
| `board_selection_commands.dart` | 11251649 | 104 | Sélection plateau |
| `tutorial_context.dart` | 11251436 | 70 | Contexte exécution |
| `tutorial_mode_commands.dart` | 11251434 | 69 | Mode tutoriel |
| `tutorial.dart` | 11251401 | 16 | Export module |
| `scratch_command.dart` | 11251401 | 59 | Modèle commande |
| `commands.dart` | 11251401 | 17 | Export commandes |
| `action_slider.dart` | 11241645 | 287 | Slider actions |
| `draggable_piece_widget.dart` | 11240854 | 134 | Drag & drop |
| **CORE** | | | |
| `solution_matcher.dart` | 11230417 | 167 | Comparaison solutions |
| `game_icons_config.dart` | 11231630 | 139 | Config icônes |
| `settings_provider.dart` | 11290000 | 190 | Provider paramètres + Duel |
| `app_settings.dart` | 11290000 | 348 | Modèle paramètres + Duel |
| `pentominos.dart` | 11200721 | 413 | 12 pièces |
| `shape_recognizer.dart` | 11200618 | 60 | Reconnaissance formes |
| `isometry_transforms.dart` | 11200617 | 66 | Transformations |
| `pentomino_solver.dart` | 11192114 | 735 | Solver backtracking |
| `piece_utils.dart` | 11191843 | 202 | Utilitaires pièces |
| `piece_renderer.dart` | 11191843 | 108 | Affichage pièce |
| `piece_border_calculator.dart` | 11191843 | 88 | Calcul bordures |
| `plateau.dart` | 11191843 | 77 | Grille de jeu |
| `game_colors.dart` | 11180612 | 66 | Palette couleurs |
| `game_utils.dart` | 11180611 | 4 | Export centralisé |
| `game_constants.dart` | 11180509 | 27 | Constantes jeu |

### Fichiers stables (Novembre 2025)

| Fichier | DATEMODIF | CODELINE | Description |
|---------|-----------|----------|-------------|
| `bigint_plateau.dart` | 11150647 | 95 | Plateau BigInt |
| `game_piece.dart` | 11150647 | 74 | Pièce interactive |
| `game.dart` | 11150647 | 120 | État partie |
| `point.dart` | 11150647 | 18 | Coordonnées 2D |
| `main.dart` | 11151556 | 69 | Point d'entrée |

---

## 📊 Statistiques

### Nombre de solutions

- **2 339** solutions canoniques (une par classe de symétrie)
- **9 356** solutions totales (avec 4 transformations)
- **45 octets** par solution dans le fichier .bin
- **105 KB** taille du fichier binaire

### Lignes de code (hors commentaires)

- **Total core** : ~5 200 lignes
- **Système tutoriel** : ~2 700 lignes 🎓
- **Système Duel** : ~1 500 lignes 🎮
- **Provider principal** : 1578 lignes (avec tutorial)
- **Duel game screen** : 986 lignes
- **Solver** : 735 lignes
- **Pentominos** : 413 lignes
- **Game board** : 388 lignes
- **Settings screen** : 386 lignes
- **App settings** : 348 lignes (avec Duel)
- **Orchestrateur** : 322 lignes
- **Commande TRANSLATE** : 204 lignes 🆕
- **Settings provider** : 190 lignes (avec Duel)

### Performances

- **Chargement solutions** : ~200-500ms
- **Génération transformations** : ~100-300ms
- **Comptage compatible** : ~10-50ms (pour 9356 solutions)
- **Transformation isométrique** : ~1-5ms
- **Exécution commande tutoriel** : ~1-10ms

---

## 🐛 Debugging

### Logs importants

```dart
// Dans main.dart
debugPrint('🔄 Pré-chargement des solutions...');
debugPrint('✅ $count solutions BigInt chargées en ${duration}ms');

// Dans solution_matcher.dart
debugPrint('[SOLUTION_MATCHER] ✓ ${_solutions.length} solutions générées');

// Dans pentomino_game_provider.dart
print('[GAME] Rotation horaire appliquée');
print('[GAME] Pièce ${pieceIndex} placée en ($gridX, $gridY)');

// Dans tutorial_provider.dart
print('[TUTORIAL] Chargement du script: ${script.name}');
print('[TUTORIAL] Exécution étape ${currentStep}/${totalSteps}');
print('[TUTORIAL] 💾 Sauvegarde de l\'état du jeu');
```

---

## 🚀 Prochaines étapes

### Court terme
- [x] Réorganisation pentomino_game Phase 1-2 (-76%)
- [x] Mode Isométries complet avec UI adaptative
- [x] Extraction complète GameBoard
- [x] Système de tutoriel Phase 1 (29 commandes) 🎓
- [x] Commande TRANSLATE avec animation 🆕
- [x] Mode Duel en temps réel 🎮
- [ ] Tutoriels supplémentaires (isométries, solutions, avancé)
- [ ] Animations pour transformations isométriques
- [ ] Sauvegarder/charger plateaux
- [ ] Améliorer UI mode Duel (animations, effets)

### Moyen terme
- [ ] Tutoriel Phase 2 : Commandes avancées (variables, conditions complexes)
- [ ] Mode challenge avec objectifs
- [ ] Statistiques et analytics
- [ ] Partage de configurations
- [ ] Améliorer UI navigateur solutions
- [ ] Classements et historique pour le mode Duel
- [ ] Mode Duel avec plusieurs rounds

### Long terme
- [ ] Générateur de puzzles avec difficulté
- [ ] Leaderboards et achievements globaux
- [ ] Support autres formats (non 6×10)
- [ ] Éditeur visuel de tutoriels
- [ ] Tournois en mode Duel

---

## 📝 Notes importantes

### ⚠️ Points d'attention

1. **Mémoire** : Les 9356 solutions BigInt occupent ~100KB en RAM
2. **Transformations** : Les isométries modifient le plateau entier
3. **Mode auto-détection** : Basé sur la présence de sélection (pièce ou placée)
4. **Orientation** : AppBar s'adapte automatiquement (portrait/paysage)
5. **Tutoriel** : Sauvegarde automatique de l'état du jeu avant démarrage
6. **Scripts YAML** : Validation stricte des commandes et paramètres
7. **Duel** : Validation stricte des placements (position + orientation exactes)
8. **Synchronisation** : Utilise Supabase Realtime pour le mode Duel
9. **Nom du joueur** : Sauvegardé dans SQLite via DuelSettings

### ✅ Bonnes pratiques

1. Toujours initialiser `solutionMatcher` au démarrage
2. Utiliser `copyWith()` pour l'immutabilité
3. Préférer `BigInt` pour les comparaisons (performances)
4. Ajouter logs pour debugging
5. Commenter les modifications avec dates (format DATEMODIF)
6. Compter les lignes de code hors commentaires (CODELINE)
7. **Tester les scripts de tutoriel avant déploiement**
8. **Valider les paramètres des commandes**
9. **Initialiser DuelValidator avec toutes les solutions**
10. **Sauvegarder le nom du joueur via SettingsProvider**
11. **Valider strictement les placements en mode Duel**

### 🔗 Liens utiles

- Flutter : https://flutter.dev
- Riverpod : https://riverpod.dev
- Supabase : https://supabase.com
- Pentominos : https://en.wikipedia.org/wiki/Pentomino
- YAML : https://yaml.org

---

**Dernière mise à jour : 1er décembre 2025**

**Mainteneur : Documentation générée automatiquement**

---

## 🔄 Changelog récent

### 1er décembre 2025
- ✅ **Suppression système Race** : Ancien système de courses multijoueur supprimé (obsolète)
- ✅ **Nouveau HomeScreen** : Menu principal moderne avec cartes visuelles
- ✅ **Simplification** : Navigation directe, suppression code mort (~534 lignes)
- ✅ **Un seul système multijoueur** : Mode Duel conservé (temps réel, 1v1)

**Format des métadonnées :**
- **DATEMODIF** : Format MMDDHHMM (Mois Jour Heure Minute)
- **CODELINE** : Nombre de lignes de code (hors commentaires et lignes vides)

---

## 🎉 Nouveautés majeures

### Version 29 novembre 2025 🎮

#### 🎮 Mode Duel (Nouveau!)
- **Jeu en temps réel** : Affrontez un adversaire pour compléter une solution
- **Code de partie** : Système de rooms avec codes uniques (4 caractères)
- **Sauvegarde du nom** : Nom du joueur persisté dans SQLite via DuelSettings
- **Overlay solution** : Guide visuel atténué pour aider les joueurs
- **Distinction visuelle** : Hachures diagonales pour les pièces adversaires
- **Isométries complètes** : Rotation et miroirs sur pièces sélectionnées
- **Validation stricte** : Position + orientation exactes requises
- **Timer de 3 minutes** : Avec changement de couleur selon l'urgence
- **Synchronisation Supabase** : Communication en temps réel via Realtime
- **~1500 lignes** de code pour le système complet

#### 🔧 Améliorations AppSettings
- **DuelSettings** : Nouvelle classe pour les paramètres du mode Duel
- **playerName** : Champ pour sauvegarder le nom du joueur
- **setDuelPlayerName()** : Méthode dans SettingsProvider
- **+51 lignes** dans app_settings.dart (297 → 348)
- **+34 lignes** dans settings_provider.dart (156 → 190)

### Version 28 novembre 2025 🆕

#### 🎯 Commande TRANSLATE (Nouvelle!)
- **Déplacement animé** de pièces déjà placées
- **2 modes** : direct (saut) ou animé (case par case)
- **Interpolation linéaire** pour mouvements diagonaux fluides
- **Préservation de l'orientation** pendant le déplacement
- **Algorithme de Manhattan** pour calcul de distance
- **204 lignes** de code optimisé

#### 🔧 Améliorations
- **Parser YAML** : +9 lignes (171 → 180)
- **Highlight commands** : +41 lignes (167 → 208)
- **Tutorial overlay** : Optimisé (-2 lignes)
- **Export centralisé** : Ajout de translate_command

### Version 27 novembre 2025

#### 🎓 Système de tutoriel complet
- **29 commandes Phase 1** type Scratch (+ TRANSLATE)
- **Parser YAML** pour scripts de tutoriel
- **Interpréteur** avec gestion d'état et contexte
- **Provider Riverpod** dédié
- **Widgets UI** : overlay, contrôles, highlights
- **Script d'exemple** : Introduction aux bases
- **Sauvegarde/restauration** automatique de l'état du jeu
- **Highlights visuels** sur cellules, pièces et boutons
- **Contrôles** : play/pause/stop avec barre de progression

#### 📈 Statistiques impressionnantes
- **+2700 lignes** de code pour le système de tutoriel
- **+1500 lignes** de code pour le système de Duel 🎮
- **Provider jeu** : 1578 lignes (avec intégration tutorial)
- **Architecture modulaire** : 76% de réduction du fichier principal
- **29 commandes** implémentées et testées
- **4 modes** : Jeu, Isométries, Tutoriel, Duel

#### 🏆 Qualité du code
- **Architecture propre** : Séparation claire des responsabilités
- **Réutilisabilité** : Widgets et commandes modulaires
- **Extensibilité** : Facile d'ajouter de nouvelles commandes
- **Documentation** : Tous les fichiers documentés
- **Tests** : Scripts de tutoriel validés
