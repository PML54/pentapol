// lib/screens/isometries_demo_screen.dart
// Démonstration pédagogique des isométries avec les pentominos

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pentominos.dart';
import '../providers/settings_provider.dart';

// État pour la démonstration des isométries
class IsometriesDemoState {
  final Map<int, PlacedPieceDemo> bottomPieces; // Pièces ORIGINALES en BAS visuel (lignes 0-4 logiques)
  final Map<int, PlacedPieceDemo> topPieces; // Pièces TRANSFORMÉES en HAUT visuel (lignes 5-9 logiques)
  final int? selectedPieceId; // Pièce sélectionnée sur le plateau
  final int? selectedSliderPieceId; // Pièce sélectionnée dans le slider
  final int? previewPieceId; // Pièce en preview depuis le slider
  final int? previewPosition;
  final int? previewX;
  final int? previewY;
  final String? lastTransformation; // Dernière transformation appliquée

  const IsometriesDemoState({
    this.bottomPieces = const {},
    this.topPieces = const {},
    this.selectedPieceId,
    this.selectedSliderPieceId,
    this.previewPieceId,
    this.previewPosition,
    this.previewX,
    this.previewY,
    this.lastTransformation,
  });

  IsometriesDemoState copyWith({
    Map<int, PlacedPieceDemo>? bottomPieces,
    Map<int, PlacedPieceDemo>? topPieces,
    int? selectedPieceId,
    int? selectedSliderPieceId,
    int? previewPieceId,
    int? previewPosition,
    int? previewX,
    int? previewY,
    String? lastTransformation,
    bool clearSelection = false,
    bool clearSliderSelection = false,
    bool clearPreview = false,
    bool clearTransformation = false,
  }) {
    return IsometriesDemoState(
      bottomPieces: bottomPieces ?? this.bottomPieces,
      topPieces: topPieces ?? this.topPieces,
      selectedPieceId: clearSelection ? null : (selectedPieceId ?? this.selectedPieceId),
      selectedSliderPieceId: clearSliderSelection ? null : (selectedSliderPieceId ?? this.selectedSliderPieceId),
      previewPieceId: clearPreview ? null : (previewPieceId ?? this.previewPieceId),
      previewPosition: clearPreview ? null : (previewPosition ?? this.previewPosition),
      previewX: clearPreview ? null : (previewX ?? this.previewX),
      previewY: clearPreview ? null : (previewY ?? this.previewY),
      lastTransformation: clearTransformation ? null : (lastTransformation ?? this.lastTransformation),
    );
  }
}

// Classe pour représenter une pièce placée
class PlacedPieceDemo {
  final int pieceId;
  final int position;
  final int x;
  final int y;

  const PlacedPieceDemo({
    required this.pieceId,
    required this.position,
    required this.x,
    required this.y,
  });

