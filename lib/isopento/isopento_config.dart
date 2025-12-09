// lib/isopento/isopento_config.dart
// Modified: 2512092201
// Configuration UI Isopento - tailles icônes, espacements, couleurs
// Accessible depuis isopento_menu_screen.dart et isopento_game_screen.dart

/// Configuration UI centralisée pour le module Isopento
/// Instance immutable avec propriétés personnalisables
class IsopentoConfig {
  // ============================================================================
  // PROPRIÉTÉS INSTANCE (personnalisables)
  // ============================================================================

  /// Taille des 4 icônes isométries : rotations + symétries
  /// Utilisé dans isopento_game_screen.dart → AppBar actions
  /// Default: 56.0 px
  final double isometryIconSize;

  /// Padding autour de chaque icône isométrie
  /// Default: 8.0 px
  final double isometryIconPadding;

  /// Taille de l'icône poubelle (delete) pour drag pièce vers slider
  /// Default: 32.0 px
  final double deleteIconSize;

  /// Taille du cercle contenant l'icône poubelle
  /// Default: 56.0 px
  final double deleteCircleSize;

  /// Taille de la croix rouge (close button) pour quitter sélection
  /// Default: 56.0 px
  final double closeIconSize;

  /// Largeur colonne actions en paysage (rotations + symétries)
  /// Default: 72.0 px
  final double landscapeActionsWidth;

  /// Largeur slider pièces en paysage
  /// Default: 120.0 px
  final double landscapeSliderWidth;

  /// Hauteur slider pièces en portrait
  /// Default: 140.0 px
  final double portraitSliderHeight;

  /// Padding interne slider pièces
  /// Default: 12.0 px
  final double sliderPadding;

  // ============================================================================
  // STATIC CONSTANTS (non-personnalisables)
  // ============================================================================

  /// Couleur bordure hover slider (drag pièce vers delete)
  static const int deleteHoverBorderColor = 0xFFF44336; // Colors.red

  /// Couleur fond semi-transparent hover slider
  static const int deleteHoverBackgroundColor = 0xFFFEEBEE; // Colors.red.shade50

  /// Durée animation container au survol slider
  static const Duration hoverAnimationDuration = Duration(milliseconds: 150);

  /// Taille cellule minimale pour plateau 3×5 en portrait
  static const double minCellSize = 40.0;

  /// Radius coins plateau
  static const double plateauBorderRadius = 16.0;

  // ============================================================================
  // CONSTRUCTEUR
  // ============================================================================

  /// Constructeur const pour configuration immutable
  const IsopentoConfig({
    this.isometryIconSize = 56.0,
    this.isometryIconPadding = 8.0,
    this.deleteIconSize = 32.0,
    this.deleteCircleSize = 56.0,
    this.closeIconSize = 56.0,
    this.landscapeActionsWidth = 72.0,
    this.landscapeSliderWidth = 120.0,
    this.portraitSliderHeight = 140.0,
    this.sliderPadding = 12.0,
  });

  // ============================================================================
  // CONFIGURATIONS PRÉ-DÉFINIES
  // ============================================================================

  /// Configuration par défaut (production)
  static const IsopentoConfig defaultConfig = IsopentoConfig();

  /// Configuration tuning (pour développement/UI tweaks)
  /// À utiliser lors du tuning des tailles
  static const IsopentoConfig debugConfig = IsopentoConfig(
    isometryIconSize: 64.0,  // Plus gros en debug
    isometryIconPadding: 10.0,
    deleteIconSize: 40.0,
    deleteCircleSize: 64.0,
    closeIconSize: 64.0,
    landscapeActionsWidth: 80.0,
    landscapeSliderWidth: 140.0,
    portraitSliderHeight: 160.0,
    sliderPadding: 16.0,
  );

  /// Configuration compacte (pour petits écrans)
  static const IsopentoConfig compactConfig = IsopentoConfig(
    isometryIconSize: 48.0,
    isometryIconPadding: 6.0,
    deleteIconSize: 28.0,
    deleteCircleSize: 48.0,
    closeIconSize: 48.0,
    landscapeActionsWidth: 60.0,
    landscapeSliderWidth: 100.0,
    portraitSliderHeight: 120.0,
    sliderPadding: 8.0,
  );
}

/// Instance globale de configuration (par défaut)
/// Utilisé dans game_screen et menu_screen
const IsopentoConfig isopentoConfig = IsopentoConfig.defaultConfig;