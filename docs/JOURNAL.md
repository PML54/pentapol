# Journal — état et passations

> Fichier de coordination entre Claude Code (CLI) et Claude cowork.
> Protocole : `docs/MODUS_VIVENDI.md`.
>
> **§ÉTAT est réécrite à chaque passage. §PASSATIONS ne garde que les trois dernières.**
>
> ⚠️ **§DÉCISIONS a été supprimée le 2026-08-31.** Elle comptait 69 entrées et 112 renvois
> croisés — une comptabilité devenue plus coûteuse que ce qu'elle rapportait, et le point de
> collision entre agents (trois renumérotations en deux jours). Les décisions qui **engagent
> encore** sont devenues des règles dans `CLAUDE.md` §Invariants ; les autres sont de
> l'histoire, et l'histoire est dans `git log`.

---

## §ÉTAT — au 2026-09-04

### L'application

Un seul module de jeu, **Pentoscope** : tailles `size3x5`…`size10x5` (tirage d'un masque de
pièces parmi les solubles) plus `size6x10` (rectangle complet). **Toutes** les réponses
« solution » (compte décroissant, disponibilité, guide) sont désormais adossées à des tables
pré-calculées : `subset_counts.bin` (comptes), `solutions_corpus.bin` (corpus 5×n, 3,13 Mo) et
`solutions_6x10_normalisees.bin`. **Plus aucun solveur backtracking dans l'app livrée.** Plus le
**multijoueur**, qui réutilise son provider. Démarrage sur `HomeScreen` (écran d'accueil livré le
2026-09-02, voir plus bas), puis `PentoscopeGameScreen` sur le niveau courant. Plus de notion de
difficulté.

### Chantiers terminés

- **Suppression du mode classique** — −3197 lignes, module, widgets, écran d'accueil.
- **Le 6×10 dans Pentoscope** — temps 1 et 2, `SolutionSource`, compteur de solutions.
- **Bilan de fin de partie** — bandeau non modal, score retiré, chronomètre corrigé.
- **Ergonomie hors plateau** — tailles ancrées sur le plateau, barre d'actions unique pour les
  deux orientations, ordre des zones aligné, écran de réglages minimal.
- **Persistance, étape 1** — Supabase, `bootstrap.dart` et `DatabaseDebugScreen` retirés.
- **Persistance (PLAN_PERSISTANCE, 4 étapes)** — **faite et committée** (`ea23af7`→`30e4fae`, tous
  ancêtres de `main` ; conservée par le revert du chantier déplacement car présente dans `1efda1a`).
  Une base drift, quatre tables (`Settings` inchangée, `CurrentGame`, `SolvedSolutions`,
  `PuzzleStats`), `schemaVersion` destructif. Records à la complétion via `solutionIndexOf`
  (`null`→`PuzzleStats`, entier→`SolvedSolutions`). Partie en cours : écriture aux poses/retraits +
  au passage en arrière-plan (`main.dart` observe `paused`), effacement à la complétion/partie neuve,
  `restoreGame` au lancement. `SharedPreferences`/Supabase retirés. **Le §ÉTAT précédent la disait à
  tort « reste à faire » — l'état « complète » (`30e4fae`) avait été perdu dans les réécritures du
  journal pendant la saga du revert.** Correctif `isProgression` du 2026-09-04 ci-dessous. **Reste :
  test device de la reprise** (jamais confirmé), et il n'y a **pas encore d'écran pour lire les
  records** (hors périmètre du plan, cf. `PLAN_PERSISTANCE` §6).
