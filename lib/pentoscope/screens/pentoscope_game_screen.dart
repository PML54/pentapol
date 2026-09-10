// Modified: 2026-09-10 06:30 — ergonomie (bloc 3, décision 6) : taille du rack pilotée par le réglage
//           live `settings.game.rackCellRatio` (_barMetrics prend pieceRatio) — rack ~1:4 trop petit
//           (C5) ; défaut figé à 0.46 après calibrage device de Paul (const = défaut seulement).
// Historique: 2026-09-10 05:42 — ergonomie (bloc 2) : chrono en `m:ss` (C7) au lieu des secondes brutes ;
//           compteur de solutions = chiffre SEUL + tooltip `compatibleSolutionsTooltip` (C1, retour
//           de Paul : le glyphe mangeait de la place) ; kShowLiveCounters=false → overlay haut-gauche
//           « rien ou total » selon showCounters, bande debug débranchée (C9). Décisions 8, 9.
// Historique: 2026-09-09 09:20 — réglage « compteurs » : récap 🔄 isométries · ⚫ fautes en OVERLAY haut-gauche
//           (sous l'AppBar, _statsOverlay) si settings.game.showCounters — pas dans la barre. S'exclut du
//           bandeau debug (même coin). Retour de Paul.
// Historique: 2026-09-09 08:15 — mode entraînement (Option A) : le game screen gère isTraining — carte de
//           bilan d'exercice (_buildTrainingCard : appuis/min/temps + « Suivante »=startTraining) sur
//           _trainingSolved (pièce sur le fantôme), enregistrement de l'exercice, « + » = exercice
//           suivant, indice masqué. Même UI que le jeu (barre isométrie en haut, tiroir en bas).
// Historique: 2026-09-09 07:01 — marge latérale du plateau (kBoardSideMargin, 26 pt/côté) appliquée en
//           portrait au plateau ET à _barMetrics (§3) : un grand plateau prenait toute la largeur →
//           le doigt butait sur le bord écran en positionnant (suivi 1:1). N'affecte que les plateaux
//           limités par la largeur. Défaut sensibilité 50-200 (voir app_settings).
// Historique: 2026-09-09 06:06 — pose ligne du bas : le rack (_buildSliderWithDragTarget) accepte aussi
//           une pièce DU RACK quand un aperçu valide est en attente (previewX/Y + isPreviewValid) et la
//           pose via tryPlaceAtAnchor — le bord bas collé au rack faisait relâcher au ras du rack, geste
//           perdu. Rouge/poubelle réservés au retrait. Géométrie de pose inchangée.
// Historique: 2026-09-09 05:29 — centralisation score : le % d'acuité du bilan lit m.acuityPercent
//           (règle unique score_rules) au lieu de recalculer (m.acuity*100).round(). Comportement
//           identique (parties propres). Manipulation des pièces inchangée.
// Historique: 2026-09-07 16:45 — plafond de case PROPORTIONNEL à l'écran (kMaxBoardCellFactor +
//           maxBoardCellSize(context)) au lieu de l'absolu 84 qui rapetissait tout sur tablette ;
//           _barMetrics reçoit le plafond résolu.
// Historique: 2026-09-07 14:41 — DEBUG test : bandeau 3ᵉ ligne = diagnostic de l'ÉTAT COURANT
//           (analyzeFault(state.plateau) recalculé à chaque coup — iso/translation/ajout/retrait).
// Historique: 2026-09-07 14:20 — DEBUG test : bandeau à deux lignes — ligne 2 = classification des
//           fautes (⚠️ aire non-mult-5 / 🌫️ subtile / Σg somme de gravité, via fault_analysis).
// Historique: 2026-09-07 11:05 — DEBUG test : bandeau des compteurs live — ajout des retraits en rouge
//           (🚑 state.redRemovalCount, sorties de cul-de-sac) à côté de iso/fautes/translations.
// Historique: 2026-09-07 10:59 — DEBUG test : bandeau des compteurs live — ajout des translations
//           (state.translationCount, déjà suivi) à côté de iso/fautes, pour observer son utilité.
// Historique: 2026-09-07 10:45 — DEBUG test : bandeau coin haut-gauche des compteurs live (iso/fautes),
//           gated par kShowLiveCounters (à repasser false avant soumission — CHECKLIST_APPSTORE) ;
//           chiffres agrandis (fontSize 13→20).
// Historique: 2026-09-07 09:35 — AppBar : retrait de l'icône visionneuse (navigateur de solutions,
//           view_carousel — buggé en 6×10, choix de Paul) ; import solutions_browser_screen devenu inutile.
// Historique: 2026-09-07 09:20 — AppBar : icônes agrandies (_kIconSizeFactor 0.075→0.11, min 30→40)
//           et retrait de l'icône Icons.person (reset « recommencer ») — choix de Paul.
// Historique: 2026-09-07 09:13 — taille des pièces : k 0.22→0.26 (pièces de barre plus grosses) +
//           kMaxBoardCellSize (borne haute de la case du plateau, supprime la « falaise » des
//           petits plateaux) ; le plafond est aussi appliqué à boardCell dans _barMetrics.
// Historique: 2026-09-07 07:34 — conformité défi V1 : proposition d'opt-in à la 1re complétion d'un défi
//           (maybeProposeConsentOnChallengeCompletion, après l'éventuelle saisie du nom).
// Historique: 2026-09-07 07:17 — conformité défi V1 : « Voir le classement » du bilan passe par
//           openLeaderboardWithConsent (opt-in requis §4.5 ; soumission du défi terminé après consentement).
// Historique: 2026-09-06 04:50 — i18n : toutes les chaînes visibles (barre, dialogues nouvelle partie /
//           saisie du nom, bilan, maillots, tooltips d'isométrie) via AppLocalizations.
// Historique: 2026-09-05 17:24 — bilan 3 maillots (A) : acuité (plafonnée) / FAUTES / temps ; partie AVEC
//           aide → « Résolu avec N aide(s) » + temps, sans maillots ni médaille. Plus de « coups »/« Help ».
// Historique: 2026-09-05 — hub d'accueil : barre de jeu allégée — bouton « Accueil » (retour au menu
//           via popUntil isFirst), retrait du multijoueur et des réglages (déplacés sur l'accueil).
// Historique: 2026-09-05 01:10 — bilan d'un défi : bouton « Voir le classement » → LeaderboardScreen
//           (week/size du défi actif). Accès direct au classement après avoir joué.
// Historique: 2026-09-04 15:57 — bilan : 4e maillot BLANC (Help / sauvetages rouge→jaune) ajouté à la
//           carte ; pastille bordée pour rendre le blanc visible.
// Historique: 2026-09-04 07:05 — carte de bilan DÉPLAÇABLE au doigt (poignée + _bilanOffset, recentré
//           au prochain bilan) — choix de Paul.
// Historique: 2026-09-04 06:56 — défi hebdo Phase 2 : en mode classé (state.isRanked, §4.8) l'appui
//           sur l'ampoule est neutralisé (message ; couleur conservée, retrait via sélection+poubelle).
// Historique: 2026-09-04 06:45 — bilan en carte flottante non-modale (centrée sur le plateau résolu,
//           fermable, un tap sur le plateau la rouvre) au lieu du bandeau bas ; chrono et compteur
//           de solutions masqués à la complétion (l'info de fin est regroupée dans la carte). Paul.
// lib/pentoscope/screens/pentoscope_game_screen.dart
// Historique: 2026-09-04 06:13 — médaille §4.6 : badge « Vision parfaite » dans le bandeau quand
//           acuité 100 % sur une partie sans aide (perfectVision && hintCount==0).
// Historique: 2026-09-04 05:20 — records perso A2 (CDC §4.5) : le bandeau de bilan affiche les trois
//           maillots — acuité %, coups (brut), temps — via computeCompletionMetrics ; détail
//           (isométries, minimums) en tooltip. Remplace les compteurs bruts iso/translation/delete.
// Historique: 2026-09-02 20:37 — progression solo : à la complétion d'un puzzle de progression du
//           niveau courant → advanceLevel (via ref.listen) ; 1er puzzle réussi → dialogue de saisie
//           du nom (setUserName) ; bilan avec bouton « Niveau suivant » (remplace « Nouvelle partie »).
// Historique: 2026-09-02 19:20 — icônes d'isométrie du PAYSAGE agrandies à isometryIconSize (comme le
//           portrait) ; la colonne d'actions paysage est élargie pour ne pas rogner.
// Historique: 2026-09-02 19:15 — suppression aussi du message « Transformation impossible » : plus
//           aucun SnackBar dans _handleTransformationResult (recentered + impossible), seuls les
//           retours haptiques restent (retour de Paul).
// Historique: 2026-09-02 17:29 — suppression du message « Recentrage » (SnackBar) lors d'une
//           rotation/miroir qui recale la pièce : recentrage silencieux, haptique conservée.
// Historique: 2026-09-02 11:28 — retrait de l'icône grid_view_rounded devant le compteur de
//           solutions (_buildSolutionCounter) — décorative, sans fonction (retour de Paul).
// Historique: 2026-09-02 11:03 — icônes de la barre d'isométrie agrandies en portrait via la
//           fonction partagée isometryIconSize (game_icons_config) — retour de Paul « trop petites
//           sur iPhone ». Paysage inchangé (rail compact, _uiIconSize).
// Historique: 2026-09-02 09:28 — #3 cul-de-sac actionnable : la pose reste autorisée même en rouge ;
//           l'ampoule rouge devient un « retour en arrière » (un appui = removePlacedPiece de la
//           dernière pièce, répétable). Ampoule inchangée (jaune = indice, rouge = retour).
// Historique: 2026-09-02 04:31 — retrait de la puce diag « c0..c4 » (_buildMastercaseChip /
//           _mastercaseLabel) et de son insertion dans la barre d'isométrie : diagnostic terminé.
// Historique: 2026-09-01 16:10 — DIAGNOSTIC (kDragDiag) : puce « c0..c4 » dans la barre d'isométrie
//           affichant le label INVARIANT de la mastercase active (index de la cellule saisie dans
//           l'orientation, stable par isométrie) — pour voir si la prise reste fixe.
// Historique: 2026-08-31 16:39 — étape B : avec CorpusSolutionSource, solutionsCount non-nul sur
//             toutes les tailles → compteur décroissant partout ; bouton « solutions » regaté au 6×10.
// Historique: 2026-08-31 18:00 — tirage au dialogue (§Affichage) : masque tiré, « n solutions »,
//             bouton « autre tirage » (hors 6×10), masque transmis à startPuzzle.
// Historique: 2026-08-31 17:00 — suppression de la difficulté : retrait du SegmentedButton du dialogue.
// Historique: 2026-08-31 16:00 — regroupement des sept valeurs de réglage visuel en un bloc de
//             constantes nommées en tête de fichier (dont kPieceToBoardCellRatio, rapatrié du board).
// Historique: 2026-08-31 15:00 — réglage à l'œil : _kSliderPad 32 → 20 ; k 0.45 → 0.35 (board).
// Historique: 2026-08-31 14:20 — bug iOS : body enveloppé dans un SafeArea.
// Historique: 2026-08-31 11:00 — PLAN_ERGONOMIE §9 (décisions 65-68) : une seule barre d'actions
//             pour les deux orientations — _buildBarItems rendue en Row (portrait) / Column (paysage) ;
//             retrait de actions:/leading ; chrono central ; trois compteurs sortis ; supersède §4d.
// Historique: 2026-08-31 09:30 — §7 (décision 61) : ordre des zones en paysage aligné sur le portrait.
// Historique: 2026-08-30 15:10 — §4d (décision 59) : icônes de l'AppBar via iconTheme (superseédé par §9).
// Historique: 2026-08-30 13:45 — PLAN_ERGONOMIE §6 étape 3 : helper _uiIconSize/_uiAppBarHeight,
//             remplace les quatre constantes (56, 42, clamp 28-50, clamp 20-36).
// Historique: 2026-08-30 13:35 — PLAN_ERGONOMIE §6 étape 2 : barre ancrée sur le plateau (_barMetrics).
// Historique: 2026-08-30 06:12 — PLAN_BILAN §2 : dialogue modal de fin de partie → bandeau non modal.
// Historique: 2026-08-30 06:04 — PLAN_BILAN §3 : retrait de la ligne Score et de son calcul
//             du score (rapport non homogène) et de son calcul, dans le dialogue de fin.
// Historique: 2026-08-29 20:22 — dialogue « Nouvelle partie » (§8 étape 3) : _showSizeChangeDialog
//             devient _showNewGameDialog (StatefulBuilder : taille + difficulté + montrer la
//             solution, bouton « Lancer » → startPuzzle direct). Absorbe l'ancien écran de menu.
//             Bouton reset renommé « Recommencer (même taille) » pour lever l'ambiguïté.
// Historique: 2026-08-29 20:18 — étape 2 : bouton Réglages dans l'AppBar.
//             2026-08-29 14:02 — étape 6 : retrait du bouton « Mode Classique ».
// Historique: 2026-08-29 13:43 — étape 3 : bouton « Solutions compatibles » (navigateur),
//             gaté par solutionsCount != null.
//             2026-08-29 10:05 — 6×10 temps 2 étape 5 : compteur de solutions dans l'AppBar.
// Historique: 2026-08-28 20:30 — suppression démo : retrait de l'import demo_screen.dart et
//             des deux IconButton « Démo automatique ».
//             2026-08-27 19:57 — PentoscopePlacedPiece → PlacedPiece.
// Modified: 2604221500
// Dialogue bilan : déplacements, suppressions
// CHANGEMENTS: (1) dialogue de bilan, (2) rangées déplacements et suppressions ajoutées

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/completion_metrics.dart';
import 'package:pentapol/pentoscope/challenge_consent.dart';
import 'package:pentapol/pentoscope/fault_analysis.dart';
import 'package:pentapol/pentoscope/screens/leaderboard_screen.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_board.dart';
import 'package:pentapol/pentoscope/widgets/pentoscope_piece_slider.dart';

