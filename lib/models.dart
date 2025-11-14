class Race {
  final String id;
  final String puzzleId;
  final String createdBy;
  final String status;
  Race({required this.id, required this.puzzleId, required this.createdBy, required this.status});
  factory Race.fromJson(Map<String, dynamic> j) => Race(
    id: j['id'] as String,
    puzzleId: j['puzzle_id'] as String,
    createdBy: j['created_by'] as String,
    status: j['status'] as String,
  );
}
class RaceResult {
  final String playerId;
  final int elapsedMs;
  final int piecesPlaced;
  final DateTime finishedAt;

  RaceResult({
    required this.playerId,
    required this.elapsedMs,
    required this.piecesPlaced,
    required this.finishedAt,
  });

  factory RaceResult.fromJson(Map<String, dynamic> j) => RaceResult(
    playerId: j['player_id'] as String,
    elapsedMs: j['elapsed_ms'] as int,
    piecesPlaced: j['pieces_placed'] as int,
    finishedAt: DateTime.parse(j['finished_at'] as String),
  );
}
