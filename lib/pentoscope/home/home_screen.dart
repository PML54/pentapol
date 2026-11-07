// Modified: 2026-11-05 10:05 — unifier Jeu Iso avec Solo/Duo, fond orange Iso et noir Défi.
// Historique: 2026-10-29 07:42 — reprendre le cycle des cibles équilibrées depuis tous les accès au Training.
// Historique: 2026-11-05 09:58 — accueil : Jeu Iso, retrait de Training et classement agrandi en secondes.
// Historique: 2026-11-04 10:20 — remonter le menu et le classement dans l’espace disponible.
// Historique: 2026-10-31 06:15 — nommer le défi quotidien selon le jour de semaine.
// Historique: 2026-10-31 06:11 — nommer la Battle par jour et masquer les podiums sans score.
// Historique: 2026-10-30 08:52 — réorganiser les accès et afficher les Tops quotidiens.
// Historique: 2026-10-29 07:26 — respecter le réglage des vibrations dans tous les accès au Training.
// Historique: 2026-10-28 08:19 — ouvrir le Training guidé 5×5 depuis l’accueil et l’aide.
// Historique: 2026-10-28 05:27 — terminer la découverte uniquement par Jouer ou Passer.
// Historique: 2026-10-28 05:01 — remplacer la démo par une découverte initiale, rejouable depuis l’aide.
// Historique: 2026-10-26 15:15 — démarrer l’essai depuis l’aide avec cinq pièces à parcourir.
// Historique: 2026-10-26 15:02 — proposer l’aide initiale puis un essai guidé à une pièce.
// Historique: 2026-10-09 07:33 — entrée isométries indépendante du Training 3x5.
// Historique: 2026-10-02 06:49 — choisir un niveau débloqué au lancement d'une nouvelle partie Solo.
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/config/player_level_colors.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/help_screen.dart';
import 'package:pentapol/screens/settings_screen.dart';
import 'package:pentapol/pentoscope/screens/challenge_screen.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/screens/records_screen.dart';
import 'package:pentapol/pentoscope_multiplayer/screens/pentoscope_mp_lobby_screen.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_mode.dart';
import 'package:pentapol/pentoscope/solo_level_dialog.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart'
    show PentoscopeSize, sizeForLevel;
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart'
    show PentoscopeGameScreen;
