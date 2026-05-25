// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Zealova';

  @override
  String get navHome => 'Home';

  @override
  String get navWorkouts => 'Allenamenti';

  @override
  String get navNutrition => 'Nutrizione';

  @override
  String get navProgress => 'Progressi';

  @override
  String get navProfile => 'Profilo';

  @override
  String get buttonStart => 'Inizia';

  @override
  String get buttonSave => 'Salva';

  @override
  String get buttonCancel => 'Annulla';

  @override
  String get buttonDelete => 'Elimina';

  @override
  String get buttonRetry => 'Riprova';

  @override
  String get buttonContinue => 'Continua';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageSubtitle => 'Scegli la tua lingua preferita';

  @override
  String get equipmentCalibrationTitle => 'Calibra attrezzatura';

  @override
  String get equipmentCalibrationIntroTitle =>
      'Dicci la tua attrezzatura reale';

  @override
  String get equipmentCalibrationIntroBody =>
      'I suggerimenti dei dischi e le indicazioni di peso saranno coerenti con ciò che possiedi. Imposta i pesi delle barre, il peso del carrello, gli incrementi dei cavi e l\'inventario di dischi e manubri.';

  @override
  String get recoveryLabel => 'Recupero';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get rpeFailure => 'Cedimento';

  @override
  String get rpeOneRepLeft => '1 rep rimasta';

  @override
  String get rpeTwoRepsLeft => '2 rep rimaste';

  @override
  String get rpeEasy => 'Facile';

  @override
  String get rpeLight => 'Leggero';

  @override
  String get strengthScoreCardTitle => 'Punteggio forza';

  @override
  String get strengthBestLift => 'Migliore alzata';

  @override
  String get strengthContributionToScore => 'Contributo al punteggio';

  @override
  String get journalTitle => 'Diario di allenamento';

  @override
  String get journalSearchHint => 'Cerca allenamenti, pasti, foto…';

  @override
  String get journalEmpty =>
      'Il tuo diario è vuoto. Registra un allenamento per iniziare.';

  @override
  String get challengeCreateTitle => 'Crea sfida';

  @override
  String get challengeCreateFieldTitle => 'Titolo';

  @override
  String get challengeCreateFieldGoal => 'Obiettivo';

  @override
  String get challengeCreateFieldEnds => 'Termina';

  @override
  String get challengeCreateInviteFriends => 'Invita amici';

  @override
  String get challengePublicToggle => 'Pubblico';

  @override
  String get challengeCreateButton => 'Crea sfida';

  @override
  String get rtpTitle => 'Ritorno all\'attività';

  @override
  String get rtpDisclaimer =>
      'Quadro autoguidato. Prima di avanzare di fase serve l\'autorizzazione di un professionista sanitario.';

  @override
  String get rtpAdvancePhase => 'Ho raggiunto i traguardi';

  @override
  String get rtpGraduated => 'Completato';

  @override
  String get morningRecoveryNudgeTitle => 'Vacci piano oggi';

  @override
  String get morningRecoveryNudgeBody =>
      'Il recupero è basso. Riduciamo il volume di oggi — apri l\'app per rigenerare.';
}
