# pentoscope/screens/pentoscope_game_screen.dart

**Module:** pentoscope

## Fonctions

### PentoscopeGameScreen

⏱️ Formate le temps en secondes (max 999s) - format compact


```dart
const PentoscopeGameScreen({super.key});
```

### createState

```dart
ConsumerState<PentoscopeGameScreen> createState() => _PentoscopeGameScreenState();
```

### SnackBar

Gère l'affichage des messages et vibrations selon le résultat de transformation


```dart
const SnackBar( content: Text('Recentrage'), duration: Duration(seconds: 2), backgroundColor: Colors.orange, ), );
```

### SnackBar

```dart
const SnackBar( content: Text('Transformation impossible'), duration: Duration(seconds: 2), backgroundColor: Colors.red, ), );
```

### build

```dart
Widget build(BuildContext context) {
```

### Scaffold

```dart
return Scaffold( backgroundColor: Colors.white, appBar: isLandscape ? null : PreferredSize( preferredSize: const Size.fromHeight(56.0), child: AppBar( toolbarHeight: 56.0, backgroundColor: Colors.white, automaticallyImplyLeading: false, // 🔑 En mode transformation: pas de leading, les icônes prennent toute la place leading: (isPlacedPieceSelected || isSliderPieceSelected) ? null : Row( mainAxisSize: MainAxisSize.min, children: [ // ⏱️ Chronomètre Text( _formatTime(state.elapsedSeconds), style: const TextStyle( fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black, ), ), ], ), leadingWidth: (isPlacedPieceSelected || isSliderPieceSelected) ? 0 : 60, // 🔑 En mode transformation: icônes isométrie pleine largeur title: (isPlacedPieceSelected || isSliderPieceSelected) ? _buildFullWidthIsometryBar(state, notifier) : state.isComplete ? TweenAnimationBuilder<double>( tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 800), curve: Curves.elasticOut, builder: (context, value, child) {
```

### SizedBox

```dart
const SizedBox(width: 6), Icon(Icons.open_with, size: 14, color: Colors.purple.shade600), Text('${state.translationCount}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
```

### SizedBox

```dart
const SizedBox(width: 6), Icon(Icons.delete_outline, size: 14, color: Colors.red.shade600), Text('${state.deleteCount}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
```

### SizedBox

```dart
const SizedBox(width: 4), Text( '${state.solutionsCount}',
```

### Positioned

```dart
return Positioned( left: currentX, top: currentY, child: GestureDetector( // 🖐️ Drag pour déplacer onPanUpdate: (details) {
```

### SizedBox

```dart
const SizedBox(width: 4), const Text( '👤 Adversaire', style: TextStyle( color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, ), ), ], ), Text( '${_simulateOpponentProgress(state)}/${state.puzzle?.size.numPieces ?? 0}',
```

### Text

```dart
const Text( '👤 Adversaire', style: TextStyle( color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, ), ), ], ), Text( '${_simulateOpponentProgress(state)}/${state.puzzle?.size.numPieces ?? 0}',
```

### Padding

Simule la progression de l'adversaire (pour démo)
Construit le mini-plateau (vue simplifiée)


```dart
return Padding( padding: const EdgeInsets.only(top: 22), // Espace pour le bandeau child: Center( child: SizedBox( width: cellSize * boardWidth, height: cellSize * boardHeight, child: GridView.builder( physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount( crossAxisCount: boardWidth, childAspectRatio: 1.0, ), itemCount: boardWidth * boardHeight, itemBuilder: (context, index) {
```

### Container

```dart
return Container( decoration: BoxDecoration( color: pieceId != null ? settings.ui.getPieceColor(pieceId).withOpacity(0.8) : Colors.grey.shade200, border: Border.all(color: Colors.grey.shade400, width: 0.5), ), );
```

### Row

Simule les pièces de l'adversaire (pour démo)
En mode miroir : affiche les mêmes pièces que nous
Récupère l'ID de la pièce à une position donnée
🔑 Barre d'isométries pleine largeur avec icônes grandes et réparties uniformément


```dart
return Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ // Rotation anti-horaire IconButton( icon: Icon(GameIcons.isometryRotationTW.icon, size: iconSize), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () {
```

### Column

