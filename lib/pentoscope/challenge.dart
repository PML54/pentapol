// Modified: 2026-09-04 06:25 — création : dérivation hors ligne du défi de la semaine (CDC §7,
//           Phase 1). Tout descend d'un entier : seed = mix(version, semaine, taille) → masque +
//           rack, via PentapolRng (dépôt). Aucun réseau, aucun état transmis. HORS V1.
// lib/pentoscope/challenge.dart

import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/pentapol_rng.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';

/// Version de l'algorithme de dérivation. **Entre dans la clé du classement** (CDC §7.3, piège 4) :
/// le jour où la dérivation change, les anciens classements restent lisibles au lieu d'être
/// silencieusement corrompus. À incrémenter à tout changement de `deriveChallenge`/`challengeSeed`.
const int kChallengeVersion = 1;

/// Lundi 5 janvier 2026, 00:00 **UTC** — origine des semaines (CDC §7.3). UTC obligatoire : sinon
/// la semaine ne commence pas au même instant selon le pays et deux joueurs ne jouent pas le même
/// défi.
final DateTime kChallengeEpoch = DateTime.utc(2026, 1, 5);

/// Tailles ouvertes au défi (CDC §7.2) : le 6×10, le 5×9 et le 5×10 sont écartés (trop longs).
/// Restent six tailles. L'ordre est figé (il n'entre pas dans la dérivation, qui passe par
/// `size.index`, mais sert l'énumération et le test de gel).
const List<PentoscopeSize> kChallengeSizes = [
  PentoscopeSize.size3x5,
  PentoscopeSize.size4x5,
  PentoscopeSize.size5x5,
  PentoscopeSize.size6x5,
  PentoscopeSize.size7x5,
  PentoscopeSize.size8x5,
];

/// Semaines écoulées depuis [kChallengeEpoch]. Un défi = `(semaine, taille)` ; `week` étant un
/// entier, tout défi passé ou futur se recalcule.
int weeksSinceEpoch(DateTime now) {
  final days = now.toUtc().difference(kChallengeEpoch).inDays;
  return days < 0 ? 0 : days ~/ 7;
}

/// Mélange (version, semaine, taille) en un seed 32 bits déterministe (FNV-1a). Défini dans le
/// dépôt pour survivre aux montées du SDK, comme [PentapolRng].
int challengeSeed(int version, int week, int sizeIndex) {
  var h = 0x811c9dc5; // FNV offset basis
  for (final v in [version, week, sizeIndex]) {
    h = (h ^ (v & 0xffffffff)) & 0xffffffff;
    h = (h * 0x01000193) & 0xffffffff; // FNV prime
  }
  return h;
}

/// Un défi dérivé : le masque de pièces et le rack (orientation initiale par pièce).
class ChallengeDefinition {
  final int week;
  final PentoscopeSize size;

  /// Masque 12 bits des pièces tirées (bit `id-1`).
  final int mask;

  /// Pièces du masque, **id croissant** (ordre figé, §7.3 piège 3).
  final List<int> pieceIds;

  /// Rack : `pieceId → index d'orientation` distribué. Commun à tous les joueurs du défi (§4.3).
  final Map<int, int> orientations;

  const ChallengeDefinition({
    required this.week,
    required this.size,
    required this.mask,
    required this.pieceIds,
    required this.orientations,
  });
}

/// Dérive le défi `(week, size)`. [solubleMasks] = masques solubles de `size.numPieces`, **triés
/// par valeur croissante** (l'ordre est figé, jamais celui d'itération d'une Map — §7.3 piège 3 ;
/// `PentoscopeGenerator` les fournit dans cet ordre). Pur : aucun réseau, aucune I/O.
ChallengeDefinition deriveChallenge({
  required int week,
  required PentoscopeSize size,
  required List<int> solubleMasks,
}) {
  final rng = PentapolRng(challengeSeed(kChallengeVersion, week, size.index));

  // 1. la configuration : un masque parmi les solubles.
  final mask = solubleMasks[rng.nextInt(solubleMasks.length)];

  // 2. le rack : une orientation par pièce, pièces par id croissant.
  final pieceIds = <int>[
    for (int id = 1; id <= 12; id++)
      if (mask & (1 << (id - 1)) != 0) id,
  ];
  final orientations = <int, int>{
    for (final id in pieceIds) id: rng.nextInt(pentominos[id - 1].numOrientations),
  };

  return ChallengeDefinition(
    week: week,
    size: size,
    mask: mask,
    pieceIds: pieceIds,
    orientations: orientations,
  );
}
