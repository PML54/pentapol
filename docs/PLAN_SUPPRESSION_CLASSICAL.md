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

> ⛔ **RENVERSÉ le 2026-08-29 (décision 32).** Paul a finalement choisi d'**abandonner**
> l'historique plutôt que de le porter. Mode opératoire : **§9**. La section ci-dessous reste
> pour mémoire — c'est elle qui a montré le coût réel du portage, et c'est ce coût qui a
> emporté la décision.


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

## 8. Suite — les Réglages dans l'AppBar, et l'abandon de `HomeScreen`

> Décidé par Paul le 2026-08-29 (décision 31) : l'entrée « Réglages » passe dans l'AppBar de
> Pentoscope, `HomeScreen` est abandonné. **Attention : cette décision a deux conséquences
> qu'elle n'énonce pas** — §8.2.

### 8.1 Le geste principal

`SettingsScreen` n'est référencé que depuis `HomeScreen` l.114. Il faut lui donner une entrée
dans `pentoscope_game_screen.dart`, bloc `actions:` (l.184-249) :

```dart
IconButton(
  icon: const Icon(Icons.settings),
  onPressed: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const SettingsScreen())),
  tooltip: 'Réglages',
),
```

Puis retirer de `main.dart` la route `'/home'` (l.76) et l'import de `HomeScreen`, et
`git rm lib/screens/home_screen.dart`.

> ⚠️ **Le bloc `actions:` vaut `null` quand une pièce est sélectionnée** (l.184-186). Le
> bouton Réglages disparaît donc pendant une manipulation. C'est sans conséquence — on
> n'ouvre pas les réglages en tenant une pièce — mais il ne faut pas le prendre pour un
> défaut au test.

> ⚠️ **Encombrement.** L'AppBar porte déjà cinq `IconButton` (taille plateau, multijoueur,
> nouvelle partie, indice, navigateur de solutions). Un sixième, à ~48 px chacun, occupe
> ~288 px : sur un écran de 390 px de large il ne reste qu'une centaine de pixels pour le
> titre — **où s'affiche justement le compteur de solutions**. Si c'est trop serré au test,
> le remède est de grouper les trois boutons rares (multijoueur, navigateur, réglages) dans
> un `PopupMenuButton`, pas de rogner les icônes.

### 8.2 Ce que l'abandon de `HomeScreen` emporte avec lui

`HomeScreen` porte **trois** cartes, pas une. Retirer l'écran orpheline les deux autres :

| écran | lignes | seul accès | conséquence |
|---|---|---|---|
| `SettingsScreen` | 738 | `home_screen` l.114 | **traité** par §8.1 |
| `PentoscopeMenuScreen` | 190 | `home_screen` l.92 | **orphelin** |
| `DatabaseDebugScreen` | 255 | `home_screen` l.125 | **orphelin** |

**`PentoscopeMenuScreen`** — ⚠️ **« double emploi » n'est vrai qu'à moitié.** Vérification
faite, le bouton « + » de l'AppBar appelle `_showSizeChangeDialog`, qui appelle
`changeBoardSize`, qui code en dur `difficulty: PentoscopeDifficulty.random` et
`showSolution: false` (`pentoscope_provider.dart` l.704-712). Le menu est donc le **seul
endroit** où l'on choisit :

- la **difficulté** (`easy` / `random` / `hard`) — sans lui, `generateEasy` et `generateHard`
  n'ont plus d'appelant et deviennent du code mort ;
- l'option **« montrer la solution »** au démarrage.

Seul le choix de la taille est réellement dupliqué.

> ✅ **Tranché par Paul (décision 35) : le dialogue absorbe le menu.** « Changer la taille du
> plateau » devient **« Nouvelle partie »** et porte les trois réglages ; `PentoscopeMenuScreen`
> est supprimé.

#### Mode opératoire du dialogue

`_showSizeChangeDialog` (`pentoscope_game_screen.dart` l.989-1022) devient
`_showNewGameDialog` et gagne deux contrôles, repris de
`pentoscope_menu_screen.dart` l.19-21 et l.170-178 :

- la difficulté — `PentoscopeDifficulty.easy / random / hard` ;
- un `SwitchListTile` « Montrer la solution ».

