// Modified: 2026-11-05 10:32 — retirer les doubles flèches et conserver les bandes de balayage.
// Historique: 2026-10-30 17:12 — remplacer le numéro de la consigne par la miniature de la cible.
// Historique: 2026-11-05 10:21 — guider le premier balayage par une bande dédiée avec double flèche.
// Historique: 2026-10-30 17:20 — montrer la miniature orientée dans la consigne Positionne.
// Historique: 2026-10-29 07:42 — répartir les cibles par cycles de onze pièces avant de choisir un pavage.
// Historique: 2026-10-29 07:39 — hachurer la silhouette manquante au lieu de la remplir en gris.
// Historique: 2026-10-29 07:35 — afficher la silhouette manquante en gris dès le début du Training.
// Historique: 2026-10-29 07:31 — compacter le tiroir et ses pièces, agrandir les quatre icônes.
// Historique: 2026-10-29 07:26 — adoucir le fond en bleu et confirmer la pose réussie par un impact tactile.
// Historique: 2026-10-28 08:05 — varier la découverte sur les 856 pavages 5×5 avec une seule pièce à poser.
// Historique: 2026-10-28 06:56 — mélanger les douze pièces et placer la cible entre les positions 7 et 12.
// Historique: 2026-10-28 06:49 — montrer douze pièces, agrandir Bravo et colorer Training à la réussite.
// Historique: 2026-10-28 06:35 — proposer les quatre isométries et guider vers la cible.
// Historique: 2026-10-28 05:27 — enchaîner les exercices sur demande sans terminer la découverte à la réussite.
// Historique: 2026-10-28 05:01 — découverte locale : chercher, sélectionner, tourner et poser une pièce.
// lib/pentoscope/home/discovery_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/home/home_tirages_data.dart'
    show HomeTirage, HomePiece;
import 'package:pentapol/pentoscope/home/discovery_boards_data.dart';
import 'package:pentapol/pentoscope/home/guided_home.dart'
    show shapeKey, orientationCells;

const double _discoveryRackCellRatio = .55;

enum DiscoveryPhase { browse, select, rotate, place, complete }

/// Un pavage vérifié, indépendant du moteur Solo et de sa sauvegarde.
class DiscoveryPuzzle {
  static const width = 5;
  static const height = 5;
  final int exerciseIndex;
  final math.Random _random;
  DiscoveryPuzzle({this.exerciseIndex = 0, math.Random? random})
    : _random = random ?? math.Random();

  static final _eligible = pentominos
      .where((p) => p.numOrientations > 1)
      .toList();
  static final _boardsByPiece = {
    for (final piece in _eligible)
      piece.id: [
        for (var i = 0; i < kDiscoveryBoards5x5.length; i++)
          if (kDiscoveryBoards5x5[i].contains(piece.id.toRadixString(16))) i,
      ],
  };

  late final Pento piece = _eligible[exerciseIndex % _eligible.length];
  late final HomeTirage solution = _decodeSolution();
  late final HomePiece target = solution.pieces.firstWhere(
    (p) => p.id == piece.id,
  );

  HomeTirage _decodeSolution() {
    final candidates = _boardsByPiece[piece.id]!;
    final index =
        candidates[(exerciseIndex ~/ _eligible.length) % candidates.length];
    final encoded = kDiscoveryBoards5x5[index];
    final cellsById = <int, List<List<int>>>{};
    for (var i = 0; i < encoded.length; i++) {
      final id = int.parse(encoded[i], radix: 16);
      (cellsById[id] ??= []).add([i % width, i ~/ width]);
    }
    return HomeTirage('5×5-$index', [
      for (final entry in cellsById.entries) HomePiece(entry.key, entry.value),
    ]);
  }

  int get orientation {
    final key = shapeKey(target.cells.map((c) => math.Point(c[0], c[1])));
    return List.generate(
      piece.numOrientations,
      (i) => i,
    ).firstWhere((i) => shapeKey(orientationCells(piece, i)) == key);
  }

  int get initialOrientation => piece.rotationTW(orientation);
  late final List<Pento> rack = _shuffleRack();

  List<Pento> _shuffleRack() {
    final pieces = pentominos.where((p) => p.id != piece.id).toList()
      ..shuffle(_random);
    // Index 6 à 11 : la cible ne figure jamais dans les six premières pièces.
    pieces.insert(6 + _random.nextInt(6), piece);
    return List.unmodifiable(pieces);
  }

