// lib/duel_isometry/providers/duel_isometry_provider.dart
// Provider Riverpod pour la gestion du mode Duel Isométries

import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

// Import explicite des models - tout vient de duel_isometry_state.dart
import '../models/duel_isometry_state.dart';

// Import explicite des messages
import '../models/duel_isometry_messages.dart';

// Import explicite des services - seulement les classes nécessaires
import '../services/isometry_puzzle.dart' show IsometryPuzzle, TargetPiece;
import '../services/isometry_utils.dart' show PieceConfiguration;

/// Configuration du serveur
const String kIsometryServerBaseUrl = 'https://pentapol-duel.pentapml.workers.dev';
const String kIsometryServerWsUrl = 'wss://pentapol-duel.pentapml.workers.dev';

/// Provider pour l'état du duel isométries
final duelIsometryProvider =
NotifierProvider<DuelIsometryNotifier, DuelIsometryState>(() {
  return DuelIsometryNotifier();
});

/// Notifier pour gérer l'état du duel isométries
class DuelIsometryNotifier extends Notifier<DuelIsometryState> {
  /// WebSocket channel
  WebSocketChannel? _channel;

  /// Subscription aux messages
  StreamSubscription<dynamic>? _messageSubscription;

  /// Timer local pour le temps écoulé
  Timer? _elapsedTimer;

  /// Timestamp de début du round
  DateTime? _roundStartTime;

  /// Nom du joueur local
  String? _localPlayerName;

  @override
  DuelIsometryState build() {
    ref.onDispose(_cleanup);
    return const DuelIsometryState();
  }

  // ============================================================
  // ACTIONS PUBLIQUES - ROOM
  // ============================================================

