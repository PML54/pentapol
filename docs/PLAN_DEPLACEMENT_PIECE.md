# Plan — déplacement d'une pièce sur le plateau, et mastercase

> Ouvert le 2026-09-01 sur signalement de Paul : « j'ai du mal à déplacer horizontalement la
> pièce en bas ; de temps en temps elle va une case vers le haut ».
>
> **Les deux captures fournies ne documentent pas le saut** : elles montrent le même état à deux
> échelles légèrement différentes. Le diagnostic ci-dessous vient donc de la lecture du code, pas
> de l'observation. Ce qui est marqué *fait* est établi par le code ; ce qui est marqué
> *hypothèse* demande une mesure.

## 1. Comment un déplacement fonctionne aujourd'hui

1. **Sélection.** Un tap sur une case occupée appelle `selectPlacedPiece(placed, x, y)`
   (`pentoscope_provider.dart` l.538). Il retire la pièce du plateau, mémorise
   `selectedCellInPiece` (coordonnée **locale** de la case tapée = la *mastercase*) et
   `selectedMasterAbs` (la même case en coordonnée **absolue**), puis engendre `validPlacements`.
2. **Rendu.** La mastercase reçoit une bordure rouge de 4 px (`pentoscope_board.dart`, branche
   `isReferenceCell` de `_calculateBorder`). **Chaque case de la pièce sélectionnée est un
   `Draggable<Pento>` distinct** (l.420).
3. **Glissé.** Le plateau entier est un `DragTarget<Pento>` ; `onMove` (l.93) convertit
   `details.offset` en coordonnées plateau, en déduit une case par `floor(p / cellSize)`, et
   appelle `updatePreview(logicalX, logicalY)`.
4. **Aimantation.** `updatePreview` (l.1014) calcule l'ancre désirée par
   `_calculateDesiredAnchorFromDrag` puis retient, dans `validPlacements`, **le placement le plus
   proche** (`_findClosestValidPlacement`, l.1852). `previewX/previewY` est donc une **ancre**,
   mastercase déjà absorbée.
5. **Dépôt.** `onAcceptWithDetails` **reconstruit une fausse position de doigt**
   (`previewX + selectedCellInPiece`) et appelle `tryPlacePiece`, qui re-dérive l'ancre par
   `_calculateDesiredAnchorFromDrag`.

## 2. Deux mécanismes indépendants produisent le saut d'une case

### (a) `details.offset` n'est pas le doigt — *fait*

Dans Flutter, `DragTargetDetails.offset` vaut `positionGlobaleDuDoigt − dragStartPoint`, où
`dragStartPoint` est fourni par le `dragAnchorStrategy`. Par défaut
(`childDragAnchorStrategy`), c'est **la position du doigt à l'intérieur de l'enfant, au début du
glissé**. Ici l'enfant est **une case du plateau** : `dragStartPoint ∈ [0, cellSize)².`

Donc la case calculée en `onMove` est décalée de 0 ou 1 case dans chaque axe, et le décalage est
**fixé pour tout le glissé par l'endroit où le doigt s'est posé dans la case** :

- appui près du **bas** de la case ⟹ `dragStartPoint.dy ≈ cellSize` ⟹ ligne rapportée =
  ligne du doigt **− 1** ⟹ **la pièce est une case au-dessus du doigt pendant tout le glissé** ;
- appui près du **haut** ⟹ aucun décalage.

C'est exactement le symptôme décrit, et cela vaut aussi en X — d'où la difficulté à viser
horizontalement.

Le glissé depuis le tiroir souffre du même défaut en pire : l'enfant y est la pièce entière
(`DraggablePieceWidget`), donc `dragStartPoint` peut valoir plusieurs cases. Les traces de cette
chasse sont encore dans le fichier : `const double margin = 100.0; // Marge GIGANTESQUE pour
test` et un `debugPrint` spécial « pièce 12 verticale ».

### (b) La mastercase n'est pas la case saisie — *fait*

