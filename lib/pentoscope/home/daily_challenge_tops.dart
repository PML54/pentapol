// Modified: 2026-11-17 09:57 — partager et afficher la ceinture acquise dans les classements.
// Historique: 2026-11-11 06:37 — identifier le joueur courant dans les résultats publics.
// Historique: 2026-11-11 06:07 — titrer les résultats par Défi et niveau sans le jour.
// Historique: 2026-11-11 06:00 — afficher les noms partagés des niveaux dans les classements quotidiens.
// Historique: 2026-11-05 09:58 — accueil : Jeu Iso, retrait de Training et classement agrandi en secondes.
// lib/pentoscope/home/daily_challenge_tops.dart
// Historique: 2026-11-04 10:20 — actualiser au retour à l’accueil et afficher les cinq meilleurs temps par taille.
// Historique: 2026-10-31 06:15 — limiter les podiums de l’accueil au classement en temps.
// Historique: 2026-10-31 06:11 — nommer la Battle par jour et masquer les podiums sans score.
// Historique: 2026-10-30 08:52 — faire défiler les podiums Temps et Stratégie des défis du jour.

import 'dart:async';
import 'package:pentapol/config/challenge_belts.dart';

import 'package:pentapol/config/player_level_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/challenge_api.dart';
import 'package:pentapol/pentoscope/challenge_consent.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/screens/leaderboard_screen.dart';
import 'package:pentapol/providers/settings_provider.dart';

typedef _Top = ({PentoscopeSize size, List<LeaderboardEntry> podium});

final _dailyTopsProvider = FutureProvider.autoDispose
    .family<List<_Top>, String>((ref, day) async {
      final api = ref.watch(challengeApiProvider);
      final groups = await Future.wait([
        for (final size in kChallengeSizes)
          () async {
            final entries = await api.leaderboard(
              version: kChallengeVersion,
              day: day,
              size: size.index,
              maillot: Maillot.temps,
              limit: 5,
            );
            return <_Top>[
              if (entries.isNotEmpty)
                (size: size, podium: entries.take(5).toList()),
            ];
          }(),
      ]);
      return groups.expand((group) => group).toList();
    });

class DailyChallengeTops extends ConsumerStatefulWidget {
  const DailyChallengeTops({super.key});

  @override
  ConsumerState<DailyChallengeTops> createState() => _DailyChallengeTopsState();
}

class _DailyChallengeTopsState extends ConsumerState<DailyChallengeTops>
    with WidgetsBindingObserver {
  final _pages = PageController();
  late final Timer _timer;
  String _day = challengeDay();
  int _page = 0;
  int _count = 0;
  bool _wasCurrent = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final day = challengeDay();
      if (day != _day) {
        setState(() {
          _day = day;
          _page = 0;
        });
        if (_pages.hasClients) _pages.jumpToPage(0);
        return;
      }
      if (!_pages.hasClients ||
          _count < 2 ||
          MediaQuery.disableAnimationsOf(context) ||
          ModalRoute.of(context)?.isCurrent != true ||
          _pages.position.isScrollingNotifier.value) {
        return;
      }
      _pages.animateToPage(
        (_page + 1) % _count,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.isCurrentOf(context) ?? true;
    if (current && !_wasCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh();
      });
    }
    _wasCurrent = current;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _wasCurrent) _refresh();
  }

  void _refresh() {
    final day = challengeDay();
    if (day != _day) {
      setState(() {
        _day = day;
        _page = 0;
      });
      if (_pages.hasClients) _pages.jumpToPage(0);
    }
    if (ref.read(settingsProvider).shareScoresOptIn) {
      ref.invalidate(_dailyTopsProvider(_day));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _pages.dispose();
    super.dispose();
  }

  Future<void> _open(PentoscopeSize size) async {
    await openLeaderboardWithConsent(
      context,
      ref,
      builder: () => LeaderboardScreen(day: _day, size: size),
    );
  }

  String _duration(LeaderboardEntry entry, AppLocalizations l10n) {
    final seconds = entry.timeMs ~/ 1000;
    return l10n.rankingDuration(0, '$seconds');
  }

  String _challengeTitle(AppLocalizations l10n, PentoscopeSize size) {
    return l10n.homeChallengeLevel(
      playerSizeLabel(l10n, size).replaceFirst(' +', '+'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final myId = ref.watch(settingsProvider.select((s) => s.playerId));
    final myBelt = ref.watch(settingsProvider.select((s) => s.challengeBelt));
    final optedIn = ref.watch(
      settingsProvider.select((s) => s.shareScoresOptIn),
    );
    _count = 0;
    Widget content;
    if (!optedIn) {
      return const SizedBox.shrink();
    } else {
      final tops = ref.watch(_dailyTopsProvider(_day));
      content = tops.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (entries) {
          _count = entries.length;
          if (entries.isEmpty) {
            return const SizedBox.shrink();
          }
          return PageView.builder(
            controller: _pages,
            onPageChanged: (page) => _page = page,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final top = entries[index];
              return InkWell(
                onTap: () => _open(top.size),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                              size: 21,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _challengeTitle(l10n, top.size),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      for (var rank = 0; rank < top.podium.length; rank++)
                        _rankingRow(
                          top.podium[rank],
                          rank,
                          top.podium,
                          myId,
                          myBelt,
                          l10n,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
    if (_count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        key: const ValueKey('home-daily-tops'),
        color: const Color(0xFFF2F3F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF20242A), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height:
              (MediaQuery.textScalerOf(context).scale(1) > 1.2 ? 300 : 230) *
              MediaQuery.textScalerOf(context).scale(1),
          child: content,
        ),
      ),
    );
  }

  Widget _rankingRow(
    LeaderboardEntry entry,
    int rank,
    List<LeaderboardEntry> entries,
    String? myId,
    int myBelt,
    AppLocalizations l10n,
  ) {
    final mine = myId != null && entry.playerId == myId;
    final belt = mine ? myBelt : entry.belt;
    final time = Text(
      _duration(entry, l10n),
      style: const TextStyle(
        color: Color(0xFF5B6472),
        fontSize: 15,
        height: 1.15,
        fontWeight: FontWeight.w600,
      ),
    );
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    return Semantics(
      label: mine ? l10n.rankingYou : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '${rank + 1}.',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    leaderboardDisplayName(entry, entries, l10n.defaultPlayer),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.15,
                      fontWeight: mine ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                if (belt != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: BeltIcon(
                      key: ValueKey('ranking-belt-${entry.playerId}'),
                      belt: belt,
                    ),
                  ),
                if (!largeText) ...[const SizedBox(width: 7), time],
              ],
            ),
            if (largeText)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Align(alignment: Alignment.centerRight, child: time),
              ),
          ],
        ),
      ),
    );
  }
}
