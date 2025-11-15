<!-- Modified: 2025-11-15 17:30:00 -->
# 🧩 Pentapol

> **Jeu collaboratif de pentominos en temps réel — Flutter + Supabase + IA bienveillante**

---

## 🎯 Vision

Pentapol est une application **multijoueur iOS/Android** où les joueurs résolvent ensemble des **puzzles de type pentomino**.  
Chaque partie est collaborative, animée par un **coach IA bienveillant** qui encourage, modère et accompagne la progression.

---

## 🎮 Mode Jeu Solo

### Interface adaptative
- **Mode Portrait** : Plateau 6×10 vertical, slider horizontal en bas
- **Mode Paysage** : Plateau 10×6 horizontal, sliders verticaux à droite
  - Slider d'actions (compteur de solutions, visibilité, rotation, annuler)
  - Slider de pièces disponibles
  - Pas d'AppBar (plein écran)

### Interactions
- **Tap simple** sur pièce du slider : sélectionner
- **Double-tap** sur pièce : rotation
- **Long press** (200ms) sur pièce : démarrer le drag & drop
- **Tap sur plateau** : sélectionner/désélectionner une pièce placée
- **Drag & drop** : placer une pièce sur le plateau

### Compteur de solutions
- Affiche le nombre de solutions possibles en temps réel
- Masqué quand le plateau est vide
- Bouton 👁️ pour visualiser les solutions compatibles

### Fonctionnalités
- ✅ Démarrage direct sur le jeu
- ✅ Adaptation automatique portrait/paysage
- ✅ Pré-chargement de 9356 solutions (BigInt)
- ✅ Calcul temps réel des solutions possibles
- ✅ Undo/Redo des placements
- ✅ Feedback haptique sur les actions

---

## 🏗️ Stack technique

| Côté | Technologie | Rôle |
|------|--------------|------|
| **Client** | Flutter / Dart | Interface & logique locale |
| **État** | Riverpod | Gestion réactive des états |
| **Modèles** | Freezed | Données immuables, unions |
| **Local** | SQLite | Cache, pseudo, messages |
| **Backend** | Supabase (Postgres + Realtime + RLS) | Rooms, progression, chat |
| **Edge** | Cloudflare Workers / Durable Objects | WebSocket, quotas, upload |
| **IA** | API IA + Edge Function | Coach, modération, résumé |
| **Langues** | FR/EN (intl, .arb) | Interface multilingue |

---

## 🔄 Fonctionnement du jeu

1. Un joueur crée une **room** (figure à 3–12 pièces).
2. D’autres joueurs rejoignent via lien ou QR code.
3. Tous placent les pièces ensemble, le compteur `X / total` est partagé.
4. Le **coach IA “Penta”** commente et encourage.
5. À la fin, l’IA résume la partie (durée, coopération, rythme).

---

## 🤖 IA : Coach & Modération

### Rôles
| Type | Description |
|------|--------------|
| 🛡️ **Gardienne** | Modère le chat (`OK / WARN / BLOCK`) |
| 💬 **Coach** | Encourage et anime la partie |
| 📊 **Analyste** | Génère un débrief anonyme post-partie |

### Personnalité
- Bienveillante, jamais intrusive
- Langage simple, positif, multilingue
- Intervient à des moments-clés (début, milestones, fin)

### Exemples
> “Super esprit d’équipe ! 🧩”  
> “Essaie une pièce droite ici 👀”  
> “Encore une et la figure sera complète !”

---

## 🌐 Internationalisation

- Langues : **français / anglais**
- Détection : locale système → fallback `en`
- Fichiers : `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Provider Riverpod : `localeProvider`
- Coach et IA répondent dans la langue de la room (`room.lang`)

---

## 🧱 Données (Supabase)

### Tables principales
- `rooms(id, pieces_total, image_url, lang, created_at)`
- `room_members(room_id, player_id, display_name, joined_at)`
- `progress(room_id, placed, updated_at)`
- `messages(id, room_id, player_id, text, status, created_at)`
- `scores(room_id, player_id, points)`

### Règles RLS
- Lecture/écriture restreinte au `room_id` du joueur.
- Auth anonyme ou device token.

---

## 🔐 Sécurité & vie privée

- Pas de données personnelles stockées.
- Pseudos et préférences locaux (SQLite).
- Chat modéré, purge automatique ≤ 24 h.
- Uploads d’images (si activés) : URL signées, purge ≤ 30 min.

---

## ⚙️ Installation (base Flutter)

```bash
