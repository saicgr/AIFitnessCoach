// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Zealova';

  @override
  String get navHome => 'Главная';

  @override
  String get navWorkouts => 'Тренировки';

  @override
  String get navNutrition => 'Питание';

  @override
  String get navProgress => 'Прогресс';

  @override
  String get navProfile => 'Профиль';

  @override
  String get buttonStart => 'Старт';

  @override
  String get buttonSave => 'Сохранить';

  @override
  String get buttonCancel => 'Отмена';

  @override
  String get buttonDelete => 'Удалить';

  @override
  String get buttonRetry => 'Повторить';

  @override
  String get buttonContinue => 'Продолжить';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSubtitle => 'Выберите предпочитаемый язык';

  @override
  String get equipmentCalibrationTitle => 'Калибровка оборудования';

  @override
  String get equipmentCalibrationIntroTitle =>
      'Расскажите о вашем реальном инвентаре';

  @override
  String get equipmentCalibrationIntroBody =>
      'Подсказки по блинам и рекомендации веса будут соответствовать тому, что у вас есть. Установите вес грифа, вес каретки тренажёра, шаг штифта блочного тренажёра и инвентарь блинов / гантелей.';

  @override
  String get recoveryLabel => 'Восстановление';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get rpeFailure => 'Отказ';

  @override
  String get rpeOneRepLeft => 'Остался 1 повтор';

  @override
  String get rpeTwoRepsLeft => 'Осталось 2 повтора';

  @override
  String get rpeEasy => 'Легко';

  @override
  String get rpeLight => 'Очень легко';

  @override
  String get strengthScoreCardTitle => 'Балл силы';

  @override
  String get strengthBestLift => 'Лучшее упражнение';

  @override
  String get strengthContributionToScore => 'Вклад в балл';

  @override
  String get journalTitle => 'Дневник тренировок';

  @override
  String get journalSearchHint => 'Поиск тренировок, еды, фото…';

  @override
  String get journalEmpty =>
      'Дневник пуст. Запишите тренировку, чтобы начать ленту.';

  @override
  String get challengeCreateTitle => 'Создать челлендж';

  @override
  String get challengeCreateFieldTitle => 'Название';

  @override
  String get challengeCreateFieldGoal => 'Цель';

  @override
  String get challengeCreateFieldEnds => 'Окончание';

  @override
  String get challengeCreateInviteFriends => 'Пригласить друзей';

  @override
  String get challengePublicToggle => 'Публично';

  @override
  String get challengeCreateButton => 'Создать челлендж';

  @override
  String get rtpTitle => 'Возвращение к нагрузке';

  @override
  String get rtpDisclaimer =>
      'Самостоятельная программа. Перед переходом на каждую фазу требуется одобрение врача.';

  @override
  String get rtpAdvancePhase => 'Достиг(ла) ориентиров';

  @override
  String get rtpGraduated => 'Завершено';

  @override
  String get morningRecoveryNudgeTitle => 'Сегодня — спокойно';

  @override
  String get morningRecoveryNudgeBody =>
      'Готовность сегодня низкая. Снижаем объём — откройте приложение для перегенерации.';
}
