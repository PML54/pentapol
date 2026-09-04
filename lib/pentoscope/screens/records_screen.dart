// Modified: 2026-09-04 16:10 — 4e maillot BLANC (Help) dans les records perso : colonne bestHelp
//           lue/agrégée, ligne + légende, pastilles bordées pour le blanc.
// lib/pentoscope/screens/records_screen.dart
// Historique: 2026-09-04 06:13 — médaille §4.6 : icône « vision parfaite » sur les tailles au best
//           d'acuité 100 % (hasPerfectVision).
// Historique: 2026-09-04 06:05 — création : écran de lecture des records perso (CDC §4). Une carte
//           par taille jouée, les trois maillots (acuité jaune / coups à pois / temps vert). Lit
//           PuzzleStats (pièces tirées) et agrège SolvedSolutions (rectangles, 6×10).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';

/// Les trois maillots d'une taille, agrégés. Bests nullables : `null` = aucune partie propre.
class _SizeRecord {
  final int count; // complétions (pièces tirées) ou solutions distinctes (rectangle)
  final int? acuityMinIso;
  final int? acuityIsoCount;
  final int? moves;
  final int? timeSeconds;
  final int? help;

  const _SizeRecord({
    required this.count,
    this.acuityMinIso,
    this.acuityIsoCount,
    this.moves,
    this.timeSeconds,
    this.help,
  });

  /// Acuité en % (§4.2), ou null si pas de best.
  int? get acuityPercent {
    final mi = acuityMinIso, iso = acuityIsoCount;
    if (mi == null || iso == null) return null;
    return ((mi + 1) / (iso + 1) * 100).round();
  }

  /// Médaille « vision parfaite » (§4.6) : un best d'acuité à 100 % (isoCount == minIso).
  bool get hasPerfectVision =>
      acuityMinIso != null && acuityMinIso == acuityIsoCount;
}

/// Agrège les solutions découvertes d'un rectangle : meilleure acuité (ratio le plus grand),
/// moins de coups, meilleur temps — en ignorant les null (parties avec aide).
_SizeRecord _aggregateSolved(List<SolvedSolution> rows) {
  int? bestMi, bestIso, bestMoves, bestTime, bestHelp;
  for (final r in rows) {
    if (r.bestAcuityMinIso != null && r.bestAcuityIsoCount != null) {
      if (bestMi == null ||
          (r.bestAcuityMinIso! + 1) * (bestIso! + 1) >
              (bestMi + 1) * (r.bestAcuityIsoCount! + 1)) {
        bestMi = r.bestAcuityMinIso;
        bestIso = r.bestAcuityIsoCount;
      }
    }
    if (r.bestMoves != null && (bestMoves == null || r.bestMoves! < bestMoves)) {
      bestMoves = r.bestMoves;
    }
    if (r.bestTimeSeconds != null &&
        (bestTime == null || r.bestTimeSeconds! < bestTime)) {
      bestTime = r.bestTimeSeconds;
    }
    if (r.bestHelp != null && (bestHelp == null || r.bestHelp! < bestHelp)) {
      bestHelp = r.bestHelp;
    }
  }
  return _SizeRecord(
    count: rows.length,
    acuityMinIso: bestMi,
    acuityIsoCount: bestIso,
    moves: bestMoves,
    timeSeconds: bestTime,
    help: bestHelp,
  );
}

Future<Map<PentoscopeSize, _SizeRecord>> _loadRecords(SettingsDatabase db) async {
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
      if (rows != null && rows.isNotEmpty) result[size] = _aggregateSolved(rows);
    } else {
      final s = byName[size.name];
      if (s != null) {
        result[size] = _SizeRecord(
          count: s.completed,
          acuityMinIso: s.bestAcuityMinIso,
          acuityIsoCount: s.bestAcuityIsoCount,
          moves: s.bestMoves,
          timeSeconds: s.bestTimeSeconds,
          help: s.bestHelp,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Mes records')),
      body: SafeArea(
        child: FutureBuilder<Map<PentoscopeSize, _SizeRecord>>(
          future: _loadRecords(db),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final records = snap.data!;
            final sizes =
                PentoscopeSize.values.where(records.containsKey).toList();
            if (sizes.isEmpty) {
              return const _EmptyState();
            }
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const _Legend(),
                const SizedBox(height: 8),
                for (final size in sizes)
                  _RecordCard(size: size, record: records[size]!),
              ],
            );
          },
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
            Icon(Icons.emoji_events_outlined,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            const Text(
              'Aucun record pour l\'instant.\nTermine un puzzle sans aide pour en poser un.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LegendItem(color: Color(0xFFF2B705), label: 'Acuité'),
          _LegendItem(color: Color(0xFFD64545), label: 'Coups'),
          _LegendItem(color: Color(0xFF2E9E5B), label: 'Temps'),
          _LegendItem(color: Colors.white, label: 'Help'),
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
            border: Border.all(color: Colors.black26), // maillot blanc visible
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
  const _RecordCard({required this.size, required this.record});

  @override
  Widget build(BuildContext context) {
    final acuity = record.acuityPercent;
    final moves = record.moves;
    final time = record.timeSeconds;
    final help = record.help;
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (record.hasPerfectVision) ...[
                  const SizedBox(width: 6),
                  const Tooltip(
                    message: 'Vision parfaite — acuité 100 %',
                    child: Icon(Icons.military_tech,
                        color: Color(0xFFF2B705), size: 22),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  '· ${size.numPieces} pièces',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                const Spacer(),
                Text(countLabel, style: TextStyle(color: Theme.of(context).hintColor)),
              ],
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
                  value: moves == null ? '—' : '$moves',
                ),
                _MaillotValue(
                  color: const Color(0xFF2E9E5B),
                  value: time == null ? '—' : _mmss(time),
                ),
                _MaillotValue(
                  color: Colors.white, // maillot blanc — Help
                  value: help == null ? '—' : '$help',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _mmss(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
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
            border: Border.all(color: Colors.black26), // maillot blanc visible
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
