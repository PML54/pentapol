#!/bin/bash
# ============================================================
# Script de création de l'arborescence du mode Duel
# À exécuter depuis ~/StudioProjects/pentapol/
# ============================================================

echo "🎮 Création de l'arborescence du mode Duel..."
echo ""

# Vérifier qu'on est dans le bon dossier
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Erreur: Exécutez ce script depuis le dossier racine du projet Flutter"
    echo "   cd ~/StudioProjects/pentapol"
    echo "   ./create_duel_structure.sh"
    exit 1
fi

# ============================================================
# Création des dossiers
# ============================================================

echo "📁 Création des dossiers..."

mkdir -p lib/duel/models
mkdir -p lib/duel/providers
mkdir -p lib/duel/services
mkdir -p lib/duel/screens
mkdir -p lib/duel/widgets

echo "   ✅ lib/duel/models/"
echo "   ✅ lib/duel/providers/"
echo "   ✅ lib/duel/services/"
echo "   ✅ lib/duel/screens/"
echo "   ✅ lib/duel/widgets/"

# ============================================================
# Création des fichiers models/
# ============================================================

echo ""
echo "📄 Création des fichiers models/..."

cat > lib/duel/models/duel_state.dart << 'EOF'
// lib/duel/models/duel_state.dart
// État d'une partie duel multijoueur
// TODO: Implémenter

import 'package:flutter/foundation.dart';

@immutable
class DuelState {
  // TODO: Ajouter les champs
  const DuelState();

  factory DuelState.initial() => const DuelState();
}
EOF
echo "   ✅ duel_state.dart"

cat > lib/duel/models/duel_messages.dart << 'EOF'
// lib/duel/models/duel_messages.dart
// Messages WebSocket client ↔ serveur
// TODO: Implémenter

// Messages Client → Serveur
// Messages Serveur → Client
EOF
echo "   ✅ duel_messages.dart"

# ============================================================
# Création des fichiers providers/
# ============================================================

echo ""
echo "📄 Création des fichiers providers/..."

cat > lib/duel/providers/duel_provider.dart << 'EOF'
// lib/duel/providers/duel_provider.dart
// Provider Riverpod pour la gestion du mode duel
// TODO: Implémenter

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/duel_state.dart';

final duelProvider = NotifierProvider<DuelNotifier, DuelState>(() {
  return DuelNotifier();
});

class DuelNotifier extends Notifier<DuelState> {
  @override
  DuelState build() => DuelState.initial();

  // TODO: Ajouter les méthodes
}
EOF
echo "   ✅ duel_provider.dart"

# ============================================================
# Création des fichiers services/
# ============================================================

echo ""
echo "📄 Création des fichiers services/..."

cat > lib/duel/services/websocket_service.dart << 'EOF'
// lib/duel/services/websocket_service.dart
// Service de connexion WebSocket
// TODO: Implémenter

class WebSocketService {
  final String serverUrl;

  WebSocketService({required this.serverUrl});

  // TODO: Ajouter les méthodes connect, send, etc.
}
EOF
echo "   ✅ websocket_service.dart"

cat > lib/duel/services/duel_validator.dart << 'EOF'
// lib/duel/services/duel_validator.dart
// Validation des placements contre la solution
// TODO: Implémenter

class DuelValidator {
  /// Vérifie si un placement est valide pour la solution donnée
  static bool isValidPlacement({
    required int solutionId,
    required int pieceId,
    required int x,
    required int y,
    required int orientation,
  }) {
    // TODO: Implémenter la validation
    return false;
  }
}
EOF
echo "   ✅ duel_validator.dart"

# ============================================================
# Création des fichiers screens/
# ============================================================

echo ""
echo "📄 Création des fichiers screens/..."

