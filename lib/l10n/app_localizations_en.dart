// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pentapol';

  @override
  String get loading => 'Loading Pentoscope…';

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
  String get homeChallenge => 'Weekly challenge';

  @override
  String get homeRecords => 'My records';

  @override
  String get homeSettings => 'Settings';

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
  String get legendFaults => 'Faults';

  @override
  String get legendTime => 'Time';

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
  String get leaderboardEmpty => 'No score this week\n(or server unreachable).';

  @override
  String get solutionsTitle => 'Solutions';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get challengeTitle => 'Weekly challenge';

  @override
  String get challengeIntro =>
      'Pick a size. The setup is the same for everyone this week, and hints are disabled (ranked mode).';

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
  String get congrats => 'Well done! 🎉';

  @override
  String get firstPuzzlePrompt => 'First puzzle solved. What\'s your name?';

  @override
  String get yourName => 'Your name';

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
  String get hintDisabledChallenge => 'Hint disabled in challenge mode';

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
  String get faultsSome => 'dead ends';

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
      'Sends your nickname and an anonymous identifier to the ranking server. Off by default.';

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
      'To show the ranking, Pentapol sends your nickname and an anonymous identifier to its server when you finish a challenge. Nothing is sent otherwise. You can turn this off and delete your data anytime in Settings.';

  @override
  String get consentEnable => 'Take part';

  @override
  String get consentLater => 'Not now';
}
