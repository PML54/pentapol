# Plan — Ergonomie : icônes d'isométrie, rangée d'actions, rack

> ✅ **VALIDÉ par Paul le 2026-09-10** — les dix décisions du §9 sont adoptées.
> **Préalable impératif : voir §0 (pousser l'état actuel avant toute modification).**
>
> Écrit le 2026-09-10 par cowork. Premier document du projet fondé sur des **captures d'écran
> réelles** (`screenshot/piece5.png`, `screenshot/piece9.png`, 2026-09-09, 1206×2622) : le §5 de
> `CHECKLIST_APPSTORE.md` (« cowork n'a jamais vu l'app tourner ») devient partiellement caduc.
> À supprimer une fois appliqué et testé (`MODUS_VIVENDI` §5).

---

## 0. Préalable — pousser l'état actuel AVANT toute modification

**Condition posée par Paul à la validation (2026-09-10).** Ce plan touche à la disposition de
l'écran de jeu, c'est-à-dire à ce que Paul vient de déclarer satisfaisant après trois jours de
correctifs sur le glissé. Il faut donc un **point de comparaison stable et publié** avant d'y
toucher.

1. `main` est **en avance d'un commit sur `origin`** (`c31685c`, hub d'icônes + entraînement
   Option A). **Le pousser d'abord**, seul, sans rien y ajouter.
