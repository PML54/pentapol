// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Pentapol';

  @override
  String get loading => 'Chargement de Pentoscope…';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get save => 'Sauvegarder';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get retry => 'Réessayer';

  @override
  String get back => 'Retour';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageSystem => 'Système';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get homeChallenge => 'Défi de la semaine';

  @override
  String get homeRecords => 'Mes records';

  @override
  String get homeSettings => 'Réglages';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsResetConfirm =>
      'Voulez-vous réinitialiser tous les paramètres par défaut ?';

  @override
  String get sectionInterface => 'Interface';

  @override
  String get pieceColors => 'Couleurs des pièces';

  @override
  String get customizeColors => 'Personnaliser les couleurs';

  @override
  String get customizeColorsSub => 'Définir les 12 couleurs des pièces';

  @override
  String get sectionGame => 'Jeu';

  @override
  String get solutionCounter => 'Compteur de solutions';

  @override
  String get solutionCounterSub => 'Afficher le nombre de solutions possibles';

  @override
  String get haptics => 'Retour haptique';

  @override
  String get hapticsSub => 'Vibrations lors des actions';

  @override
  String get showCounters => 'Afficher les compteurs';

  @override
  String get showCountersSub =>
      'Géométrie, impasses et triche pendant la partie.';

  @override
  String get rackSize => 'Taille des pièces du rack';

  @override
  String get details => 'Détails';

  @override
  String get showPieceNumbers => 'Numéro des pièces';

  @override
  String get showPieceNumbersSub =>
      'Une pastille par pièce sur le plateau (couleur seule si désactivé).';

  @override
  String get dragSensitivity => 'Sensibilité du drag';

  @override
  String dragMs(int ms) {
    return '${ms}ms';
  }

  @override
  String get duelSettings => 'Paramètres Duel';

  @override
  String get duelPlayerName => 'Nom du joueur';

  @override
  String get duelNicknameHint => 'Entrez votre pseudo';

  @override
  String get duelResetStats => 'Réinit. stats';

  @override
  String get clearStatsTitle => 'Effacer les statistiques ?';

  @override
  String get clearStatsBody => 'Cette action est irréversible.';

  @override
  String get clearAction => 'Effacer';

  @override
  String get version => 'Version';

  @override
  String get colorSchemeClassic => 'Classique';

  @override
  String get colorSchemePastel => 'Pastel';

  @override
  String get colorSchemeNeon => 'Néon';

  @override
  String get colorSchemeMonochrome => 'Monochrome';

  @override
  String get colorSchemeRainbow => 'Arc-en-ciel';

  @override
  String get colorSchemeCustom => 'Personnalisé';

  @override
  String get customColorsTitle => 'Couleurs personnalisées';

  @override
  String get saveTooltip => 'Enregistrer';

  @override
  String pieceLabel(String name, int id) {
    return 'Pièce $name (#$id)';
  }

  @override
  String pieceColorTitle(String name) {
    return 'Couleur de la pièce $name';
  }

  @override
  String get recordsTitle => 'Mes records';

  @override
  String get legendAcuity => 'Acuité';

  @override
  String get legendFaults => 'Impasses';

  @override
  String get legendTime => 'Temps';

  @override
  String get recordsEmpty =>
      'Aucun record pour l\'instant.\nTermine un puzzle sans aide pour en poser un.';

  @override
  String get perfectVisionMsg => 'Vision parfaite — acuité 100 %';

  @override
  String leaderboardTitle(int w, int h) {
    return 'Classement · $w×$h';
  }

  @override
  String challengeWeek(String week) {
    return 'Défi de la semaine $week';
  }

  @override
  String get leaderboardEmpty =>
      'Aucun score cette semaine\n(ou serveur injoignable).';

  @override
  String get solutionsTitle => 'Solutions';

  @override
  String get previous => 'Précédente';

  @override
  String get next => 'Suivante';

  @override
  String get challengeTitle => 'Défi de la semaine';

  @override
  String get challengeIntro =>
      'Choisis une taille. La configuration est la même pour tous cette semaine, et l\'indice est désactivé (mode classé).';

  @override
  String piecesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces',
      one: '$count pièce',
    );
    return '$_temp0';
  }

  @override
  String get rankingTooltip => 'Classement';

  @override
  String get congrats => 'Bravo ! 🎉';

  @override
  String get firstPuzzlePrompt =>
      'Premier puzzle réussi. Comment t\'appelles-tu ?';

  @override
  String get yourName => 'Ton nom';

  @override
  String get validate => 'Valider';

  @override
  String get noPuzzle => 'Aucun puzzle';

  @override
  String get homeTooltip => 'Accueil';

  @override
  String get newGame => 'Nouvelle partie';

  @override
  String get restartTooltip => 'Recommencer (même taille)';

  @override
  String get hintDisabledChallenge => 'Indice désactivé en mode défi';

  @override
  String get noSolutionBack => 'Aucune solution — revenir en arrière';

  @override
  String compatibleSolutionsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count solutions compatibles',
      one: '$count solution compatible',
    );
    return '$_temp0';
  }

  @override
  String get compatibleSolutionsTooltip => 'Solutions compatibles';

  @override
  String get boardSize => 'Taille du plateau';

  @override
  String sizeOption(String label, int w, int h) {
    return '$label ($w×$h)';
  }

  @override
  String get otherDraw => 'Autre tirage';

  @override
  String get showSolutionOpt => 'Montrer la solution';

  @override
  String get launch => 'Lancer';

  @override
  String get nextLevel => 'Niveau suivant';

  @override
  String get solved => 'Résolu !';

  @override
  String get faultsNone => 'aucune impasse';

  @override
  String get faultsSome => 'entrées en impasse';

  @override
  String solvedWithHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Résolu avec $count aides',
      one: 'Résolu avec $count aide',
    );
    return '$_temp0';
  }

  @override
  String get viewRanking => 'Voir le classement';

  @override
  String get perfectVision => 'Vision parfaite';

  @override
  String get isoRotateTW => 'Rotation 90° ↺ (TW)';

  @override
  String get isoRotateCW => 'Rotation 90° ↻ (CW)';

  @override
  String get isoSymH => 'Symétrie axe horizontal (SymH)';

  @override
  String get isoSymV => 'Symétrie axe vertical (SymV)';

  @override
  String get isoRemove => 'Retirer';

  @override
  String get quit => 'Quitter';

  @override
  String get quitGameTitle => 'Quitter la partie ?';

  @override
  String get quitGameBody =>
      'Tu vas abandonner la partie en cours.\nLes autres joueurs continueront sans toi.';

  @override
  String get replay => 'Rejouer';

  @override
  String get victory => 'Victoire ! 🎉';

  @override
  String get niceTry => 'Bien joué !';

  @override
  String finishedIn(String time) {
    return 'Terminé en $time';
  }

  @override
  String get yourNickname => 'Ton pseudo';

  @override
  String get enterNickname => 'Entre ton pseudo';

  @override
  String get createGame => 'Créer une Partie';

  @override
  String get joinGame => 'Rejoindre une Partie';

  @override
  String get roomCode => 'Code de la room';

  @override
  String get roomCodeHint => 'Ex : ABCD';

  @override
  String get waitingLaunch => 'En attente du lancement…';

  @override
  String get codeCopied => 'Code copié !';

  @override
  String get codeMustBe4 => 'Le code doit faire 4 caractères';

  @override
  String challengeWeekLabel(String week) {
    return 'Semaine $week';
  }

  @override
  String get solutionsEmpty => 'Aucune solution compatible avec ce plateau.';

  @override
  String levelLabel(int level) {
    return 'Niveau $level';
  }

  @override
  String get play => 'Jouer';

  @override
  String get multiplayer => 'Multijoueur';

  @override
  String get defaultPlayer => 'Joueur';

  @override
  String get hint => 'Indice';

  @override
  String drawSolutionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count solutions',
      one: '$count solution',
    );
    return '$_temp0';
  }

  @override
  String get sectionDuel => 'Mode Duel';

  @override
  String get sectionAbout => 'À propos';

  @override
  String get notDefined => 'Non défini';

  @override
  String duelStatsSummary(int wins, int losses, int draws) {
    return '${wins}V / ${losses}D / ${draws}N';
  }

  @override
  String get gameDuration => 'Durée de partie';

  @override
  String get statsHeader => '📊 Statistiques';

  @override
  String get statGames => 'Parties';

  @override
  String get statWins => 'Victoires';

  @override
  String get statLosses => 'Défaites';

  @override
  String get statDraws => 'Égalités';

  @override
  String winRate(String rate) {
    return 'Taux de victoire : $rate%';
  }

  @override
  String get buildLabel => 'Build';

  @override
  String get aboutAuthor => 'Auteur';

  @override
  String get resultsTitle => '🏆 Résultats';

  @override
  String get me => 'Moi';

  @override
  String get finished => 'Terminé';

  @override
  String get connecting => 'Connexion…';

  @override
  String get playersLabel => 'Joueurs';

  @override
  String waitingPlayers(int count) {
    return 'En attente de joueurs ($count/4)';
  }

  @override
  String startGame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Démarrer ($count joueurs)',
      one: 'Démarrer ($count joueur)',
    );
    return '$_temp0';
  }

  @override
  String get shareCode => 'Partage ce code avec tes amis';

  @override
  String get piecesLabel => 'Pièces';

  @override
  String get configFormat => 'Format';

  @override
  String get configLimit => 'Limite';

  @override
  String get host => 'Hôte';

  @override
  String get genericError => 'Une erreur est survenue';

  @override
  String piecesPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces placées',
      one: '$count pièce placée',
    );
    return '$_temp0';
  }

  @override
  String isometryDetail(int count, int min) {
    return '$count isométries · min $min';
  }

  @override
  String get sectionRanking => 'Classement en ligne';

  @override
  String get displayName => 'Nom affiché';

  @override
  String get shareScores => 'Participer au classement en ligne';

  @override
  String get shareScoresSub =>
      'Envoie ton pseudo et un identifiant anonyme au serveur de classement. Désactivé par défaut.';

  @override
  String get deleteOnlineData => 'Supprimer mes données de classement';

  @override
  String get deleteOnlineDataSub =>
      'Efface tes scores du serveur et ton identifiant sur cet appareil.';

  @override
  String get deleteOnlineDataConfirm =>
      'Ceci efface tes scores du classement en ligne et ton identifiant sur cet appareil. C\'est irréversible.';

  @override
  String get deleteAction => 'Supprimer';

  @override
  String get deleteOnlineDataDone =>
      'Tes données de classement ont été supprimées.';

  @override
  String get consentTitle => 'Participer au classement en ligne ?';

  @override
  String get consentBody =>
      'Pour afficher le classement, Pentapol envoie ton pseudo et un identifiant anonyme à son serveur à la fin d\'un défi. Rien n\'est envoyé autrement. Tu peux le désactiver et supprimer tes données à tout moment dans les Réglages.';

  @override
  String get consentEnable => 'Participer';

  @override
  String get consentLater => 'Plus tard';

  @override
  String get guidedRotate =>
      'Bien ! Utilise les icônes pour tourner la pièce comme la silhouette.';

  @override
  String get guidedMirror =>
      'Bien ! Essaie les icônes de miroir pour retourner la pièce comme la silhouette.';

  @override
  String get guidedDone => 'Bravo, tu as rempli le plateau ! À toi de jouer.';

  @override
  String get guidedReady =>
      'Parfait ! Maintiens la pièce, puis glisse-la sur sa silhouette sur le plateau.';

  @override
  String get guidedAnother => 'Training';

  @override
  String get guidedBrowse =>
      'Fais défiler le rack en faisant glisser les pièces.';

  @override
  String guidedChoose(int number) {
    return 'Bien ! Touche la pièce n°$number pour la sélectionner.';
  }

  @override
  String guidedNext(int number) {
    return 'Bien joué ! Cherche maintenant la pièce n°$number dans le rack et touche-la.';
  }

  @override
  String guidedPiece(int number) {
    return 'Pièce n°$number';
  }

  @override
  String get guidedRetry =>
      'Tu y es presque ! Ajuste la forme avec les icônes, puis vise la silhouette.';

  @override
  String get geometryTitle => 'Réglage du barème';

  @override
  String get geometrySettingsSub => 'Mettre au point la note Géométrie';

  @override
  String get geometryNextGame =>
      'Les réglages sauvegardés s’appliquent à la prochaine partie solo. Une partie commencée conserve son barème, même après une reprise. Les défis et duels gardent leurs règles.';

  @override
  String get geometryExperimental => 'Barème expérimental · hors records';

  @override
  String get geometryInitial => 'Note de départ';

  @override
  String get geometryCoefficient => 'Pénalité liée au remplissage';

  @override
  String get geometryExponent => 'Progressivité';

  @override
  String get geometryExponentHelp =>
      '1 : régulière · 2 : accentuée en fin de partie · 3–4 : début plus indulgent';

  @override
  String get geometryAreaBonus => 'Supplément : zone non multiple de 5';

  @override
  String get geometryPreview => 'Points retirés par nouvelle impasse';

  @override
  String get geometryPreviewFill => 'Rempli';

  @override
  String get geometryPreviewOrdinary => 'Impasse';

  @override
  String get geometryPreviewArea => 'Zone impossible';

  @override
  String get geometryDefaults => 'Rétablir les valeurs initiales';

  @override
  String get geometrySaveError =>
      'Impossible de sauvegarder les réglages. Réessaie.';

  @override
  String get legendGeometry => 'Géométrie';

  @override
  String get legendCheating => 'Triche';

  @override
  String get geometryAssisted => 'Partie aidée';

  @override
  String get geometryLegacy => 'Barème du défi';
}
