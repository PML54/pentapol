// Modified: 2026-09-01 07:54 — correctif 3 (PLAN_DEPLACEMENT_PIECE §4) : onAcceptWithDetails dépose
//           à previewX/previewY via tryPlaceAtAnchor, sans reconstruire de faux doigt (défaut 3.3).
// lib/pentoscope/widgets/pentoscope_board.dart
// Historique: 2026-09-01 07:54 — correctif 2 : onDragStarted → setDragMastercase (mécanisme (b)).
// Historique: 2026-09-01 07:54 — correctif 1 : Draggable de case en pointerDragAnchorStrategy
//             (details.offset = doigt exact, mécanisme (a)) ; feedback recentré FractionalTranslation.
// Historique: 2026-09-01 07:54 — commit 0 : instrumentation kDebugMode du glissé (dragAnchorStrategy).
// Historique: 2026-08-31 16:00 — regroupement des réglages visuels : kPieceToBoardCellRatio n'est
//             plus défini ici mais en tête de pentoscope_game_screen.dart (importé). Valeur (0.35).
// Historique: 2026-08-31 15:00 — réglage à l'œil : kPieceToBoardCellRatio 0.45 → 0.35.
// Historique: 2026-08-30 13:50 — PLAN_ERGONOMIE §6 étape 4 : le numéro sur une case suit cellSize.
// Historique: 2026-08-30 13:35 — étape 2 : le feedback de drag (« miniature ») prend la taille de
//             case du plateau × k ; _buildCell reçoit cellSize ; constante kPieceToBoardCellRatio.
// Historique: 2026-08-28 20:48 — suppression de la démonstration : retrait du champ et des
//             méthodes de surbrillance locale et des deux méthodes de démonstration du State.
//             2026-08-27 20:46 — retrait de _showVictoryDialog, orpheline (54 lignes).

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';

import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/common/widgets/piece_border_calculator.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
// Le rapport pièce/plateau (feedback de drag) est regroupé avec les autres réglages visuels
// en tête de pentoscope_game_screen.dart. Import ciblé pour ne prendre que cette constante.
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart'
    show kPieceToBoardCellRatio;

class PentoscopeBoard extends ConsumerStatefulWidget {
  final bool isLandscape;

  const PentoscopeBoard({super.key, required this.isLandscape});

  @override
  ConsumerState<PentoscopeBoard> createState() => _PentoscopeBoardState();

  // Méthode statique pour accéder au state depuis l'extérieur
  static _PentoscopeBoardState? of(BuildContext context) {
    return context.findAncestorStateOfType<_PentoscopeBoardState>();
  }
}

