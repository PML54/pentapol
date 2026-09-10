// Modified: 2026-09-10 15:08 — accueil : déposer la bonne forme sur la silhouette sans viser la case saisie.
// Historique: 2026-09-10 14:53 — finaliser accueil guidé : feedback visible, validation géométrique, reprise et progression EN/FR.
// Historique: 2026-09-10 10:24 — trois gestes guidés sur un pavage réel, état local sans score ni persistance.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/home/home_tirages_data.dart';

String shapeKey(Iterable<math.Point<int>> cells) {
  final points = cells.toList();
  final x = points.map((p) => p.x).reduce(math.min);
  final y = points.map((p) => p.y).reduce(math.min);
  final keys = points.map((p) => '${p.x - x},${p.y - y}').toList()..sort();
  return keys.join(';');
}

List<math.Point<int>> orientationCells(Pento piece, int index) => piece
    .orientations[index]
    .map((n) => math.Point((n - 1) % 5, (n - 1) ~/ 5))
    .toList();

int transformedOrientation(Pento piece, int index, {bool mirror = false}) {
  return mirror ? piece.symmetryV(index) : piece.rotationCW(index);
}

/// U : pose ; P : rotation ; F : miroir (sa chiralité impose un retournement).
class GuidedStep {
  final HomePiece target;
  final Pento piece;
  final int targetOrientation;
  final int initialOrientation;
  GuidedStep(
    this.target,
    this.piece,
    this.targetOrientation,
    this.initialOrientation,
  );
}

List<GuidedStep> guidedSteps() {
  final solution = kHomeTirages.first;
  return [7, 2, 4].asMap().entries.map((entry) {
    final target = solution.pieces.firstWhere((p) => p.id == entry.value);
    final piece = pentominos.firstWhere((p) => p.id == target.id);
    final key = shapeKey(target.cells.map((c) => math.Point(c[0], c[1])));
    final orientation = piece.orientations.indexWhere(
      (o) =>
          shapeKey(o.map((n) => math.Point((n - 1) % 5, (n - 1) ~/ 5))) == key,
    );
    if (orientation < 0) throw StateError('Missing guided orientation');
    var start = orientation;
    if (entry.key == 1) {
      for (var i = 0; i < 3; i++) {
        start = transformedOrientation(piece, start);
      }
    } else if (entry.key == 2) {
      start = transformedOrientation(piece, start, mirror: true);
    }
    return GuidedStep(target, piece, orientation, start);
  }).toList();
}

class GuidedHome extends StatefulWidget {
  final Color Function(int) colorOf;
  final double ratio;
  final VoidCallback onPlay;
  final Duration longPressDuration;
  const GuidedHome({
    super.key,
    required this.colorOf,
    required this.ratio,
    required this.onPlay,
    this.longPressDuration = const Duration(milliseconds: 100),
  });
  @override
  State<GuidedHome> createState() => _GuidedHomeState();
}

class _GuidedHomeState extends State<GuidedHome> {
  final steps = guidedSteps();
  final boardKey = GlobalKey();
  final dragVisual = ValueNotifier<(bool, Offset)>((false, Offset.zero));

  @override
  void dispose() {
    dragVisual.dispose();
    super.dispose();
  }

  void updateHover(bool valid) {
    dragVisual.value = (valid, dragVisual.value.$2);
    if (valid != validHover) setState(() => validHover = valid);
  }

  void restart() {
    updateHover(false);
    setState(() {
      step = 0;
      orientation = steps.first.initialOrientation;
    });
  }

  bool get shapeReady =>
      !complete &&
      shapeKey(orientationCells(steps[step].piece, orientation)) ==
          shapeKey(steps[step].target.cells.map((c) => math.Point(c[0], c[1])));

  int step = 0;
  late int orientation = steps.first.initialOrientation;
  math.Point<int> grab = const math.Point(0, 0);
  bool validHover = false;
  bool get complete => step == steps.length;

