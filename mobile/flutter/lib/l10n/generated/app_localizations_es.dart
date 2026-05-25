// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Zealova';

  @override
  String get navHome => 'Inicio';

  @override
  String get navWorkouts => 'Entrenamientos';

  @override
  String get navNutrition => 'Nutrición';

  @override
  String get navProgress => 'Progreso';

  @override
  String get navProfile => 'Perfil';

  @override
  String get buttonStart => 'Empezar';

  @override
  String get buttonSave => 'Guardar';

  @override
  String get buttonCancel => 'Cancelar';

  @override
  String get buttonDelete => 'Eliminar';

  @override
  String get buttonRetry => 'Reintentar';

  @override
  String get buttonContinue => 'Continuar';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Elige tu idioma preferido';

  @override
  String get equipmentCalibrationTitle => 'Calibrar equipo';

  @override
  String get equipmentCalibrationIntroTitle => 'Cuéntanos tu material real';

  @override
  String get equipmentCalibrationIntroBody =>
      'Las sugerencias de discos y las prescripciones de peso coincidirán con lo que realmente posees. Configura el peso de tus barras, el peso del trineo de la máquina, los incrementos del pin del cable y el inventario de discos y mancuernas.';

  @override
  String get recoveryLabel => 'Recuperación';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get rpeFailure => 'Fallo';

  @override
  String get rpeOneRepLeft => 'Queda 1 repetición';

  @override
  String get rpeTwoRepsLeft => 'Quedan 2 repeticiones';

  @override
  String get rpeEasy => 'Fácil';

  @override
  String get rpeLight => 'Ligero';

  @override
  String get strengthScoreCardTitle => 'Puntuación de fuerza';

  @override
  String get strengthBestLift => 'Mejor levantamiento';

  @override
  String get strengthContributionToScore => 'Contribución a la puntuación';

  @override
  String get journalTitle => 'Diario de entrenamiento';

  @override
  String get journalSearchHint => 'Busca entrenamientos, comida, fotos…';

  @override
  String get journalEmpty =>
      'Tu diario está vacío. Registra un entrenamiento para empezar.';

  @override
  String get challengeCreateTitle => 'Crear reto';

  @override
  String get challengeCreateFieldTitle => 'Título';

  @override
  String get challengeCreateFieldGoal => 'Objetivo';

  @override
  String get challengeCreateFieldEnds => 'Termina';

  @override
  String get challengeCreateInviteFriends => 'Invitar amigos';

  @override
  String get challengePublicToggle => 'Público';

  @override
  String get challengeCreateButton => 'Crear reto';

  @override
  String get rtpTitle => 'Vuelta a la actividad';

  @override
  String get rtpDisclaimer =>
      'Marco autoguiado. Antes de avanzar de fase, se requiere autorización médica.';

  @override
  String get rtpAdvancePhase => 'He cumplido los hitos';

  @override
  String get rtpGraduated => 'Completado';

  @override
  String get morningRecoveryNudgeTitle => 'Tómatelo con calma hoy';

  @override
  String get morningRecoveryNudgeBody =>
      'Tu readiness es baja. Reduciremos el volumen de hoy — abre la app para regenerar.';
}
