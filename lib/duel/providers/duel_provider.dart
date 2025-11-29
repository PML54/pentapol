// lib/duel/providers/duel_provider.dart
// Provider Riverpod pour la gestion du mode duel

import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/duel_state.dart';
import '../models/duel_messages.dart';
import '../services/websocket_service.dart';

/// Configuration du serveur
const String kDuelServerBaseUrl = 'https://pentapol-duel.pentapml.workers.dev';
const String kDuelServerWsUrl = 'wss://pentapol-duel.pentapml.workers.dev';

/// Provider pour l'état du duel
final duelProvider = NotifierProvider<DuelNotifier, DuelState>(() {
  return DuelNotifier();
});

/// Notifier pour gérer l'état du duel
class DuelNotifier extends Notifier<DuelState> {
  /// Service WebSocket
  WebSocketService? _wsService;

  /// Subscription aux messages
  StreamSubscription<ServerMessage>? _messageSubscription;

  /// Subscription à l'état de connexion
  StreamSubscription<WebSocketConnectionState>? _connectionSubscription;

  /// Timer pour le compte à rebours local
  Timer? _countdownTimer;

  /// Nom du joueur local
  String? _localPlayerName;

  @override
  DuelState build() {
    ref.onDispose(_cleanup);
    return DuelState.initial();
  }

  // ============================================================
  // ACTIONS PUBLIQUES
  // ============================================================

