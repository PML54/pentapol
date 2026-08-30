# Plan — le bilan de fin de partie

> Établi le 2026-08-30 par cowork, sur constat de Paul : « le message récapitulatif en fin
> de puzzle masque le puzzle. À mon avis trop détaillé. »
>
> Décidé : **bandeau non modal** (décision 42) et **suppression du score** (décision 43).
> Numéros de ligne relevés sur `pentoscope_game_screen.dart` après `fe3c331`.

---

## 1. Trois problèmes, pas un

**a) Le masquage est structurel.** `_showCompletionDialog` (l.944) est un `AlertDialog`
modal, centré, `barrierDismissible: false`. Il s'ouvre au centre au moment précis où le
joueur veut voir le plateau qu'il vient de compléter. **Alléger son contenu n'y change
rien** — même à deux lignes, un dialogue centré couvre le centre.

**b) Le détail est long** : quatre à six lignes selon la partie — Temps, Isométries,
Déplacements, puis Suppressions et Indices s'ils sont non nuls, puis Score.

**c) Le score est faux, deux fois** (décision 41) :

```dart
scorePercent = (minIsometries + numPieces) / (isometryCount + translationCount + deleteCount) × 100
```

- **rapport non homogène** : `numPieces` compte une pose par pièce au numérateur, mais le
  dénominateur n'en compte aucune — `translationCount` ne s'incrémente que sur le
  déplacement d'une pièce **déjà posée** (`tryPlacePiece` l.796-798) ;
- **`minIsometries` vaut toujours 0 sur le 6×10** : il n'est calculé que
  `if (puzzle.solutions.isNotEmpty)` (l.596-611) et `_buildFullRectanglePuzzle` laisse cette
  liste délibérément vide. Le numérateur se réduit à 12 : il faudrait finir un 6×10 en 15
  actions pour atteindre 80 %. **Le score y est rouge en toutes circonstances.**

C'est (c) qui commande l'ordre : la ligne la plus visible du bilan est celle qui est fausse.
Alléger sans corriger reviendrait à ne garder que le mauvais chiffre.

---

## 2. Ce qui remplace le dialogue

**Un bandeau, à la place de la barre de pièces.** Au moment de la complétion,
`availablePieces` est vide : **la barre n'a plus rien à montrer**. Le bandeau prend sa
place, à surface d'écran constante, et le plateau reste entièrement visible.

Deux emplacements à traiter, un par orientation :

| orientation | site actuel | structure |
|---|---|---|
| portrait | l.776-796 | `Column` : `Expanded(flex: 3, PentoscopeBoard)` puis le conteneur qui reçoit `sliderChild` |
| paysage | l.820-933 | `Row` : `Expanded(PentoscopeBoard)` puis la colonne qui reçoit `sliderChild` |

Dans les deux cas : `state.isComplete ? const _BilanBanner() : const PentoscopePieceSlider(...)`.

**Contenu**, une seule ligne de puces `icône + valeur`, sans libellés :

```
⏱ 04:12   ↻ 23   ✥ 7   [🗑 2]   [💡 1]        [Fermer]  [Nouvelle partie]
```

Suppressions et Indices restent conditionnés à `> 0`, comme aujourd'hui. **Sans le score,
il n'y a plus besoin d'un bouton « Détail »** : tout tient sur une ligne.

**Ce que ça simplifie.** Le `ref.listen` de la l.90-95 et sa garde « afficher une seule
fois » (`next.isComplete && !prev.isComplete`) **disparaissent** : un widget déclaratif
piloté par `state.isComplete` n'a pas besoin de savoir s'il a déjà été montré.

**Ce que ça ajoute.** Un `bool _bilanFerme` local à l'écran, remis à `false` au démarrage
d'une partie — c'est le seul état neuf, et il est nécessaire parce que « Fermer » doit
pouvoir masquer le bandeau alors que `isComplete` reste vrai.

---

## 3. Le score : retiré, et ce que ça entraîne

Retirer la ligne `Score` **et** le calcul qui la précède (l.950-961 : `minTotal`,
`realTotal`, `scorePercent`, `scoreColor`).

`state.minIsometries` n'a alors **plus aucun lecteur** — vérifié : son unique consommateur
hors du provider est la l.951. Sont à retirer avec lui :

