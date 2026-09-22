// Modified: 2026-09-21 17:13 — remplacer l'accueil vide par un menu principal responsive.
// Historique: 2026-09-21 09:04 — ne pas relancer le training après un retour à l'accueil.
// Historique: 2026-09-21 08:49 — ouvrir le parcours initial avec le mode training explicite.
// Historique: 2026-09-12 06:30 — transmettre le réglage des vibrations à l’accueil guidé.
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
import 'package:pentapol/pentoscope/pentoscope_mode.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart'
    show sizeForLevel;
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart'
    show PentoscopeGameScreen;

class HomeScreen extends ConsumerStatefulWidget {
  final bool startRecreationalOnOpen;

  const HomeScreen({super.key, this.startRecreationalOnOpen = true});
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
        if (mounted) _playRecreational(context);
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }

  Widget _buildMenu(BuildContext context, int level) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth > constraints.maxHeight;
        final playPanel = _PlayPanel(
          level: l10n.levelLabel(level),
          playLabel: l10n.play,
          trainingLabel: l10n.guidedAnother,
          onPlay: () => _play(context, level),
          onTraining: () => _playRecreational(context),
        );
        final destinations = GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: landscape ? 1.65 : 1.45,
          children: [
            _HomeDestination(
              key: const ValueKey('home-challenge'),
              icon: Icons.flag_outlined,
              color: const Color(0xFFE84A5F),
              label: l10n.homeChallenge,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChallengeScreen()),
              ),
            ),
            _HomeDestination(
              key: const ValueKey('home-multiplayer'),
              icon: Icons.people_outline,
              color: const Color(0xFF3768C5),
              label: l10n.multiplayer,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PentoscopeMPLobbyScreen(),
                ),
              ),
            ),
            _HomeDestination(
              key: const ValueKey('home-records'),
              icon: Icons.emoji_events_outlined,
              color: const Color(0xFFE9A820),
              label: l10n.homeRecords,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordsScreen()),
              ),
            ),
            _HomeDestination(
              key: const ValueKey('home-settings'),
              icon: Icons.tune,
              color: const Color(0xFF657487),
              label: l10n.homeSettings,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        );

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: landscape
                  ? SizedBox(
                      height: constraints.maxHeight - 40,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 280, child: playPanel),
                          const SizedBox(width: 24),
                          Expanded(child: destinations),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        playPanel,
                        const SizedBox(height: 20),
                        destinations,
                      ],
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

  Future<void> _playRecreational(BuildContext context) async {
    if (!_isLaunchingRecreational && mounted) {
      setState(() => _isLaunchingRecreational = true);
    }
    final notifier = ref.read(pentoscopeProvider.notifier);
    await notifier.startRecreationalPuzzle();
    if (!context.mounted) return;
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

class _PlayPanel extends StatelessWidget {
  final String level;
  final String playLabel;
  final String trainingLabel;
  final VoidCallback onPlay;
  final VoidCallback onTraining;

  const _PlayPanel({
    required this.level,
    required this.playLabel,
    required this.trainingLabel,
    required this.onPlay,
    required this.onTraining,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 250),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFF27364A),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: _PentapolMark(size: 48),
        ),
        const SizedBox(height: 28),
        Text(
          level,
          style: const TextStyle(
            color: Color(0xFFCAD2DE),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const ValueKey('home-play'),
          onPressed: onPlay,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(playLabel),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4D9DF7),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const ValueKey('home-training'),
          onPressed: onTraining,
          icon: const Icon(Icons.school_outlined),
          label: Text(trainingLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF8392A7)),
            minimumSize: const Size.fromHeight(46),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HomeDestination extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _HomeDestination({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE0E4EA)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF27364A),
                  fontSize: 15,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
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
