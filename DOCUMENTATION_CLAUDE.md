# 📚 DOCUMENTATION PENTAPOL - Claude

**Dernière mise à jour : 7 novembre 2024**

---

## 🎯 1. PRÉSENTATION DU PROJET

### Description
**Pentapol** est une application Flutter de courses de puzzles (pentominos) en temps réel.

- **Backend** : Supabase (authentification, base de données PostgreSQL, Realtime)
- **Frontend** : Flutter avec Riverpod pour la gestion d'état
- **Plateforme** : Multi-plateforme (iOS, Android, Web, Desktop)

### Repository GitHub
- **URL** : https://github.com/PML54/pentapol
- **Propriétaire** : PML54
- **Branche principale** : main
- **Description** : "Pentamino network"

---

## 📁 2. STRUCTURE DU PROJET

### Fichiers Dart principaux (10 fichiers)

#### Point d'entrée
1. **lib/main.dart**
   - Point d'entrée de l'application
   - Initialisation de Supabase
   - Configuration de l'application Flutter avec Riverpod
   - Gestion de la navigation conditionnelle (AuthScreen vs HomeScreen)
   - Thème Material 3

2. **lib/bootstrap.dart**
   - Configuration et initialisation de Supabase
   - URL : `https://qawvjbxwoxwpxlcufhjp.supabase.co`
   - Configuration Realtime (10 événements/seconde)

#### Modèles de données
3. **lib/models.dart**
   - **Race** : Modèle pour les courses (id, puzzleId, createdBy, status)
   - **RaceResult** : Modèle pour les résultats (playerId, elapsedMs, piecesPlaced, finishedAt)
   - Sérialisation/désérialisation JSON

#### Couche données (Repository Pattern)
4. **lib/data/race_repo.dart**
   - **RaceRepo** : Repository pour la gestion des courses via Supabase
   - Méthodes :
     - `createRace()` : Créer une nouvelle course
     - `myRaces()` : Récupérer les courses de l'utilisateur
     - `joinRace()` : Rejoindre une course existante
     - `finishRace()` : Terminer une course avec résultats
     - `fetchLeaderboard()` : Récupérer le classement d'une course

#### Logique métier
5. **lib/logic/race_presence.dart**
   - **RacePresence** : Gestion de la présence en temps réel pour les courses
   - Utilise Supabase Realtime Channels
   - Méthodes :
     - `open()` : Ouvrir un canal Realtime
     - `subscribeInitial()` : S'abonner avec état initial
     - `updateProgress()` : Mettre à jour la progression
     - `players()` : Récupérer la liste des joueurs triés
     - `close()` : Fermer la connexion

#### Écrans (Screens)
6. **lib/screens/auth_screen.dart**
   - Écran d'authentification (connexion/inscription)
   - Formulaire email/mot de passe
   - Gestion des états de chargement et d'erreur

7. **lib/screens/home_screen.dart**
   - Écran principal avec liste des courses
   - Création de nouvelles courses
   - Navigation vers les courses en direct

8. **lib/screens/home_screen.dart** (RaceLiveScreen)
   - Écran de course en temps réel
   - Affichage de la progression des joueurs
   - Placement de pièces
   - Gestion de la présence Realtime

9. **lib/screens/leaderboard_screen.dart**
   - Affichage du classement des courses
   - Tri par temps (elapsed_ms)
   - Identification du joueur actuel
   - Formatage des temps et informations

#### Utilitaires
10. **lib/utils/time_format.dart**
    - `formatMillis()` : Conversion millisecondes → format MM:SS.mmm
    - Formatage avec padding pour l'affichage

#### Tests
11. **test/widget_test.dart**
    - Test de widget basique (template Flutter par défaut)
    - ⚠️ Note : Ce test ne correspond pas à l'application actuelle

---

## 🗄️ 3. BASE DE DONNÉES SUPABASE

