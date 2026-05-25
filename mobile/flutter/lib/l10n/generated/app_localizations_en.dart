// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Zealova';

  @override
  String get navHome => 'Home';

  @override
  String get navWorkouts => 'Workouts';

  @override
  String get navNutrition => 'Nutrition';

  @override
  String get navProgress => 'Progress';

  @override
  String get navProfile => 'Profile';

  @override
  String get buttonStart => 'Start';

  @override
  String get buttonSave => 'Save';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonDelete => 'Delete';

  @override
  String get buttonRetry => 'Retry';

  @override
  String get buttonContinue => 'Continue';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose your preferred language';

  @override
  String get equipmentCalibrationTitle => 'Calibrate equipment';

  @override
  String get equipmentCalibrationIntroTitle => 'Tell us your real gear';

  @override
  String get equipmentCalibrationIntroBody =>
      'Plate suggestions and weight prescriptions will match what you actually own. Set your bar weights, machine sled weights, cable pin increments, and plate / dumbbell inventory.';

  @override
  String get recoveryLabel => 'Recovery';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get rpeFailure => 'Failure';

  @override
  String get rpeOneRepLeft => '1 rep left';

  @override
  String get rpeTwoRepsLeft => '2 reps left';

  @override
  String get rpeEasy => 'Easy';

  @override
  String get rpeLight => 'Light';

  @override
  String get strengthScoreCardTitle => 'Strength score';

  @override
  String get strengthBestLift => 'Best lift';

  @override
  String get strengthContributionToScore => 'Contribution to score';

  @override
  String get journalTitle => 'Training journal';

  @override
  String get journalSearchHint => 'Search workouts, food, photos…';

  @override
  String get journalEmpty =>
      'Your journal is empty. Log a workout to start your timeline.';

  @override
  String get challengeCreateTitle => 'Create challenge';

  @override
  String get challengeCreateFieldTitle => 'Title';

  @override
  String get challengeCreateFieldGoal => 'Goal';

  @override
  String get challengeCreateFieldEnds => 'Ends';

  @override
  String get challengeCreateInviteFriends => 'Invite friends';

  @override
  String get challengePublicToggle => 'Public';

  @override
  String get challengeCreateButton => 'Create challenge';

  @override
  String get rtpTitle => 'Return to play';

  @override
  String get rtpDisclaimer =>
      'Self-guided framework. Clearance from a healthcare provider is required before progressing each phase.';

  @override
  String get rtpAdvancePhase => 'I\'ve met the milestones';

  @override
  String get rtpGraduated => 'Graduated';

  @override
  String get morningRecoveryNudgeTitle => 'Take it easy today';

  @override
  String get morningRecoveryNudgeBody =>
      'Readiness is low. Reducing today\'s volume — open the app to regenerate.';
}
