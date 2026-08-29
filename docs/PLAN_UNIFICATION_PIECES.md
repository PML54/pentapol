# Plan — unifier la manipulation des pièces (barre + plateau) sur les 3 modules

> Établi le 2026-08-27 20:22. Objectif fixé par Paul : **une seule implémentation** de la
> manipulation des pièces, depuis la barre comme sur le plateau, partagée par
> `classical`, `pentoscope` et `pentoscope_multiplayer`.
>
> Toutes les mesures de ce document ont été obtenues par extraction automatique sur les
> sources. La méthode est indiquée pour que tu puisses les refaire.

---

> ⚠️ **CHANTIER SUSPENDU le 2026-08-29.** Décision de Paul : le mode classique n'est plus
> modifié, Pentoscope devient la référence de la manipulation des pièces et reçoit une
> taille 6×10 adossée aux 9356 solutions. **Les étapes 3 (familles Isométries, Barre,
> Placement), 4 et 5 de ce document ne sont plus à appliquer.** Le plan en vigueur est
> `docs/PLAN_6X10_DANS_PENTOSCOPE.md`.
>
> Ce document reste valide comme historique et comme socle : ses étapes 0 à 2
> (`PlacedPiece` commun, `PieceManipulationState`, `TransformationResult`,
> `ViewOrientation`, `GameTimerMixin`, `PieceInteractionMixin`) sont ce qui rend le port
> possible.

---

## 1. Où on en est vraiment

### Deux familles, pas trois

Le multijoueur n'est pas une troisième implémentation : c'est Pentoscope plus du réseau.
Il réutilise ses widgets et son provider tels quels. **La fracture est entre `classical`
et `pentoscope`** — c'est un problème à deux termes, pas à trois.

| | classical | pentoscope | multijoueur |
|---|---|---|---|
| Plateau | `shared/game_board.dart` (529 l.) | `pentoscope_board.dart` (859 l.) | idem pentoscope |
| Barre | `game_mode/piece_slider.dart` (189 l.) | `pentoscope_piece_slider.dart` (197 l.) | idem pentoscope |
| Provider | `PentominoGameNotifier` (1841 l., 54 méthodes) | `PentoscopeNotifier` (1846 l., 34 méthodes) | consomme celui de pentoscope |

### Ce qui est déjà partagé, et qui marche

- `common/pentomino_game_mixin.dart` — 6 helpers de géométrie : `canPlacePiece` (abstrait),
  `remapSelectedCell`, `getRawMastercaseCoords`, `calculateDefaultCell`,
  `calculateAnchorPosition`, `findNearestValidPosition`
- `common/pentomino_symmetry_api.dart` — les isométries
- `common/placed_piece.dart` — **depuis le 2026-08-27**, un seul type de pièce posée
- `piece_renderer.dart`, `draggable_piece_widget.dart`, `piece_border_calculator.dart` —
  importés par les **deux** familles

Autrement dit : la géométrie et le rendu bas niveau sont mutualisés. C'est la couche
d'**orchestration** — l'enchaînement sélection → drag → snap → pose — qui est doublée.

### 28 méthodes portent le même nom dans les deux providers

Mesure : extraction des méthodes déclarées dans le corps de chaque classe `Notifier`.

| Constat | Nombre |
|---|---|
| Noms communs aux deux providers | **28** |
| Dont signatures identiques et corps de taille comparable | 15 |
| Dont **signatures différentes** | **6** |
| Dont corps très différents (rapport ≥ 2) | 7 |

Les 6 signatures divergentes :

| Méthode | classical | pentoscope |
|---|---|---|
| `applyIsometryRotationCW` | `void` | `TransformationResult` |
| `applyIsometryRotationTW` | `void` | `TransformationResult` |
| `applyIsometrySymmetryH` | `void` | `TransformationResult` |
| `applyIsometrySymmetryV` | `void` | `TransformationResult` |
| `reset` | `void` | `Future<void>` |
| `build` | `PentominoGameState` | `PentoscopeState` |

Les 7 corps très divergents : `cancelSelection`, `cycleToNextOrientation`,
`getRawMastercaseCoordsPublic`, `highlightPieceInSlider`, `placeSelectedPieceForTutorial`,
`scrollSliderToPiece`, `selectPiece`.

À noter : la divergence de taille ne signifie pas toujours une divergence de
comportement. `applyIsometryRotationCW` fait 14 lignes côté classical contre 3 côté
pentoscope simplement parce que classical distingue pièce du slider et pièce posée là où
pentoscope délègue à un helper. C'est de la **normalisation**, pas de la réconciliation.

### Le noyau d'état est déjà commun à 15 champs

`PentominoGameState` (18 champs) et `PentoscopeState` (27 champs) partagent **15 champs
de type strictement identique** :

```
plateau · availablePieces · placedPieces
selectedPiece · selectedPositionIndex · selectedPlacedPiece
piecePositionIndices · selectedCellInPiece
previewX · previewY · isPreviewValid · isSnapped · isDragging
viewOrientation · elapsedSeconds
```

`placedPieces` est de type `List<PlacedPiece>` des deux côtés **depuis la fusion du
2026-08-27** — avant, les types différaient et ce noyau n'existait pas.

Champs propres à classical : `boardIsValid`, `offBoardCells`, `solutionsCount`,
`solvedSolutionIndex`, `isInTutorial`, `isometriesCount`, `solutionsViewCount`.
Champs propres à pentoscope : `puzzle`, `currentSolution`, `validPlacements`,
`selectedMasterAbs`, `hasPossibleSolution`, `isComplete`, `showSolution`, et cinq
compteurs de statistiques.

**C'est la découverte qui structure tout le plan** : le désordre est en surface. Dessous,
les deux modules manipulent déjà la même chose.

---

## 2. Le vrai obstacle

Deux verrous, dans cet ordre de gravité.

**Les widgets lisent un provider global nommément.**

```
game_board.dart        →  import classical/pentomino_game_provider
pentoscope_board.dart  →  import pentoscope/pentoscope_provider
```

