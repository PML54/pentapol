// Modified: 2026-09-08 22:37 — Mode entraînement niveau 1 (PLAN_MODE_ENTRAINEMENT §2) : écran dédié —
//           plateau 5×5, forme cible en fantôme, la pièce se tourne/retourne aux quatre boutons
//           d'isométrie et se déplace au doigt ; à la superposition exacte (mêmes cases), carte de
//           bilan « N appuis — M suffisaient » + temps, puis exercice suivant. Aucune écriture DB.
// lib/pentoscope/training/training_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/common/point.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/pentoscope/training/training_mode.dart';
import 'package:pentapol/pentoscope/training/training_provider.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(trainingProvider);
    final settings = ref.watch(settingsProvider);

    // À la transition « résolu », enregistrer l'exercice (retour, pas un record) — une seule fois.
    ref.listen<TrainingState>(trainingProvider, (prev, next) {
      if ((prev == null || !prev.solved) && next.solved) {
        if (settings.game.enableHaptics) HapticFeedback.mediumImpact();
        ref.read(settingsProvider.notifier).recordTrainingExercise();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trainingMode),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Consigne.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                state.exercise.poseOnly
                    ? l10n.trainingInstructionPose
                    : l10n.trainingInstruction,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            // Plateau + carte de bilan superposée.
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _TrainingBoard(
                        state: state,
                        getPieceColor: (id) => settings.ui.getPieceColor(id),
                        onMove: (a) => ref.read(trainingProvider.notifier).moveTo(a),
                      ),
                    ),
                  ),
                  if (state.solved)
                    Center(child: _ResultCard(state: state)),
                ],
              ),
            ),
            // Barre d'isométrie (les quatre boutons du vrai jeu).
            _IsometryBar(enabled: !state.solved),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Plateau 5×5 : quadrillage, fantôme (forme cible) et pièce manipulée, déplaçable au doigt.
class _TrainingBoard extends StatefulWidget {
  final TrainingState state;
  final Color Function(int pieceId) getPieceColor;
  final void Function(Point anchor) onMove;

  const _TrainingBoard({
    required this.state,
    required this.getPieceColor,
    required this.onMove,
  });

  @override
  State<_TrainingBoard> createState() => _TrainingBoardState();
}

class _TrainingBoardState extends State<_TrainingBoard> {
  /// Décalage (en cases) entre la case empoignée et l'ancre, figé au début du glissé.
  Point? _grabOffset;

  Point _cellAt(Offset local, double cell) {
    final cx = (local.dx ~/ cell).clamp(0, kTrainBoardWidth - 1);
    final cy = (local.dy ~/ cell).clamp(0, kTrainBoardHeight - 1);
    return Point(cx, cy);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final cell = side / kTrainBoardWidth;
        final boardPx = cell * kTrainBoardWidth;
        final st = widget.state;
        final piece = st.exercise.piece;

        final pieceCells = cellsFor(piece, st.currentPositionIndex, st.currentAnchor);
        final ghostCells = st.exercise.targetCells();

        return SizedBox(
          width: boardPx,
          height: boardPx,
          child: GestureDetector(
            onPanStart: (d) {
              if (st.solved) return;
              final c = _cellAt(d.localPosition, cell);
              if (pieceCells.contains(c)) {
                _grabOffset = Point(c.x - st.currentAnchor.x, c.y - st.currentAnchor.y);
              } else {
                _grabOffset = null;
              }
            },
            onPanUpdate: (d) {
              final grab = _grabOffset;
              if (grab == null || st.solved) return;
              final c = _cellAt(d.localPosition, cell);
              widget.onMove(Point(c.x - grab.x, c.y - grab.y));
            },
            onPanEnd: (_) => _grabOffset = null,
            child: Stack(
              children: [
                // Quadrillage.
                for (int y = 0; y < kTrainBoardHeight; y++)
                  for (int x = 0; x < kTrainBoardWidth; x++)
                    Positioned(
                      left: x * cell,
                      top: y * cell,
                      width: cell,
                      height: cell,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                      ),
                    ),
                // Fantôme : la forme cible en surbrillance.
                for (final c in ghostCells)
                  Positioned(
                    left: c.x * cell,
                    top: c.y * cell,
                    width: cell,
                    height: cell,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.getPieceColor(piece.id).withValues(alpha: 0.20),
                        border: Border.all(
                          color: widget.getPieceColor(piece.id).withValues(alpha: 0.85),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                // Pièce manipulée : PieceRenderer aligné sur la grille (marge interne de 4 px).
                Positioned(
                  left: st.currentAnchor.x * cell - 4,
                  top: st.currentAnchor.y * cell - 4,
                  child: DecoratedBox(
                    decoration: st.solved
                        ? BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.7),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          )
                        : const BoxDecoration(),
                    child: PieceRenderer(
                      piece: piece,
                      positionIndex: st.currentPositionIndex,
                      cellSize: cell,
                      showLabel: false,
                      getPieceColor: widget.getPieceColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Barre des quatre isométries (rotation ↺ / ↻, miroir haut-bas / gauche-droite).
class _IsometryBar extends ConsumerWidget {
  final bool enabled;
  const _IsometryBar({required this.enabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(trainingProvider.notifier);
    final size = isometryIconSize(context).clamp(40.0, 56.0);

    Widget btn(GameIconConfig cfg, String tip, VoidCallback onTap) => IconButton(
          icon: Icon(cfg.icon),
          iconSize: size,
          color: cfg.color,
          tooltip: tip,
          onPressed: enabled ? onTap : null,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        btn(GameIcons.isometryRotationTW, l10n.isoRotateTW, notifier.rotateTW),
        btn(GameIcons.isometryRotationCW, l10n.isoRotateCW, notifier.rotateCW),
        btn(GameIcons.isometrySymmetryH, l10n.isoSymH, notifier.mirrorH),
        btn(GameIcons.isometrySymmetryV, l10n.isoSymV, notifier.mirrorV),
      ],
    );
  }
}

/// Carte de bilan de fin d'exercice : appuis effectués, minimum, temps — informatif, non comparatif.
class _ResultCard extends ConsumerWidget {
  final TrainingState state;
  const _ResultCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.congrats,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              '${l10n.trainingPresses(state.presses)} · ${l10n.trainingSeconds(state.elapsedSeconds)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.trainingEnough(state.exercise.minPresses),
              style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(trainingProvider.notifier).next(),
              child: Text(l10n.next),
            ),
          ],
        ),
      ),
    );
  }
}
