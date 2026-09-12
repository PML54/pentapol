// Modified: 2026-09-12 06:30 — transmettre le réglage des vibrations à l’accueil guidé.
// Historique: 2026-09-11 16:11 — bouton Jouer permanent en tête pour passer directement de l’accueil au jeu.
// lib/pentoscope/home/home_screen.dart
// Historique: 2026-09-10 14:53 — accueil interactif : respecter le délai de prise réglé pour le jeu.
// Historique: 2026-09-10 10:24 — accueil : remplacer la démonstration passive par le 3×5 guidé.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/settings_screen.dart';
import 'package:pentapol/pentoscope/screens/records_screen.dart';
import 'package:pentapol/pentoscope/screens/challenge_screen.dart';
import 'package:pentapol/pentoscope_multiplayer/screens/pentoscope_mp_lobby_screen.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart'
    show sizeForLevel;
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart'
    show PentoscopeGameScreen;

import 'package:pentapol/pentoscope/home/guided_home.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, settings.currentLevel),
            Expanded(
              child: GuidedHome(
                colorOf: settings.ui.getPieceColor,
                ratio: settings.game.rackCellRatio,
                enableHaptics: settings.game.enableHaptics,
                longPressDuration: Duration(
                  milliseconds: settings.game.longPressDuration,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int level) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      // Accès direct au jeu, toujours visible ; deux icônes de chaque côté gardent le centre libre.
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.people, color: Colors.black87),
                iconSize: 32,
                tooltip: l10n.multiplayer,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PentoscopeMPLobbyScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.flag_outlined, color: Colors.black54),
                iconSize: 32,
                tooltip: l10n.homeChallenge,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChallengeScreen()),
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: FilledButton(
                key: const ValueKey('home-play'),
                onPressed: () => _play(context, level),
                child: Text(l10n.play),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.black54,
                ),
                iconSize: 32,
                tooltip: l10n.homeRecords,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecordsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.black54),
                iconSize: 32,
                tooltip: l10n.homeSettings,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _play(BuildContext context, int level) async {
    final notifier = ref.read(pentoscopeProvider.notifier);
    final st = ref.read(pentoscopeProvider);
    final size = sizeForLevel(level);
    final needFresh =
        st.puzzle == null ||
        st.isComplete ||
        !st.isProgression ||
        st.puzzle!.size != size;
    if (needFresh) {
      await notifier.startPuzzle(size, isProgression: true);
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PentoscopeGameScreen()),
    );
  }
}