Un widget qui nomme son provider ne peut servir qu'un module. La duplication n'est pas un
défaut de discipline, c'est une conséquence mécanique. Tant que ce couplage tient, aucune
fusion de widget n'est possible.

**Les 28 méthodes opèrent sur deux types d'état distincts.** Elles ne peuvent pas monter
dans un mixin partagé tant qu'elles manipulent `PentominoGameState` d'un côté et
`PentoscopeState` de l'autre.

---

## 3. Ce qu'il ne faut PAS faire en premier

**Fusionner les deux plateaux.** C'est le réflexe, et c'est un piège.
`pentoscope_board.dart` contient de la **logique de jeu** que `game_board.dart` laisse à
son provider : `placeSelectedPiece`, `selectPieceOnBoard`, `highlightCell`,
`_showVictoryDialog`. Sur les méthodes des deux fichiers, 5 noms communs seulement,
25 propres à Pentoscope. Les fusionner maintenant produirait un fichier commun contenant
le désordre des deux, sans rien résoudre.

---

## 4. Le chemin

Cinq étapes. Chacune a un critère de fin vérifiable et laisse l'application en état de
marche — aucune ne demande un « big bang ».

### Étape 0 — un seul type de pièce posée ✅ FAIT le 2026-08-27

`PentoscopePlacedPiece` fusionné dans `common/PlacedPiece` (commit `1b97e82`).
C'est ce qui a rendu le noyau d'état commun possible.

### Étape 1 — extraire le noyau d'état commun ✅ FAIT le 2026-08-27

**Réalisée autrement que prévu.** Le plan proposait un objet de valeur imbriqué ; mesure
faite avant d'écrire, les 15 champs sont lus à **≈ 407 endroits** dans `lib/`, qu'il
aurait fallu réécrire en `state.pieces.<champ>`. Retenu à la place : une **interface
abstraite** `common/piece_manipulation_state.dart`, que les deux états implémentent. Les
champs `final` existants la satisfont automatiquement — **aucun site d'appel modifié**, et
le compilateur garantit désormais que les deux états restent alignés.

Obstacle découvert au passage : `ViewOrientation` était déclaré **deux fois**, en deux
types distincts pour Dart. Unifié dans `common/view_orientation.dart`, ré-exporté par les
deux anciens hôtes.

- **Critère de fin** : les deux états compilent, les 15 champs ne sont plus déclarés
  qu'une fois, l'application se comporte à l'identique.
- **Risque** : faible mais diffus — chaque `state.selectedPiece` devient
  `state.pieces.selectedPiece`. Beaucoup de sites d'appel, tous mécaniques. Le
  compilateur les signale tous ; rien ne peut passer silencieusement.
- **Taille** : la plus grosse en nombre de lignes touchées, la plus faible en réflexion.

### Étape 2 — aligner les signatures divergentes ✅ FAIT le 2026-08-27

`TransformationResult` (enum `success` / `recentered` / `impossible`) déplacé de
`pentoscope_provider.dart` vers `common/transformation_result.dart`, ré-exporté par
l'ancien hôte. Les 4 `applyIsometry*` du mode classique le renvoient désormais au lieu
de `void`.

Sur 31 sites d'appel des isométries, **4 seulement consomment le résultat**, tous côté
Pentoscope. Les 27 autres ignorent la valeur : le changement leur est transparent.

**Le mode classique ne renvoie que `success`.** Ses helpers
(`_applyRotationToPlacedPiece`, `_applySymmetryToPlacedPiece`) n'ont, vérification faite,
**aucun chemin d'échec** : ils sortent sans rien faire quand la transformation ne change
rien, sans le signaler. L'alignement porte donc sur le **type**, pas sur la sémantique —
celle-ci relève de l'étape 3, quand les corps fusionneront. C'est documenté sur l'enum
lui-même, pour que personne ne se fie à un `success` venant du mode classique.

#### Décision : `reset` et `build` ne sont PAS alignés

Le plan initial prévoyait d'aligner `reset` sur `Future<void>` des deux côtés. **Écarté
après examen**, pour deux raisons :

- Le `reset()` du mode classique est **réellement synchrone** — arrêt du chrono,
  réinitialisation de l'état, comptage des solutions. Celui de Pentoscope est
  `Future<void>` parce qu'il **régénère un puzzle**, ce qui est asynchrone par nature.
  Forcer `Future<void>` sur classical produirait un `async` de façade, sans bénéfice.
- `reset` et `build` relèvent du **cycle de vie**, pas de la manipulation des pièces.
  Ils sortent du périmètre de ce plan.

Divergence légitime, donc conservée. Il reste 0 signature divergente **dans le périmètre
des pièces**.

- **Critère de fin atteint** : les méthodes de manipulation des pièces ont des signatures
  identiques dans les deux providers.

### Étape 3 — remonter les méthodes dans le mixin, par famille

Une fois 1 et 2 faites, les 28 méthodes opèrent sur le même noyau avec les mêmes
signatures. Elles peuvent monter dans `PentominoGameMixin`. **Par famille, un commit
chacune**, jamais toutes d'un coup :

| Famille | Méthodes |
|---|---|
| Sélection ⚠ | `selectPiece`, `selectPlacedPiece`, `cancelSelection` — **temps 1 fait**, temps 2 planifié, voir plus bas |
| Preview & drag ⚠ | `setDragging` ✅, `clearPreview` ✅ — **`updatePreview` reclassé** (voir ci-dessous) |
| Placement | `tryPlacePiece`, `updatePreview`, `getPlacedPieceAt`, `removePlacedPiece` |
| Isométries | les 4 `applyIsometry*`, `cycleToNextOrientation` |
| Barre | `highlightPieceInSlider`, `clearSliderHighlight`, `scrollSliderToPiece` |
| Chrono ✅ | `startTimer`, `stopTimer`, `getElapsedSeconds` — **fait le 2026-08-27** |

Commencer par **Chrono** et **Preview & drag** : corps déjà quasi identiques, gain
immédiat, risque nul.

