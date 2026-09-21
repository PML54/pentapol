// Modified: 2026-09-21 09:04 — vérifier que Jouer revient au Game sans bandeau après le training.
// Historique: 2026-09-21 08:49 — tester mode training, bandeau déplaçable, quatre états et nouvel exercice.
// Historique: 2026-09-12 03:40 — parcours en navigation accessible ; défilement testé séparément.
// Historique: 2026-09-11 16:12 — vérifier l’accès immédiat au jeu depuis le bouton de l’accueil.
// test/home_play_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/pentoscope/home/home_screen.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_mode.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';

class _Game extends PentoscopeNotifier {
  void load(PentoscopeState value) => state = value;
}

class _AutoGame extends _Game {
  int recreationalStarts = 0;
  int gameStarts = 0;

  @override
  Future<void> startPuzzle(
    PentoscopeSize size, {
    int? mask,
    bool showSolution = false,
    bool isProgression = false,
  }) async {
    gameStarts++;
    final piece = pentominos.first;
    load(
      PentoscopeState.initial().copyWith(
        puzzle: PentoscopePuzzle(
          size: size,
          pieceIds: [piece.id],
          solutionCount: 1,
        ),
        plateau: Plateau.allVisible(size.width, size.height),
        availablePieces: [piece],
        piecePositionIndices: {piece.id: 0},
        solutionsCount: 1,
        isProgression: isProgression,
      ),
    );
  }

