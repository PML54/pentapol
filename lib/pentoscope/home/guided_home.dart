// Modified: 2026-09-12 06:30 — retours haptiques de sélection, prise, transformation, cible et pose, réglables.
// Historique: 2026-09-12 03:40 — consignes agrandies et défilantes, réserve fixe pour préserver le plateau.
// Historique: 2026-09-11 16:11 — bouton Training plein pour le prochain parcours ; Jouer déplacé dans l’en-tête.
// Historique: 2026-09-11 07:57 — sept accueils 3×5 et orientations initiales toujours différentes de la cible.
// Historique: 2026-09-11 07:33 — accueil : rack défilant, sélection numérotée, quatre isométries du jeu et encouragements.
// Historique: 2026-09-10 15:08 — accueil : déposer la bonne forme sur la silhouette sans viser la case saisie.
// Historique: 2026-09-10 14:53 — finaliser accueil guidé : feedback visible, validation géométrique, reprise et progression EN/FR.
// Historique: 2026-09-10 10:24 — trois gestes guidés sur un pavage réel, état local sans score ni persistance.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/pentapol_rng.dart';
import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/home/home_tirages_data.dart';
import 'package:pentapol/pentoscope/home/guided_success_celebration.dart';
import 'package:pentapol/pentoscope/home/guided_scrolling_message.dart';

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

/// Vrai si les seules rotations ne permettent pas d'atteindre l'orientation cible.
bool needsGuidedMirror(Pento piece, int from, int target) {
  var current = from;
  for (var i = 0; i < 4; i++) {
    if (current == target) return false;
    current = piece.rotationCW(current);
  }
  return true;
}

/// Une pièce du parcours : rotation d'abord, miroir nécessaire en dernier.
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

List<GuidedStep> guidedSteps({int tirageIndex = 0}) {
  final solution = kHomeTirages[tirageIndex];
  final targets = solution.pieces.map((target) {
    final piece = pentominos.firstWhere((p) => p.id == target.id);
    final key = shapeKey(target.cells.map((c) => math.Point(c[0], c[1])));
    final orientation = piece.orientations.indexWhere(
      (o) =>
          shapeKey(o.map((n) => math.Point((n - 1) % 5, (n - 1) ~/ 5))) == key,
    );
    if (orientation < 0) throw StateError('Missing guided orientation');
    return GuidedStep(
      target,
      piece,
      orientation,
      piece.rotationTW(orientation),
    );
  }).toList();
  // Les sept tirages contiennent une pièce chirale : la garder pour apprendre le miroir.
  final mirror = targets.lastWhere(
    (s) => needsGuidedMirror(
      s.piece,
      s.piece.symmetryV(s.targetOrientation),
      s.targetOrientation,
    ),
  );
  targets.remove(mirror);
  targets.sort((a, b) {
    final order = a.piece.numOrientations.compareTo(b.piece.numOrientations);
    return order == 0 ? a.piece.id.compareTo(b.piece.id) : order;
  });
  targets.add(
    GuidedStep(
      mirror.target,
      mirror.piece,
      mirror.targetOrientation,
      mirror.piece.symmetryV(mirror.targetOrientation),
    ),
  );
  // Comparer les formes, y compris pour les pièces ayant des symétries propres.
  if (targets.any(
    (s) =>
        shapeKey(orientationCells(s.piece, s.initialOrientation)) ==
        shapeKey(orientationCells(s.piece, s.targetOrientation)),
  )) {
    throw StateError('A guided piece already matches its target');
  }
  return targets;
}

class GuidedHome extends StatefulWidget {
  final Color Function(int) colorOf;
  final double ratio;
  final Duration longPressDuration;
  final bool enableHaptics;

  /// Départ reproductible pour prévisualisations/tests ; sinon tirage choisi au montage.
  final int? initialTirageIndex;
  const GuidedHome({
    super.key,
    required this.colorOf,
    required this.ratio,
    this.enableHaptics = true,
    this.longPressDuration = const Duration(milliseconds: 100),
    this.initialTirageIndex,
  });
  @override
  State<GuidedHome> createState() => _GuidedHomeState();
}

class _GuidedHomeState extends State<GuidedHome> {
  late int tirageIndex =
      widget.initialTirageIndex ??
      PentapolRng(
        DateTime.now().microsecondsSinceEpoch,
      ).nextInt(kHomeTirages.length);
  late List<GuidedStep> steps = guidedSteps(tirageIndex: tirageIndex);
  final boardKey = GlobalKey();
  final rackController = ScrollController();
  final dragVisual = ValueNotifier<(bool, Offset)>((false, Offset.zero));
  late List<int> orientations = steps.map((s) => s.initialOrientation).toList();
  int step = 0;
  int? selected;
  bool browsed = false;
  bool validHover = false;
  bool retry = false;
  bool get complete => step == steps.length;
  bool get shapeReady =>
      !complete &&
      selected == step &&
      shapeKey(orientationCells(steps[step].piece, orientations[step])) ==
          shapeKey(steps[step].target.cells.map((c) => math.Point(c[0], c[1])));

