# pentapol - Documentation

*Pentapol - Analyse du code Flutter/Dart*

## Modules

- **common** (15 fichiers)
- **config** (4 fichiers)
- **database** (2 fichiers)
- **debug** (1 fichiers)
- **main.dart** (1 fichiers)
- **models** (1 fichiers)
- **pentoscope** (9 fichiers)
- **pentoscope_multiplayer** (6 fichiers)
- **providers** (1 fichiers)
- **screens** (3 fichiers)
- **services** (3 fichiers)
- **utils** (5 fichiers)

---

## Module: common

### common/bigint_plateau.dart

**Fonctions :**

- `placePiece()`
- `ArgumentError()`
- `ArgumentError()`
- `clearCells()`
- `ArgumentError()`
- `getCell()`
- `ArgumentError()`

### common/game_colors.dart

**Fonctions :**

- `getPieceColorFallback()`

### common/game_piece.dart

**Fonctions :**

- `GamePiece()`
- `shapeToCoordinates()`
- `Point()`
- `shapeToCoordinates()`
- `Point()`
- `rotate()`
- `GamePiece()`
- `place()`
- `GamePiece()`
- `unplace()`
- `GamePiece()`

### common/game_timer_mixin.dart

**Fonctions :**

- `stateWithElapsedSeconds()`
- `startTimer()`
- `stopTimer()`
- `resetTimer()`
- `getElapsedSeconds()`

### common/pentomino_game_mixin.dart

**Fonctions :**

- `canPlacePiece()`
- `coordsInPositionOrder()`
- `Point()`
- `getRawMastercaseCoords()`
- `Point()`
- `Point()`
- `calculateAnchorPosition()`
- `Point()`
- `Point()`

### common/pentomino_symmetry_api.dart

**Fonctions :**

- `applyRotationAbs()`
- `Point()`
- `Point()`
- `applySymmetryAbs()`
- `Point()`
- `Point()`
- `normalizeCoords()`
- `findOrientationIndexFromNormalized()`

### common/pentominos.dart

**Fonctions :**

- `Pento()`
- `findRotation90()`
- `findSymmetryH()`
- `findSymmetryV()`
- `getLetter()`
- `getLetterForPosition()`
- `rotate180()`
- `rotationCW()`
- `rotationTW()`
- `symmetryH()`
- `symmetryV()`
- `symmetryHRelativeToMastercase()`
- `symmetryVRelativeToMastercase()`
- `minIsometriesToReach()`

### common/piece_interaction_mixin.dart

**Fonctions :**

- `stateWithDragging()`
- `stateWithPreviewCleared()`
- `setDragging()`
- `clearPreview()`

### common/placed_piece.dart

**Fonctions :**

- `PlacedPiece()`
- `Point()`
- `copyWith()`
- `PlacedPiece()`
- `toString()`
- `getOccupiedCells()`

### common/plateau.dart

**Fonctions :**

- `Plateau()`
- `Plateau()`
- `Plateau()`
- `isInBounds()`
- `getCell()`
- `setCell()`
- `copy()`
- `Plateau()`

### common/point.dart

**Fonctions :**

- `Point()`
- `toString()`

### common/shape_recognizer.dart

**Fonctions :**

- `ShapeMatch()`
- `toString()`
- `ShapeMatch()`

### common/widgets/draggable_piece_widget.dart

**Fonctions :**

- `DraggablePieceWidget()`
- `createState()`
- `dispose()`
- `build()`

### common/widgets/piece_border_calculator.dart

**Fonctions :**

- `calculate()`
- `neighborId()`
- `Border()`
- `Border()`

### common/widgets/piece_renderer.dart

**Fonctions :**

- `PieceRenderer()`
- `build()`
- `Container()`

---

## Module: config

### config/game_icons_config.dart

**Fonctions :**

- `GameIconConfig()`
- `isVisibleIn()`
- `getIconsForMode()`

### config/ui_dimensions.dart

**Fonctions :**

- `BoardDimensions()`
- `SliderDimensions()`
- `ActionBarDimensions()`
- `TextDimensions()`
- `UILayout()`

### config/ui_layout_manager.dart

**Fonctions :**

- `calculate()`
- `UILayout()`
- `ActionBarDimensions()`
- `SliderDimensions()`
- `BoardDimensions()`
- `TextDimensions()`
- `fromContext()`
- `calculate()`
- `fromConstraints()`
- `calculate()`

