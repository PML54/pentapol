// Modified: 2026-09-23 17:15 — ralentir encore légèrement la démonstration.
// lib/pentoscope/home/animated_home_board.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/pentoscope/corpus_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/solution_source.dart';

const _homeDemoSolutionCount = 8;

/// Une sélection de solutions 5×5 distinctes, sans modifier la partie du joueur.
final homeDemoSolutionsProvider = FutureProvider<List<List<PlacedPiece>>>((
  ref,
) async {
  final generator = PentoscopeGenerator();
  final corpus = await ref.watch(tirageCorpusProvider.future);
  final random = math.Random();
  final solutions = <List<PlacedPiece>>[];
  final signatures = <String>{};

  for (
    var attempt = 0;
    solutions.length < _homeDemoSolutionCount && attempt < 80;
    attempt++
  ) {
    final puzzle = await generator.generate(PentoscopeSize.size5x5);
    final mask = puzzle.pieceIds.fold<int>(
      0,
      (value, id) => value | (1 << (id - 1)),
    );
    final source = CorpusSolutionSource(
      corpus.solutionsFor(mask),
      width: 5,
      height: 5,
      random: random,
    );
    final solution = source.hintFrom(Plateau.allVisible(5, 5), const []);
    if (solution == null || !signatures.add(_solutionSignature(solution))) {
      continue;
    }
    solution.shuffle(random);
    solutions.add(List.unmodifiable(solution));
  }

  if (solutions.isEmpty) {
    throw StateError('Aucune solution disponible pour la démonstration 5×5.');
  }
  return List.unmodifiable(solutions);
});

@immutable
class HomeDemoTiming {
  final Duration preview;
  final Duration drag;
  final Duration settle;
  final Duration completed;
  final Duration reset;

  const HomeDemoTiming({
    this.preview = const Duration(milliseconds: 650),
    this.drag = const Duration(milliseconds: 800),
    this.settle = const Duration(milliseconds: 180),
    this.completed = const Duration(milliseconds: 1150),
    this.reset = const Duration(milliseconds: 700),
  });

  int get pieceMilliseconds =>
      preview.inMilliseconds + drag.inMilliseconds + settle.inMilliseconds;
}

class AnimatedHomeBoard extends StatefulWidget {
  static const double chromeHeight = 120;

  final List<List<PlacedPiece>> solutions;
  final Color Function(int pieceId) colorOf;
  final double cellSize;
  final HomeDemoTiming timing;

  const AnimatedHomeBoard({
    super.key,
    required this.solutions,
    required this.colorOf,
    this.cellSize = 34,
    this.timing = const HomeDemoTiming(),
  }) : assert(solutions.length > 0);

  @override
  State<AnimatedHomeBoard> createState() => _AnimatedHomeBoardState();
}

class _AnimatedHomeBoardState extends State<AnimatedHomeBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _reduceMotion = false;
  int _solutionIndex = 0;
  double _lastControllerValue = 0;

  List<PlacedPiece> get _solution =>
      widget.solutions[_solutionIndex % widget.solutions.length];

  int get _piecesDuration => _solution.length * widget.timing.pieceMilliseconds;
  int get _loopMilliseconds =>
      _piecesDuration +
      widget.timing.completed.inMilliseconds +
      widget.timing.reset.inMilliseconds;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _loopMilliseconds),
    )..addListener(_advanceSolutionAfterReset);
  }

  void _advanceSolutionAfterReset() {
    final value = _controller.value;
    if (value < _lastControllerValue && widget.solutions.length > 1) {
      setState(
        () => _solutionIndex = (_solutionIndex + 1) % widget.solutions.length,
      );
    }
    _lastControllerValue = value;
  }

  @override
  void didUpdateWidget(covariant AnimatedHomeBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.solutions != widget.solutions ||
        oldWidget.timing != widget.timing) {
      _solutionIndex %= widget.solutions.length;
      _controller.duration = Duration(milliseconds: _loopMilliseconds);
      if (!_reduceMotion) _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion == _reduceMotion &&
        (_controller.isAnimating || reduceMotion)) {
      return;
    }
    _reduceMotion = reduceMotion;
    reduceMotion ? _controller.stop() : _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) {
      return _HomeGameScene(
        solution: _solution,
        colorOf: widget.colorOf,
        cellSize: widget.cellSize,
        elapsed: _piecesDuration,
        timing: widget.timing,
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _HomeGameScene(
        solution: _solution,
        colorOf: widget.colorOf,
        cellSize: widget.cellSize,
        elapsed: (_controller.value * _loopMilliseconds).floor(),
        timing: widget.timing,
      ),
    );
  }
}

