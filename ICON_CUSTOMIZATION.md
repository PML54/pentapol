# Personnalisation des Icônes

## Vue d'ensemble

Ce document décrit le système de personnalisation des icônes ajouté à l'application Pentapol. Les utilisateurs peuvent maintenant modifier les icônes et leurs couleurs via l'écran des paramètres.

## Modifications apportées

### 1. Configuration des icônes (`lib/config/game_icons_config.dart`)

Ajout de nouvelles configurations d'icônes :
- `closeIsometries` : Icône de fermeture du mode isométries (croix)
- `thumbUp` : Icône pour indiquer des solutions possibles (pouce levé)
- `thumbDown` : Icône pour indiquer l'absence de solutions (pouce baissé)

### 2. Modèle de paramètres (`lib/models/app_settings.dart`)

Extension de la classe `UISettings` avec les propriétés suivantes :

#### Icônes personnalisables
- `settingsIcon` / `settingsColor` : Icône des paramètres
- `closeIsometriesIcon` / `closeIsometriesColor` : Icône de fermeture du mode isométries
- `thumbUpIcon` / `thumbUpColor` : Icône du pouce levé
- `thumbDownIcon` / `thumbDownColor` : Icône du pouce baissé
- `rotationIcon` / `rotationColor` : Icône de rotation anti-horaire
- `rotationCWIcon` / `rotationCWColor` : Icône de rotation horaire
- `symmetryHIcon` / `symmetryHColor` : Icône de symétrie horizontale
- `symmetryVIcon` / `symmetryVColor` : Icône de symétrie verticale

#### Valeurs par défaut
Toutes les icônes ont des valeurs par défaut correspondant à l'interface originale :
- Paramètres : `Icons.settings` (blanc)
- Fermeture : `Icons.close` (blanc)
- Pouce levé : `Icons.thumb_up` (vert)
- Pouce baissé : `Icons.thumb_down` (rouge)
- Rotation : `Icons.rotate_right` (orange)
- Rotation horaire : `Icons.rotate_left` (orange foncé)
- Symétrie H : `Icons.swap_horiz` (bleu)
- Symétrie V : `Icons.swap_vert` (vert)

### 3. Provider de paramètres (`lib/providers/settings_provider.dart`)

Ajout de méthodes pour modifier chaque icône et sa couleur :
- `setSettingsIcon()` / `setSettingsColor()`
- `setCloseIsometriesIcon()` / `setCloseIsometriesColor()`
- `setThumbUpIcon()` / `setThumbUpColor()`
- `setThumbDownIcon()` / `setThumbDownColor()`
- `setRotationIcon()` / `setRotationColor()`
- `setRotationCWIcon()` / `setRotationCWColor()`
- `setSymmetryHIcon()` / `setSymmetryHColor()`
- `setSymmetryVIcon()` / `setSymmetryVColor()`
- `resetIconsToDefaults()` : Réinitialise toutes les icônes

### 4. Écran de personnalisation (`lib/screens/icon_customization_screen.dart`)

Nouvel écran permettant de :
- Visualiser toutes les icônes personnalisables
- Modifier l'icône via un sélecteur de grille
- Modifier la couleur via une palette prédéfinie
- Réinitialiser toutes les icônes aux valeurs par défaut

#### Icônes disponibles dans le sélecteur
- `Icons.settings`, `Icons.settings_outlined`, `Icons.tune`, `Icons.build`
- `Icons.close`, `Icons.clear`, `Icons.cancel`
- `Icons.thumb_up`, `Icons.thumb_up_outlined`, `Icons.check_circle`, `Icons.check`
- `Icons.thumb_down`, `Icons.thumb_down_outlined`, `Icons.cancel_outlined`
- `Icons.rotate_right`, `Icons.rotate_left`, `Icons.refresh`, `Icons.replay`
- `Icons.swap_horiz`, `Icons.swap_horizontal_circle`, `Icons.compare_arrows`
- `Icons.swap_vert`, `Icons.swap_vertical_circle`, `Icons.unfold_more`

#### Couleurs disponibles
20 couleurs Material Design prédéfinies, incluant :
- Couleurs de base (blanc, rouge, bleu, vert, jaune, etc.)
- Nuances variées pour s'adapter à tous les thèmes

### 5. Écran des paramètres (`lib/screens/settings_screen.dart`)

