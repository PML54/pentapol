// lib/screens/isometries_demo_screen_v2.dart
// Démonstration pédagogique des isométries avec les pentominos

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../models/pentominos.dart';
import '../providers/settings_provider.dart';

// État pour la démonstration des isométries
class IsometriesDemoState {
  final Pento? selectedPiece;
  final int selectedPositionIndex;
  final int? transformedPositionIndex;
  final List<String> appliedTransformations;
  final Offset translationOffset;

  const IsometriesDemoState({
    this.selectedPiece,
    this.selectedPositionIndex = 0,
    this.transformedPositionIndex,
    this.appliedTransformations = const [],
    this.translationOffset = Offset.zero,
  });

  IsometriesDemoState copyWith({
    Pento? selectedPiece,
    int? selectedPositionIndex,
    int? transformedPositionIndex,
    List<String>? appliedTransformations,
    Offset? translationOffset,
    bool clearTransformedPosition = false,
  }) {
    return IsometriesDemoState(
      selectedPiece: selectedPiece ?? this.selectedPiece,
      selectedPositionIndex: selectedPositionIndex ?? this.selectedPositionIndex,
      transformedPositionIndex: clearTransformedPosition ? null : (transformedPositionIndex ?? this.transformedPositionIndex),
      appliedTransformations: appliedTransformations ?? this.appliedTransformations,
      translationOffset: translationOffset ?? this.translationOffset,
    );
  }
}

// Notifier pour l'état des isométries
class IsometriesDemoNotifier extends Notifier<IsometriesDemoState> {
  @override
  IsometriesDemoState build() {
    return const IsometriesDemoState();
  }

  void selectPiece(Pento piece) {
    state = IsometriesDemoState(
      selectedPiece: piece,
      selectedPositionIndex: 0,
      transformedPositionIndex: null,
      appliedTransformations: [],
      translationOffset: Offset.zero,
    );
  }

  void applyRotation() {
    if (state.selectedPiece == null) return;

    final numPositions = state.selectedPiece!.numPositions;
    int nextIndex;

    if (state.transformedPositionIndex == null) {
      nextIndex = (state.selectedPositionIndex + 1) % numPositions;
    } else {
      nextIndex = (state.transformedPositionIndex! + 1) % numPositions;
    }

    state = state.copyWith(
      transformedPositionIndex: nextIndex,
      appliedTransformations: [...state.appliedTransformations, 'Rotation 90°'],
    );
  }

  void applySymmetryH() {
    if (state.selectedPiece == null) return;

    final numPositions = state.selectedPiece!.numPositions;
    final baseIndex = state.transformedPositionIndex ?? state.selectedPositionIndex;

    int nextIndex = (baseIndex + numPositions ~/ 2) % numPositions;

    state = state.copyWith(
      transformedPositionIndex: nextIndex,
      appliedTransformations: [...state.appliedTransformations, 'Symétrie H'],
    );
  }

  void applySymmetryV() {
    if (state.selectedPiece == null) return;

    final numPositions = state.selectedPiece!.numPositions;
    final baseIndex = state.transformedPositionIndex ?? state.selectedPositionIndex;

    int nextIndex;
    if (numPositions >= 4) {
      nextIndex = (baseIndex + 2) % numPositions;
    } else {
      nextIndex = (baseIndex + 1) % numPositions;
    }

    state = state.copyWith(
      transformedPositionIndex: nextIndex,
      appliedTransformations: [...state.appliedTransformations, 'Symétrie V'],
    );
  }

  void applyTranslation() {
    state = state.copyWith(
      translationOffset: Offset(
        (state.translationOffset.dx + 1) % 3,
        (state.translationOffset.dy + 1) % 2,
      ),
      appliedTransformations: [...state.appliedTransformations, 'Translation'],
    );
  }

  void reset() {
    if (state.selectedPiece == null) return;

    state = state.copyWith(
      clearTransformedPosition: true,
      appliedTransformations: [],
      translationOffset: Offset.zero,
    );
  }
}

// Provider
final isometriesDemoProvider = NotifierProvider<IsometriesDemoNotifier, IsometriesDemoState>(() {
  return IsometriesDemoNotifier();
});

