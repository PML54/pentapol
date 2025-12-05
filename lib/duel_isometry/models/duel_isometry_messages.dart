// lib/duel/models/duel_messages.dart
// Messages WebSocket pour la communication duel
// MODIFIÉ: Fallback ownerId/playerId pour compatibilité serveur

import 'dart:convert';

/// Types de messages client → serveur
enum ClientMessageType {
  createRoom,
  joinRoom,
  leaveRoom,
  placePiece,
  playerReady,
  ping,
}

/// Types de messages serveur → client
enum ServerMessageType {
  roomCreated,
  roomJoined,
  playerJoined,
  playerLeft,
  gameStart,
  countdown,
  piecePlaced,
  placementRejected,
  gameState,
  gameEnd,
  error,
  pong,
}

// ============================================================
// MESSAGES CLIENT → SERVEUR
// ============================================================

/// Message de base client
abstract class ClientMessage {
  ClientMessageType get type;
  Map<String, dynamic> toJson();

  String encode() => jsonEncode({
    'type': type.name,
    ...toJson(),
  });
}

/// Créer une room
class CreateRoomMessage extends ClientMessage {
  final String playerName;

  CreateRoomMessage({required this.playerName});

  @override
  ClientMessageType get type => ClientMessageType.createRoom;

  @override
  Map<String, dynamic> toJson() => {
    'playerName': playerName,
  };
}

/// Rejoindre une room
class JoinRoomMessage extends ClientMessage {
  final String roomCode;
  final String playerName;

  JoinRoomMessage({required this.roomCode, required this.playerName});

  @override
  ClientMessageType get type => ClientMessageType.joinRoom;

  @override
  Map<String, dynamic> toJson() => {
    'roomCode': roomCode,
    'playerName': playerName,
  };
}

/// Quitter une room
class LeaveRoomMessage extends ClientMessage {
  @override
  ClientMessageType get type => ClientMessageType.leaveRoom;

  @override
  Map<String, dynamic> toJson() => {};
}

/// Placer une pièce
class PlacePieceMessage extends ClientMessage {
  final int pieceId;
  final int x;
  final int y;
  final int orientation;

  PlacePieceMessage({
    required this.pieceId,
    required this.x,
    required this.y,
    required this.orientation,
  });

  @override
  ClientMessageType get type => ClientMessageType.placePiece;

  @override
  Map<String, dynamic> toJson() => {
    'pieceId': pieceId,
    'x': x,
    'y': y,
    'orientation': orientation,
  };
}

/// Joueur prêt
class PlayerReadyMessage extends ClientMessage {
  @override
  ClientMessageType get type => ClientMessageType.playerReady;

  @override
  Map<String, dynamic> toJson() => {};
}

/// Ping (keep-alive)
class PingMessage extends ClientMessage {
  @override
  ClientMessageType get type => ClientMessageType.ping;

  @override
  Map<String, dynamic> toJson() => {};
}

// ============================================================
// MESSAGES SERVEUR → CLIENT
// ============================================================

/// Message de base serveur
abstract class ServerMessage {
  ServerMessageType get type;

  /// Parse un message JSON du serveur
  static ServerMessage? parse(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final typeStr = json['type'] as String;

      switch (typeStr) {
        case 'roomCreated':
          return RoomCreatedMessage.fromJson(json);
        case 'roomJoined':
          return RoomJoinedMessage.fromJson(json);
        case 'playerJoined':
          return PlayerJoinedMessage.fromJson(json);
        case 'playerLeft':
          return PlayerLeftMessage.fromJson(json);
        case 'gameStart':
          return GameStartMessage.fromJson(json);
        case 'countdown':
          return CountdownMessage.fromJson(json);
        case 'piecePlaced':
          return PiecePlacedMessage.fromJson(json);
        case 'placementRejected':
          return PlacementRejectedMessage.fromJson(json);
        case 'gameState':
          return GameStateMessage.fromJson(json);
        case 'gameEnd':
          return GameEndMessage.fromJson(json);
        case 'error':
          return ErrorMessage.fromJson(json);
        case 'pong':
          return PongMessage();
        default:
          print('[DUEL] Message inconnu: $typeStr');
          return null;
      }
    } catch (e) {
      print('[DUEL] Erreur parsing message: $e');
      return null;
    }
  }
}

