// Modified: 2026-08-30 06:12 — PLAN_BILAN §2 : le dialogue modal de fin de partie est remplacé
//           par un bandeau non modal (_BilanBanner) à la place de la barre de pièces (portrait
//           ET paysage) ; l'écouteur de complétion et la rangée de bilan disparaissent ; état
//           local _bilanFerme piloté en build par state.isComplete.
// lib/pentoscope/screens/pentoscope_game_screen.dart
// Historique: 2026-08-30 06:04 — PLAN_BILAN §3 : retrait de la ligne Score et de son calcul
//             du score (rapport non homogène) et de son calcul, dans le dialogue de fin.
// Historique: 2026-08-29 20:22 — dialogue « Nouvelle partie » (§8 étape 3) : _showSizeChangeDialog
//             devient _showNewGameDialog (StatefulBuilder : taille + difficulté + montrer la
//             solution, bouton « Lancer » → startPuzzle direct). Absorbe l'ancien écran de menu.
//             Bouton reset renommé « Recommencer (même taille) » pour lever l'ambiguïté.
// Historique: 2026-08-29 20:18 — étape 2 : bouton Réglages dans l'AppBar.
//             2026-08-29 14:02 — étape 6 : retrait du bouton « Mode Classique ».
// Historique: 2026-08-29 13:43 — étape 3 : bouton « Solutions compatibles » (navigateur),
//             gaté par solutionsCount != null.
//             2026-08-29 10:05 — 6×10 temps 2 étape 5 : compteur de solutions dans l'AppBar.
// Historique: 2026-08-28 20:30 — suppression démo : retrait de l'import demo_screen.dart et
//             des deux IconButton « Démo automatique ».
//             2026-08-27 19:57 — PentoscopePlacedPiece → PlacedPiece.
// Modified: 2604221500
// Dialogue bilan : déplacements, suppressions
// CHANGEMENTS: (1) dialogue de bilan, (2) rangées déplacements et suppressions ajoutées

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_board.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_piece_slider.dart';
import 'package:pentapol/pentoscope/screens/solutions_browser_screen.dart';
import 'package:pentapol/pentoscope_multiplayer/screens/pentoscope_mp_lobby_screen.dart';
import 'package:pentapol/screens/settings_screen.dart';

/// ⏱️ Formate le temps en secondes (max 999s) - format compact
String _formatTime(int seconds) {
  final clamped = seconds.clamp(0, 999);
  return '${clamped}s';
}

class PentoscopeGameScreen extends ConsumerStatefulWidget {
  const PentoscopeGameScreen({super.key});

  @override
  ConsumerState<PentoscopeGameScreen> createState() => _PentoscopeGameScreenState();
}

class _PentoscopeGameScreenState extends ConsumerState<PentoscopeGameScreen> {
  // 👁️ État du mini-plateau adversaire
  bool _showOpponentOverlay = false;

  // 📍 Position du mini-plateau (draggable)
  Offset? _overlayPosition; // null = position par défaut (coin bas-droit)

  // 🏁 Bandeau de bilan fermé par « Fermer » alors que le puzzle reste complet.
  // Remis à false en build dès que le puzzle n'est plus complet (voir build()).
  bool _bilanFerme = false;

