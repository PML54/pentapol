# BILAN DUEL ISOMÉTRIES - État au 3 décembre 2025

> ⚠️ **Encadré ajouté le 2026-08-29 — ce document est VIVANT, ne pas le supprimer.**
> Le « duel isométries » est le mode multijoueur actuel ; le client s'appelle désormais
> `lib/pentoscope_multiplayer/`. Vérification : même serveur
> `pentapol-duel.pentapml.workers.dev`, même `roomCode`, même WebSocket. Avec
> `DUEL_ISOM_ARCH.md`, c'est la seule trace du protocole serveur, absent de ce dépôt.
> L'état daté « 3 décembre 2025 » porte sur l'avancement, pas sur l'architecture.

## 🎯 OBJECTIF

Mode de jeu multijoueur 1v1 où deux joueurs doivent reconstituer le même puzzle de pentominos en appliquant des isométries (rotations, symétries). Le gagnant est celui qui utilise le moins d'isométries, ou en cas d'égalité, le plus rapide.

---

## 🏗️ ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARCHITECTURE SEED-BASED                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│   CLIENT 1 (Flutter)              SERVEUR (Cloudflare)           │
│   ──────────────────              ────────────────────           │
│                                                                   │
│   POST /room/create ─────────────> Crée DuelIsometryRoom         │
│                      <───────────── {roomCode: "ABCD"}           │
│                                                                   │
│   WS /room/ABCD/ws  ─────────────> Connexion WebSocket           │
│                      <───────────── {type: "room_created"}       │
│                                                                   │
│                                                                   │
│   CLIENT 2 (Flutter)                                             │
│   ──────────────────                                             │
│                                                                   │
│   GET /room/ABCD/exists ─────────> Vérifie existence             │
│                         <───────── {exists: true}                │
│                                                                   │
│   WS /room/ABCD/ws  ─────────────> Connexion WebSocket           │
│                      <───────────── {type: "room_joined"}        │
│                                                                   │
│   ══════════════════════════════════════════════════════════     │
│   QUAND 2 JOUEURS CONNECTÉS :                                    │
│   ══════════════════════════════════════════════════════════     │
│                                                                   │
│   Serveur génère SEED ───────────> {type: "puzzle_ready",        │
│                                     seed: 1733195523000,         │
│                                     pieceCount: 3}               │
│                                                                   │
│   Client génère puzzle localement :                              │
│   IsometryPuzzle.generate(seed: 1733195523000, width: 3)         │
│                                                                   │
│   → Les 2 clients ont EXACTEMENT le même puzzle                  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

**Principe clé** : Le serveur ne connaît RIEN des pentominos. Il génère juste un `seed` (timestamp). Chaque client utilise ce seed pour générer le puzzle localement avec `Random(seed)`, garantissant des puzzles identiques.

---

## 📁 STRUCTURE DES FICHIERS

### Serveur (Cloudflare Workers)

```
~/StudioProjects/pentapol-server/
├── src/
│   ├── index.ts              # Router HTTP + WebSocket
│   ├── duel-room.ts          # Duel Classique (existant)
│   └── duel-isometry-room.ts # Duel Isométries (NOUVEAU)
├── wrangler.toml             # Config Cloudflare
├── tsconfig.json
└── package.json
```

### Client Flutter

```
~/StudioProjects/pentapol/lib/duel_isometry/
├── models/
│   ├── duel_isometry_state.dart     # États du jeu
│   └── duel_isometry_messages.dart  # Messages WebSocket
├── providers/
│   └── duel_isometry_provider.dart  # Logique Riverpod
├── screens/
│   ├── duel_isometry_screen.dart    # Écran de jeu principal
│   ├── duel_isometry_lobby.dart     # Écran d'accueil (existant)
│   └── duel_isometry_result_screen.dart # Résultats (existant)
├── services/
│   ├── isometry_puzzle.dart         # Générateur de puzzles (EXISTANT)
│   └── isometry_utils.dart          # Utilitaires (EXISTANT)
└── widgets/
    └── duel_isometry_countdown.dart # Widget countdown (existant)
```

---

## 📋 ÉTAT DES FICHIERS

### ✅ SERVEUR - Fichiers fonctionnels