  /// Créer une nouvelle room
  Future<bool> createRoom(String playerName) async {
    print('[DUEL-ISO] Création de room par $playerName...');
    _localPlayerName = playerName;

    state = state.copyWith(
      connectionState: DuelIsometryConnectionState.connecting,
      clearError: true,
    );

    try {
      // 1. Créer la room via HTTP
      print('[DUEL-ISO] 📡 Appel HTTP POST /room/create...');
      final response = await http.post(
        Uri.parse('$kIsometryServerBaseUrl/room/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'gameMode': 'isometry'}),
      );

      if (response.statusCode != 200) {
        print('[DUEL-ISO] ❌ Erreur HTTP: ${response.statusCode}');
        state = state.copyWith(
          connectionState: DuelIsometryConnectionState.error,
          errorMessage: 'Erreur serveur: ${response.statusCode}',
        );
        return false;
      }

      final data = jsonDecode(response.body);
      final roomCode = data['roomCode'] as String;
      print('[DUEL-ISO] ✅ Room créée: $roomCode');

      // 2. Se connecter en WebSocket
      return await _connectToRoom(roomCode, playerName, isCreator: true);
    } catch (e) {
      print('[DUEL-ISO] ❌ Erreur: $e');
      state = state.copyWith(
        connectionState: DuelIsometryConnectionState.error,
        errorMessage: 'Erreur: $e',
      );
      return false;
    }
  }

  /// Rejoindre une room existante
  Future<bool> joinRoom(String roomCode, String playerName) async {
    print('[DUEL-ISO] $playerName rejoint la room $roomCode...');
    _localPlayerName = playerName;

    state = state.copyWith(
      connectionState: DuelIsometryConnectionState.connecting,
      clearError: true,
    );

    try {
      // 1. Vérifier que la room existe
      print('[DUEL-ISO] 📡 Vérification room $roomCode...');
      final checkResponse = await http.get(
        Uri.parse('$kIsometryServerBaseUrl/room/$roomCode/exists'),
      );

      if (checkResponse.statusCode != 200) {
        state = state.copyWith(
          connectionState: DuelIsometryConnectionState.error,
          errorMessage: 'Erreur serveur',
        );
        return false;
      }

      final checkData = jsonDecode(checkResponse.body);
      if (checkData['exists'] != true) {
        print('[DUEL-ISO] ❌ Room $roomCode introuvable');
        state = state.copyWith(
          connectionState: DuelIsometryConnectionState.error,
          errorMessage: 'Code invalide ou partie expirée',
        );
        return false;
      }

      // Vérifier le mode de jeu (optionnel)
      if (checkData['gameMode'] != null && checkData['gameMode'] != 'isometry') {
        print('[DUEL-ISO] ❌ Room $roomCode n\'est pas un duel isométries');
        state = state.copyWith(
          connectionState: DuelIsometryConnectionState.error,
          errorMessage: 'Cette room n\'est pas un Duel Isométries',
        );
        return false;
      }

      print('[DUEL-ISO] ✅ Room $roomCode existe');

      // 2. Se connecter en WebSocket
      return await _connectToRoom(roomCode, playerName, isCreator: false);
    } catch (e) {
      print('[DUEL-ISO] ❌ Erreur: $e');
      state = state.copyWith(
        connectionState: DuelIsometryConnectionState.error,
        errorMessage: 'Erreur: $e',
      );
      return false;
    }
  }

  /// Connexion WebSocket commune
  Future<bool> _connectToRoom(
      String roomCode,
      String playerName, {
        required bool isCreator,
      }) async {
    final wsUrl = '$kIsometryServerWsUrl/room/$roomCode/ws';
    print('[DUEL-ISO] 🔌 Connexion WebSocket: $wsUrl');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Attendre que la connexion soit établie
      await _channel!.ready;

      // S'abonner aux messages
      _messageSubscription = _channel!.stream.listen(
        _onRawMessage,
        onError: (error) {
          print('[DUEL-ISO] ❌ WebSocket error: $error');
          state = state.copyWith(
            connectionState: DuelIsometryConnectionState.error,
            errorMessage: 'Connexion perdue',
          );
        },
        onDone: () {
          print('[DUEL-ISO] WebSocket fermé');
          state = state.copyWith(
            connectionState: DuelIsometryConnectionState.disconnected,
          );
        },
      );

      // Envoyer le message approprié
      if (isCreator) {
        _sendMessage(CreateRoomMessage(playerName: playerName));
      } else {
        _sendMessage(JoinRoomMessage(roomCode: roomCode, playerName: playerName));
      }

      state = state.copyWith(
        roomCode: roomCode,
        gameState: DuelIsometryGameState.waiting,
        connectionState: DuelIsometryConnectionState.connected,
      );

      return true;
    } catch (e) {
      print('[DUEL-ISO] ❌ Erreur connexion WebSocket: $e');
      state = state.copyWith(
        connectionState: DuelIsometryConnectionState.error,
        errorMessage: 'Impossible de se connecter',
      );
      return false;
    }
  }

  /// Quitter la room actuelle
  void leaveRoom() {
    print('[DUEL-ISO] Quitter la room...');

    if (_channel != null) {
      _sendMessage(LeaveRoomMessage());
    }

    _cleanup();
    state = const DuelIsometryState();
  }

  /// Signaler que le joueur est prêt
  void setReady() {
    _sendMessage(PlayerReadyMessage());
  }

  // ============================================================
  // ACTIONS PUBLIQUES - GAMEPLAY
  // ============================================================

  /// Placer une pièce
  void placePiece({
    required int pieceId,
    required int gridX,
    required int gridY,
    required int positionIndex,
  }) {
    if (state.gameState != DuelIsometryGameState.playing) {
      print('[DUEL-ISO] ⚠️ Partie non en cours, placement ignoré');
      return;
    }

    // Vérifier que la pièce n'est pas déjà placée
    final alreadyPlaced = state.placedPieces.any((p) => p.pieceId == pieceId);
    if (alreadyPlaced) {
      print('[DUEL-ISO] ⚠️ Pièce $pieceId déjà placée');
      return;
    }

    print('[DUEL-ISO] Placement: pièce $pieceId en ($gridX, $gridY) pos $positionIndex');

    _sendMessage(PlacePieceMessage(
      pieceId: pieceId,
      gridX: gridX,
      gridY: gridY,
      positionIndex: positionIndex,
    ));

    // Ajouter localement (le serveur confirmera)
    final newPiece = DuelIsometryPlacedPiece(
      pieceId: pieceId,
      gridX: gridX,
      gridY: gridY,
      positionIndex: positionIndex,
      ownerId: state.localPlayer?.id ?? 'local',
    );

    state = state.copyWith(
      placedPieces: [...state.placedPieces, newPiece],
    );
  }

