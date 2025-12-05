// lib/duel/providers/duel_provider.dart
// Provider Riverpod pour la gestion du mode duel

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pentapol/models/pentominos.dart';
import 'package:pentapol/models/plateau.dart';
import 'package:pentapol/pentoscope/pentoscope_data.dart';
import 'package:pentapol/pentoscope/pentoscope_solver.dart';

import '../models/duel_isometry_messages.dart';
import '../models/duel_isometry_state.dart';
import '../services/duel_isometry_websocket_service.dart';
/// Configuration du serveur
const String kDuelServerBaseUrl = 'https://pentapol-duel.pentapml.workers.dev';
const String kDuelServerWsUrl = 'wss://pentapol-duel.pentapml.workers.dev';

/// Provider pour l'état du duel
final duelIsometryProvider = NotifierProvider<DuelIsometryNotifier, DuelIsometryState>(() {
  return DuelIsometryNotifier();
});

/// Notifier pour gérer l'état du duel
class DuelIsometryNotifier extends Notifier<DuelIsometryState> {
  /// Service WebSocket
  DuelIsometryWebSocketService? _wsService;

  /// Subscription aux messages
  StreamSubscription<ServerMessage>? _messageSubscription;

  /// Subscription à l'état de connexion
  StreamSubscription<WebSocketConnectionState>? _connectionSubscription;

  /// Timer pour le compte à rebours local
  Timer? _countdownTimer;

  /// Nom du joueur local
  String? _localPlayerName;

  @override
  DuelIsometryState build() {
    ref.onDispose(_cleanup);
    return DuelIsometryState.initial();
  }