- **Records perso (CDC §4, V1)** — les **trois maillots** (acuité/coups/temps). Calcul
  (`completion_metrics.dart`, testé), rack initial capturé/persisté, bilan de fin, schéma à trois
  bests indépendants (partie avec aide comptée mais hors record, §4.8), **écran de lecture**
  (`records_screen.dart`, bouton trophée de l'accueil) et **médaille « vision parfaite » §4.6**
  (acuité 100 % : badge au bilan, icône sur l'écran de records). Détail en §ÉTAT « Records perso ».
- **Phase 0 du défi hebdo (prérequis V1)** — PRNG du dépôt (`PentapolRng`, testé) et pause du
  chronomètre en arrière-plan (solo). Détail en §ÉTAT « Phase 0 ».
- **Suppression de la difficulté puis tirages précalculés (étape A)** — `subset_counts.bin`
  (4096 × uint16, 8 Ko) donne le nombre de solutions de tout tirage 5×n ; le générateur tire un
  masque parmi les solubles (plus d'appel-boucle au solveur, plus de difficulté), le compte est
  affiché au dialogue avec « autre tirage ». Table validée contre `REFERENCE_TIRAGES.md` §2.
- **Tirages précalculés (étape B)** — corpus complet `solutions_corpus.bin` (3,13 Mo, octet/case,
  73 876 solutions 5×n) ; `CorpusSolutionSource` adosse **toutes** les tailles à une table,
  appariement d'octets sans allocation (`common/byte_matching.dart`), compteur décroissant partout,
  et **`PentoscopeSolver` supprimé du dépôt** (les outils réimplémentent l'énumération Flutter-free
  — inutile de le garder dans `tools/`). Motivé par la mesure n°2 : le pire `_solutionStatus`
  (38–78 ms) venait du solveur live, pas du comptage par table (~0,6 ms). Choix : **2 sources
  table-backed** (6×10 via `SolutionMatcher`/BigInt pour son navigateur ; 5×n via corpus/bytes).

Leurs plans ont été **supprimés** une fois appliqués et testés (`MODUS_VIVENDI` §5).

### Chantiers ouverts

| chantier | document | reste à faire |
|---|---|---|
| **Défi de la semaine + classement en ligne** | `CAHIER_DES_CHARGES_V1.md` §7 | **HORS V1** (Paul, §12 Q3). **Phases 0-3 faites** : PRNG (0), dérivation `challenge.dart` (1), mode défi jouable local (2), **identité 128 bits** `AppSettings.playerId` + `generatePlayerId`/`ensurePlayerId` (3). **Phase 4 DÉPLOYÉE** (worker en ligne `https://pentapol-defi.pentapml.workers.dev`, D1 + `SEED_TOKEN` posés, round-trip validé au curl : POST 201, essai unique 409, leaderboard trié). **Client** : `challenge_api.dart` (POST score / GET tableau, échec silencieux §7.8) + **soumission auto à la complétion d'un défi** (`_submitChallengeScore`, `_activeChallenge`). **Phases 0-5 + extras faites** : `LeaderboardScreen` (4 onglets), accès **par l'icône classement d'une taille (ChallengeScreen)** ET **par un bouton « Voir le classement » au bilan d'un défi**. Fetch `GET /challenge` (composition à la main côté client, repli dérivation), et **semeur** `tools/seed_challenges.dart` (dérive + POST avec `SEED_TOKEN`, auto-contrôle du digest gelé). **Le défi est complet de bout en bout.** Reste seulement : composer/semer les vraies semaines (geste de Paul) |
| **Mise sur l'App Store** | `CHECKLIST_APPSTORE.md` | bloquants technique/produit/conformité — s'allonge au fil du travail. **Nouveau bloquant** : `PRODUCT_BUNDLE_IDENTIFIER = com.example.pentapol` (voir `FICHE_APP_STORE.md`) |

**Priorité recommandée** : test device de tout ce qui a été livré le 2026-09-04 (reprise
`isProgression`, pause chrono, records perso), puis — au choix — la **médaille §4.6** (raffinement
des records) ou le début du **défi hebdo Phase 1** (hors V1).

### Chantier « déplacement d'une pièce » — REVERT (2026-09-01)

Le chantier `PLAN_DEPLACEMENT_PIECE` (correctifs 1→5) a fait **apparaître beaucoup d'anomalies**
(déplacements aléatoires) au test de Paul. Décision de Paul : **revenir à l'état pré-chantier**.
La branche de travail a été **reset --hard sur `1efda1a`** (= tag `avant-deplacement-piece`), puis
l'ergonomie conservée (voir plus bas) **fusionnée dans `main`** (`b9bec37`, fast-forward) et
**poussée sur `origin`**. La branche `deplacement-piece`, devenue redondante, a été **supprimée**.
Tout le chantier ET l'instrumentation DRAGDIAG posée ensuite sont **écartés du tree** mais
**conservés intacts** sur `c5306b5` :

- branche **`backup/deplacement-piece-c5306b5`** — **poussée sur `origin`** (donc visible pour
  cowork sur un clone neuf ; ne PAS la fusionner, c'est une archive).
- tag **`chantier-deplacement-backup`** — **local à la machine du CLI** (non poussé).

On y retrouve : plan `PLAN_DEPLACEMENT_PIECE.md`, correctifs 1→5 (carte des sha dans le `git log`
du backup), `PLAN_DIAG_DRAG.md` et l'instrumentation `lib/common/drag_diag.dart` + points DRAGDIAG.
**Rien n'est perdu** — reprise possible par `git cherry-pick`/`checkout` depuis la branche de backup.

**Conservés par-dessus le pré-chantier** (indépendants du chantier, validés par Paul) : les deux
correctifs d'ergonomie du 2026-09-01 — (a) saisie du « I » (barre des pièces, `hitBoxSize` : toute
la boîte de la case répond au doigt ; halo de sélection collé à la pièce) et (b) sortie de l'écran
Paramètres sur iPad (bouton « Fermer » en bas + `SafeArea`, la flèche retour étant recouverte par
les commandes multitâche macOS « Designed for iPad sur Mac »). Reposés à la main sur la version
pré-chantier de `draggable_piece_widget.dart` (le fichier avait été touché par le correctif 1),
`slider`/`settings` repris tels quels. `analyze` 0 error.

### Déplacement d'une pièce — cartographie du bug intermittent (pour la reprise)

Analyse du code **actuel `main` (pré-chantier)** — le décalage horizontal intermittent au glissé
vertical **précède le chantier** et est donc toujours là. Séparé en faits / hypothèse / correctif.

**Faits — topologie.** 2 sinks `DragTarget` : le plateau (`pentoscope_board.dart:85`) et le tiroir
(`pentoscope_game_screen.dart:648`). 3 trajets réels : ① poser depuis le tiroir, ② déplacer une
pièce posée, ③ supprimer (glisser vers le tiroir).
- ③ **fait bande à part** sainement : sink tiroir, `removePlacedPiece`, aucune arithmétique de case.
- ① et ② partagent le **sink plateau**, mais le partage est trompeur — deux fourches :
  - **Fourche A, aperçu ≠ dépôt.** L'aperçu (`onMove`→`updatePreview`→`_findClosestValidPlacement`)
    **snappe** sur l'ancre valide la plus proche. Le dépôt (`onAccept`, board:162-173) **ne snappe
    pas** : il **reconstruit un faux doigt** = `previewX/Y + selectedCellInPiece`, puis
    `tryPlacePiece` **re-dérive** l'ancre via `_calculateDesiredAnchorFromDrag` et place en direct.
  - **Fourche B, mode A ≠ mode B** dans `_calculateDesiredAnchorFromDrag` (prov ~1720). Tiroir
    (mode A, `selectedPlacedPiece == null`) → branche `selectedCellInPiece`, et la reconstruction du
    dépôt (`+selectedCellInPiece`) en est **l'exact inverse** → boucle propre. Pièce posée (mode B,
    `selectedMasterAbs != null`) → branche **`masterAbs`**, formule différente ; or le dépôt ajoute
    `selectedCellInPiece`, **pas** `masterAbs` → **pas inverses**, coïncidence seulement si
    `masterAbs == sp.gridX + selectedCellInPiece` (vrai au décalage de normalisation près).
- Aggravant : `selectPlacedPiece` (prov ~563-571) cherche `selectedCellInPiece` en comparant
  `rawLocal` à des coords **non normalisées** alors que les cellules sont **normalisées** → si
  l'offset de forme ≠ 0, match raté et **fallback brut** `Point(rawLocalX, rawLocalY)`.
- **Fourche C, métrique du snap aveugle à la direction (piste de Paul, la plus probable pour le
  « ça monte »).** `_findClosestValidPlacement` retient l'ancre valide qui minimise
  `dx*dx + dy*dy` — **isotrope** (x et y pèsent pareil) et **sans plafond** sur `main` (le plafond
  ~1,5 case était le correctif 4 du chantier, reverté). Conséquence : si la case visée par le doigt
  est occupée, monter d'une ligne (`dy=1`, d²=1) **bat** continuer horizontalement de deux cases
  (`dx=2`, d²=4) → la pièce « saute vers le haut » pendant un glissé horizontal, et le saut n'est
  même pas borné. La métrique ignore **la direction du geste**.

**Hypothèse (à PROUVER par mesure, pas à affirmer).** Le décalage vit dans le **trajet ②** :
aperçu (snap) et dépôt (reconstruction + re-dérivation `masterAbs`) divergent, et
`selectedCellInPiece` bascule parfois sur son fallback brut selon **forme / orientation / case
saisie** → non systématique, biaisé d'une case dans un sens. Le **trajet ① (tiroir) boucle
proprement** → il devrait être nettement plus stable. **L'asymétrie ① vs ② est testable** — c'est
ce que DRAGDIAG (dans le backup) mesure : `fcol` aperçu vs `finalX` dépôt, `grabx/graby` A vs B.

**Correctif ① appliqué (2026-09-03, testé par Paul).** L'analyse « ① boucle proprement » était
incomplète : le tiroir ancrait le **feedback** sur la case empoignée mais le **placement** sur la
cellule PAR DÉFAUT (`_calculateDefaultCell`) — mismatch → « je n'arrive pas à poser sur une case
dispo depuis le tiroir » (rapport de Paul). Fix : `DraggablePieceWidget` capte l'offset du toucher
(`dragAnchorStrategy` → `onGrab`), le slider en déduit la cellule empoignée (`_grabbedCell`) et la
passe à `selectPiece(grabbedCell:)`. Le tiroir ancre désormais sur la case tenue, comme le plateau.
Correctif isolé, un commit, validé sur device.

**Correctif minimal proposé (isolé, mesurable, un seul changement de comportement).**
**Déposer directement à `previewX/previewY`** dans `onAccept` — l'aperçu contient déjà une ancre
snappée et validée — **au lieu** de reconstruire un faux doigt puis de re-dériver. Supprime la
fourche A d'un coup. Corriger en parallèle le raw-vs-normalisé de `selectPlacedPiece` (fourche B /
fallback). Ne PAS ré-empaqueter avec d'autres retouches (c'est ce qui a coulé le chantier) ; un
correctif = un commit, testé à l'écran par Paul, l'asymétrie ①/② servant d'oracle avant/après.

