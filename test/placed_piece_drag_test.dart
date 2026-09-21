// Modified: 2026-09-21 14:21 — couvrir la fin de translation refusée aux limites du plateau.
// test/placed_piece_drag_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_board.dart';
import 'package:pentapol/providers/settings_provider.dart';

class _Game extends PentoscopeNotifier {
  void load(PentoscopeState value) => state = value;
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  testWidgets('un dépôt refusé efface l’aperçu d’une pièce posée', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 850);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final piece = pentominos.firstWhere((candidate) => candidate.id == 5);
    final placed = PlacedPiece(
      piece: piece,
      positionIndex: 0,
      gridX: 0,
      gridY: 3,
    );
    final board = Plateau.allVisible(5, 8);
    for (final cell in placed.absoluteCells) {
      board.setCell(cell.x, cell.y, piece.id);
    }

    final game = _Game();
    final container = ProviderContainer(
      overrides: [
        pentoscopeProvider.overrideWith(() => game),
        settingsProvider.overrideWith(_Settings.new),
      ],
    );
    addTearDown(container.dispose);
    container.read(pentoscopeProvider);
    game.load(
      PentoscopeState.initial().copyWith(
        puzzle: const PentoscopePuzzle(
          size: PentoscopeSize.size8x5,
          pieceIds: [5],
          solutionCount: 1,
        ),
        plateau: board,
        placedPieces: [placed],
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 700,
              child: PentoscopeBoard(isLandscape: false),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final source = find.text('5').first;
    await tester.tap(source);
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(pentoscopeProvider).selectedPlacedPiece, isNotNull);

    final gesture = await tester.startGesture(tester.getCenter(source));
    await gesture.moveTo(const Offset(250, 300));
    await tester.pump();
    expect(container.read(pentoscopeProvider).previewX, isNotNull);

    await gesture.moveTo(const Offset(-80, -80));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    final state = container.read(pentoscopeProvider);
    expect(state.isDragging, isFalse);
    expect(state.previewX, isNull);
    expect(state.previewY, isNull);
    expect(state.selectedPlacedPiece, isNotNull);
    expect(state.placedPieces, [placed]);
  });
}
