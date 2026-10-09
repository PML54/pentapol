// Modified: 2026-10-09 07:33 — tester le Training isométries réel, refus, aimantation et absence de persistance.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/pentoscope_mode.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';

class _Game extends PentoscopeNotifier {
  bool recordNextStage = false;
  int? requestedStage;
  @override
  Future<void> startIsometryTraining({int missingPieceCount = 2}) {
    if (recordNextStage) {
      requestedStage = missingPieceCount;
      return Future.value();
    }
    return super.startIsometryTraining(missingPieceCount: missingPieceCount);
  }

  void orient(int index) {
    state = state.copyWith(selectedPositionIndex: index);
    cancelSelection();
  }
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  for (final k in [2, 3, 4, 5]) {
    testWidgets('isométries k=$k, cible exacte et base intacte', (
      tester,
    ) async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      final game = _Game();
      final container = ProviderContainer(
        overrides: [
          settingsDatabaseProvider.overrideWithValue(db),
          settingsProvider.overrideWith(_Settings.new),
          pentoscopeProvider.overrideWith(() => game),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await tester.runAsync(db.close);
      });
      container.read(pentoscopeProvider);
      Future<List<String>> snapshot() async => [
        for (final table in db.allTables)
          '${table.actualTableName}:${(await db.customSelect('SELECT * FROM ${table.actualTableName}').get()).map((r) => r.data).toList()}',
      ];
      final before = await tester.runAsync(snapshot);
      await tester.runAsync(
        () => game.startIsometryTraining(missingPieceCount: k),
      );
      PentoscopeState current() => container.read(pentoscopeProvider);
      expect(current().availablePieces.length, k);
      expect(current().placedPieces.length, 5 - k);
      expect(current().fixedPieceIds.length, 5 - k);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = k.isEven
          ? const Size(390, 844)
          : const Size(874, 402);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: Locale(k.isEven ? 'fr' : 'en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PentoscopeGameScreen(mode: PentoscopeMode.training),
          ),
        ),
      );
      await tester.pump();
      expect(current().selectedPiece, isNull);
      for (final cell in current().trainingTarget!.absoluteCells) {
        final ghost = find.byKey(
          ValueKey('isometry-target-${cell.x}-${cell.y}'),
        );
        expect(ghost, findsOneWidget);
        expect(
          tester
              .widgetList<Text>(
                find.descendant(of: ghost, matching: find.byType(Text)),
              )
              .every((text) => text.data == ''),
          isTrue,
        );
      }
      for (final target in current().trainingTargets) {
        expect(
          current().initialOrientations[target.piece.id],
          isNot(target.positionIndex),
        );
      }
      for (final fixed in current().placedPieces) {
        game.removePlacedPiece(fixed);
        game.selectPlacedPiece(fixed, fixed.gridX, fixed.gridY);
        expect(current().selectedPiece, isNull);
      }
      final wrong = current().availablePieces.last;
      game.selectPiece(wrong);
      expect(current().trainingWrongSelections, 1);
      game.selectPiece(wrong);
      expect(current().trainingWrongSelections, 1);
      final target = current().trainingTarget!;
      game.selectPiece(target.piece);
      final board = current().plateau;
      expect(game.tryPlaceAtAnchor(target.gridX, target.gridY), isFalse);
      expect(current().plateau, same(board));
      game.recordRejectedDrop();
      game.cancelSelection();
      expect(current().trainingRejectedDrops, 1);
      while (current().trainingTarget != null) {
        final next = current().trainingTarget!;
        game.selectPiece(next.piece);
        game.orient(next.positionIndex);
        game.selectPiece(next.piece);
        expect(current().validPlacements, [Point(next.gridX, next.gridY)]);
        expect(game.tryPlaceAtAnchor(next.gridX + 1, next.gridY), isFalse);
        final grab = current().selectedCellInPiece!;
        final raw = next.piece.orientations[next.positionIndex];
        final minX = raw
            .map((n) => (n - 1) % 5)
            .reduce((a, b) => a < b ? a : b);
        final minY = raw
            .map((n) => (n - 1) ~/ 5)
            .reduce((a, b) => a < b ? a : b);
        game.updatePreview(
          next.gridX + grab.x - minX + 1,
          next.gridY + grab.y - minY,
        );
        expect(current().isPreviewValid, isTrue);
        expect(current().previewX, next.gridX);
        expect(current().previewY, next.gridY);
        expect(
          game.tryPlaceAtAnchor(current().previewX!, current().previewY!),
          isTrue,
        );
      }
      expect(current().isComplete, isTrue);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.runAsync(game.saveCurrentGameSnapshot);
      expect(await tester.runAsync(snapshot), before);
      game.recordNextStage = true;
      await tester.tap(find.byKey(const ValueKey('training-continue')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(game.requestedStage, (k + 1).clamp(2, 5));
      expect(await tester.runAsync(snapshot), before);
    });
  }
}
