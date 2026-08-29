# Plan — supprimer le module classique

> Établi le 2026-08-29 par cowork, sur l'intention annoncée par Paul. **Rien n'est à
> exécuter en l'état** : deux décisions de fonctionnalité manquent (§3) et une condition
> d'ordre n'est pas remplie (§5).
>
> Mesures relevées sur l'arbre de travail après `1833aba`.

---

## 1. Pourquoi c'est devenu possible

Ce n'était pas le cas avant le temps 2. Ça l'est depuis, et pour une raison précise :
**Pentoscope ne dépend plus d'aucune ligne du chemin classique.**

Le câblage livré par le CLI lui a donné sa propre chaîne complète :

| | mode classique | Pentoscope depuis `35ba8e4` |
|---|---|---|
| chargement | `solutionsReadyProvider` → singleton global `solutionMatcher` | `pentoscopeSolutionsProvider`, famille indexée par `SolutionTable`, instances propres |
| masque pieces/mask | extension `plateau_solution_counter._toBigIntMask` (6×10 en dur) | `TableSolutionSource._mask`, dimensionné par la table |
| comptage / indice | `Plateau.countPossibleSolutions()` | `SolutionSource` |

Vérification : `grep -rn 'solutionMatcher\|countPossibleSolutions\|solutionsReadyProvider'
lib/pentoscope/` ne renvoie **rien**. Les 14 sites qui restent sont tous dans
`lib/classical/`, `lib/screens/` ou `lib/main.dart`.

C'est ce découplage qui rend la suppression mécanique plutôt que risquée.

> **Effet de bord à connaître** : il existe désormais **trois** implémentations du couple
> (pieces, mask) — `common/bigint_plateau.dart` (orpheline, la mieux écrite),
> `plateau_solution_counter._PlateauBigIntMask`, et `TableSolutionSource._mask`. Supprimer
> le module classique en éteint une ; il en restera deux, dont une orpheline.

---

## 2. Ce qui s'en va sans qu'aucune décision soit nécessaire

| chemin | lignes | remarque |
|---|---|---|
| `lib/classical/` (4 fichiers) | **2313** | provider 1387, screen 661, state 236, spec 29 |
| `lib/screens/pentomino_game/` moins les fichiers à déménager | **966** | `game_board` 486, `action_slider` 285, `piece_slider` 189, `game_utils` 6 (déjà mort, aucun lecteur) |

**Plancher : 3279 lignes**, sans rien décider.

Points d'entrée à couper — trois sites, mais **un seul est vivant** (constaté le
2026-08-29, voir §2.1) :

| site | quoi | vivant ? |
|---|---|---|
| `lib/pentoscope/screens/pentoscope_game_screen.dart` l.26 et l.231-241 | import + bouton « Mode Classique » (icône `manage_search`) | **oui — le seul** |
| `lib/screens/home_screen.dart` l.8 et l.103 | import + bouton | non, l'écran est injoignable |
| `lib/main.dart` l.16 et l.80 | import + route `'/game'` | non, aucun `pushNamed` dans le dépôt |

### 2.1 Découverte du 2026-08-29 — `HomeScreen` est injoignable, et il porte les Réglages

`main.dart` démarre sur `PentoscopeGameScreen` (l.77). Les deux routes nommées `'/home'` et
`'/game'` sont déclarées (l.80-81) et **jamais utilisées** : `grep -rn "pushNamed" lib/` ne
renvoie rien. `HomeScreen` n'est donc atteignable par aucun chemin à l'exécution.

Conséquence immédiate, **indépendante de cette suppression** : `SettingsScreen`
(`lib/screens/settings_screen.dart`, seul référencé depuis `home_screen` l.124) et
`DatabaseDebugScreen` (l.135) sont **inatteignables**. Tous les réglages de jeu sont hors
d'atteinte — taille des icônes, couleurs, difficulté, indices, et la bascule « Compteur de
solutions » ajoutée par la décision 16.

