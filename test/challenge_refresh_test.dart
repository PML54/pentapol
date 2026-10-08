// Modified: 2026-10-07 07:40 — vérifier pièces à poser et coups à la place du nombre de solutions.
// Historique: 2026-10-07 02:10 — vérifier que le renvoi actualise Temps sans afficher les coups.
// Historique: 2026-10-07 01:46 — vérifier l'annonce « Nouveaux défis à … » sur l'écran Défis.
// Historique: 2026-10-06 04:48 — vérifier le nombre de solutions et la nouvelle règle lors du renvoi.
// Historique: 2026-10-06 04:16 — vérifier le renvoi avant lecture, la panne persistante et les renvois concurrents.
import 'dart:async';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/challenge_api.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/screens/challenge_screen.dart';
import 'package:pentapol/pentoscope/screens/leaderboard_screen.dart';
import 'package:pentapol/providers/settings_provider.dart';

class _DefinitionsGame extends PentoscopeNotifier {
  int loads = 0;

  @override
  Future<ChallengeDefinition> dailyChallengeDefinition(
    PentoscopeSize size, {
    DateTime? date,
  }) async {
    loads++;
    return ChallengeDefinition(
      day: challengeDay(),
      dayIndex: 0,
      size: size,
      mask: 74,
      solutionCount: 1,
      theoreticalMoves: 7,
      pieceIds: const [2, 4, 7],
      orientations: const {},
    );
  }
}

// SQLite runs outside the widget test's virtual clock; alternate real IO and UI frames.
Future<void> settleIO(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  await tester.pump();
}

PendingChallengeScore score(String day) => PendingChallengeScore(
  version: 2,
  day: day,
  size: 0,
  playerId: 'a' * 32,
  pseudo: 'Paul',
  minIso: 0,
  isoCount: 0,
  faults: 0,
  timeMs: 1000,
  moves: 3,
  grid: '123',
  strategyActions: 3,
  theoreticalMoves: 3,
  finalSolutionMinimum: true,
  actionCounts: const {
    'placement': 3,
    'rotation': 0,
    'symmetry': 0,
    'translation': 0,
    'removal': 0,
  },
);

