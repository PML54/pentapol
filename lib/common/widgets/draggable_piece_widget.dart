// Modified: 2026-09-01 08:58 — hitBoxSize optionnel : la zone tactile au repos remplit toute la
//           boîte de la case (opaque) au lieu de la seule pièce, pour que le « I » (1 case de
//           large) s'attrape aussi bien que les autres. Le feedback de drag reste à la taille de
//           la pièce. null = comportement d'avant (multijoueur inchangé).
// lib/common/widgets/draggable_piece_widget.dart
// Historique: 2026-09-01 07:54 — correctif 1 (PLAN_DEPLACEMENT_PIECE §4) : les deux Draggable du
//             tiroir passent en pointerDragAnchorStrategy (details.offset = doigt exact, plus le
//             décalage multi-cases du childDragAnchorStrategy, mécanisme (a) « en pire ») ; feedback
//             recentré par FractionalTranslation(-0.5,-0.5).
// Historique: 2026-08-29 13:43 — déménagé de l’ancien dossier du mode classique vers
//             lib/common/widgets/ (suppression du mode classique §4) : partagé par Pentoscope
//             et le multijoueur.
// Widget pour gérer le drag & drop d'une pièce avec double-tap

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pentapol/common/pentominos.dart';

/// Widget pour gérer proprement le double-tap sans propagation
/// 
/// Gère deux modes :
/// - Pièce non sélectionnée : LongPressDraggable (long press pour drag)
/// - Pièce sélectionnée : Draggable normal (drag immédiat)
/// 
/// Interactions :
/// - Tap simple : sélectionner la pièce
/// - Double-tap : faire pivoter (si déjà sélectionnée)
/// - Long press : commencer le drag (si non sélectionnée)
/// - Drag immédiat : si déjà sélectionnée
class DraggablePieceWidget extends StatefulWidget {
  final Pento piece;
  final int positionIndex;
  final bool isSelected;
  final int selectedPositionIndex;
  final Duration longPressDuration;
  final VoidCallback onSelect;
  final VoidCallback onCycle;
  final VoidCallback onCancel;
  final Widget Function(bool isDragging) childBuilder;

  /// Côté de la boîte tactile carrée au repos. Quand fourni, tout le carré répond au doigt
  /// (utile pour les pièces étroites comme le « I »). null : la zone reste collée à la pièce.
  final double? hitBoxSize;

  const DraggablePieceWidget({
    super.key,
    required this.piece,
    required this.positionIndex,
    required this.isSelected,
    required this.selectedPositionIndex,
    required this.longPressDuration,
    required this.onSelect,
    required this.onCycle,
    required this.onCancel,
    required this.childBuilder,
    this.hitBoxSize,
  });

  @override
  State<DraggablePieceWidget> createState() => _DraggablePieceWidgetState();
}

class _DraggablePieceWidgetState extends State<DraggablePieceWidget> {
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

  /// Zone au repos : opaque sur toute la boîte quand hitBoxSize est fourni, sinon collée à la pièce.
  Widget _restingChild() {
    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      child: widget.hitBoxSize == null
          ? widget.childBuilder(false)
          : Center(child: widget.childBuilder(false)),
    );
    if (widget.hitBoxSize == null) return gesture;
    return SizedBox(
      width: widget.hitBoxSize,
      height: widget.hitBoxSize,
      child: gesture,
    );
  }

  /// Trou laissé pendant le drag : même empreinte que la boîte pour éviter le décalage du tiroir.
  Widget _placeholderWhenDragging() {
    final faded = Opacity(opacity: 0.3, child: widget.childBuilder(false));
    if (widget.hitBoxSize == null) return faded;
    return SizedBox(
      width: widget.hitBoxSize,
      height: widget.hitBoxSize,
      child: Center(child: faded),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si la pièce est déjà sélectionnée, utiliser Draggable normal
    // Sinon, utiliser LongPressDraggable
    if (widget.isSelected) {
      return Draggable<Pento>(
        data: widget.piece,
        // Correctif 1 (§4) : le doigt, pas le coin de la pièce (mécanisme (a) « en pire »
        // au tiroir, où l'enfant est la pièce entière et dragStartPoint vaut plusieurs cases).
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () {
          // Déjà sélectionnée, pas besoin de rappeler onSelect
        },
        onDragEnd: (details) {
          if (!details.wasAccepted) {
            widget.onCancel();
          }
        },
        // Recentre le feedback sous le doigt (−feedbackSize/2 sur chaque axe).
        feedback: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: Material(
            color: Colors.transparent,
            child: widget.childBuilder(true),
          ),
        ),
        childWhenDragging: _placeholderWhenDragging(),
        child: _restingChild(),
      );
    } else {
      return LongPressDraggable<Pento>(
        data: widget.piece,
        delay: widget.longPressDuration,
        // Correctif 1 (§4) : le doigt, pas le coin de la pièce (mécanisme (a) « en pire »).
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () {
          widget.onSelect();
        },
        onDragEnd: (details) {
          if (!details.wasAccepted) {
            widget.onCancel();
          }
        },
        // Recentre le feedback sous le doigt (−feedbackSize/2 sur chaque axe).
        feedback: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: Material(
            color: Colors.transparent,
            child: widget.childBuilder(true),
          ),
        ),
        childWhenDragging: _placeholderWhenDragging(),
        child: _restingChild(),
      );
    }
  }
}

