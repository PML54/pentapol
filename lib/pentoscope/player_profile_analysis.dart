// Modified: 2026-09-30 07:10 — calculer rapidité et indicateurs sur tentatives terminées ou non.
// lib/pentoscope/player_profile_analysis.dart

import 'package:pentapol/models/app_settings.dart';

class PlayerProfileAnalysis {
  final int attempts;
  final int completed;
  final int cleanCompleted;
  final int totalFaults;
  final int firstPlacements;
  final int safeFirstPlacements;
  final List<int> cleanCompletionTimes;

  const PlayerProfileAnalysis({
    required this.attempts,
    required this.completed,
    required this.cleanCompleted,
    required this.totalFaults,
    required this.firstPlacements,
    required this.safeFirstPlacements,
    required this.cleanCompletionTimes,
  });

  factory PlayerProfileAnalysis.forSize(
    String sizeName,
    Iterable<PlayerAttemptSummary> history,
  ) {
    final attempts = history
        .where((attempt) => attempt.sizeName == sizeName)
        .toList();
    final cleanTimes = [
      for (final attempt in attempts)
        if (attempt.completed && attempt.clean) attempt.elapsedSeconds,
    ];
    final firstPlacements = attempts
        .where(
          (attempt) =>
              attempt.firstPlacementSolvable != null &&
              !attempt.firstPlacementAssisted,
        )
        .toList();
    return PlayerProfileAnalysis(
      attempts: attempts.length,
      completed: attempts.where((attempt) => attempt.completed).length,
      cleanCompleted: cleanTimes.length,
      totalFaults: attempts.fold(0, (sum, attempt) => sum + attempt.faults),
      firstPlacements: firstPlacements.length,
      safeFirstPlacements: firstPlacements
          .where((attempt) => attempt.firstPlacementSolvable == true)
          .length,
      cleanCompletionTimes: List.unmodifiable(cleanTimes),
    );
  }

  int? get bestSeconds => cleanCompletionTimes.isEmpty
      ? null
      : cleanCompletionTimes.reduce((a, b) => a < b ? a : b);

  int? get recentMedian {
    if (cleanCompletionTimes.isEmpty) return null;
    final start = cleanCompletionTimes.length > 10
        ? cleanCompletionTimes.length - 10
        : 0;
    return _median(cleanCompletionTimes.sublist(start));
  }

  int? get previousMedian {
    if (cleanCompletionTimes.length < 20) return null;
    return _median(
      cleanCompletionTimes.sublist(
        cleanCompletionTimes.length - 20,
        cleanCompletionTimes.length - 10,
      ),
    );
  }

  /// Positif = plus rapide récemment, négatif = plus lent.
  int? get speedTrendPercent {
    final previous = previousMedian;
    final recent = recentMedian;
    if (previous == null || recent == null || previous == 0) return null;
    return (((previous - recent) / previous) * 100).round();
  }

  double? get faultsPerAttempt => attempts == 0 ? null : totalFaults / attempts;

  int? get initialAnticipationScore => firstPlacements == 0
      ? null
      : (safeFirstPlacements / firstPlacements * 1000).round();

  static int _median(List<int> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return ((sorted[middle - 1] + sorted[middle]) / 2).round();
  }
}
