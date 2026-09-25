// Modified: 2026-09-25 02:30 — afficher le jour courant et distinguer les défis terminés.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/challenge_consent.dart';
import 'package:pentapol/pentoscope/pentoscope_mode.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/screens/leaderboard_screen.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';
import 'package:pentapol/providers/settings_provider.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  late Future<List<ChallengeDefinition>> _definitions;

  @override
  void initState() {
    super.initState();
    _definitions = _loadDefinitions();
    Future.microtask(
      () => ref.read(settingsProvider.notifier).dailyChallengeCompletions(),
    );
  }

  Future<List<ChallengeDefinition>> _loadDefinitions() async {
    final notifier = ref.read(pentoscopeProvider.notifier);
    return Future.wait([
      for (final size in kChallengeSizes)
        notifier.dailyChallengeDefinition(size),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final day = challengeDay();
    final weekday = _weekdayLabel(l10n, DateTime.now().toUtc().weekday);
    final completed = settings.dailyChallengeDay == day
        ? settings.completedDailyChallengeSizes.toSet()
        : <int>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.challengeOfDay(weekday)),
        actions: [
          IconButton(
            tooltip: l10n.rankingTooltip,
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => openLeaderboardWithConsent(
              context,
              ref,
              builder: () =>
                  LeaderboardScreen(day: day, size: kChallengeSizes.first),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<ChallengeDefinition>>(
          future: _definitions,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final definitions = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(day, style: TextStyle(color: Theme.of(context).hintColor)),
                const SizedBox(height: 4),
                Text(
                  l10n.challengeIntro,
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 12),
                for (int index = 0; index < definitions.length; index++)
                  _ChallengeTile(
                    definition: definitions[index],
                    completed: completed.contains(index),
                    unlocked: index == 0 || completed.contains(index - 1),
                    piecesLabel: l10n.piecesCount(
                      definitions[index].size.numPieces,
                    ),
                    rankingLabel: l10n.rankingTooltip,
                    onPlay: () => _launch(definitions[index]),
                    onRanking: () => openLeaderboardWithConsent(
                      context,
                      ref,
                      builder: () => LeaderboardScreen(
                        day: day,
                        size: definitions[index].size,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _launch(ChallengeDefinition definition) async {
    await ref
        .read(pentoscopeProvider.notifier)
        .startDailyChallenge(definition.size);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PentoscopeGameScreen(mode: PentoscopeMode.challenge),
      ),
    );
    if (mounted) setState(() {});
  }
}

class _ChallengeTile extends StatelessWidget {
  final ChallengeDefinition definition;
  final bool completed;
  final bool unlocked;
  final String piecesLabel;
  final String rankingLabel;
  final VoidCallback onPlay;
  final VoidCallback onRanking;

  const _ChallengeTile({
    required this.definition,
    required this.completed,
    required this.unlocked,
    required this.piecesLabel,
    required this.rankingLabel,
    required this.onPlay,
    required this.onRanking,
  });

  @override
  Widget build(BuildContext context) {
    final size = definition.size;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: completed ? const Color(0xFFEAF7EF) : null,
      surfaceTintColor: Colors.transparent,
      child: ListTile(
        enabled: unlocked && !completed,
        leading: Icon(
          completed
              ? Icons.check_circle
              : unlocked
              ? Icons.flag_outlined
              : Icons.lock_outline,
          color: completed ? const Color(0xFF2E9E5B) : null,
        ),
        title: Text(
          '${size.width}×${size.height}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$piecesLabel · ${definition.solutionCount} solutions'),
        trailing: completed
            ? IconButton(
                tooltip: rankingLabel,
                icon: const Icon(Icons.leaderboard_outlined),
                onPressed: onRanking,
              )
            : Icon(unlocked ? Icons.play_arrow : Icons.lock_outline),
        onTap: unlocked && !completed ? onPlay : null,
      ),
    );
  }
}

String _weekdayLabel(AppLocalizations l10n, int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return l10n.weekdayMonday;
    case DateTime.tuesday:
      return l10n.weekdayTuesday;
    case DateTime.wednesday:
      return l10n.weekdayWednesday;
    case DateTime.thursday:
      return l10n.weekdayThursday;
    case DateTime.friday:
      return l10n.weekdayFriday;
    case DateTime.saturday:
      return l10n.weekdaySaturday;
    default:
      return l10n.weekdaySunday;
  }
}
