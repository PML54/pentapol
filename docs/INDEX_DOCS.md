# Index de `docs/` — à quoi sert chaque fichier, et lequel ment

> Écrit par cowork le 2026-09-07, par vérification mécanique du dépôt à `731775a` :
> pour chaque document, date du dernier commit qui l'a touché, et existence réelle de
> **tous** les chemins `lib/`, `tools/`, `server/`, `test/`, `assets/` qu'il cite.
> Un chemin mort n'est pas forcément une erreur (plusieurs documents assument leur part
> d'histoire dans un encadré) — les écarts non signalés sont listés en §3.
>
> **Ce fichier n'est pas une source de vérité** : c'est une table des matières. La source
> de vérité de l'état courant reste `JOURNAL.md` §ÉTAT.

---

## 1. Par usage

### Ce qu'on ouvre pour savoir où on en est

| Fichier | Ko | Dernier commit | En un mot | État |
|---|---|---|---|---|
| **`JOURNAL.md`** | 52 | 2026-09-06 | §ÉTAT (réécrite à chaque passage) + passations CLI ↔ cowork + cartographie du bug de glissé | **à jour** — le point d'entrée |
| **`MODUS_VIVENDI.md`** | 10 | 2026-08-31 | Le protocole à deux agents : qui touche quoi, ce qui doit s'écrire dans le dépôt | **à jour** (règles, pas d'état) |
| **`CHECKLIST_APPSTORE.md`** | 11 | 2026-09-06 | Dettes à solder avant la première soumission : bloquants technique / produit / conformité | **partiellement périmé** — cf. §3.2 |

### Spécification et produit

| Fichier | Ko | Dernier commit | En un mot | État |
|---|---|---|---|---|
| **`CAHIER_DES_CHARGES_V1.md`** | 40 | 2026-09-05 | Le CDC de la V1 : positionnement, maillots, tirages, défi, modèle économique. Chaque nombre est mesuré, pas estimé | **à jour sauf §7** — cf. §3.1 |
| **`MANUEL_DEFIS_ET_MAILLOTS.md`** | 13 | 2026-09-05 | Les trois maillots (acuité / fautes / temps), formules exactes, records perso vs défi en ligne | **à jour, fait foi** sur les maillots |
| **`FICHE_APP_STORE.md`** | 8 | 2026-09-06 | La vitrine : nom, sous-titre, mots-clés, description, dans les limites App Store Connect | **à jour, incomplet par construction** — version FR seule, le pendant EN reste à écrire |
| **`PLAN_ECRAN_ACCUEIL.md`** | 6 | 2026-09-02 | Maquette validée de l'écran d'accueil : plateau, vignette animée, un bouton | **livré** — plan appliqué, candidat à suppression (`MODUS_VIVENDI` §5) |

### Références de calcul — rejouables, ne périment pas

| Fichier | Ko | Dernier commit | En un mot | État |
|---|---|---|---|---|
| **`REFERENCE_ISOMETRIES.md`** | 12 | 2026-09-03 | Coût d'une isométrie, `minIso`, chiralité des tirages. Rejouable : `python3 tools/verif_isometries.py` | **à jour** — script présent |
| **`REFERENCE_TIRAGES.md`** | 15 | 2026-09-03 | Tirages solubles et nombre de solutions 5×n ; test d'acceptation du générateur. Rejouable : `tools/verif_subset_counts.py` | **à jour** — script présent |
| **`PIECES_ENCODING.md`** | 13 | 2026-08-27 | Grille 5×5 de référence, numérotation des cases, encodage par bits des 63 orientations | **à jour** — géométrie, rien à périmer |

### Architecture et fonctionnement