class _HomeGameScene extends StatelessWidget {
  static const rackGap = 12.0;
  static const rackHeight = 108.0;
  static const toolbarHeight = 44.0;
  final List<PlacedPiece> solution;
  final Color Function(int pieceId) colorOf;
  final double cellSize;
  final int elapsed;
  final HomeDemoTiming timing;

  const _HomeGameScene({
    required this.solution,
    required this.colorOf,
    required this.cellSize,
    required this.elapsed,
    required this.timing,
  });

  @override
  Widget build(BuildContext context) {
    final boardSize = cellSize * 5;
    final sceneWidth = math.max(boardSize, cellSize * 6.4);
    final boardLeft = (sceneWidth - boardSize) / 2;
    final pieceMs = timing.pieceMilliseconds;
    final piecesDuration = solution.length * pieceMs;
    final resetting =
        elapsed >= piecesDuration + timing.completed.inMilliseconds;
    final completion =
        ((elapsed - piecesDuration) / timing.completed.inMilliseconds).clamp(
          0.0,
          1.0,
        );
    final pulse = resetting ? 0.0 : math.sin(completion * math.pi);
    final resetProgress = resetting
        ? ((elapsed - piecesDuration - timing.completed.inMilliseconds) /
                  timing.reset.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;
    var current = (elapsed ~/ pieceMs).clamp(0, solution.length);
    if (elapsed >= piecesDuration) current = solution.length;
    final local = current < solution.length ? elapsed % pieceMs : 0;
    final dragStart = timing.preview.inMilliseconds;
    final dragEnd = dragStart + timing.drag.inMilliseconds;
    final dragging =
        current < solution.length && local >= dragStart && local < dragEnd;
    final orientProgress = current < solution.length
        ? Curves.easeOutCubic.transform(
            (local / timing.preview.inMilliseconds).clamp(0.0, 1.0),
          )
        : 1.0;
    final dragProgress = dragging
        ? Curves.easeInOutCubic.transform(
            ((local - dragStart) / timing.drag.inMilliseconds).clamp(0, 1),
          )
        : 0.0;

    return ExcludeSemantics(
      child: Opacity(
        opacity: 1 - resetProgress,
        child: Transform.scale(
          scale: 1 + pulse * .018,
          child: SizedBox(
            width: sceneWidth,
            height: boardSize + rackGap + rackHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: boardLeft,
                  child: _DemoBoard(
                    solution: solution,
                    colorOf: colorOf,
                    cellSize: cellSize,
                    placedCount: current,
                    highlighted: current < solution.length
                        ? solution[current]
                        : null,
                    glow: pulse,
                  ),
                ),
                Positioned(
                  top: boardSize + rackGap,
                  child: _DemoRack(
                    solution: solution,
                    colorOf: colorOf,
                    width: sceneWidth,
                    height: rackHeight,
                    cellSize: cellSize * .30,
                    placedCount: current,
                    hideCurrent: dragging,
                    currentIndex: current,
                    orientProgress: orientProgress,
                    clockwise: current.isOdd,
                  ),
                ),
                if (dragging)
                  _movingPiece(
                    solution[current],
                    current,
                    sceneWidth,
                    boardLeft,
                    boardSize,
                    dragProgress,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _movingPiece(
    PlacedPiece piece,
    int index,
    double sceneWidth,
    double boardLeft,
    double boardSize,
    double progress,
  ) {
    final cells = _normalizedCells(piece);
    final width = cells.map((c) => c.$1).reduce(math.max) + 1;
    final height = cells.map((c) => c.$2).reduce(math.max) + 1;
    const startScale = .28;
    final slotWidth = sceneWidth / solution.length;
    final start = Offset(
      slotWidth * (index + .5) - width * cellSize * startScale / 2,
      boardSize +
          rackGap +
          toolbarHeight +
          (rackHeight - toolbarHeight) / 2 -
          height * cellSize * startScale / 2,
    );
    final end = Offset(
      boardLeft + piece.gridX * cellSize,
      piece.gridY * cellSize,
    );
    final position = Offset.lerp(start, end, progress)!;
    return Positioned(
      key: const ValueKey('home-moving-piece'),
      left: position.dx,
      top: position.dy,
      child: Transform.scale(
        alignment: Alignment.topLeft,
        scale: startScale + (1 - startScale) * progress,
        child: _DemoPiece(
          cells: cells,
          color: colorOf(piece.piece.id),
          cellSize: cellSize,
        ),
      ),
    );
  }
}

class _DemoBoard extends StatelessWidget {
  final List<PlacedPiece> solution;
  final Color Function(int pieceId) colorOf;
  final double cellSize;
  final int placedCount;
  final PlacedPiece? highlighted;
  final double glow;

  const _DemoBoard({
    required this.solution,
    required this.colorOf,
    required this.cellSize,
    required this.placedCount,
    required this.highlighted,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = <(int, int), Color>{};
    for (var i = 0; i < placedCount; i++) {
      for (final cell in solution[i].absoluteCells) {
        colors[(cell.x, cell.y)] = colorOf(solution[i].piece.id);
      }
    }
    final targets = {
      if (highlighted != null)
        for (final cell in highlighted!.absoluteCells) (cell.x, cell.y),
    };
    return Container(
      key: const ValueKey('home-board-frame'),
      width: cellSize * 5,
      height: cellSize * 5,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF52657D), width: 4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4D9DF7).withValues(alpha: .08 + glow * .18),
            blurRadius: 8 + glow * 12,
            spreadRadius: glow * 2,
          ),
        ],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 25,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemBuilder: (context, index) {
          final cell = (index % 5, index ~/ 5);
          return AnimatedContainer(
            key: ValueKey('home-board-${cell.$1}-${cell.$2}'),
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color:
                  colors[cell] ??
                  (targets.contains(cell)
                      ? const Color(0xFFD9E0E8)
                      : const Color(0xFFF3F5F8)),
              border: Border.all(color: const Color(0xFFD8DEE8), width: .65),
            ),
          );
        },
      ),
    );
  }
}

class _DemoRack extends StatelessWidget {
  final List<PlacedPiece> solution;
  final Color Function(int pieceId) colorOf;
  final double width;
  final double height;
  final double cellSize;
  final int placedCount;
  final bool hideCurrent;
  final int currentIndex;
  final double orientProgress;
  final bool clockwise;