// ═══════════════════════════════════════════════════════════════════════════════════════════
// RÉGLAGE VISUEL — les sept valeurs « à régler à l'œil » de l'ergonomie hors plateau,
// rassemblées ici (PLAN_ERGONOMIE §3/§4d). **Regroupement pur : comportement inchangé.**
// Seul `kPieceToBoardCellRatio` est public : `pentoscope_board.dart` l'importe pour le
// feedback de drag. Les autres sont privés au fichier.
// ═══════════════════════════════════════════════════════════════════════════════════════════

/// Rapport pièce/plateau **par défaut** : `pieceCellSize = boardCellSize × k`. Gouverne la taille
/// des pièces de la barre **et** du feedback de drag ; l'épaisseur de la barre en dérive.
/// Depuis le 2026-09-10 la valeur *runtime* vient du réglage live `settings.game.rackCellRatio`
/// (calibrage device, retour de Paul) — cette constante n'est plus que le **défaut**, tenue à
/// l'identique de `GameSettings.rackCellRatio` (0.46). Historique : 0.22 → 0.26 (2026-09-07) →
/// 0.42 → 0.46 (2026-09-10, décision 6 : le rack était ~1:4 du plateau, C5 ; 0.46 figé par Paul
/// après calibrage device). Coût : la barre étant comptée comme ~5k rangées dans `_barMetrics`,
/// un rack plus gros rétrécit le plateau.
const double kPieceToBoardCellRatio = 0.46;

