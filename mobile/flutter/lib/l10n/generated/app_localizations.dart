import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ha.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_jv.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_sw.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tl.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('ar'),
    Locale('bn'),
    Locale('cs'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('fr'),
    Locale('ha'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('jv'),
    Locale('kn'),
    Locale('ko'),
    Locale('ml'),
    Locale('mr'),
    Locale('ms'),
    Locale('ne'),
    Locale('nl'),
    Locale('or'),
    Locale('pa'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('sv'),
    Locale('sw'),
    Locale('ta'),
    Locale('te'),
    Locale('th'),
    Locale('tl'),
    Locale('tr'),
    Locale('ur'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// Product name
  ///
  /// In en, this message translates to:
  /// **'Zealova'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get navWorkouts;

  /// No description provided for @navNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get navNutrition;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @buttonStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get buttonStart;

  /// No description provided for @buttonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// No description provided for @buttonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// No description provided for @buttonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get buttonDelete;

  /// No description provided for @buttonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get buttonRetry;

  /// No description provided for @buttonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get buttonContinue;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @equipmentCalibrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Calibrate equipment'**
  String get equipmentCalibrationTitle;

  /// No description provided for @equipmentCalibrationIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us your real gear'**
  String get equipmentCalibrationIntroTitle;

  /// No description provided for @equipmentCalibrationIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Plate suggestions and weight prescriptions will match what you actually own. Set your bar weights, machine sled weights, cable pin increments, and plate / dumbbell inventory.'**
  String get equipmentCalibrationIntroBody;

  /// No description provided for @recoveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get recoveryLabel;

  /// No description provided for @rpeLabel.
  ///
  /// In en, this message translates to:
  /// **'RPE'**
  String get rpeLabel;

  /// No description provided for @rpeFailure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get rpeFailure;

  /// No description provided for @rpeOneRepLeft.
  ///
  /// In en, this message translates to:
  /// **'1 rep left'**
  String get rpeOneRepLeft;

  /// No description provided for @rpeTwoRepsLeft.
  ///
  /// In en, this message translates to:
  /// **'2 reps left'**
  String get rpeTwoRepsLeft;

  /// No description provided for @rpeEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get rpeEasy;

  /// No description provided for @rpeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get rpeLight;

  /// No description provided for @strengthScoreCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Strength score'**
  String get strengthScoreCardTitle;

  /// No description provided for @strengthBestLift.
  ///
  /// In en, this message translates to:
  /// **'Best lift'**
  String get strengthBestLift;

  /// No description provided for @strengthContributionToScore.
  ///
  /// In en, this message translates to:
  /// **'Contribution to score'**
  String get strengthContributionToScore;

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'Training journal'**
  String get journalTitle;

  /// No description provided for @journalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search workouts, food, photos…'**
  String get journalSearchHint;

  /// No description provided for @journalEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your journal is empty. Log a workout to start your timeline.'**
  String get journalEmpty;

  /// No description provided for @challengeCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create challenge'**
  String get challengeCreateTitle;

  /// No description provided for @challengeCreateFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get challengeCreateFieldTitle;

  /// No description provided for @challengeCreateFieldGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get challengeCreateFieldGoal;

  /// No description provided for @challengeCreateFieldEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get challengeCreateFieldEnds;

  /// No description provided for @challengeCreateInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get challengeCreateInviteFriends;

  /// No description provided for @challengePublicToggle.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get challengePublicToggle;

  /// No description provided for @challengeCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create challenge'**
  String get challengeCreateButton;

  /// No description provided for @rtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Return to play'**
  String get rtpTitle;

  /// No description provided for @rtpDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Self-guided framework. Clearance from a healthcare provider is required before progressing each phase.'**
  String get rtpDisclaimer;

  /// No description provided for @rtpAdvancePhase.
  ///
  /// In en, this message translates to:
  /// **'I\'ve met the milestones'**
  String get rtpAdvancePhase;

  /// No description provided for @rtpGraduated.
  ///
  /// In en, this message translates to:
  /// **'Graduated'**
  String get rtpGraduated;

  /// No description provided for @morningRecoveryNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Take it easy today'**
  String get morningRecoveryNudgeTitle;

  /// No description provided for @morningRecoveryNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'Readiness is low. Reducing today\'s volume — open the app to regenerate.'**
  String get morningRecoveryNudgeBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'cs',
    'de',
    'en',
    'es',
    'fi',
    'fr',
    'ha',
    'hi',
    'id',
    'it',
    'ja',
    'jv',
    'kn',
    'ko',
    'ml',
    'mr',
    'ms',
    'ne',
    'nl',
    'or',
    'pa',
    'pl',
    'pt',
    'ru',
    'sv',
    'sw',
    'ta',
    'te',
    'th',
    'tl',
    'tr',
    'ur',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'ha':
      return AppLocalizationsHa();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'jv':
      return AppLocalizationsJv();
    case 'kn':
      return AppLocalizationsKn();
    case 'ko':
      return AppLocalizationsKo();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'ms':
      return AppLocalizationsMs();
    case 'ne':
      return AppLocalizationsNe();
    case 'nl':
      return AppLocalizationsNl();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'sw':
      return AppLocalizationsSw();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'th':
      return AppLocalizationsTh();
    case 'tl':
      return AppLocalizationsTl();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
