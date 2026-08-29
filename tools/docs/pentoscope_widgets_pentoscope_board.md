# pentoscope/widgets/pentoscope_board.dart

**Module:** pentoscope

## Fonctions

### PentoscopeBoard

```dart
const PentoscopeBoard({super.key, required this.isLandscape});
```

### createState

```dart
ConsumerState<PentoscopeBoard> createState() => _PentoscopeBoardState();
```

### build

```dart
Widget build(BuildContext context) {
```

### LayoutBuilder

```dart
return LayoutBuilder( builder: (context, constraints) {
```

### Align

```dart
return Align( // En paysage: aligner en haut pour éviter l'espace // En portrait: centrer alignment: widget.isLandscape ? Alignment.topCenter : Alignment.center, child: Container( width: gridWidth, height: gridHeight, decoration: BoxDecoration( gradient: LinearGradient( begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.grey.shade50, Colors.grey.shade100], ), border: Border.all( color: Colors.grey.shade700, width: 3, ), boxShadow: [ BoxShadow( color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: 2, ), ], borderRadius: BorderRadius.circular(16), ), child: ClipRRect( borderRadius: BorderRadius.circular(16), child: GridView.builder( padding: EdgeInsets.zero, physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount( crossAxisCount: visualCols, childAspectRatio: 1.0, crossAxisSpacing: 0, mainAxisSpacing: 0, ), itemCount: boardWidth * boardHeight, itemBuilder: (context, index) {
```

