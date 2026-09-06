import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Pentapol'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading Pentoscope…'**
  String get loading;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @homeChallenge.
  ///
  /// In en, this message translates to:
  /// **'Weekly challenge'**
  String get homeChallenge;

  /// No description provided for @homeRecords.
  ///
  /// In en, this message translates to:
  /// **'My records'**
  String get homeRecords;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset all settings to their defaults?'**
  String get settingsResetConfirm;

  /// No description provided for @sectionInterface.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get sectionInterface;

  /// No description provided for @pieceColors.
  ///
  /// In en, this message translates to:
  /// **'Piece colors'**
  String get pieceColors;

  /// No description provided for @customizeColors.
  ///
  /// In en, this message translates to:
  /// **'Customize colors'**
  String get customizeColors;

  /// No description provided for @customizeColorsSub.
  ///
  /// In en, this message translates to:
  /// **'Set the 12 piece colors'**
  String get customizeColorsSub;

  /// No description provided for @sectionGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get sectionGame;

  /// No description provided for @solutionCounter.
  ///
  /// In en, this message translates to:
  /// **'Solution counter'**
  String get solutionCounter;

  /// No description provided for @solutionCounterSub.
  ///
  /// In en, this message translates to:
  /// **'Show the number of possible solutions'**
  String get solutionCounterSub;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get haptics;

  /// No description provided for @hapticsSub.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on actions'**
  String get hapticsSub;

  /// No description provided for @dragSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Drag sensitivity'**
  String get dragSensitivity;

  /// No description provided for @dragMs.
  ///
  /// In en, this message translates to:
  /// **'{ms}ms'**
  String dragMs(int ms);

  /// No description provided for @duelSettings.
  ///
  /// In en, this message translates to:
  /// **'Duel settings'**
  String get duelSettings;

  /// No description provided for @duelPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get duelPlayerName;

  /// No description provided for @duelNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get duelNicknameHint;

  /// No description provided for @duelResetStats.
  ///
  /// In en, this message translates to:
  /// **'Reset stats'**
  String get duelResetStats;

  /// No description provided for @clearStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear statistics?'**
  String get clearStatsTitle;

  /// No description provided for @clearStatsBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get clearStatsBody;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @colorSchemeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get colorSchemeClassic;

  /// No description provided for @colorSchemePastel.
  ///
  /// In en, this message translates to:
  /// **'Pastel'**
  String get colorSchemePastel;

  /// No description provided for @colorSchemeNeon.
  ///
  /// In en, this message translates to:
  /// **'Neon'**
  String get colorSchemeNeon;

  /// No description provided for @colorSchemeMonochrome.
  ///
  /// In en, this message translates to:
  /// **'Monochrome'**
  String get colorSchemeMonochrome;

  /// No description provided for @colorSchemeRainbow.
  ///
  /// In en, this message translates to:
  /// **'Rainbow'**
  String get colorSchemeRainbow;

  /// No description provided for @colorSchemeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get colorSchemeCustom;

  /// No description provided for @customColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom colors'**
  String get customColorsTitle;

  /// No description provided for @saveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveTooltip;

  /// No description provided for @pieceLabel.
  ///
  /// In en, this message translates to:
  /// **'Piece {name} (#{id})'**
  String pieceLabel(String name, int id);

  /// No description provided for @pieceColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Color of piece {name}'**
  String pieceColorTitle(String name);

  /// No description provided for @recordsTitle.
  ///
  /// In en, this message translates to:
  /// **'My records'**
  String get recordsTitle;

  /// No description provided for @legendAcuity.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get legendAcuity;

  /// No description provided for @legendFaults.
  ///
  /// In en, this message translates to:
  /// **'Faults'**
  String get legendFaults;

  /// No description provided for @legendTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get legendTime;

  /// No description provided for @recordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet.\nFinish a puzzle without help to set one.'**
  String get recordsEmpty;

  /// No description provided for @perfectVisionMsg.
  ///
  /// In en, this message translates to:
  /// **'Perfect vision — 100% accuracy'**
  String get perfectVisionMsg;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Ranking · {w}×{h}'**
  String leaderboardTitle(int w, int h);

  /// No description provided for @challengeWeek.
  ///
  /// In en, this message translates to:
  /// **'Weekly challenge {week}'**
  String challengeWeek(String week);

  /// No description provided for @leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No score this week\n(or server unreachable).'**
  String get leaderboardEmpty;

  /// No description provided for @solutionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Solutions'**
  String get solutionsTitle;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @challengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly challenge'**
  String get challengeTitle;

  /// No description provided for @challengeIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick a size. The setup is the same for everyone this week, and hints are disabled (ranked mode).'**
  String get challengeIntro;

  /// No description provided for @piecesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} piece} other{{count} pieces}}'**
  String piecesCount(int count);

  /// No description provided for @rankingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get rankingTooltip;

  /// No description provided for @congrats.
  ///
  /// In en, this message translates to:
  /// **'Well done! 🎉'**
  String get congrats;

  /// No description provided for @firstPuzzlePrompt.
  ///
  /// In en, this message translates to:
  /// **'First puzzle solved. What\'s your name?'**
  String get firstPuzzlePrompt;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @validate.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get validate;

  /// No description provided for @noPuzzle.
  ///
  /// In en, this message translates to:
  /// **'No puzzle'**
  String get noPuzzle;

  /// No description provided for @homeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTooltip;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get newGame;

  /// No description provided for @restartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Restart (same size)'**
  String get restartTooltip;

  /// No description provided for @hintDisabledChallenge.
  ///
  /// In en, this message translates to:
  /// **'Hint disabled in challenge mode'**
  String get hintDisabledChallenge;

  /// No description provided for @noSolutionBack.
  ///
  /// In en, this message translates to:
  /// **'No solution — step back'**
  String get noSolutionBack;

  /// No description provided for @compatibleSolutionsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} compatible solution} other{{count} compatible solutions}}'**
  String compatibleSolutionsTitle(int count);

  /// No description provided for @compatibleSolutionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Compatible solutions'**
  String get compatibleSolutionsTooltip;

  /// No description provided for @boardSize.
  ///
  /// In en, this message translates to:
  /// **'Board size'**
  String get boardSize;

  /// No description provided for @sizeOption.
  ///
  /// In en, this message translates to:
  /// **'{label} ({w}×{h})'**
  String sizeOption(String label, int w, int h);

  /// No description provided for @otherDraw.
  ///
  /// In en, this message translates to:
  /// **'Another draw'**
  String get otherDraw;

  /// No description provided for @showSolutionOpt.
  ///
  /// In en, this message translates to:
  /// **'Show solution'**
  String get showSolutionOpt;

  /// No description provided for @launch.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get launch;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get nextLevel;

  /// No description provided for @solved.
  ///
  /// In en, this message translates to:
  /// **'Solved!'**
  String get solved;

  /// No description provided for @faultsNone.
  ///
  /// In en, this message translates to:
  /// **'no dead ends'**
  String get faultsNone;

  /// No description provided for @faultsSome.
  ///
  /// In en, this message translates to:
  /// **'dead ends'**
  String get faultsSome;

  /// No description provided for @solvedWithHelp.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Solved with {count} hint} other{Solved with {count} hints}}'**
  String solvedWithHelp(int count);

  /// No description provided for @viewRanking.
  ///
  /// In en, this message translates to:
  /// **'View ranking'**
  String get viewRanking;

  /// No description provided for @perfectVision.
  ///
  /// In en, this message translates to:
  /// **'Perfect vision'**
  String get perfectVision;

  /// No description provided for @isoRotateTW.
  ///
  /// In en, this message translates to:
  /// **'Rotate 90° ↺ (CCW)'**
  String get isoRotateTW;

  /// No description provided for @isoRotateCW.
  ///
  /// In en, this message translates to:
  /// **'Rotate 90° ↻ (CW)'**
  String get isoRotateCW;

  /// No description provided for @isoSymH.
  ///
  /// In en, this message translates to:
  /// **'Flip horizontal (SymH)'**
  String get isoSymH;

  /// No description provided for @isoSymV.
  ///
  /// In en, this message translates to:
  /// **'Flip vertical (SymV)'**
  String get isoSymV;

  /// No description provided for @isoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get isoRemove;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @quitGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the game?'**
  String get quitGameTitle;

  /// No description provided for @quitGameBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll forfeit the current game.\nThe other players will continue without you.'**
  String get quitGameBody;

  /// No description provided for @replay.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get replay;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory! 🎉'**
  String get victory;

  /// No description provided for @niceTry.
  ///
  /// In en, this message translates to:
  /// **'Well played!'**
  String get niceTry;

  /// No description provided for @finishedIn.
  ///
  /// In en, this message translates to:
  /// **'Finished in {time}'**
  String finishedIn(String time);

  /// No description provided for @yourNickname.
  ///
  /// In en, this message translates to:
  /// **'Your nickname'**
  String get yourNickname;

  /// No description provided for @enterNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get enterNickname;

  /// No description provided for @createGame.
  ///
  /// In en, this message translates to:
  /// **'Create a game'**
  String get createGame;

  /// No description provided for @joinGame.
  ///
  /// In en, this message translates to:
  /// **'Join a game'**
  String get joinGame;

  /// No description provided for @roomCode.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get roomCode;

  /// No description provided for @roomCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ABCD'**
  String get roomCodeHint;

  /// No description provided for @waitingLaunch.
  ///
  /// In en, this message translates to:
  /// **'Waiting to start…'**
  String get waitingLaunch;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get codeCopied;

  /// No description provided for @codeMustBe4.
  ///
  /// In en, this message translates to:
  /// **'The code must be 4 characters'**
  String get codeMustBe4;

  /// No description provided for @challengeWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String challengeWeekLabel(String week);

  /// No description provided for @solutionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No solution compatible with this board.'**
  String get solutionsEmpty;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelLabel(int level);

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @multiplayer.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer'**
  String get multiplayer;

  /// No description provided for @defaultPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get defaultPlayer;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @drawSolutionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} solution} other{{count} solutions}}'**
  String drawSolutionsCount(int count);

  /// No description provided for @sectionDuel.
  ///
  /// In en, this message translates to:
  /// **'Duel mode'**
  String get sectionDuel;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @notDefined.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notDefined;

  /// No description provided for @duelStatsSummary.
  ///
  /// In en, this message translates to:
  /// **'{wins}W / {losses}L / {draws}D'**
  String duelStatsSummary(int wins, int losses, int draws);

  /// No description provided for @gameDuration.
  ///
  /// In en, this message translates to:
  /// **'Game duration'**
  String get gameDuration;

  /// No description provided for @statsHeader.
  ///
  /// In en, this message translates to:
  /// **'📊 Statistics'**
  String get statsHeader;

  /// No description provided for @statGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get statGames;

  /// No description provided for @statWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get statWins;

  /// No description provided for @statLosses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get statLosses;

  /// No description provided for @statDraws.
  ///
  /// In en, this message translates to:
  /// **'Draws'**
  String get statDraws;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate: {rate}%'**
  String winRate(String rate);

  /// No description provided for @buildLabel.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get buildLabel;

  /// No description provided for @aboutAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get aboutAuthor;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'🏆 Results'**
  String get resultsTitle;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @playersLabel.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get playersLabel;

  /// No description provided for @waitingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players ({count}/4)'**
  String waitingPlayers(int count);

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Start ({count} player)} other{Start ({count} players)}}'**
  String startGame(int count);

  /// No description provided for @shareCode.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your friends'**
  String get shareCode;

  /// No description provided for @piecesLabel.
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get piecesLabel;

  /// No description provided for @configFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get configFormat;

  /// No description provided for @configLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get configLimit;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get genericError;

  /// No description provided for @piecesPlaced.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} piece placed} other{{count} pieces placed}}'**
  String piecesPlaced(int count);

  /// No description provided for @isometryDetail.
  ///
  /// In en, this message translates to:
  /// **'{count} isometries · min {min}'**
  String isometryDetail(int count, int min);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
