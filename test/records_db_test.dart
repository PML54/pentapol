// Modified: 2026-09-04 05:45 — création : test des records à trois bests indépendants (CDC §4.1).
//           Base drift en mémoire ; vérifie la mise à jour par dimension, la porte « clean », et
//           la comparaison d'acuité.
// test/records_db_test.dart

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';

void main() {
  late SettingsDatabase db;

  setUp(() => db = SettingsDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<PuzzleStat> completed({
    required int minIso,
    required int isoCount,
    required int moves,
    required int timeSeconds,
    required bool clean,
    int help = 0,
  }) async {
    await db.recordPuzzleCompleted(
      sizeName: 'size4x5',
      minIso: minIso,
      isoCount: isoCount,
      moves: moves,
      timeSeconds: timeSeconds,
      help: help,
      clean: clean,
    );
    return (db.select(db.puzzleStats)..where((s) => s.sizeName.equals('size4x5')))
        .getSingle();
  }

  test('première partie propre : pose tous les bests, completed=1', () async {
    final r = await completed(minIso: 2, isoCount: 5, moves: 6, timeSeconds: 100, clean: true);
    expect(r.completed, 1);
    expect(r.bestAcuityMinIso, 2);
    expect(r.bestAcuityIsoCount, 5);
    expect(r.bestMoves, 6);
    expect(r.bestTimeSeconds, 100);
  });

  test('partie avec aide : compte mais ne pose aucun record', () async {
    final r = await completed(minIso: 0, isoCount: 0, moves: 4, timeSeconds: 10, clean: false);
    expect(r.completed, 1);
    expect(r.bestAcuityMinIso, isNull);
    expect(r.bestMoves, isNull);
    expect(r.bestTimeSeconds, isNull);
  });

  test('chaque best évolue indépendamment', () async {
    // 1re : acuité 3/6, 8 coups, 200 s
    await completed(minIso: 2, isoCount: 5, moves: 8, timeSeconds: 200, clean: true);
    // 2e : acuité MEILLEURE (5/6 > 3/6), coups PIRES (10), temps PIRE (300)
    final r = await completed(minIso: 4, isoCount: 5, moves: 10, timeSeconds: 300, clean: true);
    expect(r.completed, 2);
    // acuité mise à jour (le nouveau ratio est meilleur)
    expect(r.bestAcuityMinIso, 4);
    expect(r.bestAcuityIsoCount, 5);
    // coups et temps NON dégradés
    expect(r.bestMoves, 8);
    expect(r.bestTimeSeconds, 200);
  });

  test('acuité : un ratio moins bon ne remplace pas', () async {
    await completed(minIso: 5, isoCount: 5, moves: 6, timeSeconds: 100, clean: true); // acuité 1.0
    final r = await completed(minIso: 1, isoCount: 5, moves: 6, timeSeconds: 100, clean: true); // 2/6
    expect(r.bestAcuityMinIso, 5); // inchangé (1.0 reste le meilleur)
    expect(r.bestAcuityIsoCount, 5);
  });

  test('meilleurs coups et temps sur des parties séparées', () async {
    await completed(minIso: 2, isoCount: 4, moves: 12, timeSeconds: 50, clean: true); // temps 50
    final r = await completed(minIso: 2, isoCount: 4, moves: 6, timeSeconds: 500, clean: true); // coups 6
    expect(r.bestMoves, 6); // meilleur coups de la 2e
    expect(r.bestTimeSeconds, 50); // meilleur temps de la 1re
  });

  test('bestHelp : garde le moins de sauvetages (maillot blanc)', () async {
    await completed(minIso: 2, isoCount: 3, moves: 6, timeSeconds: 80, clean: true, help: 3);
    var r = await (db.select(db.puzzleStats)..where((s) => s.sizeName.equals('size4x5')))
        .getSingle();
    expect(r.bestHelp, 3);
    r = await completed(minIso: 2, isoCount: 3, moves: 6, timeSeconds: 80, clean: true, help: 1);
    expect(r.bestHelp, 1); // amélioré
    r = await completed(minIso: 2, isoCount: 3, moves: 6, timeSeconds: 80, clean: true, help: 5);
    expect(r.bestHelp, 1); // pas dégradé
  });

  test('aide APRÈS une partie propre : ne dégrade pas les bests', () async {
    await completed(minIso: 2, isoCount: 3, moves: 6, timeSeconds: 80, clean: true);
    final r = await completed(minIso: 0, isoCount: 0, moves: 4, timeSeconds: 10, clean: false);
    expect(r.completed, 2);
    expect(r.bestMoves, 6); // l'aide, meilleure en apparence, est ignorée
    expect(r.bestTimeSeconds, 80);
  });
}
