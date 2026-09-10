// Modified: 2026-09-10 06:48 — C8/décision 7 : numéro d'une pièce posée = UNE pastille (case haut-gauche,
//           labelCells) au lieu du chiffre sur les 5 cases, optionnel via settings.game.showPieceNumbers,
//           agrandie (≈0,5 case, retour de Paul). Miniature de drag = cellSize × rackCellRatio (décision 6).
// Historique: 2026-09-09 07:35 — ancre à la bonne échelle : onMove ré-ajoute localGrab (notifier.dragGrabLocal)
//           à details.offset pour reconstruire le doigt réel — sinon un offset à l'échelle du rack était
//           mappé en case plateau → ancre décalée ~1 case selon la prise (bord bas). Portrait + rack.
// Historique: 2026-09-09 07:01 — marge latérale en portrait (kBoardSideMargin) : availableWidth réserve
//           2×marge → un grand plateau ne prend plus toute la largeur, le doigt garde de la place pour
//           positionner près d'un bord (suivi 1:1). Cohérent avec _barMetrics (§3).
// Historique: 2026-09-09 06:06 — pose de la ligne du bas : onLeave ne fait PLUS clearPreview() (le bord
//           bas est collé au rack ; effleurer le rack effaçait l'ancre → dépôt perdu). L'aperçu valide
//           survit et le rack le pose (cf. pentoscope_game_screen _buildSliderWithDragTarget).
// Historique: 2026-09-07 16:45 — (1) glissé « suivi exact » : feedback réactif (image RÉELLE si posable,
//           TRANSPARENT si chevauchement, observe isPreviewValid) ; (2) plafond de case PROPORTIONNEL
//           à l'écran (kMaxBoardCellFactor) au lieu de l'absolu 84 qui rapetissait tout sur tablette.
// Historique: 2026-09-07 09:13 — taille des pièces : cellSize plafonné par kMaxBoardCellSize (borne
//           haute partagée avec _barMetrics) — supprime la « falaise » de réduction des petits plateaux.
// Historique: 2026-09-06 04:50 — i18n : « Aucun puzzle » via AppLocalizations.
// Historique: 2026-09-02 09:42 — #6 répartition verticale : en portrait le plateau est ancré en bas
//           (Alignment.bottomCenter) au lieu d'être centré ; offsetY du hit-test drag couplé au
//           même alignement (portrait = bas, paysage = haut) sinon le dépôt viserait le centre.
// lib/pentoscope/widgets/pentoscope_board.dart
// Historique: 2026-09-02 04:31 — retrait du log DRAGDIAG event=drop dans onAccept et de l'import
//           drag_diag : diagnostic terminé, le dépôt à l'ancre de l'aperçu est conservé tel quel.
// Historique: 2026-09-01 15:45 — prise stable : onDragStarted ancre la mastercase sur la cellule
//           empoignée (setDragMastercase(logicalX,logicalY)) avant setDragging — la référence ne
//           dépend plus du dernier tap. (Dépôt à l'aperçu / fourche A/B conservé.)
// Historique: 2026-09-01 15:30 — fourche A/B : onAccept dépose à l'ancre de l'aperçu
//             (tryPlaceAtAnchor(previewX,previewY)), plus de reconstruction. + log event=drop.
// Historique: 2026-08-31 16:00 — regroupement des réglages visuels : kPieceToBoardCellRatio n'est
//             plus défini ici mais en tête de pentoscope_game_screen.dart (importé). Valeur (0.35).
// Historique: 2026-08-31 15:00 — réglage à l'œil : kPieceToBoardCellRatio 0.45 → 0.35.
// Historique: 2026-08-30 13:50 — PLAN_ERGONOMIE §6 étape 4 : le numéro sur une case suit cellSize.
// Historique: 2026-08-30 13:35 — étape 2 : le feedback de drag (« miniature ») prend la taille de
//             case du plateau × k ; _buildCell reçoit cellSize ; constante kPieceToBoardCellRatio.
// Historique: 2026-08-28 20:48 — suppression de la démonstration : retrait du champ et des
//             méthodes de surbrillance locale et des deux méthodes de démonstration du State.
//             2026-08-27 20:46 — retrait de _showVictoryDialog, orpheline (54 lignes).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';

