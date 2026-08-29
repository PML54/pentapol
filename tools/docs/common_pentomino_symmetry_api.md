# common/pentomino_symmetry_api.dart

**Module:** common

## Fonctions

### applyRotationAbs

Type de symétrie demandée.
Axe horizontal: droite y = masterY.
Axe vertical: droite x = masterX.
Applique une rotation en coordonnées ABSOLUES autour de la mastercase.

- [cellsAbs]: liste de cellules absolues (plateau).
- [masterAbs]: mastercase absolue (centre de rotation).
- [clockwise]: true = rotation horaire, false = anti-horaire.

Retourne les nouvelles coordonnées ABSOLUES (peuvent être négatives).


```dart
List<Point> applyRotationAbs({
```

### Point

```dart
return Point(xm + dy, ym - dx);
```

### Point

```dart
return Point(xm - dy, ym + dx);
```

### applySymmetryAbs

Applique une symétrie en coordonnées ABSOLUES.

- [cellsAbs]: liste de cellules absolues (plateau).
- [masterAbs]: mastercase absolue (point fixe de l'axe).
- [type]: horizontal ou vertical.

Retourne les nouvelles coordonnées ABSOLUES (peuvent être négatives).


```dart
List<Point> applySymmetryAbs({
```

### Point

```dart
return Point(p.x, 2 * ym - p.y);
```

### Point

```dart
return Point(2 * xm - p.x, p.y);
```

### normalizeCoords

Normalise une liste de coordonnées en décalant le min vers (0,0).

Utile pour comparer une forme à des coordonnées normalisées d'orientation.


```dart
List<Point> normalizeCoords(List<Point> coords) {
```

### findOrientationIndexFromNormalized

Trie des coords pour comparaison stable.
Retrouve l'index d'orientation correspondant à des coordonnées normalisées.

Retourne null si aucune orientation ne correspond.
Pipeline complet: symétrie ABS -> normalisation -> orientation.

Retourne l'index d'orientation ou null si non trouvée.


```dart
return findOrientationIndexFromNormalized( piece: piece, normalizedCoords: normalized, );
```

