// Modified: 2026-09-25 15:00 — vérifier Réglages dans le header et le retrait de Records.
// Historique: 2026-09-23 15:10 — vérifier l'accueil compact et le chargement Training asynchrone.
// Historique: 2026-09-22 05:35 — après le Training 1, le tap démarre le Training 2 avec
//           deux pièces ; le double-tap vers Game reste prioritaire.
// Historique: 2026-09-22 05:14 — fin training : double-tap plein cadre vers Game, tap simple
//           conservé pour enchaîner l'entraînement.
// Historique: 2026-09-22 04:46 — fin training : bandeau « Tap pour un autre training » + tap sur le
//           plateau résolu (training-continue) pour enchaîner (ni bouton ni relance auto) ; geste
//           « dépôt » via long press ; import ui_dimensions redondant retiré ; couleur par état.
// Historique: 2026-09-21 19:13 — vérifier le guide training dans la barre et le dépôt sur la rangée haute.
// Historique: 2026-09-21 17:13 — vérifier le menu principal complet après le training.
// Historique: 2026-09-21 09:04 — vérifier que Jouer revient au Game sans bandeau après le training.
// Historique: 2026-09-21 08:49 — tester mode training, bandeau déplaçable, quatre états et nouvel exercice.
// Historique: 2026-09-12 03:40 — parcours en navigation accessible ; défilement testé séparément.
// Historique: 2026-09-11 16:12 — vérifier l’accès immédiat au jeu depuis le bouton de l’accueil.
// test/home_play_test.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/config/training_bar_colors.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/pentoscope/home/home_screen.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_mode.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_board.dart';

class _Game extends PentoscopeNotifier {
  void load(PentoscopeState value) => state = value;
}

class _AutoGame extends _Game {
  int recreationalStarts = 0;
  int? lastMissingPieceCount;
  int gameStarts = 0;
  PentoscopeSize? lastGameSize;
  bool? lastGameIsProgression;

  @override
  Future<void> startPuzzle(
    PentoscopeSize size, {
    int? mask,
    bool showSolution = false,
    bool isProgression = false,
  }) async {
    gameStarts++;
    lastGameSize = size;
    lastGameIsProgression = isProgression;
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
    PentoscopeSize size = PentoscopeSize.size3x5,
    int missingPieceCount = 1,
  }) async {
    recreationalStarts++;
    lastMissingPieceCount = missingPieceCount;
    final pieces = pentominos.take(missingPieceCount).toList();
    load(
      PentoscopeState.initial().copyWith(
        puzzle: PentoscopePuzzle(
          size: size,
          pieceIds: pieces.map((piece) => piece.id).toList(),
          solutionCount: 1,
        ),
        plateau: Plateau.allVisible(size.width, size.height),
        availablePieces: pieces,
        piecePositionIndices: {for (final piece in pieces) piece.id: 0},
        solutionsCount: 1,
      ),
    );
  }
}

class _DelayedTrainingGame extends _AutoGame {
  final ready = Completer<void>();

  @override
  Future<void> startRecreationalPuzzle({
    PentoscopeSize size = PentoscopeSize.size3x5,
    int missingPieceCount = 1,
  }) async {
    await ready.future;
    await super.startRecreationalPuzzle(
      size: size,
      missingPieceCount: missingPieceCount,
    );
  }
}

class _GestureGame extends _Game {
  int? acceptedY;
  int recreationalStarts = 0;
  int? lastMissingPieceCount;

