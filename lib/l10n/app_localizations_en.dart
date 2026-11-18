// Modified: 2026-11-17 09:57 — ceinture partagée avec les résultats FR/EN.

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String trainingCountdownSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String trainingTimeRemaining(int seconds) {
    return 'Time remaining: $seconds seconds';
  }

  @override
  String get trainingTimeExpired => 'Time is up';

  @override
  String get isometryTrainingTitle => 'Isometries';

  @override
  String isometryTrainingAcuity(int score) {
    return 'Acuity: $score/10';
  }

  @override
  String isometryTrainingStars(int count) {
    return '$count stars';
  }

  @override
  String get appTitle => 'Pentapol';

  @override
  String get loading => 'Loading Pentoscope…';

  @override
  String get resetLocalResultsTitle => 'Reset local results';

  @override
  String get resetLocalResultsConfirm =>
      'Erase the current game, records, personal history and local Solo/Duo/Challenge results? This cannot be undone. Your identity, settings and unlocked Solo levels are kept. Online scores are unchanged.';

  @override
  String get resetLocalResultsDone => 'Local results have been reset.';

  @override
  String get chooseSoloLevel => 'Choose a Solo level';

  @override
  String soloLevelOption(int level, int width, int height) {
    return 'Level $level · $width×$height';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get reset => 'Reset';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get homeIso => 'Iso Game';

  @override
  String get playerQualifierLabel => 'City or qualifier (optional)';

  @override
  String get playerQualifierHint => 'London, Scotland, Owl…';

  @override
  String get playerQualifierHelp =>
      'Shown beside your nickname in rankings. Choose a city, region or nickname, without a precise address. Leave blank to remove it.';

  @override
  String get playerQualifierInvalid =>
      'Up to 20 characters: letters, numbers, spaces, apostrophes and hyphens.';

  @override
  String get rankingYou => 'You';

  @override
  String homeChallengeLevel(String level) {
    return '$level Challenge';
  }

  @override
  String homeDailyChallenge(String day) {
    return '$day Challenge';
  }

  @override
  String get homeRecords => 'My records';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeSolo => 'Solo Game';

  @override
  String get playerRankNovice => 'Novice';

  @override
  String get playerRankExpert => 'Expert';

  @override
  String get playerRankVirtuoso => 'Virtuoso';

  @override
  String homeSoloProgress(int level, int width, int height) {
    return 'Level $level/9 · $width×$height';
  }

  @override
  String get homeDuo => 'Duo Game';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsResetConfirm => 'Reset all settings to their defaults?';

  @override
  String get sectionInterface => 'Interface';

  @override
  String get pieceColors => 'Piece colors';

  @override
  String get customizeColors => 'Customize colors';

  @override
  String get customizeColorsSub => 'Set the 12 piece colors';

  @override
  String get sectionGame => 'Game';

  @override
  String get solutionCounter => 'Solution counter';

  @override
  String get solutionCounterSub => 'Show the number of possible solutions';

  @override
  String get haptics => 'Haptic feedback';

  @override
  String get hapticsSub => 'Vibrate on actions';

  @override
  String get showDragFeedback => 'Piece during dragging';

  @override
  String get showDragFeedbackSub =>
      'Show a copy of the piece under your finger.';

  @override
  String get showIllustratedPieces => 'Illustrated pieces (experimental)';

  @override
  String get showIllustratedPiecesSub =>
      'Split an image across the pieces of every board size.';

  @override
  String get showCounters => 'Show counters';

  @override
  String get showCountersSub =>
      'Time, strategy and assistance during the game.';

  @override
  String get rackSize => 'Rack piece size';

  @override
  String get details => 'Details';

  @override
  String get showPieceNumbers => 'Piece numbers';

  @override
  String get showPieceNumbersSub =>
      'One badge per piece on the board (color only when off).';

  @override
  String get dragSensitivity => 'Drag sensitivity';

  @override
  String dragMs(int ms) {
    return '${ms}ms';
  }

  @override
  String get duelSettings => 'Duel settings';

  @override
  String get duelPlayerName => 'Player name';

  @override
  String get duelNicknameHint => 'Enter your nickname';

  @override
  String get duelResetStats => 'Reset stats';

  @override
  String get clearStatsTitle => 'Clear statistics?';

  @override
  String get clearStatsBody => 'This cannot be undone.';

  @override
  String get clearAction => 'Clear';

  @override
  String get version => 'Version';

  @override
  String get colorSchemeClassic => 'Classic';

  @override
  String get colorSchemePastel => 'Pastel';

  @override
  String get colorSchemeNeon => 'Neon';

  @override
  String get colorSchemeMonochrome => 'Monochrome';

  @override
  String get colorSchemeRainbow => 'Rainbow';

  @override
  String get colorSchemeCustom => 'Custom';

  @override
  String get customColorsTitle => 'Custom colors';

  @override
  String get saveTooltip => 'Save';

  @override
  String pieceLabel(String name, int id) {
    return 'Piece $name (#$id)';
  }

  @override
  String pieceColorTitle(String name) {
    return 'Color of piece $name';
  }

  @override
  String get recordsTitle => 'My records';

  @override
  String get legendAcuity => 'Accuracy';

  @override
  String get legendFaults => 'Dead ends';

  @override
  String get legendTime => 'Speed';

  @override
  String get rankingTime => 'Time';

  @override
  String get challengeFixedPiece => 'Fixed piece';

  @override
  String challengeFixedPieces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fixed pieces',
      one: '$count fixed piece',
    );
    return '$_temp0';
  }

  @override
  String challengePlayablePieces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pieces to place',
      one: '$count piece to place',
    );
    return '$_temp0';
  }

  @override
  String challengePiecesInMoves(int count, int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pieces to place',
      one: '$count piece to place',
    );
    String _temp1 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: '$moves moves',
      one: '$moves move',
    );
    return '$_temp0 in $_temp1';
  }

  @override
  String rankingPoints(int count) {
    return '$count pts';
  }

  @override
  String rankingDuration(int minutes, String seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min $seconds s',
      zero: '$seconds s',
    );
    return '$_temp0';
  }

  @override
  String get refreshChallengeResults => 'Refresh results';

  @override
  String get rankingStrategy => 'Strategy';

  @override
  String strategyActionCount(int count) {
    return '$count moves';
  }

  @override
  String theoreticalMoveCount(int count) {
    return '$count theoretical moves';
  }

  @override
  String strategyMoveRatio(int theoretical, int played) {
    return '$played/$theoretical';
  }

  @override
  String get strategyPlacements => 'Placements';

  @override
  String get strategyRotations => 'Rotations';

  @override
  String get strategySymmetries => 'Reflections';

  @override
  String get strategyTranslations => 'Moves on the board';

  @override
  String get strategyRemovals => 'Removals';

  @override
  String get recordsEmpty =>
      'No records yet.\nFinish a puzzle without help to set one.';

  @override
  String get perfectVisionMsg => 'Perfect vision — 100% accuracy';

  @override
  String leaderboardTitle(int w, int h) {
    return 'Ranking · $w×$h';
  }

  @override
  String challengeWeek(String week) {
    return 'Weekly challenge $week';
  }

  @override
  String get leaderboardEmpty => 'No score today\n(or server unreachable).';

  @override
  String get solutionsTitle => 'Solutions';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get challengeTitle => 'Daily Challenges';

  @override
  String challengeOfDay(String day) {
    return '$day Challenge';
  }

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get challengeModeBadge => 'Challenge Mode';

  @override
  String nextChallengesAt(String time) {
    return 'New challenges at $time';
  }

  @override
  String get challengeIntro =>
      'Six challenges, from white to black belt. Solve your grading puzzle within the time limit to earn the next belt. Otherwise, try again with the next daily challenge. Earned belts are retained; hints are disabled.';

  @override
  String piecesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pieces',
      one: '$count piece',
    );
    return '$_temp0';
  }

  @override
  String get rankingTooltip => 'Ranking';

  @override
  String get periodDay => 'Day';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get congrats => 'Well done! 🎉';

  @override
  String get firstPuzzlePrompt => 'First puzzle solved. What\'s your name?';

  @override
  String get yourName => 'Your name';

  @override
  String get playerNameRules =>
      '3 to 20 characters · letters, numbers, spaces, apostrophes and hyphens';

  @override
  String get playerNameInvalid =>
      'Choose a name with 3 to 20 characters and at least one letter.';

  @override
  String get validate => 'Confirm';

  @override
  String get noPuzzle => 'No puzzle';

  @override
  String get homeTooltip => 'Home';

  @override
  String get newGame => 'New game';

  @override
  String get restartTooltip => 'Restart (same size)';

  @override
  String get noSolutionBack => 'No solution — step back';

  @override
  String compatibleSolutionsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compatible solutions',
      one: '$count compatible solution',
    );
    return '$_temp0';
  }

  @override
  String get compatibleSolutionsTooltip => 'Compatible solutions';

  @override
  String get boardSize => 'Board size';

  @override
  String sizeOption(String label, int w, int h) {
    return '$label ($w×$h)';
  }

  @override
  String get otherDraw => 'Another draw';

  @override
  String get showSolutionOpt => 'Show solution';

  @override
  String get launch => 'Start';

  @override
  String get nextLevel => 'Next level';

  @override
  String get solved => 'Solved!';

  @override
  String get faultsNone => 'no dead ends';

  @override
  String get faultsSome => 'dead ends entered';

  @override
  String solvedWithHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Solved with $count hints',
      one: 'Solved with $count hint',
    );
    return '$_temp0';
  }

  @override
  String get viewRanking => 'View ranking';

  @override
  String get challengeScorePending => 'Result waiting for the network.';

  @override
  String get challengeScorePendingDetail =>
      'Pentapol will send it automatically when the connection returns.';

  @override
  String get perfectVision => 'Perfect vision';

  @override
  String get isoRotateTW => 'Rotate 90° ↺ (CCW)';

  @override
  String get isoRotateCW => 'Rotate 90° ↻ (CW)';

  @override
  String get isoSymH => 'Flip horizontal (SymH)';

  @override
  String get isoSymV => 'Flip vertical (SymV)';

  @override
  String get isoRemove => 'Remove';

  @override
  String get quit => 'Quit';

  @override
  String get quitGameTitle => 'Leave the game?';

  @override
  String get quitGameBody =>
      'You\'ll forfeit the current game.\nThe other players will continue without you.';

  @override
  String get replay => 'Play again';

  @override
  String get victory => 'Victory! 🎉';

  @override
  String get niceTry => 'Well played!';

  @override
  String finishedIn(String time) {
    return 'Finished in $time';
  }

  @override
  String get yourNickname => 'Your nickname';

  @override
  String get enterNickname => 'Enter your nickname';

  @override
  String get createGame => 'Create a game';

  @override
  String get joinGame => 'Join a game';

  @override
  String get roomCode => 'Room code';

  @override
  String get roomCodeHint => 'e.g. ABCD';

  @override
  String get waitingLaunch => 'Waiting to start…';

  @override
  String get codeCopied => 'Code copied!';

  @override
  String get codeMustBe4 => 'The code must be 4 characters';

  @override
  String challengeWeekLabel(String week) {
    return 'Week $week';
  }

  @override
  String get solutionsEmpty => 'No solution compatible with this board.';

  @override
  String levelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get play => 'Play';

  @override
  String get multiplayer => 'Multiplayer';

  @override
  String get defaultPlayer => 'Player';

  @override
  String get hint => 'Hint';

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
  String get sectionDuel => 'Duel mode';

  @override
  String get sectionAbout => 'About';

  @override
  String get notDefined => 'Not set';

  @override
  String duelStatsSummary(int wins, int losses, int draws) {
    return '${wins}W / ${losses}L / ${draws}D';
  }

  @override
  String get gameDuration => 'Game duration';

  @override
  String get statsHeader => '📊 Statistics';

  @override
  String get statGames => 'Games';

  @override
  String get statWins => 'Wins';

  @override
  String get statLosses => 'Losses';

  @override
  String get statDraws => 'Draws';

  @override
  String winRate(String rate) {
    return 'Win rate: $rate%';
  }

  @override
  String get buildLabel => 'Build';

  @override
  String get aboutAuthor => 'Author';

  @override
  String get resultsTitle => '🏆 Results';

  @override
  String get me => 'Me';

  @override
  String get finished => 'Finished';

  @override
  String get connecting => 'Connecting…';

  @override
  String get playersLabel => 'Players';

  @override
  String waitingPlayers(int count) {
    return 'Waiting for players ($count/4)';
  }

  @override
  String startGame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Start ($count players)',
      one: 'Start ($count player)',
    );
    return '$_temp0';
  }

  @override
  String get shareCode => 'Share this code with your friends';

  @override
  String get piecesLabel => 'Pieces';

  @override
  String get configFormat => 'Format';

  @override
  String get configLimit => 'Limit';

  @override
  String get host => 'Host';

  @override
  String get genericError => 'An error occurred';

  @override
  String piecesPlaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pieces placed',
      one: '$count piece placed',
    );
    return '$_temp0';
  }

  @override
  String isometryDetail(int count, int min) {
    return '$count isometries · min $min';
  }

  @override
  String get sectionRanking => 'Online ranking';

  @override
  String get displayName => 'Display name';

  @override
  String get shareScores => 'Take part in the online ranking';

  @override
  String get shareScoresSub =>
      'Sends your nickname, belt, optional qualifier and an anonymous identifier to the ranking server. Off by default.';

  @override
  String get deleteOnlineData => 'Delete my ranking data';

  @override
  String get deleteOnlineDataSub =>
      'Erases your scores from the server and your identifier on this device.';

  @override
  String get deleteOnlineDataConfirm =>
      'This erases your scores from the online ranking and your identifier on this device. This cannot be undone.';

  @override
  String get deleteAction => 'Delete';

  @override
  String get deleteOnlineDataDone => 'Your ranking data has been deleted.';

  @override
  String get consentTitle => 'Take part in the online ranking?';

  @override
  String get consentBody =>
      'To show the ranking, Pentapol sends your nickname, belt, optional qualifier and an anonymous identifier to its server when you finish a challenge. Nothing is sent otherwise. You can turn this off and delete your data anytime in Settings.';

  @override
  String get consentEnable => 'Take part';

  @override
  String get consentLater => 'Not now';

  @override
  String get guidedRotate =>
      'Good! Use the icons to turn the piece to match the outline.';

  @override
  String get guidedMirror =>
      'Good! Try the mirror icons to flip the piece to match the outline.';

  @override
  String get guidedDone =>
      'Well done, you filled the board! You are ready to play.';

  @override
  String get guidedReady =>
      'Perfect! Hold the piece, then drag it onto its outline on the board.';

  @override
  String get guidedAnother => 'Training';

  @override
  String get guidedBrowse => 'Swipe through the rack to explore the pieces.';

  @override
  String guidedChoose(int number) {
    return 'Nice! Tap piece #$number to select it.';
  }

  @override
  String guidedNext(int number) {
    return 'Well done! Find piece #$number in the rack and tap it.';
  }

  @override
  String guidedPiece(int number) {
    return 'Piece #$number';
  }

  @override
  String get guidedRetry =>
      'Nearly there! Adjust the shape with the icons, then aim for the outline.';

  @override
  String get guidedSelectPiece => 'Tap the piece in the rack to select it.';

  @override
  String get guidedTransformPiece =>
      'Use the icons to put the piece in the right position.';

  @override
  String get guidedPlacePiece => 'Move it to the right place on the board.';

  @override
  String get guidedPlaced => 'That’s right!';

  @override
  String get recreationalSelect => 'Tap the piece in the tray.';

  @override
  String get recreationalSelectTwo =>
      'Choose one of the two pieces in the rack.';

  @override
  String get recreationalTransform => 'Rotate or flip the piece.';

  @override
  String get recreationalPlace => 'Drag the piece onto its outline.';

  @override
  String get recreationalPlaced => 'That’s right!';

  @override
  String get recreationalTapAgain => 'Tap: retry. Double tap: play.';

  @override
  String get recreationalTapTraining2 => 'Tap: two pieces. Double tap: play.';

  @override
  String get gameTapNewGame => 'Double tap for a new game.';

  @override
  String get newGameTooltip => 'New game';

  @override
  String soloCompletionStats(String size, int seconds, int helps, int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: '$moves moves',
      one: '1 move',
    );
    String _temp1 = intl.Intl.pluralLogic(
      helps,
      locale: localeName,
      other: 'with $helps assists',
      one: 'with 1 assist',
      zero: 'without assistance',
    );
    return '$size completed in $seconds s and $_temp0 $_temp1';
  }

  @override
  String get geometryTitle => 'Score tuning';

  @override
  String get geometrySettingsSub => 'Fine-tune the Geometry score';

  @override
  String get geometryNextGame =>
      'Saved settings apply to the next solo game. A started game keeps its rules, even after resuming. Challenges and duels keep their own rules.';

  @override
  String get geometryExperimental => 'Experimental scoring · no records';

  @override
  String get geometryInitial => 'Starting score';

  @override
  String get geometryCoefficient => 'Fill penalty';

  @override
  String get geometryExponent => 'Progression exponent';

  @override
  String get geometryExponentHelp =>
      '1: steady · 2: stronger near the end · 3–4: more forgiving early on';

  @override
  String get geometryAreaBonus => 'Extra penalty: region not a multiple of 5';

  @override
  String get geometryPreview => 'Points deducted for each new dead end';

  @override
  String get geometryPreviewFill => 'Filled';

  @override
  String get geometryPreviewOrdinary => 'Dead end';

  @override
  String get geometryPreviewArea => 'Impossible region';

  @override
  String get geometryDefaults => 'Restore defaults';

  @override
  String get geometrySaveError => 'Could not save settings. Try again.';

  @override
  String get legendGeometry => 'Geometry';

  @override
  String get legendCheating => 'Assistance';

  @override
  String get geometryAssisted => 'Assisted game';

  @override
  String get geometryLegacy => 'Challenge scoring';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpIconsTitle => 'Game icons';

  @override
  String get playerProfileTitle => 'Player profile';

  @override
  String playerProfileLevel(int level, int maxLevel) {
    return 'Level $level/$maxLevel';
  }

  @override
  String get playerPieceAcuityTitle => 'Isometric acuity by piece';

  @override
  String get playerPieceDetailTitle => 'Acuity details';

  @override
  String playerPieceDetailValues(
    int placements,
    int theoretical,
    int actual,
    int percent,
  ) {
    return 'Final placements: $placements\nTheoretical minimum: $theoretical\nIsometries performed: $actual\nAcuity: $percent%';
  }

  @override
  String get playerSpeedTitle => 'Solving speed';

  @override
  String get playerSpeedInfo =>
      'Measured on completed games without the yellow lamp. Dead ends and corrections do not change the time.';

  @override
  String playerSpeedFaster(int percent) {
    return '$percent% faster';
  }

  @override
  String playerSpeedSlower(int percent) {
    return '$percent% slower';
  }

  @override
  String get playerSpeedStable => 'Stable speed';

  @override
  String get playerAttemptsTitle => 'Attempt analysis';

  @override
  String playerAttemptsCompleted(int completed, int attempts) {
    return '$completed/$attempts completed';
  }

  @override
  String playerInitialPlacements(int safe, int total, int score) {
    return 'First placement: $safe/$total viable · $score/1000';
  }

  @override
  String playerFaultsPerAttempt(String value) {
    return '$value dead ends / attempt';
  }

  @override
  String get helpTile => 'Help';

  @override
  String get helpTileSub => 'What the game icons mean';

  @override
  String get helpLabelEnterIso => 'Isometries mode';

  @override
  String get helpLabelExitIso => 'Back to game';

  @override
  String get helpLabelViewSolutions => 'View solutions';

  @override
  String get helpLabelSolutionsCounter => 'Solution count';

  @override
  String get helpLabelRotate => 'Rotate';

  @override
  String get helpLabelRemove => 'Remove';

  @override
  String get helpLabelUndo => 'Undo';

  @override
  String get helpDescSettings => 'Opens the settings screen.';

  @override
  String get helpDescEnterIso =>
      'Switches to isometries mode, saving the current board state.';

  @override
  String get helpDescExitIso =>
      'Leaves isometries mode and restores the game state.';

  @override
  String get helpDescViewSolutions =>
      'Shows the solutions that still fit the current board.';

  @override
  String get helpDescSolutionsCounter =>
      'Shows how many solutions are still possible.';

  @override
  String get helpDescRotate => 'Rotates the selected piece (normal mode).';

  @override
  String get helpDescRemove =>
      'Select a piece on the board, then tap the trash icon to return it to the tray.';

  @override
  String get helpDescUndo => 'Undoes the last piece placement.';

  @override
  String get helpDescIsoRotateTW => 'Rotates the piece 90° counter-clockwise.';

  @override
  String get helpDescIsoRotateCW => 'Rotates the piece 90° clockwise.';

  @override
  String get helpDescIsoSymH =>
      'Flips the piece top ↔ bottom (mirror across the horizontal axis).';

  @override
  String get helpDescIsoSymV =>
      'Flips the piece left ↔ right (mirror across the vertical axis).';

  @override
  String get helpDescIsoDelete =>
      'Removes the selected piece from the board (isometries mode).';

  @override
  String get helpDescHome => 'Returns to the home screen.';

  @override
  String get helpDescNewGame => 'Starts a new game with a fresh draw.';

  @override
  String get helpLampAmberLabel => 'Yellow lamp';

  @override
  String get helpLampRedLabel => 'Red lamp';

  @override
  String get helpPlayTitle => 'Playing Pentapol';

  @override
  String get helpPlaySteps =>
      '1. Tap a piece in the tray.\n2. Rotate or flip it with the icons.\n3. Hold it and drag it onto the board.\n\nYou can move placed pieces too. Stuck? Try the light bulb.';

  @override
  String get helpPlayGoal => 'Fill the board, with no gaps or overlaps.';

  @override
  String get helpDescLampAmber =>
      'You can continue: at least one solution remains. If you want help, tap the lamp: it places a piece correctly for you. This tap counts as assistance.';

  @override
  String get helpDescLampRed =>
      'The board has no solution left: you have reached a dead end. Tapping the red lamp removes the last placed piece to step back. You can tap again, until a solution becomes possible — the lamp then turns yellow.';

  @override
  String get aboutDeveloperTitle => 'About the developer';

  @override
  String get aboutDeveloperHeading => 'Paul Marie Larivière';

  @override
  String get aboutDeveloperOriginsTitle => 'The origins of Pentapol';

  @override
  String get aboutDeveloperOrigins1 =>
      'In the late 1970s, at Citroën, Paul de Casteljau trained me in curves and surfaces. At Citroën, we called them ‘curves and surfaces with poles’; they later became famous as Bézier curves and surfaces. Paul de Casteljau spoke of this development with humor tinged with disappointment. He also introduced me to the game of ‘pentaminos’, as we called them then.';

  @override
  String get aboutDeveloperOrigins2 =>
      'In a solution to the 6 × 10 rectangle, he liked to look for groups of two or three pieces with axes of symmetry, or groups that could be rearranged in several ways. Starting with a single layout, these groups could generate many more solutions.';

  @override
  String get aboutDeveloperComputingTitle =>
      'From one computing generation to another';

  @override
  String get aboutDeveloperComputing1 =>
      'At the time, we submitted overnight jobs to IBM mainframes and obtained only a handful of solutions by morning. Today, using a Python program on my iPhone, I have calculated all 9,356 solutions to the 6 × 10 rectangle in advance.';

  @override
  String get aboutDeveloperComputing2 =>
      'These precomputed solutions are stored using a compact 6-bit encoding. The twelve piece codes form a Sperner antichain: no code can be mistaken for another during binary operations. Pentapol can therefore query them with almost instantaneous response times.';

  @override
  String get aboutDeveloperComputing3 =>
      'Artificial intelligence, particularly ChatGPT, also accompanied me in developing Pentapol. This new stage reminds me of the major transitions I have experienced: from assembly language to more accessible languages such as BASIC, and then to object-oriented languages. AI replaces neither the developer\'s experience nor judgement, but it profoundly changes the way software is designed, verified and evolved.';

  @override
  String get aboutDeveloperTributeTitle => 'A tribute';

  @override
  String get aboutDeveloperTribute =>
      'More than forty-five years later, my career as a systems engineer and developer has enabled me to continue that introduction through Pentapol, in tribute to Paul de Casteljau.';

  @override
  String get aboutDeveloperThanksTitle => 'Acknowledgements';

  @override
  String get aboutDeveloperThanks1 =>
      'My thanks to my wife Francine, a tester as attentive as she is demanding. Her formidable ‘Nobody understands this!’ and ‘This isn\'t clear!’ accompanied Pentapol\'s development and often brought me back to what matters most.';

  @override
  String get aboutDeveloperThanks2 =>
      'The days when users apologized for not knowing how to use an application are over: today, it is the developer\'s responsibility to make an application understandable. Francine reminded me of that whenever necessary.';

  @override
  String get discoveryTitle => 'Discover the game';

  @override
  String get discoverySkip => 'Skip';

  @override
  String get discoverySwipeHere => 'Swipe here to see the pieces';

  @override
  String get discoveryBrowse => 'Swipe the tray.\nSelect';

  @override
  String get discoverySelect => 'Select';

  @override
  String get discoveryRotate => 'Orient';

  @override
  String get discoveryUsingIcons => 'using the icons.';

  @override
  String get discoveryPlace => 'Drag the piece\ninto the gap.';

  @override
  String get discoveryDone => 'Bravo!';

  @override
  String get discoveryAgain => 'Training';

  @override
  String get discoveryPlay => 'Play';

  @override
  String leaderboardLevelTitle(String level) {
    return '$level leaderboard';
  }

  @override
  String get cardboardTitle => 'Make your own Pentapol';

  @override
  String get cardboardSlogan => 'What if we explored geometry through play?';

  @override
  String get cardboardIntro =>
      'Make your twelve pentominoes, then solve puzzles. Explore rotations and reflections by moving, turning and flipping the pieces.';

  @override
  String get cardboardMaterialsTitle => 'What you need';

  @override
  String get cardboardMaterials =>
      'Thin cardboard, two A4 sheets, a colour printer, glue and scissors. A ruler to check the 2 cm squares.';

  @override
  String get cardboardStepPrint =>
      'Print the template at actual size, 100%. Each square measures 2 cm.';

  @override
  String get cardboardStepGlue =>
      'Glue the sheets onto thin cardboard, such as a cereal box.';

  @override
  String get cardboardStepCut =>
      'Cut around the outer edges, keeping all five squares of each piece connected.';

  @override
  String get cardboardStepPlay =>
      'Start with the small board and pieces 8, 2 and 6. Fill it without gaps or overlaps.';

  @override
  String get cardboardStepInvent =>
      'Arrange a few pieces, trace their outline and make a puzzle for a friend.';

  @override
  String get cardboardAdultHelp =>
      'Ask an adult to help with cutting if needed.';

  @override
  String get cardboardDownload => 'Download the template';

  @override
  String get cardboardOpenError =>
      'The template page could not be opened. Check your connection and try again.';

  @override
  String get cardboardUnavailable =>
      'The template will be available here once the Pentapol website is live.';

  @override
  String get helpShapesTitle => 'Why twelve shapes?';

  @override
  String get helpShapesRule =>
      'A pentomino is made of five equal-sized squares joined edge to edge. The squares cannot overlap, and touching at a corner alone does not count.';

  @override
  String get helpShapesCount =>
      'Rotating or flipping a shape does not make a new one. Counting these rotations and reflections as the same shape gives exactly twelve different shapes.';

  @override
  String get helpShapesChallenge =>
      'Can you find them all? Take a sheet of squared paper and a pencil. Try drawing all twelve shapes on your own, without looking at the game pieces. Check that each has five squares and remove any duplicates.';

  @override
  String get cardboardHomeTitle => 'Make your own cardboard Pentapol';

  @override
  String get cardboardSearchTitle => 'Your turn to explore!';

  @override
  String get cardboardMakeTitle => 'Make your game';

  @override
  String get cardboardWoodTitle => 'A wooden alternative';

  @override
  String get cardboardWoodMaterials =>
      'As an alternative to cardboard, you can make your Pentapol with 60 identical small wooden cubes, available from craft shops or online, for example on Amazon.';

  @override
  String get cardboardWoodShapes =>
      'First, find the twelve shapes on paper before looking at the templates. For each piece, arrange five cubes face to face, lying flat in a single layer.';

  @override
  String get cardboardWoodGlue =>
      'Glue the cubes together using glue suitable for wood and follow its instructions. Ask an adult for help if needed, then let the glue dry completely.';

  @override
  String get cardboardWoodPaint =>
      'You can then paint each piece a different colour with water-based acrylic paint suitable for your age. Apply thin coats so the pieces still fit together easily, and let them dry before playing.';

  @override
  String get beltWhite => 'White belt';

  @override
  String get beltYellow => 'Yellow belt';

  @override
  String get beltOrange => 'Orange belt';

  @override
  String get beltGreen => 'Green belt';

  @override
  String get beltBlue => 'Blue belt';

  @override
  String get beltBrown => 'Brown belt';

  @override
  String get beltBlack => 'Black belt';

  @override
  String get beltRetryTitle => 'Puzzle solved, belt still to earn';

  @override
  String beltRetryTomorrow(int seconds) {
    return 'For this belt, finish within $seconds s. Try again with the next daily challenge.';
  }

  @override
  String beltGoal(int seconds, String belt) {
    return 'Next goal: $belt, within $seconds s.';
  }

  @override
  String beltTimeLimit(int seconds) {
    return 'Time limit: $seconds s';
  }

  @override
  String beltEarned(String belt) {
    return 'Well done! $belt earned.';
  }

  @override
  String beltChallengeBadge(String belt, int seconds) {
    return '$belt · ≤ $seconds s';
  }
}