### config/ui_layout_provider.dart

**Fonctions :**

- `UILayoutState()`
- `UILayoutState()`
- `copyWith()`
- `UILayoutState()`
- `build()`
- `updateScreenSize()`
- `updateBoardSize()`
- `recalculate()`
- `UILayoutNotifier()`
- `UILayoutInitializer()`
- `createState()`
- `didChangeDependencies()`
- `build()`
- `calculateLayout()`
- `calculateBoardDimensions()`
- `calculateLayout()`
- `calculateSliderDimensions()`
- `calculateLayout()`
- `calculateActionBarDimensions()`
- `calculateLayout()`

---

## Module: database

### database/settings_database.dart

**Fonctions :**

- `LazyDatabase()`
- `NativeDatabase()`
- `getSetting()`
- `setSetting()`
- `into()`
- `deleteSetting()`
- `clearAllSettings()`
- `delete()`
- `saveGameSession()`
- `into()`
- `getFastestCompletion()`
- `getHighestScore()`
- `getTotalSessionsCount()`
- `getUniqueSolutionsCount()`
- `getSolutionStats()`
- `update()`
- `into()`

### database/settings_database.g.dart

**Fonctions :**

- `validateIntegrity()`
- `map()`
- `Setting()`
- `Setting()`
- `toColumns()`
- `toCompanion()`
- `SettingsCompanion()`
- `Setting()`
- `toJson()`
- `copyWith()`
- `copyWithCompanion()`
- `Setting()`
- `toString()`
- `SettingsCompanion()`
- `custom()`
- `RawValuesInsertable()`
- `copyWith()`
- `SettingsCompanion()`
- `toColumns()`
- `toString()`
- `VerificationMeta()`
- `validateIntegrity()`
- `map()`
- `GameSession()`
- `GameSession()`
- `toColumns()`
- `toCompanion()`
- `GameSessionsCompanion()`
- `GameSession()`
- `toJson()`
- `copyWith()`
- `copyWithCompanion()`
- `GameSession()`
- `toString()`
- `GameSessionsCompanion()`
- `custom()`
- `RawValuesInsertable()`
- `copyWith()`
- `GameSessionsCompanion()`
- `toColumns()`
- `toString()`
- `validateIntegrity()`
- `map()`
- `SolutionStat()`
- `SolutionStat()`
- `toColumns()`
- `toCompanion()`
- `SolutionStatsCompanion()`
- `SolutionStat()`
- `toJson()`
- `copyWith()`
- `copyWithCompanion()`
- `SolutionStat()`
- `toString()`
- `SolutionStatsCompanion()`
- `custom()`
- `RawValuesInsertable()`
- `copyWith()`
- `SolutionStatsCompanion()`
- `toColumns()`
- `toString()`
- `DriftDatabaseOptions()`
- `Function()`
- `Function()`
- `Function()`
- `Function()`
- `Function()`
- `Function()`
- `Function()`
- `Function()`
- `Function()`
- `Function()`
- `Function()`
- `Function()`

---

## Module: debug

### debug/database_debug_screen.dart

**Fonctions :**

- `DatabaseDebugScreen()`
- `createState()`
- `build()`
- `Scaffold()`
- `Text()`
- `Column()`
- `Text()`
- `Column()`
- `Container()`
- `Column()`
- `SizedBox()`
- `Row()`
- `Row()`
- `SnackBar()`

---

## Module: main.dart

### main.dart

**Fonctions :**

- `main()`
- `PentapolApp()`
- `createState()`
- `initState()`
- `build()`
- `MaterialApp()`

---

## Module: models

### models/app_settings.dart

**Fonctions :**

- `UISettings()`
- `copyWith()`
- `UISettings()`
- `getPieceColor()`
- `toJson()`
- `UISettings()`
- `GameSettings()`
- `copyWith()`
- `GameSettings()`
- `toJson()`
- `GameSettings()`
- `DuelSettings()`
- `copyWith()`
- `DuelSettings()`
- `recordGame()`
- `copyWith()`
- `resetStats()`
- `copyWith()`
- `toJson()`
- `DuelSettings()`
- `AppSettings()`
- `copyWith()`
- `AppSettings()`
- `toJson()`
- `AppSettings()`

---

## Module: pentoscope

### pentoscope/pentoscope_generator.dart

**Fonctions :**