| Fichier | Ko | Dernier commit | En un mot | État |
|---|---|---|---|---|
| **`FONCTIONNEMENT.md`** | 27 | 2026-08-31 | Documentation fonctionnelle générale (Pentoscope fusionné dedans) | ⚠️ **le plus périmé** — cf. §3.3 |
| **`BASE_LOCALE.md`** | 5 | 2026-09-05 | Ce que l'app garde sur le téléphone : une base drift, quatre tables, cycle de vie | **à jour à un chiffre près** (§3.4) |
| **`CLOUDFLARE_CONFIG.md`** | 6 | 2026-09-05 | Les deux workers Cloudflare (`pentapol-duel` hors dépôt, `pentapol-defi` dans `server/`), config et commandes | **à jour** — porte déjà `faults` |
| **`services.md`** | 9 | 2026-08-31 | La chaîne `.bin` → loader → matcher → compteur, dans `lib/services/` | **périmé sur un point** (§3.5) |
| **`MEMO_DEPLACEMENT_PIECES.md`** | 10 | 2026-08-30 | Drag & drop : mastercase, ancre, snapping vers les poses valides | **valide**, mais l'analyse fine du bug intermittent est dans `JOURNAL.md`, pas ici |
| **`I18N.md`** | 6 | 2026-09-06 | Mécanique EN/FR : `l10n.yaml`, ~90 clés ARB, comment ajouter une chaîne sans texte en dur | **à jour** — le plus récent |

### Multijoueur — seule trace du protocole serveur

| Fichier | Ko | Dernier commit | En un mot | État |
|---|---|---|---|---|
| **`DUEL_ISOM_ARCH.md`** | 38 | 2026-08-29 | Flux complet du duel : création de room, WebSocket, phases, messages | **vivant, ne pas supprimer** — le worker duel n'est pas dans ce dépôt |
| **`BILAN_DUEL_ISOMETRIES.md`** | 13 | 2026-08-30 | Objectif, architecture seed-based et avancement du duel (avancement daté déc. 2025) | **vivant** — architecture valide, avancement daté |

### Histoire, à lire pour comprendre un choix

| Fichier | Ko | Dernier commit | En un mot | État |
|---|---|---|---|---|
| **`ANALYSE_STOCKAGE_POSITIONS.md`** | 35 | 2026-08-30 | Comment sont codées les positions ; **§7 = fondement combinatoire**, la référence du projet sur le choix des codes | **mi-histoire mi-référence** — encadré à compléter (§3.6) |
| **`PLAN_6X10_DANS_PENTOSCOPE.md`** | 12 | 2026-08-31 | Les tables pré-calculées ; ce qui reste = **§5, tables 5×12 et 4×15** | **périmé sur la méthode**, valide sur l'objectif (§3.7) |
| **`PLAN_PERSISTANCE.md`** | 12 | 2026-08-31 | Plan des quatre étapes de la base locale | ⚠️ **contredit par `JOURNAL.md`** (§3.8) |
| **`ICON_GENERATION.md`** | 6 | 2025-12-01 | Génération des icônes Android/iOS par `flutter_launcher_icons` | **le plus ancien** — deux fichiers cités n'existent pas |

---

## 2. Lequel ouvrir selon la question

| La question | Le fichier |
|---|---|
| Où en est-on aujourd'hui ? | `JOURNAL.md` §ÉTAT |
| Qui a le droit de faire quoi ? | `MODUS_VIVENDI.md` |
| Qu'est-ce qui bloque la publication ? | `CHECKLIST_APPSTORE.md` (à relire, §3.2) |
| Comment un maillot est-il calculé ? | `MANUEL_DEFIS_ET_MAILLOTS.md` |
| Combien de solutions pour ce tirage ? | `REFERENCE_TIRAGES.md` |
| Combien coûte une réflexion ? | `REFERENCE_ISOMETRIES.md` |
| Comment une pièce est-elle codée ? | `PIECES_ENCODING.md`, puis `ANALYSE_STOCKAGE_POSITIONS.md` §7 |
| Qu'est-ce qui est écrit sur le téléphone ? | `BASE_LOCALE.md` |
| Qu'est-ce qui tourne en ligne ? | `CLOUDFLARE_CONFIG.md` (défi) et `DUEL_ISOM_ARCH.md` (duel) |
| Comment ajouter une chaîne traduite ? | `I18N.md` |

---

## 3. Les écarts constatés — par ordre de gravité

### 3.1 🔴 Le défi en ligne est dit « hors V1 » et il est pourtant livré, déployé, et atteignable

**Fait.** `CAHIER_DES_CHARGES_V1.md` §7 porte en tête : « **Hors V1** — décision de Paul du
2026-09-03 (§12, Q3) ». `JOURNAL.md` répète « **HORS V1** » dans la ligne du chantier.