Il faut donc un état local : envelopper le contenu dans un `StatefulBuilder` (le dialogue est
aujourd'hui sans état), et remplacer l'action immédiate par un bouton **« Lancer »** qui
appelle directement :

```dart
notifier.startPuzzle(size, difficulty: difficulty, showSolution: showSolution);
```

`changeBoardSize` (`pentoscope_provider.dart` l.704-712) n'a alors plus d'appelant : le
supprimer dans le même commit.

> **Le changement d'interaction est un gain, pas seulement un coût.** Aujourd'hui, toucher une
> taille dans la liste **relance immédiatement une partie** et jette celle en cours, sans le
> dire. Demain il faudra un tap de plus — mais l'intention devient explicite. Ne pas essayer
> de garder les deux comportements : une liste qui agit au tap et un bouton qui agit aussi,
> c'est le meilleur moyen de perdre une partie par mégarde.

> **Préalable, décision 34** : `PentoscopeDifficulty` est déclaré **deux fois**
> (`piece_difficulty.dart` l.25 et `pentoscope_provider.dart` l.65). Le dialogue va le
> référencer : unifier **avant**, sinon on choisit au hasard lequel des deux types on importe.
> Garder celui de `pentoscope_provider.dart` (c'est lui que `startPuzzle` prend en paramètre)
> et faire de l'autre un ré-export, ou l'inverse — mais un seul déclarant.

Le sélecteur de taille en deux groupes du plan 6×10 §5.5 prend alors place **dans ce
dialogue**, et non plus dans un écran séparé.

**`DatabaseDebugScreen`** — tranché par la décision 32 : il part avec l'historique. Voir §9.

### 8.3 Ordre

1. **Unifier `PentoscopeDifficulty`** (décision 34). Commit seul, préalable strict.
2. **Bouton Réglages dans l'AppBar.** Commit seul, testable immédiatement — c'est lui qui
   débloque le point 3 du test du temps 2.
3. **Dialogue « Nouvelle partie »** : les trois réglages, `startPuzzle` direct, suppression de
   `changeBoardSize` puis `git rm lib/pentoscope/screens/pentoscope_menu_screen.dart`.
4. **`git rm lib/screens/home_screen.dart`** + route `'/home'` + import dans `main.dart`.
   **En dernier** : tant que `HomeScreen` existe, il reste le filet vers les écrans pas encore
   rebranchés.

**Ne pas fusionner 2 et 4.** Si l'AppBar se révèle trop encombrée au test, on veut pouvoir
revenir sur le bouton sans avoir perdu l'autre chemin.

### 8.4 Critères de fin

```bash
grep -rn "HomeScreen\|'/home'" lib/          # attendu : aucun, après l'étape 3
grep -rn "SettingsScreen" lib/                # attendu : sa déclaration + l'entrée AppBar
grep -rn "PentoscopeMenuScreen\|DatabaseDebugScreen" lib/   # aucun orphelin non décidé
flutter analyze                               # 0 warning
```

Test appareil : les Réglages s'ouvrent depuis la partie ; la bascule « Compteur de
solutions » fait bien apparaître et disparaître le compteur — **c'est le point 3 du test du
temps 2, ininstruisable jusqu'ici** ; le compteur reste lisible dans l'AppBar avec le bouton
supplémentaire.

---

## 9. Abandonner l'historique de parties — décision 32

> Paul, 2026-08-29 : l'historique est **abandonné**, pas porté. Motif : les lignes déjà
> enregistrées sont des parties du mode classique, qui n'existe plus ; le portage demandait
> une migration de schéma (§3.2) pour une fonctionnalité qu'il ne consultait pas.
> **Cette décision annule la décision 22.**

### 9.1 Ce qui part

| élément | fichier | lignes |
|---|---|---|
| table `GameSessions` | `database/settings_database.dart` l.33-63 | ~30 |
| table `SolutionStats` | idem l.67-92 | ~26 |
| `saveGameSession`, `getGameHistory`, `getSolutionHistory`, `getFastestCompletion`, `getHighestScore`, `getSolutionStats`, `_updateSolutionStats` | idem l.138-260 | ~120 |
| `DatabaseDebugScreen` | `debug/database_debug_screen.dart` | 255 |

**Aucun de ces éléments n'a d'appelant vivant** — vérifié le 2026-08-29 : le seul lecteur
restant était `getGameHistory` depuis l'écran de debug, lui-même injoignable. La suppression
ne casse donc rien.

La table `Settings` **reste** : c'est elle que consomme `settings_provider`, donc toute la
configuration de l'application.

### 9.2 Le point qui n'est pas mécanique — la migration

`@DriftDatabase(tables: [Settings, GameSessions, SolutionStats])`, `schemaVersion => 1`, et
**aucune `MigrationStrategy`** : le projet n'a jamais migré. Deux façons de faire :

1. **Retirer les tables de la liste et ne rien migrer.** Les nouvelles installations ne les
   créent jamais ; sur un appareil déjà installé, les deux tables restent dans le fichier
   SQLite, orphelines et invisibles. Coût nul, propreté douteuse.
2. **Passer `schemaVersion` à 2** et ajouter une `MigrationStrategy` dont l'`onUpgrade` fait
   deux `DROP TABLE`. Cinq lignes.

*Avis de cowork : la seconde.* Ce sera la première migration du projet ; l'établir sur un cas
trivial et sans enjeu de données vaut mieux que de la découvrir un jour où des données
comptent. Et laisser deux tables fantômes dans la base d'un appareil, c'est exactement le
genre de chose qu'on ne retrouve pas six mois plus tard.

> ⚠️ **`settings_database.g.dart` est généré** (2113 lignes). Après modification du schéma :
> `dart run build_runner build --delete-conflicting-outputs`. Ne jamais l'éditer à la main.

### 9.3 Ordre et critères de fin

1. Retirer les deux tables, les sept méthodes, ajouter la `MigrationStrategy`, régénérer.
2. `git rm lib/debug/database_debug_screen.dart` (et le dossier `lib/debug/` s'il se vide).
3. Commit unique — l'étape 1 seule laisserait un écran qui référence des méthodes disparues.

```bash
grep -rn "GameSession\|SolutionStat\|saveGameSession\|getGameHistory" lib/   # attendu : aucun
grep -n "schemaVersion" lib/database/settings_database.dart                     # attendu : 2
flutter analyze                                                                 # 0 warning
```

Test appareil : l'application démarre **sur une base existante** (c'est le seul vrai test de
la migration — une installation neuve ne l'exécute pas), les réglages sont conservés, aucune
exception au lancement.

---

## Voir aussi

- `docs/PLAN_6X10_DANS_PENTOSCOPE.md` — §4.3 (le canari), §6 (les défauts du mode classique)
- `docs/JOURNAL.md` — §ÉTAT, décisions 7 (le gel du mode classique) et 19
- `docs/PLAN_SUPPRESSION_DEMO.md` — le précédent, même forme, exécuté le 2026-08-28
