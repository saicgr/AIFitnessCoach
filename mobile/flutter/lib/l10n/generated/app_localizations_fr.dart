// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Zealova';

  @override
  String get navHome => 'Accueil';

  @override
  String get navWorkouts => 'Séances';

  @override
  String get navNutrition => 'Nutrition';

  @override
  String get navProgress => 'Progression';

  @override
  String get navProfile => 'Profil';

  @override
  String get buttonStart => 'Démarrer';

  @override
  String get buttonSave => 'Enregistrer';

  @override
  String get buttonCancel => 'Annuler';

  @override
  String get buttonDelete => 'Supprimer';

  @override
  String get buttonRetry => 'Réessayer';

  @override
  String get buttonContinue => 'Continuer';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSubtitle => 'Choisis ta langue préférée';

  @override
  String get equipmentCalibrationTitle => 'Calibrer l\'équipement';

  @override
  String get equipmentCalibrationIntroTitle =>
      'Parle-nous de ton matériel réel';

  @override
  String get equipmentCalibrationIntroBody =>
      'Les suggestions de disques et les charges correspondront à ce que tu possèdes vraiment. Règle le poids des barres, le poids du chariot, les incréments de poulie et l\'inventaire des disques et haltères.';

  @override
  String get recoveryLabel => 'Récupération';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get rpeFailure => 'Échec';

  @override
  String get rpeOneRepLeft => '1 rép restante';

  @override
  String get rpeTwoRepsLeft => '2 rép restantes';

  @override
  String get rpeEasy => 'Facile';

  @override
  String get rpeLight => 'Léger';

  @override
  String get strengthScoreCardTitle => 'Score de force';

  @override
  String get strengthBestLift => 'Meilleur soulevé';

  @override
  String get strengthContributionToScore => 'Contribution au score';

  @override
  String get journalTitle => 'Journal d\'entraînement';

  @override
  String get journalSearchHint => 'Cherche séances, repas, photos…';

  @override
  String get journalEmpty =>
      'Ton journal est vide. Enregistre une séance pour commencer.';

  @override
  String get challengeCreateTitle => 'Créer un défi';

  @override
  String get challengeCreateFieldTitle => 'Titre';

  @override
  String get challengeCreateFieldGoal => 'Objectif';

  @override
  String get challengeCreateFieldEnds => 'Termine le';

  @override
  String get challengeCreateInviteFriends => 'Inviter des amis';

  @override
  String get challengePublicToggle => 'Public';

  @override
  String get challengeCreateButton => 'Lancer le défi';

  @override
  String get rtpTitle => 'Retour à l\'entraînement';

  @override
  String get rtpDisclaimer =>
      'Cadre auto-guidé. L\'autorisation d\'un professionnel de santé est requise avant chaque progression de phase.';

  @override
  String get rtpAdvancePhase => 'J\'ai atteint les jalons';

  @override
  String get rtpGraduated => 'Terminé';

  @override
  String get morningRecoveryNudgeTitle => 'Vas-y doucement aujourd\'hui';

  @override
  String get morningRecoveryNudgeBody =>
      'Ta récupération est basse. On réduit le volume du jour — ouvre l\'app pour régénérer.';
}