cat > lib/duel/screens/duel_home_screen.dart << 'EOF'
// lib/duel/screens/duel_home_screen.dart
// Écran d'accueil du mode duel (créer/rejoindre)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuelHomeScreen extends ConsumerWidget {
  const DuelHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Duel'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Bouton Créer une partie
            ElevatedButton(
              onPressed: () {
                // TODO: Naviguer vers création
              },
              child: const Text('Créer une partie'),
            ),
            const SizedBox(height: 20),
            // TODO: Bouton Rejoindre une partie
            ElevatedButton(
              onPressed: () {
                // TODO: Naviguer vers rejoindre
              },
              child: const Text('Rejoindre une partie'),
            ),
          ],
        ),
      ),
    );
  }
}
EOF
echo "   ✅ duel_home_screen.dart"

cat > lib/duel/screens/duel_create_screen.dart << 'EOF'
// lib/duel/screens/duel_create_screen.dart
// Écran de création de partie (affiche le code)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuelCreateScreen extends ConsumerStatefulWidget {
  const DuelCreateScreen({super.key});

  @override
  ConsumerState<DuelCreateScreen> createState() => _DuelCreateScreenState();
}

class _DuelCreateScreenState extends ConsumerState<DuelCreateScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une partie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Champ nom du joueur
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Votre pseudo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // TODO: Bouton créer
            ElevatedButton(
              onPressed: () {
                // TODO: Créer la room
              },
              child: const Text('Créer'),
            ),
            // TODO: Afficher le code de la room
            // TODO: Boutons Copier / Partager
            // TODO: Message "En attente d'un adversaire..."
          ],
        ),
      ),
    );
  }
}
EOF
echo "   ✅ duel_create_screen.dart"

cat > lib/duel/screens/duel_join_screen.dart << 'EOF'
// lib/duel/screens/duel_join_screen.dart
// Écran pour rejoindre une partie (saisir le code)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuelJoinScreen extends ConsumerStatefulWidget {
  const DuelJoinScreen({super.key});

  @override
  ConsumerState<DuelJoinScreen> createState() => _DuelJoinScreenState();
}

class _DuelJoinScreenState extends ConsumerState<DuelJoinScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejoindre une partie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Champ nom du joueur
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Votre pseudo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Champ code de la room
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Code de la partie',
                border: OutlineInputBorder(),
                hintText: 'ABC123',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
            const SizedBox(height: 24),
            // TODO: Bouton rejoindre
            ElevatedButton(
              onPressed: () {
                // TODO: Rejoindre la room
              },
              child: const Text('Rejoindre'),
            ),
          ],
        ),
      ),
    );
  }
}
EOF
echo "   ✅ duel_join_screen.dart"

cat > lib/duel/screens/duel_waiting_screen.dart << 'EOF'
// lib/duel/screens/duel_waiting_screen.dart
// Écran d'attente d'un adversaire

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuelWaitingScreen extends ConsumerWidget {
  final String roomCode;

  const DuelWaitingScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('En attente...'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Code de la partie',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            // TODO: Afficher le code en grand
            Text(
              roomCode,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 24),
            // TODO: Boutons Copier / Partager
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: roomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copié !')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Partager
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                ),
              ],
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('En attente d\'un adversaire...'),
          ],
        ),
      ),
    );
  }
}
EOF
echo "   ✅ duel_waiting_screen.dart"

cat > lib/duel/screens/duel_game_screen.dart << 'EOF'
// lib/duel/screens/duel_game_screen.dart
// Écran principal du jeu duel (plateau partagé)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuelGameScreen extends ConsumerWidget {
  const DuelGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duel en cours'),
        // TODO: Afficher timer, scores
      ),
      body: Column(
        children: [
          // TODO: Barre de score
          // - Nom joueur 1 : score
          // - Timer
          // - Nom joueur 2 : score

          // TODO: Plateau de jeu partagé
          // - Pièces du joueur local en couleur normale
          // - Pièces de l'adversaire avec hachures

          // TODO: Slider des pièces
          // - Pièces disponibles
          // - Pièces déjà placées grisées
        ],
      ),
    );
  }
}
EOF
echo "   ✅ duel_game_screen.dart"

