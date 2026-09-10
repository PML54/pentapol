// Modified: 2026-09-10 10:13 — pièce visible dès la prise du rack, contour rouge tant que le dépôt est interdit.
// Historique: 2026-09-10 06:00 — ergonomie (bloc 3, C6) : fondu de bord du rack SENSIBLE au défilement.
//           Fondu de tête seulement si on a défilé (offset > 0) → la 1re pièce n'est jamais rognée
//           (C6) ; fondu de queue tant qu'il reste des pièces après → suggère au nouveau joueur (3×5)
//           que le rack défile, sans rétrécir les pièces (respecte l'invariant #3). ShaderMask dstIn.
// Historique: 2026-09-09 07:35 — drag rack, ancre à la bonne échelle : onGrab passe aussi grabLocal
//           (offset px du toucher) à selectPiece — le plateau reconstruit le doigt réel dans onMove.
// Historique: 2026-09-07 16:30 — glissé « suivi exact » : le feedback tiroir (image sous le doigt)
//           devient réactif — image RÉELLE si posable, TRANSPARENT si chevauchement (isPreviewValid).
// Historique: 2026-09-07 09:35 — halo de sélection lisible sur pièce jaune (N°3) : le halo ambré seul
//           ne contrastait pas ; ajout d'un contour sombre net par-dessus (visible quelle que soit
//           la couleur de la pièce, palettes perso incluses).
// Historique: 2026-09-03 07:10 — fix drag tiroir : onGrab calcule la cellule empoignée (_grabbedCell,
//           depuis l'offset du toucher, centrage + marge PieceRenderer, valable en paysage) et la
//           passe à selectPiece(grabbedCell:) → le placement colle au doigt comme sur le plateau.
// Historique: 2026-09-01 09:01 — zone tactile pleine boîte (hitBoxSize = fixedSize) pour attraper le
//           « I » aussi bien que les autres ; le halo de sélection passe dans childBuilder, collé à
//           la pièce et affiché au repos seulement (pas sur le feedback de drag).
// lib/pentoscope/widgets/pentoscope_piece_slider.dart
// Historique: 2026-08-30 13:35 — PLAN_ERGONOMIE §6 étape 2 : la barre reçoit pieceCellSize (défaut
//             22) ; la boîte de pièce et PieceRenderer en dérivent, au lieu de la taille figée 118.
// Historique: 2026-08-28 20:48 — suppression de la démonstration : retrait du champ et des
//             méthodes de surbrillance locale et du bloc lecteur ; l'enveloppe Container disparaît.
//             2512100457 — FIX _getDisplayPositionIndex() rotation paysage stable.

import 'package:flutter/material.dart';
import 'package:pentapol/pentoscope/widgets/piece_drag_feedback.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/common/widgets/draggable_piece_widget.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';

class PentoscopePieceSlider extends ConsumerStatefulWidget {
  final bool isLandscape;

  /// Taille de case des pièces de la barre, ancrée sur le plateau (PLAN_ERGONOMIE §3).
  /// Défaut 22 : comportement d'avant l'ergonomie tablette pour tout appelant non modifié.
  final double pieceCellSize;

  const PentoscopePieceSlider({
    super.key,
    required this.isLandscape,
    this.pieceCellSize = 22.0,
  });

  @override
  ConsumerState<PentoscopePieceSlider> createState() => _PentoscopePieceSliderState();

  // Méthode statique pour accéder au state depuis l'extérieur
  static _PentoscopePieceSliderState? of(BuildContext context) {
    return context.findAncestorStateOfType<_PentoscopePieceSliderState>();
  }
}

class _PentoscopePieceSliderState extends ConsumerState<PentoscopePieceSlider> {
  final ScrollController _scrollController = ScrollController();

  /// Fondu de bord (C6) : `_showLeadingFade` = du contenu défilé avant le bord de tête ;
  /// `_showTrailingFade` = du contenu reste après le bord de queue. Recalculés au défilement
  /// et après chaque layout (le débordement dépend du nombre de pièces et de leur taille).
  bool _showLeadingFade = false;
  bool _showTrailingFade = false;

  /// Fraction de la longueur du rack occupée par chaque fondu.
  static const double _kFadeFraction = 0.08;