  /// Mettre à jour la progression locale (pour sync avec serveur)
  void updateLocalProgress({
    required int placedPieces,
    required int isometryCount,
  }) {
    _sendMessage(UpdateProgressMessage(
      placedPieces: placedPieces,
      isometryCount: isometryCount,
    ));
  }

  /// Puzzle terminé par le joueur local
  void completePuzzle({
    required int totalIsometries,
    required int timeMs,
  }) {
    print('[DUEL-ISO] 🏁 Puzzle terminé ! Iso: $totalIsometries, Temps: ${timeMs}ms');

    _sendMessage(PuzzleCompletedMessage(
      totalIsometries: totalIsometries,
      timeMs: timeMs,
    ));

    state = state.copyWith(
      localCompleted: true,
      localIsometries: totalIsometries,
      localTimeMs: timeMs,
    );
  }

  // ============================================================
  // TRAITEMENT DES MESSAGES SERVEUR
  // ============================================================

  void _onRawMessage(dynamic rawData) {
    try {
      final message = ServerMessage.decode(rawData as String);
      _onServerMessage(message);
    } catch (e) {
      print('[DUEL-ISO] ❌ Erreur parsing message: $e');
      print('[DUEL-ISO] Raw data: $rawData');
    }
  }

  void _onServerMessage(ServerMessage message) {
    print('[DUEL-ISO] 📨 Message serveur: ${message.type}');

    switch (message) {
      case RoomCreatedMessage msg:
        _handleRoomCreated(msg);
      case RoomJoinedMessage msg:
        _handleRoomJoined(msg);
      case PlayerJoinedMessage msg:
        _handlePlayerJoined(msg);
      case PlayerLeftMessage msg:
        _handlePlayerLeft(msg);
      case PuzzleReadyMessage msg:
        _handlePuzzleReady(msg);
      case CountdownMessage msg:
        _handleCountdown(msg);
      case RoundStartMessage msg:
        _handleRoundStart(msg);
      case PiecePlacedMessage msg:
        _handlePiecePlaced(msg);
      case PlacementRejectedMessage msg:
        _handlePlacementRejected(msg);
      case OpponentProgressMessage msg:
        _handleOpponentProgress(msg);
      case PlayerCompletedMessage msg:
        _handlePlayerCompleted(msg);
      case RoundResultMessage msg:
        _handleRoundResult(msg);
      case MatchResultMessage msg:
        _handleMatchResult(msg);
      case ErrorMessage msg:
        _handleError(msg);
      default:
        print('[DUEL-ISO] Message non géré: ${message.type}');
    }
  }

  void _handleRoomCreated(RoomCreatedMessage msg) {
    print('[DUEL-ISO] ✅ Room confirmée: ${msg.roomCode}');

    state = state.copyWith(
      roomCode: msg.roomCode,
      localPlayer: DuelIsometryPlayer(
        id: msg.playerId,
        name: _localPlayerName ?? 'Joueur',
      ),
      gameState: DuelIsometryGameState.waiting,
    );
  }

  void _handleRoomJoined(RoomJoinedMessage msg) {
    print('[DUEL-ISO] ✅ Room rejointe: ${msg.roomCode}');

    state = state.copyWith(
      roomCode: msg.roomCode,
      localPlayer: DuelIsometryPlayer(
        id: msg.playerId,
        name: _localPlayerName ?? 'Joueur',
      ),
      opponent: msg.opponentId != null
          ? DuelIsometryPlayer(
        id: msg.opponentId!,
        name: msg.opponentName ?? 'Adversaire',
      )
          : null,
      gameState: DuelIsometryGameState.waiting,
    );
  }

  void _handlePlayerJoined(PlayerJoinedMessage msg) {
    print('[DUEL-ISO] 👤 Joueur rejoint: ${msg.playerName}');

    if (msg.playerId != state.localPlayer?.id) {
      state = state.copyWith(
        opponent: DuelIsometryPlayer(id: msg.playerId, name: msg.playerName),
      );
    }
  }