2. Décider du sort de `screenshot/` (non suivi par git aujourd'hui) : ce plan **cite ces deux
   captures comme sources datées** de ses neuf constats. Soit elles entrent dans le dépôt et les
   références tiennent, soit le §1 devient invérifiable pour quiconque clone. Recommandation :
   les committer (≈ 400 Ko) et y déposer aussi les captures **après** modification (§8).
3. Ce n'est qu'ensuite que commencent les modifications du présent plan.

Objectif : que Paul puisse tester **avant/après** sur device et revenir en arrière d'un seul
`git revert` si la disposition nouvelle se révèle pire que l'actuelle — en particulier les −11 %
de surface de jeu du §4, qui sont le seul point de ce plan à coûter quelque chose d'irréversible
au confort de jeu.

---

## 1. Constats, mesurés sur les captures du 2026-09-09

| # | constat | mesure |
|---|---|---|
| C1 | Le **compteur de solutions** (`_buildSolutionCounter`) s'affiche comme un chiffre nu **collé à l'ampoule** : sur `piece5` il vaut `1` et se lit « 1 indice ». Le différenciateur de l'app est invisible par ambiguïté | AppBar l. 1204 |
| C2 | La rangée d'isométries **remplace l'AppBar** quand une pièce est sélectionnée : maison, chrono, ampoule et compteur disparaissent au moment où l'utilisateur agit | `piece9` vs `piece5` |
| C3 | Distance entre la commande la plus utilisée et l'objet manipulé | **~1600 px sur 2622** |
| C4 | Icônes de symétrie = `Icons.swap_vert` / `Icons.swap_horiz`, qui signifient **« réordonner une liste »** dans le vocabulaire Material. L'utilisateur les lit correctement ; leur sens est faux | `game_icons_config.dart` l. 138, 146 |
| C5 | Les pièces du rack sont **~4 fois plus petites** que les cases du plateau (`cellSize` codé en dur à 22 px) | `piece5` |
| C6 | La **première pièce du rack est rognée** par le bord gauche de l'écran | `piece5` |
| C7 | Le chrono affiche des **secondes brutes** (`106s`) ; à trois minutes il affichera `203s` | `_formatTime`, l. 211 |
| C8 | Le numéro de pièce est répété **sur les cinq cases** d'une pièce posée, mais une seule fois en pastille au rack : deux conventions pour la même information | `piece5`, `piece9` |
| C9 | Le bandeau de debug **recouvre** le haut du plateau (déjà point 22 de la checklist) | `piece5` |

---

## 2. Invariant — le plateau reste toujours légal

**Règle de Paul (2026-09-10), déjà en vigueur dans le code :** les isométries s'appliquent
librement sur une pièce **du rack** ; sur une pièce **posée**, elles ne s'appliquent que si le
résultat est valide.

Cette règle n'est pas un choix d'interface, c'est un **invariant structurel** : deux mécanismes en
dépendent.

- Le **compteur de solutions** apparie les positions contre un corpus de placements **légaux**.
- Le **classifieur de fautes** (`fault_analysis`) mesure des transitions soluble→insoluble ; une
  superposition illégale n'est pas « insoluble », elle est **hors modèle**.

Un plateau qui accueillerait un chevauchement, même transitoirement, fausserait les deux. À porter
dans `CLAUDE.md` §Invariants.

**Ce qui doit changer : la façon dont le refus se manifeste.** `_handleTransformationResult`
(l. 241) signale `impossible` par un `heavyImpact` et `recentered` par un `mediumImpact` — deux
issues différentes sur **le même canal, à deux intensités**. Personne ne les distingue de façon
fiable, et vibrations coupées il ne reste rien : l'utilisateur appuie, rien ne bouge.

→ **Griser d'avance** les boutons dont l'opération échouerait, au moment de la sélection (quatre
tests, coût négligeable). On ne signale plus une interdiction : on ne l'offre pas. Les messages
texte restent supprimés (choix de Paul, à ne pas rouvrir).

---

## 3. Les quatre boutons d'isométrie

### 3.1 Terminologie — à fixer avant le code

Une symétrie se nomme par son **axe**, jamais par un mouvement : « symétrie d'axe vertical »
(les cases échangent gauche↔droite), « symétrie d'axe horizontal » (haut↔bas). Aujourd'hui
`isometrySymmetryH` porte `swap_vert` et `isometrySymmetryV` porte `swap_horiz` : **noms et
glyphes sont croisés**. À vérifier à l'exécution et à réaligner sur la convention d'axe, sinon le
prochain passage les ré-inversera.

Rappel : `applyIsometrySymmetryH` échange son implémentation entre portrait et paysage
(`pentoscope_provider.dart` l. 230-241). L'opération est donc définie **par rapport à l'écran**,
pas par rapport à la pièce. C'est le bon choix — et c'est pourquoi le glyphe doit montrer un
miroir **à l'écran**.

### 3.2 Proposition retenue — le résultat sur le bouton

Chaque bouton affiche **la pièce sélectionnée telle qu'elle sera après l'appui**. Quatre vignettes
au lieu de quatre symboles. Plus rien à comprendre : on voit ce qu'on obtient. Le jeu n'a que douze
formes, `PieceRenderer` et la table des orientations existent — rien à inventer.

Trois conditions, sans lesquelles la proposition échoue :

1. **Fantôme de l'orientation courante** en pâle derrière la projection — à 40 px, un L et son
   tourné se ressemblent.
2. **Animation de la transformation sur ~150 ms** à l'appui : l'œil doit voir l'opération, pas
   seulement l'état d'arrivée. Règle aussi le cas `recentered`, où la pièce se déplace
   silencieusement pour tenir sur le plateau — un déplacement animé se lit comme un mouvement, un
   déplacement instantané se lit comme un bug.
3. **Vignette grisée = opération impossible** (§2). La règle « sur le plateau, seulement si c'est
   valide » devient visible sans un mot et sans une clé i18n.

**Repli si les vignettes ne se lisent pas sur device :** `Icons.flip` (forme + reflet de part et
d'autre d'un axe pointillé — le glyphe de tous les éditeurs d'image), tel quel pour l'axe vertical,
`Transform.rotate(pi/2)` pour l'axe horizontal.

### 3.3 Invariants de la barre

- **L'ordre des quatre boutons ne change jamais.** C'est la mémoire du geste qui rend onze appuis
  par partie supportables (coût moyen 11,25 sur un 6×10, `REFERENCE_ISOMETRIES.md` §2).
- Le code couleur (rotations bleues / symétries vertes) est conservé — pastille ou liseré si les
  vignettes prennent la place des glyphes.
- **Ne pas** remplacer les 4 opérations par 8 vignettes d'orientation directe : cela supprimerait la
  rotation mentale que le mode entraînement vient d'être écrit pour enseigner, mettrait huit cibles
  sur un téléphone, et écraserait la métrique d'acuité (tout deviendrait atteignable en un appui).

---

## 4. Placement de la rangée

**Retenu : rangée réservée en permanence, juste au-dessus du rack.** L'AppBar redevient permanente.

- Zone du pouce (tiers bas), sur la ligne droite du geste rack → plateau.
- Hauteur **réservée en permanence** (grisée quand rien n'est sélectionné) : le plateau ne doit
  jamais bouger sous le doigt. Une rangée qui apparaît décale le plateau et déplace la pièce en
  cours de manipulation — la classe de bug corrigée les 7, 8 et 9 septembre.
- Effet de bord bénéfique : l'AppBar cessant d'être escamotée, le **compteur de solutions redevient
  visible en permanence** (C1, C2).

**Prix, mesuré sur `piece5` (5×7, capture 1206×2622).** Le plateau est contraint par la **hauteur** :
1624 px pour 7 lignes = 232 px par case, contre 236 px disponibles en largeur. La rangée occupe
172 px ; il reste 1452 px, soit **207 px par case — −11 %**.

**Option écartée : la rangée prend la place du rack pendant la manipulation.** Elle ne coûtait rien
en hauteur, mais elle est **incompatible avec la règle du §2** : puisque les isométries s'appliquent
d'abord sur la pièce **du rack**, le rack doit rester visible pendant qu'on appuie. Écartée pour
cette raison, pas par préférence.

**Paysage :** rangée en bas également. Ne pas rouvrir le chantier « barre d'actions unique pour les
deux orientations » (2026-08-31).

---

## 5. Le rack

- **Taille de case = fraction calculée de la case du plateau** (0,5 à 0,6), et non les 22 px codés
  en dur de `PieceRenderer`. Rapport actuel mesuré : **~1:4** (C5) — c'est pourquoi la pièce
  « grossit » quand on l'attrape.
- **Marge horizontale** et rack défilable avec dégradé de bord : la première pièce ne doit plus être
  rognée (C6).
- **Une seule convention pour le numéro** : la pastille du rack, pas le chiffre répété sur les cinq
  cases du plateau (C8).

---

## 6. Le compteur de solutions — le plus rentable des points

Indépendant du reste et le moins cher : donner au compteur **une place à lui, un libellé, et rendre
visible qu'il décroît**. C'est ce que l'app a d'unique ; aujourd'hui il se lit comme un compteur
d'indices (C1). Aucun module de démonstration ne rattrapera un différenciateur invisible dans le jeu
lui-même.

---

## 7. Hors périmètre de ce plan

Module de démonstration, forme des défis, interrupteur de disponibilité du multijoueur : traités
ailleurs. Rappel de deux points restés ouverts et non couverts ici :

- le **bloquant n°6** (URL du worker en dur, aucun interrupteur distant) reste armé ;
- **aucune semaine de défi n'a jamais été semée** — juger la forme des défis avant de les avoir vus
  avec des données réelles, c'est décorer une pièce vide.

---

## 8. Vérifications attendues du CLI

- `flutter analyze lib test` : 0 erreur, 0 warning ; tous les tests au vert.
- Grisage préventif : test unitaire sur une pièce posée au bord (les opérations refusées sont bien
  celles qui échouent réellement).
- Le plateau **ne se décale pas** entre « rien de sélectionné » et « pièce sélectionnée » (la
  hauteur de la rangée est réservée dans les deux cas).
- Chrono en `mm:ss` (C7).
- i18n EN **et** FR pour toute chaîne nouvelle.
- Captures avant/après sur device, portrait **et** paysage, à déposer dans `screenshot/`.

---

## 9. Décisions validées par Paul (2026-09-10)

1. Vignettes du résultat sur les quatre boutons (§3.2), avec fantôme + animation 150 ms.
2. Repli `Icons.flip` si les vignettes ne se lisent pas.
3. Grisage préventif à la place du refus haptique muet (§2).
4. Convention de nommage par **axe**, et réalignement des noms/glyphes croisés (§3.1).
5. Rangée réservée au-dessus du rack, AppBar permanente, **−11 % sur la taille des cases** (§4).
6. Taille des pièces du rack en fraction calculée de la case du plateau (§5).
7. Numéro en pastille uniquement (§5).
8. Chrono en `mm:ss` (§8).
9. Compteur de solutions sorti de l'ambiguïté avec l'ampoule (§6).
10. Invariant « le plateau reste toujours légal » porté dans `CLAUDE.md` §Invariants (§2).