> **Défaut corrigé, 2026-08-27 — une isométrie pouvait faire sortir la pièce du
> plateau.** Signalé par Paul en mode classique : une rotation ou une symétrie change
> l'empreinte de la pièce **sans déplacer son ancre**, si bien qu'une pièce collée à un
> bord se retrouvait partiellement hors plateau et s'affichait tronquée.
>
> Cause exacte : les **quatre** méthodes d'isométrie du mode classique ne faisaient
> aucune vérification de bornes — ce qui est précisément la raison pour laquelle elles
> renvoyaient toujours `success` (voir étape 2). Pentoscope, lui, recentre déjà : son
> `neededRecentering` est posé à dix endroits.
>
> Correction : un garde-fou unique `_keepOnBoard(PlacedPiece)` appliqué aux **6 sites**
> où une pièce posée reçoit une nouvelle orientation. Décalage **minimal**, juste ce
> qu'il faut pour que toutes les cellules rentrent. Il ne vérifie **que les bornes**,
> pas les chevauchements : c'est le défaut signalé, et `boardIsValid` continue de
> signaler le reste.
>
> **Dette restante** : le décalage n'est pas remonté dans le retour. Ces méthodes
> devraient renvoyer `TransformationResult.recentered` quand `_keepOnBoard` a déplacé la
> pièce. Non fait ici pour ne pas mêler une correction de défaut à un changement de
> sémantique dans le même commit — à traiter avec la famille Isométries.
>
> **Décision de jeu, 2026-08-27 — le magnétisme devient assistant partout.** Les deux
> modes n'avaient pas le même comportement d'accrochage : le mode classique cherchait
> une position valide dans un rayon de **2 cases** et affichait rouge au-delà ; Pentoscope
> snappait sur la position valide la plus proche **sans aucune limite de distance**. Paul
> a tranché pour le comportement de Pentoscope, plus assistant.
>
> **Appliqué autrement que « reprendre l'implémentation de Pentoscope ».** Ce port aurait
> imposé d'ajouter `validPlacements` à l'état classique et d'en répliquer les **13 sites
> d'invalidation**, et fait perdre l'indicateur `isSnapped` (preview cyan) que seul le mode
> classique alimente. Le mode classique ayant déjà l'algorithme « position valide la plus
> proche dans un rayon », il a suffi de porter `_snapRadius` de 2 à **10** — le plateau
> 6×10 est alors entièrement couvert depuis n'importe quelle ancre. Une constante, aucun
> état ajouté, l'indicateur cyan préservé.
>
> Coût : 440 positions testées par mouvement du doigt au lieu de 24, soit ~2200
> vérifications de case. Négligeable à l'échelle d'un geste ; c'est le premier poste à
> regarder si le drag devenait saccadé sur un appareil lent.
>
> **Défaut découvert, non corrigé** : Pentoscope **lit** `state.isSnapped` dans
> `pentoscope_board.dart` pour afficher une preview cyan, mais ne l'**écrit** jamais — le
> champ n'apparaît chez lui qu'en déclaration, valeur par défaut et plomberie de
> `copyWith`. La branche cyan de Pentoscope est donc morte depuis toujours. À traiter avec
> la famille Placement, où les deux `updatePreview` seront réconciliés.
>
> **Famille Sélection — analyse du 2026-08-28 09:15, décision en attente.**
>
> Les trois méthodes (`selectPiece`, `selectPlacedPiece`, `cancelSelection`) diffèrent
> non par leur écriture mais par un **modèle de données différent** de ce qu'est une
> « pièce posée sélectionnée ».
>
> | | mode classique | Pentoscope |
> |---|---|---|
> | Modèle | **lift-out** : la pièce est *retirée* de `placedPieces` pendant la manipulation | **stay + mask** : la pièce *reste* dans `placedPieces` |
> | Fin de sélection | il faut la **ré-ajouter** et reconstruire le plateau à la main | `plateau: _rebuildPlateau()` — une ligne |
> | Plateau sans la pièce | reconstruit à la main | `_rebuildPlateau(exclude: placed)` |
>
> Mesures :
>
> | | classique | Pentoscope |
> |---|---|---|
> | Reconstructions du plateau écrites à la main (`Plateau.allVisible`) | **12** | 0 |
> | Appels à un helper factorisé (`_rebuildPlateau`) | 0 | **11** |
> | Ré-ajouts de pièce (`..add(`) à ne pas oublier | **8** | 0 |
> | Boucles `(cellNum - 1) % 5` recopiées | 19 | 13 |
>
> **Pourquoi le modèle de Pentoscope est meilleur, et pas seulement plus court :** dans
> le modèle lift-out, tout chemin de sortie qui oublie de ré-ajouter la pièce la fait
> **disparaître définitivement**. Il y a 8 endroits où cet oubli est possible. Dans le
> modèle stay + mask, cette classe de défaut **n'existe pas** : la pièce n'ayant jamais
> quitté la liste, aucun code ne peut omettre de l'y remettre.
>
> **Vérifications faites, sans résultat alarmant** — à ne pas re-suspecter :
> - `cancelSelection` du mode classique commence par `if (state.selectedPiece == null)
>   return;`. Ce garde-fou est **sain** : `selectPlacedPiece` renseigne bien
>   `selectedPiece` (ligne 101), la pièce est donc toujours restituée.
> - `calculateDefaultCell` du mixin normalise, la copie inline du mode classique non.
>   **Sans conséquence** : les 63 orientations ayant toutes leur minimum à 0, les deux
>   expressions donnent le même point.
>
> **Différences de comportement réelles, à trancher :**
> - Pentoscope refuse la sélection si le puzzle est complet (`if (state.isComplete)
>   return;`), le mode classique non.
> - Pentoscope garde l'orientation courante quand on re-sélectionne la pièce déjà
>   sélectionnée (commentaire « BUGFIX ») ; le mode classique relit toujours
>   `piecePositionIndices`.
> - Pentoscope nettoie davantage à l'annulation : `selectedMasterAbs`, `preview`,
>   `validPlacements`. Le mode classique peut laisser une preview obsolète.
>
> **Chemin proposé, en deux temps** (modes opératoires détaillés plus bas) **:**
> 1. **Porter `_rebuildPlateau()` dans le mode classique** et remplacer les 12
>    reconstructions manuelles. Purement mécanique, aucun changement de modèle, gain
>    immédiat en lisibilité et en risque.
> 2. **Puis** basculer le mode classique sur le modèle stay + mask. C'est le vrai
>    changement : les 8 sites de ré-ajout disparaissent, mais tout code supposant « la
>    pièce sélectionnée n'est pas dans `placedPieces` » doit être revu.
>
> Faire le temps 2 avant le temps 1 reviendrait à changer le modèle **et** la forme du code
> en même temps, sans pouvoir attribuer une régression à l'un ou à l'autre.
>
> **Preview & drag, fait le 2026-08-27** → `common/piece_interaction_mixin.dart`,
> `PieceInteractionMixin<S extends PieceManipulationState> on Notifier<S>`. Le bornage
> sur le contrat de l'étape 1 est ce qui permet à `clearPreview` de lire
> `state.previewX` sans connaître le type concret — première fois que l'interface sert
> à autre chose qu'à documenter.
>
> **`updatePreview` a été reclassé dans la famille Placement.** Le plan le disait « quasi
> identique » sur la foi de sa taille — 37 lignes contre 38. Le nombre de lignes était un
> mauvais indicateur : ce sont deux **algorithmes différents**. Le mode classique calcule
> la validité à la volée ; Pentoscope s'appuie sur `validPlacements`, une liste
> pré-calculée dans son état que le mode classique n'a pas, et n'écrit jamais `isSnapped`.
> Les unifier revient à choisir un comportement de snapping pour les deux modes : une
> décision de jeu, pas un refactor.
>
> Gain brut de cette famille : 15 lignes. Le vrai intérêt est d'avoir établi le domicile
> des familles lourdes sur deux méthodes dont l'échec aurait été immédiat et sans
> conséquence.
>
> **Chrono, fait le 2026-08-27** → `common/game_timer_mixin.dart`, mixin générique
> `GameTimerMixin<S> on Notifier<S>`. Le module ne fournit que
> `stateWithElapsedSeconds` : le mixin ignore la forme de l'état.
>
> Contrairement à l'attente, `startTimer` **n'était pas** identique. Les gardes
> différaient — `_startTime != null` côté classique, `_gameTimer != null` côté
> Pentoscope — donnant des comportements incompatibles : le premier ne repartait
> jamais après un arrêt, le second repartait en **perdant le temps écoulé**. La cause
> était que « mettre en pause » et « remettre à zéro » passaient par le même appel.
> Résolu en séparant les intentions : `stopTimer()` conserve l'origine, `resetTimer()`
> l'efface. `startTimer()` devient idempotent et reprend sans perte.
>
> Les champs privés du chrono vivant désormais dans une autre bibliothèque, les accès
> directs ont été remplacés par l'API du mixin : `isTimerRunning` côté Pentoscope,
> `resetTimer()` / `stopTimer()` côté classique.
>
> **Découverte** : il existait une **troisième** implémentation du chrono, dans
> `pentoscope_mp_provider.dart` — l'audit initial disait « deux familles », ce qui vaut
> pour les widgets mais pas ici. Elle n'est **pas** absorbée, pour une raison précise :
> ce provider a **deux** timers qui se partagent les mêmes champs, `_startGameTimer()`
> (1 s, vérifie l'état de partie) et `startTimer()` (100 ms). Le second n'est **jamais
> appelé** ; `getElapsedSeconds` ne l'est que depuis lui. Les deux sont donc morts, mais
> ils échappent à `flutter analyze` parce qu'ils sont publics. À traiter à part.
---

#### Sélection, temps 1 — porter `_rebuildPlateau` ✅ FAIT le 2026-08-27

**Rétro-documenté le 2026-08-28 08:05.** Ce temps 1 est le modèle des étapes suivantes :
il montre à quel niveau de détail un mode opératoire doit descendre pour qu'un autre
agent l'applique sans avoir à redécider.

**Ce qui a été introduit** — un helper unique dans le provider classique, copie
littérale de celui de Pentoscope :

```dart
Plateau _rebuildPlateau({
  List<PlacedPiece>? pieces,
  PlacedPiece? exclude,
}) {
  final src = pieces ?? state.placedPieces;
  final p = Plateau.allVisible(state.plateau.width, state.plateau.height);
  for (final placed in src) {
    if (exclude != null && placed.piece.id == exclude.piece.id) continue;
    for (final cell in placed.absoluteCells) {
      p.setCell(cell.x, cell.y, placed.piece.id);
    }
  }
  return p;
}
```

**Trois formes d'appel, et une seule règle pour choisir :**

| Forme | Sens | Quand |
|---|---|---|
| `_rebuildPlateau()` | plateau tel que `placedPieces` le décrit | restitution, annulation |
| `_rebuildPlateau(exclude: p)` | idem, sans `p` | on prend `p` en main |
| `_rebuildPlateau(pieces: liste)` | plateau d'une liste **explicite** | la liste vient d'être calculée et n'est pas encore dans l'état |

La troisième forme existe parce qu'un `state = state.copyWith(...)` ne peut pas se
servir d'un plateau reconstruit depuis un état qui n'a pas encore été écrit. C'est le
seul cas où `pieces:` est justifié ; l'employer ailleurs recopie l'état pour rien.

**Résultat mesuré** (refaire les commandes de la §6) :

| | avant | après |
|---|---|---|
| `Plateau.allVisible` dans le provider classique | 12 | **3** |
| appels à `_rebuildPlateau` | 0 | **11** |

Les 3 `Plateau.allVisible` restants sont **corrects et doivent rester** : lignes 203
(`build`) et 809 (`reset`) construisent un plateau **vide** pour en compter les
solutions — ce n'est pas une reconstruction depuis `placedPieces` ; ligne 1389 est
l'intérieur du helper lui-même. Un critère de fin formulé « zéro `allVisible` » aurait
donc été faux : le bon critère est **zéro `allVisible` en dehors de `build`, `reset` et
du helper**.

**Deux équivalences vérifiées avant la substitution** — ce sont elles qui autorisent à
supprimer du code, et non seulement à le déplacer :

1. **`absoluteCells` ne renormalise pas.** Les 63 orientations de `pentominos.dart` ont
   déjà leur minimum en (0,0). Remplacer une boucle `(cellNum - 1) % 5` par
   `placed.absoluteCells` ne décale donc aucune pièce. *(Vérifié par calcul sur les 63
   orientations, cf. `docs/ANALYSE_STOCKAGE_POSITIONS.md`.)*
2. **`Plateau.setCell` teste déjà les bornes** (`if (isInBounds(x, y))`, `plateau.dart`
   l.66-70). Les gardes de bornes écrites à la main autour de chaque `setCell` dans les
   12 reconstructions étaient **redondantes**. C'est la raison pour laquelle elles ont
   disparu sans être remplacées — leur absence dans le code actuel n'est pas un oubli.

> ⚠️ Cette seconde équivalence a une conséquence qu'il faut avoir en tête : `setCell`
> **avale silencieusement** une écriture hors plateau. Une pièce hors bornes n'est pas
> signalée par la reconstruction ; c'est `_recomputeBoardValidity` qui s'en charge, et
> lui seul. Ne jamais compter sur `_rebuildPlateau` pour détecter quoi que ce soit.

**Correction d'une mesure du présent document.** La ligne « Boucles `(cellNum - 1) % 5`
recopiées | 19 | 13 » du tableau de la famille Sélection compare deux choses
différentes : 19 était un nombre de **lignes** côté classique, 13 un nombre de
**boucles** côté Pentoscope. Compté de la même façon des deux côtés, c'est aujourd'hui
**10 boucles côté classique** (20 lignes) contre **13 côté Pentoscope** (26 lignes). Le
rapport du CLI annonçant « 19 → 9 » n'est pas reproductible et ne doit pas être repris.

**Critères de vérification** — à relancer après toute reprise de ce temps 1 :

```bash
C=lib/classical/pentomino_game_provider.dart
grep -n 'Plateau.allVisible' $C      # attendu : 3 lignes (203 build, 809 reset, 1389 helper)
grep -c '_rebuildPlateau' $C         # attendu : 12 (1 définition + 11 appels)
grep -c 'cellNum - 1' $C             # attendu : 20 lignes = 10 boucles
```

> ⚠️ Piège d'outillage rencontré ici : un `grep '_rebuildPlateau([^)]*)'` **rate** les
> appels dont l'argument contient une parenthèse, par exemple
> `_rebuildPlateau(pieces: [...state.placedPieces, transformedPiece])`. Il a fait croire
> à une conversion incomplète (9 sur 10) là où elle était complète. Compter les
> occurrences du nom, pas les appels bien formés.