#### wrangler.toml
```toml
name = "pentapol-duel"
main = "src/index.ts"
compatibility_date = "2024-01-01"

[vars]
GAME_TIME_LIMIT = "180"

[durable_objects]
bindings = [
  { name = "DUEL_ROOM", class_name = "DuelRoom" },
  { name = "DUEL_ISOMETRY_ROOM", class_name = "DuelIsometryRoom" }
]

[[migrations]]
tag = "v1"
new_classes = ["DuelRoom"]

[[migrations]]
tag = "v2"
new_sqlite_classes = ["DuelIsometryRoom"]
```

#### index.ts (points clés)
- Route `POST /room/create` avec paramètre `gameMode` ("classic" | "isometry")
- Route `GET /room/:code/exists` cherche dans les 2 namespaces
- Route `GET /room/:code/ws` pour WebSocket (auto-détecte le mode)
- CORS headers pour toutes les réponses

#### duel-isometry-room.ts (Durable Object)
- Gère l'état de la partie en mémoire
- Problème d'hibernation : les WebSockets sont perdus entre les requêtes
- Utilise `state.storage.put()` pour persister le roomCode
- Devrait utiliser `serializeAttachment()` / `deserializeAttachment()` pour les joueurs
- Messages en **snake_case** : `room_created`, `room_joined`, `puzzle_ready`, etc.

### ⚠️ CLIENT - Fichiers à corriger

#### duel_isometry_messages.dart
Format simplifié pour correspondre au serveur :
```dart
// PuzzleReadyMessage attend maintenant :
// - seed (int)
// - pieceCount (int)
// - roundNumber, totalRounds, timeLimit
// Plus de: width, height, pieces[], optimalIsometries
```

#### duel_isometry_provider.dart
```dart
void _handlePuzzleReady(PuzzleReadyMessage msg) {
  // GÉNÉRATION CÔTÉ CLIENT avec le seed du serveur
  final puzzle = IsometryPuzzle.generate(
    width: msg.pieceCount,  // width = nombre de pièces
    height: 5,              // hauteur fixe
    seed: msg.seed,
  );
  // ...
}
```

#### duel_isometry_screen.dart
- Manque la méthode `_buildWaitingScreen()` pour l'écran d'attente
- Doit vérifier `state.gameState == DuelIsometryGameState.waiting` avant d'afficher le jeu

---

## 🔴 PROBLÈMES IDENTIFIÉS

### 1. Hibernation des Durable Objects
**Symptôme** : Le 2ème joueur ne peut pas rejoindre la room  
**Cause** : Cloudflare "hibernate" les DO entre les requêtes, les WebSockets et l'état en mémoire sont perdus  
**Solution partielle** :
- Persister `roomCode` avec `state.storage.put()`
- Utiliser `getWebSockets()` + `serializeAttachment()` pour restaurer les joueurs
- Pas complètement résolu

### 2. Format des messages
**Symptôme** : Erreur de parsing `type 'Null' is not a subtype of type 'int'`  
**Cause** : Le client attend l'ancien format (width, height, pieces[]) mais le serveur envoie le nouveau (seed, pieceCount)  
**Solution** : Mettre à jour `duel_isometry_messages.dart` et `duel_isometry_provider.dart`

### 3. Affichage du puzzle
**Symptôme** : Grille mal rendue, miniatures vides  
**Cause** : Le puzzle n'est pas correctement généré ou transmis à l'UI  
**À investiguer** : `_initializeGame()`, liaison avec `state.puzzle`

### 4. Écran d'attente
**Symptôme** : Pas d'affichage du code de room  
**Cause** : Méthode `_buildWaitingScreen()` manquante  
**Solution** : Ajouter la méthode et le check du state `waiting`

---

## 📝 MESSAGES WEBSOCKET

### Client → Serveur
| Type | Payload | Quand |
|------|---------|-------|
| `create_room` | `{playerName}` | Création |
| `join_room` | `{playerName, roomCode}` | Rejoindre |
| `progress` | `{placedPieces, isometryCount}` | Pendant le jeu |
| `completed` | `{isometryCount, completionTime}` | Puzzle terminé |

