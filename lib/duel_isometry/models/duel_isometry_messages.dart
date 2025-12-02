// lib/duel_isometry/models/duel_isometry_messages.dart
// Messages WebSocket pour le mode Duel Isométries

import 'dart:convert';

// ============================================================================
// CLASSE DE BASE
// ============================================================================

/// Message client → serveur
abstract class ClientMessage {
  String get type;
  Map<String, dynamic> toJson();

  String encode() => jsonEncode({'type': type, ...toJson()});
}

/// Message serveur → client
abstract class ServerMessage {
  String get type;

  factory ServerMessage.decode(String data) {
    final json = jsonDecode(data) as Map<String, dynamic>;
    final type = json['type'] as String;

    return switch (type) {
    // Room management
      'room_created' => RoomCreatedMessage.fromJson(json),
      'room_joined' => RoomJoinedMessage.fromJson(json),
      'player_joined' => PlayerJoinedMessage.fromJson(json),
      'player_left' => PlayerLeftMessage.fromJson(json),

    // Game flow
      'puzzle_ready' => PuzzleReadyMessage.fromJson(json),
      'countdown' => CountdownMessage.fromJson(json),
      'round_start' => RoundStartMessage.fromJson(json),

    // Gameplay
      'piece_placed' => PiecePlacedMessage.fromJson(json),
      'placement_rejected' => PlacementRejectedMessage.fromJson(json),
      'opponent_progress' => OpponentProgressMessage.fromJson(json),
      'player_completed' => PlayerCompletedMessage.fromJson(json),

    // Results
      'round_result' => RoundResultMessage.fromJson(json),
      'match_result' => MatchResultMessage.fromJson(json),

    // Errors
      'error' => ErrorMessage.fromJson(json),

      _ => UnknownMessage(type, json),
    };
  }
}

// ============================================================================
// MESSAGES CLIENT → SERVEUR
// ============================================================================

/// Créer une room
class CreateRoomMessage extends ClientMessage {
  final String playerName;
  final String gameMode = 'isometry'; // Différencie du duel classique

  CreateRoomMessage({required this.playerName});

  @override
  String get type => 'create_room';

  @override
  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'gameMode': gameMode,
  };
}

/// Rejoindre une room
class JoinRoomMessage extends ClientMessage {
  final String roomCode;
  final String playerName;

  JoinRoomMessage({required this.roomCode, required this.playerName});

  @override
  String get type => 'join_room';

  @override
  Map<String, dynamic> toJson() => {
    'roomCode': roomCode,
    'playerName': playerName,
  };
}

/// Quitter la room
class LeaveRoomMessage extends ClientMessage {
  @override
  String get type => 'leave_room';

  @override
  Map<String, dynamic> toJson() => {};
}

/// Joueur prêt
class PlayerReadyMessage extends ClientMessage {
  @override
  String get type => 'player_ready';

  @override
  Map<String, dynamic> toJson() => {};
}

/// Placer une pièce
class PlacePieceMessage extends ClientMessage {
  final int pieceId;
  final int gridX;
  final int gridY;
  final int positionIndex;

  PlacePieceMessage({
    required this.pieceId,
    required this.gridX,
    required this.gridY,
    required this.positionIndex,
  });

  @override
  String get type => 'place_piece';

  @override
  Map<String, dynamic> toJson() => {
    'pieceId': pieceId,
    'gridX': gridX,
    'gridY': gridY,
    'positionIndex': positionIndex,
  };
}

/// Notifier une isométrie appliquée
class IsometryAppliedMessage extends ClientMessage {
  final int pieceId;
  final String operation; // "R", "L", "H", "V"
  final int newPositionIndex;

  IsometryAppliedMessage({
    required this.pieceId,
    required this.operation,
    required this.newPositionIndex,
  });

  @override
  String get type => 'isometry_applied';

  @override
  Map<String, dynamic> toJson() => {
    'pieceId': pieceId,
    'operation': operation,
    'newPositionIndex': newPositionIndex,
  };
}