🔑 Barre d'isométries pleine hauteur (mode paysage) avec icônes grandes et réparties


```dart
return Column( mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ // Rotation anti-horaire IconButton( icon: Icon(GameIcons.isometryRotationTW.icon, size: iconSize), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () {
```

### AnimatedContainer

Construit le slider avec DragTarget (drag pièce vers slider = suppression)


```dart
return AnimatedContainer( duration: const Duration(milliseconds: 150), width: width, height: height, decoration: decoration.copyWith( border: isHovering ? Border.all(color: Colors.red.shade400, width: 3) : null, color: isHovering ? Colors.red.shade50 : decoration.color, ), child: Stack( children: [ sliderChild, // Icône poubelle au survol if (isHovering) Positioned.fill( child: IgnorePointer( child: Container( color: Colors.red.withOpacity(0.1), child: Center( child: Container( padding: const EdgeInsets.all(12), decoration: BoxDecoration( color: Colors.red.shade100, shape: BoxShape.circle, ), child: Icon( Icons.delete_outline, color: Colors.red.shade700, size: 32, ), ), ), ), ), ), ], ), );
```

### Column

Layout portrait : plateau en haut, actions + slider en bas


```dart
return Column( children: [ // Plateau de jeu const Expanded(flex: 3, child: PentoscopeBoard(isLandscape: false)),  // Slider de pièces horizontal _buildSliderWithDragTarget( ref: ref, isLandscape: false, height: 160, decoration: BoxDecoration( color: Colors.grey.shade100, boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2), ), ], ), sliderChild: const PentoscopePieceSlider(isLandscape: false), ), ], );
```

### Expanded

```dart
const Expanded(flex: 3, child: PentoscopeBoard(isLandscape: false)),  // Slider de pièces horizontal _buildSliderWithDragTarget( ref: ref, isLandscape: false, height: 160, decoration: BoxDecoration( color: Colors.grey.shade100, boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2), ), ], ), sliderChild: const PentoscopePieceSlider(isLandscape: false), ), ], );
```

### LayoutBuilder

Layout paysage : plateau à gauche, actions + slider vertical à droite


```dart
return LayoutBuilder( builder: (context, constraints) {
```

### Row

```dart
return Row( children: [ // Plateau de jeu const Expanded(child: PentoscopeBoard(isLandscape: true)),  // Colonne de droite : actions + slider Row( children: [ // 🎯 Colonne d'actions (contextuelles) Container( width: actionColumnWidth, decoration: BoxDecoration( color: Colors.white, boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(-1, 0), ), ], ), child: (isPlacedPieceSelected || isSliderPieceSelected) // 🔑 Mode transformation: icônes pleine hauteur, réparties uniformément ? _buildFullHeightIsometryBar(state, notifier, actionColumnWidth) // Mode normal: actions centrées : Column( mainAxisAlignment: MainAxisAlignment.center, children: [ // ⏱️ Chronomètre Padding( padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text( _formatTime(state.elapsedSeconds), style: TextStyle( fontSize: (iconSize * 0.5).clamp(10.0, 16.0), fontWeight: FontWeight.bold, color: Colors.black, ), ), ), // Actions générales (reset, close, hint) IconButton( icon: Icon(Icons.games, size: iconSize), onPressed: () {
```

### Expanded

```dart
const Expanded(child: PentoscopeBoard(isLandscape: true)),  // Colonne de droite : actions + slider Row( children: [ // 🎯 Colonne d'actions (contextuelles) Container( width: actionColumnWidth, decoration: BoxDecoration( color: Colors.white, boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(-1, 0), ), ], ), child: (isPlacedPieceSelected || isSliderPieceSelected) // 🔑 Mode transformation: icônes pleine hauteur, réparties uniformément ? _buildFullHeightIsometryBar(state, notifier, actionColumnWidth) // Mode normal: actions centrées : Column( mainAxisAlignment: MainAxisAlignment.center, children: [ // ⏱️ Chronomètre Padding( padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text( _formatTime(state.elapsedSeconds), style: TextStyle( fontSize: (iconSize * 0.5).clamp(10.0, 16.0), fontWeight: FontWeight.bold, color: Colors.black, ), ), ), // Actions générales (reset, close, hint) IconButton( icon: Icon(Icons.games, size: iconSize), onPressed: () {
```