/// Room créée
class RoomCreatedMessage extends ServerMessage {
  final String roomCode;
  final String playerId;

  RoomCreatedMessage({required this.roomCode, required this.playerId});

  @override
  ServerMessageType get type => ServerMessageType.roomCreated;

  factory RoomCreatedMessage.fromJson(Map<String, dynamic> json) {
    return RoomCreatedMessage(
      roomCode: json['roomCode'] as String,
      playerId: json['playerId'] as String,
    );
  }
}

/// Room rejointe
class RoomJoinedMessage extends ServerMessage {
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

  @override
  ServerMessageType get type => ServerMessageType.roomJoined;

  factory RoomJoinedMessage.fromJson(Map<String, dynamic> json) {
    return RoomJoinedMessage(
      roomCode: json['roomCode'] as String,
      playerId: json['playerId'] as String,
      opponentId: json['opponentId'] as String?,
      opponentName: json['opponentName'] as String?,
    );
  }
}

/// Joueur a rejoint
class PlayerJoinedMessage extends ServerMessage {
  final String playerId;
  final String playerName;

  PlayerJoinedMessage({required this.playerId, required this.playerName});

  @override
  ServerMessageType get type => ServerMessageType.playerJoined;

  factory PlayerJoinedMessage.fromJson(Map<String, dynamic> json) {
    return PlayerJoinedMessage(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
    );
  }
}

/// Joueur a quitté
class PlayerLeftMessage extends ServerMessage {
  final String playerId;

  PlayerLeftMessage({required this.playerId});

  @override
  ServerMessageType get type => ServerMessageType.playerLeft;

  factory PlayerLeftMessage.fromJson(Map<String, dynamic> json) {
    return PlayerLeftMessage(
      playerId: json['playerId'] as String,
    );
  }
}

/// Partie commence
class GameStartMessage extends ServerMessage {
  final int? solutionId;                    // Pour duel classique
  final Map<String, int>? puzzleTriple;    // Pour duel isometry
  final int timeLimit;

  GameStartMessage({
    this.solutionId,
    this.puzzleTriple,
    required this.timeLimit,
  });

  @override
  ServerMessageType get type => ServerMessageType.gameStart;

  factory GameStartMessage.fromJson(Map<String, dynamic> json) {
    Map<String, int>? puzzleTriple;
    if (json['puzzleTriple'] != null) {
      final pt = json['puzzleTriple'] as Map<String, dynamic>;
      puzzleTriple = {
        'taille': pt['taille'] as int,
        'configIndex': pt['configIndex'] as int,
        'solutionNum': pt['solutionNum'] as int,
      };
    }

    return GameStartMessage(
      solutionId: json['solutionId'] as int?,
      puzzleTriple: puzzleTriple,
      timeLimit: json['timeLimit'] as int,
    );
  }

}

/// Compte à rebours
class CountdownMessage extends ServerMessage {
  final int value; // 3, 2, 1, 0 (0 = GO!)

  CountdownMessage({required this.value});

  @override
  ServerMessageType get type => ServerMessageType.countdown;

  factory CountdownMessage.fromJson(Map<String, dynamic> json) {
    return CountdownMessage(
      value: json['value'] as int,
    );
  }
}

/// Pièce placée (broadcast)
class PiecePlacedMessage extends ServerMessage {
  final int pieceId;
  final int x;
  final int y;
  final int orientation;
  final String ownerId;
  final String ownerName;
  final int timestamp;

