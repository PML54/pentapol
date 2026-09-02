// Modified: 2026-09-02 20:37 — progression : label « Niveau N » sous la démo ; « Jouer » enchaîne
//           sur le puzzle du niveau courant (sizeForLevel), frais si l'actuel est terminé/autre
//           niveau, sinon reprend.
// lib/pentoscope/home/home_screen.dart
// Historique: 2026-09-02 17:05 — écran d'accueil (PLAN_ECRAN_ACCUEIL) : en-tête PENTAPOL + engrenage,
//           scène plateau VERTICAL 3×5 (retour de Paul) + animation-démo (miniature → rotation par
//           quarts → montée/pose, boucle sur les 7 tirages), bouton Jouer. cellSize bornée par la
//           hauteur. Réutilise PieceRenderer (showLabel:false, pièces nues).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/settings_screen.dart';
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

/// Fenêtres temporelles (secondes) d'une pièce dans la boucle (§2).
class _Span {
  final double rotStart;
  final double rotEnd;
  final double riseStart;
  final double riseEnd;
  const _Span(this.rotStart, this.rotEnd, this.riseStart, this.riseEnd);
}

// Durées (§2), en secondes.
const double _kRotPerQuarter = 0.40;
const double _kGapRotToRise = 0.18;
const double _kRiseDur = 0.66;
const double _kBetweenPieces = 0.18;
const double _kFinalPause = 2.0;

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
  List<int> _quarters = const []; // quarts d'écart initiaux, par pièce, pour la boucle courante
  List<_Span> _spans = const [];
  double _loopDuration = 1;

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
    _prepareLoop();
    _controller
      ..duration = Duration(milliseconds: (_loopDuration * 1000).round())
      ..forward(from: 0);
  }

  void _nextTirage() {
    if (!mounted) return;
    setState(() => _tirageIndex = (_tirageIndex + 1) % _tirages.length);
    _startLoop();
  }

  /// Prépare les quarts d'écart et la chronologie de la boucle courante.
  void _prepareLoop() {
    final pieces = _tirages[_tirageIndex];
    _quarters = [for (var _ in pieces) 1 + _rng.nextInt(3)]; // 1..3
    final spans = <_Span>[];
    double t = 0;
    for (int i = 0; i < pieces.length; i++) {
      final rotStart = t;
      final rotEnd = rotStart + _quarters[i] * _kRotPerQuarter;
      final riseStart = rotEnd + _kGapRotToRise;
      final riseEnd = riseStart + _kRiseDur;
      spans.add(_Span(rotStart, rotEnd, riseStart, riseEnd));
      t = riseEnd + _kBetweenPieces;
    }
    _spans = spans;
    _loopDuration = (spans.last.riseEnd + _kFinalPause).clamp(0.5, 60.0);
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
          final elapsed =
              _reduceMotion ? _loopDuration : _controller.value * _loopDuration;
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
              // Pièces (miniatures → posées).
              for (int i = 0; i < pieces.length; i++)
                _buildAnimatedPiece(
                  pieces[i],
                  i,
                  pieces.length,
                  cell,
                  boardH,
                  gap,
                  stripH,
                  sceneW,
                  elapsed,
                  colorOf,
                ),
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

  Widget _buildAnimatedPiece(
    _Placement pl,
    int index,
    int count,
    double cell,
    double boardH,
    double gap,
    double stripH,
    double sceneW,
    double elapsed,
    Color Function(int) colorOf,
  ) {
    final span = _reduceMotion ? null : _spans[index];
    final quarters = _reduceMotion ? 0 : _quarters[index];

    // Progrès des deux phases.
    final rotP = span == null
        ? 1.0
        : ((elapsed - span.rotStart) / (span.rotEnd - span.rotStart))
            .clamp(0.0, 1.0);
    final riseP = span == null
        ? 1.0
        : ((elapsed - span.riseStart) / (span.riseEnd - span.riseStart))
            .clamp(0.0, 1.0);

    // Taille du widget PieceRenderer à taille réelle (cellSize = cell).
    final fullW = pl.wCells * cell + 8;
    final fullH = pl.hCells * cell + 8;

    // Centre final : au milieu de la zone de cases occupée sur le plateau.
    final finalCenter = Offset(
      (pl.anchorX + pl.wCells / 2) * cell,
      (pl.anchorY + pl.hCells / 2) * cell,
    );
    // Centre de départ : réparti sur la bande basse.
    final slotCenter = Offset(
      sceneW * (index + 1) / (count + 1),
      boardH + gap + stripH / 2,
    );

    final center = Offset.lerp(slotCenter, finalCenter, riseP)!;
    final scale = _lerp(kPieceToBoardCellRatio, 1.0, riseP);
    final angle = (1 - rotP) * quarters * (math.pi / 2);

    return Positioned(
      left: center.dx - fullW / 2,
      top: center.dy - fullH / 2,
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: scale,
          child: PieceRenderer(
            piece: pl.pento,
            positionIndex: pl.orientation,
            getPieceColor: colorOf,
            cellSize: cell,
            showLabel: false, // accueil : pièces nues (PLAN_ECRAN_ACCUEIL §1)
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