### Serveur → Client
| Type | Payload | Quand |
|------|---------|-------|
| `room_created` | `{roomCode, playerId}` | Room créée |
| `room_joined` | `{roomCode, playerId, opponentId?, opponentName?}` | Room rejointe |
| `player_joined` | `{playerId, playerName}` | Adversaire rejoint |
| `puzzle_ready` | `{roundNumber, totalRounds, seed, pieceCount, timeLimit}` | Début round |
| `countdown` | `{value}` | Décompte 3,2,1 |
| `round_start` | `{roundNumber}` | Go ! |
| `opponent_progress` | `{placedPieces, isometryCount}` | Update adversaire |
| `player_completed` | `{playerId, isometryCount, completionTime}` | Adversaire terminé |
| `round_result` | `{roundNumber, winnerId, players{...}}` | Fin de round |
| `match_result` | `{winnerId, players{...}}` | Fin de match |

---

## 🎮 CONFIGURATION DU JEU

```dart
// Rounds
const ROUND_CONFIGS = [
  { pieceCount: 3 },  // Round 1
  { pieceCount: 4 },  // Round 2
  { pieceCount: 5 },  // Round 3
  { pieceCount: 6 },  // Round 4
];

// Temps limite par round
const TIME_LIMIT = 180; // 3 minutes

// Victoire : premier à 3 rounds gagnés (best of 4)
```

---

## 🔧 COMMANDES UTILES

### Serveur
```bash
cd ~/StudioProjects/pentapol-server

# Développement local
wrangler dev

# Déployer
wrangler deploy

# Logs en temps réel
wrangler tail --format pretty

# Tester
curl https://pentapol-duel.pentapml.workers.dev/
```

### Client
```bash
cd ~/StudioProjects/pentapol

# Analyser les erreurs
flutter analyze lib/duel_isometry/

# Lancer
flutter run

# Debug avec 2 appareils
flutter run -d "iPhone 15"  # Terminal 1
flutter run -d "iPhone 15 Pro Max"  # Terminal 2
```

---

## 📚 FICHIERS DE RÉFÉRENCE (EXISTANTS ET FONCTIONNELS)

Ces fichiers existent déjà et fonctionnent bien :

### IsometryPuzzle.generate() - lib/duel_isometry/services/isometry_puzzle.dart
```dart
/// Génère un puzzle avec un seed donné
static IsometryPuzzle generate({
  required int width,  // Nombre de pièces
  int height = 5,
  int? seed,
}) {
  final random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
  // ... génération déterministe
}
```

### Classes principales
- `IsometryPuzzle` : Le puzzle complet avec pièces et grille cible
- `TargetPiece` : Une pièce avec position cible et position initiale
- `PieceConfiguration` : Rotation + flip d'une pièce
- `Pento` : La pièce pentomino de base (12 pièces existantes)

---

## ✅ CE QUI FONCTIONNE

1. ✅ Serveur déployé sur Cloudflare Workers
2. ✅ Création de room (POST /room/create)
3. ✅ Connexion WebSocket du créateur
4. ✅ Message `room_created` reçu
5. ✅ Écran d'attente avec code affiché (après correction)
6. ✅ Persistance du roomCode dans le storage

## ❌ CE QUI NE FONCTIONNE PAS

1. ❌ Rejoindre une room existante (hibernation DO)
2. ❌ Affichage correct du puzzle (grille, miniatures)
3. ❌ Synchronisation des deux joueurs
4. ❌ Déroulement complet d'une partie

---

## 🎯 PROCHAINES ÉTAPES RECOMMANDÉES

1. **Résoudre l'hibernation** : Tester avec `wrangler dev` en local pour éviter l'hibernation Cloudflare

2. **Simplifier le test** : Créer un mode "solo" temporaire pour tester l'affichage sans serveur

3. **Débugger l'UI** : Vérifier que `IsometryPuzzle.generate()` produit des données valides et qu'elles sont bien transmises aux widgets

4. **Alternative** : Utiliser un autre backend (Firebase, Supabase) si l'hibernation Cloudflare est trop problématique

---

## 📎 URLs

- **Serveur production** : https://pentapol-duel.pentapml.workers.dev/
- **Health check** : https://pentapol-duel.pentapml.workers.dev/ → `{"status":"ok","service":"pentapol-duel","version":"2.0.0","modes":["classic","isometry"]}`