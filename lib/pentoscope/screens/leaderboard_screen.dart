// Modified: 2026-09-06 04:50 — i18n : titre, semaine, onglets (label de maillot résolu par helper —
//           le const _maillots ne peut pas appeler l10n), état vide et « Joueur » par défaut.
// Historique: 2026-09-05 10:30 — trois maillots (A) : onglets acuité / FAUTES / temps (blanc/Help
//           supprimé, à pois affiche les fautes). Lit GET /leaderboard, met en avant le joueur
//           courant, dégradation gracieuse (§7.8).
// lib/pentoscope/screens/leaderboard_screen.dart
// Historique: 2026-09-05 00:20 — création : écran des quatre classements du défi (CDC §7, Phase 5).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/challenge_api.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';

String leaderboardDisplayName(
  LeaderboardEntry entry,
  List<LeaderboardEntry> entries,
  String fallback,
) {
  final name = entry.pseudo.trim().isEmpty ? fallback : entry.pseudo.trim();
  final normalized = name.toLowerCase();
  final duplicateCount = entries.where((candidate) {
    final candidateName = candidate.pseudo.trim().isEmpty
        ? fallback
        : candidate.pseudo.trim();
    return candidateName.toLowerCase() == normalized;
  }).length;
  if (duplicateCount < 2 || entry.playerId.length < 4) return name;
  final suffix = entry.playerId
      .substring(entry.playerId.length - 4)
      .toUpperCase();
  return '$name · $suffix';
}

/// Les trois maillots, avec leur couleur. Le libellé est résolu par [_maillotLabel] (le const
/// ne peut pas appeler AppLocalizations).
class _MaillotSpec {
  final Maillot maillot;
  final Color color;
  const _MaillotSpec(this.maillot, this.color);
}

const List<_MaillotSpec> _maillots = [
  _MaillotSpec(Maillot.temps, Color(0xFF2E9E5B)),
  _MaillotSpec(Maillot.acuite, Color(0xFFF2B705)),
  _MaillotSpec(Maillot.coups, Color(0xFF3976C4)),
];

/// Libellé localisé d'un maillot (les mêmes trois mots que la légende des records).
String _maillotLabel(AppLocalizations l10n, Maillot m) {
  switch (m) {
    case Maillot.temps:
      return l10n.legendTime;
    case Maillot.acuite:
      return l10n.legendAcuity;
    case Maillot.coups:
      return 'Coups';
  }
}

/// Écran des classements d'un défi `(semaine, taille)` : un onglet par maillot.
class LeaderboardScreen extends ConsumerStatefulWidget {
  final String day;
  final PentoscopeSize size;
  const LeaderboardScreen({super.key, required this.day, required this.size});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final ChallengeApi _api = ChallengeApi();
  LeaderboardPeriod _period = LeaderboardPeriod.day;

  String _valueOf(_MaillotSpec spec, LeaderboardEntry e) {
    if (_period != LeaderboardPeriod.day) {
      return '${e.points.toStringAsFixed(1)} pts';
    }
    switch (spec.maillot) {
      case Maillot.temps:
        final s = e.timeMs ~/ 1000;
        return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
      case Maillot.acuite:
        return '${e.acuityPercent} %';
      case Maillot.coups:
        return '${e.moves}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final myId = ref.read(settingsProvider).playerId;
    return DefaultTabController(
      length: _maillots.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.leaderboardTitle(widget.size.width, widget.size.height),
          ),
          bottom: TabBar(
            tabs: [
              for (final m in _maillots)
                Tab(
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: m.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_maillotLabel(l10n, m.maillot)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: SegmentedButton<LeaderboardPeriod>(
                  segments: [
                    ButtonSegment(
                      value: LeaderboardPeriod.day,
                      label: Text(l10n.periodDay),
                    ),
                    ButtonSegment(
                      value: LeaderboardPeriod.week,
                      label: Text(l10n.periodWeek),
                    ),
                    ButtonSegment(
                      value: LeaderboardPeriod.month,
                      label: Text(l10n.periodMonth),
                    ),
                  ],
                  selected: {_period},
                  onSelectionChanged: (selection) {
                    setState(() => _period = selection.first);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  widget.day,
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final m in _maillots)
                      _MaillotTab(
                        key: ValueKey('${m.maillot.name}-${_period.name}'),
                        spec: m,
                        screen: this,
                        myId: myId,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaillotTab extends StatelessWidget {
  final _MaillotSpec spec;
  final _LeaderboardScreenState screen;
  final String? myId;
  const _MaillotTab({
    super.key,
    required this.spec,
    required this.screen,
    required this.myId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: screen._api.leaderboard(
        version: kChallengeVersion,
        day: screen.widget.day,
        size: screen.widget.size.index,
        maillot: spec.maillot,
        period: screen._period,
      ),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snap.data ?? const [];
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                AppLocalizations.of(context).leaderboardEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final e = entries[i];
            final isMe = myId != null && e.playerId == myId;
            return Container(
              color: isMe ? spec.color.withOpacity(0.15) : null,
              child: ListTile(
                dense: true,
                leading: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                title: Text(
                  leaderboardDisplayName(
                    e,
                    entries,
                    AppLocalizations.of(context).defaultPlayer,
                  ),
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: Text(
                  screen._valueOf(spec, e),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
