// lib/duel_isometry/models/duel_isometry_state.dart
// État complet du jeu Duel Isométries

// NOTE: On importe isometry_puzzle.dart pour les types TargetPiece et IsometryPuzzle
// mais on s'assure qu'il n'y a pas de classes dupliquées entre les deux fichiers
import '../services/isometry_puzzle.dart' show IsometryPuzzle, TargetPiece;

// ============================================================================
// ENUMS
// ============================================================================

enum DuelIsometryGameState {
  waiting,    // En attente d'un adversaire
  countdown,  // Countdown avant le début du round
  playing,    // Round en cours
  roundEnded, // Round terminé, affichage des résultats
  matchEnded, // Match terminé (tous les rounds joués)
}

enum DuelIsometryConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

// ============================================================================
// MODELS
// ============================================================================

/// Joueur
class DuelIsometryPlayer {
  final String id;
  final String name;

  const DuelIsometryPlayer({
    required this.id,
    required this.name,
  });

  DuelIsometryPlayer copyWith({String? id, String? name}) {
    return DuelIsometryPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  String toString() => 'Player($name, $id)';
}

/// Pièce placée sur le plateau
class DuelIsometryPlacedPiece {
  final int pieceId;
  final int gridX;
  final int gridY;
  final int positionIndex;
  final String ownerId;

  const DuelIsometryPlacedPiece({
    required this.pieceId,
    required this.gridX,
    required this.gridY,
    required this.positionIndex,
    required this.ownerId,
  });

  @override
  String toString() => 'Placed($pieceId at $gridX,$gridY pos$positionIndex)';
}

/// Résultat d'un round
class RoundResult {
  final String? winnerId;
  final int localIsometries;
  final int localTimeMs;
  final int opponentIsometries;
  final int opponentTimeMs;
  final int optimalIsometries;

  const RoundResult({
    this.winnerId,
    required this.localIsometries,
    required this.localTimeMs,
    required this.opponentIsometries,
    required this.opponentTimeMs,
    required this.optimalIsometries,
  });

  /// Efficacité du joueur local (100% = optimal)
  double get localEfficiency {
    if (localIsometries == 0) return optimalIsometries == 0 ? 100.0 : 0.0;
    return (optimalIsometries / localIsometries * 100).clamp(0.0, 100.0);
  }

  /// Efficacité de l'adversaire
  double get opponentEfficiency {
    if (opponentIsometries == 0) return optimalIsometries == 0 ? 100.0 : 0.0;
    return (optimalIsometries / opponentIsometries * 100).clamp(0.0, 100.0);
  }

  /// Temps local formaté
  String get localTimeFormatted {
    final seconds = localTimeMs / 1000;
    return '${seconds.toStringAsFixed(1)}s';
  }

  /// Temps adversaire formaté
  String get opponentTimeFormatted {
    final seconds = opponentTimeMs / 1000;
    return '${seconds.toStringAsFixed(1)}s';
  }
}

// ============================================================================
// STATE PRINCIPAL
// ============================================================================

/// État complet du Duel Isométries
class DuelIsometryState {
  // --- Connexion ---
  final DuelIsometryConnectionState connectionState;
  final String? roomCode;
  final String? errorMessage;

  // --- État du jeu ---
  final DuelIsometryGameState gameState;
  final int? countdown;
  final int? elapsedTime; // Temps écoulé en secondes

  // --- Joueurs ---
  final DuelIsometryPlayer? localPlayer;
  final DuelIsometryPlayer? opponent;

  // --- Puzzle actuel ---
  final IsometryPuzzle? puzzle;
  final int roundNumber;
  final int totalRounds;
  final int optimalIsometries;

  // --- Pièces placées (joueur local uniquement) ---
  final List<DuelIsometryPlacedPiece> placedPieces;

  // --- Progression locale ---
  final bool localCompleted;
  final int localIsometries;
  final int localTimeMs;

  // --- Progression adversaire (live) ---
  final int opponentPlacedPieces;
  final int opponentIsometries;
  final bool opponentCompleted;
  final int opponentTimeMs;

  // --- Scores globaux ---
  final int localScore;
  final int opponentScore;

  // --- Résultat du round ---
  final RoundResult? roundResult;

