# Serveur du défi quotidien — Pentapol

Worker Cloudflare + base D1 pour le **classement du défi quotidien**. Asynchrone :
**POST d'un score**, **GET d'un tableau**. Rien à voir avec le worker duel (WebSocket + Durable
Objects) ; ici aucun Durable Object.

> Base recréée et worker déployé par le CLI le 2026-10-05, à la demande de Paul.

## Vérification — modèle de confiance (décision Paul, 2026-09-04)

L'app **mesure** le temps et les cinq compteurs d'actions localement ; le joueur ne saisit
rien → il ne peut pas tricher via le jeu. Le seul vecteur résiduel est un **POST forgé** hors de
l'app (`curl` sur l'endpoint public) ; jugé négligeable pour une app payante à petite population.
Le serveur vérifie les entiers et la cohérence du total ; SQLite calcule la somme des cinq
compteurs. Il conserve la grille (`scores.grid`) pour vérifier le pavage hors ligne.
La grille finale ne permet pas de reconstruire les gestes ni le temps ; ces mesures restent
fondées sur la confiance dans l'app.

## Déploiement

Prérequis : Node + `npm i` (installe `wrangler`), et `wrangler login`.

```bash
cd server
npm install

# 1) Créer la base D1 et coller l'id retourné dans wrangler.toml (database_id).
npx wrangler d1 create pentapol-defi

# 2) Créer les tables (distant).
npm run db:init:remote        # = wrangler d1 execute pentapol-defi --remote --file=schema.sql

# 3) Jeton d'amorçage des définitions (protège la table challenges — voir plus bas).
npx wrangler secret put SEED_TOKEN

# 4) Déployer.
npm run deploy
```

En local : `npm run db:init:local` puis `npm run dev`.

## Protocole

Base URL = l'URL du worker déployé.

- **`POST /score`** — enregistre l'essai (unique par joueur/défi, §7.1). Corps JSON :
  ```json
  { "version": 2, "day": "2026-09-24", "size": 1, "playerId": "<32 hex>", "pseudo": "Paul",
    "timeMs": 92000, "strategyActions": 10, "theoreticalMoves": 6, "finalSolutionMinimum": true,
    "actionCounts": { "placement": 4, "rotation": 2, "symmetry": 1, "translation": 2, "removal": 1 },
    "grid": "<ids par case>" }
  ```
  `201` si enregistré ; `409` si un essai existe déjà (premier essai seulement) ; `400` si invalide.
  Avec aide, `strategyActions`, `actionCounts` et `theoreticalMoves` sont null : seul le temps est classé.

- **`DELETE /score?playerId=<32 hex>`** — suppression RGPD (CDC §7.4) : efface **toutes** les lignes
  du joueur (toutes semaines/tailles/versions). `200 { "ok": true, "deleted": <n> }`. Non authentifié :
  le `playerId` est un secret 128 bits connu du seul propriétaire → n'expose que ses propres données
  (même modèle de confiance que `POST /score`). Appelé par le bouton « Supprimer mes données de
  classement » des Réglages.

- **`GET /leaderboard?version=&day=&size=&maillot=&limit=`** — tableau trié.
  `maillot` vaut `temps` (vert) ou `strategie` (jaune).
  Stratégie trie `strategy_actions / theoretical_moves` croissant, puis le temps. Chaque pose (y compris la première),
  rotation, symétrie, déplacement sur le plateau et effacement compte pour un coup ; les
  tentatives refusées comptent aussi. Les scores sans minimum final et les parties aidées
  ne participent qu'au classement Temps.
  Réponse : `{ "maillot": "...", "entries": [ { player_id, pseudo, time_ms, strategy_actions, theoretical_moves, placements, rotations, symmetries, translations, removals }, ... ] }`.
  L'app affiche `strategy_actions/theoretical_moves`, sans pourcentage. Le minimum est calculé
  pour la solution finale obtenue, depuis les orientations initiales du tiroir : une pose par
  pièce plus les transformations minimales. `finalSolutionMinimum: true` identifie cette règle ;
  un minimum global envoyé par une ancienne app n'est pas utilisé pour Stratégie.
  En semaine/mois, le ratio porte sur les sommes des coups théoriques et joués des jours retenus,
  en excluant les résultats sans repère théorique comparable.
  Ajouter `period=week` ou `period=month` retourne les points agrégés sur les 5 ou 20 meilleurs
  jours ; `period=day` est la valeur par défaut.