  /// Créer une nouvelle room
  Future<bool> createRoom(String playerName) async {
    print('[DUEL] Création de room par $playerName...');
    _localPlayerName = playerName;

    state = state.copyWith(
      connectionState: DuelConnectionState.connecting,
      clearErrorMessage: true,
    );

    try {
      // 1. Créer la room via HTTP
      print('[DUEL] 📡 Appel HTTP POST /room/create...');
      final response = await http.post(
        Uri.parse('$kDuelServerBaseUrl/room/create'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        print('[DUEL] ❌ Erreur HTTP: ${response.statusCode}');
        state = state.copyWith(
          connectionState: DuelConnectionState.error,
          errorMessage: 'Erreur serveur: ${response.statusCode}',
        );
        return false;
      }

      final data = jsonDecode(response.body);
      final roomCode = data['roomCode'] as String;
      print('[DUEL] ✅ Room créée: $roomCode');

      // 2. Se connecter en WebSocket
      final wsUrl = '$kDuelServerWsUrl/room/$roomCode/ws';
      print('[DUEL] 🔌 Connexion WebSocket: $wsUrl');

      _wsService = WebSocketService(serverUrl: wsUrl);

      // S'abonner aux événements
      _messageSubscription = _wsService!.messages.listen(_onServerMessage);
      _connectionSubscription = _wsService!.connectionState.listen(_onConnectionStateChange);

      final connected = await _wsService!.connect();
      if (!connected) {
        state = state.copyWith(
          connectionState: DuelConnectionState.error,
          errorMessage: 'Impossible de se connecter au WebSocket',
        );
        return false;
      }

      // 3. Envoyer le message createRoom
      _wsService!.send(CreateRoomMessage(playerName: playerName));

      state = state.copyWith(
        roomCode: roomCode,
        gameState: DuelGameState.waiting,
        connectionState: DuelConnectionState.connected,
      );

      return true;

    } catch (e) {
      print('[DUEL] ❌ Erreur: $e');
      state = state.copyWith(
        connectionState: DuelConnectionState.error,
        errorMessage: 'Erreur: $e',
      );
      return false;
    }
  }

  /// Rejoindre une room existante
  Future<bool> joinRoom(String roomCode, String playerName) async {
    print('[DUEL] $playerName rejoint la room $roomCode...');
    _localPlayerName = playerName;

    state = state.copyWith(
      connectionState: DuelConnectionState.connecting,
      clearErrorMessage: true,
    );

    try {
      // 1. Vérifier que la room existe
      print('[DUEL] 📡 Vérification room $roomCode...');
      final checkResponse = await http.get(
        Uri.parse('$kDuelServerBaseUrl/room/$roomCode/exists'),
      );

      if (checkResponse.statusCode != 200) {
        state = state.copyWith(
          connectionState: DuelConnectionState.error,
          errorMessage: 'Erreur serveur',
        );
        return false;
      }

      final checkData = jsonDecode(checkResponse.body);
      if (checkData['exists'] != true) {
        print('[DUEL] ❌ Room $roomCode introuvable');
        state = state.copyWith(
          connectionState: DuelConnectionState.error,
          errorMessage: 'Code invalide ou partie expirée',
        );
        return false;
      }

      print('[DUEL] ✅ Room $roomCode existe');

      // 2. Se connecter en WebSocket
      final wsUrl = '$kDuelServerWsUrl/room/$roomCode/ws';
      print('[DUEL] 🔌 Connexion WebSocket: $wsUrl');

      _wsService = WebSocketService(serverUrl: wsUrl);

      _messageSubscription = _wsService!.messages.listen(_onServerMessage);
      _connectionSubscription = _wsService!.connectionState.listen(_onConnectionStateChange);

      final connected = await _wsService!.connect();
      if (!connected) {
        state = state.copyWith(
          connectionState: DuelConnectionState.error,
          errorMessage: 'Impossible de se connecter',
        );
        return false;
      }

      // 3. Envoyer le message joinRoom
      _wsService!.send(JoinRoomMessage(roomCode: roomCode, playerName: playerName));

      state = state.copyWith(
        roomCode: roomCode,
        gameState: DuelGameState.waiting,
        connectionState: DuelConnectionState.connected,
      );

      return true;

    } catch (e) {
      print('[DUEL] ❌ Erreur: $e');
      state = state.copyWith(
        connectionState: DuelConnectionState.error,
        errorMessage: 'Erreur: $e',
      );
      return false;
    }
  }

  /// Quitter la room actuelle
  void leaveRoom() {
    print('[DUEL] Quitter la room...');

    if (_wsService?.isConnected ?? false) {
      _wsService!.send(LeaveRoomMessage());
    }

    _cleanup();
    state = DuelState.initial();
  }

  /// Placer une pièce
  void placePiece({
    required int pieceId,
    required int x,
    required int y,
    required int orientation,
  }) {
    if (!state.isPlaying) {
      print('[DUEL] ⚠️ Partie non en cours, placement ignoré');
      return;
    }

    final alreadyPlaced = state.placedPieces.any((p) => p.pieceId == pieceId);
    if (alreadyPlaced) {
      print('[DUEL] ⚠️ Pièce $pieceId déjà placée');
      return;
    }

    print('[DUEL] Tentative de placement: pièce $pieceId en ($x, $y) orientation $orientation');

    _wsService?.send(PlacePieceMessage(
      pieceId: pieceId,
      x: x,
      y: y,
      orientation: orientation,
    ));
  }

  /// Signaler que le joueur est prêt
  void setReady() {
    _wsService?.send(PlayerReadyMessage());
  }

  // ============================================================
  // GESTION CONNEXION
  // ============================================================

  void _onConnectionStateChange(WebSocketConnectionState wsState) {
    print('[DUEL] État connexion WS: $wsState');

    final connectionState = switch (wsState) {
      WebSocketConnectionState.disconnected => DuelConnectionState.disconnected,
      WebSocketConnectionState.connecting => DuelConnectionState.connecting,
      WebSocketConnectionState.connected => DuelConnectionState.connected,
      WebSocketConnectionState.reconnecting => DuelConnectionState.reconnecting,
      WebSocketConnectionState.error => DuelConnectionState.error,
    };

    state = state.copyWith(connectionState: connectionState);

    if (wsState == WebSocketConnectionState.error && state.isPlaying) {
      state = state.copyWith(
        errorMessage: 'Connexion perdue avec le serveur',
      );
    }
  }

  // ============================================================
  // TRAITEMENT DES MESSAGES SERVEUR
  // ============================================================

  void _onServerMessage(ServerMessage message) {
    print('[DUEL] Message serveur: ${message.type}');

    switch (message) {
      case RoomCreatedMessage msg:
        _handleRoomCreated(msg);
      case RoomJoinedMessage msg:
        _handleRoomJoined(msg);
      case PlayerJoinedMessage msg:
        _handlePlayerJoined(msg);
      case PlayerLeftMessage msg:
        _handlePlayerLeft(msg);
      case GameStartMessage msg:
        _handleGameStart(msg);
      case CountdownMessage msg:
        _handleCountdown(msg);
      case PiecePlacedMessage msg:
        _handlePiecePlaced(msg);
      case PlacementRejectedMessage msg:
        _handlePlacementRejected(msg);
      case GameStateMessage msg:
        _handleGameState(msg);
      case GameEndMessage msg:
        _handleGameEnd(msg);
      case ErrorMessage msg:
        _handleError(msg);
      default:
        print('[DUEL] Message non géré: ${message.type}');
    }
  }

  void _handleRoomCreated(RoomCreatedMessage msg) {
    print('[DUEL] ✅ Room confirmée: ${msg.roomCode}');

    state = state.copyWith(
      roomCode: msg.roomCode,
      localPlayer: DuelPlayer(
        id: msg.playerId,
        name: _localPlayerName ?? 'Joueur',
      ),
      gameState: DuelGameState.waiting,
    );
  }

  void _handleRoomJoined(RoomJoinedMessage msg) {
    print('[DUEL] ✅ Room rejointe: ${msg.roomCode}');

    state = state.copyWith(
      roomCode: msg.roomCode,
      localPlayer: DuelPlayer(
        id: msg.playerId,
        name: _localPlayerName ?? 'Joueur',
      ),
      opponent: msg.opponentId != null
          ? DuelPlayer(id: msg.opponentId!, name: msg.opponentName ?? 'Adversaire')
          : null,
      gameState: DuelGameState.waiting,
    );
  }

  void _handlePlayerJoined(PlayerJoinedMessage msg) {
    print('[DUEL] 👤 Joueur rejoint: ${msg.playerName}');

    if (msg.playerId != state.localPlayer?.id) {
      state = state.copyWith(
        opponent: DuelPlayer(id: msg.playerId, name: msg.playerName),
      );
    }
  }

  void _handlePlayerLeft(PlayerLeftMessage msg) {
    print('[DUEL] 👤 Joueur parti: ${msg.playerId}');

    if (msg.playerId == state.opponent?.id) {
      if (state.isPlaying) {
        state = state.copyWith(
          gameState: DuelGameState.ended,
          clearOpponent: true,
        );
      } else {
        state = state.copyWith(clearOpponent: true);
      }
    }
  }

  void _handleGameStart(GameStartMessage msg) {
    print('[DUEL] 🎮 Partie commence ! Solution #${msg.solutionId}');

    state = state.copyWith(
      solutionId: msg.solutionId,
      timeRemaining: msg.timeLimit,
      placedPieces: [],
      gameState: DuelGameState.countdown,
    );
  }

  void _handleCountdown(CountdownMessage msg) {
    print('[DUEL] ⏱️ Countdown: ${msg.value}');

    if (msg.value == 0) {
      state = state.copyWith(
        gameState: DuelGameState.playing,
        clearCountdown: true,
      );
      _startLocalTimer();
    } else {
      state = state.copyWith(countdown: msg.value);
    }
  }

  void _handlePiecePlaced(PiecePlacedMessage msg) {
    print('[DUEL] ✅ Pièce placée: ${msg.pieceId} par ${msg.ownerName}');

    final newPiece = DuelPlacedPiece(
      pieceId: msg.pieceId,
      x: msg.x,
      y: msg.y,
      orientation: msg.orientation,
      ownerId: msg.ownerId,
      ownerName: msg.ownerName,
      timestamp: msg.timestamp,
    );

    state = state.copyWith(
      placedPieces: [...state.placedPieces, newPiece],
    );
  }

  void _handlePlacementRejected(PlacementRejectedMessage msg) {
    print('[DUEL] ❌ Placement refusé: ${msg.reason}');

    state = state.copyWith(
      errorMessage: msg.reasonText,
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (state.errorMessage == msg.reasonText) {
        state = state.copyWith(clearErrorMessage: true);
      }
    });
  }

