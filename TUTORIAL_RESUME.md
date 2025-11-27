# 📋 Reprendre le travail sur Tutorial Pentapol

## ⚡ Contexte minimal (copier-coller)
```
Je travaille sur le système de tutoriels Pentapol (Scratch-like pour Flutter/Dart).

ARCHITECTURE :
- 20 fichiers module tutorial/ créés et opérationnels
- 28 commandes Phase 1 implémentées et testées
- Parser YAML + Interpréteur + Provider Riverpod
- Widgets UI (TutorialOverlay + TutorialControls)
- Highlights de cases fonctionnels
- Placement et rotations autour de mastercase OK

LOCALISATION :
- Code : ~/StudioProjects/pentapol/lib/tutorial/
- Assets : ~/StudioProjects/pentapol/assets/tutorials/
- Docs : ~/StudioProjects/pentapol/TUTORIAL_*.md
- Provider jeu : ~/StudioProjects/pentapol/lib/providers/pentomino_game_provider.dart

COORDONNÉES PLATEAU :
- Plateau 6×10 (X: 0-5, Y: 0-9)
- Origine (0,0) = HAUT-GAUCHE
- Y augmente vers le BAS

MASTERCASE :
- Point de référence d'une pièce (point rouge visible)
- Dans YAML : gridX/gridY = position de la MASTERCASE (pas de l'ancre)
- En interne : système convertit automatiquement mastercase → ancre
- Centre de rotation pour les transformations géométriques

DOCUMENTATIONS :
- TUTORIAL_COMMANDS.md : Référence des 28 commandes
- TUTORIAL_ARCHITECTURE.md : Architecture technique
- TUTORIAL_MASTERCASE.md : Concept de mastercase

ÉTAT ACTUEL :
- ✅ Système Phase 1 fonctionnel et testé
- ✅ Tutorial 01_intro_basics.yaml opérationnel
- ✅ Highlights, placement, rotations, mastercase OK
- ✅ Messages avec auto-hide
- ✅ Nettoyage UI en fin de tutorial
- ✅ 3 documentations complètes
```

---

## 📚 Documentations à fournir

### Option A : Lecture rapide (recommandé)
```bash
cat ~/StudioProjects/pentapol/TUTORIAL_COMMANDS.md
cat ~/StudioProjects/pentapol/TUTORIAL_MASTERCASE.md
```

### Option B : Architecture complète (si modifications profondes)
```bash
cat ~/StudioProjects/pentapol/TUTORIAL_ARCHITECTURE.md
```

---

## 📂 Fichiers à uploader selon le besoin

### Pour débugger un script YAML
- `assets/tutorials/[votre_script].yaml`
- Logs d'erreur complets

### Pour modifier/créer une commande
- `lib/tutorial/commands/[fichier_concerné].dart`
- `lib/tutorial/parser/yaml_parser.dart` (si nouvelle commande)

### Pour modifier l'interpréteur
- `lib/tutorial/interpreter/scratch_interpreter.dart`

### Pour modifier l'état/provider
- `lib/tutorial/providers/tutorial_provider.dart`

### Pour modifier le placement/sélection
- `lib/providers/pentomino_game_provider.dart` (méthodes tutorial)
- `lib/providers/pentomino_game_state.dart` (si absoluteCells)

### Pour modifier l'UI
- `lib/tutorial/widgets/tutorial_overlay.dart` (messages)
- `lib/tutorial/widgets/tutorial_controls.dart` (boutons)

---

## 🎯 Template message pour nouvelle conversation
```
Bonjour ! Je reprends le travail sur le système Tutorial Pentapol.

CONTEXTE :
- Système Scratch-like avec 28 commandes Phase 1 opérationnelles
- Fichiers dans lib/tutorial/ (20 fichiers)
- Parser YAML + Interpréteur + Riverpod + Widgets UI
- Coordonnées : (0,0) = haut-gauche, plateau 6×10
- Mastercase : point rouge = centre de rotation, position de référence

BESOIN :
[Décrire précisément ce que vous voulez faire]
- Créer une nouvelle commande ?
- Débugger un script ?
- Ajouter une fonctionnalité ?
- Phase 2 (conditions, variables, etc.) ?

FICHIERS JOINTS :
[Si applicable : scripts YAML, logs d'erreur, fichiers Dart concernés]

LOGS/ERREURS :
[Copier-coller les logs pertinents avec [TUTORIAL], [INTERPRETER], [GAME]]
```

---

## 🔍 Commandes de vérification rapide

### Vérifier l'intégrité du système
```bash
# Nombre de fichiers tutorial (doit être 20)
find lib/tutorial -type f -name "*.dart" | wc -l

# Pas d'erreurs de compilation
flutter analyze | grep error | wc -l  # Doit retourner 0

# Scripts disponibles
ls -lh assets/tutorials/

# Docs présentes
ls -lh TUTORIAL_*.md
```

### Tester rapidement
```bash
# Lancer l'app
flutter run

# Filtrer les logs tutorial
flutter run 2>&1 | grep -E "TUTORIAL|INTERPRETER|PARSER"
```

