// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get appName => 'Zealova';

  @override
  String get navHome => 'Etusivu';

  @override
  String get navWorkouts => 'Treenit';

  @override
  String get navNutrition => 'Ravinto';

  @override
  String get navProgress => 'Edistyminen';

  @override
  String get navProfile => 'Profiili';

  @override
  String get buttonStart => 'Aloita';

  @override
  String get buttonSave => 'Tallenna';

  @override
  String get buttonCancel => 'Peruuta';

  @override
  String get buttonDelete => 'Poista';

  @override
  String get buttonRetry => 'Yritä uudelleen';

  @override
  String get buttonContinue => 'Jatka';

  @override
  String get settingsTitle => 'Asetukset';

  @override
  String get settingsLanguage => 'Kieli';

  @override
  String get settingsLanguageSubtitle => 'Valitse haluamasi kieli';

  @override
  String get equipmentCalibrationTitle => 'Kalibroi varusteet';

  @override
  String get equipmentCalibrationIntroTitle => 'Kerro todelliset varusteesi';

  @override
  String get equipmentCalibrationIntroBody =>
      'Levyehdotukset ja painosuositukset vastaavat sitä, mitä todella omistat. Aseta tangon paino, laitteen kelkan paino, kaapelitappien askel ja levy- / käsipainovarasto.';

  @override
  String get recoveryLabel => 'Palautuminen';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get rpeFailure => 'Uupumus';

  @override
  String get rpeOneRepLeft => '1 toisto jäljellä';

  @override
  String get rpeTwoRepsLeft => '2 toistoa jäljellä';

  @override
  String get rpeEasy => 'Helppo';

  @override
  String get rpeLight => 'Kevyt';

  @override
  String get strengthScoreCardTitle => 'Voimapisteet';

  @override
  String get strengthBestLift => 'Paras nosto';

  @override
  String get strengthContributionToScore => 'Osuus pisteistä';

  @override
  String get journalTitle => 'Harjoituspäiväkirja';

  @override
  String get journalSearchHint => 'Etsi treenejä, ruokaa, kuvia…';

  @override
  String get journalEmpty =>
      'Päiväkirjasi on tyhjä. Kirjaa treeni aloittaaksesi aikajanan.';

  @override
  String get challengeCreateTitle => 'Luo haaste';

  @override
  String get challengeCreateFieldTitle => 'Otsikko';

  @override
  String get challengeCreateFieldGoal => 'Tavoite';

  @override
  String get challengeCreateFieldEnds => 'Päättyy';

  @override
  String get challengeCreateInviteFriends => 'Kutsu kavereita';

  @override
  String get challengePublicToggle => 'Julkinen';

  @override
  String get challengeCreateButton => 'Luo haaste';

  @override
  String get rtpTitle => 'Paluu liikuntaan';

  @override
  String get rtpDisclaimer =>
      'Itseohjautuva runko. Terveydenhuollon ammattilaisen lupa vaaditaan ennen jokaiseen vaiheeseen siirtymistä.';

  @override
  String get rtpAdvancePhase => 'Olen saavuttanut virstanpylväät';

  @override
  String get rtpGraduated => 'Valmis';

  @override
  String get morningRecoveryNudgeTitle => 'Ota tänään rauhallisesti';

  @override
  String get morningRecoveryNudgeBody =>
      'Tämän päivän valmius on matala. Vähennämme volyymia — avaa sovellus regenerointiin.';
}
