// Modified: 2026-09-07 14:41 — centralisation (Paul) : tous les indicateurs d'observation sont
//           DÉFINIS, DOCUMENTÉS et FORMATÉS ici (FaultIndicators + diagnosticCourant) ; le bandeau
//           debug ne fait que les afficher. L'accumulation reste dans PentoscopeState (par coup).
// Historique: 2026-09-07 14:20 — refonte (Paul) : « aire non multiple de 5 » englobe les poches < 5
//           → suppression de pocheTropPetite ; la gravité devient CONTINUE, décroissante avec la
//           taille de la zone fautive (zone de 4 plus grave qu'une zone de 9), coefficient réglable.
// Historique: 2026-09-07 14:08 — création : classifieur des fautes par gravité. Couche d'OBSERVATION
//           (ne touche pas aux maillots) ; alimentera un barème une fois la distribution observée.
// lib/pentoscope/fault_analysis.dart

import 'package:pentapol/common/plateau.dart';

/// Coefficient du barème de gravité d'une **aire non multiple de 5** : `gravité = k / taille`.
/// Décroît avec la taille (une zone de 4 est plus grave qu'une zone de 9). **À régler à l'observation.**
const double kGraviteAireCoeff = 20.0;

/// Gravité d'une **impossibilité subtile** (combinatoire) : faute la moins grave. **À régler.**
const double kGraviteSubtile = 1.0;

/// Les **constats d'erreur** possibles quand un coup rend le plateau insoluble (🟡→🔴).
///
/// La gravité n'est plus un niveau discret mais un **nombre continu** (voir [FaultAnalysis.gravite]) ;
/// il ne reste que deux *causes* :
enum FaultKind {
  /// Une zone vide connexe dont la **taille n'est pas multiple de 5** — donc impavable par des
  /// pentominos. Englobe les poches < 5 (4, 3, 2, 1 sont non-multiples de 5). Se voit au comptage ;
  /// **plus la zone est petite, plus c'est évident, plus c'est grave**.
  aireNonMultipleDe5(emoji: '⚠️', libelle: 'aire non multiple de 5'),

  /// Toutes les zones sont des multiples de 5, mais le plateau est quand même mort : la forme n'est
  /// pas pavable **ou** les pièces restantes ne suffisent pas. Impasse combinatoire subtile (la
  /// table le sait, l'œil non) — la moins grave.
  impossibiliteSubtile(emoji: '🌫️', libelle: 'impossibilité subtile');

  const FaultKind({required this.emoji, required this.libelle});

  final String emoji;
  final String libelle;
}

/// Résultat de l'analyse d'une faute : la cause, la **gravité** (continue), la chaîne descriptive
/// lisible, et les tailles brutes des zones vides (diagnostic).
class FaultAnalysis {
  final FaultKind kind;

  /// Taille de la zone **en cause** = la plus petite zone non multiple de 5 (celle qui fixe la
  /// gravité). `null` pour [FaultKind.impossibiliteSubtile] (aucune zone fautive géométriquement).
  final int? zoneCause;

  /// Gravité de la faute (plus grand = plus grave). Pour une aire non multiple de 5,
  /// `kGraviteAireCoeff / zoneCause` ; pour une impossibilité subtile, `kGraviteSubtile`.
  final double gravite;

  /// Tailles de **toutes** les zones vides connexes du plateau, ordre de découverte (diagnostic).
  final List<int> zoneSizes;

  const FaultAnalysis({
    required this.kind,
    required this.zoneCause,
    required this.gravite,
    required this.zoneSizes,
  });

  /// La chaîne de caractères descriptive de la faute (observation / debug).
  String get description {
    switch (kind) {
      case FaultKind.aireNonMultipleDe5:
        return 'Zone de $zoneCause cases (non multiple de 5) — gravité ${_g()}';
      case FaultKind.impossibiliteSubtile:
        return 'Impossibilité subtile (zones multiples de 5) — gravité ${_g()}';
    }
  }

  /// Étiquette compacte pour un bandeau : `⚠️ 4 (g5.0)`.
  String get labelCourt =>
      '${kind.emoji} ${zoneCause ?? '·'} (g${_g()})';

  String _g() => gravite.toStringAsFixed(1);

  @override
  String toString() => description;
}