  PlacedPieceDemo copyWith({int? position, int? x, int? y}) {
    return PlacedPieceDemo(
      pieceId: pieceId,
      position: position ?? this.position,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

// Notifier pour gérer l'état
class IsometriesDemoNotifier extends Notifier<IsometriesDemoState> {
  @override
  IsometriesDemoState build() {
    return const IsometriesDemoState();
  }

  // Placer une pièce dans la zone ORIGINALE (BAS visuel = lignes 0-4 logiques)
  void placePieceInBottom(int pieceId, int position, int x, int y) {
    // Vérifier que c'est bien dans la zone basse visuelle (logique 0-4)
    if (y >= 5) return;

    final piece = pentominos.firstWhere((p) => p.id == pieceId);
    final shape = piece.positions[position];
    
    // Ajuster la position pour qu'elle reste dans [0-4]
    final adjusted = _adjustToBottomZone(x, y, shape);

    final newBottomPieces = Map<int, PlacedPieceDemo>.from(state.bottomPieces);
    newBottomPieces[pieceId] = PlacedPieceDemo(
      pieceId: pieceId,
      position: position,
      x: adjusted['x']!,
      y: adjusted['y']!,
    );

    state = state.copyWith(
      bottomPieces: newBottomPieces,
      clearPreview: true,
      clearSelection: true,
      selectedSliderPieceId: pieceId, // Sélectionner dans le slider
    );
  }

  // Retirer une pièce de la zone basse
  void removePieceFromBottom(int pieceId) {
    final newBottomPieces = Map<int, PlacedPieceDemo>.from(state.bottomPieces);
    newBottomPieces.remove(pieceId);

    state = state.copyWith(
      bottomPieces: newBottomPieces,
      clearSelection: true,
    );
  }

  // Sélectionner une pièce
  void selectPiece(int? pieceId) {
    state = state.copyWith(
      selectedPieceId: pieceId,
      clearSelection: pieceId == null,
    );
  }

  // Mettre à jour le preview
  void updatePreview(int pieceId, int position, int x, int y) {
    state = state.copyWith(
      previewPieceId: pieceId,
      previewPosition: position,
      previewX: x,
      previewY: y,
    );
  }

  // Effacer le preview
  void clearPreview() {
    state = state.copyWith(clearPreview: true);
  }

  // Appliquer une rotation
  void applyRotation() {
    if (state.bottomPieces.isEmpty) return;

    // Si topPieces est vide, on duplique depuis le bas
    // Sinon, on transforme ce qui est déjà en haut
    final sourcePieces = state.topPieces.isEmpty ? state.bottomPieces : state.topPieces;
    final newTopPieces = <int, PlacedPieceDemo>{};

    for (final entry in sourcePieces.entries) {
      final piece = pentominos.firstWhere((p) => p.id == entry.value.pieceId);
      final newPosition = (entry.value.position + 1) % piece.numPositions;

      // Si on duplique depuis le bas, ajuster y: bas (0-4) → haut (5-9)
      int baseY = state.topPieces.isEmpty ? entry.value.y + 5 : entry.value.y;
      int baseX = entry.value.x;

      // Ajuster la position pour qu'elle reste dans la zone haute (5-9)
      final shape = piece.positions[newPosition];
      final adjusted = _adjustToTopZone(baseX, baseY, shape);

      newTopPieces[entry.key] = PlacedPieceDemo(
        pieceId: entry.value.pieceId,
        position: newPosition,
        x: adjusted['x']!,
        y: adjusted['y']!,
      );
    }

    state = state.copyWith(
      topPieces: newTopPieces,
      lastTransformation: 'Rotation 90°',
    );
  }

  // Appliquer une symétrie horizontale
  void applySymmetryH() {
    if (state.bottomPieces.isEmpty) return;

    final sourcePieces = state.topPieces.isEmpty ? state.bottomPieces : state.topPieces;
    final newTopPieces = <int, PlacedPieceDemo>{};

    for (final entry in sourcePieces.entries) {
      final piece = pentominos.firstWhere((p) => p.id == entry.value.pieceId);
      final numPositions = piece.numPositions;
      final newPosition = (entry.value.position + numPositions ~/ 2) % numPositions;

      int baseY = state.topPieces.isEmpty ? entry.value.y + 5 : entry.value.y;
      int baseX = entry.value.x;

      // Ajuster la position pour qu'elle reste dans la zone haute (5-9)
      final shape = piece.positions[newPosition];
      final adjusted = _adjustToTopZone(baseX, baseY, shape);

      newTopPieces[entry.key] = PlacedPieceDemo(
        pieceId: entry.value.pieceId,
        position: newPosition,
        x: adjusted['x']!,
        y: adjusted['y']!,
      );
    }

    state = state.copyWith(
      topPieces: newTopPieces,
      lastTransformation: 'Symétrie H',
    );
  }

  // Appliquer une symétrie verticale
  void applySymmetryV() {
    if (state.bottomPieces.isEmpty) return;

    final sourcePieces = state.topPieces.isEmpty ? state.bottomPieces : state.topPieces;
    final newTopPieces = <int, PlacedPieceDemo>{};

    for (final entry in sourcePieces.entries) {
      final piece = pentominos.firstWhere((p) => p.id == entry.value.pieceId);
      final numPositions = piece.numPositions;
      int newPosition;
      if (numPositions >= 4) {
        newPosition = (entry.value.position + 2) % numPositions;
      } else {
        newPosition = (entry.value.position + 1) % numPositions;
      }

      int baseY = state.topPieces.isEmpty ? entry.value.y + 5 : entry.value.y;
      int baseX = entry.value.x;

      // Ajuster la position pour qu'elle reste dans la zone haute (5-9)
      final shape = piece.positions[newPosition];
      final adjusted = _adjustToTopZone(baseX, baseY, shape);

      newTopPieces[entry.key] = PlacedPieceDemo(
        pieceId: entry.value.pieceId,
        position: newPosition,
        x: adjusted['x']!,
        y: adjusted['y']!,
      );
    }

    state = state.copyWith(
      topPieces: newTopPieces,
      lastTransformation: 'Symétrie V',
    );
  }

  // Ajuster une pièce pour qu'elle reste dans la zone haute (HAUT visuel = 5-9 logiques)
  Map<String, int> _adjustToTopZone(int x, int y, List<int> shape) {
    // Calculer les limites de la pièce
    int minX = 5, maxX = 0, minY = 10, maxY = 0;
    
    for (final cellNumber in shape) {
      final localX = (cellNumber - 1) % 5;
      final localY = (cellNumber - 1) ~/ 5;
      final cellX = x + localX;
      final cellY = y + localY;
      
      if (cellX < minX) minX = cellX;
      if (cellX > maxX) maxX = cellX;
      if (cellY < minY) minY = cellY;
      if (cellY > maxY) maxY = cellY;
    }

    // Ajuster X pour rester dans [0, 5]
    int adjustedX = x;
    if (minX < 0) {
      adjustedX -= minX; // Décaler à droite
    } else if (maxX >= 6) {
      adjustedX -= (maxX - 5); // Décaler à gauche
    }

    // Ajuster Y pour rester dans [5, 9]
    int adjustedY = y;
    if (minY < 5) {
      adjustedY += (5 - minY); // Décaler vers le bas
    } else if (maxY >= 10) {
      adjustedY -= (maxY - 9); // Décaler vers le haut
    }

    return {'x': adjustedX, 'y': adjustedY};
  }

  // Ajuster une pièce pour qu'elle reste dans la zone basse (BAS visuel = 0-4 logiques)
  Map<String, int> _adjustToBottomZone(int x, int y, List<int> shape) {
    // Calculer les limites de la pièce
    int minX = 5, maxX = 0, minY = 5, maxY = 0;
    
    for (final cellNumber in shape) {
      final localX = (cellNumber - 1) % 5;
      final localY = (cellNumber - 1) ~/ 5;
      final cellX = x + localX;
      final cellY = y + localY;
      
      if (cellX < minX) minX = cellX;
      if (cellX > maxX) maxX = cellX;
      if (cellY < minY) minY = cellY;
      if (cellY > maxY) maxY = cellY;
    }

    // Ajuster X pour rester dans [0, 5]
    int adjustedX = x;
    if (minX < 0) {
      adjustedX -= minX; // Décaler à droite
    } else if (maxX >= 6) {
      adjustedX -= (maxX - 5); // Décaler à gauche
    }

    // Ajuster Y pour rester dans [0, 4]
    int adjustedY = y;
    if (minY < 0) {
      adjustedY -= minY; // Décaler vers le bas
    } else if (maxY >= 5) {
      adjustedY -= (maxY - 4); // Décaler vers le haut
    }

    return {'x': adjustedX, 'y': adjustedY};
  }

  // Reset complet
  void reset() {
    state = const IsometriesDemoState();
  }
}

// Provider
final isometriesDemoProvider = NotifierProvider<IsometriesDemoNotifier, IsometriesDemoState>(() {
  return IsometriesDemoNotifier();
});

// Widget principal
class IsometriesDemoScreen extends ConsumerStatefulWidget {
  const IsometriesDemoScreen({super.key});

  @override
  ConsumerState<IsometriesDemoScreen> createState() => _IsometriesDemoScreenState();
}

class _IsometriesDemoScreenState extends ConsumerState<IsometriesDemoScreen> {
  final ScrollController _sliderController = ScrollController();

  @override
  void dispose() {
    _sliderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(isometriesDemoProvider);
    final notifier = ref.read(isometriesDemoProvider.notifier);
    final settings = ref.watch(settingsProvider);

    // Détecter l'orientation
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: isLandscape ? null : PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: AppBar(
          toolbarHeight: 56.0,
          title: state.lastTransformation != null
              ? Text(
                  state.lastTransformation!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const SizedBox.shrink(),
          backgroundColor: Colors.indigo,
          actions: [
            // Bouton Rotation
            IconButton(
              icon: Icon(
                Icons.rotate_right,
                size: 24,
                color: state.bottomPieces.isNotEmpty ? Colors.blue[400] : Colors.grey[600],
              ),
              tooltip: 'Rotation 90°',
              onPressed: state.bottomPieces.isNotEmpty
                  ? () {
                      HapticFeedback.selectionClick();
                      notifier.applyRotation();
                    }
                  : null,
            ),
            // Bouton Symétrie H
            IconButton(
              icon: Icon(
                Icons.swap_horiz,
                size: 24,
                color: state.bottomPieces.isNotEmpty ? Colors.green[400] : Colors.grey[600],
              ),
              tooltip: 'Symétrie Horizontale',
              onPressed: state.bottomPieces.isNotEmpty
                  ? () {
                      HapticFeedback.selectionClick();
                      notifier.applySymmetryH();
                    }
                  : null,
            ),
            // Bouton Symétrie V
            IconButton(
              icon: Icon(
                Icons.swap_vert,
                size: 24,
                color: state.bottomPieces.isNotEmpty ? Colors.orange[400] : Colors.grey[600],
              ),
              tooltip: 'Symétrie Verticale',
              onPressed: state.bottomPieces.isNotEmpty
                  ? () {
                      HapticFeedback.selectionClick();
                      notifier.applySymmetryV();
                    }
                  : null,
            ),
            // Bouton Reset
            IconButton(
              icon: const Icon(Icons.refresh, size: 24),
              tooltip: 'Reset',
              onPressed: () {
                HapticFeedback.mediumImpact();
                notifier.reset();
              },
            ),
          ],
        ),
      ),
      body: isLandscape
          ? _buildLandscapeLayout(context, state, notifier, settings)
          : _buildPortraitLayout(context, state, notifier, settings),
    );
  }

  // Layout portrait : plateau au milieu, slider en bas
  Widget _buildPortraitLayout(
    BuildContext context,
    IsometriesDemoState state,
    IsometriesDemoNotifier notifier,
    settings,
  ) {
    return Column(
      children: [
        // Plateau
        Expanded(
          child: _buildPlateau(context, state, notifier, settings, isLandscape: false),
        ),

        // Slider de pièces
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: _buildPieceSlider(state, notifier, settings, isLandscape: false),
        ),
      ],
    );
  }

  // Layout paysage : plateau à gauche, actions + slider à droite (comme le jeu)
  Widget _buildLandscapeLayout(
    BuildContext context,
    IsometriesDemoState state,
    IsometriesDemoNotifier notifier,
    settings,
  ) {
    return Row(
      children: [
        // Plateau (10x6)
        Expanded(
          child: _buildPlateau(context, state, notifier, settings, isLandscape: true),
        ),

        // Colonne de droite : actions + slider
        Row(
          children: [
            // Slider d'actions vertical
            Container(
              width: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(-1, 0),
                  ),
                ],
              ),
              child: _buildActionSlider(context, state, notifier),
            ),

            // Slider de pièces vertical
            Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: _buildPieceSlider(state, notifier, settings, isLandscape: true),
            ),
          ],
        ),
      ],
    );
  }

  // Slider d'actions vertical (mode paysage uniquement)
  Widget _buildActionSlider(
    BuildContext context,
    IsometriesDemoState state,
    IsometriesDemoNotifier notifier,
  ) {
    final hasBottomPieces = state.bottomPieces.isNotEmpty;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Transformation affichée
        if (state.lastTransformation != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Transform.rotate(
              angle: -1.5708, // Texte tourné
              child: Text(
                state.lastTransformation!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Bouton Rotation
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasBottomPieces
                ? () {
                    HapticFeedback.selectionClick();
                    notifier.applyRotation();
                  }
                : null,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Icon(
                Icons.rotate_right,
                size: 24,
                color: hasBottomPieces ? Colors.blue[400] : Colors.grey[600],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Bouton Symétrie H
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasBottomPieces
                ? () {
                    HapticFeedback.selectionClick();
                    notifier.applySymmetryH();
                  }
                : null,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Icon(
                Icons.swap_horiz,
                size: 24,
                color: hasBottomPieces ? Colors.green[400] : Colors.grey[600],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Bouton Symétrie V
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasBottomPieces
                ? () {
                    HapticFeedback.selectionClick();
                    notifier.applySymmetryV();
                  }
                : null,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Icon(
                Icons.swap_vert,
                size: 24,
                color: hasBottomPieces ? Colors.orange[400] : Colors.grey[600],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Bouton Reset
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              notifier.reset();
            },
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: const Icon(
                Icons.refresh,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlateau(
    BuildContext context,
    IsometriesDemoState state,
    IsometriesDemoNotifier notifier,
    settings, {
    required bool isLandscape,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final plateauWidth = constraints.maxWidth;
        final plateauHeight = constraints.maxHeight;
        
        // En paysage : 10x6, en portrait : 6x10
        final int visualCols = isLandscape ? 10 : 6;
        final int visualRows = isLandscape ? 6 : 10;
        
        final cellWidth = plateauWidth / visualCols;
        final cellHeight = plateauHeight / visualRows;

        return Stack(
          children: [
            // Grille de fond
            _buildGrid(plateauWidth, plateauHeight, cellWidth, cellHeight, visualCols, visualRows),

            // Ligne de séparation (horizontale en portrait, verticale en paysage)
            if (isLandscape)
              Positioned(
                left: plateauWidth / 2,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: Colors.red[700],
                ),
              )
            else
              Positioned(
                left: 0,
                right: 0,
                top: plateauHeight / 2,
                child: Container(
                  height: 3,
                  color: Colors.red[700],
                ),
              ),

            // Pièces de la zone basse
            ...state.bottomPieces.values.map((placed) {
              return _buildPlacedPiece(
                placed,
                cellWidth,
                cellHeight,
                settings,
                notifier,
                isBottom: true,
              );
            }),

            // Pièces de la zone haute (transformées)
            ...state.topPieces.values.map((placed) {
              return _buildPlacedPiece(
                placed,
                cellWidth,
                cellHeight,
                settings,
                notifier,
                isBottom: false,
              );
            }),

            // Preview
            if (state.previewPieceId != null &&
                state.previewPosition != null &&
                state.previewX != null &&
                state.previewY != null)
              _buildPreview(
                state.previewPieceId!,
                state.previewPosition!,
                state.previewX!,
                state.previewY!,
                cellWidth,
                cellHeight,
                settings,
              ),

            // Zones de drop (grille invisible pour drag & drop)
            ...List.generate(6, (col) {
              return List.generate(5, (row) {
                // Zone basse visuelle = lignes logiques 0-4
                final logicalY = row;
                // Conversion visuelle : y inversé (ligne 4 devient 5, ligne 0 devient 9)
                final visualY = 9 - logicalY;
                
                return Positioned(
                  left: col * cellWidth,
                  top: visualY * cellHeight,
                  width: cellWidth,
                  height: cellHeight,
                  child: DragTarget<Map<String, dynamic>>(
                    onWillAcceptWithDetails: (details) {
                      final data = details.data;
                      notifier.updatePreview(
                        data['pieceId'],
                        data['position'],
                        col,
                        logicalY,
                      );
                      return true;
                    },
                    onLeave: (_) {
                      notifier.clearPreview();
                    },
                    onAcceptWithDetails: (details) {
                      final data = details.data;
                      notifier.placePieceInBottom(
                        data['pieceId'],
                        data['position'],
                        col,
                        logicalY,
                      );
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Container(); // Invisible
                    },
                  ),
                );
              });
            }).expand((list) => list),
          ],
        );
      },
    );
  }

  Widget _buildGrid(double width, double height, double cellWidth, double cellHeight, int cols, int rows) {
    return CustomPaint(
      size: Size(width, height),
      painter: _GridPainter(
        cellWidth: cellWidth,
        cellHeight: cellHeight,
        cols: cols,
        rows: rows,
      ),
    );
  }

  Widget _buildPlacedPiece(
    PlacedPieceDemo placed,
    double cellWidth,
    double cellHeight,
    settings,
    IsometriesDemoNotifier notifier,
    {required bool isBottom}
  ) {
    final piece = pentominos.firstWhere((p) => p.id == placed.pieceId);
    final shape = piece.positions[placed.position];
    final pieceColor = settings.ui.getPieceColor(placed.pieceId);

    return Stack(
      children: shape.map((cellNumber) {
        final localX = (cellNumber - 1) % 5;
        final localY = (cellNumber - 1) ~/ 5;
        final x = placed.x + localX;
        final y = placed.y + localY;

        // Conversion visuelle (y inversé)
        final visualY = 9 - y;

        return Positioned(
          left: x * cellWidth,
          top: visualY * cellHeight,
          width: cellWidth,
          height: cellHeight,
          child: GestureDetector(
            onTap: isBottom
                ? () {
                    HapticFeedback.selectionClick();
                    notifier.selectPiece(placed.pieceId);
                  }
                : null,
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: isBottom ? pieceColor : pieceColor.withValues(alpha: 0.7),
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Text(
                  placed.pieceId.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreview(
    int pieceId,
    int position,
    int x,
    int y,
    double cellWidth,
    double cellHeight,
    settings,
  ) {
    final piece = pentominos.firstWhere((p) => p.id == pieceId);
    final shape = piece.positions[position];
    final pieceColor = settings.ui.getPieceColor(pieceId);

    return Stack(
      children: shape.map((cellNumber) {
        final localX = (cellNumber - 1) % 5;
        final localY = (cellNumber - 1) ~/ 5;
        final cellX = x + localX;
        final cellY = y + localY;

        final visualY = 9 - cellY;

        return Positioned(
          left: cellX * cellWidth,
          top: visualY * cellHeight,
          width: cellWidth,
          height: cellHeight,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: pieceColor.withValues(alpha: 0.3),
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPieceSlider(
    IsometriesDemoState state,
    IsometriesDemoNotifier notifier,
    settings, {
    required bool isLandscape,
  }) {
    return ListView.builder(
      controller: _sliderController,
      scrollDirection: isLandscape ? Axis.vertical : Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: pentominos.length,
      itemBuilder: (context, index) {
        final piece = pentominos[index];
        final pieceColor = settings.ui.getPieceColor(piece.id);
        final isSelected = state.selectedSliderPieceId == piece.id;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 0 : 4,
            vertical: isLandscape ? 4 : 0,
          ),
          child: Draggable<Map<String, dynamic>>(
            data: {
              'pieceId': piece.id,
              'position': 0,
            },
            feedback: _buildDraggableFeedback(piece, pieceColor, isLandscape: isLandscape),
            childWhenDragging: _buildPieceWidget(
              piece,
              pieceColor,
              isDragging: true,
              isSelected: false,
              isLandscape: isLandscape,
            ),
            onDragStarted: () {
              HapticFeedback.mediumImpact();
            },
            onDragEnd: (details) {
              notifier.clearPreview();
            },
            child: _buildPieceWidget(
              piece,
              pieceColor,
              isSelected: isSelected,
              isLandscape: isLandscape,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieceWidget(
    Pento piece,
    Color pieceColor, {
    bool isDragging = false,
    bool isSelected = false,
    required bool isLandscape,
  }) {
    Widget content = Container(
      width: 70,
      decoration: BoxDecoration(
        color: isDragging
            ? Colors.grey[300]
            : (isSelected ? pieceColor.withValues(alpha: 0.2) : Colors.white),
        border: Border.all(
          color: isSelected ? pieceColor : Colors.grey,
          width: isSelected ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            piece.id.toString(),
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
              fontSize: 14,
              color: isSelected ? pieceColor : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: _buildMiniPiecePreview(piece, pieceColor),
          ),
        ],
      ),
    );

    // En paysage, rotation de 90° anti-horaire
    if (isLandscape) {
      return Transform.rotate(
        angle: -1.5708, // -90° en radians
        child: content,
      );
    }
    return content;
  }

  Widget _buildDraggableFeedback(Pento piece, Color pieceColor, {required bool isLandscape}) {
    Widget content = Material(
      color: Colors.transparent,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: pieceColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            piece.id.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    // En paysage, rotation de 90° anti-horaire
    if (isLandscape) {
      return Transform.rotate(
        angle: -1.5708,
        child: content,
      );
    }
    return content;
  }

  Widget _buildMiniPiecePreview(Pento piece, Color pieceColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final cellSize = size / 5;

        return Stack(
          children: piece.baseShape.map((cellNumber) {
            final localX = (cellNumber - 1) % 5;
            final localY = (cellNumber - 1) ~/ 5;

            return Positioned(
              left: localX * cellSize,
              top: (4 - localY) * cellSize,
              width: cellSize,
              height: cellSize,
              child: Container(
                margin: const EdgeInsets.all(0.5),
                decoration: BoxDecoration(
                  color: pieceColor,
                  border: Border.all(color: Colors.black, width: 0.5),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final double cellWidth;
  final double cellHeight;
  final int cols;
  final int rows;

  _GridPainter({
    required this.cellWidth,
    required this.cellHeight,
    required this.cols,
    required this.rows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    // Lignes verticales
    for (int i = 0; i <= cols; i++) {
      final x = i * cellWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Lignes horizontales
    for (int i = 0; i <= rows; i++) {
      final y = i * cellHeight;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.cols != cols || oldDelegate.rows != rows;
}
