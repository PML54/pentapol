// Modified: 2026-09-11 15:10 — tester le glissé en mode jeu avec une base isolée, sans le mode supprimé.
// test/rack_drag_landscape_test.dart
// Historique: 2026-09-10 10:14 — feedback visible dès la prise, obstacle, sortie et retour au plateau sans perdre la pose.
// Historique: 2026-09-10 09:46 — régression pièce 5 : drag réel rack tourné vers ligne basse, formats iPhone et tablette.
import 'dart:math' as math;
import 'package:drift/native.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/pentoscope/widgets/piece_drag_feedback.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_board.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_piece_slider.dart';

class _Game extends PentoscopeNotifier {
  void load(PentoscopeState value) => state = value;
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  for (final screen in [const Size(874, 402), const Size(1366, 1024)]) {
    testWidgets('rack paysage vers ligne basse, écran $screen', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = screen;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));
      final game = _Game();
      final container = ProviderContainer(
        overrides: [
          settingsDatabaseProvider.overrideWithValue(db),
          pentoscopeProvider.overrideWith(() => game),
          settingsProvider.overrideWith(_Settings.new),
        ],
      );
      addTearDown(container.dispose);
      container.read(pentoscopeProvider);
      // Initialiser aussi la source de solutions, comme une vraie partie.
      await tester.runAsync(() => game.startPuzzle(PentoscopeSize.size8x5));
      final piece = pentominos.firstWhere((p) => p.id == 5);
      final cell = screen == const Size(874, 402) ? 48.0 : 90.0;
      final rackCell = cell * 0.46;
      for (var index = 0; index < piece.numOrientations; index++) {
        final raw = piece.orientations[index];
        final minX = raw.map((n) => (n - 1) % 5).reduce(math.min);
        final minY = raw.map((n) => (n - 1) ~/ 5).reduce(math.min);
        for (final n in raw) {
          await tester.pumpWidget(const SizedBox.shrink());
          game.load(
            PentoscopeState.initial().copyWith(
              puzzle: const PentoscopePuzzle(
                size: PentoscopeSize.size8x5,
                pieceIds: [5],
                solutionCount: 1,
              ),
              plateau: Plateau.allVisible(5, 8),
              availablePieces: [piece],
              piecePositionIndices: {5: index},
            ),
          );
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      height: cell * 5,
                      child: Row(
                        children: [
                          SizedBox(
                            width: cell * 8,
                            child: const PentoscopeBoard(isLandscape: true),
                          ),
                          SizedBox(
                            width: rackCell * 5 + 24,
                            child: PentoscopePieceSlider(
                              isLandscape: true,
                              pieceCellSize: rackCell,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          final x = (n - 1) % 5 - minX;
          final y = (n - 1) ~/ 5 - minY;
          final renderer = tester.renderObject<RenderBox>(
            find.byType(PieceRenderer).first,
          );
          // Prise sur une vraie case, dans le rack tourné de -90 degrés.
          final grab = renderer.localToGlobal(
            Offset(4 + (x + .5) * rackCell, 4 + (y + .5) * rackCell),
          );
          final gesture = await tester.startGesture(grab);
          await tester.pump(const Duration(milliseconds: 300));
          PieceRenderer feedback() => tester.widget<PieceRenderer>(
            find.descendant(
              of: find.byType(PieceDragFeedback),
              matching: find.byType(PieceRenderer),
            ),
          );
          expect(
            feedback().invalidPlacement,
            isTrue,
            reason: 'visible et rouge avant le plateau',
          );
          expect(
            tester.getSize(find.byType(PieceDragFeedback)).isEmpty,
            isFalse,
          );
          // Ancre logique (0,2) : x logique 0 = dernière ligne VISUELLE en paysage.
          final target = Offset((2 + y + .5) * cell, (4 - x + .5) * cell);
          await gesture.moveTo(target);
          await tester.pump();
          final preview = container.read(pentoscopeProvider);
          expect(
            preview.previewX,
            0,
            reason: 'orientation $index, prise ($x,$y)',
          );
          expect(
            preview.previewY,
            2,
            reason: 'orientation $index, prise ($x,$y)',
          );
          expect(preview.isPreviewValid, isTrue);
          expect(
            feedback().invalidPlacement,
            isFalse,
            reason: 'couleur normale sur pose valide',
          );
          // Simuler des emplacements occupés : le feedback reste présent et devient rouge.
          game.load(preview.copyWith(validPlacements: []));
          await tester.pump();
          await gesture.moveTo(target + const Offset(1, 0));
          await tester.pump();
          expect(
            feedback().invalidPlacement,
            isTrue,
            reason: 'rouge en cas de chevauchement',
          );
          game.load(preview);
          await tester.pump();
          await gesture.moveTo(Offset(cell * 8 + 10, cell * 5 + 30));
          await tester.pump();
          expect(
            feedback().invalidPlacement,
            isTrue,
            reason: 'rouge à nouveau hors plateau',
          );
          expect(
            container.read(pentoscopeProvider).previewX,
            preview.previewX,
            reason:
                'conserver la dernière ancre pour le dépôt tolérant au bord',
          );
          await gesture.moveTo(target);
          await tester.pump();
          expect(feedback().invalidPlacement, isFalse);
          await tester.runAsync(() async {
            await gesture.up();
            // Laisser les écritures SQLite finir hors de l’horloge simulée des gestes.
            await db.customSelect('SELECT 1').get();
          });
          await tester.pump();
          final placed = container.read(pentoscopeProvider).placedPieces.single;
          expect(placed.gridX, 0);
          expect(placed.gridY, 2);
          expect(placed.positionIndex, index);
          game.stopTimer();
        }
      }
    });
  }
}