---

## 🚀 Scénarios courants

### 1. "Je veux créer une nouvelle commande X"

**Fournir** :
- Description de ce que fait la commande
- Paramètres attendus
- Exemple d'utilisation YAML

**Je fournirai** :
- Code de la commande
- Modification du parser
- Exemple d'utilisation dans un script

---

### 2. "Mon script YAML ne fonctionne pas"

**Fournir** :
- Le fichier YAML complet
- Les logs d'erreur complets (avec [PARSER], [INTERPRETER], [TUTORIAL])
- Description du comportement attendu vs observé

**Je fournirai** :
- Diagnostic de l'erreur
- Script corrigé
- Explications

---

### 3. "Je veux modifier le comportement d'une commande existante"

**Fournir** :
- Nom de la commande
- Comportement actuel
- Comportement souhaité
- Optionnel : fichier de la commande

**Je fournirai** :
- Code modifié
- Impact sur les scripts existants
- Tests suggérés

---

### 4. "Je veux ajouter une fonctionnalité UI"

**Fournir** :
- Description de la fonctionnalité
- Où doit-elle apparaître (overlay, contrôles, plateau)
- Comportement souhaité

**Je fournirai** :
- Modifications des widgets
- Code Flutter nécessaire
- Tests suggérés

---

### 5. "Phase 2 : conditions, variables, boucles"

**Fournir** :
- Quelle fonctionnalité Phase 2 vous voulez (IF/WHILE/variables/etc.)
- Exemples d'utilisation envisagés

**Je fournirai** :
- Architecture pour la fonctionnalité
- Code d'implémentation
- Documentation mise à jour

---

## 🐛 Debug : Logs pertinents

### Logs à copier selon le problème

**Problème de parsing** :
```
Chercher : [PARSER]
Exemple : [PARSER] Erreur parsing params pour SHOW_MESSAGE: ...
```

**Problème d'exécution** :
```
Chercher : [INTERPRETER]
Exemple : [INTERPRETER] Erreur à l'étape 22: Bad state: ...
```

**Problème de commande** :
```
Chercher : [TUTORIAL]
Exemple : [TUTORIAL] Case (2, 4) surlignée
```

**Problème de jeu** :
```
Chercher : [GAME]
Exemple : [GAME] 🔃 Rotation 90° horaire autour de (2, 4)
```

### Filtrer les logs utiles
```bash
# Tous les logs tutorial
flutter run 2>&1 | grep -E "TUTORIAL|INTERPRETER|PARSER|GAME"

# Seulement les erreurs
flutter run 2>&1 | grep -E "Erreur|ERROR|Exception|Bad state"

# Trace d'exécution d'un script
flutter run 2>&1 | grep -E "Étape|Step"
```

---

## 💡 Informations supplémentaires utiles

### Structure d'une pièce (si problème de mastercase)
```bash
grep -A 30 "id: [ID_PIECE]," lib/models/pentominos.dart
```

### Vérifier absoluteCells
```bash
sed -n '60,75p' lib/providers/pentomino_game_state.dart
```

### Voir toutes les commandes disponibles
```bash
grep "class.*Command extends ScratchCommand" lib/tutorial/commands/*.dart
```

### Voir les méthodes tutorial du GameNotifier
```bash
grep -n "ForTutorial" lib/providers/pentomino_game_provider.dart
```

---

## 📊 État des fichiers (novembre 2025)

### Modules créés
- ✅ Models (4 fichiers)
- ✅ Parser (1 fichier)
- ✅ Interpreter (1 fichier)
- ✅ Commands (9 fichiers, 28 commandes)
- ✅ Provider (1 fichier)
- ✅ Widgets (2 fichiers)
- ✅ Examples (1 fichier)

### Intégrations
- ✅ TutorialOverlay dans GameScreen
- ✅ TutorialControls dans GameScreen
- ✅ Bouton "?" pour lancer le tutorial
- ✅ Méthodes tutorial dans PentominoGameNotifier

### Fonctionnalités
- ✅ Parsing YAML robuste
- ✅ Exécution asynchrone pas à pas
- ✅ Messages avec auto-hide
- ✅ Highlights de cases (couleurs)
- ✅ Placement avec mastercase
- ✅ Sélection de pièces (slider + plateau)
- ✅ Rotations géométriques autour mastercase
- ✅ Mode tutoriel avec sauvegarde/restauration
- ✅ Contrôles Play/Pause/Stop
- ✅ Nettoyage complet en fin

---

## 🎯 Gain de temps maximal

**Le plus simple** : Copiez juste le **bloc "Contexte minimal"** du début de ce document.

Dans 95% des cas, ça suffit ! Les documentations sont dans votre projet, je les relirai au besoin.

**Ajoutez ensuite** :
1. Votre besoin précis
2. Fichiers concernés (si vous savez)
3. Logs d'erreur (si problème)

**C'est tout ! 🚀**

---

**Dernière mise à jour : Novembre 2025**