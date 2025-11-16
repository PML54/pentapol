<!-- Modified: 2025-11-16 11:20:00 -->
# 🔧 Refactoring - Code Commun

## 📋 Objectif

Extraire les parties communes du code pour éviter la duplication et faciliter la maintenance.

---

## 🎨 **1. Utilitaires des Pièces** (`lib/utils/piece_utils.dart`)

### Constantes Extraites

#### **Noms des pièces**
```dart
const Map<int, String> pieceNames = {
  1: 'X', 2: 'I', 3: 'Z', 4: 'V', 5: 'T', 6: 'W',
  7: 'U', 8: 'F', 9: 'P', 10: 'N', 11: 'Y', 12: 'L',
};
```

**Utilisé dans :**
- `lib/screens/custom_colors_screen.dart`

**Remplace :** Duplication locale du mapping ID → Nom

---

#### **Couleurs par défaut**
```dart
const List<Color> defaultPieceColors = [
  Color(0xFFE57373), // Rouge
  Color(0xFF81C784), // Vert
  // ... 12 couleurs
];
```

**Utilisé dans :**
- `lib/screens/custom_colors_screen.dart`
- `lib/models/app_settings.dart` (via `_getClassicColor`)

**Remplace :** 3 duplications de la même palette

---

### Fonctions Utilitaires

#### **`getPieceName(int pieceId)`**
Retourne le nom d'une pièce (X, I, L, etc.)

#### **`getDefaultPieceColor(int pieceId)`**
Retourne la couleur par défaut d'une pièce

#### **`getColorHex(Color color)`**
Convertit une couleur en code hexadécimal (#RRGGBB)

#### **`getPredefinedColors()`**
Retourne une palette de 50+ couleurs prédéfinies pour le sélecteur

---

### Widgets Réutilisables

#### **`PiecePreview`**
Affiche la forme d'une pièce en miniature

**Paramètres :**
- `piece`: Pento
- `color`: Color
- `cellSize`: double (défaut: 12.0)
- `showBorder`: bool (défaut: true)

**Utilisé dans :**
- `lib/screens/custom_colors_screen.dart`

**Remplace :** Méthode `_buildPiecePreview()` locale

---

#### **`PieceIcon`**
Affiche une pièce avec sa lettre dans un carré coloré

**Paramètres :**
- `pieceId`: int
- `color`: Color
- `size`: double (défaut: 50.0)
- `showBorder`: bool (défaut: true)

**Utilisé dans :**
- `lib/screens/custom_colors_screen.dart`

**Remplace :** Container custom avec Text

---

## 🎨 **2. Unification des Couleurs**

### Avant le Refactoring

Chaque écran avait sa propre palette de couleurs :

```dart
// solutions_browser_screen.dart
const colors = [
  Colors.black, Colors.blue, Colors.green, ...
];

// solutions_viewer_screen.dart
const colors = [
  Colors.black, Colors.blue, Colors.green, ...
];

// plateau_editor_screen.dart
static const List<Color> pieceColors = [
  Colors.black, Colors.blue, Colors.green, ...
];
```

**Problèmes :**
- ❌ Duplication de code
- ❌ Incohérence possible entre écrans
- ❌ Impossible de personnaliser les couleurs globalement

---

### Après le Refactoring

Tous les écrans utilisent `settings.ui.getPieceColor(pieceId)` :

```dart
// Tous les écrans
Color _getPieceColor(int pieceId) {
  final settings = ref.read(settingsProvider);
  return settings.ui.getPieceColor(pieceId);
}
```

**Avantages :**
- ✅ Une seule source de vérité
- ✅ Cohérence visuelle garantie
- ✅ Personnalisation globale
- ✅ Moins de code

---

### Écrans Refactorisés

#### **`lib/screens/solutions_browser_screen.dart`**
- Conversion en `ConsumerStatefulWidget`
- Ajout de `ref.read(settingsProvider)`
- Suppression de la palette locale (15 lignes)

#### **`lib/screens/solutions_viewer_screen.dart`**
- Ajout de l'import `settings_provider`
- Utilisation de `settings.ui.getPieceColor()`
- Suppression de la palette locale (14 lignes)

#### **`lib/screens/plateau_editor_screen.dart`**
- Ajout de `ref.watch(settingsProvider)`
- Utilisation de `settings.ui.getPieceColor()`
- Suppression de la constante `pieceColors` (13 lignes)

#### **`lib/screens/pentomino_game_screen.dart`**
- Déjà utilisait `settings.ui.getPieceColor()` ✅

---

## 📊 **Résultats**

### Lignes de Code Supprimées
- **Duplications de palettes :** ~42 lignes
- **Méthodes locales :** ~40 lignes
- **Constantes dupliquées :** ~15 lignes
- **Total :** ~97 lignes

### Lignes de Code Ajoutées
- **`piece_utils.dart` :** 220 lignes (réutilisables)
- **Imports et adaptations :** ~10 lignes
- **Total :** ~230 lignes

### Bilan
- **Code réutilisable :** +220 lignes
- **Code dupliqué supprimé :** -97 lignes
- **Ratio :** 1 ligne réutilisable remplace 0.44 lignes dupliquées

---

## 🎯 **Prochaines Étapes Possibles**

### 1. **Utiliser `PieceIcon` dans d'autres écrans**
- Slider de pièces du jeu
- Sélecteur de pièces dans l'éditeur

### 2. **Centraliser les bordures de pièces**
Extraire `_buildPieceBorder()` dans `piece_utils.dart`

### 3. **Créer un widget `PieceGrid`**
Widget réutilisable pour afficher une grille 6×10 avec des pièces

### 4. **Ajouter des tests unitaires**
Tester les fonctions utilitaires de `piece_utils.dart`

---

## 📝 **Conventions de Code**

### Utilisation de `piece_utils.dart`

```dart
// ✅ BON : Utiliser les utilitaires
import '../utils/piece_utils.dart';

final name = getPieceName(pieceId);
final color = getDefaultPieceColor(pieceId);

// ❌ MAUVAIS : Dupliquer le code
const names = {1: 'X', 2: 'I', ...};
const colors = [Color(0xFF...), ...];
```

### Utilisation des Settings

```dart
// ✅ BON : Utiliser les settings
final color = settings.ui.getPieceColor(pieceId);

// ❌ MAUVAIS : Palette locale
const colors = [Colors.red, Colors.blue, ...];
```

---

## 🔍 **Vérification**

Pour vérifier qu'il n'y a plus de duplications :

```bash
# Chercher les palettes de couleurs locales
grep -r "Colors.black.*// 1" lib/

# Chercher les méthodes _getPieceColor locales
grep -r "Color _getPieceColor" lib/

# Chercher les constantes pieceColors
grep -r "const.*pieceColors.*=" lib/
```

**Résultat attendu :** Aucune duplication trouvée ✅

---

**Dernière mise à jour :** 2025-11-16 11:20:00