  /// Gère l'affichage des messages et vibrations selon le résultat de transformation
  void _handleTransformationResult(BuildContext context, TransformationResult result) {
    switch (result) {
      case TransformationResult.success:
        // Pas de message pour une transformation réussie sans ajustement
        break;
      case TransformationResult.recentered:
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recentrage'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
        break;
      case TransformationResult.impossible:
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transformation impossible'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);
    final settings = ref.watch(settingsProvider);

    // Bilan non modal : piloté par state.isComplete. _bilanFerme se remet à false dès que le
    // puzzle n'est plus complet (reset, nouvelle partie, retrait d'une pièce), ce qui couvre
    // tous les démarrages sans avoir à le faire dans chaque handler.
    if (!state.isComplete && _bilanFerme) _bilanFerme = false;

    if (state.puzzle == null) {
      return const Scaffold(body: Center(child: Text('Aucun puzzle')));
    }

    // Détection du mode transformation
    final isPlacedPieceSelected = state.selectedPlacedPiece != null;
    final isSliderPieceSelected = state.selectedPiece != null;

    // Orientation
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isLandscape
          ? null
          : PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: AppBar(
          toolbarHeight: 56.0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          // 🔑 En mode transformation: pas de leading, les icônes prennent toute la place
          leading: (isPlacedPieceSelected || isSliderPieceSelected)
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ⏱️ Chronomètre
                    Text(
                      _formatTime(state.elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
          leadingWidth: (isPlacedPieceSelected || isSliderPieceSelected) ? 0 : 60,
          // 🔑 En mode transformation: icônes isométrie pleine largeur
          title: (isPlacedPieceSelected || isSliderPieceSelected)
              ? _buildFullWidthIsometryBar(state, notifier)
              : state.isComplete
              ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicateurs de performance
                    Icon(Icons.rotate_right, size: 14, color: Colors.blue.shade600),
                    Text('${state.isometryCount}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(width: 6),
                    Icon(Icons.open_with, size: 14, color: Colors.purple.shade600),
                    Text('${state.translationCount}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(width: 6),
                    Icon(Icons.delete_outline, size: 14, color: Colors.red.shade600),
                    Text('${state.deleteCount}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              );
            },
          )
              : (settings.game.showSolutionCounter && state.solutionsCount != null)
                  // 🔢 Compteur de solutions (tailles adossées à une table, ex. 6×10).
                  // Rouge à 0 : cohérent avec le bouton d'indice qui vire au rouge.
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_view_rounded,
                            size: 14, color: Colors.indigo.shade400),
                        const SizedBox(width: 4),
                        Text(
                          '${state.solutionsCount}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: state.hasPossibleSolution
                                ? Colors.black87
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    )
                  : null,
          centerTitle: true,
          // 🔑 En mode transformation: pas d'actions, tout est dans le title
          actions: (isPlacedPieceSelected || isSliderPieceSelected)
              ? null
              : [
            // 🆕 Nouvelle partie (taille + difficulté + montrer la solution)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.blue,
              onPressed: () => _showNewGameDialog(context, ref),
              tooltip: 'Nouvelle partie',
            ),
            // 👥 Bouton multijoueur
            IconButton(
              icon: const Icon(Icons.people_outline),
              color: Colors.purple,
              onPressed: () => _navigateToMultiplayer(context),
              tooltip: 'Mode multijoueur',
            ),
            // 👤 Solo — réinitialiser
            IconButton(
              icon: Icon(
                Icons.person,
                color: state.isComplete ? Colors.green : Colors.indigo,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                notifier.reset();
              },
              tooltip: 'Recommencer (même taille)',
            ),
            // 💡 Bouton Hint (lampe) — amber si solution possible, rouge sinon
            if (!state.isComplete && state.availablePieces.isNotEmpty)
              IconButton(
                icon: Icon(
                  state.hasPossibleSolution
                      ? Icons.lightbulb
                      : Icons.lightbulb,
                  color: state.hasPossibleSolution ? Colors.amber : Colors.red,
                ),
                onPressed: () {
                  if (state.hasPossibleSolution) {
                    HapticFeedback.mediumImpact();
                    notifier.applyHint();
                  }
                },
                tooltip: state.hasPossibleSolution ? 'Indice' : 'Aucune solution possible',
              ),
            // 🔎 Navigateur de solutions (tailles adossées à une table)
            if (state.solutionsCount != null)
              IconButton(
                icon: const Icon(Icons.view_carousel),
                color: Colors.indigo,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final sols = notifier.compatibleSolutions();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SolutionsBrowserScreen.forSolutions(
                        solutions: sols,
                        title: '${sols.length} solution(s) compatible(s)',
                      ),
                    ),
                  );
                },
                tooltip: 'Solutions compatibles',
              ),
            // ⚙️ Réglages (seul accès aux Réglages, depuis l'AppBar — §8.1)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              tooltip: 'Réglages',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;

              if (isLandscape) {
                return _buildLandscapeLayout(
                  context,
                  ref,
                  state,
                  notifier,
                  settings,
                  isSliderPieceSelected,
                  isPlacedPieceSelected,
                );
              } else {
                return _buildPortraitLayout(
                  context,
                  ref,
                  state,
                  notifier,
                  isSliderPieceSelected,
                  isPlacedPieceSelected,
                );
              }
            },
          ),
          
