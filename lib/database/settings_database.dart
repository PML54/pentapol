// Modified: 2026-09-04 05:45 — records perso B (CDC §4.1) : trois bests INDÉPENDANTS par
//           dimension (acuité = minIso+isoCount bruts §7.6, coups, temps), nullables (une partie
//           avec aide compte mais ne pose pas de record). schemaVersion 6 → 7 (bump + destructif).
// Historique: 2026-09-04 05:20 — records perso (CDC §4) : CurrentGame.initialOrientations (rack
//           distribué, JSON) pour que l'acuité d'une partie REPRISE reste calculable. schemaVersion
//           5 → 6 (bump + destructif, règle n°6).
// Historique: 2026-09-04 04:08 — reprise fidèle : CurrentGame.isProgression persisté (la progression
//           a atterri après la persistance ; sans lui, une partie reprise retombait à false et
//           « Jouer » la jetait). schemaVersion 4 → 5 (bump + destructif, règle n°6).
// Historique: 2026-08-31 18:00 — tirage par table (REFERENCE §8 A) : CurrentGame.solutionCount
//           REDEVIENT non-nullable (la table donne toujours un compte) — annule le nullable() du
//           matin. schemaVersion 3 → 4 : la colonne change encore, règle n°6 (bump + destructif ;
//           la v3 a tourné sur l'iPad, un retour à v2 serait un downgrade → crash).
// Historique: 2026-08-31 17:00 — suppression de la difficulté : solutionCount nullable, schemaVersion 3.
// Historique: 2026-08-30 12:05 — PLAN_PERSISTANCE §7 étape 4 : méthodes CurrentGame —
//           saveCurrentGame (upsert de la ligne unique), clearCurrentGame, loadCurrentGame.
// lib/database/settings_database.dart
// Historique: 2026-08-30 11:40 — étape 3 : recordSolvedSolution et recordPuzzleCompleted (records).
// Historique: 2026-08-30 11:10 — étape 2 : schéma. Tables mortes de l'ancien historique retirées ;
//             ajout de CurrentGame, SolvedSolutions, PuzzleStats ; schemaVersion 2 +
//             destructiveFallback.
// Historique: 2025-11-16 10:15:00 → 251226 — base SQLite Pentapol (Drift), version corrigée.

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'settings_database.g.dart';

// ✨ IMPORTANT: Cette fonction DOIT être AVANT la classe
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pentapol_settings.db'));
    return NativeDatabase(file);
  });
}

/// Table pour stocker les paramètres de l'application
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// La partie en cours — une seule ligne (id fixe 0), écrasée. Voir PLAN_PERSISTANCE §2.
/// Ne stocke ni le plateau (reconstruit depuis placedPieces) ni les solutions.
class CurrentGame extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))(); // ligne unique
  TextColumn get sizeName => text()();          // PentoscopeSize.name, ex. 'size6x10'
  TextColumn get pieceIds => text()();          // '1,2,3,…' — le tirage du puzzle
  IntColumn get solutionCount => integer()();   // repris de PentoscopePuzzle (toujours connu)
  TextColumn get placedPieces => text()();      // JSON : [{id,pos,x,y}, …]
  TextColumn get positionIndices => text()();   // JSON : {pieceId: orientation}
  IntColumn get elapsedSeconds => integer()();
  IntColumn get isometryCount => integer()();
  IntColumn get translationCount => integer()();
  IntColumn get deleteCount => integer()();
  IntColumn get hintCount => integer()();
  BoolColumn get isProgression =>
      boolean().withDefault(const Constant(false))(); // fait avancer le niveau
  TextColumn get initialOrientations =>
      text().withDefault(const Constant('{}'))(); // rack distribué, JSON (acuité §4.2)
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Rectangles complets : une ligne par SOLUTION DÉCOUVERTE. Voir PLAN_PERSISTANCE §4.1.
/// board en clé dès maintenant : la solution n° 5 du 6×10 et celle du 5×12 ne se confondent pas.
/// Trois bests INDÉPENDANTS (CDC §4.1) : ils peuvent venir de trois parties différentes. Le
/// maillot jaune stocke ses ingrédients bruts (minIso, isoCount) plutôt que le ratio (§7.6),
/// auditable et recomparable. Nullables : une partie AVEC AIDE compte (timesSolved) mais ne pose
/// aucun record (§4.8) — une solution peut donc exister sans best (tous résolus avec indice).
class SolvedSolutions extends Table {
  TextColumn get board => text()();                 // '6x10', '5x12', '4x15'
  IntColumn get solutionNumber => integer()();      // 1..9356 pour le 6×10
  IntColumn get timesSolved => integer().withDefault(const Constant(1))();
  IntColumn get bestAcuityMinIso => integer().nullable()();   // 🟡 minIso du meilleur score d'acuité
  IntColumn get bestAcuityIsoCount => integer().nullable()(); // 🟡 isométries de la même partie
  IntColumn get bestMoves => integer().nullable()();          // ⚫ coups (à pois)
  IntColumn get bestTimeSeconds => integer().nullable()();    // 🟢 temps (vert)
  DateTimeColumn get firstSolvedAt => dateTime()();
  DateTimeColumn get lastSolvedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {board, solutionNumber};
}