  const _DemoRack({
    required this.solution,
    required this.colorOf,
    required this.width,
    required this.height,
    required this.cellSize,
    required this.placedCount,
    required this.hideCurrent,
    required this.currentIndex,
    required this.orientProgress,
    required this.clockwise,
  });

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('home-piece-rack'),
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFEEF2F7),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFD8DEE8)),
    ),
    child: Column(
      children: [
        SizedBox(
          height: _HomeGameScene.toolbarHeight,
          child: _DemoIsometryBar(clockwise: clockwise),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFD8DEE8)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                for (var index = 0; index < solution.length; index++)
                  Expanded(
                    child: Center(
                      child:
                          index < placedCount ||
                              (index == placedCount && hideCurrent)
                          ? const SizedBox.shrink()
                          : Transform.rotate(
                              key: ValueKey('home-rack-piece-$index'),
                              angle:
                                  _rackAngle(index) *
                                  (index == currentIndex
                                      ? 1 - orientProgress
                                      : 1),
                              child: _DemoPiece(
                                cells: _normalizedCells(solution[index]),
                                color: colorOf(solution[index].piece.id),
                                cellSize: cellSize,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _DemoIsometryBar extends StatelessWidget {
  final bool clockwise;

  const _DemoIsometryBar({required this.clockwise});

  @override
  Widget build(BuildContext context) {
    final actions = [
      GameIcons.isometryRotationTW,
      GameIcons.isometryRotationCW,
      GameIcons.isometrySymmetryH,
      GameIcons.isometrySymmetryV,
    ];
    return Row(
      key: const ValueKey('home-isometry-bar'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var index = 0; index < actions.length; index++)
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: index == (clockwise ? 1 : 0)
                  ? actions[index].color.withValues(alpha: .14)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              actions[index].icon,
              size: 34,
              color: actions[index].color,
            ),
          ),
      ],
    );
  }
}

double _rackAngle(int index) => (index.isEven ? 1 : -1) * math.pi / 2;

class _DemoPiece extends StatelessWidget {
  final List<(int, int)> cells;
  final Color color;
  final double cellSize;

  const _DemoPiece({
    required this.cells,
    required this.color,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final width = cells.map((c) => c.$1).reduce(math.max) + 1;
    final height = cells.map((c) => c.$2).reduce(math.max) + 1;
    return SizedBox(
      width: width * cellSize,
      height: height * cellSize,
      child: Stack(
        children: [
          for (final cell in cells)
            Positioned(
              left: cell.$1 * cellSize,
              top: cell.$2 * cellSize,
              child: Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Colors.white, width: .8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

List<(int, int)> _normalizedCells(PlacedPiece piece) {
  final absolute = piece.absoluteCells.toList(growable: false);
  final minX = absolute.map((c) => c.x).reduce(math.min);
  final minY = absolute.map((c) => c.y).reduce(math.min);
  return [for (final cell in absolute) (cell.x - minX, cell.y - minY)];
}

String _solutionSignature(List<PlacedPiece> solution) {
  final cells = <String>[];
  for (final piece in solution) {
    for (final cell in piece.absoluteCells) {
      cells.add('${cell.x},${cell.y}:${piece.piece.id}');
    }
  }
  cells.sort();
  return cells.join('|');
}
