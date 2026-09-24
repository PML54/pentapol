# Cloudflare — configuration et fonctionnement (Pentapol)

> Mémo opérationnel : ce qui tourne sur Cloudflare pour Pentapol, la config exacte, le flux de
> données, et les commandes courantes. Source de vérité : `server/` (worker + schéma + wrangler).

---

## 1. Vue d'ensemble — DEUX workers distincts

Pentapol utilise **deux** services Cloudflare **indépendants**, sur le **même compte**
(`paulmarie.lariviere@gmail.com`, sous-domaine **`pentapml`**) :

| Worker | Rôle | Techno | Source |
|---|---|---|---|
| **`pentapol-duel`** | duel temps réel (multijoueur) | WebSocket + **Durable Objects** | *hors dépôt* |
| **`pentapol-defi`** | classement du défi quotidien | HTTP + **D1** (POST/GET) | **`server/`** dans ce dépôt |

Ils ne partagent **rien** sauf le compte Cloudflare. Ce mémo concerne le **worker défi**
(`pentapol-defi`). Le worker duel est déployé ailleurs et n'est pas géré ici.

---

## 2. Le worker défi — coordonnées

| Champ | Valeur |
|---|---|
| Nom du worker | `pentapol-defi` |
| URL publique | `https://pentapol-defi.pentapml.workers.dev` |
| Base D1 (nom) | `pentapol-defi` |
| Base D1 (id) | `7ea667b1-22ec-4cb9-afcd-7dd42541da41` |
| Secret | `SEED_TOKEN` (écriture seule, non relisible) |
| `compatibility_date` | `2026-01-01` |
| Code | `server/src/index.ts`, `server/schema.sql`, `server/wrangler.toml` |

> Le `database_id` (UUID) est **public** — il vit en clair dans `wrangler.toml`, dans le dépôt. Ce
> n'est **pas** un secret. Le seul secret est `SEED_TOKEN`.

---

## 3. La base D1 — deux tables

Schéma dans `server/schema.sql`.

### Worker et D1 : deux rôles différents

Le **Worker** est le programme serveur de Pentapol. Il reçoit les demandes de l'application,
contrôle leur contenu, puis lit ou écrit les données. C'est le guichet :

- il accepte un score terminé avec `POST /score` ;
- il refuse un nom invalide ou un second résultat pour le même défi ;
- il calcule et renvoie les classements jour, semaine et mois ;
- il permet la suppression des données d'un joueur.

**D1** est la base de données persistante placée derrière le Worker. C'est le registre : elle
conserve les définitions officielles et les résultats. L'application mobile ne dialogue jamais
directement avec D1 ; elle passe toujours par le Worker.

Conséquence opérationnelle importante :

- `npm run deploy` met à jour le Worker et **conserve les données** ;
- `npm run db:init:remote` applique `schema.sql`. Le schéma de développement actuel commence par
  supprimer puis recréer les tables : cette commande **efface les défis et les scores**.

Pour activer une nouvelle vérification serveur, comme les règles sur les noms, utiliser uniquement
`npm run deploy`. Ne pas réinitialiser D1.

### `scores` — les résultats des joueurs

Un **résultat par joueur et par défi** (clé primaire `(version, day, size, player_id)`). Colonnes :
les valeurs brutes (`min_iso`, `iso_count`, `moves`, `faults`, `time_ms`), le `pseudo`, l'identité
`player_id` (128 bits), la `grid` (grille terminée, conservée pour audit), `created_at`.

### `challenges` — les définitions (optionnel)

La définition `(taille, masque, rack, nombre de solutions)` d'un défi, indexée par
`(version, day, size)`. **Vide par défaut** : l'app dérive la config elle-même. Ne se remplit que si
tu **composes/semences** des défis
(voir §6).

Il n'est pas nécessaire de semer une définition chaque jour. En l'absence de ligne dans
`challenges`, tous les téléphones dérivent automatiquement le même défi depuis la date UTC. Le
semeur sert uniquement à figer ou remplacer exceptionnellement cette définition côté serveur.

---

## 4. Endpoints (API HTTP)

Base = `https://pentapol-defi.pentapml.workers.dev`