  @override
  Future<void> startRecreationalPuzzle({
    PentoscopeSize size = PentoscopeSize.size3x5,
    int missingPieceCount = 1,
  }) async {
    recreationalStarts++;
    lastMissingPieceCount = missingPieceCount;
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

  @override
  void updatePreview(int gridX, int gridY) {
    load(
      state.copyWith(
        previewX: gridX,
        previewY: gridY,
        isPreviewValid: true,
        isSnapped: false,
      ),
    );
  }

  @override
  bool tryPlaceAtAnchor(int anchorX, int anchorY) {
    acceptedY = anchorY;
    load(
      state.copyWith(
        availablePieces: const [],
        clearSelectedPiece: true,
        clearPreview: true,
        validPlacements: const [],
        isComplete: true,
      ),
    );
    return true;
  }
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  testWidgets(
    'Game sans + : double-tap relance ou change cycliquement la taille',
    (tester) async {
      final game = _AutoGame();
      final container = ProviderContainer(
        overrides: [
          pentoscopeProvider.overrideWith(() => game),
          settingsProvider.overrideWith(_Settings.new),
        ],
      );
      addTearDown(container.dispose);
      container.read(pentoscopeProvider);

      void load(PentoscopeSize size, {bool occupied = false}) {
        final piece = pentominos.first;
        game.load(
          PentoscopeState.initial().copyWith(
            puzzle: PentoscopePuzzle(
              size: size,
              pieceIds: [piece.id],
              solutionCount: 1,
            ),
            plateau: Plateau.allVisible(size.width, size.height),
            availablePieces: [piece],
            placedPieces: occupied
                ? [
                    PlacedPiece(
                      piece: piece,
                      positionIndex: 0,
                      gridX: 0,
                      gridY: 0,
                    ),
                  ]
                : const [],
            piecePositionIndices: {piece.id: 0},
            solutionsCount: 1,
            isProgression: occupied,
          ),
        );
      }

      load(PentoscopeSize.size5x5, occupied: true);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PentoscopeGameScreen(),
          ),
        ),
      );
      await tester.pump();