### Informations de connexion
- **URL** : https://qawvjbxwoxwpxlcufhjp.supabase.co
- **Project Reference** : qawvjbxwoxwpxlcufhjp
- **Région** : Stockholm (eu-north-1)
- **Type** : PostgreSQL
- **Database Password** : `<VOTRE_DB_PASSWORD>` (stocké en local dans mcp.json)

### Tables (8 tables)

1. **races**
   - Stocke les courses
   - Colonnes : id, puzzle_id, created_by, status, started_at
   - Status possibles : 'running', 'finished'

2. **race_results**
   - Résultats des courses terminées
   - Colonnes : race_id, player_id, elapsed_ms, pieces_placed, finished_at

3. **race_participants**
   - Participants aux courses
   - Colonnes : race_id, player_id

4. **profiles**
   - Profils utilisateurs

5. **messages**
   - Messages (probablement pour un chat)

6. **progress**
   - Progression

7. **rooms**
   - Salles

8. **room_members**
   - Membres des salles

### Statistiques actuelles (7 novembre 2024)
- **Courses en cours** : 2 (status = 'running')
- **Courses terminées** : 0 (status = 'finished')

---

## 🔧 4. CONFIGURATION GIT

### Historique
- **Initialisation** : 7 novembre 2024
- **Premier commit** : "Initial commit: Pentapol Flutter app with Supabase integration"
- **Hash** : 6ff2881
- **Fichiers** : 141 fichiers, 6513 insertions

### Commandes Git utiles
```bash
# Voir le statut
git status

# Ajouter des modifications
git add .

# Commiter
git commit -m "Votre message"

# Pousser vers GitHub
git push

# Voir l'historique
git log --oneline
```

---

## 🤖 5. MCP SERVERS (Model Context Protocol)

