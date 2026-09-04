// Modified: 2026-09-04 06:56 — défi hebdo Phase 2 : en mode classé (state.isRanked, §4.8) l'appui
//           sur l'ampoule est neutralisé (message ; couleur conservée, retrait via sélection+poubelle).
// Historique: 2026-09-04 06:45 — bilan en carte flottante non-modale (centrée sur le plateau résolu,
//           fermable, un tap sur le plateau la rouvre) au lieu du bandeau bas ; chrono et compteur
//           de solutions masqués à la complétion (l'info de fin est regroupée dans la carte). Paul.
// lib/pentoscope/screens/pentoscope_game_screen.dart
// Historique: 2026-09-04 06:13 — médaille §4.6 : badge « Vision parfaite » dans le bandeau quand
//           acuité 100 % sur une partie sans aide (perfectVision && hintCount==0).
// Historique: 2026-09-04 05:20 — records perso A2 (CDC §4.5) : le bandeau de bilan affiche les trois
//           maillots — acuité %, coups (brut), temps — via computeCompletionMetrics ; détail
//           (isométries, minimums) en tooltip. Remplace les compteurs bruts iso/translation/delete.
// Historique: 2026-09-02 20:37 — progression solo : à la complétion d'un puzzle de progression du
//           niveau courant → advanceLevel (via ref.listen) ; 1er puzzle réussi → dialogue de saisie
//           du nom (setUserName) ; bilan avec bouton « Niveau suivant » (remplace « Nouvelle partie »).
// Historique: 2026-09-02 19:20 — icônes d'isométrie du PAYSAGE agrandies à isometryIconSize (comme le
//           portrait) ; la colonne d'actions paysage est élargie pour ne pas rogner.
// Historique: 2026-09-02 19:15 — suppression aussi du message « Transformation impossible » : plus
//           aucun SnackBar dans _handleTransformationResult (recentered + impossible), seuls les
//           retours haptiques restent (retour de Paul).
// Historique: 2026-09-02 17:29 — suppression du message « Recentrage » (SnackBar) lors d'une
//           rotation/miroir qui recale la pièce : recentrage silencieux, haptique conservée.
// Historique: 2026-09-02 11:28 — retrait de l'icône grid_view_rounded devant le compteur de
//           solutions (_buildSolutionCounter) — décorative, sans fonction (retour de Paul).
// Historique: 2026-09-02 11:03 — icônes de la barre d'isométrie agrandies en portrait via la
//           fonction partagée isometryIconSize (game_icons_config) — retour de Paul « trop petites
//           sur iPhone ». Paysage inchangé (rail compact, _uiIconSize).
// Historique: 2026-09-02 09:28 — #3 cul-de-sac actionnable : la pose reste autorisée même en rouge ;
//           l'ampoule rouge devient un « retour en arrière » (un appui = removePlacedPiece de la
//           dernière pièce, répétable). Ampoule inchangée (jaune = indice, rouge = retour).
// Historique: 2026-09-02 04:31 — retrait de la puce diag « c0..c4 » (_buildMastercaseChip /
//           _mastercaseLabel) et de son insertion dans la barre d'isométrie : diagnostic terminé.
// Historique: 2026-09-01 16:10 — DIAGNOSTIC (kDragDiag) : puce « c0..c4 » dans la barre d'isométrie
//           affichant le label INVARIANT de la mastercase active (index de la cellule saisie dans
//           l'orientation, stable par isométrie) — pour voir si la prise reste fixe.
// Historique: 2026-08-31 16:39 — étape B : avec CorpusSolutionSource, solutionsCount non-nul sur
//             toutes les tailles → compteur décroissant partout ; bouton « solutions » regaté au 6×10.
// Historique: 2026-08-31 18:00 — tirage au dialogue (§Affichage) : masque tiré, « n solutions »,
//             bouton « autre tirage » (hors 6×10), masque transmis à startPuzzle.
// Historique: 2026-08-31 17:00 — suppression de la difficulté : retrait du SegmentedButton du dialogue.
// Historique: 2026-08-31 16:00 — regroupement des sept valeurs de réglage visuel en un bloc de
//             constantes nommées en tête de fichier (dont kPieceToBoardCellRatio, rapatrié du board).
// Historique: 2026-08-31 15:00 — réglage à l'œil : _kSliderPad 32 → 20 ; k 0.45 → 0.35 (board).
// Historique: 2026-08-31 14:20 — bug iOS : body enveloppé dans un SafeArea.
// Historique: 2026-08-31 11:00 — PLAN_ERGONOMIE §9 (décisions 65-68) : une seule barre d'actions
//             pour les deux orientations — _buildBarItems rendue en Row (portrait) / Column (paysage) ;
//             retrait de actions:/leading ; chrono central ; trois compteurs sortis ; supersède §4d.
// Historique: 2026-08-31 09:30 — §7 (décision 61) : ordre des zones en paysage aligné sur le portrait.
// Historique: 2026-08-30 15:10 — §4d (décision 59) : icônes de l'AppBar via iconTheme (superseédé par §9).
// Historique: 2026-08-30 13:45 — PLAN_ERGONOMIE §6 étape 3 : helper _uiIconSize/_uiAppBarHeight,
//             remplace les quatre constantes (56, 42, clamp 28-50, clamp 20-36).
// Historique: 2026-08-30 13:35 — PLAN_ERGONOMIE §6 étape 2 : barre ancrée sur le plateau (_barMetrics).
// Historique: 2026-08-30 06:12 — PLAN_BILAN §2 : dialogue modal de fin de partie → bandeau non modal.
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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/completion_metrics.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_board.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_piece_slider.dart';
import 'package:pentapol/pentoscope/screens/solutions_browser_screen.dart';
import 'package:pentapol/pentoscope_multiplayer/screens/pentoscope_mp_lobby_screen.dart';
import 'package:pentapol/screens/settings_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════════════════
// RÉGLAGE VISUEL — les sept valeurs « à régler à l'œil » de l'ergonomie hors plateau,
// rassemblées ici (PLAN_ERGONOMIE §3/§4d). **Regroupement pur : comportement inchangé.**
// Seul `kPieceToBoardCellRatio` est public : `pentoscope_board.dart` l'importe pour le
// feedback de drag. Les autres sont privés au fichier.
// ═══════════════════════════════════════════════════════════════════════════════════════════