**Fait.** Le même journal, la même ligne, conclut : « **Le défi est complet de bout en bout** » —
phases 0 à 5 plus extras, worker `pentapol-defi` en ligne, D1 réinitialisée le 2026-09-05, client
`challenge_api.dart`, écran de classement à trois onglets, atteignable **par l'icône classement
d'une taille** *et* **par un bouton au bilan d'un défi**.

**Fait.** `pentoscope_provider.dart` ligne ~957 : `_submitChallengeScore()` est appelée à la
complétion d'un défi, **sans condition**. Elle envoie `playerId` (identité 128 bits persistante),
`pseudo`, les trois métriques et la **grille terminée**.

**Fait.** Le CDC prévoyait pourtant l'inverse. §4.5 : « Le classement n'apparaît que si le joueur
a **activé l'envoi de score** (§7). » §8, en toutes lettres : « **Recommandation :** envoi de score
**désactivé par défaut**, activé par un geste explicite du joueur. […] Cela garde "aucune donnée
collectée" comme comportement par défaut et rend la déclaration honnête. » Et §7.4 : « **RGPD** :
un identifiant persistant lié à une activité *est* une donnée personnelle, même sans nom. » Aucun
`optIn`, `consent` ni booléen d'envoi n'existe dans `lib/` : l'envoi est inconditionnel.

**Conséquence — c'est là que ça fait mal.** `CHECKLIST_APPSTORE.md` point 12 (App Privacy) affirme
que l'app « ne collecte **rien** » *parce que* le classement est hors V1 ; le point 13 conclut
« **rien à faire ici pour la V1** » sur la suppression de compte. Les deux reposent sur une
prémisse que le code contredit. Si la V1 part avec ce binaire, la déclaration App Privacy est
fausse et l'exigence Apple de suppression d'identité redevient exigible.

