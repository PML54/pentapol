// Modified: 2025-11-16 10:00:00
// lib/screens/pentomino_game_screen.dart
// Écran de jeu de pentominos avec drag & drop

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pentomino_game_provider.dart';
import '../providers/settings_provider.dart';
import '../models/pentominos.dart';
import '../screens/solutions_browser_screen.dart';
import '../screens/settings_screen.dart';
import '../services/plateau_solution_counter.dart'; // Extension getCompatibleSolutionsBigInt
import '../config/game_icons_config.dart'; // Configuration centralisée des icônes

// Widgets extraits
import 'pentomino_game/widgets/shared/piece_renderer.dart';
import 'pentomino_game/widgets/shared/piece_border_calculator.dart';
import 'pentomino_game/widgets/shared/action_slider.dart';
import 'pentomino_game/widgets/game_mode/piece_slider.dart';


class PentominoGameScreen extends ConsumerStatefulWidget {
  const PentominoGameScreen({super.key});

  @override
  ConsumerState<PentominoGameScreen> createState() => _PentominoGameScreenState();
}

class _PentominoGameScreenState extends ConsumerState<PentominoGameScreen> {

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pentominoGameProvider);
    final notifier = ref.read(pentominoGameProvider.notifier);
    final settings = ref.watch(settingsProvider);

    // Détecter l'orientation pour adapter l'AppBar
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      // AppBar uniquement en mode portrait
      appBar: isLandscape ? null : PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: AppBar(
          toolbarHeight: 56.0,
          backgroundColor: state.isIsometriesMode 
              ? Colors.deepPurple[700]  // Fond violet en mode isométries
              : null,  // Fond par défaut (indigo) en mode normal
          leading: state.isIsometriesMode
              ? null  // Pas de bouton paramètres en mode isométries
              : IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
          title: !state.isIsometriesMode && settings.game.showSolutionCounter && state.solutionsCount != null && state.placedPieces.isNotEmpty
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
          actions: state.isIsometriesMode
              ? [
                  // MODE ISOMÉTRIES : Boutons de transformation (icônes plus grandes)
                  IconButton(
                    icon: Icon(GameIcons.isometryRotation.icon, size: 32),
                    onPressed: state.selectedPlacedPiece != null
                        ? () {
                            HapticFeedback.selectionClick();
                            notifier.applyIsometryRotation();
                          }
                        : null,
                    tooltip: GameIcons.isometryRotation.tooltip,
                    color: state.selectedPlacedPiece != null 
                        ? GameIcons.isometryRotation.color 
                        : Colors.grey,
                  ),
                  IconButton(
                    icon: Icon(GameIcons.isometrySymmetryH.icon, size: 32),
                    onPressed: state.selectedPlacedPiece != null
                        ? () {
                            HapticFeedback.selectionClick();
                            notifier.applyIsometrySymmetryH();
                          }
                        : null,
                    tooltip: GameIcons.isometrySymmetryH.tooltip,
                    color: state.selectedPlacedPiece != null 
                        ? GameIcons.isometrySymmetryH.color 
                        : Colors.grey,
                  ),
                  IconButton(
                    icon: Icon(GameIcons.isometrySymmetryV.icon, size: 32),
                    onPressed: state.selectedPlacedPiece != null
                        ? () {
                            HapticFeedback.selectionClick();
                            notifier.applyIsometrySymmetryV();
                          }
                        : null,
                    tooltip: GameIcons.isometrySymmetryV.tooltip,
                    color: state.selectedPlacedPiece != null 
                        ? GameIcons.isometrySymmetryV.color 
                        : Colors.grey,
                  ),
                  // Bouton Delete (visible si une pièce placée est sélectionnée)
                  if (state.selectedPlacedPiece != null)
                    IconButton(
                      icon: Icon(GameIcons.isometryDelete.icon, size: 32),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        notifier.removePlacedPiece(state.selectedPlacedPiece!);
                      },
                      tooltip: GameIcons.isometryDelete.tooltip,
                      color: GameIcons.isometryDelete.color,
                    ),
                  IconButton(
                    icon: Icon(GameIcons.exitIsometries.icon, size: 32),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      notifier.exitIsometriesMode();
                    },
                    tooltip: GameIcons.exitIsometries.tooltip,
                    color: GameIcons.exitIsometries.color,
                  ),
                ]
              : [
                  // MODE JEU NORMAL : Boutons normaux
                  // 🎓 Bouton "Mode Isométries"
                  IconButton(
                    icon: Icon(GameIcons.enterIsometries.icon, size: 24),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      notifier.enterIsometriesMode();
                    },
                    tooltip: GameIcons.enterIsometries.tooltip,
                    color: GameIcons.enterIsometries.color,
                  ),

                  // 👁️ Bouton "voir les solutions possibles"
                  if (state.solutionsCount != null && state.solutionsCount! > 0)
                    IconButton(
                      icon: Icon(GameIcons.viewSolutions.icon, size: 24),
                      tooltip: GameIcons.viewSolutions.tooltip,
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
                      icon: Icon(GameIcons.rotatePiece.icon, size: 24),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        notifier.cyclePosition();
                      },
                      tooltip: GameIcons.rotatePiece.tooltip,
                      color: GameIcons.rotatePiece.color,
                    ),
                  // Bouton retirer (visible si pièce placée sélectionnée)
                  if (state.selectedPlacedPiece != null)
                    IconButton(
                      icon: Icon(GameIcons.removePiece.icon, size: 24),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        notifier.removePlacedPiece(state.selectedPlacedPiece!);
                      },
                      tooltip: GameIcons.removePiece.tooltip,
                      color: GameIcons.removePiece.color,
                    ),
                  // Bouton Undo
                  IconButton(
                    icon: Icon(GameIcons.undo.icon, size: 24),
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
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          if (isLandscape) {
            return _buildLandscapeLayout(context, ref, state, notifier);
          } else {
            return _buildPortraitLayout(context, ref, state, notifier);
          }
        },
      ),
    );
  }

  /// Layout portrait (classique) : plateau en haut, slider en bas
  Widget _buildPortraitLayout(
      BuildContext context,
      WidgetRef ref,
      state,
      notifier,
      ) {
    return Column(
      children: [
        // Plateau de jeu
        Expanded(
          flex: 3,
          child: _buildGameBoard(context, ref, state, notifier, isLandscape: false),
        ),

        // Slider de pièces horizontal
        Container(
          height: 140,
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
          child: PieceSlider(isLandscape: false),
        ),
      ],
    );
  }

  /// Layout paysage : plateau à gauche, actions + slider vertical à droite
  Widget _buildLandscapeLayout(
      BuildContext context,
      WidgetRef ref,
      state,
      notifier,
      ) {
    return Row(
      children: [
        // Plateau de jeu (10×6 visuel)
        Expanded(
          child: _buildGameBoard(context, ref, state, notifier, isLandscape: true),
        ),

        // Colonne de droite : actions + slider
        Row(
          children: [
            // Slider d'actions verticales
            Container(
              width: 44,
              decoration: BoxDecoration(
                color: state.isIsometriesMode 
                    ? Colors.deepPurple[100]  // Fond violet clair en mode isométries
                    : Colors.grey.shade200,   // Fond gris en mode normal
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(-1, 0),
                  ),
                ],
              ),
              child: const ActionSlider(),
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
              child: PieceSlider(isLandscape: true),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit le plateau de jeu
  /// Portrait: 6×10 (logique et visuel)
  /// Paysage: 10×6 (visuel), mais logique reste 6×10
  Widget _buildGameBoard(
      BuildContext context,
      WidgetRef ref,
      state,
      notifier,
      {required bool isLandscape}
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dimensions visuelles
        final visualCols = isLandscape ? 10 : 6;
        final visualRows = isLandscape ? 6 : 10;

        // Note: Les dimensions logiques restent toujours 6×10 (gérées dans le provider)

        final cellSize =
        (constraints.maxWidth / visualCols).clamp(0.0, constraints.maxHeight / visualRows).toDouble();

        return Center(
          child: Container(
            width: cellSize * visualCols,
            height: cellSize * visualRows,
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
                  color: Colors.black.withValues(alpha: 0.1),
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
                    // Calculer les coordonnées visuelles
                    final visualX = (offset.dx / cellSize).floor().clamp(0, visualCols - 1);
                    final visualY = (offset.dy / cellSize).floor().clamp(0, visualRows - 1);

                    // Transformer en coordonnées logiques (6×10)
                    int logicalX, logicalY;
                    if (isLandscape) {
                      // Paysage: rotation 90° anti-horaire
                      logicalX = (visualRows - 1) - visualY;
                      logicalY = visualX;
                    } else {
                      // Portrait: pas de transformation
                      logicalX = visualX;
                      logicalY = visualY;
                    }

                    notifier.updatePreview(logicalX, logicalY);
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
                    // Calculer les coordonnées visuelles
                    final visualX = (offset.dx / cellSize).floor().clamp(0, visualCols - 1);
                    final visualY = (offset.dy / cellSize).floor().clamp(0, visualRows - 1);

                    // Transformer en coordonnées logiques (6×10)
                    int logicalX, logicalY;
                    if (isLandscape) {
                      // Paysage: rotation 90° anti-horaire
                      logicalX = (visualRows - 1) - visualY;
                      logicalY = visualX;
                    } else {
                      // Portrait: pas de transformation
                      logicalX = visualX;
                      logicalY = visualY;
                    }

                    final success = notifier.tryPlacePiece(logicalX, logicalY);

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
                      crossAxisCount: visualCols,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 0, // contours gérés manuellement
                      mainAxisSpacing: 0,
                    ),
                    itemCount: 60,
                    itemBuilder: (context, index) {
                      // Calculer les coordonnées visuelles
                      final visualX = index % visualCols;
                      final visualY = index ~/ visualCols;

                      // Transformer en coordonnées logiques (6×10)
                      int logicalX, logicalY;
                      if (isLandscape) {
                        // Paysage: rotation 90° anti-horaire
                        // visualX (0-9) → logicalY (0-9)
                        // visualY (0-5) → logicalX (5-0)
                        logicalX = (visualRows - 1) - visualY;
                        logicalY = visualX;
                      } else {
                        // Portrait: pas de transformation
                        logicalX = visualX;
                        logicalY = visualY;
                      }

                      final cellValue = state.plateau.getCell(logicalX, logicalY);

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

                        // Vérifier si (logicalX, logicalY) est dans la zone de la pièce sélectionnée
                        for (final cellNum in position) {
                          final localX = (cellNum - 1) % 5;
                          final localY = (cellNum - 1) ~/ 5;
                          final pieceX = selectedPiece.gridX + localX;
                          final pieceY = selectedPiece.gridY + localY;

                          if (pieceX == logicalX && pieceY == logicalY) {
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

                          if (pieceX == logicalX && pieceY == logicalY) {
                            isPreview = true;
                            // Couleur selon validité
                            if (state.isPreviewValid) {
                              cellColor = _getPieceColor(piece.id).withValues(alpha: 0.4);
                            } else {
                              cellColor = Colors.red.withValues(alpha: 0.3);
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
                        border = PieceBorderCalculator.calculate(logicalX, logicalY, state.plateau, isLandscape);
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
                            child: PieceRenderer(
                              piece: state.selectedPiece!,
                              positionIndex: state.selectedPositionIndex,
                              isDragging: true,
                              getPieceColor: _getPieceColor,
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
                            final piece = notifier.getPlacedPieceAt(logicalX, logicalY);
                            if (piece != null) {
                              HapticFeedback.selectionClick();
                              notifier.selectPlacedPiece(piece, logicalX, logicalY);
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

  /// Couleurs des pièces selon les paramètres
  Color _getPieceColor(int pieceId) {
    final settings = ref.read(settingsProvider);
    return settings.ui.getPieceColor(pieceId);
  }

}