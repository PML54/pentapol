# 💰 Guide Complet : Tokens et Coûts - Claude AI

**Documentation des tokens, calculs et tarification**

**Date de création : 23 novembre 2025 05:29**

---

## 📋 Table des matières

1. [Qu'est-ce qu'un token ?](#quest-ce-quun-token)
2. [Conversion tokens ↔ texte](#conversion-tokens--texte)
3. [Tokens dans le code](#tokens-dans-le-code)
4. [Tarification Claude Sonnet 4.5](#tarification-claude-sonnet-45)
5. [Calcul des coûts](#calcul-des-coûts)
6. [Exemples concrets](#exemples-concrets)
7. [Optimisation des coûts](#optimisation-des-coûts)
8. [Suivi des tokens](#suivi-des-tokens)

---

## 🔤 Qu'est-ce qu'un token ?

### Définition

Un **token** est une unité de traitement du langage utilisée par les modèles d'IA. Ce n'est pas exactement un mot, mais plutôt un morceau de texte que le modèle comprend comme une unité atomique.

### Pourquoi les tokens ?

Les modèles d'IA ne lisent pas lettre par lettre, mais par "morceaux" optimisés :
- Plus efficace que de traiter caractère par caractère
- Permet de comprendre les patterns linguistiques
- Optimise la vitesse de traitement

### Tokenisation en action

**Exemple 1 : Phrase simple**
```
Texte : "Bonjour, comment allez-vous ?"

Tokens possibles :
["Bon", "jour", ",", " comment", " all", "ez", "-", "vous", " ?"]
≈ 9 tokens
```

**Exemple 2 : Texte technique**
```
Texte : "PentominoGameProvider"

Tokens possibles :
["Pent", "omino", "Game", "Provider"]
≈ 4 tokens
```

---

## 📊 Conversion tokens ↔ texte

### Règles générales

| Langue/Type | Ratio tokens/caractères | Ratio tokens/mots |
|-------------|------------------------|-------------------|
| **Anglais** | 1 token ≈ 4 caractères | 1 token ≈ 0.75 mot |
| **Français** | 1 token ≈ 2-3 caractères | 1 token ≈ 0.6 mot |
| **Code** | 1 token ≈ 3-4 caractères | Variable |
| **JSON/XML** | 1 token ≈ 2-3 caractères | N/A |

### Exemples de conversion

#### Texte français

```
Texte : "Je vais mettre à jour la documentation avec les derniers fichiers modifiés."

Caractères : 78
Mots : 13
Tokens : ~30-35

Calcul :
- Par caractères : 78 / 2.5 ≈ 31 tokens
- Par mots : 13 / 0.6 ≈ 22 tokens
- Moyenne : ~30 tokens
```

#### Texte anglais

```
Text: "I will update the documentation with the latest modified files."

Characters: 64
Words: 10
Tokens: ~15-18

Calculation:
- By characters: 64 / 4 ≈ 16 tokens
- By words: 10 / 0.75 ≈ 13 tokens
- Average: ~15 tokens
```

### Tableau de conversion rapide

| Volume | Tokens (approx) | Caractères | Mots (FR) | Mots (EN) |
|--------|----------------|------------|-----------|-----------|
| Phrase courte | 10-20 | 25-60 | 5-12 | 8-15 |
| Paragraphe | 50-100 | 125-300 | 30-60 | 40-75 |
| Page A4 | 400-600 | 1,200-1,800 | 250-360 | 300-450 |
| Document 10 pages | 4,000-6,000 | 12,000-18,000 | 2,500-3,600 | 3,000-4,500 |
| Livre 200 pages | 80,000-120,000 | 240,000-360,000 | 50,000-72,000 | 60,000-90,000 |

---

## 💻 Tokens dans le code

### Lignes de code Dart/Flutter

#### Exemples réels

**Ligne très courte :**
```dart
final int id;
```
- Caractères : 13
- Tokens : **4-5**
- Détail : `final` (1) + `int` (1) + `id` (1) + `;` (1)

**Ligne courte :**
```dart
void reset() {
```
- Caractères : 14
- Tokens : **5-6**
- Détail : `void` (1) + `reset` (1) + `(` (1) + `)` (1) + `{` (1)

**Ligne moyenne :**
```dart
void selectPiece(int? pieceIndex) {
```
- Caractères : 37
- Tokens : **8-10**
- Détail : `void` (1) + `select` (1) + `Piece` (1) + `(` (1) + `int` (1) + `?` (1) + `piece` (1) + `Index` (1) + `)` (1) + `{` (1)

**Ligne longue :**
```dart
final solutions = await loadNormalizedSolutionsAsBigInt();
```
- Caractères : 60
- Tokens : **12-15**
- Détail : `final` (1) + `solutions` (1) + `=` (1) + `await` (1) + `load` (1) + `Normalized` (1) + `Solutions` (1) + `As` (1) + `Big` (1) + `Int` (1) + `(` (1) + `)` (1) + `;` (1)

**Ligne très longue :**
```dart
BigIntPlateau placePiece({required int pieceId, required Iterable<int> cellIndices, required Map<int, int> bit6ById}) {
```
- Caractères : 130
- Tokens : **30-35**

#### Tableau récapitulatif

| Type de ligne | Caractères | Tokens | Ratio |
|---------------|------------|--------|-------|
| Très courte (< 20 car) | 5-20 | 3-6 | 1 token / 3-4 car |
| Courte (20-40 car) | 20-40 | 5-10 | 1 token / 4 car |
| Moyenne (40-70 car) | 40-70 | 10-18 | 1 token / 4 car |
| Longue (70-100 car) | 70-100 | 18-25 | 1 token / 4 car |
| Très longue (> 100 car) | 100-150 | 25-40 | 1 token / 3-4 car |

### Moyenne pour code Dart/Flutter

**Règle d'or :**
```
1 ligne de code Dart = ~12-15 tokens (moyenne)
```

### Calcul pour fichiers entiers

**Exemples du projet Pentapol :**

| Fichier | Lignes | Tokens estimés | Calcul |
|---------|--------|----------------|--------|
| `main.dart` | 55 | ~715 | 55 × 13 |
| `plateau.dart` | 67 | ~870 | 67 × 13 |
| `pentomino_game_state.dart` | 168 | ~2,184 | 168 × 13 |
| `pentomino_game_screen.dart` | 231 | ~3,003 | 231 × 13 |
| `game_board.dart` | 336 | ~4,368 | 336 × 13 |
| `pentomino_solver.dart` | 589 | ~7,657 | 589 × 13 |
| `pentomino_game_provider.dart` | 844 | ~10,972 | 844 × 13 |
| **TOTAL (core)** | **~5,200** | **~67,600** | 5,200 × 13 |

### Facteurs qui influencent les tokens

#### Augmentent le nombre de tokens :
- **Noms longs** : `PentominoGameNotifier` = 5-6 tokens
- **CamelCase** : Découpe en morceaux (`selectPiece` = 2 tokens)
- **Symboles** : Chaque `{`, `}`, `(`, `)`, `;` = 1 token
- **Commentaires longs** : Texte en langage naturel
- **Strings longues** : Texte dans les guillemets

#### Réduisent le nombre de tokens :
- **Mots-clés courts** : `int`, `if`, `for`, `var` = 1 token
- **Mots communs** : Optimisés dans le vocabulaire du modèle
- **Code minifié** : Moins d'espaces et de retours à la ligne

---

## 💳 Tarification Claude Sonnet 4.5

### Prix officiels (Anthropic)

| Type | Prix par 1M tokens | Prix par 1K tokens |
|------|-------------------|-------------------|
| **Input** (lecture) | $3.00 | $0.003 |
| **Output** (génération) | $15.00 | $0.015 |

### Ratio Input/Output

```
Output coûte 5× plus cher que Input
```

**Pourquoi ?**
- L'input est juste "lu" et encodé
- L'output nécessite génération créative, token par token
- Chaque token généré nécessite un calcul complet du modèle

### Comparaison avec d'autres modèles

| Modèle | Input ($/1M) | Output ($/1M) | Ratio |
|--------|-------------|--------------|-------|
| **Claude Sonnet 4.5** | $3.00 | $15.00 | 5× |
| Claude Sonnet 3.5 | $3.00 | $15.00 | 5× |
| Claude Opus 3 | $15.00 | $75.00 | 5× |
| GPT-4 Turbo | $10.00 | $30.00 | 3× |
| GPT-3.5 Turbo | $0.50 | $1.50 | 3× |

**Claude Sonnet 4.5 = Excellent rapport qualité/prix** ✅

---

## 🧮 Calcul des coûts

### Formule de base

```
Coût total = (Input tokens × $3 / 1M) + (Output tokens × $15 / 1M)
```

### Exemples de calcul

#### Exemple 1 : Question simple

```
Question : "Explique-moi comment fonctionne le provider"
Réponse : Paragraphe de 200 mots

Input tokens :
- Question : 20 tokens
- Contexte du projet : 5,000 tokens
- Fichier provider lu : 11,000 tokens
Total Input : 16,020 tokens

Output tokens :
- Réponse : 300 tokens

Coût :
Input  : 16,020 × $3 / 1M  = $0.048
Output : 300 × $15 / 1M     = $0.0045
TOTAL  : $0.0525 (5.3 centimes)
```

#### Exemple 2 : Génération de documentation

```
Demande : "Génère une doc complète avec métadonnées"
Résultat : Fichier markdown de 600 lignes

Input tokens :
- Demande : 50 tokens
- Contexte : 5,000 tokens
- Lecture de 20 fichiers : 15,000 tokens
- Doc existante : 5,000 tokens
Total Input : 25,050 tokens

Output tokens :
- Commandes shell : 500 tokens
- Documentation générée : 4,000 tokens
- Réponses : 500 tokens
Total Output : 5,000 tokens

Coût :
Input  : 25,050 × $3 / 1M  = $0.075
Output : 5,000 × $15 / 1M   = $0.075
TOTAL  : $0.15 (15 centimes)
```

#### Exemple 3 : Refactoring de code

```
Demande : "Refactore ce fichier de 1000 lignes"
Résultat : Fichier refactoré + explications

Input tokens :
- Demande : 30 tokens
- Contexte : 5,000 tokens
- Fichier à refactorer : 13,000 tokens
- Fichiers dépendants : 10,000 tokens
Total Input : 28,030 tokens

Output tokens :
- Code refactoré : 10,000 tokens
- Explications : 2,000 tokens
Total Output : 12,000 tokens

Coût :
Input  : 28,030 × $3 / 1M  = $0.084
Output : 12,000 × $15 / 1M  = $0.18
TOTAL  : $0.264 (26.4 centimes)
```

### Tableau de coûts typiques

| Tâche | Input | Output | Coût total |
|-------|-------|--------|------------|
| Question simple | 5K | 300 | $0.02 |
| Explication détaillée | 10K | 1K | $0.045 |
| Lecture de code | 20K | 500 | $0.068 |
| Génération doc | 25K | 5K | $0.15 |
| Refactoring | 30K | 10K | $0.24 |
| Analyse complète projet | 100K | 20K | $0.60 |

---

## 📈 Exemples concrets (Projet Pentapol)

### Cas réel 1 : Mise à jour documentation avec métadonnées

**Demande :**
> "Mets à jour la doc avec les derniers fichiers modifiés. Ajoute DATEMODIF et CODELINE pour chaque fichier."

**Détail des tokens :**

| Étape | Tokens | Type |
|-------|--------|------|
| Question initiale | 100 | Input |
| Contexte projet chargé | 5,000 | Input |
| Lecture ~20 fichiers pour dates | 5,000 | Input |
| Comptage lignes de code | 10,000 | Input |
| Lecture doc existante | 5,000 | Input |
| **Total Input** | **25,100** | **Input** |
| | | |
| Commandes shell générées | 500 | Output |
| Documentation générée (600 lignes) | 4,000 | Output |
| Réponses explicatives | 500 | Output |
| **Total Output** | **5,000** | **Output** |

**Calcul du coût :**
```
Input  : 25,100 × $3 / 1,000,000  = $0.0753
Output : 5,000 × $15 / 1,000,000  = $0.075
───────────────────────────────────────────
TOTAL                             = $0.1503 (15 centimes)
```

**Répartition :**
- 📖 Lecture : 50% ($0.075)
- ✍️ Génération : 50% ($0.075)

---

### Cas réel 2 : Explication des tokens

**Demande :**
> "C'est quoi un token ? Combien pour lire mon code ? Génère une doc MD complète."

**Détail des tokens :**

| Étape | Tokens | Type |
|-------|--------|------|
| Questions | 150 | Input |
| Contexte conversation | 3,000 | Input |
| Exemples de code lus | 2,000 | Input |
| **Total Input** | **5,150** | **Input** |
| | | |
| Explications détaillées | 2,000 | Output |
| Documentation MD (ce fichier!) | 8,000 | Output |
| **Total Output** | **10,000** | **Output** |

**Calcul du coût :**
```
Input  : 5,150 × $3 / 1,000,000   = $0.0155
Output : 10,000 × $15 / 1,000,000 = $0.15
───────────────────────────────────────────
TOTAL                             = $0.1655 (16.5 centimes)
```

**Répartition :**
- 📖 Lecture : 9% ($0.0155)
- ✍️ Génération : 91% ($0.15)

**Note :** L'output coûte beaucoup plus car je génère une longue documentation!

---

### Cas réel 3 : Refactoring pentomino_game_screen.dart

**Contexte :**
Fichier monolithique de 1350 lignes → Extraction en modules (231 lignes + widgets)

**Détail des tokens (estimation) :**

| Étape | Tokens | Type |
|-------|--------|------|
| Demande de refactoring | 200 | Input |
| Contexte projet | 10,000 | Input |
| Fichier original (1350 lignes) | 17,550 | Input |
| Fichiers dépendants lus | 15,000 | Input |
| **Total Input** | **42,750** | **Input** |
| | | |
| Fichier principal refactoré | 3,000 | Output |
| 6 nouveaux widgets créés | 12,000 | Output |
| Explications et documentation | 3,000 | Output |
| **Total Output** | **18,000** | **Output** |

**Calcul du coût :**
```
Input  : 42,750 × $3 / 1,000,000  = $0.128
Output : 18,000 × $15 / 1,000,000 = $0.27
───────────────────────────────────────────
TOTAL                             = $0.398 (40 centimes)
```

**Résultat :**
- Code réduit de 83% (1350 → 231 lignes)
- Architecture modulaire propre
- Coût : **40 centimes** pour plusieurs heures de travail manuel! 🎯

---

## 🎯 Optimisation des coûts

### Stratégies pour réduire les coûts

#### 1. Optimiser l'Input

**❌ Mauvais :**
```
"Lis tous les fichiers du projet et dis-moi ce qui ne va pas"
→ Lit 100+ fichiers inutilement
→ Coût élevé
```

**✅ Bon :**
```
"Analyse le fichier pentomino_game_provider.dart et vérifie la logique de placement"
→ Lit uniquement les fichiers nécessaires
→ Coût réduit
```

#### 2. Réutiliser le contexte

**❌ Mauvais :**
```
Session 1 : "Explique le provider"
Session 2 : "Explique le state" (nouvelle conversation)
→ Recharge tout le contexte
```

**✅ Bon :**
```
Session 1 : "Explique le provider"
Suite : "Maintenant explique le state"
→ Réutilise le contexte déjà chargé
```

#### 3. Limiter l'Output

**❌ Mauvais :**
```
"Génère une documentation complète de 50 pages avec tous les détails"
→ Output massif = coût élevé
```

**✅ Bon :**
```
"Génère une documentation concise avec les points essentiels"
→ Output ciblé = coût réduit
```

#### 4. Utiliser des résumés

**❌ Mauvais :**
```
Inclure 10 fichiers complets de 500 lignes chacun
→ 65,000 tokens d'input
```

**✅ Bon :**
```
Inclure les signatures et structures clés
→ 10,000 tokens d'input
```

### Tableau d'optimisation

| Technique | Économie | Difficulté |
|-----------|----------|------------|
| Questions ciblées | 30-50% | Facile |
| Réutilisation contexte | 40-60% | Facile |
| Limiter output | 20-40% | Moyen |
| Résumés au lieu de fichiers complets | 50-70% | Moyen |
| Batch de questions | 20-30% | Facile |
| Désactiver contexte inutile | 10-30% | Difficile |

### Exemples d'économies

#### Avant optimisation
```
10 questions séparées sur le projet
= 10 × chargement contexte
= 10 × 5,000 tokens = 50,000 tokens input
Coût : $0.15
```

#### Après optimisation
```
10 questions dans la même conversation
= 1 × chargement contexte
= 1 × 5,000 + 10 × 100 = 6,000 tokens input
Coût : $0.018
Économie : 88% ! 🎉
```

---

## 📊 Suivi des tokens

### Comment je compte les tokens

Après chaque opération, je reçois un message système :

```xml
<system_warning>Token usage: 61058/1000000; 938942 remaining</system_warning>
```

**Signification :**
- `61058` = Tokens utilisés depuis le début de la conversation
- `1000000` = Budget total (1 million de tokens)
- `938942` = Tokens restants

### Calcul pour une demande spécifique

**Exemple :**
```
Début de ta demande : 27,888 tokens utilisés
Fin de ta demande   : 58,098 tokens utilisés
───────────────────────────────────────────
Coût de la demande  : 30,210 tokens
```

### Budget typique

Pour une conversation Cursor avec Claude :
- **Budget total** : 1,000,000 tokens
- **Contexte initial** : ~10,000-20,000 tokens
- **Marge disponible** : ~980,000 tokens

**Équivalent en pages :**
- 1M tokens ≈ **1,500-2,000 pages** de texte
- 1M tokens ≈ **75,000 lignes** de code

### Indicateurs de consommation

| Niveau | Tokens utilisés | % Budget | Statut |
|--------|----------------|----------|--------|
| 🟢 Faible | 0-100K | 0-10% | Excellent |
| 🟡 Moyen | 100K-300K | 10-30% | Bon |
| 🟠 Élevé | 300K-600K | 30-60% | Attention |
| 🔴 Critique | 600K-900K | 60-90% | Limite proche |
| ⛔ Maximum | 900K-1M | 90-100% | Fin imminente |

### Que se passe-t-il à 1M tokens ?

Quand le budget est atteint :
1. **Résumé automatique** : L'historique est résumé
2. **Nouveau contexte** : Une nouvelle fenêtre démarre
3. **Continuité** : Les infos importantes sont conservées
4. **Pas de perte** : Le travail continue normalement

---

## 💡 Conseils pratiques

### Pour les développeurs

1. **Posez des questions ciblées**
   - ❌ "Analyse tout mon projet"
   - ✅ "Analyse le provider de jeu"

2. **Groupez vos demandes**
   - ❌ 10 petites conversations
   - ✅ 1 conversation avec 10 questions

3. **Soyez spécifique**
   - ❌ "Améliore le code"
   - ✅ "Optimise la fonction selectPiece() dans le provider"

4. **Réutilisez le contexte**
   - ❌ Recommencer à zéro
   - ✅ Continuer la conversation

### Pour les projets

1. **Documentation incrémentale**
   - Mettez à jour par sections
   - Pas tout d'un coup

2. **Refactoring progressif**
   - Un fichier à la fois
   - Testez entre chaque étape

3. **Code reviews ciblées**
   - Fichiers spécifiques
   - Fonctionnalités précises

---

## 📚 Résumé rapide

### Conversions essentielles

```
1 token ≈ 3-4 caractères (code)
1 token ≈ 2-3 caractères (français)
1 ligne de code Dart ≈ 12-15 tokens
100 lignes de code ≈ 1,300 tokens
1,000 lignes de code ≈ 13,000 tokens
```

### Prix Claude Sonnet 4.5

```
Input  : $3 / 1M tokens  = $0.003 / 1K tokens
Output : $15 / 1M tokens = $0.015 / 1K tokens

Output = 5× plus cher que Input
```

### Coûts typiques

```
Question simple        : $0.02
Explication détaillée  : $0.05
Lecture code          : $0.07
Génération doc        : $0.15
Refactoring           : $0.25-0.40
Analyse projet        : $0.60
```

### Optimisation

```
✅ Questions ciblées
✅ Réutiliser le contexte
✅ Limiter l'output
✅ Grouper les demandes

= Économie de 50-80% possible !
```

---

## 🎓 Conclusion

### Points clés à retenir

1. **Les tokens sont des unités de traitement**, pas exactement des mots
2. **L'output coûte 5× plus cher** que l'input
3. **1 ligne de code ≈ 13 tokens** en moyenne
4. **Claude Sonnet 4.5 est très abordable** : quelques centimes par tâche
5. **L'optimisation peut économiser 50-80%** des coûts

### Perspective

Pour le prix d'un café ☕ (~$3), vous pouvez :
- Analyser **1 million de tokens** en input
- Lire **~75,000 lignes de code**
- Ou générer **~15,000 lignes de documentation**

**C'est incroyablement rentable pour le développement logiciel!** 🚀

---

**Dernière mise à jour : 23 novembre 2025 05:29**

**Auteur : Documentation générée par Claude Sonnet 4.5**

**Coût de génération de ce document : ~$0.17 (17 centimes)** 💰