cat > lib/duel/screens/duel_result_screen.dart << 'EOF'
// lib/duel/screens/duel_result_screen.dart
// Écran de résultat de la partie

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuelResultScreen extends ConsumerWidget {
  const DuelResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Afficher victoire/défaite/égalité
            const Icon(
              Icons.emoji_events,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            const Text(
              'Victoire !',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Afficher les scores
            const Text('Vous : 7 - Adversaire : 5'),
            const SizedBox(height: 48),
            // TODO: Boutons rejouer / retour
            ElevatedButton(
              onPressed: () {
                // TODO: Revanche
              },
              child: const Text('Revanche'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // TODO: Retour au menu
              },
              child: const Text('Retour au menu'),
            ),
          ],
        ),
      ),
    );
  }
}
EOF
echo "   ✅ duel_result_screen.dart"

# ============================================================
# Création des fichiers widgets/
# ============================================================

echo ""
echo "📄 Création des fichiers widgets/..."

cat > lib/duel/widgets/duel_scoreboard.dart << 'EOF'
// lib/duel/widgets/duel_scoreboard.dart
// Barre de score affichant les 2 joueurs et le timer

import 'package:flutter/material.dart';

class DuelScoreboard extends StatelessWidget {
  final String player1Name;
  final int player1Score;
  final String player2Name;
  final int player2Score;
  final int timeRemaining;
  final bool isPlayer1Local;