  @override
  void dispose() {
    rackController.dispose();
    dragVisual.dispose();
    super.dispose();
  }

  void updateHover(bool valid) {
    if (valid && !validHover && widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
    dragVisual.value = (valid, dragVisual.value.$2);
    if (valid != validHover) setState(() => validHover = valid);
  }

  void select(int index) {
    updateHover(false);
    setState(() {
      browsed = true;
      selected = index;
      retry = false;
    });
  }

  void transform(int Function(Pento, int) operation) {
    if (selected == null) return;
    if (widget.enableHaptics) HapticFeedback.selectionClick();
    updateHover(false);
    setState(() {
      final i = selected!;
      orientations[i] = operation(steps[i].piece, orientations[i]);
      retry = false;
    });
  }

  void nextTraining() {
    updateHover(false);
    setState(() {
      step = 0;
      selected = null;
      browsed = false;
      retry = false;
      // Parcourir les sept configurations sans répétition avant le tour suivant.
      tirageIndex = (tirageIndex + 1) % kHomeTirages.length;
      steps = guidedSteps(tirageIndex: tirageIndex);
      orientations = steps.map((s) => s.initialOrientation).toList();
    });
    if (rackController.hasClients) rackController.jumpTo(0);
  }

  bool accepts(Offset position, double cell) {
    if (!shapeReady) return false;
    final box = boardKey.currentContext!.findRenderObject() as RenderBox;
    final local = box.globalToLocal(position);
    final target = steps[step].target.cells;
    final targetArea = Rect.fromLTRB(
      target.map((p) => p[0]).reduce(math.min) * cell,
      target.map((p) => p[1]).reduce(math.min) * cell,
      (target.map((p) => p[0]).reduce(math.max) + 1) * cell,
      (target.map((p) => p[1]).reduce(math.max) + 1) * cell,
    ).inflate(cell * .25);
    return (Offset.zero & box.size).contains(local) &&
        targetArea.contains(local);
  }

  String message(AppLocalizations l10n) {
    if (complete) return l10n.guidedDone;
    if (!browsed) return l10n.guidedBrowse;
    final id = steps[step].piece.id;
    if (selected != null && selected != step) return l10n.guidedChoose(id);
    if (selected == null) {
      return step == 0 ? l10n.guidedChoose(id) : l10n.guidedNext(id);
    }
    if (retry) return l10n.guidedRetry;
    if (shapeReady) return l10n.guidedReady;
    return needsGuidedMirror(
          steps[step].piece,
          orientations[step],
          steps[step].targetOrientation,
        )
        ? l10n.guidedMirror
        : l10n.guidedRotate;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, bounds) {
        final landscape = bounds.maxWidth > bounds.maxHeight;
        final contentWidth = bounds.maxWidth - 24;
        final contentHeight = bounds.maxHeight - 24;
        final controlsWidth = landscape ? bounds.maxWidth * .48 : contentWidth;
        final textStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
          fontSize: (controlsWidth * .06).clamp(22.0, 28.0),
          fontWeight: FontWeight.w700,
          height: 1.3,
        );
        double textHeight(String text) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: textStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: controlsWidth);
          final height = painter.height;
          painter.dispose();
          return height;
        }

        // Réserve identique pour toutes les consignes : le plateau ne saute pas.
        final messageHeight = [
          l10n.guidedBrowse,
          l10n.guidedRotate,
          l10n.guidedMirror,
          l10n.guidedReady,
          l10n.guidedRetry,
          l10n.guidedDone,
          for (final s in steps) ...[
            l10n.guidedChoose(s.piece.id),
            l10n.guidedNext(s.piece.id),
          ],
        ].map(textHeight).reduce(math.max);
        // Même taille et mêmes configurations d'icônes que le jeu.
        final iconSize = isometryIconSize(context);
        final actionsHeight = iconSize + 14;
        final fixedHeight = messageHeight + 8 + actionsHeight + 16;
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
        final rackHeight = rackCell * 4 + 16;
        final board = SizedBox(
          key: boardKey,
          width: 3 * cell,
          height: 5 * cell,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DragTarget<int>(
                    onWillAcceptWithDetails: (d) => !complete && d.data == step,
                    onMove: (d) =>
                        updateHover(d.data == step && accepts(d.offset, cell)),
                    onLeave: (_) => updateHover(false),
                    onAcceptWithDetails: (d) {
                      if (d.data != step || !accepts(d.offset, cell)) return;
                      if (widget.enableHaptics) HapticFeedback.mediumImpact();
                      updateHover(false);
                      setState(() {
                        step++;
                        selected = null;
                        retry = false;
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
                          if (i < step || (i == step && selected == step))
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
                  // Peindre le contour au-dessus des cases, sans padding ni changement de repère.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: const ValueKey('guided-board-frame'),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade700,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  if (step > 0)
                    Positioned.fill(
                      child: GuidedSuccessCelebration(
                        key: ValueKey('guided-success-$tirageIndex-$step'),
                        complete: complete,
                        origin: complete
                            ? const Offset(.5, .5)
                            : Offset(
                                steps[step - 1].target.cells
                                        .map((c) => c[0] + .5)
                                        .reduce((a, b) => a + b) /
                                    15,
                                steps[step - 1].target.cells
                                        .map((c) => c[1] + .5)
                                        .reduce((a, b) => a + b) /
                                    25,
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        final configs = [
          GameIcons.isometryRotationTW,
          GameIcons.isometryRotationCW,
          GameIcons.isometrySymmetryH,
          GameIcons.isometrySymmetryV,
        ];
        final tooltips = [
          l10n.isoRotateTW,
          l10n.isoRotateCW,
          l10n.isoSymH,
          l10n.isoSymV,
        ];
        final operations = <int Function(Pento, int)>[
          (p, o) => p.rotationTW(o),
          (p, o) => p.rotationCW(o),
          (p, o) => p.symmetryH(o),
          (p, o) => p.symmetryV(o),
        ];
        final actionKeys = [
          'guided-rotate-left',
          'guided-rotate',
          'guided-mirror-horizontal',
          'guided-mirror',
        ];
        final controls = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: messageHeight,
              child: GuidedScrollingMessage(
                message: message(l10n),
                style: textStyle,
                width: controlsWidth,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: actionsHeight,
              child: complete
                  ? Center(
                      child: FilledButton(
                        onPressed: nextTraining,
                        child: Text(l10n.guidedAnother),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var i = 0; i < configs.length; i++)
                          IconButton(
                            key: ValueKey(actionKeys[i]),
                            iconSize: iconSize,
                            padding: EdgeInsets.zero,
                            tooltip: tooltips[i],
                            color: configs[i].color,
                            icon: Icon(configs[i].icon),
                            onPressed: selected == null
                                ? null
                                : () => transform(operations[i]),
                          ),
                      ],
                    ),
            ),
            SizedBox(
              height: rackHeight,
              child: complete
                  ? null
                  : NotificationListener<ScrollUpdateNotification>(
                      onNotification: (n) {
                        // Une vraie exploration du rack précède le choix ; pas un défilement programmatique.
                        if (!browsed &&
                            n.dragDetails != null &&
                            n.metrics.pixels.abs() > 12) {
                          setState(() => browsed = true);
                        }
                        return false;
                      },
                      child: Scrollbar(
                        controller: rackController,
                        thumbVisibility: true,
                        child: ListView(
                          key: const ValueKey('guided-rack'),
                          controller: rackController,
                          scrollDirection: landscape
                              ? Axis.vertical
                              : Axis.horizontal,
                          itemExtent: landscape
                              ? rackHeight
                              : math.max(rackHeight, controlsWidth * .62),
                          children: [
                            // La première pièce demandée est au bout : on apprend réellement à défiler.
                            for (final i in [1, 2, 0])
                              if (i >= step)
                                Center(
                                  key: ValueKey('guided-slot-$i'),
                                  child: rackPiece(i, rackCell, l10n),
                                ),
                          ],
                        ),
                      ),
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
                    SizedBox(width: controlsWidth, child: controls),
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

  Widget rackPiece(int i, double rackCell, AppLocalizations l10n) {
    final current = steps[i];
    final index = orientations[i];
    final renderer = PieceRenderer(
      piece: current.piece,
      positionIndex: index,
      cellSize: rackCell,
      getPieceColor: widget.colorOf,
    );
    return Semantics(
      label: l10n.guidedPiece(current.piece.id),
      selected: selected == i,
      button: true,
      child: GestureDetector(
        key: ValueKey('guided-select-$i'),
        onTap: () {
          if (widget.enableHaptics) HapticFeedback.selectionClick();
          select(i);
        },
        child: LongPressDraggable<int>(
          key: ValueKey('guided-piece-$i'),
          data: i,
          delay: widget.longPressDuration,
          maxSimultaneousDrags: 1,
          hapticFeedbackOnStart: false,
          onDragStarted: () {
            select(i);
            if (widget.enableHaptics) HapticFeedback.lightImpact();
          },
          dragAnchorStrategy: (drag, ctx, pos) {
            final box = ctx.findRenderObject() as RenderBox;
            final local = box.globalToLocal(pos);
            // Même taille de feedback que la miniature : conserver exactement le point de prise.
            dragVisual.value = (false, -local);
            return Offset.zero;
          },
          onDragEnd: (_) {
            updateHover(false);
            // Le DragTarget accepte aussi les survols mal orientés : seul step change à la pose réelle.
            if (mounted && step <= i) setState(() => retry = selected == step);
          },
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
              border: Border.all(
                color: selected == i ? Colors.amber : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: renderer,
          ),
        ),
      ),
    );
  }
}