---

#### Sélection, temps 2 — basculer le mode classique sur *stay + mask*

**Plan établi le 2026-08-28 08:05, non appliqué.** À exécuter par le CLI. Le temps 1 ci-dessus est un
préalable strict : il est fait.

#### Ce qu'on change, en une phrase

Aujourd'hui, sélectionner une pièce posée la **retire** de `state.placedPieces` ; on
veut qu'elle y **reste**, et que seule la reconstruction du plateau l'ignore
(`exclude:`). Autrement dit : `placedPieces` devient la vérité complète de ce qui est
posé, à tout instant, y compris pendant une manipulation.

#### Les sites, exactement

**Trois « lift » à supprimer** — le code qui retire la pièce de la liste :

| ligne | méthode | code actuel | après |
|---|---|---|---|
| 968-970 | `selectPlacedPiece` | `state.placedPieces.where((p) => p != placedPiece).toList()` | supprimé, `placedPieces` inchangé |
| 927-938 | `selectPlacedPiece` (branche « une autre pièce était sélectionnée ») | ré-ajoute l'ancienne, reconstruit, remet l'état à plat | **tout le bloc `if` disparaît** |
| 873-878 | `selectPiece` (branche « une pièce du plateau était sélectionnée ») | ré-ajoute la pièce posée avant de sélectionner celle de la barre | **tout le bloc `if` disparaît**, remplacé par `plateau: _rebuildPlateau()` dans le `copyWith` final |