/// Mettre à jour sa progression
class UpdateProgressMessage extends ClientMessage {
  final int placedPieces;
  final int isometryCount;

  UpdateProgressMessage({
    required this.placedPieces,
    required this.isometryCount,
  });

  @override
  String get type => 'update_progress';

  @override
  Map<String, dynamic> toJson() => {
    'placedPieces': placedPieces,
    'isometryCount': isometryCount,
  };
}

/// Puzzle complété
class PuzzleCompletedMessage extends ClientMessage {
  final int totalIsometries;
  final int timeMs;

  PuzzleCompletedMessage({
    required this.totalIsometries,
    required this.timeMs,
  });

  @override
  String get type => 'puzzle_completed';

  @override
  Map<String, dynamic> toJson() => {
    'totalIsometries': totalIsometries,
    'timeMs': timeMs,
  };
}

// ============================================================================
// MESSAGES SERVEUR → CLIENT
// ============================================================================

/// Room créée
class RoomCreatedMessage implements ServerMessage {
  @override
  String get type => 'room_created';

  final String roomCode;
  final String playerId;

  RoomCreatedMessage({required this.roomCode, required this.playerId});

  factory RoomCreatedMessage.fromJson(Map<String, dynamic> json) {
    return RoomCreatedMessage(
      roomCode: json['roomCode'] as String,
      playerId: json['playerId'] as String,
    );
  }
}

/// Room rejointe
class RoomJoinedMessage implements ServerMessage {
  @override
  String get type => 'room_joined';

  final String roomCode;
  final String playerId;
  final String? opponentId;
  final String? opponentName;

  RoomJoinedMessage({
    required this.roomCode,
    required this.playerId,
    this.opponentId,
    this.opponentName,
  });

  factory RoomJoinedMessage.fromJson(Map<String, dynamic> json) {
    return RoomJoinedMessage(
      roomCode: json['roomCode'] as String,
      playerId: json['playerId'] as String,
      opponentId: json['opponentId'] as String?,
      opponentName: json['opponentName'] as String?,
    );
  }
}

/// Joueur rejoint
class PlayerJoinedMessage implements ServerMessage {
  @override
  String get type => 'player_joined';

  final String playerId;
  final String playerName;

  PlayerJoinedMessage({required this.playerId, required this.playerName});

  factory PlayerJoinedMessage.fromJson(Map<String, dynamic> json) {
    return PlayerJoinedMessage(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
    );
  }
}

/// Joueur parti
class PlayerLeftMessage implements ServerMessage {
  @override
  String get type => 'player_left';

  final String playerId;

  PlayerLeftMessage({required this.playerId});

  factory PlayerLeftMessage.fromJson(Map<String, dynamic> json) {
    return PlayerLeftMessage(
      playerId: json['playerId'] as String,
    );
  }
}

/// Puzzle prêt (envoyé aux deux joueurs)
class PuzzleReadyMessage implements ServerMessage {
  @override
  String get type => 'puzzle_ready';

  final int roundNumber;
  final int totalRounds;
  final int seed;
  final int width;
  final int height;
  final List<PuzzlePieceData> pieces;
  final int optimalIsometries;

  PuzzleReadyMessage({
    required this.roundNumber,
    required this.totalRounds,
    required this.seed,
    required this.width,
    required this.height,
    required this.pieces,
    required this.optimalIsometries,
  });

  factory PuzzleReadyMessage.fromJson(Map<String, dynamic> json) {
    return PuzzleReadyMessage(
      roundNumber: json['roundNumber'] as int,
      totalRounds: json['totalRounds'] as int,
      seed: json['seed'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
      pieces: (json['pieces'] as List)
          .map((p) => PuzzlePieceData.fromJson(p as Map<String, dynamic>))
          .toList(),
      optimalIsometries: json['optimalIsometries'] as int,
    );
  }
}

/// Données d'une pièce dans le puzzle
class PuzzlePieceData {
  final int pieceId;
  final String pieceName;
  final int targetGridX;
  final int targetGridY;
  final int targetPositionIndex;
  final int initialPositionIndex;
  final int minIsometries;