  // ============================================================
  // ACTIONS PUBLIQUES
  // ============================================================
  /// Créer une nouvelle room Duel Isométries
  Future<bool> createRoom(String playerName, [Map<String, int>? puzzleTriple]) async {
    print('[DUEL-ISO] Création de room par $playerName...');
    if (puzzleTriple != null) {
      print('[DUEL-ISO] Triple Pentoscope: taille=${puzzleTriple['taille']}, '
          'config=${puzzleTriple['configIndex']}, '
          'solution=${puzzleTriple['solutionNum']}');
    }

    _localPlayerName = playerName;
    state = state.copyWith(
      connectionState: DuelConnectionState.connecting,
      clearErrorMessage: true,
    );

    try {
      // 1. Créer la room via HTTP avec la triplette
      print('[DUEL-ISO] 📡 Appel HTTP POST /room/create...');
      final requestBody = {
        'gameMode': 'isometry',
        'playerName': playerName,
        if (puzzleTriple != null) ...puzzleTriple,
      };

      final response = await http.post(
        Uri.parse('$kDuelServerBaseUrl/room/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        print('[DUEL-ISO] ❌ Erreur HTTP: ${response.statusCode}');
        state = state.copyWith(
          connectionState: DuelConnectionState.error,
          errorMessage: 'Erreur serveur: ${response.statusCode}',
        );
        return false;
      }

      final data = jsonDecode(response.body);
      final roomCode = data['roomCode'] as String;
      print('[DUEL-ISO] ✅ Room créée: $roomCode');

      // 2. Se connecter en WebSocket
      final wsUrl = '$kDuelServerWsUrl/room/$roomCode/ws';
      print('[DUEL-ISO] 🔌 Connexion WebSocket: $wsUrl');

      _wsService = DuelIsometryWebSocketService(serverUrl: wsUrl);

      // S'abonner aux événements
      _messageSubscription = _wsService!.messages.listen(_onServerMessage);
      _connectionSubscription = _wsService!.connectionState.listen(_onConnectionStateChange);

      final connected = await _wsService!.connect();
      if (!connected) {
        print('[DUEL-ISO] ❌ Connexion WebSocket échouée');
        state = state.copyWith(
          connectionState: DuelConnectionState.error,
          errorMessage: 'Impossible de se connecter au WebSocket',
        );
        return false;
      }

      // 3. Envoyer le message createRoom
      print('[DUEL-ISO] 📤 Envoi CreateRoomMessage');
      _wsService!.send(CreateRoomMessage(playerName: playerName));

      state = state.copyWith(
        roomCode: roomCode,
        gameState: DuelGameState.waiting,
        connectionState: DuelConnectionState.connected,
      );

      print('[DUEL-ISO] ✅ Room prête!');
      return true;

    } catch (e) {
      print('[DUEL-ISO] ❌ Erreur: $e');
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

      _wsService = DuelIsometryWebSocketService(serverUrl: wsUrl);

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
    state = DuelIsometryState.initial();
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

  /// Décode un bitmask en liste d'IDs de pièces
  List<int> _bitmaskToIds(int bitmask) {
    final ids = <int>[];
    for (int i = 0; i < 12; i++) {
      if (bitmask & (1 << i) != 0) {
        ids.add(i + 1);
      }
    }
    return ids;
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

  /// Convertit les placements PentoscopeSolver en Plateau
  Plateau _convertToPlateau(
      int width,
      int height,
      List<PentoscopePlacement> placements,
      ) {
    // Créer une grille vide
    final grid = List.generate(
      height,
          (_) => List.filled(width, 0),
    );

    // Placer chaque pièce
    for (final placement in placements) {
      final pieceId = placement.pieceId;
      for (final cellIndex in placement.occupiedCells) {
        final x = cellIndex % width;
        final y = cellIndex ~/ width;
        if (x >= 0 && x < width && y >= 0 && y < height) {
          grid[y][x] = pieceId;
        }
      }
    }

    return Plateau(
      width: width,
      height: height,
      grid: grid,
    );




  }

  // Ajouter cette fonction au provider duel_isometry_provider.dart

  Plateau _generatePlateauFromTriple(Map<String, int> triple) {
    final taille = triple['taille'] as int;
    final configIndex = triple['configIndex'] as int;
    final solutionNum = triple['solutionNum'] as int;

    print('[DUEL-ISO] Génération: taille=$taille, config=$configIndex, solution=$solutionNum');

    // 1. Charger la config Pentoscope
    final configsForSize = pentoscopeData[taille];
    if (configsForSize == null || configIndex >= configsForSize.length) {
      print('[DUEL-ISO] ❌ Config invalide');
      return Plateau.empty(5, 5);
    }

    final (bitmask, numSolutions) = configsForSize[configIndex];
    print('[DUEL-ISO] Bitmask: 0x${bitmask.toRadixString(16)}, solutions: $numSolutions');

    // 2. Décoder le bitmask en pieceIds
    final pieceIds = _bitmaskToIds(bitmask);
    print('[DUEL-ISO] Pièces: $pieceIds');

    // 3. Récupérer les tailles de plateau
    final (width, height) = _getTaillePlateau(taille);
    print('[DUEL-ISO] Plateau: ${width}×$height');

    // 4. Obtenir les Pento correspondants
    final selectedPieces = <Pento>[];
    for (final id in pieceIds) {
      // pentominos est indexé par id-1 (id 1 = F, id 2 = I, etc.)
      if (id >= 1 && id <= pentominos.length) {
        selectedPieces.add(pentominos[id - 1]);
      }
    }

    if (selectedPieces.length != pieceIds.length) {
      print('[DUEL-ISO] ❌ Pièces manquantes');
      return Plateau.empty(width, height);
    }

    // 5. Lancer PentoscopeSolver
    final solver = PentoscopeSolver(
      width: width,
      height: height,
      pieces: selectedPieces,
      maxSeconds: 5,
    );

    final solution = solver.findSolution();
    if (solution == null) {
      print('[DUEL-ISO] ❌ Pas de solution trouvée');
      return Plateau.empty(width, height);
    }

    print('[DUEL-ISO] ✅ Solution trouvée: ${solution.length} placements');

    // 6. Convertir en Plateau
    final plateau = _convertToPlateau(width, height, solution);
    print('[DUEL-ISO] 🎯 Plateau généré!');

    return plateau;
  }

  /// Retourne (width, height) pour une taille Pentoscope
  (int, int) _getTaillePlateau(int sizeIndex) {
    switch (sizeIndex) {
      case 0: return (5, 3);  // 3×5
      case 1: return (5, 4);  // 4×5
      case 2: return (5, 5);  // 5×5
      default: return (5, 5);
    }
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

  void _handleError(ErrorMessage msg) {
    print('[DUEL] ❌ Erreur serveur: ${msg.code} - ${msg.message}');

    state = state.copyWith(
      errorMessage: msg.message,
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

  void _handleGameStart(GameStartMessage msg) {
    print('[DUEL-ISO] 🎮 Partie commence !');

    if (msg.solutionId != null) {
      // Duel classique
      state = state.copyWith(
        solutionId: msg.solutionId,
        timeRemaining: msg.timeLimit,
        placedPieces: [],
        gameState: DuelGameState.countdown,
      );
    }
    else if (msg.puzzleTriple != null) {
      try {
        final triple = msg.puzzleTriple!;
        print('[DUEL-ISO] Génération puzzle: $triple');
        final plateau = _generatePlateauFromTriple(triple);
        print('[DUEL-ISO] ✅ Plateau créé: ${plateau.width}×${plateau.height}');

        // ✅ AJOUTER LE PLATEAU AU STATE
        state = state.copyWith(
          plateau: plateau,
          timeRemaining: msg.timeLimit,
          placedPieces: [],
          gameState: DuelGameState.countdown,
        );
      } catch (e) {
        print('[DUEL-ISO] ❌ ERREUR: $e');
      }
    }
  }

  void _handleGameState(GameStateMessage msg) {
    state = state.copyWith(
      timeRemaining: msg.timeRemaining,
      placedPieces: msg.placedPieces
          .map((p) => DuelIsometryPlacedPiece.fromJson(p))
          .toList(),
    );
  }

  void _handlePiecePlaced(PiecePlacedMessage msg) {
    print('[DUEL] ✅ Pièce placée: ${msg.pieceId} par ${msg.ownerName}');

    final newPiece = DuelIsometryPlacedPiece(
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
}