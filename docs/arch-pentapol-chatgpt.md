# Architecture de Pentapol

## 1. Vue d'ensemble

Pentapol est une application mobile Flutter, destinée à iOS et Android. Son architecture repose sur quatre ensembles principaux :

- l'interface et la logique de jeu en Flutter/Dart ;
- la gestion d'état avec Riverpod ;
- la persistance locale avec Drift et SQLite ;
- deux services Cloudflare pour les défis et le mode multijoueur.

```text
Application Flutter
├── Interface utilisateur
├── Moteur et état du jeu
├── Données statiques pré-calculées
├── Base locale Drift / SQLite
└── Services distants Cloudflare
    ├── Défis et classements : Worker + D1
    └── Duels multijoueurs : Worker + Durable Objects + WebSocket
```

Le point d'entrée est `lib/main.dart`. L'application démarre dans un `ProviderScope`, charge les préférences, tente de restaurer une partie locale, puis affiche l'écran d'accueil.

Lors du passage en arrière-plan, elle met le chronomètre en pause et sauvegarde la partie courante. Au retour au premier plan, elle reprend le chronomètre.

## 2. Technologies principales

| Domaine | Technologie |
| --- | --- |
| Application mobile | Flutter / Dart |
| Plateformes | iOS et Android |
| Gestion d'état | Riverpod 3 |
| Base locale | SQLite avec Drift 2.29 |
| Modèles immuables | Freezed |
| Traductions | Flutter Localizations et fichiers ARB français/anglais |
| Backend des défis | Cloudflare Worker + D1 |
| Backend multijoueur | Cloudflare Worker + Durable Objects + WebSocket |

## 3. Modules Flutter

### `lib/common/`

Socle partagé du jeu :

- définition des pentominos ;
- plateau, points et pièces placées ;
- symétries des pièces ;
- comportements partagés de manipulation des pièces ;
- logique commune de partie et de chronomètre ;
- génération aléatoire ;
- composants graphiques communs pour le plateau et le glisser-déposer.

### `lib/services/`

Services de chargement et de recherche des solutions pré-calculées, notamment pour les grilles 6 x 10.

L'application livrée ne résout pas les puzzles par backtracking en temps réel. Elle s'appuie sur des tables de solutions embarquées.

### `lib/pentoscope/`

Module principal du jeu. Il contient notamment :

- l'état central et les actions de jeu ;
- la génération des parties ;
- le choix des sources de solutions ;
- les règles de score ;
- l'analyse géométrique et les erreurs ;
- les métriques de fin de partie ;
- le mode défi ;
- les écrans et composants visuels du jeu.

Les tailles prises en charge vont de 3 x 5 à 5 x 10, ainsi que 6 x 10.

### `lib/pentoscope_multiplayer/`

Mode duel en ligne :

- modèles multijoueurs ;
- état de la salle et de la partie ;
- connexion WebSocket ;
- synchronisation du duel ;
- écrans de lobby, de partie et de résultat.

Ce module réutilise l'état principal de jeu fourni par `pentoscopeProvider`.

### `lib/database/`

Définition de la base locale Drift, migrations et accès aux données persistantes.

### `lib/providers/`

Providers transversaux, principalement la base locale et les paramètres de l'application.

### `lib/models/`

Modèles de données immuables, en particulier `AppSettings`, générés avec Freezed et sérialisables en JSON.

### `lib/screens/`

Écrans généraux qui ne dépendent pas directement d'un mode de jeu :

- paramètres ;
- personnalisation des couleurs ;
- réglages géométriques.

### `lib/config/`

Configuration de l'interface : couleurs, icônes, dimensions et constantes visuelles.

### `lib/utils/`

Fonctions utilitaires et outils géométriques.

### `lib/l10n/`

Traductions françaises et anglaises, avec fichiers ARB et classes générées par Flutter.

### `lib/data/`

Documentation ou données relatives au backend. Ce dossier ne contient pas de logique Dart centrale.

