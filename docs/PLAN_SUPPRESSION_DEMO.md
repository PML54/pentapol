# Plan — supprimer la démo automatique et la machinerie de tutoriel

> 🗄️ **ARCHIVE — plan exécuté le 2026-08-28, conservé pour l'histoire.** Les chemins
> `lib/classical/…`, `lib/screens/demo_screen.dart` et
> `lib/screens/pentomino_game/…` qu'il cite n'existent plus : le module classique a été
> supprimé le 2026-08-29. **Ne pas les « corriger »** — un plan exécuté décrit l'état
> d'alors, c'est ce qui lui donne sa valeur.

> Établi le 2026-08-28 18:14. Décidé par Paul : la démonstration automatique ne lui
> plaît pas, elle disparaît, avec toute l'infrastructure de tutoriel qui la sert et les
> deux « modes » qui n'ont jamais été branchés.
>
> Périmètre retenu : **A + B + C + D** (les quatre couches ci-dessous). C'est le seul
> périmètre qui ne laisse pas de branches orphelines dans `game_board.dart` et
> `pentomino_game_screen.dart`.
>
> Toutes les mesures ont été relevées sur les sources le 2026-08-28. La méthode de
> vérification est donnée en §5.

---

## 1. De quoi on parle, exactement

Le mot « tutoriel » recouvre **deux choses distinctes**, et il n'y a jamais eu de
tutoriel interactif dans ce projet.

**Une démonstration automatique** — `lib/screens/demo_screen.dart`, 696 lignes : une
liste de `DemoStep` déroulée par un `Timer`, qui pilote le provider du mode **classique**
et commente à l'écran. C'est ce que l'utilisateur voit.

**Un « mode tutoriel » côté état** — `isInTutorial`, `enterTutorialMode`,
`exitTutorialMode`, `savedGameState` — qui **n'a jamais d'appelant**. Ni la démo ni
l'interface n'y entrent. Le commentaire de `restoreState` (l.813) mentionne un
`TutorialProvider` **qui n'existe pas dans le dépôt**.

S'y ajoute un troisième mort de la même famille, découvert au passage : le **mode
isométries** (`isIsometriesMode`, `enterIsometriesMode`, `exitIsometriesMode`). Personne
n'y entre non plus, alors que `game_board.dart` teste `state.isIsometriesMode` à quatre
endroits — quatre branches d'affichage qui ne s'exécutent jamais.

**Point d'entrée anormal, à noter avant qu'il disparaisse** : les deux boutons qui
lancent la démo du mode **classique** sont dans l'écran **Pentoscope**
(`lib/pentoscope/screens/pentoscope_game_screen.dart`, l.204-217 et l.849-863). Le mode
classique n'a aucun bouton vers sa propre démo.

---

## 2. Inventaire exhaustif

### Couche A — la démo (vivante)

| fichier | quoi |
|---|---|
| `lib/screens/demo_screen.dart` | **fichier entier**, 696 lignes (`DemoScreen`, `_DemoScreenState`, `DemoStep`, `DemoAction`) |
| `lib/pentoscope/screens/pentoscope_game_screen.dart` | l.21 `import ... demo_screen.dart` ; l.204-217 `IconButton` « Démo automatique » ; l.849-863 le second, en disposition paysage |

### Couche B — l'API `*ForTutorial` (une seule vivante)

`lib/classical/pentomino_game_provider.dart` :

| ligne | méthode | appelant |
|---|---|---|
| 694 | `placeSelectedPieceForTutorial` | **aucun** |
| 883 | `selectPieceFromSliderForTutorial` | **aucun** |
| 954 | `selectPlacedPieceAtForTutorial` | **aucun** |
| 969 | `selectPlacedPieceWithMastercaseForTutorial` | `demo_screen.dart:284` — le seul |

`lib/pentoscope/pentoscope_provider.dart`, bloc l.1812-1884, en entier :
`selectPieceFromSliderForTutorial`, `highlightPieceInSlider`, `clearSliderHighlight`,
`scrollSliderToPiece`, `placeSelectedPieceForTutorial`, `selectPlacedPieceAt`,
`rotateAroundMasterForTutorial`. **Aucun appelant.** `rotateAroundMasterForTutorial` ne
fait même qu'un `print` — elle n'a jamais été implémentée.

### Couche C — la machinerie de surlignage

