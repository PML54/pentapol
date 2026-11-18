// Modified: 2026-11-17 09:57 — vérifier les ceintures réelles après les noms du classement.
// Historique: 2026-11-17 09:07 — adapter les vérifications aux ceintures et au passage suivant.
// Historique: 2026-11-13 17:35 — placer le défi quotidien avant les résultats.
// Historique: 2026-11-11 06:00 — vérifier le nom partagé du niveau dans le bandeau des défis.
// Historique: 2026-11-05 09:58 — accueil : Jeu Iso, retrait de Training et classement agrandi en secondes.
// Historique: 2026-10-30 08:52 — vérifier les rangées et les podiums quotidiens, réseau et animations.
// Historique: 2026-11-04 10:20 — vérifier les cinq premiers et l’actualisation au retour au menu.
// Historique: 2026-10-31 06:15 — vérifier les requêtes du classement Temps uniquement.
// Historique: 2026-10-31 06:11 — vérifier la disparition du bandeau sans score.
// test/home_daily_tops_test.dart
import 'package:flutter/material.dart';
import 'package:pentapol/config/challenge_belts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/challenge_api.dart';
import 'package:pentapol/pentoscope/home/home_screen.dart';
import 'package:pentapol/providers/settings_provider.dart';

class _Settings extends SettingsNotifier {
  final bool optedIn;
  final int belt;
  _Settings(this.optedIn, [this.belt = 0]);
  @override
  AppSettings build() => AppSettings(
    shareScoresOptIn: optedIn,
    challengeBelt: belt,
    userName: 'Paul',
    playerId: 'player1',
  );
}

class _Api extends ChallengeApi {
  int calls = 0;
  bool empty;
  String prefix = 'Podium';
  _Api({this.empty = false});
  @override
  Future<List<LeaderboardEntry>> leaderboard({
    required int version,
    required String day,
    required int size,
    required Maillot maillot,
    LeaderboardPeriod period = LeaderboardPeriod.day,
    int limit = 100,
  }) async {
    calls++;
    expectSync(version, kChallengeVersion);
    expectSync(day, challengeDay());
    expectSync(period, LeaderboardPeriod.day);
    expectSync(limit, 5);
    expectSync(maillot, Maillot.temps);
    if (empty) return [];
    return [
      for (var i = 1; i <= 5; i++)
        LeaderboardEntry(
          playerId: 'player$i',
          pseudo: '$prefix $i',
          belt: i == 2 ? 4 : null,
          minIso: 0,
          isoCount: 0,
          faults: 0,
          timeMs: i * 12000,
          moves: i,
          strategyActions: i,
        ),
    ];
  }
}