/// Rapport pièce/plateau : `pieceCellSize = boardCellSize × k`. Gouverne la taille des pièces
/// de la barre **et** du feedback de drag ; l'épaisseur de la barre en dérive.
const double kPieceToBoardCellRatio = 0.22;

/// Icônes (AppBar + colonne d'actions) : `shortestSide × facteur`, borné.
const double _kIconSizeFactor = 0.075;
const double _kIconSizeMin = 30.0;
const double _kIconSizeMax = 64.0;

/// Hauteur de l'AppBar : `shortestSide × facteur`, borné.
const double _kAppBarHeightFactor = 0.14;
const double _kAppBarHeightMin = 50.0;
const double _kAppBarHeightMax = 100.0;

/// Petits textes/pictos du titre (compteur) et base du chrono : `_uiIconSize × facteur`, borné.
const double _kLabelSizeFactor = 0.35;
const double _kLabelSizeMin = 13.0;
const double _kLabelSizeMax = 40.0;

/// Chrono de la barre : `_uiLabelSize × ce facteur` (plus gros que les autres labels).
const double _kChronoFactor = 1.4;

/// Marge de la barre de pièces autour de la boîte (épaisseur de barre = `5 × cell + marge`).
const double _kSliderPad = 20.0;

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
        // Recentrage silencieux : plus de message (retour de Paul). Retour haptique conservé.
        HapticFeedback.mediumImpact();
        break;
      case TransformationResult.impossible:
        // Silencieux : plus de message (retour de Paul). Retour haptique fort conservé.
        HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Appelé une fois quand le puzzle vient d'être complété (transition via ref.listen).
  /// Progression : avance le niveau si c'était le puzzle du niveau courant. 1ᵉʳ succès : demande
  /// le nom du joueur s'il n'est pas encore saisi.
  void _onPuzzleCompleted(BuildContext context, PentoscopeState st) {
    final settings = ref.read(settingsProvider);
    if (st.isProgression &&
        st.puzzle != null &&
        st.puzzle!.size == sizeForLevel(settings.currentLevel)) {
      ref.read(settingsProvider.notifier).advanceLevel();
    }
    if (settings.userName == null || settings.userName!.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _promptUserName(context);
      });
    }
  }

  /// Dialogue de saisie du nom au 1ᵉʳ puzzle réussi.
  Future<void> _promptUserName(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Bravo ! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Premier puzzle réussi. Comment t\'appelles-tu ?'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ton nom',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) {
      await ref.read(settingsProvider.notifier).setUserName(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);
    final settings = ref.watch(settingsProvider);

    // Progression / nom : réagir à la transition « puzzle complété ».
    ref.listen<PentoscopeState>(pentoscopeProvider, (prev, next) {
      final justCompleted = !(prev?.isComplete ?? false) && next.isComplete;
      if (justCompleted) _onPuzzleCompleted(context, next);
    });

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
        preferredSize: Size.fromHeight(_uiAppBarHeight(context)),
        child: AppBar(
          toolbarHeight: _uiAppBarHeight(context),
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          centerTitle: false,
          // §9 : une seule barre d'actions, répartie. `actions:` tasserait les boutons à droite
          // et ne couvre pas le paysage — la barre vit dans le `title`, via _buildBarItems, qui
          // sert aussi le paysage. Mode transformation : la barre d'isométrie prend la place.
          title: (isPlacedPieceSelected || isSliderPieceSelected)
              ? _buildFullWidthIsometryBar(state, notifier)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _buildBarItems(context, state, notifier),
                ),
        ),
      ),
      // §iOS : sans SafeArea le corps passe sous l'îlot dynamique (paysage, appBar null) et sous
      // l'indicateur d'accueil (portrait). SafeArea par défaut couvre TOUS les bords — donc les
      // deux sens de rotation, sans padding directionnel en dur. Le LayoutBuilder interne voit
      // alors les contraintes réduites, et le plateau se recalcule sur la place restante.
      body: SafeArea(
        child: Stack(
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

          // 🏁 Bilan fermé : un tap sur le plateau résolu **rouvre** la carte (choix de Paul).
          // Capteur plein cadre actif uniquement dans cet état (rien d'autre à faire sur le
          // plateau une fois résolu). N'affecte pas la barre du haut (hors de ce Stack).
          if (state.isComplete && _bilanFerme)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _bilanFerme = false),
              ),
            ),

          // 🏁 Bilan de fin — carte flottante non-modale, posée au centre par-dessus le plateau
          // résolu (visible derrière). Fermable ; ne bloque pas (les zones hors carte laissent
          // passer les taps). Regroupe tout le bilan (les compteurs éparpillés sont retirés).
          if (state.isComplete && !_bilanFerme)
            _buildBilanCard(context, state, notifier),
        ],
      ),
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
    // Icônes de la barre de transformation : taille dédiée partagée (solo + duel), plus grosse
    // que la barre d'état (cibles d'action ; retour de Paul « trop petites sur iPhone »).
    final double iconSize = isometryIconSize(context);

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
    // Icônes de la barre de transformation (paysage) : même taille dédiée qu'en portrait
    // (isometryIconSize), sinon elles « rétrécissent » en tournant en paysage (retour de Paul).
    final iconSize = isometryIconSize(context);
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

  /// 🏁 Bilan de fin — carte flottante non-modale, centrée par-dessus le plateau résolu.
  Widget _buildBilanCard(
      BuildContext context, PentoscopeState state, PentoscopeNotifier notifier) {
    // « Niveau suivant » proposé si le puzzle terminé est un puzzle de progression qui n'est pas
    // déjà le niveau maximal. La complétion a déjà avancé currentLevel (via _onPuzzleCompleted).
    final canNext = state.isProgression &&
        state.puzzle != null &&
        state.puzzle!.size != sizeForLevel(kMaxLevel);
    return _BilanCard(
      metrics: notifier.computeCompletionMetrics(), // trois maillots (CDC §4.5)
      hintCount: state.hintCount,
      onClose: () => setState(() => _bilanFerme = true),
      onNewGame: () {
        HapticFeedback.mediumImpact();
        notifier.reset();
      },
      onNextLevel: canNext
          ? () {
              HapticFeedback.mediumImpact();
              final level = ref.read(settingsProvider).currentLevel;
              notifier.startPuzzle(sizeForLevel(level), isProgression: true);
            }
          : null,
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

  /// Échelle de l'interface hors plateau, ancrée sur la plus petite dimension de l'écran
  /// (PLAN_ERGONOMIE §4d). Un seul point de réglage pour les icônes et la hauteur d'AppBar,
  /// au lieu des quatre constantes improvisées (56, 42, clamp 28-50, clamp 20-36). Clamps
  /// calés pour ≈ conserver l'iPhone et grandir sur tablette ; **à régler à l'œil**.
  double _uiIconSize(BuildContext context) =>
      (MediaQuery.of(context).size.shortestSide * _kIconSizeFactor)
          .clamp(_kIconSizeMin, _kIconSizeMax);

  double _uiAppBarHeight(BuildContext context) =>
      (MediaQuery.of(context).size.shortestSide * _kAppBarHeightFactor)
          .clamp(_kAppBarHeightMin, _kAppBarHeightMax);

  /// Taille des petits textes/pictos d'information de l'AppBar (chrono, compteurs du titre),
  /// ≈ _uiIconSize × 0.35 (PLAN_ERGONOMIE §4d, décision 59). Plancher 13 : sur iPhone
  /// _uiIconSize plafonne à 30, ×0.35 = 10,5 < actuel ; le plancher tient le garde-fou
  /// « iPhone proche de l'actuel » tout en laissant grandir sur tablette.
  double _uiLabelSize(BuildContext context) =>
      (_uiIconSize(context) * _kLabelSizeFactor)
          .clamp(_kLabelSizeMin, _kLabelSizeMax);

  /// Les actions de la barre, dans l'ordre, **communes aux deux orientations** (PLAN_ERGONOMIE
  /// §9). Une seule source garantit que portrait et paysage proposent la même chose — pas la
  /// discipline de qui édite le fichier. Rendue en `Row` (portrait) ou `Column` (paysage), en
  /// `spaceEvenly`. Le chrono est inséré au centre ; le compteur de solutions reste, les
  /// compteurs iso/déplacements/suppressions sont sortis de la barre (décision 66) — ils vivent
  /// dans le bandeau de fin de partie.
  List<Widget> _buildBarItems(
      BuildContext context, PentoscopeState state, PentoscopeNotifier notifier) {
    final iconSize = _uiIconSize(context);
    // Compteur masqué à la complétion : l'info de fin vit dans la carte de bilan (nettoyage).
    final showCounter = ref.read(settingsProvider).game.showSolutionCounter &&
        state.solutionsCount != null &&
        !state.isComplete;

    final items = <Widget>[
      IconButton(
        icon: const Icon(Icons.add_circle_outline),
        iconSize: iconSize,
        color: Colors.blue,
        onPressed: () => _showNewGameDialog(context, ref),
        tooltip: 'Nouvelle partie',
      ),
      IconButton(
        icon: const Icon(Icons.people_outline),
        iconSize: iconSize,
        color: Colors.purple,
        onPressed: () => _navigateToMultiplayer(context),
        tooltip: 'Mode multijoueur',
      ),
      IconButton(
        icon: Icon(Icons.person,
            color: state.isComplete ? Colors.green : Colors.indigo),
        iconSize: iconSize,
        onPressed: () {
          HapticFeedback.mediumImpact();
          notifier.reset();
        },
        tooltip: 'Recommencer (même taille)',
      ),
      if (!state.isComplete && state.availablePieces.isNotEmpty)
        IconButton(
          icon: Icon(Icons.lightbulb,
              color: state.hasPossibleSolution ? Colors.amber : Colors.red),
          iconSize: iconSize,
          onPressed: () {
            // Mode classé (défi, §4.8) : l'appui est neutralisé. La couleur reste (elle sort du
            // même calcul que le compteur). Le retrait passe par sélection + poubelle.
            if (state.isRanked) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('Indice désactivé en mode défi'),
                  duration: Duration(seconds: 2),
                ));
              return;
            }
            if (state.hasPossibleSolution) {
              HapticFeedback.mediumImpact();
              notifier.applyHint();
            } else if (state.placedPieces.isNotEmpty) {
              // #3 cul-de-sac : la pose reste autorisée (le joueur peut croire, à tort
              // ou à raison, que c'est jouable). Quand l'ampoule est rouge, un appui
              // revient d'un coup en arrière — retire la dernière pièce posée. Répétable :
              // removePlacedPiece recalcule le statut, donc le rouge s'éteint dès que le
              // plateau redevient soluble.
              HapticFeedback.mediumImpact();
              notifier.removePlacedPiece(state.placedPieces.last);
            }
          },
          tooltip: state.hasPossibleSolution
              ? 'Indice'
              : 'Aucune solution — revenir en arrière',
        ),
      // Navigateur de solutions compatibles : seul le 6×10 le sert (BigInt, rendu 6×10).
      // Les petites tailles ont un compte non-nul mais pas de navigateur — sinon il serait vide.
      if (state.puzzle?.size.table != null)
        IconButton(
          icon: const Icon(Icons.view_carousel),
          iconSize: iconSize,
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
      if (showCounter) _buildSolutionCounter(context, state),
      IconButton(
        icon: const Icon(Icons.settings),
        iconSize: iconSize,
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
        tooltip: 'Réglages',
      ),
    ];

    // ⏱️ Chrono au centre : avec spaceEvenly il reste au milieu quel que soit le nombre
    // d'icônes conditionnelles affichées (§9.3). Masqué à la complétion (le temps est dans la
    // carte de bilan) — nettoyage de la barre à la fin.
    if (!state.isComplete) {
      items.insert(items.length ~/ 2, _buildChrono(context, state));
    }
    return items;
  }

  /// Chronomètre de la barre — lisible : `_uiLabelSize × 1.4`, gras (§9.3).
  Widget _buildChrono(BuildContext context, PentoscopeState state) {
    return Text(
      _formatTime(state.elapsedSeconds),
      style: TextStyle(
        fontSize: _uiLabelSize(context) * _kChronoFactor,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  /// Compteur de solutions (nombre restant) — reste dans la barre (§9.4). Rouge à 0, cohérent
  /// avec le bouton d'indice.
  Widget _buildSolutionCounter(BuildContext context, PentoscopeState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${state.solutionsCount}',
          style: TextStyle(
            fontSize: _uiLabelSize(context),
            fontWeight: FontWeight.bold,
            color:
                state.hasPossibleSolution ? Colors.black87 : Colors.red.shade700,
          ),
        ),
      ],
    );
  }

  /// `(taille de case d'une pièce de la barre, épaisseur de la barre)` — la barre est ancrée
  /// sur le plateau : `pieceCellSize = boardCellSize × k` (§3). La dépendance circulaire (la
  /// barre prend de la place au plateau qui la dimensionne) est résolue en comptant la barre
  /// comme ~5k rangées (portrait) ou colonnes (paysage). [reserve] = largeur déjà prise à côté
  /// (la colonne d'actions, en paysage). Garde-fou : jamais sous 8 pt.
  ({double cell, double extent}) _barMetrics(
      Size body, PentoscopeSize size, bool isLandscape, double reserve) {
    final cols = isLandscape ? size.height : size.width;
    final rows = isLandscape ? size.width : size.height;
    const k = kPieceToBoardCellRatio;
    final double boardCell;
    if (isLandscape) {
      boardCell = math.min(
        (body.width - reserve - _kSliderPad) / (cols + 5 * k),
        body.height / rows,
      );
    } else {
      boardCell = math.min(
        (body.width - 8) / cols,
        (body.height - _kSliderPad) / (rows + 5 * k),
      );
    }
    final cell = math.max(8.0, boardCell * k);
    return (cell: cell, extent: cell * 5 + _kSliderPad);
  }

  /// Layout portrait : plateau en haut, actions + slider en bas
  Widget _buildPortraitLayout(
      BuildContext context,
      WidgetRef ref,
      PentoscopeState state,
      PentoscopeNotifier notifier,
      bool isSliderPieceSelected,
      bool isPlacedPieceSelected,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Taille des pièces de la barre, ancrée sur le plateau ; hauteur de barre dérivée.
        final m = _barMetrics(constraints.biggest, state.puzzle!.size, false, 0);
        return Column(
          children: [
            // Plateau de jeu
            const Expanded(flex: 3, child: PentoscopeBoard(isLandscape: false)),

            // Slider de pièces horizontal
            _buildSliderWithDragTarget(
              ref: ref,
              isLandscape: false,
              height: m.extent,
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
              // Le bilan n'occupe plus la zone slider (il est en carte flottante) : slider normal,
              // vide à la complétion (toutes les pièces posées).
              sliderChild:
                  PentoscopePieceSlider(isLandscape: false, pieceCellSize: m.cell),
            ),
          ],
        );
      },
    );
  }

  /// Layout paysage : colonne d'actions à gauche, plateau au milieu, barre à droite —
  /// même ordre qu'en portrait (haut→bas), un seul Row de trois enfants (§7).
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
        // Largeur de la colonne d'actions : assez pour la barre d'isométrie (icônes dédiées, la
        // plus grosse chose qui s'y trouve) + son padding, sinon rognage (§9). L'ancienne formule
        // (0.08 × hauteur) plafonnait.
        final actionColumnWidth = isometryIconSize(context) + 24;
        // Barre ancrée sur le plateau ; sa largeur (pièces verticales) dérive de pieceCellSize.
        final m = _barMetrics(
            constraints.biggest, state.puzzle!.size, true, actionColumnWidth);
        final sliderWidth = m.extent;

        // §7 : ordre identique au portrait — colonne d'actions, plateau, barre, aplati en
        // un seul Row de trois enfants (plus de Row imbriqué « actions + slider »).
        return Row(
          children: [
                // 🎯 Colonne d'actions (contextuelles) — à gauche
                Container(
                  width: actionColumnWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        // Ombre portée vers le plateau (à droite) : la colonne est à gauche.
                        offset: const Offset(1, 0),
                      ),
                    ],
                  ),
                  child: (isPlacedPieceSelected || isSliderPieceSelected)
                      // 🔑 Mode transformation: icônes pleine hauteur, réparties uniformément
                      ? _buildFullHeightIsometryBar(state, notifier, actionColumnWidth)
                      // Mode normal : la MÊME liste qu'en portrait, en colonne, répartie (§9).
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _buildBarItems(context, state, notifier),
                        ),
                ),

                // Plateau de jeu — au milieu
                const Expanded(child: PentoscopeBoard(isLandscape: true)),

                // Slider de pièces vertical — à droite
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
                  sliderChild:
                      PentoscopePieceSlider(isLandscape: true, pieceCellSize: m.cell),
                ),
          ],
        );
      },
    );
  }

  /// Tire un puzzle pour une taille : `(masque, nombre de solutions)`. Le 6×10 est un cas à part
  /// (un seul tirage possible, 12 pièces) : pas de masque, compte = 9356 (la table du 6×10).
  Future<({int? mask, int count})> _drawTirage(
      PentoscopeNotifier notifier, PentoscopeSize size) async {
    if (size == PentoscopeSize.size6x10) {
      return (mask: null, count: size.table!.totalCount);
    }
    final mask = await notifier.drawMask(size);
    return (mask: mask, count: notifier.countOfMask(mask));
  }

  /// Dialogue « Nouvelle partie » : taille + tirage (« n solutions » + « autre tirage ») +
  /// montrer la solution. Le tirage se fait ICI (REFERENCE_TIRAGES §Affichage) : le compte n'est
  /// vrai qu'au tirage, et le masque tiré est transmis à la partie via startPuzzle.
  Future<void> _showNewGameDialog(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(pentoscopeProvider.notifier);
    var selectedSize =
        ref.read(pentoscopeProvider).puzzle?.size ?? PentoscopeSize.size5x5;
    var showSolution = false;

    // Tirage initial avant l'ouverture (charge la table au besoin).
    var tirage = await _drawTirage(notifier, selectedSize);
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> redraw() async {
            final t = await _drawTirage(notifier, selectedSize);
            setState(() => tirage = t);
          }

          return AlertDialog(
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
                      title:
                          Text('${size.label} (${size.width}×${size.height})'),
                      value: size,
                      groupValue: selectedSize,
                      onChanged: (value) async {
                        setState(() => selectedSize = value!);
                        await redraw(); // nouveau tirage pour la nouvelle taille
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${tirage.count} solution${tirage.count > 1 ? "s" : ""}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (selectedSize != PentoscopeSize.size6x10)
                        TextButton.icon(
                          onPressed: redraw,
                          icon: const Icon(Icons.casino_outlined),
                          label: const Text('Autre tirage'),
                        ),
                    ],
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
                    mask: tirage.mask,
                    showSolution: showSolution,
                  );
                },
                child: const Text('Lancer'),
              ),
            ],
          );
        },
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