**Deux « restitutions » à réduire à une ligne :**

| ligne | méthode | après |
|---|---|---|
| 227-238 | `cancelSelection` | la branche `if (state.selectedPlacedPiece != null)` n'a plus qu'à poser `plateau: _rebuildPlateau()` ; les deux branches deviennent identiques à un champ près et fusionnent |
| 1160-1180 | `tryPlacePiece`, branche `wasPlacedPiece` | voir ci-dessous : c'est le site sensible |

**Le site sensible — `tryPlacePiece`, ligne 1153-1180.** Aujourd'hui la branche
`wasPlacedPiece` écrit explicitement `placedPieces: state.placedPieces` avec le
commentaire « ✅ Ne pas ajouter la pièce aux placées », parce que dans le modèle lift-out
la pièce n'y est pas et ne doit pas y revenir tant qu'elle est manipulée. Dans le
nouveau modèle elle **y est déjà**, à son **ancienne** position : il faut la
**remplacer**, pas l'ajouter. L'idiome de Pentoscope (l.769-773) est à reprendre tel
quel :

```dart
if (state.selectedPlacedPiece != null) {
  // déplacement : on remplace l'entrée existante
  newPlacedPieces = state.placedPieces
      .map((p) => p.piece.id == piece.id ? placedPiece : p)
      .toList();
  newAvailable = state.availablePieces;
} else {
  // nouvelle pièce venue de la barre
  newPlacedPieces = [...state.placedPieces, placedPiece];
  newAvailable = state.availablePieces.where((p) => p.id != piece.id).toList();
}
```

Le `..add(placedPiece)` de la ligne 1154 et le `..removeWhere(...)` de la ligne 1150
sont alors à faire migrer dans la seule branche `else`. **Oublier ce point produit un
doublon dans `placedPieces` à chaque déplacement d'une pièce posée** — c'est la
régression la plus probable de toute l'étape.

**Un site à corriger dans l'autre sens — `_computeSolutionsWithTransformedPiece`,
ligne 1401-1406.** Il écrit :

```dart
final tempPlateau = _rebuildPlateau(
  pieces: [...state.placedPieces, transformedPiece],
);
```

