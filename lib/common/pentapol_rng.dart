// Modified: 2026-09-04 04:34 — création : PRNG déterministe du dépôt (xorshift32). dart:math
//           Random(seed) n'est pas garanti stable entre versions du SDK — une montée de Flutter
//           changerait tous les puzzles seedés (duel aujourd'hui, défi hebdo demain). CDC §7.3.
// lib/common/pentapol_rng.dart

/// Générateur pseudo-aléatoire **déterministe et portable**, écrit dans le dépôt.
///
/// `Random(seed)` de `dart:math` ne garantit pas la même séquence entre versions du
/// SDK : deux appareils sur des builds différents divergeraient. `PentapolRng` fige
/// l'algorithme (xorshift32) une fois pour toutes — même seed ⟹ même séquence, partout
/// et pour toujours. C'est le socle de tout tirage qui doit se reproduire sans transiter
/// par le réseau : le duel (orientations) et, à venir, le défi de la semaine (CDC §7).
///
/// Non destiné à la cryptographie ni à une qualité statistique fine : pour choisir un
/// masque et des orientations, un xorshift suffit et sa reproductibilité prime.
class PentapolRng {
  /// État interne, maintenu dans [0, 2³²). Jamais 0 (point fixe de xorshift).
  int _state;

  /// Amorce le générateur. Le seed est ramené sur 32 bits ; 0 est remplacé par une
  /// constante non nulle (xorshift resterait bloqué à 0).
  PentapolRng(int seed)
      : _state = (seed & 0xffffffff) == 0 ? 0x9e3779b9 : (seed & 0xffffffff);

  /// Prochain entier brut dans [0, 2³²). xorshift32 (Marsaglia, décalages 13/17/5).
  int _next() {
    var x = _state;
    x ^= (x << 13) & 0xffffffff;
    x ^= x >> 17;
    x ^= (x << 5) & 0xffffffff;
    _state = x & 0xffffffff;
    return _state;
  }

  /// Entier uniforme dans [0, [max]). [max] doit être strictement positif.
  ///
  /// Le biais du modulo est négligeable aux tailles en jeu (nombre d'orientations ≤ 8,
  /// listes de masques ≤ quelques centaines) devant 2³².
  int nextInt(int max) {
    assert(max > 0, 'PentapolRng.nextInt: max doit être > 0');
    return _next() % max;
  }
}
