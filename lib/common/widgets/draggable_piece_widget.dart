// Modified: 2026-09-03 07:10 — fix drag tiroir : callback onGrab + dragAnchorStrategy captent
//           l'offset local du toucher au départ du drag, transmis à l'appelant (le slider) pour
//           ancrer la pièce sur la cellule empoignée. Feedback par défaut inchangé.
// Historique: 2026-09-01 14:09 — hitBoxSize optionnel : la zone tactile au repos remplit toute la
//           boîte de la case (opaque), pour attraper le « I » (1 case) comme les autres. Reposé sur
//           la base PRÉ-chantier après revert du chantier déplacement (voir JOURNAL §ÉTAT).
// lib/common/widgets/draggable_piece_widget.dart
// Historique: 2026-08-29 13:43 — déménagé de l’ancien dossier du mode classique vers
//             lib/common/widgets/ (suppression du mode classique §4) : partagé Pentoscope + multijoueur.
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

  /// Appelé au départ du drag avec l'offset local du toucher (dans la boîte du widget) et la
  /// taille de cette boîte, pour que l'appelant en déduise la cellule empoignée et ancre le drag
  /// dessus. null : pas de suivi de la case empoignée (l'appelant sélectionne via onSelect).
  final void Function(Offset localGrab, Size boxSize)? onGrab;

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
    this.onGrab,
  });

  @override
  State<DraggablePieceWidget> createState() => _DraggablePieceWidgetState();
}

class _DraggablePieceWidgetState extends State<DraggablePieceWidget> {
  Timer? _tapTimer;
  bool _isProcessing = false;

  // Offset local du toucher au départ du drag (capturé par dragAnchorStrategy) et taille de la
  // boîte, transmis à onGrab pour que le slider en déduise la cellule empoignée.
  Offset? _grabLocal;
  Size? _grabBox;

  /// dragAnchorStrategy = simple hook : capture l'offset local du toucher, garde le feedback par
  /// défaut (le doigt reste sur le même point de la pièce).
  Offset _captureGrab(Draggable<Object> d, BuildContext ctx, Offset position) {
    final rb = ctx.findRenderObject();
    if (rb is RenderBox) {
      _grabLocal = rb.globalToLocal(position);
      _grabBox = rb.size;
    }
    return childDragAnchorStrategy(d, ctx, position);
  }

  /// Au départ du drag : ancrer sur la cellule empoignée si l'appelant le gère (onGrab), sinon
  /// sélection simple (comportement d'avant).
  void _handleDragStart() {
    if (widget.onGrab != null && _grabLocal != null && _grabBox != null) {
      widget.onGrab!(_grabLocal!, _grabBox!);
    } else if (!widget.isSelected) {
      widget.onSelect();
    }
  }

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
        dragAnchorStrategy: _captureGrab,
        onDragStarted: _handleDragStart,
        onDragEnd: (details) {
          if (!details.wasAccepted) {
            widget.onCancel();
          }
        },
        feedback: Material(
          color: Colors.transparent,
          child: widget.childBuilder(true),
        ),
        childWhenDragging: _placeholderWhenDragging(),
        child: _restingChild(),
      );
    } else {
      return LongPressDraggable<Pento>(
        data: widget.piece,
        delay: widget.longPressDuration,
        dragAnchorStrategy: _captureGrab,
        onDragStarted: _handleDragStart,
        onDragEnd: (details) {
          if (!details.wasAccepted) {
            widget.onCancel();
          }
        },
        feedback: Material(
          color: Colors.transparent,
          child: widget.childBuilder(true),
        ),
        childWhenDragging: _placeholderWhenDragging(),
        child: _restingChild(),
      );
    }
  }
}