Ce `[...placedPieces, transformedPiece]` est une **compensation du lift-out** : il
remet à la main la pièce que la sélection avait retirée. Dans le nouveau modèle elle est
déjà dans la liste, à son ancienne orientation, et cette expression produirait un
plateau où la pièce figure **deux fois**. À remplacer par :

```dart
final tempPlateau = _rebuildPlateau(
  pieces: state.placedPieces
      .map((p) => p.piece.id == transformedPiece.piece.id ? transformedPiece : p)
      .toList(),
);
```

Même idiome que ci-dessus. Noter que le résultat n'est **pas** identique à l'actuel :
aujourd'hui l'ancienne empreinte est absente ; demain elle serait écrasée par la
nouvelle via `setCell`, ce qui est correct **si et seulement si** la nouvelle recouvre
l'ancienne — ce qui n'est pas garanti. D'où le `map`, et non un simple ajout.

#### Ce qui devient faux, et qu'il faut réparer dans le même commit

**La condition de victoire.** `pentomino_game_screen.dart` ligne 136 teste
`state.placedPieces.length == 12` dans le `build`. Sous lift-out, une pièce en cours de
manipulation ne compte pas — la victoire ne peut donc se déclencher que sélection
relâchée. Sous stay + mask elle compte, et le déclenchement avance.

