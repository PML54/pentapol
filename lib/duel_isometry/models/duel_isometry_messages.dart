// lib/duel_isometry/models/duel_isometry_messages.dart
// Messages WebSocket pour le mode Duel Isométries
// FORMAT SIMPLIFIÉ : Le serveur envoie un SEED, le client génère le puzzle

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
    // Room management (accepte les deux formats)
      'room_created' || 'roomCreated' => RoomCreatedMessage.fromJson(json),
      'room_joined' || 'roomJoined' => RoomJoinedMessage.fromJson(json),
      'player_joined' || 'opponentJoined' => PlayerJoinedMessage.fromJson(json),
      'player_left' || 'opponentLeft' => PlayerLeftMessage.fromJson(json),

    // Game flow
      'puzzle_ready' || 'puzzleReady' => PuzzleReadyMessage.fromJson(json),
      'countdown' => CountdownMessage.fromJson(json),
      'round_start' || 'roundStart' => RoundStartMessage.fromJson(json),

    // Gameplay
      'opponent_progress' || 'opponentProgress' => OpponentProgressMessage.fromJson(json),
      'player_completed' || 'opponentCompleted' => PlayerCompletedMessage.fromJson(json),

    // Results
      'round_result' || 'roundEnd' => RoundResultMessage.fromJson(json),
      'match_result' || 'gameEnd' => MatchResultMessage.fromJson(json),

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
  final String gameMode = 'isometry';

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

/// Progression du joueur
class ProgressMessage extends ClientMessage {
  final int placedPieces;
  final int isometryCount;

  ProgressMessage({required this.placedPieces, required this.isometryCount});

  @override
  String get type => 'progress';

  @override
  Map<String, dynamic> toJson() => {
    'placedPieces': placedPieces,
    'isometryCount': isometryCount,
  };
}

/// Puzzle terminé
class CompletedMessage extends ClientMessage {
  final int isometryCount;
  final int completionTime;

  CompletedMessage({required this.isometryCount, required this.completionTime});

  @override
  String get type => 'completed';

  @override
  Map<String, dynamic> toJson() => {
    'isometryCount': isometryCount,
    'completionTime': completionTime,
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
      playerId: json['playerId'] ?? json['opponentId'] ?? '',
      playerName: json['playerName'] ?? json['opponentName'] ?? 'Adversaire',
    );
  }
}

/// Joueur parti
class PlayerLeftMessage implements ServerMessage {
  @override
  String get type => 'player_left';

  final String? playerId;

  PlayerLeftMessage({this.playerId});

  factory PlayerLeftMessage.fromJson(Map<String, dynamic> json) {
    return PlayerLeftMessage(
      playerId: json['playerId'] as String?,
    );
  }
}

/// Puzzle prêt - FORMAT SIMPLIFIÉ
/// Le serveur envoie juste seed + pieceCount
/// Le client génère le puzzle avec IsometryPuzzle.generate()
class PuzzleReadyMessage implements ServerMessage {
  @override
  String get type => 'puzzle_ready';

  final int roundNumber;
  final int totalRounds;
  final int seed;
  final int pieceCount;
  final int timeLimit;

  PuzzleReadyMessage({
    required this.roundNumber,
    required this.totalRounds,
    required this.seed,
    required this.pieceCount,
    required this.timeLimit,
  });

  factory PuzzleReadyMessage.fromJson(Map<String, dynamic> json) {
    return PuzzleReadyMessage(
      roundNumber: json['roundNumber'] as int? ?? 1,
      totalRounds: json['totalRounds'] as int? ?? 4,
      seed: json['seed'] as int,
      pieceCount: json['pieceCount'] as int? ?? 3,
      timeLimit: json['timeLimit'] as int? ?? 180,
    );
  }
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

/// Début du round - FORMAT SIMPLIFIÉ
class RoundStartMessage implements ServerMessage {
  @override
  String get type => 'round_start';

  final int roundNumber;

  RoundStartMessage({required this.roundNumber});

  factory RoundStartMessage.fromJson(Map<String, dynamic> json) {
    return RoundStartMessage(
      roundNumber: json['roundNumber'] as int? ?? 1,
    );
  }
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
      placedPieces: json['placedPieces'] as int? ?? 0,
      isometryCount: json['isometryCount'] as int? ?? 0,
    );
  }
}

/// Joueur a terminé
class PlayerCompletedMessage implements ServerMessage {
  @override
  String get type => 'player_completed';

  final String? playerId;
  final int isometryCount;
  final int completionTime;

  PlayerCompletedMessage({
    this.playerId,
    required this.isometryCount,
    required this.completionTime,
  });

  factory PlayerCompletedMessage.fromJson(Map<String, dynamic> json) {
    return PlayerCompletedMessage(
      playerId: json['playerId'] as String?,
      isometryCount: json['isometryCount'] as int? ?? 0,
      completionTime: json['completionTime'] as int? ?? 0,
    );
  }
}

/// Résultat du round
class RoundResultMessage implements ServerMessage {
  @override
  String get type => 'round_result';

  final int roundNumber;
  final String? winnerId;
  final Map<String, dynamic> players;

  RoundResultMessage({
    required this.roundNumber,
    this.winnerId,
    required this.players,
  });

  factory RoundResultMessage.fromJson(Map<String, dynamic> json) {
    return RoundResultMessage(
      roundNumber: json['roundNumber'] as int? ?? 1,
      winnerId: json['winnerId'] as String?,
      players: json['players'] as Map<String, dynamic>? ?? json['results'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Résultat final du match
class MatchResultMessage implements ServerMessage {
  @override
  String get type => 'match_result';

  final String? winnerId;
  final Map<String, dynamic> players;

  MatchResultMessage({
    this.winnerId,
    required this.players,
  });

  factory MatchResultMessage.fromJson(Map<String, dynamic> json) {
    return MatchResultMessage(
      winnerId: json['winnerId'] as String?,
      players: json['players'] as Map<String, dynamic>? ?? json['finalScores'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Message d'erreur
class ErrorMessage implements ServerMessage {
  @override
  String get type => 'error';

  final String message;
  final String? code;

  ErrorMessage({required this.message, this.code});

  factory ErrorMessage.fromJson(Map<String, dynamic> json) {
    return ErrorMessage(
      message: json['message'] as String? ?? 'Erreur inconnue',
      code: json['code'] as String?,
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