  void _updateFades() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final leading = pos.pixels > 1.0;
    final trailing = pos.pixels < pos.maxScrollExtent - 1.0;
    if (leading != _showLeadingFade || trailing != _showTrailingFade) {
      setState(() {
        _showLeadingFade = leading;
        _showTrailingFade = trailing;
      });
    }
  }

  void selectPiece(int pieceIndex) {
    final state = ref.read(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);

    if (pieceIndex >= 0 && pieceIndex < state.availablePieces.length) {
      final piece = state.availablePieces[pieceIndex];
      notifier.selectPiece(piece);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = context as WidgetRef;
    final state = ref.watch(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);
    final settings = ref.read(settingsProvider);
    

    final pieces = state.availablePieces;

    if (pieces.isEmpty) {
      return const SizedBox.shrink();
    }

    final scrollDirection = widget.isLandscape ? Axis.vertical : Axis.horizontal;
    final padding = widget.isLandscape
        ? const EdgeInsets.symmetric(vertical: 16, horizontal: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    // Recalcul du débordement après ce layout (le nombre de pièces vient de changer, etc.).
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());

    final listView = ListView.builder(
      controller: _scrollController,
      scrollDirection: scrollDirection,
      padding: padding,
      itemCount: pieces.length,
      itemBuilder: (context, index) {
        final piece = pieces[index];

        return _buildDraggablePiece(piece, notifier, state, settings, widget.isLandscape);
      },
    );

    // Fondu de bord (C6) : n'apparaît que du côté où il reste du contenu à défiler. Au repos
    // (offset 0) → pas de fondu de tête, la 1re pièce est nette ; un fondu de queue suggère qu'il
    // y en a plus. ShaderMask/dstIn : l'alpha du dégradé masque le contenu (blanc = opaque,
    // transparent = effacé). Le feedback de drag est rendu dans un Overlay, hors de ce sous-arbre :
    // la pièce glissée n'est pas affectée par le fondu.
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _updateFades();
        return false;
      },
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) {
          final begin = widget.isLandscape
              ? Alignment.topCenter
              : Alignment.centerLeft;
          final end = widget.isLandscape
              ? Alignment.bottomCenter
              : Alignment.centerRight;
          return LinearGradient(
            begin: begin,
            end: end,
            colors: [
              _showLeadingFade ? Colors.transparent : Colors.white,
              Colors.white,
              Colors.white,
              _showTrailingFade ? Colors.transparent : Colors.white,
            ],
            stops: const [0.0, _kFadeFraction, 1 - _kFadeFraction, 1.0],
          ).createShader(rect);
        },
        child: listView,
      ),
    );
  }

  /// Convertit positionIndex interne en displayPositionIndex pour l'affichage
  int _getDisplayPositionIndex(int positionIndex, Pento piece, bool isLandscape) {
    return positionIndex; // ✅ plus de -1 / modulo
  }

  /// Dimension max de la pièce (en cases) sur **toutes** ses orientations : côté d'une boîte
  /// carrée qui contient n'importe quelle orientation. Constante par pièce → la boîte ne change
  /// pas quand on tourne la pièce (pas de reflow du rack). I = 5, L/N/Y = 4, les autres = 3.
  int _pieceMaxDim(Pento piece) {
    int maxDim = 1;
    for (int i = 0; i < piece.numOrientations; i++) {
      int minX = 5, minY = 5, maxX = 0, maxY = 0;
      for (final n in piece.orientations[i]) {
        final x = (n - 1) % 5;
        final y = (n - 1) ~/ 5;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
      final w = maxX - minX + 1;
      final h = maxY - minY + 1;
      if (w > maxDim) maxDim = w;
      if (h > maxDim) maxDim = h;
    }
    return maxDim;
  }

  /// Cellule (normalisée) de la pièce sous le doigt au départ du drag. [localGrab] est l'offset
  /// local dans la boîte du widget (côté [box.width] = fixedSize), la pièce étant centrée et rendue
  /// par PieceRenderer (case = pieceCellSize, +4 de marge interne). Renvoie la cellule réelle la
  /// plus proche (le toucher peut tomber sur un creux de la forme). null si la pièce n'a pas de case.
  Point? _grabbedCell(Pento piece, int positionIndex, Offset localGrab, Size box) {
    final cellSize = widget.pieceCellSize;
    final cells = piece.orientations[positionIndex]
        .map((n) => Point((n - 1) % 5, (n - 1) ~/ 5))
        .toList();
    if (cells.isEmpty) return null;
    final minX = cells.map((c) => c.x).reduce(math.min);
    final minY = cells.map((c) => c.y).reduce(math.min);
    final norm = cells.map((c) => Point(c.x - minX, c.y - minY)).toList();
    final wCells = norm.map((c) => c.x).reduce(math.max) + 1;
    final hCells = norm.map((c) => c.y).reduce(math.max) + 1;
    final pieceW = wCells * cellSize + 8;
    final pieceH = hCells * cellSize + 8;
    final topLeftX = (box.width - pieceW) / 2;
    final topLeftY = (box.height - pieceH) / 2;
    // Position du doigt en unités de case dans le repère normalisé de la pièce.
    final gx = (localGrab.dx - topLeftX - 4) / cellSize;
    final gy = (localGrab.dy - topLeftY - 4) / cellSize;
    Point? best;
    double bestD = double.infinity;
    for (final c in norm) {
      final dx = (c.x + 0.5) - gx;
      final dy = (c.y + 0.5) - gy;
      final d = dx * dx + dy * dy;
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best;
  }


  Widget _buildDraggablePiece(
      Pento piece,
      PentoscopeNotifier notifier,
      PentoscopeState state,
      settings,
      bool isLandscape,
      ) {
    // Emplacement serré (C6, retour de Paul sur le 3×5) : au lieu d'une boîte carrée de 5 cases
    // pour tout le monde, la boîte fait la **dimension max de la pièce sur toutes ses orientations**
    // (3 à 5 cases). Carrée → n'importe quelle orientation y tient, donc **aucun reflow à la
    // rotation** ; côté = maxDim → les pièces se serrent (la plupart des 3×5 montrent leurs 3
    // pièces) sans jamais rétrécir la case (invariant #3). L'axe croisé garde la pleine épaisseur
    // de barre (5 cases) pour un centrage vertical stable.
    final double cell = widget.pieceCellSize;
    final double thickness = cell * 5 + 8;
    final double pieceBox = _pieceMaxDim(piece) * cell + 8;
    final double slotW = isLandscape ? thickness : pieceBox;
    final double slotH = isLandscape ? pieceBox : thickness;
    int positionIndex = state.selectedPiece?.id == piece.id
        ? state.selectedPositionIndex
        : state.getPiecePositionIndex(piece.id);

    // Convertir pour l'affichage
    int displayPositionIndex = _getDisplayPositionIndex(positionIndex, piece, isLandscape);

    final isSelected = state.selectedPiece?.id == piece.id;

    return SizedBox(
      width: slotW,
      height: slotH,
      child: Center(
        child: Transform.rotate(
          angle: isLandscape ? -math.pi / 2 : 0.0,
          child: DraggablePieceWidget(
            piece: piece,
            positionIndex: displayPositionIndex,
            isSelected: isSelected,
            selectedPositionIndex: isSelected ? displayPositionIndex : state.selectedPositionIndex,
            longPressDuration: Duration(milliseconds: settings.game.longPressDuration),
            // Toute la boîte de la case répond au doigt : le « I » (1 case) s'attrape comme le reste.
            // Carrée (côté = maxDim) → _grabbedCell centre correctement.
            hitBoxSize: pieceBox,
            onSelect: () {
              if (settings.game.enableHaptics) {
                HapticFeedback.selectionClick();
              }
              notifier.selectPiece(piece);
            },
            // Départ de drag : ancrer la pièce sur la cellule réellement empoignée (comme le
            // plateau), pour que le placement colle au doigt (fix : viser une case dispo depuis
            // le tiroir).
            onGrab: (localGrab, box) {
              ref.read(dragOverBoardProvider.notifier).update(false);
              if (settings.game.enableHaptics) {
                HapticFeedback.selectionClick();
              }
              final cell =
                  _grabbedCell(piece, displayPositionIndex, localGrab, box);
              // grabLocal (px du toucher dans la boîte) : le plateau reconstruit le doigt réel
              // (details.offset + localGrab) → ancre à la bonne échelle (fin de l'erreur ~1 case).
              notifier.selectPiece(piece, grabbedCell: cell, grabLocal: localGrab);
            },
            onCycle: () {},
            onCancel: () {
              if (settings.game.enableHaptics) {
                HapticFeedback.lightImpact();
              }
              notifier.cancelSelection();
            },
            // Halo ambré de sélection collé à la pièce (auparavant un Container externe, qui serait
            // devenu un grand carré une fois la boîte tactile élargie).
            childBuilder: (isDragging) {
              final renderer = PieceRenderer(
                piece: piece,
                positionIndex: displayPositionIndex,
                isDragging: isDragging,
                cellSize: widget.pieceCellSize,
                getPieceColor: (pieceId) => settings.ui.getPieceColor(pieceId),
              );
              // Visible dès la prise, rouge hors plateau ou si le placement est interdit.
              if (isDragging) {
                return PieceDragFeedback(piece: piece, positionIndex: displayPositionIndex,
                  cellSize: widget.pieceCellSize,
                  getPieceColor: (id) => settings.ui.getPieceColor(id));
              }
              // Halo au repos seulement (pièce sélectionnée, immobile).
              if (!isSelected) return renderer;
              return DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    // Halo ambré « sélection » (langage cohérent avec l'ampoule).
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.85),
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                    // Contour sombre net PAR-DESSUS le halo : garantit une limite visible même quand
                    // la pièce est elle-même jaune/ambrée (ex. N°3), où l'ambre seul ne contraste pas.
                    // Dernier de la liste = peint au-dessus.
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 1.5,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
                child: renderer,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}