import 'package:pentapol/pentoscope/home/discovery_screen.dart';
import 'package:pentapol/pentoscope/home/daily_challenge_tops.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool showDiscoveryOnOpen;

  const HomeScreen({super.key, this.showDiscoveryOnOpen = false});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLaunchingGame = false;
  late bool _showDiscovery = widget.showDiscoveryOnOpen;
  late final int _initialDiscoveryExercise = ref
      .read(settingsProvider)
      .discoveryNextExercise;
  Future<void>? _discoverySaved;

  Future<void> _completeDiscovery() => _discoverySaved ??= ref
      .read(settingsProvider.notifier)
      .markDiscoveryCompleted();

  Future<void> _leaveInitialDiscovery({bool play = false}) async {
    await _completeDiscovery();
    if (!mounted) return;
    setState(() => _showDiscovery = false);
    if (play) await _startFirstSolo();
  }

  Future<void> _openHelp() async {
    final discover = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HelpScreen(onStart: () => Navigator.pop(context, true)),
      ),
    );
    if (mounted && discover == true) await _openDiscovery();
  }

  Future<void> _openDiscovery() async {
    final initialExerciseIndex = ref
        .read(settingsProvider)
        .discoveryNextExercise;
    final play = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (routeContext) => DiscoveryScreen(
          initialExerciseIndex: initialExerciseIndex,
          onExerciseStarted: (next) => ref
              .read(settingsProvider.notifier)
              .setDiscoveryNextExercise(next),
          colorOf: ref.read(settingsProvider).ui.getPieceColor,
          enableHaptics: ref.read(settingsProvider).game.enableHaptics,
          longPressDuration: Duration(
            milliseconds: ref.read(settingsProvider).game.longPressDuration,
          ),
          onSkip: () async {
            await _completeDiscovery();
            if (routeContext.mounted) Navigator.pop(routeContext, false);
          },
          onPlay: () async {
            await _completeDiscovery();
            if (routeContext.mounted) Navigator.pop(routeContext, true);
          },
        ),
      ),
    );
    if (mounted && play == true) await _startFirstSolo();
  }

  Future<void> _startFirstSolo() async {
    setState(() => _isLaunchingGame = true);
    try {
      await ref
          .read(pentoscopeProvider.notifier)
          .startPuzzle(
            PentoscopeSize.size3x5,
            isProgression: ref.read(settingsProvider).currentLevel == 1,
          );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PentoscopeGameScreen()),
      );
    } finally {
      if (mounted) setState(() => _isLaunchingGame = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    if (_showDiscovery) {
      return DiscoveryScreen(
        initialExerciseIndex: _initialDiscoveryExercise,
        onExerciseStarted: (next) =>
            ref.read(settingsProvider.notifier).setDiscoveryNextExercise(next),
        colorOf: settings.ui.getPieceColor,
        enableHaptics: settings.game.enableHaptics,
        longPressDuration: Duration(
          milliseconds: settings.game.longPressDuration,
        ),
        onSkip: _leaveInitialDiscovery,
        onPlay: () => _leaveInitialDiscovery(play: true),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, settings.currentLevel),
            Expanded(
              child: _isLaunchingGame
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
            onPressed: _openHelp,
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
            onPressed: _isLaunchingGame ? null : _resetLocalResults,
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

  Widget _buildMenu(BuildContext context, int level) => Align(
    alignment: Alignment.topCenter,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: _HomeActions(
          expanded: true,
          onSolo: () => _play(context, level),
          onDuo: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PentoscopeMPLobbyScreen()),
          ),
          onChallenge: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChallengeScreen()),
          ),
          onIsometries: _playIsometries,
        ),
      ),
    ),
  );

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

  Future<void> _playIsometries() async {
    if (_isLaunchingGame) return;
    setState(() => _isLaunchingGame = true);
    try {
      await ref.read(pentoscopeProvider.notifier).startIsometryTraining();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const PentoscopeGameScreen(mode: PentoscopeMode.training),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).genericError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunchingGame = false);
    }
  }
}

class _HomeActions extends StatelessWidget {
  final bool expanded;
  final VoidCallback onSolo;
  final VoidCallback onDuo;
  final VoidCallback onChallenge;
  final VoidCallback onIsometries;

  const _HomeActions({
    required this.expanded,
    required this.onSolo,
    required this.onDuo,
    required this.onChallenge,
    required this.onIsometries,
  });

  // Une couleur distincte par module (accès), pour les distinguer d'un coup d'œil.
  static const Color _soloColor = Color(0xFF3768C5); // bleu
  static const Color _challengeColor = Colors.black;
  static const Color _isoColor = Color(0xFFF57C00); // orange
  static const Color _duoColor = Color(0xFF00897B); // turquoise

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DailyChallengeTops(),
        _buildPrimary(
          key: const ValueKey('home-challenge'),
          icon: Icons.flag_outlined,
          label: l10n.homeDailyChallenge(
            DateFormat.EEEE(
              l10n.localeName,
            ).format(DateTime.parse(challengeDay())),
          ),
          color: _challengeColor,
          onPressed: onChallenge,
        ),
        const SizedBox(height: 10),
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
                key: const ValueKey('home-multiplayer'),
                icon: Icons.people_outline,
                label: l10n.homeDuo,
                color: _duoColor,
                onPressed: onDuo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildPrimary(
          key: const ValueKey('home-isometries'),
          icon: Icons.flip,
          label: l10n.homeIso,
          color: _isoColor,
          onPressed: onIsometries,
        ),
      ],
    );
  }

  /// Bouton plein partagé entre Solo, Duo, Jeu Iso et Défi.
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
