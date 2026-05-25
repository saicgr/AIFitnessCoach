// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Zealova';

  @override
  String get navHome => 'ホーム';

  @override
  String get navWorkouts => 'ワークアウト';

  @override
  String get navNutrition => '栄養';

  @override
  String get navProgress => '進捗';

  @override
  String get navProfile => 'プロフィール';

  @override
  String get buttonStart => '開始';

  @override
  String get buttonSave => '保存';

  @override
  String get buttonCancel => 'キャンセル';

  @override
  String get buttonDelete => '削除';

  @override
  String get buttonRetry => '再試行';

  @override
  String get buttonContinue => '続ける';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageSubtitle => '希望の言語を選択してください';

  @override
  String get equipmentCalibrationTitle => '器具のキャリブレーション';

  @override
  String get equipmentCalibrationIntroTitle => '実際の器具を教えてください';

  @override
  String get equipmentCalibrationIntroBody =>
      'プレート提案と重量推奨は、あなたが実際に持っているものに合わせます。バーの重さ、マシンのソリ重量、ケーブルピンの増分、プレート/ダンベル在庫を設定してください。';

  @override
  String get recoveryLabel => '回復';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get rpeFailure => '限界';

  @override
  String get rpeOneRepLeft => 'あと1レップ';

  @override
  String get rpeTwoRepsLeft => 'あと2レップ';

  @override
  String get rpeEasy => '楽';

  @override
  String get rpeLight => '軽い';

  @override
  String get strengthScoreCardTitle => '筋力スコア';

  @override
  String get strengthBestLift => 'ベストリフト';

  @override
  String get strengthContributionToScore => 'スコアへの寄与';

  @override
  String get journalTitle => 'トレーニング日誌';

  @override
  String get journalSearchHint => 'ワークアウト、食事、写真を検索…';

  @override
  String get journalEmpty => '日誌は空です。タイムラインを始めるためワークアウトを記録してください。';

  @override
  String get challengeCreateTitle => 'チャレンジを作成';

  @override
  String get challengeCreateFieldTitle => 'タイトル';

  @override
  String get challengeCreateFieldGoal => '目標';

  @override
  String get challengeCreateFieldEnds => '終了日';

  @override
  String get challengeCreateInviteFriends => '友達を招待';

  @override
  String get challengePublicToggle => '公開';

  @override
  String get challengeCreateButton => 'チャレンジ作成';

  @override
  String get rtpTitle => '競技復帰';

  @override
  String get rtpDisclaimer => 'セルフガイド型のフレームワーク。各フェーズに進む前に医療提供者の許可が必要です。';

  @override
  String get rtpAdvancePhase => 'マイルストーンを達成';

  @override
  String get rtpGraduated => '完了';

  @override
  String get morningRecoveryNudgeTitle => '今日は無理をしないで';

  @override
  String get morningRecoveryNudgeBody =>
      '今日のレディネスが低いです。ボリュームを下げます——アプリを開いて再生成してください。';
}