  void _handleGameState(GameStateMessage msg) {
    state = state.copyWith(
      timeRemaining: msg.timeRemaining,
      placedPieces: msg.placedPieces
          .map((p) => DuelPlacedPiece.fromJson(p))
          .toList(),
    );
  }

  void _handleGameEnd(GameEndMessage msg) {
    print('[DUEL] 🏁 Partie terminée ! Gagnant: ${msg.winnerName}');

    _countdownTimer?.cancel();

    state = state.copyWith(
      gameState: DuelGameState.ended,
      clearCountdown: true,
    );
  }

  void _handleError(ErrorMessage msg) {
    print('[DUEL] ❌ Erreur serveur: ${msg.code} - ${msg.message}');

    state = state.copyWith(
      errorMessage: msg.message,
    );
  }

  // ============================================================
  // TIMER LOCAL
  // ============================================================

  void _startLocalTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.timeRemaining != null && state.timeRemaining! > 0) {
        state = state.copyWith(timeRemaining: state.timeRemaining! - 1);
      } else if (state.timeRemaining == 0) {
        _countdownTimer?.cancel();
      }
    });
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  void _cleanup() {
    _countdownTimer?.cancel();
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _wsService?.disconnect();
    _messageSubscription = null;
    _connectionSubscription = null;
    _wsService = null;
  }
}