      Future<void> doubleTapBoard() async {
        await tester.tap(find.byType(PentoscopeBoard));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(PentoscopeBoard));
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byIcon(Icons.add_circle_outline), findsNothing);
      await doubleTapBoard();
      expect(game.lastGameSize, PentoscopeSize.size5x5);
      expect(game.lastGameIsProgression, isTrue);

      load(PentoscopeSize.size5x5);
      await tester.pump();
      await doubleTapBoard();
      expect(game.lastGameSize, PentoscopeSize.size6x5);
      expect(game.lastGameIsProgression, isFalse);

      load(PentoscopeSize.size6x10);
      await tester.pump();
      await doubleTapBoard();
      expect(game.lastGameSize, PentoscopeSize.size3x5);
    },
  );

  testWidgets('le démarrage affiche le nouvel accueil puis ouvre le Training', (
    tester,
  ) async {
    final game = _DelayedTrainingGame();
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
            data: MediaQuery.of(
              context,
            ).copyWith(accessibleNavigation: true, disableAnimations: true),
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

    expect(game.recreationalStarts, 0);
    expect(find.byType(PentoscopeGameScreen), findsNothing);
    expect(find.byKey(const ValueKey('home-recreational')), findsNothing);
    expect(find.byKey(const ValueKey('home-animated-board')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-play')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-training')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-challenge')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-multiplayer')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-records')), findsNothing);
    expect(find.byKey(const ValueKey('home-header-settings')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-settings')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-training')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    game.ready.complete();
    await tester.pumpAndSettle();
    expect(game.recreationalStarts, 1);
    expect(find.byType(PentoscopeGameScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(game.recreationalStarts, 1);
    expect(find.byType(PentoscopeGameScreen), findsNothing);

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
                  data: MediaQuery.of(context).copyWith(
                    accessibleNavigation: true,
                    disableAnimations: true,
                  ),
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
          expect(find.byKey(const ValueKey('home-training')), findsOneWidget);
          final play = find.byKey(const ValueKey('home-play'));
          expect(tester.widget(play), isA<FilledButton>());
          expect(find.byIcon(Icons.person), findsNothing);
          for (final key in [
            'home-challenge',
            'home-multiplayer',
            'home-header-settings',
          ]) {
            expect(find.byKey(ValueKey(key)), findsOneWidget);
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
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    // Couleur de police par état (bloc 5) — en navigation accessible le bandeau est
    // stationnaire : un `Text` de clé 'guided-message' porte le style, couleur comprise.
    Color? guideColor() => tester
        .widget<Text>(find.byKey(const ValueKey('guided-message')))
        .style
        ?.color;
    // État 1 — aucune sélection.
    expect(guideColor(), TrainingBarColors.noSelection);
    final guide = find.byKey(const ValueKey('recreational-guide'));
    final portraitActions = find.byKey(const ValueKey('portrait-actions'));
    expect(
      find.descendant(of: portraitActions, matching: guide),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('game-body-stack')),
        matching: guide,
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('training-guide-drag')), findsNothing);
    expect(find.byIcon(Icons.drag_indicator), findsNothing);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
    expect(find.byIcon(Icons.lightbulb), findsNothing);
    expect(find.text('0:00'), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    game.selectPiece(piece);
    game.load(
      container.read(pentoscopeProvider).copyWith(validPlacements: const []),
    );
    await tester.pump();
    expect(
      find.text('Mets la pièce dans la bonne position avec les icônes.'),
      findsWidgets,
    );
    // État 2 — sélection sans placement valide.
    expect(guideColor(), TrainingBarColors.noValidPlacement);

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
    // Bandeau de fin : félicitation + consigne des gestes.
    expect(find.textContaining('C’est bon'), findsWidgets);
    expect(find.textContaining('Tap pour le training 2'), findsWidgets);
    expect(find.textContaining('Double tap pour jouer'), findsWidgets);
    // État 4 — puzzle complété.
    expect(guideColor(), TrainingBarColors.complete);
    // Ni bouton « Voir un autre » ni relance auto : le plateau résolu attend un geste.
    expect(find.byKey(const ValueKey('training-next')), findsNothing);
    expect(find.text('Géométrie'), findsNothing);
    expect(game.recreationalStarts, 0);
    expect(game.gameStarts, 0);

    // Un double-tap lance le vrai Game et remplace l'écran training.
    await tester.tap(find.byKey(const ValueKey('training-continue')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('training-continue')));
    await tester.pumpAndSettle();
    expect(game.recreationalStarts, 0);
    expect(game.gameStarts, 1);
    expect(find.byKey(const ValueKey('recreational-guide')), findsNothing);
    expect(find.byKey(const ValueKey('training-continue')), findsNothing);
  });

  testWidgets('le guide training est dans la barre paysage', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(874, 402);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PentoscopeGameScreen(mode: PentoscopeMode.training),
        ),
      ),
    );
    await tester.pump();

    final actions = find.byKey(const ValueKey('landscape-actions'));
    final guide = find.byKey(const ValueKey('recreational-guide'));
    expect(find.descendant(of: actions, matching: guide), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
    expect(find.byIcon(Icons.lightbulb), findsNothing);
    expect(find.text('0:00'), findsNothing);
  });

  testWidgets('le training accepte un dépôt sur la rangée haute', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = _GestureGame();
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
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PentoscopeGameScreen(mode: PentoscopeMode.training),
        ),
      ),
    );
    await tester.pump();

    final rackPiece = find.byType(PieceRenderer).first;

    final boardRect = tester.getRect(find.byType(PentoscopeBoard));
    final cellSize = [
      (boardRect.width - 2 * kBoardSideMargin) / size.width,
      boardRect.height / size.height,
      tester.view.physicalSize.shortestSide * kMaxBoardCellFactor,
    ].reduce(math.min);
    final gridTop = boardRect.bottom - cellSize * size.height;
    final target = Offset(boardRect.center.dx, gridTop + cellSize / 2);

    // Pièce non sélectionnée → LongPressDraggable : tenir le long press (défaut 100 ms) AVANT de
    // déplacer (motif de rack_drag_landscape_test). Un tap + saut unique ne démarre pas le drag.
    final gesture = await tester.startGesture(tester.getCenter(rackPiece));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveTo(target);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(game.acceptedY, 0);
    expect(container.read(pentoscopeProvider).isComplete, isTrue);
    // Ni bouton ni relance auto : le plateau résolu attend un tap pour le Training 2.
    expect(find.byKey(const ValueKey('training-next')), findsNothing);
    expect(game.recreationalStarts, 0);
    await tester.tap(find.byKey(const ValueKey('training-continue')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(game.recreationalStarts, 1);
    expect(game.lastMissingPieceCount, 2);
  });
}
