# pentoscope/widgets/pentoscope_piece_slider.dart

**Module:** pentoscope

## Fonctions

### PentoscopePieceSlider

```dart
const PentoscopePieceSlider({
```

### createState

```dart
ConsumerState<PentoscopePieceSlider> createState() => _PentoscopePieceSliderState();
```

### selectPiece

```dart
void selectPiece(int pieceIndex) {
```

### build

```dart
Widget build(BuildContext context) {
```

### SizedBox

Convertit positionIndex interne en displayPositionIndex pour l'affichage


```dart
return SizedBox( width: fixedSize, height: fixedSize, child: Center( child: Transform.rotate( angle: isLandscape ? -math.pi / 2 : 0.0, child: Container( decoration: BoxDecoration( boxShadow: isSelected ? [ BoxShadow( color: Colors.amber.withOpacity(0.7), blurRadius: 14, spreadRadius: 2, ), ] : null, ), child: DraggablePieceWidget( piece: piece, positionIndex: displayPositionIndex, isSelected: isSelected, selectedPositionIndex: isSelected ? displayPositionIndex : state.selectedPositionIndex, longPressDuration: Duration(milliseconds: settings.game.longPressDuration), onSelect: () {
```

### dispose

```dart
void dispose() {
```

