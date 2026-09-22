// Modified: 2026-09-22 03:59 — couleurs de police du bandeau training, une par état du cascade.
// lib/config/training_bar_colors.dart
import 'package:flutter/material.dart';

/// Couleur de police du bandeau d'entraînement, **une par branche** du même `if` en cascade
/// que la consigne (voir `_buildTrainingBarMessage`). Le fond du bandeau est blanc : ces teintes
/// sont volontairement foncées (`shade800`/`shade700`) pour rester lisibles dessus.
///
/// `static final` et non `const` : `Colors.blue.shade800` est un getter de `MaterialColor`,
/// non évaluable à la compilation.
class TrainingBarColors {
  TrainingBarColors._();

  /// État 1 — aucune sélection (« Appuie sur la pièce… »).
  static final Color noSelection = Colors.blue.shade800;

  /// État 2 — pièce sélectionnée mais aucun placement valide (« Mets la pièce dans la bonne
  /// position… ») : `validPlacements` vide, même après de mauvaises isométries.
  static final Color noValidPlacement = Colors.deepOrange.shade800;

  /// État 3 — orientation offrant un placement valide (« Déplace-la au bon endroit… »).
  static final Color validPlacement = Colors.purple.shade700;

  /// État 4 — puzzle complété (« C'est bon ! »).
  static final Color complete = Colors.green.shade800;
}