- `generate()`
- `PentoscopePuzzle()`
- `generateEasy()`
- `PentoscopePuzzle()`
- `generateHard()`
- `PentoscopePuzzle()`
- `generateFromSeed()`
- `PentoscopePuzzle()`
- `PentoscopePuzzle()`
- `toString()`
- `SolutionTable()`
- `PentoscopeSize()`
- `PentoscopeStats()`
- `toString()`

### pentoscope/pentoscope_provider.dart

**Fonctions :**

- `stateWithDragging()`
- `stateWithPreviewCleared()`
- `stateWithElapsedSeconds()`
- `canPlacePiece()`
- `applyIsometryRotationCW()`
- `applyIsometryRotationTW()`
- `applyIsometrySymmetryH()`
- `applyIsometrySymmetryV()`
- `build()`
- `TableSolutionSource()`
- `compatibleSolutions()`
- `calculateNote()`
- `applyHint()`
- `cancelSelection()`
- `cycleToNextOrientation()`
- `removePlacedPiece()`
- `reset()`
- `selectPiece()`
- `selectPlacedPiece()`
- `Point()`
- `setViewOrientation()`
- `startPuzzle()`
- `startPuzzleFromSeed()`
- `changeBoardSize()`
- `startPuzzle()`
- `tryPlacePiece()`
- `updatePreview()`
- `Point()`
- `Point()`
- `Point()`
- `Point()`
- `Point()`
- `Point()`
- `Point()`
- `Point()`
- `Point()`
- `calculateDefaultCell()`
- `Point()`
- `Point()`
- `Point()`
- `Point()`
- `remapSelectedCell()`
- `PentoscopeState()`
- `PentoscopeState()`
- `canPlacePiece()`
- `copyWith()`
- `PentoscopeState()`
- `getPiecePositionIndex()`

### pentoscope/pentoscope_solver.dart

**Fonctions :**

- `SolverPlacement()`
- `toString()`
- `findFirstSolution()`
- `findAllSolutions()`
- `backtrackAll()`
- `SolverResult()`
- `canSolveFrom()`
- `SolverResult()`
- `toString()`

### pentoscope/screens/pentoscope_game_screen.dart

**Fonctions :**

- `PentoscopeGameScreen()`
- `createState()`
- `SnackBar()`
- `SnackBar()`
- `build()`
- `Scaffold()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `Positioned()`
- `SizedBox()`
- `Text()`
- `Padding()`
- `Container()`
- `Row()`
- `Column()`
- `AnimatedContainer()`
- `Column()`
- `Expanded()`
- `LayoutBuilder()`
- `Row()`
- `Expanded()`
- `Divider()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `Divider()`
- `SizedBox()`
- `Text()`
- `SizedBox()`
- `build()`
- `Row()`
- `SizedBox()`
- `Spacer()`

### pentoscope/screens/pentoscope_menu_screen.dart

**Fonctions :**