Scénario concret de faux positif, reproductible à la main : douze pièces sur le plateau
mais la dernière mal posée (chevauchement ou hors bornes — le mode classique l'autorise,
c'est `_recomputeBoardValidity` qui le signale). L'utilisateur la reprend pour la
recaler et la repose au bon endroit. Sous lift-out, la ligne 1168 la laisse hors de
`placedPieces` : `length` vaut 11, rien ne se déclenche tant qu'il n'a pas désélectionné.
Sous stay + mask, le `map` la remet immédiatement : `length` vaut 12, **la victoire part
alors que la pièce est encore tenue et que le plateau affiche un trou à son
emplacement**.

Correction demandée : **ne plus déduire la complétion de `placedPieces.length` dans le
`build`**, mais poser un booléen `isComplete` dans l'état, écrit **uniquement dans
`tryPlacePiece`** au moment d'une pose valide, comme le fait Pentoscope (l.783-793).
C'est aussi ce qui rapprochera les deux états en vue de l'étape 3.

**Les lecteurs de `placedPieces` changent de sens.** Ils voient désormais la pièce
sélectionnée. Trois sont concernés :

- `findPlacedPieceAt` (l.565) et `getPlacedPieceAt` (l.585) : ils retourneront la pièce
  sélectionnée alors que le plateau est masqué à cet endroit. **Comportement voulu**
  côté Pentoscope, mais à vérifier au clic : un tap sur le trou laissé par la pièce
  reprise ne doit pas la re-sélectionner en boucle.
- `_recomputeBoardValidity` (l.1426) : **pas de faux chevauchement** — il compte les
  cellules par pièce et chaque cellule n'est visitée qu'une fois. En revanche la pièce
  tenue sera désormais évaluée pendant sa manipulation : ses cellules hors bornes, et
  ses recouvrements avec les autres, s'afficheront en direct au lieu d'apparaître à la
  pose. C'est un changement visible à l'écran. **À montrer à Paul avant de le corriger**
  — c'est peut-être un progrès.
- `applyHint` (l.284) : `placedPieceIds` inclura la pièce sélectionnée, donc l'indice ne
  proposera plus une pièce en cours de manipulation. **Amélioration**, pas régression.

**La persistance.** `enterIsometriesMode` (l.474) et `restoreState` (l.826) copient
`placedPieces`. Sous lift-out, sauvegarder pendant une sélection **perd** la pièce
sélectionnée si `selectedPlacedPiece` n'est pas restauré avec elle. Sous stay + mask le
problème disparaît de lui-même — le signaler comme bénéfice acquis, pas comme travail.

#### Piège d'égalité, à ne pas reproduire

`PlacedPiece` définit `operator ==` sur `(piece.id, positionIndex, gridX, gridY,
isometriesUsed)` (`lib/common/placed_piece.dart` l.89). Les lifts actuels s'en servent :
`where((p) => p != placedPiece)`. C'est fragile — il suffit qu'un appelant passe une
copie transformée pour que **rien** ne soit retiré, en silence. Le remplacement par
`map` sur `p.piece.id` supprime cette dépendance : **comparer par `piece.id`, jamais par
valeur de `PlacedPiece`**, puisqu'un identifiant de pentomino est unique sur le plateau.

#### Décisions de jeu à prendre avant de coder

Les trois divergences relevées le 2026-08-28 restent ouvertes. Elles ne sont **pas**
imposées par le changement de modèle ; les trancher ici évite un second passage :

1. Bloquer la sélection quand le puzzle est complet (Pentoscope le fait, le mode
   classique non). *Proposition : oui, cohérent avec le `isComplete` introduit
   ci-dessus.*
2. Re-sélectionner une pièce déjà sélectionnée doit-il conserver l'orientation courante
   (Pentoscope) ou relire `piecePositionIndices` (classique) ? *Proposition : conserver
   l'orientation courante — relire l'index annule silencieusement une isométrie que
   l'utilisateur vient d'appliquer.*
3. `cancelSelection` doit-il aussi nettoyer la preview ? *Proposition : oui — le mode
   classique peut aujourd'hui laisser une preview obsolète à l'écran.*

**Ces trois points sont pour Paul, pas pour le CLI.** Tant qu'ils ne sont pas tranchés,
appliquer l'étape à comportement constant et les traiter ensuite.

#### Ordre d'exécution imposé

1. Les 3 suppressions de lift + les 2 restitutions réduites.
2. `tryPlacePiece` : `map`/`add` selon la branche.
3. `_computeSolutionsWithTransformedPiece` : `map` au lieu de l'ajout.
4. `isComplete` dans l'état + `build` du screen.
5. `flutter analyze` — **0 warning attendu**, pas seulement 0 erreur.

Un seul commit pour 1-4 : séparer laisserait un état intermédiaire où `placedPieces`
contient des doublons.

#### Critères de fin, vérifiables

```bash
C=lib/classical/pentomino_game_provider.dart
grep -c '\.\.add(' $C                 # 8 → 3 attendus (applyHint, tutoriel, removePlacedPiece/undo sur availablePieces)
grep -n 'where((p) => p != placedPiece)' $C   # attendu : 1 seul, dans removePlacedPiece
grep -n 'placedPieces.length == 12' lib/classical/   # attendu : aucun résultat
```

Et, en test manuel du mode classique — c'est le seul juge :

- poser 3 pièces, en reprendre une, la déplacer : **3 pièces sur le plateau**, pas 4 ;
- reprendre une pièce puis toucher une autre pièce posée : la première revient à sa
  place, aucune ne disparaît ;
- reprendre une pièce puis sélectionner une pièce de la barre : idem ;
- reprendre une pièce puis appuyer sur Annuler : elle revient exactement où elle était ;
- reprendre une pièce puis appliquer une rotation puis reposer : compteur de solutions
  cohérent, aucune pièce en double ;
- compléter le puzzle : la victoire se déclenche **une fois**, et pas pendant un
  déplacement.

Le mode Pentoscope et le multijoueur ne sont pas touchés par cette étape — mais les
tester quand même, `PlacedPiece` étant partagé.

---

#### Sélection, temps 2 — bilan d'exécution et dettes ouvertes

**Appliqué par le CLI le 2026-08-28 10:19. Vérifié le 2026-08-28 18:14.**

Critères de fin du plan, relevés sur le code livré :

| critère | attendu au plan | mesuré | verdict |
|---|---|---|---|
| `where((p) => p != placedPiece)` | 1, dans `removePlacedPiece` | 1 (l.770) | ✅ |
| `placedPieces.length == 12` | aucun | aucun | ✅ |
| `..add(` | « 3 » | **4** (279, 731, 763, 1198) | ✅ — **le critère du plan était faux** |

Le quatrième `..add(` est ligne 731, dans `placeSelectedPieceForTutorial`. En établissant
le critère j'avais oublié cette méthode. Le code livré est correct ; c'est la mesure
attendue qui était sous-estimée.

**Correction au plan — `isComplete` ne pouvait pas se limiter à `tryPlacePiece`.** Le
plan écrivait « écrit **uniquement** dans `tryPlacePiece` ». Faux : `applyHint` pose une
pièce et peut poser la douzième. Sans écriture là, la victoire par indice disparaissait.
Le CLI l'a vu et posé `isComplete: newPlaced.length == 12` (l.301), avec remise à `false`
dans `removePlacedPiece` (l.784) et `undoLastPlacement` (l.1214). Correct.

`placeSelectedPieceForTutorial` est bien du code mort — aucun appelant. Attention
toutefois : le tutoriel dans son ensemble ne l'est pas.
`selectPlacedPieceWithMastercaseForTutorial` est appelée depuis
`lib/screens/demo_screen.dart:284`, qui enchaîne sélection → isométrie →
`tryPlacePiece` (l.267, 394). Cette séquence survit au nouveau modèle **parce qu'il y a
une pose derrière chaque rotation** — à confirmer en lançant la démo.

##### Décision de jeu, 2026-08-28 — la rotation non déposée est ABANDONNÉE

Tranché par Paul. **Comportement retenu : annuler annule.**

Sous *lift-out*, `selectedPlacedPiece` n'était pas une copie mais **la seule** instance :
la sélection l'avait retirée de `placedPieces`, et les trois sorties la réinjectaient via
`copyWith(positionIndex: state.selectedPositionIndex)`. Tourner une pièce puis taper
ailleurs **committait** la rotation, par construction.

Sous *stay + mask*, `selectedPlacedPiece` est une copie de travail posée à côté de
l'original, et les opérations d'isométrie n'écrivent **qu'elle** (`applyIsometry*` l.106
et suivantes, `cycleToNextOrientation` l.425-447). Il n'existe qu'un seul writeback,
`tryPlacePiece`, via son `map`. Les autres sorties jettent la copie.

| sortie | rotation |
|---|---|
| `tryPlacePiece` | committée (`map` sur `piece.id`) |
| `cancelSelection` | **abandonnée** |
| `selectPiece` / `selectPlacedPiece` (autre pièce) | **abandonnée** |

Conséquence acceptée : le recentrage de `_keepOnBoard` disparaît avec la rotation, une
pièce tournée près d'un bord ne conserve pas non plus son décalage. C'est cohérent — le
décalage n'existait que pour rendre cette rotation-là légale.

**Ce comportement aligne le mode classique sur Pentoscope**, qui n'écrit lui non plus que
`selectedPlacedPiece` (`pentoscope_provider.dart` l.1147, l.1396). C'est donc un pas vers
l'objectif d'unification, pas une divergence de plus.

**Ne pas re-synchroniser `placedPieces` dans les isométries.** Ce serait le correctif du
comportement inverse ; il est écarté. Si la question revient, c'est une décision de jeu à
rouvrir, pas un défaut à corriger.

##### Dette 1 — `solutionsCount` périmé après abandon d'une rotation (défaut)

**Ce n'est pas une préférence, c'est un état incohérent.** Les isométries écrivent
`solutionsCount` pour la pièce **tournée**. Puisque la rotation est désormais abandonnée
à la sortie, le compteur reste celui d'une orientation qui n'est plus sur le plateau.

Deux sites ne le recalculent pas :

- `cancelSelection` (l.217-233) — n'écrit pas `solutionsCount`.
- `selectPiece` (branche pièce du slider) — n'écrit pas `solutionsCount`.

`selectPlacedPiece` n'est **pas** concernée : elle appelle
`_computeSolutionsWithTransformedPiece` sur la pièce nouvellement sélectionnée, et
depuis le passage au `map` ce calcul part de `placedPieces`, donc de l'orientation
réellement posée.

Correctif : dans les deux sites, recalculer depuis le plateau reconstruit.

```dart
// cancelSelection
final wasPlaced = state.selectedPlacedPiece != null;
final newPlateau = wasPlaced ? _rebuildPlateau() : state.plateau;
state = state.copyWith(
  plateau: newPlateau,
  solutionsCount: wasPlaced ? newPlateau.countPossibleSolutions() : state.solutionsCount,
  clearSelectedPiece: true,
  clearSelectedPlacedPiece: true,
  clearSelectedCellInPiece: true,
);
```

Même forme dans `selectPiece`, où `plateau: _rebuildPlateau()` est déjà écrit : garder le
plateau reconstruit dans une variable locale et en tirer le compteur, plutôt que de le
reconstruire deux fois.

##### Dette 2 — `isComplete` n'a pas de chemin de retour vers `true`

`tryPlacePiece`, branche `wasPlacedPiece`, force `isComplete: false` (l.1133, commentaire
« pièce encore tenue : plateau incomplet »). C'est juste : le plateau affiche un trou.
Mais `cancelSelection` **n'écrit jamais `isComplete`**. Sur un plateau complet, reprendre
une pièce et la reposer met le drapeau à `false` **définitivement** : douze pièces dans
`placedPieces`, plateau plein, état qui dit le contraire.

**Latent, pas vivant** — `_completionProcessed` verrouille l'écran après le premier
déclenchement. Mais ce drapeau est remis à `false` en quatre endroits de
`pentomino_game_screen.dart` (l.207, 389, 399, 410), et `isComplete` est destiné à servir
au-delà de ce seul test dans l'étape 3.

Correctif, dans le même `copyWith` que la dette 1 :

```dart
isComplete: wasPlaced && state.placedPieces.length == 12 && state.boardIsValid,
```

Le `boardIsValid` est nécessaire : les isométries ne vérifient que les bornes
(`_keepOnBoard`), jamais les chevauchements. Douze pièces posées ne valent pas
puzzle résolu.

##### Ce qui reste à faire

1. Les deux dettes ci-dessus, **un seul commit** — elles touchent le même `copyWith`.
2. Le test manuel du mode classique (liste des critères de fin, plus haut), plus le
   passage de la démo `demo_screen.dart`.
3. `flutter pub add collection` — lint `depend_on_referenced_packages` préexistant.


---

Garder **Placement** pour la fin — `tryPlacePiece` fait 178 lignes
côté classical contre 91 côté pentoscope, c'est là qu'est la vraie réconciliation.

- **Critère de fin, par famille** : la méthode n'existe plus que dans le mixin, les deux
  modules se comportent à l'identique.
- **Risque** : moyen et croissant selon la famille. Test manuel des deux modes après
  chaque famille.

### Étape 4 — sortir la logique de `pentoscope_board.dart`

Déplacer `placeSelectedPiece`, `selectPieceOnBoard`, `highlightCell`,
`_showVictoryDialog` et consorts vers `PentoscopeNotifier`, pour que les deux plateaux
aient la même répartition des responsabilités : le widget affiche, le provider décide.

- **Critère de fin** : `pentoscope_board.dart` ne contient plus que du rendu et des
  callbacks. Son volume devrait se rapprocher des 529 lignes de `game_board.dart`.
- **Bénéfice propre, indépendant de la fusion** : Pentoscope devient testable sans monter
  d'arbre Flutter.
- **Peut se faire en parallèle de l'étape 3.**

### Étape 5 — plateau et barre uniques, paramétrés

Un seul `GameBoard` et un seul `PieceSlider`, recevant dimensions, pièces posées,
sélection et callbacks **en arguments** — jamais un provider lu en dur. Chaque module les
alimente depuis son propre provider.

- **Critère de fin** : `pentoscope_board.dart` et `pentoscope_piece_slider.dart`
  supprimés, les trois modules montent les mêmes widgets.
- **Préalable strict** : étapes 1 à 4. Toute tentative avant est prématurée.

---

## 5. Pièges connus

**`PlacedPiece.getOccupiedCells()`** a les bornes du plateau 6×10 écrites en dur. Depuis
que la classe est partagée, Pentoscope y a accès et obtiendrait un résultat faux, sans
erreur, sur un plateau de largeur ≠ 6. Un avertissement est en place dans la doc de la
méthode. Utiliser `absoluteCells`, qui ne présume rien des dimensions.

**Le nommage des isométries.** Dans `pentominos.dart`, les méthodes publiques appellent
des helpers privés au nom **opposé** (`rotationCW` → `_rotate90TWCoords`, `symmetryH` →
`_flipVCoords`). L'inversion compense le repère écran, mais elle a déjà produit deux
tables de documentation contradictoires. Se fier aux noms publics, jamais aux privés.

**Le multijoueur suit sans le savoir.** Il ne nomme jamais les types de Pentoscope, il
consomme `PentoscopeState`. Les étapes 1 à 3 lui sont transparentes — mais il doit être
testé après chaque famille de l'étape 3, puisqu'il partage le provider modifié.

**Le tutoriel est asymétrique.** `placeSelectedPieceForTutorial` fait 69 lignes côté
classical contre 14 côté pentoscope. Ce n'est probablement pas la même fonctionnalité :
à traiter à part, pas dans une famille de l'étape 3.

---

## 6. Reproduire les mesures

```bash
# noms de méthodes communs aux deux providers
# (extraire les méthodes du corps de chaque classe Notifier, puis comm -12)

# champs communs aux deux états
grep -n "final .*;" lib/classical/pentomino_game_state.dart
grep -n "final .*;" lib/pentoscope/pentoscope_provider.dart
```

> ⚠️ Attention en refaisant la mesure des champs : un formateur a coupé quatre
> déclarations de `PentominoGameState` sur deux lignes (`final Pento?` puis
> `selectedPiece;`). Une regex sur une seule ligne les rate et sous-estime le noyau
> commun de 4 champs — l'erreur a été commise en établissant ce document.

---

## Voir aussi

- `docs/FONCTIONNEMENT.md` — documentation fonctionnelle vérifiée
- `docs/PLAN_SUPPRESSION_DEMO.md` — suppression de la démo automatique et de la
  machinerie de tutoriel ; allège les étapes 4 et 5
- `docs/PENTOSCOPE.md` — le module dont la logique est à extraire (étape 4)
