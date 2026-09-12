// Modified: 2026-09-12 03:40 — parcours en navigation accessible ; défilement testé séparément.
// Historique: 2026-09-11 16:12 — vérifier l’accès immédiat au jeu depuis le bouton de l’accueil.
// test/home_play_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/pentoscope/home/home_screen.dart';
import 'package:pentapol/pentoscope/home/guided_home.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';

class _Game extends PentoscopeNotifier {
  void load(PentoscopeState value) => state = value;
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
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
                home: const HomeScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(GuidedHome), findsOneWidget);
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
}
