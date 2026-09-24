// Modified: 2026-09-23 17:45 — vérifier sélection, icône puis transformation.
// test/animated_home_board_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/pentoscope/home/animated_home_board.dart';

void main() {
  Color cellColor(WidgetTester tester, int x, int y) {
    final widget = tester.widget<AnimatedContainer>(
      find.byKey(ValueKey('home-board-$x-$y')),
    );
    return (widget.decoration! as BoxDecoration).color!;
  }

  final firstSolution = [
    for (var y = 0; y < 5; y++)
      PlacedPiece(piece: pentominos.last, positionIndex: 1, gridX: 0, gridY: y),
  ];

  Widget app({bool reduceMotion = false, List<List<PlacedPiece>>? solutions}) =>
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Scaffold(
          body: AnimatedHomeBoard(
            solutions: solutions ?? [firstSolution],
            colorOf: (id) => Color(0xFF000000 | id * 0x00111111),
          ),
        ),
      );

  testWidgets('une nouvelle solution est présentée à la boucle suivante', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(solutions: [firstSolution, firstSolution.reversed.toList()]),
    );
    await tester.pump(const Duration(milliseconds: 21140));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(const Duration(milliseconds: 2050));

    expect(cellColor(tester, 0, 4), const Color(0xFFD9E0E8));
  });

  testWidgets('la sélection puis l’icône précèdent le déplacement', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('home-isometry-bar')), findsOneWidget);
    expect(find.byIcon(Icons.rotate_left), findsOneWidget);
    expect(find.byIcon(Icons.rotate_right), findsOneWidget);
    expect(find.byIcon(Icons.swap_vert), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    final frame = tester.widget<Container>(
      find.byKey(const ValueKey('home-board-frame')),
    );
    final frameDecoration = frame.decoration! as BoxDecoration;
    expect(frameDecoration.border!.top.width, 4);
    final initialTurn = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('home-rack-piece-0')),
        matching: find.byType(Transform),
      ),
    );
    final selectedSlot = tester.widget<Container>(
      find.byKey(const ValueKey('home-piece-slot-0')),
    );
    expect((selectedSlot.decoration! as BoxDecoration).border!.top.width, 2);
    final initialAction = tester.widget<Container>(
      find.byKey(const ValueKey('home-isometry-action-0')),
    );
    expect((initialAction.decoration! as BoxDecoration).border, isNull);
    expect(cellColor(tester, 0, 0), const Color(0xFFF3F5F8));

    await tester.pump(const Duration(milliseconds: 650));
    final chosenAction = tester.widget<Container>(
      find.byKey(const ValueKey('home-isometry-action-0')),
    );
    expect((chosenAction.decoration! as BoxDecoration).border!.top.width, 2);
    expect(cellColor(tester, 0, 0), const Color(0xFFF3F5F8));

    await tester.pump(const Duration(milliseconds: 700));
    final oriented = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('home-rack-piece-0')),
        matching: find.byType(Transform),
      ),
    );
    expect(oriented.transform, isNot(initialTurn.transform));

    await tester.pump(const Duration(milliseconds: 600));
    expect(cellColor(tester, 0, 0), const Color(0xFFD9E0E8));

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('home-moving-piece')), findsOneWidget);
    expect(cellColor(tester, 0, 0), const Color(0xFFD9E0E8));

    await tester.pump(const Duration(milliseconds: 1200));
    expect(cellColor(tester, 0, 0), const Color(0xFFCCCCCC));
    expect(cellColor(tester, 0, 1), const Color(0xFFF3F5F8));
    await tester.pump(const Duration(milliseconds: 2050));
    expect(cellColor(tester, 0, 1), const Color(0xFFD9E0E8));

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('les quatre isometries sont montrees pendant une boucle', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    for (var action = 0; action < 4; action++) {
      await tester.pump(Duration(milliseconds: action == 0 ? 650 : 3750));
      final button = tester.widget<Container>(
        find.byKey(ValueKey('home-isometry-action-$action')),
      );
      expect((button.decoration! as BoxDecoration).border, isNotNull);
    }
  });

  testWidgets(
    'la réduction de mouvement affiche le plateau rempli et statique',
    (tester) async {
      await tester.pumpWidget(app(reduceMotion: true));
      await tester.pumpAndSettle();

      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 3; x++) {
          expect(cellColor(tester, x, y), isNot(const Color(0xFFF3F5F8)));
        }
      }
      expect(tester.takeException(), isNull);
    },
  );
}
