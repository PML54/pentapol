// Modified: 2026-09-05 — vignette « une pièce, deux isométries, une pose » : l'animation-démo montre
//           les autres pièces déjà posées + UNE pièce du rack sélectionnée (halo) → rotation (iso 1)
//           → miroir (iso 2), avec les VRAIES icônes d'isométrie surlignées → montée/pose. Boucle en
//           changeant de tirage/pièce. Remplace l'ancien remplissage multi-pièces. Onboarding + met
//           en avant la barre d'isométrie (découvrabilité, REFERENCE_ISOMETRIES §4).
// lib/pentoscope/home/home_screen.dart
// Historique: 2026-09-04 06:56 — défi hebdo Phase 2 : bouton drapeau dans l'en-tête → ChallengeScreen
//           (choix de taille du défi de la semaine).
// Historique: 2026-09-04 06:05 — records perso C : bouton trophée dans l'en-tête → RecordsScreen
//           (écran de lecture des trois maillots).
// Historique: 2026-09-02 20:37 — progression : label « Niveau N » sous la démo ; « Jouer » enchaîne
//           sur le puzzle du niveau courant (sizeForLevel), frais si l'actuel est terminé/autre
//           niveau, sinon reprend.
// Historique: 2026-09-02 17:05 — écran d'accueil (PLAN_ECRAN_ACCUEIL) : en-tête PENTAPOL + engrenage,
//           scène plateau VERTICAL 3×5 (retour de Paul) + animation-démo (miniature → rotation par
//           quarts → montée/pose, boucle sur les 7 tirages), bouton Jouer. cellSize bornée par la
//           hauteur. Réutilise PieceRenderer (showLabel:false, pièces nues).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/settings_screen.dart';
import 'package:pentapol/pentoscope/screens/records_screen.dart';
import 'package:pentapol/pentoscope/screens/challenge_screen.dart';
import 'package:pentapol/pentoscope/home/home_tirages_data.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart' show sizeForLevel;
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart'
    show kPieceToBoardCellRatio, PentoscopeGameScreen;

/// Placement d'une pièce prêt à rendre : le [Pento], l'index d'orientation qui reproduit les
/// cellules du tirage, l'ancre (case haut-gauche) sur le plateau 5×3, et la taille en cases.
class _Placement {
  final Pento pento;
  final int orientation;
  final int anchorX;
  final int anchorY;
  final int wCells;
  final int hCells;
  const _Placement(this.pento, this.orientation, this.anchorX, this.anchorY,
      this.wCells, this.hCells);
}

