// Modified: 2026-09-01 09:35 — création : logger de diagnostic du drag (PLAN_DIAG_DRAG §3).
//           Instrumentation seule, derrière kDragDiag et kDebugMode. Une ligne CSV par événement,
//           tag DRAGDIAG. Aucune correction. Flag mis à TRUE pour la phase de capture du §4.
// lib/common/drag_diag.dart

import 'package:flutter/foundation.dart';

/// Interrupteur du diagnostic de drag (PLAN_DIAG_DRAG). Comme c'est un `const`, tout le code gardé
/// par `kDragDiag` est éliminé à la compilation quand il vaut `false`. En release, `dragDiag`
/// n'imprime de toute façon rien (garde `kDebugMode`), donc ce flag n'a d'effet qu'en debug.
///
/// **Actuellement `true`** : phase de capture des 20 descentes du §4 (build **debug**). À remettre
/// à `false` une fois la ou les causes prouvées et consignées dans `JOURNAL §DÉCISIONS`.
const bool kDragDiag = true;

/// Compteur d'échantillonnage des `pointer-move` (voir [dragDiagSample]).
int _moveCounter = 0;

/// Émet une ligne CSV de diagnostic, préfixée du tag `DRAGDIAG,`. N'imprime qu'en debug et
/// quand [kDragDiag] est actif. Le contenu est une suite de jetons `clé=valeur` séparés par des
/// virgules — greppable par `grep DRAGDIAG`, analysable par `awk -F,`.
void dragDiag(String csv) {
  if (kDragDiag && kDebugMode) {
    debugPrint('DRAGDIAG,$csv');
  }
}

/// Vrai une frame sur [every] : sert à n'échantillonner qu'un `pointer-move` sur cinq, comme le
/// demande le §3 (les move sont trop nombreux pour être tous tracés). Incrémente à chaque appel,
/// donc à n'appeler que derrière une garde `kDragDiag` pour ne pas fausser l'échantillon.
bool dragDiagSample([int every = 5]) => (_moveCounter++ % every) == 0;

/// Réinitialise le compteur d'échantillonnage : à appeler au début de chaque drag (pointer-down)
/// pour que chaque descente commence sur une frame tracée.
void dragDiagResetSample() => _moveCounter = 0;