### Qu'est-ce qu'un MCP Server ?
Un protocole qui permet à Claude (l'IA) de se connecter à des outils et sources de données externes de manière standardisée.

**Analogie** : Donner des super-pouvoirs à l'IA
- Sans MCP : Claude peut seulement parler et conseiller
- Avec MCP : Claude peut agir directement sur vos outils

### Configuration
**Fichier** : `/Users/pml/.cursor/mcp.json`

### Les 3 MCP Servers configurés

#### 1. Dart MCP Server
```json
{
  "type": "stdio",
  "command": "dart mcp-server --experimental-mcp-server --force-roots-fallback"
}
```
**Fonctionnalités** :
- Analyse de code Flutter/Dart
- Détection d'erreurs
- Suggestions de refactoring

#### 2. GitHub MCP Server
```json
{
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "<VOTRE_GITHUB_TOKEN>"
  }
}
```
**Fonctionnalités** :
- Créer/gérer des issues
- Gérer les pull requests
- Consulter l'historique des commits
- Gérer les branches
- Lire et modifier les fichiers du repository

**Token GitHub** : `<VOTRE_GITHUB_TOKEN>` (configuré dans `/Users/pml/.cursor/mcp.json`)

#### 3. PostgreSQL/Supabase MCP Server
```json
{
  "type": "stdio",
  "command": "npx",
  "args": [
    "-y",
    "@modelcontextprotocol/server-postgres",
    "postgresql://postgres:<VOTRE_DB_PASSWORD>@db.qawvjbxwoxwpxlcufhjp.supabase.co:5432/postgres"
  ]
}
```
**Fonctionnalités** :
- Exécuter des requêtes SQL directement
- Consulter les tables et leur structure
- Analyser les données de courses
- Créer/modifier des tables
- Gérer les migrations de base de données

### Exemples d'utilisation

**Avec GitHub** :
```
"Crée une issue pour ajouter la fonctionnalité de chat"
"Liste mes pull requests ouvertes"
"Montre-moi les commits de cette semaine"
```

**Avec Supabase** :
```
"Combien de courses sont en cours ?"
"Montre-moi la structure de la table races"
"Crée une requête pour le top 10 des joueurs"
```

---

## 🏗️ 6. ARCHITECTURE & PATTERNS

### Repository Pattern

**Définition** : Une couche intermédiaire entre l'interface utilisateur et la base de données.

**Analogie** : Le vendeur dans un magasin
- Vous (client) ne allez pas directement dans l'entrepôt
- Vous passez par le vendeur (Repository)
- Le vendeur gère l'accès aux données (entrepôt)

**Architecture en couches** :
```
PRESENTATION (UI/Screens)
    ↓
BUSINESS LOGIC (Repositories)
    ↓
DATA SOURCE (Supabase/API)
```

**Avantages** :
- ✅ Code propre et organisé
- ✅ Facile à tester
- ✅ Facile à modifier
- ✅ Réutilisable
- ✅ Séparation des responsabilités

**Exemple dans Pentapol** :
```dart
// Au lieu de mettre le code Supabase partout
// On centralise dans RaceRepo
class RaceRepo {
  Future<Race> createRace({required String puzzleId}) { ... }
  Future<List<Race>> myRaces() { ... }
  Future<void> joinRace(String raceId) { ... }
}
```

---

## 🗄️ 7. POSTGRESQL & SUPABASE

### Qu'est-ce que PostgreSQL ?
**PostgreSQL** (Postgres) est un système de base de données SQL puissant et gratuit (open source).

**Comparaison avec Oracle** :

| Aspect | PostgreSQL | Oracle |
|--------|------------|--------|
| Prix | 💰 Gratuit | 💰💰💰 Très cher |
| Type | Open Source | Commercial |
| Usage | Startups, web, mobile | Grandes entreprises, banques |
| SQL | Compatible SQL standard | Compatible SQL standard |
| Puissance | Très puissant | Extrêmement puissant |

### Relation avec Supabase

**Supabase = Voiture complète**
```
SUPABASE
├─ PostgreSQL (Moteur - base de données)
├─ Interface web (Tableau de bord)
├─ API REST (Transmission)
└─ Auth/Storage/Realtime (Accessoires)
```

**Supabase utilise PostgreSQL comme moteur de base de données.**

Le SQL est presque identique entre PostgreSQL et Oracle !

---

## 🤖 8. CLAUDE - L'INTELLIGENCE ARTIFICIELLE

### Identité
- **Nom** : Claude 3.5 Sonnet
- **Créateur** : Anthropic
- **Spécialités** : Code, raisonnement complexe, utilisation d'outils

### Ce que Claude N'EST PAS
- ❌ Claude n'est PAS ChatGPT (OpenAI)
- ❌ Claude ne travaille PAS avec ChatGPT
- ❌ Claude ne sous-traite à AUCUNE autre IA
- ❌ Claude ne communique JAMAIS avec d'autres IA

### Architecture
```
VOUS (Cursor)
    ↓
CLAUDE (Une seule IA)
    ↓
    ├─> Outil GitHub MCP
    ├─> Outil Supabase MCP
    ├─> Outil Dart MCP
    └─> Autres outils
```

**Claude est UNE seule IA qui utilise des outils, comme un humain utilise un marteau.**

### Comparaison des IA

| IA | Créateur | Où ? |
|----|----------|------|
| **Claude** | Anthropic | Cursor, Claude.ai |
| ChatGPT | OpenAI | ChatGPT.com |
| Gemini | Google | Google.com |
| Copilot | Microsoft | GitHub, Windows |

---

## 💎 9. ABONNEMENTS

### Claude Pro - 20$/mois
- **Plateforme** : claude.ai (interface web)
- **Avantages** :
  - ~5x plus de messages que gratuit
  - Accès prioritaire
  - Nouvelles fonctionnalités en premier
  - Conversations plus longues
  - Analyse d'images/documents
- **Usage recommandé** : Questions générales, brainstorming, documentation

### Cursor Pro - 20$/mois
- **Plateforme** : Cursor IDE
- **Avantages** :
  - 500 requêtes Claude par mois
  - MCP servers activés
  - Autocomplétion avancée
  - Cmd+K illimité
- **Usage recommandé** : Développement de Pentapol

### Total : 40$/mois

**Important** : Les deux abonnements sont SÉPARÉS et INDÉPENDANTS
- ❌ Ne partagent pas les quotas
- ❌ Ne communiquent pas entre eux
- ✅ Deux sessions complètement différentes

---

## 🎯 10. STRATÉGIE D'UTILISATION

### Utilisez Cursor (avec Claude) pour :
- ✅ Développer Pentapol
- ✅ Modifier des fichiers de code
- ✅ Gérer GitHub (issues, PRs, commits)
- ✅ Requêtes Supabase (SQL)
- ✅ Debugging et refactoring
- ✅ Analyse de code

### Utilisez Claude.ai pour :
- ✅ Brainstorming de nouvelles fonctionnalités
- ✅ Apprendre Flutter/Dart (tutoriels)
- ✅ Rédiger la documentation
- ✅ Planifier l'architecture
- ✅ Questions générales
- ✅ Analyse d'images/documents

---

## ⚠️ 11. SÉCURITÉ

### Fichiers sensibles
- **Fichier MCP** : `/Users/pml/.cursor/mcp.json`
- ⚠️ Contient des tokens et mots de passe
- ⚠️ Ne JAMAIS commiter dans Git
- ✅ Situé dans `~/.cursor/` donc hors du projet (sécurisé)

### Credentials à protéger

#### GitHub Token
```
<VOTRE_GITHUB_TOKEN>
```
- **Type** : Personal Access Token
- **Permissions** : repo, read:org, read:user
- **Localisation** : `/Users/pml/.cursor/mcp.json` (en local uniquement)
- **Si compromis** : Révoquer sur GitHub Settings > Developer settings > Tokens

#### Database Password
```
<VOTRE_DB_PASSWORD>
```
- **Type** : PostgreSQL password
- **Localisation** : `/Users/pml/.cursor/mcp.json` (en local uniquement)
- **Si compromis** : Réinitialiser dans Supabase Settings > Database

### Bonnes pratiques
- ✅ Ne jamais partager les tokens publiquement
- ✅ Ne jamais commiter les credentials dans Git
- ✅ Utiliser des variables d'environnement pour les secrets
- ✅ Révoquer et recréer les tokens régulièrement

---

## 🚀 12. PROCHAINES ÉTAPES POSSIBLES

### Fonctionnalités à développer
1. **Système de chat** (tables messages/rooms déjà présentes)
2. **Profils utilisateurs enrichis**
3. **Historique des courses**
4. **Statistiques des joueurs**
5. **Différents types de puzzles**
6. **Mode solo vs multijoueur**
7. **Système de points/achievements**
8. **Invitations à des courses**

### Améliorations techniques
1. **Tests unitaires** pour les repositories
2. **Tests d'intégration** pour les écrans
3. **Gestion d'erreurs** améliorée
4. **Internationalisation** (i18n) - fichiers l10n déjà présents
5. **Optimisation des performances**
6. **Gestion du cache**
7. **Mode offline**

### DevOps
1. **CI/CD** avec GitHub Actions
2. **Déploiement automatique**
3. **Monitoring et analytics**
4. **Gestion des versions**

---

## 📞 13. COMMENT INTERAGIR AVEC CLAUDE

### Pour le code
```
"Ajoute une fonctionnalité X dans le fichier Y"
"Refactorise la classe Z pour améliorer la lisibilité"
"Corrige le bug dans la fonction W"
"Crée un nouveau widget pour afficher X"
```

### Pour GitHub
```
"Crée une issue pour ajouter le système de chat"
"Liste mes pull requests ouvertes"
"Montre les commits de la semaine dernière"
"Crée une branche feature/chat"
```

### Pour Supabase
```
"Combien de courses sont en cours ?"
"Montre la structure de la table races"
"Crée une requête pour le top 10 des joueurs"
"Ajoute une colonne 'difficulty' à la table races"
```

### Pour l'analyse
```
"Analyse les performances de l'application"
"Trouve les points d'amélioration dans le code"
"Vérifie s'il y a des problèmes de sécurité"
"Suggère des optimisations"
```

---

## 📚 14. GLOSSAIRE

### Termes techniques

**Flutter** : Framework de développement d'applications multi-plateformes créé par Google.

**Dart** : Langage de programmation utilisé par Flutter.

**Riverpod** : Bibliothèque de gestion d'état pour Flutter.

**Supabase** : Backend-as-a-Service (BaaS) open source, alternative à Firebase.

**PostgreSQL** : Système de gestion de base de données relationnelle open source.

**Repository Pattern** : Pattern de conception qui sépare la logique d'accès aux données de la logique métier.

**MCP (Model Context Protocol)** : Protocole permettant aux IA de se connecter à des outils externes.

**Realtime** : Fonctionnalité de Supabase permettant la synchronisation en temps réel.

**Widget** : Élément de base de l'interface utilisateur dans Flutter.

**Stateful/Stateless Widget** : Types de widgets Flutter (avec ou sans état).

---

## 📝 15. NOTES DE VERSION

### Version actuelle : 0.1.0 (MVP)

**Fonctionnalités implémentées** :
- ✅ Authentification (connexion/inscription)
- ✅ Création de courses
- ✅ Participation aux courses
- ✅ Suivi en temps réel de la progression
- ✅ Leaderboard
- ✅ Formatage des temps

**Limitations connues** :
- ⚠️ Pas de gestion des erreurs réseau
- ⚠️ Pas de mode offline
- ⚠️ Pas de tests automatisés
- ⚠️ Interface basique (à améliorer)
- ⚠️ Un seul type de puzzle

---

## 🔗 16. LIENS UTILES

### Documentation officielle
- **Flutter** : https://flutter.dev/docs
- **Dart** : https://dart.dev/guides
- **Supabase** : https://supabase.com/docs
- **Riverpod** : https://riverpod.dev/docs

### Ressources
- **GitHub Pentapol** : https://github.com/PML54/pentapol
- **Supabase Dashboard** : https://supabase.com/dashboard
- **Claude.ai** : https://claude.ai
- **Cursor** : https://cursor.sh

### Communautés
- **Flutter Discord** : https://discord.gg/flutter
- **Supabase Discord** : https://discord.supabase.com

---

## 📅 17. HISTORIQUE DES MODIFICATIONS

### 7 novembre 2024
- ✅ Création initiale du projet
- ✅ Configuration Git et GitHub
- ✅ Configuration des MCP servers (Dart, GitHub, Supabase)
- ✅ Connexion à la base de données Supabase
- ✅ Création de cette documentation

---

## 🎯 18. TODO / ROADMAP

### Court terme (1-2 semaines)
- [ ] Améliorer la gestion des erreurs
- [ ] Ajouter des tests unitaires
- [ ] Améliorer l'UI/UX
- [ ] Ajouter l'internationalisation (FR/EN)

### Moyen terme (1-2 mois)
- [ ] Implémenter le système de chat
- [ ] Ajouter les profils utilisateurs enrichis
- [ ] Créer différents types de puzzles
- [ ] Ajouter un système de points

### Long terme (3-6 mois)
- [ ] Mode offline
- [ ] Notifications push
- [ ] Système d'achievements
- [ ] Tournois et compétitions

---

**📌 Ce document est maintenu à jour par Claude lors de chaque modification significative du projet.**

**Pour toute question, demandez à Claude dans Cursor !** 🤖💙

