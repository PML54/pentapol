// Modified: 2026-09-30 07:39 — limiter le bilan de rapidité à la seule tendance.
// Historique: 2026-09-30 07:37 — retirer record et volume du bilan de rapidité.
// Historique: 2026-09-30 07:27 — afficher l'acuité par pièce en pourcentage tronqué.
// Historique: 2026-09-30 07:10 — afficher rapidité et analyses des tentatives même abandonnées.
// Historique: 2026-09-29 07:59 — retirer les numéros qui concurrençaient les silhouettes des pièces.
// Historique: 2026-09-29 07:51 — titrer le classement « Acuité isométrique par pièce ».
// Historique: 2026-09-29 07:49 — trier l'acuité de la moins bonne à la meilleure et la noter sur 1000.
// Historique: 2026-09-29 06:19 — identifier les pièces du profil par leurs numéros plutôt que leurs lettres.
// Historique: 2026-09-29 06:10 — afficher les douze pièces et leur acuité cumulée dans le profil.
// Historique: 2026-09-29 06:05 — appliquer au profil le même code couleur que l'icône de niveau.
// Historique: 2026-09-29 05:50 — transformer les records en profil joueur avec niveau en tête.
// Historique: 2026-09-09 05:29 — centralisation score : acuityPercent, agrégation « meilleure acuité »
//           et hasPerfectVision délèguent à score_rules (formule plafonnée, comparaison et prédicat
//           uniques). Le % devient plafonné — sans effet visible (records = parties propres, ratio ≤ 1).
// Historique: 2026-09-06 04:50 — i18n : titre, légende (acuité/fautes/temps), état vide, médaille
//           « vision parfaite » et compte de pièces via AppLocalizations.
// Historique: 2026-09-05 17:24 — trois maillots (A) : acuité / FAUTES / temps (coups et Help supprimés,
//           bestFaults remplace bestMoves+bestHelp).
// Historique: 2026-09-04 16:10 — 4e maillot BLANC (Help) dans les records perso : colonne bestHelp
//           lue/agrégée, ligne + légende, pastilles bordées pour le blanc.
// lib/pentoscope/screens/records_screen.dart
// Historique: 2026-09-04 06:13 — médaille §4.6 : icône « vision parfaite » sur les tailles au best
//           d'acuité 100 % (hasPerfectVision).
// Historique: 2026-09-04 06:05 — création : écran de lecture des records perso (CDC §4). Une carte
//           par taille jouée, les trois maillots (acuité jaune / coups à pois / temps vert). Lit
//           PuzzleStats (pièces tirées) et agrège SolvedSolutions (rectangles, 6×10).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/config/player_level_colors.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/player_profile_analysis.dart';
import 'package:pentapol/pentoscope/score_rules.dart' as rules;

/// Les trois maillots d'une taille, agrégés. Bests nullables : `null` = aucune partie propre.
class _SizeRecord {
  final int
  count; // complétions (pièces tirées) ou solutions distinctes (rectangle)
  final int? acuityMinIso;
  final int? acuityIsoCount;
  final int? faults;
  final int? timeSeconds;

  const _SizeRecord({
    required this.count,
    this.acuityMinIso,
    this.acuityIsoCount,
    this.faults,
    this.timeSeconds,
  });

  /// Acuité en % (§4.2), ou null si pas de best. Règle unique (plafonnée) dans score_rules.
  int? get acuityPercent {
    final mi = acuityMinIso, iso = acuityIsoCount;
    if (mi == null || iso == null) return null;
    return rules.acuityPercent(mi, iso);
  }

  /// Médaille « vision parfaite » (§4.6) : un best d'acuité à 100 % — prédicat unique dans score_rules.
  bool get hasPerfectVision =>
      acuityMinIso != null &&
      acuityIsoCount != null &&
      rules.isPerfectVision(acuityMinIso!, acuityIsoCount!);
}

/// Agrège les solutions découvertes d'un rectangle : meilleure acuité (ratio le plus grand),
/// moins de coups, meilleur temps — en ignorant les null (parties avec aide).
_SizeRecord _aggregateSolved(List<SolvedSolution> rows) {
  int? bestMi, bestIso, bestFaults, bestTime;
  for (final r in rows) {
    if (r.bestAcuityMinIso != null && r.bestAcuityIsoCount != null) {
      if (rules.isBetterAcuity(
        bestMi,
        bestIso,
        r.bestAcuityMinIso!,
        r.bestAcuityIsoCount!,
      )) {
        bestMi = r.bestAcuityMinIso;
        bestIso = r.bestAcuityIsoCount;
      }
    }
    if (r.bestFaults != null &&
        (bestFaults == null || r.bestFaults! < bestFaults)) {
      bestFaults = r.bestFaults;
    }
    if (r.bestTimeSeconds != null &&
        (bestTime == null || r.bestTimeSeconds! < bestTime)) {
      bestTime = r.bestTimeSeconds;
    }
  }
  return _SizeRecord(
    count: rows.length,
    acuityMinIso: bestMi,
    acuityIsoCount: bestIso,
    faults: bestFaults,
    timeSeconds: bestTime,
  );
}

