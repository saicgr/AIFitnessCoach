// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get aboutDisableBeastMode => '关闭 Beast Mode';

  @override
  String get aboutLoadingBuildInfo => '正在加载构建信息...';

  @override
  String get accessibilityAccessibility => '辅助功能';

  @override
  String get accessibilityAppMode => '应用模式';

  @override
  String get accessibilityCardAccessibility => '辅助功能';

  @override
  String get accessibilityCardBiggerTouchTargetsFor => '增大触摸区域以便点击';

  @override
  String get accessibilityCardHighContrast => '高对比度';

  @override
  String get accessibilityCardIncreaseColorContrastFor => '增加颜色对比度以提高可见性';

  @override
  String get accessibilityCardLargeButtons => '大按钮';

  @override
  String get accessibilityCardMinimizeMotionEffects => '最小化动态效果';

  @override
  String get accessibilityCardReduceAnimations => '减少动画';

  @override
  String get accessibilityCardVisualAndInteractionAdjustm => '视觉与交互调整';

  @override
  String get accessibilityCurrentMode => '当前模式';

  @override
  String get accessibilityFontSize => '字体大小';

  @override
  String get accessibilityHighContrast => '高对比度';

  @override
  String get accessibilityLargeButtons => '大按钮';

  @override
  String get accessibilityLevelUpProgression => '升级进度';

  @override
  String get accessibilityReduceAnimations => '减少动画';

  @override
  String get accessibilitySenior => '长者';

  @override
  String get accessibilityStandard => '标准';

  @override
  String get accuracyFeedbackSnackbarAccurate => '准确吗？';

  @override
  String accuracyFeedbackSnackbarCal(Object calories, Object displayName) {
    return '$displayName — $calories 卡路里';
  }

  @override
  String get achievementsBadges => '徽章';

  @override
  String get achievementsByCategory => '按类别';

  @override
  String get achievementsCardAchievements => '成就';

  @override
  String achievementsCardBadges(Object totalAchieved) {
    return '$totalAchieved 枚徽章';
  }

  @override
  String get achievementsCardCompleteWorkoutsToUnlock => '完成训练以解锁徽章！';

  @override
  String get achievementsCardLoadingAchievements => '正在加载成就...';

  @override
  String get achievementsCardNext => '下一个：';

  @override
  String get achievementsCardStartYourJourney => '开启你的旅程';

  @override
  String get achievementsCompleteWorkoutsToEarn => '完成训练以赢取成就！';

  @override
  String get achievementsCurrentStreaks => '当前连练天数';

  @override
  String get achievementsKeepWorkingOutTo => '继续训练以解锁徽章！';

  @override
  String get achievementsLiftHeavierToSet => '增加重量以刷新 PRs！';

  @override
  String get achievementsNoAchievementsYet => '暂无成就';

  @override
  String get achievementsNoBadgesEarned => '未获得徽章';

  @override
  String get achievementsNoPersonalRecords => '暂无个人纪录';

  @override
  String get achievementsPrs => 'PR';

  @override
  String get achievementsRecentAchievements => '近期成就';

  @override
  String achievementsScreenAchievementsEarned(Object totalAchievements) {
    return '已获得 $totalAchievements 项成就';
  }

  @override
  String achievementsScreenBestDays(Object longestStreak) {
    return '最佳: $longestStreak 天';
  }

  @override
  String achievementsScreenValue(Object points) {
    return '+$points';
  }

  @override
  String achievementsScreenValue2(Object record) {
    return '+$record%';
  }

  @override
  String get achievementsSeeAll => '查看全部';

  @override
  String get achievementsSummary => '摘要';

  @override
  String get achievementsTotalPoints => '总积分';

  @override
  String get achievementsUnlocked => '已解锁';

  @override
  String get actionCalibrationSavedSummary => '校准已保存';

  @override
  String get actionChipsRowAdjust => '调整';

  @override
  String get actionChipsRowIncrements => '增量';

  @override
  String get actionChipsRowInfo => '信息';

  @override
  String get actionChipsRowLR => '左/右';

  @override
  String get actionChipsRowNote => '备注';

  @override
  String get actionChipsRowReorder => '重新排序';

  @override
  String get actionChipsRowSuperset => '超级组';

  @override
  String get actionChipsRowSwap => '替换';

  @override
  String get actionChipsRowTargets => '目标';

  @override
  String get actionChipsRowTimer => '计时器';

  @override
  String get actionChipsRowVideo => '视频';

  @override
  String get actionChipsRowWarmUp => '热身';

  @override
  String get actionDarkModeToggledSummary => '深色模式已切换';

  @override
  String actionDeloadStartedSummary(Object reason) {
    return '减载期开始：$reason';
  }

  @override
  String get actionEquipmentCalibratedSummary => '设备已校准';

  @override
  String actionExerciseSwappedSummary(Object newExercise, Object oldExercise) {
    return '已将 $oldExercise 替换为 $newExercise';
  }

  @override
  String get actionFoodLoggedSummary => '饮食已记录';

  @override
  String actionHydrationLoggedSummary(Object amount) {
    return '已记录 $amount';
  }

  @override
  String actionMealScannedSummary(Object itemCount) {
    return '已扫描 $itemCount 个项目';
  }

  @override
  String actionMenuScannedSummary(Object itemCount) {
    return '已分析 $itemCount 个菜单项';
  }

  @override
  String get actionRegenerateRequestedSummary => '已请求重新生成训练';

  @override
  String actionSettingsChangedSummary(Object settingName) {
    return '$settingName 已更新';
  }

  @override
  String get actionWorkoutAddedSummary => '训练已添加';

  @override
  String get actionWorkoutRemovedSummary => '训练已移除';

  @override
  String activeFilterChipsAvoid(Object avoid) {
    return '避免: $avoid';
  }

  @override
  String get activeFilterChipsClearAll => '清除全部';

  @override
  String get activeWorkoutHelperAdvanced => '进阶';

  @override
  String get activeWorkoutHelperAutoAdjusts => '自动调整';

  @override
  String get activeWorkoutHelperBodyweight => '自重';

  @override
  String get activeWorkoutHelperBreathing => '呼吸';

  @override
  String get activeWorkoutHelperChooseHowWeightChanges => '选择各组重量的变化方式';

  @override
  String get activeWorkoutHelperDifficulty => '难度';

  @override
  String get activeWorkoutHelperDonTHaveThis => '没有这个器械？';

  @override
  String get activeWorkoutHelperEquipment => '器械';

  @override
  String get activeWorkoutHelperExerciseInfo => '动作信息';

  @override
  String get activeWorkoutHelperFormCues => '动作要点';

  @override
  String get activeWorkoutHelperLoadingAiCoachTips => '正在加载 AI 教练建议...';

  @override
  String get activeWorkoutHelperPrimaryMuscle => '主要肌群';

  @override
  String get activeWorkoutHelperProTip => '专业建议';

  @override
  String get activeWorkoutHelperSecondaryMuscles => '次要肌群';

  @override
  String get activeWorkoutHelperSetProgression => '组数进阶';

  @override
  String get activeWorkoutHelperTapVideoToWatch => '点击“视频”观看动作演示';

  @override
  String get activeWorkoutHelperVideo => '视频';

  @override
  String get activeWorkoutHelperWatchOutFor => '注意事项';

  @override
  String get activeWorkoutHelperWhenToUse => '何时使用';

  @override
  String get activeWorkoutScreenExerciseSwappedSuccessfully => '动作替换成功';

  @override
  String activeWorkoutScreenRefactoredExerciseSAdded(Object _exercises) {
    return '已添加 $_exercises 个练习';
  }

  @override
  String activeWorkoutScreenRefactoredFor(Object name) {
    return ') 用于 (name)';
  }

  @override
  String get activeWorkoutScreenUndo => '撤销';

  @override
  String get activeWorkoutScreenWorkoutAdapted => '训练已调整。';

  @override
  String get activityCardAdditionalDetailsOptional => '附加详情（可选）';

  @override
  String get activityCardAreYouSureYou => '确定要删除此动态吗？此操作无法撤销。';

  @override
  String get activityCardCopyLink => '复制链接';

  @override
  String get activityCardDeletePost => '删除动态';

  @override
  String get activityCardEditPost => '编辑动态';

  @override
  String get activityCardFailedToSubmitReport => '提交报告失败。请重试。';

  @override
  String get activityCardLinkCopiedToClipboard => '链接已复制到剪贴板';

  @override
  String activityCardPartChallengeLeaderboardM(Object duration) {
    return '$duration分钟';
  }

  @override
  String get activityCardPartLeaderboard => '排行榜';

  @override
  String get activityCardPinToTop => '置顶';

  @override
  String get activityCardPinnedPost => '置顶帖';

  @override
  String get activityCardReport => '举报';

  @override
  String get activityCardReportPost => '举报帖子';

  @override
  String get activityCardReportSubmittedThankYou => '报告已提交。感谢您为维护社区安全所做的贡献。';

  @override
  String get activityCardSubmit => '提交';

  @override
  String get activityCardUiChallengeAttempted => '已参与挑战';

  @override
  String get activityCardUiEarnedAnAchievement => '获得了一项成就';

  @override
  String get activityCardUiKeepTrainingEveryAttempt => '继续训练！每一次尝试都让你变得更强';

  @override
  String activityCardUiLbs(Object yourVolume) {
    return '$yourVolume 磅';
  }

  @override
  String activityCardUiLbs2(Object theirVolume) {
    return '$theirVolume 磅';
  }

  @override
  String activityCardUiLbs3(Object volumeDifference) {
    return '+$volumeDifference 磅';
  }

  @override
  String activityCardUiMin(Object yourDuration) {
    return '$yourDuration 分钟';
  }

  @override
  String activityCardUiMin2(Object theirDuration) {
    return '$theirDuration 分钟';
  }

  @override
  String activityCardUiMinFaster(Object timeDifference) {
    return '快 $timeDifference 分钟';
  }

  @override
  String get activityCardUiTarget => '目标：';

  @override
  String get activityCardUiThem => '对方';

  @override
  String get activityCardUiTime => '时间';

  @override
  String get activityCardUiVictory => '胜利！';

  @override
  String get activityCardUiVolume => '容量';

  @override
  String get activityCardUiYou => '你：';

  @override
  String get activityCardUnpinPost => '取消置顶';

  @override
  String get activityCardWhyAreYouReporting => '你为什么要举报此帖？';

  @override
  String get activityHeatmapActivity => '活动';

  @override
  String get activityHeatmapFailedToLoadActivity => '加载活动失败';

  @override
  String get activityHeatmapMissed => '错过';

  @override
  String get activityHeatmapRest => '休息';

  @override
  String get activityHeatmapSearchExercise => '搜索练习...';

  @override
  String activityHeatmapTimes(Object timesPerformed) {
    return '$timesPerformed次';
  }

  @override
  String get activityShareAddACaption => '添加说明...';

  @override
  String get activityShareCardConsistencyIsKey => '坚持是关键';

  @override
  String activityShareCardLbs(Object absValue) {
    return '$absValue lbs';
  }

  @override
  String get activityShareCardSharedAnUpdate => '分享了更新';

  @override
  String activityShareCardValue(Object userName) {
    return '@$userName';
  }

  @override
  String get activityShareCopyText => '复制文本';

  @override
  String get activityShareInstagram => 'Instagram';

  @override
  String get activityShareSaveImage => '保存图片';

  @override
  String get activityShareSharePost => '分享帖子';

  @override
  String get activityShareShowWatermark => '显示水印';

  @override
  String get activityShareTapToAddA => '点击添加说明...';

  @override
  String get addFoodEGMadeWith => '例如：“用橄榄油制作，无全谷物”或“我只吃了一半”';

  @override
  String get addFoodRefineWithAi => '使用AI优化';

  @override
  String get addGymProfileAccountDefault => '账户默认';

  @override
  String get addGymProfileAddNewGym => '添加新健身房';

  @override
  String get addGymProfileAvailableEquipment => '可用器械';

  @override
  String get addGymProfileClear => '清除';

  @override
  String get addGymProfileColor => '颜色';

  @override
  String get addGymProfileCreateGym => '创建健身房';

  @override
  String get addGymProfileCustomizeTheEquipmentAvaila => '自定义此健身房的可用器械，包括重量范围';

  @override
  String get addGymProfileDoYouHaveA => '你有卧推凳吗？';

  @override
  String get addGymProfileDoYouHaveA2 => '你有深蹲架吗？';

  @override
  String get addGymProfileEGHomeGym => '例如：家庭健身房、Planet Fitness、酒店';

  @override
  String get addGymProfileEnterANameFor => '请先输入健身房名称（第1步）。';

  @override
  String get addGymProfileEquipment => '器械';

  @override
  String get addGymProfileGymName => '健身房名称';

  @override
  String get addGymProfileIcon => '图标';

  @override
  String get addGymProfileImportFromPdfPhoto => '从PDF、照片或URL导入';

  @override
  String get addGymProfileMatchAppTheme => '匹配应用主题';

  @override
  String get addGymProfileOptionalLeaveOnLet => '可选——如果不确定，请保留为“让AI决定”。';

  @override
  String get addGymProfilePickAtLeastOne => '为此健身房至少选择一个训练日。';

  @override
  String get addGymProfilePleaseEnterAName => '请输入健身房名称';

  @override
  String get addGymProfileRequiredForBarbellSquat => '适用于：杠铃深蹲、过顶推举、杠铃卧推';

  @override
  String get addGymProfileResetAll => '全部重置';

  @override
  String addGymProfileSheetCouldNotSaveProfile(Object e) {
    return '导入前无法保存个人资料：$e';
  }

  @override
  String addGymProfileSheetExtSelectedEquipment(Object length) {
    return '已选器械 ($length)';
  }

  @override
  String addGymProfileSheetPartEquipmentFollowUpValue(Object currentColor) {
    return '#$currentColor';
  }

  @override
  String get addGymProfileTapToAddRemove => '点击以添加、删除或编辑重量';

  @override
  String get addGymProfileThisHelpsUsSuggest => '这有助于我们建议合适的器械';

  @override
  String get addGymProfileTrainingSplit => '训练计划';

  @override
  String get addGymProfileUnlocksBenchPressIncline =>
      '解锁：卧推、上斜推举、仰卧屈臂上拉、胸部支撑划船';

  @override
  String get addGymProfileUnlocksChestSupportedKb => '解锁：胸部支撑壶铃划船、壶铃地板推举替代动作';

  @override
  String get addGymProfileWorkoutEnvironment => '训练环境';

  @override
  String get addGymProfileWorkoutSchedule => '训练日程';

  @override
  String get addGymProfileYesAddIt => '是的，添加它';

  @override
  String get addGymSheetAddNewGym => '添加新健身房';

  @override
  String addGymSheetAlsoAt(Object names) {
    return '同时也在：$names';
  }

  @override
  String get addGymSheetBack => '返回';

  @override
  String get addGymSheetCommercialGym => '商业健身房';

  @override
  String get addGymSheetCommercialGymDesc => '可使用所有器械和设备';

  @override
  String addGymSheetConflictDay(Object day, Object names) {
    return '$day 也在“$names”';
  }

  @override
  String addGymSheetConflictMessage(Object details) {
    return '日程冲突：$details。当天处于激活状态的配置将负责该训练。';
  }

  @override
  String get addGymSheetCreateGym => '创建健身房';

  @override
  String addGymSheetCreatedProfile(Object name) {
    return '✓ 已创建“$name”健身房配置';
  }

  @override
  String get addGymSheetCurrent => '当前';

  @override
  String get addGymSheetEnterGymName => '请输入健身房名称';

  @override
  String get addGymSheetEnterNameFirst => '请先输入健身房名称';

  @override
  String get addGymSheetEquipment => '器械';

  @override
  String addGymSheetEquipmentCount(Object count) {
    return '$count 件器械';
  }

  @override
  String addGymSheetEquipmentSelected(Object count) {
    return '已选 $count 件器械';
  }

  @override
  String addGymSheetFailedToCreate(Object error) {
    return '创建配置失败：$error';
  }

  @override
  String get addGymSheetFollowUpBenchSubtitle => '解锁：卧推、上斜推举、仰卧上拉、胸部支撑划船';

  @override
  String get addGymSheetFollowUpBenchTitle => '你有健身椅吗？';

  @override
  String get addGymSheetFollowUpSquatRackSubtitle => '以下动作必需：杠铃深蹲、过顶推举、杠铃卧推';

  @override
  String get addGymSheetFollowUpSquatRackTitle => '你有深蹲架吗？';

  @override
  String get addGymSheetGymNameHint => '例如：家庭健身房、Planet Fitness、酒店';

  @override
  String get addGymSheetHelpsUsSuggest => '这有助于我们推荐合适的器械';

  @override
  String get addGymSheetHomeGym => '家庭健身房';

  @override
  String get addGymSheetHomeGymDesc => '拥有专属器械的健身空间';

  @override
  String get addGymSheetHomeMinimal => '居家（极简）';

  @override
  String get addGymSheetHomeMinimalDesc => '仅限自重训练';

  @override
  String get addGymSheetHotelTravel => '酒店/旅行';

  @override
  String get addGymSheetHotelTravelDesc => '旅行期间空间和器械有限';

  @override
  String addGymSheetItems(Object count) {
    return '$count 项';
  }

  @override
  String get addGymSheetNext => '下一步';

  @override
  String get addGymSheetOutdoors => '户外';

  @override
  String get addGymSheetOutdoorsDesc => '公园、户外健身区和开阔空间';

  @override
  String get addGymSheetPickAtLeastOneDay => '请至少选择一个训练日';

  @override
  String get addGymSheetPickDaysDesc =>
      '选择你在此健身房的训练日期。当你切换到此配置时，我们将为你预生成 14 天的训练计划。';

  @override
  String addGymSheetSameAs(Object name) {
    return '与 $name 相同';
  }

  @override
  String get addGymSheetSkip => '跳过';

  @override
  String get addGymSheetSplitBodyPart => '部位分化';

  @override
  String get addGymSheetSplitDesc3Days => '3 天';

  @override
  String get addGymSheetSplitDesc4Days => '4 天';

  @override
  String get addGymSheetSplitDesc56Days => '5-6 天';

  @override
  String get addGymSheetSplitDesc6Days => '6 天';

  @override
  String get addGymSheetSplitDescFlexible => '灵活';

  @override
  String get addGymSheetSplitFullBody => '全身训练';

  @override
  String get addGymSheetSplitLetAiDecide => '让 AI 决定';

  @override
  String get addGymSheetSplitPhul => 'PHUL';

  @override
  String get addGymSheetSplitPushPullLegs => '推/拉/腿';

  @override
  String get addGymSheetSplitUpperLower => '上下肢分化';

  @override
  String addGymSheetStepOf(Object step, Object total) {
    return '第 $step 步，共 $total 步';
  }

  @override
  String get addGymSheetWorkoutEnvironment => '训练环境';

  @override
  String get addGymSheetYesAddIt => '是的，添加';

  @override
  String get addScheduleItemAddToGoogleCalendar => '添加到Google Calendar';

  @override
  String get addScheduleItemAddToSchedule => '添加到日程';

  @override
  String get addScheduleItemEditItem => '编辑项目';

  @override
  String get addScheduleItemSaveChanges => '保存更改';

  @override
  String get advancedAudioCountdownRestTimerVoice => '倒计时、休息计时器、语音播报';

  @override
  String get advancedAudioSoundEffectsWorkoutAudio => '音效与训练音频';

  @override
  String get agentInfoHeaderConnectedToSupport => '已连接到客服';

  @override
  String get agentInfoHeaderOffline => '离线';

  @override
  String get agentInfoHeaderOnline => '在线';

  @override
  String agentInfoHeaderSupportAgent(Object appName) {
    return '$appName支持专员';
  }

  @override
  String get agentInfoHeaderTyping => '正在输入';

  @override
  String get aiCoachAdvancedSettings => '高级设置';

  @override
  String get aiCoachAiPersonalizedMessages => 'AI个性化消息';

  @override
  String get aiCoachBalanced => '平衡';

  @override
  String get aiCoachCelebrateStreakMilestones => '庆祝连续打卡里程碑';

  @override
  String get aiCoachCoachNotifications => '教练通知';

  @override
  String get aiCoachCoachVoicePersonality => '教练语音与个性';

  @override
  String get aiCoachEveningCheckInFor => '习惯晚间打卡';

  @override
  String get aiCoachFloatingAiChatBubble => '悬浮 AI 聊天气泡';

  @override
  String get aiCoachGentle => '温和';

  @override
  String get aiCoachGetNotifiedWhenYour => '当你的补给箱准备好时接收通知';

  @override
  String get aiCoachHabitReminders => '习惯提醒';

  @override
  String get aiCoachHowMuchYourAi => 'AI 教练对你的督促程度';

  @override
  String get aiCoachMatchYourCoachS => '匹配你的教练个性';

  @override
  String get aiCoachMealAnalyzingYourDay => '正在分析你的一天…';

  @override
  String get aiCoachMealAngryWhatToEat => '生气了 — 吃什么好？';

  @override
  String get aiCoachMealAnxiousCalmingPick => '焦虑 — 有什么安抚食物？';

  @override
  String get aiCoachMealAnythingHealthy => '任何健康食物';

  @override
  String get aiCoachMealAsian => '亚洲风味';

  @override
  String get aiCoachMealAsianInspiredPick => '亚洲风味推荐？';

  @override
  String get aiCoachMealAskTheCoach => '询问教练';

  @override
  String get aiCoachMealBalanceMyMacros => '平衡我的宏量营养素？';

  @override
  String get aiCoachMealBloatedWhatNow => '腹胀 — 现在怎么办？';

  @override
  String get aiCoachMealBoredEatingWhatInstead => '无聊进食 — 换成什么好？';

  @override
  String get aiCoachMealBudgetFriendlyMeal => '经济实惠的餐点？';

  @override
  String get aiCoachMealBulkingCalorieDensePick => '增肌期高热量推荐？';

  @override
  String get aiCoachMealCoachNeedsAConnection => '教练需要网络连接。';

  @override
  String get aiCoachMealComfortFoodSmartVersion => '舒适食物，智能版本？';

  @override
  String get aiCoachMealCravingSugarSmartSwap => '渴望糖分 — 智能替代方案？';

  @override
  String get aiCoachMealCuttingFriendlyMeal => '减脂期友好餐点？';

  @override
  String get aiCoachMealFastFood => '快餐';

  @override
  String get aiCoachMealFastFoodPick => '快餐推荐？';

  @override
  String get aiCoachMealFastingFriendlyPick => '轻断食友好推荐？';

  @override
  String get aiCoachMealFavoriteIMissed => '我错过的最爱？';

  @override
  String get aiCoachMealHeadacheFoodFix => '头痛 — 有什么饮食缓解方案？';

  @override
  String get aiCoachMealHeartburnSafePick => '胃灼热安全推荐？';

  @override
  String get aiCoachMealHighProtein => '高蛋白';

  @override
  String get aiCoachMealHighProteinIdea => '高蛋白点子？';

  @override
  String get aiCoachMealHitMyCalorieTarget => '达到我的热量目标？';

  @override
  String get aiCoachMealHydrationCheck => '补水检查？';

  @override
  String get aiCoachMealIndian => '印度风味';

  @override
  String get aiCoachMealItalianComfort => '意式 / 舒适食物';

  @override
  String get aiCoachMealLateNightSnack => '深夜零食？';

  @override
  String get aiCoachMealLogThisMeal => '记录此餐';

  @override
  String get aiCoachMealLookingAtTodayS => '正在查看今天的饮食、训练和最爱项目…';

  @override
  String get aiCoachMealLowCalSwap => '低卡替代方案？';

  @override
  String get aiCoachMealLowSugarOption => '低糖选项？';

  @override
  String get aiCoachMealMaintenanceSteadyPick => '维持期稳健推荐？';

  @override
  String get aiCoachMealMediterranean => '地中海风味';

  @override
  String get aiCoachMealMediterraneanOption => '地中海风味选项？';

  @override
  String get aiCoachMealMexican => '墨西哥风味';

  @override
  String get aiCoachMealMexicanWithGoodMacros => '宏量营养素优秀的墨西哥餐？';

  @override
  String get aiCoachMealNeedMoreFiber => '需要更多纤维？';

  @override
  String get aiCoachMealNoCook5Min => '无需烹饪 / 5分钟';

  @override
  String get aiCoachMealNoCookOption => '无需烹饪选项？';

  @override
  String get aiCoachMealOpenFullChat => '打开完整聊天';

  @override
  String get aiCoachMealPoorSleepLastNight => '昨晚睡眠不佳？';

  @override
  String get aiCoachMealPostWorkoutMeal => '训练后餐点？';

  @override
  String get aiCoachMealPreWorkoutFuel => '训练前补给？';

  @override
  String get aiCoachMealQuickSnackIdeas => '快速零食点子？';

  @override
  String get aiCoachMealRecoveryDayEating => '恢复日饮食？';

  @override
  String get aiCoachMealSearchQuestionsTryAngry => '搜索问题（尝试“生气”、“纤维”、“墨西哥”）';

  @override
  String get aiCoachMealSomethingWentWrong => '出错了。';

  @override
  String get aiCoachMealStressedWhatHelps => '压力大 — 什么有帮助？';

  @override
  String aiCoachMealSuggestionSheetAsianInspiredOnePick(
    Object budgetTail,
    Object meal,
  ) {
    return '亚洲风味 $meal ——一个选择（盖饭、面条、寿司、炒菜），宏量营养素及准备建议。$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetAsianInspiredThatS(Object meal) {
    return '推荐一个高蛋白且符合宏量营养素目标的亚洲风味 $meal。附带宏量营养素。';
  }

  @override
  String aiCoachMealSuggestionSheetBulkingCalorieDenseThat(Object meal) {
    return '增肌期——推荐一个热量密度高且吃起来不费劲的 $meal 方案。附带宏量营养素。';
  }

  @override
  String aiCoachMealSuggestionSheetComfortFoodCravingBut(Object meal) {
    return '想吃慰藉食物但又想保持计划。推荐一个经典的智能版 $meal。附带宏量营养素。';
  }

  @override
  String aiCoachMealSuggestionSheetCravingFastFoodFor(Object meal) {
    return '想吃 $meal 快餐。从常见的美国连锁店中选出一个真实单品 ';
  }

  @override
  String aiCoachMealSuggestionSheetCravingMexicanPickThat(Object meal) {
    return '想吃墨西哥菜。推荐一个符合我宏量营养素目标的 $meal 选择（不仅仅是米饭和玉米饼）。附带宏量营养素。';
  }

  @override
  String aiCoachMealSuggestionSheetDropALowCal(Object meal) {
    return '推荐一个低热量的 $meal 替代方案，同时满足我的宏量营养素需求。保持简洁，并附上宏量营养素数据。';
  }

  @override
  String aiCoachMealSuggestionSheetFastingFriendlyIdeaThat(Object meal) {
    return '推荐一个适合断食的 $meal 方案，且不会引起血糖剧烈波动。给出一个选择，附带宏量营养素及推荐理由。';
  }

  @override
  String aiCoachMealSuggestionSheetFeelingAnxiousPickWith(Object meal) {
    return '感到焦虑——推荐一个含有镇静营养素（如镁、Omega-3 等）的 $meal 选择？附带宏量营养素及理由。';
  }

  @override
  String aiCoachMealSuggestionSheetFeelingStressedAndReaching(Object meal) {
    return '感到压力大想吃东西。给我一个能真正缓解压力而非仅仅补充糖分的 $meal 选择。附带宏量营养素。';
  }

  @override
  String aiCoachMealSuggestionSheetGotALaterToday(
    Object meal,
    Object workoutType,
  ) {
    return '今天晚些时候有 $workoutType 训练。有什么适合作为练前餐的 $meal 吗？请提供宏量营养素和进食时间建议。';
  }

  @override
  String aiCoachMealSuggestionSheetHeadacheComingOnAny(Object meal) {
    return '头痛要发作了。有什么 $meal 或补水建议能缓解吗？如果没有直接关联请跳过。';
  }

  @override
  String aiCoachMealSuggestionSheetHeartburnProneTodaySafe(Object meal) {
    return '今天容易胃灼热。推荐一个安全的 $meal 选择——说明吃什么和避开什么。附带宏量营养素。';
  }

  @override
  String aiCoachMealSuggestionSheetHighProteinPickOne(
    Object budgetTail,
    Object meal,
  ) {
    return '高蛋白 $meal 选择。一个单品，完整宏量营养素，简短准备建议。$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetHowAmITracking(Object meal) {
    return '我今天的热量摄入目标完成得如何？如果还没达标，什么 $meal 可以补齐差距？';
  }

  @override
  String aiCoachMealSuggestionSheetIMAngryAnd(Object meal) {
    return '我很生气，想通过进食来缓解。给我一个不会破坏宏量营养素目标的 $meal 选择。简短且实用。';
  }

  @override
  String aiCoachMealSuggestionSheetIMBloatedPick(Object meal) {
    return '我感到腹胀。推荐一个对肠胃温和的 $meal 选择，并说明今天应避免什么？';
  }

  @override
  String aiCoachMealSuggestionSheetIMCuttingIdea(Object meal) {
    return '我正在减脂。推荐一个高饱腹感、高蛋白且经济实惠的 $meal 方案。附带宏量营养素。';
  }

  @override
  String aiCoachMealSuggestionSheetIMHuntingFor(Object meal) {
    return '我正在寻找一份高蛋白的 $meal 选择。给出一个方案，附带完整宏量营养素，并说明推荐理由。';
  }

  @override
  String aiCoachMealSuggestionSheetINeedMoreFiber(Object meal) {
    return '我需要更多纤维。有什么 $meal 建议可以在不摄入过多碳水的情况下增加纤维？';
  }

  @override
  String aiCoachMealSuggestionSheetIndianOneAuthenticPick(
    Object budgetTail,
    Object meal,
  ) {
    return '印度风味 $meal ——一个地道选择（北印度或南印度），宏量营养素，以及为了保持目标应避开/包含的配菜。$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetItalianOrComfortOne(
    Object budgetTail,
    Object meal,
  ) {
    return '意式或慰藉类 $meal ——一个真实选择，宏量营养素，以及如有必要可提供的更轻盈的替代方案。$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetJustFinishedMyRecovery(
    Object meal,
    Object workoutType,
  ) {
    return '刚结束 $workoutType 训练。有什么适合恢复的 $meal，且能与我今天已摄入的食物搭配？';
  }

  @override
  String aiCoachMealSuggestionSheetKeepingSpendTightCheap(Object meal) {
    return '预算有限——推荐一个实惠且宏量营养素均衡的 $meal 方案。给出一个选择，附带预估成本和宏量营养素。';
  }

  @override
  String aiCoachMealSuggestionSheetLoggingMyHitMe(Object meal) {
    return '正在记录我的 $meal。给我推荐一个符合我今日饮食目标的方案——仅需一个选择，包含宏量营养素，简短且实用。';
  }

  @override
  String aiCoachMealSuggestionSheetLoggingMyHitMe2(
    Object budgetTail,
    Object meal,
  ) {
    return '正在记录我的 $meal。给我推荐一个符合我今日目标的健康实物选择——宏量营养素，简短直接。$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetLowSugarPickThat(Object meal) {
    return '推荐一个低糖且美味的 $meal 选择。附带宏量营养素及低糖理由。';
  }

  @override
  String aiCoachMealSuggestionSheetMediterraneanOnePickBowl(
    Object budgetTail,
    Object meal,
  ) {
    return '地中海风味 $meal ——一个选择（碗装、拼盘、卷饼），宏量营养素，以及推荐理由。$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetMediterraneanStyleMacrosWhat(Object meal) {
    return '地中海风格 $meal ——附带宏量营养素、推荐理由及一个快速准备建议。';
  }

  @override
  String aiCoachMealSuggestionSheetMexicanOneRealPick(
    Object budgetTail,
    Object meal,
  ) {
    return '墨西哥风味 $meal ——一个真实选择（碗装、塔可等），宏量营养素，以及如何搭配以保持目标。$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetNoQuestionsMatch(Object _query) {
    return '没有与“$_query”匹配的问题。';
  }

  @override
  String aiCoachMealSuggestionSheetNoStoveNoOven(Object meal) {
    return '没有炉灶和烤箱——有什么 5 分钟内能搞定的简单 $meal 吗？请附上宏量营养素数据。';
  }

  @override
  String aiCoachMealSuggestionSheetNoStoveNoOven2(
    Object budgetTail,
    Object meal,
  ) {
    return '没有炉灶和烤箱——一个 5 分钟内能搞定的 $meal。宏量营养素 + 采购建议。$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetOnMaintenanceGiveMe(Object meal) {
    return '处于维持期。给我一个能保持状态的 $meal 方案——宏量营养素均衡，无需极端调整。';
  }

  @override
  String aiCoachMealSuggestionSheetQuestions(Object length) {
    return '$length 个问题';
  }

  @override
  String aiCoachMealSuggestionSheetRunningOnFumesPick(Object meal) {
    return '精疲力竭。推荐一个能提供持久能量（不崩溃）的 $meal 选择，并附带宏量营养素。';
  }

  @override
  String aiCoachMealSuggestionSheetSleptBadWhatHelps(Object meal) {
    return '没睡好。什么 $meal 能让我今天保持状态，且不会导致后续能量崩溃？';
  }

  @override
  String aiCoachMealSuggestionSheetStomachSOffGentle(Object meal) {
    return '胃部不适。推荐一个不会加重症状的温和 $meal 选择。附带宏量营养素。';
  }

  @override
  String aiCoachMealSuggestionSheetTodaySARecovery(Object meal) {
    return '今天是恢复日。我的 $meal 应该怎么吃——宏量营养素、份量，以及与训练日相比的调整建议？';
  }

  @override
  String aiCoachMealSuggestionSheetVegetarianIdeaThatStill(Object meal) {
    return '推荐一个既是素食 $meal 又能保证蛋白质摄入的方案。给出一个选择，附带宏量营养素和准备建议。';
  }

  @override
  String get aiCoachMealTiredEnergyFood => '疲惫 — 补充能量的食物？';

  @override
  String get aiCoachMealUpsetStomachGentleMeal => '胃部不适 — 温和餐点？';

  @override
  String get aiCoachMealVegetarianPick => '素食推荐？';

  @override
  String get aiCoachMealWhatAreYouFeeling => '你现在的感觉如何？';

  @override
  String get aiCoachMealWhatCanIEat => '我现在能吃什么？';

  @override
  String get aiCoachMealWorkingFromPartialData => '基于部分数据分析 — 回答可能较为通用。';

  @override
  String get aiCoachMissedWorkoutNudge => '漏练提醒';

  @override
  String get aiCoachNudgeIntensity => '提醒强度';

  @override
  String get aiCoachOff => '关闭';

  @override
  String get aiCoachOtherNotifications => '其他通知';

  @override
  String aiCoachPageTapToChange(Object tagline) {
    return '$tagline · 点击更改';
  }

  @override
  String get aiCoachPostWorkoutMeal => '训练后餐点';

  @override
  String get aiCoachRefuelReminderAfterTraining => '训练后补给提醒';

  @override
  String get aiCoachRemindByEveningIf => '如果跳过训练，在傍晚提醒我';

  @override
  String aiCoachReportCardMin(Object unit) {
    return '$unit/分钟';
  }

  @override
  String aiCoachReportCardS(Object sets) {
    return '$sets 组';
  }

  @override
  String aiCoachReportCardSet(Object unit) {
    return '$unit/组';
  }

  @override
  String get aiCoachReportGreatWorkoutKeepUp => '训练很棒！保持势头。';

  @override
  String get aiCoachReportMusclesWorked => '锻炼肌肉';

  @override
  String get aiCoachReportPr => 'PR';

  @override
  String get aiCoachReportPrs => 'PR';

  @override
  String get aiCoachReportVolume => '训练总量';

  @override
  String get aiCoachReportVsLast => '对比上次';

  @override
  String get aiCoachShowFloatingBubbleFor => '显示悬浮气泡以便快速访问 AI 教练';

  @override
  String get aiCoachShowFloatingChatBubble => '显示悬浮聊天气泡、小众通知及隐私控制';

  @override
  String get aiCoachStreakCelebrations => '连胜庆祝';

  @override
  String get aiCoachTough => '严格';

  @override
  String get aiDataUsageDataWeDoNot => '我们不会与模型共享的数据';

  @override
  String get aiDataUsageEverythingNeededToCoach => '指导您所需的一切信息';

  @override
  String get aiDataUsageHowDataIsProtected => '数据如何受到保护';

  @override
  String get aiDataUsageHowYourDataIs => '您的数据如何被使用';

  @override
  String aiDataUsageScreenSendsYourFitnessProfile(Object appName) {
    return '$appName会将你的健身档案、聊天记录、食物照片和动作视频发送给生成个性化指导的模型。以下是具体处理流程。';
  }

  @override
  String get aiDataUsageTechnicalSafeguardsInPlace => '已采取的技术保障措施';

  @override
  String get aiDataUsageWhatModelsReceive => '模型接收的内容';

  @override
  String get aiDataUsageWhatNeverLeavesOur => '绝不会离开我们服务器的内容';

  @override
  String get aiDataUsageYouAreInCharge => '您可以掌控自己的数据';

  @override
  String get aiDataUsageYourControls => '您的控制选项';

  @override
  String aiFeaturesMixinValue(
    Object displayCurrent,
    Object message,
    Object snappedDisplay,
    Object unit,
  ) {
    return '$message：$displayCurrent → $snappedDisplay $unit';
  }

  @override
  String get aiInputPreview => ' × ';

  @override
  String get aiInputPreviewBodyweight => '自重';

  @override
  String get aiInputPreviewDeselectAll => '取消全选';

  @override
  String get aiInputPreviewEditSet => '编辑组数';

  @override
  String get aiInputPreviewSelectAll => '全选';

  @override
  String aiInputPreviewSheetEdit(Object name) {
    return '编辑 $name';
  }

  @override
  String aiInputPreviewSheetFrom(Object originalInput) {
    return '来自: \"$originalInput\"';
  }

  @override
  String get aiInputPreviewWarmup => '热身';

  @override
  String get aiIntegrationsAiIntegrations => 'AI 集成';

  @override
  String get aiIntegrationsConnectionReady => '连接就绪！';

  @override
  String get aiIntegrationsCopied => '已复制！';

  @override
  String get aiIntegrationsCopyConfig => '复制配置';

  @override
  String get aiIntegrationsCopyTokenOnly => '仅复制令牌';

  @override
  String get aiIntegrationsCouldNotCreateConnection => '无法创建连接。';

  @override
  String get aiIntegrationsCouldNotLoadIntegrations => '无法加载集成';

  @override
  String get aiIntegrationsCreateConnection => '创建连接';

  @override
  String get aiIntegrationsCustom => '自定义';

  @override
  String get aiIntegrationsDisconnect => '断开连接';

  @override
  String get aiIntegrationsDisconnectThisAssistant => '断开此助手连接？';

  @override
  String get aiIntegrationsDisconnecting => '正在断开连接…';

  @override
  String get aiIntegrationsGenerate => '生成';

  @override
  String get aiIntegrationsGiveThisConnectionA => '请先为此连接命名。';

  @override
  String get aiIntegrationsGrantedPermissions => '已授予权限';

  @override
  String get aiIntegrationsIVeSavedMy => '我已保存配置 · 完成';

  @override
  String get aiIntegrationsMyLaptopClaude => '我的笔记本电脑 Claude';

  @override
  String get aiIntegrationsName => '名称';

  @override
  String get aiIntegrationsNoConnectionsYet => '暂无连接';

  @override
  String get aiIntegrationsOauth => 'OAuth';

  @override
  String get aiIntegrationsPasteThisConfigInto => '将此配置粘贴到您的 AI 客户端中。';

  @override
  String get aiIntegrationsPermissions => '权限';

  @override
  String get aiIntegrationsQuickSetup => '快速设置';

  @override
  String aiIntegrationsScreenConnectAnywhere(Object appName) {
    return '在任何地方连接 $appName';
  }

  @override
  String aiIntegrationsScreenCouldNotDisconnect(Object name) {
    return '无法断开 $name 的连接。';
  }

  @override
  String aiIntegrationsScreenCreateAConnectionTo(Object appName) {
    return '创建连接以将 $appName 接入 Claude、ChatGPT、Cursor、';
  }

  @override
  String aiIntegrationsScreenCreateOneToStart(Object appName) {
    return '创建一个连接，即可在 Claude、ChatGPT 或 Cursor 中使用 $appName。';
  }

  @override
  String aiIntegrationsScreenDataYouCanCreate(Object appName) {
    return '$appName 数据。您可以随时创建新的连接。';
  }

  @override
  String aiIntegrationsScreenDisconnected(Object name) {
    return '$name 已断开连接';
  }

  @override
  String aiIntegrationsScreenReadAndModifyYour(Object appName) {
    return '在以下范围内读取和修改您的 $appName 数据：';
  }

  @override
  String aiIntegrationsScreenWillImmediatelyLoseAccess(Object name) {
    return '$name 将立即失去对您以下内容的访问权限：';
  }

  @override
  String get aiIntegrationsSetupGuide => '设置指南';

  @override
  String get aiIntegrationsTryAgain => '重试';

  @override
  String get aiIntegrationsUncheckAnythingYouWant => '取消勾选您不想提供给此连接的任何内容。';

  @override
  String get aiModelDownloadBasic => '基础';

  @override
  String get aiModelDownloadBatteryWarning =>
      '设备端 AI 模型会在您的手机上运行密集计算。这可能会增加电池消耗，并导致设备在生成锻炼计划时发热。更大的模型会占用更多资源。';

  @override
  String get aiModelDownloadBestQuality => '最佳质量';

  @override
  String get aiModelDownloadCancel => '取消';

  @override
  String get aiModelDownloadCapability => '功能';

  @override
  String get aiModelDownloadChecking => '正在检查...';

  @override
  String aiModelDownloadDeleteModelFree(Object size) {
    return '删除模型（释放 $size）';
  }

  @override
  String get aiModelDownloadDeviceCompatibility => '设备兼容性';

  @override
  String aiModelDownloadDownloadModel(Object modelName) {
    return '下载 $modelName';
  }

  @override
  String aiModelDownloadDownloadingProgress(Object percent) {
    return '下载中... $percent%';
  }

  @override
  String get aiModelDownloadGetYourTokenAt =>
      '在 huggingface.co/settings/tokens 获取您的令牌';

  @override
  String get aiModelDownloadHf => 'hf_...';

  @override
  String get aiModelDownloadHuggingfaceToken => 'HuggingFace 令牌';

  @override
  String get aiModelDownloadHuggingfaceTokenRemoved => 'HuggingFace 令牌已移除';

  @override
  String get aiModelDownloadHuggingfaceTokenSaved => 'HuggingFace 令牌已保存';

  @override
  String get aiModelDownloadImages => '图像';

  @override
  String get aiModelDownloadModelOptions => '模型选项';

  @override
  String get aiModelDownloadMultimodal => '多模态';

  @override
  String get aiModelDownloadNotCompatible => '不兼容';

  @override
  String get aiModelDownloadNotSupportedOnThis => '此设备不支持';

  @override
  String get aiModelDownloadOnDeviceAiModel => '设备端 AI 模型';

  @override
  String get aiModelDownloadOptimal => '最优';

  @override
  String get aiModelDownloadRam => 'RAM';

  @override
  String get aiModelDownloadRecommended => '推荐';

  @override
  String get aiModelDownloadRemove => '移除';

  @override
  String get aiModelDownloadRequiredToDownload =>
      '下载 HuggingFace 模型所需。请在 huggingface.co/settings/tokens 获取您的免费令牌';

  @override
  String aiModelDownloadRequiresRam(Object ramLabel) {
    return '需要 $ramLabel 内存';
  }

  @override
  String get aiModelDownloadSaveToken => '保存令牌';

  @override
  String aiModelDownloadScreenGb(Object ram) {
    return '$ram GB';
  }

  @override
  String get aiModelDownloadSearch => '搜索';

  @override
  String get aiModelDownloadSelectAModel => '选择模型';

  @override
  String aiModelDownloadSizeStorage(Object size) {
    return '$size 存储空间';
  }

  @override
  String get aiModelDownloadStandard => '标准';

  @override
  String get aiModelDownloadTokenSavedSecurely => '令牌已安全保存';

  @override
  String get aiModelDownloadUnknown => '未知';

  @override
  String get aiModelsCheckingDeviceCapabilities => '正在检查设备功能...';

  @override
  String get aiModelsCouldNotDetectDevice => '无法检测设备功能';

  @override
  String get aiModelsGetTokenAtHuggingface =>
      '在 huggingface.co/settings/tokens 获取令牌';

  @override
  String get aiModelsHf => 'hf_...';

  @override
  String get aiModelsHuggingfaceToken => 'HuggingFace 令牌';

  @override
  String get aiModelsManageGemmaModelsFor => '管理用于离线训练生成的 Gemma 模型';

  @override
  String get aiModelsModelLibrary => '模型库';

  @override
  String get aiModelsNotSupportedOnThis => '此设备不支持';

  @override
  String get aiModelsOnDeviceAiModels => '设备端 AI 模型';

  @override
  String get aiModelsRemove => '移除';

  @override
  String get aiModelsRequiredToDownloadGated => '下载受限模型至 HuggingFace 所必需。';

  @override
  String get aiModelsSaveToken => '保存令牌';

  @override
  String aiModelsSectionDeleteModelFree(Object downloadState) {
    return '删除模型 (免费 $downloadState)';
  }

  @override
  String aiModelsSectionDevice(Object displayName) {
    return '设备：$displayName';
  }

  @override
  String aiModelsSectionDownload(Object displayName) {
    return '下载 $displayName';
  }

  @override
  String aiModelsSectionGbRam(Object ram) {
    return '$ram GB 内存';
  }

  @override
  String aiModelsSectionGbRam2(Object minRamGB) {
    return '$minRamGB GB 内存';
  }

  @override
  String get aiModelsTokenSavedSecurely => '令牌已安全保存';

  @override
  String get aiPrivacyContributeToWomenS => '为女性健康研究做出贡献';

  @override
  String get aiPrivacyControlHowYourData => '控制您的数据使用方式';

  @override
  String get aiPrivacyCouldnTUpdateConsent => '无法更新许可。请重试。';

  @override
  String get aiPrivacyHowYourDataIs => '您的数据如何被使用';

  @override
  String get aiPrivacyImportantHealthInformation => '重要健康信息';

  @override
  String get aiPrivacyMedicalDisclaimer => '医疗免责声明';

  @override
  String get aiPrivacyMessagesAreStoredSo => '存储消息以便您的教练记住上下文';

  @override
  String get aiPrivacyPersonalization => '个性化';

  @override
  String get aiPrivacyPrivacyData => '隐私与数据';

  @override
  String get aiPrivacySaveChatHistory => '保存聊天记录';

  @override
  String get aiPrivacySeeWhatDataIs => '查看处理了哪些数据以及处理方式';

  @override
  String get aiPrivacyYourCoachPersonalizesWorkou => '您的教练会为您个性化定制训练和聊天内容';

  @override
  String get aiSettingsAdvancedSettings => '高级设置';

  @override
  String get aiSettingsAiAgents => 'AI 智能体';

  @override
  String get aiSettingsAiSettings => 'AI 设置';

  @override
  String get aiSettingsFitnessCoaching => '健身指导';

  @override
  String get aiSettingsFocusOn => '专注于…';

  @override
  String get aiSettingsPersonalityTone => '个性和语气';

  @override
  String get aiSettingsPickTheWeeklyStructure =>
      '选择 AI 应围绕其进行规划的每周结构。更改将应用于您的下一次生成，当前周不受影响。';

  @override
  String get aiSettingsPrivacyData => '隐私与数据';

  @override
  String get aiSettingsRemove => '移除';

  @override
  String get aiSettingsResponsePreferences => '回复偏好';

  @override
  String get aiSettingsScreenAddEmojisToAi => '在 AI 回复中添加表情符号';

  @override
  String aiSettingsScreenAddFocus(Object length) {
    return '添加重点 ($length/5)';
  }

  @override
  String get aiSettingsScreenAddHelpfulTipsIn => '在回复中添加实用建议';

  @override
  String get aiSettingsScreenAiCoachDuringWorkouts => '训练期间的 AI 教练';

  @override
  String get aiSettingsScreenAiCoachSettings => 'AI 教练设置';

  @override
  String get aiSettingsScreenAiLearnsFromPast => 'AI 从过往互动中学习 (RAG)';

  @override
  String get aiSettingsScreenAvailableAgents => '可用智能体';

  @override
  String get aiSettingsScreenChatHistoryCleared => '聊天记录已清除';

  @override
  String get aiSettingsScreenClear => '清除';

  @override
  String get aiSettingsScreenClearChatHistory => '清除聊天记录';

  @override
  String get aiSettingsScreenClearChatHistory2 => '清除聊天记录？';

  @override
  String get aiSettingsScreenCoachName => '教练名称';

  @override
  String get aiSettingsScreenCoachingStyle => '指导风格';

  @override
  String get aiSettingsScreenCommunicationTone => '沟通语气';

  @override
  String get aiSettingsScreenConsiderYourInjuriesWhen => '提供建议时考虑您的伤病情况';

  @override
  String get aiSettingsScreenCustomizeHowYourAi => '自定义 AI 教练与您的互动方式';

  @override
  String get aiSettingsScreenDefaultAgent => '默认智能体';

  @override
  String get aiSettingsScreenEnableOrDisableAgents => '启用或禁用您可以 @提及的智能体';

  @override
  String get aiSettingsScreenEncouragementLevel => '鼓励程度';

  @override
  String get aiSettingsScreenFormReminders => '动作提醒';

  @override
  String get aiSettingsScreenGetRemindersAboutProper => '获取关于正确运动姿势的提醒';

  @override
  String get aiSettingsScreenGetSuggestionsForRest => '获取休息和恢复建议';

  @override
  String get aiSettingsScreenIncludeNutritionAdviceIn => '在训练讨论中包含营养建议';

  @override
  String get aiSettingsScreenIncludeTips => '包含建议';

  @override
  String get aiSettingsScreenInjurySensitivity => '伤病敏感度';

  @override
  String get aiSettingsScreenMinimal => '极简';

  @override
  String get aiSettingsScreenNutritionMentions => '营养提及';

  @override
  String aiSettingsScreenPartAIHeaderCardValue(Object name) {
    return '@$name';
  }

  @override
  String aiSettingsScreenPriorityOf(Object value) {
    return '优先级 $value / 5';
  }

  @override
  String get aiSettingsScreenRenameYourCoachPreset => '重命名您的教练 — 预设保持不变';

  @override
  String get aiSettingsScreenResponseLength => '回复长度';

  @override
  String get aiSettingsScreenRestDaySuggestions => '休息日建议';

  @override
  String get aiSettingsScreenSaveChatHistory => '保存聊天记录';

  @override
  String get aiSettingsScreenShowAiCoachAssistant => '运动时显示 AI 教练助手';

  @override
  String get aiSettingsScreenStoreConversationsForContex => '存储对话以供上下文参考';

  @override
  String get aiSettingsScreenThisAgentRespondsWhen => '当您未 @提及特定智能体时，此智能体将进行回复';

  @override
  String get aiSettingsScreenThisWillDeleteAll => '这将删除您所有的聊天记录';

  @override
  String get aiSettingsScreenThisWillPermanentlyDelete =>
      '这将永久删除您与 AI 教练的所有对话。此操作无法撤销。';

  @override
  String get aiSettingsScreenUseEmojis => '使用表情符号';

  @override
  String get aiSettingsScreenUsePreviousConversations => '使用过往对话';

  @override
  String get aiSettingsShowAiAgentsFitness => '显示 AI 智能体、健身指导开关和隐私控制';

  @override
  String get aiSettingsSuggestions => '建议';

  @override
  String get aiSettingsTellTheAiWhat => '告诉 AI 本阶段最重要的事情。最多 5 项，每项权重 1–5。';

  @override
  String get aiSettingsTrainingSplit => '训练拆分';

  @override
  String get aiSettingsWhatToFocusOn => '关注重点';

  @override
  String get aiSettingsYourCoach => '您的教练';

  @override
  String get aiSplitPresetBenefits => '益处';

  @override
  String aiSplitPresetDetailSheetDaysWeek(Object daysPerWeek) {
    return '$daysPerWeek 天/周';
  }

  @override
  String aiSplitPresetDetailSheetFailedToUpdate(Object e) {
    return '更新失败：$e';
  }

  @override
  String aiSplitPresetDetailSheetSwitchedToGeneratingNew(
    Object scheduleSuffix,
    Object splitDisplayName,
  ) {
    return '已切换至 $splitDisplayName$scheduleSuffix。正在生成新的锻炼计划...';
  }

  @override
  String aiSplitPresetDetailSheetValue(Object hypertrophyScore) {
    return '$hypertrophyScore/10';
  }

  @override
  String get aiSplitPresetFlexible => '灵活';

  @override
  String get aiSplitPresetSchedule => '计划';

  @override
  String get aiSuggestionCardExercisesPreview => '动作预览';

  @override
  String get aiSuggestionCoachIsReviewingYour => '教练正在查看您的饮食…';

  @override
  String aiSuggestionSectionSTip(Object name) {
    return '$name 的建议';
  }

  @override
  String aiSuggestionSectionTry(Object recommendedSwap) {
    return '尝试：$recommendedSwap';
  }

  @override
  String get aiTextInputAddExercisesWithAi => '使用 AI 添加动作...';

  @override
  String get aiTextInputAddNewExercises => '➕ 添加新动作：';

  @override
  String get aiTextInputAiExerciseInput => 'AI 动作输入';

  @override
  String get aiTextInputGotIt => '知道了';

  @override
  String get aiTextInputLogSets1358 =>
      '记录组数：135*8, 145*6, +10...\n添加动作：3x10 硬拉，重量 135';

  @override
  String get aiTextInputLogSetsAddExercises => '记录组数 / 添加动作';

  @override
  String get aiTextInputLogSetsForCurrent => '📝 为当前动作记录组数：';

  @override
  String get aiTextInputOpenAiExerciseInput => '打开 AI 动作输入';

  @override
  String get aiTextInputPhotoOfWorkoutLog => '训练日志、白板或杠铃的照片';

  @override
  String get aiTextInputSpeakNaturallyDid135 => '自然说话：“做了 135，8 次”';

  @override
  String get aiTextInputTapToAddExercises => '点击 ✦ 使用 AI 添加动作';

  @override
  String get allSplitsTrainingSplits => '训练拆分';

  @override
  String get appName => 'Zealova';

  @override
  String get appTourTooltipGotIt => '知道了！';

  @override
  String get appTourTooltipSkipTutorial => '跳过教程';

  @override
  String get appearanceAppearance => '外观';

  @override
  String get appearanceSeriousMode => '专注模式';

  @override
  String askCoachButtonAskCoachAbout(Object contextLabel) {
    return '向教练咨询 $contextLabel';
  }

  @override
  String get audioCoachCardAudioSynthesisDisabledSho => '音频合成已禁用 — 仅显示文本。';

  @override
  String get audioCoachCardTodaySCoachBrief => '今日教练简报';

  @override
  String get audioSettingsAudioDucking => '音频闪避';

  @override
  String get audioSettingsBackgroundMusic => '背景音乐';

  @override
  String get audioSettingsKeepSpotifyMusicPlaying => '训练期间保持 Spotify/音乐播放';

  @override
  String get audioSettingsLowerMusicDuringVoice => '语音播报时调低音乐音量';

  @override
  String get audioSettingsMuteVoiceDuringVideos => '视频播放时静音语音';

  @override
  String audioSettingsSectionValue(Object displayPct) {
    return '$displayPct%';
  }

  @override
  String get audioSettingsVoiceAnnouncements => '语音播报';

  @override
  String get audioSettingsVoiceVolumeVideo => '语音音量与视频';

  @override
  String get audioSettingsWorkoutAudio => '训练音频';

  @override
  String get authBuildMyPlan => '创建我的计划';

  @override
  String get authContinueWithApple => '使用 Apple 继续';

  @override
  String get authContinueWithEmail => '使用邮箱继续';

  @override
  String get authContinueWithGoogle => '使用 Google 继续';

  @override
  String get authEmailHint => '邮箱';

  @override
  String get authIntroAiCoach => 'AI 教练';

  @override
  String get authIntroExercises => '运动';

  @override
  String get authIntroFoods => '食物';

  @override
  String get authPasswordHint => '密码';

  @override
  String get authSignIn => '登录';

  @override
  String get authSignUp => '注册';

  @override
  String get authWelcomeSubtitle => '你的 AI 健身教练';

  @override
  String get authWelcomeTitle => '欢迎使用 Zealova';

  @override
  String get avoidedExercisesAddToAvoidList => '添加到规避列表';

  @override
  String get avoidedExercisesChangeExercise => '更换动作';

  @override
  String get avoidedExercisesErrorLoadingExercises => '加载动作时出错';

  @override
  String get avoidedExercisesExercisesToAvoid => '规避动作';

  @override
  String get avoidedExercisesExercisesYouAddHere =>
      '您在此处添加的动作将从 AI 生成的训练计划中排除。';

  @override
  String get avoidedExercisesNoExercisesToAvoid => '没有需要规避的动作';

  @override
  String get avoidedExercisesPleaseLogIn => '请登录';

  @override
  String get avoidedExercisesReasonAndTemporarySettings =>
      '原因和临时设置将应用于每个动作。您可以稍后编辑单个条目。';

  @override
  String get avoidedExercisesReasonOptional => '原因（可选）';

  @override
  String get avoidedExercisesRemove => '移除';

  @override
  String get avoidedExercisesRemoveExercise => '移除动作';

  @override
  String get avoidedExercisesSaveChanges => '保存更改';

  @override
  String avoidedExercisesScreenAddToAvoidList(Object count) {
    return '将 $count 个动作加入避开列表';
  }

  @override
  String avoidedExercisesScreenAvoid(Object exerciseName) {
    return '避开 “$exerciseName”';
  }

  @override
  String avoidedExercisesScreenAvoidExercises(Object count) {
    return '避开 $count 个动作';
  }

  @override
  String get avoidedExercisesScreenBrowseTheExerciseLibrary => '浏览动作库以获取选项';

  @override
  String avoidedExercisesScreenEdit(Object exerciseName) {
    return '编辑 “$exerciseName”';
  }

  @override
  String get avoidedExercisesScreenErrorLoadingAlternatives => '加载替代动作时出错';

  @override
  String get avoidedExercisesScreenNoSpecificAlternativesFound => '未找到特定的替代动作';

  @override
  String avoidedExercisesScreenPartAvoidedExerciseCardInsteadOf(
    Object exerciseName,
  ) {
    return '代替 $exerciseName';
  }

  @override
  String avoidedExercisesScreenPartAvoidedExerciseCardUntil(
    Object day,
    Object month,
    Object year,
  ) {
    return '直到 $year年$month月$day日';
  }

  @override
  String avoidedExercisesScreenRemoveFromAvoidList(Object exerciseName) {
    return '将 “$exerciseName” 从避开列表中移除？';
  }

  @override
  String avoidedExercisesScreenRemoved(Object exerciseName) {
    return '已移除 “$exerciseName”';
  }

  @override
  String avoidedExercisesScreenReplacedInUpcomingWorkouts(Object exerciseName) {
    return '已在即将到来的训练中替换 “$exerciseName”';
  }

  @override
  String get avoidedExercisesScreenSafe => '安全';

  @override
  String get avoidedExercisesScreenSafeAlternatives => '安全替代动作';

  @override
  String avoidedExercisesScreenUntil(Object day, Object month, Object year) {
    return '直到 $day/$month/$year';
  }

  @override
  String avoidedExercisesScreenUntil2(Object day, Object month, Object year) {
    return '直到 $day/$month/$year';
  }

  @override
  String avoidedExercisesScreenUntil3(Object day, Object month, Object year) {
    return '直到 $day/$month/$year';
  }

  @override
  String avoidedExercisesScreenUpdated(Object exerciseName) {
    return '已更新 “$exerciseName”';
  }

  @override
  String get avoidedExercisesScreenViewSafeAlternatives => '查看安全替代动作';

  @override
  String get avoidedExercisesSetAnEndDate => '为这些限制设置结束日期';

  @override
  String get avoidedExercisesSetAnEndDate2 => '为此限制设置结束日期';

  @override
  String get avoidedExercisesTapToAddExercises => '点击 + 添加您想要跳过的动作';

  @override
  String get avoidedExercisesTemporary => '临时';

  @override
  String get avoidedMusclesAvoid => '规避';

  @override
  String get avoidedMusclesCurrentlyAvoided => '当前规避';

  @override
  String get avoidedMusclesErrorLoadingMuscles => '加载肌肉数据时出错';

  @override
  String get avoidedMusclesExercisesTargetingThisMuscl => '针对此肌肉的动作将被完全排除';

  @override
  String get avoidedMusclesMusclesToAvoid => '规避肌肉';

  @override
  String get avoidedMusclesPleaseLogIn => '请登录';

  @override
  String get avoidedMusclesReduce => '减少';

  @override
  String get avoidedMusclesRemove => '移除';

  @override
  String get avoidedMusclesRemoveFromAvoidList => '从规避列表中移除';

  @override
  String get avoidedMusclesReplacedExercisesTargetingT => '已替换即将进行的训练中针对此肌肉的动作';

  @override
  String get avoidedMusclesSaveChanges => '保存更改';

  @override
  String avoidedMusclesScreenReason(Object reason) {
    return '原因：$reason';
  }

  @override
  String avoidedMusclesScreenRemove(Object displayName) {
    return '移除“$displayName”？';
  }

  @override
  String avoidedMusclesScreenRemoved(Object displayName) {
    return '已移除“$displayName”';
  }

  @override
  String avoidedMusclesScreenReplacedExercisesTargetingMuscles(Object count) {
    return '已替换即将进行的锻炼中针对 $count 块肌肉的动作';
  }

  @override
  String get avoidedMusclesSelectMusclesToAvoid => '选择您在训练中想要规避或减少的肌肉';

  @override
  String get avoidedMusclesSeverity => '严重程度';

  @override
  String get badgeHubAllAvailableBadges => '所有可用徽章';

  @override
  String get badgeHubBadges => '徽章';

  @override
  String get badgeHubChallenges => '挑战';

  @override
  String get badgeHubHeroEarnBadgesForEvery => '为每一个里程碑、连胜和 PB 赢取徽章。';

  @override
  String get badgeHubHeroHowItWorks => '如何运作';

  @override
  String get badgeHubHeroRewardYourProgress => '奖励您的进步';

  @override
  String get badgeHubInProgress => '进行中';

  @override
  String get badgeHubInProgress2 => '进行中';

  @override
  String get badgeHubLevelledBadgesThatKeep =>
      '随着您记录更多的步数、卡路里、训练次数或距离，徽章等级会不断提升。';

  @override
  String get badgeHubMasteries => '精通';

  @override
  String get badgeHubMasteries2 => '精通';

  @override
  String get badgeHubMyBadges => '我的徽章';

  @override
  String get badgeHubOneTimeTrophiesFor => '针对达成里程碑的一次性奖杯——时间目标、连续打卡、重大 PR。';

  @override
  String get badgeHubPersonalBests => '个人最好成绩';

  @override
  String get badgeHubPersonalBests2 => '个人最好成绩';

  @override
  String get badgeHubRewardYourProgress => '奖励您的进步';

  @override
  String badgeHubScreenTotal(Object count) {
    return '总计$count个';
  }

  @override
  String get badgeHubWeeklyOrDailyChallenges =>
      '您可以参与的每周或每日挑战。它们会按计划重置，因此您可以随时重新赢取。';

  @override
  String get badgeHubYourHighestLiftsLongest =>
      '您最高的举重重量、最长的训练时长、最大的训练量。打破它们来升级奖牌。';

  @override
  String get barcodeScannerOverlayPointYourCameraAt => '将摄像头对准产品条形码';

  @override
  String get barcodeScannerOverlayScanABarcode => '扫描条形码';

  @override
  String get batchPortioningBatchPortioning => '批量份量计算';

  @override
  String get batchPortioningCalculateNutritionPerPortio => '计算每份营养';

  @override
  String get batchPortioningCalories => '卡路里';

  @override
  String get batchPortioningCarbsG => '碳水化合物 (g)';

  @override
  String get batchPortioningFatG => '脂肪 (g)';

  @override
  String get batchPortioningHowManyServings => '总份数？';

  @override
  String get batchPortioningHowMuchDidYou => '您吃了多少？';

  @override
  String get batchPortioningLogThisPortion => '记录此份量';

  @override
  String get batchPortioningPerServing => '每份';

  @override
  String get batchPortioningProteinG => '蛋白质 (g)';

  @override
  String get batchPortioningRecipeMealName => '食谱/餐名';

  @override
  String get batchPortioningThisMakes => '这总共包含';

  @override
  String get batchPortioningTotalBatchNutrition => '总批量营养';

  @override
  String get beastHeaderCardBeastMode => '野兽模式';

  @override
  String get beastHeaderCardPowerUserToolkit => '高阶用户工具包';

  @override
  String get beastModeAboutBeastMode => '关于 Beast Mode';

  @override
  String get beastModeAboutBeastModeSubtitle => '构建信息与控制';

  @override
  String get beastModeAlgorithmInspector => '算法检查器';

  @override
  String get beastModeAlgorithmInspectorSubtitle => '查看训练背后的数学逻辑';

  @override
  String get beastModeBeastMode => '野兽模式';

  @override
  String get beastModeCustomizationLab => '自定义实验室';

  @override
  String get beastModeCustomizationLabSubtitle => '高级颜色和字体控制';

  @override
  String get beastModeDataAndSyncTools => '数据与同步工具';

  @override
  String get beastModeDataAndSyncToolsSubtitle => '调试同步问题并管理数据';

  @override
  String get beastModePremium => '高级版';

  @override
  String get beastModeRecoveryAndProgression => '恢复与进度';

  @override
  String get beastModeRecoveryAndProgressionSubtitle => '可视化身体恢复情况并预测增长';

  @override
  String get beastModeUnlockBeastMode => '野兽模式';

  @override
  String get beastModeUnlockLetSGo => '开始吧';

  @override
  String get beastModeUnlockUnlocked => '已解锁';

  @override
  String get beastModeUnlockYouVeUnlockedThe => '你已解锁高级用户工具包。查看你锻炼背后的算法。';

  @override
  String get beastModeWorkoutAlgorithm => '训练算法';

  @override
  String get beastModeWorkoutAlgorithmSubtitle => '深度控制训练生成';

  @override
  String get beastModeWorkoutTemplates => '训练模板';

  @override
  String get beastModeWorkoutTemplatesSubtitle => '自定义训练结构预设';

  @override
  String get bleHeartRateAutoConnectOnWorkout => '锻炼开始时自动连接';

  @override
  String get bleHeartRateConnect => '连接';

  @override
  String get bleHeartRateDisconnect => '断开连接';

  @override
  String get bleHeartRateForgetDevice => '忽略设备';

  @override
  String get bleHeartRateHeartRateMonitor => '心率监测仪';

  @override
  String get bleHeartRateHeartRateMonitor2 => '心率监测仪';

  @override
  String get bleHeartRateNoDevicesFound => '未找到设备';

  @override
  String get bleHeartRateRescan => '重新扫描';

  @override
  String get bleHeartRateScanForHrMonitors => '扫描心率监测仪';

  @override
  String get bleHeartRateSearchingForDevices => '正在搜索设备...';

  @override
  String bleHeartRateSectionDbm(Object rssi) {
    return '$rssi dBm';
  }

  @override
  String get bleHeartRateTryAgain => '重试';

  @override
  String bodyAgeBadgeBodyAge(Object bodyAge) {
    return '身体年龄 $bodyAge';
  }

  @override
  String get bodyAgeBadgeMatchesYourAge => '符合你的年龄';

  @override
  String bodyAgeBadgeYrVsActual(Object delta, Object sign) {
    return '$sign$delta 岁（对比实际年龄）';
  }

  @override
  String get bodyAnalyzerBodyAnalyzer => '身体分析器';

  @override
  String get bodyAnalyzerBodyFat => '体脂';

  @override
  String get bodyAnalyzerCaptureAlsoEstimateTapeMeasurement => '同时根据照片估算卷尺测量值';

  @override
  String get bodyAnalyzerCaptureAnalyzing => '正在分析…';

  @override
  String get bodyAnalyzerCaptureFusesHeightWeightBody =>
      '将身高、体重、体脂和卷尺测量值融合到分析中。';

  @override
  String get bodyAnalyzerCapturePickAtLeastOne => '至少选择一张照片。';

  @override
  String get bodyAnalyzerCapturePickPhotos => '选择照片';

  @override
  String bodyAnalyzerCaptureScreenNoPhotosYetCapture(Object label) {
    return '暂无 $label 照片 — 请在“进度”中拍摄一张。';
  }

  @override
  String get bodyAnalyzerCaptureUseMyStoredMeasurements => '使用我存储的测量值';

  @override
  String get bodyAnalyzerCreatingProposal => '正在创建建议…';

  @override
  String get bodyAnalyzerGetYourBodyAnalyzer => '获取你的身体分析器反馈';

  @override
  String get bodyAnalyzerHeroOverallRating => '综合评分';

  @override
  String get bodyAnalyzerMuscleMass => '肌肉量';

  @override
  String get bodyAnalyzerNewAnalysis => '新分析';

  @override
  String get bodyAnalyzerPersonalizedTips => '个性化建议';

  @override
  String bodyAnalyzerScreenCorrectiveExercisesQueuedFor(Object length) {
    return '已为下个计划排队 $length 个矫正训练';
  }

  @override
  String bodyAnalyzerScreenCouldnTLoadBody(Object _error) {
    return '无法加载身体分析：$_error';
  }

  @override
  String get bodyAnalyzerStartAnalysis => '开始分析';

  @override
  String get bodyAnalyzerSymmetry => '对称性';

  @override
  String bodyHydrationAnimationValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String get bodyMetricsBodyMetricsScore => '身体指标与评分';

  @override
  String get bodyMetricsConsistency => '一致性';

  @override
  String get bodyMetricsFitnessScore => '健身评分';

  @override
  String get bodyMetricsStrength => '力量';

  @override
  String get bodyMuscleSelectorLoadingBodyDiagram => '正在加载身体图示...';

  @override
  String get bodyMuscleSelectorTapOnAMuscle => '点击肌肉进行选择 • 双指缩放';

  @override
  String get bodyPartSelectorSelectBodyPart => '选择身体部位';

  @override
  String get bodyPartSelectorTapTheAffectedArea => '点击受影响区域';

  @override
  String get bodyScoreOverlayLoadingBodyDiagram => '正在加载身体图示...';

  @override
  String breathPromptWidgetStartsInS(Object _sessionSecondsLeft) {
    return '$_sessionSecondsLeft秒后开始';
  }

  @override
  String get breathingGuideBreathingGuide => '呼吸指南';

  @override
  String get breathingGuideExhale => '呼气';

  @override
  String get breathingGuideInhale => '吸气';

  @override
  String buddyWorkoutBarSets(Object _partnerSetsLogged) {
    return '$_partnerSetsLogged 组';
  }

  @override
  String get buttonCancel => '取消';

  @override
  String get buttonContinue => '继续';

  @override
  String get buttonDelete => '删除';

  @override
  String get buttonRetry => '重试';

  @override
  String get buttonSave => '保存';

  @override
  String get buttonStart => '开始';

  @override
  String get calendarIconButtonSchedule => '计划';

  @override
  String get caloriesBurnedAllFromBackgroundActivity => '全部来自后台活动';

  @override
  String get caloriesBurnedCaloriesBurnedToday => '今日消耗热量';

  @override
  String get caloriesBurnedCompleteAWorkoutOr => '完成一次锻炼或从你的健康应用同步';

  @override
  String get caloriesBurnedInApp => '应用内';

  @override
  String get caloriesBurnedNoActivityRecordedToday => '今日无记录活动';

  @override
  String get caloriesBurnedPassive => '被动';

  @override
  String get caloriesBurnedSauna => '桑拿';

  @override
  String caloriesBurnedSheetKcal(Object totalBurned) {
    return '$totalBurned kcal';
  }

  @override
  String caloriesBurnedSheetKcal2(Object entry) {
    return '$entry kcal';
  }

  @override
  String caloriesBurnedSheetKcal3(Object value) {
    return '$value kcal';
  }

  @override
  String caloriesBurnedSheetMin(Object durationMinutes) {
    return '$durationMinutes 分钟';
  }

  @override
  String caloriesBurnedSheetWorkouts(Object appName) {
    return '$appName 训练';
  }

  @override
  String get caloriesBurnedStepsHeartRateAnd => '全天的步数、心率和运动';

  @override
  String get caloriesBurnedSynced => '已同步';

  @override
  String get caloriesBurnedSyncedFromHealth => '已从健康应用同步';

  @override
  String get caloriesBurnedTodaySActivity => '今日活动';

  @override
  String caloriesSummaryCardCalPhase(Object delta, Object phase) {
    return '+$delta 卡路里 · $phase 阶段';
  }

  @override
  String get caloriesSummaryCardCalories => '热量';

  @override
  String caloriesSummaryCardKcal(Object calorieTarget, Object consumed) {
    return '$consumed / $calorieTarget kcal';
  }

  @override
  String get caloriesSummaryCardOveLeft => '剩余';

  @override
  String get cancelConfirmationAnythingElseYouD => '还有什么想分享的吗？（可选）';

  @override
  String get cancelConfirmationCancelAnyway => '仍然取消';

  @override
  String get cancelConfirmationHelpUsImprove => '帮助我们改进';

  @override
  String get cancelConfirmationKeepMySubscription => '保留我的订阅';

  @override
  String get cancelConfirmationNeedABreakInstead => '需要休息一下吗？';

  @override
  String get cancelConfirmationNeverMindKeepMy => '没关系，保留我的订阅';

  @override
  String get cancelConfirmationPauseForUpTo => '暂停长达 3 个月';

  @override
  String cancelConfirmationSheetAppliedSuccessfully(Object name) {
    return '$name 应用成功！';
  }

  @override
  String cancelConfirmationSheetCancel(Object planName) {
    return '取消 $planName？';
  }

  @override
  String cancelConfirmationSheetFailedToApplyOffer(Object e) {
    return '应用优惠失败：$e';
  }

  @override
  String get cancelConfirmationSpecialOffersJustFor => '专属于你的特别优惠';

  @override
  String get cancelConfirmationWeDHateTo => '我们不希望你离开';

  @override
  String get cancelConfirmationWhatYouLlLose => '你将失去的内容';

  @override
  String get cancelConfirmationWhyAreYouThinking => '你为什么考虑取消？';

  @override
  String get capabilityAndCommunityAiCoachAvailability => 'AI 教练可用性';

  @override
  String get capabilityAndCommunityAiUpdatedContinuously => 'AI，持续更新';

  @override
  String get capabilityAndCommunityBuiltRight => '精心打造。';

  @override
  String get capabilityAndCommunityDiscord => 'Discord';

  @override
  String get capabilityAndCommunityExercisesWithHdVideo => '高清视频练习';

  @override
  String get capabilityAndCommunityFoodsInOurDatabase => '我们数据库中的食物';

  @override
  String get capabilityAndCommunityInstagram => 'Instagram';

  @override
  String get capabilityAndCommunityReachUsAnytime => '随时联系我们';

  @override
  String get capabilityAndCommunityRealNumbersRealPeople => '真实数据。背后是真实的人。';

  @override
  String get cardioHistoryAll => '全部';

  @override
  String get cardioHistoryAllTime => '历史总计';

  @override
  String get cardioHistoryAvgHr => '平均心率';

  @override
  String get cardioHistoryAvgPace => '平均配速';

  @override
  String get cardioHistoryAvgSpeed => '平均速度';

  @override
  String get cardioHistoryAvgWatts => '平均功率';

  @override
  String get cardioHistoryCalories => '卡路里';

  @override
  String get cardioHistoryCardioHistory => '有氧运动记录';

  @override
  String get cardioHistoryClearDateFilter => '清除日期筛选';

  @override
  String get cardioHistoryCouldNotLoadCardio => '无法加载有氧运动历史记录';

  @override
  String get cardioHistoryCycle => '骑行';

  @override
  String get cardioHistoryDateRange => '日期范围';

  @override
  String get cardioHistoryDistance => '距离';

  @override
  String get cardioHistoryDuration => '时长';

  @override
  String get cardioHistoryElevation => '海拔';

  @override
  String get cardioHistoryHiit => 'HIIT';

  @override
  String get cardioHistoryHike => '徒步';

  @override
  String get cardioHistoryImportFromStravaPeloton =>
      '从 Strava、Peloton、Garmin、Apple Health 或 Fitbit 导入，即可在此处查看您的历史记录。';

  @override
  String get cardioHistoryIndoorCycle => '室内骑行';

  @override
  String get cardioHistoryMaxHr => '最大心率';

  @override
  String cardioHistoryNActivities(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次活动',
      one: '1 次活动',
    );
    return '$_temp0';
  }

  @override
  String cardioHistoryNSessions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次训练',
      one: '1 次训练',
    );
    return '$_temp0';
  }

  @override
  String get cardioHistoryNoCardioSessionsYet => '暂无有氧运动记录。';

  @override
  String get cardioHistoryNoSessionsMatchThis => '没有符合此筛选条件的记录。';

  @override
  String get cardioHistoryNotes => '备注';

  @override
  String get cardioHistoryPleaseSignInTo => '请登录以查看您的有氧运动记录。';

  @override
  String cardioHistoryRouteRecordedPts(Object count) {
    return '路线已记录（$count 个点）';
  }

  @override
  String get cardioHistoryRow => '划船';

  @override
  String get cardioHistoryRpe => 'RPE';

  @override
  String get cardioHistoryRun => '跑步';

  @override
  String cardioHistoryScreenBpm(Object avgHeartRate) {
    return '$avgHeartRate bpm';
  }

  @override
  String cardioHistoryScreenBpm2(Object maxHeartRate) {
    return '$maxHeartRate bpm';
  }

  @override
  String cardioHistoryScreenCal(Object calories) {
    return '$calories 大卡';
  }

  @override
  String cardioHistoryScreenM(Object log) {
    return '$log 米';
  }

  @override
  String cardioHistoryScreenW(Object avgWatts) {
    return '$avgWatts W';
  }

  @override
  String get cardioHistorySessions => '运动记录';

  @override
  String get cardioHistorySplits => '分段';

  @override
  String get cardioHistorySwim => '游泳';

  @override
  String get cardioHistoryThisWeek => '本周';

  @override
  String get cardioHistoryTryClearingFiltersOr => '请尝试清除筛选条件或扩大日期范围。';

  @override
  String get cardioHistoryWalk => '步行';

  @override
  String get cardioHistoryYoga => '瑜伽';

  @override
  String get cardioPrHistoryAllTimeBestsBy => '各运动项目历史最佳';

  @override
  String get cardioPrHistoryCardioPrs => '有氧运动 PR';

  @override
  String get cardioPrHistoryCouldNotLoadTrend => '无法加载趋势';

  @override
  String get cardioPrHistoryFirstTime => '首次达成！';

  @override
  String get cardioPrHistoryLogACardioSession => '记录一次有氧运动以开始追踪 PR。';

  @override
  String get cardioPrHistoryNoCardioPrsYet => '暂无有氧运动 PR';

  @override
  String get cardioPrHistoryNoHistoryYet => '暂无历史记录。';

  @override
  String cardioPrHistorySheetCouldNotLoadCardio(Object err) {
    return '无法加载有氧运动 PR：$err';
  }

  @override
  String get categoryExercisesLoadMore => '加载更多';

  @override
  String get categoryExercisesNoExercisesFound => '未找到相关动作';

  @override
  String get categoryFilterChipsAll => '全部';

  @override
  String get chainDetailLoading => '加载中...';

  @override
  String get chainDetailProgressionPath => '进阶路径';

  @override
  String get chainDetailProgressionStartedGoodLuck => '进阶计划已开启！祝你好运！';

  @override
  String chainDetailScreenAttemptsAtCurrentStep(Object attemptsAtCurrent) {
    return '当前步骤已尝试 $attemptsAtCurrent 次';
  }

  @override
  String chainDetailScreenBestReps(Object bestRepsAtCurrent) {
    return '最佳: $bestRepsAtCurrent 次';
  }

  @override
  String chainDetailScreenStep(Object difficultyLabel, Object stepOrder) {
    return '步骤 $stepOrder - $difficultyLabel';
  }

  @override
  String chainDetailScreenSteps(Object length) {
    return '$length 个步骤';
  }

  @override
  String get chainDetailStartThisProgression => '开始此进阶计划';

  @override
  String get chainDetailYourProgress => '您的进度';

  @override
  String get challengeCardAcceptChallenge => '接受挑战';

  @override
  String get challengeCardActive => '进行中';

  @override
  String get challengeCardChallengedYouToBeat => '向你发起挑战，目标是超越';

  @override
  String challengeCardDaysLeft(Object daysRemaining) {
    return '剩余 $daysRemaining 天';
  }

  @override
  String get challengeCardDecline => '拒绝';

  @override
  String get challengeCardExpired => '已过期';

  @override
  String challengeCardParticipating(Object participantCount) {
    return '$participantCount 人参与';
  }

  @override
  String get challengeCardYouChallengedToBeat => '你发起的挑战目标是超越';

  @override
  String get challengeCompareChallengeResults => '挑战结果';

  @override
  String get challengeCompareFailedToLoadChallenge => '无法加载挑战';

  @override
  String get challengeCompareRematch => '再次挑战';

  @override
  String get challengeCompareRematchSent => '再次挑战请求已发送！';

  @override
  String get challengeCompareReps => '次数';

  @override
  String challengeCompareScreenFailedToSendRematch(Object e) {
    return '发送重赛请求失败: $e';
  }

  @override
  String challengeCompareScreenMin(Object v) {
    return '$v 分钟';
  }

  @override
  String get challengeCompareSets => '组数';

  @override
  String get challengeCompareTime => '时间';

  @override
  String get challengeCompareViewFeed => '查看动态';

  @override
  String get challengeCompareVolume => '总容量';

  @override
  String get challengeCompareWinner => '获胜者';

  @override
  String get challengeCompleteChallengeAttempted => '挑战已完成';

  @override
  String get challengeCompleteContinue => '继续';

  @override
  String challengeCompleteDialogLbs(Object theirVolume) {
    return '$theirVolume lbs';
  }

  @override
  String challengeCompleteDialogMin(Object yourDuration) {
    return '$yourDuration 分钟';
  }

  @override
  String challengeCompleteDialogMin2(Object theirDuration) {
    return '$theirDuration 分钟';
  }

  @override
  String get challengeCompletePerformanceComparison => '表现对比';

  @override
  String get challengeCompleteThem => '对方：';

  @override
  String get challengeCompleteTime => '时间';

  @override
  String get challengeCompleteVictory => '胜利！';

  @override
  String get challengeCompleteViewFullComparison => '查看完整对比';

  @override
  String get challengeCompleteViewInFeed => '在动态中查看';

  @override
  String get challengeCompleteVolume => '总容量';

  @override
  String get challengeCompleteYou => '你：';

  @override
  String get challengeCompleteYourVictoryHasBeen => '你的胜利已分享给好友！🎉';

  @override
  String get challengeCreateAnyoneCanJoinVia => '任何人都可以通过社交标签页加入';

  @override
  String get challengeCreateButton => '创建挑战';

  @override
  String get challengeCreateDescriptionOptional => '描述（可选）';

  @override
  String get challengeCreateEG100Chest => '例如：本周完成 100 组胸部训练';

  @override
  String get challengeCreateFieldEnds => '结束';

  @override
  String get challengeCreateFieldGoal => '目标';

  @override
  String get challengeCreateFieldTitle => '标题';

  @override
  String get challengeCreateInviteFriends => '邀请好友';

  @override
  String get challengeCreateTitle => '创建挑战';

  @override
  String get challengeFriendsAddTrashTalkMessage => '添加挑衅留言（可选）💪';

  @override
  String get challengeFriendsChallengeFriends => '挑战好友';

  @override
  String challengeFriendsDialogChallengeSentToFriend(Object length) {
    return '🏆 挑战已发送给 $length 位好友！';
  }

  @override
  String challengeFriendsDialogFailedToSendChallenges(Object e) {
    return '发送挑战失败: $e';
  }

  @override
  String challengeFriendsDialogSendChallenge(Object length) {
    return '发送挑战 ($length)';
  }

  @override
  String get challengeFriendsNoFriendsToChallenge => '没有可挑战的好友';

  @override
  String get challengeFriendsPleaseSelectAtLeast => '请至少选择一位好友';

  @override
  String get challengeFriendsSearchFriends => '搜索好友...';

  @override
  String get challengeFriendsSending => '发送中...';

  @override
  String get challengeFriendsStatsToBeat => '挑战目标：';

  @override
  String get challengeHistoryAll => '全部';

  @override
  String get challengeHistoryChallengeHistory => '挑战历史';

  @override
  String get challengeHistoryChallengeStats => '挑战统计';

  @override
  String get challengeHistoryFailedToLoadChallenges => '无法加载挑战';

  @override
  String get challengeHistoryLetSGo => '开始吧！💪';

  @override
  String get challengeHistoryLost => '已失败';

  @override
  String get challengeHistoryNotNow => '暂不';

  @override
  String get challengeHistoryPending => '待处理';

  @override
  String get challengeHistoryQuit => '已退出';

  @override
  String get challengeHistoryRetryChallenge => '重试挑战';

  @override
  String get challengeHistoryRetryChallenge2 => '重试挑战？';

  @override
  String get challengeHistoryRetryChallengeSentTime => '🔥 已发送重试挑战！是时候一雪前耻了！';

  @override
  String challengeHistoryScreenFailedToSendRetry(Object e) {
    return '发送重试失败：$e';
  }

  @override
  String get challengeHistoryTarget => '目标：';

  @override
  String get challengeHistoryThem => '对方';

  @override
  String get challengeHistoryUnknownError => '未知错误';

  @override
  String get challengeHistoryWon => '已获胜';

  @override
  String get challengeHistoryYou => '你：';

  @override
  String get challengePublicToggle => '公开';

  @override
  String get challengesBeTheFirstTo => '快来成为第一个发起挑战的人！';

  @override
  String get challengesChallenge => '挑战';

  @override
  String get challengesCouldNotLoadChallenges => '无法加载挑战。\n请重试。';

  @override
  String get challengesCouldNotLoadYour => '无法加载你的挑战。\n请重试。';

  @override
  String get challengesCreateChallenge => '创建挑战';

  @override
  String get challengesFailedToLoadChallenges => '加载挑战失败';

  @override
  String get challengesJoinAChallengeTo => '加入挑战，与好友一较高下，\n达成你的健身目标！';

  @override
  String get challengesMyChallenges => '我的挑战';

  @override
  String get challengesNoActiveChallenges => '暂无进行中的挑战';

  @override
  String get challengesNoChallengesFound => '未找到挑战';

  @override
  String get challengesPopularChallenges => '热门挑战';

  @override
  String get challengesStartYourOwnChallenge => '发起你自己的挑战并邀请好友';

  @override
  String get challengesStrip100KmTarget => '100公里目标';

  @override
  String get challengesStrip25KmTarget => '25公里目标';

  @override
  String get challengesStrip5WorkoutsIn7 => '7天内完成5次训练';

  @override
  String get challengesStripMonthlyRunChallenge => '月度跑步挑战';

  @override
  String changeEquipmentHelperCouldNotSaveEquipment(Object e) {
    return '无法保存器械：$e';
  }

  @override
  String get changeEquipmentHelperEquipment => '器械';

  @override
  String get changeEquipmentHelperNoActiveGymProfile =>
      '没有激活的健身房配置 — 请先打开“设置”→“健身房”。';

  @override
  String get chatActionConfirmApplied => '已应用';

  @override
  String get chatActionConfirmApply => '应用';

  @override
  String get chatActionConfirmDismissed => '已忽略';

  @override
  String get chatClear => '清除';

  @override
  String get chatClearChatHistory => '清除聊天记录？';

  @override
  String get chatFeaturesInfoLongPressActionPills => '长按操作胶囊可自定义快捷方式';

  @override
  String get chatFeaturesInfoTryAskingWhatCan => '试着问：“你能做什么？”以获取完整功能列表';

  @override
  String get chatFeaturesInfoWhatCanIDo => '我能做什么？';

  @override
  String get chatFeaturesInfoYourAiCoachCan => '你的AI教练可以分析媒体、生成训练计划、提供营养建议等。';

  @override
  String get chatGotIt => '知道了';

  @override
  String get chatLeftToday => ') 今日剩余';

  @override
  String chatMediaWidgetsCalTotal(Object totalCal) {
    return '总计 $totalCal 卡路里';
  }

  @override
  String chatMediaWidgetsGProtein(Object totalProtein) {
    return '${totalProtein}g 蛋白质';
  }

  @override
  String chatMediaWidgetsGoTo(Object workoutName) {
    return '前往 $workoutName';
  }

  @override
  String get chatMediaWidgetsGoToWorkout => '前往训练';

  @override
  String chatMediaWidgetsItemsFound(Object length) {
    return '找到 $length 个项目';
  }

  @override
  String get chatMediaWidgetsViewAllLog => '查看全部并记录';

  @override
  String get chatMessageBubbleCopied => '已复制';

  @override
  String get chatMessageBubbleCopy => '复制';

  @override
  String get chatMessageBubbleDeleteThisMessage => '删除此消息？';

  @override
  String get chatMessageBubblePin => '置顶';

  @override
  String get chatMessageBubbleRegenerate => '重新生成';

  @override
  String get chatMessageBubbleReport => '举报';

  @override
  String get chatMessageBubbleThisActionCannotBe => '此操作无法撤销。';

  @override
  String get chatMessageBubbleUnpin => '取消置顶';

  @override
  String get chatMessageBubbleUploading => '上传中...';

  @override
  String chatMessageBubbleValue(Object message) {
    return '+$message';
  }

  @override
  String chatMessageBubbleValue2(Object label) {
    return '$label：';
  }

  @override
  String get chatMessageBubbleWorkoutContext => '训练背景';

  @override
  String get chatNotNow => '暂不';

  @override
  String get chatQuickPillsChatActions => '聊天操作';

  @override
  String get chatQuickPillsChooseMultiplePhotos => '选择多张照片';

  @override
  String get chatQuickPillsChoosePhoto => '选择照片';

  @override
  String get chatQuickPillsChooseVideo => '选择视频';

  @override
  String get chatQuickPillsCustomizeShortcuts => '自定义快捷方式';

  @override
  String get chatQuickPillsDragToReorderTop => '拖动以重新排序。前5个将显示在输入栏上方的胶囊中。';

  @override
  String get chatQuickPillsRecordVideo => '录制视频';

  @override
  String get chatQuickPillsResetToDefault => '重置为默认';

  @override
  String get chatQuickPillsTakePhoto => '拍照';

  @override
  String get chatQuickPillsTapAnActionTo => '点击操作即可使用。长按胶囊可重新排序。';

  @override
  String get chatScreenCantReachCoach => '暂时无法联系教练。';

  @override
  String get chatScreenCheckConnection => '请检查网络连接并重试。';

  @override
  String get chatScreenCoachIsThinkingLonger => '教练正在思考，比平时稍久一些。';

  @override
  String get chatScreenCouldntReachCoach => '无法联系教练。';

  @override
  String get chatScreenExtAboutAiCoach => '关于AI教练';

  @override
  String chatScreenExtAs(Object mealType) {
    return ') 作为 (mealType)';
  }

  @override
  String get chatScreenExtChangeCoach => '更换教练';

  @override
  String get chatScreenExtChatTips => '聊天小贴士';

  @override
  String get chatScreenExtChooseMultiplePhotos => '选择多张照片';

  @override
  String get chatScreenExtChoosePhoto => '选择照片';

  @override
  String get chatScreenExtChooseVideo => '选择视频';

  @override
  String get chatScreenExtClearChatHistory => '清除聊天记录';

  @override
  String get chatScreenExtConnectWithAReal => '联系人工客服';

  @override
  String get chatScreenExtEmailOurSupportTeam => '发送邮件给我们的支持团队';

  @override
  String get chatScreenExtFailedToLogFood => '记录食物失败';

  @override
  String chatScreenExtFailedToSendMedia(Object e) {
    return '发送媒体失败：$e';
  }

  @override
  String chatScreenExtFailedToSendMedia2(Object e) {
    return '发送媒体失败：$e';
  }

  @override
  String chatScreenExtFailedToSendMessage(Object e) {
    return '发送消息失败：$e';
  }

  @override
  String get chatScreenExtRecordVideo => '录制视频';

  @override
  String get chatScreenExtReportAProblem => '报告问题';

  @override
  String get chatScreenExtResetsAtMidnight => '午夜重置';

  @override
  String get chatScreenExtSeeWhatYourAi => '查看你的AI教练能做什么';

  @override
  String get chatScreenExtSwitchToADifferent => '切换到不同的AI教练';

  @override
  String get chatScreenExtTakePhoto => '拍照';

  @override
  String get chatScreenExtTalkToHuman => '联系人工客服';

  @override
  String chatScreenExtThatWasYourLast(Object gateName) {
    return '这是本周期内最后一次免费 $gateName。';
  }

  @override
  String chatScreenExtThatWasYourLast2(Object gateName) {
    return '这是本周期内最后一次免费 $gateName。';
  }

  @override
  String get chatScreenExtTodaySUsage => '今日使用量';

  @override
  String get chatScreenExtUnlimitedAccessWithPremium => '升级至 Premium 即可无限使用';

  @override
  String get chatScreenExtUpgradeForUnlimited => '升级以获取无限使用权限';

  @override
  String chatScreenFailedToSendVoice(Object error) {
    return '语音消息发送失败：$error';
  }

  @override
  String chatScreenMessagesLeftToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今天还剩 $count 条消息',
    );
    return '$_temp0';
  }

  @override
  String get chatScreenMultiAgentHangTight => '多智能体回答可能需要两分钟——请稍候或重试。';

  @override
  String get chatScreenPartAddAMessage => '添加消息...';

  @override
  String get chatScreenPartAddVideo => '添加视频';

  @override
  String get chatScreenPartCheckingAvailability => '正在检查可用性...';

  @override
  String get chatScreenPartChooseVideo => '选择视频';

  @override
  String get chatScreenPartConnect => '连接';

  @override
  String get chatScreenPartFromGalleryMax60s => '从相册选择（最长 60 秒）';

  @override
  String chatScreenPartMediaSendStatusFailedToConnect(Object e) {
    return '连接失败：$e';
  }

  @override
  String chatScreenPartMediaSendStatusPeopleInQueue(Object currentQueueSize) {
    return '排队人数：$currentQueueSize';
  }

  @override
  String get chatScreenPartRecordVideo => '录制视频';

  @override
  String get chatScreenPartSelectACategory => '选择类别：';

  @override
  String get chatScreenPartTalkToHumanSupport => '联系人工客服';

  @override
  String get chatScreenPartUseCameraMax60s => '使用相机（最长 60 秒）';

  @override
  String get chatScreenPartWaitTimeUnavailable => '等待时间不可用';

  @override
  String get chatScreenPartYouWillBeConnected => '您将与真人客服取得联系，他们可以为您解答疑问。';

  @override
  String chatScreenRouteNotRegistered(Object route) {
    return '路由未注册：$route';
  }

  @override
  String get chatScreenSomethingWentWrongLoading => '加载聊天时出错了。';

  @override
  String get chatScreenTyping => '正在输入...';

  @override
  String get chatScreenMastheadTitle => 'Coach';

  @override
  String get chatScreenMastheadSubtitle => 'Your corner, always open.';

  @override
  String get chatScreenMastheadHistory => 'History';

  @override
  String get chatScreenMastheadNew => 'New';

  @override
  String chatScreenMastheadDay(int count) {
    return 'Day $count';
  }

  @override
  String get chatScreenUiConnectionDropped => '连接中断';

  @override
  String get chatScreenUiTyping => '正在输入…';

  @override
  String get chatSearchOverlayNoResultsFound => '未找到结果';

  @override
  String get chatSearchOverlaySearchChat => '搜索聊天';

  @override
  String get chatSearchOverlaySearchMessages => '搜索消息...';

  @override
  String get chatSearchOverlayTypeToSearch => '输入以搜索';

  @override
  String get chatThisMatchIsMissing => '此匹配项缺少练习 ID。';

  @override
  String get chatThisWillDeleteAll => '这将删除您与 AI 教练的所有对话记录。此操作无法撤销。';

  @override
  String get chatYourPersonalAiPowered =>
      '您的专属 AI 健身教练。您可以询问有关训练、营养、恢复或任何健身相关的问题。AI 会根据您的进度学习，为您提供个性化建议。';

  @override
  String get classicStatsTemplateCalories => '卡路里';

  @override
  String get classicStatsTemplateDuration => '时长';

  @override
  String get classicStatsTemplateExercises => '练习';

  @override
  String get classicStatsTemplateVolume => '容量';

  @override
  String get coachAskAnything => '尽管问吧…';

  @override
  String get coachAskYourCoach => '咨询您的教练';

  @override
  String coachBannerOverlayXp(Object xpAwarded) {
    return '+$xpAwarded XP';
  }

  @override
  String get coachDashboardActiveGoals => '当前目标';

  @override
  String get coachDashboardBodyFat => '体脂率';

  @override
  String get coachDashboardFailedToLoadDashboard => '仪表板加载失败';

  @override
  String get coachDashboardReadiness => '准备状态';

  @override
  String coachDashboardScreenValue(Object nutritionPct) {
    return '$nutritionPct%';
  }

  @override
  String coachDashboardScreenValue2(Object pct) {
    return '$pct%';
  }

  @override
  String get coachDashboardThisWeek => '本周';

  @override
  String get coachDashboardTryAgain => '重试';

  @override
  String get coachDashboardWeight => '体重';

  @override
  String get coachHeroCardAlreadyRefreshedInThe => '过去 30 分钟内已刷新。';

  @override
  String get coachHeroCardRethinking => '思考中…';

  @override
  String get coachHeroCardTapToOpenChat => '点击打开聊天。';

  @override
  String get coachHeroCardYourCoach => '您的教练';

  @override
  String get coachHeroCardYourCoachIsGathering => '您的教练正在整理思路。';

  @override
  String get coachHeroCardYourCoachIsHere => '您的教练已就位。';

  @override
  String get coachProfileCardSampleConversation => '对话示例';

  @override
  String get coachReviewApply => '应用';

  @override
  String get coachReviewApplySwapComingWith => '应用替换 — 即将随计划功能集成推出';

  @override
  String get coachReviewCoachReview => '教练评估';

  @override
  String get coachReviewFullFeedback => '完整反馈';

  @override
  String get coachReviewMacroBalance => '宏量营养素平衡';

  @override
  String get coachReviewMicronutrientGaps => '微量营养素缺口';

  @override
  String get coachReviewNoReviewYetTap => '暂无评估 — 点击刷新以生成';

  @override
  String get coachReviewOutOfDate => '已过期';

  @override
  String get coachReviewOverallScore => '总分';

  @override
  String get coachReviewRequestHumanProReview => '申请专业人工评估';

  @override
  String coachReviewSheetAllergenAlert(Object allergenFlags) {
    return '过敏原提醒：$allergenFlags';
  }

  @override
  String coachReviewSheetValue(Object deficitPct) {
    return '$deficitPct%';
  }

  @override
  String coachReviewSheetValue2(Object suggestedLabel, Object targetLabel) {
    return '$targetLabel → $suggestedLabel';
  }

  @override
  String get coachReviewSuggestedSwaps => '建议替换';

  @override
  String get coachReviewTemplateCoachSReview => '教练评估';

  @override
  String get coachReviewTemplateWorkoutReview => '训练评估';

  @override
  String get coachReviewWeLlNotifyYou => '当人工评估功能上线时，我们会通知您。';

  @override
  String get coachSelectionAiGeneratedAvatar => 'AI 生成头像';

  @override
  String get coachSelectionAppearance => '外观';

  @override
  String get coachSelectionBuild => '体型';

  @override
  String get coachSelectionCoachAce => 'Coach Ace';

  @override
  String get coachSelectionCoachingStyle => '执教风格';

  @override
  String get coachSelectionCommunicationTone => '沟通语气';

  @override
  String get coachSelectionCreateYourOwnCoach => '创建您的专属教练';

  @override
  String get coachSelectionCustom => '自定义';

  @override
  String get coachSelectionDesignACoachThat => '设计一位符合您风格的教练';

  @override
  String get coachSelectionEGAtlasRiley => '例如：Atlas, Riley, Sensei';

  @override
  String get coachSelectionEncouragement => '鼓励';

  @override
  String get coachSelectionGender => '性别';

  @override
  String get coachSelectionLetSGoooTime =>
      '冲鸭！是时候去突破自我了！您已经连续坚持 5 天了，我可不会让你中断记录。准备好创造奇迹了吗？';

  @override
  String get coachSelectionLook => '形象';

  @override
  String get coachSelectionMotivationalEncouraging => '激励与鼓励';

  @override
  String get coachSelectionNameYourCoach => '为您的教练命名';

  @override
  String get coachSelectionSampleMessage => '消息示例';

  @override
  String get coachSelectionScreenChangeCoach => '更换教练';

  @override
  String get coachSelectionScreenCreateYourOwnCoach => '创建您的专属教练';

  @override
  String get coachSelectionScreenEnergy => '活力';

  @override
  String get coachSelectionScreenHowTheyTalk => '沟通方式';

  @override
  String get coachSelectionScreenMeetYourCoach => '认识您的教练';

  @override
  String get coachSelectionScreenSaveCoach => '保存教练';

  @override
  String get coachSelectionScreenSelectANewAi => '选择新的 AI 教练人设';

  @override
  String coachSelectionScreenUse(Object _customName) {
    return '使用 $_customName';
  }

  @override
  String get coachSelectionWhatYouLlBe => '您可以自定义的内容';

  @override
  String get coachVoicePicker => '🗣️';

  @override
  String get coachVoicePickerCalmPreciseVoice => '冷静、精准的语音';

  @override
  String get coachVoicePickerCoachChad => 'Chad 教练';

  @override
  String get coachVoicePickerCoachSerena => 'Serena 教练';

  @override
  String get coachVoicePickerCoachVoice => '教练语音';

  @override
  String get coachVoicePickerDeeperHighEnergyVoice => '深沉、高能量的语音';

  @override
  String get coachVoicePickerDefault => '默认';

  @override
  String coachVoicePickerFailedToSwitchVoice(Object error) {
    return '切换语音失败：$error';
  }

  @override
  String get coachVoicePickerPlaysDuringWorkoutAnnouncem => '在训练播报时播放';

  @override
  String get coachVoicePickerUnlocksAtLevel50 => '达到 50 级解锁 — 继续升级吧！';

  @override
  String get coachVoicePickerUnlocksAtLevel502 => '达到 50 级解锁';

  @override
  String get coachVoicePickerYourDeviceSDefault => '您设备的默认语音';

  @override
  String get collapsedBannerStrip2x => '2x';

  @override
  String collapsedBannerStripGoals(Object completedGoals, Object totalGoals) {
    return '$completedGoals/$totalGoals 个目标';
  }

  @override
  String get collapsedBannerStripU00b7 => '·';

  @override
  String get combinedHealthActiveEnergy => '活动能量';

  @override
  String get combinedHealthActiveMinutesGoal => '活动分钟数目标';

  @override
  String get combinedHealthActivityStreak => '活动连胜';

  @override
  String combinedHealthActivityStreakDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连续 $count 天达到或超过步数目标。',
    );
    return '$_temp0';
  }

  @override
  String get combinedHealthCardHealthOverview => '健康概览';

  @override
  String get combinedHealthConnectHealth => '连接健康数据';

  @override
  String get combinedHealthConnectHealthBody =>
      '步数、心率、睡眠等数据通过 Android 的 Health Connect 和 iOS 的健康 App 同步。';

  @override
  String get combinedHealthConnectHealthToSee => '连接健康数据以查看您的活动';

  @override
  String get combinedHealthCouldNotLoadYour => '无法加载您的健康数据。请下拉重试。';

  @override
  String get combinedHealthCouldNotSaveGoal => '无法保存目标。';

  @override
  String get combinedHealthDailyGoals => '每日目标';

  @override
  String get combinedHealthHealth => '健康';

  @override
  String get combinedHealthHitYourStepGoal => '达成步数目标以开启连胜。';

  @override
  String get combinedHealthRestingHeartRate => '静息心率';

  @override
  String get combinedHealthSaving => '保存中…';

  @override
  String combinedHealthScreenBpm(Object restingHeartRate) {
    return '$restingHeartRate bpm';
  }

  @override
  String combinedHealthScreenCal(Object caloriesBurned) {
    return '$caloriesBurned 大卡';
  }

  @override
  String combinedHealthScreenHM(Object day, Object day1) {
    return '$day 小时 $day1 分钟';
  }

  @override
  String combinedHealthScreenMl(Object waterMl) {
    return '$waterMl ml';
  }

  @override
  String get combinedHealthSleep => '睡眠';

  @override
  String get combinedHealthStepGoal => '步数目标';

  @override
  String get combinedHealthSteps => '步数';

  @override
  String get combinedHealthWater => '饮水';

  @override
  String get comebackModeComebackModeReducesSets =>
      '恢复模式会减少组数和强度，以帮助您在休息后避免受伤。';

  @override
  String get comebackModeEaseMeBackIn => '让我循序渐进地恢复';

  @override
  String get comebackModeIMReadyFor => '我已经准备好进行完整训练了';

  @override
  String comebackModeSheetYouHavenTWorked(Object daysSinceLastWorkout) {
    return '你已经 $daysSinceLastWorkout 天没有锻炼了';
  }

  @override
  String get comebackModeWelcomeBack => '欢迎回来！';

  @override
  String get comingSoonActiveChallenges => '活跃挑战';

  @override
  String get comingSoonBeforeAfterProgressComparis => '前后进度对比';

  @override
  String get comingSoonBluetoothHeartRateHardware => '蓝牙心率硬件';

  @override
  String get comingSoonBody => '我们正在开发这个功能,敬请期待。';

  @override
  String get comingSoonBottomComingSoon => '敬请期待';

  @override
  String get comingSoonBottomGotIt => '知道了！';

  @override
  String comingSoonBottomSheetWeeksSessionsPerWeek(
    Object durationWeeks,
    Object sessionsPerWeek,
  ) {
    return '$durationWeeks 周 • 每周 $sessionsPerWeek 次训练';
  }

  @override
  String get comingSoonBottomWhatYouCanExpect => '您可以期待：';

  @override
  String get comingSoonBrowseLikeAndRemix => '浏览、点赞并重组社区分享的食谱。即将随“社交”标签页推出。';

  @override
  String get comingSoonCaloriesSummary => '卡路里摘要';

  @override
  String get comingSoonChallengeProgressMiniCard => '挑战进度迷你卡片';

  @override
  String get comingSoonComingSoon => '敬请期待';

  @override
  String get comingSoonDailyActivity => '每日活动';

  @override
  String get comingSoonDailyStats => '每日统计';

  @override
  String get comingSoonExerciseVariationThisWeek => '本周运动多样性';

  @override
  String get comingSoonFeaturesWeReWorking => '我们正在开发的功能';

  @override
  String get comingSoonFitnessScore => '健身评分';

  @override
  String get comingSoonFoodPreferences => '饮食偏好';

  @override
  String get comingSoonFriendActivity => '好友动态';

  @override
  String get comingSoonHealthDeviceActivitySummary => '健康设备活动摘要';

  @override
  String get comingSoonHolisticPlanWithWorkouts => '包含训练、营养和断食的整体计划';

  @override
  String get comingSoonLeaderboard => '排行榜';

  @override
  String get comingSoonMacroRings => '宏量营养素圆环';

  @override
  String get comingSoonMiniCalendar => '迷你日历';

  @override
  String get comingSoonMiniCalendarWithWorkout => '带有训练日期的迷你日历';

  @override
  String get comingSoonMoodCheckIn => '心情打卡';

  @override
  String get comingSoonMuscleGroupsTrainedRecently => '近期训练的肌肉群';

  @override
  String get comingSoonMuscleHeatmap => '肌肉热力图';

  @override
  String get comingSoonMyJourney => '我的旅程';

  @override
  String get comingSoonOneTapOnYour =>
      '在主屏幕或锁屏点击一次，即可获取包含卡路里和宏量营养素的 AI 饮食建议，并附带“记录”按钮';

  @override
  String get comingSoonOneTapToStart => '一键开始今日训练';

  @override
  String get comingSoonOverallFitnessStrengthNu => '整体健身、力量和营养评分';

  @override
  String get comingSoonOverlayComingSoon => '敬请期待';

  @override
  String get comingSoonPairBleChestStraps => '配对 BLE 胸带和心率监测器，以获取训练期间的实时 BPM';

  @override
  String get comingSoonPhotoCompare => '照片对比';

  @override
  String get comingSoonProgressCharts => '进度图表';

  @override
  String get comingSoonQuickMeasurements => '快速测量';

  @override
  String get comingSoonQuickMoodPickerFor => '用于即时训练的快速心情选择器';

  @override
  String get comingSoonQuickStart => '快速开始';

  @override
  String get comingSoonRecentWeightWithTrend => '带有趋势箭头的近期体重';

  @override
  String get comingSoonRecipeDiscoveryFeed => '食谱发现流';

  @override
  String get comingSoonRecipeImport => '食谱导入';

  @override
  String get comingSoonRecoveryTipsForRest => '休息日的恢复建议';

  @override
  String get comingSoonRestDayTips => '休息日建议';

  @override
  String get comingSoonSearchFeatures => '搜索功能...';

  @override
  String get comingSoonSeeWhatFriendsAre => '查看好友动态';

  @override
  String get comingSoonStepsCountAndCalorie => '步数与热量缺口追踪';

  @override
  String get comingSoonStrengthAndVolumeCharts => '力量与训练容量趋势图';

  @override
  String get comingSoonTheseFeaturesAreIn => '这些功能正在开发中，即将作为可切换的主屏幕小组件推出。';

  @override
  String get comingSoonTitle => '即将推出';

  @override
  String get comingSoonTodaySIntakeVs => '今日摄入量与目标一览';

  @override
  String get comingSoonTotalWorkoutsTimeInvested => '总训练次数、投入时间及里程碑';

  @override
  String get comingSoonTrackBodyMeasurementsEasily => '轻松追踪身体测量数据';

  @override
  String get comingSoonUpcomingHomeWidgets => '即将推出的主屏幕小组件';

  @override
  String get comingSoonVisualDonutChartsFor => '蛋白质、碳水化合物和脂肪的视觉圆环图';

  @override
  String get comingSoonWeekChanges => '周变化';

  @override
  String get comingSoonWeeklyPlan => '周计划';

  @override
  String get comingSoonWeightTracker => '体重追踪器';

  @override
  String get comingSoonWhatShouldIEat => '“我该吃什么？”小组件';

  @override
  String get comingSoonYourFitnessJourneyProgress => '你的健身旅程进度';

  @override
  String get comingSoonYourJourneyRoi => '你的旅程回报率';

  @override
  String get comingSoonYourPositionOnThe => '你在排行榜上的位置';

  @override
  String get commentsAddAComment => '添加评论...';

  @override
  String get commentsAreYouSureYou => '确定要删除这条评论吗？';

  @override
  String get commentsBeTheFirstTo => '成为第一个评论的人！';

  @override
  String get commentsCopyText => '复制文本';

  @override
  String get commentsDeleteComment => '删除评论';

  @override
  String get commentsNoCommentsYet => '暂无评论';

  @override
  String get commitmentPactHoldToCommit => '按住以承诺';

  @override
  String get commitmentPactIMIn => '我加入';

  @override
  String get commitmentPactOneLastThing => '最后一件事。';

  @override
  String get commitmentPactOtherWorkoutDays => '其他训练日';

  @override
  String commitmentPactScreenFirstSession(Object dayLabel) {
    return '首次训练 · $dayLabel';
  }

  @override
  String get commitmentPactSkipAnyway => '仍然跳过';

  @override
  String get commitmentPactSkipTheCommitment => '跳过承诺？';

  @override
  String get commitmentPactWeLlHandleThe => '我们负责制定计划，你负责坚持执行。';

  @override
  String get commonBack => '返回';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClear => '清除';

  @override
  String get commonClose => '关闭';

  @override
  String get commonDelete => '删除';

  @override
  String get commonDone => '完成';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonError => '错误';

  @override
  String get commonLoading => '加载中…';

  @override
  String get commonNew => 'NEW';

  @override
  String get commonNext => '下一步';

  @override
  String get commonShare => '分享';

  @override
  String get commonTryAgain => '重试';

  @override
  String get commonYes => '是';

  @override
  String get commonYou => '你';

  @override
  String get communityRecipeSearchCommunityRecipes => '社区食谱';

  @override
  String get communityRecipeSearchNothingFoundInCommunity => '在社区食谱中未找到相关内容。';

  @override
  String get communityRecipeSearchOpenTheRecipeTo => '打开食谱以保存到你的库中';

  @override
  String get communityRecipeSearchSaveToMyRecipes => '保存到我的食谱';

  @override
  String communityRecipeSearchScreenKcalLogs(
    Object summary,
    Object timesLogged,
  ) {
    return '$summary kcal · $timesLogged次记录';
  }

  @override
  String get communityRecipeSearchSearchPublicRecipes => '搜索公开食谱…';

  @override
  String get communityRecipeSearchSearchPublicRecipesShared => '搜索其他用户分享的公开食谱。';

  @override
  String compactSplitCardDWk(Object daysPerWeek, Object duration) {
    return '(daysPerWeek)天/周 · (duration)';
  }

  @override
  String get compactWorkoutRow => ' • ';

  @override
  String compactWorkoutRowMinExercises(
    Object bestDurationMinutes,
    Object exerciseCount,
  ) {
    return '$bestDurationMinutes 分钟 • $exerciseCount 个动作';
  }

  @override
  String get companionPickerAddAll => '全部添加';

  @override
  String get companionPickerLastTimeYouLogged => '上次你一起记录了这些内容——请仅选择今天适用的项目。';

  @override
  String get companionPickerLogSelected => '记录所选';

  @override
  String get companionPickerPickWhatYouHad => '选择你摄入的内容';

  @override
  String companionPickerSheetCal(Object item) {
    return '$item 卡路里';
  }

  @override
  String companionPickerSheetCal2(Object estCalories) {
    return '$estCalories 卡路里';
  }

  @override
  String companionPickerSheetCal3(Object _selectedCalTotal) {
    return '$_selectedCalTotal 卡路里';
  }

  @override
  String companionPickerSheetCalAlwaysIncluded(Object primaryCalories) {
    return '$primaryCalories 卡路里 — 始终包含';
  }

  @override
  String companionPickerSheetGProtein(Object _selectedProteinTotal) {
    return '· ${_selectedProteinTotal}g 蛋白质';
  }

  @override
  String companionPickerSheetOnItsOwn(Object primaryName) {
    return '单独的 $primaryName。';
  }

  @override
  String companionPickerSheetTypicalCompanionsFor(Object primaryName) {
    return '$primaryName 的典型搭配。';
  }

  @override
  String get comparisonAiSummary => 'AI 总结';

  @override
  String get comparisonAlign => '对齐';

  @override
  String get comparisonBorder => '边框';

  @override
  String get comparisonComparisonSaved => '对比已保存！';

  @override
  String get comparisonCtaLabel => '行动号召标签';

  @override
  String get comparisonDates => '日期';

  @override
  String get comparisonGalleryComparisonDeleted => '对比已删除';

  @override
  String get comparisonGalleryCreateABeforeAfter => '在“照片”选项卡中创建前后对比图，查看你的进步。';

  @override
  String get comparisonGalleryDeleteComparison => '删除对比？';

  @override
  String get comparisonGalleryExportAndShareThis => '导出并分享此对比';

  @override
  String get comparisonGalleryNoComparisonsYet => '暂无对比';

  @override
  String get comparisonGalleryOpen => '打开';

  @override
  String get comparisonGalleryOpenInComparisonEditor => '在对比编辑器中打开';

  @override
  String get comparisonGalleryOpenTheComparisonIn => '请先在编辑器中打开对比图以进行导出和分享。';

  @override
  String get comparisonGalleryReEdit => '重新编辑';

  @override
  String get comparisonGalleryRemoveThisComparison => '移除此对比';

  @override
  String get comparisonGallerySavedComparisons => '已保存的对比';

  @override
  String get comparisonGalleryThisWillPermanentlyRemove =>
      '这将永久删除此对比。原始照片不会被删除。';

  @override
  String comparisonGalleryValue(Object afterDate, Object beforeDate) {
    return '$beforeDate  ->  $afterDate';
  }

  @override
  String get comparisonGap => '间距';

  @override
  String get comparisonGhost => '重影';

  @override
  String get comparisonLogo => '标志';

  @override
  String get comparisonNextCustomize => '下一步：自定义';

  @override
  String get comparisonNextSelectPhotos => '下一步：选择照片';

  @override
  String get comparisonRadius => '圆角';

  @override
  String get comparisonReset => '重置';

  @override
  String get comparisonSeeAll => '查看全部';

  @override
  String get comparisonShape => '形状';

  @override
  String get comparisonStartNow => '立即开始';

  @override
  String get comparisonStats => '统计数据';

  @override
  String get comparisonTemplates => '模板';

  @override
  String get comparisonUsername => '用户名';

  @override
  String comparisonViewComparison(Object displayName) {
    return '$displayName 对比';
  }

  @override
  String get comparisonViewExtAll => '全部';

  @override
  String get comparisonViewExtClear => '清除';

  @override
  String comparisonViewExtSelected(Object length, Object photoCount) {
    return '已选 $length / $photoCount';
  }

  @override
  String comparisonViewExtSelectedPhotos(
    Object length,
    Object maxPhotos,
    Object minPhotos,
  ) {
    return '已选 $length 张（$minPhotos-$maxPhotos 张照片）';
  }

  @override
  String comparisonViewKg(Object weight) {
    return '$weight kg';
  }

  @override
  String get comparisonViewUi2PhotoLayouts => '双图布局';

  @override
  String get comparisonViewUiMultiPhotoLayouts => '多图布局';

  @override
  String get comparisonViewUiMyProgress => '我的进步';

  @override
  String get comparisonViewUiNoPhotosFound => '未找到照片';

  @override
  String get comparisonViewUiNoPhotosSelected => '未选择照片';

  @override
  String comparisonViewUiNoPhotosYetTry(Object displayName) {
    return '暂无 $displayName 照片。请尝试其他筛选条件。';
  }

  @override
  String get comparisonViewUiProgressSummary => '进步总结';

  @override
  String get comparisonViewUiSelect2Photos => '选择 2 张照片';

  @override
  String get comparisonViewUiU00b7 => '  ·  ';

  @override
  String comparisonViewUiValue(Object username) {
    return '@$username';
  }

  @override
  String comparisonViewValue(Object values) {
    return '+$values';
  }

  @override
  String comparisonViewViral(Object length) {
    return '$length 个热门';
  }

  @override
  String get comparisonWeights => '体重';

  @override
  String get comparisonWidth => '宽度';

  @override
  String get completeExtendFailed => '延长训练失败。请重试。';

  @override
  String get completeNoFriendsYet => '还没有好友 — 快去邀请吧！';

  @override
  String get completeNoShareData => '暂无训练数据可分享';

  @override
  String get completePleaseRateWorkout => '请评价您的训练';

  @override
  String get completeUnableToChallenge => '无法开始挑战';

  @override
  String get completeUnableToExtend => '无法延长训练';

  @override
  String get completeViewGoals => '查看目标';

  @override
  String get complianceRingCardAllWorkoutsCompleted => '已完成所有训练';

  @override
  String get complianceRingCardGetStartedToday => '今天开始训练';

  @override
  String complianceRingCardGreatPace(Object arg0) {
    return '进度良好 $arg0';
  }

  @override
  String get complianceRingCardNoWorkoutsScheduledThis => '本周无计划训练';

  @override
  String complianceRingCardOnTrack(Object arg0) {
    return '进度正常 $arg0';
  }

  @override
  String get complianceRingCardWorkoutCompliance => '训练合规度';

  @override
  String complianceRingCardWorkoutsRemaining(Object arg0) {
    return '剩余训练 $arg0';
  }

  @override
  String get comprehensiveStatsStatsScores => '统计与评分';

  @override
  String get connectedAppsAutoImportEvery15 => '每15分钟自动导入';

  @override
  String get connectedAppsConnect => '连接';

  @override
  String get connectedAppsConnectedApps => '已连接的应用';

  @override
  String get connectedAppsDisconnect => '断开连接';

  @override
  String get connectedAppsEnable => '启用';

  @override
  String get connectedAppsIncludeCardioSessions => '包含有氧训练';

  @override
  String get connectedAppsIncludeStrengthWorkouts => '包含力量训练';

  @override
  String get connectedAppsNoSyncYetWill => '尚未同步 — 将在15分钟内运行。';

  @override
  String get connectedAppsReconnect => '重新连接';

  @override
  String connectedAppsScreenDisconnect(Object displayName) {
    return '断开 $displayName 连接？';
  }

  @override
  String connectedAppsScreenPreviouslyImportedActivitiesWill(Object appName) {
    return '之前导入的活动将保留在您的 $appName 历史记录中。';
  }

  @override
  String connectedAppsScreenRidesAndWorkoutsData(Object appName) {
    return '骑行和训练数据。数据双向同步 — $appName 训练可以';
  }

  @override
  String connectedAppsScreenSignInTo(Object displayName) {
    return '登录 $displayName';
  }

  @override
  String get connectedAppsSyncNow => '立即同步';

  @override
  String get consistencyCardConsistency => '持续性';

  @override
  String get consistencyCardDayBestNstreak => '最佳天数\n连续记录';

  @override
  String get consistencyCardOfDaysYouShowed => '你已坚持的天数';

  @override
  String consistencyCardValue(Object workoutConsistencyPct) {
    return '$workoutConsistencyPct%';
  }

  @override
  String get consistencyConsistency => '持续性';

  @override
  String get consistencyDayStreak => '连续天数';

  @override
  String get consistencyFailedToLoadData => '数据加载失败';

  @override
  String get consistencyFullWorkout => '完整训练';

  @override
  String get consistencyInsightCardDayStreak => '天连续记录';

  @override
  String get consistencyInsightCardStartFreshToday => '今天重新开始！';

  @override
  String get consistencyInsightCardStreak => '连续记录';

  @override
  String get consistencyInsightCardTapToBeginA => '点击开启新的连续记录';

  @override
  String get consistencyInsightCardTapToRefresh => '点击刷新';

  @override
  String get consistencyLast4Weeks => '过去4周';

  @override
  String get consistencyQuick15min => '15分钟快速训练';

  @override
  String get consistencyScoreCardConsistencyScore => '持续性评分';

  @override
  String consistencyScoreCardDays(Object currentStreakValue) {
    return '$currentStreakValue 天';
  }

  @override
  String get consistencyScoreCardPrs30d => 'PR (30天)';

  @override
  String get consistencyScoreCardStreak => '连续记录';

  @override
  String get consistencyScoreCardThisWeek => '本周';

  @override
  String consistencyScoreCardValue(Object consistencyScore) {
    return '$consistencyScore%';
  }

  @override
  String get consistencyScoreCardWorkoutCompletionRate => '训练完成率';

  @override
  String consistencyScreenAverageWeeklyCompletion(Object avgRate) {
    return '平均: $avgRate% 每周完成率';
  }

  @override
  String consistencyScreenCompletionRate(Object rate) {
    return '$rate% 完成率';
  }

  @override
  String consistencyScreenLongestDays(Object longestStreak) {
    return '最长: $longestStreak 天';
  }

  @override
  String consistencyScreenOfWorkouts(Object scheduled) {
    return '共 $scheduled 次训练';
  }

  @override
  String get consistencyStartFreshToday => '今天重新开始！';

  @override
  String get consistencyThisMonth => '本月';

  @override
  String get consistencyThisWeek => '本周';

  @override
  String get consistencyTryAgain => '重试';

  @override
  String get consistencyWeeklyTrend => '每周趋势';

  @override
  String get consistencyWorkoutPatterns => '训练模式';

  @override
  String contextualBannerFastingWindowEndsIn(Object timeStr) {
    return '断食窗口将在 $timeStr 后结束';
  }

  @override
  String get contextualBannerKeepItUp => '继续保持！';

  @override
  String contextualBannerLbs(Object exerciseName, Object weightLbs) {
    return '$exerciseName: $weightLbs lbs';
  }

  @override
  String get contextualBannerNewPr => '新PR！';

  @override
  String contextualBannerYouReAwayFrom(Object remaining, Object workoutWord) {
    return '距离本周目标还差 $remaining $workoutWord';
  }

  @override
  String get contributeFoodDataCouldNotDeletePlease => '无法删除 — 请重试';

  @override
  String get contributeFoodDataDeleteFoodContributions => '删除食物贡献？';

  @override
  String get contributeFoodDataDeleteMyFoodContributions => '删除我的食物贡献';

  @override
  String get contributeFoodDataHelpImproveNutritionData => '帮助完善营养数据';

  @override
  String get contributeFoodDataNoContributionsToDelete => '没有可删除的贡献';

  @override
  String get contributeFoodDataSharingNovelDishesRecommen => '分享新菜品（推荐）';

  @override
  String get conversationEncrypted => '已加密';

  @override
  String get conversationFailedToLoadMessages => '消息加载失败';

  @override
  String get conversationFailedToSendMessage => '消息发送失败';

  @override
  String get conversationNoMessagesYet => '暂无消息';

  @override
  String get conversationNotLoggedIn => '未登录';

  @override
  String get conversationRead => '已读';

  @override
  String conversationScreenIsTyping(Object first) {
    return '$first 正在输入...';
  }

  @override
  String conversationScreenPeopleTyping(Object length) {
    return '$length 人正在输入...';
  }

  @override
  String get conversationSendTheFirstMessage => '发送第一条消息！';

  @override
  String get conversationSomeMessagesWereEncrypted => '部分消息在其他设备上已加密，无法在此处读取。';

  @override
  String get conversationTypeAMessage => '输入消息...';

  @override
  String get cookingConverterConvertBetweenRawAnd => '转换生食与熟食重量';

  @override
  String get cookingConverterCooked => '熟食';

  @override
  String get cookingConverterCookedRaw => '熟食 → 生食';

  @override
  String get cookingConverterCookingConverter => '烹饪转换器';

  @override
  String cookingConverterEnterWeight(Object type) {
    return '输入 $type 重量';
  }

  @override
  String get cookingConverterNoFoodsFound => '未找到食物';

  @override
  String get cookingConverterRaw => '生食';

  @override
  String get cookingConverterRawCooked => '生食 → 熟食';

  @override
  String get cookingConverterSearchFoods => '搜索食物...';

  @override
  String get cookingConverterSelectFood => '选择食物';

  @override
  String cookingConverterSheetG(Object inputAmount) {
    return '${inputAmount}g';
  }

  @override
  String get cookingConverterUseThisValue => '使用此数值';

  @override
  String get cookingConverterWeight => ') 重量';

  @override
  String get cosmeticsGalleryCosmetics => '装饰';

  @override
  String get cosmeticsGalleryEquip => '装备';

  @override
  String get cosmeticsGalleryEquipped => '已装备';

  @override
  String get cosmeticsGalleryFailedToLoadCosmetics => '装饰加载失败';

  @override
  String get cosmeticsGalleryNoBadgeEquipped => '未装备徽章';

  @override
  String cosmeticsGalleryScreenFrame(Object displayName) {
    return '$displayName 边框';
  }

  @override
  String cosmeticsGalleryScreenUnlocksAtLevel(Object unlockLevel) {
    return '等级 $unlockLevel 解锁';
  }

  @override
  String get cosmeticsGalleryYourLoadout => '你的装备';

  @override
  String get createChallengeAnyoneCanDiscoverAnd => '任何人都可以发现并加入';

  @override
  String get createChallengeChallengeType => '挑战类型';

  @override
  String get createChallengeCreateChallenge => '创建挑战';

  @override
  String get createChallengeDescribeTheChallenge => '描述挑战内容...';

  @override
  String get createChallengeDescriptionOptional => '描述（可选）';

  @override
  String get createChallengeEG30 => '例如：30';

  @override
  String get createChallengeEG30Day => '例如：30天训练打卡';

  @override
  String get createChallengeEGWorkouts => '例如：训练';

  @override
  String get createChallengeEndDate => '结束日期';

  @override
  String get createChallengePublicChallenge => '公开挑战';

  @override
  String get createChallengeStartDate => '开始日期';

  @override
  String get createChallengeUnit => '单位';

  @override
  String get createExerciseAdd => '添加';

  @override
  String get createExerciseAddAtLeast2 => '至少添加 2 个动作';

  @override
  String get createExerciseAddExercise => '添加动作';

  @override
  String get createExerciseAddPhoto => '添加照片';

  @override
  String get createExerciseAdvancedOptional => '进阶（可选）';

  @override
  String get createExerciseAiFilledExerciseDetails => 'AI 已填充动作详情 — 请检查并保存';

  @override
  String get createExerciseAnalyzeWithAi => '使用 AI 分析';

  @override
  String get createExerciseAnalyzing => '分析中...';

  @override
  String get createExerciseAnySpecialInstructions => '任何特别说明...';

  @override
  String get createExerciseBand => '弹力带';

  @override
  String get createExerciseChooseFromGallery => '从相册选择';

  @override
  String get createExerciseCombo => '组合';

  @override
  String get createExerciseCreateExercise => '创建动作';

  @override
  String get createExerciseDescribeHowToPerform => '描述如何执行此动作...';

  @override
  String get createExerciseEGBenchPress => '例如：卧推与胸部飞鸟超级组';

  @override
  String get createExerciseEGBenchPress2 => '例如：卧推';

  @override
  String get createExerciseEGFocusOn => '例如：专注于顶峰收缩，缓慢离心';

  @override
  String get createExerciseEGMyCustom => '例如：我的自定义推举';

  @override
  String get createExerciseExerciseName => '动作名称';

  @override
  String get createExerciseNotes => '备注';

  @override
  String get createExerciseReps => '次数：';

  @override
  String get createExerciseRestRpeTempoIncline => '休息、RPE、节奏、坡度、距离、时长、备注';

  @override
  String createExerciseSheetAddMoreExercises(Object length) {
    return '再添加 $length 个动作';
  }

  @override
  String createExerciseSheetExercises(Object length) {
    return '动作 ($length)';
  }

  @override
  String createExerciseSheetFailedToAnalyzePhoto(Object e) {
    return '照片分析失败: $e';
  }

  @override
  String get createExerciseSimple => '简单';

  @override
  String get createExerciseTakePhoto => '拍照';

  @override
  String get createGoalChallengeYourselfToBeat => '挑战自我，打破个人纪录！';

  @override
  String get createGoalExercise => '动作';

  @override
  String get createGoalGoalType => '目标类型';

  @override
  String get createGoalMaxReps => '最大次数';

  @override
  String get createGoalOneSetMaxEffort => '单组最大努力';

  @override
  String get createGoalOrTypeCustomExercise => '或输入自定义动作...';

  @override
  String get createGoalPleaseEnterAValid => '请输入有效目标';

  @override
  String get createGoalPleaseEnterAnExercise => '请输入动作名称';

  @override
  String get createGoalSetGoal => '设定目标';

  @override
  String get createGoalSetWeeklyGoal => '设定每周目标';

  @override
  String createGoalSheetTargetBestInOne(Object fullLabel) {
    return '目标 $fullLabel（单次训练最佳）';
  }

  @override
  String createGoalSheetTargetTotalThisWeek(Object fullLabel) {
    return '目标 $fullLabel（本周总计）';
  }

  @override
  String get createGoalTotalRepsThisWeek => '本周总次数';

  @override
  String get createGoalUnit => '单位';

  @override
  String get createGoalWeeklyVolume => '每周容量';

  @override
  String get createHabitBreak => '戒除';

  @override
  String get createHabitBuild => '养成';

  @override
  String get createHabitCategory => '类别';

  @override
  String get createHabitColor => '颜色';

  @override
  String get createHabitCreateHabit => '创建习惯';

  @override
  String get createHabitDescriptionOptional => '描述（可选）';

  @override
  String get createHabitEG8 => '例如：8';

  @override
  String get createHabitEGDrink8 => '例如：喝 8 杯水';

  @override
  String get createHabitEGGlasses => '例如：杯';

  @override
  String get createHabitEditHabit => '编辑习惯';

  @override
  String get createHabitFrequency => '频率';

  @override
  String get createHabitHabitName => '习惯名称';

  @override
  String get createHabitHabitType => '习惯类型';

  @override
  String get createHabitSaveChanges => '保存更改';

  @override
  String get createHabitTargetOptional => '目标（可选）';

  @override
  String get createHabitUnitOptional => '单位（可选）';

  @override
  String get createPostEditPost => '编辑帖子';

  @override
  String get createPostHideExercises => '隐藏动作';

  @override
  String get createPostPost => '发布';

  @override
  String get createPostSheetAddMore => '添加更多';

  @override
  String get createPostSheetCamera => '相机';

  @override
  String get createPostSheetCaption => '说明';

  @override
  String get createPostSheetGallery => '相册';

  @override
  String get createPostSheetMediaOptional => '媒体（可选）';

  @override
  String get createPostSheetShareYourFitnessJourney => '分享你的健身旅程...';

  @override
  String get createPostSheetTrending => '热门';

  @override
  String get createPostSheetVideo => '视频';

  @override
  String get createPostShowExercises => '显示动作';

  @override
  String get createPostTags => '标签';

  @override
  String get createPostWhoCanSeeThis => '谁可以看到此内容？';

  @override
  String get createPostWorkoutStats => '训练统计';

  @override
  String credibilityStripJoinPeopleTrainingWith(Object formatted) {
    return '加入 $formatted+ 位正在使用 Zealova 训练的用户';
  }

  @override
  String credibilityStripRatings(Object count, Object rating) {
    return '$rating · $count 条评分';
  }

  @override
  String credibilityStripValue(Object quote) {
    return '“$quote”';
  }

  @override
  String get customCoachFormCoachName => '教练名称';

  @override
  String get customCoachFormCoachingStyle => '执教风格';

  @override
  String get customCoachFormCommunicationTone => '沟通语气';

  @override
  String get customCoachFormEGMyCoach => '例如：我的教练、Ace 等';

  @override
  String get customCoachFormEncouragementLevel => '鼓励程度';

  @override
  String get customCoachFormMaximum => '最高';

  @override
  String get customCoachFormMinimal => '最低';

  @override
  String customColorLabCardMatched(Object displayName) {
    return '匹配: $displayName';
  }

  @override
  String get customColorLabCustomColorLab => '自定义颜色实验室';

  @override
  String get customColorLabFineTuneAccentColor => '使用 HSV 取色器微调强调色';

  @override
  String get customContentAddYourOwnEquipment => '添加你自己的器械和动作';

  @override
  String get customContentMyCustomContent => '我的自定义内容';

  @override
  String get customContentSectionAdd => '添加';

  @override
  String get customContentSectionAddCustomExercise => '添加自定义动作';

  @override
  String get customContentSectionAddEquipmentAboveTo => '添加上方器械以开始';

  @override
  String get customContentSectionAddEquipmentNotIn => '添加标准列表中没有的器械';

  @override
  String get customContentSectionAddEquipmentThatWill => '添加生成训练计划时将使用的器械。';

  @override
  String get customContentSectionAddExercise => '添加动作';

  @override
  String get customContentSectionCompoundExercise => '复合动作';

  @override
  String get customContentSectionCreateCustomComboExercise => '创建自定义及组合动作';

  @override
  String get customContentSectionCreateExercisesThatCan =>
      '创建可包含在 AI 生成训练中的动作。';

  @override
  String get customContentSectionDeleteExercise => '删除动作？';

  @override
  String get customContentSectionDescribeHowToPerform => '描述如何执行...';

  @override
  String get customContentSectionEGPikePush => '例如：派克俯卧撑';

  @override
  String get customContentSectionEnterEquipmentName => '输入器械名称...';

  @override
  String get customContentSectionFailedToLoadExercises => '加载动作失败';

  @override
  String get customContentSectionInstructionsOptional => '说明（可选）';

  @override
  String get customContentSectionMyCustomEquipment => '我的自定义器械';

  @override
  String get customContentSectionMyCustomExercises => '我的自定义动作';

  @override
  String get customContentSectionMyEquipment => '我的器械';

  @override
  String get customContentSectionMyExercises => '我的动作';

  @override
  String get customContentSectionNoCustomEquipmentYet => '暂无自定义器械';

  @override
  String get customContentSectionNoCustomExercisesYet => '暂无自定义动作';

  @override
  String customContentSectionPartCustomContentCardAddedToYourEquipment(
    Object trimmed,
  ) {
    return '已将“$trimmed”添加到您的器械中';
  }

  @override
  String customContentSectionPartCustomContentCardAreYouSureYou(Object name) {
    return '确定要删除“$name”吗？';
  }

  @override
  String customContentSectionPartCustomContentCardDeleted(Object name) {
    return '已删除“$name”';
  }

  @override
  String customContentSectionPartCustomContentCardFailedToSave(Object e) {
    return '保存失败：$e';
  }

  @override
  String customContentSectionPartCustomContentCardIsAlreadyInYour(
    Object trimmed,
  ) {
    return '$trimmed 已在您的列表中';
  }

  @override
  String customContentSectionPartCustomContentCardRemoved(Object name) {
    return '已移除“$name”';
  }

  @override
  String get customContentSectionReps => '次数';

  @override
  String get customContentSectionSets => '组数';

  @override
  String get customContentSectionTapTheButtonAbove => '点击上方按钮创建一个';

  @override
  String get customContentSectionTargetsMultipleMuscleGroups => '针对多个肌肉群';

  @override
  String get customExerciseCard => ' • ';

  @override
  String customExerciseCardExercises(Object componentCount) {
    return '$componentCount 个动作';
  }

  @override
  String customExerciseCardUsedTimes(Object usageCount) {
    return '已使用 $usageCount 次';
  }

  @override
  String get customExercisesAll => '全部';

  @override
  String get customExercisesCombos => '组合';

  @override
  String get customExercisesComponents => '组件';

  @override
  String get customExercisesCreate => '创建';

  @override
  String get customExercisesDeleteExercise => '删除动作';

  @override
  String get customExercisesMyExercises => '我的动作';

  @override
  String get customExercisesNoExercisesMatchYour => '没有匹配搜索的动作';

  @override
  String customExercisesScreenAreYouSureYou(Object name) {
    return '确定要删除 “$name” 吗？此操作无法撤销。';
  }

  @override
  String customExercisesScreenExercisesUses(
    Object totalCustomExercises,
    Object totalUses,
  ) {
    return '$totalCustomExercises 个动作，$totalUses 次使用';
  }

  @override
  String customExercisesScreenUsedTimes(
    Object lastUsedFormatted,
    Object usageCount,
  ) {
    return '已使用 (usageCount) 次(lastUsedFormatted)\" : \"\")';
  }

  @override
  String customExercisesScreenValue(Object name, Object targetDisplay) {
    return '(name) (targetDisplay))\" : \"\")';
  }

  @override
  String get customExercisesSearchExercises => '搜索动作...';

  @override
  String get customExercisesSimple => '简单';

  @override
  String get customFoodBuilderAiFillFromName => 'AI 根据名称填充';

  @override
  String get customFoodBuilderAiIsSuggesting => 'AI 正在建议…';

  @override
  String get customFoodBuilderAlreadyInYourLibrary => '已在你的库中';

  @override
  String get customFoodBuilderBrandOptional => '品牌（可选）';

  @override
  String get customFoodBuilderCreateCustomFood => '创建自定义食物';

  @override
  String get customFoodBuilderCreateNewAnyway => '仍然创建新食物';

  @override
  String get customFoodBuilderFillItInYourself =>
      '你可以自行填写，或让 AI 根据名称或标签照片进行建议。所有数值均可编辑。';

  @override
  String get customFoodBuilderLabelFromPhotos => '从照片获取标签';

  @override
  String get customFoodBuilderName => '名称';

  @override
  String get customFoodBuilderSaveCustomFood => '保存自定义食物';

  @override
  String get customFoodBuilderScanLabel => '扫描标签';

  @override
  String get customFoodBuilderServingOptional => '份量（可选）';

  @override
  String customFoodBuilderSheetAlreadyExistsAsA(Object name) {
    return '“$name”已作为自定义食物存在';
  }

  @override
  String customFoodBuilderSheetNeedsEntry(Object label) {
    return '$label • 需要输入';
  }

  @override
  String get customFoodBuilderUseExisting => '使用现有';

  @override
  String get customGoalsAddSpecificSkillsOr =>
      '添加你想要提升的具体技能或目标。\nAI 将帮助找到合适的动作。';

  @override
  String get customGoalsAiGeneratedKeywords => 'AI 生成的关键词';

  @override
  String get customGoalsCustomGoals => '自定义目标';

  @override
  String get customGoalsDeleteGoal => '删除目标？';

  @override
  String get customGoalsEGImproveBox => '例如：“提高箱式跳跃高度”';

  @override
  String get customGoalsGoalCreated => '目标已创建！';

  @override
  String get customGoalsGotIt => '知道了';

  @override
  String get customGoalsNoCustomGoalsYet => '暂无自定义目标';

  @override
  String customGoalsScreenAreYouSureYou(Object goalText) {
    return '确定要删除“$goalText”吗？';
  }

  @override
  String get customGoalsSomethingWentWrong => '出错了';

  @override
  String get customGoalsTheseKeywordsWillHelp => '这些关键词将有助于找到与你目标相关的动作。';

  @override
  String get customTrendAddMetric => '添加指标';

  @override
  String get customTrendAlreadySaved => '已保存';

  @override
  String get customTrendCompareLastCycle => '对比上一周期';

  @override
  String get customTrendCompareLastCycleNeeds => '对比上一周期 · 需要范围内 ≥ 2 个周期';

  @override
  String get customTrendCustomTrendSaved => '自定义趋势已保存';

  @override
  String get customTrendCustomTrends => '自定义趋势';

  @override
  String get customTrendCyclePhases => '周期阶段';

  @override
  String get customTrendSaveThisTrend => '保存此趋势';

  @override
  String customTrendScreenCorrelationVs(Object displayName) {
    return '与 $displayName 的相关性';
  }

  @override
  String customTrendScreenCouldnTLoad(Object name) {
    return '无法加载 $name';
  }

  @override
  String customTrendScreenLastCycle(Object displayName) {
    return '$displayName · 上个周期';
  }

  @override
  String customTrendScreenMaxOverlaysRemoveOne(Object _kMaxOverlays) {
    return '最多 $_kMaxOverlays 个叠加层 — 请移除一个后再添加';
  }

  @override
  String customTrendScreenSharedDays(
    Object kMinCorrelationPairs,
    Object pairedPoints,
  ) {
    return '$pairedPoints/$kMinCorrelationPairs 个共同记录日';
  }

  @override
  String customTrendScreenValue(Object strengthLabel, Object value) {
    return ')(value) · (strengthLabel)';
  }

  @override
  String get customWorkoutBuilderAddExercise => '添加动作';

  @override
  String get customWorkoutBuilderBuildCustomWorkout => '构建自定义训练';

  @override
  String get customWorkoutBuilderCustomWorkoutCreated => '自定义训练已创建！';

  @override
  String get customWorkoutBuilderDifficulty => '难度';

  @override
  String get customWorkoutBuilderExercise => '动作';

  @override
  String get customWorkoutBuilderFailedToCreateWorkout => '创建训练失败';

  @override
  String get customWorkoutBuilderNoExercisesAddedYet => '尚未添加动作';

  @override
  String get customWorkoutBuilderPleaseAddAtLeast => '请至少添加一个动作';

  @override
  String get customWorkoutBuilderPleaseEnterAWorkout => '请输入训练名称';

  @override
  String get customWorkoutBuilderReps => '次数';

  @override
  String get customWorkoutBuilderScheduleFor => '安排在';

  @override
  String customWorkoutBuilderScreenExercises(Object length) {
    return '训练动作 ($length)';
  }

  @override
  String customWorkoutBuilderScreenIsAlreadyInYour(Object name) {
    return '$name 已在你的训练计划中';
  }

  @override
  String get customWorkoutBuilderSearchExercises => '搜索动作...';

  @override
  String get customWorkoutBuilderSets => '组数';

  @override
  String get customWorkoutBuilderTapTheButtonBelow => '点击下方按钮添加动作';

  @override
  String get customWorkoutBuilderWeightKg => '重量 (kg)';

  @override
  String get customWorkoutBuilderWorkoutName => '训练名称';

  @override
  String get customWorkoutBuilderWorkoutType => '训练类型';

  @override
  String get customizeRingsAdd => '添加';

  @override
  String get customizeRingsCore => '核心';

  @override
  String get customizeRingsCustomizeYourRings => '自定义圆环';

  @override
  String get customizeRingsResetToDefault => '恢复默认';

  @override
  String get cycleAiInsightTellMeMore => '了解更多';

  @override
  String get cycleAskYourCycleCoach => '咨询您的周期教练';

  @override
  String get cycleCalendar => '日历';

  @override
  String get cycleConceptionMeterChanceOfConception => '受孕几率';

  @override
  String get cycleCycle => '周期';

  @override
  String get cycleDayDetailAskCoach => '咨询教练';

  @override
  String get cycleDayDetailEditThisDay => '编辑本日';

  @override
  String cycleDayDetailSheetPhase(Object displayName) {
    return '$displayName 阶段';
  }

  @override
  String get cycleDayDetailThisDayIsIn => '这一天在未来。';

  @override
  String get cycleDisclaimerBeforeYouStart => '开始之前';

  @override
  String get cycleInsights => '洞察';

  @override
  String get cycleInsightsChartsAsk => '咨询';

  @override
  String get cycleInsightsChartsCycleLengthHistory => '周期长度历史';

  @override
  String get cycleInsightsChartsCycleStats => '周期统计';

  @override
  String cycleInsightsChartsD(Object days) {
    return '$days 天';
  }

  @override
  String cycleInsightsChartsDays(Object stddev) {
    return '(±$stddev 天)。';
  }

  @override
  String cycleInsightsChartsDaysVariability(Object avg) {
    return '$avg 天，波动 ';
  }

  @override
  String cycleInsightsChartsMyCycleStatsCycles(Object cyclesTracked) {
    return '我的周期统计 — 已追踪 $cyclesTracked 个周期，';
  }

  @override
  String get cycleInsightsChartsPhaseDistribution => '阶段分布';

  @override
  String get cycleInsightsChartsSymptomPatterns => '症状模式';

  @override
  String cycleInsightsChartsValue(Object pct) {
    return '$pct%';
  }

  @override
  String get cycleMonthlySummaryThisRecapStaysPrivate =>
      '此回顾仅您可见 — 周期数据绝不会被共享。';

  @override
  String get cycleMonthlySummaryYourMonthInReview => '月度回顾';

  @override
  String get cycleOnboardingGeneralTracking => '常规追踪';

  @override
  String cycleOnboardingSheetDays(Object _cycleLength) {
    return '$_cycleLength 天';
  }

  @override
  String cycleOnboardingSheetDays2(Object _periodLength) {
    return '$_periodLength 天';
  }

  @override
  String get cycleOnboardingStartTracking => '开始追踪';

  @override
  String get cycleOnboardingTrackYourCycle => '追踪您的周期';

  @override
  String get cycleOnboardingTryingToConceive => '尝试受孕';

  @override
  String get cycleOnboardingTypicalCycleLength => '典型周期长度';

  @override
  String get cycleOnboardingTypicalPeriodLength => '典型经期长度';

  @override
  String get cycleOpen => '打开';

  @override
  String get cyclePeriodSavedYourCoach => '经期已保存 — 您的教练已刷新您的洞察';

  @override
  String get cyclePhaseChartGotIt => '知道了';

  @override
  String get cyclePhaseRingAskCoachAboutThis => '咨询教练关于此项的内容';

  @override
  String cyclePhaseRingCycleDay(Object day) {
    return '周期第 $day 天';
  }

  @override
  String cyclePhaseRingEstimate(Object cycleConfidence) {
    return '$cycleConfidence · 预估';
  }

  @override
  String get cyclePhaseRingNoData => '暂无数据';

  @override
  String cycleScreenCouldNotSwitchMode(Object e) {
    return '无法切换模式：$e';
  }

  @override
  String cycleScreenIJustLoggedMy(Object what) {
    return '我刚刚记录了 $what。有什么我需要注意的吗？';
  }

  @override
  String cycleScreenSwitchedTo(Object displayName) {
    return '已切换至 $displayName';
  }

  @override
  String get cycleScreenUiCheckYourConnectionAnd => '请检查您的网络连接并重试。';

  @override
  String get cycleScreenUiCouldnTLoadYour => '无法加载您的周期数据';

  @override
  String get cycleScreenUiDailyCheckIn => '每日打卡';

  @override
  String get cycleScreenUiLogAPeriod => '记录经期';

  @override
  String get cycleScreenUiLogPeriod => '记录经期';

  @override
  String get cycleScreenUiLogYourFirstPeriod => '记录你的第一次月经以开始预测。';

  @override
  String get cycleScreenUiPhase => ') 阶段';

  @override
  String cycleScreenUiPhaseLabel(Object displayName) {
    return '$displayName 阶段';
  }

  @override
  String get cycleScreenUiPredictionsAreEstimates =>
      '预测结果基于你的记录数据，仅供参考，并非避孕方法，也不构成医疗建议。如有健康顾虑，请咨询医生。';

  @override
  String get cycleScreenUiPregnancyModeIsOn => '孕期模式已开启';

  @override
  String get cycleScreenUiRetry => '重试';

  @override
  String get cycleScreenUiStartTracking => '开始追踪';

  @override
  String cycleScreenUiSuggestedTraining(Object intensity) {
    return '建议训练：$intensity';
  }

  @override
  String get cycleSettingsAMorningNudgeTo => '早晨提醒记录 BBT';

  @override
  String get cycleSettingsAnEveningNudgeTo => '晚间提醒记录身体感受';

  @override
  String get cycleSettingsBestTakenBeforeGetting => '最好在起床前测量';

  @override
  String get cycleSettingsCalendarPredictionsLogging => '日历、预测、记录和洞察';

  @override
  String get cycleSettingsCheckInTime => '打卡时间';

  @override
  String get cycleSettingsCycle => '周期';

  @override
  String get cycleSettingsCycleAwarePhotoReminders => '周期感知照片提醒';

  @override
  String get cycleSettingsCycleReminders => '周期提醒';

  @override
  String get cycleSettingsCycleTracking => '周期追踪';

  @override
  String get cycleSettingsDailyTemperatureReminder => '每日体温提醒';

  @override
  String get cycleSettingsDaysBefore => '天前';

  @override
  String get cycleSettingsFertileWindow => '易孕期';

  @override
  String get cycleSettingsMasterSwitchForAll => '所有周期通知的总开关';

  @override
  String get cycleSettingsOnYourPredictedPeriod => '在预测的经期开始日';

  @override
  String get cycleSettingsOpenCycle => '打开周期';

  @override
  String get cycleSettingsPeakFertility => '排卵高峰期';

  @override
  String get cycleSettingsPeriodApproaching => '经期临近';

  @override
  String get cycleSettingsPeriodRunningLate => '经期推迟';

  @override
  String get cycleSettingsPeriodStartDay => '经期开始日';

  @override
  String get cycleSettingsReminderTime => '提醒时间';

  @override
  String cycleSettingsScreenAHeadsUp(Object cyclePeriodApproachingLeadDays) {
    return '提醒 $cyclePeriodApproachingLeadDays ';
  }

  @override
  String get cycleSettingsSymptomCheckIn => '症状打卡';

  @override
  String get cycleSettingsTemperatureReminderTime => '体温提醒时间';

  @override
  String get cycleSettingsWhenTheRemindersAbove => '上述提醒的发送时间';

  @override
  String get cycleSetupHomeDismiss => '忽略';

  @override
  String get cycleSetupHomeSetUp => '设置';

  @override
  String get cycleSetupHomeTrackYourCycle => '追踪您的周期';

  @override
  String get cycleStatusCardCycle => '周期';

  @override
  String get cycleStatusCardCycleTracking => '周期追踪';

  @override
  String cycleStatusCardDay(Object day) {
    return '· 第$day天';
  }

  @override
  String get cycleStatusCardLogPeriod => '记录经期';

  @override
  String get cycleStatusCardViewCycle => '查看周期';

  @override
  String get cycleSuggestedChipsAskYourCoach => '咨询您的教练';

  @override
  String get cycleSwitchHowTheCycle => '切换周期界面的工作方式以匹配您当前的状态。';

  @override
  String get cycleTemperatureChartAsk => '咨询';

  @override
  String get cycleTemperatureChartBasalTemperature => '基础体温';

  @override
  String get cycleTemperatureChartDragAcrossTheChart => '在图表上拖动以查看任意日期';

  @override
  String get cycleTemperatureChartLogBasalTemperatureTo => '记录基础体温以填充此图表';

  @override
  String get cycleToday => '今天';

  @override
  String get cycleTrackerCycleTracker => '周期追踪器';

  @override
  String get cycleTrackerDay1 => '第 1 天';

  @override
  String get cycleTrackerLogPeriod => '记录经期';

  @override
  String cycleTrackerWidgetDay(Object cycleLength) {
    return '第 $cycleLength 天';
  }

  @override
  String cycleTrackerWidgetValue(Object label) {
    return '$label：';
  }

  @override
  String get cycleTrackingMode => '追踪模式';

  @override
  String get dailyActivityCardActiveCal => '活动热量';

  @override
  String dailyActivityCardConnectToSeeSteps(Object healthName) {
    return '连接 $healthName 以查看步数、卡路里及更多信息';
  }

  @override
  String get dailyActivityCardDailyGoal => '每日目标';

  @override
  String get dailyActivityCardFromAppleHealth => '来自 Apple Health';

  @override
  String get dailyActivityCardFromHealthConnect => '来自 Health Connect';

  @override
  String get dailyActivityCardRestingHr => '静息心率';

  @override
  String get dailyActivityCardSteps => '步数';

  @override
  String get dailyActivityCardTodaySActivity => '今日活动';

  @override
  String get dailyActivityCardTrackYourActivity => '追踪您的活动';

  @override
  String get dailyCalories => '热量';

  @override
  String get dailyCarbohydrates => '碳水化合物';

  @override
  String get dailyCookedDish => '烹饪菜肴';

  @override
  String get dailyCrateBannerActivityCrate => '活动宝箱';

  @override
  String get dailyCrateBannerBasicRewards => '基础奖励';

  @override
  String get dailyCrateBannerChoose1CrateTo => '选择 1 个宝箱在今天开启';

  @override
  String get dailyCrateBannerDailyCrate => '每日宝箱';

  @override
  String get dailyCrateBannerDailyCratesAvailable => '有可用的每日宝箱！';

  @override
  String get dailyCrateBannerFailedToClaimCrate => '领取宝箱失败';

  @override
  String get dailyCrateBannerPickYourDailyCrate => '🎁 选择您的每日宝箱';

  @override
  String get dailyCrateBannerStreakCrate => '连胜宝箱';

  @override
  String get dailyCrateBannerTapToPickYour => '点击选择您的奖励';

  @override
  String get dailyEditGoalsInSettings => '在设置中编辑目标';

  @override
  String get dailyExpired => '已过期';

  @override
  String get dailyFailedToUpdatePinned => '更新置顶营养素失败';

  @override
  String get dailyFat => '脂肪';

  @override
  String get dailyFiber => '纤维';

  @override
  String get dailyLeftoversReadyToLog => '剩菜已准备好记录';

  @override
  String get dailyPickTheNutrientsYou => '选择您想在“每日”选项卡顶部显示的营养素。';

  @override
  String get dailyPinNutrients => '置顶营养素';

  @override
  String get dailyPlanDetailCalories => '热量';

  @override
  String get dailyPlanDetailCarbs => '碳水化合物';

  @override
  String get dailyPlanDetailCompleted => '已完成';

  @override
  String get dailyPlanDetailEatingEnds => '进食结束';

  @override
  String get dailyPlanDetailEatingStarts => '进食开始';

  @override
  String get dailyPlanDetailFastingWindow => '禁食窗口';

  @override
  String get dailyPlanDetailFat => '脂肪';

  @override
  String get dailyPlanDetailMealSuggestions => '饮食建议';

  @override
  String get dailyPlanDetailMealsRegenerated => '饮食已重新生成！';

  @override
  String get dailyPlanDetailNotesWarnings => '备注与警告';

  @override
  String get dailyPlanDetailNutritionTargets => '营养目标';

  @override
  String get dailyPlanDetailProtein => '蛋白质';

  @override
  String get dailyPlanDetailRefresh => '刷新';

  @override
  String get dailyPlanDetailScheduledWorkout => '计划训练';

  @override
  String dailyPlanDetailSheetCal(Object calories) {
    return '$calories 卡路里';
  }

  @override
  String dailyPlanDetailSheetG(Object proteinTargetG) {
    return '${proteinTargetG}g';
  }

  @override
  String dailyPlanDetailSheetG2(Object carbsTargetG) {
    return '${carbsTargetG}g';
  }

  @override
  String dailyPlanDetailSheetG3(Object fatTargetG) {
    return '${fatTargetG}g';
  }

  @override
  String dailyPlanDetailSheetHFast(Object fastingDurationHours) {
    return '断食 $fastingDurationHours 小时';
  }

  @override
  String dailyPlanDetailSheetMin(Object workoutDurationMinutes) {
    return '$workoutDurationMinutes 分钟';
  }

  @override
  String dailyPlanDetailSheetValue(Object amount, Object name) {
    return '$name ($amount)';
  }

  @override
  String get dailyPlanDetailStartWorkout => '开始训练';

  @override
  String get dailyProtein => '蛋白质';

  @override
  String dailyStatsCardCalBurnedFromExercise(Object caloriesBurned) {
    return '运动消耗 $caloriesBurned 大卡';
  }

  @override
  String get dailyStatsCardDailyStats => '每日统计';

  @override
  String get dailyStatsCardLoadingStats => '正在加载统计数据...';

  @override
  String get dailyStatsCardStepsGoal => '步数目标';

  @override
  String dailyTabFailedToLog(Object e) {
    return '记录失败: $e';
  }

  @override
  String dailyTabLogged(Object name) {
    return '已记录 $name';
  }

  @override
  String dailyTabLogged2(Object ev) {
    return '已记录 $ev';
  }

  @override
  String dailyTabOfLeft(Object portionsMade, Object portionsRemaining) {
    return '剩余 $portionsRemaining / $portionsMade 份';
  }

  @override
  String dailyTabPinned(Object length) {
    return '已置顶 $length 项';
  }

  @override
  String get dailyTapSettingsIconTo => '点击设置图标以调整这些目标';

  @override
  String get dailyTapToLog => '点击记录';

  @override
  String dailyXpStripTodayGoals(Object completed, Object total) {
    return '今日：$completed/$total 个目标';
  }

  @override
  String dailyXpStripX(Object multiplier) {
    return '$multiplier 倍';
  }

  @override
  String dailyXpStripXp(Object xpEarned) {
    return '+$xpEarned XP';
  }

  @override
  String get dailyYourDailyGoals => '您的每日目标';

  @override
  String get dangerZoneDangerZone => '危险区域';

  @override
  String get dangerZoneDeleteAccount => '删除账户';

  @override
  String get dangerZoneDeleteWorkoutsKeepAccount => '删除训练记录，保留账户';

  @override
  String get dangerZonePermanentlyDeleteAllData => '永久删除所有数据';

  @override
  String get dangerZoneResetProgram => '重置计划';

  @override
  String get dangerZoneResetProgram2 => '重置计划？';

  @override
  String get dangerZoneThisWill => '此操作将：';

  @override
  String get dangerZoneYourCompletedWorkoutHistory => '您已完成的训练历史将被保留。';

  @override
  String get dataManagementAutoRenewalActive => '自动续订已激活';

  @override
  String get dataManagementDataManagement => '数据管理';

  @override
  String get dataManagementDownloadThisWeekS => '下载本周的视频';

  @override
  String get dataManagementDownloadYourWorkoutNutrit => '下载您的训练 + 营养数据';

  @override
  String get dataManagementDownloadedVideos => '已下载的视频';

  @override
  String get dataManagementExportMyWorkouts => '导出我的训练';

  @override
  String get dataManagementHevyStrongFitbodPdf =>
      'Hevy / Strong / Fitbod / PDF / GPX — 随身携带';

  @override
  String get dataManagementLifetimeAccess => '终身访问权限';

  @override
  String get dataManagementManageDuplicateImports => '管理重复导入';

  @override
  String get dataManagementManageOfflineExerciseVideos => '管理离线运动视频';

  @override
  String get dataManagementNoExercisesFoundIn => '您的计划中未找到运动项目。';

  @override
  String get dataManagementNoUpcomingChargesYou => '没有即将到来的扣费 - 您拥有终身访问权限';

  @override
  String get dataManagementNoVideoUrlsAvailable => '您的计划没有可用的视频链接。';

  @override
  String get dataManagementPreCacheAllExercises => '预缓存计划中的所有运动视频以供离线使用';

  @override
  String get dataManagementRePickThePrimary => '当同一训练被同步两次时，重新选择主要来源';

  @override
  String get dataManagementRequestRefund => '申请退款';

  @override
  String dataManagementSectionExportData(Object appName) {
    return '导出 $appName 数据';
  }

  @override
  String dataManagementSectionFinishedQueuingDownloads(Object length) {
    return '✅ 已完成 $length 个下载排队';
  }

  @override
  String dataManagementSectionImportData(Object appName) {
    return '导入 $appName 数据';
  }

  @override
  String dataManagementSectionPlan(Object tierName) {
    return '$tierName 计划';
  }

  @override
  String dataManagementSectionQueuingVideosForDownload(Object length) {
    return '正在排队下载 $length 个视频...';
  }

  @override
  String dataManagementSectionRestoreFromABackup(Object appName) {
    return '从 $appName 备份 ZIP 文件恢复';
  }

  @override
  String get dataManagementSignInToDownload => '登录以下载您的每周计划。';

  @override
  String get dataManagementSubmitARefundRequest => '提交退款申请';

  @override
  String get dataManagementSubscription => '订阅';

  @override
  String get dataManagementUpcomingRenewal => '即将续订';

  @override
  String get dataSyncClearAllCaches => '清除所有缓存';

  @override
  String get dataSyncDeviceInfo => '设备信息';

  @override
  String get dataSyncFreeMemoryByClearing => '通过清除内存缓存来释放空间';

  @override
  String get dataSyncLoading => '加载中...';

  @override
  String get dataSyncNotificationTester => '通知测试器';

  @override
  String get dataSyncSendTestNotifications => '发送测试通知';

  @override
  String get dateRangeFilterApply => '应用';

  @override
  String get dateRangeFilterCustom => '自定义';

  @override
  String get dateRangeFilterSelectDateRange => '选择日期范围';

  @override
  String get dateStripPickADate => '选择日期';

  @override
  String dayCardNoteS(Object length) {
    return '$length 条笔记';
  }

  @override
  String get deleteAccountFlowActiveSubscription => '当前订阅';

  @override
  String get deleteAccountFlowConfirmWithYourPassword => '使用密码确认';

  @override
  String get deleteAccountFlowDeleteAccount => '删除账户？';

  @override
  String get deleteAccountFlowDeleteAccount2 => '删除账户';

  @override
  String get deleteAccountFlowDeleteAnyway => '仍然删除';

  @override
  String deleteAccountFlowDeletingYourAccountDoes(Object storeName) {
    return '删除您的账户并不会取消您的 $storeName 订阅。';
  }

  @override
  String deleteAccountFlowOpen(Object storeName) {
    return '打开 $storeName';
  }

  @override
  String get deleteAccountFlowPleaseEnterYourPassword => '请输入您的密码';

  @override
  String get deleteAccountFlowReAuthenticationRequired => '需要重新验证';

  @override
  String get deleteAccountFlowResetPassword => '重置密码';

  @override
  String get deleteAccountFlowSignInAgain => '重新登录';

  @override
  String get deleteAccountFlowThisActionCannotBe => '此操作无法撤销！';

  @override
  String get deleteAccountFlowThisWillPermanentlyDelete => '这将永久删除：';

  @override
  String get deleteAccountFlowWeCouldNotVerify =>
      '我们无法验证您的密码。请先重置密码，然后再尝试删除您的账户。';

  @override
  String deleteAccountFlowYouWillContinueTo(Object storeName) {
    return '除非您先在 $storeName 中取消，否则您将继续被扣费。\n\n';
  }

  @override
  String get deleteAccountFlowYouWillNeedTo => '您需要重新注册才能使用本应用。';

  @override
  String get deleteAccountProgressDeletingYourAccount => '正在删除您的账户';

  @override
  String get deloadRecommendationCardPlanDeloadWeek => '计划减负周';

  @override
  String get demoActiveWorkoutAiCoachReview => 'AI 教练评估';

  @override
  String get demoActiveWorkoutAiCoachTip => 'AI 教练建议';

  @override
  String get demoActiveWorkoutBackToPreview => '返回预览';

  @override
  String get demoActiveWorkoutCoolDown => '冷身运动';

  @override
  String get demoActiveWorkoutExercise => '练习';

  @override
  String get demoActiveWorkoutExerciseDemo => '练习演示';

  @override
  String get demoActiveWorkoutExit => '退出';

  @override
  String get demoActiveWorkoutExitWorkout => '退出训练？';

  @override
  String get demoActiveWorkoutGetAiGeneratedWorkout =>
      '获取 AI 生成的训练计划，追踪您的进度，更快达成健身目标。';

  @override
  String get demoActiveWorkoutGetPersonalizedWorkouts => '获取个性化训练';

  @override
  String get demoActiveWorkoutGreatJobTimeTo => '做得好！是时候拉伸和恢复了。';

  @override
  String get demoActiveWorkoutNextExerciseComingUp => '即将进行下一个练习！';

  @override
  String get demoActiveWorkoutReadyForTheFull => '准备好体验完整功能了吗？';

  @override
  String get demoActiveWorkoutRestTime => '休息时间';

  @override
  String demoActiveWorkoutScreenCompleteSet(Object _currentSet) {
    return '完成组数 $_currentSet';
  }

  @override
  String demoActiveWorkoutScreenUi1Reps(Object _currentExerciseReps) {
    return '$_currentExerciseReps 次';
  }

  @override
  String demoActiveWorkoutScreenUi1SetOf(
    Object _currentExerciseSets,
    Object _currentSet,
  ) {
    return '第 $_currentSet 组，共 $_currentExerciseSets 组';
  }

  @override
  String get demoActiveWorkoutSignUpToGet =>
      '注册以获取个性化 AI 指导、详细的进度追踪以及为您量身定制的训练计划。';

  @override
  String get demoActiveWorkoutSkipAll => '全部跳过';

  @override
  String get demoActiveWorkoutSkipRest => '跳过休息';

  @override
  String get demoActiveWorkoutUpNext => '接下来';

  @override
  String get demoActiveWorkoutWarmUp => '热身运动';

  @override
  String get demoActiveWorkoutWorkoutComplete => '训练完成！';

  @override
  String get demoActiveWorkoutYourProgressInThis => '您在此演示训练中的进度将不会被保存。确定要退出吗？';

  @override
  String get demoDayBanner24HoursOfFull => '24 小时完整访问权限';

  @override
  String get demoDayBannerDemoDay => '演示日';

  @override
  String get demoDayBannerExploreAllPremiumFeatures => '探索所有高级功能 - 无需承诺';

  @override
  String get demoDayBannerTimeRemaining => '剩余时间：';

  @override
  String get demoTasksSeeHowTrainingWorks => '了解训练运作方式';

  @override
  String get demoTasksSeeItInAction => '查看实际操作';

  @override
  String get demoTasksSnapAMenuLog => '拍摄菜单，记录饮食';

  @override
  String get demoTasksTryOneOrBoth => '尝试其中一项或两项。如果愿意，也可以跳过。';

  @override
  String get demoWorkoutCreatingYourPersonalizedWor => '正在创建您的个性化训练...';

  @override
  String get demoWorkoutExercises => '练习';

  @override
  String get demoWorkoutFailedToLoadWorkout => '无法加载训练';

  @override
  String get demoWorkoutFocusOnProperForm => '专注于正确的姿势和受控的动作。';

  @override
  String get demoWorkoutHowToPerform => '如何执行';

  @override
  String get demoWorkoutScreenAi => 'AI';

  @override
  String get demoWorkoutScreenBasedOnYourGoals => '基于您的目标、设备和健身水平';

  @override
  String get demoWorkoutScreenDifficulty => '难度';

  @override
  String get demoWorkoutScreenEquipmentNeeded => '所需设备';

  @override
  String get demoWorkoutScreenGetAiPersonalizedWorkouts => '获取 AI 个性化训练';

  @override
  String get demoWorkoutScreenGetPersonalizedWorkouts => '获取个性化训练';

  @override
  String get demoWorkoutScreenSampleWorkout => '训练示例';

  @override
  String get demoWorkoutScreenSampleWorkoutPreview => '训练示例预览';

  @override
  String get demoWorkoutScreenSignUpToGet => '注册以获取根据您的目标、健身水平和现有设备量身定制的训练计划。';

  @override
  String get demoWorkoutScreenStartWorkout => '开始训练';

  @override
  String get demoWorkoutScreenTryAnotherSampleWorkout => '尝试另一个训练示例';

  @override
  String get demoWorkoutScreenType => '类型';

  @override
  String demoWorkoutScreenValue(Object label) {
    return '$label：';
  }

  @override
  String get demoWorkoutScreenYourPersonalizedWorkout => '您的个性化训练';

  @override
  String get demoWorkoutTryAgain => '重试';

  @override
  String get demoWorkoutVideo => '视频';

  @override
  String get demoWorkoutVideoUnavailable => '视频不可用';

  @override
  String get derivedMetricDetailABmiBetween18 =>
      'BMI 在 18.5 到 24.9 之间被认为是健康的体重范围。继续保持！';

  @override
  String get derivedMetricDetailABmiBetween25 =>
      'BMI在25到29.9之间被视为超重。注意：BMI无法区分肌肉和脂肪。';

  @override
  String get derivedMetricDetailABmiOf30 => 'BMI达到30或以上被归类为肥胖。建议咨询医疗专业人士以获取指导。';

  @override
  String get derivedMetricDetailAChestToWaist =>
      '胸腰比低于1.1表示相对于腰部，胸部较窄。建议专注于胸部和背部训练。';

  @override
  String get derivedMetricDetailAChestToWaist2 =>
      '胸腰比在1.1-1.3之间属于平均水平。胸部和腰部的比例健康。';

  @override
  String get derivedMetricDetailAChestToWaist3 =>
      '胸腰比高于1.3表示相对于腰部，胸部发育良好。比例非常棒！';

  @override
  String get derivedMetricDetailAWhtrAbove0 => 'WHtR高于0.6表示腹部脂肪较多，健康风险增加。';

  @override
  String get derivedMetricDetailAWhtrBetween0 =>
      'WHtR在0.4到0.5之间被视为健康。你的腰围小于身高的一半。';

  @override
  String get derivedMetricDetailAWhtrBetween02 =>
      'WHtR在0.5到0.6之间表示腹部脂肪增加。建议专注于减小腰围。';

  @override
  String get derivedMetricDetailAboveAverage => '高于平均水平';

  @override
  String get derivedMetricDetailAthletic => '运动型';

  @override
  String get derivedMetricDetailAverage => '平均水平';

  @override
  String get derivedMetricDetailAvg => '平均';

  @override
  String get derivedMetricDetailBasedOn => '基于';

  @override
  String get derivedMetricDetailBelowAverage => '低于平均水平';

  @override
  String get derivedMetricDetailBicepsL => '肱二头肌（左）';

  @override
  String get derivedMetricDetailBicepsR => '肱二头肌（右）';

  @override
  String get derivedMetricDetailBodyFat => '体脂率';

  @override
  String get derivedMetricDetailChest => '胸部';

  @override
  String get derivedMetricDetailExcellent => '优秀';

  @override
  String get derivedMetricDetailGood => '良好';

  @override
  String get derivedMetricDetailGoodSymmetry9397 =>
      '对称性良好（93-97%）。差异较小，处于正常范围内。';

  @override
  String get derivedMetricDetailHealthy => '健康';

  @override
  String get derivedMetricDetailHeight => '身高';

  @override
  String get derivedMetricDetailHighRisk => '高风险';

  @override
  String get derivedMetricDetailHips => '臀部';

  @override
  String get derivedMetricDetailHistory => '历史记录';

  @override
  String get derivedMetricDetailImbalanced => '不平衡';

  @override
  String get derivedMetricDetailInsufficientData => '数据不足';

  @override
  String get derivedMetricDetailLeanMass => '瘦体重';

  @override
  String get derivedMetricDetailLowRisk => '低风险';

  @override
  String get derivedMetricDetailMax => '最大值';

  @override
  String get derivedMetricDetailMin => '最小值';

  @override
  String get derivedMetricDetailModerate => '中等';

  @override
  String get derivedMetricDetailModerateAsymmetry8893 =>
      '对称性中等（88-93%）。考虑增加单侧训练以改善不平衡。';

  @override
  String get derivedMetricDetailModerateRisk => '中等风险';

  @override
  String get derivedMetricDetailMonthlyRate => '月度变化率';

  @override
  String get derivedMetricDetailNarrow => '窄';

  @override
  String get derivedMetricDetailNearPerfectSymmetry97 =>
      '对称性近乎完美（97%+）。两侧非常平衡。';

  @override
  String get derivedMetricDetailNoHistoryYet => '暂无历史记录';

  @override
  String get derivedMetricDetailNormal => '正常';

  @override
  String get derivedMetricDetailObese => '肥胖';

  @override
  String get derivedMetricDetailOverweight => '超重';

  @override
  String derivedMetricDetailScreenArmSymmetryComparesYour(Object info) {
    return '手臂对称度对比您的左右二头肌测量值。$info';
  }

  @override
  String derivedMetricDetailScreenEntries(Object length) {
    return '$length 条记录';
  }

  @override
  String derivedMetricDetailScreenLegSymmetryComparesYour(Object info) {
    return '腿部对称度对比您的左右大腿测量值。$info';
  }

  @override
  String get derivedMetricDetailShoulders => '肩部';

  @override
  String get derivedMetricDetailSignificantAsymmetryBelow8 =>
      '对称性显著不足（低于88%）。请专注于弱侧的单侧训练。';

  @override
  String get derivedMetricDetailSuperior => '卓越';

  @override
  String get derivedMetricDetailThighL => '大腿（左）';

  @override
  String get derivedMetricDetailThighR => '大腿（右）';

  @override
  String get derivedMetricDetailTrends => '趋势';

  @override
  String get derivedMetricDetailUnderweight => '体重过轻';

  @override
  String get derivedMetricDetailVTaper => '倒三角体型';

  @override
  String get derivedMetricDetailWaist => '腰部';

  @override
  String get derivedMetricDetailWeeklyRate => '周变化率';

  @override
  String get derivedMetricDetailWeight => '体重';

  @override
  String get diabetesDashboardDiabetes => '糖尿病';

  @override
  String get diabetesDashboardGlucoseLevel => '血糖水平';

  @override
  String get diabetesDashboardInsulinType => '胰岛素类型';

  @override
  String get diabetesDashboardLogGlucose => '记录血糖';

  @override
  String get diabetesDashboardLogInsulin => '记录胰岛素';

  @override
  String get diabetesDashboardLong => '长效';

  @override
  String get diabetesDashboardMixed => '预混';

  @override
  String get diabetesDashboardNotesOptional => '备注（可选）';

  @override
  String get diabetesDashboardRapid => '速效';

  @override
  String get diabetesDashboardScreenAbove => '高于';

  @override
  String get diabetesDashboardScreenAllBloodGlucoseReadings => '所有血糖读数';

  @override
  String get diabetesDashboardScreenBasedOnReadings => '基于读数';

  @override
  String get diabetesDashboardScreenBelow => '低于';

  @override
  String get diabetesDashboardScreenCurrentGlucose => '当前血糖';

  @override
  String get diabetesDashboardScreenEstimated => '预估';

  @override
  String diabetesDashboardScreenGlucoseLoggedMgDl(Object value) {
    return '已记录血糖：$value mg/dL';
  }

  @override
  String get diabetesDashboardScreenGreatYouReMeeting => '太棒了！你已达到70%+的目标范围。';

  @override
  String get diabetesDashboardScreenHealthConnect => 'Health Connect';

  @override
  String get diabetesDashboardScreenInRange => '范围内';

  @override
  String diabetesDashboardScreenInsulinLoggedU(Object units) {
    return '已记录胰岛素：$units U';
  }

  @override
  String get diabetesDashboardScreenLatest => '最新';

  @override
  String get diabetesDashboardScreenLogGlucose => '记录血糖';

  @override
  String get diabetesDashboardScreenLogInsulin => '记录胰岛素';

  @override
  String get diabetesDashboardScreenLong => '长效';

  @override
  String get diabetesDashboardScreenManual => '手动';

  @override
  String get diabetesDashboardScreenMgDl => 'mg/dL';

  @override
  String get diabetesDashboardScreenNoAdditionalReadingsAvailab => '没有更多可用读数';

  @override
  String diabetesDashboardScreenPartA1CCardDaysAgo(Object daysSinceMeasured) {
    return '$daysSinceMeasured 天前';
  }

  @override
  String diabetesDashboardScreenPartA1CCardMgDl(Object valueMgDl) {
    return '$valueMgDl mg/dL';
  }

  @override
  String diabetesDashboardScreenPartCurrentGlucoseCardLastDays(
    Object daysIncluded,
  ) {
    return '过去 $daysIncluded 天';
  }

  @override
  String diabetesDashboardScreenPartCurrentGlucoseCardMgDl(Object range) {
    return '$range mg/dL';
  }

  @override
  String diabetesDashboardScreenPartCurrentGlucoseCardU(Object totalUnits) {
    return '${totalUnits}U';
  }

  @override
  String diabetesDashboardScreenPartCurrentGlucoseCardU2(
    Object totalRapidUnits,
  ) {
    return '${totalRapidUnits}U';
  }

  @override
  String diabetesDashboardScreenPartCurrentGlucoseCardU3(
    Object totalLongUnits,
  ) {
    return '${totalLongUnits}U';
  }

  @override
  String diabetesDashboardScreenPartCurrentGlucoseCardU4(Object units) {
    return '$units U';
  }

  @override
  String diabetesDashboardScreenPartCurrentGlucoseCardValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String get diabetesDashboardScreenRapid => '速效';

  @override
  String get diabetesDashboardScreenRecentDoses => '近期剂量';

  @override
  String get diabetesDashboardScreenRecentReadings => '近期读数';

  @override
  String get diabetesDashboardScreenSeeAll => '查看全部';

  @override
  String get diabetesDashboardScreenSync => '同步';

  @override
  String get diabetesDashboardScreenSyncYourGlucoseData => '同步您的血糖数据';

  @override
  String get diabetesDashboardScreenTimeInRange => '目标范围内时间';

  @override
  String get diabetesDashboardScreenTodaySInsulin => '今日胰岛素';

  @override
  String get diabetesDashboardScreenTotal => '总计';

  @override
  String get diabetesDashboardUnableToLoadData => '无法加载数据';

  @override
  String get diabetesDashboardUnits => '单位';

  @override
  String get dietHeuristics25GPerDish => '每份 25 克以上';

  @override
  String get dietHeuristicsAntiInflammatory => '抗炎';

  @override
  String get dietHeuristicsBloodSugarFriendly => '血糖友好';

  @override
  String get dietHeuristicsGutFriendly => '肠道友好';

  @override
  String get dietHeuristicsHighProtein => '高蛋白';

  @override
  String get dietHeuristicsLowCarb => '低碳水';

  @override
  String get dietHeuristicsLowFodmap => '低 FODMAP';

  @override
  String get dietHeuristicsLowGlycemicLoad => '低血糖负荷';

  @override
  String get dietHeuristicsNotUltraProcessed => '非超加工食品';

  @override
  String get dietHeuristicsScore3OrLower => '评分 3 或以下';

  @override
  String get dietHeuristicsUnder20GCarbs => '碳水低于 20 克';

  @override
  String get dietHeuristicsUnder450Cal => '热量低于 450 卡';

  @override
  String get dietHeuristicsWholeFoods => '全食物';

  @override
  String get difficultyCardDifficultyMultipliers => '难度倍数';

  @override
  String get difficultyCardResetAll => '重置全部';

  @override
  String get difficultyCardRest => '休息';

  @override
  String difficultyCardRest2(Object tier) {
    return '$tier - 休息';
  }

  @override
  String difficultyCardRpe(Object tier) {
    return '$tier - RPE';
  }

  @override
  String get difficultyCardTapAnyCellTo => '点击任意单元格以编辑缩放系数';

  @override
  String get difficultyCardTier => '层级';

  @override
  String get difficultyCardVolume => '容量';

  @override
  String difficultyCardVolume2(Object tier) {
    return '$tier - 训练量';
  }

  @override
  String difficultyCardX(Object v) {
    return '${v}x';
  }

  @override
  String difficultyCardX2(Object v) {
    return '${v}x';
  }

  @override
  String get difficultySelectorChooseAnother => '选择其他';

  @override
  String get difficultySelectorChooseDifferent => '选择不同';

  @override
  String get difficultySelectorConsiderChallengingForA => '考虑选择“挑战”以获得更安全的强度训练';

  @override
  String get difficultySelectorContinueAnyway => '仍然继续';

  @override
  String get difficultySelectorDifficulty => '难度';

  @override
  String get difficultySelectorGotIt => '知道了';

  @override
  String get difficultySelectorHellIntensity => '地狱强度';

  @override
  String get difficultySelectorHellModeWarning => 'HELL 模式警告';

  @override
  String get difficultySelectorHighIntensity => '高强度';

  @override
  String get difficultySelectorIAcceptTheRisk => '我接受风险';

  @override
  String difficultySelectorModeIsDesignedFor(Object displayName) {
    return '$displayName 模式专为经验丰富的运动员设计。作为初学者，这可能会导致受伤或过度训练。我们建议从“初学者”或“中等”难度开始。';
  }

  @override
  String difficultySelectorModeMayBeIntense(Object displayName) {
    return '$displayName 模式对初学者来说可能强度过大。建议从“初学者”或“中等”难度开始，随着力量和耐力的提升逐步增加强度。';
  }

  @override
  String get difficultySelectorThisIsAnExtreme => '这是一项旨在挑战您极限的极端强度训练。';

  @override
  String get discoverBrowseByCategory => '按类别浏览';

  @override
  String get discoverBrowseByEquipment => '按器械浏览';

  @override
  String get discoverBrowseByMuscle => '按肌肉部位浏览';

  @override
  String get discoverChallenges => '挑战';

  @override
  String get discoverCheckYourConnectionAnd => '请检查您的连接并重试。';

  @override
  String get discoverComplete3WorkoutsTo => '完成 3 次训练以解锁您的健身档案。';

  @override
  String get discoverCompleteAWorkoutThis => '本周完成一次训练';

  @override
  String get discoverCompleteAWorkoutTo => '完成一次训练以登上排行榜';

  @override
  String get discoverCompleteYourProfileTo => '完善您的个人资料以获取个性化推荐';

  @override
  String get discoverCouldnTLoadDiscover => '无法加载“发现”页面。';

  @override
  String get discoverCuratedRecipesToTry => '精选食谱，供您尝试或发挥创意';

  @override
  String get discoverFeed => '动态';

  @override
  String get discoverForYou => '为您推荐';

  @override
  String get discoverFriends => '好友';

  @override
  String get discoverGetAPersonalizedAi => '获取个性化 AI 推荐';

  @override
  String get discoverHidden => '已隐藏';

  @override
  String get discoverMatchedToYourGym => '匹配您的健身房档案';

  @override
  String get discoverNotEnoughDataYet => '数据尚不足';

  @override
  String get discoverNotSureAskAi => '不确定？问问 AI';

  @override
  String discoverScreenLvl(Object level) {
    return '等级 $level';
  }

  @override
  String discoverScreenLvl2(Object level) {
    return '等级 $level';
  }

  @override
  String discoverScreenOf(Object totalActive, Object yourRank) {
    return '#$yourRank / $totalActive';
  }

  @override
  String discoverScreenValue(Object rank) {
    return '#$rank';
  }

  @override
  String discoverScreenValue2(Object rank) {
    return '#$rank';
  }

  @override
  String discoverScreenValue3(Object username) {
    return '@$username';
  }

  @override
  String discoverScreenValue4(Object bio) {
    return '\"$bio\"';
  }

  @override
  String discoverScreenValue5(Object rank) {
    return '#$rank';
  }

  @override
  String get discoverTapAnAxis => '点击坐标轴';

  @override
  String get discoverThem => '他们';

  @override
  String get discoverThisWeek => '本周';

  @override
  String get discoverTopOfTheWeek => '本周榜首';

  @override
  String get discoverTourBrowseRisingStarsAnd => '浏览“新星”和“附近的人”，看看谁和您处于同一训练水平。';

  @override
  String get discoverTourFindYourPeers => '寻找同伴';

  @override
  String get discoverTourOpenTheir6Axis =>
      '打开他们的 6 轴健身雷达，看看您在 XP、容量、连续记录等方面的表现如何。';

  @override
  String get discoverTourSwitchBoards => '切换榜单';

  @override
  String get discoverTourTapAnyUser => '点击任意用户';

  @override
  String get discoverTourXpVolumeStreaksEach =>
      'XP / 容量 / 连续记录分别代表不同的游戏维度——尝试全部，找到您最强的领域。';

  @override
  String get discoverTrainingPlans => '训练计划';

  @override
  String get discoverTryAgain => '重试';

  @override
  String get discoverViewAll => '查看全部';

  @override
  String get discoverWhatShouldITrain => '我该练什么？';

  @override
  String get discoverXpThisWeek => '本周 XP';

  @override
  String get discoverYou => '您 · ';

  @override
  String get discoverYourRankPercentileAppears => '一旦上榜，您的排名和百分位就会显示';

  @override
  String get dismissedBannersDailyXpGoals => '每日 XP 目标';

  @override
  String get dismissedBannersDismissedBanners => '已关闭的横幅';

  @override
  String get dismissedBannersDismissedBannersResetAutoma => '已关闭的横幅会在午夜自动重置。';

  @override
  String get dismissedBannersRestore => '恢复';

  @override
  String get doubleXpBannerDayStreak => '天连续记录';

  @override
  String doubleXpBannerEndsIn(Object formattedTimeRemaining) {
    return '$formattedTimeRemaining 后结束';
  }

  @override
  String doubleXpBannerX(Object xpMultiplier) {
    return '${xpMultiplier}x';
  }

  @override
  String doubleXpBannerX2(Object multiplier) {
    return '${multiplier}x';
  }

  @override
  String get downloadedVideosAllDownloadsCleared => '所有下载已清除';

  @override
  String get downloadedVideosBrowseExerciseLibrary => '浏览动作库';

  @override
  String get downloadedVideosClearAll => '全部清除';

  @override
  String get downloadedVideosClearAllDownloads => '清除所有下载？';

  @override
  String get downloadedVideosDownloadedVideos => '已下载视频';

  @override
  String get downloadedVideosHowToDownload => '如何下载';

  @override
  String get downloadedVideosNoDownloadsYet => '暂无下载';

  @override
  String get downloadedVideosSaveExerciseVideosFor =>
      '保存训练视频以供离线观看 — 非常适合健身房 WiFi 信号不佳时使用。';

  @override
  String downloadedVideosScreenDeleted(Object exerciseName) {
    return '已删除 \"$exerciseName\"';
  }

  @override
  String downloadedVideosScreenMb(Object formattedCacheSize) {
    return '$formattedCacheSize / 500 MB';
  }

  @override
  String downloadedVideosScreenVideos(Object cachedVideoCount) {
    return '$cachedVideoCount 个视频';
  }

  @override
  String get downloadedVideosStorageAlmostFullOldest => '存储空间即将满。最旧的视频将被自动删除。';

  @override
  String get downloadedVideosStorageUsed => '已用存储空间';

  @override
  String get downloadedVideosThisWillDeleteAll =>
      '这将从您的设备中删除所有已下载的训练视频。您可以随时重新下载。';

  @override
  String get durationRangeSliderDuration => '时长';

  @override
  String durationRangeSliderMin(Object minDuration) {
    return '$minDuration 分钟';
  }

  @override
  String durationRangeSliderMin2(Object maxDuration) {
    return '$maxDuration 分钟';
  }

  @override
  String get durationSliderDuration => '时长';

  @override
  String durationSliderMin(Object duration) {
    return '$duration 分钟';
  }

  @override
  String durationSliderMin2(Object minDuration) {
    return '$minDuration 分钟';
  }

  @override
  String durationSliderMin3(Object maxDuration) {
    return '$maxDuration 分钟';
  }

  @override
  String get easyActiveWorkoutComplete => '完成';

  @override
  String get easyActiveWorkoutCompleteWorkoutNow => '立即完成训练？';

  @override
  String get easyActiveWorkoutExerciseSwapped => '动作已更换';

  @override
  String get easyActiveWorkoutKeepGoing => '继续训练';

  @override
  String get easyActiveWorkoutQuit => '退出';

  @override
  String get easyActiveWorkoutQuitWorkout => '退出训练？';

  @override
  String get easyActiveWorkoutSavingWorkout => '正在保存训练...';

  @override
  String get easyChatPillAskCoach => '咨询教练';

  @override
  String get easyChatPillAskYourCoach => '咨询您的教练';

  @override
  String get easyExerciseActionsChangeEquipment => '更换器械';

  @override
  String get easyExerciseActionsDonTHaveWhat => '没有列表中的器械？';

  @override
  String get easyExerciseActionsPickADifferentMovement => '为此位置选择其他动作';

  @override
  String get easyExerciseActionsReportPain => '报告疼痛';

  @override
  String get easyExerciseActionsShowVideo => '显示视频';

  @override
  String get easyExerciseActionsSkipThisExerciseAvoid => '跳过此动作并暂时避免';

  @override
  String get easyExerciseActionsSkipToNextExercise => '跳至下一个动作';

  @override
  String get easyExerciseActionsSwapExercise => '更换动作';

  @override
  String get easyExerciseHeaderAddSet => '添加组数';

  @override
  String get easyExerciseHeaderInstructions => '说明';

  @override
  String get easyExerciseHeaderPlan => '计划';

  @override
  String get easyExerciseHeaderRemoveSet => '移除组数';

  @override
  String easyExerciseHeaderSetOf(Object currentSet, Object totalSets) {
    return '第$currentSet组，共$totalSets组';
  }

  @override
  String get easyExerciseHeaderVideo => '视频';

  @override
  String get easyFocalColumnHold => '保持';

  @override
  String get easyFocalColumnReps => '次数';

  @override
  String get easyFocalColumnWeight => '重量';

  @override
  String get easyHelpAdjustWeightAndReps => '使用 − 和 + 调整重量和次数。长按数字可直接输入。';

  @override
  String get easyHelpGotIt => '知道了';

  @override
  String get easyHelpLogASet => '记录一组';

  @override
  String get easyHelpLogASetBody => '记录一组训练';

  @override
  String get easyHelpSkipToNextExercise => '跳至下一个动作';

  @override
  String get easyHelpSwitchToAdvanced => '切换至进阶模式';

  @override
  String get easyHelpTapTheBigWhen => '完成一组后点击大大的 ✓。剩下的交给我们处理 — 真的。';

  @override
  String get easyHelpThisIsTodayS => '这是今天的训练动作。需要复习动作要领时，随时点击 ▶ 显示视频。';

  @override
  String get easyHelpTodaySExercise => '今日训练';

  @override
  String get easyHelpTodaysExercise => '今日训练';

  @override
  String get easyHelpTodaysExerciseBody => '今日训练内容';

  @override
  String get easyHelpWeightAndReps => '重量与次数';

  @override
  String get easyHelpWeightAndRepsBody => '重量与次数';

  @override
  String get easyRestOverlayRest => '休息';

  @override
  String easyRestOverlaySetOf(Object nextSetNumber, Object totalSets) {
    return '第 $nextSetNumber 组，共 $totalSets 组';
  }

  @override
  String get easyRestOverlaySkipRest => '跳过休息';

  @override
  String get easySheetHelpersAboutThisExercise => '关于此动作';

  @override
  String get easySheetHelpersBodyPart => '身体部位';

  @override
  String get easySheetHelpersBreathing => '呼吸';

  @override
  String get easySheetHelpersEquipment => '器械';

  @override
  String get easySheetHelpersFormTips => '动作要领';

  @override
  String get easySheetHelpersHowToPerform => '如何执行';

  @override
  String get easySheetHelpersNoDemoVideoFor => '暂无此动作的演示视频。';

  @override
  String get easySheetHelpersPrimaryMuscle => '主要肌群';

  @override
  String get easySheetHelpersSecondary => '次要肌群';

  @override
  String get easyTopBarAddToFavorites => '添加到收藏';

  @override
  String get easyTopBarCompleteWorkout => '完成训练';

  @override
  String get easyTopBarMinimizeWorkout => '最小化训练';

  @override
  String get easyTopBarQuitWorkout => '退出训练';

  @override
  String get easyTopBarRemoveFromFavorites => '从收藏中移除';

  @override
  String get easyTopBarSkipToNextExercise => '跳至下一个动作';

  @override
  String get editGymProfileAutoAiDecides => '自动（由 AI 决定）';

  @override
  String get editGymProfileAutoSwitchAtThis => '在此时间自动切换';

  @override
  String get editGymProfileAutoSwitchWhenI => '到达时自动切换';

  @override
  String get editGymProfileChooseIcon => '选择图标';

  @override
  String get editGymProfileClear => '清除';

  @override
  String get editGymProfileColor => '颜色';

  @override
  String get editGymProfileCustomizeWorkoutsForThis => '为此健身房自定义训练';

  @override
  String get editGymProfileDuplicate => '复制';

  @override
  String get editGymProfileEditIcon => '编辑图标';

  @override
  String get editGymProfileEnterGymName => '输入健身房名称';

  @override
  String get editGymProfileEnterNewName => '输入新名称';

  @override
  String get editGymProfileEnvironment => '环境';

  @override
  String get editGymProfileEquipment => '器械';

  @override
  String get editGymProfileExperienceLevel => '经验水平';

  @override
  String get editGymProfileFocusAreas => '重点区域';

  @override
  String get editGymProfileHowMuchExerciseVariety => '每周的动作多样性';

  @override
  String get editGymProfileIcon => '图标';

  @override
  String get editGymProfileLeaveOnAutoFor =>
      '保持“自动”让 AI 决定，或将重点固定在特定日期（例如：周二 → 上肢）。';

  @override
  String get editGymProfileLocationOptional => '位置（可选）';

  @override
  String get editGymProfileMuscleGroupsToPrioritize => '优先训练的肌群';

  @override
  String get editGymProfileName => '名称';

  @override
  String get editGymProfileNoPref => '无偏好';

  @override
  String get editGymProfilePinFocusPerDay => '固定每日重点（可选）';

  @override
  String get editGymProfilePleaseEnterAName => '请输入名称';

  @override
  String get editGymProfileRename => '重命名';

  @override
  String get editGymProfileRenameGym => '重命名健身房';

  @override
  String get editGymProfileRequiresLocationPermission => '需要位置权限';

  @override
  String get editGymProfileSaveChanges => '保存更改';

  @override
  String get editGymProfileSetALocationTo => '设置位置以自动切换配置';

  @override
  String editGymProfileSheetEquipmentItems(Object length) {
    return '$length 件器械';
  }

  @override
  String editGymProfileSheetExtCreatedCopyOf(Object name) {
    return '已创建“$name”的副本';
  }

  @override
  String editGymProfileSheetExtFailedToDuplicate(Object e) {
    return '复制失败: $e';
  }

  @override
  String editGymProfileSheetExtFailedToSave(Object e) {
    return '保存失败: $e';
  }

  @override
  String editGymProfileSheetExtMinutes(Object _selectedDuration) {
    return '$_selectedDuration 分钟';
  }

  @override
  String editGymProfileSheetExtPinFocusFor(Object dayName) {
    return '置顶 $dayName 的重点';
  }

  @override
  String editGymProfileSheetExtUpdated(Object text) {
    return '已更新“$text”';
  }

  @override
  String get editGymProfileTapToAddRemove => '点击以添加、移除或编辑重量';

  @override
  String get editGymProfileTrainingPreferencesOptional => '训练偏好（可选）';

  @override
  String get editGymProfileWeeklyVariety => '每周多样性';

  @override
  String get editGymProfileWhenDoYouUsually => '你通常什么时候在这里锻炼？';

  @override
  String get editGymProfileWorkoutDays => '锻炼天数';

  @override
  String get editGymProfileWorkoutDuration => '锻炼时长';

  @override
  String get editGymProfileWorkoutTimeOptional => '锻炼时间（可选）';

  @override
  String get editPersonalInfoChooseFromGallery => '从相册选择';

  @override
  String get editPersonalInfoEditProfile => '编辑个人资料';

  @override
  String get editPersonalInfoHeight => '身高';

  @override
  String get editPersonalInfoRemovePhoto => '移除照片';

  @override
  String get editPersonalInfoTakePhoto => '拍照';

  @override
  String get editPersonalInfoTapToChangePhoto => '点击更换照片';

  @override
  String get editPersonalInfoTargetWeight => '目标体重';

  @override
  String get editPersonalInfoTellUsAboutYourself => '告诉我们关于你的信息...';

  @override
  String get editPersonalInfoUploadPhoto => '上传照片';

  @override
  String get editPersonalInfoUploading => '正在上传...';

  @override
  String get editPersonalInfoWeight => '体重';

  @override
  String get editPersonalInfoYourEmailCom => 'your@email.com';

  @override
  String get editPersonalInfoYourName => '你的名字';

  @override
  String get editProgramSheetBack => '返回';

  @override
  String get editProgramSheetChangeYourWeeklySchedule =>
      '更改你的每周计划、器械或难度。你的锻炼计划将根据新设置重新生成。';

  @override
  String get editProgramSheetChooseATrainingSplit => '选择适合你日程和目标的训练拆分';

  @override
  String get editProgramSheetContinue => '继续';

  @override
  String get editProgramSheetCurrent => '当前';

  @override
  String get editProgramSheetCustomProgram => '自定义计划';

  @override
  String editProgramSheetCustomValue(Object arg0) {
    return '自定义值 $arg0';
  }

  @override
  String get editProgramSheetCustomizeProgram => '自定义计划';

  @override
  String get editProgramSheetDays => '天数';

  @override
  String editProgramSheetDaysAgo(Object days) {
    return '$days 天前';
  }

  @override
  String editProgramSheetDaysPerWeek(Object days) {
    return '$days 天/周';
  }

  @override
  String get editProgramSheetDescribeWhatYouWant => '描述你的训练目标，AI 将为你创建个性化计划。';

  @override
  String get editProgramSheetDifficulty => '难度';

  @override
  String get editProgramSheetDuration => '时长';

  @override
  String get editProgramSheetEGTrainFor => '例如：“为 HYROX 比赛进行训练”';

  @override
  String get editProgramSheetEquipment => '器械';

  @override
  String get editProgramSheetEquipmentLabel => '器械标签';

  @override
  String get editProgramSheetExamples => '示例';

  @override
  String editProgramSheetFailedToLoadHistory(Object arg0) {
    return '加载历史记录 $arg0';
  }

  @override
  String editProgramSheetFailedToRestore(Object arg0) {
    return '恢复 $arg0';
  }

  @override
  String get editProgramSheetFailedToUpdateProgram => '更新计划';

  @override
  String get editProgramSheetFocus => '重点';

  @override
  String get editProgramSheetHealth => '健康';

  @override
  String get editProgramSheetInjuries => '伤病';

  @override
  String get editProgramSheetNoProgramHistoryFound => '未找到计划历史';

  @override
  String editProgramSheetPartEditProgramSheetStateOf(
    Object _generatingWorkout,
    Object _totalWorkoutsToGenerate,
  ) {
    return '$_generatingWorkout / $_totalWorkoutsToGenerate';
  }

  @override
  String get editProgramSheetPleaseLogInTo => '请登录以查看计划历史';

  @override
  String get editProgramSheetPleaseSelectAtLeast => '请至少选择一个锻炼日';

  @override
  String get editProgramSheetProgram => '计划';

  @override
  String get editProgramSheetProgramHistory => '计划历史';

  @override
  String get editProgramSheetProgramRestoredRegenerateW =>
      '计划已恢复！请重新生成锻炼以应用更改。';

  @override
  String get editProgramSheetRestoreAPreviousProgram => '恢复之前的计划配置';

  @override
  String get editProgramSheetRestoreThisProgram => '恢复此计划';

  @override
  String get editProgramSheetSaveCustomProgram => '保存自定义计划';

  @override
  String get editProgramSheetSavingPreferences => '正在保存偏好设置';

  @override
  String get editProgramSheetSchedule => '日程';

  @override
  String get editProgramSheetSummary => '摘要';

  @override
  String get editProgramSheetThisStepIsOptional => '此步骤为可选。如果没有需要报告的伤病，你可以跳过。';

  @override
  String get editProgramSheetToday => '今天';

  @override
  String get editProgramSheetTrainingProgram => '训练计划';

  @override
  String get editProgramSheetUnknownDate => '未知日期';

  @override
  String get editProgramSheetUpdateAndRegenerate => '更新并重新生成';

  @override
  String get editProgramSheetUpdating => '正在更新';

  @override
  String editProgramSheetWeeksAgo(Object weeks) {
    return '$weeks 周前';
  }

  @override
  String get editProgramSheetYesterday => '昨天';

  @override
  String get editSetAddSet => '添加组';

  @override
  String get editSetEditSets => '编辑组';

  @override
  String get editSetSaveChanges => '保存更改';

  @override
  String get editSetThisSetWillBe => '此组将被移除。';

  @override
  String get editSetWeightKg => '重量 (kg)';

  @override
  String get editTargetsDietPreset => '饮食预设';

  @override
  String get editTargetsEditDailyTargets => '编辑每日目标';

  @override
  String get editTargetsLockCalories => '锁定卡路里';

  @override
  String get editTargetsMaintainingWeight => '维持体重';

  @override
  String get editTargetsRec => '推荐';

  @override
  String get editTargetsRecalculateFromProfile => '从个人资料重新计算';

  @override
  String get editTargetsRecommendationUnavailableR => '推荐不可用 — 请先从个人资料重新计算';

  @override
  String get editTargetsReset => '重置';

  @override
  String get editTargetsSaveTargets => '保存目标';

  @override
  String editTargetsSheetCalculatedKcal(Object numberFormat) {
    return '计算得出：$numberFormat kcal';
  }

  @override
  String editTargetsSheetCappedAtSafeMinimum(Object cappedMinimum) {
    return '已限制在安全最小值 ($cappedMinimum kcal) — ';
  }

  @override
  String editTargetsSheetFailedToRecalculate(Object e) {
    return '重新计算失败：$e';
  }

  @override
  String editTargetsSheetFailedToSave(Object e) {
    return '保存失败：$e';
  }

  @override
  String editTargetsSheetGKg(Object currentRatio) {
    return '$currentRatio g/kg · ';
  }

  @override
  String editTargetsSheetGKg2(Object ratio) {
    return '$ratio g/kg';
  }

  @override
  String editTargetsSheetKg(Object fmt) {
    return '${fmt}kg';
  }

  @override
  String editTargetsSheetProteinTarget(Object anchorLabel) {
    return '蛋白质目标 $anchorLabel';
  }

  @override
  String editTargetsSheetSafeMinimumCaloriesMeet(Object cappedMinimum) {
    return '安全最低卡路里 ($cappedMinimum) 满足您的 TDEE — ';
  }

  @override
  String editTargetsSheetTotalUBMust(Object sum) {
    return '总计：$sum% · 必须等于 100%';
  }

  @override
  String editTargetsSheetUWks(
    Object dateStr,
    Object deficitInfo,
    Object goalLabel,
    Object weeks,
  ) {
    return '$goalLabel → ~$weeks 周 ($dateStr)$deficitInfo';
  }

  @override
  String editTargetsSheetValue(Object label, Object pct) {
    return '$label $pct%';
  }

  @override
  String get editTargetsTargetsRecalculatedFromProf => '目标已根据个人资料重新计算';

  @override
  String get editTargetsTargetsUpdated => '目标已更新';

  @override
  String get editTargetsTotal100 => '总计：100%';

  @override
  String get editTargetsUseRecommended => '使用推荐值';

  @override
  String get editTargetsWeeklyRateKgWk => '每周速率 (kg/周)';

  @override
  String get editTrackingAtLeastOneStat => '至少保留一项可见统计数据';

  @override
  String get editTrackingCaloriesBurned => '消耗卡路里';

  @override
  String get editTrackingCaloriesPCF => '卡路里、P/C/F 宏量营养素及饮水量';

  @override
  String get editTrackingChooseWhichStatsTo => '选择要在追踪栏中显示的统计数据';

  @override
  String get editTrackingConsecutiveWorkoutDays => '连续锻炼天数';

  @override
  String get editTrackingDailyGoals => '每日目标';

  @override
  String get editTrackingDailyHabitCompletionProgres => '每日习惯完成进度';

  @override
  String get editTrackingDailyStepCountFrom => '来自健康设备的每日步数';

  @override
  String get editTrackingEditTracking => '编辑追踪';

  @override
  String get editTrackingFromConnectedHealthDevices => '来自已连接的健康设备';

  @override
  String get editTrackingHabits => '习惯';

  @override
  String get editTrackingLastNightSSleep => '昨晚的睡眠时长与质量';

  @override
  String get editTrackingLoginWeightMealWorkout => '登录、体重、饮食与锻炼打卡';

  @override
  String get editTrackingNutritionHydration => '营养与水分';

  @override
  String get editTrackingReset => '重置';

  @override
  String get editTrackingSleep => '睡眠';

  @override
  String get editTrackingSteps => '步数';

  @override
  String get editTrackingWorkoutStreak => '健身连胜';

  @override
  String get editWeightsAnyWeightAllowedIn => '训练中允许使用任何重量';

  @override
  String get editWeightsApplyAPreset => '应用预设';

  @override
  String get editWeightsClearAll => '全部清除';

  @override
  String get editWeightsClearAll2 => '全部清除';

  @override
  String get editWeightsClearedAllWeights => '已清除所有重量';

  @override
  String get editWeightsCommercialGymStandardSet => '商用健身房标准套装';

  @override
  String get editWeightsCompetitionSet832 => '比赛套装 (8–32 kg)';

  @override
  String get editWeightsCustomWeight => '自定义重量...';

  @override
  String get editWeightsEditWeights => '编辑重量';

  @override
  String get editWeightsEnter0ToRemove => '输入 0 以移除';

  @override
  String get editWeightsGenerateStackWeights => '生成配重片重量';

  @override
  String get editWeightsHomeAdjustableSet => '家用可调节套装';

  @override
  String get editWeightsMax => '最大值';

  @override
  String get editWeightsMicroloadingAddOn => '微调配重片';

  @override
  String get editWeightsMin => '最小值';

  @override
  String get editWeightsNoWeightsYetPick => '暂无重量 — 选择最小值/最大值/步长并点击“生成”。';

  @override
  String get editWeightsPreset => '预设';

  @override
  String get editWeightsQuantity => '数量';

  @override
  String get editWeightsSet => '组';

  @override
  String get editWeightsSetQuantity => '设置数量';

  @override
  String editWeightsSheetSelectedItems(Object _totalWeights) {
    return '已选: $_totalWeights 项';
  }

  @override
  String get editWeightsStackRange => '配重范围';

  @override
  String get editWeightsStep => '步长';

  @override
  String get editWeightsUndo => '撤销';

  @override
  String get editWorkoutEquipmentDeselect => '取消选择';

  @override
  String get editWorkoutEquipmentEditEquipment => '编辑器材';

  @override
  String get editWorkoutEquipmentSearchEquipment => '搜索器材...';

  @override
  String get editWorkoutEquipmentSelectAll => '全选';

  @override
  String editWorkoutEquipmentSheetItemsSelected(Object length) {
    return '已选 $length 项';
  }

  @override
  String editWorkoutEquipmentSheetValue(
    Object length,
    Object selectedInCategory,
  ) {
    return '($selectedInCategory/$length)';
  }

  @override
  String get editWorkoutEquipmentUpdateWorkoutEquipment => '更新训练器材';

  @override
  String get editWorkoutEquipmentWeights => '重量';

  @override
  String get editableFitnessCard15Min => '15 分钟';

  @override
  String get editableFitnessCard90Min => '90 分钟';

  @override
  String get editableFitnessCardActiveGym => '活跃健身房';

  @override
  String get editableFitnessCardActiveInjuries => '现有伤病';

  @override
  String get editableFitnessCardChangesAffectYourWorkout => '更改将影响您的健身计划';

  @override
  String get editableFitnessCardCustom => '自定义';

  @override
  String get editableFitnessCardCustomDailySteps => '自定义每日步数';

  @override
  String get editableFitnessCardDailySteps => '每日步数';

  @override
  String get editableFitnessCardDailyStepsGoal => '每日步数目标';

  @override
  String get editableFitnessCardDays => '天';

  @override
  String get editableFitnessCardDuration => '时长';

  @override
  String get editableFitnessCardEG8500 => '例如 8500';

  @override
  String editableFitnessCardFailedToUpdate(Object error) {
    return '更新失败：$error';
  }

  @override
  String get editableFitnessCardFitnessGoal => '健身目标';

  @override
  String get editableFitnessCardFitnessLevel => '健身水平';

  @override
  String get editableFitnessCardFitnessSettingsUpdatedWor =>
      '健身设置已更新 - 训练计划将重新生成';

  @override
  String get editableFitnessCardGoal => '目标';

  @override
  String get editableFitnessCardGym => '健身房';

  @override
  String get editableFitnessCardInjuries => '伤病';

  @override
  String get editableFitnessCardLevel => '水平';

  @override
  String editableFitnessCardNAreas(Object count) {
    return '$count 个区域';
  }

  @override
  String get editableFitnessCardNoGym => '无健身房';

  @override
  String get editableFitnessCardNone => '无';

  @override
  String get editableFitnessCardNotSet => '未设置';

  @override
  String editableFitnessCardPartEditableFitnessCardStateExtMin(
    Object _selectedStretchDuration,
    Object _selectedWarmupDuration,
  ) {
    return '$_selectedWarmupDuration+$_selectedStretchDuration 分钟';
  }

  @override
  String editableFitnessCardPartEditableFitnessCardStateMin(
    Object _selectedWarmupDuration,
  ) {
    return '$_selectedWarmupDuration 分钟';
  }

  @override
  String editableFitnessCardPartEditableFitnessCardStateMin2(
    Object _selectedStretchDuration,
  ) {
    return '$_selectedStretchDuration 分钟';
  }

  @override
  String editableFitnessCardPartEditableFitnessCardStateMin3(Object duration) {
    return '$duration 分钟';
  }

  @override
  String editableFitnessCardPartEditableFitnessCardStateMin4(Object duration) {
    return '$duration 分钟';
  }

  @override
  String get editableFitnessCardPrep => '准备';

  @override
  String get editableFitnessCardSet => '组';

  @override
  String get editableFitnessCardSteps => '步数';

  @override
  String get editableFitnessCardStretch => '拉伸';

  @override
  String get editableFitnessCardWarmup => '热身';

  @override
  String get editableFitnessCardWarmupStretch => '热身 + 拉伸';

  @override
  String get editableFitnessCardWorkoutDays => '训练天数';

  @override
  String get editableFitnessCardWorkoutDuration => '训练时长';

  @override
  String get elevationProfileElevation => '海拔';

  @override
  String elevationProfileM(Object ascent) {
    return '+$ascent 米';
  }

  @override
  String elevationProfileM2(Object value) {
    return '$value 米';
  }

  @override
  String get emailPreferencesAFollowUpIf => '若预定时间过后未记录，发送跟进提醒';

  @override
  String get emailPreferencesAchievementUnlocks => '成就解锁';

  @override
  String get emailPreferencesBillingAccount => '账单与账户';

  @override
  String get emailPreferencesCheckInsFromYour => '教练签到 — 激活、回归、温和提醒';

  @override
  String get emailPreferencesDailyRemindersAboutYour => '关于您预定训练的每日提醒';

  @override
  String get emailPreferencesEmailPreferences => '电子邮件偏好';

  @override
  String get emailPreferencesFailedToLoadEmail => '无法加载电子邮件偏好';

  @override
  String get emailPreferencesKeepOnlyEssentialWorkout => '仅保留必要的训练提醒';

  @override
  String get emailPreferencesMissedWorkoutNudges => '漏练提醒';

  @override
  String get emailPreferencesMotivationalNudges => '激励提醒';

  @override
  String get emailPreferencesNewFeaturesAndApp => '新功能与应用改进';

  @override
  String get emailPreferencesOffersDiscounts => '优惠与折扣';

  @override
  String get emailPreferencesProductUpdates => '产品更新';

  @override
  String get emailPreferencesPurchaseBillingCancellatio => '购买、账单、取消（必选）';

  @override
  String emailPreferencesSectionControlWhatEmailsYou(Object appName) {
    return '管理你从$appName收到的电子邮件';
  }

  @override
  String get emailPreferencesSpecialOffersAndRe => '特别优惠与回归折扣';

  @override
  String get emailPreferencesStreakAlerts => '连胜提醒';

  @override
  String get emailPreferencesSundayRecapWithWorkouts => '周日回顾：包含训练、营养、连胜、XP';

  @override
  String get emailPreferencesThisWillTurnOff => '这将关闭所有营销邮件：';

  @override
  String get emailPreferencesTrophiesFirstWorkoutCeleb => '奖杯 + 首次训练庆祝';

  @override
  String get emailPreferencesUnsubscribe => '取消订阅';

  @override
  String get emailPreferencesUnsubscribeFromAllMarketing => '取消订阅所有营销邮件';

  @override
  String get emailPreferencesUnsubscribedFromMarketingEm => '已取消订阅营销邮件';

  @override
  String get emailPreferencesWeeklySummary => '每周总结';

  @override
  String get emailPreferencesWhenYourStreakIs => '当你的连续打卡记录即将中断时';

  @override
  String get emailPreferencesWorkoutReminders => '训练提醒';

  @override
  String get emailPreferencesYouWillStillReceive => '你仍将收到必要的训练提醒。';

  @override
  String get emailSignInAlreadyHaveAnAccount => '已有账号？';

  @override
  String get emailSignInAtLeast8Characters => '至少 8 个字符';

  @override
  String get emailSignInCreateAccount => '创建账号';

  @override
  String get emailSignInDonTHaveAn => '还没有账号？';

  @override
  String get emailSignInForgotPassword => '忘记密码？';

  @override
  String get emailSignInIfAnAccountExists => '如果该邮箱已注册，重置密码链接已发送。';

  @override
  String emailSignInScreenSupportIsNowYour(Object appName) {
    return '$appName 支持团队现在是您的好伙伴。随时联系我们获取帮助！';
  }

  @override
  String emailSignInScreenWelcomeTo(Object appName) {
    return '欢迎来到 $appName！';
  }

  @override
  String get emailSignInSignIn => '登录';

  @override
  String get emailSignInSignUp => '注册';

  @override
  String get emailSignInYouExampleCom => 'you@example.com';

  @override
  String get emailVerificationBannerResend => '重新发送';

  @override
  String get emailVerificationBannerVerifyYourEmailTo => '验证你的邮箱以保护账号安全。';

  @override
  String get embeddedCameraPanelFromGallery => '从相册选择';

  @override
  String get embeddedCameraPanelTryAgain => '重试';

  @override
  String get emptyCustomExercisesBuildCustomExercisesTailore =>
      '创建符合你需求的自定义动作，或将多个动作组合成强大的训练组合。';

  @override
  String get emptyCustomExercisesCreateYourFirstExercise => '创建你的第一个动作';

  @override
  String get emptyCustomExercisesCreateYourOwnExercises => '创建你自己的动作';

  @override
  String get emptyStateClearFilters => '清除筛选';

  @override
  String get emptyStateCompleteYourFirstWorkout => '完成你的第一次训练\n开始追踪进度！';

  @override
  String get emptyStateCreateProgram => '创建计划';

  @override
  String get emptyStateNoConnection => '无网络连接';

  @override
  String get emptyStateNoExercisesFound => '未找到动作';

  @override
  String get emptyStateNoResults => '无结果';

  @override
  String get emptyStateNoWorkoutHistory => '暂无训练记录';

  @override
  String get emptyStateNoWorkoutsYet => '暂无训练';

  @override
  String get emptyStatePleaseCheckYourInternet => '请检查你的网络连接\n并重试。';

  @override
  String get emptyStateTipGotIt => '知道了';

  @override
  String get emptyStateTryAdjustingYourFilters => '尝试调整筛选条件\n或搜索其他内容。';

  @override
  String get emptyStateWeCouldnTFind => '我们找不到你想要的内容。\n尝试使用其他关键词。';

  @override
  String get emptyStateYourWorkoutScheduleIs => '你的训练计划为空。\n先创建一个计划吧！';

  @override
  String get enhancedEmptyStateTryAsking => '试着问问...';

  @override
  String enhancedEmptyStateTryAsking2(Object name) {
    return '试着问问$name';
  }

  @override
  String get enhancedEmptyStateYourPersonalFitnessAssistan => '你的私人健身助手';

  @override
  String get enhancedNotesAddNotesAboutForm => '添加关于动作姿势、提示或修改的备注...';

  @override
  String get enhancedNotesCamera => '相机';

  @override
  String get enhancedNotesClear => '清除';

  @override
  String get enhancedNotesDictate => '听写';

  @override
  String get enhancedNotesExerciseNotes => '动作备注';

  @override
  String get enhancedNotesGallery => '相册';

  @override
  String get enhancedNotesListening => '正在聆听...';

  @override
  String get enhancedNotesListeningSpeakNow => '正在聆听...请讲';

  @override
  String get enhancedNotesMicrophonePermissionRequired => '需要麦克风权限';

  @override
  String get enhancedNotesRecord => '录音';

  @override
  String get enhancedNotesRecording => '正在录音...';

  @override
  String get enhancedNotesSpeechRecognitionNotAvailab => '语音识别不可用';

  @override
  String get enhancedNotesStop => '停止';

  @override
  String get enhancedNotesVoiceNote => '语音备注';

  @override
  String get environmentDetailAddCustomEquipment => '添加自定义器械';

  @override
  String get environmentDetailAddEquipment => '添加器械';

  @override
  String get environmentDetailAvailableWeights => '可用重量';

  @override
  String get environmentDetailBrowse => '浏览';

  @override
  String get environmentDetailCustom => '自定义';

  @override
  String get environmentDetailDiscard => '放弃';

  @override
  String get environmentDetailEG1525 => '例如：15, 25, 40';

  @override
  String get environmentDetailEG2 => '例如：2';

  @override
  String get environmentDetailEGAdjustable5 => '例如：可调节 5-50 磅';

  @override
  String get environmentDetailEGTrxBands => '例如：TRX 训练带';

  @override
  String get environmentDetailEquipmentName => '器械名称';

  @override
  String get environmentDetailEquipmentSaved => '器械已保存';

  @override
  String get environmentDetailHowManyDoYou => '你有多少个？';

  @override
  String get environmentDetailNoEquipmentAdded => '未添加器械';

  @override
  String get environmentDetailNotesOptional => '备注（可选）';

  @override
  String get environmentDetailQuantity => '数量';

  @override
  String get environmentDetailSaveChanges => '保存更改';

  @override
  String environmentDetailScreenEdit(Object displayName) {
    return '编辑 $displayName';
  }

  @override
  String environmentDetailScreenRemoved(Object displayName) {
    return '$displayName 已移除';
  }

  @override
  String environmentDetailScreenSwitchedTo(Object displayName) {
    return '已切换至 $displayName';
  }

  @override
  String get environmentDetailSearchEquipment => '搜索器械...';

  @override
  String get environmentDetailSeparateMultipleWeightsWith => '多个重量请用逗号分隔';

  @override
  String get environmentDetailTapAddEquipmentTo => '点击“添加器械”开始';

  @override
  String get environmentDetailThisIsYourActive => '这是你当前启用的环境';

  @override
  String get environmentDetailUndo => '撤销';

  @override
  String get environmentDetailUnsavedChanges => '未保存的更改';

  @override
  String get environmentDetailUseThis => '使用此项';

  @override
  String get environmentDetailYouHaveUnsavedChanges => '你有未保存的更改。离开前是否要保存？';

  @override
  String get environmentListActive => '已启用';

  @override
  String get environmentListAddCustomEnvironment => '添加自定义环境';

  @override
  String get environmentListChooseIcon => '选择图标';

  @override
  String get environmentListCreateEnvironment => '创建环境';

  @override
  String get environmentListEGBeachWorkout => '例如：海滩锻炼';

  @override
  String get environmentListEnvironmentName => '环境名称';

  @override
  String environmentListScreenEnvironmentSaved(Object name) {
    return '环境“$name”已保存';
  }

  @override
  String environmentListScreenEquipmentItems(Object length) {
    return '$length 件器械';
  }

  @override
  String environmentListScreenMore(Object currentEquipment) {
    return '+$currentEquipment 更多';
  }

  @override
  String get environmentListSelectYourWorkoutEnvironmen =>
      '选择您的锻炼环境，以自定义可用的器械。';

  @override
  String get environmentListUseThis => '使用此环境';

  @override
  String get environmentListWorkoutEnvironment => '锻炼环境';

  @override
  String get equipmentCalibration15x220x225x230x2 =>
      '15x2, 20x2, 25x2, 30x2, 35x2';

  @override
  String get equipmentCalibration175ForEz => 'EZ杆 17.5，奥林匹克杆 45';

  @override
  String get equipmentCalibration45x435x225x410x2 =>
      '45x4, 35x2, 25x4, 10x2, 5x2, 2.5x2';

  @override
  String get equipmentCalibration794ForEz => 'EZ杆 7.94，奥林匹克杆 20';

  @override
  String get equipmentCalibrationAddABarbellMachine => '添加杠铃、器械或绳索以覆盖默认设置。';

  @override
  String get equipmentCalibrationAddEquipment => '添加器械';

  @override
  String get equipmentCalibrationCalibration => '校准';

  @override
  String get equipmentCalibrationCouldNotLoadCalibrations => '无法加载校准数据';

  @override
  String get equipmentCalibrationEGHomeRack => '例如：家庭深蹲架 EZ杆';

  @override
  String get equipmentCalibrationEditEquipment => '编辑器械';

  @override
  String get equipmentCalibrationIntroBody =>
      '杠片建议和重量推荐将匹配您实际拥有的器材。设置杠铃重量、器械底盘重量、绳索机重量步进,以及杠片/哑铃库存。';

  @override
  String get equipmentCalibrationIntroTitle => '告诉我们您的真实器材';

  @override
  String get equipmentCalibrationLabelOptional => '标签（可选）';

  @override
  String get equipmentCalibrationLeaveBlankToUse => '留空以使用标准 IPF 配重';

  @override
  String get equipmentCalibrationLegPress20 => '腿举机：20';

  @override
  String get equipmentCalibrationLegPress45 => '腿举机：45';

  @override
  String get equipmentCalibrationNoCalibratedEquipmentYet => '暂无已校准的器械';

  @override
  String get equipmentCalibrationPlateMathWillFall => '配重计算将回退至标准默认值。';

  @override
  String get equipmentCalibrationRemove => '移除';

  @override
  String get equipmentCalibrationSaveChanges => '保存更改';

  @override
  String equipmentCalibrationScreenBarEmptyWeight(Object _weightUnit) {
    return '杠铃杆自重 ($_weightUnit)';
  }

  @override
  String equipmentCalibrationScreenMachineSledCarriage(Object _weightUnit) {
    return '器械滑块/配重架 ($_weightUnit)';
  }

  @override
  String equipmentCalibrationScreenPinStart(Object _weightUnit) {
    return '插销起始重量 ($_weightUnit)';
  }

  @override
  String equipmentCalibrationScreenPinStep(Object _weightUnit) {
    return '插销递增重量 ($_weightUnit)';
  }

  @override
  String get equipmentCalibrationSetBarSledCable => '设置杠铃 / 负重雪橇 / 绳索 / 配重库存';

  @override
  String get equipmentCalibrationTitle => '校准器材';

  @override
  String get equipmentCalibrationUnits => '单位';

  @override
  String get equipmentEquipment => '器械';

  @override
  String equipmentMatchCardExerciseYouCanDo(Object length, Object matches) {
    return '您可以在此进行 $length 项练习$matches';
  }

  @override
  String get equipmentMatchCardStartAWorkoutWith => '使用此器械开始锻炼';

  @override
  String get equipmentMatchCardUse => '使用';

  @override
  String get equipmentOfflineEquipmentOffline => '器械与离线';

  @override
  String get equipmentSearchAdd => '添加';

  @override
  String get equipmentSearchAddCustomEquipment => '添加自定义器械';

  @override
  String get equipmentSearchAddCustomEquipment2 => '添加自定义器械';

  @override
  String get equipmentSearchCanTFindYour => '找不到您的器械？';

  @override
  String get equipmentSearchCustom => '自定义';

  @override
  String get equipmentSearchEGHomemadePull => '例如：自制引体向上杆';

  @override
  String get equipmentSearchNoEquipmentFound => '未找到器械';

  @override
  String get equipmentSearchOtherEquipment => '其他器械';

  @override
  String get equipmentSearchSearchEquipment => '搜索器械...';

  @override
  String get equipmentSearchSearchFrom100Equipment => '从 100 多种器械中搜索';

  @override
  String equipmentSearchSheetAdd(Object _searchQuery) {
    return '添加“$_searchQuery”';
  }

  @override
  String equipmentSearchSheetSelected(Object length) {
    return '已选 $length 项';
  }

  @override
  String get equipmentSelectorEnterCustomEquipmentE =>
      '输入自定义器械（例如：\"TRX 弹力带\"）';

  @override
  String get equipmentSelectorEquipmentAvailable => '可用器械';

  @override
  String get equipmentSelectorOnlyGenerateExercisesWith => '仅生成使用所选器械的动作';

  @override
  String equipmentSelectorSelected(Object selectedCount) {
    return '已选$selectedCount项';
  }

  @override
  String get equipmentSnapFlowDescribeInstead => '改为描述';

  @override
  String get equipmentSnapFlowLooksABitBlurry => '看起来有点模糊';

  @override
  String get equipmentSnapFlowNotTheseDescribeInstead => '不是这些 — 改为描述';

  @override
  String get equipmentSnapFlowReplaceWithCardio => '替换为有氧运动？';

  @override
  String get equipmentSnapFlowRetake => '重拍';

  @override
  String equipmentSnapFlowSet(Object m, Object s) {
    return '组：$m:$s';
  }

  @override
  String get equipmentSnapFlowSomethingWentWrong => '出错了。';

  @override
  String get equipmentSnapFlowThisWillSwapSets => '这将把组数/次数替换为时长目标。继续吗？';

  @override
  String get equipmentSnapFlowTryAgain => '重试';

  @override
  String get equipmentSnapFlowUseAnyway => '仍然使用';

  @override
  String get equipmentSnapFlowWeReNot100 => '我们无法 100% 确定 — 请选择最接近的匹配项。';

  @override
  String get equipmentSnapFlowWhichOneIsIt => '这是哪一个？';

  @override
  String get eventBasedWorkout183DaysLeft => '还剩 183 天';

  @override
  String get eventBasedWorkoutEventBasedWorkout => '基于活动的锻炼';

  @override
  String get eventBasedWorkoutHigh => '高';

  @override
  String get eventBasedWorkoutTapToLearnMore => '点击了解更多';

  @override
  String get eventBasedWorkoutTrainForYourBig => '为您的重要日子进行训练';

  @override
  String get eventBasedWorkoutWeddingPrep => '婚礼筹备';

  @override
  String get eventLoggedUndoRemoved => '已移除';

  @override
  String get eventLoggedUndoSaved => '已保存';

  @override
  String get eventLoggedUndoUndo => '撤销';

  @override
  String get eventWorkoutComingEventBasedWorkouts => '基于活动的锻炼';

  @override
  String get eventWorkoutComingGotIt => '知道了！';

  @override
  String get eventWorkoutComingJune152026183 => '2026年6月15日 • 还剩 183 天';

  @override
  String get eventWorkoutComingTrainSmarterForYour => '为您的重要时刻更智能地训练';

  @override
  String get eventWorkoutComingWeddingPrep => '婚礼筹备';

  @override
  String get eventWorkoutComingWhatYouLlBe => '您将能够做到：';

  @override
  String get exerciseAddBadgeCustom => '自定义';

  @override
  String get exerciseAddBadgeFav => '收藏';

  @override
  String get exerciseAddBadgeStaple => '常用';

  @override
  String get exerciseAddNoMineYet => '暂无个人动作';

  @override
  String get exerciseAddNoMineYetHint => '添加收藏、常用或自定义动作以在此处查看';

  @override
  String get exerciseAddSearchMine => '搜索我的动作...';

  @override
  String get exerciseAddSectionCustom => '自定义动作';

  @override
  String get exerciseAddSectionFavorites => '收藏';

  @override
  String get exerciseAddSectionStaples => '常用动作';

  @override
  String get exerciseAddSheetAddExercise => '添加动作';

  @override
  String get exerciseAddSheetAiPicks => 'AI 精选';

  @override
  String get exerciseAddSheetAll => '全部';

  @override
  String get exerciseAddSheetCreateCustomExercisesOr =>
      '在“库 → 我的”中创建自定义动作或标记收藏';

  @override
  String get exerciseAddSheetFailedToAddExercise => '添加动作失败';

  @override
  String get exerciseAddSheetFindThePerfectExercise => '找到完美的动作添加到您的锻炼中';

  @override
  String get exerciseAddSheetGettingAiSuggestions => '正在获取 AI 建议...';

  @override
  String get exerciseAddSheetLibrary => '库';

  @override
  String get exerciseAddSheetMine => '我的';

  @override
  String get exerciseAddSheetNoCustomExercisesFavorites => '暂无自定义动作、收藏或常用动作';

  @override
  String get exerciseAddSheetNoSuggestionsAvailable => '暂无建议';

  @override
  String exerciseAddSheetPartExerciseAddSheetStateAdded(Object exerciseName) {
    return '已添加 $exerciseName';
  }

  @override
  String get exerciseAddSheetSearchExercises => '搜索动作...';

  @override
  String get exerciseAddSheetSearchMyExercises => '搜索我的动作...';

  @override
  String get exerciseAddSheetSnapEquipment => '拍摄器械';

  @override
  String get exerciseAddSheetSnapped => '已拍摄';

  @override
  String get exerciseAddSheetSubtitle => '副标题';

  @override
  String get exerciseAddSheetTabAiPicks => 'AI 精选';

  @override
  String get exerciseAddSheetTabLibrary => '库';

  @override
  String get exerciseAddSheetTabMine => '我的';

  @override
  String get exerciseAddSheetTabSnapped => '已拍摄';

  @override
  String get exerciseAddSheetTryAgain => '重试';

  @override
  String get exerciseAnalyticsCompareWithFriends => '与好友对比';

  @override
  String get exerciseAnalyticsCompleteMoreSessionsTo => '完成更多训练以查看趋势';

  @override
  String get exerciseAnalyticsDrop => '递减组';

  @override
  String get exerciseAnalyticsInviteFriends => '邀请好友';

  @override
  String get exerciseAnalyticsLastSession => '上次训练';

  @override
  String get exerciseAnalyticsMyAnalytics => '我的数据分析';

  @override
  String exerciseAnalyticsPageAnalytics(Object name) {
    return '$name 分析';
  }

  @override
  String exerciseAnalyticsPageSeeHowYourPerformance(Object name) {
    return '查看您在 $name 上的表现与好友的对比。';
  }

  @override
  String exerciseAnalyticsPageValue(Object _unit) {
    return '0 $_unit';
  }

  @override
  String get exerciseAnalyticsPersonalRecord => '个人纪录';

  @override
  String get exerciseAnalyticsQuickStats => '快速统计';

  @override
  String get exerciseAnalyticsSetTypeDistribution => '组别类型分布';

  @override
  String get exerciseAnalyticsTotalSessions => '总训练次数';

  @override
  String get exerciseAnalyticsTotalSets => '总组数';

  @override
  String get exerciseAnalyticsTotalVolume => '总容量';

  @override
  String get exerciseAnalyticsVolumeWeightXReps => '容量（重量 x 次数）趋势';

  @override
  String get exerciseAnalyticsWarmup => '热身';

  @override
  String get exerciseAnalyticsWeightProgression => '重量进展';

  @override
  String get exerciseAnalyticsWeightProgressionChart => '重量进展图表';

  @override
  String get exerciseAnalyticsWorking => '正式组';

  @override
  String exerciseBreakdownTemplateValue(Object reps, Object sets) {
    return '$sets × $reps';
  }

  @override
  String get exerciseCardAddToQueue => '加入队列';

  @override
  String get exerciseCardAddToWorkout => '加入训练';

  @override
  String exerciseCardAddedTo(Object exerciseName, Object name) {
    return '已将“$exerciseName”加入 $name';
  }

  @override
  String exerciseCardAddedToQueue(Object exerciseName) {
    return '已将“$exerciseName”加入队列';
  }

  @override
  String get exerciseCardAlreadyInQueue => '已在队列中';

  @override
  String get exerciseCardFailedToAddExercise => '添加动作失败';

  @override
  String get exerciseCardFailedToLoadWorkouts => '加载训练计划失败';

  @override
  String get exerciseCardGenerateAWorkoutPlan => '请先生成训练计划';

  @override
  String get exerciseCardNoUpcomingWorkouts => '暂无即将进行的训练';

  @override
  String get exerciseCardOrAddToWorkout => '或加入训练';

  @override
  String get exerciseCardWillBeIncludedIn => '将包含在下次训练中';

  @override
  String get exerciseDetailActionGuide => '动作指南';

  @override
  String get exerciseDetailAutoPlay => '自动播放';

  @override
  String get exerciseDetailDownloadFailed => '下载失败';

  @override
  String get exerciseDetailEachSide => '(单侧)';

  @override
  String get exerciseDetailEnterWeightLbs => '输入重量 (lbs)';

  @override
  String get exerciseDetailEquipmentNeeded => '所需器械';

  @override
  String get exerciseDetailGotIt => '知道了';

  @override
  String get exerciseDetailImage => '图片';

  @override
  String get exerciseDetailInstructions => '动作说明';

  @override
  String get exerciseDetailLevel => '难度等级';

  @override
  String get exerciseDetailLoadingVideo => '正在加载视频...';

  @override
  String get exerciseDetailMuscle => '目标肌肉';

  @override
  String get exerciseDetailNoHistoryForThis => '暂无此动作的历史记录';

  @override
  String get exerciseDetailPrevious => '上次记录';

  @override
  String get exerciseDetailPreviousPerformance => '过往表现';

  @override
  String get exerciseDetailRepRange => '建议次数范围';

  @override
  String get exerciseDetailRestTimer => '休息计时器';

  @override
  String get exerciseDetailScreenAlternative => '替代动作';

  @override
  String get exerciseDetailScreenAvoid => '避免';

  @override
  String get exerciseDetailScreenBreathing => '呼吸';

  @override
  String get exerciseDetailScreenCoachingCues => '教练提示';

  @override
  String get exerciseDetailScreenCompleteAWorkoutTo => '完成一次训练以开始追踪';

  @override
  String get exerciseDetailScreenDifficulty => '难度';

  @override
  String exerciseDetailScreenErrorLoadingHistory(Object error) {
    return '加载历史记录出错：$error';
  }

  @override
  String get exerciseDetailScreenExerciseInfo => '动作信息';

  @override
  String get exerciseDetailScreenFavorite => '收藏';

  @override
  String get exerciseDetailScreenForm => '动作要领';

  @override
  String exerciseDetailScreenMS(Object mins, Object secs) {
    return '$mins分 $secs秒';
  }

  @override
  String get exerciseDetailScreenNoStatsForThis => '暂无此动作的统计数据';

  @override
  String get exerciseDetailScreenNotes => '备注';

  @override
  String get exerciseDetailScreenQueue => '队列';

  @override
  String get exerciseDetailScreenSecondaryMuscles => '辅助肌肉';

  @override
  String get exerciseDetailScreenSetup => '设置';

  @override
  String get exerciseDetailScreenStaple => '核心动作';

  @override
  String get exerciseDetailScreenTempo => '节奏';

  @override
  String exerciseDetailScreenUiErrorLoadingStats(Object error) {
    return '加载统计数据出错：$error';
  }

  @override
  String exerciseDetailScreenUiRir(Object rir) {
    return 'RIR $rir';
  }

  @override
  String exerciseDetailScreenUiRir2(Object targetRir) {
    return 'RIR $targetRir';
  }

  @override
  String get exerciseDetailSet => '组';

  @override
  String get exerciseDetailSheetAvoid => '避免';

  @override
  String get exerciseDetailSheetDeleteDownload => '删除下载？';

  @override
  String get exerciseDetailSheetDownloadCancelled => '下载已取消';

  @override
  String get exerciseDetailSheetDownloadRemoved => '下载已移除';

  @override
  String exerciseDetailSheetDownloading(Object pct) {
    return '下载中 $pct%';
  }

  @override
  String get exerciseDetailSheetDownloadingVideo => '正在下载视频...';

  @override
  String get exerciseDetailSheetFavorite => '收藏';

  @override
  String exerciseDetailSheetLbs(Object repRange) {
    return ') 磅 × (repRange)';
  }

  @override
  String get exerciseDetailSheetLoading => '加载中...';

  @override
  String get exerciseDetailSheetLog1rm => '记录 1RM';

  @override
  String exerciseDetailSheetMS(Object restMins, Object restSecs) {
    return '$restMins 分 $restSecs 秒';
  }

  @override
  String get exerciseDetailSheetNoExercisesInCurrent => '当前训练中没有可替换的动作';

  @override
  String exerciseDetailSheetPartExerciseActionButtonsStateFailedToStaple(
    Object e,
  ) {
    return '固定失败：$e';
  }

  @override
  String exerciseDetailSheetPartExerciseActionButtonsStateReplacedWith(
    Object exerciseName,
    Object selected,
  ) {
    return '已将“$selected”替换为“$exerciseName”';
  }

  @override
  String exerciseDetailSheetPartExerciseActionButtonsStateStapledTo(
    Object exerciseName,
    Object section,
    Object timing,
  ) {
    return '已将“$exerciseName”固定到 $section ($timing)';
  }

  @override
  String exerciseDetailSheetPartExerciseActionButtonsStateUnstapled(
    Object exerciseName,
  ) {
    return '已取消固定“$exerciseName”';
  }

  @override
  String exerciseDetailSheetPartLog1RMButtonRemoveTheOfflineVideo(
    Object exerciseName,
  ) {
    return '移除“$exerciseName”的离线视频吗？你可以随时重新下载。';
  }

  @override
  String get exerciseDetailSheetQueue => '队列';

  @override
  String get exerciseDetailSheetReplaceWhichExercise => '替换哪个动作？';

  @override
  String exerciseDetailSheetSet(Object setNumber) {
    return '第 $setNumber 组';
  }

  @override
  String get exerciseDetailSheetStaple => '核心动作';

  @override
  String get exerciseDetailSheetTrackYourMaxStrength => '追踪你的最大力量';

  @override
  String get exerciseDetailStapleOptions => '核心动作选项';

  @override
  String get exerciseDetailTarget => '目标';

  @override
  String get exerciseDetailType => '类型';

  @override
  String get exerciseDetailVideo => '视频';

  @override
  String get exerciseDetailVideoNotAvailable => '视频不可用';

  @override
  String get exerciseDetailWillAutoPlayWhen => '准备好后将自动播放';

  @override
  String get exerciseDetailYourSessionsWillAppear => '您的训练记录将显示在此处';

  @override
  String get exerciseDetailsAiCoachTips => 'AI 教练提示';

  @override
  String get exerciseDetailsBodyweight => '自重';

  @override
  String get exerciseDetailsBreathing => '呼吸';

  @override
  String get exerciseDetailsDetails => '详情';

  @override
  String get exerciseDetailsDifficulty => '难度';

  @override
  String get exerciseDetailsDontHaveEquipment => '没有器械';

  @override
  String get exerciseDetailsEquipment => '器械';

  @override
  String get exerciseDetailsExerciseInfo => '动作信息';

  @override
  String get exerciseDetailsFormCues => '动作要领';

  @override
  String get exerciseDetailsNotSpecified => '未指定';

  @override
  String get exerciseDetailsPrimaryMuscle => '主要肌群';

  @override
  String get exerciseDetailsProTip => '专业提示';

  @override
  String get exerciseDetailsSecondaryMuscles => '次要肌群';

  @override
  String get exerciseDetailsSetup => '设置';

  @override
  String get exerciseDetailsSheetBodyweight => '自重';

  @override
  String get exerciseDetailsSheetBreathing => '呼吸';

  @override
  String get exerciseDetailsSheetDifficulty => '难度';

  @override
  String get exerciseDetailsSheetDonTHaveThis => '没有此器械？';

  @override
  String get exerciseDetailsSheetEquipment => '器械';

  @override
  String get exerciseDetailsSheetExerciseInfo => '动作信息';

  @override
  String get exerciseDetailsSheetFormCues => '动作要点';

  @override
  String get exerciseDetailsSheetLoadingAiCoachTips => '正在加载 AI 教练建议...';

  @override
  String get exerciseDetailsSheetPrimaryMuscle => '主要肌群';

  @override
  String get exerciseDetailsSheetProTip => '专业建议';

  @override
  String get exerciseDetailsSheetSecondaryMuscles => '次要肌群';

  @override
  String get exerciseDetailsSheetTapVideoToWatch => '点击“视频”观看动作演示';

  @override
  String get exerciseDetailsSheetVideo => '视频';

  @override
  String get exerciseDetailsSheetWatchOutFor => '注意事项';

  @override
  String get exerciseDetailsTapVideoHint => '点击视频提示';

  @override
  String get exerciseDetailsVideo => '视频';

  @override
  String get exerciseDetailsWatchOutFor => '注意事项';

  @override
  String get exerciseFilterApplyFilters => '应用筛选';

  @override
  String get exerciseFilterAvoidIfYouHave => '如有以下情况请避免';

  @override
  String get exerciseFilterBodyPart => '身体部位';

  @override
  String get exerciseFilterClearAll => '清除全部';

  @override
  String get exerciseFilterEquipment => '器械';

  @override
  String get exerciseFilterExerciseType => '动作类型';

  @override
  String get exerciseFilterFailedToLoadFilters => '筛选条件加载失败';

  @override
  String get exerciseFilterFilters => '筛选';

  @override
  String get exerciseFilterGoals => '目标';

  @override
  String get exerciseFilterSuitableFor => '适用人群';

  @override
  String get exerciseHistoryAllTime => '全部';

  @override
  String get exerciseHistoryCompleteSomeWorkoutsTo => '完成一些训练以查看您的动作历史记录并追踪进度。';

  @override
  String get exerciseHistoryExerciseHistory => '动作历史';

  @override
  String get exerciseHistoryExercisesPrs => '动作与 PR';

  @override
  String get exerciseHistoryFailedToLoadExercises => '动作加载失败';

  @override
  String get exerciseHistoryKeepTrainingAndPushing =>
      '继续训练，突破极限。当您变得更强时，个人纪录将显示在此处。';

  @override
  String get exerciseHistoryLast30Days => '最近 30 天';

  @override
  String get exerciseHistoryNoExerciseHistoryYet => '暂无动作历史';

  @override
  String get exerciseHistoryNoPersonalRecordsYet => '暂无个人纪录';

  @override
  String get exerciseHistoryPrStreak => 'PR 连胜';

  @override
  String get exerciseHistoryRecentPersonalRecords => '近期个人纪录';

  @override
  String exerciseHistoryScreenValue(Object timesPerformed) {
    return '$timesPerformed×';
  }

  @override
  String exerciseHistoryScreenValue2(Object pr) {
    return '+$pr%';
  }

  @override
  String exerciseHistoryScreenValue3(Object rank) {
    return '第 $rank 名';
  }

  @override
  String get exerciseHistorySearchExercises => '搜索动作...';

  @override
  String get exerciseHistoryTotalPrs => 'PR 总数';

  @override
  String get exerciseInfoLoadingVideo => '正在加载视频...';

  @override
  String get exerciseInfoRetrying => '正在重试';

  @override
  String get exerciseManagementMixinAiPoweredAlternatives => 'AI 驱动的替代动作';

  @override
  String get exerciseManagementMixinBreakTheSupersetPair => '取消超级组配对';

  @override
  String get exerciseManagementMixinChooseExerciseToPair => '选择要配对的动作';

  @override
  String get exerciseManagementMixinCreateSuperset => '创建超级组';

  @override
  String exerciseManagementMixinCreateSupersetWith(Object name) {
    return '与$name创建超级组';
  }

  @override
  String get exerciseManagementMixinMakeThisTheActive => '设为当前动作';

  @override
  String get exerciseManagementMixinNoAvailableExercisesTo => '没有可配对的动作';

  @override
  String get exerciseManagementMixinPairWithNextExercise => '与下一个动作配对';

  @override
  String get exerciseManagementMixinRemoveFromSuperset => '从超级组中移除';

  @override
  String get exerciseManagementMixinRemoveFromThisWorkout => '从本次训练中移除';

  @override
  String get exerciseManagementMixinReplaceExercise => '替换动作';

  @override
  String get exerciseManagementMixinSkipExercise => '跳过动作';

  @override
  String get exerciseManagementMixinStartThisExercise => '开始此动作';

  @override
  String get exerciseMenuAddToFavorites => '添加到收藏';

  @override
  String get exerciseMenuAddedToFavorites => '已添加到收藏';

  @override
  String get exerciseMenuLinkAsSuperset => '设为超级组';

  @override
  String get exerciseMenuMarkAsStaple => '标记为常用动作';

  @override
  String get exerciseMenuMarkedAsStaple => '已标记为常用动作';

  @override
  String get exerciseMenuNeverRecommend => '不再推荐';

  @override
  String get exerciseMenuQueuedForNext => '已加入下一次训练队列';

  @override
  String get exerciseMenuRemoveAsStaple => '取消常用动作';

  @override
  String get exerciseMenuRemoveFromFavorites => '从收藏中移除';

  @override
  String get exerciseMenuRemoveFromQueue => '从队列中移除';

  @override
  String get exerciseMenuRemoveFromWorkout => '从训练中移除';

  @override
  String get exerciseMenuRemovedFromFavorites => '已从收藏中移除';

  @override
  String get exerciseMenuRemovedFromQueue => '已从队列中移除';

  @override
  String get exerciseMenuRemovedFromStaples => '已取消常用动作标记';

  @override
  String get exerciseMenuRepeatNextTime => '下次重复';

  @override
  String get exerciseMenuSwapExercise => '更换动作';

  @override
  String get exerciseMenuViewHistory => '查看历史记录';

  @override
  String get exerciseMenuWhatDoTheseMean => '这些是什么意思？';

  @override
  String get exerciseMiniChartNotEnoughHistory => '历史记录不足';

  @override
  String get exerciseNavigationMixinApplyToAllLinked => '应用于所有关联动作？';

  @override
  String get exerciseNavigationMixinBarType => '杠铃类型';

  @override
  String get exerciseNavigationMixinCannotRemoveTheLast => '无法移除最后一个动作';

  @override
  String exerciseNavigationMixinChangedTo(Object displayName) {
    return '已更改为 $displayName';
  }

  @override
  String get exerciseNavigationMixinContinueAnyway => '仍然继续';

  @override
  String get exerciseNavigationMixinDoNotShowAgain => '不再显示';

  @override
  String get exerciseNavigationMixinEndWorkout => '结束训练';

  @override
  String exerciseNavigationMixinFailedToAddExercises(Object e) {
    return '添加动作失败: $e';
  }

  @override
  String exerciseNavigationMixinFailedToAddExercises2(Object e) {
    return '添加动作失败: $e';
  }

  @override
  String get exerciseNavigationMixinIncompleteExercises => '未完成的动作';

  @override
  String get exerciseNavigationMixinMyGym => '我的健身房';

  @override
  String get exerciseNavigationMixinNoJustThisOne => '不，仅此一个';

  @override
  String get exerciseNavigationMixinRemove => '移除';

  @override
  String get exerciseNavigationMixinRemoveExercise => '移除动作';

  @override
  String exerciseNavigationMixinRemoveFromThisWorkout(Object name) {
    return '从本次训练中移除 \"$name\"？';
  }

  @override
  String exerciseNavigationMixinRemoved(Object name) {
    return '已移除 $name';
  }

  @override
  String exerciseNavigationMixinRemovedFromSuperset(Object name) {
    return '已从超级组中移除 $name';
  }

  @override
  String exerciseNavigationMixinSetThisCountSets(Object newCount) {
    return '将超级组中所有动作的组数设为 $newCount 组？';
  }

  @override
  String get exerciseNavigationMixinSomeExercisesHaveMissing => '部分动作缺少记录：';

  @override
  String exerciseNavigationMixinSuperset(Object name, Object name1) {
    return '超级组: $name + $name1';
  }

  @override
  String exerciseNavigationMixinSuperset2(Object name) {
    return '超级组: $name';
  }

  @override
  String get exerciseNavigationMixinSwapExercise => '交换动作';

  @override
  String exerciseNavigationMixinUiRemoved(Object name) {
    return '已移除 $name';
  }

  @override
  String get exerciseNavigationMixinUndo => '撤销';

  @override
  String get exerciseNavigationMixinUseTheNotesSection => '使用组数下方的备注栏';

  @override
  String get exerciseNavigationMixinYesApplyToAll => '是，应用于所有';

  @override
  String get exerciseOptionsAddToSuperset => '添加到超级组';

  @override
  String get exerciseOptionsChangeEquipment => '更改器械';

  @override
  String get exerciseOptionsChangeRepsProgression => '更改次数进阶';

  @override
  String get exerciseOptionsExerciseHistory => '动作历史';

  @override
  String get exerciseOptionsInfoExerciseOptionsExplained => '动作选项说明';

  @override
  String get exerciseOptionsInfoFavorite => '收藏';

  @override
  String get exerciseOptionsInfoLinkAsSuperset => '设为超级组';

  @override
  String get exerciseOptionsInfoMarkAsACore =>
      '标记为核心动作，该动作将不会被轮换。AI 会始终将核心动作包含在您的训练计划中，非常适合您想要持续进行渐进式超负荷的复合动作。';

  @override
  String get exerciseOptionsInfoNeverRecommend => '不再推荐';

  @override
  String get exerciseOptionsInfoPairWithAnotherExercise =>
      '与其他动作配对，以极短的休息时间连续进行。非常适合提升训练效率和肌肉泵感。';

  @override
  String get exerciseOptionsInfoPermanentlyBlockThisExercis =>
      '永久屏蔽此动作，不再出现在AI推荐中。适用于你不喜欢或因伤无法进行的动作。';

  @override
  String get exerciseOptionsInfoQueueThisExerciseTo =>
      '将此动作加入下一次训练计划。适合你想重点强化的动作。加入队列的动作若7天内未进行，将会过期。';

  @override
  String get exerciseOptionsInfoRemoveFromWorkout => '从训练中移除';

  @override
  String get exerciseOptionsInfoRemoveThisExerciseFrom =>
      '仅从本次训练中移除该动作。该动作未来仍可能出现在训练计划中。';

  @override
  String get exerciseOptionsInfoRepeatNextTime => '下次重复';

  @override
  String get exerciseOptionsInfoReplaceWithASimilar =>
      '替换为针对相同肌肉群的类似动作。可从AI建议、近期替换记录中选择，或浏览完整动作库。';

  @override
  String get exerciseOptionsInfoSaveExercisesYouLove =>
      '收藏你喜爱的动作以便快速访问。收藏的动作会显示在动作库的筛选视图中，并在AI推荐中获得优先考虑。';

  @override
  String get exerciseOptionsInfoSeeYourPerformanceHistory =>
      '查看该动作随时间变化的表现历史和进度图表。';

  @override
  String get exerciseOptionsInfoStapleExercise => '固定动作';

  @override
  String get exerciseOptionsInfoSwapExercise => '替换动作';

  @override
  String get exerciseOptionsInfoViewHistory => '查看历史';

  @override
  String get exerciseOptionsNotes => '备注';

  @override
  String get exerciseOptionsRemoveAndDonT => '移除并不再推荐';

  @override
  String get exerciseOptionsRemoveFromWorkout => '从训练中移除';

  @override
  String get exerciseOptionsReportPain => '报告疼痛';

  @override
  String get exerciseOptionsSwapExercise => '替换动作';

  @override
  String get exerciseOptionsVideoInstructions => '视频与说明';

  @override
  String exercisePickerSheetAddAsCustom(Object name) {
    return '将“$name”添加为自定义动作';
  }

  @override
  String get exercisePickerSheetAddExerciseToAvoid => '添加要避免的动作';

  @override
  String get exercisePickerSheetAddFavoriteExercise => '添加收藏动作';

  @override
  String get exercisePickerSheetAddStapleExercise => '添加核心动作';

  @override
  String get exercisePickerSheetAddToExerciseQueue => '添加到训练队列';

  @override
  String get exercisePickerSheetAi => 'AI';

  @override
  String get exercisePickerSheetBodyPart => '身体部位';

  @override
  String get exercisePickerSheetCanTFindYour => '找不到你的动作？添加为自定义动作';

  @override
  String get exercisePickerSheetClearAll => '清除全部';

  @override
  String get exercisePickerSheetCreateCustomExercise => '创建自定义动作';

  @override
  String get exercisePickerSheetCustom => '自定义';

  @override
  String get exercisePickerSheetCustomOnly => '仅限自定义';

  @override
  String get exercisePickerSheetEquipment => '器械';

  @override
  String exercisePickerSheetNSelected(Object n) {
    return '已选 $n 个';
  }

  @override
  String get exercisePickerSheetNoExercisesFound => '未找到动作';

  @override
  String get exercisePickerSheetOrTypeAboveTo => '或在上方输入以搜索完整动作库';

  @override
  String exercisePickerSheetPartExercisePickerSheetStateShowingOf(
    Object length,
    Object length1,
  ) {
    return '显示 $length / $length1';
  }

  @override
  String exercisePickerSheetPartExercisePickerSheetStateValue(
    Object customCount,
  ) {
    return '($customCount)';
  }

  @override
  String exercisePickerSheetPartExercisePickerSheetStateValue2(
    Object count,
    Object name,
  ) {
    return '$name ($count)';
  }

  @override
  String get exercisePickerSheetSave => '保存';

  @override
  String exercisePickerSheetSaveN(Object n) {
    return '保存 ($n)';
  }

  @override
  String get exercisePickerSheetSearchForCoreLifts => '搜索要锁定的核心动作';

  @override
  String get exercisePickerSheetSearchForExercises => '搜索动作';

  @override
  String get exercisePickerSheetSearchForExercisesToAdd => '搜索要添加到收藏的动作';

  @override
  String get exercisePickerSheetSearchForExercisesToInclude =>
      '搜索要包含在下一次训练中的动作';

  @override
  String get exercisePickerSheetSearchForExercisesToSkip => '搜索要跳过的动作';

  @override
  String get exercisePickerSheetSearchTryPushRow => '搜索 — 尝试“推”、“划船”、“深蹲”';

  @override
  String get exercisePickerSheetSearching => '搜索中...';

  @override
  String get exercisePickerSheetShowingResultsFor => '显示结果：';

  @override
  String get exercisePickerSheetTapExercisesToSelect => '点击动作以多选';

  @override
  String get exercisePickerSheetTryADifferentSearch => '尝试不同的搜索或筛选条件';

  @override
  String get exercisePickerSheetType => '类型';

  @override
  String get exercisePickerSheetTypeToSearchOr => '输入以搜索，或使用筛选器进行浏览';

  @override
  String get exercisePickerSheetYourCustomExercises => '你的自定义动作';

  @override
  String get exercisePreferencesCardAiWillPrioritizeThese => 'AI将优先考虑这些动作';

  @override
  String exercisePreferencesCardAvoided(Object avoidedCount) {
    return '$avoidedCount 个已避开';
  }

  @override
  String get exercisePreferencesCardCooldownStretch => '冷身拉伸';

  @override
  String get exercisePreferencesCardCoreLiftsThatNever => '从不轮换的核心动作';

  @override
  String get exercisePreferencesCardCustomExercises => '自定义动作';

  @override
  String get exercisePreferencesCardCustomizeStepPerEquipme => '自定义每种器械的增重幅度';

  @override
  String get exercisePreferencesCardCustomizeWhichExercisesAppe =>
      '自定义训练中出现的动作';

  @override
  String get exercisePreferencesCardDynamicWarmupBeforeWorkouts => '训练前动态热身';

  @override
  String get exercisePreferencesCardEnableOrDisableWorkout => '启用或禁用训练阶段';

  @override
  String get exercisePreferencesCardExercisePreferences => '动作偏好';

  @override
  String get exercisePreferencesCardExercisePreferences2 => '动作偏好';

  @override
  String get exercisePreferencesCardExercisePreferencesExplained => '动作偏好说明';

  @override
  String get exercisePreferencesCardExerciseQueue => '动作队列';

  @override
  String exercisePreferencesCardExercises(Object customCount) {
    return '$customCount 个动作';
  }

  @override
  String exercisePreferencesCardExercises2(Object favoriteCount) {
    return '$favoriteCount 个动作';
  }

  @override
  String exercisePreferencesCardExercises3(Object stapleCount) {
    return '$stapleCount 个动作';
  }

  @override
  String get exercisePreferencesCardExercisesToAvoid => '要避免的动作';

  @override
  String get exercisePreferencesCardFavoriteExercises => '收藏的动作';

  @override
  String get exercisePreferencesCardFavoritesAvoidedQueue => '收藏、屏蔽、队列';

  @override
  String get exercisePreferencesCardIncompleteExerciseWarning => '未完成动作警告';

  @override
  String get exercisePreferencesCardMusclesToAvoid => '要避免的肌肉群';

  @override
  String get exercisePreferencesCardQueueExercisesForNext => '将动作加入下一次训练';

  @override
  String exercisePreferencesCardQueued(Object queueCount) {
    return '$queueCount 个已排队';
  }

  @override
  String get exercisePreferencesCardSkipOrReduceMuscle => '跳过或减少特定肌肉群训练';

  @override
  String get exercisePreferencesCardSkipSpecificExercises => '跳过特定动作';

  @override
  String get exercisePreferencesCardStapleExercises => '固定动作';

  @override
  String get exercisePreferencesCardStretchingAfterWorkouts => '训练后拉伸';

  @override
  String get exercisePreferencesCardWarmupCooldown => '热身与冷身';

  @override
  String get exercisePreferencesCardWarmupPhase => '热身阶段';

  @override
  String get exercisePreferencesCardWarnBeforeFinishingWith =>
      '结束前若有未记录的组数进行警告';

  @override
  String get exercisePreferencesCardWeightIncrements => '重量增幅';

  @override
  String get exercisePreferencesCardWhatSThis => '这是什么？';

  @override
  String get exercisePreferencesCardWorkoutMode => '训练模式';

  @override
  String get exercisePreferencesCardYourPersonalExerciseLibrary => '你的个人动作库';

  @override
  String get exercisePreviewOverlayFormDemo => '动作演示';

  @override
  String exercisePreviewOverlayS(Object _remainingSeconds) {
    return '$_remainingSeconds 秒';
  }

  @override
  String get exercisePreviewOverlayTapAnywhereToStart => '点击任意位置开始';

  @override
  String exercisePreviewOverlayTarget(Object muscles) {
    return '目标：$muscles';
  }

  @override
  String get exerciseProgressDetail => '•  ';

  @override
  String get exerciseProgressDetailHistory => '历史';

  @override
  String get exerciseProgressDetailInsights => '洞察';

  @override
  String get exerciseProgressDetailNoDataForThis => '暂无此动作数据';

  @override
  String get exerciseProgressDetailNoSessionsRecorded => '暂无记录的训练';

  @override
  String get exerciseProgressDetailProgress => '进度';

  @override
  String get exerciseProgressionsAdvance => '进阶';

  @override
  String get exerciseProgressionsAdvanceProgression => '进行进阶？';

  @override
  String get exerciseProgressionsBestLoad => '最佳负重';

  @override
  String get exerciseProgressionsBestReps => '最佳次数';

  @override
  String get exerciseProgressionsEarnTheHarderVariant => '解锁更高难度变式';

  @override
  String get exerciseProgressionsLoadingYourProgressions => '正在加载你的进阶进度...';

  @override
  String get exerciseProgressionsMasteryProgress => '掌握进度';

  @override
  String get exerciseProgressionsNoProgressionsYet => '暂无进阶';

  @override
  String get exerciseProgressionsNotYet => '暂不';

  @override
  String get exerciseProgressionsOneMoreTooEasy => '再完成一次“太简单”的训练即可解锁下一个变式。';

  @override
  String get exerciseProgressionsOtherTrackedExercises => '其他已追踪动作';

  @override
  String get exerciseProgressionsProgressions => '进阶';

  @override
  String get exerciseProgressionsReadyToAdvance => '准备进阶';

  @override
  String get exerciseProgressionsReadyToAdvance2 => '准备进阶';

  @override
  String get exerciseProgressionsReadyToProgress => '准备进阶';

  @override
  String get exerciseProgressionsRefresh => '刷新';

  @override
  String exerciseProgressionsScreenAdvanceTo(Object suggestedExercise) {
    return '进阶至 $suggestedExercise';
  }

  @override
  String exerciseProgressionsScreenChain(Object chainName) {
    return '$chainName 链';
  }

  @override
  String exerciseProgressionsScreenConfident(Object confidencePct) {
    return '$confidencePct% 确定';
  }

  @override
  String exerciseProgressionsScreenCouldNotAdvance(Object e) {
    return '无法进阶: $e';
  }

  @override
  String exerciseProgressionsScreenDifficulty(Object difficultyLevel) {
    return '难度 $difficultyLevel/10';
  }

  @override
  String exerciseProgressionsScreenEasySessions(
    Object _target,
    Object consecutiveEasy,
  ) {
    return '$consecutiveEasy / $_target 次轻松训练';
  }

  @override
  String exerciseProgressionsScreenKg(Object mastery) {
    return '$mastery kg';
  }

  @override
  String exerciseProgressionsScreenReps(Object currentMaxReps) {
    return '$currentMaxReps 次';
  }

  @override
  String exerciseProgressionsScreenSessionsBest(Object totalSessions) {
    return '$totalSessions 次训练 · 最佳 ';
  }

  @override
  String exerciseProgressionsScreenYouWillMoveFrom(
    Object exerciseName,
    Object suggestedExercise,
  ) {
    return '你将从 $exerciseName 进阶至 $suggestedExercise。';
  }

  @override
  String get exerciseProgressionsSessions => '训练课';

  @override
  String get exerciseProgressionsTryAgain => '重试';

  @override
  String get exerciseProgressionsUnlocked => '已解锁';

  @override
  String get exerciseProgressionsYourProgressionChains => '你的进阶链';

  @override
  String get exerciseQueue => ' • ';

  @override
  String get exerciseQueueAddToQueue => '加入队列';

  @override
  String get exerciseQueueExerciseQueue => '训练队列';

  @override
  String get exerciseQueueNoExercisesQueued => '暂无队列中的训练';

  @override
  String get exerciseQueueQueuedExercisesWillBe =>
      '队列中的训练将包含在你的下一次锻炼中。项目将在7天后过期。';

  @override
  String get exerciseQueueRemove => '移除';

  @override
  String get exerciseQueueRemoveFromQueue => '从队列中移除？';

  @override
  String exerciseQueueScreenAddedToQueue(Object exerciseName) {
    return '已将 “$exerciseName” 加入队列';
  }

  @override
  String exerciseQueueScreenExpiresInDays(Object daysLeft) {
    return '$daysLeft 天后过期';
  }

  @override
  String exerciseQueueScreenRemoveFromYourQueue(Object exerciseName) {
    return '确定要从队列中移除 “$exerciseName” 吗？它将不会出现在你的下一次训练中。';
  }

  @override
  String get exerciseQueueTheseExercisesWillBe =>
      '这些训练将包含在你的下一次锻炼中。队列项目将在7天后过期。';

  @override
  String get exerciseSafetyAuditAllExercisesTagged => '所有训练已标记！';

  @override
  String get exerciseSafetyAuditFailedToLoadExercises => '加载训练失败';

  @override
  String get exerciseSafetyAuditInjurySafeFlags => '损伤安全标记';

  @override
  String get exerciseSafetyAuditMovementPattern => '动作模式';

  @override
  String get exerciseSafetyAuditNoDifficulty => '无难度';

  @override
  String get exerciseSafetyAuditNoExercisesPendingManual => '没有待人工审核的训练。';

  @override
  String get exerciseSafetyAuditNoPattern => '无模式';

  @override
  String get exerciseSafetyAuditOptionalCiteSourceExplain =>
      '可选：引用来源、解释边缘情况、标记歧义...';

  @override
  String get exerciseSafetyAuditRefresh => '刷新';

  @override
  String get exerciseSafetyAuditReview => '审核';

  @override
  String get exerciseSafetyAuditReviewerNotes => '审核员备注';

  @override
  String get exerciseSafetyAuditSafetyDifficulty => '安全难度';

  @override
  String get exerciseSafetyAuditSafetyTagAudit => '安全标签审核';

  @override
  String get exerciseSafetyAuditSaveTags => '保存标签';

  @override
  String exerciseSafetyAuditScreenExerciseSPendingAudit(Object length) {
    return '$length 个动作待审核';
  }

  @override
  String get exerciseSafetyAuditSelectDifficulty => '选择难度';

  @override
  String get exerciseSafetyAuditSelectMovementPattern => '选择动作模式';

  @override
  String get exerciseSafetyAuditTryAgain => '重试';

  @override
  String get exerciseScienceResearchAllTrainingParametersAre =>
      '所有训练参数均源自同行评审的运动科学文献。个人结果可能有所不同。';

  @override
  String get exerciseScienceResearchAmericanCollegeOfSports => '美国运动医学会 (ACSM)';

  @override
  String get exerciseScienceResearchAndroulakisKorakakisPFis =>
      'Androulakis-Korakakis, P., Fisher, J. P. & Steele, J.';

  @override
  String get exerciseScienceResearchBarbaRuizCEt => 'Barba-Ruiz, C. 等';

  @override
  String get exerciseScienceResearchEffectsOfSupersetConfigurat =>
      '超级组配置对杠铃卧推中动力学、运动学和感知用力程度的影响';

  @override
  String get exerciseScienceResearchEpleyBrzyckiMayhewHelms =>
      'Epley, Brzycki, Mayhew / Helms, E. R. 等';

  @override
  String get exerciseScienceResearchEssentialsOfStrengthTrainin =>
      '力量训练与体能调节基础';

  @override
  String get exerciseScienceResearchEverySubmittedSourceIs =>
      '每一份提交的来源在加入知识库之前，都会经过人工审核和验证。';

  @override
  String get exerciseScienceResearchEvidenceBasedTraining => '循证训练';

  @override
  String get exerciseScienceResearchFeedDataToRag => '输入数据至 RAG';

  @override
  String get exerciseScienceResearchFeedYourOwnResearch =>
      '将你自己的研究论文、训练数据库和训练方法输入到我们的 RAG（检索增强生成）系统中。这使得 AI 教练在生成个性化训练计划时能够参考更多高质量来源，从而使建议更智能，并更贴合前沿科学。';

  @override
  String get exerciseScienceResearchFonsecaRMEt => 'Fonseca, R. M. 等';

  @override
  String get exerciseScienceResearchGoldsteinANLeung =>
      'Goldstein, A. N. & Leung, E.';

  @override
  String get exerciseScienceResearchGuidelinesForExerciseTestin => '运动测试与处方指南';

  @override
  String get exerciseScienceResearchHaffGGTriplett =>
      'Haff, G. G. & Triplett, N. T.';

  @override
  String get exerciseScienceResearchHowItWorks => '工作原理';

  @override
  String get exerciseScienceResearchImportantGuidelines => '重要指南';

  @override
  String get exerciseScienceResearchIsraetelMRpStrength =>
      'Israetel, M. / RP Strength';

  @override
  String get exerciseScienceResearchKeyFindings => '关键发现';

  @override
  String get exerciseScienceResearchResearch => '研究';

  @override
  String exerciseScienceResearchScreenEveryWorkoutParameterIn(Object appName) {
    return '$appName 中的每个训练参数均源自同行评审的运动科学研究。点击论文查看详情。';
  }

  @override
  String exerciseScienceResearchScreenHowUsesThis(Object appName) {
    return '$appName 如何使用这些研究';
  }

  @override
  String exerciseScienceResearchScreenValue(Object journal, Object year) {
    return '$journal, $year';
  }

  @override
  String get exerciseScienceResearchUploadData => '上传数据';

  @override
  String get exerciseScienceResearchUploadPdfsArticlesOr =>
      '上传包含运动科学研究的 PDF、文章或文本文件。我们的系统会处理并索引这些内容，使其在 AI 生成你的训练计划时作为背景知识使用。';

  @override
  String get exerciseScienceResearchZourdosMCEt => 'Zourdos, M. C. 等';

  @override
  String get exerciseSearchBarSearchExercisesOrEquipment => '搜索训练或器械...';

  @override
  String get exerciseSearchBarSearchPrograms => '搜索计划...';

  @override
  String exerciseSearchResultsBest(Object bestSetDisplay) {
    return '最佳：$bestSetDisplay';
  }

  @override
  String get exerciseSearchResultsFailedToSearchExercises => '搜索训练失败';

  @override
  String exerciseSearchResultsMoreWorkouts(Object results) {
    return '+$results 更多训练';
  }

  @override
  String get exerciseSearchResultsNoResultsFound => '未找到结果';

  @override
  String exerciseSearchResultsNoWorkoutsContainingIn(Object exerciseName) {
    return '在选定时间范围内没有包含 \"$exerciseName\" 的训练';
  }

  @override
  String exerciseSearchResultsSets(Object setsCompleted) {
    return '$setsCompleted 组';
  }

  @override
  String exerciseSearchResultsWorkoutsFound(
    Object exerciseName,
    Object totalResults,
  ) {
    return '\"$exerciseName\" - 找到 $totalResults 次训练';
  }

  @override
  String get exerciseSetTracker15s => '−15秒';

  @override
  String get exerciseSetTracker15s2 => '+15秒';

  @override
  String get exerciseSetTrackerAddNotesHere => '在此添加备注...';

  @override
  String get exerciseSetTrackerAddSet => '添加组';

  @override
  String get exerciseSetTrackerBarbell => ') 杠铃';

  @override
  String get exerciseSetTrackerReps => '次数';

  @override
  String get exerciseSetTrackerRestTarget => '休息目标';

  @override
  String exerciseSetTrackerS(Object seconds) {
    return '$seconds秒';
  }

  @override
  String exerciseSetTrackerSavedAsYourDefault(Object muscle) {
    return '已保存为 $muscle 的默认设置';
  }

  @override
  String get exerciseSetTrackerSet => '组';

  @override
  String get exerciseSetTrackerTarget => '目标';

  @override
  String get exerciseStatsAvgRpe => '平均 RPE';

  @override
  String get exerciseStatsEst1rm => '预估 1RM';

  @override
  String get exerciseStatsMaxReps => '最大次数';

  @override
  String get exerciseStatsMaxWeight => '最大重量';

  @override
  String get exerciseStatsProgression => '进阶';

  @override
  String exerciseStatsSheetKg(Object item) {
    return '$item kg';
  }

  @override
  String exerciseStatsSheetKg2(Object item) {
    return '$item kg';
  }

  @override
  String get exerciseStatsTotalSets => '总组数';

  @override
  String get exerciseStatsVolume => '容量';

  @override
  String exerciseStatsWidgetsAchieved(Object formattedAchievedDate) {
    return '达成日期：$formattedAchievedDate';
  }

  @override
  String get exerciseStatsWidgetsEst1rm => '预估 1RM';

  @override
  String get exerciseStatsWidgetsNotEnoughDataTo => '数据不足，无法显示图表';

  @override
  String get exerciseStatsWidgetsPersonalRecords => '个人纪录';

  @override
  String get exerciseStatsWidgetsSessions => '训练课';

  @override
  String get exerciseStatsWidgetsSetsReps => '组数 × 次数';

  @override
  String get exerciseStatsWidgetsSummary => '摘要';

  @override
  String get exerciseStatsWidgetsTotalVolume => '总容量';

  @override
  String exerciseStatsWidgetsTrainingFrequency(Object formattedFrequency) {
    return '训练频率：$formattedFrequency';
  }

  @override
  String get exerciseStatsWidgetsVolume => '容量';

  @override
  String get exerciseStatsWidgetsWeight => '重量';

  @override
  String get exerciseStatsWidgetsWeightChange => '重量变化';

  @override
  String get exerciseSwapAiUnavailable => 'AI 建议暂不可用';

  @override
  String get exerciseSwapAskAiHint => '例如：针对我肩膀不适的动作...';

  @override
  String get exerciseSwapAskAiTitle => '向 AI 寻求建议';

  @override
  String get exerciseSwapBadgeBestMatch => '最佳匹配';

  @override
  String get exerciseSwapBadgeTopPick => '首选推荐';

  @override
  String get exerciseSwapFindingAlternatives => '正在寻找最佳替代方案';

  @override
  String get exerciseSwapGetAiSuggestions => '获取 AI 建议';

  @override
  String get exerciseSwapInstructions => '说明';

  @override
  String get exerciseSwapListeningNow => '正在聆听...请讲';

  @override
  String get exerciseSwapMatchingEquipment => '正在匹配器械、肌肉群及你的训练历史';

  @override
  String get exerciseSwapNoAlternatives => '未找到替代方案';

  @override
  String get exerciseSwapOptionSwap => '选项替换';

  @override
  String get exerciseSwapSheetAiPicks => 'AI 推荐';

  @override
  String get exerciseSwapSheetAiPicksUnavailable => 'AI 推荐不可用';

  @override
  String get exerciseSwapSheetAnyEquipment => '任何器械';

  @override
  String get exerciseSwapSheetAskAiForSuggestions => '向 AI 寻求建议';

  @override
  String get exerciseSwapSheetDescribeYourEquipmentOr =>
      '描述您的器械或偏好\n例如：“肩膀不适，仅限自重”';

  @override
  String get exerciseSwapSheetEGIOnly => '例如：“我只有哑铃”';

  @override
  String get exerciseSwapSheetFailedToSwapExercise => '替换动作失败';

  @override
  String get exerciseSwapSheetFindingMuscleMatchedAlterna => '正在寻找肌肉匹配的替代动作...';

  @override
  String get exerciseSwapSheetFindingSimilarExercises => '正在寻找相似动作...';

  @override
  String get exerciseSwapSheetFindingYourBestAlternatives => '正在寻找最适合您的替代动作';

  @override
  String get exerciseSwapSheetGetAiSuggestions => '获取 AI 建议';

  @override
  String get exerciseSwapSheetImport => '导入';

  @override
  String get exerciseSwapSheetInstructions => '说明';

  @override
  String get exerciseSwapSheetLibrary => '动作库';

  @override
  String get exerciseSwapSheetListeningSpeakNow => '正在聆听...请讲';

  @override
  String get exerciseSwapSheetLoadingRecentExercises => '正在加载最近动作...';

  @override
  String get exerciseSwapSheetMatchingEquipmentMusclesA => '正在匹配器械、肌肉和您的训练记录';

  @override
  String get exerciseSwapSheetNoAlternativesYet => '暂无替代动作';

  @override
  String get exerciseSwapSheetNoRecentSwaps => '暂无最近替换记录';

  @override
  String exerciseSwapSheetPartExerciseSwapSheetStateSwappedTo(
    Object newExerciseName,
  ) {
    return '已替换为 $newExerciseName';
  }

  @override
  String get exerciseSwapSheetReason => '原因：';

  @override
  String get exerciseSwapSheetRecent => '最近';

  @override
  String get exerciseSwapSheetReplacing => '正在替换';

  @override
  String get exerciseSwapSheetSearchExercises => '搜索动作...';

  @override
  String get exerciseSwapSheetSimilar => '相似';

  @override
  String get exerciseSwapSheetSnapEquipment => '拍摄器械';

  @override
  String get exerciseSwapSheetSnapped => '已拍摄';

  @override
  String get exerciseSwapSheetSpeechRecognitionNotAvailab => '语音识别不可用';

  @override
  String get exerciseSwapSheetSwap => '替换';

  @override
  String get exerciseSwapSheetSwapExercise => '替换动作';

  @override
  String get exerciseSwapSheetSwapToThisExercise => '替换为此动作';

  @override
  String get exerciseSwapSheetTabAnyEquipment => '任何器械';

  @override
  String get exerciseSwapSheetTabRecent => '最近';

  @override
  String get exerciseSwapSheetTabSimilar => '相似';

  @override
  String get exerciseSwapSheetTabSnapped => '已锁定';

  @override
  String get exerciseSwapSheetTitle => '标题';

  @override
  String get exerciseSwapSheetTryAgain => '重试';

  @override
  String get exerciseSwapSheetTryAiSuggestions => '尝试 AI 建议';

  @override
  String get exerciseSwapSheetTryRephrasingYourRequest =>
      '请尝试重新表述您的要求，选择不同的原因，或查看“动作库”标签页。';

  @override
  String get exerciseSwapSheetYourSwapHistoryWill => '您的替换历史将显示在此处';

  @override
  String get exerciseSwapSwapToThis => '切换为此动作';

  @override
  String get exerciseSwapTryRephrasing => '请尝试换种说法';

  @override
  String get exerciseTableHeaderLast => '上次';

  @override
  String get exerciseTableHeaderSet => '组数';

  @override
  String get exerciseTableHeaderTarget => '目标';

  @override
  String get exercisesLoadMore => '加载更多';

  @override
  String exercisesTabFailedToLoadExercises(Object error) {
    return '加载练习失败：$error';
  }

  @override
  String get exercisesTabHistoryToggle => 'History';

  @override
  String expandableSummaryExerciseCardKg(Object weightKg) {
    return '$weightKg kg';
  }

  @override
  String expandableSummaryExerciseCardTime(Object formatted) {
    return '时长: $formatted';
  }

  @override
  String get expandableSummaryExerciseReps => '次数';

  @override
  String get expandableSummaryExerciseSet => '组数';

  @override
  String get expandableSummaryExerciseVsPreviousSession => '对比上次训练';

  @override
  String get expandableSummaryExerciseWeight => '重量';

  @override
  String get expandedExerciseCardAddToFavorites => '添加到收藏';

  @override
  String get expandedExerciseCardAlternatingHands => '交替手';

  @override
  String get expandedExerciseCardBarbell => ') 杠铃';

  @override
  String get expandedExerciseCardBreathing => '呼吸';

  @override
  String get expandedExerciseCardBreathingGuide => '呼吸指南';

  @override
  String get expandedExerciseCardCollapse => '收起';

  @override
  String get expandedExerciseCardDetails => '详情';

  @override
  String get expandedExerciseCardFavorite => '收藏';

  @override
  String get expandedExerciseCardLinkAsSuperset => '设为超级组';

  @override
  String get expandedExerciseCardMarkAsStaple => '标记为常用动作';

  @override
  String get expandedExerciseCardNeverRecommend => '不再推荐';

  @override
  String get expandedExerciseCardQueued => '已加入队列';

  @override
  String get expandedExerciseCardRemoveAsStaple => '取消常用动作';

  @override
  String get expandedExerciseCardRemoveFromFavorites => '取消收藏';

  @override
  String get expandedExerciseCardRemoveFromQueue => '从队列移除';

  @override
  String get expandedExerciseCardRemoveFromWorkout => '从训练中移除';

  @override
  String get expandedExerciseCardRepeatNextTime => '下次重复此设置';

  @override
  String get expandedExerciseCardRestTimer => '休息计时器：';

  @override
  String get expandedExerciseCardStaple => '常用';

  @override
  String get expandedExerciseCardSwapExercise => '替换动作';

  @override
  String get expandedExerciseCardTarget => '目标';

  @override
  String get expandedExerciseCardViewHistory => '查看历史';

  @override
  String get expandedExerciseCardWhatDoTheseMean => '这些是什么意思？';

  @override
  String get exportDataAlwaysIncludedForCardio => '有氧运动格式始终包含此项。';

  @override
  String get exportDataCardioSessions => '有氧训练记录';

  @override
  String get exportDataCustom => '自定义...';

  @override
  String get exportDataDisabledThisFormatIs => '已禁用 — 此格式仅适用于有氧运动。';

  @override
  String get exportDataExportMyData => '导出我的数据';

  @override
  String get exportDataExportedAsText => '数据已成功导出为文本！';

  @override
  String get exportDataExportedSuccessfully => '数据导出成功！';

  @override
  String get exportDataGenerateExport => '生成导出文件';

  @override
  String get exportDataGenerating => '正在生成...';

  @override
  String get exportDataNotApplicableForCardio => '不适用于有氧运动格式。';

  @override
  String get exportDataPickAtLeastOne => '请至少选择一个数据集进行导出。';

  @override
  String get exportDataProgramTemplates => '训练计划模板';

  @override
  String exportDataScreenGdprArtCompliant(Object appName) {
    return '$appName。符合 GDPR 第 20 条规定。';
  }

  @override
  String exportDataScreenNativeSchemaMaximumFidelity(Object appName) {
    return '$appName 原生架构。最高保真度。';
  }

  @override
  String get exportDataStrengthHistory => '力量训练历史';

  @override
  String get exportDataYourDataIsYours => '数据属于您自己 — 随时随地随身携带。';

  @override
  String get exportDialogPartCsvZip => 'CSV/ZIP';

  @override
  String get exportDialogPartDataToExport => '待导出数据';

  @override
  String get exportDialogPartEnd => '结束';

  @override
  String get exportDialogPartExcel => 'Excel';

  @override
  String get exportDialogPartExport => '导出';

  @override
  String exportDialogPartExportDataDialogExportData(Object appName) {
    return '导出$appName数据';
  }

  @override
  String get exportDialogPartExportFormat => '导出格式';

  @override
  String get exportDialogPartExportInfo => '导出信息';

  @override
  String get exportDialogPartExportedData => '已导出数据';

  @override
  String get exportDialogPartFormats => '格式';

  @override
  String get exportDialogPartGotIt => '知道了';

  @override
  String get exportDialogPartParquet => 'Parquet';

  @override
  String get exportDialogPartPlainText => '纯文本';

  @override
  String get exportDialogPartProfileIsAlwaysIncluded => '个人资料将始终包含在内。';

  @override
  String get exportDialogPartTimeRange => '时间范围';

  @override
  String get exportDialogPartYourDataWillBe => '您的数据将导出为包含 CSV 文件的 ZIP 文件。';

  @override
  String get exportExportingYourData => '正在导出数据...';

  @override
  String get exportExportingYourDataAs => '正在导出文本数据...';

  @override
  String get exportNoDataReceivedFrom => '未从服务器接收到数据';

  @override
  String get exportStatsCsvZip => 'CSV / ZIP';

  @override
  String get exportStatsExportStats => '导出统计数据';

  @override
  String get exportStatsFullDataExportWith => '完整数据导出，包含所有训练、PR 和身体测量数据';

  @override
  String get exportStatsPdfReport => 'PDF 报告';

  @override
  String get exportStatsQuickShareableTextSummary => '快速分享您的统计数据摘要';

  @override
  String get exportStatsStyledReportWithStats => '包含统计摘要和进度分析的精美报告';

  @override
  String get exportStatsTextSummary => '文本摘要';

  @override
  String get exportThisMayTakeA => '这可能需要几秒钟';

  @override
  String get exportUserDataNotFound => '未找到用户数据。请尝试退出登录后重新登录。';

  @override
  String get exportWorkoutButtonExportAsFit => '导出为 FIT';

  @override
  String get exportWorkoutButtonExportAsGpx => '导出为 GPX';

  @override
  String get exportWorkoutButtonExportAsTcx => '导出为 TCX';

  @override
  String get exportWorkoutButtonExportWorkout => '导出训练';

  @override
  String get exportWorkoutButtonGarminWahooNative => 'Garmin / Wahoo 原生格式';

  @override
  String get exportWorkoutButtonMyfitnesspalSportstracks =>
      'MyFitnessPal / Sportstracks';

  @override
  String get exportWorkoutButtonStravaGarminConnectKomo =>
      'Strava / Garmin Connect / Komoot';

  @override
  String get fastingAiInsightAiInsight => 'AI 洞察';

  @override
  String get fastingAiInsightCouldnTLoadYour => '无法加载您的洞察。请检查网络连接。';

  @override
  String get fastingAreYouSureYou => '确定要立即结束断食吗？';

  @override
  String get fastingAvgDuration => '平均时长';

  @override
  String get fastingBenefit_appetite => '食欲激素会随时间重置，让你更容易控制食量。';

  @override
  String get fastingBenefit_autophagy => '细胞自噬能清除受损蛋白质，与延缓衰老有关。';

  @override
  String get fastingBenefit_bs_control => '血糖保持更稳定，减少对食物的渴望和能量波动。';

  @override
  String get fastingBenefit_cellular_repair => '在长时间禁食期间，DNA修复通路会被激活。';

  @override
  String get fastingBenefit_energy => '全天能量稳定——告别餐后疲劳。';

  @override
  String get fastingBenefit_gut_rest => '消化系统得到休息，有助于肠道微生物群的健康。';

  @override
  String get fastingBenefit_insulin_sensitivity => '提高胰岛素敏感性可降低患2型糖尿病的风险。';

  @override
  String get fastingBenefit_longevity => '动物研究表明，禁食与更长的健康寿命和更低的疾病标志物有关。';

  @override
  String get fastingBenefit_mental_clarity => '相比血糖波动，酮体能为大脑提供更稳定的能量。';

  @override
  String get fastingBenefit_weight_loss => '通过针对储存的脂肪而非瘦组织，实现可持续的减重。';

  @override
  String get fastingBodyStatusBeyondGoal => '已超过目标';

  @override
  String get fastingBodyStatusBodyStatus => '身体状态';

  @override
  String get fastingBodyStatusKeyMoments => '关键时刻';

  @override
  String fastingBodyStatusLiveSubtitle(Object elapsed) {
    return '你的实时代谢之旅 — 已进行 $elapsed。';
  }

  @override
  String get fastingBodyStatusPreviewSubtitle => '断食代谢阶段预览。';

  @override
  String fastingBodyStatusScreenAtH(Object startHour) {
    return '$startHour 时';
  }

  @override
  String fastingBodyStatusScreenAtH2(Object hourOffset) {
    return '$hourOffset 时';
  }

  @override
  String fastingBodyStatusScreenH(Object hourOffset) {
    return '$hourOffset 小时 · ';
  }

  @override
  String get fastingBodyStatusStartFastHint => '开始断食以查看实时时间轴，了解每个阶段达到的确切时间。';

  @override
  String get fastingBodyStatusYouAreHere => '你在这里';

  @override
  String get fastingCalendarEnergy => '能量';

  @override
  String get fastingCalendarFasting => '断食';

  @override
  String get fastingCalendarGoals => '目标';

  @override
  String get fastingCalendarTapToMark => '点击标记';

  @override
  String get fastingCalendarWeight => '体重';

  @override
  String fastingCalendarWidgetCompleted(
    Object goalsCompleted,
    Object goalsTotal,
  ) {
    return '已完成 $goalsCompleted/$goalsTotal';
  }

  @override
  String fastingCalendarWidgetHFast(Object data) {
    return '$data小时断食';
  }

  @override
  String fastingCalendarWidgetKg(Object data) {
    return '$data kg';
  }

  @override
  String fastingCalendarWidgetValue(Object energyLevel) {
    return '$energyLevel/10';
  }

  @override
  String get fastingCompleteYourFirstFast => '完成您的首次断食以在此处查看';

  @override
  String get fastingContinueFasting => '继续断食';

  @override
  String get fastingEditDuration => '时长：';

  @override
  String get fastingEditEditFast => '编辑断食';

  @override
  String get fastingEditEnd => '结束';

  @override
  String get fastingEditFastUpdated => '断食已更新';

  @override
  String get fastingEditSaveChanges => '保存更改';

  @override
  String get fastingEditSchedule => '编辑计划';

  @override
  String fastingEditSheetHM(Object h, Object m) {
    return '$h小时 $m分钟';
  }

  @override
  String get fastingEndFast => '结束断食？';

  @override
  String get fastingEndFast2 => '结束断食';

  @override
  String get fastingFailedToEndFast => '无法结束断食。请重试。';

  @override
  String get fastingFasting => '断食';

  @override
  String get fastingFastingSettings => '断食设置';

  @override
  String get fastingFastingTracker => '断食追踪器';

  @override
  String get fastingGuideBeginnerTips => '新手建议';

  @override
  String get fastingGuideCommonProtocols => '常见方案';

  @override
  String get fastingGuideFaq => 'FAQ';

  @override
  String get fastingGuideFastingGuide => '断食指南';

  @override
  String get fastingGuideHowItWorks => '运作原理';

  @override
  String get fastingGuideIsItSafeFor => '我适合断食吗？';

  @override
  String get fastingGuideSafetyBody =>
      '如果你感到头晕、昏厥、颤抖或不适，请停止断食并进食。超过 24 小时的断食需要额外注意电解质补充，超过 72 小时的断食应仅在医疗监督下进行。断食不能替代医疗护理——本指南仅供教育参考，不构成医疗建议。';

  @override
  String get fastingGuideStaySafe => '安全须知';

  @override
  String get fastingGuideSubtitle => '自信断食所需的一切知识——它是什么、如何运作以及你的身体会发生什么。';

  @override
  String get fastingGuideSwipeTimeline => '滑动查看每小时的变化——从最后一餐到 30 天断食。';

  @override
  String get fastingGuideTheFastingTimeline => '断食时间轴';

  @override
  String get fastingGuideWhatIsFasting => '什么是断食？';

  @override
  String get fastingHistoryListCompleted => '已完成';

  @override
  String get fastingHistoryListLoadMore => '加载更多';

  @override
  String fastingHistoryListValue(Object completionPercent) {
    return '$completionPercent%';
  }

  @override
  String get fastingHydrationRow250Ml => '+250 毫升';

  @override
  String get fastingHydrationRow500Ml => '+500 毫升';

  @override
  String get fastingHydrationRowBottle => '瓶';

  @override
  String get fastingHydrationRowGlass => '杯';

  @override
  String get fastingHydrationRowHydration => '补水';

  @override
  String fastingHydrationRowMl(Object goalMl) {
    return ' / $goalMl 毫升';
  }

  @override
  String get fastingHydrationRowSyncedVisibleOnHome => '已同步 — 同时显示在首页和营养页面。';

  @override
  String get fastingHydrationRowWaterKeepsYouEnergized => '断食期间补水让您保持活力';

  @override
  String get fastingImpactActivityCalendar => '活动日历';

  @override
  String get fastingImpactAiInsights => 'AI 洞察';

  @override
  String fastingImpactCardCorrelation(Object displayName) {
    return '相关性: $displayName';
  }

  @override
  String get fastingImpactCompleteMoreFastsTo =>
      '完成更多断食以获取准确的影响分析。我们建议至少记录 7 天断食。';

  @override
  String get fastingImpactCompleteSomeFastsAnd => '完成一些断食并记录体重，查看断食如何影响您的目标。';

  @override
  String get fastingImpactFailedToLoadData => '数据加载失败';

  @override
  String get fastingImpactFastingDaysMarkedWith => '断食日以紫色圆点标记';

  @override
  String get fastingImpactFastingImpact => '断食影响';

  @override
  String get fastingImpactFastingVsNonFasting => '断食日与非断食日对比';

  @override
  String get fastingImpactGoalAchievement => '目标达成情况';

  @override
  String get fastingImpactLimitedDataAvailable => '可用数据有限';

  @override
  String get fastingImpactNoImpactDataYet => '暂无影响数据';

  @override
  String get fastingImpactOverallImpactScore => '综合影响评分';

  @override
  String fastingImpactScreenKg(Object comparison) {
    return '$comparison kg';
  }

  @override
  String fastingImpactScreenKg2(Object comparison) {
    return '$comparison kg';
  }

  @override
  String fastingImpactScreenValue(Object comparison) {
    return '$comparison%';
  }

  @override
  String fastingImpactScreenValue2(Object comparison) {
    return '$comparison%';
  }

  @override
  String fastingImpactScreenValue3(Object comparison) {
    return '$comparison%';
  }

  @override
  String fastingImpactScreenValue4(Object comparison) {
    return '$comparison%';
  }

  @override
  String get fastingImpactStartAFast => '开始断食';

  @override
  String get fastingImpactWeightImpact => '体重影响';

  @override
  String get fastingImpactWeightTrend => '体重趋势';

  @override
  String get fastingImpactWorkoutPerformance => '运动表现';

  @override
  String get fastingLongestFast => '最长断食';

  @override
  String get fastingMoodCheckinEndFast => '结束断食';

  @override
  String get fastingMoodCheckinEnergy => '能量';

  @override
  String get fastingMoodCheckinHowDoYouFeel => '感觉如何？';

  @override
  String get fastingMoodCheckinLogYourMoodAnd => '记录断食后的心情和能量（可选）。';

  @override
  String fastingMoodCheckinValue(Object value) {
    return '$value/5';
  }

  @override
  String get fastingNoFastingHistoryYet => '暂无断食记录';

  @override
  String get fastingPanelFasting => '断食';

  @override
  String get fastingPanelIntermittentFasting => '间歇性断食';

  @override
  String fastingPanelLeft(Object remainingTimeString) {
    return '剩余 $remainingTimeString';
  }

  @override
  String get fastingPlanCardsFlexible => '灵活';

  @override
  String get fastingPlanCardsPopular => '热门';

  @override
  String get fastingProtocol_16_8_desc => '跳过早餐，在中午至晚上 8 点之间进食';

  @override
  String get fastingProtocol_16_8_name => '16:8';

  @override
  String get fastingProtocol_18_6_desc => '更严格的 6 小时进食窗口';

  @override
  String get fastingProtocol_18_6_name => '18:6';

  @override
  String get fastingProtocol_20_4_desc => '勇士饮食法 — 一顿主餐';

  @override
  String get fastingProtocol_20_4_name => '20:4';

  @override
  String get fastingProtocol_36h_desc => '僧侣断食 — 延长的细胞自噬窗口';

  @override
  String get fastingProtocol_36h_name => '36 小时';

  @override
  String get fastingProtocol_48h_desc => '延长断食 — 建议在医疗监督下进行';

  @override
  String get fastingProtocol_48h_name => '48 小时';

  @override
  String get fastingProtocol_5_2_desc => '5 天正常饮食，2 天摄入 500-600 大卡';

  @override
  String get fastingProtocol_5_2_name => '5:2';

  @override
  String get fastingProtocol_72h_desc => '干细胞更新断食 — 必须在医疗监督下进行';

  @override
  String get fastingProtocol_72h_name => '72 小时';

  @override
  String get fastingProtocol_adf_desc => '隔日断食 — 正常饮食日后接极低热量日';

  @override
  String get fastingProtocol_adf_name => 'ADF';

  @override
  String get fastingProtocol_custom_desc => '设置你自己的进食和断食窗口';

  @override
  String get fastingProtocol_custom_name => '自定义';

  @override
  String get fastingProtocol_omad_desc => '每日一餐 — 在一次进食中摄入所有营养';

  @override
  String get fastingProtocol_omad_name => 'OMAD';

  @override
  String get fastingSavedRowFasting => '断食';

  @override
  String get fastingSavedRowSaved => '已保存';

  @override
  String get fastingScheduleEditorPickAProtocolFor => '为每一天选择方案';

  @override
  String get fastingScheduleEditorRestEatingDay => '休息/进食日';

  @override
  String get fastingScheduleEditorSaveSchedule => '保存计划';

  @override
  String fastingScheduleEditorSheetFailedToSaveSchedule(Object e) {
    return '保存计划失败：$e';
  }

  @override
  String fastingScheduleEditorSheetValue(
    Object difficulty,
    Object displayName,
  ) {
    return '$displayName  ·  $difficulty';
  }

  @override
  String get fastingScheduleEditorWeeklyFastingScheduleSaved => '每周断食计划已保存';

  @override
  String get fastingScheduleEditorWeeklySchedule => '每周计划';

  @override
  String get fastingScoreCardBreakdown => '细分';

  @override
  String get fastingScoreCardCompletionRate => '完成率';

  @override
  String get fastingScoreCardFastingScore => '断食评分';

  @override
  String get fastingScoreCardProtocolLevel => '方案等级';

  @override
  String get fastingScoreCardScore => '评分';

  @override
  String get fastingScoreCardStreakBonus => '连胜奖励';

  @override
  String fastingScoreCardValue(Object scoreChange) {
    return '$scoreChange';
  }

  @override
  String fastingScoreCardValue2(Object value) {
    return '$value%';
  }

  @override
  String fastingScoreCardValue3(Object weightedValue) {
    return '+$weightedValue';
  }

  @override
  String get fastingScoreCardVsLastWeek => '与上周相比';

  @override
  String get fastingScoreCardWeeklyGoal => '每周目标';

  @override
  String fastingScreenFailedToStartFast(Object e) {
    return '开启断食失败：$e';
  }

  @override
  String get fastingScreenRedesignedAvgDuration => '平均时长';

  @override
  String get fastingScreenRedesignedBackToToday => '回到今天';

  @override
  String get fastingScreenRedesignedCompleteAFastTo => '完成一次断食以在此查看';

  @override
  String get fastingScreenRedesignedDayStreak => '连续天数';

  @override
  String get fastingScreenRedesignedEndFast => '结束断食';

  @override
  String fastingScreenRedesignedFailedToEndFast(Object e) {
    return '无法结束断食：$e';
  }

  @override
  String fastingScreenRedesignedFailedToStartFast(Object e) {
    return '无法开始断食：$e';
  }

  @override
  String get fastingScreenRedesignedFastPaused => '断食已暂停';

  @override
  String get fastingScreenRedesignedFastResumedYourTimer => '断食已恢复 — 计时器已重新启动。';

  @override
  String get fastingScreenRedesignedFasting => '断食';

  @override
  String get fastingScreenRedesignedFastingTracker => '断食追踪器';

  @override
  String get fastingScreenRedesignedInProgress => '进行中';

  @override
  String get fastingScreenRedesignedLongestFast => '最长断食';

  @override
  String get fastingScreenRedesignedNoFastYet => '暂无断食';

  @override
  String get fastingScreenRedesignedNoFastingHistoryYet => '暂无断食记录';

  @override
  String get fastingScreenRedesignedPauseFast => '暂停断食';

  @override
  String get fastingScreenRedesignedPaused => '已暂停';

  @override
  String fastingScreenRedesignedPlan(Object displayName) {
    return '$displayName 计划';
  }

  @override
  String get fastingScreenRedesignedRestDay => '休息日';

  @override
  String get fastingScreenRedesignedResumeFast => '恢复断食';

  @override
  String get fastingScreenRedesignedSignUpToUnlock => '注册以解锁';

  @override
  String get fastingScreenRedesignedStartFast => '开始断食';

  @override
  String fastingScreenRedesignedStartedOngoing(Object timeFormat) {
    return '开始于 $timeFormat · 进行中';
  }

  @override
  String get fastingScreenRedesignedTodaySPlan => '今日计划：';

  @override
  String get fastingScreenRedesignedTotalFasts => '总断食次数';

  @override
  String get fastingScreenRedesignedViewTrends => '查看趋势';

  @override
  String get fastingScreenRedesignedYouDidNotLog => '您当天没有记录断食。';

  @override
  String fastingScreenYouVeBeenFasting(Object elapsedTimeFormatted) {
    return '你已断食 $elapsedTimeFormatted';
  }

  @override
  String get fastingSettingsCustom => '自定义';

  @override
  String get fastingSettingsCustomWeeklySchedule => '自定义每周计划';

  @override
  String get fastingSettingsEatingWindowEnd => '进食窗口结束时间';

  @override
  String get fastingSettingsFastStartReminder => '断食开始提醒';

  @override
  String get fastingSettingsFastingHours => '断食时长：';

  @override
  String get fastingSettingsFastingSettings => '断食设置';

  @override
  String get fastingSettingsFastingSettingsSaved => '断食设置已保存';

  @override
  String get fastingSettingsGoalReached => '已达成目标';

  @override
  String get fastingSettingsNotifyWhenEnteringNew => '进入新断食阶段时通知我';

  @override
  String get fastingSettingsNotifyWhenYouReach => '达到断食目标时通知我';

  @override
  String get fastingSettingsRemindBeforeEatingWindow => '进食窗口关闭前提醒我';

  @override
  String get fastingSettingsRemindWhenItS => '到开始断食时间时提醒我';

  @override
  String get fastingSettingsSaveSettings => '保存设置';

  @override
  String fastingSettingsSheetFailedToSave(Object e) {
    return '保存失败：$e';
  }

  @override
  String fastingSettingsSheetH(Object _customHours) {
    return '$_customHours小时';
  }

  @override
  String fastingSettingsSheetHFasting(Object _customHours) {
    return '$_customHours小时断食';
  }

  @override
  String get fastingSettingsStartEatingAt => '开始进食时间';

  @override
  String get fastingSettingsStartFastingAt => '开始断食时间';

  @override
  String get fastingSettingsZoneTransitions => '阶段转换';

  @override
  String get fastingSignUpToUnlock => '注册以解锁';

  @override
  String get fastingStageCardCurrentStage => '当前阶段';

  @override
  String get fastingStageCardFinalMetabolicStageReached => '已达到最终代谢阶段';

  @override
  String fastingStageCardNext(Object name) {
    return '下一步：$name';
  }

  @override
  String get fastingStageModel24Hours => '24小时';

  @override
  String get fastingStageTimerElapsed => '已进行';

  @override
  String get fastingStageTimerReadyToFast => '准备好断食了';

  @override
  String get fastingStage_autophagy_desc => '细胞开始分解并回收受损的蛋白质和细胞器——这是一次深度的细胞清理。';

  @override
  String get fastingStage_autophagy_name => '细胞自噬';

  @override
  String get fastingStage_fat_burning_desc => '当糖原水平降低时，脂肪细胞会释放脂肪酸进入血液作为燃料。';

  @override
  String get fastingStage_fat_burning_name => '脂肪燃烧';

  @override
  String get fastingStage_glycogen_depletion_desc =>
      '身体优先使用储存的葡萄糖。12-14 小时后，肝糖原储备降低，代谢开始转变。';

  @override
  String get fastingStage_glycogen_depletion_name => '糖原耗尽';

  @override
  String get fastingStage_growth_hormone_desc => 'HGH水平急剧上升，保护瘦体重并加速脂肪代谢。';

  @override
  String get fastingStage_growth_hormone_name => '生长激素激增';

  @override
  String get fastingStage_inflammation_drop_desc => '随着肠道休息和免疫细胞再生，炎症标志物会减少。';

  @override
  String get fastingStage_inflammation_drop_name => '炎症水平下降';

  @override
  String get fastingStage_insulin_low_desc => '胰岛素保持在基准线附近，从而释放脂肪储备并提高胰岛素敏感性。';

  @override
  String get fastingStage_insulin_low_name => '低胰岛素';

  @override
  String get fastingStage_ketosis_desc => '肝脏将脂肪酸转化为酮体——这是大脑的一种清洁、高效的燃料。';

  @override
  String get fastingStage_ketosis_name => '生酮状态';

  @override
  String get fastingStartFast => '开始断食';

  @override
  String get fastingStartYourFirstFast => '开始您的第一次断食以建立统计数据';

  @override
  String get fastingStatsCardAvg => '平均';

  @override
  String get fastingStatsCardCurrentStreak => '当前连胜';

  @override
  String get fastingStatsCardFastingDays => '断食天数';

  @override
  String get fastingStatsCardFastingHelps => '断食有助';

  @override
  String get fastingStatsCardFastingScore => '断食评分';

  @override
  String fastingStatsCardFastsProgress(Object fasts, Object goal) {
    return '$fasts / $goal 次断食';
  }

  @override
  String get fastingStatsCardHours => '小时';

  @override
  String fastingStatsCardKg(Object value) {
    return '$value kg';
  }

  @override
  String get fastingStatsCardLongest => '最长';

  @override
  String get fastingStatsCardMixedResults => '结果不一';

  @override
  String get fastingStatsCardNeedMoreData => '需要更多数据';

  @override
  String get fastingStatsCardNeutral => '中性';

  @override
  String get fastingStatsCardNonFasting => '非断食';

  @override
  String fastingStatsCardStreakDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '$_temp0';
  }

  @override
  String get fastingStatsCardThisWeek => '本周';

  @override
  String get fastingStatsCardTotal => '总计';

  @override
  String get fastingStatsCardWeightFasting => '体重与断食';

  @override
  String get fastingStreak => '连胜';

  @override
  String fastingTabFailedToEndFast(Object e) {
    return '结束断食失败：$e';
  }

  @override
  String fastingTabFailedToStartFast(Object e) {
    return '开始断食失败：$e';
  }

  @override
  String get fastingTileFast => '开始断食';

  @override
  String get fastingTileFasting => '断食中';

  @override
  String get fastingTileNotFasting => '未断食';

  @override
  String get fastingTimelinePagerAdvancedTerritory => '进阶领域';

  @override
  String fastingTimelinePagerExtendedFast(Object label) {
    return '延长断食 · $label';
  }

  @override
  String fastingTimelinePagerH(Object hourOffset, Object text) {
    return '$hourOffset小时 — $text';
  }

  @override
  String get fastingTimer => '计时器';

  @override
  String get fastingTimerEndFast => '结束断食';

  @override
  String get fastingTip_bcaa_avoid => 'BCAAs以及大多数含有卡路里或氨基酸的补剂会打破禁食。';

  @override
  String get fastingTip_break_with_protein => '禁食结束后，先吃一顿富含蛋白质的餐食，以保护肌肉并增加饱腹感。';

  @override
  String get fastingTip_coffee_ok => '黑咖啡不会打破禁食状态，实际上还能抑制饥饿感。';

  @override
  String get fastingTip_exercise_fasted_ok_intermediate =>
      '一旦适应，空腹进行轻度到中度的有氧运动是可以的。请倾听身体的反馈。';

  @override
  String get fastingTip_exercise_high_intensity_eat_first =>
      '对于大重量训练或高强度间歇运动，提前进食能保护运动表现。';

  @override
  String get fastingTip_ramp_up_gradually => '从12小时开始，每周增加30分钟——不要第一天就尝试OMAD。';

  @override
  String get fastingTip_refeed_carbs_carefully =>
      '在禁食36小时以上后，请逐渐摄入碳水化合物，以避免复食不适。';

  @override
  String get fastingTip_sleep_helps_extended => '将禁食时间安排在睡眠期间，会让长时间禁食变得容易得多。';

  @override
  String get fastingTip_stay_hydrated => '禁食期间可以喝水、黑咖啡和纯茶。';

  @override
  String get fastingTip_track_hunger_separate_from_appetite =>
      '饥饿感和食欲是两回事。饥饿感会阵阵消退；食欲则是一种习惯。';

  @override
  String get fastingTotalFasts => '断食总次数';

  @override
  String get fastingTrackYourIntermittentFastin =>
      '通过智能区域通知、进度洞察和详细历史记录来追踪您的间歇性断食。';

  @override
  String fastingTrainingWarningH(Object hoursFasted) {
    return '$hoursFasted 小时';
  }

  @override
  String fastingTrainingWarningHFasted(Object hoursFasted) {
    return '已断食 $hoursFasted 小时';
  }

  @override
  String get fastingTrainingWarningSuggestions => '建议：';

  @override
  String get fastingTypesInAppProtocols => '应用内方案';

  @override
  String get fastingTypesTypesOfFasting => '断食类型';

  @override
  String get fastingZoneTimelineFastingZones => '断食区间';

  @override
  String fastingZoneTimelineH(Object startHour) {
    return '$startHour点';
  }

  @override
  String get fatigueAlertAcceptSuggestion => '接受建议';

  @override
  String get fatigueAlertContinueAsPlanned => '按计划继续';

  @override
  String get fatigueAlertModalAcceptSuggestion => '接受建议';

  @override
  String fatigueAlertModalAlert(Object severityLabel) {
    return '$severityLabel 提醒';
  }

  @override
  String get fatigueAlertModalBodyweightExerciseDropThe =>
      '自重训练 — 降低目标次数，而不是重量。';

  @override
  String get fatigueAlertModalContinueAsPlanned => '按计划继续';

  @override
  String get fatigueAlertModalDetectedIssues => '检测到的问题';

  @override
  String get fatigueAlertModalFatigueDetected => '检测到疲劳';

  @override
  String fatigueAlertModalHeavier(Object truePercent) {
    return '增加 $truePercent%';
  }

  @override
  String fatigueAlertModalLighter(Object truePercent) {
    return '减轻 $truePercent%';
  }

  @override
  String fatigueAlertModalReps(Object newReps) {
    return '$newReps 次';
  }

  @override
  String get fatigueAlertModalStopExercise => '停止训练';

  @override
  String get fatigueAlertModalSuggestedAdjustment => '建议调整';

  @override
  String get fatigueAlertModalSuggestedRepTarget => '建议目标次数';

  @override
  String get fatigueAlertStopExercise => '停止训练';

  @override
  String get favoriteExercisesFavoriteExercises => '收藏的动作';

  @override
  String get favoriteExercisesRemove => '移除';

  @override
  String get favoriteExercisesRemoveFavorite => '移除收藏？';

  @override
  String favoriteExercisesScreenAddedToFavorites(Object exerciseName) {
    return '已将“$exerciseName”添加到收藏';
  }

  @override
  String favoriteExercisesScreenAddedToFavorites2(Object name) {
    return '已将“$name”添加到收藏';
  }

  @override
  String favoriteExercisesScreenIsAlreadyAFavorite(Object name) {
    return '“$name”已在收藏中';
  }

  @override
  String favoriteExercisesScreenRemoveFromYourFavorites(Object exerciseName) {
    return '将“$exerciseName”从收藏中移除？AI 将不再优先推荐此动作。';
  }

  @override
  String get favoriteExercisesTheAiWillPrioritize => 'AI 在生成训练计划时将优先考虑这些动作。';

  @override
  String get favoriteWorkoutsFavoriteWorkouts => '收藏的训练';

  @override
  String get favoriteWorkoutsNoFavoriteWorkoutsYet => '暂无收藏的训练';

  @override
  String favoriteWorkoutsSavedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个已保存训练',
    );
    return '$_temp0';
  }

  @override
  String get favoriteWorkoutsTapTheHeartOn => '点击任意训练上的心形图标即可将其保存至此';

  @override
  String get favoriteWorkoutsWorkoutFallback => '训练';

  @override
  String get favoritesCardFavoriteMuscleGroup => '最常训练肌群';

  @override
  String get favoritesCardYourGoTo => '您的首选';

  @override
  String get favoritesCardYourMostPerformedExercise => '您执行次数最多的动作';

  @override
  String get favoritesCheckYourConnectionAnd => '请检查您的网络连接并重试。';

  @override
  String get favoritesFavorites => '收藏';

  @override
  String get favoritesNoFavoritesYet => '暂无收藏';

  @override
  String get favoritesTapU2665OnAny => '点击“发现”或您的资料库中任意食谱上的 ♥ 即可将其保存至此。';

  @override
  String get favoritesTryAgain => '重试';

  @override
  String get featureVotingInProgress => '进行中';

  @override
  String get featureVotingNoFeaturesYet => '暂无功能';

  @override
  String get featureVotingPlanned => '已规划';

  @override
  String get featureVotingReleased => '已发布';

  @override
  String get featureVotingVoting => '投票中';

  @override
  String get feedCompleteWorkoutsToSee => '完成训练即可在此分享！\n关注好友以查看他们的训练动态。';

  @override
  String get feedCouldNotLoadYour => '无法加载您的动态信息流。\n请稍后再试。';

  @override
  String get feedCreateYourFirstPost => '发布您的第一条动态！';

  @override
  String get feedFailedToLoadFeed => '加载信息流失败';

  @override
  String get feedNoActivityYet => '暂无动态';

  @override
  String get feedNoPostsYet => '暂无帖子';

  @override
  String get feedNotLoggedIn => '未登录';

  @override
  String get feedPleaseLogInTo => '请登录以查看您的动态信息流';

  @override
  String feedTabErrorLoadingFeed(Object error) {
    return '加载动态失败：$error';
  }

  @override
  String get feelResultsCompleteWorkoutsWithMood => '完成带有心情打卡的训练，看看运动如何改善您的感受。';

  @override
  String get feelResultsFeelResults => '感受成果';

  @override
  String get feelResultsFeelingStronger => '感觉更强壮';

  @override
  String get feelResultsMoodBeforeVsAfter => '运动前后心情对比';

  @override
  String feelResultsScreenValue(Object moodImprovementPercent) {
    return '+$moodImprovementPercent%';
  }

  @override
  String feelResultsScreenValue2(Object moodChange) {
    return '+$moodChange';
  }

  @override
  String feelResultsScreenValue3(Object percent) {
    return '$percent%';
  }

  @override
  String feelResultsScreenW(Object week) {
    return '第$week周';
  }

  @override
  String feelResultsScreenYouFeltStrongerAfter(
    Object feelingStrongerCount,
    Object totalWorkouts,
  ) {
    return '在 $totalWorkouts 次锻炼中，您有 $feelingStrongerCount 次感觉更强了！';
  }

  @override
  String get feelResultsStartTrackingYourProgress => '开始追踪您的进度！';

  @override
  String get feelResultsU1f4aa => '💪';

  @override
  String get feelResultsWeeklyTrends => '每周趋势';

  @override
  String get feelResultsYourTrainingIsWorking => '您的训练卓有成效！';

  @override
  String get feltPicker => '😮‍💨';

  @override
  String get feltPickerGood => '良好';

  @override
  String get feltPickerHard => '困难';

  @override
  String get feltPickerVHard => '非常困难';

  @override
  String get filterNoMatchingOptions => '没有匹配选项';

  @override
  String filterSectionSearch(Object title) {
    return '搜索 $title...';
  }

  @override
  String filterSectionShowMore(Object initialShowCount) {
    return '显示更多 $initialShowCount 个';
  }

  @override
  String get firstActionPromptPickOneTakesUnder => '选一个吧 — 不到一分钟即可完成。';

  @override
  String get firstActionPromptPullInYourActivity => '导入您的活动、睡眠和体重历史记录。';

  @override
  String get firstActionPromptQuickStart => '快速开始';

  @override
  String get firstActionPromptTheyHaveAMessage => '他们有一条消息在等您。';

  @override
  String get firstWorkoutForecastCaloriesBurned => '消耗卡路里';

  @override
  String get firstWorkoutForecastDay1Complete => '第 1 天完成';

  @override
  String get firstWorkoutForecastIn30DaysAt => '以此进度在 30 天后';

  @override
  String get firstWorkoutForecastLetSGo => '开始吧';

  @override
  String get firstWorkoutForecastProjectedStrengthGainOn => '主要动作的预计力量增长';

  @override
  String firstWorkoutForecastSheetEstimateBasedOnSessions(
    Object effectiveSessions,
  ) {
    return '基于每周 $effectiveSessions 次训练的估算';
  }

  @override
  String firstWorkoutForecastSheetThatS(Object volumeComparison) {
    return '相当于 $volumeComparison';
  }

  @override
  String firstWorkoutForecastSheetThatS2(Object caloriesComparison) {
    return '相当于 $caloriesComparison';
  }

  @override
  String firstWorkoutForecastSheetYourFirstWorkout(Object appName) {
    return '你的首次 $appName 训练';
  }

  @override
  String get firstWorkoutForecastShowMeDay7 => '查看第 7 天';

  @override
  String get firstWorkoutForecastTotalTimeTrained => '总训练时长';

  @override
  String get firstWorkoutForecastTotalVolumeLifted => '总训练容量';

  @override
  String get fitnessAssessmentBodyweightSquats => '自重深蹲';

  @override
  String get fitnessAssessmentCardioCapacity => '心肺能力';

  @override
  String get fitnessAssessmentHelpUsPersonalizeYour => '帮助我们个性化您的训练（约 2 分钟）';

  @override
  String get fitnessAssessmentHowLongCanYou => '您可以坚持平板支撑多久？';

  @override
  String get fitnessAssessmentHowLongCanYou2 => '您可以持续进行有氧运动多久？';

  @override
  String get fitnessAssessmentHowLongHaveYou => '您进行力量训练多久了？';

  @override
  String get fitnessAssessmentHowManyCanYou => '您可以连续做多少个？';

  @override
  String get fitnessAssessmentHowManyConsecutivePush =>
      '动作标准的情况下，您可以连续做多少个俯卧撑？';

  @override
  String get fitnessAssessmentHowManyPullUps => '您可以做多少个引体向上？';

  @override
  String get fitnessAssessmentNoWrongAnswersJust => '没有错误答案，请如实回答！';

  @override
  String get fitnessAssessmentPlankHold => '平板支撑';

  @override
  String get fitnessAssessmentPullUps => '引体向上';

  @override
  String get fitnessAssessmentPushUps => '俯卧撑';

  @override
  String get fitnessAssessmentQuickFitnessCheck => '快速体能评估';

  @override
  String get fitnessAssessmentTrainingExperience => '训练经验';

  @override
  String get fitnessAssessmentWhatGetsPersonalized => '个性化内容';

  @override
  String get fitnessAssessmentWhyThisMatters => '为什么这很重要';

  @override
  String get fitnessAssessmentYourAnswersHelpThe =>
      '您的回答有助于 AI 将训练调整至最适合您的体能水平，无需猜测。';

  @override
  String get fitnessCrateCollect => '领取';

  @override
  String fitnessCrateDialogCrate(Object displayName) {
    return '$displayName 补给箱';
  }

  @override
  String get fitnessCrateOpenCrate => '打开宝箱';

  @override
  String get fitnessCrateRewards => '奖励！';

  @override
  String get fitnessScoreCardConsistency => '规律性';

  @override
  String get fitnessScoreCardFitnessScore => '体能评分';

  @override
  String get fitnessScoreCardLoadingScores => '正在加载评分...';

  @override
  String get fitnessScoreCardOverall => '综合';

  @override
  String get fitnessScoreCardReadiness => '准备状态';

  @override
  String get fitnessScoreCardStrength => '力量';

  @override
  String fitnessScoreCardValue(Object consistencyScore) {
    return '$consistencyScore%';
  }

  @override
  String fitnessScoreCardValue2(Object label) {
    return '$label：';
  }

  @override
  String get flexibilityAssessmentAllTests => '所有测试';

  @override
  String get flexibilityAssessmentCompleteSomeFlexibilityAsse =>
      '完成一些柔韧性评估，以获取个性化的拉伸建议';

  @override
  String get flexibilityAssessmentCompleteTheseTestsTo => '完成这些测试以获取完整的柔韧性档案';

  @override
  String get flexibilityAssessmentFailedToLoadData => '数据加载失败';

  @override
  String get flexibilityAssessmentFlexibilityAssessment => '柔韧性评估';

  @override
  String get flexibilityAssessmentFocusOnTheseAreas => '专注于这些区域以改善您的整体柔韧性';

  @override
  String get flexibilityAssessmentMyPlans => '我的计划';

  @override
  String get flexibilityAssessmentNoFlexibilityTestsAvailable => '暂无柔韧性测试';

  @override
  String get flexibilityAssessmentNoStretchPlansYet => '暂无拉伸计划';

  @override
  String get flexibilityAssessmentNotYetAssessed => '尚未评估';

  @override
  String get flexibilityAssessmentOverview => '概览';

  @override
  String get flexibilityAssessmentPriorityImprovements => '优先改善项';

  @override
  String get flexibilityAssessmentRecentAssessments => '近期评估';

  @override
  String get flexibilityAssessmentRecommendedStretches => '推荐拉伸动作';

  @override
  String flexibilityAssessmentScreenCurrentRating(Object rating) {
    return '当前评分：$rating';
  }

  @override
  String flexibilityAssessmentScreenViewAllTests(Object length) {
    return '查看全部 $length 项测试';
  }

  @override
  String get flexibilityAssessmentTakeAnAssessment => '进行评估';

  @override
  String get flexibilityHistoryAll => '全部';

  @override
  String get flexibilityHistoryAssessmentHistory => '评估历史';

  @override
  String get flexibilityHistoryCompleteSomeFlexibilityTest =>
      '完成一些柔韧性测试以在此查看您的历史记录';

  @override
  String get flexibilityHistoryDeleteAssessment => '删除评估';

  @override
  String get flexibilityHistoryDeleteAssessment2 => '确定删除评估吗？';

  @override
  String get flexibilityHistoryNoAssessmentsYet => '暂无评估记录';

  @override
  String get flexibilityHistoryNotes => '备注';

  @override
  String get flexibilityHistoryThisActionCannotBe => '此操作无法撤销。';

  @override
  String flexibilityProgressChartAssessments(Object totalAssessments) {
    return '$totalAssessments 次评估';
  }

  @override
  String get flexibilityProgressChartChange => '变化';

  @override
  String get flexibilityProgressChartFirst => '首次';

  @override
  String get flexibilityProgressChartLatest => '最新';

  @override
  String get flexibilityProgressChartNoDataAvailable => '暂无数据';

  @override
  String flexibilityProgressChartValue(Object improvementAbsolute) {
    return '$improvementAbsolute';
  }

  @override
  String get flexibilityScoreCardByArea => '按区域';

  @override
  String get flexibilityScoreCardFocusAreas => '重点区域';

  @override
  String get flexibilityScoreCardOverallFlexibility => '整体柔韧性';

  @override
  String flexibilityScoreCardTestsCompleted(Object testsCompleted) {
    return '已完成 $testsCompleted 项测试';
  }

  @override
  String flexibilityScoreCardTotalAssessments(Object totalAssessments) {
    return '共 $totalAssessments 项评估';
  }

  @override
  String get flexibilityTestCardNotYetAssessed => '尚未评估';

  @override
  String get flexibilityTestCardRecordAssessment => '记录评估';

  @override
  String get flexibilityTestCardUpdateAssessment => '更新评估';

  @override
  String get flexibilityTestDetailAboutThisTest => '关于此测试';

  @override
  String get flexibilityTestDetailCommonMistakesToAvoid => '常见错误';

  @override
  String get flexibilityTestDetailEquipmentNeeded => '所需器材';

  @override
  String get flexibilityTestDetailFlexibilityTrends => '柔韧性趋势';

  @override
  String get flexibilityTestDetailInstructions => '说明';

  @override
  String get flexibilityTestDetailNotYetAssessed => '尚未评估';

  @override
  String get flexibilityTestDetailRecentAssessments => '近期评估';

  @override
  String get flexibilityTestDetailStartAssessment => '开始评估';

  @override
  String get flexibilityTestDetailTakeTest => '进行测试';

  @override
  String get flexibilityTestDetailTakeThisTestTo => '进行此测试以获取您的柔韧性等级和个性化建议';

  @override
  String get flexibilityTestDetailTargetMuscles => '目标肌肉';

  @override
  String get flexibilityTestDetailTips => '提示';

  @override
  String get flexibilityTestDetailU2022 => '• ';

  @override
  String get flexibilityTestDetailUpdate => '更新';

  @override
  String get floatingChatBubbleAskMeAnythingAbout => '关于健身，尽管问我';

  @override
  String get floatingChatBubbleAskYourAiCoach => '询问您的 AI 教练...';

  @override
  String get floatingChatBubbleChangeCoach => '更换教练';

  @override
  String get floatingChatBubbleErrorLoadingMessages => '加载消息时出错';

  @override
  String get floatingChatBubbleHowCanIHelp => '今天有什么我可以帮您的吗？';

  @override
  String get floatingChatBubbleOnline => '在线';

  @override
  String get floatingChatBubbleTyping => '正在输入...';

  @override
  String get floatingChatOverlayAskMeAnythingAbout => '关于健身，尽管问我';

  @override
  String get floatingChatOverlayAskYourAiCoach => '询问您的AI教练...';

  @override
  String get floatingChatOverlayErrorLoadingMessages => '加载消息时出错';

  @override
  String floatingChatOverlayGoTo(Object workoutName) {
    return '前往 $workoutName';
  }

  @override
  String get floatingChatOverlayHowCanIHelp => '今天有什么我可以帮您的吗？';

  @override
  String get floatingChatOverlayMediaAttachmentsAvailableIn => '媒体附件可在完整聊天中查看';

  @override
  String get floatingChatOverlayOnline => '在线';

  @override
  String get floatingChatOverlayTypeYourNextMessage => '输入您的下一条消息...';

  @override
  String get floatingChatOverlayTyping => '正在输入...';

  @override
  String focalStepperInternalsEditValueCurrently(Object _display, Object unit) {
    return '编辑$unit值，当前为$_display';
  }

  @override
  String get focalStepperValue => '数值';

  @override
  String get focusAreasSelectorEnterCustomFocusArea => '输入自定义重点区域（例如“肩袖肌群”）';

  @override
  String focusAreasSelectorSelected(Object selectedCount) {
    return '已选$selectedCount项';
  }

  @override
  String get focusAreasSelectorTargetAreas => '目标区域';

  @override
  String get focusAreasSelectorWhichBodyRegionsTo =>
      '选择要锻炼的身体部位。可与上方的训练风格结合使用。';

  @override
  String get foldableWarmupLayoutPause => '暂停';

  @override
  String foldableWarmupLayoutS(Object duration) {
    return '$duration 秒';
  }

  @override
  String foldableWarmupLayoutSec(Object duration) {
    return '$duration 秒';
  }

  @override
  String get foldableWarmupLayoutSkipWarmup => '跳过热身';

  @override
  String get foldableWarmupLayoutStartWorkout => '开始训练';

  @override
  String get foldableWarmupLayoutUpNext => '接下来';

  @override
  String get foldableWarmupLayoutWarmUp => '热身';

  @override
  String get foldableWorkoutLeftUpNext => '接下来';

  @override
  String get fontScaleCard085x => '0.85x';

  @override
  String get fontScaleCardFontScale => '字体缩放';

  @override
  String get fontScaleCardPreciseFontScalingControl => '精确的字体缩放控制';

  @override
  String fontScaleCardX(Object scale) {
    return '$scale倍';
  }

  @override
  String foodAnalysisInlineCardCal(Object _selectedCalTotal) {
    return '$_selectedCalTotal 卡路里';
  }

  @override
  String foodAnalysisInlineCardCal2(Object cal) {
    return '$cal 卡路里';
  }

  @override
  String foodAnalysisInlineCardGC(Object carbs) {
    return '${carbs}g 碳水';
  }

  @override
  String foodAnalysisInlineCardGF(Object fat) {
    return '${fat}g 脂肪';
  }

  @override
  String foodAnalysisInlineCardGP(Object protein) {
    return '${protein}g 蛋白质';
  }

  @override
  String get foodAnalysisInlineFoodAnalysis => '食物分析';

  @override
  String get foodAnalysisInlineLogged => '已记录';

  @override
  String get foodAnalysisInlineU00b7 => '·';

  @override
  String foodAnalysisLoadingElapsed(
    Object _elapsedSeconds,
    Object _stillWorkingIndex,
  ) {
    return '已过去-$_elapsedSeconds-$_stillWorkingIndex';
  }

  @override
  String foodAnalysisLoadingS(
    Object _elapsedSeconds,
    Object analysisLoadingCopy,
  ) {
    return '$analysisLoadingCopy… $_elapsedSeconds秒';
  }

  @override
  String foodAnalysisLoadingSElapsed(Object _elapsedSeconds) {
    return '已过去 $_elapsedSeconds秒';
  }

  @override
  String foodAnalysisLoadingValue(Object displayMessage) {
    return '$displayMessage…';
  }

  @override
  String get foodAnalysisResultAiNutritionAnalysisIs =>
      'AI营养分析仅供参考。如需个性化饮食建议，请咨询营养师。';

  @override
  String foodAnalysisResultCardCal(Object adjustedCal) {
    return '$adjustedCal 大卡';
  }

  @override
  String foodAnalysisResultCardCalTotal(Object totalCalories) {
    return '总计 $totalCalories 大卡';
  }

  @override
  String foodAnalysisResultCardGP(Object adjustedProtein) {
    return '$adjustedProtein 克蛋白质';
  }

  @override
  String foodAnalysisResultCardGProtein(Object totalProtein) {
    return '$totalProtein 克蛋白质';
  }

  @override
  String foodAnalysisResultCardLeavesYouCalFor(
    Object mealLabel,
    Object remaining,
  ) {
    return '剩余 $remaining 大卡用于 $mealLabel';
  }

  @override
  String foodAnalysisResultCardSelected(Object length) {
    return '已选 $length 个';
  }

  @override
  String foodAnalysisResultCardShowMore(Object dishes) {
    return '显示更多 $dishes 个...';
  }

  @override
  String foodAnalysisResultCardValue(Object label, Object length) {
    return '$label ($length)';
  }

  @override
  String get foodAnalysisResultDeselectAll => '取消全选';

  @override
  String get foodAnalysisResultGreatChoices => '优质选择';

  @override
  String get foodAnalysisResultInModeration => '适量食用';

  @override
  String get foodAnalysisResultItemsLoggedToNutrition => '已记录到营养追踪器';

  @override
  String get foodAnalysisResultLimitThese => '限制摄入';

  @override
  String get foodAnalysisResultSelectItemsToLog => '选择要记录的项目';

  @override
  String get foodAnalysisResultShowLess => '收起';

  @override
  String get foodAnalysisResultTips => '小贴士';

  @override
  String get foodAnalysisResultU00b7 => ' · ';

  @override
  String get foodBrowserPanelAddModifier => '添加修饰符...';

  @override
  String get foodBrowserPanelAllCountries => '所有国家';

  @override
  String get foodBrowserPanelCalorieDense => '高热量';

  @override
  String get foodBrowserPanelCoachTip => '教练小贴士';

  @override
  String get foodBrowserPanelCooking => '烹饪';

  @override
  String get foodBrowserPanelCouldNotParseAny => '无法解析任何食物项目';

  @override
  String get foodBrowserPanelDefault => '默认';

  @override
  String get foodBrowserPanelDoneness => '熟度';

  @override
  String foodBrowserPanelFailedToLog(Object error) {
    return '记录失败：$error';
  }

  @override
  String get foodBrowserPanelFilterByCountry => '按国家筛选';

  @override
  String get foodBrowserPanelFilterBySource => '按来源筛选';

  @override
  String get foodBrowserPanelHighFat => '高脂肪';

  @override
  String get foodBrowserPanelHighFiber => '高纤维';

  @override
  String get foodBrowserPanelHighProtein => '高蛋白';

  @override
  String foodBrowserPanelItems(Object totalItems) {
    return '$totalItems 项';
  }

  @override
  String get foodBrowserPanelKcal => ' 千卡';

  @override
  String foodBrowserPanelKcal2(Object totalCal) {
    return '$totalCal kcal';
  }

  @override
  String get foodBrowserPanelLoadingModifiers => '正在加载修饰符...';

  @override
  String get foodBrowserPanelLog => '记录';

  @override
  String get foodBrowserPanelLogAMealTo => '记录一餐以在此查看您的历史记录';

  @override
  String foodBrowserPanelLogSelectedItems(Object count) {
    return '记录所选项目（$count 个）';
  }

  @override
  String get foodBrowserPanelLookingForASpecific => '寻找特定产品？请尝试搜索';

  @override
  String get foodBrowserPanelLowCal => '低热量';

  @override
  String get foodBrowserPanelModifiers => '修饰符';

  @override
  String foodBrowserPanelNoFoodsFound(Object query) {
    return '未找到与“$query”相关的食物';
  }

  @override
  String get foodBrowserPanelNoSavedFoodsYet => '暂无已保存的食物';

  @override
  String get foodBrowserPanelOnlyMatchFound => '找到唯一匹配项';

  @override
  String foodBrowserPanelPartExpandableSearchCardStateValue(
    Object calDelta,
    Object label,
    Object opt,
  ) {
    return '$label ($opt$calDelta)';
  }

  @override
  String foodBrowserPanelPartFoodBrowserItemValue(Object healthScore) {
    return '$healthScore/10';
  }

  @override
  String foodBrowserPanelPartFoodBrowserItemValue2(Object healthScore) {
    return '$healthScore/10';
  }

  @override
  String foodBrowserPanelPartNLItemSectionStateCalG(Object calPer100g) {
    return '$calPer100g 大卡/100g';
  }

  @override
  String foodBrowserPanelPartNLItemSectionStateValue(
    Object calDelta,
    Object label,
    Object opt,
  ) {
    return '$label ($opt$calDelta)';
  }

  @override
  String get foodBrowserPanelPureFat => '纯脂肪';

  @override
  String get foodBrowserPanelRecent => '最近';

  @override
  String foodBrowserPanelResultsUBMs(Object searchTimeMs, Object totalCount) {
    return '$totalCount 个结果 · ${searchTimeMs}ms';
  }

  @override
  String get foodBrowserPanelSearch528000Foods =>
      '搜索来自USDA、加拿大、印度等数据库的528,000多种食物';

  @override
  String get foodBrowserPanelSearchAlternatives => '搜索替代品...';

  @override
  String get foodBrowserPanelSearchCountries => '搜索国家...';

  @override
  String get foodBrowserPanelSearchError => '搜索错误';

  @override
  String get foodBrowserPanelSeeAll => '查看全部';

  @override
  String get foodBrowserPanelSetDefault => '设为默认';

  @override
  String get foodBrowserPanelSize => '份量';

  @override
  String get foodBrowserPanelStarFoodsAfterLogging => '记录后收藏食物以便保存';

  @override
  String get foodBrowserPanelStartTypingAbove => '在上方开始输入...';

  @override
  String get foodBrowserPanelTapItemsToAdjust => '点击项目进行调整或选择替代品';

  @override
  String get foodBrowserPanelUseAnalyzeForAi => '使用“分析”进行AI估算';

  @override
  String get foodBrowserPanelYourFoods => '我的食物';

  @override
  String get foodBrowserPanelYourSavedFoods => '我保存的食物';

  @override
  String get foodHistoryFailedToDeleteFood => '删除食物记录失败';

  @override
  String get foodHistoryFailedToReLog => '重新记录食物失败';

  @override
  String get foodHistoryFailedToUpdateFood => '更新食物记录失败';

  @override
  String get foodHistoryFoodHistory => '食物历史';

  @override
  String get foodHistoryScreenAiCoachTip => 'AI教练小贴士';

  @override
  String get foodHistoryScreenAvgDay => '平均/天';

  @override
  String get foodHistoryScreenCal => ' 卡路里';

  @override
  String get foodHistoryScreenDatabase => '数据库';

  @override
  String get foodHistoryScreenDateRange => '日期范围';

  @override
  String get foodHistoryScreenDays => '天';

  @override
  String foodHistoryScreenDeleted(Object foodName) {
    return '已删除 $foodName';
  }

  @override
  String get foodHistoryScreenEditPortion => '编辑份量';

  @override
  String foodHistoryScreenFailedToReLog(Object name) {
    return '重新记录 $name 失败';
  }

  @override
  String get foodHistoryScreenFrequentlyEaten => '常吃食物';

  @override
  String get foodHistoryScreenInflammationScore => '炎症评分';

  @override
  String get foodHistoryScreenLoadMore => '加载更多';

  @override
  String get foodHistoryScreenMealType => '餐次类型';

  @override
  String get foodHistoryScreenMeals => '餐次';

  @override
  String get foodHistoryScreenNoFoodHistoryYet => '暂无饮食记录';

  @override
  String foodHistoryScreenPartDateRangeCal(Object calories) {
    return '$calories 大卡';
  }

  @override
  String foodHistoryScreenPartDateRangeCal2(Object dayCals) {
    return '$dayCals 大卡';
  }

  @override
  String foodHistoryScreenPartDateRangeG(Object totalProteinG) {
    return '${totalProteinG}g';
  }

  @override
  String foodHistoryScreenPartDateRangeGP(Object result) {
    return '${result}g 蛋白质';
  }

  @override
  String foodHistoryScreenPartDateRangeGP2(Object dayProtein) {
    return '${dayProtein}g 蛋白质';
  }

  @override
  String foodHistoryScreenPartDateRangeNoResultsFor(Object query) {
    return '未找到 \"$query\" 的结果';
  }

  @override
  String foodHistoryScreenPartDateRangeValue(
    Object _dateLabel,
    Object _mealLabel,
    Object _sourceLabel,
  ) {
    return '$_dateLabel  ·  $_mealLabel  ·  $_sourceLabel';
  }

  @override
  String foodHistoryScreenPartFrequentFoodChipPCF(
    Object carbsG,
    Object fatG,
    Object proteinG,
  ) {
    return '${proteinG}P · ${carbsG}C · ${fatG}F';
  }

  @override
  String foodHistoryScreenPartFrequentFoodChipX(Object timesLogged) {
    return '$timesLogged次';
  }

  @override
  String get foodHistoryScreenProtein => '蛋白质';

  @override
  String foodHistoryScreenReLoggedAs(Object mealType, Object name) {
    return '已将 $name 重新记录为 $mealType';
  }

  @override
  String foodHistoryScreenReLoggedAs2(Object foodName, Object mealType) {
    return '已将 $foodName 重新记录为 $mealType';
  }

  @override
  String get foodHistoryScreenRecent => '最近';

  @override
  String get foodHistoryScreenSaveChanges => '保存更改';

  @override
  String get foodHistoryScreenSearchError => '搜索错误';

  @override
  String get foodHistoryScreenStartLoggingMealsTo => '开始记录饮食，即可在此查看历史记录！';

  @override
  String get foodHistorySearchMealsFoodsHigh => '搜索餐次、食物，“高蛋白”...';

  @override
  String get foodHistoryUndo => '撤销';

  @override
  String get foodItemRankingAddFood => '添加食物';

  @override
  String get foodItemRankingDetails => ') 详情';

  @override
  String foodItemRankingNFoodItems(Object count) {
    return '$count 个食物项目';
  }

  @override
  String get foodItemRankingScore => '评分';

  @override
  String get foodItemRankingTapToHideDetails => '点击隐藏详情';

  @override
  String get foodItemRankingTapToSeeDetails => '点击查看详情';

  @override
  String get foodLibraryAHomemadeMealWith => '包含多种成分的自制餐';

  @override
  String get foodLibraryASingleFoodType => '单一食物 — 输入名称或让AI自动填充';

  @override
  String get foodLibraryAdd => '添加';

  @override
  String get foodLibraryCustomFood => '自定义食物';

  @override
  String get foodLibraryFailedToDelete => '删除失败';

  @override
  String get foodLibraryFoodLibrary => '食物库';

  @override
  String get foodLibraryRecipe => '食谱';

  @override
  String foodLibraryScreenAdded(Object name) {
    return '已添加 “$name”';
  }

  @override
  String foodLibraryScreenAll(Object length) {
    return '全部 ($length)';
  }

  @override
  String get foodLibraryScreenCalories => '卡路里';

  @override
  String get foodLibraryScreenCarbs => '碳水化合物';

  @override
  String foodLibraryScreenDelete(Object name) {
    return '删除 $name？';
  }

  @override
  String foodLibraryScreenDeleted(Object name) {
    return '已删除 $name';
  }

  @override
  String get foodLibraryScreenDescription => '描述';

  @override
  String foodLibraryScreenFailedToLoadRecipe(Object e) {
    return '加载食谱失败: $e';
  }

  @override
  String foodLibraryScreenFailedToLog(Object e) {
    return '记录失败: $e';
  }

  @override
  String get foodLibraryScreenFat => '脂肪';

  @override
  String get foodLibraryScreenIngredients => '配料';

  @override
  String get foodLibraryScreenLog => '记录';

  @override
  String get foodLibraryScreenLogThisFood => '记录此食物';

  @override
  String get foodLibraryScreenLogToWhichMeal => '记录到哪一餐？';

  @override
  String foodLibraryScreenLoggedTo(Object label, Object name) {
    return '已将 $name 记录到 $label';
  }

  @override
  String foodLibraryScreenLogging(Object name) {
    return '正在记录 $name...';
  }

  @override
  String foodLibraryScreenPartFoodLibraryCardCal(Object calories) {
    return '$calories 卡路里';
  }

  @override
  String foodLibraryScreenPartFoodLibraryCardDelete(Object name) {
    return '删除 $name？';
  }

  @override
  String foodLibraryScreenPartFoodLibraryCardGProtein(Object item) {
    return '${item}g 蛋白质';
  }

  @override
  String foodLibraryScreenPartFoodLibraryCardLoggedX(Object timesUsed) {
    return '已记录 $timesUsed 次';
  }

  @override
  String foodLibraryScreenPartFoodLibraryCardX(Object timesUsed) {
    return '$timesUsed 次';
  }

  @override
  String get foodLibraryScreenProtein => '蛋白质';

  @override
  String get foodLibraryScreenRecipe => '食谱';

  @override
  String foodLibraryScreenRecipes(Object length) {
    return '食谱 ($length)';
  }

  @override
  String foodLibraryScreenSaved(Object length) {
    return '已保存 ($length)';
  }

  @override
  String get foodLibraryScreenSavedFood => '已保存食物';

  @override
  String get foodLibraryScreenServings => '份数';

  @override
  String get foodLibraryScreenSortBy => '排序方式';

  @override
  String get foodLibraryScreenThisActionCannotBe => '此操作无法撤销。';

  @override
  String get foodLibrarySearchFoodsAndRecipes => '搜索食物和食谱...';

  @override
  String get foodLibraryThisActionCannotBe => '此操作无法撤销。';

  @override
  String get foodLibraryUsingYourExistingCustom => '使用您现有的自定义食物';

  @override
  String get foodLoggingRulesAddRule => '添加规则';

  @override
  String get foodLoggingRulesAlwaysRules => '固定规则';

  @override
  String get foodLoggingRulesConflictingRules => '冲突规则';

  @override
  String get foodLoggingRulesDeleteRule => '删除规则？';

  @override
  String get foodLoggingRulesEGNoBun => '例如：“不要面包”或“我们做的是低油南印度菜”';

  @override
  String get foodLoggingRulesEditRule => '编辑规则';

  @override
  String get foodLoggingRulesNewAlwaysRule => '新建固定规则';

  @override
  String get foodLoggingRulesNoRulesYet => '暂无规则';

  @override
  String foodLoggingRulesScreenValue(Object text) {
    return '“$text”';
  }

  @override
  String get foodMoodAnalyticsAnalyzingMoodPatterns => '正在分析心情模式...';

  @override
  String get foodMoodAnalyticsAvailableWhenLoggingMeals => '记录饮食时可用';

  @override
  String get foodMoodAnalyticsAverage => '平均值：';

  @override
  String get foodMoodAnalyticsAvgEnergy => '平均能量';

  @override
  String get foodMoodAnalyticsByMealType => '按餐次类型';

  @override
  String foodMoodAnalyticsCardPartFoodMoodAnalyticsSheetX(Object occurrences) {
    return '$occurrences次';
  }

  @override
  String get foodMoodAnalyticsEnergyLevels => '能量水平';

  @override
  String get foodMoodAnalyticsFoodMood => '饮食与心情';

  @override
  String get foodMoodAnalyticsFoodMoodInsights => '饮食与心情洞察';

  @override
  String get foodMoodAnalyticsFoodsThatBoostYour => '提升心情的食物';

  @override
  String get foodMoodAnalyticsFoodsToWatch => '需注意的食物';

  @override
  String get foodMoodAnalyticsLogHowYouFeel => '记录餐前和餐后的感受，以发现模式';

  @override
  String get foodMoodAnalyticsMealsTracked => '已追踪餐食';

  @override
  String get foodMoodAnalyticsMoodAfterEating => '餐后心情';

  @override
  String get foodMoodAnalyticsMoodImproved => '情绪改善';

  @override
  String get foodMoodAnalyticsNoEnergyDataRecorded => '暂无能量数据记录';

  @override
  String get foodMoodAnalyticsNoMoodDataYet => '暂无心情数据';

  @override
  String foodMoodAnalyticsOftenImprovesYourMood(Object food) {
    return '$food 通常能改善您的情绪';
  }

  @override
  String get foodMoodAnalyticsStartTrackingMood => '开始追踪心情';

  @override
  String get foodMoodAnalyticsTrackYourMoodWhen => '记录饮食时追踪您的心情\n以查看模式和洞察';

  @override
  String get foodMoodAnalyticsTrackedMeals => '已追踪餐食';

  @override
  String get foodMoodAnalyticsTrackingRate => '追踪率';

  @override
  String get foodMoodAnalyticsUnableToLoadData => '无法加载数据';

  @override
  String get foodMoodAnalyticsUnableToLoadMood => '无法加载心情数据';

  @override
  String get foodReportCalories => '卡路里';

  @override
  String get foodReportCarbs => '碳水化合物';

  @override
  String get foodReportCorrectedValues => '修正值';

  @override
  String foodReportDialogFailedToSubmitReport(Object e) {
    return '提交报告失败：$e';
  }

  @override
  String foodReportDialogValue(Object reportId) {
    return '#$reportId';
  }

  @override
  String get foodReportEGISearched => '例如：我搜索的是墨西哥可乐，而不是墨西哥卷饼碗';

  @override
  String get foodReportFat => '脂肪';

  @override
  String get foodReportProtein => '蛋白质';

  @override
  String get foodReportReportIssue => '报告问题';

  @override
  String get foodReportReportSubmitted => '报告已提交';

  @override
  String get foodReportSubmitReport => '提交报告';

  @override
  String get foodReportWeLlReviewAnd => '我们将在48小时内审核并更新。\n感谢您帮助改进我们的数据！';

  @override
  String get foodReportWhatFoodDidYou => '您实际指的是什么食物？';

  @override
  String get foodReportWrongFood => '错误的食物';

  @override
  String get foodReportWrongNutrition => '营养信息错误';

  @override
  String get foodSearchBarClearAll => '全部清除';

  @override
  String get foodSearchBarRecentSearches => '最近搜索';

  @override
  String get foodSearchBarSearchFoods => '搜索食物...';

  @override
  String foodSearchResultsAiWillEstimateNutrition(Object query) {
    return 'AI 将估算 \"$query\" 的营养成分';
  }

  @override
  String get foodSearchResultsAnalyzeWithAi => '使用AI分析';

  @override
  String get foodSearchResultsDatabase => '数据库';

  @override
  String get foodSearchResultsFoodDatabase => '食物数据库';

  @override
  String foodSearchResultsG(Object result) {
    return '${result}g';
  }

  @override
  String get foodSearchResultsInstantResults => '即时结果';

  @override
  String get foodSearchResultsNoFoodsFound => '未找到食物';

  @override
  String foodSearchResultsNoSavedFoodsMatch(Object query) {
    return '没有找到与 \"$query\" 匹配的已保存食物。';
  }

  @override
  String get foodSearchResultsRecent => '最近';

  @override
  String get foodSearchResultsSavedFoods => '已保存食物';

  @override
  String get foodSearchResultsSomethingWentWrong => '出错了';

  @override
  String get foodSearchResultsTypeToSearchYour => '输入以搜索您已保存的食物、最近的餐食或数据库。';

  @override
  String get formCheckResultAiFormAnalysisIs => 'AI动作分析仅供教育参考。请咨询专业教练以获取个性化指导。';

  @override
  String get formCheckResultAreasToImprove => '待改进区域';

  @override
  String get formCheckResultBreathing => '呼吸';

  @override
  String formCheckResultCardEstimatedReps(Object repCount) {
    return '~$repCount 次预估次数';
  }

  @override
  String formCheckResultCardObserved(Object pattern) {
    return '观察到：$pattern';
  }

  @override
  String formCheckResultCardObserved2(Object observed) {
    return '观察到：$observed';
  }

  @override
  String formCheckResultCardShowMore(Object improvements) {
    return '显示 $improvements 项更多改进...';
  }

  @override
  String formCheckResultCardValue(Object score) {
    return '$score/10';
  }

  @override
  String get formCheckResultDoingWell => '做得好的地方';

  @override
  String get formCheckResultFormCheck => '动作检查';

  @override
  String get formCheckResultGood => '良好';

  @override
  String get formCheckResultNeedsWork => '需要改进';

  @override
  String get formCheckResultSendAVideoOf => '发送您的锻炼视频，我将为您检查动作、计算次数并提供纠正建议。';

  @override
  String get formCheckResultTempo => '节奏';

  @override
  String get formComparisonResultAiFormAnalysisIs =>
      'AI动作分析仅供教育参考。请咨询专业教练以获取个性化指导。';

  @override
  String get formComparisonResultBeta => 'BETA';

  @override
  String formComparisonResultCardReps(Object repCount) {
    return '$repCount 次';
  }

  @override
  String get formComparisonResultConsistent => '保持一致';

  @override
  String get formComparisonResultFormComparison => '动作对比';

  @override
  String get formComparisonResultImproved => '有进步';

  @override
  String get formComparisonResultImproving => '正在改善';

  @override
  String get formComparisonResultOverallTrend => '总体趋势';

  @override
  String get formComparisonResultRecommendations => '建议';

  @override
  String get formComparisonResultRegressed => '退步';

  @override
  String get formComparisonResultRegressing => '正在退步';

  @override
  String get formComparisonResultScoreTrend => '评分趋势';

  @override
  String get formComparisonResultStable => '保持稳定';

  @override
  String get founderNoteDiscord => 'Discord';

  @override
  String get founderNoteRoadmap => '路线图';

  @override
  String get founderNoteFounderSoloStillOn => '创始人，单枪匹马，仍在第一版。';

  @override
  String get founderNoteIUsedToLog =>
      '我曾经连续两周记录每一顿饭，为自己感到自豪，然后走进一家看不懂菜单的泰国餐厅，吃看起来最安全的东西，然后默默地不再打开那个应用。三周后，我会重新安装另一个应用，发誓这次一定能坚持，然后再次陷入同样的循环。每个应用都记录了我的数据，但没有一个在我沉默时注意到我——它们只是账本，而不是教练。';

  @override
  String get founderNoteInstagram => 'Instagram';

  @override
  String founderNoteSheetANoteFrom(Object _founderName) {
    return '来自 $_founderName 的寄语';
  }

  @override
  String founderNoteSheetValue(Object _founderName) {
    return '— $_founderName';
  }

  @override
  String get founderNoteSoIBuiltThe =>
      '所以我建立的是人，而不是账本。拍下任何菜单——无论是在国内还是国外——教练都会以宏的方式将其读给你听。跳过周二，周三早上你就会回到过去，而不会感到内疚。它可以了解您的食物、您的健身情况、您的滑倒模式——每月只需不到一次的 PT 疗程。';

  @override
  String get founderNoteTheFriendsWhoActually =>
      '那些真正瘦下来的朋友都有一个随时发信息给他们的人。真正的监督每月大约需要两百美元，这正是我们大多数人从未拥有它的原因，也正是“记录”与“改变”之间的鸿沟多年来无法弥合的原因。';

  @override
  String get freshnessDecayCardAgo => '前';

  @override
  String get freshnessDecayCardControlsHowQuicklyExercise =>
      '控制运动新鲜度衰减的速度：e^(-k * 会话数)';

  @override
  String get freshnessDecayCardFreshnessDecayTuner => '新鲜度衰减调节器';

  @override
  String freshnessDecayCardK(Object _freshnessDecay) {
    return 'k = $_freshnessDecay';
  }

  @override
  String get freshnessDecayCardLivePreview => '实时预览';

  @override
  String get freshnessDecayCardRange0100 => '范围：0.10 - 0.60';

  @override
  String freshnessDecayCardUsedSessionsAgo(num sessions) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions 次训练前使用过',
      one: '1 次训练前使用过',
    );
    return '$_temp0';
  }

  @override
  String friendAvatarsRowMore(Object remaining) {
    return '+$remaining 位';
  }

  @override
  String get friendAvatarsRowOnThisGoal => '在此目标上';

  @override
  String friendCardBadges(Object totalAchievements) {
    return '$totalAchievements 枚徽章';
  }

  @override
  String friendCardDayStreak(Object currentStreak) {
    return '$currentStreak 天连胜';
  }

  @override
  String get friendCardFollow => '关注';

  @override
  String get friendCardFriend => '好友';

  @override
  String friendCardSupport(Object appName) {
    return '$appName 支持';
  }

  @override
  String get friendCardUnfollow => '取消关注';

  @override
  String friendCardWorkouts(Object totalWorkouts) {
    return '$totalWorkouts 次锻炼';
  }

  @override
  String get friendProfileBlock => '拉黑';

  @override
  String get friendProfileBlockUser => '拉黑用户';

  @override
  String get friendProfileFailedToOpenConversation => '无法打开对话';

  @override
  String get friendProfileFailedToUpdateFollow => '无法更新关注状态';

  @override
  String get friendProfileFollow => '关注';

  @override
  String get friendProfileFollowers => '粉丝';

  @override
  String get friendProfileFollowing => '关注中';

  @override
  String get friendProfileMemberInfo => '会员信息';

  @override
  String get friendProfileMessage => '私信';

  @override
  String get friendProfileMoreDetailsComingSoon => '更多详情敬请期待';

  @override
  String get friendProfileThisUserWillNot => '该用户将无法查看您的内容或给您发送消息。您可以稍后解除拉黑。';

  @override
  String get friendProfileUserBlocked => '用户已拉黑';

  @override
  String get friendProfileWorkoutHistoryPrsAnd => '锻炼历史、PR和奖杯\n将显示在此处。';

  @override
  String get friendSearchFindFriends => '寻找好友';

  @override
  String get friendSearchFollowFriendsToGet => '关注好友以获取更好的推荐';

  @override
  String get friendSearchNoSuggestionsYet => '暂无推荐';

  @override
  String get friendSearchNoUsersFound => '未找到用户';

  @override
  String get friendSearchSearch => '搜索';

  @override
  String get friendSearchSearchByNameOr => '按姓名或用户名搜索...';

  @override
  String get friendSearchSearchForFriends => '搜索好友';

  @override
  String get friendSearchSuggestions => '推荐';

  @override
  String get friendSearchTryADifferentSearch => '尝试不同的搜索词';

  @override
  String get friendSearchTypeANameOr => '输入姓名或用户名以查找用户';

  @override
  String get friendsAddFriendsToSee => '添加好友以查看他们的锻炼\n并一起参加挑战！';

  @override
  String get friendsCouldNotLoadUsers => '无法加载您关注的用户。\n请重试。';

  @override
  String get friendsCouldNotLoadYour => '无法加载您的好友列表。\n请重试。';

  @override
  String get friendsCouldNotLoadYour2 => '无法加载您的粉丝列表。\n请重试。';

  @override
  String get friendsFailedToLoadFollowers => '无法加载粉丝';

  @override
  String get friendsFailedToLoadFollowing => '无法加载关注列表';

  @override
  String get friendsFailedToLoadFriends => '无法加载好友';

  @override
  String get friendsFollowFriendsToSee => '关注好友以查看他们的锻炼\n并共同保持动力！';

  @override
  String get friendsFollowers => '粉丝';

  @override
  String get friendsFollowing => '关注中';

  @override
  String get friendsFriendRequests => '好友请求';

  @override
  String get friendsKeepCrushingYourWorkouts => '继续努力锻炼！\n好友们会想要关注你的进步。';

  @override
  String get friendsNoFollowersYet => '暂无粉丝';

  @override
  String get friendsNoFriendsYet => '暂无好友';

  @override
  String get friendsNotFollowingAnyone => '未关注任何人';

  @override
  String get fuelFasting => '断食';

  @override
  String get fuelNutrients => '营养素';

  @override
  String get fuelWater => '水分';

  @override
  String get fullScreenChart1y => '1年';

  @override
  String get fullScreenChart30d => '30天';

  @override
  String get fullScreenChart7d => '7天';

  @override
  String get fullScreenChart90d => '90天';

  @override
  String get fullScreenChartAll => '全部';

  @override
  String get fullScreenChartCompareWith => '对比…';

  @override
  String get fullScreenChartCouldNotLoad => '无法加载';

  @override
  String get fullScreenChartNotEnoughHistory => '历史数据不足';

  @override
  String get fullscreenImageViewerCouldNotLoadImage => '无法加载图片';

  @override
  String get futuristicSetCardAiSuggested => 'AI 建议';

  @override
  String get futuristicSetCardHidePrevious => '隐藏上次记录';

  @override
  String futuristicSetCardRir(Object targetRir) {
    return '$targetRir RIR';
  }

  @override
  String futuristicSetCardRmKg(Object suggestion) {
    return '1RM: ${suggestion}kg';
  }

  @override
  String futuristicSetCardSetOf(Object currentSetNumber, Object totalSets) {
    return '第 $currentSetNumber 组，共 $totalSets 组';
  }

  @override
  String get futuristicSetCardSkipExercise => '跳过动作';

  @override
  String futuristicSetCardValue(Object targetReps) {
    return '$targetReps';
  }

  @override
  String futuristicSetCardValue2(Object reps) {
    return '$reps';
  }

  @override
  String get generatePlanCreateAHolisticPlan => '创建一个协调您的锻炼、营养和禁食的整体计划。';

  @override
  String get generatePlanFastingProtocol => '禁食方案';

  @override
  String get generatePlanGeneratePlan => '生成计划';

  @override
  String get generatePlanGenerateWeeklyPlan => '生成周计划';

  @override
  String get generatePlanGenerating => '正在生成...';

  @override
  String get generatePlanNutritionStrategy => '营养策略';

  @override
  String get generatePlanPreferredWorkoutTime => '首选锻炼时间';

  @override
  String get generatePlanTrainingDays => '训练日';

  @override
  String get generatePlanWeeklyPlanGenerated => '周计划已生成！';

  @override
  String get generateWorkoutPlaceholderEachWorkoutAdaptsTo =>
      '每次锻炼都会自动调整，助您安全进步！';

  @override
  String get generateWorkoutPlaceholderGenerateWorkout => '生成锻炼';

  @override
  String get generateWorkoutPlaceholderGenerating => '正在生成...';

  @override
  String get generateWorkoutPlaceholderGenerationFailed => '生成失败';

  @override
  String get generateWorkoutPlaceholderPersonalizedUsingYourWorkou =>
      '根据您的锻炼历史进行个性化定制';

  @override
  String get generateWorkoutPlaceholderTapBelowToTry => '点击下方重试';

  @override
  String get generateWorkoutPlaceholderTapToRetry => '点击重试';

  @override
  String get generateWorkoutPlaceholderWhatPowersYourWorkout => '是什么驱动您的锻炼？';

  @override
  String get generateWorkoutPlaceholderYourAiCoachCreates =>
      '您的 AI 教练会根据以下内容创建锻炼：';

  @override
  String get glassDragToResize => '拖动以调整大小';

  @override
  String get globalChatBubbleAskMeAnythingAbout => '问我任何关于健身的问题';

  @override
  String get globalChatBubbleAskYourAiCoach => '询问您的 AI 教练...';

  @override
  String get globalChatBubbleChangeCoach => '更换教练';

  @override
  String get globalChatBubbleErrorLoadingMessages => '加载消息时出错';

  @override
  String get globalChatBubbleHowCanIHelp => '今天有什么我可以帮您的吗？';

  @override
  String get globalChatBubbleOnline => '在线';

  @override
  String get globalChatBubbleTyping => '正在输入...';

  @override
  String get glossaryGlossary => '术语表';

  @override
  String get glossaryNoTermsFound => '未找到术语';

  @override
  String glossaryScreenTerms(Object length) {
    return '$length个术语';
  }

  @override
  String get glossarySearchTerms => '搜索术语...';

  @override
  String glowButtonCompleteSet(Object setNumber) {
    return '完成组数 $setNumber';
  }

  @override
  String get goalCard1DayLeft => '剩余 1 天';

  @override
  String get goalCardBestAttempt => '最佳尝试';

  @override
  String goalCardDaysLeft(Object daysRemaining) {
    return '剩余 $daysRemaining 天';
  }

  @override
  String get goalCardDeleteGoal => '删除目标';

  @override
  String get goalCardNewPr => '新 PR！';

  @override
  String goalCardPermanentlyRemove(Object exerciseName) {
    return '永久移除“$exerciseName”';
  }

  @override
  String get goalCardPersonalBest => '个人最佳';

  @override
  String get goalCardViewProgressHistory => '查看进度历史';

  @override
  String get goalHistoryAllTimeBest => '历史最佳';

  @override
  String get goalHistoryChartAllTimeBest => '历史最佳';

  @override
  String goalHistoryChartBestValue(Object value) {
    return '最佳：$value';
  }

  @override
  String get goalHistoryChartCompleteMoreWeeksTo => '完成更多周数以查看您的目标趋势';

  @override
  String get goalHistoryChartGoalTrends => '目标趋势';

  @override
  String get goalHistoryChartNoHistoryYet => '暂无历史记录';

  @override
  String get goalHistoryCouldNotLoadHistory => '无法加载历史记录';

  @override
  String get goalHistoryThisWeek => '本周';

  @override
  String get goalHistoryTipsForBeatingYour => '打破 PR 的技巧';

  @override
  String get goalHistoryTryAgain => '重试';

  @override
  String get goalHistoryU2022 => '• ';

  @override
  String get goalLeaderboardCouldNotLoadLeaderboard => '无法加载排行榜';

  @override
  String get goalLeaderboardFriendsLeaderboard => '好友排行榜';

  @override
  String get goalLeaderboardInviteFriendsToCompete => '邀请好友来竞争！';

  @override
  String get goalLeaderboardNoFriendsOnThis => '此目标暂无好友参与';

  @override
  String get goalLeaderboardPr => 'PR';

  @override
  String goalLeaderboardSheetValue(Object userProgressPercentage) {
    return '$userProgressPercentage%';
  }

  @override
  String get googleCalendarConnectConnectGoogleCalendar => '连接 Google Calendar';

  @override
  String get googleCalendarConnectConnected => '已连接';

  @override
  String get googleCalendarConnectDisconnect => '断开连接';

  @override
  String get googleCalendarConnectFailedToConnectGoogle =>
      '无法连接 Google Calendar';

  @override
  String get googleCalendarConnectGoogleCalendar => 'Google Calendar';

  @override
  String get googleCalendarConnectGoogleCalendarConnected =>
      'Google Calendar 已连接！';

  @override
  String get googleCalendarConnectGoogleCalendarDisconnected =>
      'Google Calendar 已断开连接';

  @override
  String googleCalendarConnectSheetConnectYourGoogleCalendar(Object appName) {
    return '连接您的 Google Calendar 以查看忙碌时间并同步 $appName 事件';
  }

  @override
  String get googleCalendarConnectWeOnlyAccessCalendar => '我们仅访问您明确允许的日历数据';

  @override
  String get groceryListAdd => '添加';

  @override
  String get groceryListAddItem => '添加项目';

  @override
  String get groceryListAisleOptional => '货架（可选）';

  @override
  String get groceryListCopiedToClipboard => '已复制到剪贴板';

  @override
  String get groceryListCopyAsText => '复制为文本';

  @override
  String get groceryListGroceryList => '购物清单';

  @override
  String get groceryListHidePantryStaples => '隐藏常备食品';

  @override
  String get groceryListHidingKeepsTheList => '隐藏常备食品可让清单专注于您真正需要的东西';

  @override
  String get groceryListItemName => '项目名称';

  @override
  String get groceryListNoItemsYet => '暂无项目';

  @override
  String get groceryListQty => '数量';

  @override
  String get groceryListShareAsCsv => '分享为 CSV';

  @override
  String get groceryListShowPantryStaples => '显示常备食材';

  @override
  String get groceryListTapTheButtonBelow => '点击下方的 + 按钮添加食材。';

  @override
  String get groceryListUnitGCup => '单位 (g, cup, ...)';

  @override
  String get groceryListsIndexCreate => '创建';

  @override
  String get groceryListsIndexGroceryLists => '购物清单';

  @override
  String get groceryListsIndexListNameOptional => '清单名称（可选）';

  @override
  String get groceryListsIndexNewGroceryList => '新建购物清单';

  @override
  String get groceryListsIndexNoListsYet => '暂无清单';

  @override
  String groceryListsIndexScreenOfChecked(
    Object checkedCount,
    Object itemCount,
  ) {
    return '已勾选 $checkedCount / $itemCount 项';
  }

  @override
  String get groceryListsIndexTapToCreateA => '点击 + 创建清单，或从食谱中添加。';

  @override
  String get groceryListsIndexUntitled => '未命名';

  @override
  String get groundingPromptGroundYourself => '平复心情';

  @override
  String get groundingPromptIMReady => '我准备好了';

  @override
  String get groupCreateCreateGroup => '创建群组';

  @override
  String get groupCreateEGGymSquad => '例如：健身小分队';

  @override
  String get groupCreateFailedToLoadFriends => '加载好友失败';

  @override
  String get groupCreateMin2Required => '至少需要 2 人';

  @override
  String get groupCreateNewGroup => '新建群组';

  @override
  String get groupCreateNoFriendsToAdd => '没有可添加的好友';

  @override
  String get groupCreateSearchFriends => '搜索好友...';

  @override
  String groupCreateSheetNoFriendsMatching(Object searchQuery) {
    return '没有匹配“$searchQuery”的好友';
  }

  @override
  String groupCreateSheetSelectFriendsSelected(Object length) {
    return '选择好友（已选 $length 位）';
  }

  @override
  String get groupSettingsAdd => '添加';

  @override
  String get groupSettingsAddMembers => '添加成员';

  @override
  String get groupSettingsAdmin => '管理员';

  @override
  String get groupSettingsAllYourFriendsAre => '你的所有好友已在该群组中';

  @override
  String get groupSettingsAreYouSureYou => '确定要退出该群组吗？退出后你将无法再收到此对话的消息。';

  @override
  String get groupSettingsGroupNameUpdated => '群组名称已更新';

  @override
  String get groupSettingsGroupSettings => '群组设置';

  @override
  String get groupSettingsLeave => '退出';

  @override
  String get groupSettingsLeaveGroup => '退出群组';

  @override
  String get groupSettingsMemberListWillLoad => '成员列表将从服务器加载';

  @override
  String get groupSettingsMembers => '成员';

  @override
  String get groupSettingsRemove => '移除';

  @override
  String get groupSettingsRemoveMember => '移除成员';

  @override
  String groupSettingsScreenAdd(Object length) {
    return '添加 ($length)';
  }

  @override
  String groupSettingsScreenAddedMemberS(Object length) {
    return '已添加 $length 位成员';
  }

  @override
  String groupSettingsScreenFailedToUpdateName(Object e) {
    return '更新名称失败：$e';
  }

  @override
  String groupSettingsScreenRemoveFromThisGroup(Object memberName) {
    return '将 $memberName 从此群组中移除？';
  }

  @override
  String groupSettingsScreenRemovedFromGroup(Object memberName) {
    return '已将 $memberName 从群组中移除';
  }

  @override
  String groupSettingsScreenYou(Object memberName) {
    return '$memberName (您)';
  }

  @override
  String get guestHome1700WithSignup => '注册即可解锁 1700+ 动作';

  @override
  String get guestHomeAiCoachDemo => 'AI 教练演示';

  @override
  String get guestHomeAllFree => '全部免费';

  @override
  String get guestHomeContinuePreview => '继续预览';

  @override
  String get guestHomeEnjoyingThePreview => '喜欢这个预览吗？';

  @override
  String get guestHomeExerciseLibrary => '动作库';

  @override
  String get guestHomeGetUnlimitedAiCoaching => '获取无限 AI 教练指导';

  @override
  String get guestHomeInteractive => '互动式';

  @override
  String get guestHomePreview => '预览';

  @override
  String get guestHomePreview20Exercises => '预览 20 个动作';

  @override
  String get guestHomeScreenAiCoachChat => 'AI 教练对话';

  @override
  String get guestHomeScreenAskAnythingAboutFitness => '咨询任何健身相关问题';

  @override
  String guestHomeScreenExploreWhatCanDo(Object appName) {
    return '探索 $appName 的功能';
  }

  @override
  String get guestHomeScreenLiveDemo => '实时演示';

  @override
  String get guestHomeScreenTapToTryAi => '点击尝试 AI 教练';

  @override
  String get guestHomeSeeHowYourPersonal => '看看你的专属 AI 教练如何工作';

  @override
  String get guestHomeSessionEndingSoon => '预览即将结束';

  @override
  String get guestHomeSignUpFree => '免费注册';

  @override
  String get guestHomeSignUpFreeTo => '免费注册，无限制使用所有功能！';

  @override
  String get guestHomeSignUpFreeTo2 => '免费注册，解锁全部功能，开启你的健身之旅！';

  @override
  String get guestHomeSignUpFreeTo3 => '免费注册，随时提问并获取个性化健身建议';

  @override
  String get guestHomeTapAQuestionTo => '点击问题查看 AI 回复';

  @override
  String get guestHomeTryItNow => '立即尝试';

  @override
  String get guestHomeWelcomeGuest => '欢迎，访客';

  @override
  String get guestHomeWhatYouLlGet => '你将获得';

  @override
  String get guestHomeYour10MinutePreview => '你的 10 分钟预览时间已结束。';

  @override
  String get guestLibraryBrowseSampleExercises => '浏览示例动作';

  @override
  String get guestLibraryClearSearch => '清除搜索';

  @override
  String get guestLibraryExerciseLibrary => '动作库';

  @override
  String get guestLibraryFailedToLoadExercises => '加载动作失败';

  @override
  String get guestLibraryGetVideoDemonstrations => '获取视频演示';

  @override
  String get guestLibraryInstructions => '说明';

  @override
  String get guestLibraryNoExercisesFound => '未找到相关动作';

  @override
  String get guestLibraryPreview => '预览';

  @override
  String guestLibraryScreenShowingSampleExercisesSign(
    Object guestExerciseLimit,
  ) {
    return '展示 $guestExerciseLimit 个示例练习。免费注册即可访问 1700+ 个练习！';
  }

  @override
  String get guestLibrarySearchExercises => '搜索动作...';

  @override
  String get guestLibrarySignUp => '注册';

  @override
  String get guestLibrarySignUpFree => '免费注册';

  @override
  String get guestLibrarySignUpFreeTo => '免费注册，即可访问包含视频演示和说明的完整动作库。';

  @override
  String get guestLibrarySignUpFreeTo2 => '免费注册，即可观看所有动作的高清视频指南。';

  @override
  String get guestLibrarySignUpToView => '注册后即可查看该动作的详细说明。';

  @override
  String get guestLibraryUnlock1700Exercises => '解锁 1700+ 动作';

  @override
  String get guestLockedFeatureUnlockFree => '免费解锁';

  @override
  String get guestSampleWorkoutExercises => '动作';

  @override
  String get guestSampleWorkoutExercisesIncluded => '包含动作：';

  @override
  String get guestSampleWorkoutFullBodyStrength => '全身力量训练';

  @override
  String get guestSampleWorkoutGetPersonalizedWorkouts => '获取个性化训练计划';

  @override
  String get guestSampleWorkoutSampleWorkout => '训练示例';

  @override
  String get guestSampleWorkoutSampleWorkoutDemo => '训练示例演示';

  @override
  String get guestSampleWorkoutSignUpFree => '免费注册';

  @override
  String get guestSampleWorkoutSignUpFreeTo =>
      '免费注册，获取根据您的目标、器械和日程量身定制的AI健身计划。';

  @override
  String get guestSampleWorkoutTapToSeeWorkout => '点击查看健身演示';

  @override
  String get guestSessionTimerFreeDemoDay => '免费体验日';

  @override
  String get guestSessionTimerPreviewPlan => '预览计划';

  @override
  String get guestSessionTimerTryFree => '免费试用';

  @override
  String get guestSessionTimerTryWorkout => '尝试健身';

  @override
  String get guestSignUpGetYourPersonalPlan => '获取您的专属计划';

  @override
  String get guestSignUpSeeYourFullWorkout => '付款前查看完整的健身计划 - 无需信用卡！';

  @override
  String get guestSignUpSignUp => '注册';

  @override
  String get guestUpgradeContinueAsGuest => '以访客身份继续';

  @override
  String get guestUpgradeGuestMode => '访客模式';

  @override
  String guestUpgradeSheetChatsLeft(Object remainingChatMessages) {
    return '还剩 $remainingChatMessages 次对话';
  }

  @override
  String get guestUpgradeSignUp => '注册';

  @override
  String get guestUpgradeSignUpFree => '免费注册';

  @override
  String get guestUpgradeSignUpFreeFor => '免费注册以获取无限访问权限';

  @override
  String get guestUpgradeYourGuestUsageToday => '今日访客使用情况';

  @override
  String get gymEquipmentDeselectAll => '取消全选';

  @override
  String get gymEquipmentEditWeights => '编辑重量';

  @override
  String get gymEquipmentEquipment => '器械';

  @override
  String get gymEquipmentFilterEquipmentByName => '按名称筛选器械';

  @override
  String get gymEquipmentImportFromPdfPhotos => '从PDF、照片或URL导入';

  @override
  String get gymEquipmentLetAiPopulateYour => '让AI自动填充您的器械列表';

  @override
  String get gymEquipmentResetAll => '重置所有';

  @override
  String get gymEquipmentSelectAll => '全选';

  @override
  String gymEquipmentSheetSaveItems(Object length) {
    return '保存 $length 项';
  }

  @override
  String gymEquipmentSheetSelected(Object length) {
    return '已选 $length 项';
  }

  @override
  String get gymLocationPickerGymLocation => '健身房位置';

  @override
  String get gymLocationPickerMapBasedLocationPicker =>
      '基于地图的位置选择器暂不可用。\n目前，请在个人资料中设置您的健身房名称。';

  @override
  String get gymProfileSwitcherActive => '当前';

  @override
  String get gymProfileSwitcherAddGym => '添加健身房';

  @override
  String gymProfileSwitcherAreYouSureYou(Object name) {
    return '确定要删除 \"$name\" 吗？此操作无法撤销。';
  }

  @override
  String gymProfileSwitcherCreated(Object result) {
    return '已创建 \"$result\"';
  }

  @override
  String get gymProfileSwitcherDeleteGym => '删除健身房？';

  @override
  String gymProfileSwitcherDeleted(Object name) {
    return '已删除 \"$name\"';
  }

  @override
  String get gymProfileSwitcherDragToReorderProfiles => '拖动以重新排序资料';

  @override
  String get gymProfileSwitcherDuplicate => '复制';

  @override
  String get gymProfileSwitcherDuplicateGym => '复制健身房';

  @override
  String get gymProfileSwitcherEnterANameFor => '输入复制的健身房名称：';

  @override
  String gymProfileSwitcherEquipment(
    Object environmentDisplayName,
    Object equipmentCount,
  ) {
    return '$equipmentCount 件器械 • $environmentDisplayName';
  }

  @override
  String gymProfileSwitcherFailedToDelete(Object e) {
    return '删除失败: $e';
  }

  @override
  String gymProfileSwitcherFailedToSwitchProfile(Object e) {
    return '切换配置失败: $e';
  }

  @override
  String get gymProfileSwitcherGymName => '健身房名称';

  @override
  String get gymProfileSwitcherManageProfiles => '管理资料';

  @override
  String get gymProfileSwitcherSwitchGym => '切换健身房';

  @override
  String get gymProfileSwitcherTapToRetry => '点击重试';

  @override
  String get habitCardLast30Days => '过去30天';

  @override
  String habitCardValue(Object completionRate7d) {
    return '$completionRate7d%';
  }

  @override
  String get habitDetailCalendar => '日历';

  @override
  String get habitDetailFailedToCaptureImage => '无法捕获图像';

  @override
  String get habitDetailFailedToLoadHabit => '无法加载习惯详情';

  @override
  String get habitDetailHabitNotFound => '未找到该习惯';

  @override
  String get habitDetailOverview => '概览';

  @override
  String get habitDetailScreen8WeekTrend => '8周趋势';

  @override
  String get habitDetailScreenBest => '最佳';

  @override
  String get habitDetailScreenCompleteThisHabitTo => '完成此习惯以查看您的历史记录';

  @override
  String get habitDetailScreenCompleted => '已完成';

  @override
  String get habitDetailScreenDayOfWeek => '星期';

  @override
  String get habitDetailScreenDayStreak => '天连续记录';

  @override
  String get habitDetailScreenHabitStrength => '习惯强度';

  @override
  String get habitDetailScreenMissed => '未完成';

  @override
  String get habitDetailScreenMonthlySummary => '月度总结';

  @override
  String get habitDetailScreenNoActivityYet => '暂无活动';

  @override
  String get habitDetailScreenNoMonthlyDataYet => '暂无月度数据';

  @override
  String get habitDetailScreenNotEnoughDataYet => '数据不足';

  @override
  String habitDetailScreenPartCompactHeroSectionDaysUntilYouBeat(
    Object daysUntilBestStreak,
  ) {
    return '再过 $daysUntilBestStreak 天即可打破你的个人最佳纪录！';
  }

  @override
  String habitDetailScreenPartCompactHeroSectionValue(Object completionRate) {
    return '$completionRate%';
  }

  @override
  String habitDetailScreenPartCompactHeroSectionValue2(Object strength) {
    return '$strength%';
  }

  @override
  String habitDetailScreenPartYearlyHeatmapStateActivity(Object year) {
    return '$year 活动';
  }

  @override
  String habitDetailScreenPartYearlyHeatmapStateValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String get habitDetailScreenRate => '完成率';

  @override
  String get habitDetailScreenStreak => '连续记录';

  @override
  String get habitDetailScreenTotal => '总计';

  @override
  String get habitDetailScreenWeeklyCompletions => '每周完成情况';

  @override
  String get habitDetailSharedSuccessfully => '分享成功！';

  @override
  String get habitProgressHeaderAllDone => '全部完成！';

  @override
  String habitProgressHeaderComplete(Object percentage) {
    return '已完成 $percentage%';
  }

  @override
  String habitProgressHeaderOf(Object total) {
    return '$total 中的';
  }

  @override
  String get habitProgressHeaderTodaySHabits => '今日习惯';

  @override
  String get habitProgressHeaderYouCompletedAllYour => '您今天完成了所有习惯！';

  @override
  String get habitTemplatesChooseATemplate => '选择模板';

  @override
  String habitTemplatesSheetTarget(Object suggestedTargetCount, Object unit) {
    return '目标：$suggestedTargetCount $unit';
  }

  @override
  String get habits30DayRate => '30天完成率';

  @override
  String get habitsAddHabit => '添加习惯';

  @override
  String get habitsBestStreak => '最佳连续记录';

  @override
  String get habitsCardAddYourFirstHabit => '添加您的第一个习惯';

  @override
  String get habitsCardAllHabitsCompleted => '所有习惯已完成！';

  @override
  String get habitsCardBuildDailyHabits => '养成日常习惯';

  @override
  String habitsCardCompletedCount(Object arg0, Object arg1) {
    return '完成次数 $arg0 $arg1';
  }

  @override
  String habitsCardDayStreak(Object arg0) {
    return '连续打卡 $arg0 天';
  }

  @override
  String get habitsCardFailedToLoadHabits => '无法加载习惯';

  @override
  String get habitsCardGreatJobKeepingUp => '保持连续记录，做得好';

  @override
  String get habitsCardQuickStart => '快速开始：';

  @override
  String get habitsCardStartTrackingDailyHabits => '开始追踪日常习惯，以建立一致性并实现您的目标。';

  @override
  String get habitsCardTodaySHabits => '今日习惯';

  @override
  String get habitsCardTryAgain => '重试';

  @override
  String get habitsCardU1f525 => '🔥';

  @override
  String habitsCardViewAllHabits(Object arg0) {
    return '查看所有习惯 $arg0';
  }

  @override
  String get habitsCompleted => '已完成';

  @override
  String get habitsDeleteHabit => '删除习惯？';

  @override
  String get habitsHoldToReorderSwipe => '长按以排序 • 滑动以删除';

  @override
  String get habitsLog => '+ 记录';

  @override
  String get habitsLog2 => '记录';

  @override
  String habitsScreenAdded(Object name) {
    return '已添加 “$name”';
  }

  @override
  String habitsScreenDeleted(Object name) {
    return '已删除 “$name”';
  }

  @override
  String habitsScreenOfDays(Object last30Days) {
    return '30 天中的 $last30Days 天';
  }

  @override
  String get habitsScreenPartAddHabit => '添加习惯';

  @override
  String get habitsScreenPartCreateCustomHabit => '创建自定义习惯';

  @override
  String get habitsScreenPartDefineYourOwnHabit => '使用自定义名称和图标定义您自己的习惯';

  @override
  String get habitsScreenPartNoHabitsFound => '未找到习惯';

  @override
  String get habitsScreenPartOrChooseATemplate => '或选择一个模板';

  @override
  String get habitsScreenPartSearchHabits => '搜索习惯...';

  @override
  String get habitsScreenUiChooseColor => '选择颜色';

  @override
  String get habitsScreenUiChooseIcon => '选择图标';

  @override
  String get habitsScreenUiCreateCustomHabit => '创建自定义习惯';

  @override
  String get habitsScreenUiCreateHabit => '创建习惯';

  @override
  String habitsScreenUiCreated(Object habitName) {
    return '已创建“$habitName”';
  }

  @override
  String habitsScreenUiCreatedXpBonus(Object habitName, Object xpAwarded) {
    return '已创建“$habitName” +$xpAwarded XP 奖励！';
  }

  @override
  String habitsScreenUiFailedToCreateHabit(Object e) {
    return '创建习惯失败：$e';
  }

  @override
  String get habitsScreenUiHabitName => '习惯名称';

  @override
  String get habitsScreenUiPleaseEnterAHabit => '请输入习惯名称';

  @override
  String get habitsScreenUiPreview => '预览';

  @override
  String habitsScreenValue(Object autoPercentage) {
    return '$autoPercentage%';
  }

  @override
  String get habitsTileCardAddHabit => '添加习惯';

  @override
  String get habitsTileCardAllHabitsDoneToday => '今天的所有习惯已完成！';

  @override
  String get habitsTileCardBuildHealthyHabits => '养成健康习惯';

  @override
  String get habitsTileCardHabits => '习惯';

  @override
  String get habitsTileCardLoadingHabits => '正在加载习惯...';

  @override
  String habitsTileCardMore(Object remainingCount) {
    return '+$remainingCount 项更多';
  }

  @override
  String get habitsTileCardNoHabits => '暂无习惯';

  @override
  String get habitsTileCardSignInToTrack => '登录以追踪习惯';

  @override
  String get habitsTileCardTodaySHabits => '今日习惯';

  @override
  String get habitsTodaySProgress => '今日进度';

  @override
  String get habitsViewTrends => '查看趋势';

  @override
  String get habitsYourHabits => '您的习惯';

  @override
  String get hapticsHapticFeedback => '触觉反馈';

  @override
  String get hapticsHaptics => '触觉反馈';

  @override
  String get hardPaywallBestStreak => '最佳连胜';

  @override
  String get hardPaywallCancelAnytimeInSettings => '可在设置中随时取消';

  @override
  String get hardPaywallDonTLoseYour => '不要丢失您的进度';

  @override
  String get hardPaywallGet25Off37 => '享受 25% 折扣 — \$37.49/年';

  @override
  String get hardPaywallLbsLifted => '磅举重总量';

  @override
  String get hardPaywallPurchasesRestored => '购买记录已恢复！';

  @override
  String get hardPaywallRestorePurchases => '恢复购买';

  @override
  String get hardPaywallSignOut => '退出登录';

  @override
  String get hardPaywallSubscribeNow => '立即订阅';

  @override
  String get hardPaywallWelcomeBack => '欢迎回来！';

  @override
  String get hardPaywallYourAiCoachRemembers => '您的 AI 教练记得一切';

  @override
  String get hardPaywallYourProgressIsStill => '您的进度依然保留。订阅以从上次中断的地方继续。';

  @override
  String get hardPaywallYourTrialHasEnded => '您的试用期已结束';

  @override
  String hashtagFeedScreenNoPostsWith(Object hashtagName) {
    return '没有带有 #$hashtagName 的帖子';
  }

  @override
  String hashtagFeedScreenValue(Object hashtagName) {
    return '#$hashtagName';
  }

  @override
  String get healthBreakdownAddedSugar => '添加糖';

  @override
  String get healthBreakdownBloodSugar => '血糖';

  @override
  String get healthBreakdownChronicLowGradeInflammation =>
      '慢性低度炎症会影响关节舒适度、能量和恢复。';

  @override
  String get healthBreakdownFodmap => 'FODMAP';

  @override
  String get healthBreakdownGlycemicLoadGiCarbs =>
      '血糖负荷 = GI × 碳水化合物 ÷ 100。数值越低，能量越平稳，血糖波动越小。';

  @override
  String get healthBreakdownHealthBreakdown => '健康分析';

  @override
  String get healthBreakdownInflammation => '炎症';

  @override
  String get healthBreakdownNoGlycemicLoadComputed => '未计算血糖负荷（可能是无碳水化合物菜肴）。';

  @override
  String get healthBreakdownNotClassifiedForThis => '此菜肴未分类。';

  @override
  String get healthBreakdownNotComputedForThis => '此菜肴未计算。';

  @override
  String get healthBreakdownNotComputedLikelyNo => '未计算 — 此菜肴中可能没有添加糖。';

  @override
  String get healthBreakdownNovaGroup4Industrial =>
      'NOVA 第 4 组 — 含有乳化剂、高果糖玉米糖浆、人工甜味剂等的工业配方食品。';

  @override
  String healthBreakdownSheetGl(Object gl) {
    return 'GL $gl';
  }

  @override
  String healthBreakdownSheetTriggers(Object fodmapReason) {
    return '触发因素：$fodmapReason';
  }

  @override
  String healthBreakdownSheetValue(Object s) {
    return '$s/10';
  }

  @override
  String get healthBreakdownTapAnyRowFor => '点击任意行以获取完整解释、量表和科普信息。';

  @override
  String get healthBreakdownUltraProcessed => '超加工食品';

  @override
  String get healthConnectConnect => '连接';

  @override
  String get healthConnectConnectHealth => '连接健康数据';

  @override
  String get healthConnectConnectedSuccessfully => '连接成功！';

  @override
  String get healthConnectMaybeLater => '以后再说';

  @override
  String get healthConnectOnboardingACoachThatSees => '一位洞察一切的教练';

  @override
  String get healthConnectOnboardingHealthConnectIsnT =>
      '未安装 Health Connect — 可稍后在设置中连接。';

  @override
  String get healthConnectOnboardingRecoveryAwareWorkouts => '基于恢复情况的锻炼建议';

  @override
  String healthConnectOnboardingScreenConnect(Object _platformName) {
    return '连接 $_platformName';
  }

  @override
  String healthConnectOnboardingScreenConnectSoZealovaCan(
    Object _platformName,
  ) {
    return '连接 $_platformName，以便 Zealova 可以转换您的 ';
  }

  @override
  String get healthConnectOnboardingSleepCoaching => '睡眠指导';

  @override
  String get healthConnectOnboardingUnlockYourAiHealth => '解锁您的 AI 健康教练';

  @override
  String get healthConnectSyncYourHealthData => '同步您的健康数据以获取个性化的健身见解';

  @override
  String get healthDevicesHealthDevices => '健康与设备';

  @override
  String get healthInsightCardSleep => '睡眠';

  @override
  String get healthMetricsCardAbove => '高于';

  @override
  String get healthMetricsCardAverage => '平均值';

  @override
  String get healthMetricsCardAverageToday => '今日平均值';

  @override
  String get healthMetricsCardBelow => '低于';

  @override
  String get healthMetricsCardBloodGlucose => '血糖';

  @override
  String get healthMetricsCardBloodGlucoseReadingsWill => '血糖读数将显示在此处';

  @override
  String get healthMetricsCardConnectAGlucoseMonitor =>
      '通过 Health Connect 连接血糖监测仪';

  @override
  String get healthMetricsCardConnectHealthConnectTo =>
      '连接 Health Connect 以查看您的血糖';

  @override
  String get healthMetricsCardHealthMetrics => '健康指标';

  @override
  String get healthMetricsCardInRange => '在范围内';

  @override
  String get healthMetricsCardInsulinDelivery => '胰岛素输注';

  @override
  String get healthMetricsCardInsulinDeliveryData => '来自已连接设备的胰岛素输送数据将显示在此处';

  @override
  String get healthMetricsCardLoadingHealthData => '正在加载健康数据...';

  @override
  String get healthMetricsCardMax => '最大值';

  @override
  String get healthMetricsCardMgDl => 'mg/dL';

  @override
  String get healthMetricsCardMin => '最小值';

  @override
  String get healthMetricsCardNoBloodGlucoseReadings => '无血糖读数';

  @override
  String get healthMetricsCardNoDataForToday => '今日无数据';

  @override
  String get healthMetricsCardNoGlucoseData => '无血糖数据';

  @override
  String get healthMetricsCardNoInsulinData => '无胰岛素数据';

  @override
  String get healthMetricsCardNotEnoughDataFor => '数据不足，无法生成图表';

  @override
  String healthMetricsCardReadings(Object readingCount) {
    return '$readingCount 次读数';
  }

  @override
  String get healthMetricsCardRecentReadings => '近期读数';

  @override
  String get healthMetricsCardTimeInRange => '目标范围内时间';

  @override
  String get healthMetricsCardUnits => '单位';

  @override
  String get healthSyncAiHealthCoachingIs => 'AI 健康指导已开启';

  @override
  String get healthSyncBodyFat => '体脂率';

  @override
  String get healthSyncCaloriesBurned => '消耗热量';

  @override
  String get healthSyncConnectSamsungHealth => '连接 Samsung Health';

  @override
  String get healthSyncConnected => '已连接';

  @override
  String get healthSyncDataToSync => '待同步数据';

  @override
  String get healthSyncEnable => '启用';

  @override
  String get healthSyncEnableAiHealthCoaching => '启用 AI 健康指导？';

  @override
  String get healthSyncEnableAllDataYou => '启用您想要同步的所有数据（步数、心率、睡眠等）';

  @override
  String get healthSyncEnableSync => '启用同步';

  @override
  String get healthSyncFindHealthConnect => '找到 Health Connect';

  @override
  String get healthSyncGoToSettingsGear => '前往设置（齿轮图标）';

  @override
  String get healthSyncGotIt => '知道了';

  @override
  String get healthSyncGrantPermissions => '授予权限';

  @override
  String get healthSyncHealthConnectIsNot => 'Health Connect 不可用。请从 Play 商店安装。';

  @override
  String get healthSyncHealthSync => '健康同步';

  @override
  String get healthSyncHeartRate => '心率';

  @override
  String get healthSyncHydration => '水分摄入';

  @override
  String get healthSyncInstall => '安装';

  @override
  String get healthSyncMealsNutrition => '饮食与营养';

  @override
  String get healthSyncNotConnected => '未连接';

  @override
  String get healthSyncNotNow => '暂不';

  @override
  String get healthSyncOk => 'OK';

  @override
  String get healthSyncOpen => '打开';

  @override
  String get healthSyncOpenSamsungHealth => '打开 Samsung Health';

  @override
  String get healthSyncReturnHereAndToggle => '返回此处并开启 Health Connect';

  @override
  String get healthSyncScrollDownAndTap => '向下滚动并点击“Health Connect”';

  @override
  String healthSyncSectionConnect(Object appName) {
    return '连接 $appName';
  }

  @override
  String healthSyncSectionConnectedTo(Object platform) {
    return '已连接至 $platform';
  }

  @override
  String healthSyncSectionDisconnect(Object platform) {
    return '断开 $platform 连接？';
  }

  @override
  String healthSyncSectionFindN(Object appName) {
    return '3. 找到 \"$appName\"\n';
  }

  @override
  String healthSyncSectionOpenHealthConnectAnd(Object appName) {
    return '打开 Health Connect 并授予 $appName 权限';
  }

  @override
  String healthSyncSectionSamsungHealthDataSyncs(Object appName) {
    return 'Samsung Health 数据通过 Health Connect 同步至 $appName。请按照以下步骤操作：';
  }

  @override
  String healthSyncSectionSyncedHealthDataPoints(Object length) {
    return '已同步 $length 个健康数据点';
  }

  @override
  String healthSyncSectionYourSamsungHealthData(Object appName) {
    return '设置完成后，您的 Samsung Health 数据将自动出现在 $appName 中。';
  }

  @override
  String get healthSyncSelectDataTypes => '选择数据类型';

  @override
  String get healthSyncSetupGuide => '设置指南';

  @override
  String get healthSyncSleep => '睡眠';

  @override
  String get healthSyncStepsDistance => '步数与距离';

  @override
  String get healthSyncSyncNow => '立即同步';

  @override
  String get healthSyncTurnOnSyncWith => '开启“与 Health Connect 同步”';

  @override
  String get healthSyncUsingSamsungHealth => '正在使用 Samsung Health？';

  @override
  String get healthSyncWeight => '体重';

  @override
  String get healthSyncWriteToHealthApp => '写入健康应用';

  @override
  String get hearInsightButtonNoAudioOutputAvailable => '无可用音频输出 — 请连接耳机或取消静音。';

  @override
  String get hearInsightButtonStop => '停止';

  @override
  String get hearInsightButtonStopInsightPlayback => '停止洞察播放';

  @override
  String get heartRateChartAddRestingHeartRate => '添加静息心率以进行估算';

  @override
  String get heartRateChartAerobic => '有氧';

  @override
  String get heartRateChartAnaerobic => '无氧';

  @override
  String get heartRateChartConnectASmartwatchTo => '连接智能手表以追踪心率';

  @override
  String get heartRateChartEstimatedVo2Max => '预估 VO2 Max';

  @override
  String heartRateChartFatBurnMinutes(num minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分钟燃脂区间',
      one: '1 分钟燃脂区间',
    );
    return '$_temp0';
  }

  @override
  String get heartRateChartFatBurning => '燃脂';

  @override
  String heartRateChartFatCalories(Object calories) {
    return '$calories 燃脂卡路里';
  }

  @override
  String get heartRateChartGotIt => '知道了';

  @override
  String get heartRateChartHeartRate => '心率';

  @override
  String get heartRateChartNoHeartRateData => '无心率数据';

  @override
  String heartRateChartPartZoneLegendItemHeartRateOfMax(
    Object percentageRange,
  ) {
    return '心率：最大心率的 $percentageRange';
  }

  @override
  String heartRateChartPartZoneLegendItemM(
    Object minutes,
    Object percent,
    Object shortLabel,
  ) {
    return '$shortLabel $minutes分钟 ($percent%)';
  }

  @override
  String heartRateChartPartZoneLegendItemZone(Object name) {
    return '$name 区间';
  }

  @override
  String get heartRateChartSummaryAvg => '平均';

  @override
  String heartRateChartSummaryBpm(Object value) {
    return '$value bpm';
  }

  @override
  String get heartRateChartSummaryMax => '最大';

  @override
  String get heartRateChartSummaryMin => '最小';

  @override
  String get heartRateChartSummaryNoDataRecorded => '无记录数据';

  @override
  String get heartRateChartSummaryPeak => '峰值';

  @override
  String heartRateChartSummaryReadings(Object count) {
    return '$count 次读数';
  }

  @override
  String get heartRateChartTrainingEffect => '训练效果';

  @override
  String heartRateChartValue(Object label, Object value) {
    return '$label：$value';
  }

  @override
  String get heartRateChartWearYourWatchDuring => '在锻炼时佩戴手表以追踪心率';

  @override
  String get heartRateChartZoneBreakdown => '区间细分';

  @override
  String get heartRateDisplayCalculatingZone => '正在计算区间...';

  @override
  String get heartRateDisplayGotIt => '知道了';

  @override
  String heartRateDisplayValue(Object label) {
    return '$label：';
  }

  @override
  String get heartRateDisplayWaitingForWatch => '正在等待手表...';

  @override
  String heartRateDisplayZone(Object name) {
    return '$name 区间';
  }

  @override
  String heartRateDisplayZone2(Object name) {
    return '$name 区间';
  }

  @override
  String get heroActionCardActive => '活跃中';

  @override
  String get heroActionCardCancel => '取消';

  @override
  String get heroActionCardCustom => '自定义';

  @override
  String get heroActionCardCustomAmount => '自定义量';

  @override
  String get heroActionCardEnd => '结束';

  @override
  String get heroActionCardEnter1To5000Ml => '输入 1–5000 毫升';

  @override
  String get heroActionCardFailedToLogWater => '记录饮水失败';

  @override
  String get heroActionCardFastEndedSuccessfully => '断食已成功结束';

  @override
  String get heroActionCardFasting => '断食';

  @override
  String get heroActionCardFastingLabel => '断食';

  @override
  String get heroActionCardLog => '记录';

  @override
  String heroActionCardLogMl(Object ml) {
    return '记录 $ml 毫升';
  }

  @override
  String get heroActionCardLogWater => '记录饮水';

  @override
  String get heroActionCardOpenHydrationTracker => '打开饮水追踪器';

  @override
  String get heroActionCardOrPickAPreset => '或选择预设：';

  @override
  String get heroActionCardPleaseLogIn => '请登录';

  @override
  String get heroActionCardPresetBigBottle => '大瓶';

  @override
  String get heroActionCardPresetGlass => '水杯';

  @override
  String get heroActionCardPresetLargeJug => '大水壶';

  @override
  String get heroActionCardPresetMouthful => '一大口';

  @override
  String get heroActionCardPresetSip => '一小口';

  @override
  String get heroActionCardPresetSmallCup => '小杯';

  @override
  String get heroActionCardPresetSmallSip => '抿一口';

  @override
  String get heroActionCardPresetSportsBottle => '运动水壶';

  @override
  String get heroActionCardPresetTallGlass => '高杯';

  @override
  String get heroActionCardPresetXlJug => '超大水壶';

  @override
  String get heroActionCardSelectAmountToLog => '选择要记录的量';

  @override
  String get heroActionCardSipToXlJug => '从一小口到超大水壶';

  @override
  String get heroActionCardTakeProgressPhoto => '拍摄进度照片以记录你的蜕变';

  @override
  String get heroActionCardTrackYourProgress => '追踪进度';

  @override
  String get heroActionCardUploadingPhoto => '正在上传照片…';

  @override
  String get heroActionCardWaterLabel => '饮水';

  @override
  String heroActionCardWaterLogged(Object ml) {
    return '已记录 $ml 毫升';
  }

  @override
  String get heroFastingCardAutophagy => '细胞自噬';

  @override
  String get heroFastingCardBurnFat => '燃脂';

  @override
  String get heroFastingCardEndFast => '结束断食';

  @override
  String get heroFastingCardEnergy => '能量';

  @override
  String get heroFastingCardFasting => '断食中';

  @override
  String heroFastingCardHM(Object hours, Object mins) {
    return '$hours 小时 $mins 分';
  }

  @override
  String get heroFastingCardNotFasting => '未断食';

  @override
  String heroFastingCardOfHGoal(Object targetHours) {
    return '目标 $targetHours 小时';
  }

  @override
  String heroFastingCardProtocol(Object defaultProtocol) {
    return '$defaultProtocol 方案';
  }

  @override
  String get heroFastingCardReadyToFast => '准备好断食了吗？';

  @override
  String get heroFastingCardStartFast => '开始断食';

  @override
  String get heroFastingCardViewDetails => '查看详情';

  @override
  String get heroNutritionCardCalLeft => '剩余卡路里';

  @override
  String get heroNutritionCardCalOver => '超出卡路里';

  @override
  String get heroNutritionCardCarbs => '碳水化合物';

  @override
  String get heroNutritionCardFat => '脂肪';

  @override
  String heroNutritionCardGG(Object consumed, Object target) {
    return '${consumed}g / ${target}g';
  }

  @override
  String heroNutritionCardKcal(Object calorieTarget, Object caloriesConsumed) {
    return '$caloriesConsumed / $calorieTarget kcal';
  }

  @override
  String get heroNutritionCardLogMeal => '记录饮食';

  @override
  String get heroNutritionCardProtein => '蛋白质';

  @override
  String heroNutritionCardValue(Object caloriesRemaining) {
    return '+$caloriesRemaining';
  }

  @override
  String get heroNutritionCardViewDetails => '查看详情';

  @override
  String get heroWorkoutCardAddExercises => '添加练习';

  @override
  String get heroWorkoutCardAskCoach => '咨询教练';

  @override
  String get heroWorkoutCardBodyweightVariant => '自重变式';

  @override
  String get heroWorkoutCardCouldNotDismissWorkout => '无法移除锻炼';

  @override
  String get heroWorkoutCardCouldNotMarkWorkout => '无法将锻炼标记为完成';

  @override
  String get heroWorkoutCardCouldNotSkipWorkout => '无法跳过锻炼';

  @override
  String get heroWorkoutCardCouldNotUndoCompletion => '无法撤销完成状态';

  @override
  String get heroWorkoutCardCouldnTRegenerateWorkout => '无法重新生成锻炼。请重试。';

  @override
  String get heroWorkoutCardDelayUntilFastEnds => '延迟至断食结束';

  @override
  String get heroWorkoutCardDismissQuick => '快速移除';

  @override
  String get heroWorkoutCardDismissQuickWorkout => '移除快速锻炼？';

  @override
  String get heroWorkoutCardDismissedOfflineWillSync => '已离线移除 — 将在联网后同步';

  @override
  String get heroWorkoutCardDoToday => '今日任务';

  @override
  String get heroWorkoutCardExerciseAdded => '练习已添加！';

  @override
  String heroWorkoutCardExercises(Object exerciseCount) {
    return '$exerciseCount 个动作';
  }

  @override
  String heroWorkoutCardExtExercises(
    Object exerciseCount,
    Object formattedDurationShort,
  ) {
    return '$formattedDurationShort • $exerciseCount 个动作';
  }

  @override
  String heroWorkoutCardExtMoreExercises(Object exercises) {
    return '+$exercises 个更多动作';
  }

  @override
  String heroWorkoutCardExtSets(Object e) {
    return '$e 组';
  }

  @override
  String get heroWorkoutCardGlanceWorkout => '快速浏览锻炼';

  @override
  String get heroWorkoutCardLoadingYourWorkout => '正在加载您的锻炼...';

  @override
  String get heroWorkoutCardLogASnack => '记录零食';

  @override
  String get heroWorkoutCardLogPostWorkoutMeal => '记录练后餐';

  @override
  String get heroWorkoutCardMarkAsDone => '标记为已完成？';

  @override
  String get heroWorkoutCardMarkAsDone2 => '标记为已完成';

  @override
  String get heroWorkoutCardMarkDone => '标记完成';

  @override
  String get heroWorkoutCardMarkedAsARest => '已标记为休息日。好好恢复。';

  @override
  String get heroWorkoutCardMissedWorkout => '错过的训练';

  @override
  String heroWorkoutCardModesVariantComingWithThe(Object which) {
    return '$which 变体即将随后端变体生成器推出';
  }

  @override
  String get heroWorkoutCardMoveToToday => '移至今天';

  @override
  String get heroWorkoutCardNothingToShareYet => '暂无内容可分享 — 请先记录一次训练';

  @override
  String heroWorkoutCardPartCompletedWorkoutHeroCardExercises(
    Object exerciseCount,
  ) {
    return '$exerciseCount 个动作';
  }

  @override
  String heroWorkoutCardPartCompletedWorkoutHeroCardMin(
    Object bestDurationMinutes,
  ) {
    return '$bestDurationMinutes 分钟';
  }

  @override
  String get heroWorkoutCardPreview => '预览';

  @override
  String get heroWorkoutCardQuick => '快速';

  @override
  String get heroWorkoutCardQuickWorkout => '快速训练';

  @override
  String get heroWorkoutCardQuickWorkoutDismissed => '已取消快速训练';

  @override
  String get heroWorkoutCardRegenerate => '重新生成';

  @override
  String get heroWorkoutCardRegenerateWorkout => '重新生成训练';

  @override
  String get heroWorkoutCardRepeat => '重复';

  @override
  String get heroWorkoutCardResume => '继续';

  @override
  String get heroWorkoutCardResumeNow => '立即继续';

  @override
  String get heroWorkoutCardSeeTomorrowSPlan => '查看明日计划';

  @override
  String get heroWorkoutCardShareToSocial => '分享到社交平台';

  @override
  String get heroWorkoutCardSkipWorkout => '跳过训练？';

  @override
  String get heroWorkoutCardStartAnyway => '仍然开始';

  @override
  String get heroWorkoutCardStartAsPlanned => '按计划开始';

  @override
  String get heroWorkoutCardStartAsPlanned2 => '按计划开始';

  @override
  String get heroWorkoutCardStartFasted => '空腹开始';

  @override
  String get heroWorkoutCardStartLighter => '开始（轻量）';

  @override
  String get heroWorkoutCardSummary => '总结';

  @override
  String get heroWorkoutCardSwitchGymProfile => '切换健身房配置';

  @override
  String get heroWorkoutCardSwitchToLighter => '切换为轻量';

  @override
  String get heroWorkoutCardSwitchToModerate => '切换为中等';

  @override
  String get heroWorkoutCardTakeRest => '休息';

  @override
  String get heroWorkoutCardTapToRetry => '点击重试';

  @override
  String get heroWorkoutCardThisMayTakeA => '这可能需要一点时间';

  @override
  String get heroWorkoutCardThisWillMarkThe => '这将把该训练标记为未完成。';

  @override
  String get heroWorkoutCardThisWorkoutWillBe => '该训练将被标记为已跳过。';

  @override
  String get heroWorkoutCardTodaySWorkoutComplete => '今日训练已完成！';

  @override
  String get heroWorkoutCardUndo => '撤销';

  @override
  String get heroWorkoutCardUndoCompletion => '撤销完成状态？';

  @override
  String get heroWorkoutCardViewDetails => '查看详情';

  @override
  String get heroWorkoutCardViewWorkout => '查看训练';

  @override
  String heroWorkoutCardWorkout(Object id) {
    return '/workout/$id';
  }

  @override
  String get heroWorkoutCardWorkoutIsNotReady => '训练尚未准备好。请尝试重新生成。';

  @override
  String get heroWorkoutCardWorkoutMarkedAsDone => '训练已标记为完成！';

  @override
  String get heroWorkoutCardWorkoutRegenerated => '训练已重新生成！';

  @override
  String get heroWorkoutCardWorkoutSkipped => '训练已跳过';

  @override
  String get heroWorkoutCardWorkoutUnmarked => '训练已取消标记';

  @override
  String get heroWorkoutCardYouLlLoseThis => '你将丢失此快速训练。其中记录的任何组数都将被丢弃。继续吗？';

  @override
  String get heroWorkoutCarouselAllDoneForThis => '本周任务已全部完成！';

  @override
  String get heroWorkoutCarouselCouldNotLoadWorkouts => '无法加载训练';

  @override
  String get heroWorkoutCarouselGeneratingWorkout => '正在生成训练...';

  @override
  String get heroWorkoutCarouselNoWorkoutYet => '暂无训练';

  @override
  String get heroWorkoutCarouselRestUpForNext => '为下周好好休息';

  @override
  String get heroWorkoutCarouselSetYourWorkoutDays => '设置你的训练日';

  @override
  String get heroWorkoutCarouselSettingUpYourWorkout => '正在设置你的训练...';

  @override
  String get heroWorkoutCarouselTapToSetUp => '点击在设置中进行配置';

  @override
  String get heroWorkoutCarouselToday => '今天';

  @override
  String holdToConfirmButtonPressAndHoldTo(Object label) {
    return '$label。长按以确认。';
  }

  @override
  String get homeApply => '应用';

  @override
  String get homeCustomizeYourHomeLayout => '在此自定义你的主页布局、切换健身房配置并追踪你的等级。';

  @override
  String get homeDailyStepsGoal => '每日步数目标';

  @override
  String get homeDefaultLayoutRestored => '已恢复默认布局！';

  @override
  String get homeEmptyAchievements_v1 => '暂无成就。坚持训练即可解锁。';

  @override
  String get homeEmptyAchievements_v2 => '达成里程碑即可解锁成就。继续加油。';

  @override
  String get homeEmptyAchievements_v3 => '暂无解锁成就。你离第一个成就比想象中更近。';

  @override
  String get homeEmptyAchievements_v4 => '开始记录锻炼，成就随之而来。';

  @override
  String get homeEmptyChallenges_v1 => '暂无挑战。浏览并选择一个开始吧。';

  @override
  String get homeEmptyChallenges_v2 => '挑战是建立动力的好方法。加入一个试试。';

  @override
  String get homeEmptyChallenges_v3 => '暂无正在进行的挑战。找到适合你水平的挑战吧。';

  @override
  String get homeEmptyChallenges_v4 => '没有挑战？这里有一些很棒的挑战在等着你。';

  @override
  String get homeEmptyChat_v1 => '暂无消息。随时向你的教练提问。';

  @override
  String get homeEmptyChat_v2 => '你的教练已准备就绪。有什么想聊的吗？';

  @override
  String get homeEmptyChat_v3 => '聊天记录为空。提出问题或分享你的感受吧。';

  @override
  String get homeEmptyChat_v4 => '第一次对话从这里开始。打个招呼吧。';

  @override
  String get homeEmptyCustomExercises_v1 => '暂无自定义动作。创建你自己的动作并将其添加到任何锻炼中。';

  @override
  String get homeEmptyCustomExercises_v2 => '自定义动作库为空。创建你的第一个动作吧。';

  @override
  String get homeEmptyCustomExercises_v3 => '这里什么都没有。添加一个主库中没有的动作。';

  @override
  String get homeEmptyCustomExercises_v4 => '暂无自定义动作。创建一个，它就会出现在搜索结果中。';

  @override
  String get homeEmptyFasting_v1 => '暂无断食记录。选择一个方案开始吧。';

  @override
  String get homeEmptyFasting_v2 => '断食追踪器为空。准备好后就开始一次记录吧。';

  @override
  String get homeEmptyFasting_v3 => '暂无记录。选择一个时间窗口并开始计时。';

  @override
  String get homeEmptyFasting_v4 => '暂无断食数据。点击开始你的第一次记录。';

  @override
  String get homeEmptyFavorites_v1 => '暂无收藏。点击锻炼或动作旁的心形图标即可保存。';

  @override
  String get homeEmptyFavorites_v2 => '这里什么都没有。找到你喜欢的并保存下来吧。';

  @override
  String get homeEmptyFavorites_v3 => '你的收藏列表正虚位以待。去探索并添加书签吧。';

  @override
  String get homeEmptyFavorites_v4 => '点击任意锻炼上的心形图标，即可将其添加到此处。';

  @override
  String get homeEmptyFriends_v1 => '暂无好友。邀请朋友一起训练吧。';

  @override
  String get homeEmptyFriends_v2 => '好友列表为空。相互监督非常有效。';

  @override
  String get homeEmptyFriends_v3 => '这里还没人。分享你的链接来扩大你的圈子吧。';

  @override
  String get homeEmptyFriends_v4 => '暂无好友。与他人一起锻炼很有帮助——添加一个吧。';

  @override
  String get homeEmptyGymProfiles_v1 => '暂无健身房配置。添加你的设备，让锻炼更符合你的环境。';

  @override
  String get homeEmptyGymProfiles_v2 => '健身房配置为空。告诉我们一次你的设备，我们每次都会用到。';

  @override
  String get homeEmptyGymProfiles_v3 => '暂无保存的设置。添加健身房配置以获取量身定制的锻炼。';

  @override
  String get homeEmptyGymProfiles_v4 => '配置为空。配置你的设备，剩下的交给AI。';

  @override
  String get homeEmptyHabits_v1 => '暂无习惯设置。添加一个简单的小习惯即可开始。';

  @override
  String get homeEmptyHabits_v2 => '习惯追踪器为空。养成一个习惯，让它成为自动行为。';

  @override
  String get homeEmptyHabits_v3 => '暂无追踪记录。从每天都能完成的一个习惯开始吧。';

  @override
  String get homeEmptyHabits_v4 => '暂无活跃习惯。每日的小行动会汇聚成巨大的成果。';

  @override
  String get homeEmptyHistory_v1 => '暂无训练记录。完成一次训练来开启你的历史记录。';

  @override
  String get homeEmptyHistory_v2 => '你的历史记录还是空白的——完成第一次训练后就会改变。';

  @override
  String get homeEmptyHistory_v3 => '没有过往训练。完成一次训练，它就会显示在这里。';

  @override
  String get homeEmptyHistory_v4 => '历史记录为空，说明你才刚刚开始。去记录一下吧。';

  @override
  String get homeEmptyJournal_v1 => '暂无日志记录。写下今天的收获，无论多小。';

  @override
  String get homeEmptyJournal_v2 => '日志为空。记录你的旅程——你会为此感到高兴的。';

  @override
  String get homeEmptyJournal_v3 => '暂无书写内容。从这里开始你的第一篇记录。';

  @override
  String get homeEmptyJournal_v4 => '暂无记录。花2分钟写点真诚的内容吧。';

  @override
  String get homeEmptyMeasurements_v1 => '暂无测量数据。添加基准数据以追踪进度。';

  @override
  String get homeEmptyMeasurements_v2 => '暂无追踪记录。从你当前的数值开始吧。';

  @override
  String get homeEmptyMeasurements_v3 => '暂无身体数据。记录测量值以查看趋势。';

  @override
  String get homeEmptyMeasurements_v4 => '测量数据为空。添加一个数据，给自己设定一个超越的目标。';

  @override
  String get homeEmptyMood_v1 => '暂无心情记录。今天感觉如何？';

  @override
  String get homeEmptyMood_v2 => '心情追踪为空。在下次锻炼后记录你的感受吧。';

  @override
  String get homeEmptyMood_v3 => '暂无记录。心情模式有助于预测你状态最好的训练日。';

  @override
  String get homeEmptyMood_v4 => '暂无心情数据。点击添加今日记录。';

  @override
  String get homeEmptyNutrition_v1 => '暂无记录。拍张照片即可开始。';

  @override
  String get homeEmptyNutrition_v2 => '你的饮食记录还是空白的。第一餐吃了什么？';

  @override
  String get homeEmptyNutrition_v3 => '今天没有记录饮食。记录一餐来看看你的宏量营养素。';

  @override
  String get homeEmptyNutrition_v4 => '在吃东西吗？拍张照，剩下的交给我们来计算。';

  @override
  String get homeEmptyPhotos_v1 => '暂无进度照片。今天拍下第一张吧。';

  @override
  String get homeEmptyPhotos_v2 => '照片能讲述数字无法表达的故事。现在就拍一张吧。';

  @override
  String get homeEmptyPhotos_v3 => '这里还什么都没有。开启你的视觉进度日志吧。';

  @override
  String get homeEmptyPhotos_v4 => '暂无照片记录。添加一张以追踪随时间变化的视觉效果。';

  @override
  String get homeEmptyPlans_v1 => '暂无计划。让AI根据你的日程和目标为你制定一个。';

  @override
  String get homeEmptyPlans_v2 => '计划为空。生成个性化训练计划以开始吧。';

  @override
  String get homeEmptyPlans_v3 => '暂无设置。创建一个计划并坚持执行。';

  @override
  String get homeEmptyPlans_v4 => '暂无活动计划。开始一个计划，不再为每天做什么而纠结。';

  @override
  String get homeEmptyPrograms_v1 => '暂无活动计划。浏览计划以找到你的下一个目标。';

  @override
  String get homeEmptyPrograms_v2 => '计划能为你的训练提供结构。选择一个开始吧。';

  @override
  String get homeEmptyPrograms_v3 => '暂无正在进行的计划。开始一个计划以解锁每周安排。';

  @override
  String get homeEmptyPrograms_v4 => '暂无活动计划。选择一个符合你当前水平的计划。';

  @override
  String get homeEmptyRecipes_v1 => '暂无食谱。浏览库或咨询你的教练。';

  @override
  String get homeEmptyRecipes_v2 => '食谱收藏为空。添加一些你喜欢的餐点吧。';

  @override
  String get homeEmptyRecipes_v3 => '这里什么都没有。去探索并保存你喜欢的食谱吧。';

  @override
  String get homeEmptyRecipes_v4 => '食谱库为空。点击发现新餐点。';

  @override
  String get homeEmptyRecovery_v1 => '暂无恢复数据。记录睡眠、HRV或酸痛感以获取评分。';

  @override
  String get homeEmptyRecovery_v2 => '恢复追踪为空。连接可穿戴设备或手动记录。';

  @override
  String get homeEmptyRecovery_v3 => '暂无追踪记录。恢复数据有助于你更科学地训练。';

  @override
  String get homeEmptyRecovery_v4 => '恢复数据为空。添加今日数据以保护你的下一次训练。';

  @override
  String get homeEmptyScores_v1 => '暂无评分。记录一次锻炼以生成你的第一个就绪评分。';

  @override
  String get homeEmptyScores_v2 => '评分会在你开始记录数据后出现。坚持下去。';

  @override
  String get homeEmptyScores_v3 => '暂无评分。完成一次训练以查看你的第一个评级。';

  @override
  String get homeEmptyScores_v4 => '评分为空。更多数据意味着更精准的洞察——开始记录吧。';

  @override
  String get homeEmptySleep_v1 => '暂无睡眠数据。连接可穿戴设备或手动记录。';

  @override
  String get homeEmptySleep_v2 => '睡眠追踪为空。了解睡眠是恢复的开始。';

  @override
  String get homeEmptySleep_v3 => '暂无睡眠记录。添加昨晚的数据以查看恢复趋势。';

  @override
  String get homeEmptySleep_v4 => '缺少睡眠数据。记录下来，我们将把它纳入你的恢复评分。';

  @override
  String get homeEmptyTrends_v1 => '暂无趋势。连续记录7天以查看模式。';

  @override
  String get homeEmptyTrends_v2 => '趋势需要数据。继续记录，图表就会自动填充。';

  @override
  String get homeEmptyTrends_v3 => '暂无内容。追踪一周后再来看看吧。';

  @override
  String get homeEmptyTrends_v4 => '趋势视图为空。坚持记录即可解锁此功能——开始每日记录吧。';

  @override
  String get homeEmptyVitals_v1 => '暂无生命体征记录。连接可穿戴设备或手动输入。';

  @override
  String get homeEmptyVitals_v2 => '生命体征追踪为空。添加一个数据点开始吧。';

  @override
  String get homeEmptyVitals_v3 => '这里什么都没有。记录静息心率、HRV或血压。';

  @override
  String get homeEmptyVitals_v4 => '暂无生命体征数据。连接您的可穿戴设备以进行自动同步。';

  @override
  String get homeEmptyWater_v1 => '今天还没记录饮水量。喝下第一杯吧。';

  @override
  String get homeEmptyWater_v2 => '补水追踪为空。记录你的第一杯水。';

  @override
  String get homeEmptyWater_v3 => '暂无记录。开始记录你今天的饮水量吧。';

  @override
  String get homeEmptyWater_v4 => '暂无饮水记录。在口渴前补水——现在就记录吧。';

  @override
  String get homeEmptyWorkout_v1 => '暂无训练记录——点击以生成今日课程。';

  @override
  String get homeEmptyWorkout_v2 => '休息日？还是准备好运动了？由你决定。';

  @override
  String get homeEmptyWorkout_v3 => '处于计划间隙——开启新计划以重回正轨。';

  @override
  String get homeEmptyWorkout_v4 => '暂无计划。让AI根据你的目标为你定制一个。';

  @override
  String get homeFromHealthConnect => ') 来自 Health Connect';

  @override
  String homeGreetingAfternoon_v1(Object name) {
    return '下午能量满满，$name！';
  }

  @override
  String homeGreetingAfternoon_v2(Object name) {
    return '嗨 $name，该活动一下了吗？';
  }

  @override
  String homeGreetingAfternoon_v3(Object name) {
    return '拉伸一下吗，$name？';
  }

  @override
  String homeGreetingAfternoon_v4(Object name) {
    return '今天过得怎么样，$name？';
  }

  @override
  String homeGreetingAfternoon_v5(Object name) {
    return '下午好，$name';
  }

  @override
  String homeGreetingEvening_v1(Object name) {
    return '放松时间，$name';
  }

  @override
  String homeGreetingEvening_v2(Object name) {
    return '晚上好，$name';
  }

  @override
  String homeGreetingEvening_v3(Object name) {
    return '以强劲的状态结束这一天，$name';
  }

  @override
  String homeGreetingEvening_v4(Object name) {
    return '最后的几组动作，$name？';
  }

  @override
  String homeGreetingEvening_v5(Object name) {
    return '晚间复盘，$name';
  }

  @override
  String homeGreetingMidday_v1(Object name) {
    return '午休时间到了吗，$name？';
  }

  @override
  String homeGreetingMidday_v2(Object name) {
    return '中午打卡，$name';
  }

  @override
  String homeGreetingMidday_v3(Object name) {
    return '嘿 $name，已经完成一半了';
  }

  @override
  String homeGreetingMidday_v4(Object name) {
    return '动力十足，$name？';
  }

  @override
  String homeGreetingMidday_v5(Object name) {
    return '今天表现很棒，$name';
  }

  @override
  String homeGreetingMorning_v1(Object name) {
    return '早上好，$name！';
  }

  @override
  String homeGreetingMorning_v2(Object name) {
    return '嘿 $name，准备好大干一场了吗？';
  }

  @override
  String homeGreetingMorning_v3(Object name) {
    return '早上好，$name';
  }

  @override
  String homeGreetingMorning_v4(Object name) {
    return '起这么早，$name？';
  }

  @override
  String homeGreetingMorning_v5(Object name) {
    return '欢迎回来，$name';
  }

  @override
  String get homeLogMeal => '记录餐食';

  @override
  String get homeMore => '更多';

  @override
  String get homeMySpaceApply => '应用';

  @override
  String get homeMySpaceCurrentLayout => '● 当前布局';

  @override
  String get homeMySpaceMySpace => '我的空间';

  @override
  String get homeMySpaceReset => '重置';

  @override
  String homeMySpaceScreenLayoutApplied(Object name) {
    return '已应用$name布局';
  }

  @override
  String get homeMySpaceStartFromAReady => '从现成的布局开始，然后在“自定义”中进行微调。';

  @override
  String get homeQuickActions => '快捷操作';

  @override
  String get homeQuickWorkoutGenerationWeig => '快速生成训练、记录重量、记录饮食等。';

  @override
  String get homeReadinessCardCheckIn => '签到';

  @override
  String homeReadinessCardEstimated(Object label) {
    return '预计：$label';
  }

  @override
  String get homeReadinessCardHowAreYouFeeling => '你感觉如何？';

  @override
  String get homeReadinessCardTodaySReadiness => '今日准备状态';

  @override
  String get homeReset => '重置';

  @override
  String get homeResetToDefault => '重置为默认？';

  @override
  String get homeScanFood => '扫描食物';

  @override
  String get homeScanMealsWithYour => '使用相机扫描餐食。轻松追踪宏量营养素。';

  @override
  String get homeScreenApply => '应用';

  @override
  String homeScreenApplyPreset(Object name) {
    return '应用“$name”？';
  }

  @override
  String homeScreenApplyPresetBody(Object name) {
    return '这将使用“$name”预设替换你当前的布局。';
  }

  @override
  String get homeScreenCancel => '取消';

  @override
  String get homeScreenDailyStepsGoal => '每日步数目标';

  @override
  String get homeScreenDefaultRestored => '已恢复默认布局';

  @override
  String homeScreenImportedWorkouts(Object count) {
    return '已导入 $count 次训练';
  }

  @override
  String homeScreenPresetApplied(Object name) {
    return '已应用“$name”';
  }

  @override
  String get homeScreenReset => '重置';

  @override
  String get homeScreenResetToDefault => '恢复默认设置？';

  @override
  String get homeScreenResetToDefaultBody => '这将把你的主屏幕恢复为默认布局。';

  @override
  String get homeScreenTourCarouselDesc => '滑动查看你的训练计划。点击开始！';

  @override
  String get homeScreenTourCarouselTitle => '今日训练';

  @override
  String get homeScreenTourNutritionDesc => '追踪你的宏量营养素和日常营养摄入';

  @override
  String get homeScreenTourNutritionTitle => '营养标签页';

  @override
  String get homeScreenTourProfileDesc => '查看你的进度和设置';

  @override
  String get homeScreenTourProfileTitle => '个人资料标签页';

  @override
  String get homeScreenTourQuicklogDesc => '快速记录饮食、饮水和训练';

  @override
  String get homeScreenTourQuicklogTitle => '快速记录';

  @override
  String get homeScreenTourTopbarDesc => '点击查看并编辑你的健身资料';

  @override
  String get homeScreenTourTopbarTitle => '个人资料';

  @override
  String get homeScreenTourWorkoutDesc => '访问你的完整训练计划和历史记录';

  @override
  String get homeScreenTourWorkoutTitle => '训练标签页';

  @override
  String homeScreenUi1MoreTiles(Object tiles) {
    return '+$tiles 个更多磁贴';
  }

  @override
  String homeScreenUi1Workouts(Object length) {
    return '$length 次训练';
  }

  @override
  String homeScreenUi2TryAgainInS(Object cooldownLeft) {
    return '$cooldownLeft 秒后重试';
  }

  @override
  String homeScreenUi3Workouts(Object length) {
    return '$length 次训练';
  }

  @override
  String get homeScreenUiAddTile => '添加磁贴';

  @override
  String get homeScreenUiChooseAPresetLayout => '选择一个符合你目标的预设布局。应用后你还可以进一步自定义。';

  @override
  String get homeScreenUiCustomizeYourDashboard => '自定义你的仪表板';

  @override
  String get homeScreenUiDiscoverLayouts => '发现布局';

  @override
  String get homeScreenUiDragToReorderTap => '拖动以重新排序 • 点击尺寸以调整大小 • 点击眼睛以隐藏';

  @override
  String get homeScreenUiGotIt => '知道了！';

  @override
  String get homeScreenUiResetToDefault => '重置为默认';

  @override
  String homeScreenUiRestoreTheOriginalLayout(Object appName) {
    return '恢复 $appName 原始布局';
  }

  @override
  String get homeScreenUiUpcoming => '即将到来';

  @override
  String get homeScreenUiYourProgress => '你的进度';

  @override
  String get homeScreenUiYourWeek => '本周概览';

  @override
  String get homeStartWorkout => '开始训练';

  @override
  String get homeStreak100Day_v1 => '100天。你成就了真正的自我。';

  @override
  String get homeStreak100Day_v2 => '三位数连胜。你从不缺席。';

  @override
  String get homeStreak100Day_v3 => '100天连胜！这是精英级别的专注力。';

  @override
  String get homeStreak100Day_v4 => '100天达成。势不可挡。';

  @override
  String get homeStreak30Day_v1 => '30天。整整一个月的坚持。';

  @override
  String get homeStreak30Day_v2 => '一个月了。这已经成为一种习惯。';

  @override
  String get homeStreak30Day_v3 => '30天连胜！大多数人早就放弃了——但你没有。';

  @override
  String get homeStreak30Day_v4 => '一个月的自律。这非常难得。';

  @override
  String get homeStreak365Day_v1 => '365天。整整一年的坚持。';

  @override
  String get homeStreak365Day_v2 => '一年连胜。传奇。';

  @override
  String get homeStreak365Day_v3 => '连续365天。完整的一年。';

  @override
  String get homeStreak365Day_v4 => '一年了。你重新定义了什么是自律。';

  @override
  String get homeStreak7Day_v1 => '连续7天——状态已锁定！';

  @override
  String get homeStreak7Day_v2 => '7天了。你势不可挡。';

  @override
  String get homeStreak7Day_v3 => '一周连胜！再接再厉。';

  @override
  String get homeStreak7Day_v4 => '连续7天。保持这股热劲。';

  @override
  String get homeSwipeToSeeThis => '滑动查看本周计划。点击开始今日训练。';

  @override
  String get homeThisWillRestoreThe => '这将恢复为极简布局（应用默认设置）。你当前的自定义设置将被替换。';

  @override
  String get homeTimelineCouldnTLoadYour => '无法加载你的时间轴';

  @override
  String homeTimelineElapsed(Object elapsedTimeString) {
    return '已进行 $elapsedTimeString';
  }

  @override
  String get homeTimelineFastingWindow => '断食窗口';

  @override
  String get homeTimelineGeneratingYourWorkout => '正在生成你的训练计划…';

  @override
  String get homeTimelineHangTightAlmostReady => '请稍候，马上就好';

  @override
  String homeTimelineLeft(Object remainingTimeString) {
    return '剩余 $remainingTimeString · ';
  }

  @override
  String get homeTimelineLogYourMeals => '记录饮食';

  @override
  String get homeTimelineNothingLoggedOrPlanned => '暂无记录或计划';

  @override
  String get homeTimelineNothingLoggedYetToday => '今天暂无记录';

  @override
  String get homeTimelineNothingPlannedForThis => '今日暂无计划';

  @override
  String homeTimelineProtocolNotStarted(Object defaultProtocol) {
    return '$defaultProtocol 方案 · 未开始';
  }

  @override
  String get homeTip_ankle_mobility => '踝关节灵活性受限会迫使深蹲时产生代偿。每天进行拉伸和训练。';

  @override
  String get homeTip_breathing_during_lifts => '发力时呼气，放松时吸气。全程保持核心收紧。';

  @override
  String get homeTip_caffeine_timing => '咖啡因在饮用后 45–60 分钟达到峰值。请在训练前把握好时间。';

  @override
  String get homeTip_cardio_and_strength => '只要饮食充足且不过度训练，有氧运动不会抵消增肌效果。';

  @override
  String get homeTip_cold_exposure => '冷水澡或冰浴可能会抑制训练后的炎症。请在训练后进行，而不是训练前。';

  @override
  String get homeTip_compound_before_isolation => '精力充沛时先做大重量复合动作。孤立动作放在最后。';

  @override
  String get homeTip_compound_lifts => '深蹲、铰链、推、拉、负重行走。掌握这五个动作，你就涵盖了 80% 的训练。';

  @override
  String get homeTip_consistency_beats_perfection =>
      '以 70% 的状态坚持训练，胜过因为无法达到 100% 而直接放弃。';

  @override
  String get homeTip_core_in_every_lift => '核心在每个复合动作中都在发力。您不需要专门做 20 分钟的卷腹。';

  @override
  String get homeTip_creatine_basics => '一水肌酸是运动科学中研究最充分的补剂。每天 3–5g 即可见效。';

  @override
  String get homeTip_deload_week => '每 4–6 周将训练量减少 40%。您的身体会以更强的状态回归。';

  @override
  String get homeTip_eat_before_training =>
      '空腹训练可行，但大多数人在训练前 60–90 分钟进食少量餐点表现更好。';

  @override
  String get homeTip_eccentric_focus => '离心阶段（下放过程）是肌肉损伤（及生长）发生最多的阶段。控制好它。';

  @override
  String get homeTip_fiber_and_gut => '每天 30g 膳食纤维可保持能量稳定并减少食欲。大多数人只摄入 15g。';

  @override
  String get homeTip_form_over_weight => '动作不规范的虚荣重量只会导致受伤，而非增长肌肉。先练好动作。';

  @override
  String get homeTip_grip_strength => '握力是预测长寿的最佳指标之一。多加训练。';

  @override
  String get homeTip_hydration_basics => '每天饮水量（盎司）应达到体重的一半。训练日需额外补充。';

  @override
  String get homeTip_meal_timing_simple => '多吃天然食物，保证蛋白质摄入，睡眠充足。其余的大多是干扰信息。';

  @override
  String get homeTip_mind_muscle_connection => '放慢速度，感受肌肉发力。这不仅仅是移动重量。';

  @override
  String get homeTip_mobility_daily => '每天 10 分钟的灵活性训练胜过每周一次 60 分钟的训练。';

  @override
  String get homeTip_no_junk_volume => '10 组高质量、专注的训练胜过 20 组敷衍的训练。质量重于数量。';

  @override
  String get homeTip_omega3_basics => '每天 1–2g EPA+DHA 可减少炎症并支持关节健康。';

  @override
  String get homeTip_periodization => '随时间调整重复次数和强度。线性进步不会永远持续。';

  @override
  String get homeTip_progressive_overload => '每周增加一点重量或多做一次重复。这就是进步的方式。';

  @override
  String get homeTip_protein_per_meal => '目标是每餐摄入 30–40g 蛋白质。分散摄入比一次性大量摄入效果更好。';

  @override
  String get homeTip_protein_sources_vary =>
      '混合蛋白质来源——鸡肉、鸡蛋、希腊酸奶、豆类。多样化摄入可涵盖所有氨基酸。';

  @override
  String get homeTip_rate_of_perceived_exertion =>
      '给您的努力程度打分 1–10。大多数训练保持在 7–8 分是最佳区间。';

  @override
  String get homeTip_rest_days_grow_muscle => '休息日不是偷懒，而是身体真正发生适应性改变的时候。';

  @override
  String get homeTip_scale_not_everything => '体重会因水分和食物摄入每天波动 2–4 磅。请以周平均值为准。';

  @override
  String get homeTip_set_rep_ranges =>
      '1–5 次重复增加力量，6–12 次增加维度，12–20 次增加耐力。都很重要。';

  @override
  String get homeTip_sleep_for_recovery => '肌肉不是在训练时生长的，而是在睡眠时生长的。';

  @override
  String get homeTip_sodium_and_water => '盐不是敌人，它有助于补水和提升表现。不要害怕它。';

  @override
  String get homeTip_split_options => '推/拉/腿、上/下肢、全身训练 3 次——只要坚持，都有效果。';

  @override
  String get homeTip_stress_and_recovery => '高压力等于高皮质醇，会导致恢复变慢。请从整体上管理压力。';

  @override
  String get homeTip_tempo_training =>
      '尝试 3-0-1 的节奏（下放 3 秒，停顿 0 秒，上举 1 秒），感受不一样的训练效果。';

  @override
  String get homeTip_track_to_progress => '如果不追踪，就无法管理。记录您的训练组数。';

  @override
  String get homeTip_vitamin_d => '大多数人缺乏维生素 D。每天 1000–2000 IU 是安全的基准。';

  @override
  String get homeTip_walk_after_meals => '饭后散步 10 分钟可将血糖峰值降低 30%。';

  @override
  String get homeTip_warm_up_matters => '5 分钟的动作准备能让每一组训练更安全、更强效。';

  @override
  String get homeTip_zone2_cardio => 'Zone 2 有氧（可以交谈的配速）能构建有氧基础，这是其他一切的基础。';

  @override
  String get homeTodaysNutrition => '今日营养';

  @override
  String get homeTodaysWorkout => '今日训练';

  @override
  String get homeTrackNutrition => '追踪营养';

  @override
  String get homeViewStrengthChartsStreaks => '查看力量图表、连续记录、XP 和成就。';

  @override
  String get homeViewYourWorkoutHistory => '查看你的训练历史并浏览动作库。';

  @override
  String get homeYourAiWorkout => '你的 AI 训练';

  @override
  String get homeYourCommandCenter => '你的控制中心';

  @override
  String get homeYourProgress => '你的进度';

  @override
  String get homescreenCustomizationChangesAreSavedAutomaticall =>
      '更改将自动保存并立即生效。';

  @override
  String get homescreenCustomizationChooseWhichCardsTo => '选择要在主屏幕上显示的卡片';

  @override
  String get homescreenCustomizationCustomizeHome => '自定义主页';

  @override
  String get homescreenCustomizationDailyActivity => '每日活动';

  @override
  String get homescreenCustomizationExerciseVariationThisWeek => '本周动作变化';

  @override
  String get homescreenCustomizationFeatureVotingAndRoadmap => '功能投票与路线图预览';

  @override
  String get homescreenCustomizationFitnessScore => '健身评分';

  @override
  String get homescreenCustomizationGoalsAndMilestonesFor => '本周目标与里程碑';

  @override
  String get homescreenCustomizationHealthDeviceActivitySummary => '健康设备活动摘要';

  @override
  String get homescreenCustomizationLogFoodStatsShare => '记录饮食、数据、分享、饮水按钮';

  @override
  String get homescreenCustomizationMoodCheckIn => '心情打卡';

  @override
  String get homescreenCustomizationOverallFitnessStrengthNu => '综合健身、力量与营养评分';

  @override
  String get homescreenCustomizationQuickActions => '快捷操作';

  @override
  String get homescreenCustomizationQuickMoodPickerFor => '用于即时训练的快速心情选择器';

  @override
  String get homescreenCustomizationResetToDefaults => '恢复默认设置';

  @override
  String get homescreenCustomizationUpcomingFeatures => '即将推出的功能';

  @override
  String get homescreenCustomizationWeekChanges => '周变化';

  @override
  String get homescreenCustomizationWeeklyGoals => '每周目标';

  @override
  String get homescreenCustomizationWeeklyProgress => '每周进度';

  @override
  String get homescreenCustomizationWorkoutCompletionProgressRi => '训练完成进度环';

  @override
  String get hormonalHealthFailedToLoadHormonal => '无法加载荷尔蒙健康数据';

  @override
  String get hormonalHealthGetStarted => '开始使用';

  @override
  String get hormonalHealthHormonalHealth => '荷尔蒙健康';

  @override
  String get hormonalHealthHormonalHealthTracking => '荷尔蒙健康追踪';

  @override
  String get hormonalHealthLogHowYouRe => '记录你的感受';

  @override
  String get hormonalHealthLogNow => '立即记录';

  @override
  String get hormonalHealthLogToday => '记录今日';

  @override
  String get hormonalHealthNoCheckInYet => '今日暂无打卡';

  @override
  String get hormonalHealthNotLogged => '未记录';

  @override
  String get hormonalHealthPeriodStartLogged => '已记录经期开始';

  @override
  String get hormonalHealthRecommendations => '建议';

  @override
  String hormonalHealthScreenValue(Object value) {
    return '$value/10';
  }

  @override
  String get hormonalHealthSettingsAddHormoneGoal => '添加荷尔蒙目标';

  @override
  String get hormonalHealthSettingsAdjustWorkoutIntensityBased =>
      '根据你的周期阶段调整训练强度';

  @override
  String get hormonalHealthSettingsBirthSex => '生理性别';

  @override
  String get hormonalHealthSettingsCycleLength => '周期长度';

  @override
  String get hormonalHealthSettingsCycleSyncNutrition => '周期同步营养';

  @override
  String get hormonalHealthSettingsCycleSyncWorkouts => '周期同步训练';

  @override
  String get hormonalHealthSettingsEnableCycleTracking => '启用周期追踪';

  @override
  String get hormonalHealthSettingsGenderIdentity => '性别认同';

  @override
  String get hormonalHealthSettingsGetNutritionTipsBased => '获取基于你周期阶段的营养建议';

  @override
  String get hormonalHealthSettingsHormonalHealthSettings => '荷尔蒙健康设置';

  @override
  String get hormonalHealthSettingsHormoneSupportiveExercises => '荷尔蒙支持性训练';

  @override
  String get hormonalHealthSettingsHormoneSupportiveFoods => '荷尔蒙支持性食物';

  @override
  String get hormonalHealthSettingsIncludeHormoneFriendlyFood => '包含荷尔蒙友好型食物建议';

  @override
  String get hormonalHealthSettingsLastPeriodStart => '上次经期开始日期';

  @override
  String get hormonalHealthSettingsNotSet => '未设置';

  @override
  String get hormonalHealthSettingsPeriodDuration => '经期持续时间';

  @override
  String get hormonalHealthSettingsPrioritizeExercisesThatSupp =>
      '优先选择支持你目标的训练';

  @override
  String hormonalHealthSettingsScreenDays(Object selected) {
    return '$selected 天';
  }

  @override
  String hormonalHealthSettingsScreenDays2(Object selected) {
    return '$selected 天';
  }

  @override
  String hormonalHealthSettingsScreenDays3(Object selected) {
    return '$selected 天';
  }

  @override
  String hormonalHealthSettingsScreenDays4(Object selected) {
    return '$selected 天';
  }

  @override
  String get hormonalHealthSettingsSelectHormoneGoals => '选择荷尔蒙目标';

  @override
  String get hormonalHealthSettingsTrackYourMenstrualCycle => '追踪你的月经周期以优化训练';

  @override
  String get hormonalHealthTodaySCheckIn => '今日打卡';

  @override
  String get hormonalHealthUnableToLoadToday => '无法加载今日记录';

  @override
  String get hormoneGoalsCardNoHormoneGoalsSet => '未设置荷尔蒙目标';

  @override
  String get hormoneGoalsCardSetGoals => '设置目标';

  @override
  String get hormoneGoalsCardYourGoals => '你的目标';

  @override
  String get hormoneLogAddReading => '添加读数';

  @override
  String get hormoneLogBasalTemperature => '基础体温';

  @override
  String get hormoneLogCervicalMucus => '宫颈粘液';

  @override
  String get hormoneLogCheckInSaved => '打卡已保存！';

  @override
  String get hormoneLogDailyCheckIn => '每日打卡';

  @override
  String get hormoneLogHelpsYourCoachTime => '帮助你的教练掌握生育指导时间';

  @override
  String get hormoneLogHowAreYouFeeling => '你今天感觉如何？';

  @override
  String get hormoneLogLhOvulationTest => 'LH排卵测试';

  @override
  String get hormoneLogMood => '心情';

  @override
  String get hormoneLogNone => '无';

  @override
  String get hormoneLogNotesOptional => '备注（可选）';

  @override
  String get hormoneLogPeriodFlow => '经期流量';

  @override
  String get hormoneLogSaveCheckIn => '保存打卡';

  @override
  String get hormoneLogSaving => '正在保存...';

  @override
  String get hormoneLogSexualActivity => '性活动';

  @override
  String hormoneLogSheetFailedToSave(Object e) {
    return '保存失败：$e';
  }

  @override
  String hormoneLogSheetValue(Object value) {
    return '$value/10';
  }

  @override
  String get hormoneLogSymptoms => '症状';

  @override
  String get hormoneLogTakeItFirstThing => '每天早晨起床前第一时间进行测试。';

  @override
  String get hourlyActivityChartActive => '活跃';

  @override
  String get hourlyActivityChartActive2 => '活跃';

  @override
  String get hourlyActivityChartActiveHours => '活跃时长';

  @override
  String hourlyActivityChartActiveHours2(Object _activeHours) {
    return '$_activeHours 个活跃小时';
  }

  @override
  String get hourlyActivityChartActivityTrends => '活动趋势';

  @override
  String get hourlyActivityChartSedentary => '久坐';

  @override
  String get hourlyActivityChartSedentary2 => '久坐';

  @override
  String get hourlyActivityChartSedentaryHours => '久坐时长';

  @override
  String hourlyActivityChartSedentaryHours2(Object _sedentaryHours) {
    return '$_sedentaryHours 个久坐小时';
  }

  @override
  String hourlyActivityChartSteps(Object steps) {
    return '$steps 步';
  }

  @override
  String get hrZonesCardAddYourDateOf => '添加出生日期以计算个性化心率区间';

  @override
  String hrZonesCardBpm(Object currentHR) {
    return '$currentHR bpm';
  }

  @override
  String get hrZonesCardFitnessAge => '体能年龄';

  @override
  String get hrZonesCardHeartRateZones => '心率区间';

  @override
  String get hrZonesCardHrZonesNotAvailable => '心率区间不可用';

  @override
  String hrZonesCardMaxHrBpm(Object maxHR) {
    return '最大心率：$maxHR bpm';
  }

  @override
  String get hrZonesCardMlKgMin => 'ml/kg/min';

  @override
  String get hrZonesCardPersonalizedTrainingZones => '个性化训练区间';

  @override
  String get hrZonesCardSetCustomMaxHr => '设置自定义最大心率';

  @override
  String get hrZonesCardVo2Max => 'VO2 Max';

  @override
  String hrZonesCardYearsYounger(Object ageDiff) {
    return '年轻 $ageDiff 岁';
  }

  @override
  String hrZonesCardZone(Object name) {
    return '区间：$name';
  }

  @override
  String get hydrationAdd => '添加';

  @override
  String get hydrationAddWater => '加水';

  @override
  String get hydrationAmount => '金额';

  @override
  String get hydrationAmountMl => '用量（毫升）';

  @override
  String get hydrationCurrent => '当前';

  @override
  String get hydrationCustomAmount => '定制金额';

  @override
  String get hydrationDailyGoal => '每日目标';

  @override
  String hydrationDialogLog(Object label) {
    return '记录 $label';
  }

  @override
  String get hydrationEnterAnyAmountIn => '输入任意毫升数';

  @override
  String get hydrationGoalMl => '目标（毫升）';

  @override
  String get hydrationHydrationSettings => '水合设置';

  @override
  String get hydrationNotesOptional => '注释（可选）';

  @override
  String get hydrationQuickActionsInstructions => '使用说明';

  @override
  String get hydrationQuickActionsLogDrink => '原木饮料';

  @override
  String get hydrationQuickActionsNote => '注意事项';

  @override
  String get hydrationQuickActionsVideo => '视频';

  @override
  String get hydrationRecommended20003000mlPer => '建议：每天 2000-3000ml';

  @override
  String get hydrationRemaining => '剩余';

  @override
  String hydrationSummaryBlockGal(Object gallons, Object goalGallons) {
    return '($gallons / $goalGallons 加仑)';
  }

  @override
  String get hydrationSummaryBlockHydration => '保湿';

  @override
  String hydrationSummaryBlockMl(Object currentMl, Object goalMl) {
    return '$currentMl / $goalMl 毫升';
  }

  @override
  String get hydrationSummaryBlockTapToViewDetails => '点击查看详情';

  @override
  String hydrationSummaryBlockValue(Object percentageInt) {
    return '$percentageInt%';
  }

  @override
  String hydrationTabAddedOfWater(Object displayAmount, Object label) {
    return '已添加 $displayAmount$label 水';
  }

  @override
  String hydrationTabLog(Object label) {
    return '记录 $label';
  }

  @override
  String hydrationTabMl(Object ml) {
    return '${ml}ml';
  }

  @override
  String hydrationTabMlOf(Object label, Object ml) {
    return '${ml}ml / $label';
  }

  @override
  String get hydrationTabPartAnyMl => '任意毫升';

  @override
  String get hydrationTabPartBreakdown => '故障';

  @override
  String get hydrationTabPartChat => '聊天';

  @override
  String get hydrationTabPartCustom => '定制';

  @override
  String get hydrationTabPartFuel => '燃料';

  @override
  String get hydrationTabPartOther => '其他';

  @override
  String get hydrationTabPartOtherDrinks => '其他饮品';

  @override
  String get hydrationTabPartProteinShake => '蛋白质奶昔';

  @override
  String get hydrationTabPartQuickAddWater => '快速加水';

  @override
  String get hydrationTabPartSportsDrink => '运动饮料';

  @override
  String hydrationTabPartStatItemVia(Object label) {
    return '通过 $label';
  }

  @override
  String get hydrationTabPartWater => '水';

  @override
  String get hydrationTodaySLog => '今天的日志';

  @override
  String get hydrationUpdateGoal => '更新目标';

  @override
  String importDialogFile(Object name) {
    return '文件：$name';
  }

  @override
  String importDialogImportData(Object appName) {
    return '导入 $appName 数据';
  }

  @override
  String importDialogImportData2(Object appName) {
    return '导入 $appName 数据';
  }

  @override
  String importDialogImportedN(Object summary) {
    return '已导入：\n$summary';
  }

  @override
  String importDialogSelectAPreviouslyExported(Object appName) {
    return '选择之前导出的 $appName ZIP 文件以恢复数据。导入将使用文件中所有可用的数据。';
  }

  @override
  String importDialogThisWillReplaceYour(Object appName) {
    return '这将替换你当前的 $appName 数据';
  }

  @override
  String get importEquipmentAnalyze => '分析';

  @override
  String get importEquipmentAnyPublicWebpageListing => '任何列出健身器材的公开网页。';

  @override
  String get importEquipmentEGNdumbbells5 =>
      '例如：\n5-100磅哑铃\n2个深蹲架\n腿举机（挂片式）\n4台跑步机\n综合训练器...';

  @override
  String get importEquipmentEverythingImportedGoesTo =>
      '所有导入的内容都会进入审核界面——未经您的确认，我们绝不会覆盖您的现有器材。';

  @override
  String get importEquipmentImportEquipment => '导入器材';

  @override
  String get importEquipmentImportFailed => '导入失败';

  @override
  String get importEquipmentLetAiReadYour => '让AI读取您健身房的器材列表';

  @override
  String get importEquipmentPasteEquipmentText => '粘贴器材文本';

  @override
  String get importEquipmentPasteTheUrl => '粘贴URL';

  @override
  String get importEquipmentResultAdd => '+ 添加';

  @override
  String get importEquipmentResultCustom => '自定义 ✓';

  @override
  String get importEquipmentResultInferredFromImportedContent => '根据导入内容推断';

  @override
  String get importEquipmentResultNoEquipmentCouldBe => '无法从您的导入内容中匹配到器材。';

  @override
  String get importEquipmentResultReviewBeforeSavingTap => '保存前请审核。点击标签即可移除。';

  @override
  String get importEquipmentResultSaving => '正在保存...';

  @override
  String importEquipmentResultSheetAddedEquipmentItems(Object addedCount) {
    return '已添加 $addedCount 个器械';
  }

  @override
  String importEquipmentResultSheetMatched(
    Object matchedKeptCount,
    Object totalMatched,
  ) {
    return '已匹配 ($matchedKeptCount/$totalMatched)';
  }

  @override
  String importEquipmentResultSheetSaveItems(Object keepCount) {
    return '保存 $keepCount 个项目';
  }

  @override
  String importEquipmentResultSheetUnmatched(Object length) {
    return '未匹配 ($length)';
  }

  @override
  String importEquipmentResultSheetWeFoundItemsIn(Object totalExtracted) {
    return '我们在您的健身房中发现了 $totalExtracted 个项目';
  }

  @override
  String get importEquipmentResultWeCouldnTMatch =>
      '我们无法将这些内容与已知器材匹配。您可以跳过或保留为自定义项。';

  @override
  String get importEquipmentResultWorkoutEnvironment => '锻炼环境';

  @override
  String importEquipmentSheetUpToPhotosEquipment(Object _kMaxPhotos) {
    return '最多 $_kMaxPhotos 张照片 — 器械墙、架子、机器标签';
  }

  @override
  String get importEquipmentThisUsuallyTakes10 => '这通常需要10-30秒。';

  @override
  String get importEquipmentTryAgain => '重试';

  @override
  String get importEquipmentWorking => '处理中...';

  @override
  String get importEquipmentYourGymSEquipment => '您健身房的器材列表或设施手册';

  @override
  String get importExerciseDescribeTheExercise => '描述该动作';

  @override
  String get importExerciseEGSeatedCable => '例如：“中性握距坐姿划船，针对中背部和后三角肌”';

  @override
  String get importExerciseExerciseNameHintOptional => '动作名称提示（可选）';

  @override
  String get importExerciseFromGallery => '从相册导入';

  @override
  String get importExerciseFromLibrary => '从库中选择';

  @override
  String get importExerciseImportExercise => '导入动作';

  @override
  String get importExerciseImportWithAi => '使用AI导入';

  @override
  String get importExercisePreviewAddStep => '添加步骤';

  @override
  String get importExercisePreviewAiSearchable => 'AI可搜索';

  @override
  String get importExercisePreviewAlreadyInYourExercises => '已存在于您的动作库中';

  @override
  String get importExercisePreviewDiscard => '放弃';

  @override
  String get importExercisePreviewDiscardImportedExercise => '放弃导入的动作？';

  @override
  String get importExercisePreviewSaveExercise => '保存动作';

  @override
  String get importExercisePreviewSaving => '正在保存...';

  @override
  String importExercisePreviewSheetAiConfidencePleaseReview(Object pct) {
    return 'AI 置信度: $pct% — 请检查';
  }

  @override
  String importExercisePreviewSheetYouAlreadyHaveIn(Object name) {
    return '你的动作库中已有“$name”。正在查看';
  }

  @override
  String get importExercisePreviewUseExisting => '使用现有动作';

  @override
  String get importExerciseRecordA510s => '录制5-10秒视频';

  @override
  String get importExerciseRecordVideo => '录制视频';

  @override
  String importExerciseScreenS(Object inSeconds) {
    return '$inSeconds秒';
  }

  @override
  String get importExerciseSnapItWeLl => '拍下来，我们来提取';

  @override
  String get importExerciseTakePhoto => '拍照';

  @override
  String get importExerciseWorking => '处理中...';

  @override
  String get importImport => '导入';

  @override
  String get importImportSuccessful => '导入成功';

  @override
  String get importNewDataWillBe => '新数据将与您的现有数据合并。';

  @override
  String get importSelectFile => '选择文件';

  @override
  String get importThisWillImport => '这将导入：';

  @override
  String get inProgressStripLogAWorkoutTo => '记录一次锻炼以解锁您的首个进度徽章。';

  @override
  String get inflammationAnalysisAiIsCheckingFor => 'AI正在检查炎症成分';

  @override
  String get inflammationAnalysisAnalyzingIngredients => '正在分析成分...';

  @override
  String get inflammationAnalysisConcern => '关注';

  @override
  String get inflammationAnalysisGood => '良好';

  @override
  String get inflammationAnalysisInflammationScore => '炎症评分';

  @override
  String get inflammationAnalysisIngredientAnalysisUnavailabl => '成分分析不可用';

  @override
  String get inflammationAnalysisIngredientsAnalysis => '成分分析';

  @override
  String get inflammationAnalysisNeutral => '中性';

  @override
  String get inflammationAnalysisShowLess => '收起';

  @override
  String inflammationAnalysisWidgetShowMore(Object sortedIngredients) {
    return '显示更多 $sortedIngredients 项';
  }

  @override
  String get inflammationTagsContainsUltraProcessedItems => '含有超加工食品';

  @override
  String get inflammationTagsExamplesSoftDrinksInstant =>
      '例如：软饮、方便面、包装零食、鸡块、大多数早餐麦片。';

  @override
  String get inflammationTagsHowTheScoreIs => '评分计算方式';

  @override
  String get inflammationTagsInflammationScore => '炎症评分';

  @override
  String get inflammationTagsLowerScoresReduceSystemic =>
      '较低的评分有助于减少全身性炎症、肠道刺激和餐后能量崩溃。';

  @override
  String get inflammationTagsNovaProcessingLevelOmega =>
      '基于NOVA加工等级、Omega-6与Omega-3脂肪酸比例、精制糖含量、纤维和多酚密度、血糖负荷以及植物油含量。参考同行评审的膳食炎症指数 (DII) 标准进行校准。';

  @override
  String get inflammationTagsResearchLinksRegularConsump =>
      '研究表明，经常食用此类食品与炎症、肥胖、心脏病和消化系统问题增加有关。';

  @override
  String get inflammationTagsUltraProcessedFoods => '超加工食品';

  @override
  String get inflammationTagsUltraProcessedFoodsNova =>
      '超加工食品 (NOVA 第4组) 含有工业添加剂，如乳化剂、氢化油、人工甜味剂和蛋白质分离物——这些物质在家庭烹饪中并不常见。';

  @override
  String get injuriesActive => '进行中';

  @override
  String get injuriesHealed => '已痊愈';

  @override
  String get injuriesHowIsYourPain => '你今天的疼痛程度如何？';

  @override
  String get injuriesInjuryTracker => '伤病追踪';

  @override
  String get injuriesListFailedToLoad => '加载失败';

  @override
  String get injuriesListInjuryManagement => '伤病管理';

  @override
  String get injuriesListReportInjury => '报告伤病';

  @override
  String injuriesListScreenInjuries(Object id) {
    return '/injuries/$id';
  }

  @override
  String get injuriesMild => '轻微';

  @override
  String get injuriesRecovering => '恢复中';

  @override
  String get injuriesReportAnInjury => '报告伤病';

  @override
  String get injuriesReportInjury => '报告伤病';

  @override
  String injuriesScreenCheckIn(Object bodyPartDisplay) {
    return '签到：$bodyPartDisplay';
  }

  @override
  String injuriesScreenCheckInSavedPain(Object painLevel) {
    return '签到已保存：疼痛等级 $painLevel/10';
  }

  @override
  String get injuriesSelectorAiWillAvoidExercises => 'AI 将避开可能加重这些部位负担的动作';

  @override
  String get injuriesSelectorEnterCustomInjuryE => '输入自定义伤病 (例如：\"网球肘\")';

  @override
  String get injuriesSelectorInjuriesToConsider => '需考虑的伤病';

  @override
  String injuriesSelectorSelected(Object selectedCount) {
    return '已选$selectedCount项';
  }

  @override
  String get injuriesSevere => '严重';

  @override
  String get injuriesSomethingWentWrong => '出错了';

  @override
  String get injuriesTryAgain => '重试';

  @override
  String get injuriesUnknownError => '未知错误';

  @override
  String get injuryCardCheckIn => '打卡';

  @override
  String injuryCardDaysAgo(Object daysSinceReported) {
    return '$daysSinceReported 天前';
  }

  @override
  String injuryCardDaysLeft(Object daysUntilRecovery) {
    return '剩余 $daysUntilRecovery 天';
  }

  @override
  String get injuryCardFullyRecovered => '完全康复';

  @override
  String get injuryCardHealed => '已痊愈';

  @override
  String injuryCardPain(Object painLevel) {
    return '疼痛感：$painLevel/10';
  }

  @override
  String get injuryCardRecoveryProgress => '恢复进度';

  @override
  String injuryCardValue(Object recoveryProgress) {
    return '$recoveryProgress%';
  }

  @override
  String get injuryDetailAffectedExercises => '受影响的动作';

  @override
  String get injuryDetailAreYouSureThis => '确定该伤病已完全痊愈吗？这会将其移至你的伤病历史记录中。';

  @override
  String get injuryDetailCheckInLoggedSuccessfully => '打卡记录成功';

  @override
  String get injuryDetailCongratulationsOnYourRecove => '恭喜你康复了！';

  @override
  String get injuryDetailGoBack => '返回';

  @override
  String get injuryDetailInjuryDetails => '伤病详情';

  @override
  String get injuryDetailInjuryNotFound => '未找到伤病记录';

  @override
  String get injuryDetailMarkAsHealed => '标记为已痊愈？';

  @override
  String get injuryDetailMarkAsHealed2 => '标记为已痊愈';

  @override
  String get injuryDetailNotes => '备注';

  @override
  String get injuryDetailPainLevelHistory => '疼痛程度历史';

  @override
  String get injuryDetailRecoveryProgress => '恢复进度';

  @override
  String get injuryDetailRehabExercises => '康复训练';

  @override
  String get injuryDetailScreenAnyNotesAboutHow => '关于今天感觉的任何备注...';

  @override
  String get injuryDetailScreenDailyCheckIn => '每日打卡';

  @override
  String injuryDetailScreenFailedToLogCheck(Object e) {
    return '记录签到失败：$e';
  }

  @override
  String injuryDetailScreenFailedToMarkAs(Object e) {
    return '标记为已愈合失败：$e';
  }

  @override
  String injuryDetailScreenInjuries(Object id) {
    return '/injuries/$id';
  }

  @override
  String get injuryDetailScreenLogCheckIn => '记录打卡';

  @override
  String injuryDetailScreenPartCheckInSheetHowIsYourFeeling(
    Object bodyPartDisplay,
  ) {
    return '您今天的 $bodyPartDisplay 感觉如何？';
  }

  @override
  String injuryDetailScreenValue(Object recoveryProgress) {
    return '$recoveryProgress%';
  }

  @override
  String get injuryDetailSomethingWentWrong => '出错了';

  @override
  String get injuryDetailThisInjuryMayHave => '该伤病记录可能已被删除';

  @override
  String get injuryDetailTryAgain => '重试';

  @override
  String get injuryDetailUnknownError => '未知错误';

  @override
  String get injuryDetailYesHealed => '是的，已痊愈';

  @override
  String inlineEditPillEditSetByReps(
    Object _weightText,
    Object reps,
    Object unit,
  ) {
    return '编辑组，$_weightText $unit，$reps 次';
  }

  @override
  String get inlineEditPillSaveSet => '保存组';

  @override
  String inlineEditPillValue(Object _weightText, Object reps, Object unit) {
    return '$_weightText $unit × $reps';
  }

  @override
  String get inlineExerciseInfoFormTips => '动作要领';

  @override
  String get inlineExerciseInfoSetup => '设置';

  @override
  String get inlineReferralExpanderApply => '应用';

  @override
  String get inlineReferralExpanderEnterCode => '输入代码';

  @override
  String get inlineReferralExpanderReferralCodeApplied => '✓ 推荐码已应用';

  @override
  String get inlineRestRow15s => '-15s';

  @override
  String get inlineRestRow15s2 => '+15秒';

  @override
  String get inlineRestRowAddANoteAbout => '添加关于此组的备注...';

  @override
  String get inlineRestRowGettingTip => '获取建议中...';

  @override
  String get inlineRestRowHowDidThatFeel => '感觉如何？';

  @override
  String get inlineRestRowNote => '备注';

  @override
  String get inlineRestRowRpe => '(RPE)';

  @override
  String inlineRestRowValue(Object aiTip) {
    return '\"$aiTip\"';
  }

  @override
  String get inlineThemeSelectorAuto => '自动';

  @override
  String get inlineWorkoutChatAddAMessage => '添加消息...';

  @override
  String get inlineWorkoutChatAskMeAnything => '尽管问我！';

  @override
  String get inlineWorkoutChatChangeCoach => '更换教练';

  @override
  String inlineWorkoutChatCheckMyFormOn(Object name) {
    return '检查我的 $name 动作姿势';
  }

  @override
  String get inlineWorkoutChatCollapseChat => '收起聊天';

  @override
  String get inlineWorkoutChatExpandChat => '展开聊天';

  @override
  String get inlineWorkoutChatFailedToLoadChat => '聊天记录加载失败';

  @override
  String get inlineWorkoutChatForm => '动作要领';

  @override
  String inlineWorkoutChatHowLongShouldI(Object name) {
    return '做 $name 时组间休息多久合适？';
  }

  @override
  String inlineWorkoutChatHowManySetsShould(Object name) {
    return '为了达到最佳效果，$name 应该做几组？';
  }

  @override
  String get inlineWorkoutChatIntentIdentifyEquipmentWh =>
      '[intent:identify_equipment] 这是什么器械？';

  @override
  String get inlineWorkoutChatRest => '休息';

  @override
  String get inlineWorkoutChatSets => '组数';

  @override
  String get inlineWorkoutChatSwaps => '替换';

  @override
  String inlineWorkoutChatWhatAreSomeAlternative(Object name) {
    return '有哪些可以替代 $name 的动作？';
  }

  @override
  String inlineWorkoutChatWhatAreTheKey(Object name) {
    return '$name 的关键动作要点是什么？';
  }

  @override
  String get inlineWorkoutChatWhatSThis => '这是什么？';

  @override
  String get insightsDetailAiAnalysis => 'AI 分析';

  @override
  String get insightsDetailCompletionRate => '完成率';

  @override
  String get insightsDetailGenerateAiAnalysis => '生成 AI 分析';

  @override
  String get insightsDetailGenerating => '正在生成...';

  @override
  String get insightsDetailHighlights => '亮点';

  @override
  String get insightsDetailNoAiAnalysisYet => '此报告暂无 AI 分析';

  @override
  String get insightsDetailRegenerateAiAnalysis => '重新生成 AI 分析';

  @override
  String insightsDetailScreenCouldNotRegenerate(Object e) {
    return '无法重新生成 — $e';
  }

  @override
  String insightsDetailScreenDayStreak(Object currentStreak) {
    return '连续 $currentStreak 天';
  }

  @override
  String insightsDetailScreenOfWorkouts(
    Object workoutsCompleted,
    Object workoutsScheduled,
  ) {
    return '已完成 $workoutsCompleted/$workoutsScheduled 次训练';
  }

  @override
  String insightsDetailScreenPrs(Object prsAchieved) {
    return '$prsAchieved 项 PR';
  }

  @override
  String insightsDetailScreenReport(Object weekLabel) {
    return '$weekLabel 报告';
  }

  @override
  String insightsDetailScreenValue(Object rate) {
    return '$rate%';
  }

  @override
  String get insightsDetailTipsForNextWeek => '下周建议';

  @override
  String get insightsDetailWorkoutSummary => '训练总结';

  @override
  String insightsNarrativeTemplateAi(Object periodName) {
    return '$periodName AI';
  }

  @override
  String get insightsNarrativeTemplateYourConsistencyIsCompoundin =>
      '你的坚持正在产生复利效应。继续保持训练量。';

  @override
  String get insightsPastReports => '往期报告';

  @override
  String get insightsProgressTemplateBodyFat => '体脂率';

  @override
  String get insightsProgressTemplateBodyRecovery => '身体与恢复';

  @override
  String insightsProgressTemplateDays(Object maxStreak) {
    return '$maxStreak 天';
  }

  @override
  String get insightsProgressTemplateMaxStreak => '最长连练';

  @override
  String get insightsProgressTemplateNutrition => '营养';

  @override
  String get insightsProgressTemplateReadiness => '准备状态';

  @override
  String get insightsProgressTemplateWeight => '体重';

  @override
  String get insightsPrsTemplate1Pr => '1 项 PR';

  @override
  String insightsPrsTemplateMorePrs(Object length) {
    return '+ 更多 $length 项 PR';
  }

  @override
  String get insightsPrsTemplateNoPrsYetThis => '本周期暂无 PR';

  @override
  String get insightsPrsTemplatePersonalRecords => '个人纪录 (PR)';

  @override
  String insightsPrsTemplatePrs(Object count) {
    return '$count 项 PR';
  }

  @override
  String get insightsPrsTemplateShowingUpIsThe => '坚持训练就是真正的胜利。继续保持。';

  @override
  String get insightsReportCardCalories => '卡路里';

  @override
  String get insightsReportCardCompleted => '已完成';

  @override
  String get insightsReportCardCompletion => '完成度';

  @override
  String get insightsReportCardMaxStreak => '最长连练';

  @override
  String get insightsReportCardPrs => 'PR';

  @override
  String get insightsReportCardReportCard => '成绩单';

  @override
  String insightsReportCardTemplateDays(Object maxStreak) {
    return '$maxStreak 天';
  }

  @override
  String insightsReportCardTemplateValue(Object _completionPercent) {
    return '$_completionPercent%';
  }

  @override
  String get insightsReportsInsights => '报告与洞察';

  @override
  String get insightsScreenPartAiAnalysis => 'AI 分析';

  @override
  String get insightsScreenPartBody => '身体';

  @override
  String insightsScreenPartBodyCardValue(Object completionRate) {
    return '$completionRate%';
  }

  @override
  String insightsScreenPartBodyCardWorkoutsMinKcal(
    Object caloriesBurnedEstimate,
    Object totalTimeMinutes,
    Object workoutsCompleted,
    Object workoutsScheduled,
  ) {
    return '$workoutsCompleted/$workoutsScheduled 次训练  |  $totalTimeMinutes分钟  |  $caloriesBurnedEstimate kcal';
  }

  @override
  String get insightsScreenPartBodyFat => '体脂率';

  @override
  String get insightsScreenPartFailedToLoadInsights => '无法加载洞察数据';

  @override
  String get insightsScreenPartGenerateAiInsight => '生成 AI 洞察';

  @override
  String get insightsScreenPartGetPersonalizedAiAnalysis =>
      '获取针对你本周期训练数据的个性化 AI 分析。';

  @override
  String get insightsScreenPartLogYourMeasurementsTo => '记录你的身体测量数据以追踪体成分变化';

  @override
  String get insightsScreenPartLogYourReadinessAnd => '记录你的准备状态和心情以查看恢复洞察';

  @override
  String get insightsScreenPartMoodDistribution => '心情分布';

  @override
  String get insightsScreenPartNoPastReportsYet => '暂无往期报告';

  @override
  String get insightsScreenPartOverview => '概览';

  @override
  String insightsScreenPartPeriodSelectorCompletionRate(Object completionRate) {
    return '完成率 $completionRate%';
  }

  @override
  String insightsScreenPartPeriodSelectorValue(Object adherence) {
    return '$adherence%';
  }

  @override
  String get insightsScreenPartPleaseCheckYourConnection => '请检查网络连接并重试。';

  @override
  String get insightsScreenPartPrs => 'PR';

  @override
  String get insightsScreenPartShareThisReport => '分享此报告';

  @override
  String get insightsScreenPartStartTrackingNutritionTo => '开始记录营养以在此处查看洞察';

  @override
  String get insightsScreenPartTips => '建议';

  @override
  String get insightsScreenPartWeeklyReportsWillAppear => '周报生成后将显示在此处。';

  @override
  String get insightsScreenPartWeight => '体重';

  @override
  String get insightsStreakTemplateStreak => '连练';

  @override
  String get insightsStreakTemplateWorkouts => '训练';

  @override
  String get insightsSummaryTemplateCalories => '卡路里';

  @override
  String get insightsSummaryTemplatePrs => 'PR';

  @override
  String get insightsSummaryTemplateSummary => '总结';

  @override
  String insightsSummaryTemplateValue(Object pct) {
    return '$pct%';
  }

  @override
  String get insightsSummaryTemplateWorkouts => '训练';

  @override
  String get intensityPrompt1Left => '剩余 1 次';

  @override
  String get intensityPrompt2Left => '剩余 2 次';

  @override
  String get intensityPrompt3Left => '剩余 3 次以上';

  @override
  String get intensityPromptHard => '困难';

  @override
  String get intensityPromptHideRpeSlideDial =>
      '隐藏 RPE 滑块      精准设定 (RPE 1-10)';

  @override
  String get intensityPromptHowHardWasThat => '这组训练难度如何？';

  @override
  String get intensityPromptMax => '极限';

  @override
  String get intensityPromptModerate => '中等';

  @override
  String get intensityPromptPickAnEffortTo => '选择一个强度以继续';

  @override
  String intensityPromptSheetSet(Object exerciseName, Object setNumber) {
    return '第 $setNumber 组 · $exerciseName';
  }

  @override
  String get introAnAiCoachThat => '一位能制定计划、了解你的身体并每周进行调整的 AI 教练。';

  @override
  String get introBuildMyPlan => '制定我的计划';

  @override
  String introCardFormatDataTotalvolumelbsRound(Object totalSets) {
    return ').format(data.totalVolumeLbs.round())) 磅 · (totalSets) 组';
  }

  @override
  String get introCardMonth => '月。';

  @override
  String get introIAlreadyHaveAnAccount => '我已有账号';

  @override
  String introScreenV(Object _appVersion) {
    return 'v$_appVersion';
  }

  @override
  String get introTagline => '一位 AI 教练，为你制定计划、了解你的身体，并每周进行调整。';

  @override
  String get introYourBody => '你的身体。';

  @override
  String get introYourTimeline => '你的进度。';

  @override
  String get inventory2xXpActivatedFor => '2 倍 XP 已激活，持续 24 小时！';

  @override
  String get inventory2xXpActive => '⚡ 2 倍 XP 已激活';

  @override
  String get inventory3RefsSticker10 => '3 位推荐 → 贴纸 · 10 → 摇摇杯 · 25 → T 恤';

  @override
  String get inventory730100Day => '7、30、100 天连练';

  @override
  String get inventoryAddedToYourInventory => '已添加到你的物品栏';

  @override
  String get inventoryAddedToYourXp => '已添加到你的 XP 总量';

  @override
  String get inventoryAwesome => '太棒了！';

  @override
  String get inventoryCompleteAllDailyGoals => '完成所有每日目标';

  @override
  String get inventoryCosmetics => '装饰品';

  @override
  String get inventoryCrates => '补给箱';

  @override
  String get inventoryDailyCrates => '每日补给箱';

  @override
  String get inventoryEvery5Levels => '每 5 级';

  @override
  String get inventoryEveryXpEarnedRight => '当前获得的每一点 XP 都会翻倍。';

  @override
  String get inventoryFailedToActivate2x => '激活 2x XP 代币失败。请重试。';

  @override
  String get inventoryFailedToOpenCrate => '打开宝箱失败';

  @override
  String get inventoryFirstUnlockLevel50 => '首次解锁：50 级 — 免费贴纸包';

  @override
  String get inventoryGotIt => '知道了';

  @override
  String get inventoryHowToEarnItems => '如何获取物品';

  @override
  String get inventoryInventory => '库存';

  @override
  String get inventoryItems => '物品';

  @override
  String get inventoryLevelUpRewards => '升级奖励';

  @override
  String get inventoryMerchRewards => '周边奖励';

  @override
  String get inventoryOf24hBoost => '的 24 小时加成';

  @override
  String get inventoryOpenCratesToReceive => '打开宝箱以获取 XP 或消耗品';

  @override
  String get inventoryPick1Of3 => '每天从 3 个宝箱中选 1 个';

  @override
  String get inventoryReferFriendsEarnMerch => '邀请好友，更快获得周边';

  @override
  String inventoryScreenHM(Object hours, Object minutes) {
    return '$hours小时 $minutes分钟';
  }

  @override
  String inventoryScreenHMRemaining(Object hours, Object minutes) {
    return '剩余 $hours小时 $minutes分钟';
  }

  @override
  String inventoryScreenPartConsumableCardX(Object count) {
    return 'x$count';
  }

  @override
  String inventoryScreenToClaim(Object pendingCount) {
    return '待领取 $pendingCount 个';
  }

  @override
  String get inventoryScreenUiComeBackTomorrowFor => '明天再来获取更多！';

  @override
  String get inventoryScreenUiDailyCrates => '每日宝箱';

  @override
  String get inventoryScreenUiPick1Of3 => '每天从 3 个宝箱中选 1 个';

  @override
  String get inventoryScreenUiTrustLevel => '信任等级';

  @override
  String get inventoryStreakMilestones => '连续打卡里程碑';

  @override
  String get inventoryTapToBrowseOr => '点击以浏览或更改';

  @override
  String get inventoryTrustLevelAffectsXp => '信任等级会影响从锻炼和活动中获得的 XP。';

  @override
  String get inventoryTrustLevels => '信任等级';

  @override
  String get inventoryUnlockActivityCrate => '解锁活动宝箱';

  @override
  String get inventoryUsedAutomaticallyWhenYou => '在您中断打卡时自动使用';

  @override
  String get inventoryYouReceived => '您已获得：';

  @override
  String get journalEmpty => '日志为空。记录一次训练以开启时间线。';

  @override
  String get journalLogAWorkoutMeal => '记录一次锻炼、一顿餐食或一张照片以开始您的时间轴。';

  @override
  String get journalSearchHint => '搜索训练、餐食、照片…';

  @override
  String get journalTitle => '训练日志';

  @override
  String get journalYourJournalIsEmpty => '您的日志为空';

  @override
  String get kegelSessionAreYouSureYou => '确定要提前结束本次训练吗？您的进度将不会被保存。';

  @override
  String get kegelSessionBenefits => '益处';

  @override
  String get kegelSessionDoAnother => '再做一次';

  @override
  String get kegelSessionEndSession => '结束训练？';

  @override
  String get kegelSessionEndSession2 => '结束训练';

  @override
  String get kegelSessionInstructions => '说明';

  @override
  String get kegelSessionKegelExercise => '凯格尔运动';

  @override
  String get kegelSessionKegelSession => '凯格尔训练';

  @override
  String get kegelSessionNoExercisesAvailable => '暂无可用运动';

  @override
  String get kegelSessionQuickStart => '快速开始';

  @override
  String kegelSessionScreenErrorLoadingExercises(Object e) {
    return '加载动作时出错: $e';
  }

  @override
  String kegelSessionScreenRepOf(Object _currentRep, Object _totalReps) {
    return '第 $_currentRep 次，共 $_totalReps 次';
  }

  @override
  String kegelSessionScreenRepsXSHold(
    Object defaultHoldSeconds,
    Object defaultReps,
  ) {
    return '$defaultReps 次 x $defaultHoldSeconds 秒保持';
  }

  @override
  String get kegelSessionSessionComplete => '训练完成！';

  @override
  String get kegelSessionSqueeze => '收缩';

  @override
  String get kegelSessionSqueezeYourPelvicFloor => '收缩您的盆底肌并保持...';

  @override
  String get kegelSessionStartABasicKegel => '立即开始基础凯格尔训练';

  @override
  String get kegelSessionStartExercise => '开始运动';

  @override
  String get kegelSettingsAddKegelsToYour => '将凯格尔运动加入热身流程';

  @override
  String get kegelSettingsAddKegelsToYour2 => '将凯格尔运动加入拉伸放松流程';

  @override
  String get kegelSettingsBeginner => '初学者';

  @override
  String get kegelSettingsCooldown => '放松';

  @override
  String get kegelSettingsDailyReminders => '每日提醒';

  @override
  String get kegelSettingsDailySessionsGoal => '每日训练目标';

  @override
  String get kegelSettingsDedicatedPelvicFloorWorkout => '专属盆底肌训练课程';

  @override
  String get kegelSettingsEnableKegelExercises => '启用凯格尔运动';

  @override
  String get kegelSettingsExerciseLevel => '运动难度';

  @override
  String get kegelSettingsFocusArea => '重点区域';

  @override
  String get kegelSettingsGeneral => '常规';

  @override
  String get kegelSettingsGetRemindedToDo => '获取凯格尔运动提醒';

  @override
  String get kegelSettingsIncludeIn => '包含在';

  @override
  String get kegelSettingsIncludePelvicFloorExercises => '在您的训练中包含盆底肌运动';

  @override
  String get kegelSettingsPelvicFloorTraining => '盆底肌训练';

  @override
  String get kegelSettingsSelectExerciseLevel => '选择运动难度';

  @override
  String get kegelSettingsSelectFocusArea => '选择重点区域';

  @override
  String get kegelSettingsStandaloneSessions => '独立训练课程';

  @override
  String get kegelSettingsStrengthenYourPelvicFloor => '通过在锻炼计划中加入凯格尔运动来增强盆底肌。';

  @override
  String get kegelSettingsWarmup => '热身';

  @override
  String get languageLanguage => '语言';

  @override
  String lastNightSleepCardH(Object hours) {
    return '$hours小时';
  }

  @override
  String lastNightSleepCardM(Object minutes) {
    return '$minutes分钟';
  }

  @override
  String lastNightSleepCardValue(Object fmt, Object fmt1) {
    return '$fmt – $fmt1';
  }

  @override
  String get lastNightSleepLastNightSSleep => '昨晚睡眠';

  @override
  String get layoutEditorAppliedYourDefaultLayout => '已应用您的默认布局';

  @override
  String get layoutEditorFailedToLoadLayout => '加载布局失败';

  @override
  String get layoutEditorLayoutResetToOriginal => '布局已重置为原始状态';

  @override
  String get layoutEditorMySpace => '我的空间';

  @override
  String get layoutEditorNoLayoutFound => '未找到布局';

  @override
  String get layoutEditorReset => '重置';

  @override
  String get layoutEditorResetLayout => '重置布局';

  @override
  String get layoutEditorSavedAsYourDefault => '已保存为您的默认布局';

  @override
  String get layoutEditorScreenAppliedYourDefaultLayout => '已应用您的默认布局';

  @override
  String get layoutEditorScreenApply => '应用';

  @override
  String get layoutEditorScreenChooseAPresetTo => '选择一个预设以快速自定义您的主屏幕';

  @override
  String get layoutEditorScreenDragToReorderTap => '拖动以排序 • 点击以切换';

  @override
  String get layoutEditorScreenHidden => '已隐藏';

  @override
  String get layoutEditorScreenMyDefault => '我的默认';

  @override
  String layoutEditorScreenPartTogglesTabApplied(Object name) {
    return '已应用 $name';
  }

  @override
  String layoutEditorScreenPartTogglesTabApplied2(Object name) {
    return '已应用 $name';
  }

  @override
  String layoutEditorScreenPartTogglesTabTiles(Object length) {
    return '$length 个磁贴';
  }

  @override
  String layoutEditorScreenPartTogglesTabTiles2(Object length) {
    return '$length 个磁贴';
  }

  @override
  String get layoutEditorScreenPreview => '预览';

  @override
  String get layoutEditorScreenYourSavedCustomLayout => '您保存的自定义布局';

  @override
  String get layoutEditorToggles => '切换开关';

  @override
  String get leaderboardBeatTheirBest => '击败他们最好的';

  @override
  String get leaderboardChallengeWithoutNotification => '挑战而不通知（异步）';

  @override
  String get leaderboardEntryCardBeatTheirBest => '击败他们最好的';

  @override
  String get leaderboardEntryCardChallengeFriend => '挑战朋友';

  @override
  String get leaderboardEntryCardFriend => '✓ 朋友';

  @override
  String leaderboardEntryCardValue(Object rank) {
    return '第 $rank 名';
  }

  @override
  String get leaderboardLockedStateCompleteMoreWorkoutsTo => '完成更多锻炼即可解锁！';

  @override
  String get leaderboardLockedStateGlobalLeaderboardLocked => '全球排行榜已锁定';

  @override
  String get leaderboardLockedStateViewFriendsLeaderboard => '查看好友排行榜';

  @override
  String leaderboardLockedStateWorkouts(Object workoutsCompleted) {
    return '$workoutsCompleted / 10 次训练';
  }

  @override
  String get leaderboardMasters => '🏆 大师';

  @override
  String get leaderboardNoRankingsYet => '还没有排名';

  @override
  String get leaderboardPrivacyAnonymousMode => '匿名模式';

  @override
  String get leaderboardPrivacyCouldnTLoadPrivacy => '无法加载隐私设置。拉动重试。';

  @override
  String get leaderboardPrivacyLeaderboardPrivacy => '排行榜隐私';

  @override
  String get leaderboardPrivacyShowMeOnLeaderboards => '在排行榜中显示我';

  @override
  String get leaderboardPrivacyShowMyStatsOn => '在个人资料预览中显示我的统计数据';

  @override
  String leaderboardRankCardOf(Object totalUsers) {
    return '/ $totalUsers';
  }

  @override
  String leaderboardRankCardTop(Object percentile) {
    return '前 $percentile%';
  }

  @override
  String leaderboardRankCardValue(Object rank) {
    return '#$rank';
  }

  @override
  String get leaderboardRankCardYourRank => '你的等级';

  @override
  String leaderboardRowAdornmentsDownPlaces(Object absStr) {
    return '下降 $absStr 名';
  }

  @override
  String get leaderboardRowAdornmentsNoPreviousRankData => '暂无之前的排名数据';

  @override
  String get leaderboardRowAdornmentsRankUnchanged => '排名未变';

  @override
  String leaderboardRowAdornmentsStreakDays(Object streak) {
    return '连续 $streak 天';
  }

  @override
  String leaderboardRowAdornmentsUpPlaces(Object absStr) {
    return '上升 $absStr 名';
  }

  @override
  String get leaderboardRush => '🚀 冲刺';

  @override
  String get leaderboardStreaks => '🔥 条纹';

  @override
  String leaderboardTabChallenge(Object userName) {
    return '挑战 $userName';
  }

  @override
  String get leaderboardVolume => '🏋️ 音量';

  @override
  String get leaderboardWeek => '⚡ 周';

  @override
  String get levelUpCatchAwesomeGotIt => '太棒了，知道了';

  @override
  String get levelUpCatchIncludesAFreePhysical => '包含一份免费实物奖励 — 请在“周边奖励”中领取';

  @override
  String get levelUpCatchReveal => '揭晓';

  @override
  String get levelUpCatchTapToSeeYour => '点击查看你的奖励';

  @override
  String levelUpCatchUpBannerFree(Object displayName) {
    return '免费 $displayName';
  }

  @override
  String levelUpCatchUpBannerLevelUnlocked(Object levelReached) {
    return '已解锁 $levelReached 级！';
  }

  @override
  String levelUpCatchUpBannerValue(Object displayName, Object quantity) {
    return '$quantity× $displayName';
  }

  @override
  String levelUpCatchUpBannerYouGainedLevelsUp(
    Object count,
    Object highestLevel,
  ) {
    return '你获得了 $count 个等级（最高至 L$highestLevel）';
  }

  @override
  String levelUpCatchUpBannerYouLeveledUpTimes(Object length) {
    return '你升级了 $length 次';
  }

  @override
  String levelUpCatchUpBannerYouLeveledUpTo(Object highestLevel) {
    return '你已升级至 $highestLevel 级！';
  }

  @override
  String get levelUpCatchYourRewardsAreAlready => '你的奖励已放入库存';

  @override
  String get levelUpContinue => '继续';

  @override
  String get levelUpDialogAccomplishments => '成就';

  @override
  String levelUpDialogLevelReward(Object level) {
    return '等级 $level 奖励';
  }

  @override
  String get levelUpDialogLevelUp => '升级！';

  @override
  String levelUpDialogLevels(Object levelRange) {
    return '等级 $levelRange';
  }

  @override
  String levelUpDialogNewRank(Object displayName) {
    return '新等级: $displayName';
  }

  @override
  String levelUpDialogNextMilestoneLevel(Object m) {
    return '下一里程碑: 等级 $m';
  }

  @override
  String get levelUpDialogOpenCrate => '打开宝箱';

  @override
  String levelUpDialogPartAccomplishmentNextRewardAtLevel(Object widget) {
    return '下一奖励等级 $widget';
  }

  @override
  String levelUpDialogPlayAgainBest(Object _bonusGameScore) {
    return '再玩一次 · 最高分 $_bonusGameScore';
  }

  @override
  String levelUpDialogRank(Object displayName) {
    return '等级: $displayName';
  }

  @override
  String levelUpDialogTier(Object displayName) {
    return '$displayName 阶层';
  }

  @override
  String levelUpDialogX(Object displayName, Object quantity) {
    return '$displayName x$quantity';
  }

  @override
  String levelUpDialogXpEarned(Object xpEarned) {
    return '+$xpEarned XP 已获得';
  }

  @override
  String get levelUpLevelUp => '升级！';

  @override
  String get levelUpWhatSNext => '接下来是什么';

  @override
  String get libraryLibrary => '库';

  @override
  String get libraryQuickAccessBrowseExercisesProgramsW => '浏览动作、计划和训练历史';

  @override
  String get libraryQuickAccessExerciseLibrary => '动作库';

  @override
  String get librarySearchExercises => '搜索动作...';

  @override
  String lifetimeMemberBadgeDaysUntil(
    Object daysRemaining,
    Object nextTierName,
  ) {
    return '距离 $nextTierName 还有 $daysRemaining 天';
  }

  @override
  String get lifetimeMemberBadgeEstimatedValueReceived => '预估已获价值';

  @override
  String get lifetimeMemberBadgeLifetime => '终身';

  @override
  String get lifetimeMemberBadgeLifetime2 => '终身';

  @override
  String get lifetimeMemberBadgeMember => '会员';

  @override
  String liquidBodyHydrationValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String get listWorkoutAddExercise => '添加动作';

  @override
  String get listWorkoutFinish => '完成';

  @override
  String get listWorkoutNoSetsCompleted => '未完成任何组数';

  @override
  String get listWorkoutYouHavenTCompleted => '你尚未完成任何组数。确定要结束吗？';

  @override
  String get liveChatAboutLiveChat => '关于在线客服';

  @override
  String get liveChatAreYouSureYou => '确定要结束本次对话吗？你可以稍后开启新对话。';

  @override
  String get liveChatConnectWithOurSupport =>
      '联系我们的支持团队获取实时帮助。我们的客服在工作时间内随时为你解答疑问或处理问题。';

  @override
  String get liveChatEndChat => '结束对话？';

  @override
  String get liveChatEndChat2 => '结束对话';

  @override
  String get liveChatFailedToConnectTo => '无法连接至支持团队';

  @override
  String get liveChatGotIt => '知道了';

  @override
  String get liveChatInputAttachFile => '添加附件';

  @override
  String get liveChatInputTypeAMessage => '输入消息...';

  @override
  String get liveChatLiveChat => '在线客服';

  @override
  String get liveChatMessageAgent => '客服';

  @override
  String get liveChatTryAgain => '重试';

  @override
  String get liveChatUnknownError => '未知错误';

  @override
  String get livePrSnackbarNewPr => '新的 PR！';

  @override
  String livePrSnackbarRm(
    Object oneRmStr,
    Object reps,
    Object unitLabel,
    Object weightStr,
  ) {
    return '$weightStr$unitLabel×$reps  →  $oneRmStr $unitLabel 1RM, ';
  }

  @override
  String livePrSnackbarValue(Object deltaStr, Object unitLabel) {
    return '+$deltaStr $unitLabel';
  }

  @override
  String localizedName(Object arg0) {
    return '本地化名称 $arg0';
  }

  @override
  String get locationSettingsAddALocationTo =>
      '将位置添加到你的健身房配置中以启用自动切换。编辑配置并点击“添加位置”。';

  @override
  String get locationSettingsAutoSwitchGymProfiles => '自动切换健身房配置';

  @override
  String get locationSettingsAutoSwitchNeedsAlways =>
      '自动切换功能需要“始终”允许位置访问权限，以便检测你何时到达健身房。';

  @override
  String get locationSettingsAutoSwitchProfiles => '自动切换配置';

  @override
  String get locationSettingsBackgroundLocationRequired => '需要后台位置权限';

  @override
  String get locationSettingsGrantPermission => '授予权限';

  @override
  String get locationSettingsLocationPermission => '位置权限';

  @override
  String locationSettingsSectionActiveForGymS(Object length) {
    return '对 $length 个健身房生效';
  }

  @override
  String locationSettingsSectionActiveForProfileS(Object length) {
    return '对 $length 个档案生效';
  }

  @override
  String get locationSettingsSetAPreferredWorkout =>
      '在健身房配置中设置首选训练时间，以启用基于时间的切换。';

  @override
  String get locationSettingsTapToGrantPermission => '点击以授予权限';

  @override
  String get locationSettingsTimeBasedSwitching => '基于时间的切换';

  @override
  String get locationSettingsYourLocationIsOnly => '你的位置仅在本地用于检查与已保存健身房的距离。';

  @override
  String get log1rmCurrent1rm => '当前 1RM：';

  @override
  String get log1rmEnterTheMaxWeight => '输入你完成 1 次重复的最大重量';

  @override
  String get log1rmEstimated1rm => '预估 1RM';

  @override
  String get log1rmLog1rm => '记录 1RM';

  @override
  String get log1rmNewPr => '新的 PR！';

  @override
  String get log1rmPleaseEnterAValid => '请输入有效的重量';

  @override
  String get log1rmPleaseEnterAValid2 => '请输入有效的重复次数';

  @override
  String get log1rmRepsCompleted => '已完成次数';

  @override
  String get log1rmRpeRateOfPerceived => 'RPE (主观疲劳程度)';

  @override
  String get log1rmSave1rm => '保存 1RM';

  @override
  String log1rmSheetKg(Object widget) {
    return '$widget kg';
  }

  @override
  String log1rmSheetRpe(Object _rpe) {
    return 'RPE $_rpe';
  }

  @override
  String get log1rmWeightKg => '重量 (kg)';

  @override
  String get logCardioActivityType => '活动类型';

  @override
  String get logCardioAvgHr => '平均心率';

  @override
  String get logCardioCaloriesBurned => '消耗卡路里';

  @override
  String get logCardioDistance => '距离';

  @override
  String get logCardioDuration => '时长';

  @override
  String get logCardioHowDidTheSession => '这次训练感觉如何？写点备注...';

  @override
  String get logCardioLocation => '位置';

  @override
  String get logCardioLogCardio => '记录有氧运动';

  @override
  String get logCardioMaxHr => '最大心率';

  @override
  String get logCardioOptionalDetails => '可选详情';

  @override
  String get logCardioSaveCardioSession => '保存有氧训练';

  @override
  String logCardioScreenSessionLogged(Object formattedDuration, Object label) {
    return '已记录$label训练 - $formattedDuration';
  }

  @override
  String get logCardioWeatherConditions => '天气状况';

  @override
  String get logMealAiEstimatedNutrition => 'AI 预估营养';

  @override
  String get logMealAllergens => '过敏原';

  @override
  String get logMealCalcium => '钙';

  @override
  String get logMealCalories => '卡路里';

  @override
  String get logMealCarbs => '碳水化合物';

  @override
  String get logMealDiscard => '放弃';

  @override
  String get logMealDiscardAnalysis => '放弃分析？';

  @override
  String get logMealEndFastLog => '结束断食并记录';

  @override
  String get logMealEndYourFast => '结束断食？';

  @override
  String get logMealFat => '脂肪';

  @override
  String get logMealFiber => '膳食纤维';

  @override
  String get logMealFoundProduct => '已找到产品';

  @override
  String get logMealHealth => '健康';

  @override
  String get logMealHelpersEcoScore => '生态评分 ';

  @override
  String logMealHelpersNova(Object group) {
    return 'NOVA $group ';
  }

  @override
  String get logMealHelpersNutriScore => '营养评分 ';

  @override
  String get logMealHelpersProcessingBreakdown => '加工分析';

  @override
  String logMealHelpersValue(Object count, Object label) {
    return '$label ($count)';
  }

  @override
  String get logMealInflammation => '炎症';

  @override
  String get logMealIngredients => '配料';

  @override
  String get logMealIron => '铁';

  @override
  String get logMealLogOnly => '仅记录';

  @override
  String get logMealLogThis => '记录此项';

  @override
  String get logMealLogThisMeal => '记录此餐';

  @override
  String get logMealLoggingThisMealWill => '记录此餐将结束您的断食。是否继续？';

  @override
  String get logMealMagnesium => '镁';

  @override
  String get logMealPotassium => '钾';

  @override
  String get logMealProtein => '蛋白质';

  @override
  String get logMealServings => '份量';

  @override
  String get logMealSheet => '  •  ';

  @override
  String get logMealSheetAdd => '添加';

  @override
  String get logMealSheetAddABitMore => '添加更多细节以优化结果。';

  @override
  String get logMealSheetAddAPhotoOr => '添加照片或描述餐食以进行分析。';

  @override
  String get logMealSheetAddPhotos => '添加照片';

  @override
  String get logMealSheetAddedTheFirst5 => '已添加前 5 张照片（上限）。';

  @override
  String get logMealSheetAiEstimatesFromA => '通过照片进行 AI 估算 — 您稍后可以优化结果。';

  @override
  String get logMealSheetAllItemsMatchedVerified => '所有项目均匹配已验证的营养数据';

  @override
  String get logMealSheetAnalysisFailed => '分析失败。请重试。';

  @override
  String get logMealSheetAnalyze => '分析';

  @override
  String get logMealSheetAnalyzing => '分析中…';

  @override
  String get logMealSheetAnythingElseInThe => '照片里还有其他东西吗？（例如亚麻籽、乳清蛋白）';

  @override
  String get logMealSheetBackToResults => '返回结果';

  @override
  String get logMealSheetAddSauceOrSide => 'Add a sauce or side?';

  @override
  String get logMealSheetAddSauceSide => 'Add sauce / item';

  @override
  String get logMealSheetBarcode => '条形码';

  @override
  String get logMealSheetBarcodeScan => '条形码扫描';

  @override
  String get logMealSheetCached => '（已缓存）';

  @override
  String get logMealSheetCaptured => '）已拍摄';

  @override
  String get logMealSheetChooseFoodPhotos => '选择食物照片';

  @override
  String get logMealSheetChooseFromGallery => '从相册选择';

  @override
  String get logMealSheetChooseFromLibrary => '从图库选择';

  @override
  String get logMealSheetChooseMenuPhotos => '选择菜单照片';

  @override
  String get logMealSheetCoach => '教练';

  @override
  String get logMealSheetConfirmAnalyze => '确认并分析';

  @override
  String logMealSheetCouldnTAddFood(Object message) {
    return '无法添加食物：$message';
  }

  @override
  String get logMealSheetCouldnTApplyThat => '无法应用该修正 — 餐食未更改。';

  @override
  String get logMealSheetCouldnTLogThose => '无法记录这些项目。请检查您的网络连接。';

  @override
  String get logMealSheetCouldnTRecognizeAny => '无法从该描述中识别出任何食物。';

  @override
  String logMealSheetCouldnTRefineError(Object message) {
    return '无法优化：$message';
  }

  @override
  String get logMealSheetCouldnTSaveYour => '无法保存您的餐食。请检查您的网络连接。';

  @override
  String get logMealSheetCustomEG1 => '自定义（例如 1.25）';

  @override
  String get logMealSheetDidnTCatchAny => '未识别到任何食物 — 请重试。';

  @override
  String get logMealSheetEGGrilledChicken => '例如“烤鸡肉碗，我吃了一半”';

  @override
  String get logMealSheetEnableMicrophoneAccessIn =>
      '请在设置中启用麦克风权限，或在搜索中输入餐食名称。';

  @override
  String get logMealSheetEstimatedNutrition => '预估营养';

  @override
  String get logMealSheetEstimatesBasedOnYour => '基于您的照片/描述进行估算';

  @override
  String logMealSheetFailedToSaveError(Object error) {
    return '保存失败：$error';
  }

  @override
  String get logMealSheetFrequentMeals => '常用餐食';

  @override
  String logMealSheetG(Object totalProtein) {
    return '${totalProtein}g';
  }

  @override
  String logMealSheetG2(Object totalCarbs) {
    return '${totalCarbs}g';
  }

  @override
  String logMealSheetG3(Object totalFat) {
    return '${totalFat}g';
  }

  @override
  String logMealSheetG4(Object totalFiber) {
    return '${totalFiber}g';
  }

  @override
  String logMealSheetG5(Object totalSugar) {
    return '${totalSugar}g';
  }

  @override
  String logMealSheetG6(Object vitaminA100g) {
    return '$vitaminA100g µg';
  }

  @override
  String logMealSheetG7(Object vitaminD100g) {
    return '$vitaminD100g µg';
  }

  @override
  String get logMealSheetHandsFreeLoggingSpeak =>
      '免提记录 — 自然说话，检查文字，然后确认。烹饪时非常方便。';

  @override
  String get logMealSheetHeardEditIfNeeded => '已识别 — 如有需要请编辑，然后确认';

  @override
  String get logMealSheetHowManyServingsDid => '您吃了多少份？';

  @override
  String get logMealSheetImportALogFrom => '从 MyFitnessPal、Cronometer 等导入记录…';

  @override
  String get logMealSheetInstructionsOptional => '说明（可选）';

  @override
  String logMealSheetKcal(Object totalCalories) {
    return '$totalCalories kcal';
  }

  @override
  String logMealSheetL2Kcal(Object calories, Object timesLogged) {
    return '~$calories kcal · $timesLogged×';
  }

  @override
  String logMealSheetL2Logged(Object timesLogged) {
    return '已记录 $timesLogged×';
  }

  @override
  String logMealSheetL2SetToForThe(Object label) {
    return '已设为 $label — 点击餐食胶囊即可更改。';
  }

  @override
  String logMealSheetL2YourUsual(Object label) {
    return '您平时的 $label';
  }

  @override
  String get logMealSheetListening => '正在聆听…';

  @override
  String get logMealSheetLogManually => '手动记录';

  @override
  String get logMealSheetLogThisMeal => '记录此餐';

  @override
  String logMealSheetLoggedItems(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已记录 $count 项',
      one: '已记录 1 项',
    );
    return '$_temp0';
  }

  @override
  String logMealSheetLoggedPhotos(num count, Object kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已记录 $count 张照片 ($kcal kcal)',
      one: '已记录 1 张照片 ($kcal kcal)',
    );
    return '$_temp0';
  }

  @override
  String get logMealSheetLooksRight => '看起来没问题';

  @override
  String get logMealSheetMealRefined => '餐食已优化';

  @override
  String get logMealSheetMenu => '菜单';

  @override
  String get logMealSheetMenuUpdated => '菜单已更新';

  @override
  String logMealSheetMg(Object vitaminC100g) {
    return '$vitaminC100g mg';
  }

  @override
  String logMealSheetMg2(Object calcium100g) {
    return '$calcium100g mg';
  }

  @override
  String logMealSheetMg3(Object iron100g) {
    return '$iron100g mg';
  }

  @override
  String logMealSheetMg4(Object potassium100g) {
    return '$potassium100g mg';
  }

  @override
  String logMealSheetMg5(Object magnesium100g) {
    return '$magnesium100g mg';
  }

  @override
  String logMealSheetMg6(Object zinc100g) {
    return '$zinc100g mg';
  }

  @override
  String get logMealSheetMicrophoneUnavailable => '麦克风不可用';

  @override
  String get logMealSheetNeedToAddNotes => '需要添加备注或多张照片？请使用“描述”。';

  @override
  String logMealSheetNutritionFor(Object servingsLabel) {
    return '$servingsLabel 的营养成分';
  }

  @override
  String get logMealSheetNutritionLabel => '营养标签';

  @override
  String get logMealSheetOneTapInstantNutrition => '一键获取即时营养信息';

  @override
  String get logMealSheetOverBudgetPickOne => '超出预算 — 请选择一项：';

  @override
  String get logMealSheetPhoto => '照片';

  @override
  String get logMealSheetPhotos => '照片';

  @override
  String get logMealSheetPickFromGallery => '从相册选择';

  @override
  String get logMealSheetPickUpTo5 => '从图库中最多选择 5 张';

  @override
  String get logMealSheetPlannedHighOutputDay => '已计划的高强度日 — 这是刻意安排的。';

  @override
  String get logMealSheetPortionsAdjustedReviewWei => '份量已调整 — 请查看下方的重量';

  @override
  String get logMealSheetReTakePhoto => '重新拍摄';

  @override
  String get logMealSheetReadMacrosOffA => '从包装食品标签上读取宏量营养素';

  @override
  String get logMealSheetRefine => '优化';

  @override
  String get logMealSheetReport => '报告';

  @override
  String get logMealSheetSavedToFavorites => '已保存到收藏夹！';

  @override
  String get logMealSheetSaving => '正在保存...';

  @override
  String get logMealSheetScan => '扫描';

  @override
  String get logMealSheetScanAppScreenshot => '扫描应用截图';

  @override
  String get logMealSheetScanFood => '扫描食物';

  @override
  String get logMealSheetScanImport => '扫描并导入';

  @override
  String get logMealSheetScanMenu => '扫描菜单';

  @override
  String get logMealSheetScanNutritionLabel => '扫描营养标签';

  @override
  String get logMealSheetScreenshot => '截图';

  @override
  String get logMealSheetSearchFoods => '搜索食物';

  @override
  String get logMealSheetSnapAPhoto => '拍张照片';

  @override
  String get logMealSheetSpeakNowTapMic => '请说话...点击麦克风停止';

  @override
  String get logMealSheetSpeechRecognitionNotAvailab => '语音识别不可用';

  @override
  String get logMealSheetStartingAnalysis => '正在开始分析...';

  @override
  String get logMealSheetStopListening => '停止聆听';

  @override
  String get logMealSheetTakeAPhoto => '拍张照片';

  @override
  String get logMealSheetTakeFoodPhoto => '拍摄食物照片';

  @override
  String get logMealSheetTakeMenuPhoto => '拍摄菜单照片';

  @override
  String get logMealSheetTakePhoto => '拍照';

  @override
  String get logMealSheetTapAgainWhenYou => '完成后再次点击';

  @override
  String get logMealSheetTapHereToSave => '点击此处将餐食保存到您的每日记录中。仅进行分析不会记录餐食！';

  @override
  String get logMealSheetTapToConfirmEach => '点击以确认每一项，或在下方列表中编辑数值。';

  @override
  String get logMealSheetTapToSpeak => '点击说话';

  @override
  String get logMealSheetTellTheAiAnything => '告诉AI任何有帮助的信息——如进食份量、替换食物、盘子大小等。';

  @override
  String get logMealSheetThatCorrectionProducedAn => '该修正导致餐食信息为空——已保留之前的估算值。';

  @override
  String get logMealSheetThatLooksLikeA => '这看起来像是一份食谱——请将其粘贴到食谱导入器中。';

  @override
  String get logMealSheetThisPhotoWasHard => '这张照片难以识别';

  @override
  String get logMealSheetTipAddBrandPortion =>
      '提示：添加品牌和份量以获得更准确的结果（例如：“Chipotle 鸡肉碗”或“2 片 Domino’s”）。';

  @override
  String get logMealSheetTryAgain => '重试';

  @override
  String get logMealSheetTypeItInstead => '改为手动输入';

  @override
  String logMealSheetUi1AddAnother(Object noun) {
    return '添加另一个 $noun';
  }

  @override
  String logMealSheetUi1ThatCorrectionLooksOff(Object cals) {
    return '该修正看起来不准确（$cals kcal）——已保留之前的估算值。';
  }

  @override
  String logMealSheetUi2GProteinLeft(Object proteinRemaining) {
    return '还剩 ${proteinRemaining}g 蛋白质';
  }

  @override
  String logMealSheetUi2KcalLeft(Object caloriesRemaining) {
    return '还剩 $caloriesRemaining kcal';
  }

  @override
  String logMealSheetUi2PickUpTo(Object remaining) {
    return '最多选择 $remaining';
  }

  @override
  String logMealSheetUi2Value(Object length) {
    return '$length/5';
  }

  @override
  String logMealSheetUiGProteinLeft(Object proteinRemaining) {
    return '剩余 $proteinRemaining 克蛋白质';
  }

  @override
  String logMealSheetUiKcalLeft(Object caloriesRemaining) {
    return '剩余 $caloriesRemaining 大卡';
  }

  @override
  String logMealSheetUiOfItemsMatchedVerified(
    Object length,
    Object verifiedCount,
  ) {
    return '$length 个项目中，有 $verifiedCount 个匹配了已验证的营养数据';
  }

  @override
  String logMealSheetUiValue(Object description) {
    return '\"$description\"';
  }

  @override
  String logMealSheetUiValue2(Object dateLabel) {
    return '$dateLabel：';
  }

  @override
  String get logMealSheetUndo => '撤销';

  @override
  String get logMealSheetUpTo5Pages => '最多 5 页同一菜单';

  @override
  String get logMealSheetUpTo5Photos => '最多 5 张照片——移除一张以添加更多。';

  @override
  String get logMealSheetUpTo5Shots => '最多 5 次拍摄——在照片之间添加另一张';

  @override
  String get logMealSheetUse => '使用';

  @override
  String logMealSheetValue(Object servingLabel) {
    return '× $servingLabel';
  }

  @override
  String get logMealSheetVoiceInput => '语音输入';

  @override
  String get logMealSheetWhatDidYouEat => '你吃了什么？';

  @override
  String logMealSheetYouVeBeenFasting(Object elapsedHours, Object elapsedMins) {
    return '你已经断食 $elapsedHours 小时 $elapsedMins 分钟。';
  }

  @override
  String get logMealSugar => '糖';

  @override
  String get logMealTheseValuesAreAi => '这些数值是基于您的描述得出的 AI 估算值。';

  @override
  String get logMealVitaminA => '维生素 A';

  @override
  String get logMealVitaminC => '维生素 C';

  @override
  String get logMealVitaminD => '维生素 D';

  @override
  String get logMealVitaminsMinerals => '维生素与矿物质';

  @override
  String get logMealYouHavenTLogged => '您尚未记录此餐食。您的分析结果将会丢失。';

  @override
  String get logMealZinc => '锌';

  @override
  String get logMeasurementAnyNotesAboutThis => '关于此测量值的任何备注...';

  @override
  String get logMeasurementLogMeasurements => '记录测量值';

  @override
  String get logMeasurementMeasurementDate => '测量日期';

  @override
  String get logMeasurementMeasurementsSaved => '测量值已保存！';

  @override
  String get logMeasurementPleaseEnterAtLeast => '请输入至少一个测量值';

  @override
  String logMeasurementSheetFailedToSave(Object e) {
    return '保存失败：$e';
  }

  @override
  String get logPeriodEndDateOptional => '结束日期（可选）';

  @override
  String get logPeriodEndToday => '今天结束';

  @override
  String get logPeriodLogANewPeriod => '记录新经期';

  @override
  String get logPeriodLogPeriod => '记录经期';

  @override
  String get logPeriodOrStartANew => '— 或开始新经期 —';

  @override
  String get logPeriodPeriodInProgress => '经期进行中';

  @override
  String get logPeriodPeriodLogged => '经期已记录';

  @override
  String get logPeriodSavePeriod => '保存经期';

  @override
  String get logPeriodSaving => '正在保存...';

  @override
  String logPeriodSheetCouldNotSave(Object e) {
    return '保存失败：$e';
  }

  @override
  String logPeriodSheetStarted(Object cycleDates) {
    return '开始于 $cycleDates';
  }

  @override
  String logPeriodSheetWithNoEnd(Object cycleDates) {
    return '$cycleDates 无结束日期';
  }

  @override
  String get logPeriodStartDateDay1 => '开始日期（第 1 天）';

  @override
  String get logWeightAddANoteOptional => '添加备注（可选）';

  @override
  String get logWeightBodyFatDidnT => '体脂率未保存——体重已记录';

  @override
  String get logWeightBodyFatOptional => '体脂率 %（可选）';

  @override
  String get logWeightContext => '背景信息';

  @override
  String get logWeightCurrent => '当前';

  @override
  String get logWeightEG185 => '例如 18.5';

  @override
  String get logWeightEnterWeight => '输入体重';

  @override
  String get logWeightHideDetails => '隐藏详情';

  @override
  String get logWeightIfThisWasA => '如果这是一个错误，请用正确的体重重新记录。';

  @override
  String get logWeightLogWeight => '记录体重';

  @override
  String get logWeightMoreDetails => '更多详情';

  @override
  String get logWeightSaving => '正在保存...';

  @override
  String logWeightSheetDAvg(Object avgDisplay, Object label) {
    return '7天平均 · $avgDisplay $label';
  }

  @override
  String logWeightSheetFromYourPreviousLow(Object _selectedUnit, Object label) {
    return '-$_selectedUnit $label，低于您之前的最低记录';
  }

  @override
  String logWeightSheetValidRange(
    Object label,
    Object maxValue,
    Object minValue,
  ) {
    return '有效范围：$minValue-$maxValue $label';
  }

  @override
  String logWeightSheetValue(Object changeInUnit) {
    return '$changeInUnit';
  }

  @override
  String get logWeightSyncedFromAppleHealth => '已从 Apple Health 同步';

  @override
  String get logWeightSyncedToAppleHealth => '已同步至 Apple Health';

  @override
  String get logWeightTapToEdit => '点击编辑';

  @override
  String get logWeightViewChart => '查看图表';

  @override
  String get logWeightWeightChart => '体重图表';

  @override
  String get logWeightWeightHistory => '体重历史';

  @override
  String get logWeightWeightUpdate => '体重更新';

  @override
  String get loggedMeals => '⚠️';

  @override
  String get loggedMeals1U00bc => '1¼';

  @override
  String get loggedMeals1U00bd => '1½';

  @override
  String get loggedMeals1x => '1x';

  @override
  String get loggedMeals2x => '2x';

  @override
  String get loggedMeals3x => '3x';

  @override
  String get loggedMealsAddItem => '添加项目';

  @override
  String get loggedMealsAddNote => '添加备注';

  @override
  String get loggedMealsAddNote2 => '添加备注';

  @override
  String get loggedMealsAddThisToShopping => '添加到购物清单';

  @override
  String get loggedMealsAddToShoppingList => '添加到购物清单';

  @override
  String get loggedMealsAdjustPortion => '调整份量';

  @override
  String get loggedMealsAdjustPortion2 => '调整份量';

  @override
  String get loggedMealsAfterEating => '餐后';

  @override
  String get loggedMealsAmount => '数量';

  @override
  String get loggedMealsBeforeEating => '餐前';

  @override
  String get loggedMealsCG => '碳水 (g)';

  @override
  String get loggedMealsCal => '卡路里';

  @override
  String get loggedMealsCarbs => '碳水化合物';

  @override
  String get loggedMealsContainsUltraProcessedItems => '包含超加工食品';

  @override
  String get loggedMealsCopyTo => '复制到...';

  @override
  String get loggedMealsCopyToAnotherMeal => '复制到另一餐';

  @override
  String get loggedMealsCurrent => '当前';

  @override
  String get loggedMealsDeleteMeal => '删除餐食';

  @override
  String get loggedMealsDouble => '双倍';

  @override
  String get loggedMealsEGAteAt => '例如：在餐厅吃、自制...';

  @override
  String get loggedMealsEGMedium1 => '例如：中份、1杯、350毫升';

  @override
  String get loggedMealsEGSideSalad => '例如：配菜沙拉';

  @override
  String get loggedMealsEGSweetTea => '例如：甜茶';

  @override
  String get loggedMealsEdit => '编辑';

  @override
  String get loggedMealsEditNote => '编辑备注';

  @override
  String get loggedMealsEditPortion => '编辑份量';

  @override
  String get loggedMealsEditTargets => '编辑目标';

  @override
  String get loggedMealsEditTime => '编辑时间';

  @override
  String get loggedMealsEnergyLevel => '能量水平';

  @override
  String get loggedMealsExamplesSoftDrinksInstant =>
      '示例：软饮料、方便面、包装零食、鸡块、大多数早餐麦片。';

  @override
  String get loggedMealsFG => '脂肪 (g)';

  @override
  String get loggedMealsFat => '脂肪';

  @override
  String get loggedMealsFodmap => 'FODMAP';

  @override
  String get loggedMealsFoodName => '食物名称';

  @override
  String get loggedMealsHealthScore => '健康评分';

  @override
  String get loggedMealsHideEditHistory => '隐藏编辑历史';

  @override
  String get loggedMealsHowDidYouFeel => '感觉如何？';

  @override
  String get loggedMealsInflammationScore => '炎症评分';

  @override
  String get loggedMealsLarge => '大份';

  @override
  String get loggedMealsLogAgainTomorrow => '明天再次记录';

  @override
  String get loggedMealsLogMoodEnergy => '记录心情与能量';

  @override
  String get loggedMealsLogThisAgainTomorrow => '明天再次记录此项';

  @override
  String get loggedMealsLooksOffTapTo => '看起来不对 — 点击确认';

  @override
  String get loggedMealsLowerIsBetterFor => '数值越低，越有助于减少身体炎症和改善肠道健康。';

  @override
  String get loggedMealsMedium => '中份';

  @override
  String get loggedMealsMicronutrients => '微量营养素';

  @override
  String get loggedMealsMoveTo => '移动到...';

  @override
  String get loggedMealsMoveToAnotherMeal => '移动到另一餐';

  @override
  String get loggedMealsNoEditsYet => '暂无编辑记录';

  @override
  String get loggedMealsNoFoodsLogged => '未记录食物';

  @override
  String get loggedMealsNutritionEditIfThe => '营养成分（如果AI识别错误请编辑）';

  @override
  String get loggedMealsPG => '蛋白质 (g)';

  @override
  String get loggedMealsProtein => '蛋白质';

  @override
  String get loggedMealsQuantity => '数量';

  @override
  String get loggedMealsRatesHowInflammatoryA =>
      '根据加工水平、脂肪构成、含糖量、纤维和抗氧化特性，评估食物的致炎性。';

  @override
  String get loggedMealsRemove => '移除';

  @override
  String get loggedMealsRemoveFromMeal => '从餐食中移除';

  @override
  String loggedMealsRemovedItem(Object name) {
    return '已移除 $name';
  }

  @override
  String get loggedMealsReportIncorrectData => '报告错误数据';

  @override
  String get loggedMealsResearchLinksRegularConsump =>
      '研究表明，经常食用此类食物与炎症、肥胖、心脏病和消化系统问题增加有关。';

  @override
  String get loggedMealsSaveAsRecipe => '保存为食谱';

  @override
  String get loggedMealsSaveToMyFoods => '保存到我的食物';

  @override
  String get loggedMealsScheduleRecurring => '设置重复提醒...';

  @override
  String loggedMealsSectionCal(Object target, Object totalCaloriesEaten) {
    return '$totalCaloriesEaten / $target 卡路里';
  }

  @override
  String loggedMealsSectionCal2(Object calories) {
    return '$calories 卡路里';
  }

  @override
  String loggedMealsSectionCal3(Object food) {
    return '$food 大卡';
  }

  @override
  String loggedMealsSectionCopyTo(Object name) {
    return '复制 $name 到...';
  }

  @override
  String loggedMealsSectionEaten(Object totalCaloriesEaten) {
    return '已摄入 $totalCaloriesEaten';
  }

  @override
  String loggedMealsSectionG(Object proteinG) {
    return '${proteinG}g';
  }

  @override
  String loggedMealsSectionG2(Object carbsG) {
    return '${carbsG}g';
  }

  @override
  String loggedMealsSectionG3(Object fatG) {
    return '${fatG}g';
  }

  @override
  String loggedMealsSectionG4(Object consumed, Object target) {
    return '$consumed/${target}g';
  }

  @override
  String loggedMealsSectionG5(Object consumed) {
    return '${consumed}g';
  }

  @override
  String loggedMealsSectionGC(Object totalCarbs) {
    return '${totalCarbs}g 碳水';
  }

  @override
  String loggedMealsSectionGF(Object totalFat) {
    return '${totalFat}g 脂肪';
  }

  @override
  String loggedMealsSectionGP(Object totalProtein) {
    return '${totalProtein}g 蛋白质';
  }

  @override
  String loggedMealsSectionGProtein(Object proteinG) {
    return '${proteinG}g 蛋白质';
  }

  @override
  String loggedMealsSectionGProtein2(Object food) {
    return '${food}g 蛋白质';
  }

  @override
  String loggedMealsSectionGl(Object glycemicLoad) {
    return 'GL $glycemicLoad';
  }

  @override
  String loggedMealsSectionKcal(Object totalCalories) {
    return '$totalCalories kcal';
  }

  @override
  String loggedMealsSectionKcal2(Object totalCalories) {
    return '$totalCalories kcal';
  }

  @override
  String loggedMealsSectionMoveTo(Object name) {
    return '移动 $name 到...';
  }

  @override
  String loggedMealsSectionRemoved2(Object removedName) {
    return '已移除 $removedName';
  }

  @override
  String loggedMealsSectionRemoved3(Object name) {
    return '已移除 $name';
  }

  @override
  String loggedMealsSectionSwap(Object existingName) {
    return '替换 $existingName';
  }

  @override
  String loggedMealsSectionValue(Object energyLevel) {
    return '$energyLevel/5';
  }

  @override
  String loggedMealsSectionValue2(Object energyLevel) {
    return '$energyLevel/5';
  }

  @override
  String loggedMealsSectionValue3(Object key) {
    return '$key: ';
  }

  @override
  String loggedMealsSectionValue4(Object dateStr) {
    return '($dateStr)';
  }

  @override
  String loggedMealsSectionVia(Object label) {
    return '通过 $label';
  }

  @override
  String get loggedMealsServings => '份数';

  @override
  String get loggedMealsSetACalorieTarget => '设置卡路里目标以追踪剩余摄入量';

  @override
  String get loggedMealsShareMeal => '分享餐食';

  @override
  String get loggedMealsSmall => '小份';

  @override
  String get loggedMealsStandard => '标准';

  @override
  String get loggedMealsSwapItem => '更换项目';

  @override
  String get loggedMealsTriple => '三倍';

  @override
  String get loggedMealsTypeAFoodAnd => '输入食物名称并点击AI自动填充宏量营养素';

  @override
  String get loggedMealsU00bd => '½';

  @override
  String get loggedMealsU00be => '¾';

  @override
  String get loggedMealsUltraProcessedFoods => '超加工食品';

  @override
  String get loggedMealsUltraProcessedFoodsNova =>
      '超加工食品（NOVA第4组）含有工业添加剂，如乳化剂、氢化油、人工甜味剂和蛋白质分离物——这些物质在家庭烹饪中并不常见。';

  @override
  String get loggedMealsUndo => '撤销';

  @override
  String get loggedMealsViewEditHistory => '查看编辑历史';

  @override
  String get loggedMealsWeight => '重量';

  @override
  String get loggedMealsXLarge => '特大份';

  @override
  String get logoutAreYouSureYou => '确定要退出登录吗？您可以随时重新登录。';

  @override
  String get logoutSignOut => '退出登录';

  @override
  String get logoutSignOut2 => '退出登录？';

  @override
  String macroRingsCardGG(Object consumed, Object target) {
    return '${consumed}g / ${target}g';
  }

  @override
  String get macroRingsCardMacros => '宏量营养素';

  @override
  String mainShellPartChatsLeftToday(Object arg0) {
    return '今日剩余聊天次数 $arg0';
  }

  @override
  String get mainShellPartGuestMode => '访客模式';

  @override
  String get mainShellPartQuickActions => '快捷操作';

  @override
  String get mainShellPartSignUp => '注册';

  @override
  String get mainShellPartSignUpFreeFor => '注册即可免费获取无限访问权限';

  @override
  String get manageDuplicateImportsCouldNotLoadDuplicate => '无法加载重复导入项';

  @override
  String get manageDuplicateImportsDuplicateImports => '重复导入项';

  @override
  String get manageDuplicateImportsHidden => '已隐藏';

  @override
  String get manageDuplicateImportsMakeThisPrimary => '设为主要项';

  @override
  String get manageDuplicateImportsNoDuplicateImportsDetected => '未检测到重复导入项';

  @override
  String get manageDuplicateImportsPrimary => '主要项';

  @override
  String manageDuplicateImportsScreenSources(Object length) {
    return '$length 个来源';
  }

  @override
  String manageDuplicateImportsScreenValue(Object primary) {
    return '$primary · ';
  }

  @override
  String manageDuplicateImportsScreenValue2(Object row) {
    return '$row';
  }

  @override
  String get manageDuplicateImportsUnlinkFromGroup => '从组中取消关联';

  @override
  String get manageDuplicateImportsUnlinkedFromGroup => '已从组中取消关联';

  @override
  String get manageGymProfilesActive => '活跃';

  @override
  String get manageGymProfilesAddNewGym => '添加新健身房';

  @override
  String get manageGymProfilesDeleteGymProfile => '删除健身房资料？';

  @override
  String get manageGymProfilesDragToReorderTap => '拖动以排序 • 点击以编辑';

  @override
  String get manageGymProfilesDuplicate => '复制';

  @override
  String get manageGymProfilesManageGyms => '管理健身房';

  @override
  String get manageGymProfilesNoGymProfilesYet => '暂无健身房资料';

  @override
  String get manageGymProfilesSetAsActive => '设为活跃';

  @override
  String manageGymProfilesSheetAreYouSureYou(Object name) {
    return '确定要删除“$name”吗？';
  }

  @override
  String manageGymProfilesSheetCreated(Object name) {
    return '已创建“$name”';
  }

  @override
  String manageGymProfilesSheetDeleted(Object name) {
    return '已删除“$name”';
  }

  @override
  String manageGymProfilesSheetEquipment(
    Object environmentDisplayName,
    Object equipmentCount,
  ) {
    return '$equipmentCount 件器械 • $environmentDisplayName';
  }

  @override
  String get managedGymCardActive => '活跃';

  @override
  String managedGymCardGymProfilesTapTo(Object profileCount) {
    return '$profileCount 个健身房配置 · 点击切换';
  }

  @override
  String get markFastingDay12h => '12h';

  @override
  String get markFastingDayEstimatedHours => '预计时长';

  @override
  String get markFastingDayFastingDuration => '断食时长';

  @override
  String get markFastingDayFastingProtocol => '断食方案';

  @override
  String get markFastingDayForgotToTrackA => '忘记记录断食了？标记过去的一天为断食日。';

  @override
  String get markFastingDayHowDidTheFast => '断食感觉如何？';

  @override
  String get markFastingDayMarkAsFastingDay => '标记为断食日';

  @override
  String get markFastingDayMarkFastingDay => '标记断食日';

  @override
  String get markFastingDayNotesOptional => '备注（可选）';

  @override
  String get markFastingDaySelectDate => '选择日期';

  @override
  String markFastingDaySheetHours(Object _estimatedHours) {
    return '$_estimatedHours小时';
  }

  @override
  String get markFastingDayYouCanMarkDays => '您可以标记过去 30 天内的日期';

  @override
  String masteriesGridLv(Object level) {
    return 'Lv.$level';
  }

  @override
  String get masteriesGridYourMasteriesWillLevel =>
      '随着您记录锻炼、步数和有氧运动，您的精通等级将会提升。';

  @override
  String get mealPlannerAddARecipe => '添加食谱';

  @override
  String get mealPlannerApply => '应用';

  @override
  String get mealPlannerCarbs => '碳水化合物';

  @override
  String get mealPlannerCoachReview => '教练评估';

  @override
  String get mealPlannerCustomItems => '自定义项目';

  @override
  String get mealPlannerEmptyTapToAdd => '（空 — 点击 + 添加）';

  @override
  String get mealPlannerFat => '脂肪';

  @override
  String get mealPlannerGrocery => '杂货';

  @override
  String get mealPlannerMacroProjection => '宏量营养素预测';

  @override
  String get mealPlannerPlanDay => '计划全天饮食';

  @override
  String get mealPlannerProtein => '蛋白质';

  @override
  String get mealPlannerRecipe => '食谱';

  @override
  String get mealPlannerSaveAsTemplate => '保存为模板';

  @override
  String get mealPlannerSavedAsTemplate => '已保存为模板';

  @override
  String mealPlannerScreenG(Object current, Object target) {
    return '$current / $target g';
  }

  @override
  String mealPlannerScreenKcal(Object r) {
    return '$r kcal';
  }

  @override
  String mealPlannerScreenLoggedItemS(Object length) {
    return '已记录 $length 个项目';
  }

  @override
  String mealPlannerScreenServings(Object servings) {
    return '×$servings 份';
  }

  @override
  String get mealPlannerSearchYourRecipes => '搜索您的食谱…';

  @override
  String get mealPlannerType2Chars => '输入 2 个以上字符';

  @override
  String get mealRemindersSettingsActiveSchedules => '活跃计划';

  @override
  String get mealRemindersSettingsAutoSnapshotRecipeVersions => '自动快照食谱版本';

  @override
  String get mealRemindersSettingsDeleteSchedule => '删除计划？';

  @override
  String get mealRemindersSettingsMealReminderNotifications => '用餐提醒通知';

  @override
  String get mealRemindersSettingsMealReminders => '用餐提醒';

  @override
  String get mealRemindersSettingsNoSchedulesYetAdd => '暂无计划。请从食谱详情页面添加。';

  @override
  String get mealRemindersSettingsPublicSharingDefault => '默认公开分享';

  @override
  String mealRemindersSettingsScreenCouldnTLoadSchedules(Object e) {
    return '无法加载日程：$e';
  }

  @override
  String mealRemindersSettingsScreenReminder(Object value) {
    return '$value 个提醒';
  }

  @override
  String get mealRemindersSettingsSignInToSee => '登录以查看您的计划。';

  @override
  String get mealScoreWidgetsGoalFit => '目标契合度';

  @override
  String get mealScoreWidgetsHealth => '健康度';

  @override
  String mealScoreWidgetsValue(Object score) {
    return '$score/10';
  }

  @override
  String get measurementBodyMoreMetrics => '更多指标';

  @override
  String measurementBodyViewMore(Object length) {
    return '+$length 更多';
  }

  @override
  String get measurementDetailAddAnyNotes => '添加备注...';

  @override
  String get measurementDetailAddEntry => '添加条目';

  @override
  String get measurementDetailAvg => '平均值';

  @override
  String get measurementDetailDeleteEntry => '删除条目？';

  @override
  String get measurementDetailHistory => '历史记录';

  @override
  String get measurementDetailImperial => '英制';

  @override
  String get measurementDetailMax => '最大值';

  @override
  String get measurementDetailMetric => '公制';

  @override
  String get measurementDetailMin => '最小值';

  @override
  String get measurementDetailNoDataInThis => '此范围内无数据';

  @override
  String get measurementDetailNotesOptional => '备注（可选）';

  @override
  String get measurementDetailPleaseEnterAValid => '请输入有效数字';

  @override
  String get measurementDetailPleaseEnterAValue => '请输入数值';

  @override
  String measurementDetailScreenCouldnTSaveTry(Object displayName) {
    return '无法保存 $displayName。请重试。';
  }

  @override
  String measurementDetailScreenEntries(Object length) {
    return '$length 条记录';
  }

  @override
  String measurementDetailScreenLog(Object displayName) {
    return '记录 $displayName';
  }

  @override
  String measurementDetailScreenLog2(Object displayName) {
    return '记录 $displayName';
  }

  @override
  String get measurementDetailScreenMonthly => '月度';

  @override
  String get measurementDetailScreenNoHistoryYet => '暂无历史记录';

  @override
  String measurementDetailScreenRecorded(Object displayName) {
    return '已记录 $displayName';
  }

  @override
  String get measurementDetailScreenRelatedMetrics => '相关指标';

  @override
  String get measurementDetailScreenTrends => '趋势';

  @override
  String measurementDetailScreenUiSourceGuideline(Object source) {
    return '来源：$source 指南';
  }

  @override
  String measurementDetailScreenUiTrend(Object displayName) {
    return '$displayName 趋势';
  }

  @override
  String get measurementDetailScreenWeekly => '每周';

  @override
  String get measurementDetailTrends => '趋势';

  @override
  String get measurementDetailTrySelectingAWider => '尝试选择更长的时间范围或记录新数据';

  @override
  String get measurementDetailViewTrends => '查看趋势';

  @override
  String get measurementValuePillCouldNotSaveTry => '无法保存，请重试';

  @override
  String get measurementsAddEntry => '添加记录';

  @override
  String get measurementsAddMeasurement => '添加测量数据';

  @override
  String get measurementsDeleteEntry => '删除记录？';

  @override
  String get measurementsFailedToLoadData => '加载数据失败';

  @override
  String get measurementsImperial => '英制';

  @override
  String get measurementsLogAgainToSee => '再次记录以查看趋势';

  @override
  String get measurementsMeasurements => '测量数据';

  @override
  String get measurementsMetric => '公制';

  @override
  String measurementsScreenCouldnTSaveTry(Object displayName) {
    return '无法保存 $displayName。请重试。';
  }

  @override
  String measurementsScreenEntries(Object measurementsState) {
    return '$measurementsState 条记录';
  }

  @override
  String measurementsScreenHistory(Object displayName) {
    return '历史记录 - $displayName';
  }

  @override
  String measurementsScreenNoDataYet(Object displayName) {
    return '暂无 $displayName 数据';
  }

  @override
  String get measurementsScreenPartAddAnyNotes => '添加备注...';

  @override
  String measurementsScreenPartAddMeasurementSheetExportMeasurementTypesAs(
    Object _selectedFormat,
    Object length,
  ) {
    return '导出 (length)\") 测量类型为 .(_selectedFormat)';
  }

  @override
  String measurementsScreenPartAddMeasurementSheetLog(Object displayName) {
    return '记录 $displayName';
  }

  @override
  String get measurementsScreenPartAvailableMeasurementTypes => '可用测量类型';

  @override
  String get measurementsScreenPartClear => '清除';

  @override
  String get measurementsScreenPartDateRange => '日期范围';

  @override
  String get measurementsScreenPartDeselectAll => '取消全选';

  @override
  String get measurementsScreenPartExportAllData => '导出所有数据';

  @override
  String get measurementsScreenPartExportInfo => '导出信息';

  @override
  String get measurementsScreenPartExportMeasurements => '导出测量数据';

  @override
  String get measurementsScreenPartExportedColumns => '已导出列';

  @override
  String get measurementsScreenPartFormat => '格式';

  @override
  String get measurementsScreenPartFormats => '格式';

  @override
  String get measurementsScreenPartGotIt => '知道了';

  @override
  String get measurementsScreenPartImperial => '英制';

  @override
  String get measurementsScreenPartMeasurementType => '测量类型';

  @override
  String get measurementsScreenPartMeasurements => '测量数据';

  @override
  String get measurementsScreenPartMeasurementsOnly => '仅测量数据';

  @override
  String get measurementsScreenPartMetric => '公制';

  @override
  String get measurementsScreenPartNotesOptional => '备注（可选）';

  @override
  String get measurementsScreenPartPleaseEnterAValid => '请输入有效数字';

  @override
  String get measurementsScreenPartPleaseEnterAValue => '请输入数值';

  @override
  String get measurementsScreenPartSelectAll => '全选';

  @override
  String get measurementsScreenPartWeightBodyFatChest =>
      '体重, 体脂, 胸围, 腰围, 臀围, 颈围, 肩宽, 左二头肌, 右二头肌, 左前臂, 右前臂, 左大腿, 右大腿, 左小腿, 右小腿';

  @override
  String get measurementsScreenPartWorkoutsNutritionMeasureme =>
      '训练、营养、测量数据及更多';

  @override
  String measurementsScreenRecorded(Object displayName) {
    return '已记录 $displayName';
  }

  @override
  String get measurementsScreenUiNoData => '暂无数据';

  @override
  String get measurementsScreenUiNoHistoryYet => '暂无历史记录';

  @override
  String measurementsTabCouldnTSaveTry(Object displayName) {
    return '无法保存 $displayName。请重试。';
  }

  @override
  String measurementsTabLog(Object displayName) {
    return '记录 $displayName';
  }

  @override
  String measurementsTabLogToSeeTrends(Object displayName) {
    return '记录 $displayName 以查看趋势';
  }

  @override
  String measurementsTabNoLogsInLast(Object displayName, Object periodLabel) {
    return '最近 $periodLabel 内无 $displayName 记录';
  }

  @override
  String get measurementsTabUiChooseMetric => '选择指标';

  @override
  String get measurementsTabUiNoData => '暂无数据';

  @override
  String measurementsTabUiValue(Object unit) {
    return '— $unit';
  }

  @override
  String measurementsTabValue(Object unit) {
    return '— $unit';
  }

  @override
  String get measurementsTakingLongerThanExpected => '加载时间比预期长...';

  @override
  String get measurementsViewAll => '查看全部';

  @override
  String mediaPickerHelperAccessHasBeenPermanently(Object permissionName) {
    return '$permissionName 访问权限已被永久拒绝。';
  }

  @override
  String get mediaPickerHelperAddMedia => '添加媒体';

  @override
  String get mediaPickerHelperCameraPermissionRequired => '需要相机权限';

  @override
  String get mediaPickerHelperChooseMultiplePhotos => '选择多张照片';

  @override
  String get mediaPickerHelperChoosePhoto => '选择照片';

  @override
  String get mediaPickerHelperChooseVideo => '选择视频';

  @override
  String get mediaPickerHelperCompressingVideo => '正在压缩视频...';

  @override
  String get mediaPickerHelperFromGallery => '从相册选择';

  @override
  String get mediaPickerHelperFromGalleryMax60s => '从相册选择（最长60秒）';

  @override
  String get mediaPickerHelperImagesMax10Mb => '图片：最大10 MB | 视频：最大60秒（测试版）';

  @override
  String get mediaPickerHelperOpenSettings => '打开设置';

  @override
  String mediaPickerHelperPermissionRequired(Object permissionName) {
    return '需要 $permissionName 权限';
  }

  @override
  String get mediaPickerHelperPhotoLibraryPermissionRequi => '需要相册权限';

  @override
  String get mediaPickerHelperRecordVideo => '录制视频';

  @override
  String get mediaPickerHelperSelectUpTo5 => '从相册最多选择5个';

  @override
  String get mediaPickerHelperTakePhoto => '拍摄照片';

  @override
  String get mediaPickerHelperUseCamera => '使用相机';

  @override
  String get mediaPickerHelperUseCameraMax60s => '使用相机（最长60秒）';

  @override
  String get mediaPickerHelperVideo => '视频';

  @override
  String get mediaPreviewStripMediaRemoved => '媒体已移除';

  @override
  String get mediaPreviewStripRemove => '移除';

  @override
  String get mediaPreviewStripUndo => '撤销';

  @override
  String get medicalDisclaimerAiRecommendations => 'AI 建议';

  @override
  String get medicalDisclaimerAlwaysSeekTheAdvice =>
      '在开始任何新的锻炼计划之前，请务必咨询您的医生或其他合格的医疗保健提供者，特别是如果您有任何既往病史、受伤或健康问题。切勿因为在此应用中阅读的内容而忽视专业的医疗建议或延迟就医。';

  @override
  String get medicalDisclaimerAssumptionOfRisk => '风险承担';

  @override
  String get medicalDisclaimerBannerAiGeneratedContentNot => 'AI 生成内容 - 非医疗建议';

  @override
  String get medicalDisclaimerConsultYourDoctor => '咨询您的医生';

  @override
  String get medicalDisclaimerImportantHealthNotice => '重要健康提示';

  @override
  String get medicalDisclaimerListenToYourBody => '倾听您的身体';

  @override
  String get medicalDisclaimerMedicalDisclaimer => '医疗免责声明';

  @override
  String get medicalDisclaimerNotMedicalAdvice => '非医疗建议';

  @override
  String medicalDisclaimerScreenByContinuingToUse(Object appName) {
    return '继续使用 $appName 即表示您已阅读并理解本免责声明。';
  }

  @override
  String medicalDisclaimerScreenPhysicalExerciseInvolvesInherent(
    Object appName,
  ) {
    return '体育锻炼存在固有风险。使用 $appName 即表示您承认您是自愿参加体育活动，并承担与此类活动相关的所有风险，包括但不限于受伤、疾病或死亡。';
  }

  @override
  String medicalDisclaimerScreenPleaseReadThisDisclaimer(Object appName) {
    return '在使用 $appName 前，请仔细阅读本免责声明。';
  }

  @override
  String medicalDisclaimerScreenProvidesAiGeneratedFitness(Object appName) {
    return '$appName 提供的 AI 生成健身建议仅供参考和教育目的。本应用提供的内容不旨在替代专业的医疗建议、诊断或治疗。';
  }

  @override
  String get medicalDisclaimerStopExercisingImmediatelyIf =>
      '如果您感到疼痛、头晕、气短、恶心或任何超出正常运动强度的不适，请立即停止锻炼。AI 无法实时评估您的身体状况，因此您有责任在自身能力范围内进行锻炼。';

  @override
  String get medicalDisclaimerWorkoutRecommendationsAreGe =>
      '锻炼建议是根据您提供的信息（健身水平、目标、设备等）生成的。虽然 AI 力求准确，但无法考虑所有个人因素。建议可能并不适合所有人。';

  @override
  String get menuAnalysisAddFood => '添加食物';

  @override
  String get menuAnalysisAdding => '正在添加...';

  @override
  String get menuAnalysisAddressOptional => '地址（可选）';

  @override
  String get menuAnalysisAlreadySaved => '已保存';

  @override
  String get menuAnalysisAutoDetectedFromThe => '已从菜单自动识别 — 如有错误请编辑';

  @override
  String get menuAnalysisCal => '卡路里';

  @override
  String get menuAnalysisCarbs => '碳水化合物';

  @override
  String get menuAnalysisClearAll => '全部清除';

  @override
  String get menuAnalysisClearFilters => '清除筛选';

  @override
  String get menuAnalysisCouldnTRecognizeAny => '无法识别描述中的任何食物。';

  @override
  String get menuAnalysisEG123Main => '例如：123 Main St，或直接输入“市中心”';

  @override
  String get menuAnalysisEGIndianPlace => '例如：工作附近的印度餐厅';

  @override
  String get menuAnalysisEditSavedMenu => '编辑已保存菜单';

  @override
  String get menuAnalysisFat => '脂肪';

  @override
  String get menuAnalysisHistoryAddAddress => '添加地址';

  @override
  String get menuAnalysisHistoryAddressOptional => '地址（可选）';

  @override
  String get menuAnalysisHistoryClearSearch => '清除搜索';

  @override
  String get menuAnalysisHistoryCouldnTLoadYour => '无法加载您保存的菜单';

  @override
  String get menuAnalysisHistoryEG123Main => '例如：123 Main St，或直接输入“市中心”';

  @override
  String get menuAnalysisHistoryEGIndianPlace => '例如：工作附近的印度餐厅';

  @override
  String get menuAnalysisHistoryEditDetails => '编辑详情';

  @override
  String get menuAnalysisHistoryName => '名称';

  @override
  String get menuAnalysisHistoryNoMatchingMenus => '没有匹配的菜单';

  @override
  String get menuAnalysisHistoryNoSavedMenusYet => '暂无已保存的菜单';

  @override
  String get menuAnalysisHistoryPin => '置顶';

  @override
  String get menuAnalysisHistorySavedMenus => '已保存菜单';

  @override
  String menuAnalysisHistoryScreenItems(Object length, Object type) {
    return '$length 项 · $type';
  }

  @override
  String menuAnalysisHistoryScreenNothingMatchedTryAnother(Object query) {
    return '未找到匹配 \"$query\" 的结果。请尝试其他搜索词。';
  }

  @override
  String get menuAnalysisHistorySearchByNameRestaurant => '按名称、餐厅或地址搜索';

  @override
  String get menuAnalysisHistoryTapTheBookmarkButton =>
      '扫描菜单后点击书签按钮，即可将其保存至此处。';

  @override
  String get menuAnalysisHistoryTryADifferentSearch => '请尝试其他搜索词。';

  @override
  String get menuAnalysisHistoryUnpin => '取消置顶';

  @override
  String get menuAnalysisHistoryUseRestaurantName => '使用餐厅名称';

  @override
  String get menuAnalysisHistoryYouReOfflineThis => '您处于离线状态 — 此功能需要网络连接';

  @override
  String get menuAnalysisItemAddedSugar => '添加糖';

  @override
  String get menuAnalysisItemAdjustWhatYouAte => '调整您的饮食内容';

  @override
  String get menuAnalysisItemAdjusted => '已调整';

  @override
  String get menuAnalysisItemAllScoresGreen => '所有评分均为绿色';

  @override
  String get menuAnalysisItemBloodSugar => '血糖';

  @override
  String menuAnalysisItemCardG(Object grams) {
    return '$grams 克';
  }

  @override
  String menuAnalysisItemCardValue(Object s) {
    return '$s/10';
  }

  @override
  String get menuAnalysisItemFodmap => 'FODMAP';

  @override
  String get menuAnalysisItemFullBreakdown => '完整分析';

  @override
  String get menuAnalysisItemInflammation => '炎症';

  @override
  String get menuAnalysisItemPortion => '份量';

  @override
  String get menuAnalysisItemUltraProcessed => '超加工食品';

  @override
  String get menuAnalysisLogged => '已记录';

  @override
  String get menuAnalysisMenuUpdated => '菜单已更新';

  @override
  String get menuAnalysisMore => '更多…';

  @override
  String get menuAnalysisName => '名称';

  @override
  String get menuAnalysisNameOptional => '名称（可选）';

  @override
  String get menuAnalysisNoDishesMatchYour => '没有符合您筛选条件的菜品';

  @override
  String get menuAnalysisProtein => '蛋白质';

  @override
  String get menuAnalysisReScan => '重新扫描';

  @override
  String get menuAnalysisReScanMenu => '重新扫描菜单';

  @override
  String get menuAnalysisReScanThisMenu => '重新扫描此菜单？';

  @override
  String get menuAnalysisRecommendedForYou => '为您推荐';

  @override
  String get menuAnalysisRemove => '移除';

  @override
  String get menuAnalysisRemoveFromSaved => '从已保存中移除';

  @override
  String get menuAnalysisRemoveFromSaved2 => '从已保存中移除？';

  @override
  String get menuAnalysisRemovedFromSavedMenus => '已从已保存菜单中移除';

  @override
  String get menuAnalysisResults => '结果';

  @override
  String get menuAnalysisSaveAsNew => '另存为新菜单';

  @override
  String get menuAnalysisSaveMenu => '保存菜单';

  @override
  String get menuAnalysisSaveThisMenu => '保存此菜单';

  @override
  String get menuAnalysisSavedEdit => '已保存 · 编辑';

  @override
  String get menuAnalysisSavedMenus => '已保存菜单';

  @override
  String get menuAnalysisSavedToYourMenu => '已保存至您的菜单历史';

  @override
  String get menuAnalysisSearchDishes => '搜索菜品';

  @override
  String menuAnalysisSheetCalGP(Object cal, Object protein) {
    return '$cal 卡路里  ${protein}g 蛋白质  ';
  }

  @override
  String menuAnalysisSheetCouldnTAddFood(Object message) {
    return '无法添加食物：$message';
  }

  @override
  String menuAnalysisSheetGCGF(Object carbs, Object fat) {
    return '${carbs}g 碳水  ${fat}g 脂肪';
  }

  @override
  String menuAnalysisSheetGoal(Object displayName) {
    return '目标：$displayName';
  }

  @override
  String menuAnalysisSheetMore(Object extraCount) {
    return '更多 (+$extraCount)';
  }

  @override
  String menuAnalysisSheetMore2(Object extraCount) {
    return '+$extraCount 更多';
  }

  @override
  String menuAnalysisSheetSelected(Object length) {
    return '已选择 $length 项';
  }

  @override
  String menuAnalysisSheetSort(Object label) {
    return '排序：$label';
  }

  @override
  String menuAnalysisSheetValue(Object elapsed) {
    return '$elapsed';
  }

  @override
  String menuAnalysisSheetValue2(Object rank) {
    return '#$rank';
  }

  @override
  String menuAnalysisSheetYouAlreadySavedA(Object restaurantName) {
    return '您已经为“$restaurantName”保存过菜单';
  }

  @override
  String get menuAnalysisSort => '排序：';

  @override
  String get menuAnalysisSort2 => '排序';

  @override
  String get menuAnalysisTourAiPicksTheBest =>
      'AI 会根据您剩余的宏量营养素、过敏原和炎症耐受度，为您挑选出最合适的三个菜品。';

  @override
  String get menuAnalysisTourFilterByDietAllergens => '按饮食习惯和过敏原筛选';

  @override
  String get menuAnalysisTourHideDishesThatDon =>
      '隐藏不符合您饮食习惯或包含过敏原的菜品 — 您的偏好将从“设置”中同步。';

  @override
  String get menuAnalysisTourRecommendedForYou => '为您推荐';

  @override
  String get menuAnalysisTourSelectDishesToLog => '选择要记录的菜品';

  @override
  String get menuAnalysisTourSortTheWholeMenu => '对整个菜单进行排序';

  @override
  String get menuAnalysisTourTapProteinCarbsFat =>
      '点击“蛋白质”、“碳水”、“脂肪”或“炎症”即可立即重新排列所有菜品。“更多…”可开启高级排序。';

  @override
  String get menuAnalysisTourTickTheDishesYou =>
      '勾选您实际点的菜品，然后点击“记录”将其发送到您的每日总量中。';

  @override
  String get menuAnalysisUpdateExisting => '更新现有菜单';

  @override
  String get menuAnalysisUpdatedYourSavedMenu => '已更新您保存的菜单';

  @override
  String get menuAnalysisUseRestaurantName => '使用餐厅名称';

  @override
  String get menuAnalysisYouReOfflineThis => '您处于离线状态 — 此功能需要网络连接';

  @override
  String get menuDishAdjustAddABitMore => '添加更多细节以进行优化。';

  @override
  String get menuDishAdjustAdjustThisDish => '调整此菜品';

  @override
  String get menuDishAdjustApply => '应用';

  @override
  String get menuDishAdjustCouldnTRefineThat => '无法优化 — 请尝试重新表述。';

  @override
  String get menuDishAdjustHowMuchDidYou => '您吃了多少？';

  @override
  String get menuDishAdjustMenuMacrosAreAs =>
      '菜单宏量营养素为“按份供应”数值 — 请告诉我们您实际吃了多少。';

  @override
  String get menuDishAdjustOrDescribeIt => '或进行描述';

  @override
  String get menuDishAdjustRefining => '正在优化…';

  @override
  String menuDishAdjustSheetThisDishCalG(Object previewCal, Object previewP) {
    return '此菜品：~$previewCal 卡 · $previewP克蛋白质';
  }

  @override
  String get menuFilterAdvancedFilters => '高级筛选';

  @override
  String get menuFilterAppliesOnlyToDishes => '仅适用于标价的菜品。';

  @override
  String get menuFilterAvoid => '避免';

  @override
  String get menuFilterBasedOnIngredientProfile => '基于成分概况（Omega-3、纤维、添加糖等）。';

  @override
  String get menuFilterBloodSugar => '血糖';

  @override
  String get menuFilterCaloriesAtMost => '最高卡路里';

  @override
  String get menuFilterCarbsAtMost => '最高碳水化合物';

  @override
  String get menuFilterCoachSVerdict => '教练评价';

  @override
  String get menuFilterDiet => '饮食';

  @override
  String get menuFilterFatAtMost => '最高脂肪';

  @override
  String get menuFilterFilters => '筛选';

  @override
  String get menuFilterFineTuneMacros => '微调宏量营养素';

  @override
  String get menuFilterFodmapIbs => 'FODMAP (IBS)';

  @override
  String get menuFilterForSpecificTargetsMost => '针对特定目标。大多数人不需要此项。';

  @override
  String get menuFilterGlycemicLoadPerServing => '单份升糖负荷 — 越低 = 能量越平稳。';

  @override
  String get menuFilterGood => '✅ 良好';

  @override
  String get menuFilterHideAdvancedFilters => '隐藏高级筛选';

  @override
  String get menuFilterHideDishesWithMy => '隐藏包含我过敏原的菜品';

  @override
  String get menuFilterHideUltraProcessedDishes => '隐藏超加工食品';

  @override
  String get menuFilterHowTheAiRated => 'AI 对每道菜符合您目标的评分。';

  @override
  String get menuFilterInflammation => '炎症';

  @override
  String get menuFilterMaxPrice => '最高价格';

  @override
  String get menuFilterMenuSections => '菜单分区';

  @override
  String get menuFilterNoDishesMatch => '没有匹配的菜品';

  @override
  String get menuFilterOkay => '👌 一般';

  @override
  String get menuFilterOnionGarlicWheatLactose => '洋葱、大蒜、小麦、乳糖可能会诱发 IBS 症状。';

  @override
  String get menuFilterPerDishBudget => '单菜预算';

  @override
  String get menuFilterProteinAtLeast => '最低蛋白质';

  @override
  String get menuFilterReset => '重置';

  @override
  String menuFilterSheetShowAllDishes(Object total) {
    return '显示全部 $total 道菜';
  }

  @override
  String menuFilterSheetShowOfDishes(Object matches, Object total) {
    return '显示 $matches/$total 道菜';
  }

  @override
  String get menuFilterShowOnlyCertainParts => '仅显示菜单的特定部分。';

  @override
  String get menuFilterSkip => '⚠️ 跳过';

  @override
  String get menuFilterSkipsNova4Foods => '跳过 NOVA-4 食品（工业乳化剂、高果糖玉米糖浆等）';

  @override
  String get menuFilterTapAnyThatApply => '点击所有适用项 — 我们将只显示匹配的菜品。';

  @override
  String get menuFilterUsesYourSavedAllergen => '使用您保存的过敏原档案';

  @override
  String get menuFilterWeLlHideDishes => '我们将隐藏不符合您饮食习惯的菜品。';

  @override
  String get menuFilterWhatAreYouIn => '你想吃什么？';

  @override
  String get merchClaimsAcceptReward => '接受奖励';

  @override
  String merchClaimsAcceptedWeWillBeIn(Object displayName) {
    return '$displayName 已接受！我们会与你联系。';
  }

  @override
  String get merchClaimsCancelReward => '取消奖励';

  @override
  String get merchClaimsCancelThisReward => '取消此奖励？';

  @override
  String get merchClaimsCarrier => '承运商';

  @override
  String merchClaimsClaimYour(Object displayName) {
    return '领取您的 $displayName？';
  }

  @override
  String get merchClaimsDeliveryDetails => '配送详情';

  @override
  String merchClaimsFailedToAccept(Object error) {
    return '接受失败：$error';
  }

  @override
  String merchClaimsFailedToCancel(Object error) {
    return '取消失败：$error';
  }

  @override
  String get merchClaimsFailedToLoadMerch => '无法加载周边奖励';

  @override
  String get merchClaimsFailedToUpdateTry => '更新失败。请重试。';

  @override
  String get merchClaimsKeepIt => '保留';

  @override
  String get merchClaimsMerchNotifications => '周边通知';

  @override
  String get merchClaimsMerchRewards => '周边奖励';

  @override
  String get merchClaimsNoMerchUnlockedYet => '暂未解锁周边';

  @override
  String get merchClaimsNotNow => '暂不';

  @override
  String get merchClaimsPushEmailAlertsWhen => '当接近周边等级或有奖励待领时，接收推送和电子邮件提醒';

  @override
  String get merchClaimsRealRewardsForReal => '真实的进步，真实的奖励';

  @override
  String get merchClaimsRewardAcceptedWeLl => '奖励已接受！我们将通过电子邮件联系您收集配送详情。';

  @override
  String get merchClaimsRewardCancelled => '奖励已取消。';

  @override
  String merchClaimsScreenDelivered(Object claim) {
    return '已送达：$claim';
  }

  @override
  String merchClaimsScreenKeepAnEyeOn(Object appName) {
    return '请留意与您的 $appName 账户绑定的电子邮箱。';
  }

  @override
  String merchClaimsScreenReachMilestoneLevelsAnd(Object appName) {
    return '达到里程碑等级，我们将为您寄送真实的 $appName 周边。';
  }

  @override
  String merchClaimsScreenShipped(Object claim) {
    return '已发货：$claim';
  }

  @override
  String merchClaimsScreenValue(Object displayName, Object statusLabel) {
    return '$displayName — $statusLabel';
  }

  @override
  String merchClaimsScreenYourFirstPhysicalReward(Object appName) {
    return '您的第一个实物奖励在 50 级解锁 — 一套免费的 $appName 贴纸。';
  }

  @override
  String get merchClaimsTapAcceptToClaim =>
      '点击“接受”即可领取。准备发货时，我们将通过电子邮件联系您收集尺码和收货地址。';

  @override
  String get merchClaimsTracking => '追踪单号';

  @override
  String merchClaimsUnlockedAtLevel(Object level) {
    return '达到 $level 级解锁';
  }

  @override
  String get merchClaimsViewTracking => '查看物流';

  @override
  String get merchClaimsWeLlEmailYou => '我们将在未来几周内通过电子邮件联系您，以收集您的';

  @override
  String merchClaimsYouWillForfeit(Object displayName, Object level) {
    return '您将放弃 $displayName（等级 $level）。此操作无法撤销。';
  }

  @override
  String get messagesCouldNotLoadYour => '无法加载您的对话。\n请稍后再试。';

  @override
  String get messagesFailedToLoadMessages => '无法加载消息';

  @override
  String get messagesNewGroup => '新建群组';

  @override
  String get messagesNoMessagesYet => '暂无消息';

  @override
  String get messagesNotLoggedIn => '未登录';

  @override
  String get messagesPleaseLogInTo => '请登录以查看您的消息';

  @override
  String get messagesStartAConversationWith => '与好友开启对话吧！\n您的消息将显示在这里。';

  @override
  String get metricHistoryCardNoDataForThis => '今日无数据';

  @override
  String get metricHistoryCardTrendUnavailable => '趋势不可用。';

  @override
  String get metricHistoryCardTwoOrMoreSynced => '需要同步两天或以上的数据才能绘制趋势图。';

  @override
  String get metricPickerChooseAMetric => '选择指标';

  @override
  String get metricPickerRecentlyUsed => '最近使用';

  @override
  String metricPickerSheetNoMetricMatches(Object text) {
    return '没有匹配“$text”的指标';
  }

  @override
  String metricPickerSheetResults(Object length) {
    return '$length 个结果';
  }

  @override
  String metricPickerSheetSearchMetrics(Object length) {
    return '搜索 $length 个指标…';
  }

  @override
  String get metricsDashboardActiveStreak => '活跃连胜';

  @override
  String get metricsDashboardAddEntry => '添加条目';

  @override
  String get metricsDashboardAddMetric => '添加指标';

  @override
  String get metricsDashboardBmi => 'BMI';

  @override
  String get metricsDashboardBodyFat => '身体脂肪';

  @override
  String get metricsDashboardBodyFatPct => '体脂率';

  @override
  String get metricsDashboardCalories => '卡路里';

  @override
  String get metricsDashboardCaloriesBurned => '燃烧的卡路里';

  @override
  String get metricsDashboardEnterValue => '输入数值';

  @override
  String get metricsDashboardHealthMetrics => '健康指标';

  @override
  String get metricsDashboardHeartRate => '心率';

  @override
  String get metricsDashboardHip => '臀围';

  @override
  String get metricsDashboardMetricType => '公制类型';

  @override
  String get metricsDashboardMuscleMass => '肌肉量';

  @override
  String get metricsDashboardNoDataAvailable => '暂无数据';

  @override
  String metricsDashboardNoMetricDataYet(Object arg0) {
    return '暂无指标数据 $arg0';
  }

  @override
  String get metricsDashboardQuickStats => '快速统计';

  @override
  String get metricsDashboardRestingHeartRate => '静息心率';

  @override
  String get metricsDashboardRestingHr => '静息心率';

  @override
  String get metricsDashboardSave => '保存';

  @override
  String get metricsDashboardTotalTime => '总时间';

  @override
  String get metricsDashboardTrackYourProgressOver => '追踪您的长期进度';

  @override
  String get metricsDashboardValue => '数值';

  @override
  String get metricsDashboardWaist => '腰围';

  @override
  String get metricsDashboardWeight => '重量';

  @override
  String get metricsDashboardWorkoutsThisWeek => '本周锻炼';

  @override
  String get micronutrientsNoMicronutrientDataAvailabl => '暂无微量营养素数据';

  @override
  String get micronutrientsVitaminsMinerals => '维生素与矿物质';

  @override
  String get milestoneCelebrationCopy => '复制';

  @override
  String milestoneCelebrationDialogPts(Object points) {
    return '+$points 积分';
  }

  @override
  String get milestoneCelebrationMilestoneAchieved => '达成里程碑！';

  @override
  String get milestoneCelebrationShareYourAchievement => '分享您的成就';

  @override
  String get milestonesAchieved => '已达成';

  @override
  String get milestonesAll => '全部';

  @override
  String get milestonesMilestone => '里程碑';

  @override
  String get milestonesMilestones => '里程碑';

  @override
  String get milestonesNextMilestone => '下一个里程碑';

  @override
  String get milestonesPoints => '积分';

  @override
  String get milestonesPoints2 => '积分';

  @override
  String milestonesScreenPts(Object points) {
    return '$points 分';
  }

  @override
  String milestonesScreenUiAchieved(Object totalAchieved) {
    return '已达成 ($totalAchieved)';
  }

  @override
  String milestonesScreenUiAverageMinWorkout(
    Object averageWorkoutDurationMinutes,
  ) {
    return '平均: $averageWorkoutDurationMinutes 分钟/次';
  }

  @override
  String get milestonesScreenUiCompleteWorkoutsToSee => '完成训练以查看你的 ROI';

  @override
  String milestonesScreenUiKg(Object totalWeightLiftedKg) {
    return '$totalWeightLiftedKg kg';
  }

  @override
  String get milestonesScreenUiNoDataYet => '暂无数据';

  @override
  String get milestonesScreenUiUpcoming => '即将到来';

  @override
  String milestonesScreenValue(Object next) {
    return '$next%';
  }

  @override
  String milestonesScreenValue2(Object progress) {
    return '$progress%';
  }

  @override
  String get milestonesTotalWorkouts => '总训练次数';

  @override
  String get milestonesYourJourney => '你的历程';

  @override
  String get milestonesYourRoi => '你的 ROI';

  @override
  String get minimalHeaderChangeGymProfile => '更改健身房配置';

  @override
  String get minimalHeaderCollapseWeekStrip => '折叠周条';

  @override
  String minimalHeaderD(Object streakDays) {
    return '$streakDays 天';
  }

  @override
  String get minimalHeaderExpandWeekStrip => '展开周视图';

  @override
  String get minimalHeaderHideDayStrip => '隐藏日视图';

  @override
  String get minimalHeaderMySpace => '我的空间';

  @override
  String get minimalHeaderShowDayStrip => '显示日视图';

  @override
  String get missedWorkoutBannerDoToday => '今日完成';

  @override
  String missedWorkoutBannerExercises(Object exercisesCount) {
    return '$exercisesCount 个动作';
  }

  @override
  String missedWorkoutBannerMin(Object durationMinutes) {
    return '$durationMinutes 分钟';
  }

  @override
  String get missedWorkoutBannerMissedWorkout => '错过的训练';

  @override
  String missedWorkoutBannerMoreMissedWorkouts(Object missedList) {
    return '+$missedList 更多错过的锻炼';
  }

  @override
  String get missedWorkoutBannerSkipIt => '跳过';

  @override
  String get missedWorkoutBannerSkipWithoutReason => '直接跳过';

  @override
  String get missedWorkoutBannerThisHelpsUsAdjust => '这有助于我们调整你的计划';

  @override
  String get missedWorkoutBannerWhyAreYouSkipping => '为什么要跳过？';

  @override
  String get missedWorkoutBannerWorkoutSkipped => '训练已跳过';

  @override
  String missedWorkoutBannerYouMissed(Object dayPossessive, Object name) {
    return '你错过了 $dayPossessive $name';
  }

  @override
  String get moodAnalyticsCardCheckIns => '打卡';

  @override
  String get moodAnalyticsCardCompleted => '已完成';

  @override
  String get moodAnalyticsCardMoodDistribution => '情绪分布';

  @override
  String get moodAnalyticsCardMostCommonMood => '最常见情绪';

  @override
  String moodAnalyticsCardValue(Object completionRate) {
    return '$completionRate%';
  }

  @override
  String moodAnalyticsCardValue2(Object percentage) {
    return '$percentage%';
  }

  @override
  String get moodCalendarHeatmapDaysTracked => '已追踪天数';

  @override
  String get moodCalendarHeatmapFailedToLoadCalendar => '无法加载日历';

  @override
  String get moodCalendarHeatmapGood => '良好';

  @override
  String get moodCalendarHeatmapGreat => '很棒';

  @override
  String get moodCalendarHeatmapMostCommon => '最常见';

  @override
  String get moodCalendarHeatmapStressed => '压力大';

  @override
  String get moodCalendarHeatmapTired => '疲惫';

  @override
  String get moodCalendarHeatmapTotalCheckIns => '总打卡次数';

  @override
  String get moodCardBias => '偏差';

  @override
  String get moodCardInt => '强度';

  @override
  String moodCardIntensity(Object mood) {
    return '$mood - 强度';
  }

  @override
  String get moodCardMood => '情绪';

  @override
  String get moodCardMoodMultipliers => '情绪乘数';

  @override
  String get moodCardResetAll => '重置全部';

  @override
  String get moodCardRest => '休息';

  @override
  String moodCardRest2(Object mood) {
    return '$mood - 休息';
  }

  @override
  String get moodCardTapCellsToTune => '点击单元格以调整基于情绪的设置';

  @override
  String get moodCardVol => '容量';

  @override
  String moodCardVolume(Object mood) {
    return '$mood - 容量';
  }

  @override
  String moodCardX(Object v) {
    return '${v}x';
  }

  @override
  String moodCardX2(Object v) {
    return '${v}x';
  }

  @override
  String moodCardX3(Object v) {
    return '${v}x';
  }

  @override
  String get moodHistoryCheckInHistory => '打卡历史';

  @override
  String get moodHistoryInsightsSuggestions => '洞察与建议';

  @override
  String moodHistoryItemCardFeeling(Object mood) {
    return '感觉$mood';
  }

  @override
  String get moodHistoryItemMoodWorkout => '情绪训练';

  @override
  String get moodHistoryMoodHistoryAnalysis => '情绪历史与分析';

  @override
  String get moodHistoryNoMoodCheckIns => '暂无情绪打卡';

  @override
  String moodHistoryScreenLastDays(Object daysTracked) {
    return '过去 $daysTracked 天';
  }

  @override
  String moodHistoryScreenTotal(Object totalCount) {
    return '共 $totalCount 条';
  }

  @override
  String get moodHistoryStartTrackingYourMood =>
      '开始追踪你的情绪，以获取个性化的训练建议并查看你的长期趋势。';

  @override
  String get moodHistoryYourMoodInsights => '你的情绪洞察';

  @override
  String get moodPickerAdvancedOptions => '高级选项';

  @override
  String get moodPickerCardGeneratingYourWorkout => '正在生成你的训练...';

  @override
  String moodPickerCardGeneratingYourWorkout2(Object label) {
    return '正在生成你的 $label 训练...';
  }

  @override
  String get moodPickerCardGenerationFailed => '生成失败';

  @override
  String get moodPickerCardGetAWorkoutFor => '获取适合你当前情绪的训练';

  @override
  String get moodPickerCardHowAreYouFeeling => '你感觉如何？';

  @override
  String get moodPickerCardSomethingWentWrong => '出错了';

  @override
  String moodPickerCardStepOf(Object currentStep, Object totalSteps) {
    return '第 $currentStep 步，共 $totalSteps 步';
  }

  @override
  String moodPickerCardStepOf2(Object currentStep, Object totalSteps) {
    return '第 $currentStep 步，共 $totalSteps 步';
  }

  @override
  String get moodPickerCardTryAgain => '重试';

  @override
  String get moodPickerCouldnTSaveYour => '无法保存你的情绪。请重试。';

  @override
  String get moodPickerGenerateWorkout => '生成训练';

  @override
  String get moodPickerHowAreYouFeeling => '你感觉如何？';

  @override
  String get moodPickerJustLogMood => '仅记录情绪';

  @override
  String get moodPickerResetToRecommended => '重置为推荐设置';

  @override
  String moodPickerSheetFailedToGenerateWorkout(Object e) {
    return '生成锻炼失败：$e';
  }

  @override
  String moodPickerSheetMin(Object _effectiveDuration) {
    return '$_effectiveDuration 分钟';
  }

  @override
  String moodPickerSheetMood(Object description, Object label) {
    return '$label 心情。$description';
  }

  @override
  String moodPickerSheetMoodLogged(Object label) {
    return '心情已记录：$label';
  }

  @override
  String get moodPickerViewHistoryAnalysis => '查看历史与分析';

  @override
  String get moodStreakCardBestStreak => '最佳连胜';

  @override
  String get moodStreakCardCurrentStreak => '当前连胜';

  @override
  String get moodWeeklyChartAvgScore => '平均分';

  @override
  String get moodWeeklyChartCheckIns => '打卡';

  @override
  String get moodWeeklyChartDaysActive => '活跃天数';

  @override
  String get moodWeeklyChartDeclining => '正在下降';

  @override
  String get moodWeeklyChartFailedToLoadMood => '无法加载情绪数据';

  @override
  String get moodWeeklyChartImproving => '正在改善';

  @override
  String get moodWeeklyChartMoodTrends => '情绪趋势';

  @override
  String get moodWeeklyChartNoMoodDataThis => '本周无情绪数据';

  @override
  String get moodWeeklyChartStable => '保持稳定';

  @override
  String get moodWeeklyChartStartTrackingYourMood => '开始追踪你的情绪以查看趋势';

  @override
  String moodWeeklyChartValue(Object length) {
    return '$length/7';
  }

  @override
  String get morningRecoveryNudgeBody => '今日恢复值偏低。我们将减少训练量——打开应用以重新生成。';

  @override
  String get morningRecoveryNudgeTitle => '今天放轻松';

  @override
  String get motivationalTemplateCompleted => '已完成';

  @override
  String get muscleAnalyticsAllowRecovery => '允许恢复';

  @override
  String get muscleAnalyticsBalance => '平衡';

  @override
  String get muscleAnalyticsBalanceRatios => '平衡比例';

  @override
  String get muscleAnalyticsBalanceScore => '平衡得分';

  @override
  String get muscleAnalyticsBalanced => '已平衡';

  @override
  String get muscleAnalyticsCompleteMoreWorkoutsTo => '完成更多训练以查看你的肌肉平衡分析。';

  @override
  String get muscleAnalyticsCompleteSomeWorkoutsTo => '完成一些训练以查看你的肌肉训练热力图。';

  @override
  String get muscleAnalyticsCompleteWorkoutsOverMultipl => '在多周内完成训练以查看训练频率。';

  @override
  String get muscleAnalyticsFrequency => '频率';

  @override
  String get muscleAnalyticsHeatmap => '热力图';

  @override
  String get muscleAnalyticsImbalanced => '不平衡';

  @override
  String get muscleAnalyticsLeastTrained => '训练最少';

  @override
  String get muscleAnalyticsMostTrained => '训练最多';

  @override
  String get muscleAnalyticsMuscleBreakdown => '肌肉分析';

  @override
  String get muscleAnalyticsMuscleTrends => '肌肉趋势';

  @override
  String get muscleAnalyticsNeedsWork => '有待加强';

  @override
  String get muscleAnalyticsNoBalanceData => '无平衡数据';

  @override
  String get muscleAnalyticsNoFrequencyData => '无频率数据';

  @override
  String get muscleAnalyticsNoTrainingData => '无训练数据';

  @override
  String get muscleAnalyticsOvertrained => '过度训练';

  @override
  String get muscleAnalyticsPushPull => '推 / 拉';

  @override
  String get muscleAnalyticsRecommendations => '建议';

  @override
  String muscleAnalyticsScreenKg(Object balance) {
    return '$balance kg';
  }

  @override
  String get muscleAnalyticsTrainMore => '加强训练';

  @override
  String get muscleAnalyticsTrainingIntensity => '训练强度';

  @override
  String get muscleAnalyticsUndertrained => '训练不足';

  @override
  String get muscleAnalyticsUpperLower => '上肢 / 下肢';

  @override
  String get muscleAnalyticsWeeklyTrainingFrequency => '每周训练频率';

  @override
  String get muscleBalanceChartBalanced => '平衡';

  @override
  String get muscleBalanceChartImbalanced => '不平衡';

  @override
  String get muscleBalanceChartLower => '下肢';

  @override
  String get muscleBalanceChartPull => '拉';

  @override
  String get muscleBalanceChartPush => '推';

  @override
  String get muscleBalanceChartPushPull => '推 / 拉';

  @override
  String get muscleBalanceChartUpper => '上肢';

  @override
  String get muscleBalanceChartUpperLower => '上肢 / 下肢';

  @override
  String get muscleDetail => '•  ';

  @override
  String get muscleDetailInsights => '洞察';

  @override
  String get muscleDetailMax => '最大值';

  @override
  String get muscleDetailMaxWeight => '最大重量';

  @override
  String get muscleDetailNeedMoreDataFor => '图表需要更多数据';

  @override
  String muscleDetailScreenSetsWk(Object weeklySets) {
    return '$weeklySets 组/周';
  }

  @override
  String get muscleDetailTimes => '次数';

  @override
  String get muscleDetailTotalSets => '总组数';

  @override
  String get muscleDetailTotalVolume => '总容量';

  @override
  String get muscleDetailVolume => '容量';

  @override
  String get muscleDetailVolumeTrend => '容量趋势';

  @override
  String get muscleFrequencyChartHigh4xWk => '高 (>4次/周)';

  @override
  String get muscleFrequencyChartLow1xWk => '低 (<1次/周)';

  @override
  String get muscleFrequencyChartNoFrequencyDataAvailable => '无频率数据可用';

  @override
  String get muscleFrequencyChartOptimal13xWk => '最佳 (1-3次/周)';

  @override
  String muscleFrequencyChartX(Object frequency) {
    return '${frequency}x';
  }

  @override
  String muscleFrequencyChartX2(Object frequency) {
    return '${frequency}x';
  }

  @override
  String muscleFrequencyChartXWk(Object value) {
    return '$value次/周';
  }

  @override
  String get muscleGroupFilterAllMuscles => '所有肌肉';

  @override
  String get muscleHeatmapCore => '核心';

  @override
  String get muscleHeatmapHigh => '高';

  @override
  String get muscleHeatmapLow => '低';

  @override
  String get muscleHeatmapLowerBody => '下肢';

  @override
  String get muscleHeatmapMedium => '中';

  @override
  String get muscleHeatmapNone => '无';

  @override
  String get muscleHeatmapOther => '其他';

  @override
  String get muscleHeatmapTileCompleteWorkoutsToSee => '完成训练以查看肌肉数据';

  @override
  String get muscleHeatmapTileCouldnTLoad => '无法加载';

  @override
  String muscleHeatmapTileMostTrained(Object arg0) {
    return '最常训练 $arg0';
  }

  @override
  String get muscleHeatmapTileMuscles => '肌肉';

  @override
  String get muscleHeatmapTileRetry => '重试';

  @override
  String get muscleHeatmapUpperBody => '上肢';

  @override
  String get muscleScoreBreakdownNoExerciseDataIn => '过去90天内无训练数据。';

  @override
  String muscleScoreBreakdownSheetEstimatedRmKg(Object e1rm) {
    return '预估 1RM $e1rm kg';
  }

  @override
  String muscleScoreBreakdownSheetValue(Object pct) {
    return '$pct%';
  }

  @override
  String get my1rmsAdd1rm => '添加1RM';

  @override
  String get my1rmsAddManually => '手动添加';

  @override
  String get my1rmsAddYourMaxLifts => '添加您的最大重量，以便根据您的训练强度获取个性化的重量建议。';

  @override
  String get my1rmsAutoPopulateFromWorkout => '从训练历史自动填充';

  @override
  String get my1rmsDelete1rm => '删除1RM？';

  @override
  String get my1rmsMy1rms => '我的1RM';

  @override
  String get my1rmsNo1rmsRecorded => '未记录1RM';

  @override
  String get my1rmsScreen1rmWeightKg => '1RM 重量 (kg)';

  @override
  String get my1rmsScreenAdd1rm => '添加1RM';

  @override
  String get my1rmsScreenAngle => '角度';

  @override
  String get my1rmsScreenDelete1rm => '删除1RM';

  @override
  String get my1rmsScreenEG100 => '例如：100';

  @override
  String get my1rmsScreenEGBenchPress => '例如：卧推';

  @override
  String get my1rmsScreenEGInclineBench => '例如：上斜卧推';

  @override
  String get my1rmsScreenEdit1rm => '编辑1RM';

  @override
  String get my1rmsScreenEnteredManually => '手动输入';

  @override
  String get my1rmsScreenEquipment => '器械';

  @override
  String get my1rmsScreenExerciseName => '动作名称';

  @override
  String get my1rmsScreenLinkExercise => '关联动作';

  @override
  String get my1rmsScreenLinkExercises => '关联动作';

  @override
  String get my1rmsScreenLinkedExercises => '已关联动作';

  @override
  String my1rmsScreenPartOneRMCardDerivedRmKg(Object derivedWeight) {
    return '推算 1RM: $derivedWeight kg';
  }

  @override
  String my1rmsScreenPartOneRMCardKg(
    Object derivedWeight,
    Object multiplierDisplay,
    Object relationshipDisplay,
  ) {
    return '$multiplierDisplay = $derivedWeight kg • $relationshipDisplay';
  }

  @override
  String my1rmsScreenPartOneRMCardLinkTo(Object primaryExerciseName) {
    return '关联至 $primaryExerciseName';
  }

  @override
  String my1rmsScreenPartOneRMCardLinked(Object linkedCount) {
    return '已关联 $linkedCount 个';
  }

  @override
  String my1rmsScreenPartOneRMCardLinkedTo(
    Object primaryExerciseName,
    Object text,
  ) {
    return '已将 $text 关联至 $primaryExerciseName';
  }

  @override
  String my1rmsScreenPartOneRMCardRemoveFromLinkedExercises(
    Object linkedExerciseName,
  ) {
    return '将 $linkedExerciseName 从关联动作中移除？';
  }

  @override
  String get my1rmsScreenProgression => '进度';

  @override
  String get my1rmsScreenRelationshipType => '关系类型';

  @override
  String get my1rmsScreenRemove => '移除';

  @override
  String my1rmsScreenRemoveFromYourSaved(Object exerciseName) {
    return '从已保存的 1RM 中移除 $exerciseName？';
  }

  @override
  String get my1rmsScreenRemoveLink => '移除关联？';

  @override
  String get my1rmsScreenSource => '来源';

  @override
  String get my1rmsScreenSuggestions => '建议';

  @override
  String get my1rmsScreenTested1rm => '已测试1RM';

  @override
  String get my1rmsScreenUpdate => '更新';

  @override
  String get my1rmsScreenVariant => '变式';

  @override
  String myBadgesShowcaseBadgesAvailable(Object total) {
    return '共有 $total 枚徽章';
  }

  @override
  String myBadgesShowcaseEarned(Object length, Object totalTrophies) {
    return '已获得 $length / $totalTrophies';
  }

  @override
  String myBadgesShowcaseEarned2(Object length) {
    return '已获得 $length 枚';
  }

  @override
  String get myBadgesShowcaseLogYourFirstWorkout => '记录你的第一次训练以获得首个徽章';

  @override
  String myExercisesAreYouSureDelete(Object exercise) {
    return '确定要删除“$exercise”吗？此操作无法撤销。';
  }

  @override
  String get myExercisesAvoided => '已避开';

  @override
  String get myExercisesCreate => '创建';

  @override
  String get myExercisesCreateExercise => '创建动作';

  @override
  String get myExercisesCreateYourOwnExercises => '创建你自己的动作以用于训练';

  @override
  String get myExercisesCustom => '自定义';

  @override
  String get myExercisesDeleteExercise => '删除动作';

  @override
  String get myExercisesExercisePreferences => '动作偏好';

  @override
  String get myExercisesFavorites => '收藏';

  @override
  String get myExercisesMuscles => '肌肉';

  @override
  String get myExercisesNoCustomExercisesYet => '暂无自定义动作';

  @override
  String get myExercisesQueue => '队列';

  @override
  String get myExercisesStaples => '核心动作';

  @override
  String get myFoodsCreateNewRecipe => '创建新食谱';

  @override
  String get myFoodsCreateRecipesToQuickly => '创建食谱以快速记录常吃的餐食';

  @override
  String get myFoodsCreateYourFirstRecipe => '创建你的第一个食谱';

  @override
  String get myFoodsMyFoods => '我的食物';

  @override
  String get myFoodsNoRecipesYet => '暂无食谱';

  @override
  String get myFoodsNoSavedFoodsFound => '未找到已保存的食物';

  @override
  String get myFoodsReopenARestaurantMenu => '重新打开之前扫描过的餐厅菜单';

  @override
  String get myFoodsSaveFoodsWhenLogging => '记录餐食时保存食物';

  @override
  String get myFoodsSavedMenus => '已保存菜单';

  @override
  String get myFoodsSearchSavedFoods => '搜索已保存的食物...';

  @override
  String myFoodsSheetIngredients(Object ingredientCount) {
    return '$ingredientCount 种配料';
  }

  @override
  String myFoodsSheetKcal(Object recipe) {
    return '$recipe kcal';
  }

  @override
  String myFoodsSheetKcalUBP(
    Object food,
    Object food1,
    Object food2,
    Object food3,
  ) {
    return '$food kcal · P:${food1}g · C:${food2}g · F:${food3}g';
  }

  @override
  String myFoodsSheetLoggedX(Object timesLogged) {
    return '已记录 $timesLogged 次';
  }

  @override
  String myFoodsSheetX(Object timesLogged) {
    return ' $timesLogged 次';
  }

  @override
  String get myJourneyCardAmazingStreak => '连续打卡太棒了！继续保持！';

  @override
  String get myJourneyCardBuildingGreatHabits => '您正在养成良好的习惯！';

  @override
  String get myJourneyCardComesoFar => '您已经走了这么远。继续加油！';

  @override
  String get myJourneyCardDayStreak => '天连续打卡';

  @override
  String get myJourneyCardEveryWorkoutCounts => '每一次训练都很重要。您一定行！';

  @override
  String get myJourneyCardKeepMomentum => '保持势头，继续前进！';

  @override
  String get myJourneyCardMilestoneAthlete => '运动员';

  @override
  String get myJourneyCardMilestoneBeginner => '初学者';

  @override
  String get myJourneyCardMilestoneBuildingHabit => '养成习惯';

  @override
  String get myJourneyCardMilestoneChampion => '冠军';

  @override
  String get myJourneyCardMilestoneConsistent => '持续坚持';

  @override
  String get myJourneyCardMilestoneDedicated => '专注投入';

  @override
  String get myJourneyCardMilestoneGettingStarted => '入门';

  @override
  String get myJourneyCardMilestoneLegend => '传奇';

  @override
  String get myJourneyCardMyJourney => '我的旅程';

  @override
  String myJourneyCardNext(Object title) {
    return '下一项：$title';
  }

  @override
  String get myJourneyCardOneWorkoutLeft => '本周还剩 1 次训练';

  @override
  String get myJourneyCardProgress => '进度';

  @override
  String get myJourneyCardProgressCharts => '进度图表';

  @override
  String get myJourneyCardTapToSeeFullJourney => '点击查看完整旅程';

  @override
  String get myJourneyCardThisWeek => '本周';

  @override
  String get myJourneyCardTotal => '总计';

  @override
  String get myJourneyCardViewCharts => '查看图表';

  @override
  String get myJourneyCardViewStrengthAndVolume => '查看力量和训练量随时间的变化趋势';

  @override
  String myJourneyCardWeekNumber(Object week) {
    return '第 $week 周';
  }

  @override
  String get myJourneyCardWeeklyGoalComplete => '已完成本周目标！';

  @override
  String myJourneyCardWorkoutsLeft(Object count) {
    return '本周还剩 $count 次训练';
  }

  @override
  String myJourneyCardWorkoutsProgress(Object completed, Object total) {
    return '$completed / $total 次训练';
  }

  @override
  String get myLibraryTabAiPrioritizesTheseIn => 'AI 会在你的训练中优先安排这些动作';

  @override
  String get myLibraryTabBuildSupersetsCombosOr => '构建超级组、组合动作或独特动作';

  @override
  String get myLibraryTabCompleteWorkoutsToSee => '完成训练以查看你的动作历史';

  @override
  String get myLibraryTabCreate => '创建';

  @override
  String get myLibraryTabCreateYourFirstCustom => '创建你的第一个自定义动作';

  @override
  String get myLibraryTabFailedToLoadActivity => '加载活动失败';

  @override
  String get myLibraryTabGetStarted => '开始使用';

  @override
  String get myLibraryTabHeartExercisesToSave => '收藏动作以将其保存在此处';

  @override
  String get myLibraryTabMarkExercisesAsStaples => '将动作标记为核心动作，以便 AI 优先安排';

  @override
  String get myLibraryTabMyExercises => '我的动作';

  @override
  String myLibraryTabPartCustomExercisesSectionFavorites(Object length) {
    return '收藏 ($length)';
  }

  @override
  String myLibraryTabPartCustomExercisesSectionStaples(Object length) {
    return '常用 ($length)';
  }

  @override
  String myLibraryTabPartHistoryTimelineCardBestKgX(
    Object item,
    Object maxReps,
  ) {
    return '最佳: ${item}kg x $maxReps';
  }

  @override
  String myLibraryTabPartHistoryTimelineCardValue(Object item) {
    return ')(item)%';
  }

  @override
  String get myLibraryTabRecentActivity => '近期活动';

  @override
  String get myLibraryTabViewAll => '查看全部';

  @override
  String myProgramSummaryCardValue(
    Object experience,
    Object goal,
    Object workoutDays,
  ) {
    return '$workoutDays  •  $experience  •  $goal';
  }

  @override
  String get myProgramSummaryMyProgram => '我的计划';

  @override
  String get myStats1rm => '1RM';

  @override
  String get myStatsCompleteWorkoutsToSee => '完成训练以查看你的统计数据';

  @override
  String get myStatsExercisePerformance => '动作表现';

  @override
  String get myStatsFailedToLoadStats => '加载统计数据失败';

  @override
  String get myStatsKgMax => 'kg 最大值';

  @override
  String get myStatsNoExerciseHistoryYet => '暂无训练历史';

  @override
  String myStatsTabExercisesTrackedTotalSets(Object length, Object totalSets) {
    return '已追踪 $length 个动作  •  总组数 $totalSets';
  }

  @override
  String get myWrappedCompleteAtLeast3 => '本月至少完成 3 次训练\n即可解锁你的个性化回顾';

  @override
  String get myWrappedEarnAUniquePersonality => '每月至少完成 3 次训练，即可获得独特的健身人格。';

  @override
  String get myWrappedFailedToLoadWrapped => '加载回顾数据失败';

  @override
  String get myWrappedFitnessPersonalities => '健身人格';

  @override
  String get myWrappedMyWrapped => '我的回顾';

  @override
  String get myWrappedPastWraps => '往期回顾';

  @override
  String get myWrappedPersonalities => '人格';

  @override
  String myWrappedScreenOfCollected(Object collected) {
    return '已收集 $collected/12';
  }

  @override
  String myWrappedScreenWorkouts(Object totalWorkouts) {
    return '$totalWorkouts 次训练';
  }

  @override
  String myWrappedScreenWrappedDropsInDays(
    Object daysUntilDrop,
    Object monthName,
  ) {
    return '$monthName 年度总结将在 $daysUntilDrop 天后发布';
  }

  @override
  String myWrappedScreenWrappedDropsSoon(Object monthName) {
    return '$monthName 年度总结即将发布';
  }

  @override
  String myWrappedScreenYourWrappedIsBuilding(Object monthName) {
    return '正在生成你的 $monthName 年度总结...';
  }

  @override
  String get myWrappedViewAgain => '再次查看';

  @override
  String get myWrappedYourMonthlyWrapped => '你的月度回顾';

  @override
  String get navDiscover => '发现';

  @override
  String get navHome => '首页';

  @override
  String get navNutrition => '营养';

  @override
  String get navProfile => '个人';

  @override
  String get navProgress => '进度';

  @override
  String get navWorkout => '训练';

  @override
  String get navWorkouts => '训练';

  @override
  String get navYou => '我';

  @override
  String get navCoach => '教练';

  @override
  String get neatAchievementCardNew => '新！';

  @override
  String get neatActivityCardActive => '活跃';

  @override
  String get neatActivityCardDailyActivity => '每日活动';

  @override
  String get neatActivityCardGoalMet => '目标达成！';

  @override
  String neatActivityCardH(Object activeHours) {
    return '$activeHours 小时';
  }

  @override
  String get neatActivityCardSetUpStepGoals => '设置步数目标 →';

  @override
  String get neatActivityCardTrackYourDailySteps => '追踪你的每日步数和活动';

  @override
  String get neatDashboardDailyActivity => '每日活动';

  @override
  String get neatDashboardScreenActive => '活跃';

  @override
  String get neatDashboardScreenActiveHours => '活跃小时数';

  @override
  String get neatDashboardScreenActiveHoursNtoday => '今日\n活跃小时数';

  @override
  String get neatDashboardScreenAiCoachTip => 'AI 教练建议';

  @override
  String get neatDashboardScreenCalories => '卡路里';

  @override
  String get neatDashboardScreenComplete => '已完成';

  @override
  String get neatDashboardScreenGreatJobYouVe => '做得好！你今天已经达到了活跃小时数目标。';

  @override
  String get neatDashboardScreenHourlyActivity => '每小时活动';

  @override
  String get neatDashboardScreenIfBelow => '如果低于';

  @override
  String get neatDashboardScreenLongestNeatStreak => '最长 NEAT 连续记录';

  @override
  String get neatDashboardScreenMovementReminders => '活动提醒';

  @override
  String get neatDashboardScreenNeatScore => 'NEAT 分数';

  @override
  String neatDashboardScreenPartNeatScoreCardGoal(Object goal) {
    return '目标：$goal+';
  }

  @override
  String neatDashboardScreenPartNeatScoreCardOf(Object maxScore) {
    return '/ $maxScore';
  }

  @override
  String neatDashboardScreenPartNeatScoreCardValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String neatDashboardScreenPartStreaksCardDays(Object longestNeatScoreStreak) {
    return '$longestNeatScoreStreak 天';
  }

  @override
  String neatDashboardScreenPartStreaksCardMin(Object minutes) {
    return '$minutes分钟';
  }

  @override
  String neatDashboardScreenPartStreaksCardQuietHours(
    Object endTime,
    Object startTime,
  ) {
    return '静默时段: $startTime - $endTime';
  }

  @override
  String neatDashboardScreenPartStreaksCardSteps(Object stepsThreshold) {
    return '$stepsThreshold 步';
  }

  @override
  String neatDashboardScreenPartStreaksCardValue(Object points) {
    return '+$points';
  }

  @override
  String get neatDashboardScreenProgressive => '渐进式';

  @override
  String get neatDashboardScreenRecent => '近期';

  @override
  String get neatDashboardScreenRemindEvery => '提醒频率';

  @override
  String get neatDashboardScreenSeeAll => '查看全部';

  @override
  String get neatDashboardScreenStepGoal => '步数目标';

  @override
  String get neatDashboardScreenSteps => '步数';

  @override
  String get neatDashboardScreenStreaks => '连续记录';

  @override
  String get neatDashboardScreenUpNext => '接下来';

  @override
  String get neatDashboardScreenWorkHoursOnly9am => '仅工作时间 (9am - 5pm)';

  @override
  String get neatDashboardUnableToLoadData => '无法加载数据';

  @override
  String get neatGamificationWidgetsAccept => '接受';

  @override
  String get neatGamificationWidgetsAchievementUnlocked => '成就解锁！';

  @override
  String get neatGamificationWidgetsActive => '活跃';

  @override
  String get neatGamificationWidgetsActiveWalker => '活跃步行者';

  @override
  String get neatGamificationWidgetsCasualMover => '日常活动者';

  @override
  String get neatGamificationWidgetsClaimReward => '领取奖励';

  @override
  String get neatGamificationWidgetsCouchPotato => '沙发土豆';

  @override
  String neatGamificationWidgetsCurrentXp(Object arg0) {
    return '当前 XP $arg0';
  }

  @override
  String get neatGamificationWidgetsDailyChallenge => '每日挑战';

  @override
  String get neatGamificationWidgetsExpired => '已过期';

  @override
  String neatGamificationWidgetsHoursMinutesLeft(Object arg0, Object arg1) {
    return '剩余 $arg0 小时 $arg1 分钟';
  }

  @override
  String neatGamificationWidgetsLevel(Object level) {
    return '等级 $level';
  }

  @override
  String get neatGamificationWidgetsLevelUp => '升级！';

  @override
  String get neatGamificationWidgetsMaxLevel => '已达最高等级！';

  @override
  String neatGamificationWidgetsMinutesLeft(Object arg0) {
    return '剩余 $arg0 分钟';
  }

  @override
  String get neatGamificationWidgetsNeat => 'NEAT';

  @override
  String get neatGamificationWidgetsNeatChampion => '冠军';

  @override
  String get neatGamificationWidgetsNeatEnthusiast => '爱好者';

  @override
  String get neatGamificationWidgetsNeatPts => 'NEAT 积分';

  @override
  String get neatGamificationWidgetsNoRankingsYetThis => '本周暂无排名';

  @override
  String neatGamificationWidgetsPartNeatMilestonePopupStateXp(Object xpEarned) {
    return '+$xpEarned XP';
  }

  @override
  String get neatGamificationWidgetsScore => '分数';

  @override
  String neatGamificationWidgetsStepGoal(Object arg0) {
    return '步数目标 $arg0';
  }

  @override
  String get neatGamificationWidgetsSteps => '步数';

  @override
  String neatGamificationWidgetsTargetActiveHours(Object arg0) {
    return '目标活跃时长 $arg0';
  }

  @override
  String get neatGamificationWidgetsU1f3c6 => '🏆';

  @override
  String get neatGamificationWidgetsU26a1 => '⚡';

  @override
  String get neatGamificationWidgetsU2705 => '✅';

  @override
  String get neatGamificationWidgetsU2b50 => '⭐';

  @override
  String get neatGamificationWidgetsViewAll => '查看全部';

  @override
  String get neatGamificationWidgetsWeeklyLeaderboard => '每周排行榜';

  @override
  String neatGamificationWidgetsXpToNext(Object levelName, Object xpToNext) {
    return '$xpToNext XP 即可达到 $levelName';
  }

  @override
  String get neatGamificationWidgetsYou => '（你）';

  @override
  String get neatScoreDisplayNeatScore => 'NEAT 分数';

  @override
  String neatScoreDisplayNeatScoreOutOf(Object animatedScore, Object label) {
    return 'NEAT 分数：$animatedScore/100，等级：$label';
  }

  @override
  String get neatScoreDisplayScoreBreakdown => '分数明细';

  @override
  String get neatScoreDisplayTapForBreakdown => '点击查看明细';

  @override
  String neatScoreDisplayTrend(Object name) {
    return '趋势：$name';
  }

  @override
  String neatScoreDisplayValue(Object widget) {
    return '))(widget)';
  }

  @override
  String get netflixExerciseCarouselLoading => '加载中...';

  @override
  String get netflixExerciseCarouselSeeAll => '查看全部';

  @override
  String get netflixExercisesAddYourOwnExercises => '添加自定义动作，设置重复次数、组数和说明。';

  @override
  String get netflixExercisesAiSearchEG => 'AI 搜索（例如“胸部训练”）';

  @override
  String get netflixExercisesCustomExercises => '自定义动作';

  @override
  String get netflixExercisesEquipment => '器械';

  @override
  String get netflixExercisesExercisesByMuscle => '按肌肉部位分类';

  @override
  String get netflixExercisesFailedToLoadExercises => '加载动作失败';

  @override
  String get netflixExercisesGotIt => '知道了';

  @override
  String get netflixExercisesTab => ' • ';

  @override
  String get netflixExercisesTabAllExercises => '所有动作';

  @override
  String get netflixExercisesTabClearFilters => '清除筛选';

  @override
  String get netflixExercisesTabClearSearch => '清除搜索';

  @override
  String get netflixExercisesTabCreate => '创建';

  @override
  String get netflixExercisesTabCreateYourOwnExercises => '通过照片和 AI 分析创建你自己的动作';

  @override
  String get netflixExercisesTabMyCustomExercises => '我的自定义动作';

  @override
  String get netflixExercisesTabNoCustomExercisesYet => '暂无自定义动作';

  @override
  String get netflixExercisesTabNoExercisesFound => '未找到相关动作';

  @override
  String netflixExercisesTabPartExerciseListCardDaysWeek(
    Object daysPerWeek,
    Object duration,
  ) {
    return '$daysPerWeek 天/周 • $duration';
  }

  @override
  String netflixExercisesTabPartExerciseListCardFlexible(Object duration) {
    return '灵活 • $duration';
  }

  @override
  String get netflixExercisesTabSearching => '搜索中...';

  @override
  String get netflixExercisesTabTrainingSplits => '训练计划';

  @override
  String netflixExercisesTabUiAllExercisesLoaded(Object length) {
    return '已加载全部 $length 个动作';
  }

  @override
  String get newTilesAmazingStreakKeepGoing => '连胜太棒了！继续保持！';

  @override
  String newTilesPartActiveChallengeCardDayOf(
    Object currentDay,
    Object totalDays,
  ) {
    return '第 $currentDay 天，共 $totalDays 天';
  }

  @override
  String newTilesPartActiveChallengeCardRestingBpm(Object restingBPM) {
    return '静息心率: $restingBPM BPM';
  }

  @override
  String newTilesPartActiveChallengeCardTodayReps(
    Object targetReps,
    Object todayReps,
  ) {
    return '今日: $todayReps / $targetReps 次';
  }

  @override
  String newTilesPartActiveChallengeCardValue(Object match) {
    return '$match,';
  }

  @override
  String get newTilesPartAskCoachForMore => '向教练咨询更多建议';

  @override
  String get newTilesPartCoachTip => '教练建议';

  @override
  String get newTilesPartCompleteWorkoutsToEarn => '完成训练以获得 PR';

  @override
  String get newTilesPartConnectHealthToTrack => '连接健康应用以进行追踪';

  @override
  String get newTilesPartDayStreak => '天连胜';

  @override
  String get newTilesPartGettingYourPersonalizedTip => '正在获取你的个性化建议...';

  @override
  String get newTilesPartHeartRate => '心率';

  @override
  String get newTilesPartMyJourney => '我的历程';

  @override
  String get newTilesPartPersonalRecords => '个人纪录';

  @override
  String newTilesPartPersonalRecordsCardH(Object sleepHours) {
    return '$sleepHours 小时';
  }

  @override
  String newTilesPartPersonalRecordsCardKg(Object change) {
    return '$change kg';
  }

  @override
  String newTilesPartPersonalRecordsCardValue(Object rank) {
    return '第 $rank 名';
  }

  @override
  String get newTilesPartProgressCharts => '进度图表';

  @override
  String get newTilesPartRank => '排名';

  @override
  String get newTilesPartRecentWorkouts => '近期训练';

  @override
  String get newTilesPartRestDayRecovery => '休息日恢复';

  @override
  String get newTilesPartSleep => '睡眠';

  @override
  String get newTilesPartSteps => '步数';

  @override
  String get newTilesPartTapToSeeYour => '点击查看你的完整历程';

  @override
  String get newTilesPartThisWeek => '本周';

  @override
  String get newTilesPartViewAll => '查看全部';

  @override
  String get newTilesPartViewCharts => '查看图表';

  @override
  String get newTilesPartViewStrengthAndVolume => '查看力量和容量趋势';

  @override
  String get newTilesPartWater => '饮水';

  @override
  String get newTilesPartWeight => '体重';

  @override
  String get newTilesStreak => '连胜';

  @override
  String newspaperTemplateContinuedOnPage(Object completedAt) {
    return '续见第 $completedAt 页';
  }

  @override
  String newspaperTemplateExpertsStunnedByPerformance(Object topEx) {
    return '“专家对 $topEx 的表现感到震惊”';
  }

  @override
  String newspaperTemplateLiftsInGruelingSession(Object name, Object volLabel) {
    return '$name 在高强度训练中举起 $volLabel';
  }

  @override
  String get newspaperTemplateTheNumbers => '数字';

  @override
  String get newspaperTemplateTheZealovaTimes => '热忱时代';

  @override
  String get nextSetPreviewAiRecommendation => 'AI 推荐';

  @override
  String get nextSetPreviewAnalyzing => '正在分析您的表现...';

  @override
  String get nextSetPreviewAnalyzingPerformance => '正在分析表现';

  @override
  String get nextSetPreviewCalculating => '正在计算下一组...';

  @override
  String get nextSetPreviewCalculatingOptimalNextSet => '正在计算最佳下一组数据...';

  @override
  String nextSetPreviewCardIntensity(Object intensityPercentage) {
    return '$intensityPercentage% 强度';
  }

  @override
  String nextSetPreviewCardKg(Object recommendedWeight) {
    return '$recommendedWeight kg';
  }

  @override
  String nextSetPreviewCardKg2(Object weightDelta) {
    return ')(weightDelta) kg';
  }

  @override
  String nextSetPreviewCardValue(Object weightDelta) {
    return ')(weightDelta)';
  }

  @override
  String nextSetPreviewCardX(Object recommendedReps) {
    return 'x $recommendedReps';
  }

  @override
  String get nextSetPreviewFinal => '最后一组';

  @override
  String get nextSetPreviewKg => ' 公斤';

  @override
  String get nextSetPreviewNextSet => '下一组';

  @override
  String get nextSetPreviewReps => ' 次';

  @override
  String get nextSetPreviewUse => '使用';

  @override
  String get nextSetPreviewUseThis => '使用此组';

  @override
  String get nextWorkoutCardCouldNotSkipWorkout => '无法跳过训练。请重试。';

  @override
  String get nextWorkoutCardQuick => '快速';

  @override
  String get nextWorkoutCardRegenerate => '重新生成';

  @override
  String get nextWorkoutCardSkipWorkout => '跳过训练？';

  @override
  String get nextWorkoutCardThisWorkoutWillBe => '此训练将被标记为跳过，且不会计入你的每周目标。';

  @override
  String get nextWorkoutCardUpcoming => '即将开始';

  @override
  String nextWorkoutCardValue(Object count) {
    return '+$count';
  }

  @override
  String get nextWorkoutCardWorkoutRegenerated => '训练已重新生成！';

  @override
  String get nextWorkoutCardWorkoutSkipped => '训练已跳过';

  @override
  String get notificationBellButtonNotifications => '通知';

  @override
  String get notificationPrimeEnableNotifications => '开启通知';

  @override
  String get notificationPrimeNotNow => '暂不';

  @override
  String get notificationPrimePrCelebrations => 'PR 庆祝';

  @override
  String notificationPrimeScreenTurnOnNotificationsSo(Object appName) {
    return '开启通知，以便 $appName 在关键时刻为您提供指导。';
  }

  @override
  String get notificationPrimeStayOnTrackWith => '通过贴心提醒保持进度';

  @override
  String get notificationPrimeStreakSaves => '连续打卡保护';

  @override
  String get notificationPrimeWorkoutReminders => '训练提醒';

  @override
  String get notificationPrimeYouCanChangeThis => '您可以随时在设置中更改此项。';

  @override
  String get notificationTestAiCoachMessage => 'AI教练消息';

  @override
  String get notificationTestBasicTest => '基础测试';

  @override
  String get notificationTestBreakfastReminder => '早餐提醒';

  @override
  String get notificationTestDinnerReminder => '晚餐提醒';

  @override
  String get notificationTestGoodProgress70 => '进展良好 (70%)';

  @override
  String get notificationTestGuilt1DayMissed => '愧疚感（错过1天）';

  @override
  String get notificationTestGuilt2DaysMissed => '愧疚感（错过2天）';

  @override
  String get notificationTestGuilt3DaysMissed => '愧疚感（错过3天以上）';

  @override
  String get notificationTestHeyYourAiCoach => '\"嘿！我是您的AI教练 💪\"';

  @override
  String get notificationTestImmediateLocalNotification => '立即本地通知';

  @override
  String get notificationTestItSBeenX => '\"已经过去X天了！😱\"';

  @override
  String get notificationTestKeepItUpAlmost => '\"继续保持！💧 快完成了！\"';

  @override
  String get notificationTestLowProgress40 => '进展缓慢 (40%)';

  @override
  String get notificationTestLunchReminder => '午餐提醒';

  @override
  String get notificationTestNoPendingNotificationsSched => '没有待处理的定时通知';

  @override
  String get notificationTestNoTitle => '无标题';

  @override
  String get notificationTestNotificationTesting => '通知测试';

  @override
  String get notificationTestScheduleIn10Seconds => '10秒后定时';

  @override
  String get notificationTestScheduleIn60Seconds => '60秒后定时';

  @override
  String notificationTestScreenId(Object id) {
    return 'ID: $id';
  }

  @override
  String notificationTestScreenPendingNotifications(Object length) {
    return '待处理通知 ($length)';
  }

  @override
  String notificationTestScreenValue(Object key) {
    return '$key:';
  }

  @override
  String get notificationTestShowsANotificationRight => '立即显示通知';

  @override
  String get notificationTestShowsAllScheduledNotificati => '显示所有已定时通知';

  @override
  String get notificationTestShowsCurrentTimezoneSetting => '显示当前时区设置';

  @override
  String get notificationTestStayHydratedYouRe => '\"记得补水！💧 您已完成40%\"';

  @override
  String get notificationTestTestsScheduledNotificationD => '测试定时通知发送';

  @override
  String get notificationTestTheseAreLocalNotifications =>
      '这些是本地通知（非Firebase）。使用这些来测试定时通知在您的设备上是否正常工作。';

  @override
  String get notificationTestTheseNotificationsAreSent =>
      '这些通知是通过后端Firebase Cloud Messaging发送的。';

  @override
  String get notificationTestTimeToLogYour => '\"该记录早餐了！📸\"';

  @override
  String get notificationTestTimeToLogYour2 => '\"该记录午餐了！📸\"';

  @override
  String get notificationTestTimeToLogYour3 => '\"该记录晚餐了！📸\"';

  @override
  String get notificationTestTimeToTrain => '\"该训练了！💪\"';

  @override
  String get notificationTestTimezoneInfo => '时区信息';

  @override
  String get notificationTestViewPendingNotifications => '查看待处理通知';

  @override
  String get notificationTestViewTimezoneInfo => '查看时区信息';

  @override
  String get notificationTestWorkoutReminder => '训练提醒';

  @override
  String get notificationTestYourAiCoachIs => '\"您的AI教练感到孤单了... 🥺\"';

  @override
  String get notificationTestYourAiCoachIs2 => '\"您的AI教练已就绪！💪\"';

  @override
  String get notificationTestYourMusclesMissYou => '\"您的肌肉想念您了！💪\"';

  @override
  String get notifications3Day => '3次/天';

  @override
  String get notifications45Day => '4-5次/天';

  @override
  String get notifications810Day => '8-10次/天';

  @override
  String get notificationsAdvanced => '高级';

  @override
  String get notificationsAnomalyAlerts => '异常提醒';

  @override
  String get notificationsBalanced => '均衡';

  @override
  String get notificationsBreakfast => '早餐';

  @override
  String get notificationsBreakfastLunchDinner => '早餐、午餐和晚餐';

  @override
  String get notificationsClearAll => '全部清除';

  @override
  String get notificationsCycleReminders => '周期提醒';

  @override
  String get notificationsDay => '天';

  @override
  String get notificationsDeliveryTime => '发送时间';

  @override
  String get notificationsDifferentScheduleOnSat => '周六和周日使用不同时间表';

  @override
  String get notificationsDinner => '晚餐';

  @override
  String get notificationsDuolingoStyleNudgesWhen => '不活跃时发送Duolingo风格的提醒';

  @override
  String get notificationsEnd => '结束';

  @override
  String get notificationsEvening => '傍晚';

  @override
  String get notificationsFailedToAcceptRequest => '无法接受请求。请重试。';

  @override
  String get notificationsFailedToIgnoreRequest => '无法忽略请求。请重试。';

  @override
  String get notificationsFailedToLoadNotifications => '无法加载通知';

  @override
  String get notificationsFineTuneIndividualNotificat => '微调各类通知';

  @override
  String get notificationsFriendRequestIgnored => '好友请求已忽略';

  @override
  String get notificationsFullCoach => '全能教练';

  @override
  String get notificationsGuiltNotifications => '愧疚感提醒';

  @override
  String get notificationsHeadsUpWhenResting => '静息心率偏高时提醒';

  @override
  String get notificationsHourlyDuringWorkHours => '工作时间内每小时提醒';

  @override
  String get notificationsIncludeEmoji => '包含表情符号';

  @override
  String get notificationsLunch => '午餐';

  @override
  String get notificationsMarkAllAsRead => '全部标记为已读';

  @override
  String get notificationsMealReminders => '饮食提醒';

  @override
  String get notificationsMidday => '中午';

  @override
  String get notificationsMinimal => '极简';

  @override
  String get notificationsMorning => '早晨';

  @override
  String get notificationsMorningReadinessCheckIn => '早晨状态签到';

  @override
  String get notificationsMovementHydration => '运动 + 补水';

  @override
  String get notificationsNoNotificationsInThis => '此类别下无通知';

  @override
  String get notificationsNotificationFrequency => '通知频率';

  @override
  String get notificationsNotifications => '通知';

  @override
  String get notificationsNudgeTime => '提醒时间';

  @override
  String get notificationsPeriodFertilityAndLogging => '经期、生育能力和记录提醒';

  @override
  String get notificationsRecommended => '推荐';

  @override
  String get notificationsRemindEvery => '提醒频率';

  @override
  String get notificationsRemindOnWorkoutDays => '仅在训练日提醒';

  @override
  String get notificationsReminderTime => '提醒时间';

  @override
  String get notificationsReminderWhenYouRe => '当步数未达标时提醒我';

  @override
  String get notificationsScreenPartAccept => '接受';

  @override
  String get notificationsScreenPartIgnore => '忽略';

  @override
  String get notificationsScreenPartNoNotificationsYet => '暂无通知';

  @override
  String get notificationsScreenPartWhatToExpect => '你会收到什么';

  @override
  String get notificationsScreenPartYourAiCoachWill =>
      '你的AI教练会在这里向你发送训练提醒、激励信息和进度更新。';

  @override
  String notificationsScreenYouAndAreNow(Object fromUserName) {
    return '您和 $fromUserName 现在是好友了！';
  }

  @override
  String get notificationsShowEmojiInNotification => '在通知文本中显示表情符号';

  @override
  String get notificationsStayHydratedThroughoutThe => '全天保持水分充足';

  @override
  String get notificationsTime => '时间';

  @override
  String get notificationsWaterReminders => '饮水提醒';

  @override
  String get notificationsWeekendTimes => '周末时间';

  @override
  String get notificationsWeeklyReport => '每周报告';

  @override
  String get notificationsWorkoutBreakfast => '训练 + 早餐';

  @override
  String get notificationsWorkoutReminders => '训练提醒';

  @override
  String get notificationsYourFriendIsDoing => '你的好友正在进行你的训练！';

  @override
  String get notificationsYourProgressSummary => '你的进度摘要';

  @override
  String get notifsAllowButton => '允许通知';

  @override
  String get notifsLaterButton => '稍后再说';

  @override
  String get notifsPrimerBody => '获取训练和打卡提醒。';

  @override
  String get notifsPrimerTitle => '保持节奏';

  @override
  String numberInputWidgetsTarget(Object targetReps) {
    return '目标 ($targetReps)';
  }

  @override
  String numberInputWidgetsTarget2(Object targetReps) {
    return '目标：$targetReps';
  }

  @override
  String numberInputWidgetsValue(Object accuracyPercent) {
    return '$accuracyPercent%';
  }

  @override
  String nutrientExplorerAddedToPinnedNutrients(Object displayName) {
    return '已将 $displayName 添加到固定营养素';
  }

  @override
  String get nutrientExplorerCurrent => '当前';

  @override
  String get nutrientExplorerFailedToUpdatePinned => '无法更新置顶营养素';

  @override
  String get nutrientExplorerFattyAcids => '脂肪酸';

  @override
  String get nutrientExplorerMinerals => '矿物质';

  @override
  String get nutrientExplorerNutrientsThatMatterMost => '你当前周期阶段最重要的营养素';

  @override
  String get nutrientExplorerPartCeiling => '上限';

  @override
  String get nutrientExplorerPartFloor => '下限';

  @override
  String get nutrientExplorerPartHigh => '高';

  @override
  String get nutrientExplorerPartLogSomeFoodTo => '记录一些食物以查看你的微量营养素摄入情况';

  @override
  String get nutrientExplorerPartLow => '低';

  @override
  String get nutrientExplorerPartNoNutrientData => '无营养数据';

  @override
  String get nutrientExplorerPartNutrientScore => '营养评分';

  @override
  String nutrientExplorerPartNutrientScoreCardCurrent(
    Object currentValue,
    Object unit,
  ) {
    return '当前: $currentValue$unit';
  }

  @override
  String nutrientExplorerPartNutrientScoreCardNutrients(Object length) {
    return '$length 种营养素';
  }

  @override
  String nutrientExplorerPartNutrientScoreCardOptimal(
    Object optimalCount,
    Object totalCount,
  ) {
    return '$optimalCount/$totalCount 项达标';
  }

  @override
  String nutrientExplorerPartNutrientScoreCardValue(Object score) {
    return '$score%';
  }

  @override
  String nutrientExplorerPartNutrientScoreCardValue2(Object percentage) {
    return '$percentage%';
  }

  @override
  String get nutrientExplorerPartOptimal => '最佳';

  @override
  String get nutrientExplorerPartRefresh => '刷新';

  @override
  String get nutrientExplorerPartScore => '评分';

  @override
  String get nutrientExplorerPartTarget => '目标';

  @override
  String get nutrientExplorerPinToDashboard => '置顶到仪表板';

  @override
  String get nutrientExplorerPrioritisedForYourCycle => '针对你的周期阶段优先推荐';

  @override
  String nutrientExplorerRemovedFromPinnedNutrients(Object displayName) {
    return '已将 $displayName 从固定营养素移除';
  }

  @override
  String nutrientExplorerTarget(Object unit) {
    return '目标 $unit';
  }

  @override
  String get nutrientExplorerTopContributors => '主要来源';

  @override
  String get nutrientExplorerUnknown => '未知';

  @override
  String get nutrientExplorerUnpinNutrient => '取消置顶营养素';

  @override
  String nutrientExplorerValue(Object unit) {
    return ') (unit)';
  }

  @override
  String get nutrientExplorerVitamins => '维生素';

  @override
  String get nutrientRushGameCatchTheGoldenZealova => '抓住金色 Zealova 标记以获得强化！';

  @override
  String get nutrientRushGameNewBest => '🎉 新纪录！';

  @override
  String get nutrientRushGameNewPersonalBest => '🎉 新个人纪录！';

  @override
  String get nutrientRushGameNutrientRushFriends => 'Nutrient Rush — 好友';

  @override
  String nutrientRushGameS(Object _stageNumber) {
    return 'S$_stageNumber';
  }

  @override
  String get nutrientRushGameStageClear => '🔥 关卡完成';

  @override
  String nutrientRushGameX(Object _combo) {
    return 'x$_combo';
  }

  @override
  String nutrientRushGameYou(Object name) {
    return '$name (你)';
  }

  @override
  String nutrientRushGameYourBest(Object best) {
    return '你的最高分: $best';
  }

  @override
  String get nutritionAlreadyInMyFoods => '已在“我的食物”中';

  @override
  String get nutritionCaloriesByCyclePhase => '各周期阶段热量';

  @override
  String get nutritionCookingUpYourRecipe => '正在后台为你生成食谱……';

  @override
  String get nutritionCouldNotLoadCycle => '无法加载周期叠加层';

  @override
  String get nutritionDailyTab => '今日';

  @override
  String get nutritionErrorStatePleaseCheckYourConnection => '请检查你的网络连接并重试';

  @override
  String get nutritionErrorStateTryAgain => '重试';

  @override
  String get nutritionErrorStateUnableToLoadNutrition => '无法加载营养数据';

  @override
  String get nutritionFailedToSaveFood => '保存食物失败';

  @override
  String get nutritionFastingCardAllergens => '过敏原';

  @override
  String get nutritionFastingCardBodyCompositionTarget => '身体成分目标';

  @override
  String nutritionFastingCardCal(Object currentCalories) {
    return '$currentCalories 卡路里';
  }

  @override
  String get nutritionFastingCardDailyTarget => '每日目标';

  @override
  String get nutritionFastingCardDietType => '饮食类型';

  @override
  String get nutritionFastingCardEditNutritionSettings => '编辑营养设置';

  @override
  String get nutritionFastingCardFastingProtocol => '断食方案';

  @override
  String nutritionFastingCardG(Object protein) {
    return '${protein}g';
  }

  @override
  String nutritionFastingCardG2(Object carbs) {
    return '${carbs}g';
  }

  @override
  String nutritionFastingCardG3(Object fat) {
    return '${fat}g';
  }

  @override
  String get nutritionFastingCardGoalWeight => '目标体重';

  @override
  String get nutritionFastingCardMacros => '宏量营养素';

  @override
  String get nutritionFastingCardMaintainWeight => '维持体重';

  @override
  String get nutritionFastingCardNutritionFasting => '营养与断食';

  @override
  String get nutritionFastingCardRestrictions => '限制';

  @override
  String get nutritionFastingCardTargetDate => '目标日期';

  @override
  String get nutritionFastingCardWeeklyRate => '每周进度';

  @override
  String get nutritionFastingConfigureYourEatingSchedule => '配置你的进食时间表';

  @override
  String get nutritionFastingFastingProtocol => '断食方案';

  @override
  String get nutritionFastingIntermittentFasting => '间歇性断食';

  @override
  String get nutritionFastingNutritionFasting => '营养与断食';

  @override
  String get nutritionFastingProtocol => '方案';

  @override
  String get nutritionFastingSleep => '睡眠';

  @override
  String get nutritionFastingWake => '起床';

  @override
  String get nutritionFuel => '能量补给';

  @override
  String get nutritionGoalsCardBmrBasalMetabolicRate => 'BMR (基础代谢率)';

  @override
  String nutritionGoalsCardBurned(Object caloriesBurned) {
    return '消耗 $caloriesBurned kcal';
  }

  @override
  String get nutritionGoalsCardCalories => '热量';

  @override
  String get nutritionGoalsCardCarbs => '碳水化合物';

  @override
  String get nutritionGoalsCardDailyCalorieTarget => '每日热量目标';

  @override
  String get nutritionGoalsCardDailyGoals => '每日目标';

  @override
  String get nutritionGoalsCardEditTargets => '编辑目标';

  @override
  String get nutritionGoalsCardFat => '脂肪';

  @override
  String get nutritionGoalsCardFemaleConstant => '女性常数';

  @override
  String get nutritionGoalsCardFemalesHaveDifferentBody => '女性的身体成分不同';

  @override
  String get nutritionGoalsCardGoalAdjustment => '目标调整';

  @override
  String get nutritionGoalsCardHowYourTargetsAre => '目标计算方式';

  @override
  String get nutritionGoalsCardMaleConstant => '男性常数';

  @override
  String get nutritionGoalsCardMalesHaveMoreLean => '男性的瘦体重更多';

  @override
  String get nutritionGoalsCardMetabolismSlowsWithAge => '新陈代谢随年龄增长而减慢';

  @override
  String get nutritionGoalsCardMifflinStJeorFormula =>
      'Mifflin-St Jeor 公式 · 点击查看详情';

  @override
  String get nutritionGoalsCardMifflinStJeorFormula2 =>
      'Mifflin-St Jeor 公式（个人资料数据不足，无法进行细分）';

  @override
  String get nutritionGoalsCardMoreMassMoreEnergy => '质量越大 = 静息时消耗的能量越多';

  @override
  String nutritionGoalsCardPartCalculationInfoSheetActivityMultiplier(
    Object activityMultiplier,
  ) {
    return '活动系数 (×$activityMultiplier)';
  }

  @override
  String nutritionGoalsCardPartCalculationInfoSheetCal(Object bmr) {
    return '= $bmr cal';
  }

  @override
  String nutritionGoalsCardPartCalculationInfoSheetCm(Object height) {
    return '6.25 × $height cm';
  }

  @override
  String nutritionGoalsCardPartCalculationInfoSheetG(Object grams) {
    return '${grams}g';
  }

  @override
  String nutritionGoalsCardPartCalculationInfoSheetG2(Object target) {
    return '/${target}g';
  }

  @override
  String nutritionGoalsCardPartCalculationInfoSheetKg(Object weight) {
    return '10 × $weight kg';
  }

  @override
  String nutritionGoalsCardPartCalculationInfoSheetMacroSplit(
    Object carbPct,
    Object displayName,
    Object fatPct,
    Object proteinPct,
  ) {
    return '宏量营养素比例 ($displayName: $carbPct/$proteinPct/$fatPct)';
  }

  @override
  String nutritionGoalsCardPartCalculationInfoSheetValue(Object displayValue) {
    return '= $displayValue';
  }

  @override
  String nutritionGoalsCardPartCalculationInfoSheetValue2(Object pct) {
    return '$pct%';
  }

  @override
  String nutritionGoalsCardPartCalculationInfoSheetValue3(Object label) {
    return '$label: ';
  }

  @override
  String nutritionGoalsCardPartCalculationInfoSheetYrs(Object age) {
    return '5 × $age 岁';
  }

  @override
  String get nutritionGoalsCardProtein => '蛋白质';

  @override
  String get nutritionGoalsCardRecalculate => '重新计算';

  @override
  String get nutritionGoalsCardTallerLargerSurfaceArea => '身高越高 = 表面积越大';

  @override
  String get nutritionGoalsCardTdeeDailyEnergyNeeds => 'TDEE（每日能量需求）';

  @override
  String get nutritionJumpToToday => '跳转至今天';

  @override
  String get nutritionLogAFewDays => '记录几天数据以查看周期叠加图';

  @override
  String get nutritionLogFood => '记录食物';

  @override
  String get nutritionLogSomeFoodFirst => '请先记录一些食物以便分享';

  @override
  String get nutritionLogSomeMealsFirst => '请先记录一些餐食以便分享';

  @override
  String get nutritionMealDeleted => '餐食已删除';

  @override
  String get nutritionPatterns45MinReminderPush => '45分钟提醒推送';

  @override
  String get nutritionPatternsAiGuess => 'AI 猜测';

  @override
  String get nutritionPatternsAiMoodGuesses => 'AI 心情猜测';

  @override
  String get nutritionPatternsAutoInferMoodFrom => '跳过打卡时，自动根据营养摄入推断心情';

  @override
  String get nutritionPatternsBasedOnTheLast => '基于过去90天的数据';

  @override
  String get nutritionPatternsCalorieTrends => '热量趋势';

  @override
  String get nutritionPatternsCheckInInsights => '打卡与洞察';

  @override
  String get nutritionPatternsCheckInsAreOff => '打卡功能已关闭';

  @override
  String get nutritionPatternsFoodsHighestIn => '含量最高的食物…';

  @override
  String get nutritionPatternsFoodsThatDragYou => '让你状态变差的食物';

  @override
  String get nutritionPatternsFoodsThatEnergizeYou => '让你充满活力的食物';

  @override
  String get nutritionPatternsLog3MealsWith =>
      '记录3顿以上餐食并进行打卡，即可查看哪些食物为你供能，哪些让你状态变差。';

  @override
  String get nutritionPatternsLogAFewMeals => '记录几顿餐食以查看你的宏量营养素趋势。';

  @override
  String get nutritionPatternsLoggedMealsWillShow => '已记录的餐食将在此处以时间轴形式显示。';

  @override
  String get nutritionPatternsMealHistory => '餐食历史';

  @override
  String get nutritionPatternsNeedMoreDaysOf => '需要更多天数的数据';

  @override
  String get nutritionPatternsNoFoodsYet => '暂无食物';

  @override
  String get nutritionPatternsNoMealsLogged => '暂无餐食记录';

  @override
  String get nutritionPatternsNoPatternsYet => '暂无模式';

  @override
  String get nutritionPatternsNudgeIfYouSkip => '如果跳过打卡则进行提醒';

  @override
  String get nutritionPatternsNutritionTrends => '营养趋势';

  @override
  String get nutritionPatternsPostMealCheckIn => '餐后打卡';

  @override
  String get nutritionPatternsReEnable => '重新启用';

  @override
  String get nutritionPatternsReEnableThePost => '重新启用餐后打卡表单，开始建立你的食物与心情模式。';

  @override
  String get nutritionPatternsSignInToSee => '登录以查看你的模式';

  @override
  String get nutritionJournalTab => 'Journal';

  @override
  String get nutritionPatternsTab => '模式';

  @override
  String nutritionPatternsTabG(Object grams, Object pct) {
    return '${grams}g · $pct%';
  }

  @override
  String nutritionPatternsTabG2(Object grams) {
    return '${grams}g';
  }

  @override
  String nutritionPatternsTabGoalKcal(Object calorieGoal) {
    return '目标: $calorieGoal kcal';
  }

  @override
  String nutritionPatternsTabKcalDay(Object avgCalories) {
    return '$avgCalories kcal/天';
  }

  @override
  String nutritionPatternsTabKcalPGC(Object c, Object cal, Object f, Object p) {
    return '$cal kcal · P ${p}g · C ${c}g · F ${f}g';
  }

  @override
  String nutritionPatternsTabLogMealsToSee(Object _METRICS) {
    return '记录饮食以查看你的主要 $_METRICS 来源。';
  }

  @override
  String nutritionPatternsTabNoMealsThis(Object range) {
    return '本 $range 无饮食记录';
  }

  @override
  String nutritionPatternsTabViewAll(Object length) {
    return '查看全部 $length';
  }

  @override
  String get nutritionPatternsTheQuickHowDo => '记录后快速回答“你感觉如何？”的表单';

  @override
  String get nutritionPatternsTodaySMacros => '今日宏量营养素';

  @override
  String get nutritionPatternsYourBodySResponses => '你身体的反应';

  @override
  String get nutritionPreferencesAdd => '添加…';

  @override
  String get nutritionPreferencesDailyFoodBudgetUsd => '每日食品预算（美元，可选）';

  @override
  String get nutritionPreferencesDietAllergens => '饮食与过敏原';

  @override
  String get nutritionPreferencesDishesOrIngredientsYou => '我们应在推荐中隐藏的菜肴或配料';

  @override
  String get nutritionPreferencesDislikes => '不喜欢的食物';

  @override
  String get nutritionPreferencesFoodBudget => '食品预算';

  @override
  String get nutritionPreferencesFoodsToAvoid => '要避免的食物';

  @override
  String get nutritionPreferencesInflammationTolerance => '炎症耐受度';

  @override
  String get nutritionPreferencesLenient => '宽松';

  @override
  String get nutritionPreferencesMealBudgetUsd => '单餐预算（美元）';

  @override
  String get nutritionPreferencesNutritionPreferences => '营养偏好';

  @override
  String get nutritionPreferencesOtherAllergens => '其他过敏原';

  @override
  String get nutritionPreferencesOutsideTheFdaBig =>
      'FDA“九大”过敏原之外（例如：芒果、茄科植物、玉米）';

  @override
  String get nutritionRecipesTab => '食谱';

  @override
  String get nutritionReview => '回顾';

  @override
  String get nutritionSavedToMyFoods => '已保存至我的食物';

  @override
  String get nutritionScheduling => '正在安排…';

  @override
  String get nutritionScoreCardLogYourMealsTo => '记录你的餐食以查看营养评分细分。';

  @override
  String get nutritionScoreCardNutritionScore => '营养评分';

  @override
  String nutritionScoreCardValue(Object percent) {
    return '$percent%';
  }

  @override
  String get nutritionScoreCardWeeklyNutritionAdherence => '每周营养依从性';

  @override
  String nutritionScreenUpdatedYourDailyTarget(Object newCalories) {
    return '已更新您的每日目标：$newCalories 卡路里/天 ';
  }

  @override
  String nutritionScreenWasWeFixedHow(Object oldCalories) {
    return '（原为 $oldCalories）。我们修正了热量缺口的计算方式 ';
  }

  @override
  String get nutritionSettingsAdjustAiCalorieEstimates => '调整 AI 热量估算以符合你的实际情况';

  @override
  String get nutritionSettingsAlwaysRules => '始终规则';

  @override
  String get nutritionSettingsCalmMode => '平静模式';

  @override
  String get nutritionSettingsCalorieEstimateBias => '热量估算偏差';

  @override
  String get nutritionSettingsCompactTrackerView => '紧凑追踪视图';

  @override
  String get nutritionSettingsDisableAiFoodTips => '禁用 AI 食物建议';

  @override
  String get nutritionSettingsManageYourFoodLibrary => '管理你的食物库以便快速记录';

  @override
  String get nutritionSettingsNutritionSettings => '营养设置';

  @override
  String get nutritionSettingsPostMealCheckIn => '餐后打卡';

  @override
  String get nutritionSettingsQuickLogMode => '快速记录模式';

  @override
  String get nutritionSettingsRestDayReduction => '休息日减量';

  @override
  String get nutritionSettingsSavedFoodsRecipes => '已保存的食物与食谱';

  @override
  String get nutritionSettingsScreenAllergens => '过敏原';

  @override
  String get nutritionSettingsScreenBudget => '预算';

  @override
  String get nutritionSettingsScreenCalorieEstimateBias => '热量估算偏差';

  @override
  String get nutritionSettingsScreenCalories => '热量';

  @override
  String get nutritionSettingsScreenCarbs => '碳水化合物';

  @override
  String get nutritionSettingsScreenCookingSkill => '烹饪水平';

  @override
  String get nutritionSettingsScreenCookingTimeMinutes => '烹饪时间（分钟）';

  @override
  String get nutritionSettingsScreenCurrentTargets => '当前目标';

  @override
  String get nutritionSettingsScreenDietaryRestrictions => '饮食限制';

  @override
  String get nutritionSettingsScreenDue => '到期';

  @override
  String get nutritionSettingsScreenEditNutritionGoals => '编辑营养目标';

  @override
  String get nutritionSettingsScreenEditTargets => '编辑目标';

  @override
  String nutritionSettingsScreenErrorSavingSettings(Object e) {
    return '保存设置出错：$e';
  }

  @override
  String get nutritionSettingsScreenFat => '脂肪';

  @override
  String get nutritionSettingsScreenFoodPreferences => '食物偏好';

  @override
  String get nutritionSettingsScreenGoalsUpdatedAndTargets => '目标已更新，目标值已重新计算！';

  @override
  String get nutritionSettingsScreenMealPattern => '用餐模式';

  @override
  String get nutritionSettingsScreenNoGoalsSet => '未设定目标';

  @override
  String get nutritionSettingsScreenPrimary => '主要';

  @override
  String get nutritionSettingsScreenProtein => '蛋白质';

  @override
  String get nutritionSettingsScreenRateOfChange => '变化率';

  @override
  String get nutritionSettingsScreenRecalculateFromProfile => '根据个人资料重新计算';

  @override
  String get nutritionSettingsScreenReviewAdjustTargets => '查看并调整目标';

  @override
  String get nutritionSettingsScreenRunWeeklyCheckIn => '进行每周打卡';

  @override
  String get nutritionSettingsScreenSaveRecalculate => '保存并重新计算';

  @override
  String get nutritionSettingsScreenSelectYourGoalsFirst =>
      '选择你的目标（第一个选中的为主要目标）';

  @override
  String get nutritionSettingsScreenTrainingDay => '训练日';

  @override
  String nutritionSettingsScreenUi1Value(Object length) {
    return '+$length';
  }

  @override
  String nutritionSettingsScreenUiExampleACalMeal(Object exampleCal) {
    return '示例：600 卡路里的餐食将记录为 $exampleCal 卡路里';
  }

  @override
  String nutritionSettingsScreenUiMin(Object t) {
    return '$t 分钟';
  }

  @override
  String nutritionSettingsScreenUiX(Object multiplier) {
    return '${multiplier}x';
  }

  @override
  String get nutritionSettingsScreenUnderMore => '在“更多”下方';

  @override
  String get nutritionSettingsScreenWeeklyGoal => '每周目标';

  @override
  String get nutritionSettingsScreenYourGoals => '你的目标';

  @override
  String get nutritionSettingsScreenYourPreferences => '你的偏好';

  @override
  String get nutritionSettingsShowMacrosOnLog => '在记录中显示宏量营养素';

  @override
  String get nutritionSettingsStandingRulesZealovaApplies =>
      'Zealova 应用于每次食物分析的固定规则';

  @override
  String get nutritionSettingsStreakFreezeUsedYour => '已使用连续打卡冻结！你的连续记录已受保护。';

  @override
  String get nutritionSettingsTargetsRecalculatedFromYour => '已根据你的个人资料重新计算目标。';

  @override
  String get nutritionSettingsTrainingDayBoost => '训练日加成';

  @override
  String get nutritionSettingsWeeklyCheckInReminders => '每周打卡提醒';

  @override
  String get nutritionSettingsWeeklyView => '每周视图';

  @override
  String get nutritionShowcase11Dishes4Sections => '11 道菜 · 4 个板块';

  @override
  String get nutritionShowcaseAnalyze => '分析';

  @override
  String get nutritionShowcaseCacioEPepe => '意式奶酪胡椒面';

  @override
  String get nutritionShowcaseDesserts => '甜点';

  @override
  String get nutritionShowcaseDinner => '晚餐';

  @override
  String get nutritionShowcaseFilter => '筛选';

  @override
  String get nutritionShowcaseFoodDb => '食物数据库';

  @override
  String get nutritionShowcaseGrilledSalmonBowl => '香煎三文鱼碗';

  @override
  String get nutritionShowcaseLunchDinner => '— 午餐与晚餐 —';

  @override
  String get nutritionShowcaseMenuAnalyzed => '菜单已分析';

  @override
  String get nutritionShowcaseMultiplePagesSnapThem => '有多页？全部拍下来。';

  @override
  String get nutritionShowcaseNoDishesSelectedGo => '未选择菜品 — 请返回并挑选几道。';

  @override
  String get nutritionShowcaseRecent => '最近';

  @override
  String get nutritionShowcaseSaved => '已保存';

  @override
  String get nutritionShowcaseScanningMenu => '正在扫描菜单…';

  @override
  String nutritionShowcaseScreenCalJustNow(Object cal) {
    return '$cal 卡路里 · 刚刚';
  }

  @override
  String nutritionShowcaseScreenG(Object price, Object weightG) {
    return '$weightG g · $price';
  }

  @override
  String nutritionShowcaseScreenOfCal(Object _calorieGoal) {
    return '目标 $_calorieGoal 卡路里';
  }

  @override
  String nutritionShowcaseScreenSelected(Object length) {
    return '已选 $length 项';
  }

  @override
  String nutritionShowcaseScreenValue(Object count) {
    return '· $count';
  }

  @override
  String get nutritionShowcaseSort => '排序：';

  @override
  String get nutritionShowcaseStarters => '前菜';

  @override
  String get nutritionShowcaseTapADishTo => '点击菜品进行选择';

  @override
  String get nutritionShowcaseTapBelowToScan => '点击下方扫描菜单';

  @override
  String get nutritionShowcaseTheBistro => '小酒馆';

  @override
  String get nutritionShowcaseTiramisu => '提拉米苏';

  @override
  String get nutritionShowcaseToday => '今天';

  @override
  String get nutritionShowcaseWhatDidYouEat => '你吃了什么？';

  @override
  String get nutritionSignInToView => '登录以查看营养统计数据';

  @override
  String get nutritionStreakCardBestEver => '历史最高';

  @override
  String nutritionStreakCardBestTotalDays(Object best, Object total) {
    return '最佳 $best · 总计 $total 天';
  }

  @override
  String nutritionStreakCardCouldNotUseFreeze(Object e) {
    return '无法使用补签卡：$e';
  }

  @override
  String get nutritionStreakCardCurrent => '当前';

  @override
  String nutritionStreakCardDayStreak(Object streakDays) {
    return '连续 $streakDays 天';
  }

  @override
  String nutritionStreakCardDays(Object logged, Object target) {
    return '$logged / $target 天';
  }

  @override
  String get nutritionStreakCardFreezesAvailable => '可用冻结次数';

  @override
  String get nutritionStreakCardLogAMealTo => '记录一餐以开启你的连续打卡';

  @override
  String get nutritionStreakCardStreakFreezeUsedYour =>
      '已使用连续打卡冻结 — 你的连续记录很安全。';

  @override
  String get nutritionStreakCardThisWeek => '本周';

  @override
  String get nutritionStreakCardTotalDaysLogged => '总记录天数';

  @override
  String get nutritionStreakCardUseAFreeze => '使用冻结';

  @override
  String get nutritionStreakCardUseFreeze => '使用冻结';

  @override
  String get nutritionStreakCardUsing => '正在使用…';

  @override
  String get nutritionStreakCardYourStreak => '你的连续打卡';

  @override
  String nutritionTabPartAdherenceCardLastWeeks(Object length) {
    return '过去 $length 周';
  }

  @override
  String nutritionTabPartAdherenceCardValue(Object averageAdherence) {
    return '$averageAdherence%';
  }

  @override
  String nutritionTabPartAdherenceCardValue2(Object consistencyScore) {
    return '$consistencyScore%';
  }

  @override
  String nutritionTabPartAdherenceCardValue3(Object loggingScore) {
    return '$loggingScore%';
  }

  @override
  String get nutritionTabPartAdherenceConsistency => '依从性与一致性';

  @override
  String get nutritionTabPartAvgCalories => '平均热量';

  @override
  String get nutritionTabPartAvgProtein => '平均蛋白质';

  @override
  String get nutritionTabPartCalorieTrend => '热量趋势';

  @override
  String get nutritionTabPartCarbs => '碳水化合物';

  @override
  String get nutritionTabPartConsistency => '一致性';

  @override
  String get nutritionTabPartCouldNotLoadAdherence => '无法加载依从性数据';

  @override
  String get nutritionTabPartCouldNotLoadCalorie => '无法加载热量数据';

  @override
  String get nutritionTabPartCouldNotLoadMacros => '无法加载宏量营养素';

  @override
  String get nutritionTabPartCouldNotLoadTdee => '无法加载TDEE数据';

  @override
  String get nutritionTabPartDaysLogged => '记录天数';

  @override
  String get nutritionTabPartFat => '脂肪';

  @override
  String get nutritionTabPartLogging => '记录中';

  @override
  String get nutritionTabPartMacroBreakdown => '宏量营养素分析';

  @override
  String get nutritionTabPartNoMacroDataThis => '本周无宏量营养素数据';

  @override
  String get nutritionTabPartNoNutritionDataThis => '本周无营养数据';

  @override
  String get nutritionTabPartNotEnoughDataFor => 'TDEE估算数据不足';

  @override
  String get nutritionTabPartProtein => '蛋白质';

  @override
  String get nutritionTabPartTdeeEnergyBalance => 'TDEE与能量平衡';

  @override
  String get nutritionTabPartWeeklyAverageDistribution => '每周平均分布';

  @override
  String get nutritionTabPartWeeklyOverview => '每周概览';

  @override
  String nutritionTabPartWeeklyOverviewCardAvgCal(Object averageDailyCalories) {
    return '平均 $averageDailyCalories 大卡';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardAvgIntakeCal(Object avgIntake) {
    return '平均摄入：$avgIntake 大卡';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardCal(Object tdee) {
    return ')(tdee) 大卡';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardCalDay(Object uncertaintyDisplay) {
    return '大卡/天 $uncertaintyDisplay';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardG(Object avgProtein) {
    return '$avgProtein 克';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardG2(Object grams) {
    return '$grams 克';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardKg(Object data) {
    return ')(data) 公斤';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardValue(Object daysLogged) {
    return '$daysLogged/7';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardValue2(Object pct) {
    return '$pct%';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardWeight(Object formattedWeeklyRate) {
    return '体重：$formattedWeeklyRate';
  }

  @override
  String get nutritionTabPartWeeksAnalyzed => '已分析周数';

  @override
  String get nutritionTabPartWeight => '体重';

  @override
  String get nutritionTourIntermittentFasting => '间歇性禁食';

  @override
  String get nutritionTourSaved => '已保存';

  @override
  String get nutritionTourStartAndTrackA => '在此开始并追踪禁食——你的实时禁食窗口会显示在此卡片上。';

  @override
  String get nutritionTourSwipeThroughDates => '滑动切换日期';

  @override
  String get nutritionTourTapTheCameraBarcode =>
      '点击相机、条形码或+按钮——视觉OCR会自动填充卡路里和宏量营养素。';

  @override
  String get nutritionTourUseTheDateArrows => '使用日期箭头或点击“历史记录”查看过去的日子。';

  @override
  String get nutritionTourYourSavedRecipesFoods =>
      '你保存的食谱、食物和扫描过的菜单都在这里——一键即可再次记录。';

  @override
  String get nutritionUndo => '撤销';

  @override
  String get offlineBannerDismissSyncFailureBanner => '关闭同步失败横幅';

  @override
  String get offlineModeOfflineMode => '离线模式';

  @override
  String get offlineModeWorkOutWithoutInternet =>
      '无需网络即可锻炼。支持设备端AI、预缓存锻炼、锻炼视频下载及后台同步。';

  @override
  String get onboardingAlreadyHaveAccount => '我已有账号';

  @override
  String get onboardingBlockerLetSDoIt => '开始吧';

  @override
  String get onboardingBlockerNoJudgmentKnowingThe =>
      '无需评判。了解障碍所在，我们才能制定绕过它的计划。';

  @override
  String get onboardingBlockerThatMakesSense => '有道理。';

  @override
  String get onboardingBlockerWhatSHeldYou => '之前是什么阻碍了你？';

  @override
  String get onboardingConfidenceARealisticPlaceTo => '一个现实的起点。';

  @override
  String get onboardingConfidenceBeHonestThereIs => '诚实一点。这里没有错误答案。';

  @override
  String get onboardingConfidenceFullyIn => '全力以赴';

  @override
  String get onboardingConfidenceHowConfidentAreYou => '你有多大信心能达成目标？';

  @override
  String get onboardingConfidenceNotSureYet => '还不确定';

  @override
  String onboardingConfidenceScreenHowConfidentAreYou(Object name) {
    return '$name，您有多大信心能达成目标？';
  }

  @override
  String onboardingConfidenceScreenOutOf(Object value) {
    return '$value / 10';
  }

  @override
  String get onboardingConfidenceStartingUnsureIsHonest => '开始时感到不确定是很诚实的表现。';

  @override
  String get onboardingConfidenceThatBeliefWillCarry => '这份信念将支撑你走下去。';

  @override
  String get onboardingContinueButton => '继续';

  @override
  String get onboardingGetStarted => '开始';

  @override
  String get onboardingReflectHereSWhatWe => '这是我们听到的反馈。';

  @override
  String get onboardingSkip => '跳过';

  @override
  String get onboardingValueHereSWhatThat => '以下是单独订阅这些服务的费用。';

  @override
  String onboardingValueScreenMo(Object priceLabel) {
    return '$priceLabel/月';
  }

  @override
  String get onboardingValueSeeMyPlan => '查看我的计划';

  @override
  String get onboardingValueSeeMyPlanAnd => '查看我的计划与价格';

  @override
  String get onboardingValueSeparateApps => '独立应用';

  @override
  String get onboardingValueThreeToolsOneApp => '三个工具，一个App。';

  @override
  String get onboardingValueZealovaAllOfIt => 'Zealova，全部包含';

  @override
  String get onboardingWhyFirstTheWhy => '首先，为什么';

  @override
  String get onboardingWhyWhatSDrivingThis => '是什么驱动了这一切？';

  @override
  String get openAllCrates24HoursOf2xXp => '24 小时双倍 XP';

  @override
  String get openAllCratesActivityCrate => '活动宝箱';

  @override
  String get openAllCratesBonusCrateToOpen => '待开启奖励宝箱';

  @override
  String openAllCratesCollect(Object arg0, Object arg1) {
    return '领取 $arg0 $arg1';
  }

  @override
  String openAllCratesCratesOpened(Object arg0) {
    return '已开启宝箱 $arg0';
  }

  @override
  String get openAllCratesDailyCrate => '每日宝箱';

  @override
  String get openAllCratesDone => '完成';

  @override
  String get openAllCratesDoubleXpToken => '双倍 XP 卡';

  @override
  String get openAllCratesFailedToOpenCrates => '开启宝箱失败。请重试。';

  @override
  String get openAllCratesFitnessCrate => '健身宝箱';

  @override
  String openAllCratesGainedXp(Object arg0) {
    return '获得 XP $arg0';
  }

  @override
  String get openAllCratesMaxLevel => '最高等级';

  @override
  String get openAllCratesOpenYourCrates => '开启你的宝箱';

  @override
  String get openAllCratesOpened => ') 已开启！';

  @override
  String get openAllCratesOpeningYourCrates => '正在开启你的宝箱';

  @override
  String openAllCratesPickRewardPerDay(Object arg0, Object arg1) {
    return '每日选择奖励 $arg0 $arg1';
  }

  @override
  String openAllCratesPickYourReward(Object arg0, Object arg1) {
    return '选择你的奖励 $arg0 $arg1';
  }

  @override
  String get openAllCratesProtectYourStreak => '保护你的连胜';

  @override
  String get openAllCratesSelectAll => '全选';

  @override
  String get openAllCratesStreakCrate => '连胜宝箱';

  @override
  String get openAllCratesStreakShield => '连胜护盾';

  @override
  String get openAllCratesToday => '今天';

  @override
  String openAllCratesTotalXpFormatted(Object arg0) {
    return '总XP $arg0';
  }

  @override
  String openAllCratesTotalXpLevel(Object arg0, Object arg1) {
    return '总XP等级 $arg0 $arg1';
  }

  @override
  String get openAllCratesUd83cUdf89Rewards => '🎉 奖励！';

  @override
  String openAllCratesXpInLevel(Object arg0, Object arg1) {
    return '当前等级XP $arg0 $arg1';
  }

  @override
  String openAllCratesXpToNextLevel(Object arg0, Object arg1) {
    return '距离下一级XP $arg0 $arg1';
  }

  @override
  String get openAllCratesYesterday => '昨天';

  @override
  String get overallScoreHeroOverall => '总分';

  @override
  String get overviewActiveSkill => '活跃技能';

  @override
  String get overviewActiveStreaks => '活跃连胜';

  @override
  String get overviewBodyMeasurements => '身体测量数据';

  @override
  String get overviewCouldnTRefreshShowing => '无法刷新。正在显示缓存数据。';

  @override
  String get overviewCycle => '周期';

  @override
  String get overviewExerciseHistory => '锻炼历史';

  @override
  String get overviewLastWeek => '上周';

  @override
  String get overviewMuscleAnalytics => '肌肉分析';

  @override
  String get overviewMy1rms => '我的1RM';

  @override
  String get overviewNoAchievementsYet => '暂无成就';

  @override
  String get overviewNoPersonalRecordsYet => '暂无个人纪录';

  @override
  String get overviewPersonalRecords => '个人纪录';

  @override
  String get overviewPersonalRecordsAreTracked =>
      '当你完成锻炼时，个人纪录会被自动追踪。开始训练以在此查看你的进步！';

  @override
  String get overviewQuickAccess => '快速访问';

  @override
  String get overviewRecentAchievements => '近期成就';

  @override
  String get overviewRecentTrophy => '近期奖杯';

  @override
  String get overviewReportsInsights => '报告与洞察';

  @override
  String get overviewRewards => '奖励';

  @override
  String get overviewSocial => '社交';

  @override
  String get overviewStatsRewardsTabHas => '“统计与奖励”标签页包含所有额外内容。';

  @override
  String get overviewStreak => '连胜';

  @override
  String overviewTabReady(Object ready) {
    return '$ready 就绪';
  }

  @override
  String overviewTabValue(Object dateStr, Object liftDescription) {
    return '$liftDescription  •  $dateStr';
  }

  @override
  String overviewTabValue2(Object pr) {
    return '+$pr%';
  }

  @override
  String overviewTabWorkoutsPrs(Object prs, Object workouts) {
    return '$workouts 次训练 • $prs 项 PR';
  }

  @override
  String get overviewTime => '时间';

  @override
  String get overviewTotal => '总计';

  @override
  String get overviewViewAll => '查看全部';

  @override
  String get overviewViewPerks => '查看福利';

  @override
  String get overviewWeek => '周';

  @override
  String get paceChartExpand => '展开';

  @override
  String get paceChartPace => '配速';

  @override
  String parsedExercisesPreviewSheetEdit(Object name) {
    return '编辑 $name';
  }

  @override
  String parsedExercisesPreviewSheetParsedExercises(Object length) {
    return '已解析 $length 个动作';
  }

  @override
  String parsedExercisesPreviewSheetValue(
    Object exercise,
    Object formattedSetsReps,
  ) {
    return '$formattedSetsReps @ $exercise';
  }

  @override
  String get pauseInterceptGoingOnVacationLife => '要去度假？生活太忙？';

  @override
  String get pauseInterceptLongerBreakIllnessTransi => '更长的休息——生病、过渡期、生活变动';

  @override
  String get pauseInterceptNoThanksContinueWith => '不用了，继续取消';

  @override
  String get pauseInterceptPauseFor14Days => '暂停 14 天';

  @override
  String get pauseInterceptPauseFor30Days => '暂停 30 天';

  @override
  String get pauseInterceptPauseYourPlanInstead => '改为暂停你的计划——随时从中断处继续。';

  @override
  String get pauseInterceptQuickBreakShortTrip => '短暂休息——短途旅行、忙碌的一周';

  @override
  String pauseInterceptSheetCouldnTPause(Object e) {
    return '无法暂停：$e';
  }

  @override
  String get pauseSubscription1Month => '1 个月';

  @override
  String get pauseSubscription1Week => '1 周';

  @override
  String get pauseSubscription2Months => '2 个月';

  @override
  String get pauseSubscription2Weeks => '2 周';

  @override
  String get pauseSubscription3Months => '3 个月';

  @override
  String get pauseSubscriptionAutoResumeDate => '自动恢复日期';

  @override
  String get pauseSubscriptionBillingIsPaused => '已暂停计费';

  @override
  String get pauseSubscriptionDataIsPreserved => '数据已保留';

  @override
  String get pauseSubscriptionExtendedBreak => '延长休息';

  @override
  String get pauseSubscriptionHowLongDoYou => '你需要休息多久？';

  @override
  String get pauseSubscriptionLimitedAccess => '受限访问';

  @override
  String get pauseSubscriptionLongPause => '长期暂停';

  @override
  String get pauseSubscriptionMaximumPause => '最长暂停时间';

  @override
  String pauseSubscriptionPauseForDuration(Object duration) {
    return '暂停 $duration';
  }

  @override
  String pauseSubscriptionPausePlan(Object planName) {
    return '暂停 $planName';
  }

  @override
  String get pauseSubscriptionPremiumFeaturesAre => '高级功能暂时不可用';

  @override
  String get pauseSubscriptionSelectADuration => '选择时长';

  @override
  String get pauseSubscriptionShortBreak => '短暂休息';

  @override
  String get pauseSubscriptionTakeABreakWithout => '休息的同时保留你的数据';

  @override
  String get pauseSubscriptionVacationMode => '度假模式';

  @override
  String get pauseSubscriptionWhatHappensWhenYou => '暂停期间会发生什么';

  @override
  String get pauseSubscriptionYouWontBeCharged => '暂停期间不会扣费';

  @override
  String get pauseSubscriptionYourWorkoutHistory => '你的训练历史和进度保持安全';

  @override
  String get paywallFeatures14Features => '14+ 项功能';

  @override
  String get paywallFeatures3Tools => '3 款工具';

  @override
  String get paywallFeatures52Skills => '52 项技能';

  @override
  String get paywallFeatures7DayFreeTrial => '7 天免费试用\n随时取消，无需理由';

  @override
  String get paywallFeaturesAiCoachChat => 'AI 教练聊天';

  @override
  String get paywallFeaturesAiCoachExperience => 'AI 教练体验';

  @override
  String get paywallFeaturesAiWorkouts => 'AI 训练计划';

  @override
  String get paywallFeaturesAutoAdaptWorkoutsAround => '根据你的伤病自动调整训练';

  @override
  String get paywallFeaturesChartsHeatmapsAndDetailed => '图表、热力图及详细趋势分析';

  @override
  String get paywallFeaturesFoodPhotoScanning => '食物照片扫描';

  @override
  String get paywallFeaturesInjuryAware => '伤病感知';

  @override
  String get paywallFeaturesInjuryAwareTraining => '伤病感知训练';

  @override
  String get paywallFeaturesLearnMore => '了解更多';

  @override
  String get paywallFeaturesNutritionFormRecoveryAs => '营养、动作、恢复——随时提问';

  @override
  String get paywallFeaturesPersonalizedPlansForAny => '针对任何设备和目标的个性化计划';

  @override
  String get paywallFeaturesProgressTrackingAnalytics => '进度追踪与分析';

  @override
  String get paywallFeaturesSafety => '安全';

  @override
  String get paywallFeaturesSnapAPhotoGet => '拍张照片，即刻获取卡路里和宏量营养素';

  @override
  String get paywallFeaturesUnlimitedAiWorkouts => '无限次 AI 训练';

  @override
  String get paywallFeaturesUnlockTheFull => '解锁完整';

  @override
  String get paywallPricing => ' • ';

  @override
  String get paywallPricing45Min => '45 分钟';

  @override
  String get paywallPricing7DayFreeTrial => '7 天免费试用';

  @override
  String get paywallPricing7DayFreeTrial2 => '7 天免费试用\n随时取消，无需理由';

  @override
  String get paywallPricingAi6Exercises => 'AI · 6 个动作';

  @override
  String get paywallPricingBestValue => '超值推荐';

  @override
  String get paywallPricingBilledSecurelyThroughThe => '通过 App Store 安全扣款';

  @override
  String get paywallPricingCancelAnytime => '随时取消';

  @override
  String get paywallPricingChangePlan => '更改计划';

  @override
  String get paywallPricingChestShouldersTriceps => '· 胸部 · 肩部 · 三头肌';

  @override
  String get paywallPricingFreeFor7Days => '免费试用 7 天。随时取消。';

  @override
  String get paywallPricingIn5DaysReminder => '5 天后 · 提醒';

  @override
  String get paywallPricingIn7DaysBilling => '7 天后 · 开始计费';

  @override
  String get paywallPricingIsReady => '已准备就绪';

  @override
  String get paywallPricingLessThanThePrice => '每周不到一杯咖啡的价格';

  @override
  String get paywallPricingMonthly => '按月订阅';

  @override
  String get paywallPricingNoPaymentDueNow => '现在无需付款';

  @override
  String get paywallPricingNoPaymentDueNow2 => '现在无需付款';

  @override
  String get paywallPricingNoPurchasesFound => '未找到购买记录';

  @override
  String get paywallPricingNoSurprisesCancelAnytime => '无隐形消费。在第 7 天前随时在设置中取消。';

  @override
  String get paywallPricingPlanUpdatedSuccessfully => '计划更新成功！';

  @override
  String get paywallPricingPurchasesRestored => '购买记录已恢复！';

  @override
  String get paywallPricingPushDay => '推日';

  @override
  String get paywallPricingRestore => '恢复购买';

  @override
  String get paywallPricingScreen5999Year => '\$59.99/年';

  @override
  String get paywallPricingScreenBackToPlans => '返回计划列表';

  @override
  String get paywallPricingScreenConfirmChange => '确认更改';

  @override
  String get paywallPricingScreenConfirmPlanChange => '确认更改计划';

  @override
  String get paywallPricingScreenConfirmUpgrade => '确认升级';

  @override
  String get paywallPricingScreenCurrentPlan => '当前计划';

  @override
  String get paywallPricingScreenExclusiveYearlyDiscountJust => '专属于你的年度折扣！';

  @override
  String get paywallPricingScreenGetYearlyFor37 => '获取年度计划仅需 \$37.49';

  @override
  String get paywallPricingScreenJust312Month => '每月仅需 \$3.12';

  @override
  String get paywallPricingScreenNewPlan => '新计划';

  @override
  String get paywallPricingScreenNoThanksILl => '不用了，谢谢';

  @override
  String get paywallPricingScreenOfferExpired => '优惠已过期';

  @override
  String get paywallPricingScreenOfferExpiresIn => '优惠倒计时：';

  @override
  String get paywallPricingScreenPremiumYearly => '年度高级会员';

  @override
  String get paywallPricingScreenPriceDifference => ' 价格差额';

  @override
  String get paywallPricingScreenSave125025 => '节省 \$12.50 (25% 折扣)';

  @override
  String get paywallPricingScreenThatSJust0 => '每天仅需 \$0.10，比一杯咖啡还便宜';

  @override
  String get paywallPricingScreenThisSpecialDiscountIs => '此特别折扣已失效。';

  @override
  String get paywallPricingScreenWaitSpecialOffer => '等等！特别优惠';

  @override
  String paywallPricingScreenYear(Object yearlyTotal) {
    return '$yearlyTotal/年';
  }

  @override
  String get paywallPricingScreenYouCanStillGet => '您仍可以获得年度高级会员，价格为';

  @override
  String get paywallPricingScreenYouWillBeUpgraded => '您将立即升级';

  @override
  String get paywallPricingStartWithA7 => '开启 7 天免费试用。随时取消，试用期结束前不会扣费。';

  @override
  String get paywallPricingStartYour7Day => '开启 7 天免费试用以继续';

  @override
  String get paywallPricingTerms => '条款';

  @override
  String get paywallPricingToday => '今天';

  @override
  String get paywallPricingUnlockUnlimitedAiWorkouts =>
      '解锁无限 AI 训练、食物扫描与宏量营养素分析、动作分析及全面的进度追踪。';

  @override
  String get paywallPricingWeLlSendYou => '我们会在试用期结束前提醒您';

  @override
  String get paywallPricingWhatYouGet => '您将获得';

  @override
  String get paywallPricingYearly => '年度';

  @override
  String get paywallPricingYouAreAlreadyOn => '您已订阅此方案';

  @override
  String get paywallPricingYouReAllSet => '设置完成。您的试用现已激活。';

  @override
  String get paywallPricingYourAiCoach => '您的 AI 教练';

  @override
  String get paywallTimelineCancelAnytimeDuringOr =>
      '在试用期间或之后随时取消。试用期结束前不会扣费，您可以通过 Google Play 管理订阅。';

  @override
  String get paywallTimelineHowYourFree => '免费试用';

  @override
  String get paywallTimelineHowYourFreeTrial => '免费试用如何运作';

  @override
  String get paywallTimelineIn5Days => '5 天后';

  @override
  String get paywallTimelineIn7Days => '7 天后';

  @override
  String paywallTimelineScreenFirstCharge(Object dateFormat) {
    return '首次扣款：$dateFormat';
  }

  @override
  String paywallTimelineScreenYouLlBeCharged(Object dateFormat) {
    return '您将在 $dateFormat 被扣款。可随时取消，无需任何理由。';
  }

  @override
  String get paywallTimelineToday => '今天';

  @override
  String get paywallTimelineTrialWorks => '运作方式';

  @override
  String get paywallTimelineUnlimitedWorkoutsFoodScann =>
      '无限训练、食物扫描、伤病追踪、技能进阶等';

  @override
  String get paywallTimelineWeLlRemindYou => '我们会在试用结束前提醒您，绝无意外扣费';

  @override
  String pendingRequestCardValue(Object message) {
    return '\"$message\"';
  }

  @override
  String get pendingRequestCardViewProfile => '查看个人资料';

  @override
  String get permissionsPrimerAFewQuickPermissions => '几项快速权限设置';

  @override
  String get permissionsPrimerCamera => '相机';

  @override
  String get permissionsPrimerEachAppFeatureWill => '每项应用功能在请求权限前都会进行说明。';

  @override
  String get permissionsPrimerGrantPermissions => '授予权限';

  @override
  String get permissionsPrimerGrantingTheseNowMeans =>
      '现在授予权限意味着功能可以直接使用，不会在训练中途弹出提示。';

  @override
  String get permissionsPrimerMicrophone => '麦克风';

  @override
  String get permissionsPrimerNotNow => '暂不';

  @override
  String get permissionsPrimerNotifications => '通知';

  @override
  String get permissionsPrimerPhotos => '照片';

  @override
  String get personalBestsGrid => '⏱️';

  @override
  String get personalBestsGridHeaviestLift => '最大重量';

  @override
  String personalBestsGridLb(Object weightLb) {
    return '$weightLb lb';
  }

  @override
  String get personalBestsGridLongestSession => '最长训练时长';

  @override
  String get personalBestsGridMostVolume => '最大训练容量';

  @override
  String get personalGoalsActiveGoals => '当前目标';

  @override
  String get personalGoalsDeleteGoal => '删除目标？';

  @override
  String get personalGoalsFullRecordsViewComing => '完整记录视图将在未来版本中推出';

  @override
  String get personalGoalsMaxReps => '最大次数';

  @override
  String get personalGoalsNewGoal => '新目标';

  @override
  String get personalGoalsNewPrs => '新 PR';

  @override
  String get personalGoalsNoGoalsThisWeek => '本周暂无目标';

  @override
  String get personalGoalsPersonalRecords => '个人纪录';

  @override
  String get personalGoalsReps => ' 次';

  @override
  String personalGoalsScreenDeleted(Object exerciseName) {
    return '已删除“$exerciseName”';
  }

  @override
  String personalGoalsScreenPermanentlyDeleteThisCannot(Object exerciseName) {
    return '永久删除“$exerciseName”？此操作无法撤销。';
  }

  @override
  String personalGoalsScreenViewAllRecords(Object length) {
    return '查看全部 $length 条记录';
  }

  @override
  String get personalGoalsSetAWeeklyChallenge => '设定每周挑战以突破极限！';

  @override
  String get personalGoalsSetYourFirstGoal => '设定您的第一个目标';

  @override
  String get personalGoalsSomethingWentWrong => '出错了';

  @override
  String get personalGoalsThisWeek => '本周';

  @override
  String get personalGoalsTryAgain => '重试';

  @override
  String get personalGoalsUnknownError => '未知错误';

  @override
  String get personalGoalsWeeklyGoals => '每周目标';

  @override
  String get personalGoalsWeeklyVolume => '每周训练容量';

  @override
  String get personalInfoACoupleFinalDetails => '最后几个细节';

  @override
  String get personalInfoDateOfBirth => '出生日期';

  @override
  String get personalInfoDoYouTrackA => '您是否追踪月经周期？';

  @override
  String get personalInfoFirstName => '名字';

  @override
  String get personalInfoNoThanks => '不用了，谢谢';

  @override
  String get personalInfoPleaseCompleteTheBody => '请先完成身体指标步骤。';

  @override
  String personalInfoScreenFailedToSave(Object e) {
    return '保存失败：$e';
  }

  @override
  String get personalInfoWeUseTheseTo => '我们使用这些信息来个性化您的教练服务并保障您的账户安全。';

  @override
  String get personalInfoYesSetItUp => '是的，进行设置';

  @override
  String get personalInfoYouMustBeAt => '您必须年满 16 岁才能使用 Zealova。';

  @override
  String get personalInfoYourName => '您的姓名';

  @override
  String get personalRecordsAllTime => '历史纪录';

  @override
  String get personalRecordsCard1MonthAgo => '1 个月前';

  @override
  String get personalRecordsCard1WeekAgo => '1 周前';

  @override
  String get personalRecordsCardAfternoonTip => '保持水分充足！运动前至少喝500毫升水。';

  @override
  String get personalRecordsCardAskCoachForMore => '向教练咨询更多建议';

  @override
  String get personalRecordsCardCoachTip => '教练建议';

  @override
  String get personalRecordsCardCompleteWorkoutsToPR => '完成训练以刷新个人纪录';

  @override
  String get personalRecordsCardConnectHealthToTrack => '连接健康应用以进行追踪';

  @override
  String personalRecordsCardDaysAgo(Object days) {
    return '$days 天前';
  }

  @override
  String get personalRecordsCardEveningTip => '晚间运动有助于改善心情。如果想今晚睡个好觉，请保持中等强度。';

  @override
  String get personalRecordsCardGettingPersonalizedTip => '正在获取个性化建议…';

  @override
  String personalRecordsCardGlasses(Object current, Object goal) {
    return '$current/$goal 杯';
  }

  @override
  String personalRecordsCardMonthsAgo(Object months) {
    return '$months个月前';
  }

  @override
  String get personalRecordsCardMorningTip => '运动前进行5分钟动态热身，以提升表现并降低受伤风险。';

  @override
  String personalRecordsCardOfUsers(Object count) {
    return '$count位用户中的';
  }

  @override
  String get personalRecordsCardPersonalRecords => '个人纪录';

  @override
  String personalRecordsCardQualitySleep(Object duration) {
    return '$duration 高质量睡眠';
  }

  @override
  String get personalRecordsCardRank => '排名';

  @override
  String get personalRecordsCardSleep => '睡眠';

  @override
  String get personalRecordsCardToday => '今天';

  @override
  String personalRecordsCardTopPercentile(Object percentile) {
    return '前 $percentile%';
  }

  @override
  String get personalRecordsCardViewAll => '查看全部';

  @override
  String get personalRecordsCardWater => '饮水';

  @override
  String personalRecordsCardWeeksAgo(Object weeks) {
    return '$weeks 周前';
  }

  @override
  String get personalRecordsCardWeight => '重量';

  @override
  String get personalRecordsCardYesterday => '昨天';

  @override
  String get personalRecordsCompleteWorkoutsToStart => '完成训练以开始追踪您的各项练习 PR。';

  @override
  String get personalRecordsNoPersonalRecordsYet => '暂无个人纪录';

  @override
  String get personalRecordsNoPrsYetLog => '暂无 PR — 记录一次训练来设定您的第一个纪录！';

  @override
  String get personalRecordsPersonalRecords => '个人纪录';

  @override
  String personalRecordsScreenValue(Object pr) {
    return '+$pr%';
  }

  @override
  String get personalRecordsSearchExercises => '搜索练习...';

  @override
  String get personalRecordsSortBy => '排序方式：';

  @override
  String get personalityCardFunFact => '趣味事实';

  @override
  String personalityCardValue(Object motivationQuote) {
    return '\"$motivationQuote\"';
  }

  @override
  String get personalityCardYourGymPersonalityIs => '您的健身人格是...';

  @override
  String phaseRecommendationBannerBasedOn(Object evidenceCitation) {
    return '基于：$evidenceCitation';
  }

  @override
  String phaseRecommendationBannerConfidenceEstimate(Object confidence) {
    return '(置信度)-置信度估计\" : \"\")';
  }

  @override
  String phaseRecommendationBannerCycleDay(Object cycleDay) {
    return '周期第 $cycleDay 天';
  }

  @override
  String phaseRecommendationBannerEvidence(Object evidenceCitation) {
    return '依据：$evidenceCitation';
  }

  @override
  String get phaseRecommendationBannerGotIt => '知道了';

  @override
  String get photoEditorAddSticker => '添加贴纸';

  @override
  String get photoEditorCrop => '裁剪';

  @override
  String get photoEditorCropPhoto => '裁剪照片';

  @override
  String get photoEditorFailedToCropImage => '裁剪图片失败。请重试。';

  @override
  String get photoEditorFlip => '翻转';

  @override
  String get photoEditorHideLogo => '隐藏Logo';

  @override
  String get photoEditorNoStickersUsedYet => '暂无使用的贴纸';

  @override
  String get photoEditorProcessing => '处理中…';

  @override
  String get photoEditorResetLogo => '重置Logo';

  @override
  String get photoEditorRotate => '旋转';

  @override
  String photoEditorScreenEditPhoto(Object viewTypeName) {
    return '编辑 $viewTypeName 照片';
  }

  @override
  String photoEditorScreenFailedToSave(Object e) {
    return '保存失败：$e';
  }

  @override
  String photoEditorScreenPose(Object viewTypeName) {
    return '$viewTypeName 姿势';
  }

  @override
  String get photoEditorShowLogo => '显示Logo';

  @override
  String get photoEditorSize => '大小';

  @override
  String get photoEditorYourRecentlyUsedStickers => '您最近使用的贴纸将显示在此处';

  @override
  String get photoOverlayTemplateAddYourPhoto => '添加照片';

  @override
  String get photoOverlayTemplateTime => '时间';

  @override
  String get photoOverlayTemplateVolume => '容量';

  @override
  String get photoOverlayTemplateWorkoutComplete => '训练完成';

  @override
  String get photosAll => '全部';

  @override
  String get photosChooseFromGallery => '从相册选择';

  @override
  String get photosCompare => '对比';

  @override
  String get photosDeletePhoto => '删除照片？';

  @override
  String get photosLatestByView => '按视图查看最新';

  @override
  String get photosSelectExistingPhoto => '选择现有照片';

  @override
  String get photosSelectViewType => '选择视图类型';

  @override
  String photosTabFailedToOpenEditor(Object e) {
    return '无法打开编辑器: $e';
  }

  @override
  String photosTabFailedToUploadPhoto(Object e) {
    return '照片上传失败: $e';
  }

  @override
  String photosTabPhotoSaved(Object displayName) {
    return '$displayName 照片已保存！';
  }

  @override
  String photosTabSavedComparisons(Object length) {
    return '已保存的对比 ($length)';
  }

  @override
  String photosTabSelected(Object length) {
    return '已选 $length 个';
  }

  @override
  String get photosTabUiNoProgressPhotosYet => '暂无进度照片';

  @override
  String get photosTabUiTakeFirstPhoto => '拍摄第一张照片';

  @override
  String get photosTabUiTakePhotosFromDifferent => '从不同角度拍摄照片，以追踪您的视觉进度。';

  @override
  String get photosTakePhoto => '拍摄照片';

  @override
  String get photosThisActionCannotBe => '此操作无法撤销。';

  @override
  String get photosUploadingPhoto => '正在上传照片...';

  @override
  String get photosUseCamera => '使用相机';

  @override
  String get photosViewAll => '查看全部';

  @override
  String get pillarDetail7DayCompletion => '7天完成度';

  @override
  String get pillarDetailActiveMin => '活动分钟数';

  @override
  String get pillarDetailBandShowsThe10th => '色带显示您过去30天的第10至第90百分位区间。';

  @override
  String get pillarDetailCalorieHit => '热量目标达成';

  @override
  String get pillarDetailCaloriesBurned => '消耗热量';

  @override
  String get pillarDetailCompletion => '完成度';

  @override
  String get pillarDetailComponents => '组成部分';

  @override
  String get pillarDetailCouldNotLoad => '无法加载';

  @override
  String get pillarDetailCustomTrends => '自定义趋势';

  @override
  String get pillarDetailDarkerCloserToGoal => '颜色越深越接近目标。带边框的单元格表示已达成目标。';

  @override
  String get pillarDetailDuration => '时长';

  @override
  String get pillarDetailFiveOrMoreLoggedDays => '已记录五天或以上';

  @override
  String get pillarDetailHeatmap30d => '30天热力图';

  @override
  String get pillarDetailHourlyActivityRibbon => '每小时活动勋章';

  @override
  String get pillarDetailHourlyActivityRibbonBody => '每小时活动勋章详情';

  @override
  String get pillarDetailIntensity => '强度';

  @override
  String get pillarDetailLast30Days => '过去30天';

  @override
  String get pillarDetailLogged => '已记录';

  @override
  String get pillarDetailMacroStream => '宏观数据流';

  @override
  String get pillarDetailMacroStreamBody => '宏观数据流详情';

  @override
  String get pillarDetailNoHistoryYet => '暂无历史记录';

  @override
  String get pillarDetailOpenActivity => '活动';

  @override
  String get pillarDetailOpenFullScreen => '全屏打开';

  @override
  String get pillarDetailOpenNutrition => '营养';

  @override
  String get pillarDetailOpenSleep => '打开睡眠 →';

  @override
  String get pillarDetailOpenWorkouts => '训练';

  @override
  String get pillarDetailPending => '待处理';

  @override
  String get pillarDetailProteinHit => '蛋白质目标达成';

  @override
  String pillarDetailScreenEx(Object exerciseCount) {
    return '$exerciseCount 项练习';
  }

  @override
  String pillarDetailScreenKcal(Object cal) {
    return '$cal kcal';
  }

  @override
  String pillarDetailScreenMin(Object activeMin) {
    return '$activeMin 分钟';
  }

  @override
  String pillarDetailScreenNotActiveToday(Object label) {
    return '$label · 今日未激活';
  }

  @override
  String pillarDetailScreenStatsTab(Object statsTab) {
    return '/stats?tab=$statsTab';
  }

  @override
  String pillarDetailScreenTodayS(Object label) {
    return '今日 $label';
  }

  @override
  String get pillarDetailSetAGoal => '设定目标';

  @override
  String get pillarDetailSleepStages => '睡眠阶段';

  @override
  String get pillarDetailSleepStagesBody => '睡眠阶段详情';

  @override
  String get pillarDetailSparkline7d => '7天走势图';

  @override
  String get pillarDetailSteps => '步数';

  @override
  String get pillarDetailTodayVsYour30 => '今日与30天范围对比';

  @override
  String get pillarDetailTracking => '追踪';

  @override
  String get pillarDetailTwoOrMoreLoggedDays => '已记录两天或以上';

  @override
  String get pillarDetailVariety => '多样性';

  @override
  String get pillarDetailViewFullStats => '查看完整统计';

  @override
  String get pillarDetailVolume => '容量';

  @override
  String get pillarDetailWhenYouTrain => '训练时段';

  @override
  String get pillarDetailWhenYouTrainBody => '训练时段详情';

  @override
  String get pinnedMessageBarN => '\n';

  @override
  String get pinnedMessageBarUnpin => '取消置顶';

  @override
  String get pinnedNutrientsCardFocusThisPhase => '本阶段重点：';

  @override
  String get pinnedNutrientsCardPinnedNutrients => '已置顶营养素';

  @override
  String get planAnalyzingBuildingYourPlan => '正在构建您的计划';

  @override
  String get planAnalyzingCalculatingYourGoalDate => '正在计算您的目标日期';

  @override
  String get planAnalyzingCalibratingYourSchedule => '正在校准您的日程';

  @override
  String get planAnalyzingMatchingYourBodyType => '正在匹配您的体型';

  @override
  String get planAnalyzingPullingFrom1700 => '正在从1700+个动作中筛选';

  @override
  String get planAnalyzingReviewingYourGoals => '正在审核您的目标';

  @override
  String get planAnalyzingThisWillTakeA => '这需要几秒钟时间…';

  @override
  String get planHeaderAvgCalories => '平均热量';

  @override
  String planHeaderDays(Object trainingDayCount) {
    return '$trainingDayCount 天';
  }

  @override
  String planHeaderDays2(Object restDayCount) {
    return '$restDayCount 天';
  }

  @override
  String get planHeaderRest => '休息';

  @override
  String get planHeaderThisWeek => '本周';

  @override
  String get planPreviewFreePreview => '免费预览';

  @override
  String get planPreviewRestRecovery => '休息与恢复';

  @override
  String get planPreviewScreenAnalyzingYourGoalsFitness =>
      '正在分析您的目标、健身水平和设备，以打造完美的计划';

  @override
  String get planPreviewScreenBuildStrengthFoundation => '建立力量基础';

  @override
  String get planPreviewScreenBuildingYour4Week => '正在构建您的4周计划...';

  @override
  String get planPreviewScreenContinueFree => '继续免费使用';

  @override
  String planPreviewScreenDaysPerWeek(Object arg0) {
    return '每周 $arg0 天';
  }

  @override
  String get planPreviewScreenDesignedBasedOnYour => '根据您的问卷回答设计';

  @override
  String planPreviewScreenEquipmentCount(Object arg0) {
    return '器械数量 $arg0';
  }

  @override
  String planPreviewScreenExercisesMin(Object arg0, Object arg1) {
    return '训练动作最少 $arg0 $arg1';
  }

  @override
  String get planPreviewScreenIncreaseIntensityVolume => '增加强度与容量';

  @override
  String get planPreviewScreenMasterTheMovement => '掌握动作技巧';

  @override
  String get planPreviewScreenPeakPerformanceWeek => '巅峰表现周';

  @override
  String get planPreviewScreenSetsreps => '组数/次数';

  @override
  String get planPreviewScreenSubscribeForFullAccess => '订阅以获取完整访问权限';

  @override
  String get planPreviewScreenThisIsYourPersonalized => '这是为您量身定制的计划';

  @override
  String get planPreviewScreenTryOneWorkoutFree => '免费试用一次训练';

  @override
  String get planPreviewScreenViewing => '正在查看';

  @override
  String planPreviewScreenWeekNumber(Object arg0) {
    return '第 $arg0 周';
  }

  @override
  String get planPreviewScreenWhatYouLlAchieve => '您将实现的目标';

  @override
  String get planPreviewYour4WeekPlan => '您的4周计划';

  @override
  String get planTodaySPlan => '今日计划';

  @override
  String get plateauDashboardCompleteMoreWorkoutsAnd =>
      '完成更多训练并记录体重，以查看平台期检测分析。';

  @override
  String get plateauDashboardCurrentWeight => '当前体重';

  @override
  String get plateauDashboardFailedToLoadData => '数据加载失败';

  @override
  String get plateauDashboardGetAiCoachAdvice => '获取 AI 教练建议';

  @override
  String get plateauDashboardNoPlateauDataYet => '暂无平台期数据';

  @override
  String get plateauDashboardOverallStatus => '总体状态';

  @override
  String get plateauDashboardPlateauDetection => '平台期检测';

  @override
  String plateauDashboardScreenKg(Object currentWeight) {
    return '$currentWeight kg';
  }

  @override
  String plateauDashboardScreenWeeksStalled(Object weeksStalled) {
    return '停滞 $weeksStalled 周';
  }

  @override
  String get plateauDashboardSuggestedAction => '建议操作';

  @override
  String get plateauDashboardWeightProgress => '体重进度';

  @override
  String get portionAmountInput1x => '1x';

  @override
  String get portionAmountInputAdjustPortion => '调整份量';

  @override
  String get portionAmountInputCal => '卡路里';

  @override
  String get portionAmountInputCustomAmount => '自定义份量';

  @override
  String get portionAmountInputDouble => '双倍';

  @override
  String get portionAmountInputHalf => '半份';

  @override
  String get portionAmountInputOneAndAHalf => '1.5 份';

  @override
  String get portionAmountInputOneAndAQuarter => '1.25 份';

  @override
  String get portionAmountInputStandard => '标准';

  @override
  String get portionAmountInputThreeQuarters => '0.75 份';

  @override
  String get postMealReviewCheckInDisabledRe => '打卡已禁用。请在“营养”→“模式”中重新启用。';

  @override
  String get postMealReviewCheckInSaved => '打卡已保存！';

  @override
  String get postMealReviewDonTShowAgain => '不再显示';

  @override
  String get postMealReviewEnergyLevel => '能量水平';

  @override
  String get postMealReviewHide => '隐藏';

  @override
  String get postMealReviewHowDidYouFeel => '进食前感觉如何？';

  @override
  String get postMealReviewHowDoYouFeel => '进食后感觉如何？';

  @override
  String get postMealReviewMealLogged => '餐食已记录！';

  @override
  String get postMealReviewQuickCheckInOptional => '快速打卡（可选）';

  @override
  String get postMealReviewSaveCheckIn => '保存打卡';

  @override
  String postMealReviewSheetKcal(
    Object extraCount,
    Object foodSummary,
    Object totalCalories,
  ) {
    return '$foodSummary$extraCount · $totalCalories kcal';
  }

  @override
  String get postMealReviewWhyTrackThis => '为什么要记录这个？';

  @override
  String get postWorkoutHr60sRec => '60秒恢复';

  @override
  String get postWorkoutHrAvg => '平均值';

  @override
  String postWorkoutHrGraphAvg(Object avg) {
    return '平均 $avg';
  }

  @override
  String postWorkoutHrGraphValue(Object recovery) {
    return '−$recovery';
  }

  @override
  String get postWorkoutHrHeartRate => '心率';

  @override
  String get postWorkoutHrMin => '最小值';

  @override
  String get postWorkoutHrNoHeartRateData =>
      '未捕获心率数据。请佩戴心率带（如 Amazfit Helios）并授予健康权限，以查看实时心率和训练后图表。';

  @override
  String get postWorkoutHrPeak => '峰值';

  @override
  String get postWorkoutNutritionCarbs => '碳水化合物';

  @override
  String get postWorkoutNutritionFasted => '空腹';

  @override
  String get postWorkoutNutritionFat => '脂肪';

  @override
  String get postWorkoutNutritionLog => '记录';

  @override
  String get postWorkoutNutritionLogPostWorkoutMeal => '记录训练后餐食';

  @override
  String get postWorkoutNutritionProtein => '蛋白质';

  @override
  String get postWorkoutNutritionQuickOptions => '快捷选项：';

  @override
  String postWorkoutNutritionReminderG(Object proteinTarget) {
    return '${proteinTarget}g';
  }

  @override
  String postWorkoutNutritionReminderG2(Object carbsTarget) {
    return '${carbsTarget}g';
  }

  @override
  String postWorkoutNutritionReminderG3(Object fatTarget) {
    return '${fatTarget}g';
  }

  @override
  String get postureFindingsCardAddCorrectiveExercises => '添加矫正练习';

  @override
  String get postureFindingsCardPostureFindings => '体态评估结果';

  @override
  String get postureFindingsCardQueuing => '排队中…';

  @override
  String get prCardShareE1rm => '📈 e1RM · ';

  @override
  String get prCardShareNewPr => '新 PR';

  @override
  String get prCardShareNewPr2 => '🏆 新 PR · ';

  @override
  String get prCardSharePreparing => '准备中…';

  @override
  String get prCardShareSharePr => '分享 PR';

  @override
  String get prCardShareZealovaAiFitnessCoach => 'Zealova · AI 健身教练';

  @override
  String get prCardShareZealovaCom => 'zealova.com';

  @override
  String get prDetailsFirstRecord => '首次记录';

  @override
  String get prDetailsNewRecord => '新纪录';

  @override
  String get prDetailsPrevious => '上一次';

  @override
  String prDetailsSheetKgXReps(Object reps, Object weight) {
    return '${weight}kg x $reps 次';
  }

  @override
  String prDetailsSheetOnFirePrs(Object length) {
    return '状态火热！$length 项 PR！';
  }

  @override
  String prDetailsSheetValue(Object improvementPercent) {
    return '+$improvementPercent%';
  }

  @override
  String get prDetailsViewAllAchievements => '查看所有成就';

  @override
  String get prFullCelebration6MonthBest1rm => '6个月内最佳 1RM';

  @override
  String get prFullCelebrationContinueWorkout => '继续训练';

  @override
  String get prFullCelebrationNewPersonalRecord => '新个人纪录！';

  @override
  String prFullCelebrationPersonalRecords(Object length) {
    return '$length 项个人纪录！';
  }

  @override
  String prFullCelebrationReps(Object reps) {
    return '$reps 次';
  }

  @override
  String get prFullCelebrationShareYourAchievement => '分享你的成就';

  @override
  String prFullCelebrationValue(Object improvementPercent) {
    return '(+$improvementPercent%)';
  }

  @override
  String get prFullCelebrationYouReOnFire => '状态火热！';

  @override
  String get prInlineCelebrationOnFire => '状态火热！🔥';

  @override
  String prInlineCelebrationPersonalRecords(Object length) {
    return '$length 项个人纪录！';
  }

  @override
  String prInlineCelebrationValue(Object improvementPercent) {
    return '+$improvementPercent%';
  }

  @override
  String prInlineCelebrationValue2(Object exerciseName, Object formattedValue) {
    return '$exerciseName • $formattedValue';
  }

  @override
  String get prPosterTemplateFromLast => ') 较上次';

  @override
  String get prShareCardCopiedToClipboard => '已复制到剪贴板！';

  @override
  String get prShareCardCopyText => '复制文本';

  @override
  String get prShareCardFailedToCaptureImage => '截图失败';

  @override
  String get prShareCardFailedToShare => '分享失败';

  @override
  String get prShareCardNewPersonalRecord => '新个人纪录！';

  @override
  String prShareCardReps(Object reps) {
    return '$reps 次';
  }

  @override
  String get prShareCardShareImage => '分享图片';

  @override
  String get prShareCardShareYourPr => '分享你的 PR';

  @override
  String prShareCardWorkout(Object workoutName) {
    return '训练：$workoutName';
  }

  @override
  String get prSummaryCardLogYourWorkoutsAnd => '记录你的训练，我们将自动追踪\n你的最佳成绩！';

  @override
  String get prSummaryCardNoPersonalRecordsYet => '暂无个人纪录';

  @override
  String get prSummaryCardPersonalRecords => '个人纪录';

  @override
  String get prSummaryCardRecentPrs => '近期 PR';

  @override
  String prSummaryCardValue(Object pr) {
    return '+$pr%';
  }

  @override
  String get practiceAttemptHoldTimeSeconds => '保持时间（秒）';

  @override
  String get practiceAttemptHowDidItFeel => '感觉如何？有什么观察吗？';

  @override
  String get practiceAttemptLogAttempt => '记录尝试';

  @override
  String get practiceAttemptLogPractice => '记录练习';

  @override
  String get practiceAttemptNotesOptional => '备注（可选）';

  @override
  String get practiceAttemptPleaseEnterRepsOr => '请输入次数或保持时间';

  @override
  String get practiceAttemptQuickSelectReps => '快速选择次数';

  @override
  String get practiceAttemptReps => '次数';

  @override
  String get practiceAttemptSets => '组数';

  @override
  String practiceAttemptSheetGoal(Object unlockCriteriaText) {
    return '目标: $unlockCriteriaText';
  }

  @override
  String get preAuthQuizConsistencyBeatsIntensity => '持之以恒胜过高强度';

  @override
  String get preAuthQuizControlsHowQuicklyWeights => '控制每周增加重量、次数和难度的速度。';

  @override
  String get preAuthQuizEveryExerciseWillBe => '每个动作都将根据您实际拥有的器械进行选择。无需替换。';

  @override
  String get preAuthQuizFailedToSaveOnboarding => '保存引导数据失败。请重试。';

  @override
  String get preAuthQuizFineTuningYourPlan => '正在微调您的计划';

  @override
  String get preAuthQuizFitnessLevelHelpsSet =>
      '健身水平有助于设定合适的起点——包括合适的重量、次数范围和动作复杂度。';

  @override
  String get preAuthQuizFuelYourTraining => '为您的训练补充能量';

  @override
  String get preAuthQuizGenerateMyFirstWorkout => '生成我的第一次训练';

  @override
  String get preAuthQuizGotIt => '知道了';

  @override
  String get preAuthQuizMatchedToYourSetup => '匹配您的器械配置';

  @override
  String get preAuthQuizNutritionTrackingIsOptional =>
      '营养追踪是可选的，但功能强大。AI 会根据您的目标和活动水平计算宏量营养素。';

  @override
  String get preAuthQuizSafetyFirst => '安全第一';

  @override
  String get preAuthQuizSkipAndFinish => '跳过并完成';

  @override
  String get preAuthQuizSkipLetAiDecide => '跳过，让 AI 决定';

  @override
  String get preAuthQuizSomethingWentWrongPlease => '出错了。请重试。';

  @override
  String get preAuthQuizTellingUsAboutInjuries =>
      '告知我们伤病情况，确保我们避开可能导致疼痛或阻碍训练的动作。';

  @override
  String get preAuthQuizTheseOptionalDetailsMake =>
      '这些可选细节能让您的训练更加个性化。如果您偏好 AI 默认设置，可以跳过。';

  @override
  String get preAuthQuizWeLlBuildThe =>
      '我们将根据您的日程安排构建最佳训练计划。天数多并不总是更好——恢复同样重要。';

  @override
  String get preAuthQuizWeUseYourGoals => '我们使用您的目标来确定训练计划、动作选择以及您的进步速度。';

  @override
  String get preAuthQuizWhichDaysWorkBest => '哪几天最方便？';

  @override
  String get preAuthQuizYourGoalsShapeEverything => '您的目标决定一切';

  @override
  String get preAuthQuizYourProgressionSpeed => '您的进步速度';

  @override
  String get preAuthReferralAbc123 => 'ABC123';

  @override
  String preAuthReferralChipCodeWillApplyAfter(Object _pendingCode) {
    return '代码$_pendingCode将在注册后生效';
  }

  @override
  String get preAuthReferralEnterReferralCode => '输入推荐码';

  @override
  String get preAuthReferralRemove => '移除';

  @override
  String get preAuthReferralSaveCode => '保存代码';

  @override
  String get preAuthReferralThatCodeDoesnT => '该代码似乎不正确，请重试。';

  @override
  String preSetCoachingBannerCoachingInsight(Object message) {
    return '教练洞察。$message。';
  }

  @override
  String get preSetCoachingDismiss => '忽略';

  @override
  String get preSetCoachingDismissCoachingInsight => '忽略教练建议';

  @override
  String preSetInsightBannerValue(Object label) {
    return '$label · ';
  }

  @override
  String get preSetInsightDismissInsight => '忽略洞察';

  @override
  String get preWorkoutCheckinAddMoreDetails => '添加更多详情';

  @override
  String get preWorkoutCheckinEnergyLevel => '能量水平';

  @override
  String get preWorkoutCheckinHowAreYouFeeling => '您感觉如何？';

  @override
  String get preWorkoutCheckinHowWasYourSleep => '您昨晚睡得怎么样？';

  @override
  String get preWorkoutCheckinQuickCheckBeforeYour => '训练前快速检查';

  @override
  String get preWorkoutCheckinSkipCheckIn => '跳过签到';

  @override
  String get preWorkoutCheckinStartWorkout => '开始训练';

  @override
  String get preferencesAccentColor => '强调色';

  @override
  String get preferencesAutoDetectedOverrideIf => '自动检测，如在旅行中可覆盖';

  @override
  String get preferencesChooseYourAppAccent => '选择您的应用强调色';

  @override
  String get preferencesGymProfiles => '健身房配置';

  @override
  String get preferencesKilogramsOrPounds => '公斤或磅';

  @override
  String get preferencesManageGymsEquipmentAnd => '管理健身房、器械和地点';

  @override
  String get preferencesPreferences => '偏好设置';

  @override
  String get preferencesShowDailyGoals => '显示每日目标';

  @override
  String get preferencesSystemLightOrDark => '系统、浅色或深色';

  @override
  String get preferencesTimezone => '时区';

  @override
  String get preferencesTrainingFocus => '训练重点';

  @override
  String get preferencesWeightUnit => '重量单位';

  @override
  String get preferencesXpProgressStripOn => '主屏幕上的 XP 进度条';

  @override
  String get premiumGatePremiumFeature => '高级功能';

  @override
  String get premiumGateUnlock => '解锁';

  @override
  String get pressAndHoldPressAndHoldTo => '按住以确认';

  @override
  String get previewTileMock45Min6Exercises => '45 分钟 - 6 个动作';

  @override
  String get previewTileMock8234Steps => '8,234 步';

  @override
  String get previewTileMockFitnessScore => '健身评分';

  @override
  String get previewTileMockGoodProgressKeepIt => '进步不错，继续保持！';

  @override
  String get previousWorkoutsCompleteYourFirstWorkout => '完成您的第一次训练以在此查看';

  @override
  String get previousWorkoutsNoCompletedWorkoutsYet => '暂无已完成的训练';

  @override
  String get previousWorkoutsPreviousWorkouts => '往期训练';

  @override
  String get privacyDataPrivacyData => '隐私与数据';

  @override
  String get profileAddEquipmentThatWill => '添加生成训练时将使用的器械。';

  @override
  String get profileAiPrivacy => 'AI 隐私';

  @override
  String get profileCustomTrends => '自定义趋势';

  @override
  String get profileDeleteAccount => '删除账户';

  @override
  String get profileFitness => '健身';

  @override
  String get profileFromAppleHealth => '来自 Apple Health';

  @override
  String get profileFromHealthConnect => '来自 Health Connect';

  @override
  String get profileGlossary => '术语表';

  @override
  String profileHeaderValue(Object username) {
    return '@$username';
  }

  @override
  String get profileManageMembership => '管理会员';

  @override
  String get profileMyCustomEquipment => '我的自定义器械';

  @override
  String get profilePrivacyData => '隐私与数据';

  @override
  String get profileScreenPartAdd => '添加';

  @override
  String get profileScreenPartAddEquipmentAboveTo => '添加上方器械以开始';

  @override
  String get profileScreenPartEnterEquipmentName => '输入器械名称...';

  @override
  String get profileScreenPartNoCustomEquipmentYet => '暂无自定义器械';

  @override
  String get profileScreenPartNoSyncedWorkoutsYet => '暂无同步的训练';

  @override
  String get profileScreenPartPrimaryGoalMusclePrioriti => '主要目标与肌肉优先级';

  @override
  String get profileScreenPartSeeAll => '查看全部';

  @override
  String get profileScreenPartTrainingFocus => '训练重点';

  @override
  String get profileSessionDetails => '会话详情';

  @override
  String get profileWorkoutHistoryImport => '训练历史导入';

  @override
  String get programBuilderPartAddYourWarmUp => '在每次训练中添加热身和拉伸动作。';

  @override
  String get programBuilderPartApplyMyStapleExercises => '应用我的常用练习';

  @override
  String programBuilderPartExercisePickerAddTo(Object dayName) {
    return '添加到$dayName';
  }

  @override
  String get programBuilderPartNoScheduledDeload => '无计划减载';

  @override
  String get programBuilderPartOff => '休息';

  @override
  String get programBuilderPartProgramSettings => '计划设置';

  @override
  String get programBuilderPartSearchExercises => '搜索练习...';

  @override
  String programBuilderPartTemplateMetaEveryWeeks(Object current) {
    return '每 $current 周';
  }

  @override
  String get programCarouselSeeAll => '查看全部';

  @override
  String get programDetailCategory => '类别';

  @override
  String get programDetailDescription => '描述';

  @override
  String get programDetailDuration => '时长';

  @override
  String get programDetailLevel => '等级';

  @override
  String get programDetailProgram => '计划';

  @override
  String get programDetailSessions => '训练次数';

  @override
  String programDetailSheetInspiredBy(Object celebrityName) {
    return '灵感来自 $celebrityName';
  }

  @override
  String programDetailSheetStartWeekProgram(Object _selectedWeeks) {
    return '开始 $_selectedWeeks 周计划';
  }

  @override
  String programDetailSheetValue(Object tag) {
    return '#$tag';
  }

  @override
  String programDetailSheetWeek(Object _selectedSessionsPerWeek) {
    return '$_selectedSessionsPerWeek/周';
  }

  @override
  String programDetailSheetWeeks(Object _selectedWeeks) {
    return '$_selectedWeeks 周';
  }

  @override
  String get programDurationSelectorHowFarAheadTo => '计划排期时长';

  @override
  String get programDurationSelectorProgramDuration => '计划时长';

  @override
  String get programHistoryCurrent => '当前';

  @override
  String get programHistoryFailedToLoadProgram => '无法加载计划历史';

  @override
  String get programHistoryNoProgramHistoryYet => '暂无计划历史';

  @override
  String get programHistoryProgramHistory => '计划历史';

  @override
  String get programHistoryProgramRestoredSuccessfully => '计划恢复成功！';

  @override
  String get programHistoryRestoreProgram => '恢复计划？';

  @override
  String get programHistoryRestoreProgram2 => '恢复计划';

  @override
  String programHistoryScreenDaysWeek(Object length) {
    return '$length 天/周';
  }

  @override
  String programHistoryScreenFailedToRestoreProgram(Object e) {
    return '恢复计划失败: $e';
  }

  @override
  String programHistoryScreenMin(Object durationMinutes) {
    return '$durationMinutes 分钟';
  }

  @override
  String programHistoryScreenThisWillRestoreAs(Object displayName) {
    return '这将把“$displayName”恢复为您的当前计划。';
  }

  @override
  String programHistoryScreenWorkoutsCompleted(Object totalWorkoutsCompleted) {
    return '已完成 $totalWorkoutsCompleted 次训练';
  }

  @override
  String get programHistoryUnknownError => '未知错误';

  @override
  String get programHistoryWhenYouCustomizeYour => '当你自定义计划时，快照将保存在这里。';

  @override
  String get programLibrary => '•  ';

  @override
  String get programLibraryAll => '全部';

  @override
  String get programLibraryAny => '任意';

  @override
  String programLibraryCardWk(Object durationWeeks) {
    return '$durationWeeks 周';
  }

  @override
  String programLibraryCardWk2(Object sessionsPerWeek) {
    return '每周 $sessionsPerWeek 次';
  }

  @override
  String get programLibraryClearFilters => '清除筛选';

  @override
  String get programLibraryCouldNotImportThis => '无法导入此计划。请重试。';

  @override
  String get programLibraryImportCustomize => '导入并自定义';

  @override
  String get programLibraryImporting => '正在导入...';

  @override
  String get programLibraryLevel => '等级';

  @override
  String get programLibraryNoProgramsMatchThese => '没有符合筛选条件的计划。';

  @override
  String get programLibraryProgramLibrary => '计划库';

  @override
  String programLibraryScreenRest(Object dayName) {
    return '$dayName · 休息';
  }

  @override
  String programLibraryScreenValue(Object ex, Object sets) {
    return '$sets × $ex';
  }

  @override
  String programLibraryScreenWith(Object card) {
    return '包含 $card';
  }

  @override
  String get programLibrarySearchPrograms => '搜索计划';

  @override
  String get programMenuButtonBrowsePrograms => '浏览计划';

  @override
  String get programMenuButtonChangeDaysEquipmentDiffic => '更改训练日、器械、难度等';

  @override
  String get programMenuButtonCustomizeProgram => '自定义计划';

  @override
  String get programMenuButtonCustomizeYourWorkoutProgram =>
      '自定义你的健身计划或使用当前设置重新生成。';

  @override
  String get programMenuButtonFailedToClearWorkouts => '无法清除训练';

  @override
  String programMenuButtonGeneratedFreshWorkouts(Object generatedCount) {
    return '已生成$generatedCount个新训练！';
  }

  @override
  String get programMenuButtonGetFreshWorkoutsWith => '使用当前设置获取新的训练计划';

  @override
  String get programMenuButtonMySpace => '我的空间';

  @override
  String get programMenuButtonPleaseLogInTo => '请登录以重新生成训练';

  @override
  String get programMenuButtonProgramOptions => '计划选项';

  @override
  String get programMenuButtonProgramUpdatedYourNew => '计划已更新！你的新训练已准备就绪。';

  @override
  String get programMenuButtonRegenerateThisWeek => '重新生成本周训练';

  @override
  String get programMenuButtonRegenerateWorkouts => '重新生成训练？';

  @override
  String get programMenuButtonSeeYourWorkoutDays => '查看你的训练日、经验等级和目标';

  @override
  String get programMenuButtonThisWillDeleteYour =>
      '这将删除你即将进行的未完成训练，并使用当前的计划设置生成新的训练。\n\n已完成的训练将不受影响。';

  @override
  String get programMenuButtonTryCelebrityWorkoutsSport => '尝试明星健身、运动训练等';

  @override
  String get programMenuButtonViewMyPreferences => '查看我的偏好';

  @override
  String get programMetaApplyStaples => '应用基础动作';

  @override
  String get programMetaApplyStaplesSubtitle => '应用基础动作副标题';

  @override
  String get programMetaDeloadEvery => '减载周期';

  @override
  String get programMetaFixedLoadsNote => '固定负荷说明';

  @override
  String get programMetaProgramSettings => '计划设置';

  @override
  String get programMetaProgression => '进阶方式';

  @override
  String get programSummaryAdaptsWorkoutsBasedOn => '根据你的进度调整训练';

  @override
  String get programSummaryAdvancedLabel => '进阶';

  @override
  String get programSummaryAutomaticallyIncreasesChalle => '随时间自动增加挑战难度';

  @override
  String get programSummaryAvoidsExercisesThatStress => '避免对你的受限部位造成压力的练习';

  @override
  String get programSummaryBeginnerLabel => '初学者';

  @override
  String get programSummaryBodyweight => '自重训练';

  @override
  String get programSummaryBuildMuscle => '增肌';

  @override
  String get programSummaryEndurance => '耐力';

  @override
  String get programSummaryEquipment => '器械';

  @override
  String get programSummaryFullGym => '完整健身房';

  @override
  String get programSummaryGeneralFitness => '综合体能';

  @override
  String get programSummaryGenerateNewProgram => '生成新计划';

  @override
  String get programSummaryGetStronger => '增强力量';

  @override
  String get programSummaryInjuryAwareness => '伤病意识';

  @override
  String get programSummaryIntermediateLabel => '中级';

  @override
  String get programSummaryLevel => '等级';

  @override
  String get programSummaryLoseWeight => '减脂';

  @override
  String get programSummaryMacrosAndMealsAligned => '宏量营养素和饮食与你的训练保持一致';

  @override
  String programSummaryNItems(Object arg0) {
    return '$arg0 个项目';
  }

  @override
  String get programSummaryNutritionIntegration => '营养整合';

  @override
  String get programSummaryPersonalizedForYourGoals => '根据你的目标和器械进行个性化定制';

  @override
  String get programSummaryProgressiveOverload => '渐进式超负荷';

  @override
  String get programSummaryStartTraining => '开始训练';

  @override
  String get programSummaryStayFit => '保持健康';

  @override
  String get programSummaryStrengthSize => '力量与体型';

  @override
  String get programSummaryWhatSIncluded => '包含内容';

  @override
  String get programSummaryYourProgramIsReady => '你的计划已准备就绪';

  @override
  String get programTemplateBuilderAProgramNeedsAt => '一个计划至少需要一个训练日。';

  @override
  String get programTemplateBuilderAddExercise => '添加练习';

  @override
  String get programTemplateBuilderBuildFromScratch => '从零开始构建';

  @override
  String get programTemplateBuilderCopyDayToAnother => '将某天复制到另一天';

  @override
  String get programTemplateBuilderCouldNotSaveThe => '无法保存模板。请重试。';

  @override
  String get programTemplateBuilderDropInASplit => '输入你已写好的分化计划，我们将为你解析。';

  @override
  String get programTemplateBuilderEditProgram => '编辑计划';

  @override
  String get programTemplateBuilderEmpty => '空';

  @override
  String get programTemplateBuilderGiveYourProgramA => '为你的计划命名。';

  @override
  String get programTemplateBuilderImportFromLibrary => '从库中导入';

  @override
  String get programTemplateBuilderLayOutEachTraining => '逐个练习地规划每个训练日。';

  @override
  String get programTemplateBuilderMakeRestDay => '设为休息日';

  @override
  String get programTemplateBuilderMakeTrainingDay => '设为训练日';

  @override
  String get programTemplateBuilderMyTemplates => '我的模板';

  @override
  String get programTemplateBuilderNewProgram => '新计划';

  @override
  String get programTemplateBuilderParseProgram => '解析计划';

  @override
  String get programTemplateBuilderParsing => '解析中...';

  @override
  String get programTemplateBuilderPasteMyProgram => '粘贴我的计划';

  @override
  String get programTemplateBuilderSaveTemplate => '保存模板';

  @override
  String get programTemplateBuilderSaving => '保存中...';

  @override
  String programTemplateBuilderScreenCopyInto(Object sourceName) {
    return '复制 \"$sourceName\" 到…';
  }

  @override
  String programTemplateBuilderScreenDay(Object d, Object label) {
    return '第 $d 天 · $label';
  }

  @override
  String programTemplateBuilderScreenSaved(Object name) {
    return '已保存 \"$name\"';
  }

  @override
  String programTemplateBuilderScreenTo(Object destLabel) {
    return '至 $destLabel';
  }

  @override
  String programTemplateBuilderScreenValue(Object exercise, Object sets) {
    return '$sets × $exercise';
  }

  @override
  String programTemplateBuilderScreenWeeksWhenScheduled(
    Object repeatWeeksHint,
  ) {
    return '计划周期为 $repeatWeeksHint 周。';
  }

  @override
  String get programTemplateBuilderStartFromAStructured =>
      '从结构化计划开始，并打造属于你自己的计划。';

  @override
  String get programsAll => '全部';

  @override
  String get programsClearFilters => '清除筛选';

  @override
  String get programsIntro185Programs => '185+ 个计划';

  @override
  String get programsIntro37WorkoutDays => '每周 3-7 个训练日';

  @override
  String get programsIntroAllLevels => '所有级别';

  @override
  String get programsIntroBeginnerToAdvanced => '从初学者到进阶者';

  @override
  String get programsIntroBrowsePrograms => '浏览计划';

  @override
  String get programsIntroCategories => '分类';

  @override
  String get programsIntroCustomFrequency => '自定义频率';

  @override
  String get programsIntroFlexibleDuration => '灵活时长';

  @override
  String get programsIntroProfessionalExerciseTutorial => '专业动作教程';

  @override
  String get programsIntroProgramsFrom1To => '1 到 16 周的训练计划';

  @override
  String get programsIntroStrengthCardioMobilityM => '力量、有氧、灵活性训练等';

  @override
  String get programsIntroVideoDemos => '视频演示';

  @override
  String get programsIntroWhatYouCanExpect => '你可以期待什么';

  @override
  String get programsIntroWorkoutPrograms => '训练计划';

  @override
  String get programsNoProgramsFound => '未找到相关计划';

  @override
  String get programsSearch => '搜索';

  @override
  String get programsSearchPrograms => '搜索计划...';

  @override
  String get programsTapAnyProgramTo => '点击任意计划以了解详情';

  @override
  String get programsTryAgain => '重试';

  @override
  String get progressAll => '全部';

  @override
  String get progressChartsCompleteSomeWorkoutsTo => '完成一些训练以查看你的训练量进度。';

  @override
  String get progressChartsCompleteWeightedExercisesTo => '完成负重训练以查看你的力量进度。';

  @override
  String get progressChartsFailedToLoadData => '数据加载失败';

  @override
  String get progressChartsMuscleGroupBreakdown => '肌群分析';

  @override
  String get progressChartsNoStrengthDataYet => '暂无力量数据';

  @override
  String get progressChartsNoVolumeDataYet => '暂无训练量数据';

  @override
  String get progressChartsPeriodSummary => '周期总结';

  @override
  String progressChartsScreenKg(Object value) {
    return '$value kg';
  }

  @override
  String get progressChartsStrengthSummary => '力量总结';

  @override
  String get progressChartsStrengthTrends => '力量趋势';

  @override
  String get progressChartsTopMuscle => '主要肌群：';

  @override
  String get progressChartsTrends => '趋势';

  @override
  String get progressChartsVolumeTrend => '训练量趋势';

  @override
  String get progressChartsVolumeTrends => '训练量趋势';

  @override
  String get progressChooseFromGallery => '从相册选择';

  @override
  String get progressDeletePhoto => '删除照片？';

  @override
  String get progressFailedToProcessPhoto => '照片处理失败。请重试。';

  @override
  String get progressFitness => '健身';

  @override
  String get progressGreat => '太棒了！';

  @override
  String get progressMeasurements => '身体测量';

  @override
  String get progressOk => 'OK';

  @override
  String get progressPhotoSaved => '照片已保存！';

  @override
  String get progressPhotoTileProgressPhotos => '进度照片';

  @override
  String get progressPhotoTileTakeYourFirstPhoto => '拍摄你的第一张照片';

  @override
  String get progressPhotos => '照片';

  @override
  String get progressProgressTracking => '进度追踪';

  @override
  String get progressPrs30d => 'PR (30天)';

  @override
  String get progressScores => '评分';

  @override
  String get progressScreenExtCompleteWorkoutsTargetingTh =>
      '完成针对该肌群的训练\n以查看你的力量进度。';

  @override
  String get progressScreenExtDetails => '详情';

  @override
  String get progressScreenExtNoDataForThis => '该肌群暂无数据';

  @override
  String get progressScreenExtProgressToNextLevel => '进阶至下一阶段';

  @override
  String progressScreenExtSetsWk(Object weeklySets) {
    return '$weeklySets 组/周';
  }

  @override
  String get progressScreenPartView => '查看';

  @override
  String get progressScreenUiAddPhoto => '添加照片';

  @override
  String get progressScreenUiAi100RatingBody => 'AI /100 评分、体脂环及体态反馈';

  @override
  String get progressScreenUiBodyAnalyzer => '身体分析器';

  @override
  String get progressScreenUiBodyMeasurements => '身体测量';

  @override
  String get progressScreenUiDetailedAnalytics => '详细分析';

  @override
  String get progressScreenUiExerciseHistory => '训练历史';

  @override
  String get progressScreenUiExerciseProgressions => '动作进阶';

  @override
  String get progressScreenUiFailedToLoadMeasurements => '测量数据加载失败';

  @override
  String get progressScreenUiLatestByView => '按视图查看最新';

  @override
  String get progressScreenUiLogMeasurement => '记录测量数据';

  @override
  String get progressScreenUiLogMeasurements => '记录测量数据';

  @override
  String get progressScreenUiMasterEasierVariantsThen => '掌握简单变式，然后进阶到更难的动作';

  @override
  String get progressScreenUiMuscleAnalytics => '肌群分析';

  @override
  String get progressScreenUiNoProgressPhotosYet => '暂无进度照片';

  @override
  String get progressScreenUiPerExerciseProgressPrs => '单项动作进度与 PR';

  @override
  String get progressScreenUiPhotoProgress => '照片进度';

  @override
  String get progressScreenUiPleaseTryAgain => '请重试。';

  @override
  String get progressScreenUiTakeFirstPhoto => '拍摄第一张照片';

  @override
  String get progressScreenUiTakePhotosFromDifferent => '从不同角度拍摄照片，以追踪你的视觉进度。';

  @override
  String get progressScreenUiTrackYourBodyMeasurements =>
      '追踪你的身体测量数据，查看体重秤之外的详细进度。';

  @override
  String get progressScreenUiTrainingVolumeBalance => '训练量与平衡';

  @override
  String progressScreenWeight(Object formattedWeight) {
    return '体重: $formattedWeight';
  }

  @override
  String progressScreenYourProgressPhotoHas(Object displayName) {
    return '您的 $displayName 进度照片已成功保存。';
  }

  @override
  String get progressSelectExistingPhoto => '选择现有照片';

  @override
  String get progressSelectViewType => '选择视图类型';

  @override
  String progressShareGalleryScreenViralFormats(Object length) {
    return '$length 种热门格式';
  }

  @override
  String get progressShareGalleryShareYourTransformation => '分享你的蜕变';

  @override
  String get progressShareGalleryTapToOpen => '点击打开';

  @override
  String get progressShareTemplatesANtransformationNstudy => '一项\n蜕变\n研究';

  @override
  String get progressShareTemplatesBreaking => '突发';

  @override
  String get progressShareTemplatesConsistency => '坚持';

  @override
  String progressShareTemplatesFromAgo(Object durationText) {
    return '$durationText 前';
  }

  @override
  String get progressShareTemplatesFromILlStart => '从“我周一就开始”';

  @override
  String progressShareTemplatesHowSheLost(Object weightLostText) {
    return '她是如何减掉 $weightLostText 的';
  }

  @override
  String get progressShareTemplatesInGreenBoxes => '在绿色方框中';

  @override
  String get progressShareTemplatesInTheBooks => '已记录在案';

  @override
  String progressShareTemplatesLocalLegendShedsIn(
    Object durationText,
    Object weightLostText,
  ) {
    return '本地传奇在 $durationText 内减重 $weightLostText';
  }

  @override
  String progressShareTemplatesLocalLegendTransformsIn(Object durationText) {
    return '本地传奇在 $durationText 内完成蜕变';
  }

  @override
  String get progressShareTemplatesMyTransformation => '我的蜕变';

  @override
  String progressShareTemplatesNworkouts(Object totalWorkouts) {
    return '+$totalWorkouts\n次锻炼';
  }

  @override
  String get progressShareTemplatesOfConsistency => '的坚持';

  @override
  String get progressShareTemplatesOfDiscipline => '的自律。';

  @override
  String get progressShareTemplatesOfPureWork => '纯粹的努力';

  @override
  String progressShareTemplatesOfWork(Object durationText) {
    return '$durationText 的训练';
  }

  @override
  String get progressShareTemplatesProgress => '进度';

  @override
  String get progressShareTemplatesReportedBy => '报道：';

  @override
  String get progressShareTemplatesSourcesCloseToThe =>
      '据接近当事人的消息来源证实，这一转变归功于持续的训练、诚实的饮食以及从不跳过练腿日。专家称之为“前所未有的奉献”。';

  @override
  String get progressShareTemplatesTheDailyGains => '每日增肌';

  @override
  String progressShareTemplatesTheGlowUp(Object durationText) {
    return '$durationText 的蜕变';
  }

  @override
  String get progressShareTemplatesTheTransformation => '蜕变';

  @override
  String get progressShareTemplatesTimeline => '时间轴';

  @override
  String progressShareTemplatesToLater(Object durationText) {
    return '至 $durationText 后';
  }

  @override
  String get progressShareTemplatesToRightNow => '到此时此刻。';

  @override
  String progressShareTemplatesTotal(Object totalWorkouts) {
    return '总计 $totalWorkouts 次';
  }

  @override
  String get progressShareTemplatesTransformationNtuesday => '#蜕变\n周二';

  @override
  String get progressShareTemplatesTransformed => '已蜕变';

  @override
  String progressShareTemplatesValue(Object daysBetween) {
    return '#$daysBetween';
  }

  @override
  String progressShareTemplatesValue2(Object daysBetween) {
    return '#$daysBetween';
  }

  @override
  String progressShareTemplatesVol(Object totalWorkouts) {
    return '总量 $totalWorkouts';
  }

  @override
  String progressShareTemplatesWW(Object weeks) {
    return '第1周 → 第$weeks周';
  }

  @override
  String progressShareTemplatesWorkouts(Object totalWorkouts) {
    return '$totalWorkouts 次锻炼';
  }

  @override
  String progressShareTemplatesWorkoutsDayStreak(
    Object currentStreak,
    Object totalWorkouts,
  ) {
    return '$totalWorkouts 次锻炼 · $currentStreak 天连续记录';
  }

  @override
  String get progressShareTemplatesZealova => 'ZEALOVA';

  @override
  String get progressShareTemplatesZealovaMarket => 'ZEALOVA 市场';

  @override
  String get progressSignUpToUnlock => '注册以解锁';

  @override
  String get progressStrength => '力量';

  @override
  String get progressTakePhoto => '拍照';

  @override
  String get progressTemplateDayStreak => '连续天数';

  @override
  String get progressTemplatePrsThisMonth => '本月 PR';

  @override
  String get progressTemplateThisWeek => '本周';

  @override
  String get progressTemplateTotalLifted => '总举重重量';

  @override
  String get progressTemplateTotalWorkouts => '总训练次数';

  @override
  String get progressThisActionCannotBe => '此操作无法撤销。';

  @override
  String get progressTrackYourFitnessJourney =>
      '通过进度照片、身体测量和力量评分来追踪你的健身之旅。看看你已经走了多远！';

  @override
  String get progressUploadFailed => '上传失败';

  @override
  String get progressUploadingPhoto => '正在上传照片...';

  @override
  String get progressUseCamera => '使用相机';

  @override
  String get progressWeCouldnTSave => '无法保存你的照片。请重试。';

  @override
  String progressionChainCardStepOf(Object chain, Object currentStepOrder) {
    return '第 $currentStepOrder 步，共 $chain 步';
  }

  @override
  String progressionChainCardStepOf2(Object chain, Object currentStepOrder) {
    return '第 $currentStepOrder 步，共 $chain 步';
  }

  @override
  String progressionChainCardSteps(Object chain) {
    return '$chain 步';
  }

  @override
  String get progressionPaceAutoDeloadWeeks => '自动减载周';

  @override
  String get progressionPaceControlHowQuicklyThe =>
      '控制 AI 增加训练重量的速度。较慢的进度对初学者更安全，而较快的进度适合有经验的举重者。';

  @override
  String get progressionPaceDeloadFrequency => '减载频率';

  @override
  String get progressionPaceDeloadSettings => '减载设置';

  @override
  String get progressionPaceFineTuneSettings => '微调设置';

  @override
  String get progressionPaceHowManyWeeksBefore => '增加重量前的周数';

  @override
  String get progressionPaceHowMuchToIncrease => '每次进阶增加多少重量';

  @override
  String get progressionPacePeriodicallyReduceIntensity => '定期降低强度以进行恢复';

  @override
  String get progressionPaceProgressionPace => '进阶节奏';

  @override
  String get progressionPaceProgressionSpeed => '进度速度';

  @override
  String get progressionPaceProgressiveOverload => '渐进式超负荷';

  @override
  String get progressionPaceSaveSettings => '保存设置';

  @override
  String progressionPaceScreenEveryWeeks(Object deloadFrequency) {
    return '每 $deloadFrequency 周';
  }

  @override
  String progressionPaceScreenWeeks(Object weeksToProgress) {
    return '$weeksToProgress 周';
  }

  @override
  String get progressionPaceSettingsSaved => '设置已保存';

  @override
  String get progressionPaceWeeksToProgress => '进阶周数';

  @override
  String get progressionPaceWeightIncrement => '重量增量';

  @override
  String get progressionSelectorAdvanced => '进阶';

  @override
  String get progressionSelectorAutoAdjusts => '自动调整';

  @override
  String get progressionSelectorChooseHowWeightChanges => '选择重量在各组间如何变化';

  @override
  String get progressionSelectorSetProgression => '设置进阶';

  @override
  String get progressionSelectorSubtitle => '副标题';

  @override
  String get progressionSelectorTitle => '标题';

  @override
  String get progressionSelectorWhenToUse => '何时使用';

  @override
  String get progressionStepCardCompletePreviousStepTo => '完成上一步以解锁';

  @override
  String get progressionStepCardCompleted => '已完成';

  @override
  String progressionStepCardGoal(Object unlockCriteriaText) {
    return '目标: $unlockCriteriaText';
  }

  @override
  String get progressionStepCardPractice => '练习';

  @override
  String get progressionStripTarget => '目标 ';

  @override
  String get progressionSuggestionCardCompleteAFewMore => '再完成几次“轻松”训练以解锁进阶';

  @override
  String get progressionSuggestionCardCurrent => '当前';

  @override
  String get progressionSuggestionCardExerciseUnlocked => '动作已解锁！';

  @override
  String get progressionSuggestionCardKeepCurrent => '保持当前';

  @override
  String get progressionSuggestionCardKeepGoing => '继续加油！';

  @override
  String get progressionSuggestionCardNextLevel => '下一等级';

  @override
  String get progressionSuggestionCardTryNextLevel => '尝试下一等级';

  @override
  String progressionSuggestionCardValue(Object difficultyIncrease) {
    return '+$difficultyIncrease';
  }

  @override
  String progressionSuggestionCardValue2(
    Object currentExercise,
    Object suggestedExercise,
  ) {
    return '$currentExercise -> $suggestedExercise';
  }

  @override
  String progressionSuggestionCardValue3(Object difficultyIncrease) {
    return '+$difficultyIncrease';
  }

  @override
  String get progressionSuggestionCardWhyThisProgression => '为什么选择此进阶？';

  @override
  String get proposedChangeCardApplied => '已应用';

  @override
  String get proposedChangeCardApplyChange => '应用更改';

  @override
  String get proposedChangeCardDismissed => '已忽略';

  @override
  String get proposedChangeCardExpiredAskAgainFor => '已过期 — 请再次询问以获取最新建议';

  @override
  String get proposedChangeCardNotNow => '暂不';

  @override
  String get protocolSelector12h => '12h';

  @override
  String get protocolSelectorAdvanced => '进阶';

  @override
  String protocolSelectorChipHFast(Object fastingHours) {
    return '$fastingHours小时断食';
  }

  @override
  String get protocolSelectorDuration => '持续时间';

  @override
  String get protocolSelectorExtendedFasts24h => '长时间禁食 (24小时+)';

  @override
  String get protocolSelectorSelectProtocol => '选择方案';

  @override
  String protocolSelectorSheetHours(Object _customHours) {
    return '$_customHours 小时';
  }

  @override
  String get protocolSelectorTimeRestrictedEating => '限时进食';

  @override
  String prsTemplateAchievementsUnlocked(Object length) {
    return '+$length 项成就已解锁';
  }

  @override
  String get prsTemplateKeepPushing => '继续努力！';

  @override
  String get prsTemplateNewPersonalRecords => '新的个人记录';

  @override
  String get prsTemplateNewPrsAreJust => '新的 PR 即将到来';

  @override
  String prsTemplateValue(Object unit) {
    return ') (单位)';
  }

  @override
  String prsTemplateValue2(Object improvement, Object unit) {
    return '+$improvement $unit';
  }

  @override
  String get publicRecipeIngredients => '配料';

  @override
  String get publicRecipeInstructions => '步骤';

  @override
  String get publicRecipeRecipeNotAvailable => '食谱不可用';

  @override
  String get publicRecipeSaveToMyRecipes => '保存到我的食谱';

  @override
  String publicRecipeScreenByViewsSaves(
    Object authorDisplayName,
    Object saveCount,
    Object viewCount,
  ) {
    return '作者：$authorDisplayName · $viewCount 次浏览 · $saveCount 次保存';
  }

  @override
  String queuePositionCardEstimatedWaitMin(Object estimatedWaitMinutes) {
    return '预计等待：~$estimatedWaitMinutes 分钟';
  }

  @override
  String get queuePositionCardInQueue => '排队中';

  @override
  String queuePositionCardInQueue2(Object position) {
    return '排队中：#$position';
  }

  @override
  String get queuePositionCardPleaseWaitWhileWe => '请稍候，我们正在为您连接\n客服专员';

  @override
  String queuePositionCardValue(Object position) {
    return '#$position';
  }

  @override
  String get queuePositionCardYouAre => '您当前排在第';

  @override
  String get quickActions500mlWaterLogged => '已记录 +500ml 水';

  @override
  String get quickActionsCustomizeQuickActions => '自定义快捷操作';

  @override
  String get quickActionsDisplayExtraShortcutsOn => '在首页显示额外快捷方式';

  @override
  String get quickActionsFailedToLogWater => '记录饮水失败。请重试。';

  @override
  String get quickActionsNoActionsFound => '未找到操作';

  @override
  String get quickActionsPleaseLogInTo => '请登录以追踪水分摄入';

  @override
  String get quickActionsResetToDefault => '重置为默认';

  @override
  String get quickActionsRow1 => '第 1 行';

  @override
  String get quickActionsRow100Ml => '100 ml';

  @override
  String get quickActionsRow125L => '1.25 L';

  @override
  String get quickActionsRow150Ml => '150 ml';

  @override
  String get quickActionsRow15L => '1.5 L';

  @override
  String get quickActionsRow1l => '1L';

  @override
  String get quickActionsRow2 => '第 2 行';

  @override
  String get quickActionsRow200Ml => '200 ml';

  @override
  String get quickActionsRow250ml => '250ml';

  @override
  String get quickActionsRow25L => '2.5 L';

  @override
  String get quickActionsRow2L => '2 L';

  @override
  String get quickActionsRow30Ml => '30 ml';

  @override
  String get quickActionsRow350Ml => '350 ml';

  @override
  String get quickActionsRow500ml => '500ml';

  @override
  String get quickActionsRow60Ml => '60 ml';

  @override
  String get quickActionsRow750ml => '750ml';

  @override
  String get quickActionsRowActive => '进行中';

  @override
  String get quickActionsRowBarcode => '条形码';

  @override
  String get quickActionsRowBigBottle => '大水瓶';

  @override
  String get quickActionsRowChat => '聊天';

  @override
  String get quickActionsRowCoach => '教练';

  @override
  String get quickActionsRowCustom => '自定义';

  @override
  String get quickActionsRowCustomAmount => '自定义数量';

  @override
  String get quickActionsRowEG180 => '例如 180';

  @override
  String get quickActionsRowEnd => '结束';

  @override
  String get quickActionsRowEnter15000Ml => '输入 1–5000 ml';

  @override
  String get quickActionsRowFailedToLogWater => '记录饮水失败。请重试。';

  @override
  String get quickActionsRowFastEndedSuccessfully => '轻断食已成功结束';

  @override
  String get quickActionsRowFasting => '轻断食';

  @override
  String get quickActionsRowGlass => '玻璃杯';

  @override
  String get quickActionsRowLargeJug => '大水壶';

  @override
  String get quickActionsRowLogFood => '记录饮食';

  @override
  String get quickActionsRowLogWater => '记录饮水';

  @override
  String get quickActionsRowMenu => '菜单';

  @override
  String get quickActionsRowMood => '心情';

  @override
  String get quickActionsRowMouthful => '一口';

  @override
  String get quickActionsRowOpenHydrationTracker => '打开饮水追踪器';

  @override
  String get quickActionsRowOrPickAPreset => '或选择预设';

  @override
  String quickActionsRowPartHeroActionCardFailedToEndFast(Object e) {
    return '结束断食失败：$e';
  }

  @override
  String quickActionsRowPartHeroActionCardFailedToUploadPhoto(Object e) {
    return '上传照片失败：$e';
  }

  @override
  String quickActionsRowPartHeroActionCardHM(Object hours, Object mins) {
    return '$hours小时 $mins分钟';
  }

  @override
  String quickActionsRowPartHeroActionCardPhotoSaved(Object displayName) {
    return '$displayName 照片已保存！';
  }

  @override
  String get quickActionsRowPhotoLog => '照片记录';

  @override
  String get quickActionsRowPleaseLogInTo => '请登录以追踪水分摄入';

  @override
  String get quickActionsRowQuick => '快捷';

  @override
  String get quickActionsRowScan => '扫描';

  @override
  String get quickActionsRowSelectAmountToLog => '选择要记录的数量';

  @override
  String get quickActionsRowSip => '小口';

  @override
  String get quickActionsRowSipToXlJug => '从小口到超大水壶，或精确输入';

  @override
  String get quickActionsRowSmallCup => '小杯';

  @override
  String get quickActionsRowSmallSip => '一小口';

  @override
  String get quickActionsRowSportsBottle => '运动水壶';

  @override
  String get quickActionsRowTakeAProgressPhoto => '拍摄进度照片，见证您的蜕变';

  @override
  String get quickActionsRowTallGlass => '高玻璃杯';

  @override
  String get quickActionsRowTrackYourProgress => '追踪您的进度';

  @override
  String get quickActionsRowUploadingPhoto => '正在上传照片...';

  @override
  String get quickActionsRowWater => '水';

  @override
  String get quickActionsRowWhatSThis => '这是什么？';

  @override
  String get quickActionsRowXlJug => '超大水壶';

  @override
  String get quickActionsSearchActions => '搜索操作...';

  @override
  String get quickActionsSheetActive => '进行中';

  @override
  String get quickActionsSheetEnd => '结束';

  @override
  String get quickActionsSheetFastEndedSuccessfully => '轻断食已成功结束';

  @override
  String get quickActionsSheetFasting => '轻断食';

  @override
  String quickActionsSheetPartHeroActionCardFailedToEndFast(Object e) {
    return '结束断食失败: $e';
  }

  @override
  String quickActionsSheetPartHeroActionCardHM(Object hours, Object mins) {
    return '$hours小时 $mins分钟';
  }

  @override
  String get quickActionsSheetTakeAProgressPhoto => '拍摄进度照片，见证您的蜕变';

  @override
  String get quickActionsSheetTrackYourProgress => '追踪您的进度';

  @override
  String get quickActionsShowTwoRows => '显示两行';

  @override
  String get quickAddFabLogFood => '记录饮食';

  @override
  String get quickAdjust5Min => '5 分钟';

  @override
  String get quickAdjustAdaptWorkout => '调整训练';

  @override
  String get quickAdjustAdjustTodaySWorkout => '直接调整今日训练。';

  @override
  String get quickAdjustDrained => '精疲力竭';

  @override
  String get quickAdjustEnergy => '能量';

  @override
  String get quickAdjustHowAreYouFeeling => '你感觉如何？';

  @override
  String get quickAdjustNone => '无';

  @override
  String get quickAdjustPeak => '巅峰';

  @override
  String get quickAdjustSoreness => '酸痛感';

  @override
  String get quickAdjustTimeAvailable => '可用时间';

  @override
  String get quickAdjustVerySore => '非常酸痛';

  @override
  String get quickLogFabBatch => '批量';

  @override
  String get quickLogFabListening => '正在聆听...';

  @override
  String get quickLogFabLogFood => '记录饮食';

  @override
  String get quickLogFabPhoto => '照片';

  @override
  String get quickLogFabScan => '扫描';

  @override
  String get quickLogFabType => '输入';

  @override
  String get quickLogFabVoice => '语音';

  @override
  String get quickLogMeasurementsBodyMeasurements => '身体测量数据';

  @override
  String get quickLogMeasurementsChest => '胸围';

  @override
  String get quickLogMeasurementsHips => '臀围';

  @override
  String get quickLogMeasurementsLoadingMeasurements => '正在加载测量数据...';

  @override
  String get quickLogMeasurementsLog => '记录';

  @override
  String get quickLogMeasurementsLogMeasurements => '记录测量数据';

  @override
  String get quickLogMeasurementsMeasurements => '测量数据';

  @override
  String get quickLogMeasurementsNotLoggedYet => '尚未记录';

  @override
  String get quickLogMeasurementsPleaseSignInTo => '请登录以记录测量数据';

  @override
  String get quickLogMeasurementsTapToViewFull => '点击查看完整历史记录和趋势';

  @override
  String get quickLogMeasurementsTrackYourBodyChanges => '追踪你的身体变化';

  @override
  String get quickLogMeasurementsUpdate => '更新';

  @override
  String quickLogMeasurementsUpdatedDaysAgo(Object arg0) {
    return '$arg0 天前更新';
  }

  @override
  String get quickLogMeasurementsUpdatedToday => '今天更新';

  @override
  String get quickLogMeasurementsUpdatedYesterday => '昨天';

  @override
  String get quickLogMeasurementsWaist => '腰围';

  @override
  String get quickLogOverlayBreakfast => '早餐';

  @override
  String get quickLogOverlayDinner => '晚餐';

  @override
  String get quickLogOverlayGoToApp => '前往应用';

  @override
  String get quickLogOverlayLunch => '午餐';

  @override
  String get quickLogOverlayQuickLog => '快速记录';

  @override
  String get quickLogOverlaySnack => '零食';

  @override
  String get quickLogOverlayTapAMealType => '点击餐食类型进行记录，或前往应用查看更多选项';

  @override
  String get quickLogWeightLogMoreWeightsTo => '记录更多体重数据以查看趋势';

  @override
  String get quickLogWeightLogged => '已记录！';

  @override
  String get quickLogWeightQuickLogWeight => '快速记录体重';

  @override
  String get quickStartCardCouldNotLoadWorkout => '无法加载训练';

  @override
  String get quickStartCardGenerateAWorkoutProgram => '生成一个训练计划以开始！';

  @override
  String quickStartCardInDays(Object daysUntilNext) {
    return '$daysUntilNext 天后';
  }

  @override
  String get quickStartCardLoadingTodaySWorkout => '正在加载今日训练...';

  @override
  String quickStartCardNext(Object name) {
    return '下一项：$name';
  }

  @override
  String get quickStartCardNoWorkoutsScheduled => '暂无计划的训练';

  @override
  String get quickStartCardRestDay => '休息日';

  @override
  String get quickStartCardStartWorkout => '开始训练';

  @override
  String get quickStartCardTakeItEasyToday => '今天放轻松！';

  @override
  String get quickStartCardTomorrow => '明天';

  @override
  String get quickStartCardViewUpcoming => '查看即将进行的训练';

  @override
  String get quickStatsCardActive => '已启用';

  @override
  String get quickStatsCardActiveFeatures => '已启用的功能';

  @override
  String get quickStatsCardConfigureYourHormonalHealth =>
      '配置你的荷尔蒙健康偏好以获取个性化见解。';

  @override
  String get quickStatsCardCycleSyncedNutrition => '周期同步营养';

  @override
  String get quickStatsCardCycleSyncedWorkouts => '周期同步训练';

  @override
  String get quickStatsCardCycleTracking => '周期追踪';

  @override
  String get quickStatsCardEnabled => '已启用';

  @override
  String get quickStatsCardOn => '开启';

  @override
  String get quickStatsCardPcosSupport => 'PCOS 支持';

  @override
  String get quickStatsCardTOptimization => 'T-Optimization';

  @override
  String get quickWorkoutAllEquipment => '所有器械';

  @override
  String get quickWorkoutAvailableWeights => '可用重量';

  @override
  String get quickWorkoutConflictAddAnyway => '仍然添加';

  @override
  String quickWorkoutConflictBody(Object workoutName) {
    return '您今天已经安排了“$workoutName”。您想怎么做？';
  }

  @override
  String get quickWorkoutConflictChangeDate => '更改日期';

  @override
  String get quickWorkoutConflictReplace => '替换';

  @override
  String get quickWorkoutConflictTitle => '训练已安排';

  @override
  String get quickWorkoutDiscoverSubtitle => '基于您的个人资料的个性化建议';

  @override
  String get quickWorkoutDiscoverWorkouts => '发现训练';

  @override
  String get quickWorkoutDuration => '时长';

  @override
  String get quickWorkoutFavorite => '收藏';

  @override
  String get quickWorkoutFocus => '重点';

  @override
  String get quickWorkoutFocusOptional => '重点（可选）';

  @override
  String get quickWorkoutNoSuggestions => '暂无建议';

  @override
  String get quickWorkoutSheetAddAnyway => '仍然添加';

  @override
  String get quickWorkoutSheetAllEquipment => '所有器械';

  @override
  String get quickWorkoutSheetAvailableWeights => '可用重量';

  @override
  String get quickWorkoutSheetChangeDate => '更改日期';

  @override
  String get quickWorkoutSheetClear => '清除';

  @override
  String get quickWorkoutSheetCustomizeMore => '更多自定义';

  @override
  String get quickWorkoutSheetDifficulty => '难度';

  @override
  String get quickWorkoutSheetDiscoverWorkouts => '发现训练';

  @override
  String get quickWorkoutSheetDuration => '时长';

  @override
  String get quickWorkoutSheetEquipment => '器械';

  @override
  String get quickWorkoutSheetEquipmentDetails => '器械详情';

  @override
  String get quickWorkoutSheetFavorite => '收藏';

  @override
  String get quickWorkoutSheetFocusOptional => '重点（可选）';

  @override
  String get quickWorkoutSheetFormat => '形式';

  @override
  String get quickWorkoutSheetFullGym => '完整健身房';

  @override
  String get quickWorkoutSheetGenerating => '正在生成...';

  @override
  String get quickWorkoutSheetGoalOptional => '目标（可选）';

  @override
  String get quickWorkoutSheetInjuriesOptional => '伤病（可选）';

  @override
  String get quickWorkoutSheetInstantGenerationPoweredBy => '基于运动科学研究的即时生成。';

  @override
  String get quickWorkoutSheetMoodOptional => '心情（可选）';

  @override
  String get quickWorkoutSheetNoAdditionalSuggestionsAvai => '没有其他建议。';

  @override
  String get quickWorkoutSheetPairOpposingMusclesTo => '组合拮抗肌群以节省时间';

  @override
  String quickWorkoutSheetPartQuickWorkoutSheetStateExt1X(Object qty) {
    return '${qty}x';
  }

  @override
  String quickWorkoutSheetPartQuickWorkoutSheetStateGenerateMinWorkout(
    Object _selectedDuration,
  ) {
    return '生成 $_selectedDuration 分钟训练';
  }

  @override
  String quickWorkoutSheetPartQuickWorkoutSheetStateMesocycle(
    Object phaseDisplayName,
  ) {
    return '周期：$phaseDisplayName';
  }

  @override
  String quickWorkoutSheetPartQuickWorkoutSheetStateMin(
    Object _selectedDuration,
  ) {
    return '$_selectedDuration 分钟';
  }

  @override
  String quickWorkoutSheetPartQuickWorkoutSheetStateWeek(
    Object totalWeeks,
    Object weekNumber,
  ) {
    return '第 $weekNumber/$totalWeeks 周';
  }

  @override
  String get quickWorkoutSheetPerfectForBusyDays => '忙碌日期的完美选择';

  @override
  String get quickWorkoutSheetPersonalizedSuggestionsBased => '基于你个人资料的个性化建议';

  @override
  String get quickWorkoutSheetQuickWorkout => '快速训练';

  @override
  String get quickWorkoutSheetReplace => '替换';

  @override
  String get quickWorkoutSheetShowLess => '收起';

  @override
  String get quickWorkoutSheetSupersets => '超级组';

  @override
  String get quickWorkoutSheetTapToAddTap => '点击添加（再次点击可配对）';

  @override
  String get quickWorkoutSheetUnfavorite => '取消收藏';

  @override
  String get quickWorkoutSheetWithPlates => '含杠铃片';

  @override
  String get quickWorkoutSheetWorkoutAlreadyScheduled => '训练计划已安排';

  @override
  String get quickWorkoutSheetWorkoutFocus => '训练重点';

  @override
  String get quickWorkoutSubtitle => '副标题';

  @override
  String get quickWorkoutTapToAddPairs => '点击添加哑铃对';

  @override
  String get quickWorkoutTitle => '标题';

  @override
  String get quickWorkoutUnfavorite => '取消收藏';

  @override
  String get quickWorkoutWithPlates => '含杠铃片';

  @override
  String get quitWorkoutAddANoteOptional => '添加备注（可选）...';

  @override
  String quitWorkoutDialogCompleteSetsDone(
    Object progressPercent,
    Object totalCompletedSets,
  ) {
    return '$progressPercent% 完成 • 已完成 $totalCompletedSets 组';
  }

  @override
  String quitWorkoutDialogSays(Object name) {
    return '$name 说:';
  }

  @override
  String get quitWorkoutEndWorkout => '结束训练';

  @override
  String get quitWorkoutEndWorkoutEarly => '提前结束训练？';

  @override
  String get quitWorkoutEquipmentBusy => '器械被占用';

  @override
  String get quitWorkoutKeepGoing => '继续训练';

  @override
  String get quitWorkoutNotFeelingWell => '身体不适';

  @override
  String get quitWorkoutOtherReason => '其他原因';

  @override
  String get quitWorkoutOutOfTime => '时间不够';

  @override
  String get quitWorkoutPainInjury => '疼痛/受伤';

  @override
  String get quitWorkoutTooTired => '太累了';

  @override
  String get quitWorkoutWhyAreYouEnding => '为什么要提前结束？';

  @override
  String quizBodyMetricsEnterAValueBetween(Object dialogMax, Object unit) {
    return '输入 1-$dialogMax $unit 之间的数值';
  }

  @override
  String quizBodyMetricsEnterAmountTo(Object directionLabel) {
    return '输入要 $directionLabel 的数值';
  }

  @override
  String get quizBodyMetricsGain => '增肌';

  @override
  String get quizBodyMetricsGender => '性别';

  @override
  String get quizBodyMetricsHeight => '身高';

  @override
  String quizBodyMetricsHowMuchDoYou(Object directionLabel) {
    return '你想要 $directionLabel 多少？';
  }

  @override
  String get quizBodyMetricsLetSSetYour => '设定您的身体目标';

  @override
  String get quizBodyMetricsLose => '减脂';

  @override
  String get quizBodyMetricsMaintain => '维持';

  @override
  String get quizBodyMetricsOther => '其他';

  @override
  String quizBodyMetricsUiCurrentBmi(Object bmi) {
    return '当前 BMI：$bmi';
  }

  @override
  String quizBodyMetricsUiY(Object age) {
    return '$age 岁';
  }

  @override
  String get quizBodyMetricsWeLlUseThis => '我们将用此数据计算您的个性化目标';

  @override
  String get quizBodyMetricsWeight => '体重';

  @override
  String get quizBodyMetricsWeightGoal => '体重目标';

  @override
  String get quizBodyMetricsWhatShouldWeCall => '怎么称呼您？';

  @override
  String get quizBodyMetricsYourName => '您的名字';

  @override
  String get quizContinueButtonSeeMyPlan => '查看我的计划';

  @override
  String get quizDaysSelectorAiGeneratesWorkoutsWithin => 'AI 将在您选择的范围内生成训练';

  @override
  String get quizDaysSelectorBest => '最佳';

  @override
  String get quizDaysSelectorConsistencyBeatsIntensity => '坚持胜过强度 - 选择您能保持的频率';

  @override
  String quizDaysSelectorDays(Object arg0) {
    return '$arg0 天';
  }

  @override
  String quizDaysSelectorDaysSelected(Object arg0, Object arg1) {
    return '已选 $arg0 天 $arg1';
  }

  @override
  String get quizDaysSelectorForYourWorkouts => ') 用于您的训练';

  @override
  String get quizDaysSelectorFri => '周五';

  @override
  String get quizDaysSelectorHowLongAreYour => '您的训练时长是多少？';

  @override
  String get quizDaysSelectorHowManyDaysPer => '您每周可以训练几天？';

  @override
  String get quizDaysSelectorMin => '最少';

  @override
  String get quizDaysSelectorMon => '周一';

  @override
  String get quizDaysSelectorSat => '周六';

  @override
  String quizDaysSelectorSelectNDays(Object arg0) {
    return '选择 $arg0 天';
  }

  @override
  String get quizDaysSelectorSun => '周日';

  @override
  String get quizDaysSelectorThu => '周四';

  @override
  String get quizDaysSelectorTue => '周二';

  @override
  String get quizDaysSelectorWed => '周三';

  @override
  String get quizDaysSelectorWhichDaysWorkBest => '哪几天最方便？';

  @override
  String get quizEquipmentApartmentFriendly => '公寓友好型';

  @override
  String get quizEquipmentBarbell => '杠铃';

  @override
  String get quizEquipmentBodyweightBands => '自重 + 弹力带';

  @override
  String get quizEquipmentBodyweightOnly => '仅自重';

  @override
  String get quizEquipmentBodyweightOnly2 => '仅自重训练';

  @override
  String get quizEquipmentBodyweightPullUpBar => '自重 + 引体向上杆';

  @override
  String get quizEquipmentCableMachine => '绳索训练机';

  @override
  String get quizEquipmentCouldnTLoadIdentified => '无法加载识别的器械。请从下方列表中选择。';

  @override
  String get quizEquipmentCouldnTOpenThe => '无法打开相机。请在下方选择您的器械。';

  @override
  String get quizEquipmentDedicatedSpaceWithDumbbells => '拥有哑铃、杠铃、长凳的专用空间';

  @override
  String get quizEquipmentDoYouHaveA => '您有健身长凳吗？';

  @override
  String get quizEquipmentDoYouHaveA2 => '您有深蹲架吗？';

  @override
  String get quizEquipmentDumbbells => '哑铃';

  @override
  String get quizEquipmentEnablesChestPress => '支持胸部推举';

  @override
  String get quizEquipmentFlatBench => '平卧推凳';

  @override
  String get quizEquipmentFullGym => '综合健身房';

  @override
  String get quizEquipmentFullGymAccess => '健身房器械';

  @override
  String get quizEquipmentFullGymWithMachines => '包含器械、绳索和自由重量的综合健身房';

  @override
  String get quizEquipmentGym => '健身房';

  @override
  String get quizEquipmentHome => '居家';

  @override
  String get quizEquipmentHomeDumbbellsBench => '居家 + 哑铃和长凳';

  @override
  String get quizEquipmentHomeGym => '家庭健身房';

  @override
  String get quizEquipmentHomeKettlebell => '居家 + 壶铃';

  @override
  String get quizEquipmentHotel => '酒店';

  @override
  String quizEquipmentIdentifiedCount(Object arg0) {
    return '已识别数量 $arg0';
  }

  @override
  String get quizEquipmentKettlebell => '壶铃';

  @override
  String get quizEquipmentMedicineBall => '药球';

  @override
  String get quizEquipmentMinimalEquipmentBodyweight => '极简器械 - 自重、瑜伽垫';

  @override
  String get quizEquipmentNeededForBarbell => '杠铃所需';

  @override
  String get quizEquipmentNoEquipmentIdentifiedPick => '未识别到器械。请从下方列表中选择。';

  @override
  String quizEquipmentOtherCount(Object arg0) {
    return '其他数量 $arg0';
  }

  @override
  String get quizEquipmentOtherEquipment => '其他器械';

  @override
  String get quizEquipmentPullUpBar => '引体向上杆';

  @override
  String get quizEquipmentQuickPresets => '快速预设';

  @override
  String get quizEquipmentRecommended => '推荐';

  @override
  String get quizEquipmentRequiredForBarbellSquat => '适用于：杠铃深蹲、推举、杠铃卧推';

  @override
  String get quizEquipmentResistanceBands => '弹力带';

  @override
  String get quizEquipmentSelectAllThatApply => '选择所有适用的项 - 我们将根据您拥有的器械设计训练';

  @override
  String get quizEquipmentSelectingYourWorkoutEnviron =>
      '选择您的训练环境有助于我们为您推荐合适的动作和器械。';

  @override
  String get quizEquipmentSquatRack => '深蹲架';

  @override
  String get quizEquipmentTakeAFewPhotos => '拍几张照片，我们的 AI 将识别您的器械。';

  @override
  String get quizEquipmentTravelFriendlyDumbbellsC => '差旅友好型 - 哑铃、有氧器械';

  @override
  String get quizEquipmentTrxSuspension => 'TRX悬挂训练带';

  @override
  String get quizEquipmentU1f3e0 => '🏠';

  @override
  String get quizEquipmentU1f3e1 => '🏡';

  @override
  String get quizEquipmentU1f3e2 => '🏢';

  @override
  String get quizEquipmentU1f4f8SnapYour => '📸 拍摄您的健身房';

  @override
  String get quizEquipmentU1f9f3 => '🧳';

  @override
  String get quizEquipmentUnlocksBenchPressIncline => '解锁：卧推、上斜推举、仰卧上拉、胸部支撑划船';

  @override
  String get quizEquipmentUnlocksChestSupportedKb => '解锁：胸部支撑壶铃划船、壶铃地板推举替代动作';

  @override
  String quizEquipmentUsersSnappedEquipment(Object apiBaseUrl, Object userId) {
    return '$apiBaseUrl/users/$userId/snapped-equipment';
  }

  @override
  String get quizEquipmentWhatEquipmentDoYou => '您可以使用哪些器械？';

  @override
  String get quizEquipmentWhereDoYouWorkout => '您在哪里训练？';

  @override
  String get quizEquipmentWorkoutEnvironment => '训练环境';

  @override
  String get quizEquipmentYesAddIt => '是的，添加它';

  @override
  String get quizEquipmentYouCanCustomizeEquipment =>
      '您可以在选择环境后自定义器械，或跳过此步骤手动选择。';

  @override
  String get quizFastingApplyCustomProtocol => '应用自定义方案';

  @override
  String get quizFastingChooseAFastingProtocol => '选择一种轻断食方案';

  @override
  String quizFastingCustomProtocol(
    Object _customEatingHours,
    Object _customFastingHours,
  ) {
    return '自定义 $_customFastingHours:$_customEatingHours 方案';
  }

  @override
  String get quizFastingEatingHours => '进食时间';

  @override
  String get quizFastingFastingHours => '断食时间';

  @override
  String quizFastingH(Object _customFastingHours) {
    return '$_customFastingHours 小时';
  }

  @override
  String quizFastingH2(Object _customEatingHours) {
    return '$_customEatingHours 小时';
  }

  @override
  String get quizFastingIntermittentFastingCanHelp => '轻断食可以帮助您更快达成目标';

  @override
  String get quizFastingOptionalYouCanSet => '可选 - 您以后可以再设置';

  @override
  String get quizFastingPopular => '热门';

  @override
  String get quizFastingRecommended => '推荐';

  @override
  String get quizFastingSetYourCustomFasting => '设置您的自定义断食窗口';

  @override
  String quizFastingUiAHEatingWindow(Object eatingHours, Object maxMeals) {
    return '$eatingHours小时的进食窗口最多可容纳 $maxMeals 餐。';
  }

  @override
  String quizFastingUiAdjustToMeals(Object maxMeals) {
    return '调整为 $maxMeals 餐';
  }

  @override
  String get quizFastingUiBedtime => '就寝时间';

  @override
  String get quizFastingUiHelpsOptimizeYourFasting => '有助于优化您的断食窗口';

  @override
  String quizFastingUiMealScheduleInH(Object eatingHours) {
    return '$eatingHours小时进食窗口的饮食计划';
  }

  @override
  String quizFastingUiMealsSpacedHoursApart(
    Object hoursBetweenMeals,
    Object meals,
  ) {
    return '$meals 餐，每餐间隔 ~$hoursBetweenMeals 小时';
  }

  @override
  String get quizFastingUiTipConsiderLargerNutrient => '提示：考虑摄入分量更大、营养丰富的餐食';

  @override
  String get quizFastingUiWakeUp => '起床时间';

  @override
  String get quizFastingUiYourSleepSchedule => '您的睡眠时间表';

  @override
  String get quizFastingYesLetSTry => '是的，试试看';

  @override
  String get quizFitnessLevel2To5Years => '2 至 5 年经验';

  @override
  String get quizFitnessLevel5PlusYears => '5 年以上经验';

  @override
  String get quizFitnessLevel6MonTo2Yrs => '6 个月至 2 年经验';

  @override
  String get quizFitnessLevelAdvanced => '进阶';

  @override
  String get quizFitnessLevelAdvancedDesc => '进阶描述';

  @override
  String get quizFitnessLevelBeHonestWeLl => '请诚实回答——我们会随您的进度进行调整';

  @override
  String get quizFitnessLevelBeginner => '初学者';

  @override
  String get quizFitnessLevelBeginnerDesc => '初学者描述';

  @override
  String get quizFitnessLevelBrandNewToLifting => '刚接触力量训练';

  @override
  String get quizFitnessLevelBuildingConsistency => '建立运动习惯';

  @override
  String get quizFitnessLevelDailyActivityLevelOutside => '日常活动水平（健身房外）？';

  @override
  String get quizFitnessLevelHelpsCalculateYourCalorie => '有助于计算您的热量需求';

  @override
  String get quizFitnessLevelHowLongHaveYou => '您进行力量训练有多久了？';

  @override
  String get quizFitnessLevelIntermediate => '中级';

  @override
  String get quizFitnessLevelIntermediateDesc => '中级描述';

  @override
  String get quizFitnessLevelJustGettingStarted => '刚开始起步';

  @override
  String get quizFitnessLevelLessThan6Months => '少于 6 个月经验';

  @override
  String get quizFitnessLevelLight => '轻度';

  @override
  String get quizFitnessLevelLightDesc => '轻度描述';

  @override
  String get quizFitnessLevelModerate => '中度';

  @override
  String get quizFitnessLevelModerateDesc => '中度描述';

  @override
  String get quizFitnessLevelNever => '从不';

  @override
  String get quizFitnessLevelSedentary => '久坐不动';

  @override
  String get quizFitnessLevelSedentaryDesc => '久坐不动描述';

  @override
  String get quizFitnessLevelSolidFoundation => '有坚实基础';

  @override
  String get quizFitnessLevelThisHelpsUsPick => '这有助于我们选择合适的练习';

  @override
  String get quizFitnessLevelVeryActive => '非常活跃';

  @override
  String get quizFitnessLevelVeryActiveDesc => '非常活跃描述';

  @override
  String get quizFitnessLevelVeteranLifter => '资深训练者';

  @override
  String get quizFitnessLevelWhatSYourCurrent => '您目前的健身水平如何？';

  @override
  String get quizLimitationsAnyInjuriesOrLimitations => '有任何伤病或限制吗？';

  @override
  String get quizLimitationsDescribeYourLimitation => '描述您的限制';

  @override
  String get quizLimitationsEGCarpalTunnel => '例如：腕管综合征、椎间盘突出等';

  @override
  String get quizLimitationsWeLlAvoidExercises => '我们将避开会对这些部位造成压力的练习';

  @override
  String get quizMotivationBeHealthierOverall => '整体更健康';

  @override
  String get quizMotivationBuildConfidence => '建立自信';

  @override
  String get quizMotivationFeelStronger => '感觉更强壮';

  @override
  String get quizMotivationHaveMoreEnergy => '拥有更多精力';

  @override
  String get quizMotivationImproveMentalHealth => '改善心理健康';

  @override
  String get quizMotivationLookBetter => '外形更好';

  @override
  String get quizMotivationSelectAllThatResonate => '选择所有符合您情况的选项';

  @override
  String get quizMotivationSleepBetter => '改善睡眠';

  @override
  String get quizMotivationSportsPerformance => '运动表现';

  @override
  String get quizMotivationWhatSDrivingYou => '是什么驱动您去锻炼？';

  @override
  String quizMuscleFocusAvailable(
    Object availablePoints,
    Object maxTotalPoints,
  ) {
    return '$availablePoints/$maxTotalPoints 可用点数';
  }

  @override
  String get quizMuscleFocusCore => '核心';

  @override
  String get quizMuscleFocusFocusPoints => '重点部位';

  @override
  String get quizMuscleFocusLowerBody => '下肢';

  @override
  String get quizMuscleFocusUpperBody => '上肢';

  @override
  String get quizNutritionGateCalorieMacroTargets => '热量与宏量营养素目标';

  @override
  String get quizNutritionGateDietaryPreferences => '饮食偏好';

  @override
  String get quizNutritionGateGetPersonalizedCalorieAnd =>
      '获取个性化的热量与宏量营养素目标，以支持您的健身目标';

  @override
  String get quizNutritionGateMealTimingGuidance => '进餐时间指导';

  @override
  String get quizNutritionGateNotNow => '暂不';

  @override
  String get quizNutritionGateOptimizeWhenYouEat => '优化您的进餐时间以获得更好的效果';

  @override
  String get quizNutritionGateOptional => '可选';

  @override
  String get quizNutritionGateRecommendedForYou => '为您推荐';

  @override
  String get quizNutritionGateRespectsYourRestrictionsAnd => '尊重您的限制和偏好';

  @override
  String get quizNutritionGateTailoredToYourGoals => '根据您的目标和活动水平量身定制';

  @override
  String get quizNutritionGateWantNutritionGuidanceToo => '也需要营养指导吗？';

  @override
  String get quizNutritionGateYesSetNutrition => '是的，设置营养方案';

  @override
  String get quizNutritionGoalsAnyDietaryRestrictions => '有任何饮食限制吗？';

  @override
  String quizNutritionGoalsG(Object protein) {
    return '${protein}g';
  }

  @override
  String quizNutritionGoalsG2(Object carbs) {
    return '${carbs}g';
  }

  @override
  String quizNutritionGoalsG3(Object fat) {
    return '${fat}g';
  }

  @override
  String get quizNutritionGoalsHelpsPersonalizeMealSuggest => '有助于个性化餐食建议';

  @override
  String get quizNutritionGoalsIncludeAllMealsAnd => '包含所有正餐和零食';

  @override
  String quizNutritionGoalsKcalGProteinPer(
    Object calPerMeal,
    Object proteinPerMeal,
  ) {
    return '每餐 $calPerMeal kcal 和 ${proteinPerMeal}g 蛋白质';
  }

  @override
  String get quizNutritionGoalsMealsSnacksPerDay => '每天的餐食 + 零食次数？';

  @override
  String get quizNutritionGoalsSelectAllThatApply => '选择所有适用的选项';

  @override
  String get quizNutritionGoalsWhatAreYourNutrition => '您的营养目标是什么？';

  @override
  String get quizNutritionGoalsYourEstimatedDailyTargets => '您的每日预估目标';

  @override
  String get quizPersonalizationGateAFewQuickMeasurements => '几个快速测量数据';

  @override
  String get quizPersonalizationGateCurrentWeight => '当前体重';

  @override
  String get quizPersonalizationGateFemale => '女性';

  @override
  String get quizPersonalizationGateFineTune2Min => '微调（2分钟）';

  @override
  String get quizPersonalizationGateGoalWeight => '目标体重';

  @override
  String get quizPersonalizationGateHeight => '身高';

  @override
  String get quizPersonalizationGateMale => '男性';

  @override
  String get quizPersonalizationGateOther => '其他';

  @override
  String get quizPersonalizationGateQuickStart => '快速开始';

  @override
  String get quizPersonalizationGateUsedToPersonalizeYour => '用于个性化您的计划和预测';

  @override
  String get quizPrimaryGoalAdjustsRestPeriodsExercise =>
      '根据您的侧重点调整休息时间、练习难度和整体训练量。';

  @override
  String get quizPrimaryGoalAiPicksExercisesThat =>
      'AI 会挑选最符合您目标的练习——力量训练选择复合动作，增肌训练选择孤立动作。';

  @override
  String get quizPrimaryGoalCanChangeAnytime => '可随时更改';

  @override
  String get quizPrimaryGoalExerciseSelection => '练习选择';

  @override
  String get quizPrimaryGoalGotIt => '明白了';

  @override
  String get quizPrimaryGoalHowAiUsesThis => 'AI 如何使用这些信息';

  @override
  String get quizPrimaryGoalRepRanges => '次数范围';

  @override
  String get quizPrimaryGoalSetsTheNumberOf =>
      '设置每个练习的重复次数。增肌通常为 8-12 次，力量训练为 3-6 次，耐力训练为 12 次以上。';

  @override
  String get quizPrimaryGoalWorkoutIntensity => '训练强度';

  @override
  String get quizPrimaryGoalYouCanUpdateYour => '当您的目标发生变化时，您可以随时在设置中更新您的训练重点。';

  @override
  String get quizProgressionConstraintsBalanced => '均衡';

  @override
  String get quizProgressionConstraintsBuildStrengthGraduallyLowe =>
      '循序渐进地增强力量，降低受伤风险';

  @override
  String get quizProgressionConstraintsFastAggressive => '快速且激进';

  @override
  String get quizProgressionConstraintsHowFastDoYou => '您希望进步的速度有多快？';

  @override
  String get quizProgressionConstraintsProgressionPace => '进步节奏';

  @override
  String get quizProgressionConstraintsPushHardFasterGains =>
      '高强度推进，更快获得收益（进阶）';

  @override
  String get quizProgressionConstraintsSlowSteady => '缓慢且稳健';

  @override
  String get quizProgressionConstraintsSteadyProgressWithManageabl =>
      '在可控的挑战下稳步前进';

  @override
  String get quizTrainingPreferencesAllOptional => '均为可选';

  @override
  String get quizTrainingPreferencesBiggestObstacles => '最大的障碍';

  @override
  String get quizTrainingPreferencesNotSureTapTo => '不确定？点击了解更多';

  @override
  String get quizTrainingPreferencesProgressionPace => '进步节奏';

  @override
  String get quizTrainingPreferencesProgressiveOverloadRirInt =>
      '整合了渐进式超负荷与 RIR';

  @override
  String get quizTrainingPreferencesTrainingPreferences => '训练偏好';

  @override
  String get quizTrainingPreferencesTrainingSplitsExplained => '训练拆分详解';

  @override
  String quizTrainingPreferencesValue(Object selectedCount) {
    return '$selectedCount/3';
  }

  @override
  String get quizTrainingPreferencesWorkoutTypes => '训练类型';

  @override
  String get quizTrainingStyleArnoldSplit => 'Arnold Split';

  @override
  String get quizTrainingStyleAutomaticallyOptimizedForYo => '自动为您优化（推荐）';

  @override
  String get quizTrainingStyleBestFor56 => '最适合每周 5-6 天';

  @override
  String get quizTrainingStyleBodyPartSplit => '身体部位分化训练';

  @override
  String get quizTrainingStyleChestBackShouldersArms => '胸/背、肩/臂、腿（6 天）';

  @override
  String get quizTrainingStyleChooseHowYouWant => '选择你想要的训练结构';

  @override
  String get quizTrainingStyleDoYouPreferThe => '你更喜欢每周进行相同的练习还是多样化的练习？';

  @override
  String get quizTrainingStyleExerciseVariety => '练习多样性';

  @override
  String get quizTrainingStyleFullBody => '全身训练';

  @override
  String get quizTrainingStyleLetAiDecide => '让 AI 决定';

  @override
  String get quizTrainingStyleOneMuscleGroupPer => '每天一个肌群（5 天以上）';

  @override
  String get quizTrainingStylePowerHypertrophyAdaptiveTra =>
      '力量与肥大自适应训练 (PHAT)（5 天）';

  @override
  String get quizTrainingStylePowerHypertrophyUpperL => '力量 + 肥大，上肢 + 下肢（4 天）';

  @override
  String get quizTrainingStylePushPullLegsPpl => '推/拉/腿 (PPL)';

  @override
  String get quizTrainingStylePushPullLegsUpper => '推/拉/腿/上肢/下肢（5 天）';

  @override
  String get quizTrainingStyleScheduleConflict => '日程冲突';

  @override
  String get quizTrainingStyleSplitBetweenUpperAnd => '上肢与下肢分化训练（4 天）';

  @override
  String get quizTrainingStyleTrainAllMusclesEach => '每次训练锻炼所有肌肉（2-4 天）';

  @override
  String get quizTrainingStyleTrainingSplit => '训练分化';

  @override
  String get quizTrainingStyleTrainingStyle => '训练风格';

  @override
  String get quizTrainingStyleUpperLower => '上肢 / 下肢';

  @override
  String get quizTrainingStyleWorkoutType => '训练类型';

  @override
  String racePredictorCardCouldNotLoadPredictions(Object message) {
    return '无法加载预测结果。\n$message';
  }

  @override
  String get racePredictorCardLogRun => '记录跑步';

  @override
  String get racePredictorCardRacePredictor => '比赛预测';

  @override
  String get racePredictorCardRunAMeasuredKm => '进行一两次测量距离的跑步以获取首次预测';

  @override
  String get racePredictorDetailAskCoach => '咨询教练';

  @override
  String get racePredictorDetailHowPredictionsAreCalculated => '预测是如何计算的';

  @override
  String get racePredictorDetailLogAtLeastThree =>
      '至少记录三次跑步（包括一次测量距离的公里数），即可显示预测结果。';

  @override
  String get racePredictorDetailNeedMoreData => '需要更多数据';

  @override
  String get racePredictorDetailNoPredictionsYet => '暂无预测';

  @override
  String get racePredictorDetailRacePredictor => '比赛预测';

  @override
  String racePredictorDetailScreenCouldNotLoadPredictions(Object e) {
    return '无法加载预测结果。\n$e';
  }

  @override
  String get racePredictorDetailYourBestRun => '你最好的跑步表现';

  @override
  String get ratingPromptBannerGot30Seconds => '有 30 秒时间吗？';

  @override
  String get ratingPromptBannerHelpUsOutRate =>
      '帮个忙，在 App Store 给 Zealova 评分吧。';

  @override
  String get ratingPromptDonTAskAgain => '不再询问';

  @override
  String get ratingPromptEnjoyingZealovaSoFar => '目前喜欢 Zealova 吗？';

  @override
  String get ratingPromptLovingIt => '非常喜欢';

  @override
  String get ratingPromptNotGreat => '不太好';

  @override
  String get ratingPromptRemindMeLater => '稍后提醒我';

  @override
  String get readinessCheckinCardEnergyFatigue => '能量/疲劳度';

  @override
  String get readinessCheckinCardGotIt => '知道了！';

  @override
  String get readinessCheckinCardHowAreYouFeeling => '今天感觉如何？';

  @override
  String get readinessCheckinCardMuscleSoreness => '肌肉酸痛';

  @override
  String get readinessCheckinCardQuickCheckInHelps => '快速签到有助于优化你的训练';

  @override
  String readinessCheckinCardReadiness(Object readinessScore) {
    return '准备状态：$readinessScore';
  }

  @override
  String get readinessCheckinCardSleepQuality => '睡眠质量';

  @override
  String get readinessCheckinCardStressLevel => '压力水平';

  @override
  String get readinessCheckinCardSubmitCheckIn => '提交签到';

  @override
  String get readinessCheckinCardSubmitting => '正在提交...';

  @override
  String get readinessCheckinCardTodaySReadiness => '今日准备状态';

  @override
  String get readinessTileBuildingBaselineCheckIn => '正在建立基准 — 请连续 14 天进行签到';

  @override
  String get readinessTileRecoveryReadiness => '恢复准备状态';

  @override
  String get receiptTemplate => '─────────────────────────────';

  @override
  String get receiptTemplateNoExercisesLogged => '未记录任何练习';

  @override
  String receiptTemplateOrder(Object workoutName) {
    return '订单：$workoutName';
  }

  @override
  String get receiptTemplateThankYouComeAgain => '谢谢惠顾 — 欢迎再次光临';

  @override
  String receiptTemplateX(Object reps, Object sets) {
    return '${sets}x$reps';
  }

  @override
  String get recipeBuilderAddIngredient => '添加配料';

  @override
  String get recipeBuilderCalculatePortionToLog => '计算要记录的份量';

  @override
  String get recipeBuilderConverter => '转换器';

  @override
  String get recipeBuilderCookTime => '烹饪时间';

  @override
  String get recipeBuilderDescriptionOptional => '描述（可选）';

  @override
  String get recipeBuilderEditRecipe => '编辑食谱';

  @override
  String get recipeBuilderIngredients => '配料';

  @override
  String get recipeBuilderInstructionsOptional => '说明（可选）';

  @override
  String get recipeBuilderNoIngredientsYet => '暂无配料';

  @override
  String get recipeBuilderNutritionPerServing => '每份营养成分';

  @override
  String get recipeBuilderPrepTime => '准备时间';

  @override
  String get recipeBuilderServings => '份数';

  @override
  String get recipeBuilderShareRecipe => '分享食谱';

  @override
  String get recipeBuilderSheetAddIngredient => '添加配料';

  @override
  String get recipeBuilderSheetAmount => '数量';

  @override
  String get recipeBuilderSheetAnalyzing => '正在分析...';

  @override
  String get recipeBuilderSheetCalories => '卡路里';

  @override
  String get recipeBuilderSheetCarbs => '碳水化合物';

  @override
  String get recipeBuilderSheetFat => '脂肪';

  @override
  String get recipeBuilderSheetFiber => '纤维';

  @override
  String recipeBuilderSheetG(Object inputGrams, Object result) {
    return '${inputGrams}g $result ';
  }

  @override
  String recipeBuilderSheetG2(Object foodName, Object outputGrams) {
    return '$foodName = ${outputGrams}g ';
  }

  @override
  String get recipeBuilderSheetIngredientName => '配料名称';

  @override
  String recipeBuilderSheetItems(Object length) {
    return '$length 项';
  }

  @override
  String recipeBuilderSheetKcal(Object caloriesConsumed) {
    return '$caloriesConsumed kcal';
  }

  @override
  String recipeBuilderSheetLoggedServingSOf(
    Object portionEaten,
    Object recipeName,
  ) {
    return '已记录 $portionEaten 份“$recipeName”：';
  }

  @override
  String get recipeBuilderSheetNutritionPerAmountAbove => '营养成分（按上述数量）';

  @override
  String recipeBuilderSheetPartIngredientEntryFailedToAnalyze(Object e) {
    return '分析失败: $e';
  }

  @override
  String recipeBuilderSheetPartIngredientEntryG(Object value) {
    return '${value}g';
  }

  @override
  String get recipeBuilderSheetProtein => '蛋白质';

  @override
  String recipeBuilderSheetRecipeCreated(Object text) {
    return '食谱“$text”已创建！';
  }

  @override
  String get recipeCardAi => 'AI';

  @override
  String get recipeCardCurated => '精选';

  @override
  String get recipeCardImported => '已导入';

  @override
  String get recipeCardImprovized => '即兴创作';

  @override
  String recipeCardKcal(Object caloriesPerServing) {
    return '$caloriesPerServing kcal';
  }

  @override
  String recipeCardValue(Object timesLogged) {
    return '×$timesLogged';
  }

  @override
  String get recipeCreateAddPhotoOptional => '添加照片（可选）';

  @override
  String get recipeCreateChooseFromGallery => '从相册选择';

  @override
  String get recipeCreateCustom => '+ 自定义';

  @override
  String get recipeCreateCustomCategory => '自定义类别';

  @override
  String get recipeCreateEG4Oz => '例如：4盎司烤鸡胸肉';

  @override
  String get recipeCreateEGPostWorkout => '例如：运动后、备餐、奶昔';

  @override
  String get recipeCreateEditCustom => '✏️ 编辑自定义';

  @override
  String get recipeCreateNewRecipe => '新建食谱';

  @override
  String get recipeCreateNone => '无';

  @override
  String get recipeCreatePerServing => '每份';

  @override
  String get recipeCreateRecipeNameRequired => '食谱名称必填';

  @override
  String get recipeCreateRemovePhoto => '移除照片';

  @override
  String get recipeCreateSaving => '保存中…';

  @override
  String recipeCreateScreenValue(Object brand, Object foodName) {
    return '(brand) \" : \"\")(foodName)';
  }

  @override
  String recipeCreateScreenValue2(Object selected) {
    return '✨ $selected';
  }

  @override
  String get recipeCreateTakePhoto => '拍照';

  @override
  String get recipeCreateTapToEdit => '点击编辑';

  @override
  String get recipeDetailAddToPlan => '添加到计划';

  @override
  String get recipeDetailAddedToFavorites => '已添加到收藏';

  @override
  String get recipeDetailCoachReview => '教练评估';

  @override
  String get recipeDetailDeleteRecipe => '删除食谱？';

  @override
  String get recipeDetailFavorite => '收藏';

  @override
  String get recipeDetailFavorited => '已收藏';

  @override
  String get recipeDetailGroceryList => '购物清单';

  @override
  String get recipeDetailImprovize => '即兴发挥';

  @override
  String get recipeDetailImprovizedEditAndSave => '已即兴修改！编辑并保存你的版本。';

  @override
  String get recipeDetailImprovizing => '正在即兴修改…';

  @override
  String get recipeDetailIngredients => '配料';

  @override
  String get recipeDetailInstructions => '步骤';

  @override
  String get recipeDetailLog => '记录';

  @override
  String get recipeDetailLogged1ServingAs => '已将1份记录为午餐';

  @override
  String get recipeDetailNoIngredients => '无配料';

  @override
  String get recipeDetailRecipeDeleted => '食谱已删除';

  @override
  String get recipeDetailRemovedFromFavorites => '已从收藏中移除';

  @override
  String get recipeDetailSchedule => '日程';

  @override
  String recipeDetailScreenGroceryListCreatedItems(Object length) {
    return '已创建购物清单 ($length 项)';
  }

  @override
  String recipeDetailScreenKcal(Object i) {
    return '$i kcal';
  }

  @override
  String recipeDetailScreenPerServingUD(Object servings) {
    return '每份 (×$servings 份)';
  }

  @override
  String recipeDetailScreenUForkedFrom(Object sourceName) {
    return '✨ 衍生自 $sourceName';
  }

  @override
  String recipeDetailScreenValue(Object brand, Object foodName) {
    return '(brand) \" : \"\")(foodName)';
  }

  @override
  String recipeDetailScreenWillBePermanentlyRemoved(Object name) {
    return '“$name” 将被永久删除。';
  }

  @override
  String get recipeDetailUd83cUdf1fCuratedRecipe => '🌟 精选食谱';

  @override
  String get recipeDetailView => '查看';

  @override
  String get recipeFilterSortApply => '应用';

  @override
  String get recipeFilterSortClearAll => '全部清除';

  @override
  String get recipeFilterSortFavoritesOnly => '⭐ 仅限收藏';

  @override
  String get recipeFilterSortFilters => '筛选';

  @override
  String get recipeFilterSortHasLeftoversOnly => '🍱 仅限有剩菜';

  @override
  String get recipeFilterSortMealType => '餐次类型';

  @override
  String get recipeFilterSortOther => '其他';

  @override
  String get recipeFilterSortSource => '来源';

  @override
  String get recipeFromFridgeAdd => '添加';

  @override
  String get recipeFromFridgeChooseFromGallery => '从相册选择';

  @override
  String get recipeFromFridgeFindRecipes => '查找食谱';

  @override
  String get recipeFromFridgeFindingRecipesU2026 => '正在查找食谱…';

  @override
  String get recipeFromFridgeFoundInYourPhoto => '在你的照片中找到';

  @override
  String get recipeFromFridgeFromYourFridge => '来自你的冰箱';

  @override
  String get recipeFromFridgeNoRecipesFoundFor => '未找到包含这些配料的食谱。尝试添加更多食材。';

  @override
  String get recipeFromFridgeScanComplete => '扫描完成';

  @override
  String recipeFromFridgeScreenKcalServ(Object caloriesPerServing) {
    return '$caloriesPerServing kcal/份';
  }

  @override
  String recipeFromFridgeScreenMatch(Object overallMatchScore) {
    return '匹配度 $overallMatchScore%';
  }

  @override
  String recipeFromFridgeScreenNeed(Object missingIngredients) {
    return '需要: $missingIngredients';
  }

  @override
  String recipeFromFridgeScreenScanningU(Object done, Object total) {
    return '正在扫描 $done/$total…';
  }

  @override
  String recipeFromFridgeScreenUGP(Object suggestion) {
    return '• ${suggestion}g 蛋白质';
  }

  @override
  String recipeFromFridgeScreenUses(Object matchedPantryItems) {
    return '使用: $matchedPantryItems';
  }

  @override
  String get recipeFromFridgeSnapFridgePhoto => '拍摄冰箱照片';

  @override
  String get recipeFromFridgeSuggestions => '建议';

  @override
  String get recipeFromFridgeTapFindRecipesTo => '点击“查找食谱”以获取使用这些配料的建议';

  @override
  String get recipeFromFridgeTypeIngredientEggsSpinach => '输入配料（鸡蛋、菠菜…）';

  @override
  String get recipeFromFridgeTypeIngredientsOrSnap => '输入配料或拍摄照片';

  @override
  String get recipeHistoryCompare => '对比';

  @override
  String get recipeHistoryNoDifferences => '无差异';

  @override
  String get recipeHistoryNoEditsYetVersioning => '暂无编辑记录 — 版本控制将在你首次修改后开始。';

  @override
  String get recipeHistoryNowPickASecond => '现在选择第二个版本';

  @override
  String get recipeHistoryRevert => '还原';

  @override
  String get recipeHistoryRevertToThisVersion => '还原到此版本？';

  @override
  String recipeHistoryScreenScheduleSNowUse(Object schedulesUsingRecipeCount) {
    return '$schedulesUsingRecipeCount 个计划现已使用还原版本';
  }

  @override
  String recipeHistoryScreenV(Object versionNumber) {
    return 'v$versionNumber';
  }

  @override
  String recipeHistoryScreenVV(Object fromVersion, Object toVersion) {
    return 'v$fromVersion → v$toVersion';
  }

  @override
  String recipeHistoryScreenValue(Object f, Object f1) {
    return '$f  →  $f1';
  }

  @override
  String get recipeHistoryUpdated => '已更新';

  @override
  String get recipeImportAimAtARecipe => '对准食谱卡片、烹饪书页面或截图。填满取景框，保持稳定。';

  @override
  String get recipeImportAlignRecipeInsideFrame => '将食谱对齐到取景框内';

  @override
  String get recipeImportChooseFromGalleryInstead => '改为从相册选择';

  @override
  String get recipeImportFailed => '失败';

  @override
  String get recipeImportImportFromUrl => '从URL导入';

  @override
  String get recipeImportImportRecipe => '导入食谱';

  @override
  String get recipeImportParseText => '解析文本';

  @override
  String get recipeImportPasteARecipeTitle => '粘贴食谱（标题、配料、步骤）…';

  @override
  String get recipeImportPhoto => '照片';

  @override
  String get recipeImportReviewSave => '检查并保存';

  @override
  String recipeImportScreenConfidence(Object confidence) {
    return '置信度: $confidence%';
  }

  @override
  String get recipeImportTapTheLargeWhite => '点击下方白色大圆圈进行拍摄';

  @override
  String get recipeImportText => '文本';

  @override
  String get recipePreferencesPreferencesSaved => '偏好已保存！';

  @override
  String get recipePreferencesRecipePreferences => '食谱偏好';

  @override
  String get recipePreferencesSelectCuisinesYouEnjoy => '选择你喜欢的菜系（点击切换）';

  @override
  String get recipePreferencesYourBodyTypeHelps => '你的体型有助于我们推荐针对你代谢优化的食谱';

  @override
  String recipeSaveJobsListenerCouldnTSaveRecipe(Object job) {
    return '无法保存食谱：$job';
  }

  @override
  String recipeSaveJobsListenerCouldnTSchedule(Object job, Object mealName) {
    return '无法安排 \'$mealName\'：$job';
  }

  @override
  String recipeSaveJobsListenerIsAlreadyInYour(Object mealName) {
    return '\'$mealName\' 已在你的食谱中';
  }

  @override
  String recipeSaveJobsListenerNextAt(Object cadenceLabel, Object fmt) {
    return '$cadenceLabel — 下次于 $fmt';
  }

  @override
  String recipeSaveJobsListenerSavedToYourRecipes(Object mealName) {
    return '已将 \'$mealName\' 保存到你的食谱';
  }

  @override
  String get recipeSaveJobsView => '查看';

  @override
  String get recipeScheduleAddASlotFor => '为你计划食用的每一份餐点添加一个时段';

  @override
  String get recipeScheduleAddSlot => '添加时段';

  @override
  String get recipeScheduleBatchCookOnce => '批量（烹饪一次）';

  @override
  String get recipeScheduleCounter1d => '台面 (1天)';

  @override
  String get recipeScheduleFreezer30d => '冷冻 (30天)';

  @override
  String get recipeScheduleFridge3d => '冷藏 (3天)';

  @override
  String get recipeScheduleRecurring => '重复';

  @override
  String get recipeScheduleSaving => '保存中…';

  @override
  String get recipeScheduleSchedule => '计划';

  @override
  String recipeScheduleScreenSlots(Object _batchSlots, Object _portionsMade) {
    return '份数：$_batchSlots / $_portionsMade';
  }

  @override
  String recipeScheduleScreenValue(Object servings) {
    return '×$servings';
  }

  @override
  String get recipeScheduleSilentAutoLogAdvanced => '静默自动记录 (高级)';

  @override
  String get recipeSearchBarRecentSearches => '最近搜索';

  @override
  String get recipeSearchBarSearchYourRecipesIngredien => '搜索食谱、配料、标签…';

  @override
  String get recipeShareCopiedToClipboard => '已复制到剪贴板';

  @override
  String get recipeShareGenerateShareLink => '生成分享链接';

  @override
  String get recipeShareRecipeIsPublic => '食谱已公开';

  @override
  String get recipeShareSharePublicly => '公开分享';

  @override
  String recipeShareSheetAnyoneWithTheLink(Object saveCount, Object viewCount) {
    return '拥有链接的任何人均可查看。已保存至库: $saveCount · 浏览量: $viewCount';
  }

  @override
  String get recipeShareStopSharing => '停止分享';

  @override
  String recipeSuggestionCardCal(Object calories) {
    return '$calories 卡路里';
  }

  @override
  String get recipeSuggestionCardCookAgain => '再次烹饪';

  @override
  String get recipeSuggestionCardIMadeThis => '我做过这个';

  @override
  String get recipeSuggestionCardIngredients => '配料';

  @override
  String get recipeSuggestionCardInstructions => '烹饪步骤';

  @override
  String get recipeSuggestionCardMatchAnalysis => '匹配分析';

  @override
  String get recipeSuggestionCardRateThisRecipe => '评价此食谱';

  @override
  String get recipeSuggestionCardSaveRecipe => '保存食谱';

  @override
  String get recipeSuggestionCardSaved => '已保存';

  @override
  String recipeSuggestionCardServings(Object servings) {
    return '$servings 份';
  }

  @override
  String recipeSuggestionCardValue(Object overallMatchScore) {
    return '$overallMatchScore%';
  }

  @override
  String recipeSuggestionCardValue2(Object score) {
    return '$score%';
  }

  @override
  String get recipeSuggestionsAnySpecificRequirementsE =>
      '有特殊要求吗？(例如：低于400卡路里，高纤维)';

  @override
  String get recipeSuggestionsGenerateSuggestions => '生成建议';

  @override
  String get recipeSuggestionsGenerating => '生成中...';

  @override
  String get recipeSuggestionsMarkedAsCooked => '已标记为已烹饪！';

  @override
  String get recipeSuggestionsNoSavedRecipes => '暂无已保存的食谱';

  @override
  String get recipeSuggestionsNoSuggestionsYet => '暂无建议';

  @override
  String get recipeSuggestionsRecipeSuggestions => '食谱建议';

  @override
  String get recipeSuggestionsSaveRecipesYouLike => '保存您喜欢的食谱，以便稍后在此查看';

  @override
  String get recipeSuggestionsSaved => '已保存';

  @override
  String recipeSuggestionsScreenRecipeSavedXpFirst(Object xpAwarded) {
    return '食谱已保存！+$xpAwarded XP首个食谱奖励！';
  }

  @override
  String get recipeSuggestionsSuggestions => '建议';

  @override
  String get recipeSuggestionsTapGenerateSuggestionsTo =>
      '点击“生成建议”，获取基于您偏好的AI食谱灵感';

  @override
  String get recipeSuggestionsWhatMealAreYou => '您打算吃哪一餐？';

  @override
  String get recipesBuild => '创建';

  @override
  String get recipesChooseFromGallery => '从相册选择';

  @override
  String get recipesComingUpToday => '今日安排';

  @override
  String get recipesCookedDish => '已烹饪菜肴';

  @override
  String get recipesDeleteRecipe => '删除食谱？';

  @override
  String get recipesExpired => '已过期';

  @override
  String get recipesFavorites => '收藏';

  @override
  String get recipesFavorites2 => '⭐ 收藏';

  @override
  String get recipesFilters => '筛选';

  @override
  String get recipesFridge => '冰箱';

  @override
  String get recipesHasLeftovers => '🍱 有剩菜';

  @override
  String get recipesImport => '导入';

  @override
  String get recipesLeftovers => '剩菜';

  @override
  String get recipesLists => '列表';

  @override
  String get recipesMultiSelectSupported => '支持多选';

  @override
  String get recipesNoRecipesYet => '暂无食谱';

  @override
  String get recipesOpen => '打开';

  @override
  String get recipesPlanDay => '计划全天';

  @override
  String get recipesRecipeDeleted => '食谱已删除';

  @override
  String get recipesScanYourFridge => '扫描您的冰箱';

  @override
  String get recipesScheduledMeal => '计划餐食';

  @override
  String get recipesSortRecipes => '排序食谱';

  @override
  String recipesTabAreYouSureYou(Object name) {
    return '确定要删除 \"$name\" 吗？此操作无法撤销。';
  }

  @override
  String recipesTabCouldnTLoadRecipes(Object message) {
    return '无法加载食谱: $message';
  }

  @override
  String recipesTabOfLeft(Object portionsMade, Object portionsRemaining) {
    return '剩余 $portionsRemaining / $portionsMade 份';
  }

  @override
  String recipesTabServing(Object servings) {
    return '$servings 份';
  }

  @override
  String recipesTabValue(Object timeLabel, Object value) {
    return '$timeLabel · $value';
  }

  @override
  String get recipesTakePhoto => '拍照';

  @override
  String get recipesTapBuildToCreate => '点击“创建”来制作您的第一个食谱，或尝试上方的冰箱/导入路径。';

  @override
  String get recipesUpTo5Photos => '最多5张照片 — 冰箱、储藏室、冷冻室';

  @override
  String get recommendationExplainGotIt => '知道了';

  @override
  String recommendationExplainSheetRankOf(Object rank, Object totalAccepted) {
    return '排名第 $rank，共 $totalAccepted 项';
  }

  @override
  String recommendationExplainSheetWhy(Object name) {
    return '为什么选择 $name？';
  }

  @override
  String get recordAssessmentAnyNotesAboutThis => '关于此评估的备注...';

  @override
  String get recordAssessmentEnterMeasurement => '输入测量值';

  @override
  String get recordAssessmentNotesOptional => '备注 (可选)';

  @override
  String get recordAssessmentQuickInstructions => '快速说明';

  @override
  String get recordAssessmentRecordAssessment => '记录评估';

  @override
  String recordAssessmentSheetTop(Object assessment) {
    return '前 $assessment%';
  }

  @override
  String get recordAssessmentTips => '提示';

  @override
  String get recordAssessmentU2022 => '• ';

  @override
  String get recordAssessmentYourMeasurement => '您的测量值';

  @override
  String get recordAttemptCurrentBest => '当前最佳';

  @override
  String recordAttemptDialogAdd(Object unit) {
    return '添加 $unit';
  }

  @override
  String recordAttemptDialogAdd2(Object unit) {
    return '添加 $unit';
  }

  @override
  String recordAttemptDialogCompleted(Object unit) {
    return '$unit 已完成';
  }

  @override
  String recordAttemptDialogToAdd(Object unit) {
    return '待添加 $unit';
  }

  @override
  String get recordAttemptHowDidItFeel => '感觉如何？';

  @override
  String get recordAttemptNotesOptional => '备注 (可选)';

  @override
  String get recordAttemptPersonalBest => '个人最佳';

  @override
  String get recordAttemptPleaseEnterAValid => '请输入有效的数字';

  @override
  String get recordAttemptRecordAttempt => '记录尝试';

  @override
  String get recordAttemptTotalSoFar => '目前总计';

  @override
  String get recordsCardBestPr => '最佳 PR';

  @override
  String get recordsCardPersonalRecords => '个人记录';

  @override
  String get recovery1rmCalculatorPlayground => '1RM 计算器演练场';

  @override
  String get recoveryColorCodedRed40 => '颜色编码：红色 <40% | 黄色 40-70% | 绿色 >70%';

  @override
  String get recoveryCompareEpleyBrzyckiAnd => '比较 Epley、Brzycki 和 Mayhew 估算值';

  @override
  String get recoveryLabel => '恢复';

  @override
  String get recoveryPerMuscleExponentialDecay => '各肌肉指数衰减率 (k值)';

  @override
  String get recoveryPerMuscleRecoveryGrid => '各肌肉恢复网格';

  @override
  String recoveryPillsRowValue(Object scorePct) {
    return '$scorePct%';
  }

  @override
  String get recoveryRecoveryConstantsEditor => '恢复常量编辑器';

  @override
  String get recoveryReps => '次数';

  @override
  String get recoveryReset => '重置';

  @override
  String recoverySectionKg(Object value) {
    return '$value kg';
  }

  @override
  String recoverySectionValue(Object score) {
    return '$score%';
  }

  @override
  String get recoveryWeightKg => '重量 (kg)';

  @override
  String get referralsAbc123 => 'ABC123';

  @override
  String get referralsAllRewardTiers => '所有奖励等级';

  @override
  String get referralsApplyCode => '使用邀请码';

  @override
  String get referralsApplying => '正在应用…';

  @override
  String get referralsCodeCopied => '邀请码已复制！';

  @override
  String get referralsFailedToLoadReferrals => '无法加载邀请信息';

  @override
  String get referralsHaveACodeFrom => '有朋友的邀请码吗？';

  @override
  String get referralsHowItWorks => '如何运作';

  @override
  String get referralsInviteFriends => '邀请好友';

  @override
  String get referralsMaxTierReached => '已达最高等级';

  @override
  String get referralsPending => '待处理';

  @override
  String get referralsQualified => '已达标';

  @override
  String get referralsRedeemItHereBoth => '在此兑换 — 你们双方都将获得 XP 和一个宝箱。';

  @override
  String referralsScreenMoreQualifiedReferral(Object neededForNext) {
    return '还需要 $neededForNext 个有效推荐';
  }

  @override
  String referralsScreenNextFree(Object nextMerchDisplayName) {
    return '下一个: 免费 $nextMerchDisplayName';
  }

  @override
  String referralsScreenQualifiedReferrals(Object threshold) {
    return '$threshold 个有效推荐';
  }

  @override
  String referralsScreenToUnlock(Object summary) {
    return '$summary 以解锁';
  }

  @override
  String get referralsYouVeUnlockedEvery => '你已解锁所有邀请奖励。传奇。';

  @override
  String get referralsYourReferralCode => '你的邀请码';

  @override
  String get refuelWindowCardAskCoachAboutRecovery => '向教练咨询恢复期补给';

  @override
  String get refuelWindowCardCarbs => '碳水化合物';

  @override
  String get refuelWindowCardLogMeal => '记录饮食';

  @override
  String get refuelWindowCardProtein => '蛋白质';

  @override
  String get refuelWindowCardRecoveryWindow => '🥤 恢复窗口';

  @override
  String get refuelWindowCardWater => '水分';

  @override
  String get regenerateSheetAddingVariety => '增加多样性';

  @override
  String get regenerateSheetAiGenerationTakes => 'AI 生成通常需要 15–30 秒';

  @override
  String get regenerateSheetAiSuggestions => 'AI 建议';

  @override
  String get regenerateSheetAlmostThere => '即将完成…';

  @override
  String get regenerateSheetAnalyzingYourPreferences => '正在分析您的偏好…';

  @override
  String get regenerateSheetApply => '应用';

  @override
  String get regenerateSheetApplyThisWorkout => '应用此训练';

  @override
  String get regenerateSheetBalancingMuscleGroups => '平衡肌肉群';

  @override
  String get regenerateSheetBootingUpTheAi => '正在启动 AI';

  @override
  String get regenerateSheetBuildingYourPlan => '正在构建您的计划';

  @override
  String get regenerateSheetBuildingYourWorkout => '正在构建您的训练…';

  @override
  String get regenerateSheetCheckingEquipment => '正在检查器械';

  @override
  String get regenerateSheetCheckingPreferences => '正在检查偏好设置';

  @override
  String get regenerateSheetConnectingToTheAi => '正在连接 AI';

  @override
  String get regenerateSheetConsideringFocusAreas => '正在考虑重点区域';

  @override
  String get regenerateSheetCustomize => '自定义';

  @override
  String get regenerateSheetCustomizeOrLetAi => '自定义或让 AI 提供建议';

  @override
  String get regenerateSheetCustomizeOrLetAiSuggest => '自定义或让 AI 建议';

  @override
  String get regenerateSheetDescribeYourIdealWorkout => '描述您理想的训练';

  @override
  String get regenerateSheetDesigningYourWorkout => '正在设计您的训练';

  @override
  String get regenerateSheetDialingInSetsAndReps => '正在调整组数和次数';

  @override
  String get regenerateSheetDoThisToday => '今天完成此训练';

  @override
  String get regenerateSheetEnterAPrompt => '输入提示词';

  @override
  String get regenerateSheetEnterAPromptAbove => '在上方输入提示词…';

  @override
  String get regenerateSheetFilteringByEquipment => '正在按器械筛选';

  @override
  String get regenerateSheetFilteringByYourEquipment => '正在按您的器械筛选';

  @override
  String get regenerateSheetFinalizingDetails => '正在确定最终细节…';

  @override
  String get regenerateSheetFinalizingYourWorkout => '正在完成您的训练';

  @override
  String get regenerateSheetFineTuningTheDetails => '正在微调细节';

  @override
  String regenerateSheetGeneratingElapsed(Object arg0) {
    return '生成耗时 $arg0';
  }

  @override
  String get regenerateSheetGeneratingSuggestions => '正在生成建议…';

  @override
  String get regenerateSheetGetSuggestions => '获取建议';

  @override
  String get regenerateSheetGettingCreative => '正在发挥创意';

  @override
  String get regenerateSheetGettingReady => '准备中';

  @override
  String get regenerateSheetHoldingYourSchedule => '保持您的日程安排';

  @override
  String get regenerateSheetKeepCurrent => '保持当前';

  @override
  String regenerateSheetKeepDate(Object day, Object month, Object weekday) {
    return '保留 $weekday, $month $day';
  }

  @override
  String get regenerateSheetLoadingInjuriesAndGoals => '伤病与目标';

  @override
  String get regenerateSheetLoadingPreferences => '偏好设置';

  @override
  String get regenerateSheetLoadingYourProfile => '您的个人资料';

  @override
  String get regenerateSheetMatchingIntensity => '匹配强度';

  @override
  String get regenerateSheetMatchingYourFitnessLevel => '匹配您的健身水平';

  @override
  String get regenerateSheetNoSuggestionsYet => '暂无建议';

  @override
  String get regenerateSheetOptimizingForYourGoals => '正在针对您的目标进行优化';

  @override
  String get regenerateSheetPairingPushAndPull => '配对推与拉动作';

  @override
  String get regenerateSheetPersonalizingExercises => '正在个性化动作';

  @override
  String get regenerateSheetPickingYourExercises => '正在选择您的动作';

  @override
  String get regenerateSheetPreparingYourRequest => '正在准备您的请求';

  @override
  String get regenerateSheetPrimingTheEngine => '正在启动引擎';

  @override
  String get regenerateSheetPullingYourGoals => '正在获取您的目标';

  @override
  String get regenerateSheetReadingYourProfile => '正在读取您的个人资料';

  @override
  String get regenerateSheetRegenerateCurrentWorkout => '重新生成当前训练';

  @override
  String get regenerateSheetRegenerateWorkout => '重新生成训练';

  @override
  String get regenerateSheetRegenerationComplete => '重新生成完成！';

  @override
  String get regenerateSheetReset => '重置';

  @override
  String get regenerateSheetRespectingYourInjuryList => '正在考虑您的伤病列表';

  @override
  String get regenerateSheetRestoredFromLastRegen => '已从上次生成恢复';

  @override
  String get regenerateSheetRestoredFromLastRegeneration => '已从上次重新生成中恢复';

  @override
  String get regenerateSheetSavingToYourPlan => '正在保存到您的计划';

  @override
  String get regenerateSheetScanningTheExerciseLibrary => '正在扫描动作库';

  @override
  String get regenerateSheetSchedulingYourWorkout => '正在安排您的训练';

  @override
  String get regenerateSheetSequencingCompoundLifts => '正在排列复合动作顺序';

  @override
  String get regenerateSheetShapingTheSession => '正在塑造训练环节';

  @override
  String get regenerateSheetStartingRegeneration => '正在开始重新生成…';

  @override
  String regenerateSheetStepOf(Object current, Object total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get regenerateSheetTodayNotInSchedule => '今天不在您的常规训练计划中';

  @override
  String get regenerateSheetTodayNotInUsualDays => '今天不在常规训练日内';

  @override
  String get regenerateSheetTuningRestPeriods => '正在调整休息时间';

  @override
  String get regenerateSheetUpdatingYourSchedule => '正在更新您的日程';

  @override
  String get regenerateSheetUseThisSuggestion => '使用此建议';

  @override
  String get regenerateSheetWarmingUp => '正在热身';

  @override
  String get regenerateSheetWhen => '何时进行？';

  @override
  String get regenerateWithNewContinueCurrent => '继续当前';

  @override
  String get regenerateWithNewEitherWayFutureWorkouts =>
      '无论如何，未来的训练都将使用你更新后的设备。';

  @override
  String get regenerateWithNewEquipmentUpdated => '设备已更新';

  @override
  String get regenerateWithNewRegenerateThisWorkout => '重新生成此训练';

  @override
  String get regenerateWorkoutSheetAiGenerationTypicallyTakes =>
      'AI 生成通常需要 15-30 秒';

  @override
  String get regenerateWorkoutSheetAiSuggestions => 'AI 建议';

  @override
  String get regenerateWorkoutSheetApplyThisWorkout => '应用此训练';

  @override
  String get regenerateWorkoutSheetCouldnTKeepYour => '无法保留你原本的训练 — 仅显示新的训练。';

  @override
  String get regenerateWorkoutSheetCustomize => '自定义';

  @override
  String get regenerateWorkoutSheetCustomizeOrLetAi => '自定义或让 AI 提供建议';

  @override
  String get regenerateWorkoutSheetDefaultedToReplaceYour =>
      '已默认替换 — 你之前的训练已被覆盖。';

  @override
  String get regenerateWorkoutSheetDescribeYourIdealWorkout => '描述你理想的训练';

  @override
  String get regenerateWorkoutSheetDoThisToday => '今天进行此训练';

  @override
  String get regenerateWorkoutSheetEGAQuick => '例如：“无需器械的快速上肢训练”';

  @override
  String get regenerateWorkoutSheetEnterAPromptAbove =>
      '在上方输入提示词或点击刷新以获取 AI 驱动的训练建议';

  @override
  String get regenerateWorkoutSheetGeneratingSuggestions => '正在生成建议...';

  @override
  String get regenerateWorkoutSheetGetSuggestions => '获取建议';

  @override
  String get regenerateWorkoutSheetNoSuggestionsYet => '暂无建议';

  @override
  String
  regenerateWorkoutSheetPartRegenerateWorkoutSheetStateExtFailedToApplySuggestion(
    Object message,
  ) {
    return '应用建议失败：$message';
  }

  @override
  String
  regenerateWorkoutSheetPartRegenerateWorkoutSheetStateExtFailedToApplySuggestion2(
    Object e,
  ) {
    return '应用建议失败：$e';
  }

  @override
  String
  regenerateWorkoutSheetPartRegenerateWorkoutSheetStateExtFailedToRegenerate(
    Object message,
  ) {
    return '重新生成失败：$message';
  }

  @override
  String
  regenerateWorkoutSheetPartRegenerateWorkoutSheetStateExtFailedToRegenerate2(
    Object e,
  ) {
    return '重新生成失败：$e';
  }

  @override
  String get regenerateWorkoutSheetPreviewNotSupportedBy =>
      '服务器不支持预览。请更新应用或联系支持团队。';

  @override
  String get regenerateWorkoutSheetRegenerateCurrentWorkout => '重新生成当前训练';

  @override
  String get regenerateWorkoutSheetRegenerateWorkout => '重新生成训练';

  @override
  String get regenerateWorkoutSheetReset => '重置';

  @override
  String get regenerateWorkoutSheetRestoredFromYourLast => '已从你上次的重新生成中恢复';

  @override
  String get regenerateWorkoutSheetTodayIsnTIn => '今天不在你平时的训练计划中 — 我们仍会将其添加。';

  @override
  String get regenerateWorkoutSheetWhen => '何时？';

  @override
  String get regionVariantDropdownCouldNotSwapVariant => '无法切换变体。请重试。';

  @override
  String regionVariantDropdownKcalG(Object v) {
    return '$v kcal/100g';
  }

  @override
  String get regionVariantDropdownRegion => '地区';

  @override
  String get renewalReminderBannerDismiss => '忽略';

  @override
  String get renewalReminderBannerManage => '管理';

  @override
  String renewalReminderBannerRenewsOn(Object formattedRenewalDate) {
    return '$formattedRenewalDate 续订';
  }

  @override
  String get repPreferencesAvoidHighRepSets => '避免高次数训练组';

  @override
  String get repPreferencesChooseYourPrimaryTraining => '选择你的主要训练目标';

  @override
  String get repPreferencesConfigureYourSetVolume => '配置你的训练组容量';

  @override
  String get repPreferencesEnforceRepCeiling => '强制执行次数上限';

  @override
  String get repPreferencesHowShouldWeProgress => '我们该如何推进你的练习？';

  @override
  String get repPreferencesPreventBoring15Rep => '避免枯燥的 15 次以上训练组';

  @override
  String get repPreferencesProgressionStyle => '进阶风格';

  @override
  String get repPreferencesRepProgressionPreferences => '次数与进阶偏好';

  @override
  String get repPreferencesRepRange => '次数范围';

  @override
  String get repPreferencesSectionConfigureYourSetVolume => '为每个练习配置训练组容量';

  @override
  String get repPreferencesSectionEndurance1520 => '耐力 (15-20)';

  @override
  String get repPreferencesSectionHighVolume36 => '高容量 (3-6)';

  @override
  String get repPreferencesSectionHypertrophy812 => '肌肥大 (8-12)';

  @override
  String get repPreferencesSectionMax => '最大';

  @override
  String get repPreferencesSectionMaxSets => '最大组数';

  @override
  String get repPreferencesSectionMaximumNumberOfSets => '每个练习的最大组数';

  @override
  String get repPreferencesSectionMin => '最小';

  @override
  String get repPreferencesSectionMinSets => '最少组数';

  @override
  String get repPreferencesSectionMinimal12 => '极简 (1-2)';

  @override
  String get repPreferencesSectionMinimumSetsToEnsure => '确保足够容量的最少组数';

  @override
  String repPreferencesSectionPartTrainingFocusOptionTileMaximumSets(
    Object maxSets,
  ) {
    return '最多组数：$maxSets';
  }

  @override
  String repPreferencesSectionPartTrainingFocusOptionTileMinimumSets(
    Object minSets,
  ) {
    return '最少组数：$minSets';
  }

  @override
  String get repPreferencesSectionRecommended => '推荐';

  @override
  String get repPreferencesSectionRepRangePreference => '次数范围偏好';

  @override
  String get repPreferencesSectionSetYourPreferredReps => '设置你每组的首选次数';

  @override
  String get repPreferencesSectionSetsPerExercise => '每个练习的组数';

  @override
  String get repPreferencesSectionStandard24 => '标准 (2-4)';

  @override
  String get repPreferencesSectionStrength15 => '力量 (1-5)';

  @override
  String get repPreferencesSectionTheAiWillGenerate =>
      'AI 将根据此次数范围生成训练计划。组数越多 = 训练量越大 = 肌肉刺激越强。';

  @override
  String get repPreferencesSectionTheAiWillTry =>
      'AI 将通过调整重量或建议进阶动作，尽量将练习保持在此范围内。';

  @override
  String get repPreferencesSetsPerExercise => '每项练习组数';

  @override
  String get repPreferencesStrictlyEnforceYourMaximum => '严格执行最大次数限制';

  @override
  String get repPreferencesTrainingFocus => '训练重点';

  @override
  String get repPreferencesYourPreferredRepsPer => '您偏好的每组次数';

  @override
  String get repProgressionCardFineTuneRepRanges => '微调次数范围和进阶方式';

  @override
  String get repProgressionCardRepProgression => '次数与进阶';

  @override
  String repProgressionCardReps(
    Object preferredMaxReps,
    Object preferredMinReps,
  ) {
    return '$preferredMinReps-$preferredMaxReps 次';
  }

  @override
  String get reportInjuryAdditionalNotesOptional => '附加说明（可选）';

  @override
  String get reportInjuryCurrentPainLevel => '目前的疼痛程度';

  @override
  String get reportInjuryDescribeHowTheInjury => '描述受伤是如何发生的、症状等。';

  @override
  String get reportInjuryInjuryReportedSuccessfully => '伤病报告已成功提交';

  @override
  String get reportInjuryInjuryTypeOptional => '伤害类型（可选）';

  @override
  String get reportInjuryNoPain => '无疼痛';

  @override
  String get reportInjuryNotSure => '不确定';

  @override
  String get reportInjuryPleaseSelectABody => '请选择身体部位';

  @override
  String get reportInjuryReportInjury => '报告受伤情况';

  @override
  String reportInjuryScreenFailedToReportInjury(Object e) {
    return '报告伤情失败：$e';
  }

  @override
  String get reportInjurySelectInjuryType => '选择伤病类型';

  @override
  String get reportInjurySeverity => '严重性';

  @override
  String get reportInjuryThisIsForTracking =>
      '这仅用于跟踪目的。请咨询医疗保健专业人士以进行正确的诊断和治疗。';

  @override
  String get reportInjuryWhenDidItOccur => '什么时候发生的？';

  @override
  String get reportMessageAdditionalDetailsOptional => '其他详细信息（可选）';

  @override
  String get reportMessageHelpUsImproveOur => '帮助我们改进 AI 教练';

  @override
  String get reportMessageReportSubmittedThankYou => '报告已提交。感谢您的反馈！';

  @override
  String get reportMessageReportThisResponse => '举报此回复';

  @override
  String reportMessageSheetFailedToSubmitReport(Object e) {
    return '提交报告失败: $e';
  }

  @override
  String get reportMessageSubmitReport => '提交报告';

  @override
  String get reportMessageTellUsMoreAbout => '告诉我们有关该问题的更多信息...';

  @override
  String get reportMessageWhatSWrongWith => '这个回应有什么问题吗？';

  @override
  String get reportNewspaperTemplateExclusiveReport => '独家报告';

  @override
  String get reportNewspaperTemplateNo01 => '没有。 01';

  @override
  String get reportNewspaperTemplateTheZealovaTimes => '热忱时代';

  @override
  String reportNewspaperTemplateValue(Object title) {
    return '— $title';
  }

  @override
  String get reportPainCouldNotSavePlease => '无法保存 - 请重试。';

  @override
  String get reportPainPainOnThisExercise => '这个练习疼吗？';

  @override
  String get reportPainSkipAvoid => '跳过并避免';

  @override
  String get reportPainSkipThisExercise => '跳过此练习';

  @override
  String get reportReceiptTemplateCustomer => '客户';

  @override
  String get reportReceiptTemplateReport => '报告';

  @override
  String reportReceiptTemplateReportReceipt(Object periodLabel) {
    return '报告回执 · $periodLabel';
  }

  @override
  String reportReceiptTemplateTotal(Object unit) {
    return '总计 $unit';
  }

  @override
  String get reportReceiptTemplateZealovaGym => '热洛瓦健身房';

  @override
  String get reportShareCopyLink => '复制链接';

  @override
  String get reportShareInstagram => 'Instagram';

  @override
  String reportShareSheetShare(Object title) {
    return '分享 $title';
  }

  @override
  String get reportShareShowWatermark => '显示水印';

  @override
  String get reportStrainAiWillSuggestLighter => 'AI 将建议更轻松的训练';

  @override
  String get reportStrainReportStrain => '报告应变';

  @override
  String get reportStrainRequestRestDay => '请求休息日';

  @override
  String get reportStrainSelectAtLeastOne => '请至少选择一个肌肉群';

  @override
  String get reportStrainStrainReportSubmitted => '劳损报告已提交';

  @override
  String get reportStrainSubmitReport => '提交报告';

  @override
  String get reportWrappedTemplateLifter => '升降机';

  @override
  String get reportWrappedTemplateWrapped => '包裹的';

  @override
  String get reportsHub1RepMaxes => '1RM';

  @override
  String get reportsHubBadgesUnlockedAlongYour => '旅途中解锁的徽章';

  @override
  String get reportsHubBodyMeasurements => '身体测量数据';

  @override
  String get reportsHubBodyRecovery => '身体与恢复';

  @override
  String reportsHubCouldntBuildShare(Object error) {
    return '无法生成分享内容 — $error';
  }

  @override
  String get reportsHubDetail => '详情';

  @override
  String get reportsHubEstimated1rmsForEvery => '每个主要动作的预估 1RM';

  @override
  String get reportsHubEveryLiftPrYou => '您达成的每个动作 PR，按排名显示';

  @override
  String get reportsHubExerciseHistory => '练习历史';

  @override
  String get reportsHubLifestyle => '生活方式';

  @override
  String get reportsHubMacrosCaloriesAdherence => '宏量营养素、卡路里、依从性';

  @override
  String get reportsHubMilestones => '里程碑';

  @override
  String get reportsHubMuscleStrength => '肌肉力量';

  @override
  String reportsHubNoDataForMonth(Object month, Object reportName) {
    return '$month 暂无 $reportName 数据 — 请尝试其他月份';
  }

  @override
  String get reportsHubNotEnoughDataYet => '数据不足，请在下次训练后再试';

  @override
  String get reportsHubPeriodInsights => '周期洞察';

  @override
  String get reportsHubPersonalRecords => '个人纪录';

  @override
  String get reportsHubProgressCharts => '进度图表';

  @override
  String get reportsHubProgressionCurveForEvery => '您完成的每个练习的进阶曲线';

  @override
  String get reportsHubReadinessRecovery => '准备状态与恢复';

  @override
  String get reportsHubReportsInsights => '报告与洞察';

  @override
  String get reportsHubScorePerMuscleGroup => '各肌肉群得分、趋势及热力图';

  @override
  String reportsHubScreenEverythingYouVeEarned(Object appName) {
    return '您在 $appName 中获得的一切';
  }

  @override
  String get reportsHubSleepFatigueStressReadin => '睡眠、疲劳、压力、准备状态评分';

  @override
  String get reportsHubTraining => '训练';

  @override
  String get reportsHubViewReport => '查看报告';

  @override
  String get reportsHubVolumeStrengthAndConsiste => '随时间变化的训练量、力量和一致性';

  @override
  String get reportsHubWeightBodyFatCircumferenc => '体重、体脂、围度趋势';

  @override
  String get reportsHubWorkoutsTimeCaloriesBy =>
      '按 1周 / 1月 / 3月 / 6月 / 1年 / 年初至今 / 自定义查看训练、时长、卡路里';

  @override
  String get requestRefundAdditionalCommentsOptional => '其他评论（可选）';

  @override
  String get requestRefundCheckYourEmail => '请检查您的电子邮件';

  @override
  String get requestRefundOneTime => '一次性';

  @override
  String get requestRefundOneTime2 => '一次性';

  @override
  String get requestRefundPleaseSelectTheReason => '请选择最能描述您情况的原因';

  @override
  String get requestRefundReasonForRefund => '退款原因';

  @override
  String get requestRefundRefundPolicy => '退款政策';

  @override
  String get requestRefundRefundRequestSubmitted => '退款请求已提交';

  @override
  String get requestRefundRefundRequestsAreTypically =>
      '退款请求通常在 5-7 个工作日内处理。请求审核通过后，您将收到电子邮件确认。';

  @override
  String get requestRefundRequestId => '请求 ID';

  @override
  String get requestRefundRequestRefund => '申请退款';

  @override
  String get requestRefundSaveThisIdFor => '请保存此 ID 以备查询';

  @override
  String requestRefundScreenPer(Object _billingPeriod) {
    return '每 $_billingPeriod';
  }

  @override
  String requestRefundScreenWeHaveReceivedYour(Object planName) {
    return '我们已收到你对 $planName 的退款申请';
  }

  @override
  String get requestRefundSubmitRefundRequest => '提交退款请求';

  @override
  String get requestRefundSubscriptionBeingRefunded => '正在退款的订阅';

  @override
  String get requestRefundTellUsMoreAbout => '告诉我们更多关于您的体验...';

  @override
  String get requestRefundWeWillSendYou =>
      '我们将向您发送一封包含退款请求详情的电子邮件确认。处理通常需要 5-7 个工作日。';

  @override
  String get rescheduleFailedToLoadSuggestions => '无法加载建议';

  @override
  String get rescheduleFailedToRescheduleWorkout => '无法重新安排训练';

  @override
  String get reschedulePickADifferentDay => '选择不同的日期';

  @override
  String get rescheduleRescheduleWorkout => '重新安排训练';

  @override
  String rescheduleSheetSwapsWith(Object swapWorkoutName) {
    return '与 $swapWorkoutName 交换';
  }

  @override
  String get rescheduleWorkoutSwappedSuccessfully => '训练已成功调换';

  @override
  String get restRateLastSet => '评价上一组';

  @override
  String get restRateLastSetOptional => '可选';

  @override
  String get restSuggestionAiRestCoach => 'AI 休息教练';

  @override
  String get restSuggestionCalculatingOptimalRestTime => '正在计算最佳休息时间';

  @override
  String get restSuggestionCardAiRestCoach => 'AI 休息教练';

  @override
  String get restSuggestionCardCalculatingOptimalRestTime => '正在计算最佳休息时间...';

  @override
  String get restSuggestionCardQuickRest => '快速休息';

  @override
  String get restSuggestionCardSuggested => '建议';

  @override
  String get restSuggestionCardUseSuggested => '使用建议';

  @override
  String get restSuggestionQuick => '快速';

  @override
  String get restSuggestionQuickRest => '快速休息';

  @override
  String restSuggestionSaveTime(Object arg0) {
    return '节省时间 $arg0';
  }

  @override
  String get restSuggestionSuggested => '建议';

  @override
  String get restSuggestionUseSuggested => '使用建议值';

  @override
  String get restTimerCardBaseRest => '基础休息';

  @override
  String get restTimerCardControlRestPeriodsBetween => '控制组间休息时间';

  @override
  String get restTimerCardCustomRestTimer => '自定义休息计时器';

  @override
  String get restTimerCardFormula => '公式';

  @override
  String get restTimerCardFormulaBaserestRpe7 =>
      '公式: BaseRest * (RPE / 7) * Multiplier';

  @override
  String get restTimerCardLivePreview => '实时预览';

  @override
  String get restTimerCardMultiplier => '乘数';

  @override
  String get restTimerCardRestBaserestRpe7 => '休息 = BaseRest * (RPE / 7)';

  @override
  String restTimerCardS(Object value) {
    return '$value 秒';
  }

  @override
  String restTimerCardS2(Object restTimerBaseRest) {
    return '$restTimerBaseRest 秒';
  }

  @override
  String restTimerCardS3(Object s) {
    return '$s 秒';
  }

  @override
  String get restTimerCardVariablesBaseRpeMultipli =>
      '变量: base, rpe, multiplier, tier';

  @override
  String restTimerCardX(Object restTimerMultiplier) {
    return '$restTimerMultiplier 倍';
  }

  @override
  String get restTimerOverlayAiWeightCoach => 'AI 重量教练';

  @override
  String get restTimerOverlayAnalyzingYourPerformance => '正在分析您的表现...';

  @override
  String restTimerOverlayAsk(Object coachName) {
    return '询问 $coachName';
  }

  @override
  String get restTimerOverlayCoachReview => '教练评估';

  @override
  String get restTimerOverlayGetTipsForYour => '获取下一组动作的建议';

  @override
  String get restTimerOverlayGotIt => '知道了';

  @override
  String get restTimerOverlayLog1rm => '记录 1RM';

  @override
  String get restTimerOverlayNextSet => '下一组';

  @override
  String get restTimerOverlayNextUp => '接下来';

  @override
  String get restTimerOverlayRateLastSet => '评价上一组';

  @override
  String get restTimerOverlayRirRepsInReserve => 'RIR (预留次数)';

  @override
  String get restTimerOverlayRpeRateOfPerceived => 'RPE (主观疲劳程度)';

  @override
  String restTimerOverlayS(Object restSecondsRemaining) {
    return '$restSecondsRemaining 秒';
  }

  @override
  String get restTimerOverlaySkipRest => '跳过休息';

  @override
  String get restTimerOverlayTrackYourMax => '追踪您的最大重量';

  @override
  String restTimerOverlayUiKg(Object currentExercise) {
    return '$currentExercise kg';
  }

  @override
  String restTimerOverlayUiKg2(Object suggestedWeight) {
    return '$suggestedWeight kg';
  }

  @override
  String restTimerOverlayUiReps(Object reps) {
    return '$reps 次';
  }

  @override
  String restTimerOverlayUiUseKg(Object suggestedWeight) {
    return '使用 $suggestedWeight kg';
  }

  @override
  String get restTimerRest => '休息';

  @override
  String get restTimerSkipRest => '跳过休息';

  @override
  String get retro80sTemplateCalories => '卡路里';

  @override
  String get retro80sTemplateVolume => '训练总量';

  @override
  String get retuneProposalApplyChanges => '应用更改';

  @override
  String get retuneProposalApplying => '正在应用...';

  @override
  String get retuneProposalDismiss => '忽略';

  @override
  String get retuneProposalDismissing => '正在忽略...';

  @override
  String get retuneProposalMuscleFocusShifts => '肌肉侧重调整:';

  @override
  String get retuneProposalPreviewNextWeek => '预览下周计划';

  @override
  String get retuneProposalPreviewUnavailable => '无法预览。';

  @override
  String get retuneProposalProgramRetunedNextPlan => '计划已重新调整。下个计划将反映这些更改。';

  @override
  String get retuneProposalRetuneProposal => '调整建议';

  @override
  String retuneProposalSheetValue(Object after, Object before) {
    return '$before  →  $after';
  }

  @override
  String get rewardsAvailable => '可用';

  @override
  String get rewardsClaim => '领取';

  @override
  String get rewardsClaimed => '已领取';

  @override
  String get rewardsConfirm => '确认';

  @override
  String get rewardsKeepLevelingUpTo => '继续升级以解锁奖励！';

  @override
  String get rewardsNoRewardsAvailableYet => '暂无可用奖励';

  @override
  String get rewardsRewards => '奖励';

  @override
  String rewardsScreenTotalXp(Object totalXp) {
    return '总计 $totalXp XP';
  }

  @override
  String get rewardsYourEmailExampleCom => 'your.email@example.com';

  @override
  String get ringCatalogCycleDay => '周期天数';

  @override
  String get ringCatalogHeartRate => '心率';

  @override
  String get ringCatalogHydration => '保湿';

  @override
  String get ringCatalogMove => '移动';

  @override
  String get ringCatalogNourish => '滋养';

  @override
  String get ringCatalogSleep => '睡眠';

  @override
  String get ringCatalogStress => '压力';

  @override
  String get ringCatalogTrain => '火车';

  @override
  String get ringCatalogWeight => '重量';

  @override
  String get ringLabelCycleDay => '周期日';

  @override
  String get ringLabelHeartRate => '心率';

  @override
  String get ringLabelHrv => 'HRV';

  @override
  String get ringLabelHydration => '水分';

  @override
  String get ringLabelMove => '活动';

  @override
  String get ringLabelNourish => '营养';

  @override
  String get ringLabelRecovery => '恢复';

  @override
  String get ringLabelSleep => '睡眠';

  @override
  String get ringLabelStress => '压力';

  @override
  String get ringLabelTrain => '训练';

  @override
  String get ringLabelWeight => '体重';

  @override
  String get roiSummaryCardCalories => '卡路里';

  @override
  String get roiSummaryCardCompleteYourFirstWorkout => '完成您的第一次训练以开始追踪进度！';

  @override
  String get roiSummaryCardInvested => '已投入';

  @override
  String get roiSummaryCardLoadingYourProgress => '正在加载您的进度...';

  @override
  String get roiSummaryCardStartYourJourney => '开启您的旅程';

  @override
  String roiSummaryCardYouReSinceYou(Object strengthIncreaseText) {
    return '自开始以来，你已 $strengthIncreaseText！';
  }

  @override
  String get routeMapOpenstreetmapContributors => '© OpenStreetMap 贡献者';

  @override
  String get rpeCardAutomaticallyAdjustBasedOn => '根据 RPE 反馈自动调整';

  @override
  String get rpeCardRpeAutoRegulation => 'RPE 自动调节';

  @override
  String get rpeCardRpePromptFrequency => 'RPE 提示频率';

  @override
  String get rpeCardSensitivity => '灵敏度';

  @override
  String get rpeEasy => '轻松';

  @override
  String get rpeFailure => '力竭';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get rpeLight => '很轻';

  @override
  String get rpeOneRepLeft => '还剩1次';

  @override
  String get rpePillRpeRateOfPerceived => 'RPE — 主观疲劳程度';

  @override
  String get rpeRirHelpsAdjustNextSet => '有助于调整下一组';

  @override
  String get rpeRirHowHardWasThatSet => '这一组感觉如何';

  @override
  String get rpeRirRateOfPerceivedExertion => '主观体力感觉量表 (RPE)';

  @override
  String get rpeRirRepsInReserve => '预留次数 (RIR)';

  @override
  String get rpeRirRir => 'RIR';

  @override
  String get rpeRirRpe => 'RPE';

  @override
  String get rpeTwoRepsLeft => '还剩2次';

  @override
  String get rtpAdvancePhase => '我已达到里程碑';

  @override
  String get rtpDisclaimer => '自助框架。进入下一阶段前需获得医疗服务提供者的许可。';

  @override
  String get rtpGraduated => '已完成';

  @override
  String get rtpTitle => '重返训练';

  @override
  String get safetyDisclaimerBannerDismissDisclaimer => '关闭免责声明';

  @override
  String safetyDisclaimerBannerInjuriesFlagged(Object arg0) {
    return '已标记伤病 $arg0';
  }

  @override
  String get safetyDisclaimerBannerInjuryBody => '伤病部位';

  @override
  String get safetyDisclaimerBannerLearnMore => '了解更多';

  @override
  String safetyDisclaimerBannerMore(Object overflow) {
    return '+$overflow 更多';
  }

  @override
  String get safetyDisclaimerBannerSafetyModeActive => '安全模式已激活';

  @override
  String get safetyDisclaimerBannerSafetyModeBody => '安全模式说明';

  @override
  String get saunaCustomDuration => '自定义时长';

  @override
  String saunaDialogLogMinSauna(Object selectedMinutes) {
    return '记录 $selectedMinutes 分钟桑拿';
  }

  @override
  String saunaDialogMin(Object minutes) {
    return '$minutes 分钟';
  }

  @override
  String get saunaLogSaunaTime => '记录桑拿时间';

  @override
  String get savedHubCheckYourConnectionAnd => '请检查您的网络连接并重试。';

  @override
  String get savedHubCouldnTLoadYour => '无法加载您的已保存项目。';

  @override
  String get savedHubNothingSavedYet => '暂无已保存内容';

  @override
  String get savedHubSaveAMealOr => '保存餐食或食物到饮食记录，以便稍后快速添加。';

  @override
  String get savedHubSaved => '已保存';

  @override
  String get savedHubScanARestaurantMenu => '扫描餐厅菜单或自助餐 — 扫描结果将保存在这里。';

  @override
  String get savedHubSignInToSee => '登录以查看您在此处保存的食谱。';

  @override
  String get savedHubSignInToSee2 => '登录以查看您在此处保存的食物。';

  @override
  String get savedHubTapOnAnyRecipe => '点击“发现”或您的库中任何食谱上的 ♥ 即可将其保存到此处。';

  @override
  String get savedHubTryAgain => '重试';

  @override
  String get scheduleGenerateThisWeek => '生成本周计划';

  @override
  String scheduleItemCardMin(Object durationMinutes) {
    return '$durationMinutes 分钟';
  }

  @override
  String get scheduleMealDays => '天数';

  @override
  String get scheduleMealEndDate => '结束日期';

  @override
  String get scheduleMealInterval => '间隔';

  @override
  String get scheduleMealPickACadenceWe => '选择一个节奏；我们将为您处理 AI 食谱保存。';

  @override
  String get scheduleMealPickADate => '选择日期';

  @override
  String get scheduleMealPickAnEndDate => '选择结束日期';

  @override
  String get scheduleMealPickAtLeastOne => '至少选择一天';

  @override
  String get scheduleMealSchedule => '安排';

  @override
  String get scheduleMealScheduleThisMeal => '安排此餐食';

  @override
  String scheduleMealSheetDays(Object i) {
    return '$i 天';
  }

  @override
  String scheduleMealSheetEveryDays(Object _intervalDays) {
    return '每 $_intervalDays 天';
  }

  @override
  String get scheduleMealTime => '时间';

  @override
  String get scheduleMismatchConfirm => '确认';

  @override
  String scheduleMismatchDialogAiWillSwitchTo(Object compatibleSplitName) {
    return 'AI 将改为切换至 $compatibleSplitName';
  }

  @override
  String scheduleMismatchDialogRequiresDaysPerWeek(
    Object currentDayCount,
    Object requiredDays,
    Object splitName,
  ) {
    return '$splitName 需要每周 $requiredDays 天，但你目前选择了 $currentDayCount 天。';
  }

  @override
  String scheduleMismatchDialogUpdateToSchedule(Object splitName) {
    return '更新至 $splitName 计划';
  }

  @override
  String scheduleMismatchDialogUseTheFullDay(Object requiredDays) {
    return '使用完整的 $requiredDays 天计划';
  }

  @override
  String get scheduleMismatchKeepMyCurrentDays => '保留我当前的天数';

  @override
  String get scheduleMismatchRecommended => '推荐';

  @override
  String get scheduleMismatchScheduleMismatch => '计划不匹配';

  @override
  String get scheduleNoItemsScheduled => '没有已安排的项目';

  @override
  String get scheduleRestDay => '休息日';

  @override
  String get scheduleSchedule => '计划';

  @override
  String scheduleScreenFailedToLoad(Object error) {
    return '加载失败：$error';
  }

  @override
  String scheduleScreenFailedToLoadTimeline(Object error) {
    return '加载时间轴失败：$error';
  }

  @override
  String scheduleScreenGeneratedOfWorkouts(Object length, Object successCount) {
    return '已生成 $length 个训练计划中的 $successCount 个';
  }

  @override
  String scheduleScreenGenerating(
    Object _generatedCount,
    Object _totalToGenerate,
  ) {
    return '正在生成 $_generatedCount/$_totalToGenerate...';
  }

  @override
  String get scheduleScreenPartMon => '周一';

  @override
  String get scheduleScreenPartStrength => '力量训练';

  @override
  String get scheduleScreenPartSun => '周日';

  @override
  String get scheduleScreenPartThisWeek => '本周';

  @override
  String scheduleScreenPartWeekSelectorEx(Object exerciseCount) {
    return '$exerciseCount 个动作';
  }

  @override
  String scheduleScreenPartWeekSelectorMin(Object bestDurationMinutes) {
    return '$bestDurationMinutes 分钟';
  }

  @override
  String get scheduleToday => '今天';

  @override
  String get scheduleWorkoutCheckingSchedule => '正在检查日程...';

  @override
  String scheduleWorkoutDialogFailedToScheduleWorkout(Object e) {
    return '安排训练失败：$e';
  }

  @override
  String scheduleWorkoutDialogScheduleFor(Object workoutName) {
    return '将“$workoutName”安排在：';
  }

  @override
  String scheduleWorkoutDialogWorkoutSAlreadyOn(Object length) {
    return '该日期已有 $length 个训练';
  }

  @override
  String scheduleWorkoutDialogWorkoutScheduledFor(Object day, Object month) {
    return '训练已安排在 $month/$day！';
  }

  @override
  String get scheduleWorkoutSchedule => '日程';

  @override
  String get scheduleWorkoutScheduleWorkout => '安排训练';

  @override
  String get scheduleWorkoutSchedulingWorkout => '正在安排训练...';

  @override
  String get scheduleWorkoutThisWorkoutWillBe => '此训练将与它们一起添加。';

  @override
  String get scoreBreakdownConsistency => '一致性';

  @override
  String get scoreBreakdownReadiness => '就绪状态';

  @override
  String get scoreBreakdownScoreBreakdown => '评分细则';

  @override
  String get scoreBreakdownStrength => '力量';

  @override
  String get scoreChangeAnnouncementGotIt => '知道了';

  @override
  String get scoreChangeAnnouncementMove => '活动';

  @override
  String get scoreChangeAnnouncementNourish => '营养';

  @override
  String scoreChangeAnnouncementSheetValue(Object label, Object weight) {
    return '$label · $weight%';
  }

  @override
  String get scoreChangeAnnouncementSleep => '睡眠';

  @override
  String get scoreChangeAnnouncementSleepNowCountsToward => '睡眠现在计入您的每日评分。';

  @override
  String get scoreChangeAnnouncementTrain => '训练';

  @override
  String get scoreChangeAnnouncementWhatSNew => '新功能';

  @override
  String get scoreColorsExcellent => '优秀';

  @override
  String get scoreExplain03AntiInflammatory => '0 – 3 抗炎';

  @override
  String get scoreExplain13Poor => '1 – 3 较差';

  @override
  String get scoreExplain46Average => '4 – 6 一般';

  @override
  String get scoreExplain46NeutralMild => '4 – 6 中性 / 轻微';

  @override
  String get scoreExplain710GoodExcellent => '7 – 10 良好 / 优秀';

  @override
  String get scoreExplain710HighlyInflammatory => '7 – 10 高度促炎';

  @override
  String get scoreExplainAddedSugar => '添加糖';

  @override
  String get scoreExplainAddedSugarIsThe => '添加糖是西方饮食中代谢综合征最强的饮食预测指标。';

  @override
  String scoreExplainAddedSugarValue(Object value) {
    return '添加糖：$value';
  }

  @override
  String get scoreExplainAiPicksATrafficLight => 'AI 会根据您的个人健康目标为每顿饭选择一个红绿灯等级。';

  @override
  String get scoreExplainAimForADailyAverage =>
      '目标日均分低于 4。抗炎食物得分为 1–3 分；高炎症食物得分为 7–10 分。';

  @override
  String get scoreExplainCertainPortionsOfAvocado =>
      '牛油果、红薯、杏仁的特定份量——小份没问题，大份则较难消化。';

  @override
  String get scoreExplainChronicLowGradeInflammation =>
      '饮食引起的慢性低度炎症与代谢疾病、关节疼痛和认知能力下降有关。';

  @override
  String get scoreExplainCurrentLabelAntiInfl => '抗炎';

  @override
  String get scoreExplainCurrentLabelAverage => '平均';

  @override
  String get scoreExplainCurrentLabelGood => 'GOOD';

  @override
  String get scoreExplainCurrentLabelHigh => 'HIGH';

  @override
  String get scoreExplainCurrentLabelLow => 'LOW';

  @override
  String get scoreExplainCurrentLabelMedium => '中等';

  @override
  String get scoreExplainCurrentLabelMild => 'MILD';

  @override
  String get scoreExplainCurrentLabelModerate => '中等';

  @override
  String get scoreExplainCurrentLabelNova4 => 'NOVA 4';

  @override
  String get scoreExplainCurrentLabelPoor => 'POOR';

  @override
  String get scoreExplainCurrentLabelSkip => 'SKIP';

  @override
  String get scoreExplainCurrentLabelWhole => 'WHOLE';

  @override
  String get scoreExplainDailyAverageAbove6 => '日均分高于 6 分与更好的长期代谢健康相关。';

  @override
  String get scoreExplainDessertsSugaryDrinksCandy =>
      '甜点、含糖饮料、糖果、许多早餐麦片。会导致胰岛素飙升，能量骤降。';

  @override
  String get scoreExplainEachMealGets =>
      '每顿饭都会根据营养密度、加工水平以及与您目标的契合度获得 1–10 分的健康评分。';

  @override
  String get scoreExplainEngineeredFoodProductsChip =>
      '工程食品：薯片、苏打水、方便面、包装甜食、大多数快餐。';

  @override
  String get scoreExplainFodmapRating => 'FODMAP 评分';

  @override
  String get scoreExplainFodmapsAreShortChain =>
      'FODMAP 是短链碳水化合物，难以被肠道细菌吸收和发酵。';

  @override
  String get scoreExplainFriedFoodsProcessedMeats =>
      '油炸食品、加工肉类、含糖饮料、精炼种子油、包装零食。';

  @override
  String get scoreExplainGlycemicLoadCombines =>
      '血糖负荷结合了碳水化合物的数量和质量。它可以预测一顿饭会使血糖升高多少。';

  @override
  String scoreExplainGlycemicLoadValue(Object v) {
    return '血糖负荷：$v';
  }

  @override
  String get scoreExplainGood => '良好';

  @override
  String get scoreExplainHealthScore => '健康评分';

  @override
  String scoreExplainHealthScoreValue(Object v) {
    return '健康评分：$v / 10';
  }

  @override
  String get scoreExplainHigh => '高';

  @override
  String get scoreExplainHigh15G => '高 (15 克以上)';

  @override
  String get scoreExplainHigh20 => '高 (20+)';

  @override
  String get scoreExplainHighInflammationUltraProce =>
      '高炎症、超加工或严重偏离您的宏量营养素目标。如果可能，请换成“良好”选项。';

  @override
  String get scoreExplainHighProteinOrFiber => '高蛋白质或纤维、天然食物、低添加糖、抗炎成分。';

  @override
  String get scoreExplainHitsYourGoalMacros =>
      '符合您的宏量营养素目标，主要是天然食物，炎症水平低至中等。可放心选择。';

  @override
  String get scoreExplainHowThisDishRates => '此菜品对您的评分影响';

  @override
  String get scoreExplainImportantIfYouHaveDiabetes =>
      '如果您患有糖尿病、胰岛素抵抗或正在管理能量水平，这一点很重要。';

  @override
  String scoreExplainInflammationScoreValue(Object v) {
    return '炎症评分：$v / 10';
  }

  @override
  String get scoreExplainLargePopulationStudies =>
      '大型人群研究将超加工食品的摄入与癌症、心血管疾病和早期死亡联系起来。';

  @override
  String get scoreExplainLeafyGreensBerriesWild =>
      '绿叶蔬菜、浆果、野生三文鱼、姜黄、特级初榨橄榄油、坚果、豆类。';

  @override
  String get scoreExplainLow => '低';

  @override
  String get scoreExplainLowUnder10 => '低 (低于 10)';

  @override
  String get scoreExplainLowUnder5G => '低 (低于 5 克)';

  @override
  String get scoreExplainMeatEggsRiceOats =>
      '肉类、鸡蛋、米饭、燕麦、无乳糖乳制品、胡萝卜、西葫芦、菠菜、浆果、橙子。';

  @override
  String get scoreExplainMedium => '中等';

  @override
  String get scoreExplainMedium1019 => '中等 (10 – 19)';

  @override
  String get scoreExplainMinimalBloodSugarSpike =>
      '血糖波动极小。非淀粉类蔬菜、鸡蛋、肉类、浆果、大多数乳制品。';

  @override
  String get scoreExplainModerate => '适中';

  @override
  String get scoreExplainModerate514G => '适中 (5 – 14 克)';

  @override
  String get scoreExplainModerateSpikeOatsWhole => '波动适中。燕麦、全麦面包、香蕉、红薯、巴斯马蒂香米。';

  @override
  String get scoreExplainMostSavouryDishesPlain =>
      '大多数咸味菜肴、纯乳制品、完整水果。对血糖没有明显影响。';

  @override
  String get scoreExplainOnionGarlicWheatRye =>
      '洋葱、大蒜、小麦、黑麦、牛奶/冰淇淋、苹果、梨、蜂蜜、豆类、花椰菜。';

  @override
  String get scoreExplainOnlyRelevantIfYouHaveIbs =>
      '仅在您患有 IBS 或确诊肠道疾病时相关。否则可以忽略。';

  @override
  String get scoreExplainRatingsArePersonalised =>
      '评分是根据您的目标、过敏原和饮食记录进行个性化定制的。';

  @override
  String get scoreExplainRawOrBasicCooked => '生食或基础烹饪食物：肉类、鸡蛋、蔬菜、原味酸奶、奶酪、全谷物。';

  @override
  String get scoreExplainReasonableChoiceCouldBe =>
      '合理的选择——可以在一两个方面进行改进（增加纤维，减少加工）。';

  @override
  String get scoreExplainReasonableChoiceWithA => '有权衡的合理选择——注意份量或搭配更健康的配菜。';

  @override
  String get scoreExplainScoreDetailUnavailable => '此餐食的评分详情不可用。';

  @override
  String get scoreExplainSkip => '跳过';

  @override
  String get scoreExplainSteepSpikeCrashWhite => '剧烈波动 + 骤降。白米饭碗、含糖饮料、糕点、大份意面。';

  @override
  String get scoreExplainSweetenedYogurtASmall =>
      '加糖酸奶、小份糕点、半瓶运动饮料。合理的零食——不建议每天食用。';

  @override
  String scoreExplainThatIsAboutPctDay(Object pctDay) {
    return '这大约是 WHO 25 克/天限制的 $pctDay%。添加糖会导致牙齿腐烂、胰岛素飙升和非酒精性脂肪肝。';
  }

  @override
  String get scoreExplainUltraProcessed => '超加工';

  @override
  String get scoreExplainUltraProcessedDeepFried => '超加工、油炸、低纤维或添加糖/钠含量极高。';

  @override
  String get scoreExplainUltraProcessedNova4 => '超加工 (NOVA 4)';

  @override
  String get scoreExplainWeUseTheNovaClassification =>
      '我们使用圣保罗大学开发的 NOVA 分类系统。';

  @override
  String get scoreExplainWhiteRicePlainEggs => '白米饭、纯鸡蛋、硬奶酪、小份瘦红肉。';

  @override
  String get scoreExplainWhoRecommendsAdults =>
      'WHO 建议成年人将添加糖摄入量限制在 < 25 克/天（占总能量的 5%）。';

  @override
  String get scoreExplainWholeMinimallyProcessed => '天然 / 最低限度加工';

  @override
  String get scoreExplainWhyThisScore => '为什么是这个评分';

  @override
  String get scoringCard6FactorWeightedSelection => '6 因素加权选择算法';

  @override
  String get scoringCardExerciseScoringBreakdown => '运动评分细则';

  @override
  String get scoringCardNormalize => '归一化';

  @override
  String get scoringCardOver100 => '超过 100%';

  @override
  String get scoringCardReset => '重置';

  @override
  String scoringCardTotal(Object totalPct) {
    return '总计：$totalPct%';
  }

  @override
  String get scoringCardUnder90 => '低于 90%';

  @override
  String scoringCardValue(Object key, Object pct) {
    return '$key：$pct%';
  }

  @override
  String scoringCardValue2(Object pct) {
    return '$pct%';
  }

  @override
  String get scoringFitnessScore => '健身评分';

  @override
  String get scoringHowScoresAreCalculated => '评分计算方式';

  @override
  String get scoringYourOverallFitnessScore => '您的整体健身评分结合了这些因素，为您提供健身历程的全面视图。';

  @override
  String get sectionHeaderWhatSThis => '这是什么？';

  @override
  String get sectionedHeroAreaCalendarDisplayOptions => '日历显示选项';

  @override
  String get sectionedHeroAreaMon => '周一';

  @override
  String get sectionedHeroAreaShowSyncedWorkouts => '显示已同步的训练';

  @override
  String get sectionedHeroAreaStartWeekOnMonday => '周一作为每周的第一天';

  @override
  String get sectionedHeroAreaStartWeekOnSunday => '周日作为一周的开始';

  @override
  String get sectionedHeroAreaSun => '周日';

  @override
  String get selectableChipOther => '其他';

  @override
  String get seniorButtonRecommended => '推荐';

  @override
  String seniorCardExercisesMin(Object durationMinutes, Object exerciseCount) {
    return '$exerciseCount 个动作  •  $durationMinutes 分钟';
  }

  @override
  String get seniorCardLoading => '加载中...';

  @override
  String get seniorCardStartWorkout => '开始训练';

  @override
  String get seniorCardTodaySWorkout => '今日训练';

  @override
  String get seniorFitnessAgeAdaptedWorkouts => '适龄训练计划';

  @override
  String get seniorFitnessRestBetweenSets => '组间休息';

  @override
  String get seniorFitnessSaveSettings => '保存设置';

  @override
  String seniorFitnessScreenS(Object restBetweenSets) {
    return '$restBetweenSets 秒';
  }

  @override
  String get seniorFitnessSeniorFitness => '银发健身';

  @override
  String get seniorFitnessSettingsSaved => '设置已保存';

  @override
  String get seniorFitnessTheseSettingsHelpCustomize =>
      '这些设置有助于根据银发族的健身需求定制训练，包括更长的恢复时间和对关节更友好的动作。';

  @override
  String get seniorNavFood => '饮食';

  @override
  String get sessionDetailReps => '次数';

  @override
  String get sessionDetailSet => '组';

  @override
  String sessionDetailSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 组',
    );
    return '$_temp0 · 高亮显示最高组';
  }

  @override
  String get sessionDetailTime => '时间';

  @override
  String get sessionDetailTopSetHighlighted => ') • 已高亮显示顶峰组';

  @override
  String get sessionDetailWeight => '重量';

  @override
  String get setAdjustmentAdditionalNotesOptional => '补充说明（可选）';

  @override
  String get setAdjustmentConfirm => '确认';

  @override
  String get setAdjustmentEGShoulderFeels => '例如：肩膀感觉紧绷...';

  @override
  String get setAdjustmentSheet1Set => '+1 组';

  @override
  String get setAdjustmentSheet1Set2 => '-1 组';

  @override
  String get setAdjustmentSheetAdditionalNotesOptional => '补充说明（可选）';

  @override
  String get setAdjustmentSheetApply => '应用';

  @override
  String get setAdjustmentSheetCopyLast => '复制上一组';

  @override
  String get setAdjustmentSheetDoneWithThisExercise => '完成该动作了吗？';

  @override
  String get setAdjustmentSheetEditSets => '编辑组数';

  @override
  String setAdjustmentSheetPartInWorkoutSetEditingSheetStateAdded(
    Object originalSetCount,
  ) {
    return '已添加 +$originalSetCount 组';
  }

  @override
  String setAdjustmentSheetPartInWorkoutSetEditingSheetStateDone(
    Object completedCount,
  ) {
    return '已完成 $completedCount 组';
  }

  @override
  String setAdjustmentSheetPartInWorkoutSetEditingSheetStateRemaining(
    Object remainingCount,
  ) {
    return '剩余 $remainingCount 组';
  }

  @override
  String setAdjustmentSheetPartInWorkoutSetEditingSheetStateRemoved(
    Object length,
  ) {
    return '已移除 $length 组';
  }

  @override
  String setAdjustmentSheetPartSetAdjustmentReasonOf(Object exerciseName) {
    return ') / (exerciseName)';
  }

  @override
  String setAdjustmentSheetPartSetAdjustmentReasonOfPlanned(Object totalSets) {
    return '共计划 $totalSets 组';
  }

  @override
  String setAdjustmentSheetPartSetAdjustmentReasonSetsCompleted(
    Object completedSets,
  ) {
    return '已完成 $completedSets 组';
  }

  @override
  String get setAdjustmentSheetReps => '次数';

  @override
  String get setAdjustmentSheetSaveChanges => '保存更改';

  @override
  String get setAdjustmentSheetSkipContinue => '跳过并继续';

  @override
  String get setAdjustmentSheetWeight => '重量';

  @override
  String get setAdjustmentSheetWhyAreYouReducing => '为什么要减少组数？';

  @override
  String get setAdjustmentSheetWhyAreYouStopping => '为什么要提前结束？';

  @override
  String get setAdjustmentWhyAreYouAdjusting => '为什么要调整？';

  @override
  String get setLoggingMixinReps => '次数';

  @override
  String get setLoggingMixinRirRepsInReserve => 'RIR (预留次数)';

  @override
  String get setLoggingMixinSetTargetRir => '设置目标 RIR';

  @override
  String setRailInternalsMoreSets(Object count) {
    return '更多组数 $count';
  }

  @override
  String setRailInternalsValue(Object count) {
    return '+$count';
  }

  @override
  String get setRailOverflowAllSets => '所有组';

  @override
  String setRailOverflowRowSet(Object displayIndex) {
    return '第 $displayIndex 组';
  }

  @override
  String setRailOverflowSheetTotal(Object length) {
    return '共$length项';
  }

  @override
  String get setRowHidePrevious => '隐藏上次记录';

  @override
  String setRowNReps(Object count) {
    return '$count 次';
  }

  @override
  String get setRowPartHide => '隐藏';

  @override
  String get setRowPartHidePrevious => '隐藏上一组';

  @override
  String get setRowPartHowHardWasThat => '这一组感觉如何？';

  @override
  String get setRowPartRateOfPerceivedExertion => 'RPE (主观用力程度)';

  @override
  String get setRowPartRepsInReserve => 'RIR (预留次数)';

  @override
  String get setRowPartRirHowManyMore => 'RIR = 你还能再做多少次？';

  @override
  String get setRowPartRpeMeasuresHowHard => 'RPE 用于衡量一组动作的吃力程度，范围为 6-10：';

  @override
  String setRowPartRpeRirSelectorStateLeft(Object value) {
    return '剩余 $value';
  }

  @override
  String get setRowPartThisHelpsUsAdjust => '这有助于我们调整你的下一组训练';

  @override
  String setRowPartWeightIncrementsValue(Object actualPercent) {
    return '$actualPercent%';
  }

  @override
  String get setRowPartWhatSThis => '这是什么？';

  @override
  String setRowPrevKg(Object setData) {
    return '上次：$setData kg';
  }

  @override
  String setRowPrevReps(Object previousReps) {
    return '上次：$previousReps 次';
  }

  @override
  String setRowPreviousData(Object reps, Object unit, Object weight) {
    return '上次：$weight $unit × $reps 次';
  }

  @override
  String setRowRm(Object oneRM) {
    return '(1RM: $oneRM)';
  }

  @override
  String setRowSetN(Object n) {
    return '第 $n 组';
  }

  @override
  String setRowSetNCompact(Object n) {
    return '第 $n 组';
  }

  @override
  String setRowTarget(Object targetPercent) {
    return '目标：$targetPercent%';
  }

  @override
  String setRowValue(Object actualPercent) {
    return '→ $actualPercent%';
  }

  @override
  String get setRowVisualsEdited => '已编辑';

  @override
  String get setRowVisualsGotIt => '知道了';

  @override
  String get setRowVisualsStarterWeight => '起始重量';

  @override
  String get setTrackingExerciseComplete => '动作完成！';

  @override
  String get setTrackingNext => '下一个：';

  @override
  String get setTrackingOverlayAnalytics => '分析';

  @override
  String get setTrackingOverlayBackToCurrentExercise => '返回当前动作';

  @override
  String get setTrackingOverlayEffectiveSets => '有效组数';

  @override
  String get setTrackingOverlayHide => '隐藏';

  @override
  String get setTrackingOverlayIncrement => '增量';

  @override
  String get setTrackingOverlayProgression => '进度';

  @override
  String get setTrackingOverlaySet => '+ 组';

  @override
  String get setTrackingOverlaySetType => '组类型：';

  @override
  String get setTrackingOverlayShow => '显示';

  @override
  String get setTrackingOverlayStraight => '标准组';

  @override
  String get setTrackingOverlayTapToAddNotes => '点击添加备注...';

  @override
  String get setTrackingOverlayTarget => '目标';

  @override
  String setTrackingOverlayUi1Of(Object totalExercises, Object widget) {
    return '$widget / $totalExercises';
  }

  @override
  String setTrackingOverlayUi1Value(Object warmupReps, Object warmupWeight) {
    return '$warmupWeight × $warmupReps';
  }

  @override
  String get setTrackingOverlayView => '查看';

  @override
  String get setTrackingOverlayViewPr => '查看 PR';

  @override
  String get setTrackingOverlayWarmupSets => '热身组';

  @override
  String setTrackingSectionExerciseOf(Object totalExercises, Object widget) {
    return '第 $widget 个训练，共 $totalExercises 个';
  }

  @override
  String setTrackingSectionSetTapToExpand(
    Object currentSetNumber,
    Object totalSets,
  ) {
    return '第 $currentSetNumber/$totalSets 组 • 点击展开';
  }

  @override
  String setTrackingSectionSets(Object widget) {
    return '$widget 组';
  }

  @override
  String setTrackingSectionSetsCompleted(Object length) {
    return '已完成 $length 组';
  }

  @override
  String setTrackingSectionValue(Object reps) {
    return ')×(reps)';
  }

  @override
  String get setTrackingSheetsAmountToAdjustWeight => '重量调整幅度';

  @override
  String get setTrackingSheetsDropSet => '递减组';

  @override
  String get setTrackingSheetsExerciseHistory => '动作历史';

  @override
  String get setTrackingSheetsGotIt => '知道了';

  @override
  String get setTrackingSheetsImmediatelyReduceWeightAfte =>
      '力竭后立即减轻重量并继续训练。非常适合肌肉增长！';

  @override
  String get setTrackingSheetsLastSession => '上次训练';

  @override
  String get setTrackingSheetsLightWeightToPrepare => '用于准备肌肉的轻重量。不计入训练总量。';

  @override
  String get setTrackingSheetsMarkWhenYouCouldn => '当你无法完成目标次数时进行标记。有助于追踪强度。';

  @override
  String get setTrackingSheetsPersonalRecord => '个人纪录';

  @override
  String get setTrackingSheetsRateOfPerceivedExertion =>
      'RPE (主观用力程度) 用于衡量一组动作的吃力程度：';

  @override
  String get setTrackingSheetsReps => '次数';

  @override
  String get setTrackingSheetsSaveTarget => '保存目标';

  @override
  String get setTrackingSheetsSetTarget => '设置目标';

  @override
  String get setTrackingSheetsSetTypes => '组类型';

  @override
  String get setTrackingSheetsTargetRir => '目标 RIR';

  @override
  String get setTrackingSheetsWarmup => '热身';

  @override
  String get setTrackingSheetsWeightIncrement => '重量增量';

  @override
  String get setTrackingSheetsWeightKg => '重量 (kg)';

  @override
  String get setTrackingSheetsWeightLbs => '重量 (lbs)';

  @override
  String get setTrackingSheetsWhatIsRpe => '什么是 RPE？';

  @override
  String get setTrackingTableALowerRir0 =>
      '较低的 RIR (0–1) 意味着你已达到极限。较高的 RIR (如 4–6+) 意味着这组动作感觉较轻松，你还有很大余力。';

  @override
  String get setTrackingTableALowerRir02 =>
      '较低的 RIR (0–1) 意味着你已接近极限。较高的 RIR (如 3–4) 意味着你还有余力完成更多次数。';

  @override
  String get setTrackingTableAddSet => '添加组';

  @override
  String get setTrackingTableBeginnersGetExtraBuffer =>
      '初学者会有额外的缓冲空间以学习动作规范。进阶训练者可以更安全地接近力竭。';

  @override
  String get setTrackingTableCompoundLiftsSquatsPresse =>
      '复合动作（深蹲、推举）比孤立动作（弯举、侧平举）更保守。肌肥大训练比力量训练更接近力竭。';

  @override
  String get setTrackingTableEasiest => '最轻松';

  @override
  String get setTrackingTableEquipmentSafety => '器械安全性';

  @override
  String get setTrackingTableHardest => '最吃力';

  @override
  String get setTrackingTableHowYourTargetRir => '如何计算你的目标 RIR';

  @override
  String get setTrackingTableLeft => '左';

  @override
  String get setTrackingTableMachinesCablesAreSafer =>
      '器械和绳索训练更安全，可以尝试高强度。杠铃和壶铃由于受伤风险，需要保留更多余力。';

  @override
  String get setTrackingTableManyRepsInReserve => '余力充足';

  @override
  String get setTrackingTableNoRepsInReserve => '无余力';

  @override
  String setTrackingTablePartSetNumberBadgeRir(Object previousRir) {
    return 'RIR $previousRir';
  }

  @override
  String setTrackingTablePartSetNumberBadgeRir2(Object displayRir) {
    return 'RIR $displayRir';
  }

  @override
  String get setTrackingTablePrevious => '上一组';

  @override
  String get setTrackingTableRight => '右';

  @override
  String get setTrackingTableRirDecreasesAcrossSets =>
      'RIR 会随着组数增加而降低——最后一组强度最大，前面的组数作为铺垫。';

  @override
  String get setTrackingTableRirStandsForReps =>
      'RIR 代表 Reps in Reserve（保留次数），这是一种描述一组动作难度感的简单方式。';

  @override
  String get setTrackingTableSet => '组';

  @override
  String get setTrackingTableTarget => '目标';

  @override
  String get setTrackingTableTrainingGoalExerciseType => '训练目标 + 动作类型';

  @override
  String get setTrackingTableWhatIsRir => '什么是 RIR？';

  @override
  String get setTrackingTableWhatYouSeeAbove => '上方显示的是 RIR 量表';

  @override
  String get setTrackingTableYouAreNotRequired =>
      '你不必强制记录 RIR，但我们强烈建议这样做。了解你距离力竭的程度，将有助于 App 更好地适应你当前的体能水平和疲劳程度。';

  @override
  String get setTrackingTableYourFitnessLevel => '你的健身水平';

  @override
  String get setTrackingTableYourRirTargetIs => '你的 RIR 目标是根据以下三个因素个性化定制的：';

  @override
  String get settings24UpcomingFeatures => '24 项即将推出的功能';

  @override
  String get settingsAboutSection => '关于';

  @override
  String get settingsAccount => '账户';

  @override
  String get settingsAccountSection => '账户';

  @override
  String get settingsAppSection => '应用';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsAppleHealth => 'Apple Health';

  @override
  String get settingsBeastMode => '野兽模式';

  @override
  String settingsCardAvoided(Object length) {
    return '$length 个已避免';
  }

  @override
  String settingsCardBodyWorkout(Object bodyUnit, Object workoutUnit) {
    return '身体 $bodyUnit · 训练 $workoutUnit';
  }

  @override
  String get settingsCardChangingDaysWillReschedule => '更改日期将自动重新安排你即将进行的训练。';

  @override
  String settingsCardExercises(Object length) {
    return '$length 个动作';
  }

  @override
  String settingsCardExercises2(Object length) {
    return '$length 个动作';
  }

  @override
  String get settingsCardFailedToUpdate => '更新失败';

  @override
  String get settingsCardHowMuchExerciseVariety => '每周的动作多样性程度？';

  @override
  String settingsCardLifts(Object length) {
    return '$length 个举重动作';
  }

  @override
  String get settingsCardMonday => '周一';

  @override
  String settingsCardNDaysSelected(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已选 $n 天',
      one: '已选 1 天',
    );
    return '$_temp0';
  }

  @override
  String get settingsCardNoChanges => '无更改';

  @override
  String settingsCardPartAccentColorGridLvl(Object unlockLevel) {
    return '等级 $unlockLevel';
  }

  @override
  String settingsCardPartAccentColorGridSelected(Object length) {
    return '已选 $length 项';
  }

  @override
  String settingsCardPartAccentColorGridUnlocksAtLevelKeep(Object unlockLevel) {
    return '等级 $unlockLevel 解锁 — 继续加油！';
  }

  @override
  String settingsCardPartAccentColorGridValue(
    Object currentOffset,
    Object region,
  ) {
    return '$region • $currentOffset';
  }

  @override
  String get settingsCardPartChangingDaysWillReschedule =>
      '更改日期将自动重新安排你接下来的训练计划。';

  @override
  String get settingsCardPartClearAll => '全部清除';

  @override
  String get settingsCardPartForLearning => '用于学习';

  @override
  String get settingsCardPartFri => '周五';

  @override
  String get settingsCardPartFriday => '星期五';

  @override
  String get settingsCardPartMon => '周一';

  @override
  String get settingsCardPartMonday => '星期一';

  @override
  String get settingsCardPartMyEquipment => '我的器械';

  @override
  String get settingsCardPartNoChanges => '无更改';

  @override
  String get settingsCardPartRecommended => '推荐';

  @override
  String get settingsCardPartSat => '周六';

  @override
  String get settingsCardPartSaturday => '星期六';

  @override
  String get settingsCardPartSaveChanges => '保存更改';

  @override
  String get settingsCardPartSaveEquipment => '保存器械';

  @override
  String get settingsCardPartSearchEquipment => '搜索器械...';

  @override
  String get settingsCardPartSelectAllEquipmentYou => '选择你可使用的所有器械';

  @override
  String get settingsCardPartSelectWhichDaysYou => '选择你的训练日期';

  @override
  String get settingsCardPartSun => '周日';

  @override
  String get settingsCardPartSunday => '星期日';

  @override
  String get settingsCardPartThu => '周四';

  @override
  String get settingsCardPartThursday => '星期四';

  @override
  String get settingsCardPartTue => '周二';

  @override
  String get settingsCardPartTuesday => '星期二';

  @override
  String get settingsCardPartWed => '周三';

  @override
  String get settingsCardPartWednesday => '星期三';

  @override
  String get settingsCardPartWorkoutDays => '训练日';

  @override
  String get settingsCardPleaseSelectAtLeastOne => '请至少选择一个训练日';

  @override
  String settingsCardQueued(Object length) {
    return '$length 个已排队';
  }

  @override
  String get settingsCardSaveChanges => '保存更改';

  @override
  String get settingsCardSelectWhichDaysYou => '选择你要训练的日子';

  @override
  String get settingsCardSunday => '星期日';

  @override
  String get settingsCardUiAccentColor => '强调色';

  @override
  String get settingsCardUiBodyMeasurements => '身体测量';

  @override
  String get settingsCardUiBodyWeight => '体重';

  @override
  String get settingsCardUiChooseAnAccentColor => '为按钮和高亮显示选择一种强调色';

  @override
  String get settingsCardUiChooseHowToStructure => '选择如何安排每周的训练计划';

  @override
  String get settingsCardUiChooseTimezone => '选择时区';

  @override
  String get settingsCardUiExerciseConsistency => '训练一致性';

  @override
  String get settingsCardUiForLoggingLiftsSets => '用于记录举重、组数、训练重量';

  @override
  String get settingsCardUiForWaistChestHips => '用于腰围、胸围、臀围、手臂、腿部测量';

  @override
  String get settingsCardUiForWeighingYourselfBmi => '用于记录体重、BMI 计算';

  @override
  String get settingsCardUiHowFastShouldWe => '我们应该以多快的速度增加你的训练重量？';

  @override
  String get settingsCardUiHowHardShouldYour => '你的训练强度应该达到多少？';

  @override
  String get settingsCardUiHowShouldTheAi => 'AI 应该如何为你的训练选择动作？';

  @override
  String get settingsCardUiProgressionPace => '进阶节奏';

  @override
  String get settingsCardUiTrainingIntensity => '训练强度';

  @override
  String get settingsCardUiTrainingSplit => '训练拆分';

  @override
  String get settingsCardUiUnits => '单位';

  @override
  String get settingsCardUiWeightWorkoutAndBody => '重量、锻炼和身体测量单位';

  @override
  String get settingsCardUiWhatTypeOfWorkouts => '你偏好哪种类型的锻炼？';

  @override
  String get settingsCardUiWorkoutType => '锻炼类型';

  @override
  String get settingsCardUiWorkoutWeight => '锻炼重量';

  @override
  String settingsCardValue(Object label, Object value) {
    return '$label ($value%)';
  }

  @override
  String settingsCardValue2(Object label, Object value) {
    return '$label ($value%)';
  }

  @override
  String settingsCardValue3(Object percentage) {
    return '$percentage%';
  }

  @override
  String settingsCardValue4(Object globalIntensityPercent) {
    return '$globalIntensityPercent%';
  }

  @override
  String settingsCardVideos(Object cachedVideoCount) {
    return '$cachedVideoCount 个视频';
  }

  @override
  String get settingsCardWeeklyVariety => '每周多样性';

  @override
  String get settingsCardWorkoutDays => '训练日';

  @override
  String settingsCardWorkoutDaysUpdatedTo(Object days) {
    return '训练日已更新为 $days';
  }

  @override
  String get settingsComingSoon => '敬请期待';

  @override
  String get settingsConnections => '连接';

  @override
  String get settingsContactSupport => '联系支持';

  @override
  String get settingsDeleteAccount => '删除账户';

  @override
  String get settingsEquipment => '器械';

  @override
  String get settingsExercisePrefs => '锻炼偏好';

  @override
  String get settingsFavoritesAvoidedQueue => '收藏、屏蔽与队列';

  @override
  String get settingsHealthConnect => 'Health Connect';

  @override
  String get settingsHealthDevices => '健康与设备';

  @override
  String get settingsHelpSection => '帮助';

  @override
  String get settingsHelpSupport => '帮助与支持';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSubtitle => '选择您的首选语言';

  @override
  String get settingsLogout => '退出登录';

  @override
  String get settingsMealReminders => '饮食提醒';

  @override
  String get settingsMyGyms => '我的健身房';

  @override
  String get settingsNutritionSection => '营养';

  @override
  String get settingsPersonalization => '个性化';

  @override
  String get settingsPowerUserTools => '高级用户工具';

  @override
  String get settingsPrivacyData => '隐私与数据';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsPrivacySection => '隐私';

  @override
  String get settingsRateApp => '评价应用';

  @override
  String get settingsRecipeSchedulesSharingV => '食谱计划 + 分享 + 版本管理';

  @override
  String get settingsReplayToursOrReset => '重播导览或重置内联提示';

  @override
  String get settingsResearchScience => '研究与科学';

  @override
  String settingsScreenAbout(Object appName) {
    return '关于 $appName';
  }

  @override
  String settingsScreenCouldNotOpen(Object url) {
    return '无法打开 $url';
  }

  @override
  String get settingsScreenExtANoteFromChetan => '来自 Chetan 的寄语';

  @override
  String get settingsScreenExtInlineHints => '内联提示';

  @override
  String get settingsScreenExtReplay => '重播';

  @override
  String get settingsScreenExtReplayIndividualTours => '重播单个导览';

  @override
  String get settingsScreenExtReplayOnboardingWalkthrough => '重播新手引导';

  @override
  String get settingsScreenExtReplayTheOnboardingWalkthro =>
      '重播新手引导、单个屏幕导览，或重置内联提示。';

  @override
  String get settingsScreenExtResetInlineHints => '重置内联提示';

  @override
  String get settingsScreenExtSearchSettings => '搜索设置...';

  @override
  String get settingsScreenExtSmallEmptyStateHints =>
      '散布在应用各处的空状态小提示。重置它们以再次查看帮助文本。';

  @override
  String get settingsScreenExtTutorialsHints => '教程与提示';

  @override
  String settingsScreenExtVersion(Object buildNumber, Object version) {
    return '版本 $version ($buildNumber)';
  }

  @override
  String settingsScreenExtWhyIBuilt(Object appName) {
    return '我为何开发 $appName';
  }

  @override
  String get settingsScreenExtYourAiPoweredPersonal =>
      '你的 AI 驱动个人健身教练。获取个性化锻炼计划，追踪进度，并实现你的健身目标。';

  @override
  String settingsScreenMailtoSubjectSupportRequest(
    Object appName,
    Object supportEmail,
  ) {
    return 'mailto:$supportEmail?subject=$appName 支持请求';
  }

  @override
  String settingsScreenUBDays(Object daysPerWeek, Object splitName) {
    return '$splitName · $daysPerWeek 天';
  }

  @override
  String get settingsScreenUiNoSettingsFound => '未找到相关设置';

  @override
  String get settingsScreenUiTryDifferentKeywordsLike =>
      '尝试使用不同的关键词，例如“主题”、“通知”或“AI 语音”';

  @override
  String settingsScreenV(Object appName, Object version) {
    return '$appName v$version';
  }

  @override
  String get settingsSearchSettings => '搜索设置';

  @override
  String get settingsSetProgressionResearch => '设置进度与研究';

  @override
  String get settingsSharingExportEmail => '分享、导出、电子邮件';

  @override
  String get settingsSingleLevelWithCrate => '单级，带宝箱奖励';

  @override
  String get settingsSoundNotifs => '声音与通知';

  @override
  String get settingsSubscription => '订阅';

  @override
  String get settingsTermsOfService => '服务条款';

  @override
  String get settingsTestLevelUpLevel => '测试升级（2级→3级）';

  @override
  String get settingsTestLevelUpLevel2 => '测试升级（10级→11级）';

  @override
  String get settingsTestMultiLevel1 => '测试多级升级（1级→5级）';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeMode => '主题';

  @override
  String get settingsThemeSystem => '系统';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsTitleChangeBeginnerNovic => '称号变更：初学者 → 新手';

  @override
  String get settingsTraining => '训练';

  @override
  String get settingsTrainingMethods => '训练方法';

  @override
  String get settingsTrainingSection => '训练';

  @override
  String get settingsTutorialsHints => '教程与提示';

  @override
  String get settingsVoiceAudioReminders => '语音、音频、提醒';

  @override
  String get settingsVoicePersonality => '语音与个性';

  @override
  String get settingsWithCascadeOverlayDialog => '带级联叠加层 + 对话框';

  @override
  String get settingsWorkoutMode => '锻炼模式';

  @override
  String get settingsWorkoutSettings => '锻炼设置';

  @override
  String get shareArtifactCardCopyShare => '复制并分享';

  @override
  String get shareableGallerySortDefault => '默认';

  @override
  String get shareableGallerySortFavorites => '收藏优先';

  @override
  String get shareableGallerySortRecents => '最近优先';

  @override
  String get shareableGallerySortTooltip => '模板排序';

  @override
  String get shareArtifactCardCouldNotCreateShare => '无法创建分享链接。';

  @override
  String get shareArtifactCardOpenInApp => '在应用中打开';

  @override
  String get shareBodyAnalyzerBodyFat => '体脂率';

  @override
  String get shareBodyAnalyzerMuscleMass => '肌肉量';

  @override
  String get shareBodyAnalyzerShareFailed => '分享失败';

  @override
  String get shareBodyAnalyzerShareImage => '分享图片';

  @override
  String shareBodyAnalyzerSheetBodyAnalyzer(Object appName) {
    return '@$appName · 体成分分析';
  }

  @override
  String get shareBodyAnalyzerSymmetry => '对称性';

  @override
  String shareBreakdownNExercises(Object count) {
    return '$count 个动作';
  }

  @override
  String shareBreakdownNMore(Object count) {
    return '+$count 个更多';
  }

  @override
  String shareBreakdownNSets(Object count) {
    return '$count 组';
  }

  @override
  String get shareBreakdownTodaysLifts => '今日训练';

  @override
  String get shareCoachWorkoutReview => '教练训练回顾';

  @override
  String get shareInsightsShareReport => '分享报告';

  @override
  String shareInsightsSheetMyReport(Object appName, Object periodName) {
    return '我的 $appName $periodName 报告';
  }

  @override
  String shareInsightsSheetMyReport2(Object appName) {
    return '我的 $appName 报告';
  }

  @override
  String get shareMotivationalCompleted => '已完成';

  @override
  String get sharePrNewPr => '新 PR';

  @override
  String get shareStatsCalories => '卡路里';

  @override
  String get shareStatsDuration => '时长';

  @override
  String get shareStatsEliteTemplate => '精英模板';

  @override
  String get shareStatsExercises => '训练动作';

  @override
  String get shareStatsInstagram => 'Instagram';

  @override
  String get shareStatsLogAWorkoutTo => '记录一次锻炼以解锁分享模板。';

  @override
  String get shareStatsSaveOnly => '仅保存';

  @override
  String get shareStatsShareYourStats => '分享你的数据';

  @override
  String shareStatsSheetUnlocksAtLevelLevels(Object levelsToGo) {
    return '75级解锁 · 距离下一级还差 $levelsToGo 级';
  }

  @override
  String get shareStatsShowWatermark => '显示水印';

  @override
  String get shareStatsVolume => '训练总量';

  @override
  String get shareStatsWorkoutComplete => '训练完成';

  @override
  String get shareStrengthFocusAreas => '重点区域';

  @override
  String get shareStrengthInstagram => 'Instagram';

  @override
  String get shareStrengthMuscleBreakdown => '肌肉分布';

  @override
  String get shareStrengthSaveToGallery => '保存到相册';

  @override
  String get shareStrengthShareStrength => '分享力量';

  @override
  String shareStrengthSheetMuscleGroups(Object length) {
    return '$length 个肌群';
  }

  @override
  String get shareStrengthShowWatermark => '显示水印';

  @override
  String get shareStrengthStrengthScore => '力量评分';

  @override
  String get shareStrengthTopMuscles => '主要肌肉';

  @override
  String get shareStrengthTopScores => '最高评分';

  @override
  String get shareTemplateInstagram => 'Instagram';

  @override
  String get shareTemplateSaveOnly => '仅保存';

  @override
  String get shareTemplateShowWatermark => '显示水印';

  @override
  String get shareWeeklySummaryShareYourWeek => '分享本周动态';

  @override
  String shareWeeklySummarySheetMyWeek(Object appName, Object dateRange) {
    return '我的 $appName 周报 — $dateRange';
  }

  @override
  String shareWeeklySummarySheetMyWeeklyReport(Object appName) {
    return '我的 $appName 每周报告';
  }

  @override
  String get shareWorkoutAddYourPhoto => '添加照片';

  @override
  String get shareWorkoutAiCaption => 'AI 文案';

  @override
  String get shareWorkoutChangePhoto => '更换照片';

  @override
  String get shareWorkoutEditImage => '编辑图片';

  @override
  String get shareWorkoutInstagram => 'Instagram';

  @override
  String get shareWorkoutSaveOnly => '仅保存';

  @override
  String get shareWorkoutShareYourWorkout => '分享训练';

  @override
  String get shareWorkoutSheetBrightness => '亮度';

  @override
  String get shareWorkoutSheetContrast => '对比度';

  @override
  String shareWorkoutSheetCopied(Object caption) {
    return '已复制: “$caption”';
  }

  @override
  String get shareWorkoutSheetEditImage => '编辑图片';

  @override
  String shareWorkoutSheetPartSimplePhotoEditorFailedToShare(Object e) {
    return '分享失败：$e';
  }

  @override
  String get shareWorkoutSheetPinchToZoomTap => '双指缩放 • 点击任意处关闭';

  @override
  String get shareWorkoutSheetReset => '重置';

  @override
  String get shareWorkoutSheetTapToPreview => '点击预览';

  @override
  String get shareWorkoutShowWatermark => '显示水印';

  @override
  String get shareWorkoutWriting => '正在生成...';

  @override
  String get sharedWorkoutDetailAcceptChallenge => '接受挑战';

  @override
  String get sharedWorkoutDetailExerciseDetailsNotAvailable => '无法获取动作详情';

  @override
  String get sharedWorkoutDetailScheduleForLater => '稍后安排';

  @override
  String sharedWorkoutDetailScreenBy(Object _actionVerb, Object posterName) {
    return '$_actionVerb，发布者：$posterName';
  }

  @override
  String sharedWorkoutDetailScreenExercises(Object _exercises) {
    return '$_exercises 个动作';
  }

  @override
  String sharedWorkoutDetailScreenMin(Object _duration) {
    return '$_duration 分钟';
  }

  @override
  String get sharedWorkoutDetailStarting => '正在开始...';

  @override
  String get sharedWorkoutDetailU2022 => '  •  ';

  @override
  String get sharedWorkoutDetailWorkoutDetails => '训练详情';

  @override
  String get signInReady => '准备就绪';

  @override
  String signInScreenSupportIsNowYour(Object appName) {
    return '$appName 支持团队现在是你的好朋友。随时联系我们寻求帮助！';
  }

  @override
  String signInScreenValue(Object progressPercent) {
    return '$progressPercent%';
  }

  @override
  String signInScreenWelcomeTo(Object appName) {
    return '欢迎使用 $appName！';
  }

  @override
  String signInScreenYourPlanDaysWeek(Object goalDisplay, Object quizData) {
    return '你的 $goalDisplay 计划 · $quizData 天/周';
  }

  @override
  String get signInSigningIn => '正在登录...';

  @override
  String skillProgressSummaryCardTotalPracticeSessions(Object totalAttempts) {
    return '共$totalAttempts次练习';
  }

  @override
  String get skillProgressSummaryMastered => '已掌握';

  @override
  String get skillProgressSummarySkillsStarted => '已开始的技能';

  @override
  String get skillProgressSummaryStepsUnlocked => '已解锁步骤';

  @override
  String get skillProgressSummaryYourProgress => '你的进度';

  @override
  String get skillProgressionsActiveProgressions => '进行中的进阶';

  @override
  String get skillProgressionsAllSkills => '所有技能';

  @override
  String get skillProgressionsBrowseSkills => '浏览技能';

  @override
  String get skillProgressionsChooseASkillProgression => '选择一个技能进阶，开始逐步掌握自重动作。';

  @override
  String get skillProgressionsDiscoverMoreSkills => '发现更多技能';

  @override
  String get skillProgressionsMasterBodyweightSkillsStep => '逐步掌握自重技能';

  @override
  String get skillProgressionsMyProgress => '我的进度';

  @override
  String get skillProgressionsNoSkillsInThis => '该类别下暂无技能';

  @override
  String get skillProgressionsSkillProgressions => '技能进阶';

  @override
  String get skillProgressionsSomethingWentWrong => '出错了';

  @override
  String get skillProgressionsStartYourJourney => '开启你的旅程';

  @override
  String get skillProgressionsTryAgain => '重试';

  @override
  String get skillsMasterBodyweightSkillsStep => '通过引导式进阶链，逐步掌握自重技能。';

  @override
  String get skillsSkillProgressions => '技能进阶';

  @override
  String sleepCorrelationCardPairedSessionsR(Object n, Object r) {
    return '$n 次配对训练 · r=$r';
  }

  @override
  String get sleepCorrelationCardSleepPace => '睡眠 × 配速';

  @override
  String get sleepDetail30DayTrend => '30天趋势';

  @override
  String get sleepDetailAvgNight => '每晚平均';

  @override
  String get sleepDetailBestNight => '最佳睡眠夜';

  @override
  String get sleepDetailCoachingTips => '教练建议';

  @override
  String get sleepDetailConnectHealth => '连接健康应用';

  @override
  String get sleepDetailConnectHealthToSee => '连接健康应用以查看睡眠数据';

  @override
  String get sleepDetailCouldNotLoadSleep => '无法加载睡眠数据。请下拉重试。';

  @override
  String get sleepDetailCouldNotSaveSleep => '无法保存睡眠目标。';

  @override
  String get sleepDetailCustomTrends => '自定义趋势';

  @override
  String get sleepDetailDebtRegularity => '睡眠债与规律性';

  @override
  String get sleepDetailEfficiency => '效率';

  @override
  String get sleepDetailFellAsleepIn => '入睡耗时';

  @override
  String get sleepDetailLast7Nights => '过去7晚';

  @override
  String get sleepDetailMonthlySummary => '月度总结';

  @override
  String get sleepDetailNap => '小睡';

  @override
  String get sleepDetailNightsWithNaps => '包含小睡的夜晚';

  @override
  String get sleepDetailNoSleepTrackedIn => '过去7晚未追踪到睡眠数据。';

  @override
  String get sleepDetailRegularity => '规律性';

  @override
  String get sleepDetailSaving => '正在保存…';

  @override
  String sleepDetailScreenAcrossTrackedNights(Object nightCount) {
    return '基于 $nightCount 个夜晚的追踪记录。';
  }

  @override
  String sleepDetailScreenHM(Object summary, Object summary1) {
    return '$summary小时 $summary1分钟';
  }

  @override
  String sleepDetailScreenHM2(Object summary, Object summary1) {
    return '$summary小时 $summary1分钟';
  }

  @override
  String sleepDetailScreenHM3(Object summary, Object summary1) {
    return '$summary小时 $summary1分钟';
  }

  @override
  String sleepDetailScreenMin(Object latencyMinutes) {
    return '$latencyMinutes 分钟';
  }

  @override
  String sleepDetailScreenNaps(Object length) {
    return '$length 次小睡';
  }

  @override
  String sleepDetailScreenValue(Object fmt, Object fmt1) {
    return '$fmt – $fmt1';
  }

  @override
  String sleepDetailScreenValue2(Object regularity) {
    return '$regularity / 100';
  }

  @override
  String get sleepDetailShortestNight => '最短睡眠夜';

  @override
  String get sleepDetailSleep => '睡眠';

  @override
  String get sleepDetailSleepDebt14d => '睡眠债 (14天)';

  @override
  String get sleepDetailSleepGoal => '睡眠目标';

  @override
  String get sleepDetailTrendUnavailable => '趋势不可用。';

  @override
  String get sleepDetailTwoOrMoreSynced => '需要同步至少两个夜晚的数据才能生成趋势图。';

  @override
  String get sleepHypnogramAwake => '清醒';

  @override
  String get sleepHypnogramDeep => '深睡';

  @override
  String get slowLoadIndicatorTryAgain => '重试';

  @override
  String smartInsightCardDays(Object n) {
    return '$n天';
  }

  @override
  String get smartInsightCardSmartInsight => '智能洞察';

  @override
  String get snappedEquipmentCouldnTReuseThat => '无法复用该快照。请重试。';

  @override
  String get snappedEquipmentNoMatchingExercisesFor => '没有匹配该设备的动作。';

  @override
  String get snappedEquipmentNoSnappedEquipmentYet => '暂无已识别的器械';

  @override
  String get snappedEquipmentTapTheCameraButton => '点击相机按钮以识别眼前的器械。';

  @override
  String get socialAutoScrollFeed => '自动滚动动态';

  @override
  String get socialAutoScrollStories => '自动滚动快拍';

  @override
  String get socialFeedOptions => '动态选项';

  @override
  String get socialFindFriends => '查找好友';

  @override
  String get socialMessages => '消息';

  @override
  String get socialMyPostsOnly => '仅显示我的帖子';

  @override
  String get socialPrivacyAllowChallengeInvites => '允许挑战邀请';

  @override
  String get socialPrivacyAllowFriendRequests => '允许好友请求';

  @override
  String get socialPrivacyAllowGeneratingShareableWor => '允许生成任何人均可打开的健身分享链接';

  @override
  String get socialPrivacyAppearInPublicAnd => '出现在公开和好友排行榜中';

  @override
  String get socialPrivacyChallengeInvites => '挑战邀请';

  @override
  String get socialPrivacyComments => '评论';

  @override
  String get socialPrivacyFriendActivity => '好友动态';

  @override
  String get socialPrivacyFriendRequests => '好友请求';

  @override
  String get socialPrivacyLetOthersInviteYou => '允许他人邀请你参加挑战';

  @override
  String get socialPrivacyLetOthersSeeWhen => '允许他人查看你是否已读消息';

  @override
  String get socialPrivacyLetOthersSendYou => '允许他人向你发送好友请求';

  @override
  String get socialPrivacyPrivateAccount => '私密账户';

  @override
  String get socialPrivacyPublicShareLinks => '公开分享链接';

  @override
  String get socialPrivacyReactions => '回应';

  @override
  String get socialPrivacyReadReceipts => '已读回执';

  @override
  String get socialPrivacyRequireApprovalForFollow => '关注请求需经批准';

  @override
  String get socialPrivacyShowOnLeaderboards => '在排行榜上显示';

  @override
  String get socialPrivacySocialNotifications => '社交通知';

  @override
  String get socialPrivacySocialPrivacy => '社交与隐私';

  @override
  String get socialPrivacyWhenFriendsCompleteWorkouts => '当好友完成健身或达成里程碑时';

  @override
  String get socialPrivacyWhenSomeoneCommentsOn => '当有人评论你的帖子时';

  @override
  String get socialPrivacyWhenSomeoneInvitesYou => '当有人邀请你参加挑战时';

  @override
  String get socialPrivacyWhenSomeoneReactsTo => '当有人回应你的帖子时';

  @override
  String get socialPrivacyWhenSomeoneSendsYou => '当有人向你发送好友请求时';

  @override
  String get socialRanks => '排名';

  @override
  String get socialScreenPartEnterAGroupName => '输入群组名称并选择至少 2 名成员';

  @override
  String get socialScreenPartFailedToCreateGroup => '创建群组失败';

  @override
  String get socialScreenPartFailedToLoad => '加载失败';

  @override
  String get socialScreenPartFailedToLoadFriends => '加载好友失败';

  @override
  String get socialScreenPartFailedToStartConversation => '开启对话失败';

  @override
  String get socialScreenPartGroupName => '群组名称';

  @override
  String get socialScreenPartMessages => '消息';

  @override
  String socialScreenPartMessagesScreenGroupCreated(Object name) {
    return '群组“$name”已创建';
  }

  @override
  String socialScreenPartMessagesScreenSelectMembersSelected(Object length) {
    return '选择成员（已选 $length 位）';
  }

  @override
  String get socialScreenPartNewGroup => '新建群组';

  @override
  String get socialScreenPartNewMessage => '新消息';

  @override
  String get socialScreenPartNoConversationsFound => '未找到对话';

  @override
  String get socialScreenPartNoFriendsToAdd => '没有可添加的好友';

  @override
  String get socialScreenPartNoFriendsToMessage => '没有可发送消息的好友';

  @override
  String get socialScreenPartNotLoggedIn => '未登录';

  @override
  String get socialSocial => '社交';

  @override
  String get socialSortBy => '排序方式';

  @override
  String get socialSortRecent => '最新';

  @override
  String get socialSortTop => '热门';

  @override
  String get socialSortTrending => '趋势';

  @override
  String get socialUserIdCopied => '用户 ID 已复制';

  @override
  String socialUsernameCopied(Object username) {
    return '用户名已复制：@$username';
  }

  @override
  String get sortOptionsClear => '清除';

  @override
  String get sortOptionsHighLow => '从高到低';

  @override
  String get sortOptionsLowHigh => '从低到高';

  @override
  String get sortOptionsRemoveFromSort => '从排序中移除';

  @override
  String get sortOptionsSortMenu => '排序菜单';

  @override
  String get sortOptionsTapAFieldTo => '点击字段进行排序。';

  @override
  String get soundNotificationsSoundNotifications => '声音与通知';

  @override
  String get soundSettingsCountdownSounds => '倒计时声音';

  @override
  String get soundSettingsCustomizeWorkoutSounds => '自定义健身声音';

  @override
  String get soundSettingsExerciseCompletion => '动作完成';

  @override
  String get soundSettingsPlaySoundWhenAll => '完成所有动作组时播放声音';

  @override
  String get soundSettingsPlaySoundWhenEntire => '整个健身结束时播放声音';

  @override
  String get soundSettingsPlaySoundWhenRest => '休息时间结束时播放声音';

  @override
  String get soundSettingsPlaySoundsDuringCountdown => '倒计时期间播放声音 (3, 2, 1)';

  @override
  String get soundSettingsRestTimerEnd => '休息计时结束';

  @override
  String get soundSettingsSound => '声音';

  @override
  String get soundSettingsSoundEffects => '音效';

  @override
  String get soundSettingsSoundVolume => '音量';

  @override
  String get soundSettingsTapToSelectLong => '点击选择。长按预览。';

  @override
  String get soundSettingsWorkoutCompletion => '健身完成';

  @override
  String get splitsChartSplits => '分段';

  @override
  String stackedBannerPanelCrateOpenedYouGot(Object rewardName) {
    return '🎁 宝箱已开启！你获得了 $rewardName';
  }

  @override
  String stackedBannerPanelCratesAvailable(Object displayCount) {
    return '有 $displayCount 个宝箱可用！';
  }

  @override
  String stackedBannerPanelCratesReadyToOpen(Object displayCount) {
    return '$displayCount 个宝箱待开启';
  }

  @override
  String get stackedBannerPanelDismissAll => '全部忽略';

  @override
  String get stackedBannerPanelDismissAnyway => '仍然忽略';

  @override
  String get stackedBannerPanelFailedToClaimCrate => '领取宝箱失败';

  @override
  String get stackedBannerPanelFollowUsOnInstagram => '在 Instagram 上关注我们';

  @override
  String get stackedBannerPanelGetHelpShareWins =>
      '在 Discord 上获取帮助、分享成就并提出功能建议';

  @override
  String get stackedBannerPanelJoinTheCommunity => '加入社区';

  @override
  String get stackedBannerPanelKeepItUp => '继续保持！';

  @override
  String stackedBannerPanelLbs(Object exerciseName, Object weightLbs) {
    return '$exerciseName：$weightLbs 磅';
  }

  @override
  String stackedBannerPanelMinExercises(
    Object durationMinutes,
    Object exercisesCount,
    Object missedDescription,
  ) {
    return '$missedDescription · $durationMinutes 分钟 · $exercisesCount 个动作';
  }

  @override
  String get stackedBannerPanelNewPr => '新的 PR！';

  @override
  String get stackedBannerPanelNoCratesAvailableRight => '目前没有可用的宝箱';

  @override
  String get stackedBannerPanelOpenAll => '全部打开';

  @override
  String get stackedBannerPanelOpenThemBeforeDismissing => '忽略前先打开它们吗？';

  @override
  String get stackedBannerPanelOpeningCrate => '正在开启宝箱...';

  @override
  String stackedBannerPanelRenewsInDaysFor(
    Object days,
    Object formattedAmount,
    Object tierLabel,
  ) {
    return '$tierLabel 将在 $days 天后以 $formattedAmount 续订';
  }

  @override
  String get stackedBannerPanelSubscriptionRenewing => '订阅续订中';

  @override
  String get stackedBannerPanelTapToRevisitYour => '点击回顾你的健身人格';

  @override
  String stackedBannerPanelValue(Object eventName, Object timeStr) {
    return '$eventName · $timeStr';
  }

  @override
  String stackedBannerPanelWorkoutTipsMealIdeas(Object marketingDomain) {
    return '训练技巧、饮食建议及社区精选 @$marketingDomain';
  }

  @override
  String stackedBannerPanelWorkoutsLifted(
    Object totalWorkouts,
    Object volumeStr,
  ) {
    return '$totalWorkouts 次训练 · 举起 $volumeStr';
  }

  @override
  String stackedBannerPanelWrapped(Object period) {
    return '/wrapped/$period';
  }

  @override
  String stackedBannerPanelWrapped2(Object month) {
    return '$month 年度总结';
  }

  @override
  String stackedBannerPanelWrapped3(Object period) {
    return '/wrapped/$period';
  }

  @override
  String stackedBannerPanelXXpActive(Object xpMultiplier) {
    return '$xpMultiplier 倍经验值加成中';
  }

  @override
  String get stackedBannerPanelYouHaveUnopenedCrates => '你有未开启的宝箱！';

  @override
  String stackedBannerPanelYouReAwayFrom(Object remaining, Object workoutWord) {
    return '距离本周目标还差 $remaining $workoutWord';
  }

  @override
  String stackedBannerPanelYourWrappedIsHere(Object month) {
    return '你的 $month 年度总结已送达';
  }

  @override
  String get stapleChoiceAddAs => '添加为';

  @override
  String get stapleChoiceAdvancedOptional => '进阶（可选）';

  @override
  String get stapleChoiceAllProfiles => '所有档案';

  @override
  String get stapleChoiceBand => '弹力带';

  @override
  String get stapleChoiceCustom => '自定义';

  @override
  String get stapleChoiceCustomizeOptional => '自定义（可选）';

  @override
  String get stapleChoiceDiscard => '放弃';

  @override
  String get stapleChoiceDiscardSelection => '放弃选择？';

  @override
  String get stapleChoiceDistance => '距离';

  @override
  String get stapleChoiceDotsYourWorkoutDays => '圆点 = 你的训练日';

  @override
  String get stapleChoiceDuration => '时长';

  @override
  String get stapleChoiceEGFocusOn => '例如：专注于顶峰收缩，慢速离心';

  @override
  String get stapleChoiceEveryDay => '每天';

  @override
  String get stapleChoiceGoBack => '返回';

  @override
  String get stapleChoiceHoldDuration => '保持时长';

  @override
  String get stapleChoiceIncline => '坡度';

  @override
  String get stapleChoiceMoreOptional => '更多（可选）';

  @override
  String get stapleChoiceNextWorkout => '下一次训练';

  @override
  String get stapleChoiceNotes => '备注';

  @override
  String get stapleChoiceReplaceAnExerciseIn => '替换今日训练中的一个动作';

  @override
  String get stapleChoiceReps => '次数';

  @override
  String get stapleChoiceRest => '休息';

  @override
  String get stapleChoiceRpeEffort => 'RPE（强度）';

  @override
  String get stapleChoiceSets => '组数';

  @override
  String get stapleChoiceSheetCardioSettings => '有氧设置';

  @override
  String get stapleChoiceSheetCouldNotLoadWorkout => '无法加载训练';

  @override
  String get stapleChoiceSheetDistance => '距离';

  @override
  String get stapleChoiceSheetDuration => '时长';

  @override
  String get stapleChoiceSheetIncline => '坡度';

  @override
  String get stapleChoiceSheetNoExercisesInWorkout => '训练中没有动作';

  @override
  String get stapleChoiceSheetNoWorkoutAvailable => '暂无可用训练';

  @override
  String get stapleChoiceSheetResistance => '阻力';

  @override
  String get stapleChoiceSheetSpeed => '速度';

  @override
  String get stapleChoiceSheetStrokeRate => '划桨频率';

  @override
  String get stapleChoiceSpeed => '速度';

  @override
  String get stapleChoiceSwapWithExercise => '替换动作';

  @override
  String get stapleChoiceTargetDays => '目标日期';

  @override
  String get stapleChoiceTempo => '节奏';

  @override
  String get stapleChoiceWeight => '重量';

  @override
  String get stapleChoiceWhenToApply => '应用时间';

  @override
  String get stapleChoiceWhichGymProfile => '选择健身档案';

  @override
  String get stapleChoiceWorkoutDays => '训练日';

  @override
  String get stapleChoiceYourExerciseWonT => '你的动作将不会被保存为固定动作。';

  @override
  String get stapleExercisesBikeSettings => '单车设置';

  @override
  String get stapleExercisesCardioSettings => '有氧设置';

  @override
  String get stapleExercisesDuration => '时长';

  @override
  String get stapleExercisesDurationSetsRest => '时长 / 组数 / 休息';

  @override
  String get stapleExercisesEG812 => '例如：8-12';

  @override
  String get stapleExercisesEllipticalSettings => '椭圆机设置';

  @override
  String get stapleExercisesHighlightedYourWorkoutDay => '高亮 = 你的训练日';

  @override
  String get stapleExercisesIncline => '坡度';

  @override
  String get stapleExercisesRemove => '移除';

  @override
  String get stapleExercisesRemoveStaple => '移除固定动作？';

  @override
  String get stapleExercisesReps => '次数';

  @override
  String get stapleExercisesResistance => '阻力';

  @override
  String get stapleExercisesRest => '休息';

  @override
  String get stapleExercisesRowerSettings => '划船机设置';

  @override
  String get stapleExercisesSaveChanges => '保存更改';

  @override
  String stapleExercisesScreenAddedAsAStaple(Object exerciseName) {
    return '已将 “$exerciseName” 添加为常驻动作';
  }

  @override
  String stapleExercisesScreenAddedAsAStaple2(Object name) {
    return '已将 “$name” 添加为常驻动作';
  }

  @override
  String get stapleExercisesScreenAllProfiles => '所有档案';

  @override
  String stapleExercisesScreenEdit(Object exerciseName) {
    return '编辑 “$exerciseName”';
  }

  @override
  String stapleExercisesScreenIsAlreadyAStaple(Object name) {
    return '“$name” 已是常驻动作';
  }

  @override
  String get stapleExercisesScreenRemove => '移除';

  @override
  String stapleExercisesScreenRemoveFromYourStaples(Object exerciseName) {
    return '确定要从常驻动作中移除 “$exerciseName” 吗？该动作在未来的训练中可能会被轮换掉。';
  }

  @override
  String get stapleExercisesScreenStretch => '拉伸';

  @override
  String stapleExercisesScreenUpdated(Object exerciseName) {
    return '已更新 “$exerciseName”';
  }

  @override
  String get stapleExercisesScreenWarmup => '热身';

  @override
  String get stapleExercisesSection => '部分';

  @override
  String get stapleExercisesSets => '组数';

  @override
  String get stapleExercisesSpeed => '速度';

  @override
  String get stapleExercisesStapleExercises => '固定动作';

  @override
  String get stapleExercisesStrokeRate => '划桨频率';

  @override
  String get stapleExercisesTargetDays => '目标日期';

  @override
  String get stapleExercisesTheseCoreLiftsWill =>
      '无论你的多样性设置如何，这些核心动作将永远不会从你的训练中被替换。';

  @override
  String get stapleExercisesTreadmillSettings => '跑步机设置';

  @override
  String get stapleExercisesWeight => '重量';

  @override
  String get stapleExercisesWeightSetsRepsRest => '重量 / 组数 / 次数 / 休息';

  @override
  String get startFast12h => '12h';

  @override
  String get startFastAdvanced => '进阶';

  @override
  String get startFastChooseAPlan => '选择计划';

  @override
  String get startFastChooseProtocolStartTime => '选择方案与开始时间';

  @override
  String get startFastDuration => '时长';

  @override
  String get startFastExtendedFasts24h => '长时断食 (24小时+)';

  @override
  String get startFastOrPickAProtocol => '或选择一种方案';

  @override
  String startFastSheetHours(Object _customHours) {
    return '$_customHours 小时';
  }

  @override
  String get startFastStartAFast => '开始断食';

  @override
  String get startFastStartFastNow => '立即开始断食';

  @override
  String get startFastStartNow => '立即开始';

  @override
  String get startFastStartTime => '开始时间';

  @override
  String get statsAchievementsTemplateAchievements => '成就';

  @override
  String get statsAchievementsTemplateAchievementsUnlocked => '已解锁成就';

  @override
  String get statsAchievementsTemplateDayStreak => '连续天数';

  @override
  String get statsLevelUpExperience => '经验值';

  @override
  String get statsLevelUpStreak => '连续天数';

  @override
  String statsOverviewTemplateDayStreak(Object currentStreak) {
    return '$currentStreak 天连胜';
  }

  @override
  String get statsOverviewTemplateMyStats => '我的数据';

  @override
  String get statsOverviewTemplateStreak => '连续天数';

  @override
  String get statsOverviewTemplateThisWeek => '本周';

  @override
  String get statsOverviewTemplateTotalTime => '总时长';

  @override
  String get statsOverviewTemplateWorkouts => '训练';

  @override
  String get statsPrsTemplateKeepPushingToSet => '继续努力，刷新纪录！';

  @override
  String get statsPrsTemplateNoPrsYet => '暂无个人纪录';

  @override
  String get statsPrsTemplatePersonalRecords => '个人纪录';

  @override
  String statsPrsTemplatePrs(Object totalPRCount) {
    return '$totalPRCount 项 PR';
  }

  @override
  String get statsRewardsBuildATrend => '建立趋势';

  @override
  String get statsRewardsCollectibles => '收藏品';

  @override
  String get statsRewardsCustomTrends => '自定义趋势';

  @override
  String get statsRewardsInsights => '洞察';

  @override
  String get statsRewardsInventory => '库存';

  @override
  String get statsRewardsItems => '物品';

  @override
  String get statsRewardsLeaderboard => '排行榜';

  @override
  String get statsRewardsOverlayAnyTwoMetrics => '叠加任意两项指标并查看相关性';

  @override
  String get statsRewardsProgress => '进度';

  @override
  String get statsRewardsRecapsPerks => '回顾与福利';

  @override
  String get statsRewardsRecognition => '认可';

  @override
  String get statsRewardsRewards => '奖励';

  @override
  String get statsRewardsSocial => '社交';

  @override
  String statsRewardsTabActive(Object activeChains) {
    return '$activeChains 个进行中';
  }

  @override
  String statsRewardsTabDone(Object completedChains) {
    return '$completedChains 个已完成';
  }

  @override
  String statsRewardsTabEarned(Object achievementsEarned) {
    return '$achievementsEarned 个已获得';
  }

  @override
  String statsRewardsTabPrsLastWeek(Object prs) {
    return '上周 $prs 项 PR';
  }

  @override
  String statsRewardsTabPts(Object achievementsPoints) {
    return '$achievementsPoints 分';
  }

  @override
  String statsRewardsTabReady(Object unclaimedRewards) {
    return '$unclaimedRewards 个待领取';
  }

  @override
  String statsRewardsTabWorkouts(Object workouts) {
    return '$workouts 次训练';
  }

  @override
  String get statsStreakFireDayStreak => '连续天数';

  @override
  String get statsStreakFireLongest => '最长纪录';

  @override
  String get statsStreakFireTotal => '总计';

  @override
  String get statsTemplateCalories => '卡路里';

  @override
  String get statsTemplateDuration => '时长';

  @override
  String get statsTemplateVolume => '容量';

  @override
  String get statsTemplateWorkoutComplete => '训练完成';

  @override
  String get statsWeeklyReportCompleted => '已完成';

  @override
  String get statsWeeklyReportCompletion => '完成度';

  @override
  String get statsWeeklyReportReportCard => '成绩单';

  @override
  String get statsWeeklyReportStreak => '连续天数';

  @override
  String statsWeeklyReportTemplateDays(Object currentStreak) {
    return '$currentStreak 天';
  }

  @override
  String statsWeeklyReportTemplateValue(Object _completionPercent) {
    return '$_completionPercent%';
  }

  @override
  String statsWeeklyReportTemplateWorkouts(Object totalWorkouts) {
    return '$totalWorkouts 次锻炼';
  }

  @override
  String get statsWeeklyReportWeekly => '每周';

  @override
  String get stepGoalCardGoalReached => '已达成目标';

  @override
  String get stepGoalCardGoalReachedGreatJob => '目标已达成！做得好！';

  @override
  String stepGoalCardStepGoalProgressOf(
    Object currentSteps,
    Object goalSteps,
    Object percentage,
  ) {
    return '步数目标进度：已完成 $currentSteps/$goalSteps 步，完成 $percentage%';
  }

  @override
  String get stepGoalCardSteps => '步数';

  @override
  String stepGoalCardValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String get stepGoalEditorAutomaticallyIncreasesYourG => '随着你的进步自动增加目标';

  @override
  String get stepGoalEditorQuickSelect => '快速选择';

  @override
  String get stepGoalEditorSaveGoal => '保存目标';

  @override
  String get stepGoalEditorSetStepGoal => '设置步数目标';

  @override
  String stepGoalEditorSheetSaveGoalOfSteps(Object _selectedGoal) {
    return '保存 $_selectedGoal 步的目标';
  }

  @override
  String stepGoalEditorSheetSelectedGoalSteps(Object _selectedGoal) {
    return '已选目标：$_selectedGoal 步';
  }

  @override
  String stepGoalEditorSheetStepGoalSliderFrom(
    Object _maxGoal,
    Object _minGoal,
  ) {
    return '步数目标滑块，从 $_minGoal 到 $_maxGoal 步';
  }

  @override
  String stepGoalEditorSheetSteps(Object _selectedGoal) {
    return '$_selectedGoal 步';
  }

  @override
  String get stepGoalEditorStepsPerDay => '步/天';

  @override
  String get stepGoalEditorUseProgressiveGoal => '使用进阶目标';

  @override
  String get stepGoalEditorWhenYouHitYour =>
      '当你连续5天达成目标时，我们会将目标增加500步。若错过3天，目标将重置为基础目标。';

  @override
  String stepsCounterCardConnect(Object sourceLabel) {
    return '连接 $sourceLabel';
  }

  @override
  String stepsCounterCardDailyGoalReachedVia(Object sourceLabel) {
    return '已达成每日目标 🎉 · 通过 $sourceLabel';
  }

  @override
  String get storiesRingYourStory => '你的故事';

  @override
  String get storyCreateAddACaption => '添加说明...';

  @override
  String get storyCreateCamera => '相机';

  @override
  String get storyCreateGallery => '相册';

  @override
  String get storyCreateNewStory => '发布新故事';

  @override
  String get storyCreateShareAMoment => '分享精彩瞬间';

  @override
  String get storyCreateShareStory => '分享故事';

  @override
  String get storyCreateUploading => '上传中...';

  @override
  String get storyCreateYourStoryWillBe => '你的故事将展示24小时';

  @override
  String get storyViewerNoStories => '暂无故事';

  @override
  String get strainCoachCardConnect => '连接';

  @override
  String get strainCoachCardConnectHealthForAn => '连接健康数据以获取强度建议。';

  @override
  String get strainCoachCardTodaySIntensity => '今日强度';

  @override
  String get strainDashboardCompleteSomeWorkoutsTo => '完成一些训练以查看你的压力预防洞察。';

  @override
  String get strainDashboardFailedToLoadData => '数据加载失败';

  @override
  String get strainDashboardNoStrainDataYet => '暂无压力数据';

  @override
  String get strainDashboardOverallStatus => '总体状态';

  @override
  String get strainDashboardStrainPrevention => '压力预防';

  @override
  String get strainDashboardViewHistory => '查看历史记录';

  @override
  String get strainDashboardVolumeAlerts => '容量提醒';

  @override
  String strainRiskCardKg(Object currentVolumeKg) {
    return '$currentVolumeKg kg';
  }

  @override
  String strainRiskCardOfKgCap(Object volumeCapKg) {
    return '/ $volumeCapKg kg 上限';
  }

  @override
  String strainRiskCardPercentOverCap(Object percent) {
    return '超出上限 $percent%';
  }

  @override
  String strainRiskCardPercentVsLastWeek(Object signedPercent) {
    return '较上周 $signedPercent%';
  }

  @override
  String get strainRiskCardTooFast => '过快';

  @override
  String streakBadgesBestDays(Object longestStreak) {
    return '最高纪录：$longestStreak 天';
  }

  @override
  String streakBadgesDayStreak(Object currentStreak) {
    return '$currentStreak 天连胜';
  }

  @override
  String get streakBadgesHitYourGoalTo => '达成目标以开启连续记录！';

  @override
  String streakBadgesMoreDaysToBronze(Object currentStreak) {
    return '再坚持 $currentStreak 天即可获得青铜勋章！';
  }

  @override
  String get streakBadgesNewBest => '新纪录！';

  @override
  String get streakExplainerGotIt => '知道了';

  @override
  String get streakExplainerHowTheStreakWorks => '连续记录规则';

  @override
  String get streakExplainerStreakFreezes => '连续记录冻结';

  @override
  String get streakExplainerUseFreeze => '使用补签卡';

  @override
  String get streakExplainerYourStreak => '你的连胜';

  @override
  String get streakMilestoneDays => 'DAYS';

  @override
  String streakMilestoneDaysToGo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还剩 $count 天！',
    );
    return '$_temp0';
  }

  @override
  String get streakMilestoneKeepTheStreakGoing => '保持连胜！';

  @override
  String streakMilestoneNextBadgeName(Object name) {
    return '下一个：$name';
  }

  @override
  String streakMilestonePreviewDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '$_temp0';
  }

  @override
  String get streakMilestoneRare => 'RARE';

  @override
  String get streakMilestoneRewards => '奖励';

  @override
  String get streakMilestoneStreakMilestone => '连胜里程碑！';

  @override
  String get streakMilestoneToGo => ') 即可达成！';

  @override
  String get streakMilestoneYouVeReachedThe => '你已达到终极连胜里程碑！';

  @override
  String streakSavedDialogWeUsedStreakShield(Object savedStreakCount) {
    return '我们使用了1个连胜保护盾，以保持你的$savedStreakCount天连胜。';
  }

  @override
  String get streakSavedKeepItGoing => '继续保持';

  @override
  String get streakSavedStreakSaved => '连胜已保存！';

  @override
  String get strengthBestLift => '最佳动作';

  @override
  String get strengthChartStrengthTrends => '力量趋势';

  @override
  String get strengthContributionToScore => '对评分的贡献';

  @override
  String get strengthExercisesPrs => '训练动作与 PR';

  @override
  String get strengthFitnessScore => '健身评分';

  @override
  String get strengthMuscleAnalytics => '肌肉分析';

  @override
  String get strengthOverviewCardCheckIn => '签到';

  @override
  String get strengthOverviewCardCompleteWorkoutsWithResista =>
      '完成抗阻训练\n以追踪你的力量进度。';

  @override
  String get strengthOverviewCardDragU2630ToReorder => '拖动 ☰ 以重新排序 · 点击图钉以置顶';

  @override
  String get strengthOverviewCardHowAreYouFeeling => '你今天感觉如何？';

  @override
  String get strengthOverviewCardHowScoresWork => '评分机制';

  @override
  String get strengthOverviewCardHowStrengthScoresWork => '力量评分机制';

  @override
  String get strengthOverviewCardLevels => '等级';

  @override
  String get strengthOverviewCardMax => '最大值';

  @override
  String get strengthOverviewCardMin => '最小值';

  @override
  String get strengthOverviewCardMuscle => '肌肉';

  @override
  String get strengthOverviewCardNoStrengthDataYet => '暂无力量数据';

  @override
  String get strengthOverviewCardOptimal => '最佳';

  @override
  String get strengthOverviewCardOverallScoreHeroRing => '综合评分 (Hero Ring)';

  @override
  String get strengthOverviewCardReadiness => '准备状态';

  @override
  String get strengthOverviewCardRecalculate => '重新计算';

  @override
  String get strengthOverviewCardScoreIsCalculatedFrom =>
      '评分基于你过去 90 天内每个肌群的最佳训练组（重量 x 次数）计算得出。体重比越高，评分越高。';

  @override
  String get strengthOverviewCardScoresUpdateAutomaticallyAf =>
      '评分会在每次训练后自动更新。仅计入抗阻训练动作，导入的有氧运动不会影响评分。';

  @override
  String get strengthOverviewCardStrengthScore => '力量评分';

  @override
  String get strengthOverviewCardTheRingDisplaysA =>
      '圆环显示了你所有肌群评分的加权平均值。1RM 是根据你过去 90 天内记录的最佳训练组，通过 Brzycki/Epley/Lombardi 公式平均值估算的。';

  @override
  String get strengthOverviewCardTrainingStatus => '训练状态';

  @override
  String strengthOverviewCardUiMuscleGroups(Object length) {
    return '$length 个肌群';
  }

  @override
  String get strengthOverviewCardValuesAreForIntermediate =>
      '数值适用于中级训练者，并会根据你的训练水平自动调整。状态也会参考你的准备状态签到。';

  @override
  String get strengthOverviewCardVolumeGuidelinesSetsWeek => '训练量指南（组数/周）';

  @override
  String get strengthOverviewCardYourOverallFitnessScore =>
      '你的综合健身评分加权如下：\n力量 40% + 持续性 30% + 营养 20% + 准备状态 10%';

  @override
  String get strengthOverviewCardYourStrengthScore0 =>
      '你的力量评分 (0-100) 用于衡量你相对于体重的举重能力，并与既定标准进行对比。';

  @override
  String get strengthRecentPersonalRecords => '近期个人纪录';

  @override
  String get strengthScoreCardTitle => '力量评分';

  @override
  String get stretchControllerComplete => '完成';

  @override
  String get stretchControllerCoolDown => '冷身';

  @override
  String get stretchControllerPause => '暂停';

  @override
  String get stretchControllerResume => '继续';

  @override
  String get stretchControllerSkipAll => '跳过全部';

  @override
  String get stretchControllerStartTimer => '开始计时';

  @override
  String get stretchControllerUpNext => '接下来';

  @override
  String get stretchPhaseCoolDown => '冷身';

  @override
  String get stretchPhaseFinish => '结束';

  @override
  String get stretchPhaseGreatJobTimeTo => '做得好！是时候拉伸和恢复了。';

  @override
  String get stretchPhasePause => '暂停';

  @override
  String stretchPhaseScreenSec(Object duration) {
    return '$duration 秒';
  }

  @override
  String get stretchPhaseSkipAll => '跳过全部';

  @override
  String get stretchPhaseUpNext => '接下来';

  @override
  String get subscriptionManagementBillingInformation => '账单信息';

  @override
  String get subscriptionManagementCouldNotOpenSubscription => '无法打开订阅设置';

  @override
  String get subscriptionManagementFailedToLoadSubscription => '无法加载订阅';

  @override
  String get subscriptionManagementGetUnlimitedWorkoutsAi =>
      '获取无限训练、AI 教练及更多功能';

  @override
  String get subscriptionManagementManageSubscription => '管理订阅';

  @override
  String get subscriptionManagementNoBillingInformationAvailab => '无可用账单信息';

  @override
  String get subscriptionManagementPurchasesRestoredSuccessfull => '购买记录恢复成功';

  @override
  String get subscriptionManagementRequestRefund => '申请退款';

  @override
  String get subscriptionManagementRestorePurchases => '恢复购买';

  @override
  String get subscriptionManagementScreenAccessNeverExpires => '访问权限永不过期';

  @override
  String get subscriptionManagementScreenCancelAutoRenewal => '取消自动续订';

  @override
  String get subscriptionManagementScreenCancelSubscription => '取消订阅';

  @override
  String subscriptionManagementScreenFailedToPauseSubscription(Object e) {
    return '暂停订阅失败：$e';
  }

  @override
  String subscriptionManagementScreenFailedToResumeSubscription(Object e) {
    return '恢复订阅失败：$e';
  }

  @override
  String get subscriptionManagementScreenLeftInTrial => '试用剩余时间';

  @override
  String get subscriptionManagementScreenLifetime => '终身会员';

  @override
  String get subscriptionManagementScreenManageSubscription => '管理订阅';

  @override
  String get subscriptionManagementScreenPauseSubscription => '暂停订阅';

  @override
  String get subscriptionManagementScreenResumeSubscription => '恢复订阅';

  @override
  String get subscriptionManagementScreenStartBillingAgain => '重新开始计费';

  @override
  String subscriptionManagementScreenSubscriptionPausedForDays(
    Object durationDays,
  ) {
    return '订阅已暂停 $durationDays 天';
  }

  @override
  String get subscriptionManagementScreenTakeABreakFor => '最多可暂停 3 个月';

  @override
  String get subscriptionManagementScreenTrialEnded => '试用已结束';

  @override
  String get subscriptionManagementSubmitARefundRequest => '提交退款申请';

  @override
  String get subscriptionManagementSubscriptionPaused => '订阅已暂停';

  @override
  String get subscriptionManagementSubscriptionResumedSuccessfu => '订阅已成功恢复';

  @override
  String get subscriptionManagementSyncWithAppStore =>
      '与 App Store / Play Store 同步';

  @override
  String get subscriptionManagementUnknownError => '未知错误';

  @override
  String get subscriptionManagementUpgradeToPremium => '升级至 Premium';

  @override
  String get subscriptionManagementViewPlans => '查看方案';

  @override
  String get suggestFeatureCategory => '类别';

  @override
  String get suggestFeatureDescribeYourFeatureIdea => '详细描述你的功能建议...';

  @override
  String get suggestFeatureDescription => '描述';

  @override
  String get suggestFeatureEGSocialWorkout => '例如：社交训练分享';

  @override
  String get suggestFeatureFeatureSuggestionSubmittedS => '功能建议提交成功！';

  @override
  String get suggestFeatureFeatureTitle => '功能标题';

  @override
  String suggestFeatureSheetYouVeUsedAll(Object used) {
    return '你已使用 $used 个建议中的全部 $used 个。请改为对现有功能进行投票！';
  }

  @override
  String get suggestFeatureSubmitSuggestion => '提交建议';

  @override
  String get suggestFeatureSuggestAFeature => '建议新功能';

  @override
  String get suggestFeatureYouHaveReachedThe => '您最多只能提交 2 条功能建议';

  @override
  String get suggestedReplyChipsBodyweightVersion => '自重版本';

  @override
  String get suggestedReplyChipsCycleadjusted => 'cycleAdjusted';

  @override
  String get suggestedReplyChipsHowShouldITrain => '这个阶段我该如何训练？';

  @override
  String get suggestedReplyChipsILlDoIt => '我今晚还是会做';

  @override
  String get suggestedReplyChipsKeepPlanned => '保持原计划';

  @override
  String get suggestedReplyChipsLogASnack => '记录零食';

  @override
  String get suggestedReplyChipsLogBreakfast => '记录早餐';

  @override
  String get suggestedReplyChipsLogWater => '记录饮水';

  @override
  String get suggestedReplyChipsMoveToTomorrow => '移至明天';

  @override
  String get suggestedReplyChipsPlanTomorrow => '规划明天';

  @override
  String get suggestedReplyChipsPreworkoutfuelgap => 'preWorkoutFuelGap';

  @override
  String get suggestedReplyChipsQuickCheck => '快速检查';

  @override
  String get suggestedReplyChipsRecapDetails => '回顾详情';

  @override
  String get suggestedReplyChipsRecoverylighter => 'recoveryLighter';

  @override
  String get suggestedReplyChipsStartAnyway => '直接开始';

  @override
  String get suggestedReplyChipsSwitchToLighter => '切换为轻量版';

  @override
  String get suggestedReplyChipsWhatSNext => '接下来做什么？';

  @override
  String get suggestedReplyChipsWhy => '为什么？';

  @override
  String get suggestedReplyChipsWindDown => '放松休息';

  @override
  String get suggestionCardAccept => '接受';

  @override
  String get suggestionCardAcceptGoal => '接受目标';

  @override
  String get suggestionCardNotNow => '暂不';

  @override
  String get suggestionCardTarget => '目标';

  @override
  String get suggestionCardWhyThisGoal => '为什么是这个目标？';

  @override
  String get suggestionCarouselCouldNotLoadSuggestions => '无法加载建议';

  @override
  String get suggestionCarouselSuggestedGoals => '建议目标';

  @override
  String get summaryAiBreathingGuide => '呼吸指导';

  @override
  String get summaryAiCoachOpened => '已打开教练';

  @override
  String get summaryAiCoachTips => '教练建议';

  @override
  String get summaryAiExerciseSwaps => '动作替换';

  @override
  String get summaryAiFatigueAlerts => '疲劳提醒';

  @override
  String get summaryAiInfoOpened => '已查看详情';

  @override
  String get summaryAiInteractions => 'AI 互动';

  @override
  String get summaryAiMessagesSent => '已发送消息';

  @override
  String get summaryAiRestSuggestions => '休息建议';

  @override
  String get summaryAiTipsDismissed => '已忽略建议';

  @override
  String get summaryAiVideosWatched => '已观看视频';

  @override
  String get summaryAiWeightSuggestions => '重量建议';

  @override
  String get summaryAllExercisesCompleted => '所有动作已完成';

  @override
  String get summaryAtlasBack => 'BACK';

  @override
  String get summaryAtlasFront => 'FRONT';

  @override
  String get summaryAvgExercises => '平均（动作数）';

  @override
  String get summaryAvgRir => '平均 RIR';

  @override
  String get summaryAvgRpe => '平均 RPE';

  @override
  String get summaryAvgSets => '平均（组数）';

  @override
  String summaryBestSet(Object reps, Object weight) {
    return '最佳组: $weight lb x $reps';
  }

  @override
  String get summaryCardBestStreak => '最佳连胜';

  @override
  String get summaryCardHours => '小时';

  @override
  String get summaryCardPrs => 'PRs';

  @override
  String get summaryCardShareYourWrapped => '分享您的年度总结';

  @override
  String get summaryCardVolumeLbs => '训练总量 (lbs)';

  @override
  String get summaryCardYourMonthInReview => '本月回顾';

  @override
  String get summaryCardioSession => '有氧训练';

  @override
  String get summaryCardsPrs => 'PRs';

  @override
  String get summaryCardsStreak => '连胜';

  @override
  String get summaryCardsVolume => '训练总量';

  @override
  String get summaryCoachLabel => 'COACH';

  @override
  String get summaryColPrev => '上次';

  @override
  String get summaryColReps => '次数';

  @override
  String get summaryColRir => 'RIR';

  @override
  String get summaryColRpe => 'RPE';

  @override
  String get summaryColSet => '组数';

  @override
  String get summaryColTarget => '目标';

  @override
  String get summaryColWeight => '重量';

  @override
  String get summaryDonutIntensity => '强度';

  @override
  String get summaryDonutOnTarget => '达标';

  @override
  String get summaryDonutPlanAdherence => '计划执行度';

  @override
  String get summaryDonutRestCompliance => '休息合规度';

  @override
  String get summaryDuration => '时长';

  @override
  String get summaryEpleyFormula => '基于你最佳组数的 Epley 公式计算';

  @override
  String summaryEquipmentIncrement(Object name) {
    return '$name 增量';
  }

  @override
  String summaryEst1RM(Object value) {
    return '预估 1RM: $value lb';
  }

  @override
  String get summaryEstimated1RM => '预估 1RM';

  @override
  String get summaryEverySetRated => '每组均已评分';

  @override
  String get summaryExerciseOrderAndTime => '动作顺序与时间';

  @override
  String get summaryExerciseTableNoNotesOrPhotos => '此组未保存任何笔记或照片。';

  @override
  String get summaryExerciseTableNoNotesSavedOn => '此组未保存任何笔记。';

  @override
  String summaryExerciseTableNotes(Object n) {
    return '$n 条备注';
  }

  @override
  String get summaryExerciseTablePrevious => '上次';

  @override
  String get summaryExerciseTableReps => '次数';

  @override
  String get summaryExerciseTableSet => '组数';

  @override
  String summaryExerciseTableSetNotes(Object setNumber) {
    return '第 $setNumber 组备注';
  }

  @override
  String get summaryExerciseTableSkipped => '已跳过';

  @override
  String get summaryExerciseTableTarget => '目标';

  @override
  String get summaryExitExercisesDone => '已完成动作';

  @override
  String get summaryExitProgress => '进度';

  @override
  String get summaryExitTimeSpent => '耗时';

  @override
  String get summaryFeedbackConfidence => '自信度';

  @override
  String get summaryFeedbackEnergy => '精力';

  @override
  String get summaryFeedbackFeelingStronger => '感觉更强';

  @override
  String get summaryFeedbackMood => '心情';

  @override
  String get summaryHideDetails => '收起详情';

  @override
  String get summaryHowYouFelt => '训练感受';

  @override
  String get summaryHydration => '补水';

  @override
  String get summaryHydrationLabel => '补水';

  @override
  String get summaryIntensityAnalysis => '强度分析';

  @override
  String get summaryIntensityEasy => '轻松';

  @override
  String get summaryIntensityHard => '困难';

  @override
  String get summaryIntensityMaximal => '极限';

  @override
  String get summaryIntensityModerate => '中等';

  @override
  String get summaryIntensityVeryHard => '非常困难';

  @override
  String get summaryMoreDetails => '更多详情';

  @override
  String get summaryMuscleMapNotApplicable => '不适用肌肉分布图';

  @override
  String get summaryMusclesHit => '目标肌群';

  @override
  String summaryNSets(Object count) {
    return '$count 组';
  }

  @override
  String summaryNSkipped(Object count) {
    return '跳过 $count 个';
  }

  @override
  String get summaryNoCompletedSets => '本次训练没有已完成的组数记录。';

  @override
  String get summaryNoDetailedData => '本次训练暂无详细追踪数据。';

  @override
  String get summaryNoPlanData => '无计划数据';

  @override
  String get summaryNoRestData => '无休息数据';

  @override
  String get summaryNoRirLogged => '未记录 RIR';

  @override
  String get summaryNoVolumeData => '暂无容量数据';

  @override
  String get summaryNoWorkingSets => '无正式组';

  @override
  String get summaryOutOf100 => '满分 100';

  @override
  String get summaryPeakRpe => '峰值 RPE';

  @override
  String get summaryPerExercise => '按动作';

  @override
  String get summaryPerExerciseDeepDive => '单项动作深度分析';

  @override
  String get summaryPerExerciseDeepDiveLabel => '单项动作深度分析';

  @override
  String get summaryPerformanceComparison => '表现对比';

  @override
  String get summaryReps => '次数';

  @override
  String summaryRepsLeft(Object count) {
    return '剩余 $count 次';
  }

  @override
  String get summaryRestAnalysis => '休息分析';

  @override
  String get summaryRingEffort => '努力程度';

  @override
  String get summaryRingPlan => '计划';

  @override
  String get summaryRingRest => '休息';

  @override
  String get summaryRpeDistribution => 'RPE 分布';

  @override
  String get summarySessionScore => '训练评分';

  @override
  String get summarySessionTimeline => '训练时间轴';

  @override
  String get summarySetTypeDistribution => '组类型分布';

  @override
  String get summarySets => '组数';

  @override
  String get summarySettingsUsed => '所用设置';

  @override
  String get summaryStretching => '拉伸';

  @override
  String get summarySupersetDetails => '超级组详情';

  @override
  String summarySupersetN(Object id) {
    return '超级组 $id';
  }

  @override
  String summaryTagMuscles(Object exercises) {
    return '标记肌肉 · $exercises';
  }

  @override
  String get summaryTiming => '时间安排';

  @override
  String get summaryTotalRest => '总休息时间';

  @override
  String get summaryTotalVolumeLabel => '总容量: ';

  @override
  String get summaryVolume => '容量';

  @override
  String get summaryVolumeBreakdown => '容量分析';

  @override
  String summaryVsDaysAgo(Object days) {
    return '对比 $days 天前';
  }

  @override
  String get summaryWarmup => '热身';

  @override
  String get summaryWarmupStretching => '热身与拉伸';

  @override
  String get summaryWeightUnit => '重量单位';

  @override
  String get summaryWorkoutEndedEarly => '训练提前结束';

  @override
  String get supersetAlgorithmCardAddFavoritePair => '添加收藏组合';

  @override
  String get supersetAlgorithmCardAddPair => '添加组合';

  @override
  String get supersetAlgorithmCardAddYourGoTo => '添加您常用的动作组合';

  @override
  String get supersetAlgorithmCardEGBenchPress => '例如：卧推';

  @override
  String get supersetAlgorithmCardEGBentOver => '例如：俯身划船';

  @override
  String get supersetAlgorithmCardEnterTwoExercisesYou => '输入您想要超级组训练的两个动作';

  @override
  String get supersetAlgorithmCardFavoritePairs => '收藏组合';

  @override
  String get supersetAlgorithmCardFineTuneSupersetGeneration => '微调超级组生成';

  @override
  String get supersetAlgorithmCardFirstExercise => '第一个动作';

  @override
  String get supersetAlgorithmCardNoFavoritePairsYet => '暂无收藏组合';

  @override
  String supersetAlgorithmCardSaved(Object length) {
    return '已保存 $length 个';
  }

  @override
  String get supersetAlgorithmCardSecondExercise => '第二个动作';

  @override
  String get supersetAlgorithmCardSupersetAlgorithm => '超级组算法';

  @override
  String get supersetCreate => '创建超级组';

  @override
  String get supersetCreatePair => '创建超级组';

  @override
  String supersetExerciseN(Object n) {
    return '动作 $n';
  }

  @override
  String get supersetExercisePickerAddExercisesToYour => '请先将动作添加到您的训练中';

  @override
  String get supersetExercisePickerSearchExercises => '搜索动作...';

  @override
  String get supersetIndicatorBreak => '休息';

  @override
  String get supersetIndicatorCreateSuperset => '创建超级组';

  @override
  String get supersetIndicatorNoRestBetween => '组间无休息';

  @override
  String get supersetIndicatorSelectTwoExercisesTo => '选择两个动作进行组合';

  @override
  String supersetIndicatorSs(Object groupNumber) {
    return 'SS$groupNumber';
  }

  @override
  String supersetIndicatorSuperset(Object groupNumber) {
    return '超级组 SUPERSET $groupNumber';
  }

  @override
  String get supersetIndicatorSwap => '交换';

  @override
  String get supersetIndicatorTapTheFirstExercise => '点击第一个动作';

  @override
  String get supersetPairSheetClear => '清除';

  @override
  String get supersetPairSheetCreateSuperset => '创建超级组';

  @override
  String get supersetPairSheetCreateSupersetPair => '创建超级组组合';

  @override
  String get supersetPairSheetPairTwoExercisesFor => '组合两个动作以提高训练效率';

  @override
  String supersetPairSheetPartSupersetPairSheetStateValue(
    Object name,
    Object name1,
  ) {
    return '$name + $name1';
  }

  @override
  String get supersetPairSheetRestAfterSuperset => '超级组后休息';

  @override
  String get supersetPairSheetRestBetweenExercises => '动作间休息';

  @override
  String get supersetPairSheetRestSettings => '休息设置';

  @override
  String get supersetPairSheetReuseThisPairIn => '在未来的训练中重复使用此组合';

  @override
  String get supersetPairSheetSaveToFavorites => '保存到收藏';

  @override
  String get supersetPairSheetSelectExercise1 => '选择动作 1';

  @override
  String get supersetPairSheetSelectExercise2 => '选择动作 2';

  @override
  String get supersetPairSheetSuggestedPairs => '建议组合';

  @override
  String get supersetPairSheetSupersetType => '超级组类型';

  @override
  String get supersetPairSheetTapToSelect => '点击选择';

  @override
  String get supersetPairSubtitle => '将两个动作配对，交替进行以缩短休息时间';

  @override
  String get supersetReorderASupersetNeedsAt => '超级组至少需要 2 个动作';

  @override
  String get supersetReorderApplyChanges => '应用更改';

  @override
  String get supersetReorderDragToReorderSwipe => '拖动以重新排序，向左滑动以移除';

  @override
  String get supersetReorderNoChanges => '无更改';

  @override
  String get supersetReorderNoRestBetween => '组间无休息';

  @override
  String get supersetReorderRemove => '移除';

  @override
  String get supersetReorderReset => '重置';

  @override
  String supersetReorderSheetEdit(
    Object _originalTypeLabel,
    Object groupNumber,
  ) {
    return '编辑 $_originalTypeLabel $groupNumber';
  }

  @override
  String get supersetRestAfter => '超级组后休息';

  @override
  String get supersetRestBetween => '动作间休息';

  @override
  String get supersetRestSettings => '休息设置';

  @override
  String get supersetSaveToFavorites => '保存到收藏';

  @override
  String get supersetSaveToFavoritesSubtitle => '保存此组合以便快速重复使用';

  @override
  String get supersetSettingsAutoGenerateSupersets => '自动生成超级组';

  @override
  String get supersetSettingsChestBackBicepsTriceps => '胸/背，二头/三头配对';

  @override
  String get supersetSettingsControlHowSupersetsAre => '控制 AI 如何在你的训练中生成超级组';

  @override
  String get supersetSettingsIncludeSupersetPairsIn => '在 AI 生成的训练中包含超级组配对';

  @override
  String get supersetSettingsPreferAntagonistPairs => '优先选择拮抗肌配对';

  @override
  String get supersetSettingsSupersetSettings => '超级组设置';

  @override
  String get supersetSuggestedPairs => '推荐配对';

  @override
  String get supersetTapToSelect => '点击选择';

  @override
  String get supersetType => '类型';

  @override
  String get syncDetailsAllSynced => '已全部同步！';

  @override
  String get syncDetailsDiscard => '放弃';

  @override
  String get syncDetailsDiscardThisChange => '放弃此更改？';

  @override
  String get syncDetailsDiscarded => '已放弃';

  @override
  String get syncDetailsExport => '导出';

  @override
  String get syncDetailsNoFailedSyncItems => '没有同步失败的项目。';

  @override
  String get syncDetailsRetryAll => '重试全部';

  @override
  String get syncDetailsRetrying => '正在重试...';

  @override
  String syncDetailsScreenLatest(Object first) {
    return '最新：$first';
  }

  @override
  String syncDetailsScreenRetries(Object retryCount) {
    return '$retryCount 次重试';
  }

  @override
  String get syncDetailsSyncDetails => '同步详情';

  @override
  String get syncDetailsThisErrorWonT => '此错误无法通过重试解决。请使用“编辑并重新登录”或“放弃”。';

  @override
  String get syncStatusSyncNow => '立即同步';

  @override
  String get syncStatusSyncing => '正在同步...';

  @override
  String get syncedSummaryAvgHr => '平均心率';

  @override
  String get syncedSummaryCalories => '卡路里';

  @override
  String get syncedSummaryDistance => '距离';

  @override
  String get syncedSummaryDuration => '时长';

  @override
  String get syncedSummaryMaxHr => '最大心率';

  @override
  String get syncedSummaryNoActivityMetricsWere => '本次训练未捕获到活动指标。';

  @override
  String get syncedSummarySyncedActivity => '已同步活动';

  @override
  String syncedSummaryViewActivity(Object platform) {
    return '$platform 活动';
  }

  @override
  String syncedSummaryViewBpm(Object avgHr) {
    return '$avgHr bpm';
  }

  @override
  String syncedSummaryViewBpm2(Object maxHr) {
    return '$maxHr bpm';
  }

  @override
  String syncedSummaryViewM(Object duration) {
    return '$duration 分钟';
  }

  @override
  String syncedSummaryViewSessionsOpenOnYour(Object platform) {
    return '会话 — 在您的设备上打开 $platform 以查看';
  }

  @override
  String syncedSummaryViewSyncedFrom(Object platform) {
    return '同步自 $platform';
  }

  @override
  String syncedSummaryViewThisWorkoutWasImported(Object platform) {
    return '本次训练导入自 $platform。Zealova ';
  }

  @override
  String get syncedWorkoutDetailActiveCal => '活动卡路里';

  @override
  String get syncedWorkoutDetailAvg => '平均';

  @override
  String get syncedWorkoutDetailBodySignals => '身体信号';

  @override
  String get syncedWorkoutDetailBodyTemp => '体温';

  @override
  String get syncedWorkoutDetailBodyWt => '体重';

  @override
  String get syncedWorkoutDetailBreathing => '呼吸';

  @override
  String get syncedWorkoutDetailCadence => '步频';

  @override
  String get syncedWorkoutDetailCapturedAroundYourSession => '在训练期间捕获';

  @override
  String get syncedWorkoutDetailDate => '日期';

  @override
  String get syncedWorkoutDetailDeleteThisSyncedWorkout => '删除此已同步的训练？';

  @override
  String get syncedWorkoutDetailDistance => '距离';

  @override
  String get syncedWorkoutDetailDuplicateOfAnotherImport =>
      '与其他导入重复 — 优先保留主要来源。';

  @override
  String get syncedWorkoutDetailDuration => '时长';

  @override
  String get syncedWorkoutDetailElevGain => '海拔上升';

  @override
  String get syncedWorkoutDetailFlights => '爬楼层数';

  @override
  String get syncedWorkoutDetailHeartRate => '心率';

  @override
  String get syncedWorkoutDetailHowDidItFeel => '感觉如何？';

  @override
  String get syncedWorkoutDetailHowDidThisSession => '这次训练感觉如何？';

  @override
  String get syncedWorkoutDetailHrvPost => 'HRV（训练后）';

  @override
  String get syncedWorkoutDetailHrvPre => 'HRV（训练前）';

  @override
  String get syncedWorkoutDetailItWillReAppear =>
      '下次与 Health Connect 同步时它会重新出现。';

  @override
  String get syncedWorkoutDetailManage => '管理';

  @override
  String get syncedWorkoutDetailMetrics => '指标';

  @override
  String get syncedWorkoutDetailMin => '最小';

  @override
  String get syncedWorkoutDetailNotes => '备注';

  @override
  String get syncedWorkoutDetailPace => '配速';

  @override
  String get syncedWorkoutDetailPeak => '峰值';

  @override
  String get syncedWorkoutDetailPullingRicherDataFrom =>
      '正在从 Health Connect 获取更丰富的数据...';

  @override
  String get syncedWorkoutDetailRestingHr => '静息心率';

  @override
  String get syncedWorkoutDetailRpeRateOfPerceived => 'RPE · 自觉运动强度';

  @override
  String syncedWorkoutDetailScreenAppDetailedSamplesMay(Object sourceApp) {
    return '应用，详细数据可能无法同步至 $sourceApp。';
  }

  @override
  String syncedWorkoutDetailScreenBpm(Object label, Object value) {
    return '$label $value bpm';
  }

  @override
  String syncedWorkoutDetailScreenBpm2(Object rhr) {
    return '$rhr bpm';
  }

  @override
  String syncedWorkoutDetailScreenC(Object temp) {
    return '$temp°C';
  }

  @override
  String syncedWorkoutDetailScreenCoach(Object _insight) {
    return '教练：$_insight';
  }

  @override
  String syncedWorkoutDetailScreenIn(Object stride) {
    return '$stride 英寸';
  }

  @override
  String syncedWorkoutDetailScreenKg(Object bodyKg) {
    return '$bodyKg kg';
  }

  @override
  String syncedWorkoutDetailScreenM(Object elev) {
    return '$elev 米';
  }

  @override
  String syncedWorkoutDetailScreenMs(Object hrvPre) {
    return '$hrvPre ms';
  }

  @override
  String syncedWorkoutDetailScreenMs2(Object hrvPost) {
    return '$hrvPost ms';
  }

  @override
  String syncedWorkoutDetailScreenOnlyASummaryWas(Object sourceApp) {
    return '仅从 $sourceApp 同步了摘要';
  }

  @override
  String syncedWorkoutDetailScreenSpm(Object cadence) {
    return '$cadence spm';
  }

  @override
  String syncedWorkoutDetailScreenTrimpFromHrReserve(Object trimp) {
    return 'TRIMP $trimp · 基于心率储备、时长和恢复情况';
  }

  @override
  String syncedWorkoutDetailScreenValue2(Object spo2) {
    return '$spo2%';
  }

  @override
  String get syncedWorkoutDetailSessionInfo => '训练信息';

  @override
  String get syncedWorkoutDetailSpeed => '速度';

  @override
  String get syncedWorkoutDetailSplits => '分段';

  @override
  String get syncedWorkoutDetailSpoAvg => '平均血氧饱和度';

  @override
  String get syncedWorkoutDetailSteps => '步数';

  @override
  String get syncedWorkoutDetailStride => '步幅';

  @override
  String get syncedWorkoutDetailTapToAddNotes => '点击添加备注';

  @override
  String get syncedWorkoutDetailTotalCal => '总卡路里';

  @override
  String get syncedWorkoutDetailTrainingEffect => '训练效果';

  @override
  String get syncedWorkoutDetailZones => '区间';

  @override
  String get syncedWorkoutsHistoryActive => '活动';

  @override
  String get syncedWorkoutsHistoryAll => '全部';

  @override
  String get syncedWorkoutsHistoryBiggestClimb => '最大爬升';

  @override
  String get syncedWorkoutsHistoryBreakdown => '细分';

  @override
  String get syncedWorkoutsHistoryCalories => '卡路里';

  @override
  String get syncedWorkoutsHistoryFastestMile => '最快英里';

  @override
  String get syncedWorkoutsHistoryHardestSession => '最艰苦训练';

  @override
  String get syncedWorkoutsHistoryLast90Days => '过去90天';

  @override
  String get syncedWorkoutsHistoryLess => '收起';

  @override
  String get syncedWorkoutsHistoryLongestHike => '最长徒步';

  @override
  String get syncedWorkoutsHistoryLongestRide => '最长骑行';

  @override
  String get syncedWorkoutsHistoryLongestSession => '最长训练';

  @override
  String get syncedWorkoutsHistoryLongestWalk => '最长步行';

  @override
  String get syncedWorkoutsHistoryMiles => '英里';

  @override
  String get syncedWorkoutsHistoryNoSyncedWorkoutsYet => '暂无同步的训练';

  @override
  String syncedWorkoutsHistoryScreenM(Object bestElev) {
    return '$bestElev 米';
  }

  @override
  String syncedWorkoutsHistoryScreenMi(Object miles) {
    return '$miles 英里';
  }

  @override
  String syncedWorkoutsHistoryScreenMi2(Object miles) {
    return '$miles 英里';
  }

  @override
  String syncedWorkoutsHistoryScreenValue(Object count, Object label) {
    return '$label · $count';
  }

  @override
  String syncedWorkoutsHistoryScreenZ(Object bestZ4plus) {
    return '$bestZ4plus% Z4+';
  }

  @override
  String get syncedWorkoutsHistorySessions => '训练次数';

  @override
  String get syncedWorkoutsHistorySyncedWorkouts => '已同步训练';

  @override
  String get syncedWorkoutsHistoryYourRecords => '个人纪录';

  @override
  String get syncedWorkoutsSummary1SyncedWorkout => '1次已同步训练';

  @override
  String syncedWorkoutsSummaryCardCal(Object calories) {
    return '$calories 大卡';
  }

  @override
  String syncedWorkoutsSummaryCardFrom(Object platformLabel) {
    return '来自 $platformLabel';
  }

  @override
  String syncedWorkoutsSummaryCardM(Object duration) {
    return '$duration 分钟';
  }

  @override
  String syncedWorkoutsSummaryCardSteps(Object steps) {
    return '$steps 步';
  }

  @override
  String syncedWorkoutsSummaryCardSynced(Object day, Object month) {
    return '已同步 $month/$day';
  }

  @override
  String syncedWorkoutsSummaryCardSyncedWorkouts(Object count) {
    return '$count 次已同步训练';
  }

  @override
  String syncedWorkoutsSummaryCardViewAll(Object count) {
    return '查看全部 $count';
  }

  @override
  String get syncedWorkoutsSummarySynced => '已同步';

  @override
  String get syncedWorkoutsSummaryTodaySSyncedWorkouts => '今日已同步训练';

  @override
  String get tappableCellSelectBias => '选择偏好';

  @override
  String get templateAddOneOrUse => '添加一个或使用下方的预设模板';

  @override
  String get templateEditorAddTemplate => '添加模板';

  @override
  String get templateEditorEditTemplate => '编辑模板';

  @override
  String get templateEditorNewTemplate => '新建模板';

  @override
  String get templateEditorSaveChanges => '保存更改';

  @override
  String get templateEditorSupersets => '超级组';

  @override
  String get templateListAMondayInThe => '计划中的周一将落在下一个周一。';

  @override
  String get templateListAddYourWarmUp => '为每次训练添加热身和拉伸动作。';

  @override
  String get templateListAlignToCalendarWeekdays => '对齐日历工作日';

  @override
  String get templateListApplyMyStaples => '应用我的常用动作';

  @override
  String get templateListCouldNotDeletePlease => '删除失败。请重试。';

  @override
  String get templateListCouldNotSchedulePlease => '排程失败。请重试。';

  @override
  String get templateListCreateAProgram => '创建计划';

  @override
  String get templateListDay1OfThe => '计划的第1天将在你选择的日期开始。';

  @override
  String get templateListDeleteProgram => '删除计划？';

  @override
  String get templateListMyPrograms => '我的计划';

  @override
  String get templateListNewProgram => '新建计划';

  @override
  String get templateListNoSavedProgramsYet => '暂无已保存的计划。';

  @override
  String get templateListScheduleThis => '排程此计划';

  @override
  String get templateListScheduling => '正在排程...';

  @override
  String templateListScreenAllDays(Object _defaultTime) {
    return '所有日期：$_defaultTime';
  }

  @override
  String templateListScreenAlreadyExisted(Object skippedExisting) {
    return '($skippedExisting 个已存在)';
  }

  @override
  String templateListScreenDeleted(Object name) {
    return '已删除 \"$name\"';
  }

  @override
  String templateListScreenRemoveWorkoutsAlreadyOn(Object name) {
    return '移除 \"$name\"？日历中已有相关训练';
  }

  @override
  String templateListScreenSchedule(Object name) {
    return '安排 \"$name\"';
  }

  @override
  String templateListScreenWorkoutsAdded(Object workoutsCreated) {
    return '已添加 $workoutsCreated 个训练';
  }

  @override
  String templateListScreenWorkoutsAddedToYour(Object workoutsCreated) {
    return '已将 $workoutsCreated 个训练添加到你的日历';
  }

  @override
  String get templateListStartDay1On => '在我的开始日期执行第1天';

  @override
  String get templateListTapADayTo => '点击某一天以设置不同时间。';

  @override
  String get templateListWeCouldNotLoad => '无法加载你的计划。';

  @override
  String get templateMyTemplates => '我的模板';

  @override
  String get templateNew => '新建';

  @override
  String get templateNoCustomTemplatesYet => '暂无自定义模板';

  @override
  String get templatePickerFailedToLoadTemplates => '加载模板失败';

  @override
  String templatePickerSheetTheOriginalHomeScreen(Object appName) {
    return '原始的$appName主屏幕体验';
  }

  @override
  String get templatePickerStartWithAPre => '从预设布局开始';

  @override
  String get templatePickerTemplates => '模板';

  @override
  String get templatePickerUseThisTemplate => '使用此模板';

  @override
  String get templatePreBuiltTemplates => '预设模板';

  @override
  String get tierComparisonAdv => '进阶';

  @override
  String get tierComparisonAdvanced => '进阶版';

  @override
  String get tierComparisonFeature => '功能';

  @override
  String get tierComparisonLongPressTheEasy => '随时长按“基础/进阶”选项卡即可重新打开此页面。';

  @override
  String get tierComparisonWhichTierIsRight => '哪个版本适合我？';

  @override
  String get tierExcellent => '优秀';

  @override
  String get tierFair => '一般';

  @override
  String get tierGood => '良好';

  @override
  String get tierLow => '较低';

  @override
  String get tileFactoryFoodPatterns => '饮食模式';

  @override
  String get tileFactorySeeWhichFoodsFuel => '查看哪些食物为你提供能量，哪些让你感到疲惫';

  @override
  String get tilePickerAdd => '添加';

  @override
  String get tilePickerAddTile => '添加磁贴';

  @override
  String get timeCardMostActiveDay => '最活跃的一天';

  @override
  String get timeCardPeakHour => '高峰时段';

  @override
  String get timeCardSpentWorkingOut => '训练时长';

  @override
  String get timeCardYourTime => '你的时间';

  @override
  String get timedExerciseTimerComplete => '完成';

  @override
  String get timedExerciseTimerPaused => '已暂停';

  @override
  String get timedExerciseTimerReset => '重置';

  @override
  String get timedExerciseTimerRunning => '进行中';

  @override
  String timedExerciseTimerSetOf(Object setNumber, Object totalSets) {
    return '第 $setNumber 组，共 $totalSets 组';
  }

  @override
  String get timedExerciseTimerTapPauseToRest => '点击暂停以休息，然后继续';

  @override
  String get timelineBusy => '忙碌';

  @override
  String get timelineCloseSearch => '关闭搜索';

  @override
  String get timelineCouldnTLoadTimeline => '无法加载时间轴。';

  @override
  String get timelineEntryDetailDeleted => '已删除 ✓';

  @override
  String get timelineEntryDetailEditDurationMin => '编辑时长（分钟）';

  @override
  String get timelineEntryDetailFailedToDeleteRefresh => '删除失败 — 请刷新重试。';

  @override
  String get timelineEntryDetailFailedToUpdate => '更新失败';

  @override
  String get timelineEntryDetailReLog => '重新记录';

  @override
  String get timelineEntryDetailReLogQueuedComing => '已加入重新记录队列 — 即将完成';

  @override
  String get timelineEntryDetailRefresh => '刷新';

  @override
  String get timelineEntryDetailRelog => '重新记录';

  @override
  String get timelineEntryDetailShareSheetComingSoon => '分享功能即将推出';

  @override
  String get timelineEntryDetailUpdated => '已更新 ✓';

  @override
  String timelineEntryTileValue(Object coachNote) {
    return '💬 $coachNote';
  }

  @override
  String get timelineLoadEarlierDays => '加载更早的记录';

  @override
  String get timelineLogYourFirstWorkout =>
      '在聊天中或通过“+”按钮记录你的第一次训练、饮食或饮水 — 它会显示在这里。';

  @override
  String get timelineNothingLogged => '暂无记录。';

  @override
  String get timelineRefresh => '刷新';

  @override
  String get timelineSearchTimeline => '搜索时间线';

  @override
  String get timelineSearchTitleOrNotes => '搜索标题或备注…';

  @override
  String timelineSummaryCardDay(Object streakDay) {
    return '第 $streakDay 天';
  }

  @override
  String timelineSummaryCardHabits(Object habitsCompleted) {
    return '已完成 $habitsCompleted 个习惯';
  }

  @override
  String timelineSummaryCardKcalIn(Object caloriesEaten) {
    return '摄入 $caloriesEaten kcal';
  }

  @override
  String timelineSummaryCardM(Object workoutsTotalMinutes) {
    return '$workoutsTotalMinutes分钟';
  }

  @override
  String timelineSummaryCardMl(Object waterGoalMl, Object waterMl) {
    return '$waterMl/$waterGoalMl 毫升';
  }

  @override
  String timelineSummaryCardMood(Object mood) {
    return '心情: $mood';
  }

  @override
  String get timelineSummaryCardNetKcal => '净卡路里';

  @override
  String timelineSummaryCardSteps(Object steps) {
    return '$steps 步';
  }

  @override
  String timelineSummaryCardXp(Object xpEarned) {
    return '$xpEarned XP';
  }

  @override
  String get timelineTodaySJournal => '今日日志';

  @override
  String get timelineYourDayStartsHere => '从这里开始你的一天';

  @override
  String get timerRestMixinAccept => '接受';

  @override
  String get timerRestMixinGotIt => '知道了';

  @override
  String get timerRestMixinRateOfPerceivedExertion => 'RPE 用于衡量一组动作的吃力程度：';

  @override
  String get timerRestMixinWhatIsRpe => '什么是 RPE？';

  @override
  String get todayCycleLengthLastCycles => '最近周期';

  @override
  String get todayCycleLengthLog2CyclesTo => '记录 2 个周期以生成图表';

  @override
  String todayCycleLengthSparklineD(Object last) {
    return '$last天';
  }

  @override
  String get todayFertilityWindowFertilityWindow => '受孕窗口期';

  @override
  String get todayFertilityWindowLowConfidenceEstimate => '低置信度 · 预估';

  @override
  String get todayScoreCardConnect => '连接';

  @override
  String get todayScoreCardCustomize => '自定义';

  @override
  String get todayScoreCardToday => '今天';

  @override
  String todayScoreDetailDown(Object arg0) {
    return '下降 $arg0';
  }

  @override
  String todayScoreDetailEarnedPts(Object arg0, Object arg1) {
    return '获得积分 $arg0 $arg1';
  }

  @override
  String get todayScoreDetailHowItWorks => '如何运作';

  @override
  String todayScoreDetailInactiveExplanation(Object arg0, Object arg1) {
    return '不活跃说明 $arg0 $arg1';
  }

  @override
  String todayScoreDetailMomentumWithAvg(Object arg0, Object arg1) {
    return '动力趋势，平均值 $arg0 $arg1';
  }

  @override
  String get todayScoreDetailNotCounted => '未计入';

  @override
  String get todayScoreDetailSetupText => '设置文本';

  @override
  String get todayScoreDetailSteady => '平稳';

  @override
  String get todayScoreDetailTodayScore => '今日评分';

  @override
  String todayScoreDetailUp(Object arg0) {
    return '上升 $arg0';
  }

  @override
  String get todayScoreSetupAddAWorkoutPlan => '添加训练计划';

  @override
  String todayScoreSetupCardContinue(Object label) {
    return '继续：$label';
  }

  @override
  String todayScoreSetupCardGetStarted(Object completedCount, Object length) {
    return '开始训练 · $completedCount/$length';
  }

  @override
  String get todayScoreSetupTrackYourFirstSleep => '记录你的首次睡眠';

  @override
  String get todayScoreSetupYouReAllSet => '设置完成';

  @override
  String get todayStatsRowKcal => ' kcal';

  @override
  String todayStatsRowL(Object currentL) {
    return '${currentL}L';
  }

  @override
  String todayStatsRowValue(Object completed) {
    return '$completed/4';
  }

  @override
  String get todayWorkoutCardCouldNotLoadWorkout => '无法加载训练';

  @override
  String get todayWorkoutCardGenerateAWorkoutProgram => '生成训练计划以开始！';

  @override
  String get todayWorkoutCardGenerateWorkouts => '生成训练';

  @override
  String todayWorkoutCardInDays(Object daysUntilNext) {
    return '$daysUntilNext 天后';
  }

  @override
  String get todayWorkoutCardLoadingTodaySWorkout => '正在加载今日训练...';

  @override
  String todayWorkoutCardNext(Object name) {
    return '下一项：$name';
  }

  @override
  String get todayWorkoutCardNoWorkoutsScheduled => '暂无计划的训练';

  @override
  String get todayWorkoutCardRestDay => '休息日';

  @override
  String get todayWorkoutCardStartWorkout => '开始训练';

  @override
  String get todayWorkoutCardTakeItEasyToday => '今天放轻松！你的肌肉正在恢复中。';

  @override
  String get todayWorkoutCardViewUpcoming => '查看即将进行的训练';

  @override
  String get todaysHealthCardActiveEnergy => '活动能量';

  @override
  String get todaysHealthCardAvgHr => '平均心率';

  @override
  String get todaysHealthCardConnect => '连接';

  @override
  String get todaysHealthCardConnectHealth => '连接健康数据';

  @override
  String get todaysHealthCardHrRange => '心率区间';

  @override
  String get todaysHealthCardRestingHr => '静息心率';

  @override
  String get todaysHealthCardSyncStepsHeartRate => '同步步数、心率和睡眠';

  @override
  String get todaysHealthCardTodaySHealth => '今日健康';

  @override
  String get trainingFocusAllocateUpTo5 => '最多分配 5 个重点点数以优先训练特定肌群';

  @override
  String get trainingFocusFocusPoints => '重点点数';

  @override
  String get trainingFocusMuscleFocusPoints => '肌肉重点点数';

  @override
  String get trainingFocusPrimaryTrainingGoal => '主要训练目标';

  @override
  String trainingFocusScreenAvailable(
    Object availablePoints,
    Object maxTotalPoints,
  ) {
    return '可用 $availablePoints/$maxTotalPoints 点';
  }

  @override
  String trainingFocusScreenFailedToSave(Object e) {
    return '保存失败：$e';
  }

  @override
  String get trainingFocusTrainingFocus => '训练重点';

  @override
  String get trainingFocusTrainingFocusUpdated => '训练重点已更新';

  @override
  String get trainingLoadAcute7d => '急性负荷 (7天)';

  @override
  String get trainingLoadAskCoachAboutYour => '向教练咨询你的训练负荷';

  @override
  String get trainingLoadChartBuildingBaseline => '正在建立基准';

  @override
  String trainingLoadChartCouldNotLoadTraining(Object e) {
    return '无法加载训练负荷：$e';
  }

  @override
  String get trainingLoadChartNoCardioActivityYet =>
      '暂无有氧运动记录 — 记录一次跑步、骑行或划船以开始建立你的基准。';

  @override
  String get trainingLoadChronic28d => '慢性负荷 (28天)';

  @override
  String trainingLoadScreenCouldNotLoadTraining(Object message) {
    return '无法加载训练负荷: $message';
  }

  @override
  String get trainingLoadTrainingLoad => '训练负荷';

  @override
  String trainingMethodsScreenRest(Object restDisplayHint) {
    return '休息: $restDisplayHint';
  }

  @override
  String get trainingMethodsTrainingMethods => '训练方法';

  @override
  String get trainingPreferencesAddPastWorkoutsFor => '添加过往训练以获得更精准的 AI 重量建议';

  @override
  String get trainingPreferencesBoostedInSelectionCan => '在选择中增强，可轮换';

  @override
  String get trainingPreferencesCustomizeHowWorkoutsAre => '自定义训练生成方式';

  @override
  String get trainingPreferencesEquipmentAvailableForWorkou => '训练可用器械';

  @override
  String get trainingPreferencesExerciseConsistency => '动作一致性';

  @override
  String get trainingPreferencesExerciseQueue => '动作队列';

  @override
  String get trainingPreferencesExercisesToAvoid => '要避免的动作';

  @override
  String get trainingPreferencesFavoriteExercises => '收藏的动作';

  @override
  String get trainingPreferencesFirstDayOfThe => '日历周的第一天';

  @override
  String get trainingPreferencesGuaranteedNeverRotateOut => '已锁定，绝不轮换';

  @override
  String get trainingPreferencesHowFastToIncrease => '重量增加速度';

  @override
  String get trainingPreferencesHowMuchExercisesChange => '每周动作变化幅度';

  @override
  String get trainingPreferencesImportWorkoutHistory => '导入训练历史';

  @override
  String get trainingPreferencesMusclesToAvoid => '要避免的肌肉部位';

  @override
  String get trainingPreferencesMy1rms => '我的 1RM';

  @override
  String get trainingPreferencesMyEquipment => '我的器械';

  @override
  String get trainingPreferencesProgressCharts => '进度图表';

  @override
  String get trainingPreferencesProgressionPace => '进阶节奏';

  @override
  String get trainingPreferencesPushPullLegsFull => '推/拉/腿、全身训练等';

  @override
  String get trainingPreferencesQueueExercisesForNext => '将动作加入下一次训练队列';

  @override
  String get trainingPreferencesSkipOrReduceMuscle => '跳过或减少特定肌群';

  @override
  String get trainingPreferencesSkipSpecificExercises => '跳过特定动作';

  @override
  String get trainingPreferencesStapleExercises => '核心动作';

  @override
  String get trainingPreferencesStrengthCardioOrMixed => '力量、有氧或混合';

  @override
  String get trainingPreferencesTraining => '训练';

  @override
  String get trainingPreferencesTrainingIntensity => '训练强度';

  @override
  String get trainingPreferencesTrainingSplit => '训练拆分';

  @override
  String get trainingPreferencesVaryOrKeepSame => '变换或保持现有练习';

  @override
  String get trainingPreferencesViewAndEditYour => '查看并编辑你的最大重量';

  @override
  String get trainingPreferencesVisualizeStrengthVolumeOv => '可视化查看力量与训练量趋势';

  @override
  String get trainingPreferencesWeekStartsOn => '一周起始日';

  @override
  String get trainingPreferencesWeeklyVariety => '每周多样性';

  @override
  String get trainingPreferencesWhereYouTrain => '训练地点';

  @override
  String get trainingPreferencesWhichDaysYouTrain => '训练日期';

  @override
  String get trainingPreferencesWorkAtAPercentage => '按最大重量的百分比训练';

  @override
  String get trainingPreferencesWorkoutDays => '训练日';

  @override
  String get trainingPreferencesWorkoutEnvironment => '训练环境';

  @override
  String get trainingPreferencesWorkoutType => '训练类型';

  @override
  String get trainingProgramSelectorChooseYourTrainingSplit => '选择你的训练分化';

  @override
  String get trainingProgramSelectorCustomProgram => '自定义计划';

  @override
  String get trainingProgramSelectorDescribeWhatYouWant =>
      '描述你的训练目标，AI 将为你创建个性化计划。';

  @override
  String get trainingProgramSelectorEGTrainFor => '例如：“为 HYROX 比赛训练”';

  @override
  String get trainingProgramSelectorExamples => '示例';

  @override
  String get trainingProgramSelectorSaveCustomProgram => '保存自定义计划';

  @override
  String get trainingProgramSelectorTrainingProgram => '训练计划';

  @override
  String get trainingSetupCardAddEquipmentNotIn => '添加不在标准列表中的器械';

  @override
  String get trainingSetupCardEnvironment => '环境';

  @override
  String get trainingSetupCardEquipment => '器械';

  @override
  String get trainingSetupCardExperience => '经验';

  @override
  String get trainingSetupCardFocusAreas => '重点部位';

  @override
  String get trainingSetupCardHowMuchExerciseVariety => '每周需要多少练习多样性？';

  @override
  String get trainingSetupCardMyCustomEquipment => '我的自定义器械';

  @override
  String get trainingSetupCardNotSet => '未设置';

  @override
  String get trainingSetupCardTrainingSetup => '训练设置';

  @override
  String get trainingSetupCardTrainingSplit => '训练分化';

  @override
  String trainingSetupCardValue(Object label, Object value) {
    return '$label ($value%)';
  }

  @override
  String get trainingSetupCardWeeklyVariety => '每周多样性';

  @override
  String get trainingSetupCardWorkoutDays => '训练日';

  @override
  String get transitionCountdownOverlayGetReady => '准备开始';

  @override
  String get transitionCountdownOverlayNextExerciseStartingSoon => '下一项练习即将开始';

  @override
  String get transitionCountdownOverlayStartNow => '立即开始';

  @override
  String get transitionCountdownOverlayUpNext => '接下来';

  @override
  String get trendAiInsightAiInsight => 'AI 洞察';

  @override
  String get trendAiInsightCouldnTGenerateAn => '暂时无法生成洞察。';

  @override
  String get trendAiInsightReadingYourTrends => '正在读取你的趋势数据…';

  @override
  String get trendChartNoDataInThis => '此范围内无数据';

  @override
  String get trendChartPinchToZoomTap => '双指缩放 · 点击重置';

  @override
  String get trendChartTryAWiderTime => '尝试更长的时间范围或记录新数据';

  @override
  String get trialProgress1DayLeft => '剩余 1 天';

  @override
  String get trialProgressGoal => '目标：';

  @override
  String trialProgressWidgetDaysLeft(Object daysRemaining) {
    return '剩余 $daysRemaining 天';
  }

  @override
  String trialProgressWidgetTrialDay(Object dayOfTrial) {
    return '试用 · 第 $dayOfTrial / 7 天';
  }

  @override
  String get trophiesCardKeepShowingUpBadges => '保持打卡 — 达成里程碑即可解锁徽章。';

  @override
  String trophiesCardNewBadgesThisPeriod(Object length) {
    return '本期新增 $length 个徽章';
  }

  @override
  String get trophiesCardNoNewBadgesThis => '此阶段暂无新徽章。';

  @override
  String trophiesCardWrapped(Object appName) {
    return '$appName 年度总结';
  }

  @override
  String get trophiesCardYourBadges => '我的徽章';

  @override
  String get trophiesEarnedAchievementsUnlocked => '已解锁成就';

  @override
  String get trophiesEarnedAllMilestonesCleared => '已达成所有里程碑';

  @override
  String get trophiesEarnedAllTime => '历史总计';

  @override
  String get trophiesEarnedCardioAchievements => '有氧成就';

  @override
  String get trophiesEarnedDayStreak => '连续打卡';

  @override
  String get trophiesEarnedFirstTime => '首次达成！';

  @override
  String get trophiesEarnedKg => ') 公斤';

  @override
  String get trophiesEarnedMilestoneReached => '达成里程碑';

  @override
  String get trophiesEarnedMilestoneReachedNice => '达成里程碑 — 干得漂亮！';

  @override
  String get trophiesEarnedMilestones => '里程碑';

  @override
  String trophiesEarnedNewBadges(Object arg0) {
    return '徽章 $arg0';
  }

  @override
  String trophiesEarnedNewCardioPRs(Object arg0) {
    return '有氧 PR $arg0';
  }

  @override
  String get trophiesEarnedNewPR => '获得新PR';

  @override
  String trophiesEarnedNewPRs(Object arg0) {
    return 'PR $arg0';
  }

  @override
  String get trophiesEarnedNewPr => '新 PR';

  @override
  String get trophiesEarnedNextMilestones => '下一里程碑';

  @override
  String get trophiesEarnedNoNewRecords => '暂无新纪录';

  @override
  String get trophiesEarnedNoNewRecordsThis => '本次训练无新纪录 — 以下是你正在努力的目标：';

  @override
  String get trophiesEarnedPersonalRecords => '个人纪录';

  @override
  String trophiesEarnedRemainingToUnlock(Object arg0, Object arg1) {
    return '剩余解锁 $arg0 $arg1';
  }

  @override
  String get trophiesEarnedSessionHighlights => '训练亮点';

  @override
  String trophiesEarnedSheetPts(Object points) {
    return '+$points 分';
  }

  @override
  String trophiesEarnedSheetX(Object reps) {
    return ' x $reps';
  }

  @override
  String get trophiesEarnedTitle => '标题';

  @override
  String get trophiesEarnedTotalWorkouts => '总训练次数';

  @override
  String get trophiesEarnedTrophiesAchievements => '奖杯与成就';

  @override
  String get trophiesEarnedViewAllCardioPRs => '查看所有有氧 PR';

  @override
  String get trophiesEarnedViewAllCardioPrs => '查看所有有氧 PR';

  @override
  String get trophiesEarnedYouVeClearedEvery => '你已完成所有里程碑 — 保持节奏，新的里程碑即将出现！';

  @override
  String get trophiesEarnedYourFitnessJourney => '你的健身旅程';

  @override
  String get trophiesEarnedYourSessionHighlights => '本次训练亮点';

  @override
  String get trophyCardMerch => '周边商品';

  @override
  String trophyCardValue(Object progressPercentage) {
    return '$progressPercentage%';
  }

  @override
  String trophyCardXp(Object xpReward) {
    return '+$xpReward XP';
  }

  @override
  String trophyCelebrationOverlayDayStreak(Object currentStreak) {
    return '连续打卡 $currentStreak 天！';
  }

  @override
  String get trophyCelebrationOverlayKeepTheMomentumGoing => '保持势头';

  @override
  String get trophyCelebrationOverlayMilestoneReached => '达成里程碑！';

  @override
  String get trophyCelebrationOverlayTapAnywhereToContinue => '点击任意位置继续';

  @override
  String get trophyCelebrationOverlayTrophiesEarned => '获得奖杯！';

  @override
  String trophyCelebrationOverlayWorkoutsCompleted(Object workoutMilestone) {
    return '已完成 $workoutMilestone 次训练';
  }

  @override
  String get trophyCeremonyOverlayCongratsOnEarningThis => '恭喜获得此奖杯！';

  @override
  String trophyCeremonyOverlayLv(Object level) {
    return 'Lv.$level';
  }

  @override
  String get trophyCeremonyOverlayPlayBonusRound => '开始奖励环节';

  @override
  String get trophyFilterFilterTrophies => '筛选奖杯';

  @override
  String get trophyFilterReset => '重置';

  @override
  String trophyFilterSheetApplyFilters(Object activeFilterCount) {
    return '应用$activeFilterCount个筛选条件';
  }

  @override
  String get trophyRoomEarned => '已获得';

  @override
  String get trophyRoomLocked => '已锁定';

  @override
  String get trophyRoomMystery => '神秘';

  @override
  String get trophyRoomMysteryTrophies => '神秘奖杯';

  @override
  String get trophyRoomPoints => '积分';

  @override
  String trophyRoomScreenPartTrophyCardComplete(Object progressPercentage) {
    return '$progressPercentage% 已完成';
  }

  @override
  String trophyRoomScreenPartTrophyCardValue(Object progressPercentage) {
    return '$progressPercentage%';
  }

  @override
  String get trophyRoomScreenProgressHiddenUntilDiscover => '进度在发现前隐藏';

  @override
  String get trophyRoomScreenTrophyRoom => '奖杯陈列室';

  @override
  String get trophyRoomSearchTrophies => '搜索奖杯...';

  @override
  String get trustAndExpectationsABitOfHonesty => '坦诚相待';

  @override
  String get trustAndExpectationsBeforeWeBuildYour => '在制定您的计划之前';

  @override
  String get trustAndExpectationsDeleteAnythingAnytime => '随时删除任何内容。';

  @override
  String get trustAndExpectationsEncryptedInTransitAnd => '传输和存储均已加密。';

  @override
  String get trustAndExpectationsReadOurFullPrivacy => '阅读我们的完整隐私政策';

  @override
  String get trustAndExpectationsRealChangeShowsUp => '真正的改变会在第 3 周显现。';

  @override
  String get trustAndExpectationsSoundsGood => '听起来不错';

  @override
  String get trustAndExpectationsTls13Aes => 'TLS 1.3 + AES-256。与您的银行采用相同标准。';

  @override
  String get trustAndExpectationsTwoThingsYouShould => '您应该了解的两件事。';

  @override
  String get trustAndExpectationsWeNeverSellYour => '我们绝不出售您的数据。';

  @override
  String get trustAndExpectationsWeWonTSugarcoat => '我们不会粉饰事实。';

  @override
  String get trustAndExpectationsWeek1WillFeel => '第 1 周会感觉进展缓慢。';

  @override
  String typingIndicatorIsTyping(Object agentName) {
    return '$agentName 正在输入';
  }

  @override
  String typingIndicatorIsTyping2(Object userName) {
    return '$userName 正在输入';
  }

  @override
  String typingIndicatorIsTyping3(Object agentName) {
    return '$agentName 正在输入...';
  }

  @override
  String get unifiedHomeWidgetsActivity => '活动';

  @override
  String unifiedHomeWidgetsBreakfastLogged(Object arg0) {
    return '已记录早餐 $arg0';
  }

  @override
  String get unifiedHomeWidgetsBreakfastSuggestion => '早餐建议';

  @override
  String get unifiedHomeWidgetsCarbs => '碳水化合物';

  @override
  String get unifiedHomeWidgetsConnect => '连接';

  @override
  String get unifiedHomeWidgetsConnectAppleHealth => '连接 Apple Health';

  @override
  String unifiedHomeWidgetsCups(Object cupGoal, Object cups) {
    return '$cups / $cupGoal 杯';
  }

  @override
  String unifiedHomeWidgetsCupsToday(Object arg0, Object arg1) {
    return '今日饮水量 $arg0 $arg1';
  }

  @override
  String get unifiedHomeWidgetsDrink16ozPostWorkout => '训练后请补充16盎司水分';

  @override
  String unifiedHomeWidgetsEndTheDayAtGoal(Object arg0) {
    return '今日目标达成 $arg0';
  }

  @override
  String get unifiedHomeWidgetsFasting => '轻断食';

  @override
  String get unifiedHomeWidgetsFat => '脂肪';

  @override
  String unifiedHomeWidgetsG(Object eaten, Object goal) {
    return '$eaten / $goal g';
  }

  @override
  String get unifiedHomeWidgetsKcal => ' kcal';

  @override
  String unifiedHomeWidgetsKcalBurned(Object arg0) {
    return '今日总计 $arg0 千卡';
  }

  @override
  String get unifiedHomeWidgetsKcalLeft => ' kcal 剩余';

  @override
  String get unifiedHomeWidgetsLastNight => '昨晚';

  @override
  String get unifiedHomeWidgetsLog16oz => '记录 16oz';

  @override
  String get unifiedHomeWidgetsNoData => '暂无数据';

  @override
  String get unifiedHomeWidgetsNoWorkoutWasScheduled => '未安排训练';

  @override
  String get unifiedHomeWidgetsNutrition => '营养';

  @override
  String get unifiedHomeWidgetsOver => '超过';

  @override
  String get unifiedHomeWidgetsOvernightWaterReset => '夜间饮水重置';

  @override
  String get unifiedHomeWidgetsProtein => '蛋白质';

  @override
  String get unifiedHomeWidgetsQuickLog => '快速记录';

  @override
  String get unifiedHomeWidgetsRefuelHydration => '补充水分';

  @override
  String get unifiedHomeWidgetsRestDayNoWorkoutScheduled => '休息日，无训练安排';

  @override
  String get unifiedHomeWidgetsRestDayNothingScheduled => '休息日，无计划';

  @override
  String get unifiedHomeWidgetsSeeYourStepsCalories => '在主屏幕查看您的步数、卡路里和睡眠';

  @override
  String get unifiedHomeWidgetsSleep => '睡眠';

  @override
  String get unifiedHomeWidgetsStartAFast => '开始轻断食 →';

  @override
  String get unifiedHomeWidgetsWakeHydration => '晨间补水';

  @override
  String get unifiedHomeWidgetsWater => '饮水';

  @override
  String get unifiedHomeWidgetsWorkoutCompleteGreatJob => '训练完成，干得漂亮';

  @override
  String get unresolvedExercisesApplyMapping => '应用映射';

  @override
  String get unresolvedExercisesBulkFixUnresolvedExercises => '修复未解析的动作';

  @override
  String get unresolvedExercisesBulkMapRawNamesFrom => '将导入的原始名称映射到动作库。';

  @override
  String get unresolvedExercisesBulkMore => '更多…';

  @override
  String get unresolvedExercisesBulkNoAutoSuggestionOpen => '无自动建议 — 点击手动选择。';

  @override
  String get unresolvedExercisesBulkNothingToFixEvery => '无需修复 — 所有导入的动作均已映射！';

  @override
  String unresolvedExercisesBulkSheetCouldNotLoad(Object error) {
    return '无法加载: $error';
  }

  @override
  String unresolvedExercisesBulkSheetMap(Object canonicalName) {
    return '映射 → $canonicalName';
  }

  @override
  String unresolvedExercisesBulkSheetMappedRowsTo(
    Object canonicalName,
    Object rowsAffected,
  ) {
    return '已将 $rowsAffected 行映射至“$canonicalName”。';
  }

  @override
  String unresolvedExercisesBulkSheetRevertedRows(Object rowsAffected) {
    return '已还原 $rowsAffected 行。';
  }

  @override
  String unresolvedExercisesBulkSheetRows(Object rowCount) {
    return '$rowCount 行';
  }

  @override
  String get unresolvedExercisesBulkUndo => '撤销';

  @override
  String get unresolvedExercisesEGBarbellBack => '例如：杠铃深蹲';

  @override
  String get unresolvedExercisesMapExercise => '映射动作';

  @override
  String get unresolvedExercisesNoAutomaticSuggestionsFor => '此名称无自动建议。';

  @override
  String get unresolvedExercisesOrTypeACanonical => '或输入标准名称';

  @override
  String get unresolvedExercisesSearchLibrary => '搜索动作库…';

  @override
  String unresolvedExercisesSheetValue(Object pct, Object source) {
    return '$pct% · $source';
  }

  @override
  String get unresolvedExercisesSuggestions => '建议';

  @override
  String get upNextCardCouldNotLoadSchedule => '无法加载日程';

  @override
  String get upNextCardNoUpcomingItemsTap => '暂无即将进行的日程。点击 + 添加到您的计划中';

  @override
  String get upNextCardTapToRetry => '点击重试';

  @override
  String get upNextCardUpNext => '接下来';

  @override
  String get upNextCardViewFullSchedule => '查看完整日程';

  @override
  String upcomingWorkoutCardMExercises(Object exerciseCount, Object workout) {
    return '$workout 分钟 - $exerciseCount 个动作';
  }

  @override
  String get upcomingWorkoutsAiWillCreateYour => 'AI 将为您创建训练计划';

  @override
  String get upcomingWorkoutsCreatingYourPersonalizedWor => '正在创建您的个性化训练';

  @override
  String get upcomingWorkoutsEditGymProfile => '编辑健身房资料';

  @override
  String get upcomingWorkoutsGenerating => '生成中...';

  @override
  String get upcomingWorkoutsLater => '稍后';

  @override
  String get upcomingWorkoutsNoWorkoutDaysScheduled => '未安排训练日';

  @override
  String get upcomingWorkoutsNotEnoughEquipment => '器械不足';

  @override
  String upcomingWorkoutsSheetFailedToGenerateWorkout(Object message) {
    return '无法生成训练计划: $message';
  }

  @override
  String upcomingWorkoutsSheetFailedToGenerateWorkout2(Object e) {
    return '无法生成训练计划: $e';
  }

  @override
  String get upcomingWorkoutsTapADateTo => '点击日期以生成您的训练';

  @override
  String get upcomingWorkoutsTapToGenerate => '点击生成';

  @override
  String get upcomingWorkoutsUpcomingWorkouts => '即将进行的训练';

  @override
  String get upcomingWorkoutsUpdateYourWorkoutSchedule => '在设置中更新您的训练计划';

  @override
  String get upgradePromptDismiss => '忽略';

  @override
  String get upgradePromptLimitReached => '已达上限';

  @override
  String get upgradePromptSeePremiumPlans => '查看高级计划';

  @override
  String upgradePromptSheetYouVeUsedAll(Object featureName) {
    return '你已用完本周期内所有的 $featureName。';
  }

  @override
  String usageCounterStripLeft(Object displayCount) {
    return '剩余 $displayCount';
  }

  @override
  String userSearchResultCardValue(Object username) {
    return '@$username';
  }

  @override
  String userSearchResultCardWorkouts(Object totalWorkouts) {
    return '$totalWorkouts 次训练';
  }

  @override
  String get vacationModeClear => '清除';

  @override
  String get vacationModeEndDate => '结束日期';

  @override
  String get vacationModeLeaveEmptyForOpen => '留空即为不限期的假期';

  @override
  String get vacationModeLeaveEmptyToStart => '留空即立即开始';

  @override
  String get vacationModeNoChanges => '无更改';

  @override
  String vacationModePageFailedToSave(Object e) {
    return '保存失败：$e';
  }

  @override
  String get vacationModeSaveChanges => '保存更改';

  @override
  String get vacationModeStartDate => '开始日期';

  @override
  String get vacationModeSuppressingNonCriticalNotif => '已屏蔽非必要通知';

  @override
  String get vacationModeVacationMode => '假期模式';

  @override
  String get vacationModeVacationModeSettingsSaved => '假期模式设置已保存';

  @override
  String get vacationModeVacationStartMustBe => '假期开始日期必须在结束日期之前或当天';

  @override
  String get vacationModeWhatVacationModeDoes => '假期模式的作用';

  @override
  String viralExtrasW(Object marketingDomain, Object shortId) {
    return '$marketingDomain/w/$shortId';
  }

  @override
  String get vo2maxDetail30DayAvg => '30 天平均值';

  @override
  String get vo2maxDetailAllTimeBest => '历史最佳';

  @override
  String get vo2maxDetailAskCoach => '咨询教练';

  @override
  String get vo2maxDetailCurrent => '当前';

  @override
  String get vo2maxDetailLast180Days => '过去 180 天';

  @override
  String get vo2maxDetailLatestVo2max => '最新 VO2max';

  @override
  String get vo2maxDetailMlKgMin => 'ml/kg/min';

  @override
  String get vo2maxDetailNoVo2maxYet => '暂无 VO2max 数据';

  @override
  String vo2maxDetailScreenAsOf(Object whenStr) {
    return '截至 $whenStr';
  }

  @override
  String vo2maxDetailScreenCouldNotLoadVo(Object error) {
    return '无法加载 VO2max。\n$error';
  }

  @override
  String vo2maxDetailScreenFitnessAge(Object fitnessAge) {
    return '体能年龄 $fitnessAge';
  }

  @override
  String vo2maxDetailScreenPts(Object length) {
    return '$length 分';
  }

  @override
  String get vo2maxDetailTrendWillAppearAfter => '记录几次测量后将显示趋势。';

  @override
  String get vo2maxDetailVo2max => 'VO2max';

  @override
  String get voiceAnnouncementsAnnouncingExerciseNamesDuri => '在过渡期间播报动作名称';

  @override
  String get voiceAnnouncementsMicFabOnActive => '活动训练中的麦克风悬浮按钮 — “225 for 5”';

  @override
  String get voiceAnnouncementsTestVoice => '测试语音';

  @override
  String get voiceAnnouncementsVoiceAnnouncements => '语音播报';

  @override
  String get voiceAnnouncementsVoiceAnnouncements2 => '语音播报';

  @override
  String get voiceAnnouncementsVoiceSetLogging => '语音记录组数';

  @override
  String get voiceAnnouncementsWhenEnabledYouWill => '启用后，您将听到：';

  @override
  String get voiceMicFabHearing => '聆听中…';

  @override
  String get volumeAlertCardAcknowledge => '确认';

  @override
  String volumeAlertCardIncrease(
    Object formattedIncrease,
    Object muscleGroupDisplay,
  ) {
    return '$muscleGroupDisplay: 增加 $formattedIncrease';
  }

  @override
  String get volumeAlertCardVolumeAlert => '训练量提醒';

  @override
  String volumeAlertCardVolumeAlerts(Object length) {
    return '$length 个训练量提醒';
  }

  @override
  String get volumeCardTotalVolumeLifted => '总训练量';

  @override
  String get volumeChartAverage => '平均值';

  @override
  String get volumeChartCompleteSomeWorkoutsTo => '完成一些训练以查看您的训练量趋势。';

  @override
  String get volumeChartDangerousIncrease => '危险增长';

  @override
  String get volumeChartLogAFewWeighted => '记录几次负重组数以查看您的训练量趋势。';

  @override
  String volumeChartMuscleGroupVolume(Object muscleGroup) {
    return '$muscleGroup 容量';
  }

  @override
  String volumeChartNRisky(Object count) {
    return '$count 项风险';
  }

  @override
  String get volumeChartNoVolumeData => '无训练量数据';

  @override
  String get volumeChartNoWeightedVolumeYet => '暂无负重训练量';

  @override
  String get volumeChartPeak => '峰值';

  @override
  String get volumeChartVolume => '容量';

  @override
  String get volumeChartVolumeTrends => '训练量趋势';

  @override
  String get volumeChartWeeklyVolumeTrend => '每周容量趋势';

  @override
  String get volumeChartWeeks => '周';

  @override
  String get volumeHeroTemplateExercises => '动作';

  @override
  String volumeHeroTemplateThatS(Object comparison) {
    return '— 相当于 $comparison —';
  }

  @override
  String get volumeHistoryCompleteWorkoutsToSee => '完成训练以查看训练量趋势';

  @override
  String get volumeHistoryFailedToLoad => '加载失败';

  @override
  String get volumeHistoryNoHistoryYet => '暂无历史记录';

  @override
  String volumeHistoryScreenSets(Object totalSets) {
    return '$totalSets 组';
  }

  @override
  String volumeHistoryScreenValue(Object key, Object value) {
    return '$key: $value';
  }

  @override
  String get volumeHistoryTotalVolume => '总训练量';

  @override
  String get volumeHistoryVolumeHistory => '训练量历史';

  @override
  String get volumeProgressionCardDefineCustomProgressionVia =>
      '通过 JSON 定义自定义进度（高级）';

  @override
  String get volumeProgressionCardHowTrainingVolumeIncreases => '训练量随时间增加的方式';

  @override
  String volumeProgressionCardValue(Object v) {
    return '$v%';
  }

  @override
  String get volumeProgressionCardVolumeProgressionCurves => '训练量增长曲线';

  @override
  String volumeProgressionCardW(Object v) {
    return '第 $v 周';
  }

  @override
  String get volumeProgressionCardWavePatternVolumeCycles => '波浪模式：训练量每周循环起伏';

  @override
  String get warmupControllerPause => '暂停';

  @override
  String get warmupControllerSkipWarmup => '跳过热身';

  @override
  String get warmupControllerStartWorkout => '开始训练';

  @override
  String get warmupControllerUpNext => '接下来';

  @override
  String get warmupControllerWarmUp => '热身';

  @override
  String get warmupCooldownCard1Min => '1 分钟';

  @override
  String warmupCooldownCardMin(Object warmupDurationMinutes) {
    return '$warmupDurationMinutes 分钟';
  }

  @override
  String get warmupCooldownCardPreciseDurationControl1 => '精确时长控制（1-15 分钟）';

  @override
  String get warmupCooldownCardWarmupCooldown => '热身与拉伸';

  @override
  String get warmupPhaseIncline => '坡度';

  @override
  String get warmupPhaseIntervals => '间歇';

  @override
  String get warmupPhasePause => '暂停';

  @override
  String warmupPhaseScreenSec(Object duration) {
    return '$duration 秒';
  }

  @override
  String get warmupPhaseSkipWarmup => '跳过热身';

  @override
  String get warmupPhaseSpeed => '速度';

  @override
  String get warmupPhaseStartWorkout => '开始训练';

  @override
  String get warmupPhaseUpNext => '接下来';

  @override
  String get warmupPhaseWarmUp => '热身';

  @override
  String get warmupSettingsCooldownStretchDuration => '拉伸时长';

  @override
  String get warmupSettingsEnableCooldownStretch => '启用训练后拉伸';

  @override
  String get warmupSettingsEnableWarmupPhase => '启用热身阶段';

  @override
  String get warmupSettingsHowLongToStretch => '训练后拉伸的时长';

  @override
  String get warmupSettingsHowLongToWarm => '训练前热身的时长';

  @override
  String get warmupSettingsIncompleteExerciseWarning => '未完成动作警告';

  @override
  String warmupSettingsSectionMin(Object label, Object minutes) {
    return '$label ($minutes 分钟)';
  }

  @override
  String get warmupSettingsShowStretchScreenAfter => '训练后显示拉伸界面';

  @override
  String get warmupSettingsShowWarmupScreenBefore => '训练前显示热身界面';

  @override
  String get warmupSettingsTipsForEffectiveWarm => '有效热身的小贴士：';

  @override
  String get warmupSettingsWarmupCooldown => '热身与拉伸';

  @override
  String get warmupSettingsWarmupDuration => '热身时长';

  @override
  String get warmupSettingsWarnBeforeFinishingWith => '结束前若有未记录组数则发出警告';

  @override
  String get watchInstallBannerCouldNotOpenPlay => '无法在手表上打开 Play Store。请手动安装。';

  @override
  String get watchInstallBannerFailedToConnectTo => '无法连接到手表。请重试。';

  @override
  String get watchInstallBannerInstallOnWatch => '在手表上安装';

  @override
  String get watchInstallBannerNotNow => '暂不';

  @override
  String get watchInstallBannerTrackWorkoutsFromYour => '通过手腕追踪训练';

  @override
  String get watchInstallBannerWatchDetected => '已检测到手表';

  @override
  String get wearOsAutomaticDataSync => '自动数据同步';

  @override
  String get wearOsComingFeatures => '即将推出的功能：';

  @override
  String get wearOsLogSetsDirectlyFromWatch => '直接在手表上记录组数';

  @override
  String get wearOsQuickFoodLoggingViaVoice => '语音快速记录饮食';

  @override
  String get wearOsRealTimeHeartRateTracking => '实时心率追踪';

  @override
  String get wearOsSmartwatch => '智能手表';

  @override
  String get wearOsTrackWorkoutsFromYour => '通过手腕追踪训练';

  @override
  String get wearOsWearOs => 'WEAR OS';

  @override
  String get week1TipBannerTryIt => '立即尝试';

  @override
  String get weekChangesCardConsistent => '保持一致';

  @override
  String get weekChangesCardLastWeek => '上周';

  @override
  String weekChangesCardMoreNewExercises(Object newExercises) {
    return '+$newExercises 项更多新动作';
  }

  @override
  String get weekChangesCardNewThisWeek => '本周新增';

  @override
  String get weekChangesCardRotatedOut => '已移除';

  @override
  String get weekChangesCardThisWeek => '本周';

  @override
  String get weekChangesCardThisWeekSChanges => '本周变化';

  @override
  String get weekChangesCardWeekComparison => '周对比';

  @override
  String get weekChangesCardYourFirstWeek => '您的第一周';

  @override
  String get weekDurationSelectorCustomizeDuration => '自定义时长';

  @override
  String get weekDurationSelectorDuration => '时长';

  @override
  String get weekDurationSelectorSessionsWeek => '每周训练次数';

  @override
  String weekDurationSelectorW(Object first) {
    return '$first周';
  }

  @override
  String weekDurationSelectorWeeks(Object selectedWeeks) {
    return '$selectedWeeks 周';
  }

  @override
  String weekDurationSelectorWk(Object spw) {
    return '$spw次/周';
  }

  @override
  String weekProgressStripCompletedCount(Object arg0, Object arg1) {
    return '已完成 $arg0 $arg1';
  }

  @override
  String get weekProgressStripCouldNotLoadProgress => '无法加载进度';

  @override
  String get weekProgressStripLoading => '加载中...';

  @override
  String get weekProgressStripNoWorkoutsScheduled => '暂无计划训练';

  @override
  String get weekProgressStripThisWeek => '本周';

  @override
  String get weekProgressStripViewAll => '查看全部';

  @override
  String get weeklyCalendarTileThisWeek => '本周';

  @override
  String get weeklyCheckinAnalyzingYourProgress => '正在分析您的进度...';

  @override
  String get weeklyCheckinAppearsOnceAWeek => '每周出现一次';

  @override
  String get weeklyCheckinApplyChanges => '应用更改';

  @override
  String get weeklyCheckinConservativeModerateOrAgg =>
      '保守、适中或激进——每种方案都有不同的热量目标和预期的每周变化。';

  @override
  String get weeklyCheckinDisable => '禁用';

  @override
  String get weeklyCheckinDisableWeeklyCheckIn => '禁用每周打卡？';

  @override
  String get weeklyCheckinDonTShowThis => '不再显示';

  @override
  String get weeklyCheckinGotIt => '知道了';

  @override
  String get weeklyCheckinGotItShowMy => '知道了——显示我的打卡';

  @override
  String get weeklyCheckinKeepCurrent => '保持当前';

  @override
  String get weeklyCheckinKeepIt => '保留它';

  @override
  String get weeklyCheckinPickAPlanTo => '选择一个计划来更新您的目标，或跳过以保持现状。不会自动进行任何更改。';

  @override
  String get weeklyCheckinPleaseTryAgainLater => '请稍后再试';

  @override
  String get weeklyCheckinReviewProgressChooseYour => '回顾进度并选择您的路径';

  @override
  String get weeklyCheckinSheetAdherence => '依从性';

  @override
  String get weeklyCheckinSheetAdherenceSustainability => '依从性与可持续性';

  @override
  String get weeklyCheckinSheetAvgCalories => '平均热量';

  @override
  String get weeklyCheckinSheetAvgProtein => '平均蛋白质';

  @override
  String get weeklyCheckinSheetBasedOnActualIntake => '基于实际摄入量和体重变化';

  @override
  String get weeklyCheckinSheetBuildingYourProfile => '正在建立您的个人资料';

  @override
  String get weeklyCheckinSheetCalories => '热量';

  @override
  String get weeklyCheckinSheetCaloriesDay => '卡路里/天';

  @override
  String get weeklyCheckinSheetCarbs => '碳水化合物';

  @override
  String get weeklyCheckinSheetChooseYourPath => '选择您的路径';

  @override
  String get weeklyCheckinSheetComplete => '完成！';

  @override
  String get weeklyCheckinSheetConfidenceRange => '置信区间';

  @override
  String get weeklyCheckinSheetDataQuality => '数据质量';

  @override
  String get weeklyCheckinSheetDaysLogged => '记录天数';

  @override
  String get weeklyCheckinSheetEmaSmoothedCalculation => 'EMA平滑计算';

  @override
  String weeklyCheckinSheetEveryWeekAnalysesYour(Object appName) {
    return '每周，$appName 都会分析您的饮食记录，以计算您身体实际消耗的热量，并根据您的真实进展建议更科学的热量和宏量营养素目标。';
  }

  @override
  String get weeklyCheckinSheetFat => '脂肪';

  @override
  String get weeklyCheckinSheetFoodLogging => '饮食记录';

  @override
  String get weeklyCheckinSheetKeepLogging => '继续记录！';

  @override
  String get weeklyCheckinSheetKeepLoggingYourMeals =>
      '继续记录您的饮食和体重，以解锁个性化的TDEE计算。';

  @override
  String get weeklyCheckinSheetLogMealsConsistentlyFor => '持续记录饮食以获得最佳结果';

  @override
  String get weeklyCheckinSheetMetabolicAdaptationDetected => '检测到代谢适应';

  @override
  String get weeklyCheckinSheetNeed60DataQuality => '需要60%的数据质量以进行准确计算';

  @override
  String get weeklyCheckinSheetNewTargets => '新目标';

  @override
  String weeklyCheckinSheetPartRecommendationOptionCardCal(Object calories) {
    return '$calories kcal';
  }

  @override
  String weeklyCheckinSheetPartRecommendationOptionCardDays(
    Object current,
    Object target,
  ) {
    return '$current / $target 天';
  }

  @override
  String weeklyCheckinSheetPartRecommendationOptionCardGC(Object carbsG) {
    return '${carbsG}g 碳水';
  }

  @override
  String weeklyCheckinSheetPartRecommendationOptionCardGF(Object fatG) {
    return '${fatG}g 脂肪';
  }

  @override
  String weeklyCheckinSheetPartRecommendationOptionCardGP(Object proteinG) {
    return '${proteinG}g 蛋白质';
  }

  @override
  String weeklyCheckinSheetPartWeeklySummaryCardG(Object avgProtein) {
    return '${avgProtein}g';
  }

  @override
  String weeklyCheckinSheetPartWeeklySummaryCardValue(Object daysLogged) {
    return '$daysLogged/7';
  }

  @override
  String weeklyCheckinSheetPartWeeklySummaryCardValue2(
    Object dataQualityPercent,
  ) {
    return '$dataQualityPercent%';
  }

  @override
  String weeklyCheckinSheetPartWeeklySummaryCardValue3(Object value) {
    return '$value%';
  }

  @override
  String weeklyCheckinSheetPartWeeklySummaryCardWeightTrend(
    Object formattedWeeklyRate,
  ) {
    return '体重趋势：$formattedWeeklyRate';
  }

  @override
  String get weeklyCheckinSheetPlateauDetected => '检测到平台期';

  @override
  String get weeklyCheckinSheetProtein => '蛋白质';

  @override
  String get weeklyCheckinSheetRecommended => '推荐';

  @override
  String get weeklyCheckinSheetRecommendedAdjustment => '推荐调整';

  @override
  String get weeklyCheckinSheetSelectARecommendationBased => '根据您的偏好选择推荐方案';

  @override
  String weeklyCheckinSheetSuggestedAction(Object action) {
    return '建议：$action';
  }

  @override
  String get weeklyCheckinSheetSustainability => '可持续性';

  @override
  String weeklyCheckinSheetSustainabilityRating(Object rating) {
    return '$rating 可持续性';
  }

  @override
  String get weeklyCheckinSheetThisWeek => '本周';

  @override
  String get weeklyCheckinSheetTipsForBetterResults => '获得更好结果的建议';

  @override
  String get weeklyCheckinSheetWeNeedABit => '我们需要更多数据来计算您的个性化TDEE。';

  @override
  String get weeklyCheckinSheetWeightChange => '体重变化';

  @override
  String get weeklyCheckinSheetWeightLogs => '体重记录';

  @override
  String get weeklyCheckinSheetYouReOnTrack => '您在正轨上！';

  @override
  String get weeklyCheckinSheetYourAdaptiveTdee => '您的自适应TDEE';

  @override
  String get weeklyCheckinSheetYourCurrentTargetsAre => '您当前的目标与您的进度一致。继续保持！';

  @override
  String get weeklyCheckinSkipThisWeek => '跳过本周';

  @override
  String get weeklyCheckinTryAgain => '重试';

  @override
  String get weeklyCheckinUnableToLoadData => '无法加载数据';

  @override
  String get weeklyCheckinWeAnalyseYourWeek => '我们分析您的这一周';

  @override
  String get weeklyCheckinWeeklyCheckIn => '每周打卡';

  @override
  String get weeklyCheckinWhatHappensEachWeek => '每周会发生什么';

  @override
  String get weeklyCheckinWhatIsThis => '这是什么？';

  @override
  String get weeklyCheckinWhatIsWeeklyCheck => '什么是每周打卡？';

  @override
  String get weeklyCheckinYouCanReEnable => '您可以随时在营养设置中重新启用此功能。';

  @override
  String get weeklyCheckinYouCanTurnThis => '您可以随时在“营养设置”→“每周打卡提醒”中关闭此功能。';

  @override
  String get weeklyCheckinYouChooseOrSkip => '由您选择——或跳过';

  @override
  String get weeklyCheckinYouLlMissOut => '您将错过：';

  @override
  String get weeklyCheckinYouSee23 => '您会看到2-3个计划选项';

  @override
  String get weeklyCheckinYourLoggedMealsAnd =>
      '您记录的饮食和体重数据用于计算您的真实TDEE——比任何公式都更准确。';

  @override
  String weeklyGoalsCardNewPr(Object prsThisWeek) {
    return '🏆 $prsThisWeek 项新 PR！';
  }

  @override
  String get weeklyGoalsCardSetAChallengeTo => '设定一个挑战来突破您的极限！';

  @override
  String get weeklyGoalsCardWeeklyGoals => '每周目标';

  @override
  String get weeklyHighlightsTemplateAiHighlights => 'AI亮点';

  @override
  String get weeklyHighlightsTemplateAnotherWeekInThe => '又过去了一周。坚持才是真正的实力。';

  @override
  String get weeklyHighlightsTemplateThisWeek => '本周';

  @override
  String weeklyPercentileHeroOfActiveUsersTap(
    Object totalActive,
    Object yourRank,
  ) {
    return '在 $totalActive 名活跃用户中排名第 #$yourRank · 点击发现更多';
  }

  @override
  String weeklyPercentileHeroTopThisWeek(Object topPct) {
    return '本周前 $topPct%';
  }

  @override
  String get weeklyPlanCardCreateYourWeeklyPlan => '创建您的每周计划';

  @override
  String get weeklyPlanCardGetAHolisticPlan => '获取协调锻炼、营养和禁食的整体计划';

  @override
  String get weeklyPlanCardTodaySPlan => '今日计划';

  @override
  String get weeklyPlanCardWeeklyPlan => '每周计划';

  @override
  String get weeklyPlanCreateAHolisticPlan => '创建一个协调您本周锻炼、营养和禁食安排的整体计划。';

  @override
  String get weeklyPlanErrorLoadingPlan => '加载计划时出错';

  @override
  String get weeklyPlanGenerateMyPlan => '生成我的计划';

  @override
  String get weeklyPlanGeneratePlan => '生成计划';

  @override
  String get weeklyPlanNoWeeklyPlanYet => '暂无周计划';

  @override
  String get weeklyPlanWeeklyPlan => '周计划';

  @override
  String weeklyProgressCardOfWorkouts(Object completed, Object total) {
    return '$completed / $total 次训练';
  }

  @override
  String get weeklyPrsTemplate1Pr => '1 个 PR';

  @override
  String weeklyPrsTemplateMore(Object length) {
    return '+ 更多 $length 项';
  }

  @override
  String get weeklyPrsTemplateNoPrsThisWeek => '本周无 PR';

  @override
  String get weeklyPrsTemplatePersonalRecords => '个人纪录';

  @override
  String weeklyPrsTemplatePrs(Object count) {
    return '$count 项 PR';
  }

  @override
  String get weeklyPrsTemplateShowingUpIsThe => '坚持就是胜利。下周继续加油。';

  @override
  String get weeklyRecap => '🛡️';

  @override
  String get weeklyRecapBonusRound => '奖励环节';

  @override
  String get weeklyRecapCatchNutrientsWinBonus => '获取营养，赢取额外 XP';

  @override
  String weeklyRecapDialogRankShieldsActivated(Object count) {
    return '已激活 $count 个排名护盾';
  }

  @override
  String weeklyRecapDialogValue(Object rank) {
    return '第$rank名';
  }

  @override
  String weeklyRecapDialogWeekIn(Object tierLabel, Object weeks) {
    return '在 $tierLabel 的第 $weeks 周';
  }

  @override
  String weeklyRecapDialogXp(Object shown) {
    return '+$shown XP';
  }

  @override
  String weeklyRecapDialogXp2(Object xp) {
    return '+$xp XP';
  }

  @override
  String get weeklyRecapEarnedLastWeek => '上周获得';

  @override
  String get weeklyRecapLastWeek => '上周回顾';

  @override
  String get weeklyRecapPassed => '已超越';

  @override
  String get weeklyRecapPassedBy => '被超越';

  @override
  String get weeklyRecapRankShieldActivatedStreak => '排名保护盾已激活 — 连胜已保留';

  @override
  String get weeklyRecapRewardsUnlocked => '已解锁奖励';

  @override
  String get weeklyRecapStartThisWeek => '开始本周 →';

  @override
  String get weeklyRecapTemplatePrs => 'PR';

  @override
  String get weeklyRecapTemplateStreak => '连胜';

  @override
  String weeklyRecapTemplateValue(Object pct) {
    return '$pct%';
  }

  @override
  String get weeklyRecapTemplateWorkouts => '训练';

  @override
  String get weeklyRecapWeeklyRecap => '周回顾';

  @override
  String weeklyReportCardDayStreak(Object streak) {
    return '连续 $streak 天打卡';
  }

  @override
  String weeklyReportCardOfWorkoutsThisWeek(
    Object completed,
    Object scheduled,
  ) {
    return '本周已完成 $completed/$scheduled 次训练';
  }

  @override
  String get weeklyReportCardReportsInsights => '报告与洞察';

  @override
  String weeklyReportCardValue(Object pct) {
    return '$pct%';
  }

  @override
  String get weeklyReportCardViewReport => '查看报告';

  @override
  String get weeklySummaryAiSummary => 'AI 总结';

  @override
  String get weeklySummaryGenerateSummary => '生成总结';

  @override
  String get weeklySummaryGenerateYourFirstWeekly =>
      '生成您的第一个周总结，通过 AI 驱动的洞察查看您的进度';

  @override
  String get weeklySummaryHighlights => '亮点';

  @override
  String get weeklySummaryNoSummariesYet => '暂无总结';

  @override
  String weeklySummaryScreenDayStreak(Object streak) {
    return '连续 $streak 天';
  }

  @override
  String weeklySummaryScreenPrs(Object count) {
    return '$count 项 PR';
  }

  @override
  String weeklySummaryScreenValue(Object completionRate) {
    return '$completionRate%';
  }

  @override
  String weeklySummaryScreenWorkoutsCompleted(
    Object workoutsCompleted,
    Object workoutsScheduled,
  ) {
    return '已完成 $workoutsCompleted/$workoutsScheduled 次训练';
  }

  @override
  String get weeklySummaryShareReport => '分享报告';

  @override
  String get weeklySummaryTapToViewDetails => '点击查看详情';

  @override
  String get weeklySummaryTipsForNextWeek => '下周建议';

  @override
  String get weeklySummaryWeeklySummaries => '周总结';

  @override
  String get weeklySummaryWeeklySummaryGenerated => '周总结已生成！';

  @override
  String get weeklyVolumeBarsWeeklyVolumePerMuscle => '各肌肉群周训练量';

  @override
  String get weeklyWrappedFromYourCoach => '来自您的教练';

  @override
  String get weeklyWrappedNoWorkoutsScheduledYet => '暂无预定训练。请在首页生成计划。';

  @override
  String get weeklyWrappedPrs => 'PR';

  @override
  String get weeklyWrappedSets => '组数';

  @override
  String get weeklyWrappedStreak => '连胜';

  @override
  String get weeklyWrappedYourWeek => '本周回顾';

  @override
  String get weightFastingChartNoWeightDataAvailable => '暂无体重数据';

  @override
  String get weightFastingChartWeightTrends => '体重趋势';

  @override
  String get weightIncrementsBarbell => '杠铃';

  @override
  String get weightIncrementsBasedOnStandardCommercial => '基于标准商用健身器材：';

  @override
  String get weightIncrementsCardConfigureIncrements => '配置增量';

  @override
  String get weightIncrementsCardCustomizeStepPerEquipme => '自定义每种器材的 +/- 步长';

  @override
  String get weightIncrementsCardWeightIncrements => '重量增量';

  @override
  String get weightIncrementsCustomIncrement => '自定义增量';

  @override
  String get weightIncrementsCustomizeStepSizePer => '自定义每种器材的 +/- 步长';

  @override
  String get weightIncrementsEG25 => '例如 2.5';

  @override
  String get weightIncrementsGotIt => '知道了';

  @override
  String get weightIncrementsPerSide => '单侧';

  @override
  String get weightIncrementsSet => '设置';

  @override
  String weightIncrementsSheetSide(Object unit) {
    return '每侧 $unit';
  }

  @override
  String weightIncrementsSheetTotal(Object unit) {
    return '总计 $unit';
  }

  @override
  String get weightIncrementsSourcesRogueLifeFitness =>
      '来源：Rogue, Life Fitness, Eleiko';

  @override
  String get weightIncrementsUseDefaults => '使用默认值';

  @override
  String get weightIncrementsWeightIncrements => '重量增量';

  @override
  String get weightProjectionCurrent => '当前';

  @override
  String get weightProjectionHowFastDoYou => '您希望以多快的速度减重？';

  @override
  String get weightProjectionPerWeek => '每周';

  @override
  String get weightProjectionSafeRate05 => '安全速率：每周 0.5–1 公斤。您的计划遵循循证指南。';

  @override
  String get weightProjectionScreenContinueToYourPlan => '继续您的计划';

  @override
  String weightProjectionScreenDaysWk(Object workoutDays) {
    return '$workoutDays 天/周';
  }

  @override
  String get weightProjectionScreenLetSKeepYou =>
      '让我们保持现状！我们将专注于维持您当前的体格，同时提升您的整体健康、力量和能量水平。';

  @override
  String get weightProjectionScreenYouReAtYour => '您已达到理想体重！';

  @override
  String get weightProjectionToGain => '增重';

  @override
  String get weightProjectionToLose => '减重';

  @override
  String get weightTrackingCardHighest => '最高';

  @override
  String get weightTrackingCardLowest => '最低';

  @override
  String get weightTrackingCardRecentEntries => '近期记录';

  @override
  String get weightTrackingCardSeeAll => '查看全部';

  @override
  String weightTrackingCardValue(Object label, Object value) {
    return '$value · $label';
  }

  @override
  String get weightTrackingCardWeightTracking => '体重追踪';

  @override
  String weightTrendCardDownThisWeek(Object arg0) {
    return '本周下降 $arg0';
  }

  @override
  String weightTrendCardDownVsLastCycle(Object arg0) {
    return '较上一周期下降 $arg0';
  }

  @override
  String get weightTrendCardLoadingWeight => '正在加载体重...';

  @override
  String get weightTrendCardLogYourWeightTo => '记录体重以查看趋势';

  @override
  String get weightTrendCardMaintaining => '保持中';

  @override
  String get weightTrendCardNoChange => '无变化';

  @override
  String get weightTrendCardNoData => '暂无数据';

  @override
  String get weightTrendCardOnTrack => '进展顺利';

  @override
  String get weightTrendCardReviewGoals => '查看目标';

  @override
  String get weightTrendCardSameAsLastCycle => '与上一周期持平';

  @override
  String get weightTrendCardTapToLogWeight => '点击记录体重';

  @override
  String get weightTrendCardTargetHeld => '已达标';

  @override
  String weightTrendCardTargetHeldWindow(Object arg0) {
    return '达标区间 $arg0';
  }

  @override
  String weightTrendCardUpThisWeek(Object arg0) {
    return '本周上升 $arg0';
  }

  @override
  String weightTrendCardUpVsLastCycle(Object arg0) {
    return '较上一周期上升 $arg0';
  }

  @override
  String get weightTrendCardWeightStableThisWeek => '本周体重稳定';

  @override
  String get weightTrendCardWeightTrends => '体重趋势';

  @override
  String get welcomeAffirmationGreatChoice => '明智的选择。';

  @override
  String get welcomeAffirmationLetSBegin => '让我们开始吧';

  @override
  String get welcomeAffirmationMostUsersHitTheir => '大多数用户在 30 天内实现了第一个里程碑';

  @override
  String get welcomeAffirmationYouReAboutTo => '您很快也会成为其中一员。';

  @override
  String get welcomeAffirmationYouReInThe => '您来对地方了。\n让我们一起制定您的计划。';

  @override
  String get wellnessCheckinCardAddANoteOptional => '添加备注（可选）';

  @override
  String get wellnessCheckinCardCheckedInU2713 => '已打卡 ✓';

  @override
  String get wellnessCheckinCardDailyWellnessCheckIn => '每日健康打卡';

  @override
  String wellnessCheckinCardEnergy(Object energyLevel) {
    return '精力 $energyLevel  ';
  }

  @override
  String get wellnessCheckinCardEnergyLevel => '能量水平';

  @override
  String get wellnessCheckinCardHowSYourMood => '今天心情如何？';

  @override
  String get wellnessCheckinCardMuscleSoreness => '肌肉酸痛感';

  @override
  String wellnessCheckinCardSleep(Object sleepQuality) {
    return '睡眠 $sleepQuality  ';
  }

  @override
  String get wellnessCheckinCardSleepQuality => '睡眠质量';

  @override
  String wellnessCheckinCardSoreness(Object muscleSoreness) {
    return '酸痛 $muscleSoreness  ';
  }

  @override
  String wellnessCheckinCardStress(Object stressLevel) {
    return '压力 $stressLevel  ';
  }

  @override
  String get wellnessCheckinCardStressLevel => '压力水平';

  @override
  String get wellnessCheckinCardU1f9d8 => '🧘';

  @override
  String get workoutActionsChangeWorkoutDate => '更改训练日期';

  @override
  String get workoutActionsCompleteTheWorkoutFirst => '请先完成训练以生成分享链接';

  @override
  String get workoutActionsCoolDownStretches => '冷身拉伸';

  @override
  String get workoutActionsCouldNotCreateShare => '无法创建分享链接';

  @override
  String get workoutActionsCreateCoolDownStretches => '创建冷身拉伸';

  @override
  String get workoutActionsCreateWarmupExercises => '创建热身运动';

  @override
  String get workoutActionsCurrent => '当前';

  @override
  String get workoutActionsDeleteWorkout => '删除训练';

  @override
  String get workoutActionsDeleteWorkout2 => '确定删除训练吗？';

  @override
  String get workoutActionsFailedToGenerateStretches => '无法生成拉伸动作';

  @override
  String get workoutActionsFailedToGenerateWarmup => '无法生成热身动作';

  @override
  String get workoutActionsFailedToRegenerateWorkout => '无法重新生成训练';

  @override
  String get workoutActionsFailedToRescheduleWorkout => '无法重新安排训练';

  @override
  String get workoutActionsFinishThisWorkoutTo => '完成此训练即可分享';

  @override
  String get workoutActionsGenerateStretches => '生成拉伸动作';

  @override
  String get workoutActionsGenerateWarmup => '生成热身动作';

  @override
  String get workoutActionsLinkCopiedToClipboard => '链接已复制到剪贴板';

  @override
  String get workoutActionsNoVersionHistory => '无版本历史记录';

  @override
  String get workoutActionsRegenerate => '重新生成';

  @override
  String get workoutActionsRegenerateWorkout => '确定重新生成训练吗？';

  @override
  String get workoutActionsRemoveThisWorkout => '移除此训练';

  @override
  String get workoutActionsReschedule => '重新安排';

  @override
  String get workoutActionsRevert => '还原';

  @override
  String get workoutActionsRevertToThisVersion => '确定还原到此版本吗？';

  @override
  String get workoutActionsShareWorkout => '分享训练';

  @override
  String workoutActionsSheetGetALinkFor(Object marketingDomain) {
    return '获取 $marketingDomain 链接分享给好友';
  }

  @override
  String workoutActionsSheetN(Object appName, Object url) {
    return ') — Zealova\n(url)';
  }

  @override
  String workoutActionsSheetRestore(Object name) {
    return '恢复 “$name”？';
  }

  @override
  String workoutActionsSheetS(Object duration) {
    return '$duration 秒';
  }

  @override
  String workoutActionsSheetV(Object versionNum) {
    return 'v$versionNum';
  }

  @override
  String workoutActionsSheetValue(
    Object _regenerateMessage,
    Object _regenerateStep,
    Object _regenerateTotalSteps,
  ) {
    return '$_regenerateMessage ($_regenerateStep/$_regenerateTotalSteps)';
  }

  @override
  String workoutActionsSheetWorkout(Object appName) {
    return '$appName 训练';
  }

  @override
  String get workoutActionsThisActionCannotBe => '此操作无法撤销。';

  @override
  String get workoutActionsThisWillCreateA =>
      '这将为当天创建一个新的训练计划。当前的训练将保存在版本历史记录中。';

  @override
  String get workoutActionsThisWorkoutCannotBe => '此训练暂无法分享';

  @override
  String get workoutActionsVersionHistory => '版本历史记录';

  @override
  String get workoutActionsViewAndRestorePrevious => '查看并恢复之前的版本';

  @override
  String get workoutActionsWarmupExercises => '热身运动';

  @override
  String get workoutActionsWorkoutDeleted => '训练已删除';

  @override
  String get workoutActionsWorkoutOptions => '训练选项';

  @override
  String get workoutActionsWorkoutRegenerated => '训练已重新生成';

  @override
  String get workoutActionsWorkoutRescheduled => '训练已重新安排';

  @override
  String get workoutAiCoachAddAMessageOptional => '添加留言（可选）...';

  @override
  String get workoutAiCoachAskMeAnythingAbout => '关于训练，尽管问我！';

  @override
  String get workoutAiCoachChangeCoach => '更换教练';

  @override
  String get workoutAiCoachFailedToLoadChat => '无法加载聊天记录';

  @override
  String get workoutAiCoachForm => '动作规范';

  @override
  String get workoutAiCoachRest => '休息';

  @override
  String get workoutAiCoachSets => '组数';

  @override
  String workoutAiCoachSheetCheckMyFormOn(Object name) {
    return '检查我的 $name 动作姿势';
  }

  @override
  String workoutAiCoachSheetHowLongShouldI(Object name) {
    return '做 $name 时组间休息多久合适？';
  }

  @override
  String workoutAiCoachSheetHowManySetsShould(Object name) {
    return '为了达到最佳效果，$name 应该做几组？';
  }

  @override
  String workoutAiCoachSheetWhatAreSomeAlternative(Object name) {
    return '有哪些可以替代 $name 的动作？';
  }

  @override
  String workoutAiCoachSheetWhatAreTheKey(Object name) {
    return '$name 的关键动作要点是什么？';
  }

  @override
  String get workoutAiCoachSwaps => '替换';

  @override
  String get workoutBottomBarInstructions => '说明';

  @override
  String get workoutBottomBarSkip => '跳过';

  @override
  String get workoutCompleteAdding => '添加中...';

  @override
  String get workoutCompleteDoMore => '做更多';

  @override
  String get workoutCompleteGiveDetailedFeedback => '提供详细反馈';

  @override
  String get workoutCompleteHowWasTheDifficulty => '难度如何？';

  @override
  String get workoutCompleteHowWasYourWorkout => '今天的训练感觉如何？';

  @override
  String get workoutCompleteJustRight => '刚刚好';

  @override
  String get workoutCompleteLess => '较少';

  @override
  String get workoutCompleteLogWater => '记录饮水';

  @override
  String get workoutCompleteMoreActions => '更多操作';

  @override
  String get workoutCompleteRateExercises => '评价动作';

  @override
  String get workoutCompleteSauna => '桑拿';

  @override
  String get workoutCompleteScreenCal => '卡路里';

  @override
  String get workoutCompleteScreenDuration => '时长';

  @override
  String get workoutCompleteScreenEnergy => '能量';

  @override
  String get workoutCompleteScreenExerciseProgress => '训练进度';

  @override
  String workoutCompleteScreenExt1AddedMoreExercises(Object length) {
    return '已添加 $length 个练习！';
  }

  @override
  String workoutCompleteScreenExt1ErrorCompletingChallenge(Object e) {
    return '完成挑战时出错：$e';
  }

  @override
  String workoutCompleteScreenExt1GreatWillBeIncluded(
    Object suggestedNextVariant,
  ) {
    return '太棒了！$suggestedNextVariant 将被包含在未来的锻炼中。';
  }

  @override
  String workoutCompleteScreenExt2OfRated(Object length, Object length1) {
    return '$length / $length1 已评分';
  }

  @override
  String workoutCompleteScreenExt2PrKg(Object maxWeight) {
    return 'PR: $maxWeight kg';
  }

  @override
  String get workoutCompleteScreenFailedToExtendWorkout => '无法延长训练。请重试。';

  @override
  String get workoutCompleteScreenFeelingStrongerToday => '今天感觉更强了！';

  @override
  String get workoutCompleteScreenGoBack => '返回';

  @override
  String get workoutCompleteScreenHard => '困难';

  @override
  String get workoutCompleteScreenHeartRateAnalysis => '心率分析';

  @override
  String get workoutCompleteScreenHeartRateMetrics => '心率指标';

  @override
  String get workoutCompleteScreenHideDetails => '隐藏详情';

  @override
  String get workoutCompleteScreenHowDoYouFeel => '你现在感觉如何？';

  @override
  String get workoutCompleteScreenLevelUp => '升级';

  @override
  String workoutCompleteScreenMin(Object _saunaMinutes) {
    return '$_saunaMinutes 分钟';
  }

  @override
  String workoutCompleteScreenMinSaunaCal(
    Object _saunaCalories,
    Object _saunaMinutes,
  ) {
    return '$_saunaMinutes 分钟桑拿 · ~$_saunaCalories 卡路里';
  }

  @override
  String get workoutCompleteScreenMood => '心情';

  @override
  String get workoutCompleteScreenNewPersonalRecords => '新的个人纪录！';

  @override
  String get workoutCompleteScreenNoData => '暂无数据';

  @override
  String get workoutCompleteScreenNoWorkoutDataTo => '暂无训练数据可分享';

  @override
  String get workoutCompleteScreenNotYet => '暂不';

  @override
  String get workoutCompleteScreenNoticeImprovementsInYour => '发现力量或耐力有所提升？';

  @override
  String get workoutCompleteScreenPleaseRateYourWorkout => '请评价本次训练';

  @override
  String get workoutCompleteScreenRateIndividualExercises => '评价单个动作';

  @override
  String get workoutCompleteScreenRatingsHelpOurAi =>
      '评分有助于我们的AI制定更好的训练计划。确定要跳过吗？';

  @override
  String get workoutCompleteScreenReadyToLevelUp => '准备好升级了！';

  @override
  String get workoutCompleteScreenReps => '次数';

  @override
  String get workoutCompleteScreenSets => '组数';

  @override
  String get workoutCompleteScreenShowAllStats => '显示所有统计数据';

  @override
  String get workoutCompleteScreenSkipRating => '跳过评分？';

  @override
  String get workoutCompleteScreenTime => '时间';

  @override
  String get workoutCompleteScreenTotalReps => '总次数';

  @override
  String get workoutCompleteScreenTotalWorkout => '总训练量';

  @override
  String get workoutCompleteScreenTrackYourMoodTo => '记录心情以查看进度';

  @override
  String get workoutCompleteScreenTrophiesEarned => '获得奖杯！';

  @override
  String get workoutCompleteScreenTrophiesMilestones => '奖杯与里程碑';

  @override
  String get workoutCompleteScreenU1f4aa => '💪';

  @override
  String workoutCompleteScreenUi1DayStreakTotalWorkouts(
    Object streak,
    Object totalWorkouts,
  ) {
    return '连续 $streak 天，总计 $totalWorkouts 次训练';
  }

  @override
  String workoutCompleteScreenUi1MarkedAsTooEasy(
    Object consecutiveEasySessions,
  ) {
    return '连续 $consecutiveEasySessions 次被标记为“太简单”';
  }

  @override
  String workoutCompleteScreenUi1RmKg(Object estimated1rm) {
    return '1RM: $estimated1rm kg';
  }

  @override
  String workoutCompleteScreenUi2Kg(Object currentTotalVolumeKg) {
    return '$currentTotalVolumeKg kg';
  }

  @override
  String workoutCompleteScreenUi2KgXReps(Object currentReps, Object exComp) {
    return '$exComp kg x $currentReps 次';
  }

  @override
  String workoutCompleteScreenUi2SetsReps(
    Object currentReps,
    Object currentSets,
  ) {
    return '$currentSets 组，$currentReps 次';
  }

  @override
  String workoutCompleteScreenUi2Value(Object workoutComp) {
    return ')(workoutComp)';
  }

  @override
  String get workoutCompleteScreenUnableToChallengeFriends => '目前无法挑战好友';

  @override
  String get workoutCompleteScreenUnableToExtendWorkout => '无法延长训练';

  @override
  String get workoutCompleteScreenViewAllMetrics => '查看所有指标';

  @override
  String get workoutCompleteScreenViewGoals => '查看目标';

  @override
  String get workoutCompleteScreenVolume => '容量';

  @override
  String workoutCompleteScreenWorkout(Object appName) {
    return 'Zealova 训练';
  }

  @override
  String get workoutCompleteScreenYouDonTHave => '你还没有好友。先添加一些好友吧！';

  @override
  String get workoutCompleteScreenYouVeMasteredThese => '你已经掌握了这些动作。要尝试更难的变式吗？';

  @override
  String get workoutCompleteSkipRating => '跳过评分';

  @override
  String get workoutCompleteSummary => '总结';

  @override
  String get workoutCompleteThisWeek => '本周';

  @override
  String get workoutCompleteTooEasy => '太简单';

  @override
  String get workoutCompleteTooHard => '太困难';

  @override
  String get workoutCompleteWorkoutComplete => '训练完成！';

  @override
  String get workoutCompleteYourRatingsHelpUs => '你的评分有助于我们个性化你未来的训练';

  @override
  String get workoutDayDetailAvgHr => '平均心率';

  @override
  String get workoutDayDetailAvgRpe => '平均 RPE';

  @override
  String get workoutDayDetailBestSet => '最佳组';

  @override
  String get workoutDayDetailCalories => '卡路里';

  @override
  String get workoutDayDetailCoachFeedback => '教练反馈';

  @override
  String get workoutDayDetailDistance => '距离';

  @override
  String get workoutDayDetailDuration => '时长';

  @override
  String get workoutDayDetailFailedToLoadDetails => '加载详情失败';

  @override
  String get workoutDayDetailMaxHr => '最大心率';

  @override
  String get workoutDayDetailMusclesWorked => '锻炼肌肉';

  @override
  String get workoutDayDetailRecoveryIsJustAs => '恢复与训练同样重要。你的肌肉在休息时才会生长！';

  @override
  String get workoutDayDetailRestDay => '休息日';

  @override
  String workoutDayDetailSheetScheduled(Object workoutName) {
    return '已安排：$workoutName';
  }

  @override
  String workoutDayDetailSheetSource(Object sourceApp) {
    return '来源：$sourceApp';
  }

  @override
  String get workoutDayDetailSyncedFromHealth => '已从健康同步';

  @override
  String get workoutDayDetailVolume => '容量';

  @override
  String get workoutDayDetailWorkoutMissed => '错过训练';

  @override
  String get workoutDaysChangingWorkoutDaysWill =>
      '更改训练日将更新你的日程安排。未来的训练计划将被重新生成。';

  @override
  String get workoutDaysSelectWhichDaysYou => '选择你想训练的日子';

  @override
  String workoutDaysSelectorDaysWeek(Object length) {
    return '$length天/周';
  }

  @override
  String get workoutDaysSelectorSelectWhichDaysYou => '选择你想训练的日子';

  @override
  String get workoutDaysSelectorWorkoutDays => '训练日';

  @override
  String workoutDaysSheetFailedToUpdateWorkout(Object e) {
    return '更新训练日失败：$e';
  }

  @override
  String get workoutDaysWorkoutDays => '训练日';

  @override
  String get workoutDetailAddSaunaTime => '添加桑拿时间';

  @override
  String get workoutDetailAiAiGenerationParameters => 'AI 生成参数';

  @override
  String get workoutDetailAiAiInsights => 'AI 洞察';

  @override
  String get workoutDetailAiExerciseSelection => '动作选择';

  @override
  String get workoutDetailAiGeneratingInsights => '正在生成洞察...';

  @override
  String get workoutDetailAiGeneratingNewInsights => '正在生成新洞察...';

  @override
  String workoutDetailAiInsightsMin(Object durationMinutes) {
    return '$durationMinutes 分钟';
  }

  @override
  String workoutDetailAiInsightsMin2(Object params) {
    return '$params 分钟';
  }

  @override
  String workoutDetailAiInsightsMoreExercises(Object exerciseReasoning) {
    return '+ $exerciseReasoning 个更多动作...';
  }

  @override
  String get workoutDetailAiLoadingAiReasoning => '正在加载 AI 推理...';

  @override
  String get workoutDetailAiProgramPreferences => '计划偏好';

  @override
  String get workoutDetailAiRegenerateInsights => '重新生成洞察';

  @override
  String get workoutDetailAiTapToSeeAi => '点击查看 AI 选择动作的理由';

  @override
  String get workoutDetailAiTheseParametersWereUsed =>
      'AI 使用这些参数来生成符合你健身水平、目标和可用器械的个性化动作。';

  @override
  String get workoutDetailAiUserProfile => '用户资料';

  @override
  String get workoutDetailAiViewAllParametersSent => '查看发送给 AI 的所有参数';

  @override
  String get workoutDetailAiWhyTheseExercises => '为什么选择这些动作？';

  @override
  String get workoutDetailAiWorkoutDesign => '训练设计';

  @override
  String get workoutDetailAiWorkoutSpecifics => '训练细节';

  @override
  String get workoutDetailCoolDownStretches => '冷身拉伸';

  @override
  String get workoutDetailDifficulty => '难度';

  @override
  String get workoutDetailEquipment => '器械';

  @override
  String get workoutDetailExercises => '动作';

  @override
  String get workoutDetailFailedToLoadWorkout => '加载训练失败';

  @override
  String get workoutDetailHelpersForAvailableEquipment => ') 用于可用器械...';

  @override
  String get workoutDetailHelpersHell => '地狱';

  @override
  String get workoutDetailHelpersUpdatingExercises => '正在更新动作';

  @override
  String get workoutDetailMoreInfo => '更多信息';

  @override
  String get workoutDetailProgram => '计划';

  @override
  String workoutDetailReplacingExercises(Object arg0) {
    return '正在替换动作 $arg0';
  }

  @override
  String get workoutDetailRevert => '还原';

  @override
  String get workoutDetailScreenBreakSuperset => '拆分超级组？';

  @override
  String workoutDetailScreenCalBurned(Object estimatedCalories) {
    return '~$estimatedCalories 卡路里消耗';
  }

  @override
  String get workoutDetailScreenCannotMergeSupersets => '无法合并超级组';

  @override
  String get workoutDetailScreenCannotRemoveTheLast => '无法移除最后一个动作';

  @override
  String get workoutDetailScreenChallenge => '挑战';

  @override
  String get workoutDetailScreenDiscardTheEquipmentChange => '彻底放弃设备更改。';

  @override
  String get workoutDetailScreenEquipmentUpdated => '设备已更新';

  @override
  String get workoutDetailScreenFailedToBlockExercise => '无法屏蔽练习';

  @override
  String get workoutDetailScreenFailedToRemoveExercise => '无法移除练习';

  @override
  String get workoutDetailScreenFailedToUpdateFavorite => '无法更新收藏';

  @override
  String get workoutDetailScreenKeepThisSessionUnchanged =>
      '保持本次训练不变。新设备将应用于未来的训练。';

  @override
  String get workoutDetailScreenLetSGo => '开始吧';

  @override
  String workoutDetailScreenMinSauna(Object durationMinutes) {
    return '$durationMinutes 分钟桑拿';
  }

  @override
  String get workoutDetailScreenNeverRecommend => '不再推荐';

  @override
  String get workoutDetailScreenNoThanks => '不用了';

  @override
  String workoutDetailScreenProgressionFrom(Object progressionFrom) {
    return '进度来自 $progressionFrom';
  }

  @override
  String get workoutDetailScreenRemoveExercise => '移除练习';

  @override
  String get workoutDetailScreenReplaceNow => '立即替换';

  @override
  String get workoutDetailScreenRevertToOriginal => '恢复为原始设置？';

  @override
  String get workoutDetailScreenSaveForNextWorkout => '保存以供下次训练使用';

  @override
  String get workoutDetailScreenSaveToProfile => '保存到个人资料？';

  @override
  String get workoutDetailScreenSupersetCreated => '超级组已创建！';

  @override
  String get workoutDetailScreenSwapThoseExercisesIn =>
      '替换本次训练中的练习。你已完成的组数将保留记录。';

  @override
  String get workoutDetailScreenTapAnotherExerciseTo => '点击另一个练习以关联为超级组';

  @override
  String get workoutDetailScreenThisIsAnOptional => '这是一个可选的高级练习。准备好后尝试一下吧！';

  @override
  String get workoutDetailScreenThisWillRestoreAll => '这将把所有练习恢复到应用设备更改前的原始状态。';

  @override
  String get workoutDetailScreenThisWillUnlinkThese => '这将取消这些练习的关联，使它们分开进行。';

  @override
  String workoutDetailScreenUi1AddToCreateA(Object name, Object newSetType) {
    return '将“$name”添加到 $newSetType 中吗？';
  }

  @override
  String workoutDetailScreenUi1AndAreAlreadyIn(Object name, Object name1) {
    return '“$name”和“$name1”已存在于不同的超级组中。\n\n请先拆除现有的超级组以创建新的组合。';
  }

  @override
  String workoutDetailScreenUi1Created(Object setType) {
    return '$setType 已创建！';
  }

  @override
  String workoutDetailScreenUi2BlockFromAllFuture(Object name) {
    return '是否在未来的 AI 推荐中屏蔽“$name”？\n\n';
  }

  @override
  String workoutDetailScreenUi2FailedToRemoveExercise(Object e) {
    return '移除动作失败: $e';
  }

  @override
  String workoutDetailScreenUi2RemoveFromThisWorkout(Object name) {
    return '确定从本次训练中移除“$name”吗？';
  }

  @override
  String workoutDetailScreenUi2RemovedFromWorkout(Object name) {
    return '已从训练中移除 $name';
  }

  @override
  String workoutDetailScreenUi2WillNoLongerBe(Object name) {
    return '将不再推荐 $name';
  }

  @override
  String workoutDetailScreenUiSRest(Object restSeconds) {
    return '休息 $restSeconds 秒';
  }

  @override
  String workoutDetailScreenUiValue(Object label) {
    return '$label：';
  }

  @override
  String get workoutDetailScreenWouldYouLikeTo => '你想将此设备配置保存到个人资料以供未来训练使用吗？';

  @override
  String get workoutDetailScreenYesSave => '是的，保存';

  @override
  String get workoutDetailTryAgain => '重试';

  @override
  String get workoutDetailType => '类型';

  @override
  String get workoutDetailUpdatingExercises => '正在更新动作';

  @override
  String get workoutDetailWantAChallenge => '想要挑战吗？';

  @override
  String get workoutDetailWarmUp => '热身';

  @override
  String get workoutFavourites => '收藏';

  @override
  String get workoutFlowMixinComplete => '完成';

  @override
  String get workoutFlowMixinCompleteWorkoutNow => '现在完成训练？';

  @override
  String get workoutFlowMixinKeepGoing => '继续进行';

  @override
  String get workoutGalleryCompleteAWorkoutAnd => '完成一次训练并分享它\n以开启你的图库';

  @override
  String get workoutGalleryDeleteImage => '删除图片？';

  @override
  String get workoutGalleryNoImagesYet => '暂无图片';

  @override
  String get workoutGalleryShareAgain => '再次分享';

  @override
  String get workoutGalleryThisWillRemoveThe => '这将从你的图库中移除该图片。';

  @override
  String get workoutGalleryWorkoutGallery => '训练图库';

  @override
  String get workoutGalleryWorkoutRecap => '训练回顾';

  @override
  String get workoutGenerate => '生成训练';

  @override
  String get workoutGenerationAnalyzingYourFitnessProfile => '正在分析你的健身资料';

  @override
  String get workoutGenerationDesigningYourTrainingSplit => '正在设计你的训练计划';

  @override
  String get workoutGenerationFinalizingYourPlan => '正在最终确定你的计划';

  @override
  String get workoutGenerationGeneratingYourPersonalizedP => '正在生成你的个性化计划';

  @override
  String get workoutGenerationGeneratingYourPlan => '正在生成你的计划';

  @override
  String get workoutGenerationGenerationFailed => '生成失败';

  @override
  String get workoutGenerationOptimizingWorkoutStructure => '正在优化训练结构';

  @override
  String get workoutGenerationSelectingExercisesForYour => '正在为你的目标选择练习';

  @override
  String get workoutGenerationSomethingWentWrong => '出错了';

  @override
  String get workoutGenerationTryAgain => '重试';

  @override
  String get workoutGenerationWorkoutReady => '训练已就绪！';

  @override
  String get workoutHistory => '历史';

  @override
  String get workoutHistoryImportAddExercise => '添加练习';

  @override
  String get workoutHistoryImportAddToHistory => '添加到历史记录';

  @override
  String get workoutHistoryImportAddYourPastWorkout =>
      '添加你过去的训练数据，以便 AI 能生成与你力量水平相匹配的训练重量。';

  @override
  String get workoutHistoryImportAddYourPastWorkout2 =>
      '在上方添加你过去的训练数据，以帮助 AI 为你生成更好的训练计划。';

  @override
  String get workoutHistoryImportAppleHealth => 'Apple Health';

  @override
  String get workoutHistoryImportAutoDetect => '自动检测';

  @override
  String get workoutHistoryImportBeforeWeParse => '在我们解析之前…';

  @override
  String get workoutHistoryImportChooseFile => '选择文件';

  @override
  String get workoutHistoryImportCouldNotReadThat => '无法读取该文件。';

  @override
  String get workoutHistoryImportDeleteEntry => '删除条目？';

  @override
  String get workoutHistoryImportEG10 => '例如：10';

  @override
  String get workoutHistoryImportEG3 => '例如：3';

  @override
  String get workoutHistoryImportEG60 => '例如：60';

  @override
  String get workoutHistoryImportEGBenchPress => '例如：卧推、深蹲';

  @override
  String get workoutHistoryImportEntryDeleted => '条目已删除';

  @override
  String workoutHistoryImportError(Object error) {
    return '错误：$error';
  }

  @override
  String get workoutHistoryImportExerciseName => '练习名称';

  @override
  String get workoutHistoryImportExportFromHevy =>
      '从 Hevy, Strong, Fitbod, Jeff Nippard, Renaissance Periodization, Wendler 5/3/1, Apple Health, Garmin, Strava, Peloton 等平台导出。';

  @override
  String get workoutHistoryImportFitbod => 'Fitbod';

  @override
  String get workoutHistoryImportFitnotes => 'FitNotes';

  @override
  String get workoutHistoryImportGarmin => 'Garmin';

  @override
  String get workoutHistoryImportHevy => 'Hevy';

  @override
  String workoutHistoryImportImportFailed(Object error) {
    return '导入失败：$error';
  }

  @override
  String get workoutHistoryImportImportFromFile => '从文件导入';

  @override
  String get workoutHistoryImportImportWorkoutHistory => '导入训练历史';

  @override
  String get workoutHistoryImportInvalid => '无效';

  @override
  String get workoutHistoryImportJeffNippard => 'Jeff Nippard';

  @override
  String get workoutHistoryImportJefit => 'Jefit';

  @override
  String get workoutHistoryImportKilogramsKg => '千克 (kg)';

  @override
  String workoutHistoryImportMaxWeightKg(Object weight) {
    return '最大重量：$weight kg';
  }

  @override
  String workoutHistoryImportNSessions(Object count, Object sourceDescription) {
    return '$sourceDescription  •  $count 次训练';
  }

  @override
  String get workoutHistoryImportNoWorkoutHistoryYet => '暂无训练历史';

  @override
  String get workoutHistoryImportNsuns => 'nSuns';

  @override
  String get workoutHistoryImportOtherGenericSpreadsheet => '其他 / 通用电子表格';

  @override
  String get workoutHistoryImportPeloton => 'Peloton';

  @override
  String get workoutHistoryImportPleaseEnterExerciseName => '请输入练习名称';

  @override
  String get workoutHistoryImportPoundsLb => '磅 (lb)';

  @override
  String get workoutHistoryImportPreviewImport => '预览导入';

  @override
  String get workoutHistoryImportRecentImports => '最近导入';

  @override
  String workoutHistoryImportRemoveExercise(Object exerciseName) {
    return '从你的训练历史中移除 $exerciseName？';
  }

  @override
  String get workoutHistoryImportRenaissancePeriodization =>
      'Renaissance Periodization';

  @override
  String get workoutHistoryImportReps => '次数';

  @override
  String get workoutHistoryImportRequired => '必填';

  @override
  String workoutHistoryImportScreenKg(Object lastWeightKg) {
    return '$lastWeightKg kg';
  }

  @override
  String workoutHistoryImportScreenSetsRepsKg(
    Object reps,
    Object sets,
    Object weightKg,
  ) {
    return '$sets 组 × $reps 次 @ $weightKg kg';
  }

  @override
  String get workoutHistoryImportSets => '组数';

  @override
  String get workoutHistoryImportSourceApp => '来源应用';

  @override
  String get workoutHistoryImportStartingStrength => 'Starting Strength';

  @override
  String get workoutHistoryImportStrava => 'Strava';

  @override
  String get workoutHistoryImportStrong => 'Strong';

  @override
  String get workoutHistoryImportStronglifts => 'StrongLifts';

  @override
  String get workoutHistoryImportSupportsCsvXlsxXlsm =>
      '支持 CSV, XLSX, XLSM, JSON, Parquet, PDF, FIT, XML, ZIP。';

  @override
  String get workoutHistoryImportTheAiUsesThis => 'AI 将使用此数据来设置合适的重量';

  @override
  String get workoutHistoryImportViewAll => '查看全部';

  @override
  String get workoutHistoryImportWeightKg => '重量 (kg)';

  @override
  String get workoutHistoryImportWeightUnit => '重量单位';

  @override
  String get workoutHistoryImportWendler531 => 'Wendler 5/3/1';

  @override
  String get workoutHistoryImportWhichUnitIsThe =>
      '重量列使用的是什么单位？如果你知道来源应用，请选择它——这有助于区分相似的格式（例如 Hevy 与 Strong 的 CSV）。';

  @override
  String get workoutHistoryImportYourStrengthData => '你的力量训练数据';

  @override
  String get workoutImportAsDone => ')\" 标记为完成';

  @override
  String get workoutImportCalories => '卡路里';

  @override
  String get workoutImportCardio => '有氧运动';

  @override
  String get workoutImportCycling => '骑行';

  @override
  String get workoutImportDistance => '距离';

  @override
  String get workoutImportDuration => '时长';

  @override
  String get workoutImportEasy => '轻松';

  @override
  String get workoutImportFlexibility => '柔韧性';

  @override
  String workoutImportFromSource(Object arg0) {
    return '来自来源 $arg0';
  }

  @override
  String get workoutImportHard => '高强度';

  @override
  String get workoutImportHiit => 'HIIT';

  @override
  String get workoutImportHowHardWasThis => '这次训练难度如何？';

  @override
  String get workoutImportImportAsSeparateWorkout => '作为独立训练导入';

  @override
  String get workoutImportImportWorkout => '导入训练';

  @override
  String get workoutImportMedium => '中等';

  @override
  String get workoutImportOther => '其他';

  @override
  String get workoutImportPreviewCardioRows => '有氧运动行';

  @override
  String get workoutImportPreviewHeadsUp => '注意';

  @override
  String get workoutImportPreviewLooksRightImport => '看起来没问题 — 导入';

  @override
  String get workoutImportPreviewNo => '否';

  @override
  String get workoutImportPreviewNoSampleRowsProduced => '未生成样本行（文件可能为空或无法识别）。';

  @override
  String get workoutImportPreviewPreviewImport => '预览导入';

  @override
  String get workoutImportPreviewSampleRows => '样本行';

  @override
  String workoutImportPreviewSheetMore(Object more) {
    return '+$more 更多';
  }

  @override
  String workoutImportPreviewSheetValue(Object percent) {
    return '$percent%';
  }

  @override
  String workoutImportPreviewSheetValue2(Object w) {
    return '•  $w';
  }

  @override
  String get workoutImportPreviewStrengthRows => '力量训练行';

  @override
  String get workoutImportPreviewTemplate => '模板';

  @override
  String get workoutImportPreviewTheseWillStillImport =>
      '这些仍会被导入 — 你可以在任务完成后将它们映射到标准名称。';

  @override
  String get workoutImportPreviewUnmatchedExercises => '未匹配的动作';

  @override
  String get workoutImportProgressImportIsStillIn => '导入仍在进行中 — 请稍候。';

  @override
  String get workoutImportProgressImportingWorkoutHistory => '正在导入训练历史';

  @override
  String workoutImportProgressSheetJobId(Object jobId) {
    return '任务 ID：$jobId';
  }

  @override
  String get workoutImportProgressThisUsuallyFinishesIn => '这通常在 10–30 秒内完成。';

  @override
  String get workoutImportRunning => '跑步';

  @override
  String workoutImportScreenAvgBpm(Object avgHeartRate) {
    return '平均 $avgHeartRate bpm';
  }

  @override
  String workoutImportScreenM(Object workout) {
    return '$workout 分钟';
  }

  @override
  String workoutImportScreenMaxBpm(Object maxHeartRate) {
    return '  |  最大 $maxHeartRate bpm';
  }

  @override
  String get workoutImportSkip => '跳过';

  @override
  String get workoutImportStrengthTraining => '力量训练';

  @override
  String get workoutImportSummaryActivateProgram => '激活计划';

  @override
  String get workoutImportSummaryCardioSessionsAdded => '已添加有氧训练';

  @override
  String get workoutImportSummaryCreatorProgramDetected => '检测到创建者计划';

  @override
  String get workoutImportSummaryDuplicatesSkipped => '已跳过重复项';

  @override
  String get workoutImportSummaryFixThese => '修复这些问题';

  @override
  String get workoutImportSummaryImportComplete => '导入完成';

  @override
  String get workoutImportSummaryImportFailed => '导入失败';

  @override
  String get workoutImportSummaryProgramTemplate => '计划模板';

  @override
  String workoutImportSummarySheetMore(Object more) {
    return '还有 $more 个';
  }

  @override
  String workoutImportSummarySheetValue(Object w) {
    return '•  $w';
  }

  @override
  String get workoutImportSummaryStrengthSetsAdded => '已添加力量训练组';

  @override
  String get workoutImportSummaryTheseRowsWereImported =>
      '这些行已导入，但尚未匹配到库中的动作。映射它们可以改善重量建议和图表分析。';

  @override
  String get workoutImportSummaryUnknownErrorPleaseTry => '未知错误 — 请重试或联系支持团队。';

  @override
  String get workoutImportSummaryWarnings => '警告';

  @override
  String get workoutImportSummaryWeCouldnTFinish => '我们无法完成你的导入。';

  @override
  String get workoutImportSummaryWeParsedAMulti =>
      '我们解析了一个多周计划模板。激活它将从下周一开始安排训练。';

  @override
  String get workoutImportSummaryWeightSuggestionsAcrossThe =>
      '应用内的重量建议将在 1 分钟内开始反映此历史数据。';

  @override
  String get workoutImportSwimming => '游泳';

  @override
  String get workoutImportWalking => '步行';

  @override
  String get workoutImportWeights => '负重';

  @override
  String get workoutImportWhatTypeOfExercise => '什么类型的动作？';

  @override
  String get workoutImportWorkout => '训练';

  @override
  String get workoutImportWorkoutDetected => '检测到训练';

  @override
  String get workoutImportYoga => '瑜伽';

  @override
  String get workoutListTitle => '训练';

  @override
  String get workoutLoadingBuildingYourPlan => '正在构建你的计划';

  @override
  String workoutLoadingScreenValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String get workoutLoadingWorkoutReady => '训练已就绪！';

  @override
  String get workoutLoadingWorkoutReady2 => '训练已就绪！';

  @override
  String workoutMetricChartNotEnoughDataTo(Object label) {
    return '没有足够的$label数据来生成图表。';
  }

  @override
  String get workoutMiniPlayerEndWorkout => '结束训练？';

  @override
  String get workoutMiniPlayerEndWorkout2 => '结束训练';

  @override
  String workoutMiniPlayerS(Object restSecondsRemaining) {
    return '$restSecondsRemaining 秒';
  }

  @override
  String get workoutMiniPlayerYourWorkoutProgressWill => '你的训练进度将不会被保存。';

  @override
  String get workoutOptionsDismissQuickWorkout => '放弃快速训练？';

  @override
  String get workoutOptionsMarkAsDone => '标记为完成？';

  @override
  String workoutOptionsSheetExercises(Object exerciseCount) {
    return '$exerciseCount 个动作';
  }

  @override
  String workoutOptionsSheetMarkWorkoutForAs(Object dateLabel) {
    return '将 $dateLabel 的锻炼标记为已完成？这将把它标记为 ';
  }

  @override
  String workoutOptionsSheetMoreExercises(Object exercises) {
    return '+$exercises 个更多动作';
  }

  @override
  String workoutOptionsSheetSets(Object e) {
    return '$e 组';
  }

  @override
  String workoutOptionsSheetValue(Object formattedDurationShort) {
    return '$formattedDurationShort • ';
  }

  @override
  String get workoutOptionsSkipWorkout => '跳过训练？';

  @override
  String get workoutOptionsThisWillMarkThe => '这将把训练标记为已完成，而不记录组数。';

  @override
  String get workoutOptionsThisWorkoutWillBe => '此训练将被标记为已跳过。';

  @override
  String get workoutPermissionsPrimeGotItLetU2019s => '明白了，开始吧';

  @override
  String get workoutPermissionsPrimeLetsUsAutoConnect =>
      '允许我们在附近有 BLE 心率带时自动连接。';

  @override
  String get workoutPermissionsPrimeMicrophone => '麦克风';

  @override
  String get workoutPermissionsPrimeNearbyDevices => '附近设备';

  @override
  String get workoutPermissionsPrimeTapTheMicMid => '在组间点击麦克风，通过语音提问或记录笔记。';

  @override
  String get workoutPermissionsPrimeTwoQuickHeadsUps => '两个快速提示';

  @override
  String get workoutPermissionsPrimeYouMaySeeThese =>
      '你在训练期间可能会看到这些系统提示。两者都是可选的 — 跳过任何一个，训练仍可正常进行。';

  @override
  String get workoutPlanDrawerAddExercise => '添加动作';

  @override
  String get workoutPlanDrawerCurrent => '当前';

  @override
  String workoutPlanDrawerExerciseCount(Object arg0) {
    return '动作数量 $arg0';
  }

  @override
  String get workoutPlanDrawerLoggedTheyWillBe => ') 已记录。它们将被删除。';

  @override
  String get workoutPlanDrawerNow => '现在';

  @override
  String get workoutPlanDrawerRemove => '移除';

  @override
  String workoutPlanDrawerRemoveExercise(Object arg0) {
    return '移除动作 $arg0';
  }

  @override
  String get workoutPlanDrawerRemoveExerciseTooltip => '移除动作提示';

  @override
  String workoutPlanDrawerSetsLogged(Object arg0) {
    return '已记录组数 $arg0';
  }

  @override
  String get workoutPlanDrawerSwapExercise => '替换动作';

  @override
  String get workoutPlanDrawerTitle => '标题';

  @override
  String get workoutPlanDrawerWorkoutPlan => '训练计划';

  @override
  String get workoutPlannerCalendarDisplayOptions => '日历显示选项';

  @override
  String get workoutPlannerMon => '周一';

  @override
  String get workoutPlannerShowSyncedWorkouts => '显示已同步的训练';

  @override
  String get workoutPlannerStartWeekOnMonday => '周一作为每周的第一天';

  @override
  String get workoutPlannerSun => '周日';

  @override
  String get workoutPreferencesCardEditProgram => '编辑计划';

  @override
  String get workoutPreferencesCardEnvironment => '训练环境';

  @override
  String get workoutPreferencesCardExperience => '训练经验';

  @override
  String get workoutPreferencesCardFocusAreas => '重点部位';

  @override
  String get workoutPreferencesCardFullBody => '全身训练';

  @override
  String get workoutPreferencesCardMotivation => '训练目标';

  @override
  String get workoutPreferencesCardNotSet => '未设置';

  @override
  String get workoutPreferencesCardWeekStartsOn => '每周起始日';

  @override
  String get workoutPreferencesCardWorkoutDays => '训练日';

  @override
  String get workoutReviewAddExercise => '添加动作';

  @override
  String get workoutReviewAdding => '添加中...';

  @override
  String get workoutReviewApprovePlan => '确认计划';

  @override
  String get workoutReviewClosing => '关闭中...';

  @override
  String get workoutReviewNoExercisesYet => '暂无动作';

  @override
  String get workoutReviewReviewYourWorkout => '检查你的训练';

  @override
  String get workoutReviewSaving => '保存中...';

  @override
  String workoutReviewSheetExercises(Object exerciseCount) {
    return '$exerciseCount 个动作';
  }

  @override
  String get workoutReviewSwapExercise => '替换动作';

  @override
  String get workoutReviewTryAgain => '重试';

  @override
  String get workoutReviewYourWorkout => '你的训练';

  @override
  String get workoutSettingsAddPastWorkoutsFor => '添加过往训练以优化AI重量建议';

  @override
  String get workoutSettingsAutoDeloadDeloadFrequency => '自动减载、减载频率及进度周期';

  @override
  String get workoutSettingsCustomizeWhichExercisesAppe => '自定义训练中出现的动作';

  @override
  String get workoutSettingsExercisePreferences => '动作偏好';

  @override
  String get workoutSettingsFatigueDetection => '疲劳检测';

  @override
  String get workoutSettingsFavoritesAvoidedAndQueue => '收藏、屏蔽及队列';

  @override
  String get workoutSettingsHowFastToIncrease => '重量增加速度';

  @override
  String get workoutSettingsHowHeavyAndHow => '重量负荷与进度速度';

  @override
  String get workoutSettingsHowMuchExercisesChange => '每周动作变化幅度';

  @override
  String get workoutSettingsHowWeightsAreDisplayed => '重量显示与记录方式';

  @override
  String get workoutSettingsImportWorkoutHistory => '导入训练历史';

  @override
  String get workoutSettingsIncompleteExerciseWarning => '未完成动作提醒';

  @override
  String get workoutSettingsLiveCoaching => '实时指导';

  @override
  String get workoutSettingsMy1rms => '我的1RM';

  @override
  String get workoutSettingsMyExercises => '我的动作';

  @override
  String workoutSettingsPageStepSizeTapTo(Object ref) {
    return '步长：$ref · 点击以自定义';
  }

  @override
  String get workoutSettingsPreSetInsights => '预设洞察';

  @override
  String get workoutSettingsProgram => '训练计划';

  @override
  String get workoutSettingsProgressCharts => '进度图表';

  @override
  String get workoutSettingsProgressionDeload => '进度与减载';

  @override
  String get workoutSettingsProgressionLoad => '进度与负荷';

  @override
  String get workoutSettingsProgressionPace => '进度节奏';

  @override
  String get workoutSettingsPushPullLegsFull => '推/拉/腿、全身训练等';

  @override
  String get workoutSettingsStrengthCardioOrMixed => '力量、有氧或混合训练';

  @override
  String get workoutSettingsTrainingIntensity => '训练强度';

  @override
  String get workoutSettingsTrainingSplit => '训练拆分';

  @override
  String get workoutSettingsUnitForLoggingExercise => '训练重量记录单位';

  @override
  String get workoutSettingsUnitsTracking => '单位与追踪';

  @override
  String get workoutSettingsViewAndEditYour => '查看并编辑你的最大重量';

  @override
  String get workoutSettingsVisualizeStrengthVolumeOv => '可视化力量与训练量趋势';

  @override
  String get workoutSettingsWeeklyVariety => '每周多样性';

  @override
  String get workoutSettingsWeightIncrements => '重量增量';

  @override
  String get workoutSettingsWhatHappensDuringA => '训练过程设置';

  @override
  String get workoutSettingsWhatYouTrainAnd => '训练内容与时间';

  @override
  String get workoutSettingsWhichDaysYouTrain => '训练日期';

  @override
  String get workoutSettingsWorkAtAPercentage => '基于最大重量的百分比训练';

  @override
  String get workoutSettingsWorkoutDays => '训练日';

  @override
  String get workoutSettingsWorkoutSettings => '训练设置';

  @override
  String get workoutSettingsWorkoutType => '训练类型';

  @override
  String get workoutSettingsWorkoutWeightUnit => '训练重量单位';

  @override
  String get workoutSheetsMixinAiCoachHiddenFor => '本次训练已隐藏AI教练';

  @override
  String get workoutSheetsMixinAiTargetsWillBe => 'AI目标将根据你的历史记录生成。';

  @override
  String get workoutSheetsMixinBarType => '杠铃类型';

  @override
  String get workoutSheetsMixinBreakSuperset => '取消超级组';

  @override
  String get workoutSheetsMixinChangeRepsProgression => '更改次数进度';

  @override
  String get workoutSheetsMixinCreateSuperset => '创建超级组';

  @override
  String get workoutSheetsMixinEnterReps => '输入次数';

  @override
  String get workoutSheetsMixinHide => '隐藏';

  @override
  String get workoutSheetsMixinHideAiCoach => '隐藏AI教练？';

  @override
  String get workoutSheetsMixinHowToCreateA => '如何创建超级组：';

  @override
  String get workoutSheetsMixinLastSession => '上次训练';

  @override
  String workoutSheetsMixinLoggedLocallySyncFailed(Object label) {
    return '已本地记录 $label（同步失败）';
  }

  @override
  String workoutSheetsMixinMlLogged(Object amountMl, Object label) {
    return '已记录 ${amountMl}ml $label';
  }

  @override
  String workoutSheetsMixinMlLogged2(Object amountMl, Object label) {
    return '已记录 ${amountMl}ml $label';
  }

  @override
  String get workoutSheetsMixinNoPreviousDataFor => '该动作暂无历史数据。';

  @override
  String get workoutSheetsMixinOrDragExercisesTogether => '或将动作拖拽到一起以添加更多';

  @override
  String get workoutSheetsMixinSelectTheTypeOf => '选择你使用的杠铃类型';

  @override
  String get workoutSheetsMixinSetTargets => '设置目标';

  @override
  String get workoutSheetsMixinSupersetRemoved => '超级组已移除';

  @override
  String get workoutSheetsMixinSupersetsHelpYouSave =>
      '超级组通过交替进行动作并缩短休息时间，助你节省训练时间。';

  @override
  String get workoutSheetsMixinTheAiCoachWill => 'AI教练将在本次训练中隐藏。你仍可在设置中重新开启。';

  @override
  String workoutSheetsMixinUiChangedTo(Object displayName) {
    return '已更改为 $displayName';
  }

  @override
  String workoutSheetsMixinUiSupersetExercises(Object length) {
    return '超级组 ($length 个动作)';
  }

  @override
  String get workoutSheetsMixinUndo => '撤销';

  @override
  String get workoutSheetsMixinWarmUp => '热身';

  @override
  String get workoutSheetsMixinWarmingUpHelpsPrevent =>
      '热身有助于预防受伤并提升表现。\n\n建议：在正式组前进行 1-2 组轻重量热身。';

  @override
  String get workoutShowcase12450Lbs => '12,450 lbs';

  @override
  String get workoutShowcase15ViralFormatsTap => '15 种热门格式 — 点击任意预览';

  @override
  String get workoutShowcase1rmEstimate => '1RM 估算';

  @override
  String get workoutShowcase252Lb => '252 lb';

  @override
  String get workoutShowcase3Prs14Day => '3 项 PR · 14 天连续记录';

  @override
  String get workoutShowcase44Min => '44 分钟';

  @override
  String get workoutShowcaseAdjust => '调整';

  @override
  String get workoutShowcaseAdvanced => '进阶';

  @override
  String get workoutShowcaseAll3SetsDone => '已完成全部 3 组';

  @override
  String get workoutShowcaseAllSetsLogged => '✓ 所有组已记录';

  @override
  String get workoutShowcaseAllSetsLoggedProgression => '所有组已记录 — 进度更新中';

  @override
  String get workoutShowcaseAskCoach => '咨询教练';

  @override
  String get workoutShowcaseAutoDesc => '自动描述';

  @override
  String get workoutShowcaseAutoLabel => '自动标签';

  @override
  String get workoutShowcaseBarbellSquat => '杠铃深蹲';

  @override
  String get workoutShowcaseBenchPress => '卧推';

  @override
  String get workoutShowcaseBoardingPass => '登机牌';

  @override
  String get workoutShowcaseBreathing => '呼吸';

  @override
  String get workoutShowcaseCal => '卡路里';

  @override
  String get workoutShowcaseCalories => '卡路里';

  @override
  String get workoutShowcaseContinue => '继续';

  @override
  String get workoutShowcaseDuration => '时长';

  @override
  String get workoutShowcaseEasy => '简单';

  @override
  String get workoutShowcaseEpley2255Reps => 'Epley · 225 × 5 次';

  @override
  String get workoutShowcaseEverySetYouLog => '你记录的每一组';

  @override
  String get workoutShowcaseEveryWorkoutFlows => '每一次训练流程';

  @override
  String get workoutShowcaseFinishWorkout => '完成训练';

  @override
  String get workoutShowcaseFormat1Rm => '1RM 格式';

  @override
  String get workoutShowcaseFormatBoarding => '登机牌';

  @override
  String get workoutShowcaseFormatCard => '卡片';

  @override
  String get workoutShowcaseFormatDiscord => 'Discord';

  @override
  String get workoutShowcaseFormatFull => '完整';

  @override
  String get workoutShowcaseFormatIgStory => 'Ig story';

  @override
  String get workoutShowcaseFormatNewspaper => '报纸';

  @override
  String get workoutShowcaseFormatPassport => '护照';

  @override
  String get workoutShowcaseFormatPolaroid => '拍立得';

  @override
  String get workoutShowcaseFormatPrCard => 'PR卡';

  @override
  String get workoutShowcaseFormatQuote => '引用';

  @override
  String get workoutShowcaseFormatReceipt => '收据';

  @override
  String get workoutShowcaseFormatTrading => '交易卡';

  @override
  String get workoutShowcaseFormatTrophy => '奖杯';

  @override
  String get workoutShowcaseFormatVinyl => '黑胶唱片';

  @override
  String get workoutShowcaseFormatWrapped => '年度总结';

  @override
  String get workoutShowcaseHowYourWeightReps => '查看你的重量与次数在各组间的进展。';

  @override
  String get workoutShowcaseInfo => '信息';

  @override
  String get workoutShowcaseInstructions => '说明';

  @override
  String get workoutShowcaseLR => '左/右';

  @override
  String get workoutShowcaseLinearDesc => '线性描述';

  @override
  String get workoutShowcaseLinearLabel => '线性标签';

  @override
  String get workoutShowcaseLogAllSets => '所有组';

  @override
  String get workoutShowcaseLogDrink => '记录饮品';

  @override
  String workoutShowcaseLogSet(Object arg0) {
    return '第 $arg0 组';
  }

  @override
  String get workoutShowcaseLogWater => '记录饮水';

  @override
  String get workoutShowcaseMovedThisSession => '本次训练总量';

  @override
  String get workoutShowcaseNewPr => '新 PR';

  @override
  String get workoutShowcaseNote => '备注';

  @override
  String get workoutShowcasePlan => '计划';

  @override
  String get workoutShowcasePlanAutoAdjustsNext =>
      '计划将自动调整下一次训练 — 根据你的实际表现重新校准重量与次数。';

  @override
  String get workoutShowcasePoweredByZealova => '由 Zealova 提供支持';

  @override
  String get workoutShowcaseProgressionModel => '进阶模型';

  @override
  String get workoutShowcasePyramidDesc => '金字塔描述';

  @override
  String get workoutShowcasePyramidLabel => '金字塔标签';

  @override
  String get workoutShowcaseRare => '★ 稀有';

  @override
  String get workoutShowcaseReps => '次数';

  @override
  String workoutShowcaseScreenDay(Object day) {
    return '第 $day 天';
  }

  @override
  String workoutShowcaseScreenDuration(Object duration) {
    return '时长：$duration';
  }

  @override
  String workoutShowcaseScreenPrs(Object prs) {
    return 'PR：$prs';
  }

  @override
  String workoutShowcaseScreenPrsEntered(Object prs) {
    return '$prs PR · 已录入';
  }

  @override
  String workoutShowcaseScreenSession(Object title) {
    return '训练：$title';
  }

  @override
  String workoutShowcaseScreenTotalPrs(
    Object duration,
    Object prs,
    Object volume,
  ) {
    return '总计 $duration · $volume · $prs PR';
  }

  @override
  String workoutShowcaseScreenValue(Object duration, Object volume) {
    return '$duration · $volume';
  }

  @override
  String workoutShowcaseScreenVolZealovaPress(Object day) {
    return '容量 $day · ZEALOVA PRESS';
  }

  @override
  String workoutShowcaseScreenVolume(Object volume) {
    return '容量：$volume';
  }

  @override
  String workoutShowcaseScreenYouDay(Object day) {
    return '@you · 第 $day 天';
  }

  @override
  String get workoutShowcaseSet1 => '第 1 组';

  @override
  String get workoutShowcaseSet1Of4 => '第 1 组（共 4 组）';

  @override
  String get workoutShowcaseSet2 => '第 2 组';

  @override
  String get workoutShowcaseSet3 => '第 3 组';

  @override
  String workoutShowcaseSetNOf3(Object arg0) {
    return '训练展示：第 $arg0 组（共 3 组）';
  }

  @override
  String get workoutShowcaseShareYourWorkout => '分享你的训练';

  @override
  String get workoutShowcaseSideA => 'A 面';

  @override
  String get workoutShowcaseSuperset => '超级组';

  @override
  String workoutShowcaseTapToLogSet(Object arg0) {
    return '点击记录第 $arg0 组';
  }

  @override
  String get workoutShowcaseTheGainsGazette => '增肌日报';

  @override
  String get workoutShowcaseTime => '时间';

  @override
  String get workoutShowcaseUndulatingDesc => '波动描述';

  @override
  String get workoutShowcaseUndulatingLabel => '波动标签';

  @override
  String get workoutShowcaseUpNextBenchPress => '接下来：卧推';

  @override
  String get workoutShowcaseUpperBodyPush => '上肢推';

  @override
  String get workoutShowcaseVideo => '视频';

  @override
  String get workoutShowcaseVolume => '容量';

  @override
  String get workoutShowcaseWarmup => '热身';

  @override
  String get workoutShowcaseWeight => '重量';

  @override
  String get workoutShowcaseWorkoutComplete => '训练完成';

  @override
  String get workoutShowcaseWorkoutLogged => '训练已记录';

  @override
  String get workoutShowcaseYou => '@你';

  @override
  String get workoutShowcaseZealova => 'ZEALOVA';

  @override
  String get workoutStateCardsAiPoweredPersonalizedProgra => 'AI 驱动的个性化计划';

  @override
  String get workoutStateCardsCreatingYourWorkouts => '正在创建你的训练';

  @override
  String get workoutStateCardsGeneratingYourWorkouts => '正在生成你的训练...';

  @override
  String get workoutStateCardsGetStarted => '开始';

  @override
  String get workoutStateCardsGetYourPersonalizedWorkout => '获取你的个性化训练计划';

  @override
  String get workoutStateCardsReadyToStart => '准备好开始了吗？';

  @override
  String get workoutStateCardsTryAgain => '重试';

  @override
  String get workoutStateCardsYourPersonalizedWorkoutPlan => '正在创建你的个性化训练计划';

  @override
  String get workoutStatsStripCalories => '卡路里';

  @override
  String get workoutStatsStripDuration => '时长';

  @override
  String workoutStatsStripKcal(Object calories) {
    return '$calories kcal';
  }

  @override
  String get workoutStatsStripVolume => '容量';

  @override
  String get workoutSummaryAddASetOr => '添加一组或编辑动作以填充此摘要。';

  @override
  String get workoutSummaryAddExercise => '添加动作';

  @override
  String get workoutSummaryAdvancedAiInteractions => 'AI 交互';

  @override
  String get workoutSummaryAdvancedAvgEffort => '平均强度';

  @override
  String get workoutSummaryAdvancedAvgExercises => '平均（动作）';

  @override
  String get workoutSummaryAdvancedAvgRir => '平均 RIR';

  @override
  String get workoutSummaryAdvancedAvgRpe => '平均 RPE';

  @override
  String get workoutSummaryAdvancedAvgSets => '平均（组数）';

  @override
  String get workoutSummaryAdvancedBasedOnEpleyFormula => '基于你最佳组数的 Epley 公式';

  @override
  String get workoutSummaryAdvancedCardioSession => '有氧训练';

  @override
  String get workoutSummaryAdvancedConfidence => '置信度';

  @override
  String get workoutSummaryAdvancedDetailedTrackingDataIs => '此训练暂无详细追踪数据。';

  @override
  String get workoutSummaryAdvancedDuration => '时长';

  @override
  String get workoutSummaryAdvancedEffort => '强度';

  @override
  String get workoutSummaryAdvancedEnergy => '能量';

  @override
  String get workoutSummaryAdvancedEstimated1rm => '估算 1RM';

  @override
  String get workoutSummaryAdvancedExerciseOrderTime => '动作顺序与时间';

  @override
  String workoutSummaryAdvancedExercises(
    Object completedCount,
    Object totalPlanned,
  ) {
    return '$completedCount / $totalPlanned 个动作';
  }

  @override
  String get workoutSummaryAdvancedExercisesDone => '已完成动作';

  @override
  String get workoutSummaryAdvancedFeelingStronger => '感觉更强壮';

  @override
  String get workoutSummaryAdvancedHideDetails => '隐藏详情';

  @override
  String get workoutSummaryAdvancedHowYouFelt => '你的感受';

  @override
  String get workoutSummaryAdvancedHydration => '水分补充';

  @override
  String get workoutSummaryAdvancedHydration2 => '水分补充';

  @override
  String get workoutSummaryAdvancedIntensity => '强度';

  @override
  String get workoutSummaryAdvancedIntensityAnalysis => '强度分析';

  @override
  String workoutSummaryAdvancedLb(Object totalVol) {
    return '$totalVol 磅';
  }

  @override
  String workoutSummaryAdvancedLb2(Object value) {
    return '$value 磅';
  }

  @override
  String workoutSummaryAdvancedLong(Object tooLong) {
    return '时长 $tooLong';
  }

  @override
  String workoutSummaryAdvancedMS(Object m, Object s) {
    return '$m分 $s秒';
  }

  @override
  String get workoutSummaryAdvancedMood => '心情';

  @override
  String get workoutSummaryAdvancedMoreDetails => '更多详情';

  @override
  String get workoutSummaryAdvancedMuscleMapNotApplicable => '肌肉分布图不适用';

  @override
  String get workoutSummaryAdvancedMusclesHit => '锻炼肌肉';

  @override
  String workoutSummaryAdvancedNewThisSession(Object length) {
    return '本次训练新增 $length 项';
  }

  @override
  String get workoutSummaryAdvancedNo => '否';

  @override
  String get workoutSummaryAdvancedNoCompletedSetsLogged => '本次训练未记录已完成的组数。';

  @override
  String get workoutSummaryAdvancedNoVolumeDataYet => '暂无训练量数据';

  @override
  String get workoutSummaryAdvancedOutOf100 => '满分 100';

  @override
  String get workoutSummaryAdvancedPeakRpe => '峰值 RPE';

  @override
  String get workoutSummaryAdvancedPerExercise => '按动作';

  @override
  String get workoutSummaryAdvancedPerExerciseDeepDive => '动作深度分析';

  @override
  String get workoutSummaryAdvancedPerExerciseDeepDive2 => '动作深度分析';

  @override
  String get workoutSummaryAdvancedPerformanceComparison => '表现对比';

  @override
  String get workoutSummaryAdvancedPlan => '计划';

  @override
  String get workoutSummaryAdvancedPlanAdherence => '计划执行度';

  @override
  String get workoutSummaryAdvancedPrev => '上一项';

  @override
  String get workoutSummaryAdvancedPrsHit => '打破 PR';

  @override
  String get workoutSummaryAdvancedReps => '次数';

  @override
  String get workoutSummaryAdvancedRest => '休息';

  @override
  String get workoutSummaryAdvancedRestAnalysis => '休息分析';

  @override
  String get workoutSummaryAdvancedRestCompliance => '休息依从性';

  @override
  String workoutSummaryAdvancedRir(Object rir) {
    return 'RIR $rir';
  }

  @override
  String get workoutSummaryAdvancedRpeDistribution => 'RPE 分布';

  @override
  String workoutSummaryAdvancedS(Object duration) {
    return '$duration秒';
  }

  @override
  String get workoutSummaryAdvancedSessionScore => '训练得分';

  @override
  String get workoutSummaryAdvancedSessionTimeline => '训练时间轴';

  @override
  String get workoutSummaryAdvancedSet => '组';

  @override
  String get workoutSummaryAdvancedSetTypeDistribution => '组类型分布';

  @override
  String get workoutSummaryAdvancedSets => '组数';

  @override
  String get workoutSummaryAdvancedSettingsUsed => '使用的设置';

  @override
  String get workoutSummaryAdvancedStretching => '拉伸';

  @override
  String get workoutSummaryAdvancedSupersetDetails => '超级组详情';

  @override
  String get workoutSummaryAdvancedTarget => '目标';

  @override
  String get workoutSummaryAdvancedTimeSpent => '耗时';

  @override
  String get workoutSummaryAdvancedTiming => '时间安排';

  @override
  String get workoutSummaryAdvancedTop1rm => '最高 1RM';

  @override
  String get workoutSummaryAdvancedTotalRest => '总休息时间';

  @override
  String get workoutSummaryAdvancedTotalVolume => '总训练量：';

  @override
  String get workoutSummaryAdvancedUd83dUdca7 => '💧 ';

  @override
  String workoutSummaryAdvancedValue(Object confidence) {
    return '$confidence/5';
  }

  @override
  String workoutSummaryAdvancedValue2(Object progressPct) {
    return '$progressPct%';
  }

  @override
  String workoutSummaryAdvancedValue3(Object adherencePct) {
    return '$adherencePct%';
  }

  @override
  String get workoutSummaryAdvancedVolume => '训练量';

  @override
  String get workoutSummaryAdvancedVolume2 => '训练量';

  @override
  String get workoutSummaryAdvancedVolumeBreakdown => '训练量拆解';

  @override
  String get workoutSummaryAdvancedWarmup => '热身';

  @override
  String get workoutSummaryAdvancedWarmupStretching => '热身与拉伸';

  @override
  String get workoutSummaryAdvancedWeight => '重量';

  @override
  String get workoutSummaryAdvancedWeightSuggestions => '重量建议';

  @override
  String get workoutSummaryAdvancedWorkoutEndedEarly => '训练提前结束';

  @override
  String get workoutSummaryAdvancedYesU2705 => '是 ✅';

  @override
  String get workoutSummaryBodyweightSession => '自重训练';

  @override
  String get workoutSummaryCollapseAll => '全部折叠';

  @override
  String get workoutSummaryExpandAll => '全部展开';

  @override
  String get workoutSummaryFailedToLoadSummary => '加载摘要失败';

  @override
  String get workoutSummaryFailedToRevertWorkout => '撤销训练失败';

  @override
  String get workoutSummaryGeneralAiCoachReview => 'AI 教练评估';

  @override
  String get workoutSummaryGeneralCalories => '卡路里';

  @override
  String get workoutSummaryGeneralConnectAHeartRate => '连接心率监测器\n以追踪你的心率区间';

  @override
  String get workoutSummaryGeneralDifficulty => '难度';

  @override
  String get workoutSummaryGeneralDuration => '时长';

  @override
  String get workoutSummaryGeneralEnergy => '能量';

  @override
  String get workoutSummaryGeneralExercises => '动作';

  @override
  String get workoutSummaryGeneralHeartRate => '心率';

  @override
  String workoutSummaryGeneralLbXReps(Object reps, Object weightLbs) {
    return '$weightLbs 磅 x $reps 次';
  }

  @override
  String workoutSummaryGeneralLibraryId(Object libraryId) {
    return '库 ID：$libraryId';
  }

  @override
  String get workoutSummaryGeneralMusclesWorked => '锻炼肌肉';

  @override
  String get workoutSummaryGeneralPersonalRecords => '个人纪录';

  @override
  String get workoutSummaryGeneralPostWorkoutFeedback => '训练后反馈';

  @override
  String get workoutSummaryGeneralRating => '评分';

  @override
  String get workoutSummaryGeneralReps => '次数';

  @override
  String get workoutSummaryGeneralSets => '组数';

  @override
  String workoutSummaryGeneralSets2(Object setCount) {
    return '$setCount 组';
  }

  @override
  String get workoutSummaryGeneralVolumeLb => '训练量 (lb)';

  @override
  String get workoutSummaryManuallyMarkedDone => '已手动标记为完成';

  @override
  String get workoutSummaryNoSetsLoggedFor => '本次训练未记录组数';

  @override
  String get workoutSummaryNoWorkoutDataTo => '暂无训练数据可分享';

  @override
  String get workoutSummaryPleaseCheckYourConnection => '请检查网络连接并重试。';

  @override
  String get workoutSummaryRevertMarkAsNot => '撤销 - 标记为未完成';

  @override
  String get workoutSummaryReverting => '正在撤销...';

  @override
  String get workoutSummaryScreenAllTime => '全部历史';

  @override
  String get workoutSummaryScreenAreasToWatch => '关注区域';

  @override
  String get workoutSummaryScreenFailedToLoadSummary => '无法加载摘要';

  @override
  String get workoutSummaryScreenFirstTimePerformingThis => '首次进行此类型的训练！';

  @override
  String get workoutSummaryScreenHighlights => '亮点';

  @override
  String get workoutSummaryScreenLoadingSummary => '正在加载摘要...';

  @override
  String workoutSummaryScreenManuallyMarkedAsDone(Object formatted) {
    return '已于 $formatted 手动标记为完成';
  }

  @override
  String get workoutSummaryScreenPleaseCheckYourConnection => '请检查网络连接后重试。';

  @override
  String workoutSummaryScreenRepsAcrossSets(
    Object totalReps,
    Object totalSets,
  ) {
    return '$totalSets 组，共 $totalReps 次';
  }

  @override
  String workoutSummaryScreenTotalKgLifted(Object volume) {
    return '总计：已举起 $volume 公斤';
  }

  @override
  String get workoutSummaryScreenU2022 => '  •  ';

  @override
  String workoutSummaryScreenUiImprovement(Object pr) {
    return '提升 +$pr%';
  }

  @override
  String workoutSummaryScreenUiKgXRepsEst(
    Object estimated1rmKg,
    Object reps,
    Object weightKg,
  ) {
    return '$weightKg kg x $reps 次  |  预估 1RM: $estimated1rmKg kg';
  }

  @override
  String workoutSummaryScreenUiValue(Object overallRating) {
    return '$overallRating/10';
  }

  @override
  String get workoutSummarySetsUpdatedSuccessfully => '组数更新成功';

  @override
  String get workoutSummaryShareWorkout => '分享训练';

  @override
  String get workoutSummaryTracked => '已记录';

  @override
  String get workoutSummaryWorkoutSummary => '训练摘要';

  @override
  String get workoutTopBarCompleteWorkout => '完成训练';

  @override
  String get workoutTopBarMore => '更多';

  @override
  String get workoutTopBarSkipExercise => '跳过动作';

  @override
  String get workoutTopOverlayPaused => '已暂停';

  @override
  String get workoutTypeSelectorEnterCustomWorkoutType =>
      '输入自定义训练类型（例如“灵活性训练”）';

  @override
  String get workoutTypeSelectorHowYouWantTo => '选择您的训练方式。在下方的“目标区域”中选择身体部位。';

  @override
  String get workoutTypeSelectorTrainingStyle => '训练风格';

  @override
  String get workoutUiBuildersBreathing => '呼吸';

  @override
  String get workoutUiBuildersConfirm => '确认';

  @override
  String get workoutUiBuildersDrink => '饮水';

  @override
  String get workoutUiBuildersHeardRepsButNot => '听到了次数但未听到重量。请尝试说“225磅做5次”。';

  @override
  String get workoutUiBuildersHowTo => '操作指南';

  @override
  String get workoutUiBuildersLoadingYourPersonalizedWarm => '正在加载您的个性化热身动作';

  @override
  String workoutUiBuildersMixinUi2HeardKg(Object parsed) {
    return '识别为：$parsed kg × ';
  }

  @override
  String workoutUiBuildersMixinUi2LoggedReps(
    Object reps,
    Object weightDisplay,
  ) {
    return '已记录 $weightDisplay × $reps 次';
  }

  @override
  String workoutUiBuildersMixinUi2LoggingAnyway(Object name) {
    return '“$name”。仍记录该练习。';
  }

  @override
  String workoutUiBuildersMixinUi2YouSaidCurrentExercise(Object liftHint) {
    return '您说的是“$liftHint” — 当前练习是 ';
  }

  @override
  String get workoutUiBuildersNote => '备注';

  @override
  String get workoutUiBuildersPreparingWarmup => '正在准备热身...';

  @override
  String get workoutUiBuildersSavingWorkout => '正在保存训练...';

  @override
  String get workoutUiBuildersSkipWarmup => '跳过热身';

  @override
  String get workoutUiBuildersSwap => '替换';

  @override
  String get workoutUiBuildersTapToReturn => '点击返回';

  @override
  String get workoutUiBuildersUndo => '撤销';

  @override
  String get workoutUiModeAdvanced => '进阶模式';

  @override
  String get workoutUiModeEverythingWarmupStretchPh =>
      '全功能——包含热身/拉伸阶段、RPE/RIR、金字塔训练、超级组、递减组、±2.5 kg增量、杠铃片计算表。';

  @override
  String get workoutUiModePickTheLevelOf => '选择您在记录组数时所需的详细程度。您可以随时更改此设置。';

  @override
  String get workoutUiModePolishedDefaultSteppersAi =>
      '精简默认模式。包含步进器、AI教练、休息计时器、语音+照片备注、点击编辑过往组数。适合大多数训练。';

  @override
  String get workoutUiModeSelected => '已选择';

  @override
  String workoutUiModeSheetMode(Object title) {
    return '$title模式';
  }

  @override
  String get workoutUiModeWorkoutMode => '训练模式';

  @override
  String get workoutsBenchSquatDeadliftBest => '卧推、深蹲、硬拉——仅了解最高组数据时最适用';

  @override
  String get workoutsCollapseWeekView => '收起周视图';

  @override
  String get workoutsCompleteYourFirstWorkout => '完成您的第一次训练以在此处查看';

  @override
  String get workoutsCsvOrJsonFile => 'CSV 或 JSON 文件';

  @override
  String get workoutsCustom => '自定义';

  @override
  String get workoutsExpandWeekView => '展开周视图';

  @override
  String get workoutsFavorites => '收藏';

  @override
  String get workoutsFloatingOptionsGym => '健身房';

  @override
  String get workoutsFloatingOptionsManageGym => '管理健身房';

  @override
  String get workoutsGym => '健身房';

  @override
  String get workoutsHealthConnectAppleHealth =>
      'Health Connect / Apple Health';

  @override
  String get workoutsHevyStrongLiftinFitbod =>
      'Hevy, Strong, Liftin\', Fitbod, Stronger by the Day, 自定义 CSV';

  @override
  String get workoutsImportWorkouts => '导入训练';

  @override
  String get workoutsLibrary => '库';

  @override
  String get workoutsMoreOptions => '更多选项';

  @override
  String get workoutsNoCompletedWorkoutsYet => '暂无已完成的训练';

  @override
  String get workoutsPlan => '计划';

  @override
  String get workoutsPrograms => '课程';

  @override
  String workoutsScreenBringYourPastWorkouts(Object appName) {
    return '将你过去的训练和 PR 导入 $appName，这样 AI 从第一天起就能为你选择合适的重量。';
  }

  @override
  String get workoutsStrength => '力量';

  @override
  String get workoutsSyncSessionsFromYour => '从您的手表同步训练（已在后台同步）';

  @override
  String get workoutsTourHitStartOnToday =>
      '点击“今日训练”的“开始”按钮，即可在休息计时器的辅助下记录组数、次数和重量。';

  @override
  String get workoutsTourMakeItYours => '打造专属体验';

  @override
  String get workoutsTourPinFavoritesHideExercises =>
      '置顶收藏、隐藏不想做的动作，或将想做的动作加入队列。';

  @override
  String get workoutsTourSetYourPreferences => '设置您的偏好';

  @override
  String get workoutsTourStartAWorkout => '开始训练';

  @override
  String get workoutsTourUseCustomBrowseOr => '使用“自定义”、“浏览”或“收藏”来创建、替换或重复训练。';

  @override
  String get workoutsTypeAFewPrs => '手动输入几个 PR';

  @override
  String get workoutsUpcoming => '即将到来';

  @override
  String get workoutsYouCanEditUndo => '您可以随时编辑、撤销或重新映射任何导入的数据——所有操作均不会造成破坏。';

  @override
  String get workoutsYourNextWorkoutIs => '您的下一次训练将在每次训练后自动生成';

  @override
  String get wrappedBannerTapToRevealYour => '点击揭晓您的健身人格';

  @override
  String get wrappedBannerViewMyWrapped => '查看我的年度回顾';

  @override
  String wrappedBannerWorkoutsSoFarKeep(Object workoutsSoFar) {
    return '目前已完成 $workoutsSoFar 次训练 · 继续加油！';
  }

  @override
  String wrappedBannerWrappedDropsIn(Object daysLabel, Object month) {
    return '$month 年度总结将在 $daysLabel 后发布';
  }

  @override
  String wrappedBannerYourWrappedIsHere(Object month) {
    return '$month 年度总结已送达';
  }

  @override
  String get wrappedShareCopyText => '复制文本';

  @override
  String get wrappedShareInstagram => 'Instagram';

  @override
  String get wrappedShareSaveImage => '保存图片';

  @override
  String get wrappedShareShareWrapped => '分享年度回顾';

  @override
  String get wrappedShareShowWatermark => '显示水印';

  @override
  String get wrappedSummaryShareYourWrapped => '分享你的年度总结';

  @override
  String get wrappedSummaryStatBestStreak => '最佳连胜';

  @override
  String get wrappedSummaryStatExercises => '练习';

  @override
  String get wrappedSummaryStatHours => '时长';

  @override
  String get wrappedSummaryStatPrs => 'PR 纪录';

  @override
  String get wrappedSummaryStatVolumeLbs => '训练总量 (lbs)';

  @override
  String get wrappedSummaryStatWorkouts => '训练次数';

  @override
  String get wrappedSummaryYourMonthInReview => '你的月度回顾';

  @override
  String wrappedTemplateSets(Object workoutName) {
    return '$workoutName 组数';
  }

  @override
  String get wrappedTemplateVolume => '训练总量';

  @override
  String get wrappedTemplateWrapped => '年度回顾';

  @override
  String get wrappedViewerFailedToLoadYour => '无法加载您的年度回顾';

  @override
  String xpEarnedAnimationXp(Object xpAmount) {
    return '+$xpAmount XP';
  }

  @override
  String get xpGoalsDaily => '每日';

  @override
  String get xpGoalsDialog250LevelsAcross11Tiers => 'XP 目标对话框：11 个等级阶梯，共 250 级';

  @override
  String get xpGoalsDialogBeginnerToTranscendent => '从新手到超凡';

  @override
  String get xpGoalsDialogCompleteWorkoutXp => '完成训练 XP';

  @override
  String get xpGoalsDialogDailyGoals => '每日目标';

  @override
  String get xpGoalsDialogFirstChatWithAiCoachXp => '首次与AI教练对话 XP';

  @override
  String get xpGoalsDialogFirstMealWeightMeasurementsXp => '首次记录饮食重量 XP';

  @override
  String get xpGoalsDialogFirstPrXp => '首次 PR XP';

  @override
  String get xpGoalsDialogFirstProgressPhotoXp => '首次进度照片 XP';

  @override
  String get xpGoalsDialogFirstProteinGoalXp => '首次达成蛋白质目标 XP';

  @override
  String get xpGoalsDialogFirstWorkoutXp => '首次训练 XP';

  @override
  String get xpGoalsDialogHitProteinGoalXp => '达成蛋白质目标 XP';

  @override
  String get xpGoalsDialogLevels => '等级';

  @override
  String get xpGoalsDialogLogBodyMeasurementsXp => '记录身体测量数据 XP';

  @override
  String get xpGoalsDialogLogMealXp => '记录饮食 XP';

  @override
  String get xpGoalsDialogLogWeightXp => '记录体重 XP';

  @override
  String get xpGoalsDialogLoginXp => '登录 XP';

  @override
  String get xpGoalsDialogMilestoneRewards => '里程碑奖励';

  @override
  String get xpGoalsFirstTimeBonuses => '首次奖励';

  @override
  String get xpGoalsGotIt => '知道了！';

  @override
  String get xpGoalsHowXpWorks => 'XP 是如何运作的';

  @override
  String get xpGoalsLoginStreak => '连续登录天数';

  @override
  String get xpGoalsMonthly => '月度';

  @override
  String get xpGoalsScreenAllLevels => '所有等级';

  @override
  String get xpGoalsScreenBeginner => '初学者';

  @override
  String get xpGoalsScreenChatWithAiCoach => '与 AI 教练聊天';

  @override
  String get xpGoalsScreenCheckYourConnectionAnd => '请检查网络连接并重试';

  @override
  String get xpGoalsScreenComplete1Workout => '完成 1 次锻炼';

  @override
  String get xpGoalsScreenCompleteFirstWorkout => '完成首次锻炼';

  @override
  String get xpGoalsScreenConsumableLegend => '消耗品图例';

  @override
  String get xpGoalsScreenErrorLoadingMonthlyAchievem => '加载月度成就时出错';

  @override
  String get xpGoalsScreenErrorLoadingWeeklyProgress => '加载周进度时出错';

  @override
  String get xpGoalsScreenFailedToLoadLevels => '加载等级失败';

  @override
  String get xpGoalsScreenHit10kSteps => '达到 1 万步';

  @override
  String get xpGoalsScreenHitCalorieGoal => '达到卡路里目标';

  @override
  String get xpGoalsScreenHitFirstProteinGoal => '达到首个蛋白质目标';

  @override
  String get xpGoalsScreenHitHydrationGoal => '达到补水目标';

  @override
  String get xpGoalsScreenHitProteinGoal => '达到蛋白质目标';

  @override
  String get xpGoalsScreenInventory => '物品栏';

  @override
  String get xpGoalsScreenLegendary => '传奇';

  @override
  String xpGoalsScreenLevelCurrentTotal(Object arg0) {
    return '当前等级总计 $arg0';
  }

  @override
  String get xpGoalsScreenLevelProgress => '等级进度';

  @override
  String get xpGoalsScreenLogBodyMeasurements => '记录身体测量数据';

  @override
  String get xpGoalsScreenLogFirstMeal => '记录第一餐';

  @override
  String get xpGoalsScreenLogFirstWeight => '记录首次体重';

  @override
  String get xpGoalsScreenLogInToday => '今日登录';

  @override
  String get xpGoalsScreenLogWeight => '记录体重';

  @override
  String get xpGoalsScreenMilestone => '里程碑';

  @override
  String get xpGoalsScreenMilestoneLegend => '里程碑图例';

  @override
  String get xpGoalsScreenNoLevelsAvailable => '暂无可用等级';

  @override
  String get xpGoalsScreenReward => '奖励';

  @override
  String get xpGoalsScreenSetFirstPersonalRecord => '创下首个个人纪录';

  @override
  String xpGoalsScreenUi1CheckpointsComplete(
    Object completedCount,
    Object length,
  ) {
    return '已完成 $completedCount/$length 个检查点';
  }

  @override
  String xpGoalsScreenUi1Complete(Object completedCount, Object length) {
    return '已完成 $completedCount/$length';
  }

  @override
  String xpGoalsScreenUi1DaysRemaining(Object daysRemaining) {
    return '剩余 $daysRemaining 天';
  }

  @override
  String xpGoalsScreenUi1Xp(Object xpInCurrentLevel, Object xpToNextLevel) {
    return '$xpInCurrentLevel / $xpToNextLevel XP';
  }

  @override
  String xpGoalsScreenUi1Xp2(Object earnedXP) {
    return '$earnedXP XP';
  }

  @override
  String xpGoalsScreenUi1Xp3(Object maxXP) {
    return '/ $maxXP XP';
  }

  @override
  String xpGoalsScreenUi1Xp4(Object xpReward) {
    return '+$xpReward XP';
  }

  @override
  String xpGoalsScreenUi1Xp5(Object earnedXP, Object maxXP) {
    return '$earnedXP / $maxXP XP';
  }

  @override
  String xpGoalsScreenUi1Xp6(Object xpReward) {
    return '+$xpReward XP';
  }

  @override
  String xpGoalsScreenUi2Xp(Object xp) {
    return '+$xp XP';
  }

  @override
  String get xpGoalsScreenViewAllLevelsRewards => '查看所有等级与奖励';

  @override
  String xpGoalsScreenXp(Object effectiveXP) {
    return '+$effectiveXP XP';
  }

  @override
  String get xpGoalsScreenXpBonusLegend => 'XP奖励图例';

  @override
  String get xpGoalsScreenYouBadge => '你的徽章';

  @override
  String get xpGoalsTrophyRoom => '奖杯室';

  @override
  String get xpGoalsU2022 => '• ';

  @override
  String get xpGoalsWeekly => '每周';

  @override
  String xpGoalsXpAvailable(Object arg0) {
    return '可用 $arg0';
  }

  @override
  String xpGoalsXpEarnedToday(Object arg0) {
    return '今日获得 $arg0';
  }

  @override
  String get xpGoalsXpGoals => 'XP 目标';

  @override
  String xpGoalsXpMultiplierActive(Object arg0) {
    return '倍率已激活 $arg0';
  }

  @override
  String xpHeroTileDayStreak(Object streak) {
    return '连续 $streak 天';
  }

  @override
  String xpHeroTileLv(Object level) {
    return '等级 $level';
  }

  @override
  String xpHeroTileLv2(Object label, Object nextLevel) {
    return '等级 $nextLevel → $label';
  }

  @override
  String get xpHeroTileThisWeek => '本周';

  @override
  String xpHeroTileValue(Object thisWeekXp) {
    return '+$thisWeekXp';
  }

  @override
  String get xpHeroTileVsLastWeek => '与上周相比';

  @override
  String xpHeroTileXp(Object xpInLevel, Object xpToNext) {
    return '$xpInLevel / $xpToNext XP';
  }

  @override
  String get xpLeaderboardNoLeaderboardDataYet => '暂无排行榜数据。\n开始赚取 XP 以提升排名吧！';

  @override
  String xpLeaderboardScreenLevel(Object currentLevel) {
    return '等级 $currentLevel';
  }

  @override
  String xpLeaderboardScreenLvl(Object currentLevel) {
    return '等级 $currentLevel';
  }

  @override
  String xpLeaderboardScreenValue(Object rank) {
    return '第$rank名';
  }

  @override
  String xpLeaderboardScreenValue2(Object rank) {
    return '第$rank名';
  }

  @override
  String get xpLeaderboardTotalXp => '总 XP';

  @override
  String get xpLeaderboardXpLeaderboard => 'XP 排行榜';

  @override
  String get xpLeaderboardYourRank => '你的排名';

  @override
  String get xpLevelBarLvl => '等级';

  @override
  String xpLevelBarValue(Object progressPercent) {
    return '$progressPercent%';
  }

  @override
  String xpLevelBarValue2(Object progressPercent) {
    return '$progressPercent%';
  }

  @override
  String xpLevelBarXp(Object xpInCurrentLevel, Object xpToNextLevel) {
    return '$xpInCurrentLevel / $xpToNextLevel XP';
  }

  @override
  String get xpProgressCardDaily => '每日';

  @override
  String get xpProgressCardDays => '天';

  @override
  String get xpProgressCardLevel1Novice => '等级 1 • 新手';

  @override
  String xpProgressCardLevelN(Object level) {
    return '等级 $level';
  }

  @override
  String get xpProgressCardLoadingXp => '正在加载 XP...';

  @override
  String xpProgressCardLvl(Object currentLevel, Object displayName) {
    return '等级 $currentLevel $displayName';
  }

  @override
  String xpProgressCardLvlN(Object level) {
    return '等级 $level';
  }

  @override
  String get xpProgressCardNextLevel => '下一等级';

  @override
  String get xpProgressCardNone => '无';

  @override
  String get xpProgressCardNovice => '新手';

  @override
  String xpProgressCardPercentToLevel(Object level, Object percent) {
    return '距离等级 $level 还有 $percent%';
  }

  @override
  String xpProgressCardPrestigeN(Object level) {
    return '声望 $level';
  }

  @override
  String get xpProgressCardStartYourFitnessJourney => '开启你的健身之旅！';

  @override
  String get xpProgressCardStreak => '连胜';

  @override
  String xpProgressCardValue(Object progressPercent) {
    return '$progressPercent%';
  }

  @override
  String get xpProgressCardWeekly => '每周';

  @override
  String xpProgressCardXpTotal(Object xp) {
    return '总 XP $xp';
  }

  @override
  String get youAchievements => '成就';

  @override
  String get youHubMiniGames => '小游戏';

  @override
  String get youHubMiniGamesUnlocked => '🎮 小游戏已解锁！';

  @override
  String get youHubOverview => '概览';

  @override
  String youHubScreenMore(Object remaining) {
    return '更多$remaining…';
  }

  @override
  String get youHubStats => '统计数据';

  @override
  String get youHubStatsScores => '统计与得分';

  @override
  String get youSkills => '技能';

  @override
  String get youTrophies => '奖杯';

  @override
  String get youWrapped => '年度回顾';

  @override
  String chatLanguageChangedSystem(String nativeName) {
    return '🌐 AI Coach 现在使用 $nativeName 回复';
  }

  @override
  String get chatLanguageResetSystem => '🌐 AI Coach 语言已重置 — 使用应用语言';

  @override
  String get settingsChatLanguageTitle => 'AI Coach 语言';

  @override
  String get settingsChatLanguageDescription => 'AI Coach 回复所使用的语言（与应用界面语言分开）';

  @override
  String get settingsChatLanguageSameAsApp => '与应用语言相同';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNo => 'No';

  @override
  String get settingsImportsTitle => '进口';

  @override
  String get settingsImportsSubtitle => '您分享到 Zealova 的所有内容';

  @override
  String get settingsCycleTrackingTitle => '周期追踪';

  @override
  String get settingsCycleTrackingSubtitle => '经期、生育能力和预测';

  @override
  String settingsAboutBrand(Object appName) {
    return '关于$appName';
  }

  @override
  String get vacationModeBannerActive => '假期模式已激活';

  @override
  String vacationModeBannerPausedUntil(Object endDate) {
    return '通知将暂停直至 $endDate。';
  }

  @override
  String get vacationModeBannerPausedNoEnd => '通知已暂停。随时关闭即可恢复。';

  @override
  String get vacationModeBannerScheduled => '预定';

  @override
  String vacationModeBannerStartsOn(Object startDate) {
    return '开始于 $startDate。';
  }

  @override
  String get vacationModeBannerOn => '通知已开启';

  @override
  String get vacationModeBannerOnSubtitle => '启用下面的假期模式以暂停非关键提醒。';

  @override
  String get difficultyEasy => '初学者';

  @override
  String get difficultyMedium => '缓和';

  @override
  String get difficultyHard => '具有挑战性的';

  @override
  String get difficultyHell => '地狱';

  @override
  String get habitWorkouts => '锻炼';

  @override
  String get habitFoodLog => '食物记录';

  @override
  String get habitWater => '水';

  @override
  String get importsAppBarTitle => '进口';

  @override
  String get importsTooltipFormatsLimits => '支持的格式和限制';

  @override
  String get importsTooltipDone => '完毕';

  @override
  String get importsTooltipSelect => '选择';

  @override
  String get importsSearchHint => '搜索进口...';

  @override
  String get importsFilterAll => '全部';

  @override
  String get importsFilterAllFormats => '所有格式';

  @override
  String get importsActionDelete => '删除';

  @override
  String importsSelectedCount(Object count) {
    return '已选择 $count 个';
  }

  @override
  String get importsEmptyTitle => '尚未分享任何内容';

  @override
  String get importsEmptyBody =>
      '点击“在任何地方共享”——照片、YouTube、ChatGPT、语音备忘录——它就会自动降落到此处。';

  @override
  String get importsActionOpen => '打开';

  @override
  String get importsActionRetry => '重试';

  @override
  String get importsActionReclassify => '重新分类';

  @override
  String get importsSnackRetrying => '正在重试导入...';

  @override
  String get importsSnackRetryFailed => '无法重试 - 请稍后再试。';

  @override
  String get importsSnackReclassifyQueued => '重新分类排队 — 再次共享项目以重新路由。';

  @override
  String importsDeleteConfirmTitle(Object count) {
    return '删除 $count 个导入？';
  }

  @override
  String get importsDeleteConfirmBody =>
      '这些记录将从您的导入历史记录中删除。导入的锻炼/食谱/食物日志本身会保留。';

  @override
  String get importsActionCancel => '取消';

  @override
  String get importsRowImportFailed => '导入失败';

  @override
  String get importsTitleImportedWorkout => '进口锻炼';

  @override
  String get importsTitleImportedRecipe => '进口配方';

  @override
  String get importsTitleImportedMealPlan => '进口膳食计划';

  @override
  String get importsTitleLoggedMeal => '记录膳食';

  @override
  String get importsTitleFormCheck => '表格检查';

  @override
  String get importsTitleProgressPhoto => '进度照片';

  @override
  String get importsTitleSavedTip => '已保存小费';

  @override
  String get importsTitleImportDetail => '导入详情';

  @override
  String importsDetailFrom(Object url) {
    return '来自：$url';
  }

  @override
  String importsDetailStatus(Object status) {
    return '状态：$status';
  }

  @override
  String importsDetailDetectedAs(Object intent) {
    return '检测为：$intent';
  }

  @override
  String get importsLimitsTitle => '您可以分享什么';

  @override
  String get importsLimitsLimitsHeader => '限制';

  @override
  String get importsLimitsFooter => '每个人的每日上限都相同。他们保持进口的高品质并防止成本失控。';

  @override
  String get importsPrivacySectionTitle => '进口';

  @override
  String get importsPrivacyAlwaysAskTitle => '在路由之前始终询问';

  @override
  String get importsPrivacyAlwaysAskSubtitle => '跳过自动路由倒计时 - 每个共享都会打开选择器。';

  @override
  String get importsPrivacyClearHistoryTitle => '清除共享历史记录';

  @override
  String get importsPrivacyClearHistorySubtitle =>
      '从导入列表中删除每条记录。导入的锻炼、食谱和食物日志本身会保留下来。';

  @override
  String get importsPrivacyClearConfirmTitle => '清除共享历史记录？';

  @override
  String get importsPrivacyClearConfirmBody =>
      '导入列表中的每一行都将被删除。您导入的锻炼、食谱和饮食日志保留在原处。';

  @override
  String get importsPrivacyClearAction => '清除';

  @override
  String get importsPrivacyClearedSnack => '共享历史记录已清除。';

  @override
  String get importsPrivacyClearFailedSnack => '无法清除 - 请稍后再试。';

  @override
  String get bottomNavLeaderboard => '排行';

  @override
  String get discoverBoardXp => 'XP';

  @override
  String get discoverResetsSunday => '周日重置';

  @override
  String get discoverNoEntriesYet => '还没有记录 · 本周记录一次训练以爬升';

  @override
  String get discoverViewTop10 => '查看前 10 名';

  @override
  String get discoverMovers => '上升者';

  @override
  String get heroModesPillLoading => '加载中';

  @override
  String get heroModesBodyLoading => '正在为你准备今天的计划…';

  @override
  String get heroModesPillOffline => '离线';

  @override
  String get heroModesBodyOffline => '无法加载今日训练。点击重试。';

  @override
  String get heroModesActionRetry => '重试';

  @override
  String get heroModesPillLive => '进行中';

  @override
  String get heroModesPillPaused => '已暂停';

  @override
  String get heroModesBodyPaused => '计划已暂停。准备好后继续。';

  @override
  String get heroModesPillWindDown => '明天 · 放松';

  @override
  String get heroModesBodyWindDown => '先休息。明天的训练会等你。';

  @override
  String get heroModesPillLighter => '建议更轻';

  @override
  String get heroModesBodyLighter => '睡眠不佳。今天试试更轻的版本？';

  @override
  String get heroModesPillEquipmentGap => '器械不足';

  @override
  String get heroModesBodyEquipmentGap => '当前健身房资料中缺少部分器械。';

  @override
  String get heroModesPillFasted => '空腹中';

  @override
  String get heroModesBodyFasted => '空腹训练没问题。强度适中；训练后 30 分钟内补给。';

  @override
  String get heroModesPillFuelGap => '燃料不足';

  @override
  String get heroModesBodyFuelGap => '上一餐已经很久了。吃约 200 大卡碳水？';

  @override
  String get heroModesPillComeback => '回归训练';

  @override
  String get heroModesBodyComeback => '久违的肌群第一次训练。慢慢来。';

  @override
  String get heroModesPillPrWindow => 'PR 窗口';

  @override
  String get heroModesBodyPrWindow => '今天接近个人纪录。要试试吗？';

  @override
  String get heroModesActionStart => '开始';

  @override
  String get heroModesPillBodyAsksRest => '身体需要休息';

  @override
  String get heroModesBodyBodyAsksRest => '5 个艰苦日，睡眠下降。今天是为下周做的投资。';

  @override
  String get heroModesPillRefuelWindow => '补给窗口';

  @override
  String get heroModesBodyRefuelWindow => '30 分钟补给窗口：蛋白质 + 碳水锁定成果。';

  @override
  String get heroModesPillBonus => '加场';

  @override
  String get heroModesBodyBonus => '有 20 分钟？挤进一段快速训练。';

  @override
  String get heroModesPillYesterday => '昨天';

  @override
  String get heroModesBodyYesterday => '昨天的训练还开着。挪到今天？';

  @override
  String get metricsDashboardKeyMetrics => 'KEY METRICS';

  @override
  String get metricsDashboardTrends => 'TRENDS';

  @override
  String get metricsDashboardEnergyBurned => 'Energy burned';

  @override
  String get metricsDashboardCalorieIntake => 'Calorie intake';

  @override
  String get metricsDashboardSteps => 'Steps';

  @override
  String get metricsDashboardMindfulnessMinutes => 'Mindful minutes';

  @override
  String get metricsDashboardGoalMet => 'Goal met';

  @override
  String get metricsDashboardExerciseDays => 'Exercise days';

  @override
  String get metricsDashboardThisWeek => 'this week';

  @override
  String get metricsDashboardNoData => 'No data';

  @override
  String get metricsDashboardMacros => 'Macros';

  @override
  String get metricsDashboardCarbs => 'Carbs';

  @override
  String get metricsDashboardFat => 'Fat';

  @override
  String get metricsDashboardProtein => 'Protein';

  @override
  String get metricsDashboardHealthChecks => 'HEALTH CHECKS';

  @override
  String get metricsDashboardConnectWearable => 'Connect a wearable';

  @override
  String get metricsDashboardHrLow => 'Low';

  @override
  String get metricsDashboardHrLowNormal => 'Low-normal';

  @override
  String get metricsDashboardHrNormal => 'Normal';

  @override
  String get metricsDashboardHrHigh => 'High';

  @override
  String get metricsDashboardHrDisclaimer =>
      'Informational only, not medical advice. Talk to a clinician about any concerns.';

  @override
  String get metricsDashboardCustomizeThresholds => 'Customize thresholds';

  @override
  String get metricsDashboardHrThresholdOrderError => 'Low must be below high.';

  @override
  String get metricsDashboardSaveFailed => 'Couldn\'t save. Please try again.';

  @override
  String metricsDashboardOfGoal(String goal) {
    return 'of $goal';
  }

  @override
  String metricsDashboardHrRangeExplainer(int low, int high) {
    return 'Normal resting heart rate is $low–$high bpm. Below $low or above $high bpm is flagged for awareness.';
  }

  @override
  String get metricsDashboardGetStartedTitle => 'Start tracking';

  @override
  String get metricsDashboardGetStartedCta =>
      'Connect a wearable or log a meal to see your metrics.';

  @override
  String quizMinutesLeft(int minutes) {
    return '约剩 $minutes 分钟';
  }

  @override
  String quizStepOfTotal(int current, int total) {
    return 'STEP $current OF $total';
  }

  @override
  String get quizAlmostDone => 'ALMOST DONE';

  @override
  String get introV7HeadlineLine1 => '你的教练';

  @override
  String get introV7HeadlineAlready => '已经';

  @override
  String get introV7WordTyping => '在输入。';

  @override
  String get introV7WordSpotting => '在护杠。';

  @override
  String get introV7WordCounting => '在计数。';

  @override
  String get introV7WordChoosing => '在挑选。';

  @override
  String get introV7BuildMyPlan => '生成我的计划';

  @override
  String get introDemoLiveBadge => '实时演示';

  @override
  String get introDemoProgramBuilder => '训练计划生成器';

  @override
  String get introDemoCoachName => 'Alex 教练';

  @override
  String get introDemoUserAsk => '帮我安排每周 4 天的训练计划 💪';

  @override
  String get introDemoPushDayMon => '推力日 · 周一';

  @override
  String get introDemoGoalChip => '📅 预计达成目标：8月22日';

  @override
  String get introDemoUserReply => '开练 🔥';

  @override
  String get introDemoExerciseKicker => '推力日 · 第 1/5 个动作';

  @override
  String introDemoSetRow(int n) {
    return '第 $n 组';
  }

  @override
  String get introDemoResting => '休息中…';

  @override
  String get introDemoPrChip => '🏆 新 PR · 225 lb';

  @override
  String get introDemoCoachPrLine => '教练：“225——比之前多了 10 lb，刷新 PR。下周我们冲 230。”';

  @override
  String get introDemoPhotoLogging => '拍照记录';

  @override
  String get introDemoLoggedLine => '✓ 已记录到今天——1 张照片，2 秒搞定';

  @override
  String get introDemoKcalChip => '540 kcal';

  @override
  String get introDemoProteinChip => '38g 蛋白质';

  @override
  String get introDemoCarbsChip => '52g 碳水';

  @override
  String get introDemoFatChip => '18g 脂肪';

  @override
  String get introDemoMenuTitle => '菜单分析';

  @override
  String get introDemoMenuMeta => '8 道菜 · 3 个分区 · 2.4s';

  @override
  String get introDemoSortLabel => '排序：';

  @override
  String get introDemoSortProtein => '蛋白质';

  @override
  String get introDemoSortCarbs => '碳水';

  @override
  String get introDemoSortInflammation => '炎症';

  @override
  String get introDemoBadgeRecommended => '推荐';

  @override
  String get introDemoBadgeOk => '还行';

  @override
  String get introDemoBadgeAvoid => '避开';

  @override
  String planAnalyzingReceiptGoals(String goal) {
    return '目标已确认——$goal';
  }

  @override
  String planAnalyzingReceiptBody(String body) {
    return '体型已匹配——$body';
  }

  @override
  String planAnalyzingReceiptSchedule(int days) {
    return '日程已设定——每周 $days 天';
  }

  @override
  String get planAnalyzingSubtitleV7 => '约 20 秒 · 你的教练正在敲定每一组';

  @override
  String get signInV7DontLoseIt => '别弄丢了。';

  @override
  String get signInV7LetsGetStarted => '开始吧。';

  @override
  String get signInV7KickerPlanBuilt => '你的计划已生成';

  @override
  String signInV7GoalDateChip(String date) {
    return '📅 目标：$date';
  }

  @override
  String get personalInfoConfirmedFromQuiz => '已根据问卷确认';

  @override
  String personalInfoGoalChip(String value) {
    return '目标 $value';
  }

  @override
  String coachSelectionTrainWith(String coachName) {
    return '和 $coachName 一起训练';
  }

  @override
  String get paywallFounderKicker => '创始人的一封信';

  @override
  String get paywallFounderHeadline => '我打造了那个我请不起的教练。';

  @override
  String get paywallFounderQuote =>
      '“一位好的私人教练每月要 \$400。我实在负担不起，于是花了两年时间自己做了一个：1,722 个动作、真实的渐进负荷逻辑、一个真正会查看你这一周的教练。我自己每天都在用。”';

  @override
  String get paywallFounderName => 'Chetan · 创始人';

  @override
  String get paywallFounderSub => '从第一天起就在用 Zealova 训练';

  @override
  String get paywallTesterQuote => '“它发现我总是跳过周五的练腿日，然后就……直接把它挪到了周六。”';

  @override
  String get paywallTesterName => 'Keertan · 早期测试者';

  @override
  String get paywallEarlyAccess => '抢先体验 · 成为首批 1,000 名会员之一';

  @override
  String get paywallRemindMeCta => '提醒我 🔔';

  @override
  String get paywallTrialToggleTitle => '已开启免费试用';

  @override
  String paywallTrialToggleOn(String price) {
    return '免费 7 天，之后按 $price/年自动续订';
  }

  @override
  String get paywallTrialToggleOff => '月度方案——今天开始，无试用期';

  @override
  String get paywallV7DownsellHeadline => '你的计划要被删除了？';

  @override
  String get paywallV7DownsellSub => '一次性创始会员价，同样享 7 天免费试用。此优惠不会再出现。';
}