- le champ `minIsometries` de `PentoscopeState` (l.1869) et sa plomberie `copyWith` ;
- son calcul dans `startPuzzle` (l.596-611) **et** dans `startPuzzleFromSeed` (l.664-676) —
  deux boucles sur toutes les solutions du puzzle × tous ses placements ;
- `Pento.minIsometriesToReach` (`common/pentominos.dart` l.773) devient orphelin. **Le
  garder** : c'est une primitive juste et non triviale, et le scoring isométrique du
  multijoueur pourrait la reprendre. La signaler comme orpheline, pas la supprimer.

> **Effet de bord favorable, à ne pas surinterpréter.** La boucle `minIsometries` était
> l'argument principal du §4.5 du plan 6×10 (« ne PAS remplir `puzzle.solutions` » :
> 9356 × 12 appels au démarrage). Elle disparaît. Les deux autres raisons subsistent —
> duplication en mémoire des 9356, déjà détenues en BigInt par le matcher, et conversion
> `BigInt` → `Solution` pour chacune. **La règle du §4.5 reste donc valable**, avec un
> argument de moins.

> ⚠️ Si Paul veut un jour retrouver une note de fin de partie, ce n'est pas la formule
> actuelle qu'il faudra rétablir : il faudra un numérateur qui ait un sens sur un rectangle
> complet — par exemple le minimum d'isométries calculé sur la **seule** solution atteinte,
> obtenue par `SolutionMatcher.findSolutionIndex`, et non sur les 9356.

---

## 4. Ordre et critères de fin

0. **Corriger le chronomètre** (§5) — commit seul, **en premier**.
1. **Retirer le score et `minIsometries`** — commit seul. Le dialogue existe encore, il
   perd sa dernière ligne.
2. **Remplacer le dialogue par le bandeau** — commit seul.

Séparer les deux permet d'attribuer une régression à l'un ou à l'autre : la première touche
le provider et l'état, la seconde uniquement la mise en page.

```bash
G=lib/pentoscope/screens/pentoscope_game_screen.dart
grep -n 'minIsometries' lib/                    # attendu : uniquement pentominos.dart
grep -n 'scorePercent\|scoreColor\|_showCompletionDialog' $G   # attendu : aucun
grep -n 'ref.listen' $G                         # attendu : aucun
```

`flutter analyze` : **0 warning** — et vérifier au `grep`, pas seulement à l'analyseur :
`minIsometries` est un champ **public**, son absence d'appelant ne serait pas signalée.

Test appareil :

- terminer un puzzle : **le plateau complété reste entièrement visible**, le bandeau occupe
  la place de la barre de pièces ;
- « Fermer » masque le bandeau et laisse le plateau ; « Nouvelle partie » relance ;
- terminer un 6×10 : plus de pourcentage rouge ;
- portrait **et** paysage ;
- le multijoueur n'est pas touché (écran distinct) — mais le tester, il partage le provider.

---

## 5. Le chronomètre ne s'arrête pas — deux défauts

> Signalé par Paul le 2026-08-30 : « quand le puzzle est complet le temps continue ».
> Diagnostiqué dans `pentoscope_provider.dart`. **Deux défauts distincts**, dont le second
> est masqué par le premier — corriger l'un sans l'autre rendrait l'autre visible.

### 5.1 Défaut A — le chrono est relancé juste après avoir été arrêté

`tryPlacePiece` arrête le chrono à la complétion (l.771-776) :

```dart
if (isComplete) {
  stopTimer();
  _saveCompletedLevel();
}
```

…puis, **vingt-cinq lignes plus bas, après le `copyWith`** (l.799-801) :

```dart
// ⏱️ Démarrer le timer au premier placement depuis le slider
if (!isTimerRunning && !wasPlacedPiece) {
  startTimer();
}
```

À la pose de la **dernière** pièce depuis la barre : `wasPlacedPiece` est faux, et
`isTimerRunning` vient de passer à faux **parce qu'on vient de l'arrêter**. La garde est
donc satisfaite et le chrono **repart immédiatement**. C'est exactement le symptôme.

> Le bug ne se voit pas quand on termine en **déplaçant** une pièce déjà posée :
> `wasPlacedPiece` est alors vrai et la relance n'a pas lieu. Il ne se manifeste donc que
> dans le cas normal — finir en posant une pièce de la barre.
>
> `applyHint` (l.267-270) n'a **pas** ce défaut : il arrête le chrono et ne le relance
> jamais. Finir par un indice arrête donc correctement le temps.