`onDragStarted` n'appelle que `setDragging(true)`. Un glissé ne déclenche pas `onTap`, donc
**la mastercase reste celle du tap précédent**. Or `_calculateDesiredAnchorFromDrag` (l.1697)
translate la pièce de `doigt − masterAbs`. Si l'on tape la case A puis que l'on saisit la case B,
la pièce saute de `(B − A)` dès le début du glissé. B une case au-dessus de A ⟹ **la pièce monte
d'une case**.

Les deux mécanismes sont réels et indépendants ; lequel domine à l'usage est une question de
mesure, pas de raisonnement.

## 3. Autres défauts trouvés en chemin

| # | Défaut | Conséquence |
|---|---|---|
| 3.1 | `_findClosestValidPlacement` n'a **aucun plafond de distance** (`minDistance` part de l'infini, aucun seuil) | Sur un plateau où les placements valides sont rares, la pièce se **téléporte** à l'autre bout. L'utilisateur ne peut pas refuser l'aimantation |
| 3.2 | L'ancre est calculée sur des **cases entières** (`floor`), sans hystérésis | Le choix bascule dès que le doigt franchit une frontière ; scintillement entre deux candidats quand le doigt reste près d'une limite |
| 3.3 | **Deux conventions de référence** cohabitent : l'aperçu stocke une *ancre*, le dépôt reconstruit un *faux doigt* pour re-dériver la même ancre | Le trajet aperçu → dépôt n'est correct que si `selectedMasterAbs` est parfaitement resynchronisé après chaque isométrie. Le dépôt peut atterrir ailleurs que l'aperçu |
| 3.4 | Dans `selectPlacedPiece`, la boucle de recherche de la mastercase compare `rawLocalX/Y` (déjà **normalisé** : `absolu − gridX`, et `gridX` est l'ancre normalisée) à `coords[i]` (coordonnées **brutes**, min non retranché) | La boucle ne peut correspondre que si `minX == minY == 0` ; sinon le repli `Point(rawLocalX, rawLocalY)` s'applique — **et c'est lui qui est juste**. Pire, une coïncidence entre la coordonnée normalisée de la case tapée et la coordonnée brute d'une autre case donne une **mastercase fausse**. La boucle est à supprimer, le repli est la formule correcte |
| 3.5 | `onLeave` appelle `clearPreview()` **sous un commentaire qui dit de ne pas l'appeler** | L'aperçu disparaît en sortant du `DragTarget`. Le correctif a été écrit puis perdu |
| 3.6 | `debugPrint` à chaque événement de glissé, non gardé par `kDebugMode` | `debugPrint` **n'est pas éliminé en release** : interpolation de chaînes à chaque frame de glissé dans l'app livrée |

## 4. Correctifs, dans cet ordre

1. **`dragAnchorStrategy: pointerDragAnchorStrategy`** sur les deux `Draggable` (case du plateau
   et `DraggablePieceWidget`). `details.offset` devient alors **exactement** la position globale
   du doigt. Suite cosmétique : le coin haut-gauche du `feedback` se retrouve sous le doigt —
   le recentrer par un `Transform.translate` de `−feedbackSize / 2`.
2. **Ancrer le glissé sur la case saisie** : dans `onDragStarted` de la case du plateau, poser la
   mastercase sur `logicalX/logicalY` (l'information est disponible, `_buildCell` la reçoit).
   Supprime le mécanisme (b).
3. **Déposer à l'aperçu, sans reconstruction** : ajouter `tryPlaceAtAnchor(anchorX, anchorY)` et
   appeler `onAcceptWithDetails` avec `previewX/previewY`, déjà snappés et déjà validés.
   Supprime 3.3.
4. **Plafonner l'aimantation** (~1,5 case) : au-delà, aperçu rouge à l'ancre désirée plutôt que
   téléportation. Supprime 3.1. **Changement de comportement assumé** : aujourd'hui une pièce
   finit toujours par se poser quelque part ; demain elle pourra refuser.
5. **Nettoyage** : supprimer la boucle morte de 3.4, résoudre la contradiction 3.5, retirer les
   `debugPrint`, la `margin = 100.0` et le cas particulier « pièce 12 ».
6. **Coordonnées fractionnaires et hystérésis** (3.2) : passer `plateauX / cellSize` en `double`
   au lieu de `floor()` côté widget, arrondir une seule fois, et conserver l'aimantation courante
   tant que le doigt reste à moins de ~0,6 case. **En dernier, et jugé à l'écran** : cela change
   le toucher du jeu entier, ce n'est pas un correctif mais un réglage.

## 5. Mesure qui départage (a) et (b)

Sous `kDebugMode` uniquement, journaliser une ligne par `onDragStarted` :
`caseSaisie`, `masterAbs`, `dragStartPoint`, `cellSize`. Un seul glissé suffit :
`caseSaisie ≠ masterAbs` prouve (b) ; `dragStartPoint.dy > cellSize / 2` prouve (a).
Les deux peuvent être vrais en même temps.

## 6. Sur la mastercase — remarque de conception

La case rouge sert aujourd'hui à **deux** choses : pivot visuel des isométries, et origine de la
translation. Ces deux rôles se contredisent. Pour la rotation on veut une case stable, choisie
délibérément ; pour le glissé on veut la case sous le doigt. Le correctif 2 les sépare de fait —
il faut l'assumer dans la doc et dans le rendu, sans quoi l'utilisateur verra la case rouge
changer de place quand il saisit ailleurs.

## 7. Protocole — chantier **important**, et **réversible commit par commit**

Validé par Paul le 2026-09-01. Ce chantier touche le geste central du jeu : c'est ce qu'un
joueur fait cent fois par partie. Un correctif qui dégrade le toucher est pire que le défaut
d'origine, parce qu'il est plus difficile à nommer. D'où les règles suivantes, contraignantes.

**Avant de commencer** : poser un repère annulable en une commande —
`git tag avant-deplacement-piece`. Travailler sur une branche dédiée.

**Un correctif = un commit, et rien d'autre dedans.** Pas de nettoyage glissé dans un commit de
comportement, pas deux correctifs fusionnés « parce que c'est le même fichier ». C'est
exactement ce qui rend un `git revert` sûr, et c'est la seule raison de la règle.

**Commit 0 — instrumentation, avant tout correctif.** Le journal du §5, sous `kDebugMode`
uniquement. Il reste en place pendant tout le chantier et n'est retiré qu'au dernier commit,
une fois le résultat validé. Sans lui, « ça ne marche toujours pas » n'est pas exploitable :
avec lui, on sait si `caseSaisie ≠ masterAbs` et où le doigt s'est posé dans la case.

**Ordre imposé et dépendance à respecter** : correctifs 1 → 2 → 3 → 4 → 5 du §4.
Le **4 (plafond d'aimantation) ne doit jamais tourner sans 1 et 2**. Avec le décalage encore
présent, un plafond ferait refuser presque tous les placements et donnerait l'impression d'une
régression grave. **Si Paul annule 1 ou 2, il faut annuler 4 aussi.**

**Le correctif 6 (coordonnées fractionnaires, hystérésis) n'est pas dans ce lot.** Il ne corrige
rien, il règle le toucher. Il ne se juge qu'après que le reste est stable, et à l'écran.

**En fin de travail**, lister dans la passation les sha des commits 0 à 5, un par ligne avec son
numéro de correctif, pour que « annule le 4 » soit exécutable sans relecture de l'historique.

**Critère de test, à l'écran, par Paul** : reprendre une pièce posée par une case autre que
celle tapée, et la pousser latéralement d'une case. La pièce doit suivre le doigt sans saut
vertical, quel que soit l'endroit de la case où le doigt se pose. Tester aussi le glissé depuis
le tiroir, qui subit le même défaut en pire.