## 4. Providers Riverpod

### `settingsDatabaseProvider`

Type : `Provider<SettingsDatabase>`

Expose l'instance de la base locale Drift utilisée par l'application.

### `settingsProvider`

Type : `NotifierProvider<SettingsNotifier, AppSettings>`

Gère les préférences globales de l'application. Elles sont sérialisées en JSON et enregistrées dans la base locale sous la clé `app_settings`.

Les paramètres comprennent notamment :

- les préférences d'interface et de jeu ;
- le niveau courant ;
- le nom du joueur ;
- l'identifiant du joueur ;
- les préférences du mode duel ;
- la langue ;
- le consentement au partage des scores.

### `pentoscopeProvider`

Type : `NotifierProvider<PentoscopeNotifier, PentoscopeState>`

Provider central du jeu. Il gère notamment :

- la partie courante ;
- le placement et la suppression des pièces ;
- les compteurs et le chronomètre ;
- les scores et les fautes ;
- les indices ;
- les défis ;
- la sauvegarde et la restauration d'une partie.

### `pentoscopeSolutionsProvider`

Type : `FutureProvider.family<SolutionMatcher, SolutionTable>`

Charge à la demande une table de solutions, principalement pour les puzzles 6 x 10.

### `tirageCorpusProvider`

Type : `FutureProvider<TirageCorpus>`

Charge le corpus embarqué utilisé pour les tirages des formats 5 x n.

### `dragOverBoardProvider`

Type : `NotifierProvider<DragOverBoardNotifier, bool>`

Gère un état temporaire d'interface indiquant qu'une pièce survolée par glisser-déposer se trouve au-dessus du plateau.

### `pentoscopeMPProvider`

Type : `NotifierProvider<PentoscopeMPNotifier, PentoscopeMPState>`

Gère le mode multijoueur :

- salle de duel ;
- connexion WebSocket ;
- synchronisation des joueurs ;
- progression et résultat de la partie.

## 5. Données statiques embarquées

Les solutions et statistiques pré-calculées sont fournies avec l'application :

| Fichier | Rôle |
| --- | --- |
| `assets/data/solutions_6x10_normalisees.bin` | Solutions normalisées des grilles 6 x 10 |
| `assets/data/subset_counts.bin` | Comptages de sous-ensembles utilisés par la logique du jeu |
| `assets/data/solutions_corpus.bin` | Corpus de solutions pour les tirages |

Cette approche évite de faire tourner un solveur complet sur le téléphone pendant une partie.

## 6. Base de données locale

La base locale est un fichier SQLite nommé `pentapol_settings.db`, placé dans le répertoire de documents de l'application.

Elle est déclarée dans `lib/database/settings_database.dart` avec Drift. Sa version de schéma actuelle est `11`.

La stratégie de migration utilise actuellement un remplacement destructif de la base en cas de changement incompatible. Ce choix est indiqué comme temporaire pour la phase de prépublication et devra être remplacé avant une diffusion publique stable.

### Table `Settings`

Stockage générique clé/valeur :

| Colonne | Rôle |
| --- | --- |
| `key` | Clé primaire |
| `value` | Valeur texte, généralement du JSON |

La principale entrée est `app_settings`, contenant l'ensemble des préférences de l'application.

### Table `CurrentGame`

Sauvegarde unique de la partie courante, avec un identifiant fixe égal à `0`.

Elle contient notamment :

- la taille du plateau ;
- les pièces du tirage ;
- le nombre de solutions ;
- les pièces placées ;
- l'état géométrique ;
- les positions et orientations ;
- le temps écoulé ;
- les nombres d'isométries, translations, suppressions, indices et fautes ;
- le mode progression ;
- la date de sauvegarde.

Cette sauvegarde sert à reprendre une partie solo normale. Elle n'est pas utilisée pour les duels multijoueurs ni pour les défis.

### Table `SolvedSolutions`

Historique des rectangles entièrement résolus.

Clé primaire composite : `board` et `solutionNumber`.

