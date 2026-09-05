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
//   dart run tools/seed_challenges.dart [--token=XXXX] [--week=N] [--url=...] [--dry-run]
//     --token    SEED_TOKEN du worker (requis sauf --dry-run). À défaut, lu depuis la variable
//                d'environnement SEED_TOKEN (export SEED_TOKEN=… ; évite de l'exposer en ligne).
//     --week     semaine à semer (défaut : la semaine courante).
//     --url      base URL du worker (défaut : pentapol-defi.pentapml.workers.dev).
//     --dry-run  dérive et affiche, ne POST pas (et ne demande pas de token).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pentapol/common/pentapol_rng.dart';

const int kChallengeVersion = 1; // doit égaler challenge.dart
const String kDefaultUrl = 'https://pentapol-defi.pentapml.workers.dev';
const int kFrozenDigest = 4015859194; // challenge_test.dart : garde-fou anti-dérive

// numOrientations par id de pièce (1..12), copié de pentominos.dart (données géométriques figées).
const List<int> _numOrientations = [0, 1, 8, 4, 8, 8, 4, 4, 8, 8, 4, 4, 2];

// Les six tailles ouvertes au défi (§7.2) : (index de PentoscopeSize, nombre de pièces, nom d'enum).
const List<(int, int, String)> _sizes = [
  (0, 3, 'size3x5'),
  (1, 4, 'size4x5'),
  (2, 5, 'size5x5'),
  (3, 6, 'size6x5'),
  (4, 7, 'size7x5'),
  (5, 8, 'size8x5'),
];

/// FNV-1a sur trois entiers — challengeSeed de challenge.dart.
int _challengeSeed(int version, int week, int sizeIndex) {
  var h = 0x811c9dc5;
  for (final v in [version, week, sizeIndex]) {
    h = (h ^ (v & 0xffffffff)) & 0xffffffff;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// FNV-1a sur une chaîne (pour le digest de vérification) — comme challenge_test.dart.
int _fnvString(String s) {
  var h = 0x811c9dc5;
  for (final u in s.codeUnits) {
    h = (h ^ u) & 0xffffffff;
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

/// Semaines depuis le lundi 5 janvier 2026 00:00 UTC — weeksSinceEpoch de challenge.dart.
int _weeksSinceEpoch(DateTime now) {
  final days = now.toUtc().difference(DateTime.utc(2026, 1, 5)).inDays;
  return days < 0 ? 0 : days ~/ 7;
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

/// Dérive un défi : masque + rack. Réimplémentation exacte de deriveChallenge (vérifiée par digest).
({int mask, List<int> pieceIds, Map<int, int> orientations}) _derive(
    int week, int sizeIndex, List<int> solubleMasks) {
  final rng = PentapolRng(_challengeSeed(kChallengeVersion, week, sizeIndex));
  final mask = solubleMasks[rng.nextInt(solubleMasks.length)];
  final pieceIds = <int>[
    for (int id = 1; id <= 12; id++)
      if (mask & (1 << (id - 1)) != 0) id,
  ];
  final orientations = <int, int>{
    for (final id in pieceIds) id: rng.nextInt(_numOrientations[id]),
  };
  return (mask: mask, pieceIds: pieceIds, orientations: orientations);
}

/// Recalcule le digest des 60 premiers défis et le compare au golden gelé. Attrape toute dérive
/// entre cette réimplémentation et lib/challenge.dart.
bool _selfCheck(Map<int, List<int>> byPop) {
  final sb = StringBuffer();
  for (final (index, numPieces, name) in _sizes) {
    for (int w = 0; w < 10; w++) {
      final d = _derive(w, index, byPop[numPieces]!);
      final ori = d.pieceIds.map((id) => '$id:${d.orientations[id]}').join(',');
      sb.write('$name|$w|${d.mask}|$ori;');
    }
  }
  return _fnvString(sb.toString()) == kFrozenDigest;
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
  final week = int.tryParse(_arg(args, 'week') ?? '') ?? _weeksSinceEpoch(DateTime.now());

  final byPop = _loadSolubleByPop();

  // 🔒 Garde-fou : la dérivation du semeur DOIT être identique à lib (sinon les défis semés
  // différeraient de ce que le client dérive → classements incohérents).
  if (!_selfCheck(byPop)) {
    stderr.writeln('❌ Auto-contrôle échoué : la dérivation du semeur diverge de lib/challenge.dart '
        '(digest ≠ $kFrozenDigest). Semage ANNULÉ.');
    exit(1);
  }
  stdout.writeln('✅ Auto-contrôle OK (digest $kFrozenDigest). Semaine $week, base $url.');

  if (!dryRun && (token == null || token.isEmpty)) {
    stderr.writeln('❌ Token requis pour semer : --token=XXXX ou export SEED_TOKEN=… '
        '(ou utiliser --dry-run). Voir README.');
    exit(2);
  }

  for (final (index, numPieces, name) in _sizes) {
    final d = _derive(week, index, byPop[numPieces]!);
    final body = jsonEncode({
      'version': kChallengeVersion,
      'week': week,
      'size': index,
      'mask': d.mask,
      'rack': d.orientations.map((k, v) => MapEntry('$k', v)),
    });
    if (dryRun) {
      stdout.writeln('  [dry-run] $name : mask=${d.mask} rack=${d.orientations}');
      continue;
    }
    final resp = await http.post(
      Uri.parse('$url/challenge'),
      headers: {'content-type': 'application/json', 'authorization': 'Bearer $token'},
      body: body,
    );
    stdout.writeln('  $name : HTTP ${resp.statusCode} ${resp.body}');
  }
  stdout.writeln('Terminé.');
}