  const DuelScoreboard({
    super.key,
    required this.player1Name,
    required this.player1Score,
    required this.player2Name,
    required this.player2Score,
    required this.timeRemaining,
    required this.isPlayer1Local,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        children: [
          // Joueur 1
          Expanded(
            child: _PlayerScore(
              name: player1Name,
              score: player1Score,
              isLocal: isPlayer1Local,
            ),
          ),
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: timeRemaining < 30 ? Colors.red : Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatTime(timeRemaining),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Joueur 2
          Expanded(
            child: _PlayerScore(
              name: player2Name,
              score: player2Score,
              isLocal: !isPlayer1Local,
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

class _PlayerScore extends StatelessWidget {
  final String name;
  final int score;
  final bool isLocal;
  final bool alignRight;

  const _PlayerScore({
    required this.name,
    required this.score,
    required this.isLocal,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocal) const Icon(Icons.person, size: 16, color: Colors.green),
            if (isLocal) const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                fontWeight: isLocal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        Text(
          '$score pièces',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
EOF
echo "   ✅ duel_scoreboard.dart"

cat > lib/duel/widgets/opponent_piece_overlay.dart << 'EOF'
// lib/duel/widgets/opponent_piece_overlay.dart
// Overlay de hachures pour les pièces de l'adversaire

import 'package:flutter/material.dart';

/// Widget qui affiche des hachures sur une pièce adverse
class OpponentPieceOverlay extends StatelessWidget {
  final Widget child;
  final Color hatchColor;
  final double hatchWidth;
  final double hatchSpacing;

  const OpponentPieceOverlay({
    super.key,
    required this.child,
    this.hatchColor = Colors.black,
    this.hatchWidth = 2.0,
    this.hatchSpacing = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: CustomPaint(
            painter: _HatchPainter(
              color: hatchColor.withOpacity(0.3),
              strokeWidth: hatchWidth,
              spacing: hatchSpacing,
            ),
          ),
        ),
      ],
    );
  }
}

/// Painter pour dessiner des hachures diagonales
class _HatchPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double spacing;

  _HatchPainter({
    required this.color,
    required this.strokeWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Dessiner des lignes diagonales (haut-gauche vers bas-droite)
    final maxDimension = size.width + size.height;

    for (double i = -maxDimension; i < maxDimension; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.spacing != spacing;
  }
}
EOF
echo "   ✅ opponent_piece_overlay.dart"

cat > lib/duel/widgets/duel_countdown.dart << 'EOF'
// lib/duel/widgets/duel_countdown.dart
// Affichage du compte à rebours (3, 2, 1, GO!)

import 'package:flutter/material.dart';

class DuelCountdown extends StatelessWidget {
  final int value; // 3, 2, 1, 0 (0 = GO!)

  const DuelCountdown({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1.0),
          duration: const Duration(milliseconds: 300),
          key: ValueKey(value),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Text(
            value == 0 ? 'GO!' : '$value',
            style: TextStyle(
              fontSize: value == 0 ? 120 : 150,
              fontWeight: FontWeight.bold,
              color: value == 0 ? Colors.green : Colors.white,
              shadows: const [
                Shadow(
                  blurRadius: 20,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
EOF
echo "   ✅ duel_countdown.dart"

cat > lib/duel/widgets/duel_piece_slider.dart << 'EOF'
// lib/duel/widgets/duel_piece_slider.dart
// Slider des pièces pour le mode duel

import 'package:flutter/material.dart';

class DuelPieceSlider extends StatelessWidget {
  final List<int> availablePieces;   // Pièces disponibles (pas encore placées)
  final List<int> myPlacedPieces;    // Pièces que j'ai placées
  final List<int> opponentPieces;    // Pièces placées par l'adversaire
  final int? selectedPiece;
  final ValueChanged<int> onPieceSelected;
  final VoidCallback? onRotate;

  const DuelPieceSlider({
    super.key,
    required this.availablePieces,
    required this.myPlacedPieces,
    required this.opponentPieces,
    this.selectedPiece,
    required this.onPieceSelected,
    this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Implémenter le slider
    // - Pièces disponibles : normales, sélectionnables
    // - Mes pièces placées : vertes, non sélectionnables
    // - Pièces adversaire : rouges/grisées, non sélectionnables
    return Container(
      height: 100,
      color: Colors.grey[300],
      child: const Center(
        child: Text('TODO: Slider des pièces'),
      ),
    );
  }
}
EOF
echo "   ✅ duel_piece_slider.dart"

# ============================================================
# Création du fichier barrel (exports)
# ============================================================

echo ""
echo "📄 Création du fichier barrel (exports)..."

cat > lib/duel/duel.dart << 'EOF'
// lib/duel/duel.dart
// Barrel file - Exporte tous les composants du mode duel

// Models
export 'models/duel_state.dart';
export 'models/duel_messages.dart';

// Providers
export 'providers/duel_provider.dart';

// Services
export 'services/websocket_service.dart';
export 'services/duel_validator.dart';

// Screens
export 'screens/duel_home_screen.dart';
export 'screens/duel_create_screen.dart';
export 'screens/duel_join_screen.dart';
export 'screens/duel_waiting_screen.dart';
export 'screens/duel_game_screen.dart';
export 'screens/duel_result_screen.dart';

// Widgets
export 'widgets/duel_scoreboard.dart';
export 'widgets/opponent_piece_overlay.dart';
export 'widgets/duel_countdown.dart';
export 'widgets/duel_piece_slider.dart';
EOF
echo "   ✅ duel.dart (barrel)"

# ============================================================
# Résumé
# ============================================================

echo ""
echo "============================================================"
echo "✅ Arborescence créée avec succès !"
echo "============================================================"
echo ""
echo "📁 Structure créée :"
echo ""
echo "lib/duel/"
echo "├── duel.dart                    (barrel exports)"
echo "├── models/"
echo "│   ├── duel_state.dart"
echo "│   └── duel_messages.dart"
echo "├── providers/"
echo "│   └── duel_provider.dart"
echo "├── services/"
echo "│   ├── websocket_service.dart"
echo "│   └── duel_validator.dart"
echo "├── screens/"
echo "│   ├── duel_home_screen.dart"
echo "│   ├── duel_create_screen.dart"
echo "│   ├── duel_join_screen.dart"
echo "│   ├── duel_waiting_screen.dart"
echo "│   ├── duel_game_screen.dart"
echo "│   └── duel_result_screen.dart"
echo "└── widgets/"
echo "    ├── duel_scoreboard.dart"
echo "    ├── opponent_piece_overlay.dart"
echo "    ├── duel_countdown.dart"
echo "    └── duel_piece_slider.dart"
echo ""
echo "============================================================"
echo "📦 N'oubliez pas d'ajouter la dépendance dans pubspec.yaml :"
echo ""
echo "dependencies:"
echo "  web_socket_channel: ^2.4.0"
echo ""
echo "Puis exécutez : flutter pub get"
echo "============================================================"