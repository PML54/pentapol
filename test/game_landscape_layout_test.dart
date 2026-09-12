// Modified: 2026-09-11 16:00 — vérifier les barres paysage, le plateau fixe et les emplacements de transformation.
// test/game_landscape_layout_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_board.dart';

class _Game extends PentoscopeNotifier {
  void load(PentoscopeState value) => state = value;
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  for (final screen in [
    const Size(667, 375),
    const Size(874, 402),
    const Size(1366, 1024),
    const Size(390, 844),
  ]) {
    for (final size in [
      PentoscopeSize.size3x5,
      PentoscopeSize.size8x5,
      PentoscopeSize.size6x10,
    ]) {
      testWidgets('barres et plateau stables : $screen / $size', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = screen;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final game = _Game();
        final container = ProviderContainer(
          overrides: [
            pentoscopeProvider.overrideWith(() => game),
            settingsProvider.overrideWith(_Settings.new),
          ],
        );
        addTearDown(container.dispose);
        container.read(pentoscopeProvider);
        final piece = pentominos.firstWhere((p) => p.id == 5);
        final placed =
            [
              for (var i = 0; i < piece.numOrientations; i++)
                PlacedPiece(piece: piece, positionIndex: i, gridX: 0, gridY: 0),
            ].firstWhere(
              (p) => p.absoluteCells.every(
                (c) => c.x < size.width && c.y < size.height,
              ),
            );
        final idle = PentoscopeState.initial().copyWith(
          puzzle: PentoscopePuzzle(size: size, pieceIds: [5], solutionCount: 7),
          plateau: Plateau.allVisible(size.width, size.height),
          availablePieces: [piece],
          piecePositionIndices: {5: placed.positionIndex},
          solutionsCount: 7,
        );
        game.load(idle);
        final landscape = screen.width > screen.height;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: landscape
                      ? const EdgeInsets.fromLTRB(44, 0, 44, 21)
                      : const EdgeInsets.only(top: 44, bottom: 34),
                ),
                child: child!,
              ),
              home: const PentoscopeGameScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final grid = find.descendant(
          of: find.byType(PentoscopeBoard),
          matching: find.byType(GridView),
        );
        final boardRect = tester.getRect(grid);
        final home = find.byIcon(Icons.home_outlined);
        final homeRect = tester.getRect(home);
        final glyphs = [
          GameIcons.isometryRotationTW.icon,
          GameIcons.isometryRotationCW.icon,
          GameIcons.isometrySymmetryH.icon,
          GameIcons.isometrySymmetryV.icon,
        ];
        List<Offset> positions() => [
          for (final icon in glyphs) tester.getCenter(find.byIcon(icon)),
        ];
        final idlePositions = positions();
        if (landscape) {
          final rail = tester.getRect(
            find.byKey(const ValueKey('landscape-isometries')),
          );
          final actions = tester.getRect(
            find.byKey(const ValueKey('landscape-actions')),
          );
          expect(rail.right, lessThanOrEqualTo(boardRect.left));
          expect(actions.top, greaterThanOrEqualTo(boardRect.bottom));
          expect(actions.contains(homeRect.center), isTrue);
          for (var i = 0; i < 4; i++) {
            expect(rail.contains(idlePositions[i]), isTrue);
            if (i > 0)
              expect(idlePositions[i].dy, greaterThan(idlePositions[i - 1].dy));
          }
        } else {
          expect(
            find.byKey(const ValueKey('landscape-isometries')),
            findsNothing,
          );
          expect(homeRect.bottom, lessThan(boardRect.top));
          expect(idlePositions.first.dy, greaterThan(boardRect.bottom));
        }
        game.load(idle.copyWith(selectedPiece: piece));
        await tester.pumpAndSettle();
        final selectedPositions = positions();
        expect(tester.getRect(grid), boardRect);
        expect(tester.getRect(home), homeRect);
        if (landscape) expect(selectedPositions, idlePositions);
        for (final icon in glyphs) {
          final button = find.ancestor(
            of: find.byIcon(icon),
            matching: find.byType(IconButton),
          );
          expect(tester.widget<IconButton>(button).onPressed, isNotNull);
        }
        final board = Plateau.allVisible(size.width, size.height);
        for (final cell in placed.absoluteCells) {
          board.setCell(cell.x, cell.y, piece.id);
        }
        game.load(
          idle.copyWith(
            plateau: board,
            placedPieces: [placed],
            selectedPlacedPiece: placed,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(GameIcons.removePiece.icon), findsOneWidget);
        expect(tester.getRect(grid), boardRect);
        expect(tester.getRect(home), homeRect);
        if (landscape) expect(positions(), selectedPositions);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
