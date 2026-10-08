// Modified: 2026-10-08 07:20 — vérifier le swipe sur une pièce sélectionnée sans départ de drag.
// Historique: 2026-10-08 07:10 — vérifier que la flèche se déverrouille après une prise par appui long.
// Historique: 2026-10-08 07:06 — vérifier les pièces sans fondu et un cran entier après swipe.
// Historique: 2026-10-08 07:00 — vérifier la navigation à trois pièces et l'affichage complet sans débordement.
// Historique: 2026-10-08 03:53 — vérifier la continuité visuelle du passage dernière-première.
// Historique: 2026-10-08 03:47 — vérifier la flèche unique et le retour cyclique à la première pièce.
// Historique: 2026-10-08 03:36 — vérifier navigation par pièce, butées et changements du tiroir.
// Historique: 2026-10-07 09:42 — vérifier retour au milieu et swipes sur les pièces après l'aperçu.
// Historique: 2026-10-07 09:26 — vérifier aperçu de trois secondes, interruption et centrage du tiroir.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_piece_slider.dart';
import 'package:pentapol/providers/settings_provider.dart';

class _Game extends PentoscopeNotifier {
  void setPieces(List<Pento> pieces) =>
      state = state.copyWith(availablePieces: pieces);
  void newGame() => state = PentoscopeState.initial().copyWith(
    puzzle: PentoscopePuzzle(
      size: PentoscopeSize.size6x10,
      pieceIds: pentominos.map((piece) => piece.id).toList(),
      solutionCount: 9356,
    ),
    plateau: Plateau.allVisible(6, 10),
    availablePieces: pentominos,
  );
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  for (final landscape in [false, true]) {
    testWidgets('flèche par pièce et boucle paysage=$landscape', (
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
      game.newGame();
      Future<void> mount({double extent = 280, bool reduced = false}) =>
          tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: reduced),
                  child: child!,
                ),
                home: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: landscape ? 140 : extent,
                      height: landscape ? extent : 140,
                      child: PentoscopePieceSlider(isLandscape: landscape),
                    ),
                  ),
                ),
              ),
            ),
          );
      await mount();
      await tester.pumpAndSettle();
      final list = find.byType(ListView);
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
      final previous = find.byKey(const ValueKey('rack-previous'));
      final next = find.byKey(const ValueKey('rack-next'));
      expect(previous, findsNothing);
      expect(tester.getSize(next), const Size(64, 64));
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(next).onPressed, isNotNull);
      await tester.tap(next);
      await tester.pumpAndSettle();
      void expectCentered(int index) {
        final piece = tester.getCenter(
          find.byKey(ValueKey('rack-piece-${pentominos[index].id}')),
        );
        final center = tester.getCenter(list);
        expect(
          landscape ? piece.dy : piece.dx,
          closeTo(landscape ? center.dy : center.dx, 1),
        );
      }

      expectCentered(1);
      game.selectPiece(pentominos[1]);
      await tester.pump();
      final beforeSelectedSwipe = scroll.position.pixels;
      await tester.timedDrag(
        find.byKey(ValueKey('rack-piece-${pentominos[1].id}')),
        landscape ? const Offset(0, -70) : const Offset(-70, 0),
        const Duration(milliseconds: 100),
      );
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, greaterThan(beforeSelectedSwipe));
      expect(container.read(pentoscopeProvider).selectedPiece, isNull);
      expect(container.read(pentoscopeProvider).strategyActions.total, 0);
      expect(tester.widget<IconButton>(next).onPressed, isNotNull);
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expectCentered(1);
      await tester.tap(next);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(next);
      await tester.pumpAndSettle();
      expectCentered(3);
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expectCentered(1);
      scroll.position.jumpTo(scroll.position.pixels + 10);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expectCentered(2);
      scroll.position.jumpTo(scroll.position.pixels - 10);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expectCentered(3);
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expectCentered(2);
      game.selectPiece(pentominos[2]);
      await tester.pump();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(container.read(pentoscopeProvider).selectedPiece, isNull);
      expectCentered(3);
      expect(container.read(pentoscopeProvider).strategyActions.total, 0);
      game.selectPiece(pentominos[3]);
      await tester.pump();
      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(ValueKey('rack-piece-${pentominos[3].id}')),
        ),
      );
      await gesture.moveBy(
        landscape ? const Offset(-30, 0) : const Offset(0, -30),
      );
      await tester.pump();
      expect(tester.widget<IconButton>(next).onPressed, isNull);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(next).onPressed, isNotNull);
      final longPress = await tester.startGesture(
        tester.getCenter(
          find.byKey(ValueKey('rack-piece-${pentominos[3].id}')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await longPress.moveBy(
        landscape ? const Offset(-30, 0) : const Offset(0, -30),
      );
      await tester.pump();
      expect(tester.widget<IconButton>(next).onPressed, isNull);
      await longPress.up();
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(next).onPressed, isNotNull);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expectCentered(4);
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(next).onPressed, isNotNull);
      final lastCenter = tester.getCenter(
        find.byKey(ValueKey('rack-piece-${pentominos.last.id}')),
      );
      final listCenter = tester.getCenter(list);
      final lastOffset =
          scroll.position.pixels +
          (landscape
              ? lastCenter.dy - listCenter.dy
              : lastCenter.dx - listCenter.dx);
      scroll.position.jumpTo(lastOffset);
      await tester.pumpAndSettle();
      final beforeWrap = scroll.position.pixels;
      await tester.tap(next);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(scroll.position.pixels, greaterThan(beforeWrap));
      final incoming = tester.getCenter(
        find.byKey(ValueKey('rack-copy-2-${pentominos.first.id}')),
      );
      expect(
        landscape ? incoming.dy : incoming.dx,
        greaterThan(landscape ? listCenter.dy : listCenter.dx),
      );
      await tester.pumpAndSettle();
      expectCentered(0);
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(next);
      await tester.pumpAndSettle();
      expectCentered(1);
      for (var i = 0; i < pentominos.length * 2 + 1; i++) {
        await tester.tap(next);
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
      expectCentered(2);
      await tester.tap(next);
      await tester.pump(const Duration(milliseconds: 30));
      game.setPieces(pentominos.take(4).toList());
      await tester.pumpAndSettle();
      expect(
        scroll.position.pixels,
        lessThanOrEqualTo(scroll.position.maxScrollExtent),
      );
      game.setPieces(pentominos.take(3).toList());
      await tester.pumpAndSettle();
      expect(previous, findsNothing);
      expect(next, findsNothing);
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .maxScrollExtent,
        0,
      );
      await mount(extent: 200);
      await tester.pumpAndSettle();
      expect(next, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PentoscopePieceSlider),
          matching: find.byType(ShaderMask),
        ),
        findsNothing,
      );
      tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(0);
      await tester.pumpAndSettle();
      for (final index in [1, 2, 0]) {
        await tester.tap(next);
        await tester.pumpAndSettle();
        expectCentered(index);
      }
      game.setPieces(pentominos.take(2).toList());
      await mount();
      await tester.pumpAndSettle();
      expect(next, findsNothing);
      final fittingScroll = tester.state<ScrollableState>(
        find.byType(Scrollable),
      );
      expect(fittingScroll.position.maxScrollExtent, 0);
      final viewportRect = tester.getRect(list);
      for (final piece in pentominos.take(2)) {
        final rect = tester.getRect(
          find.byKey(ValueKey('rack-piece-${piece.id}')),
        );
        expect(
          landscape ? rect.top : rect.left,
          greaterThanOrEqualTo(
            landscape ? viewportRect.top : viewportRect.left,
          ),
        );
        expect(
          landscape ? rect.bottom : rect.right,
          lessThanOrEqualTo(
            landscape ? viewportRect.bottom : viewportRect.right,
          ),
        );
      }
      await mount(extent: 160);
      await tester.pumpAndSettle();
      expect(next, findsOneWidget);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await mount();
      await tester.pumpAndSettle();
      game.setPieces([]);
      await tester.pumpAndSettle();
      expect(list, findsNothing);
      expect(tester.takeException(), isNull);
      game.setPieces(pentominos.take(4).toList());
      await mount(extent: 550, reduced: true);
      await tester.pumpAndSettle();
      expect(next, findsNothing);
      await mount(reduced: true);
      await tester.pumpAndSettle();
      expect(next, findsOneWidget);
      final resizedScroll = tester.state<ScrollableState>(
        find.byType(Scrollable),
      );
      resizedScroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pump();
      expectCentered(1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('aperçu, centrage et arrêt manuel paysage=$landscape', (
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
      game.newGame();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: landscape ? 140 : 280,
                  height: landscape ? 280 : 140,
                  child: PentoscopePieceSlider(isLandscape: landscape),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
      final list = find.byType(ListView);
      await tester.pump();
      final start = scroll.position.pixels;
      final end = scroll.position.maxScrollExtent - start;
      expect(end, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(
        scroll.position.pixels,
        closeTo(start + (end - start) * 1500 / 2700, 2),
      );
      expect(container.read(pentoscopeProvider).selectedPiece, isNull);
      expect(container.read(pentoscopeProvider).strategyActions.total, 0);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
      final middleId = pentominos[pentominos.length ~/ 2].id;
      final middle = find.byKey(ValueKey('rack-piece-$middleId'));
      final middleCenter = tester.getCenter(middle);
      final viewportCenter = tester.getCenter(list);
      expect(
        landscape ? middleCenter.dy : middleCenter.dx,
        closeTo(landscape ? viewportCenter.dy : viewportCenter.dx, 1),
      );
      expect(container.read(pentoscopeProvider).selectedPiece, isNull);
      final beforeSwipe = scroll.position.pixels;
      await tester.drag(
        list,
        landscape ? const Offset(0, -80) : const Offset(-80, 0),
      );
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, greaterThan(beforeSwipe));
      final afterSwipe = scroll.position.pixels;
      await tester.drag(
        list,
        landscape ? const Offset(0, 80) : const Offset(80, 0),
      );
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, lessThan(afterSwipe));
      expect(container.read(pentoscopeProvider).strategyActions.total, 0);

      // Mettre la première pièce près du bord, puis la sélectionner réellement.
      scroll.position.jumpTo(40);
      await tester.pumpAndSettle();
      final firstId = pentominos.first.id;
      final piece = find.byKey(ValueKey('rack-piece-$firstId'));
      await tester.tap(piece);
      await tester.pump(const Duration(milliseconds: 310));
      await tester.pump(const Duration(milliseconds: 310));
      await tester.pumpAndSettle();
      expect(container.read(pentoscopeProvider).selectedPiece?.id, firstId);
      final pieceCenter = tester.getCenter(piece);
      final listCenter = tester.getCenter(list);
      expect(
        landscape ? pieceCenter.dy : pieceCenter.dx,
        closeTo(landscape ? listCenter.dy : listCenter.dx, 1),
      );
      expect(container.read(pentoscopeProvider).strategyActions.total, 0);

      scroll.position.jumpTo(end - 40);
      await tester.pumpAndSettle();
      final lastId = pentominos.last.id;
      final lastPiece = find.byKey(ValueKey('rack-piece-$lastId'));
      await tester.tap(lastPiece);
      await tester.pump(const Duration(milliseconds: 310));
      await tester.pump(const Duration(milliseconds: 310));
      await tester.pumpAndSettle();
      expect(container.read(pentoscopeProvider).selectedPiece?.id, lastId);
      expect(scroll.position.pixels, closeTo(end, 1));

      scroll.position.jumpTo(end - 150);
      await tester.pumpAndSettle();
      await tester.dragFrom(
        tester.getTopLeft(list) +
            (landscape ? const Offset(2, 140) : const Offset(140, 2)),
        landscape ? const Offset(0, -100) : const Offset(-100, 0),
      );
      await tester.pumpAndSettle();
      expect(container.read(pentoscopeProvider).selectedPiece, isNull);
      expect(scroll.position.pixels, greaterThan(0));
      expect(container.read(pentoscopeProvider).strategyActions.total, 0);

      // Une nouvelle partie relance l'aperçu ; toucher le tiroir le stoppe.
      game.newGame();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(scroll.position.pixels, greaterThan(0));
      final gesture = await tester.startGesture(tester.getCenter(list));
      await tester.pump();
      final stopped = scroll.position.pixels;
      await tester.pump(const Duration(seconds: 4));
      expect(scroll.position.pixels, closeTo(stopped, 1));
      await gesture.cancel();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