/// Puzzles à pièces tirées : pas de numéro de solution, un agrégat par taille. Mêmes trois bests
/// nullables que SolvedSolutions (CDC §4.1).
class PuzzleStats extends Table {
  TextColumn get sizeName => text()();               // 'size4x5'
  IntColumn get completed => integer().withDefault(const Constant(0))();
  IntColumn get bestAcuityMinIso => integer().nullable()();   // 🟡
  IntColumn get bestAcuityIsoCount => integer().nullable()(); // 🟡
  IntColumn get bestMoves => integer().nullable()();          // ⚫
  IntColumn get bestTimeSeconds => integer().nullable()();    // 🟢

  @override
  Set<Column> get primaryKey => {sizeName};
}


// ✨ MAINTENANT la classe (après la fonction et les tables)
@DriftDatabase(tables: [Settings, CurrentGame, SolvedSolutions, PuzzleStats])
class SettingsDatabase extends _$SettingsDatabase {
  // ✨ CORRECTION: super(_openConnection()) au lieu de super._openConnection()
  SettingsDatabase() : super(_openConnection());

  /// Constructeur de test : injecte un exécuteur (ex. `NativeDatabase.memory()`).
  SettingsDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 7; // 6 → 7 : records à trois bests indépendants (CDC §4.1)
  //                              (règle n°6 : bump + destructif).

  // ⚠️ Réécriture destructive : à tout changement de schemaVersion, drop + recrée toutes les
  // tables. L'app n'est pas publiée, il n'y a rien à migrer (PLAN_PERSISTANCE §5).
  // 🚨 À RETIRER avant la première soumission App Store — cf. docs/CHECKLIST_APPSTORE.md.
  @override
  MigrationStrategy get migration => destructiveFallback;

  // ============================================================================
  // SETTINGS - Paramètres de l'application (ancien code, intacte)
  // ============================================================================