  void _handlePlayerLeft(PlayerLeftMessage msg) {
    print('[DUEL-ISO] 👤 Joueur parti: ${msg.playerId}');

    if (msg.playerId == state.opponent?.id) {
      if (state.gameState == DuelIsometryGameState.playing) {
        // Victoire par forfait
        state = state.copyWith(
          gameState: DuelIsometryGameState.roundEnded,
          clearOpponent: true,
        );
      } else {
        state = state.copyWith(clearOpponent: true);
      }
    }
  }

  void _handlePuzzleReady(PuzzleReadyMessage msg) {
    print('[DUEL-ISO] 🧩 Puzzle prêt: Round ${msg.roundNumber}, ${msg.pieces.length} pièces');

    // Reconstruire le puzzle à partir des données serveur
    final puzzle = _buildPuzzleFromMessage(msg);

    state = state.copyWith(
      puzzle: puzzle,
      roundNumber: msg.roundNumber,
      totalRounds: msg.totalRounds,
      optimalIsometries: msg.optimalIsometries,
      placedPieces: [],
      opponentPlacedPieces: 0,
      opponentIsometries: 0,
      localCompleted: false,
      opponentCompleted: false,
      gameState: DuelIsometryGameState.countdown,
    );
  }

  IsometryPuzzle _buildPuzzleFromMessage(PuzzleReadyMessage msg) {
    // Construire les TargetPiece à partir des données
    final pieces = msg.pieces.map((p) {
      return TargetPiece(
        pieceId: p.pieceId,
        pieceName: p.pieceName,
        targetGridX: p.targetGridX,
        targetGridY: p.targetGridY,
        targetPositionIndex: p.targetPositionIndex,
        targetConfig: _positionIndexToConfig(p.targetPositionIndex),
        initialConfig: _positionIndexToConfig(p.initialPositionIndex),
        initialPositionIndex: p.initialPositionIndex,
        minIsometries: p.minIsometries,
      );
    }).toList();

    // Construire la grille cible
    final grid = List.generate(
      msg.height,
          (_) => List.filled(msg.width, 0),
    );

    return IsometryPuzzle(
      width: msg.width,
      height: msg.height,
      seed: msg.seed,
      pieces: pieces,
      totalMinIsometries: msg.optimalIsometries,
      targetGrid: grid,
    );
  }

  PieceConfiguration _positionIndexToConfig(int positionIndex) {
    if (positionIndex < 4) {
      return PieceConfiguration(positionIndex, false);
    } else if (positionIndex < 8) {
      return PieceConfiguration(positionIndex - 4, true);
    }
    return PieceConfiguration(positionIndex % 4, positionIndex >= 4);
  }

  void _handleCountdown(CountdownMessage msg) {
    print('[DUEL-ISO] ⏱️ Countdown: ${msg.value}');

    if (msg.value == 0) {
      state = state.copyWith(
        gameState: DuelIsometryGameState.playing,
        countdown: null,
      );
      _startElapsedTimer();
    } else {
      state = state.copyWith(countdown: msg.value);
    }
  }

  void _handleRoundStart(RoundStartMessage msg) {
    print('[DUEL-ISO] 🎮 Round ${msg.roundNumber} commence !');

    _roundStartTime = DateTime.fromMillisecondsSinceEpoch(msg.timestamp);
    state = state.copyWith(
      gameState: DuelIsometryGameState.playing,
      elapsedTime: 0,
    );
    _startElapsedTimer();
  }

  void _handlePiecePlaced(PiecePlacedMessage msg) {
    print('[DUEL-ISO] ✅ Pièce ${msg.pieceId} placée par ${msg.playerName}');

    // Ne rien faire si c'est notre propre pièce (déjà ajoutée localement)
    if (msg.playerId == state.localPlayer?.id) {
      return;
    }

    // C'est une pièce de l'adversaire - mettre à jour le compteur
    state = state.copyWith(
      opponentPlacedPieces: state.opponentPlacedPieces + 1,
    );
  }