**Provider classique**, 12 méthodes : `highlightCell` (593), `highlightCells` (606),
`highlightIsometryIcon` (621), `highlightMastercase` (632), `highlightPieceInSlider`
(638), `highlightPieceOnBoard` (648), `highlightValidPositions` (664),
`clearBoardHighlight` (364), `clearCellHighlights` (370), `clearIsometryIconHighlight`
(376), `clearMastercaseHighlight` (389), `clearSliderHighlight` (397).

Seuls écrivains réels aujourd'hui : `demo_screen.dart` l.319 et l.324. Une fois la
couche A partie, **toutes** ces méthodes sont sans appelant.

**État classique** (`pentomino_game_state.dart`), 5 champs et leur plomberie
`copyWith` : `highlightedSliderPiece`, `highlightedBoardPiece`, `highlightedMastercase`,
`cellHighlights`, `highlightedIsometryIcon` — plus les 5 drapeaux `clearXxx` du
`copyWith` et les initialisations dans le constructeur et `initial()`.

**Lecteurs qui meurent avec eux :**

| fichier | ligne | quoi |
|---|---|---|
| `lib/classical/pentomino_game_screen.dart` | 596-651 | 4 × `HighlightedIconButton(isHighlighted: state.highlightedIsometryIcon == …)` |
| `lib/screens/pentomino_game/widgets/shared/game_board.dart` | 342-344 | `state.cellHighlights[highlightPoint]` |
| `lib/screens/pentomino_game/widgets/shared/highlighted_icon_button.dart` | fichier entier | wrapper d'animation, plus aucune source à `true` |

**Surlignage local aux widgets Pentoscope**, indépendant de l'état, mort de la même
manière :

| fichier | quoi |
|---|---|
| `lib/pentoscope/widgets/pentoscope_board.dart` | champ `_highlightedCells` (l.32) ; méthodes `highlightCell` (35), `clearHighlights` (44), `placeSelectedPiece` (50, ne fait qu'un `print`), `selectPieceOnBoard` (56) ; le bloc lecteur l.410-425 |
| `lib/pentoscope/widgets/pentoscope_piece_slider.dart` | champ `_highlightedIndex` (l.36) ; `highlightPiece` (39), `clearHighlight` (45), `scrollToPiece` (51) ; le lecteur l.99-102 |

### Couche D — les « modes » (déjà morts aujourd'hui)

`lib/classical/pentomino_game_provider.dart` : `enterIsometriesMode` (454),
`exitIsometriesMode` (502), `enterTutorialMode` (~478), `exitTutorialMode` (516),
`restoreState` (813). **Aucun appelant, aucun.**

`lib/classical/pentomino_game_state.dart` : `isIsometriesMode`, `isInTutorial`,
`savedGameState` — ce dernier est un champ **auto-référent** (`PentominoGameState?`) : sa
suppression touche le constructeur, `initial()` et `copyWith` (y compris le drapeau
`clearSavedGameState`).

`lib/screens/pentomino_game/widgets/shared/game_board.dart` : 4 branches sur
`state.isIsometriesMode` (l.221, 236, 314, 507) qui ne s'exécutent jamais.

---

## 3. Mode opératoire

**Deux commits, dans cet ordre. Ne pas les fusionner** : le premier retire une
fonctionnalité visible, le second du code déjà mort. Les mêler rendrait toute régression
inattribuable.

### Commit 1 — la démo et son API (couches A + B)

1. Supprimer `lib/screens/demo_screen.dart`.
2. Dans `pentoscope_game_screen.dart` : retirer l'import l.21 et les **deux** `IconButton`
   « Démo automatique » **en entier** (l.204-217 et l.849-863), pas seulement le
   `Navigator.push`.
3. Supprimer les 4 méthodes `*ForTutorial` du provider classique et le bloc l.1812-1884
   du provider Pentoscope.
4. `flutter analyze` — 0 warning.

### Commit 2 — surlignage et modes morts (couches C + D)

Ordre imposé : **écrivains d'abord, lecteurs ensuite**. Supprimer un lecteur avant son
écrivain fait disparaître la preuve que la branche était morte.

1. Les 12 méthodes de surlignage du provider classique.
2. Les 5 champs de surlignage de `PentominoGameState` + leurs `clearXxx` dans `copyWith`.
3. Les lecteurs : les 4 `HighlightedIconButton` de `pentomino_game_screen.dart`, le bloc
   `cellHighlights` de `game_board.dart` (l.342-344), le fichier
   `highlighted_icon_button.dart`.
4. Le surlignage local des widgets Pentoscope (board et slider), champs et lecteurs.
5. Couche D : les 5 méthodes de modes, les 3 champs d'état, les 4 branches
   `isIsometriesMode` de `game_board.dart`.
6. `flutter analyze` — 0 warning.

---

## 4. Pièges

**`flutter analyze` ne vous aidera pas.** Toutes ces méthodes sont **publiques** : une
méthode publique sans appelant n'est jamais signalée. L'analyseur restera à 0 warning
même s'il en reste la moitié. **La vérification est au grep, pas à l'analyseur** — c'est
exactement l'erreur déjà commise sur le triple chrono (cf.
`docs/PLAN_UNIFICATION_PIECES.md`, étape 3, famille Chrono).

