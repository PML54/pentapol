// Modified: 2026-09-03 07:10 — fix drag tiroir : onGrab calcule la cellule empoignée (_grabbedCell,
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

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: scrollDirection,
      padding: padding,
      itemCount: pieces.length,
      itemBuilder: (context, index) {
        final piece = pieces[index];

        return _buildDraggablePiece(piece, notifier, state, settings, widget.isLandscape);
      },
    );
  }

  /// Convertit positionIndex interne en displayPositionIndex pour l'affichage
  int _getDisplayPositionIndex(int positionIndex, Pento piece, bool isLandscape) {
    return positionIndex; // ✅ plus de -1 / modulo
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
    // Boîte carrée d'une pièce : 5 cases + 8 de marge (PieceRenderer). Suit pieceCellSize.
    final double fixedSize = widget.pieceCellSize * 5 + 8;
    int positionIndex = state.selectedPiece?.id == piece.id
        ? state.selectedPositionIndex
        : state.getPiecePositionIndex(piece.id);

    // Convertir pour l'affichage
    int displayPositionIndex = _getDisplayPositionIndex(positionIndex, piece, isLandscape);

    final isSelected = state.selectedPiece?.id == piece.id;

    return SizedBox(
      width: fixedSize,
      height: fixedSize,
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
            hitBoxSize: fixedSize,
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
              if (settings.game.enableHaptics) {
                HapticFeedback.selectionClick();
              }
              final cell =
                  _grabbedCell(piece, displayPositionIndex, localGrab, box);
              notifier.selectPiece(piece, grabbedCell: cell);
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
              // Halo au repos seulement : la pièce en cours de glissement ne le porte pas.
              if (!isSelected || isDragging) return renderer;
              return DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.7),
                      blurRadius: 14,
                      spreadRadius: 2,
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