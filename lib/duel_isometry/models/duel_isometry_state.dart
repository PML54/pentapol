// lib/duel_isometry/models/duel_isometry_state.dart
// État d'une partie duel isométries

import 'package:flutter/foundation.dart';
import 'package:pentapol/models/plateau.dart';

/// État d'une partie duel isométries
@immutable
class DuelIsometryState {
  /// Code de la room (ex: "ABC123")
  final String? roomCode;

  /// État de la connexion
  final DuelConnectionState connectionState;

  /// État de la partie
  final DuelGameState gameState;

  /// Joueur local (moi)
  final DuelPlayer? localPlayer;

  /// Joueur adverse
  final DuelPlayer? opponent;

  /// ID de la solution choisie (parmi les 9356)
  final int? solutionId;

  /// Plateau généré pour duel isometry (5×5, 4×5, 3×5)
  final Plateau? plateau;

  /// Pièces placées sur le plateau partagé
  final List<DuelIsometryPlacedPiece> placedPieces;

  /// Temps restant en secondes
  final int? timeRemaining;

  /// Message d'erreur éventuel
  final String? errorMessage;

  /// Compte à rebours avant démarrage (3, 2, 1, null)
  final int? countdown;

  const DuelIsometryState({
    this.roomCode,
    this.connectionState = DuelConnectionState.disconnected,
    this.gameState = DuelGameState.idle,
    this.localPlayer,
    this.opponent,
    this.solutionId,
    this.plateau,
    this.placedPieces = const [],
    this.timeRemaining,
    this.errorMessage,
    this.countdown,
  });

  /// État initial
  factory DuelIsometryState.initial() => const DuelIsometryState();

  /// Copie avec modifications
  DuelIsometryState copyWith({
    String? roomCode,
    bool clearRoomCode = false,
    DuelConnectionState? connectionState,
    DuelGameState? gameState,
    DuelPlayer? localPlayer,
    bool clearLocalPlayer = false,
    DuelPlayer? opponent,
    bool clearOpponent = false,
    int? solutionId,
    bool clearSolutionId = false,
    Plateau? plateau,
    bool clearPlateau = false,
    List<DuelIsometryPlacedPiece>? placedPieces,
    int? timeRemaining,
    bool clearTimeRemaining = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? countdown,
    bool clearCountdown = false,
  }) {
    return DuelIsometryState(
      roomCode: clearRoomCode ? null : (roomCode ?? this.roomCode),
      connectionState: connectionState ?? this.connectionState,
      gameState: gameState ?? this.gameState,
      localPlayer: clearLocalPlayer ? null : (localPlayer ?? this.localPlayer),
      opponent: clearOpponent ? null : (opponent ?? this.opponent),
      solutionId: clearSolutionId ? null : (solutionId ?? this.solutionId),
      plateau: clearPlateau ? null : (plateau ?? this.plateau),
      placedPieces: placedPieces ?? this.placedPieces,
      timeRemaining: clearTimeRemaining ? null : (timeRemaining ?? this.timeRemaining),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      countdown: clearCountdown ? null : (countdown ?? this.countdown),
    );
  }

  /// Score du joueur local
  int get localScore => placedPieces
      .where((p) => p.ownerId == localPlayer?.id)
      .length;

  /// Score de l'adversaire
  int get opponentScore => placedPieces
      .where((p) => p.ownerId == opponent?.id)
      .length;

  /// La partie est-elle en cours ?
  bool get isPlaying => gameState == DuelGameState.playing;

  /// La partie est-elle terminée ?
  bool get isGameOver => gameState == DuelGameState.ended;

  /// Suis-je le gagnant ?
  bool get isWinner => isGameOver && localScore > opponentScore;

  /// Est-ce une égalité ?
  bool get isDraw => isGameOver && localScore == opponentScore;

  /// En attente d'un adversaire ?
  bool get isWaitingForOpponent =>
      gameState == DuelGameState.waiting && opponent == null;
}

/// État de la connexion WebSocket
enum DuelConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// État de la partie
enum DuelGameState {
  idle,        // Pas de partie
  waiting,     // En attente d'un adversaire
  countdown,   // Compte à rebours (3, 2, 1)
  playing,     // Partie en cours
  ended,       // Partie terminée
}

/// Joueur dans une partie duel
@immutable
class DuelPlayer {
  final String id;
  final String name;
  final bool isReady;
  final bool isConnected;

  const DuelPlayer({
    required this.id,
    required this.name,
    this.isReady = false,
    this.isConnected = true,
  });

  DuelPlayer copyWith({
    String? id,
    String? name,
    bool? isReady,
    bool? isConnected,
  }) {
    return DuelPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isReady: isReady ?? this.isReady,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isReady': isReady,
    'isConnected': isConnected,
  };

  factory DuelPlayer.fromJson(Map<String, dynamic> json) {
    return DuelPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      isReady: json['isReady'] as bool? ?? false,
      isConnected: json['isConnected'] as bool? ?? true,
    );
  }
}

/// Pièce placée dans une partie duel
@immutable
class DuelIsometryPlacedPiece {
  final int pieceId;        // 1-12
  final int x;              // Position X sur le plateau
  final int y;              // Position Y sur le plateau
  final int orientation;    // Index d'orientation (0-7)
  final String ownerId;     // ID du joueur qui a placé
  final String ownerName;   // Nom du joueur
  final int timestamp;      // Timestamp serveur

  const DuelIsometryPlacedPiece({
    required this.pieceId,
    required this.x,
    required this.y,
    required this.orientation,
    required this.ownerId,
    required this.ownerName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'pieceId': pieceId,
    'x': x,
    'y': y,
    'orientation': orientation,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'timestamp': timestamp,
  };

  factory DuelIsometryPlacedPiece.fromJson(Map<String, dynamic> json) {
    return DuelIsometryPlacedPiece(
      pieceId: json['pieceId'] as int,
      x: json['x'] as int,
      y: json['y'] as int,
      orientation: json['orientation'] as int,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  /// Cette pièce appartient-elle à ce joueur ?
  bool isOwnedBy(String playerId) => ownerId == playerId;
}