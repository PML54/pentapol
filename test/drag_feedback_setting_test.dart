// Modified: 2026-10-08 07:11 — vérifier la fin du drag après sélection et retrait de sa source.
// Historique: 2026-09-23 05:13 — vérifier le réglage et le découpage des pièces illustrées.
// Historique: 2026-09-22 16:31 — vérifier le relais visuel hors plateau quand la copie est masquée.
// Historique: 2026-09-22 06:06 — vérifier le défaut masqué, la persistance et le feedback optionnel.
// test/drag_feedback_setting_test.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/widgets/draggable_piece_widget.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/widgets/piece_drag_feedback.dart';
import 'package:pentapol/pentoscope/widgets/illustrated_piece_cells.dart';

void main() {
  testWidgets('fin signalée après sélection puis retrait de la source', (
    tester,
  ) async {
    var selected = false;
    var removed = false;
    var finishes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, update) => Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: removed
                      ? const SizedBox.shrink()
                      : DraggablePieceWidget(
                          piece: pentominos.first,
                          positionIndex: 0,
                          isSelected: selected,
                          selectedPositionIndex: 0,
                          longPressDuration: const Duration(milliseconds: 30),
                          onSelect: () {},
                          onCycle: () {},
                          onCancel: () {},
                          onGrab: (_, _) => update(() => selected = true),
                          onDragFinished: () => finishes++,
                          showDragFeedback: false,
                          childBuilder: (_) => const Text('source'),
                        ),
                ),
                DragTarget<Pento>(
                  onAcceptWithDetails: (_) => update(() => removed = true),
                  builder: (_, _, _) => const SizedBox(
                    width: 100,
                    height: 100,
                    child: Text('target'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('source')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(selected, isTrue);
    await gesture.moveTo(tester.getCenter(find.byType(DragTarget<Pento>)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(removed, isTrue);
    expect(finishes, 1);
  });
  test('la miniature de drag est masquée par défaut et sérialisée', () {
    expect(const GameSettings().showDragFeedback, isFalse);

    const settings = AppSettings(game: GameSettings(showDragFeedback: true));
    final restored = AppSettings.fromJson(
      jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>,
    );
    expect(restored.game.showDragFeedback, isTrue);
  });

  test('les pièces illustrées sont désactivées par défaut et sérialisées', () {
    expect(const GameSettings().showIllustratedPieces, isFalse);

    const settings = AppSettings(
      game: GameSettings(showIllustratedPieces: true),
    );
    final restored = AppSettings.fromJson(
      jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>,
    );
    expect(restored.game.showIllustratedPieces, isTrue);
  });

  test('le découpage conserve les cinq identités de cellule', () {
    final placed = PlacedPiece(
      piece: pentominos.first,
      positionIndex: 0,
      gridX: 2,
      gridY: 3,
    );
    final layout = IllustratedPuzzleLayout.fromSolution(
      [placed],
      boardWidth: 6,
      boardHeight: 10,
    );

    expect(
      layout.cellsForPiece(placed.piece.id),
      placed.absoluteCells.toList(growable: false),
    );
    expect(layout.cellsForPiece(placed.piece.id), hasLength(5));
  });

  for (final visible in [false, true]) {
    testWidgets('feedback du tiroir visible=$visible', (tester) async {
      final piece = pentominos.first;
      await tester.pumpWidget(
        MaterialApp(
          home: DraggablePieceWidget(
            piece: piece,
            positionIndex: 0,
            isSelected: false,
            selectedPositionIndex: 0,
            longPressDuration: const Duration(milliseconds: 100),
            showDragFeedback: visible,
            onSelect: () {},
            onCycle: () {},
            onCancel: () {},
            childBuilder: (isDragging) =>
                Text(isDragging ? 'feedback' : 'piece'),
          ),
        ),
      );

      final draggable = tester.widget<LongPressDraggable<Pento>>(
        find.byType(LongPressDraggable<Pento>),
      );
      if (visible) {
        expect(draggable.feedback, isA<Material>());
      } else {
        expect(draggable.feedback, isA<SizedBox>());
        expect((draggable.feedback as SizedBox).width, 0);
      }
    });
  }

  testWidgets(
    'copie masquée sur le plateau mais visible dans la zone intermédiaire',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PieceDragFeedback(
              piece: pentominos.first,
              positionIndex: 0,
              cellSize: 20,
              getPieceColor: (_) => Colors.blue,
              showOverBoard: false,
            ),
          ),
        ),
      );

      expect(find.byType(PieceRenderer), findsOneWidget);

      final context = tester.element(find.byType(PieceDragFeedback));
      final container = ProviderScope.containerOf(context);
      container.read(dragOverBoardProvider.notifier).update(true);
      await tester.pump();

      expect(find.byType(PieceRenderer), findsNothing);
      expect(find.byType(PieceDragFeedback), findsOneWidget);
    },
  );
}