### Divider

🏆 Bilan affiché à la complétion du puzzle


```dart
const Divider(), const SizedBox(height: 8), _BilanRow(icon: Icons.timer_outlined, label: 'Temps', value: timeStr), const SizedBox(height: 12), _BilanRow(icon: Icons.rotate_right, label: 'Isométries', value: '${state.isometryCount}'),
```

### SizedBox

```dart
const SizedBox(height: 8), _BilanRow(icon: Icons.timer_outlined, label: 'Temps', value: timeStr), const SizedBox(height: 12), _BilanRow(icon: Icons.rotate_right, label: 'Isométries', value: '${state.isometryCount}'),
```

### SizedBox

```dart
const SizedBox(height: 12), _BilanRow(icon: Icons.rotate_right, label: 'Isométries', value: '${state.isometryCount}'),
```

### SizedBox

```dart
const SizedBox(height: 12), _BilanRow(icon: Icons.open_with, label: 'Déplacements', value: '${state.translationCount}'),
```

### SizedBox

```dart
const SizedBox(height: 12), _BilanRow(icon: Icons.delete_outline, label: 'Suppressions', value: '${state.deleteCount}', valueColor: Colors.orange),
```

### SizedBox

```dart
const SizedBox(height: 12), _BilanRow(icon: Icons.lightbulb, label: 'Indices', value: '${state.hintCount}', valueColor: Colors.orange),
```

### SizedBox

```dart
const SizedBox(height: 12), const Divider(), const SizedBox(height: 4), _BilanRow(icon: Icons.stars, label: 'Score', value: '$scorePercent %', valueColor: scoreColor), ], ), actions: [ TextButton( onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'), ), FilledButton.icon( icon: const Icon(Icons.refresh, size: 18), label: const Text('Nouvelle partie'), onPressed: () {
```

### Divider

```dart
const Divider(), const SizedBox(height: 4), _BilanRow(icon: Icons.stars, label: 'Score', value: '$scorePercent %', valueColor: scoreColor), ], ), actions: [ TextButton( onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'), ), FilledButton.icon( icon: const Icon(Icons.refresh, size: 18), label: const Text('Nouvelle partie'), onPressed: () {
```

### SizedBox

```dart
const SizedBox(height: 4), _BilanRow(icon: Icons.stars, label: 'Score', value: '$scorePercent %', valueColor: scoreColor), ], ), actions: [ TextButton( onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'), ), FilledButton.icon( icon: const Icon(Icons.refresh, size: 18), label: const Text('Nouvelle partie'), onPressed: () {
```

### Text

📏 Affiche le dialogue de changement de taille de plateau


```dart
const Text('Sélectionnez la nouvelle taille :'), const SizedBox(height: 16), ...PentoscopeSize.values.map((size) => RadioListTile<PentoscopeSize>( title: Text('${size.label} (${size.width}x${size.height})'),
```

### SizedBox

```dart
const SizedBox(height: 16), ...PentoscopeSize.values.map((size) => RadioListTile<PentoscopeSize>( title: Text('${size.label} (${size.width}x${size.height})'),
```

### build

👥 Navigation vers le mode multijoueur


```dart
Widget build(BuildContext context) {
```

### Row

```dart
return Row( children: [ Icon(icon, size: 20, color: theme.colorScheme.primary), const SizedBox(width: 10), Text(label, style: theme.textTheme.bodyMedium), const Spacer(), Text( value, style: theme.textTheme.titleMedium?.copyWith( fontWeight: FontWeight.bold, color: valueColor ?? theme.colorScheme.primary, ), ), ], );
```

### SizedBox

```dart
const SizedBox(width: 10), Text(label, style: theme.textTheme.bodyMedium), const Spacer(), Text( value, style: theme.textTheme.titleMedium?.copyWith( fontWeight: FontWeight.bold, color: valueColor ?? theme.colorScheme.primary, ), ), ], );
```

### Spacer

```dart
const Spacer(), Text( value, style: theme.textTheme.titleMedium?.copyWith( fontWeight: FontWeight.bold, color: valueColor ?? theme.colorScheme.primary, ), ), ], );
```