class _PentoscopeBoardState extends ConsumerState<PentoscopeBoard> {
  @override
  Widget build(BuildContext context) {
    final ref = context as WidgetRef;
    final state = ref.watch(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);
    final settings = ref.read(settingsProvider);

    // Informe le provider APRÈS le build (sinon Riverpod assertion).
    // ✅ Ne PAS modifier le provider pendant le build.
    // On reporte l'info d'orientation après la frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.setViewOrientation(widget.isLandscape);
    });

    final puzzle = state.puzzle;
    if (puzzle == null) {
      return const Center(child: Text('Aucun puzzle'));
    }

    final boardWidth = puzzle.size.width;
    final boardHeight = puzzle.size.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Dimensions visuelles (swap si paysage)
        final visualCols = widget.isLandscape ? boardHeight : boardWidth;
        final visualRows = widget.isLandscape ? boardWidth : boardHeight;

        // Réserver 8px de marge uniquement en portrait (largeur limitée)
        // En paysage, pas besoin de marge car le plateau a plus d'espace
        final availableWidth = widget.isLandscape ? constraints.maxWidth : constraints.maxWidth - 8;
        final cellSize = (availableWidth / visualCols)
            .clamp(0.0, constraints.maxHeight / visualRows)
            .toDouble();

        final gridWidth = cellSize * visualCols;
        final gridHeight = cellSize * visualRows;

        // Offset du plateau centré
        final offsetX = (constraints.maxWidth - gridWidth) / 2;
        final offsetY = (constraints.maxHeight - gridHeight) / 2;

        // DragTarget englobe TOUT l'espace pour capturer le drag partout
        return DragTarget<Pento>(
          onWillAcceptWithDetails: (details) {
            debugPrint('🎯 DragTarget: pièce acceptée depuis slider');
            return true;
          },
          onMove: (details) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) return;

            final localOffset = renderBox.globalToLocal(details.offset);

            // Coordonnées relatives au plateau centré
            final plateauX = localOffset.dx - offsetX;
            final plateauY = localOffset.dy - offsetY;

            // TEST: Agrandir drastiquement la zone pour device réel
            const double margin = 100.0; // Marge GIGANTESQUE pour test
            if (plateauX < -margin ||
                plateauX >= gridWidth + margin ||
                plateauY < -margin ||
                plateauY >= gridHeight + margin) {
              debugPrint('❌ LOIN du plateau: plateau=(${plateauX.toInt()},${plateauY.toInt()})');
              return;
            }

            // Debug seulement si on est proche des bords (pour éviter spam)
            if (plateauX < 20 || plateauX > gridWidth - 20 ||
                plateauY < 20 || plateauY > gridHeight - 20) {
              debugPrint('🎯 Drag près bord: plateau=(${plateauX.toInt()},${plateauY.toInt()}) gridSize=${gridWidth}x${gridHeight}');
            }

            final visualX = (plateauX / cellSize).floor().clamp(
              0,
              visualCols - 1,
            );
            final visualY = (plateauY / cellSize).floor().clamp(
              0,
              visualRows - 1,
            );

            int logicalX, logicalY;
            if (widget.isLandscape) {
              logicalX = (visualRows - 1) - visualY;
              logicalY = visualX;
            } else {
              logicalX = visualX;
              logicalY = visualY;
            }

            // Log pour pièce 12 verticale seulement (pour éviter spam)
            if (state.selectedPiece?.id == 12 && state.selectedPositionIndex == 0) {
              debugPrint('🎯 Drag pièce 12 verticale: plateau=(${plateauX.toInt()},${plateauY.toInt()}) visual=(${visualX},${visualY}) logical=(${logicalX},${logicalY})');
            }

            notifier.updatePreview(logicalX, logicalY);
          },
          onLeave: (data) {
            // ✨ BUGFIX: Ne pas appeler clearPreview()
            // Garder le preview quand on sort du DragTarget

            notifier.clearPreview();
            // La pièce reste affichée à sa dernière position valide
          },
          onAcceptWithDetails: (details) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) {
              notifier.clearPreview();
              return;
            }

            // Correctif 3 (§4) : déposer à l'ancre de l'aperçu, déjà snappée et validée.
            // previewX/previewY EST l'ancre ; plus de reconstruction d'un faux doigt.
            if (state.previewX == null || state.previewY == null) {
              notifier.clearPreview();
              return;
            }

            final success = notifier.tryPlaceAtAnchor(
              state.previewX!,
              state.previewY!,
            );

            if (success) {
              HapticFeedback.mediumImpact();
              final newState = ref.read(pentoscopeProvider);
              if (newState.isComplete) {
              }
            } else {
              HapticFeedback.heavyImpact();
            }

            notifier.clearPreview();
          },
          builder: (context, candidateData, rejectedData) {
            return Align(
              // En paysage: aligner en haut pour éviter l'espace
              // En portrait: centrer
              alignment: widget.isLandscape ? Alignment.topCenter : Alignment.center,
              child: Container(
                width: gridWidth,
                height: gridHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey.shade50, Colors.grey.shade100],
                  ),
                  border: Border.all(
                    color: Colors.grey.shade700,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 2,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: visualCols,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0,
                    ),
                    itemCount: boardWidth * boardHeight,
                    itemBuilder: (context, index) {
                      final visualX = index % visualCols;
                      final visualY = index ~/ visualCols;

                      int logicalX, logicalY;
                      if (widget.isLandscape) {
                        logicalX = (visualRows - 1) - visualY;
                        logicalY = visualX;
                      } else {
                        logicalX = visualX;
                        logicalY = visualY;
                      }

                      return _buildCell(
                        context,
                        ref,
                        state,
                        notifier,
                        settings,
                        logicalX,
                        logicalY,
                        widget.isLandscape,
                        cellSize,
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================================
  // HELPER FUNCTIONS POUR _buildCell - À AJOUTER À LA FIN DE LA CLASSE
  // ============================================================================

  // ============================================================================
  // NOUVELLE FONCTION _buildCell - REFACTORISÉE ET LISIBLE
  // ============================================================================

  Widget _buildCell(
      BuildContext context,
      WidgetRef ref,
      PentoscopeState state,
      PentoscopeNotifier notifier,
      settings,
      int logicalX,
      int logicalY,
      bool isLandscape,
      double cellSize,
      ) {
    // 1️⃣ RÉCUPÉRER LES DONNÉES DE BASE
    var cellValue = state.plateau.getCell(logicalX, logicalY);

    // 🐛 FIX: Si cette cellule appartient à une pièce sélectionnée (en cours de déplacement),
    // ne pas l'afficher à son ancienne position
    if (state.selectedPlacedPiece != null) {
      // Vérifier si cette cellule fait partie de la pièce sélectionnée
      final selectedPiece = state.selectedPlacedPiece!;
      for (final cell in selectedPiece.absoluteCells) {
        if (cell.x == logicalX && cell.y == logicalY) {
          cellValue = 0; // Masquer cette cellule de la pièce sélectionnée
          break;
        }
      }
    }
    final isSolutionCell = _isSolutionCell(state, logicalX, logicalY);
    final solutionPieceId = _getSolutionPieceIdAt(state, logicalX, logicalY);

    // 2️⃣ DÉTERMINER LA COULEUR DE BASE
    Color cellColor = _getBaseCellColor(
      cellValue,
      isSolutionCell,
      solutionPieceId,
      settings,
    );

    // 3️⃣ DÉTECTER LA PIÈCE SÉLECTIONNÉE
    final selectedInfo = _detectSelectedPlacedPiece(
      state,
      logicalX,
      logicalY,
      cellValue,
      settings,
    );
    bool isSelected = selectedInfo.isSelected;
    bool isReferenceCell = false;

    if (isSelected && selectedInfo.selectedColor != null) {
      cellColor = selectedInfo.selectedColor!;
    }

    // Vérifier mastercase
    if (isSelected && state.selectedCellInPiece != null) {
      // Chercher position locale pour comparer
      final selectedPiece = state.selectedPlacedPiece!;
      final position =
      selectedPiece.piece.orientations[state.selectedPositionIndex];
      final minOffset = _getMinOffset(position);

      for (final cellNum in position) {
        final localX = (cellNum - 1) % 5 - minOffset.$1;
        final localY = (cellNum - 1) ~/ 5 - minOffset.$2;
        final pieceX = selectedPiece.gridX + localX;
        final pieceY = selectedPiece.gridY + localY;

        if (pieceX == logicalX && pieceY == logicalY) {
          isReferenceCell =
          (localX == state.selectedCellInPiece!.x &&
              localY == state.selectedCellInPiece!.y);
          break;
        }
      }
    }

    // 4️⃣ DÉTECTER LA PREVIEW
    // Pendant le drag, ne pas bloquer le preview sur les cellules sélectionnées
    final previewInfo = _detectPreview(
      state,
      logicalX,
      logicalY,
      state.isDragging ? false : isSelected,
      settings,
    );

    if (previewInfo.isPreview && previewInfo.previewColor != null) {
      cellColor = previewInfo.previewColor!;
    }

    // 5️⃣ DÉTERMINER LE TEXTE
    String cellText = _getCellText(cellValue, isSolutionCell, solutionPieceId);

    if (isSelected && selectedInfo.selectedText != null) {
      cellText = selectedInfo.selectedText!;
    } else if (previewInfo.isPreview && previewInfo.previewText != null) {
      cellText = previewInfo.previewText!;
    }

    // 6️⃣ CALCULER LA BORDURE
    Border border = _calculateBorder(
      state,
      // ✅ AJOUTER en premier!
      isReferenceCell,
      previewInfo.isPreview,
      isSelected,
      previewInfo.isSnappedPreview,
      previewInfo.isPreviewValid,
      logicalX,
      logicalY,
      isLandscape,
    );

    // 7️⃣ CRÉER LE WIDGET DE CELLULE
    Widget cellWidget = Container(
      decoration: BoxDecoration(
        color: cellColor,
        border: border,
        boxShadow: previewInfo.isSnappedPreview && previewInfo.isPreviewValid
            ? [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),
      child: Center(
        child: Text(
          cellText,
          style: TextStyle(
            color: _getTextColor(
              previewInfo.isPreview,
              isSelected,
              previewInfo.isPreviewValid,
              previewInfo.isSnappedPreview,
            ),
            fontWeight: _getTextWeight(previewInfo.isPreview, isSelected),
            fontSize: _getTextSize(isSelected, previewInfo.isPreview, cellSize),
          ),
        ),
      ),
    );

    // 8️⃣ GÉRER LES INTERACTIONS
    bool isOccupied = cellValue > 0;

    if (isSelected && state.selectedPiece != null) {
      // Pièce sélectionnée: draggable
      final emptyCell = Container(color: Colors.grey.shade300);
      cellWidget = Draggable<Pento>(
        data: state.selectedPiece!,
        // Correctif 1 (§4) — pointerDragAnchorStrategy : details.offset devient
        // EXACTEMENT la position globale du doigt (plus le décalage intra-case du
        // childDragAnchorStrategy, mécanisme (a) du plan).
        // Le log kDebugMode du commit 0 subsiste : on calcule encore la position
        // intra-case (childDragAnchorStrategy) pour la mesure, sans l'utiliser.
        dragAnchorStrategy: (draggable, dragContext, position) {
          if (kDebugMode) {
            final within = childDragAnchorStrategy(draggable, dragContext, position);
            debugPrint(
              '[drag-instr] caseSaisie=($logicalX,$logicalY) '
              'masterAbs=${state.selectedMasterAbs} '
              'dragStartPoint=(${within.dx.toStringAsFixed(1)},${within.dy.toStringAsFixed(1)}) '
              'cellSize=${cellSize.toStringAsFixed(1)}',
            );
          }
          return pointerDragAnchorStrategy(draggable, dragContext, position);
        },
        onDragStarted: () {
          // Correctif 2 (§4) : ancrer sur la case saisie (logicalX/logicalY, disponible
          // ici) avant tout, pour que _calculateDesiredAnchorFromDrag translate depuis
          // le doigt et non depuis la case tapée à la sélection (mécanisme (b)).
          notifier.setDragMastercase(logicalX, logicalY);
          notifier.setDragging(true);
        },
        onDragEnd: (_) => notifier.setDragging(false),
        // Correctif 1 (§4), suite cosmétique : avec pointerDragAnchorStrategy le coin
        // haut-gauche du feedback se pose sous le doigt. FractionalTranslation(-0.5,-0.5)
        // le recentre — soit −feedbackSize/2 sur chaque axe, sans calculer la taille.
        feedback: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: Material(
            color: Colors.transparent,
            child: PieceRenderer(
              piece: state.selectedPiece!,
              positionIndex: _getDisplayPositionIndex(
                state.selectedPositionIndex,
                state.selectedPiece!,
                isLandscape,
              ),
              isDragging: true,
              // 🔎 La miniature sous le doigt suit l'échelle du plateau (§4a), au lieu de 22.
              cellSize: cellSize * kPieceToBoardCellRatio,
              getPieceColor: (pieceId) => settings.ui.getPieceColor(pieceId),
            ),
          ),
        ),
        childWhenDragging: previewInfo.isPreview ? cellWidget : emptyCell,
        child: state.isDragging
            ? (previewInfo.isPreview ? cellWidget : emptyCell)
            : GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.selectPlacedPiece(
                    state.selectedPlacedPiece!,
                    logicalX,
                    logicalY,
                  );
                },
                onDoubleTap: () {
                  HapticFeedback.selectionClick();
                  notifier.applyIsometryRotationTW();
                },
                child: cellWidget,
              ),
      );
    } else if (isOccupied && !isSelected) {
      // Pièce placée non sélectionnée: sélectionnable
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
      // Case vide avec pièce sélectionnée: annuler sélection
      cellWidget = GestureDetector(
        onTap: () {
          notifier.cancelSelection();
        },
        child: cellWidget,
      );
    }

    return cellWidget;
  }

  /// Détermine la bordure à afficher
  Border _calculateBorder(
      PentoscopeState state, // ✅ AJOUTER
      bool isReferenceCell,
      bool isPreview,
      bool isSelected,
      bool isSnappedPreview,
      bool isPreviewValid,
      int logicalX,
      int logicalY,
      bool isLandscape,
      ) {
    // Mastercase
    if (isReferenceCell) return Border.all(color: Colors.red, width: 4);

    // Preview
    if (isPreview) {
      if (isPreviewValid) {
        if (isSnappedPreview) {
          return Border.all(color: Colors.cyan.shade400, width: 3);
        } else {
          return Border.all(color: Colors.green, width: 3);
        }
      } else {
        return Border.all(color: Colors.red, width: 3);
      }
    }

    // Pièce sélectionnée
    if (isSelected) return Border.all(color: Colors.amber, width: 3);

    // Bordure fusionnée normale
    return PieceBorderCalculator.calculate(
      logicalX,
      logicalY,
      state.plateau,
      isLandscape,
    );
  }

  /// Détecte si une preview est à cette cellule
  ({
  bool isPreview,
  Color? previewColor,
  String? previewText,
  bool isSnappedPreview,
  bool isPreviewValid,
  })
  _detectPreview(
      PentoscopeState state,
      int logicalX,
      int logicalY,
      bool isSelected,
      dynamic settings,
      ) {
    if (isSelected ||
        state.selectedPiece == null ||
        state.previewX == null ||
        state.previewY == null) {
      return (
      isPreview: false,
      previewColor: null,
      previewText: null,
      isSnappedPreview: false,
      isPreviewValid: false,
      );
    }

    final piece = state.selectedPiece!;
    final position = piece.orientations[state.selectedPositionIndex];
    final minOffset = _getMinOffset(position);

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5 - minOffset.$1;
      final localY = (cellNum - 1) ~/ 5 - minOffset.$2;
      final pieceX = state.previewX! + localX;
      final pieceY = state.previewY! + localY;

      if (pieceX == logicalX && pieceY == logicalY) {
        Color previewColor;
        bool isSnappedPreview = state.isSnapped;

        if (state.isPreviewValid) {
          if (isSnappedPreview) {
            previewColor = settings.ui
                .getPieceColor(piece.id)
                .withValues(alpha: 0.6);
          } else {
            previewColor = settings.ui
                .getPieceColor(piece.id)
                .withValues(alpha: 0.4);
          }
        } else {
          previewColor = Colors.red.withValues(alpha: 0.3);
        }

        return (
        isPreview: true,
        previewColor: previewColor,
        previewText: piece.id.toString(),
        isSnappedPreview: isSnappedPreview,
        isPreviewValid: state.isPreviewValid,
        );
      }
    }

    return (
    isPreview: false,
    previewColor: null,
    previewText: null,
    isSnappedPreview: false,
    isPreviewValid: false,
    );
  }

  /// Détecte si une pièce placée est sélectionnée à cette cellule
  ({bool isSelected, Color? selectedColor, String? selectedText})
  _detectSelectedPlacedPiece(
      PentoscopeState state,
      int logicalX,
      int logicalY,
      int cellValue,
      dynamic settings,
      ) {
    if (state.selectedPlacedPiece == null) {
      return (isSelected: false, selectedColor: null, selectedText: null);
    }

    final selectedPiece = state.selectedPlacedPiece!;
    final position = selectedPiece.piece.orientations[state.selectedPositionIndex];
    final minOffset = _getMinOffset(position);

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5 - minOffset.$1;
      final localY = (cellNum - 1) ~/ 5 - minOffset.$2;
      final pieceX = selectedPiece.gridX + localX;
      final pieceY = selectedPiece.gridY + localY;

      if (pieceX == logicalX && pieceY == logicalY) {
        Color selectedColor = settings.ui.getPieceColor(selectedPiece.piece.id);

        if (cellValue == 0) {
          selectedColor = settings.ui.getPieceColor(selectedPiece.piece.id);
        }

        return (
        isSelected: true,
        selectedColor: selectedColor,
        selectedText: selectedPiece.piece.id.toString(),
        );
      }
    }

    return (isSelected: false, selectedColor: null, selectedText: null);
  }

  /// Détermine la couleur de base de la cellule
  Color _getBaseCellColor(
      int cellValue,
      bool isSolution,
      int? solutionPieceId,
      dynamic settings,
      ) {
    // Bordure de plateau
    if (cellValue == -1) return Colors.grey.shade800;

    // Cellule vide avec solution → afficher couleur VRAIE de la pièce!
    if (cellValue == 0 && isSolution && solutionPieceId != null) {
      return settings.ui
          .getPieceColor(solutionPieceId)
          .withOpacity(0.6); // ✅ COULEUR VRAIE!
    }
    // Cellule vide normale
    if (cellValue == 0) return Colors.grey.shade300;

    // Pièce placée
    return settings.ui.getPieceColor(cellValue);
  }

  /// Texte à afficher dans la cellule
  String _getCellText(int cellValue, bool isSolution, int? solutionPieceId) {
    // Solution: afficher numéro de pièce
    if (isSolution && solutionPieceId != null) {
      return solutionPieceId.toString();
    }

    // Pièce occupée: afficher son numéro
    if (cellValue > 0) return cellValue.toString();

    // Vide: rien
    return '';
  }

  int _getDisplayPositionIndex(
      int positionIndex,
      Pento piece,
      bool isLandscape,
      ) {
    if (isLandscape) {
      return (positionIndex - 1 + piece.numOrientations) % piece.numOrientations;
    }
    return positionIndex;
  }

  /// Calcule le décalage minimum pour normaliser une forme
  (int, int) _getMinOffset(List<int> position) {
    int minX = 5, minY = 5;
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (localX < minX) minX = localX;
      if (localY < minY) minY = localY;
    }
    return (minX, minY);
  }

  /// Récupère le numéro de pièce solution à une cellule donnée
  int? _getSolutionPieceIdAt(
      PentoscopeState state,
      int logicalX,
      int logicalY,
      ) {
    if (state.currentSolution == null) return null;

    for (final placement in state.currentSolution!) {
      final piece = placement.piece;
      final position = piece.orientations[placement.positionIndex];

      // Calculer le minOffset pour normalisation
      int minLocalX = 5, minLocalY = 5;
      for (final cellNum in position) {
        final lx = (cellNum - 1) % 5;
        final ly = (cellNum - 1) ~/ 5;
        if (lx < minLocalX) minLocalX = lx;
        if (ly < minLocalY) minLocalY = ly;
      }

      // Chercher la cellule
      for (final cellNum in position) {
        final localX = (cellNum - 1) % 5 - minLocalX;
        final localY = (cellNum - 1) ~/ 5 - minLocalY;
        final absX = placement.gridX + localX;
        final absY = placement.gridY + localY;

        if (absX == logicalX && absY == logicalY) {
          return placement.piece.id;
        }
      }
    }
    return null;
  }

  /// Couleur du texte selon le contexte
  Color _getTextColor(
      bool isPreview,
      bool isSelected,
      bool isPreviewValid,
      bool isSnappedPreview,
      ) {
    if (isPreview) {
      if (isPreviewValid) {
        return isSnappedPreview ? Colors.cyan.shade900 : Colors.green.shade900;
      } else {
        return Colors.red.shade900;
      }
    }
    return Colors.white;
  }

  /// Taille du numéro sur une case, proportionnelle à la case (§4e) au lieu de 14/16 fixes :
  /// sur iPad la case est 2× plus grande, le texte doit suivre. Ratios calés pour reproduire
  /// ≈ 14/16 sur iPhone (case ≈ 76) et grandir ensuite ; plancher pour rester lisible.
  double _getTextSize(bool isSelected, bool isPreview, double cellSize) {
    final ratio = (isSelected || isPreview) ? 0.21 : 0.18;
    return (cellSize * ratio).clamp(11.0, 48.0);
  }

  /// Épaisseur du texte
  FontWeight _getTextWeight(bool isSelected, bool isPreview) {
    return (isSelected || isPreview) ? FontWeight.w900 : FontWeight.bold;
  }

  /// Détecte si cette cellule est une pièce solution
  bool _isSolutionCell(PentoscopeState state, int logicalX, int logicalY) {
    return _getSolutionPieceIdAt(state, logicalX, logicalY) != null;
  }
}