  const PuzzlePieceData({
    required this.pieceId,
    required this.pieceName,
    required this.targetGridX,
    required this.targetGridY,
    required this.targetPositionIndex,
    required this.initialPositionIndex,
    required this.minIsometries,
  });

  factory PuzzlePieceData.fromJson(Map<String, dynamic> json) {
    return PuzzlePieceData(
      pieceId: json['pieceId'] as int,
      pieceName: json['pieceName'] as String,
      targetGridX: json['targetGridX'] as int,
      targetGridY: json['targetGridY'] as int,
      targetPositionIndex: json['targetPositionIndex'] as int,
      initialPositionIndex: json['initialPositionIndex'] as int,
      minIsometries: json['minIsometries'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'pieceId': pieceId,
    'pieceName': pieceName,
    'targetGridX': targetGridX,
    'targetGridY': targetGridY,
    'targetPositionIndex': targetPositionIndex,
    'initialPositionIndex': initialPositionIndex,
    'minIsometries': minIsometries,
  };
}

/// Countdown
class CountdownMessage implements ServerMessage {
  @override
  String get type => 'countdown';

  final int value;

  CountdownMessage({required this.value});

  factory CountdownMessage.fromJson(Map<String, dynamic> json) {
    return CountdownMessage(value: json['value'] as int);
  }
}

/// Début du round
class RoundStartMessage implements ServerMessage {
  @override
  String get type => 'round_start';

  final int roundNumber;
  final int timestamp;

  RoundStartMessage({required this.roundNumber, required this.timestamp});

  factory RoundStartMessage.fromJson(Map<String, dynamic> json) {
    return RoundStartMessage(
      roundNumber: json['roundNumber'] as int,
      timestamp: json['timestamp'] as int,
    );
  }
}

/// Pièce placée (broadcast)
class PiecePlacedMessage implements ServerMessage {
  @override
  String get type => 'piece_placed';

  final String playerId;
  final String playerName;
  final int pieceId;
  final int gridX;
  final int gridY;
  final int positionIndex;
  final bool isCorrect;

  PiecePlacedMessage({
    required this.playerId,
    required this.playerName,
    required this.pieceId,
    required this.gridX,
    required this.gridY,
    required this.positionIndex,
    required this.isCorrect,
  });

  factory PiecePlacedMessage.fromJson(Map<String, dynamic> json) {
    return PiecePlacedMessage(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      pieceId: json['pieceId'] as int,
      gridX: json['gridX'] as int,
      gridY: json['gridY'] as int,
      positionIndex: json['positionIndex'] as int,
      isCorrect: json['isCorrect'] as bool? ?? true,
    );
  }
}

/// Placement refusé
class PlacementRejectedMessage implements ServerMessage {
  @override
  String get type => 'placement_rejected';

  final String reason;

  PlacementRejectedMessage({required this.reason});

  factory PlacementRejectedMessage.fromJson(Map<String, dynamic> json) {
    return PlacementRejectedMessage(
      reason: json['reason'] as String,
    );
  }

  String get reasonText => switch (reason) {
    'wrong_position' => 'Mauvaise position !',
    'wrong_orientation' => 'Mauvaise orientation !',
    'already_placed' => 'Pièce déjà placée',
    'out_of_bounds' => 'Hors du plateau',
    _ => reason,
  };
}

/// Progression adversaire
class OpponentProgressMessage implements ServerMessage {
  @override
  String get type => 'opponent_progress';

  final int placedPieces;
  final int isometryCount;

  OpponentProgressMessage({
    required this.placedPieces,
    required this.isometryCount,
  });

  factory OpponentProgressMessage.fromJson(Map<String, dynamic> json) {
    return OpponentProgressMessage(
      placedPieces: json['placedPieces'] as int,
      isometryCount: json['isometryCount'] as int,
    );
  }
}

/// Un joueur a terminé
class PlayerCompletedMessage implements ServerMessage {
  @override
  String get type => 'player_completed';

  final String playerId;
  final String playerName;
  final int totalIsometries;
  final int timeMs;

  PlayerCompletedMessage({
    required this.playerId,
    required this.playerName,
    required this.totalIsometries,
    required this.timeMs,
  });

  factory PlayerCompletedMessage.fromJson(Map<String, dynamic> json) {
    return PlayerCompletedMessage(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      totalIsometries: json['totalIsometries'] as int,
      timeMs: json['timeMs'] as int,
    );
  }
}

/// Résultat du round
class RoundResultMessage implements ServerMessage {
  @override
  String get type => 'round_result';

  final int roundNumber;
  final String? winnerId;
  final String? winnerName;
  final String winReason; // "fewer_isometries", "faster", "opponent_quit"

  final PlayerRoundStats player1Stats;
  final PlayerRoundStats player2Stats;

  final int player1Score;
  final int player2Score;

  final int optimalIsometries;

  RoundResultMessage({
    required this.roundNumber,
    this.winnerId,
    this.winnerName,
    required this.winReason,
    required this.player1Stats,
    required this.player2Stats,
    required this.player1Score,
    required this.player2Score,
    required this.optimalIsometries,
  });

  factory RoundResultMessage.fromJson(Map<String, dynamic> json) {
    return RoundResultMessage(
      roundNumber: json['roundNumber'] as int,
      winnerId: json['winnerId'] as String?,
      winnerName: json['winnerName'] as String?,
      winReason: json['winReason'] as String? ?? 'unknown',
      player1Stats:
      PlayerRoundStats.fromJson(json['player1Stats'] as Map<String, dynamic>),
      player2Stats:
      PlayerRoundStats.fromJson(json['player2Stats'] as Map<String, dynamic>),
      player1Score: json['player1Score'] as int,
      player2Score: json['player2Score'] as int,
      optimalIsometries: json['optimalIsometries'] as int,
    );
  }
}

/// Stats d'un joueur pour un round
class PlayerRoundStats {
  final String playerId;
  final String playerName;
  final int isometries;
  final int timeMs;
  final bool completed;

  const PlayerRoundStats({
    required this.playerId,
    required this.playerName,
    required this.isometries,
    required this.timeMs,
    required this.completed,
  });

  factory PlayerRoundStats.fromJson(Map<String, dynamic> json) {
    return PlayerRoundStats(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      isometries: json['isometries'] as int,
      timeMs: json['timeMs'] as int,
      completed: json['completed'] as bool? ?? false,
    );
  }

  double efficiencyPercent(int optimal) {
    if (isometries == 0) return optimal == 0 ? 100.0 : 0.0;
    return (optimal / isometries * 100).clamp(0.0, 100.0);
  }
}

/// Résultat final du match
class MatchResultMessage implements ServerMessage {
  @override
  String get type => 'match_result';

  final String? winnerId;
  final String? winnerName;
  final int player1FinalScore;
  final int player2FinalScore;

  MatchResultMessage({
    this.winnerId,
    this.winnerName,
    required this.player1FinalScore,
    required this.player2FinalScore,
  });

  factory MatchResultMessage.fromJson(Map<String, dynamic> json) {
    return MatchResultMessage(
      winnerId: json['winnerId'] as String?,
      winnerName: json['winnerName'] as String?,
      player1FinalScore: json['player1FinalScore'] as int,
      player2FinalScore: json['player2FinalScore'] as int,
    );
  }
}

/// Erreur
class ErrorMessage implements ServerMessage {
  @override
  String get type => 'error';

  final String code;
  final String message;

  ErrorMessage({required this.code, required this.message});

  factory ErrorMessage.fromJson(Map<String, dynamic> json) {
    return ErrorMessage(
      code: json['code'] as String? ?? 'unknown',
      message: json['message'] as String? ?? 'Erreur inconnue',
    );
  }
}

/// Message inconnu
class UnknownMessage implements ServerMessage {
  @override
  final String type;
  final Map<String, dynamic> data;

  UnknownMessage(this.type, this.data);
}