/// 🏁 Bilan de fin — **carte flottante non-modale**, centrée par-dessus le plateau résolu (visible
/// derrière). Regroupe tout le bilan lisiblement : titre, médaille éventuelle, les trois maillots
/// en lignes libellées (acuité / coups / temps), puis « Fermer » et l'action primaire. « Fermer »
/// escamote la carte pour admirer la solution ; les zones hors carte laissent passer les taps.
class _BilanCard extends StatelessWidget {
  /// Les trois maillots (CDC §4.5). null si aucun puzzle (ne devrait pas arriver à la complétion).
  final CompletionMetrics? metrics;

  /// Aides utilisées : si > 0, la partie n'est pas « propre » (hors record, §4.8).
  final int hintCount;
  final VoidCallback onClose;
  final VoidCallback onNewGame;

  /// Progression : passer au niveau suivant. null si ce n'est pas un puzzle de progression, ou
  /// si le niveau maximal vient d'être terminé.
  final VoidCallback? onNextLevel;

  const _BilanCard({
    required this.metrics,
    required this.hintCount,
    required this.onClose,
    required this.onNewGame,
    this.onNextLevel,
  });

  static String _mmss(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final perfect = m != null && m.perfectVision && hintCount == 0;

    final primaryButton = onNextLevel == null
        ? FilledButton.icon(
            onPressed: onNewGame,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Nouvelle partie'),
          )
        : FilledButton.icon(
            onPressed: onNextLevel,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Niveau suivant'),
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                      const SizedBox(width: 8),
                      Text(
                        'Résolu !',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (perfect) ...[
                    const SizedBox(height: 10),
                    const _PerfectBadge(),
                  ],
                  const SizedBox(height: 18),
                  if (m != null) ...[
                    _MaillotLine(
                      color: const Color(0xFFF2B705),
                      label: 'Acuité',
                      value: '${(m.acuity * 100).round()} %',
                      detail: '${m.isometryCount} isométries · min ${m.minIso}',
                    ),
                    _MaillotLine(
                      color: const Color(0xFFD64545),
                      label: 'Coups',
                      value: '${m.moves}',
                      detail: 'minimum ${m.minMoves}',
                    ),
                    _MaillotLine(
                      color: const Color(0xFF2E9E5B),
                      label: 'Temps',
                      value: _mmss(m.timeSeconds),
                    ),
                  ],
                  if (hintCount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb, size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          '$hintCount aide${hintCount > 1 ? 's' : ''} — hors record',
                          style: const TextStyle(color: Colors.orange, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: onClose, child: const Text('Fermer')),
                      const SizedBox(width: 8),
                      primaryButton,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Une ligne de maillot dans la carte de bilan : pastille colorée + libellé, valeur brute à
/// droite (§4.5), détail (minimums, isométries) en petit dessous.
class _MaillotLine extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String? detail;

  const _MaillotLine({
    required this.color,
    required this.label,
    required this.value,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (detail != null)
                Text(detail!,
                    style: TextStyle(
                        fontSize: 11, color: Theme.of(context).hintColor)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Badge « Vision parfaite » (§4.6) affiché en tête de carte quand l'acuité est à 100 %.
class _PerfectBadge extends StatelessWidget {
  const _PerfectBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2B705).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech, color: Color(0xFFF2B705), size: 18),
          SizedBox(width: 6),
          Text('Vision parfaite',
              style: TextStyle(
                  color: Color(0xFF9A7400), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}