/// Borne HAUTE de la taille d'une case du plateau, **proportionnelle à l'écran** :
/// `maxCell = shortestSide × kMaxBoardCellFactor`. Sans plafond, `cellSize = min(W/w, H/h)` fait des
/// petits plateaux (3×5, 4×5) démesurés → « falaise » de réduction vers les grands. Le plafond
/// l'atténue. Il était **absolu** (84) au départ, mais 84 pt rapetissait TOUT sur une grande tablette
/// (tout dépasse 84 → tout rogné à 84). **Relatif** : ≈84 sur iPhone (390×0.215), bien plus grand sur
/// tablette → les plateaux remplissent l'écran. Appliqué au board ET à `_barMetrics`. **À régler à l'œil.**
const double kMaxBoardCellFactor = 0.215;

/// Marge latérale RÉSERVÉE de chaque côté du plateau, en portrait, en points (retour de Paul,
/// 2026-09-09). Sur un grand plateau (5×n, 6×10) `cellSize` est limité par la largeur → le plateau
/// prenait TOUTE la largeur (≈4 pt de marge) : avec le suivi exact 1:1 du doigt, positionner une pièce
/// près d'un bord amenait le doigt contre le biseau → lâcher forcé au mauvais endroit. Réserver cette
/// marge redonne de la place au doigt de chaque côté. N'affecte QUE les plateaux limités par la largeur
/// (les petits plateaux, plafonnés par `maxCell`, gardent leur taille). Appliquée au plateau ET à
/// `_barMetrics` (ancrage §3). **À régler à l'œil sur device.**
const double kBoardSideMargin = 26.0;

/// Le plafond ci-dessus, résolu pour l'écran courant.
double maxBoardCellSize(BuildContext context) =>
    MediaQuery.of(context).size.shortestSide * kMaxBoardCellFactor;

/// 🐞 DEBUG (test device) : affiche un bandeau coin haut-gauche avec les compteurs **live**
/// d'isométries et de fautes (`state.isometryCount` / `state.faultCount`), pour vérifier qu'ils
/// s'incrémentent en direct. **NON destiné à la production** — à repasser `false` avant toute
/// soumission App Store (suivi dans `docs/CHECKLIST_APPSTORE.md`). Pas `kDebugMode` : le test se
/// fait en `--release`, où il vaut faux.
///
/// Repassé à **false** le 2026-09-10 (retour de Paul) : quand il valait `true`, le coin
/// haut-gauche n'avait jamais d'état « rien » — réglage `showCounters` OFF → bande debug
/// (verbeuse), ON → récap propre. Désormais OFF → **rien**, ON → **récap** (isométries · fautes) :
/// le réglage donne bien « rien ou total ». Traite aussi le C9 (bande debug sur le plateau,
/// checklist point 22). Repasser `true` pour l'observation en dev.
const bool kShowLiveCounters = false;

/// Icônes (AppBar + colonne d'actions) : `shortestSide × facteur`, borné. **À régler à l'œil.**
/// (0.075→0.11, min 30→40 le 2026-09-07 : « trop petites dans l'AppBar » — retour de Paul.)
const double _kIconSizeFactor = 0.11;
const double _kIconSizeMin = 40.0;
const double _kIconSizeMax = 64.0;

/// Hauteur de l'AppBar : `shortestSide × facteur`, borné.
const double _kAppBarHeightFactor = 0.14;
const double _kAppBarHeightMin = 50.0;
const double _kAppBarHeightMax = 100.0;

/// Petits textes/pictos du titre (compteur) et base du chrono : `_uiIconSize × facteur`, borné.
const double _kLabelSizeFactor = 0.35;
const double _kLabelSizeMin = 13.0;
const double _kLabelSizeMax = 40.0;

/// Chrono de la barre : `_uiLabelSize × ce facteur` (plus gros que les autres labels).
const double _kChronoFactor = 1.4;

/// Marge de la barre de pièces autour de la boîte (épaisseur de barre = `5 × cell + marge`).
const double _kSliderPad = 20.0;

