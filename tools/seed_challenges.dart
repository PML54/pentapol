// Modified: 2026-09-05 18:20 — le token peut venir de la variable d'environnement SEED_TOKEN
//           (repli si --token absent), pour ne jamais l'exposer sur la ligne de commande.
// tools/seed_challenges.dart
// Historique: 2026-09-05 00:35 — création : semeur des définitions de défi (CDC §7). Dérive les
//           six défis d'une semaine (défaut algorithmique) et les POST au serveur avec SEED_TOKEN,
//           pour remplir les semaines non composées à la main (le serveur a alors le rack pour
//           l'audit). Pur Dart (pas d'import Flutter) : réimplémente la dérivation de challenge.dart
//           et l'AUTO-CONTRÔLE contre le digest gelé du test (refuse de tourner s'il a divergé).
//
// Usage :
//   dart run tools/seed_challenges.dart [--token=XXXX] [--day=YYYY-MM-DD] [--url=...] [--dry-run]
//     --token    SEED_TOKEN du worker (requis sauf --dry-run). À défaut, lu depuis la variable
//                d'environnement SEED_TOKEN (export SEED_TOKEN=… ; évite de l'exposer en ligne).
//     --day      jour UTC à semer (défaut : aujourd'hui).
//     --url      base URL du worker (défaut : pentapol-defi.pentapml.workers.dev).
//     --dry-run  dérive et affiche, ne POST pas (et ne demande pas de token).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pentapol/common/pentapol_rng.dart';

const int kChallengeVersion = 2; // doit égaler challenge.dart
const String kDefaultUrl = 'https://pentapol-defi.pentapml.workers.dev';

// numOrientations par id de pièce (1..12), copié de pentominos.dart (données géométriques figées).
const List<int> _numOrientations = [0, 1, 8, 4, 8, 8, 4, 4, 8, 8, 4, 4, 2];

// Les neuf tailles du parcours quotidien.
const List<(int, int, String)> _sizes = [
  (0, 3, 'size3x5'),
  (1, 4, 'size4x5'),
  (2, 5, 'size5x5'),
  (3, 6, 'size6x5'),
  (4, 7, 'size7x5'),
  (5, 8, 'size8x5'),
  (6, 9, 'size9x5'),
  (7, 10, 'size10x5'),
  (8, 12, 'size6x10'),
];

/// FNV-1a sur trois entiers — challengeSeed de challenge.dart.
int _challengeSeed(int version, int day, int sizeIndex) {
  var h = 0x811c9dc5;
  for (final v in [version, day, sizeIndex]) {
    h = (h ^ (v & 0xffffffff)) & 0xffffffff;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

int _popcount(int x) {
  var c = 0;
  while (x != 0) {
    c += x & 1;
    x >>= 1;
  }
  return c;
}

int _daysSinceEpoch(DateTime now) {
  final utc = now.toUtc();
  final date = DateTime.utc(utc.year, utc.month, utc.day);
  final days = date.difference(DateTime.utc(2026, 1, 1)).inDays;
  return days < 0 ? 0 : days;
}

/// Masques solubles par popcount, lus depuis l'asset (comme _ensureTable / le test).
Map<int, List<int>> _loadSolubleByPop() {
  final bytes = File('assets/data/subset_counts.bin').readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  final byPop = <int, List<int>>{};
  for (int m = 0; m < 4096; m++) {
    if (data.getUint16(m * 2, Endian.little) > 0) {
      byPop.putIfAbsent(_popcount(m), () => <int>[]).add(m);
    }
  }
  return byPop;
}

int _solutionCount(int mask) {
  final bytes = File('assets/data/subset_counts.bin').readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  return data.getUint16(mask * 2, Endian.little);
}

/// Dérive un défi : masque + rack. Réimplémentation exacte de deriveChallenge (vérifiée par digest).
({int mask, List<int> pieceIds, Map<int, int> orientations}) _derive(
  int day,
  int sizeIndex,
  List<int> solubleMasks,
) {
  final rng = PentapolRng(_challengeSeed(kChallengeVersion, day, sizeIndex));
  final mask = sizeIndex == 8
      ? 0xFFF
      : solubleMasks[rng.nextInt(solubleMasks.length)];
  final pieceIds = <int>[
    for (int id = 1; id <= 12; id++)
      if (mask & (1 << (id - 1)) != 0) id,
  ];
  final orientations = <int, int>{
    for (final id in pieceIds) id: rng.nextInt(_numOrientations[id]),
  };
  return (mask: mask, pieceIds: pieceIds, orientations: orientations);
}

String? _arg(List<String> args, String name) {
  for (final a in args) {
    if (a.startsWith('--$name=')) return a.substring(name.length + 3);
  }
  return null;
}

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final url = _arg(args, 'url') ?? kDefaultUrl;
  // --token prioritaire ; à défaut, la variable d'environnement SEED_TOKEN (hors ligne de commande).
  final token = _arg(args, 'token') ?? Platform.environment['SEED_TOKEN'];
  final now = DateTime.now().toUtc();
  final day =
      _arg(args, 'day') ??
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final parsedDay = DateTime.tryParse(day);
  if (parsedDay == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) {
    stderr.writeln('Jour invalide : utiliser --day=YYYY-MM-DD.');
    exit(1);
  }
  final dayIndex = _daysSinceEpoch(parsedDay);

  final byPop = _loadSolubleByPop();

  stdout.writeln('Defi du $day, base $url.');

  if (!dryRun && (token == null || token.isEmpty)) {
    stderr.writeln(
      '❌ Token requis pour semer : --token=XXXX ou export SEED_TOKEN=… '
      '(ou utiliser --dry-run). Voir README.',
    );
    exit(2);
  }

  var failures = 0;
  for (final (index, numPieces, name) in _sizes) {
    final d = _derive(dayIndex, index, byPop[numPieces] ?? const []);
    final solutionCount = index == 8 ? 9356 : _solutionCount(d.mask);
    final body = jsonEncode({
      'version': kChallengeVersion,
      'day': day,
      'size': index,
      'mask': d.mask,
      'rack': d.orientations.map((k, v) => MapEntry('$k', v)),
      'solutionCount': solutionCount,
    });
    if (dryRun) {
      stdout.writeln(
        '  [dry-run] $name : mask=${d.mask} rack=${d.orientations}',
      );
      continue;
    }
    final resp = await http.post(
      Uri.parse('$url/challenge'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: body,
    );
    stdout.writeln('  $name : HTTP ${resp.statusCode} ${resp.body}');
    if (resp.statusCode < 200 || resp.statusCode >= 300) failures++;
  }
  if (failures > 0) {
    stderr.writeln('$failures défi(s) refusé(s). Amorçage incomplet.');
    exitCode = 3;
    return;
  }
  stdout.writeln('Les neuf défis ont été amorcés.');
}
