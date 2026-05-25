// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Zealova';

  @override
  String get navHome => '首页';

  @override
  String get navWorkouts => '训练';

  @override
  String get navNutrition => '营养';

  @override
  String get navProgress => '进度';

  @override
  String get navProfile => '个人';

  @override
  String get buttonStart => '开始';

  @override
  String get buttonSave => '保存';

  @override
  String get buttonCancel => '取消';

  @override
  String get buttonDelete => '删除';

  @override
  String get buttonRetry => '重试';

  @override
  String get buttonContinue => '继续';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSubtitle => '选择您的首选语言';

  @override
  String get equipmentCalibrationTitle => '校准器材';

  @override
  String get equipmentCalibrationIntroTitle => '告诉我们您的真实器材';

  @override
  String get equipmentCalibrationIntroBody =>
      '杠片建议和重量推荐将匹配您实际拥有的器材。设置杠铃重量、器械底盘重量、绳索机重量步进,以及杠片/哑铃库存。';

  @override
  String get recoveryLabel => '恢复';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get rpeFailure => '力竭';

  @override
  String get rpeOneRepLeft => '还剩1次';

  @override
  String get rpeTwoRepsLeft => '还剩2次';

  @override
  String get rpeEasy => '轻松';

  @override
  String get rpeLight => '很轻';

  @override
  String get strengthScoreCardTitle => '力量评分';

  @override
  String get strengthBestLift => '最佳动作';

  @override
  String get strengthContributionToScore => '对评分的贡献';

  @override
  String get journalTitle => '训练日志';

  @override
  String get journalSearchHint => '搜索训练、餐食、照片…';

  @override
  String get journalEmpty => '日志为空。记录一次训练以开启时间线。';

  @override
  String get challengeCreateTitle => '创建挑战';

  @override
  String get challengeCreateFieldTitle => '标题';

  @override
  String get challengeCreateFieldGoal => '目标';

  @override
  String get challengeCreateFieldEnds => '结束';

  @override
  String get challengeCreateInviteFriends => '邀请好友';

  @override
  String get challengePublicToggle => '公开';

  @override
  String get challengeCreateButton => '创建挑战';

  @override
  String get rtpTitle => '重返训练';

  @override
  String get rtpDisclaimer => '自助框架。进入下一阶段前需获得医疗服务提供者的许可。';

  @override
  String get rtpAdvancePhase => '我已达到里程碑';

  @override
  String get rtpGraduated => '已完成';

  @override
  String get morningRecoveryNudgeTitle => '今天放轻松';

  @override
  String get morningRecoveryNudgeBody => '今日恢复值偏低。我们将减少训练量——打开应用以重新生成。';
}
