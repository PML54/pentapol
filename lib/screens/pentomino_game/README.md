# 📁 Pentomino Game - Structure

Réorganisation progressive de `pentomino_game_screen.dart` en modules réutilisables.

## 🎯 Objectif

Découper le fichier monolithique (1350+ lignes) en composants plus petits et maintenables.

## 📊 État actuel

### ✅ Fait
- `utils/` - Constantes et couleurs extraites
  - `game_constants.dart` - Dimensions, bordures, etc.
  - `game_colors.dart` - Palette de couleurs
  - `game_utils.dart` - Export centralisé

### 📋 À faire (progressivement)
- `widgets/shared/` - Widgets partagés entre les 2 modes
  - `game_board.dart` - Grille 6×10
  - `piece_renderer.dart` - Affichage d'une pièce
  - `draggable_piece_widget.dart` - Drag & drop
  
- `widgets/game_mode/` - Widgets mode jeu normal
  - `piece_slider.dart` - Slider horizontal
  - `game_mode_app_bar.dart` - AppBar mode jeu
  
- `widgets/isometries_mode/` - Widgets mode isométries
  - `isometries_toolbar.dart` - Toolbar transformations
  - `isometries_app_bar.dart` - AppBar mode isométries
  
- `modes/` - Vues des 2 modes
  - `game_mode_view.dart` - Vue mode jeu
  - `isometries_mode_view.dart` - Vue mode isométries

## 📖 Usage

### Importer les utilitaires

```dart
// Import unique pour tous les utilitaires
import '../pentomino_game/utils/game_utils.dart';

// Utilisation
final width = GameConstants.boardWidth;
final color = GameColors.masterCellBorderColor;
```

### Migration progressive

Les widgets seront extraits au fur et à mesure des modifications du code, sans tout casser d'un coup.

## 🎨 Architecture cible

```
pentomino_game/
├── pentomino_game_screen.dart    # Orchestrateur (100 lignes)
├── modes/                         # Vues des modes
├── widgets/                       # Composants UI
│   ├── shared/                   # Partagés
│   ├── game_mode/                # Mode jeu
│   └── isometries_mode/          # Mode isométries
└── utils/                         # Utilitaires ✅
```

## 📝 Notes

- Les utils sont déjà utilisables
- Le reste sera extrait progressivement
- Chaque extraction sera testée individuellement
- Pas de breaking changes