- `PentoscopeMenuScreen()`
- `createState()`
- `build()`
- `Scaffold()`
- `Text()`
- `SizedBox()`
- `SizedBox()`
- `Text()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `Row()`
- `Expanded()`
- `SizedBox()`

### pentoscope/screens/solutions_browser_screen.dart

**Fonctions :**

- `createState()`
- `initState()`
- `build()`
- `Scaffold()`
- `Scaffold()`
- `SizedBox()`
- `SizedBox()`
- `Container()`
- `Container()`
- `SizedBox()`
- `SizedBox()`
- `Divider()`
- `SizedBox()`
- `SizedBox()`
- `neighborId()`
- `Border()`
- `Border()`

### pentoscope/solution_source.dart

**Fonctions :**

- `hasSolutionFrom()`
- `compatibleSolutions()`
- `hasSolutionFrom()`
- `compatibleSolutions()`
- `hasSolutionFrom()`
- `compatibleSolutions()`

### pentoscope/widgets/pentoscope_board.dart

**Fonctions :**

- `PentoscopeBoard()`
- `createState()`
- `build()`
- `LayoutBuilder()`
- `Align()`

### pentoscope/widgets/pentoscope_piece_slider.dart

**Fonctions :**

- `PentoscopePieceSlider()`
- `createState()`
- `selectPiece()`
- `build()`
- `SizedBox()`
- `dispose()`

---

## Module: pentoscope_multiplayer

### pentoscope_multiplayer/models/pentoscope_mp_messages.dart

**Fonctions :**

- `toJson()`
- `encode()`
- `toJson()`
- `toJson()`
- `toJson()`
- `toJson()`
- `toJson()`
- `PlacedPieceSummary()`
- `toJson()`
- `toJson()`
- `fromJson()`
- `RoomCreatedMessage()`
- `RoomJoinedMessage()`
- `PlayerInfo()`
- `PlayerJoinedMessage()`
- `PlayerLeftMessage()`
- `PuzzleReadyMessage()`
- `CountdownMessage()`
- `GameStartMessage()`
- `OpponentProgressMessage()`
- `PlayerCompletedMessage()`
- `GameEndMessage()`
- `RankingEntry()`
- `ErrorMessage()`

### pentoscope_multiplayer/models/pentoscope_mp_state.dart

**Fonctions :**

- `MPPlacedPiece()`
- `MPPlacedPiece()`
- `MPPlayer()`
- `copyWith()`
- `MPPlayer()`
- `toString()`
- `MPGameConfig()`
- `MPGameConfig()`
- `MPGameConfig()`
- `toPentoscopeSize()`
- `toString()`
- `PentoscopeMPState()`
- `copyWith()`
- `PentoscopeMPState()`
- `toString()`

### pentoscope_multiplayer/providers/pentoscope_mp_provider.dart

**Fonctions :**

- `build()`
- `createRoom()`
- `Exception()`
- `Duration()`
- `joinRoom()`
- `Exception()`
- `Exception()`
- `Duration()`
- `leaveRoom()`
- `startGame()`
- `updateProgress()`
- `complete()`
- `startTimer()`
- `stopTimer()`
- `getElapsedSeconds()`

### pentoscope_multiplayer/screens/pentoscope_mp_game_screen.dart

**Fonctions :**

- `PentoscopeMPGameScreen()`
- `createState()`
- `initState()`
- `build()`
- `Scaffold()`
- `Container()`
- `Row()`
- `Padding()`
- `SizedBox()`
- `Positioned()`
- `AnimatedContainer()`
- `Container()`
- `SizedBox()`
- `Icon()`
- `Column()`
- `Row()`
- `SizedBox()`
- `SizedBox()`
- `Spacer()`
- `Spacer()`
- `Row()`
- `Column()`

### pentoscope_multiplayer/screens/pentoscope_mp_lobby_screen.dart

**Fonctions :**

- `PentoscopeMPLobbyScreen()`
- `createState()`
- `initState()`
- `SnackBar()`
- `dispose()`
- `build()`
- `Scaffold()`
- `SingleChildScrollView()`
- `SizedBox()`
- `Column()`
- `SnackBar()`
- `SizedBox()`
- `Column()`
- `SizedBox()`
- `Padding()`
- `SizedBox()`
- `SizedBox()`
- `Text()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `Container()`
- `Text()`
- `SizedBox()`
- `SizedBox()`
- `SnackBar()`
- `SizedBox()`
- `Text()`
- `Container()`
- `Column()`
- `SizedBox()`
- `Container()`
- `SizedBox()`
- `Center()`
- `Icon()`
- `SizedBox()`
- `SizedBox()`
- `SnackBar()`
- `SnackBar()`
- `formatEditUpdate()`
- `TextEditingValue()`

### pentoscope_multiplayer/screens/pentoscope_mp_result_screen.dart

**Fonctions :**

- `PentoscopeMPResultScreen()`
- `build()`
- `Scaffold()`
- `SizedBox()`
- `Text()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `Container()`
- `SizedBox()`
- `SizedBox()`
- `Padding()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `Column()`
- `SizedBox()`
- `SizedBox()`
- `Container()`
- `SizedBox()`
- `Text()`

---

## Module: providers

### providers/settings_provider.dart

**Fonctions :**

- `SettingsDatabase()`
- `SettingsNotifier()`
- `build()`
- `recordDuelGame()`
- `resetDuelSettings()`
- `resetDuelStats()`
- `resetToDefaults()`
- `setColorScheme()`
- `setCustomColors()`
- `setDifficulty()`
- `setDuelCustomDuration()`
- `setDuelDuration()`
- `setDuelGuideOpacity()`
- `setDuelHatchOpacity()`
- `setDuelPlayerName()`
- `setDuelShowGuide()`
- `setDuelShowHatch()`
- `setDuelShowOpponentProgress()`
- `setDuelShowPieceNumbers()`
- `setDuelSounds()`
- `setDuelVibration()`
- `setEnableAnimations()`
- `setEnableHaptics()`
- `setEnableHints()`
- `setEnableTimer()`
- `setIconSize()`
- `setIsometriesAppBarColor()`
- `setLongPressDuration()`
- `setPieceOpacity()`
- `setShowGridLines()`
- `setShowPieceNumbers()`
- `setShowSolutionCounter()`