Future<void> _mount(
  WidgetTester tester,
  _Api api, {
  bool optedIn = true,
  bool reduceMotion = false,
  String locale = 'fr',
  double textScale = 1,
  int belt = 0,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(() => _Settings(optedIn, belt)),
        challengeApiProvider.overrideWithValue(api),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ceinture locale du joueur et ceinture connue du concurrent', (
    tester,
  ) async {
    await _mount(tester, _Api(), belt: 3);
    final mine = find.byKey(const ValueKey('ranking-belt-player1'));
    final other = find.byKey(const ValueKey('ranking-belt-player2'));
    expect(tester.widget<BeltIcon>(mine).belt, 3);
    expect(tester.widget<BeltIcon>(other).belt, 4);
    expect(find.byKey(const ValueKey('ranking-belt-player3')), findsNothing);
    expect(
      tester.getTopLeft(mine).dx,
      greaterThan(tester.getTopRight(find.text('Podium 1')).dx),
    );
    expect(
      tester.getTopLeft(other).dx,
      greaterThan(tester.getTopRight(find.text('Podium 2')).dx),
    );
    await tester.pumpWidget(const SizedBox());
  });
  for (final lang in ['fr', 'en']) {
    testWidgets('sept ceintures, petit écran et texte doublé $lang', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (var belt = 0; belt < 7; belt++) {
        await _mount(tester, _Api(), locale: lang, textScale: 2, belt: belt);
        expect(
          tester.widget<BeltIcon>(find.byKey(const ValueKey('home-belt'))).belt,
          belt,
        );
        expect(find.text('Paul'), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const ValueKey('home-cardboard')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  for (final locale in ['fr', 'en']) {
    for (final size in [const Size(320, 568), const Size(874, 402)]) {
      testWidgets('rangées accueil $locale $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _mount(tester, _Api(), locale: locale);
        Rect rect(String key) => tester.getRect(find.byKey(ValueKey(key)));
        expect(
          rect('home-challenge').bottom,
          lessThan(rect('home-daily-tops').top),
        );
        expect(rect('home-daily-tops').bottom, lessThan(rect('home-play').top));
        expect(rect('home-play').top, rect('home-multiplayer').top);
        expect(rect('home-play').height, rect('home-multiplayer').height);
        expect(find.byKey(const ValueKey('home-training')), findsNothing);
        expect(
          find.text(locale == 'fr' ? 'Jeu Iso' : 'Iso Game'),
          findsOneWidget,
        );
        expect(
          rect('home-isometries').top,
          greaterThan(rect('home-play').bottom),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  for (final locale in ['fr', 'en']) {
    testWidgets('cinq lignes lisibles avec texte agrandi $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(tester, _Api(), locale: locale, textScale: 1.3);
      final panel = tester.getRect(
        find.byKey(const ValueKey('home-daily-tops')),
      );
      for (var rank = 1; rank <= 5; rank++) {
        final row = tester.getRect(find.text('Podium $rank'));
        expect(row.top, greaterThanOrEqualTo(panel.top));
        expect(row.bottom, lessThanOrEqualTo(panel.bottom));
      }
      expect(
        panel.top,
        greaterThan(
          tester.getRect(find.byKey(const ValueKey('home-challenge'))).bottom,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('podium défile et permet le balayage manuel', (tester) async {
    final api = _Api();
    await _mount(tester, api);
    expect(api.calls, kChallengeSizes.length);
    final pages = tester.widget<PageView>(find.byType(PageView));
    expect(pages.controller!.page, 0);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-daily-tops')),
        matching: find.textContaining('Ceinture jaune'),
      ),
      findsOneWidget,
    );
    for (var rank = 1; rank <= 5; rank++) {
      expect(find.text('Podium $rank'), findsOneWidget);
      expect(find.text('${rank * 12} s'), findsOneWidget);
    }
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(pages.controller!.page, 1);
    expect(find.text('Podium 5'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(pages.controller!.page, 2);
    expect(api.calls, kChallengeSizes.length);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('animations réduites : podium fixe et balayage disponible', (
    tester,
  ) async {
    await _mount(tester, _Api(), reduceMotion: true);
    final pages = tester.widget<PageView>(find.byType(PageView));
    await tester.pump(const Duration(seconds: 8));
    expect(pages.controller!.page, 0);
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(pages.controller!.page, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('sans opt-in : aucun accès au réseau', (tester) async {
    final api = _Api();
    await _mount(tester, api, optedIn: false);
    await tester.pump(const Duration(seconds: 8));
    expect(api.calls, 0);
    expect(find.byType(PageView), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'retour au menu : classement vide rechargé puis nouveaux scores visibles',
    (tester) async {
      final api = _Api(empty: true);
      await _mount(tester, api);
      expect(find.byKey(const ValueKey('home-daily-tops')), findsNothing);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
      await tester.pumpAndSettle();
      final callsBeforeReturn = api.calls;
      api.empty = false;
      navigator.pop();
      await tester.pumpAndSettle();
      expect(api.calls, callsBeforeReturn + kChallengeSizes.length);
      expect(find.text('Podium 5'), findsOneWidget);
      navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
      await tester.pumpAndSettle();
      api.prefix = 'Updated';
      navigator.pop();
      await tester.pumpAndSettle();
      expect(api.calls, callsBeforeReturn + 2 * kChallengeSizes.length);
      expect(find.text('Updated 5'), findsOneWidget);
      expect(find.text('Podium 5'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('reprise de l’application : actualisation du classement', (
    tester,
  ) async {
    final api = _Api();
    await _mount(tester, api);
    final calls = api.calls;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    api.prefix = 'Resumed';
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(api.calls, calls + kChallengeSizes.length);
    expect(find.text('Resumed 5'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('aucun score : accueil toujours utilisable', (tester) async {
    await _mount(tester, _Api(empty: true));
    expect(find.textContaining("Aucun score aujourd'hui"), findsNothing);
    expect(find.byKey(const ValueKey('home-daily-tops')), findsNothing);
    expect(find.byKey(const ValueKey('home-play')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