  const DuelIsometryState({
    this.connectionState = DuelIsometryConnectionState.disconnected,
    this.roomCode,
    this.errorMessage,
    this.gameState = DuelIsometryGameState.waiting,
    this.countdown,
    this.elapsedTime,
    this.localPlayer,
    this.opponent,
    this.puzzle,
    this.roundNumber = 1,
    this.totalRounds = 4,
    this.optimalIsometries = 0,
    this.placedPieces = const [],
    this.localCompleted = false,
    this.localIsometries = 0,
    this.localTimeMs = 0,
    this.opponentPlacedPieces = 0,
    this.opponentIsometries = 0,
    this.opponentCompleted = false,
    this.opponentTimeMs = 0,
    this.localScore = 0,
    this.opponentScore = 0,
    this.roundResult,
  });

  // --- Getters utiles ---

  /// Le jeu est-il en cours ?
  bool get isPlaying => gameState == DuelIsometryGameState.playing;

  /// Un adversaire est-il connecté ?
  bool get hasOpponent => opponent != null;

  /// Nombre de pièces dans le puzzle actuel
  int get totalPieces => puzzle?.pieceCount ?? 0;

  /// Nombre de pièces correctement placées par le joueur local
  int get localPlacedCount => placedPieces.length;

  /// Progression locale en pourcentage (0-100)
  double get localProgressPercent {
    if (totalPieces == 0) return 0.0;
    return (localPlacedCount / totalPieces * 100).clamp(0.0, 100.0);
  }

  /// Progression adversaire en pourcentage
  double get opponentProgressPercent {
    if (totalPieces == 0) return 0.0;
    return (opponentPlacedPieces / totalPieces * 100).clamp(0.0, 100.0);
  }

  /// Temps écoulé formaté (MM:SS)
  String get elapsedTimeFormatted {
    final time = elapsedTime ?? 0;
    final minutes = time ~/ 60;
    final seconds = time % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Est-ce le dernier round ?
  bool get isLastRound => roundNumber >= totalRounds;

  /// Le match est-il terminé (un joueur a gagné) ?
  bool get isMatchOver {
    final requiredWins = (totalRounds / 2).ceil();
    return localScore >= requiredWins || opponentScore >= requiredWins;
  }

  // --- CopyWith ---

  DuelIsometryState copyWith({
    DuelIsometryConnectionState? connectionState,
    String? roomCode,
    String? errorMessage,
    DuelIsometryGameState? gameState,
    int? countdown,
    int? elapsedTime,
    DuelIsometryPlayer? localPlayer,
    DuelIsometryPlayer? opponent,
    IsometryPuzzle? puzzle,
    int? roundNumber,
    int? totalRounds,
    int? optimalIsometries,
    List<DuelIsometryPlacedPiece>? placedPieces,
    bool? localCompleted,
    int? localIsometries,
    int? localTimeMs,
    int? opponentPlacedPieces,
    int? opponentIsometries,
    bool? opponentCompleted,
    int? opponentTimeMs,
    int? localScore,
    int? opponentScore,
    RoundResult? roundResult,
    // Flags de reset
    bool clearError = false,
    bool clearOpponent = false,
    bool clearRoundResult = false,
  }) {
    return DuelIsometryState(
      connectionState: connectionState ?? this.connectionState,
      roomCode: roomCode ?? this.roomCode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      gameState: gameState ?? this.gameState,
      countdown: countdown ?? this.countdown,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      localPlayer: localPlayer ?? this.localPlayer,
      opponent: clearOpponent ? null : (opponent ?? this.opponent),
      puzzle: puzzle ?? this.puzzle,
      roundNumber: roundNumber ?? this.roundNumber,
      totalRounds: totalRounds ?? this.totalRounds,
      optimalIsometries: optimalIsometries ?? this.optimalIsometries,
      placedPieces: placedPieces ?? this.placedPieces,
      localCompleted: localCompleted ?? this.localCompleted,
      localIsometries: localIsometries ?? this.localIsometries,
      localTimeMs: localTimeMs ?? this.localTimeMs,
      opponentPlacedPieces: opponentPlacedPieces ?? this.opponentPlacedPieces,
      opponentIsometries: opponentIsometries ?? this.opponentIsometries,
      opponentCompleted: opponentCompleted ?? this.opponentCompleted,
      opponentTimeMs: opponentTimeMs ?? this.opponentTimeMs,
      localScore: localScore ?? this.localScore,
      opponentScore: opponentScore ?? this.opponentScore,
      roundResult: clearRoundResult ? null : (roundResult ?? this.roundResult),
    );
  }

  @override
  String toString() {
    return 'DuelIsometryState('
        'game: $gameState, '
        'round: $roundNumber/$totalRounds, '
        'local: $localPlacedCount/$totalPieces pieces, '
        'opponent: $opponentPlacedPieces/$totalPieces pieces, '
        'score: $localScore-$opponentScore'
        ')';
  }
}