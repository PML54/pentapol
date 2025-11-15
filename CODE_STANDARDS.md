<!-- Modified: 2025-11-15 06:45:00 -->
# Standards de Code - Pentapol

## 📋 Règles d'en-tête de fichier

### Pour tous les fichiers de code

Chaque fichier de code doit avoir un en-tête standardisé contenant :

1. **Date et heure de modification** (format : `YYYY-MM-DD HH:MM:SS`)
2. **Chemin absolu du fichier** (depuis `lib/...`)
3. **Description optionnelle** (si pertinent)

### Format par type de fichier

#### Fichiers Dart (`.dart`)

```dart
// Modified: 2025-11-15 14:36:12
// lib/chemin/vers/fichier.dart
// Description optionnelle du fichier

import 'package:flutter/material.dart';
// ... reste du code
```

#### Fichiers Markdown (`.md`)

```markdown
<!-- Modified: 2025-11-15 06:45:00 -->
# Titre du document

Contenu...
```

#### Autres langages

Utiliser le format de commentaire approprié au langage :

**Python** :
```python
# Modified: 2025-11-15 14:36:12
# chemin/vers/fichier.py
```

**JavaScript/TypeScript** :
```javascript
// Modified: 2025-11-15 14:36:12
// chemin/vers/fichier.js
```

**Kotlin** :
```kotlin
// Modified: 2025-11-15 14:36:12
// chemin/vers/fichier.kt
```

## 🎯 Objectifs

Ces en-têtes permettent de :

- **Tracer l'historique** : Savoir quand un fichier a été modifié pour la dernière fois
- **Identifier rapidement** : Connaître le chemin absolu du fichier sans ambiguïté
- **Documenter** : Ajouter une description du rôle du fichier si nécessaire

## ✅ Application

Cette règle a été appliquée à tous les fichiers Dart existants le **2025-11-15** :

- ✅ 7 fichiers dans `lib/screens/`
- ✅ 6 fichiers dans `lib/models/`
- ✅ 5 fichiers dans `lib/services/`
- ✅ 4 fichiers dans `lib/providers/`
- ✅ 4 fichiers dans `lib/utils/`
- ✅ 3 fichiers dans `lib/data/` et `lib/logic/`
- ✅ 3 fichiers racine (`main.dart`, `bootstrap.dart`, `models.dart`)

**Total : 32 fichiers Dart mis à jour**

## 🔄 Maintenance

À chaque modification d'un fichier :

1. Mettre à jour la date et l'heure dans l'en-tête
2. Vérifier que le chemin absolu est correct
3. Mettre à jour la description si le rôle du fichier a changé

## 📝 Exemple complet

```dart
// Modified: 2025-11-15 14:36:12
// lib/services/solution_matcher.dart
// Gestion des solutions de pentominos encodées en BigInt (360 bits).
//
// Chaque solution canonique est un BigInt construit ainsi :
//   acc = BigInt.zero;
//   for (code in boardBit6) { // 60 cases, code = bit6 (0..63)
//     acc = (acc << 6) | BigInt.from(code);
//   }

import 'package:flutter/foundation.dart';

class SolutionMatcher {
  // ... code
}
```

---

**Dernière mise à jour** : 2025-11-15 06:45:00