  bool accepts(Offset position, double cell) {
    if (!shapeReady) return false;
    final box = boardKey.currentContext!.findRenderObject() as RenderBox;
    final local = box.globalToLocal(position);
    final target = steps[step].target.cells;
    final minX = target.map((p) => p[0]).reduce(math.min);
    final minY = target.map((p) => p[1]).reduce(math.min);
    final maxX = target.map((p) => p[0]).reduce(math.max);
    final maxY = target.map((p) => p[1]).reduce(math.max);
    // Accueil guidé : le geste vise la silhouette entière, pas la case saisie dans
    // la miniature. Une petite tolérance au bord aide sans autoriser un dépôt hors plateau.
    final targetArea = Rect.fromLTRB(
      minX * cell,
      minY * cell,
      (maxX + 1) * cell,
      (maxY + 1) * cell,
    ).inflate(cell * .25);
    return (Offset.zero & box.size).contains(local) &&
        targetArea.contains(local);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = complete
        ? l10n.guidedDone
        : step > 0 && shapeReady
        ? l10n.guidedReady
        : [l10n.guidedPlace, l10n.guidedRotate, l10n.guidedMirror][step];
    return LayoutBuilder(
      builder: (context, bounds) {
        final landscape = bounds.maxWidth > bounds.maxHeight;
        final contentWidth = bounds.maxWidth - 24;
        final contentHeight = bounds.maxHeight - 24;
        final controlsWidth = landscape ? bounds.maxWidth * .48 : contentWidth;
        double textHeight(String text, TextStyle style) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: controlsWidth);
          final height = painter.height;
          painter.dispose();
          return height;
        }

        final messageHeight =
            [
                  l10n.guidedPlace,
                  l10n.guidedRotate,
                  l10n.guidedMirror,
                  l10n.guidedReady,
                  l10n.guidedDone,
                ]
                .map(
                  (text) => textHeight(
                    text,
                    Theme.of(context).textTheme.titleMedium!,
                  ),
                )
                .reduce(math.max);
        final stepHeight = textHeight(
          l10n.guidedStep(3),
          DefaultTextStyle.of(
            context,
          ).style.copyWith(fontWeight: FontWeight.bold),
        );
        // Texte + commandes + marges du rack réservés ; aucune étape ne déplace le plateau.
        final fixedHeight = stepHeight + messageHeight + 4 + 8 + 48 + 16;
        final cell = math.max(
          1.0,
          math.min(
            landscape
                ? (contentWidth - controlsWidth - 24) / 3
                : contentWidth / 3,
            landscape
                ? math.min(
                    contentHeight / 5,
                    (contentHeight - fixedHeight) / (4 * widget.ratio),
                  )
                : (contentHeight - fixedHeight) / (5 + 4 * widget.ratio),
          ),
        );
        final rackCell = cell * widget.ratio;
        final board = SizedBox(
          key: boardKey,
          width: 3 * cell,
          height: 5 * cell,
          child: DragTarget<int>(
            onWillAcceptWithDetails: (d) => !complete && d.data == step,
            onMove: (d) => updateHover(accepts(d.offset, cell)),
            onLeave: (_) => updateHover(false),
            onAcceptWithDetails: (d) {
              if (!accepts(d.offset, cell)) return;
              updateHover(false);
              setState(() {
                step++;
                validHover = false;
                if (!complete) orientation = steps[step].initialOrientation;
              });
            },
            builder: (context, candidates, rejected) => Stack(
              children: [
                for (var y = 0; y < 5; y++)
                  for (var x = 0; x < 3; x++)
                    Positioned(
                      left: x * cell,
                      top: y * cell,
                      width: cell,
                      height: cell,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: .5,
                          ),
                        ),
                      ),
                    ),
                for (var i = 0; i < steps.length; i++)
                  if (i <= step)
                    for (final c in steps[i].target.cells)
                      Positioned(
                        left: c[0] * cell,
                        top: c[1] * cell,
                        width: cell,
                        height: cell,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: widget
                                .colorOf(steps[i].piece.id)
                                .withValues(
                                  alpha: i < step
                                      ? 1
                                      : validHover
                                      ? .65
                                      : .2,
                                ),
                            border: Border.all(
                              color: i < step
                                  ? Colors.white54
                                  : widget.colorOf(steps[i].piece.id),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
        final controls = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: stepHeight,
              child: complete
                  ? null
                  : Text(
                      l10n.guidedStep(step + 1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: messageHeight,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: complete
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: restart,
                          child: Text(l10n.guidedAgain),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: widget.onPlay,
                          child: Text(l10n.play),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          key: const ValueKey('guided-rotate'),
                          iconSize: 34,
                          tooltip: l10n.guidedRotateAction,
                          icon: const Icon(Icons.rotate_right),
                          onPressed: step == 1
                              ? () => setState(() {
                                  orientation = transformedOrientation(
                                    steps[step].piece,
                                    orientation,
                                  );
                                })
                              : null,
                        ),
                        IconButton(
                          key: const ValueKey('guided-mirror'),
                          iconSize: 34,
                          tooltip: l10n.guidedMirrorAction,
                          icon: const Icon(Icons.flip),
                          onPressed: step == 2
                              ? () => setState(() {
                                  orientation = transformedOrientation(
                                    steps[step].piece,
                                    orientation,
                                    mirror: true,
                                  );
                                })
                              : null,
                        ),
                      ],
                    ),
            ),
            SizedBox(
              height: rackCell * 4 + 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(steps.length, (i) {
                  final current = steps[i];
                  final index = i == step
                      ? orientation
                      : current.initialOrientation;
                  final renderer = PieceRenderer(
                    piece: current.piece,
                    positionIndex: index,
                    cellSize: rackCell,
                    getPieceColor: widget.colorOf,
                  );
                  if (i < step) {
                    return Icon(
                      Icons.check_circle,
                      color: widget.colorOf(current.piece.id),
                      size: rackCell * 2,
                    );
                  }
                  if (i != step) return Opacity(opacity: .4, child: renderer);
                  return LongPressDraggable<int>(
                    key: ValueKey('guided-piece-$i'),
                    data: i,
                    delay: widget.longPressDuration,
                    dragAnchorStrategy: (drag, ctx, pos) {
                      final box = ctx.findRenderObject() as RenderBox;
                      final local = box.globalToLocal(pos);
                      grab = math.Point(
                        ((local.dx - 4) / rackCell).floor(),
                        ((local.dy - 4) / rackCell).floor(),
                      );
                      dragVisual.value = (
                        false,
                        Offset(-grab.x * rackCell - 4, -grab.y * rackCell - 4),
                      );
                      return Offset.zero;
                    },
                    onDragEnd: (_) => updateHover(false),
                    feedback: Material(
                      color: Colors.transparent,
                      child: ValueListenableBuilder<(bool, Offset)>(
                        valueListenable: dragVisual,
                        builder: (context, visual, _) => Transform.translate(
                          offset: visual.$2,
                          child: PieceRenderer(
                            piece: current.piece,
                            positionIndex: index,
                            cellSize: rackCell,
                            getPieceColor: widget.colorOf,
                            isDragging: true,
                            invalidPlacement: !visual.$1,
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(opacity: .25, child: renderer),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: renderer,
                    ),
                  );
                }),
              ),
            ),
          ],
        );
        return Padding(
          padding: const EdgeInsets.all(12),
          child: landscape
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    board,
                    SizedBox(width: bounds.maxWidth * .48, child: controls),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [board, controls],
                ),
        );
      },
    );
  }
}