Future<Map<PentoscopeSize, _SizeRecord>> _loadRecords(
  SettingsDatabase db,
) async {
  final stats = await db.allPuzzleStats();
  final solved = await db.allSolvedSolutions();
  final byName = {for (final s in stats) s.sizeName: s};
  final byBoard = <String, List<SolvedSolution>>{};
  for (final s in solved) {
    (byBoard[s.board] ??= []).add(s);
  }

  final result = <PentoscopeSize, _SizeRecord>{};
  for (final size in PentoscopeSize.values) {
    if (size.table != null) {
      final rows = byBoard['${size.width}x${size.height}'];
      if (rows != null && rows.isNotEmpty) {
        result[size] = _aggregateSolved(rows);
      }
    } else {
      final s = byName[size.name];
      if (s != null) {
        result[size] = _SizeRecord(
          count: s.completed,
          acuityMinIso: s.bestAcuityMinIso,
          acuityIsoCount: s.bestAcuityIsoCount,
          faults: s.bestFaults,
          timeSeconds: s.bestTimeSeconds,
        );
      }
    }
  }
  return result;
}

/// Écran de lecture des records personnels — une carte par taille jouée.
class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(settingsDatabaseProvider);
    final level = ref.watch(settingsProvider.select((s) => s.currentLevel));
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).playerProfileTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 42,
                    color: playerLevelColor(level),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      ).playerProfileLevel(level, kMaxLevel),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: playerLevelColor(level),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<PentoscopeSize, _SizeRecord>>(
                future: _loadRecords(db),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final records = snap.data!;
                  final analyses = {
                    for (final size in PentoscopeSize.values)
                      size: PlayerProfileAnalysis.forSize(
                        size.name,
                        settings.attemptHistory,
                      ),
                  };
                  final sizes = PentoscopeSize.values
                      .where(
                        (size) =>
                            records.containsKey(size) ||
                            analyses[size]!.attempts > 0,
                      )
                      .toList();
                  final speedSizes = sizes
                      .where(
                        (size) => analyses[size]!.speedTrendPercent != null,
                      )
                      .toList();
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (speedSizes.isNotEmpty)
                        _SpeedAnalysisSection(
                          sizes: speedSizes,
                          analyses: analyses,
                        ),
                      if (speedSizes.isNotEmpty) const SizedBox(height: 20),
                      _PieceAcuityList(settings: settings),
                      const SizedBox(height: 20),
                      if (sizes.isNotEmpty)
                        Text(
                          AppLocalizations.of(context).playerAttemptsTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      if (sizes.isNotEmpty) const _Legend(),
                      if (sizes.isNotEmpty) const SizedBox(height: 8),
                      for (final size in sizes)
                        _RecordCard(
                          size: size,
                          record: records[size] ?? const _SizeRecord(count: 0),
                          analysis: analyses[size]!,
                        ),
                      if (sizes.isEmpty) const _EmptyState(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedAnalysisSection extends StatelessWidget {
  final List<PentoscopeSize> sizes;
  final Map<PentoscopeSize, PlayerProfileAnalysis> analyses;

  const _SpeedAnalysisSection({required this.sizes, required this.analyses});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.playerSpeedTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Tooltip(
              message: l10n.playerSpeedInfo,
              child: const Icon(Icons.info_outline, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final size in sizes)
          _SpeedCard(size: size, analysis: analyses[size]!),
      ],
    );
  }
}

class _SpeedCard extends StatelessWidget {
  final PentoscopeSize size;
  final PlayerProfileAnalysis analysis;

  const _SpeedCard({required this.size, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trend = analysis.speedTrendPercent;
    final trendLabel = trend == null
        ? null
        : trend > 0
        ? l10n.playerSpeedFaster(trend)
        : trend < 0
        ? l10n.playerSpeedSlower(-trend)
        : l10n.playerSpeedStable;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.timer_outlined, color: Color(0xFF2E9E5B)),
        title: Text(
          '${size.width}×${size.height}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(trendLabel!),
      ),
    );
  }
}

class _PieceAcuityList extends StatelessWidget {
  final AppSettings settings;