  /// Récupère une valeur de paramètre
  Future<String?> getSetting(String key) async {
    final query = select(settings)..where((tbl) => tbl.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }

  /// Définit une valeur de paramètre
  Future<void> setSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(
        key: key,
        value: value,
      ),
    );
  }

  /// Supprime un paramètre
  Future<void> deleteSetting(String key) async {
    await (delete(settings)..where((tbl) => tbl.key.equals(key))).go();
  }

  /// Supprime tous les paramètres
  Future<void> clearAllSettings() async {
    await delete(settings).go();
  }

  // ============================================================================
  // RECORDS - SolvedSolutions (rectangles complets) / PuzzleStats (pièces tirées)
  // ============================================================================

  /// Acuité `(minIso+1)/(iso+1)` la plus GRANDE = la meilleure (CDC §4.2). Comparaison croisée
  /// (sans flottant). `true` si le nouveau score bat l'existant, ou s'il n'y a pas encore de best.
  bool _isBetterAcuity(int? bestMinIso, int? bestIso, int newMinIso, int newIso) {
    if (bestMinIso == null || bestIso == null) return true;
    return (newMinIso + 1) * (bestIso + 1) > (bestMinIso + 1) * (newIso + 1);
  }

  /// Enregistre une solution découverte sur un rectangle complet. Incrémente `timesSolved` ;
  /// met à jour **chaque** best indépendamment (acuité / coups / temps) — mais seulement si
  /// [clean] (partie sans aide, §4.8). Une partie avec aide compte sans poser de record.
  Future<void> recordSolvedSolution({
    required String board,
    required int solutionNumber,
    required int minIso,
    required int isoCount,
    required int moves,
    required int timeSeconds,
    required bool clean,
  }) async {
    final existing = await (select(solvedSolutions)
          ..where((s) =>
              s.board.equals(board) & s.solutionNumber.equals(solutionNumber)))
        .getSingleOrNull();
    final now = DateTime.now();

    if (existing == null) {
      await into(solvedSolutions).insert(
        SolvedSolutionsCompanion.insert(
          board: board,
          solutionNumber: solutionNumber,
          bestAcuityMinIso: Value(clean ? minIso : null),
          bestAcuityIsoCount: Value(clean ? isoCount : null),
          bestMoves: Value(clean ? moves : null),
          bestTimeSeconds: Value(clean ? timeSeconds : null),
          firstSolvedAt: now,
          lastSolvedAt: now,
        ),
      );
      return;
    }

    var companion = SolvedSolutionsCompanion(
      timesSolved: Value(existing.timesSolved + 1),
      lastSolvedAt: Value(now),
    );
    if (clean) {
      if (_isBetterAcuity(
          existing.bestAcuityMinIso, existing.bestAcuityIsoCount, minIso, isoCount)) {
        companion = companion.copyWith(
          bestAcuityMinIso: Value(minIso),
          bestAcuityIsoCount: Value(isoCount),
        );
      }
      if (existing.bestMoves == null || moves < existing.bestMoves!) {
        companion = companion.copyWith(bestMoves: Value(moves));
      }
      if (existing.bestTimeSeconds == null || timeSeconds < existing.bestTimeSeconds!) {
        companion = companion.copyWith(bestTimeSeconds: Value(timeSeconds));
      }
    }
    await (update(solvedSolutions)
          ..where((s) =>
              s.board.equals(board) & s.solutionNumber.equals(solutionNumber)))
        .write(companion);
  }

  /// Enregistre la complétion d'un puzzle à pièces tirées (pas de numéro de solution).
  /// Incrémente `completed` ; met à jour chaque best si [clean] (§4.8).
  Future<void> recordPuzzleCompleted({
    required String sizeName,
    required int minIso,
    required int isoCount,
    required int moves,
    required int timeSeconds,
    required bool clean,
  }) async {
    final existing = await (select(puzzleStats)
          ..where((s) => s.sizeName.equals(sizeName)))
        .getSingleOrNull();

    if (existing == null) {
      await into(puzzleStats).insert(
        PuzzleStatsCompanion.insert(
          sizeName: sizeName,
          completed: const Value(1),
          bestAcuityMinIso: Value(clean ? minIso : null),
          bestAcuityIsoCount: Value(clean ? isoCount : null),
          bestMoves: Value(clean ? moves : null),
          bestTimeSeconds: Value(clean ? timeSeconds : null),
        ),
      );
      return;
    }

    var companion = PuzzleStatsCompanion(completed: Value(existing.completed + 1));
    if (clean) {
      if (_isBetterAcuity(
          existing.bestAcuityMinIso, existing.bestAcuityIsoCount, minIso, isoCount)) {
        companion = companion.copyWith(
          bestAcuityMinIso: Value(minIso),
          bestAcuityIsoCount: Value(isoCount),
        );
      }
      if (existing.bestMoves == null || moves < existing.bestMoves!) {
        companion = companion.copyWith(bestMoves: Value(moves));
      }
      if (existing.bestTimeSeconds == null || timeSeconds < existing.bestTimeSeconds!) {
        companion = companion.copyWith(bestTimeSeconds: Value(timeSeconds));
      }
    }
    await (update(puzzleStats)..where((s) => s.sizeName.equals(sizeName))).write(companion);
  }

  // ============================================================================
  // CURRENT GAME - la partie en cours (une seule ligne, id 0, écrasée)
  // ============================================================================

  /// Écrit la partie en cours (upsert sur la ligne unique). Les listes sont
  /// sérialisées en JSON par l'appelant (PLAN_PERSISTANCE §2.1).
  Future<void> saveCurrentGame({
    required String sizeName,
    required String pieceIds,
    required int solutionCount,
    required String placedPieces,
    required String positionIndices,
    required int elapsedSeconds,
    required int isometryCount,
    required int translationCount,
    required int deleteCount,
    required int hintCount,
    required bool isProgression,
    required String initialOrientations,
  }) async {
    await into(currentGame).insertOnConflictUpdate(
      CurrentGameCompanion.insert(
        sizeName: sizeName,
        pieceIds: pieceIds,
        solutionCount: solutionCount,
        placedPieces: placedPieces,
        positionIndices: positionIndices,
        elapsedSeconds: elapsedSeconds,
        isometryCount: isometryCount,
        translationCount: translationCount,
        deleteCount: deleteCount,
        hintCount: hintCount,
        isProgression: Value(isProgression),
        initialOrientations: Value(initialOrientations),
        savedAt: DateTime.now(),
      ),
    );
  }

  /// Efface la partie en cours (complétion, ou démarrage d'une partie neuve).
  Future<void> clearCurrentGame() async {
    await delete(currentGame).go();
  }

  /// La partie en cours, ou `null` s'il n'y en a pas.
  Future<CurrentGameData?> loadCurrentGame() async {
    return (select(currentGame)..where((g) => g.id.equals(0))).getSingleOrNull();
  }

}