/// Analyse **pourquoi** un plateau est en impasse et **à quel point c'est grave**.
///
/// À appeler **au moment d'une faute** (le plateau vient de passer 🟡→🔴). La fonction ne juge pas
/// *si* c'est une impasse (ça, c'est la table via `count == 0`) : elle explique la cause visible et
/// sa gravité. Sur un plateau réellement soluble, elle renverrait [FaultKind.impossibiliteSubtile]
/// (aucune cause géométrique) — d'où l'appel réservé aux vrais culs-de-sac.
///
/// Règle : s'il existe une zone dont la taille n'est pas multiple de 5, la faute est de ce type et
/// sa gravité est fixée par **la plus petite** de ces zones (la plus évidente à voir). Sinon, la
/// faute est une impossibilité subtile.
///
/// Cases : `0` = vide, tout le reste (pièce `> 0`, masquée `-1`) = mur. Connexité 4-voisins.
FaultAnalysis analyzeFault(Plateau board) {
  final sizes = _emptyRegionSizes(board);

  final nonMultiples = sizes.where((s) => s % 5 != 0).toList()..sort();
  if (nonMultiples.isNotEmpty) {
    final zone = nonMultiples.first; // la plus petite = la plus grave
    return FaultAnalysis(
      kind: FaultKind.aireNonMultipleDe5,
      zoneCause: zone,
      gravite: kGraviteAireCoeff / zone,
      zoneSizes: sizes,
    );
  }

  return FaultAnalysis(
    kind: FaultKind.impossibiliteSubtile,
    zoneCause: null,
    gravite: kGraviteSubtile,
    zoneSizes: sizes,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════════════════════
// INDICATEURS D'OBSERVATION (bandeau debug) — définition, documentation et formatage centralisés.
// ═══════════════════════════════════════════════════════════════════════════════════════════════
//
// Tous ces indicateurs sont de l'OBSERVATION : ils N'ENTRENT PAS dans les maillots et ne sont PAS
// persistés. Ils sont accumulés dans `PentoscopeState` au fil des coups (aux 4 sites de faute et,
// pour les compteurs bruts, à chaque action correspondante), puis regroupés et formatés ici pour
// que leur définition vive à UN seul endroit. Affichés par le bandeau `kShowLiveCounters`.
//
// L'analyse est faite à CHAQUE mouvement (isométrie dont translation, ajout, retrait) :
//  - les compteurs d'ÉVÉNEMENTS (lignes 1-2) n'avancent qu'à une transition 🟡→🔴 (une faute) ;
//  - le DIAGNOSTIC courant (ligne 3, `diagnosticCourant`) est recalculé à chaque coup, quel que
//    soit l'état — c'est la photo de l'instant.

/// Regroupe et **formate** les indicateurs d'observation d'une partie (valeurs venues de l'état).
class FaultIndicators {
  /// 🔄 Isométries appliquées (rotations + miroirs), toutes pièces confondues.
  final int isometryCount;

  /// 🔴 **Fautes** = entrées en cul-de-sac (transitions 🟡→🔴). C'est le maillot à pois ; ici
  /// seulement affiché. Cf. `_bumpFault` dans le provider.
  final int faultCount;

  /// ↔️ Déplacements (translations) d'une pièce **déjà posée**.
  final int translationCount;

  /// 🚑 Retraits effectués alors que le plateau était **rouge** (sorties de cul-de-sac).
  final int redRemovalCount;

  /// ⚠️ Fautes classées « **aire non multiple de 5** » (englobe les poches < 5).
  final int faultAireCount;

  /// 🌫️ Fautes classées « **impossibilité subtile** » (zones multiples de 5, mais plateau mort).
  final int faultSubtileCount;

  /// Σg **Somme des gravités** des fautes (gravité d'une aire = `kGraviteAireCoeff / taille`).
  final double faultGraviteSum;

  const FaultIndicators({
    required this.isometryCount,
    required this.faultCount,
    required this.translationCount,
    required this.redRemovalCount,
    required this.faultAireCount,
    required this.faultSubtileCount,
    required this.faultGraviteSum,
  });

  /// Ligne 1 — compteurs bruts d'actions/événements.
  String get ligneCompteurs =>
      '🔄 $isometryCount  🔴 $faultCount  ↔️ $translationCount  🚑 $redRemovalCount';

  /// Ligne 2 — classification cumulée des fautes (décompte par cause + somme de gravité).
  String get ligneClassification =>
      '⚠️ $faultAireCount  🌫️ $faultSubtileCount  Σg ${faultGraviteSum.toStringAsFixed(1)}';
}

/// Ligne 3 — **diagnostic de l'état COURANT** du plateau, à recalculer à chaque coup :
/// `✅ résolu` si terminé, `🟢 soluble` si une solution reste atteignable, sinon la cause courante
/// (`analyzeFault`) avec sa zone et sa gravité (`⚠️ 4 (g5.0)` / `🌫️ · (g1.0)`).
String diagnosticCourant({
  required Plateau plateau,
  required bool hasPossibleSolution,
  required bool isComplete,
}) {
  if (isComplete) return 'maintenant : ✅ résolu';
  if (hasPossibleSolution) return 'maintenant : 🟢 soluble';
  return 'maintenant : ${analyzeFault(plateau).labelCourt}';
}

/// Tailles des zones **vides** (case == 0) connexes (4-voisins), par flood-fill itératif.
List<int> _emptyRegionSizes(Plateau board) {
  final w = board.width;
  final h = board.height;
  final seen = List.generate(h, (_) => List<bool>.filled(w, false));
  final sizes = <int>[];

  for (int y0 = 0; y0 < h; y0++) {
    for (int x0 = 0; x0 < w; x0++) {
      if (board.getCell(x0, y0) != 0 || seen[y0][x0]) continue;
      int size = 0;
      final stack = <List<int>>[
        [x0, y0]
      ];
      seen[y0][x0] = true;
      while (stack.isNotEmpty) {
        final p = stack.removeLast();
        final x = p[0], y = p[1];
        size++;
        const deltas = [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1]
        ];
        for (final d in deltas) {
          final nx = x + d[0];
          final ny = y + d[1];
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          if (board.getCell(nx, ny) != 0 || seen[ny][nx]) continue;
          seen[ny][nx] = true;
          stack.add([nx, ny]);
        }
      }
      sizes.add(size);
    }
  }
  return sizes;
}
