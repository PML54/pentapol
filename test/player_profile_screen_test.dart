// Modified: 2026-09-30 07:39 — vérifier le bilan de rapidité réduit à la tendance.
// test/player_profile_screen_test.dart
// Historique: 2026-09-30 07:37 — vérifier le bilan de rapidité sans record ni volume.
// Historique: 2026-09-30 07:27 — vérifier l'acuité visible tronquée à 99 %.
// Historique: 2026-09-30 07:10 — vérifier l'affichage rapidité et tentatives du profil joueur.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/screens/records_screen.dart';
import 'package:pentapol/providers/settings_provider.dart';

PlayerAttemptSummary _attempt({
  String sizeName = 'size4x5',
  required bool completed,
  required int seconds,
  required int faults,
  required bool firstSolvable,
}) => PlayerAttemptSummary(
  sizeName: sizeName,
  completed: completed,
  elapsedSeconds: seconds,
  faults: faults,
  isometries: 2,
  translations: 1,
  removals: 0,
  hints: 0,
  placedPieces: completed ? 4 : 1,
  firstPieceId: 2,
  firstPlacementSolvable: firstSolvable,
  endedAt: '2026-09-30T07:10:00Z',
);

void main() {
  testWidgets('le profil sépare vitesse réussie et analyses de tentatives', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = SettingsDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.setSetting(
      'app_settings',
      jsonEncode(
        AppSettings(
          pieceAcuityTotals: const {
            2: PieceAcuityTotals(
              placements: 1,
              theoretical: 9999,
              actual: 10000,
            ),
          },
          attemptHistory: [
            for (var i = 0; i < 10; i++)
              _attempt(
                sizeName: 'size3x5',
                completed: true,
                seconds: 120,
                faults: 0,
                firstSolvable: true,
              ),
            for (var i = 0; i < 10; i++)
              _attempt(
                sizeName: 'size3x5',
                completed: true,
                seconds: 100,
                faults: 0,
                firstSolvable: true,
              ),
            _attempt(
              completed: true,
              seconds: 100,
              faults: 4,
              firstSolvable: true,
            ),
            _attempt(
              completed: false,
              seconds: 20,
              faults: 1,
              firstSolvable: false,
            ),
          ],
        ).toJson(),
      ),
    );
    await db.recordPuzzleCompleted(
      sizeName: 'size4x5',
      minIso: 2,
      isoCount: 3,
      faults: 4,
      timeSeconds: 100,
      clean: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RecordsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rapidité de résolution'), findsOneWidget);
    expect(find.text('17 % plus rapide'), findsOneWidget);
    expect(find.textContaining('Médiane'), findsNothing);
    expect(find.text('Record'), findsNothing);
    expect(find.textContaining('partie observée'), findsNothing);
    expect(find.textContaining('parties observées'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('1/2 terminées'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('1/2 terminées'), findsOneWidget);
    expect(find.textContaining('1/2 viables'), findsOneWidget);
    expect(find.text('2,5 impasses / tentative'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('99 %'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('99 %'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