---

## Module: screens

### screens/custom_colors_screen.dart

**Fonctions :**

- `CustomColorsScreen()`
- `createState()`
- `initState()`
- `build()`
- `Scaffold()`
- `Card()`
- `SizedBox()`
- `GestureDetector()`

### screens/home_screen.dart

**Fonctions :**

- `HomeScreen()`
- `build()`
- `Scaffold()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `build()`
- `Material()`
- `build()`
- `Material()`
- `SizedBox()`
- `SizedBox()`
- `Icon()`

### screens/settings_screen.dart

**Fonctions :**

- `SettingsScreen()`
- `build()`
- `Scaffold()`
- `Divider()`
- `Divider()`
- `Divider()`
- `SizedBox()`
- `ListTile()`
- `Icon()`
- `SizedBox()`
- `Text()`
- `Spacer()`
- `SizedBox()`
- `SizedBox()`
- `Text()`
- `SizedBox()`
- `ChoiceChip()`
- `SizedBox()`
- `Text()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `SizedBox()`
- `Column()`
- `SizedBox()`
- `ListTile()`
- `SizedBox()`
- `Text()`
- `Divider()`
- `SizedBox()`
- `Padding()`
- `Padding()`
- `Color()`
- `Color()`
- `Color()`
- `Color()`
- `Color()`
- `Color()`
- `Color()`
- `Color()`
- `Color()`
- `Color()`
- `Color()`
- `Color()`
- `GestureDetector()`

---

## Module: services

### services/pentapol_solutions_loader.dart

**Fonctions :**

- `StateError()`

### services/pentomino_solver.dart

**Fonctions :**

- `hasSolution()`
- `findSolution()`
- `ArgumentError()`
- `areIsolatedRegionsValid()`
- `backtrack()`
- `backtrackFromPosition()`
- `backtrack()`
- `canAnyAvailablePieceFitRegion()`
- `canPlaceWithOffset()`
- `countAllSolutions()`
- `countRecursive()`
- `countRecursive()`
- `countRecursive()`
- `Function()`
- `searchRecursive()`
- `searchRecursive()`
- `searchRecursive()`
- `findSmallestFreeCell()`
- `floodFillAndCollect()`
- `placeWithOffset()`
- `removeWithOffset()`
- `stopCounting()`
- `tryNextPlacements()`
- `toString()`

### services/solution_matcher.dart

**Fonctions :**

- `SolutionInfo()`
- `toString()`
- `initWithBigIntSolutions()`
- `StateError()`
- `ArgumentError()`
- `countCompatibleFromBigInts()`
- `getCompatibleSolutionsFromBigInts()`
- `getCompatibleSolutionIndices()`
- `findSolutionIndex()`
- `solutionToPlacedPieces()`
- `solutionToPlacedPieces()`

---

## Module: utils

### utils/pentomino_geometry.dart

**Fonctions :**

- `Point2D()`
- `toString()`
- `cellNumberToCoords()`
- `Point2D()`
- `calculateBarycenter()`
- `Point2D()`
- `getPieceRotationCenter()`
- `calculateBarycenter()`
- `PentominoGeometry()`
- `describeTransformation()`
- `toOffset()`

### utils/piece_utils.dart

**Fonctions :**

- `getPieceName()`
- `getDefaultPieceColor()`
- `PiecePreview()`
- `build()`
- `SizedBox()`
- `Positioned()`
- `PieceIcon()`
- `build()`
- `Container()`
- `getColorHex()`
- `getPredefinedColors()`

### utils/solution_collector.dart

**Fonctions :**

- `onSolutionFound()`
- `finalize()`
- `collectAllSolutions()`

### utils/solution_exporter.dart

**Fonctions :**

- `empty()`
- `PentominoSolution()`
- `toString()`
- `addSolution()`
- `saveToFile()`
- `saveCompact()`
- `saveDartCode()`
- `placementsToGrid()`
- `PentominoSolution()`
- `main()`

### utils/time_format.dart

**Fonctions :**

- `formatMillis()`

