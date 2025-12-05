// lib/duel/services/websocket_service.dart
// Service de connexion WebSocket pour le mode duel

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/duel_isometry_messages.dart';

/// Service de connexion WebSocket
class DuelIsometryWebSocketService {
  /// URL du serveur WebSocket
  final String serverUrl;

  /// Canal WebSocket
  WebSocketChannel? _channel;

  /// Stream controller pour les messages reçus
  final _messageController = StreamController<ServerMessage>.broadcast();

  /// Stream controller pour l'état de connexion
  final _connectionController = StreamController<WebSocketConnectionState>.broadcast();

  /// État actuel de la connexion
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;

  /// Timer pour le ping/pong (keep-alive)
  Timer? _pingTimer;

  /// Timer pour la reconnexion
  Timer? _reconnectTimer;

  /// Nombre de tentatives de reconnexion
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  DuelIsometryWebSocketService({required this.serverUrl});

  /// Stream des messages reçus
  Stream<ServerMessage> get messages => _messageController.stream;

  /// Stream de l'état de connexion
  Stream<WebSocketConnectionState> get connectionState => _connectionController.stream;

  /// État actuel
  WebSocketConnectionState get currentState => _connectionState;

  /// Est connecté ?
  bool get isConnected => _connectionState == WebSocketConnectionState.connected;

  /// Se connecter au serveur
  Future<bool> connect() async {
    if (_connectionState == WebSocketConnectionState.connecting ||
        _connectionState == WebSocketConnectionState.connected) {
      print('[WS] Déjà connecté ou en cours de connexion');
      return isConnected;
    }

    _setConnectionState(WebSocketConnectionState.connecting);
    print('[WS] Connexion à $serverUrl...');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

      // Attendre la connexion
      await _channel!.ready;

      _setConnectionState(WebSocketConnectionState.connected);
      print('[WS] ✅ Connecté !');

      // Écouter les messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Démarrer le ping/pong
      _startPingTimer();

      // Reset compteur de reconnexion
      _reconnectAttempts = 0;

      return true;
    } catch (e) {
      print('[WS] ❌ Erreur de connexion: $e');
      _setConnectionState(WebSocketConnectionState.error);
      _scheduleReconnect();
      return false;
    }
  }

  /// Se déconnecter
  Future<void> disconnect() async {
    print('[WS] Déconnexion...');

    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    await _channel?.sink.close();
    _channel = null;

    _setConnectionState(WebSocketConnectionState.disconnected);
    print('[WS] Déconnecté');
  }

  /// Envoyer un message
  void send(ClientMessage message) {
    if (!isConnected) {
      print('[WS] ⚠️ Non connecté, message ignoré: ${message.type}');
      return;
    }

    final encoded = message.encode();
    print('[WS] 📤 Envoi: ${message.type}');
    _channel?.sink.add(encoded);
  }

  /// Envoyer un message brut (pour debug)
  void sendRaw(String message) {
    if (!isConnected) return;
    _channel?.sink.add(message);
  }

  // ============================================================
  // HANDLERS PRIVÉS
  // ============================================================

  void _onMessage(dynamic data) {
    print('[WS] 📥 Reçu: $data');

    if (data is! String) {
      print('[WS] ⚠️ Message non-string ignoré');
      return;
    }

    final message = ServerMessage.parse(data);
    if (message != null) {
      // Gérer le pong spécialement
      if (message is PongMessage) {
        print('[WS] 🏓 Pong reçu');
        return;
      }

      _messageController.add(message);
    }
  }

  void _onError(dynamic error) {
    print('[WS] ❌ Erreur: $error');
    _setConnectionState(WebSocketConnectionState.error);
    _scheduleReconnect();
  }

  void _onDone() {
    print('[WS] 🔌 Connexion fermée');

    if (_connectionState != WebSocketConnectionState.disconnected) {
      _setConnectionState(WebSocketConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _setConnectionState(WebSocketConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionController.add(state);
    }
  }

  // ============================================================
  // PING/PONG (Keep-Alive)
  // ============================================================

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected) {
        print('[WS] 🏓 Ping...');
        send(PingMessage());
      }
    });
  }

  // ============================================================
  // RECONNEXION
  // ============================================================

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[WS] ❌ Trop de tentatives de reconnexion, abandon');
      _setConnectionState(WebSocketConnectionState.error);
      return;
    }

    _reconnectTimer?.cancel();

    final delay = Duration(seconds: (_reconnectAttempts + 1) * 2); // 2, 4, 6, 8, 10 sec
    print('[WS] 🔄 Reconnexion dans ${delay.inSeconds}s (tentative ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');

    _setConnectionState(WebSocketConnectionState.reconnecting);

    _reconnectTimer = Timer(delay, () async {
      _reconnectAttempts++;
      await connect();
    });
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  void dispose() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _connectionController.close();
  }
}

/// État de la connexion WebSocket
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}