> **`HomeScreen` ne doit donc PAS être supprimé avec le mode classique** : il faut au
> contraire lui redonner un accès, ou déplacer l'entrée « Réglages » vers l'AppBar de
> Pentoscope ou son écran de menu. C'est un correctif à part, plus urgent que la
> suppression — voir décision 23.

---

## 3. Les deux fonctionnalités à ré-héberger — tranché le 2026-08-29

Paul a retenu le portage dans les deux cas (décisions 21 et 22). Le travail réel n'est pas
le même des deux côtés, et **une de mes deux estimations était fausse** : elle est corrigée
en §3.2.

### 3.1 Le navigateur de solutions — plus simple que prévu

`lib/screens/solutions_browser_screen.dart` (437 l.) est atteignable depuis deux sites, tous
deux dans le mode classique : l'écran l.312 et `action_slider` l.229.

**Son couplage au singleton est du code mort.** L'écran a deux constructeurs :

| constructeur | source des solutions | appelants |
|---|---|---|
| `SolutionsBrowserScreen()` | `_matcher.allSolutions` — le singleton | **aucun** |
| `.forSolutions(solutions:, title:)` | la liste passée | les **deux** sites vivants |

Le champ `final SolutionMatcher _matcher = solutionMatcher;` (l.38) ne sert donc que la
branche `else` du `initState`, que personne n'atteint. **Le navigateur n'a pas besoin d'un
`SolutionMatcher` du tout** : supprimer le champ, l'import de `solution_matcher.dart`, le
constructeur par défaut et la branche `else`. L'écran devient un afficheur pur de
`List<BigInt>`, sans dépendance à quoi que ce soit de global.

Il quitte alors `lib/screens/` pour `lib/common/widgets/` ou `lib/pentoscope/screens/`.

**Le travail est côté appelant.** Ce qu'il faut reconstituer, c'est
`getCompatibleSolutionsIncludingSelected` (`action_slider.dart` l.19-51), qui prend un
`PentominoGameState` et rend `List<BigInt>`. Le remplaçant est une **quatrième méthode de
`SolutionSource`**, cohérente avec l'interface existante :

```dart
/// Les solutions complètes compatibles avec ce plateau, en BigInt.
/// Liste vide pour la source à la volée, qui ne les énumère pas.
List<BigInt> compatibleSolutions(Plateau plateau);
```

`TableSolutionSource` la sert en trois lignes : son `_mask` existe déjà, et le matcher
expose `getCompatibleSolutionsFromBigInts`. `LiveSolutionSource` renvoie `const []`, et le
bouton du navigateur ne s'affiche que si la liste peut être non vide — c'est-à-dire quand
`size.table != null`.

> ⚠️ **La subtilité « including selected ».** Le nom de la fonction classique dit ce qu'elle
> fait : sous *lift-out*, la pièce sélectionnée avait quitté `placedPieces`, il fallait la
> réinjecter à la main dans un plateau temporaire — d'où ses 33 lignes. Sous *stay + mask*,
> Pentoscope a déjà la pièce dans `placedPieces` ; c'est `state.plateau` qui la masque.
> L'équivalent tient donc en **un appel** : demander `compatibleSolutions(_rebuildPlateau())`
> — sans `exclude:` — au lieu de `state.plateau`. Les 33 lignes disparaissent, elles ne se
> portent pas.

**Ce qui meurt quand même** : `services/plateau_solution_counter.dart` (135 l.) et
`providers/solutions_provider.dart` (49 l.) n'auront plus aucun lecteur, ni le singleton
`solutionMatcher` lui-même. Le navigateur survit ; sa plomberie 6×10-en-dur, non.

### 3.2 L'historique de parties — mon estimation était fausse

J'ai annoncé « une dizaine de lignes ». **C'est faux, et pour une raison de schéma.**

`GameSessions.solutionNumber` est `integer()` **non nullable** : c'est le numéro de la
solution résolue, de 1 à 9356. Et `saveGameSession` s'en sert comme **clé** pour
`_updateSolutionStats`, qui alimente la table `SolutionStats`.