**Correctif** — exclure la complétion de la garde de démarrage :

```dart
if (!isComplete && !isTimerRunning && !wasPlacedPiece) {
  startTimer();
}
```

Préférer la garde au déplacement du bloc `stopTimer()` : elle dit l'intention (« on ne
démarre pas un chrono sur une partie finie ») au lieu de dépendre d'un ordre de lignes.

### 5.2 Défaut B — `resetTimer()` n'est appelé nulle part

Vérifié : `grep -rn "resetTimer" lib/` ne trouve que sa **déclaration** et sa
**documentation** dans `common/game_timer_mixin.dart`. Aucun appelant.

Or le mixin distingue explicitement deux intentions :

| Méthode | Effet | Reprise après |
|---|---|---|
| `stopTimer()` | arrête le tic, **conserve** l'origine | reprend là où on s'était arrêté |
| `resetTimer()` | arrête le tic et **efface** l'origine | repart de zéro |

Les trois sites qui **démarrent une partie neuve** appellent `stopTimer()` :

| ligne | méthode | commentaire du code |
|---|---|---|
| 437 | `reset()` | « ⏱️ **Reset** sans démarrer le timer » — le commentaire dit reset, l'appel dit stop |
| 604 | `startPuzzle` | |
| 652 | `startPuzzleFromSeed` | |

`_startTime` n'est donc **jamais effacé de toute la vie de l'application**. Au premier
placement de la partie suivante, `startTimer()` exécute `_startTime ??= DateTime.now()` :
l'origine de la **toute première** partie est réutilisée. L'état neuf affiche `0`, puis le
premier tic écrit le temps écoulé depuis le lancement de l'app.

**Correctif** : `resetTimer()` aux lignes 437, 604 et 652. Les deux sites de **fin** de
partie — `applyHint` l.269 et `tryPlacePiece` l.773 — gardent `stopTimer()`, qui est le bon
appel : la partie est finie, l'origine doit rester lisible pour `_saveCompletedLevel`. Le
`ref.onDispose` l.157-159 garde `stopTimer()` également.

> **Ironie à consigner.** `resetTimer()` a été créée **exactement pour ce cas**, lors de
> l'unification (famille Chrono) : la séparation stop/reset répondait à deux `startTimer`
> aux gardes incompatibles. La méthode a été écrite, documentée… et jamais branchée. C'est
> le cas d'école de l'avertissement de `CLAUDE.md` : **`flutter analyze` ne signale pas une
> méthode publique sans appelant.**

> Le multijoueur n'est pas concerné : `pentoscope_mp_provider.dart` a son propre chrono, avec
> son propre `_startTime` qu'il réaffecte à chaque démarrage (l.603, l.621).

### 5.3 Ordre et critères de fin

**Ces deux correctifs passent AVANT le reste de ce plan** : le bandeau affiche le temps, il
vaut mieux qu'il affiche le bon. Un seul commit — les deux défauts touchent le même sujet et
se masquent l'un l'autre, les séparer laisserait un état intermédiaire trompeur.

```bash
P=lib/pentoscope/pentoscope_provider.dart
grep -n 'resetTimer' $P          # attendu : 3 (reset, startPuzzle, startPuzzleFromSeed)
grep -n 'stopTimer' $P           # attendu : 3 (onDispose, applyHint, tryPlacePiece)
grep -n 'isComplete && !isTimerRunning' $P   # attendu : 1
```

Test appareil :

- terminer un puzzle en posant la dernière pièce **depuis la barre** : le temps **se fige** ;
- terminer un puzzle **en déplaçant** une pièce déjà posée : idem (cas déjà correct) ;
- terminer par un **indice** : idem ;
- enchaîner deux parties : la seconde repart bien de **00:00**, pas du temps cumulé ;
- « Nouvelle partie » depuis le bandeau, et changement de taille : même vérification.

---

## Voir aussi

- `docs/JOURNAL.md` — décisions 41 (le défaut de score), 42 (le bandeau), 43 (le retrait)
- `docs/PLAN_6X10_DANS_PENTOSCOPE.md` §4.5 — pourquoi `puzzle.solutions` reste vide