  const _PieceAcuityList({required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pieces = [...pentominos]
      ..sort((a, b) {
        final aTotals = settings.pieceAcuityTotals[a.id];
        final bTotals = settings.pieceAcuityTotals[b.id];
        final aHasScore = aTotals != null && aTotals.placements > 0;
        final bHasScore = bTotals != null && bTotals.placements > 0;
        if (!aHasScore && !bHasScore) return a.id.compareTo(b.id);
        if (!aHasScore) return 1;
        if (!bHasScore) return -1;
        final byScore = aTotals.percent.compareTo(bTotals.percent);
        return byScore != 0 ? byScore : a.id.compareTo(b.id);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.playerPieceAcuityTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final piece in pieces) _buildPieceRow(context, piece),
      ],
    );
  }

  Widget _buildPieceRow(BuildContext context, Pento piece) {
    final l10n = AppLocalizations.of(context);
    final storedTotals = settings.pieceAcuityTotals[piece.id];
    final totals = storedTotals != null && storedTotals.placements > 0
        ? storedTotals
        : null;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: SizedBox(
        width: 72,
        height: 54,
        child: FittedBox(
          fit: BoxFit.contain,
          child: PieceRenderer(
            piece: piece,
            positionIndex: 0,
            getPieceColor: settings.ui.getPieceColor,
            cellSize: 12,
            showLabel: false,
          ),
        ),
      ),
      trailing: Text(
        totals == null ? '—' : '${totals.percent} %',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      onTap: totals == null
          ? null
          : () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.playerPieceDetailTitle),
                content: Text(
                  l10n.playerPieceDetailValues(
                    totals.placements,
                    totals.theoretical,
                    totals.actual,
                    totals.percent,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).recordsEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rappel des trois maillots en tête de liste.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 6,
        children: [
          _LegendItem(color: const Color(0xFFF2B705), label: l10n.legendAcuity),
          _LegendItem(color: const Color(0xFFD64545), label: l10n.legendFaults),
          _LegendItem(color: const Color(0xFF2E9E5B), label: l10n.legendTime),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black26,
            ), // léger bord pour détacher la pastille
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  final PentoscopeSize size;
  final _SizeRecord record;
  final PlayerProfileAnalysis analysis;
  const _RecordCard({
    required this.size,
    required this.record,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final acuity = record.acuityPercent;
    final faults = record.faults;
    final time = record.timeSeconds;
    final isRectangle = size.table != null;
    final countLabel = isRectangle
        ? '${record.count} solution${record.count > 1 ? 's' : ''}'
        : '${record.count} fois';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${size.width}×${size.height}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (record.hasPerfectVision) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: AppLocalizations.of(context).perfectVisionMsg,
                    child: const Icon(
                      Icons.military_tech,
                      color: Color(0xFFF2B705),
                      size: 22,
                    ),
                  ),
                ],
                const Spacer(),
                Flexible(
                  child: Text(
                    countLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
              ],
            ),
            Text(
              AppLocalizations.of(context).piecesCount(size.numPieces),
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MaillotValue(
                  color: const Color(0xFFF2B705),
                  value: acuity == null ? '—' : '$acuity %',
                ),
                _MaillotValue(
                  color: const Color(0xFFD64545),
                  value: faults == null ? '—' : '$faults',
                ),
                _MaillotValue(
                  color: const Color(0xFF2E9E5B),
                  value: time == null ? '—' : _mmss(time),
                ),
              ],
            ),
            if (analysis.attempts > 0) ...[
              const Divider(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AttemptValue(
                    icon: Icons.flag_outlined,
                    label: AppLocalizations.of(context).playerAttemptsCompleted(
                      analysis.completed,
                      analysis.attempts,
                    ),
                  ),
                  if (analysis.firstPlacements > 0)
                    _AttemptValue(
                      icon: Icons.grid_view_outlined,
                      label: AppLocalizations.of(context)
                          .playerInitialPlacements(
                            analysis.safeFirstPlacements,
                            analysis.firstPlacements,
                            analysis.initialAnticipationScore!,
                          ),
                    ),
                  if (analysis.faultsPerAttempt != null)
                    _AttemptValue(
                      icon: Icons.warning_amber_outlined,
                      label: AppLocalizations.of(context)
                          .playerFaultsPerAttempt(
                            NumberFormat(
                              '0.0',
                              Localizations.localeOf(context).toLanguageTag(),
                            ).format(analysis.faultsPerAttempt),
                          ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttemptValue extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AttemptValue({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).hintColor),
        const SizedBox(width: 5),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

String _mmss(int seconds) {
  final mm = (seconds ~/ 60).toString().padLeft(2, '0');
  final ss = (seconds % 60).toString().padLeft(2, '0');
  return '$mm:$ss';
}

class _MaillotValue extends StatelessWidget {
  final Color color;
  final String value;
  const _MaillotValue({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black26,
            ), // léger bord pour détacher la pastille
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
