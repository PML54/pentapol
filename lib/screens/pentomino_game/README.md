# 📁 Pentomino Game - Structure

Réorganisation progressive de `pentomino_game_screen.dart` en modules réutilisables.

## 🎯 Objectif

Découper le fichier monolithique (1350+ lignes) en composants plus petits et maintenables.

## 📊 État actuel (18 novembre 2025)

### ✅ Phase 1 : Utilitaires (Complète)
- `utils/game_constants.dart` - Dimensions, bordures, slider
- `utils/game_colors.dart` - Palette de couleurs complète
- `utils/game_utils.dart` - Export centralisé

### ✅ Phase 2 : Widgets (Complète)
- `widgets/shared/piece_renderer.dart` - Affichage d'une pièce (120 lignes)
- `widgets/shared/draggable_piece_widget.dart` - Drag & drop + double-tap (170 lignes)
- `widgets/shared/piece_border_calculator.dart` - Bordures de pièces (120 lignes)
- `widgets/shared/action_slider.dart` - Actions mode paysage (310 lignes)
- `widgets/game_mode/piece_slider.dart` - Slider de pièces (175 lignes)

### 📈 Résultats
- **Avant** : 1350 lignes (monolithique)
- **Après** : 650 lignes (orchestrateur)
- **Gain** : -700 lignes (-52%) 🎯
- **Widgets extraits** : 5 fichiers (~895 lignes)

### 📋 À faire (futur)
- `widgets/shared/game_board.dart` - Grille 6×10 (~400 lignes)
- AppBars des 2 modes (~100 lignes)
- Vues complètes des modes

## 📖 Usage

### Importer les utilitaires

```dart
// Imports absolus depuis lib/
import 'package:pentapol/screens/pentomino_game/utils/game_utils.dart';

// Utilisation
final width = GameConstants.boardWidth;
final color = GameColors.masterCellBorderColor;
```

### Importer les widgets

```dart
// Widgets partagés
import 'package:pentapol/screens/pentomino_game/widgets/shared/piece_renderer.dart';
import 'package:pentapol/screens/pentomino_game/widgets/shared/action_slider.dart';

// Widgets mode jeu
import 'package:pentapol/screens/pentomino_game/widgets/game_mode/piece_slider.dart';
```

## 🎨 Architecture actuelle

```
pentomino_game/
├── pentomino_game_screen.dart    # Orchestrateur (650 lignes)
├── widgets/                       # Composants UI
│   ├── shared/                   # Partagés ✅
│   │   ├── piece_renderer.dart
│   │   ├── draggable_piece_widget.dart
│   │   ├── piece_border_calculator.dart
│   │   └── action_slider.dart
│   ├── game_mode/                # Mode jeu ✅
│   │   └── piece_slider.dart
│   └── isometries_mode/          # Mode isométries (futur)
└── utils/                         # Utilitaires ✅
    ├── game_constants.dart
    ├── game_colors.dart
    └── game_utils.dart
```

## 🔧 Principes de conception

### 1. Imports absolus
Tous les imports utilisent `package:pentapol/` pour une meilleure lisibilité.

### 2. Widgets réutilisables
Chaque widget extrait est autonome et réutilisable.

### 3. Séparation des responsabilités
- **Utils** : Constantes et couleurs
- **Shared** : Widgets partagés entre modes
- **Game mode** : Widgets spécifiques au jeu
- **Orchestrateur** : Coordination et layouts

### 4. Migration progressive
Extraction au fur et à mesure, sans breaking changes.

## 📝 Notes

- ✅ Tous les widgets extraits sont testés
- ✅ 0 erreurs, 0 warnings
- ✅ Tests OK sur iOS et macOS
- 📦 Prêt pour extraction future du GameBoard