/// ⏱️ Formate le temps en `m:ss` (C7, décision 8 du PLAN_ERGONOMIE_ICONES) : les
/// secondes brutes (`106s`, `203s`) ne se lisent pas comme une durée. Chaîne
/// purement numérique — pas d'i18n (comme les libellés numériques de durée du duel).
String _formatTime(int seconds) {
  final total = seconds < 0 ? 0 : seconds;
  final m = total ~/ 60;
  final s = total % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class PentoscopeGameScreen extends ConsumerStatefulWidget {
  const PentoscopeGameScreen({super.key});

  @override
  ConsumerState<PentoscopeGameScreen> createState() => _PentoscopeGameScreenState();
}

class _PentoscopeGameScreenState extends ConsumerState<PentoscopeGameScreen> {
  // 👁️ État du mini-plateau adversaire
  bool _showOpponentOverlay = false;

  // 📍 Position du mini-plateau (draggable)
  Offset? _overlayPosition; // null = position par défaut (coin bas-droit)

  // 🏁 Bandeau de bilan fermé par « Fermer » alors que le puzzle reste complet.
  // Remis à false en build dès que le puzzle n'est plus complet (voir build()).
  bool _bilanFerme = false;

  // 🏁 Décalage de la carte de bilan par rapport au centre (la fenêtre est déplaçable au doigt).
  // Remis à zéro au démarrage d'une nouvelle partie (comme _bilanFerme).
  Offset _bilanOffset = Offset.zero;

  // 🎓 Temps figé à la réussite d'un exercice d'entraînement (getElapsedSeconds continue de croître
  // après stopTimer). null tant que l'exercice n'est pas résolu ; remis à null à « Suivante ».
  int? _trainingElapsed;

  /// Gère l'affichage des messages et vibrations selon le résultat de transformation
  void _handleTransformationResult(BuildContext context, TransformationResult result) {
    switch (result) {
      case TransformationResult.success:
        // Pas de message pour une transformation réussie sans ajustement
        break;
      case TransformationResult.recentered:
        // Recentrage silencieux : plus de message (retour de Paul). Retour haptique conservé.
        HapticFeedback.mediumImpact();
        break;
      case TransformationResult.impossible:
        // Silencieux : plus de message (retour de Paul). Retour haptique fort conservé.
        HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Appelé une fois quand le puzzle vient d'être complété (transition via ref.listen).
  /// Progression : avance le niveau si c'était le puzzle du niveau courant. 1ᵉʳ succès : demande
  /// le nom du joueur s'il n'est pas encore saisi.
  void _onPuzzleCompleted(BuildContext context, PentoscopeState st) {
    final settings = ref.read(settingsProvider);
    if (st.isProgression &&
        st.puzzle != null &&
        st.puzzle!.size == sizeForLevel(settings.currentLevel)) {
      ref.read(settingsProvider.notifier).advanceLevel();
    }
    final needName =
        settings.userName == null || settings.userName!.trim().isEmpty;
    final rankedCompletion = st.isRanked; // défi terminé → proposer l'opt-in (une fois)
    if (needName || rankedCompletion) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        // this.context (State.context) gardé par State.mounted : motif sûr entre await successifs.
        if (needName) await _promptUserName(this.context);
        if (rankedCompletion && mounted) {
          await maybeProposeConsentOnChallengeCompletion(this.context, ref);
        }
      });
    }
  }

  /// Dialogue de saisie du nom au 1ᵉʳ puzzle réussi.
  Future<void> _promptUserName(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
        title: Text(l10n.congrats),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.firstPuzzlePrompt),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.yourName,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.validate),
          ),
        ],
        );
      },
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) {
      await ref.read(settingsProvider.notifier).setUserName(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context);

    // Progression / nom : réagir à la transition « puzzle complété ».
    ref.listen<PentoscopeState>(pentoscopeProvider, (prev, next) {
      final justCompleted = !(prev?.isComplete ?? false) && next.isComplete;
      if (justCompleted) _onPuzzleCompleted(context, next);

      // 🎓 Entraînement : la pièce vient de recouvrir le fantôme → figer le temps, enregistrer
      // l'exercice (retour, pas un record), retour haptique. La carte de bilan s'affiche via l'état.
      if (next.isTraining) {
        final wasSolved = prev != null && _trainingSolved(prev);
        if (!wasSolved && _trainingSolved(next)) {
          notifier.stopTimer();
          setState(() => _trainingElapsed = notifier.getElapsedSeconds());
          ref.read(settingsProvider.notifier).recordTrainingExercise();
          if (settings.game.enableHaptics) HapticFeedback.mediumImpact();
        }
      }
    });

    // Bilan non modal : piloté par state.isComplete. _bilanFerme se remet à false dès que le
    // puzzle n'est plus complet (reset, nouvelle partie, retrait d'une pièce), ce qui couvre
    // tous les démarrages sans avoir à le faire dans chaque handler.
    if (!state.isComplete) {
      if (_bilanFerme) _bilanFerme = false;
      if (_bilanOffset != Offset.zero) _bilanOffset = Offset.zero; // recentrer au prochain bilan
    }

    if (state.puzzle == null) {
      return Scaffold(body: Center(child: Text(l10n.noPuzzle)));
    }

    // Détection du mode transformation
    final isPlacedPieceSelected = state.selectedPlacedPiece != null;
    final isSliderPieceSelected = state.selectedPiece != null;

    // Orientation
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return PopScope(
      canPop: true,
      // Sortie d'entraînement par geste système (swipe-back) : restaurer la partie du jeu figée à
      // l'entrée, comme le fait le bouton 🏠 (sinon « Jouer » repartirait fraîche et effacerait la
      // sauvegarde). No-op hors entraînement.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && state.isTraining) notifier.endTraining();
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: isLandscape
          ? null
          : PreferredSize(
        preferredSize: Size.fromHeight(_uiAppBarHeight(context)),
        child: AppBar(
          toolbarHeight: _uiAppBarHeight(context),
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          centerTitle: false,
          // §9 : une seule barre d'actions, répartie. `actions:` tasserait les boutons à droite
          // et ne couvre pas le paysage — la barre vit dans le `title`, via _buildBarItems, qui
          // sert aussi le paysage. Mode transformation : la barre d'isométrie prend la place.
          title: (isPlacedPieceSelected || isSliderPieceSelected)
              ? _buildFullWidthIsometryBar(state, notifier)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _buildBarItems(context, state, notifier),
                ),
        ),
      ),
      // §iOS : sans SafeArea le corps passe sous l'îlot dynamique (paysage, appBar null) et sous
      // l'indicateur d'accueil (portrait). SafeArea par défaut couvre TOUS les bords — donc les
      // deux sens de rotation, sans padding directionnel en dur. Le LayoutBuilder interne voit
      // alors les contraintes réduites, et le plateau se recalcule sur la place restante.
      body: SafeArea(
        child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;

              if (isLandscape) {
                return _buildLandscapeLayout(
                  context,
                  ref,
                  state,
                  notifier,
                  settings,
                  isSliderPieceSelected,
                  isPlacedPieceSelected,
                );
              } else {
                return _buildPortraitLayout(
                  context,
                  ref,
                  state,
                  notifier,
                  isSliderPieceSelected,
                  isPlacedPieceSelected,
                );
              }
            },
          ),
          
          // 🔄⚫ Récap utilisateur (réglage showCounters) : isométries + fautes, haut-gauche.
          if (settings.game.showCounters) _statsOverlay(state),

          // 🐞 DEBUG (test) : bandeau d'observation coin haut-gauche. Défini/documenté/formaté dans
          // fault_analysis (FaultIndicators + diagnosticCourant) ; ici on ne fait que l'afficher.
          // Masqué si le récap utilisateur est actif (même coin) — les deux s'excluent.
          if (kShowLiveCounters && !settings.game.showCounters)
            _debugIndicatorsOverlay(state),

          // 👁️ Mini-plateau adversaire (overlay)
          if (_showOpponentOverlay)
            _buildOpponentOverlay(context, state, settings),

          // 🏁 Bilan fermé : un tap sur le plateau résolu **rouvre** la carte (choix de Paul).
          // Capteur plein cadre actif uniquement dans cet état (rien d'autre à faire sur le
          // plateau une fois résolu). N'affecte pas la barre du haut (hors de ce Stack).
          if (state.isComplete && _bilanFerme)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _bilanFerme = false),
              ),
            ),

          // 🏁 Bilan de fin — carte flottante non-modale, posée au centre par-dessus le plateau
          // résolu (visible derrière). Fermable ; ne bloque pas (les zones hors carte laissent
          // passer les taps). Regroupe tout le bilan (les compteurs éparpillés sont retirés).
          if (state.isComplete && !_bilanFerme)
            _buildBilanCard(context, state, notifier),

          // 🎓 Entraînement : carte de fin d'exercice (appuis / minimum / temps) + « Suivante ».
          if (state.isTraining && _trainingSolved(state))
            Center(child: _buildTrainingCard(context, state, notifier)),
        ],
      ),
      ),
    ),
    );
  }

  /// Vrai si l'unique pièce d'un exercice d'entraînement recouvre EXACTEMENT le fantôme.
  bool _trainingSolved(PentoscopeState st) {
    if (!st.isTraining) return false;
    final ghost = st.currentSolution;
    if (ghost == null || ghost.isEmpty || st.placedPieces.length != 1) return false;
    final placed = st.placedPieces.first.absoluteCells.map((c) => (c.x, c.y)).toSet();
    final target = ghost.first.absoluteCells.map((c) => (c.x, c.y)).toSet();
    return placed.length == target.length && placed.containsAll(target);
  }

  /// Carte de bilan d'un exercice d'entraînement : informatif (appuis effectués, minimum, temps),
  /// non comparatif, puis « Suivante » → nouvel exercice.
  Widget _buildTrainingCard(
      BuildContext context, PentoscopeState state, PentoscopeNotifier notifier) {
    final l10n = AppLocalizations.of(context);
    final ex = notifier.trainingExercise;
    final min = ex?.minPresses ?? 0;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.congrats,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              '${l10n.trainingPresses(state.isometryCount)} · ${l10n.trainingSeconds(_trainingElapsed ?? 0)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.trainingEnough(min),
              style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() => _trainingElapsed = null);
                notifier.startTraining();
              },
              child: Text(l10n.next),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 👁️ MINI-PLATEAU ADVERSAIRE (OVERLAY)
  // ============================================================================

  Widget _buildOpponentOverlay(
      BuildContext context,
      PentoscopeState state,
      dynamic settings,
      ) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    // Taille du mini-plateau (35% de l'écran)
    final overlaySize = isLandscape 
        ? screenSize.height * 0.35 
        : screenSize.width * 0.35;
    
    // Position par défaut : coin bas-droit avec marge
    final defaultX = screenSize.width - overlaySize - 12;
    final defaultY = isLandscape 
        ? screenSize.height - overlaySize - 12 
        : screenSize.height - overlaySize - 170; // Au-dessus du slider en portrait
    
    // Utiliser la position custom ou la position par défaut
    final currentX = _overlayPosition?.dx ?? defaultX;
    final currentY = _overlayPosition?.dy ?? defaultY;

    return Positioned(
      left: currentX,
      top: currentY,
      child: GestureDetector(
        // 🖐️ Drag pour déplacer
        onPanUpdate: (details) {
          setState(() {
            final newX = (currentX + details.delta.dx)
                .clamp(0.0, screenSize.width - overlaySize);
            final newY = (currentY + details.delta.dy)
                .clamp(0.0, screenSize.height - overlaySize - 60); // Marge pour ne pas sortir
            _overlayPosition = Offset(newX, newY);
          });
        },
        // 🔄 Double-tap pour reset la position
        onDoubleTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _overlayPosition = null; // Reset à la position par défaut
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: overlaySize,
          height: overlaySize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // 🎮 Mini-plateau (simulation adversaire)
                _buildMiniBoard(state, settings, overlaySize),
                
                // 📊 Bandeau info adversaire (aussi zone de drag)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade400],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 🖐️ Icône drag
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.drag_indicator, color: Colors.white.withOpacity(0.7), size: 12),
                            const SizedBox(width: 4),
                            const Text(
                              '👤 Adversaire',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_simulateOpponentProgress(state)}/${state.puzzle?.size.numPieces ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // ❌ Bouton fermer
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showOpponentOverlay = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Simule la progression de l'adversaire (pour démo)
  int _simulateOpponentProgress(PentoscopeState state) {
    // Simulation miroir : même progression que nous
    return state.placedPieces.length;
  }

  /// Construit le mini-plateau (vue simplifiée)
  Widget _buildMiniBoard(PentoscopeState state, dynamic settings, double size) {
    final puzzle = state.puzzle;
    if (puzzle == null) return const SizedBox();

    final boardWidth = puzzle.size.width;
    final boardHeight = puzzle.size.height;
    
    // Calculer la taille des cellules pour le mini-plateau
    final availableSize = size - 24; // Marge pour le bandeau
    final maxDimension = boardWidth > boardHeight ? boardWidth : boardHeight;
    final cellSize = availableSize / maxDimension;

    return Padding(
      padding: const EdgeInsets.only(top: 22), // Espace pour le bandeau
      child: Center(
        child: SizedBox(
          width: cellSize * boardWidth,
          height: cellSize * boardHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: boardWidth,
              childAspectRatio: 1.0,
            ),
            itemCount: boardWidth * boardHeight,
            itemBuilder: (context, index) {
              final x = index % boardWidth;
              final y = index ~/ boardWidth;
              
              // Simuler le plateau adversaire (quelques pièces placées)
              final opponentPieces = _getSimulatedOpponentPieces(state);
              final pieceId = _getPieceAtPosition(opponentPieces, x, y);
              
              return Container(
                decoration: BoxDecoration(
                  color: pieceId != null 
                      ? settings.ui.getPieceColor(pieceId).withOpacity(0.8)
                      : Colors.grey.shade200,
                  border: Border.all(color: Colors.grey.shade400, width: 0.5),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Simule les pièces de l'adversaire (pour démo)
  /// En mode miroir : affiche les mêmes pièces que nous
  List<PlacedPiece> _getSimulatedOpponentPieces(PentoscopeState state) {
    // Simulation miroir : mêmes pièces que nous
    return state.placedPieces.toList();
  }

  /// Récupère l'ID de la pièce à une position donnée
  int? _getPieceAtPosition(List<PlacedPiece> pieces, int x, int y) {
    for (final placed in pieces) {
      for (final cell in placed.absoluteCells) {
        if (cell.x == x && cell.y == y) {
          return placed.piece.id;
        }
      }
    }
    return null;
  }

  /// 🔑 Barre d'isométries pleine largeur avec icônes grandes et réparties uniformément
  Widget _buildFullWidthIsometryBar(
      PentoscopeState state,
      PentoscopeNotifier notifier,
      ) {
    // Icônes de la barre de transformation : taille dédiée partagée (solo + duel), plus grosse
    // que la barre d'état (cibles d'action ; retour de Paul « trop petites sur iPhone »).
    final double iconSize = isometryIconSize(context);
    final l10n = AppLocalizations.of(context);

    final hasDeleteButton = state.selectedPlacedPiece != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Rotation anti-horaire
        IconButton(
          icon: Icon(GameIcons.isometryRotationTW.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            final result = notifier.applyIsometryRotationTW();
            _handleTransformationResult(context, result);
          },
          tooltip: l10n.isoRotateTW,
          color: GameIcons.isometryRotationTW.color,
        ),
        // Rotation horaire
        IconButton(
          icon: Icon(GameIcons.isometryRotationCW.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            final result = notifier.applyIsometryRotationCW();
            _handleTransformationResult(context, result);
          },
          tooltip: l10n.isoRotateCW,
          color: GameIcons.isometryRotationCW.color,
        ),
        // Symétrie horizontale
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryH.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            final result = notifier.applyIsometrySymmetryH();
            _handleTransformationResult(context, result);
          },
          tooltip: l10n.isoSymH,
          color: GameIcons.isometrySymmetryH.color,
        ),
        // Symétrie verticale
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryV.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            final result = notifier.applyIsometrySymmetryV();
            _handleTransformationResult(context, result);
          },
          tooltip: l10n.isoSymV,
          color: GameIcons.isometrySymmetryV.color,
        ),
        // Supprimer (si pièce placée)
        if (hasDeleteButton)
          IconButton(
            icon: Icon(GameIcons.removePiece.icon, size: iconSize),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              HapticFeedback.selectionClick();
              notifier.removePlacedPiece(state.selectedPlacedPiece!);
            },
            tooltip: l10n.isoRemove,
            color: GameIcons.removePiece.color,
          ),
      ],
    );
  }

  /// 🔑 Barre d'isométries pleine hauteur (mode paysage) avec icônes grandes et réparties
  Widget _buildFullHeightIsometryBar(
      PentoscopeState state,
      PentoscopeNotifier notifier,
      double columnWidth,
      ) {
    // Icônes de la barre de transformation (paysage) : même taille dédiée qu'en portrait
    // (isometryIconSize), sinon elles « rétrécissent » en tournant en paysage (retour de Paul).
    final iconSize = isometryIconSize(context);
    final l10n = AppLocalizations.of(context);
    final hasDeleteButton = state.selectedPlacedPiece != null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Rotation anti-horaire
        IconButton(
          icon: Icon(GameIcons.isometryRotationTW.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometryRotationTW();
          },
          tooltip: l10n.isoRotateTW,
          color: GameIcons.isometryRotationTW.color,
        ),
        // Rotation horaire
        IconButton(
          icon: Icon(GameIcons.isometryRotationCW.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometryRotationCW();
          },
          tooltip: l10n.isoRotateCW,
          color: GameIcons.isometryRotationCW.color,
        ),
        // Symétrie horizontale
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryH.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometrySymmetryH();
          },
          tooltip: l10n.isoSymH,
          color: GameIcons.isometrySymmetryH.color,
        ),
        // Symétrie verticale
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryV.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometrySymmetryV();
          },
          tooltip: l10n.isoSymV,
          color: GameIcons.isometrySymmetryV.color,
        ),
        // Supprimer (si pièce placée)
        if (hasDeleteButton)
          IconButton(
            icon: Icon(GameIcons.removePiece.icon, size: iconSize),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              HapticFeedback.selectionClick();
              notifier.removePlacedPiece(state.selectedPlacedPiece!);
            },
            tooltip: l10n.isoRemove,
            color: GameIcons.removePiece.color,
          ),
      ],
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// 🐞 Bandeau d'observation (debug, `kShowLiveCounters`), coin haut-gauche. Les trois lignes sont
  /// **définies et formatées dans `fault_analysis`** (`FaultIndicators` + `diagnosticCourant`) ; ici
  /// on ne fait que les afficher. `IgnorePointer` : ne capte aucun geste (les glissés passent).
  Widget _debugIndicatorsOverlay(PentoscopeState state) {
    final ind = FaultIndicators(
      isometryCount: state.isometryCount,
      faultCount: state.faultCount,
      translationCount: state.translationCount,
      redRemovalCount: state.redRemovalCount,
      faultAireCount: state.faultAireCount,
      faultSubtileCount: state.faultSubtileCount,
      faultGraviteSum: state.faultGraviteSum,
    );
    const base = TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return Positioned(
      left: 8,
      top: 8,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ind.ligneCompteurs, style: base), // ligne 1
              Text(ind.ligneClassification,
                  style: base.copyWith(color: Colors.amberAccent)), // ligne 2
              Text(
                diagnosticCourant(
                  plateau: state.plateau,
                  hasPossibleSolution: state.hasPossibleSolution,
                  isComplete: state.isComplete,
                ),
                style: base.copyWith(color: Colors.lightBlueAccent), // ligne 3
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🏁 Bilan de fin — carte flottante non-modale, **déplaçable au doigt** (choix de Paul), posée
  /// au centre par-dessus le plateau résolu. `_bilanOffset` mémorise le déplacement (recentré au
  /// prochain bilan). Le glissé bouge la carte ; les boutons restent cliquables (tap ≠ pan).
  Widget _buildBilanCard(
      BuildContext context, PentoscopeState state, PentoscopeNotifier notifier) {
    // « Niveau suivant » proposé si le puzzle terminé est un puzzle de progression qui n'est pas
    // déjà le niveau maximal. La complétion a déjà avancé currentLevel (via _onPuzzleCompleted).
    final canNext = state.isProgression &&
        state.puzzle != null &&
        state.puzzle!.size != sizeForLevel(kMaxLevel);
    // Défi : proposer de voir le classement (on vient d'y soumettre son score).
    final challenge = state.isRanked ? notifier.activeChallenge : null;
    return Center(
      child: Transform.translate(
        offset: _bilanOffset,
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onPanUpdate: (d) => setState(() => _bilanOffset += d.delta),
          child: _BilanCard(
            metrics: notifier.computeCompletionMetrics(), // trois maillots (CDC §4.5)
            hintCount: state.hintCount,
            onLeaderboard: challenge == null
                ? null
                : () => openLeaderboardWithConsent(
                      context,
                      ref,
                      submitAfterOptIn: true,
                      builder: () => LeaderboardScreen(
                          week: challenge.week, size: challenge.size),
                    ),
            onClose: () => setState(() => _bilanFerme = true),
            onNewGame: () {
              HapticFeedback.mediumImpact();
              notifier.reset();
            },
            onNextLevel: canNext
                ? () {
                    HapticFeedback.mediumImpact();
                    final level = ref.read(settingsProvider).currentLevel;
                    notifier.startPuzzle(sizeForLevel(level), isProgression: true);
                  }
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSliderWithDragTarget({
    required WidgetRef ref,
    required bool isLandscape,
    required Widget sliderChild,
    required BoxDecoration decoration,
    double? width,
    double? height,
  }) {
    final state = ref.watch(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);

    // Un dépôt de pièce du RACK est en attente et VALIDE (aperçu vert sur le plateau) : le bord bas
    // du plateau est collé au rack, donc viser la ligne du bas fait souvent relâcher au ras/au-dessus
    // du rack. On pose alors à l'ancre de l'aperçu au lieu de perdre le geste (cf. board onLeave qui
    // ne l'efface plus). La géométrie de pose est inchangée (même tryPlaceAtAnchor).
    final hasPendingPlacement = state.selectedPlacedPiece == null &&
        state.selectedPiece != null &&
        state.previewX != null &&
        state.previewY != null &&
        state.isPreviewValid;

    return DragTarget<Pento>(
      onWillAcceptWithDetails: (details) {
        // Pièce placée → retrait ; pièce du rack avec aperçu valide → pose sur le plateau.
        return state.selectedPlacedPiece != null || hasPendingPlacement;
      },
      onAcceptWithDetails: (details) {
        if (state.selectedPlacedPiece != null) {
          // Retirer la pièce du plateau (geste poubelle).
          HapticFeedback.mediumImpact();
          notifier.removePlacedPiece(state.selectedPlacedPiece!);
        } else if (hasPendingPlacement) {
          // Poser la pièce du rack à l'ancre de l'aperçu (relâché au ras du rack, ligne du bas).
          final success =
              notifier.tryPlaceAtAnchor(state.previewX!, state.previewY!);
          HapticFeedback.mediumImpact();
          if (!success) HapticFeedback.heavyImpact();
          notifier.clearPreview();
        }
      },
      builder: (context, candidateData, rejectedData) {
        // Le rouge/poubelle ne concerne QUE le retrait (pièce placée), pas la pose d'une pièce du rack.
        final isRemoving =
            candidateData.isNotEmpty && state.selectedPlacedPiece != null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: height,
          decoration: decoration.copyWith(
            border: isRemoving
                ? Border.all(color: Colors.red.shade400, width: 3)
                : null,
            color: isRemoving ? Colors.red.shade50 : decoration.color,
          ),
          child: Stack(
            children: [
              sliderChild,
              // Icône poubelle au survol (retrait seulement)
              if (isRemoving)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.red.withOpacity(0.1),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade700,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // LAYOUTS
  // ============================================================================

  /// Échelle de l'interface hors plateau, ancrée sur la plus petite dimension de l'écran
  /// (PLAN_ERGONOMIE §4d). Un seul point de réglage pour les icônes et la hauteur d'AppBar,
  /// au lieu des quatre constantes improvisées (56, 42, clamp 28-50, clamp 20-36). Clamps
  /// calés pour ≈ conserver l'iPhone et grandir sur tablette ; **à régler à l'œil**.
  double _uiIconSize(BuildContext context) =>
      (MediaQuery.of(context).size.shortestSide * _kIconSizeFactor)
          .clamp(_kIconSizeMin, _kIconSizeMax);

  double _uiAppBarHeight(BuildContext context) =>
      (MediaQuery.of(context).size.shortestSide * _kAppBarHeightFactor)
          .clamp(_kAppBarHeightMin, _kAppBarHeightMax);

  /// Taille des petits textes/pictos d'information de l'AppBar (chrono, compteurs du titre),
  /// ≈ _uiIconSize × 0.35 (PLAN_ERGONOMIE §4d, décision 59). Plancher 13 : sur iPhone
  /// _uiIconSize plafonne à 30, ×0.35 = 10,5 < actuel ; le plancher tient le garde-fou
  /// « iPhone proche de l'actuel » tout en laissant grandir sur tablette.
  double _uiLabelSize(BuildContext context) =>
      (_uiIconSize(context) * _kLabelSizeFactor)
          .clamp(_kLabelSizeMin, _kLabelSizeMax);

  /// Les actions de la barre, dans l'ordre, **communes aux deux orientations** (PLAN_ERGONOMIE
  /// §9). Une seule source garantit que portrait et paysage proposent la même chose — pas la
  /// discipline de qui édite le fichier. Rendue en `Row` (portrait) ou `Column` (paysage), en
  /// `spaceEvenly`. Le chrono est inséré au centre ; le compteur de solutions reste, les
  /// compteurs iso/déplacements/suppressions sont sortis de la barre (décision 66) — ils vivent
  /// dans le bandeau de fin de partie.
  List<Widget> _buildBarItems(
      BuildContext context, PentoscopeState state, PentoscopeNotifier notifier) {
    final iconSize = _uiIconSize(context);
    final l10n = AppLocalizations.of(context);
    // Compteur masqué à la complétion : l'info de fin vit dans la carte de bilan (nettoyage).
    final showCounter = ref.read(settingsProvider).game.showSolutionCounter &&
        state.solutionsCount != null &&
        !state.isComplete;

    final items = <Widget>[
      IconButton(
        icon: const Icon(Icons.home_outlined),
        iconSize: iconSize,
        color: Colors.blueGrey,
        onPressed: () {
          HapticFeedback.selectionClick();
          // Sortie d'entraînement : restaurer la partie du jeu figée à l'entrée avant de revenir.
          if (state.isTraining) notifier.endTraining();
          Navigator.popUntil(context, (r) => r.isFirst); // retour au menu d'entrée
        },
        tooltip: l10n.homeTooltip,
      ),
      IconButton(
        icon: const Icon(Icons.add_circle_outline),
        iconSize: iconSize,
        color: Colors.blue,
        // En entraînement, « + » tire un nouvel exercice (pas le dialogue de nouvelle partie, qui
        // sortirait du mode). En jeu, dialogue de nouvelle partie.
        onPressed: state.isTraining
            ? () => notifier.startTraining()
            : () => _showNewGameDialog(context, ref),
        tooltip: state.isTraining ? l10n.next : l10n.newGame,
      ),
      // Icône « person » (reset « recommencer ») retirée le 2026-09-07 (choix de Paul) : la remise à
      // zéro reste accessible par « Nouvelle partie » (add_circle) et par la carte de bilan.
      // Indice masqué en entraînement (aucune table de solutions : il ne ferait rien).
      if (!state.isComplete && !state.isTraining && state.availablePieces.isNotEmpty)
        IconButton(
          icon: Icon(Icons.lightbulb,
              color: state.hasPossibleSolution ? Colors.amber : Colors.red),
          iconSize: iconSize,
          onPressed: () {
            // Mode classé (défi, §4.8) : l'appui est neutralisé. La couleur reste (elle sort du
            // même calcul que le compteur). Le retrait passe par sélection + poubelle.
            if (state.isRanked) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(l10n.hintDisabledChallenge),
                  duration: const Duration(seconds: 2),
                ));
              return;
            }
            if (state.hasPossibleSolution) {
              HapticFeedback.mediumImpact();
              notifier.applyHint();
            } else if (state.placedPieces.isNotEmpty) {
              // #3 cul-de-sac : la pose reste autorisée (le joueur peut croire, à tort
              // ou à raison, que c'est jouable). Quand l'ampoule est rouge, un appui
              // revient d'un coup en arrière — retire la dernière pièce posée. Répétable :
              // removePlacedPiece recalcule le statut, donc le rouge s'éteint dès que le
              // plateau redevient soluble.
              HapticFeedback.mediumImpact();
              notifier.removePlacedPiece(state.placedPieces.last);
            }
          },
          tooltip: state.hasPossibleSolution
              ? l10n.hint
              : l10n.noSolutionBack,
        ),
      // Navigateur de solutions compatibles (icône visionneuse) retiré le 2026-09-07 (choix de
      // Paul : buggé en 6×10). Le compteur de solutions reste ; la navigation viendra si refaite.
      if (showCounter) _buildSolutionCounter(context, state),
      // Réglages retiré de la barre de jeu (choix de Paul) : il vit sur le menu d'accueil.
    ];

    // ⏱️ Chrono au centre : avec spaceEvenly il reste au milieu quel que soit le nombre
    // d'icônes conditionnelles affichées (§9.3). Masqué à la complétion (le temps est dans la
    // carte de bilan) — nettoyage de la barre à la fin.
    if (!state.isComplete) {
      items.insert(items.length ~/ 2, _buildChrono(context, state));
    }
    return items;
  }

  /// Chronomètre de la barre — lisible : `_uiLabelSize × 1.4`, gras (§9.3).
  Widget _buildChrono(BuildContext context, PentoscopeState state) {
    return Text(
      _formatTime(state.elapsedSeconds),
      style: TextStyle(
        fontSize: _uiLabelSize(context) * _kChronoFactor,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  /// Récap **isométries + fautes** en haut-gauche, sous l'AppBar (retour de Paul, réglage
  /// `showCounters`). Petit bandeau propre, à ne pas confondre avec le bandeau **debug**
  /// (`kShowLiveCounters`, 3 lignes) : les deux s'excluent (voir le Stack du build).
  Widget _statsOverlay(PentoscopeState state) {
    const base = TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return Positioned(
      left: 8,
      top: 8,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('🔄 ${state.isometryCount}   ⚫ ${state.faultCount}',
              style: base),
        ),
      ),
    );
  }

  /// Compteur de solutions (nombre restant) — reste dans la barre (§9.4). Rouge à 0, cohérent
  /// avec le bouton d'indice.
  ///
  /// C1 / décision 9 du PLAN_ERGONOMIE_ICONES : le chiffre restait collé à l'ampoule et se lisait
  /// « 1 indice ». Chiffre **seul** (le glyphe mangeait de la place — retour de Paul) + tooltip
  /// libellé (`compatibleSolutionsTooltip`) au survol/maintien pour lever l'ambiguïté sans coût
  /// de place. Affichage optionnel via `GameSettings.showSolutionCounter` (Réglages).
  Widget _buildSolutionCounter(BuildContext context, PentoscopeState state) {
    final l10n = AppLocalizations.of(context);
    final color =
        state.hasPossibleSolution ? Colors.black87 : Colors.red.shade700;
    return Tooltip(
      message: l10n.compatibleSolutionsTooltip,
      child: Text(
        '${state.solutionsCount}',
        style: TextStyle(
          fontSize: _uiLabelSize(context),
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// `(taille de case d'une pièce de la barre, épaisseur de la barre)` — la barre est ancrée
  /// sur le plateau : `pieceCellSize = boardCellSize × k` (§3). La dépendance circulaire (la
  /// barre prend de la place au plateau qui la dimensionne) est résolue en comptant la barre
  /// comme ~5k rangées (portrait) ou colonnes (paysage). [reserve] = largeur déjà prise à côté
  /// (la colonne d'actions, en paysage). Garde-fou : jamais sous 8 pt.
  ({double cell, double extent}) _barMetrics(
      Size body, PentoscopeSize size, bool isLandscape, double reserve,
      double maxCell, double pieceRatio) {
    final cols = isLandscape ? size.height : size.width;
    final rows = isLandscape ? size.width : size.height;
    // Rapport pièce/plateau : réglage live (`settings.game.rackCellRatio`), défaut
    // kPieceToBoardCellRatio. Gouverne la taille des pièces du rack ET l'épaisseur de la barre.
    final k = pieceRatio;
    double boardCell;
    if (isLandscape) {
      boardCell = math.min(
        (body.width - reserve - _kSliderPad) / (cols + 5 * k),
        body.height / rows,
      );
    } else {
      boardCell = math.min(
        (body.width - 2 * kBoardSideMargin) / cols,
        (body.height - _kSliderPad) / (rows + 5 * k),
      );
    }
    // Même plafond que le plateau (maxBoardCellSize) → la barre reste ancrée sur la case réelle (§3).
    boardCell = math.min(boardCell, maxCell);
    final cell = math.max(8.0, boardCell * k);
    return (cell: cell, extent: cell * 5 + _kSliderPad);
  }

  /// Layout portrait : plateau en haut, actions + slider en bas
  Widget _buildPortraitLayout(
      BuildContext context,
      WidgetRef ref,
      PentoscopeState state,
      PentoscopeNotifier notifier,
      bool isSliderPieceSelected,
      bool isPlacedPieceSelected,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Taille des pièces de la barre, ancrée sur le plateau ; hauteur de barre dérivée.
        final m = _barMetrics(constraints.biggest, state.puzzle!.size, false, 0,
            maxBoardCellSize(context), ref.read(settingsProvider).game.rackCellRatio);
        return Column(
          children: [
            // Plateau de jeu
            const Expanded(flex: 3, child: PentoscopeBoard(isLandscape: false)),

            // Slider de pièces horizontal
            _buildSliderWithDragTarget(
              ref: ref,
              isLandscape: false,
              height: m.extent,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              // Le bilan n'occupe plus la zone slider (il est en carte flottante) : slider normal,
              // vide à la complétion (toutes les pièces posées).
              sliderChild:
                  PentoscopePieceSlider(isLandscape: false, pieceCellSize: m.cell),
            ),
          ],
        );
      },
    );
  }

  /// Layout paysage : colonne d'actions à gauche, plateau au milieu, barre à droite —
  /// même ordre qu'en portrait (haut→bas), un seul Row de trois enfants (§7).
  Widget _buildLandscapeLayout(
      BuildContext context,
      WidgetRef ref,
      PentoscopeState state,
      PentoscopeNotifier notifier,
      dynamic settings,
      bool isSliderPieceSelected,
      bool isPlacedPieceSelected,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Largeur de la colonne d'actions : assez pour la barre d'isométrie (icônes dédiées, la
        // plus grosse chose qui s'y trouve) + son padding, sinon rognage (§9). L'ancienne formule
        // (0.08 × hauteur) plafonnait.
        final actionColumnWidth = isometryIconSize(context) + 24;
        // Barre ancrée sur le plateau ; sa largeur (pièces verticales) dérive de pieceCellSize.
        final m = _barMetrics(constraints.biggest, state.puzzle!.size, true,
            actionColumnWidth, maxBoardCellSize(context),
            ref.read(settingsProvider).game.rackCellRatio);
        final sliderWidth = m.extent;

        // §7 : ordre identique au portrait — colonne d'actions, plateau, barre, aplati en
        // un seul Row de trois enfants (plus de Row imbriqué « actions + slider »).
        return Row(
          children: [
                // 🎯 Colonne d'actions (contextuelles) — à gauche
                Container(
                  width: actionColumnWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        // Ombre portée vers le plateau (à droite) : la colonne est à gauche.
                        offset: const Offset(1, 0),
                      ),
                    ],
                  ),
                  child: (isPlacedPieceSelected || isSliderPieceSelected)
                      // 🔑 Mode transformation: icônes pleine hauteur, réparties uniformément
                      ? _buildFullHeightIsometryBar(state, notifier, actionColumnWidth)
                      // Mode normal : la MÊME liste qu'en portrait, en colonne, répartie (§9).
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _buildBarItems(context, state, notifier),
                        ),
                ),

                // Plateau de jeu — au milieu
                const Expanded(child: PentoscopeBoard(isLandscape: true)),

                // Slider de pièces vertical — à droite
                _buildSliderWithDragTarget(
                  ref: ref,
                  isLandscape: true,
                  width: sliderWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(-2, 0),
                      ),
                    ],
                  ),
                  sliderChild:
                      PentoscopePieceSlider(isLandscape: true, pieceCellSize: m.cell),
                ),
          ],
        );
      },
    );
  }

  /// Tire un puzzle pour une taille : `(masque, nombre de solutions)`. Le 6×10 est un cas à part
  /// (un seul tirage possible, 12 pièces) : pas de masque, compte = 9356 (la table du 6×10).
  Future<({int? mask, int count})> _drawTirage(
      PentoscopeNotifier notifier, PentoscopeSize size) async {
    if (size == PentoscopeSize.size6x10) {
      return (mask: null, count: size.table!.totalCount);
    }
    final mask = await notifier.drawMask(size);
    return (mask: mask, count: notifier.countOfMask(mask));
  }

  /// Dialogue « Nouvelle partie » : taille + tirage (« n solutions » + « autre tirage ») +
  /// montrer la solution. Le tirage se fait ICI (REFERENCE_TIRAGES §Affichage) : le compte n'est
  /// vrai qu'au tirage, et le masque tiré est transmis à la partie via startPuzzle.
  Future<void> _showNewGameDialog(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(pentoscopeProvider.notifier);
    var selectedSize =
        ref.read(pentoscopeProvider).puzzle?.size ?? PentoscopeSize.size5x5;
    var showSolution = false;

    // Tirage initial avant l'ouverture (charge la table au besoin).
    var tirage = await _drawTirage(notifier, selectedSize);
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> redraw() async {
            final t = await _drawTirage(notifier, selectedSize);
            setState(() => tirage = t);
          }

          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l10n.newGame),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.boardSize,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  ...PentoscopeSize.values.map(
                    (size) => RadioListTile<PentoscopeSize>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title:
                          Text(l10n.sizeOption(size.label, size.width, size.height)),
                      value: size,
                      groupValue: selectedSize,
                      onChanged: (value) async {
                        setState(() => selectedSize = value!);
                        await redraw(); // nouveau tirage pour la nouvelle taille
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.drawSolutionsCount(tirage.count),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (selectedSize != PentoscopeSize.size6x10)
                        TextButton.icon(
                          onPressed: redraw,
                          icon: const Icon(Icons.casino_outlined),
                          label: Text(l10n.otherDraw),
                        ),
                    ],
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.showSolutionOpt),
                    value: showSolution,
                    onChanged: (value) => setState(() => showSolution = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  notifier.startPuzzle(
                    selectedSize,
                    mask: tirage.mask,
                    showSolution: showSolution,
                  );
                },
                child: Text(l10n.launch),
              ),
            ],
          );
        },
      ),
    );
  }

}