Deux problèmes, dont un bloquant :

1. **Pentoscope ne connaît pas ce numéro.** Le mode classique le tient dans
   `state.solvedSolutionIndex`. Récupérable côté table : `SolutionMatcher.findSolutionIndex`
   (`solution_matcher.dart` l.603) existe et fait exactement ça. → une **cinquième méthode**
   de `SolutionSource` : `int? solutionIndexOf(Plateau plateau)`, `null` pour la source à la
   volée.
2. **Le numéro n'est pas unique entre tables.** Dès l'arrivée du 5×12 et du 4×15, la
   solution n° 5 du 6×10 et la solution n° 5 du 5×12 sont deux choses différentes, et
   `SolutionStats` les fusionnerait en silence. **Il faut une colonne qui identifie le
   plateau** — donc une **migration drift**, pas un simple `insert`.

Et une question de jeu qui n'a pas de réponse évidente : **que fait-on des tailles sans
table ?** Un puzzle 4×5 n'a pas de numéro de solution. Trois options : ne rien enregistrer
pour ces tailles ; enregistrer avec `solutionNumber = -1` — ce que fait déjà le mode
classique en repli, et qui pollue `SolutionStats` d'une clé bidon ; ou rendre la colonne
nullable, ce qui est la solution propre et fait partie de la même migration.

**Périmètre réel** : cinquième méthode de `SolutionSource`, migration drift (colonne de
plateau + `solutionNumber` nullable), écriture dans le chemin de complétion de Pentoscope,
et l'adaptation de `getGameHistory` / `getFastestCompletion` / `getHighestScore` qui
devront filtrer par plateau pour rester comparables. `database_debug_screen.dart` (255 l.)
suit.

Ce n'est pas énorme, mais c'est un chantier à part entière — **il ne doit pas se glisser
dans le commit de suppression.** Il vient avant, sur le module classique encore vivant, ou
après, sur Pentoscope seul.

> **Les données existantes sont préservées** dans les deux cas : la migration ajoute une
> colonne, elle n'efface rien. Les parties déjà enregistrées sont des 6×10 du mode
> classique et le resteront, avec la valeur par défaut de la nouvelle colonne.

## 4. Ce qui doit DÉMÉNAGER avant, pas être supprimé

Cinq fichiers de `lib/screens/pentomino_game/` servent **Pentoscope et le multijoueur**.
Supprimer le dossier sans les sortir d'abord casse la compilation :

| fichier | lignes | lu par |
|---|---|---|
| `widgets/shared/piece_renderer.dart` | 120 | `pentoscope_board`, `pentoscope_piece_slider` |
| `widgets/shared/piece_border_calculator.dart` | 109 | `pentoscope_board` |
| `widgets/shared/draggable_piece_widget.dart` | 160 | `pentoscope_piece_slider` |
| `utils/game_colors.dart` | 80 | les deux précédents |
| `utils/game_constants.dart` | 36 | `piece_border_calculator` |

**505 lignes à déplacer** vers `lib/common/widgets/` (et `lib/common/` pour les deux utils),
avec les imports correspondants. Chaîne de dépendances vérifiée : aucun de ces cinq
fichiers n'importe quoi que ce soit du mode classique.

> C'est aussi le bon moment pour `PieceRenderer` et sa taille de case codée en dur à 22 px
> (§6 du plan 6×10, la miniature signalée par Paul) : le fichier change d'adresse, un
> paramètre `cellSize` de défaut 22 s'y ajoute sans risque.

---

## 5. La condition d'ordre — non remplie à ce jour

**Le test appareil du temps 2 n'a pas été rapporté.** Or le §4.3 du plan 6×10 désigne le
compteur du mode classique comme **canari** : c'est lui qui prouve que la paramétrisation
additive de `SolutionMatcher` n'a rien cassé.

