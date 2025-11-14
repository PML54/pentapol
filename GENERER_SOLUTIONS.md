# 🚀 Comment générer les solutions

## 📦 Architecture modulaire

Le système est désormais composé de modules réutilisables dans `lib/` :

- **`lib/utils/solution_collector.dart`** : Collecte les solutions du solver
- **`lib/utils/solution_exporter.dart`** : Exporte les solutions en plusieurs formats
- **`lib/utils/plateau_compressor.dart`** : Compression et canonisation des plateaux
- **`lib/data/solution_database.dart`** : Base de données des solutions canoniques
- **`lib/screens/solutions_viewer_screen.dart`** : Écran de visualisation des solutions
- **`test/canonical_forms_extractor.dart`** : Extraction des formes canoniques uniques

## ✅ Génération des solutions

### Option 1 : Depuis l'app Flutter (recommandé)

Utilise le `SolutionCollector` directement dans ton code :

```dart
import 'package:pentapol/utils/solution_collector.dart';
import 'package:pentapol/models/plateau.dart';
import 'package:pentapol/models/pentominos.dart';
import 'package:pentapol/services/pentomino_solver.dart';

Future<void> exportAllSolutions() async {
  final plateau = Plateau.allVisible(6, 10);
  final pieces = pentominos.take(12).toList();

  final collector = SolutionCollector(
    outputPath: '/path/to/pentomino_solutions.txt'
  );

  final solver = PentominoSolver(
    plateau: plateau,
    pieces: pieces,
  );

  print('Démarrage de la collecte...');
  final startTime = DateTime.now();

  await solver.countAllSolutions(
    onProgress: (count, elapsed) {
      print('[$elapsed s] $count solutions trouvées...');
    },
    onSolutionFound: collector.onSolutionFound,
  );

  final duration = DateTime.now().difference(startTime);
  print('Collecte terminée en ${duration.inMinutes}m ${duration.inSeconds % 60}s');

  await collector.finalize();
}
```

### Option 2 : Depuis un script test

Utilise le script `test/canonical_forms_extractor.dart` :

```bash
# 1. Exporter d'abord toutes les solutions (via l'app ou un script)
# 2. Extraire les formes canoniques
dart run test/canonical_forms_extractor.dart
```

## ⏱️ Durée estimée

**~9 minutes** (le temps de calcul des 9356 solutions)
**+ quelques secondes** (canonisation et déduplication)

## 📊 Flux de génération

```
═══════════════════════════════════════════════════════
🧩 GÉNÉRATION DES SOLUTIONS PENTOMINO
═══════════════════════════════════════════════════════

📊 ÉTAPE 1: Collecte des solutions brutes (9356 solutions)
   └─ Via SolutionCollector.onSolutionFound()
   └─ Plateau: 6×10 (60 cellules)
   └─ Pièces: 12 pentominos
   └─ Durée: ~9 minutes

   Formats générés:
   ✓ pentomino_solutions.txt         (format lisible)
   ✓ pentomino_solutions.txt.compact (CSV: une ligne par solution)
   ✓ pentomino_solutions.txt.dart    (const List<List<int>>)

📊 ÉTAPE 2: Extraction des formes canoniques (~2339 uniques)
   └─ Via CanonicalFormsExtractor
   └─ Élimine rotations 180° et symétries
   └─ Facteur de déduplication: ~4×
   └─ Durée: quelques secondes

   Formats générés:
   ✓ pentomino_canonical_forms.txt         (lisible)
   ✓ pentomino_canonical_forms.txt.compact (CSV)
   ✓ pentomino_canonical_forms.txt.dart    (const)

📊 ÉTAPE 3: Compression binaire (si nécessaire)
   └─ Via PlateauCompressor
   └─ 4 bits par cellule (au lieu de 8)
   └─ Facteur de compression: 2×
   └─ Fichier: assets/solutions_canonical.bin

═══════════════════════════════════════════════════════
✨ Architecture modulaire prête !
═══════════════════════════════════════════════════════
```

## 📁 Modules créés

### Utils (`lib/utils/`)

- **`solution_collector.dart`**
  - Adaptateur entre le solver et l'exporteur
  - Convertit `List<PlacementInfo>` en grilles 10x6
  - Callback `onSolutionFound` pour le solver

