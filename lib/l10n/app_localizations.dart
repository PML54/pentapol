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
  /// **'Daily Challenges'**
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

  /// No description provided for @homeSolo.
  ///
  /// In en, this message translates to:
  /// **'Solo Game'**
  String get homeSolo;

  /// No description provided for @homeDuo.
  ///
  /// In en, this message translates to:
  /// **'Duo Game'**
  String get homeDuo;

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

  /// No description provided for @showDragFeedback.
  ///
  /// In en, this message translates to:
  /// **'Piece during dragging'**
  String get showDragFeedback;

  /// No description provided for @showDragFeedbackSub.
  ///
  /// In en, this message translates to:
  /// **'Show a copy of the piece under your finger.'**
  String get showDragFeedbackSub;

  /// No description provided for @showIllustratedPieces.
  ///
  /// In en, this message translates to:
  /// **'Illustrated pieces (experimental)'**
  String get showIllustratedPieces;

  /// No description provided for @showIllustratedPiecesSub.
  ///
  /// In en, this message translates to:
  /// **'Split an image across the pieces of every board size.'**
  String get showIllustratedPiecesSub;

  /// No description provided for @showCounters.
  ///
  /// In en, this message translates to:
  /// **'Show counters'**
  String get showCounters;

  /// No description provided for @showCountersSub.
  ///
  /// In en, this message translates to:
  /// **'Geometry, dead ends and cheating during the game.'**
  String get showCountersSub;

  /// No description provided for @rackSize.
  ///
  /// In en, this message translates to:
  /// **'Rack piece size'**
  String get rackSize;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @showPieceNumbers.
  ///
  /// In en, this message translates to:
  /// **'Piece numbers'**
  String get showPieceNumbers;

  /// No description provided for @showPieceNumbersSub.
  ///
  /// In en, this message translates to:
  /// **'One badge per piece on the board (color only when off).'**
  String get showPieceNumbersSub;

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
  /// **'Dead ends'**
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
  /// **'No score today\n(or server unreachable).'**
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
  /// **'Daily Challenges'**
  String get challengeTitle;

  /// No description provided for @challengeOfDay.
  ///
  /// In en, this message translates to:
  /// **'{day} Challenge'**
  String challengeOfDay(String day);

  /// No description provided for @weekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySunday;

  /// No description provided for @challengeModeBadge.
  ///
  /// In en, this message translates to:
  /// **'Challenge Mode'**
  String get challengeModeBadge;

  /// No description provided for @challengeIntro.
  ///
  /// In en, this message translates to:
  /// **'Everyone gets the same setup today. Complete a board to unlock the next one; hints are disabled.'**
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

  /// No description provided for @periodDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get periodDay;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

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

  /// No description provided for @playerNameRules.
  ///
  /// In en, this message translates to:
  /// **'3 to 20 characters · letters, numbers, spaces, apostrophes and hyphens'**
  String get playerNameRules;

  /// No description provided for @playerNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a name with 3 to 20 characters and at least one letter.'**
  String get playerNameInvalid;

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
  /// **'dead ends entered'**
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

  /// No description provided for @sectionRanking.
  ///
  /// In en, this message translates to:
  /// **'Online ranking'**
  String get sectionRanking;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @shareScores.
  ///
  /// In en, this message translates to:
  /// **'Take part in the online ranking'**
  String get shareScores;

  /// No description provided for @shareScoresSub.
  ///
  /// In en, this message translates to:
  /// **'Sends your nickname and an anonymous identifier to the ranking server. Off by default.'**
  String get shareScoresSub;

  /// No description provided for @deleteOnlineData.
  ///
  /// In en, this message translates to:
  /// **'Delete my ranking data'**
  String get deleteOnlineData;

  /// No description provided for @deleteOnlineDataSub.
  ///
  /// In en, this message translates to:
  /// **'Erases your scores from the server and your identifier on this device.'**
  String get deleteOnlineDataSub;

  /// No description provided for @deleteOnlineDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This erases your scores from the online ranking and your identifier on this device. This cannot be undone.'**
  String get deleteOnlineDataConfirm;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @deleteOnlineDataDone.
  ///
  /// In en, this message translates to:
  /// **'Your ranking data has been deleted.'**
  String get deleteOnlineDataDone;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Take part in the online ranking?'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'To show the ranking, Pentapol sends your nickname and an anonymous identifier to its server when you finish a challenge. Nothing is sent otherwise. You can turn this off and delete your data anytime in Settings.'**
  String get consentBody;

  /// No description provided for @consentEnable.
  ///
  /// In en, this message translates to:
  /// **'Take part'**
  String get consentEnable;

  /// No description provided for @consentLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get consentLater;

  /// No description provided for @guidedRotate.
  ///
  /// In en, this message translates to:
  /// **'Good! Use the icons to turn the piece to match the outline.'**
  String get guidedRotate;

  /// No description provided for @guidedMirror.
  ///
  /// In en, this message translates to:
  /// **'Good! Try the mirror icons to flip the piece to match the outline.'**
  String get guidedMirror;

  /// No description provided for @guidedDone.
  ///
  /// In en, this message translates to:
  /// **'Well done, you filled the board! You are ready to play.'**
  String get guidedDone;

  /// No description provided for @guidedReady.
  ///
  /// In en, this message translates to:
  /// **'Perfect! Hold the piece, then drag it onto its outline on the board.'**
  String get guidedReady;

  /// No description provided for @guidedAnother.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get guidedAnother;

  /// No description provided for @guidedBrowse.
  ///
  /// In en, this message translates to:
  /// **'Swipe through the rack to explore the pieces.'**
  String get guidedBrowse;

  /// No description provided for @guidedChoose.
  ///
  /// In en, this message translates to:
  /// **'Nice! Tap piece #{number} to select it.'**
  String guidedChoose(int number);

  /// No description provided for @guidedNext.
  ///
  /// In en, this message translates to:
  /// **'Well done! Find piece #{number} in the rack and tap it.'**
  String guidedNext(int number);

  /// No description provided for @guidedPiece.
  ///
  /// In en, this message translates to:
  /// **'Piece #{number}'**
  String guidedPiece(int number);

  /// No description provided for @guidedRetry.
  ///
  /// In en, this message translates to:
  /// **'Nearly there! Adjust the shape with the icons, then aim for the outline.'**
  String get guidedRetry;

  /// No description provided for @guidedSelectPiece.
  ///
  /// In en, this message translates to:
  /// **'Tap the piece in the rack to select it.'**
  String get guidedSelectPiece;

  /// No description provided for @guidedTransformPiece.
  ///
  /// In en, this message translates to:
  /// **'Use the icons to put the piece in the right position.'**
  String get guidedTransformPiece;

  /// No description provided for @guidedPlacePiece.
  ///
  /// In en, this message translates to:
  /// **'Move it to the right place on the board.'**
  String get guidedPlacePiece;

  /// No description provided for @guidedPlaced.
  ///
  /// In en, this message translates to:
  /// **'That’s right!'**
  String get guidedPlaced;

  /// No description provided for @recreationalSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap the piece in the rack to select it.'**
  String get recreationalSelect;

  /// No description provided for @recreationalSelectTwo.
  ///
  /// In en, this message translates to:
  /// **'Choose one of the two pieces in the rack.'**
  String get recreationalSelectTwo;

  /// No description provided for @recreationalTransform.
  ///
  /// In en, this message translates to:
  /// **'Use the icons to put the piece in the right position.'**
  String get recreationalTransform;

  /// No description provided for @recreationalPlace.
  ///
  /// In en, this message translates to:
  /// **'Move it to the right place on the board.'**
  String get recreationalPlace;

  /// No description provided for @recreationalPlaced.
  ///
  /// In en, this message translates to:
  /// **'That’s right!'**
  String get recreationalPlaced;

  /// No description provided for @recreationalTapAgain.
  ///
  /// In en, this message translates to:
  /// **'Tap to restart with Training 1. Double tap to play.'**
  String get recreationalTapAgain;

  /// No description provided for @recreationalTapTraining2.
  ///
  /// In en, this message translates to:
  /// **'Tap for Training 2. Double tap to play.'**
  String get recreationalTapTraining2;

  /// No description provided for @gameTapNewGame.
  ///
  /// In en, this message translates to:
  /// **'Double tap for a new game.'**
  String get gameTapNewGame;

  /// No description provided for @geometryTitle.
  ///
  /// In en, this message translates to:
  /// **'Score tuning'**
  String get geometryTitle;

  /// No description provided for @geometrySettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune the Geometry score'**
  String get geometrySettingsSub;

  /// No description provided for @geometryNextGame.
  ///
  /// In en, this message translates to:
  /// **'Saved settings apply to the next solo game. A started game keeps its rules, even after resuming. Challenges and duels keep their own rules.'**
  String get geometryNextGame;

  /// No description provided for @geometryExperimental.
  ///
  /// In en, this message translates to:
  /// **'Experimental scoring · no records'**
  String get geometryExperimental;

  /// No description provided for @geometryInitial.
  ///
  /// In en, this message translates to:
  /// **'Starting score'**
  String get geometryInitial;

  /// No description provided for @geometryCoefficient.
  ///
  /// In en, this message translates to:
  /// **'Fill penalty'**
  String get geometryCoefficient;

  /// No description provided for @geometryExponent.
  ///
  /// In en, this message translates to:
  /// **'Progression exponent'**
  String get geometryExponent;

  /// No description provided for @geometryExponentHelp.
  ///
  /// In en, this message translates to:
  /// **'1: steady · 2: stronger near the end · 3–4: more forgiving early on'**
  String get geometryExponentHelp;

  /// No description provided for @geometryAreaBonus.
  ///
  /// In en, this message translates to:
  /// **'Extra penalty: region not a multiple of 5'**
  String get geometryAreaBonus;

  /// No description provided for @geometryPreview.
  ///
  /// In en, this message translates to:
  /// **'Points deducted for each new dead end'**
  String get geometryPreview;

  /// No description provided for @geometryPreviewFill.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get geometryPreviewFill;

  /// No description provided for @geometryPreviewOrdinary.
  ///
  /// In en, this message translates to:
  /// **'Dead end'**
  String get geometryPreviewOrdinary;

  /// No description provided for @geometryPreviewArea.
  ///
  /// In en, this message translates to:
  /// **'Impossible region'**
  String get geometryPreviewArea;

  /// No description provided for @geometryDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get geometryDefaults;

  /// No description provided for @geometrySaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings. Try again.'**
  String get geometrySaveError;

  /// No description provided for @legendGeometry.
  ///
  /// In en, this message translates to:
  /// **'Geometry'**
  String get legendGeometry;

  /// No description provided for @legendCheating.
  ///
  /// In en, this message translates to:
  /// **'Cheating'**
  String get legendCheating;

  /// No description provided for @geometryAssisted.
  ///
  /// In en, this message translates to:
  /// **'Assisted game'**
  String get geometryAssisted;

  /// No description provided for @geometryLegacy.
  ///
  /// In en, this message translates to:
  /// **'Challenge scoring'**
  String get geometryLegacy;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help — game icons'**
  String get helpTitle;

  /// No description provided for @helpTile.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTile;

  /// No description provided for @helpTileSub.
  ///
  /// In en, this message translates to:
  /// **'What the game icons mean'**
  String get helpTileSub;

  /// No description provided for @helpLabelEnterIso.
  ///
  /// In en, this message translates to:
  /// **'Isometries mode'**
  String get helpLabelEnterIso;

  /// No description provided for @helpLabelExitIso.
  ///
  /// In en, this message translates to:
  /// **'Back to game'**
  String get helpLabelExitIso;

  /// No description provided for @helpLabelViewSolutions.
  ///
  /// In en, this message translates to:
  /// **'View solutions'**
  String get helpLabelViewSolutions;

  /// No description provided for @helpLabelSolutionsCounter.
  ///
  /// In en, this message translates to:
  /// **'Solution count'**
  String get helpLabelSolutionsCounter;

  /// No description provided for @helpLabelRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get helpLabelRotate;

  /// No description provided for @helpLabelRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get helpLabelRemove;

  /// No description provided for @helpLabelUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get helpLabelUndo;

  /// No description provided for @helpDescSettings.
  ///
  /// In en, this message translates to:
  /// **'Opens the settings screen.'**
  String get helpDescSettings;

  /// No description provided for @helpDescEnterIso.
  ///
  /// In en, this message translates to:
  /// **'Switches to isometries mode, saving the current board state.'**
  String get helpDescEnterIso;

  /// No description provided for @helpDescExitIso.
  ///
  /// In en, this message translates to:
  /// **'Leaves isometries mode and restores the game state.'**
  String get helpDescExitIso;

  /// No description provided for @helpDescViewSolutions.
  ///
  /// In en, this message translates to:
  /// **'Shows the solutions that still fit the current board.'**
  String get helpDescViewSolutions;

  /// No description provided for @helpDescSolutionsCounter.
  ///
  /// In en, this message translates to:
  /// **'Shows how many solutions are still possible.'**
  String get helpDescSolutionsCounter;

  /// No description provided for @helpDescRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotates the selected piece (normal mode).'**
  String get helpDescRotate;

  /// No description provided for @helpDescRemove.
  ///
  /// In en, this message translates to:
  /// **'Removes the selected piece from the board.'**
  String get helpDescRemove;

  /// No description provided for @helpDescUndo.
  ///
  /// In en, this message translates to:
  /// **'Undoes the last piece placement.'**
  String get helpDescUndo;

  /// No description provided for @helpDescIsoRotateTW.
  ///
  /// In en, this message translates to:
  /// **'Rotates the piece 90° counter-clockwise.'**
  String get helpDescIsoRotateTW;

  /// No description provided for @helpDescIsoRotateCW.
  ///
  /// In en, this message translates to:
  /// **'Rotates the piece 90° clockwise.'**
  String get helpDescIsoRotateCW;

  /// No description provided for @helpDescIsoSymH.
  ///
  /// In en, this message translates to:
  /// **'Flips the piece top ↔ bottom (mirror across the horizontal axis).'**
  String get helpDescIsoSymH;

  /// No description provided for @helpDescIsoSymV.
  ///
  /// In en, this message translates to:
  /// **'Flips the piece left ↔ right (mirror across the vertical axis).'**
  String get helpDescIsoSymV;

  /// No description provided for @helpDescIsoDelete.
  ///
  /// In en, this message translates to:
  /// **'Removes the selected piece from the board (isometries mode).'**
  String get helpDescIsoDelete;

  /// No description provided for @helpDescHome.
  ///
  /// In en, this message translates to:
  /// **'Returns to the home screen.'**
  String get helpDescHome;

  /// No description provided for @helpDescNewGame.
  ///
  /// In en, this message translates to:
  /// **'Starts a new game with a fresh draw.'**
  String get helpDescNewGame;

  /// No description provided for @helpLampAmberLabel.
  ///
  /// In en, this message translates to:
  /// **'Yellow lamp'**
  String get helpLampAmberLabel;

  /// No description provided for @helpLampRedLabel.
  ///
  /// In en, this message translates to:
  /// **'Red lamp'**
  String get helpLampRedLabel;

  /// No description provided for @helpDescLampAmber.
  ///
  /// In en, this message translates to:
  /// **'The board still has at least one solution. Tapping the yellow lamp gives a hint: a correct piece is placed automatically.'**
  String get helpDescLampAmber;

  /// No description provided for @helpDescLampRed.
  ///
  /// In en, this message translates to:
  /// **'The board has no solution left: you have reached a dead end. Tapping the red lamp removes the last placed piece to step back. You can tap again, until a solution becomes possible — the lamp then turns yellow.'**
  String get helpDescLampRed;

  /// No description provided for @aboutDeveloperTitle.
  ///
  /// In en, this message translates to:
  /// **'About the developer'**
  String get aboutDeveloperTitle;

  /// No description provided for @aboutDeveloperHeading.
  ///
  /// In en, this message translates to:
  /// **'Paul Marie Larivière'**
  String get aboutDeveloperHeading;

  /// No description provided for @aboutDeveloperOriginsTitle.
  ///
  /// In en, this message translates to:
  /// **'The origins of Pentapol'**
  String get aboutDeveloperOriginsTitle;

  /// No description provided for @aboutDeveloperOrigins1.
  ///
  /// In en, this message translates to:
  /// **'In the late 1970s, at Citroën, Paul de Casteljau trained me in curves and surfaces. At Citroën, we called them ‘curves and surfaces with poles’; they later became famous as Bézier curves and surfaces. Paul de Casteljau spoke of this development with humor tinged with disappointment. He also introduced me to the game of ‘pentaminos’, as we called them then.'**
  String get aboutDeveloperOrigins1;

  /// No description provided for @aboutDeveloperOrigins2.
  ///
  /// In en, this message translates to:
  /// **'In a solution to the 6 × 10 rectangle, he liked to look for groups of two or three pieces with axes of symmetry, or groups that could be rearranged in several ways. Starting with a single layout, these groups could generate many more solutions.'**
  String get aboutDeveloperOrigins2;

  /// No description provided for @aboutDeveloperComputingTitle.
  ///
  /// In en, this message translates to:
  /// **'From one computing generation to another'**
  String get aboutDeveloperComputingTitle;

  /// No description provided for @aboutDeveloperComputing1.
  ///
  /// In en, this message translates to:
  /// **'At the time, we submitted overnight jobs to IBM mainframes and obtained only a handful of solutions by morning. Today, using a Python program on my iPhone, I have calculated all 9,356 solutions to the 6 × 10 rectangle in advance.'**
  String get aboutDeveloperComputing1;

  /// No description provided for @aboutDeveloperComputing2.
  ///
  /// In en, this message translates to:
  /// **'These precomputed solutions are stored using a compact 6-bit encoding. The twelve piece codes form a Sperner antichain: no code can be mistaken for another during binary operations. Pentapol can therefore query them with almost instantaneous response times.'**
  String get aboutDeveloperComputing2;

  /// No description provided for @aboutDeveloperComputing3.
  ///
  /// In en, this message translates to:
  /// **'Artificial intelligence, particularly ChatGPT, also accompanied me in developing Pentapol. This new stage reminds me of the major transitions I have experienced: from assembly language to more accessible languages such as BASIC, and then to object-oriented languages. AI replaces neither the developer\'s experience nor judgement, but it profoundly changes the way software is designed, verified and evolved.'**
  String get aboutDeveloperComputing3;

  /// No description provided for @aboutDeveloperTributeTitle.
  ///
  /// In en, this message translates to:
  /// **'A tribute'**
  String get aboutDeveloperTributeTitle;

  /// No description provided for @aboutDeveloperTribute.
  ///
  /// In en, this message translates to:
  /// **'More than forty-five years later, my career as a systems engineer and developer has enabled me to continue that introduction through Pentapol, in tribute to Paul de Casteljau.'**
  String get aboutDeveloperTribute;

  /// No description provided for @aboutDeveloperThanksTitle.
  ///
  /// In en, this message translates to:
  /// **'Acknowledgements'**
  String get aboutDeveloperThanksTitle;

  /// No description provided for @aboutDeveloperThanks1.
  ///
  /// In en, this message translates to:
  /// **'My thanks to my wife Francine, a tester as attentive as she is demanding. Her formidable ‘Nobody understands this!’ and ‘This isn\'t clear!’ accompanied Pentapol\'s development and often brought me back to what matters most.'**
  String get aboutDeveloperThanks1;

  /// No description provided for @aboutDeveloperThanks2.
  ///
  /// In en, this message translates to:
  /// **'The days when users apologized for not knowing how to use an application are over: today, it is the developer\'s responsibility to make an application understandable. Francine reminded me of that whenever necessary.'**
  String get aboutDeveloperThanks2;
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
