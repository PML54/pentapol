# Plan — écran d'accueil

> Ouvert le 2026-09-01. Maquette itérée avec Paul et **validée** dans cet état :
> plateau, miniatures, bouton. Rien d'autre.
>
> ⚠️ **Cet écran remet en place quelque chose que Paul avait délibérément supprimé** (démarrage
> direct sur `PentoscopeGameScreen`, journal §ÉTAT). À traiter comme réversible : voir §6.

## 1. Ce que l'écran contient — exhaustivement

Trois éléments, et **deux mots de texte sur tout l'écran**.

1. **En-tête** — le mot `PENTAPOL` à gauche, un engrenage à droite. Pas de menu, pas de bandeau,
   **pas de logo image** (`pentopol.png` fait 1 Mo : explicitement hors périmètre).
2. **La scène** — un plateau **5 de large × 3 de haut** en haut, et sous lui l'animation décrite
   au §2.
3. **Un bouton pleine largeur** — `Jouer`, ou `Reprendre` s'il existe une partie sauvegardée.
   **Sans sous-titre.** Contrepartie assumée : on ne sait pas *quelle* partie on reprend avant de
   l'avoir rouverte.

**Ce qu'il ne contient pas, et c'est voulu** : aucune ligne de progression, aucune légende sous
le plateau, aucun bouton secondaire, aucun compteur. Ne pas les rajouter « pour compléter ».

## 2. L'animation, précisément

Elle est l'accroche **et** l'onboarding : ce qu'un nouveau venu ne comprend pas, ce n'est pas
qu'il faut remplir une grille, c'est qu'**on a le droit de faire tourner les pièces**.

Boucle, pour un tirage donné (3 pièces) :

1. Les trois pièces apparaissent **ensemble, en bas**, en **miniature**, réparties
   horizontalement sur une rangée — là où le joueur ira les chercher. Échelle : la constante
   existante **`kPieceToBoardCellRatio`** (0,35), **pas une valeur écrite en dur** — si la
   miniature paraît trop petite ici, c'est qu'elle l'est aussi dans le tiroir.
2. Chaque pièce apparaît avec **1 à 3 quarts de tour d'écart** par rapport à son orientation
   finale.
3. Puis, l'une après l'autre : elle pivote par quarts de tour (≈ 0,40 s par quart), puis **monte,
   reprend sa taille réelle et se pose** (≈ 0,66 s). Environ 0,18 s entre les deux phases,
   ≈ 0,18 s entre deux pièces.
4. Plateau complet, pause ≈ 2 s, tirage suivant.

**Rendu des pièces** : réutiliser `PieceRenderer` avec `getPieceColor` des réglages. L'écran
d'accueil ne redessine pas les pentominos à sa façon — sinon il dérivera visuellement du jeu.

**Au repos et en accessibilité** : si les animations sont désactivées
(`MediaQuery.disableAnimations`), afficher le **plateau complet, immobile** — pas un plateau vide.
Le contrôleur d'animation est arrêté et libéré dès que l'écran n'est plus visible.

## 3. Les données

La boucle passe en revue **les 7 tirages jouables du 3 × 5** — soit la totalité du contenu de
cette taille — avec une solution réelle chacune.

**Ne pas charger `solutions_corpus.bin` (3,13 Mo) au lancement pour ça.** Sept tirages × 3 pièces
× 5 cases, c'est une centaine d'entiers : les figer dans une constante du widget, **produite par
le générateur** et non saisie à la main.

Contrôle d'acceptation, dans un test :
- les 7 masques sont exactement ceux du §7 de `REFERENCE_TIRAGES.md` — **PFU, PUN, PVL, PVU,
  PYU, TYL, VLN** ;
- chacun a exactement **4 solutions** (soit une seule à symétrie près) ;
- les identifiants suivent la table du §10 de `REFERENCE_TIRAGES.md` (P=2, T=3, F=4, Y=5, V=6,
  U=7, L=8, N=9) — **pas `_pieceNames`, qui est fausse**.

## 4. Le branchement

`main.dart` l.97-104 : `MaterialApp(home: _isInitialized ? const PentoscopeGameScreen() : …)`.
Remplacer par le nouvel écran ; `Jouer` / `Reprendre` pousse `PentoscopeGameScreen`. Conserver
tel quel l'écran de chargement pendant l'initialisation. La taille de départ reste la valeur par
défaut actuelle — le choix de taille vit dans le dialogue de nouvelle partie, pas ici.

## 5. Dépendance — une seule, et elle est contournable

L'épuration a dissous l'objection initiale. Il ne reste **plus qu'une** dépendance : `Reprendre`
suppose la partie en cours sauvegardée (persistance étape 4, point 5 de la checklist).

Donc : **livrer maintenant avec `Jouer` seul**, et n'ajouter `Reprendre` que le jour où la
sauvegarde existe. C'est une condition dans le libellé du bouton, rien de plus. Ne pas attendre
la persistance pour faire l'écran, et ne pas simuler une partie sauvegardée en attendant.

## 6. Protocole

**Un seul commit**, précédé de `git tag avant-ecran-accueil`. L'écran est ajouté, `main.dart`
modifié, rien d'autre touché. Revenir en arrière doit être un `git revert` unique — parce que
c'est une décision de produit que Paul peut vouloir défaire après l'avoir vue tourner sur son
téléphone, et non un correctif.

**Priorité** : le chantier « déplacement d'une pièce » est terminé (test de Paul concluant,
`a155cd8`). Reste devant cet écran la **persistance étape 4 — la partie en cours n'est toujours
pas sauvegardée**, point 5 de la checklist et bloquant d'usage. L'écran d'accueil ne la double
pas : il se livre avec `Jouer` seul (§5) et gagne `Reprendre` quand la sauvegarde existe.

**i18n** : deux chaînes seulement (`Jouer`, `Reprendre`). Les écrire de façon à être extraites
sans peine le jour venu, mais **ne pas** mettre en place le mécanisme ARB dans ce commit.

## 7. Objections consignées

- **Un écran d'accueil est une friction.** Le démarrage direct était une bonne décision. Elle
  n'est défaite que parce que cet écran *montre* quelque chose — pas parce qu'une application
  « doit » avoir un accueil.
- **Le 3 × 5 flatte la taille la plus pauvre** : 7 tirages, une solution unique chacun à symétrie
  près, 28 pavages en tout. C'est le contenu le plus mince de l'application. L'animation y est
  lisible, mais elle ne doit pas laisser croire que le jeu se joue à trois pièces.
- **La progression a disparu avec le texte.** « 37 / 996 » était le meilleur argument de
  rétention — un objectif fini qu'aucun générateur ne peut afficher. Piste si Paul veut la
  retrouver sans casser l'épuration : une rangée de 996 points minuscules dont 37 allumés, qui
  dirait la même chose **sans un mot**. À proposer, pas à implémenter d'office.
- **L'arbitrage reporté, pas tranché** : un puzzle « résolu », c'est un tirage parmi 996 en 5 × n,
  mais le 6 × 10 est un seul puzzle et 9 356 solutions. Deux compteurs de nature différente. La
  question revient au premier écran de statistiques.