  void _handlePlacementRejected(PlacementRejectedMessage msg) {
    print('[DUEL-ISO] ❌ Placement refusé: ${msg.reason}');

    // Retirer la dernière pièce ajoutée localement
    if (state.placedPieces.isNotEmpty) {
      final updatedPieces = List<DuelIsometryPlacedPiece>.from(state.placedPieces);
      updatedPieces.removeLast();
      state = state.copyWith(
        placedPieces: updatedPieces,
        errorMessage: msg.reasonText,
      );
    } else {
      state = state.copyWith(errorMessage: msg.reasonText);
    }

    // Effacer le message après un délai
    Future.delayed(const Duration(seconds: 2), () {
      if (state.errorMessage == msg.reasonText) {
        state = state.copyWith(clearError: true);
      }
    });
  }

  void _handleOpponentProgress(OpponentProgressMessage msg) {
    state = state.copyWith(
      opponentPlacedPieces: msg.placedPieces,
      opponentIsometries: msg.isometryCount,
    );
  }

  void _handlePlayerCompleted(PlayerCompletedMessage msg) {
    print('[DUEL-ISO] 🏁 ${msg.playerName} a terminé ! Iso: ${msg.totalIsometries}');

    if (msg.playerId == state.opponent?.id) {
      state = state.copyWith(
        opponentCompleted: true,
        opponentIsometries: msg.totalIsometries,
        opponentTimeMs: msg.timeMs,
      );
    }
  }

  void _handleRoundResult(RoundResultMessage msg) {
    print('[DUEL-ISO] 🏆 Round ${msg.roundNumber} terminé ! Gagnant: ${msg.winnerName}');

    _elapsedTimer?.cancel();

    final isLocalWinner = msg.winnerId == state.localPlayer?.id;

    // Trouver les stats du joueur local et de l'adversaire
    final localStats = msg.player1Stats.playerId == state.localPlayer?.id
        ? msg.player1Stats
        : msg.player2Stats;
    final opponentStats = msg.player1Stats.playerId == state.localPlayer?.id
        ? msg.player2Stats
        : msg.player1Stats;

    final result = RoundResult(
      winnerId: msg.winnerId,
      localIsometries: localStats.isometries,
      localTimeMs: localStats.timeMs,
      opponentIsometries: opponentStats.isometries,
      opponentTimeMs: opponentStats.timeMs,
      optimalIsometries: msg.optimalIsometries,
    );

    state = state.copyWith(
      gameState: DuelIsometryGameState.roundEnded,
      roundResult: result,
      localScore: isLocalWinner ? state.localScore + 1 : state.localScore,
      opponentScore: !isLocalWinner && msg.winnerId != null
          ? state.opponentScore + 1
          : state.opponentScore,
    );
  }

  void _handleMatchResult(MatchResultMessage msg) {
    print('[DUEL-ISO] 🎊 Match terminé ! Gagnant: ${msg.winnerName}');

    state = state.copyWith(
      gameState: DuelIsometryGameState.matchEnded,
      localScore: msg.player1FinalScore,
      opponentScore: msg.player2FinalScore,
    );
  }

  void _handleError(ErrorMessage msg) {
    print('[DUEL-ISO] ❌ Erreur serveur: ${msg.code} - ${msg.message}');

    state = state.copyWith(
      errorMessage: msg.message,
    );
  }

  // ============================================================
  // TIMER LOCAL
  // ============================================================

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _roundStartTime = DateTime.now();

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_roundStartTime != null) {
        final elapsed = DateTime.now().difference(_roundStartTime!).inSeconds;
        state = state.copyWith(elapsedTime: elapsed);
      }
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _sendMessage(ClientMessage message) {
    if (_channel != null) {
      _channel!.sink.add(message.encode());
    } else {
      print('[DUEL-ISO] ⚠️ WebSocket non connecté, message ignoré');
    }
  }

  void _cleanup() {
    _elapsedTimer?.cancel();
    _messageSubscription?.cancel();
    _channel?.sink.close();
    _messageSubscription = null;
    _channel = null;
    _roundStartTime = null;
  }
}