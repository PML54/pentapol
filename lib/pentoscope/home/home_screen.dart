// Modified: 2026-10-02 06:49 — choisir un niveau débloqué au lancement d'une nouvelle partie Solo.
// Historique: 2026-10-02 06:39 — ajouter une remise à zéro confirmée des résultats locaux à l'accueil.
// Historique: 2026-09-29 06:05 — rendre le code couleur du niveau nettement visible dans le header.
// Historique: 2026-09-29 05:50 — ouvrir le profil joueur par une icône colorée selon le niveau et
//           agrandir les icônes du header.
// Historique: 2026-09-29 05:41 — afficher le niveau Solo sous Pentapol dans le header de l'accueil.
// Historique: 2026-09-29 05:41 — afficher le niveau local et la taille sur le bouton Jeu Solo.
// Historique: 2026-09-25 15:26 — retirer le bouton Réglages redondant de la rangée basse.
// Historique: 2026-09-25 15:00 — simplifier le header et agrandir ses icônes à 30 px ;
//             retirer la marque et remplacer Records par Réglages.
// Historique: 2026-09-25 14:43 — ajouter l'accès « À propos du développeur » dans le header.
// Historique: 2026-09-25 07:48 — accueil : icône Help dans le header, couleur par module et
//             Solo/Défi agrandis.
// Historique: 2026-09-25 02:30 — agrandir la démonstration et les actions sur tablette.
// Historique: 2026-09-23 16:40 — maximiser la démo et compacter les actions inférieures.
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
import 'package:pentapol/config/player_level_colors.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/help_screen.dart';
import 'package:pentapol/screens/settings_screen.dart';
import 'package:pentapol/pentoscope/screens/challenge_screen.dart';
import 'package:pentapol/pentoscope/screens/records_screen.dart';
import 'package:pentapol/pentoscope_multiplayer/screens/pentoscope_mp_lobby_screen.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_mode.dart';
import 'package:pentapol/pentoscope/solo_level_dialog.dart';
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
            _buildHeader(context, settings.currentLevel),
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

  Widget _buildHeader(BuildContext context, int level) {
    final l10n = AppLocalizations.of(context);
    final size = sizeForLevel(level);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF27364A),
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.homeSoloProgress(level, size.width, size.height),
                  key: const ValueKey('home-solo-progress'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: playerLevelColor(level),
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('home-player-profile'),
            tooltip: l10n.playerProfileTitle,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecordsScreen()),
            ),
            icon: Icon(
              Icons.person_outline,
              color: playerLevelColor(level),
              size: 36,
            ),
          ),
          IconButton(
            key: const ValueKey('home-help'),
            tooltip: l10n.helpTile,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
            icon: const Icon(
              Icons.help_outline,
              color: Color(0xFF52657D),
              size: 36,
            ),
          ),
          IconButton(
            key: const ValueKey('home-header-settings'),
            tooltip: l10n.settingsTitle,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF52657D),
              size: 36,
            ),
          ),
          IconButton(
            key: const ValueKey('home-reset-results'),
            tooltip: l10n.resetLocalResultsTitle,
            onPressed: _isLaunchingRecreational ? null : _resetLocalResults,
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Color(0xFFB43B43),
              size: 30,
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
        final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
        final demoHeight =
            (constraints.maxHeight - (landscape ? 12 : (tablet ? 175 : 130)))
                .clamp(250.0, tablet ? 700.0 : 380.0);
        final contentWidth = math.min(
          constraints.maxWidth - 16,
          landscape ? (tablet ? 1040.0 : 720.0) : (tablet ? 720.0 : 520.0),
        );
        final actionsWidth = tablet ? 380.0 : 320.0;
        final demoWidth = landscape
            ? contentWidth - 24 - actionsWidth
            : contentWidth;
        final widthCellSize = demoWidth / 6.4;
        final heightCellSize =
            (demoHeight -
                AnimatedHomeBoard.chromeHeightForCell(widthCellSize)) /
            5;
        final demoCellSize = math.min(heightCellSize, widthCellSize);
        final resolvedDemoHeight =
            demoCellSize * 5 +
            AnimatedHomeBoard.chromeHeightForCell(demoCellSize);
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
          expanded: tablet,
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
        );

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: landscape ? 6 : 8,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: landscape
                    ? (tablet ? 1040 : 720)
                    : (tablet ? 720 : 520),
              ),
              child: landscape
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        board,
                        const SizedBox(width: 24),
                        SizedBox(width: actionsWidth, child: actions),
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
        (level > 1 && st.placedPieces.isEmpty) ||
        !st.isProgression ||
        st.puzzle!.size != size;
    if (needFresh) {
      final chosen = await showSoloLevelDialog(context, unlockedLevel: level);
      if (chosen == null || !context.mounted) return;
      await notifier.startPuzzle(
        sizeForLevel(chosen),
        isProgression: chosen == ref.read(settingsProvider).currentLevel,
      );
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PentoscopeGameScreen()),
    );
  }

  Future<void> _resetLocalResults() async {
    final l10n = AppLocalizations.of(context);
    var busy = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => PopScope(
          canPop: !busy,
          child: AlertDialog(
            title: Text(l10n.resetLocalResultsTitle),
            content: busy
                ? const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Text(l10n.resetLocalResultsConfirm),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        setDialogState(() => busy = true);
                        try {
                          await ref
                              .read(settingsProvider.notifier)
                              .resetLocalResults();
                          ref
                              .read(pentoscopeProvider.notifier)
                              .discardCurrentGameAfterLocalReset();
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(l10n.resetLocalResultsDone)),
                          );
                        } catch (_) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() => busy = false);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(l10n.genericError)),
                          );
                        }
                      },
                child: Text(l10n.reset),
              ),
            ],
          ),
        ),
      ),
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
  final bool expanded;
  final VoidCallback onSolo;
  final VoidCallback onDuo;
  final VoidCallback onChallenge;
  final VoidCallback onTraining;

  const _HomeActions({
    required this.expanded,
    required this.onSolo,
    required this.onDuo,
    required this.onChallenge,
    required this.onTraining,
  });

  // Une couleur distincte par module (accès), pour les distinguer d'un coup d'œil.
  static const Color _soloColor = Color(0xFF3768C5); // bleu
  static const Color _challengeColor = Color(0xFFF57C00); // orange
  static const Color _duoColor = Color(0xFF00897B); // turquoise
  static const Color _trainingColor = Color(0xFF8E24AA); // violet

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rangée principale, volontairement plus grande : Solo et Défi.
        Row(
          children: [
            Expanded(
              child: _buildPrimary(
                key: const ValueKey('home-play'),
                icon: Icons.play_arrow_rounded,
                label: l10n.homeSolo,
                color: _soloColor,
                onPressed: onSolo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPrimary(
                key: const ValueKey('home-challenge'),
                icon: Icons.flag_outlined,
                label: l10n.homeChallenge,
                color: _challengeColor,
                onPressed: onChallenge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _HomeDestination(
                key: const ValueKey('home-multiplayer'),
                icon: Icons.people_outline,
                label: l10n.homeDuo,
                color: _duoColor,
                expanded: expanded,
                onTap: onDuo,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HomeDestination(
                key: const ValueKey('home-training'),
                icon: Icons.school_outlined,
                label: l10n.guidedAnother,
                color: _trainingColor,
                expanded: expanded,
                onTap: onTraining,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Grand bouton plein (Solo, Défi) : plus haut et police plus grande que les accès
  /// secondaires, chacun avec sa couleur de module.
  Widget _buildPrimary({
    required Key key,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return FilledButton.icon(
      key: key,
      onPressed: onPressed,
      icon: Icon(icon, size: expanded ? 32 : 27),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: Size.fromHeight(expanded ? 82 : 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(
          fontSize: expanded ? 26 : 21,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HomeDestination extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool expanded;

  const _HomeDestination({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) => Material(
    // Fond teinté clair + bord et icône dans la couleur du module : distingue les accès
    // sans écraser la lisibilité du libellé (qui reste en encre sombre).
    color: color.withValues(alpha: 0.10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 4,
          vertical: expanded ? 10 : 6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: expanded ? 27 : 20),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF27364A),
                fontSize: expanded ? 14 : 11.5,
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
