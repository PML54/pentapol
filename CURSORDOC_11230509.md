# 📚 CURSORDOC - Documentation Technique Pentapol

**Application de puzzles pentominos en Flutter**

**Date de création : 14 novembre 2025**  
**Dernière mise à jour : 23 novembre 2025 05:09**

---

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [Modèles de données](#modèles-de-données)
4. [Services](#services)
5. [Écrans](#écrans)
6. [Providers (Riverpod)](#providers-riverpod)
7. [Système de solutions](#système-de-solutions)
8. [Configuration](#configuration)
9. [Réorganisation complète](#réorganisation-complète)
10. [Index des fichiers](#index-des-fichiers)

---

## 🎯 Vue d'ensemble

Pentapol est une application Flutter permettant de :
- Créer et éditer des plateaux de pentominos (grille 6×10)
- Résoudre automatiquement les puzzles
- Jouer interactivement avec drag & drop
- Naviguer dans une base de 2339 solutions canoniques (9356 avec transformations)
- Jouer avec deux modes : **Mode Jeu** (placement de pièces) et **Mode Isométries** (transformations géométriques)

### Technologies principales
- **Flutter** : Framework UI
- **Riverpod** : Gestion d'état
- **Supabase** : Backend (courses multijoueur)
- **BigInt** : Encodage solutions sur 360 bits (60 cases × 6 bits)
- **SQLite** : Base de données locale (via Drift)

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # Point d'entrée, pré-chargement solutions
│   DATEMODIF: 11212044  CODELINE: 55
│
├── bootstrap.dart               # Init Supabase
│
├── config/
│   └── game_icons_config.dart  # Configuration des icônes de jeu
│       DATEMODIF: 11230417  CODELINE: 139
│
├── models/                      # Modèles de données
│   ├── pentominos.dart         # 12 pièces avec toutes rotations
│   │   DATEMODIF: 11200721  CODELINE: 364
│   ├── plateau.dart            # Grille de jeu 6×10
│   │   DATEMODIF: 11191843  CODELINE: 67
│   ├── bigint_plateau.dart     # Plateau encodé en BigInt
│   │   DATEMODIF: 11150647  CODELINE: 70
│   ├── game_piece.dart         # Pièce interactive
│   │   DATEMODIF: 11150647  CODELINE: 63
│   ├── game.dart               # État complet d'une partie
│   │   DATEMODIF: 11150647  CODELINE: 96
│   ├── point.dart              # Coordonnées 2D
│   │   DATEMODIF: 11150647  CODELINE: 13
│   └── app_settings.dart       # Paramètres de l'application
│       DATEMODIF: 11220530  CODELINE: 271
│
├── database/                    # Base de données locale
│   ├── settings_database.dart  # Drift database pour settings
│   └── settings_database.g.dart # Code généré
│
├── services/                    # Logique métier
│   ├── solution_matcher.dart           # Comparaison solutions BigInt
│   │   DATEMODIF: 11230417  CODELINE: 131
│   ├── pentapol_solutions_loader.dart  # Chargement .bin → BigInt
│   │   DATEMODIF: 11150647  CODELINE: 51
│   ├── plateau_solution_counter.dart   # Extension Plateau
│   │   DATEMODIF: 11150647  CODELINE: 74
│   ├── pentomino_solver.dart          # Backtracking avec heuristiques
│   │   DATEMODIF: 11192114  CODELINE: 589
│   ├── isometry_transforms.dart       # Transformations géométriques
│   │   DATEMODIF: 11200617  CODELINE: 57
│   └── shape_recognizer.dart          # Reconnaissance de formes
│       DATEMODIF: 11200618  CODELINE: 46
│
├── providers/                   # Gestion d'état Riverpod
│   ├── pentomino_game_provider.dart   # Logique jeu unifié
│   │   DATEMODIF: 11230501  CODELINE: 844
│   ├── pentomino_game_state.dart      # État jeu
│   │   DATEMODIF: 11210756  CODELINE: 168
│   └── settings_provider.dart         # Paramètres utilisateur
│       DATEMODIF: 11220530  CODELINE: 131
│
├── screens/                     # Interfaces utilisateur
│   ├── pentomino_game_screen.dart     # Jeu interactif (orchestrateur)
│   │   DATEMODIF: 11230417  CODELINE: 231
│   │
│   ├── pentomino_game/                # Structure modulaire ✅
│   │   ├── utils/                     # Utilitaires
│   │   │   ├── game_constants.dart    # Constantes du jeu
│   │   │   │   DATEMODIF: 11180509  CODELINE: 19
│   │   │   ├── game_colors.dart       # Palette de couleurs
│   │   │   │   DATEMODIF: 11180612  CODELINE: 52
│   │   │   └── game_utils.dart        # Export centralisé
│   │   │       DATEMODIF: 11180611  CODELINE: 2
│   │   │
│   │   └── widgets/                   # Widgets modulaires
│   │       ├── shared/                # Partagés entre modes
│   │       │   ├── piece_renderer.dart          # Affichage pièce
│   │       │   │   DATEMODIF: 11191843  CODELINE: 98
│   │       │   ├── draggable_piece_widget.dart  # Drag & drop
│   │       │   │   DATEMODIF: 11180633  CODELINE: 119
│   │       │   ├── piece_border_calculator.dart # Bordures
│   │       │   │   DATEMODIF: 11191843  CODELINE: 79
│   │       │   ├── action_slider.dart           # Actions paysage
│   │       │   │   DATEMODIF: 11230447  CODELINE: 214
│   │       │   └── game_board.dart              # Plateau de jeu
│   │       │       DATEMODIF: 11212021  CODELINE: 336
│   │       │
│   │       └── game_mode/             # Mode jeu normal
│   │           └── piece_slider.dart  # Slider pièces
│   │               DATEMODIF: 11210703  CODELINE: 137
│   │
│   ├── solutions_browser_screen.dart  # Navigateur solutions
│   ├── solutions_viewer_screen.dart   # Visualisation solutions
│   ├── home_screen.dart               # Écran principal
│   ├── settings_screen.dart           # Paramètres
│   │   DATEMODIF: 11220406  CODELINE: 355
│   ├── custom_colors_screen.dart      # Personnalisation couleurs
│   ├── auth_screen.dart               # Connexion
│   └── leaderboard_screen.dart        # Classements
│
├── utils/                       # Utilitaires
│   ├── time_format.dart        # Formatage temps
│   ├── pentomino_geometry.dart # Géométrie pentominos
│   ├── piece_utils.dart        # Utilitaires pièces
│   │   DATEMODIF: 11191843  CODELINE: 184
│   ├── plateau_compressor.dart # Compression plateau
│   ├── solution_collector.dart # Collection solutions
│   └── solution_exporter.dart  # Export solutions
│
└── data/                        # Données
    ├── race_repo.dart          # Repository courses
    └── solution_database.dart  # Base de données solutions
```

---

## 📦 Modèles de données

### 1. `pentominos.dart` - Les 12 pièces
**DATEMODIF:** 11200721 | **CODELINE:** 364

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

**Utilisation** :
```dart
import 'package:pentapol/models/pentominos.dart';

// Liste globale des 12 pièces
final pieces = pentominos;

// Accéder à une pièce
final piece1 = pentominos[0]; // Pièce id=1
print('${piece1.numPositions} orientations'); // 1
```

---

### 2. `plateau.dart` - Grille de jeu
**DATEMODIF:** 11191843 | **CODELINE:** 67

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
**DATEMODIF:** 11150647 | **CODELINE:** 70

Version optimisée du plateau encodée sur 360 bits (60 cases × 6 bits).

**Structure `BigIntPlateau`** :
```dart
class BigIntPlateau {
  final BigInt pieces; // Codes bit6 de chaque case
  final BigInt mask;   // 0x3F si case occupée, 0 sinon
  
  // Factory
  factory BigIntPlateau.empty();
  
  // Méthodes
  BigIntPlateau placePiece({
    required int pieceId,
    required Iterable<int> cellIndices,
    required Map<int, int> bit6ById,
  });
  
  BigIntPlateau clearCells(Iterable<int> cellIndices);
  int getCell(int x, int y); // Retourne 0 ou 1-12
}
```

**Encodage** :
- Chaque case = 6 bits (codes 1-12 pour les pièces)
- Case 0 → bits 354-359
- Case 59 → bits 0-5
- Total : 360 bits (45 octets)

---

### 4. `game_piece.dart` - Pièce interactive
**DATEMODIF:** 11150647 | **CODELINE:** 63

Wrapper autour de `Pento` pour le jeu interactif.

**Structure `GamePiece`** :
```dart
class GamePiece {
  final Pento piece;
  final int currentOrientation;  // 0 à numPositions-1
  final bool isPlaced;
  final int? placedX, placedY;
  
  // Méthodes
  GamePiece rotate();
  GamePiece place(int x, int y);
  GamePiece unplace();
  List<Point> get currentCoordinates;
  List<Point>? get absoluteCoordinates;
}
```

---

### 5. `game.dart` - État complet d'une partie
**DATEMODIF:** 11150647 | **CODELINE:** 96

**Structure `Game`** :
```dart
class Game {
  final Plateau plateau;
  final List<GamePiece> pieces;
  final DateTime createdAt;
  final int? seed;
  
  // Factory
  static Game create({
    required Plateau plateau,
    required List<int> pieceIds,
    int? seed,
  });
  
  // Méthodes
  bool get isCompleted;
  int get numPlacedPieces;
  bool canPlacePiece(int pieceIndex, int x, int y);
  Game? placePieceAt(int pieceIndex, int x, int y);
  Game? removePiece(int pieceIndex);
}
```

---

### 6. `point.dart` - Coordonnées 2D
**DATEMODIF:** 11150647 | **CODELINE:** 13

Simple classe pour représenter des coordonnées (x, y).

---

### 7. `app_settings.dart` - Paramètres application
**DATEMODIF:** 11220530 | **CODELINE:** 271

**Structure `AppSettings`** :
```dart
class AppSettings {
  final bool showSolutionCount;
  final bool enableHapticFeedback;
  final bool showPieceNumbers;
  final Map<int, Color> customPieceColors;
  
  // Méthodes
  AppSettings copyWith({...});
  Map<String, dynamic> toJson();
  factory AppSettings.fromJson(Map<String, dynamic> json);
}
```

---

## ⚙️ Services

### 1. `solution_matcher.dart` - Comparaison solutions BigInt
**DATEMODIF:** 11230417 | **CODELINE:** 131

Service central pour comparer un plateau avec les 2339 solutions canoniques.

**Classe `SolutionMatcher`** :
```dart
class SolutionMatcher {
  late final List<BigInt> _solutions; // ~9356 solutions
  
  // Initialisation (appelée au démarrage)
  void initWithBigIntSolutions(List<BigInt> canonicalSolutions);
  
  // Comptage
  int countCompatibleFromBigInts(BigInt piecesBits, BigInt maskBits);
  
  // Récupération
  List<BigInt> getCompatibleSolutionsFromBigInts(
    BigInt piecesBits, 
    BigInt maskBits,
  );
  
  // Propriétés
  int get totalSolutions; // ~9356
  List<BigInt> get allSolutions;
}

// Singleton global
final solutionMatcher = SolutionMatcher();
```

**Transformations générées** :
Pour chaque solution canonique (2339), on génère 4 variantes :
1. Identité
2. Rotation 180°
3. Miroir horizontal
4. Miroir vertical

Total : 2339 × 4 = 9356 solutions

---

### 2. `pentapol_solutions_loader.dart` - Chargement binaire
**DATEMODIF:** 11150647 | **CODELINE:** 51

Charge le fichier `assets/data/solutions_6x10_normalisees.bin`.

**Format du fichier** :
- 45 octets par solution (360 bits ÷ 8)
- 2339 solutions × 45 octets = 105 255 octets
- Encodage bit-packed 6 bits par case

---

### 3. `plateau_solution_counter.dart` - Extension Plateau
**DATEMODIF:** 11150647 | **CODELINE:** 74

Ajoute des méthodes au `Plateau` pour compter les solutions.

**Extension** :
```dart
extension PlateauSolutionCounter on Plateau {
  // Compte les solutions compatibles
  int? countPossibleSolutions();
  
  // Récupère les solutions compatibles (BigInt)
  List<BigInt> getCompatibleSolutionsBigInt();
}
```

---

### 4. `pentomino_solver.dart` - Backtracking
**DATEMODIF:** 11192114 | **CODELINE:** 589

Algorithme de résolution par backtracking avec heuristiques avancées.

**Structure `PlacementInfo`** :
```dart
class PlacementInfo {
  final int pieceIndex;
  final int orientation;
  final int targetCell;      // 1-60
  final int offsetX, offsetY;
  final List<int> occupiedCells;
}
```

**Classe `PentominoSolver`** :
```dart
class PentominoSolver {
  int maxSeconds = 30; // Timeout
  
  // Résolution
  List<PlacementInfo>? solve();
  List<PlacementInfo>? findNext(); // Solution suivante
  
  // Heuristiques
  bool areIsolatedRegionsValid();
  int findSmallestFreeCell();
  bool canPlaceWithOffset(...);
}
```

**Optimisations** :
1. **Timeout 30s** : Évite blocages infinis
2. **Détection zones isolées** : Élagage précoce
3. **Flood fill** : Détecte régions impossibles
4. **Ordre fixe des pièces** : Reproductibilité

---

### 5. `isometry_transforms.dart` - Transformations géométriques
**DATEMODIF:** 11200617 | **CODELINE:** 57

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

### 6. `shape_recognizer.dart` - Reconnaissance de formes
**DATEMODIF:** 11200618 | **CODELINE:** 46

Service pour reconnaître les pièces placées sur le plateau.

**Classe `ShapeRecognizer`** :
```dart
class ShapeRecognizer {
  // Reconnaît la pièce à partir de ses coordonnées
  int? recognizePiece(List<Point> coordinates);
  
  // Vérifie si une forme correspond à une pièce
  bool matchesPiece(List<Point> shape, int pieceId);
}
```

---

## 📱 Écrans

### 1. `pentomino_game_screen.dart` - Jeu interactif (REFACTORÉ ✅)
**DATEMODIF:** 11230417 | **CODELINE:** 231

Interface de jeu complète avec **2 modes auto-détectés** :

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

**Architecture modulaire** :
```dart
class PentominoGameScreen extends ConsumerStatefulWidget {
  // Orchestrateur principal (231 lignes)
  
  // Composants extraits :
  Widget _buildGameBoard();      // → GameBoard widget
  Widget _buildPieceSlider();    // → PieceSlider widget
  Widget _buildActionSlider();   // → ActionSlider widget
}
```

**Widgets extraits** :
- `GameBoard` : Plateau de jeu avec DragTarget (336 lignes)
- `PieceSlider` : Slider horizontal pièces (137 lignes)
- `ActionSlider` : Slider actions (214 lignes)
- `PieceRenderer` : Affichage pièce (98 lignes)
- `DraggablePieceWidget` : Gestion gestures (119 lignes)
- `PieceBorderCalculator` : Calcul bordures (79 lignes)

---

### 2. `settings_screen.dart` - Paramètres
**DATEMODIF:** 11220406 | **CODELINE:** 355

Écran de configuration de l'application.

**Fonctionnalités** :
- ✅ Afficher/masquer compteur de solutions
- ✅ Activer/désactiver haptic feedback
- ✅ Afficher/masquer numéros de pièces
- ✅ Personnaliser couleurs des pièces
- ✅ Réinitialiser paramètres

---

## 🔄 Providers (Riverpod)

### 1. `pentomino_game_provider.dart` - Logique jeu unifiée
**DATEMODIF:** 11230501 | **CODELINE:** 844

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
  
  // Utilitaires
  int? getPlacedPieceAt(int gridX, int gridY);
  bool canPlacePiece(int pieceIndex, int gridX, int gridY);
}

final pentominoGameProvider = NotifierProvider<
  PentominoGameNotifier, 
  PentominoGameState
>(PentominoGameNotifier.new);
```

---

### 2. `pentomino_game_state.dart` - État jeu
**DATEMODIF:** 11210756 | **CODELINE:** 168

**Structure** :
```dart
class PentominoGameState {
  final Plateau plateau;
  final List<Pento> availablePieces;
  final List<PlacedPiece> placedPieces;
  
  // Mode Jeu
  final int? selectedPiece;           // Index pièce sélectionnée
  final int? selectedPlacedPiece;     // Index pièce placée sélectionnée
  final int selectedOrientation;      // Orientation actuelle
  final Map<int, int> pieceOrientations; // Orientations par pièce
  final Point? referenceCellInPiece;  // Case de référence
  final int? previewX, previewY;      // Position preview
  final bool isPreviewValid;          // Preview valide?
  
  // Historique
  final List<PentominoGameState> history;
  
  factory PentominoGameState.initial();
  PentominoGameState copyWith({...});
  bool canPlacePiece(int pieceIndex, int gridX, int gridY);
  bool get isCompleted;
}
```

---

### 3. `settings_provider.dart` - Paramètres utilisateur
**DATEMODIF:** 11220530 | **CODELINE:** 131

**Notifier** :
```dart
class SettingsNotifier extends Notifier<AppSettings> {
  Future<void> toggleSolutionCount();
  Future<void> toggleHapticFeedback();
  Future<void> togglePieceNumbers();
  Future<void> setCustomColor(int pieceId, Color color);
  Future<void> resetColors();
  Future<void> resetAll();
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
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    UTILISATION RUNTIME                       │
│                                                              │
│  Plateau.countPossibleSolutions()                           │
│    └─> Convertit Plateau en (piecesBits, maskBits)         │
│        └─> solutionMatcher.countCompatibleFromBigInts()    │
│            └─> Compare avec les 9356 solutions             │
│                ├─> (solution & mask) == pieces ?           │
│                └─> Retourne compteur                        │
│                                                              │
│  Plateau.getCompatibleSolutionsBigInt()                     │
│    └─> Récupère List<BigInt> des solutions compatibles     │
│        └─> Utilisé pour navigateur de solutions            │
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

## ⚙️ Configuration

### `main.dart` - Point d'entrée
**DATEMODIF:** 11212044 | **CODELINE:** 55

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
- `game_constants.dart` - DATEMODIF: 11180509 | CODELINE: 19
- `game_colors.dart` - DATEMODIF: 11180612 | CODELINE: 52
- `game_utils.dart` - DATEMODIF: 11180611 | CODELINE: 2

### Phase 2 : Widgets ✅ (18-23 nov 2025)
**Fichiers créés** :
- `piece_renderer.dart` - DATEMODIF: 11191843 | CODELINE: 98
- `draggable_piece_widget.dart` - DATEMODIF: 11180633 | CODELINE: 119
- `piece_border_calculator.dart` - DATEMODIF: 11191843 | CODELINE: 79
- `action_slider.dart` - DATEMODIF: 11230447 | CODELINE: 214
- `game_board.dart` - DATEMODIF: 11212021 | CODELINE: 336
- `piece_slider.dart` - DATEMODIF: 11210703 | CODELINE: 137

### Résultats
- **Avant** : 1350 lignes (monolithique)
- **Après** : 231 lignes (orchestrateur)
- **Gain** : -1119 lignes (-83%) 🎯
- **Imports** : Tous en absolu depuis `lib/`

**Architecture finale** :
```
pentomino_game_screen.dart (231 lignes)
├── GameBoard (336 lignes)
├── PieceSlider (137 lignes) - Mode Jeu
├── ActionSlider (214 lignes) - Mode Isométries
└── Widgets partagés
    ├── PieceRenderer (98 lignes)
    ├── DraggablePieceWidget (119 lignes)
    └── PieceBorderCalculator (79 lignes)
```

### Améliorations apportées (23 nov 2025)
- ✅ **Détection automatique des modes** : Plus besoin de toggle manuel
- ✅ **Mode Isométries complet** : Rotation, miroirs avec UI adaptative
- ✅ **Extraction GameBoard** : Plateau de jeu complètement modulaire
- ✅ **Code ultra-propre** : Orchestrateur de 231 lignes seulement
- ✅ **Architecture scalable** : Facile d'ajouter de nouveaux modes

---

## 📊 Index des fichiers

### Fichiers récemment modifiés (Novembre 2025)

| Fichier | DATEMODIF | CODELINE | Description |
|---------|-----------|----------|-------------|
| `pentomino_game_provider.dart` | 11230501 | 844 | Provider jeu unifié |
| `action_slider.dart` | 11230447 | 214 | Slider actions isométries |
| `solution_matcher.dart` | 11230417 | 131 | Comparaison solutions |
| `pentomino_game_screen.dart` | 11230417 | 231 | Orchestrateur principal |
| `game_icons_config.dart` | 11230417 | 139 | Config icônes |
| `settings_provider.dart` | 11220530 | 131 | Provider paramètres |
| `app_settings.dart` | 11220530 | 271 | Modèle paramètres |
| `settings_screen.dart` | 11220406 | 355 | Écran paramètres |
| `main.dart` | 11212044 | 55 | Point d'entrée |
| `game_board.dart` | 11212021 | 336 | Plateau de jeu |
| `pentomino_game_state.dart` | 11210756 | 168 | État jeu |
| `piece_slider.dart` | 11210703 | 137 | Slider pièces |
| `pentominos.dart` | 11200721 | 364 | 12 pièces |
| `shape_recognizer.dart` | 11200618 | 46 | Reconnaissance formes |
| `isometry_transforms.dart` | 11200617 | 57 | Transformations |
| `pentomino_solver.dart` | 11192114 | 589 | Solver backtracking |
| `piece_utils.dart` | 11191843 | 184 | Utilitaires pièces |
| `piece_renderer.dart` | 11191843 | 98 | Affichage pièce |
| `piece_border_calculator.dart` | 11191843 | 79 | Calcul bordures |
| `plateau.dart` | 11191843 | 67 | Grille de jeu |
| `draggable_piece_widget.dart` | 11180633 | 119 | Drag & drop |
| `game_colors.dart` | 11180612 | 52 | Palette couleurs |
| `game_utils.dart` | 11180611 | 2 | Export centralisé |
| `game_constants.dart` | 11180509 | 19 | Constantes jeu |

### Fichiers stables (Novembre 2025)

| Fichier | DATEMODIF | CODELINE | Description |
|---------|-----------|----------|-------------|
| `bigint_plateau.dart` | 11150647 | 70 | Plateau BigInt |
| `game_piece.dart` | 11150647 | 63 | Pièce interactive |
| `game.dart` | 11150647 | 96 | État partie |
| `point.dart` | 11150647 | 13 | Coordonnées 2D |
| `pentapol_solutions_loader.dart` | 11150647 | 51 | Chargement binaire |
| `plateau_solution_counter.dart` | 11150647 | 74 | Extension Plateau |

---

## 📊 Statistiques

### Nombre de solutions

- **2 339** solutions canoniques (une par classe de symétrie)
- **9 356** solutions totales (avec 4 transformations)
- **45 octets** par solution dans le fichier .bin
- **105 KB** taille du fichier binaire

### Lignes de code (hors commentaires)

- **Total core** : ~5 200 lignes
- **Provider principal** : 844 lignes
- **Solver** : 589 lignes
- **Pentominos** : 364 lignes
- **Settings screen** : 355 lignes
- **Game board** : 336 lignes
- **App settings** : 271 lignes

### Performances

- **Chargement solutions** : ~200-500ms
- **Génération transformations** : ~100-300ms
- **Comptage compatible** : ~10-50ms (pour 9356 solutions)
- **Transformation isométrique** : ~1-5ms

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
```

---

## 🚀 Prochaines étapes

### Court terme
- [x] Réorganisation pentomino_game Phase 1-2 (-83%)
- [x] Mode Isométries complet avec UI adaptative
- [x] Extraction complète GameBoard
- [ ] Optimiser transformations isométriques (cache)
- [ ] Ajouter animations pour transformations
- [ ] Sauvegarder/charger plateaux

### Moyen terme
- [ ] Mode challenge avec objectifs
- [ ] Statistiques et analytics
- [ ] Partage de configurations
- [ ] Tutorial interactif
- [ ] Améliorer UI navigateur solutions

### Long terme
- [ ] Mode multijoueur temps réel
- [ ] Générateur de puzzles avec difficulté
- [ ] Leaderboards et achievements
- [ ] Support autres formats (non 6×10)

---

## 📝 Notes importantes

### ⚠️ Points d'attention

1. **Mémoire** : Les 9356 solutions BigInt occupent ~100KB en RAM
2. **Transformations** : Les isométries modifient le plateau entier
3. **Mode auto-détection** : Basé sur la présence de sélection (pièce ou placée)
4. **Orientation** : AppBar s'adapte automatiquement (portrait/paysage)

### ✅ Bonnes pratiques

1. Toujours initialiser `solutionMatcher` au démarrage
2. Utiliser `copyWith()` pour l'immutabilité
3. Préférer `BigInt` pour les comparaisons (performances)
4. Ajouter logs pour debugging
5. Commenter les modifications avec dates (format DATEMODIF)
6. Compter les lignes de code hors commentaires (CODELINE)

### 🔗 Liens utiles

- Flutter : https://flutter.dev
- Riverpod : https://riverpod.dev
- Supabase : https://supabase.com
- Pentominos : https://en.wikipedia.org/wiki/Pentomino

---

**Dernière mise à jour : 23 novembre 2025 05:09**

**Mainteneur : Documentation générée automatiquement**

**Format des métadonnées :**
- **DATEMODIF** : Format MMDDHHMM (Mois Jour Heure Minute)
- **CODELINE** : Nombre de lignes de code (hors commentaires et lignes vides)