          // 👁️ Mini-plateau adversaire (overlay)
          if (_showOpponentOverlay)
            _buildOpponentOverlay(context, state, settings),
        ],
      ),
    );
  }

  // ============================================================================
  // 👁️ MINI-PLATEAU ADVERSAIRE (OVERLAY)
  // ============================================================================

  Widget _buildOpponentOverlay(
      BuildContext context,
      PentoscopeState state,
      dynamic settings,
      ) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    // Taille du mini-plateau (35% de l'écran)
    final overlaySize = isLandscape 
        ? screenSize.height * 0.35 
        : screenSize.width * 0.35;
    
    // Position par défaut : coin bas-droit avec marge
    final defaultX = screenSize.width - overlaySize - 12;
    final defaultY = isLandscape 
        ? screenSize.height - overlaySize - 12 
        : screenSize.height - overlaySize - 170; // Au-dessus du slider en portrait
    
    // Utiliser la position custom ou la position par défaut
    final currentX = _overlayPosition?.dx ?? defaultX;
    final currentY = _overlayPosition?.dy ?? defaultY;

    return Positioned(
      left: currentX,
      top: currentY,
      child: GestureDetector(
        // 🖐️ Drag pour déplacer
        onPanUpdate: (details) {
          setState(() {
            final newX = (currentX + details.delta.dx)
                .clamp(0.0, screenSize.width - overlaySize);
            final newY = (currentY + details.delta.dy)
                .clamp(0.0, screenSize.height - overlaySize - 60); // Marge pour ne pas sortir
            _overlayPosition = Offset(newX, newY);
          });
        },
        // 🔄 Double-tap pour reset la position
        onDoubleTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _overlayPosition = null; // Reset à la position par défaut
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: overlaySize,
          height: overlaySize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // 🎮 Mini-plateau (simulation adversaire)
                _buildMiniBoard(state, settings, overlaySize),
                
                // 📊 Bandeau info adversaire (aussi zone de drag)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade400],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 🖐️ Icône drag
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.drag_indicator, color: Colors.white.withOpacity(0.7), size: 12),
                            const SizedBox(width: 4),
                            const Text(
                              '👤 Adversaire',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_simulateOpponentProgress(state)}/${state.puzzle?.size.numPieces ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // ❌ Bouton fermer
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showOpponentOverlay = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Simule la progression de l'adversaire (pour démo)
  int _simulateOpponentProgress(PentoscopeState state) {
    // Simulation miroir : même progression que nous
    return state.placedPieces.length;
  }

  /// Construit le mini-plateau (vue simplifiée)
  Widget _buildMiniBoard(PentoscopeState state, dynamic settings, double size) {
    final puzzle = state.puzzle;
    if (puzzle == null) return const SizedBox();

    final boardWidth = puzzle.size.width;
    final boardHeight = puzzle.size.height;
    
    // Calculer la taille des cellules pour le mini-plateau
    final availableSize = size - 24; // Marge pour le bandeau
    final maxDimension = boardWidth > boardHeight ? boardWidth : boardHeight;
    final cellSize = availableSize / maxDimension;

    return Padding(
      padding: const EdgeInsets.only(top: 22), // Espace pour le bandeau
      child: Center(
        child: SizedBox(
          width: cellSize * boardWidth,
          height: cellSize * boardHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: boardWidth,
              childAspectRatio: 1.0,
            ),
            itemCount: boardWidth * boardHeight,
            itemBuilder: (context, index) {
              final x = index % boardWidth;
              final y = index ~/ boardWidth;
              
              // Simuler le plateau adversaire (quelques pièces placées)
              final opponentPieces = _getSimulatedOpponentPieces(state);
              final pieceId = _getPieceAtPosition(opponentPieces, x, y);
              
              return Container(
                decoration: BoxDecoration(
                  color: pieceId != null 
                      ? settings.ui.getPieceColor(pieceId).withOpacity(0.8)
                      : Colors.grey.shade200,
                  border: Border.all(color: Colors.grey.shade400, width: 0.5),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Simule les pièces de l'adversaire (pour démo)
  /// En mode miroir : affiche les mêmes pièces que nous
  List<PlacedPiece> _getSimulatedOpponentPieces(PentoscopeState state) {
    // Simulation miroir : mêmes pièces que nous
    return state.placedPieces.toList();
  }

  /// Récupère l'ID de la pièce à une position donnée
  int? _getPieceAtPosition(List<PlacedPiece> pieces, int x, int y) {
    for (final placed in pieces) {
      for (final cell in placed.absoluteCells) {
        if (cell.x == x && cell.y == y) {
          return placed.piece.id;
        }
      }
    }
    return null;
  }

  /// 🔑 Barre d'isométries pleine largeur avec icônes grandes et réparties uniformément
  Widget _buildFullWidthIsometryBar(
      PentoscopeState state,
      PentoscopeNotifier notifier,
      ) {
    // Hauteur AppBar = 56, on prend ~75% pour les icônes
    const double iconSize = 42.0;
    
    final hasDeleteButton = state.selectedPlacedPiece != null;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Rotation anti-horaire
        IconButton(
          icon: Icon(GameIcons.isometryRotationTW.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            final result = notifier.applyIsometryRotationTW();
            _handleTransformationResult(context, result);
          },
          tooltip: GameIcons.isometryRotationTW.tooltip,
          color: GameIcons.isometryRotationTW.color,
        ),
        // Rotation horaire
        IconButton(
          icon: Icon(GameIcons.isometryRotationCW.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            final result = notifier.applyIsometryRotationCW();
            _handleTransformationResult(context, result);
          },
          tooltip: GameIcons.isometryRotationCW.tooltip,
          color: GameIcons.isometryRotationCW.color,
        ),
        // Symétrie horizontale
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryH.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            final result = notifier.applyIsometrySymmetryH();
            _handleTransformationResult(context, result);
          },
          tooltip: GameIcons.isometrySymmetryH.tooltip,
          color: GameIcons.isometrySymmetryH.color,
        ),
        // Symétrie verticale
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryV.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            final result = notifier.applyIsometrySymmetryV();
            _handleTransformationResult(context, result);
          },
          tooltip: GameIcons.isometrySymmetryV.tooltip,
          color: GameIcons.isometrySymmetryV.color,
        ),
        // Supprimer (si pièce placée)
        if (hasDeleteButton)
          IconButton(
            icon: Icon(GameIcons.removePiece.icon, size: iconSize),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              HapticFeedback.selectionClick();
              notifier.removePlacedPiece(state.selectedPlacedPiece!);
            },
            tooltip: GameIcons.removePiece.tooltip,
            color: GameIcons.removePiece.color,
          ),
      ],
    );
  }

  /// 🔑 Barre d'isométries pleine hauteur (mode paysage) avec icônes grandes et réparties
  Widget _buildFullHeightIsometryBar(
      PentoscopeState state,
      PentoscopeNotifier notifier,
      double columnWidth,
      ) {
    // Icônes ~80% de la largeur de la colonne
    final iconSize = (columnWidth * 0.75).clamp(28.0, 50.0);
    final hasDeleteButton = state.selectedPlacedPiece != null;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Rotation anti-horaire
        IconButton(
          icon: Icon(GameIcons.isometryRotationTW.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometryRotationTW();
          },
          tooltip: GameIcons.isometryRotationTW.tooltip,
          color: GameIcons.isometryRotationTW.color,
        ),
        // Rotation horaire
        IconButton(
          icon: Icon(GameIcons.isometryRotationCW.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometryRotationCW();
          },
          tooltip: GameIcons.isometryRotationCW.tooltip,
          color: GameIcons.isometryRotationCW.color,
        ),
        // Symétrie horizontale
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryH.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometrySymmetryH();
          },
          tooltip: GameIcons.isometrySymmetryH.tooltip,
          color: GameIcons.isometrySymmetryH.color,
        ),
        // Symétrie verticale
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryV.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometrySymmetryV();
          },
          tooltip: GameIcons.isometrySymmetryV.tooltip,
          color: GameIcons.isometrySymmetryV.color,
        ),
        // Supprimer (si pièce placée)
        if (hasDeleteButton)
          IconButton(
            icon: Icon(GameIcons.removePiece.icon, size: iconSize),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              HapticFeedback.selectionClick();
              notifier.removePlacedPiece(state.selectedPlacedPiece!);
            },
            tooltip: GameIcons.removePiece.tooltip,
            color: GameIcons.removePiece.color,
          ),
      ],
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Construit le slider avec DragTarget (drag pièce vers slider = suppression)
  /// 🏁 Bandeau de bilan non modal, à la place de la barre de pièces (vide à la complétion).
  Widget _buildBilanBanner(
      bool isLandscape, PentoscopeState state, PentoscopeNotifier notifier) {
    return _BilanBanner(
      isLandscape: isLandscape,
      elapsedSeconds: state.elapsedSeconds,
      isometryCount: state.isometryCount,
      translationCount: state.translationCount,
      deleteCount: state.deleteCount,
      hintCount: state.hintCount,
      onClose: () => setState(() => _bilanFerme = true),
      onNewGame: () {
        HapticFeedback.mediumImpact();
        notifier.reset();
      },
    );
  }

  Widget _buildSliderWithDragTarget({
    required WidgetRef ref,
    required bool isLandscape,
    required Widget sliderChild,
    required BoxDecoration decoration,
    double? width,
    double? height,
  }) {
    final state = ref.watch(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);

    return DragTarget<Pento>(
      onWillAcceptWithDetails: (details) {
        // Accepter seulement si c'est une pièce placée
        return state.selectedPlacedPiece != null;
      },
      onAcceptWithDetails: (details) {
        // Retirer la pièce du plateau
        if (state.selectedPlacedPiece != null) {
          HapticFeedback.mediumImpact();
          notifier.removePlacedPiece(state.selectedPlacedPiece!);
        }
      },
      builder: (context, candidateData, rejectedData) {
        // Highlight visuel au survol
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: height,
          decoration: decoration.copyWith(
            border: isHovering
                ? Border.all(color: Colors.red.shade400, width: 3)
                : null,
            color: isHovering ? Colors.red.shade50 : decoration.color,
          ),
          child: Stack(
            children: [
              sliderChild,
              // Icône poubelle au survol
              if (isHovering)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.red.withOpacity(0.1),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade700,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // LAYOUTS
  // ============================================================================

  /// Layout portrait : plateau en haut, actions + slider en bas
  Widget _buildPortraitLayout(
      BuildContext context,
      WidgetRef ref,
      PentoscopeState state,
      PentoscopeNotifier notifier,
      bool isSliderPieceSelected,
      bool isPlacedPieceSelected,
      ) {
    return Column(
      children: [
        // Plateau de jeu
        const Expanded(flex: 3, child: PentoscopeBoard(isLandscape: false)),

        // Slider de pièces horizontal
        _buildSliderWithDragTarget(
          ref: ref,
          isLandscape: false,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          sliderChild: (state.isComplete && !_bilanFerme)
              ? _buildBilanBanner(false, state, notifier)
              : const PentoscopePieceSlider(isLandscape: false),
        ),
      ],
    );
  }

  /// Layout paysage : plateau à gauche, actions + slider vertical à droite
  Widget _buildLandscapeLayout(
      BuildContext context,
      WidgetRef ref,
      PentoscopeState state,
      PentoscopeNotifier notifier,
      dynamic settings,
      bool isSliderPieceSelected,
      bool isPlacedPieceSelected,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapter les tailles selon l'espace disponible (iPad vs iPhone)
        final screenHeight = constraints.maxHeight;
        final actionColumnWidth = (screenHeight * 0.08).clamp(44.0, 70.0);
        final sliderWidth = (screenHeight * 0.18).clamp(100.0, 180.0);
        final iconSize = (screenHeight * 0.045).clamp(20.0, 36.0);

        return Row(
          children: [
            // Plateau de jeu
            const Expanded(child: PentoscopeBoard(isLandscape: true)),

            // Colonne de droite : actions + slider
            Row(
              children: [
                // 🎯 Colonne d'actions (contextuelles)
                Container(
                  width: actionColumnWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(-1, 0),
                      ),
                    ],
                  ),
                  child: (isPlacedPieceSelected || isSliderPieceSelected)
                      // 🔑 Mode transformation: icônes pleine hauteur, réparties uniformément
                      ? _buildFullHeightIsometryBar(state, notifier, actionColumnWidth)
                      // Mode normal: actions centrées
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ⏱️ Chronomètre
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          _formatTime(state.elapsedSeconds),
                          style: TextStyle(
                            fontSize: (iconSize * 0.5).clamp(10.0, 16.0),
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      // Actions générales (reset, close, hint)
                      IconButton(
                        icon: Icon(Icons.games, size: iconSize),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          notifier.reset();
                        },
                        tooltip: 'Recommencer',
                      ),
                      // 💡 Bouton Hint (lampe)
                      if (!state.isComplete &&
                          state.hasPossibleSolution &&
                          state.availablePieces.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.lightbulb_outline, size: iconSize),
                          color: Colors.amber,
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            notifier.applyHint();
                          },
                          tooltip: 'Indice',
                        ),
                      // 🔎 Navigateur de solutions (tailles adossées à une table)
                      if (state.solutionsCount != null)
                        IconButton(
                          icon: Icon(Icons.view_carousel, size: iconSize),
                          color: Colors.indigo,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            final sols = notifier.compatibleSolutions();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SolutionsBrowserScreen.forSolutions(
                                  solutions: sols,
                                  title: '${sols.length} solution(s) compatible(s)',
                                ),
                              ),
                            );
                          },
                          tooltip: 'Solutions compatibles',
                        ),
                      // ⚙️ Réglages
                      IconButton(
                        icon: Icon(Icons.settings, size: iconSize),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                        tooltip: 'Réglages',
                      ),
                    ],
                  ),
                ),

                // Slider de pièces vertical
                _buildSliderWithDragTarget(
                  ref: ref,
                  isLandscape: true,
                  width: sliderWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(-2, 0),
                      ),
                    ],
                  ),
                  sliderChild: (state.isComplete && !_bilanFerme)
                      ? _buildBilanBanner(true, state, notifier)
                      : const PentoscopePieceSlider(isLandscape: true),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// 📏 Affiche le dialogue de changement de taille de plateau
  /// Dialogue « Nouvelle partie » : taille + difficulté + montrer la solution,
  /// avec un bouton « Lancer » qui appelle startPuzzle directement (§8.2).
  /// Absorbe l'ancien écran de menu de démarrage ; état local via StatefulBuilder.
  void _showNewGameDialog(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(pentoscopeProvider.notifier);
    var selectedSize =
        ref.read(pentoscopeProvider).puzzle?.size ?? PentoscopeSize.size5x5;
    var difficulty = PentoscopeDifficulty.random;
    var showSolution = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouvelle partie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Taille du plateau',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...PentoscopeSize.values.map(
                  (size) => RadioListTile<PentoscopeSize>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${size.label} (${size.width}×${size.height})'),
                    value: size,
                    groupValue: selectedSize,
                    onChanged: (value) => setState(() => selectedSize = value!),
                  ),
                ),
                const Divider(),
                const Text('Difficulté',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<PentoscopeDifficulty>(
                  segments: const [
                    ButtonSegment(
                        value: PentoscopeDifficulty.easy, label: Text('Facile')),
                    ButtonSegment(
                        value: PentoscopeDifficulty.random,
                        label: Text('Aléatoire')),
                    ButtonSegment(
                        value: PentoscopeDifficulty.hard,
                        label: Text('Difficile')),
                  ],
                  selected: {difficulty},
                  onSelectionChanged: (s) =>
                      setState(() => difficulty = s.first),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Montrer la solution'),
                  value: showSolution,
                  onChanged: (value) => setState(() => showSolution = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                notifier.startPuzzle(
                  selectedSize,
                  difficulty: difficulty,
                  showSolution: showSolution,
                );
              },
              child: const Text('Lancer'),
            ),
          ],
        ),
      ),
    );
  }

  /// 👥 Navigation vers le mode multijoueur
  void _navigateToMultiplayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PentoscopeMPLobbyScreen(),
      ),
    );
  }
}

