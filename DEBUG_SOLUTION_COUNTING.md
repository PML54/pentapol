# 🔍 Debug du Comptage de Solutions

## Problème décrit par l'utilisateur

Lorsqu'un joueur place une pièce sur le plateau dans le jeu, le système devrait :
1. ✅ Compter parmi les **9356 solutions** combien contiennent cette pièce à cet endroit exact
2. ✅ Mettre à jour ce compteur à chaque nouvelle pièce placée
3. ❓ **PROBLÈME** : Le compteur affiche peut-être 0 alors qu'il devrait trouver des solutions

## Architecture actuelle

```
Joueur place pièce
    ↓
PentominoGameProvider.tryPlacePiece()
    ↓
newPlateau.setCell(x, y, piece.id)  ← Stocke l'ID (1-12)
    ↓
newPlateau.countPossibleSolutions()
    ↓
PlateauSolutionCounter.toMask()     ← Crée masque [0=libre, 1-12=pièce]
    ↓
SolutionMatcher.countCompatible()   ← Compare avec 9356 solutions
    ↓
Retourne nombre de solutions compatibles
```

## Ce qui a été ajouté pour le debug

### 1. Logs dans `plateau_solution_counter.dart`

```dart
int countPossibleSolutions() {
  final mask = toMask();
  
  // Debug: compter combien de pièces sont placées
  final placedCells = mask.where((v) => v > 0).length;
  final pieceIds = mask.where((v) => v > 0).toSet();
  
  print('[PLATEAU_COUNTER] 🔍 Comptage des solutions:');
  print('[PLATEAU_COUNTER]   - Cellules occupées: $placedCells');
  print('[PLATEAU_COUNTER]   - IDs de pièces placées: $pieceIds');
  print('[PLATEAU_COUNTER]   - Première ligne du masque: ${mask.sublist(0, 6)}');
  
  final count = solutionMatcher.countCompatible(mask);
  print('[PLATEAU_COUNTER]   - ✓ Solutions compatibles trouvées: $count');
  
  return count;
}
```

### 2. Logs dans `pentomino_game_provider.dart`

```dart
print('[GAME] 📍 Placement de la pièce ${piece.id} (orientation $positionIndex):');
for (final cellNum in position) {
  print('[GAME]   - Cellule ($x, $y) = pièce ${piece.id}');
  newPlateau.setCell(x, y, piece.id);
}

print('[GAME] 🔎 Calcul des solutions possibles...');
final solutionsCount = newPlateau.countPossibleSolutions();
print('[GAME] 🎯 Solutions possibles: $solutionsCount');
```

## Comment tester

### Étape 1 : Lancer l'application
```bash
flutter run
```

### Étape 2 : Aller dans le mode jeu
- Cliquer sur "Jouer" depuis l'écran d'accueil

### Étape 3 : Placer une pièce
- Sélectionner une pièce dans le slider du bas
- La glisser sur le plateau
- Observer les logs dans la console

### Étape 4 : Analyser les logs

#### Exemple de logs attendus (succès) :
```
[GAME] 📍 Placement de la pièce 1 (orientation 0):
[GAME]   - Cellule (0, 0) = pièce 1
[GAME]   - Cellule (1, 0) = pièce 1
[GAME]   - Cellule (2, 0) = pièce 1
[GAME]   - Cellule (0, 1) = pièce 1
[GAME]   - Cellule (1, 1) = pièce 1
[GAME] 🔎 Calcul des solutions possibles...
[PLATEAU_COUNTER] 🔍 Comptage des solutions:
[PLATEAU_COUNTER]   - Cellules occupées: 5
[PLATEAU_COUNTER]   - IDs de pièces placées: {1}
[PLATEAU_COUNTER]   - Première ligne du masque: [1, 1, 1, 0, 0, 0]
[PLATEAU_COUNTER]   - ✓ Solutions compatibles trouvées: 342
[GAME] 🎯 Solutions possibles: 342
```

#### Exemple de logs si problème :
```
[PLATEAU_COUNTER]   - Cellules occupées: 5
[PLATEAU_COUNTER]   - IDs de pièces placées: {1}
[PLATEAU_COUNTER]   - ✓ Solutions compatibles trouvées: 0  ← PROBLÈME !
```

## Causes possibles si compteur = 0

### 1. ❌ Les 9356 solutions ne contiennent pas cette pièce à cet endroit
**Solution** : Vérifier que les solutions pré-calculées sont complètes

### 2. ❌ Le masque est incorrect
**Vérifier** : 
- Les IDs de pièces (doivent être 1-12)
- Les positions (doivent correspondre aux cellules occupées)

### 3. ❌ Bug dans `SolutionMatcher._isCompatible()`
**Vérifier** : La comparaison entre masque et solutions

### 4. ❌ Les solutions pré-calculées utilisent un système de numérotation différent
**Vérifier** : 
- Ordre des pièces dans les solutions
- Convention de numérotation des cellules

## Prochaines étapes selon les logs

### Si "Solutions compatibles trouvées: 0" alors que des pièces sont placées :

1. **Vérifier le format des solutions pré-calculées**
   - Fichier : `lib/services/pentomino_canonical_forms_hexa.dart`
   - Question : Les IDs de pièces correspondent-ils ?

2. **Ajouter un test unitaire**
   ```dart
   test('Comptage avec une pièce placée', () {
     final plateau = Plateau.allVisible(6, 10);
     plateau.setCell(0, 0, 1); // Pièce 1 en (0,0)
     final count = plateau.countPossibleSolutions();
     expect(count, greaterThan(0)); // Devrait trouver des solutions
   });
   ```

3. **Inspecter une solution pré-calculée**
   ```dart
   final firstSolution = solutionMatcher._allSolutions[0];
   final grid = firstSolution.toList();
   print('Première solution: $grid');
   ```

## Contact

Si le problème persiste après ces tests, fournir :
- Les logs complets d'un placement de pièce
- Le nombre de solutions affichées (0 ou autre)
- L'ID et la position de la pièce placée

---

**Note** : Ces logs de debug peuvent être retirés en production une fois le problème résolu.





