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
const int _kLoopMs = 10000; // boucle lente (démo pédagogique)
// Fractions de la boucle (0..1). Des pauses (dwell) séparent les phases pour laisser lire.
const double _kSelectEnd = 0.14; // sélection + halo
const double _kIso1Start = 0.22, _kIso1End = 0.42; // 1re isométrie
const double _kIso2Start = 0.52, _kIso2End = 0.72; // 2e isométrie
const double _kRiseStart = 0.80, _kRiseEnd = 0.94; // montée + pose (0.94..1.0 : maintien)

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
  int _demoIndex = 0; // quelle pièce du tirage fait la démo
  bool _demoUseMirror = false; // 2e isométrie = miroir (si visible) sinon 2e rotation

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
    // Une pièce au hasard fait la démo ; les autres restent dans le rack.
    _demoIndex = _rng.nextInt(_tirages[_tirageIndex].length);
    // 2e isométrie = miroir seulement s'il CHANGE la pièce (sinon 2e rotation, toujours visible :
    // le U/pièce 7 est symétrique par miroir → le miroir ne ferait rien).
    _demoUseMirror = _mirrorChanges(_tirages[_tirageIndex][_demoIndex]);
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

  /// Le miroir horizontal change-t-il la pièce (à son orientation posée) ? Faux pour une pièce
  /// symétrique (ex. le U) — auquel cas la démo utilise une 2e rotation à la place.
  bool _mirrorChanges(_Placement pl) {
    final cells = pl.pento.orientations[pl.orientation]
        .map((n) => [(n - 1) % 5, (n - 1) ~/ 5])
        .toList();
    final flipped = [for (final c in cells) [-c[0], c[1]]];
    return _normKey(flipped) != _normKey(cells);
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
    // Disposition du vrai jeu : barre d'isométrie EN HAUT, plateau au milieu, rack EN BAS.
    const gap = 18.0;
    const toolbarH = 64.0; // barre haute pour des icônes d'isométrie bien visibles
    const rackCells = kPieceToBoardCellRatio * 3; // hauteur du rack, en cases-équivalent
    final cellByW = constraints.maxWidth / kHomeBoardWidth;
    final cellByH = (constraints.maxHeight - toolbarH - gap * 2 - 24) /
        (kHomeBoardHeight + rackCells);
    final cell = math.min(cellByW, cellByH).clamp(0.0, 96.0).toDouble();
    final boardW = cell * kHomeBoardWidth;
    final boardH = cell * kHomeBoardHeight;
    final rackH = cell * rackCells + 24;
    final boardTop = toolbarH + gap;
    final rackTop = boardTop + boardH + gap;
    final sceneW = boardW;
    final sceneH = rackTop + rackH;

    return SizedBox(
      width: sceneW,
      height: sceneH,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final f = _reduceMotion ? 1.0 : _controller.value;
          final pieces = _tirages[_tirageIndex];
          final demo = pieces[_demoIndex];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Barre d'isométrie EN HAUT (vraies icônes), surlignée pendant les isométries.
              if (!_reduceMotion) _buildIsoToolbar(f, toolbarH, sceneW),
              // Plateau (vide) + case-cible fantôme de la pièce-démo.
              Positioned(
                left: 0,
                top: boardTop,
                child: _buildBoardBackdrop(boardW, boardH, cell),
              ),
              _buildGhostTarget(demo, cell, boardTop, colorOf),
              // Rack EN BAS : le fond, puis toutes les pièces en minis (la démo est animée).
              _buildRackBackdrop(sceneW, rackTop, rackH),
              for (int i = 0; i < pieces.length; i++)
                if (i != _demoIndex)
                  _buildRackMini(pieces[i], i, pieces.length, cell, rackTop,
                      rackH, sceneW, colorOf),
              _buildDemoPiece(demo, _demoIndex, pieces.length, f, cell, boardTop,
                  rackTop, rackH, sceneW, colorOf),
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
  /// Case-cible fantôme : la pièce-démo dessinée en transparence à sa place, pour montrer où elle va.
  Widget _buildGhostTarget(
      _Placement pl, double cell, double boardTop, Color Function(int) colorOf) {
    final fullW = pl.wCells * cell + 8;
    final fullH = pl.hCells * cell + 8;
    final center = Offset(
      (pl.anchorX + pl.wCells / 2) * cell,
      boardTop + (pl.anchorY + pl.hCells / 2) * cell,
    );
    return Positioned(
      left: center.dx - fullW / 2,
      top: center.dy - fullH / 2,
      child: Opacity(
        opacity: 0.16,
        child: PieceRenderer(
          piece: pl.pento,
          positionIndex: pl.orientation,
          getPieceColor: colorOf,
          cellSize: cell,
          showLabel: false,
        ),
      ),
    );
  }

  /// Le fond du rack (bande basse), comme le tiroir du jeu.
  Widget _buildRackBackdrop(double sceneW, double rackTop, double rackH) {
    return Positioned(
      left: 0,
      top: rackTop,
      width: sceneW,
      height: rackH,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  /// Une pièce au repos dans le rack (mini, à son emplacement).
  Widget _buildRackMini(_Placement pl, int index, int count, double cell,
      double rackTop, double rackH, double sceneW, Color Function(int) colorOf) {
    final effCell = cell * kPieceToBoardCellRatio;
    final fullW = pl.wCells * effCell + 8;
    final fullH = pl.hCells * effCell + 8;
    final center =
        Offset(sceneW * (index + 1) / (count + 1), rackTop + rackH / 2);
    return Positioned(
      left: center.dx - fullW / 2,
      top: center.dy - fullH / 2,
      child: PieceRenderer(
        piece: pl.pento,
        positionIndex: pl.orientation,
        getPieceColor: colorOf,
        cellSize: effCell,
        showLabel: false,
      ),
    );
  }

  /// La pièce-démo : dans le rack (bas) avec un halo, tournée (iso 1), retournée (iso 2), puis
  /// montée du rack jusqu'à sa case sur le plateau. `f` = progression de la boucle (0..1).
  Widget _buildDemoPiece(
      _Placement pl,
      int index,
      int count,
      double f,
      double cell,
      double boardTop,
      double rackTop,
      double rackH,
      double sceneW,
      Color Function(int) colorOf) {
    final selectP = (f / _kSelectEnd).clamp(0.0, 1.0);
    final iso1 =
        ((f - _kIso1Start) / (_kIso1End - _kIso1Start)).clamp(0.0, 1.0);
    final iso2 =
        ((f - _kIso2Start) / (_kIso2End - _kIso2Start)).clamp(0.0, 1.0);
    final rise = ((f - _kRiseStart) / (_kRiseEnd - _kRiseStart)).clamp(0.0, 1.0);

    // Taille de case : miniature dans le rack, pleine une fois posée.
    final effCell = cell * _lerp(kPieceToBoardCellRatio, 1.0, rise);
    final fullW = pl.wCells * effCell + 8;
    final fullH = pl.hCells * effCell + 8;

    // Départ : l'emplacement de la pièce dans le rack. Arrivée : sa case sur le plateau.
    final rackCenter =
        Offset(sceneW * (index + 1) / (count + 1), rackTop + rackH / 2);
    final boardCenter = Offset(
      (pl.anchorX + pl.wCells / 2) * cell,
      boardTop + (pl.anchorY + pl.hCells / 2) * cell,
    );
    final center = Offset.lerp(rackCenter, boardCenter, rise)!;

    // Rotation : 1 quart si la 2e isométrie est un miroir ; sinon 2 quarts (les deux isométries
    // sont des rotations — cas des pièces symétriques comme le U). Chaque quart est défait à son iso.
    final startQuarters = _demoUseMirror ? 1 : 2;
    final quartersLeft = startQuarters - iso1 - (_demoUseMirror ? 0.0 : iso2);
    final angle = quartersLeft * (math.pi / 2);
    final mirrorX = _demoUseMirror ? _lerp(-1.0, 1.0, iso2) : 1.0;
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
  Widget _buildIsoToolbar(double f, double toolbarH, double sceneW) {
    final inIso1 = f >= _kIso1Start && f < _kIso1End;
    final inIso2 = f >= _kIso2Start && f < _kIso2End;
    // Icône active : rotation pendant iso 1 (et iso 2 si la 2e isométrie est une rotation) ;
    // miroir seulement quand la 2e isométrie est un miroir.
    final rotActive = inIso1 || (inIso2 && !_demoUseMirror);
    final mirrorActive = inIso2 && _demoUseMirror;

    double opacity;
    if (f < _kIso1Start - 0.06) {
      opacity = 0;
    } else if (f < _kIso1Start) {
      opacity = ((f - (_kIso1Start - 0.06)) / 0.06).clamp(0.0, 1.0);
    } else if (f < _kIso2End) {
      opacity = 1;
    } else {
      opacity = (1 - (f - _kIso2End) / 0.06).clamp(0.0, 1.0);
    }
    if (opacity <= 0.01) return const SizedBox.shrink();

    final iconSize = (toolbarH * 0.62).clamp(22.0, 42.0).toDouble();
    final items = <(IconData, bool)>[
      (GameIcons.isometryRotationTW.icon, false),
      (GameIcons.isometryRotationCW.icon, rotActive),
      (GameIcons.isometrySymmetryH.icon, mirrorActive),
      (GameIcons.isometrySymmetryV.icon, false),
    ];

    return Positioned(
      top: 0,
      left: 0,
      width: sceneW,
      height: toolbarH,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Center(
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (icon, active) in items)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.all(7),
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