/// 🏁 Bilan de fin — **carte flottante non-modale**, centrée par-dessus le plateau résolu (visible
/// derrière). Regroupe tout le bilan lisiblement : titre, médaille éventuelle, les trois maillots
/// en lignes libellées (acuité / coups / temps), puis « Fermer » et l'action primaire. « Fermer »
/// escamote la carte pour admirer la solution ; les zones hors carte laissent passer les taps.
class _BilanCard extends StatelessWidget {
  /// Les trois maillots (CDC §4.5). null si aucun puzzle (ne devrait pas arriver à la complétion).
  final CompletionMetrics? metrics;

  /// Aides utilisées : si > 0, la partie n'est pas « propre » (hors record, §4.8).
  final int hintCount;

  /// Défi : ouvrir le classement (on vient d'y soumettre son score). null hors défi.
  final VoidCallback? onLeaderboard;
  final VoidCallback onClose;
  final VoidCallback onNewGame;

  /// Progression : passer au niveau suivant. null si ce n'est pas un puzzle de progression, ou
  /// si le niveau maximal vient d'être terminé.
  final VoidCallback? onNextLevel;

  const _BilanCard({
    required this.metrics,
    required this.hintCount,
    this.onLeaderboard,
    required this.onClose,
    required this.onNewGame,
    this.onNextLevel,
  });