Elle conserve notamment :

- le nombre de résolutions ;
- les meilleurs scores d'acuité et d'isométrie ;
- le plus petit nombre de fautes ;
- le meilleur temps ;
- les dates de première et dernière résolution.

### Table `PuzzleStats`

Statistiques agrégées par taille de puzzle :

- nombre de parties terminées ;
- meilleure acuité ;
- meilleur nombre de fautes ;
- meilleur temps.

## 7. Backend des défis

Le service `pentapol-defi` utilise un Cloudflare Worker et une base Cloudflare D1.

Le code est situé dans `server/`, principalement dans :

- `server/src/index.ts` ;
- `server/schema.sql` ;
- `server/wrangler.toml`.

URL du service : `https://pentapol-defi.pentapml.workers.dev`

Base D1 :

- nom : `pentapol-defi` ;
- liaison Worker : `DB` ;
- identifiant : `7ea667b1-22ec-4cb9-afcd-7dd42541da41`.

Le secret `SEED_TOKEN`, utilisé pour alimenter les défis, n'est pas conservé dans le dépôt.

### Table distante `challenges`

Contient les défis hebdomadaires, identifiés par :

- la version ;
- la semaine ;
- la taille.

Elle conserve également le masque et le tirage du défi.

### Table distante `scores`

Contient un score par joueur et par défi. Elle enregistre notamment :

- l'identifiant et le pseudonyme du joueur ;
- les scores d'isométrie ;
- les fautes ;
- le temps ;
- la grille finale, conservée pour contrôle ;
- la date de création.

Le serveur reçoit les mesures calculées par le client. La grille enregistrée permet un audit, mais les valeurs ne sont pas entièrement recalculées côté serveur.

### API des défis

| Méthode et route | Fonction |
| --- | --- |
| `POST /score` | Enregistrer un score |
| `DELETE /score?playerId=...` | Supprimer les données d'un joueur |
| `GET /leaderboard` | Lire un classement |
| `GET /challenge` | Lire un défi |
| `POST /challenge` | Créer ou alimenter un défi avec authentification |

Lors du premier envoi de score autorisé, l'application génère si nécessaire un identifiant joueur aléatoire de 128 bits.

## 8. Backend multijoueur

Le service `pentapol-duel` est distinct du backend des défis. Il repose sur :

- un Cloudflare Worker ;
- des Durable Objects pour conserver l'état des salles ;
- des connexions WebSocket pour les échanges en temps réel.

Le client correspondant se trouve dans `lib/pentoscope_multiplayer/`. Le code serveur du duel n'est pas géré dans ce dépôt.

## 9. Flux principal de l'application

```text
Démarrage
  ↓
Initialisation de Flutter et de Riverpod
  ↓
Chargement des paramètres locaux
  ↓
Détermination du niveau et de la taille de départ
  ↓
Recherche d'une partie sauvegardée
  ├── Partie trouvée : restauration
  └── Aucune partie : création d'un nouveau puzzle
  ↓
Affichage de l'accueil et du jeu
  ↓
Sauvegarde automatique lors du passage en arrière-plan
```

Pour un défi, l'application échange avec le Worker et la base D1. Pour un duel, elle utilise le service WebSocket associé aux Durable Objects.

## 10. Résumé des responsabilités

| Élément | Responsabilité |
| --- | --- |
| `common` | Objets et comportements fondamentaux du jeu |
| `services` | Chargement et recherche dans les solutions pré-calculées |
| `pentoscope` | Jeu solo, génération, score et défis |
| `pentoscope_multiplayer` | Duels en ligne et synchronisation temps réel |
| `providers` | Exposition des états transversaux avec Riverpod |
| `database` | Persistance locale Drift / SQLite |
| `models` | Modèles immuables et sérialisation |
| `screens`, `config`, `l10n` | Interface, thème et traductions |
| Cloudflare D1 | Défis et classements persistants |
| Durable Objects | Salles et état du multijoueur en temps réel |