Ajout d'une nouvelle option dans la section "Interface" :
- **Personnaliser les icônes** : Ouvre l'écran de personnalisation
- Description : "Modifier les icônes et leurs couleurs"

### 6. Écran de jeu (`lib/screens/pentomino_game_screen.dart`)

Mise à jour pour utiliser les icônes personnalisées depuis `settings.ui` :
- Icône des paramètres dans l'AppBar (mode normal)
- Icône de fermeture dans l'AppBar (mode isométries)
- Icônes de pouce levé/baissé pour le compteur de solutions
- Icônes d'isométries (rotation, symétries) dans l'AppBar

### 7. Slider d'actions (`lib/screens/pentomino_game/widgets/shared/action_slider.dart`)

Mise à jour pour utiliser les icônes personnalisées :
- Boutons de rotation en mode isométries
- Boutons de symétrie en mode isométries
- Bouton de rotation en mode jeu normal

## Utilisation

### Pour l'utilisateur

1. Ouvrir l'application Pentapol
2. Aller dans **Paramètres** (icône ⚙️)
3. Dans la section "Interface", sélectionner **Personnaliser les icônes**
4. Pour chaque icône :
   - Cliquer sur l'icône de crayon (✏️) pour changer l'icône
   - Cliquer sur l'icône de palette (🎨) pour changer la couleur
5. Les modifications sont sauvegardées automatiquement
6. Utiliser le bouton de réinitialisation (🔄) pour revenir aux valeurs par défaut

### Pour le développeur

Les icônes sont maintenant accessibles via `settings.ui` :

```dart
// Exemple d'utilisation
final settings = ref.watch(settingsProvider);

IconButton(
  icon: Icon(settings.ui.rotationIcon),
  color: settings.ui.rotationColor,
  onPressed: () => doRotation(),
)
```

## Persistance

Les paramètres d'icônes sont sauvegardés dans SQLite via `SettingsDatabase` :
- Sauvegarde automatique à chaque modification
- Restauration au démarrage de l'application
- Format JSON pour la sérialisation

## Compatibilité

- ✅ Compatible avec tous les modes de jeu (normal et isométries)
- ✅ Compatible avec les orientations portrait et paysage
- ✅ Sauvegarde persistante entre les sessions
- ✅ Réinitialisation facile aux valeurs par défaut

## Notes techniques

### Sérialisation des IconData

Les `IconData` sont sérialisées en JSON via leur `codePoint` :
```dart
// Sauvegarde
'rotationIcon': rotationIcon.codePoint

// Restauration
rotationIcon: IconData(json['rotationIcon'] ?? Icons.rotate_right.codePoint, 
                       fontFamily: 'MaterialIcons')
```

### Gestion des couleurs

Les couleurs utilisent la propriété `value` (bien que dépréciée, elle reste fonctionnelle) :
```dart
// Sauvegarde
'rotationColor': rotationColor.value

// Restauration
rotationColor: Color(json['rotationColor'] ?? 0xFFFFA726)
```

## Améliorations futures possibles

1. **Sélecteur de couleur personnalisé** : Permettre de choisir n'importe quelle couleur RGB
2. **Prévisualisations** : Afficher un aperçu de l'interface avec les icônes sélectionnées
3. **Thèmes d'icônes** : Créer des ensembles d'icônes prédéfinis (minimaliste, coloré, etc.)
4. **Import/Export** : Partager ses configurations d'icônes avec d'autres utilisateurs
5. **Icônes personnalisées** : Permettre l'upload d'images personnalisées

## Fichiers modifiés

- ✅ `lib/config/game_icons_config.dart` - Ajout de nouvelles configurations
- ✅ `lib/models/app_settings.dart` - Extension du modèle UISettings
- ✅ `lib/providers/settings_provider.dart` - Ajout des setters
- ✅ `lib/screens/settings_screen.dart` - Ajout du lien vers la personnalisation
- ✅ `lib/screens/icon_customization_screen.dart` - Nouvel écran (créé)
- ✅ `lib/screens/pentomino_game_screen.dart` - Utilisation des icônes personnalisées
- ✅ `lib/screens/pentomino_game/widgets/shared/action_slider.dart` - Utilisation des icônes personnalisées

## Tests

✅ Compilation réussie sans erreurs critiques
✅ Analyse statique passée (4 avertissements de dépréciation Flutter non critiques)
✅ Aucune erreur de linting dans les fichiers modifiés


