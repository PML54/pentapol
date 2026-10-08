// Modified: 2026-10-07 07:40 — conserver le minimum théorique du défi unique pour la liste.
// Historique: 2026-10-07 06:53 — défis version 3 avec pièces fixes et une solution exacte commune.
// Historique: 2026-10-07 01:46 — prochain minuit UTC pour annoncer le changement de défis.
// Historique: 2026-10-06 04:48 — retirer le minimum global, désormais propre à chaque solution finale.
// Historique: 2026-10-06 04:16 — conserver le minimum théorique calculé avant le défi.
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/pentapol_rng.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';

/// Toute modification de la derivation doit incrementer cette version.
const int kChallengeVersion = 3;

final DateTime kChallengeEpoch = DateTime.utc(2026, 1, 1);

/// Progression quotidienne, de la plus petite grille au 6x10.
const List<PentoscopeSize> kChallengeSizes = PentoscopeSize.values;

String challengeDay([DateTime? now]) {
  final utc = (now ?? DateTime.now()).toUtc();
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}';
}

/// Instant (UTC) où [challengeDay] change : le prochain minuit UTC, strictement
/// après [now]. À afficher en heure locale (`toLocal()`).
DateTime nextChallengeChange([DateTime? now]) {
  final utc = (now ?? DateTime.now()).toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day + 1);
}

int daysSinceEpoch(DateTime now) {
  final utc = now.toUtc();
  final date = DateTime.utc(utc.year, utc.month, utc.day);
  final days = date.difference(kChallengeEpoch).inDays;
  return days < 0 ? 0 : days;
}

int challengeSeed(int version, int day, int sizeIndex) {
  var h = 0x811c9dc5;
  for (final value in [version, day, sizeIndex]) {
    h = (h ^ (value & 0xffffffff)) & 0xffffffff;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

class ChallengeDefinition {
  final int? theoreticalMoves;
  final List<PlacedPiece> fixedPieces;
  int get playablePieceCount => pieceIds.length - fixedPieces.length;
  final String day;
  final int dayIndex;
  final PentoscopeSize size;
  final int mask;
  final int solutionCount;
  final List<int> pieceIds;
  final Map<int, int> orientations;

  const ChallengeDefinition({
    this.theoreticalMoves,
    this.fixedPieces = const [],
    required this.day,
    required this.dayIndex,
    required this.size,
    required this.mask,
    required this.solutionCount,
    required this.pieceIds,
    required this.orientations,
  });
}

ChallengeDefinition deriveChallenge({
  required DateTime date,
  required PentoscopeSize size,
  required List<int> solubleMasks,
  required int Function(int mask) solutionCountForMask,
}) {
  final dayIndex = daysSinceEpoch(date);
  final rng = PentapolRng(
    challengeSeed(kChallengeVersion, dayIndex, size.index),
  );
  final mask = size == PentoscopeSize.size6x10
      ? 0xFFF
      : solubleMasks[rng.nextInt(solubleMasks.length)];
  final pieceIds = <int>[
    for (int id = 1; id <= 12; id++)
      if (mask & (1 << (id - 1)) != 0) id,
  ];
  final orientations = <int, int>{
    for (final id in pieceIds)
      id: rng.nextInt(pentominos[id - 1].numOrientations),
  };

  return ChallengeDefinition(
    day: challengeDay(date),
    dayIndex: dayIndex,
    size: size,
    mask: mask,
    solutionCount: size == PentoscopeSize.size6x10
        ? 9356
        : solutionCountForMask(mask),
    pieceIds: pieceIds,
    orientations: orientations,
  );
}