/// 🏁 Bandeau de bilan non modal, affiché à la place de la barre de pièces (vide à la
/// complétion). Une ligne de puces `icône + valeur` sans libellés, plus « Fermer » et
/// « Nouvelle partie ». Se dispose horizontalement en portrait, verticalement en paysage
/// (la barre y est une colonne étroite).
class _BilanBanner extends StatelessWidget {
  final bool isLandscape;
  final int elapsedSeconds;
  final int isometryCount;
  final int translationCount;
  final int deleteCount;
  final int hintCount;
  final VoidCallback onClose;
  final VoidCallback onNewGame;

  const _BilanBanner({
    required this.isLandscape,
    required this.elapsedSeconds,
    required this.isometryCount,
    required this.translationCount,
    required this.deleteCount,
    required this.hintCount,
    required this.onClose,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    final mm = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (elapsedSeconds % 60).toString().padLeft(2, '0');

    final chips = <Widget>[
      _BilanChip(icon: Icons.timer_outlined, value: '$mm:$ss'),
      _BilanChip(icon: Icons.rotate_right, value: '$isometryCount'),
      _BilanChip(icon: Icons.open_with, value: '$translationCount'),
      if (deleteCount > 0)
        _BilanChip(
            icon: Icons.delete_outline, value: '$deleteCount', color: Colors.orange),
      if (hintCount > 0)
        _BilanChip(icon: Icons.lightbulb, value: '$hintCount', color: Colors.orange),
    ];

    final closeButton = TextButton(
      onPressed: onClose,
      child: const Text('Fermer'),
    );
    final newGameButton = FilledButton.icon(
      onPressed: onNewGame,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Nouvelle partie'),
    );
    const trophy = Icon(Icons.emoji_events, color: Colors.amber, size: 28);

    if (isLandscape) {
      // Colonne étroite : tout empilé, défilable si l'espace manque.
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              trophy,
              const SizedBox(height: 12),
              for (final chip in chips)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: chip,
                ),
              const SizedBox(height: 12),
              closeButton,
              const SizedBox(height: 4),
              newGameButton,
            ],
          ),
        ),
      );
    }

    // Portrait : une ligne — trophée, puces, puis les deux boutons.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          trophy,
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: chips,
            ),
          ),
          const SizedBox(width: 8),
          closeButton,
          const SizedBox(width: 8),
          newGameButton,
        ],
      ),
    );
  }
}

/// Puce `icône + valeur` du bandeau de bilan, sans libellé.
class _BilanChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;

  const _BilanChip({required this.icon, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 16),
        ),
      ],
    );
  }
}