- **`solution_exporter.dart`**
  - Exporte en 3 formats : lisible, compact (CSV), Dart (const)
  - Indépendant du reste de l'app
  - Peut être utilisé standalone

- **`plateau_compressor.dart`**
  - Encode : Plateau → List<int> (8 × int32)
  - Décode : List<int> → Plateau
  - Canonisation : 8 variantes géométriques → forme minimale

### Data (`lib/data/`)

- **`solution_database.dart`**
  - Charge les solutions depuis assets
  - API de recherche : `findMatchingSolutions(plateau)`
  - Décodage des solutions compressées

### Screens (`lib/screens/`)

- **`solutions_viewer_screen.dart`**
  - Visualisation interactive des solutions
  - Navigation, slider, stats
  - Décodage à la volée des solutions binaires

### Test (`test/`)

- **`canonical_forms_extractor.dart`**
  - Script autonome pour extraire les formes canoniques
  - Élimine rotations 180° et symétries
  - Génère 3 formats de sortie

## 📊 Fichiers de données

### Générés par SolutionCollector

- `pentomino_solutions.txt` : Format lisible avec grilles
- `pentomino_solutions.txt.compact` : CSV, une solution par ligne (60 nombres)
- `pentomino_solutions.txt.dart` : Code Dart avec const

### Générés par CanonicalFormsExtractor

- `pentomino_canonical_forms.txt` : Formes canoniques lisibles
- `pentomino_canonical_forms.txt.compact` : CSV des formes uniques
- `pentomino_canonical_forms.txt.dart` : Code Dart des formes canoniques

### Assets de l'app

- `assets/solutions_canonical.bin` : Binaire compact (optionnel)
- `assets/solutions_canonical.meta.txt` : Métadonnées et stats

## 🎯 Utilisation dans l'app

### Pour utiliser les solutions dans l'app

1. **Ajouter dans `pubspec.yaml`** :

```yaml
flutter:
  assets:
    - assets/solutions_canonical.bin
```

2. **Charger au démarrage** (`lib/main.dart`) :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Charger les solutions (35 Ko, ~10ms)
  await SolutionDatabase.init();
  
  runApp(MyApp());
}
```

3. **Utiliser dans l'app** :

```dart
// Vérifier si un plateau est soluble
if (SolutionDatabase.hasSolution(monPlateau)) {
  print('✓ Soluble !');
}

// Trouver toutes les solutions compatibles
final solutions = SolutionDatabase.findMatchingSolutions(monPlateau);
print('${solutions.length} solutions trouvées');
```

## 🔥 Avantages

- ✅ **Instantané** : 10 ms au lieu de 9 minutes
- ✅ **Léger** : 35 Ko = rien
- ✅ **Offline** : Aucun calcul nécessaire
- ✅ **Fiable** : Solutions garanties correctes

## 🔄 Workflow complet

1. **Collecter les solutions** (dans ton app ou un script)
```dart
final collector = SolutionCollector(outputPath: 'tmp/solutions.txt');
await solver.countAllSolutions(onSolutionFound: collector.onSolutionFound);
await collector.finalize();
```

2. **Extraire les formes canoniques**
```bash
dart run test/canonical_forms_extractor.dart
```

3. **Visualiser dans l'app**
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const SolutionsViewerScreen(),
));
```

## ❓ Questions ?

- Voir `COMPRESSION.md` pour les détails techniques de compression
- Voir `assets/SOLUTIONS_README.md` pour le format des fichiers
- Consulter les commentaires dans chaque fichier `.dart` pour plus de détails

## 🎯 Avantages de cette architecture

✅ **Modulaire** : Chaque composant est indépendant et réutilisable
✅ **Testable** : Les scripts peuvent être lancés en standalone
✅ **Flexible** : 3 formats de sortie (lisible, CSV, Dart)
✅ **Efficace** : Compression 4× via canonisation + 2× via binaire
✅ **Intégré** : Écran de visualisation inclus dans l'app

---

**Note** : Les anciens scripts dans `tools/` ont été remplacés par cette architecture modulaire dans `lib/` et `test/`.

