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

## Voir aussi

- `docs/JOURNAL.md` — décisions 41 (le défaut de score), 42 (le bandeau), 43 (le retrait)
- `docs/PLAN_6X10_DANS_PENTOSCOPE.md` §4.5 — pourquoi `puzzle.solutions` reste vide