**Ce que je ne peux pas trancher à ta place** : soit le défi est *effectivement* coupé du build V1
(je n'ai trouvé aucun interrupteur qui le fasse), soit la décision « hors V1 » est caduque depuis
le 2026-09-04. Il faut choisir — et les points 12 et 13 de la checklist se réécrivent dans les deux
cas.

### 3.2 🟠 Trois points de la checklist ne correspondent plus au dépôt

| Point | Ce que dit la checklist | Ce que dit le dépôt |
|---|---|---|
| 1 | « `flutter test` est rouge, `test/widget_test.dart` est le template par défaut » | **Le fichier n'existe plus.** `test/` contient 11 fichiers de tests réels ; le journal annonce 49/49 au vert |
| 2 | « Retirer `supabase_flutter` », « `lib/bootstrap.dart` » | **Fait.** Aucune occurrence de `supabase` dans `pubspec.yaml`, `bootstrap.dart` supprimé (étape 1 de la persistance) |
| 7 | « `version: 1.0.0+1` » | `pubspec.yaml` dit toujours `1.0.0+1`, mais `lib/config/build_info.dart` dit **1.0.3 / build 202609061842**, régénéré par `scripts/update_version.sh`. Deux sources de version qui divergent : à réconcilier avant de téléverser, c'est `pubspec.yaml` qu'Apple lit |

**Et un bloquant absent** : `PRODUCT_BUNDLE_IDENTIFIER = com.example.pentapol` (iOS) et
`applicationId = "com.example.pentapol"` (Android). Le journal le signale comme « nouveau
bloquant » ; il n'est **pas** dans `CHECKLIST_APPSTORE.md`, qui est pourtant décrit comme « le seul
endroit où ces dettes sont rassemblées ».

### 3.3 🟠 `FONCTIONNEMENT.md` décrit une application qui n'existe plus

Dernier commit **2026-08-31**, avant trois chantiers qui changent ce qu'on voit à l'écran :

- ligne 139 : « **Il n'y a plus d'écran d'accueil ni de route nommée.** `HomeScreen` a été
  supprimé » — faux depuis le 2026-09-02 (accueil livré) et surtout le 2026-09-05 (menu d'entrée
  devenu hub mono/multi/réglages) ;
- **zéro occurrence** de « maillot », « faute », « défi » : la refonte « A » du 2026-09-05 et tout
  le mode défi lui sont invisibles ;
- **une** occurrence d'i18n : le bilinguisme du 2026-09-06 n'y est pas.

C'est le document qu'un lecteur neuf ouvrira en premier après le journal. En l'état il l'égare.

### 3.4 🟡 `BASE_LOCALE.md` — `schemaVersion` **9**, le code dit **10**

`lib/database/settings_database.dart:129` : `int get schemaVersion => 10;` (bump du 2026-09-05,
`helpCount`→`faultCount`). Le reste du document a bien suivi la refonte — il documente déjà
`bestFaults`. Seul le numéro est resté en arrière : une ligne à corriger.

### 3.5 🟡 `services.md` — « **trois** fichiers », il y en a **deux**

`lib/services/` contient `pentapol_solutions_loader.dart` et `solution_matcher.dart`.
`pentomino_solver.dart` a été supprimé le 2026-08-31 (étape B), soit **après** le dernier commit du
document. Il cite aussi `tools/generate_6x10_solutions.dart` et `tools/solutions_6x10_brutes.bin`,
supprimés au même moment — l'énumération est reprise par `tools/generate_solutions_corpus.dart`.

### 3.6 🟡 `ANALYSE_STOCKAGE_POSITIONS.md` — l'encadré ne couvre pas la purge du 2026-08-31

L'encadré du 2026-08-29, complété le 2026-08-30, désamorce déjà treize identifiants morts. Mais six
chemins qu'il ne mentionne pas ont disparu **depuis** : `lib/services/pentomino_solver.dart`,
`lib/pentoscope/pentoscope_solver.dart`, `tools/generate_6x10_solutions.dart`,
`tools/generate_canonical_solutions.dart`, `tools/solutions_6x10_brutes.bin`,
`assets/solutions_canonical.bin`. Un troisième paragraphe d'encadré suffit — **le §7 reste la
référence du projet** et justifie à lui seul de garder le fichier.

### 3.7 🟡 `PLAN_6X10_DANS_PENTOSCOPE.md` — l'objectif tient, la méthode a changé

Le « reste à faire » (§5 : tables **5×12** et **4×15**, le 3×20 écarté) est toujours d'actualité, et
c'est le remède direct aux points 9 et 10 de la checklist. Mais le plan s'appuie sur
`pentomino_solver.dart` et `tools/generate_6x10_solutions.dart`, tous deux supprimés : le chemin
réel passe désormais par `tools/generate_solutions_corpus.dart` et `CorpusSolutionSource`.

### 3.8 🟡 `PLAN_PERSISTANCE.md` — se dit inachevé, le journal le dit fait

Le plan annonce « **Étape 1 faite**, restent les étapes 2 à 4 ». `JOURNAL.md` §ÉTAT : « Persistance
(PLAN_PERSISTANCE, 4 étapes) — **faite et committée** ». Le plan cite `lib/bootstrap.dart`,
supprimé. Deux plans appliqués (celui-ci et `PLAN_ECRAN_ACCUEIL.md`) survivent alors que
`MODUS_VIVENDI` §5 prévoit de supprimer un plan une fois appliqué et testé — ce sont les deux seuls
documents du dossier qui décrivent un futur déjà passé.

### 3.9 ⚪ Détails

- `BILAN_DUEL_ISOMETRIES.md` cite `lib/duel_isometry/services/isometry_puzzle.dart` — inexistant,
  **déjà signalé** dans son propre encadré. Rien à faire.
- `ICON_GENERATION.md` cite `ic_launcher_background.xml` et `notification_icon.png`, absents de
  `android/`. Document de décembre 2025, jamais rouvert.
- `JOURNAL.md` cite `lib/common/drag_diag.dart` — normal, c'est l'instrumentation conservée sur la
  branche de backup, pas dans le tree.
- `services.md` est le seul fichier en minuscules du dossier.

---

## 4. Si tu ne devais faire que trois choses

1. **Trancher §3.1** — le défi est-il dans la V1 ou non ? Tout le §Conformité de la checklist en
   dépend, et c'est le seul écart qui peut coûter un rejet.
2. **Réviser `FONCTIONNEMENT.md`** contre le code (§3.3) : accueil, hub, maillots, défi, i18n.
3. **Nettoyer la checklist** (§3.2) : retirer les points 1 et 2 déjà soldés, y inscrire le bundle
   identifier, réconcilier les deux sources de numéro de version.

Les §3.4 à §3.8 sont des corrections d'une à dix lignes chacune, sans urgence.
