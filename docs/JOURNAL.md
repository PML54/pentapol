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

## §ÉTAT — au 2026-09-10

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

- **Ergonomie du jeu (2026-09-10, PLAN_ERGONOMIE_ICONES blocs 2-3 + carte de fin)** — chrono `m:ss`,
  compteur de solutions désambiguïsé, bande debug débranchée (C9), invariant « plateau toujours légal »
  (CLAUDE.md §Inv. #7) ; rack agrandi (`rackCellRatio` live, défaut 0.46) à emplacement serré + fondu de
  bord, pastille unique par pièce posée (`showPieceNumbers`) ; carte de fin refondue (étoiles 1-3 +
  bouton infos, plus de « Résolu »/« Vision parfaite »). **Reste du plan** : décision 4 (noms/glyphes
  d'axe), bloc 4 (vignettes + grisage préventif), bloc 5 (rangée d'isométrie réservée, −11 %). Détail
  en §PASSATIONS 2026-09-10.
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
- **Records perso (CDC §4, V1)** — les **trois maillots** (acuité **plafonnée** / **fautes** /
  temps, refonte « A » du 2026-09-05 — voir plus bas). Calcul (`completion_metrics.dart`, testé),
  rack initial capturé/persisté, bilan de fin, schéma à trois bests indépendants (partie avec aide
  comptée mais hors record, §4.8), **écran de lecture** (`records_screen.dart`, bouton trophée de
  l'accueil) et **médaille « vision parfaite » §4.6** (acuité 100 % : badge au bilan, icône sur
  l'écran de records). Détail en §ÉTAT « Records perso ».
- **Refonte « A » des maillots (2026-09-05, choix de Paul)** — retour à **trois** maillots après
  l'épisode « 4e maillot blanc » du 2026-09-04. L'acuité est **plafonnée à 100 %** (elle dépassait
  quand l'ampoule plaçait une pièce sans coûter d'isométrie), et les maillots **Coups** et **Help
  (blanc)** fusionnent en **🔴 À pois — Fautes** = nombre de transitions soluble→insoluble
  (culs-de-sac), mathématiquement égal aux anciens sauvetages. `helpCount`→`faultCount`,
  `bestMoves`+`bestHelp`→`bestFaults` (schéma drift **10**, réécriture destructive), `Maillot` à
  trois cas, serveur `scores.faults` (**redéployé + D1 réinitialisée le 2026-09-05** — voir §ÉTAT défi).
  Bilan d'une **partie avec aide** (`hintCount>0`) : pas de maillots, message « Résolu avec N
  aide(s) » + temps. Docs : `MANUEL_DEFIS_ET_MAILLOTS.md` (réécrit, fait foi), CDC §4.1 (amendé).
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

- **Bilinguisme EN/FR (i18n, 2026-09-06)** — l'app était **française en dur** ; `lib/l10n/` ne contenait
  que 4 clés jamais câblées. Désormais : `flutter_localizations` + `generate: true`, `l10n.yaml`,
  délégués et `supportedLocales: [en, fr]` dans le `MaterialApp` (`main.dart`), **locale résolue depuis
  `AppSettings.localeCode`** (nouveau champ JSON, `null` = suit l'appareil ; pas de migration, invariant #6)
  et **sélecteur `Système / Français / English`** dans les Réglages (`setLocale`). **~90 clés** (dont
  pluriels et placeholders) dans `app_en.arb` (template) / `app_fr.arb` ; **toutes les chaînes visibles**
  des 13 écrans/widgets passent par `AppLocalizations` (accueil, jeu solo, bilan/maillots, records,
  réglages, couleurs perso, navigateur de solutions, défi, classement, **et** duel/multijoueur — choix
  de Paul « tout d'un coup »). Restent **littéraux** par choix : `PENTAPOL` (logo), `Pentoscope
  Multiplayer` (nom), `Go`/`DNF`/`GO!` (abréviations), le SnackBar de debug « test DB » du lobby, et les
  libellés `DuelDuration` (« 1 min »… numériques ; « Perso » n'apparaît jamais à l'écran). `analyze lib
  test` **0 error/0 warning** (61 infos, toutes préexistantes), **49/49 tests**. **Fichiers générés
  `lib/l10n/app_localizations*.dart` non encore suivis par git** — à committer avec le reste pour que
  l'arbre soit autonome (imports résolus sur clone neuf). **Reste : test device** (langue système + bascule
  manuelle) par Paul.

### Chantiers ouverts

| chantier | document | reste à faire |
|---|---|---|
| **Défi de la semaine + classement en ligne** | `CAHIER_DES_CHARGES_V1.md` §7 | ⚠️ **EN V1 (décision de Paul du 2026-09-07, révise le « hors V1 » du 2026-09-03)** — rendu conforme : envoi de score **désactivé par défaut** (opt-in explicite), consultation du classement conditionnée à l'opt-in (§4.5), **suppression des données** (RGPD §7.4). Détail en §ÉTAT « Conformité défi V1 ». **Phases 0-3 faites** : PRNG (0), dérivation `challenge.dart` (1), mode défi jouable local (2), **identité 128 bits** `AppSettings.playerId` + `generatePlayerId`/`ensurePlayerId` (3). **Phase 4 DÉPLOYÉE** (worker en ligne `https://pentapol-defi.pentapml.workers.dev`, D1 + `SEED_TOKEN` posés, round-trip validé au curl : POST 201, essai unique 409, leaderboard trié). **Client** : `challenge_api.dart` (POST score / GET tableau, échec silencieux §7.8) + **soumission auto à la complétion d'un défi** (`_submitChallengeScore`, `_activeChallenge`). **Phases 0-5 + extras faites** : `LeaderboardScreen` (**3 onglets** depuis la refonte « A »), accès **par l'icône classement d'une taille (ChallengeScreen)** ET **par un bouton « Voir le classement » au bilan d'un défi**. Fetch `GET /challenge` (composition à la main côté client, repli dérivation), et **semeur** `tools/seed_challenges.dart` (dérive + POST avec `SEED_TOKEN`, auto-contrôle du digest gelé). **Le défi est complet de bout en bout.** **Refonte « A » (2026-09-05) : le serveur `scores` porte `faults` au lieu de `moves`/`help` — worker REDÉPLOYÉ (`Version ID a459eb84…`) et D1 RÉINITIALISÉE le 2026-09-05 (DROP `scores` puis `schema.sql` ; `challenges` intacte ; round-trip revalidé au curl : POST 201, doublon 409, leaderboard renvoie `faults`).** Reste : composer/semer les vraies semaines (geste de Paul) |
| **Mise sur l'App Store** | `CHECKLIST_APPSTORE.md` | bloquants technique/produit/conformité — s'allonge au fil du travail. **Bloquant 21 (bundle id) réglé côté code le 2026-09-08** : `com.example.pentapol` → **`com.pml.pentapol`** sur iOS ET Android ; reste l'enregistrement de l'App ID dans les consoles (hors dépôt). Migration iOS **SPM + min iOS 15** committée le même jour. |

**Priorité recommandée** : test device de tout ce qui a été livré le 2026-09-04 (reprise
`isProgression`, pause chrono, records perso), puis — au choix — la **médaille §4.6** (raffinement
des records) ou le début du **défi hebdo Phase 1** (hors V1).

### Entraînement Option A + réglage « compteurs » + accueil hub (2026-09-09, choix de Paul — NON testé device)

Trois changements de la journée, `analyze` **0/0**, **67/67 tests**, commités ensemble (voir `git log`
du jour). **Aucun n'est encore validé sur device par Paul.**

- **Mode entraînement — Option A** : l'exercice n'a plus d'écran propre. `training_screen.dart` et
  `training_provider.dart` **supprimés** ; l'état entraînement vit dans **`pentoscope_provider`
  (`startTraining()`)** et l'affichage réutilise **`PentoscopeGameScreen`** (même UI que le jeu).
  Plateau d'entraînement porté **5×5 → 5×7** (`kTrainBoardHeight`, remplit l'écran en portrait).
- **Réglage « compteurs »** : `AppSettings.showCounters` (défaut **false**, JSON, pas de migration,
  invariant #6), `setShowCounters` (settings_provider), case dans les Réglages, **overlay
  isométries 🔄 · fautes ⚫** en haut-gauche de la barre de jeu quand activé.
- **Accueil = hub d'icônes** (`home_screen.dart`) : titre « PENTAPOL » retiré ; les 3 gros boutons du
  bas supprimés. En-tête = **Jouer (person) VERT, gros (46), au centre géométrique** (Stack) ;
  Multijoueur (people) + Entraînement (psychology) à gauche ; défi/records/réglages à droite (toutes
  à 32). Tooltips i18n existants, aucune chaîne nouvelle.

### Mode entraînement — niveau 1 livré (2026-09-08, `PLAN_MODE_ENTRAINEMENT`)

Premier pas contre le **bloquant produit n°8** (« aucun onboarding ») : un exercice interactif de
**rotation mentale**, hors progression et hors records. **Niveau 1 (une pièce)** appliqué et vérifié
statiquement ; **niveau 2 (deux pièces) NON fait** — le plan le gate sur un **test device du niveau 1
par Paul** (à sa demande). Le plan **reste** (supprimé seulement après application ET test, MODUS §5).
⚠️ **Le détail ci-dessous décrit l'état livré en `3c90d00` (écrans séparés) ; il est SUPERSÉDÉ par
l'Option A du 2026-09-09 ci-dessus** — conservé pour la logique pure (`training_mode.dart`), inchangée.

- **Logique pure** `lib/pentoscope/training/training_mode.dart` (Flutter-free, testée) : plateau
  `size5x5` (PLAN §4 — plus petit où les 63 orientations tiennent), tirage reproductible via
  `PentapolRng`, **validation par égalité des ensembles de cases occupées** (jamais par index),
  minimum d'appuis via **`Pento.minIsometriesToReach`** (l'orpheline, réutilisée telle quelle).
  **Terminaison garantie X compris** (le X ne boucle pas : pose seule, `minPresses` 0 ; les autres
  tirent une orientation de départ de **forme** différente de la cible).
- **Provider** `training_provider.dart` : état **PUR, aucune écriture DB** (prouvé au grep §9). Les
  quatre boutons d'isométrie comptent en **appuis** ; le doigt **déplace** (translation, non comptée).
- **Écran** `training_screen.dart` : plateau 5×5, fantôme (forme cible en surbrillance), pièce
  déplaçable au doigt (`onPanStart/Update` — grab sur une case occupée, suit le doigt, confiné au
  plateau par `clampAnchor`), barre des quatre isométries (icônes/tooltips réutilisés), carte de
  bilan « N appuis · Ns » + « M suffisai(en)t » (informatif, non comparatif), « Suivante ».
- **Persistance** : `AppSettings.trainingExercisesDone` (`int?`, `null` = jamais joué), setter
  `recordTrainingExercise` → **retour d'exercice, PAS un record** (aucune écriture PuzzleStats/
  SolvedSolutions, pas de bump de `schemaVersion`, invariant #6). JSON.
- **Entrée** : bouton « Mode entraînement » (school_outlined) sous « Multijoueur » sur l'accueil.
- **i18n** : clés `trainingMode/Instruction/InstructionPose/Presses/Enough/Seconds` en EN **et** FR ;
  réutilise `isoRotateTW/CW`, `isoSymH/V`, `congrats`, `next`. `gen-l10n` régénéré (générés versionnés).
- **Tests** `test/training_mode_test.dart` (§9) : terminaison sur les 12 pièces, validation par
  ensembles (I symétrique), et **catalogue §5 confirmé par exécution** — 342 couples distincts,
  210 à un appui, 132 à deux, **diamètre 2** (aucun repli `minIsometriesToReach` non trouvé). Les
  nombres du plan sont donc **vérifiés**, pas supposés (règle n°7).

`flutter analyze lib test` **0 error / 0 warning** (62 infos préexistantes), **59/59 tests**.
**Reste : test device par Paul** (ressenti du glissé, lisibilité du fantôme, tailles/timing) — puis,
seulement alors, le **niveau 2** (§3 du plan : accepter TOUT pavage valide de la région). ⚠️ Ce que
le mode **n'enseigne pas** (PLAN §7) : ni le compteur décroissant, ni la lampe rouge, ni le but du
jeu — le n°8 ne se refermera qu'avec un écran de vraie partie 3×5 commentée, à planifier à part.

### Corrections documentaires (2026-09-08, `PLAN_MODE_ENTRAINEMENT` §8)

Cinq des six corrections du §8 appliquées ; la sixième **rejetée car son postulat était faux**
(règle n°7, vérifié au `ls`/`grep`) :

- **`CHECKLIST_APPSTORE.md`** : points **1** (`flutter test` rouge — `widget_test.dart` n'existe
  plus) et **2** (`supabase_flutter` — absent, `bootstrap.dart` supprimé) **retirés** (note datée).
  Point **7** reformulé en **point de contrôle de soumission** (`update_version.sh` n'écrit que
  `build_info.dart`, volontairement ; `pubspec.yaml` renseigné à la main — pas une divergence).
  Bloquant **9** : tables 5×12/4×15 **abandonnées** (format téléphone), remède reporté sur la
  `ListSolutionSource` du point 10. En-tête : **Android dans le périmètre** (Play Console, keystore,
  métadonnées EN/FR ×2 stores).
- **`CLAUDE.md`** : « Plateforme cible : iOS » → **iOS + Android** (ne pas supprimer `android/`).
- **⚠️ §8 point 3 NON appliqué** : le plan disait `bigint_plateau`, `shape_recognizer` et
  `ui_layout_provider` « supprimés » — **c'est faux**, les trois existent toujours et sont suivis
  par git (aucun importateur). Le §4 du checklist était donc **déjà exact** ; j'y ai ajouté une note
  datée. `ui_layout_provider` est de plus **entrelacé** avec `ui_layout_manager`→`ui_dimensions` :
  leur retrait est un **chantier de code** (à décider avec Paul), pas une correction documentaire.
  `bigint_plateau`/`shape_recognizer` sont autonomes (zéro import) → suppression sûre si voulue.
- **Suite (2026-09-09, décision de Paul)** : `bigint_plateau.dart` et `shape_recognizer.dart`
  **supprimés** (`git rm`, zéro importateur). `analyze` 0/0, 59/59 tests inchangés. Reste le seul
  `ui_layout_provider` (cluster entrelacé). *(Verrou git `index.lock` périmé de la veille retiré au
  passage — aucun processus git actif.)*

### Centralisation des règles de score (2026-09-09, décision de Paul)

Les **calculs de score côté Dart** sont désormais isolés, testables et **réellement réutilisés** par
leurs consommateurs, à **résultats identiques** (prouvé par tests) et **sans toucher à la manipulation
des pièces**. Le socle métrique (`computeMetrics`/`CompletionMetrics`) était déjà central et partagé
(records + défi) ; ce qui restait dispersé, c'était la **règle d'acuité**, recopiée en **quatre** endroits.

- **Nouveau module pur, sans dépendance** `lib/pentoscope/score_rules.dart` (importable par la couche
  drift, l'API, les écrans) : `acuityRatio` (plafonné 1.0), `acuityPercent` (entier plafonné),
  `isBetterAcuity` (produit croisé sans flottant), `isPerfectVision`. Une seule définition de chaque règle.
- **Consommateurs routés** : `completion_metrics.dart` (`acuity`/`acuityPercent`/`perfectVision`
  délèguent), `pentoscope_game_screen.dart` (bilan lit `m.acuityPercent`), `records_screen.dart`
  (`acuityPercent`, agrégation 6×10, `hasPerfectVision`), `settings_database.dart` (`_isBetterAcuity`
  **retiré**, deux sites → `isBetterAcuity`), `challenge_api.dart` (`LeaderboardEntry.acuityPercent`).
- **Plafond partout (décision de Paul, 2026-09-09)** : `records_screen.acuityPercent` était **non
  plafonné**, il l'est maintenant. **Aucun effet visible** : les records ne stockent que les parties
  **propres** (`isoCount ≥ minIso` → ratio ≤ 1) — prouvé par un test d'équivalence sur ce domaine.
- **Code mort supprimé** : `PentoscopeNotifier.calculateNote()` (note 0-20 sur les indices), **zéro
  appelant** (public → invisible à `analyze`, famille des « membres publics morts » de CHECKLIST §4).
- **Tests** `test/score_rules_test.dart` : plafond, équivalence exhaustive de `isBetterAcuity` avec
  l'ancien `_isBetterAcuity` (grille 9⁴), et de `acuityPercent` avec les anciennes formules (API
  plafonnée partout ; records non plafonné sur le domaine propre). `completion_metrics_test` et
  `records_db_test` protègent les comportements existants.

`flutter analyze lib test` **0 error / 0 warning** (62 infos préexistantes), **67/67 tests**. Aucune
ligne de la manipulation des pièces (drag/rotation/pose) touchée. **Incohérence latente laissée
telle quelle** (à décider si besoin) : `isBetterAcuity` compare des ratios **non** plafonnés (ordre
total) alors que l'affichage est plafonné — sans conséquence tant que les records sont propres.

### Conformité défi V1 (2026-09-07) — opt-in + suppression (décision de Paul)

**Décision de Paul (2026-09-07), déclenchée par `INDEX_DOCS.md` §3.1 de cowork** : le défi en ligne
**reste dans la V1** (révise le « hors V1 » du 2026-09-03). Or le code envoyait `playerId` + pseudo
+ grille **sans condition** à la complétion d'un défi, alors que la déclaration App Privacy visée
(« ne collecte rien ») supposait le défi hors V1. Rendu conforme sans couper le défi :

- **Opt-in, désactivé par défaut** (CDC §8). `AppSettings.shareScoresOptIn` (bool, défaut `false`,
  JSON sans migration, invariant #6). `_submitChallengeScore` **ne fait rien** sans opt-in → **aucun
  `playerId` n'est généré** par défaut (`ensurePlayerId` n'est appelé que sous opt-in) : « ne collecte
  rien » redevient vrai pour une install par défaut.
- **Consultation du classement conditionnée** (CDC §4.5). Les deux accès (icône classement d'une
  taille dans `ChallengeScreen` ; « Voir le classement » au bilan d'un défi) passent par
  `openLeaderboardWithConsent` (`challenge_consent.dart`) : sans opt-in, un **dialogue de
  consentement** explique ce qui est envoyé et propose Activer / Plus tard. Refus → rien ne s'ouvre.
  Depuis le bilan, l'activation soumet le défi qu'on vient de terminer (`submitAfterOptIn`).
- **Proposition à la 1re complétion d'un défi** (choix de Paul, 2026-09-07) : à la fin d'un défi, si
  l'opt-in n'est pas donné, un dialogue le propose — **une seule fois** (drapeau
  `challengeConsentAsked`, JSON sans migration), après l'éventuelle saisie du nom. Refus → ne
  redemande plus automatiquement (activable ensuite via Réglages / classement).
  `maybeProposeConsentOnChallengeCompletion` dans `challenge_consent.dart`, appelé depuis
  `_onPuzzleCompleted`.
- **Interrupteur permanent** dans les Réglages (nouvelle section « Classement en ligne »).
- **Suppression RGPD** (CDC §7.4, exigence Apple en V1). Bouton « Supprimer mes données de
  classement » (Réglages) → `deleteOnlineIdentity()` : `DELETE /score?playerId=…` (efface toutes les
  lignes du joueur) puis efface le `playerId` local et coupe l'opt-in. Route serveur `DELETE /score`
  ajoutée (`server/src/index.ts`) — **à redéployer par Paul** avant que le nettoyage serveur soit
  effectif (le nettoyage local, lui, se fait toujours).
- **i18n** : ~12 clés (consentement, section réglages, suppression) dans `app_en.arb`/`app_fr.arb`,
  `gen-l10n` régénéré (invariant #8).
- **Docs** : `CHECKLIST_APPSTORE.md` points 12-14 réécrits (le défi est en V1, opt-in, suppression
  faite) + **nouveau bloquant 21** (bundle id `com.example.pentapol`) et note de divergence de
  version sur le point 7, tous deux signalés par `INDEX_DOCS.md` §3.2.

`flutter analyze lib test` **0 error / 0 warning** (61 infos préexistantes), **49/49 tests**,
`tsc --noEmit` (serveur) OK. **Reste : (1) redéploiement du worker par Paul** (route DELETE),
**(2) test device** (dialogue de consentement, bascule Réglages, suppression), **(3)** déclarer le
comportement opt-in dans App Store Connect (point 12).

### Taille des pièces et icônes (2026-09-07) — retour de Paul « réduction perturbante entre configs »

Gêne signalée par Paul : les pièces rétrécissent d'une config à l'autre (plus le plateau est grand,
plus la case — et donc la pièce de barre `= boardCell × k` — est petite). **Cause** : `cellSize =
min(W/w, H/h)` **sans borne haute** → les petits plateaux (3×5, 4×5) s'affichent démesurés et le
passage à un plus grand fait une « falaise ». Le rétrécissement des pièces **du plateau** est en
partie inévitable (géométrie : le 6×10 a 4× plus de cases), mais la falaise, elle, est corrigeable.
Direction retenue par Paul (Levier 1+3) :

- **Borne haute `kMaxBoardCellSize = 84.0`** (pt absolus, pas relatifs à l'appareil pour ne pas
  réintroduire une détection de tablette, §3) appliquée au `cellSize` du board **et** au `boardCell`
  de `_barMetrics` (cohérence §3). Effet iPhone : la case des niveaux 1-2 passe de 112/95 à 84.
- **`kPieceToBoardCellRatio` 0.22 → 0.26** : pièces de barre ~+18 % partout (le 6×10 reste préhensible).
- **Icônes d'isométrie** `isometryIconSize` facteur 0.12 → 0.14 (≈47→55 pt).
- **Icônes de l'AppBar** (`_uiIconSize`) : `_kIconSizeFactor` 0.075 → 0.11 et plancher 30 → 40 (elles
  étaient collées au plancher 30 sur iPhone → ≈43 pt) — « trop petites dans l'AppBar » (Paul).
- **Retrait de l'icône `Icons.person`** de l'AppBar (elle faisait `reset()` « recommencer ») — choix
  de Paul ; la remise à zéro reste dans « Nouvelle partie » (add_circle) et la carte de bilan.
- **Halo de sélection lisible sur pièce jaune** (`pentoscope_piece_slider.dart`) : le halo ambré seul
  ne contrastait pas sur la pièce N°3 (jaune) ; ajout d'un **contour sombre net par-dessus**, visible
  quelle que soit la couleur (palettes perso incluses).
- **Retrait de l'icône visionneuse** (`view_carousel`, navigateur de solutions, 6×10) — buggée (Paul).
  `compatibleSolutions()` (provider) et les clés i18n `compatibleSolutionsTitle/Tooltip` deviennent
  orphelines, laissées en place (comme `restartTooltip`).
- **Vignette d'accueil découplée du `k` de gameplay** (`home_screen.dart`, `_kHomePieceRatio = 0.20`) :
  la hausse de `k` (0.22→0.26) faisait se toucher les mini-pièces du rack de la démo (posées à des
  fractions égales de la largeur). La vignette étant décorative, elle garde son propre ratio.
- **🐞 DEBUG bandeau compteurs live** (`kShowLiveCounters = true`) : coin haut-gauche, `🔄 iso · 🔴
  fautes · ↔️ translations · 🚑 retraits-en-rouge` (`state.isometryCount`/`faultCount`/
  `translationCount`/`redRemovalCount`), pour le test device. **À repasser `false` avant soumission**
  — `CHECKLIST_APPSTORE` point 22. Pas `kDebugMode` (test en `--release`). *Décision de Paul
  (2026-09-07)* : ne PAS compter le tâtonnement en rouge (translation ni retrait) comme **faute** —
  ça casserait l'invariant fautes=culs-de-sac et doublonnerait avec le temps — mais **observer**
  d'abord les compteurs bruts. `translationCount` existait déjà ; `redRemovalCount` est neuf (retrait
  quand le plateau était rouge = sortie de cul-de-sac), **non persisté** (compteur d'observation).
- **🔎 Classifieur de fautes** (`lib/pentoscope/fault_analysis.dart`, pur, testé — `test/fault_analysis_test.dart`).
  À chaque faute (🟡→🔴), `analyzeFault(board)` classe la cause : **⚠️ aire non multiple de 5** (une zone
  vide dont la taille n'est pas multiple de 5 ; **englobe les poches < 5** — refonte du 2026-09-07 qui a
  supprimé `pocheTropPetite`) ou **🌫️ impossibilité subtile** (zones toutes multiples de 5, mais mort).
  **Gravité continue** = `kGraviteAireCoeff / taille` (défaut 20 → zone de 4 = 5.0, plus petite = plus
  grave), `kGraviteSubtile` (défaut 1.0) pour le subtil — coefficients **à régler à l'observation**.
  Câblé aux 4 sites de faute (pose/déplacement, retrait, rotation, symétrie) : `faultAireCount`,
  `faultSubtileCount`, `faultGraviteSum` (état, **non persistés**), affichés en **2ᵉ ligne** du bandeau
  debug (`⚠️ n · 🌫️ m · Σg X.X`). **Observation seulement** : n'entre PAS dans les maillots ; le barème
  et son éventuelle intégration se décideront sur données (avant lock de publication si classé).
  **Centralisation (2026-09-07)** : tous les indicateurs d'observation sont **définis, documentés et
  formatés dans `fault_analysis.dart`** — `FaultIndicators` (les deux lignes de compteurs) et
  `diagnosticCourant(...)` (3ᵉ ligne = **diagnostic de l'état courant**, recalculé à **chaque coup** :
  `✅ résolu` / `🟢 soluble` / `⚠️ zone (g)` / `🌫️ subtile`). Le bandeau (`_debugIndicatorsOverlay`) ne
  fait que les afficher ; l'accumulation reste dans `PentoscopeState`. L'analyse tourne donc bien à
  **chaque mouvement** (le bandeau se reconstruit à chaque changement d'état).

Toutes ces valeurs sont des **constantes nommées « à régler à l'œil sur device »**. `analyze lib test`
**0/0**, **49/49 tests**. **Reste : test device** (calage des valeurs par Paul).

### Déplacement d'une pièce — méthode « suivi exact du doigt » (2026-09-07, testée OK par Paul) ✅

> ⚠️ **Les deux sections ci-dessous (REVERT + cartographie des fourches) sont désormais HISTORIQUES.**
> Elles décrivaient l'ancien état ; le bug intermittent « la pièce ne suit pas toujours le doigt » a
> été repris et **corrigé** le 2026-09-07. Correction du §ÉTAT au passage : contrairement à ce que
> disaient ces sections, les correctifs de `snap-directionnel` **avaient bien été fusionnés dans
> `main`** (dépôt à l'ancre de l'aperçu, snap directionnel, `setDragMastercase`) — la branche a été
> supprimée depuis. Le bug **persistait malgré eux**, ce qui a motivé un changement de **méthode**.

**Méthode retenue (validée puis testée par Paul)** : **suivi exact du doigt, validité = couleur, aucune
aimantation.** La case empoignée reste sous le doigt à tout instant ; la pièce ne « saute » plus vers un
placement valide.

- **`updatePreview`** pose TOUJOURS à l'ancre désirée (`_calculateDesiredAnchorFromDrag`), sans snap ;
  `isPreviewValid` = appartenance à `validPlacements` (déjà calculé pièce exclue).
- **Suppression** de `_findClosestValidPlacement` et `_gestureAxis` (l'aimantation et l'heuristique
  d'axe, devenues inutiles) — fix **soustractif**.
- **Feedback sous le doigt réactif** (plateau + tiroir) : **image réelle si posable, transparent si
  chevauchement** (un `Consumer` sur `isPreviewValid`, se reconstruit à chaque coup). Le **fantôme du
  plateau** garde son vert/rouge.
- **Effet de bord corrigé le même jour** : le plafond de case était **absolu** (`kMaxBoardCellSize=84`)
  et **rapetissait tout sur tablette** (grand écran → tout rogné à 84). Rendu **proportionnel**
  (`kMaxBoardCellFactor=0.215`, `maxBoardCellSize(context)` = `shortestSide × facteur`) : ≈84 sur
  iPhone, plein écran sur tablette.

`analyze lib test` **0/0**, **55/55 tests**. **Testé OK sur tablette 9×5 par Paul** (le drag suit le
doigt, les plateaux remplissent l'écran). Valeurs `à régler à l'œil` : `kMaxBoardCellFactor`,
`kPieceToBoardCellRatio`. *(Les deux sections historiques ci-dessous peuvent être élaguées à la
prochaine passe.)*

- **Confinement de l'ancre (2026-09-08, testé OK par Paul, `44b9c04`)** — effet de bord du retrait de
  l'aimantation : une **grande pièce** (Paul : la N°8) glissée au ras d'un bord — surtout le **bas**,
  collé au rack — **débordait** hors du plateau → aperçu rouge, dépôt refusé, obligeant à poser
  ailleurs puis repositionner (« en 2 temps »). `_clampAnchorToBoard` borne l'ancre à
  `x ∈ [0, W−larg]`, `y ∈ [0, H−haut]` (boîte englobante de l'orientation courante), appliqué aux deux
  cas (rack + pièce posée déplacée). **Pas** un retour à l'aimantation vers un emplacement VALIDE : le
  suivi du doigt est inchangé à l'intérieur, les chevauchements restent rouges — la pièce ne peut plus
  sortir de la table. `analyze` 0/0, 55/55.

- **Pose de la ligne du bas — acceptation du dépôt au bord (2026-09-09, testé OK par Paul)** — le
  confinement corrigeait le débordement de l'aperçu, mais **pas l'acceptation du dépôt** : le plateau
  est ancré en bas (design #6) → sa ligne du bas est **collée** à la cible de drop du rack. Viser une
  case basse (surtout en empoignant une case basse de la pièce) faisait relâcher au ras/au-dessus du
  rack. Deux causes conjuguées : (1) `pentoscope_board.dart` `onLeave` **appelait `clearPreview()`**
  (contredisant son propre commentaire) → l'ancre `previewX/Y` était effacée dès que le doigt
  effleurait le rack ; (2) le rack (`_buildSliderWithDragTarget`) **rejetait** une pièce venue du rack
  (`onWillAccept → selectedPlacedPiece != null`) → au relâcher, **aucune** cible n'acceptait, geste
  perdu (« s'y reprendre à plusieurs fois »). Correctif, **câblage des drop-targets uniquement** (la
  géométrie de pose — `updatePreview`/`tryPlaceAtAnchor`/clamp — est **inchangée**) : (1) `onLeave` ne
  fait **plus** `clearPreview` (l'aperçu valide survit) ; (2) le rack accepte aussi une pièce **du
  rack** quand un aperçu valide est en attente (`selectedPiece != null && previewX/Y != null &&
  isPreviewValid`) et la **pose** via `tryPlaceAtAnchor` ; rouge/poubelle réservés au **retrait** d'une
  pièce déjà placée. `analyze` 0/0, 67/67. **Non couvert** (à traiter si rencontré) : *déplacer une
  pièce **déjà posée** vers la ligne du bas* retombe sur le même bord, mais là lâcher sur le rack =
  retrait volontaire.

- **Ligne du bas — CAUSE RACINE trouvée et corrigée (2026-09-09, testé OK par Paul).** Les correctifs
  ci-dessus (rack-coopération, marge) aidaient sans suffire : la pose du bas restait **aléatoire** sur
  un grand plateau (5×7). Diagnostic de Paul (« ça vient des mouvements du doigt ») + lecture du
  pipeline : le **feedback de drag est rendu à l'échelle du RACK** (petit, `≈0,26×case plateau`) et la
  `dragAnchorStrategy` l'ancre par la case empoignée → `details.offset = doigt − localGrab` (px rack).
  `onMove` mappait ce point **à l'échelle du plateau** sans ré-ajouter `localGrab` → l'ancre se
  décalait de **~0-1 case selon la ligne empoignée** (et la hauteur de la pièce), non rattrapable au
  bord bas. **Correctif** : le slider passe `localGrab` au provider (`selectPiece(grabLocal:)` →
  `dragGrabLocal`) et `onMove` **reconstruit le doigt réel** `details.offset + localGrab` → `ancre =
  caseDoigt − caseEmpoignée` (la case empoignée tombe exactement sous le doigt). **Portrait + pièce du
  rack seulement** (paysage = swap d'axes ; pièce posée = branche `masterAbs`, inchangés). `analyze`
  0/0, 67/67. **Testé OK par Paul.** C'est LA correction qui rend la ligne du bas fiable.

- **Marge latérale du plateau (2026-09-09, retour de Paul, testé OK).** Un grand plateau (5×n, 6×10)
  prenait toute la largeur (≈4 pt de marge) → avec le suivi 1:1, positionner près d'un bord amenait le
  doigt contre le biseau. `kBoardSideMargin = 26 pt/côté` (portrait) réservé au plateau **et** à
  `_barMetrics` (§3). N'affecte que les plateaux **limités par la largeur** (les petits, plafonnés par
  `maxCell`, gardent leur taille). Constante « à régler à l'œil ».

- **Sensibilité du drag (2026-09-09, retour de Paul).** `longPressDuration` défaut **200 → 100 ms** ;
  réglage Params borné **50-200** (pas de 50 ; setter clampé). *Une valeur déjà persistée sur l'appareil
  ne change pas seule — à réajuster une fois via les −/+.*

- **Orientation du rack conservée (2026-09-09, retour de Paul).** `cancelSelection` commit
  `selectedPositionIndex` dans `piecePositionIndices` pour une pièce du rack → un drag annulé (relâché
  hors cible) **garde** l'orientation donnée au lieu de revenir à l'initiale. (Cause : `_applyIsoUsingLookup`
  CAS 1 ne mettait à jour que `selectedPositionIndex` ; `cycleToNextOrientation`, qui committait, était mort.)

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

### Menu d'entrée = hub de navigation (2026-09-05, choix de Paul)

L'accueil devient le **hub** : sous « Jouer » (solo/progression), un **bouton « Multijoueur »** (→
lobby duel) ; l'en-tête garde **Défi 🚩 / Records 🏆 / Réglages ⚙️**. La **barre du jeu solo** est
**allégée** : bouton **« Accueil » 🏠** (retour au menu, `popUntil isFirst`), et **retrait** du
multijoueur (people) et des **Réglages** (déplacés sur l'accueil). Le joueur part toujours du menu,
choisit solo/multi, et revient au menu depuis le solo. `analyze` 0/0, 50/50.

### Vignette d'accueil (2026-09-05) — « une pièce, deux isométries, une pose »

L'animation-démo a été **remplacée** (choix de Paul, après avis), **disposition du vrai jeu** :
**barre d'isométrie EN HAUT** (vraies icônes `GameIcons`, surlignées pendant chaque isométrie),
**plateau au milieu** (vide, avec une **case-cible fantôme**), **rack EN BAS** contenant **toutes les
pièces** du tirage en minis. Une pièce (la démo) est **sélectionnée** (halo) → **rotation** (iso 1) →
**miroir** (iso 2) → **montée** du rack jusqu'à sa case. Boucle **~10 s** (ralentie, avec pauses) en
changeant de tirage/pièce. **Pièces symétriques** (ex. le U) : la 2e isométrie devient une **2e
rotation** (`_mirrorChanges` : le miroir ne serait pas visible) → jamais d'isométrie sans effet ;
l'icône surlignée suit (rotation vs miroir). But : onboarding **et** mise
en avant de la barre d'isométrie (découvrabilité, `REFERENCE_ISOMETRIES §4` : 42,9 % des 1res parties
insolubles sans le miroir). Constantes de réglage : `_kLoopMs`, `_kSelectEnd`, `_kIso1End`, `_kIso2End`,
`_kRiseEnd` dans `home_screen.dart`. `analyze` 0/0, 50/50. **À valider sur device** (timing, tailles,
lisibilité du flip).

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

> ⚠️ **Détails « coups » (`bestMoves`, `pièces + 2·retraits`) SUPERSÉDÉS par la refonte « A »
> (2026-09-05)** : le maillot Coups est remplacé par **Fautes**. L'acuité et le rack initial
> ci-dessous restent valides (l'acuité est désormais **plafonnée à 100 %**). Voir §ÉTAT en tête.

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

### Compteur Help — maillot blanc (2026-09-04) — ⚠️ SUPERSÉDÉ par la refonte « A » (2026-09-05)

> Cette section décrit le 4e maillot blanc **tel qu'il a existé du 2026-09-04 au 2026-09-05**. La
> refonte « A » l'a **fusionné avec Coups** en un seul maillot 🔴 **Fautes** (`helpCount`→
> `faultCount`, `bestHelp`+`bestMoves`→`bestFaults`, schéma **10**). L'insight qui autorise la
> fusion : à la complétion, sauvetages (rouge→jaune) = fautes (jaune→rouge). Conservée pour la trace.

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

`INDICATEURS_OBSERVATION.md` (neuf, 2026-09-07) — référence de **tous les indicateurs du bandeau debug**
(compteurs bruts 🔄🔴↔️🚑, classification des fautes ⚠️🌫️Σg + gravité, diagnostic courant). Outil de
test/observation, gated `kShowLiveCounters` (à couper avant publication). S'appuie sur `fault_analysis.dart`.

`MANUEL_DEFIS_ET_MAILLOTS.md` (neuf 2026-09-05, **réécrit le 2026-09-05** pour la refonte « A ») —
manuel de référence **faisant foi** : défi perso (records locaux) vs défi réseau (classement en
ligne), et le **mode de calcul exact des trois maillots** (acuité **plafonnée**, fautes, temps) + la
médaille + le bilan « avec aide ». Ancré sur l'implémentation et `CDC §4`/`§7`.

`CLOUDFLARE_CONFIG.md` (neuf, 2026-09-05) — mémo opérationnel de l'infra Cloudflare : les deux
workers (duel WebSocket *hors dépôt* ; défi `pentapol-defi` dans `server/`), la config exacte (URL,
base D1 `7ea667b1…`, secret `SEED_TOKEN`), le flux de données, et les commandes courantes (déployer,
init D1, secret, semer, inspecter/purger). Le `SEED_TOKEN` n'y figure pas (secret non relisible).

`BASE_LOCALE.md` (neuf, 2026-09-05) — miroir côté appareil : la base drift/SQLite locale
(`pentapol_settings.db`, `schemaVersion 10`, réécriture destructive), les quatre tables (`Settings` =
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

**2026-09-10 — CLI (ergonomie du jeu : PLAN_ERGONOMIE_ICONES + refonte carte de fin). Commité et poussé ce jour.**
Session pilotée en direct par Paul, testée bloc par bloc sur device. Commits `3dde2e8`
(§0 : push de `c31685c`, captures `screenshot/` + plan committés), `9b73a4d` (bloc 2),
`0203871` (bloc 3), plus le commit de refonte de la carte de fin (ce commit).
- **Bloc 2** (décisions 8/9/10, C1/C7/C9) : chrono `m:ss` ; compteur de solutions = chiffre seul +
  tooltip (glyphe retiré à la demande de Paul) ; `kShowLiveCounters=false` → coin haut-gauche « rien
  ou total » selon `showCounters`, bande debug débranchée (**C9 / checklist 22 FAIT**) ; invariant
  « le plateau reste toujours légal » porté dans `CLAUDE.md` §Invariants #7.
- **Bloc 3** (décisions 6/7, C5/C6/C8) : taille du rack pilotée par le réglage **live**
  `GameSettings.rackCellRatio` (stepper Réglages 0.30-0.60, défaut figé **0.46** après calibrage
  device), miniature de drag alignée ; **emplacement à la largeur réelle** (boîte carrée = dimension
  max, pas de reflow) → 3×5 montre ses 3 pièces ; **fondu de bord** sensible au défilement (C6) ;
  **pastille unique** par pièce posée (C8) agrandie, réglage `showPieceNumbers` (défaut on). Checklist :
  point 23 (trancher `rackCellRatio` avant store), point 16 mis à jour.
- **Refonte carte de fin** (hors plan, demande de Paul) : plus de « Résolu »/« Vision parfaite » —
  **animation d'étoiles 1-3** (`_SuccessStars`, palier : 3=parfait acuité 100 % + 0 faute, 2=0 faute,
  1=résolu/aide) + **bouton infos** repliant le détail (isométries/temps/fautes/acuité). `_BilanCard`
  → Stateful. `_PerfectBadge` supprimé.
- **Reste du PLAN_ERGONOMIE_ICONES** (NON fait) : **décision 4** (nommage par axe + réalignement
  noms/glyphes croisés `swap_vert`/`swap_horiz`), **bloc 4** (vignettes du résultat sur les 4 boutons
  d'isométrie + grisage préventif, décisions 1/2/3), **bloc 5** (rangée d'isométrie réservée au-dessus
  du rack + AppBar permanente, les **−11 %** de surface, décision 5). Le plan reste dans `docs/` tant
  qu'il n'est pas entièrement appliqué et testé.
- `analyze` 0/0, **67/67** à chaque commit. **Reste : test device** de la carte de fin (fait par Paul,
  OK) et de l'ensemble.

**2026-09-09 (4) — CLI (entraînement Option A + réglage « compteurs » + accueil hub). Commité ce jour.**
Trois demandes de Paul en une session, commitées ensemble. (a) **Mode entraînement Option A** :
`training_screen`/`training_provider` supprimés, l'état passe dans `pentoscope_provider.startTraining()`
et l'affichage réutilise `PentoscopeGameScreen` ; plateau 5×5 → **5×7**. (b) **Réglage « compteurs »**
(`AppSettings.showCounters`, défaut off, JSON sans migration) : overlay isométries/fautes en haut-gauche
de la barre de jeu. (c) **Accueil = hub d'icônes** : titre « PENTAPOL » et les 3 gros boutons du bas
retirés ; en-tête avec **Jouer (person) vert, gros, centré** (Stack), Multijoueur/Entraînement à gauche,
défi/records/réglages à droite. `analyze` 0/0, **67/67 tests**. Plan `docs/PLAN_MODE_ENTRAINEMENT.md`
committé avec le code. **Reste : test device de tout ça par Paul** — puis le niveau 2 de l'entraînement.
Détail en §ÉTAT « Entraînement Option A + réglage compteurs + accueil hub ».

**2026-09-09 (3) — CLI (ergonomie du drag : ancre à la bonne échelle + marge + sensibilité + orientation). Commité `c0f3255`, testé OK par Paul.**
Suite du retour de Paul sur la pose de la ligne du bas, qui restait **aléatoire** sur grand plateau
malgré (2). **CAUSE RACINE trouvée** (piste de Paul « ça vient des mouvements du doigt ») : le feedback
de drag est à l'échelle du RACK, `details.offset = doigt − localGrab` (px rack), et `onMove` mappait ce
point en case **plateau** sans ré-ajouter `localGrab` → ancre décalée ~0-1 case selon la prise, fatale
au bord bas. **Correctif d'échelle** : `selectPiece(grabLocal:)` → `dragGrabLocal` ; `onMove` reconstruit
le doigt réel `details.offset + localGrab` (portrait + rack seulement). **Testé OK par Paul.** Plus, même
session, trois retours : **marge latérale** `kBoardSideMargin` (26 pt/côté, grand plateau ne prend plus
toute la largeur), **sensibilité** `longPressDuration` défaut 100 ms / plage 50-200, **orientation du
rack conservée** au drag annulé (`cancelSelection` commit). `analyze` 0/0, **67/67**. Détail en §ÉTAT
« Ligne du bas — CAUSE RACINE ». Build `202609090737`.

*(Les passations du 2026-09-09 (2), 2026-09-08 et antérieures sont sorties de la liste au fil des ajouts ; elles
restent dans `git log` et leurs décisions vivent dans `CAHIER_DES_CHARGES_V1.md` et le §ÉTAT.)*
