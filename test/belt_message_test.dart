// Modified: 2026-11-17 09:48 — vérifier l’icône acquise et les félicitations de passage en FR/EN.
// test/belt_message_test.dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/config/challenge_belts.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/corpus_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_mode.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';
import 'package:pentapol/pentoscope/solution_source.dart';
import 'package:pentapol/providers/settings_provider.dart';

void main() {
  for (final language in ['fr', 'en']) {
    for (final seconds in [30, 31]) {
      testWidgets('icône acquise et félicitations $language $seconds s', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = SettingsDatabase.forTesting(NativeDatabase.memory());
        final container = ProviderContainer(
          overrides: [settingsDatabaseProvider.overrideWithValue(db)],
        );
        addTearDown(
          () => tester.runAsync(() async {
            await container
                .read(pentoscopeProvider.notifier)
                .saveCurrentGameSnapshot();
            container.dispose();
            await db.close();
          }),
        );
        final game = container.read(pentoscopeProvider.notifier);
        await tester.runAsync(() async {
          final settings = container.read(settingsProvider.notifier);
          await settings.ensureLoaded();
          await settings.setUserName('Paul');
          await settings.setChallengeConsentAsked(true);
          await game.startDailyChallenge(kChallengeSizes.first);
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const PentoscopeGameScreen(mode: PentoscopeMode.challenge),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final badge = find.byKey(const ValueKey('challenge-mode-badge'));
        expect(
          tester
              .widget<BeltIcon>(
                find.byKey(const ValueKey('challenge-player-belt')),
              )
              .belt,
          0,
        );
        expect(
          find.descendant(of: badge, matching: find.byType(Text)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: badge,
            matching: find.byIcon(Icons.flag_outlined),
          ),
          findsNothing,
        );
        await tester.runAsync(() async {
          final definition = game.activeChallenge!;
          final before = container.read(pentoscopeProvider);
          final corpus = await container.read(tirageCorpusProvider.future);
          final solution = CorpusSolutionSource(
            corpus.solutionsFor(definition.mask),
            width: definition.size.width,
            height: definition.size.height,
          ).hintFrom(before.plateau, before.availablePieces)!;
          for (final piece in solution) {
            if (before.fixedPieceIds.contains(piece.piece.id)) continue;
            game.selectPiece(piece.piece);
            for (var reflection = 0; reflection < 2; reflection++) {
              for (var rotation = 0; rotation < 4; rotation++) {
                if (container.read(pentoscopeProvider).selectedPositionIndex ==
                    piece.positionIndex) {
                  break;
                }
                game.applyIsometryRotationCW();
              }
              if (container.read(pentoscopeProvider).selectedPositionIndex ==
                  piece.positionIndex) {
                break;
              }
              game.applyIsometrySymmetryH();
            }
            game.restoreTimerOrigin(seconds);
            game.startTimer();
            expect(game.tryPlaceAtAnchor(piece.gridX, piece.gridY), isTrue);
          }
          await game.waitForChallengeCompletion();
        });
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1100)),
        );
        await tester.pumpAndSettle();
        if (seconds == 30) {
          expect(
            find.byKey(const ValueKey('belt-earned-dialog')),
            findsOneWidget,
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(PentoscopeGameScreen)),
          );
          expect(find.text(l10n.beltEarned(l10n.beltYellow)), findsOneWidget);
          // The next puzzle must not start before the congratulations are dismissed.
          expect(game.activeChallenge!.size, kChallengeSizes.first);
          expect(container.read(settingsProvider).challengeBelt, 1);
        } else {
          final l10n = AppLocalizations.of(
            tester.element(find.byType(PentoscopeGameScreen)),
          );
          expect(find.text(l10n.beltRetryTitle), findsOneWidget);
          expect(
            find.byKey(const ValueKey('belt-earned-dialog')),
            findsNothing,
          );
          expect(container.read(settingsProvider).challengeBelt, 0);
          expect(game.activeChallenge!.size, kChallengeSizes.first);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
