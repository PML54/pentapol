// Modified: 2026-08-31 17:00 — suppression de la difficulté : CurrentGame.solutionCount devient
//           nullable() (null hors 6×10) ; schemaVersion 2 → 3 (réécriture destructive, pas de
//           migration — l'app n'est pas publiée, règle n°6). saveCurrentGame prend un int?.
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
  IntColumn get solutionCount => integer().nullable()(); // repris de PentoscopePuzzle (null hors 6×10)
  TextColumn get placedPieces => text()();      // JSON : [{id,pos,x,y}, …]
  TextColumn get positionIndices => text()();   // JSON : {pieceId: orientation}
  IntColumn get elapsedSeconds => integer()();
  IntColumn get isometryCount => integer()();
  IntColumn get translationCount => integer()();
  IntColumn get deleteCount => integer()();
  IntColumn get hintCount => integer()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Rectangles complets : une ligne par SOLUTION DÉCOUVERTE. Voir PLAN_PERSISTANCE §4.1.
/// board en clé dès maintenant : la solution n° 5 du 6×10 et celle du 5×12 ne se confondent pas.
class SolvedSolutions extends Table {
  TextColumn get board => text()();                 // '6x10', '5x12', '4x15'
  IntColumn get solutionNumber => integer()();      // 1..9356 pour le 6×10
  IntColumn get timesSolved => integer().withDefault(const Constant(1))();
  IntColumn get bestTimeSeconds => integer()();
  IntColumn get bestActions => integer().nullable()();
  DateTimeColumn get firstSolvedAt => dateTime()();
  DateTimeColumn get lastSolvedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {board, solutionNumber};
}

/// Puzzles à pièces tirées : pas de numéro de solution, un agrégat par taille.
class PuzzleStats extends Table {
  TextColumn get sizeName => text()();               // 'size4x5'
  IntColumn get completed => integer().withDefault(const Constant(0))();
  IntColumn get bestTimeSeconds => integer().nullable()();

  @override
  Set<Column> get primaryKey => {sizeName};
}


// ✨ MAINTENANT la classe (après la fonction et les tables)
@DriftDatabase(tables: [Settings, CurrentGame, SolvedSolutions, PuzzleStats])
class SettingsDatabase extends _$SettingsDatabase {
  // ✨ CORRECTION: super(_openConnection()) au lieu de super._openConnection()
  SettingsDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // 2 → 3 : CurrentGame.solutionCount devient nullable.

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

  /// Enregistre une solution découverte sur un rectangle complet. Upsert : incrémente
  /// `timesSolved`, ne garde que le meilleur temps et le meilleur nombre d'actions.
  Future<void> recordSolvedSolution({
    required String board,
    required int solutionNumber,
    required int timeSeconds,
    int? actions,
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
          bestTimeSeconds: timeSeconds,
          bestActions: Value(actions),
          firstSolvedAt: now,
          lastSolvedAt: now,
        ),
      );
    } else {
      final bestActions = (existing.bestActions == null)
          ? actions
          : (actions == null
              ? existing.bestActions
              : (actions < existing.bestActions! ? actions : existing.bestActions));
      await (update(solvedSolutions)
            ..where((s) =>
                s.board.equals(board) & s.solutionNumber.equals(solutionNumber)))
          .write(
        SolvedSolutionsCompanion(
          timesSolved: Value(existing.timesSolved + 1),
          bestTimeSeconds: Value(
              timeSeconds < existing.bestTimeSeconds ? timeSeconds : existing.bestTimeSeconds),
          bestActions: Value(bestActions),
          lastSolvedAt: Value(now),
        ),
      );
    }
  }

  /// Enregistre la complétion d'un puzzle à pièces tirées (pas de numéro de solution).
  /// Upsert : incrémente `completed`, ne garde que le meilleur temps.
  Future<void> recordPuzzleCompleted({
    required String sizeName,
    required int timeSeconds,
  }) async {
    final existing = await (select(puzzleStats)
          ..where((s) => s.sizeName.equals(sizeName)))
        .getSingleOrNull();

    if (existing == null) {
      await into(puzzleStats).insert(
        PuzzleStatsCompanion.insert(
          sizeName: sizeName,
          completed: const Value(1),
          bestTimeSeconds: Value(timeSeconds),
        ),
      );
    } else {
      final best = (existing.bestTimeSeconds == null || timeSeconds < existing.bestTimeSeconds!)
          ? timeSeconds
          : existing.bestTimeSeconds;
      await (update(puzzleStats)..where((s) => s.sizeName.equals(sizeName))).write(
        PuzzleStatsCompanion(
          completed: Value(existing.completed + 1),
          bestTimeSeconds: Value(best),
        ),
      );
    }
  }

  // ============================================================================
  // CURRENT GAME - la partie en cours (une seule ligne, id 0, écrasée)
  // ============================================================================

  /// Écrit la partie en cours (upsert sur la ligne unique). Les listes sont
  /// sérialisées en JSON par l'appelant (PLAN_PERSISTANCE §2.1).
  Future<void> saveCurrentGame({
    required String sizeName,
    required String pieceIds,
    required int? solutionCount,
    required String placedPieces,
    required String positionIndices,
    required int elapsedSeconds,
    required int isometryCount,
    required int translationCount,
    required int deleteCount,
    required int hintCount,
  }) async {
    await into(currentGame).insertOnConflictUpdate(
      CurrentGameCompanion.insert(
        sizeName: sizeName,
        pieceIds: pieceIds,
        solutionCount: Value(solutionCount),
        placedPieces: placedPieces,
        positionIndices: positionIndices,
        elapsedSeconds: elapsedSeconds,
        isometryCount: isometryCount,
        translationCount: translationCount,
        deleteCount: deleteCount,
        hintCount: hintCount,
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