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

## Qualificatif public facultatif — 2026-11-11

Migration appliquée et worker déployé le 2026-11-11 06:43 CET ; les 141 scores
existants sont conservés. Version déployée : `384b2a33-d42d-42e6-b459-96bbf1dcfef5`.

`POST /score` accepte désormais `qualifier` (facultatif, 20 caractères maximum,
même alphabet que le pseudo). Les classements jour/semaine/mois le renvoient
séparément. Les anciens clients et anciens scores conservent `null`.
Le qualificatif est attaché au score lors de l’envoi ; le modifier dans les
Paramètres concerne les prochains scores, sans modifier les scores déjà soumis.

Sur la base existante, appliquer **une seule fois** la migration additive avant
de déployer le worker. Vérifier d’abord `PRAGMA table_info(scores)` : si la
colonne `qualifier` existe déjà, ne pas rejouer cette migration.

```bash
npx wrangler d1 execute pentapol-defi --remote --file=migrations/20261111_player_qualifier.sql
npm run deploy
```

Ne pas utiliser `schema.sql` : il détruirait les scores existants.
La suppression RGPD des scores supprime aussi leurs qualificatifs.

## Remise à zéro des scores depuis Cloudflare

Procédure de développement, ajoutée le 2026-10-07 à la demande de Paul.
Dans le tableau de bord Cloudflare, ouvrir **Storage & Databases → D1 → pentapol-defi**,
puis l'onglet **Console**. La suppression est définitive : choisir une seule des deux options.

Pour supprimer uniquement les anciens scores et conserver ceux des défis version 3 :

```sql
DELETE FROM scores WHERE version < 3;
```

Pour vider tous les scores, y compris ceux de la version 3 :

```sql
DELETE FROM scores;
```

Vérifier ensuite les scores restants par version :

```sql
SELECT version, COUNT(*) AS nombre
FROM scores
GROUP BY version;
```

Après une suppression complète, cette requête ne doit retourner aucune ligne.
Ces commandes ne modifient ni la table `challenges`, ni les réglages, l'identité ou
les résultats locaux des joueurs. Des clients conservant des scores en attente peuvent
les renvoyer : la nouvelle app réinitialise les anciens défis et leur file locale avec
la révision 3, mais les anciens clients doivent être mis à jour pour éviter ce renvoi.
Ne pas utiliser `schema.sql` pour cette opération : il recrée aussi la table `challenges`.
En cas de refus d'accès CLI Cloudflare (7403), utiliser la console avec un compte ayant
accès à cette base ; l'erreur ne constitue pas une confirmation de suppression.

## Protocole

Base URL = l'URL du worker déployé.

Depuis la version de défi **3** (2026-10-07), l'app dérive localement le même puzzle
prérempli depuis la date UTC, la taille et le corpus versionné, avec ou sans réseau.
Un ensemble minimal de pièces fixes isole une solution exacte, en laissant au moins
la moitié des pièces à jouer. Les indices ne comptent ni dans les coups ni dans le
minimum théorique. Le réseau transporte les résultats, pas une variante du puzzle.
Les scores version 2 restent séparés par la partition `version` ; aucune migration D1
ni nouveau schéma n'est nécessaire. Les endpoints de composition restent disponibles
pour les anciens clients/outils, mais ne remplacent plus les défis quotidiens version 3.

- **`POST /score`** — enregistre l'essai (unique par joueur/défi, §7.1). Corps JSON :
  ```json
  { "version": 3, "day": "2026-10-07", "size": 1, "playerId": "<32 hex>", "pseudo": "Paul",
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


## Ceintures dans les classements — 2026-11-17

`POST /score` accepte `belt` facultatif : entier de 0 (blanche) à 6 (noire).
L'app l'envoie après la sauvegarde du passage, uniquement avec le consentement
existant. Les renvois hors ligne conservent cette donnée. Les anciens clients
restent compatibles et les anciens scores gardent NULL : aucun grade inventé.
`GET /leaderboard` renvoie la plus haute ceinture connue du joueur, tous ses
scores confondus, sur jour/semaine/mois et Temps/Stratégie. Un doublon peut
actualiser cette métadonnée sans remplacer le temps ni changer le rang (409).
Le modèle de confiance client reste identique à celui des mesures de jeu.

Appliquer une seule fois `migrations/20261117_player_belt.sql` à D1 avant de
déployer le Worker. Cette migration ajoute une colonne nullable et un index,
sans toucher aux résultats existants. **Ne pas utiliser schema.sql en production**.
La ceinture des autres joueurs devient connue après un score envoyé avec la
nouvelle app. La ligne du joueur connecté utilise sa ceinture locale actuelle.