- **`GET /challenge?version=&day=&size=`** — définition composée : `{ mask, rack, solutionCount }`, ou
  `404` si non définie (le client retombe alors sur sa dérivation locale).

- **`POST /challenge`** — sème une définition (`{version, day, size, mask, rack, solutionCount}`).
  `INSERT OR IGNORE` (idempotent, premier semeur gagne). **Exige `Authorization: Bearer <SEED_TOKEN>`**
  si le secret est défini.

## Composition à la main & amorçage — note de sécurité

En phase de développement, Paul demande le 2026-10-06 de repartir de tables vides avec
la règle du minimum propre à la solution finale. Appliquer `schema.sql` de façon destructive,
sans migration ni reprise historique. Cette procédure est interdite après publication.

Paul autorise le 2026-10-05 la destruction de l'ancien contenu réseau.
Appliquer `wrangler d1 execute pentapol-defi --remote --file=schema.sql`, puis déployer le worker.
Le schéma conserve le temps et cinq compteurs de gestes. Le total Stratégie est une colonne
calculée par SQLite, égale à leur somme. Les parties aidées ont des compteurs null.

CDC §7 Acté 1 veut des défis **composables à la main** (autorité serveur), et Acté 1bis un
**amorçage paresseux par le premier joueur**. Tension : si `POST /challenge` est **ouvert**, un POST
forgé pourrait **empoisonner** la définition d'une semaine avant le premier joueur honnête.

Choix retenu ici : **`POST /challenge` est gardé par `SEED_TOKEN`.** Conséquence :
- Les définitions sont posées par **toi** (composition à la main) ou par un **job de confiance** —
  un petit script Dart qui exécute `deriveChallenge` (le défaut algorithmique) et POST le résultat
  avec le jeton, pour les semaines non composées. C'est le rôle qu'aurait joué le « premier
  joueur », déplacé vers un semeur de confiance.
- L'amorçage **ouvert par le premier joueur** (Acté 1bis) reste possible en **retirant la garde**
  (ne pas définir `SEED_TOKEN`), au prix du risque d'empoisonnement — **non recommandé**. À
  reconsigner dans le CDC si tu changes d'avis.

## Côté app — fait

- **Identité 128 bits** (`ensurePlayerId`), **soumission auto** du score à la complétion d'un défi,
  et **fetch de la définition composée** (`GET /challenge`, repli sur la dérivation locale).
- **Phase 5 (UI)** : `LeaderboardScreen` — quatre classements (onglets), joueur courant surligné,
  dégradation gracieuse (§7.8).

## Semer les défis d'une journée

Le semeur Dart dérive les neuf tailles du jour et les envoie au Worker :

```bash
# depuis la racine du dépôt (pas server/)
dart run tools/seed_challenges.dart --dry-run --day=2026-09-24

# sème la semaine courante — le token vient de --token OU de l'environnement :
export SEED_TOKEN=…                                          # (recommandé : hors ligne de commande)
dart run tools/seed_challenges.dart
# … ou en une fois, sans le laisser dans l'historique du shell :
SEED_TOKEN=… dart run tools/seed_challenges.dart
# … ou explicitement :
dart run tools/seed_challenges.dart --token=<SEED_TOKEN>
```

Le token est lu depuis `--token` en priorité, sinon depuis la **variable d'environnement
`SEED_TOKEN`** — préférer l'environnement pour ne pas l'exposer sur la ligne de commande. Le semeur
**auto-contrôle** sa dérivation contre le digest gelé du test (refuse de tourner s'il a divergé
de `lib/challenge.dart`). Pour **composer à la main** une journée, POST ta propre définition avec
le même en-tête `Authorization: Bearer <SEED_TOKEN>`.
