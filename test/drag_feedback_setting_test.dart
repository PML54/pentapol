// Modified: 2026-09-22 16:31 — vérifier le relais visuel hors plateau quand la copie est masquée.
// Historique: 2026-09-22 06:06 — vérifier le défaut masqué, la persistance et le feedback optionnel.
// test/drag_feedback_setting_test.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/widgets/draggable_piece_widget.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/widgets/piece_drag_feedback.dart';

void main() {
  test('la miniature de drag est masquée par défaut et sérialisée', () {
    expect(const GameSettings().showDragFeedback, isFalse);

    const settings = AppSettings(game: GameSettings(showDragFeedback: true));
    final restored = AppSettings.fromJson(
      jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>,
    );
    expect(restored.game.showDragFeedback, isTrue);
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