**Retirer `HighlightedIconButton` est visuellement neutre — c'est démontré.** Son `build`
commence par :

```dart
if (!widget.isHighlighted) {
  return widget.child;
}
```

`isHighlighted` étant désormais toujours `false`, remplacer
`HighlightedIconButton(isHighlighted: …, child: X)` par `X` rend **exactement** le même
arbre de widgets. Bénéfice au passage : le widget crée un `AnimationController` en
`repeat(reverse: true)` dès `initState`, surligné ou non — quatre animations tournaient
en permanence pour rien derrière la barre d'isométries.

**Les méthodes d'état des widgets Pentoscope ne sont pas appelables.** `highlightCell`,
`clearHighlights`, `highlightPiece`… sont des méthodes de `State` : elles ne seraient
atteignables que par une `GlobalKey`. Il n'y a **aucun `GlobalKey<…>` dans tout `lib/`**
(vérifié). Elles sont donc inatteignables, pas seulement inutilisées.

**Ne pas confondre les variantes.** Seules les méthodes suffixées `ForTutorial` partent.
`selectPlacedPiece`, `selectPiece`, `tryPlacePiece`, `scrollSlider` sont le cœur du jeu et
restent. Attention en particulier à `scrollSliderToPiece` : il en existe une version
Pentoscope dans le bloc tutoriel (l.1843) **et** une version classique appelée par le jeu.

**`savedGameState` est auto-référent.** Sa suppression n'est pas un simple retrait de
ligne : constructeur, `initial()`, paramètre de `copyWith`, drapeau `clearSavedGameState`
et la ligne ternaire correspondante.

**On perd un révélateur.** La démo était le seul consommateur vivant de l'enchaînement
sélection → isométrie → pose. Après sa suppression, ce scénario n'est plus couvert que
par le test manuel. C'est le prix de la suppression, accepté ; le noter pour ne pas s'en
étonner plus tard.

**Ce qui reste et qui n'a rien à voir.** `lib/pentoscope/widgets/pentoscope_board.dart`
lit `state.isSnapped` sans que personne ne l'écrive (branche de preview cyan morte) :
défaut connu, à traiter avec la famille Placement, **pas ici**.

---

## 5. Critères de fin

```bash
grep -ril "tutorial\|tutoriel" lib/     # attendu : rien, hors reformulation du
                                        # commentaire de common/piece_manipulation_state.dart l.16
grep -rn "DemoScreen\|demo_screen" lib/ # attendu : rien
grep -rn "ForTutorial" lib/             # attendu : rien
grep -rni "highlight" lib/              # attendu : rien dans classical/ ni dans les
                                        # widgets partagés ; rien dans pentoscope/widgets/
grep -rn "isInTutorial\|isIsometriesMode\|savedGameState\|restoreState" lib/   # attendu : rien
flutter analyze                         # 0 warning — nécessaire, pas suffisant (cf. §4)
```

Test manuel, après le commit 2 :

- le mode classique se lance, se joue, la barre d'isométries fonctionne et **s'affiche
  comme avant** (c'est le seul endroit où une différence visuelle serait possible) ;
- Pentoscope se lance et se joue, la barre d'outils n'a plus le bouton teal « Démo
  automatique », en portrait **et** en paysage ;
- le multijoueur se lance ;
- aucune trace `[TUTORIAL]` ni `[BOARD] Placement simulé` dans la console.

---

## Voir aussi

- `docs/PLAN_UNIFICATION_PIECES.md` — cette suppression allège les étapes 4 et 5
  (`game_board.dart`, `pentomino_game_screen.dart`, widgets Pentoscope)
- `docs/FONCTIONNEMENT.md` — vérifié le 2026-08-28 : il ne mentionne ni la démo ni le
  tutoriel, rien à y corriger