  @override
  Future<void> startRecreationalPuzzle({
    PentoscopeSize size = PentoscopeSize.size7x5,
  }) async {
    recreationalStarts++;
    final piece = pentominos.first;
    load(
      PentoscopeState.initial().copyWith(
        puzzle: PentoscopePuzzle(
          size: size,
          pieceIds: [piece.id],
          solutionCount: 1,
        ),
        plateau: Plateau.allVisible(size.width, size.height),
        availablePieces: [piece],
        piecePositionIndices: {piece.id: 0},
        solutionsCount: 1,
      ),
    );
  }
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  testWidgets('le démarrage ouvre directement le Game récréatif', (
    tester,
  ) async {
    final game = _AutoGame();
    final container = ProviderContainer(
      overrides: [
        pentoscopeProvider.overrideWith(() => game),
        settingsProvider.overrideWith(_Settings.new),
      ],
    );
    addTearDown(container.dispose);
    container.read(pentoscopeProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
            child: child!,
          ),
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(game.recreationalStarts, 1);
    expect(find.byType(PentoscopeGameScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('home-recreational')), findsNothing);
    expect(
      find.text('Appuie sur la pièce du tiroir pour la sélectionner.'),
      findsWidgets,
    );

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(game.recreationalStarts, 1);
    expect(find.byType(PentoscopeGameScreen), findsNothing);
    expect(find.byKey(const ValueKey('home-play')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-play')));
    await tester.pumpAndSettle();
    expect(game.gameStarts, 1);
    expect(find.byType(PentoscopeGameScreen), findsOneWidget);
    expect(
      tester
          .widget<PentoscopeGameScreen>(find.byType(PentoscopeGameScreen))
          .mode,
      PentoscopeMode.game,
    );
    expect(find.byKey(const ValueKey('recreational-guide')), findsNothing);
  });

  for (final screen in [const Size(320, 568), const Size(874, 402)]) {
    for (final lang in ['fr', 'en']) {
      testWidgets(
        'Jouer contourne l’accueil sans perdre la partie : $screen $lang',
        (tester) async {
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
          final size = sizeForLevel(1);
          final puzzle = PentoscopePuzzle(
            size: size,
            pieceIds: [5],
            solutionCount: 7,
          );
          game.load(
            PentoscopeState.initial().copyWith(
              puzzle: puzzle,
              plateau: Plateau.allVisible(size.width, size.height),
              availablePieces: [pentominos.firstWhere((p) => p.id == 5)],
              piecePositionIndices: {5: 0},
              isProgression: true,
              solutionsCount: 7,
              elapsedSeconds: 42,
            ),
          );
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(accessibleNavigation: true),
                  child: child!,
                ),
                locale: Locale(lang),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const HomeScreen(startRecreationalOnOpen: false),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('home-recreational')), findsNothing);
          expect(find.byKey(const ValueKey('home-training')), findsNothing);
          final play = find.byKey(const ValueKey('home-play'));
          expect(tester.widget(play), isA<FilledButton>());
          expect(find.byIcon(Icons.person), findsNothing);
          final bounds = tester.getRect(play);
          for (final icon in [
            Icons.people,
            Icons.flag_outlined,
            Icons.emoji_events_outlined,
            Icons.settings,
          ]) {
            final button = find.ancestor(
              of: find.byIcon(icon),
              matching: find.byType(IconButton),
            );
            expect(bounds.overlaps(tester.getRect(button)), isFalse);
          }
          await tester.tap(play);
          await tester.pumpAndSettle();
          expect(find.byType(PentoscopeGameScreen), findsOneWidget);
          expect(container.read(pentoscopeProvider).puzzle, same(puzzle));
          expect(container.read(pentoscopeProvider).elapsedSeconds, 42);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('le training suit les quatre états et relance sans bilan', (
    tester,
  ) async {
    final game = _AutoGame();
    final container = ProviderContainer(
      overrides: [
        pentoscopeProvider.overrideWith(() => game),
        settingsProvider.overrideWith(_Settings.new),
      ],
    );
    addTearDown(container.dispose);
    container.read(pentoscopeProvider);
    final size = PentoscopeSize.size3x5;
    final piece = pentominos.firstWhere((p) => p.numOrientations > 1);
    game.load(
      PentoscopeState.initial().copyWith(
        puzzle: PentoscopePuzzle(
          size: size,
          pieceIds: [piece.id],
          solutionCount: 1,
        ),
        plateau: Plateau.allVisible(size.width, size.height),
        availablePieces: [piece],
        piecePositionIndices: {piece.id: 0},
        solutionsCount: 1,
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
            child: child!,
          ),
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PentoscopeGameScreen(mode: PentoscopeMode.training),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text('Appuie sur la pièce du tiroir pour la sélectionner.'),
      findsWidgets,
    );
    final guide = find.byKey(const ValueKey('training-guide-drag'));
    final guideStart = tester.getCenter(guide);
    await tester.drag(guide, const Offset(40, 28));
    await tester.pump();
    expect(tester.getCenter(guide), guideStart + const Offset(40, 28));

    game.selectPiece(piece);
    game.load(
      container.read(pentoscopeProvider).copyWith(validPlacements: const []),
    );
    await tester.pump();
    expect(
      find.text('Mets la pièce dans la bonne position avec les icônes.'),
      findsWidgets,
    );

    game.applyIsometryRotationCW();
    game.load(
      container.read(pentoscopeProvider).copyWith(validPlacements: const []),
    );
    await tester.pump();
    expect(
      find.text('Mets la pièce dans la bonne position avec les icônes.'),
      findsWidgets,
    );

    game.load(
      container
          .read(pentoscopeProvider)
          .copyWith(validPlacements: const [Point(0, 0)]),
    );
    await tester.pump();
    expect(
      find.text('Déplace-la au bon endroit sur le plateau.'),
      findsWidgets,
    );

    final state = container.read(pentoscopeProvider);
    game.load(
      state.copyWith(
        placedPieces: [
          PlacedPiece(
            piece: piece,
            positionIndex: state.selectedPositionIndex,
            gridX: 0,
            gridY: 0,
          ),
        ],
        availablePieces: const [],
        clearSelectedPiece: true,
        isComplete: true,
      ),
    );
    await tester.pump();
    expect(find.text('C’est bon !'), findsWidgets);
    expect(find.byKey(const ValueKey('training-next')), findsOneWidget);
    expect(find.text('Géométrie'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('training-next')));
    await tester.pumpAndSettle();
    expect(game.recreationalStarts, 1);
    expect(
      find.text('Appuie sur la pièce du tiroir pour la sélectionner.'),
      findsWidgets,
    );
  });
}
