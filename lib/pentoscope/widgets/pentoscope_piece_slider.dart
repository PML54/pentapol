// Modified: 2026-08-30 13:35 — PLAN_ERGONOMIE §6 étape 2 : la barre reçoit pieceCellSize (défaut
//           22) ; la boîte de pièce et PieceRenderer en dérivent, au lieu de la taille figée 118.
// lib/pentoscope/widgets/pentoscope_piece_slider.dart
// Historique: 2026-08-28 20:48 — suppression de la démonstration : retrait du champ et des
//             méthodes de surbrillance locale et du bloc lecteur ; l'enveloppe Container disparaît.
//             2512100457 — FIX _getDisplayPositionIndex() rotation paysage stable.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/common/pentominos.dart';
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
      child: Container(
        decoration: BoxDecoration(
          boxShadow: isSelected
              ? [
            BoxShadow(
                        color: Colors.amber.withOpacity(0.7),
                        blurRadius: 14,
                        spreadRadius: 2,
            ),
          ]
              : null,
        ),
              child: DraggablePieceWidget(
              piece: piece,
              positionIndex: displayPositionIndex,
              isSelected: isSelected,
              selectedPositionIndex: isSelected ? displayPositionIndex : state.selectedPositionIndex,
              longPressDuration: Duration(milliseconds: settings.game.longPressDuration),
              onSelect: () {
                if (settings.game.enableHaptics) {
                  HapticFeedback.selectionClick();
                }
                notifier.selectPiece(piece);
              },
              onCycle: () {},
              onCancel: () {
                if (settings.game.enableHaptics) {
                  HapticFeedback.lightImpact();
                }
                notifier.cancelSelection();
              },
              childBuilder: (isDragging) => PieceRenderer(
                piece: piece,
                positionIndex: displayPositionIndex,
                isDragging: isDragging,
                cellSize: widget.pieceCellSize,
                getPieceColor: (pieceId) => settings.ui.getPieceColor(pieceId),
              ),
            ),
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