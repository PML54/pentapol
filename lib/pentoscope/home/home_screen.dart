// Modified: 2026-09-23 16:40 — maximiser la démo et compacter les actions inférieures.
// Historique: 2026-09-21 09:04 — ne pas relancer le training après un retour à l'accueil.
// Historique: 2026-09-21 08:49 — ouvrir le parcours initial avec le mode training explicite.
// Historique: 2026-09-12 06:30 — transmettre le réglage des vibrations à l’accueil guidé.
// Historique: 2026-09-11 16:11 — bouton Jouer permanent en tête pour passer directement de l’accueil au jeu.
// lib/pentoscope/home/home_screen.dart
// Historique: 2026-09-10 14:53 — accueil interactif : respecter le délai de prise réglé pour le jeu.
// Historique: 2026-09-10 10:24 — accueil : remplacer la démonstration passive par le 3×5 guidé.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/settings_screen.dart';
import 'package:pentapol/pentoscope/screens/challenge_screen.dart';
import 'package:pentapol/pentoscope/screens/records_screen.dart';
import 'package:pentapol/pentoscope_multiplayer/screens/pentoscope_mp_lobby_screen.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_mode.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart'
    show sizeForLevel;
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart'
    show PentoscopeGameScreen;
import 'package:pentapol/pentoscope/home/animated_home_board.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool startRecreationalOnOpen;

  const HomeScreen({super.key, this.startRecreationalOnOpen = false});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late bool _isLaunchingRecreational = widget.startRecreationalOnOpen;

  @override
  void initState() {
    super.initState();
    if (widget.startRecreationalOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playRecreational();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLaunchingRecreational
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMenu(context, settings.currentLevel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PentapolMark(size: 28),
              const SizedBox(width: 12),
              Text(
                l10n.appTitle,
                style: const TextStyle(
                  color: Color(0xFF27364A),
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              key: const ValueKey('home-records'),
              tooltip: l10n.homeRecords,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordsScreen()),
              ),
              icon: const Icon(
                Icons.emoji_events_outlined,
                color: Color(0xFF52657D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context, int level) {
    final settings = ref.watch(settingsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth > constraints.maxHeight;
        final demoHeight = (constraints.maxHeight - (landscape ? 12 : 130))
            .clamp(250.0, 380.0);
        final heightCellSize =
            (demoHeight - AnimatedHomeBoard.chromeHeight) / 5;
        final contentWidth = math.min(
          constraints.maxWidth - 16,
          landscape ? 720.0 : 520.0,
        );
        final demoWidth = landscape ? contentWidth - 24 - 320 : contentWidth;
        final widthCellSize = demoWidth / 6.4;
        final demoCellSize = math.min(heightCellSize, widthCellSize);
        final resolvedDemoHeight =
            demoCellSize * 5 + AnimatedHomeBoard.chromeHeight;
        final resolvedDemoWidth = demoCellSize * 6.4;
        final demo = ref.watch(homeDemoSolutionsProvider);
        final board = demo.when(
          data: (solutions) => AnimatedHomeBoard(
            key: const ValueKey('home-animated-board'),
            solutions: solutions,
            colorOf: settings.ui.getPieceColor,
            cellSize: demoCellSize,
          ),
          loading: () => SizedBox(
            key: const ValueKey('home-animated-board-loading'),
            width: resolvedDemoWidth,
            height: resolvedDemoHeight,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => SizedBox(
            width: resolvedDemoWidth,
            height: resolvedDemoHeight,
            child: const Icon(
              Icons.grid_view_rounded,
              color: Color(0xFF9AA8B8),
            ),
          ),
        );
        final actions = _HomeActions(
          onSolo: () => _play(context, level),
          onDuo: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PentoscopeMPLobbyScreen()),
          ),
          onChallenge: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChallengeScreen()),
          ),
          onTraining: _playRecreational,
          onSettings: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        );

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: landscape ? 6 : 8,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: landscape ? 720 : 520),
              child: landscape
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        board,
                        const SizedBox(width: 24),
                        SizedBox(width: 320, child: actions),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [board, const SizedBox(height: 10), actions],
                    ),
            ),
          ),
        );
      },
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

  Future<void> _playRecreational() async {
    if (!_isLaunchingRecreational && mounted) {
      setState(() => _isLaunchingRecreational = true);
    }
    final notifier = ref.read(pentoscopeProvider.notifier);
    await notifier.startRecreationalPuzzle();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PentoscopeGameScreen(mode: PentoscopeMode.training),
      ),
    );
    if (!mounted) return;
    setState(() => _isLaunchingRecreational = false);
  }
}

class _HomeActions extends StatelessWidget {
  final VoidCallback onSolo;
  final VoidCallback onDuo;
  final VoidCallback onChallenge;
  final VoidCallback onTraining;
  final VoidCallback onSettings;

  const _HomeActions({
    required this.onSolo,
    required this.onDuo,
    required this.onChallenge,
    required this.onTraining,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('home-play'),
                onPressed: onSolo,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.homeSolo),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3768C5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('home-multiplayer'),
                onPressed: onDuo,
                icon: const Icon(Icons.people_outline),
                label: Text(l10n.homeDuo),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3768C5),
                  side: const BorderSide(color: Color(0xFF9BB8E8)),
                  minimumSize: const Size.fromHeight(46),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _HomeDestination(
                key: const ValueKey('home-challenge'),
                icon: Icons.flag_outlined,
                label: l10n.homeChallenge,
                onTap: onChallenge,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HomeDestination(
                key: const ValueKey('home-training'),
                icon: Icons.school_outlined,
                label: l10n.guidedAnother,
                onTap: onTraining,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HomeDestination(
                key: const ValueKey('home-settings'),
                icon: Icons.tune,
                label: l10n.homeSettings,
                onTap: onSettings,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeDestination extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeDestination({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE0E4EA)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF52657D), size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF27364A),
                fontSize: 11.5,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PentapolMark extends StatelessWidget {
  final double size;

  const _PentapolMark({required this.size});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF4D9DF7),
      Color(0xFFFFD052),
      Color(0xFFE84A5F),
      Color(0xFF4DB6AC),
      Color(0xFFBA68C8),
    ];
    final cell = size / 3;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * cell,
              top: cell,
              child: _MarkCell(size: cell, color: colors[i]),
            ),
          Positioned(
            left: cell,
            top: 0,
            child: _MarkCell(size: cell, color: colors[3]),
          ),
          Positioned(
            left: cell,
            top: cell * 2,
            child: _MarkCell(size: cell, color: colors[4]),
          ),
        ],
      ),
    );
  }
}

class _MarkCell extends StatelessWidget {
  final double size;
  final Color color;

  const _MarkCell({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: Colors.white, width: size > 20 ? 2 : 1),
    ),
  );
}