import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/common/widgets/piece_border_calculator.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
// Constantes de layout regroupées en tête de pentoscope_game_screen.dart. Le rapport pièce/plateau
// vient désormais du réglage live `settings.game.rackCellRatio` (feedback de drag), plus du const.
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart'
    show kMaxBoardCellFactor, kBoardSideMargin;

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
      return Center(child: Text(AppLocalizations.of(context).noPuzzle));
    }

    final boardWidth = puzzle.size.width;
    final boardHeight = puzzle.size.height;

    // Case « étiquette » de chaque pièce posée : la plus haute puis la plus à gauche (C8). Le
    // numéro (pastille unique) n'y est peint que là — plus le chiffre répété sur les 5 cases.
    // Balayage y externe / x interne → premier rencontré = coin haut-gauche.
    final Set<Point> labelCells = {};
    {
      final seen = <int>{};
      for (int y = 0; y < boardHeight; y++) {
        for (int x = 0; x < boardWidth; x++) {
          final v = state.plateau.getCell(x, y);
          if (v > 0 && seen.add(v)) labelCells.add(Point(x, y));
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Dimensions visuelles (swap si paysage)
        final visualCols = widget.isLandscape ? boardHeight : boardWidth;
        final visualRows = widget.isLandscape ? boardWidth : boardHeight;

        // Portrait : réserver kBoardSideMargin de chaque côté pour que le doigt garde de la place
        // en positionnant près d'un bord (suivi 1:1) — un grand plateau prenait toute la largeur.
        // Paysage : pas de marge (le plateau a plus d'espace, et l'axe critique n'est pas horizontal).
        final availableWidth = widget.isLandscape
            ? constraints.maxWidth
            : constraints.maxWidth - 2 * kBoardSideMargin;
        // Plafond de hauteur ET plafond partagé (proportionnel à l'écran, kMaxBoardCellFactor) :
        // atténue la « falaise » des petits plateaux sans les rapetisser sur une grande tablette.
        final maxCell = MediaQuery.of(context).size.shortestSide * kMaxBoardCellFactor;
        final heightCap = constraints.maxHeight / visualRows;
        final upperCap = heightCap < maxCell ? heightCap : maxCell;
        final cellSize =
            (availableWidth / visualCols).clamp(0.0, upperCap).toDouble();

        final gridWidth = cellSize * visualCols;
        final gridHeight = cellSize * visualRows;

        // Offset du plateau — DOIT suivre l'Align visuel plus bas, sinon le hit-test du
        // drag (plateauY = localY − offsetY) viserait un plateau ailleurs que là où il est
        // dessiné. Centré horizontalement ; portrait ancré en bas, paysage ancré en haut.
        final offsetX = (constraints.maxWidth - gridWidth) / 2;
        final offsetY = widget.isLandscape
            ? 0.0
            : (constraints.maxHeight - gridHeight);

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

            // Reconstruction du doigt réel. `details.offset` est le coin du feedback, ancré par la
            // case empoignée : `details.offset = doigt − localGrab`. Sans le ré-ajout de localGrab,
            // on mappe un point à l'échelle du RACK dans une case du PLATEAU → l'ancre se décale de
            // ~1 case selon la ligne empoignée (bord bas impossible ; « aléatoire », retour de Paul).
            // Portrait + pièce du RACK seulement (le paysage swappe les axes ; la pièce posée suit une
            // autre branche — masterAbs — inchangée).
            final grab = (!widget.isLandscape && state.selectedPlacedPiece == null)
                ? (notifier.dragGrabLocal ?? Offset.zero)
                : Offset.zero;

            // Coordonnées relatives au plateau centré
            final plateauX = localOffset.dx + grab.dx - offsetX;
            final plateauY = localOffset.dy + grab.dy - offsetY;

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
            // NE PAS effacer l'aperçu en sortant du plateau. La ligne du bas est collée au rack :
            // en visant une case basse, le doigt effleure le rack et déclenchait ce onLeave, qui
            // effaçait previewX/Y → au relâcher, plus d'ancre, dépôt perdu (« s'y reprendre à
            // plusieurs fois »). On garde la dernière position valide ; le rack sait la poser
            // (voir _buildSliderWithDragTarget). Le commentaire l'exigeait déjà ; le clearPreview
            // était une régression contraire à l'intention.
          },
          onAcceptWithDetails: (details) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) {
              notifier.clearPreview();
              return;
            }

            if (state.previewX == null || state.previewY == null) {
              notifier.clearPreview();
              return;
            }

            // Fourche A/B (JOURNAL) : déposer DIRECTEMENT à l'ancre de l'aperçu (previewX/Y,
            // déjà snappée et validée) au lieu de reconstruire un faux doigt puis de re-dériver
            // — c'est cette re-dérivation qui replaçait la pièce `−minY` plus haut au relâcher.
            // Ce que l'aperçu montre est exactement ce qui se pose.
            final success = notifier.tryPlaceAtAnchor(state.previewX!, state.previewY!);

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
              // En paysage : aligner en haut (le rab vertical passe en bas).
              // En portrait : ancrer en bas — le plateau (carré, borné par la largeur)
              // se groupe avec la barre de pièces, tout le rab vertical passe en haut,
              // sous la barre d'icônes (lu comme respiration d'en-tête) plutôt que réparti
              // en deux marges qui font « flotter » le plateau.
              alignment:
                  widget.isLandscape ? Alignment.topCenter : Alignment.bottomCenter,
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
                        labelCells,
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
      Set<Point> labelCells,
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
    // C8 : pour une pièce posée, le numéro n'apparaît que sur sa case étiquette (pastille unique)
    // et seulement si le réglage `showPieceNumbers` est actif.
    final bool isPieceLabelCell = labelCells.contains(Point(logicalX, logicalY));
    String cellText = _getCellText(cellValue, isSolutionCell, solutionPieceId,
        isPieceLabelCell, settings.game.showPieceNumbers);

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
            // La pastille unique d'une pièce posée (C8) est seule sur la pièce → nettement plus
            // grosse que l'ancien chiffre répété. Les numéros de solution (5 par pièce) gardent
            // leur petite taille pour ne pas se chevaucher.
            fontSize: _getTextSize(
              isSelected,
              previewInfo.isPreview,
              cellSize,
              isSinglePastille: cellValue > 0 &&
                  !isSolutionCell &&
                  !isSelected &&
                  !previewInfo.isPreview &&
                  isPieceLabelCell,
            ),
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
        onDragStarted: () {
          // Ancrer la mastercase sur la cellule empoignée (logicalX/Y), pas sur le dernier tap :
          // la prise devient stable et la direction est mesurée depuis le doigt.
          notifier.setDragMastercase(logicalX, logicalY);
          notifier.setDragging(true);
        },
        onDragEnd: (_) => notifier.setDragging(false),
        feedback: Material(
          color: Colors.transparent,
          // Feedback réactif : image réelle si la pose est valide, TRANSPARENT si elle chevauche
          // (méthode « validité = couleur », 2026-09-07). Le Consumer se reconstruit à chaque
          // updatePreview → bascule réel ↔ transparent en direct pendant le glissé.
          child: Consumer(
            builder: (context, ref, _) {
              final valid = ref
                  .watch(pentoscopeProvider.select((s) => s.isPreviewValid));
              return Opacity(
                opacity: valid ? 1.0 : 0.0,
                child: PieceRenderer(
                  piece: state.selectedPiece!,
                  positionIndex: _getDisplayPositionIndex(
                    state.selectedPositionIndex,
                    state.selectedPiece!,
                    isLandscape,
                  ),
                  isDragging: true,
                  // 🔎 La miniature sous le doigt suit l'échelle du plateau (§4a), au lieu de 22.
                  // Réglage live `rackCellRatio` (même source que le rack) → la pièce garde la
                  // même taille du rack au doigt quand Paul calibre en direct.
                  cellSize: cellSize * settings.game.rackCellRatio,
                  getPieceColor: (pieceId) => settings.ui.getPieceColor(pieceId),
                ),
              );
            },
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
  String _getCellText(int cellValue, bool isSolution, int? solutionPieceId,
      bool isPieceLabelCell, bool showPieceNumbers) {
    // Solution: afficher numéro de pièce (vue réponse, hors périmètre C8 — inchangée).
    if (isSolution && solutionPieceId != null) {
      return solutionPieceId.toString();
    }

    // Pièce posée (C8) : une seule pastille, sur la case étiquette, si le réglage l'autorise.
    if (cellValue > 0) {
      return (showPieceNumbers && isPieceLabelCell) ? cellValue.toString() : '';
    }

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
  double _getTextSize(bool isSelected, bool isPreview, double cellSize,
      {bool isSinglePastille = false}) {
    // Pastille unique d'une pièce posée (C8) : seule sur la pièce → grosse (≈ 0,5 case).
    if (isSinglePastille) return (cellSize * 0.5).clamp(16.0, 60.0);
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