  bool accepts({required int pieceId, required int position}) =>
      pieceId == piece.id &&
      shapeKey(orientationCells(piece, position)) ==
          shapeKey(target.cells.map((c) => math.Point(c[0], c[1])));
}

class DiscoveryScreen extends StatefulWidget {
  final Color Function(int) colorOf;
  final Duration longPressDuration;
  final bool enableHaptics;
  final int initialExerciseIndex;
  final ValueChanged<int>? onExerciseStarted;
  final Future<void> Function() onSkip;
  final Future<void> Function() onPlay;

  const DiscoveryScreen({
    super.key,
    required this.colorOf,
    this.enableHaptics = true,
    this.initialExerciseIndex = 0,
    this.onExerciseStarted,
    this.longPressDuration = const Duration(milliseconds: 100),
    required this.onSkip,
    required this.onPlay,
  });

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late int exerciseIndex = widget.initialExerciseIndex;
  late DiscoveryPuzzle puzzle = DiscoveryPuzzle(exerciseIndex: exerciseIndex);
  final rackController = ScrollController();
  final contentController = ScrollController();
  final targetKey = GlobalKey();
  final viewportKey = GlobalKey();
  final boardKey = GlobalKey();
  DiscoveryPhase phase = DiscoveryPhase.browse;
  late int position = puzzle.initialOrientation;
  bool leaving = false;
  bool hasSwipedRack = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onExerciseStarted?.call(exerciseIndex + 1);
    });
  }

  @override
  void dispose() {
    rackController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void nextExercise() {
    if (phase != DiscoveryPhase.complete || leaving) return;
    if (rackController.hasClients) rackController.jumpTo(0);
    if (contentController.hasClients) contentController.jumpTo(0);
    setState(() {
      exerciseIndex++;
      puzzle = DiscoveryPuzzle(exerciseIndex: exerciseIndex);
      position = puzzle.initialOrientation;
      phase = DiscoveryPhase.browse;
    });
    widget.onExerciseStarted?.call(exerciseIndex + 1);
  }

  void checkVisibleTarget() {
    if (phase != DiscoveryPhase.browse) return;
    final target = targetKey.currentContext?.findRenderObject() as RenderBox?;
    final viewport =
        viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (target == null || viewport == null) return;
    final targetRect = target.localToGlobal(Offset.zero) & target.size;
    final visibleRect = viewport.localToGlobal(Offset.zero) & viewport.size;
    if (targetRect.intersect(visibleRect).width >= target.size.width * .75) {
      setState(() => phase = DiscoveryPhase.select);
    }
  }

  void select(Pento piece) {
    if (piece.id != puzzle.piece.id ||
        phase.index > DiscoveryPhase.select.index) {
      return;
    }
    setState(() => phase = DiscoveryPhase.rotate);
  }

  void transform(int Function(int) operation) {
    if (phase != DiscoveryPhase.rotate && phase != DiscoveryPhase.place) return;
    setState(() {
      position = operation(position);
      phase = puzzle.accepts(pieceId: puzzle.piece.id, position: position)
          ? DiscoveryPhase.place
          : DiscoveryPhase.rotate;
    });
  }

  Widget buildTransformations(AppLocalizations l10n) {
    final actions = [
      (
        GameIcons.isometryRotationTW,
        'discovery-rotate-left',
        l10n.isoRotateTW,
        puzzle.piece.rotationTW,
      ),
      (
        GameIcons.isometryRotationCW,
        'discovery-rotate',
        l10n.isoRotateCW,
        puzzle.piece.rotationCW,
      ),
      (
        GameIcons.isometrySymmetryH,
        'discovery-mirror-horizontal',
        l10n.isoSymH,
        puzzle.piece.symmetryH,
      ),
      (
        GameIcons.isometrySymmetryV,
        'discovery-mirror-vertical',
        l10n.isoSymV,
        puzzle.piece.symmetryV,
      ),
    ];
    final enabled =
        phase == DiscoveryPhase.rotate || phase == DiscoveryPhase.place;
    final distance = puzzle.piece.minIsometriesToReach(
      position,
      puzzle.orientation,
    );
    final suggested = phase == DiscoveryPhase.rotate
        ? actions.indexWhere(
            (action) =>
                puzzle.piece.minIsometriesToReach(
                  action.$4(position),
                  puzzle.orientation,
                ) <
                distance,
          )
        : -1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < actions.length; i++)
          Container(
            decoration: BoxDecoration(
              color: i == suggested
                  ? actions[i].$1.color.withValues(alpha: .2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              key: ValueKey(actions[i].$2),
              onPressed: enabled ? () => transform(actions[i].$4) : null,
              tooltip: actions[i].$3,
              icon: Icon(actions[i].$1.icon),
              color: actions[i].$1.color,
              iconSize: 44,
              constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
            ),
          ),
      ],
    );
  }

  /// Une seule cible légale. La marge d'une case aide à viser sans accepter une
  /// autre pièce ni remplir une case déjà occupée.
  bool acceptsDrop(Offset globalCenter, double cell, int pieceId) {
    if (phase != DiscoveryPhase.place ||
        !puzzle.accepts(pieceId: pieceId, position: position)) {
      return false;
    }
    final box = boardKey.currentContext!.findRenderObject() as RenderBox;
    final local = box.globalToLocal(globalCenter);
    final cells = puzzle.target.cells;
    final left = cells.map((c) => c[0]).reduce(math.min) * cell;
    final top = cells.map((c) => c[1]).reduce(math.min) * cell;
    final right = (cells.map((c) => c[0]).reduce(math.max) + 1) * cell;
    final bottom = (cells.map((c) => c[1]).reduce(math.max) + 1) * cell;
    return Rect.fromLTRB(
      left,
      top,
      right,
      bottom,
    ).inflate(cell).contains(local);
  }

  Future<void> leave(Future<void> Function() action) async {
    if (leaving) return;
    setState(() => leaving = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => leaving = false);
    }
  }

  String message(AppLocalizations l10n) => switch (phase) {
    DiscoveryPhase.browse => l10n.discoveryBrowse,
    DiscoveryPhase.select => l10n.discoverySelect,
    DiscoveryPhase.rotate => l10n.discoveryRotate,
    DiscoveryPhase.place => l10n.discoveryPlace,
    DiscoveryPhase.complete => l10n.discoveryDone,
  };

  Widget buildMessage(AppLocalizations l10n, double boardCell) {
    final selecting =
        phase == DiscoveryPhase.browse || phase == DiscoveryPhase.select;
    final textScale = MediaQuery.textScalerOf(context).scale(20) / 20;
    final orienting = phase == DiscoveryPhase.rotate;
    if (selecting || orienting) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${message(l10n)} '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: SizedBox(
                width: 50 * textScale,
                height: 34 * textScale,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: PieceRenderer(
                    key: const ValueKey('discovery-target-thumbnail'),
                    piece: puzzle.piece,
                    positionIndex: orienting
                        ? puzzle.orientation
                        : puzzle.initialOrientation,
                    getPieceColor: widget.colorOf,
                    cellSize: boardCell * .30,
                    showLabel: false,
                  ),
                ),
              ),
            ),
            if (orienting) TextSpan(text: '\n${l10n.discoveryUsingIcons}'),
          ],
        ),
        key: const ValueKey('discovery-message'),
        semanticsLabel:
            '${message(l10n)} ${l10n.guidedPiece(puzzle.piece.id)}'
            '${orienting ? '\n${l10n.discoveryUsingIcons}' : ''}',
        textAlign: TextAlign.center,
        maxLines: 2,
        style: const TextStyle(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    Widget text(double size) => Text(
      message(l10n),
      key: const ValueKey('discovery-message'),
      textAlign: TextAlign.center,
      maxLines: 2,
      style: TextStyle(
        fontSize: size,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    );
    if (phase != DiscoveryPhase.complete) return text(20);
    return TweenAnimationBuilder<double>(
      key: const ValueKey('discovery-bravo-growth'),
      tween: Tween(begin: 20, end: 34),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, size, _) => text(size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leave(widget.onSkip);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF3FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFEAF3FC),
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(l10n.appTitle),
          actions: [
            TextButton(
              key: const ValueKey('discovery-skip'),
              onPressed: leaving ? null : () => leave(widget.onSkip),
              child: Text(l10n.discoverySkip),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final landscape = bounds.maxWidth > bounds.maxHeight;
              // Le texte garde sa taille et sa place ; seule la géométrie du jeu
              // s'adapte à l'espace restant, avec défilement vertical si nécessaire.
              final textScale = MediaQuery.textScalerOf(context).scale(20) / 20;
              final messageHeight = 68.0 * textScale;
              final available = math.max(
                220.0,
                bounds.maxHeight - messageHeight - 28,
              );
              final cell = math
                  .min(
                    landscape
                        ? math.min(
                            (available - 16) / 5,
                            (available - 148) / 3.25,
                          )
                        : (available - 168) / 8,
                    landscape
                        ? bounds.maxWidth * .40 / DiscoveryPuzzle.width
                        : (bounds.maxWidth - 32) / 5,
                  )
                  .clamp(22.0, 72.0);
              final rackCell = cell * _discoveryRackCellRatio;
              final board = buildBoard(cell);
              final controls = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTransformations(l10n),
                  buildSwipeStrip(l10n, rackCell),
                  buildRack(rackCell),
                  const SizedBox(height: 12),
                  if (phase == DiscoveryPhase.complete)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton(
                          key: const ValueKey('discovery-next'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF8E24AA),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: leaving ? null : nextExercise,
                          child: Text(l10n.discoveryAgain),
                        ),
                        FilledButton(
                          key: const ValueKey('discovery-play'),
                          onPressed: leaving
                              ? null
                              : () => leave(widget.onPlay),
                          child: Text(l10n.discoveryPlay),
                        ),
                      ],
                    ),
                ],
              );
              return Column(
                children: [
                  SizedBox(
                    height: messageHeight,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: buildMessage(l10n, cell),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: contentController,
                      padding: const EdgeInsets.all(12),
                      child: landscape
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                board,
                                const SizedBox(width: 20),
                                Expanded(child: controls),
                              ],
                            )
                          : Column(
                              children: [
                                board,
                                const SizedBox(height: 12),
                                controls,
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildBoard(double cell) => DragTarget<int>(
    onWillAcceptWithDetails: (details) =>
        phase == DiscoveryPhase.place && details.data == puzzle.piece.id,
    onAcceptWithDetails: (details) {
      // Avec l’ancre centrée ci-dessous, offset est le coin du feedback.
      final cells = orientationCells(puzzle.piece, position);
      final width =
          (cells.map((c) => c.x).reduce(math.max) -
                  cells.map((c) => c.x).reduce(math.min) +
                  1) *
              cell +
          8;
      final height =
          (cells.map((c) => c.y).reduce(math.max) -
                  cells.map((c) => c.y).reduce(math.min) +
                  1) *
              cell +
          8;
      if (!acceptsDrop(
        details.offset + Offset(width / 2, height / 2),
        cell,
        details.data,
      )) {
        return;
      }
      setState(() => phase = DiscoveryPhase.complete);
      if (widget.enableHaptics) {
        HapticFeedback.mediumImpact();
      }
    },
    builder: (context, candidates, rejected) => SizedBox(
      key: boardKey,
      width: cell * DiscoveryPuzzle.width,
      height: cell * DiscoveryPuzzle.height,
      child: Stack(
        key: const ValueKey('discovery-board'),
        children: [
          for (var y = 0; y < DiscoveryPuzzle.height; y++)
            for (var x = 0; x < DiscoveryPuzzle.width; x++)
              Positioned(
                left: x * cell,
                top: y * cell,
                width: cell,
                height: cell,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blueGrey.shade200),
                  ),
                ),
              ),
          if (phase != DiscoveryPhase.complete)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  key: const ValueKey('discovery-hatching'),
                  painter: _DiscoveryHatchPainter(puzzle.target.cells),
                ),
              ),
            ),
          for (final placed in puzzle.solution.pieces)
            if (placed.id != puzzle.piece.id ||
                phase == DiscoveryPhase.complete)
              for (final square in placed.cells)
                Positioned(
                  left: square[0] * cell,
                  top: square[1] * cell,
                  width: cell,
                  height: cell,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.colorOf(placed.id),
                      border: Border.all(color: Colors.white70),
                    ),
                  ),
                ),
          if (phase == DiscoveryPhase.place)
            for (final square in puzzle.target.cells)
              Positioned(
                left: square[0] * cell,
                top: square[1] * cell,
                width: cell,
                height: cell,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                ),
              ),
        ],
      ),
    ),
  );

  void scrollRackFromStrip(double delta) {
    if (!rackController.hasClients ||
        leaving ||
        phase == DiscoveryPhase.complete) {
      return;
    }
    final scroll = rackController.position;
    final offset = (scroll.pixels - delta).clamp(
      scroll.minScrollExtent,
      scroll.maxScrollExtent,
    );
    if (offset == scroll.pixels) return;
    if (!hasSwipedRack) setState(() => hasSwipedRack = true);
    rackController.jumpTo(offset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkVisibleTarget();
    });
  }

  Widget buildSwipeStrip(AppLocalizations l10n, double cell) {
    if (phase == DiscoveryPhase.complete) return const SizedBox(height: 8);
    final showHint =
        !hasSwipedRack && exerciseIndex == widget.initialExerciseIndex;
    return Semantics(
      label: l10n.discoverySwipeHere,
      child: GestureDetector(
        key: const ValueKey('discovery-swipe-strip'),
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) =>
            scrollRackFromStrip(details.delta.dx),
        child: SizedBox(
          width: cell / _discoveryRackCellRatio * 5,
          height: 56 * (MediaQuery.textScalerOf(context).scale(14) / 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showHint)
                Text(
                  l10n.discoverySwipeHere,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: Color(0xFF476484),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRack(double cell) => NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification is ScrollUpdateNotification &&
          notification.dragDetails != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!hasSwipedRack) setState(() => hasSwipedRack = true);
          checkVisibleTarget();
        });
      }
      return false;
    },
    child: Container(
      key: viewportKey,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFDDEAF7),
        borderRadius: BorderRadius.circular(16),
      ),
      width: cell / _discoveryRackCellRatio * 5,
      height: cell * 5 + 16,
      child: ListView(
        key: const ValueKey('discovery-rack'),
        controller: rackController,
        scrollDirection: Axis.horizontal,
        children: [
          for (final piece in puzzle.rack)
            if (piece.id != puzzle.piece.id || phase != DiscoveryPhase.complete)
              buildRackPiece(piece, cell),
        ],
      ),
    ),
  );

  Widget buildRackPiece(Pento piece, double cell) {
    final target = piece.id == puzzle.piece.id;
    final selected = target && phase.index >= DiscoveryPhase.rotate.index;
    final renderer = PieceRenderer(
      piece: piece,
      positionIndex: target ? position : 0,
      getPieceColor: widget.colorOf,
      cellSize: cell,
    );
    final tile = Semantics(
      label: AppLocalizations.of(context).guidedPiece(piece.id),
      button: true,
      selected: selected,
      child: GestureDetector(
        key: ValueKey('discovery-piece-${piece.id}'),
        onTap: () => select(piece),
        child: Container(
          key: target ? targetKey : null,
          width: cell * 5 + 16,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.blue.shade50 : Colors.white,
            border: Border.all(
              color: target && phase != DiscoveryPhase.browse
                  ? Colors.blue
                  : Colors.blueGrey.shade100,
              width: selected ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: renderer,
        ),
      ),
    );
    if (!selected || phase != DiscoveryPhase.place) return tile;
    // Même échelle de cellules pendant le drag que sur le plateau.
    return LongPressDraggable<int>(
      data: piece.id,
      delay: widget.longPressDuration,
      hapticFeedbackOnStart: false,
      dragAnchorStrategy: (_, _, _) {
        final cells = orientationCells(piece, position);
        return Offset(
          (cells.map((p) => p.x).reduce(math.max) -
                      cells.map((p) => p.x).reduce(math.min) +
                      1) *
                  cell /
                  _discoveryRackCellRatio /
                  2 +
              4,
          (cells.map((p) => p.y).reduce(math.max) -
                      cells.map((p) => p.y).reduce(math.min) +
                      1) *
                  cell /
                  _discoveryRackCellRatio /
                  2 +
              4,
        );
      },
      feedback: Material(
        color: Colors.transparent,
        child: PieceRenderer(
          piece: piece,
          positionIndex: position,
          getPieceColor: widget.colorOf,
          cellSize: cell / _discoveryRackCellRatio,
          isDragging: true,
        ),
      ),
      childWhenDragging: Opacity(opacity: .25, child: tile),
      child: tile,
    );
  }
}

/// Hachures continues, découpées exactement sur les cinq cases de la cible.
class _DiscoveryHatchPainter extends CustomPainter {
  final List<List<int>> cells;
  const _DiscoveryHatchPainter(this.cells);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / DiscoveryPuzzle.width;
    final silhouette = Path();
    for (final square in cells) {
      silhouette.addRect(
        Rect.fromLTWH(square[0] * cell, square[1] * cell, cell, cell),
      );
    }
    final pen = Paint()
      ..color = const Color(0xFF7890A6)
      ..strokeWidth = 1.2;
    canvas.save();
    canvas.clipPath(silhouette);
    for (var x = -size.height; x < size.width + size.height; x += cell / 4) {
      canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), pen);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiscoveryHatchPainter oldDelegate) =>
      oldDelegate.cells != cells;
}