  static String _mmss(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = metrics;
    final assisted = hintCount > 0; // partie avec aide → pas de score de performance affiché
    final perfect = m != null && m.perfectVision && !assisted;

    final primaryButton = onNextLevel == null
        ? FilledButton.icon(
            onPressed: onNewGame,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.newGame),
          )
        : FilledButton.icon(
            onPressed: onNextLevel,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(l10n.nextLevel),
          );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Card(
          elevation: 10,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Poignée de déplacement : la fenêtre se glisse au doigt (Paul).
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                      const SizedBox(width: 8),
                      Text(
                        l10n.solved,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (perfect) ...[
                    const SizedBox(height: 10),
                    const _PerfectBadge(),
                  ],
                  const SizedBox(height: 18),
                  if (m != null && !assisted) ...[
                    // Partie SANS aide : les trois maillots (acuité plafonnée / fautes / temps).
                    _MaillotLine(
                      color: const Color(0xFFF2B705),
                      label: l10n.legendAcuity,
                      value: '${m.acuityPercent} %',
                      detail: l10n.isometryDetail(m.isometryCount, m.minIso),
                    ),
                    _MaillotLine(
                      color: const Color(0xFFD64545),
                      label: l10n.legendFaults,
                      value: '${m.faults}',
                      detail: m.faults == 0 ? l10n.faultsNone : l10n.faultsSome,
                    ),
                    _MaillotLine(
                      color: const Color(0xFF2E9E5B),
                      label: l10n.legendTime,
                      value: _mmss(m.timeSeconds),
                    ),
                  ] else if (m != null) ...[
                    // Partie AVEC aide : pas de score de performance (§4.8). Temps seulement.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          l10n.solvedWithHelp(hintCount),
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _MaillotLine(
                      color: const Color(0xFF2E9E5B),
                      label: l10n.legendTime,
                      value: _mmss(m.timeSeconds),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (onLeaderboard != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: onLeaderboard,
                        icon: const Icon(Icons.leaderboard_outlined, size: 18),
                        label: Text(l10n.viewRanking),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: onClose, child: Text(l10n.close)),
                      const SizedBox(width: 8),
                      primaryButton,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

/// Une ligne de maillot dans la carte de bilan : pastille colorée + libellé, valeur brute à
/// droite (§4.5), détail (minimums, isométries) en petit dessous.
class _MaillotLine extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String? detail;

  const _MaillotLine({
    required this.color,
    required this.label,
    required this.value,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26), // léger bord pour détacher la pastille
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (detail != null)
                Text(detail!,
                    style: TextStyle(
                        fontSize: 11, color: Theme.of(context).hintColor)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Badge « Vision parfaite » (§4.6) affiché en tête de carte quand l'acuité est à 100 %.
class _PerfectBadge extends StatelessWidget {
  const _PerfectBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2B705).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech, color: Color(0xFFF2B705), size: 18),
          const SizedBox(width: 6),
          Text(AppLocalizations.of(context).perfectVision,
              style: const TextStyle(
                  color: Color(0xFF9A7400), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}