void main() {
  test('pièces à poser en coups, pluriels FR/EN', () async {
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(fr.challengePiecesInMoves(7, 12), '7 pièces à poser en 12 coups');
    expect(fr.challengePiecesInMoves(1, 1), '1 pièce à poser en 1 coup');
    expect(en.challengePiecesInMoves(7, 12), '7 pieces to place in 12 moves');
    expect(en.challengePiecesInMoves(1, 1), '1 piece to place in 1 move');
  });
  for (final language in ['fr', 'en']) {
    testWidgets(
      'Actualiser attend le POST et recharge les classements ($language)',
      (tester) async {
        final db = SettingsDatabase.forTesting(NativeDatabase.memory());
        final sent = Completer<http.Response>();
        final events = <String>[];
        var published = false;
        final api = ChallengeApi(
          client: MockClient((request) async {
            events.add(request.method);
            if (request.method == 'POST') {
              final response = await sent.future;
              published = true;
              return response;
            }
            return http.Response(
              jsonEncode({
                'entries': [
                  if (published)
                    {
                      'player_id': 'a' * 32,
                      'pseudo': 'Paul',
                      'time_ms': 1000,
                      'strategy_actions': 14,
                      'theoretical_moves': 7,
                    },
                ],
              }),
              200,
            );
          }),
        );
        final container = ProviderContainer(
          overrides: [
            settingsDatabaseProvider.overrideWithValue(db),
            challengeApiProvider.overrideWithValue(api),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(() => tester.runAsync(db.close));
        late SettingsNotifier settings;
        await tester.runAsync(() async {
          settings = container.read(settingsProvider.notifier);
          await settings.ensureLoaded();
          await settings.setShareScoresOptIn(true);
          await settings.retryPendingChallengeScores();
          await settings.enqueuePendingChallengeScore(score('2026-10-06'));
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const LeaderboardScreen(
                day: '2026-10-06',
                size: PentoscopeSize.size3x5,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final readsBefore = events.where((event) => event == 'GET').length;
        expect(readsBefore, 2);
        final button = find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.tooltip ==
                  (language == 'fr'
                      ? 'Actualiser les résultats'
                      : 'Refresh results'),
        );
        await tester.runAsync(() => tester.tap(button));
        await tester.pump();
        expect(events.where((event) => event == 'POST').length, 1);
        expect(events.where((event) => event == 'GET').length, readsBefore);
        expect(tester.widget<IconButton>(button).onPressed, isNull);
        final concurrentRetry = settings.retryPendingChallengeScores();
        var concurrentDone = false;
        concurrentRetry.then((_) => concurrentDone = true);
        await tester.pump();
        expect(concurrentDone, isFalse);
        // A new score arriving during the POST must survive removal of the sent score.
        await tester.runAsync(
          () => settings.enqueuePendingChallengeScore(score('2026-10-07')),
        );
        await tester.runAsync(() async {
          sent.complete(http.Response('{}', 201));
          await concurrentRetry;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        await settleIO(tester);
        expect(events.where((event) => event == 'POST').length, 1);
        expect(events.where((event) => event == 'GET').length, readsBefore + 2);
        expect(find.text('Paul'), findsWidgets);
        expect(
          tester
              .widget<ListTile>(find.byType(ListTile).hitTestable().first)
              .subtitle,
          isNull,
        );
        expect(
          container.read(settingsProvider).pendingChallengeScores.single.day,
          '2026-10-07',
        );
        expect(tester.widget<IconButton>(button).onPressed, isNotNull);
      },
    );
  }

  testWidgets('la panne conserve le score et réactive le bouton', (
    tester,
  ) async {
    final db = SettingsDatabase.forTesting(NativeDatabase.memory());
    final api = ChallengeApi(
      client: MockClient(
        (request) async => request.method == 'POST'
            ? http.Response('{}', 503)
            : http.Response('{"entries":[]}', 200),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        settingsDatabaseProvider.overrideWithValue(db),
        challengeApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() => tester.runAsync(db.close));
    late SettingsNotifier settings;
    await tester.runAsync(() async {
      settings = container.read(settingsProvider.notifier);
      await settings.ensureLoaded();
      await settings.setShareScoresOptIn(true);
      await settings.retryPendingChallengeScores();
      await settings.enqueuePendingChallengeScore(score('2026-10-06'));
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: LeaderboardScreen(
            day: '2026-10-06',
            size: PentoscopeSize.size3x5,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.byIcon(Icons.refresh)));
    await tester.runAsync(() async {
      await settings.retryPendingChallengeScores();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await settleIO(tester);
    expect(
      container.read(settingsProvider).pendingChallengeScores,
      hasLength(1),
    );
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton &&
                  widget.tooltip == 'Actualiser les résultats',
            ),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('le bouton à droite des Défis renvoie et recharge la liste', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = SettingsDatabase.forTesting(NativeDatabase.memory());
    var posts = 0;
    final api = ChallengeApi(
      client: MockClient((request) async {
        posts++;
        return http.Response('{}', 201);
      }),
    );
    final game = _DefinitionsGame();
    final container = ProviderContainer(
      overrides: [
        settingsDatabaseProvider.overrideWithValue(db),
        challengeApiProvider.overrideWithValue(api),
        pentoscopeProvider.overrideWith(() => game),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() => tester.runAsync(db.close));
    await tester.runAsync(() async {
      final settings = container.read(settingsProvider.notifier);
      await settings.ensureLoaded();
      await settings.setShareScoresOptIn(true);
      await settings.retryPendingChallengeScores();
      await settings.enqueuePendingChallengeScore(score(challengeDay()));
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: ChallengeScreen(),
        ),
      ),
    );
    await settleIO(tester);
    expect(game.loads, kChallengeSizes.length);
    expect(find.textContaining('1 solution'), findsNothing);
    expect(find.textContaining('3 pièces à poser en 7 coups'), findsWidgets);
    expect(find.textContaining('Nouveaux défis à '), findsOneWidget);
    expect(find.textContaining('coups théoriques'), findsNothing);
    expect(
      tester.getCenter(find.byIcon(Icons.refresh)).dx,
      greaterThan(
        tester.getCenter(find.byIcon(Icons.leaderboard_outlined).first).dx,
      ),
    );
    await tester.runAsync(() => tester.tap(find.byIcon(Icons.refresh)));
    await settleIO(tester);
    expect(posts, 1);
    expect(game.loads, kChallengeSizes.length * 2);
    expect(container.read(settingsProvider).pendingChallengeScores, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