Supprimer le module classique avant ce test, c'est retirer le témoin avant de l'avoir lu.
Deux conséquences :

1. Si le compteur de Pentoscope se révélait faux, il n'y aurait plus de seconde
   implémentation à laquelle le comparer.
2. Le canari doit être **remplacé** avant de disparaître : un test unitaire sur
   `SolutionMatcher` — plateau vide 6×10 → 9356 ; un plateau à une pièce posée → compte
   stable entre deux exécutions. C'est le seul travail neuf que cette suppression exige.

**Ordre imposé :**

1. Test appareil du temps 2 (§4.7 du plan 6×10), **étape 5 comprise**. ⛔ Bloquant.
2. Test unitaire de `SolutionMatcher` — le remplaçant du canari. Commit seul.
3. **Navigateur** (§3.1) : le dégraisser du singleton, ajouter `compatibleSolutions` à
   `SolutionSource`, le brancher dans Pentoscope. Commit seul. À ce stade il existe **deux**
   accès au navigateur, l'ancien et le nouveau — c'est voulu, ça permet de les comparer à
   l'écran sur le même plateau.
4. **Historique** (§3.2) : chantier à part — cinquième méthode, migration drift, écriture
   dans Pentoscope. **Ne pas le mêler à la suppression.** Peut aussi bien venir après
   l'étape 7.
5. Déménagement des 5 fichiers (§4), commit seul, `flutter analyze` à 0.
6. Coupure des 3 points d'entrée (§2), commit seul — l'app ne mène plus au mode classique.
7. Suppression des fichiers, `git rm`, commit seul.

Les étapes 5, 6 et 7 sont séparées à dessein : après 5 tout compile encore avec le mode
classique en place, après 6 il est injoignable mais présent, après 7 il n'est plus là.
Chacune est réversible seule.

**L'étape 3 avant l'étape 6, sans exception.** Couper l'accès au mode classique avant
d'avoir vu le navigateur marcher depuis Pentoscope, c'est perdre le point de comparaison au
moment précis où on en a besoin.

---

## 6. Critères de fin

```bash
grep -rn "classical/" lib/                      # attendu : aucun résultat
grep -rn "screens/pentomino_game/" lib/         # attendu : aucun résultat
grep -rn "solutionMatcher" lib/ | grep -v pentoscope/   # selon décision §3.1
dart run tools/check_orphan_files.dart          # ne doit pas signaler de nouvel orphelin
flutter analyze                                 # 0 warning
```

Test appareil : les trois modules (Pentoscope, multijoueur, et **toutes** les tailles) se
lancent ; aucun bouton ne mène nulle part ; le compteur du 6×10 est intact.

---

## 7. Ce que ça éteint, en dette

- la troisième implémentation du chrono n'est pas concernée (elle est dans le multijoueur) ;
- `applyIsometryRotation()` inexistante appelée sur un `notifier` dynamique
  (`game_board.dart` l.447) — **disparaît avec le fichier** ; c'était un
  `NoSuchMethodError` au double-tap ;
- `setDragging` jamais appelé côté classique — la question s'éteint, le mixin ne sert plus
  qu'à Pentoscope, qui l'appelle ;
- `_toBigIntMask` et son `try/catch` qui convertit une erreur en `null` — disparaît si
  §3.1 retient l'issue 1 ou 2 ;
- le commentaire faux de `main.dart` l.38-39 (« Pentoscope […] n'en a pas besoin, il ne
  doit pas être ralenti au démarrage ») — à corriger ou à supprimer, il ment depuis le
  temps 2.

---

## Voir aussi

- `docs/PLAN_6X10_DANS_PENTOSCOPE.md` — §4.3 (le canari), §6 (les défauts du mode classique)
- `docs/JOURNAL.md` — §ÉTAT, décisions 7 (le gel du mode classique) et 19
- `docs/PLAN_SUPPRESSION_DEMO.md` — le précédent, même forme, exécuté le 2026-08-28
