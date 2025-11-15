// Modified: 2025-11-15 08:07:55
// lib/screens/pentomino_game_screen.dart
// Écran de jeu de pentominos avec drag & drop

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pentomino_game_provider.dart';
import '../models/pentominos.dart';
import '../models/plateau.dart';
import '../screens/solutions_browser_screen.dart';
import '../services/plateau_solution_counter.dart'; // pour getCompatibleSolutionsBigInt()


class PentominoGameScreen extends ConsumerStatefulWidget {
  const PentominoGameScreen({super.key});

  @override
  ConsumerState<PentominoGameScreen> createState() => _PentominoGameScreenState();
}

class _PentominoGameScreenState extends ConsumerState<PentominoGameScreen> {
  final ScrollController _sliderController = ScrollController();

  @override
  void dispose() {
    _sliderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pentominoGameProvider);
    final notifier = ref.read(pentominoGameProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: state.solutionsCount != null && state.placedPieces.isNotEmpty
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${state.solutionsCount}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: state.solutionsCount! > 0 ? Colors.green[700] : Colors.red[700],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.emoji_events, size: 24),
          ],
        )
            : const SizedBox.shrink(),
        actions: [
          // 👁️ Bouton "voir les solutions possibles"
          if (state.solutionsCount != null && state.solutionsCount! > 0)
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: 'Voir les solutions possibles',
              onPressed: () {
                HapticFeedback.selectionClick();

                // Récupérer les solutions compatibles pour le plateau actuel (BigInt)
                final compatible = state.plateau.getCompatibleSolutionsBigInt();

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SolutionsBrowserScreen.forSolutions(
                      solutions: compatible,
                      title: 'Solutions possibles',
                    ),
                  ),
                );
              },
            ),

          // Bouton de rotation (visible si pièce sélectionnée)
          if (state.selectedPiece != null)
            IconButton(
              icon: const Icon(Icons.rotate_right),
              onPressed: () {
                HapticFeedback.selectionClick();
                notifier.cyclePosition();
              },
              tooltip: 'Rotation',
              color: Colors.blue[400],
            ),
          // Bouton retirer (visible si pièce placée sélectionnée)
          if (state.selectedPlacedPiece != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                HapticFeedback.mediumImpact();
                notifier.removePlacedPiece(state.selectedPlacedPiece!);
              },
              tooltip: 'Retirer',
              color: Colors.red[600], // Rouge pour mieux voir la poubelle
            ),
          // Bouton Undo
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: state.placedPieces.isNotEmpty && state.selectedPiece == null
                ? () {
              HapticFeedback.mediumImpact();
              notifier.undoLastPlacement();
            }
                : null,
            tooltip: 'Annuler',
          ),
        ],
      ),
      body: Column(
        children: [
          // Plateau de jeu
          Expanded(
            flex: 3,
            child: _buildGameBoard(context, ref, state, notifier),
          ),

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
            child: _buildPieceSlider(context, ref, state, notifier),
          ),
        ],
      ),
    );
  }

  /// Construit le plateau de jeu (6×10)
  Widget _buildGameBoard(
      BuildContext context,
      WidgetRef ref,
      state,
      notifier,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = 6;
        final rows = 10;
        final cellSize =
        (constraints.maxWidth / cols).clamp(0.0, constraints.maxHeight / rows).toDouble();

        return Center(
          child: Container(
            width: cellSize * cols,
            height: cellSize * rows,
            decoration: BoxDecoration(
              // Fond avec dégradé doux
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade50,
                  Colors.grey.shade100,
                ],
              ),
              // Ombre douce autour du plateau
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
              // Coins arrondis
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DragTarget<Pento>(
              onWillAcceptWithDetails: (details) => true,
              onMove: (details) {
                // Mettre à jour la preview pendant le drag
                final offset =
                (context.findRenderObject() as RenderBox?)?.globalToLocal(details.offset);

                if (offset != null) {
                  final gridX = (offset.dx / cellSize).round().clamp(0, cols - 1);
                  final gridY = (offset.dy / cellSize).round().clamp(0, rows - 1);
                  notifier.updatePreview(gridX, gridY);
                }
              },
              onLeave: (data) {
                // Effacer la preview quand on quitte le plateau
                notifier.clearPreview();
              },
              onAcceptWithDetails: (details) {
                // Calculer la position sur la grille depuis le point de dépôt
                final offset =
                (context.findRenderObject() as RenderBox?)?.globalToLocal(details.offset);

                if (offset != null) {
                  final gridX = (offset.dx / cellSize).round().clamp(0, cols - 1);
                  final gridY = (offset.dy / cellSize).round().clamp(0, rows - 1);

                  final success = notifier.tryPlacePiece(gridX, gridY);

                  // Haptic feedback selon le résultat
                  if (success) {
                    HapticFeedback.mediumImpact();
                  } else {
                    HapticFeedback.heavyImpact();
                  }
                }

                // Effacer la preview
                notifier.clearPreview();
              },
              builder: (context, candidateData, rejectedData) {
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 0, // contours gérés manuellement
                    mainAxisSpacing: 0,
                  ),
                  itemCount: 60,
                  itemBuilder: (context, index) {
                    final x = index % cols;
                    final y = index ~/ cols;
                    final cellValue = state.plateau.getCell(x, y);

                    Color cellColor;
                    String cellText = '';
                    bool isOccupied = false;

                    if (cellValue == -1) {
                      cellColor = Colors.grey.shade800;
                    } else if (cellValue == 0) {
                      cellColor = Colors.grey.shade300;
                    } else {
                      cellColor = _getPieceColor(cellValue);
                      cellText = cellValue.toString();
                      isOccupied = true;
                    }

                    // Vérifier si cette cellule fait partie de la pièce sélectionnée
                    bool isSelected = false;
                    bool isReferenceCell = false; // Case de référence (point d'ancrage)
                    bool isPreview = false; // Fait partie de la preview

                    if (state.selectedPlacedPiece != null) {
                      final selectedPiece = state.selectedPlacedPiece!;
                      final position =
                      selectedPiece.piece.positions[state.selectedPositionIndex];

                      // Vérifier si (x, y) est dans la zone de la pièce sélectionnée
                      for (final cellNum in position) {
                        final localX = (cellNum - 1) % 5;
                        final localY = (cellNum - 1) ~/ 5;
                        final pieceX = selectedPiece.gridX + localX;
                        final pieceY = selectedPiece.gridY + localY;

                        if (pieceX == x && pieceY == y) {
                          isSelected = true;

                          // Vérifier si c'est la case de référence
                          if (state.selectedCellInPiece != null) {
                            isReferenceCell = (localX == state.selectedCellInPiece!.x &&
                                localY == state.selectedCellInPiece!.y);
                          }

                          // Afficher la pièce sélectionnée même si retirée du plateau
                          if (cellValue == 0) {
                            cellColor = _getPieceColor(selectedPiece.piece.id);
                            cellText = selectedPiece.piece.id.toString();
                            isOccupied = true;
                          }
                          break;
                        }
                      }
                    }

                    // Vérifier si cette cellule fait partie de la preview
                    if (!isSelected &&
                        state.selectedPiece != null &&
                        state.previewX != null &&
                        state.previewY != null) {
                      final piece = state.selectedPiece!;
                      final position = piece.positions[state.selectedPositionIndex];

                      for (final cellNum in position) {
                        final localX = (cellNum - 1) % 5;
                        final localY = (cellNum - 1) ~/ 5;
                        final pieceX = state.previewX! + localX;
                        final pieceY = state.previewY! + localY;

                        if (pieceX == x && pieceY == y) {
                          isPreview = true;
                          // Couleur selon validité
                          if (state.isPreviewValid) {
                            cellColor = _getPieceColor(piece.id).withOpacity(0.4);
                          } else {
                            cellColor = Colors.red.withOpacity(0.3);
                          }
                          cellText = piece.id.toString();
                          break;
                        }
                      }
                    }

                    // Construire la bordure en fonction du contexte
                    Border border;
                    if (isReferenceCell) {
                      // Case de référence : rouge bien visible
                      border = Border.all(color: Colors.red, width: 4);
                    } else if (isPreview) {
                      // Preview : tout en vert/rouge (comme avant)
                      border = Border.all(
                        color: state.isPreviewValid ? Colors.green : Colors.red,
                        width: 3,
                      );
                    } else if (isSelected) {
                      // Pièce sélectionnée : bordure amber
                      border = Border.all(
                        color: Colors.amber,
                        width: 3,
                      );
                    } else {
                      // Cas normal : utiliser les contours de pièces comme dans le browser
                      border = _buildPieceBorderOnBoard(x, y, state.plateau);
                    }

                    Widget cellWidget = Container(
                      decoration: BoxDecoration(
                        color: cellColor,
                        border: border,
                      ),
                      child: Center(
                        child: Text(
                          cellText,
                          style: TextStyle(
                            color: isPreview
                                ? (state.isPreviewValid
                                ? Colors.green.shade900
                                : Colors.red.shade900)
                                : Colors.white,
                            fontWeight:
                            (isSelected || isPreview) ? FontWeight.w900 : FontWeight.bold,
                            fontSize: (isSelected || isPreview) ? 16 : 14,
                          ),
                        ),
                      ),
                    );

                    // Si une pièce est sélectionnée, on peut la déplacer depuis le plateau
                    if (isSelected && state.selectedPiece != null) {
                      cellWidget = Draggable<Pento>(
                        data: state.selectedPiece!,
                        feedback: Material(
                          color: Colors.transparent,
                          child: _buildPieceWidget(
                            state.selectedPiece!,
                            state.selectedPositionIndex,
                            true,
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: cellWidget,
                        ),
                        child: GestureDetector(
                          onDoubleTap: () {
                            // Double-tap → changer de position
                            HapticFeedback.selectionClick();
                            notifier.cyclePosition();
                          },
                          child: cellWidget,
                        ),
                      );
                    } else if (isOccupied && !isSelected) {
                      // Tap simple pour sélectionner (désélectionne automatiquement l'ancienne)
                      cellWidget = GestureDetector(
                        onTap: () {
                          final piece = notifier.getPlacedPieceAt(x, y);
                          if (piece != null) {
                            HapticFeedback.selectionClick();
                            notifier.selectPlacedPiece(piece, x, y);
                          }
                        },
                        child: cellWidget,
                      );
                    } else if (!isOccupied && state.selectedPiece != null && cellValue == 0) {
                      // Tap sur case vide → désélectionner
                      cellWidget = GestureDetector(
                        onTap: () {
                          notifier.cancelSelection();
                        },
                        child: cellWidget,
                      );
                    }

                    return cellWidget;
                  },
                );
              },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construit le slider de pièces en bas (boucle infinie)
  Widget _buildPieceSlider(
      BuildContext context,
      WidgetRef ref,
      state,
      notifier,
      ) {
    if (state.availablePieces.isEmpty) {
      return const SizedBox.shrink();
    }

    final pieces = state.availablePieces;
    if (pieces.isEmpty) return const SizedBox.shrink();

    // Si moins de 4 pièces restantes, afficher simplement la liste
    if (pieces.length < 4) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: pieces.length,
        itemBuilder: (context, index) {
          final piece = pieces[index];
          return _buildDraggablePiece(piece, notifier, state);
        },
      );
    }

    // Sinon, boucle infinie pour plus de 4 pièces
    // On crée 1000 "pages" de la même liste pour donner l'impression d'infini
    const itemsPerPage = 1000;
    final totalItems = pieces.length * itemsPerPage;

    // Initialiser le scroll au milieu une seule fois
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sliderController.hasClients && _sliderController.offset == 0) {
        const itemWidth = 92.0; // padding horizontal (12) + width approximative de la pièce
        final middleOffset = (totalItems / 2) * itemWidth;
        _sliderController.jumpTo(middleOffset);
      }
    });

    return ListView.builder(
      controller: _sliderController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Utiliser modulo pour boucler sur les pièces
        final pieceIndex = index % pieces.length;
        final piece = pieces[pieceIndex];

        return _buildDraggablePiece(piece, notifier, state);
      },
    );
  }

  /// Construit une pièce draggable
  Widget _buildDraggablePiece(Pento piece, notifier, state) {
    // Trouver l'index de position actuel pour cette pièce
    // Si sélectionnée, utiliser selectedPositionIndex, sinon l'index sauvegardé
    int positionIndex = state.selectedPiece?.id == piece.id
        ? state.selectedPositionIndex
        : state.getPiecePositionIndex(piece.id);

    final isSelected = state.selectedPiece?.id == piece.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.amber.shade700 : Colors.grey.shade300,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.2 : 0.1),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: _DraggablePieceWidget(
          piece: piece,
          positionIndex: positionIndex,
          isSelected: isSelected,
          selectedPositionIndex: state.selectedPositionIndex,
          onSelect: () {
            HapticFeedback.selectionClick();
            notifier.selectPiece(piece);
          },
          onCycle: () {
            HapticFeedback.selectionClick();
            notifier.cyclePosition();
          },
          onCancel: () {
            HapticFeedback.lightImpact();
            notifier.cancelSelection();
          },
          childBuilder: (isDragging) => _buildPieceWidget(
            piece,
            state.selectedPiece?.id == piece.id ? state.selectedPositionIndex : positionIndex,
            isDragging,
          ),
        ),
      ),
    );
  }

  /// Construit le widget visuel d'une pièce (dans le slider ou en drag)
  Widget _buildPieceWidget(Pento piece, int positionIndex, bool isDragging) {
    final position = piece.positions[positionIndex];

    // Convertir les cellNum (1-25) en coordonnées (x, y)
    final coords = position.map((cellNum) {
      final x = (cellNum - 1) % 5;
      final y = (cellNum - 1) ~/ 5;
      return {'x': x, 'y': y};
    }).toList();

    // Calculer les dimensions de la pièce
    int minX = coords[0]['x']!;
    int maxX = coords[0]['x']!;
    int minY = coords[0]['y']!;
    int maxY = coords[0]['y']!;

    for (final coord in coords) {
      final x = coord['x']!;
      final y = coord['y']!;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    final width = maxX - minX + 1;
    final height = maxY - minY + 1;
    final cellSize = 16.0; // Taille des petits carrés

    return Container(
      width: width * cellSize + 8,
      height: height * cellSize + 8,
      decoration: BoxDecoration(
        boxShadow: isDragging
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ]
            : null,
      ),
      child: Stack(
        children: [
          // Les 5 carrés de la pièce
          for (final coord in coords)
            Positioned(
              left: (coord['x']! - minX) * cellSize + 4,
              top: (coord['y']! - minY) * cellSize + 4,
              child: Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: _getPieceColor(piece.id),
                  border: Border.all(color: Colors.white, width: 1.5),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                // Numéro de la pièce sur le premier carré
                child: coord == coords.first
                    ? Center(
                  child: Text(
                    piece.id.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                )
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  /// Couleurs des pièces (même palette que l'éditeur)
  Color _getPieceColor(int pieceId) {
    const colors = [
      Colors.black, // Pièce 1
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.brown,
      Colors.indigo,
      Colors.lime,
      Colors.cyan,
      Colors.amber,
    ];
    return colors[(pieceId - 1) % colors.length];
  }

  /// Construit un contour de pièce sur le plateau :
  /// trait épais aux frontières entre pièces (ou bord/zone invisible).
  Border _buildPieceBorderOnBoard(int x, int y, Plateau plateau) {
    const width = 6;
    const height = 10;

    final int id = plateau.getCell(x, y);
    // On considère 0 et -1 comme "pas de pièce"
    final int baseId = id > 0 ? id : 0;

    int neighborId(int nx, int ny) {
      if (nx < 0 || nx >= width || ny < 0 || ny >= height) return 0;
      final v = plateau.getCell(nx, ny);
      return v > 0 ? v : 0;
    }

    final idTop = neighborId(x, y - 1);
    final idBottom = neighborId(x, y + 1);
    final idLeft = neighborId(x - 1, y);
    final idRight = neighborId(x + 1, y);

    const borderWidthOuter = 2.0;
    const borderWidthInner = 0.5;

    return Border(
      top: BorderSide(
        color: (idTop != baseId) ? Colors.black : Colors.grey.shade400,
        width: (idTop != baseId) ? borderWidthOuter : borderWidthInner,
      ),
      bottom: BorderSide(
        color: (idBottom != baseId) ? Colors.black : Colors.grey.shade400,
        width: (idBottom != baseId) ? borderWidthOuter : borderWidthInner,
      ),
      left: BorderSide(
        color: (idLeft != baseId) ? Colors.black : Colors.grey.shade400,
        width: (idLeft != baseId) ? borderWidthOuter : borderWidthInner,
      ),
      right: BorderSide(
        color: (idRight != baseId) ? Colors.black : Colors.grey.shade400,
        width: (idRight != baseId) ? borderWidthOuter : borderWidthInner,
      ),
    );
  }
}

/// Widget pour gérer proprement le double-tap sans propagation
class _DraggablePieceWidget extends StatefulWidget {
  final Pento piece;
  final int positionIndex;
  final bool isSelected;
  final int selectedPositionIndex;
  final VoidCallback onSelect;
  final VoidCallback onCycle;
  final VoidCallback onCancel;
  final Widget Function(bool isDragging) childBuilder;

  const _DraggablePieceWidget({
    required this.piece,
    required this.positionIndex,
    required this.isSelected,
    required this.selectedPositionIndex,
    required this.onSelect,
    required this.onCycle,
    required this.onCancel,
    required this.childBuilder,
  });

  @override
  State<_DraggablePieceWidget> createState() => _DraggablePieceWidgetState();
}

class _DraggablePieceWidgetState extends State<_DraggablePieceWidget> {
  Timer? _tapTimer;
  bool _isProcessing = false;

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    // Annuler le timer précédent s'il existe
    _tapTimer?.cancel();

    // Si on est déjà en train de traiter un double-tap, ignorer
    if (_isProcessing) return;

    // Attendre un peu pour voir si c'est un double-tap
    _tapTimer = Timer(const Duration(milliseconds: 300), () {
      // C'était un tap simple → sélectionner la pièce
      if (!widget.isSelected) {
        widget.onSelect();
      }
    });
  }

  void _handleDoubleTap() {
    // Annuler le timer du tap simple
    _tapTimer?.cancel();

    // Éviter les doubles exécutions
    if (_isProcessing) return;
    _isProcessing = true;

    // Si la pièce est déjà sélectionnée dans le slider,
    // le double-tap sert à faire pivoter
    if (widget.isSelected) {
      widget.onCycle();
    } else {
      // Sinon, sélectionner la pièce
      widget.onSelect();
    }

    // Réinitialiser après un court délai
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si la pièce est déjà sélectionnée, utiliser Draggable normal
    // Sinon, utiliser LongPressDraggable
    if (widget.isSelected) {
      return Draggable<Pento>(
        data: widget.piece,
        onDragStarted: () {
          // Déjà sélectionnée, pas besoin de rappeler onSelect
        },
        onDragEnd: (details) {
          if (!details.wasAccepted) {
            widget.onCancel();
          }
        },
        feedback: Material(
          color: Colors.transparent,
          child: widget.childBuilder(true),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: widget.childBuilder(false),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          onDoubleTap: _handleDoubleTap,
          child: widget.childBuilder(false),
        ),
      );
    } else {
      return LongPressDraggable<Pento>(
        data: widget.piece,
        onDragStarted: () {
          widget.onSelect();
        },
        onDragEnd: (details) {
          if (!details.wasAccepted) {
            widget.onCancel();
          }
        },
        feedback: Material(
          color: Colors.transparent,
          child: widget.childBuilder(true),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: widget.childBuilder(false),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          onDoubleTap: _handleDoubleTap,
          child: widget.childBuilder(false),
        ),
      );
    }
  }
}
