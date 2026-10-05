// Modified: 2026-10-05 07:43 — vérifier la persistance JSON des scores de défi en attente.
// Historique: 2026-09-30 07:10 — vérifier analyses, persistance et historique borné des tentatives.
// test/player_profile_analysis_test.dart

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/player_profile_analysis.dart';
import 'package:pentapol/providers/settings_provider.dart';

PlayerAttemptSummary _attempt({
  required int seconds,
  bool completed = true,
  int faults = 0,
  int hints = 0,
  bool? firstSolvable = true,
  bool firstAssisted = false,
}) => PlayerAttemptSummary(
  sizeName: 'size4x5',
  completed: completed,
  elapsedSeconds: seconds,
  faults: faults,
  isometries: 0,
  translations: 0,
  removals: 0,
  hints: hints,
  placedPieces: 1,
  firstPieceId: 2,
  firstPlacementSolvable: firstSolvable,
  firstPlacementAssisted: firstAssisted,
  endedAt: '2026-09-30T07:10:00Z',
);

void main() {
  test('la rapidité ignore fautes et tentatives non terminées', () {
    final analysis = PlayerProfileAnalysis.forSize('size4x5', [
      _attempt(seconds: 90, faults: 8),
      _attempt(seconds: 40, completed: false, faults: 1),
      _attempt(seconds: 30, faults: 0, hints: 1),
      _attempt(seconds: 110, faults: 0),
    ]);

    expect(analysis.attempts, 4);
    expect(analysis.completed, 3);
    expect(analysis.cleanCompleted, 2);
    expect(analysis.bestSeconds, 90);
    expect(analysis.recentMedian, 100);
    expect(analysis.totalFaults, 9);
  });

  test('la tendance compare dix réussites récentes aux dix précédentes', () {
    final history = [
      for (var i = 0; i < 10; i++) _attempt(seconds: 200),
      for (var i = 0; i < 10; i++) _attempt(seconds: 150),
    ];
    final analysis = PlayerProfileAnalysis.forSize('size4x5', history);

    expect(analysis.previousMedian, 200);
    expect(analysis.recentMedian, 150);
    expect(analysis.speedTrendPercent, 25);
  });

  test(
    'anticipation et impasses incluent les abandons mais pas un premier indice',
    () {
      final analysis = PlayerProfileAnalysis.forSize('size4x5', [
        _attempt(
          seconds: 20,
          completed: false,
          faults: 1,
          firstSolvable: false,
        ),
        _attempt(seconds: 80, firstSolvable: true),
        _attempt(seconds: 10, hints: 1, firstAssisted: true),
      ]);

      expect(analysis.firstPlacements, 2);
      expect(analysis.safeFirstPlacements, 1);
      expect(analysis.initialAnticipationScore, 500);
      expect(analysis.faultsPerAttempt, closeTo(1 / 3, 1e-10));
    },
  );

  test('historique des tentatives survit au JSON AppSettings', () {
    final settings = AppSettings(
      attemptHistory: [_attempt(seconds: 75, completed: false, faults: 2)],
    );
    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.attemptHistory, hasLength(1));
    expect(restored.attemptHistory.single.completed, isFalse);
    expect(restored.attemptHistory.single.faults, 2);
    expect(restored.attemptHistory.single.firstPieceId, 2);
  });

  test('scores de défi en attente survivent au JSON AppSettings', () {
    const score = PendingChallengeScore(
      version: 2,
      day: '2026-10-05',
      size: 3,
      playerId: '0123456789abcdef0123456789abcdef',
      pseudo: 'Paul',
      minIso: 4,
      isoCount: 5,
      faults: 1,
      timeMs: 123000,
      moves: 8,
      grid: '1,1,1,1,1',
    );
    const settings = AppSettings(pendingChallengeScores: [score]);
    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.pendingChallengeScores, hasLength(1));
    expect(restored.pendingChallengeScores.single.toJson(), score.toJson());
  });

  test(
    'la persistance garde les vingt dernières tentatives de chaque taille',
    () async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [settingsDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final notifier = container.read(settingsProvider.notifier);
      await notifier.ensureLoaded();

      for (var seconds = 1; seconds <= 21; seconds++) {
        await notifier.recordPlayerAttempt(_attempt(seconds: seconds));
      }
      await notifier.recordPlayerAttempt(
        PlayerAttemptSummary(
          sizeName: 'size5x5',
          completed: false,
          elapsedSeconds: 8,
          faults: 0,
          isometries: 1,
          translations: 0,
          removals: 0,
          hints: 0,
          placedPieces: 0,
          endedAt: '2026-09-30T07:10:00Z',
        ),
      );

      final history = container.read(settingsProvider).attemptHistory;
      final size4 = history
          .where((item) => item.sizeName == 'size4x5')
          .toList();
      expect(size4, hasLength(kAttemptHistoryPerSize));
      expect(size4.first.elapsedSeconds, 2);
      expect(size4.last.elapsedSeconds, 21);
      expect(history.where((item) => item.sizeName == 'size5x5'), hasLength(1));
    },
  );
}
