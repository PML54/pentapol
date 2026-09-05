# Base locale (sur l'appareil) — ce que Pentapol garde

> Mémo : ce que l'app stocke **sur le téléphone**, dans quelle structure, quand c'est écrit/effacé.
> Pendant, la base Cloudflare (classement en ligne) est décrite dans `CLOUDFLARE_CONFIG.md`.
> Source de vérité : `lib/database/settings_database.dart` et `lib/models/app_settings.dart`.

---

## 1. Vue d'ensemble

**Une seule base, locale, `drift`/SQLite** — aucun cloud, aucun `SharedPreferences`, aucun fichier à
côté.

| Champ | Valeur |
|---|---|
| Fichier | `pentapol_settings.db` |
| Emplacement | dossier *Documents* de l'app (`getApplicationDocumentsDirectory`) |
| Techno | `drift` (SQLite natif) |
| `schemaVersion` | **9** |
| Migration | `destructiveFallback` — **efface et recrée** à tout changement de version |

> ⚠️ **Réécriture destructive.** Tant que l'app n'est pas publiée, un changement de `schemaVersion`
> **efface toute la base** au prochain lancement (réglages, partie en cours, records). C'est voulu
> (pas de migration à écrire en développement). **À remplacer par une vraie migration avant la
> première soumission App Store** (voir `CHECKLIST_APPSTORE.md`).

> **Portée** : purement local. **Désinstaller l'app efface tout** — y compris l'identité 128 bits
> (`playerId`), donc l'historique de classement en ligne. Rien n'est synchronisé ni transférable.

---

## 2. Les quatre tables

### `Settings` — les réglages (clé/valeur)
Une seule ligne utile, clé `app_settings`, valeur = **tout `AppSettings` en JSON**. Ajouter/retirer
un champ ne demande **aucune migration** (c'est du JSON dans une colonne texte).

Champs de `AppSettings` (voir `app_settings.dart`) :

| Champ | Rôle |
|---|---|
| `ui`, `game`, `duel` | préférences (affichage, jeu, duel) |
| `userName` | pseudo du joueur (saisi au 1er succès) |
| `currentLevel` | niveau de progression solo (1..9) |
| `playerId` | **identité 128 bits** (32 hex) — clé du joueur pour le classement en ligne, distincte du pseudo. Générée à la 1re soumission de défi. |

### `CurrentGame` — la partie en cours (une seule ligne, `id = 0`, écrasée)
Permet de **reprendre** une partie interrompue. Ne stocke **ni le plateau** (reconstruit depuis
`placedPieces`) **ni les solutions** (dans les `.bin`).

| Colonne | Contenu |
|---|---|
| `sizeName` | taille (`PentoscopeSize.name`, ex. `size6x10`) |
| `pieceIds` | le tirage (`'1,2,3,…'`) |
| `solutionCount` | nombre de solutions du tirage |
| `placedPieces` | JSON `[{id,pos,x,y}, …]` — les pièces posées |
| `positionIndices` | JSON `{pieceId: orientation}` — orientations courantes |
| `initialOrientations` | JSON — le **rack distribué** (figé), pour l'acuité (🟡) |
| `elapsedSeconds` | temps écoulé |
| `isometryCount`, `translationCount`, `deleteCount`, `hintCount`, `faultCount` | compteurs (voir maillots) |
| `isProgression` | la partie fait-elle avancer le niveau |
| `savedAt` | horodatage |

**Écrite** après chaque pose/retrait et au passage en arrière-plan. **Effacée** à la complétion et au
démarrage d'une partie neuve. **Non écrite** en multijoueur ni en **défi** (éphémère).

### `SolvedSolutions` — records des rectangles complets (une ligne par solution découverte)
Clé `(board, solutionNumber)`. Pour le 6×10 (et, à terme, 5×12/4×15).

| Colonne | Contenu |
|---|---|
| `board`, `solutionNumber` | quelle solution (ex. `6x10`, n° 1..9356) |
| `timesSolved` | nombre de fois résolue |
| `bestAcuityMinIso` + `bestAcuityIsoCount` | 🟡 meilleur score d'acuité (ingrédients bruts, plafonné à 100 %) |
| `bestFaults` | 🔴 moins de fautes (culs-de-sac jaune→rouge) |
| `bestTimeSeconds` | 🟢 meilleur temps |
| `firstSolvedAt`, `lastSolvedAt` | horodatages |

### `PuzzleStats` — records des tailles à pièces tirées (un agrégat par taille)
Clé `sizeName`. Mêmes trois bests que ci-dessus, plus `completed` (nombre de complétions).

> Les trois bests sont **nullables** et **indépendants** (ils peuvent venir de trois parties
> différentes). Une partie **avec aide** (`hintCount > 0`) incrémente `completed`/`timesSolved` mais
> **ne pose aucun record**. Une partie de **défi** (mode classé) **n'écrit pas** ici (son classement
> est en ligne).

---

## 3. Ce qui n'est PAS stocké (et pourquoi)

- **Le plateau** : reconstruit depuis `placedPieces` (`_rebuildPlateau`).
- **Les solutions** : dans les assets `.bin`, jamais dupliquées en base.
- **Un journal partie par partie** : on garde des **agrégats** (records), pas l'historique complet —
  une table qui grossirait sans fin pour une donnée que personne ne relit.

---

## 4. Inspecter la base (développement)

La base vit dans le conteneur de l'app (device/simulateur). En pratique, on l'observe via les
**écrans** (Mes records, reprise de partie) plutôt qu'en SQL. Il n'y a **plus** d'écran de debug
(`DatabaseDebugScreen` retiré).

> ⚠️ `settings_database.g.dart` (code drift généré) est **gitignoré** : après un `pull`, régénérer
> par `dart run build_runner build --delete-conflicting-outputs`.

---

## 5. Voir aussi

- `CLOUDFLARE_CONFIG.md` — la base **en ligne** (classement du défi).
- `MANUEL_DEFIS_ET_MAILLOTS.md` — le sens des compteurs et des maillots.
- `PLAN_PERSISTANCE.md` — le plan d'origine de la persistance (les étapes, la réécriture destructive
  et sa date de péremption).
- `CHECKLIST_APPSTORE.md` — **retirer la stratégie destructive** avant publication.
