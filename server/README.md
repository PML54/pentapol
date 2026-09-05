# Serveur du défi de la semaine — Pentapol (Phase 4)

Worker Cloudflare + base D1 pour le **classement du défi de la semaine** (CDC §7). Asynchrone :
**POST d'un score**, **GET d'un tableau**. Rien à voir avec le worker duel (WebSocket + Durable
Objects) ; ici aucun Durable Object.

> ⚠️ **Écrit par le CLI, à déployer par Paul.** Le CLI n'a pas accès au compte Cloudflare et ne
> peut ni déployer ni tester ce service. Les étapes ci-dessous sont à exécuter par toi.

## Vérification — modèle de confiance (décision Paul, 2026-09-04)

L'app **mesure** les trois valeurs (acuité plafonnée, fautes, temps) localement ; le joueur ne saisit
rien → il ne peut pas tricher via le jeu. Le seul vecteur résiduel est un **POST forgé** hors de
l'app (`curl` sur l'endpoint public) ; jugé négligeable pour une app payante à petite population.
**Le serveur ne recalcule donc pas `minIso`** (on évite le portage en JS de la géométrie + du BFS
d'isométries). Il **conserve la grille** (`scores.grid`) : si un classement paraît louche, un outil
Dart pourra recalculer *a posteriori* (« infalsifiable » → « auditable »). Durcir plus tard si la
triche devient réelle.

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
  { "version": 1, "week": 35, "size": 1, "playerId": "<32 hex>", "pseudo": "Paul",
    "minIso": 4, "isoCount": 5, "faults": 2, "timeMs": 92000, "grid": "<ids par case>" }
  ```
  `201` si enregistré ; `409` si un essai existe déjà (premier essai seulement) ; `400` si invalide.

- **`GET /leaderboard?version=&week=&size=&maillot=&limit=`** — tableau trié.
  `maillot` ∈ `jaune` (acuité ↓, plafonnée à 100 %), `pois` (fautes ↑), `vert` (temps ↑).
  Réponse : `{ "maillot": "...", "entries": [ { player_id, pseudo, min_iso, iso_count, faults, time_ms }, ... ] }`.

- **`GET /challenge?version=&week=&size=`** — définition composée à la main : `{ mask, rack }`, ou
  `404` si non définie (le client retombe alors sur sa dérivation locale).

- **`POST /challenge`** — sème/compose une définition (`{version, week, size, mask, rack}`).
  `INSERT OR IGNORE` (idempotent, premier semeur gagne). **Exige `Authorization: Bearer <SEED_TOKEN>`**
  si le secret est défini.

## Composition à la main & amorçage — note de sécurité

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

## Semer les défis d'une semaine

Pour remplir les semaines **non composées à la main** (le serveur a alors le rack pour l'audit, et
tout est cohérent avec ce que le client dérive), un semeur Dart dérive les six défis et les POST :

```bash
# depuis la racine du dépôt (pas server/)
dart run tools/seed_challenges.dart --dry-run --week=35      # aperçu, ne POST pas

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
de `lib/challenge.dart`). Pour **composer à la main** une semaine, POST ta propre définition
`{version, week, size, mask, rack}` avec le même en-tête `Authorization: Bearer <SEED_TOKEN>`.
