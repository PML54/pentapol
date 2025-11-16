// Modified: 2025-11-16 08:30:00
// lib/services/ai_coach.dart
// Coach IA pour guider le joueur et enseigner la géométrie

import 'dart:async';
import '../config/game_config.dart';
import '../models/plateau.dart';
import '../models/pentominos.dart';

/// Service de coaching IA
class AICoach {
  final GameConfig config;
  final StreamController<CoachMessage> _messageController = StreamController.broadcast();
  
  // Historique des actions du joueur
  final List<PlayerAction> _actionHistory = [];
  DateTime? _lastMessageTime;
  int _piecesPlacedCount = 0;
  
  AICoach({required this.config});
  
  Stream<CoachMessage> get messages => _messageController.stream;
  
  /// Appelé au démarrage du jeu
  void onGameStart() {
    _piecesPlacedCount = 0;
    _actionHistory.clear();
    
    _sendMessage(
      CoachMessages.getWelcomeMessage(config.level),
      type: MessageType.welcome,
      priority: MessagePriority.high,
    );
    
    // Pour les débutants, expliquer les bases
    if (config.level == PlayerLevel.beginner) {
      Future.delayed(const Duration(seconds: 2), () {
        _sendMessage(
          "🎯 Ton objectif : Placer les 12 pentominos sur le plateau 6×10.\n"
          "👆 Appuie longuement sur une pièce pour la déplacer !",
          type: MessageType.tutorial,
          priority: MessagePriority.high,
        );
      });
    }
  }
  
  /// Appelé quand une pièce est placée
  void onPiecePlaced(Pento piece, int x, int y, Plateau plateau) {
    _piecesPlacedCount++;
    _actionHistory.add(PlayerAction(
      type: ActionType.placePiece,
      timestamp: DateTime.now(),
      pieceId: piece.id,
    ));
    
    // Premier placement
    if (_piecesPlacedCount == 1) {
      _sendMessage(
        CoachMessages.getFirstPiecePlaced(config.level),
        type: MessageType.encouragement,
        priority: MessagePriority.medium,
      );
      
      // Leçon de géométrie pour débutants
      if (config.level == PlayerLevel.beginner) {
        Future.delayed(const Duration(seconds: 2), () {
          _sendMessage(
            CoachMessages.getGeometryLesson('area'),
            type: MessageType.geometry,
            priority: MessagePriority.low,
          );
        });
      }
    }
    
    // Jalons
    if (_piecesPlacedCount == 6) {
      _sendMessage(
        "🎉 Tu es à mi-chemin ! Continue comme ça !",
        type: MessageType.milestone,
        priority: MessagePriority.medium,
      );
    }
    
    if (_piecesPlacedCount == 10) {
      _sendMessage(
        "🔥 Plus que 2 pièces ! Tu y es presque !",
        type: MessageType.milestone,
        priority: MessagePriority.high,
      );
    }
  }
  
  /// Appelé quand le joueur utilise la rotation
  void onRotationUsed() {
    _actionHistory.add(PlayerAction(
      type: ActionType.rotate,
      timestamp: DateTime.now(),
    ));
    
    // Première rotation pour un débutant
    if (config.level == PlayerLevel.beginner && 
        _actionHistory.where((a) => a.type == ActionType.rotate).length == 1) {
      _sendMessage(
        CoachMessages.getGeometryLesson('rotation'),
        type: MessageType.geometry,
        priority: MessagePriority.medium,
      );
    }
  }
  
  /// Appelé quand le joueur est bloqué (pas d'action depuis 30s)
  void onPlayerStuck(int solutionsCount) {
    final hint = CoachMessages.getStuckHint(config.level, solutionsCount);
    if (hint.isNotEmpty) {
      _sendMessage(
        hint,
        type: MessageType.hint,
        priority: MessagePriority.high,
      );
    }
  }
  
  /// Appelé quand le puzzle est complété
  void onPuzzleCompleted(Duration elapsed) {
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    
    String message;
    if (config.level == PlayerLevel.beginner) {
      message = "🎊 BRAVO ! Tu as réussi ton premier puzzle en ${minutes}min ${seconds}s !\n"
                "Tu as compris les bases. Continue pour débloquer de nouvelles fonctionnalités !";
    } else {
      message = "🏆 Puzzle complété en ${minutes}min ${seconds}s !";
    }
    
    _sendMessage(
      message,
      type: MessageType.victory,
      priority: MessagePriority.high,
    );
    
    // Leçon finale pour débutants
    if (config.level == PlayerLevel.beginner) {
      Future.delayed(const Duration(seconds: 3), () {
        _sendMessage(
          CoachMessages.getGeometryLesson('tessellation'),
          type: MessageType.geometry,
          priority: MessagePriority.medium,
        );
      });
    }
  }
  
  /// Appelé quand le joueur demande une explication
  void explainConcept(String concept) {
    final lesson = CoachMessages.getGeometryLesson(concept);
    if (lesson.isNotEmpty) {
      _sendMessage(
        lesson,
        type: MessageType.geometry,
        priority: MessagePriority.high,
      );
    }
  }
  
  /// Envoie un message au joueur
  void _sendMessage(
    String text, {
    required MessageType type,
    required MessagePriority priority,
  }) {
    // Éviter le spam (max 1 message toutes les 3 secondes)
    final now = DateTime.now();
    if (_lastMessageTime != null && 
        now.difference(_lastMessageTime!) < const Duration(seconds: 3) &&
        priority != MessagePriority.high) {
      return;
    }
    
    _lastMessageTime = now;
    _messageController.add(CoachMessage(
      text: text,
      type: type,
      priority: priority,
      timestamp: now,
    ));
  }
  
  void dispose() {
    _messageController.close();
  }
}

/// Message du coach
class CoachMessage {
  final String text;
  final MessageType type;
  final MessagePriority priority;
  final DateTime timestamp;
  
  const CoachMessage({
    required this.text,
    required this.type,
    required this.priority,
    required this.timestamp,
  });
}

/// Type de message
enum MessageType {
  welcome,       // Message de bienvenue
  tutorial,      // Tutoriel
  encouragement, // Encouragement
  hint,          // Indice
  geometry,      // Leçon de géométrie
  milestone,     // Jalon atteint
  victory,       // Victoire
}

/// Priorité du message
enum MessagePriority {
  low,    // Peut être ignoré
  medium, // Important
  high,   // Critique
}

/// Action du joueur
class PlayerAction {
  final ActionType type;
  final DateTime timestamp;
  final int? pieceId;
  
  const PlayerAction({
    required this.type,
    required this.timestamp,
    this.pieceId,
  });
}

/// Type d'action
enum ActionType {
  placePiece,
  removePiece,
  rotate,
  undo,
  viewSolutions,
}