**Correctif A — snap conscient de l'axe du geste (en préparation, 2026-09-01).** Vise la fourche C.
**Objection posée puis intégrée** : le « A naïf » (ne garder que les candidats de même ligne)
créerait le **bug miroir** pour un glissé vertical (saut latéral) ; aucune métrique *statique* ne
distingue horizontal de vertical quand la géométrie est symétrique. Il faut donc **la direction
réelle du geste**. Implémentation retenue : suivre l'axe dominant du mouvement (case doigt
précédente → courante, dans `updatePreview`, via un champ transitoire `_dragAxis` remis à zéro à
chaque sélection/pose), puis dans `_findClosestValidPlacement` **départager lexicographiquement** —
axe horizontal : minimiser d'abord `|Δligne|` puis `|Δcolonne|` ; axe vertical : l'inverse ; axe
inconnu : isotrope (comportement d'avant). Pas de plafond réintroduit (hors périmètre). Livré sur la
branche **`snap-directionnel`** (hors `main` tant que non testé), en **2 commits** : (1)
instrumentation DRAGDIAG rebranchée (oracle avant/après, `drag_diag.dart` du backup + log
`event=snap` avec `axis`, snap encore isotrope) ; (2) le changement de métrique.
Oracle : `event=snap` doit montrer, après (2), un `chosen` qui **reste sur la ligne du doigt** en
glissé horizontal. Test à l'écran par Paul.

**Résultat (2026-09-02, test de Paul).** La version aboutie de la branche — snap directionnel +
dépôt à l'ancre de l'aperçu (fourche A supprimée) + **ancrage de la mastercase sur la cellule
empoignée** + puce diag `c0..c4` (`d93b584`) — **fonctionne mieux** : le déplacement d'une pièce
posée se comporte correctement à l'écran. Branche **poussée sur `origin/snap-directionnel`** pour
que cowork la voie. Pas encore fusionnée dans `main`.

**Instrumentation retirée (2026-09-02).** Le diagnostic ayant rempli son office, `kDragDiag`,
`dragDiag()` et tous les points DRAGDIAG ont été supprimés : fichier `lib/common/drag_diag.dart`
(`git rm`), blocs `event=grab`/`event=snap`/`event=drop`, helper `_diagCandidates`, et la puce
`c0..c4` de la barre d'isométrie (`_mastercaseLabel` + `_buildMastercaseChip`). **La logique du
correctif A est intacte** — `setDragMastercase`, `_gestureAxis`, snap directionnel, dépôt à l'ancre
de l'aperçu. `analyze` 0 erreur. La branche est **prête à fusionner dans `main`** sous réserve d'un
dernier tour de test de Paul. (L'archive DRAGDIAG reste disponible sur `backup/deplacement-piece-c5306b5`.)

### Revue UI (2026-09-02) — #6 (répartition verticale) et #3 (cul-de-sac réversible)

Revue d'UI menée sur **simulateur** (captures `simctl` ; le ressenti du geste n'est **pas** jugé —
réservé au test device de Paul). Deux corrections retenues par Paul, appliquées sur `main`.

- **#6 — plateau ancré bas en portrait.** Sur un plateau quasi-carré (5×5) la hauteur excède la
  largeur : le plateau « flottait », centré entre deux marges. `pentoscope_board.dart` : portrait
  `Alignment.center` → `Alignment.bottomCenter` (paysage inchangé, `topCenter`). **Piège rattrapé au
  contrôle visuel** : le positionnement visuel (`Align`) et le hit-test du drag
  (`offsetY = (maxHeight − gridHeight)/2`, centré en dur, l.90) étaient **découplés** ; déplacer le
  seul visuel aurait fait tomber les dépôts sur les mauvaises cases. `offsetY` est désormais **couplé
  à l'alignement** (portrait = bas, paysage = haut) — ce qui corrige au passage une incohérence
  latente du paysage (offset centré alors que l'Align est `topCenter`, sans effet tant que le paysage
  n'a pas de rab vertical). Vérifié à l'écran : haut du plateau 26 % → 39 %.

- **#3 — cul-de-sac réversible par l'ampoule.** Choix de Paul : **laisser poser** même quand le
  compteur est à 0 (le joueur peut croire, à tort ou à raison, que c'est jouable), et faire du
  **voyant rouge le bouton de retour**. `pentoscope_game_screen.dart` : la branche `else` (ampoule
  rouge, `!hasPossibleSolution`, jusqu'ici sans effet) appelle `removePlacedPiece(placedPieces.last)`
  — **un appui = un coup en arrière, répétable** ; `removePlacedPiece` recalcule `hasPossibleSolution`,
  donc le rouge s'éteint dès que le plateau redevient soluble. Icône inchangée (ampoule jaune =
  indice, rouge = retour). `deleteCount` s'incrémente mais **n'entre pas** dans `calculateNote`
  (basée sur `hintCount`) → aucune pénalité. **Non encore validé au test device** (comportement gestuel).

`analyze` 0 erreur / 0 warning sur les deux fichiers. **Autres constats de la revue non traités** (à
arbitrer) : barre d'icônes principale hétérogène, rouge sémantiquement surchargé (alerte / suppression
/ mastercase), hiérarchie de boutons ambiguë à l'entrée multijoueur, titre « Multiplayer » en anglais.

### Revue UI — suite (2026-09-02) : icônes d'isométrie + Route 2 (mini-plateau docké)

Deux ajouts, sur retour de Paul.

- **Icônes de la barre d'isométrie agrandies (portrait).** « Trop petites sur iPhone » — de fait
  `_uiIconSize` plafonne à 30 sur iPhone (côté court ≈ 393). Nouvelle fonction **partagée**
  `isometryIconSize(context)` (`config/game_icons_config.dart`) = `shortestSide × 0.12` borné [44, 84]
  ≈ 47 sur iPhone, utilisée par les barres d'isométrie **portrait** des DEUX écrans (solo
  `PentoscopeGameScreen` et duel `PentoscopeMpGameScreen`, jusqu'ici 30 et 42 en dur, indépendants).
  Paysage laissé tel quel (rails compacts, icônes à 20 alignées ; les élargir en permanence pour des
  boutons qui n'apparaissent qu'en manipulation serait un mauvais compromis — à faire si demandé).

- **Route 2 — « occuper le rab » avec le mini-plateau adverse (duel).** #6 libère une bande en haut
  en portrait ; on y **docke** le mini-plateau adverse au lieu de le laisser flotter/chevaucher le
  jeu. `pentoscope_mp_game_screen.dart` : `_opponentDockHeight` décide (portrait, œil actif, **1v1**,
  bande suffisante) et dimensionne le dock d'après la géométrie réelle du plateau — estimation
  **conservatrice** (hauteur de grille bornée par la largeur → on ne docke que si l'espace est franc,
  sinon **repli sur l'overlay flottant** existant). Le dock est le premier enfant de la Column
  portrait (dockH ≤ rab → plateau non rétréci) ; l'overlay flottant est supprimé dans ce cas (pas de
  double rendu). **Réservé au 1v1** (à 2-3 adversaires la bande peu profonde ne tient pas une rangée
  de minis lisibles → empilement à droite conservé). Vraies données adverses. **Non observable au
  simulateur seul** (duel 1v1 réel requis) → à valider sur device.

`analyze` 0 erreur / 0 warning. Découverte au passage : l'overlay adverse de `PentoscopeGameScreen`
(solo) est **dormant** (`_showOpponentOverlay` jamais mis à `true`) et **simulé** ; le vrai mini du
duel vit dans `PentoscopeMpGameScreen` et utilise des données réelles.

### Écran d'accueil (2026-09-02) — implémenté (PLAN_ECRAN_ACCUEIL)

L'écran d'accueil du plan est implémenté et vérifié au **simulateur** (pas encore device). `main.dart`
démarre sur `HomeScreen` au lieu de `PentoscopeGameScreen` direct. En-tête `PENTAPOL` + engrenage,
scène avec l'animation-démo (pièces en miniature → rotation par quarts → montée/pose, boucle sur les
7 tirages du 3×5), bouton `Jouer`. `Reprendre` viendra avec la persistance (§5). **Écart au plan
assumé (choix de Paul)** : le plateau de démo est **vertical 3×5** (le plan §2 disait 5×3).

- **Données** : `tools/generate_home_tirages.dart` (nouveau, Flutter-free, contrôles d'acceptation
  intégrés — 7 tirages PFU/PUN/PVL/PVU/PYU/TYL/VLN, 4 solutions chacun, ids §10) →
  `lib/pentoscope/home/home_tirages_data.dart` (constante `kHomeTirages`, plateau **3×5 vertical**). Le
  corpus n'est pas chargé au lancement (§3).
- **Widget** : `lib/pentoscope/home/home_screen.dart`. Réutilise `PieceRenderer` + un param **additif**
  `showLabel` (défaut true ; l'accueil = false → **pièces nues**, §1). Respecte `disableAnimations`
  (plateau complet immobile) et suspend l'animation en arrière-plan. Plateau **ancré haut** (retour de Paul).
- **Réversibilité** (§6) : tag `avant-ecran-accueil` posé avant le **commit unique** ; un `git revert`
  unique défait tout.

**À suivre** : test device (ressenti, timing, taille des miniatures `kPieceToBoardCellRatio`). Le plan
`PLAN_ECRAN_ACCUEIL.md` **reste** (supprimé seulement une fois appliqué ET testé, MODUS_VIVENDI §5). La
priorité de fond est inchangée : la **persistance étape 4** reste devant (l'accueil se livre avec `Jouer` seul).

### Progression solo (niveaux) + nom du joueur (2026-09-02)

Nouveau : une **progression de niveaux solo**, sauvée, et la **saisie du nom du joueur**.

- **Niveaux = tailles.** `sizeForLevel(n)` (`pentoscope_generator.dart`) : niveau 1..9 → size3x5
  (3 pièces) … size6x10 (12 pièces). `kMaxLevel = 9`.
- **Persistance** (AppSettings, JSON, sans migration, invariant #6) : `currentLevel` (défaut 1) et
  `userName` (nom canonique). Setters `advanceLevel`, `setUserName`, plus `ensureLoaded` (attendre le
  chargement des réglages avant de lire currentLevel au démarrage).
- **Démarrage** : `main.dart` démarre sur `sizeForLevel(currentLevel)` (niveau 1 = 5×3),
  `isProgression:true`. L'accueil affiche « Niveau N » ; « Jouer » enchaîne sur le niveau courant
  (frais si l'actuel est terminé/d'un autre niveau, sinon reprend).
- **Complétion** : un puzzle de progression du niveau courant terminé → `advanceLevel` (via
  `ref.listen` dans l'écran de jeu). Le bilan propose alors **« Niveau suivant »** (remplace
  « Nouvelle partie »). Au **1er puzzle réussi** (userName vide) → dialogue de saisie du nom.
- **`PentoscopeState.isProgression`** distingue un puzzle de progression d'un puzzle du « + » (choix
  libre de taille) ou du multijoueur, qui ne font **pas** avancer le niveau.
- **Pseudo unique** : `userName` est LE nom, utilisé par le MP lobby (« Ton pseudo »), les Réglages
  (« Nom du joueur ») et le dialogue au 1er succès. `duel.playerName` reste dans le modèle mais n'est
  plus lu (vestige).

**Vérifié au simulateur** : accueil « Niveau 1 ». **À valider sur device** (résoudre un puzzle) :
Jouer→5×3 → solution → dialogue nom → niveau 2 sauvé + « Niveau suivant ». Cas limite assumé : une
partie **reprise** d'une session précédente est `isProgression=false` (la terminer n'avance pas le niveau).

### Persistance — correctif `isProgression` (2026-09-04)

Bug d'intégration trouvé en relisant le code (la progression a atterri **après** la persistance) :
`restoreGame` reconstruisait l'état **sans** poser `isProgression` → toute partie reprise retombait
sur le défaut `false`, et la table `CurrentGame` **ne stockait pas** ce champ. Conséquences sur une
partie de **progression** reprise : (1) le bouton « Jouer » (`home_screen.dart` `_play`, `needFresh =
… || !st.isProgression`) démarrait un puzzle **frais** et **effaçait** la partie reprise ; (2) même
atteinte, la terminer **n'avançait pas le niveau**. La reprise était donc silencieusement défaite
dans le flux principal.

**Correctif (un commit, pré-publication → destructif assumé, règle n°6).** Colonne
`CurrentGame.isProgression` (`boolean().withDefault(false)`), `schemaVersion` 4 → 5 ;
`saveCurrentGame` écrit `state.isProgression`, `restoreGame` le lit depuis `row.isProgression`.
`build_runner` régénéré, `flutter analyze lib/` **0 error / 0 warning** (56 infos préexistantes).
**À valider sur device** (PLAN_PERSISTANCE §8, base existante) : commencer un puzzle de progression,
poser des pièces, **tuer l'app**, relancer, « Jouer » → la partie reprend et sa complétion avance le
niveau. `settings_database.g.dart` est gitignoré : régénérer après `pull`.

### Phase 0 du défi de la semaine (2026-09-04) — PRNG du dépôt + pause du chrono

Deux prérequis posés (décision de Paul : les faire **en V1**, ils servent aussi les records perso).
Ils ouvrent les phases 1→5 du défi (spec `CDC §7`), mais **ne créent pas** encore le mode défi.

- **`PentapolRng` (`lib/common/pentapol_rng.dart`)** — PRNG déterministe (xorshift32), indépendant de
  `dart:math` dont `Random(seed)` n'est pas garanti stable entre versions du SDK (`CDC §7.3`, piège 2).
  Test de gel `test/pentapol_rng_test.dart` (goldens + reproductibilité + bornes) — le seul garde-fou
  contre une dérive involontaire des puzzles seedés. **Seul consommateur seedé actuel migré** : les
  orientations du duel (`startPuzzleFromSeed`, ex-`Random(seed)`). *Le `seed` de `generateFromSeed`
  reste mort — le masque du duel vient des `pieceIds` du serveur.* Conséquence assumée : les
  orientations du duel changent vs anciens builds, sans effet (les deux joueurs sont sur la même
  release ; rien de persisté n'en dépend).
- **Pause du chrono** — `pauseTimerForBackground` / `resumeTimerFromBackground` sur le provider,
  câblés dans l'observateur déjà présent de `main.dart` (`paused`/`resumed`). **Solo uniquement**
  (`!_isMultiplayer` ; en duel le serveur fait foi). Correction d'une imprécision de `CDC §7.7` :
  `stopTimer()` seul **ne met pas en pause** (`getElapsedSeconds` = `now − _startTime`, le temps court
  toujours) — on capture la valeur à `paused` et `restoreTimerOrigin(figé)` recale l'origine à
  `resumed`, sans compter l'arrière-plan.

`flutter analyze lib/` 0 error/warning, **22/22 tests** (7 PRNG + 15 existants). **À valider sur
device** : lancer une partie solo, la mettre en arrière-plan (ou passer un appel) 30 s, revenir — le
chrono n'a pas avancé du trou.

### Défi de la semaine — Phase 1 (2026-09-04) : dérivation hors ligne (HORS V1)

Deuxième brique du défi (après le PRNG de Phase 0). **Tout descend d'un entier** (`CDC §7.3`), rien
ne transite : `lib/pentoscope/challenge.dart` (pur, sans réseau) — `weeksSinceEpoch` (origine lundi
5 janvier 2026 **UTC**), `challengeSeed(version, semaine, taille)` (FNV-1a, dépôt), et
`deriveChallenge(week, size, solubleMasks)` → masque + rack (orientation par pièce, id croissant), via
`PentapolRng`. `kChallengeVersion` (dans la clé du classement), `kChallengeSizes` (six tailles, §7.2 :
6×10, 5×9, 5×10 écartés).

**Vérifié** : `_solubleByPopcount` du générateur est **trié par valeur croissante** (balayage
`for m in 0..4095`) → dérivation reproductible (§7.3 piège 3) ; `solubleMasksFor(size)` l'expose (ordre
figé, pour brancher le défi en Phase 2). **Test de gel** `test/challenge_test.dart` : digest des 60
premiers défis (6 tailles × semaines 0..9) + spot-check + invariants (masque soluble, orientations
valides, reproductibilité, semaines) — le garde-fou du §7.3 piège 5. **45/45 tests.**

**Phase 2 (2026-09-04) — mode défi jouable en local (mode classé).** `startChallenge(ChallengeDefinition)`
et `startWeeklyChallenge(size)` construisent le puzzle depuis le **masque + rack dérivés** (pas de
tirage aléatoire). Nouvel état `isRanked` : l'**appui sur l'ampoule est neutralisé** (§4.8 ; message ;
couleur/compteur conservés ; retrait via sélection+poubelle). Le défi est **éphémère** — non persisté
(garde `isRanked` dans `_saveCurrentGame`) et **n'efface pas** la partie de progression sauvegardée
(garde dans le clear). Écran `challenge_screen.dart` (choix parmi les 6 tailles, §7.2) + **bouton
drapeau** sur l'accueil. **Décision de Paul (2026-09-04)** : un défi **n'écrit PAS** dans les records
perso (`_saveCompletionRecord` skip si `isRanked`) — parties libres/progression restent purs, le
classement du défi viendra du serveur. Le bilan affiche quand même acuité/coups/temps.
`analyze lib/` 0 error/warning, 45/45 tests. **Reste Phases 3-5** (réseau) : identité 128 bits (§7.4),
serveur Worker+D1 (§7.5-7.6, recalcul serveur du `minIso`), UI des trois classements.

### Records perso — Phase A (2026-09-04) : calcul + capture du rack + bilan de fin

Premier tiers du chantier §4 (les deux maillots recommandés : acuité complète + bilan de fin).

- **Socle de calcul** `lib/pentoscope/completion_metrics.dart` (+ `test/completion_metrics_test.dart`,
  7 tests) : `minIso = Σ minIsometriesToReach(rack, placement)`, `acuité = (minIso+1)/(iso+1)`,
  `coups = pièces + 2·retraits` (Q6 : `translationCount` exclu ; démonstration :
  `poses − retraits = pièces` à la complétion), temps. Vérifié que `rotationCW/symmetryH…` opèrent
  sur le **même espace d'index** que `positionIndex` — le maillot jaune est sain.
- **Rack initial** : `PentoscopeState.initialOrientations`, figé au démarrage
  (`Map.from(piecePositionIndices)`), **persisté** dans `CurrentGame.initialOrientations`
  (schéma **5→6**, destructif) et restauré → l'acuité survit à une reprise (`piecePositionIndices`
  mute quand le joueur tourne les pièces, pas ce champ).
- **Bilan de fin** (`pentoscope_game_screen.dart`) : le bandeau affiche les trois maillots — acuité %
  (jaune), coups brut (à pois), temps (vert) — détail (isométries, minimums) en tooltip. Remplace les
  compteurs bruts iso/translation/delete.
- **Bug corrigé au passage** : `computeCompletionMetrics` lisait le temps **vivant**
  (`getElapsedSeconds`), qui continue de croître après `stopTimer()` (l'origine n'est pas recalée) →
  le bilan aurait grandi à chaque rebuild. `elapsedSeconds` est désormais **figé dans l'état** aux deux
  sites de complétion (placement et indice) et le bilan le lit.

`analyze lib/` 0 error/warning. **À valider sur device** : terminer un puzzle, voir les trois maillots ;
le temps ne bouge plus une fois résolu.

**Phase B (2026-09-04) — enregistrement à trois bests indépendants (§4.1).** `SolvedSolutions` et
`PuzzleStats` portent désormais **trois bests nullables** : acuité (`bestAcuityMinIso` +
`bestAcuityIsoCount`, bruts §7.6), coups (`bestMoves`), temps (`bestTimeSeconds`) — schéma **6→7**.
`_saveCompletionRecord` passe les métriques et `clean = hintCount == 0` : **fini le `bestActions`
faux** (iso+translation+delete). Décision alignée §4.8 : **une partie avec aide compte** (timesSolved
/ completed) **mais ne pose aucun record** (l'indice place à l'optimum, gonflerait l'acuité). Chaque
best évolue **séparément** (comparaison d'acuité croisée sans flottant, `_isBetterAcuity`). Test
d'intégration base-mémoire `test/records_db_test.dart` (6 cas). **35/35 tests.**

**Phase C (2026-09-04) — écran de lecture.** `lib/pentoscope/screens/records_screen.dart` : une
carte par taille jouée, les trois maillots (acuité % / coups / temps, `—` si pas de best), lus depuis
`PuzzleStats` (pièces tirées) et **agrégés** depuis `SolvedSolutions` (6×10 : meilleure acuité, moins
de coups, meilleur temps parmi les solutions trouvées). Accès par un **bouton trophée** ajouté à
l'en-tête de l'accueil. État vide explicite tant qu'aucun record. **À valider sur
device** : terminer quelques puzzles (sans aide), ouvrir l'écran, vérifier les trois maillots.

**Médaille « vision parfaite » §4.6 (2026-09-04).** Acuité 100 % = `isometryCount == minIso` (aucun
geste de trop), **jamais** un seuil sur `minIso` brut (`minIso = 0` récompenserait le tirage).
`CompletionMetrics.perfectVision` (testé) ; badge « Vision parfaite » au bilan si `perfectVision &&
hintCount == 0` (partie sans aide) ; icône médaille sur l'écran de records pour les tailles au best
d'acuité 100 %. Chantier records perso **clos**. 38/38 tests.

### FIX minIso toujours à 0 (2026-09-04)

Bug signalé par Paul : le maillot jaune affichait `minimum 0` sur toute partie **relancée**. Cause :
`reset()` (« recommencer »/« Nouvelle partie ») construisait l'état avec `piecePositionIndices: {}` et
**sans** `initialOrientations` → rack de référence absent → `computeMetrics` faisait `rack == null →
continue` pour chaque pièce → minIso = 0. La partie initiale (via `startPuzzle`) marchait ; `reset()`
était le seul chemin de démarrage à ne pas capturer le rack. Correctif : `reset()` tire des orientations
**aléatoires** (comme `startPuzzle`) et fige `initialOrientations`. Effet de bord corrigé : après un
« recommencer », les pièces repartaient toutes à l'orientation 0 (plus facile, incohérent) ; désormais
tirage aléatoire comme la partie initiale. `analyze lib/` 0/0, 45/45.

### Bilan de fin — carte flottante (2026-09-04, choix de Paul)

Le bilan de fin **supersède le bandeau non-modal** (`PLAN_BILAN §2`) : c'est désormais une **carte
flottante non-modale** (`_BilanCard` dans `pentoscope_game_screen.dart`), centrée par-dessus le
plateau résolu, **fermable** (tap sur le plateau pour rouvrir) et **déplaçable au doigt** (poignée +
`_bilanOffset`, recentré au prochain bilan). Elle regroupe tout le bilan
lisiblement : titre, badge « Vision parfaite » éventuel, les trois maillots en **lignes libellées**
(acuité / coups / temps + détail), note d'aides, boutons Fermer / Nouvelle partie ou Niveau suivant.
Nettoyage demandé : à la complétion, le **chrono** et le **compteur de solutions** sont retirés de la
barre du haut, et le bandeau du bas disparaît (slider vide). **Pendant le jeu, rien ne change.**
`analyze lib/` 0 error/warning, 45/45 tests. Testé à l'écran par Paul.

### Compteur Help — maillot blanc (2026-09-04)

Implémenté (CDC §7 Acté 3-4). État `PentoscopeState.helpCount`, incrémenté à chaque **sauvetage
rouge→jaune** (`_bumpHelp` : lampe `false→true` après une action) aux **trois** sites qui peuvent
rétablir la solubilité — retrait (`removePlacedPiece`), déplacement (`tryPlaceAtAnchor`), rotation/
symétrie d'une pièce **posée** (`_applyIsoUsingLookup` CAS 2, `_applySymmetryAbs`). Poser une pièce
neuve ne peut jamais sortir d'un cul-de-sac (prouvé) → non compté là. Persisté `CurrentGame.helpCount`
(schéma **7→8**), exposé par `CompletionMetrics.rescues` (param `computeMetrics`, défaut 0, testé),
affiché au **bilan comme 4e maillot blanc** ⚪ (pastille bordée). Tourne aussi en défi (mode classé).
**4e colonne Help dans les records perso locaux (2026-09-04)** : `bestHelp` nullable dans
`SolvedSolutions`/`PuzzleStats` (schéma **8→9**), mis à jour comme les autres bests sur partie propre
(le moins de sauvetages = best) ; l'écran trophée affiche désormais **quatre maillots** (acuité/coups/
temps/Help), agrégation `bestHelp` pour le 6×10. Test `records_db_test` étendu. `analyze lib/` 0/0,
**48/48 tests**.

### Défi Phase 4 — serveur écrit, à déployer (2026-09-04)

`server/` (neuf, TypeScript/Cloudflare) : worker `src/index.ts`, `schema.sql` (D1), `wrangler.toml`,
`package.json`, `tsconfig.json`, `README.md`. **Modèle confiance** (décision Paul) : l'app mesure, le
joueur ne saisit rien → pas de triche via le jeu ; le seul vecteur (POST forgé hors app) est jugé
négligeable → **le serveur ne recalcule pas `minIso`**, il **stocke la grille** pour audit hors ligne.
Endpoints : `POST /score` (essai unique par clé primaire `(version,week,size,player_id)`, §7.1),
`GET /leaderboard?maillot=jaune|pois|vert|blanc`, `GET/POST /challenge` (définition composée à la main,
`POST` gardé par `SEED_TOKEN` pour éviter l'empoisonnement — **révise Acté 1bis** : l'amorçage n'est
plus ouvert au premier joueur mais réservé à un semeur de confiance, cf. `server/README.md`).
**Déployée par Paul le 2026-09-04** : worker en ligne `https://pentapol-defi.pentapml.workers.dev`,
base D1 + tables créées, `SEED_TOKEN` posé. Round-trip validé au curl (POST /score → 201, doublon →
409, GET /leaderboard trié). **Intégration client (2026-09-05)** : `lib/pentoscope/challenge_api.dart`
(client HTTP, échec silencieux §7.8, `submitScore`/`leaderboard`) et **soumission auto** — à la
complétion d'un défi (`isRanked`), le provider POST le score (`_submitChallengeScore` ; `_activeChallenge`
porte week/size ; grille sérialisée pour l'audit). `analyze lib/` 0/0, 50/50. **Reste Phase 5** : écran
des quatre classements (une vue, onglets/podiums, dégradation gracieuse), + fetch `GET /challenge`
(composition à la main côté client) + un script Dart de semage (dérive + POST avec le token). *Ligne de
test « Test » sur (v1, week0, size1) à purger par Paul si souhaité.*

### Documentation

`MANUEL_DEFIS_ET_MAILLOTS.md` (neuf, 2026-09-05) — manuel de référence : défi perso (records
locaux) vs défi réseau (classement en ligne), et le **mode de calcul exact des quatre maillots**
(acuité, coups, temps, Help) + la médaille. Ancré sur l'implémentation et `CDC §4`/`§7`.

`CLOUDFLARE_CONFIG.md` (neuf, 2026-09-05) — mémo opérationnel de l'infra Cloudflare : les deux
workers (duel WebSocket *hors dépôt* ; défi `pentapol-defi` dans `server/`), la config exacte (URL,
base D1 `7ea667b1…`, secret `SEED_TOKEN`), le flux de données, et les commandes courantes (déployer,
init D1, secret, semer, inspecter/purger). Le `SEED_TOKEN` n'y figure pas (secret non relisible).

`BASE_LOCALE.md` (neuf, 2026-09-05) — miroir côté appareil : la base drift/SQLite locale
(`pentapol_settings.db`, `schemaVersion 9`, réécriture destructive), les quatre tables (`Settings` =
AppSettings JSON dont `playerId` ; `CurrentGame` ; `SolvedSolutions` ; `PuzzleStats`), quand c'est
écrit/effacé, et ce qui n'est PAS stocké. Reflète le schéma courant.

`FONCTIONNEMENT.md` est la description de référence de l'application — elle absorbe depuis
le 2026-08-31 l'ancien `PENTOSCOPE.md`, devenu un doublon partiel une fois qu'il n'est resté
qu'un module de jeu. `UI_PROPERTIES_GUIDE.md`, guide Flutter générique sans rapport avec
l'état du projet, est supprimé. `REFERENCE_TIRAGES.md` est le **test d'acceptation** du
générateur de tirages (`tools/generate_subset_counts.dart`) : sa sortie doit reproduire les
nombres du §2 (ce que le générateur vérifie, exit 1 sinon). Son §11 (ajouté le 2026-09-03)
recontrôle l'**asset livré** `subset_counts.bin` (996 confirmé), pas seulement l'énumération.

Trois documents de référence commités le 2026-09-03 (`69fce95`) : `REFERENCE_ISOMETRIES.md`
(coût des isométries, `minIso`, acuité, chiralité des tirages ; rejouable par
`tools/verif_isometries.py`), `CAHIER_DES_CHARGES_V1.md` (positionnement V1, système de score,
défi de la semaine) et `FICHE_APP_STORE.md` (champs mesurés contre les limites App Store).

### Test

Paul, iPhone et iPad simulé, en release :

```bash
flutter run --release -d 00008150-000165D4027B401C
```

> ⚠️ En `--release`, `debugPrint` est supprimé : tout critère formulé sur la console doit être
> reformulé en observation à l'écran.
> ⚠️ La réécriture destructive de la base ne se teste que **sur une base existante** — une
> installation neuve ne l'exécute jamais.

### Git

`origin/main` = **`8091059`** (poussé le 2026-09-04 : fix `isProgression` + Phase 0 défi + bump
`202609040505`, 1.0.3). **Commit local non poussé** : records perso **Phase A** (calcul + rack + bilan).
Bump de version à lancer (`scripts/update_version.sh`, date/heure) juste avant le prochain push.
La branche `deplacement-piece` a été
**supprimée** (fusionnée dans `main`). Depuis, commits locaux non poussés (2026-09-04, après le push de `16df5f8`) : médaille §4.6
(`ef58394`) et défi **Phase 1** (`challenge.dart`). Sauvegarde du
chantier écarté : branche **`backup/deplacement-piece-c5306b5`** (sur `origin` **et** locale) et tag
`chantier-deplacement-backup` (local seul), tous deux sur `c5306b5` — **ne pas supprimer** tant que
la question du déplacement d'une pièce n'est pas retranchée. Détail dans §ÉTAT « REVERT ».

> ⚠️ `settings_database.g.dart` (généré) est gitignoré : après un `pull`, régénérer par
> `dart run build_runner build --delete-conflicting-outputs`. `subset_counts.bin` **est** suivi.

---

## §PASSATIONS

> Les trois dernières seulement. Au-delà, `git log --oneline` dit la même chose en plus court.

**2026-09-04 — CLI → cowork (discussion défi : composition à la main, vérification, indicateur Help).** Décisions
de Paul consignées dans `CAHIER_DES_CHARGES_V1.md` §7 (bloc « Révision du 2026-09-04 » en tête). **Aucun
code touché** — tout est hors V1, le serveur n'existe pas ; le client Phase 2 reste sur `deriveChallenge`
en interim (et futur repli). **Actés** : (1) le défi est **composable à la main, autorité serveur** — définition
`(taille, masque, rack)` en table serveur, `deriveChallenge` devient générateur par défaut (téléversé
depuis Dart, pas de PRNG en JS) + repli offline ; le serveur a le rack → recalcule `minIso` sans porter
le PRNG. **Amorçage paresseux** (Acté 1bis) : au lancement le client lit si les *n* défis de la semaine
sont initialisés côté serveur, sinon **le premier joueur les sème** (écriture idempotente « insérer si
absent », course inoffensive car dérivation déterministe ; composition à la main = pré-remplir avant le 1er joueur) ;
(2) le serveur **fait confiance** aux coups/temps/Help d'une partie validée (recalcule seul
`minIso`) ; (3) indicateur **Help = sauvetages rouge→jaune** (agnostique au geste). **Tranché par Paul
le 2026-09-04** : (4) **Help est un 4e maillot classé** → **§4.1 amendé : quatre maillots** (acuité,
coups, temps, Help = **maillot blanc**) ; (5) **un seul essai par joueur et par config**
— §7.1 « premier essai » **conservé** (insertion unique), l'essai produit **quatre valeurs** → une ligne
par `(joueur, semaine, taille)` + la grille, quatre index D1, chaque maillot trie sur sa colonne.
Détail dans `CDC §7` (Actés 4 et 5). Cette mise à jour docs est commitée seule (doc sans code,
MODUS_VIVENDI §5).

**2026-09-04 — CLI → cowork (la persistance était déjà faite ; correctif `isProgression`).** En
reprenant « la persistance », constat : les **4 étapes du `PLAN_PERSISTANCE` sont codées et
committées** depuis `ea23af7`→`30e4fae` (ancêtres de `main`, conservées par le revert). Le §ÉTAT les
disait à tort « reste à faire » — l'état « complète » (`30e4fae`) avait disparu dans les réécritures
du journal pendant la saga du revert. §ÉTAT corrigé : persistance déplacée en « chantiers terminés »,
priorité recommandée passée aux **records perso**. **Un vrai bug corrigé** : `isProgression` n'était
ni stocké ni restauré → une partie de progression reprise était jetée par « Jouer » et n'avançait pas
le niveau. Colonne ajoutée, `schemaVersion` 4→5 (destructif), save/restore câblés, `build_runner`
régénéré, `analyze lib/` 0 error/warning. **Commité `53f688c`** (2 fichiers `lib/` + journal, un seul
commit), non poussé — à tester sur device (base existante : réécriture destructive une fois).

**Puis Phase 0 du défi (V1, décision de Paul).** Deux prérequis qui servent aussi les records perso :
**`PentapolRng`** (PRNG du dépôt, xorshift32 + test de gel ; migration du seul chemin seedé actuel, les
orientations du duel) et la **pause du chrono en arrière-plan** (solo, câblée dans `main.dart`). Détail
en §ÉTAT « Phase 0 du défi ». `analyze lib/` 0 error/warning, 22/22 tests. **Modifs non commitées**
(attente du feu vert de Paul) : `lib/common/pentapol_rng.dart` (neuf), `test/pentapol_rng_test.dart`
(neuf), `lib/pentoscope/pentoscope_provider.dart`, `lib/main.dart`, et **ce journal** (doc avec code
derrière → même commit, MODUS_VIVENDI §5). Phases 1→5 (dérivation défi, mode classé, identité, serveur,
UI) restent à faire — hors V1.

**2026-09-03 — CLI → cowork (Paul a tranché les sept questions du CDC §12).** Les réponses sont
encodées dans `CAHIER_DES_CHARGES_V1.md` : §12 réécrit en décisions, sections concernées mises à
jour. Décisions :
1. **Déverrouillage progressif** (pas de choix libre) — statu quo du code.
2. **Compteur = toutes les solutions**, symétries comprises (pas « à symétrie près »).
3. **Payant, sans classement en V1** (option 1) → **§7 défi de la semaine + classement en ligne
   passent HORS V1**, deviennent la 1re mise à jour. La V1 garde les **records/stats personnels**.
4. **Duel temps réel maintenu dans la V1** (priorité #9), contre la reco initiale de couper.
5. **Nommage Tour de France figé** : jaune = acuité, à pois = coups, vert = temps.
6. **Le déplacement direct ne compte pas comme un coup** (`translationCount` hors décompte) →
   §4.7 mis à jour : coup = pose ou retrait, minimum = nombre de pièces.
7. **3×5 et 4×5 restent ouverts au défi** (défis de vitesse — concerne la mise à jour, défi hors V1).

Impact §ÉTAT : chantier « défi de la semaine » marqué hors V1 ; « records perso » reste V1.
**À noter côté code (Q6)** : le décompte des coups devra ignorer `translationCount` et sommer
poses + retraits (`deleteCount` existe, le compteur de poses est à vérifier).

`CHECKLIST_APPSTORE.md` alignée sur Q3 et Q6 : **point 19** (nouveau, bloquant technique) — figer
la règle des coups avant tout record publié (Q6, sinon les anciens records deviennent
incomparables) ; **points 12 et 13** annotés — Q3 met le classement en ligne hors V1, donc la
suppression de compte reste hors sujet pour la V1 et « ne collecte rien » est conservé (les deux
reviennent à la mise à jour « classement »). **Point 6** aligné sur Q4 : le multijoueur est
maintenu en V1, donc l'URL en dur et l'absence d'interrupteur distant deviennent bloquants (au
lieu de « à couper »).