// Vignette « une pièce, deux isométries, une pose ». Une pièce du rack est sélectionnée (halo),
// tournée (icône rotation), retournée (icône miroir), puis montée à sa place. Fractions de la
// boucle (0..1) où finit chaque phase.
const int _kLoopMs = 6000;
const double _kSelectEnd = 0.16; // sélection + halo
const double _kIso1End = 0.42; // 1re isométrie : rotation
const double _kIso2End = 0.68; // 2e isométrie : miroir
const double _kRiseEnd = 0.88; // montée + pose  (0.88..1.0 : maintien)

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  final math.Random _rng = math.Random();

  /// Placements pré-calculés des 7 tirages (indépendants de l'animation).
  late final List<List<_Placement>> _tirages;

  int _tirageIndex = 0;
  int _demoIndex = 0; // quelle pièce du tirage fait la démo (le reste est déjà posé)

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tirages = kHomeTirages.map(_placementsFor).toList();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _nextTirage();
      });
    // Démarrage différé : disableAnimations n'est lisible qu'avec un contexte monté.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_reduceMotion) _startLoop();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Économie : suspendre l'animation quand l'app passe en arrière-plan.
    if (state == AppLifecycleState.resumed) {
      if (!_reduceMotion && !_controller.isAnimating) _controller.forward();
    } else if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  void _startLoop() {
    // Une pièce au hasard fait la démo ; les autres sont déjà posées (case laissée vide = la cible).
    _demoIndex = _rng.nextInt(_tirages[_tirageIndex].length);
    _controller
      ..duration = const Duration(milliseconds: _kLoopMs)
      ..forward(from: 0);
  }

  void _nextTirage() {
    if (!mounted) return;
    // Tirage suivant (autre pièce-démo au prochain _startLoop).
    setState(() => _tirageIndex = (_tirageIndex + 1) % _tirages.length);
    _startLoop();
  }

  // ── Géométrie des pièces ────────────────────────────────────────────────────

  /// Convertit un tirage (cellules) en placements rendables (orientation + ancre).
  List<_Placement> _placementsFor(HomeTirage tirage) {
    return tirage.pieces.map((hp) {
      final pento = pentominos[hp.id - 1];
      // Cellules normalisées du placement (ancre = min).
      int minX = 1 << 30, minY = 1 << 30, maxX = -(1 << 30), maxY = -(1 << 30);
      for (final c in hp.cells) {
        minX = math.min(minX, c[0]);
        minY = math.min(minY, c[1]);
        maxX = math.max(maxX, c[0]);
        maxY = math.max(maxY, c[1]);
      }
      final wantKey = _normKey([for (final c in hp.cells) [c[0] - minX, c[1] - minY]]);
      // Orientation de Pento qui reproduit cette forme.
      int oi = 0;
      for (int i = 0; i < pento.orientations.length; i++) {
        final cells = pento.orientations[i]
            .map((n) => [(n - 1) % 5, (n - 1) ~/ 5])
            .toList();
        if (_normKey(cells) == wantKey) {
          oi = i;
          break;
        }
      }
      return _Placement(pento, oi, minX, minY, maxX - minX + 1, maxY - minY + 1);
    }).toList();
  }

  String _normKey(List<List<int>> cells) {
    int minX = 1 << 30, minY = 1 << 30;
    for (final c in cells) {
      minX = math.min(minX, c[0]);
      minY = math.min(minY, c[1]);
    }
    final norm = [for (final c in cells) [c[0] - minX, c[1] - minY]]
      ..sort((a, b) => a[1] != b[1] ? a[1] - b[1] : a[0] - b[0]);
    return norm.map((c) => '${c[0]},${c[1]}').join(';');
  }

  // ── Rendu ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    Color colorOf(int id) => settings.ui.getPieceColor(id);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Align(
                // Plateau ancré haut, près de l'en-tête ; le rab passe sous la scène.
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        _buildScene(constraints, colorOf),
                  ),
                ),
              ),
            ),
            _buildPlayButton(context, settings.currentLevel),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PENTAPOL',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Colors.black87,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.flag_outlined, color: Colors.black54),
                iconSize: 28,
                tooltip: 'Défi de la semaine',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChallengeScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.emoji_events_outlined, color: Colors.black54),
                iconSize: 28,
                tooltip: 'Mes records',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecordsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.black54),
                iconSize: 28,
                tooltip: 'Réglages',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScene(BoxConstraints constraints, Color Function(int) colorOf) {
    const gap = 28.0;
    // Taille de case bornée par la largeur ET par la hauteur disponible : le plateau vertical
    // (3×5) est plus haut que large, il ne doit pas déborder sous l'en-tête.
    final cellByW = constraints.maxWidth / kHomeBoardWidth;
    final cellByH = (constraints.maxHeight - gap - 24) /
        (kHomeBoardHeight + kPieceToBoardCellRatio * 3);
    final cell = math.min(cellByW, cellByH).clamp(0.0, 96.0).toDouble();
    final boardW = cell * kHomeBoardWidth;
    final boardH = cell * kHomeBoardHeight;
    // Bande basse : hauteur d'une pièce en miniature (jusqu'à 3 cases de haut).
    final stripH = cell * kPieceToBoardCellRatio * 3 + 24;
    final sceneW = boardW;
    final sceneH = boardH + gap + stripH;

    return SizedBox(
      width: sceneW,
      height: sceneH,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final f = _reduceMotion ? 1.0 : _controller.value;
          final pieces = _tirages[_tirageIndex];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Fond : le plateau 5×3.
              Positioned(
                left: 0,
                top: 0,
                child: _buildBoardBackdrop(boardW, boardH, cell),
              ),
              // Les autres pièces sont DÉJÀ posées (la case de la pièce-démo reste vide = la cible).
              for (int i = 0; i < pieces.length; i++)
                if (i != _demoIndex) _buildPlacedPiece(pieces[i], cell, colorOf),
              // La pièce-démo : sélection (halo) → rotation → miroir → montée + pose.
              _buildDemoPiece(pieces[_demoIndex], f, cell, boardH, gap, stripH,
                  sceneW, colorOf),
              // La barre d'isométrie (vraies icônes), surlignée pendant les isométries.
              if (!_reduceMotion)
                _buildIsoToolbar(f, cell, boardH, gap, sceneW),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBoardBackdrop(double boardW, double boardH, double cell) {
    return Container(
      width: boardW,
      height: boardH,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade500, width: 3),
      ),
      child: Column(
        children: [
          for (int y = 0; y < kHomeBoardHeight; y++)
            Expanded(
              child: Row(
                children: [
                  for (int x = 0; x < kHomeBoardWidth; x++)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey.shade300, width: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Une pièce déjà posée à sa place sur le plateau (statique, pièces nues §1).
  Widget _buildPlacedPiece(
      _Placement pl, double cell, Color Function(int) colorOf) {
    final fullW = pl.wCells * cell + 8;
    final fullH = pl.hCells * cell + 8;
    final center = Offset(
      (pl.anchorX + pl.wCells / 2) * cell,
      (pl.anchorY + pl.hCells / 2) * cell,
    );
    return Positioned(
      left: center.dx - fullW / 2,
      top: center.dy - fullH / 2,
      child: PieceRenderer(
        piece: pl.pento,
        positionIndex: pl.orientation,
        getPieceColor: colorOf,
        cellSize: cell,
        showLabel: false,
      ),
    );
  }

  /// La pièce-démo : dans le rack avec un halo de sélection, tournée (iso 1), retournée (iso 2),
  /// puis montée + posée à sa place. `f` = progression de la boucle (0..1).
  Widget _buildDemoPiece(_Placement pl, double f, double cell, double boardH,
      double gap, double stripH, double sceneW, Color Function(int) colorOf) {
    final selectP = (f / _kSelectEnd).clamp(0.0, 1.0);
    final iso1 =
        ((f - _kSelectEnd) / (_kIso1End - _kSelectEnd)).clamp(0.0, 1.0);
    final iso2 = ((f - _kIso1End) / (_kIso2End - _kIso1End)).clamp(0.0, 1.0);
    final rise = ((f - _kIso2End) / (_kRiseEnd - _kIso2End)).clamp(0.0, 1.0);

    // Taille de case : miniature dans le rack, pleine une fois posée.
    final effCell = cell * _lerp(kPieceToBoardCellRatio, 1.0, rise);
    final fullW = pl.wCells * effCell + 8;
    final fullH = pl.hCells * effCell + 8;

    final finalCenter = Offset(
      (pl.anchorX + pl.wCells / 2) * cell,
      (pl.anchorY + pl.hCells / 2) * cell,
    );
    final rackCenter = Offset(sceneW / 2, boardH + gap + stripH / 2);
    final center = Offset.lerp(rackCenter, finalCenter, rise)!;

    final angle = (1 - iso1) * (math.pi / 2); // rotation d'un quart, défaite à l'iso 1
    final mirrorX = _lerp(-1.0, 1.0, iso2); // miroir horizontal, défait à l'iso 2
    final halo = (selectP * (1 - rise)).clamp(0.0, 1.0);

    return Positioned(
      left: center.dx - fullW / 2,
      top: center.dy - fullH / 2,
      width: fullW,
      height: fullH,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: halo > 0.02
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.55 * halo),
                    blurRadius: 18,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Transform.rotate(
            angle: angle, // iso 1 : rotation d'un quart
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(mirrorX, 1.0, 1.0), // iso 2 : miroir horizontal
              child: PieceRenderer(
                piece: pl.pento,
                positionIndex: pl.orientation,
                getPieceColor: colorOf,
                cellSize: effCell,
                showLabel: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// La barre d'isométrie (VRAIES icônes du jeu), surlignée sur l'icône active pendant chaque
  /// isométrie — c'est l'info à faire découvrir. Fondu au début, disparaît à la montée.
  Widget _buildIsoToolbar(
      double f, double cell, double boardH, double gap, double sceneW) {
    final inIso1 = f >= _kSelectEnd && f < _kIso1End; // rotation
    final inIso2 = f >= _kIso1End && f < _kIso2End; // miroir
    double opacity;
    if (f < _kSelectEnd * 0.4) {
      opacity = 0;
    } else if (f < _kSelectEnd) {
      opacity = ((f - _kSelectEnd * 0.4) / (_kSelectEnd * 0.6)).clamp(0.0, 1.0);
    } else if (f < _kIso2End) {
      opacity = 1;
    } else {
      opacity = (1 - (f - _kIso2End) / 0.06).clamp(0.0, 1.0);
    }
    if (opacity <= 0.01) return const SizedBox.shrink();

    final iconSize = (cell * 0.42).clamp(16.0, 30.0).toDouble();
    final items = <(IconData, bool)>[
      (GameIcons.isometryRotationTW.icon, false),
      (GameIcons.isometryRotationCW.icon, inIso1),
      (GameIcons.isometrySymmetryH.icon, inIso2),
      (GameIcons.isometrySymmetryV.icon, false),
    ];

    return Positioned(
      top: boardH + gap * 0.12,
      left: 0,
      width: sceneW,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (icon, active) in items)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: active ? Colors.amber : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 1)
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: iconSize * (active ? 1.15 : 1.0),
                    color: active ? Colors.white : Colors.black45,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, int level) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Niveau $level',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () => _play(context, level),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Jouer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// « Jouer » : enchaîne sur le puzzle du niveau courant. Si aucune partie de progression du bon
  /// niveau n'est en cours (terminée, autre taille, puzzle du « + », ou aucune), on en démarre une
  /// fraîche ; sinon on reprend celle en cours.
  Future<void> _play(BuildContext context, int level) async {
    final notifier = ref.read(pentoscopeProvider.notifier);
    final st = ref.read(pentoscopeProvider);
    final size = sizeForLevel(level);
    final needFresh = st.puzzle == null ||
        st.isComplete ||
        !st.isProgression ||
        st.puzzle!.size != size;
    if (needFresh) {
      await notifier.startPuzzle(size, isProgression: true);
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PentoscopeGameScreen()),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