class IsometriesDemoScreen extends ConsumerWidget {
  const IsometriesDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(isometriesDemoProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Démonstration des Isométries'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Info sur la pièce sélectionnée
          if (state.selectedPiece != null)
            _buildPieceInfo(state.selectedPiece!),

          // Plateau divisé
          Expanded(
            flex: 3,
            child: _buildDividedPlateau(context, ref, state, settings),
          ),

          // Boutons de transformation
          if (state.selectedPiece != null)
            _buildTransformationButtons(context, ref),

          // Slider de pièces
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildPieceSlider(context, ref, state, settings),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceInfo(Pento piece) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.indigo[50],
      child: Column(
        children: [
          Text(
            'Pièce ${piece.id}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '${piece.numPositions} position(s) distincte(s)',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDividedPlateau(
      BuildContext context,
      WidgetRef ref,
      IsometriesDemoState state,
      settings,
      ) {
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

            // Ligne de séparation au milieu
            Positioned(
              left: 0,
              right: 0,
              top: plateauHeight / 2,
              child: Container(
                height: 2,
                color: Colors.red[700],
              ),
            ),

            // Labels des zones
            Positioned(
              left: 10,
              top: plateauHeight * 0.25 - 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TRANSFORMÉE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: plateauHeight * 0.75 - 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'RÉFÉRENCE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            // Pièce d'origine (bas)
            if (state.selectedPiece != null)
              ..._buildPieceOnPlateau(
                state.selectedPiece!,
                state.selectedPositionIndex,
                cellWidth,
                cellHeight,
                plateauHeight,
                settings,
                offsetY: 5,
                offsetX: 0,
              ),

            // Pièce transformée (haut)
            if (state.selectedPiece != null && state.transformedPositionIndex != null)
              ..._buildPieceOnPlateau(
                state.selectedPiece!,
                state.transformedPositionIndex!,
                cellWidth,
                cellHeight,
                plateauHeight,
                settings,
                offsetY: 0,
                offsetX: state.translationOffset.dx.toInt(),
                highlightColor: Colors.indigo[300],
              ),
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

  List<Widget> _buildPieceOnPlateau(
      Pento piece,
      int positionIndex,
      double cellWidth,
      double cellHeight,
      double plateauHeight,
      settings,
      {required int offsetY, required int offsetX, Color? highlightColor}
      ) {
    final shape = piece.positions[positionIndex];
    final pieceColor = highlightColor ?? settings.ui.getPieceColor(piece.id);

    return shape.map((cellNumber) {
      final localX = (cellNumber - 1) % 5;
      final localY = (cellNumber - 1) ~/ 5;

      final x = localX + offsetX;
      final y = offsetY + localY;

      final visualY = 9 - y;

      return Positioned(
        left: x * cellWidth,
        top: visualY * cellHeight,
        width: cellWidth,
        height: cellHeight,
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: pieceColor,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(2),
            boxShadow: highlightColor != null ? [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              piece.id.toString(),
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
      );
    }).toList();
  }

  Widget _buildTransformationButtons(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(isometriesDemoProvider);
    final notifier = ref.read(isometriesDemoProvider.notifier);
    
    final hasSymH = state.appliedTransformations.contains('Symétrie H');
    final hasSymV = state.appliedTransformations.contains('Symétrie V');
    final isRotation180 = hasSymH && hasSymV;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Affichage des transformations appliquées
          if (state.appliedTransformations.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    'Transformations : ${state.appliedTransformations.join(' → ')}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  if (isRotation180)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lightbulb, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Sym H ∘ Sym V = Rotation 180° !',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // Boutons de transformation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTransformButton(
                icon: Icons.rotate_right,
                label: 'Rotation',
                color: Colors.blue,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  notifier.applyRotation();
                },
              ),
              _buildTransformButton(
                icon: Icons.swap_horiz,
                label: 'Sym H',
                color: Colors.green,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  notifier.applySymmetryH();
                },
              ),
              _buildTransformButton(
                icon: Icons.swap_vert,
                label: 'Sym V',
                color: Colors.orange,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  notifier.applySymmetryV();
                },
              ),
              _buildTransformButton(
                icon: Icons.open_with,
                label: 'Translation',
                color: Colors.purple,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  notifier.applyTranslation();
                },
              ),
              _buildTransformButton(
                icon: Icons.refresh,
                label: 'Reset',
                color: Colors.red,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  notifier.reset();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransformButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
            shape: const CircleBorder(),
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPieceSlider(
      BuildContext context,
      WidgetRef ref,
      IsometriesDemoState state,
      settings,
      ) {
    final notifier = ref.read(isometriesDemoProvider.notifier);
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: pentominos.length,
      itemBuilder: (context, index) {
        final piece = pentominos[index];
        final isSelected = state.selectedPiece?.id == piece.id;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            notifier.selectPiece(piece);
          },
          child: Container(
            width: 100,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.indigo[100] : Colors.white,
              border: Border.all(
                color: isSelected ? Colors.indigo : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pièce ${piece.id}',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${piece.numPositions} pos.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildMiniPiecePreview(piece, settings),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniPiecePreview(Pento piece, settings) {
    final pieceColor = settings.ui.getPieceColor(piece.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
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

    for (int i = 0; i <= 6; i++) {
      final x = i * cellWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

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