| Méthode | Route | Rôle | Auth |
|---|---|---|---|
| `POST` | `/score` | enregistre un score (201 ; 409 si déjà soumis) | — |
| `DELETE` | `/score?playerId=` | suppression RGPD : efface toutes les lignes du joueur (200) | — |
| `GET` | `/leaderboard?version=&day=&size=&maillot=&period=` | classement (`temps`, `acuite` ou `coups`; période `day`, `week` ou `month`) | — |
| `GET` | `/challenge?version=&day=&size=` | définition officielle ou 404 | — |
| `POST` | `/challenge` | pose/compose une définition | **`Bearer SEED_TOKEN`** |

Seul `POST /challenge` exige le token. Tout le reste (jouer, envoyer un score, lire un classement)
est public — c'est ce qui fait que **le classement marche sans rien configurer de plus**.

---

## 5. Flux de données (comment ça marche)

1. **Le joueur ouvre un défi** `(jour UTC, taille)`. L'app tente `GET /challenge` ; si 404 (non
   composé), elle **dérive** la config localement (même résultat pour tous, sans réseau).
2. **Il joue** en mode classé (l'app mesure acuité, coups et temps ; la lampe est inactive).
3. **À la fin**, l'app `POST /score` avec son identité 128 bits, son nom et la grille.
4. Le **Worker valide** notamment le nom (3 à 20 caractères), puis demande à D1 d'insérer le score.
5. **Il consulte** `GET /leaderboard` — son score y apparaît, surligné.

Le serveur **fait confiance** aux chiffres (l'app mesure, le joueur ne saisit rien) et **garde la
grille** pour un audit éventuel. Il ne recalcule pas les scores.

---

## 6. Commandes courantes

Toujours depuis `server/` (sauf le semeur, depuis la racine). Prérequis : `npm install`,
`npx wrangler login`.

### Déployer / mettre à jour le Worker
```bash
cd server
npm run deploy                 # = npx wrangler deploy → affiche l'URL
```

### Réinitialiser les tables — destructif
```bash
npm run db:init:remote         # EFFACE puis recrée challenges et scores
```

### Poser / changer le secret d'amorçage
```bash
npx wrangler secret put SEED_TOKEN     # écrit une valeur (écrase l'ancienne). NON relisible.
# valeur solide : openssl rand -hex 32
```

### Semer une journée (optionnel — définitions dans `challenges`)
```bash
# depuis la RACINE du dépôt :
dart run tools/seed_challenges.dart --dry-run --day=2026-09-24
export SEED_TOKEN=…                                        # token via l'environnement (recommandé)
dart run tools/seed_challenges.dart                        # sème la journée courante
# (équivaut à --token=… ; --token est prioritaire s'il est passé)
```

### Inspecter / purger la base (SQL direct)
```bash
npx wrangler d1 execute pentapol-defi --remote --command "SELECT COUNT(*) FROM scores"
npx wrangler d1 execute pentapol-defi --remote --command "DELETE FROM scores WHERE pseudo='Test'"
npx wrangler d1 info pentapol-defi     # infos + id de la base
npx wrangler d1 list                   # toutes tes bases D1
```

### Vérifier que le worker répond (sans rien installer)
```bash
curl "https://pentapol-defi.pentapml.workers.dev/leaderboard?version=2&day=2026-09-24&size=0&maillot=temps&period=day"
# → {"maillot":"temps","entries":[...]}
```

---

## 7. Secrets & sécurité

- **`SEED_TOKEN`** : seul secret. Posé par `wrangler secret put`, **non relisible** (ni CLI ni
  dashboard). Si oublié → en reposer un neuf (ça écrase). Ne le mets **jamais** dans `wrangler.toml`
  ni dans le dépôt.
- Le `database_id` n'est **pas** un secret (public).
- Ne colle jamais le `SEED_TOKEN` dans une conversation, un commit, ou un fichier suivi par git.

---

## 8. Coût

`pentapol-defi` tient largement dans les **paliers gratuits** de Cloudflare (Workers : 100 000
requêtes/jour ; D1 : lectures/écritures généreuses en gratuit) pour une app à petite population. À
surveiller seulement si le trafic explose.

---

## 9. Où vit le code

- **`server/src/index.ts`** — le Worker et ses endpoints HTTP.
- **`server/schema.sql`** — les tables D1.
- **`server/wrangler.toml`** — nom, `database_id`, binding.
- **`server/README.md`** — guide de déploiement détaillé + note de sécurité.
- **`tools/seed_challenges.dart`** — le semeur (dérive + POST, auto-contrôlé).
- **`docs/MANUEL_DEFIS_ET_MAILLOTS.md`** — le fonctionnement côté joueur (maillots, défi perso/réseau).
