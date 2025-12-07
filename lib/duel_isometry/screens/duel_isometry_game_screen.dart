// 251206 1730
// Version: Claude V2 Final
// lib/duel_isometry/screens/duel_isometry_game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/duel_isometry/models/duel_isometry_state.dart';
import 'package:pentapol/duel_isometry/providers/duel_isometry_provider.dart';
import 'package:pentapol/duel_isometry/services/duel_isometry_validator.dart';
import 'package:pentapol/duel_isometry/widgets/duel_isometry_piece_slider.dart';
import 'package:pentapol/duel_isometry/widgets/duel_isometry_plateau.dart';
import 'package:pentapol/models/plateau.dart';

class DuelIsometryGameScreen extends ConsumerStatefulWidget {
  const DuelIsometryGameScreen({super.key});

  @override
  ConsumerState<DuelIsometryGameScreen> createState() =>
      _DuelIsometryGameScreenState();
}

class _DuelIsometryGameScreenState extends ConsumerState<DuelIsometryGameScreen> {
  int? _selectedPieceId;
  int? _selectedOrientation;
  int _localScore = 0;
  int _opponentScore = 0;

  final Map<int, ({int x, int y, int orientation})> _myPlacedPieces = {};
  final Map<int, ({int x, int y, int orientation})> _opponentPlacedPieces = {};

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(duelIsometryProvider);
    final notifier = ref.read(duelIsometryProvider.notifier);

    _updatePlacementsFromState(gameState);

    final isPlaying = gameState.gameState == DuelGameState.playing;
    final plateau = gameState.plateau;

    if (plateau == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Duel Isométries')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Duel Isométries'),
        centerTitle: true,
        actions: [
          if (gameState.timeRemaining != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '⏱️ ${gameState.timeRemaining}s',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isPlaying ? _buildPlayingState(gameState, plateau, notifier) : _buildGameState(gameState),
    );
  }

  Widget _buildCountdown(DuelIsometryState state) {
    final countdown = state.countdown ?? 0;
    final text = countdown > 0 ? '$countdown' : 'GO!';
    final color = countdown == 0 ? Colors.green : (countdown == 1 ? Colors.orange : Colors.blue);

    return Center(
      child: Text(
        text,
        style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildGameEnd(DuelIsometryState state) {
    final winner = state.localScore < state.opponentScore
        ? state.localPlayer?.name ?? 'Moi'
        : state.opponent?.name ?? 'Adversaire';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          const Text('Partie terminée!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Gagnant: $winner', style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text('Mes isométries: ${state.localScore}', style: const TextStyle(fontSize: 16)),
          Text('Isométries adversaire: ${state.opponentScore}', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  /// États autres (countdown, waiting, ended)
  Widget _buildGameState(DuelIsometryState state) {
    switch (state.gameState) {
      case DuelGameState.countdown:
        return _buildCountdown(state);
      case DuelGameState.ended:
        return _buildGameEnd(state);
      case DuelGameState.waiting:
        return _buildWaiting(state);
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  /// État de jeu en cours
  Widget _buildPlayingState(DuelIsometryState gameState, Plateau plateau, DuelIsometryNotifier notifier) {
    return Column(
      children: [
        // Scores header
        Container(
          color: Colors.blue.shade50,
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('${gameState.localPlayer?.name ?? "Moi"}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                  Text('$_localScore',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              Column(
                children: [
                  const Text('Pièces', style: TextStyle(fontSize: 12)),
                  Text('${_myPlacedPieces.length}/12',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                children: [
                  Text('${gameState.opponent?.name ?? "Adversaire"}',
                      style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                  Text('$_opponentScore',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ],
          ),
        ),

        // Plateau
        Expanded(
          child: SingleChildScrollView(
            child: DuelIsometryPlateau(
              solutionPlateau: plateau,
              myPlacedPieces: _myPlacedPieces,
              opponentPlacedPieces: _opponentPlacedPieces,
              isEnabled: true,
              myPlacedColor: Colors.blue,
              opponentPlacedColor: Colors.red,
              onCellTapped: (x, y) {
                if (_selectedPieceId != null && _selectedOrientation != null) {
                  _tryPlacePiece(notifier, plateau, _selectedPieceId!, x, y, _selectedOrientation!);
                }
              },
            ),
          ),
        ),

        // Slider des pièces (HAUTEUR FIXE!)
        Container(
          height: 200,
          color: Colors.grey.shade100,
          child: DuelIsometryPieceSlider(
            myPlacedPieces: _myPlacedPieces,
            opponentPlacedPieces: _opponentPlacedPieces,
            selectedPieceId: _selectedPieceId,
            isEnabled: true,
            myPlacedColor: Colors.blue,
            opponentPlacedColor: Colors.red,
            onPieceSelected: (pieceId, orientation) {
              setState(() {
                _selectedPieceId = pieceId;
                _selectedOrientation = orientation;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWaiting(DuelIsometryState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(state.opponent?.name != null ? 'Prêt à jouer avec ${state.opponent!.name}...' : 'En attente d\'un adversaire...'),
        ],
      ),
    );
  }

  void _tryPlacePiece(DuelIsometryNotifier notifier, Plateau plateau, int pieceId, int x, int y, int orientation) {
    if (_myPlacedPieces.containsKey(pieceId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pièce $pieceId déjà placée'), backgroundColor: Colors.red, duration: const Duration(seconds: 2)),
      );
      return;
    }

    final result = DuelIsometryValidator.validatePlacement(
      pieceId: pieceId,
      x: x,
      y: y,
      orientation: orientation,
      solutionPlateau: plateau,
    );

    if (!result.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${result.reason}'), backgroundColor: Colors.red, duration: const Duration(seconds: 2)),
      );
      return;
    }

    final isometries = DuelIsometryValidator.countIsometries(pieceId, orientation);

    setState(() {
      _myPlacedPieces[pieceId] = (x: x, y: y, orientation: orientation);
      _localScore += isometries;
      _selectedPieceId = null;
      _selectedOrientation = null;
    });

    print('[DUEL-ISO] ✅ Pièce $pieceId placée en ($x,$y) O$orientation (±$isometries)');

    notifier.placePiece(pieceId: pieceId, x: x, y: y, orientation: orientation);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Pièce $pieceId placée (+$isometries isométries)'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _updatePlacementsFromState(DuelIsometryState state) {
    _opponentScore = 0;

    for (final piece in state.placedPieces) {
      final isometries = DuelIsometryValidator.countIsometries(piece.pieceId, piece.orientation);

      if (piece.ownerId == state.localPlayer?.id) {
        // Placement de moi
      } else if (piece.ownerId == state.opponent?.id) {
        // Placement de l'adversaire
        _opponentPlacedPieces[piece.pieceId] = (x: piece.x, y: piece.y, orientation: piece.orientation);
        _opponentScore += isometries;
      }
    }
  }
}