  PiecePlacedMessage({
    required this.pieceId,
    required this.x,
    required this.y,
    required this.orientation,
    required this.ownerId,
    required this.ownerName,
    required this.timestamp,
  });

  @override
  ServerMessageType get type => ServerMessageType.piecePlaced;

  factory PiecePlacedMessage.fromJson(Map<String, dynamic> json) {
    return PiecePlacedMessage(
      pieceId: json['pieceId'] as int,
      x: json['x'] as int,
      y: json['y'] as int,
      orientation: json['orientation'] as int,
      // Fallback: accepte ownerId OU playerId
      ownerId: (json['ownerId'] ?? json['playerId']) as String,
      ownerName: (json['ownerName'] ?? json['playerName']) as String,
      // Fallback: timestamp optionnel
      timestamp: (json['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// Placement refusé
class PlacementRejectedMessage extends ServerMessage {
  final int pieceId;
  final String reason; // "already_placed", "wrong_position", "wrong_orientation"

  PlacementRejectedMessage({required this.pieceId, required this.reason});

  @override
  ServerMessageType get type => ServerMessageType.placementRejected;

  factory PlacementRejectedMessage.fromJson(Map<String, dynamic> json) {
    return PlacementRejectedMessage(
      pieceId: (json['pieceId'] as int?) ?? 0,
      reason: json['reason'] as String,
    );
  }

  String get reasonText {
    switch (reason) {
      case 'already_placed':
        return 'Pièce déjà placée par l\'adversaire !';
      case 'wrong_position':
        return 'Position incorrecte';
      case 'wrong_orientation':
        return 'Mauvaise orientation';
      default:
        return 'Placement refusé';
    }
  }
}

/// État complet du jeu (synchronisation)
class GameStateMessage extends ServerMessage {
  final List<Map<String, dynamic>> players;
  final List<Map<String, dynamic>> placedPieces;
  final int timeRemaining;

  GameStateMessage({
    required this.players,
    required this.placedPieces,
    required this.timeRemaining,
  });

  @override
  ServerMessageType get type => ServerMessageType.gameState;

  factory GameStateMessage.fromJson(Map<String, dynamic> json) {
    return GameStateMessage(
      players: (json['players'] as List).cast<Map<String, dynamic>>(),
      placedPieces: (json['placedPieces'] as List).cast<Map<String, dynamic>>(),
      timeRemaining: json['timeRemaining'] as int,
    );
  }
}

/// Fin de partie
class GameEndMessage extends ServerMessage {
  final String winnerId;
  final String winnerName;
  final int winnerScore;
  final String loserId;
  final String loserName;
  final int loserScore;
  final String reason; // "time_up", "all_placed", "opponent_left"

  GameEndMessage({
    required this.winnerId,
    required this.winnerName,
    required this.winnerScore,
    required this.loserId,
    required this.loserName,
    required this.loserScore,
    required this.reason,
  });

  @override
  ServerMessageType get type => ServerMessageType.gameEnd;

  factory GameEndMessage.fromJson(Map<String, dynamic> json) {
    return GameEndMessage(
      winnerId: json['winnerId'] as String,
      winnerName: json['winnerName'] as String,
      winnerScore: json['winnerScore'] as int,
      loserId: json['loserId'] as String,
      loserName: json['loserName'] as String,
      loserScore: json['loserScore'] as int,
      reason: json['reason'] as String,
    );
  }

  bool isDraw() => winnerScore == loserScore;
}

/// Erreur
class ErrorMessage extends ServerMessage {
  final String code;
  final String message;

  ErrorMessage({required this.code, required this.message});

  @override
  ServerMessageType get type => ServerMessageType.error;

  factory ErrorMessage.fromJson(Map<String, dynamic> json) {
    return ErrorMessage(
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }
}

/// Pong (réponse au ping)
class PongMessage extends ServerMessage {
  @override
  ServerMessageType get type => ServerMessageType.pong;
}