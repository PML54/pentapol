// lib/screens/isometries_demo_screen.dart
// Démonstration pédagogique des isométries avec les pentominos

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pentominos.dart';
import '../providers/settings_provider.dart';

// État pour la démonstration des isométries
class IsometriesDemoState {
  final Map<int, PlacedPieceDemo> bottomPieces; // Pièces dans zone basse (lignes 5-9)
  final Map<int, PlacedPieceDemo> topPieces; // Pièces transformées dans zone haute (lignes 0-4)
  final int? selectedPieceId; // Pièce sélectionnée sur le plateau
  final int? previewPieceId; // Pièce en preview depuis le slider
  final int? previewPosition;
  final int? previewX;
  final int? previewY;
  final String? lastTransformation; // Dernière transformation appliquée

  const IsometriesDemoState({
    this.bottomPieces = const {},
    this.topPieces = const {},
    this.selectedPieceId,
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
    int? previewPieceId,
    int? previewPosition,
    int? previewX,
    int? previewY,
    String? lastTransformation,
    bool clearSelection = false,
    bool clearPreview = false,
    bool clearTransformation = false,
  }) {
    return IsometriesDemoState(
      bottomPieces: bottomPieces ?? this.bottomPieces,
      topPieces: topPieces ?? this.topPieces,
      selectedPieceId: clearSelection ? null : (selectedPieceId ?? this.selectedPieceId),
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

  // Placer une pièce dans la zone basse (lignes 5-9)
  void placePieceInBottom(int pieceId, int position, int x, int y) {
    // Vérifier que c'est bien dans la zone basse (y >= 5)
    if (y < 5) return;

    final newBottomPieces = Map<int, PlacedPieceDemo>.from(state.bottomPieces);
    newBottomPieces[pieceId] = PlacedPieceDemo(
      pieceId: pieceId,
      position: position,
      x: x,
      y: y,
    );

    state = state.copyWith(
      bottomPieces: newBottomPieces,
      clearPreview: true,
      clearSelection: true,
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

      // Si on duplique depuis le bas, ajuster y
      final targetY = state.topPieces.isEmpty ? entry.value.y - 5 : entry.value.y;

      newTopPieces[entry.key] = PlacedPieceDemo(
        pieceId: entry.value.pieceId,
        position: newPosition,
        x: entry.value.x,
        y: targetY,
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

      final targetY = state.topPieces.isEmpty ? entry.value.y - 5 : entry.value.y;

      newTopPieces[entry.key] = PlacedPieceDemo(
        pieceId: entry.value.pieceId,
        position: newPosition,
        x: entry.value.x,
        y: targetY,
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

      final targetY = state.topPieces.isEmpty ? entry.value.y - 5 : entry.value.y;

      newTopPieces[entry.key] = PlacedPieceDemo(
        pieceId: entry.value.pieceId,
        position: newPosition,
        x: entry.value.x,
        y: targetY,
      );
    }

    state = state.copyWith(
      topPieces: newTopPieces,
      lastTransformation: 'Symétrie V',
    );
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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Isométries'),
            if (state.lastTransformation != null) ...[
              const SizedBox(width: 8),
              Text(
                '• ${state.lastTransformation}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.indigo,
        actions: [
          // Bouton Rotation
          IconButton(
            icon: const Icon(Icons.rotate_right),
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
            icon: const Icon(Icons.swap_horiz),
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
            icon: const Icon(Icons.swap_vert),
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: () {
              HapticFeedback.mediumImpact();
              notifier.reset();
            },
          ),
        ],
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
          child: _buildPieceSlider(state, notifier, settings, isVertical: false),
        ),
      ],
    );
  }

  // Layout paysage : plateau au centre, slider en bas
  Widget _buildLandscapeLayout(
    BuildContext context,
    IsometriesDemoState state,
    IsometriesDemoNotifier notifier,
    settings,
  ) {
    return Column(
      children: [
        // Plateau
        Expanded(
          child: _buildPlateau(context, state, notifier, settings, isLandscape: true),
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
          child: _buildPieceSlider(state, notifier, settings, isVertical: false),
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
        final cellWidth = plateauWidth / 6;
        final cellHeight = plateauHeight / 10;

        return Stack(
          children: [
            // Grille de fond
            _buildGrid(plateauWidth, plateauHeight, cellWidth, cellHeight),

            // Ligne de séparation
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
                // Seulement zone basse (lignes 5-9)
                final y = row + 5;
                return Positioned(
                  left: col * cellWidth,
                  top: y * cellHeight,
                  width: cellWidth,
                  height: cellHeight,
                  child: DragTarget<Map<String, dynamic>>(
                    onWillAcceptWithDetails: (details) {
                      final data = details.data;
                      notifier.updatePreview(
                        data['pieceId'],
                        data['position'],
                        col,
                        y,
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
                        y,
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

  Widget _buildGrid(double width, double height, double cellWidth, double cellHeight) {
    return CustomPaint(
      size: Size(width, height),
      painter: _GridPainter(cellWidth: cellWidth, cellHeight: cellHeight),
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
    required bool isVertical,
  }) {
    return ListView.builder(
      controller: _sliderController,
      scrollDirection: isVertical ? Axis.vertical : Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: pentominos.length,
      itemBuilder: (context, index) {
        final piece = pentominos[index];
        final pieceColor = settings.ui.getPieceColor(piece.id);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: LongPressDraggable<Map<String, dynamic>>(
            data: {
              'pieceId': piece.id,
              'position': 0,
            },
            feedback: _buildDraggableFeedback(piece, pieceColor),
            childWhenDragging: _buildPieceWidget(piece, pieceColor, isDragging: true),
            onDragStarted: () {
              HapticFeedback.mediumImpact();
            },
            onDragEnd: (details) {
              notifier.clearPreview();
            },
            child: _buildPieceWidget(piece, pieceColor),
          ),
        );
      },
    );
  }

  Widget _buildPieceWidget(Pento piece, Color pieceColor, {bool isDragging = false}) {
    return Container(
      width: 70, // Réduit de 80 à 70
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey[300] : Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            piece.id.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14, // Réduit de 16 à 14
            ),
          ),
          const SizedBox(height: 2), // Réduit de 4 à 2
          Expanded(
            child: _buildMiniPiecePreview(piece, pieceColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableFeedback(Pento piece, Color pieceColor) {
    return Material(
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

  _GridPainter({required this.cellWidth, required this.cellHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    // Lignes verticales
    for (int i = 0; i <= 6; i++) {
      final x = i * cellWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Lignes horizontales
    for (int i = 0; i <= 10; i++) {
      final y = i * cellHeight;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
