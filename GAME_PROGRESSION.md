<!-- Modified: 2025-11-16 08:30:00 -->
# 🎮 Progression Pédagogique - Pentapol

## 🎯 Vision

Pentapol est conçu pour **évoluer avec le joueur**, du premier contact (interface simplifiée) jusqu'au mode expert (compétition). Le coach IA "Penta" accompagne cette progression en enseignant la géométrie de manière ludique.

---

## 📊 Niveaux de Progression

### 🌱 Niveau 1 : Débutant (Beginner)

**Objectif** : Comprendre les bases du jeu

#### Interface
- ✅ Drag & drop uniquement
- ✅ Bouton Undo visible
- ❌ Compteur de solutions masqué
- ❌ Bouton rotation masqué
- ❌ Bouton miroir masqué
- ❌ Bouton "Voir solutions" masqué

#### Coach IA
- **Personnalité** : Très encourageant
- **Messages** :
  - Bienvenue et explication des règles
  - Encouragement après chaque pièce placée
  - Leçons de géométrie (aire, périmètre)
  - Indices si bloqué > 30s

#### Critères de passage au niveau 2
- ✅ 3 puzzles complétés

---

### 🌿 Niveau 2 : Intermédiaire (Intermediate)

**Objectif** : Maîtriser rotation et symétrie

#### Interface
- ✅ Toutes les fonctions de base
- ✅ Compteur de solutions visible
- ✅ Bouton rotation visible
- ✅ Bouton "Voir solutions" visible
- ❌ Bouton miroir masqué (pas encore)
- ❌ Rotation in-situ masquée

#### Coach IA
- **Personnalité** : Aide stratégique
- **Messages** :
  - Conseils sur l'utilisation des rotations
  - Explication des symétries
  - Leçons de géométrie (transformations)
  - Astuces de placement

#### Critères de passage au niveau 3
- ✅ 15 puzzles complétés
- ✅ 20+ rotations utilisées

---

### 🌳 Niveau 3 : Avancé (Advanced)

**Objectif** : Optimiser temps et stratégie

#### Interface
- ✅ Toutes les fonctions
- ✅ Bouton miroir visible
- ✅ Rotation in-situ activée
- ✅ Chronomètre visible
- ✅ Statistiques détaillées

#### Coach IA
- **Personnalité** : Défis et challenges
- **Messages** :
  - Défis de temps
  - Exploration des 9356 solutions
  - Leçons de géométrie (pavage, tessellation)
  - Comparaison avec records personnels

#### Critères de passage au niveau 4
- ✅ 50 puzzles complétés
- ✅ Temps moyen < 5 minutes

---

### 🏆 Niveau 4 : Expert (Expert)

**Objectif** : Compétition et multijoueur

#### Interface
- ✅ Mode compétition
- ✅ Classements mondiaux
- ✅ Défis quotidiens
- ✅ Mode multijoueur débloqué

#### Coach IA
- **Personnalité** : Compétitif
- **Messages** :
  - Comparaison avec top joueurs
  - Défis avancés
  - Stratégies optimales
  - Préparation multijoueur

---

## 🤖 Coach IA "Penta"

### Leçons de Géométrie

#### 1. **Aire et Périmètre** (Niveau 1)
> "📐 Chaque pentomino couvre 5 cases. 12 pièces × 5 cases = 60 cases (le plateau 6×10) !"

#### 2. **Rotation** (Niveau 2)
> "🔄 La rotation fait tourner une pièce de 90°. Certaines pièces ont 4 orientations différentes !"

#### 3. **Symétrie** (Niveau 2)
> "🪞 La symétrie crée l'image miroir d'une pièce. Comme si tu la retournais !"

#### 4. **Pavage** (Niveau 3)
> "🧩 Le pavage, c'est remplir un espace sans trou ni chevauchement. Il existe 9356 solutions différentes !"

#### 5. **Transformations** (Niveau 3)
> "🔀 En combinant rotation et symétrie, certaines pièces ont 8 positions différentes !"

#### 6. **Optimisation** (Niveau 4)
> "⚡ Les coins et bords d'abord ! C'est la stratégie la plus efficace."

---

## 🎨 Thèmes Visuels

### Débutant : Colorful
- Couleurs vives et contrastées
- Animations encourageantes
- Feedback visuel important

### Intermédiaire : Balanced
- Couleurs équilibrées
- Animations subtiles
- Interface claire

### Avancé/Expert : Minimalist
- Couleurs sobres
- Animations discrètes
- Focus sur la performance

---

## 📈 Statistiques Suivies

- ✅ Puzzles complétés
- ✅ Temps moyen de résolution
- ✅ Temps total de jeu
- ✅ Rotations utilisées
- ✅ Symétries utilisées
- ✅ Undos utilisés
- ✅ Solutions explorées
- ✅ Record personnel

---

## 🚀 Implémentation

### Fichiers créés
1. `lib/config/game_config.dart` - Configuration des niveaux
2. `lib/services/ai_coach.dart` - Service de coaching IA
3. `lib/widgets/coach_message_widget.dart` - UI des messages
4. `lib/providers/game_config_provider.dart` - Gestion de la progression

### Intégration dans le jeu
```dart
// Dans pentomino_game_screen.dart
final config = ref.watch(gameConfigProvider);
final coach = AICoach(config: config);

// Wrapper l'écran avec CoachOverlay
CoachOverlay(
  messageStream: coach.messages,
  child: Scaffold(...),
)
```

---

## 🎯 Prochaines Étapes

1. ✅ Intégrer le coach dans `pentomino_game_screen.dart`
2. ⏳ Ajouter les dépendances (`shared_preferences`)
3. ⏳ Tester la progression niveau 1 → 2
4. ⏳ Affiner les messages selon les retours utilisateurs
5. ⏳ Ajouter des animations pour les leçons de géométrie
6. ⏳ Implémenter le mode multijoueur (niveau 4)

---

**Dernière mise à jour** : 2025-11-16 08:30:00

