# services/pentapol_solutions_loader.dart

**Module:** services

## Fonctions

### StateError

Charge les solutions normalisées d'un rectangle de 60 cases depuis [asset].

[asset] par défaut : la table 6×10 (comportement historique inchangé). Le
format (60 cases × 6 bits = 45 octets/solution) ne dépend pas de la forme du
rectangle, seul le nom du fichier change — voir PLAN_6X10_DANS_PENTOSCOPE.md §4.3.


```dart
throw StateError( 'Taille de fichier invalide: ${bytes.length} octets, '
```

