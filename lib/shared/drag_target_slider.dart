// lib/shared/widgets/drag_target_slider.dart
// Widget générique pour transformer un slider en zone de suppression
// Usage: Drag une pièce placée vers le slider pour la retirer du plateau

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/pentominos.dart';

/// Widget qui enveloppe un slider et permet de retirer des pièces en les draguant dessus
///
/// Usage:
/// ```dart
/// DragTargetSlider(
///   canAccept: state.selectedPlacedPiece != null,
///   onAccept: () => notifier.removePlacedPiece(state.selectedPlacedPiece!),
///   isLandscape: false,
///   width: null,  // null = prend toute la largeur
///   height: 140,
///   child: MyPieceSlider(),
/// )
/// ```
class DragTargetSlider extends StatelessWidget {
  /// Le slider enfant (PentoscopePieceSlider, PieceSlider, etc.)
  final Widget child;

  /// Callback pour vérifier si on peut accepter le drop
  /// Typiquement: state.selectedPlacedPiece != null
  final bool canAccept;

  /// Callback appelé quand une pièce est droppée
  /// Typiquement: notifier.removePlacedPiece(state.selectedPlacedPiece!)
  final VoidCallback onAccept;

  /// Mode paysage ou portrait
  final bool isLandscape;

  /// Dimensions (null = flex/expand)
  final double? width;
  final double? height;

  /// Couleur de fond par défaut
  final Color backgroundColor;

  /// Couleur de fond au survol
  final Color hoverBackgroundColor;

  /// Couleur de bordure au survol
  final Color hoverBorderColor;

  /// Ombre du container
  final List<BoxShadow>? boxShadow;

  /// Bordure radius
  final BorderRadius? borderRadius;

  /// Afficher l'icône poubelle au survol
  final bool showDeleteIcon;

  const DragTargetSlider({
    super.key,
    required this.child,
    required this.canAccept,
    required this.onAccept,
    this.isLandscape = false,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFFF5F5F5), // Colors.grey.shade100
    this.hoverBackgroundColor = const Color(0xFFFFEBEE), // Colors.red.shade50
    this.hoverBorderColor = const Color(0xFFEF5350), // Colors.red.shade400
    this.boxShadow,
    this.borderRadius,
    this.showDeleteIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Pento>(
      onWillAcceptWithDetails: (details) => canAccept,
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        onAccept();
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isHovering ? hoverBackgroundColor : backgroundColor,
            border: isHovering
                ? Border.all(color: hoverBorderColor, width: 3)
                : null,
            borderRadius: borderRadius,
            boxShadow: boxShadow,
          ),
          child: Stack(
            children: [
              // Le slider enfant
              child,

              // Overlay de suppression au survol
              if (isHovering && showDeleteIcon)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _buildDeleteOverlay(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeleteOverlay() {
    return Container(
      color: Colors.red.withOpacity(0.1),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.delete_outline,
              color: Colors.red.shade700,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// VARIANTES PRÉCONFIGURÉES
// =============================================================================

/// Variante portrait (slider horizontal en bas)
class DragTargetSliderPortrait extends DragTargetSlider {
  const DragTargetSliderPortrait({
    super.key,
    required super.child,
    required super.canAccept,
    required super.onAccept,
    super.height = 140,
  }) : super(
    isLandscape: false,
    width: null,
    boxShadow: const [
      BoxShadow(
        color: Color(0x1A000000), // Colors.black.withOpacity(0.1)
        blurRadius: 4,
        offset: Offset(0, -2),
      ),
    ],
  );
}

/// Variante paysage (slider vertical à droite)
class DragTargetSliderLandscape extends DragTargetSlider {
  const DragTargetSliderLandscape({
    super.key,
    required super.child,
    required super.canAccept,
    required super.onAccept,
    super.width = 120,
  }) : super(
    isLandscape: true,
    height: null,
    boxShadow: const [
      BoxShadow(
        color: Color(0x1A000000), // Colors.black.withOpacity(0.1)
        blurRadius: 4,
        offset: Offset(-2, 0),
      ),
    ],
  );
}

// =============================================================================
// EXTENSION HELPER POUR SIMPLIFIER L'USAGE
// =============================================================================

/// Extension pour créer rapidement un DragTargetSlider
///
/// Usage:
/// ```dart
/// MySlider().wrapWithDragTarget(
///   canAccept: state.selectedPlacedPiece != null,
///   onAccept: () => notifier.removePlacedPiece(state.selectedPlacedPiece!),
/// )
/// ```
extension DragTargetSliderExtension on Widget {
  Widget wrapWithDragTarget({
    required bool canAccept,
    required VoidCallback onAccept,
    bool isLandscape = false,
    double? width,
    double? height,
  }) {
    return DragTargetSlider(
      canAccept: canAccept,
      onAccept: onAccept,
      isLandscape: isLandscape,
      width: width,
      height: height,
      child: this,
    );
  }
}