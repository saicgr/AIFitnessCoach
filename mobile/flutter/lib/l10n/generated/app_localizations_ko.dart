// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get aboutDisableBeastMode => 'Beast Mode 비활성화';

  @override
  String get aboutLoadingBuildInfo => '빌드 정보 불러오는 중...';

  @override
  String get accessibilityAccessibility => '접근성';

  @override
  String get accessibilityAppMode => '앱 모드';

  @override
  String get accessibilityCardAccessibility => '접근성';

  @override
  String get accessibilityCardBiggerTouchTargetsFor => '터치 영역을 확대하여 조작을 쉽게 합니다';

  @override
  String get accessibilityCardHighContrast => '고대비';

  @override
  String get accessibilityCardIncreaseColorContrastFor =>
      '색상 대비를 높여 가독성을 향상합니다';

  @override
  String get accessibilityCardLargeButtons => '큰 버튼';

  @override
  String get accessibilityCardMinimizeMotionEffects => '동작 효과 최소화';

  @override
  String get accessibilityCardReduceAnimations => '애니메이션 줄이기';

  @override
  String get accessibilityCardVisualAndInteractionAdjustm => '시각 및 상호작용 조정';

  @override
  String get accessibilityCurrentMode => '현재 모드';

  @override
  String get accessibilityFontSize => '글자 크기';

  @override
  String get accessibilityHighContrast => '고대비';

  @override
  String get accessibilityLargeButtons => '큰 버튼';

  @override
  String get accessibilityLevelUpProgression => '레벨업 진행도';

  @override
  String get accessibilityReduceAnimations => '애니메이션 줄이기';

  @override
  String get accessibilitySenior => '시니어';

  @override
  String get accessibilityStandard => '표준';

  @override
  String get accuracyFeedbackSnackbarAccurate => '정확한가요?';

  @override
  String accuracyFeedbackSnackbarCal(Object calories, Object displayName) {
    return '$displayName — $calories cal';
  }

  @override
  String get achievementsBadges => '배지';

  @override
  String get achievementsByCategory => '카테고리별';

  @override
  String get achievementsCardAchievements => '업적';

  @override
  String achievementsCardBadges(Object totalAchieved) {
    return '배지 $totalAchieved개';
  }

  @override
  String get achievementsCardCompleteWorkoutsToUnlock =>
      '운동을 완료하고 배지를 잠금 해제하세요!';

  @override
  String get achievementsCardLoadingAchievements => '업적 불러오는 중...';

  @override
  String get achievementsCardNext => '다음: ';

  @override
  String get achievementsCardStartYourJourney => '여정 시작하기';

  @override
  String get achievementsCompleteWorkoutsToEarn => '운동을 완료하고 업적을 달성하세요!';

  @override
  String get achievementsCurrentStreaks => '현재 연속 기록';

  @override
  String get achievementsKeepWorkingOutTo => '계속 운동하여 배지를 잠금 해제하세요!';

  @override
  String get achievementsLiftHeavierToSet => '더 무겁게 들어 새로운 PR을 세우세요!';

  @override
  String get achievementsNoAchievementsYet => '아직 달성한 업적이 없습니다';

  @override
  String get achievementsNoBadgesEarned => '획득한 배지가 없습니다';

  @override
  String get achievementsNoPersonalRecords => '개인 기록이 없습니다';

  @override
  String get achievementsPrs => 'PR';

  @override
  String get achievementsRecentAchievements => '최근 업적';

  @override
  String achievementsScreenAchievementsEarned(Object totalAchievements) {
    return '업적 $totalAchievements개 달성';
  }

  @override
  String achievementsScreenBestDays(Object longestStreak) {
    return '최고: $longestStreak일';
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
  String get achievementsSeeAll => '모두 보기';

  @override
  String get achievementsSummary => '요약';

  @override
  String get achievementsTotalPoints => '총 점수';

  @override
  String get achievementsUnlocked => '잠금 해제됨';

  @override
  String get actionCalibrationSavedSummary => '보정 저장됨';

  @override
  String get actionChipsRowAdjust => '조정';

  @override
  String get actionChipsRowIncrements => '증분';

  @override
  String get actionChipsRowInfo => '정보';

  @override
  String get actionChipsRowLR => '좌/우';

  @override
  String get actionChipsRowNote => '메모';

  @override
  String get actionChipsRowReorder => '재정렬';

  @override
  String get actionChipsRowSuperset => '슈퍼세트';

  @override
  String get actionChipsRowSwap => '교체';

  @override
  String get actionChipsRowTargets => '목표';

  @override
  String get actionChipsRowTimer => '타이머';

  @override
  String get actionChipsRowVideo => '비디오';

  @override
  String get actionChipsRowWarmUp => '웜업';

  @override
  String get actionDarkModeToggledSummary => '다크 모드 전환됨';

  @override
  String actionDeloadStartedSummary(Object reason) {
    return '디로딩 시작: $reason';
  }

  @override
  String get actionEquipmentCalibratedSummary => '장비 보정 완료';

  @override
  String actionExerciseSwappedSummary(Object newExercise, Object oldExercise) {
    return '$oldExercise을(를) $newExercise(으)로 교체함';
  }

  @override
  String get actionFoodLoggedSummary => '음식 기록됨';

  @override
  String actionHydrationLoggedSummary(Object amount) {
    return '$amount 기록됨';
  }

  @override
  String actionMealScannedSummary(Object itemCount) {
    return '$itemCount개 항목 스캔됨';
  }

  @override
  String actionMenuScannedSummary(Object itemCount) {
    return '$itemCount개 메뉴 항목 분석됨';
  }

  @override
  String get actionRegenerateRequestedSummary => '운동 재생성 요청됨';

  @override
  String actionSettingsChangedSummary(Object settingName) {
    return '$settingName 업데이트됨';
  }

  @override
  String get actionWorkoutAddedSummary => '운동 추가됨';

  @override
  String get actionWorkoutRemovedSummary => '운동 삭제됨';

  @override
  String activeFilterChipsAvoid(Object avoid) {
    return '제외: $avoid';
  }

  @override
  String get activeFilterChipsClearAll => '모두 지우기';

  @override
  String get activeWorkoutHelperAdvanced => '고급';

  @override
  String get activeWorkoutHelperAutoAdjusts => '자동 조정';

  @override
  String get activeWorkoutHelperBodyweight => '맨몸 운동';

  @override
  String get activeWorkoutHelperBreathing => '호흡';

  @override
  String get activeWorkoutHelperChooseHowWeightChanges => '세트 간 중량 변경 방식 선택';

  @override
  String get activeWorkoutHelperDifficulty => '난이도';

  @override
  String get activeWorkoutHelperDonTHaveThis => '이 장비가 없으신가요?';

  @override
  String get activeWorkoutHelperEquipment => '장비';

  @override
  String get activeWorkoutHelperExerciseInfo => '운동 정보';

  @override
  String get activeWorkoutHelperFormCues => '자세 팁';

  @override
  String get activeWorkoutHelperLoadingAiCoachTips => 'AI 코치 팁 불러오는 중...';

  @override
  String get activeWorkoutHelperPrimaryMuscle => '주동근';

  @override
  String get activeWorkoutHelperProTip => '프로 팁';

  @override
  String get activeWorkoutHelperSecondaryMuscles => '협응근';

  @override
  String get activeWorkoutHelperSetProgression => '세트 진행 방식';

  @override
  String get activeWorkoutHelperTapVideoToWatch => '\"비디오\"를 탭하여 자세 시연 보기';

  @override
  String get activeWorkoutHelperVideo => '비디오';

  @override
  String get activeWorkoutHelperWatchOutFor => '주의 사항';

  @override
  String get activeWorkoutHelperWhenToUse => '사용 시기';

  @override
  String get activeWorkoutScreenExerciseSwappedSuccessfully =>
      '운동이 성공적으로 교체되었습니다';

  @override
  String activeWorkoutScreenRefactoredExerciseSAdded(Object _exercises) {
    return '운동 $_exercises개 추가됨';
  }

  @override
  String get activeWorkoutScreenUndo => '실행 취소';

  @override
  String get activeWorkoutScreenWorkoutAdapted => '운동이 조정되었습니다.';

  @override
  String get activityCardAdditionalDetailsOptional => '추가 세부 정보 (선택 사항)';

  @override
  String get activityCardAreYouSureYou => '이 게시물을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get activityCardCopyLink => '링크 복사';

  @override
  String get activityCardDeletePost => '게시물 삭제';

  @override
  String get activityCardEditPost => '게시물 수정';

  @override
  String get activityCardFailedToSubmitReport => '신고 제출에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get activityCardLinkCopiedToClipboard => '링크가 클립보드에 복사되었습니다';

  @override
  String activityCardPartChallengeLeaderboardM(Object duration) {
    return '$duration분';
  }

  @override
  String get activityCardPartLeaderboard => '리더보드';

  @override
  String get activityCardPinToTop => '상단에 고정';

  @override
  String get activityCardPinnedPost => '고정된 게시물';

  @override
  String get activityCardReport => '신고';

  @override
  String get activityCardReportPost => '게시물 신고';

  @override
  String get activityCardReportSubmittedThankYou =>
      '신고가 제출되었습니다. 커뮤니티를 안전하게 유지하도록 도와주셔서 감사합니다.';

  @override
  String get activityCardSubmit => '제출';

  @override
  String get activityCardUiChallengeAttempted => '챌린지 도전 완료';

  @override
  String get activityCardUiEarnedAnAchievement => '업적 달성';

  @override
  String get activityCardUiKeepTrainingEveryAttempt =>
      '계속 훈련하세요! 모든 시도가 당신을 더 강하게 만듭니다';

  @override
  String activityCardUiLbs(Object yourVolume) {
    return '$yourVolume lbs';
  }

  @override
  String activityCardUiLbs2(Object theirVolume) {
    return '$theirVolume lbs';
  }

  @override
  String activityCardUiLbs3(Object volumeDifference) {
    return '+$volumeDifference lbs';
  }

  @override
  String activityCardUiMin(Object yourDuration) {
    return '$yourDuration 분';
  }

  @override
  String activityCardUiMin2(Object theirDuration) {
    return '$theirDuration 분';
  }

  @override
  String activityCardUiMinFaster(Object timeDifference) {
    return '$timeDifference 분 더 빠름';
  }

  @override
  String get activityCardUiTarget => '목표: ';

  @override
  String get activityCardUiThem => '상대';

  @override
  String get activityCardUiTime => '시간';

  @override
  String get activityCardUiVictory => '승리!';

  @override
  String get activityCardUiVolume => '볼륨';

  @override
  String get activityCardUiYou => '나: ';

  @override
  String get activityCardUnpinPost => '게시물 고정 해제';

  @override
  String get activityCardWhyAreYouReporting => '이 게시물을 신고하는 이유는 무엇인가요?';

  @override
  String get activityHeatmapActivity => '활동';

  @override
  String get activityHeatmapFailedToLoadActivity => '활동을 불러오지 못했습니다';

  @override
  String get activityHeatmapMissed => '놓침';

  @override
  String get activityHeatmapRest => '휴식';

  @override
  String get activityHeatmapSearchExercise => '운동 검색...';

  @override
  String activityHeatmapTimes(Object timesPerformed) {
    return '$timesPerformed회';
  }

  @override
  String get activityShareAddACaption => '캡션 추가...';

  @override
  String get activityShareCardConsistencyIsKey => '꾸준함이 핵심입니다';

  @override
  String activityShareCardLbs(Object absValue) {
    return '$absValue lbs';
  }

  @override
  String get activityShareCardSharedAnUpdate => '업데이트 공유됨';

  @override
  String activityShareCardValue(Object userName) {
    return '@$userName';
  }

  @override
  String get activityShareCopyText => '텍스트 복사';

  @override
  String get activityShareInstagram => 'Instagram';

  @override
  String get activityShareSaveImage => '이미지 저장';

  @override
  String get activityShareSharePost => '게시물 공유';

  @override
  String get activityShareShowWatermark => '워터마크 표시';

  @override
  String get activityShareTapToAddA => '탭하여 캡션 추가...';

  @override
  String get addFoodEGMadeWith => '예: \'올리브 오일로 조리, 통곡물 제외\' 또는 \'절반만 먹음\'';

  @override
  String get addFoodRefineWithAi => 'AI로 다듬기';

  @override
  String get addGymProfileAccountDefault => '계정 기본값';

  @override
  String get addGymProfileAddNewGym => '새 체육관 추가';

  @override
  String get addGymProfileAvailableEquipment => '사용 가능한 장비';

  @override
  String get addGymProfileClear => '지우기';

  @override
  String get addGymProfileColor => '색상';

  @override
  String get addGymProfileCreateGym => '체육관 만들기';

  @override
  String get addGymProfileCustomizeTheEquipmentAvaila =>
      '무게 범위를 포함하여 이 체육관에서 사용할 수 있는 장비를 맞춤 설정하세요';

  @override
  String get addGymProfileDoYouHaveA => '웨이트 벤치가 있나요?';

  @override
  String get addGymProfileDoYouHaveA2 => '스쿼트 랙이 있나요?';

  @override
  String get addGymProfileEGHomeGym => '예: 홈 짐, Planet Fitness, 호텔';

  @override
  String get addGymProfileEnterANameFor => '먼저 체육관 이름을 입력하세요 (1단계).';

  @override
  String get addGymProfileEquipment => '장비';

  @override
  String get addGymProfileGymName => '체육관 이름';

  @override
  String get addGymProfileIcon => '아이콘';

  @override
  String get addGymProfileImportFromPdfPhoto => 'PDF, 사진 또는 URL에서 가져오기';

  @override
  String get addGymProfileMatchAppTheme => '앱 테마와 일치';

  @override
  String get addGymProfileOptionalLeaveOnLet =>
      '선택 사항 — 확실하지 않으면 \"AI가 결정하도록 두기\"로 두세요.';

  @override
  String get addGymProfilePickAtLeastOne => '이 체육관에서 운동할 요일을 최소 하나 이상 선택하세요.';

  @override
  String get addGymProfilePleaseEnterAName => '체육관 이름을 입력해 주세요';

  @override
  String get addGymProfileRequiredForBarbellSquat =>
      '필수 항목: 바벨 스쿼트, 오버헤드 프레스, 바벨 벤치 프레스';

  @override
  String get addGymProfileResetAll => '모두 재설정';

  @override
  String addGymProfileSheetCouldNotSaveProfile(Object e) {
    return '가져오기 전 프로필을 저장할 수 없습니다: $e';
  }

  @override
  String addGymProfileSheetExtSelectedEquipment(Object length) {
    return '선택된 장비 ($length)';
  }

  @override
  String addGymProfileSheetPartEquipmentFollowUpValue(Object currentColor) {
    return '#$currentColor';
  }

  @override
  String get addGymProfileTapToAddRemove => '탭하여 무게 추가, 제거 또는 편집';

  @override
  String get addGymProfileThisHelpsUsSuggest => '올바른 장비를 제안하는 데 도움이 됩니다';

  @override
  String get addGymProfileTrainingSplit => '트레이닝 분할';

  @override
  String get addGymProfileUnlocksBenchPressIncline =>
      '잠금 해제: 벤치 프레스, 인클라인 프레스, 풀오버, 체스트 서포티드 로우';

  @override
  String get addGymProfileUnlocksChestSupportedKb =>
      '잠금 해제: 체스트 서포티드 KB 로우, KB 플로어 프레스 대안';

  @override
  String get addGymProfileWorkoutEnvironment => '운동 환경';

  @override
  String get addGymProfileWorkoutSchedule => '운동 일정';

  @override
  String get addGymProfileYesAddIt => '네, 추가합니다';

  @override
  String get addGymSheetAddNewGym => '새 헬스장 추가';

  @override
  String addGymSheetAlsoAt(Object names) {
    return '추가 장소: $names';
  }

  @override
  String get addGymSheetBack => '뒤로';

  @override
  String get addGymSheetCommercialGym => '상업용 헬스장';

  @override
  String get addGymSheetCommercialGymDesc => '모든 머신과 장비 이용 가능';

  @override
  String addGymSheetConflictDay(Object day, Object names) {
    return '$day에 \"$names\"에서도 운동';
  }

  @override
  String addGymSheetConflictMessage(Object details) {
    return '일정 중복: $details. 해당 요일에 활성화된 프로필이 운동을 담당합니다.';
  }

  @override
  String get addGymSheetCreateGym => '헬스장 생성';

  @override
  String addGymSheetCreatedProfile(Object name) {
    return '✓ \"$name\" 헬스장 프로필 생성됨';
  }

  @override
  String get addGymSheetCurrent => '현재';

  @override
  String get addGymSheetEnterGymName => '헬스장 이름을 입력하세요';

  @override
  String get addGymSheetEnterNameFirst => '먼저 헬스장 이름을 입력하세요';

  @override
  String get addGymSheetEquipment => '장비';

  @override
  String addGymSheetEquipmentCount(Object count) {
    return '기구 $count개';
  }

  @override
  String addGymSheetEquipmentSelected(Object count) {
    return '$count개의 장비 선택됨';
  }

  @override
  String addGymSheetFailedToCreate(Object error) {
    return '프로필 생성 실패: $error';
  }

  @override
  String get addGymSheetFollowUpBenchSubtitle =>
      '잠금 해제: 벤치 프레스, 인클라인 프레스, 풀오버, 체스트 서포티드 로우';

  @override
  String get addGymSheetFollowUpBenchTitle => '웨이트 벤치가 있나요?';

  @override
  String get addGymSheetFollowUpSquatRackSubtitle =>
      '필수 항목: 바벨 스쿼트, 오버헤드 프레스, 바벨 벤치 프레스';

  @override
  String get addGymSheetFollowUpSquatRackTitle => '스쿼트 랙이 있나요?';

  @override
  String get addGymSheetGymNameHint => '예: 홈짐, Planet Fitness, 호텔';

  @override
  String get addGymSheetHelpsUsSuggest => '적절한 장비를 추천하는 데 도움이 됩니다';

  @override
  String get addGymSheetHomeGym => '홈짐';

  @override
  String get addGymSheetHomeGymDesc => '장비가 갖춰진 전용 운동 공간';

  @override
  String get addGymSheetHomeMinimal => '홈 (최소 장비)';

  @override
  String get addGymSheetHomeMinimalDesc => '맨몸 운동 전용';

  @override
  String get addGymSheetHotelTravel => '호텔 / 여행';

  @override
  String get addGymSheetHotelTravelDesc => '여행 중 제한된 공간과 장비';

  @override
  String addGymSheetItems(Object count) {
    return '$count개 항목';
  }

  @override
  String get addGymSheetNext => '다음';

  @override
  String get addGymSheetOutdoors => '야외';

  @override
  String get addGymSheetOutdoorsDesc => '공원, 야외 운동 시설 및 개방된 공간';

  @override
  String get addGymSheetPickAtLeastOneDay => '최소 하루 이상의 운동 요일을 선택하세요';

  @override
  String get addGymSheetPickDaysDesc =>
      '이 헬스장에서 운동할 요일을 선택하세요. 프로필을 전환하는 즉시 해당 요일에 대한 14일치 운동 계획이 미리 생성됩니다.';

  @override
  String addGymSheetSameAs(Object name) {
    return '$name과(와) 동일';
  }

  @override
  String get addGymSheetSkip => '건너뛰기';

  @override
  String get addGymSheetSplitBodyPart => '부위별';

  @override
  String get addGymSheetSplitDesc3Days => '3일';

  @override
  String get addGymSheetSplitDesc4Days => '4일';

  @override
  String get addGymSheetSplitDesc56Days => '5-6일';

  @override
  String get addGymSheetSplitDesc6Days => '6일';

  @override
  String get addGymSheetSplitDescFlexible => '유연함';

  @override
  String get addGymSheetSplitFullBody => '전신';

  @override
  String get addGymSheetSplitLetAiDecide => 'AI가 결정';

  @override
  String get addGymSheetSplitPhul => 'PHUL';

  @override
  String get addGymSheetSplitPushPullLegs => '밀기/당기기/하체';

  @override
  String get addGymSheetSplitUpperLower => '상체/하체';

  @override
  String addGymSheetStepOf(Object step, Object total) {
    return '$step단계 / $total';
  }

  @override
  String get addGymSheetWorkoutEnvironment => '운동 환경';

  @override
  String get addGymSheetYesAddIt => '네, 추가합니다';

  @override
  String get addScheduleItemAddToGoogleCalendar => 'Google Calendar에 추가';

  @override
  String get addScheduleItemAddToSchedule => '일정에 추가';

  @override
  String get addScheduleItemEditItem => '항목 편집';

  @override
  String get addScheduleItemSaveChanges => '변경 사항 저장';

  @override
  String get advancedAudioCountdownRestTimerVoice => '카운트다운, 휴식 타이머, 음성 안내';

  @override
  String get advancedAudioSoundEffectsWorkoutAudio => '효과음 및 운동 오디오';

  @override
  String get agentInfoHeaderConnectedToSupport => '고객 지원 연결됨';

  @override
  String get agentInfoHeaderOffline => '오프라인';

  @override
  String get agentInfoHeaderOnline => '온라인';

  @override
  String agentInfoHeaderSupportAgent(Object appName) {
    return '$appName 지원 상담원';
  }

  @override
  String get agentInfoHeaderTyping => '입력 중';

  @override
  String get aiCoachAdvancedSettings => '고급 설정';

  @override
  String get aiCoachAiPersonalizedMessages => 'AI 맞춤형 메시지';

  @override
  String get aiCoachBalanced => '균형 잡힌';

  @override
  String get aiCoachCelebrateStreakMilestones => '연속 기록 마일스톤 축하';

  @override
  String get aiCoachCoachNotifications => '코치 알림';

  @override
  String get aiCoachCoachVoicePersonality => '코치의 목소리와 성격';

  @override
  String get aiCoachEveningCheckInFor => '습관을 위한 저녁 체크인';

  @override
  String get aiCoachFloatingAiChatBubble => '떠다니는 AI 채팅 버블';

  @override
  String get aiCoachGentle => '온화한';

  @override
  String get aiCoachGetNotifiedWhenYour => '크레이트가 준비되면 알림 받기';

  @override
  String get aiCoachHabitReminders => '습관 알림';

  @override
  String get aiCoachHowMuchYourAi => 'AI 코치가 당신을 독려하는 정도';

  @override
  String get aiCoachMatchYourCoachS => '코치의 성격 맞춤 설정';

  @override
  String get aiCoachMealAnalyzingYourDay => '하루를 분석하는 중…';

  @override
  String get aiCoachMealAngryWhatToEat => '화났어요 - 무엇을 먹을까?';

  @override
  String get aiCoachMealAnxiousCalmingPick => '불안함 - 차분한 선택?';

  @override
  String get aiCoachMealAnythingHealthy => '건강한 음식 아무거나';

  @override
  String get aiCoachMealAsian => '아시아 사람';

  @override
  String get aiCoachMealAsianInspiredPick => '아시아에서 영감을 받은 선택?';

  @override
  String get aiCoachMealAskTheCoach => '코치에게 물어보기';

  @override
  String get aiCoachMealBalanceMyMacros => '내 매크로의 균형을 맞추나요?';

  @override
  String get aiCoachMealBloatedWhatNow => '부풀어 오른 — 지금은 무엇입니까?';

  @override
  String get aiCoachMealBoredEatingWhatInstead => '지루하게 먹는 것 - 대신에 무엇을?';

  @override
  String get aiCoachMealBudgetFriendlyMeal => '예산 친화적인 식사?';

  @override
  String get aiCoachMealBulkingCalorieDensePick => '칼로리 밀도가 높은 선택을 원하십니까?';

  @override
  String get aiCoachMealCoachNeedsAConnection => '코치는 연결이 필요합니다.';

  @override
  String get aiCoachMealComfortFoodSmartVersion => '편안한 음식, 스마트 버전?';

  @override
  String get aiCoachMealCravingSugarSmartSwap => '설탕에 대한 갈망 – 스마트 스왑?';

  @override
  String get aiCoachMealCuttingFriendlyMeal => '커팅 친화적인 식사?';

  @override
  String get aiCoachMealFastFood => '패스트푸드';

  @override
  String get aiCoachMealFastFoodPick => '패스트푸드 선택?';

  @override
  String get aiCoachMealFastingFriendlyPick => '단식 친화적인 선택?';

  @override
  String get aiCoachMealFavoriteIMissed => '내가 놓친 좋아하는 것?';

  @override
  String get aiCoachMealHeadacheFoodFix => '두통 - 음식 해결?';

  @override
  String get aiCoachMealHeartburnSafePick => '속쓰림에 안전한 선택?';

  @override
  String get aiCoachMealHighProtein => '고단백';

  @override
  String get aiCoachMealHighProteinIdea => '고단백 아이디어?';

  @override
  String get aiCoachMealHitMyCalorieTarget => '내 칼로리 목표를 달성했나요?';

  @override
  String get aiCoachMealHydrationCheck => '수분체크?';

  @override
  String get aiCoachMealIndian => '옥수수';

  @override
  String get aiCoachMealItalianComfort => '이탈리아어 / 컴포트';

  @override
  String get aiCoachMealLateNightSnack => '야식?';

  @override
  String get aiCoachMealLogThisMeal => '이 식단 기록하기';

  @override
  String get aiCoachMealLookingAtTodayS => '오늘의 식사와 운동, 즐겨찾기를 살펴보며…';

  @override
  String get aiCoachMealLowCalSwap => '저칼로리 교환?';

  @override
  String get aiCoachMealLowSugarOption => '저당 옵션?';

  @override
  String get aiCoachMealMaintenanceSteadyPick => '유지관리 꾸준한 픽?';

  @override
  String get aiCoachMealMediterranean => '지중해';

  @override
  String get aiCoachMealMediterraneanOption => '지중해식 옵션?';

  @override
  String get aiCoachMealMexican => '멕시코 인';

  @override
  String get aiCoachMealMexicanWithGoodMacros => '매크로가 좋은 멕시코 사람?';

  @override
  String get aiCoachMealNeedMoreFiber => '섬유질이 더 필요하신가요?';

  @override
  String get aiCoachMealNoCook5Min => '요리 없음 / 5분';

  @override
  String get aiCoachMealNoCookOption => '조리 필요 없는 옵션?';

  @override
  String get aiCoachMealOpenFullChat => '전체 채팅 열기';

  @override
  String get aiCoachMealPoorSleepLastNight => '어젯밤 잠을 설쳤나요?';

  @override
  String get aiCoachMealPostWorkoutMeal => '운동 후 식사?';

  @override
  String get aiCoachMealPreWorkoutFuel => '운동 전 에너지 보충?';

  @override
  String get aiCoachMealQuickSnackIdeas => '빠른 간식 아이디어?';

  @override
  String get aiCoachMealRecoveryDayEating => '회복일 식단?';

  @override
  String get aiCoachMealSomethingWentWrong => '문제가 발생했습니다.';

  @override
  String get aiCoachMealStressedWhatHelps => '스트레스를 받습니다. 무엇이 도움이 되나요?';

  @override
  String aiCoachMealSuggestionSheetAsianInspiredOnePick(
    Object budgetTail,
    Object meal,
  ) {
    return '아시아 스타일 $meal 메뉴 하나를 추천해 주세요. 매크로와 조리법 포함.$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetAsianInspiredThatS(Object meal) {
    return '고단백이면서 매크로 친화적인 아시아 스타일 $meal 메뉴를 추천해 주세요. 매크로 포함.';
  }

  @override
  String aiCoachMealSuggestionSheetBulkingCalorieDenseThat(Object meal) {
    return '벌크업 중이에요. 먹기 힘들지 않으면서 칼로리가 높은 $meal 메뉴를 추천해 주세요. 매크로 포함.';
  }

  @override
  String aiCoachMealSuggestionSheetComfortFoodCravingBut(Object meal) {
    return '익숙한 음식이 당기지만 식단을 유지하고 싶어요. 클래식한 메뉴를 건강하게 바꾼 $meal 아이디어를 주세요. 매크로 포함.';
  }

  @override
  String aiCoachMealSuggestionSheetCravingFastFoodFor(Object meal) {
    return '$meal로 패스트푸드가 당겨요. 유명 체인점에서 먹을 수 있는 현실적인 메뉴 하나를 추천해 주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetCravingMexicanPickThat(Object meal) {
    return '멕시칸 음식이 당겨요. 단순히 밥과 토르티야만 있는 게 아니라 매크로를 맞출 수 있는 $meal 메뉴를 추천해 주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetDropALowCal(Object meal) {
    return '매크로를 유지하면서 칼로리를 낮출 수 있는 $meal 대체 메뉴를 알려주세요. 매크로 포함해서요.';
  }

  @override
  String aiCoachMealSuggestionSheetFastingFriendlyIdeaThat(Object meal) {
    return '인슐린 수치를 크게 높이지 않는 간헐적 단식 친화적인 $meal 아이디어를 주세요. 메뉴 하나, 매크로, 이유 포함.';
  }

  @override
  String aiCoachMealSuggestionSheetFeelingAnxiousPickWith(Object meal) {
    return '불안해요. 마음을 진정시키는 영양소(마그네슘, 오메가-3 등)가 포함된 $meal 메뉴와 매크로, 그리고 이유를 알려주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetFeelingStressedAndReaching(Object meal) {
    return '스트레스를 받아서 음식을 찾게 돼요. 단순히 당분만 높은 게 아니라 마음을 진정시켜 줄 $meal 메뉴를 추천해 주세요. 매크로 포함.';
  }

  @override
  String aiCoachMealSuggestionSheetGotALaterToday(
    Object meal,
    Object workoutType,
  ) {
    return '오늘 나중에 $workoutType 예정이에요. 운동 전 에너지를 채울 수 있는 $meal 메뉴가 있을까요? 매크로와 타이밍 알려주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetHeadacheComingOnAny(Object meal) {
    return '두통이 오려고 해요. 도움이 될 만한 $meal이나 수분 섭취 방법이 있을까요? 음식과 관련이 없다면 건너뛰어 주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetHeartburnProneTodaySafe(Object meal) {
    return '오늘 속쓰림이 있어요. 안전한 $meal 메뉴와 먹어야 할 것, 피해야 할 것을 알려주세요. 매크로 포함.';
  }

  @override
  String aiCoachMealSuggestionSheetHighProteinPickOne(
    Object budgetTail,
    Object meal,
  ) {
    return '고단백 $meal 메뉴 하나를 추천해 주세요. 전체 매크로와 간단한 조리법 포함.$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetHowAmITracking(Object meal) {
    return '오늘 칼로리 목표 대비 어떻게 먹고 있나요? 부족하다면 어떤 $meal로 채울 수 있을까요?';
  }

  @override
  String aiCoachMealSuggestionSheetIMAngryAnd(Object meal) {
    return '화가 나서 폭식하고 싶어요. 매크로를 망치지 않으면서 기분을 가라앉힐 수 있는 $meal 메뉴를 짧고 현실적으로 알려주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetIMBloatedPick(Object meal) {
    return '배가 더부룩해요. 소화에 부담이 없는 $meal 메뉴와 오늘 피해야 할 음식을 알려주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetIMCuttingIdea(Object meal) {
    return '커팅 중이에요. 포만감이 높고 단백질 위주이면서 예산 내에서 가능한 $meal 아이디어를 주세요. 매크로 포함.';
  }

  @override
  String aiCoachMealSuggestionSheetIMHuntingFor(Object meal) {
    return '고단백 $meal 옵션을 찾고 있어요. 딱 하나만, 전체 매크로와 함께 왜 좋은지 알려주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetINeedMoreFiber(Object meal) {
    return '식이섬유가 더 필요해요. 탄수화물 과다 없이 식이섬유를 높일 수 있는 $meal 아이디어가 있을까요?';
  }

  @override
  String aiCoachMealSuggestionSheetIndianOneAuthenticPick(
    Object budgetTail,
    Object meal,
  ) {
    return '인도식 $meal 메뉴 하나를 추천해 주세요. 매크로와 함께 식단 유지를 위해 포함하거나 제외할 사이드 메뉴를 알려주세요.$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetItalianOrComfortOne(
    Object budgetTail,
    Object meal,
  ) {
    return '이탈리안 또는 익숙한 $meal 메뉴 하나를 추천해 주세요. 매크로와 더 가벼운 대체 옵션 포함.$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetJustFinishedMyRecovery(
    Object meal,
    Object workoutType,
  ) {
    return '$workoutType을 방금 마쳤어요. 이미 먹은 식단과 조화를 이루는 회복용 $meal 메뉴를 추천해 주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetKeepingSpendTightCheap(Object meal) {
    return '비용을 아끼면서 매크로가 좋은 $meal 아이디어를 주세요. 메뉴 하나, 대략적인 비용, 매크로 포함.';
  }

  @override
  String aiCoachMealSuggestionSheetLoggingMyHitMe(Object meal) {
    return '$meal 기록 중. 지금까지의 하루 식단에 맞는 메뉴를 추천해 주세요. 딱 하나만, 매크로 포함, 짧고 현실적으로요.';
  }

  @override
  String aiCoachMealSuggestionSheetLoggingMyHitMe2(
    Object budgetTail,
    Object meal,
  ) {
    return '$meal 기록 중. 하루 식단에 맞는 건강한 메뉴 하나를 추천해 주세요. 매크로 포함, 짧고 직접적으로요.$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetLowSugarPickThat(Object meal) {
    return '맛있으면서 당분이 낮은 $meal 메뉴를 추천해 주세요. 매크로와 낮은 당분인 이유도 함께요.';
  }

  @override
  String aiCoachMealSuggestionSheetMediterraneanOnePickBowl(
    Object budgetTail,
    Object meal,
  ) {
    return '지중해식 $meal 메뉴 하나를 추천해 주세요. 매크로와 좋은 이유 포함.$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetMediterraneanStyleMacrosWhat(Object meal) {
    return '지중해식 $meal 메뉴를 추천해 주세요. 매크로, 좋은 이유, 간단한 조리 팁 포함.';
  }

  @override
  String aiCoachMealSuggestionSheetMexicanOneRealPick(
    Object budgetTail,
    Object meal,
  ) {
    return '멕시칸 $meal 메뉴 하나를 추천해 주세요. 매크로와 함께 식단 유지를 위해 어떻게 구성해야 할지 알려주세요.$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetNoQuestionsMatch(Object _query) {
    return '\"$_query\"와 일치하는 질문이 없습니다.';
  }

  @override
  String aiCoachMealSuggestionSheetNoStoveNoOven(Object meal) {
    return '가스레인지나 오븐 없이 5분 안에 만들 수 있는 간단한 $meal 메뉴가 있을까요? 매크로도 알려주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetNoStoveNoOven2(
    Object budgetTail,
    Object meal,
  ) {
    return '가스레인지나 오븐 없이 5분 안에 만들 수 있는 $meal 메뉴 하나를 추천해 주세요. 매크로와 준비물 포함.$budgetTail';
  }

  @override
  String aiCoachMealSuggestionSheetOnMaintenanceGiveMe(Object meal) {
    return '유지기예요. 균형 잡힌 매크로로 안정적인 상태를 유지할 수 있는 $meal 메뉴를 추천해 주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetQuestions(Object length) {
    return '$length개의 질문';
  }

  @override
  String aiCoachMealSuggestionSheetRunningOnFumesPick(Object meal) {
    return '기운이 하나도 없어요. 에너지를 확실히 올려주면서 급격한 피로가 오지 않는 $meal 메뉴와 매크로를 알려주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetSleptBadWhatHelps(Object meal) {
    return '잠을 잘 못 잤어요. 에너지를 떨어뜨리지 않으면서 컨디션을 회복할 수 있는 $meal 메뉴가 있을까요?';
  }

  @override
  String aiCoachMealSuggestionSheetStomachSOffGentle(Object meal) {
    return '속이 안 좋아요. 부담 없이 먹을 수 있는 $meal 메뉴와 매크로를 알려주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetTodaySARecovery(Object meal) {
    return '오늘은 회복의 날이에요. $meal은 어떻게 구성해야 할까요? 매크로, 양, 훈련일과의 차이점 등을 알려주세요.';
  }

  @override
  String aiCoachMealSuggestionSheetVegetarianIdeaThatStill(Object meal) {
    return '단백질을 챙길 수 있는 채식 $meal 아이디어를 주세요. 메뉴 하나, 매크로, 조리 팁 포함.';
  }

  @override
  String get aiCoachMealTiredEnergyFood => '피곤하다 - 에너지 식품?';

  @override
  String get aiCoachMealUpsetStomachGentleMeal => '배탈 — 부드러운 식사?';

  @override
  String get aiCoachMealVegetarianPick => '채식주의자를 선택하나요?';

  @override
  String get aiCoachMealWhatAreYouFeeling => '기분이 어때요?';

  @override
  String get aiCoachMealWhatCanIEat => '이제 무엇을 먹을 수 있나요?';

  @override
  String get aiCoachMealWorkingFromPartialData =>
      '부분 데이터로 작업 - 대답은 일반적일 수 있습니다.';

  @override
  String get aiCoachMissedWorkoutNudge => '놓친 운동 넛지';

  @override
  String get aiCoachNudgeIntensity => '넛지 강도';

  @override
  String get aiCoachOff => '끄기';

  @override
  String get aiCoachOtherNotifications => '기타 알림';

  @override
  String aiCoachPageTapToChange(Object tagline) {
    return '$tagline · 탭하여 변경';
  }

  @override
  String get aiCoachPostWorkoutMeal => '운동 후 식사';

  @override
  String get aiCoachRefuelReminderAfterTraining => '운동 후 영양 보충 알림';

  @override
  String get aiCoachRemindByEveningIf => '건너뛸 경우 저녁에 알림';

  @override
  String aiCoachReportCardMin(Object unit) {
    return '$unit/분';
  }

  @override
  String aiCoachReportCardS(Object sets) {
    return '${sets}s';
  }

  @override
  String aiCoachReportCardSet(Object unit) {
    return '$unit/세트';
  }

  @override
  String get aiCoachReportGreatWorkoutKeepUp => '훌륭한 운동입니다! 계속해서 추진력을 유지하세요.';

  @override
  String get aiCoachReportMusclesWorked => '운동한 근육';

  @override
  String get aiCoachReportPr => 'PR';

  @override
  String get aiCoachReportPrs => 'PRs';

  @override
  String get aiCoachReportVolume => '볼륨';

  @override
  String get aiCoachReportVsLast => '지난번 대비';

  @override
  String get aiCoachShowFloatingBubbleFor => 'AI Coach 빠른 접속을 위한 플로팅 버블 표시';

  @override
  String get aiCoachShowFloatingChatBubble => '플로팅 채팅 버블, 알림 및 개인정보 보호 설정 표시';

  @override
  String get aiCoachStreakCelebrations => '연속 축하 행사';

  @override
  String get aiCoachTough => '힘든';

  @override
  String get aiDataUsageDataWeDoNot => '모델과 공유하지 않는 데이터';

  @override
  String get aiDataUsageEverythingNeededToCoach => '코칭에 필요한 모든 데이터';

  @override
  String get aiDataUsageHowDataIsProtected => '데이터가 보호되는 방법';

  @override
  String get aiDataUsageHowYourDataIs => '데이터 사용 방식';

  @override
  String aiDataUsageScreenSendsYourFitnessProfile(Object appName) {
    return '$appName은(는) 귀하의 피트니스 프로필, 채팅, 음식 사진, 운동 영상을 개인화된 가이드를 생성하는 모델로 전송합니다. 정확히 어떤 일이 일어나는지 확인하세요.';
  }

  @override
  String get aiDataUsageTechnicalSafeguardsInPlace => '기술적 보호 조치 적용됨';

  @override
  String get aiDataUsageWhatModelsReceive => '모델이 수신하는 정보';

  @override
  String get aiDataUsageWhatNeverLeavesOur => '우리 서버를 떠나지 않는 것';

  @override
  String get aiDataUsageYouAreInCharge => '데이터 관리 권한은 사용자에게 있습니다';

  @override
  String get aiDataUsageYourControls => '당신의 통제';

  @override
  String aiFeaturesMixinValue(
    Object displayCurrent,
    Object message,
    Object snappedDisplay,
    Object unit,
  ) {
    return '$message: $displayCurrent → $snappedDisplay $unit';
  }

  @override
  String get aiInputPreview => '×';

  @override
  String get aiInputPreviewBodyweight => '체중';

  @override
  String get aiInputPreviewDeselectAll => '전체 선택 해제';

  @override
  String get aiInputPreviewEditSet => '세트 편집';

  @override
  String get aiInputPreviewSelectAll => '전체 선택';

  @override
  String aiInputPreviewSheetEdit(Object name) {
    return '$name 편집';
  }

  @override
  String aiInputPreviewSheetFrom(Object originalInput) {
    return '출처: \"$originalInput\"';
  }

  @override
  String get aiInputPreviewWarmup => '웜업';

  @override
  String get aiIntegrationsAiIntegrations => 'AI 연동';

  @override
  String get aiIntegrationsConnectionReady => '연결 준비 완료!';

  @override
  String get aiIntegrationsCopied => '복사되었습니다!';

  @override
  String get aiIntegrationsCopyConfig => '설정 복사';

  @override
  String get aiIntegrationsCopyTokenOnly => '토큰만 복사';

  @override
  String get aiIntegrationsCouldNotCreateConnection => '연결을 생성할 수 없습니다.';

  @override
  String get aiIntegrationsCouldNotLoadIntegrations => '연동 항목을 불러올 수 없습니다';

  @override
  String get aiIntegrationsCreateConnection => '연결 생성';

  @override
  String get aiIntegrationsCustom => '사용자 지정';

  @override
  String get aiIntegrationsDisconnect => '연결 끊기';

  @override
  String get aiIntegrationsDisconnectThisAssistant => '이 어시스턴트를 연결 해제하시겠습니까?';

  @override
  String get aiIntegrationsDisconnecting => '연결 해제 중...';

  @override
  String get aiIntegrationsGenerate => '생성';

  @override
  String get aiIntegrationsGiveThisConnectionA => '먼저 이 연결에 이름을 지정하십시오.';

  @override
  String get aiIntegrationsGrantedPermissions => '권한 승인됨';

  @override
  String get aiIntegrationsIVeSavedMy => '내 구성을 저장했습니다 · 완료';

  @override
  String get aiIntegrationsMyLaptopClaude => '내 노트북 Claude';

  @override
  String get aiIntegrationsName => '이름';

  @override
  String get aiIntegrationsNoConnectionsYet => '아직 연결된 항목이 없습니다';

  @override
  String get aiIntegrationsOauth => 'OAuth';

  @override
  String get aiIntegrationsPasteThisConfigInto => '이 구성을 AI 클라이언트에 붙여넣으세요.';

  @override
  String get aiIntegrationsPermissions => '권한';

  @override
  String get aiIntegrationsQuickSetup => '빠른 설정';

  @override
  String aiIntegrationsScreenConnectAnywhere(Object appName) {
    return '$appName 어디서나 연결';
  }

  @override
  String aiIntegrationsScreenCouldNotDisconnect(Object name) {
    return '$name 연결을 해제할 수 없습니다.';
  }

  @override
  String aiIntegrationsScreenCreateAConnectionTo(Object appName) {
    return '$appName을(를) Claude, ChatGPT, Cursor에 연결하기 위한 연결 생성';
  }

  @override
  String aiIntegrationsScreenCreateOneToStart(Object appName) {
    return '연결을 생성하여 Claude, ChatGPT 또는 Cursor에서 $appName 사용을 시작하세요.';
  }

  @override
  String aiIntegrationsScreenDataYouCanCreate(Object appName) {
    return '$appName 데이터. 언제든지 새 연결을 생성할 수 있습니다.';
  }

  @override
  String aiIntegrationsScreenDisconnected(Object name) {
    return '$name 연결 해제됨';
  }

  @override
  String aiIntegrationsScreenReadAndModifyYour(Object appName) {
    return '범위 내에서 $appName 데이터를 읽고 수정';
  }

  @override
  String aiIntegrationsScreenWillImmediatelyLoseAccess(Object name) {
    return '$name에서 즉시 액세스 권한이 상실됩니다: ';
  }

  @override
  String get aiIntegrationsSetupGuide => '설정 가이드';

  @override
  String get aiIntegrationsTryAgain => '다시 시도';

  @override
  String get aiIntegrationsUncheckAnythingYouWant =>
      '이 연결에서 보류하려는 항목을 선택 취소하세요.';

  @override
  String get aiModelDownloadBasic => '기본';

  @override
  String get aiModelDownloadBatteryWarning =>
      '기기 내 AI 모델은 휴대폰에서 집중적인 연산을 수행합니다. 이로 인해 배터리 소모가 빨라지고 운동 생성 중 기기가 뜨거워질 수 있습니다. 더 큰 모델은 더 많은 리소스를 사용합니다.';

  @override
  String get aiModelDownloadBestQuality => '최고 품질';

  @override
  String get aiModelDownloadCancel => '취소';

  @override
  String get aiModelDownloadCapability => '능력';

  @override
  String get aiModelDownloadChecking => '확인 중...';

  @override
  String aiModelDownloadDeleteModelFree(Object size) {
    return '모델 삭제 (여유 공간 $size)';
  }

  @override
  String get aiModelDownloadDeviceCompatibility => '기기 호환성';

  @override
  String aiModelDownloadDownloadModel(Object modelName) {
    return '$modelName 다운로드';
  }

  @override
  String aiModelDownloadDownloadingProgress(Object percent) {
    return '다운로드 중... $percent%';
  }

  @override
  String get aiModelDownloadGetYourTokenAt =>
      'huggingface.co/settings/tokens에서 토큰을 받으세요';

  @override
  String get aiModelDownloadHf => 'HF_...';

  @override
  String get aiModelDownloadHuggingfaceToken => 'HuggingFace 토큰';

  @override
  String get aiModelDownloadHuggingfaceTokenRemoved =>
      'HuggingFace 토큰이 제거되었습니다';

  @override
  String get aiModelDownloadHuggingfaceTokenSaved => 'HuggingFace 토큰이 저장되었습니다';

  @override
  String get aiModelDownloadImages => '이미지';

  @override
  String get aiModelDownloadModelOptions => '모델 옵션';

  @override
  String get aiModelDownloadMultimodal => '멀티모달';

  @override
  String get aiModelDownloadNotCompatible => '호환되지 않음';

  @override
  String get aiModelDownloadNotSupportedOnThis => '이 기기에서는 지원되지 않습니다';

  @override
  String get aiModelDownloadOnDeviceAiModel => '온디바이스 AI 모델';

  @override
  String get aiModelDownloadOptimal => '최적';

  @override
  String get aiModelDownloadRam => 'RAM';

  @override
  String get aiModelDownloadRecommended => '권장';

  @override
  String get aiModelDownloadRemove => '제거하다';

  @override
  String get aiModelDownloadRequiredToDownload =>
      'HuggingFace에서 모델을 다운로드하려면 필요합니다. huggingface.co/settings/tokens에서 무료 토큰을 받으세요.';

  @override
  String aiModelDownloadRequiresRam(Object ramLabel) {
    return '$ramLabel RAM 필요';
  }

  @override
  String get aiModelDownloadSaveToken => '토큰 저장';

  @override
  String aiModelDownloadScreenGb(Object ram) {
    return '$ram GB';
  }

  @override
  String get aiModelDownloadSearch => '검색';

  @override
  String get aiModelDownloadSelectAModel => '모델 선택';

  @override
  String aiModelDownloadSizeStorage(Object size) {
    return '$size 저장 공간';
  }

  @override
  String get aiModelDownloadStandard => '표준';

  @override
  String get aiModelDownloadTokenSavedSecurely => '토큰이 안전하게 저장되었습니다';

  @override
  String get aiModelDownloadUnknown => '알 수 없음';

  @override
  String get aiModelsCheckingDeviceCapabilities => '기기 성능 확인 중...';

  @override
  String get aiModelsCouldNotDetectDevice => '기기 성능을 감지할 수 없습니다';

  @override
  String get aiModelsGetTokenAtHuggingface =>
      'Huggingface.co/settings/tokens에서 토큰을 받으세요.';

  @override
  String get aiModelsHf => 'hf_...';

  @override
  String get aiModelsHuggingfaceToken => 'HuggingFace 토큰';

  @override
  String get aiModelsManageGemmaModelsFor => '오프라인 운동 생성을 위한 Gemma 모델 관리';

  @override
  String get aiModelsModelLibrary => '모델 라이브러리';

  @override
  String get aiModelsNotSupportedOnThis => '이 기기에서는 지원되지 않습니다';

  @override
  String get aiModelsOnDeviceAiModels => '온디바이스 AI 모델';

  @override
  String get aiModelsRemove => '제거';

  @override
  String get aiModelsRequiredToDownloadGated =>
      'HuggingFace에서 제한 모델을 다운로드하는 데 필요합니다.';

  @override
  String get aiModelsSaveToken => '토큰 저장';

  @override
  String aiModelsSectionDeleteModelFree(Object downloadState) {
    return '모델 삭제 (무료 $downloadState)';
  }

  @override
  String aiModelsSectionDevice(Object displayName) {
    return '기기: $displayName';
  }

  @override
  String aiModelsSectionDownload(Object displayName) {
    return '$displayName 다운로드';
  }

  @override
  String aiModelsSectionGbRam(Object ram) {
    return '$ram GB RAM';
  }

  @override
  String aiModelsSectionGbRam2(Object minRamGB) {
    return '$minRamGB GB RAM';
  }

  @override
  String get aiModelsTokenSavedSecurely => '토큰이 안전하게 저장되었습니다';

  @override
  String get aiPrivacyContributeToWomenS => '여성 건강 연구에 기여하기';

  @override
  String get aiPrivacyControlHowYourData => '데이터 사용 방식 제어';

  @override
  String get aiPrivacyCouldnTUpdateConsent =>
      '동의 설정을 업데이트할 수 없습니다. 다시 시도해 주세요.';

  @override
  String get aiPrivacyHowYourDataIs => '데이터 사용 방식';

  @override
  String get aiPrivacyImportantHealthInformation => '중요한 건강 정보';

  @override
  String get aiPrivacyMedicalDisclaimer => '의료 면책 조항';

  @override
  String get aiPrivacyMessagesAreStoredSo => '코치가 맥락을 기억할 수 있도록 메시지가 저장됩니다';

  @override
  String get aiPrivacyPersonalization => '개인화';

  @override
  String get aiPrivacyPrivacyData => '개인정보 및 데이터';

  @override
  String get aiPrivacySaveChatHistory => '채팅 기록 저장';

  @override
  String get aiPrivacySeeWhatDataIs => '처리되는 데이터와 방식 확인';

  @override
  String get aiPrivacyYourCoachPersonalizesWorkou => '코치가 운동과 채팅을 개인화합니다';

  @override
  String get aiSettingsAdvancedSettings => '고급 설정';

  @override
  String get aiSettingsAiAgents => 'AI 에이전트';

  @override
  String get aiSettingsAiSettings => 'AI 설정';

  @override
  String get aiSettingsFitnessCoaching => '피트니스 코칭';

  @override
  String get aiSettingsFocusOn => '집중할 부분...';

  @override
  String get aiSettingsPersonalityTone => '성격과 톤';

  @override
  String get aiSettingsPickTheWeeklyStructure =>
      'AI가 계획해야 할 주간 구조를 선택하세요. 변경 사항은 다음 세대에 적용됩니다. 현재 주는 그대로 유지됩니다.';

  @override
  String get aiSettingsPrivacyData => '개인정보 및 데이터';

  @override
  String get aiSettingsRemove => '삭제';

  @override
  String get aiSettingsResponsePreferences => '응답 환경설정';

  @override
  String get aiSettingsScreenAddEmojisToAi => 'AI 응답에 이모지 추가';

  @override
  String aiSettingsScreenAddFocus(Object length) {
    return '집중 항목 추가 ($length/5)';
  }

  @override
  String get aiSettingsScreenAddHelpfulTipsIn => '응답에 유용한 팁 추가';

  @override
  String get aiSettingsScreenAiCoachDuringWorkouts => '운동 중 AI 코치';

  @override
  String get aiSettingsScreenAiCoachSettings => 'AI 코치 설정';

  @override
  String get aiSettingsScreenAiLearnsFromPast => 'AI가 과거 상호작용을 통해 학습 (RAG)';

  @override
  String get aiSettingsScreenAvailableAgents => '사용 가능한 에이전트';

  @override
  String get aiSettingsScreenChatHistoryCleared => '채팅 기록이 삭제되었습니다';

  @override
  String get aiSettingsScreenClear => '지우기';

  @override
  String get aiSettingsScreenClearChatHistory => '채팅 기록 지우기';

  @override
  String get aiSettingsScreenClearChatHistory2 => '채팅 기록을 지우시겠습니까?';

  @override
  String get aiSettingsScreenCoachName => '코치 이름';

  @override
  String get aiSettingsScreenCoachingStyle => '코칭 스타일';

  @override
  String get aiSettingsScreenCommunicationTone => '대화 톤';

  @override
  String get aiSettingsScreenConsiderYourInjuriesWhen => '조언 시 부상 고려';

  @override
  String get aiSettingsScreenCustomizeHowYourAi => 'AI 코치와의 상호작용 방식 맞춤 설정';

  @override
  String get aiSettingsScreenDefaultAgent => '기본 에이전트';

  @override
  String get aiSettingsScreenEnableOrDisableAgents =>
      '@멘션할 수 있는 상담원 활성화 또는 비활성화';

  @override
  String get aiSettingsScreenEncouragementLevel => '격려 수준';

  @override
  String get aiSettingsScreenFormReminders => '양식 알림';

  @override
  String get aiSettingsScreenGetRemindersAboutProper => '올바른 운동 자세 알림 받기';

  @override
  String get aiSettingsScreenGetSuggestionsForRest => '휴식 및 회복 제안 받기';

  @override
  String get aiSettingsScreenIncludeNutritionAdviceIn => '운동 관련 대화에 영양 조언 포함';

  @override
  String get aiSettingsScreenIncludeTips => '팁 포함';

  @override
  String get aiSettingsScreenInjurySensitivity => '부상 민감도';

  @override
  String get aiSettingsScreenMinimal => '최소화';

  @override
  String get aiSettingsScreenNutritionMentions => '영양 관련 언급';

  @override
  String aiSettingsScreenPartAIHeaderCardValue(Object name) {
    return '@$name';
  }

  @override
  String aiSettingsScreenPriorityOf(Object value) {
    return '5점 중 $value점 우선순위';
  }

  @override
  String get aiSettingsScreenRenameYourCoachPreset => '코치 이름 변경 — 프리셋은 유지됩니다';

  @override
  String get aiSettingsScreenResponseLength => '응답 길이';

  @override
  String get aiSettingsScreenRestDaySuggestions => '휴식일 제안';

  @override
  String get aiSettingsScreenSaveChatHistory => '채팅 기록 저장';

  @override
  String get aiSettingsScreenShowAiCoachAssistant => '운동 중 AI 코치 어시스턴트 표시';

  @override
  String get aiSettingsScreenStoreConversationsForContex => '맥락 파악을 위해 대화 저장';

  @override
  String get aiSettingsScreenThisAgentRespondsWhen =>
      '특정 에이전트를 @멘션하지 않을 때 응답하는 에이전트입니다';

  @override
  String get aiSettingsScreenThisWillDeleteAll => '모든 채팅 기록이 삭제됩니다';

  @override
  String get aiSettingsScreenThisWillPermanentlyDelete =>
      'AI 코치와의 모든 대화가 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get aiSettingsScreenUseEmojis => '이모지 사용';

  @override
  String get aiSettingsScreenUsePreviousConversations => '이전 대화 사용';

  @override
  String get aiSettingsShowAiAgentsFitness =>
      'AI 에이전트, 피트니스 코칭 토글 및 개인정보 보호 설정 표시';

  @override
  String get aiSettingsSuggestions => '제안';

  @override
  String get aiSettingsTellTheAiWhat =>
      '이번 블록에서 가장 중요한 목표를 AI에게 알려주세요. 최대 5개까지, 각각 1~5점으로 가중치를 설정하세요.';

  @override
  String get aiSettingsTrainingSplit => '트레이닝 분할';

  @override
  String get aiSettingsWhatToFocusOn => '집중할 목표';

  @override
  String get aiSettingsYourCoach => '나의 코치';

  @override
  String get aiSplitPresetBenefits => '장점';

  @override
  String aiSplitPresetDetailSheetDaysWeek(Object daysPerWeek) {
    return '주 $daysPerWeek일';
  }

  @override
  String aiSplitPresetDetailSheetFailedToUpdate(Object e) {
    return '업데이트 실패: $e';
  }

  @override
  String aiSplitPresetDetailSheetSwitchedToGeneratingNew(
    Object scheduleSuffix,
    Object splitDisplayName,
  ) {
    return '$splitDisplayName$scheduleSuffix(으)로 변경되었습니다. 새로운 운동을 생성 중입니다...';
  }

  @override
  String aiSplitPresetDetailSheetValue(Object hypertrophyScore) {
    return '$hypertrophyScore/10';
  }

  @override
  String get aiSplitPresetFlexible => '유연함';

  @override
  String get aiSplitPresetSchedule => '일정';

  @override
  String get aiSuggestionCardExercisesPreview => '운동 미리보기';

  @override
  String get aiSuggestionCoachIsReviewingYour => '코치가 식단을 검토 중입니다...';

  @override
  String aiSuggestionSectionSTip(Object name) {
    return '$name의 팁';
  }

  @override
  String aiSuggestionSectionTry(Object recommendedSwap) {
    return '추천: $recommendedSwap';
  }

  @override
  String get aiTextInputAddExercisesWithAi => 'AI로 운동 추가...';

  @override
  String get aiTextInputAddNewExercises => '➕ 새 운동 추가:';

  @override
  String get aiTextInputAiExerciseInput => 'AI 운동 입력';

  @override
  String get aiTextInputGotIt => '확인';

  @override
  String get aiTextInputLogSets1358 =>
      '세트 기록: 135*8, 145*6, +10...\n운동 추가: 3x10 데드리프트 135';

  @override
  String get aiTextInputLogSetsAddExercises => '세트 기록 / 운동 추가';

  @override
  String get aiTextInputLogSetsForCurrent => '📝 현재 운동 세트 기록:';

  @override
  String get aiTextInputOpenAiExerciseInput => 'AI 운동 입력 열기';

  @override
  String get aiTextInputPhotoOfWorkoutLog => '운동 기록, 화이트보드 또는 바벨 사진';

  @override
  String get aiTextInputSpeakNaturallyDid135 => '자연스럽게 말하기: \"135로 8회 했어\"';

  @override
  String get aiTextInputTapToAddExercises => '✦를 눌러 AI로 운동 추가';

  @override
  String get allSplitsTrainingSplits => '트레이닝 분할';

  @override
  String get appName => 'Zealova';

  @override
  String get appTourTooltipGotIt => '확인!';

  @override
  String get appTourTooltipSkipTutorial => '튜토리얼 건너뛰기';

  @override
  String get appearanceAppearance => '테마';

  @override
  String get appearanceSeriousMode => '진지 모드';

  @override
  String askCoachButtonAskCoachAbout(Object contextLabel) {
    return '$contextLabel에 대해 코치에게 물어보기';
  }

  @override
  String get audioCoachCardAudioSynthesisDisabledSho =>
      '음성 합성 비활성화됨 — 텍스트만 표시됩니다.';

  @override
  String get audioCoachCardTodaySCoachBrief => '오늘의 코치 브리핑';

  @override
  String get audioSettingsAudioDucking => '오디오 더킹';

  @override
  String get audioSettingsBackgroundMusic => '배경 음악';

  @override
  String get audioSettingsKeepSpotifyMusicPlaying => '운동 중 Spotify/음악 계속 재생';

  @override
  String get audioSettingsLowerMusicDuringVoice => '음성 안내 중 음악 소리 줄이기';

  @override
  String get audioSettingsMuteVoiceDuringVideos => '영상 재생 중 음성 끄기';

  @override
  String audioSettingsSectionValue(Object displayPct) {
    return '$displayPct%';
  }

  @override
  String get audioSettingsVoiceAnnouncements => '음성 안내';

  @override
  String get audioSettingsVoiceVolumeVideo => '음성 볼륨 및 영상';

  @override
  String get audioSettingsWorkoutAudio => '운동 오디오';

  @override
  String get authBuildMyPlan => '내 플랜 만들기';

  @override
  String get authContinueWithApple => 'Apple로 계속';

  @override
  String get authContinueWithEmail => '이메일로 계속';

  @override
  String get authContinueWithGoogle => 'Google로 계속';

  @override
  String get authEmailHint => '이메일';

  @override
  String get authIntroAiCoach => 'AI 코치';

  @override
  String get authIntroExercises => '운동';

  @override
  String get authIntroFoods => '음식';

  @override
  String get authPasswordHint => '비밀번호';

  @override
  String get authSignIn => '로그인';

  @override
  String get authSignUp => '회원가입';

  @override
  String get authWelcomeSubtitle => '당신의 AI 피트니스 코치';

  @override
  String get authWelcomeTitle => 'Zealova에 오신 것을 환영합니다';

  @override
  String get avoidedExercisesAddToAvoidList => '제외 목록에 추가';

  @override
  String get avoidedExercisesChangeExercise => '운동 변경';

  @override
  String get avoidedExercisesErrorLoadingExercises => '운동 목록을 불러오는 중 오류 발생';

  @override
  String get avoidedExercisesExercisesToAvoid => '제외할 운동';

  @override
  String get avoidedExercisesExercisesYouAddHere =>
      '여기에 추가한 운동은 AI가 생성하는 운동 계획에서 제외됩니다.';

  @override
  String get avoidedExercisesNoExercisesToAvoid => '제외할 운동 없음';

  @override
  String get avoidedExercisesPleaseLogIn => '로그인해주세요';

  @override
  String get avoidedExercisesReasonAndTemporarySettings =>
      '이유와 임시 설정은 모든 운동에 적용됩니다. 이후에 개별 항목을 수정할 수 있습니다.';

  @override
  String get avoidedExercisesReasonOptional => '이유 (선택 사항)';

  @override
  String get avoidedExercisesRemove => '제거';

  @override
  String get avoidedExercisesRemoveExercise => '운동 제거';

  @override
  String get avoidedExercisesSaveChanges => '변경 사항 저장';

  @override
  String avoidedExercisesScreenAddToAvoidList(Object count) {
    return '$count개를 제외 목록에 추가';
  }

  @override
  String avoidedExercisesScreenAvoid(Object exerciseName) {
    return '\"$exerciseName\" 제외';
  }

  @override
  String avoidedExercisesScreenAvoidExercises(Object count) {
    return '$count개 운동 제외';
  }

  @override
  String get avoidedExercisesScreenBrowseTheExerciseLibrary =>
      '운동 라이브러리에서 옵션 찾아보기';

  @override
  String avoidedExercisesScreenEdit(Object exerciseName) {
    return '\"$exerciseName\" 편집';
  }

  @override
  String get avoidedExercisesScreenErrorLoadingAlternatives =>
      '대체 운동을 불러오는 중 오류가 발생했습니다';

  @override
  String get avoidedExercisesScreenNoSpecificAlternativesFound =>
      '구체적인 대체 운동을 찾을 수 없습니다';

  @override
  String avoidedExercisesScreenPartAvoidedExerciseCardInsteadOf(
    Object exerciseName,
  ) {
    return '$exerciseName 대신';
  }

  @override
  String avoidedExercisesScreenPartAvoidedExerciseCardUntil(
    Object day,
    Object month,
    Object year,
  ) {
    return '$year년 $month월 $day일까지';
  }

  @override
  String avoidedExercisesScreenRemoveFromAvoidList(Object exerciseName) {
    return '\"$exerciseName\"을(를) 제외 목록에서 삭제할까요?';
  }

  @override
  String avoidedExercisesScreenRemoved(Object exerciseName) {
    return '\"$exerciseName\" 삭제됨';
  }

  @override
  String avoidedExercisesScreenReplacedInUpcomingWorkouts(Object exerciseName) {
    return '예정된 운동에서 \"$exerciseName\"을(를) 대체했습니다';
  }

  @override
  String get avoidedExercisesScreenSafe => '안전';

  @override
  String get avoidedExercisesScreenSafeAlternatives => '안전한 대체 운동';

  @override
  String avoidedExercisesScreenUntil(Object day, Object month, Object year) {
    return '$year년 $month월 $day일까지';
  }

  @override
  String avoidedExercisesScreenUntil2(Object day, Object month, Object year) {
    return '$year년 $month월 $day일까지';
  }

  @override
  String avoidedExercisesScreenUntil3(Object day, Object month, Object year) {
    return '$year년 $month월 $day일까지';
  }

  @override
  String avoidedExercisesScreenUpdated(Object exerciseName) {
    return '\"$exerciseName\" 업데이트됨';
  }

  @override
  String get avoidedExercisesScreenViewSafeAlternatives => '안전한 대체 운동 보기';

  @override
  String get avoidedExercisesSetAnEndDate => '이 제한 사항에 대한 종료 날짜 설정';

  @override
  String get avoidedExercisesSetAnEndDate2 => '이 제한 사항에 대한 종료 날짜 설정';

  @override
  String get avoidedExercisesTapToAddExercises => '+를 눌러 제외할 운동을 추가하세요';

  @override
  String get avoidedExercisesTemporary => '임시';

  @override
  String get avoidedMusclesAvoid => '제외';

  @override
  String get avoidedMusclesCurrentlyAvoided => '현재 제외됨';

  @override
  String get avoidedMusclesErrorLoadingMuscles => '근육 정보를 불러오는 중 오류가 발생했습니다';

  @override
  String get avoidedMusclesExercisesTargetingThisMuscl =>
      '이 근육을 타겟으로 하는 운동은 완전히 제외됩니다';

  @override
  String get avoidedMusclesMusclesToAvoid => '제외할 근육';

  @override
  String get avoidedMusclesPleaseLogIn => '로그인해주세요';

  @override
  String get avoidedMusclesReduce => '줄이기';

  @override
  String get avoidedMusclesRemove => '제거';

  @override
  String get avoidedMusclesRemoveFromAvoidList => '제외 목록에서 제거';

  @override
  String get avoidedMusclesReplacedExercisesTargetingT =>
      '다가오는 운동에서 이 근육을 타겟으로 하는 운동이 대체되었습니다';

  @override
  String get avoidedMusclesSaveChanges => '변경 사항 저장';

  @override
  String avoidedMusclesScreenReason(Object reason) {
    return '이유: $reason';
  }

  @override
  String avoidedMusclesScreenRemove(Object displayName) {
    return '\"$displayName\"을(를) 제거할까요?';
  }

  @override
  String avoidedMusclesScreenRemoved(Object displayName) {
    return '\"$displayName\" 제거됨';
  }

  @override
  String avoidedMusclesScreenReplacedExercisesTargetingMuscles(Object count) {
    return '다가오는 운동에서 $count개 근육을 타겟팅하는 운동이 교체되었습니다';
  }

  @override
  String get avoidedMusclesSelectMusclesToAvoid => '운동에서 제외하거나 줄일 근육을 선택하세요';

  @override
  String get avoidedMusclesSeverity => '강도';

  @override
  String get badgeHubAllAvailableBadges => '모든 사용 가능한 배지';

  @override
  String get badgeHubBadges => '배지';

  @override
  String get badgeHubChallenges => '챌린지';

  @override
  String get badgeHubHeroEarnBadgesForEvery =>
      '모든 이정표, 연속 기록, PB에 대해 배지를 획득하세요.';

  @override
  String get badgeHubHeroHowItWorks => '작동 방식';

  @override
  String get badgeHubHeroRewardYourProgress => '진행 상황 보상';

  @override
  String get badgeHubInProgress => '진행 중';

  @override
  String get badgeHubInProgress2 => '진행 중';

  @override
  String get badgeHubLevelledBadgesThatKeep =>
      '더 많은 걸음 수, 칼로리, 세션 또는 거리를 기록할수록 계속 올라가는 레벨 배지입니다.';

  @override
  String get badgeHubMasteries => '마스터리';

  @override
  String get badgeHubMasteries2 => '마스터리';

  @override
  String get badgeHubMyBadges => '내 배지';

  @override
  String get badgeHubOneTimeTrophiesFor =>
      '시간 목표, 꾸준함, 큰 PR 등 이정표 달성을 위한 일회성 트로피입니다.';

  @override
  String get badgeHubPersonalBests => '개인 최고 기록';

  @override
  String get badgeHubPersonalBests2 => '개인 최고 기록';

  @override
  String get badgeHubRewardYourProgress => '진행 상황 보상';

  @override
  String badgeHubScreenTotal(Object count) {
    return '총 $count개';
  }

  @override
  String get badgeHubWeeklyOrDailyChallenges =>
      '매주 또는 매일 도전할 수 있는 챌린지입니다. 일정에 따라 초기화되므로 언제든 다시 획득할 수 있습니다.';

  @override
  String get badgeHubYourHighestLiftsLongest =>
      '최고 중량, 최장 세션, 최대 운동량입니다. 기록을 경신하여 메달을 업그레이드하세요.';

  @override
  String get barcodeScannerOverlayPointYourCameraAt => '제품 바코드에 카메라를 비추세요';

  @override
  String get barcodeScannerOverlayScanABarcode => '바코드 스캔';

  @override
  String get batchPortioningBatchPortioning => '일괄 분할';

  @override
  String get batchPortioningCalculateNutritionPerPortio => '1인분당 영양 성분 계산';

  @override
  String get batchPortioningCalories => '칼로리';

  @override
  String get batchPortioningCarbsG => '탄수화물 (g)';

  @override
  String get batchPortioningFatG => '지방 (g)';

  @override
  String get batchPortioningHowManyServings => '몇 인분인가요?';

  @override
  String get batchPortioningHowMuchDidYou => '얼마나 드셨나요?';

  @override
  String get batchPortioningLogThisPortion => '이 분량 기록하기';

  @override
  String get batchPortioningPerServing => '1인분당';

  @override
  String get batchPortioningProteinG => '단백질 (g)';

  @override
  String get batchPortioningRecipeMealName => '레시피/식사 이름';

  @override
  String get batchPortioningThisMakes => '총 분량';

  @override
  String get batchPortioningTotalBatchNutrition => '전체 배치 영양 성분';

  @override
  String get beastHeaderCardBeastMode => 'BEAST MODE';

  @override
  String get beastHeaderCardPowerUserToolkit => '파워 유저 툴킷';

  @override
  String get beastModeAboutBeastMode => 'Beast Mode 정보';

  @override
  String get beastModeAboutBeastModeSubtitle => '빌드 정보 및 제어';

  @override
  String get beastModeAlgorithmInspector => '알고리즘 검사기';

  @override
  String get beastModeAlgorithmInspectorSubtitle => '운동 뒤에 숨겨진 수학적 원리 확인';

  @override
  String get beastModeBeastMode => 'Beast Mode';

  @override
  String get beastModeCustomizationLab => '커스터마이징 랩';

  @override
  String get beastModeCustomizationLabSubtitle => '고급 색상 및 글꼴 제어';

  @override
  String get beastModeDataAndSyncTools => '데이터 및 동기화 도구';

  @override
  String get beastModeDataAndSyncToolsSubtitle => '동기화 문제 디버깅 및 데이터 관리';

  @override
  String get beastModePremium => '프리미엄';

  @override
  String get beastModeRecoveryAndProgression => '회복 및 진행 상황';

  @override
  String get beastModeRecoveryAndProgressionSubtitle => '신체 회복 시각화 및 성장 예측';

  @override
  String get beastModeUnlockBeastMode => 'BEAST MODE';

  @override
  String get beastModeUnlockLetSGo => '시작하기';

  @override
  String get beastModeUnlockUnlocked => '잠금 해제됨';

  @override
  String get beastModeUnlockYouVeUnlockedThe =>
      '파워 유저 툴킷이 잠금 해제되었습니다. 운동 뒤에 숨겨진 알고리즘을 확인해보세요.';

  @override
  String get beastModeWorkoutAlgorithm => '운동 알고리즘';

  @override
  String get beastModeWorkoutAlgorithmSubtitle => '운동 생성에 대한 심층 제어';

  @override
  String get beastModeWorkoutTemplates => '운동 템플릿';

  @override
  String get beastModeWorkoutTemplatesSubtitle => '맞춤형 운동 구조 프리셋';

  @override
  String get bleHeartRateAutoConnectOnWorkout => '운동 시작 시 자동 연결';

  @override
  String get bleHeartRateConnect => '연결';

  @override
  String get bleHeartRateDisconnect => '연결 해제';

  @override
  String get bleHeartRateForgetDevice => '기기 지우기';

  @override
  String get bleHeartRateHeartRateMonitor => '심박수 모니터';

  @override
  String get bleHeartRateHeartRateMonitor2 => '심박수 모니터';

  @override
  String get bleHeartRateNoDevicesFound => '기기를 찾을 수 없습니다';

  @override
  String get bleHeartRateRescan => '다시 검색';

  @override
  String get bleHeartRateScanForHrMonitors => '심박수 모니터 검색';

  @override
  String get bleHeartRateSearchingForDevices => '기기 검색 중...';

  @override
  String bleHeartRateSectionDbm(Object rssi) {
    return '$rssi dBm';
  }

  @override
  String get bleHeartRateTryAgain => '다시 시도';

  @override
  String bodyAgeBadgeBodyAge(Object bodyAge) {
    return '신체 나이 $bodyAge';
  }

  @override
  String get bodyAgeBadgeMatchesYourAge => '나이와 일치함';

  @override
  String bodyAgeBadgeYrVsActual(Object delta, Object sign) {
    return '실제 나이 대비 $sign$delta세';
  }

  @override
  String get bodyAnalyzerBodyAnalyzer => '신체 분석기';

  @override
  String get bodyAnalyzerBodyFat => '체지방';

  @override
  String get bodyAnalyzerCaptureAlsoEstimateTapeMeasurement =>
      '사진에서 줄자 측정값도 추정';

  @override
  String get bodyAnalyzerCaptureAnalyzing => '분석 중…';

  @override
  String get bodyAnalyzerCaptureFusesHeightWeightBody =>
      '키, 체중, 체지방 및 줄자 측정값을 분석에 통합합니다.';

  @override
  String get bodyAnalyzerCapturePickAtLeastOne => '사진을 하나 이상 선택하세요.';

  @override
  String get bodyAnalyzerCapturePickPhotos => '사진 선택';

  @override
  String bodyAnalyzerCaptureScreenNoPhotosYetCapture(Object label) {
    return '$label 사진이 아직 없습니다. 진행 상황에서 하나를 촬영하세요.';
  }

  @override
  String get bodyAnalyzerCaptureUseMyStoredMeasurements => '저장된 측정값 사용';

  @override
  String get bodyAnalyzerCreatingProposal => '제안 생성 중…';

  @override
  String get bodyAnalyzerGetYourBodyAnalyzer => 'Body Analyzer 피드백 받기';

  @override
  String get bodyAnalyzerHeroOverallRating => '종합 평가';

  @override
  String get bodyAnalyzerMuscleMass => '근육량';

  @override
  String get bodyAnalyzerNewAnalysis => '새로운 분석';

  @override
  String get bodyAnalyzerPersonalizedTips => '맞춤형 팁';

  @override
  String bodyAnalyzerScreenCorrectiveExercisesQueuedFor(Object length) {
    return '다음 프로그램을 위한 교정 운동 $length개가 대기 중입니다.';
  }

  @override
  String bodyAnalyzerScreenCouldnTLoadBody(Object _error) {
    return 'Body Analyzer를 불러올 수 없습니다: $_error';
  }

  @override
  String get bodyAnalyzerStartAnalysis => '분석 시작';

  @override
  String get bodyAnalyzerSymmetry => '대칭성';

  @override
  String bodyHydrationAnimationValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String get bodyMetricsBodyMetricsScore => '신체 지표 및 점수';

  @override
  String get bodyMetricsConsistency => '일관성';

  @override
  String get bodyMetricsFitnessScore => '피트니스 점수';

  @override
  String get bodyMetricsStrength => '근력';

  @override
  String get bodyMuscleSelectorLoadingBodyDiagram => '신체 다이어그램 불러오는 중...';

  @override
  String get bodyMuscleSelectorTapOnAMuscle => '근육을 탭하여 선택 • 핀치로 확대';

  @override
  String get bodyPartSelectorSelectBodyPart => '신체 부위 선택';

  @override
  String get bodyPartSelectorTapTheAffectedArea => '영향을 받는 부위를 탭하세요';

  @override
  String get bodyScoreOverlayLoadingBodyDiagram => '신체 다이어그램 불러오는 중...';

  @override
  String breathPromptWidgetStartsInS(Object _sessionSecondsLeft) {
    return '$_sessionSecondsLeft초 후 시작';
  }

  @override
  String get breathingGuideBreathingGuide => '호흡 가이드';

  @override
  String get breathingGuideExhale => '내쉬기';

  @override
  String get breathingGuideInhale => '들이마시기';

  @override
  String buddyWorkoutBarSets(Object _partnerSetsLogged) {
    return '$_partnerSetsLogged세트';
  }

  @override
  String get buttonCancel => '취소';

  @override
  String get buttonContinue => '계속';

  @override
  String get buttonDelete => '삭제';

  @override
  String get buttonRetry => '다시 시도';

  @override
  String get buttonSave => '저장';

  @override
  String get buttonStart => '시작';

  @override
  String get calendarIconButtonSchedule => '일정';

  @override
  String get caloriesBurnedAllFromBackgroundActivity => '모두 배경 활동에서 발생';

  @override
  String get caloriesBurnedCaloriesBurnedToday => '오늘 소모한 칼로리';

  @override
  String get caloriesBurnedCompleteAWorkoutOr => '운동을 완료하거나 건강 앱에서 동기화하세요';

  @override
  String get caloriesBurnedInApp => '앱 내';

  @override
  String get caloriesBurnedNoActivityRecordedToday => '오늘 기록된 활동 없음';

  @override
  String get caloriesBurnedPassive => '수동';

  @override
  String get caloriesBurnedSauna => '사우나';

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
    return '$durationMinutes 분';
  }

  @override
  String caloriesBurnedSheetWorkouts(Object appName) {
    return '$appName 운동';
  }

  @override
  String get caloriesBurnedStepsHeartRateAnd => '걸음 수, 심박수 및 하루 종일 움직임';

  @override
  String get caloriesBurnedSynced => '동기화됨';

  @override
  String get caloriesBurnedSyncedFromHealth => '건강 앱에서 동기화됨';

  @override
  String get caloriesBurnedTodaySActivity => '오늘의 활동';

  @override
  String caloriesSummaryCardCalPhase(Object delta, Object phase) {
    return '+$delta cal · $phase 단계';
  }

  @override
  String get caloriesSummaryCardCalories => '칼로리';

  @override
  String caloriesSummaryCardKcal(Object calorieTarget, Object consumed) {
    return '$consumed / $calorieTarget kcal';
  }

  @override
  String get cancelConfirmationAnythingElseYouD =>
      '공유하고 싶은 다른 의견이 있으신가요? (선택 사항)';

  @override
  String get cancelConfirmationCancelAnyway => '그래도 취소';

  @override
  String get cancelConfirmationHelpUsImprove => '개선에 도움을 주세요';

  @override
  String get cancelConfirmationKeepMySubscription => '구독 유지';

  @override
  String get cancelConfirmationNeedABreakInstead => '잠시 휴식이 필요하신가요?';

  @override
  String get cancelConfirmationNeverMindKeepMy => '아니요, 구독을 유지할게요';

  @override
  String get cancelConfirmationPauseForUpTo => '최대 3개월 일시 중지';

  @override
  String cancelConfirmationSheetAppliedSuccessfully(Object name) {
    return '$name 적용 완료!';
  }

  @override
  String cancelConfirmationSheetCancel(Object planName) {
    return '$planName 구독을 취소할까요?';
  }

  @override
  String cancelConfirmationSheetFailedToApplyOffer(Object e) {
    return '제안 적용 실패: $e';
  }

  @override
  String get cancelConfirmationSpecialOffersJustFor => '회원님을 위한 특별 혜택';

  @override
  String get cancelConfirmationWeDHateTo => '떠나신다니 아쉬워요';

  @override
  String get cancelConfirmationWhatYouLlLose => '잃게 될 혜택';

  @override
  String get cancelConfirmationWhyAreYouThinking => '취소하려는 이유가 무엇인가요?';

  @override
  String get capabilityAndCommunityAiCoachAvailability => 'AI 코치 이용 가능';

  @override
  String get capabilityAndCommunityAiUpdatedContinuously => '지속적으로 업데이트되는 AI';

  @override
  String get capabilityAndCommunityBuiltRight => '제대로 만들어졌습니다.';

  @override
  String get capabilityAndCommunityDiscord => 'Discord';

  @override
  String get capabilityAndCommunityExercisesWithHdVideo => 'HD 영상이 포함된 운동';

  @override
  String get capabilityAndCommunityFoodsInOurDatabase => '데이터베이스에 포함된 음식';

  @override
  String get capabilityAndCommunityInstagram => 'Instagram';

  @override
  String get capabilityAndCommunityReachUsAnytime => '언제든 문의하세요';

  @override
  String get capabilityAndCommunityRealNumbersRealPeople =>
      '실제 수치. 그 뒤에 있는 실제 사람들.';

  @override
  String get cardioHistoryAll => '전체';

  @override
  String get cardioHistoryAllTime => '전체 기간';

  @override
  String get cardioHistoryAvgHr => '평균 심박수';

  @override
  String get cardioHistoryAvgPace => '평균 페이스';

  @override
  String get cardioHistoryAvgSpeed => '평균 속도';

  @override
  String get cardioHistoryAvgWatts => '평균 와트';

  @override
  String get cardioHistoryCalories => '칼로리';

  @override
  String get cardioHistoryCardioHistory => '유산소 운동 기록';

  @override
  String get cardioHistoryClearDateFilter => '날짜 필터 지우기';

  @override
  String get cardioHistoryCouldNotLoadCardio => '유산소 운동 기록을 불러올 수 없습니다';

  @override
  String get cardioHistoryCycle => '사이클';

  @override
  String get cardioHistoryDateRange => '날짜 범위';

  @override
  String get cardioHistoryDistance => '거리';

  @override
  String get cardioHistoryDuration => '시간';

  @override
  String get cardioHistoryElevation => '고도';

  @override
  String get cardioHistoryHiit => 'HIIT';

  @override
  String get cardioHistoryHike => '하이킹';

  @override
  String get cardioHistoryImportFromStravaPeloton =>
      'Strava, Peloton, Garmin, Apple Health 또는 Fitbit에서 가져와 기록을 확인하세요.';

  @override
  String get cardioHistoryIndoorCycle => '실내 사이클';

  @override
  String get cardioHistoryMaxHr => '최대 심박수';

  @override
  String cardioHistoryNActivities(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '활동 $count개',
      one: '활동 1개',
    );
    return '$_temp0';
  }

  @override
  String cardioHistoryNSessions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '세션 $count개',
      one: '세션 1개',
    );
    return '$_temp0';
  }

  @override
  String get cardioHistoryNoCardioSessionsYet => '아직 유산소 운동 세션이 없습니다.';

  @override
  String get cardioHistoryNoSessionsMatchThis => '이 필터와 일치하는 세션이 없습니다.';

  @override
  String get cardioHistoryNotes => '메모';

  @override
  String get cardioHistoryPleaseSignInTo => '유산소 운동 기록을 보려면 로그인하세요.';

  @override
  String cardioHistoryRouteRecordedPts(Object count) {
    return '경로 기록됨 ($count개 지점)';
  }

  @override
  String get cardioHistoryRow => '로잉';

  @override
  String get cardioHistoryRpe => 'RPE';

  @override
  String get cardioHistoryRun => '달리기';

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
    return '$calories cal';
  }

  @override
  String cardioHistoryScreenM(Object log) {
    return '$log m';
  }

  @override
  String cardioHistoryScreenW(Object avgWatts) {
    return '$avgWatts W';
  }

  @override
  String get cardioHistorySessions => '세션';

  @override
  String get cardioHistorySplits => '구간 기록';

  @override
  String get cardioHistorySwim => '수영';

  @override
  String get cardioHistoryThisWeek => '이번 주';

  @override
  String get cardioHistoryTryClearingFiltersOr => '필터를 지우거나 날짜 범위를 넓혀보세요.';

  @override
  String get cardioHistoryWalk => '걷기';

  @override
  String get cardioHistoryYoga => '요가';

  @override
  String get cardioPrHistoryAllTimeBestsBy => '종목별 역대 최고 기록';

  @override
  String get cardioPrHistoryCardioPrs => '유산소 PR';

  @override
  String get cardioPrHistoryCouldNotLoadTrend => '트렌드를 불러올 수 없습니다';

  @override
  String get cardioPrHistoryFirstTime => '첫 기록입니다!';

  @override
  String get cardioPrHistoryLogACardioSession => '유산소 세션을 기록하여 PR 추적을 시작하세요.';

  @override
  String get cardioPrHistoryNoCardioPrsYet => '아직 유산소 PR이 없습니다';

  @override
  String get cardioPrHistoryNoHistoryYet => '아직 기록이 없습니다.';

  @override
  String cardioPrHistorySheetCouldNotLoadCardio(Object err) {
    return '유산소 PR을 불러올 수 없습니다: $err';
  }

  @override
  String get categoryExercisesLoadMore => '더 보기';

  @override
  String get categoryExercisesNoExercisesFound => '운동을 찾을 수 없습니다';

  @override
  String get categoryFilterChipsAll => '전체';

  @override
  String get chainDetailLoading => '불러오는 중...';

  @override
  String get chainDetailProgressionPath => '진행 경로';

  @override
  String get chainDetailProgressionStartedGoodLuck => '진행이 시작되었습니다! 행운을 빕니다!';

  @override
  String chainDetailScreenAttemptsAtCurrentStep(Object attemptsAtCurrent) {
    return '현재 단계 시도 횟수: $attemptsAtCurrent회';
  }

  @override
  String chainDetailScreenBestReps(Object bestRepsAtCurrent) {
    return '최고 기록: $bestRepsAtCurrent회';
  }

  @override
  String chainDetailScreenStep(Object difficultyLabel, Object stepOrder) {
    return '$stepOrder단계 - $difficultyLabel';
  }

  @override
  String chainDetailScreenSteps(Object length) {
    return '$length 걸음';
  }

  @override
  String get chainDetailStartThisProgression => '이 진행 시작하기';

  @override
  String get chainDetailYourProgress => '나의 진행 상황';

  @override
  String get challengeCardAcceptChallenge => '챌린지 수락';

  @override
  String get challengeCardActive => '진행 중';

  @override
  String get challengeCardChallengedYouToBeat => '님이 기록 도전을 요청했습니다';

  @override
  String challengeCardDaysLeft(Object daysRemaining) {
    return '$daysRemaining일 남음';
  }

  @override
  String get challengeCardDecline => '거절';

  @override
  String get challengeCardExpired => '만료됨';

  @override
  String challengeCardParticipating(Object participantCount) {
    return '$participantCount명 참여 중';
  }

  @override
  String get challengeCardYouChallengedToBeat => '도전 과제:';

  @override
  String get challengeCompareChallengeResults => '챌린지 결과';

  @override
  String get challengeCompareFailedToLoadChallenge => '챌린지를 불러오지 못했습니다';

  @override
  String get challengeCompareRematch => '재대결';

  @override
  String get challengeCompareRematchSent => '재대결 요청을 보냈습니다!';

  @override
  String get challengeCompareReps => '횟수';

  @override
  String challengeCompareScreenFailedToSendRematch(Object e) {
    return '재대결 요청 실패: $e';
  }

  @override
  String challengeCompareScreenMin(Object v) {
    return '$v분';
  }

  @override
  String get challengeCompareSets => '세트';

  @override
  String get challengeCompareTime => '시간';

  @override
  String get challengeCompareViewFeed => '피드 보기';

  @override
  String get challengeCompareVolume => '볼륨';

  @override
  String get challengeCompareWinner => '승자';

  @override
  String get challengeCompleteChallengeAttempted => '챌린지 완료';

  @override
  String get challengeCompleteContinue => '계속';

  @override
  String challengeCompleteDialogLbs(Object theirVolume) {
    return '$theirVolume lbs';
  }

  @override
  String challengeCompleteDialogMin(Object yourDuration) {
    return '$yourDuration분';
  }

  @override
  String challengeCompleteDialogMin2(Object theirDuration) {
    return '$theirDuration분';
  }

  @override
  String get challengeCompletePerformanceComparison => '성과 비교';

  @override
  String get challengeCompleteThem => '상대: ';

  @override
  String get challengeCompleteTime => '시간';

  @override
  String get challengeCompleteVictory => '승리!';

  @override
  String get challengeCompleteViewFullComparison => '전체 비교 보기';

  @override
  String get challengeCompleteViewInFeed => '피드에서 보기';

  @override
  String get challengeCompleteVolume => '볼륨';

  @override
  String get challengeCompleteYou => '나: ';

  @override
  String get challengeCompleteYourVictoryHasBeen => '승리 소식이 친구들에게 공유되었습니다! 🎉';

  @override
  String get challengeCreateAnyoneCanJoinVia => '소셜 탭을 통해 누구나 참여할 수 있습니다';

  @override
  String get challengeCreateButton => '챌린지 만들기';

  @override
  String get challengeCreateDescriptionOptional => '설명 (선택 사항)';

  @override
  String get challengeCreateEG100Chest => '예: 이번 주 가슴 운동 100세트';

  @override
  String get challengeCreateFieldEnds => '종료';

  @override
  String get challengeCreateFieldGoal => '목표';

  @override
  String get challengeCreateFieldTitle => '제목';

  @override
  String get challengeCreateInviteFriends => '친구 초대';

  @override
  String get challengeCreateTitle => '챌린지 만들기';

  @override
  String get challengeFriendsAddTrashTalkMessage => '도발 메시지 추가 (선택 사항) 💪';

  @override
  String get challengeFriendsChallengeFriends => '친구 도전하기';

  @override
  String challengeFriendsDialogChallengeSentToFriend(Object length) {
    return '🏆 $length명의 친구에게 챌린지를 보냈습니다!';
  }

  @override
  String challengeFriendsDialogFailedToSendChallenges(Object e) {
    return '챌린지 전송 실패: $e';
  }

  @override
  String challengeFriendsDialogSendChallenge(Object length) {
    return '챌린지 보내기 ($length)';
  }

  @override
  String get challengeFriendsNoFriendsToChallenge => '도전할 친구가 없습니다';

  @override
  String get challengeFriendsPleaseSelectAtLeast => '최소 한 명의 친구를 선택하세요';

  @override
  String get challengeFriendsSearchFriends => '친구 검색...';

  @override
  String get challengeFriendsSending => '보내는 중...';

  @override
  String get challengeFriendsStatsToBeat => '도전할 기록:';

  @override
  String get challengeHistoryAll => '전체';

  @override
  String get challengeHistoryChallengeHistory => '챌린지 기록';

  @override
  String get challengeHistoryChallengeStats => '챌린지 통계';

  @override
  String get challengeHistoryFailedToLoadChallenges => '챌린지를 불러오지 못했습니다';

  @override
  String get challengeHistoryLetSGo => '시작하자! 💪';

  @override
  String get challengeHistoryLost => '패배';

  @override
  String get challengeHistoryNotNow => '나중에';

  @override
  String get challengeHistoryPending => '대기 중';

  @override
  String get challengeHistoryQuit => '포기';

  @override
  String get challengeHistoryRetryChallenge => '챌린지 재도전';

  @override
  String get challengeHistoryRetryChallenge2 => '챌린지 재도전?';

  @override
  String get challengeHistoryRetryChallengeSentTime =>
      '🔥 재도전 요청을 보냈습니다! 설욕할 시간입니다!';

  @override
  String challengeHistoryScreenFailedToSendRetry(Object e) {
    return '재시도 전송 실패: $e';
  }

  @override
  String get challengeHistoryTarget => '목표: ';

  @override
  String get challengeHistoryThem => '상대';

  @override
  String get challengeHistoryUnknownError => '알 수 없는 오류';

  @override
  String get challengeHistoryWon => '승리';

  @override
  String get challengeHistoryYou => '나: ';

  @override
  String get challengePublicToggle => '공개';

  @override
  String get challengesBeTheFirstTo => '가장 먼저 챌린지를 만들어보세요!';

  @override
  String get challengesChallenge => '챌린지';

  @override
  String get challengesCouldNotLoadChallenges => '챌린지를 불러올 수 없습니다.\n다시 시도해주세요.';

  @override
  String get challengesCouldNotLoadYour => '내 챌린지를 불러올 수 없습니다.\n다시 시도해주세요.';

  @override
  String get challengesCreateChallenge => '챌린지 만들기';

  @override
  String get challengesFailedToLoadChallenges => '챌린지 불러오기 실패';

  @override
  String get challengesJoinAChallengeTo =>
      '챌린지에 참여하여 친구들과 경쟁하고\n피트니스 목표를 달성하세요!';

  @override
  String get challengesMyChallenges => '내 챌린지';

  @override
  String get challengesNoActiveChallenges => '진행 중인 챌린지 없음';

  @override
  String get challengesNoChallengesFound => '챌린지를 찾을 수 없음';

  @override
  String get challengesPopularChallenges => '인기 챌린지';

  @override
  String get challengesStartYourOwnChallenge => '나만의 챌린지를 시작하고 친구들을 초대하세요';

  @override
  String get challengesStrip100KmTarget => '100 km 목표';

  @override
  String get challengesStrip25KmTarget => '25 km 목표';

  @override
  String get challengesStrip5WorkoutsIn7 => '7일 동안 5회 운동';

  @override
  String get challengesStripMonthlyRunChallenge => '월간 달리기 챌린지';

  @override
  String changeEquipmentHelperCouldNotSaveEquipment(Object e) {
    return '장비를 저장할 수 없습니다: $e';
  }

  @override
  String get changeEquipmentHelperEquipment => '장비';

  @override
  String get changeEquipmentHelperNoActiveGymProfile =>
      '활성화된 짐 프로필이 없습니다. 설정 → 짐 메뉴를 먼저 확인하세요.';

  @override
  String get chatActionConfirmApplied => '적용됨';

  @override
  String get chatActionConfirmApply => '적용';

  @override
  String get chatActionConfirmDismissed => '해제됨';

  @override
  String get chatClear => '지우기';

  @override
  String get chatClearChatHistory => '채팅 기록을 지울까요?';

  @override
  String get chatFeaturesInfoLongPressActionPills =>
      '액션 버튼을 길게 눌러 바로가기를 사용자 지정하세요';

  @override
  String get chatFeaturesInfoTryAskingWhatCan =>
      '전체 기능 목록을 보려면 \"무엇을 할 수 있나요?\"라고 물어보세요';

  @override
  String get chatFeaturesInfoWhatCanIDo => '무엇을 할 수 있나요?';

  @override
  String get chatFeaturesInfoYourAiCoachCan =>
      'AI 코치가 미디어 분석, 운동 생성, 영양 조언 등을 제공합니다.';

  @override
  String get chatGotIt => '확인';

  @override
  String chatMediaWidgetsCalTotal(Object totalCal) {
    return '총 $totalCal cal';
  }

  @override
  String chatMediaWidgetsGProtein(Object totalProtein) {
    return '단백질 ${totalProtein}g';
  }

  @override
  String chatMediaWidgetsGoTo(Object workoutName) {
    return '$workoutName으로 이동';
  }

  @override
  String get chatMediaWidgetsGoToWorkout => '운동 시작하기';

  @override
  String chatMediaWidgetsItemsFound(Object length) {
    return '항목 $length개 발견';
  }

  @override
  String get chatMediaWidgetsViewAllLog => '모두 보기 및 기록';

  @override
  String get chatMessageBubbleCopied => '복사됨';

  @override
  String get chatMessageBubbleCopy => '복사';

  @override
  String get chatMessageBubbleDeleteThisMessage => '이 메시지를 삭제할까요?';

  @override
  String get chatMessageBubblePin => '고정';

  @override
  String get chatMessageBubbleRegenerate => '다시 생성';

  @override
  String get chatMessageBubbleReport => '신고';

  @override
  String get chatMessageBubbleThisActionCannotBe => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get chatMessageBubbleUnpin => '고정 해제';

  @override
  String get chatMessageBubbleUploading => '업로드 중...';

  @override
  String chatMessageBubbleValue(Object message) {
    return '+$message';
  }

  @override
  String chatMessageBubbleValue2(Object label) {
    return '$label: ';
  }

  @override
  String get chatMessageBubbleWorkoutContext => '운동 컨텍스트';

  @override
  String get chatNotNow => '나중에';

  @override
  String get chatQuickPillsChatActions => '채팅 액션';

  @override
  String get chatQuickPillsChooseMultiplePhotos => '사진 여러 장 선택';

  @override
  String get chatQuickPillsChoosePhoto => '사진 선택';

  @override
  String get chatQuickPillsChooseVideo => '동영상 선택';

  @override
  String get chatQuickPillsCustomizeShortcuts => '바로가기 사용자 지정';

  @override
  String get chatQuickPillsDragToReorderTop =>
      '드래그하여 순서를 변경하세요. 상위 5개 항목이 입력창 위에 표시됩니다.';

  @override
  String get chatQuickPillsRecordVideo => '동영상 촬영';

  @override
  String get chatQuickPillsResetToDefault => '기본값으로 재설정';

  @override
  String get chatQuickPillsTakePhoto => '사진 촬영';

  @override
  String get chatQuickPillsTapAnActionTo =>
      '액션을 탭하여 사용하세요. 버튼을 길게 눌러 순서를 변경할 수 있습니다.';

  @override
  String get chatScreenCantReachCoach => '현재 코치에게 연결할 수 없습니다.';

  @override
  String get chatScreenCheckConnection => '연결 상태를 확인하고 다시 시도하세요.';

  @override
  String get chatScreenCoachIsThinkingLonger => '코치가 평소보다 더 오래 생각하고 있습니다.';

  @override
  String get chatScreenCouldntReachCoach => '코치에게 연결하지 못했습니다.';

  @override
  String get chatScreenExtAboutAiCoach => 'AI 코치 소개';

  @override
  String get chatScreenExtChangeCoach => '코치 변경';

  @override
  String get chatScreenExtChatTips => '채팅 팁';

  @override
  String get chatScreenExtChooseMultiplePhotos => '사진 여러 장 선택';

  @override
  String get chatScreenExtChoosePhoto => '사진 선택';

  @override
  String get chatScreenExtChooseVideo => '동영상 선택';

  @override
  String get chatScreenExtClearChatHistory => '채팅 기록 지우기';

  @override
  String get chatScreenExtConnectWithAReal => '상담원과 연결';

  @override
  String get chatScreenExtEmailOurSupportTeam => '지원팀에 이메일 보내기';

  @override
  String get chatScreenExtFailedToLogFood => '음식 기록 실패';

  @override
  String chatScreenExtFailedToSendMedia(Object e) {
    return '미디어 전송 실패: $e';
  }

  @override
  String chatScreenExtFailedToSendMedia2(Object e) {
    return '미디어 전송 실패: $e';
  }

  @override
  String chatScreenExtFailedToSendMessage(Object e) {
    return '메시지 전송 실패: $e';
  }

  @override
  String get chatScreenExtRecordVideo => '동영상 촬영';

  @override
  String get chatScreenExtReportAProblem => '문제 신고';

  @override
  String get chatScreenExtResetsAtMidnight => '자정에 초기화';

  @override
  String get chatScreenExtSeeWhatYourAi => 'AI 코치 기능 알아보기';

  @override
  String get chatScreenExtSwitchToADifferent => '다른 AI 코치로 전환';

  @override
  String get chatScreenExtTakePhoto => '사진 촬영';

  @override
  String get chatScreenExtTalkToHuman => '상담원 연결';

  @override
  String chatScreenExtThatWasYourLast(Object gateName) {
    return '이번 기간의 마지막 무료 $gateName입니다.';
  }

  @override
  String chatScreenExtThatWasYourLast2(Object gateName) {
    return '이번 기간의 마지막 무료 $gateName입니다.';
  }

  @override
  String get chatScreenExtTodaySUsage => '오늘 사용량';

  @override
  String get chatScreenExtUnlimitedAccessWithPremium => 'Premium으로 무제한 이용';

  @override
  String get chatScreenExtUpgradeForUnlimited => '무제한 이용을 위해 업그레이드';

  @override
  String chatScreenFailedToSendVoice(Object error) {
    return '음성 메시지 전송 실패: $error';
  }

  @override
  String chatScreenMessagesLeftToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오늘 남은 메시지 $count개',
    );
    return '$_temp0';
  }

  @override
  String get chatScreenMultiAgentHangTight =>
      '다중 에이전트 답변은 최대 2분까지 걸릴 수 있습니다. 잠시 기다리거나 다시 시도하세요.';

  @override
  String get chatScreenPartAddAMessage => '메시지 입력...';

  @override
  String get chatScreenPartAddVideo => '동영상 추가';

  @override
  String get chatScreenPartCheckingAvailability => '가능 여부 확인 중...';

  @override
  String get chatScreenPartChooseVideo => '동영상 선택';

  @override
  String get chatScreenPartConnect => '연결';

  @override
  String get chatScreenPartFromGalleryMax60s => '갤러리에서 선택 (최대 60초)';

  @override
  String chatScreenPartMediaSendStatusFailedToConnect(Object e) {
    return '연결 실패: $e';
  }

  @override
  String chatScreenPartMediaSendStatusPeopleInQueue(Object currentQueueSize) {
    return '대기 인원 $currentQueueSize명';
  }

  @override
  String get chatScreenPartRecordVideo => '동영상 촬영';

  @override
  String get chatScreenPartSelectACategory => '카테고리 선택:';

  @override
  String get chatScreenPartTalkToHumanSupport => '상담원 연결';

  @override
  String get chatScreenPartUseCameraMax60s => '카메라 사용 (최대 60초)';

  @override
  String get chatScreenPartWaitTimeUnavailable => '대기 시간 확인 불가';

  @override
  String get chatScreenPartYouWillBeConnected =>
      '질문에 도움을 드릴 수 있는 실제 상담원과 연결됩니다.';

  @override
  String chatScreenRouteNotRegistered(Object route) {
    return '등록되지 않은 경로: $route';
  }

  @override
  String get chatScreenSomethingWentWrongLoading => '채팅을 불러오는 중 오류가 발생했습니다.';

  @override
  String get chatScreenTyping => '입력 중...';

  @override
  String get chatScreenMastheadTitle => '코치';

  @override
  String get chatScreenMastheadSubtitle => '언제나 당신 편이에요.';

  @override
  String get chatScreenMastheadHistory => '기록';

  @override
  String get chatScreenMastheadNew => '새로 만들기';

  @override
  String chatScreenMastheadDay(int count) {
    return '$count일차';
  }

  @override
  String get chatScreenUiConnectionDropped => '연결이 끊겼습니다';

  @override
  String get chatScreenUiTyping => '입력 중…';

  @override
  String get chatSearchOverlayNoResultsFound => '검색 결과 없음';

  @override
  String get chatSearchOverlaySearchChat => '채팅 검색';

  @override
  String get chatSearchOverlaySearchMessages => '메시지 검색...';

  @override
  String get chatSearchOverlayTypeToSearch => '검색어 입력';

  @override
  String get chatThisMatchIsMissing => '이 매치에 운동 ID가 누락되었습니다.';

  @override
  String get chatThisWillDeleteAll =>
      'AI 코치와의 모든 대화 기록이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get chatYourPersonalAiPowered =>
      '당신의 개인 AI 피트니스 코치입니다. 운동, 영양, 회복 또는 피트니스 관련 질문을 무엇이든 물어보세요. AI는 당신의 진행 상황을 학습하여 맞춤형 조언을 제공합니다.';

  @override
  String get classicStatsTemplateCalories => '칼로리';

  @override
  String get classicStatsTemplateDuration => '운동 시간';

  @override
  String get classicStatsTemplateExercises => '운동';

  @override
  String get classicStatsTemplateVolume => '볼륨';

  @override
  String get coachAskAnything => '무엇이든 물어보세요…';

  @override
  String get coachAskYourCoach => '코치에게 물어보기';

  @override
  String coachBannerOverlayXp(Object xpAwarded) {
    return '+$xpAwarded XP';
  }

  @override
  String get coachDashboardActiveGoals => '진행 중인 목표';

  @override
  String get coachDashboardBodyFat => '체지방';

  @override
  String get coachDashboardFailedToLoadDashboard => '대시보드를 불러오지 못했습니다';

  @override
  String get coachDashboardReadiness => '컨디션';

  @override
  String coachDashboardScreenValue(Object nutritionPct) {
    return '$nutritionPct%';
  }

  @override
  String coachDashboardScreenValue2(Object pct) {
    return '$pct%';
  }

  @override
  String get coachDashboardThisWeek => '이번 주';

  @override
  String get coachDashboardTryAgain => '다시 시도';

  @override
  String get coachDashboardWeight => '체중';

  @override
  String get coachHeroCardAlreadyRefreshedInThe => '최근 30분 이내에 이미 새로고침되었습니다.';

  @override
  String get coachHeroCardRethinking => '생각 중…';

  @override
  String get coachHeroCardTapToOpenChat => '탭하여 채팅 열기';

  @override
  String get coachHeroCardYourCoach => '나의 코치';

  @override
  String get coachHeroCardYourCoachIsGathering => '코치가 생각을 정리하고 있습니다.';

  @override
  String get coachHeroCardYourCoachIsHere => '코치가 여기 있습니다.';

  @override
  String get coachProfileCardSampleConversation => '대화 예시';

  @override
  String get coachReviewApply => '적용';

  @override
  String get coachReviewApplySwapComingWith => '교체 적용 — 플래너 연동 기능과 함께 제공 예정';

  @override
  String get coachReviewCoachReview => '코치 리뷰';

  @override
  String get coachReviewFullFeedback => '전체 피드백';

  @override
  String get coachReviewMacroBalance => '매크로 밸런스';

  @override
  String get coachReviewMicronutrientGaps => '미량 영양소 부족분';

  @override
  String get coachReviewNoReviewYetTap => '아직 리뷰가 없습니다 — 새로고침을 탭하여 생성하세요';

  @override
  String get coachReviewOutOfDate => '업데이트 필요';

  @override
  String get coachReviewOverallScore => '종합 점수';

  @override
  String get coachReviewRequestHumanProReview => '전문가 리뷰 요청';

  @override
  String coachReviewSheetAllergenAlert(Object allergenFlags) {
    return '알레르기 주의: $allergenFlags';
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
  String get coachReviewSuggestedSwaps => '추천 교체 운동';

  @override
  String get coachReviewTemplateCoachSReview => '코치의 리뷰';

  @override
  String get coachReviewTemplateWorkoutReview => '운동 리뷰';

  @override
  String get coachReviewWeLlNotifyYou => '전문가 리뷰 기능이 출시되면 알려드릴게요';

  @override
  String get coachSelectionAiGeneratedAvatar => 'AI 생성 아바타';

  @override
  String get coachSelectionAppearance => '외형';

  @override
  String get coachSelectionBuild => '체격';

  @override
  String get coachSelectionCoachAce => '코치 Ace';

  @override
  String get coachSelectionCoachingStyle => '코칭 스타일';

  @override
  String get coachSelectionCommunicationTone => '대화 톤';

  @override
  String get coachSelectionCreateYourOwnCoach => '나만의 코치 만들기';

  @override
  String get coachSelectionCustom => '사용자 지정';

  @override
  String get coachSelectionDesignACoachThat => '나의 분위기에 맞는 코치를 디자인하세요';

  @override
  String get coachSelectionEGAtlasRiley => '예: Atlas, Riley, Sensei';

  @override
  String get coachSelectionEncouragement => '격려';

  @override
  String get coachSelectionGender => '성별';

  @override
  String get coachSelectionLetSGoooTime =>
      '가자! 오늘 제대로 불태워 봅시다! 5일 연속 기록 중인데 여기서 멈출 순 없죠. 마법 같은 결과를 만들어 볼 준비 되셨나요?';

  @override
  String get coachSelectionLook => '외모';

  @override
  String get coachSelectionMotivationalEncouraging => '동기 부여 및 격려형';

  @override
  String get coachSelectionNameYourCoach => '코치 이름 정하기';

  @override
  String get coachSelectionSampleMessage => '메시지 예시';

  @override
  String get coachSelectionScreenChangeCoach => '코치 변경';

  @override
  String get coachSelectionScreenCreateYourOwnCoach => '나만의 코치 만들기';

  @override
  String get coachSelectionScreenEnergy => '에너지';

  @override
  String get coachSelectionScreenHowTheyTalk => '대화 방식';

  @override
  String get coachSelectionScreenMeetYourCoach => '코치 만나기';

  @override
  String get coachSelectionScreenSaveCoach => '코치 저장';

  @override
  String get coachSelectionScreenSelectANewAi => '새로운 AI 코치 페르소나 선택';

  @override
  String coachSelectionScreenUse(Object _customName) {
    return '$_customName 사용';
  }

  @override
  String get coachSelectionWhatYouLlBe => '커스터마이징 가능한 항목';

  @override
  String get coachVoicePicker => '🗣️';

  @override
  String get coachVoicePickerCalmPreciseVoice => '차분하고 정확한 목소리';

  @override
  String get coachVoicePickerCoachChad => '코치 Chad';

  @override
  String get coachVoicePickerCoachSerena => '코치 Serena';

  @override
  String get coachVoicePickerCoachVoice => '코치 목소리';

  @override
  String get coachVoicePickerDeeperHighEnergyVoice => '낮고 에너지가 넘치는 목소리';

  @override
  String get coachVoicePickerDefault => '기본';

  @override
  String coachVoicePickerFailedToSwitchVoice(Object error) {
    return '음성 전환 실패: $error';
  }

  @override
  String get coachVoicePickerPlaysDuringWorkoutAnnouncem => '운동 안내 시 재생';

  @override
  String get coachVoicePickerUnlocksAtLevel50 =>
      '레벨 50 달성 시 잠금 해제 — 계속 레벨업하세요!';

  @override
  String get coachVoicePickerUnlocksAtLevel502 => '레벨 50 달성 시 잠금 해제';

  @override
  String get coachVoicePickerYourDeviceSDefault => '기기 기본 음성';

  @override
  String get collapsedBannerStrip2x => '2x';

  @override
  String collapsedBannerStripGoals(Object completedGoals, Object totalGoals) {
    return '목표 $completedGoals / $totalGoals개';
  }

  @override
  String get collapsedBannerStripU00b7 => '·';

  @override
  String get combinedHealthActiveEnergy => '활동 에너지';

  @override
  String get combinedHealthActiveMinutesGoal => '활동 시간 목표';

  @override
  String get combinedHealthActivityStreak => '활동 연속 기록';

  @override
  String combinedHealthActivityStreakDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '걸음 수 목표를 $count일 연속 달성했습니다.',
    );
    return '$_temp0';
  }

  @override
  String get combinedHealthCardHealthOverview => '건강 개요';

  @override
  String get combinedHealthConnectHealth => '건강 연동';

  @override
  String get combinedHealthConnectHealthBody =>
      '걸음 수, 심박수, 수면 등은 Android의 Health Connect와 iOS의 건강 앱에서 동기화됩니다.';

  @override
  String get combinedHealthConnectHealthToSee => '활동을 확인하려면 건강 데이터를 연동하세요';

  @override
  String get combinedHealthCouldNotLoadYour =>
      '건강 데이터를 불러올 수 없습니다. 아래로 당겨서 다시 시도하세요.';

  @override
  String get combinedHealthCouldNotSaveGoal => '목표를 저장할 수 없습니다.';

  @override
  String get combinedHealthDailyGoals => '일일 목표';

  @override
  String get combinedHealthHealth => '건강';

  @override
  String get combinedHealthHitYourStepGoal => '걸음 수 목표를 달성하고 연속 기록을 시작하세요.';

  @override
  String get combinedHealthRestingHeartRate => '안정 시 심박수';

  @override
  String get combinedHealthSaving => '저장 중…';

  @override
  String combinedHealthScreenBpm(Object restingHeartRate) {
    return '$restingHeartRate bpm';
  }

  @override
  String combinedHealthScreenCal(Object caloriesBurned) {
    return '$caloriesBurned cal';
  }

  @override
  String combinedHealthScreenHM(Object day, Object day1) {
    return '$day시간 $day1분';
  }

  @override
  String combinedHealthScreenMl(Object waterMl) {
    return '$waterMl ml';
  }

  @override
  String get combinedHealthSleep => '수면';

  @override
  String get combinedHealthStepGoal => '걸음 수 목표';

  @override
  String get combinedHealthSteps => '걸음 수';

  @override
  String get combinedHealthWater => '수분 섭취';

  @override
  String get comebackModeComebackModeReducesSets =>
      'Comeback 모드는 휴식 후 부상을 방지하기 위해 세트 수와 강도를 줄여줍니다.';

  @override
  String get comebackModeEaseMeBackIn => '천천히 다시 시작하기';

  @override
  String get comebackModeIMReadyFor => '전체 운동을 시작할 준비가 되었습니다';

  @override
  String comebackModeSheetYouHavenTWorked(Object daysSinceLastWorkout) {
    return '$daysSinceLastWorkout일 동안 운동하지 않으셨습니다';
  }

  @override
  String get comebackModeWelcomeBack => '다시 오신 것을 환영합니다!';

  @override
  String get comingSoonActiveChallenges => '진행 중인 챌린지';

  @override
  String get comingSoonBeforeAfterProgressComparis => '비포/애프터 진행 상황 비교';

  @override
  String get comingSoonBluetoothHeartRateHardware => '블루투스 심박수 장치';

  @override
  String get comingSoonBody => '이 기능을 준비 중입니다. 곧 만나요.';

  @override
  String get comingSoonBottomComingSoon => '준비 중';

  @override
  String get comingSoonBottomGotIt => '확인했습니다!';

  @override
  String comingSoonBottomSheetWeeksSessionsPerWeek(
    Object durationWeeks,
    Object sessionsPerWeek,
  ) {
    return '$durationWeeks주 • 주 $sessionsPerWeek회 세션';
  }

  @override
  String get comingSoonBottomWhatYouCanExpect => '기대할 수 있는 기능:';

  @override
  String get comingSoonBrowseLikeAndRemix =>
      '커뮤니티에서 공유한 레시피를 탐색하고, 좋아요를 누르고, 리믹스하세요. 소셜 탭과 함께 제공됩니다.';

  @override
  String get comingSoonCaloriesSummary => '칼로리 요약';

  @override
  String get comingSoonChallengeProgressMiniCard => '챌린지 진행 상황 미니 카드';

  @override
  String get comingSoonComingSoon => '준비 중';

  @override
  String get comingSoonDailyActivity => '일일 활동';

  @override
  String get comingSoonDailyStats => '일일 통계';

  @override
  String get comingSoonExerciseVariationThisWeek => '이번 주 운동 변화';

  @override
  String get comingSoonFeaturesWeReWorking => '개발 중인 다음 기능';

  @override
  String get comingSoonFitnessScore => '피트니스 점수';

  @override
  String get comingSoonFoodPreferences => '음식 선호도';

  @override
  String get comingSoonFriendActivity => '친구 활동';

  @override
  String get comingSoonHealthDeviceActivitySummary => '건강 기기 활동 요약';

  @override
  String get comingSoonHolisticPlanWithWorkouts => '운동, 영양 및 단식을 포함한 종합 계획';

  @override
  String get comingSoonLeaderboard => '리더보드';

  @override
  String get comingSoonMacroRings => '매크로 링';

  @override
  String get comingSoonMiniCalendar => '미니 캘린더';

  @override
  String get comingSoonMiniCalendarWithWorkout => '운동 일정이 표시된 미니 캘린더';

  @override
  String get comingSoonMoodCheckIn => '기분 체크인';

  @override
  String get comingSoonMuscleGroupsTrainedRecently => '최근 훈련한 근육 그룹';

  @override
  String get comingSoonMuscleHeatmap => '근육 히트맵';

  @override
  String get comingSoonMyJourney => '나의 여정';

  @override
  String get comingSoonOneTapOnYour =>
      '홈 또는 잠금 화면에서 한 번의 탭으로 칼로리와 매크로가 포함된 AI 식단 아이디어를 확인하고 \'기록하기\' 버튼을 사용하세요.';

  @override
  String get comingSoonOneTapToStart => '한 번의 탭으로 오늘의 운동 시작';

  @override
  String get comingSoonOverallFitnessStrengthNu => '전반적인 피트니스, 근력 및 영양 점수';

  @override
  String get comingSoonOverlayComingSoon => '준비 중';

  @override
  String get comingSoonPairBleChestStraps =>
      'BLE 가슴 스트랩 및 심박수 모니터를 페어링하여 운동 중 실시간 BPM 확인';

  @override
  String get comingSoonPhotoCompare => '사진 비교';

  @override
  String get comingSoonProgressCharts => '진행 상황 차트';

  @override
  String get comingSoonQuickMeasurements => '빠른 측정';

  @override
  String get comingSoonQuickMoodPickerFor => '즉석 운동을 위한 빠른 기분 선택기';

  @override
  String get comingSoonQuickStart => '빠른 시작';

  @override
  String get comingSoonRecentWeightWithTrend => '추세 화살표가 포함된 최근 체중';

  @override
  String get comingSoonRecipeDiscoveryFeed => '레시피 탐색 피드';

  @override
  String get comingSoonRecipeImport => '레시피 가져오기';

  @override
  String get comingSoonRecoveryTipsForRest => '휴식일을 위한 회복 팁';

  @override
  String get comingSoonRestDayTips => '휴식일 팁';

  @override
  String get comingSoonSearchFeatures => '기능 검색...';

  @override
  String get comingSoonSeeWhatFriendsAre => '친구들의 활동 확인';

  @override
  String get comingSoonStepsCountAndCalorie => '걸음 수 및 칼로리 결손 추적';

  @override
  String get comingSoonStrengthAndVolumeCharts => '시간에 따른 근력 및 볼륨 차트';

  @override
  String get comingSoonTheseFeaturesAreIn =>
      '이 기능들은 현재 개발 중이며 곧 홈 화면 위젯으로 추가될 예정입니다.';

  @override
  String get comingSoonTitle => '곧 출시';

  @override
  String get comingSoonTodaySIntakeVs => '오늘의 섭취량과 목표를 한눈에 확인';

  @override
  String get comingSoonTotalWorkoutsTimeInvested => '총 운동 횟수, 투자 시간 및 마일스톤';

  @override
  String get comingSoonTrackBodyMeasurementsEasily => '신체 치수를 쉽게 추적';

  @override
  String get comingSoonUpcomingHomeWidgets => '출시 예정 홈 위젯';

  @override
  String get comingSoonVisualDonutChartsFor => '단백질, 탄수화물, 지방을 위한 시각적 도넛 차트';

  @override
  String get comingSoonWeekChanges => '주간 변화';

  @override
  String get comingSoonWeeklyPlan => '주간 계획';

  @override
  String get comingSoonWeightTracker => '체중 추적기';

  @override
  String get comingSoonWhatShouldIEat => '무엇을 먹을까요? 위젯';

  @override
  String get comingSoonYourFitnessJourneyProgress => '나의 피트니스 여정 진행 상황';

  @override
  String get comingSoonYourJourneyRoi => '나의 여정 ROI';

  @override
  String get comingSoonYourPositionOnThe => '리더보드 내 나의 순위';

  @override
  String get commentsAddAComment => '댓글 추가...';

  @override
  String get commentsAreYouSureYou => '이 댓글을 삭제하시겠습니까?';

  @override
  String get commentsBeTheFirstTo => '첫 번째 댓글을 남겨보세요!';

  @override
  String get commentsCopyText => '텍스트 복사';

  @override
  String get commentsDeleteComment => '댓글 삭제';

  @override
  String get commentsNoCommentsYet => '아직 댓글이 없습니다';

  @override
  String get commitmentPactHoldToCommit => '길게 눌러 약속하기';

  @override
  String get commitmentPactIMIn => '참여하기';

  @override
  String get commitmentPactOneLastThing => '마지막으로 한 가지.';

  @override
  String get commitmentPactOtherWorkoutDays => '다른 운동일';

  @override
  String commitmentPactScreenFirstSession(Object dayLabel) {
    return '첫 세션 · $dayLabel';
  }

  @override
  String get commitmentPactSkipAnyway => '건너뛰기';

  @override
  String get commitmentPactSkipTheCommitment => '약속을 건너뛸까요?';

  @override
  String get commitmentPactWeLlHandleThe => '계획은 저희가 세울게요. 당신은 운동만 하세요.';

  @override
  String get commonBack => '뒤로';

  @override
  String get commonCancel => '취소';

  @override
  String get commonClear => '지우기';

  @override
  String get commonClose => '닫기';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonDone => '완료';

  @override
  String get commonEdit => '편집';

  @override
  String get commonError => '오류';

  @override
  String get commonLoading => '불러오는 중…';

  @override
  String get commonNew => 'NEW';

  @override
  String get commonNext => '다음';

  @override
  String get commonShare => '공유';

  @override
  String get commonTryAgain => '다시 시도';

  @override
  String get commonYes => '예';

  @override
  String get commonYou => '나';

  @override
  String get communityRecipeSearchCommunityRecipes => '커뮤니티 레시피';

  @override
  String get communityRecipeSearchNothingFoundInCommunity =>
      '커뮤니티 레시피에서 찾을 수 없습니다.';

  @override
  String get communityRecipeSearchOpenTheRecipeTo => '레시피를 열어 라이브러리에 저장하세요';

  @override
  String get communityRecipeSearchSaveToMyRecipes => '내 레시피에 저장';

  @override
  String communityRecipeSearchScreenKcalLogs(
    Object summary,
    Object timesLogged,
  ) {
    return '$summary kcal · $timesLogged회 기록';
  }

  @override
  String get communityRecipeSearchSearchPublicRecipes => '공개 레시피 검색...';

  @override
  String get communityRecipeSearchSearchPublicRecipesShared =>
      '다른 사용자가 공유한 공개 레시피를 검색하세요.';

  @override
  String compactSplitCardDWk(Object daysPerWeek, Object duration) {
    return '(daysPerWeek)일/주 · (duration)';
  }

  @override
  String get compactWorkoutRow => ' • ';

  @override
  String compactWorkoutRowMinExercises(
    Object bestDurationMinutes,
    Object exerciseCount,
  ) {
    return '$bestDurationMinutes분 • 운동 $exerciseCount개';
  }

  @override
  String get companionPickerAddAll => '모두 추가';

  @override
  String get companionPickerLastTimeYouLogged =>
      '지난번에 함께 기록하셨네요. 오늘 적용할 항목만 선택하세요.';

  @override
  String get companionPickerLogSelected => '선택 항목 기록';

  @override
  String get companionPickerPickWhatYouHad => '섭취한 항목 선택';

  @override
  String companionPickerSheetCal(Object item) {
    return '$item cal';
  }

  @override
  String companionPickerSheetCal2(Object estCalories) {
    return '$estCalories cal';
  }

  @override
  String companionPickerSheetCal3(Object _selectedCalTotal) {
    return '$_selectedCalTotal cal';
  }

  @override
  String companionPickerSheetCalAlwaysIncluded(Object primaryCalories) {
    return '$primaryCalories cal — 항상 포함';
  }

  @override
  String companionPickerSheetGProtein(Object _selectedProteinTotal) {
    return '· 단백질 ${_selectedProteinTotal}g';
  }

  @override
  String companionPickerSheetOnItsOwn(Object primaryName) {
    return '$primaryName 단독.';
  }

  @override
  String companionPickerSheetTypicalCompanionsFor(Object primaryName) {
    return '$primaryName과(와) 함께 자주 먹는 음식.';
  }

  @override
  String get comparisonAiSummary => 'AI 요약';

  @override
  String get comparisonAlign => '정렬';

  @override
  String get comparisonBorder => '테두리';

  @override
  String get comparisonComparisonSaved => '비교가 저장되었습니다!';

  @override
  String get comparisonCtaLabel => 'CTA 라벨';

  @override
  String get comparisonDates => '날짜';

  @override
  String get comparisonGalleryComparisonDeleted => '비교가 삭제되었습니다';

  @override
  String get comparisonGalleryCreateABeforeAfter =>
      '사진 탭에서 비포 & 애프터 비교를 만들어 시간 경과에 따른 변화를 확인하세요.';

  @override
  String get comparisonGalleryDeleteComparison => '비교를 삭제할까요?';

  @override
  String get comparisonGalleryExportAndShareThis => '이 비교 내보내기 및 공유';

  @override
  String get comparisonGalleryNoComparisonsYet => '아직 비교 기록이 없습니다';

  @override
  String get comparisonGalleryOpen => '열기';

  @override
  String get comparisonGalleryOpenInComparisonEditor => '비교 편집기에서 열기';

  @override
  String get comparisonGalleryOpenTheComparisonIn =>
      '내보내기 및 공유를 하려면 먼저 편집기에서 비교를 여세요.';

  @override
  String get comparisonGalleryReEdit => '다시 편집';

  @override
  String get comparisonGalleryRemoveThisComparison => '이 비교 삭제';

  @override
  String get comparisonGallerySavedComparisons => '저장된 비교';

  @override
  String get comparisonGalleryThisWillPermanentlyRemove =>
      '이 비교가 영구적으로 삭제됩니다. 원본 사진은 삭제되지 않습니다.';

  @override
  String comparisonGalleryValue(Object afterDate, Object beforeDate) {
    return '$beforeDate  ->  $afterDate';
  }

  @override
  String get comparisonGap => '간격';

  @override
  String get comparisonGhost => '고스트';

  @override
  String get comparisonLogo => '로고';

  @override
  String get comparisonNextCustomize => '다음: 사용자 지정';

  @override
  String get comparisonNextSelectPhotos => '다음: 사진 선택';

  @override
  String get comparisonRadius => '반경';

  @override
  String get comparisonReset => '재설정';

  @override
  String get comparisonSeeAll => '모두 보기';

  @override
  String get comparisonShape => '모양';

  @override
  String get comparisonStartNow => '지금 시작';

  @override
  String get comparisonStats => '통계';

  @override
  String get comparisonTemplates => '템플릿';

  @override
  String get comparisonUsername => '사용자 이름';

  @override
  String comparisonViewComparison(Object displayName) {
    return '$displayName 비교';
  }

  @override
  String get comparisonViewExtAll => '전체';

  @override
  String get comparisonViewExtClear => '지우기';

  @override
  String comparisonViewExtSelected(Object length, Object photoCount) {
    return '$length / $photoCount개 선택됨';
  }

  @override
  String comparisonViewExtSelectedPhotos(
    Object length,
    Object maxPhotos,
    Object minPhotos,
  ) {
    return '$length개 선택됨 ($minPhotos-$maxPhotos장)';
  }

  @override
  String comparisonViewKg(Object weight) {
    return '$weight kg';
  }

  @override
  String get comparisonViewUi2PhotoLayouts => '2장 사진 레이아웃';

  @override
  String get comparisonViewUiMultiPhotoLayouts => '다중 사진 레이아웃';

  @override
  String get comparisonViewUiMyProgress => '나의 진행 상황';

  @override
  String get comparisonViewUiNoPhotosFound => '사진을 찾을 수 없음';

  @override
  String get comparisonViewUiNoPhotosSelected => '선택된 사진 없음';

  @override
  String comparisonViewUiNoPhotosYetTry(Object displayName) {
    return '$displayName 사진이 아직 없습니다. 다른 필터를 시도해 보세요.';
  }

  @override
  String get comparisonViewUiProgressSummary => '진행 상황 요약';

  @override
  String get comparisonViewUiSelect2Photos => '사진 2장 선택';

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
    return '$length 바이럴';
  }

  @override
  String get comparisonWeights => '무게';

  @override
  String get comparisonWidth => '너비';

  @override
  String get completeExtendFailed => '운동 시간 연장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get completeNoFriendsYet => '아직 친구가 없습니다. 친구를 초대하세요!';

  @override
  String get completeNoShareData => '공유할 운동 데이터가 없습니다';

  @override
  String get completePleaseRateWorkout => '운동 평가를 남겨주세요';

  @override
  String get completeUnableToChallenge => '챌린지를 시작할 수 없습니다';

  @override
  String get completeUnableToExtend => '운동 시간을 연장할 수 없습니다';

  @override
  String get completeViewGoals => '목표 보기';

  @override
  String get complianceRingCardAllWorkoutsCompleted => '모든 운동 완료';

  @override
  String get complianceRingCardGetStartedToday => '오늘 시작하기';

  @override
  String complianceRingCardGreatPace(Object arg0) {
    return '좋은 페이스예요! $arg0 남음';
  }

  @override
  String get complianceRingCardNoWorkoutsScheduledThis => '이번 주에 예정된 운동이 없습니다';

  @override
  String complianceRingCardOnTrack(Object arg0) {
    return '순조로워요 — $arg0 남음';
  }

  @override
  String get complianceRingCardWorkoutCompliance => '운동 준수율';

  @override
  String complianceRingCardWorkoutsRemaining(Object arg0) {
    return '운동 $arg0개 남음';
  }

  @override
  String get comprehensiveStatsStatsScores => '통계 및 점수';

  @override
  String get connectedAppsAutoImportEvery15 => '15분마다 자동 가져오기';

  @override
  String get connectedAppsConnect => '연결';

  @override
  String get connectedAppsConnectedApps => '연결된 앱';

  @override
  String get connectedAppsDisconnect => '연결 해제';

  @override
  String get connectedAppsEnable => '활성화';

  @override
  String get connectedAppsIncludeCardioSessions => '유산소 운동 세션 포함';

  @override
  String get connectedAppsIncludeStrengthWorkouts => '근력 운동 포함';

  @override
  String get connectedAppsNoSyncYetWill => '아직 동기화되지 않았습니다. 15분 이내에 실행됩니다.';

  @override
  String get connectedAppsReconnect => '재연결';

  @override
  String connectedAppsScreenDisconnect(Object displayName) {
    return '$displayName 연결을 해제할까요?';
  }

  @override
  String connectedAppsScreenPreviouslyImportedActivitiesWill(Object appName) {
    return '이전에 가져온 활동은 $appName 기록에 그대로 유지됩니다. ';
  }

  @override
  String connectedAppsScreenRidesAndWorkoutsData(Object appName) {
    return '라이딩 및 운동 데이터. 데이터는 양방향으로 흐릅니다. $appName 운동을 ';
  }

  @override
  String connectedAppsScreenSignInTo(Object displayName) {
    return '$displayName에 로그인';
  }

  @override
  String get connectedAppsSyncNow => '지금 동기화';

  @override
  String get consistencyCardConsistency => '일관성';

  @override
  String get consistencyCardDayBestNstreak => '최고 연속 기록';

  @override
  String get consistencyCardOfDaysYouShowed => '운동한 날';

  @override
  String consistencyCardValue(Object workoutConsistencyPct) {
    return '$workoutConsistencyPct%';
  }

  @override
  String get consistencyConsistency => '일관성';

  @override
  String get consistencyDayStreak => '연속 기록';

  @override
  String get consistencyFailedToLoadData => '데이터를 불러오지 못했습니다';

  @override
  String get consistencyFullWorkout => '전체 운동';

  @override
  String get consistencyInsightCardDayStreak => '일 연속 기록';

  @override
  String get consistencyInsightCardStartFreshToday => '오늘부터 다시 시작하세요!';

  @override
  String get consistencyInsightCardStreak => '연속 기록';

  @override
  String get consistencyInsightCardTapToBeginA => '탭하여 새로운 기록 시작하기';

  @override
  String get consistencyInsightCardTapToRefresh => '탭하여 새로고침';

  @override
  String get consistencyLast4Weeks => '지난 4주';

  @override
  String get consistencyQuick15min => '15분 빠른 운동';

  @override
  String get consistencyScoreCardConsistencyScore => '일관성 점수';

  @override
  String consistencyScoreCardDays(Object currentStreakValue) {
    return '$currentStreakValue일';
  }

  @override
  String get consistencyScoreCardPrs30d => 'PR (30일)';

  @override
  String get consistencyScoreCardStreak => '연속 기록';

  @override
  String get consistencyScoreCardThisWeek => '이번 주';

  @override
  String consistencyScoreCardValue(Object consistencyScore) {
    return '$consistencyScore%';
  }

  @override
  String get consistencyScoreCardWorkoutCompletionRate => '운동 완료율';

  @override
  String consistencyScreenAverageWeeklyCompletion(Object avgRate) {
    return '평균: 주간 완료율 $avgRate%';
  }

  @override
  String consistencyScreenCompletionRate(Object rate) {
    return '완료율 $rate%';
  }

  @override
  String consistencyScreenLongestDays(Object longestStreak) {
    return '최장: $longestStreak일';
  }

  @override
  String consistencyScreenOfWorkouts(Object scheduled) {
    return '예정된 운동 $scheduled개 중';
  }

  @override
  String get consistencyStartFreshToday => '오늘부터 다시 시작하세요!';

  @override
  String get consistencyThisMonth => '이번 달';

  @override
  String get consistencyThisWeek => '이번 주';

  @override
  String get consistencyTryAgain => '다시 시도';

  @override
  String get consistencyWeeklyTrend => '주간 추세';

  @override
  String get consistencyWorkoutPatterns => '운동 패턴';

  @override
  String contextualBannerFastingWindowEndsIn(Object timeStr) {
    return '단식 종료까지 $timeStr 남음';
  }

  @override
  String get contextualBannerKeepItUp => '계속 유지하세요!';

  @override
  String contextualBannerLbs(Object exerciseName, Object weightLbs) {
    return '$exerciseName: $weightLbs lbs';
  }

  @override
  String get contextualBannerNewPr => '새로운 PR 달성!';

  @override
  String contextualBannerYouReAwayFrom(Object remaining, Object workoutWord) {
    return '주간 목표까지 $remaining $workoutWord 남았습니다';
  }

  @override
  String get contributeFoodDataCouldNotDeletePlease => '삭제할 수 없습니다. 다시 시도해주세요';

  @override
  String get contributeFoodDataDeleteFoodContributions => '음식 기여 데이터를 삭제할까요?';

  @override
  String get contributeFoodDataDeleteMyFoodContributions => '내 음식 기여 데이터 삭제';

  @override
  String get contributeFoodDataHelpImproveNutritionData => '영양 데이터 개선 돕기';

  @override
  String get contributeFoodDataNoContributionsToDelete => '삭제할 기여 데이터가 없습니다';

  @override
  String get contributeFoodDataSharingNovelDishesRecommen => '새로운 요리 공유하기 (권장)';

  @override
  String get conversationEncrypted => '암호화됨';

  @override
  String get conversationFailedToLoadMessages => '메시지를 불러오지 못했습니다';

  @override
  String get conversationFailedToSendMessage => '메시지를 보내지 못했습니다';

  @override
  String get conversationNoMessagesYet => '아직 메시지가 없습니다';

  @override
  String get conversationNotLoggedIn => '로그인되지 않았습니다';

  @override
  String get conversationRead => '읽음';

  @override
  String conversationScreenIsTyping(Object first) {
    return '$first님이 입력 중...';
  }

  @override
  String conversationScreenPeopleTyping(Object length) {
    return '$length명이 입력 중...';
  }

  @override
  String get conversationSendTheFirstMessage => '첫 메시지를 보내보세요!';

  @override
  String get conversationSomeMessagesWereEncrypted =>
      '일부 메시지는 다른 기기에서 암호화되어 여기서 읽을 수 없습니다.';

  @override
  String get conversationTypeAMessage => '메시지 입력...';

  @override
  String get cookingConverterConvertBetweenRawAnd => '조리 전/후 무게 변환';

  @override
  String get cookingConverterCooked => '조리 후';

  @override
  String get cookingConverterCookedRaw => '조리 후 → 조리 전';

  @override
  String get cookingConverterCookingConverter => '조리 무게 변환기';

  @override
  String cookingConverterEnterWeight(Object type) {
    return '$type 무게 입력';
  }

  @override
  String get cookingConverterNoFoodsFound => '음식을 찾을 수 없습니다';

  @override
  String get cookingConverterRaw => '조리 전';

  @override
  String get cookingConverterRawCooked => '조리 전 → 조리 후';

  @override
  String get cookingConverterSearchFoods => '음식 검색...';

  @override
  String get cookingConverterSelectFood => '음식 선택';

  @override
  String cookingConverterSheetG(Object inputAmount) {
    return '${inputAmount}g';
  }

  @override
  String get cookingConverterUseThisValue => '이 값 사용';

  @override
  String get cosmeticsGalleryCosmetics => '코스메틱';

  @override
  String get cosmeticsGalleryEquip => '장착';

  @override
  String get cosmeticsGalleryEquipped => '장착됨';

  @override
  String get cosmeticsGalleryFailedToLoadCosmetics => '코스메틱을 불러오지 못했습니다';

  @override
  String get cosmeticsGalleryNoBadgeEquipped => '장착된 배지가 없습니다';

  @override
  String cosmeticsGalleryScreenFrame(Object displayName) {
    return '$displayName 프레임';
  }

  @override
  String cosmeticsGalleryScreenUnlocksAtLevel(Object unlockLevel) {
    return '레벨 $unlockLevel에서 잠금 해제';
  }

  @override
  String get cosmeticsGalleryYourLoadout => '내 장착 아이템';

  @override
  String get createChallengeAnyoneCanDiscoverAnd => '누구나 발견하고 참여할 수 있습니다';

  @override
  String get createChallengeChallengeType => '챌린지 유형';

  @override
  String get createChallengeCreateChallenge => '챌린지 만들기';

  @override
  String get createChallengeDescribeTheChallenge => '챌린지 설명...';

  @override
  String get createChallengeDescriptionOptional => '설명 (선택 사항)';

  @override
  String get createChallengeEG30 => '예: 30';

  @override
  String get createChallengeEG30Day => '예: 30일 운동 연속 기록';

  @override
  String get createChallengeEGWorkouts => '예: 운동';

  @override
  String get createChallengeEndDate => '종료일';

  @override
  String get createChallengePublicChallenge => '공개 챌린지';

  @override
  String get createChallengeStartDate => '시작일';

  @override
  String get createChallengeUnit => '단위';

  @override
  String get createExerciseAdd => '추가';

  @override
  String get createExerciseAddAtLeast2 => '최소 2개의 운동을 추가하세요';

  @override
  String get createExerciseAddExercise => '운동 추가';

  @override
  String get createExerciseAddPhoto => '사진 추가';

  @override
  String get createExerciseAdvancedOptional => '고급 (선택 사항)';

  @override
  String get createExerciseAiFilledExerciseDetails =>
      'AI가 운동 세부 정보를 채웠습니다. 검토 후 저장하세요';

  @override
  String get createExerciseAnalyzeWithAi => 'AI로 분석';

  @override
  String get createExerciseAnalyzing => '분석 중...';

  @override
  String get createExerciseAnySpecialInstructions => '특별한 지침...';

  @override
  String get createExerciseBand => '밴드';

  @override
  String get createExerciseChooseFromGallery => '갤러리에서 선택';

  @override
  String get createExerciseCombo => '콤보';

  @override
  String get createExerciseCreateExercise => '운동 생성';

  @override
  String get createExerciseDescribeHowToPerform => '이 운동 수행 방법을 설명하세요...';

  @override
  String get createExerciseEGBenchPress => '예: 벤치 프레스 & 체스트 플라이 슈퍼세트';

  @override
  String get createExerciseEGBenchPress2 => '예: 벤치 프레스';

  @override
  String get createExerciseEGFocusOn => '예: 상단에서 수축에 집중, 천천히 이완';

  @override
  String get createExerciseEGMyCustom => '예: 나만의 프레스';

  @override
  String get createExerciseExerciseName => '운동 이름';

  @override
  String get createExerciseNotes => '메모';

  @override
  String get createExerciseReps => '횟수: ';

  @override
  String get createExerciseRestRpeTempoIncline =>
      '휴식, RPE, 템포, 경사도, 거리, 시간, 메모';

  @override
  String createExerciseSheetAddMoreExercises(Object length) {
    return '$length개의 운동 추가';
  }

  @override
  String createExerciseSheetExercises(Object length) {
    return '운동 ($length)';
  }

  @override
  String createExerciseSheetFailedToAnalyzePhoto(Object e) {
    return '사진 분석 실패: $e';
  }

  @override
  String get createExerciseSimple => '단일';

  @override
  String get createExerciseTakePhoto => '사진 촬영';

  @override
  String get createGoalChallengeYourselfToBeat => '개인 최고 기록 경신에 도전하세요!';

  @override
  String get createGoalExercise => '운동';

  @override
  String get createGoalGoalType => '목표 유형';

  @override
  String get createGoalMaxReps => '최대 횟수';

  @override
  String get createGoalOneSetMaxEffort => '1세트 최대 노력';

  @override
  String get createGoalOrTypeCustomExercise => '또는 사용자 지정 운동 입력...';

  @override
  String get createGoalPleaseEnterAValid => '유효한 목표를 입력하세요';

  @override
  String get createGoalPleaseEnterAnExercise => '운동 이름을 입력하세요';

  @override
  String get createGoalSetGoal => '목표 설정';

  @override
  String get createGoalSetWeeklyGoal => '주간 목표 설정';

  @override
  String createGoalSheetTargetBestInOne(Object fullLabel) {
    return '$fullLabel 목표 (한 세션 최고 기록)';
  }

  @override
  String createGoalSheetTargetTotalThisWeek(Object fullLabel) {
    return '$fullLabel 목표 (이번 주 합계)';
  }

  @override
  String get createGoalTotalRepsThisWeek => '이번 주 총 횟수';

  @override
  String get createGoalUnit => '단위';

  @override
  String get createGoalWeeklyVolume => '주간 볼륨';

  @override
  String get createHabitBreak => '나쁜 습관 끊기';

  @override
  String get createHabitBuild => '좋은 습관 만들기';

  @override
  String get createHabitCategory => '카테고리';

  @override
  String get createHabitColor => '색상';

  @override
  String get createHabitCreateHabit => '습관 생성';

  @override
  String get createHabitDescriptionOptional => '설명 (선택 사항)';

  @override
  String get createHabitEG8 => '예: 8';

  @override
  String get createHabitEGDrink8 => '예: 물 8잔 마시기';

  @override
  String get createHabitEGGlasses => '예: 잔';

  @override
  String get createHabitEditHabit => '습관 편집';

  @override
  String get createHabitFrequency => '빈도';

  @override
  String get createHabitHabitName => '습관 이름';

  @override
  String get createHabitHabitType => '습관 유형';

  @override
  String get createHabitSaveChanges => '변경 사항 저장';

  @override
  String get createHabitTargetOptional => '목표 (선택 사항)';

  @override
  String get createHabitUnitOptional => '단위 (선택 사항)';

  @override
  String get createPostEditPost => '게시물 편집';

  @override
  String get createPostHideExercises => '운동 숨기기';

  @override
  String get createPostPost => '게시';

  @override
  String get createPostSheetAddMore => '더 추가';

  @override
  String get createPostSheetCamera => '카메라';

  @override
  String get createPostSheetCaption => '캡션';

  @override
  String get createPostSheetGallery => '갤러리';

  @override
  String get createPostSheetMediaOptional => '미디어 (선택 사항)';

  @override
  String get createPostSheetShareYourFitnessJourney => '당신의 피트니스 여정을 공유하세요...';

  @override
  String get createPostSheetTrending => '트렌딩';

  @override
  String get createPostSheetVideo => '비디오';

  @override
  String get createPostShowExercises => '운동 보기';

  @override
  String get createPostTags => '태그';

  @override
  String get createPostWhoCanSeeThis => '공개 범위';

  @override
  String get createPostWorkoutStats => '운동 통계';

  @override
  String credibilityStripJoinPeopleTrainingWith(Object formatted) {
    return 'Zealova로 운동하는 $formatted+명의 사람들과 함께하세요';
  }

  @override
  String credibilityStripRatings(Object count, Object rating) {
    return '$rating · 평가 $count개';
  }

  @override
  String credibilityStripValue(Object quote) {
    return '\"$quote\"';
  }

  @override
  String get customCoachFormCoachName => '코치 이름';

  @override
  String get customCoachFormCoachingStyle => '코칭 스타일';

  @override
  String get customCoachFormCommunicationTone => '소통 어조';

  @override
  String get customCoachFormEGMyCoach => '예: 마이 코치, 에이스 등';

  @override
  String get customCoachFormEncouragementLevel => '격려 수준';

  @override
  String get customCoachFormMaximum => '최대';

  @override
  String get customCoachFormMinimal => '최소';

  @override
  String customColorLabCardMatched(Object displayName) {
    return '일치: $displayName';
  }

  @override
  String get customColorLabCustomColorLab => '사용자 지정 색상 연구소';

  @override
  String get customColorLabFineTuneAccentColor => 'HSV 선택기로 강조 색상 미세 조정';

  @override
  String get customContentAddYourOwnEquipment => '나만의 장비와 운동 추가';

  @override
  String get customContentMyCustomContent => '내 사용자 지정 콘텐츠';

  @override
  String get customContentSectionAdd => '추가';

  @override
  String get customContentSectionAddCustomExercise => '사용자 지정 운동 추가';

  @override
  String get customContentSectionAddEquipmentAboveTo => '시작하려면 위에서 장비를 추가하세요';

  @override
  String get customContentSectionAddEquipmentNotIn => '표준 목록에 없는 장비 추가';

  @override
  String get customContentSectionAddEquipmentThatWill =>
      'AI 생성 운동에 포함될 장비를 추가하세요.';

  @override
  String get customContentSectionAddExercise => '운동 추가';

  @override
  String get customContentSectionCompoundExercise => '복합 운동';

  @override
  String get customContentSectionCreateCustomComboExercise =>
      '사용자 지정 및 콤보 운동 생성';

  @override
  String get customContentSectionCreateExercisesThatCan =>
      'AI 생성 운동에 포함할 수 있는 운동을 만드세요.';

  @override
  String get customContentSectionDeleteExercise => '운동을 삭제할까요?';

  @override
  String get customContentSectionDescribeHowToPerform => '수행 방법 설명...';

  @override
  String get customContentSectionEGPikePush => '예: Pike Push-ups';

  @override
  String get customContentSectionEnterEquipmentName => '기구 이름 입력...';

  @override
  String get customContentSectionFailedToLoadExercises => '운동 목록을 불러오지 못했습니다';

  @override
  String get customContentSectionInstructionsOptional => '설명 (선택 사항)';

  @override
  String get customContentSectionMyCustomEquipment => '내 맞춤 기구';

  @override
  String get customContentSectionMyCustomExercises => '내 맞춤 운동';

  @override
  String get customContentSectionMyEquipment => '내 기구';

  @override
  String get customContentSectionMyExercises => '내 운동';

  @override
  String get customContentSectionNoCustomEquipmentYet => '아직 맞춤 기구가 없습니다';

  @override
  String get customContentSectionNoCustomExercisesYet => '아직 맞춤 운동이 없습니다';

  @override
  String customContentSectionPartCustomContentCardAddedToYourEquipment(
    Object trimmed,
  ) {
    return '\"$trimmed\"을(를) 장비에 추가했습니다';
  }

  @override
  String customContentSectionPartCustomContentCardAreYouSureYou(Object name) {
    return '\"$name\"을(를) 정말 삭제하시겠습니까?';
  }

  @override
  String customContentSectionPartCustomContentCardDeleted(Object name) {
    return '\"$name\" 삭제됨';
  }

  @override
  String customContentSectionPartCustomContentCardFailedToSave(Object e) {
    return '저장 실패: $e';
  }

  @override
  String customContentSectionPartCustomContentCardIsAlreadyInYour(
    Object trimmed,
  ) {
    return '$trimmed은(는) 이미 목록에 있습니다';
  }

  @override
  String customContentSectionPartCustomContentCardRemoved(Object name) {
    return '\"$name\" 삭제됨';
  }

  @override
  String get customContentSectionReps => '횟수';

  @override
  String get customContentSectionSets => '세트';

  @override
  String get customContentSectionTapTheButtonAbove => '위 버튼을 눌러 생성하세요';

  @override
  String get customContentSectionTargetsMultipleMuscleGroups => '여러 근육군을 타겟팅';

  @override
  String get customExerciseCard => ' • ';

  @override
  String customExerciseCardExercises(Object componentCount) {
    return '운동 $componentCount개';
  }

  @override
  String customExerciseCardUsedTimes(Object usageCount) {
    return '$usageCount회 사용됨';
  }

  @override
  String get customExercisesAll => '전체';

  @override
  String get customExercisesCombos => '콤보';

  @override
  String get customExercisesComponents => '구성 요소';

  @override
  String get customExercisesCreate => '생성';

  @override
  String get customExercisesDeleteExercise => '운동 삭제';

  @override
  String get customExercisesMyExercises => '내 운동';

  @override
  String get customExercisesNoExercisesMatchYour => '검색 결과가 없습니다';

  @override
  String customExercisesScreenAreYouSureYou(Object name) {
    return '\"$name\"을(를) 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String customExercisesScreenExercisesUses(
    Object totalCustomExercises,
    Object totalUses,
  ) {
    return '운동 $totalCustomExercises개, 사용 횟수 $totalUses회';
  }

  @override
  String get customExercisesSearchExercises => '운동 검색...';

  @override
  String get customExercisesSimple => '단일';

  @override
  String get customFoodBuilderAiFillFromName => '이름으로 AI 자동 채우기';

  @override
  String get customFoodBuilderAiIsSuggesting => 'AI가 제안 중...';

  @override
  String get customFoodBuilderAlreadyInYourLibrary => '이미 라이브러리에 있습니다';

  @override
  String get customFoodBuilderBrandOptional => '브랜드 (선택 사항)';

  @override
  String get customFoodBuilderCreateCustomFood => '맞춤 음식 생성';

  @override
  String get customFoodBuilderCreateNewAnyway => '그래도 새로 생성';

  @override
  String get customFoodBuilderFillItInYourself =>
      '직접 입력하거나, 이름 또는 라벨 사진으로 AI의 제안을 받아보세요. 모든 값은 수정 가능합니다.';

  @override
  String get customFoodBuilderLabelFromPhotos => '사진에서 라벨 추출';

  @override
  String get customFoodBuilderName => '이름';

  @override
  String get customFoodBuilderSaveCustomFood => '맞춤 음식 저장';

  @override
  String get customFoodBuilderScanLabel => '라벨 스캔';

  @override
  String get customFoodBuilderServingOptional => '1회 제공량 (선택 사항)';

  @override
  String customFoodBuilderSheetAlreadyExistsAsA(Object name) {
    return '\"$name\"은(는) 이미 사용자 지정 음식으로 존재합니다';
  }

  @override
  String customFoodBuilderSheetNeedsEntry(Object label) {
    return '$label  •  입력 필요';
  }

  @override
  String get customFoodBuilderUseExisting => '기존 항목 사용';

  @override
  String get customGoalsAddSpecificSkillsOr =>
      '향상시키고 싶은 특정 기술이나 목표를 추가하세요.\nAI가 적절한 운동을 찾는 데 도움을 드립니다.';

  @override
  String get customGoalsAiGeneratedKeywords => 'AI 생성 키워드';

  @override
  String get customGoalsCustomGoals => '맞춤 목표';

  @override
  String get customGoalsDeleteGoal => '목표를 삭제할까요?';

  @override
  String get customGoalsEGImproveBox => '예: \"박스 점프 높이 향상\"';

  @override
  String get customGoalsGoalCreated => '목표가 생성되었습니다!';

  @override
  String get customGoalsGotIt => '확인했습니다';

  @override
  String get customGoalsNoCustomGoalsYet => '아직 맞춤 목표가 없습니다';

  @override
  String customGoalsScreenAreYouSureYou(Object goalText) {
    return '\"$goalText\"을(를) 삭제하시겠습니까?';
  }

  @override
  String get customGoalsSomethingWentWrong => '문제가 발생했습니다';

  @override
  String get customGoalsTheseKeywordsWillHelp =>
      '이 키워드들은 목표에 맞는 운동을 찾는 데 도움이 됩니다.';

  @override
  String get customTrendAddMetric => '지표 추가';

  @override
  String get customTrendAlreadySaved => '이미 저장됨';

  @override
  String get customTrendCompareLastCycle => '지난 주기와 비교';

  @override
  String get customTrendCompareLastCycleNeeds => '지난 주기와 비교 · 범위 내 최소 2주기 필요';

  @override
  String get customTrendCustomTrendSaved => '맞춤 트렌드 저장됨';

  @override
  String get customTrendCustomTrends => '맞춤 트렌드';

  @override
  String get customTrendCyclePhases => '주기 단계';

  @override
  String get customTrendSaveThisTrend => '이 트렌드 저장';

  @override
  String customTrendScreenCorrelationVs(Object displayName) {
    return '$displayName와의 상관관계';
  }

  @override
  String customTrendScreenCouldnTLoad(Object name) {
    return '$name을(를) 불러올 수 없습니다';
  }

  @override
  String customTrendScreenLastCycle(Object displayName) {
    return '$displayName · 지난 주기';
  }

  @override
  String customTrendScreenMaxOverlaysRemoveOne(Object _kMaxOverlays) {
    return '최대 $_kMaxOverlays개의 오버레이만 가능합니다. 하나를 제거하고 추가하세요.';
  }

  @override
  String customTrendScreenSharedDays(
    Object kMinCorrelationPairs,
    Object pairedPoints,
  ) {
    return '$pairedPoints/$kMinCorrelationPairs 공유 일수';
  }

  @override
  String get customWorkoutBuilderAddExercise => '운동 추가';

  @override
  String get customWorkoutBuilderBuildCustomWorkout => '맞춤 운동 구성';

  @override
  String get customWorkoutBuilderCustomWorkoutCreated => '맞춤 운동이 생성되었습니다!';

  @override
  String get customWorkoutBuilderDifficulty => '난이도';

  @override
  String get customWorkoutBuilderExercise => '운동';

  @override
  String get customWorkoutBuilderFailedToCreateWorkout => '운동 생성 실패';

  @override
  String get customWorkoutBuilderNoExercisesAddedYet => '아직 추가된 운동이 없습니다';

  @override
  String get customWorkoutBuilderPleaseAddAtLeast => '최소 하나의 운동을 추가해주세요';

  @override
  String get customWorkoutBuilderPleaseEnterAWorkout => '운동 이름을 입력해주세요';

  @override
  String get customWorkoutBuilderReps => '횟수';

  @override
  String get customWorkoutBuilderScheduleFor => '일정:';

  @override
  String customWorkoutBuilderScreenExercises(Object length) {
    return '운동 ($length)';
  }

  @override
  String customWorkoutBuilderScreenIsAlreadyInYour(Object name) {
    return '$name은(는) 이미 운동 목록에 있습니다';
  }

  @override
  String get customWorkoutBuilderSearchExercises => '운동 검색...';

  @override
  String get customWorkoutBuilderSets => '세트';

  @override
  String get customWorkoutBuilderTapTheButtonBelow => '아래 버튼을 눌러 운동을 추가하세요';

  @override
  String get customWorkoutBuilderWeightKg => '무게 (kg)';

  @override
  String get customWorkoutBuilderWorkoutName => '운동 이름';

  @override
  String get customWorkoutBuilderWorkoutType => '운동 유형';

  @override
  String get customizeRingsAdd => '추가';

  @override
  String get customizeRingsCore => '코어';

  @override
  String get customizeRingsCustomizeYourRings => '링 커스터마이징';

  @override
  String get customizeRingsResetToDefault => '기본값으로 재설정';

  @override
  String get cycleAiInsightTellMeMore => '더 알아보기';

  @override
  String get cycleAskYourCycleCoach => '사이클 코치에게 물어보기';

  @override
  String get cycleCalendar => '캘린더';

  @override
  String get cycleConceptionMeterChanceOfConception => '임신 가능성';

  @override
  String get cycleCycle => '주기';

  @override
  String get cycleDayDetailAskCoach => '코치에게 물어보기';

  @override
  String get cycleDayDetailEditThisDay => '오늘 기록 수정';

  @override
  String cycleDayDetailSheetPhase(Object displayName) {
    return '$displayName 단계';
  }

  @override
  String get cycleDayDetailThisDayIsIn => '미래의 날짜입니다.';

  @override
  String get cycleDisclaimerBeforeYouStart => '시작하기 전에';

  @override
  String get cycleInsights => '인사이트';

  @override
  String get cycleInsightsChartsAsk => '질문하기';

  @override
  String get cycleInsightsChartsCycleLengthHistory => '주기 길이 기록';

  @override
  String get cycleInsightsChartsCycleStats => '주기 통계';

  @override
  String cycleInsightsChartsD(Object days) {
    return '$days일';
  }

  @override
  String cycleInsightsChartsDays(Object stddev) {
    return '(±$stddev일).';
  }

  @override
  String cycleInsightsChartsDaysVariability(Object avg) {
    return '평균 $avg일, 변동성 ';
  }

  @override
  String cycleInsightsChartsMyCycleStatsCycles(Object cyclesTracked) {
    return '내 주기 통계 — $cyclesTracked 주기 기록됨, ';
  }

  @override
  String get cycleInsightsChartsPhaseDistribution => '단계별 분포';

  @override
  String get cycleInsightsChartsSymptomPatterns => '증상 패턴';

  @override
  String cycleInsightsChartsValue(Object pct) {
    return '$pct%';
  }

  @override
  String get cycleMonthlySummaryThisRecapStaysPrivate =>
      '이 요약은 본인만 볼 수 있으며, 주기 데이터는 절대 공유되지 않습니다.';

  @override
  String get cycleMonthlySummaryYourMonthInReview => '이번 달 요약';

  @override
  String get cycleOnboardingGeneralTracking => '일반 추적';

  @override
  String cycleOnboardingSheetDays(Object _cycleLength) {
    return '$_cycleLength일';
  }

  @override
  String cycleOnboardingSheetDays2(Object _periodLength) {
    return '$_periodLength일';
  }

  @override
  String get cycleOnboardingStartTracking => '추적 시작';

  @override
  String get cycleOnboardingTrackYourCycle => '주기 추적하기';

  @override
  String get cycleOnboardingTryingToConceive => '임신 준비 중';

  @override
  String get cycleOnboardingTypicalCycleLength => '평균 주기 길이';

  @override
  String get cycleOnboardingTypicalPeriodLength => '평균 생리 기간';

  @override
  String get cycleOpen => '열기';

  @override
  String get cyclePeriodSavedYourCoach => '생리 기록이 저장되었습니다. 코치가 인사이트를 업데이트했습니다.';

  @override
  String get cyclePhaseChartGotIt => '확인';

  @override
  String get cyclePhaseRingAskCoachAboutThis => '코치에게 물어보기';

  @override
  String cyclePhaseRingCycleDay(Object day) {
    return '생리 주기 $day일차';
  }

  @override
  String cyclePhaseRingEstimate(Object cycleConfidence) {
    return '$cycleConfidence · 예상';
  }

  @override
  String get cyclePhaseRingNoData => '데이터 없음';

  @override
  String cycleScreenCouldNotSwitchMode(Object e) {
    return '모드를 전환할 수 없습니다: $e';
  }

  @override
  String cycleScreenIJustLoggedMy(Object what) {
    return '$what을(를) 방금 기록했어요. 알아두어야 할 점이 있나요?';
  }

  @override
  String cycleScreenSwitchedTo(Object displayName) {
    return '$displayName(으)로 전환되었습니다';
  }

  @override
  String get cycleScreenUiCheckYourConnectionAnd => '연결 상태를 확인하고 다시 시도하세요.';

  @override
  String get cycleScreenUiCouldnTLoadYour => '주기 데이터를 불러올 수 없습니다';

  @override
  String get cycleScreenUiDailyCheckIn => '일일 체크인';

  @override
  String get cycleScreenUiLogAPeriod => '생리 기록하기';

  @override
  String get cycleScreenUiLogPeriod => '생리 기록';

  @override
  String get cycleScreenUiLogYourFirstPeriod => '첫 생리일을 기록하여 예측을 시작하세요.';

  @override
  String cycleScreenUiPhaseLabel(Object displayName) {
    return '$displayName 단계';
  }

  @override
  String get cycleScreenUiPredictionsAreEstimates =>
      '예측은 기록된 데이터를 기반으로 한 추정치이며, 피임 방법이나 의학적 조언이 아닙니다. 건강 관련 우려 사항은 전문의와 상담하세요.';

  @override
  String get cycleScreenUiPregnancyModeIsOn => '임신 모드 활성화됨';

  @override
  String get cycleScreenUiRetry => '재시도';

  @override
  String get cycleScreenUiStartTracking => '추적 시작';

  @override
  String cycleScreenUiSuggestedTraining(Object intensity) {
    return '권장 훈련: $intensity';
  }

  @override
  String get cycleSettingsAMorningNudgeTo => 'BBT 기록을 위한 아침 알림';

  @override
  String get cycleSettingsAnEveningNudgeTo => '오늘의 컨디션 기록을 위한 저녁 알림';

  @override
  String get cycleSettingsBestTakenBeforeGetting => '기상 직후 측정 권장';

  @override
  String get cycleSettingsCalendarPredictionsLogging => '캘린더, 예측, 기록 및 인사이트';

  @override
  String get cycleSettingsCheckInTime => '체크인 시간';

  @override
  String get cycleSettingsCycle => '주기';

  @override
  String get cycleSettingsCycleAwarePhotoReminders => '주기 맞춤형 사진 알림';

  @override
  String get cycleSettingsCycleReminders => '주기 알림';

  @override
  String get cycleSettingsCycleTracking => '주기 추적';

  @override
  String get cycleSettingsDailyTemperatureReminder => '일일 체온 알림';

  @override
  String get cycleSettingsDaysBefore => '일 전';

  @override
  String get cycleSettingsFertileWindow => '가임기';

  @override
  String get cycleSettingsMasterSwitchForAll => '모든 주기 알림 통합 스위치';

  @override
  String get cycleSettingsOnYourPredictedPeriod => '예상 생리 시작일에';

  @override
  String get cycleSettingsOpenCycle => '주기 열기';

  @override
  String get cycleSettingsPeakFertility => '배란기';

  @override
  String get cycleSettingsPeriodApproaching => '생리 예정일 알림';

  @override
  String get cycleSettingsPeriodRunningLate => '생리 지연 알림';

  @override
  String get cycleSettingsPeriodStartDay => '생리 시작일';

  @override
  String get cycleSettingsReminderTime => '알림 시간';

  @override
  String cycleSettingsScreenAHeadsUp(Object cyclePeriodApproachingLeadDays) {
    return '$cyclePeriodApproachingLeadDays일 전 알림';
  }

  @override
  String get cycleSettingsSymptomCheckIn => '증상 체크인';

  @override
  String get cycleSettingsTemperatureReminderTime => '체온 알림 시간';

  @override
  String get cycleSettingsWhenTheRemindersAbove => '위 알림이 발송될 시간';

  @override
  String get cycleSetupHomeDismiss => '닫기';

  @override
  String get cycleSetupHomeSetUp => '설정';

  @override
  String get cycleSetupHomeTrackYourCycle => '주기 추적하기';

  @override
  String get cycleStatusCardCycle => '주기';

  @override
  String get cycleStatusCardCycleTracking => '주기 추적';

  @override
  String cycleStatusCardDay(Object day) {
    return '· $day일차';
  }

  @override
  String get cycleStatusCardLogPeriod => '생리 기록';

  @override
  String get cycleStatusCardViewCycle => '주기 보기';

  @override
  String get cycleSuggestedChipsAskYourCoach => '코치에게 물어보기';

  @override
  String get cycleSwitchHowTheCycle => '현재 상태에 맞춰 주기 화면 작동 방식을 변경하세요.';

  @override
  String get cycleTemperatureChartAsk => '질문하기';

  @override
  String get cycleTemperatureChartBasalTemperature => '기초 체온';

  @override
  String get cycleTemperatureChartDragAcrossTheChart =>
      '차트를 드래그하여 특정 날짜를 확인하세요';

  @override
  String get cycleTemperatureChartLogBasalTemperatureTo =>
      '기초 체온을 기록하여 차트를 채우세요';

  @override
  String get cycleToday => '오늘';

  @override
  String get cycleTrackerCycleTracker => '주기 추적기';

  @override
  String get cycleTrackerDay1 => '1일차';

  @override
  String get cycleTrackerLogPeriod => '생리 기록';

  @override
  String cycleTrackerWidgetDay(Object cycleLength) {
    return '$cycleLength일차';
  }

  @override
  String cycleTrackerWidgetValue(Object label) {
    return '$label: ';
  }

  @override
  String get cycleTrackingMode => '추적 모드';

  @override
  String get dailyActivityCardActiveCal => '활동 칼로리';

  @override
  String dailyActivityCardConnectToSeeSteps(Object healthName) {
    return '$healthName을(를) 연결하여 걸음 수, 칼로리 등을 확인하세요';
  }

  @override
  String get dailyActivityCardDailyGoal => '일일 목표';

  @override
  String get dailyActivityCardFromAppleHealth => 'Apple Health에서 가져옴';

  @override
  String get dailyActivityCardFromHealthConnect =>
      'Google Health Connect에서 가져옴';

  @override
  String get dailyActivityCardRestingHr => '안정 시 심박수';

  @override
  String get dailyActivityCardSteps => '걸음 수';

  @override
  String get dailyActivityCardTodaySActivity => '오늘의 활동';

  @override
  String get dailyActivityCardTrackYourActivity => '활동 기록하기';

  @override
  String get dailyCalories => '칼로리';

  @override
  String get dailyCarbohydrates => '탄수화물';

  @override
  String get dailyCookedDish => '조리된 요리';

  @override
  String get dailyCrateBannerActivityCrate => '활동 상자';

  @override
  String get dailyCrateBannerBasicRewards => '기본 보상';

  @override
  String get dailyCrateBannerChoose1CrateTo => '오늘 열 상자 1개를 선택하세요';

  @override
  String get dailyCrateBannerDailyCrate => '일일 상자';

  @override
  String get dailyCrateBannerDailyCratesAvailable => '일일 상자를 사용할 수 있습니다!';

  @override
  String get dailyCrateBannerFailedToClaimCrate => '상자 수령 실패';

  @override
  String get dailyCrateBannerPickYourDailyCrate => '🎁 일일 상자 선택하기';

  @override
  String get dailyCrateBannerStreakCrate => '연속 기록 상자';

  @override
  String get dailyCrateBannerTapToPickYour => '탭하여 보상을 선택하세요';

  @override
  String get dailyEditGoalsInSettings => '설정에서 목표 수정';

  @override
  String get dailyExpired => '만료됨';

  @override
  String get dailyFailedToUpdatePinned => '고정된 영양소 업데이트 실패';

  @override
  String get dailyFat => '지방';

  @override
  String get dailyFiber => '식이섬유';

  @override
  String get dailyLeftoversReadyToLog => '기록할 남은 음식';

  @override
  String get dailyPickTheNutrientsYou => 'Daily 탭 상단에 표시할 영양소를 선택하세요.';

  @override
  String get dailyPinNutrients => '영양소 고정';

  @override
  String get dailyPlanDetailCalories => '칼로리';

  @override
  String get dailyPlanDetailCarbs => '탄수화물';

  @override
  String get dailyPlanDetailCompleted => '완료됨';

  @override
  String get dailyPlanDetailEatingEnds => '식사 종료';

  @override
  String get dailyPlanDetailEatingStarts => '식사 시작';

  @override
  String get dailyPlanDetailFastingWindow => '단식 시간';

  @override
  String get dailyPlanDetailFat => '지방';

  @override
  String get dailyPlanDetailMealSuggestions => '식단 추천';

  @override
  String get dailyPlanDetailMealsRegenerated => '식단이 새로 생성되었습니다!';

  @override
  String get dailyPlanDetailNotesWarnings => '참고 및 주의사항';

  @override
  String get dailyPlanDetailNutritionTargets => '영양 목표';

  @override
  String get dailyPlanDetailProtein => '단백질';

  @override
  String get dailyPlanDetailRefresh => '새로고침';

  @override
  String get dailyPlanDetailScheduledWorkout => '예정된 운동';

  @override
  String dailyPlanDetailSheetCal(Object calories) {
    return '$calories kcal';
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
    return '$fastingDurationHours시간 단식';
  }

  @override
  String dailyPlanDetailSheetMin(Object workoutDurationMinutes) {
    return '$workoutDurationMinutes분';
  }

  @override
  String dailyPlanDetailSheetValue(Object amount, Object name) {
    return '$name ($amount)';
  }

  @override
  String get dailyPlanDetailStartWorkout => '운동 시작';

  @override
  String get dailyProtein => '단백질';

  @override
  String dailyStatsCardCalBurnedFromExercise(Object caloriesBurned) {
    return '운동으로 $caloriesBurned cal 소모';
  }

  @override
  String get dailyStatsCardDailyStats => '일일 통계';

  @override
  String get dailyStatsCardLoadingStats => '통계 불러오는 중...';

  @override
  String get dailyStatsCardStepsGoal => '걸음 수 목표';

  @override
  String dailyTabFailedToLog(Object e) {
    return '기록 실패: $e';
  }

  @override
  String dailyTabLogged(Object name) {
    return '$name 기록됨';
  }

  @override
  String dailyTabLogged2(Object ev) {
    return '$ev 기록됨';
  }

  @override
  String dailyTabOfLeft(Object portionsMade, Object portionsRemaining) {
    return '$portionsMade 중 $portionsRemaining 남음';
  }

  @override
  String dailyTabPinned(Object length) {
    return '$length개 고정됨';
  }

  @override
  String get dailyTapSettingsIconTo => '설정 아이콘을 탭하여 목표를 조정하세요';

  @override
  String get dailyTapToLog => '탭하여 기록';

  @override
  String dailyXpStripTodayGoals(Object completed, Object total) {
    return '오늘: $completed/$total 목표 완료';
  }

  @override
  String dailyXpStripX(Object multiplier) {
    return '${multiplier}x';
  }

  @override
  String dailyXpStripXp(Object xpEarned) {
    return '+$xpEarned XP';
  }

  @override
  String get dailyYourDailyGoals => '일일 목표';

  @override
  String get dangerZoneDangerZone => '위험 구역';

  @override
  String get dangerZoneDeleteAccount => '계정 삭제';

  @override
  String get dangerZoneDeleteWorkoutsKeepAccount => '운동 기록 삭제, 계정 유지';

  @override
  String get dangerZonePermanentlyDeleteAllData => '모든 데이터 영구 삭제';

  @override
  String get dangerZoneResetProgram => '프로그램 초기화';

  @override
  String get dangerZoneResetProgram2 => '프로그램을 초기화할까요?';

  @override
  String get dangerZoneThisWill => '이 작업은 다음을 수행합니다:';

  @override
  String get dangerZoneYourCompletedWorkoutHistory => '완료된 운동 기록은 보존됩니다.';

  @override
  String get dataManagementAutoRenewalActive => '자동 갱신 활성화됨';

  @override
  String get dataManagementDataManagement => '데이터 관리';

  @override
  String get dataManagementDownloadThisWeekS => '이번 주 영상 다운로드';

  @override
  String get dataManagementDownloadYourWorkoutNutrit => '운동 및 영양 데이터 다운로드';

  @override
  String get dataManagementDownloadedVideos => '다운로드된 영상';

  @override
  String get dataManagementExportMyWorkouts => '내 운동 기록 내보내기';

  @override
  String get dataManagementHevyStrongFitbodPdf =>
      'Hevy / Strong / Fitbod / PDF / GPX — 어디서든 확인하세요';

  @override
  String get dataManagementLifetimeAccess => '평생 이용권';

  @override
  String get dataManagementManageDuplicateImports => '중복 가져오기 관리';

  @override
  String get dataManagementManageOfflineExerciseVideos => '오프라인 운동 영상 관리';

  @override
  String get dataManagementNoExercisesFoundIn => '계획에 포함된 운동이 없습니다.';

  @override
  String get dataManagementNoUpcomingChargesYou =>
      '예정된 결제가 없습니다 - 평생 이용권이 있습니다';

  @override
  String get dataManagementNoVideoUrlsAvailable => '계획에 사용할 수 있는 영상 URL이 없습니다.';

  @override
  String get dataManagementPreCacheAllExercises =>
      '오프라인 사용을 위해 계획의 모든 운동을 미리 캐시';

  @override
  String get dataManagementRePickThePrimary =>
      '동일한 운동이 두 번 동기화된 경우 기본 소스를 다시 선택하세요';

  @override
  String get dataManagementRequestRefund => '환불 요청';

  @override
  String dataManagementSectionExportData(Object appName) {
    return '$appName 데이터 내보내기';
  }

  @override
  String dataManagementSectionFinishedQueuingDownloads(Object length) {
    return '✅ $length개의 다운로드 대기열 추가 완료';
  }

  @override
  String dataManagementSectionImportData(Object appName) {
    return '$appName 데이터 가져오기';
  }

  @override
  String dataManagementSectionPlan(Object tierName) {
    return '$tierName 플랜';
  }

  @override
  String dataManagementSectionQueuingVideosForDownload(Object length) {
    return '$length개의 동영상 다운로드 대기 중...';
  }

  @override
  String dataManagementSectionRestoreFromABackup(Object appName) {
    return '$appName 백업 ZIP에서 복원';
  }

  @override
  String get dataManagementSignInToDownload => '로그인하여 주간 계획을 다운로드하세요.';

  @override
  String get dataManagementSubmitARefundRequest => '환불 요청 제출';

  @override
  String get dataManagementSubscription => '구독';

  @override
  String get dataManagementUpcomingRenewal => '갱신 예정';

  @override
  String get dataSyncClearAllCaches => '모든 캐시 지우기';

  @override
  String get dataSyncDeviceInfo => '기기 정보';

  @override
  String get dataSyncFreeMemoryByClearing => '메모리 내 캐시를 지워 메모리 확보';

  @override
  String get dataSyncLoading => '불러오는 중...';

  @override
  String get dataSyncNotificationTester => '알림 테스트';

  @override
  String get dataSyncSendTestNotifications => '테스트 알림 보내기';

  @override
  String get dateRangeFilterApply => '적용';

  @override
  String get dateRangeFilterCustom => '사용자 지정';

  @override
  String get dateRangeFilterSelectDateRange => '날짜 범위 선택';

  @override
  String get dateStripPickADate => '날짜 선택';

  @override
  String dayCardNoteS(Object length) {
    return '메모 $length개';
  }

  @override
  String get deleteAccountFlowActiveSubscription => '활성 구독';

  @override
  String get deleteAccountFlowConfirmWithYourPassword => '비밀번호로 확인';

  @override
  String get deleteAccountFlowDeleteAccount => '계정을 삭제할까요?';

  @override
  String get deleteAccountFlowDeleteAccount2 => '계정 삭제';

  @override
  String get deleteAccountFlowDeleteAnyway => '삭제 진행';

  @override
  String deleteAccountFlowDeletingYourAccountDoes(Object storeName) {
    return '계정을 삭제해도 $storeName 구독은 취소되지 않습니다. ';
  }

  @override
  String deleteAccountFlowOpen(Object storeName) {
    return '$storeName 열기';
  }

  @override
  String get deleteAccountFlowPleaseEnterYourPassword => '비밀번호를 입력하세요';

  @override
  String get deleteAccountFlowReAuthenticationRequired => '재인증 필요';

  @override
  String get deleteAccountFlowResetPassword => '비밀번호 재설정';

  @override
  String get deleteAccountFlowSignInAgain => '다시 로그인';

  @override
  String get deleteAccountFlowThisActionCannotBe => '이 작업은 되돌릴 수 없습니다!';

  @override
  String get deleteAccountFlowThisWillPermanentlyDelete =>
      '다음 항목이 영구적으로 삭제됩니다:';

  @override
  String get deleteAccountFlowWeCouldNotVerify =>
      '비밀번호를 확인할 수 없습니다. 비밀번호를 재설정한 후 다시 계정 삭제를 시도하세요.';

  @override
  String deleteAccountFlowYouWillContinueTo(Object storeName) {
    return '먼저 $storeName에서 취소하지 않으면 계속 요금이 청구됩니다.\n\n';
  }

  @override
  String get deleteAccountFlowYouWillNeedTo => '앱을 사용하려면 다시 가입해야 합니다.';

  @override
  String get deleteAccountProgressDeletingYourAccount => '계정 삭제 중';

  @override
  String get deloadRecommendationCardPlanDeloadWeek => '디로딩 주 계획';

  @override
  String get demoActiveWorkoutAiCoachReview => 'AI 코치 리뷰';

  @override
  String get demoActiveWorkoutAiCoachTip => 'AI 코치 팁';

  @override
  String get demoActiveWorkoutBackToPreview => '미리보기로 돌아가기';

  @override
  String get demoActiveWorkoutCoolDown => '쿨다운';

  @override
  String get demoActiveWorkoutExercise => '운동';

  @override
  String get demoActiveWorkoutExerciseDemo => '운동 데모';

  @override
  String get demoActiveWorkoutExit => '나가기';

  @override
  String get demoActiveWorkoutExitWorkout => '운동을 종료할까요?';

  @override
  String get demoActiveWorkoutGetAiGeneratedWorkout =>
      'AI가 생성한 운동 계획을 받고, 진행 상황을 추적하여 피트니스 목표를 더 빠르게 달성하세요.';

  @override
  String get demoActiveWorkoutGetPersonalizedWorkouts => '맞춤형 운동 받기';

  @override
  String get demoActiveWorkoutGreatJobTimeTo =>
      '수고하셨습니다! 이제 스트레칭과 회복을 할 시간입니다.';

  @override
  String get demoActiveWorkoutNextExerciseComingUp => '다음 운동이 곧 시작됩니다!';

  @override
  String get demoActiveWorkoutReadyForTheFull => '전체 기능을 경험할 준비가 되셨나요?';

  @override
  String get demoActiveWorkoutRestTime => '휴식 시간';

  @override
  String demoActiveWorkoutScreenCompleteSet(Object _currentSet) {
    return '$_currentSet세트 완료';
  }

  @override
  String demoActiveWorkoutScreenUi1Reps(Object _currentExerciseReps) {
    return '$_currentExerciseReps회';
  }

  @override
  String demoActiveWorkoutScreenUi1SetOf(
    Object _currentExerciseSets,
    Object _currentSet,
  ) {
    return '세트 $_currentSet/$_currentExerciseSets';
  }

  @override
  String get demoActiveWorkoutSignUpToGet =>
      '가입하고 맞춤형 AI 코칭, 상세한 진행 상황 추적, 목표에 최적화된 운동을 받아보세요.';

  @override
  String get demoActiveWorkoutSkipAll => '모두 건너뛰기';

  @override
  String get demoActiveWorkoutSkipRest => '휴식 건너뛰기';

  @override
  String get demoActiveWorkoutUpNext => '다음 순서';

  @override
  String get demoActiveWorkoutWarmUp => '웜업';

  @override
  String get demoActiveWorkoutWorkoutComplete => '운동 완료!';

  @override
  String get demoActiveWorkoutYourProgressInThis =>
      '이 데모 운동에서의 진행 상황은 저장되지 않습니다. 정말 나가시겠습니까?';

  @override
  String get demoDayBanner24HoursOfFull => '24시간 전체 이용권';

  @override
  String get demoDayBannerDemoDay => '데모 데이';

  @override
  String get demoDayBannerExploreAllPremiumFeatures =>
      '모든 프리미엄 기능 체험하기 - 부담 없이';

  @override
  String get demoDayBannerTimeRemaining => '남은 시간: ';

  @override
  String get demoTasksSeeHowTrainingWorks => '트레이닝 작동 방식 보기';

  @override
  String get demoTasksSeeItInAction => '실제 작동 모습 보기';

  @override
  String get demoTasksSnapAMenuLog => '메뉴 촬영하고 식단 기록하기';

  @override
  String get demoTasksTryOneOrBoth => '하나 또는 둘 다 시도해보세요. 원치 않으면 건너뛰어도 됩니다.';

  @override
  String get demoWorkoutCreatingYourPersonalizedWor => '맞춤형 운동 생성 중...';

  @override
  String get demoWorkoutExercises => '운동';

  @override
  String get demoWorkoutFailedToLoadWorkout => '운동을 불러오지 못했습니다';

  @override
  String get demoWorkoutFocusOnProperForm => '올바른 자세와 통제된 움직임에 집중하세요.';

  @override
  String get demoWorkoutHowToPerform => '수행 방법';

  @override
  String get demoWorkoutScreenAi => 'AI';

  @override
  String get demoWorkoutScreenBasedOnYourGoals => '목표, 장비 및 피트니스 수준 기반';

  @override
  String get demoWorkoutScreenDifficulty => '난이도';

  @override
  String get demoWorkoutScreenEquipmentNeeded => '필요한 장비';

  @override
  String get demoWorkoutScreenGetAiPersonalizedWorkouts => 'AI 맞춤형 운동 받기';

  @override
  String get demoWorkoutScreenGetPersonalizedWorkouts => '맞춤형 운동 받기';

  @override
  String get demoWorkoutScreenSampleWorkout => '샘플 운동';

  @override
  String get demoWorkoutScreenSampleWorkoutPreview => '샘플 운동 미리보기';

  @override
  String get demoWorkoutScreenSignUpToGet =>
      '가입하고 목표, 피트니스 수준, 사용 가능한 장비에 맞춘 운동을 받아보세요.';

  @override
  String get demoWorkoutScreenStartWorkout => '운동 시작';

  @override
  String get demoWorkoutScreenTryAnotherSampleWorkout => '다른 샘플 운동 시도하기';

  @override
  String get demoWorkoutScreenType => '유형';

  @override
  String demoWorkoutScreenValue(Object label) {
    return '$label: ';
  }

  @override
  String get demoWorkoutScreenYourPersonalizedWorkout => '나만의 맞춤형 운동';

  @override
  String get demoWorkoutTryAgain => '다시 시도';

  @override
  String get demoWorkoutVideo => '영상';

  @override
  String get demoWorkoutVideoUnavailable => '영상 이용 불가';

  @override
  String get derivedMetricDetailABmiBetween18 =>
      'BMI 18.5~24.9는 건강한 체중 범위로 간주됩니다. 지금처럼 계속 노력하세요!';

  @override
  String get derivedMetricDetailABmiBetween25 =>
      'BMI 25~29.9는 과체중으로 간주됩니다. 참고: BMI는 근육과 지방을 구분하지 않습니다.';

  @override
  String get derivedMetricDetailABmiOf30 =>
      'BMI 30 이상은 비만으로 분류됩니다. 전문가와 상담하여 지도를 받는 것을 고려하세요.';

  @override
  String get derivedMetricDetailAChestToWaist =>
      '가슴-허리 비율이 1.1 미만이면 허리에 비해 가슴이 좁은 편입니다. 가슴과 등 운동에 집중하세요.';

  @override
  String get derivedMetricDetailAChestToWaist2 =>
      '가슴-허리 비율 1.1~1.3은 평균입니다. 가슴과 허리의 비율이 건강합니다.';

  @override
  String get derivedMetricDetailAChestToWaist3 =>
      '가슴-허리 비율이 1.3을 초과하면 허리에 비해 가슴이 잘 발달된 상태입니다. 훌륭한 비율입니다!';

  @override
  String get derivedMetricDetailAWhtrAbove0 =>
      'WHtR이 0.6을 초과하면 복부 지방이 많고 건강 위험이 증가함을 의미합니다.';

  @override
  String get derivedMetricDetailAWhtrBetween0 =>
      'WHtR 0.4~0.5는 건강한 범위입니다. 허리 둘레가 키의 절반 미만입니다.';

  @override
  String get derivedMetricDetailAWhtrBetween02 =>
      'WHtR 0.5~0.6은 복부 지방 증가를 의미합니다. 허리 둘레를 줄이는 데 집중하세요.';

  @override
  String get derivedMetricDetailAboveAverage => '평균 이상';

  @override
  String get derivedMetricDetailAthletic => '운동선수형';

  @override
  String get derivedMetricDetailAverage => '평균';

  @override
  String get derivedMetricDetailAvg => '평균';

  @override
  String get derivedMetricDetailBasedOn => '기준';

  @override
  String get derivedMetricDetailBelowAverage => '평균 이하';

  @override
  String get derivedMetricDetailBicepsL => '이두근 (좌)';

  @override
  String get derivedMetricDetailBicepsR => '이두근 (우)';

  @override
  String get derivedMetricDetailBodyFat => '체지방';

  @override
  String get derivedMetricDetailChest => '가슴';

  @override
  String get derivedMetricDetailExcellent => '매우 우수';

  @override
  String get derivedMetricDetailGood => '좋음';

  @override
  String get derivedMetricDetailGoodSymmetry9397 =>
      '양호한 대칭성 (93-97%). 정상 범위 내의 경미한 차이입니다.';

  @override
  String get derivedMetricDetailHealthy => '건강함';

  @override
  String get derivedMetricDetailHeight => '키';

  @override
  String get derivedMetricDetailHighRisk => '고위험';

  @override
  String get derivedMetricDetailHips => '엉덩이';

  @override
  String get derivedMetricDetailHistory => '기록';

  @override
  String get derivedMetricDetailImbalanced => '불균형';

  @override
  String get derivedMetricDetailInsufficientData => '데이터 부족';

  @override
  String get derivedMetricDetailLeanMass => '제지방량';

  @override
  String get derivedMetricDetailLowRisk => '저위험';

  @override
  String get derivedMetricDetailMax => '최대';

  @override
  String get derivedMetricDetailMin => '최소';

  @override
  String get derivedMetricDetailModerate => '보통';

  @override
  String get derivedMetricDetailModerateAsymmetry8893 =>
      '보통 수준의 비대칭 (88-93%). 불균형 해소를 위해 편측 운동 추가를 고려하세요.';

  @override
  String get derivedMetricDetailModerateRisk => '중등도 위험';

  @override
  String get derivedMetricDetailMonthlyRate => '월간 비율';

  @override
  String get derivedMetricDetailNarrow => '좁음';

  @override
  String get derivedMetricDetailNearPerfectSymmetry97 =>
      '거의 완벽한 대칭 (97%+). 양쪽이 매우 균형 잡혀 있습니다.';

  @override
  String get derivedMetricDetailNoHistoryYet => '기록 없음';

  @override
  String get derivedMetricDetailNormal => '정상';

  @override
  String get derivedMetricDetailObese => '비만';

  @override
  String get derivedMetricDetailOverweight => '과체중';

  @override
  String derivedMetricDetailScreenArmSymmetryComparesYour(Object info) {
    return '팔 대칭은 왼쪽과 오른쪽 이두근 측정치를 비교합니다. $info';
  }

  @override
  String derivedMetricDetailScreenEntries(Object length) {
    return '$length개 항목';
  }

  @override
  String derivedMetricDetailScreenLegSymmetryComparesYour(Object info) {
    return '다리 대칭은 왼쪽과 오른쪽 허벅지 측정치를 비교합니다. $info';
  }

  @override
  String get derivedMetricDetailShoulders => '어깨';

  @override
  String get derivedMetricDetailSignificantAsymmetryBelow8 =>
      '상당한 비대칭 (88% 미만). 약한 쪽을 위한 편측 훈련에 집중하세요.';

  @override
  String get derivedMetricDetailSuperior => '최상';

  @override
  String get derivedMetricDetailThighL => '허벅지 (좌)';

  @override
  String get derivedMetricDetailThighR => '허벅지 (우)';

  @override
  String get derivedMetricDetailTrends => '추이';

  @override
  String get derivedMetricDetailUnderweight => '저체중';

  @override
  String get derivedMetricDetailVTaper => 'V-테이퍼';

  @override
  String get derivedMetricDetailWaist => '허리';

  @override
  String get derivedMetricDetailWeeklyRate => '주간 비율';

  @override
  String get derivedMetricDetailWeight => '체중';

  @override
  String get diabetesDashboardDiabetes => '당뇨병';

  @override
  String get diabetesDashboardGlucoseLevel => '혈당 수치';

  @override
  String get diabetesDashboardInsulinType => '인슐린 유형';

  @override
  String get diabetesDashboardLogGlucose => '혈당 기록';

  @override
  String get diabetesDashboardLogInsulin => '인슐린 기록';

  @override
  String get diabetesDashboardLong => '지속형';

  @override
  String get diabetesDashboardMixed => '혼합형';

  @override
  String get diabetesDashboardNotesOptional => '메모 (선택 사항)';

  @override
  String get diabetesDashboardRapid => '속효성';

  @override
  String get diabetesDashboardScreenAbove => '높음';

  @override
  String get diabetesDashboardScreenAllBloodGlucoseReadings => '모든 혈당 측정값';

  @override
  String get diabetesDashboardScreenBasedOnReadings => '측정값 기준';

  @override
  String get diabetesDashboardScreenBelow => '낮음';

  @override
  String get diabetesDashboardScreenCurrentGlucose => '현재 혈당';

  @override
  String get diabetesDashboardScreenEstimated => '예상치';

  @override
  String diabetesDashboardScreenGlucoseLoggedMgDl(Object value) {
    return '기록된 혈당: $value mg/dL';
  }

  @override
  String get diabetesDashboardScreenGreatYouReMeeting =>
      '훌륭합니다! 목표 범위 내 70% 이상을 유지하고 있습니다.';

  @override
  String get diabetesDashboardScreenHealthConnect => 'Health Connect';

  @override
  String get diabetesDashboardScreenInRange => '정상 범위';

  @override
  String diabetesDashboardScreenInsulinLoggedU(Object units) {
    return '기록된 인슐린: $units U';
  }

  @override
  String get diabetesDashboardScreenLatest => '최신';

  @override
  String get diabetesDashboardScreenLogGlucose => '혈당 기록';

  @override
  String get diabetesDashboardScreenLogInsulin => '인슐린 기록';

  @override
  String get diabetesDashboardScreenLong => '지속형';

  @override
  String get diabetesDashboardScreenManual => '수동';

  @override
  String get diabetesDashboardScreenMgDl => 'mg/dL';

  @override
  String get diabetesDashboardScreenNoAdditionalReadingsAvailab => '추가 측정값 없음';

  @override
  String diabetesDashboardScreenPartA1CCardDaysAgo(Object daysSinceMeasured) {
    return '$daysSinceMeasured일 전';
  }

  @override
  String diabetesDashboardScreenPartA1CCardMgDl(Object valueMgDl) {
    return '$valueMgDl mg/dL';
  }

  @override
  String diabetesDashboardScreenPartCurrentGlucoseCardLastDays(
    Object daysIncluded,
  ) {
    return '지난 $daysIncluded일';
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
  String get diabetesDashboardScreenRapid => '속효성';

  @override
  String get diabetesDashboardScreenRecentDoses => '최근 투여량';

  @override
  String get diabetesDashboardScreenRecentReadings => '최근 측정값';

  @override
  String get diabetesDashboardScreenSeeAll => '모두 보기';

  @override
  String get diabetesDashboardScreenSync => '동기화';

  @override
  String get diabetesDashboardScreenSyncYourGlucoseData => '혈당 데이터 동기화';

  @override
  String get diabetesDashboardScreenTimeInRange => '목표 범위 내 시간';

  @override
  String get diabetesDashboardScreenTodaySInsulin => '오늘의 인슐린';

  @override
  String get diabetesDashboardScreenTotal => '합계';

  @override
  String get diabetesDashboardUnableToLoadData => '데이터를 불러올 수 없음';

  @override
  String get diabetesDashboardUnits => '단위';

  @override
  String get dietHeuristics25GPerDish => '요리당 25g 이상';

  @override
  String get dietHeuristicsAntiInflammatory => '항염증';

  @override
  String get dietHeuristicsBloodSugarFriendly => '혈당 친화적';

  @override
  String get dietHeuristicsGutFriendly => '장 건강 친화적';

  @override
  String get dietHeuristicsHighProtein => '고단백';

  @override
  String get dietHeuristicsLowCarb => '저탄수화물';

  @override
  String get dietHeuristicsLowFodmap => '저 FODMAP';

  @override
  String get dietHeuristicsLowGlycemicLoad => '낮은 혈당 부하';

  @override
  String get dietHeuristicsNotUltraProcessed => '초가공 식품 제외';

  @override
  String get dietHeuristicsScore3OrLower => '점수 3점 이하';

  @override
  String get dietHeuristicsUnder20GCarbs => '탄수화물 20g 미만';

  @override
  String get dietHeuristicsUnder450Cal => '450칼로리 미만';

  @override
  String get dietHeuristicsWholeFoods => '자연식';

  @override
  String get difficultyCardDifficultyMultipliers => '난이도 배수';

  @override
  String get difficultyCardResetAll => '모두 재설정';

  @override
  String get difficultyCardRest => '휴식';

  @override
  String difficultyCardRest2(Object tier) {
    return '$tier - 휴식';
  }

  @override
  String difficultyCardRpe(Object tier) {
    return '$tier - RPE';
  }

  @override
  String get difficultyCardTapAnyCellTo => '셀을 탭하여 스케일링 요소를 편집하세요';

  @override
  String get difficultyCardTier => '티어';

  @override
  String get difficultyCardVolume => '볼륨';

  @override
  String difficultyCardVolume2(Object tier) {
    return '$tier - 볼륨';
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
  String get difficultySelectorChooseAnother => '다른 항목 선택';

  @override
  String get difficultySelectorChooseDifferent => '다른 항목 선택';

  @override
  String get difficultySelectorConsiderChallengingForA =>
      '더 안전하고 강도 높은 운동을 위해 \"도전적(Challenging)\" 단계를 고려해보세요';

  @override
  String get difficultySelectorContinueAnyway => '계속 진행';

  @override
  String get difficultySelectorDifficulty => '난이도';

  @override
  String get difficultySelectorGotIt => '확인';

  @override
  String get difficultySelectorHellIntensity => '지옥의 강도';

  @override
  String get difficultySelectorHellModeWarning => 'HELL 모드 경고';

  @override
  String get difficultySelectorHighIntensity => '고강도';

  @override
  String get difficultySelectorIAcceptTheRisk => '위험을 감수하겠습니다';

  @override
  String difficultySelectorModeIsDesignedFor(Object displayName) {
    return '$displayName 모드는 숙련된 운동선수를 위해 설계되었습니다. 초보자의 경우 부상이나 번아웃으로 이어질 수 있습니다. 초급 또는 중급 난이도로 시작하는 것을 권장합니다.';
  }

  @override
  String difficultySelectorModeMayBeIntense(Object displayName) {
    return '$displayName 모드는 초보자에게 강도가 높을 수 있습니다. 초급 또는 중급 난이도로 시작하여 근력과 지구력을 키우면서 점진적으로 높여가는 것을 고려하세요.';
  }

  @override
  String get difficultySelectorThisIsAnExtreme =>
      '이것은 당신의 한계를 시험하기 위해 설계된 극한 강도의 운동입니다.';

  @override
  String get discoverBrowseByCategory => '카테고리별 탐색';

  @override
  String get discoverBrowseByEquipment => '장비별 탐색';

  @override
  String get discoverBrowseByMuscle => '근육별 탐색';

  @override
  String get discoverChallenges => '챌린지';

  @override
  String get discoverCheckYourConnectionAnd => '연결 상태를 확인하고 다시 시도하세요.';

  @override
  String get discoverComplete3WorkoutsTo => '운동 3회를 완료하여 피트니스 프로필을 잠금 해제하세요.';

  @override
  String get discoverCompleteAWorkoutThis => '이번 주에 운동 완료하기';

  @override
  String get discoverCompleteAWorkoutTo => '운동을 완료하여 순위표에 오르세요';

  @override
  String get discoverCompleteYourProfileTo => '프로필을 완성하고 맞춤형 추천을 받으세요';

  @override
  String get discoverCouldnTLoadDiscover => 'Discover를 불러올 수 없습니다.';

  @override
  String get discoverCuratedRecipesToTry => '시도하거나 응용해 볼 수 있는 엄선된 레시피';

  @override
  String get discoverFeed => '피드';

  @override
  String get discoverForYou => '추천';

  @override
  String get discoverFriends => '친구';

  @override
  String get discoverGetAPersonalizedAi => 'AI 맞춤 추천 받기';

  @override
  String get discoverHidden => '숨김';

  @override
  String get discoverMatchedToYourGym => '내 체육관 프로필과 일치';

  @override
  String get discoverNotEnoughDataYet => '데이터가 아직 부족합니다';

  @override
  String get discoverNotSureAskAi => '확실하지 않나요? AI에게 물어보세요';

  @override
  String discoverScreenLvl(Object level) {
    return 'Lv $level';
  }

  @override
  String discoverScreenLvl2(Object level) {
    return 'Lv $level';
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
  String get discoverTapAnAxis => '축을 탭하세요';

  @override
  String get discoverThem => '상대방';

  @override
  String get discoverThisWeek => '이번 주';

  @override
  String get discoverTopOfTheWeek => '이번 주의 상위권';

  @override
  String get discoverTourBrowseRisingStarsAnd =>
      'Rising Stars와 내 주변 사용자를 탐색하여 비슷한 수준의 사람들을 확인해보세요.';

  @override
  String get discoverTourFindYourPeers => '비슷한 수준의 사용자 찾기';

  @override
  String get discoverTourOpenTheir6Axis =>
      '상대방의 6축 피트니스 레이더를 열어 XP, 볼륨, 연속 기록 등에서 내가 어느 정도 수준인지 확인해보세요.';

  @override
  String get discoverTourSwitchBoards => '순위표 전환';

  @override
  String get discoverTourTapAnyUser => '사용자 탭하기';

  @override
  String get discoverTourXpVolumeStreaksEach =>
      'XP / 볼륨 / 연속 기록은 각각 다른 게임처럼 순위를 매깁니다. 모두 시도하여 나에게 가장 강한 축을 찾아보세요.';

  @override
  String get discoverTrainingPlans => '훈련 계획';

  @override
  String get discoverTryAgain => '다시 시도';

  @override
  String get discoverViewAll => '모두 보기';

  @override
  String get discoverWhatShouldITrain => '무엇을 훈련할까요?';

  @override
  String get discoverXpThisWeek => '이번 주 XP';

  @override
  String get discoverYou => '나 · ';

  @override
  String get discoverYourRankPercentileAppears => '순위표에 오르면 순위와 백분위수가 표시됩니다';

  @override
  String get dismissedBannersDailyXpGoals => '일일 XP 목표';

  @override
  String get dismissedBannersDismissedBanners => '닫은 배너';

  @override
  String get dismissedBannersDismissedBannersResetAutoma =>
      '닫은 배너는 자정에 자동으로 초기화됩니다.';

  @override
  String get dismissedBannersRestore => '복원';

  @override
  String get doubleXpBannerDayStreak => '일 연속 기록';

  @override
  String doubleXpBannerEndsIn(Object formattedTimeRemaining) {
    return '$formattedTimeRemaining 후 종료';
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
  String get downloadedVideosAllDownloadsCleared => '모든 다운로드 삭제됨';

  @override
  String get downloadedVideosBrowseExerciseLibrary => '운동 라이브러리 탐색';

  @override
  String get downloadedVideosClearAll => '모두 삭제';

  @override
  String get downloadedVideosClearAllDownloads => '모든 다운로드를 삭제할까요?';

  @override
  String get downloadedVideosDownloadedVideos => '다운로드한 영상';

  @override
  String get downloadedVideosHowToDownload => '다운로드 방법';

  @override
  String get downloadedVideosNoDownloadsYet => '아직 다운로드한 영상이 없습니다';

  @override
  String get downloadedVideosSaveExerciseVideosFor =>
      '운동 영상을 저장하여 오프라인으로 시청하세요. WiFi가 불안정한 체육관에서 유용합니다.';

  @override
  String downloadedVideosScreenDeleted(Object exerciseName) {
    return '\"$exerciseName\" 삭제됨';
  }

  @override
  String downloadedVideosScreenMb(Object formattedCacheSize) {
    return '$formattedCacheSize / 500 MB';
  }

  @override
  String downloadedVideosScreenVideos(Object cachedVideoCount) {
    return '영상 $cachedVideoCount개';
  }

  @override
  String get downloadedVideosStorageAlmostFullOldest =>
      '저장 공간이 거의 꽉 찼습니다. 가장 오래된 영상부터 자동으로 삭제됩니다.';

  @override
  String get downloadedVideosStorageUsed => '사용된 저장 공간';

  @override
  String get downloadedVideosThisWillDeleteAll =>
      '기기에 다운로드된 모든 운동 영상이 삭제됩니다. 언제든지 다시 다운로드할 수 있습니다.';

  @override
  String get durationRangeSliderDuration => '기간';

  @override
  String durationRangeSliderMin(Object minDuration) {
    return '$minDuration분';
  }

  @override
  String durationRangeSliderMin2(Object maxDuration) {
    return '$maxDuration분';
  }

  @override
  String get durationSliderDuration => '기간';

  @override
  String durationSliderMin(Object duration) {
    return '$duration분';
  }

  @override
  String durationSliderMin2(Object minDuration) {
    return '$minDuration분';
  }

  @override
  String durationSliderMin3(Object maxDuration) {
    return '$maxDuration분';
  }

  @override
  String get easyActiveWorkoutComplete => '완료';

  @override
  String get easyActiveWorkoutCompleteWorkoutNow => '지금 운동을 완료할까요?';

  @override
  String get easyActiveWorkoutExerciseSwapped => '운동이 교체되었습니다';

  @override
  String get easyActiveWorkoutKeepGoing => '계속하기';

  @override
  String get easyActiveWorkoutQuit => '종료';

  @override
  String get easyActiveWorkoutQuitWorkout => '운동을 종료할까요?';

  @override
  String get easyActiveWorkoutSavingWorkout => '운동 저장 중...';

  @override
  String get easyChatPillAskCoach => '코치에게 질문';

  @override
  String get easyChatPillAskYourCoach => '코치에게 질문하기';

  @override
  String get easyExerciseActionsChangeEquipment => '장비 변경';

  @override
  String get easyExerciseActionsDonTHaveWhat => '목록에 있는 장비가 없나요?';

  @override
  String get easyExerciseActionsPickADifferentMovement => '이 슬롯에 다른 운동 선택';

  @override
  String get easyExerciseActionsReportPain => '통증 보고';

  @override
  String get easyExerciseActionsShowVideo => '영상 보기';

  @override
  String get easyExerciseActionsSkipThisExerciseAvoid => '이 운동 건너뛰기 및 당분간 제외';

  @override
  String get easyExerciseActionsSkipToNextExercise => '다음 운동으로 건너뛰기';

  @override
  String get easyExerciseActionsSwapExercise => '운동 교체';

  @override
  String get easyExerciseHeaderAddSet => '세트 추가';

  @override
  String get easyExerciseHeaderInstructions => '지침';

  @override
  String get easyExerciseHeaderPlan => '계획';

  @override
  String get easyExerciseHeaderRemoveSet => '세트 삭제';

  @override
  String easyExerciseHeaderSetOf(Object currentSet, Object totalSets) {
    return '$totalSets세트 중 $currentSet세트';
  }

  @override
  String get easyExerciseHeaderVideo => '영상';

  @override
  String get easyFocalColumnHold => '홀드';

  @override
  String get easyFocalColumnReps => '횟수';

  @override
  String get easyFocalColumnWeight => '무게';

  @override
  String get easyHelpAdjustWeightAndReps =>
      '−와 + 버튼으로 무게와 횟수를 조절하세요. 숫자를 길게 누르면 직접 입력할 수 있습니다.';

  @override
  String get easyHelpGotIt => '확인';

  @override
  String get easyHelpLogASet => '세트 기록';

  @override
  String get easyHelpLogASetBody => '세트 기록하기';

  @override
  String get easyHelpSkipToNextExercise => '다음 운동으로 건너뛰기';

  @override
  String get easyHelpSwitchToAdvanced => '고급 모드로 전환';

  @override
  String get easyHelpTapTheBigWhen =>
      '세트를 마치면 큰 ✓ 버튼을 누르세요. 나머지는 저희가 알아서 처리해 드립니다.';

  @override
  String get easyHelpThisIsTodayS =>
      '오늘의 운동입니다. 자세를 다시 확인하고 싶을 때 언제든 ▶ 영상 보기 버튼을 누르세요.';

  @override
  String get easyHelpTodaySExercise => '오늘의 운동';

  @override
  String get easyHelpTodaysExercise => '오늘의 운동';

  @override
  String get easyHelpTodaysExerciseBody => '오늘의 운동 본문';

  @override
  String get easyHelpWeightAndReps => '무게 및 횟수';

  @override
  String get easyHelpWeightAndRepsBody => '중량 및 횟수 본문';

  @override
  String get easyRestOverlayRest => '휴식';

  @override
  String easyRestOverlaySetOf(Object nextSetNumber, Object totalSets) {
    return '$nextSetNumber / $totalSets 세트';
  }

  @override
  String get easyRestOverlaySkipRest => '휴식 건너뛰기';

  @override
  String get easySheetHelpersAboutThisExercise => '운동 정보';

  @override
  String get easySheetHelpersBodyPart => '신체 부위';

  @override
  String get easySheetHelpersBreathing => '호흡';

  @override
  String get easySheetHelpersEquipment => '장비';

  @override
  String get easySheetHelpersFormTips => '자세 팁';

  @override
  String get easySheetHelpersHowToPerform => '수행 방법';

  @override
  String get easySheetHelpersNoDemoVideoFor => '아직 이 운동에 대한 시연 영상이 없습니다.';

  @override
  String get easySheetHelpersPrimaryMuscle => '주동근';

  @override
  String get easySheetHelpersSecondary => '보조 근육';

  @override
  String get easyTopBarAddToFavorites => '즐겨찾기에 추가';

  @override
  String get easyTopBarCompleteWorkout => '운동 완료';

  @override
  String get easyTopBarMinimizeWorkout => '운동 최소화';

  @override
  String get easyTopBarQuitWorkout => '운동 종료';

  @override
  String get easyTopBarRemoveFromFavorites => '즐겨찾기에서 제거';

  @override
  String get easyTopBarSkipToNextExercise => '다음 운동으로 건너뛰기';

  @override
  String get editGymProfileAutoAiDecides => '자동 (AI가 결정)';

  @override
  String get editGymProfileAutoSwitchAtThis => '이 시간에 자동 전환';

  @override
  String get editGymProfileAutoSwitchWhenI => '도착 시 자동 전환';

  @override
  String get editGymProfileChooseIcon => '아이콘 선택';

  @override
  String get editGymProfileClear => '지우기';

  @override
  String get editGymProfileColor => '색상';

  @override
  String get editGymProfileCustomizeWorkoutsForThis => '이 헬스장에 맞게 운동 맞춤 설정';

  @override
  String get editGymProfileDuplicate => '복제';

  @override
  String get editGymProfileEditIcon => '아이콘 편집';

  @override
  String get editGymProfileEnterGymName => '헬스장 이름 입력';

  @override
  String get editGymProfileEnterNewName => '새 이름 입력';

  @override
  String get editGymProfileEnvironment => '환경';

  @override
  String get editGymProfileEquipment => '장비';

  @override
  String get editGymProfileExperienceLevel => '숙련도';

  @override
  String get editGymProfileFocusAreas => '집중 부위';

  @override
  String get editGymProfileHowMuchExerciseVariety => '매주 운동 다양성 정도';

  @override
  String get editGymProfileIcon => '아이콘';

  @override
  String get editGymProfileLeaveOnAutoFor =>
      'AI가 결정하게 하려면 \'자동\'으로 두거나, 특정 요일에 집중 부위를 고정하세요 (예: 화 → 상체).';

  @override
  String get editGymProfileLocationOptional => '위치 (선택 사항)';

  @override
  String get editGymProfileMuscleGroupsToPrioritize => '우선순위 근육 그룹';

  @override
  String get editGymProfileName => '이름';

  @override
  String get editGymProfileNoPref => '선호 없음';

  @override
  String get editGymProfilePinFocusPerDay => '요일별 집중 부위 고정 (선택 사항)';

  @override
  String get editGymProfilePleaseEnterAName => '이름을 입력해 주세요';

  @override
  String get editGymProfileRename => '이름 변경';

  @override
  String get editGymProfileRenameGym => '헬스장 이름 변경';

  @override
  String get editGymProfileRequiresLocationPermission => '위치 권한 필요';

  @override
  String get editGymProfileSaveChanges => '변경 사항 저장';

  @override
  String get editGymProfileSetALocationTo => '프로필 자동 전환을 위해 위치 설정';

  @override
  String editGymProfileSheetEquipmentItems(Object length) {
    return '장비 항목 $length개';
  }

  @override
  String editGymProfileSheetExtCreatedCopyOf(Object name) {
    return '\"$name\"의 복사본 생성됨';
  }

  @override
  String editGymProfileSheetExtFailedToDuplicate(Object e) {
    return '복제 실패: $e';
  }

  @override
  String editGymProfileSheetExtFailedToSave(Object e) {
    return '저장 실패: $e';
  }

  @override
  String editGymProfileSheetExtMinutes(Object _selectedDuration) {
    return '$_selectedDuration분';
  }

  @override
  String editGymProfileSheetExtPinFocusFor(Object dayName) {
    return '$dayName의 포커스 고정';
  }

  @override
  String editGymProfileSheetExtUpdated(Object text) {
    return '\"$text\" 업데이트됨';
  }

  @override
  String get editGymProfileTapToAddRemove => '탭하여 무게 추가, 제거 또는 편집';

  @override
  String get editGymProfileTrainingPreferencesOptional => '운동 선호도 (선택 사항)';

  @override
  String get editGymProfileWeeklyVariety => '주간 다양성';

  @override
  String get editGymProfileWhenDoYouUsually => '보통 언제 여기서 운동하시나요?';

  @override
  String get editGymProfileWorkoutDays => '운동 요일';

  @override
  String get editGymProfileWorkoutDuration => '운동 시간';

  @override
  String get editGymProfileWorkoutTimeOptional => '운동 시간 (선택 사항)';

  @override
  String get editPersonalInfoChooseFromGallery => '갤러리에서 선택';

  @override
  String get editPersonalInfoEditProfile => '프로필 편집';

  @override
  String get editPersonalInfoHeight => '키';

  @override
  String get editPersonalInfoRemovePhoto => '사진 삭제';

  @override
  String get editPersonalInfoTakePhoto => '사진 촬영';

  @override
  String get editPersonalInfoTapToChangePhoto => '탭하여 사진 변경';

  @override
  String get editPersonalInfoTargetWeight => '목표 체중';

  @override
  String get editPersonalInfoTellUsAboutYourself => '자기소개를 입력하세요...';

  @override
  String get editPersonalInfoUploadPhoto => '사진 업로드';

  @override
  String get editPersonalInfoUploading => '업로드 중...';

  @override
  String get editPersonalInfoWeight => '체중';

  @override
  String get editPersonalInfoYourEmailCom => 'your@email.com';

  @override
  String get editPersonalInfoYourName => '이름';

  @override
  String get editProgramSheetBack => '뒤로';

  @override
  String get editProgramSheetChangeYourWeeklySchedule =>
      '주간 일정, 장비 또는 난이도를 변경하세요. 새로운 설정에 맞춰 운동이 다시 생성됩니다.';

  @override
  String get editProgramSheetChooseATrainingSplit =>
      '일정과 목표에 맞는 트레이닝 분할을 선택하세요';

  @override
  String get editProgramSheetContinue => '계속';

  @override
  String get editProgramSheetCurrent => '현재';

  @override
  String get editProgramSheetCustomProgram => '맞춤 프로그램';

  @override
  String editProgramSheetCustomValue(Object arg0) {
    return '사용자 지정: $arg0';
  }

  @override
  String get editProgramSheetCustomizeProgram => '프로그램 맞춤 설정';

  @override
  String get editProgramSheetDays => '일';

  @override
  String editProgramSheetDaysAgo(Object days) {
    return '$days일 전';
  }

  @override
  String editProgramSheetDaysPerWeek(Object days) {
    return '주 $days회';
  }

  @override
  String get editProgramSheetDescribeWhatYouWant =>
      '원하는 훈련 목표를 설명하면 AI가 개인 맞춤형 프로그램을 생성합니다.';

  @override
  String get editProgramSheetDifficulty => '난이도';

  @override
  String get editProgramSheetDuration => '기간';

  @override
  String get editProgramSheetEGTrainFor => '예: \"HYROX 대회 준비\"';

  @override
  String get editProgramSheetEquipment => '장비';

  @override
  String get editProgramSheetEquipmentLabel => '장비 라벨';

  @override
  String get editProgramSheetExamples => '예시';

  @override
  String editProgramSheetFailedToLoadHistory(Object arg0) {
    return '기록을 불러오지 못했습니다: $arg0';
  }

  @override
  String editProgramSheetFailedToRestore(Object arg0) {
    return '복원하지 못했습니다: $arg0';
  }

  @override
  String get editProgramSheetFailedToUpdateProgram => '프로그램 업데이트';

  @override
  String get editProgramSheetFocus => '집중 부위';

  @override
  String get editProgramSheetHealth => '건강';

  @override
  String get editProgramSheetInjuries => '부상';

  @override
  String get editProgramSheetNoProgramHistoryFound => '프로그램 기록이 없습니다';

  @override
  String editProgramSheetPartEditProgramSheetStateOf(
    Object _generatingWorkout,
    Object _totalWorkoutsToGenerate,
  ) {
    return '$_generatingWorkout / $_totalWorkoutsToGenerate';
  }

  @override
  String get editProgramSheetPleaseLogInTo => '프로그램 기록을 보려면 로그인하세요';

  @override
  String get editProgramSheetPleaseSelectAtLeast => '최소 하루 이상의 운동 요일을 선택하세요';

  @override
  String get editProgramSheetProgram => '프로그램';

  @override
  String get editProgramSheetProgramHistory => '프로그램 기록';

  @override
  String get editProgramSheetProgramRestoredRegenerateW =>
      '프로그램이 복원되었습니다! 변경 사항을 적용하려면 운동을 다시 생성하세요.';

  @override
  String get editProgramSheetRestoreAPreviousProgram => '이전 프로그램 구성 복원';

  @override
  String get editProgramSheetRestoreThisProgram => '이 프로그램 복원';

  @override
  String get editProgramSheetSaveCustomProgram => '맞춤 프로그램 저장';

  @override
  String get editProgramSheetSavingPreferences => '환경설정 저장 중';

  @override
  String get editProgramSheetSchedule => '일정';

  @override
  String get editProgramSheetSummary => '요약';

  @override
  String get editProgramSheetThisStepIsOptional =>
      '이 단계는 선택 사항입니다. 보고할 부상이 없다면 건너뛰어도 됩니다.';

  @override
  String get editProgramSheetToday => '오늘';

  @override
  String get editProgramSheetTrainingProgram => '훈련 프로그램';

  @override
  String get editProgramSheetUnknownDate => '알 수 없는 날짜';

  @override
  String get editProgramSheetUpdateAndRegenerate => '업데이트 및 재생성';

  @override
  String get editProgramSheetUpdating => '업데이트 중';

  @override
  String editProgramSheetWeeksAgo(Object weeks) {
    return '$weeks주 전';
  }

  @override
  String get editProgramSheetYesterday => '어제';

  @override
  String get editSetAddSet => '세트 추가';

  @override
  String get editSetEditSets => '세트 편집';

  @override
  String get editSetSaveChanges => '변경 사항 저장';

  @override
  String get editSetThisSetWillBe => '이 세트가 삭제됩니다.';

  @override
  String get editSetWeightKg => '무게 (kg)';

  @override
  String get editTargetsDietPreset => '식단 프리셋';

  @override
  String get editTargetsEditDailyTargets => '일일 목표 편집';

  @override
  String get editTargetsLockCalories => '칼로리 고정';

  @override
  String get editTargetsMaintainingWeight => '체중 유지';

  @override
  String get editTargetsRec => '추천';

  @override
  String get editTargetsRecalculateFromProfile => '프로필에서 재계산';

  @override
  String get editTargetsRecommendationUnavailableR =>
      '추천을 사용할 수 없습니다 — 먼저 프로필에서 재계산하세요';

  @override
  String get editTargetsReset => '초기화';

  @override
  String get editTargetsSaveTargets => '목표 저장';

  @override
  String editTargetsSheetCalculatedKcal(Object numberFormat) {
    return '계산됨: $numberFormat kcal';
  }

  @override
  String editTargetsSheetCappedAtSafeMinimum(Object cappedMinimum) {
    return '안전 최소치로 제한됨($cappedMinimum kcal) — ';
  }

  @override
  String editTargetsSheetFailedToRecalculate(Object e) {
    return '재계산 실패: $e';
  }

  @override
  String editTargetsSheetFailedToSave(Object e) {
    return '저장 실패: $e';
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
    return '단백질 목표 $anchorLabel';
  }

  @override
  String editTargetsSheetSafeMinimumCaloriesMeet(Object cappedMinimum) {
    return '안전 최소 칼로리($cappedMinimum)가 TDEE를 충족합니다 — ';
  }

  @override
  String editTargetsSheetTotalUBMust(Object sum) {
    return '합계: $sum% · 100%여야 합니다';
  }

  @override
  String editTargetsSheetUWks(
    Object dateStr,
    Object deficitInfo,
    Object goalLabel,
    Object weeks,
  ) {
    return '$goalLabel → 약 $weeks주 ($dateStr)$deficitInfo';
  }

  @override
  String editTargetsSheetValue(Object label, Object pct) {
    return '$label $pct%';
  }

  @override
  String get editTargetsTargetsRecalculatedFromProf => '프로필에서 목표가 재계산되었습니다';

  @override
  String get editTargetsTargetsUpdated => '목표가 업데이트되었습니다';

  @override
  String get editTargetsTotal100 => '합계: 100%';

  @override
  String get editTargetsUseRecommended => '추천 사용';

  @override
  String get editTargetsWeeklyRateKgWk => '주간 감량/증량 목표 (kg/주)';

  @override
  String get editTrackingAtLeastOneStat => '최소 하나의 통계는 표시되어야 합니다';

  @override
  String get editTrackingCaloriesBurned => '소모 칼로리';

  @override
  String get editTrackingCaloriesPCF => '칼로리, P/C/F 매크로 및 수분 섭취량';

  @override
  String get editTrackingChooseWhichStatsTo => '트래킹 바에 표시할 통계를 선택하세요';

  @override
  String get editTrackingConsecutiveWorkoutDays => '연속 운동 일수';

  @override
  String get editTrackingDailyGoals => '일일 목표';

  @override
  String get editTrackingDailyHabitCompletionProgres => '일일 습관 완료 진행률';

  @override
  String get editTrackingDailyStepCountFrom => '건강 기기에서 가져온 일일 걸음 수';

  @override
  String get editTrackingEditTracking => '트래킹 편집';

  @override
  String get editTrackingFromConnectedHealthDevices => '연결된 건강 기기에서 가져오기';

  @override
  String get editTrackingHabits => '습관';

  @override
  String get editTrackingLastNightSSleep => '지난밤 수면 시간 및 질';

  @override
  String get editTrackingLoginWeightMealWorkout => '로그인, 체중, 식사 및 운동 체크';

  @override
  String get editTrackingNutritionHydration => '영양 및 수분 섭취';

  @override
  String get editTrackingReset => '초기화';

  @override
  String get editTrackingSleep => '수면';

  @override
  String get editTrackingSteps => '걸음 수';

  @override
  String get editTrackingWorkoutStreak => '운동 연속 기록';

  @override
  String get editWeightsAnyWeightAllowedIn => '운동 시 모든 무게 허용';

  @override
  String get editWeightsApplyAPreset => '프리셋 적용';

  @override
  String get editWeightsClearAll => '모두 지우기';

  @override
  String get editWeightsClearAll2 => '모두 지우기';

  @override
  String get editWeightsClearedAllWeights => '모든 무게가 지워졌습니다';

  @override
  String get editWeightsCommercialGymStandardSet => '상업용 헬스장 표준 세트';

  @override
  String get editWeightsCompetitionSet832 => '대회용 세트 (8–32 kg)';

  @override
  String get editWeightsCustomWeight => '사용자 지정 무게...';

  @override
  String get editWeightsEditWeights => '무게 편집';

  @override
  String get editWeightsEnter0ToRemove => '제거하려면 0을 입력하세요';

  @override
  String get editWeightsGenerateStackWeights => '스택 무게 생성';

  @override
  String get editWeightsHomeAdjustableSet => '가정용 조절식 세트';

  @override
  String get editWeightsMax => '최대';

  @override
  String get editWeightsMicroloadingAddOn => '마이크로로딩 추가 구성품';

  @override
  String get editWeightsMin => '최소';

  @override
  String get editWeightsNoWeightsYetPick =>
      '아직 무게가 없습니다. 최소/최대/단위를 선택하고 생성을 탭하세요.';

  @override
  String get editWeightsPreset => '프리셋';

  @override
  String get editWeightsQuantity => '수량';

  @override
  String get editWeightsSet => '세트';

  @override
  String get editWeightsSetQuantity => '수량 설정';

  @override
  String editWeightsSheetSelectedItems(Object _totalWeights) {
    return '선택됨: $_totalWeights개 항목';
  }

  @override
  String get editWeightsStackRange => '스택 범위';

  @override
  String get editWeightsStep => '단위';

  @override
  String get editWeightsUndo => '실행 취소';

  @override
  String get editWorkoutEquipmentDeselect => '선택 해제';

  @override
  String get editWorkoutEquipmentEditEquipment => '장비 편집';

  @override
  String get editWorkoutEquipmentSearchEquipment => '장비 검색...';

  @override
  String get editWorkoutEquipmentSelectAll => '전체 선택';

  @override
  String editWorkoutEquipmentSheetItemsSelected(Object length) {
    return '항목 $length개 선택됨';
  }

  @override
  String editWorkoutEquipmentSheetValue(
    Object length,
    Object selectedInCategory,
  ) {
    return '($selectedInCategory/$length)';
  }

  @override
  String get editWorkoutEquipmentUpdateWorkoutEquipment => '운동 장비 업데이트';

  @override
  String get editWorkoutEquipmentWeights => '무게';

  @override
  String get editableFitnessCard15Min => '15분';

  @override
  String get editableFitnessCard90Min => '90분';

  @override
  String get editableFitnessCardActiveGym => '활동 중인 헬스장';

  @override
  String get editableFitnessCardActiveInjuries => '현재 부상 부위';

  @override
  String get editableFitnessCardChangesAffectYourWorkout =>
      '변경 사항이 운동 프로그램에 적용됩니다';

  @override
  String get editableFitnessCardCustom => '사용자 지정';

  @override
  String get editableFitnessCardCustomDailySteps => '사용자 지정 일일 걸음 수';

  @override
  String get editableFitnessCardDailySteps => '일일 걸음 수';

  @override
  String get editableFitnessCardDailyStepsGoal => '일일 걸음 수 목표';

  @override
  String get editableFitnessCardDays => '일';

  @override
  String get editableFitnessCardDuration => '기간';

  @override
  String get editableFitnessCardEG8500 => '예: 8500';

  @override
  String editableFitnessCardFailedToUpdate(Object error) {
    return '업데이트 실패: $error';
  }

  @override
  String get editableFitnessCardFitnessGoal => '운동 목표';

  @override
  String get editableFitnessCardFitnessLevel => '운동 수준';

  @override
  String get editableFitnessCardFitnessSettingsUpdatedWor =>
      '운동 설정이 업데이트되었습니다. 운동이 다시 생성됩니다.';

  @override
  String get editableFitnessCardGoal => '목표';

  @override
  String get editableFitnessCardGym => '헬스장';

  @override
  String get editableFitnessCardInjuries => '부상';

  @override
  String get editableFitnessCardLevel => '수준';

  @override
  String editableFitnessCardNAreas(Object count) {
    return '$count개 부위';
  }

  @override
  String get editableFitnessCardNoGym => '헬스장 없음';

  @override
  String get editableFitnessCardNone => '없음';

  @override
  String get editableFitnessCardNotSet => '설정 안 됨';

  @override
  String editableFitnessCardPartEditableFitnessCardStateExtMin(
    Object _selectedStretchDuration,
    Object _selectedWarmupDuration,
  ) {
    return '$_selectedWarmupDuration+$_selectedStretchDuration분';
  }

  @override
  String editableFitnessCardPartEditableFitnessCardStateMin(
    Object _selectedWarmupDuration,
  ) {
    return '$_selectedWarmupDuration분';
  }

  @override
  String editableFitnessCardPartEditableFitnessCardStateMin2(
    Object _selectedStretchDuration,
  ) {
    return '$_selectedStretchDuration분';
  }

  @override
  String editableFitnessCardPartEditableFitnessCardStateMin3(Object duration) {
    return '$duration분';
  }

  @override
  String editableFitnessCardPartEditableFitnessCardStateMin4(Object duration) {
    return '$duration분';
  }

  @override
  String get editableFitnessCardPrep => '준비';

  @override
  String get editableFitnessCardSet => '세트';

  @override
  String get editableFitnessCardSteps => '걸음 수';

  @override
  String get editableFitnessCardStretch => '스트레칭';

  @override
  String get editableFitnessCardWarmup => '웜업';

  @override
  String get editableFitnessCardWarmupStretch => '웜업 + 스트레칭';

  @override
  String get editableFitnessCardWorkoutDays => '운동 요일';

  @override
  String get editableFitnessCardWorkoutDuration => '운동 시간';

  @override
  String get elevationProfileElevation => '고도';

  @override
  String elevationProfileM(Object ascent) {
    return '+$ascent m';
  }

  @override
  String elevationProfileM2(Object value) {
    return '$value m';
  }

  @override
  String get emailPreferencesAFollowUpIf => '예정된 시간에 운동을 기록하지 않았을 때 보내는 후속 알림';

  @override
  String get emailPreferencesAchievementUnlocks => '업적 달성';

  @override
  String get emailPreferencesBillingAccount => '결제 및 계정';

  @override
  String get emailPreferencesCheckInsFromYour =>
      '코치의 체크인 알림 — 활성화, 복귀 독려, 가벼운 동기부여';

  @override
  String get emailPreferencesDailyRemindersAboutYour => '예정된 운동에 대한 일일 알림';

  @override
  String get emailPreferencesEmailPreferences => '이메일 설정';

  @override
  String get emailPreferencesFailedToLoadEmail => '이메일 설정을 불러오지 못했습니다';

  @override
  String get emailPreferencesKeepOnlyEssentialWorkout => '필수 운동 알림만 받기';

  @override
  String get emailPreferencesMissedWorkoutNudges => '운동 놓침 알림';

  @override
  String get emailPreferencesMotivationalNudges => '동기부여 알림';

  @override
  String get emailPreferencesNewFeaturesAndApp => '새로운 기능 및 앱 개선 사항';

  @override
  String get emailPreferencesOffersDiscounts => '제안 및 할인';

  @override
  String get emailPreferencesProductUpdates => '제품 업데이트';

  @override
  String get emailPreferencesPurchaseBillingCancellatio => '구매, 결제, 취소 (필수)';

  @override
  String emailPreferencesSectionControlWhatEmailsYou(Object appName) {
    return '$appName에서 받는 이메일을 관리하세요';
  }

  @override
  String get emailPreferencesSpecialOffersAndRe => '특별 제안 및 재참여 할인';

  @override
  String get emailPreferencesStreakAlerts => '스트릭 알림';

  @override
  String get emailPreferencesSundayRecapWithWorkouts =>
      '일요일 요약 (운동, 영양, 스트릭, XP 포함)';

  @override
  String get emailPreferencesThisWillTurnOff => '다음 마케팅 이메일이 모두 꺼집니다:';

  @override
  String get emailPreferencesTrophiesFirstWorkoutCeleb => '트로피 + 첫 운동 기념';

  @override
  String get emailPreferencesUnsubscribe => '구독 취소';

  @override
  String get emailPreferencesUnsubscribeFromAllMarketing => '모든 마케팅 이메일 구독 취소';

  @override
  String get emailPreferencesUnsubscribedFromMarketingEm =>
      '마케팅 이메일 구독이 취소되었습니다';

  @override
  String get emailPreferencesWeeklySummary => '주간 요약';

  @override
  String get emailPreferencesWhenYourStreakIs => '스트릭이 끊길 위험이 있을 때';

  @override
  String get emailPreferencesWorkoutReminders => '운동 알림';

  @override
  String get emailPreferencesYouWillStillReceive => '필수 운동 알림은 계속 수신됩니다.';

  @override
  String get emailSignInAlreadyHaveAnAccount => '이미 계정이 있으신가요?';

  @override
  String get emailSignInAtLeast8Characters => '최소 8자 이상';

  @override
  String get emailSignInCreateAccount => '계정 만들기';

  @override
  String get emailSignInDonTHaveAn => '계정이 없으신가요?';

  @override
  String get emailSignInForgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get emailSignInIfAnAccountExists =>
      '해당 이메일로 가입된 계정이 있다면 비밀번호 재설정 링크가 발송되었습니다.';

  @override
  String emailSignInScreenSupportIsNowYour(Object appName) {
    return '$appName 고객 지원팀이 여러분을 도와드립니다. 언제든 문의해 주세요!';
  }

  @override
  String emailSignInScreenWelcomeTo(Object appName) {
    return '$appName에 오신 것을 환영합니다!';
  }

  @override
  String get emailSignInSignIn => '로그인';

  @override
  String get emailSignInSignUp => '회원가입';

  @override
  String get emailSignInYouExampleCom => 'you@example.com';

  @override
  String get emailVerificationBannerResend => '재전송';

  @override
  String get emailVerificationBannerVerifyYourEmailTo =>
      '계정 보안을 위해 이메일을 인증하세요.';

  @override
  String get embeddedCameraPanelFromGallery => '갤러리에서 선택';

  @override
  String get embeddedCameraPanelTryAgain => '다시 시도';

  @override
  String get emptyCustomExercisesBuildCustomExercisesTailore =>
      '나만의 운동을 맞춤 제작하거나 여러 동작을 결합하여 강력한 루틴을 만들어 보세요.';

  @override
  String get emptyCustomExercisesCreateYourFirstExercise => '첫 번째 운동 만들기';

  @override
  String get emptyCustomExercisesCreateYourOwnExercises => '나만의 운동 만들기';

  @override
  String get emptyStateClearFilters => '필터 초기화';

  @override
  String get emptyStateCompleteYourFirstWorkout =>
      '첫 번째 운동을 완료하고\n진행 상황을 기록해 보세요!';

  @override
  String get emptyStateCreateProgram => '프로그램 생성';

  @override
  String get emptyStateNoConnection => '연결 없음';

  @override
  String get emptyStateNoExercisesFound => '운동을 찾을 수 없습니다';

  @override
  String get emptyStateNoResults => '결과 없음';

  @override
  String get emptyStateNoWorkoutHistory => '운동 기록 없음';

  @override
  String get emptyStateNoWorkoutsYet => '아직 운동 기록이 없습니다';

  @override
  String get emptyStatePleaseCheckYourInternet => '인터넷 연결을 확인하고\n다시 시도해 주세요.';

  @override
  String get emptyStateTipGotIt => '확인';

  @override
  String get emptyStateTryAdjustingYourFilters => '필터를 조정하거나\n다른 검색어를 입력해 보세요.';

  @override
  String get emptyStateWeCouldnTFind => '찾으시는 결과를 찾을 수 없습니다.\n다른 키워드로 검색해 보세요.';

  @override
  String get emptyStateYourWorkoutScheduleIs =>
      '운동 일정이 비어 있습니다.\n프로그램을 만들어 시작해 보세요!';

  @override
  String get enhancedEmptyStateTryAsking => '질문해 보세요...';

  @override
  String enhancedEmptyStateTryAsking2(Object name) {
    return '$name에게 물어보세요';
  }

  @override
  String get enhancedEmptyStateYourPersonalFitnessAssistan => '나만의 피트니스 어시스턴트';

  @override
  String get enhancedNotesAddNotesAboutForm =>
      '자세, 팁, 또는 수정 사항에 대한 메모를 추가하세요...';

  @override
  String get enhancedNotesCamera => '카메라';

  @override
  String get enhancedNotesClear => '지우기';

  @override
  String get enhancedNotesDictate => '받아쓰기';

  @override
  String get enhancedNotesExerciseNotes => '운동 메모';

  @override
  String get enhancedNotesGallery => '갤러리';

  @override
  String get enhancedNotesListening => '듣는 중...';

  @override
  String get enhancedNotesListeningSpeakNow => '듣는 중... 말씀해 주세요';

  @override
  String get enhancedNotesMicrophonePermissionRequired => '마이크 권한이 필요합니다';

  @override
  String get enhancedNotesRecord => '녹음';

  @override
  String get enhancedNotesRecording => '녹음 중...';

  @override
  String get enhancedNotesSpeechRecognitionNotAvailab => '음성 인식 기능을 사용할 수 없습니다';

  @override
  String get enhancedNotesStop => '중지';

  @override
  String get enhancedNotesVoiceNote => '음성 메모';

  @override
  String get environmentDetailAddCustomEquipment => '맞춤 장비 추가';

  @override
  String get environmentDetailAddEquipment => '장비 추가';

  @override
  String get environmentDetailAvailableWeights => '사용 가능한 무게';

  @override
  String get environmentDetailBrowse => '탐색';

  @override
  String get environmentDetailCustom => '사용자 지정';

  @override
  String get environmentDetailDiscard => '취소';

  @override
  String get environmentDetailEG1525 => '예: 15, 25, 40';

  @override
  String get environmentDetailEG2 => '예: 2';

  @override
  String get environmentDetailEGAdjustable5 => '예: 조절식 5-50lbs';

  @override
  String get environmentDetailEGTrxBands => '예: TRX 밴드';

  @override
  String get environmentDetailEquipmentName => '장비 이름';

  @override
  String get environmentDetailEquipmentSaved => '장비가 저장되었습니다';

  @override
  String get environmentDetailHowManyDoYou => '몇 개를 가지고 계신가요?';

  @override
  String get environmentDetailNoEquipmentAdded => '추가된 장비 없음';

  @override
  String get environmentDetailNotesOptional => '메모 (선택 사항)';

  @override
  String get environmentDetailQuantity => '수량';

  @override
  String get environmentDetailSaveChanges => '변경 사항 저장';

  @override
  String environmentDetailScreenEdit(Object displayName) {
    return '$displayName 편집';
  }

  @override
  String environmentDetailScreenRemoved(Object displayName) {
    return '$displayName 삭제됨';
  }

  @override
  String environmentDetailScreenSwitchedTo(Object displayName) {
    return '$displayName(으)로 전환됨';
  }

  @override
  String get environmentDetailSearchEquipment => '장비 검색...';

  @override
  String get environmentDetailSeparateMultipleWeightsWith => '여러 무게는 쉼표로 구분하세요';

  @override
  String get environmentDetailTapAddEquipmentTo => '\"장비 추가\"를 눌러 시작하세요';

  @override
  String get environmentDetailThisIsYourActive => '현재 활성화된 환경입니다';

  @override
  String get environmentDetailUndo => '실행 취소';

  @override
  String get environmentDetailUnsavedChanges => '저장되지 않은 변경 사항';

  @override
  String get environmentDetailUseThis => '사용하기';

  @override
  String get environmentDetailYouHaveUnsavedChanges =>
      '저장되지 않은 변경 사항이 있습니다. 나가기 전에 저장하시겠습니까?';

  @override
  String get environmentListActive => '활성';

  @override
  String get environmentListAddCustomEnvironment => '맞춤 환경 추가';

  @override
  String get environmentListChooseIcon => '아이콘 선택';

  @override
  String get environmentListCreateEnvironment => '환경 만들기';

  @override
  String get environmentListEGBeachWorkout => '예: 해변 운동';

  @override
  String get environmentListEnvironmentName => '환경 이름';

  @override
  String environmentListScreenEnvironmentSaved(Object name) {
    return '환경 \"$name\" 저장됨';
  }

  @override
  String environmentListScreenEquipmentItems(Object length) {
    return '장비 $length개';
  }

  @override
  String environmentListScreenMore(Object currentEquipment) {
    return '+$currentEquipment개 더';
  }

  @override
  String get environmentListSelectYourWorkoutEnvironmen =>
      '운동 환경을 선택하여 사용 가능한 장비를 맞춤 설정하세요.';

  @override
  String get environmentListUseThis => '사용하기';

  @override
  String get environmentListWorkoutEnvironment => '운동 환경';

  @override
  String get equipmentCalibration15x220x225x230x2 =>
      '15x2, 20x2, 25x2, 30x2, 35x2';

  @override
  String get equipmentCalibration175ForEz => 'EZ바 17.5, 올림픽바 45';

  @override
  String get equipmentCalibration45x435x225x410x2 =>
      '45x4, 35x2, 25x4, 10x2, 5x2, 2.5x2';

  @override
  String get equipmentCalibration794ForEz => 'EZ바 7.94, 올림픽바 20';

  @override
  String get equipmentCalibrationAddABarbellMachine =>
      '바벨, 머신 또는 케이블을 추가하여 기본값을 재설정하세요.';

  @override
  String get equipmentCalibrationAddEquipment => '장비 추가';

  @override
  String get equipmentCalibrationCalibration => '보정';

  @override
  String get equipmentCalibrationCouldNotLoadCalibrations => '보정 값을 불러올 수 없습니다';

  @override
  String get equipmentCalibrationEGHomeRack => '예: \"홈 랙 EZ 바\"';

  @override
  String get equipmentCalibrationEditEquipment => '장비 편집';

  @override
  String get equipmentCalibrationIntroBody =>
      '원판 제안과 중량 추천이 실제 보유 장비와 일치합니다. 바벨 무게, 머신 슬레지 무게, 케이블 핀 증가량, 원판/덤벨 재고를 설정하세요.';

  @override
  String get equipmentCalibrationIntroTitle => '실제 장비를 알려주세요';

  @override
  String get equipmentCalibrationLabelOptional => '라벨 (선택 사항)';

  @override
  String get equipmentCalibrationLeaveBlankToUse => '비워두면 표준 IPF 세트가 사용됩니다';

  @override
  String get equipmentCalibrationLegPress20 => '레그 프레스: 20';

  @override
  String get equipmentCalibrationLegPress45 => '레그 프레스: 45';

  @override
  String get equipmentCalibrationNoCalibratedEquipmentYet => '아직 보정된 장비가 없습니다';

  @override
  String get equipmentCalibrationPlateMathWillFall => '원판 계산은 표준 기본값으로 돌아갑니다.';

  @override
  String get equipmentCalibrationRemove => '제거';

  @override
  String get equipmentCalibrationSaveChanges => '변경 사항 저장';

  @override
  String equipmentCalibrationScreenBarEmptyWeight(Object _weightUnit) {
    return '바 빈 무게 ($_weightUnit)';
  }

  @override
  String equipmentCalibrationScreenMachineSledCarriage(Object _weightUnit) {
    return '머신 슬레드 / 캐리지 ($_weightUnit)';
  }

  @override
  String equipmentCalibrationScreenPinStart(Object _weightUnit) {
    return '핀 시작 ($_weightUnit)';
  }

  @override
  String equipmentCalibrationScreenPinStep(Object _weightUnit) {
    return '핀 단계 ($_weightUnit)';
  }

  @override
  String get equipmentCalibrationSetBarSledCable => '바 / 슬레드 / 케이블 / 원판 재고 설정';

  @override
  String get equipmentCalibrationTitle => '장비 보정';

  @override
  String get equipmentCalibrationUnits => '단위';

  @override
  String get equipmentEquipment => '장비';

  @override
  String equipmentMatchCardExerciseYouCanDo(Object length, Object matches) {
    return '여기서 할 수 있는 운동 $length개$matches';
  }

  @override
  String get equipmentMatchCardStartAWorkoutWith => '이 장비로 운동 시작';

  @override
  String get equipmentMatchCardUse => '사용';

  @override
  String get equipmentOfflineEquipmentOffline => '장비 및 오프라인';

  @override
  String get equipmentSearchAdd => '추가';

  @override
  String get equipmentSearchAddCustomEquipment => '사용자 지정 장비 추가';

  @override
  String get equipmentSearchAddCustomEquipment2 => '사용자 지정 장비 추가';

  @override
  String get equipmentSearchCanTFindYour => '장비를 찾을 수 없나요?';

  @override
  String get equipmentSearchCustom => '사용자 지정';

  @override
  String get equipmentSearchEGHomemadePull => '예: 수제 풀업 바';

  @override
  String get equipmentSearchNoEquipmentFound => '장비를 찾을 수 없습니다';

  @override
  String get equipmentSearchOtherEquipment => '기타 장비';

  @override
  String get equipmentSearchSearchEquipment => '장비 검색...';

  @override
  String get equipmentSearchSearchFrom100Equipment => '100개 이상의 장비 유형에서 검색';

  @override
  String equipmentSearchSheetAdd(Object _searchQuery) {
    return '\"$_searchQuery\" 추가';
  }

  @override
  String equipmentSearchSheetSelected(Object length) {
    return '$length개 선택됨';
  }

  @override
  String get equipmentSelectorEnterCustomEquipmentE =>
      '사용자 지정 장비 입력 (예: \"TRX 밴드\")';

  @override
  String get equipmentSelectorEquipmentAvailable => '사용 가능한 장비';

  @override
  String get equipmentSelectorOnlyGenerateExercisesWith => '선택한 장비로만 운동 생성';

  @override
  String equipmentSelectorSelected(Object selectedCount) {
    return '$selectedCount개 선택됨';
  }

  @override
  String get equipmentSnapFlowDescribeInstead => '대신 설명하기';

  @override
  String get equipmentSnapFlowLooksABitBlurry => '조금 흐릿해 보여요';

  @override
  String get equipmentSnapFlowNotTheseDescribeInstead => '이게 아니라면 — 대신 설명해주세요';

  @override
  String get equipmentSnapFlowReplaceWithCardio => '유산소 운동으로 대체할까요?';

  @override
  String get equipmentSnapFlowRetake => '다시 촬영';

  @override
  String equipmentSnapFlowSet(Object m, Object s) {
    return '세트: $m:$s';
  }

  @override
  String get equipmentSnapFlowSomethingWentWrong => '문제가 발생했습니다.';

  @override
  String get equipmentSnapFlowThisWillSwapSets => '세트/횟수를 시간 목표로 교체합니다. 계속할까요?';

  @override
  String get equipmentSnapFlowTryAgain => '다시 시도';

  @override
  String get equipmentSnapFlowUseAnyway => '그냥 사용';

  @override
  String get equipmentSnapFlowWeReNot100 => '100% 확실하지 않습니다 — 가장 가까운 것을 선택하세요.';

  @override
  String get equipmentSnapFlowWhichOneIsIt => '어떤 것인가요?';

  @override
  String get eventBasedWorkout183DaysLeft => '183일 남음';

  @override
  String get eventBasedWorkoutEventBasedWorkout => '이벤트 기반 운동';

  @override
  String get eventBasedWorkoutHigh => '높음';

  @override
  String get eventBasedWorkoutTapToLearnMore => '탭하여 자세히 알아보기';

  @override
  String get eventBasedWorkoutTrainForYourBig => '중요한 날을 위해 훈련하세요';

  @override
  String get eventBasedWorkoutWeddingPrep => '결혼 준비';

  @override
  String get eventLoggedUndoRemoved => '제거됨';

  @override
  String get eventLoggedUndoSaved => '저장됨';

  @override
  String get eventLoggedUndoUndo => '실행 취소';

  @override
  String get eventWorkoutComingEventBasedWorkouts => '이벤트 기반 운동';

  @override
  String get eventWorkoutComingGotIt => '알겠습니다!';

  @override
  String get eventWorkoutComingJune152026183 => '2026년 6월 15일  •  183일 남음';

  @override
  String get eventWorkoutComingTrainSmarterForYour =>
      '중요한 순간을 위해 더 스마트하게 훈련하세요';

  @override
  String get eventWorkoutComingWeddingPrep => '결혼 준비';

  @override
  String get eventWorkoutComingWhatYouLlBe => '수행 가능한 작업:';

  @override
  String get exerciseAddBadgeCustom => '커스텀';

  @override
  String get exerciseAddBadgeFav => '즐겨찾기';

  @override
  String get exerciseAddBadgeStaple => '주요';

  @override
  String get exerciseAddNoMineYet => '아직 개인 운동이 없습니다';

  @override
  String get exerciseAddNoMineYetHint =>
      '즐겨찾기, 주요 운동 또는 커스텀 운동을 추가하여 여기에 표시하세요';

  @override
  String get exerciseAddSearchMine => '내 운동 검색...';

  @override
  String get exerciseAddSectionCustom => '커스텀 운동';

  @override
  String get exerciseAddSectionFavorites => '즐겨찾기';

  @override
  String get exerciseAddSectionStaples => '주요 운동';

  @override
  String get exerciseAddSheetAddExercise => '운동 추가';

  @override
  String get exerciseAddSheetAiPicks => 'AI 추천';

  @override
  String get exerciseAddSheetAll => '모두';

  @override
  String get exerciseAddSheetCreateCustomExercisesOr =>
      '맞춤 운동을 만들거나 즐겨찾기에 표시\n라이브러리 → 내 운동';

  @override
  String get exerciseAddSheetFailedToAddExercise => '운동 추가 실패';

  @override
  String get exerciseAddSheetFindThePerfectExercise => '운동에 추가할 완벽한 운동을 찾아보세요';

  @override
  String get exerciseAddSheetGettingAiSuggestions => 'AI 제안을 받는 중...';

  @override
  String get exerciseAddSheetLibrary => '도서관';

  @override
  String get exerciseAddSheetMine => '내 거';

  @override
  String get exerciseAddSheetNoCustomExercisesFavorites =>
      '아직 사용자 지정 운동, 즐겨찾기 또는\n주요 운동이 없습니다';

  @override
  String get exerciseAddSheetNoSuggestionsAvailable => '제안 사항 없음';

  @override
  String exerciseAddSheetPartExerciseAddSheetStateAdded(Object exerciseName) {
    return '$exerciseName 추가됨';
  }

  @override
  String get exerciseAddSheetSearchExercises => '운동 검색...';

  @override
  String get exerciseAddSheetSearchMyExercises => '내 운동 검색...';

  @override
  String get exerciseAddSheetSnapEquipment => '장비 촬영';

  @override
  String get exerciseAddSheetSnapped => '스냅됨';

  @override
  String get exerciseAddSheetSubtitle => '부제목';

  @override
  String get exerciseAddSheetTabAiPicks => 'AI 추천';

  @override
  String get exerciseAddSheetTabLibrary => '라이브러리';

  @override
  String get exerciseAddSheetTabMine => '내 운동';

  @override
  String get exerciseAddSheetTabSnapped => '스냅';

  @override
  String get exerciseAddSheetTryAgain => '다시 시도';

  @override
  String get exerciseAnalyticsCompareWithFriends => '친구와 비교';

  @override
  String get exerciseAnalyticsCompleteMoreSessionsTo =>
      '더 많은 세션을 완료하여 추세를 확인하세요';

  @override
  String get exerciseAnalyticsDrop => '떨어지다';

  @override
  String get exerciseAnalyticsInviteFriends => '친구 초대';

  @override
  String get exerciseAnalyticsLastSession => '마지막 세션';

  @override
  String get exerciseAnalyticsMyAnalytics => '내 분석';

  @override
  String exerciseAnalyticsPageAnalytics(Object name) {
    return '$name 분석';
  }

  @override
  String exerciseAnalyticsPageSeeHowYourPerformance(Object name) {
    return '$name 수행 능력이 친구들과 어떻게 비교되는지 확인해보세요.';
  }

  @override
  String exerciseAnalyticsPageValue(Object _unit) {
    return '0 $_unit';
  }

  @override
  String get exerciseAnalyticsPersonalRecord => '개인 기록';

  @override
  String get exerciseAnalyticsQuickStats => '빠른 통계';

  @override
  String get exerciseAnalyticsSetTypeDistribution => '세트 유형 분포';

  @override
  String get exerciseAnalyticsTotalSessions => '총 세션';

  @override
  String get exerciseAnalyticsTotalSets => '총 세트';

  @override
  String get exerciseAnalyticsTotalVolume => '총량';

  @override
  String get exerciseAnalyticsVolumeWeightXReps => '시간에 따른 볼륨 (중량 x 횟수)';

  @override
  String get exerciseAnalyticsWarmup => '워밍업';

  @override
  String get exerciseAnalyticsWeightProgression => '체중 진행';

  @override
  String get exerciseAnalyticsWeightProgressionChart => '중량 진행 차트';

  @override
  String get exerciseAnalyticsWorking => '일하고 있는';

  @override
  String exerciseBreakdownTemplateValue(Object reps, Object sets) {
    return '$sets × $reps';
  }

  @override
  String get exerciseCardAddToQueue => '대기열에 추가';

  @override
  String get exerciseCardAddToWorkout => '운동에 추가';

  @override
  String exerciseCardAddedTo(Object exerciseName, Object name) {
    return '\"$exerciseName\"을(를) $name에 추가했습니다';
  }

  @override
  String exerciseCardAddedToQueue(Object exerciseName) {
    return '\"$exerciseName\"을(를) 대기열에 추가했습니다';
  }

  @override
  String get exerciseCardAlreadyInQueue => '이미 대기열에 있습니다.';

  @override
  String get exerciseCardFailedToAddExercise => '운동 추가 실패';

  @override
  String get exerciseCardFailedToLoadWorkouts => '운동 불러오기 실패';

  @override
  String get exerciseCardGenerateAWorkoutPlan => '먼저 운동 계획을 생성하세요';

  @override
  String get exerciseCardNoUpcomingWorkouts => '예정된 운동 없음';

  @override
  String get exerciseCardOrAddToWorkout => '또는 운동에 추가';

  @override
  String get exerciseCardWillBeIncludedIn => '다음 운동에 포함됩니다';

  @override
  String get exerciseDetailActionGuide => '액션 가이드';

  @override
  String get exerciseDetailAutoPlay => '자동재생';

  @override
  String get exerciseDetailDownloadFailed => '다운로드 실패';

  @override
  String get exerciseDetailEachSide => '(양쪽)';

  @override
  String get exerciseDetailEnterWeightLbs => '체중(파운드)을 입력하세요.';

  @override
  String get exerciseDetailEquipmentNeeded => '필요한 장비';

  @override
  String get exerciseDetailGotIt => '알겠습니다';

  @override
  String get exerciseDetailImage => '영상';

  @override
  String get exerciseDetailInstructions => '지침';

  @override
  String get exerciseDetailLevel => '수준';

  @override
  String get exerciseDetailLoadingVideo => '동영상 로드 중...';

  @override
  String get exerciseDetailMuscle => '근';

  @override
  String get exerciseDetailNoHistoryForThis => '이 운동에 대한 기록이 아직 없습니다';

  @override
  String get exerciseDetailPrevious => '이전의';

  @override
  String get exerciseDetailPreviousPerformance => 'PR악랄한 성능';

  @override
  String get exerciseDetailRepRange => '대표 범위';

  @override
  String get exerciseDetailRestTimer => '휴식 타이머';

  @override
  String get exerciseDetailScreenAlternative => '대안';

  @override
  String get exerciseDetailScreenAvoid => '피하다';

  @override
  String get exerciseDetailScreenBreathing => '호흡';

  @override
  String get exerciseDetailScreenCoachingCues => '코칭 단서';

  @override
  String get exerciseDetailScreenCompleteAWorkoutTo => '운동을 완료하여 기록을 시작하세요';

  @override
  String get exerciseDetailScreenDifficulty => '어려움';

  @override
  String exerciseDetailScreenErrorLoadingHistory(Object error) {
    return '기록 불러오기 오류: $error';
  }

  @override
  String get exerciseDetailScreenExerciseInfo => '운동 정보';

  @override
  String get exerciseDetailScreenFavorite => '가장 좋아하는';

  @override
  String get exerciseDetailScreenForm => '형태';

  @override
  String exerciseDetailScreenMS(Object mins, Object secs) {
    return '$mins분 $secs초';
  }

  @override
  String get exerciseDetailScreenNoStatsForThis => '이 운동에 대한 통계가 아직 없습니다';

  @override
  String get exerciseDetailScreenNotes => '메모';

  @override
  String get exerciseDetailScreenQueue => '대기줄';

  @override
  String get exerciseDetailScreenSecondaryMuscles => '이차 근육';

  @override
  String get exerciseDetailScreenSetup => '설정';

  @override
  String get exerciseDetailScreenStaple => '스테이플';

  @override
  String get exerciseDetailScreenTempo => '속도';

  @override
  String exerciseDetailScreenUiErrorLoadingStats(Object error) {
    return '통계 불러오기 오류: $error';
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
  String get exerciseDetailSet => '세트';

  @override
  String get exerciseDetailSheetAvoid => '피하다';

  @override
  String get exerciseDetailSheetDeleteDownload => '다운로드를 삭제하시겠습니까?';

  @override
  String get exerciseDetailSheetDownloadCancelled => '다운로드 취소됨';

  @override
  String get exerciseDetailSheetDownloadRemoved => '다운로드 제거됨';

  @override
  String exerciseDetailSheetDownloading(Object pct) {
    return '다운로드 중 $pct%';
  }

  @override
  String get exerciseDetailSheetDownloadingVideo => '동영상 다운로드 중...';

  @override
  String get exerciseDetailSheetFavorite => '가장 좋아하는';

  @override
  String get exerciseDetailSheetLoading => '로드 중...';

  @override
  String get exerciseDetailSheetLog1rm => '로그 1RM';

  @override
  String exerciseDetailSheetMS(Object restMins, Object restSecs) {
    return '$restMins분 $restSecs초';
  }

  @override
  String get exerciseDetailSheetNoExercisesInCurrent => '현재 운동에 대체할 운동이 없습니다';

  @override
  String exerciseDetailSheetPartExerciseActionButtonsStateFailedToStaple(
    Object e,
  ) {
    return '고정 실패: $e';
  }

  @override
  String exerciseDetailSheetPartExerciseActionButtonsStateReplacedWith(
    Object exerciseName,
    Object selected,
  ) {
    return '\"$selected\"을(를) \"$exerciseName\"(으)로 교체했습니다';
  }

  @override
  String exerciseDetailSheetPartExerciseActionButtonsStateStapledTo(
    Object exerciseName,
    Object section,
    Object timing,
  ) {
    return '\"$exerciseName\"을(를) $section에 고정했습니다 ($timing)';
  }

  @override
  String exerciseDetailSheetPartExerciseActionButtonsStateUnstapled(
    Object exerciseName,
  ) {
    return '\"$exerciseName\" 고정 해제됨';
  }

  @override
  String exerciseDetailSheetPartLog1RMButtonRemoveTheOfflineVideo(
    Object exerciseName,
  ) {
    return '\"$exerciseName\"의 오프라인 동영상을 삭제할까요? 언제든지 다시 다운로드할 수 있습니다.';
  }

  @override
  String get exerciseDetailSheetQueue => '대기줄';

  @override
  String get exerciseDetailSheetReplaceWhichExercise => '어떤 운동을 바꾸시겠습니까?';

  @override
  String exerciseDetailSheetSet(Object setNumber) {
    return '$setNumber 세트';
  }

  @override
  String get exerciseDetailSheetStaple => '주요 운동';

  @override
  String get exerciseDetailSheetTrackYourMaxStrength => '최대 근력 추적';

  @override
  String get exerciseDetailStapleOptions => '스테이플 옵션';

  @override
  String get exerciseDetailTarget => '목표';

  @override
  String get exerciseDetailType => '유형';

  @override
  String get exerciseDetailVideo => '동영상';

  @override
  String get exerciseDetailVideoNotAvailable => '동영상을 사용할 수 없음';

  @override
  String get exerciseDetailWillAutoPlayWhen => '준비되면 자동 재생됩니다';

  @override
  String get exerciseDetailYourSessionsWillAppear => '여기에 세션이 표시됩니다';

  @override
  String get exerciseDetailsAiCoachTips => 'AI 코치 팁';

  @override
  String get exerciseDetailsBodyweight => '맨몸 운동';

  @override
  String get exerciseDetailsBreathing => '호흡';

  @override
  String get exerciseDetailsDetails => '상세 정보';

  @override
  String get exerciseDetailsDifficulty => '난이도';

  @override
  String get exerciseDetailsDontHaveEquipment => '장비 없음';

  @override
  String get exerciseDetailsEquipment => '장비';

  @override
  String get exerciseDetailsExerciseInfo => '운동 정보';

  @override
  String get exerciseDetailsFormCues => '자세 팁';

  @override
  String get exerciseDetailsNotSpecified => '지정되지 않음';

  @override
  String get exerciseDetailsPrimaryMuscle => '주동근';

  @override
  String get exerciseDetailsProTip => '전문가 팁';

  @override
  String get exerciseDetailsSecondaryMuscles => '협응근';

  @override
  String get exerciseDetailsSetup => '설정';

  @override
  String get exerciseDetailsSheetBodyweight => '체중';

  @override
  String get exerciseDetailsSheetBreathing => '호흡';

  @override
  String get exerciseDetailsSheetDifficulty => '어려움';

  @override
  String get exerciseDetailsSheetDonTHaveThis => '이 장비가 없나요?';

  @override
  String get exerciseDetailsSheetEquipment => '장비';

  @override
  String get exerciseDetailsSheetExerciseInfo => '운동 정보';

  @override
  String get exerciseDetailsSheetFormCues => '양식 단서';

  @override
  String get exerciseDetailsSheetLoadingAiCoachTips => 'AI 코치 팁 로드 중...';

  @override
  String get exerciseDetailsSheetPrimaryMuscle => '일차 근육';

  @override
  String get exerciseDetailsSheetProTip => '전문가 팁';

  @override
  String get exerciseDetailsSheetSecondaryMuscles => '이차 근육';

  @override
  String get exerciseDetailsSheetTapVideoToWatch => '\"비디오\"를 탭하여 자세 시연을 확인하세요';

  @override
  String get exerciseDetailsSheetVideo => '동영상';

  @override
  String get exerciseDetailsSheetWatchOutFor => '조심해';

  @override
  String get exerciseDetailsTapVideoHint => '동영상 힌트 탭하기';

  @override
  String get exerciseDetailsVideo => '동영상';

  @override
  String get exerciseDetailsWatchOutFor => '주의 사항';

  @override
  String get exerciseFilterApplyFilters => '필터 적용';

  @override
  String get exerciseFilterAvoidIfYouHave => '피해야 할 조건';

  @override
  String get exerciseFilterBodyPart => '신체 부위';

  @override
  String get exerciseFilterClearAll => '모두 지우기';

  @override
  String get exerciseFilterEquipment => '장비';

  @override
  String get exerciseFilterExerciseType => '운동 종류';

  @override
  String get exerciseFilterFailedToLoadFilters => '필터를 불러오지 못했습니다';

  @override
  String get exerciseFilterFilters => '필터';

  @override
  String get exerciseFilterGoals => '목표';

  @override
  String get exerciseFilterSuitableFor => '적합';

  @override
  String get exerciseHistoryAllTime => '상시';

  @override
  String get exerciseHistoryCompleteSomeWorkoutsTo =>
      '운동 기록을 확인하고 시간 경과에 따른 진행 상황을 추적하려면 몇 가지 운동을 완료하세요.';

  @override
  String get exerciseHistoryExerciseHistory => '운동 기록';

  @override
  String get exerciseHistoryExercisesPrs => '연습 및 PRs';

  @override
  String get exerciseHistoryFailedToLoadExercises => '운동 기록을 불러오지 못했습니다';

  @override
  String get exerciseHistoryKeepTrainingAndPushing =>
      '계속 훈련하며 한계를 돌파하세요. 더 강해질수록 개인 기록이 여기에 표시됩니다.';

  @override
  String get exerciseHistoryLast30Days => '최근 30일';

  @override
  String get exerciseHistoryNoExerciseHistoryYet => '아직 운동 기록이 없습니다';

  @override
  String get exerciseHistoryNoPersonalRecordsYet => '아직 개인 기록이 없습니다';

  @override
  String get exerciseHistoryPrStreak => 'PR 연속 기록';

  @override
  String get exerciseHistoryRecentPersonalRecords => '최근 개인 기록';

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
    return '#$rank';
  }

  @override
  String get exerciseHistorySearchExercises => '운동 검색...';

  @override
  String get exerciseHistoryTotalPrs => '총 PR';

  @override
  String get exerciseInfoLoadingVideo => '비디오 불러오는 중...';

  @override
  String get exerciseInfoRetrying => '재시도 중';

  @override
  String get exerciseManagementMixinAiPoweredAlternatives => 'AI 기반 대체 운동';

  @override
  String get exerciseManagementMixinBreakTheSupersetPair => '슈퍼세트 쌍 해제';

  @override
  String get exerciseManagementMixinChooseExerciseToPair => '함께 묶을 운동 선택';

  @override
  String get exerciseManagementMixinCreateSuperset => '슈퍼세트 생성';

  @override
  String exerciseManagementMixinCreateSupersetWith(Object name) {
    return '$name와(과) 슈퍼세트 만들기';
  }

  @override
  String get exerciseManagementMixinMakeThisTheActive => '이 운동을 활성 운동으로 설정';

  @override
  String get exerciseManagementMixinNoAvailableExercisesTo =>
      '함께 묶을 수 있는 운동이 없습니다';

  @override
  String get exerciseManagementMixinPairWithNextExercise => '다음 운동과 묶기';

  @override
  String get exerciseManagementMixinRemoveFromSuperset => '슈퍼세트에서 제거';

  @override
  String get exerciseManagementMixinRemoveFromThisWorkout => '이 운동에서 제거';

  @override
  String get exerciseManagementMixinReplaceExercise => '운동 교체';

  @override
  String get exerciseManagementMixinSkipExercise => '운동 건너뛰기';

  @override
  String get exerciseManagementMixinStartThisExercise => '이 연습을 시작하세요';

  @override
  String get exerciseMenuAddToFavorites => '즐겨찾기에 추가';

  @override
  String get exerciseMenuAddedToFavorites => '즐겨찾기에 추가됨';

  @override
  String get exerciseMenuLinkAsSuperset => '슈퍼세트로 연결';

  @override
  String get exerciseMenuMarkAsStaple => '주요 운동으로 표시';

  @override
  String get exerciseMenuMarkedAsStaple => '주요 운동으로 표시됨';

  @override
  String get exerciseMenuNeverRecommend => '추천 안 함';

  @override
  String get exerciseMenuQueuedForNext => '다음 운동으로 대기열에 추가됨';

  @override
  String get exerciseMenuRemoveAsStaple => '주요 운동에서 제거';

  @override
  String get exerciseMenuRemoveFromFavorites => '즐겨찾기에서 제거';

  @override
  String get exerciseMenuRemoveFromQueue => '대기열에서 제거';

  @override
  String get exerciseMenuRemoveFromWorkout => '운동에서 제거';

  @override
  String get exerciseMenuRemovedFromFavorites => '즐겨찾기에서 제거됨';

  @override
  String get exerciseMenuRemovedFromQueue => '대기열에서 제거됨';

  @override
  String get exerciseMenuRemovedFromStaples => '주요 운동에서 제거됨';

  @override
  String get exerciseMenuRepeatNextTime => '다음번에 반복';

  @override
  String get exerciseMenuSwapExercise => '운동 교체';

  @override
  String get exerciseMenuViewHistory => '기록 보기';

  @override
  String get exerciseMenuWhatDoTheseMean => '이게 무슨 뜻인가요?';

  @override
  String get exerciseMiniChartNotEnoughHistory => '기록이 충분하지 않습니다';

  @override
  String get exerciseNavigationMixinApplyToAllLinked => '연결된 모든 운동에 적용하시겠습니까?';

  @override
  String get exerciseNavigationMixinBarType => '바 유형';

  @override
  String get exerciseNavigationMixinCannotRemoveTheLast => '마지막 운동은 제거할 수 없습니다';

  @override
  String exerciseNavigationMixinChangedTo(Object displayName) {
    return '$displayName(으)로 변경됨';
  }

  @override
  String get exerciseNavigationMixinContinueAnyway => '계속 진행';

  @override
  String get exerciseNavigationMixinDoNotShowAgain => '다시 보지 않기';

  @override
  String get exerciseNavigationMixinEndWorkout => '운동 종료';

  @override
  String exerciseNavigationMixinFailedToAddExercises(Object e) {
    return '운동 추가 실패: $e';
  }

  @override
  String exerciseNavigationMixinFailedToAddExercises2(Object e) {
    return '운동 추가 실패: $e';
  }

  @override
  String get exerciseNavigationMixinIncompleteExercises => '불완전한 연습';

  @override
  String get exerciseNavigationMixinMyGym => '나의 헬스장';

  @override
  String get exerciseNavigationMixinNoJustThisOne => '아니요, 이것만';

  @override
  String get exerciseNavigationMixinRemove => '제거하다';

  @override
  String get exerciseNavigationMixinRemoveExercise => '운동 제거';

  @override
  String exerciseNavigationMixinRemoveFromThisWorkout(Object name) {
    return '이 운동에서 \"$name\"을(를) 삭제할까요?';
  }

  @override
  String exerciseNavigationMixinRemoved(Object name) {
    return '$name 삭제됨';
  }

  @override
  String exerciseNavigationMixinRemovedFromSuperset(Object name) {
    return '슈퍼세트에서 $name 삭제됨';
  }

  @override
  String exerciseNavigationMixinSetThisCountSets(Object newCount) {
    return '슈퍼세트 그룹의 모든 운동에 이 횟수($newCount 세트)를 설정할까요?';
  }

  @override
  String get exerciseNavigationMixinSomeExercisesHaveMissing =>
      '일부 연습에는 로그가 누락되었습니다.';

  @override
  String exerciseNavigationMixinSuperset(Object name, Object name1) {
    return '슈퍼세트: $name + $name1';
  }

  @override
  String exerciseNavigationMixinSuperset2(Object name) {
    return '슈퍼세트: $name';
  }

  @override
  String get exerciseNavigationMixinSwapExercise => '운동 교체';

  @override
  String exerciseNavigationMixinUiRemoved(Object name) {
    return '$name 삭제됨';
  }

  @override
  String get exerciseNavigationMixinUndo => '끄르다';

  @override
  String get exerciseNavigationMixinUseTheNotesSection => '세트 아래의 메모 섹션을 사용하세요';

  @override
  String get exerciseNavigationMixinYesApplyToAll => '네, 모두 적용';

  @override
  String get exerciseOptionsAddToSuperset => '슈퍼세트에 추가';

  @override
  String get exerciseOptionsChangeEquipment => '장비 변경';

  @override
  String get exerciseOptionsChangeRepsProgression => '담당자 진행 변경';

  @override
  String get exerciseOptionsExerciseHistory => '운동 기록';

  @override
  String get exerciseOptionsInfoExerciseOptionsExplained => '운동 옵션 설명';

  @override
  String get exerciseOptionsInfoFavorite => '가장 좋아하는';

  @override
  String get exerciseOptionsInfoLinkAsSuperset => '슈퍼세트로 연결';

  @override
  String get exerciseOptionsInfoMarkAsACore =>
      '절대로 회전되지 않는 코어 리프트로 표시하십시오. AI는 항상 운동에 주요 운동을 포함하므로 지속적으로 점진적인 과부하를 원하는 복합 운동에 적합합니다.';

  @override
  String get exerciseOptionsInfoNeverRecommend => '절대 추천하지 않음';

  @override
  String get exerciseOptionsInfoPairWithAnotherExercise =>
      '다른 운동과 묶어 휴식 시간을 최소화하며 연속으로 수행하세요. 시간 효율성과 근육 펌핑에 좋습니다.';

  @override
  String get exerciseOptionsInfoPermanentlyBlockThisExercis =>
      '향후 AI 추천에서 이 운동을 영구적으로 차단합니다. 싫어하거나 부상으로 인해 할 수 없는 운동에 사용하세요.';

  @override
  String get exerciseOptionsInfoQueueThisExerciseTo =>
      '다음 운동에 표시되도록 이 운동을 대기열에 추가하세요. 집중하고 싶은 운동에 적합합니다. 대기 중인 운동은 사용하지 않으면 7일 후에 만료됩니다.';

  @override
  String get exerciseOptionsInfoRemoveFromWorkout => '운동에서 제거';

  @override
  String get exerciseOptionsInfoRemoveThisExerciseFrom =>
      '현재 운동에서만 이 운동을 제거하세요. 해당 운동은 향후 운동에서 다시 나타날 수 있습니다.';

  @override
  String get exerciseOptionsInfoRepeatNextTime => '다음 번에 반복';

  @override
  String get exerciseOptionsInfoReplaceWithASimilar =>
      '동일한 근육을 대상으로 하는 유사한 운동으로 대체하세요. AI 제안, 최근 교체 중에서 선택하거나 전체 라이브러리를 찾아보세요.';

  @override
  String get exerciseOptionsInfoSaveExercisesYouLove =>
      '빠른 액세스를 위해 좋아하는 운동을 저장하세요. 즐겨찾기는 운동 라이브러리 필터링 보기에 표시되며 AI 추천에서 우선순위가 지정됩니다.';

  @override
  String get exerciseOptionsInfoSeeYourPerformanceHistory =>
      '시간 경과에 따른 이 운동의 성과 기록 및 진행 차트를 확인하세요.';

  @override
  String get exerciseOptionsInfoStapleExercise => '필수 운동';

  @override
  String get exerciseOptionsInfoSwapExercise => '스왑 운동';

  @override
  String get exerciseOptionsInfoViewHistory => '기록 보기';

  @override
  String get exerciseOptionsNotes => '메모';

  @override
  String get exerciseOptionsRemoveAndDonT => '제거하고 권장하지 않음';

  @override
  String get exerciseOptionsRemoveFromWorkout => '운동에서 제거';

  @override
  String get exerciseOptionsReportPain => '통증 보고';

  @override
  String get exerciseOptionsSwapExercise => '운동 교체';

  @override
  String get exerciseOptionsVideoInstructions => '비디오 및 지침';

  @override
  String exercisePickerSheetAddAsCustom(Object name) {
    return '\"$name\"을(를) 사용자 지정으로 추가';
  }

  @override
  String get exercisePickerSheetAddExerciseToAvoid => '피할 운동 추가';

  @override
  String get exercisePickerSheetAddFavoriteExercise => '즐겨찾는 운동 추가';

  @override
  String get exercisePickerSheetAddStapleExercise => '주요 운동 추가';

  @override
  String get exercisePickerSheetAddToExerciseQueue => '운동 대기열에 추가';

  @override
  String get exercisePickerSheetAi => 'AI';

  @override
  String get exercisePickerSheetBodyPart => '신체 부위';

  @override
  String get exercisePickerSheetCanTFindYour => '운동을 찾을 수 없나요? 커스텀으로 추가하세요';

  @override
  String get exercisePickerSheetClearAll => '모두 지우기';

  @override
  String get exercisePickerSheetCreateCustomExercise => '커스텀 운동 만들기';

  @override
  String get exercisePickerSheetCustom => '커스텀';

  @override
  String get exercisePickerSheetCustomOnly => '커스텀만';

  @override
  String get exercisePickerSheetEquipment => '운동 기구';

  @override
  String exercisePickerSheetNSelected(Object n) {
    return '$n개 선택됨';
  }

  @override
  String get exercisePickerSheetNoExercisesFound => '운동을 찾을 수 없습니다';

  @override
  String get exercisePickerSheetOrTypeAboveTo => '또는 위에서 입력하여 전체 운동 라이브러리 검색';

  @override
  String exercisePickerSheetPartExercisePickerSheetStateShowingOf(
    Object length,
    Object length1,
  ) {
    return '$length1개 중 $length개 표시 중';
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
  String get exercisePickerSheetSave => '저장';

  @override
  String exercisePickerSheetSaveN(Object n) {
    return '저장 ($n)';
  }

  @override
  String get exercisePickerSheetSearchForCoreLifts => '운동에 고정할 핵심 리프트 검색';

  @override
  String get exercisePickerSheetSearchForExercises => '운동 검색';

  @override
  String get exercisePickerSheetSearchForExercisesToAdd => '즐겨찾기에 추가할 운동 검색';

  @override
  String get exercisePickerSheetSearchForExercisesToInclude =>
      '다음 운동에 포함할 운동 검색';

  @override
  String get exercisePickerSheetSearchForExercisesToSkip => '건너뛸 운동 검색';

  @override
  String get exercisePickerSheetSearchTryPushRow =>
      '검색 — \"push\", \"row\", \"squat\"를 시도해 보세요.';

  @override
  String get exercisePickerSheetSearching => '검색 중...';

  @override
  String get exercisePickerSheetShowingResultsFor => '검색 결과: ';

  @override
  String get exercisePickerSheetTapExercisesToSelect => '운동을 탭하여 다중 선택';

  @override
  String get exercisePickerSheetTryADifferentSearch => '다른 검색어나 필터를 시도하세요';

  @override
  String get exercisePickerSheetType => '유형';

  @override
  String get exercisePickerSheetTypeToSearchOr => '입력하여 검색하거나 필터를 사용하여 탐색';

  @override
  String get exercisePickerSheetYourCustomExercises => '맞춤형 운동';

  @override
  String get exercisePreferencesCardAiWillPrioritizeThese => 'AI가 이 운동을 우선시합니다';

  @override
  String exercisePreferencesCardAvoided(Object avoidedCount) {
    return '제외됨 $avoidedCount개';
  }

  @override
  String get exercisePreferencesCardCooldownStretch => '쿨다운 스트레칭';

  @override
  String get exercisePreferencesCardCoreLiftsThatNever => '절대 교체되지 않는 핵심 리프트';

  @override
  String get exercisePreferencesCardCustomExercises => '커스텀 운동';

  @override
  String get exercisePreferencesCardCustomizeStepPerEquipme =>
      '장비별 +/- 단계 사용자 지정';

  @override
  String get exercisePreferencesCardCustomizeWhichExercisesAppe =>
      '운동에 표시될 운동 사용자 지정';

  @override
  String get exercisePreferencesCardDynamicWarmupBeforeWorkouts => '운동 전 동적 웜업';

  @override
  String get exercisePreferencesCardEnableOrDisableWorkout =>
      '운동 단계 활성화 또는 비활성화';

  @override
  String get exercisePreferencesCardExercisePreferences => '운동 선호도';

  @override
  String get exercisePreferencesCardExercisePreferences2 => '연습 PR참고자료';

  @override
  String get exercisePreferencesCardExercisePreferencesExplained =>
      '운동 환경 설정 설명';

  @override
  String get exercisePreferencesCardExerciseQueue => '운동 대기열';

  @override
  String exercisePreferencesCardExercises(Object customCount) {
    return '운동 $customCount개';
  }

  @override
  String exercisePreferencesCardExercises2(Object favoriteCount) {
    return '운동 $favoriteCount개';
  }

  @override
  String exercisePreferencesCardExercises3(Object stapleCount) {
    return '운동 $stapleCount개';
  }

  @override
  String get exercisePreferencesCardExercisesToAvoid => '피해야 할 운동';

  @override
  String get exercisePreferencesCardFavoriteExercises => '즐겨찾는 운동';

  @override
  String get exercisePreferencesCardFavoritesAvoidedQueue => '즐겨찾기, 제외, 대기열';

  @override
  String get exercisePreferencesCardIncompleteExerciseWarning => '미완료 운동 경고';

  @override
  String get exercisePreferencesCardMusclesToAvoid => '피해야 할 근육';

  @override
  String get exercisePreferencesCardQueueExercisesForNext => '다음 운동을 위해 운동 대기';

  @override
  String exercisePreferencesCardQueued(Object queueCount) {
    return '대기 중 $queueCount개';
  }

  @override
  String get exercisePreferencesCardSkipOrReduceMuscle => '근육 그룹 건너뛰기 또는 줄이기';

  @override
  String get exercisePreferencesCardSkipSpecificExercises => '특정 운동 건너뛰기';

  @override
  String get exercisePreferencesCardStapleExercises => '필수 운동';

  @override
  String get exercisePreferencesCardStretchingAfterWorkouts => '운동 후 스트레칭';

  @override
  String get exercisePreferencesCardWarmupCooldown => '웜업 및 쿨다운';

  @override
  String get exercisePreferencesCardWarmupPhase => '웜업 단계';

  @override
  String get exercisePreferencesCardWarnBeforeFinishingWith =>
      '기록되지 않은 세트로 종료하기 전 경고';

  @override
  String get exercisePreferencesCardWeightIncrements => '무게 증분';

  @override
  String get exercisePreferencesCardWhatSThis => '이게 무엇인가요?';

  @override
  String get exercisePreferencesCardWorkoutMode => '운동 모드';

  @override
  String get exercisePreferencesCardYourPersonalExerciseLibrary =>
      '나만의 운동 라이브러리';

  @override
  String get exercisePreviewOverlayFormDemo => '자세 시연';

  @override
  String exercisePreviewOverlayS(Object _remainingSeconds) {
    return '$_remainingSeconds초';
  }

  @override
  String get exercisePreviewOverlayTapAnywhereToStart => '시작하려면 아무 곳이나 탭하세요';

  @override
  String exercisePreviewOverlayTarget(Object muscles) {
    return '타겟: $muscles';
  }

  @override
  String get exerciseProgressDetail => '•  ';

  @override
  String get exerciseProgressDetailHistory => '기록';

  @override
  String get exerciseProgressDetailInsights => '인사이트';

  @override
  String get exerciseProgressDetailNoDataForThis => '이 운동에 대한 데이터가 아직 없습니다';

  @override
  String get exerciseProgressDetailNoSessionsRecorded => '기록된 세션이 없습니다';

  @override
  String get exerciseProgressDetailProgress => '진행 상황';

  @override
  String get exerciseProgressionsAdvance => '진행';

  @override
  String get exerciseProgressionsAdvanceProgression => '다음 단계로 진행할까요?';

  @override
  String get exerciseProgressionsBestLoad => '최고 중량';

  @override
  String get exerciseProgressionsBestReps => '최고 반복 횟수';

  @override
  String get exerciseProgressionsEarnTheHarderVariant => '더 어려운 변형 동작 잠금 해제';

  @override
  String get exerciseProgressionsLoadingYourProgressions => '진행 상황을 불러오는 중...';

  @override
  String get exerciseProgressionsMasteryProgress => '숙련도 진행 상황';

  @override
  String get exerciseProgressionsNoProgressionsYet => '아직 진행 단계가 없습니다';

  @override
  String get exerciseProgressionsNotYet => '아직 아님';

  @override
  String get exerciseProgressionsOneMoreTooEasy =>
      '\"너무 쉬움\" 세션을 한 번 더 완료하면 다음 변형 동작이 잠금 해제됩니다.';

  @override
  String get exerciseProgressionsOtherTrackedExercises => '기타 추적 중인 운동';

  @override
  String get exerciseProgressionsProgressions => '진행 단계';

  @override
  String get exerciseProgressionsReadyToAdvance => '진행 준비 완료';

  @override
  String get exerciseProgressionsReadyToAdvance2 => '진행 준비 완료';

  @override
  String get exerciseProgressionsReadyToProgress => '진행 준비 완료';

  @override
  String get exerciseProgressionsRefresh => '새로고침';

  @override
  String exerciseProgressionsScreenAdvanceTo(Object suggestedExercise) {
    return '$suggestedExercise(으)로 진행';
  }

  @override
  String exerciseProgressionsScreenChain(Object chainName) {
    return '$chainName 체인';
  }

  @override
  String exerciseProgressionsScreenConfident(Object confidencePct) {
    return '확신도 $confidencePct%';
  }

  @override
  String exerciseProgressionsScreenCouldNotAdvance(Object e) {
    return '진행할 수 없음: $e';
  }

  @override
  String exerciseProgressionsScreenDifficulty(Object difficultyLevel) {
    return '난이도 $difficultyLevel/10';
  }

  @override
  String exerciseProgressionsScreenEasySessions(
    Object _target,
    Object consecutiveEasy,
  ) {
    return '쉬운 세션 $consecutiveEasy / $_target회';
  }

  @override
  String exerciseProgressionsScreenKg(Object mastery) {
    return '$mastery kg';
  }

  @override
  String exerciseProgressionsScreenReps(Object currentMaxReps) {
    return '$currentMaxReps회';
  }

  @override
  String exerciseProgressionsScreenSessionsBest(Object totalSessions) {
    return '세션 $totalSessions회 · 최고 기록 ';
  }

  @override
  String exerciseProgressionsScreenYouWillMoveFrom(
    Object exerciseName,
    Object suggestedExercise,
  ) {
    return '$exerciseName에서 $suggestedExercise(으)로 이동합니다. ';
  }

  @override
  String get exerciseProgressionsSessions => '세션';

  @override
  String get exerciseProgressionsTryAgain => '다시 시도';

  @override
  String get exerciseProgressionsUnlocked => '잠금 해제됨';

  @override
  String get exerciseProgressionsYourProgressionChains => '나의 진행 체인';

  @override
  String get exerciseQueue => ' • ';

  @override
  String get exerciseQueueAddToQueue => '대기열에 추가';

  @override
  String get exerciseQueueExerciseQueue => '운동 대기열';

  @override
  String get exerciseQueueNoExercisesQueued => '대기 중인 운동 없음';

  @override
  String get exerciseQueueQueuedExercisesWillBe =>
      '대기열에 추가된 운동은 다음 운동에 포함됩니다. 항목은 7일 후 만료됩니다.';

  @override
  String get exerciseQueueRemove => '제거';

  @override
  String get exerciseQueueRemoveFromQueue => '대기열에서 제거할까요?';

  @override
  String exerciseQueueScreenAddedToQueue(Object exerciseName) {
    return '\"$exerciseName\"을(를) 대기열에 추가했습니다';
  }

  @override
  String exerciseQueueScreenExpiresInDays(Object daysLeft) {
    return '$daysLeft일 후 만료';
  }

  @override
  String exerciseQueueScreenRemoveFromYourQueue(Object exerciseName) {
    return '\"$exerciseName\"을(를) 대기열에서 삭제할까요? 다음 운동에 포함되지 않습니다.';
  }

  @override
  String get exerciseQueueTheseExercisesWillBe =>
      '이 운동들은 다음 운동에 포함됩니다. 대기열 항목은 7일 후 만료됩니다.';

  @override
  String get exerciseSafetyAuditAllExercisesTagged => '모든 운동 태그 완료!';

  @override
  String get exerciseSafetyAuditFailedToLoadExercises => '운동을 불러오지 못했습니다';

  @override
  String get exerciseSafetyAuditInjurySafeFlags => '부상 방지 플래그';

  @override
  String get exerciseSafetyAuditMovementPattern => '움직임 패턴';

  @override
  String get exerciseSafetyAuditNoDifficulty => '난이도 없음';

  @override
  String get exerciseSafetyAuditNoExercisesPendingManual =>
      '수동 검토 대기 중인 운동이 없습니다.';

  @override
  String get exerciseSafetyAuditNoPattern => '패턴 없음';

  @override
  String get exerciseSafetyAuditOptionalCiteSourceExplain =>
      '선택 사항: 출처 인용, 예외 상황 설명, 모호한 점 표시...';

  @override
  String get exerciseSafetyAuditRefresh => '새로고침';

  @override
  String get exerciseSafetyAuditReview => '검토';

  @override
  String get exerciseSafetyAuditReviewerNotes => '검토자 메모';

  @override
  String get exerciseSafetyAuditSafetyDifficulty => '안전 난이도';

  @override
  String get exerciseSafetyAuditSafetyTagAudit => '안전 태그 감사';

  @override
  String get exerciseSafetyAuditSaveTags => '태그 저장';

  @override
  String exerciseSafetyAuditScreenExerciseSPendingAudit(Object length) {
    return '검토 대기 중인 운동 $length개';
  }

  @override
  String get exerciseSafetyAuditSelectDifficulty => '난이도 선택';

  @override
  String get exerciseSafetyAuditSelectMovementPattern => '움직임 패턴 선택';

  @override
  String get exerciseSafetyAuditTryAgain => '다시 시도';

  @override
  String get exerciseScienceResearchAllTrainingParametersAre =>
      '모든 훈련 매개변수는 동료 검토를 거친 운동 과학 문헌을 기반으로 합니다. 개인별 결과는 다를 수 있습니다.';

  @override
  String get exerciseScienceResearchAmericanCollegeOfSports =>
      '미국 스포츠 의학회 (ACSM)';

  @override
  String get exerciseScienceResearchAndroulakisKorakakisPFis =>
      'Androulakis-Korakakis, P., Fisher, J. P. & Steele, J.';

  @override
  String get exerciseScienceResearchBarbaRuizCEt => 'Barba-Ruiz, C. et al.';

  @override
  String get exerciseScienceResearchEffectsOfSupersetConfigurat =>
      '바벨 벤치 프레스의 운동 역학, 운동학 및 인지된 노력에 대한 슈퍼세트 구성의 효과';

  @override
  String get exerciseScienceResearchEpleyBrzyckiMayhewHelms =>
      'Epley, Brzycki, Mayhew / Helms, E. R. et al.';

  @override
  String get exerciseScienceResearchEssentialsOfStrengthTrainin =>
      '근력 훈련 및 컨디셔닝의 필수 요소';

  @override
  String get exerciseScienceResearchEverySubmittedSourceIs =>
      '제출된 모든 출처는 지식 베이스에 추가되기 전에 사람이 직접 검토하고 검증합니다.';

  @override
  String get exerciseScienceResearchEvidenceBasedTraining => '근거 기반 훈련';

  @override
  String get exerciseScienceResearchFeedDataToRag => 'RAG에 데이터 공급';

  @override
  String get exerciseScienceResearchFeedYourOwnResearch =>
      '나만의 연구 논문, 운동 데이터베이스 및 훈련 방법론을 RAG(검색 증강 생성) 시스템에 공급하세요. 이를 통해 AI 코치가 개인 맞춤형 운동 계획을 생성할 때 더 높은 품질의 출처를 활용하여 최신 과학에 기반한 더 스마트하고 맞춤화된 제안을 제공할 수 있습니다.';

  @override
  String get exerciseScienceResearchFonsecaRMEt => 'Fonseca, R. M. et al.';

  @override
  String get exerciseScienceResearchGoldsteinANLeung =>
      'Goldstein, A. N. & Leung, E.';

  @override
  String get exerciseScienceResearchGuidelinesForExerciseTestin =>
      '운동 검사 및 처방 가이드라인';

  @override
  String get exerciseScienceResearchHaffGGTriplett =>
      'Haff, G. G. & Triplett, N. T.';

  @override
  String get exerciseScienceResearchHowItWorks => '작동 원리';

  @override
  String get exerciseScienceResearchImportantGuidelines => '중요 가이드라인';

  @override
  String get exerciseScienceResearchIsraetelMRpStrength =>
      'Israetel, M. / RP Strength';

  @override
  String get exerciseScienceResearchKeyFindings => '주요 연구 결과';

  @override
  String get exerciseScienceResearchResearch => '연구';

  @override
  String exerciseScienceResearchScreenEveryWorkoutParameterIn(Object appName) {
    return '$appName의 모든 운동 매개변수는 동료 검토를 거친 운동 과학에 기반합니다. 논문을 탭하여 자세한 내용을 확인하세요.';
  }

  @override
  String exerciseScienceResearchScreenHowUsesThis(Object appName) {
    return '$appName 활용 방법';
  }

  @override
  String exerciseScienceResearchScreenValue(Object journal, Object year) {
    return '$journal, $year';
  }

  @override
  String get exerciseScienceResearchUploadData => '데이터 업로드';

  @override
  String get exerciseScienceResearchUploadPdfsArticlesOr =>
      '운동 과학 연구가 포함된 PDF, 기사 또는 텍스트 파일을 업로드하세요. 시스템이 콘텐츠를 처리하고 색인화하여 AI가 운동을 생성할 때 참고할 수 있도록 합니다.';

  @override
  String get exerciseScienceResearchZourdosMCEt => 'Zourdos, M. C. et al.';

  @override
  String get exerciseSearchBarSearchExercisesOrEquipment => '운동 또는 장비 검색...';

  @override
  String get exerciseSearchBarSearchPrograms => '프로그램 검색...';

  @override
  String exerciseSearchResultsBest(Object bestSetDisplay) {
    return '최고 기록: $bestSetDisplay';
  }

  @override
  String get exerciseSearchResultsFailedToSearchExercises => '운동 검색 실패';

  @override
  String exerciseSearchResultsMoreWorkouts(Object results) {
    return '$results개 더 보기';
  }

  @override
  String get exerciseSearchResultsNoResultsFound => '검색 결과 없음';

  @override
  String exerciseSearchResultsNoWorkoutsContainingIn(Object exerciseName) {
    return '선택한 기간 내에 \"$exerciseName\"을(를) 포함하는 운동이 없습니다';
  }

  @override
  String exerciseSearchResultsSets(Object setsCompleted) {
    return '$setsCompleted세트';
  }

  @override
  String exerciseSearchResultsWorkoutsFound(
    Object exerciseName,
    Object totalResults,
  ) {
    return '\"$exerciseName\" - $totalResults개의 운동을 찾았습니다';
  }

  @override
  String get exerciseSetTracker15s => '−15초';

  @override
  String get exerciseSetTracker15s2 => '+15초';

  @override
  String get exerciseSetTrackerAddNotesHere => '여기에 메모 추가...';

  @override
  String get exerciseSetTrackerAddSet => '세트 추가';

  @override
  String get exerciseSetTrackerReps => '횟수';

  @override
  String get exerciseSetTrackerRestTarget => '휴식 목표';

  @override
  String exerciseSetTrackerS(Object seconds) {
    return '$seconds초';
  }

  @override
  String exerciseSetTrackerSavedAsYourDefault(Object muscle) {
    return '$muscle에 대한 기본값으로 저장됨';
  }

  @override
  String get exerciseSetTrackerSet => '세트';

  @override
  String get exerciseSetTrackerTarget => '목표';

  @override
  String get exerciseStatsAvgRpe => '평균 RPE';

  @override
  String get exerciseStatsEst1rm => '예상 1RM';

  @override
  String get exerciseStatsMaxReps => '최대 횟수';

  @override
  String get exerciseStatsMaxWeight => '최대 중량';

  @override
  String get exerciseStatsProgression => '진행 상황';

  @override
  String exerciseStatsSheetKg(Object item) {
    return '$item kg';
  }

  @override
  String exerciseStatsSheetKg2(Object item) {
    return '$item kg';
  }

  @override
  String get exerciseStatsTotalSets => '총 세트';

  @override
  String get exerciseStatsVolume => '볼륨';

  @override
  String exerciseStatsWidgetsAchieved(Object formattedAchievedDate) {
    return '$formattedAchievedDate 달성';
  }

  @override
  String get exerciseStatsWidgetsEst1rm => '예상 1RM';

  @override
  String get exerciseStatsWidgetsNotEnoughDataTo => '차트를 표시할 데이터가 부족합니다';

  @override
  String get exerciseStatsWidgetsPersonalRecords => '개인 기록';

  @override
  String get exerciseStatsWidgetsSessions => '세션';

  @override
  String get exerciseStatsWidgetsSetsReps => '세트 × 횟수';

  @override
  String get exerciseStatsWidgetsSummary => '요약';

  @override
  String get exerciseStatsWidgetsTotalVolume => '총 볼륨';

  @override
  String exerciseStatsWidgetsTrainingFrequency(Object formattedFrequency) {
    return '운동 빈도: $formattedFrequency';
  }

  @override
  String get exerciseStatsWidgetsVolume => '볼륨';

  @override
  String get exerciseStatsWidgetsWeight => '중량';

  @override
  String get exerciseStatsWidgetsWeightChange => '중량 변화';

  @override
  String get exerciseSwapAiUnavailable => 'AI 추천을 사용할 수 없습니다';

  @override
  String get exerciseSwapAskAiHint => '예: 어깨가 안 좋을 때 좋은 운동...';

  @override
  String get exerciseSwapAskAiTitle => 'AI에게 추천받기';

  @override
  String get exerciseSwapBadgeBestMatch => '최적의 매치';

  @override
  String get exerciseSwapBadgeTopPick => '추천';

  @override
  String get exerciseSwapFindingAlternatives => '최적의 대체 운동을 찾는 중';

  @override
  String get exerciseSwapGetAiSuggestions => 'AI 추천받기';

  @override
  String get exerciseSwapInstructions => '방법';

  @override
  String get exerciseSwapListeningNow => '듣는 중... 말씀하세요';

  @override
  String get exerciseSwapMatchingEquipment => '장비, 근육 및 운동 기록을 매칭하는 중';

  @override
  String get exerciseSwapNoAlternatives => '대체 운동을 찾을 수 없습니다';

  @override
  String get exerciseSwapOptionSwap => '옵션 교체';

  @override
  String get exerciseSwapSheetAiPicks => 'AI 추천';

  @override
  String get exerciseSwapSheetAiPicksUnavailable => 'AI 추천을 사용할 수 없습니다';

  @override
  String get exerciseSwapSheetAnyEquipment => '모든 장비';

  @override
  String get exerciseSwapSheetAskAiForSuggestions => 'AI에게 제안 요청하기';

  @override
  String get exerciseSwapSheetEGIOnly => '예: \"덤벨만 있어요\"';

  @override
  String get exerciseSwapSheetFailedToSwapExercise => '운동 교체 실패';

  @override
  String get exerciseSwapSheetFindingMuscleMatchedAlterna =>
      '근육 타겟 대체 운동 찾는 중...';

  @override
  String get exerciseSwapSheetFindingSimilarExercises => '유사한 운동 찾는 중...';

  @override
  String get exerciseSwapSheetFindingYourBestAlternatives => '최적의 대체 운동 찾는 중';

  @override
  String get exerciseSwapSheetGetAiSuggestions => 'AI 제안 받기';

  @override
  String get exerciseSwapSheetImport => '가져오기';

  @override
  String get exerciseSwapSheetInstructions => '지침';

  @override
  String get exerciseSwapSheetLibrary => '라이브러리';

  @override
  String get exerciseSwapSheetListeningSpeakNow => '듣는 중... 말씀하세요';

  @override
  String get exerciseSwapSheetLoadingRecentExercises => '최근 운동 불러오는 중...';

  @override
  String get exerciseSwapSheetMatchingEquipmentMusclesA =>
      '장비, 근육 및 운동 기록 매칭 중';

  @override
  String get exerciseSwapSheetNoAlternativesYet => '아직 대체 운동 없음';

  @override
  String get exerciseSwapSheetNoRecentSwaps => '최근 교체 기록 없음';

  @override
  String exerciseSwapSheetPartExerciseSwapSheetStateSwappedTo(
    Object newExerciseName,
  ) {
    return '$newExerciseName(으)로 교체됨';
  }

  @override
  String get exerciseSwapSheetReason => '이유: ';

  @override
  String get exerciseSwapSheetRecent => '최근';

  @override
  String get exerciseSwapSheetReplacing => '교체 중';

  @override
  String get exerciseSwapSheetSearchExercises => '운동 검색...';

  @override
  String get exerciseSwapSheetSimilar => '유사';

  @override
  String get exerciseSwapSheetSnapEquipment => '장비 촬영';

  @override
  String get exerciseSwapSheetSnapped => '촬영됨';

  @override
  String get exerciseSwapSheetSpeechRecognitionNotAvailab =>
      '음성 인식 기능을 사용할 수 없습니다';

  @override
  String get exerciseSwapSheetSwap => '교체';

  @override
  String get exerciseSwapSheetSwapExercise => '운동 교체';

  @override
  String get exerciseSwapSheetSwapToThisExercise => '이 운동으로 교체';

  @override
  String get exerciseSwapSheetTabAnyEquipment => '모든 장비';

  @override
  String get exerciseSwapSheetTabRecent => '최근';

  @override
  String get exerciseSwapSheetTabSimilar => '유사한 운동';

  @override
  String get exerciseSwapSheetTabSnapped => '스냅';

  @override
  String get exerciseSwapSheetTitle => '제목';

  @override
  String get exerciseSwapSheetTryAgain => '다시 시도';

  @override
  String get exerciseSwapSheetTryAiSuggestions => 'AI 제안 시도';

  @override
  String get exerciseSwapSheetTryRephrasingYourRequest =>
      '위의 요청을 다시 작성하거나, 다른 이유를 선택하거나, 라이브러리 탭을 확인하세요.';

  @override
  String get exerciseSwapSheetYourSwapHistoryWill => '교체 기록이 여기에 표시됩니다';

  @override
  String get exerciseSwapSwapToThis => '이 운동으로 교체';

  @override
  String get exerciseSwapTryRephrasing => '요청 내용을 다시 작성해 보세요';

  @override
  String get exerciseTableHeaderLast => '이전';

  @override
  String get exerciseTableHeaderSet => '세트';

  @override
  String get exerciseTableHeaderTarget => '목표';

  @override
  String get exercisesLoadMore => '더 보기';

  @override
  String exercisesTabFailedToLoadExercises(Object error) {
    return '운동 목록을 불러오지 못했습니다: $error';
  }

  @override
  String get exercisesTabHistoryToggle => '기록';

  @override
  String expandableSummaryExerciseCardKg(Object weightKg) {
    return '$weightKg kg';
  }

  @override
  String expandableSummaryExerciseCardTime(Object formatted) {
    return '시간: $formatted';
  }

  @override
  String get expandableSummaryExerciseReps => '횟수';

  @override
  String get expandableSummaryExerciseSet => '세트';

  @override
  String get expandableSummaryExerciseVsPreviousSession => '이전 세션 대비';

  @override
  String get expandableSummaryExerciseWeight => '중량';

  @override
  String get expandedExerciseCardAddToFavorites => '즐겨찾기에 추가';

  @override
  String get expandedExerciseCardAlternatingHands => '양손 번갈아 하기';

  @override
  String get expandedExerciseCardBreathing => '호흡';

  @override
  String get expandedExerciseCardBreathingGuide => '호흡 가이드';

  @override
  String get expandedExerciseCardCollapse => '접기';

  @override
  String get expandedExerciseCardDetails => '상세 정보';

  @override
  String get expandedExerciseCardFavorite => '즐겨찾기';

  @override
  String get expandedExerciseCardLinkAsSuperset => '슈퍼세트로 연결';

  @override
  String get expandedExerciseCardMarkAsStaple => '주요 운동으로 표시';

  @override
  String get expandedExerciseCardNeverRecommend => '추천 안 함';

  @override
  String get expandedExerciseCardQueued => '대기 중';

  @override
  String get expandedExerciseCardRemoveAsStaple => '주요 운동 표시 해제';

  @override
  String get expandedExerciseCardRemoveFromFavorites => '즐겨찾기에서 제거';

  @override
  String get expandedExerciseCardRemoveFromQueue => '대기열에서 제거';

  @override
  String get expandedExerciseCardRemoveFromWorkout => '운동에서 제거';

  @override
  String get expandedExerciseCardRepeatNextTime => '다음번에 반복';

  @override
  String get expandedExerciseCardRestTimer => '휴식 타이머:';

  @override
  String get expandedExerciseCardStaple => '고정';

  @override
  String get expandedExerciseCardSwapExercise => '운동 교체';

  @override
  String get expandedExerciseCardTarget => '타겟';

  @override
  String get expandedExerciseCardViewHistory => '기록 보기';

  @override
  String get expandedExerciseCardWhatDoTheseMean => '이게 무슨 뜻인가요?';

  @override
  String get exportDataAlwaysIncludedForCardio => '유산소 전용 형식에는 항상 포함됩니다.';

  @override
  String get exportDataCardioSessions => '유산소 세션';

  @override
  String get exportDataCustom => '사용자 지정...';

  @override
  String get exportDataDisabledThisFormatIs => '비활성화됨 — 이 형식은 유산소 전용입니다.';

  @override
  String get exportDataExportMyData => '내 데이터 내보내기';

  @override
  String get exportDataExportedAsText => '데이터가 텍스트로 성공적으로 내보내졌습니다!';

  @override
  String get exportDataExportedSuccessfully => '데이터가 성공적으로 내보내졌습니다!';

  @override
  String get exportDataGenerateExport => '내보내기 생성';

  @override
  String get exportDataGenerating => '생성 중...';

  @override
  String get exportDataNotApplicableForCardio => '유산소 전용 형식에는 적용되지 않습니다.';

  @override
  String get exportDataPickAtLeastOne => '내보낼 데이터 세트를 하나 이상 선택하세요.';

  @override
  String get exportDataProgramTemplates => '프로그램 템플릿';

  @override
  String exportDataScreenGdprArtCompliant(Object appName) {
    return '$appName. GDPR 제20조 준수.';
  }

  @override
  String exportDataScreenNativeSchemaMaximumFidelity(Object appName) {
    return '$appName 기본 스키마. 최대 충실도.';
  }

  @override
  String get exportDataStrengthHistory => '근력 운동 기록';

  @override
  String get exportDataYourDataIsYours => '데이터는 회원님의 것입니다. 어디서든 활용하세요.';

  @override
  String get exportDialogPartCsvZip => 'CSV/ZIP';

  @override
  String get exportDialogPartDataToExport => '내보낼 데이터';

  @override
  String get exportDialogPartEnd => '종료';

  @override
  String get exportDialogPartExcel => 'Excel';

  @override
  String get exportDialogPartExport => '내보내기';

  @override
  String exportDialogPartExportDataDialogExportData(Object appName) {
    return '$appName 데이터 내보내기';
  }

  @override
  String get exportDialogPartExportFormat => '내보내기 형식';

  @override
  String get exportDialogPartExportInfo => '내보내기 정보';

  @override
  String get exportDialogPartExportedData => '내보낸 데이터';

  @override
  String get exportDialogPartFormats => '형식';

  @override
  String get exportDialogPartGotIt => '확인';

  @override
  String get exportDialogPartParquet => 'Parquet';

  @override
  String get exportDialogPartPlainText => '일반 텍스트';

  @override
  String get exportDialogPartProfileIsAlwaysIncluded => '프로필은 항상 포함됩니다.';

  @override
  String get exportDialogPartTimeRange => '기간';

  @override
  String get exportDialogPartYourDataWillBe =>
      '데이터가 CSV 파일이 포함된 ZIP 파일로 내보내집니다.';

  @override
  String get exportExportingYourData => '데이터를 내보내는 중...';

  @override
  String get exportExportingYourDataAs => '데이터를 텍스트로 내보내는 중...';

  @override
  String get exportNoDataReceivedFrom => '서버로부터 데이터를 받지 못했습니다.';

  @override
  String get exportStatsCsvZip => 'CSV / ZIP';

  @override
  String get exportStatsExportStats => '통계 내보내기';

  @override
  String get exportStatsFullDataExportWith =>
      '모든 운동, PR, 신체 측정값이 포함된 전체 데이터 내보내기';

  @override
  String get exportStatsPdfReport => 'PDF 보고서';

  @override
  String get exportStatsQuickShareableTextSummary => '통계를 빠르게 공유할 수 있는 텍스트 요약';

  @override
  String get exportStatsStyledReportWithStats => '통계 요약 및 진행 상황이 포함된 스타일 보고서';

  @override
  String get exportStatsTextSummary => '텍스트 요약';

  @override
  String get exportThisMayTakeA => '몇 초 정도 걸릴 수 있습니다.';

  @override
  String get exportUserDataNotFound =>
      '사용자 데이터를 찾을 수 없습니다. 로그아웃 후 다시 로그인해 보세요.';

  @override
  String get exportWorkoutButtonExportAsFit => 'FIT으로 내보내기';

  @override
  String get exportWorkoutButtonExportAsGpx => 'GPX로 내보내기';

  @override
  String get exportWorkoutButtonExportAsTcx => 'TCX로 내보내기';

  @override
  String get exportWorkoutButtonExportWorkout => '운동 내보내기';

  @override
  String get exportWorkoutButtonGarminWahooNative => 'Garmin / Wahoo 기본';

  @override
  String get exportWorkoutButtonMyfitnesspalSportstracks =>
      'MyFitnessPal / Sportstracks';

  @override
  String get exportWorkoutButtonStravaGarminConnectKomo =>
      'Strava / Garmin Connect / Komoot';

  @override
  String get fastingAiInsightAiInsight => 'AI 인사이트';

  @override
  String get fastingAiInsightCouldnTLoadYour =>
      '인사이트를 불러올 수 없습니다. 연결 상태를 확인하세요.';

  @override
  String get fastingAreYouSureYou => '지금 단식을 종료하시겠습니까?';

  @override
  String get fastingAvgDuration => '평균 지속 시간';

  @override
  String get fastingBenefit_appetite =>
      '시간이 지남에 따라 식욕 호르몬이 재설정되어 적게 먹는 것이 더 쉬워집니다.';

  @override
  String get fastingBenefit_autophagy =>
      '세포 자가포식이 손상된 단백질을 제거하여 노화 방지에 도움을 줍니다.';

  @override
  String get fastingBenefit_bs_control => '혈당이 더 안정적으로 유지되어 식탐과 에너지 저하를 줄여줍니다.';

  @override
  String get fastingBenefit_cellular_repair => '장기 단식 중 DNA 복구 경로가 활성화됩니다.';

  @override
  String get fastingBenefit_energy => '식후 피로감 없이 하루 종일 안정적인 에너지를 유지합니다.';

  @override
  String get fastingBenefit_gut_rest => '소화 기관이 휴식을 취하여 장내 미생물 건강을 지원합니다.';

  @override
  String get fastingBenefit_insulin_sensitivity =>
      '인슐린 민감도가 개선되어 제2형 당뇨병 위험을 줄입니다.';

  @override
  String get fastingBenefit_longevity =>
      '동물 연구에 따르면 단식은 건강 수명을 늘리고 질병 지표를 줄이는 것과 관련이 있습니다.';

  @override
  String get fastingBenefit_mental_clarity =>
      '케톤은 포도당 급상승보다 뇌에 더 안정적인 에너지를 공급합니다.';

  @override
  String get fastingBenefit_weight_loss =>
      '제지방이 아닌 저장된 지방을 타겟팅하여 지속 가능한 체중 감량을 돕습니다.';

  @override
  String get fastingBodyStatusBeyondGoal => '목표 초과';

  @override
  String get fastingBodyStatusBodyStatus => '신체 상태';

  @override
  String get fastingBodyStatusKeyMoments => '주요 순간';

  @override
  String fastingBodyStatusLiveSubtitle(Object elapsed) {
    return '실시간 대사 여정 — $elapsed 경과.';
  }

  @override
  String get fastingBodyStatusPreviewSubtitle => '단식의 대사 단계 미리보기.';

  @override
  String fastingBodyStatusScreenAtH(Object startHour) {
    return '$startHour시에';
  }

  @override
  String fastingBodyStatusScreenAtH2(Object hourOffset) {
    return '$hourOffset시간째';
  }

  @override
  String fastingBodyStatusScreenH(Object hourOffset) {
    return '$hourOffset시간 · ';
  }

  @override
  String get fastingBodyStatusStartFastHint =>
      '단식을 시작하여 각 단계에 도달하는 정확한 시간을 포함한 실시간 타임라인을 확인하세요.';

  @override
  String get fastingBodyStatusYouAreHere => '현재 위치';

  @override
  String get fastingCalendarEnergy => '에너지';

  @override
  String get fastingCalendarFasting => '단식';

  @override
  String get fastingCalendarGoals => '목표';

  @override
  String get fastingCalendarTapToMark => '탭하여 표시';

  @override
  String get fastingCalendarWeight => '체중';

  @override
  String fastingCalendarWidgetCompleted(
    Object goalsCompleted,
    Object goalsTotal,
  ) {
    return '$goalsCompleted/$goalsTotal 완료';
  }

  @override
  String fastingCalendarWidgetHFast(Object data) {
    return '$data시간 단식';
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
  String get fastingCompleteYourFirstFast => '첫 단식을 완료하고 여기서 확인하세요.';

  @override
  String get fastingContinueFasting => '단식 계속하기';

  @override
  String get fastingEditDuration => '지속 시간: ';

  @override
  String get fastingEditEditFast => '단식 편집';

  @override
  String get fastingEditEnd => '종료';

  @override
  String get fastingEditFastUpdated => '단식 정보가 업데이트되었습니다.';

  @override
  String get fastingEditSaveChanges => '변경 사항 저장';

  @override
  String get fastingEditSchedule => '일정 편집';

  @override
  String fastingEditSheetHM(Object h, Object m) {
    return '$h시간 $m분';
  }

  @override
  String get fastingEndFast => '단식을 종료할까요?';

  @override
  String get fastingEndFast2 => '단식 종료';

  @override
  String get fastingFailedToEndFast => '단식 종료에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get fastingFasting => '단식';

  @override
  String get fastingFastingSettings => '단식 설정';

  @override
  String get fastingFastingTracker => '단식 추적기';

  @override
  String get fastingGuideBeginnerTips => '초보자 팁';

  @override
  String get fastingGuideCommonProtocols => '일반적인 프로토콜';

  @override
  String get fastingGuideFaq => 'FAQ';

  @override
  String get fastingGuideFastingGuide => '단식 가이드';

  @override
  String get fastingGuideHowItWorks => '작동 원리';

  @override
  String get fastingGuideIsItSafeFor => '저에게 안전할까요?';

  @override
  String get fastingGuideSafetyBody =>
      '어지러움, 현기증, 떨림 또는 몸 상태가 좋지 않다고 느껴지면 즉시 단식을 멈추고 식사하세요. 24시간 이상의 단식은 전해질 보충에 각별히 주의해야 하며, 72시간 이상의 단식은 반드시 의료진의 감독하에 진행해야 합니다. 단식은 의료 서비스를 대체할 수 없으며, 이 가이드는 교육용일 뿐 의학적 조언이 아닙니다.';

  @override
  String get fastingGuideStaySafe => '안전 수칙';

  @override
  String get fastingGuideSubtitle =>
      '자신 있게 단식하는 데 필요한 모든 것 — 단식의 정의, 원리, 신체 변화에 대해 알아보세요.';

  @override
  String get fastingGuideSwipeTimeline =>
      '마지막 식사부터 30일 단식까지, 시간별 변화를 스와이프하여 확인하세요.';

  @override
  String get fastingGuideTheFastingTimeline => '단식 타임라인';

  @override
  String get fastingGuideWhatIsFasting => '단식이란 무엇인가요?';

  @override
  String get fastingHistoryListCompleted => '완료됨';

  @override
  String get fastingHistoryListLoadMore => '더 보기';

  @override
  String fastingHistoryListValue(Object completionPercent) {
    return '$completionPercent%';
  }

  @override
  String get fastingHydrationRow250Ml => '+250 ml';

  @override
  String get fastingHydrationRow500Ml => '+500 ml';

  @override
  String get fastingHydrationRowBottle => '병';

  @override
  String get fastingHydrationRowGlass => '컵';

  @override
  String get fastingHydrationRowHydration => '수분 섭취';

  @override
  String fastingHydrationRowMl(Object goalMl) {
    return ' / $goalMl ml';
  }

  @override
  String get fastingHydrationRowSyncedVisibleOnHome =>
      '동기화됨 — 홈 및 영양 탭에서도 확인 가능합니다.';

  @override
  String get fastingHydrationRowWaterKeepsYouEnergized =>
      '물은 단식 중 에너지를 유지하는 데 도움을 줍니다';

  @override
  String get fastingImpactActivityCalendar => '활동 캘린더';

  @override
  String get fastingImpactAiInsights => 'AI 인사이트';

  @override
  String fastingImpactCardCorrelation(Object displayName) {
    return '상관관계: $displayName';
  }

  @override
  String get fastingImpactCompleteMoreFastsTo =>
      '정확한 영향 분석을 위해 단식을 더 완료하세요. 최소 7일 이상의 단식을 권장합니다.';

  @override
  String get fastingImpactCompleteSomeFastsAnd =>
      '단식을 완료하고 체중을 기록하여 단식이 목표에 미치는 영향을 확인하세요.';

  @override
  String get fastingImpactFailedToLoadData => '데이터를 불러오지 못했습니다';

  @override
  String get fastingImpactFastingDaysMarkedWith => '단식일은 보라색 점으로 표시됩니다';

  @override
  String get fastingImpactFastingImpact => '단식 영향';

  @override
  String get fastingImpactFastingVsNonFasting => '단식일 vs 비단식일';

  @override
  String get fastingImpactGoalAchievement => '목표 달성';

  @override
  String get fastingImpactLimitedDataAvailable => '데이터가 부족합니다';

  @override
  String get fastingImpactNoImpactDataYet => '아직 영향 데이터가 없습니다';

  @override
  String get fastingImpactOverallImpactScore => '전체 영향 점수';

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
  String get fastingImpactStartAFast => '단식 시작';

  @override
  String get fastingImpactWeightImpact => '체중 영향';

  @override
  String get fastingImpactWeightTrend => '체중 추이';

  @override
  String get fastingImpactWorkoutPerformance => '운동 수행 능력';

  @override
  String get fastingLongestFast => '최장 단식';

  @override
  String get fastingMoodCheckinEndFast => '단식 종료';

  @override
  String get fastingMoodCheckinEnergy => '에너지';

  @override
  String get fastingMoodCheckinHowDoYouFeel => '기분이 어떠신가요?';

  @override
  String get fastingMoodCheckinLogYourMoodAnd => '단식 후 기분과 에너지를 기록하세요 (선택 사항).';

  @override
  String fastingMoodCheckinValue(Object value) {
    return '$value/5';
  }

  @override
  String get fastingNoFastingHistoryYet => '아직 단식 기록이 없습니다';

  @override
  String get fastingPanelFasting => '단식';

  @override
  String get fastingPanelIntermittentFasting => '간헐적 단식';

  @override
  String fastingPanelLeft(Object remainingTimeString) {
    return '$remainingTimeString 남음';
  }

  @override
  String get fastingPlanCardsFlexible => '유연한';

  @override
  String get fastingPlanCardsPopular => '인기';

  @override
  String get fastingProtocol_16_8_desc => '아침을 거르고 정오부터 오후 8시 사이에 식사하세요.';

  @override
  String get fastingProtocol_16_8_name => '16:8';

  @override
  String get fastingProtocol_18_6_desc => '6시간의 더 짧은 식사 시간대입니다.';

  @override
  String get fastingProtocol_18_6_name => '18:6';

  @override
  String get fastingProtocol_20_4_desc => '워리어 다이어트 — 하루 한 끼 위주의 식사입니다.';

  @override
  String get fastingProtocol_20_4_name => '20:4';

  @override
  String get fastingProtocol_36h_desc => '몽크 단식 — 자가포식 시간을 늘린 단식입니다.';

  @override
  String get fastingProtocol_36h_name => '36시간';

  @override
  String get fastingProtocol_48h_desc => '장기 단식 — 의료진의 감독을 권장합니다.';

  @override
  String get fastingProtocol_48h_name => '48시간';

  @override
  String get fastingProtocol_5_2_desc => '5일은 일반 식사, 2일은 500-600 칼로리만 섭취합니다.';

  @override
  String get fastingProtocol_5_2_name => '5:2';

  @override
  String get fastingProtocol_72h_desc => '줄기세포 재생 단식 — 의료진의 감독이 필수입니다.';

  @override
  String get fastingProtocol_72h_name => '72시간';

  @override
  String get fastingProtocol_adf_desc =>
      '격일 단식 — 일반 식사일과 초저칼로리 식사일을 번갈아 진행합니다.';

  @override
  String get fastingProtocol_adf_name => 'ADF';

  @override
  String get fastingProtocol_custom_desc => '나만의 식사 및 단식 시간을 설정하세요.';

  @override
  String get fastingProtocol_custom_name => '사용자 지정';

  @override
  String get fastingProtocol_omad_desc => '1일 1식 — 모든 영양소를 한 번에 섭취합니다.';

  @override
  String get fastingProtocol_omad_name => 'OMAD';

  @override
  String get fastingSavedRowFasting => '단식';

  @override
  String get fastingSavedRowSaved => '저장됨';

  @override
  String get fastingScheduleEditorPickAProtocolFor => '요일별 프로토콜 선택';

  @override
  String get fastingScheduleEditorRestEatingDay => '휴식 / 식사일';

  @override
  String get fastingScheduleEditorSaveSchedule => '일정 저장';

  @override
  String fastingScheduleEditorSheetFailedToSaveSchedule(Object e) {
    return '일정 저장 실패: $e';
  }

  @override
  String fastingScheduleEditorSheetValue(
    Object difficulty,
    Object displayName,
  ) {
    return '$displayName  ·  $difficulty';
  }

  @override
  String get fastingScheduleEditorWeeklyFastingScheduleSaved =>
      '주간 단식 일정이 저장되었습니다';

  @override
  String get fastingScheduleEditorWeeklySchedule => '주간 일정';

  @override
  String get fastingScoreCardBreakdown => '상세 분석';

  @override
  String get fastingScoreCardCompletionRate => '완료율';

  @override
  String get fastingScoreCardFastingScore => '단식 점수';

  @override
  String get fastingScoreCardProtocolLevel => '프로토콜 레벨';

  @override
  String get fastingScoreCardScore => '점수';

  @override
  String get fastingScoreCardStreakBonus => '연속 기록 보너스';

  @override
  String fastingScoreCardValue2(Object value) {
    return '$value%';
  }

  @override
  String fastingScoreCardValue3(Object weightedValue) {
    return '+$weightedValue';
  }

  @override
  String get fastingScoreCardVsLastWeek => '지난주 대비';

  @override
  String get fastingScoreCardWeeklyGoal => '주간 목표';

  @override
  String fastingScreenFailedToStartFast(Object e) {
    return '단식 시작 실패: $e';
  }

  @override
  String get fastingScreenRedesignedAvgDuration => '평균 지속 시간';

  @override
  String get fastingScreenRedesignedBackToToday => '오늘로 돌아가기';

  @override
  String get fastingScreenRedesignedCompleteAFastTo => '단식을 완료하고 여기에 표시하세요';

  @override
  String get fastingScreenRedesignedDayStreak => '연속 단식 일수';

  @override
  String get fastingScreenRedesignedEndFast => '단식 종료';

  @override
  String fastingScreenRedesignedFailedToEndFast(Object e) {
    return '단식 종료 실패: $e';
  }

  @override
  String fastingScreenRedesignedFailedToStartFast(Object e) {
    return '단식 시작 실패: $e';
  }

  @override
  String get fastingScreenRedesignedFastPaused => '단식 일시 중지됨';

  @override
  String get fastingScreenRedesignedFastResumedYourTimer =>
      '단식이 재개되었습니다 — 타이머가 다시 작동합니다.';

  @override
  String get fastingScreenRedesignedFasting => '단식';

  @override
  String get fastingScreenRedesignedFastingTracker => '단식 추적기';

  @override
  String get fastingScreenRedesignedInProgress => '진행 중';

  @override
  String get fastingScreenRedesignedLongestFast => '최장 단식';

  @override
  String get fastingScreenRedesignedNoFastYet => '아직 단식 기록 없음';

  @override
  String get fastingScreenRedesignedNoFastingHistoryYet => '아직 단식 기록이 없습니다';

  @override
  String get fastingScreenRedesignedPauseFast => '단식 일시 중지';

  @override
  String get fastingScreenRedesignedPaused => '일시 중지됨';

  @override
  String fastingScreenRedesignedPlan(Object displayName) {
    return '$displayName 플랜';
  }

  @override
  String get fastingScreenRedesignedRestDay => '휴식일';

  @override
  String get fastingScreenRedesignedResumeFast => '단식 재개';

  @override
  String get fastingScreenRedesignedSignUpToUnlock => '가입하여 잠금 해제';

  @override
  String get fastingScreenRedesignedStartFast => '단식 시작';

  @override
  String fastingScreenRedesignedStartedOngoing(Object timeFormat) {
    return '$timeFormat 시작 · 진행 중';
  }

  @override
  String get fastingScreenRedesignedTodaySPlan => '오늘의 계획: ';

  @override
  String get fastingScreenRedesignedTotalFasts => '총 단식 횟수';

  @override
  String get fastingScreenRedesignedViewTrends => '추이 보기';

  @override
  String get fastingScreenRedesignedYouDidNotLog => '이 날은 단식을 기록하지 않았습니다.';

  @override
  String fastingScreenYouVeBeenFasting(Object elapsedTimeFormatted) {
    return '$elapsedTimeFormatted 동안 단식 중입니다';
  }

  @override
  String get fastingSettingsCustom => '사용자 지정';

  @override
  String get fastingSettingsCustomWeeklySchedule => '사용자 지정 주간 일정';

  @override
  String get fastingSettingsEatingWindowEnd => '식사 종료 시간';

  @override
  String get fastingSettingsFastStartReminder => '단식 시작 알림';

  @override
  String get fastingSettingsFastingHours => '단식 시간:';

  @override
  String get fastingSettingsFastingSettings => '단식 설정';

  @override
  String get fastingSettingsFastingSettingsSaved => '단식 설정이 저장되었습니다';

  @override
  String get fastingSettingsGoalReached => '목표 달성';

  @override
  String get fastingSettingsNotifyWhenEnteringNew => '새로운 단식 구간 진입 시 알림';

  @override
  String get fastingSettingsNotifyWhenYouReach => '단식 목표 달성 시 알림';

  @override
  String get fastingSettingsRemindBeforeEatingWindow => '식사 시간 종료 전 알림';

  @override
  String get fastingSettingsRemindWhenItS => '단식 시작 시간 알림';

  @override
  String get fastingSettingsSaveSettings => '설정 저장';

  @override
  String fastingSettingsSheetFailedToSave(Object e) {
    return '저장 실패: $e';
  }

  @override
  String fastingSettingsSheetH(Object _customHours) {
    return '$_customHours시간';
  }

  @override
  String fastingSettingsSheetHFasting(Object _customHours) {
    return '$_customHours시간 단식';
  }

  @override
  String get fastingSettingsStartEatingAt => '식사 시작 시간';

  @override
  String get fastingSettingsStartFastingAt => '단식 시작 시간';

  @override
  String get fastingSettingsZoneTransitions => '구간 전환';

  @override
  String get fastingSignUpToUnlock => '가입하고 잠금 해제하기';

  @override
  String get fastingStageCardCurrentStage => '현재 단계';

  @override
  String get fastingStageCardFinalMetabolicStageReached => '최종 대사 단계 도달';

  @override
  String fastingStageCardNext(Object name) {
    return '다음: $name';
  }

  @override
  String get fastingStageModel24Hours => '24시간';

  @override
  String get fastingStageTimerElapsed => '경과';

  @override
  String get fastingStageTimerReadyToFast => '단식 준비 완료';

  @override
  String get fastingStage_autophagy_desc =>
      '세포가 손상된 단백질과 소기관을 분해하고 재활용하기 시작하는 깊은 세포 청소 과정입니다.';

  @override
  String get fastingStage_autophagy_name => '자가포식';

  @override
  String get fastingStage_fat_burning_desc =>
      '글리코겐이 낮아지면 지방 세포가 연료로 사용하기 위해 지방산을 혈류로 방출합니다.';

  @override
  String get fastingStage_fat_burning_name => '지방 연소';

  @override
  String get fastingStage_glycogen_depletion_desc =>
      '신체는 저장된 포도당을 먼저 사용합니다. 12~14시간 후 간 글리코겐이 낮아지며 대사 전환이 시작됩니다.';

  @override
  String get fastingStage_glycogen_depletion_name => '글리코겐 고갈';

  @override
  String get fastingStage_growth_hormone_desc =>
      'HGH 수치가 급격히 상승하여 제지방량을 보호하고 지방 대사를 가속화합니다.';

  @override
  String get fastingStage_growth_hormone_name => '성장 호르몬 급증';

  @override
  String get fastingStage_inflammation_drop_desc =>
      '장기가 휴식을 취하고 면역 세포가 재생되면서 염증 수치가 감소합니다.';

  @override
  String get fastingStage_inflammation_drop_name => '염증 감소';

  @override
  String get fastingStage_insulin_low_desc =>
      '인슐린이 기준치 근처로 유지되어 지방 저장고를 열고 인슐린 민감도를 개선합니다.';

  @override
  String get fastingStage_insulin_low_name => '인슐린 저하';

  @override
  String get fastingStage_ketosis_desc =>
      '간은 지방산을 뇌를 위한 깨끗하고 효율적인 연료인 케톤체로 전환합니다.';

  @override
  String get fastingStage_ketosis_name => '케토시스';

  @override
  String get fastingStartFast => '단식 시작';

  @override
  String get fastingStartYourFirstFast => '첫 단식을 시작하여 통계를 쌓아보세요';

  @override
  String get fastingStatsCardAvg => '평균';

  @override
  String get fastingStatsCardCurrentStreak => '현재 연속 기록';

  @override
  String get fastingStatsCardFastingDays => '단식 일수';

  @override
  String get fastingStatsCardFastingHelps => '단식의 효과';

  @override
  String get fastingStatsCardFastingScore => '단식 점수';

  @override
  String fastingStatsCardFastsProgress(Object fasts, Object goal) {
    return '$fasts / $goal회 단식';
  }

  @override
  String get fastingStatsCardHours => '시간';

  @override
  String fastingStatsCardKg(Object value) {
    return '$value kg';
  }

  @override
  String get fastingStatsCardLongest => '최장 기록';

  @override
  String get fastingStatsCardMixedResults => '복합적인 결과';

  @override
  String get fastingStatsCardNeedMoreData => '데이터가 더 필요합니다';

  @override
  String get fastingStatsCardNeutral => '중립';

  @override
  String get fastingStatsCardNonFasting => '비단식';

  @override
  String fastingStatsCardStreakDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
    );
    return '$_temp0';
  }

  @override
  String get fastingStatsCardThisWeek => '이번 주';

  @override
  String get fastingStatsCardTotal => '총계';

  @override
  String get fastingStatsCardWeightFasting => '체중 및 단식';

  @override
  String get fastingStreak => '연속 기록';

  @override
  String fastingTabFailedToEndFast(Object e) {
    return '단식 종료 실패: $e';
  }

  @override
  String fastingTabFailedToStartFast(Object e) {
    return '단식 시작 실패: $e';
  }

  @override
  String get fastingTileFast => '단식';

  @override
  String get fastingTileFasting => '단식 중';

  @override
  String get fastingTileNotFasting => '단식 아님';

  @override
  String get fastingTimelinePagerAdvancedTerritory => '고급 영역';

  @override
  String fastingTimelinePagerExtendedFast(Object label) {
    return '장기 단식 · $label';
  }

  @override
  String fastingTimelinePagerH(Object hourOffset, Object text) {
    return '$hourOffset시간 — $text';
  }

  @override
  String get fastingTimer => '타이머';

  @override
  String get fastingTimerEndFast => '단식 종료';

  @override
  String get fastingTip_bcaa_avoid =>
      'BCAA 및 칼로리나 아미노산이 포함된 대부분의 보충제는 단식을 깹니다.';

  @override
  String get fastingTip_break_with_protein =>
      '근육을 보존하고 포만감을 오래 유지하기 위해 단백질이 풍부한 식사로 단식을 깨세요.';

  @override
  String get fastingTip_coffee_ok => '블랙 커피는 단식을 깨지 않으며 오히려 허기를 줄여줄 수 있습니다.';

  @override
  String get fastingTip_exercise_fasted_ok_intermediate =>
      '단식에 적응되면 가벼운 유산소 운동은 괜찮습니다. 몸의 소리에 귀를 기울이세요.';

  @override
  String get fastingTip_exercise_high_intensity_eat_first =>
      '고강도 웨이트나 인터벌 운동 전에는 식사를 해야 수행 능력을 보호할 수 있습니다.';

  @override
  String get fastingTip_ramp_up_gradually =>
      '12시간부터 시작해 매주 30분씩 늘려가세요. 첫날부터 바로 OMAD를 하지 마세요.';

  @override
  String get fastingTip_refeed_carbs_carefully =>
      '36시간 이상의 단식 후에는 소화 불편을 피하기 위해 탄수화물을 천천히 다시 섭취하세요.';

  @override
  String get fastingTip_sleep_helps_extended =>
      '수면 시간과 단식 시간을 겹치면 더 긴 단식도 훨씬 쉬워집니다.';

  @override
  String get fastingTip_stay_hydrated => '단식 중에는 물, 블랙 커피, 설탕 없는 차를 마셔도 좋습니다.';

  @override
  String get fastingTip_track_hunger_separate_from_appetite =>
      '허기와 식욕은 다릅니다. 허기는 파도처럼 지나가지만 식욕은 습관입니다.';

  @override
  String get fastingTotalFasts => '총 단식 횟수';

  @override
  String get fastingTrackYourIntermittentFastin =>
      '스마트 구간 알림, 진행 상황 분석 및 상세 기록으로 간헐적 단식을 관리하세요.';

  @override
  String fastingTrainingWarningH(Object hoursFasted) {
    return '$hoursFasted시간';
  }

  @override
  String fastingTrainingWarningHFasted(Object hoursFasted) {
    return '$hoursFasted시간 단식 중';
  }

  @override
  String get fastingTrainingWarningSuggestions => '제안:';

  @override
  String get fastingTypesInAppProtocols => '앱 내 프로토콜';

  @override
  String get fastingTypesTypesOfFasting => '단식 유형';

  @override
  String get fastingZoneTimelineFastingZones => '단식 구간';

  @override
  String fastingZoneTimelineH(Object startHour) {
    return '$startHour시간';
  }

  @override
  String get fatigueAlertAcceptSuggestion => '제안 수락';

  @override
  String get fatigueAlertContinueAsPlanned => '계획대로 진행';

  @override
  String get fatigueAlertModalAcceptSuggestion => '제안 수락';

  @override
  String fatigueAlertModalAlert(Object severityLabel) {
    return '$severityLabel 알림';
  }

  @override
  String get fatigueAlertModalBodyweightExerciseDropThe =>
      '맨몸 운동 — 무게 대신 반복 횟수 목표를 낮추세요.';

  @override
  String get fatigueAlertModalContinueAsPlanned => '계획대로 진행';

  @override
  String get fatigueAlertModalDetectedIssues => '감지된 문제';

  @override
  String get fatigueAlertModalFatigueDetected => '피로 감지됨';

  @override
  String fatigueAlertModalHeavier(Object truePercent) {
    return '$truePercent% 무겁게';
  }

  @override
  String fatigueAlertModalLighter(Object truePercent) {
    return '$truePercent% 가볍게';
  }

  @override
  String fatigueAlertModalReps(Object newReps) {
    return '$newReps회';
  }

  @override
  String get fatigueAlertModalStopExercise => '운동 중단';

  @override
  String get fatigueAlertModalSuggestedAdjustment => '제안된 조정';

  @override
  String get fatigueAlertModalSuggestedRepTarget => '제안된 반복 횟수 목표';

  @override
  String get fatigueAlertStopExercise => '운동 중단';

  @override
  String get favoriteExercisesFavoriteExercises => '즐겨찾는 운동';

  @override
  String get favoriteExercisesRemove => '제거';

  @override
  String get favoriteExercisesRemoveFavorite => '즐겨찾기에서 제거할까요?';

  @override
  String favoriteExercisesScreenAddedToFavorites(Object exerciseName) {
    return '\"$exerciseName\"을(를) 즐겨찾기에 추가했습니다';
  }

  @override
  String favoriteExercisesScreenAddedToFavorites2(Object name) {
    return '\"$name\"을(를) 즐겨찾기에 추가했습니다';
  }

  @override
  String favoriteExercisesScreenIsAlreadyAFavorite(Object name) {
    return '\"$name\"은(는) 이미 즐겨찾기에 있습니다';
  }

  @override
  String favoriteExercisesScreenRemoveFromYourFavorites(Object exerciseName) {
    return '\"$exerciseName\"을(를) 즐겨찾기에서 삭제할까요? AI가 더 이상 이 운동을 우선순위로 두지 않습니다.';
  }

  @override
  String get favoriteExercisesTheAiWillPrioritize =>
      'AI가 운동을 생성할 때 이 운동들을 우선적으로 고려합니다.';

  @override
  String get favoriteWorkoutsFavoriteWorkouts => '즐겨찾는 운동 루틴';

  @override
  String get favoriteWorkoutsNoFavoriteWorkoutsYet => '아직 즐겨찾는 운동 루틴이 없습니다';

  @override
  String favoriteWorkoutsSavedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '저장된 운동 $count개',
    );
    return '$_temp0';
  }

  @override
  String get favoriteWorkoutsTapTheHeartOn => '운동 루틴의 하트 아이콘을 눌러 여기에 저장하세요';

  @override
  String get favoriteWorkoutsWorkoutFallback => '운동';

  @override
  String get favoritesCardFavoriteMuscleGroup => '즐겨찾는 근육 그룹';

  @override
  String get favoritesCardYourGoTo => '자주 하는 운동';

  @override
  String get favoritesCardYourMostPerformedExercise => '가장 많이 수행한 운동';

  @override
  String get favoritesCheckYourConnectionAnd => '연결 상태를 확인하고 다시 시도하세요.';

  @override
  String get favoritesFavorites => '즐겨찾기';

  @override
  String get favoritesNoFavoritesYet => '아직 즐겨찾기가 없습니다';

  @override
  String get favoritesTapU2665OnAny =>
      '탐색 탭이나 라이브러리에서 레시피의 ♥ 아이콘을 눌러 여기에 저장하세요.';

  @override
  String get favoritesTryAgain => '다시 시도';

  @override
  String get featureVotingInProgress => '진행 중';

  @override
  String get featureVotingNoFeaturesYet => '아직 기능이 없습니다';

  @override
  String get featureVotingPlanned => '계획됨';

  @override
  String get featureVotingReleased => '출시됨';

  @override
  String get featureVotingVoting => '투표';

  @override
  String get feedCompleteWorkoutsToSee =>
      '운동을 완료하고 여기에 공유해보세요! 친구를 팔로우하여 친구의 운동 기록도 확인하세요.';

  @override
  String get feedCouldNotLoadYour => '활동 피드를 불러올 수 없습니다. 나중에 다시 시도해주세요.';

  @override
  String get feedCreateYourFirstPost => '첫 게시물을 작성해보세요!';

  @override
  String get feedFailedToLoadFeed => '피드를 불러오지 못했습니다';

  @override
  String get feedNoActivityYet => '아직 활동이 없습니다';

  @override
  String get feedNoPostsYet => '아직 게시물이 없습니다';

  @override
  String get feedNotLoggedIn => '로그인되지 않음';

  @override
  String get feedPleaseLogInTo => '활동 피드를 보려면 로그인하세요';

  @override
  String feedTabErrorLoadingFeed(Object error) {
    return '피드 불러오기 오류: $error';
  }

  @override
  String get feelResultsCompleteWorkoutsWithMood =>
      '운동 완료 후 기분 체크인을 통해 운동이 기분에 어떤 영향을 주는지 확인해보세요.';

  @override
  String get feelResultsFeelResults => '운동 효과 확인';

  @override
  String get feelResultsFeelingStronger => '더 강해진 느낌';

  @override
  String get feelResultsMoodBeforeVsAfter => '운동 전후 기분 변화';

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
    return '$week주차';
  }

  @override
  String feelResultsScreenYouFeltStrongerAfter(
    Object feelingStrongerCount,
    Object totalWorkouts,
  ) {
    return '총 $totalWorkouts번의 운동 중 $feelingStrongerCount번 더 강해졌다고 느꼈습니다!';
  }

  @override
  String get feelResultsStartTrackingYourProgress => '진행 상황을 기록해보세요!';

  @override
  String get feelResultsU1f4aa => '💪';

  @override
  String get feelResultsWeeklyTrends => '주간 트렌드';

  @override
  String get feelResultsYourTrainingIsWorking => '운동 효과가 나타나고 있어요!';

  @override
  String get feltPicker => '😮‍💨';

  @override
  String get feltPickerGood => '좋음';

  @override
  String get feltPickerHard => '힘듦';

  @override
  String get feltPickerVHard => '매우 힘듦';

  @override
  String get filterNoMatchingOptions => '일치하는 옵션이 없습니다';

  @override
  String filterSectionSearch(Object title) {
    return '$title 검색...';
  }

  @override
  String filterSectionShowMore(Object initialShowCount) {
    return '$initialShowCount개 더 보기';
  }

  @override
  String get firstActionPromptPickOneTakesUnder => '하나를 선택하세요 — 1분도 걸리지 않습니다.';

  @override
  String get firstActionPromptPullInYourActivity => '활동, 수면, 체중 기록을 불러오세요.';

  @override
  String get firstActionPromptQuickStart => '빠른 시작';

  @override
  String get firstActionPromptTheyHaveAMessage => '도착한 메시지가 있습니다.';

  @override
  String get firstWorkoutForecastCaloriesBurned => '소모 칼로리';

  @override
  String get firstWorkoutForecastDay1Complete => '1일 차 완료';

  @override
  String get firstWorkoutForecastIn30DaysAt => '이 속도로 30일 후';

  @override
  String get firstWorkoutForecastLetSGo => '시작하기';

  @override
  String get firstWorkoutForecastProjectedStrengthGainOn => '주요 리프팅 예상 근력 향상';

  @override
  String firstWorkoutForecastSheetEstimateBasedOnSessions(
    Object effectiveSessions,
  ) {
    return '주 $effectiveSessions회 세션 기준 예상치';
  }

  @override
  String firstWorkoutForecastSheetThatS(Object volumeComparison) {
    return '$volumeComparison에 해당합니다';
  }

  @override
  String firstWorkoutForecastSheetThatS2(Object caloriesComparison) {
    return '$caloriesComparison에 해당합니다';
  }

  @override
  String firstWorkoutForecastSheetYourFirstWorkout(Object appName) {
    return '첫 번째 $appName 운동';
  }

  @override
  String get firstWorkoutForecastShowMeDay7 => '7일 차 보기';

  @override
  String get firstWorkoutForecastTotalTimeTrained => '총 운동 시간';

  @override
  String get firstWorkoutForecastTotalVolumeLifted => '총 리프팅 볼륨';

  @override
  String get fitnessAssessmentBodyweightSquats => '맨몸 스쿼트';

  @override
  String get fitnessAssessmentCardioCapacity => '심폐 지구력';

  @override
  String get fitnessAssessmentHelpUsPersonalizeYour => '운동 맞춤 설정을 도와주세요 (~2분)';

  @override
  String get fitnessAssessmentHowLongCanYou => '플랭크를 얼마나 오래 유지할 수 있나요?';

  @override
  String get fitnessAssessmentHowLongCanYou2 => '지속적인 유산소 운동을 얼마나 오래 할 수 있나요?';

  @override
  String get fitnessAssessmentHowLongHaveYou => '웨이트 트레이닝을 얼마나 오래 하셨나요?';

  @override
  String get fitnessAssessmentHowManyCanYou => '연속으로 몇 개나 할 수 있나요?';

  @override
  String get fitnessAssessmentHowManyConsecutivePush =>
      '정확한 자세로 푸시업을 몇 개나 연속으로 할 수 있나요?';

  @override
  String get fitnessAssessmentHowManyPullUps => '풀업을 몇 개나 할 수 있나요?';

  @override
  String get fitnessAssessmentNoWrongAnswersJust => '정답은 없습니다 — 솔직하게 답변해주세요!';

  @override
  String get fitnessAssessmentPlankHold => '플랭크 유지';

  @override
  String get fitnessAssessmentPullUps => '풀업';

  @override
  String get fitnessAssessmentPushUps => '푸시업';

  @override
  String get fitnessAssessmentQuickFitnessCheck => '간편 체력 측정';

  @override
  String get fitnessAssessmentTrainingExperience => '운동 경력';

  @override
  String get fitnessAssessmentWhatGetsPersonalized => '맞춤 설정 항목';

  @override
  String get fitnessAssessmentWhyThisMatters => '이게 중요한 이유';

  @override
  String get fitnessAssessmentYourAnswersHelpThe =>
      '답변해주신 내용은 AI가 사용자의 정확한 체력 수준에 맞춰 운동을 조정하는 데 사용됩니다 — 추측할 필요가 없습니다.';

  @override
  String get fitnessCrateCollect => '수집';

  @override
  String fitnessCrateDialogCrate(Object displayName) {
    return '$displayName 크레이트';
  }

  @override
  String get fitnessCrateOpenCrate => '상자 열기';

  @override
  String get fitnessCrateRewards => '보상!';

  @override
  String get fitnessScoreCardConsistency => '일관성';

  @override
  String get fitnessScoreCardFitnessScore => '피트니스 점수';

  @override
  String get fitnessScoreCardLoadingScores => '점수 불러오는 중...';

  @override
  String get fitnessScoreCardOverall => '종합';

  @override
  String get fitnessScoreCardReadiness => '준비도';

  @override
  String get fitnessScoreCardStrength => '근력';

  @override
  String fitnessScoreCardValue(Object consistencyScore) {
    return '$consistencyScore%';
  }

  @override
  String fitnessScoreCardValue2(Object label) {
    return '$label: ';
  }

  @override
  String get flexibilityAssessmentAllTests => '모든 테스트';

  @override
  String get flexibilityAssessmentCompleteSomeFlexibilityAsse =>
      '유연성 평가를 완료하고 맞춤형 스트레칭 추천을 받아보세요';

  @override
  String get flexibilityAssessmentCompleteTheseTestsTo =>
      '테스트를 완료하고 전체 유연성 프로필을 확인하세요';

  @override
  String get flexibilityAssessmentFailedToLoadData => '데이터를 불러오지 못했습니다';

  @override
  String get flexibilityAssessmentFlexibilityAssessment => '유연성 평가';

  @override
  String get flexibilityAssessmentFocusOnTheseAreas =>
      '전반적인 유연성 향상을 위해 이 부위에 집중하세요';

  @override
  String get flexibilityAssessmentMyPlans => '내 플랜';

  @override
  String get flexibilityAssessmentNoFlexibilityTestsAvailable =>
      '사용 가능한 유연성 테스트가 없습니다';

  @override
  String get flexibilityAssessmentNoStretchPlansYet => '아직 스트레칭 플랜이 없습니다';

  @override
  String get flexibilityAssessmentNotYetAssessed => '평가 전';

  @override
  String get flexibilityAssessmentOverview => '개요';

  @override
  String get flexibilityAssessmentPriorityImprovements => '우선 개선 사항';

  @override
  String get flexibilityAssessmentRecentAssessments => '최근 평가';

  @override
  String get flexibilityAssessmentRecommendedStretches => '추천 스트레칭';

  @override
  String flexibilityAssessmentScreenCurrentRating(Object rating) {
    return '현재 등급: $rating';
  }

  @override
  String flexibilityAssessmentScreenViewAllTests(Object length) {
    return '테스트 $length개 모두 보기';
  }

  @override
  String get flexibilityAssessmentTakeAnAssessment => '평가 시작하기';

  @override
  String get flexibilityHistoryAll => '전체';

  @override
  String get flexibilityHistoryAssessmentHistory => '평가 기록';

  @override
  String get flexibilityHistoryCompleteSomeFlexibilityTest =>
      '유연성 테스트를 완료하고 여기에 기록을 확인하세요';

  @override
  String get flexibilityHistoryDeleteAssessment => '평가 삭제';

  @override
  String get flexibilityHistoryDeleteAssessment2 => '평가를 삭제할까요?';

  @override
  String get flexibilityHistoryNoAssessmentsYet => '아직 평가 기록이 없습니다';

  @override
  String get flexibilityHistoryNotes => '메모';

  @override
  String get flexibilityHistoryThisActionCannotBe => '이 작업은 되돌릴 수 없습니다.';

  @override
  String flexibilityProgressChartAssessments(Object totalAssessments) {
    return '평가 $totalAssessments회';
  }

  @override
  String get flexibilityProgressChartChange => '변화';

  @override
  String get flexibilityProgressChartFirst => '처음';

  @override
  String get flexibilityProgressChartLatest => '최근';

  @override
  String get flexibilityProgressChartNoDataAvailable => '데이터 없음';

  @override
  String get flexibilityScoreCardByArea => '부위별';

  @override
  String get flexibilityScoreCardFocusAreas => '집중 부위';

  @override
  String get flexibilityScoreCardOverallFlexibility => '종합 유연성';

  @override
  String flexibilityScoreCardTestsCompleted(Object testsCompleted) {
    return '테스트 $testsCompleted개 완료';
  }

  @override
  String flexibilityScoreCardTotalAssessments(Object totalAssessments) {
    return '총 평가 $totalAssessments개';
  }

  @override
  String get flexibilityTestCardNotYetAssessed => '평가 전';

  @override
  String get flexibilityTestCardRecordAssessment => '평가 기록하기';

  @override
  String get flexibilityTestCardUpdateAssessment => '평가 업데이트';

  @override
  String get flexibilityTestDetailAboutThisTest => '테스트 소개';

  @override
  String get flexibilityTestDetailCommonMistakesToAvoid => '피해야 할 흔한 실수';

  @override
  String get flexibilityTestDetailEquipmentNeeded => '필요한 장비';

  @override
  String get flexibilityTestDetailFlexibilityTrends => '유연성 추이';

  @override
  String get flexibilityTestDetailInstructions => '지침';

  @override
  String get flexibilityTestDetailNotYetAssessed => '아직 평가되지 않음';

  @override
  String get flexibilityTestDetailRecentAssessments => '최근 평가';

  @override
  String get flexibilityTestDetailStartAssessment => '평가 시작';

  @override
  String get flexibilityTestDetailTakeTest => '테스트 수행';

  @override
  String get flexibilityTestDetailTakeThisTestTo =>
      '이 테스트를 수행하여 유연성 등급을 확인하고 맞춤형 추천을 받으세요';

  @override
  String get flexibilityTestDetailTargetMuscles => '타겟 근육';

  @override
  String get flexibilityTestDetailTips => '팁';

  @override
  String get flexibilityTestDetailU2022 => '• ';

  @override
  String get flexibilityTestDetailUpdate => '업데이트';

  @override
  String get floatingChatBubbleAskMeAnythingAbout => '피트니스에 대해 무엇이든 물어보세요';

  @override
  String get floatingChatBubbleAskYourAiCoach => 'AI 코치에게 물어보기...';

  @override
  String get floatingChatBubbleChangeCoach => '코치 변경';

  @override
  String get floatingChatBubbleErrorLoadingMessages => '메시지를 불러오는 중 오류가 발생했습니다';

  @override
  String get floatingChatBubbleHowCanIHelp => '오늘 무엇을 도와드릴까요?';

  @override
  String get floatingChatBubbleOnline => '온라인';

  @override
  String get floatingChatBubbleTyping => '입력 중...';

  @override
  String get floatingChatOverlayAskMeAnythingAbout => '피트니스에 대해 무엇이든 물어보세요';

  @override
  String get floatingChatOverlayAskYourAiCoach => 'AI 코치에게 물어보기...';

  @override
  String get floatingChatOverlayErrorLoadingMessages =>
      '메시지를 불러오는 중 오류가 발생했습니다';

  @override
  String floatingChatOverlayGoTo(Object workoutName) {
    return '$workoutName으로 이동';
  }

  @override
  String get floatingChatOverlayHowCanIHelp => '오늘 무엇을 도와드릴까요?';

  @override
  String get floatingChatOverlayMediaAttachmentsAvailableIn =>
      '미디어 첨부 파일은 전체 채팅에서 확인할 수 있습니다';

  @override
  String get floatingChatOverlayOnline => '온라인';

  @override
  String get floatingChatOverlayTypeYourNextMessage => '메시지를 입력하세요...';

  @override
  String get floatingChatOverlayTyping => '입력 중...';

  @override
  String focalStepperInternalsEditValueCurrently(Object _display, Object unit) {
    return '$unit 값 편집, 현재 $_display';
  }

  @override
  String get focalStepperValue => '값';

  @override
  String get focusAreasSelectorEnterCustomFocusArea =>
      '사용자 지정 집중 부위 입력 (예: \"회전근개\")';

  @override
  String focusAreasSelectorSelected(Object selectedCount) {
    return '$selectedCount개 선택됨';
  }

  @override
  String get focusAreasSelectorTargetAreas => '타겟 부위';

  @override
  String get focusAreasSelectorWhichBodyRegionsTo =>
      '집중할 신체 부위를 선택하세요. 위의 트레이닝 스타일과 결합할 수 있습니다.';

  @override
  String get foldableWarmupLayoutPause => '일시정지';

  @override
  String foldableWarmupLayoutS(Object duration) {
    return '$duration초';
  }

  @override
  String foldableWarmupLayoutSec(Object duration) {
    return '$duration초';
  }

  @override
  String get foldableWarmupLayoutSkipWarmup => '웜업 건너뛰기';

  @override
  String get foldableWarmupLayoutStartWorkout => '운동 시작';

  @override
  String get foldableWarmupLayoutUpNext => '다음 순서';

  @override
  String get foldableWarmupLayoutWarmUp => '웜업';

  @override
  String get foldableWorkoutLeftUpNext => '다음 순서';

  @override
  String get fontScaleCard085x => '0.85x';

  @override
  String get fontScaleCardFontScale => '글꼴 크기';

  @override
  String get fontScaleCardPreciseFontScalingControl => '정밀한 글꼴 크기 조절';

  @override
  String fontScaleCardX(Object scale) {
    return '$scale배';
  }

  @override
  String foodAnalysisInlineCardCal(Object _selectedCalTotal) {
    return '$_selectedCalTotal cal';
  }

  @override
  String foodAnalysisInlineCardCal2(Object cal) {
    return '$cal cal';
  }

  @override
  String foodAnalysisInlineCardGC(Object carbs) {
    return '${carbs}g C';
  }

  @override
  String foodAnalysisInlineCardGF(Object fat) {
    return '${fat}g F';
  }

  @override
  String foodAnalysisInlineCardGP(Object protein) {
    return '${protein}g P';
  }

  @override
  String get foodAnalysisInlineFoodAnalysis => '음식 분석';

  @override
  String get foodAnalysisInlineLogged => '기록됨';

  @override
  String get foodAnalysisInlineU00b7 => '·';

  @override
  String foodAnalysisLoadingElapsed(
    Object _elapsedSeconds,
    Object _stillWorkingIndex,
  ) {
    return '경과-$_elapsedSeconds-$_stillWorkingIndex';
  }

  @override
  String foodAnalysisLoadingS(
    Object _elapsedSeconds,
    Object analysisLoadingCopy,
  ) {
    return '$analysisLoadingCopy… $_elapsedSeconds초';
  }

  @override
  String foodAnalysisLoadingSElapsed(Object _elapsedSeconds) {
    return '$_elapsedSeconds초 경과';
  }

  @override
  String foodAnalysisLoadingValue(Object displayMessage) {
    return '$displayMessage…';
  }

  @override
  String get foodAnalysisResultAiNutritionAnalysisIs =>
      'AI 영양 분석은 추정치입니다. 개인별 식단 조언은 영양사와 상담하세요.';

  @override
  String foodAnalysisResultCardCal(Object adjustedCal) {
    return '$adjustedCal cal';
  }

  @override
  String foodAnalysisResultCardCalTotal(Object totalCalories) {
    return '총 $totalCalories cal';
  }

  @override
  String foodAnalysisResultCardGP(Object adjustedProtein) {
    return '${adjustedProtein}g P';
  }

  @override
  String foodAnalysisResultCardGProtein(Object totalProtein) {
    return '단백질 ${totalProtein}g';
  }

  @override
  String foodAnalysisResultCardLeavesYouCalFor(
    Object mealLabel,
    Object remaining,
  ) {
    return '$mealLabel에 $remaining cal 남음';
  }

  @override
  String foodAnalysisResultCardSelected(Object length) {
    return '$length개 선택됨';
  }

  @override
  String foodAnalysisResultCardShowMore(Object dishes) {
    return '$dishes개 더 보기...';
  }

  @override
  String foodAnalysisResultCardValue(Object label, Object length) {
    return '$label ($length)';
  }

  @override
  String get foodAnalysisResultDeselectAll => '전체 선택 해제';

  @override
  String get foodAnalysisResultGreatChoices => '좋은 선택';

  @override
  String get foodAnalysisResultInModeration => '적당히 섭취';

  @override
  String get foodAnalysisResultItemsLoggedToNutrition => '영양 추적기에 항목이 기록되었습니다';

  @override
  String get foodAnalysisResultLimitThese => '섭취 제한';

  @override
  String get foodAnalysisResultSelectItemsToLog => '기록할 항목 선택';

  @override
  String get foodAnalysisResultShowLess => '간략히 보기';

  @override
  String get foodAnalysisResultTips => '팁';

  @override
  String get foodAnalysisResultU00b7 => ' · ';

  @override
  String get foodBrowserPanelAddModifier => '수정자 추가...';

  @override
  String get foodBrowserPanelAllCountries => '모든 국가';

  @override
  String get foodBrowserPanelCalorieDense => '고칼로리';

  @override
  String get foodBrowserPanelCoachTip => '코치 팁';

  @override
  String get foodBrowserPanelCooking => '조리';

  @override
  String get foodBrowserPanelCouldNotParseAny => '음식 항목을 분석할 수 없습니다';

  @override
  String get foodBrowserPanelDefault => '기본';

  @override
  String get foodBrowserPanelDoneness => '익힘 정도';

  @override
  String foodBrowserPanelFailedToLog(Object error) {
    return '기록 실패: $error';
  }

  @override
  String get foodBrowserPanelFilterByCountry => '국가별 필터링';

  @override
  String get foodBrowserPanelFilterBySource => '출처별 필터';

  @override
  String get foodBrowserPanelHighFat => '고지방';

  @override
  String get foodBrowserPanelHighFiber => '고식이섬유';

  @override
  String get foodBrowserPanelHighProtein => '고단백';

  @override
  String foodBrowserPanelItems(Object totalItems) {
    return '$totalItems개 항목';
  }

  @override
  String get foodBrowserPanelKcal => ' kcal';

  @override
  String foodBrowserPanelKcal2(Object totalCal) {
    return '$totalCal kcal';
  }

  @override
  String get foodBrowserPanelLoadingModifiers => '수정자 불러오는 중...';

  @override
  String get foodBrowserPanelLog => '기록';

  @override
  String get foodBrowserPanelLogAMealTo => '식사를 기록하여 기록을 확인하세요';

  @override
  String foodBrowserPanelLogSelectedItems(Object count) {
    return '선택 항목 기록 ($count개)';
  }

  @override
  String get foodBrowserPanelLookingForASpecific => '특정 제품을 찾으시나요? 대신 검색하세요';

  @override
  String get foodBrowserPanelLowCal => '저칼로리';

  @override
  String get foodBrowserPanelModifiers => '수정자';

  @override
  String foodBrowserPanelNoFoodsFound(Object query) {
    return '\"$query\"에 대한 검색 결과가 없습니다';
  }

  @override
  String get foodBrowserPanelNoSavedFoodsYet => '저장된 음식이 없습니다';

  @override
  String get foodBrowserPanelOnlyMatchFound => '유일한 일치 항목';

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
    return '$calPer100g cal/100g';
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
  String get foodBrowserPanelPureFat => '순수 지방';

  @override
  String get foodBrowserPanelRecent => '최근';

  @override
  String foodBrowserPanelResultsUBMs(Object searchTimeMs, Object totalCount) {
    return '$totalCount개 결과 · ${searchTimeMs}ms';
  }

  @override
  String get foodBrowserPanelSearch528000Foods =>
      'USDA, 캐나다, 인도 등 528,000개 이상의 음식 데이터베이스 검색';

  @override
  String get foodBrowserPanelSearchAlternatives => '대안 검색...';

  @override
  String get foodBrowserPanelSearchCountries => '국가 검색...';

  @override
  String get foodBrowserPanelSearchError => '검색 오류';

  @override
  String get foodBrowserPanelSeeAll => '모두 보기';

  @override
  String get foodBrowserPanelSetDefault => '기본값 설정';

  @override
  String get foodBrowserPanelSize => '크기';

  @override
  String get foodBrowserPanelStarFoodsAfterLogging => '기록 후 즐겨찾기에 추가하여 저장하세요';

  @override
  String get foodBrowserPanelStartTypingAbove => '위에서 입력을 시작하세요...';

  @override
  String get foodBrowserPanelTapItemsToAdjust => '항목을 탭하여 조정하거나 대안을 선택하세요';

  @override
  String get foodBrowserPanelUseAnalyzeForAi => 'AI 추정을 위해 분석 사용';

  @override
  String get foodBrowserPanelYourFoods => '내 음식';

  @override
  String get foodBrowserPanelYourSavedFoods => '저장된 음식';

  @override
  String get foodHistoryFailedToDeleteFood => '음식 기록 삭제 실패';

  @override
  String get foodHistoryFailedToReLog => '음식 재기록 실패';

  @override
  String get foodHistoryFailedToUpdateFood => '음식 기록 업데이트 실패';

  @override
  String get foodHistoryFoodHistory => '음식 기록';

  @override
  String get foodHistoryScreenAiCoachTip => 'AI 코치 팁';

  @override
  String get foodHistoryScreenAvgDay => '일일 평균';

  @override
  String get foodHistoryScreenCal => ' kcal';

  @override
  String get foodHistoryScreenDatabase => '데이터베이스';

  @override
  String get foodHistoryScreenDateRange => '날짜 범위';

  @override
  String get foodHistoryScreenDays => '일';

  @override
  String foodHistoryScreenDeleted(Object foodName) {
    return '$foodName 삭제됨';
  }

  @override
  String get foodHistoryScreenEditPortion => '분량 편집';

  @override
  String foodHistoryScreenFailedToReLog(Object name) {
    return '$name 다시 기록 실패';
  }

  @override
  String get foodHistoryScreenFrequentlyEaten => '자주 먹는 음식';

  @override
  String get foodHistoryScreenInflammationScore => '염증 점수';

  @override
  String get foodHistoryScreenLoadMore => '더 보기';

  @override
  String get foodHistoryScreenMealType => '식사 유형';

  @override
  String get foodHistoryScreenMeals => '식사';

  @override
  String get foodHistoryScreenNoFoodHistoryYet => '아직 음식 기록이 없습니다';

  @override
  String foodHistoryScreenPartDateRangeCal(Object calories) {
    return '$calories cal';
  }

  @override
  String foodHistoryScreenPartDateRangeCal2(Object dayCals) {
    return '$dayCals cal';
  }

  @override
  String foodHistoryScreenPartDateRangeG(Object totalProteinG) {
    return '${totalProteinG}g';
  }

  @override
  String foodHistoryScreenPartDateRangeGP(Object result) {
    return '${result}g P';
  }

  @override
  String foodHistoryScreenPartDateRangeGP2(Object dayProtein) {
    return '${dayProtein}g P';
  }

  @override
  String foodHistoryScreenPartDateRangeNoResultsFor(Object query) {
    return '\"$query\"에 대한 결과가 없습니다';
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
    return '$timesLogged회';
  }

  @override
  String get foodHistoryScreenProtein => '단백질';

  @override
  String foodHistoryScreenReLoggedAs(Object mealType, Object name) {
    return '$name을(를) $mealType(으)로 다시 기록했습니다';
  }

  @override
  String foodHistoryScreenReLoggedAs2(Object foodName, Object mealType) {
    return '$foodName을(를) $mealType(으)로 다시 기록했습니다';
  }

  @override
  String get foodHistoryScreenRecent => '최근';

  @override
  String get foodHistoryScreenSaveChanges => '변경 사항 저장';

  @override
  String get foodHistoryScreenSearchError => '검색 오류';

  @override
  String get foodHistoryScreenStartLoggingMealsTo => '식사를 기록하고 여기에 기록을 확인하세요!';

  @override
  String get foodHistorySearchMealsFoodsHigh => '식사, 음식, \"고단백\" 검색...';

  @override
  String get foodHistoryUndo => '실행 취소';

  @override
  String get foodItemRankingAddFood => '음식 추가';

  @override
  String foodItemRankingNFoodItems(Object count) {
    return '음식 항목 $count개';
  }

  @override
  String get foodItemRankingScore => '점수';

  @override
  String get foodItemRankingTapToHideDetails => '탭하여 상세 정보 숨기기';

  @override
  String get foodItemRankingTapToSeeDetails => '탭하여 상세 정보 보기';

  @override
  String get foodLibraryAHomemadeMealWith => '여러 재료가 들어간 집밥';

  @override
  String get foodLibraryASingleFoodType => '단일 음식 — 직접 입력하거나 AI가 채우도록 하세요';

  @override
  String get foodLibraryAdd => '추가';

  @override
  String get foodLibraryCustomFood => '사용자 지정 음식';

  @override
  String get foodLibraryFailedToDelete => '삭제 실패';

  @override
  String get foodLibraryFoodLibrary => '음식 라이브러리';

  @override
  String get foodLibraryRecipe => '레시피';

  @override
  String foodLibraryScreenAdded(Object name) {
    return '\"$name\" 추가됨';
  }

  @override
  String foodLibraryScreenAll(Object length) {
    return '전체 ($length)';
  }

  @override
  String get foodLibraryScreenCalories => '칼로리';

  @override
  String get foodLibraryScreenCarbs => '탄수화물';

  @override
  String foodLibraryScreenDelete(Object name) {
    return '$name을(를) 삭제할까요?';
  }

  @override
  String foodLibraryScreenDeleted(Object name) {
    return '$name 삭제됨';
  }

  @override
  String get foodLibraryScreenDescription => '설명';

  @override
  String foodLibraryScreenFailedToLoadRecipe(Object e) {
    return '레시피 불러오기 실패: $e';
  }

  @override
  String foodLibraryScreenFailedToLog(Object e) {
    return '기록 실패: $e';
  }

  @override
  String get foodLibraryScreenFat => '지방';

  @override
  String get foodLibraryScreenIngredients => '재료';

  @override
  String get foodLibraryScreenLog => '기록';

  @override
  String get foodLibraryScreenLogThisFood => '이 음식 기록하기';

  @override
  String get foodLibraryScreenLogToWhichMeal => '어떤 식사로 기록할까요?';

  @override
  String foodLibraryScreenLoggedTo(Object label, Object name) {
    return '$name을(를) $label에 기록했습니다';
  }

  @override
  String foodLibraryScreenLogging(Object name) {
    return '$name 기록 중...';
  }

  @override
  String foodLibraryScreenPartFoodLibraryCardCal(Object calories) {
    return '$calories cal';
  }

  @override
  String foodLibraryScreenPartFoodLibraryCardDelete(Object name) {
    return '$name을(를) 삭제할까요?';
  }

  @override
  String foodLibraryScreenPartFoodLibraryCardGProtein(Object item) {
    return '${item}g 단백질';
  }

  @override
  String foodLibraryScreenPartFoodLibraryCardLoggedX(Object timesUsed) {
    return '$timesUsed회 기록됨';
  }

  @override
  String foodLibraryScreenPartFoodLibraryCardX(Object timesUsed) {
    return '$timesUsed회';
  }

  @override
  String get foodLibraryScreenProtein => '단백질';

  @override
  String get foodLibraryScreenRecipe => '레시피';

  @override
  String foodLibraryScreenRecipes(Object length) {
    return '레시피 ($length)';
  }

  @override
  String foodLibraryScreenSaved(Object length) {
    return '저장됨 ($length)';
  }

  @override
  String get foodLibraryScreenSavedFood => '저장된 음식';

  @override
  String get foodLibraryScreenServings => '1회 제공량';

  @override
  String get foodLibraryScreenSortBy => '정렬 기준';

  @override
  String get foodLibraryScreenThisActionCannotBe => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get foodLibrarySearchFoodsAndRecipes => '음식 및 레시피 검색...';

  @override
  String get foodLibraryThisActionCannotBe => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get foodLibraryUsingYourExistingCustom => '기존 사용자 지정 음식 사용';

  @override
  String get foodLoggingRulesAddRule => '규칙 추가';

  @override
  String get foodLoggingRulesAlwaysRules => '상시 규칙';

  @override
  String get foodLoggingRulesConflictingRules => '충돌하는 규칙';

  @override
  String get foodLoggingRulesDeleteRule => '규칙을 삭제할까요?';

  @override
  String get foodLoggingRulesEGNoBun => '예: \"빵 제외\" 또는 \"저유분 인도식 요리\"';

  @override
  String get foodLoggingRulesEditRule => '규칙 편집';

  @override
  String get foodLoggingRulesNewAlwaysRule => '새 상시 규칙';

  @override
  String get foodLoggingRulesNoRulesYet => '아직 규칙이 없습니다';

  @override
  String foodLoggingRulesScreenValue(Object text) {
    return '\"$text\"';
  }

  @override
  String get foodMoodAnalyticsAnalyzingMoodPatterns => '기분 패턴 분석 중...';

  @override
  String get foodMoodAnalyticsAvailableWhenLoggingMeals => '식사 기록 시 사용 가능';

  @override
  String get foodMoodAnalyticsAverage => '평균: ';

  @override
  String get foodMoodAnalyticsAvgEnergy => '평균 에너지';

  @override
  String get foodMoodAnalyticsByMealType => '식사 유형별';

  @override
  String foodMoodAnalyticsCardPartFoodMoodAnalyticsSheetX(Object occurrences) {
    return '$occurrences회';
  }

  @override
  String get foodMoodAnalyticsEnergyLevels => '에너지 수준';

  @override
  String get foodMoodAnalyticsFoodMood => '음식 및 기분';

  @override
  String get foodMoodAnalyticsFoodMoodInsights => '음식 및 기분 인사이트';

  @override
  String get foodMoodAnalyticsFoodsThatBoostYour => '기분을 좋게 하는 음식';

  @override
  String get foodMoodAnalyticsFoodsToWatch => '주의할 음식';

  @override
  String get foodMoodAnalyticsLogHowYouFeel => '식사 전후의 기분을 기록하여 패턴을 발견하세요';

  @override
  String get foodMoodAnalyticsMealsTracked => '기록된 식사 수';

  @override
  String get foodMoodAnalyticsMoodAfterEating => '식사 후 기분';

  @override
  String get foodMoodAnalyticsMoodImproved => '기분 개선';

  @override
  String get foodMoodAnalyticsNoEnergyDataRecorded => '기록된 에너지 데이터가 없습니다';

  @override
  String get foodMoodAnalyticsNoMoodDataYet => '아직 기록된 기분 데이터가 없습니다';

  @override
  String foodMoodAnalyticsOftenImprovesYourMood(Object food) {
    return '$food은(는) 종종 기분을 좋게 합니다';
  }

  @override
  String get foodMoodAnalyticsStartTrackingMood => '기분 기록 시작하기';

  @override
  String get foodMoodAnalyticsTrackYourMoodWhen =>
      '식사 기록 시 기분을 함께 기록하여\n패턴과 인사이트를 확인하세요';

  @override
  String get foodMoodAnalyticsTrackedMeals => '기록된 식사';

  @override
  String get foodMoodAnalyticsTrackingRate => '기록 비율';

  @override
  String get foodMoodAnalyticsUnableToLoadData => '데이터를 불러올 수 없습니다';

  @override
  String get foodMoodAnalyticsUnableToLoadMood => '기분 데이터를 불러올 수 없습니다';

  @override
  String get foodReportCalories => '칼로리';

  @override
  String get foodReportCarbs => '탄수화물';

  @override
  String get foodReportCorrectedValues => '수정된 값';

  @override
  String foodReportDialogFailedToSubmitReport(Object e) {
    return '보고서 제출 실패: $e';
  }

  @override
  String foodReportDialogValue(Object reportId) {
    return '#$reportId';
  }

  @override
  String get foodReportEGISearched => '예: 부리또 볼이 아니라 멕시칸 콜라를 검색함';

  @override
  String get foodReportFat => '지방';

  @override
  String get foodReportProtein => '단백질';

  @override
  String get foodReportReportIssue => '문제 신고';

  @override
  String get foodReportReportSubmitted => '신고가 제출되었습니다';

  @override
  String get foodReportSubmitReport => '신고 제출';

  @override
  String get foodReportWeLlReviewAnd =>
      '48시간 이내에 검토 후 업데이트하겠습니다.\n데이터 개선에 도움을 주셔서 감사합니다!';

  @override
  String get foodReportWhatFoodDidYou => '어떤 음식을 찾으셨나요?';

  @override
  String get foodReportWrongFood => '잘못된 음식';

  @override
  String get foodReportWrongNutrition => '잘못된 영양 정보';

  @override
  String get foodSearchBarClearAll => '모두 지우기';

  @override
  String get foodSearchBarRecentSearches => '최근 검색어';

  @override
  String get foodSearchBarSearchFoods => '음식 검색...';

  @override
  String foodSearchResultsAiWillEstimateNutrition(Object query) {
    return 'AI가 \"$query\"의 영양 성분을 추정합니다';
  }

  @override
  String get foodSearchResultsAnalyzeWithAi => 'AI로 분석';

  @override
  String get foodSearchResultsDatabase => '데이터베이스';

  @override
  String get foodSearchResultsFoodDatabase => '음식 데이터베이스';

  @override
  String foodSearchResultsG(Object result) {
    return '${result}g';
  }

  @override
  String get foodSearchResultsInstantResults => '즉시 결과';

  @override
  String get foodSearchResultsNoFoodsFound => '검색된 음식이 없습니다';

  @override
  String foodSearchResultsNoSavedFoodsMatch(Object query) {
    return '\"$query\"와 일치하는 저장된 음식이 없습니다.';
  }

  @override
  String get foodSearchResultsRecent => '최근';

  @override
  String get foodSearchResultsSavedFoods => '저장된 음식';

  @override
  String get foodSearchResultsSomethingWentWrong => '오류가 발생했습니다';

  @override
  String get foodSearchResultsTypeToSearchYour =>
      '저장된 음식, 최근 식사 또는 데이터베이스를 검색하세요.';

  @override
  String get formCheckResultAiFormAnalysisIs =>
      'AI 자세 분석은 교육 목적으로만 제공됩니다. 개인별 맞춤 지도는 전문 트레이너와 상담하세요.';

  @override
  String get formCheckResultAreasToImprove => '개선할 점';

  @override
  String get formCheckResultBreathing => '호흡';

  @override
  String formCheckResultCardEstimatedReps(Object repCount) {
    return '약 $repCount회 예상';
  }

  @override
  String formCheckResultCardObserved(Object pattern) {
    return '관찰됨: $pattern';
  }

  @override
  String formCheckResultCardObserved2(Object observed) {
    return '관찰됨: $observed';
  }

  @override
  String formCheckResultCardShowMore(Object improvements) {
    return '$improvements개 더 보기...';
  }

  @override
  String formCheckResultCardValue(Object score) {
    return '$score/10';
  }

  @override
  String get formCheckResultDoingWell => '잘하고 있는 점';

  @override
  String get formCheckResultFormCheck => '자세 점검';

  @override
  String get formCheckResultGood => '좋음';

  @override
  String get formCheckResultNeedsWork => '보완 필요';

  @override
  String get formCheckResultSendAVideoOf =>
      '운동 영상을 보내주시면 자세를 확인하고, 횟수를 세어드리며, 교정 방법을 알려드립니다.';

  @override
  String get formCheckResultTempo => '템포';

  @override
  String get formComparisonResultAiFormAnalysisIs =>
      'AI 자세 분석은 교육 목적으로만 제공됩니다. 개인별 맞춤 지도는 전문 트레이너와 상담하세요.';

  @override
  String get formComparisonResultBeta => 'BETA';

  @override
  String formComparisonResultCardReps(Object repCount) {
    return '$repCount회';
  }

  @override
  String get formComparisonResultConsistent => '일관됨';

  @override
  String get formComparisonResultFormComparison => '자세 비교';

  @override
  String get formComparisonResultImproved => '향상됨';

  @override
  String get formComparisonResultImproving => '향상 중';

  @override
  String get formComparisonResultOverallTrend => '전반적인 추세';

  @override
  String get formComparisonResultRecommendations => '권장 사항';

  @override
  String get formComparisonResultRegressed => '퇴보함';

  @override
  String get formComparisonResultRegressing => '저하 중';

  @override
  String get formComparisonResultScoreTrend => '점수 추세';

  @override
  String get formComparisonResultStable => '안정적';

  @override
  String get founderNoteDiscord => 'Discord';

  @override
  String get founderNoteRoadmap => '로드맵';

  @override
  String get founderNoteFounderSoloStillOn => '1인 창업자, 여전히 버전 1에 머물러 있습니다.';

  @override
  String get founderNoteIUsedToLog =>
      '저는 2주 동안 매일 모든 식사를 기록하며 뿌듯해하다가, 메뉴를 읽을 수 없는 태국 식당에 들어가 가장 안전해 보이는 음식을 먹고 조용히 앱을 삭제하곤 했습니다. 3주 뒤에는 다른 앱을 다시 설치하고 이번엔 다를 거라 다짐하며 같은 과정을 반복했죠. 모든 앱이 제 데이터를 기록했지만, 제가 기록을 멈췄을 때 알아차린 앱은 없었습니다. 그것들은 코치가 아니라 장부였으니까요.';

  @override
  String get founderNoteInstagram => 'Instagram';

  @override
  String founderNoteSheetANoteFrom(Object _founderName) {
    return '창립자의 메시지: $_founderName';
  }

  @override
  String founderNoteSheetValue(Object _founderName) {
    return '— $_founderName';
  }

  @override
  String get founderNoteSoIBuiltThe =>
      '그래서 장부가 아닌 사람을 지었습니다. 국내든 해외든 메뉴를 찍으면 코치가 매크로로 다시 읽어줍니다. 화요일을 건너뛰면 죄책감 없이 수요일 아침에 돌아올 수 있습니다. 한 달에 한 번 미만의 PT 세션으로 음식, 체육관, 슬립 패턴을 학습합니다.';

  @override
  String get founderNoteTheFriendsWhoActually =>
      '실제로 몸을 만든 친구들은 누군가와 계속 연락을 주고받았습니다. 실제 책임감 있는 관리는 한 달에 약 200달러가 들고, 이것이 바로 우리 대부분이 그런 관리를 받지 못하는 이유이며, \'기록\'과 \'변화\' 사이의 간극이 수년 동안 좁혀지지 않는 이유입니다.';

  @override
  String get freshnessDecayCardControlsHowQuicklyExercise =>
      '운동 신선도가 감소하는 속도를 제어합니다: e^(-k * 세션)';

  @override
  String get freshnessDecayCardFreshnessDecayTuner => '신선도 감소 튜너';

  @override
  String freshnessDecayCardK(Object _freshnessDecay) {
    return 'k = $_freshnessDecay';
  }

  @override
  String get freshnessDecayCardLivePreview => '실시간 미리보기';

  @override
  String get freshnessDecayCardRange0100 => '범위: 0.10 - 0.60';

  @override
  String freshnessDecayCardUsedSessionsAgo(num sessions) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions회 세션 전 사용됨',
      one: '1회 세션 전 사용됨',
    );
    return '$_temp0';
  }

  @override
  String friendAvatarsRowMore(Object remaining) {
    return '+$remaining명 더';
  }

  @override
  String get friendAvatarsRowOnThisGoal => '이 목표 달성 중';

  @override
  String friendCardBadges(Object totalAchievements) {
    return '배지 $totalAchievements개';
  }

  @override
  String friendCardDayStreak(Object currentStreak) {
    return '$currentStreak일 연속 기록';
  }

  @override
  String get friendCardFollow => '팔로우';

  @override
  String get friendCardFriend => '친구';

  @override
  String friendCardSupport(Object appName) {
    return '$appName 고객지원';
  }

  @override
  String get friendCardUnfollow => '팔로우 취소';

  @override
  String friendCardWorkouts(Object totalWorkouts) {
    return '운동 $totalWorkouts회';
  }

  @override
  String get friendProfileBlock => '차단';

  @override
  String get friendProfileBlockUser => '사용자 차단';

  @override
  String get friendProfileFailedToOpenConversation => '대화를 열지 못했습니다';

  @override
  String get friendProfileFailedToUpdateFollow => '팔로우 상태를 업데이트하지 못했습니다';

  @override
  String get friendProfileFollow => '팔로우';

  @override
  String get friendProfileFollowers => '팔로워';

  @override
  String get friendProfileFollowing => '팔로잉';

  @override
  String get friendProfileMemberInfo => '회원 정보';

  @override
  String get friendProfileMessage => '메시지';

  @override
  String get friendProfileMoreDetailsComingSoon => '더 많은 정보가 곧 제공됩니다';

  @override
  String get friendProfileThisUserWillNot =>
      '이 사용자는 귀하의 콘텐츠를 보거나 메시지를 보낼 수 없습니다. 나중에 차단을 해제할 수 있습니다.';

  @override
  String get friendProfileUserBlocked => '사용자가 차단되었습니다';

  @override
  String get friendProfileWorkoutHistoryPrsAnd =>
      '운동 기록, PR 및 트로피가\n여기에 표시됩니다.';

  @override
  String get friendSearchFindFriends => '친구 찾기';

  @override
  String get friendSearchFollowFriendsToGet => '친구를 팔로우하고 더 나은 추천을 받으세요';

  @override
  String get friendSearchNoSuggestionsYet => '아직 추천 친구가 없습니다';

  @override
  String get friendSearchNoUsersFound => '사용자를 찾을 수 없습니다';

  @override
  String get friendSearchSearch => '검색';

  @override
  String get friendSearchSearchByNameOr => '이름 또는 사용자 이름으로 검색...';

  @override
  String get friendSearchSearchForFriends => '친구 검색';

  @override
  String get friendSearchSuggestions => '추천';

  @override
  String get friendSearchTryADifferentSearch => '다른 검색어를 입력해 보세요';

  @override
  String get friendSearchTypeANameOr => '이름이나 사용자 이름을 입력하여 사용자를 찾으세요';

  @override
  String get friendsAddFriendsToSee => '친구를 추가하고 운동을 확인하며\n함께 챌린지에 도전하세요!';

  @override
  String get friendsCouldNotLoadUsers => '팔로우 중인 사용자를 불러올 수 없습니다.\n다시 시도해 주세요.';

  @override
  String get friendsCouldNotLoadYour => '친구 목록을 불러올 수 없습니다.\n다시 시도해 주세요.';

  @override
  String get friendsCouldNotLoadYour2 => '팔로워 목록을 불러올 수 없습니다.\n다시 시도해 주세요.';

  @override
  String get friendsFailedToLoadFollowers => '팔로워를 불러오지 못했습니다';

  @override
  String get friendsFailedToLoadFollowing => '팔로잉을 불러오지 못했습니다';

  @override
  String get friendsFailedToLoadFriends => '친구를 불러오지 못했습니다';

  @override
  String get friendsFollowFriendsToSee => '친구를 팔로우하고 운동을 확인하며\n함께 동기부여를 유지하세요!';

  @override
  String get friendsFollowers => '팔로워';

  @override
  String get friendsFollowing => '팔로잉';

  @override
  String get friendsFriendRequests => '친구 요청';

  @override
  String get friendsKeepCrushingYourWorkouts =>
      '계속해서 열심히 운동하세요!\n친구들이 당신의 성장을 지켜볼 것입니다.';

  @override
  String get friendsNoFollowersYet => '아직 팔로워가 없습니다';

  @override
  String get friendsNoFriendsYet => '아직 친구가 없습니다';

  @override
  String get friendsNotFollowingAnyone => '팔로우 중인 사용자가 없습니다';

  @override
  String get fuelFasting => '단식';

  @override
  String get fuelNutrients => '영양소';

  @override
  String get fuelWater => '수분';

  @override
  String get fullScreenChart1y => '1년';

  @override
  String get fullScreenChart30d => '30일';

  @override
  String get fullScreenChart7d => '7일';

  @override
  String get fullScreenChart90d => '90일';

  @override
  String get fullScreenChartAll => '전체';

  @override
  String get fullScreenChartCompareWith => '비교 대상...';

  @override
  String get fullScreenChartCouldNotLoad => '불러올 수 없음';

  @override
  String get fullScreenChartNotEnoughHistory => '기록이 충분하지 않음';

  @override
  String get fullscreenImageViewerCouldNotLoadImage => '이미지를 불러올 수 없습니다';

  @override
  String get futuristicSetCardAiSuggested => 'AI 추천';

  @override
  String get futuristicSetCardHidePrevious => '이전 기록 숨기기';

  @override
  String futuristicSetCardRir(Object targetRir) {
    return 'RIR $targetRir';
  }

  @override
  String futuristicSetCardRmKg(Object suggestion) {
    return '1RM: ${suggestion}kg';
  }

  @override
  String futuristicSetCardSetOf(Object currentSetNumber, Object totalSets) {
    return '$totalSets세트 중 $currentSetNumber세트';
  }

  @override
  String get futuristicSetCardSkipExercise => '운동 건너뛰기';

  @override
  String get generatePlanCreateAHolisticPlan =>
      '운동, 영양, 단식을 아우르는 종합적인 계획을 세우세요.';

  @override
  String get generatePlanFastingProtocol => '단식 프로토콜';

  @override
  String get generatePlanGeneratePlan => '계획 생성';

  @override
  String get generatePlanGenerateWeeklyPlan => '주간 계획 생성';

  @override
  String get generatePlanGenerating => '생성 중...';

  @override
  String get generatePlanNutritionStrategy => '영양 전략';

  @override
  String get generatePlanPreferredWorkoutTime => '선호하는 운동 시간';

  @override
  String get generatePlanTrainingDays => '운동 요일';

  @override
  String get generatePlanWeeklyPlanGenerated => '주간 계획이 생성되었습니다!';

  @override
  String get generateWorkoutPlaceholderEachWorkoutAdaptsTo =>
      '각 운동은 안전하게 발전할 수 있도록 조정됩니다!';

  @override
  String get generateWorkoutPlaceholderGenerateWorkout => '운동 생성';

  @override
  String get generateWorkoutPlaceholderGenerating => '생성 중...';

  @override
  String get generateWorkoutPlaceholderGenerationFailed => '생성 실패';

  @override
  String get generateWorkoutPlaceholderPersonalizedUsingYourWorkou =>
      '운동 기록을 바탕으로 개인화됨';

  @override
  String get generateWorkoutPlaceholderTapBelowToTry => '다시 시도하려면 아래를 탭하세요';

  @override
  String get generateWorkoutPlaceholderTapToRetry => '탭하여 다시 시도';

  @override
  String get generateWorkoutPlaceholderWhatPowersYourWorkout =>
      '운동의 원동력은 무엇인가요?';

  @override
  String get generateWorkoutPlaceholderYourAiCoachCreates =>
      'AI 코치가 다음을 바탕으로 운동을 생성합니다:';

  @override
  String get glassDragToResize => '드래그하여 크기 조절';

  @override
  String get globalChatBubbleAskMeAnythingAbout => '피트니스에 대해 무엇이든 물어보세요';

  @override
  String get globalChatBubbleAskYourAiCoach => 'AI 코치에게 물어보기...';

  @override
  String get globalChatBubbleChangeCoach => '코치 변경';

  @override
  String get globalChatBubbleErrorLoadingMessages => '메시지를 불러오는 중 오류 발생';

  @override
  String get globalChatBubbleHowCanIHelp => '오늘 무엇을 도와드릴까요?';

  @override
  String get globalChatBubbleOnline => '온라인';

  @override
  String get globalChatBubbleTyping => '입력 중...';

  @override
  String get glossaryGlossary => '용어집';

  @override
  String get glossaryNoTermsFound => '용어를 찾을 수 없습니다';

  @override
  String glossaryScreenTerms(Object length) {
    return '$length개의 용어';
  }

  @override
  String get glossarySearchTerms => '용어 검색...';

  @override
  String glowButtonCompleteSet(Object setNumber) {
    return '$setNumber세트 완료';
  }

  @override
  String get goalCard1DayLeft => '1일 남음';

  @override
  String get goalCardBestAttempt => '최고 기록';

  @override
  String goalCardDaysLeft(Object daysRemaining) {
    return '$daysRemaining일 남음';
  }

  @override
  String get goalCardDeleteGoal => '목표 삭제';

  @override
  String get goalCardNewPr => '새로운 PR!';

  @override
  String goalCardPermanentlyRemove(Object exerciseName) {
    return '\"$exerciseName\" 영구 삭제';
  }

  @override
  String get goalCardPersonalBest => '개인 최고 기록';

  @override
  String get goalCardViewProgressHistory => '진행 기록 보기';

  @override
  String get goalHistoryAllTimeBest => '역대 최고 기록';

  @override
  String get goalHistoryChartAllTimeBest => '역대 최고 기록';

  @override
  String goalHistoryChartBestValue(Object value) {
    return '최고: $value';
  }

  @override
  String get goalHistoryChartCompleteMoreWeeksTo => '더 많은 주를 완료하여 목표 추이를 확인하세요';

  @override
  String get goalHistoryChartGoalTrends => '목표 추이';

  @override
  String get goalHistoryChartNoHistoryYet => '아직 기록이 없습니다';

  @override
  String get goalHistoryCouldNotLoadHistory => '기록을 불러올 수 없습니다';

  @override
  String get goalHistoryThisWeek => '이번 주';

  @override
  String get goalHistoryTipsForBeatingYour => 'PR 경신을 위한 팁';

  @override
  String get goalHistoryTryAgain => '다시 시도';

  @override
  String get goalHistoryU2022 => '• ';

  @override
  String get goalLeaderboardCouldNotLoadLeaderboard => '리더보드를 불러올 수 없습니다';

  @override
  String get goalLeaderboardFriendsLeaderboard => '친구 리더보드';

  @override
  String get goalLeaderboardInviteFriendsToCompete => '친구를 초대해 경쟁하세요!';

  @override
  String get goalLeaderboardNoFriendsOnThis => '이 목표에 참여 중인 친구가 없습니다';

  @override
  String get goalLeaderboardPr => 'PR';

  @override
  String goalLeaderboardSheetValue(Object userProgressPercentage) {
    return '$userProgressPercentage%';
  }

  @override
  String get googleCalendarConnectConnectGoogleCalendar => 'Google Calendar 연결';

  @override
  String get googleCalendarConnectConnected => '연결됨';

  @override
  String get googleCalendarConnectDisconnect => '연결 해제';

  @override
  String get googleCalendarConnectFailedToConnectGoogle =>
      'Google Calendar 연결에 실패했습니다';

  @override
  String get googleCalendarConnectGoogleCalendar => 'Google Calendar';

  @override
  String get googleCalendarConnectGoogleCalendarConnected =>
      'Google Calendar가 연결되었습니다!';

  @override
  String get googleCalendarConnectGoogleCalendarDisconnected =>
      'Google Calendar 연결이 해제되었습니다';

  @override
  String googleCalendarConnectSheetConnectYourGoogleCalendar(Object appName) {
    return 'Google Calendar를 연결하여 바쁜 시간을 확인하고 $appName 이벤트를 동기화하세요';
  }

  @override
  String get googleCalendarConnectWeOnlyAccessCalendar =>
      '사용자가 명시적으로 허용한 캘린더 데이터에만 액세스합니다';

  @override
  String get groceryListAdd => '추가';

  @override
  String get groceryListAddItem => '항목 추가';

  @override
  String get groceryListAisleOptional => '통로 (선택 사항)';

  @override
  String get groceryListCopiedToClipboard => '클립보드에 복사되었습니다';

  @override
  String get groceryListCopyAsText => '텍스트로 복사';

  @override
  String get groceryListGroceryList => '식료품 목록';

  @override
  String get groceryListHidePantryStaples => '상비 식재료 숨기기';

  @override
  String get groceryListHidingKeepsTheList => '숨기기를 하면 실제로 필요한 항목에 집중할 수 있습니다';

  @override
  String get groceryListItemName => '항목 이름';

  @override
  String get groceryListNoItemsYet => '아직 항목이 없습니다';

  @override
  String get groceryListQty => '수량';

  @override
  String get groceryListShareAsCsv => 'CSV로 공유';

  @override
  String get groceryListShowPantryStaples => '상비 식재료 보기';

  @override
  String get groceryListTapTheButtonBelow => '아래 + 버튼을 눌러 재료를 추가하세요.';

  @override
  String get groceryListUnitGCup => '단위 (g, cup, ...)';

  @override
  String get groceryListsIndexCreate => '생성';

  @override
  String get groceryListsIndexGroceryLists => '식료품 목록';

  @override
  String get groceryListsIndexListNameOptional => '목록 이름 (선택 사항)';

  @override
  String get groceryListsIndexNewGroceryList => '새 식료품 목록';

  @override
  String get groceryListsIndexNoListsYet => '아직 목록이 없습니다';

  @override
  String groceryListsIndexScreenOfChecked(
    Object checkedCount,
    Object itemCount,
  ) {
    return '$checkedCount / $itemCount개 체크됨';
  }

  @override
  String get groceryListsIndexTapToCreateA => '+를 눌러 목록을 만들거나 레시피에서 추가하세요.';

  @override
  String get groceryListsIndexUntitled => '제목 없음';

  @override
  String get groundingPromptGroundYourself => '마음 가다듬기';

  @override
  String get groundingPromptIMReady => '준비됐어요';

  @override
  String get groupCreateCreateGroup => '그룹 생성';

  @override
  String get groupCreateEGGymSquad => '예: 운동 모임';

  @override
  String get groupCreateFailedToLoadFriends => '친구 목록을 불러오지 못했습니다';

  @override
  String get groupCreateMin2Required => '최소 2명 필요';

  @override
  String get groupCreateNewGroup => '새 그룹';

  @override
  String get groupCreateNoFriendsToAdd => '추가할 친구가 없습니다';

  @override
  String get groupCreateSearchFriends => '친구 검색...';

  @override
  String groupCreateSheetNoFriendsMatching(Object searchQuery) {
    return '\"$searchQuery\"와 일치하는 친구가 없습니다';
  }

  @override
  String groupCreateSheetSelectFriendsSelected(Object length) {
    return '친구 선택 ($length명 선택됨)';
  }

  @override
  String get groupSettingsAdd => '추가';

  @override
  String get groupSettingsAddMembers => '멤버 추가';

  @override
  String get groupSettingsAdmin => '관리자';

  @override
  String get groupSettingsAllYourFriendsAre => '모든 친구가 이미 이 그룹에 있습니다';

  @override
  String get groupSettingsAreYouSureYou =>
      '정말 이 그룹을 나가시겠습니까? 더 이상 이 대화의 메시지를 받을 수 없습니다.';

  @override
  String get groupSettingsGroupNameUpdated => '그룹 이름이 업데이트되었습니다';

  @override
  String get groupSettingsGroupSettings => '그룹 설정';

  @override
  String get groupSettingsLeave => '나가기';

  @override
  String get groupSettingsLeaveGroup => '그룹 나가기';

  @override
  String get groupSettingsMemberListWillLoad => '멤버 목록을 서버에서 불러옵니다';

  @override
  String get groupSettingsMembers => '멤버';

  @override
  String get groupSettingsRemove => '제거';

  @override
  String get groupSettingsRemoveMember => '멤버 제거';

  @override
  String groupSettingsScreenAdd(Object length) {
    return '추가 ($length)';
  }

  @override
  String groupSettingsScreenAddedMemberS(Object length) {
    return '멤버 $length명 추가됨';
  }

  @override
  String groupSettingsScreenFailedToUpdateName(Object e) {
    return '이름 업데이트 실패: $e';
  }

  @override
  String groupSettingsScreenRemoveFromThisGroup(Object memberName) {
    return '$memberName을(를) 이 그룹에서 삭제할까요?';
  }

  @override
  String groupSettingsScreenRemovedFromGroup(Object memberName) {
    return '$memberName이(가) 그룹에서 삭제되었습니다';
  }

  @override
  String groupSettingsScreenYou(Object memberName) {
    return '$memberName (나)';
  }

  @override
  String get guestHome1700WithSignup => '가입 시 1700개 이상 제공';

  @override
  String get guestHomeAiCoachDemo => 'AI 코치 데모';

  @override
  String get guestHomeAllFree => '모두 무료';

  @override
  String get guestHomeContinuePreview => '미리보기 계속하기';

  @override
  String get guestHomeEnjoyingThePreview => '미리보기가 마음에 드시나요?';

  @override
  String get guestHomeExerciseLibrary => '운동 라이브러리';

  @override
  String get guestHomeGetUnlimitedAiCoaching => '무제한 AI 코칭 받기';

  @override
  String get guestHomeInteractive => '대화형';

  @override
  String get guestHomePreview => '미리보기';

  @override
  String get guestHomePreview20Exercises => '20가지 운동 미리보기';

  @override
  String get guestHomeScreenAiCoachChat => 'AI 코치 채팅';

  @override
  String get guestHomeScreenAskAnythingAboutFitness => '운동에 대해 무엇이든 물어보세요';

  @override
  String guestHomeScreenExploreWhatCanDo(Object appName) {
    return '$appName의 기능을 살펴보세요';
  }

  @override
  String get guestHomeScreenLiveDemo => '라이브 데모';

  @override
  String get guestHomeScreenTapToTryAi => '탭하여 AI 코치 체험하기';

  @override
  String get guestHomeSeeHowYourPersonal => '개인 AI 코치가 어떻게 작동하는지 확인해보세요';

  @override
  String get guestHomeSessionEndingSoon => '세션 종료 임박';

  @override
  String get guestHomeSignUpFree => '무료 가입';

  @override
  String get guestHomeSignUpFreeTo => '무료로 가입하고 모든 기능을 제한 없이 사용하세요!';

  @override
  String get guestHomeSignUpFreeTo2 => '무료로 가입하여 모든 기능을 잠금 해제하고 운동 여정을 시작하세요!';

  @override
  String get guestHomeSignUpFreeTo3 =>
      '무료로 가입하고 운동 관련 질문을 하여 연중무휴 개인 맞춤형 조언을 받으세요';

  @override
  String get guestHomeTapAQuestionTo => '질문을 탭하여 AI 답변 보기';

  @override
  String get guestHomeTryItNow => '지금 체험하기';

  @override
  String get guestHomeWelcomeGuest => '게스트님, 환영합니다';

  @override
  String get guestHomeWhatYouLlGet => '제공 혜택';

  @override
  String get guestHomeYour10MinutePreview => '10분 미리보기 세션이 종료되었습니다.';

  @override
  String get guestLibraryBrowseSampleExercises => '샘플 운동 둘러보기';

  @override
  String get guestLibraryClearSearch => '검색 지우기';

  @override
  String get guestLibraryExerciseLibrary => '운동 라이브러리';

  @override
  String get guestLibraryFailedToLoadExercises => '운동 목록을 불러오지 못했습니다';

  @override
  String get guestLibraryGetVideoDemonstrations => '영상 가이드 보기';

  @override
  String get guestLibraryInstructions => '운동 방법';

  @override
  String get guestLibraryNoExercisesFound => '운동을 찾을 수 없습니다';

  @override
  String get guestLibraryPreview => '미리보기';

  @override
  String guestLibraryScreenShowingSampleExercisesSign(
    Object guestExerciseLimit,
  ) {
    return '샘플 운동 $guestExerciseLimit개를 보여드리고 있습니다. 무료로 가입하고 1700개 이상의 운동을 이용하세요!';
  }

  @override
  String get guestLibrarySearchExercises => '운동 검색...';

  @override
  String get guestLibrarySignUp => '가입하기';

  @override
  String get guestLibrarySignUpFree => '무료로 가입하기';

  @override
  String get guestLibrarySignUpFreeTo =>
      '무료로 가입하고 영상 가이드와 운동 방법이 포함된 전체 운동 라이브러리를 이용하세요.';

  @override
  String get guestLibrarySignUpFreeTo2 => '무료로 가입하고 모든 운동의 HD 영상 가이드를 확인하세요.';

  @override
  String get guestLibrarySignUpToView => '가입하고 이 운동의 상세한 운동 방법을 확인하세요.';

  @override
  String get guestLibraryUnlock1700Exercises => '1700개 이상의 운동 잠금 해제';

  @override
  String get guestLockedFeatureUnlockFree => '무료로 잠금 해제';

  @override
  String get guestSampleWorkoutExercises => '운동 목록';

  @override
  String get guestSampleWorkoutExercisesIncluded => '포함된 운동:';

  @override
  String get guestSampleWorkoutFullBodyStrength => '전신 근력 운동';

  @override
  String get guestSampleWorkoutGetPersonalizedWorkouts => '맞춤형 운동 받기';

  @override
  String get guestSampleWorkoutSampleWorkout => '샘플 운동';

  @override
  String get guestSampleWorkoutSampleWorkoutDemo => '샘플 운동 데모';

  @override
  String get guestSampleWorkoutSignUpFree => '무료로 가입하기';

  @override
  String get guestSampleWorkoutSignUpFreeTo =>
      '무료로 가입하고 목표, 장비, 일정에 맞춘 AI 생성 운동을 받아보세요.';

  @override
  String get guestSampleWorkoutTapToSeeWorkout => '탭하여 운동 데모 보기';

  @override
  String get guestSessionTimerFreeDemoDay => '무료 체험일';

  @override
  String get guestSessionTimerPreviewPlan => '플랜 미리보기';

  @override
  String get guestSessionTimerTryFree => '무료 체험';

  @override
  String get guestSessionTimerTryWorkout => '운동 시작하기';

  @override
  String get guestSignUpGetYourPersonalPlan => '나만의 맞춤 플랜 받기';

  @override
  String get guestSignUpSeeYourFullWorkout =>
      '결제 전 전체 운동 플랜을 확인하세요. 신용카드는 필요하지 않습니다!';

  @override
  String get guestSignUpSignUp => '가입하기';

  @override
  String get guestUpgradeContinueAsGuest => '게스트로 계속하기';

  @override
  String get guestUpgradeGuestMode => '게스트 모드';

  @override
  String guestUpgradeSheetChatsLeft(Object remainingChatMessages) {
    return '남은 채팅 $remainingChatMessages개';
  }

  @override
  String get guestUpgradeSignUp => '가입하기';

  @override
  String get guestUpgradeSignUpFree => '무료로 가입하기';

  @override
  String get guestUpgradeSignUpFreeFor => '무료로 가입하고 무제한 이용하기';

  @override
  String get guestUpgradeYourGuestUsageToday => '오늘의 게스트 사용량';

  @override
  String get gymEquipmentDeselectAll => '전체 선택 해제';

  @override
  String get gymEquipmentEditWeights => '무게 편집';

  @override
  String get gymEquipmentEquipment => '운동 장비';

  @override
  String get gymEquipmentFilterEquipmentByName => '이름으로 장비 필터링';

  @override
  String get gymEquipmentImportFromPdfPhotos => 'PDF, 사진 또는 URL에서 가져오기';

  @override
  String get gymEquipmentLetAiPopulateYour => 'AI가 장비 목록을 자동으로 채우도록 하세요';

  @override
  String get gymEquipmentResetAll => '전체 초기화';

  @override
  String get gymEquipmentSelectAll => '전체 선택';

  @override
  String gymEquipmentSheetSaveItems(Object length) {
    return '항목 $length개 저장';
  }

  @override
  String gymEquipmentSheetSelected(Object length) {
    return '$length개 선택됨';
  }

  @override
  String get gymLocationPickerGymLocation => '헬스장 위치';

  @override
  String get gymLocationPickerMapBasedLocationPicker =>
      '지도 기반 위치 선택은 아직 지원되지 않습니다.\n현재는 프로필에서 헬스장 이름을 설정해주세요.';

  @override
  String get gymProfileSwitcherActive => '활성';

  @override
  String get gymProfileSwitcherAddGym => '헬스장 추가';

  @override
  String gymProfileSwitcherAreYouSureYou(Object name) {
    return '\"$name\"을(를) 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String gymProfileSwitcherCreated(Object result) {
    return '\"$result\" 생성됨';
  }

  @override
  String get gymProfileSwitcherDeleteGym => '헬스장을 삭제할까요?';

  @override
  String gymProfileSwitcherDeleted(Object name) {
    return '\"$name\" 삭제됨';
  }

  @override
  String get gymProfileSwitcherDragToReorderProfiles => '드래그하여 프로필 순서 변경';

  @override
  String get gymProfileSwitcherDuplicate => '복제';

  @override
  String get gymProfileSwitcherDuplicateGym => '헬스장 복제';

  @override
  String get gymProfileSwitcherEnterANameFor => '복제할 헬스장 이름을 입력하세요:';

  @override
  String gymProfileSwitcherEquipment(
    Object environmentDisplayName,
    Object equipmentCount,
  ) {
    return '기구 $equipmentCount개 • $environmentDisplayName';
  }

  @override
  String gymProfileSwitcherFailedToDelete(Object e) {
    return '삭제 실패: $e';
  }

  @override
  String gymProfileSwitcherFailedToSwitchProfile(Object e) {
    return '프로필 전환 실패: $e';
  }

  @override
  String get gymProfileSwitcherGymName => '헬스장 이름';

  @override
  String get gymProfileSwitcherManageProfiles => '프로필 관리';

  @override
  String get gymProfileSwitcherSwitchGym => '헬스장 전환';

  @override
  String get gymProfileSwitcherTapToRetry => '탭하여 다시 시도';

  @override
  String get habitCardLast30Days => '최근 30일';

  @override
  String habitCardValue(Object completionRate7d) {
    return '$completionRate7d%';
  }

  @override
  String get habitDetailCalendar => '달력';

  @override
  String get habitDetailFailedToCaptureImage => '이미지를 캡처하지 못했습니다';

  @override
  String get habitDetailFailedToLoadHabit => '습관 상세 정보를 불러오지 못했습니다';

  @override
  String get habitDetailHabitNotFound => '습관을 찾을 수 없습니다';

  @override
  String get habitDetailOverview => '개요';

  @override
  String get habitDetailScreen8WeekTrend => '8주 추이';

  @override
  String get habitDetailScreenBest => '최고 기록';

  @override
  String get habitDetailScreenCompleteThisHabitTo => '이 습관을 완료하고 기록을 확인하세요';

  @override
  String get habitDetailScreenCompleted => '완료';

  @override
  String get habitDetailScreenDayOfWeek => '요일';

  @override
  String get habitDetailScreenDayStreak => '일 연속';

  @override
  String get habitDetailScreenHabitStrength => '습관 강도';

  @override
  String get habitDetailScreenMissed => '미달성';

  @override
  String get habitDetailScreenMonthlySummary => '월간 요약';

  @override
  String get habitDetailScreenNoActivityYet => '아직 활동 기록이 없습니다';

  @override
  String get habitDetailScreenNoMonthlyDataYet => '아직 월간 데이터가 없습니다';

  @override
  String get habitDetailScreenNotEnoughDataYet => '데이터가 충분하지 않습니다';

  @override
  String habitDetailScreenPartCompactHeroSectionDaysUntilYouBeat(
    Object daysUntilBestStreak,
  ) {
    return '개인 최고 기록을 경신하기까지 $daysUntilBestStreak일 남았습니다!';
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
    return '$year 활동';
  }

  @override
  String habitDetailScreenPartYearlyHeatmapStateValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String get habitDetailScreenRate => '평가';

  @override
  String get habitDetailScreenStreak => '연속 기록';

  @override
  String get habitDetailScreenTotal => '총합';

  @override
  String get habitDetailScreenWeeklyCompletions => '주간 완료 횟수';

  @override
  String get habitDetailSharedSuccessfully => '공유되었습니다!';

  @override
  String get habitProgressHeaderAllDone => '모두 완료!';

  @override
  String habitProgressHeaderComplete(Object percentage) {
    return '$percentage% 완료';
  }

  @override
  String habitProgressHeaderOf(Object total) {
    return '$total 중';
  }

  @override
  String get habitProgressHeaderTodaySHabits => '오늘의 습관';

  @override
  String get habitProgressHeaderYouCompletedAllYour => '오늘의 모든 습관을 완료했습니다!';

  @override
  String get habitTemplatesChooseATemplate => '템플릿 선택';

  @override
  String habitTemplatesSheetTarget(Object suggestedTargetCount, Object unit) {
    return '목표: $suggestedTargetCount $unit';
  }

  @override
  String get habits30DayRate => '30일 달성률';

  @override
  String get habitsAddHabit => '습관 추가';

  @override
  String get habitsBestStreak => '최고 연속 기록';

  @override
  String get habitsCardAddYourFirstHabit => '첫 습관 추가하기';

  @override
  String get habitsCardAllHabitsCompleted => '모든 습관 완료!';

  @override
  String get habitsCardBuildDailyHabits => '매일 습관 만들기';

  @override
  String habitsCardCompletedCount(Object arg0, Object arg1) {
    return '$arg0/$arg1 완료';
  }

  @override
  String habitsCardDayStreak(Object arg0) {
    return '$arg0일 연속';
  }

  @override
  String get habitsCardFailedToLoadHabits => '습관을 불러오지 못했습니다';

  @override
  String get habitsCardGreatJobKeepingUp => '꾸준히 잘하고 있어요';

  @override
  String get habitsCardQuickStart => '빠른 시작:';

  @override
  String get habitsCardStartTrackingDailyHabits =>
      '매일 습관을 기록하여 꾸준함을 기르고 목표를 달성하세요.';

  @override
  String get habitsCardTodaySHabits => '오늘의 습관';

  @override
  String get habitsCardTryAgain => '다시 시도';

  @override
  String get habitsCardU1f525 => '🔥';

  @override
  String habitsCardViewAllHabits(Object arg0) {
    return '습관 $arg0개 모두 보기';
  }

  @override
  String get habitsCompleted => '완료';

  @override
  String get habitsDeleteHabit => '습관을 삭제할까요?';

  @override
  String get habitsHoldToReorderSwipe => '길게 눌러 순서 변경 • 밀어서 삭제';

  @override
  String get habitsLog => '+ 기록';

  @override
  String get habitsLog2 => '기록';

  @override
  String habitsScreenAdded(Object name) {
    return '\"$name\" 추가됨';
  }

  @override
  String habitsScreenDeleted(Object name) {
    return '\"$name\" 삭제됨';
  }

  @override
  String habitsScreenOfDays(Object last30Days) {
    return '30일 중 $last30Days일';
  }

  @override
  String get habitsScreenPartAddHabit => '습관 추가';

  @override
  String get habitsScreenPartCreateCustomHabit => '사용자 지정 습관 만들기';

  @override
  String get habitsScreenPartDefineYourOwnHabit =>
      '이름과 아이콘을 직접 설정하여 나만의 습관을 만드세요';

  @override
  String get habitsScreenPartNoHabitsFound => '습관이 없습니다';

  @override
  String get habitsScreenPartOrChooseATemplate => '또는 템플릿 선택';

  @override
  String get habitsScreenPartSearchHabits => '습관 검색...';

  @override
  String get habitsScreenUiChooseColor => '색상 선택';

  @override
  String get habitsScreenUiChooseIcon => '아이콘 선택';

  @override
  String get habitsScreenUiCreateCustomHabit => '사용자 지정 습관 만들기';

  @override
  String get habitsScreenUiCreateHabit => '습관 만들기';

  @override
  String habitsScreenUiCreated(Object habitName) {
    return '\"$habitName\" 생성 완료';
  }

  @override
  String habitsScreenUiCreatedXpBonus(Object habitName, Object xpAwarded) {
    return '\"$habitName\" 생성 완료! +$xpAwarded XP 보너스';
  }

  @override
  String habitsScreenUiFailedToCreateHabit(Object e) {
    return '습관 생성 실패: $e';
  }

  @override
  String get habitsScreenUiHabitName => '습관 이름';

  @override
  String get habitsScreenUiPleaseEnterAHabit => '습관 이름을 입력해주세요';

  @override
  String get habitsScreenUiPreview => '미리보기';

  @override
  String habitsScreenValue(Object autoPercentage) {
    return '$autoPercentage%';
  }

  @override
  String get habitsTileCardAddHabit => '습관 추가';

  @override
  String get habitsTileCardAllHabitsDoneToday => '오늘의 습관 모두 완료!';

  @override
  String get habitsTileCardBuildHealthyHabits => '건강한 습관 만들기';

  @override
  String get habitsTileCardHabits => '습관';

  @override
  String get habitsTileCardLoadingHabits => '습관 불러오는 중...';

  @override
  String habitsTileCardMore(Object remainingCount) {
    return '+$remainingCount개 더보기';
  }

  @override
  String get habitsTileCardNoHabits => '습관 없음';

  @override
  String get habitsTileCardSignInToTrack => '로그인하여 습관 기록하기';

  @override
  String get habitsTileCardTodaySHabits => '오늘의 습관';

  @override
  String get habitsTodaySProgress => '오늘의 진행 상황';

  @override
  String get habitsViewTrends => '트렌드 보기';

  @override
  String get habitsYourHabits => '나의 습관';

  @override
  String get hapticsHapticFeedback => '햅틱 피드백';

  @override
  String get hapticsHaptics => '햅틱';

  @override
  String get hardPaywallBestStreak => '최고 연속 기록';

  @override
  String get hardPaywallCancelAnytimeInSettings => '설정에서 언제든 취소 가능';

  @override
  String get hardPaywallDonTLoseYour => '진행 상황을 잃지 마세요';

  @override
  String get hardPaywallGet25Off37 => '25% 할인 받기 — 연 \$37.49';

  @override
  String get hardPaywallLbsLifted => 'lbs 들어 올림';

  @override
  String get hardPaywallPurchasesRestored => '구매 항목이 복원되었습니다!';

  @override
  String get hardPaywallRestorePurchases => '구매 복원';

  @override
  String get hardPaywallSignOut => '로그아웃';

  @override
  String get hardPaywallSubscribeNow => '지금 구독하기';

  @override
  String get hardPaywallWelcomeBack => '다시 오신 것을 환영합니다!';

  @override
  String get hardPaywallYourAiCoachRemembers => 'Zealova AI 코치가 모든 것을 기억합니다';

  @override
  String get hardPaywallYourProgressIsStill =>
      '진행 상황은 그대로 유지됩니다. 구독하고 다시 시작하세요.';

  @override
  String get hardPaywallYourTrialHasEnded => '체험 기간이 종료되었습니다';

  @override
  String hashtagFeedScreenNoPostsWith(Object hashtagName) {
    return '#$hashtagName 태그가 포함된 게시물이 없습니다';
  }

  @override
  String hashtagFeedScreenValue(Object hashtagName) {
    return '#$hashtagName';
  }

  @override
  String get healthBreakdownAddedSugar => '첨가당';

  @override
  String get healthBreakdownBloodSugar => '혈당';

  @override
  String get healthBreakdownChronicLowGradeInflammation =>
      '만성 저강도 염증은 관절 건강, 에너지 및 회복에 영향을 미칩니다.';

  @override
  String get healthBreakdownFodmap => 'FODMAP';

  @override
  String get healthBreakdownGlycemicLoadGiCarbs =>
      '혈당 부하(Glycemic Load) = GI × 탄수화물 ÷ 100. 낮을수록 에너지가 안정적이고 혈당 스파이크가 적습니다.';

  @override
  String get healthBreakdownHealthBreakdown => '건강 분석';

  @override
  String get healthBreakdownInflammation => '염증';

  @override
  String get healthBreakdownNoGlycemicLoadComputed =>
      '혈당 부하가 계산되지 않았습니다 (탄수화물이 없는 음식일 가능성이 높습니다).';

  @override
  String get healthBreakdownNotClassifiedForThis => '이 음식에 대해 분류되지 않았습니다.';

  @override
  String get healthBreakdownNotComputedForThis => '이 음식에 대해 계산되지 않았습니다.';

  @override
  String get healthBreakdownNotComputedLikelyNo =>
      '계산되지 않음 — 이 음식에는 첨가당이 없을 가능성이 높습니다.';

  @override
  String get healthBreakdownNovaGroup4Industrial =>
      'NOVA 그룹 4 — 유화제, 액상과당, 인공 감미료 등이 포함된 산업용 가공식품입니다.';

  @override
  String healthBreakdownSheetGl(Object gl) {
    return 'GL $gl';
  }

  @override
  String healthBreakdownSheetTriggers(Object fodmapReason) {
    return '트리거: $fodmapReason';
  }

  @override
  String healthBreakdownSheetValue(Object s) {
    return '$s/10';
  }

  @override
  String get healthBreakdownTapAnyRowFor => '전체 설명, 척도 및 교육 정보를 보려면 행을 탭하세요.';

  @override
  String get healthBreakdownUltraProcessed => '초가공식품';

  @override
  String get healthConnectConnect => '연결';

  @override
  String get healthConnectConnectHealth => '건강 데이터 연결';

  @override
  String get healthConnectConnectedSuccessfully => '연결되었습니다!';

  @override
  String get healthConnectMaybeLater => '나중에 하기';

  @override
  String get healthConnectOnboardingACoachThatSees => '모든 것을 파악하는 코치';

  @override
  String get healthConnectOnboardingHealthConnectIsnT =>
      'Health Connect가 설치되지 않았습니다. 나중에 설정에서 연결하세요.';

  @override
  String get healthConnectOnboardingRecoveryAwareWorkouts => '회복 상태를 고려한 운동';

  @override
  String healthConnectOnboardingScreenConnect(Object _platformName) {
    return '$_platformName 연결';
  }

  @override
  String healthConnectOnboardingScreenConnectSoZealovaCan(
    Object _platformName,
  ) {
    return '$_platformName을(를) 연결하여 Zealova가 귀하의 ';
  }

  @override
  String get healthConnectOnboardingSleepCoaching => '수면 코칭';

  @override
  String get healthConnectOnboardingUnlockYourAiHealth => 'AI 건강 코치 잠금 해제';

  @override
  String get healthConnectSyncYourHealthData =>
      '개인 맞춤형 피트니스 인사이트를 위해 건강 데이터를 동기화하세요';

  @override
  String get healthDevicesHealthDevices => '건강 및 기기';

  @override
  String get healthInsightCardSleep => '수면';

  @override
  String get healthMetricsCardAbove => '초과';

  @override
  String get healthMetricsCardAverage => '평균';

  @override
  String get healthMetricsCardAverageToday => '오늘 평균';

  @override
  String get healthMetricsCardBelow => '미만';

  @override
  String get healthMetricsCardBloodGlucose => '혈당';

  @override
  String get healthMetricsCardBloodGlucoseReadingsWill => '혈당 측정값이 여기에 표시됩니다';

  @override
  String get healthMetricsCardConnectAGlucoseMonitor =>
      'Health Connect를 통해 혈당 측정기 연결';

  @override
  String get healthMetricsCardConnectHealthConnectTo =>
      '혈당을 확인하려면 Health Connect를 연결하세요';

  @override
  String get healthMetricsCardHealthMetrics => '건강 지표';

  @override
  String get healthMetricsCardInRange => '정상 범위';

  @override
  String get healthMetricsCardInsulinDelivery => '인슐린 투여';

  @override
  String get healthMetricsCardInsulinDeliveryData =>
      '연결된 기기의 인슐린 주입 데이터가 여기에 표시됩니다';

  @override
  String get healthMetricsCardLoadingHealthData => '건강 데이터 불러오는 중...';

  @override
  String get healthMetricsCardMax => '최대';

  @override
  String get healthMetricsCardMgDl => 'mg/dL';

  @override
  String get healthMetricsCardMin => '최소';

  @override
  String get healthMetricsCardNoBloodGlucoseReadings => '혈당 측정값 없음';

  @override
  String get healthMetricsCardNoDataForToday => '오늘 데이터 없음';

  @override
  String get healthMetricsCardNoGlucoseData => '혈당 데이터 없음';

  @override
  String get healthMetricsCardNoInsulinData => '인슐린 데이터 없음';

  @override
  String get healthMetricsCardNotEnoughDataFor => '차트를 표시할 데이터가 부족합니다';

  @override
  String healthMetricsCardReadings(Object readingCount) {
    return '측정 기록 $readingCount개';
  }

  @override
  String get healthMetricsCardRecentReadings => '최근 측정값';

  @override
  String get healthMetricsCardTimeInRange => '목표 범위 내 시간';

  @override
  String get healthMetricsCardUnits => '단위';

  @override
  String get healthSyncAiHealthCoachingIs => 'AI 건강 코칭이 켜져 있습니다';

  @override
  String get healthSyncBodyFat => '체지방';

  @override
  String get healthSyncCaloriesBurned => '소모 칼로리';

  @override
  String get healthSyncConnectSamsungHealth => 'Samsung Health 연결';

  @override
  String get healthSyncConnected => '연결됨';

  @override
  String get healthSyncDataToSync => '동기화할 데이터';

  @override
  String get healthSyncEnable => '활성화';

  @override
  String get healthSyncEnableAiHealthCoaching => 'AI 건강 코칭을 활성화할까요?';

  @override
  String get healthSyncEnableAllDataYou =>
      '동기화할 모든 데이터(걸음 수, 심박수, 수면 등)를 활성화하세요';

  @override
  String get healthSyncEnableSync => '동기화 활성화';

  @override
  String get healthSyncFindHealthConnect => 'Health Connect 찾기';

  @override
  String get healthSyncGoToSettingsGear => '설정(톱니바퀴 아이콘)으로 이동';

  @override
  String get healthSyncGotIt => '확인';

  @override
  String get healthSyncGrantPermissions => '권한 허용';

  @override
  String get healthSyncHealthConnectIsNot =>
      'Health Connect를 사용할 수 없습니다. Play 스토어에서 설치해주세요.';

  @override
  String get healthSyncHealthSync => '건강 동기화';

  @override
  String get healthSyncHeartRate => '심박수';

  @override
  String get healthSyncHydration => '수분 섭취';

  @override
  String get healthSyncInstall => '설치';

  @override
  String get healthSyncMealsNutrition => '식사 및 영양';

  @override
  String get healthSyncNotConnected => '연결되지 않음';

  @override
  String get healthSyncNotNow => '나중에';

  @override
  String get healthSyncOk => 'OK';

  @override
  String get healthSyncOpen => '열기';

  @override
  String get healthSyncOpenSamsungHealth => 'Samsung Health 열기';

  @override
  String get healthSyncReturnHereAndToggle => '여기로 돌아와서 Health Connect를 켜세요';

  @override
  String get healthSyncScrollDownAndTap => '아래로 스크롤하여 \"Health Connect\"를 탭하세요';

  @override
  String healthSyncSectionConnect(Object appName) {
    return '$appName 연결';
  }

  @override
  String healthSyncSectionConnectedTo(Object platform) {
    return '$platform에 연결됨';
  }

  @override
  String healthSyncSectionDisconnect(Object platform) {
    return '$platform 연결을 해제할까요?';
  }

  @override
  String healthSyncSectionFindN(Object appName) {
    return '3. \"$appName\" 찾기\n';
  }

  @override
  String healthSyncSectionOpenHealthConnectAnd(Object appName) {
    return 'Health Connect를 열고 $appName에 대한 권한을 부여하세요';
  }

  @override
  String healthSyncSectionSamsungHealthDataSyncs(Object appName) {
    return 'Samsung Health 데이터가 Health Connect를 통해 $appName와 동기화됩니다. 다음 단계를 따르세요:';
  }

  @override
  String healthSyncSectionSyncedHealthDataPoints(Object length) {
    return '$length개의 건강 데이터 포인트 동기화됨';
  }

  @override
  String healthSyncSectionYourSamsungHealthData(Object appName) {
    return '설정 후 Samsung Health 데이터가 $appName에 자동으로 나타납니다.';
  }

  @override
  String get healthSyncSelectDataTypes => '데이터 유형 선택';

  @override
  String get healthSyncSetupGuide => '설정 가이드';

  @override
  String get healthSyncSleep => '수면';

  @override
  String get healthSyncStepsDistance => '걸음 수 및 거리';

  @override
  String get healthSyncSyncNow => '지금 동기화';

  @override
  String get healthSyncTurnOnSyncWith => '\"Health Connect와 동기화\"를 켜세요';

  @override
  String get healthSyncUsingSamsungHealth => 'Samsung Health를 사용 중인가요?';

  @override
  String get healthSyncWeight => '체중';

  @override
  String get healthSyncWriteToHealthApp => '건강 앱에 쓰기';

  @override
  String get hearInsightButtonNoAudioOutputAvailable =>
      '사용 가능한 오디오 출력이 없습니다. 헤드폰을 연결하거나 음소거를 해제하세요.';

  @override
  String get hearInsightButtonStop => '중지';

  @override
  String get hearInsightButtonStopInsightPlayback => '인사이트 재생 중지';

  @override
  String get heartRateChartAddRestingHeartRate => '추정을 위해 안정 시 심박수를 추가하세요';

  @override
  String get heartRateChartAerobic => '유산소';

  @override
  String get heartRateChartAnaerobic => '무산소';

  @override
  String get heartRateChartConnectASmartwatchTo => '심박수를 추적하려면 스마트워치를 연결하세요';

  @override
  String get heartRateChartEstimatedVo2Max => '예상 VO2 Max';

  @override
  String heartRateChartFatBurnMinutes(num minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '지방 연소 구간 $minutes분',
      one: '지방 연소 구간 1분',
    );
    return '$_temp0';
  }

  @override
  String get heartRateChartFatBurning => '지방 연소';

  @override
  String heartRateChartFatCalories(Object calories) {
    return '지방 연소 $calories kcal';
  }

  @override
  String get heartRateChartGotIt => '확인';

  @override
  String get heartRateChartHeartRate => '심박수';

  @override
  String get heartRateChartNoHeartRateData => '심박수 데이터 없음';

  @override
  String heartRateChartPartZoneLegendItemHeartRateOfMax(
    Object percentageRange,
  ) {
    return '심박수: 최대치의 $percentageRange';
  }

  @override
  String heartRateChartPartZoneLegendItemM(
    Object minutes,
    Object percent,
    Object shortLabel,
  ) {
    return '$shortLabel $minutes분 ($percent%)';
  }

  @override
  String heartRateChartPartZoneLegendItemZone(Object name) {
    return '$name 존';
  }

  @override
  String get heartRateChartSummaryAvg => '평균';

  @override
  String heartRateChartSummaryBpm(Object value) {
    return '$value bpm';
  }

  @override
  String get heartRateChartSummaryMax => '최대';

  @override
  String get heartRateChartSummaryMin => '최소';

  @override
  String get heartRateChartSummaryNoDataRecorded => '기록된 데이터 없음';

  @override
  String get heartRateChartSummaryPeak => '피크';

  @override
  String heartRateChartSummaryReadings(Object count) {
    return '측정값 $count개';
  }

  @override
  String get heartRateChartTrainingEffect => '운동 효과';

  @override
  String heartRateChartValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String get heartRateChartWearYourWatchDuring => '심박수를 추적하려면 운동 중에 워치를 착용하세요';

  @override
  String get heartRateChartZoneBreakdown => '구간 분석';

  @override
  String get heartRateDisplayCalculatingZone => '구간 계산 중...';

  @override
  String get heartRateDisplayGotIt => '확인';

  @override
  String heartRateDisplayValue(Object label) {
    return '$label: ';
  }

  @override
  String get heartRateDisplayWaitingForWatch => '워치 연결 대기 중...';

  @override
  String heartRateDisplayZone(Object name) {
    return '$name 존';
  }

  @override
  String heartRateDisplayZone2(Object name) {
    return '$name 존';
  }

  @override
  String get heroActionCardActive => '활동 중';

  @override
  String get heroActionCardCancel => '취소';

  @override
  String get heroActionCardCustom => '직접 입력';

  @override
  String get heroActionCardCustomAmount => '직접 입력';

  @override
  String get heroActionCardEnd => '종료';

  @override
  String get heroActionCardEnter1To5000Ml => '1~5000 ml 입력';

  @override
  String get heroActionCardFailedToLogWater => '물 기록 실패';

  @override
  String get heroActionCardFastEndedSuccessfully => '단식이 성공적으로 종료되었습니다';

  @override
  String get heroActionCardFasting => '단식';

  @override
  String get heroActionCardFastingLabel => '단식';

  @override
  String get heroActionCardLog => '기록';

  @override
  String heroActionCardLogMl(Object ml) {
    return '$ml ml 기록';
  }

  @override
  String get heroActionCardLogWater => '물 기록하기';

  @override
  String get heroActionCardOpenHydrationTracker => '수분 섭취 추적기 열기';

  @override
  String get heroActionCardOrPickAPreset => '또는 프리셋 선택:';

  @override
  String get heroActionCardPleaseLogIn => '로그인해주세요';

  @override
  String get heroActionCardPresetBigBottle => '큰 병';

  @override
  String get heroActionCardPresetGlass => '유리잔';

  @override
  String get heroActionCardPresetLargeJug => '대용량 저그';

  @override
  String get heroActionCardPresetMouthful => '한 입';

  @override
  String get heroActionCardPresetSip => '한 모금';

  @override
  String get heroActionCardPresetSmallCup => '작은 컵';

  @override
  String get heroActionCardPresetSmallSip => '조금씩';

  @override
  String get heroActionCardPresetSportsBottle => '스포츠 보틀';

  @override
  String get heroActionCardPresetTallGlass => '긴 유리잔';

  @override
  String get heroActionCardPresetXlJug => '특대형 저그';

  @override
  String get heroActionCardSelectAmountToLog => '기록할 양 선택';

  @override
  String get heroActionCardSipToXlJug => '한 모금부터 대용량까지';

  @override
  String get heroActionCardTakeProgressPhoto => '변화 과정을 기록하기 위해 사진을 찍어보세요';

  @override
  String get heroActionCardTrackYourProgress => '진척도 기록하기';

  @override
  String get heroActionCardUploadingPhoto => '사진 업로드 중…';

  @override
  String get heroActionCardWaterLabel => '물';

  @override
  String heroActionCardWaterLogged(Object ml) {
    return '$ml ml 기록됨';
  }

  @override
  String get heroFastingCardAutophagy => '오토파지';

  @override
  String get heroFastingCardBurnFat => '지방 연소';

  @override
  String get heroFastingCardEndFast => '단식 종료';

  @override
  String get heroFastingCardEnergy => '에너지';

  @override
  String get heroFastingCardFasting => '단식 중';

  @override
  String heroFastingCardHM(Object hours, Object mins) {
    return '$hours시간 $mins분';
  }

  @override
  String get heroFastingCardNotFasting => '단식 아님';

  @override
  String heroFastingCardOfHGoal(Object targetHours) {
    return '목표 $targetHours시간 중';
  }

  @override
  String heroFastingCardProtocol(Object defaultProtocol) {
    return '$defaultProtocol 프로토콜';
  }

  @override
  String get heroFastingCardReadyToFast => '단식을 시작할까요?';

  @override
  String get heroFastingCardStartFast => '단식 시작';

  @override
  String get heroFastingCardViewDetails => '상세 보기';

  @override
  String get heroNutritionCardCalLeft => '남은 칼로리';

  @override
  String get heroNutritionCardCalOver => '칼로리 초과';

  @override
  String get heroNutritionCardCarbs => '탄수화물';

  @override
  String get heroNutritionCardFat => '지방';

  @override
  String heroNutritionCardGG(Object consumed, Object target) {
    return '${consumed}g / ${target}g';
  }

  @override
  String heroNutritionCardKcal(Object calorieTarget, Object caloriesConsumed) {
    return '$caloriesConsumed / $calorieTarget kcal';
  }

  @override
  String get heroNutritionCardLogMeal => '식단 기록';

  @override
  String get heroNutritionCardProtein => '단백질';

  @override
  String heroNutritionCardValue(Object caloriesRemaining) {
    return '+$caloriesRemaining';
  }

  @override
  String get heroNutritionCardViewDetails => '상세 보기';

  @override
  String get heroWorkoutCardAddExercises => '운동 추가';

  @override
  String get heroWorkoutCardAskCoach => '코치에게 질문하기';

  @override
  String get heroWorkoutCardBodyweightVariant => '맨몸 운동 버전';

  @override
  String get heroWorkoutCardCouldNotDismissWorkout => '운동을 삭제할 수 없습니다';

  @override
  String get heroWorkoutCardCouldNotMarkWorkout => '운동 완료 처리를 할 수 없습니다';

  @override
  String get heroWorkoutCardCouldNotSkipWorkout => '운동 건너뛰기를 할 수 없습니다';

  @override
  String get heroWorkoutCardCouldNotUndoCompletion => '완료 취소를 할 수 없습니다';

  @override
  String get heroWorkoutCardCouldnTRegenerateWorkout =>
      '운동을 다시 생성할 수 없습니다. 다시 시도해 주세요.';

  @override
  String get heroWorkoutCardDelayUntilFastEnds => '단식 종료까지 미루기';

  @override
  String get heroWorkoutCardDismissQuick => 'Quick 삭제';

  @override
  String get heroWorkoutCardDismissQuickWorkout => 'Quick 운동을 삭제할까요?';

  @override
  String get heroWorkoutCardDismissedOfflineWillSync =>
      '오프라인에서 삭제됨 — 온라인 연결 시 동기화됩니다';

  @override
  String get heroWorkoutCardDoToday => '오늘 수행';

  @override
  String get heroWorkoutCardExerciseAdded => '운동이 추가되었습니다!';

  @override
  String heroWorkoutCardExercises(Object exerciseCount) {
    return '운동 $exerciseCount개';
  }

  @override
  String heroWorkoutCardExtExercises(
    Object exerciseCount,
    Object formattedDurationShort,
  ) {
    return '$formattedDurationShort • 운동 $exerciseCount개';
  }

  @override
  String heroWorkoutCardExtMoreExercises(Object exercises) {
    return '+운동 $exercises개 더';
  }

  @override
  String heroWorkoutCardExtSets(Object e) {
    return '$e 세트';
  }

  @override
  String get heroWorkoutCardGlanceWorkout => '운동 미리보기';

  @override
  String get heroWorkoutCardLoadingYourWorkout => '운동 불러오는 중...';

  @override
  String get heroWorkoutCardLogASnack => '간식 기록';

  @override
  String get heroWorkoutCardLogPostWorkoutMeal => '운동 후 식사 기록';

  @override
  String get heroWorkoutCardMarkAsDone => '완료 처리할까요?';

  @override
  String get heroWorkoutCardMarkAsDone2 => '완료 처리';

  @override
  String get heroWorkoutCardMarkDone => '완료';

  @override
  String get heroWorkoutCardMarkedAsARest => '휴식일로 설정되었습니다. 푹 쉬세요.';

  @override
  String get heroWorkoutCardMissedWorkout => '놓친 운동';

  @override
  String heroWorkoutCardModesVariantComingWithThe(Object which) {
    return '백엔드 변형 생성기와 함께 제공되는 $which 변형';
  }

  @override
  String get heroWorkoutCardMoveToToday => '오늘로 이동';

  @override
  String get heroWorkoutCardNothingToShareYet => '공유할 내용이 없습니다 — 먼저 운동을 기록하세요';

  @override
  String heroWorkoutCardPartCompletedWorkoutHeroCardExercises(
    Object exerciseCount,
  ) {
    return '운동 $exerciseCount개';
  }

  @override
  String heroWorkoutCardPartCompletedWorkoutHeroCardMin(
    Object bestDurationMinutes,
  ) {
    return '$bestDurationMinutes분';
  }

  @override
  String get heroWorkoutCardPreview => '미리보기';

  @override
  String get heroWorkoutCardQuick => '빠른 운동';

  @override
  String get heroWorkoutCardQuickWorkout => 'QUICK 운동';

  @override
  String get heroWorkoutCardQuickWorkoutDismissed => 'Quick 운동이 삭제되었습니다';

  @override
  String get heroWorkoutCardRegenerate => '다시 생성';

  @override
  String get heroWorkoutCardRegenerateWorkout => '운동 다시 생성';

  @override
  String get heroWorkoutCardRepeat => '반복';

  @override
  String get heroWorkoutCardResume => '재개';

  @override
  String get heroWorkoutCardResumeNow => '지금 재개';

  @override
  String get heroWorkoutCardSeeTomorrowSPlan => '내일 계획 보기';

  @override
  String get heroWorkoutCardHidePlan => '플랜 숨기기';

  @override
  String get heroWorkoutCardOpenFullPlan => '전체 플랜 보기';

  @override
  String heroWorkoutCardMoreExercises(int count) {
    return '외 $count개';
  }

  @override
  String get heroWorkoutCardShareToSocial => 'SNS에 공유';

  @override
  String get heroWorkoutCardSkipWorkout => '운동을 건너뛸까요?';

  @override
  String get heroWorkoutCardStartAnyway => '그대로 시작';

  @override
  String get heroWorkoutCardStartAsPlanned => '계획대로 시작';

  @override
  String get heroWorkoutCardStartAsPlanned2 => '계획대로 시작';

  @override
  String get heroWorkoutCardStartFasted => '공복 상태로 시작';

  @override
  String get heroWorkoutCardStartLighter => '시작 (가볍게)';

  @override
  String get heroWorkoutCardSummary => '요약';

  @override
  String get heroWorkoutCardSwitchGymProfile => '헬스장 프로필 전환';

  @override
  String get heroWorkoutCardSwitchToLighter => '가볍게 전환';

  @override
  String get heroWorkoutCardSwitchToModerate => '보통으로 전환';

  @override
  String get heroWorkoutCardTakeRest => '휴식';

  @override
  String get heroWorkoutCardTapToRetry => '탭하여 재시도';

  @override
  String get heroWorkoutCardThisMayTakeA => '잠시 시간이 걸릴 수 있습니다';

  @override
  String get heroWorkoutCardThisWillMarkThe => '운동이 미완료 상태로 표시됩니다.';

  @override
  String get heroWorkoutCardThisWorkoutWillBe => '이 운동은 건너뛴 것으로 표시됩니다.';

  @override
  String get heroWorkoutCardTodaySWorkoutComplete => '오늘의 운동 완료!';

  @override
  String get heroWorkoutCardUndo => '취소';

  @override
  String get heroWorkoutCardUndoCompletion => '완료를 취소할까요?';

  @override
  String get heroWorkoutCardViewDetails => '상세 보기';

  @override
  String get heroWorkoutCardViewWorkout => '운동 보기';

  @override
  String heroWorkoutCardWorkout(Object id) {
    return '/workout/$id';
  }

  @override
  String get heroWorkoutCardWorkoutIsNotReady =>
      '운동이 아직 준비되지 않았습니다. 다시 생성해 보세요.';

  @override
  String get heroWorkoutCardWorkoutMarkedAsDone => '운동이 완료 처리되었습니다!';

  @override
  String get heroWorkoutCardWorkoutRegenerated => '운동이 다시 생성되었습니다!';

  @override
  String get heroWorkoutCardWorkoutSkipped => '운동이 건너뛰기 처리되었습니다';

  @override
  String get heroWorkoutCardWorkoutUnmarked => '운동 완료가 취소되었습니다';

  @override
  String get heroWorkoutCardYouLlLoseThis =>
      '이 Quick 운동이 삭제됩니다. 기록된 세트가 있다면 모두 사라집니다. 계속할까요?';

  @override
  String get heroWorkoutCarouselAllDoneForThis => '이번 주 운동 완료!';

  @override
  String get heroWorkoutCarouselCouldNotLoadWorkouts => '운동을 불러올 수 없습니다';

  @override
  String get heroWorkoutCarouselGeneratingWorkout => '운동 생성 중...';

  @override
  String get heroWorkoutCarouselNoWorkoutYet => '아직 운동 없음';

  @override
  String get heroWorkoutCarouselRestUpForNext => '다음 주를 위해 휴식하세요';

  @override
  String get heroWorkoutCarouselSetYourWorkoutDays => '운동 요일 설정';

  @override
  String get heroWorkoutCarouselSettingUpYourWorkout => '운동 설정 중...';

  @override
  String get heroWorkoutCarouselTapToSetUp => '탭하여 설정에서 구성하세요';

  @override
  String get heroWorkoutCarouselToday => '오늘';

  @override
  String holdToConfirmButtonPressAndHoldTo(Object label) {
    return '$label. 길게 눌러 확인하세요.';
  }

  @override
  String get homeApply => '적용';

  @override
  String get homeCustomizeYourHomeLayout =>
      '홈 레이아웃을 사용자 지정하고, 헬스장 프로필을 전환하고, 레벨을 확인하세요 — 모두 여기서 가능합니다.';

  @override
  String get homeDailyStepsGoal => '일일 걸음 수 목표';

  @override
  String get homeDefaultLayoutRestored => '기본 레이아웃으로 복원되었습니다!';

  @override
  String get homeEmptyAchievements_v1 => '아직 달성한 업적이 없어요. 계속 훈련해서 잠금을 해제하세요.';

  @override
  String get homeEmptyAchievements_v2 => '마일스톤을 달성하면 업적이 해제됩니다. 계속 나아가세요.';

  @override
  String get homeEmptyAchievements_v3 => '아직 잠금 해제된 것이 없네요. 첫 번째 업적이 머지않았어요.';

  @override
  String get homeEmptyAchievements_v4 => '운동을 기록하기 시작하면 업적도 따라올 거예요.';

  @override
  String get homeEmptyChallenges_v1 => '진행 중인 챌린지가 없어요. 둘러보고 하나를 선택해 시작하세요.';

  @override
  String get homeEmptyChallenges_v2 => '챌린지는 동기부여에 최고예요. 하나 참여해 보세요.';

  @override
  String get homeEmptyChallenges_v3 =>
      '아직 진행 중인 것이 없네요. 당신의 레벨에 맞는 챌린지를 찾아보세요.';

  @override
  String get homeEmptyChallenges_v4 => '챌린지가 없나요? 당신을 기다리는 좋은 챌린지들이 많아요.';

  @override
  String get homeEmptyChat_v1 => '아직 메시지가 없어요. 코치에게 무엇이든 물어보세요.';

  @override
  String get homeEmptyChat_v2 => '코치가 준비되었습니다. 궁금한 점이 있으신가요?';

  @override
  String get homeEmptyChat_v3 => '채팅이 비어있네요. 질문을 남기거나 기분을 공유해 보세요.';

  @override
  String get homeEmptyChat_v4 => '첫 대화는 여기서 시작됩니다. 인사해 보세요.';

  @override
  String get homeEmptyCustomExercises_v1 =>
      '아직 맞춤형 운동이 없습니다. 직접 만들어 운동에 추가해보세요.';

  @override
  String get homeEmptyCustomExercises_v2 =>
      '맞춤형 운동 라이브러리가 비어 있습니다. 첫 번째 운동을 만들어보세요.';

  @override
  String get homeEmptyCustomExercises_v3 =>
      '아직 아무것도 없습니다. 기본 라이브러리에 없는 운동을 추가해보세요.';

  @override
  String get homeEmptyCustomExercises_v4 =>
      '맞춤형 운동이 없습니다. 하나를 만들면 검색 결과에 나타납니다.';

  @override
  String get homeEmptyFasting_v1 => '시작된 단식 세션이 없습니다. 프로토콜을 선택하여 시작하세요.';

  @override
  String get homeEmptyFasting_v2 => '단식 추적기가 비어 있습니다. 준비되면 세션을 시작하세요.';

  @override
  String get homeEmptyFasting_v3 => '아직 기록된 내용이 없습니다. 시간대를 선택하고 타이머를 시작하세요.';

  @override
  String get homeEmptyFasting_v4 => '단식 데이터가 없습니다. 탭하여 첫 번째 세션을 시작하세요.';

  @override
  String get homeEmptyFavorites_v1 => '아직 즐겨찾기가 없어요. 운동이나 루틴에 하트를 눌러 저장하세요.';

  @override
  String get homeEmptyFavorites_v2 => '저장된 항목이 없네요. 마음에 드는 것을 찾아 보관해 보세요.';

  @override
  String get homeEmptyFavorites_v3 => '즐겨찾기 목록이 기다리고 있어요. 탐색하고 북마크해 보세요.';

  @override
  String get homeEmptyFavorites_v4 => '운동 옆의 하트를 탭하여 여기에 추가하세요.';

  @override
  String get homeEmptyFriends_v1 => '아직 연결된 친구가 없습니다. 친구를 초대해 함께 운동하세요.';

  @override
  String get homeEmptyFriends_v2 => '친구 목록이 비어 있습니다. 서로의 운동을 독려해보세요.';

  @override
  String get homeEmptyFriends_v3 => '아직 아무도 없습니다. 링크를 공유하여 친구를 늘려보세요.';

  @override
  String get homeEmptyFriends_v4 =>
      '추가된 친구가 없습니다. 누군가와 함께 운동하면 큰 도움이 됩니다. 친구를 추가해보세요.';

  @override
  String get homeEmptyGymProfiles_v1 =>
      '헬스장 프로필이 없습니다. 장비를 추가하여 운동을 설정에 맞게 조정하세요.';

  @override
  String get homeEmptyGymProfiles_v2 =>
      '헬스장 프로필이 비어 있습니다. 장비를 한 번만 알려주시면 매번 반영해 드립니다.';

  @override
  String get homeEmptyGymProfiles_v3 =>
      '저장된 설정이 없습니다. 헬스장 프로필을 추가하여 맞춤형 운동을 받아보세요.';

  @override
  String get homeEmptyGymProfiles_v4 =>
      '프로필이 비어 있습니다. 장비를 구성하면 나머지는 AI가 알아서 처리합니다.';

  @override
  String get homeEmptyHabits_v1 => '설정된 습관이 없습니다. 작은 일일 습관 하나를 추가하여 시작해보세요.';

  @override
  String get homeEmptyHabits_v2 => '습관 추적기가 비어 있습니다. 습관 하나를 만들어 자동화해보세요.';

  @override
  String get homeEmptyHabits_v3 => '아직 추적 중인 내용이 없습니다. 매일 할 수 있는 습관 하나로 시작하세요.';

  @override
  String get homeEmptyHabits_v4 => '활성화된 습관이 없습니다. 작은 일일 행동이 모여 큰 결과를 만듭니다.';

  @override
  String get homeEmptyHistory_v1 => '아직 운동 기록이 없어요. 하나를 완료하고 기록을 시작하세요.';

  @override
  String get homeEmptyHistory_v2 => '기록이 비어있네요. 첫 세션을 마치면 채워질 거예요.';

  @override
  String get homeEmptyHistory_v3 => '과거 운동 기록이 없어요. 하나를 완료하면 여기에 나타날 거예요.';

  @override
  String get homeEmptyHistory_v4 => '기록이 비어있다는 건 이제 시작이라는 뜻이죠. 멋진 기록을 만들어 보세요.';

  @override
  String get homeEmptyJournal_v1 => '저널 항목이 없습니다. 작더라도 오늘의 성취를 기록해보세요.';

  @override
  String get homeEmptyJournal_v2 =>
      '저널이 비어 있습니다. 여정을 기록해보세요. 나중에 큰 도움이 될 것입니다.';

  @override
  String get homeEmptyJournal_v3 => '아직 작성된 내용이 없습니다. 첫 번째 기록을 여기서 시작하세요.';

  @override
  String get homeEmptyJournal_v4 => '항목이 없습니다. 2분만 투자해서 솔직한 기록을 남겨보세요.';

  @override
  String get homeEmptyMeasurements_v1 =>
      '측정값이 기록되지 않았어요. 기준값을 추가하여 진행 상황을 추적하세요.';

  @override
  String get homeEmptyMeasurements_v2 => '아직 기록된 것이 없네요. 현재 수치부터 시작해 보세요.';

  @override
  String get homeEmptyMeasurements_v3 => '신체 데이터가 없어요. 측정값을 기록하여 변화 추이를 확인하세요.';

  @override
  String get homeEmptyMeasurements_v4 => '측정값이 비어있어요. 기록을 추가하여 깨야 할 목표를 만드세요.';

  @override
  String get homeEmptyMood_v1 => '기분 기록이 없어요. 오늘 기분은 어떠신가요?';

  @override
  String get homeEmptyMood_v2 => '기분 추적이 비어있네요. 다음 운동 후 기분을 기록해 보세요.';

  @override
  String get homeEmptyMood_v3 => '아직 기록이 없네요. 기분 패턴은 최고의 훈련 날을 예측하는 데 도움이 됩니다.';

  @override
  String get homeEmptyMood_v4 => '기분 데이터가 없어요. 탭하여 오늘 기록을 추가하세요.';

  @override
  String get homeEmptyNutrition_v1 => '아직 기록된 식단이 없어요. 사진을 찍어 시작해 보세요.';

  @override
  String get homeEmptyNutrition_v2 => '식단 기록이 비어있네요. 첫 번째 식사는 무엇인가요?';

  @override
  String get homeEmptyNutrition_v3 => '오늘 기록된 식사가 없어요. 식단을 기록하고 매크로를 확인하세요.';

  @override
  String get homeEmptyNutrition_v4 => '식사 중이신가요? 사진을 찍어주시면 수치는 저희가 계산할게요.';

  @override
  String get homeEmptyPhotos_v1 => '진행 상황 사진이 없어요. 오늘 첫 번째 사진을 찍어보세요.';

  @override
  String get homeEmptyPhotos_v2 => '사진은 숫자가 말해주지 못하는 이야기를 담고 있어요. 지금 찍어보세요.';

  @override
  String get homeEmptyPhotos_v3 => '아직 아무것도 없네요. 시각적인 변화 기록을 시작해 보세요.';

  @override
  String get homeEmptyPhotos_v4 => '사진 기록이 없어요. 하나를 추가하여 시간의 흐름에 따른 변화를 추적하세요.';

  @override
  String get homeEmptyPlans_v1 =>
      '아직 계획이 없습니다. AI가 당신의 일정과 목표에 맞춰 계획을 세우게 하세요.';

  @override
  String get homeEmptyPlans_v2 => '계획이 비어 있습니다. 맞춤형 훈련 계획을 생성하여 시작해보세요.';

  @override
  String get homeEmptyPlans_v3 => '아직 설정된 내용이 없습니다. 계획을 세우고 꾸준히 실천해보세요.';

  @override
  String get homeEmptyPlans_v4 =>
      '활성화된 계획이 없습니다. 계획을 시작하여 매일 무엇을 할지 고민하는 시간을 줄이세요.';

  @override
  String get homeEmptyPrograms_v1 =>
      '활성화된 프로그램이 없습니다. 프로그램을 둘러보고 다음 목표를 찾아보세요.';

  @override
  String get homeEmptyPrograms_v2 => '프로그램은 훈련에 체계를 더해줍니다. 하나를 선택해 시작해보세요.';

  @override
  String get homeEmptyPrograms_v3 =>
      '아직 진행 중인 내용이 없습니다. 프로그램을 시작하여 주간 계획을 잠금 해제하세요.';

  @override
  String get homeEmptyPrograms_v4 => '활성화된 프로그램이 없습니다. 현재 상태에 맞는 프로그램을 선택하세요.';

  @override
  String get homeEmptyRecipes_v1 => '아직 레시피가 없어요. 라이브러리를 둘러보거나 코치에게 물어보세요.';

  @override
  String get homeEmptyRecipes_v2 => '레시피 보관함이 비어있네요. 좋아하는 식단을 추가해 보세요.';

  @override
  String get homeEmptyRecipes_v3 => '저장된 항목이 없네요. 마음에 드는 레시피를 찾아 저장해 보세요.';

  @override
  String get homeEmptyRecipes_v4 => '레시피 라이브러리가 비어있어요. 탭하여 새로운 식단을 발견하세요.';

  @override
  String get homeEmptyRecovery_v1 =>
      '회복 데이터가 없습니다. 수면, HRV 또는 근육통을 기록하여 점수를 확인하세요.';

  @override
  String get homeEmptyRecovery_v2 =>
      '회복 추적기가 비어 있습니다. 웨어러블 기기를 연결하거나 직접 기록하세요.';

  @override
  String get homeEmptyRecovery_v3 =>
      '아직 추적 중인 내용이 없습니다. 회복 데이터는 더 스마트하게 훈련하는 데 도움이 됩니다.';

  @override
  String get homeEmptyRecovery_v4 =>
      '회복 데이터가 비어 있습니다. 오늘의 데이터를 추가하여 다음 세션을 준비하세요.';

  @override
  String get homeEmptyScores_v1 => '아직 점수가 없습니다. 운동을 기록하여 첫 번째 준비도 점수를 생성하세요.';

  @override
  String get homeEmptyScores_v2 => '점수는 데이터를 기록하기 시작하면 나타납니다. 꾸준히 기록해보세요.';

  @override
  String get homeEmptyScores_v3 =>
      '아직 점수가 매겨지지 않았습니다. 세션을 완료하여 첫 번째 평가를 확인하세요.';

  @override
  String get homeEmptyScores_v4 =>
      '점수가 비어 있습니다. 데이터가 많을수록 더 정확한 통찰력을 얻을 수 있습니다. 기록을 시작하세요.';

  @override
  String get homeEmptySleep_v1 => '수면 데이터가 없어요. 웨어러블을 연결하거나 수동으로 기록하세요.';

  @override
  String get homeEmptySleep_v2 => '수면 추적이 비어있네요. 회복은 수면을 파악하는 것부터 시작됩니다.';

  @override
  String get homeEmptySleep_v3 => '수면 기록이 없어요. 어젯밤 데이터를 추가하여 회복 추이를 확인하세요.';

  @override
  String get homeEmptySleep_v4 => '수면 데이터가 부족해요. 기록해 주시면 회복 점수에 반영해 드릴게요.';

  @override
  String get homeEmptyTrends_v1 => '아직 트렌드가 없습니다. 7일 동안 꾸준히 기록하여 패턴을 확인해보세요.';

  @override
  String get homeEmptyTrends_v2 =>
      '트렌드를 보려면 데이터가 필요합니다. 계속 기록하면 그래프가 채워질 것입니다.';

  @override
  String get homeEmptyTrends_v3 => '아직 보여줄 내용이 없습니다. 일주일간 추적한 후 다시 확인해보세요.';

  @override
  String get homeEmptyTrends_v4 => '트렌드 보기가 비어 있습니다. 꾸준함이 핵심입니다. 매일 기록을 시작하세요.';

  @override
  String get homeEmptyVitals_v1 => '기록된 활력 징후가 없습니다. 웨어러블 기기를 연결하거나 직접 입력하세요.';

  @override
  String get homeEmptyVitals_v2 => '활력 징후 추적기가 비어 있습니다. 데이터 포인트를 추가하여 시작하세요.';

  @override
  String get homeEmptyVitals_v3 => '아직 아무것도 없습니다. 안정 시 심박수, HRV 또는 혈압을 기록해보세요.';

  @override
  String get homeEmptyVitals_v4 => '활력 징후 데이터가 없습니다. 웨어러블 기기를 연결하여 자동 동기화하세요.';

  @override
  String get homeEmptyWater_v1 => '오늘 물을 기록하지 않았어요. 첫 잔을 마시고 기록하세요.';

  @override
  String get homeEmptyWater_v2 => '수분 섭취 추적이 비어있네요. 첫 컵을 기록하세요.';

  @override
  String get homeEmptyWater_v3 => '아직 기록이 없네요. 오늘 하루 수분 섭취를 시작해 보세요.';

  @override
  String get homeEmptyWater_v4 => '수분 섭취 기록이 없습니다. 갈증을 느끼기 전에 지금 기록하세요.';

  @override
  String get homeEmptyWorkout_v1 => '아직 운동 기록이 없어요. 탭하여 오늘의 세션을 생성하세요.';

  @override
  String get homeEmptyWorkout_v2 => '휴식일인가요? 아니면 운동할 준비가 되셨나요? 선택은 당신의 몫입니다.';

  @override
  String get homeEmptyWorkout_v3 => '프로그램 사이의 휴식기인가요? 새 프로그램을 시작해 다시 궤도에 오르세요.';

  @override
  String get homeEmptyWorkout_v4 => '아직 계획이 없네요. AI가 당신의 목표에 맞춰 계획을 짜드릴게요.';

  @override
  String homeGreetingAfternoon_v1(Object name) {
    return '오후의 활력, $name님!';
  }

  @override
  String homeGreetingAfternoon_v2(Object name) {
    return '$name님, 이제 움직여 볼까요?';
  }

  @override
  String homeGreetingAfternoon_v3(Object name) {
    return '$name님, 스트레칭 한 번 할까요?';
  }

  @override
  String homeGreetingAfternoon_v4(Object name) {
    return '$name님, 오늘 하루 어떠신가요?';
  }

  @override
  String homeGreetingAfternoon_v5(Object name) {
    return '좋은 오후입니다, $name님';
  }

  @override
  String homeGreetingEvening_v1(Object name) {
    return '휴식이 필요한 시간이에요, $name님';
  }

  @override
  String homeGreetingEvening_v2(Object name) {
    return '저녁이네요, $name님';
  }

  @override
  String homeGreetingEvening_v3(Object name) {
    return '오늘 하루를 멋지게 마무리해요, $name님';
  }

  @override
  String homeGreetingEvening_v4(Object name) {
    return '$name님, 마지막 랩인가요?';
  }

  @override
  String homeGreetingEvening_v5(Object name) {
    return '오늘을 되돌아보는 시간, $name님';
  }

  @override
  String homeGreetingMidday_v1(Object name) {
    return '점심 시간인가요, $name님?';
  }

  @override
  String homeGreetingMidday_v2(Object name) {
    return '오후 점검 시간입니다, $name님.';
  }

  @override
  String homeGreetingMidday_v3(Object name) {
    return '$name님, 벌써 절반이나 왔어요';
  }

  @override
  String homeGreetingMidday_v4(Object name) {
    return '$name님, 힘내고 계신가요?';
  }

  @override
  String homeGreetingMidday_v5(Object name) {
    return '$name님, 오늘 아주 강렬한 하루네요';
  }

  @override
  String homeGreetingMorning_v1(Object name) {
    return '좋은 아침이에요, $name님!';
  }

  @override
  String homeGreetingMorning_v2(Object name) {
    return '$name님, 오늘도 힘차게 시작해 볼까요?';
  }

  @override
  String homeGreetingMorning_v3(Object name) {
    return '좋은 아침입니다, $name님.';
  }

  @override
  String homeGreetingMorning_v4(Object name) {
    return '일찍 일어나셨네요, $name님?';
  }

  @override
  String homeGreetingMorning_v5(Object name) {
    return '다시 오신 것을 환영합니다, $name님.';
  }

  @override
  String get homeLogMeal => '식사 기록';

  @override
  String get homeMore => '더 보기';

  @override
  String get homeMySpaceApply => '적용';

  @override
  String get homeMySpaceCurrentLayout => '● 현재 레이아웃';

  @override
  String get homeMySpaceMySpace => '마이 스페이스';

  @override
  String get homeMySpaceReset => '초기화';

  @override
  String homeMySpaceScreenLayoutApplied(Object name) {
    return '$name 레이아웃 적용됨';
  }

  @override
  String get homeMySpaceStartFromAReady =>
      '준비된 레이아웃으로 시작한 후, 사용자 지정에서 세부 조정하세요.';

  @override
  String get homeQuickActions => '빠른 작업';

  @override
  String get homeQuickWorkoutGenerationWeig =>
      '빠른 운동 생성, 체중 기록, 식단 기록 등을 이용하세요.';

  @override
  String get homeReadinessCardCheckIn => '체크인';

  @override
  String homeReadinessCardEstimated(Object label) {
    return '예상: $label';
  }

  @override
  String get homeReadinessCardHowAreYouFeeling => '오늘 컨디션은 어떠신가요?';

  @override
  String get homeReadinessCardTodaySReadiness => '오늘의 컨디션';

  @override
  String get homeReset => '초기화';

  @override
  String get homeResetToDefault => '기본값으로 초기화할까요?';

  @override
  String get homeScanFood => '음식 스캔';

  @override
  String get homeScanMealsWithYour => '카메라로 식단을 스캔하세요. 매크로를 쉽게 추적할 수 있습니다.';

  @override
  String get homeScreenApply => '적용';

  @override
  String homeScreenApplyPreset(Object name) {
    return '\"$name\"을(를) 적용할까요?';
  }

  @override
  String homeScreenApplyPresetBody(Object name) {
    return '현재 레이아웃이 \"$name\" 프리셋으로 대체됩니다.';
  }

  @override
  String get homeScreenCancel => '취소';

  @override
  String get homeScreenDailyStepsGoal => '일일 걸음 수 목표';

  @override
  String get homeScreenDefaultRestored => '기본 레이아웃 복원됨';

  @override
  String homeScreenImportedWorkouts(Object count) {
    return '$count개의 운동 가져옴';
  }

  @override
  String homeScreenPresetApplied(Object name) {
    return '\"$name\" 적용됨';
  }

  @override
  String get homeScreenReset => '초기화';

  @override
  String get homeScreenResetToDefault => '기본값으로 초기화할까요?';

  @override
  String get homeScreenResetToDefaultBody => '홈 화면을 기본 레이아웃으로 복원합니다.';

  @override
  String get homeScreenTourCarouselDesc => '스와이프하여 운동 계획을 확인하세요. 탭하면 시작합니다!';

  @override
  String get homeScreenTourCarouselTitle => '오늘의 운동';

  @override
  String get homeScreenTourNutritionDesc => '매크로와 일일 영양 섭취량을 추적하세요';

  @override
  String get homeScreenTourNutritionTitle => '영양 탭';

  @override
  String get homeScreenTourProfileDesc => '진행 상황과 설정을 확인하세요';

  @override
  String get homeScreenTourProfileTitle => '프로필 탭';

  @override
  String get homeScreenTourQuicklogDesc => '식단, 물, 운동을 빠르게 기록하세요';

  @override
  String get homeScreenTourQuicklogTitle => '빠른 기록';

  @override
  String get homeScreenTourTopbarDesc => '탭하여 피트니스 프로필을 확인하고 수정하세요';

  @override
  String get homeScreenTourTopbarTitle => '내 프로필';

  @override
  String get homeScreenTourWorkoutDesc => '전체 운동 계획과 기록을 확인하세요';

  @override
  String get homeScreenTourWorkoutTitle => '운동 탭';

  @override
  String homeScreenUi1MoreTiles(Object tiles) {
    return '+$tiles개의 타일 더 보기';
  }

  @override
  String homeScreenUi1Workouts(Object length) {
    return '운동 $length회';
  }

  @override
  String homeScreenUi2TryAgainInS(Object cooldownLeft) {
    return '$cooldownLeft초 후 다시 시도하세요';
  }

  @override
  String homeScreenUi3Workouts(Object length) {
    return '운동 $length회';
  }

  @override
  String get homeScreenUiAddTile => '타일 추가';

  @override
  String get homeScreenUiChooseAPresetLayout =>
      '원하는 목표에 맞는 프리셋 레이아웃을 선택하세요. 적용 후 추가로 사용자 지정할 수 있습니다.';

  @override
  String get homeScreenUiCustomizeYourDashboard => '대시보드 사용자 지정';

  @override
  String get homeScreenUiDiscoverLayouts => '레이아웃 탐색';

  @override
  String get homeScreenUiDragToReorderTap =>
      '드래그하여 순서 변경 • 크기 탭하여 조정 • 눈 아이콘 탭하여 숨기기';

  @override
  String get homeScreenUiGotIt => '확인했습니다!';

  @override
  String get homeScreenUiResetToDefault => '기본값으로 초기화';

  @override
  String homeScreenUiRestoreTheOriginalLayout(Object appName) {
    return '기본 $appName 레이아웃으로 복원';
  }

  @override
  String get homeScreenUiUpcoming => '예정된 일정';

  @override
  String get homeScreenUiYourProgress => '나의 진행 상황';

  @override
  String get homeScreenUiYourWeek => '이번 주';

  @override
  String get homeStartWorkout => '운동 시작';

  @override
  String get homeStreak100Day_v1 => '100일. 정말 멋진 성과를 만드셨네요.';

  @override
  String get homeStreak100Day_v2 => '세 자릿수 달성. 한 번도 빠짐없네요.';

  @override
  String get homeStreak100Day_v3 => '100일 연속 달성! 엘리트급 헌신입니다.';

  @override
  String get homeStreak100Day_v4 => '100일 기록 완료. 멈출 수 없겠네요.';

  @override
  String get homeStreak30Day_v1 => '30일. 한 달 동안 꾸준히 해내셨네요.';

  @override
  String get homeStreak30Day_v2 => '한 달 달성. 이제 완벽한 습관이 되었네요.';

  @override
  String get homeStreak30Day_v3 => '30일 연속 달성! 대부분은 이전에 포기하지만, 당신은 해냈습니다.';

  @override
  String get homeStreak30Day_v4 => '한 달간의 꾸준함. 정말 대단합니다.';

  @override
  String get homeStreak365Day_v1 => '365일. 1년 내내 함께했네요.';

  @override
  String get homeStreak365Day_v2 => '1년 연속 달성. 전설적인 기록이에요.';

  @override
  String get homeStreak365Day_v3 => '365일 연속 달성. 1년을 꽉 채웠네요.';

  @override
  String get homeStreak365Day_v4 => '1년 달성. 꾸준함의 새로운 기준을 세우셨어요.';

  @override
  String get homeStreak7Day_v1 => '7일 연속 달성 — 완벽해요!';

  @override
  String get homeStreak7Day_v2 => '7일째. 흐름이 아주 좋아요.';

  @override
  String get homeStreak7Day_v3 => '일주일 연속 달성! 기록을 더 쌓아보세요.';

  @override
  String get homeStreak7Day_v4 => '7일 연속 달성. 이 열정을 계속 유지하세요.';

  @override
  String get homeSwipeToSeeThis => '스와이프하여 이번 주 계획을 확인하세요. 탭하면 오늘의 운동이 시작됩니다.';

  @override
  String get homeThisWillRestoreThe =>
      'Minimalist 레이아웃(앱 기본값)으로 복원됩니다. 현재 설정한 사용자 지정 내용은 삭제됩니다.';

  @override
  String get homeTimelineCouldnTLoadYour => '타임라인을 불러올 수 없습니다';

  @override
  String homeTimelineElapsed(Object elapsedTimeString) {
    return '$elapsedTimeString 경과';
  }

  @override
  String get homeTimelineFastingWindow => '단식 시간';

  @override
  String get homeTimelineGeneratingYourWorkout => '운동 생성 중...';

  @override
  String get homeTimelineHangTightAlmostReady => '잠시만 기다려 주세요, 거의 준비되었습니다';

  @override
  String homeTimelineLeft(Object remainingTimeString) {
    return '$remainingTimeString 남음 · ';
  }

  @override
  String get homeTimelineLogYourMeals => '식단 기록하기';

  @override
  String get homeTimelineNothingLoggedOrPlanned => '기록되거나 계획된 항목이 없습니다';

  @override
  String get homeTimelineNothingLoggedYetToday => '오늘 기록된 내용이 없습니다';

  @override
  String get homeTimelineNothingPlannedForThis => '이 날짜에 계획된 일정이 없습니다';

  @override
  String homeTimelineProtocolNotStarted(Object defaultProtocol) {
    return '$defaultProtocol 프로토콜 · 시작 전';
  }

  @override
  String get homeTip_ankle_mobility =>
      '발목 가동성이 부족하면 스쿼트 시 보상 작용이 일어납니다. 매일 스트레칭하고 훈련하세요.';

  @override
  String get homeTip_breathing_during_lifts =>
      '힘든 부분에서 숨을 내뱉고, 쉬운 부분에서 들이마시세요. 운동 내내 코어에 힘을 주세요.';

  @override
  String get homeTip_caffeine_timing =>
      '카페인은 섭취 후 45~60분 뒤에 효과가 최고조에 달합니다. 운동 전에 맞춰 섭취하세요.';

  @override
  String get homeTip_cardio_and_strength =>
      '충분한 영양을 섭취하고 과도하게 하지 않는다면 유산소 운동이 근성장을 방해하지 않습니다.';

  @override
  String get homeTip_cold_exposure =>
      '찬물 샤워나 얼음물 목욕은 운동 후 염증을 줄여줄 수 있습니다. 운동 전이 아닌 후에 하세요.';

  @override
  String get homeTip_compound_before_isolation =>
      '컨디션이 좋을 때 복합 다관절 운동부터 하세요. 고립 운동은 마지막에 배치합니다.';

  @override
  String get homeTip_compound_lifts =>
      '스쿼트, 힌지, 푸시, 풀, 캐리. 이 다섯 가지만 마스터해도 80%는 해결됩니다.';

  @override
  String get homeTip_consistency_beats_perfection =>
      '100%를 할 수 없다고 포기하는 것보다 70%라도 꾸준히 하는 것이 훨씬 낫습니다.';

  @override
  String get homeTip_core_in_every_lift =>
      '모든 복합 운동에서 코어는 작동합니다. 20분 동안 크런치만 할 필요는 없습니다.';

  @override
  String get homeTip_creatine_basics =>
      '크레아틴 모노하이드레이트는 스포츠 과학에서 가장 많이 연구된 보충제입니다. 매일 3~5g이면 충분합니다.';

  @override
  String get homeTip_deload_week => '4~6주마다 운동량을 40% 줄이세요. 몸이 더 강해져서 돌아올 것입니다.';

  @override
  String get homeTip_eat_before_training =>
      '공복 운동도 효과가 있지만, 운동 60~90분 전 가벼운 식사는 운동 수행 능력을 높여줍니다.';

  @override
  String get homeTip_eccentric_focus =>
      '근육 손상(및 성장)의 대부분은 무게를 내리는 단계에서 일어납니다. 이 과정을 통제하세요.';

  @override
  String get homeTip_fiber_and_gut =>
      '하루 30g의 식이섬유는 에너지를 일정하게 유지하고 식탐을 줄여줍니다. 대부분은 15g 정도만 섭취합니다.';

  @override
  String get homeTip_form_over_weight =>
      '잘못된 자세로 무리하게 드는 무게는 근육이 아닌 부상을 키웁니다. 먼저 정확한 동작을 익히세요.';

  @override
  String get homeTip_grip_strength => '악력은 다른 어떤 지표보다 장수를 잘 예측합니다. 꾸준히 단련하세요.';

  @override
  String get homeTip_hydration_basics =>
      '매일 체중(온스 기준)의 절반만큼 물을 마시세요. 운동하는 날에는 더 많이 마셔야 합니다.';

  @override
  String get homeTip_meal_timing_simple =>
      '자연식 위주로 식사하고, 단백질을 챙기며, 충분히 주무세요. 나머지는 부차적인 요소일 뿐입니다.';

  @override
  String get homeTip_mind_muscle_connection =>
      '천천히 움직이며 근육의 움직임에 집중하세요. 단순히 무게를 옮기는 것이 전부가 아닙니다.';

  @override
  String get homeTip_mobility_daily =>
      '매주 한 번 60분 운동하는 것보다 매일 10분씩 가동성 훈련을 하는 것이 훨씬 효과적입니다.';

  @override
  String get homeTip_no_junk_volume =>
      '설렁설렁하는 20세트보다 집중해서 하는 10세트가 낫습니다. 양보다 질이 중요합니다.';

  @override
  String get homeTip_omega3_basics =>
      '매일 1~2g의 EPA+DHA 섭취는 염증을 줄이고 관절 건강을 돕습니다.';

  @override
  String get homeTip_periodization =>
      '시간이 지남에 따라 반복 횟수와 강도를 변화시키세요. 선형적인 성장은 영원하지 않습니다.';

  @override
  String get homeTip_progressive_overload =>
      '매주 무게를 조금씩 늘리거나 횟수를 한 번 더 해보세요. 그것이 성장의 비결입니다.';

  @override
  String get homeTip_protein_per_meal =>
      '끼니당 30~40g의 단백질 섭취를 목표로 하세요. 한 번에 몰아 먹는 것보다 나누어 먹는 것이 좋습니다.';

  @override
  String get homeTip_protein_sources_vary =>
      '닭고기, 달걀, 그릭 요거트, 콩류 등 단백질 공급원을 다양하게 섞으세요. 다양성이 모든 아미노산을 충족합니다.';

  @override
  String get homeTip_rate_of_perceived_exertion =>
      '운동 강도를 1~10으로 평가해보세요. 대부분의 세션에서 7~8을 유지하는 것이 가장 좋습니다.';

  @override
  String get homeTip_rest_days_grow_muscle =>
      '휴식일은 게으름이 아닙니다. 신체가 실제로 적응하고 성장하는 시간입니다.';

  @override
  String get homeTip_scale_not_everything =>
      '체중은 수분과 음식 섭취로 매일 2~4파운드씩 변합니다. 주간 평균으로 판단하세요.';

  @override
  String get homeTip_set_rep_ranges =>
      '1~5회는 근력, 6~12회는 근비대, 12~20회는 근지구력을 키워줍니다. 모두 중요합니다.';

  @override
  String get homeTip_sleep_for_recovery => '근육은 운동할 때가 아니라 잠잘 때 성장합니다.';

  @override
  String get homeTip_sodium_and_water =>
      '나트륨은 적이 아닙니다. 수분 보충과 운동 수행 능력을 돕습니다. 두려워하지 마세요.';

  @override
  String get homeTip_split_options =>
      'Push/pull/legs, upper/lower, full-body 3x — 꾸준히만 한다면 모두 효과적입니다.';

  @override
  String get homeTip_stress_and_recovery =>
      '높은 스트레스는 높은 코르티솔 수치를 유발해 회복을 더디게 합니다. 전체적인 관리가 필요합니다.';

  @override
  String get homeTip_tempo_training =>
      '3-0-1 템포(내릴 때 3초, 멈춤 없이, 올릴 때 1초)로 운동 자극을 다르게 느껴보세요.';

  @override
  String get homeTip_track_to_progress => '기록하지 않으면 관리할 수 없습니다. 세트를 기록하세요.';

  @override
  String get homeTip_vitamin_d =>
      '대부분의 사람들은 비타민 D가 부족합니다. 매일 1000~2000 IU 섭취가 안전한 기준입니다.';

  @override
  String get homeTip_walk_after_meals => '식후 10분 걷기는 혈당 스파이크를 30%까지 낮출 수 있습니다.';

  @override
  String get homeTip_warm_up_matters => '5분의 준비 운동이 모든 세트를 더 안전하고 강력하게 만듭니다.';

  @override
  String get homeTip_zone2_cardio =>
      'Zone 2 유산소(대화 가능한 속도)는 모든 운동의 기초가 되는 유산소 베이스를 만듭니다.';

  @override
  String get homeTodaysNutrition => '오늘의 영양';

  @override
  String get homeTodaysWorkout => '오늘의 운동';

  @override
  String get homeTrackNutrition => '영양 추적';

  @override
  String get homeViewStrengthChartsStreaks => '근력 차트, 연속 기록, XP, 업적을 확인하세요.';

  @override
  String get homeViewYourWorkoutHistory => '운동 기록을 확인하고 운동 라이브러리를 둘러보세요.';

  @override
  String get homeYourAiWorkout => '나의 AI 운동';

  @override
  String get homeYourCommandCenter => '나의 커맨드 센터';

  @override
  String get homeYourProgress => '나의 진행 상황';

  @override
  String get homescreenCustomizationChangesAreSavedAutomaticall =>
      '변경 사항은 자동으로 저장되며 즉시 적용됩니다.';

  @override
  String get homescreenCustomizationChooseWhichCardsTo => '홈 화면에 표시할 카드를 선택하세요';

  @override
  String get homescreenCustomizationCustomizeHome => '홈 화면 사용자 지정';

  @override
  String get homescreenCustomizationDailyActivity => '일일 활동';

  @override
  String get homescreenCustomizationExerciseVariationThisWeek => '이번 주 운동 변화';

  @override
  String get homescreenCustomizationFeatureVotingAndRoadmap =>
      '기능 투표 및 로드맵 미리보기';

  @override
  String get homescreenCustomizationFitnessScore => '피트니스 점수';

  @override
  String get homescreenCustomizationGoalsAndMilestonesFor => '이번 주 목표 및 마일스톤';

  @override
  String get homescreenCustomizationHealthDeviceActivitySummary =>
      '건강 기기 활동 요약';

  @override
  String get homescreenCustomizationLogFoodStatsShare => '식단, 통계, 공유, 물 기록 버튼';

  @override
  String get homescreenCustomizationMoodCheckIn => '기분 체크인';

  @override
  String get homescreenCustomizationOverallFitnessStrengthNu =>
      '전반적인 피트니스, 근력 및 영양 점수';

  @override
  String get homescreenCustomizationQuickActions => '빠른 작업';

  @override
  String get homescreenCustomizationQuickMoodPickerFor =>
      '즉각적인 운동을 위한 빠른 기분 선택';

  @override
  String get homescreenCustomizationResetToDefaults => '기본값으로 초기화';

  @override
  String get homescreenCustomizationUpcomingFeatures => '예정된 기능';

  @override
  String get homescreenCustomizationWeekChanges => '주간 변화';

  @override
  String get homescreenCustomizationWeeklyGoals => '주간 목표';

  @override
  String get homescreenCustomizationWeeklyProgress => '주간 진행 상황';

  @override
  String get homescreenCustomizationWorkoutCompletionProgressRi =>
      '운동 완료 진행률 링';

  @override
  String get hormonalHealthFailedToLoadHormonal => '호르몬 건강 데이터를 불러오지 못했습니다';

  @override
  String get hormonalHealthGetStarted => '시작하기';

  @override
  String get hormonalHealthHormonalHealth => '호르몬 건강';

  @override
  String get hormonalHealthHormonalHealthTracking => '호르몬 건강 추적';

  @override
  String get hormonalHealthLogHowYouRe => '기분 기록하기';

  @override
  String get hormonalHealthLogNow => '지금 기록하기';

  @override
  String get hormonalHealthLogToday => '오늘 기록하기';

  @override
  String get hormonalHealthNoCheckInYet => '오늘 아직 체크인하지 않았습니다';

  @override
  String get hormonalHealthNotLogged => '기록되지 않음';

  @override
  String get hormonalHealthPeriodStartLogged => '생리 시작일 기록됨';

  @override
  String get hormonalHealthRecommendations => '추천 사항';

  @override
  String hormonalHealthScreenValue(Object value) {
    return '$value/10';
  }

  @override
  String get hormonalHealthSettingsAddHormoneGoal => '호르몬 목표 추가';

  @override
  String get hormonalHealthSettingsAdjustWorkoutIntensityBased =>
      '주기 단계에 따라 운동 강도 조절';

  @override
  String get hormonalHealthSettingsBirthSex => '생물학적 성별';

  @override
  String get hormonalHealthSettingsCycleLength => '주기 길이';

  @override
  String get hormonalHealthSettingsCycleSyncNutrition => '주기 맞춤 영양';

  @override
  String get hormonalHealthSettingsCycleSyncWorkouts => '주기 맞춤 운동';

  @override
  String get hormonalHealthSettingsEnableCycleTracking => '주기 추적 활성화';

  @override
  String get hormonalHealthSettingsGenderIdentity => '성 정체성';

  @override
  String get hormonalHealthSettingsGetNutritionTipsBased => '주기 단계에 따른 영양 팁 받기';

  @override
  String get hormonalHealthSettingsHormonalHealthSettings => '호르몬 건강 설정';

  @override
  String get hormonalHealthSettingsHormoneSupportiveExercises => '호르몬 지원 운동';

  @override
  String get hormonalHealthSettingsHormoneSupportiveFoods => '호르몬 지원 음식';

  @override
  String get hormonalHealthSettingsIncludeHormoneFriendlyFood =>
      '호르몬 친화적 음식 제안 포함';

  @override
  String get hormonalHealthSettingsLastPeriodStart => '마지막 생리 시작일';

  @override
  String get hormonalHealthSettingsNotSet => '설정 안 됨';

  @override
  String get hormonalHealthSettingsPeriodDuration => '생리 기간';

  @override
  String get hormonalHealthSettingsPrioritizeExercisesThatSupp =>
      '목표를 지원하는 운동 우선순위 지정';

  @override
  String hormonalHealthSettingsScreenDays(Object selected) {
    return '$selected일';
  }

  @override
  String hormonalHealthSettingsScreenDays2(Object selected) {
    return '$selected일';
  }

  @override
  String hormonalHealthSettingsScreenDays3(Object selected) {
    return '$selected일';
  }

  @override
  String hormonalHealthSettingsScreenDays4(Object selected) {
    return '$selected일';
  }

  @override
  String get hormonalHealthSettingsSelectHormoneGoals => '호르몬 목표 선택';

  @override
  String get hormonalHealthSettingsTrackYourMenstrualCycle =>
      '최적화된 운동을 위해 생리 주기를 추적하세요';

  @override
  String get hormonalHealthTodaySCheckIn => '오늘의 체크인';

  @override
  String get hormonalHealthUnableToLoadToday => '오늘의 기록을 불러올 수 없습니다';

  @override
  String get hormoneGoalsCardNoHormoneGoalsSet => '설정된 호르몬 목표 없음';

  @override
  String get hormoneGoalsCardSetGoals => '목표 설정';

  @override
  String get hormoneGoalsCardYourGoals => '나의 목표';

  @override
  String get hormoneLogAddReading => '수치 추가';

  @override
  String get hormoneLogBasalTemperature => '기초 체온';

  @override
  String get hormoneLogCervicalMucus => '자궁경부 점액';

  @override
  String get hormoneLogCheckInSaved => '체크인이 저장되었습니다!';

  @override
  String get hormoneLogDailyCheckIn => '일일 체크인';

  @override
  String get hormoneLogHelpsYourCoachTime => '코치가 가임기 안내를 설정하는 데 도움이 됩니다';

  @override
  String get hormoneLogHowAreYouFeeling => '오늘 기분은 어떠신가요?';

  @override
  String get hormoneLogLhOvulationTest => 'LH 배란 테스트';

  @override
  String get hormoneLogMood => '기분';

  @override
  String get hormoneLogNone => '없음';

  @override
  String get hormoneLogNotesOptional => '메모 (선택 사항)';

  @override
  String get hormoneLogPeriodFlow => '생리 양';

  @override
  String get hormoneLogSaveCheckIn => '체크인 저장';

  @override
  String get hormoneLogSaving => '저장 중...';

  @override
  String get hormoneLogSexualActivity => '성생활';

  @override
  String hormoneLogSheetFailedToSave(Object e) {
    return '저장 실패: $e';
  }

  @override
  String hormoneLogSheetValue(Object value) {
    return '$value/10';
  }

  @override
  String get hormoneLogSymptoms => '증상';

  @override
  String get hormoneLogTakeItFirstThing => '매일 아침 일어나기 전 첫 번째로 측정하세요.';

  @override
  String get hourlyActivityChartActive => '활동';

  @override
  String get hourlyActivityChartActive2 => '활동';

  @override
  String get hourlyActivityChartActiveHours => '활동 시간';

  @override
  String hourlyActivityChartActiveHours2(Object _activeHours) {
    return '활동 시간 $_activeHours시간';
  }

  @override
  String get hourlyActivityChartActivityTrends => '활동 트렌드';

  @override
  String get hourlyActivityChartSedentary => '비활동';

  @override
  String get hourlyActivityChartSedentary2 => '비활동';

  @override
  String get hourlyActivityChartSedentaryHours => '비활동 시간';

  @override
  String hourlyActivityChartSedentaryHours2(Object _sedentaryHours) {
    return '비활동 시간 $_sedentaryHours시간';
  }

  @override
  String hourlyActivityChartSteps(Object steps) {
    return '$steps 걸음';
  }

  @override
  String get hrZonesCardAddYourDateOf => '생년월일을 추가하여 개인 맞춤형 심박수 구간을 계산하세요';

  @override
  String hrZonesCardBpm(Object currentHR) {
    return '$currentHR bpm';
  }

  @override
  String get hrZonesCardFitnessAge => '피트니스 연령';

  @override
  String get hrZonesCardHeartRateZones => '심박수 구간';

  @override
  String get hrZonesCardHrZonesNotAvailable => '심박수 구간을 사용할 수 없음';

  @override
  String hrZonesCardMaxHrBpm(Object maxHR) {
    return '최대 HR: $maxHR bpm';
  }

  @override
  String get hrZonesCardMlKgMin => 'ml/kg/min';

  @override
  String get hrZonesCardPersonalizedTrainingZones => '개인 맞춤형 훈련 구간';

  @override
  String get hrZonesCardSetCustomMaxHr => '사용자 지정 최대 심박수 설정';

  @override
  String get hrZonesCardVo2Max => 'VO2 Max';

  @override
  String hrZonesCardYearsYounger(Object ageDiff) {
    return '$ageDiff년 더 젊음';
  }

  @override
  String hrZonesCardZone(Object name) {
    return '존: $name';
  }

  @override
  String get hydrationAdd => '추가';

  @override
  String get hydrationAddWater => '물 추가';

  @override
  String get hydrationAmount => '양';

  @override
  String get hydrationAmountMl => '양 (ml)';

  @override
  String get hydrationCurrent => '현재';

  @override
  String get hydrationCustomAmount => '사용자 지정 양';

  @override
  String get hydrationDailyGoal => '일일 목표';

  @override
  String hydrationDialogLog(Object label) {
    return '$label 기록';
  }

  @override
  String get hydrationEnterAnyAmountIn => '밀리리터 단위로 양을 입력하세요';

  @override
  String get hydrationGoalMl => '목표 (ml)';

  @override
  String get hydrationHydrationSettings => '수분 섭취 설정';

  @override
  String get hydrationNotesOptional => '메모 (선택 사항)';

  @override
  String get hydrationQuickActionsInstructions => '지침';

  @override
  String get hydrationQuickActionsLogDrink => '음료 기록';

  @override
  String get hydrationQuickActionsNote => '메모';

  @override
  String get hydrationQuickActionsVideo => '영상';

  @override
  String get hydrationRecommended20003000mlPer => '권장량: 하루 2000-3000ml';

  @override
  String get hydrationRemaining => '남은 양';

  @override
  String hydrationSummaryBlockGal(Object gallons, Object goalGallons) {
    return '($gallons / $goalGallons 갤런)';
  }

  @override
  String get hydrationSummaryBlockHydration => '수분 섭취';

  @override
  String hydrationSummaryBlockMl(Object currentMl, Object goalMl) {
    return '$currentMl / $goalMl ml';
  }

  @override
  String get hydrationSummaryBlockTapToViewDetails => '탭하여 상세 정보 보기';

  @override
  String hydrationSummaryBlockValue(Object percentageInt) {
    return '$percentageInt%';
  }

  @override
  String hydrationTabAddedOfWater(Object displayAmount, Object label) {
    return '물 $displayAmount$label 추가됨';
  }

  @override
  String hydrationTabLog(Object label) {
    return '$label 기록';
  }

  @override
  String hydrationTabMl(Object ml) {
    return '${ml}ml';
  }

  @override
  String hydrationTabMlOf(Object label, Object ml) {
    return '])ml of (label)';
  }

  @override
  String get hydrationTabPartAnyMl => '임의 ml';

  @override
  String get hydrationTabPartBreakdown => '분석';

  @override
  String get hydrationTabPartChat => '채팅';

  @override
  String get hydrationTabPartCustom => '사용자 지정';

  @override
  String get hydrationTabPartFuel => '연료';

  @override
  String get hydrationTabPartOther => '기타';

  @override
  String get hydrationTabPartOtherDrinks => '기타 음료';

  @override
  String get hydrationTabPartProteinShake => '단백질 쉐이크';

  @override
  String get hydrationTabPartQuickAddWater => '빠른 물 추가';

  @override
  String get hydrationTabPartSportsDrink => '스포츠 음료';

  @override
  String hydrationTabPartStatItemVia(Object label) {
    return '$label 경유';
  }

  @override
  String get hydrationTabPartWater => '물';

  @override
  String get hydrationTodaySLog => '오늘의 기록';

  @override
  String get hydrationUpdateGoal => '목표 업데이트';

  @override
  String importDialogFile(Object name) {
    return '파일: $name';
  }

  @override
  String importDialogImportData(Object appName) {
    return '$appName 데이터 가져오기';
  }

  @override
  String importDialogImportData2(Object appName) {
    return '$appName 데이터 가져오기';
  }

  @override
  String importDialogImportedN(Object summary) {
    return '가져오기 완료:\n$summary';
  }

  @override
  String importDialogSelectAPreviouslyExported(Object appName) {
    return '이전에 내보낸 $appName ZIP 파일을 선택하여 데이터를 복원하세요. 파일에 포함된 모든 데이터를 가져옵니다.';
  }

  @override
  String importDialogThisWillReplaceYour(Object appName) {
    return '현재 $appName 데이터가 대체됩니다.';
  }

  @override
  String get importEquipmentAnalyze => '분석';

  @override
  String get importEquipmentAnyPublicWebpageListing => '운동 기구가 나열된 공개 웹페이지.';

  @override
  String get importEquipmentEGNdumbbells5 =>
      '예:\nDumbbells 5-100 lb\n2x Squat racks\nLeg press (plate-loaded)\nTreadmills x4\nCable station...';

  @override
  String get importEquipmentEverythingImportedGoesTo =>
      '가져온 모든 항목은 검토 화면으로 이동합니다. 확인 없이 장비를 덮어쓰지 않습니다.';

  @override
  String get importEquipmentImportEquipment => '장비 가져오기';

  @override
  String get importEquipmentImportFailed => '가져오기 실패';

  @override
  String get importEquipmentLetAiReadYour => 'AI가 헬스장 장비 목록을 읽게 하세요';

  @override
  String get importEquipmentPasteEquipmentText => '장비 텍스트 붙여넣기';

  @override
  String get importEquipmentPasteTheUrl => 'URL 붙여넣기';

  @override
  String get importEquipmentResultAdd => '+ 추가';

  @override
  String get importEquipmentResultCustom => '사용자 지정 ✓';

  @override
  String get importEquipmentResultInferredFromImportedContent =>
      '가져온 콘텐츠에서 추론됨';

  @override
  String get importEquipmentResultNoEquipmentCouldBe =>
      '가져온 데이터에서 일치하는 장비를 찾을 수 없습니다.';

  @override
  String get importEquipmentResultReviewBeforeSavingTap =>
      '저장 전 검토하세요. 칩을 탭하여 제거할 수 있습니다.';

  @override
  String get importEquipmentResultSaving => '저장 중...';

  @override
  String importEquipmentResultSheetAddedEquipmentItems(Object addedCount) {
    return '장비 $addedCount개 추가됨';
  }

  @override
  String importEquipmentResultSheetMatched(
    Object matchedKeptCount,
    Object totalMatched,
  ) {
    return '일치함 ($matchedKeptCount/$totalMatched)';
  }

  @override
  String importEquipmentResultSheetSaveItems(Object keepCount) {
    return '항목 $keepCount개 저장';
  }

  @override
  String importEquipmentResultSheetUnmatched(Object length) {
    return '일치하지 않음 ($length)';
  }

  @override
  String importEquipmentResultSheetWeFoundItemsIn(Object totalExtracted) {
    return '체육관에서 항목 $totalExtracted개를 찾았습니다.';
  }

  @override
  String get importEquipmentResultWeCouldnTMatch =>
      '알려진 장비와 일치하지 않습니다. 건너뛰거나 사용자 지정으로 유지하세요.';

  @override
  String get importEquipmentResultWorkoutEnvironment => '운동 환경';

  @override
  String importEquipmentSheetUpToPhotosEquipment(Object _kMaxPhotos) {
    return '최대 $_kMaxPhotos장의 사진 — 장비 벽, 랙, 머신 태그';
  }

  @override
  String get importEquipmentThisUsuallyTakes10 => '보통 10~30초 정도 소요됩니다.';

  @override
  String get importEquipmentTryAgain => '다시 시도';

  @override
  String get importEquipmentWorking => '작업 중...';

  @override
  String get importEquipmentYourGymSEquipment => '헬스장 장비 목록 또는 시설 안내문';

  @override
  String get importExerciseDescribeTheExercise => '운동 설명';

  @override
  String get importExerciseEGSeatedCable =>
      '예: \'중립 그립 시티드 케이블 로우, 등 중앙 및 후면 삼각근 타겟\'';

  @override
  String get importExerciseExerciseNameHintOptional => '운동 이름 힌트 (선택 사항)';

  @override
  String get importExerciseFromGallery => '갤러리에서 가져오기';

  @override
  String get importExerciseFromLibrary => '라이브러리에서 가져오기';

  @override
  String get importExerciseImportExercise => '운동 가져오기';

  @override
  String get importExerciseImportWithAi => 'AI로 가져오기';

  @override
  String get importExercisePreviewAddStep => '단계 추가';

  @override
  String get importExercisePreviewAiSearchable => 'AI 검색 가능';

  @override
  String get importExercisePreviewAlreadyInYourExercises => '이미 내 운동 목록에 있음';

  @override
  String get importExercisePreviewDiscard => '삭제';

  @override
  String get importExercisePreviewDiscardImportedExercise => '가져온 운동을 삭제할까요?';

  @override
  String get importExercisePreviewSaveExercise => '운동 저장';

  @override
  String get importExercisePreviewSaving => '저장 중...';

  @override
  String importExercisePreviewSheetAiConfidencePleaseReview(Object pct) {
    return 'AI 신뢰도: $pct% — 검토해주세요';
  }

  @override
  String importExercisePreviewSheetYouAlreadyHaveIn(Object name) {
    return '이미 \'$name\' 운동이 있습니다. 확인 중...';
  }

  @override
  String get importExercisePreviewUseExisting => '기존 항목 사용';

  @override
  String get importExerciseRecordA510s => '5~10초 영상 녹화';

  @override
  String get importExerciseRecordVideo => '영상 녹화';

  @override
  String importExerciseScreenS(Object inSeconds) {
    return '$inSeconds초';
  }

  @override
  String get importExerciseSnapItWeLl => '촬영하면 추출해 드립니다';

  @override
  String get importExerciseTakePhoto => '사진 촬영';

  @override
  String get importExerciseWorking => '작업 중...';

  @override
  String get importImport => '가져오기';

  @override
  String get importImportSuccessful => '가져오기 성공';

  @override
  String get importNewDataWillBe => '새 데이터가 기존 데이터와 함께 추가됩니다.';

  @override
  String get importSelectFile => '파일 선택';

  @override
  String get importThisWillImport => '가져올 항목:';

  @override
  String get inProgressStripLogAWorkoutTo => '운동을 기록하고 진행 상황 배지를 잠금 해제하세요.';

  @override
  String get inflammationAnalysisAiIsCheckingFor => 'AI가 염증 유발 성분을 확인 중입니다';

  @override
  String get inflammationAnalysisAnalyzingIngredients => '성분 분석 중...';

  @override
  String get inflammationAnalysisConcern => '주의';

  @override
  String get inflammationAnalysisGood => '좋음';

  @override
  String get inflammationAnalysisInflammationScore => '염증 점수';

  @override
  String get inflammationAnalysisIngredientAnalysisUnavailabl =>
      '성분 분석을 사용할 수 없음';

  @override
  String get inflammationAnalysisIngredientsAnalysis => '성분 분석';

  @override
  String get inflammationAnalysisNeutral => '보통';

  @override
  String get inflammationAnalysisShowLess => '간략히 보기';

  @override
  String inflammationAnalysisWidgetShowMore(Object sortedIngredients) {
    return '$sortedIngredients개 더 보기';
  }

  @override
  String get inflammationTagsContainsUltraProcessedItems => '초가공 식품 포함';

  @override
  String get inflammationTagsExamplesSoftDrinksInstant =>
      '예: 탄산음료, 인스턴트 라면, 포장 스낵, 치킨 너겟, 대부분의 시리얼.';

  @override
  String get inflammationTagsHowTheScoreIs => '점수 산정 방식';

  @override
  String get inflammationTagsInflammationScore => '염증 점수';

  @override
  String get inflammationTagsLowerScoresReduceSystemic =>
      '점수가 낮을수록 전신 염증, 장 자극 및 식후 에너지 저하를 줄일 수 있습니다.';

  @override
  String get inflammationTagsNovaProcessingLevelOmega =>
      'NOVA 가공 단계, 오메가-6:오메가-3 지방 비율, 정제당 함량, 식이섬유 및 폴리페놀 밀도, 혈당 부하, 씨앗유 함량. 동료 심사를 거친 식이 염증 지수(DII) 기준에 따라 조정되었습니다.';

  @override
  String get inflammationTagsResearchLinksRegularConsump =>
      '연구에 따르면 정기적인 섭취는 염증, 비만, 심장 질환 및 소화기 문제 증가와 관련이 있습니다.';

  @override
  String get inflammationTagsUltraProcessedFoods => '초가공 식품';

  @override
  String get inflammationTagsUltraProcessedFoodsNova =>
      '초가공 식품(NOVA 4단계)에는 유화제, 경화유, 인공 감미료, 단백질 분리물과 같은 산업용 첨가물이 포함되어 있으며, 이는 가정 요리에서는 찾아볼 수 없는 성분입니다.';

  @override
  String get injuriesActive => '진행 중';

  @override
  String get injuriesHealed => '완치';

  @override
  String get injuriesHowIsYourPain => '오늘 통증 수준은 어떤가요?';

  @override
  String get injuriesInjuryTracker => '부상 추적기';

  @override
  String get injuriesListFailedToLoad => '불러오기 실패';

  @override
  String get injuriesListInjuryManagement => '부상 관리';

  @override
  String get injuriesListReportInjury => '부상 보고';

  @override
  String injuriesListScreenInjuries(Object id) {
    return '/injuries/$id';
  }

  @override
  String get injuriesMild => '경미함';

  @override
  String get injuriesRecovering => '회복 중';

  @override
  String get injuriesReportAnInjury => '부상 보고하기';

  @override
  String get injuriesReportInjury => '부상 보고';

  @override
  String injuriesScreenCheckIn(Object bodyPartDisplay) {
    return '체크인: $bodyPartDisplay';
  }

  @override
  String injuriesScreenCheckInSavedPain(Object painLevel) {
    return '체크인 저장됨: 통증 레벨 $painLevel/10';
  }

  @override
  String get injuriesSelectorAiWillAvoidExercises =>
      'AI가 해당 부위를 악화시킬 수 있는 운동을 피합니다';

  @override
  String get injuriesSelectorEnterCustomInjuryE =>
      '사용자 지정 부상 입력 (예: \"테니스 엘보\")';

  @override
  String get injuriesSelectorInjuriesToConsider => '고려할 부상';

  @override
  String injuriesSelectorSelected(Object selectedCount) {
    return '$selectedCount개 선택됨';
  }

  @override
  String get injuriesSevere => '심각함';

  @override
  String get injuriesSomethingWentWrong => '문제가 발생했습니다';

  @override
  String get injuriesTryAgain => '다시 시도';

  @override
  String get injuriesUnknownError => '알 수 없는 오류';

  @override
  String get injuryCardCheckIn => '체크인';

  @override
  String injuryCardDaysAgo(Object daysSinceReported) {
    return '$daysSinceReported일 전';
  }

  @override
  String injuryCardDaysLeft(Object daysUntilRecovery) {
    return '회복까지 $daysUntilRecovery일';
  }

  @override
  String get injuryCardFullyRecovered => '완치';

  @override
  String get injuryCardHealed => '회복됨';

  @override
  String injuryCardPain(Object painLevel) {
    return '통증: $painLevel/10';
  }

  @override
  String get injuryCardRecoveryProgress => '회복 진행 상황';

  @override
  String injuryCardValue(Object recoveryProgress) {
    return '$recoveryProgress%';
  }

  @override
  String get injuryDetailAffectedExercises => '영향을 받는 운동';

  @override
  String get injuryDetailAreYouSureThis =>
      '이 부상이 완전히 나았나요? 확인 시 부상 기록으로 이동됩니다.';

  @override
  String get injuryDetailCheckInLoggedSuccessfully => '체크인이 성공적으로 기록되었습니다';

  @override
  String get injuryDetailCongratulationsOnYourRecove => '회복을 축하합니다!';

  @override
  String get injuryDetailGoBack => '뒤로 가기';

  @override
  String get injuryDetailInjuryDetails => '부상 상세 정보';

  @override
  String get injuryDetailInjuryNotFound => '부상을 찾을 수 없습니다';

  @override
  String get injuryDetailMarkAsHealed => '완치로 표시할까요?';

  @override
  String get injuryDetailMarkAsHealed2 => '완치로 표시';

  @override
  String get injuryDetailNotes => '메모';

  @override
  String get injuryDetailPainLevelHistory => '통증 수준 기록';

  @override
  String get injuryDetailRecoveryProgress => '회복 진행 상황';

  @override
  String get injuryDetailRehabExercises => '재활 운동';

  @override
  String get injuryDetailScreenAnyNotesAboutHow => '오늘 상태가 어떤지 메모를 남겨주세요...';

  @override
  String get injuryDetailScreenDailyCheckIn => '일일 체크인';

  @override
  String injuryDetailScreenFailedToLogCheck(Object e) {
    return '체크인 기록 실패: $e';
  }

  @override
  String injuryDetailScreenFailedToMarkAs(Object e) {
    return '치유 표시 실패: $e';
  }

  @override
  String injuryDetailScreenInjuries(Object id) {
    return '/injuries/$id';
  }

  @override
  String get injuryDetailScreenLogCheckIn => '체크인 기록';

  @override
  String injuryDetailScreenPartCheckInSheetHowIsYourFeeling(
    Object bodyPartDisplay,
  ) {
    return '오늘 $bodyPartDisplay 상태는 어떤가요?';
  }

  @override
  String injuryDetailScreenValue(Object recoveryProgress) {
    return '$recoveryProgress%';
  }

  @override
  String get injuryDetailSomethingWentWrong => '문제가 발생했습니다';

  @override
  String get injuryDetailThisInjuryMayHave => '이 부상 기록이 삭제되었을 수 있습니다';

  @override
  String get injuryDetailTryAgain => '다시 시도';

  @override
  String get injuryDetailUnknownError => '알 수 없는 오류';

  @override
  String get injuryDetailYesHealed => '네, 완치되었습니다';

  @override
  String inlineEditPillEditSetByReps(
    Object _weightText,
    Object reps,
    Object unit,
  ) {
    return '세트 편집, $_weightText $unit $reps회';
  }

  @override
  String get inlineEditPillSaveSet => '세트 저장';

  @override
  String inlineEditPillValue(Object _weightText, Object reps, Object unit) {
    return '$_weightText $unit × $reps';
  }

  @override
  String get inlineExerciseInfoFormTips => '자세 팁';

  @override
  String get inlineExerciseInfoSetup => '준비';

  @override
  String get inlineReferralExpanderApply => '적용';

  @override
  String get inlineReferralExpanderEnterCode => '코드 입력';

  @override
  String get inlineReferralExpanderReferralCodeApplied => '✓ 추천 코드가 적용되었습니다';

  @override
  String get inlineRestRow15s => '-15s';

  @override
  String get inlineRestRow15s2 => '+15초';

  @override
  String get inlineRestRowAddANoteAbout => '이 세트에 대한 메모를 추가하세요...';

  @override
  String get inlineRestRowGettingTip => '팁 가져오는 중...';

  @override
  String get inlineRestRowHowDidThatFeel => '느낌이 어땠나요?';

  @override
  String get inlineRestRowNote => '메모';

  @override
  String get inlineRestRowRpe => '(RPE)';

  @override
  String inlineRestRowValue(Object aiTip) {
    return '\"$aiTip\"';
  }

  @override
  String get inlineThemeSelectorAuto => '자동';

  @override
  String get inlineWorkoutChatAddAMessage => '메시지 추가...';

  @override
  String get inlineWorkoutChatAskMeAnything => '무엇이든 물어보세요!';

  @override
  String get inlineWorkoutChatChangeCoach => '코치 변경';

  @override
  String inlineWorkoutChatCheckMyFormOn(Object name) {
    return '$name 자세 확인하기';
  }

  @override
  String get inlineWorkoutChatCollapseChat => '채팅 접기';

  @override
  String get inlineWorkoutChatExpandChat => '채팅 펼치기';

  @override
  String get inlineWorkoutChatFailedToLoadChat => '채팅 기록을 불러오지 못했습니다';

  @override
  String get inlineWorkoutChatForm => '자세';

  @override
  String inlineWorkoutChatHowLongShouldI(Object name) {
    return '$name 세트 사이에는 얼마나 쉬어야 하나요?';
  }

  @override
  String inlineWorkoutChatHowManySetsShould(Object name) {
    return '최고의 결과를 위해 $name은 몇 세트 하는 것이 좋나요?';
  }

  @override
  String get inlineWorkoutChatIntentIdentifyEquipmentWh =>
      '[intent:identify_equipment] 이 기구는 무엇인가요?';

  @override
  String get inlineWorkoutChatRest => '휴식';

  @override
  String get inlineWorkoutChatSets => '세트';

  @override
  String get inlineWorkoutChatSwaps => '교체';

  @override
  String inlineWorkoutChatWhatAreSomeAlternative(Object name) {
    return '$name 대신 할 수 있는 대체 운동은 무엇인가요?';
  }

  @override
  String inlineWorkoutChatWhatAreTheKey(Object name) {
    return '$name 운동 시 올바른 자세를 위한 핵심 팁은 무엇인가요?';
  }

  @override
  String get inlineWorkoutChatWhatSThis => '이게 무엇인가요?';

  @override
  String get insightsDetailAiAnalysis => 'AI 분석';

  @override
  String get insightsDetailCompletionRate => '완료율';

  @override
  String get insightsDetailGenerateAiAnalysis => 'AI 분석 생성';

  @override
  String get insightsDetailGenerating => '생성 중...';

  @override
  String get insightsDetailHighlights => '하이라이트';

  @override
  String get insightsDetailNoAiAnalysisYet => '이 리포트에 대한 AI 분석이 아직 없습니다';

  @override
  String get insightsDetailRegenerateAiAnalysis => 'AI 분석 다시 생성';

  @override
  String insightsDetailScreenCouldNotRegenerate(Object e) {
    return '재생성할 수 없음 — $e';
  }

  @override
  String insightsDetailScreenDayStreak(Object currentStreak) {
    return '$currentStreak일 연속';
  }

  @override
  String insightsDetailScreenOfWorkouts(
    Object workoutsCompleted,
    Object workoutsScheduled,
  ) {
    return '$workoutsScheduled개 중 $workoutsCompleted개 운동 완료';
  }

  @override
  String insightsDetailScreenPrs(Object prsAchieved) {
    return 'PR $prsAchieved개';
  }

  @override
  String insightsDetailScreenReport(Object weekLabel) {
    return '$weekLabel 리포트';
  }

  @override
  String insightsDetailScreenValue(Object rate) {
    return '$rate%';
  }

  @override
  String get insightsDetailTipsForNextWeek => '다음 주를 위한 팁';

  @override
  String get insightsDetailWorkoutSummary => '운동 요약';

  @override
  String insightsNarrativeTemplateAi(Object periodName) {
    return '$periodName AI';
  }

  @override
  String get insightsNarrativeTemplateYourConsistencyIsCompoundin =>
      '꾸준함이 쌓이고 있습니다. 계속해서 반복 횟수를 늘려가세요.';

  @override
  String get insightsPastReports => '지난 리포트';

  @override
  String get insightsProgressTemplateBodyFat => '체지방';

  @override
  String get insightsProgressTemplateBodyRecovery => '신체 및 회복';

  @override
  String insightsProgressTemplateDays(Object maxStreak) {
    return '$maxStreak일';
  }

  @override
  String get insightsProgressTemplateMaxStreak => '최대 연속 기록';

  @override
  String get insightsProgressTemplateNutrition => '영양';

  @override
  String get insightsProgressTemplateReadiness => '준비 상태';

  @override
  String get insightsProgressTemplateWeight => '체중';

  @override
  String get insightsPrsTemplate1Pr => '1 PR';

  @override
  String insightsPrsTemplateMorePrs(Object length) {
    return '+ PR $length개 더';
  }

  @override
  String get insightsPrsTemplateNoPrsYetThis => '이번 기간에 기록된 PR이 없습니다';

  @override
  String get insightsPrsTemplatePersonalRecords => '개인 최고 기록 (PR)';

  @override
  String insightsPrsTemplatePrs(Object count) {
    return 'PR $count개';
  }

  @override
  String get insightsPrsTemplateShowingUpIsThe =>
      '운동을 나오는 것 자체가 진정한 승리입니다. 계속해서 반복 횟수를 쌓아가세요.';

  @override
  String get insightsReportCardCalories => '칼로리';

  @override
  String get insightsReportCardCompleted => '완료됨';

  @override
  String get insightsReportCardCompletion => '완료';

  @override
  String get insightsReportCardMaxStreak => '최대 연속 기록';

  @override
  String get insightsReportCardPrs => 'PR';

  @override
  String get insightsReportCardReportCard => '리포트 카드';

  @override
  String insightsReportCardTemplateDays(Object maxStreak) {
    return '$maxStreak일';
  }

  @override
  String insightsReportCardTemplateValue(Object _completionPercent) {
    return '$_completionPercent%';
  }

  @override
  String get insightsReportsInsights => '리포트 및 인사이트';

  @override
  String get insightsScreenPartAiAnalysis => 'AI 분석';

  @override
  String get insightsScreenPartBody => '신체';

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
    return '운동 $workoutsCompleted/$workoutsScheduled회  |  $totalTimeMinutes분  |  $caloriesBurnedEstimate kcal';
  }

  @override
  String get insightsScreenPartBodyFat => '체지방';

  @override
  String get insightsScreenPartFailedToLoadInsights => '인사이트를 불러오지 못했습니다';

  @override
  String get insightsScreenPartGenerateAiInsight => 'AI 인사이트 생성';

  @override
  String get insightsScreenPartGetPersonalizedAiAnalysis =>
      '이 기간 동안의 운동 데이터를 바탕으로 개인 맞춤형 AI 분석을 받아보세요.';

  @override
  String get insightsScreenPartLogYourMeasurementsTo =>
      '신체 치수를 기록하여 신체 구성 변화를 추적하세요';

  @override
  String get insightsScreenPartLogYourReadinessAnd =>
      '컨디션과 기분을 기록하여 회복 인사이트를 확인하세요';

  @override
  String get insightsScreenPartMoodDistribution => '기분 분포';

  @override
  String get insightsScreenPartNoPastReportsYet => '아직 이전 리포트가 없습니다';

  @override
  String get insightsScreenPartOverview => '개요';

  @override
  String insightsScreenPartPeriodSelectorCompletionRate(Object completionRate) {
    return '완료율 $completionRate%';
  }

  @override
  String insightsScreenPartPeriodSelectorValue(Object adherence) {
    return '$adherence%';
  }

  @override
  String get insightsScreenPartPleaseCheckYourConnection =>
      '연결 상태를 확인하고 다시 시도해 주세요.';

  @override
  String get insightsScreenPartPrs => 'PRs';

  @override
  String get insightsScreenPartShareThisReport => '이 리포트 공유하기';

  @override
  String get insightsScreenPartStartTrackingNutritionTo =>
      '영양 기록을 시작하여 인사이트를 확인하세요';

  @override
  String get insightsScreenPartTips => '팁';

  @override
  String get insightsScreenPartWeeklyReportsWillAppear =>
      '주간 리포트가 생성되면 여기에 표시됩니다.';

  @override
  String get insightsScreenPartWeight => '체중';

  @override
  String get insightsStreakTemplateStreak => '연속 기록';

  @override
  String get insightsStreakTemplateWorkouts => '운동';

  @override
  String get insightsSummaryTemplateCalories => '칼로리';

  @override
  String get insightsSummaryTemplatePrs => 'PRs';

  @override
  String get insightsSummaryTemplateSummary => '요약';

  @override
  String get insightsSummaryTemplateWorkouts => '운동';

  @override
  String get intensityPrompt1Left => '1회 남음';

  @override
  String get intensityPrompt2Left => '2회 남음';

  @override
  String get intensityPrompt3Left => '3회 이상 남음';

  @override
  String get intensityPromptHard => '힘듦';

  @override
  String get intensityPromptHowHardWasThat => '이번 세트의 강도는 어땠나요?';

  @override
  String get intensityPromptMax => '최대';

  @override
  String get intensityPromptModerate => '보통';

  @override
  String get intensityPromptPickAnEffortTo => '계속하려면 강도를 선택하세요';

  @override
  String intensityPromptSheetSet(Object exerciseName, Object setNumber) {
    return '$setNumber세트 · $exerciseName';
  }

  @override
  String get introAnAiCoachThat =>
      '운동 계획을 세우고, 당신의 몸을 학습하며, 매주 조정해 주는 AI 코치입니다.';

  @override
  String get introBuildMyPlan => '내 계획 만들기';

  @override
  String get introCardMonth => '개월.';

  @override
  String get introIAlreadyHaveAnAccount => '이미 계정이 있습니다';

  @override
  String introScreenV(Object _appVersion) {
    return 'v$_appVersion';
  }

  @override
  String get introTagline => 'Zealova AI 코치가 계획을 세우고, 당신의 몸을 학습하며, 매주 조정합니다.';

  @override
  String get introYourBody => '당신의 몸.';

  @override
  String get introYourTimeline => '당신의 타임라인.';

  @override
  String get inventory2xXpActivatedFor => '24시간 동안 2배 XP 활성화!';

  @override
  String get inventory2xXpActive => '⚡ 2배 XP 활성화 중';

  @override
  String get inventory3RefsSticker10 =>
      '친구 3명 초대 → 스티커 · 10명 → 쉐이커 · 25명 → 티셔츠';

  @override
  String get inventory730100Day => '7일, 30일, 100일 연속 기록';

  @override
  String get inventoryAddedToYourInventory => '인벤토리에 추가되었습니다';

  @override
  String get inventoryAddedToYourXp => 'XP 총합에 추가되었습니다';

  @override
  String get inventoryAwesome => '멋져요!';

  @override
  String get inventoryCompleteAllDailyGoals => '모든 일일 목표 완료';

  @override
  String get inventoryCosmetics => '꾸미기 아이템';

  @override
  String get inventoryCrates => '상자';

  @override
  String get inventoryDailyCrates => '일일 상자';

  @override
  String get inventoryEvery5Levels => '5레벨마다';

  @override
  String get inventoryEveryXpEarnedRight => '지금 획득하는 모든 XP가 2배가 됩니다.';

  @override
  String get inventoryFailedToActivate2x => '2배 XP 토큰 활성화에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get inventoryFailedToOpenCrate => '상자를 열지 못했습니다';

  @override
  String get inventoryFirstUnlockLevel50 => '첫 잠금 해제: 레벨 50 — 무료 스티커 팩';

  @override
  String get inventoryGotIt => '확인';

  @override
  String get inventoryHowToEarnItems => '아이템 획득 방법';

  @override
  String get inventoryInventory => '인벤토리';

  @override
  String get inventoryItems => '아이템';

  @override
  String get inventoryLevelUpRewards => '레벨업 보상';

  @override
  String get inventoryMerchRewards => '굿즈 보상';

  @override
  String get inventoryOf24hBoost => '24시간 부스트';

  @override
  String get inventoryOpenCratesToReceive => '상자를 열어 XP나 소모성 아이템을 받으세요';

  @override
  String get inventoryPick1Of3 => '매일 3개의 상자 중 1개를 선택하세요';

  @override
  String get inventoryReferFriendsEarnMerch => '친구를 초대하고 굿즈를 더 빨리 받으세요';

  @override
  String inventoryScreenHM(Object hours, Object minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String inventoryScreenHMRemaining(Object hours, Object minutes) {
    return '$hours시간 $minutes분 남음';
  }

  @override
  String inventoryScreenPartConsumableCardX(Object count) {
    return 'x$count';
  }

  @override
  String inventoryScreenToClaim(Object pendingCount) {
    return '$pendingCount개 수령 가능';
  }

  @override
  String get inventoryScreenUiComeBackTomorrowFor => '내일 다시 와서 더 확인하세요!';

  @override
  String get inventoryScreenUiDailyCrates => '일일 상자';

  @override
  String get inventoryScreenUiPick1Of3 => '매일 3개의 상자 중 1개를 선택하세요';

  @override
  String get inventoryScreenUiTrustLevel => '신뢰 레벨';

  @override
  String get inventoryStreakMilestones => '연속 기록 마일스톤';

  @override
  String get inventoryTapToBrowseOr => '탭하여 탐색하거나 변경하세요';

  @override
  String get inventoryTrustLevelAffectsXp =>
      '신뢰 레벨은 운동 및 활동에서 획득하는 XP에 영향을 줍니다.';

  @override
  String get inventoryTrustLevels => '신뢰 레벨';

  @override
  String get inventoryUnlockActivityCrate => '활동 상자 잠금 해제';

  @override
  String get inventoryUsedAutomaticallyWhenYou => '운동을 하루 쉬었을 때 자동으로 사용됩니다';

  @override
  String get inventoryYouReceived => '획득한 아이템:';

  @override
  String get journalEmpty => '일지가 비어 있습니다. 타임라인을 시작하려면 운동을 기록하세요.';

  @override
  String get journalLogAWorkoutMeal => '운동, 식사 또는 사진을 기록하여 타임라인을 시작하세요.';

  @override
  String get journalSearchHint => '운동, 음식, 사진 검색…';

  @override
  String get journalTitle => '트레이닝 일지';

  @override
  String get journalYourJournalIsEmpty => '저널이 비어 있습니다';

  @override
  String get kegelSessionAreYouSureYou => '세션을 일찍 종료하시겠습니까? 진행 상황이 저장되지 않습니다.';

  @override
  String get kegelSessionBenefits => '효과';

  @override
  String get kegelSessionDoAnother => '한 번 더 하기';

  @override
  String get kegelSessionEndSession => '세션을 종료할까요?';

  @override
  String get kegelSessionEndSession2 => '세션 종료';

  @override
  String get kegelSessionInstructions => '지침';

  @override
  String get kegelSessionKegelExercise => '케겔 운동';

  @override
  String get kegelSessionKegelSession => '케겔 세션';

  @override
  String get kegelSessionNoExercisesAvailable => '사용 가능한 운동이 없습니다';

  @override
  String get kegelSessionQuickStart => '빠른 시작';

  @override
  String kegelSessionScreenErrorLoadingExercises(Object e) {
    return '운동 불러오기 오류: $e';
  }

  @override
  String kegelSessionScreenRepOf(Object _currentRep, Object _totalReps) {
    return '$_currentRep / $_totalReps회';
  }

  @override
  String kegelSessionScreenRepsXSHold(
    Object defaultHoldSeconds,
    Object defaultReps,
  ) {
    return '$defaultReps회 반복 x $defaultHoldSeconds초 유지';
  }

  @override
  String get kegelSessionSessionComplete => '세션 완료!';

  @override
  String get kegelSessionSqueeze => '조이기';

  @override
  String get kegelSessionSqueezeYourPelvicFloor => '골반저근을 조이고 유지하세요...';

  @override
  String get kegelSessionStartABasicKegel => '기본 케겔 세션을 지금 시작하세요';

  @override
  String get kegelSessionStartExercise => '운동 시작';

  @override
  String get kegelSettingsAddKegelsToYour => '웜업 루틴에 케겔 운동 추가';

  @override
  String get kegelSettingsAddKegelsToYour2 => '쿨다운 스트레칭에 케겔 운동 추가';

  @override
  String get kegelSettingsBeginner => '초급';

  @override
  String get kegelSettingsCooldown => '쿨다운';

  @override
  String get kegelSettingsDailyReminders => '일일 알림';

  @override
  String get kegelSettingsDailySessionsGoal => '일일 세션 목표';

  @override
  String get kegelSettingsDedicatedPelvicFloorWorkout => '전용 골반저근 운동 세션';

  @override
  String get kegelSettingsEnableKegelExercises => '케겔 운동 활성화';

  @override
  String get kegelSettingsExerciseLevel => '운동 레벨';

  @override
  String get kegelSettingsFocusArea => '집중 영역';

  @override
  String get kegelSettingsGeneral => '일반';

  @override
  String get kegelSettingsGetRemindedToDo => '케겔 운동 알림 받기';

  @override
  String get kegelSettingsIncludeIn => '포함 항목';

  @override
  String get kegelSettingsIncludePelvicFloorExercises => '훈련에 골반저근 운동 포함';

  @override
  String get kegelSettingsPelvicFloorTraining => '골반저근 훈련';

  @override
  String get kegelSettingsSelectExerciseLevel => '운동 레벨 선택';

  @override
  String get kegelSettingsSelectFocusArea => '집중 영역 선택';

  @override
  String get kegelSettingsStandaloneSessions => '독립형 세션';

  @override
  String get kegelSettingsStrengthenYourPelvicFloor =>
      '운동 루틴에 포함된 케겔 운동으로 골반저근을 강화하세요.';

  @override
  String get kegelSettingsWarmup => '웜업';

  @override
  String get languageLanguage => '언어';

  @override
  String lastNightSleepCardH(Object hours) {
    return '$hours시간';
  }

  @override
  String lastNightSleepCardM(Object minutes) {
    return '$minutes분';
  }

  @override
  String lastNightSleepCardValue(Object fmt, Object fmt1) {
    return '$fmt – $fmt1';
  }

  @override
  String get lastNightSleepLastNightSSleep => '어젯밤 수면';

  @override
  String get layoutEditorAppliedYourDefaultLayout => '기본 레이아웃이 적용되었습니다';

  @override
  String get layoutEditorFailedToLoadLayout => '레이아웃을 불러오지 못했습니다';

  @override
  String get layoutEditorLayoutResetToOriginal => '레이아웃이 원래대로 재설정되었습니다';

  @override
  String get layoutEditorMySpace => '마이 스페이스';

  @override
  String get layoutEditorNoLayoutFound => '레이아웃을 찾을 수 없습니다';

  @override
  String get layoutEditorReset => '재설정';

  @override
  String get layoutEditorResetLayout => '레이아웃 재설정';

  @override
  String get layoutEditorSavedAsYourDefault => '기본 레이아웃으로 저장되었습니다';

  @override
  String get layoutEditorScreenAppliedYourDefaultLayout => '기본 레이아웃이 적용되었습니다';

  @override
  String get layoutEditorScreenApply => '적용';

  @override
  String get layoutEditorScreenChooseAPresetTo =>
      '프리셋을 선택하여 홈 화면을 빠르게 사용자 지정하세요';

  @override
  String get layoutEditorScreenDragToReorderTap => '드래그하여 순서 변경 • 탭하여 전환';

  @override
  String get layoutEditorScreenHidden => '숨김';

  @override
  String get layoutEditorScreenMyDefault => '내 기본 설정';

  @override
  String layoutEditorScreenPartTogglesTabApplied(Object name) {
    return '$name 적용됨';
  }

  @override
  String layoutEditorScreenPartTogglesTabApplied2(Object name) {
    return '$name 적용됨';
  }

  @override
  String layoutEditorScreenPartTogglesTabTiles(Object length) {
    return '$length개 타일';
  }

  @override
  String layoutEditorScreenPartTogglesTabTiles2(Object length) {
    return '$length개 타일';
  }

  @override
  String get layoutEditorScreenPreview => '미리보기';

  @override
  String get layoutEditorScreenYourSavedCustomLayout => '저장된 사용자 지정 레이아웃';

  @override
  String get layoutEditorToggles => '토글';

  @override
  String get leaderboardBeatTheirBest => '최고 기록 깨기';

  @override
  String get leaderboardChallengeWithoutNotification => '알림 없이 도전하기 (비동기)';

  @override
  String get leaderboardEntryCardBeatTheirBest => '최고 기록 깨기';

  @override
  String get leaderboardEntryCardChallengeFriend => '친구에게 도전';

  @override
  String get leaderboardEntryCardFriend => '✓ 친구';

  @override
  String leaderboardEntryCardValue(Object rank) {
    return '#$rank';
  }

  @override
  String get leaderboardLockedStateCompleteMoreWorkoutsTo =>
      '더 많은 운동을 완료하여 잠금을 해제하세요!';

  @override
  String get leaderboardLockedStateGlobalLeaderboardLocked => '글로벌 리더보드 잠김';

  @override
  String get leaderboardLockedStateViewFriendsLeaderboard => '친구 리더보드 보기';

  @override
  String leaderboardLockedStateWorkouts(Object workoutsCompleted) {
    return '$workoutsCompleted / 10회 운동';
  }

  @override
  String get leaderboardMasters => '🏆 마스터';

  @override
  String get leaderboardNoRankingsYet => '아직 순위 없음';

  @override
  String get leaderboardPrivacyAnonymousMode => '익명 모드';

  @override
  String get leaderboardPrivacyCouldnTLoadPrivacy =>
      '개인정보 설정을 불러올 수 없습니다. 당겨서 다시 시도하세요.';

  @override
  String get leaderboardPrivacyLeaderboardPrivacy => '리더보드 개인정보';

  @override
  String get leaderboardPrivacyShowMeOnLeaderboards => '리더보드에 내 이름 표시';

  @override
  String get leaderboardPrivacyShowMyStatsOn => '프로필 보기에서 내 통계 표시';

  @override
  String leaderboardRankCardOf(Object totalUsers) {
    return '/ $totalUsers명';
  }

  @override
  String leaderboardRankCardTop(Object percentile) {
    return '상위 $percentile%';
  }

  @override
  String leaderboardRankCardValue(Object rank) {
    return '#$rank';
  }

  @override
  String get leaderboardRankCardYourRank => '내 순위';

  @override
  String leaderboardRowAdornmentsDownPlaces(Object absStr) {
    return '$absStr위 하락';
  }

  @override
  String get leaderboardRowAdornmentsNoPreviousRankData => '이전 순위 데이터 없음';

  @override
  String get leaderboardRowAdornmentsRankUnchanged => '순위 변동 없음';

  @override
  String leaderboardRowAdornmentsStreakDays(Object streak) {
    return '$streak일 연속';
  }

  @override
  String leaderboardRowAdornmentsUpPlaces(Object absStr) {
    return '$absStr위 상승';
  }

  @override
  String get leaderboardRush => '🚀 러시';

  @override
  String get leaderboardStreaks => '🔥 스트릭';

  @override
  String leaderboardTabChallenge(Object userName) {
    return '$userName 도전하기';
  }

  @override
  String get leaderboardVolume => '🏋️ 볼륨';

  @override
  String get leaderboardWeek => '⚡ 주간';

  @override
  String get levelUpCatchAwesomeGotIt => '멋져요 — 확인했습니다';

  @override
  String get levelUpCatchIncludesAFreePhysical =>
      '무료 실물 보상 포함 — Merch Rewards에서 수령하세요';

  @override
  String get levelUpCatchReveal => '공개';

  @override
  String get levelUpCatchTapToSeeYour => '탭하여 보상 확인';

  @override
  String levelUpCatchUpBannerFree(Object displayName) {
    return '무료 $displayName';
  }

  @override
  String levelUpCatchUpBannerLevelUnlocked(Object levelReached) {
    return '레벨 $levelReached 잠금 해제!';
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
    return '$count 레벨 상승 (최대 L$highestLevel)';
  }

  @override
  String levelUpCatchUpBannerYouLeveledUpTimes(Object length) {
    return '$length번 레벨업했습니다';
  }

  @override
  String levelUpCatchUpBannerYouLeveledUpTo(Object highestLevel) {
    return '레벨 $highestLevel로 레벨업했습니다!';
  }

  @override
  String get levelUpCatchYourRewardsAreAlready => '보상이 이미 인벤토리에 있습니다';

  @override
  String get levelUpContinue => '계속';

  @override
  String get levelUpDialogAccomplishments => '업적';

  @override
  String levelUpDialogLevelReward(Object level) {
    return '레벨 $level 보상';
  }

  @override
  String get levelUpDialogLevelUp => '레벨 업!';

  @override
  String levelUpDialogLevels(Object levelRange) {
    return '레벨 $levelRange';
  }

  @override
  String levelUpDialogNewRank(Object displayName) {
    return '새로운 랭크: $displayName';
  }

  @override
  String levelUpDialogNextMilestoneLevel(Object m) {
    return '다음 마일스톤: 레벨 $m';
  }

  @override
  String get levelUpDialogOpenCrate => '상자 열기';

  @override
  String levelUpDialogPartAccomplishmentNextRewardAtLevel(Object widget) {
    return '다음 보상 레벨 $widget';
  }

  @override
  String levelUpDialogPlayAgainBest(Object _bonusGameScore) {
    return '다시 플레이 · 최고 기록 $_bonusGameScore';
  }

  @override
  String levelUpDialogRank(Object displayName) {
    return '랭크: $displayName';
  }

  @override
  String levelUpDialogTier(Object displayName) {
    return '$displayName 티어';
  }

  @override
  String levelUpDialogX(Object displayName, Object quantity) {
    return '$displayName x$quantity';
  }

  @override
  String levelUpDialogXpEarned(Object xpEarned) {
    return '+$xpEarned XP 획득';
  }

  @override
  String get levelUpLevelUp => '레벨 업!';

  @override
  String get levelUpWhatSNext => '다음 단계';

  @override
  String get libraryLibrary => '라이브러리';

  @override
  String get libraryQuickAccessBrowseExercisesProgramsW =>
      '운동, 프로그램 및 운동 기록 탐색';

  @override
  String get libraryQuickAccessExerciseLibrary => '운동 라이브러리';

  @override
  String get librarySearchExercises => '운동 검색...';

  @override
  String lifetimeMemberBadgeDaysUntil(
    Object daysRemaining,
    Object nextTierName,
  ) {
    return '$nextTierName까지 $daysRemaining일';
  }

  @override
  String get lifetimeMemberBadgeEstimatedValueReceived => '예상 혜택 가치';

  @override
  String get lifetimeMemberBadgeLifetime => '평생';

  @override
  String get lifetimeMemberBadgeLifetime2 => '평생';

  @override
  String get lifetimeMemberBadgeMember => '멤버';

  @override
  String liquidBodyHydrationValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String get listWorkoutAddExercise => '운동 추가';

  @override
  String get listWorkoutFinish => '완료';

  @override
  String get listWorkoutNoSetsCompleted => '완료된 세트 없음';

  @override
  String get listWorkoutYouHavenTCompleted => '완료한 세트가 없습니다. 정말로 종료하시겠습니까?';

  @override
  String get liveChatAboutLiveChat => '실시간 채팅 정보';

  @override
  String get liveChatAreYouSureYou => '정말로 대화를 종료하시겠습니까? 나중에 새 채팅을 시작할 수 있습니다.';

  @override
  String get liveChatConnectWithOurSupport =>
      '실시간 지원을 위해 고객 지원 팀에 연결하세요. 상담원은 업무 시간 중에 질문이나 문제를 도와드릴 수 있습니다.';

  @override
  String get liveChatEndChat => '채팅을 종료할까요?';

  @override
  String get liveChatEndChat2 => '채팅 종료';

  @override
  String get liveChatFailedToConnectTo => '고객 지원 연결 실패';

  @override
  String get liveChatGotIt => '확인';

  @override
  String get liveChatInputAttachFile => '파일 첨부';

  @override
  String get liveChatInputTypeAMessage => '메시지 입력...';

  @override
  String get liveChatLiveChat => '실시간 채팅';

  @override
  String get liveChatMessageAgent => '상담원';

  @override
  String get liveChatTryAgain => '다시 시도';

  @override
  String get liveChatUnknownError => '알 수 없는 오류';

  @override
  String get livePrSnackbarNewPr => '새로운 PR!';

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
    return '현지화된 이름 $arg0';
  }

  @override
  String get locationSettingsAddALocationTo =>
      '자동 전환을 활성화하려면 체육관 프로필에 위치를 추가하세요. 프로필을 편집하고 \"위치 추가\"를 탭하세요.';

  @override
  String get locationSettingsAutoSwitchGymProfiles => '체육관 프로필 자동 전환';

  @override
  String get locationSettingsAutoSwitchNeedsAlways =>
      '자동 전환 기능을 사용하려면 체육관 도착을 감지하기 위해 \"항상\" 위치 권한이 필요합니다.';

  @override
  String get locationSettingsAutoSwitchProfiles => '프로필 자동 전환';

  @override
  String get locationSettingsBackgroundLocationRequired => '백그라운드 위치 권한 필요';

  @override
  String get locationSettingsGrantPermission => '권한 허용';

  @override
  String get locationSettingsLocationPermission => '위치 권한';

  @override
  String locationSettingsSectionActiveForGymS(Object length) {
    return '$length개 헬스장에서 활성화됨';
  }

  @override
  String locationSettingsSectionActiveForProfileS(Object length) {
    return '$length개 프로필에서 활성화됨';
  }

  @override
  String get locationSettingsSetAPreferredWorkout =>
      '시간 기반 전환을 활성화하려면 체육관 프로필에서 선호하는 운동 시간을 설정하세요.';

  @override
  String get locationSettingsTapToGrantPermission => '탭하여 권한 허용';

  @override
  String get locationSettingsTimeBasedSwitching => '시간 기반 전환';

  @override
  String get locationSettingsYourLocationIsOnly =>
      '귀하의 위치는 저장된 체육관과의 근접성을 확인하기 위해 로컬에서만 사용됩니다.';

  @override
  String get log1rmCurrent1rm => '현재 1RM:';

  @override
  String get log1rmEnterTheMaxWeight => '1회 수행한 최대 중량을 입력하세요';

  @override
  String get log1rmEstimated1rm => '추정 1RM';

  @override
  String get log1rmLog1rm => '로그 1RM';

  @override
  String get log1rmNewPr => '새로운 PR!';

  @override
  String get log1rmPleaseEnterAValid => '유효한 중량을 입력하세요';

  @override
  String get log1rmPleaseEnterAValid2 => '유효한 횟수를 입력하세요';

  @override
  String get log1rmRepsCompleted => '담당자 완료';

  @override
  String get log1rmRpeRateOfPerceived => 'RPE(인지된 활동률)';

  @override
  String get log1rmSave1rm => '저장 1RM';

  @override
  String log1rmSheetKg(Object widget) {
    return '$widget kg';
  }

  @override
  String log1rmSheetRpe(Object _rpe) {
    return 'RPE $_rpe';
  }

  @override
  String get log1rmWeightKg => '체중(kg)';

  @override
  String get logCardioActivityType => '활동 유형';

  @override
  String get logCardioAvgHr => '평균 HR';

  @override
  String get logCardioCaloriesBurned => '칼로리 소모량';

  @override
  String get logCardioDistance => '거리';

  @override
  String get logCardioDuration => '지속';

  @override
  String get logCardioHowDidTheSession => '세션의 느낌은 어땠나요? 어떤 메모라도...';

  @override
  String get logCardioLocation => '위치';

  @override
  String get logCardioLogCardio => '심장 강화 운동 기록';

  @override
  String get logCardioMaxHr => '최대 심박수';

  @override
  String get logCardioOptionalDetails => '선택사항 세부정보';

  @override
  String get logCardioSaveCardioSession => '심장 강화 세션 저장';

  @override
  String logCardioScreenSessionLogged(Object formattedDuration, Object label) {
    return '$label 세션 기록됨 - $formattedDuration';
  }

  @override
  String get logCardioWeatherConditions => '날씨 조건';

  @override
  String get logMealAiEstimatedNutrition => 'AI 추정 영양';

  @override
  String get logMealAllergens => '알레르기 유발 물질';

  @override
  String get logMealCalcium => '칼슘';

  @override
  String get logMealCalories => '칼로리';

  @override
  String get logMealCarbs => '탄수화물';

  @override
  String get logMealDiscard => '버리다';

  @override
  String get logMealDiscardAnalysis => '분석을 삭제하시겠습니까?';

  @override
  String get logMealEndFastLog => '빠른 종료 및 로그';

  @override
  String get logMealEndYourFast => '단식을 끝내시겠습니까?';

  @override
  String get logMealFat => '지방';

  @override
  String get logMealFiber => '섬유';

  @override
  String get logMealFoundProduct => '발견된 제품';

  @override
  String get logMealHealth => '건강';

  @override
  String get logMealHelpersEcoScore => '에코스코어';

  @override
  String logMealHelpersNova(Object group) {
    return 'NOVA $group ';
  }

  @override
  String get logMealHelpersNutriScore => '뉴트리스코어';

  @override
  String get logMealHelpersProcessingBreakdown => '처리 내역';

  @override
  String logMealHelpersValue(Object count, Object label) {
    return '$label ($count)';
  }

  @override
  String get logMealInflammation => '염증';

  @override
  String get logMealIngredients => '재료';

  @override
  String get logMealIron => '철';

  @override
  String get logMealLogOnly => '로그만';

  @override
  String get logMealLogThis => '이것을 기록하세요';

  @override
  String get logMealLogThisMeal => '이 식사를 기록하세요';

  @override
  String get logMealLoggingThisMealWill => '이 식사를 기록하면 단식이 종료됩니다. 계속하다?';

  @override
  String get logMealMagnesium => '마그네슘';

  @override
  String get logMealPotassium => '칼륨';

  @override
  String get logMealProtein => '단백질';

  @override
  String get logMealServings => '인분';

  @override
  String get logMealSheet => '•';

  @override
  String get logMealSheetAdd => '추가하다';

  @override
  String get logMealSheetAddABitMore => '좀 더 세부적인 내용을 추가하여 개선하세요.';

  @override
  String get logMealSheetAddAPhotoOr => '분석할 사진을 추가하거나 식사에 대해 설명하세요.';

  @override
  String get logMealSheetAddPhotos => '사진 추가';

  @override
  String get logMealSheetAddedTheFirst5 => '처음 5장의 사진을 추가했습니다(최대).';

  @override
  String get logMealSheetAiEstimatesFromA =>
      'AI는 사진을 통해 추정합니다. 나중에 결과를 구체화할 수 있습니다.';

  @override
  String get logMealSheetAllItemsMatchedVerified => '모든 항목이 검증된 영양 데이터와 일치합니다';

  @override
  String get logMealSheetAnalysisFailed => '분석에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get logMealSheetAnalyze => '분석하다';

  @override
  String get logMealSheetAnalyzing => '분석 중…';

  @override
  String get logMealSheetAnythingElseInThe =>
      '사진에는 ​​또 다른 게 있나요? (예: 아마씨, 유청 단백질)';

  @override
  String get logMealSheetBackToResults => '결과로 돌아가기';

  @override
  String get logMealSheetAddSauceOrSide => '소스나 사이드를 추가할까요?';

  @override
  String get logMealSheetAddSauceSide => '소스 / 항목 추가';

  @override
  String get logMealSheetBarcode => '바코드';

  @override
  String get logMealSheetBarcodeScan => '바코드 스캔';

  @override
  String get logMealSheetCached => '(캐시됨)';

  @override
  String get logMealSheetChooseFoodPhotos => '음식 사진 선택';

  @override
  String get logMealSheetChooseFromGallery => '갤러리에서 선택';

  @override
  String get logMealSheetChooseFromLibrary => '라이브러리에서 선택';

  @override
  String get logMealSheetChooseMenuPhotos => '메뉴 사진 선택';

  @override
  String get logMealSheetCoach => '코치';

  @override
  String get logMealSheetConfirmAnalyze => '확인 및 분석';

  @override
  String logMealSheetCouldnTAddFood(Object message) {
    return '음식 추가 실패: $message';
  }

  @override
  String get logMealSheetCouldnTApplyThat =>
      '해당 수정 사항을 적용할 수 없습니다. 식사는 변경되지 않습니다.';

  @override
  String get logMealSheetCouldnTLogThose => '해당 항목을 기록할 수 없습니다. 연결을 확인하세요.';

  @override
  String get logMealSheetCouldnTRecognizeAny => '해당 설명에서는 음식을 인식할 수 없습니다.';

  @override
  String logMealSheetCouldnTRefineError(Object message) {
    return '정제 실패: $message';
  }

  @override
  String get logMealSheetCouldnTSaveYour => '식사를 저장할 수 없습니다. 연결을 확인하세요.';

  @override
  String get logMealSheetCustomEG1 => '맞춤(예: 1.25)';

  @override
  String get logMealSheetDidnTCatchAny => '거기에서 음식을 잡지 못했습니다. 다시 시도해 보세요.';

  @override
  String get logMealSheetEGGrilledChicken => '예를 들어 \"닭갈비구이 반만 먹었어요\"';

  @override
  String get logMealSheetEnableMicrophoneAccessIn =>
      '설정에서 마이크 액세스를 활성화하거나 대신 검색에 식사를 입력하세요.';

  @override
  String get logMealSheetEstimatedNutrition => '추정 영양';

  @override
  String get logMealSheetEstimatesBasedOnYour => '사진/설명을 기반으로 한 추정치';

  @override
  String logMealSheetFailedToSaveError(Object error) {
    return '저장 실패: $error';
  }

  @override
  String get logMealSheetFrequentMeals => '자주 먹는 식사';

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
      '핸즈프리 로깅 — 자연스럽게 말하고, 텍스트를 검토한 후 확인하세요. 요리하는 동안 잘 작동합니다.';

  @override
  String get logMealSheetHeardEditIfNeeded => '인식됨 — 필요시 수정 후 확인하세요';

  @override
  String get logMealSheetHowManyServingsDid => '몇 인분 드셨나요?';

  @override
  String get logMealSheetImportALogFrom => 'MyFitnessPal, 크로노미터에서 로그 가져오기…';

  @override
  String get logMealSheetInstructionsOptional => '지침(선택사항)';

  @override
  String logMealSheetKcal(Object totalCalories) {
    return '$totalCalories kcal';
  }

  @override
  String logMealSheetL2Kcal(Object calories, Object timesLogged) {
    return '~$calories kcal · $timesLogged회 기록';
  }

  @override
  String logMealSheetL2Logged(Object timesLogged) {
    return '$timesLogged회 기록됨';
  }

  @override
  String logMealSheetL2SetToForThe(Object label) {
    return '해당 시간대의 $label(으)로 설정되었습니다. 식사 탭을 눌러 변경하세요.';
  }

  @override
  String logMealSheetL2YourUsual(Object label) {
    return '평소 드시는 $label';
  }

  @override
  String get logMealSheetListening => '청취…';

  @override
  String get logMealSheetLogManually => '수동으로 기록';

  @override
  String get logMealSheetLogThisMeal => '이 식사를 기록하세요';

  @override
  String logMealSheetLoggedItems(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 항목 기록됨',
      one: '1개 항목 기록됨',
    );
    return '$_temp0';
  }

  @override
  String logMealSheetLoggedPhotos(num count, Object kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사진 $count장 기록됨 ($kcal kcal)',
      one: '사진 1장 기록됨 ($kcal kcal)',
    );
    return '$_temp0';
  }

  @override
  String get logMealSheetLooksRight => '맞아요';

  @override
  String get logMealSheetMealRefined => '식사 정보 정제됨';

  @override
  String get logMealSheetMenu => '메뉴';

  @override
  String get logMealSheetMenuUpdated => '메뉴 업데이트됨';

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
  String get logMealSheetMicrophoneUnavailable => '마이크를 사용할 수 없음';

  @override
  String get logMealSheetNeedToAddNotes => '메모나 여러 장의 사진을 추가해야 합니까? 설명을 사용하세요.';

  @override
  String logMealSheetNutritionFor(Object servingsLabel) {
    return '$servingsLabel 영양 정보';
  }

  @override
  String get logMealSheetNutritionLabel => '영양 성분표';

  @override
  String get logMealSheetOneTapInstantNutrition => '한 번의 탭으로 즉시 영양 정보 확인';

  @override
  String get logMealSheetOverBudgetPickOne => '예산 초과 — 다음 중 하나를 선택하세요.';

  @override
  String get logMealSheetPhoto => '사진';

  @override
  String get logMealSheetPhotos => '사진';

  @override
  String get logMealSheetPickFromGallery => '갤러리에서 선택';

  @override
  String get logMealSheetPickUpTo5 => '라이브러리에서 최대 5개 선택';

  @override
  String get logMealSheetPlannedHighOutputDay =>
      '계획된 고출력일 - 이는 의도적으로 설계된 것입니다.';

  @override
  String get logMealSheetPortionsAdjustedReviewWei => '분량 조정됨 — 아래 중량을 검토하세요';

  @override
  String get logMealSheetReTakePhoto => '다시 촬영';

  @override
  String get logMealSheetReadMacrosOffA => '포장 식품 라벨에서 매크로 읽기';

  @override
  String get logMealSheetRefine => '구체화';

  @override
  String get logMealSheetReport => '보고서';

  @override
  String get logMealSheetSavedToFavorites => '즐겨찾기에 저장되었습니다!';

  @override
  String get logMealSheetSaving => '절약...';

  @override
  String get logMealSheetScan => '주사';

  @override
  String get logMealSheetScanAppScreenshot => '앱 스크린샷 스캔';

  @override
  String get logMealSheetScanFood => '음식 스캔';

  @override
  String get logMealSheetScanImport => '스캔 및 가져오기';

  @override
  String get logMealSheetScanMenu => '스캔 메뉴';

  @override
  String get logMealSheetScanNutritionLabel => '영양 성분표 스캔';

  @override
  String get logMealSheetScreenshot => '스크린샷';

  @override
  String get logMealSheetSearchFoods => '음식 검색';

  @override
  String get logMealSheetSnapAPhoto => '사진 촬영';

  @override
  String get logMealSheetSpeakNowTapMic => '말씀하세요... 마이크를 탭하여 중지';

  @override
  String get logMealSheetSpeechRecognitionNotAvailab => '음성 인식을 사용할 수 없음';

  @override
  String get logMealSheetStartingAnalysis => '분석 시작 중...';

  @override
  String get logMealSheetStopListening => '듣기 중지';

  @override
  String get logMealSheetTakeAPhoto => '사진 촬영';

  @override
  String get logMealSheetTakeFoodPhoto => '음식 사진 찍기';

  @override
  String get logMealSheetTakeMenuPhoto => '메뉴 사진 찍기';

  @override
  String get logMealSheetTakePhoto => '사진 촬영';

  @override
  String get logMealSheetTapAgainWhenYou => '완료되면 다시 탭하세요';

  @override
  String get logMealSheetTapHereToSave =>
      '식사를 일일 로그에 저장하려면 여기를 누르세요. 혼자 분석하면 기록되지 않습니다!';

  @override
  String get logMealSheetTapToConfirmEach => '탭하여 각각을 확인하거나 아래 목록에서 값을 편집하세요.';

  @override
  String get logMealSheetTapToSpeak => '탭하여 말하기';

  @override
  String get logMealSheetTellTheAiAnything =>
      '섭취량, 교체 횟수, 접시 크기 등 도움이 되는 모든 것을 AI에 알려주세요.';

  @override
  String get logMealSheetThatCorrectionProducedAn =>
      '그 수정으로 인해 빈 식사가 발생했으며 이전 추정치가 유지되었습니다.';

  @override
  String get logMealSheetThatLooksLikeA => '레시피처럼 보입니다. 레시피 가져오기 도구에 붙여넣으세요.';

  @override
  String get logMealSheetThisPhotoWasHard => '이 사진은 읽기 어렵습니다';

  @override
  String get logMealSheetTipAddBrandPortion =>
      '팁: 정확도를 높이려면 브랜드 및 부분을 추가하세요(예: \'치폴레 치킨 볼\' 또는 \'도미노 슬라이스 2개\')';

  @override
  String get logMealSheetTryAgain => '다시 시도';

  @override
  String get logMealSheetTypeItInstead => '대신 직접 입력';

  @override
  String logMealSheetUi1AddAnother(Object noun) {
    return '$noun 추가';
  }

  @override
  String logMealSheetUi1ThatCorrectionLooksOff(Object cals) {
    return '수정된 값이 이상합니다 ($cals kcal) — 이전 추정치를 유지했습니다.';
  }

  @override
  String logMealSheetUi2GProteinLeft(Object proteinRemaining) {
    return '단백질 ${proteinRemaining}g 남음';
  }

  @override
  String logMealSheetUi2KcalLeft(Object caloriesRemaining) {
    return '$caloriesRemaining kcal 남음';
  }

  @override
  String logMealSheetUi2PickUpTo(Object remaining) {
    return '최대 $remaining개 선택';
  }

  @override
  String logMealSheetUi2Value(Object length) {
    return '$length/5';
  }

  @override
  String logMealSheetUiGProteinLeft(Object proteinRemaining) {
    return '단백질 ${proteinRemaining}g 남음';
  }

  @override
  String logMealSheetUiKcalLeft(Object caloriesRemaining) {
    return '$caloriesRemaining kcal 남음';
  }

  @override
  String logMealSheetUiOfItemsMatchedVerified(
    Object length,
    Object verifiedCount,
  ) {
    return '$length개 항목 중 $verifiedCount개가 검증된 영양 데이터와 일치함';
  }

  @override
  String logMealSheetUiValue(Object description) {
    return '\"$description\"';
  }

  @override
  String logMealSheetUiValue2(Object dateLabel) {
    return '$dateLabel: ';
  }

  @override
  String get logMealSheetUndo => '끄르다';

  @override
  String get logMealSheetUpTo5Pages => '동일한 메뉴 최대 5페이지';

  @override
  String get logMealSheetUpTo5Photos => '최대 5장의 사진 — 더 추가하려면 한 장을 제거하세요.';

  @override
  String get logMealSheetUpTo5Shots => '최대 5장 — 사진 사이에 추가하세요';

  @override
  String get logMealSheetUse => '사용';

  @override
  String logMealSheetValue(Object servingLabel) {
    return '× $servingLabel';
  }

  @override
  String get logMealSheetVoiceInput => '음성 입력';

  @override
  String get logMealSheetWhatDidYouEat => '무엇을 먹었나요?';

  @override
  String logMealSheetYouVeBeenFasting(Object elapsedHours, Object elapsedMins) {
    return '$elapsedHours시간 $elapsedMins분 동안 단식 중입니다.';
  }

  @override
  String get logMealSugar => '설탕';

  @override
  String get logMealTheseValuesAreAi => '이 값은 설명을 기반으로 한 AI 추정치입니다.';

  @override
  String get logMealVitaminA => '비타민 A';

  @override
  String get logMealVitaminC => '비타민C';

  @override
  String get logMealVitaminD => '비타민 D';

  @override
  String get logMealVitaminsMinerals => '비타민 및 미네랄';

  @override
  String get logMealYouHavenTLogged => '아직 이 식사를 기록하지 않으셨습니다. 분석 결과가 손실됩니다.';

  @override
  String get logMealZinc => '아연';

  @override
  String get logMeasurementAnyNotesAboutThis => '이 측정에 대한 참고사항...';

  @override
  String get logMeasurementLogMeasurements => '로그 측정';

  @override
  String get logMeasurementMeasurementDate => '측정 날짜';

  @override
  String get logMeasurementMeasurementsSaved => '측정값이 저장되었습니다!';

  @override
  String get logMeasurementPleaseEnterAtLeast => '최소 하나의 측정값을 입력하세요';

  @override
  String logMeasurementSheetFailedToSave(Object e) {
    return '저장 실패: $e';
  }

  @override
  String get logPeriodEndDateOptional => '종료일(선택사항)';

  @override
  String get logPeriodEndToday => '오늘 종료';

  @override
  String get logPeriodLogANewPeriod => '새 생리 기록';

  @override
  String get logPeriodLogPeriod => '생리 기록';

  @override
  String get logPeriodOrStartANew => '— 또는 새로운 기간을 시작하세요 —';

  @override
  String get logPeriodPeriodInProgress => '생리 진행 중';

  @override
  String get logPeriodPeriodLogged => '생리 기록됨';

  @override
  String get logPeriodSavePeriod => '생리 저장';

  @override
  String get logPeriodSaving => '절약…';

  @override
  String logPeriodSheetCouldNotSave(Object e) {
    return '저장 실패: $e';
  }

  @override
  String logPeriodSheetStarted(Object cycleDates) {
    return '$cycleDates 시작';
  }

  @override
  String logPeriodSheetWithNoEnd(Object cycleDates) {
    return '$cycleDates (종료일 없음)';
  }

  @override
  String get logPeriodStartDateDay1 => '시작일(1일차)';

  @override
  String get logWeightAddANoteOptional => '메모 추가(선택사항)';

  @override
  String get logWeightBodyFatDidnT => '체지방이 저장되지 않았습니다 — 체중은 기록되었습니다';

  @override
  String get logWeightBodyFatOptional => '체지방률(선택사항)';

  @override
  String get logWeightContext => '문맥';

  @override
  String get logWeightCurrent => '현재의';

  @override
  String get logWeightEG185 => '예를 들어 18.5';

  @override
  String get logWeightEnterWeight => '체중 입력';

  @override
  String get logWeightHideDetails => '세부 정보 숨기기';

  @override
  String get logWeightIfThisWasA => '실수였다면 올바른 무게로 다시 기록하세요.';

  @override
  String get logWeightLogWeight => '로그 무게';

  @override
  String get logWeightMoreDetails => '세부 정보 더 보기';

  @override
  String get logWeightSaving => '절약...';

  @override
  String logWeightSheetDAvg(Object avgDisplay, Object label) {
    return '7일 평균 · $avgDisplay $label';
  }

  @override
  String logWeightSheetFromYourPreviousLow(Object _selectedUnit, Object label) {
    return '이전 최저치 대비 -$_selectedUnit $label';
  }

  @override
  String logWeightSheetValidRange(
    Object label,
    Object maxValue,
    Object minValue,
  ) {
    return '유효 범위: $minValue-$maxValue $label';
  }

  @override
  String get logWeightSyncedFromAppleHealth => 'Apple 건강에서 동기화됨';

  @override
  String get logWeightSyncedToAppleHealth => 'Apple 건강에 동기화됨';

  @override
  String get logWeightTapToEdit => '탭하여 수정';

  @override
  String get logWeightViewChart => '차트 보기';

  @override
  String get logWeightWeightChart => '체중 차트';

  @override
  String get logWeightWeightHistory => '체중 기록';

  @override
  String get logWeightWeightUpdate => '체중 업데이트';

  @override
  String get loggedMeals => '⚠️';

  @override
  String get loggedMeals1U00bc => '1/4';

  @override
  String get loggedMeals1U00bd => '1/2';

  @override
  String get loggedMeals1x => '1x';

  @override
  String get loggedMeals2x => '2x';

  @override
  String get loggedMeals3x => '3x';

  @override
  String get loggedMealsAddItem => '항목 추가';

  @override
  String get loggedMealsAddNote => '메모 추가';

  @override
  String get loggedMealsAddNote2 => '메모 추가';

  @override
  String get loggedMealsAddThisToShopping => '쇼핑 목록에 추가';

  @override
  String get loggedMealsAddToShoppingList => '쇼핑 목록에 추가';

  @override
  String get loggedMealsAdjustPortion => '분량 조절';

  @override
  String get loggedMealsAdjustPortion2 => '분량 조절';

  @override
  String get loggedMealsAfterEating => '식사 후';

  @override
  String get loggedMealsAmount => '양';

  @override
  String get loggedMealsBeforeEating => '식사 전';

  @override
  String get loggedMealsCG => '탄수화물 (g)';

  @override
  String get loggedMealsCal => '칼로리';

  @override
  String get loggedMealsCarbs => '탄수화물';

  @override
  String get loggedMealsContainsUltraProcessedItems => '초가공식품 포함';

  @override
  String get loggedMealsCopyTo => '복사...';

  @override
  String get loggedMealsCopyToAnotherMeal => '다른 식사로 복사';

  @override
  String get loggedMealsCurrent => '현재';

  @override
  String get loggedMealsDeleteMeal => '식사 삭제';

  @override
  String get loggedMealsDouble => '2배';

  @override
  String get loggedMealsEGAteAt => '예: 식당에서 식사, 집밥...';

  @override
  String get loggedMealsEGMedium1 => '예: 중간, 1컵, 350ml';

  @override
  String get loggedMealsEGSideSalad => '예: 사이드 샐러드';

  @override
  String get loggedMealsEGSweetTea => '예: 스위트 티';

  @override
  String get loggedMealsEdit => '편집';

  @override
  String get loggedMealsEditNote => '메모 수정';

  @override
  String get loggedMealsEditPortion => '분량 수정';

  @override
  String get loggedMealsEditTargets => '목표 수정';

  @override
  String get loggedMealsEditTime => '시간 수정';

  @override
  String get loggedMealsEnergyLevel => '에너지 수준';

  @override
  String get loggedMealsExamplesSoftDrinksInstant =>
      '예: 탄산음료, 인스턴트 라면, 포장 간식, 치킨 너겟, 대부분의 시리얼.';

  @override
  String get loggedMealsFG => '지방 (g)';

  @override
  String get loggedMealsFat => '지방';

  @override
  String get loggedMealsFodmap => 'FODMAP';

  @override
  String get loggedMealsFoodName => '음식 이름';

  @override
  String get loggedMealsHealthScore => '건강 점수';

  @override
  String get loggedMealsHideEditHistory => '수정 기록 숨기기';

  @override
  String get loggedMealsHowDidYouFeel => '기분이 어떠셨나요?';

  @override
  String get loggedMealsInflammationScore => '염증 점수';

  @override
  String get loggedMealsLarge => '대';

  @override
  String get loggedMealsLogAgainTomorrow => '내일 다시 기록';

  @override
  String get loggedMealsLogMoodEnergy => '기분 및 에너지 기록';

  @override
  String get loggedMealsLogThisAgainTomorrow => '내일 다시 기록';

  @override
  String get loggedMealsLooksOffTapTo => '잘못된 것 같나요? 탭하여 확인하세요';

  @override
  String get loggedMealsLowerIsBetterFor => '낮을수록 신체 염증 감소와 장 건강에 좋습니다.';

  @override
  String get loggedMealsMedium => '중';

  @override
  String get loggedMealsMicronutrients => '미량 영양소';

  @override
  String get loggedMealsMoveTo => '이동...';

  @override
  String get loggedMealsMoveToAnotherMeal => '다른 식사로 이동';

  @override
  String get loggedMealsNoEditsYet => '수정 기록 없음';

  @override
  String get loggedMealsNoFoodsLogged => '기록된 음식 없음';

  @override
  String get loggedMealsNutritionEditIfThe => '영양 성분 (AI가 잘못 인식했다면 수정하세요)';

  @override
  String get loggedMealsPG => '단백질 (g)';

  @override
  String get loggedMealsProtein => '단백질';

  @override
  String get loggedMealsQuantity => '수량';

  @override
  String get loggedMealsRatesHowInflammatoryA =>
      '가공 수준, 지방 프로필, 당 함량, 식이섬유 및 항산화 특성을 기반으로 음식의 염증 유발 정도를 평가합니다.';

  @override
  String get loggedMealsRemove => '제거';

  @override
  String get loggedMealsRemoveFromMeal => '식사에서 제거';

  @override
  String loggedMealsRemovedItem(Object name) {
    return '$name 삭제됨';
  }

  @override
  String get loggedMealsReportIncorrectData => '잘못된 데이터 신고';

  @override
  String get loggedMealsResearchLinksRegularConsump =>
      '연구에 따르면 정기적인 섭취는 염증, 비만, 심장 질환 및 소화기 문제 증가와 관련이 있습니다.';

  @override
  String get loggedMealsSaveAsRecipe => '레시피로 저장';

  @override
  String get loggedMealsSaveToMyFoods => '내 음식에 저장';

  @override
  String get loggedMealsScheduleRecurring => '반복 일정 설정...';

  @override
  String loggedMealsSectionCal(Object target, Object totalCaloriesEaten) {
    return '$totalCaloriesEaten / $target cal';
  }

  @override
  String loggedMealsSectionCal2(Object calories) {
    return '$calories cal';
  }

  @override
  String loggedMealsSectionCal3(Object food) {
    return '$food cal';
  }

  @override
  String loggedMealsSectionCopyTo(Object name) {
    return '$name 복사 대상...';
  }

  @override
  String loggedMealsSectionEaten(Object totalCaloriesEaten) {
    return '$totalCaloriesEaten 섭취';
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
    return '${totalCarbs}g C';
  }

  @override
  String loggedMealsSectionGF(Object totalFat) {
    return '${totalFat}g F';
  }

  @override
  String loggedMealsSectionGP(Object totalProtein) {
    return '${totalProtein}g P';
  }

  @override
  String loggedMealsSectionGProtein(Object proteinG) {
    return '단백질 ${proteinG}g';
  }

  @override
  String loggedMealsSectionGProtein2(Object food) {
    return '${food}g 단백질';
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
    return '$name 이동 대상...';
  }

  @override
  String loggedMealsSectionRemoved2(Object removedName) {
    return '$removedName 삭제됨';
  }

  @override
  String loggedMealsSectionRemoved3(Object name) {
    return '$name 삭제됨';
  }

  @override
  String loggedMealsSectionSwap(Object existingName) {
    return '$existingName 교체';
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
    return '$label을(를) 통해';
  }

  @override
  String get loggedMealsServings => '인분';

  @override
  String get loggedMealsSetACalorieTarget => '남은 칼로리를 추적하려면 목표 칼로리를 설정하세요';

  @override
  String get loggedMealsShareMeal => '식사 공유';

  @override
  String get loggedMealsSmall => '소형';

  @override
  String get loggedMealsStandard => '표준';

  @override
  String get loggedMealsSwapItem => '항목 교체';

  @override
  String get loggedMealsTriple => '3배';

  @override
  String get loggedMealsTypeAFoodAnd => '음식 이름을 입력하고 AI를 눌러 매크로를 자동 완성하세요';

  @override
  String get loggedMealsU00bd => '½';

  @override
  String get loggedMealsU00be => '¾';

  @override
  String get loggedMealsUltraProcessedFoods => '초가공식품';

  @override
  String get loggedMealsUltraProcessedFoodsNova =>
      '초가공식품(NOVA 그룹 4)에는 유화제, 경화유, 인공 감미료, 단백질 분리물 등 가정 요리에서 볼 수 없는 산업용 첨가물이 포함되어 있습니다.';

  @override
  String get loggedMealsUndo => '실행 취소';

  @override
  String get loggedMealsViewEditHistory => '수정 기록 보기';

  @override
  String get loggedMealsWeight => '체중';

  @override
  String get loggedMealsXLarge => '특대형';

  @override
  String get logoutAreYouSureYou => '정말 로그아웃하시겠습니까? 언제든지 다시 로그인할 수 있습니다.';

  @override
  String get logoutSignOut => '로그아웃';

  @override
  String get logoutSignOut2 => '로그아웃하시겠습니까?';

  @override
  String macroRingsCardGG(Object consumed, Object target) {
    return '${consumed}g / ${target}g';
  }

  @override
  String get macroRingsCardMacros => '매크로';

  @override
  String mainShellPartChatsLeftToday(Object arg0) {
    return '오늘 남은 채팅 $arg0회';
  }

  @override
  String get mainShellPartGuestMode => '게스트 모드';

  @override
  String get mainShellPartQuickActions => '빠른 작업';

  @override
  String get mainShellPartSignUp => '가입하기';

  @override
  String get mainShellPartSignUpFreeFor => '무제한 이용을 위해 무료로 가입하세요';

  @override
  String get manageDuplicateImportsCouldNotLoadDuplicate =>
      '중복 가져오기 항목을 불러올 수 없습니다';

  @override
  String get manageDuplicateImportsDuplicateImports => '중복 가져오기';

  @override
  String get manageDuplicateImportsHidden => '숨김';

  @override
  String get manageDuplicateImportsMakeThisPrimary => '기본값으로 설정';

  @override
  String get manageDuplicateImportsNoDuplicateImportsDetected =>
      '감지된 중복 가져오기 항목이 없습니다';

  @override
  String get manageDuplicateImportsPrimary => '기본';

  @override
  String manageDuplicateImportsScreenSources(Object length) {
    return '소스 $length개';
  }

  @override
  String manageDuplicateImportsScreenValue(Object primary) {
    return '$primary · ';
  }

  @override
  String get manageDuplicateImportsUnlinkFromGroup => '그룹에서 연결 해제';

  @override
  String get manageDuplicateImportsUnlinkedFromGroup => '그룹에서 연결 해제됨';

  @override
  String get manageGymProfilesActive => '활성';

  @override
  String get manageGymProfilesAddNewGym => '새 헬스장 추가';

  @override
  String get manageGymProfilesDeleteGymProfile => '헬스장 프로필을 삭제하시겠습니까?';

  @override
  String get manageGymProfilesDragToReorderTap => '드래그하여 순서 변경 • 탭하여 편집';

  @override
  String get manageGymProfilesDuplicate => '복제';

  @override
  String get manageGymProfilesManageGyms => '헬스장 관리';

  @override
  String get manageGymProfilesNoGymProfilesYet => '아직 헬스장 프로필이 없습니다';

  @override
  String get manageGymProfilesSetAsActive => '활성으로 설정';

  @override
  String manageGymProfilesSheetAreYouSureYou(Object name) {
    return '\"$name\"을(를) 삭제하시겠습니까?';
  }

  @override
  String manageGymProfilesSheetCreated(Object name) {
    return '\"$name\" 생성됨';
  }

  @override
  String manageGymProfilesSheetDeleted(Object name) {
    return '\"$name\" 삭제됨';
  }

  @override
  String manageGymProfilesSheetEquipment(
    Object environmentDisplayName,
    Object equipmentCount,
  ) {
    return '기구 $equipmentCount개 • $environmentDisplayName';
  }

  @override
  String get managedGymCardActive => '활성';

  @override
  String managedGymCardGymProfilesTapTo(Object profileCount) {
    return '짐 프로필 $profileCount개 · 탭하여 전환';
  }

  @override
  String get markFastingDay12h => '12h';

  @override
  String get markFastingDayEstimatedHours => '예상 시간';

  @override
  String get markFastingDayFastingDuration => '단식 시간';

  @override
  String get markFastingDayFastingProtocol => '단식 프로토콜';

  @override
  String get markFastingDayForgotToTrackA => '단식 기록을 잊으셨나요? 과거 날짜를 단식일로 표시하세요.';

  @override
  String get markFastingDayHowDidTheFast => '단식은 어떠셨나요?';

  @override
  String get markFastingDayMarkAsFastingDay => '단식일로 표시';

  @override
  String get markFastingDayMarkFastingDay => '단식일 표시';

  @override
  String get markFastingDayNotesOptional => '메모 (선택 사항)';

  @override
  String get markFastingDaySelectDate => '날짜 선택';

  @override
  String markFastingDaySheetHours(Object _estimatedHours) {
    return '$_estimatedHours시간';
  }

  @override
  String get markFastingDayYouCanMarkDays => '최근 30일 이내의 날짜만 표시할 수 있습니다';

  @override
  String masteriesGridLv(Object level) {
    return 'Lv.$level';
  }

  @override
  String get masteriesGridYourMasteriesWillLevel =>
      '운동, 걸음 수, 유산소 운동을 기록하면 마스터리 레벨이 올라갑니다.';

  @override
  String get mealPlannerAddARecipe => '레시피 추가';

  @override
  String get mealPlannerApply => '적용';

  @override
  String get mealPlannerCarbs => '탄수화물';

  @override
  String get mealPlannerCoachReview => '코치 검토';

  @override
  String get mealPlannerCustomItems => '사용자 지정 항목';

  @override
  String get mealPlannerEmptyTapToAdd => '(비어 있음 — +를 눌러 추가)';

  @override
  String get mealPlannerFat => '지방';

  @override
  String get mealPlannerGrocery => '식료품';

  @override
  String get mealPlannerMacroProjection => '매크로 예상치';

  @override
  String get mealPlannerPlanDay => '일일 계획';

  @override
  String get mealPlannerProtein => '단백질';

  @override
  String get mealPlannerRecipe => '레시피';

  @override
  String get mealPlannerSaveAsTemplate => '템플릿으로 저장';

  @override
  String get mealPlannerSavedAsTemplate => '템플릿으로 저장됨';

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
    return '$length개 항목 기록됨';
  }

  @override
  String mealPlannerScreenServings(Object servings) {
    return '×$servings 인분';
  }

  @override
  String get mealPlannerSearchYourRecipes => '레시피 검색…';

  @override
  String get mealPlannerType2Chars => '2자 이상 입력';

  @override
  String get mealRemindersSettingsActiveSchedules => '활성 일정';

  @override
  String get mealRemindersSettingsAutoSnapshotRecipeVersions => '레시피 버전 자동 스냅샷';

  @override
  String get mealRemindersSettingsDeleteSchedule => '일정을 삭제하시겠습니까?';

  @override
  String get mealRemindersSettingsMealReminderNotifications => '식사 알림';

  @override
  String get mealRemindersSettingsMealReminders => '식사 알림';

  @override
  String get mealRemindersSettingsNoSchedulesYetAdd =>
      '아직 일정이 없습니다. 레시피 상세 화면에서 추가하세요.';

  @override
  String get mealRemindersSettingsPublicSharingDefault => '공개 공유 기본값';

  @override
  String mealRemindersSettingsScreenCouldnTLoadSchedules(Object e) {
    return '일정을 불러올 수 없습니다: $e';
  }

  @override
  String mealRemindersSettingsScreenReminder(Object value) {
    return '$value개 알림';
  }

  @override
  String get mealRemindersSettingsSignInToSee => '로그인하여 일정을 확인하세요.';

  @override
  String get mealScoreWidgetsGoalFit => '목표 적합도';

  @override
  String get mealScoreWidgetsHealth => '건강';

  @override
  String mealScoreWidgetsValue(Object score) {
    return '$score/10';
  }

  @override
  String get measurementBodyMoreMetrics => '추가 지표';

  @override
  String measurementBodyViewMore(Object length) {
    return '+$length개 더 보기';
  }

  @override
  String get measurementDetailAddAnyNotes => '메모 추가...';

  @override
  String get measurementDetailAddEntry => '항목 추가';

  @override
  String get measurementDetailAvg => '평균';

  @override
  String get measurementDetailDeleteEntry => '항목을 삭제하시겠습니까?';

  @override
  String get measurementDetailHistory => '기록';

  @override
  String get measurementDetailImperial => '야드파운드법';

  @override
  String get measurementDetailMax => '최대';

  @override
  String get measurementDetailMetric => '미터법';

  @override
  String get measurementDetailMin => '최소';

  @override
  String get measurementDetailNoDataInThis => '이 기간에 데이터가 없습니다';

  @override
  String get measurementDetailNotesOptional => '메모 (선택 사항)';

  @override
  String get measurementDetailPleaseEnterAValid => '유효한 숫자를 입력하세요';

  @override
  String get measurementDetailPleaseEnterAValue => '값을 입력하세요';

  @override
  String measurementDetailScreenCouldnTSaveTry(Object displayName) {
    return '$displayName을(를) 저장할 수 없습니다. 다시 시도하세요.';
  }

  @override
  String measurementDetailScreenEntries(Object length) {
    return '기록 $length개';
  }

  @override
  String measurementDetailScreenLog(Object displayName) {
    return '$displayName 기록';
  }

  @override
  String measurementDetailScreenLog2(Object displayName) {
    return '$displayName 기록';
  }

  @override
  String get measurementDetailScreenMonthly => '월간';

  @override
  String get measurementDetailScreenNoHistoryYet => '아직 기록이 없습니다';

  @override
  String measurementDetailScreenRecorded(Object displayName) {
    return '$displayName 기록됨';
  }

  @override
  String get measurementDetailScreenRelatedMetrics => '관련 지표';

  @override
  String get measurementDetailScreenTrends => '추세';

  @override
  String measurementDetailScreenUiSourceGuideline(Object source) {
    return '출처: $source 가이드라인';
  }

  @override
  String measurementDetailScreenUiTrend(Object displayName) {
    return '$displayName 추이';
  }

  @override
  String get measurementDetailScreenWeekly => '주간';

  @override
  String get measurementDetailTrends => '추세';

  @override
  String get measurementDetailTrySelectingAWider =>
      '더 넓은 기간을 선택하거나 새 항목을 기록해 보세요';

  @override
  String get measurementDetailViewTrends => '추세 보기';

  @override
  String get measurementValuePillCouldNotSaveTry => '저장할 수 없습니다. 다시 시도하세요';

  @override
  String get measurementsAddEntry => '항목 추가';

  @override
  String get measurementsAddMeasurement => '측정값 추가';

  @override
  String get measurementsDeleteEntry => '항목을 삭제할까요?';

  @override
  String get measurementsFailedToLoadData => '데이터를 불러오지 못했습니다';

  @override
  String get measurementsImperial => '야드파운드법';

  @override
  String get measurementsLogAgainToSee => '추세를 보려면 다시 기록하세요';

  @override
  String get measurementsMeasurements => '측정값';

  @override
  String get measurementsMetric => '미터법';

  @override
  String measurementsScreenCouldnTSaveTry(Object displayName) {
    return '$displayName을(를) 저장할 수 없습니다. 다시 시도하세요.';
  }

  @override
  String measurementsScreenEntries(Object measurementsState) {
    return '$measurementsState개 항목';
  }

  @override
  String measurementsScreenHistory(Object displayName) {
    return '기록 - $displayName';
  }

  @override
  String measurementsScreenNoDataYet(Object displayName) {
    return '$displayName 데이터가 아직 없습니다.';
  }

  @override
  String get measurementsScreenPartAddAnyNotes => '메모 추가...';

  @override
  String measurementsScreenPartAddMeasurementSheetExportMeasurementTypesAs(
    Object _selectedFormat,
    Object length,
  ) {
    return 'Export (length)\") measurement types as .(_selectedFormat)';
  }

  @override
  String measurementsScreenPartAddMeasurementSheetLog(Object displayName) {
    return '$displayName 기록';
  }

  @override
  String get measurementsScreenPartAvailableMeasurementTypes => '사용 가능한 측정 유형';

  @override
  String get measurementsScreenPartClear => '지우기';

  @override
  String get measurementsScreenPartDateRange => '날짜 범위';

  @override
  String get measurementsScreenPartDeselectAll => '모두 선택 해제';

  @override
  String get measurementsScreenPartExportAllData => '모든 데이터 내보내기';

  @override
  String get measurementsScreenPartExportInfo => '내보내기 정보';

  @override
  String get measurementsScreenPartExportMeasurements => '측정값 내보내기';

  @override
  String get measurementsScreenPartExportedColumns => '내보낸 열';

  @override
  String get measurementsScreenPartFormat => '형식';

  @override
  String get measurementsScreenPartFormats => '형식';

  @override
  String get measurementsScreenPartGotIt => '확인';

  @override
  String get measurementsScreenPartImperial => '야드파운드법';

  @override
  String get measurementsScreenPartMeasurementType => '측정 유형';

  @override
  String get measurementsScreenPartMeasurements => '측정값';

  @override
  String get measurementsScreenPartMeasurementsOnly => '측정값만';

  @override
  String get measurementsScreenPartMetric => '미터법';

  @override
  String get measurementsScreenPartNotesOptional => '메모 (선택 사항)';

  @override
  String get measurementsScreenPartPleaseEnterAValid => '유효한 숫자를 입력하세요';

  @override
  String get measurementsScreenPartPleaseEnterAValue => '값을 입력하세요';

  @override
  String get measurementsScreenPartSelectAll => '모두 선택';

  @override
  String get measurementsScreenPartWeightBodyFatChest =>
      '체중, 체지방, 가슴, 허리, 엉덩이, 목, 어깨, 왼쪽 이두근, 오른쪽 이두근, 왼쪽 전완근, 오른쪽 전완근, 왼쪽 허벅지, 오른쪽 허벅지, 왼쪽 종아리, 오른쪽 종아리';

  @override
  String get measurementsScreenPartWorkoutsNutritionMeasureme =>
      '운동, 영양, 측정값 등';

  @override
  String measurementsScreenRecorded(Object displayName) {
    return '$displayName 기록됨';
  }

  @override
  String get measurementsScreenUiNoData => '데이터 없음';

  @override
  String get measurementsScreenUiNoHistoryYet => '아직 기록이 없습니다';

  @override
  String measurementsTabCouldnTSaveTry(Object displayName) {
    return '$displayName을(를) 저장할 수 없습니다. 다시 시도하세요.';
  }

  @override
  String measurementsTabLog(Object displayName) {
    return '$displayName 기록';
  }

  @override
  String measurementsTabLogToSeeTrends(Object displayName) {
    return '$displayName을(를) 기록하여 추이를 확인하세요';
  }

  @override
  String measurementsTabNoLogsInLast(Object displayName, Object periodLabel) {
    return '최근 $periodLabel 동안 $displayName 기록이 없습니다';
  }

  @override
  String get measurementsTabUiChooseMetric => '지표 선택';

  @override
  String get measurementsTabUiNoData => '데이터 없음';

  @override
  String measurementsTabUiValue(Object unit) {
    return '— $unit';
  }

  @override
  String measurementsTabValue(Object unit) {
    return '— $unit';
  }

  @override
  String get measurementsTakingLongerThanExpected => '예상보다 오래 걸리고 있습니다...';

  @override
  String get measurementsViewAll => '모두 보기';

  @override
  String mediaPickerHelperAccessHasBeenPermanently(Object permissionName) {
    return '$permissionName 접근 권한이 영구적으로 거부되었습니다.';
  }

  @override
  String get mediaPickerHelperAddMedia => '미디어 추가';

  @override
  String get mediaPickerHelperCameraPermissionRequired => '카메라 권한이 필요합니다';

  @override
  String get mediaPickerHelperChooseMultiplePhotos => '사진 여러 장 선택';

  @override
  String get mediaPickerHelperChoosePhoto => '사진 선택';

  @override
  String get mediaPickerHelperChooseVideo => '동영상 선택';

  @override
  String get mediaPickerHelperCompressingVideo => '동영상 압축 중...';

  @override
  String get mediaPickerHelperFromGallery => '갤러리에서 가져오기';

  @override
  String get mediaPickerHelperFromGalleryMax60s => '갤러리에서 가져오기 (최대 60초)';

  @override
  String get mediaPickerHelperImagesMax10Mb =>
      '이미지: 최대 10MB | 동영상: 최대 60초 (BETA)';

  @override
  String get mediaPickerHelperOpenSettings => '설정 열기';

  @override
  String mediaPickerHelperPermissionRequired(Object permissionName) {
    return '$permissionName 권한이 필요합니다';
  }

  @override
  String get mediaPickerHelperPhotoLibraryPermissionRequi => '사진 보관함 권한이 필요합니다';

  @override
  String get mediaPickerHelperRecordVideo => '동영상 촬영';

  @override
  String get mediaPickerHelperSelectUpTo5 => '갤러리에서 최대 5개 선택';

  @override
  String get mediaPickerHelperTakePhoto => '사진 촬영';

  @override
  String get mediaPickerHelperUseCamera => '카메라 사용';

  @override
  String get mediaPickerHelperUseCameraMax60s => '카메라 사용 (최대 60초)';

  @override
  String get mediaPickerHelperVideo => '동영상';

  @override
  String get mediaPreviewStripMediaRemoved => '미디어가 삭제되었습니다';

  @override
  String get mediaPreviewStripRemove => '삭제';

  @override
  String get mediaPreviewStripUndo => '실행 취소';

  @override
  String get medicalDisclaimerAiRecommendations => 'AI 추천';

  @override
  String get medicalDisclaimerAlwaysSeekTheAdvice =>
      '새로운 운동 프로그램을 시작하기 전, 특히 기존 질환, 부상 또는 건강상의 문제가 있는 경우 항상 의사나 기타 자격을 갖춘 의료 전문가의 조언을 구하세요. 이 앱에서 읽은 내용 때문에 전문적인 의학적 조언을 무시하거나 구하는 것을 미루지 마세요.';

  @override
  String get medicalDisclaimerAssumptionOfRisk => '위험 부담';

  @override
  String get medicalDisclaimerBannerAiGeneratedContentNot =>
      'AI 생성 콘텐츠 - 의학적 조언 아님';

  @override
  String get medicalDisclaimerConsultYourDoctor => '의사와 상담하세요';

  @override
  String get medicalDisclaimerImportantHealthNotice => '중요 건강 알림';

  @override
  String get medicalDisclaimerListenToYourBody => '내 몸의 신호에 귀 기울이세요';

  @override
  String get medicalDisclaimerMedicalDisclaimer => '의학적 면책 조항';

  @override
  String get medicalDisclaimerNotMedicalAdvice => '의학적 조언이 아님';

  @override
  String medicalDisclaimerScreenByContinuingToUse(Object appName) {
    return '$appName을(를) 계속 사용함으로써 귀하는 이 면책 조항을 읽고 이해했음을 인정합니다.';
  }

  @override
  String medicalDisclaimerScreenPhysicalExerciseInvolvesInherent(
    Object appName,
  ) {
    return '신체 운동에는 내재된 위험이 따릅니다. $appName을(를) 사용함으로써 귀하는 자발적으로 신체 활동에 참여하며 부상, 질병 또는 사망을 포함하되 이에 국한되지 않는 그러한 활동과 관련된 모든 위험을 감수함을 인정합니다.';
  }

  @override
  String medicalDisclaimerScreenPleaseReadThisDisclaimer(Object appName) {
    return '$appName을(를) 사용하기 전에 이 면책 조항을 주의 깊게 읽어주세요.';
  }

  @override
  String medicalDisclaimerScreenProvidesAiGeneratedFitness(Object appName) {
    return '$appName은(는) 정보 및 교육 목적으로만 AI 생성 피트니스 권장 사항을 제공합니다. 이 앱에서 제공하는 콘텐츠는 전문적인 의학적 조언, 진단 또는 치료를 대신할 수 없습니다.';
  }

  @override
  String get medicalDisclaimerStopExercisingImmediatelyIf =>
      '통증, 어지러움, 호흡 곤란, 메스꺼움 또는 일반적인 운동 범위를 벗어난 불편함이 느껴지면 즉시 운동을 중단하세요. AI는 실시간으로 사용자의 신체 상태를 평가할 수 없으므로, 자신의 한계 내에서 운동하는 것은 사용자의 책임입니다.';

  @override
  String get medicalDisclaimerWorkoutRecommendationsAreGe =>
      '운동 추천은 사용자가 제공한 정보(체력 수준, 목표, 장비 등)를 바탕으로 생성됩니다. AI는 정확성을 위해 노력하지만, 모든 개인적 요소를 고려할 수는 없습니다. 따라서 추천 내용이 모든 사람에게 적합하지 않을 수 있습니다.';

  @override
  String get menuAnalysisAddFood => '음식 추가';

  @override
  String get menuAnalysisAdding => '추가 중…';

  @override
  String get menuAnalysisAddressOptional => '주소 (선택 사항)';

  @override
  String get menuAnalysisAlreadySaved => '이미 저장됨';

  @override
  String get menuAnalysisAutoDetectedFromThe => '메뉴에서 자동 감지됨 — 잘못된 경우 수정하세요';

  @override
  String get menuAnalysisCal => '칼로리';

  @override
  String get menuAnalysisCarbs => '탄수화물';

  @override
  String get menuAnalysisClearAll => '모두 지우기';

  @override
  String get menuAnalysisClearFilters => '필터 초기화';

  @override
  String get menuAnalysisCouldnTRecognizeAny => '해당 설명에서 음식을 인식할 수 없습니다.';

  @override
  String get menuAnalysisEG123Main => '예: 123 Main St, 또는 \"시내\"';

  @override
  String get menuAnalysisEGIndianPlace => '예: 직장 근처 인도 식당';

  @override
  String get menuAnalysisEditSavedMenu => '저장된 메뉴 편집';

  @override
  String get menuAnalysisFat => '지방';

  @override
  String get menuAnalysisHistoryAddAddress => '주소 추가';

  @override
  String get menuAnalysisHistoryAddressOptional => '주소 (선택 사항)';

  @override
  String get menuAnalysisHistoryClearSearch => '검색 지우기';

  @override
  String get menuAnalysisHistoryCouldnTLoadYour => '저장된 메뉴를 불러올 수 없습니다';

  @override
  String get menuAnalysisHistoryEG123Main => '예: 123 Main St, 또는 \"시내\"';

  @override
  String get menuAnalysisHistoryEGIndianPlace => '예: 직장 근처 인도 식당';

  @override
  String get menuAnalysisHistoryEditDetails => '세부 정보 편집';

  @override
  String get menuAnalysisHistoryName => '이름';

  @override
  String get menuAnalysisHistoryNoMatchingMenus => '일치하는 메뉴 없음';

  @override
  String get menuAnalysisHistoryNoSavedMenusYet => '아직 저장된 메뉴가 없습니다';

  @override
  String get menuAnalysisHistoryPin => '고정';

  @override
  String get menuAnalysisHistorySavedMenus => '저장된 메뉴';

  @override
  String menuAnalysisHistoryScreenItems(Object length, Object type) {
    return '$length개 항목 · $type';
  }

  @override
  String menuAnalysisHistoryScreenNothingMatchedTryAnother(Object query) {
    return '\"$query\"와(과) 일치하는 항목이 없습니다. 다른 검색어를 시도하세요.';
  }

  @override
  String get menuAnalysisHistorySearchByNameRestaurant => '이름, 식당 또는 주소로 검색';

  @override
  String get menuAnalysisHistoryTapTheBookmarkButton =>
      '메뉴 스캔 후 북마크 버튼을 눌러 여기에 저장하세요.';

  @override
  String get menuAnalysisHistoryTryADifferentSearch => '다른 검색어를 시도해 보세요.';

  @override
  String get menuAnalysisHistoryUnpin => '고정 해제';

  @override
  String get menuAnalysisHistoryUseRestaurantName => '식당 이름 사용';

  @override
  String get menuAnalysisHistoryYouReOfflineThis => '오프라인 상태입니다 — 연결이 필요합니다';

  @override
  String get menuAnalysisItemAddedSugar => '첨가당';

  @override
  String get menuAnalysisItemAdjustWhatYouAte => '섭취량 조정';

  @override
  String get menuAnalysisItemAdjusted => '조정됨';

  @override
  String get menuAnalysisItemAllScoresGreen => '모든 점수 양호';

  @override
  String get menuAnalysisItemBloodSugar => '혈당';

  @override
  String menuAnalysisItemCardG(Object grams) {
    return '$grams g';
  }

  @override
  String menuAnalysisItemCardValue(Object s) {
    return '$s/10';
  }

  @override
  String get menuAnalysisItemFodmap => 'FODMAP';

  @override
  String get menuAnalysisItemFullBreakdown => '전체 분석';

  @override
  String get menuAnalysisItemInflammation => '염증';

  @override
  String get menuAnalysisItemPortion => '1인분';

  @override
  String get menuAnalysisItemUltraProcessed => '초가공식품';

  @override
  String get menuAnalysisLogged => '기록됨';

  @override
  String get menuAnalysisMenuUpdated => '메뉴 업데이트됨';

  @override
  String get menuAnalysisMore => '더 보기…';

  @override
  String get menuAnalysisName => '이름';

  @override
  String get menuAnalysisNameOptional => '이름 (선택 사항)';

  @override
  String get menuAnalysisNoDishesMatchYour => '필터와 일치하는 요리가 없습니다';

  @override
  String get menuAnalysisProtein => '단백질';

  @override
  String get menuAnalysisReScan => '다시 스캔';

  @override
  String get menuAnalysisReScanMenu => '메뉴 다시 스캔';

  @override
  String get menuAnalysisReScanThisMenu => '이 메뉴를 다시 스캔할까요?';

  @override
  String get menuAnalysisRecommendedForYou => '추천 메뉴';

  @override
  String get menuAnalysisRemove => '삭제';

  @override
  String get menuAnalysisRemoveFromSaved => '저장된 항목에서 삭제';

  @override
  String get menuAnalysisRemoveFromSaved2 => '저장된 항목에서 삭제할까요?';

  @override
  String get menuAnalysisRemovedFromSavedMenus => '저장된 메뉴에서 삭제됨';

  @override
  String get menuAnalysisResults => '결과';

  @override
  String get menuAnalysisSaveAsNew => '새로 저장';

  @override
  String get menuAnalysisSaveMenu => '메뉴 저장';

  @override
  String get menuAnalysisSaveThisMenu => '이 메뉴 저장';

  @override
  String get menuAnalysisSavedEdit => '저장됨 · 편집';

  @override
  String get menuAnalysisSavedMenus => '저장된 메뉴';

  @override
  String get menuAnalysisSavedToYourMenu => '메뉴 기록에 저장됨';

  @override
  String get menuAnalysisSearchDishes => '요리 검색';

  @override
  String menuAnalysisSheetCalGP(Object cal, Object protein) {
    return '$cal cal  ${protein}g P  ';
  }

  @override
  String menuAnalysisSheetCouldnTAddFood(Object message) {
    return '음식을 추가할 수 없습니다: $message';
  }

  @override
  String menuAnalysisSheetGCGF(Object carbs, Object fat) {
    return '${carbs}g C  ${fat}g F';
  }

  @override
  String menuAnalysisSheetGoal(Object displayName) {
    return '목표: $displayName';
  }

  @override
  String menuAnalysisSheetMore(Object extraCount) {
    return '더 보기 (+$extraCount)';
  }

  @override
  String menuAnalysisSheetMore2(Object extraCount) {
    return '$extraCount개 더';
  }

  @override
  String menuAnalysisSheetSelected(Object length) {
    return '$length개 선택됨';
  }

  @override
  String menuAnalysisSheetSort(Object label) {
    return '정렬: $label';
  }

  @override
  String menuAnalysisSheetValue2(Object rank) {
    return '#$rank';
  }

  @override
  String menuAnalysisSheetYouAlreadySavedA(Object restaurantName) {
    return '\"$restaurantName\"에 대한 메뉴를 이미 저장했습니다.';
  }

  @override
  String get menuAnalysisSort => '정렬:';

  @override
  String get menuAnalysisSort2 => '정렬';

  @override
  String get menuAnalysisTourAiPicksTheBest =>
      'AI가 남은 매크로, 알레르기 유발 물질 및 염증 내성을 고려하여 최고의 요리 3가지를 선정합니다.';

  @override
  String get menuAnalysisTourFilterByDietAllergens => '식단 및 알레르기 필터링';

  @override
  String get menuAnalysisTourHideDishesThatDon =>
      '식단에 맞지 않거나 알레르기 유발 물질이 포함된 요리를 숨깁니다. 설정에서 지정한 환경설정이 적용됩니다.';

  @override
  String get menuAnalysisTourRecommendedForYou => '추천 메뉴';

  @override
  String get menuAnalysisTourSelectDishesToLog => '기록할 요리 선택';

  @override
  String get menuAnalysisTourSortTheWholeMenu => '전체 메뉴 정렬';

  @override
  String get menuAnalysisTourTapProteinCarbsFat =>
      '단백질, 탄수화물, 지방 또는 염증을 탭하여 모든 요리의 순위를 즉시 다시 매길 수 있습니다. \'더 보기…\'를 누르면 고급 정렬 옵션이 열립니다.';

  @override
  String get menuAnalysisTourTickTheDishesYou =>
      '실제로 주문한 메뉴를 선택한 후, \'기록\'을 눌러 일일 총 섭취량에 추가하세요.';

  @override
  String get menuAnalysisUpdateExisting => '기존 항목 업데이트';

  @override
  String get menuAnalysisUpdatedYourSavedMenu => '저장된 메뉴가 업데이트되었습니다';

  @override
  String get menuAnalysisUseRestaurantName => '식당 이름 사용';

  @override
  String get menuAnalysisYouReOfflineThis =>
      '오프라인 상태입니다. 이 기능을 사용하려면 연결이 필요합니다.';

  @override
  String get menuDishAdjustAddABitMore => '더 정확한 결과를 위해 세부 정보를 추가하세요.';

  @override
  String get menuDishAdjustAdjustThisDish => '메뉴 조정';

  @override
  String get menuDishAdjustApply => '적용';

  @override
  String get menuDishAdjustCouldnTRefineThat =>
      '조정할 수 없습니다. 다른 단어로 다시 시도해 보세요.';

  @override
  String get menuDishAdjustHowMuchDidYou => '얼마나 드셨나요?';

  @override
  String get menuDishAdjustMenuMacrosAreAs =>
      '메뉴의 매크로는 \'제공량 기준\'입니다. 실제로 드신 양을 알려주세요.';

  @override
  String get menuDishAdjustOrDescribeIt => '또는 직접 설명하기';

  @override
  String get menuDishAdjustRefining => '조정 중…';

  @override
  String menuDishAdjustSheetThisDishCalG(Object previewCal, Object previewP) {
    return '이 요리: ~$previewCal cal · ${previewP}g 단백질';
  }

  @override
  String get menuFilterAdvancedFilters => '고급 필터';

  @override
  String get menuFilterAppliesOnlyToDishes => '가격이 표시된 메뉴에만 적용됩니다.';

  @override
  String get menuFilterAvoid => '피하기';

  @override
  String get menuFilterBasedOnIngredientProfile =>
      '성분 프로필(오메가-3, 식이섬유, 첨가당 등) 기준.';

  @override
  String get menuFilterBloodSugar => '혈당';

  @override
  String get menuFilterCaloriesAtMost => '최대 칼로리';

  @override
  String get menuFilterCarbsAtMost => '최대 탄수화물';

  @override
  String get menuFilterCoachSVerdict => '코치의 평가';

  @override
  String get menuFilterDiet => '식단';

  @override
  String get menuFilterFatAtMost => '최대 지방';

  @override
  String get menuFilterFilters => '필터';

  @override
  String get menuFilterFineTuneMacros => '매크로 미세 조정';

  @override
  String get menuFilterFodmapIbs => 'FODMAP (IBS)';

  @override
  String get menuFilterForSpecificTargetsMost =>
      '특정 목표를 위한 설정입니다. 대부분의 경우 필요하지 않습니다.';

  @override
  String get menuFilterGlycemicLoadPerServing =>
      '1회 제공량당 혈당 부하 — 낮을수록 에너지가 안정적입니다.';

  @override
  String get menuFilterGood => '✅ 좋음';

  @override
  String get menuFilterHideAdvancedFilters => '고급 필터 숨기기';

  @override
  String get menuFilterHideDishesWithMy => '알레르기 유발 성분이 포함된 메뉴 숨기기';

  @override
  String get menuFilterHideUltraProcessedDishes => '초가공 식품 숨기기';

  @override
  String get menuFilterHowTheAiRated => 'AI가 목표에 따라 각 메뉴를 평가한 방식입니다.';

  @override
  String get menuFilterInflammation => '염증';

  @override
  String get menuFilterMaxPrice => '최대 가격';

  @override
  String get menuFilterMenuSections => '메뉴 섹션';

  @override
  String get menuFilterNoDishesMatch => '일치하는 메뉴가 없습니다';

  @override
  String get menuFilterOkay => '👌 보통';

  @override
  String get menuFilterOnionGarlicWheatLactose =>
      '양파, 마늘, 밀, 유당은 IBS 증상을 유발할 수 있습니다.';

  @override
  String get menuFilterPerDishBudget => '메뉴당 예산';

  @override
  String get menuFilterProteinAtLeast => '최소 단백질';

  @override
  String get menuFilterReset => '초기화';

  @override
  String menuFilterSheetShowAllDishes(Object total) {
    return '모든 요리 $total개 보기';
  }

  @override
  String menuFilterSheetShowOfDishes(Object matches, Object total) {
    return '요리 $total개 중 $matches개 보기';
  }

  @override
  String get menuFilterShowOnlyCertainParts => '메뉴의 특정 부분만 표시합니다.';

  @override
  String get menuFilterSkip => '⚠️ 건너뛰기';

  @override
  String get menuFilterSkipsNova4Foods => 'NOVA-4 식품(산업용 유화제, 액상과당 등) 제외';

  @override
  String get menuFilterTapAnyThatApply => '해당하는 항목을 선택하세요. 일치하는 메뉴만 표시됩니다.';

  @override
  String get menuFilterUsesYourSavedAllergen => '저장된 알레르기 프로필 사용';

  @override
  String get menuFilterWeLlHideDishes => '식단에 맞지 않는 메뉴는 숨겨집니다.';

  @override
  String get menuFilterWhatAreYouIn => '어떤 음식이 당기시나요?';

  @override
  String get merchClaimsAcceptReward => '보상 수락';

  @override
  String merchClaimsAcceptedWeWillBeIn(Object displayName) {
    return '$displayName 수락 완료! 곧 연락드리겠습니다.';
  }

  @override
  String get merchClaimsCancelReward => '보상 취소';

  @override
  String get merchClaimsCancelThisReward => '이 보상을 취소할까요?';

  @override
  String get merchClaimsCarrier => '배송업체';

  @override
  String merchClaimsClaimYour(Object displayName) {
    return '$displayName을(를) 받으시겠습니까?';
  }

  @override
  String get merchClaimsDeliveryDetails => '배송 정보';

  @override
  String merchClaimsFailedToAccept(Object error) {
    return '수락 실패: $error';
  }

  @override
  String merchClaimsFailedToCancel(Object error) {
    return '취소 실패: $error';
  }

  @override
  String get merchClaimsFailedToLoadMerch => '상품 보상 정보를 불러오지 못했습니다';

  @override
  String get merchClaimsFailedToUpdateTry => '업데이트에 실패했습니다. 다시 시도하세요.';

  @override
  String get merchClaimsKeepIt => '유지하기';

  @override
  String get merchClaimsMerchNotifications => '상품 알림';

  @override
  String get merchClaimsMerchRewards => '상품 보상';

  @override
  String get merchClaimsNoMerchUnlockedYet => '아직 잠금 해제된 상품이 없습니다';

  @override
  String get merchClaimsNotNow => '나중에';

  @override
  String get merchClaimsPushEmailAlertsWhen =>
      '상품 등급 달성 임박 시 또는 보상 대기 시 푸시 및 이메일 알림';

  @override
  String get merchClaimsRealRewardsForReal => '진정한 성장을 위한 실질적인 보상';

  @override
  String get merchClaimsRewardAcceptedWeLl =>
      '보상이 수락되었습니다! 배송 정보 수집을 위해 이메일을 보내드리겠습니다.';

  @override
  String get merchClaimsRewardCancelled => '보상이 취소되었습니다.';

  @override
  String merchClaimsScreenDelivered(Object claim) {
    return '배달 완료: $claim';
  }

  @override
  String merchClaimsScreenKeepAnEyeOn(Object appName) {
    return '$appName 계정에 연결된 이메일을 확인해 주세요.';
  }

  @override
  String merchClaimsScreenReachMilestoneLevelsAnd(Object appName) {
    return '마일스톤 레벨에 도달하면 실제 $appName 굿즈를 보내드립니다.';
  }

  @override
  String merchClaimsScreenShipped(Object claim) {
    return '배송됨: $claim';
  }

  @override
  String merchClaimsScreenValue(Object displayName, Object statusLabel) {
    return '$displayName — $statusLabel';
  }

  @override
  String merchClaimsScreenYourFirstPhysicalReward(Object appName) {
    return '레벨 50 달성 시 첫 번째 실물 보상인 $appName 스티커 팩이 잠금 해제됩니다.';
  }

  @override
  String get merchClaimsTapAcceptToClaim =>
      '수락을 눌러 보상을 받으세요. 배송 준비가 되면 사이즈와 배송지 주소를 확인하는 이메일을 보내드립니다.';

  @override
  String get merchClaimsTracking => '운송장 번호';

  @override
  String merchClaimsUnlockedAtLevel(Object level) {
    return '레벨 $level에서 잠금 해제';
  }

  @override
  String get merchClaimsViewTracking => '배송 조회';

  @override
  String get merchClaimsWeLlEmailYou => '몇 주 내로 이메일을 통해 다음 정보를 수집할 예정입니다:';

  @override
  String merchClaimsYouWillForfeit(Object displayName, Object level) {
    return '$displayName(레벨 $level)을(를) 포기하게 됩니다. 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get messagesCouldNotLoadYour => '대화 목록을 불러올 수 없습니다.\n나중에 다시 시도해 주세요.';

  @override
  String get messagesFailedToLoadMessages => '메시지를 불러오지 못했습니다';

  @override
  String get messagesNewGroup => '새 그룹';

  @override
  String get messagesNoMessagesYet => '아직 메시지가 없습니다';

  @override
  String get messagesNotLoggedIn => '로그인되지 않음';

  @override
  String get messagesPleaseLogInTo => '메시지를 보려면 로그인하세요';

  @override
  String get messagesStartAConversationWith =>
      '친구와 대화를 시작해 보세요!\n메시지가 여기에 표시됩니다.';

  @override
  String get metricHistoryCardNoDataForThis => '이 날짜에 대한 데이터가 없습니다';

  @override
  String get metricHistoryCardTrendUnavailable => '추세를 확인할 수 없습니다.';

  @override
  String get metricHistoryCardTwoOrMoreSynced =>
      '추세를 차트로 보려면 2일 이상의 데이터가 동기화되어야 합니다.';

  @override
  String get metricPickerChooseAMetric => '지표 선택';

  @override
  String get metricPickerRecentlyUsed => '최근 사용';

  @override
  String metricPickerSheetNoMetricMatches(Object text) {
    return '“$text”와 일치하는 지표가 없습니다';
  }

  @override
  String metricPickerSheetResults(Object length) {
    return '$length개의 결과';
  }

  @override
  String metricPickerSheetSearchMetrics(Object length) {
    return '$length개의 지표 검색…';
  }

  @override
  String get metricsDashboardActiveStreak => '현재 연속 기록';

  @override
  String get metricsDashboardAddEntry => '기록 추가';

  @override
  String get metricsDashboardAddMetric => '지표 추가';

  @override
  String get metricsDashboardBmi => 'BMI';

  @override
  String get metricsDashboardBodyFat => '체지방';

  @override
  String get metricsDashboardBodyFatPct => '체지방률';

  @override
  String get metricsDashboardCalories => '칼로리';

  @override
  String get metricsDashboardCaloriesBurned => '소모 칼로리';

  @override
  String get metricsDashboardEnterValue => '값 입력';

  @override
  String get metricsDashboardHealthMetrics => '건강 지표';

  @override
  String get metricsDashboardHeartRate => '심박수';

  @override
  String get metricsDashboardHip => '엉덩이 둘레';

  @override
  String get metricsDashboardMetricType => '지표 유형';

  @override
  String get metricsDashboardMuscleMass => '근육량';

  @override
  String get metricsDashboardNoDataAvailable => '사용 가능한 데이터 없음';

  @override
  String metricsDashboardNoMetricDataYet(Object arg0) {
    return '$arg0 데이터가 아직 없습니다';
  }

  @override
  String get metricsDashboardQuickStats => '빠른 통계';

  @override
  String get metricsDashboardRestingHeartRate => '안정 시 심박수';

  @override
  String get metricsDashboardRestingHr => '안정 시 심박수';

  @override
  String get metricsDashboardSave => '저장';

  @override
  String get metricsDashboardTotalTime => '총 시간';

  @override
  String get metricsDashboardTrackYourProgressOver => '시간에 따른 진행 상황 추적';

  @override
  String get metricsDashboardValue => '값';

  @override
  String get metricsDashboardWaist => '허리 둘레';

  @override
  String get metricsDashboardWeight => '체중';

  @override
  String get metricsDashboardWorkoutsThisWeek => '이번 주 운동';

  @override
  String get micronutrientsNoMicronutrientDataAvailabl =>
      '사용 가능한 미량 영양소 데이터 없음';

  @override
  String get micronutrientsVitaminsMinerals => '비타민 및 미네랄';

  @override
  String get milestoneCelebrationCopy => '복사';

  @override
  String milestoneCelebrationDialogPts(Object points) {
    return '+$points PTS';
  }

  @override
  String get milestoneCelebrationMilestoneAchieved => '마일스톤 달성!';

  @override
  String get milestoneCelebrationShareYourAchievement => '성과 공유하기';

  @override
  String get milestonesAchieved => '달성함';

  @override
  String get milestonesAll => '전체';

  @override
  String get milestonesMilestone => '마일스톤';

  @override
  String get milestonesMilestones => '마일스톤';

  @override
  String get milestonesNextMilestone => '다음 마일스톤';

  @override
  String get milestonesPoints => '포인트';

  @override
  String get milestonesPoints2 => '포인트';

  @override
  String milestonesScreenPts(Object points) {
    return '$points pts';
  }

  @override
  String milestonesScreenUiAchieved(Object totalAchieved) {
    return '달성 ($totalAchieved)';
  }

  @override
  String milestonesScreenUiAverageMinWorkout(
    Object averageWorkoutDurationMinutes,
  ) {
    return '평균: $averageWorkoutDurationMinutes 분/운동';
  }

  @override
  String get milestonesScreenUiCompleteWorkoutsToSee => '운동을 완료하고 ROI를 확인하세요';

  @override
  String milestonesScreenUiKg(Object totalWeightLiftedKg) {
    return '$totalWeightLiftedKg kg';
  }

  @override
  String get milestonesScreenUiNoDataYet => '아직 데이터 없음';

  @override
  String get milestonesScreenUiUpcoming => '예정';

  @override
  String milestonesScreenValue(Object next) {
    return '$next%';
  }

  @override
  String milestonesScreenValue2(Object progress) {
    return '$progress%';
  }

  @override
  String get milestonesTotalWorkouts => '총 운동 횟수';

  @override
  String get milestonesYourJourney => '나의 여정';

  @override
  String get milestonesYourRoi => '나의 ROI';

  @override
  String get minimalHeaderChangeGymProfile => '헬스장 프로필 변경';

  @override
  String get minimalHeaderCollapseWeekStrip => '주간 스트립 접기';

  @override
  String minimalHeaderD(Object streakDays) {
    return '$streakDays일';
  }

  @override
  String get minimalHeaderExpandWeekStrip => '주간 스트립 확장';

  @override
  String get minimalHeaderHideDayStrip => '일간 스트립 숨기기';

  @override
  String get minimalHeaderMySpace => '마이 스페이스';

  @override
  String get minimalHeaderShowDayStrip => '일간 스트립 보기';

  @override
  String get missedWorkoutBannerDoToday => '오늘 하기';

  @override
  String missedWorkoutBannerExercises(Object exercisesCount) {
    return '운동 $exercisesCount개';
  }

  @override
  String missedWorkoutBannerMin(Object durationMinutes) {
    return '$durationMinutes분';
  }

  @override
  String get missedWorkoutBannerMissedWorkout => '놓친 운동';

  @override
  String missedWorkoutBannerMoreMissedWorkouts(Object missedList) {
    return '외 $missedList개의 놓친 운동';
  }

  @override
  String get missedWorkoutBannerSkipIt => '건너뛰기';

  @override
  String get missedWorkoutBannerSkipWithoutReason => '이유 없이 건너뛰기';

  @override
  String get missedWorkoutBannerThisHelpsUsAdjust => '일정 조정에 도움이 됩니다';

  @override
  String get missedWorkoutBannerWhyAreYouSkipping => '왜 건너뛰시나요?';

  @override
  String get missedWorkoutBannerWorkoutSkipped => '운동 건너뜀';

  @override
  String missedWorkoutBannerYouMissed(Object dayPossessive, Object name) {
    return '$dayPossessive $name을(를) 놓쳤습니다';
  }

  @override
  String get moodAnalyticsCardCheckIns => '체크인';

  @override
  String get moodAnalyticsCardCompleted => '완료됨';

  @override
  String get moodAnalyticsCardMoodDistribution => '기분 분포';

  @override
  String get moodAnalyticsCardMostCommonMood => '가장 흔한 기분';

  @override
  String moodAnalyticsCardValue(Object completionRate) {
    return '$completionRate%';
  }

  @override
  String moodAnalyticsCardValue2(Object percentage) {
    return '$percentage%';
  }

  @override
  String get moodCalendarHeatmapDaysTracked => '기록된 일수';

  @override
  String get moodCalendarHeatmapFailedToLoadCalendar => '캘린더를 불러오지 못했습니다';

  @override
  String get moodCalendarHeatmapGood => '좋음';

  @override
  String get moodCalendarHeatmapGreat => '최고';

  @override
  String get moodCalendarHeatmapMostCommon => '가장 흔함';

  @override
  String get moodCalendarHeatmapStressed => '스트레스';

  @override
  String get moodCalendarHeatmapTired => '피곤함';

  @override
  String get moodCalendarHeatmapTotalCheckIns => '총 체크인';

  @override
  String get moodCardBias => '편향';

  @override
  String get moodCardInt => '강도';

  @override
  String moodCardIntensity(Object mood) {
    return '$mood - 강도';
  }

  @override
  String get moodCardMood => '기분';

  @override
  String get moodCardMoodMultipliers => '기분 배수';

  @override
  String get moodCardResetAll => '모두 재설정';

  @override
  String get moodCardRest => '휴식';

  @override
  String moodCardRest2(Object mood) {
    return '$mood - 휴식';
  }

  @override
  String get moodCardTapCellsToTune => '셀을 탭하여 기분 기반 조정';

  @override
  String get moodCardVol => '볼륨';

  @override
  String moodCardVolume(Object mood) {
    return '$mood - 볼륨';
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
  String get moodHistoryCheckInHistory => '체크인 기록';

  @override
  String get moodHistoryInsightsSuggestions => '인사이트 및 제안';

  @override
  String moodHistoryItemCardFeeling(Object mood) {
    return '$mood 기분';
  }

  @override
  String get moodHistoryItemMoodWorkout => '기분 맞춤 운동';

  @override
  String get moodHistoryMoodHistoryAnalysis => '기분 기록 및 분석';

  @override
  String get moodHistoryNoMoodCheckIns => '아직 기분 체크인 기록 없음';

  @override
  String moodHistoryScreenLastDays(Object daysTracked) {
    return '지난 $daysTracked일';
  }

  @override
  String moodHistoryScreenTotal(Object totalCount) {
    return '총 $totalCount개';
  }

  @override
  String get moodHistoryStartTrackingYourMood =>
      '기분을 기록하고 맞춤형 운동 제안을 받으며 시간 경과에 따른 패턴을 확인하세요.';

  @override
  String get moodHistoryYourMoodInsights => '나의 기분 인사이트';

  @override
  String get moodPickerAdvancedOptions => '고급 옵션';

  @override
  String get moodPickerCardGeneratingYourWorkout => '운동 생성 중...';

  @override
  String moodPickerCardGeneratingYourWorkout2(Object label) {
    return '$label 운동을 생성 중입니다...';
  }

  @override
  String get moodPickerCardGenerationFailed => '생성 실패';

  @override
  String get moodPickerCardGetAWorkoutFor => '기분에 맞는 운동 받기';

  @override
  String get moodPickerCardHowAreYouFeeling => '오늘 기분이 어떠신가요?';

  @override
  String get moodPickerCardSomethingWentWrong => '문제가 발생했습니다';

  @override
  String moodPickerCardStepOf(Object currentStep, Object totalSteps) {
    return '$currentStep단계 / $totalSteps단계';
  }

  @override
  String moodPickerCardStepOf2(Object currentStep, Object totalSteps) {
    return '$currentStep단계 / $totalSteps단계';
  }

  @override
  String get moodPickerCardTryAgain => '다시 시도';

  @override
  String get moodPickerCouldnTSaveYour => '기분 데이터를 저장하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get moodPickerGenerateWorkout => '운동 생성';

  @override
  String get moodPickerHowAreYouFeeling => '오늘 기분은 어떠신가요?';

  @override
  String get moodPickerJustLogMood => '기분만 기록';

  @override
  String get moodPickerResetToRecommended => '권장 설정으로 초기화';

  @override
  String moodPickerSheetFailedToGenerateWorkout(Object e) {
    return '운동 생성 실패: $e';
  }

  @override
  String moodPickerSheetMin(Object _effectiveDuration) {
    return '$_effectiveDuration분';
  }

  @override
  String moodPickerSheetMood(Object description, Object label) {
    return '$label 기분. $description';
  }

  @override
  String moodPickerSheetMoodLogged(Object label) {
    return '기분 기록됨: $label';
  }

  @override
  String get moodPickerViewHistoryAnalysis => '기록 및 분석 보기';

  @override
  String get moodStreakCardBestStreak => '최고 연속 기록';

  @override
  String get moodStreakCardCurrentStreak => '현재 연속 기록';

  @override
  String get moodWeeklyChartAvgScore => '평균 점수';

  @override
  String get moodWeeklyChartCheckIns => '체크인';

  @override
  String get moodWeeklyChartDaysActive => '활동 일수';

  @override
  String get moodWeeklyChartDeclining => '하락 중';

  @override
  String get moodWeeklyChartFailedToLoadMood => '기분 데이터를 불러오지 못했습니다';

  @override
  String get moodWeeklyChartImproving => '향상 중';

  @override
  String get moodWeeklyChartMoodTrends => '기분 추이';

  @override
  String get moodWeeklyChartNoMoodDataThis => '이번 주 기분 데이터가 없습니다';

  @override
  String get moodWeeklyChartStable => '안정적';

  @override
  String get moodWeeklyChartStartTrackingYourMood => '기분을 기록하고 추이를 확인해 보세요';

  @override
  String moodWeeklyChartValue(Object length) {
    return '$length/7';
  }

  @override
  String get morningRecoveryNudgeBody =>
      '오늘 컨디션이 낮습니다. 볼륨을 줄입니다 — 재생성하려면 앱을 여세요.';

  @override
  String get morningRecoveryNudgeTitle => '오늘은 천천히 가세요';

  @override
  String get motivationalTemplateCompleted => '완료';

  @override
  String get muscleAnalyticsAllowRecovery => '회복 허용';

  @override
  String get muscleAnalyticsBalance => '균형';

  @override
  String get muscleAnalyticsBalanceRatios => '균형 비율';

  @override
  String get muscleAnalyticsBalanceScore => '균형 점수';

  @override
  String get muscleAnalyticsBalanced => '균형 잡힘';

  @override
  String get muscleAnalyticsCompleteMoreWorkoutsTo =>
      '더 많은 운동을 완료하여 근육 균형 분석을 확인하세요.';

  @override
  String get muscleAnalyticsCompleteSomeWorkoutsTo =>
      '운동을 완료하여 근육 훈련 히트맵을 확인하세요.';

  @override
  String get muscleAnalyticsCompleteWorkoutsOverMultipl =>
      '여러 주에 걸쳐 운동을 완료하여 훈련 빈도를 확인하세요.';

  @override
  String get muscleAnalyticsFrequency => '빈도';

  @override
  String get muscleAnalyticsHeatmap => '히트맵';

  @override
  String get muscleAnalyticsImbalanced => '불균형';

  @override
  String get muscleAnalyticsLeastTrained => '가장 적게 훈련됨';

  @override
  String get muscleAnalyticsMostTrained => '가장 많이 훈련됨';

  @override
  String get muscleAnalyticsMuscleBreakdown => '근육 분석';

  @override
  String get muscleAnalyticsMuscleTrends => '근육 추이';

  @override
  String get muscleAnalyticsNeedsWork => '보완 필요';

  @override
  String get muscleAnalyticsNoBalanceData => '균형 데이터 없음';

  @override
  String get muscleAnalyticsNoFrequencyData => '빈도 데이터 없음';

  @override
  String get muscleAnalyticsNoTrainingData => '훈련 데이터 없음';

  @override
  String get muscleAnalyticsOvertrained => '과훈련';

  @override
  String get muscleAnalyticsPushPull => 'Push / Pull';

  @override
  String get muscleAnalyticsRecommendations => '권장 사항';

  @override
  String muscleAnalyticsScreenKg(Object balance) {
    return '$balance kg';
  }

  @override
  String get muscleAnalyticsTrainMore => '더 훈련하기';

  @override
  String get muscleAnalyticsTrainingIntensity => '훈련 강도';

  @override
  String get muscleAnalyticsUndertrained => '훈련 부족';

  @override
  String get muscleAnalyticsUpperLower => 'Upper / Lower';

  @override
  String get muscleAnalyticsWeeklyTrainingFrequency => '주간 훈련 빈도';

  @override
  String get muscleBalanceChartBalanced => '균형 잡힘';

  @override
  String get muscleBalanceChartImbalanced => '불균형';

  @override
  String get muscleBalanceChartLower => '하체';

  @override
  String get muscleBalanceChartPull => '당기기';

  @override
  String get muscleBalanceChartPush => '밀기';

  @override
  String get muscleBalanceChartPushPull => '밀기 / 당기기';

  @override
  String get muscleBalanceChartUpper => '상체';

  @override
  String get muscleBalanceChartUpperLower => '상체 / 하체';

  @override
  String get muscleDetail => '•  ';

  @override
  String get muscleDetailInsights => '인사이트';

  @override
  String get muscleDetailMax => '최대';

  @override
  String get muscleDetailMaxWeight => '최대 중량';

  @override
  String get muscleDetailNeedMoreDataFor => '차트를 위한 데이터가 더 필요합니다';

  @override
  String muscleDetailScreenSetsWk(Object weeklySets) {
    return '주당 $weeklySets 세트';
  }

  @override
  String get muscleDetailTimes => '횟수';

  @override
  String get muscleDetailTotalSets => '총 세트';

  @override
  String get muscleDetailTotalVolume => '총 볼륨';

  @override
  String get muscleDetailVolume => '볼륨';

  @override
  String get muscleDetailVolumeTrend => '볼륨 추이';

  @override
  String get muscleFrequencyChartHigh4xWk => '높음 (>4회/주)';

  @override
  String get muscleFrequencyChartLow1xWk => '낮음 (<1회/주)';

  @override
  String get muscleFrequencyChartNoFrequencyDataAvailable =>
      '사용 가능한 빈도 데이터가 없습니다';

  @override
  String get muscleFrequencyChartOptimal13xWk => '최적 (1-3회/주)';

  @override
  String muscleFrequencyChartX(Object frequency) {
    return '$frequency회';
  }

  @override
  String muscleFrequencyChartX2(Object frequency) {
    return '$frequency회';
  }

  @override
  String muscleFrequencyChartXWk(Object value) {
    return '주 $value회';
  }

  @override
  String get muscleGroupFilterAllMuscles => '모든 근육';

  @override
  String get muscleHeatmapCore => '코어';

  @override
  String get muscleHeatmapHigh => '높음';

  @override
  String get muscleHeatmapLow => '낮음';

  @override
  String get muscleHeatmapLowerBody => '하체';

  @override
  String get muscleHeatmapMedium => '중간';

  @override
  String get muscleHeatmapNone => '없음';

  @override
  String get muscleHeatmapOther => '기타';

  @override
  String get muscleHeatmapTileCompleteWorkoutsToSee => '운동을 완료하여 근육 데이터를 확인하세요';

  @override
  String get muscleHeatmapTileCouldnTLoad => '불러올 수 없음';

  @override
  String muscleHeatmapTileMostTrained(Object arg0) {
    return '가장 많이 단련: $arg0';
  }

  @override
  String get muscleHeatmapTileMuscles => '근육';

  @override
  String get muscleHeatmapTileRetry => '재시도';

  @override
  String get muscleHeatmapUpperBody => '상체';

  @override
  String get muscleScoreBreakdownNoExerciseDataIn => '지난 90일간의 운동 데이터가 없습니다.';

  @override
  String muscleScoreBreakdownSheetEstimatedRmKg(Object e1rm) {
    return '예상 1RM $e1rm kg';
  }

  @override
  String muscleScoreBreakdownSheetValue(Object pct) {
    return '$pct%';
  }

  @override
  String get my1rmsAdd1rm => '1RM 추가';

  @override
  String get my1rmsAddManually => '수동으로 추가';

  @override
  String get my1rmsAddYourMaxLifts =>
      '최대 중량을 추가하여 훈련 강도에 기반한 개인 맞춤형 중량 추천을 받아보세요.';

  @override
  String get my1rmsAutoPopulateFromWorkout => '운동 기록에서 자동 불러오기';

  @override
  String get my1rmsDelete1rm => '1RM을 삭제하시겠습니까?';

  @override
  String get my1rmsMy1rms => '나의 1RM';

  @override
  String get my1rmsNo1rmsRecorded => '기록된 1RM 없음';

  @override
  String get my1rmsScreen1rmWeightKg => '1RM 중량 (kg)';

  @override
  String get my1rmsScreenAdd1rm => '1RM 추가';

  @override
  String get my1rmsScreenAngle => '각도';

  @override
  String get my1rmsScreenDelete1rm => '1RM 삭제';

  @override
  String get my1rmsScreenEG100 => '예: 100';

  @override
  String get my1rmsScreenEGBenchPress => '예: 벤치 프레스';

  @override
  String get my1rmsScreenEGInclineBench => '예: 인클라인 벤치 프레스';

  @override
  String get my1rmsScreenEdit1rm => '1RM 수정';

  @override
  String get my1rmsScreenEnteredManually => '수동 입력됨';

  @override
  String get my1rmsScreenEquipment => '장비';

  @override
  String get my1rmsScreenExerciseName => '운동 이름';

  @override
  String get my1rmsScreenLinkExercise => '운동 연결';

  @override
  String get my1rmsScreenLinkExercises => '운동 연결';

  @override
  String get my1rmsScreenLinkedExercises => '연결된 운동';

  @override
  String my1rmsScreenPartOneRMCardDerivedRmKg(Object derivedWeight) {
    return '산출된 1RM: $derivedWeight kg';
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
    return '$primaryExerciseName에 연결';
  }

  @override
  String my1rmsScreenPartOneRMCardLinked(Object linkedCount) {
    return '연결됨 $linkedCount개';
  }

  @override
  String my1rmsScreenPartOneRMCardLinkedTo(
    Object primaryExerciseName,
    Object text,
  ) {
    return '$text을(를) $primaryExerciseName에 연결함';
  }

  @override
  String my1rmsScreenPartOneRMCardRemoveFromLinkedExercises(
    Object linkedExerciseName,
  ) {
    return '$linkedExerciseName을(를) 연결된 운동에서 삭제할까요?';
  }

  @override
  String get my1rmsScreenProgression => '점진적 과부하';

  @override
  String get my1rmsScreenRelationshipType => '관계 유형';

  @override
  String get my1rmsScreenRemove => '제거';

  @override
  String my1rmsScreenRemoveFromYourSaved(Object exerciseName) {
    return '저장된 1RM에서 $exerciseName을(를) 삭제할까요?';
  }

  @override
  String get my1rmsScreenRemoveLink => '연결을 제거하시겠습니까?';

  @override
  String get my1rmsScreenSource => '출처';

  @override
  String get my1rmsScreenSuggestions => '추천';

  @override
  String get my1rmsScreenTested1rm => '측정된 1RM';

  @override
  String get my1rmsScreenUpdate => '업데이트';

  @override
  String get my1rmsScreenVariant => '변형';

  @override
  String myBadgesShowcaseBadgesAvailable(Object total) {
    return '사용 가능한 배지 $total개';
  }

  @override
  String myBadgesShowcaseEarned(Object length, Object totalTrophies) {
    return '$length개 획득 / 총 $totalTrophies개';
  }

  @override
  String myBadgesShowcaseEarned2(Object length) {
    return '$length개 획득';
  }

  @override
  String get myBadgesShowcaseLogYourFirstWorkout => '첫 번째 운동을 기록하고 첫 배지를 획득하세요';

  @override
  String myExercisesAreYouSureDelete(Object exercise) {
    return '\"$exercise\"을(를) 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get myExercisesAvoided => '제외됨';

  @override
  String get myExercisesCreate => '생성';

  @override
  String get myExercisesCreateExercise => '운동 생성';

  @override
  String get myExercisesCreateYourOwnExercises => '나만의 운동을 생성하여 워크아웃에 사용하세요';

  @override
  String get myExercisesCustom => '사용자 지정';

  @override
  String get myExercisesDeleteExercise => '운동 삭제';

  @override
  String get myExercisesExercisePreferences => '운동 설정';

  @override
  String get myExercisesFavorites => '즐겨찾기';

  @override
  String get myExercisesMuscles => '근육';

  @override
  String get myExercisesNoCustomExercisesYet => '생성한 운동이 없습니다';

  @override
  String get myExercisesQueue => '대기열';

  @override
  String get myExercisesStaples => '주력 운동';

  @override
  String get myFoodsCreateNewRecipe => '새 레시피 생성';

  @override
  String get myFoodsCreateRecipesToQuickly => '자주 먹는 식단을 빠르게 기록하려면 레시피를 생성하세요';

  @override
  String get myFoodsCreateYourFirstRecipe => '첫 레시피 생성';

  @override
  String get myFoodsMyFoods => '나의 음식';

  @override
  String get myFoodsNoRecipesYet => '레시피가 없습니다';

  @override
  String get myFoodsNoSavedFoodsFound => '저장된 음식이 없습니다';

  @override
  String get myFoodsReopenARestaurantMenu => '이전에 스캔한 식당 메뉴 다시 열기';

  @override
  String get myFoodsSaveFoodsWhenLogging => '식단 기록 시 음식 저장';

  @override
  String get myFoodsSavedMenus => '저장된 메뉴';

  @override
  String get myFoodsSearchSavedFoods => '저장된 음식 검색...';

  @override
  String myFoodsSheetIngredients(Object ingredientCount) {
    return '재료 $ingredientCount개';
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
    return '$timesLogged회 기록됨';
  }

  @override
  String myFoodsSheetX(Object timesLogged) {
    return ' $timesLogged회';
  }

  @override
  String get myJourneyCardAmazingStreak => '놀라운 연속 기록입니다! 계속하세요!';

  @override
  String get myJourneyCardBuildingGreatHabits => '훌륭한 습관을 만들고 계시네요!';

  @override
  String get myJourneyCardComesoFar => '정말 많이 오셨네요. 계속 정진하세요!';

  @override
  String get myJourneyCardDayStreak => '일 연속 기록';

  @override
  String get myJourneyCardEveryWorkoutCounts => '모든 운동이 중요합니다. 할 수 있어요!';

  @override
  String get myJourneyCardKeepMomentum => '이 기세를 이어가세요!';

  @override
  String get myJourneyCardMilestoneAthlete => '운동선수';

  @override
  String get myJourneyCardMilestoneBeginner => '초보자';

  @override
  String get myJourneyCardMilestoneBuildingHabit => '습관 형성';

  @override
  String get myJourneyCardMilestoneChampion => '챔피언';

  @override
  String get myJourneyCardMilestoneConsistent => '꾸준함';

  @override
  String get myJourneyCardMilestoneDedicated => '헌신적';

  @override
  String get myJourneyCardMilestoneGettingStarted => '시작하기';

  @override
  String get myJourneyCardMilestoneLegend => '전설';

  @override
  String get myJourneyCardMyJourney => '나의 여정';

  @override
  String myJourneyCardNext(Object title) {
    return '다음: $title';
  }

  @override
  String get myJourneyCardOneWorkoutLeft => '이번 주 운동 1회 남음';

  @override
  String get myJourneyCardProgress => '진척도';

  @override
  String get myJourneyCardProgressCharts => '진척도 차트';

  @override
  String get myJourneyCardTapToSeeFullJourney => '탭하여 전체 여정 보기';

  @override
  String get myJourneyCardThisWeek => '이번 주';

  @override
  String get myJourneyCardTotal => '전체';

  @override
  String get myJourneyCardViewCharts => '차트 보기';

  @override
  String get myJourneyCardViewStrengthAndVolume => '시간에 따른 근력 및 볼륨 변화 확인';

  @override
  String myJourneyCardWeekNumber(Object week) {
    return '$week주차';
  }

  @override
  String get myJourneyCardWeeklyGoalComplete => '주간 목표 달성!';

  @override
  String myJourneyCardWorkoutsLeft(Object count) {
    return '이번 주 운동 $count회 남음';
  }

  @override
  String myJourneyCardWorkoutsProgress(Object completed, Object total) {
    return '운동 $completed / $total 완료';
  }

  @override
  String get myLibraryTabAiPrioritizesTheseIn => 'AI가 워크아웃에서 이 운동들을 우선시합니다';

  @override
  String get myLibraryTabBuildSupersetsCombosOr => '슈퍼세트, 콤보 또는 독특한 동작을 구성하세요';

  @override
  String get myLibraryTabCompleteWorkoutsToSee => '워크아웃을 완료하여 운동 기록을 확인하세요';

  @override
  String get myLibraryTabCreate => '생성';

  @override
  String get myLibraryTabCreateYourFirstCustom => '첫 번째 사용자 지정 운동을 생성하세요';

  @override
  String get myLibraryTabFailedToLoadActivity => '활동을 불러오지 못했습니다';

  @override
  String get myLibraryTabGetStarted => '시작하기';

  @override
  String get myLibraryTabHeartExercisesToSave => '운동을 찜하여 여기에 저장하세요';

  @override
  String get myLibraryTabMarkExercisesAsStaples =>
      '운동을 주력 운동으로 표시하여 AI가 우선시하도록 하세요';

  @override
  String get myLibraryTabMyExercises => '나의 운동';

  @override
  String myLibraryTabPartCustomExercisesSectionFavorites(Object length) {
    return '즐겨찾기 ($length)';
  }

  @override
  String myLibraryTabPartCustomExercisesSectionStaples(Object length) {
    return '주요 운동 ($length)';
  }

  @override
  String myLibraryTabPartHistoryTimelineCardBestKgX(
    Object item,
    Object maxReps,
  ) {
    return '최고 기록: ${item}kg x $maxReps';
  }

  @override
  String get myLibraryTabRecentActivity => '최근 활동';

  @override
  String get myLibraryTabViewAll => '모두 보기';

  @override
  String myProgramSummaryCardValue(
    Object experience,
    Object goal,
    Object workoutDays,
  ) {
    return '$workoutDays  •  $experience  •  $goal';
  }

  @override
  String get myProgramSummaryMyProgram => '나의 프로그램';

  @override
  String get myStats1rm => '1RM';

  @override
  String get myStatsCompleteWorkoutsToSee => '워크아웃을 완료하여 통계를 확인하세요';

  @override
  String get myStatsExercisePerformance => '운동 수행 능력';

  @override
  String get myStatsFailedToLoadStats => '통계를 불러오지 못했습니다';

  @override
  String get myStatsKgMax => 'kg 최대';

  @override
  String get myStatsNoExerciseHistoryYet => '운동 기록이 없습니다';

  @override
  String myStatsTabExercisesTrackedTotalSets(Object length, Object totalSets) {
    return '운동 $length개 기록됨  •  총 세트 $totalSets개';
  }

  @override
  String get myWrappedCompleteAtLeast3 =>
      '이번 달에 최소 3회 이상 운동을 완료하여\n개인 맞춤형 요약을 확인하세요';

  @override
  String get myWrappedEarnAUniquePersonality =>
      '매달 최소 3회 이상 운동을 완료하고 고유한 피트니스 성향을 획득하세요.';

  @override
  String get myWrappedFailedToLoadWrapped => '요약 데이터를 불러오지 못했습니다';

  @override
  String get myWrappedFitnessPersonalities => '피트니스 성향';

  @override
  String get myWrappedMyWrapped => '나의 요약';

  @override
  String get myWrappedPastWraps => '지난 요약';

  @override
  String get myWrappedPersonalities => '성향';

  @override
  String myWrappedScreenOfCollected(Object collected) {
    return '12개 중 $collected개 수집됨';
  }

  @override
  String myWrappedScreenWorkouts(Object totalWorkouts) {
    return '운동 $totalWorkouts회';
  }

  @override
  String myWrappedScreenWrappedDropsInDays(
    Object daysUntilDrop,
    Object monthName,
  ) {
    return '$monthName Wrapped가 $daysUntilDrop일 후에 공개됩니다';
  }

  @override
  String myWrappedScreenWrappedDropsSoon(Object monthName) {
    return '$monthName Wrapped가 곧 공개됩니다';
  }

  @override
  String myWrappedScreenYourWrappedIsBuilding(Object monthName) {
    return '$monthName Wrapped를 준비 중입니다...';
  }

  @override
  String get myWrappedViewAgain => '다시 보기';

  @override
  String get myWrappedYourMonthlyWrapped => '월간 요약';

  @override
  String get navDiscover => '탐색';

  @override
  String get navHome => '홈';

  @override
  String get navNutrition => '영양';

  @override
  String get navProfile => '프로필';

  @override
  String get navProgress => '진행';

  @override
  String get navWorkout => '운동';

  @override
  String get navWorkouts => '운동';

  @override
  String get navYou => '내 정보';

  @override
  String get navCoach => '코치';

  @override
  String get neatAchievementCardNew => '새로운 기능!';

  @override
  String get neatActivityCardActive => '활동 중';

  @override
  String get neatActivityCardDailyActivity => '일일 활동';

  @override
  String get neatActivityCardGoalMet => '목표 달성!';

  @override
  String neatActivityCardH(Object activeHours) {
    return '$activeHours시간';
  }

  @override
  String get neatActivityCardSetUpStepGoals => '걸음 수 목표 설정 →';

  @override
  String get neatActivityCardTrackYourDailySteps => '일일 걸음 수와 활동량을 추적하세요';

  @override
  String get neatDashboardDailyActivity => '일일 활동';

  @override
  String get neatDashboardScreenActive => '활동';

  @override
  String get neatDashboardScreenActiveHours => '활동 시간';

  @override
  String get neatDashboardScreenActiveHoursNtoday => '오늘의\n활동 시간';

  @override
  String get neatDashboardScreenAiCoachTip => 'AI 코치 팁';

  @override
  String get neatDashboardScreenCalories => '칼로리';

  @override
  String get neatDashboardScreenComplete => '완료';

  @override
  String get neatDashboardScreenGreatJobYouVe => '잘하셨어요! 오늘 활동 시간 목표를 달성했습니다.';

  @override
  String get neatDashboardScreenHourlyActivity => '시간별 활동';

  @override
  String get neatDashboardScreenIfBelow => '미만일 경우';

  @override
  String get neatDashboardScreenLongestNeatStreak => '최장 NEAT 연속 기록';

  @override
  String get neatDashboardScreenMovementReminders => '움직임 알림';

  @override
  String get neatDashboardScreenNeatScore => 'NEAT 점수';

  @override
  String neatDashboardScreenPartNeatScoreCardGoal(Object goal) {
    return '목표: $goal+';
  }

  @override
  String neatDashboardScreenPartNeatScoreCardOf(Object maxScore) {
    return '$maxScore점 중';
  }

  @override
  String neatDashboardScreenPartNeatScoreCardValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String neatDashboardScreenPartStreaksCardDays(Object longestNeatScoreStreak) {
    return '$longestNeatScoreStreak일';
  }

  @override
  String neatDashboardScreenPartStreaksCardMin(Object minutes) {
    return '$minutes분';
  }

  @override
  String neatDashboardScreenPartStreaksCardQuietHours(
    Object endTime,
    Object startTime,
  ) {
    return '방해 금지 시간: $startTime - $endTime';
  }

  @override
  String neatDashboardScreenPartStreaksCardSteps(Object stepsThreshold) {
    return '$stepsThreshold 걸음';
  }

  @override
  String neatDashboardScreenPartStreaksCardValue(Object points) {
    return '+$points';
  }

  @override
  String get neatDashboardScreenProgressive => '점진적';

  @override
  String get neatDashboardScreenRecent => '최근';

  @override
  String get neatDashboardScreenRemindEvery => '알림 주기';

  @override
  String get neatDashboardScreenSeeAll => '모두 보기';

  @override
  String get neatDashboardScreenStepGoal => '걸음 수 목표';

  @override
  String get neatDashboardScreenSteps => '걸음 수';

  @override
  String get neatDashboardScreenStreaks => '연속 기록';

  @override
  String get neatDashboardScreenUpNext => '다음 예정';

  @override
  String get neatDashboardScreenWorkHoursOnly9am => '근무 시간만 (오전 9시 - 오후 5시)';

  @override
  String get neatDashboardUnableToLoadData => '데이터를 불러올 수 없습니다';

  @override
  String get neatGamificationWidgetsAccept => '수락';

  @override
  String get neatGamificationWidgetsAchievementUnlocked => '업적 달성!';

  @override
  String get neatGamificationWidgetsActive => '활동';

  @override
  String get neatGamificationWidgetsActiveWalker => '액티브 워커';

  @override
  String get neatGamificationWidgetsCasualMover => '캐주얼 무버';

  @override
  String get neatGamificationWidgetsClaimReward => '보상 받기';

  @override
  String get neatGamificationWidgetsCouchPotato => '카우치 포테이토';

  @override
  String neatGamificationWidgetsCurrentXp(Object arg0) {
    return '$arg0 XP';
  }

  @override
  String get neatGamificationWidgetsDailyChallenge => '일일 챌린지';

  @override
  String get neatGamificationWidgetsExpired => '만료됨';

  @override
  String neatGamificationWidgetsHoursMinutesLeft(Object arg0, Object arg1) {
    return '$arg0시간 $arg1분 남음';
  }

  @override
  String neatGamificationWidgetsLevel(Object level) {
    return '레벨 $level';
  }

  @override
  String get neatGamificationWidgetsLevelUp => '레벨 업!';

  @override
  String get neatGamificationWidgetsMaxLevel => '최고 레벨!';

  @override
  String neatGamificationWidgetsMinutesLeft(Object arg0) {
    return '$arg0분 남음';
  }

  @override
  String get neatGamificationWidgetsNeat => 'NEAT';

  @override
  String get neatGamificationWidgetsNeatChampion => '챔피언';

  @override
  String get neatGamificationWidgetsNeatEnthusiast => '열정가';

  @override
  String get neatGamificationWidgetsNeatPts => 'NEAT 포인트';

  @override
  String get neatGamificationWidgetsNoRankingsYetThis => '이번 주 순위가 아직 없습니다';

  @override
  String neatGamificationWidgetsPartNeatMilestonePopupStateXp(Object xpEarned) {
    return '+$xpEarned XP';
  }

  @override
  String get neatGamificationWidgetsScore => '점수';

  @override
  String neatGamificationWidgetsStepGoal(Object arg0) {
    return '/ $arg0';
  }

  @override
  String get neatGamificationWidgetsSteps => '걸음 수';

  @override
  String neatGamificationWidgetsTargetActiveHours(Object arg0) {
    return '/ $arg0시간';
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
  String get neatGamificationWidgetsViewAll => '모두 보기';

  @override
  String get neatGamificationWidgetsWeeklyLeaderboard => '주간 리더보드';

  @override
  String neatGamificationWidgetsXpToNext(Object levelName, Object xpToNext) {
    return '$levelName까지 $xpToNext XP 필요';
  }

  @override
  String get neatGamificationWidgetsYou => ' (나)';

  @override
  String get neatScoreDisplayNeatScore => 'NEAT 점수';

  @override
  String neatScoreDisplayNeatScoreOutOf(Object animatedScore, Object label) {
    return 'NEAT 점수: 100점 만점에 $animatedScore점, 등급: $label';
  }

  @override
  String get neatScoreDisplayScoreBreakdown => '점수 상세 분석';

  @override
  String get neatScoreDisplayTapForBreakdown => '탭하여 상세 분석 보기';

  @override
  String neatScoreDisplayTrend(Object name) {
    return '추세: $name';
  }

  @override
  String get netflixExerciseCarouselLoading => '불러오는 중...';

  @override
  String get netflixExerciseCarouselSeeAll => '모두 보기';

  @override
  String get netflixExercisesAddYourOwnExercises =>
      '사용자 지정 횟수, 세트, 지침으로 나만의 운동을 추가하세요.';

  @override
  String get netflixExercisesAiSearchEG => 'AI 검색 (예: \"가슴 운동 추천\")';

  @override
  String get netflixExercisesCustomExercises => '사용자 지정 운동';

  @override
  String get netflixExercisesEquipment => '장비';

  @override
  String get netflixExercisesExercisesByMuscle => '부위별 운동';

  @override
  String get netflixExercisesFailedToLoadExercises => '운동 데이터를 불러오지 못했습니다';

  @override
  String get netflixExercisesGotIt => '확인';

  @override
  String get netflixExercisesTab => ' • ';

  @override
  String get netflixExercisesTabAllExercises => '모든 운동';

  @override
  String get netflixExercisesTabClearFilters => '필터 초기화';

  @override
  String get netflixExercisesTabClearSearch => '검색 초기화';

  @override
  String get netflixExercisesTabCreate => '생성';

  @override
  String get netflixExercisesTabCreateYourOwnExercises =>
      '사진과 AI 분석을 사용하여 나만의 운동을 만드세요';

  @override
  String get netflixExercisesTabMyCustomExercises => '내 사용자 지정 운동';

  @override
  String get netflixExercisesTabNoCustomExercisesYet => '아직 생성한 운동이 없습니다';

  @override
  String get netflixExercisesTabNoExercisesFound => '운동을 찾을 수 없습니다';

  @override
  String netflixExercisesTabPartExerciseListCardDaysWeek(
    Object daysPerWeek,
    Object duration,
  ) {
    return '주 $daysPerWeek회 • $duration';
  }

  @override
  String netflixExercisesTabPartExerciseListCardFlexible(Object duration) {
    return '유연함 • $duration';
  }

  @override
  String get netflixExercisesTabSearching => '검색 중...';

  @override
  String get netflixExercisesTabTrainingSplits => '운동 분할';

  @override
  String netflixExercisesTabUiAllExercisesLoaded(Object length) {
    return '운동 $length개 모두 로드됨';
  }

  @override
  String get newTilesAmazingStreakKeepGoing => '대단한 연속 기록입니다! 계속하세요!';

  @override
  String newTilesPartActiveChallengeCardDayOf(
    Object currentDay,
    Object totalDays,
  ) {
    return '$totalDays일 중 $currentDay일차';
  }

  @override
  String newTilesPartActiveChallengeCardRestingBpm(Object restingBPM) {
    return '휴식기: $restingBPM BPM';
  }

  @override
  String newTilesPartActiveChallengeCardTodayReps(
    Object targetReps,
    Object todayReps,
  ) {
    return '오늘: $todayReps / $targetReps회';
  }

  @override
  String newTilesPartActiveChallengeCardValue(Object match) {
    return '$match,';
  }

  @override
  String get newTilesPartAskCoachForMore => '코치에게 더 물어보기';

  @override
  String get newTilesPartCoachTip => '코치 팁';

  @override
  String get newTilesPartCompleteWorkoutsToEarn => '운동을 완료하고 PR을 달성하세요';

  @override
  String get newTilesPartConnectHealthToTrack => '건강 앱을 연결하여 추적하세요';

  @override
  String get newTilesPartDayStreak => '일 연속 기록';

  @override
  String get newTilesPartGettingYourPersonalizedTip => '맞춤형 팁을 가져오는 중...';

  @override
  String get newTilesPartHeartRate => '심박수';

  @override
  String get newTilesPartMyJourney => '나의 여정';

  @override
  String get newTilesPartPersonalRecords => '개인 최고 기록';

  @override
  String newTilesPartPersonalRecordsCardH(Object sleepHours) {
    return '$sleepHours시간';
  }

  @override
  String newTilesPartPersonalRecordsCardKg(Object change) {
    return '$change kg';
  }

  @override
  String newTilesPartPersonalRecordsCardValue(Object rank) {
    return '#$rank';
  }

  @override
  String get newTilesPartProgressCharts => '진행 상황 차트';

  @override
  String get newTilesPartRank => '순위';

  @override
  String get newTilesPartRecentWorkouts => '최근 운동';

  @override
  String get newTilesPartRestDayRecovery => '휴식일 회복';

  @override
  String get newTilesPartSleep => '수면';

  @override
  String get newTilesPartSteps => '걸음 수';

  @override
  String get newTilesPartTapToSeeYour => '탭하여 전체 여정 보기';

  @override
  String get newTilesPartThisWeek => '이번 주';

  @override
  String get newTilesPartViewAll => '모두 보기';

  @override
  String get newTilesPartViewCharts => '차트 보기';

  @override
  String get newTilesPartViewStrengthAndVolume => '시간에 따른 근력 및 볼륨 변화 보기';

  @override
  String get newTilesPartWater => '수분 섭취';

  @override
  String get newTilesPartWeight => '체중';

  @override
  String get newTilesStreak => '연속 기록';

  @override
  String newspaperTemplateContinuedOnPage(Object completedAt) {
    return '$completedAt 페이지에서 계속';
  }

  @override
  String newspaperTemplateExpertsStunnedByPerformance(Object topEx) {
    return '\"전문가들, $topEx 수행 능력에 경악\"';
  }

  @override
  String newspaperTemplateLiftsInGruelingSession(Object name, Object volLabel) {
    return '$name, 고강도 세션에서 $volLabel 리프팅';
  }

  @override
  String get newspaperTemplateTheNumbers => '수치';

  @override
  String get newspaperTemplateTheZealovaTimes => 'THE ZEALOVA TIMES';

  @override
  String get nextSetPreviewAiRecommendation => 'AI 추천';

  @override
  String get nextSetPreviewAnalyzing => '성과 분석 중...';

  @override
  String get nextSetPreviewAnalyzingPerformance => '성과 분석 중';

  @override
  String get nextSetPreviewCalculating => '다음 세트 계산 중...';

  @override
  String get nextSetPreviewCalculatingOptimalNextSet => '최적의 다음 세트 계산 중...';

  @override
  String nextSetPreviewCardIntensity(Object intensityPercentage) {
    return '강도 $intensityPercentage%';
  }

  @override
  String nextSetPreviewCardKg(Object recommendedWeight) {
    return '$recommendedWeight kg';
  }

  @override
  String nextSetPreviewCardX(Object recommendedReps) {
    return 'x $recommendedReps';
  }

  @override
  String get nextSetPreviewFinal => '마지막 세트';

  @override
  String get nextSetPreviewKg => ' kg';

  @override
  String get nextSetPreviewNextSet => '다음 세트';

  @override
  String get nextSetPreviewReps => ' 회';

  @override
  String get nextSetPreviewUse => '사용';

  @override
  String get nextSetPreviewUseThis => '사용하기';

  @override
  String get nextWorkoutCardCouldNotSkipWorkout =>
      '운동을 건너뛸 수 없습니다. 다시 시도해 주세요.';

  @override
  String get nextWorkoutCardQuick => '빠른 시작';

  @override
  String get nextWorkoutCardRegenerate => '재생성';

  @override
  String get nextWorkoutCardSkipWorkout => '운동을 건너뛸까요?';

  @override
  String get nextWorkoutCardThisWorkoutWillBe =>
      '이 운동은 건너뛴 것으로 표시되며 주간 목표에 포함되지 않습니다.';

  @override
  String get nextWorkoutCardUpcoming => '예정된 운동';

  @override
  String nextWorkoutCardValue(Object count) {
    return '+$count';
  }

  @override
  String get nextWorkoutCardWorkoutRegenerated => '운동이 재생성되었습니다!';

  @override
  String get nextWorkoutCardWorkoutSkipped => '운동 건너뜀';

  @override
  String get notificationBellButtonNotifications => '알림';

  @override
  String get notificationPrimeEnableNotifications => '알림 활성화';

  @override
  String get notificationPrimeNotNow => '나중에';

  @override
  String get notificationPrimePrCelebrations => 'PR 달성 축하';

  @override
  String notificationPrimeScreenTurnOnNotificationsSo(Object appName) {
    return '알림을 켜서 $appName이(가) 가장 중요할 때 코칭할 수 있도록 하세요.';
  }

  @override
  String get notificationPrimeStayOnTrackWith => '부드러운 알림으로 꾸준히 관리하세요';

  @override
  String get notificationPrimeStreakSaves => '연속 기록 유지';

  @override
  String get notificationPrimeWorkoutReminders => '운동 알림';

  @override
  String get notificationPrimeYouCanChangeThis => '설정에서 언제든지 변경할 수 있습니다.';

  @override
  String get notificationTestAiCoachMessage => 'AI 코치 메시지';

  @override
  String get notificationTestBasicTest => '기본 테스트';

  @override
  String get notificationTestBreakfastReminder => '아침 식사 알림';

  @override
  String get notificationTestDinnerReminder => '저녁 식사 알림';

  @override
  String get notificationTestGoodProgress70 => '진행률 좋음 (70%)';

  @override
  String get notificationTestGuilt1DayMissed => '죄책감 (1일 미달성)';

  @override
  String get notificationTestGuilt2DaysMissed => '죄책감 (2일 미달성)';

  @override
  String get notificationTestGuilt3DaysMissed => '죄책감 (3일 이상 미달성)';

  @override
  String get notificationTestHeyYourAiCoach => '\"안녕! AI 코치야 💪\"';

  @override
  String get notificationTestImmediateLocalNotification => '즉시 로컬 알림';

  @override
  String get notificationTestItSBeenX => '\"X일이나 지났어! 😱\"';

  @override
  String get notificationTestKeepItUpAlmost => '\"계속 힘내! 💧 거의 다 왔어!\"';

  @override
  String get notificationTestLowProgress40 => '진행률 낮음 (40%)';

  @override
  String get notificationTestLunchReminder => '점심 식사 알림';

  @override
  String get notificationTestNoPendingNotificationsSched => '예약된 알림 없음';

  @override
  String get notificationTestNoTitle => '제목 없음';

  @override
  String get notificationTestNotificationTesting => '알림 테스트';

  @override
  String get notificationTestScheduleIn10Seconds => '10초 후 예약';

  @override
  String get notificationTestScheduleIn60Seconds => '60초 후 예약';

  @override
  String notificationTestScreenId(Object id) {
    return 'ID: $id';
  }

  @override
  String notificationTestScreenPendingNotifications(Object length) {
    return '대기 중인 알림 ($length)';
  }

  @override
  String notificationTestScreenValue(Object key) {
    return '$key:';
  }

  @override
  String get notificationTestShowsANotificationRight => '지금 바로 알림 표시';

  @override
  String get notificationTestShowsAllScheduledNotificati => '예약된 모든 알림 표시';

  @override
  String get notificationTestShowsCurrentTimezoneSetting => '현재 시간대 설정 표시';

  @override
  String get notificationTestStayHydratedYouRe => '\"수분을 섭취하세요! 💧 40% 달성\"';

  @override
  String get notificationTestTestsScheduledNotificationD => '예약된 알림 발송 테스트';

  @override
  String get notificationTestTheseAreLocalNotifications =>
      '이 알림은 로컬 알림(Firebase 아님)입니다. 기기에서 예약된 알림이 작동하는지 테스트할 때 사용하세요.';

  @override
  String get notificationTestTheseNotificationsAreSent =>
      '이 알림은 백엔드를 통해 Firebase Cloud Messaging으로 발송됩니다.';

  @override
  String get notificationTestTimeToLogYour => '\"아침 식사를 기록할 시간이에요! 📸\"';

  @override
  String get notificationTestTimeToLogYour2 => '\"점심 식사를 기록할 시간이에요! 📸\"';

  @override
  String get notificationTestTimeToLogYour3 => '\"저녁 식사를 기록할 시간이에요! 📸\"';

  @override
  String get notificationTestTimeToTrain => '\"운동할 시간이에요! 💪\"';

  @override
  String get notificationTestTimezoneInfo => '시간대 정보';

  @override
  String get notificationTestViewPendingNotifications => '예약된 알림 보기';

  @override
  String get notificationTestViewTimezoneInfo => '시간대 정보 보기';

  @override
  String get notificationTestWorkoutReminder => '운동 알림';

  @override
  String get notificationTestYourAiCoachIs => '\"AI 코치가 외로워하고 있어요... 🥺\"';

  @override
  String get notificationTestYourAiCoachIs2 => '\"AI 코치가 준비됐어요! 💪\"';

  @override
  String get notificationTestYourMusclesMissYou => '\"근육들이 당신을 그리워해요! 💪\"';

  @override
  String get notifications3Day => '일 3회';

  @override
  String get notifications45Day => '일 4-5회';

  @override
  String get notifications810Day => '일 8-10회';

  @override
  String get notificationsAdvanced => '고급';

  @override
  String get notificationsAnomalyAlerts => '이상 징후 알림';

  @override
  String get notificationsBalanced => '균형 잡힌';

  @override
  String get notificationsBreakfast => '아침 식사';

  @override
  String get notificationsBreakfastLunchDinner => '아침, 점심, 저녁 식사';

  @override
  String get notificationsClearAll => '모두 지우기';

  @override
  String get notificationsCycleReminders => '주기 알림';

  @override
  String get notificationsDay => '일';

  @override
  String get notificationsDeliveryTime => '발송 시간';

  @override
  String get notificationsDifferentScheduleOnSat => '토요일 및 일요일 일정 다르게 설정';

  @override
  String get notificationsDinner => '저녁 식사';

  @override
  String get notificationsDuolingoStyleNudgesWhen => '비활동 시 Duolingo 스타일 알림';

  @override
  String get notificationsEnd => '종료';

  @override
  String get notificationsEvening => '저녁';

  @override
  String get notificationsFailedToAcceptRequest => '요청 수락에 실패했습니다. 다시 시도하세요.';

  @override
  String get notificationsFailedToIgnoreRequest => '요청 무시에 실패했습니다. 다시 시도하세요.';

  @override
  String get notificationsFailedToLoadNotifications => '알림을 불러오지 못했습니다';

  @override
  String get notificationsFineTuneIndividualNotificat => '개별 알림 유형 세부 설정';

  @override
  String get notificationsFriendRequestIgnored => '친구 요청을 무시했습니다';

  @override
  String get notificationsFullCoach => '풀 코치';

  @override
  String get notificationsGuiltNotifications => '죄책감 유발 알림';

  @override
  String get notificationsHeadsUpWhenResting => '안정 시 심박수가 높을 때 알림';

  @override
  String get notificationsHourlyDuringWorkHours => '근무 시간 중 매시간';

  @override
  String get notificationsIncludeEmoji => '이모지 포함';

  @override
  String get notificationsLunch => '점심 식사';

  @override
  String get notificationsMarkAllAsRead => '모두 읽음으로 표시';

  @override
  String get notificationsMealReminders => '식사 알림';

  @override
  String get notificationsMidday => '정오';

  @override
  String get notificationsMinimal => '최소';

  @override
  String get notificationsMorning => '아침';

  @override
  String get notificationsMorningReadinessCheckIn => '아침 컨디션 체크인';

  @override
  String get notificationsMovementHydration => '움직임 + 수분 섭취';

  @override
  String get notificationsNoNotificationsInThis => '이 카테고리에 알림이 없습니다';

  @override
  String get notificationsNotificationFrequency => '알림 빈도';

  @override
  String get notificationsNotifications => '알림';

  @override
  String get notificationsNudgeTime => '알림 시간';

  @override
  String get notificationsPeriodFertilityAndLogging => '생리 주기, 가임기 및 기록 알림';

  @override
  String get notificationsRecommended => '권장';

  @override
  String get notificationsRemindEvery => '알림 주기';

  @override
  String get notificationsRemindOnWorkoutDays => '운동하는 날 알림';

  @override
  String get notificationsReminderTime => '알림 시간';

  @override
  String get notificationsReminderWhenYouRe => '걸음 수 목표 미달 시 알림';

  @override
  String get notificationsScreenPartAccept => '수락';

  @override
  String get notificationsScreenPartIgnore => '무시';

  @override
  String get notificationsScreenPartNoNotificationsYet => '아직 알림이 없습니다';

  @override
  String get notificationsScreenPartWhatToExpect => '알림 안내';

  @override
  String get notificationsScreenPartYourAiCoachWill =>
      'AI 코치가 이곳에서 운동 알림, 동기 부여 및 진행 상황 업데이트를 보내드립니다.';

  @override
  String notificationsScreenYouAndAreNow(Object fromUserName) {
    return '이제 $fromUserName님과 친구가 되었습니다!';
  }

  @override
  String get notificationsShowEmojiInNotification => '알림 텍스트에 이모지 표시';

  @override
  String get notificationsStayHydratedThroughoutThe => '하루 종일 수분을 유지하세요';

  @override
  String get notificationsTime => '시간';

  @override
  String get notificationsWaterReminders => '수분 섭취 알림';

  @override
  String get notificationsWeekendTimes => '주말 시간';

  @override
  String get notificationsWeeklyReport => '주간 리포트';

  @override
  String get notificationsWorkoutBreakfast => '운동 + 아침 식사';

  @override
  String get notificationsWorkoutReminders => '운동 알림';

  @override
  String get notificationsYourFriendIsDoing => '친구가 회원님의 운동을 수행 중입니다!';

  @override
  String get notificationsYourProgressSummary => '진행 상황 요약';

  @override
  String get notifsAllowButton => '알림 허용';

  @override
  String get notifsLaterButton => '나중에';

  @override
  String get notifsPrimerBody => '운동과 체크인 알림을 받으세요.';

  @override
  String get notifsPrimerTitle => '꾸준히 갑시다';

  @override
  String numberInputWidgetsTarget(Object targetReps) {
    return '목표 ($targetReps)';
  }

  @override
  String numberInputWidgetsTarget2(Object targetReps) {
    return '목표: $targetReps';
  }

  @override
  String numberInputWidgetsValue(Object accuracyPercent) {
    return '$accuracyPercent%';
  }

  @override
  String nutrientExplorerAddedToPinnedNutrients(Object displayName) {
    return '$displayName이(가) 고정 영양소에 추가되었습니다';
  }

  @override
  String get nutrientExplorerCurrent => '현재';

  @override
  String get nutrientExplorerFailedToUpdatePinned => '고정된 영양소 업데이트 실패';

  @override
  String get nutrientExplorerFattyAcids => '지방산';

  @override
  String get nutrientExplorerMinerals => '미네랄';

  @override
  String get nutrientExplorerNutrientsThatMatterMost => '현재 주기에서 가장 중요한 영양소';

  @override
  String get nutrientExplorerPartCeiling => '상한선';

  @override
  String get nutrientExplorerPartFloor => '하한선';

  @override
  String get nutrientExplorerPartHigh => '높음';

  @override
  String get nutrientExplorerPartLogSomeFoodTo => '음식을 기록하여 미량 영양소 섭취량을 확인하세요';

  @override
  String get nutrientExplorerPartLow => '낮음';

  @override
  String get nutrientExplorerPartNoNutrientData => '영양 데이터 없음';

  @override
  String get nutrientExplorerPartNutrientScore => '영양 점수';

  @override
  String nutrientExplorerPartNutrientScoreCardCurrent(
    Object currentValue,
    Object unit,
  ) {
    return '현재: $currentValue$unit';
  }

  @override
  String nutrientExplorerPartNutrientScoreCardNutrients(Object length) {
    return '영양소 $length개';
  }

  @override
  String nutrientExplorerPartNutrientScoreCardOptimal(
    Object optimalCount,
    Object totalCount,
  ) {
    return '$optimalCount/$totalCount 최적';
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
  String get nutrientExplorerPartOptimal => '최적';

  @override
  String get nutrientExplorerPartRefresh => '새로고침';

  @override
  String get nutrientExplorerPartScore => '점수';

  @override
  String get nutrientExplorerPartTarget => '목표';

  @override
  String get nutrientExplorerPinToDashboard => '대시보드에 고정';

  @override
  String get nutrientExplorerPrioritisedForYourCycle => '주기 단계별 우선순위';

  @override
  String nutrientExplorerRemovedFromPinnedNutrients(Object displayName) {
    return '$displayName이(가) 고정 영양소에서 제거되었습니다';
  }

  @override
  String nutrientExplorerTarget(Object unit) {
    return '목표 $unit';
  }

  @override
  String get nutrientExplorerTopContributors => '주요 공급원';

  @override
  String get nutrientExplorerUnknown => '알 수 없음';

  @override
  String get nutrientExplorerUnpinNutrient => '영양소 고정 해제';

  @override
  String get nutrientExplorerVitamins => '비타민';

  @override
  String get nutrientRushGameCatchTheGoldenZealova =>
      '황금 Zealova 마크를 잡아 파워업하세요!';

  @override
  String get nutrientRushGameNewBest => '🎉 새로운 최고 기록!';

  @override
  String get nutrientRushGameNewPersonalBest => '🎉 새로운 개인 최고 기록!';

  @override
  String get nutrientRushGameNutrientRushFriends => 'Nutrient Rush — 친구';

  @override
  String nutrientRushGameS(Object _stageNumber) {
    return 'S$_stageNumber';
  }

  @override
  String get nutrientRushGameStageClear => '🔥 스테이지 클리어';

  @override
  String nutrientRushGameX(Object _combo) {
    return 'x$_combo';
  }

  @override
  String nutrientRushGameYou(Object name) {
    return '$name (나)';
  }

  @override
  String nutrientRushGameYourBest(Object best) {
    return '최고 기록: $best';
  }

  @override
  String get nutritionAlreadyInMyFoods => '이미 내 음식에 있음';

  @override
  String get nutritionCaloriesByCyclePhase => '사이클 단계별 칼로리';

  @override
  String get nutritionCookingUpYourRecipe => '백그라운드에서 레시피를 요리하는 중…';

  @override
  String get nutritionCouldNotLoadCycle => '주기 오버레이를 불러올 수 없습니다';

  @override
  String get nutritionDailyTab => '오늘';

  @override
  String get nutritionErrorStatePleaseCheckYourConnection =>
      '연결 상태를 확인하고 다시 시도하세요';

  @override
  String get nutritionErrorStateTryAgain => '다시 시도';

  @override
  String get nutritionErrorStateUnableToLoadNutrition => '영양 데이터를 불러올 수 없습니다';

  @override
  String get nutritionFailedToSaveFood => '음식 저장에 실패했습니다';

  @override
  String get nutritionFastingCardAllergens => '알레르기 유발 물질';

  @override
  String get nutritionFastingCardBodyCompositionTarget => '체성분 목표';

  @override
  String nutritionFastingCardCal(Object currentCalories) {
    return '$currentCalories cal';
  }

  @override
  String get nutritionFastingCardDailyTarget => '일일 목표';

  @override
  String get nutritionFastingCardDietType => '다이어트 유형';

  @override
  String get nutritionFastingCardEditNutritionSettings => '영양 설정 편집';

  @override
  String get nutritionFastingCardFastingProtocol => '단식 프로토콜';

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
  String get nutritionFastingCardGoalWeight => '목표 가중치';

  @override
  String get nutritionFastingCardMacros => '매크로';

  @override
  String get nutritionFastingCardMaintainWeight => '체중 유지';

  @override
  String get nutritionFastingCardNutritionFasting => '영양 및 단식';

  @override
  String get nutritionFastingCardRestrictions => '제한';

  @override
  String get nutritionFastingCardTargetDate => '목표 날짜';

  @override
  String get nutritionFastingCardWeeklyRate => '주간 요금';

  @override
  String get nutritionFastingConfigureYourEatingSchedule => '식사 일정 구성';

  @override
  String get nutritionFastingFastingProtocol => '단식 프로토콜';

  @override
  String get nutritionFastingIntermittentFasting => '간헐적 단식';

  @override
  String get nutritionFastingNutritionFasting => '영양 및 단식';

  @override
  String get nutritionFastingProtocol => '규약';

  @override
  String get nutritionFastingSleep => '잠';

  @override
  String get nutritionFastingWake => '깨어 있다';

  @override
  String get nutritionFuel => '연료';

  @override
  String get nutritionGoalsCardBmrBasalMetabolicRate => 'BMR(기초 대사율)';

  @override
  String nutritionGoalsCardBurned(Object caloriesBurned) {
    return '$caloriesBurned 소모';
  }

  @override
  String get nutritionGoalsCardCalories => '칼로리';

  @override
  String get nutritionGoalsCardCarbs => '탄수화물';

  @override
  String get nutritionGoalsCardDailyCalorieTarget => '일일 칼로리 목표';

  @override
  String get nutritionGoalsCardDailyGoals => '일일 목표';

  @override
  String get nutritionGoalsCardEditTargets => '대상 편집';

  @override
  String get nutritionGoalsCardFat => '지방';

  @override
  String get nutritionGoalsCardFemaleConstant => '여성 상수';

  @override
  String get nutritionGoalsCardFemalesHaveDifferentBody => '여성은 신체 구성이 다릅니다';

  @override
  String get nutritionGoalsCardGoalAdjustment => '목표 조정';

  @override
  String get nutritionGoalsCardHowYourTargetsAre => '목표 계산 방법';

  @override
  String get nutritionGoalsCardMaleConstant => '남성 상수';

  @override
  String get nutritionGoalsCardMalesHaveMoreLean => '남성은 제지방량이 더 많습니다';

  @override
  String get nutritionGoalsCardMetabolismSlowsWithAge => '나이가 들수록 신진대사가 느려집니다';

  @override
  String get nutritionGoalsCardMifflinStJeorFormula =>
      'Mifflin-St Jeor 공식 · 자세히 보려면 탭하세요';

  @override
  String get nutritionGoalsCardMifflinStJeorFormula2 =>
      'Mifflin-St Jeor 공식(분석할 수 없는 프로필 데이터)';

  @override
  String get nutritionGoalsCardMoreMassMoreEnergy => '질량이 클수록 휴식 시 에너지 소모가 큽니다';

  @override
  String nutritionGoalsCardPartCalculationInfoSheetActivityMultiplier(
    Object activityMultiplier,
  ) {
    return '활동 계수 (×$activityMultiplier)';
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
    return '매크로 비율 ($displayName: $carbPct/$proteinPct/$fatPct)';
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
    return '5 × $age 세';
  }

  @override
  String get nutritionGoalsCardProtein => '단백질';

  @override
  String get nutritionGoalsCardRecalculate => '재계산';

  @override
  String get nutritionGoalsCardTallerLargerSurfaceArea => '키가 클수록 표면적이 넓습니다';

  @override
  String get nutritionGoalsCardTdeeDailyEnergyNeeds => 'TDEE(일일 에너지 요구량)';

  @override
  String get nutritionJumpToToday => '오늘로 이동';

  @override
  String get nutritionLogAFewDays => '며칠간 기록하여 주기 오버레이 확인하기';

  @override
  String get nutritionLogFood => '음식 기록';

  @override
  String get nutritionLogSomeFoodFirst => '공유하려면 먼저 음식을 기록하세요';

  @override
  String get nutritionLogSomeMealsFirst => '공유하려면 먼저 식사를 기록하세요';

  @override
  String get nutritionMealDeleted => '식사 삭제됨';

  @override
  String get nutritionPatterns45MinReminderPush => '45분 알림 푸시';

  @override
  String get nutritionPatternsAiGuess => 'AI 추측';

  @override
  String get nutritionPatternsAiMoodGuesses => 'AI 기분 추측';

  @override
  String get nutritionPatternsAutoInferMoodFrom =>
      '체크인을 건너뛰면 영양 상태를 통해 기분이 자동으로 추론됩니다.';

  @override
  String get nutritionPatternsBasedOnTheLast => '지난 90일 기준';

  @override
  String get nutritionPatternsCalorieTrends => '칼로리 동향';

  @override
  String get nutritionPatternsCheckInInsights => '체크인 및 통찰력';

  @override
  String get nutritionPatternsCheckInsAreOff => '체크인이 꺼져 있습니다';

  @override
  String get nutritionPatternsFoodsHighestIn => '가장 높은 식품…';

  @override
  String get nutritionPatternsFoodsThatDragYou => '기운을 빠지게 하는 음식';

  @override
  String get nutritionPatternsFoodsThatEnergizeYou => '활력을 주는 음식';

  @override
  String get nutritionPatternsLog3MealsWith =>
      '체크인과 함께 3회 이상의 식사를 기록하여 어떤 음식이 당신에게 활력을 주고 어떤 음식이 당신을 실망시키는지 확인하세요.';

  @override
  String get nutritionPatternsLogAFewMeals => '몇 가지 식사를 기록하여 거시적 추세를 확인하세요.';

  @override
  String get nutritionPatternsLoggedMealsWillShow =>
      '기록된 식사가 여기에 타임라인으로 표시됩니다.';

  @override
  String get nutritionPatternsMealHistory => '식사 기록';

  @override
  String get nutritionPatternsNeedMoreDaysOf => '더 많은 데이터가 필요합니다';

  @override
  String get nutritionPatternsNoFoodsYet => '아직 기록된 음식이 없습니다';

  @override
  String get nutritionPatternsNoMealsLogged => '기록된 식사가 없습니다';

  @override
  String get nutritionPatternsNoPatternsYet => '아직 패턴이 없습니다';

  @override
  String get nutritionPatternsNudgeIfYouSkip => '체크인을 건너뛰면 넛지하세요';

  @override
  String get nutritionPatternsNutritionTrends => '영양 동향';

  @override
  String get nutritionPatternsPostMealCheckIn => '식사 후 체크인';

  @override
  String get nutritionPatternsReEnable => '다시 활성화';

  @override
  String get nutritionPatternsReEnableThePost =>
      '식사 후 체크인 시트를 다시 활성화하여 음식 기분 패턴 구축을 시작하세요.';

  @override
  String get nutritionPatternsSignInToSee => '로그인하여 패턴 확인하기';

  @override
  String get nutritionJournalTab => '일지';

  @override
  String get nutritionPatternsTab => '패턴';

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
    return '목표: $calorieGoal kcal';
  }

  @override
  String nutritionPatternsTabKcalDay(Object avgCalories) {
    return '$avgCalories kcal/일';
  }

  @override
  String nutritionPatternsTabKcalPGC(Object c, Object cal, Object f, Object p) {
    return '$cal kcal · P ${p}g · C ${c}g · F ${f}g';
  }

  @override
  String nutritionPatternsTabLogMealsToSee(Object _METRICS) {
    return '식사를 기록하여 주요 $_METRICS 공급원을 확인하세요.';
  }

  @override
  String nutritionPatternsTabNoMealsThis(Object range) {
    return '이번 $range에 기록된 식사가 없습니다';
  }

  @override
  String nutritionPatternsTabViewAll(Object length) {
    return '$length개 모두 보기';
  }

  @override
  String get nutritionPatternsTheQuickHowDo => '기록 후 나타나는 \"기분이 어떤가요?\" 시트';

  @override
  String get nutritionPatternsTodaySMacros => '오늘의 매크로';

  @override
  String get nutritionPatternsYourBodySResponses => '신체 반응';

  @override
  String get nutritionPreferencesAdd => '추가하다…';

  @override
  String get nutritionPreferencesDailyFoodBudgetUsd => '일일 식량예산(USD, 선택사항)';

  @override
  String get nutritionPreferencesDietAllergens => '다이어트 및 알레르기 유발 물질';

  @override
  String get nutritionPreferencesDishesOrIngredientsYou => '추천에서 제외할 요리나 재료';

  @override
  String get nutritionPreferencesDislikes => '싫어하는 것';

  @override
  String get nutritionPreferencesFoodBudget => '식비 예산';

  @override
  String get nutritionPreferencesFoodsToAvoid => '피해야 할 음식';

  @override
  String get nutritionPreferencesInflammationTolerance => '염증 내성';

  @override
  String get nutritionPreferencesLenient => '허술한';

  @override
  String get nutritionPreferencesMealBudgetUsd => '식사예산(USD)';

  @override
  String get nutritionPreferencesNutritionPreferences => '영양 선호도';

  @override
  String get nutritionPreferencesOtherAllergens => '기타 알레르기 유발 물질';

  @override
  String get nutritionPreferencesOutsideTheFdaBig =>
      'FDA Big 9 이외의 제품(예: 망고, 나이트셰이드, 옥수수)';

  @override
  String get nutritionRecipesTab => '레시피';

  @override
  String get nutritionReview => '검토';

  @override
  String get nutritionSavedToMyFoods => '내 음식에 저장됨';

  @override
  String get nutritionScheduling => '일정을 잡는 중…';

  @override
  String get nutritionScoreCardLogYourMealsTo => '식사를 기록하여 영양 점수 분석을 확인하세요.';

  @override
  String get nutritionScoreCardNutritionScore => '영양 점수';

  @override
  String nutritionScoreCardValue(Object percent) {
    return '$percent%';
  }

  @override
  String get nutritionScoreCardWeeklyNutritionAdherence => '주간 영양 준수도';

  @override
  String nutritionScreenUpdatedYourDailyTarget(Object newCalories) {
    return '일일 목표 업데이트: $newCalories kcal/일';
  }

  @override
  String nutritionScreenWasWeFixedHow(Object oldCalories) {
    return '(기존 $oldCalories). 결핍 계산 방식을 수정했습니다.';
  }

  @override
  String get nutritionSettingsAdjustAiCalorieEstimates =>
      '경험에 맞춰 AI 칼로리 추정치 조정';

  @override
  String get nutritionSettingsAlwaysRules => '항상 규칙';

  @override
  String get nutritionSettingsCalmMode => '진정 모드';

  @override
  String get nutritionSettingsCalorieEstimateBias => '칼로리 추정 편향';

  @override
  String get nutritionSettingsCompactTrackerView => '컴팩트 트래커 보기';

  @override
  String get nutritionSettingsDisableAiFoodTips => 'AI 음식 팁 비활성화';

  @override
  String get nutritionSettingsManageYourFoodLibrary => '빠른 기록을 위해 음식 라이브러리 관리';

  @override
  String get nutritionSettingsNutritionSettings => '영양 설정';

  @override
  String get nutritionSettingsPostMealCheckIn => '식사 후 체크인';

  @override
  String get nutritionSettingsQuickLogMode => '빠른 로그 모드';

  @override
  String get nutritionSettingsRestDayReduction => '휴식일 단축';

  @override
  String get nutritionSettingsSavedFoodsRecipes => '저장된 음식 및 조리법';

  @override
  String get nutritionSettingsScreenAllergens => '알레르기 유발 물질';

  @override
  String get nutritionSettingsScreenBudget => '예산';

  @override
  String get nutritionSettingsScreenCalorieEstimateBias => '칼로리 추정 편향';

  @override
  String get nutritionSettingsScreenCalories => '칼로리';

  @override
  String get nutritionSettingsScreenCarbs => '탄수화물';

  @override
  String get nutritionSettingsScreenCookingSkill => '요리 스킬';

  @override
  String get nutritionSettingsScreenCookingTimeMinutes => '조리시간(분)';

  @override
  String get nutritionSettingsScreenCurrentTargets => '현재 목표';

  @override
  String get nutritionSettingsScreenDietaryRestrictions => '식이 제한';

  @override
  String get nutritionSettingsScreenDue => '로 인한';

  @override
  String get nutritionSettingsScreenEditNutritionGoals => '영양 목표 편집';

  @override
  String get nutritionSettingsScreenEditTargets => '목표 수정';

  @override
  String nutritionSettingsScreenErrorSavingSettings(Object e) {
    return '설정 저장 오류: $e';
  }

  @override
  String get nutritionSettingsScreenFat => '지방';

  @override
  String get nutritionSettingsScreenFoodPreferences => '음식 선호도';

  @override
  String get nutritionSettingsScreenGoalsUpdatedAndTargets =>
      '목표가 업데이트되고 목표가 다시 계산되었습니다!';

  @override
  String get nutritionSettingsScreenMealPattern => '식사 패턴';

  @override
  String get nutritionSettingsScreenNoGoalsSet => '설정된 목표 없음';

  @override
  String get nutritionSettingsScreenPrimary => '주요한';

  @override
  String get nutritionSettingsScreenProtein => '단백질';

  @override
  String get nutritionSettingsScreenRateOfChange => '변화율';

  @override
  String get nutritionSettingsScreenRecalculateFromProfile => '프로필에서 재계산';

  @override
  String get nutritionSettingsScreenReviewAdjustTargets => '목표 검토 및 조정';

  @override
  String get nutritionSettingsScreenRunWeeklyCheckIn => '주간 체크인 실행';

  @override
  String get nutritionSettingsScreenSaveRecalculate => '저장 및 다시 계산';

  @override
  String get nutritionSettingsScreenSelectYourGoalsFirst =>
      '목표를 선택하세요(첫 번째 선택 = 기본)';

  @override
  String get nutritionSettingsScreenTrainingDay => '훈련일';

  @override
  String nutritionSettingsScreenUi1Value(Object length) {
    return '+$length';
  }

  @override
  String nutritionSettingsScreenUiExampleACalMeal(Object exampleCal) {
    return '예: 600 cal 식사는 $exampleCal cal로 기록됩니다';
  }

  @override
  String nutritionSettingsScreenUiMin(Object t) {
    return '$t분';
  }

  @override
  String nutritionSettingsScreenUiX(Object multiplier) {
    return '${multiplier}x';
  }

  @override
  String get nutritionSettingsScreenUnderMore => '더보기 아래';

  @override
  String get nutritionSettingsScreenWeeklyGoal => '주간 목표';

  @override
  String get nutritionSettingsScreenYourGoals => '당신의 목표';

  @override
  String get nutritionSettingsScreenYourPreferences => '귀하의 선호 사항';

  @override
  String get nutritionSettingsShowMacrosOnLog => '로그에 매크로 표시';

  @override
  String get nutritionSettingsStandingRulesZealovaApplies =>
      'Zealova가 모든 음식 분석에 적용하는 기본 규칙';

  @override
  String get nutritionSettingsStreakFreezeUsedYour =>
      '연속 동결 사용! 귀하의 연속 기록이 보호됩니다.';

  @override
  String get nutritionSettingsTargetsRecalculatedFromYour =>
      '귀하의 프로필에서 목표가 다시 계산되었습니다.';

  @override
  String get nutritionSettingsTrainingDayBoost => '트레이닝 데이 부스트';

  @override
  String get nutritionSettingsWeeklyCheckInReminders => '주간 체크인 알림';

  @override
  String get nutritionSettingsWeeklyView => '주간 보기';

  @override
  String get nutritionShowcase11Dishes4Sections => '요리 11개 · 섹션 4개';

  @override
  String get nutritionShowcaseAnalyze => '분석하다';

  @override
  String get nutritionShowcaseCacioEPepe => '카시오 에 페페';

  @override
  String get nutritionShowcaseDesserts => '디저트';

  @override
  String get nutritionShowcaseDinner => '저녁';

  @override
  String get nutritionShowcaseFieldCarbs => '탄수화물';

  @override
  String get nutritionShowcaseFieldFat => '지방';

  @override
  String get nutritionShowcaseFieldProtein => '단백질';

  @override
  String get nutritionShowcaseFilter => '필터';

  @override
  String get nutritionShowcaseFoodDb => '푸드DB';

  @override
  String get nutritionShowcaseGrilledSalmonBowl => '구운 연어 그릇';

  @override
  String get nutritionShowcaseIntroSubtitle =>
      '메뉴판을 스캔하세요 — Zealova가 목표에 맞춰 모든 메뉴를 순위화해요 🍽️';

  @override
  String get nutritionShowcaseIntroTitle => '이제 메뉴 고민은 그만';

  @override
  String get nutritionShowcaseLunchDinner => '— 점심 및 저녁 —';

  @override
  String get nutritionShowcaseMenuAnalyzed => '메뉴 분석 완료';

  @override
  String get nutritionShowcaseMultiplePagesSnapThem => '여러 페이지? 모두 찍어보세요.';

  @override
  String get nutritionShowcaseNoDishesSelectedGo =>
      '선택한 요리가 없습니다. 돌아가서 몇 가지를 선택하세요.';

  @override
  String get nutritionShowcaseRecent => '최근의';

  @override
  String get nutritionShowcaseSaved => '저장됨';

  @override
  String get nutritionShowcaseScanningMenu => '메뉴 스캔 중…';

  @override
  String nutritionShowcaseScreenCalJustNow(Object cal) {
    return '$cal cal · 방금 전';
  }

  @override
  String nutritionShowcaseScreenG(Object price, Object weightG) {
    return '$weightG g · $price';
  }

  @override
  String nutritionShowcaseScreenOfCal(Object _calorieGoal) {
    return '/ $_calorieGoal cal';
  }

  @override
  String nutritionShowcaseScreenSelected(Object length) {
    return '$length개 선택됨';
  }

  @override
  String nutritionShowcaseScreenValue(Object count) {
    return '· $count';
  }

  @override
  String get nutritionShowcaseSort => '종류:';

  @override
  String get nutritionShowcaseSortCleared => '정렬 해제 — 원래 메뉴 순서';

  @override
  String get nutritionShowcaseSortHint =>
      '눌러보세요 — \'단백질\'을 탭해 정렬. 탄수화물, 지방, 염증 기준으로도 정렬돼요.';

  @override
  String nutritionShowcaseSortedHighest(Object field) {
    return '정렬 완료 ✓ — $field 높은 순';
  }

  @override
  String get nutritionShowcaseSortedLeastInflammatory => '정렬 완료 ✓ — 염증 낮은 순';

  @override
  String nutritionShowcaseSortedLowest(Object field) {
    return '정렬 완료 ✓ — $field 낮은 순';
  }

  @override
  String get nutritionShowcaseSortedMostInflammatory => '정렬 완료 ✓ — 염증 높은 순';

  @override
  String get nutritionShowcaseStarters => '스타터';

  @override
  String get nutritionShowcaseTapADishTo => '요리를 탭하여 선택하세요';

  @override
  String get nutritionShowcaseTapBelowToScan => '아래를 탭하여 메뉴 스캔';

  @override
  String get nutritionShowcaseTheBistro => '비스트로';

  @override
  String get nutritionShowcaseTiramisu => '티라미수';

  @override
  String get nutritionShowcaseToday => '오늘';

  @override
  String get nutritionShowcaseWhatDidYouEat => '무엇을 드셨나요?';

  @override
  String get nutritionSignInToView => '로그인하여 영양 통계 보기';

  @override
  String get nutritionStreakCardBestEver => '최고 기록';

  @override
  String nutritionStreakCardBestTotalDays(Object best, Object total) {
    return '최고 $best · 총 $total일';
  }

  @override
  String nutritionStreakCardCouldNotUseFreeze(Object e) {
    return '동결을 사용할 수 없음: $e';
  }

  @override
  String get nutritionStreakCardCurrent => '현재의';

  @override
  String nutritionStreakCardDayStreak(Object streakDays) {
    return '$streakDays일 연속';
  }

  @override
  String nutritionStreakCardDays(Object logged, Object target) {
    return '$logged / $target일';
  }

  @override
  String get nutritionStreakCardFreezesAvailable => '사용 가능한 프리즈';

  @override
  String get nutritionStreakCardLogAMealTo => '식사를 기록하여 스트릭 시작하기';

  @override
  String get nutritionStreakCardStreakFreezeUsedYour =>
      'Streak Freeze를 사용했습니다. 연속 기록은 안전합니다.';

  @override
  String get nutritionStreakCardThisWeek => '이번 주';

  @override
  String get nutritionStreakCardTotalDaysLogged => '총 기록 일수';

  @override
  String get nutritionStreakCardUseAFreeze => '프리즈 사용';

  @override
  String get nutritionStreakCardUseFreeze => '프리즈 사용';

  @override
  String get nutritionStreakCardUsing => '사용 중…';

  @override
  String get nutritionStreakCardYourStreak => '나의 스트릭';

  @override
  String nutritionTabPartAdherenceCardLastWeeks(Object length) {
    return '지난 $length주';
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
  String get nutritionTabPartAdherenceConsistency => '접착력 및 일관성';

  @override
  String get nutritionTabPartAvgCalories => '평균 칼로리';

  @override
  String get nutritionTabPartAvgProtein => '평균 단백질';

  @override
  String get nutritionTabPartCalorieTrend => '칼로리 추세';

  @override
  String get nutritionTabPartCarbs => '탄수화물';

  @override
  String get nutritionTabPartConsistency => '일관성';

  @override
  String get nutritionTabPartCouldNotLoadAdherence => '준수도 데이터를 불러올 수 없습니다';

  @override
  String get nutritionTabPartCouldNotLoadCalorie => '칼로리 데이터를 불러올 수 없습니다';

  @override
  String get nutritionTabPartCouldNotLoadMacros => '매크로 데이터를 불러올 수 없습니다';

  @override
  String get nutritionTabPartCouldNotLoadTdee => 'TDEE 데이터를 불러올 수 없습니다';

  @override
  String get nutritionTabPartDaysLogged => '기록 일수';

  @override
  String get nutritionTabPartFat => '지방';

  @override
  String get nutritionTabPartLogging => '벌채 반출';

  @override
  String get nutritionTabPartMacroBreakdown => '매크로 분석';

  @override
  String get nutritionTabPartNoMacroDataThis => '이번 주 매크로 데이터 없음';

  @override
  String get nutritionTabPartNoNutritionDataThis => '이번 주 영양 데이터 없음';

  @override
  String get nutritionTabPartNotEnoughDataFor => 'TDEE 추정을 위한 데이터 부족';

  @override
  String get nutritionTabPartProtein => '단백질';

  @override
  String get nutritionTabPartTdeeEnergyBalance => 'TDEE 및 에너지 균형';

  @override
  String get nutritionTabPartWeeklyAverageDistribution => '주간 평균 분포';

  @override
  String get nutritionTabPartWeeklyOverview => '주간 개요';

  @override
  String nutritionTabPartWeeklyOverviewCardAvgCal(Object averageDailyCalories) {
    return '평균 $averageDailyCalories cal';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardAvgIntakeCal(Object avgIntake) {
    return '평균 섭취량: $avgIntake cal';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardCalDay(Object uncertaintyDisplay) {
    return 'cal/일 $uncertaintyDisplay';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardG(Object avgProtein) {
    return '${avgProtein}g';
  }

  @override
  String nutritionTabPartWeeklyOverviewCardG2(Object grams) {
    return '${grams}g';
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
    return '체중: $formattedWeeklyRate';
  }

  @override
  String get nutritionTabPartWeeksAnalyzed => '분석된 주';

  @override
  String get nutritionTabPartWeight => '무게';

  @override
  String get nutritionTourIntermittentFasting => '간헐적 단식';

  @override
  String get nutritionTourSaved => '저장됨';

  @override
  String get nutritionTourStartAndTrackA =>
      '여기에서 바로 단식을 시작하고 추적하세요. 실시간 단식 기간이 이 카드에 표시됩니다.';

  @override
  String get nutritionTourSwipeThroughDates => '날짜를 스와이프하세요';

  @override
  String get nutritionTourTapTheCameraBarcode =>
      '카메라, 바코드 또는 + 버튼을 탭하세요. 비전 OCR이 칼로리와 매크로를 자동으로 채워줍니다.';

  @override
  String get nutritionTourUseTheDateArrows =>
      '날짜 화살표를 사용하거나 기록을 탭하여 지난 날을 검토하세요.';

  @override
  String get nutritionTourYourSavedRecipesFoods =>
      '저장된 레시피, 음식, 스캔한 메뉴가 여기에 저장됩니다. 탭 한 번으로 다시 기록할 수 있습니다.';

  @override
  String get nutritionUndo => '끄르다';

  @override
  String get offlineBannerDismissSyncFailureBanner => '동기화 실패 배너 닫기';

  @override
  String get offlineModeOfflineMode => '오프라인 모드';

  @override
  String get offlineModeWorkOutWithoutInternet =>
      '인터넷 없이 운동하세요. 기기 내 AI, 사전 캐시된 운동, 운동 영상 다운로드 및 백그라운드 동기화가 지원됩니다.';

  @override
  String get onboardingAlreadyHaveAccount => '이미 계정이 있습니다';

  @override
  String get onboardingBlockerLetSDoIt => '시작해 봅시다';

  @override
  String get onboardingBlockerNoJudgmentKnowingThe =>
      '판단하지 않습니다. 한계를 아는 것이 계획의 시작입니다.';

  @override
  String get onboardingBlockerThatMakesSense => '이해가 됩니다.';

  @override
  String get onboardingBlockerWhatSHeldYou => '이전에는 무엇이 방해가 되었나요?';

  @override
  String get onboardingConfidenceARealisticPlaceTo => '현실적인 시작점입니다.';

  @override
  String get onboardingConfidenceBeHonestThereIs => '솔직해지세요. 틀린 답은 없습니다.';

  @override
  String get onboardingConfidenceFullyIn => '완벽히 준비됨';

  @override
  String get onboardingConfidenceHowConfidentAreYou => '목표 달성에 얼마나 자신 있으신가요?';

  @override
  String get onboardingConfidenceNotSureYet => '아직 잘 모르겠어요';

  @override
  String onboardingConfidenceScreenHowConfidentAreYou(Object name) {
    return '$name님, 목표를 달성할 수 있다고 얼마나 확신하시나요?';
  }

  @override
  String onboardingConfidenceScreenOutOf(Object value) {
    return '10점 만점에 $value점';
  }

  @override
  String get onboardingConfidenceStartingUnsureIsHonest =>
      '확신 없이 시작하는 것도 솔직한 모습입니다.';

  @override
  String get onboardingConfidenceThatBeliefWillCarry => '그 믿음이 당신을 이끌어줄 것입니다.';

  @override
  String get onboardingContinueButton => '계속';

  @override
  String get onboardingGetStarted => '시작하기';

  @override
  String get onboardingReflectHereSWhatWe => '저희가 들은 내용은 다음과 같습니다.';

  @override
  String get onboardingSkip => '건너뛰기';

  @override
  String get onboardingValueHereSWhatThat => '각각 구독할 경우 발생하는 비용입니다.';

  @override
  String onboardingValueScreenMo(Object priceLabel) {
    return '$priceLabel/월';
  }

  @override
  String get onboardingValueSeeMyPlan => '내 플랜 보기';

  @override
  String get onboardingValueSeeMyPlanAnd => '내 플랜 및 가격 보기';

  @override
  String get onboardingValueSeparateApps => '개별 앱';

  @override
  String get onboardingValueThreeToolsOneApp => '세 가지 도구. 하나의 앱.';

  @override
  String get onboardingValueZealovaAllOfIt => 'Zealova, 모든 기능 포함';

  @override
  String get onboardingWhyFirstTheWhy => '먼저, 이유부터';

  @override
  String get onboardingWhyWhatSDrivingThis => '무엇이 당신을 움직이게 하나요?';

  @override
  String get openAllCrates24HoursOf2xXp => '24시간 2x XP';

  @override
  String get openAllCratesActivityCrate => '액티비티 상자';

  @override
  String get openAllCratesBonusCrateToOpen => '열 수 있는 보너스 상자';

  @override
  String openAllCratesCollect(Object arg0, Object arg1) {
    return '받기 ($arg0/$arg1)';
  }

  @override
  String openAllCratesCratesOpened(Object arg0) {
    return '상자 $arg0개 개봉!';
  }

  @override
  String get openAllCratesDailyCrate => '데일리 상자';

  @override
  String get openAllCratesDone => '완료';

  @override
  String get openAllCratesDoubleXpToken => '더블 XP 토큰';

  @override
  String get openAllCratesFailedToOpenCrates => '상자를 여는 데 실패했습니다. 다시 시도해주세요.';

  @override
  String get openAllCratesFitnessCrate => '피트니스 상자';

  @override
  String openAllCratesGainedXp(Object arg0) {
    return '+$arg0 XP';
  }

  @override
  String get openAllCratesMaxLevel => '최대 레벨';

  @override
  String get openAllCratesOpenYourCrates => '🎁 상자 열기';

  @override
  String get openAllCratesOpeningYourCrates => '🎁 상자 여는 중…';

  @override
  String openAllCratesPickRewardPerDay(Object arg0, Object arg1) {
    return '하루에 보상 1개 선택 • $arg0/$arg1 선택됨';
  }

  @override
  String openAllCratesPickYourReward(Object arg0, Object arg1) {
    return '보상 선택 • $arg0/$arg1 선택됨';
  }

  @override
  String get openAllCratesProtectYourStreak => '연속 기록 보호';

  @override
  String get openAllCratesSelectAll => '모두 선택';

  @override
  String get openAllCratesStreakCrate => '스트릭 상자';

  @override
  String get openAllCratesStreakShield => '스트릭 실드';

  @override
  String get openAllCratesToday => '오늘';

  @override
  String openAllCratesTotalXpFormatted(Object arg0) {
    return '총 $arg0';
  }

  @override
  String openAllCratesTotalXpLevel(Object arg0, Object arg1) {
    return '총: $arg0 XP • 레벨 $arg1';
  }

  @override
  String get openAllCratesUd83cUdf89Rewards => '🎉 보상!';

  @override
  String openAllCratesXpInLevel(Object arg0, Object arg1) {
    return '$arg0 / $arg1 XP';
  }

  @override
  String openAllCratesXpToNextLevel(Object arg0, Object arg1) {
    return '레벨 $arg1까지 $arg0 XP';
  }

  @override
  String get openAllCratesYesterday => '어제';

  @override
  String get overallScoreHeroOverall => '종합';

  @override
  String get overviewActiveSkill => '활성 스킬';

  @override
  String get overviewActiveStreaks => '활성 스트릭';

  @override
  String get overviewBodyMeasurements => '신체 측정';

  @override
  String get overviewCouldnTRefreshShowing => '새로고침할 수 없습니다. 캐시된 데이터를 표시합니다.';

  @override
  String get overviewCycle => '주기';

  @override
  String get overviewExerciseHistory => '운동 기록';

  @override
  String get overviewLastWeek => '지난주';

  @override
  String get overviewMuscleAnalytics => '근육 분석';

  @override
  String get overviewMy1rms => '내 1RM';

  @override
  String get overviewNoAchievementsYet => '아직 달성한 업적이 없습니다';

  @override
  String get overviewNoPersonalRecordsYet => '아직 기록된 개인 최고 기록이 없습니다';

  @override
  String get overviewPersonalRecords => '개인 최고 기록';

  @override
  String get overviewPersonalRecordsAreTracked =>
      '운동을 완료하면 개인 최고 기록이 추적됩니다. 지금 바로 운동을 시작하고 진행 상황을 확인하세요!';

  @override
  String get overviewQuickAccess => '빠른 접근';

  @override
  String get overviewRecentAchievements => '최근 업적';

  @override
  String get overviewRecentTrophy => '최근 트로피';

  @override
  String get overviewReportsInsights => '리포트 및 인사이트';

  @override
  String get overviewRewards => '보상';

  @override
  String get overviewSocial => '소셜';

  @override
  String get overviewStatsRewardsTabHas => '통계 및 보상 탭에서 모든 추가 기능을 확인하세요.';

  @override
  String get overviewStreak => '스트릭';

  @override
  String overviewTabReady(Object ready) {
    return '$ready 준비 완료';
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
    return '운동 $workouts회 • PR $prs개';
  }

  @override
  String get overviewTime => '시간';

  @override
  String get overviewTotal => '합계';

  @override
  String get overviewViewAll => '모두 보기';

  @override
  String get overviewViewPerks => '혜택 보기';

  @override
  String get overviewWeek => '주';

  @override
  String get paceChartExpand => '확장';

  @override
  String get paceChartPace => '페이스';

  @override
  String parsedExercisesPreviewSheetEdit(Object name) {
    return '$name 편집';
  }

  @override
  String parsedExercisesPreviewSheetParsedExercises(Object length) {
    return '$length개 운동 파싱됨';
  }

  @override
  String parsedExercisesPreviewSheetValue(
    Object exercise,
    Object formattedSetsReps,
  ) {
    return '$formattedSetsReps @ $exercise';
  }

  @override
  String get pauseInterceptGoingOnVacationLife => '휴가를 떠나시나요? 바쁜 일정이 있으신가요?';

  @override
  String get pauseInterceptLongerBreakIllnessTransi => '장기 휴식 — 질병, 환경 변화, 일상';

  @override
  String get pauseInterceptNoThanksContinueWith => '아니요, 취소하고 계속할게요';

  @override
  String get pauseInterceptPauseFor14Days => '14일간 일시 정지';

  @override
  String get pauseInterceptPauseFor30Days => '30일간 일시 정지';

  @override
  String get pauseInterceptPauseYourPlanInstead =>
      '플랜을 일시 정지하세요. 중단한 지점부터 바로 다시 시작할 수 있습니다.';

  @override
  String get pauseInterceptQuickBreakShortTrip => '짧은 휴식 — 단기 여행, 바쁜 한 주';

  @override
  String pauseInterceptSheetCouldnTPause(Object e) {
    return '일시 정지 실패: $e';
  }

  @override
  String get pauseSubscription1Month => '1개월';

  @override
  String get pauseSubscription1Week => '1주';

  @override
  String get pauseSubscription2Months => '2개월';

  @override
  String get pauseSubscription2Weeks => '2주';

  @override
  String get pauseSubscription3Months => '3개월';

  @override
  String get pauseSubscriptionAutoResumeDate => '자동 재개 날짜';

  @override
  String get pauseSubscriptionBillingIsPaused => '결제가 일시 중지되었습니다';

  @override
  String get pauseSubscriptionDataIsPreserved => '데이터가 보존됩니다';

  @override
  String get pauseSubscriptionExtendedBreak => '장기 휴식';

  @override
  String get pauseSubscriptionHowLongDoYou => '얼마나 쉬시겠어요?';

  @override
  String get pauseSubscriptionLimitedAccess => '제한된 액세스';

  @override
  String get pauseSubscriptionLongPause => '장기 일시 정지';

  @override
  String get pauseSubscriptionMaximumPause => '최대 일시 정지';

  @override
  String pauseSubscriptionPauseForDuration(Object duration) {
    return '$duration 동안 일시 중지';
  }

  @override
  String pauseSubscriptionPausePlan(Object planName) {
    return '$planName 일시 중지';
  }

  @override
  String get pauseSubscriptionPremiumFeaturesAre => '프리미엄 기능은 일시적으로 사용할 수 없습니다';

  @override
  String get pauseSubscriptionSelectADuration => '기간 선택';

  @override
  String get pauseSubscriptionShortBreak => '단기 휴식';

  @override
  String get pauseSubscriptionTakeABreakWithout => '데이터 손실 없이 잠시 쉬어가세요';

  @override
  String get pauseSubscriptionVacationMode => '휴가 모드';

  @override
  String get pauseSubscriptionWhatHappensWhenYou => '일시 정지 시 발생하는 일';

  @override
  String get pauseSubscriptionYouWontBeCharged => '일시 중지 기간 동안에는 요금이 청구되지 않습니다';

  @override
  String get pauseSubscriptionYourWorkoutHistory => '운동 기록 및 진행 상황은 안전하게 유지됩니다';

  @override
  String get paywallFeatures14Features => '14개 이상의 기능';

  @override
  String get paywallFeatures3Tools => '3가지 도구';

  @override
  String get paywallFeatures52Skills => '52가지 스킬';

  @override
  String get paywallFeatures7DayFreeTrial => '7일 무료 체험\n언제든 취소 가능, 조건 없음';

  @override
  String get paywallFeaturesAiCoachChat => 'AI 코치 채팅';

  @override
  String get paywallFeaturesAiCoachExperience => 'AI 코치 경험';

  @override
  String get paywallFeaturesAiWorkouts => 'AI 운동';

  @override
  String get paywallFeaturesAutoAdaptWorkoutsAround => '부상 부위에 맞춰 운동 자동 조정';

  @override
  String get paywallFeaturesChartsHeatmapsAndDetailed => '차트, 히트맵 및 상세 트렌드';

  @override
  String get paywallFeaturesFoodPhotoScanning => '음식 사진 스캔';

  @override
  String get paywallFeaturesInjuryAware => '부상 방지';

  @override
  String get paywallFeaturesInjuryAwareTraining => '부상 방지 트레이닝';

  @override
  String get paywallFeaturesLearnMore => '더 알아보기';

  @override
  String get paywallFeaturesNutritionFormRecoveryAs =>
      '영양, 자세, 회복 — 무엇이든 물어보세요';

  @override
  String get paywallFeaturesPersonalizedPlansForAny =>
      '모든 장비와 목표에 맞춘 개인 맞춤형 플랜';

  @override
  String get paywallFeaturesProgressTrackingAnalytics => '진행 상황 추적 및 분석';

  @override
  String get paywallFeaturesSafety => '안전';

  @override
  String get paywallFeaturesSnapAPhotoGet => '사진을 찍어 칼로리와 매크로를 즉시 확인하세요';

  @override
  String get paywallFeaturesUnlimitedAiWorkouts => '무제한 AI 운동';

  @override
  String get paywallFeaturesUnlockTheFull => '모든 기능 잠금 해제';

  @override
  String get paywallPricing => ' • ';

  @override
  String get paywallPricing45Min => '45분';

  @override
  String get paywallPricing7DayFreeTrial => '7일 무료 체험';

  @override
  String get paywallPricing7DayFreeTrial2 => '7일 무료 체험\n언제든지 취소 가능, 추가 질문 없음';

  @override
  String get paywallPricingAi6Exercises => 'AI · 6가지 운동';

  @override
  String get paywallPricingBestValue => '최고의 가성비';

  @override
  String get paywallPricingBilledSecurelyThroughThe => 'App Store를 통해 안전하게 결제됨';

  @override
  String get paywallPricingCancelAnytime => '언제든지 취소 가능';

  @override
  String get paywallPricingChangePlan => '플랜 변경';

  @override
  String get paywallPricingChestShouldersTriceps => '· 가슴 · 어깨 · 삼두';

  @override
  String get paywallPricingFreeFor7Days => '7일 무료. 언제든지 취소 가능.';

  @override
  String get paywallPricingIn5DaysReminder => '5일 후 · 알림';

  @override
  String get paywallPricingIn7DaysBilling => '7일 후 · 결제 시작';

  @override
  String get paywallPricingIsReady => '준비 완료';

  @override
  String get paywallPricingLessThanThePrice => '매주 커피 한 잔보다 저렴한 가격';

  @override
  String get paywallPricingMonthly => '월간';

  @override
  String get paywallPricingNoPaymentDueNow => '지금 결제할 금액 없음';

  @override
  String get paywallPricingNoPaymentDueNow2 => '지금 결제할 금액 없음';

  @override
  String get paywallPricingNoPurchasesFound => '구매 내역을 찾을 수 없음';

  @override
  String get paywallPricingNoSurprisesCancelAnytime =>
      '추가 비용 없음. 7일 차 이전에 설정에서 언제든지 취소 가능.';

  @override
  String get paywallPricingPlanUpdatedSuccessfully => '플랜이 성공적으로 업데이트되었습니다!';

  @override
  String get paywallPricingPurchasesRestored => '구매 항목이 복원되었습니다!';

  @override
  String get paywallPricingPushDay => '푸시 데이';

  @override
  String get paywallPricingRestore => '복원';

  @override
  String get paywallPricingScreen5999Year => '\$59.99/년';

  @override
  String get paywallPricingScreenBackToPlans => '플랜으로 돌아가기';

  @override
  String get paywallPricingScreenConfirmChange => '변경 확인';

  @override
  String get paywallPricingScreenConfirmPlanChange => '플랜 변경 확인';

  @override
  String get paywallPricingScreenConfirmUpgrade => '업그레이드 확인';

  @override
  String get paywallPricingScreenCurrentPlan => '현재 플랜';

  @override
  String get paywallPricingScreenExclusiveYearlyDiscountJust =>
      '회원님만을 위한 독점 연간 할인!';

  @override
  String get paywallPricingScreenGetYearlyFor37 => '\$37.49에 연간 플랜 이용하기';

  @override
  String get paywallPricingScreenJust312Month => '월 \$3.12';

  @override
  String get paywallPricingScreenNewPlan => '새 플랜';

  @override
  String get paywallPricingScreenNoThanksILl => '아니요, 괜찮습니다';

  @override
  String get paywallPricingScreenOfferExpired => '제안 만료됨';

  @override
  String get paywallPricingScreenOfferExpiresIn => '제안 만료까지 남은 시간: ';

  @override
  String get paywallPricingScreenPremiumYearly => '프리미엄 연간';

  @override
  String get paywallPricingScreenPriceDifference => ' 가격 차이';

  @override
  String get paywallPricingScreenSave125025 => '\$12.50 절약 (25% 할인)';

  @override
  String get paywallPricingScreenThatSJust0 => '하루 단 \$0.10 — 커피 한 잔보다 저렴합니다';

  @override
  String get paywallPricingScreenThisSpecialDiscountIs =>
      '이 특별 할인은 더 이상 제공되지 않습니다.';

  @override
  String get paywallPricingScreenWaitSpecialOffer => '잠시만요! 특별 제안';

  @override
  String paywallPricingScreenYear(Object yearlyTotal) {
    return '$yearlyTotal/년';
  }

  @override
  String get paywallPricingScreenYouCanStillGet =>
      '여전히 프리미엄 연간 플랜을 다음 가격에 이용할 수 있습니다';

  @override
  String get paywallPricingScreenYouWillBeUpgraded => '즉시 업그레이드됩니다';

  @override
  String get paywallPricingStartWithA7 =>
      '7일 무료 체험으로 시작하세요. 언제든지 취소 가능하며, 체험 기간이 끝날 때까지 결제되지 않습니다.';

  @override
  String get paywallPricingStartYour7Day => '계속하려면 7일 무료\n체험을 시작하세요';

  @override
  String get paywallPricingTerms => '이용 약관';

  @override
  String get paywallPricingToday => '오늘';

  @override
  String get paywallPricingUnlockUnlimitedAiWorkouts =>
      '무제한 AI 운동, 음식 스캔 및 매크로, 자세 분석, 전체 진행 상황 추적 기능을 잠금 해제하세요.';

  @override
  String get paywallPricingWeLlSendYou => '무료 체험 종료 전에\n알림을 보내드립니다';

  @override
  String get paywallPricingWhatYouGet => '제공 혜택';

  @override
  String get paywallPricingYearly => '연간';

  @override
  String get paywallPricingYouAreAlreadyOn => '이미 이 플랜을 사용 중입니다';

  @override
  String get paywallPricingYouReAllSet => '준비 완료되었습니다. 체험이 활성화되었습니다.';

  @override
  String get paywallPricingYourAiCoach => '나만의 AI 코치';

  @override
  String get paywallTimelineCancelAnytimeDuringOr =>
      '체험 기간 중이나 종료 후 언제든지 취소할 수 있습니다. 체험이 끝날 때까지 결제되지 않으며, Google Play에서 구독을 관리할 수 있습니다.';

  @override
  String get paywallTimelineHowYourFree => '무료 체험';

  @override
  String get paywallTimelineHowYourFreeTrial => '무료 체험 작동 방식';

  @override
  String get paywallTimelineIn5Days => '5일 후';

  @override
  String get paywallTimelineIn7Days => '7일 후';

  @override
  String paywallTimelineScreenFirstCharge(Object dateFormat) {
    return '첫 결제일: $dateFormat';
  }

  @override
  String paywallTimelineScreenYouLlBeCharged(Object dateFormat) {
    return '$dateFormat에 결제됩니다. 언제든지 취소 가능하며 별도의 질문은 하지 않습니다.';
  }

  @override
  String get paywallTimelineToday => '오늘';

  @override
  String get paywallTimelineTrialWorks => '체험 작동 방식';

  @override
  String get paywallTimelineUnlimitedWorkoutsFoodScann =>
      '무제한 운동, 음식 스캔, 부상 추적, 스킬 향상 등';

  @override
  String get paywallTimelineWeLlRemindYou =>
      '체험 종료 전에 미리 알려드립니다 - 추가 비용 걱정 마세요';

  @override
  String pendingRequestCardValue(Object message) {
    return '\"$message\"';
  }

  @override
  String get pendingRequestCardViewProfile => '프로필 보기';

  @override
  String get permissionsPrimerAFewQuickPermissions => '몇 가지 빠른 권한 설정';

  @override
  String get permissionsPrimerCamera => '카메라';

  @override
  String get permissionsPrimerEachAppFeatureWill =>
      '각 앱 기능은 요청하기 전에 먼저 설명해 드립니다.';

  @override
  String get permissionsPrimerGrantPermissions => '권한 허용';

  @override
  String get permissionsPrimerGrantingTheseNowMeans =>
      '지금 권한을 허용하면 운동 중에 갑작스러운 알림 없이 모든 기능을 바로 사용할 수 있습니다.';

  @override
  String get permissionsPrimerMicrophone => '마이크';

  @override
  String get permissionsPrimerNotNow => '나중에';

  @override
  String get permissionsPrimerNotifications => '알림';

  @override
  String get permissionsPrimerPhotos => '사진';

  @override
  String get personalBestsGrid => '⏱️';

  @override
  String get personalBestsGridHeaviestLift => '최고 중량';

  @override
  String personalBestsGridLb(Object weightLb) {
    return '$weightLb lb';
  }

  @override
  String get personalBestsGridLongestSession => '최장 운동 시간';

  @override
  String get personalBestsGridMostVolume => '최대 볼륨';

  @override
  String get personalGoalsActiveGoals => '진행 중인 목표';

  @override
  String get personalGoalsDeleteGoal => '목표를 삭제할까요?';

  @override
  String get personalGoalsFullRecordsViewComing =>
      '전체 기록 보기는 향후 업데이트에서 제공될 예정입니다';

  @override
  String get personalGoalsMaxReps => '최대 횟수';

  @override
  String get personalGoalsNewGoal => '새 목표';

  @override
  String get personalGoalsNewPrs => '새로운 PR';

  @override
  String get personalGoalsNoGoalsThisWeek => '이번 주 목표 없음';

  @override
  String get personalGoalsPersonalRecords => '개인 최고 기록';

  @override
  String get personalGoalsReps => '회';

  @override
  String personalGoalsScreenDeleted(Object exerciseName) {
    return '\"$exerciseName\" 삭제됨';
  }

  @override
  String personalGoalsScreenPermanentlyDeleteThisCannot(Object exerciseName) {
    return '\"$exerciseName\"을(를) 영구 삭제할까요? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String personalGoalsScreenViewAllRecords(Object length) {
    return '$length개의 기록 모두 보기';
  }

  @override
  String get personalGoalsSetAWeeklyChallenge => '한계를 뛰어넘기 위해 주간 챌린지를 설정하세요!';

  @override
  String get personalGoalsSetYourFirstGoal => '첫 번째 목표 설정하기';

  @override
  String get personalGoalsSomethingWentWrong => '문제가 발생했습니다';

  @override
  String get personalGoalsThisWeek => '이번 주';

  @override
  String get personalGoalsTryAgain => '다시 시도';

  @override
  String get personalGoalsUnknownError => '알 수 없는 오류';

  @override
  String get personalGoalsWeeklyGoals => '주간 목표';

  @override
  String get personalGoalsWeeklyVolume => '주간 볼륨';

  @override
  String get personalInfoACoupleFinalDetails => '마지막으로 몇 가지 정보만 더 입력해주세요';

  @override
  String get personalInfoDateOfBirth => '생년월일';

  @override
  String get personalInfoDoYouTrackA => '생리 주기를 기록하시나요?';

  @override
  String get personalInfoFirstName => '이름';

  @override
  String get personalInfoNoThanks => '아니요, 괜찮습니다';

  @override
  String get personalInfoPleaseCompleteTheBody => '먼저 신체 지표 단계를 완료해주세요.';

  @override
  String personalInfoScreenFailedToSave(Object e) {
    return '저장 실패: $e';
  }

  @override
  String get personalInfoWeUseTheseTo =>
      '이 정보는 코칭을 개인화하고 계정을 안전하게 보호하는 데 사용됩니다.';

  @override
  String get personalInfoYesSetItUp => '네, 설정할게요';

  @override
  String get personalInfoYouMustBeAt => 'Zealova를 사용하려면 만 16세 이상이어야 합니다.';

  @override
  String get personalInfoYourName => '이름';

  @override
  String get personalRecordsAllTime => '전체 기간';

  @override
  String get personalRecordsCard1MonthAgo => '1개월 전';

  @override
  String get personalRecordsCard1WeekAgo => '1주 전';

  @override
  String get personalRecordsCardAfternoonTip =>
      '수분을 유지하세요! 운동 전 최소 500ml의 물을 마시는 것을 목표로 하세요.';

  @override
  String get personalRecordsCardAskCoachForMore => '코치에게 더 많은 팁을 물어보세요';

  @override
  String get personalRecordsCardCoachTip => '코치 팁';

  @override
  String get personalRecordsCardCompleteWorkoutsToPR =>
      '운동을 완료하여 개인 최고 기록을 세워보세요';

  @override
  String get personalRecordsCardConnectHealthToTrack => '건강 앱을 연결하여 추적하세요';

  @override
  String personalRecordsCardDaysAgo(Object days) {
    return '$days일 전';
  }

  @override
  String get personalRecordsCardEveningTip =>
      '저녁 운동은 기분을 좋게 할 수 있습니다. 오늘 밤 숙면을 원한다면 적당한 강도로 운동하세요.';

  @override
  String get personalRecordsCardGettingPersonalizedTip => '맞춤형 팁을 가져오는 중…';

  @override
  String personalRecordsCardGlasses(Object current, Object goal) {
    return '$current/$goal 잔';
  }

  @override
  String personalRecordsCardMonthsAgo(Object months) {
    return '$months개월 전';
  }

  @override
  String get personalRecordsCardMorningTip =>
      '운동 전 5분간 동적 스트레칭을 하여 수행 능력을 높이고 부상 위험을 줄이세요.';

  @override
  String personalRecordsCardOfUsers(Object count) {
    return '사용자 $count명 중';
  }

  @override
  String get personalRecordsCardPersonalRecords => '개인 최고 기록';

  @override
  String personalRecordsCardQualitySleep(Object duration) {
    return '양질의 수면 $duration';
  }

  @override
  String get personalRecordsCardRank => '순위';

  @override
  String get personalRecordsCardSleep => '수면';

  @override
  String get personalRecordsCardToday => '오늘';

  @override
  String personalRecordsCardTopPercentile(Object percentile) {
    return '상위 $percentile%';
  }

  @override
  String get personalRecordsCardViewAll => '모두 보기';

  @override
  String get personalRecordsCardWater => '수분 섭취';

  @override
  String personalRecordsCardWeeksAgo(Object weeks) {
    return '$weeks주 전';
  }

  @override
  String get personalRecordsCardWeight => '체중';

  @override
  String get personalRecordsCardYesterday => '어제';

  @override
  String get personalRecordsCompleteWorkoutsToStart =>
      '운동을 완료하여 각 운동의 PR 기록을 시작하세요.';

  @override
  String get personalRecordsNoPersonalRecordsYet => '아직 개인 최고 기록이 없습니다';

  @override
  String get personalRecordsNoPrsYetLog => '아직 PR이 없습니다. 운동을 기록하여 첫 PR을 세워보세요!';

  @override
  String get personalRecordsPersonalRecords => '개인 최고 기록';

  @override
  String personalRecordsScreenValue(Object pr) {
    return '+$pr%';
  }

  @override
  String get personalRecordsSearchExercises => '운동 검색...';

  @override
  String get personalRecordsSortBy => '정렬 기준:';

  @override
  String get personalityCardFunFact => '재미있는 사실';

  @override
  String personalityCardValue(Object motivationQuote) {
    return '\"$motivationQuote\"';
  }

  @override
  String get personalityCardYourGymPersonalityIs => '당신의 운동 성향은...';

  @override
  String phaseRecommendationBannerBasedOn(Object evidenceCitation) {
    return '기준: $evidenceCitation';
  }

  @override
  String phaseRecommendationBannerCycleDay(Object cycleDay) {
    return '$cycleDay일차';
  }

  @override
  String phaseRecommendationBannerEvidence(Object evidenceCitation) {
    return '근거: $evidenceCitation';
  }

  @override
  String get phaseRecommendationBannerGotIt => '확인';

  @override
  String get photoEditorAddSticker => '스티커 추가';

  @override
  String get photoEditorCrop => '자르기';

  @override
  String get photoEditorCropPhoto => '사진 자르기';

  @override
  String get photoEditorFailedToCropImage => '사진을 자르는 데 실패했습니다. 다시 시도해주세요.';

  @override
  String get photoEditorFlip => '뒤집기';

  @override
  String get photoEditorHideLogo => '로고 숨기기';

  @override
  String get photoEditorNoStickersUsedYet => '아직 사용한 스티커가 없습니다';

  @override
  String get photoEditorProcessing => '처리 중...';

  @override
  String get photoEditorResetLogo => '로고 초기화';

  @override
  String get photoEditorRotate => '회전';

  @override
  String photoEditorScreenEditPhoto(Object viewTypeName) {
    return '$viewTypeName 사진 편집';
  }

  @override
  String photoEditorScreenFailedToSave(Object e) {
    return '저장 실패: $e';
  }

  @override
  String photoEditorScreenPose(Object viewTypeName) {
    return '$viewTypeName 포즈';
  }

  @override
  String get photoEditorShowLogo => '로고 표시';

  @override
  String get photoEditorSize => '크기';

  @override
  String get photoEditorYourRecentlyUsedStickers => '최근 사용한 스티커가 여기에 표시됩니다';

  @override
  String get photoOverlayTemplateAddYourPhoto => '사진 추가';

  @override
  String get photoOverlayTemplateTime => '시간';

  @override
  String get photoOverlayTemplateVolume => '볼륨';

  @override
  String get photoOverlayTemplateWorkoutComplete => '운동 완료';

  @override
  String get photosAll => '전체';

  @override
  String get photosChooseFromGallery => '갤러리에서 선택';

  @override
  String get photosCompare => '비교';

  @override
  String get photosDeletePhoto => '사진을 삭제할까요?';

  @override
  String get photosLatestByView => '뷰별 최신순';

  @override
  String get photosSelectExistingPhoto => '기존 사진 선택';

  @override
  String get photosSelectViewType => '뷰 유형 선택';

  @override
  String photosTabFailedToOpenEditor(Object e) {
    return '편집기 열기 실패: $e';
  }

  @override
  String photosTabFailedToUploadPhoto(Object e) {
    return '사진 업로드 실패: $e';
  }

  @override
  String photosTabPhotoSaved(Object displayName) {
    return '$displayName 사진이 저장되었습니다!';
  }

  @override
  String photosTabSavedComparisons(Object length) {
    return '저장된 비교 ($length)';
  }

  @override
  String photosTabSelected(Object length) {
    return '$length개 선택됨';
  }

  @override
  String get photosTabUiNoProgressPhotosYet => '아직 진행 상황 사진이 없습니다';

  @override
  String get photosTabUiTakeFirstPhoto => '첫 번째 사진 찍기';

  @override
  String get photosTabUiTakePhotosFromDifferent =>
      '다양한 각도에서 사진을 찍어 시간 경과에 따른 시각적 변화를 추적하세요.';

  @override
  String get photosTakePhoto => '사진 찍기';

  @override
  String get photosThisActionCannotBe => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get photosUploadingPhoto => '사진 업로드 중...';

  @override
  String get photosUseCamera => '카메라 사용';

  @override
  String get photosViewAll => '모두 보기';

  @override
  String get pillarDetail7DayCompletion => '7일 완료율';

  @override
  String get pillarDetailActiveMin => '활동 시간(분)';

  @override
  String get pillarDetailBandShowsThe10th => '밴드는 지난 30일간의 10~90 백분위수를 보여줍니다.';

  @override
  String get pillarDetailCalorieHit => '칼로리 달성';

  @override
  String get pillarDetailCaloriesBurned => '소모 칼로리';

  @override
  String get pillarDetailCompletion => '완료율';

  @override
  String get pillarDetailComponents => '구성 요소';

  @override
  String get pillarDetailCouldNotLoad => '불러올 수 없습니다';

  @override
  String get pillarDetailCustomTrends => '맞춤형 트렌드';

  @override
  String get pillarDetailDarkerCloserToGoal =>
      '색이 진할수록 목표에 가깝습니다. 테두리가 있는 셀은 목표를 달성했습니다.';

  @override
  String get pillarDetailDuration => '운동 시간';

  @override
  String get pillarDetailFiveOrMoreLoggedDays => '5일 이상 기록됨';

  @override
  String get pillarDetailHeatmap30d => 'heatmap-30d';

  @override
  String get pillarDetailHourlyActivityRibbon => '시간별 활동 리본';

  @override
  String get pillarDetailHourlyActivityRibbonBody => '시간별 활동 리본 본문';

  @override
  String get pillarDetailIntensity => '강도';

  @override
  String get pillarDetailLast30Days => '최근 30일';

  @override
  String get pillarDetailLogged => '기록됨';

  @override
  String get pillarDetailMacroStream => '매크로 스트림';

  @override
  String get pillarDetailMacroStreamBody => '매크로 스트림 본문';

  @override
  String get pillarDetailNoHistoryYet => '아직 기록이 없습니다';

  @override
  String get pillarDetailOpenActivity => '활동';

  @override
  String get pillarDetailOpenFullScreen => '전체 화면으로 보기';

  @override
  String get pillarDetailOpenNutrition => '영양';

  @override
  String get pillarDetailOpenSleep => '수면 열기 →';

  @override
  String get pillarDetailOpenWorkouts => '운동';

  @override
  String get pillarDetailPending => '대기 중';

  @override
  String get pillarDetailProteinHit => '단백질 섭취';

  @override
  String pillarDetailScreenEx(Object exerciseCount) {
    return '운동 $exerciseCount개';
  }

  @override
  String pillarDetailScreenKcal(Object cal) {
    return '$cal kcal';
  }

  @override
  String pillarDetailScreenMin(Object activeMin) {
    return '$activeMin분';
  }

  @override
  String pillarDetailScreenNotActiveToday(Object label) {
    return '$label · 오늘 비활성';
  }

  @override
  String pillarDetailScreenStatsTab(Object statsTab) {
    return '/stats?tab=$statsTab';
  }

  @override
  String pillarDetailScreenTodayS(Object label) {
    return '오늘의 $label';
  }

  @override
  String get pillarDetailSetAGoal => '목표 설정';

  @override
  String get pillarDetailSleepStages => '수면 단계';

  @override
  String get pillarDetailSleepStagesBody => '수면 단계 본문';

  @override
  String get pillarDetailSparkline7d => 'sparkline-7d';

  @override
  String get pillarDetailSteps => '걸음 수';

  @override
  String get pillarDetailTodayVsYour30 => '오늘 vs 최근 30일 범위';

  @override
  String get pillarDetailTracking => '트래킹';

  @override
  String get pillarDetailTwoOrMoreLoggedDays => '2일 이상 기록됨';

  @override
  String get pillarDetailVariety => '다양성';

  @override
  String get pillarDetailViewFullStats => '전체 통계 보기';

  @override
  String get pillarDetailVolume => '볼륨';

  @override
  String get pillarDetailWhenYouTrain => '운동 시';

  @override
  String get pillarDetailWhenYouTrainBody => '운동 시 본문';

  @override
  String get pinnedMessageBarN => '\n';

  @override
  String get pinnedMessageBarUnpin => '고정 해제';

  @override
  String get pinnedNutrientsCardFocusThisPhase => '이번 단계 집중 목표:';

  @override
  String get pinnedNutrientsCardPinnedNutrients => '고정된 영양소';

  @override
  String get planAnalyzingBuildingYourPlan => '플랜 구성 중';

  @override
  String get planAnalyzingCalculatingYourGoalDate => '목표 달성일 계산 중';

  @override
  String get planAnalyzingCalibratingYourSchedule => '일정 조정 중';

  @override
  String get planAnalyzingMatchingYourBodyType => '체형 분석 중';

  @override
  String get planAnalyzingPullingFrom1700 => '1,700개 이상의 운동 데이터 불러오는 중';

  @override
  String get planAnalyzingReviewingYourGoals => '목표 검토 중';

  @override
  String get planAnalyzingThisWillTakeA => '잠시만 기다려 주세요…';

  @override
  String get planHeaderAvgCalories => '평균 칼로리';

  @override
  String planHeaderDays(Object trainingDayCount) {
    return '$trainingDayCount일';
  }

  @override
  String planHeaderDays2(Object restDayCount) {
    return '$restDayCount일';
  }

  @override
  String get planHeaderRest => '휴식';

  @override
  String get planHeaderThisWeek => '이번 주';

  @override
  String get planPreviewFreePreview => '무료 미리보기';

  @override
  String get planPreviewRestRecovery => '휴식 및 회복';

  @override
  String get planPreviewScreenAnalyzingYourGoalsFitness =>
      '목표, 체력 수준, 장비를 분석하여 완벽한 프로그램을 생성합니다';

  @override
  String get planPreviewScreenBuildStrengthFoundation => '근력 기초 다지기';

  @override
  String get planPreviewScreenBuildingYour4Week => '4주 플랜 구성 중...';

  @override
  String get planPreviewScreenContinueFree => '무료로 계속하기';

  @override
  String planPreviewScreenDaysPerWeek(Object arg0) {
    return '주 $arg0일';
  }

  @override
  String get planPreviewScreenDesignedBasedOnYour => '설문 답변을 바탕으로 설계됨';

  @override
  String planPreviewScreenEquipmentCount(Object arg0) {
    return '장비 $arg0개';
  }

  @override
  String planPreviewScreenExercisesMin(Object arg0, Object arg1) {
    return '운동 최소 $arg0 $arg1';
  }

  @override
  String get planPreviewScreenIncreaseIntensityVolume => '강도 및 볼륨 증가';

  @override
  String get planPreviewScreenMasterTheMovement => '동작 마스터하기';

  @override
  String get planPreviewScreenPeakPerformanceWeek => '최고 수행 주간';

  @override
  String get planPreviewScreenSetsreps => '세트/횟수';

  @override
  String get planPreviewScreenSubscribeForFullAccess => '구독하고 전체 액세스 권한 받기';

  @override
  String get planPreviewScreenThisIsYourPersonalized => '당신만을 위한 맞춤형 플랜입니다';

  @override
  String get planPreviewScreenTryOneWorkoutFree => '운동 하나 무료로 체험하기';

  @override
  String get planPreviewScreenViewing => '보기';

  @override
  String planPreviewScreenWeekNumber(Object arg0) {
    return '$arg0주차';
  }

  @override
  String get planPreviewScreenWhatYouLlAchieve => '달성하게 될 목표';

  @override
  String get planPreviewYour4WeekPlan => '나의 4주 플랜';

  @override
  String get planTodaySPlan => '오늘의 플랜';

  @override
  String get plateauDashboardCompleteMoreWorkoutsAnd =>
      '더 많은 운동을 완료하고 체중을 기록하여 정체기 분석 인사이트를 확인하세요.';

  @override
  String get plateauDashboardCurrentWeight => '현재 체중';

  @override
  String get plateauDashboardFailedToLoadData => '데이터를 불러오지 못했습니다';

  @override
  String get plateauDashboardGetAiCoachAdvice => 'AI 코치 조언 받기';

  @override
  String get plateauDashboardNoPlateauDataYet => '아직 정체기 데이터가 없습니다';

  @override
  String get plateauDashboardOverallStatus => '전체 상태';

  @override
  String get plateauDashboardPlateauDetection => '정체기 감지';

  @override
  String plateauDashboardScreenKg(Object currentWeight) {
    return '$currentWeight kg';
  }

  @override
  String plateauDashboardScreenWeeksStalled(Object weeksStalled) {
    return '$weeksStalled주째 정체 중';
  }

  @override
  String get plateauDashboardSuggestedAction => '제안된 조치';

  @override
  String get plateauDashboardWeightProgress => '체중 변화';

  @override
  String get portionAmountInput1x => '1x';

  @override
  String get portionAmountInputAdjustPortion => '분량 조절';

  @override
  String get portionAmountInputCal => '칼로리';

  @override
  String get portionAmountInputCustomAmount => '직접 입력';

  @override
  String get portionAmountInputDouble => '2배';

  @override
  String get portionAmountInputHalf => '0.5배';

  @override
  String get portionAmountInputOneAndAHalf => '1.5배';

  @override
  String get portionAmountInputOneAndAQuarter => '1.25배';

  @override
  String get portionAmountInputStandard => '표준';

  @override
  String get portionAmountInputThreeQuarters => '0.75배';

  @override
  String get postMealReviewCheckInDisabledRe =>
      '체크인이 비활성화되었습니다. 영양 → 패턴에서 다시 활성화하세요.';

  @override
  String get postMealReviewCheckInSaved => '체크인이 저장되었습니다!';

  @override
  String get postMealReviewDonTShowAgain => '다시 보지 않기';

  @override
  String get postMealReviewEnergyLevel => '에너지 수준';

  @override
  String get postMealReviewHide => '숨기기';

  @override
  String get postMealReviewHowDidYouFeel => '식사 전 기분은 어떠셨나요?';

  @override
  String get postMealReviewHowDoYouFeel => '식사 후 기분은 어떠신가요?';

  @override
  String get postMealReviewMealLogged => '식사 기록 완료!';

  @override
  String get postMealReviewQuickCheckInOptional => '간편 체크인 (선택 사항)';

  @override
  String get postMealReviewSaveCheckIn => '체크인 저장';

  @override
  String postMealReviewSheetKcal(
    Object extraCount,
    Object foodSummary,
    Object totalCalories,
  ) {
    return '$foodSummary$extraCount · $totalCalories kcal';
  }

  @override
  String get postMealReviewWhyTrackThis => '왜 기록하나요?';

  @override
  String get postWorkoutHr60sRec => '60초 회복';

  @override
  String get postWorkoutHrAvg => '평균';

  @override
  String postWorkoutHrGraphAvg(Object avg) {
    return '평균 $avg';
  }

  @override
  String postWorkoutHrGraphValue(Object recovery) {
    return '−$recovery';
  }

  @override
  String get postWorkoutHrHeartRate => '심박수';

  @override
  String get postWorkoutHrMin => '최소';

  @override
  String get postWorkoutHrNoHeartRateData =>
      '심박수 데이터가 없습니다. 스트랩(예: Amazfit Helios)을 착용하고 건강 권한을 허용하면 실시간 심박수와 운동 후 그래프를 볼 수 있습니다.';

  @override
  String get postWorkoutHrPeak => '최고';

  @override
  String get postWorkoutNutritionCarbs => '탄수화물';

  @override
  String get postWorkoutNutritionFasted => '공복';

  @override
  String get postWorkoutNutritionFat => '지방';

  @override
  String get postWorkoutNutritionLog => '기록';

  @override
  String get postWorkoutNutritionLogPostWorkoutMeal => '운동 후 식사 기록';

  @override
  String get postWorkoutNutritionProtein => '단백질';

  @override
  String get postWorkoutNutritionQuickOptions => '빠른 선택:';

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
  String get postureFindingsCardAddCorrectiveExercises => '교정 운동 추가';

  @override
  String get postureFindingsCardPostureFindings => '자세 분석 결과';

  @override
  String get postureFindingsCardQueuing => '대기 중…';

  @override
  String get prCardShareE1rm => '📈 e1RM · ';

  @override
  String get prCardShareNewPr => '새로운 PR';

  @override
  String get prCardShareNewPr2 => '🏆 새로운 PR · ';

  @override
  String get prCardSharePreparing => '준비 중…';

  @override
  String get prCardShareSharePr => 'PR 공유';

  @override
  String get prCardShareZealovaAiFitnessCoach => 'Zealova · AI 피트니스 코치';

  @override
  String get prCardShareZealovaCom => 'zealova.com';

  @override
  String get prDetailsFirstRecord => '첫 기록';

  @override
  String get prDetailsNewRecord => '새로운 기록';

  @override
  String get prDetailsPrevious => '이전';

  @override
  String prDetailsSheetKgXReps(Object reps, Object weight) {
    return '${weight}kg x $reps회';
  }

  @override
  String prDetailsSheetOnFirePrs(Object length) {
    return '불타오르네요! $length개의 PR 달성!';
  }

  @override
  String prDetailsSheetValue(Object improvementPercent) {
    return '+$improvementPercent%';
  }

  @override
  String get prDetailsViewAllAchievements => '모든 성과 보기';

  @override
  String get prFullCelebration6MonthBest1rm => '최근 6개월 최고 1RM';

  @override
  String get prFullCelebrationContinueWorkout => '운동 계속하기';

  @override
  String get prFullCelebrationNewPersonalRecord => '새로운 개인 최고 기록!';

  @override
  String prFullCelebrationPersonalRecords(Object length) {
    return '$length개의 개인 최고 기록!';
  }

  @override
  String prFullCelebrationReps(Object reps) {
    return '$reps회';
  }

  @override
  String get prFullCelebrationShareYourAchievement => '성과 공유하기';

  @override
  String prFullCelebrationValue(Object improvementPercent) {
    return '(+$improvementPercent%)';
  }

  @override
  String get prFullCelebrationYouReOnFire => '정말 대단해요!';

  @override
  String get prInlineCelebrationOnFire => '불타오르네요! 🔥';

  @override
  String prInlineCelebrationPersonalRecords(Object length) {
    return '$length개의 개인 최고 기록!';
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
  String get prShareCardCopiedToClipboard => '클립보드에 복사되었습니다!';

  @override
  String get prShareCardCopyText => '텍스트 복사';

  @override
  String get prShareCardFailedToCaptureImage => '이미지 캡처 실패';

  @override
  String get prShareCardFailedToShare => '공유 실패';

  @override
  String get prShareCardNewPersonalRecord => '새로운 개인 최고 기록!';

  @override
  String prShareCardReps(Object reps) {
    return '$reps회';
  }

  @override
  String get prShareCardShareImage => '이미지 공유';

  @override
  String get prShareCardShareYourPr => 'PR 공유하기';

  @override
  String prShareCardWorkout(Object workoutName) {
    return '운동: $workoutName';
  }

  @override
  String get prSummaryCardLogYourWorkoutsAnd =>
      '운동을 기록하면 최고의 기록을 자동으로 추적해 드립니다!';

  @override
  String get prSummaryCardNoPersonalRecordsYet => '아직 개인 최고 기록이 없습니다';

  @override
  String get prSummaryCardPersonalRecords => '개인 최고 기록';

  @override
  String get prSummaryCardRecentPrs => '최근 PR';

  @override
  String prSummaryCardValue(Object pr) {
    return '+$pr%';
  }

  @override
  String get practiceAttemptHoldTimeSeconds => '유지 시간 (초)';

  @override
  String get practiceAttemptHowDidItFeel => '어떠셨나요? 특이사항이 있나요?';

  @override
  String get practiceAttemptLogAttempt => '시도 기록';

  @override
  String get practiceAttemptLogPractice => '연습 기록';

  @override
  String get practiceAttemptNotesOptional => '메모 (선택 사항)';

  @override
  String get practiceAttemptPleaseEnterRepsOr => '횟수 또는 유지 시간을 입력해 주세요';

  @override
  String get practiceAttemptQuickSelectReps => '빠른 횟수 선택';

  @override
  String get practiceAttemptReps => '횟수';

  @override
  String get practiceAttemptSets => '세트';

  @override
  String practiceAttemptSheetGoal(Object unlockCriteriaText) {
    return '목표: $unlockCriteriaText';
  }

  @override
  String get preAuthQuizConsistencyBeatsIntensity => '강도보다 꾸준함이 중요합니다';

  @override
  String get preAuthQuizControlsHowQuicklyWeights =>
      '매주 중량, 횟수, 난이도가 증가하는 속도를 조절합니다.';

  @override
  String get preAuthQuizEveryExerciseWillBe =>
      '보유하신 장비에 맞춰 모든 운동이 선택됩니다. 별도의 대체 운동은 필요 없습니다.';

  @override
  String get preAuthQuizFailedToSaveOnboarding =>
      '온보딩 데이터를 저장하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get preAuthQuizFineTuningYourPlan => '플랜 미세 조정 중';

  @override
  String get preAuthQuizFitnessLevelHelpsSet =>
      '피트니스 레벨은 적절한 시작점(적정 중량, 반복 횟수 범위, 운동 복잡도)을 설정하는 데 도움을 줍니다.';

  @override
  String get preAuthQuizFuelYourTraining => '운동을 위한 영양 섭취';

  @override
  String get preAuthQuizGenerateMyFirstWorkout => '첫 운동 생성하기';

  @override
  String get preAuthQuizGotIt => '확인했습니다';

  @override
  String get preAuthQuizMatchedToYourSetup => '장비 맞춤 설정';

  @override
  String get preAuthQuizNutritionTrackingIsOptional =>
      '영양 기록은 선택 사항이지만 매우 유용합니다. AI가 목표와 활동량에 맞춰 매크로를 계산합니다.';

  @override
  String get preAuthQuizSafetyFirst => '안전 제일';

  @override
  String get preAuthQuizSkipAndFinish => '건너뛰고 완료';

  @override
  String get preAuthQuizSkipLetAiDecide => '건너뛰기, AI가 결정하도록 하기';

  @override
  String get preAuthQuizSomethingWentWrongPlease => '문제가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get preAuthQuizTellingUsAboutInjuries =>
      '부상 부위를 알려주시면 통증이나 부상을 유발할 수 있는 운동을 피할 수 있습니다.';

  @override
  String get preAuthQuizTheseOptionalDetailsMake =>
      '이 선택 사항들은 운동을 더욱 개인화해 줍니다. 원치 않으시면 AI 기본값으로 진행하세요.';

  @override
  String get preAuthQuizWeLlBuildThe =>
      '일정에 최적화된 트레이닝 스플릿을 구성해 드립니다. 무조건 많이 하는 것보다 회복이 중요합니다.';

  @override
  String get preAuthQuizWeUseYourGoals =>
      '목표를 바탕으로 트레이닝 스플릿, 운동 선택, 진행 속도를 결정합니다.';

  @override
  String get preAuthQuizWhichDaysWorkBest => '운동하기 가장 좋은 요일은 언제인가요?';

  @override
  String get preAuthQuizYourGoalsShapeEverything => '목표가 모든 것을 결정합니다';

  @override
  String get preAuthQuizYourProgressionSpeed => '진행 속도';

  @override
  String get preAuthReferralAbc123 => 'ABC123';

  @override
  String preAuthReferralChipCodeWillApplyAfter(Object _pendingCode) {
    return '가입 후 $_pendingCode 코드가 적용됩니다';
  }

  @override
  String get preAuthReferralEnterReferralCode => '추천 코드 입력';

  @override
  String get preAuthReferralRemove => '제거';

  @override
  String get preAuthReferralSaveCode => '코드 저장';

  @override
  String get preAuthReferralThatCodeDoesnT => '올바르지 않은 코드입니다. 다시 시도해 주세요.';

  @override
  String preSetCoachingBannerCoachingInsight(Object message) {
    return '코칭 인사이트. $message.';
  }

  @override
  String get preSetCoachingDismiss => '닫기';

  @override
  String get preSetCoachingDismissCoachingInsight => '코칭 인사이트 닫기';

  @override
  String preSetInsightBannerValue(Object label) {
    return '$label · ';
  }

  @override
  String get preSetInsightDismissInsight => '인사이트 닫기';

  @override
  String get preWorkoutCheckinAddMoreDetails => '상세 정보 추가';

  @override
  String get preWorkoutCheckinEnergyLevel => '에너지 레벨';

  @override
  String get preWorkoutCheckinHowAreYouFeeling => '오늘 컨디션은 어떠신가요?';

  @override
  String get preWorkoutCheckinHowWasYourSleep => '수면은 어떠셨나요?';

  @override
  String get preWorkoutCheckinQuickCheckBeforeYour => '운동 전 간단한 체크';

  @override
  String get preWorkoutCheckinSkipCheckIn => '체크인 건너뛰기';

  @override
  String get preWorkoutCheckinStartWorkout => '운동 시작';

  @override
  String get preferencesAccentColor => '강조 색상';

  @override
  String get preferencesAutoDetectedOverrideIf => '자동 감지됨, 여행 중인 경우 재설정';

  @override
  String get preferencesChooseYourAppAccent => '앱 강조 색상 선택';

  @override
  String get preferencesGymProfiles => '헬스장 프로필';

  @override
  String get preferencesKilogramsOrPounds => '킬로그램 또는 파운드';

  @override
  String get preferencesManageGymsEquipmentAnd => '헬스장, 장비 및 위치 관리';

  @override
  String get preferencesPreferences => '환경 설정';

  @override
  String get preferencesShowDailyGoals => '일일 목표 표시';

  @override
  String get preferencesSystemLightOrDark => '시스템, 라이트 또는 다크 모드';

  @override
  String get preferencesTimezone => '시간대';

  @override
  String get preferencesTrainingFocus => '훈련 집중 부위';

  @override
  String get preferencesWeightUnit => '무게 단위';

  @override
  String get preferencesXpProgressStripOn => '홈 화면에 XP 진행률 표시';

  @override
  String get premiumGatePremiumFeature => '프리미엄 기능';

  @override
  String get premiumGateUnlock => '잠금 해제';

  @override
  String get pressAndHoldPressAndHoldTo => '길게 눌러 확인';

  @override
  String get previewTileMock45Min6Exercises => '45분 - 6개 운동';

  @override
  String get previewTileMock8234Steps => '8,234 걸음';

  @override
  String get previewTileMockFitnessScore => '피트니스 점수';

  @override
  String get previewTileMockGoodProgressKeepIt => '좋은 진행 상황입니다. 계속 유지하세요!';

  @override
  String get previousWorkoutsCompleteYourFirstWorkout =>
      '첫 운동을 완료하고 여기에 확인해보세요';

  @override
  String get previousWorkoutsNoCompletedWorkoutsYet => '아직 완료된 운동이 없습니다';

  @override
  String get previousWorkoutsPreviousWorkouts => '이전 운동 기록';

  @override
  String get privacyDataPrivacyData => '개인정보 및 데이터';

  @override
  String get profileAddEquipmentThatWill => '운동 생성 시 사용할 장비를 추가하세요.';

  @override
  String get profileAiPrivacy => 'AI 개인정보 보호';

  @override
  String get profileCustomTrends => '맞춤형 트렌드';

  @override
  String get profileDeleteAccount => '계정 삭제';

  @override
  String get profileFitness => '피트니스';

  @override
  String get profileFromAppleHealth => 'Apple Health에서 가져오기';

  @override
  String get profileFromHealthConnect => 'Health Connect에서 가져오기';

  @override
  String get profileGlossary => '용어집';

  @override
  String profileHeaderValue(Object username) {
    return '@$username';
  }

  @override
  String get profileManageMembership => '멤버십 관리';

  @override
  String get profileMyCustomEquipment => '내 맞춤 장비';

  @override
  String get profilePrivacyData => '개인정보 및 데이터';

  @override
  String get profileScreenPartAdd => '추가';

  @override
  String get profileScreenPartAddEquipmentAboveTo => '시작하려면 위에서 장비를 추가하세요';

  @override
  String get profileScreenPartEnterEquipmentName => '장비 이름 입력...';

  @override
  String get profileScreenPartNoCustomEquipmentYet => '아직 추가된 맞춤 장비가 없습니다';

  @override
  String get profileScreenPartNoSyncedWorkoutsYet => '아직 동기화된 운동 기록이 없습니다';

  @override
  String get profileScreenPartPrimaryGoalMusclePrioriti => '주요 목표 및 근육 우선순위';

  @override
  String get profileScreenPartSeeAll => '모두 보기';

  @override
  String get profileScreenPartTrainingFocus => '훈련 집중 부위';

  @override
  String get profileSessionDetails => '세션 세부정보';

  @override
  String get profileWorkoutHistoryImport => '운동 기록 가져오기';

  @override
  String get programBuilderPartAddYourWarmUp => '각 세션에 웜업 및 스트레칭 루틴을 추가하세요.';

  @override
  String get programBuilderPartApplyMyStapleExercises => '기본 운동 루틴 적용';

  @override
  String programBuilderPartExercisePickerAddTo(Object dayName) {
    return '$dayName에 추가';
  }

  @override
  String get programBuilderPartNoScheduledDeload => '예정된 디로딩 없음';

  @override
  String get programBuilderPartOff => '끄기';

  @override
  String get programBuilderPartProgramSettings => '프로그램 설정';

  @override
  String get programBuilderPartSearchExercises => '운동 검색...';

  @override
  String programBuilderPartTemplateMetaEveryWeeks(Object current) {
    return '$current주마다';
  }

  @override
  String get programCarouselSeeAll => '모두 보기';

  @override
  String get programDetailCategory => '카테고리';

  @override
  String get programDetailDescription => '설명';

  @override
  String get programDetailDuration => '기간';

  @override
  String get programDetailLevel => '레벨';

  @override
  String get programDetailProgram => '프로그램';

  @override
  String get programDetailSessions => '세션';

  @override
  String programDetailSheetInspiredBy(Object celebrityName) {
    return '$celebrityName 영감';
  }

  @override
  String programDetailSheetStartWeekProgram(Object _selectedWeeks) {
    return '$_selectedWeeks주 프로그램 시작';
  }

  @override
  String programDetailSheetValue(Object tag) {
    return '#$tag';
  }

  @override
  String programDetailSheetWeek(Object _selectedSessionsPerWeek) {
    return '주 $_selectedSessionsPerWeek회';
  }

  @override
  String programDetailSheetWeeks(Object _selectedWeeks) {
    return '$_selectedWeeks주';
  }

  @override
  String get programDurationSelectorHowFarAheadTo => '운동 예약 기간 설정';

  @override
  String get programDurationSelectorProgramDuration => '프로그램 기간';

  @override
  String get programHistoryCurrent => '현재';

  @override
  String get programHistoryFailedToLoadProgram => '프로그램 기록을 불러오지 못했습니다';

  @override
  String get programHistoryNoProgramHistoryYet => '아직 프로그램 기록이 없습니다';

  @override
  String get programHistoryProgramHistory => '프로그램 기록';

  @override
  String get programHistoryProgramRestoredSuccessfully =>
      '프로그램이 성공적으로 복원되었습니다!';

  @override
  String get programHistoryRestoreProgram => '프로그램을 복원하시겠습니까?';

  @override
  String get programHistoryRestoreProgram2 => '프로그램 복원';

  @override
  String programHistoryScreenDaysWeek(Object length) {
    return '주 $length일';
  }

  @override
  String programHistoryScreenFailedToRestoreProgram(Object e) {
    return '프로그램 복원 실패: $e';
  }

  @override
  String programHistoryScreenMin(Object durationMinutes) {
    return '$durationMinutes분';
  }

  @override
  String programHistoryScreenThisWillRestoreAs(Object displayName) {
    return '\"$displayName\"을(를) 현재 프로그램으로 복원합니다. ';
  }

  @override
  String programHistoryScreenWorkoutsCompleted(Object totalWorkoutsCompleted) {
    return '총 $totalWorkoutsCompleted회 운동 완료';
  }

  @override
  String get programHistoryUnknownError => '알 수 없는 오류';

  @override
  String get programHistoryWhenYouCustomizeYour =>
      '프로그램을 커스터마이징하면 스냅샷이 여기에 저장됩니다.';

  @override
  String get programLibrary => '•  ';

  @override
  String get programLibraryAll => '모두';

  @override
  String get programLibraryAny => '전체';

  @override
  String programLibraryCardWk(Object durationWeeks) {
    return '$durationWeeks주';
  }

  @override
  String programLibraryCardWk2(Object sessionsPerWeek) {
    return '주 $sessionsPerWeek회';
  }

  @override
  String get programLibraryClearFilters => '필터 초기화';

  @override
  String get programLibraryCouldNotImportThis =>
      '이 프로그램을 가져올 수 없습니다. 다시 시도해주세요.';

  @override
  String get programLibraryImportCustomize => '가져오기 및 커스터마이징';

  @override
  String get programLibraryImporting => '가져오는 중...';

  @override
  String get programLibraryLevel => '레벨';

  @override
  String get programLibraryNoProgramsMatchThese => '이 필터와 일치하는 프로그램이 없습니다.';

  @override
  String get programLibraryProgramLibrary => '프로그램 라이브러리';

  @override
  String programLibraryScreenRest(Object dayName) {
    return '$dayName · 휴식';
  }

  @override
  String programLibraryScreenValue(Object ex, Object sets) {
    return '$sets × $ex';
  }

  @override
  String programLibraryScreenWith(Object card) {
    return '$card와 함께';
  }

  @override
  String get programLibrarySearchPrograms => '프로그램 검색';

  @override
  String get programMenuButtonBrowsePrograms => '프로그램 둘러보기';

  @override
  String get programMenuButtonChangeDaysEquipmentDiffic => '요일, 장비, 난이도 등 변경';

  @override
  String get programMenuButtonCustomizeProgram => '프로그램 맞춤 설정';

  @override
  String get programMenuButtonCustomizeYourWorkoutProgram =>
      '운동 프로그램을 맞춤 설정하거나 현재 설정으로 다시 생성하세요.';

  @override
  String get programMenuButtonFailedToClearWorkouts => '운동 기록을 삭제하지 못했습니다';

  @override
  String programMenuButtonGeneratedFreshWorkouts(Object generatedCount) {
    return '새로운 운동 $generatedCount개가 생성되었습니다!';
  }

  @override
  String get programMenuButtonGetFreshWorkoutsWith => '현재 설정으로 새로운 운동 생성';

  @override
  String get programMenuButtonMySpace => '마이 스페이스';

  @override
  String get programMenuButtonPleaseLogInTo => '운동을 다시 생성하려면 로그인하세요';

  @override
  String get programMenuButtonProgramOptions => '프로그램 옵션';

  @override
  String get programMenuButtonProgramUpdatedYourNew =>
      '프로그램이 업데이트되었습니다! 새로운 운동이 준비되었습니다.';

  @override
  String get programMenuButtonRegenerateThisWeek => '이번 주 운동 다시 생성';

  @override
  String get programMenuButtonRegenerateWorkouts => '운동을 다시 생성할까요?';

  @override
  String get programMenuButtonSeeYourWorkoutDays => '운동 요일, 숙련도 및 목표 확인';

  @override
  String get programMenuButtonThisWillDeleteYour =>
      '진행 중인 예정된 운동이 삭제되고 현재 프로그램 설정을 사용하여 새로운 운동이 생성됩니다.\n\n완료된 운동은 영향을 받지 않습니다.';

  @override
  String get programMenuButtonTryCelebrityWorkoutsSport =>
      '유명인 운동, 스포츠 트레이닝 등 시도';

  @override
  String get programMenuButtonViewMyPreferences => '내 환경설정 보기';

  @override
  String get programMetaApplyStaples => '기본 운동 적용';

  @override
  String get programMetaApplyStaplesSubtitle => '기본 운동 적용 부제목';

  @override
  String get programMetaDeloadEvery => '디로딩 주기';

  @override
  String get programMetaFixedLoadsNote => '고정 중량 참고';

  @override
  String get programMetaProgramSettings => '프로그램 설정';

  @override
  String get programMetaProgression => '점진적 과부하';

  @override
  String get programSummaryAdaptsWorkoutsBasedOn => '진행 상황에 맞춰 운동 조정';

  @override
  String get programSummaryAdvancedLabel => '고급';

  @override
  String get programSummaryAutomaticallyIncreasesChalle =>
      '시간이 지남에 따라 자동으로 난이도 증가';

  @override
  String get programSummaryAvoidsExercisesThatStress => '신체적 제한에 무리가 가는 운동 제외';

  @override
  String get programSummaryBeginnerLabel => '초급';

  @override
  String get programSummaryBodyweight => '맨몸 운동';

  @override
  String get programSummaryBuildMuscle => '근육 증량';

  @override
  String get programSummaryEndurance => '지구력';

  @override
  String get programSummaryEquipment => '장비';

  @override
  String get programSummaryFullGym => '전체 헬스장 기구';

  @override
  String get programSummaryGeneralFitness => '일반 피트니스';

  @override
  String get programSummaryGenerateNewProgram => '새 프로그램 생성';

  @override
  String get programSummaryGetStronger => '근력 강화';

  @override
  String get programSummaryInjuryAwareness => '부상 방지';

  @override
  String get programSummaryIntermediateLabel => '중급';

  @override
  String get programSummaryLevel => '레벨';

  @override
  String get programSummaryLoseWeight => '체중 감량';

  @override
  String get programSummaryMacrosAndMealsAligned => '트레이닝에 맞춘 매크로 및 식단';

  @override
  String programSummaryNItems(Object arg0) {
    return '$arg0개 항목';
  }

  @override
  String get programSummaryNutritionIntegration => '영양 통합';

  @override
  String get programSummaryPersonalizedForYourGoals => '목표와 장비에 맞춘 개인화';

  @override
  String get programSummaryProgressiveOverload => '점진적 과부하';

  @override
  String get programSummaryStartTraining => '트레이닝 시작';

  @override
  String get programSummaryStayFit => '건강 유지';

  @override
  String get programSummaryStrengthSize => '근력 및 크기';

  @override
  String get programSummaryWhatSIncluded => '포함된 내용';

  @override
  String get programSummaryYourProgramIsReady => '프로그램이 준비되었습니다';

  @override
  String get programTemplateBuilderAProgramNeedsAt =>
      '프로그램에는 최소 하루 이상의 트레이닝 일정이 필요합니다.';

  @override
  String get programTemplateBuilderAddExercise => '운동 추가';

  @override
  String get programTemplateBuilderBuildFromScratch => '처음부터 만들기';

  @override
  String get programTemplateBuilderCopyDayToAnother => '다른 요일로 복사';

  @override
  String get programTemplateBuilderCouldNotSaveThe =>
      '템플릿을 저장할 수 없습니다. 다시 시도해주세요.';

  @override
  String get programTemplateBuilderDropInASplit => '작성해둔 분할 루틴을 입력하면 분석해 드립니다.';

  @override
  String get programTemplateBuilderEditProgram => '프로그램 편집';

  @override
  String get programTemplateBuilderEmpty => '비어 있음';

  @override
  String get programTemplateBuilderGiveYourProgramA => '프로그램 이름을 입력하세요.';

  @override
  String get programTemplateBuilderImportFromLibrary => '라이브러리에서 가져오기';

  @override
  String get programTemplateBuilderLayOutEachTraining =>
      '각 트레이닝 일정을 운동별로 구성하세요.';

  @override
  String get programTemplateBuilderMakeRestDay => '휴식일로 설정';

  @override
  String get programTemplateBuilderMakeTrainingDay => '트레이닝일로 설정';

  @override
  String get programTemplateBuilderMyTemplates => '내 템플릿';

  @override
  String get programTemplateBuilderNewProgram => '새 프로그램';

  @override
  String get programTemplateBuilderParseProgram => '프로그램 분석';

  @override
  String get programTemplateBuilderParsing => '분석 중...';

  @override
  String get programTemplateBuilderPasteMyProgram => '내 프로그램 붙여넣기';

  @override
  String get programTemplateBuilderSaveTemplate => '템플릿 저장';

  @override
  String get programTemplateBuilderSaving => '저장 중...';

  @override
  String programTemplateBuilderScreenCopyInto(Object sourceName) {
    return '\"$sourceName\" 복사 대상...';
  }

  @override
  String programTemplateBuilderScreenDay(Object d, Object label) {
    return '$d일차 · $label';
  }

  @override
  String programTemplateBuilderScreenSaved(Object name) {
    return '\"$name\" 저장됨';
  }

  @override
  String programTemplateBuilderScreenTo(Object destLabel) {
    return '~ $destLabel';
  }

  @override
  String programTemplateBuilderScreenValue(Object exercise, Object sets) {
    return '$sets × $exercise';
  }

  @override
  String programTemplateBuilderScreenWeeksWhenScheduled(
    Object repeatWeeksHint,
  ) {
    return '예정 시 $repeatWeeksHint주.';
  }

  @override
  String get programTemplateBuilderStartFromAStructured =>
      '구조화된 프로그램으로 시작하여 나만의 루틴을 만드세요.';

  @override
  String get programsAll => '전체';

  @override
  String get programsClearFilters => '필터 초기화';

  @override
  String get programsIntro185Programs => '185개 이상의 프로그램';

  @override
  String get programsIntro37WorkoutDays => '주 3~7일 운동';

  @override
  String get programsIntroAllLevels => '모든 레벨';

  @override
  String get programsIntroBeginnerToAdvanced => '초급부터 상급까지';

  @override
  String get programsIntroBrowsePrograms => '프로그램 둘러보기';

  @override
  String get programsIntroCategories => '카테고리';

  @override
  String get programsIntroCustomFrequency => '맞춤형 빈도';

  @override
  String get programsIntroFlexibleDuration => '유연한 기간';

  @override
  String get programsIntroProfessionalExerciseTutorial => '전문적인 운동 튜토리얼';

  @override
  String get programsIntroProgramsFrom1To => '1~16주 프로그램';

  @override
  String get programsIntroStrengthCardioMobilityM => '근력, 유산소, 가동성 등';

  @override
  String get programsIntroVideoDemos => '영상 데모';

  @override
  String get programsIntroWhatYouCanExpect => '기대할 수 있는 것';

  @override
  String get programsIntroWorkoutPrograms => '운동 프로그램';

  @override
  String get programsNoProgramsFound => '프로그램을 찾을 수 없습니다';

  @override
  String get programsSearch => '검색';

  @override
  String get programsSearchPrograms => '프로그램 검색...';

  @override
  String get programsTapAnyProgramTo => '프로그램을 탭하여 자세히 알아보세요';

  @override
  String get programsTryAgain => '다시 시도';

  @override
  String get progressAll => '전체';

  @override
  String get progressChartsCompleteSomeWorkoutsTo =>
      '운동을 완료하여 시간 경과에 따른 볼륨 변화를 확인하세요.';

  @override
  String get progressChartsCompleteWeightedExercisesTo =>
      '중량 운동을 완료하여 근력 향상을 확인하세요.';

  @override
  String get progressChartsFailedToLoadData => '데이터를 불러오지 못했습니다';

  @override
  String get progressChartsMuscleGroupBreakdown => '근육 부위별 분석';

  @override
  String get progressChartsNoStrengthDataYet => '아직 근력 데이터가 없습니다';

  @override
  String get progressChartsNoVolumeDataYet => '아직 볼륨 데이터가 없습니다';

  @override
  String get progressChartsPeriodSummary => '기간 요약';

  @override
  String progressChartsScreenKg(Object value) {
    return '$value kg';
  }

  @override
  String get progressChartsStrengthSummary => '근력 요약';

  @override
  String get progressChartsStrengthTrends => '근력 추이';

  @override
  String get progressChartsTopMuscle => '주요 근육: ';

  @override
  String get progressChartsTrends => '추이';

  @override
  String get progressChartsVolumeTrend => '볼륨 추이';

  @override
  String get progressChartsVolumeTrends => '볼륨 추이';

  @override
  String get progressChooseFromGallery => '갤러리에서 선택';

  @override
  String get progressDeletePhoto => '사진을 삭제할까요?';

  @override
  String get progressFailedToProcessPhoto => '사진 처리 중 오류가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get progressFitness => '피트니스';

  @override
  String get progressGreat => '훌륭해요!';

  @override
  String get progressMeasurements => '신체 측정';

  @override
  String get progressOk => 'OK';

  @override
  String get progressPhotoSaved => '사진이 저장되었습니다!';

  @override
  String get progressPhotoTileProgressPhotos => '변화 사진';

  @override
  String get progressPhotoTileTakeYourFirstPhoto => '첫 사진 찍기';

  @override
  String get progressPhotos => '사진';

  @override
  String get progressProgressTracking => '진행 상황 추적';

  @override
  String get progressPrs30d => 'PR (30일)';

  @override
  String get progressScores => '점수';

  @override
  String get progressScreenExtCompleteWorkoutsTargetingTh =>
      '근력 변화를 확인하려면 해당 근육을 타겟으로 하는 운동을 완료하세요.';

  @override
  String get progressScreenExtDetails => '상세 정보';

  @override
  String get progressScreenExtNoDataForThis => '아직 해당 근육 그룹에 대한 데이터가 없습니다';

  @override
  String get progressScreenExtProgressToNextLevel => '다음 레벨로 진행';

  @override
  String progressScreenExtSetsWk(Object weeklySets) {
    return '주당 $weeklySets 세트';
  }

  @override
  String get progressScreenPartView => '보기';

  @override
  String get progressScreenUiAddPhoto => '사진 추가';

  @override
  String get progressScreenUiAi100RatingBody => 'AI /100 등급, 체지방 분석 및 자세 피드백';

  @override
  String get progressScreenUiBodyAnalyzer => '신체 분석기';

  @override
  String get progressScreenUiBodyMeasurements => '신체 측정';

  @override
  String get progressScreenUiDetailedAnalytics => '상세 분석';

  @override
  String get progressScreenUiExerciseHistory => '운동 기록';

  @override
  String get progressScreenUiExerciseProgressions => '운동 단계별 발전';

  @override
  String get progressScreenUiFailedToLoadMeasurements => '측정 데이터를 불러오지 못했습니다';

  @override
  String get progressScreenUiLatestByView => '보기별 최신 정보';

  @override
  String get progressScreenUiLogMeasurement => '측정값 기록';

  @override
  String get progressScreenUiLogMeasurements => '측정값 기록';

  @override
  String get progressScreenUiMasterEasierVariantsThen =>
      '쉬운 변형 동작을 마스터한 후 더 어려운 동작으로 넘어가세요';

  @override
  String get progressScreenUiMuscleAnalytics => '근육 분석';

  @override
  String get progressScreenUiNoProgressPhotosYet => '아직 변화 사진이 없습니다';

  @override
  String get progressScreenUiPerExerciseProgressPrs => '운동별 진행 상황 및 PR';

  @override
  String get progressScreenUiPhotoProgress => '사진 변화 기록';

  @override
  String get progressScreenUiPleaseTryAgain => '다시 시도해 주세요.';

  @override
  String get progressScreenUiTakeFirstPhoto => '첫 사진 찍기';

  @override
  String get progressScreenUiTakePhotosFromDifferent =>
      '다양한 각도에서 사진을 찍어 시간 경과에 따른 시각적 변화를 추적하세요.';

  @override
  String get progressScreenUiTrackYourBodyMeasurements =>
      '신체 치수를 기록하여 체중계 수치 이상의 상세한 변화를 확인하세요.';

  @override
  String get progressScreenUiTrainingVolumeBalance => '운동 볼륨 및 균형';

  @override
  String progressScreenWeight(Object formattedWeight) {
    return '체중: $formattedWeight';
  }

  @override
  String progressScreenYourProgressPhotoHas(Object displayName) {
    return '$displayName 진행 상황 사진이 성공적으로 저장되었습니다.';
  }

  @override
  String get progressSelectExistingPhoto => '기존 사진 선택';

  @override
  String get progressSelectViewType => '보기 유형 선택';

  @override
  String progressShareGalleryScreenViralFormats(Object length) {
    return '$length개의 바이럴 형식';
  }

  @override
  String get progressShareGalleryShareYourTransformation => '나의 변화 공유하기';

  @override
  String get progressShareGalleryTapToOpen => '탭하여 열기';

  @override
  String get progressShareTemplatesANtransformationNstudy => '변화\n연구';

  @override
  String get progressShareTemplatesBreaking => '속보';

  @override
  String get progressShareTemplatesConsistency => '꾸준함';

  @override
  String progressShareTemplatesFromAgo(Object durationText) {
    return '$durationText 전';
  }

  @override
  String get progressShareTemplatesFromILlStart => '\"월요일부터 시작할게\"에서';

  @override
  String progressShareTemplatesHowSheLost(Object weightLostText) {
    return '$weightLostText 감량 비결';
  }

  @override
  String get progressShareTemplatesInGreenBoxes => '성공의 기록';

  @override
  String get progressShareTemplatesInTheBooks => '기록 완료';

  @override
  String progressShareTemplatesLocalLegendShedsIn(
    Object durationText,
    Object weightLostText,
  ) {
    return '로컬 레전드: $durationText 만에 $weightLostText 감량';
  }

  @override
  String progressShareTemplatesLocalLegendTransformsIn(Object durationText) {
    return '로컬 레전드: $durationText 만에 변화';
  }

  @override
  String get progressShareTemplatesMyTransformation => '나의 변화';

  @override
  String progressShareTemplatesNworkouts(Object totalWorkouts) {
    return '+$totalWorkouts\n운동';
  }

  @override
  String get progressShareTemplatesOfConsistency => '꾸준함의 결과';

  @override
  String get progressShareTemplatesOfDiscipline => '절제의 결과.';

  @override
  String get progressShareTemplatesOfPureWork => '노력의 결실';

  @override
  String progressShareTemplatesOfWork(Object durationText) {
    return '$durationText 동안의 운동';
  }

  @override
  String get progressShareTemplatesProgress => '진행 상황';

  @override
  String get progressShareTemplatesReportedBy => '보도:';

  @override
  String get progressShareTemplatesSourcesCloseToThe =>
      '관계자에 따르면, 꾸준한 운동과 정직한 식단, 그리고 하체 운동을 거르지 않은 결과라고 합니다. 전문가들은 이를 \"전례 없는 헌신\"이라 부릅니다.';

  @override
  String get progressShareTemplatesTheDailyGains => '매일의 성장';

  @override
  String progressShareTemplatesTheGlowUp(Object durationText) {
    return '$durationText 만의 변화';
  }

  @override
  String get progressShareTemplatesTheTransformation => '변화';

  @override
  String get progressShareTemplatesTimeline => '타임라인';

  @override
  String progressShareTemplatesToLater(Object durationText) {
    return '$durationText 후';
  }

  @override
  String get progressShareTemplatesToRightNow => '지금까지.';

  @override
  String progressShareTemplatesTotal(Object totalWorkouts) {
    return '총 $totalWorkouts회';
  }

  @override
  String get progressShareTemplatesTransformationNtuesday => '#변화\n화요일';

  @override
  String get progressShareTemplatesTransformed => '변화 완료';

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
    return '볼륨 $totalWorkouts';
  }

  @override
  String progressShareTemplatesWW(Object weeks) {
    return 'W1 → W$weeks';
  }

  @override
  String progressShareTemplatesWorkouts(Object totalWorkouts) {
    return '운동 $totalWorkouts회';
  }

  @override
  String progressShareTemplatesWorkoutsDayStreak(
    Object currentStreak,
    Object totalWorkouts,
  ) {
    return '운동 $totalWorkouts회 · $currentStreak일 연속';
  }

  @override
  String get progressShareTemplatesZealova => 'ZEALOVA';

  @override
  String get progressShareTemplatesZealovaMarket => 'ZEALOVA 마켓';

  @override
  String get progressSignUpToUnlock => '가입하고 잠금 해제';

  @override
  String get progressStrength => '근력';

  @override
  String get progressTakePhoto => '사진 찍기';

  @override
  String get progressTemplateDayStreak => '연속 기록';

  @override
  String get progressTemplatePrsThisMonth => '이번 달 PR';

  @override
  String get progressTemplateThisWeek => '이번 주';

  @override
  String get progressTemplateTotalLifted => '총 중량';

  @override
  String get progressTemplateTotalWorkouts => '총 운동 횟수';

  @override
  String get progressThisActionCannotBe => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get progressTrackYourFitnessJourney =>
      '진행 상황 사진, 신체 측정 및 근력 점수로 피트니스 여정을 기록하세요. 얼마나 성장했는지 확인해보세요!';

  @override
  String get progressUploadFailed => '업로드 실패';

  @override
  String get progressUploadingPhoto => '사진 업로드 중...';

  @override
  String get progressUseCamera => '카메라 사용';

  @override
  String get progressWeCouldnTSave => '사진을 저장할 수 없습니다. 다시 시도해주세요.';

  @override
  String progressionChainCardStepOf(Object chain, Object currentStepOrder) {
    return '$chain단계 중 $currentStepOrder단계';
  }

  @override
  String progressionChainCardStepOf2(Object chain, Object currentStepOrder) {
    return '$chain단계 중 $currentStepOrder단계';
  }

  @override
  String progressionChainCardSteps(Object chain) {
    return '$chain단계';
  }

  @override
  String get progressionPaceAutoDeloadWeeks => '자동 디로딩 주간';

  @override
  String get progressionPaceControlHowQuicklyThe =>
      'AI가 운동 중량을 얼마나 빠르게 늘릴지 조절하세요. 초보자에게는 느린 진행이 더 안전하며, 숙련자에게는 빠른 진행이 적합합니다.';

  @override
  String get progressionPaceDeloadFrequency => '디로딩 빈도';

  @override
  String get progressionPaceDeloadSettings => '디로딩 설정';

  @override
  String get progressionPaceFineTuneSettings => '미세 조정 설정';

  @override
  String get progressionPaceHowManyWeeksBefore => '중량 증가 전 주 수';

  @override
  String get progressionPaceHowMuchToIncrease => '진행 시 중량 증가량';

  @override
  String get progressionPacePeriodicallyReduceIntensity =>
      '회복을 위해 주기적으로 강도 낮추기';

  @override
  String get progressionPaceProgressionPace => '진행 속도';

  @override
  String get progressionPaceProgressionSpeed => '진행 속도';

  @override
  String get progressionPaceProgressiveOverload => '점진적 과부하';

  @override
  String get progressionPaceSaveSettings => '설정 저장';

  @override
  String progressionPaceScreenEveryWeeks(Object deloadFrequency) {
    return '$deloadFrequency주마다';
  }

  @override
  String progressionPaceScreenWeeks(Object weeksToProgress) {
    return '$weeksToProgress주';
  }

  @override
  String get progressionPaceSettingsSaved => '설정이 저장되었습니다';

  @override
  String get progressionPaceWeeksToProgress => '진행까지 걸리는 주';

  @override
  String get progressionPaceWeightIncrement => '중량 증가 단위';

  @override
  String get progressionSelectorAdvanced => '고급';

  @override
  String get progressionSelectorAutoAdjusts => '자동 조정';

  @override
  String get progressionSelectorChooseHowWeightChanges => '세트 간 중량 변화 방식 선택';

  @override
  String get progressionSelectorSetProgression => '진행 설정';

  @override
  String get progressionSelectorSubtitle => '부제목';

  @override
  String get progressionSelectorTitle => '제목';

  @override
  String get progressionSelectorWhenToUse => '사용 시기';

  @override
  String get progressionStepCardCompletePreviousStepTo => '이전 단계를 완료하여 잠금 해제';

  @override
  String get progressionStepCardCompleted => '완료됨';

  @override
  String progressionStepCardGoal(Object unlockCriteriaText) {
    return '목표: $unlockCriteriaText';
  }

  @override
  String get progressionStepCardPractice => '연습';

  @override
  String get progressionStripTarget => '목표 ';

  @override
  String get progressionSuggestionCardCompleteAFewMore =>
      '진행 단계를 잠금 해제하려면 \"쉬움\" 세션을 몇 번 더 완료하세요';

  @override
  String get progressionSuggestionCardCurrent => '현재';

  @override
  String get progressionSuggestionCardExerciseUnlocked => '운동 잠금 해제 완료!';

  @override
  String get progressionSuggestionCardKeepCurrent => '현재 유지';

  @override
  String get progressionSuggestionCardKeepGoing => '계속하세요!';

  @override
  String get progressionSuggestionCardNextLevel => '다음 단계';

  @override
  String get progressionSuggestionCardTryNextLevel => '다음 단계 시도';

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
  String get progressionSuggestionCardWhyThisProgression => '왜 이 진행 방식인가요?';

  @override
  String get proposedChangeCardApplied => '적용됨';

  @override
  String get proposedChangeCardApplyChange => '변경 사항 적용';

  @override
  String get proposedChangeCardDismissed => '무시됨';

  @override
  String get proposedChangeCardExpiredAskAgainFor => '만료됨 — 새로운 제안을 다시 요청하세요';

  @override
  String get proposedChangeCardNotNow => '나중에';

  @override
  String get protocolSelector12h => '12h';

  @override
  String get protocolSelectorAdvanced => '고급';

  @override
  String protocolSelectorChipHFast(Object fastingHours) {
    return '$fastingHours시간 단식';
  }

  @override
  String get protocolSelectorDuration => '기간';

  @override
  String get protocolSelectorExtendedFasts24h => '장기 단식 (24시간 이상)';

  @override
  String get protocolSelectorSelectProtocol => '프로토콜 선택';

  @override
  String protocolSelectorSheetHours(Object _customHours) {
    return '$_customHours시간';
  }

  @override
  String get protocolSelectorTimeRestrictedEating => '시간 제한 식사';

  @override
  String prsTemplateAchievementsUnlocked(Object length) {
    return '+$length 업적 달성';
  }

  @override
  String get prsTemplateKeepPushing => '계속 밀어붙이세요!';

  @override
  String get prsTemplateNewPersonalRecords => '새로운 개인 기록';

  @override
  String get prsTemplateNewPrsAreJust => '새로운 PR이 곧 다가옵니다';

  @override
  String prsTemplateValue2(Object improvement, Object unit) {
    return '+$improvement $unit';
  }

  @override
  String get publicRecipeIngredients => '재료';

  @override
  String get publicRecipeInstructions => '조리법';

  @override
  String get publicRecipeRecipeNotAvailable => '레시피를 사용할 수 없습니다';

  @override
  String get publicRecipeSaveToMyRecipes => '내 레시피에 저장';

  @override
  String publicRecipeScreenByViewsSaves(
    Object authorDisplayName,
    Object saveCount,
    Object viewCount,
  ) {
    return '$authorDisplayName 작성 · 조회수 $viewCount회 · 저장 $saveCount회';
  }

  @override
  String queuePositionCardEstimatedWaitMin(Object estimatedWaitMinutes) {
    return '예상 대기 시간: ~$estimatedWaitMinutes분';
  }

  @override
  String get queuePositionCardInQueue => '대기 중';

  @override
  String queuePositionCardInQueue2(Object position) {
    return '대기 순번 #$position';
  }

  @override
  String get queuePositionCardPleaseWaitWhileWe => '상담원과 연결될 때까지 잠시만 기다려주세요';

  @override
  String queuePositionCardValue(Object position) {
    return '#$position';
  }

  @override
  String get queuePositionCardYouAre => '현재 대기 순번은';

  @override
  String get quickActions500mlWaterLogged => '+500ml 수분 섭취 기록됨';

  @override
  String get quickActionsCustomizeQuickActions => '빠른 작업 사용자 지정';

  @override
  String get quickActionsDisplayExtraShortcutsOn => '홈 화면에 추가 바로가기 표시';

  @override
  String get quickActionsFailedToLogWater => '수분 섭취 기록 실패. 다시 시도해주세요.';

  @override
  String get quickActionsNoActionsFound => '작업을 찾을 수 없습니다';

  @override
  String get quickActionsPleaseLogInTo => '수분 섭취를 기록하려면 로그인하세요';

  @override
  String get quickActionsResetToDefault => '기본값으로 재설정';

  @override
  String get quickActionsRow1 => '1행';

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
  String get quickActionsRow2 => '2행';

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
  String get quickActionsRowActive => '활성';

  @override
  String get quickActionsRowBarcode => '바코드';

  @override
  String get quickActionsRowBigBottle => '큰 물병';

  @override
  String get quickActionsRowChat => '채팅';

  @override
  String get quickActionsRowCoach => '코치';

  @override
  String get quickActionsRowCustom => '사용자 지정';

  @override
  String get quickActionsRowCustomAmount => '사용자 지정 양';

  @override
  String get quickActionsRowEG180 => '예: 180';

  @override
  String get quickActionsRowEnd => '종료';

  @override
  String get quickActionsRowEnter15000Ml => '1~5000 ml 입력';

  @override
  String get quickActionsRowFailedToLogWater => '수분 섭취 기록에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get quickActionsRowFastEndedSuccessfully => '단식이 성공적으로 종료되었습니다';

  @override
  String get quickActionsRowFasting => '단식 중';

  @override
  String get quickActionsRowGlass => '컵';

  @override
  String get quickActionsRowLargeJug => '대형 물병';

  @override
  String get quickActionsRowLogFood => '음식 기록';

  @override
  String get quickActionsRowLogWater => '수분 기록';

  @override
  String get quickActionsRowMenu => '메뉴';

  @override
  String get quickActionsRowMood => '기분';

  @override
  String get quickActionsRowMouthful => '한 모금';

  @override
  String get quickActionsRowOpenHydrationTracker => '수분 섭취 추적기 열기';

  @override
  String get quickActionsRowOrPickAPreset => '또는 프리셋 선택';

  @override
  String quickActionsRowPartHeroActionCardFailedToEndFast(Object e) {
    return '단식 종료 실패: $e';
  }

  @override
  String quickActionsRowPartHeroActionCardFailedToUploadPhoto(Object e) {
    return '사진 업로드 실패: $e';
  }

  @override
  String quickActionsRowPartHeroActionCardHM(Object hours, Object mins) {
    return '$hours시간 $mins분';
  }

  @override
  String quickActionsRowPartHeroActionCardPhotoSaved(Object displayName) {
    return '$displayName 사진이 저장되었습니다!';
  }

  @override
  String get quickActionsRowPhotoLog => '사진 기록';

  @override
  String get quickActionsRowPleaseLogInTo => '수분 섭취를 추적하려면 로그인하세요';

  @override
  String get quickActionsRowQuick => '빠른 기록';

  @override
  String get quickActionsRowScan => '스캔';

  @override
  String get quickActionsRowSelectAmountToLog => '기록할 양 선택';

  @override
  String get quickActionsRowSip => '한 모금';

  @override
  String get quickActionsRowSipToXlJug => '한 모금부터 XL 물병까지, 또는 직접 입력';

  @override
  String get quickActionsRowSmallCup => '작은 컵';

  @override
  String get quickActionsRowSmallSip => '아주 조금';

  @override
  String get quickActionsRowSportsBottle => '스포츠 보틀';

  @override
  String get quickActionsRowTakeAProgressPhoto => '변화 과정을 확인하기 위해 사진을 찍어보세요';

  @override
  String get quickActionsRowTallGlass => '긴 컵';

  @override
  String get quickActionsRowTrackYourProgress => '진행 상황 추적';

  @override
  String get quickActionsRowUploadingPhoto => '사진 업로드 중...';

  @override
  String get quickActionsRowWater => '물';

  @override
  String get quickActionsRowWhatSThis => '이게 무엇인가요?';

  @override
  String get quickActionsRowXlJug => 'XL 물병';

  @override
  String get quickActionsSearchActions => '작업 검색...';

  @override
  String get quickActionsSheetActive => '활성';

  @override
  String get quickActionsSheetEnd => '종료';

  @override
  String get quickActionsSheetFastEndedSuccessfully => '단식이 성공적으로 종료되었습니다';

  @override
  String get quickActionsSheetFasting => '단식 중';

  @override
  String quickActionsSheetPartHeroActionCardFailedToEndFast(Object e) {
    return '단식 종료 실패: $e';
  }

  @override
  String quickActionsSheetPartHeroActionCardHM(Object hours, Object mins) {
    return '$hours시간 $mins분';
  }

  @override
  String get quickActionsSheetTakeAProgressPhoto => '변화 과정을 확인하기 위해 사진을 찍어보세요';

  @override
  String get quickActionsSheetTrackYourProgress => '진행 상황 추적';

  @override
  String get quickActionsShowTwoRows => '두 줄로 보기';

  @override
  String get quickAddFabLogFood => '음식 기록';

  @override
  String get quickAdjust5Min => '5분';

  @override
  String get quickAdjustAdaptWorkout => '운동 조정';

  @override
  String get quickAdjustAdjustTodaySWorkout => '오늘의 운동을 즉시 조정하세요.';

  @override
  String get quickAdjustDrained => '기진맥진';

  @override
  String get quickAdjustEnergy => '에너지';

  @override
  String get quickAdjustHowAreYouFeeling => '오늘 컨디션은 어떠신가요?';

  @override
  String get quickAdjustNone => '없음';

  @override
  String get quickAdjustPeak => '최상';

  @override
  String get quickAdjustSoreness => '근육통';

  @override
  String get quickAdjustTimeAvailable => '가용 시간';

  @override
  String get quickAdjustVerySore => '심한 근육통';

  @override
  String get quickLogFabBatch => '일괄';

  @override
  String get quickLogFabListening => '듣는 중...';

  @override
  String get quickLogFabLogFood => '음식 기록';

  @override
  String get quickLogFabPhoto => '사진';

  @override
  String get quickLogFabScan => '스캔';

  @override
  String get quickLogFabType => '입력';

  @override
  String get quickLogFabVoice => '음성';

  @override
  String get quickLogMeasurementsBodyMeasurements => '신체 치수';

  @override
  String get quickLogMeasurementsChest => '가슴';

  @override
  String get quickLogMeasurementsHips => '엉덩이';

  @override
  String get quickLogMeasurementsLoadingMeasurements => '치수 불러오는 중...';

  @override
  String get quickLogMeasurementsLog => '기록';

  @override
  String get quickLogMeasurementsLogMeasurements => '치수 기록';

  @override
  String get quickLogMeasurementsMeasurements => '치수';

  @override
  String get quickLogMeasurementsNotLoggedYet => '아직 기록되지 않음';

  @override
  String get quickLogMeasurementsPleaseSignInTo => '치수를 기록하려면 로그인하세요';

  @override
  String get quickLogMeasurementsTapToViewFull => '탭하여 전체 기록 및 추세 보기';

  @override
  String get quickLogMeasurementsTrackYourBodyChanges => '시간에 따른 신체 변화 추적';

  @override
  String get quickLogMeasurementsUpdate => '업데이트';

  @override
  String quickLogMeasurementsUpdatedDaysAgo(Object arg0) {
    return '$arg0일 전 업데이트';
  }

  @override
  String get quickLogMeasurementsUpdatedToday => '오늘 업데이트됨';

  @override
  String get quickLogMeasurementsUpdatedYesterday => '어제';

  @override
  String get quickLogMeasurementsWaist => '허리';

  @override
  String get quickLogOverlayBreakfast => '아침';

  @override
  String get quickLogOverlayDinner => '저녁';

  @override
  String get quickLogOverlayGoToApp => '앱으로 이동';

  @override
  String get quickLogOverlayLunch => '점심';

  @override
  String get quickLogOverlayQuickLog => '빠른 기록';

  @override
  String get quickLogOverlaySnack => '간식';

  @override
  String get quickLogOverlayTapAMealType =>
      '기록할 식사 유형을 탭하거나, 앱에서 더 많은 옵션을 확인하세요';

  @override
  String get quickLogWeightLogMoreWeightsTo => '더 많은 체중을 기록하고 변화 추이를 확인하세요';

  @override
  String get quickLogWeightLogged => '기록 완료!';

  @override
  String get quickLogWeightQuickLogWeight => '빠른 체중 기록';

  @override
  String get quickStartCardCouldNotLoadWorkout => '운동을 불러올 수 없습니다';

  @override
  String get quickStartCardGenerateAWorkoutProgram => '운동 프로그램을 생성하고 시작하세요!';

  @override
  String quickStartCardInDays(Object daysUntilNext) {
    return '$daysUntilNext일 후';
  }

  @override
  String get quickStartCardLoadingTodaySWorkout => '오늘의 운동을 불러오는 중...';

  @override
  String quickStartCardNext(Object name) {
    return '다음: $name';
  }

  @override
  String get quickStartCardNoWorkoutsScheduled => '예정된 운동이 없습니다';

  @override
  String get quickStartCardRestDay => '휴식일';

  @override
  String get quickStartCardStartWorkout => '운동 시작';

  @override
  String get quickStartCardTakeItEasyToday => '오늘은 가볍게 쉬어가세요!';

  @override
  String get quickStartCardTomorrow => '내일';

  @override
  String get quickStartCardViewUpcoming => '예정된 운동 보기';

  @override
  String get quickStatsCardActive => '활성';

  @override
  String get quickStatsCardActiveFeatures => '활성 기능';

  @override
  String get quickStatsCardConfigureYourHormonalHealth =>
      '호르몬 건강 설정을 구성하여 개인 맞춤형 인사이트를 확인하세요.';

  @override
  String get quickStatsCardCycleSyncedNutrition => '주기 동기화 영양';

  @override
  String get quickStatsCardCycleSyncedWorkouts => '주기 동기화 운동';

  @override
  String get quickStatsCardCycleTracking => '주기 추적';

  @override
  String get quickStatsCardEnabled => '활성화됨';

  @override
  String get quickStatsCardOn => '켜짐';

  @override
  String get quickStatsCardPcosSupport => 'PCOS 지원';

  @override
  String get quickStatsCardTOptimization => 'T-Optimization';

  @override
  String get quickWorkoutAllEquipment => '모든 장비';

  @override
  String get quickWorkoutAvailableWeights => '사용 가능한 무게';

  @override
  String get quickWorkoutConflictAddAnyway => '그래도 추가';

  @override
  String quickWorkoutConflictBody(Object workoutName) {
    return '오늘 \"$workoutName\" 운동이 이미 예약되어 있습니다. 어떻게 하시겠습니까?';
  }

  @override
  String get quickWorkoutConflictChangeDate => '날짜 변경';

  @override
  String get quickWorkoutConflictReplace => '대체';

  @override
  String get quickWorkoutConflictTitle => '이미 예약된 운동';

  @override
  String get quickWorkoutDiscoverSubtitle => '프로필 기반 맞춤형 추천';

  @override
  String get quickWorkoutDiscoverWorkouts => '운동 탐색';

  @override
  String get quickWorkoutDuration => '운동 시간';

  @override
  String get quickWorkoutFavorite => '즐겨찾기';

  @override
  String get quickWorkoutFocus => '집중 부위';

  @override
  String get quickWorkoutFocusOptional => '운동 부위 (선택 사항)';

  @override
  String get quickWorkoutNoSuggestions => '추천 항목 없음';

  @override
  String get quickWorkoutSheetAddAnyway => '그래도 추가';

  @override
  String get quickWorkoutSheetAllEquipment => '모든 장비';

  @override
  String get quickWorkoutSheetAvailableWeights => '사용 가능한 무게';

  @override
  String get quickWorkoutSheetChangeDate => '날짜 변경';

  @override
  String get quickWorkoutSheetClear => '지우기';

  @override
  String get quickWorkoutSheetCustomizeMore => '추가 맞춤 설정';

  @override
  String get quickWorkoutSheetDifficulty => '난이도';

  @override
  String get quickWorkoutSheetDiscoverWorkouts => '운동 탐색';

  @override
  String get quickWorkoutSheetDuration => '운동 시간';

  @override
  String get quickWorkoutSheetEquipment => '장비';

  @override
  String get quickWorkoutSheetEquipmentDetails => '장비 세부 정보';

  @override
  String get quickWorkoutSheetFavorite => '즐겨찾기';

  @override
  String get quickWorkoutSheetFocusOptional => '집중 부위 (선택 사항)';

  @override
  String get quickWorkoutSheetFormat => '형식';

  @override
  String get quickWorkoutSheetFullGym => '전체 헬스장 장비';

  @override
  String get quickWorkoutSheetGenerating => '생성 중...';

  @override
  String get quickWorkoutSheetGoalOptional => '목표 (선택 사항)';

  @override
  String get quickWorkoutSheetInjuriesOptional => '부상 부위 (선택 사항)';

  @override
  String get quickWorkoutSheetInstantGenerationPoweredBy =>
      '운동 과학 연구를 기반으로 즉시 생성됩니다.';

  @override
  String get quickWorkoutSheetMoodOptional => '기분 (선택 사항)';

  @override
  String get quickWorkoutSheetNoAdditionalSuggestionsAvai =>
      '추가 제안을 사용할 수 없습니다.';

  @override
  String get quickWorkoutSheetPairOpposingMusclesTo => '길항근을 묶어 시간을 절약하세요';

  @override
  String quickWorkoutSheetPartQuickWorkoutSheetStateExt1X(Object qty) {
    return '${qty}x';
  }

  @override
  String quickWorkoutSheetPartQuickWorkoutSheetStateGenerateMinWorkout(
    Object _selectedDuration,
  ) {
    return '$_selectedDuration분 운동 생성';
  }

  @override
  String quickWorkoutSheetPartQuickWorkoutSheetStateMesocycle(
    Object phaseDisplayName,
  ) {
    return '메조사이클: $phaseDisplayName';
  }

  @override
  String quickWorkoutSheetPartQuickWorkoutSheetStateMin(
    Object _selectedDuration,
  ) {
    return '$_selectedDuration분';
  }

  @override
  String quickWorkoutSheetPartQuickWorkoutSheetStateWeek(
    Object totalWeeks,
    Object weekNumber,
  ) {
    return '$weekNumber/$totalWeeks주차';
  }

  @override
  String get quickWorkoutSheetPerfectForBusyDays => '바쁜 날에 완벽합니다';

  @override
  String get quickWorkoutSheetPersonalizedSuggestionsBased => '프로필 기반 맞춤형 제안';

  @override
  String get quickWorkoutSheetQuickWorkout => '빠른 운동';

  @override
  String get quickWorkoutSheetReplace => '교체';

  @override
  String get quickWorkoutSheetShowLess => '간략히 보기';

  @override
  String get quickWorkoutSheetSupersets => '슈퍼세트';

  @override
  String get quickWorkoutSheetTapToAddTap => '탭하여 추가 (다시 탭하면 묶기)';

  @override
  String get quickWorkoutSheetUnfavorite => '즐겨찾기 해제';

  @override
  String get quickWorkoutSheetWithPlates => '원판 포함';

  @override
  String get quickWorkoutSheetWorkoutAlreadyScheduled => '이미 예정된 운동입니다';

  @override
  String get quickWorkoutSheetWorkoutFocus => '운동 집중 부위';

  @override
  String get quickWorkoutSubtitle => '부제목';

  @override
  String get quickWorkoutTapToAddPairs => '탭하여 덤벨 쌍 추가';

  @override
  String get quickWorkoutTitle => '제목';

  @override
  String get quickWorkoutUnfavorite => '즐겨찾기 해제';

  @override
  String get quickWorkoutWithPlates => '원판 포함';

  @override
  String get quitWorkoutAddANoteOptional => '메모 추가 (선택 사항)...';

  @override
  String quitWorkoutDialogCompleteSetsDone(
    Object progressPercent,
    Object totalCompletedSets,
  ) {
    return '$progressPercent% 완료 · $totalCompletedSets 세트 완료';
  }

  @override
  String quitWorkoutDialogSays(Object name) {
    return '$name의 메시지:';
  }

  @override
  String get quitWorkoutEndWorkout => '운동 종료';

  @override
  String get quitWorkoutEndWorkoutEarly => '운동을 일찍 종료할까요?';

  @override
  String get quitWorkoutEquipmentBusy => '장비 사용 중';

  @override
  String get quitWorkoutKeepGoing => '계속하기';

  @override
  String get quitWorkoutNotFeelingWell => '컨디션 난조';

  @override
  String get quitWorkoutOtherReason => '기타 사유';

  @override
  String get quitWorkoutOutOfTime => '시간 부족';

  @override
  String get quitWorkoutPainInjury => '통증/부상';

  @override
  String get quitWorkoutTooTired => '너무 피곤함';

  @override
  String get quitWorkoutWhyAreYouEnding => '운동을 일찍 종료하는 이유는 무엇인가요?';

  @override
  String quizBodyMetricsEnterAValueBetween(Object dialogMax, Object unit) {
    return '1-$dialogMax $unit 사이의 값을 입력하세요';
  }

  @override
  String quizBodyMetricsEnterAmountTo(Object directionLabel) {
    return '$directionLabel할 양을 입력하세요';
  }

  @override
  String get quizBodyMetricsGain => '증량';

  @override
  String get quizBodyMetricsGender => '성별';

  @override
  String get quizBodyMetricsHeight => '키';

  @override
  String quizBodyMetricsHowMuchDoYou(Object directionLabel) {
    return '$directionLabel하고 싶은 양은 얼마인가요?';
  }

  @override
  String get quizBodyMetricsLetSSetYour => '신체 목표를 설정해 보세요';

  @override
  String get quizBodyMetricsLose => '감량';

  @override
  String get quizBodyMetricsMaintain => '유지';

  @override
  String get quizBodyMetricsOther => '기타';

  @override
  String quizBodyMetricsUiCurrentBmi(Object bmi) {
    return '현재 BMI: $bmi';
  }

  @override
  String quizBodyMetricsUiY(Object age) {
    return '$age세';
  }

  @override
  String get quizBodyMetricsWeLlUseThis => '개인 맞춤형 목표를 계산하는 데 사용됩니다';

  @override
  String get quizBodyMetricsWeight => '체중';

  @override
  String get quizBodyMetricsWeightGoal => '체중 목표';

  @override
  String get quizBodyMetricsWhatShouldWeCall => '어떻게 불러드릴까요?';

  @override
  String get quizBodyMetricsYourName => '이름';

  @override
  String get quizContinueButtonSeeMyPlan => '내 플랜 보기';

  @override
  String get quizDaysSelectorAiGeneratesWorkoutsWithin =>
      'AI가 선택하신 범위 내에서 운동을 생성합니다';

  @override
  String get quizDaysSelectorBest => '최적';

  @override
  String get quizDaysSelectorConsistencyBeatsIntensity =>
      '강도보다 꾸준함이 중요합니다. 유지할 수 있는 만큼 선택하세요';

  @override
  String quizDaysSelectorDays(int arg0) {
    String _temp0 = intl.Intl.pluralLogic(
      arg0,
      locale: localeName,
      other: '일',
      one: '일',
    );
    return '$_temp0';
  }

  @override
  String quizDaysSelectorDaysSelected(Object arg0, Object arg1) {
    return '$arg0 / $arg1일 선택됨';
  }

  @override
  String get quizDaysSelectorFri => '금';

  @override
  String get quizDaysSelectorHowLongAreYour => '운동 시간은 어느 정도인가요?';

  @override
  String get quizDaysSelectorHowManyDaysPer => '일주일에 며칠 운동할 수 있나요?';

  @override
  String get quizDaysSelectorMin => '최소';

  @override
  String get quizDaysSelectorMon => '월';

  @override
  String get quizDaysSelectorSat => '토';

  @override
  String quizDaysSelectorSelectNDays(Object arg0) {
    return '맞는 날 $arg0일을 선택하세요';
  }

  @override
  String get quizDaysSelectorSun => '일';

  @override
  String get quizDaysSelectorThu => '목';

  @override
  String get quizDaysSelectorTue => '화';

  @override
  String get quizDaysSelectorWed => '수';

  @override
  String get quizDaysSelectorWhichDaysWorkBest => '어떤 요일이 가장 좋나요?';

  @override
  String get quizEquipmentAddMoreGymsLaterHint => '체육관은 나중에 더 추가할 수 있어요';

  @override
  String get quizEquipmentApartmentFriendly => '아파트 친화적';

  @override
  String get quizEquipmentBarbell => '바벨';

  @override
  String get quizEquipmentOlympicBarbell => '올림픽 역도 바';

  @override
  String get quizEquipmentEzBar => 'EZ 바';

  @override
  String get quizEquipmentTrapBar => '트랩 바';

  @override
  String get quizEquipmentSafetySquatBar => '세이프티 스쿼트 바';

  @override
  String get quizEquipmentCamberedBar => '캠버 바';

  @override
  String get quizEquipmentSwissBar => '스위스 바';

  @override
  String get quizEquipmentLogBar => '로그 바';

  @override
  String get quizEquipmentBodyweightBands => '맨몸 + 밴드';

  @override
  String get quizEquipmentBodyweightOnly => '맨몸 운동만';

  @override
  String get quizEquipmentBodyweightOnly2 => '맨몸 운동 전용';

  @override
  String get quizEquipmentBodyweightPullUpBar => '맨몸 + 풀업 바';

  @override
  String get quizEquipmentCableMachine => '케이블 머신';

  @override
  String get quizEquipmentCouldnTLoadIdentified =>
      '식별된 장비를 불러올 수 없습니다. 아래 목록에서 선택하세요.';

  @override
  String get quizEquipmentCouldnTOpenThe => '카메라를 열 수 없습니다. 아래에서 장비를 선택하세요.';

  @override
  String get quizEquipmentDedicatedSpaceWithDumbbells => '덤벨, 바벨, 벤치가 있는 전용 공간';

  @override
  String get quizEquipmentDoYouHaveA => '웨이트 벤치가 있나요?';

  @override
  String get quizEquipmentDoYouHaveA2 => '스쿼트 랙이 있나요?';

  @override
  String get quizEquipmentDumbbells => '덤벨';

  @override
  String get quizEquipmentEnablesChestPress => '체스트 프레스 가능';

  @override
  String get quizEquipmentFlatBench => '플랫 벤치';

  @override
  String get quizEquipmentFullGym => '전체 헬스장';

  @override
  String get quizEquipmentFullGymAccess => '헬스장 이용 가능';

  @override
  String get quizEquipmentFullGymWithMachines => '머신, 케이블, 프리 웨이트가 있는 전체 헬스장';

  @override
  String get quizEquipmentGym => '헬스장';

  @override
  String get quizEquipmentHome => '홈짐';

  @override
  String get quizEquipmentHomeDumbbellsBench => '홈 + 덤벨 & 벤치';

  @override
  String get quizEquipmentHomeGym => '홈짐';

  @override
  String get quizEquipmentHomeKettlebell => '홈 + 케틀벨';

  @override
  String get quizEquipmentHotel => '호텔';

  @override
  String quizEquipmentIdentifiedCount(Object arg0) {
    return '$arg0개를 인식했습니다. 탭하여 선택 해제하세요.';
  }

  @override
  String get quizEquipmentKettlebell => '케틀벨';

  @override
  String get quizEquipmentMedicineBall => '메디신 볼';

  @override
  String get quizEquipmentMinimalEquipmentBodyweight => '최소 장비 - 맨몸, 매트';

  @override
  String get quizEquipmentNeededForBarbell => '바벨 운동에 필요';

  @override
  String get quizEquipmentNoEquipmentIdentifiedPick =>
      '식별된 장비가 없습니다. 아래 목록에서 선택하세요.';

  @override
  String quizEquipmentOtherCount(Object arg0) {
    return '$arg0개 선택됨';
  }

  @override
  String get quizEquipmentOtherEquipment => '기타 장비';

  @override
  String get quizEquipmentPullUpBar => '풀업 바';

  @override
  String get quizEquipmentQuickPresets => '빠른 프리셋';

  @override
  String get quizEquipmentImportSubtitle => '이미 있는 체육관 사진';

  @override
  String get quizEquipmentImportTitle => '사진에서 가져오기';

  @override
  String get quizEquipmentRecommended => '추천';

  @override
  String get quizEquipmentSnapSubtitle => '카메라로 비추세요';

  @override
  String get quizEquipmentSnapTitle => '체육관 촬영';

  @override
  String get quizEquipmentRequiredForBarbellSquat =>
      '필수: 바벨 스쿼트, 오버헤드 프레스, 바벨 벤치 프레스';

  @override
  String get quizEquipmentResistanceBands => '저항 밴드';

  @override
  String get quizEquipmentSelectAllThatApply =>
      '해당되는 모든 항목을 선택하세요. 보유하신 장비에 맞춰 운동을 설계해 드립니다';

  @override
  String get quizEquipmentSelectingYourWorkoutEnviron =>
      '운동 환경을 선택하면 적절한 운동과 장비를 추천해 드릴 수 있습니다.';

  @override
  String get quizEquipmentSquatRack => '스쿼트 랙';

  @override
  String get quizEquipmentTakeAFewPhotos => '사진을 몇 장 찍으면 AI가 장비를 식별합니다.';

  @override
  String get quizEquipmentTravelFriendlyDumbbellsC => '여행 친화적 - 덤벨, 유산소 머신';

  @override
  String get quizEquipmentTrxSuspension => 'TRX 서스펜션';

  @override
  String get quizEquipmentU1f3e0 => '🏠';

  @override
  String get quizEquipmentU1f3e1 => '🏡';

  @override
  String get quizEquipmentU1f3e2 => '🏢';

  @override
  String get quizEquipmentU1f4f8SnapYour => '📸 헬스장 촬영하기';

  @override
  String get quizEquipmentU1f9f3 => '🧳';

  @override
  String get quizEquipmentUnlocksBenchPressIncline =>
      '잠금 해제: 벤치 프레스, 인클라인 프레스, 풀오버, 체스트 서포티드 로우';

  @override
  String get quizEquipmentUnlocksChestSupportedKb =>
      '잠금 해제: 체스트 서포티드 KB 로우, KB 플로어 프레스 대안';

  @override
  String quizEquipmentUsersSnappedEquipment(Object apiBaseUrl, Object userId) {
    return '$apiBaseUrl/users/$userId/snapped-equipment';
  }

  @override
  String get quizEquipmentWhatEquipmentDoYou => '어떤 장비를 사용할 수 있나요?';

  @override
  String get quizEquipmentWhereDoYouWorkout => '어디서 운동하시나요?';

  @override
  String get quizEquipmentWorkoutEnvironment => '운동 환경';

  @override
  String get quizEquipmentYesAddIt => '네, 추가합니다';

  @override
  String get quizEquipmentYouCanCustomizeEquipment =>
      '환경 선택 후 장비를 맞춤 설정하거나, 건너뛰고 수동으로 선택할 수 있습니다.';

  @override
  String get quizFastingApplyCustomProtocol => '맞춤형 프로토콜 적용';

  @override
  String get quizFastingChooseAFastingProtocol => '단식 프로토콜 선택';

  @override
  String quizFastingCustomProtocol(
    Object _customEatingHours,
    Object _customFastingHours,
  ) {
    return '맞춤형 $_customFastingHours:$_customEatingHours 프로토콜';
  }

  @override
  String get quizFastingEatingHours => '식사 시간';

  @override
  String get quizFastingFastingHours => '단식 시간';

  @override
  String quizFastingH(Object _customFastingHours) {
    return '$_customFastingHours시간';
  }

  @override
  String quizFastingH2(Object _customEatingHours) {
    return '$_customEatingHours시간';
  }

  @override
  String get quizFastingIntermittentFastingCanHelp =>
      '간헐적 단식은 목표 달성 속도를 높이는 데 도움이 됩니다';

  @override
  String get quizFastingOptionalYouCanSet => '선택 사항 - 나중에 설정할 수 있습니다';

  @override
  String get quizFastingPopular => '인기';

  @override
  String get quizFastingRecommended => '추천';

  @override
  String get quizFastingSetYourCustomFasting => '맞춤형 단식 시간 설정';

  @override
  String quizFastingUiAHEatingWindow(Object eatingHours, Object maxMeals) {
    return '$eatingHours시간 식사 윈도우에는 최대 $maxMeals끼 식사가 적당합니다.';
  }

  @override
  String quizFastingUiAdjustToMeals(Object maxMeals) {
    return '$maxMeals끼로 조정';
  }

  @override
  String get quizFastingUiBedtime => '취침 시간';

  @override
  String get quizFastingUiHelpsOptimizeYourFasting => '단식 시간을 최적화하는 데 도움이 됩니다';

  @override
  String quizFastingUiMealScheduleInH(Object eatingHours) {
    return '$eatingHours시간 윈도우 내 식사 일정';
  }

  @override
  String quizFastingUiMealsSpacedHoursApart(
    Object hoursBetweenMeals,
    Object meals,
  ) {
    return '$meals끼 식사, 약 $hoursBetweenMeals시간 간격';
  }

  @override
  String get quizFastingUiTipConsiderLargerNutrient => '팁: 영양가가 높은 식사를 고려하세요';

  @override
  String get quizFastingUiWakeUp => '기상 시간';

  @override
  String get quizFastingUiYourSleepSchedule => '수면 일정';

  @override
  String get quizFastingYesLetSTry => '네, 시도해 볼게요';

  @override
  String get quizFitnessLevel2To5Years => '2~5년';

  @override
  String get quizFitnessLevel5PlusYears => '5년 이상';

  @override
  String get quizFitnessLevel6MonTo2Yrs => '6개월~2년';

  @override
  String get quizFitnessLevelAdvanced => '상급자';

  @override
  String get quizFitnessLevelAdvancedDesc => '상급자 설명';

  @override
  String get quizFitnessLevelBeHonestWeLl => '솔직하게 답변해 주세요. 진행 상황에 맞춰 조정해 드립니다';

  @override
  String get quizFitnessLevelBeginner => '초급자';

  @override
  String get quizFitnessLevelBeginnerDesc => '초급자 설명';

  @override
  String get quizFitnessLevelBrandNewToLifting => '웨이트 트레이닝 입문';

  @override
  String get quizFitnessLevelBuildingConsistency => '꾸준히 운동하는 중';

  @override
  String get quizFitnessLevelDailyActivityLevelOutside => '일상적인 활동 수준(운동 외)?';

  @override
  String get quizFitnessLevelHelpsCalculateYourCalorie => '칼로리 필요량 계산에 도움이 됩니다';

  @override
  String get quizFitnessLevelHowLongHaveYou => '웨이트 트레이닝을 얼마나 하셨나요?';

  @override
  String get quizFitnessLevelIntermediate => '중급자';

  @override
  String get quizFitnessLevelIntermediateDesc => '중급자 설명';

  @override
  String get quizFitnessLevelJustGettingStarted => '이제 막 시작함';

  @override
  String get quizFitnessLevelLessThan6Months => '6개월 미만';

  @override
  String get quizFitnessLevelLight => '가벼운 활동';

  @override
  String get quizFitnessLevelLightDesc => '가벼운 활동 설명';

  @override
  String get quizFitnessLevelModerate => '보통 활동';

  @override
  String get quizFitnessLevelModerateDesc => '보통 활동 설명';

  @override
  String get quizFitnessLevelNever => '전혀 안 함';

  @override
  String get quizFitnessLevelSedentary => '비활동적';

  @override
  String get quizFitnessLevelSedentaryDesc => '비활동적 설명';

  @override
  String get quizFitnessLevelSolidFoundation => '탄탄한 기본기';

  @override
  String get quizFitnessLevelThisHelpsUsPick => '적절한 운동을 선택하는 데 도움이 됩니다';

  @override
  String get quizFitnessLevelVeryActive => '매우 활동적';

  @override
  String get quizFitnessLevelVeryActiveDesc => '매우 활동적 설명';

  @override
  String get quizFitnessLevelVeteranLifter => '숙련된 리프터';

  @override
  String get quizFitnessLevelWhatSYourCurrent => '현재 피트니스 수준은 어느 정도인가요?';

  @override
  String get quizLimitationsAnyInjuriesOrLimitations => '부상이나 신체적 제한 사항이 있나요?';

  @override
  String get quizLimitationsDescribeYourLimitation => '제한 사항을 설명해 주세요';

  @override
  String get quizLimitationsEGCarpalTunnel => '예: 손목터널증후군, 허리 디스크 등';

  @override
  String get quizLimitationsWeLlAvoidExercises => '해당 부위에 무리가 가는 운동은 피하겠습니다';

  @override
  String get quizMotivationBeHealthierOverall => '전반적인 건강 증진';

  @override
  String get quizMotivationBuildConfidence => '자신감 향상';

  @override
  String get quizMotivationFeelStronger => '더 강해진 느낌';

  @override
  String get quizMotivationHaveMoreEnergy => '에너지 증진';

  @override
  String get quizMotivationImproveMentalHealth => '정신 건강 개선';

  @override
  String get quizMotivationLookBetter => '외모 개선';

  @override
  String get quizMotivationSelectAllThatResonate => '공감되는 모든 항목을 선택하세요';

  @override
  String get quizMotivationSleepBetter => '수면 질 개선';

  @override
  String get quizMotivationSportsPerformance => '스포츠 경기력 향상';

  @override
  String get quizMotivationWhatSDrivingYou => '운동을 하게 된 동기는 무엇인가요?';

  @override
  String quizMuscleFocusAvailable(
    Object availablePoints,
    Object maxTotalPoints,
  ) {
    return '$availablePoints / $maxTotalPoints점 사용 가능';
  }

  @override
  String get quizMuscleFocusCore => '코어';

  @override
  String get quizMuscleFocusFocusPoints => '집중 부위';

  @override
  String get quizMuscleFocusLowerBody => '하체';

  @override
  String get quizMuscleFocusUpperBody => '상체';

  @override
  String get quizNutritionGateCalorieMacroTargets => '칼로리 및 매크로 목표';

  @override
  String get quizNutritionGateDietaryPreferences => '식단 선호도';

  @override
  String get quizNutritionGateGetPersonalizedCalorieAnd =>
      '피트니스 목표를 지원하기 위한 개인 맞춤형 칼로리 및 매크로 목표를 받으세요';

  @override
  String get quizNutritionGateMealTimingGuidance => '식사 시간 안내';

  @override
  String get quizNutritionGateNotNow => '나중에';

  @override
  String get quizNutritionGateOptimizeWhenYouEat => '더 나은 결과를 위해 식사 시간을 최적화하세요';

  @override
  String get quizNutritionGateOptional => '선택 사항';

  @override
  String get quizNutritionGateRecommendedForYou => '회원님을 위한 추천';

  @override
  String get quizNutritionGateRespectsYourRestrictionsAnd => '식단 제한 및 선호 사항 반영';

  @override
  String get quizNutritionGateTailoredToYourGoals => '목표와 활동 수준에 맞춤화';

  @override
  String get quizNutritionGateWantNutritionGuidanceToo => '영양 가이드도 필요하신가요?';

  @override
  String get quizNutritionGateYesSetNutrition => '네, 영양 설정하기';

  @override
  String get quizNutritionGoalsAnyDietaryRestrictions => '식단 제한 사항이 있나요?';

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
  String get quizNutritionGoalsHelpsPersonalizeMealSuggest =>
      '식단 추천을 개인화하는 데 도움이 됩니다';

  @override
  String get quizNutritionGoalsIncludeAllMealsAnd => '모든 식사와 간식 포함';

  @override
  String quizNutritionGoalsKcalGProteinPer(
    Object calPerMeal,
    Object proteinPerMeal,
  ) {
    return '끼니당 약 $calPerMeal kcal & 단백질 ${proteinPerMeal}g';
  }

  @override
  String get quizNutritionGoalsMealsSnacksPerDay => '하루 식사 및 간식 횟수';

  @override
  String get quizNutritionGoalsSelectAllThatApply => '해당하는 모든 항목을 선택하세요';

  @override
  String get quizNutritionGoalsWhatAreYourNutrition => '영양 목표는 무엇인가요?';

  @override
  String get quizNutritionGoalsYourEstimatedDailyTargets => '예상 일일 목표';

  @override
  String get quizPersonalizationGateAFewQuickMeasurements => '간단한 신체 측정';

  @override
  String get quizPersonalizationGateCurrentWeight => '현재 체중';

  @override
  String get quizPersonalizationGateFemale => '여성';

  @override
  String get quizPersonalizationGateFineTune2Min => '세부 설정 (2분)';

  @override
  String get quizPersonalizationGateGoalWeight => '목표 체중';

  @override
  String get quizPersonalizationGateHeight => '키';

  @override
  String get quizPersonalizationGateMale => '남성';

  @override
  String get quizPersonalizationGateOther => '기타';

  @override
  String get quizPersonalizationGateQuickStart => '빠른 시작';

  @override
  String get quizPersonalizationGateUsedToPersonalizeYour =>
      '플랜과 예상치를 개인화하는 데 사용됩니다';

  @override
  String get quizPrimaryGoalAdjustsRestPeriodsExercise =>
      '휴식 시간, 운동 난이도, 전체 운동 볼륨을 목표에 따라 조정합니다.';

  @override
  String get quizPrimaryGoalAiPicksExercisesThat =>
      'AI가 목표에 가장 적합한 운동을 선택합니다. 근력 향상을 위한 복합 관절 운동, 근비대를 위한 고립 운동 등을 포함합니다.';

  @override
  String get quizPrimaryGoalCanChangeAnytime => '언제든지 변경 가능';

  @override
  String get quizPrimaryGoalExerciseSelection => '운동 선택';

  @override
  String get quizPrimaryGoalGotIt => '확인했습니다';

  @override
  String get quizPrimaryGoalHowAiUsesThis => 'AI 활용 방법';

  @override
  String get quizPrimaryGoalRepRanges => '반복 횟수 범위';

  @override
  String get quizPrimaryGoalSetsTheNumberOf =>
      '운동당 반복 횟수를 설정합니다. 근비대는 8-12회, 근력은 3-6회, 지구력은 12회 이상을 사용합니다.';

  @override
  String get quizPrimaryGoalWorkoutIntensity => '운동 강도';

  @override
  String get quizPrimaryGoalYouCanUpdateYour =>
      '목표가 변경되면 설정에서 언제든지 훈련 목표를 업데이트할 수 있습니다.';

  @override
  String get quizProgressionConstraintsBalanced => '균형 잡힌';

  @override
  String get quizProgressionConstraintsBuildStrengthGraduallyLowe =>
      '점진적으로 근력 향상, 부상 위험 감소';

  @override
  String get quizProgressionConstraintsFastAggressive => '빠르고 공격적인';

  @override
  String get quizProgressionConstraintsHowFastDoYou => '어느 정도의 속도로 진행하고 싶으신가요?';

  @override
  String get quizProgressionConstraintsProgressionPace => '진행 속도';

  @override
  String get quizProgressionConstraintsPushHardFasterGains =>
      '강도 높게, 빠른 성과 (상급자용)';

  @override
  String get quizProgressionConstraintsSlowSteady => '느리고 꾸준한';

  @override
  String get quizProgressionConstraintsSteadyProgressWithManageabl =>
      '관리 가능한 수준으로 꾸준히 진행';

  @override
  String get quizTrainingPreferencesAllOptional => '모두 선택 사항';

  @override
  String get quizTrainingPreferencesBiggestObstacles => '가장 큰 장애물';

  @override
  String get quizTrainingPreferencesNotSureTapTo => '잘 모르시나요? 탭하여 자세히 보기';

  @override
  String get quizTrainingPreferencesProgressionPace => '진행 속도';

  @override
  String get quizTrainingPreferencesProgressiveOverloadRirInt =>
      '점진적 과부하 및 RIR 통합';

  @override
  String get quizTrainingPreferencesTrainingPreferences => '훈련 선호도';

  @override
  String get quizTrainingPreferencesTrainingSplitsExplained => '훈련 분할 설명';

  @override
  String quizTrainingPreferencesValue(Object selectedCount) {
    return '$selectedCount/3';
  }

  @override
  String get quizTrainingPreferencesWorkoutTypes => '운동 유형';

  @override
  String get quizTrainingStyleArnoldSplit => '아놀드 분할';

  @override
  String get quizTrainingStyleAutomaticallyOptimizedForYo =>
      '일정에 맞춰 자동 최적화 (권장)';

  @override
  String get quizTrainingStyleBestFor56 => '주 5-6회에 적합';

  @override
  String get quizTrainingStyleBodyPartSplit => '부위별 분할';

  @override
  String get quizTrainingStyleChestBackShouldersArms => '가슴/등, 어깨/팔, 하체 (6일)';

  @override
  String get quizTrainingStyleChooseHowYouWant => '운동 구조를 선택하세요';

  @override
  String get quizTrainingStyleDoYouPreferThe =>
      '매주 동일한 운동을 선호하시나요, 아니면 다양성을 선호하시나요?';

  @override
  String get quizTrainingStyleExerciseVariety => '운동 다양성';

  @override
  String get quizTrainingStyleFullBody => '전신 운동';

  @override
  String get quizTrainingStyleLetAiDecide => 'AI가 결정하도록 하기';

  @override
  String get quizTrainingStyleOneMuscleGroupPer => '하루에 한 근육군 (5일 이상)';

  @override
  String get quizTrainingStylePowerHypertrophyAdaptiveTra =>
      'PHAT (파워 및 근비대 적응 훈련) (5일)';

  @override
  String get quizTrainingStylePowerHypertrophyUpperL =>
      '파워 + 근비대, 상체 + 하체 (4일)';

  @override
  String get quizTrainingStylePushPullLegsPpl => '밀기 / 당기기 / 하체 (PPL)';

  @override
  String get quizTrainingStylePushPullLegsUpper => '밀기/당기기/하체/상체/하체 (5일)';

  @override
  String get quizTrainingStyleScheduleConflict => '일정 충돌';

  @override
  String get quizTrainingStyleSplitBetweenUpperAnd => '상체와 하체 분할 (4일)';

  @override
  String get quizTrainingStyleTrainAllMusclesEach => '매 운동마다 모든 근육 훈련 (2-4일)';

  @override
  String get quizTrainingStyleTrainingSplit => '훈련 분할';

  @override
  String get quizTrainingStyleTrainingStyle => '훈련 스타일';

  @override
  String get quizTrainingStyleUpperLower => '상체 / 하체';

  @override
  String get quizTrainingStyleWorkoutType => '운동 유형';

  @override
  String racePredictorCardCouldNotLoadPredictions(Object message) {
    return '예측을 불러올 수 없습니다.\n$message';
  }

  @override
  String get racePredictorCardLogRun => '달리기 기록';

  @override
  String get racePredictorCardRacePredictor => '레이스 예측기';

  @override
  String get racePredictorCardRunAMeasuredKm => '첫 예측을 위해 1km 이상 측정된 거리를 달려보세요';

  @override
  String get racePredictorDetailAskCoach => '코치에게 물어보기';

  @override
  String get racePredictorDetailHowPredictionsAreCalculated => '예측 계산 방식';

  @override
  String get racePredictorDetailLogAtLeastThree =>
      '최소 3번의 달리기 기록(1km 측정 포함)을 입력하면 예측 결과가 나타납니다.';

  @override
  String get racePredictorDetailNeedMoreData => '데이터가 더 필요합니다';

  @override
  String get racePredictorDetailNoPredictionsYet => '아직 예측 결과가 없습니다';

  @override
  String get racePredictorDetailRacePredictor => '레이스 예측기';

  @override
  String racePredictorDetailScreenCouldNotLoadPredictions(Object e) {
    return '예측을 불러올 수 없습니다.\n$e';
  }

  @override
  String get racePredictorDetailYourBestRun => '최고의 달리기 기록';

  @override
  String get ratingPromptBannerGot30Seconds => '30초만 시간 내주실 수 있나요?';

  @override
  String get ratingPromptBannerHelpUsOutRate =>
      '도와주세요 — App Store에서 Zealova를 평가해주세요.';

  @override
  String get ratingPromptDonTAskAgain => '다시 묻지 않기';

  @override
  String get ratingPromptEnjoyingZealovaSoFar => 'Zealova를 잘 사용하고 계신가요?';

  @override
  String get ratingPromptLovingIt => '정말 좋아요';

  @override
  String get ratingPromptNotGreat => '별로예요';

  @override
  String get ratingPromptRemindMeLater => '나중에 알림';

  @override
  String get readinessCheckinCardEnergyFatigue => '에너지/피로도';

  @override
  String get readinessCheckinCardGotIt => '확인했어요!';

  @override
  String get readinessCheckinCardHowAreYouFeeling => '오늘 컨디션은 어떠신가요?';

  @override
  String get readinessCheckinCardMuscleSoreness => '근육통';

  @override
  String get readinessCheckinCardQuickCheckInHelps => '간편한 체크인으로 운동을 최적화하세요';

  @override
  String readinessCheckinCardReadiness(Object readinessScore) {
    return '준비 상태: $readinessScore';
  }

  @override
  String get readinessCheckinCardSleepQuality => '수면 품질';

  @override
  String get readinessCheckinCardStressLevel => '스트레스 수준';

  @override
  String get readinessCheckinCardSubmitCheckIn => '체크인 제출';

  @override
  String get readinessCheckinCardSubmitting => '제출 중...';

  @override
  String get readinessCheckinCardTodaySReadiness => '오늘의 준비 상태';

  @override
  String get readinessTileBuildingBaselineCheckIn =>
      '기준점 설정 중 — 14일 동안 매일 체크인하세요';

  @override
  String get readinessTileRecoveryReadiness => '회복 준비 상태';

  @override
  String get receiptTemplate => '─────────────────────────────';

  @override
  String get receiptTemplateNoExercisesLogged => '기록된 운동 없음';

  @override
  String receiptTemplateOrder(Object workoutName) {
    return '주문: $workoutName';
  }

  @override
  String get receiptTemplateThankYouComeAgain => '감사합니다 — 다음에 또 오세요';

  @override
  String receiptTemplateX(Object reps, Object sets) {
    return '${sets}x$reps';
  }

  @override
  String get recipeBuilderAddIngredient => '재료 추가';

  @override
  String get recipeBuilderCalculatePortionToLog => '기록할 분량 계산';

  @override
  String get recipeBuilderConverter => '변환기';

  @override
  String get recipeBuilderCookTime => '조리 시간';

  @override
  String get recipeBuilderDescriptionOptional => '설명 (선택 사항)';

  @override
  String get recipeBuilderEditRecipe => '레시피 편집';

  @override
  String get recipeBuilderIngredients => '재료';

  @override
  String get recipeBuilderInstructionsOptional => '조리 방법 (선택 사항)';

  @override
  String get recipeBuilderNoIngredientsYet => '아직 재료가 없습니다';

  @override
  String get recipeBuilderNutritionPerServing => '1회 제공량당 영양 성분';

  @override
  String get recipeBuilderPrepTime => '준비 시간';

  @override
  String get recipeBuilderServings => '제공량';

  @override
  String get recipeBuilderShareRecipe => '레시피 공유';

  @override
  String get recipeBuilderSheetAddIngredient => '재료 추가';

  @override
  String get recipeBuilderSheetAmount => '양';

  @override
  String get recipeBuilderSheetAnalyzing => '분석 중...';

  @override
  String get recipeBuilderSheetCalories => '칼로리';

  @override
  String get recipeBuilderSheetCarbs => '탄수화물';

  @override
  String get recipeBuilderSheetFat => '지방';

  @override
  String get recipeBuilderSheetFiber => '식이섬유';

  @override
  String recipeBuilderSheetG(Object inputGrams, Object result) {
    return '${inputGrams}g $result ';
  }

  @override
  String recipeBuilderSheetG2(Object foodName, Object outputGrams) {
    return '$foodName = ${outputGrams}g ';
  }

  @override
  String get recipeBuilderSheetIngredientName => '재료명';

  @override
  String recipeBuilderSheetItems(Object length) {
    return '항목 $length개';
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
    return '\"$recipeName\" $portionEaten인분 기록됨: ';
  }

  @override
  String get recipeBuilderSheetNutritionPerAmountAbove => '영양 성분 (위의 양 기준)';

  @override
  String recipeBuilderSheetPartIngredientEntryFailedToAnalyze(Object e) {
    return '분석 실패: $e';
  }

  @override
  String recipeBuilderSheetPartIngredientEntryG(Object value) {
    return '${value}g';
  }

  @override
  String get recipeBuilderSheetProtein => '단백질';

  @override
  String recipeBuilderSheetRecipeCreated(Object text) {
    return '\"$text\" 레시피가 생성되었습니다!';
  }

  @override
  String get recipeCardAi => 'AI';

  @override
  String get recipeCardCurated => '엄선된 레시피';

  @override
  String get recipeCardImported => '가져온 레시피';

  @override
  String get recipeCardImprovized => '즉석 레시피';

  @override
  String recipeCardKcal(Object caloriesPerServing) {
    return '$caloriesPerServing kcal';
  }

  @override
  String recipeCardValue(Object timesLogged) {
    return '×$timesLogged';
  }

  @override
  String get recipeCreateAddPhotoOptional => '사진 추가 (선택 사항)';

  @override
  String get recipeCreateChooseFromGallery => '갤러리에서 선택';

  @override
  String get recipeCreateCustom => '+ 사용자 지정';

  @override
  String get recipeCreateCustomCategory => '사용자 지정 카테고리';

  @override
  String get recipeCreateEG4Oz => '예: 4oz 구운 닭가슴살';

  @override
  String get recipeCreateEGPostWorkout => '예: 운동 후, 준비, 스무디';

  @override
  String get recipeCreateEditCustom => '✏️ 사용자 지정 편집';

  @override
  String get recipeCreateNewRecipe => '새 레시피';

  @override
  String get recipeCreateNone => '없음';

  @override
  String get recipeCreatePerServing => '1회 제공량당';

  @override
  String get recipeCreateRecipeNameRequired => '레시피 이름 필수';

  @override
  String get recipeCreateRemovePhoto => '사진 제거';

  @override
  String get recipeCreateSaving => '저장 중...';

  @override
  String recipeCreateScreenValue2(Object selected) {
    return '✨ $selected';
  }

  @override
  String get recipeCreateTakePhoto => '사진 촬영';

  @override
  String get recipeCreateTapToEdit => '탭하여 편집';

  @override
  String get recipeDetailAddToPlan => '계획에 추가';

  @override
  String get recipeDetailAddedToFavorites => '즐겨찾기에 추가됨';

  @override
  String get recipeDetailCoachReview => '코치 검토';

  @override
  String get recipeDetailDeleteRecipe => '레시피를 삭제할까요?';

  @override
  String get recipeDetailFavorite => '즐겨찾기';

  @override
  String get recipeDetailFavorited => '즐겨찾기됨';

  @override
  String get recipeDetailGroceryList => '장보기 목록';

  @override
  String get recipeDetailImprovize => '즉석 레시피 만들기';

  @override
  String get recipeDetailImprovizedEditAndSave => '즉석 레시피입니다! 버전을 편집하고 저장하세요.';

  @override
  String get recipeDetailImprovizing => '즉석 레시피 생성 중...';

  @override
  String get recipeDetailIngredients => '재료';

  @override
  String get recipeDetailInstructions => '조리 방법';

  @override
  String get recipeDetailLog => '기록';

  @override
  String get recipeDetailLogged1ServingAs => '1회 제공량을 점심으로 기록함';

  @override
  String get recipeDetailNoIngredients => '재료 없음';

  @override
  String get recipeDetailRecipeDeleted => '레시피가 삭제되었습니다';

  @override
  String get recipeDetailRemovedFromFavorites => '즐겨찾기에서 제거됨';

  @override
  String get recipeDetailSchedule => '일정';

  @override
  String recipeDetailScreenGroceryListCreatedItems(Object length) {
    return '장보기 목록 생성됨 ($length개 항목)';
  }

  @override
  String recipeDetailScreenKcal(Object i) {
    return '$i kcal';
  }

  @override
  String recipeDetailScreenPerServingUD(Object servings) {
    return '1회 제공량당 (×$servings인분)';
  }

  @override
  String recipeDetailScreenUForkedFrom(Object sourceName) {
    return '✨ $sourceName에서 포크됨';
  }

  @override
  String recipeDetailScreenWillBePermanentlyRemoved(Object name) {
    return '\"$name\"이(가) 영구적으로 삭제됩니다.';
  }

  @override
  String get recipeDetailUd83cUdf1fCuratedRecipe => '🌟 엄선된 레시피';

  @override
  String get recipeDetailView => '보기';

  @override
  String get recipeFilterSortApply => '적용';

  @override
  String get recipeFilterSortClearAll => '모두 지우기';

  @override
  String get recipeFilterSortFavoritesOnly => '⭐ 즐겨찾기만';

  @override
  String get recipeFilterSortFilters => '필터';

  @override
  String get recipeFilterSortHasLeftoversOnly => '🍱 남은 음식만';

  @override
  String get recipeFilterSortMealType => '식사 유형';

  @override
  String get recipeFilterSortOther => '기타';

  @override
  String get recipeFilterSortSource => '출처';

  @override
  String get recipeFromFridgeAdd => '추가';

  @override
  String get recipeFromFridgeChooseFromGallery => '갤러리에서 선택';

  @override
  String get recipeFromFridgeFindRecipes => '레시피 찾기';

  @override
  String get recipeFromFridgeFindingRecipesU2026 => '레시피 찾는 중…';

  @override
  String get recipeFromFridgeFoundInYourPhoto => '사진에서 발견됨';

  @override
  String get recipeFromFridgeFromYourFridge => '냉장고 속 재료';

  @override
  String get recipeFromFridgeNoRecipesFoundFor =>
      '해당 재료로 찾은 레시피가 없습니다. 재료를 더 추가해 보세요.';

  @override
  String get recipeFromFridgeScanComplete => '스캔 완료';

  @override
  String recipeFromFridgeScreenKcalServ(Object caloriesPerServing) {
    return '$caloriesPerServing kcal/인분';
  }

  @override
  String recipeFromFridgeScreenMatch(Object overallMatchScore) {
    return '$overallMatchScore% 일치';
  }

  @override
  String recipeFromFridgeScreenNeed(Object missingIngredients) {
    return '필요: $missingIngredients';
  }

  @override
  String recipeFromFridgeScreenScanningU(Object done, Object total) {
    return '$done/$total 스캔 중...';
  }

  @override
  String recipeFromFridgeScreenUGP(Object suggestion) {
    return '• ${suggestion}g 단백질';
  }

  @override
  String recipeFromFridgeScreenUses(Object matchedPantryItems) {
    return '사용: $matchedPantryItems';
  }

  @override
  String get recipeFromFridgeSnapFridgePhoto => '냉장고 사진 찍기';

  @override
  String get recipeFromFridgeSuggestions => '추천';

  @override
  String get recipeFromFridgeTapFindRecipesTo =>
      '\"레시피 찾기\"를 눌러 재료를 활용한 추천 레시피를 확인하세요';

  @override
  String get recipeFromFridgeTypeIngredientEggsSpinach => '재료 입력 (계란, 시금치 등…)';

  @override
  String get recipeFromFridgeTypeIngredientsOrSnap => '재료를 입력하거나 사진을 찍으세요';

  @override
  String get recipeHistoryCompare => '비교';

  @override
  String get recipeHistoryNoDifferences => '차이 없음';

  @override
  String get recipeHistoryNoEditsYetVersioning =>
      '아직 수정 내역이 없습니다. 첫 변경 후 버전 관리가 시작됩니다.';

  @override
  String get recipeHistoryNowPickASecond => '이제 두 번째 버전을 선택하세요';

  @override
  String get recipeHistoryRevert => '되돌리기';

  @override
  String get recipeHistoryRevertToThisVersion => '이 버전으로 되돌릴까요?';

  @override
  String recipeHistoryScreenScheduleSNowUse(Object schedulesUsingRecipeCount) {
    return '$schedulesUsingRecipeCount개의 스케줄이 현재 되돌린 버전을 사용 중입니다.';
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
  String get recipeHistoryUpdated => '업데이트됨';

  @override
  String get recipeImportAimAtARecipe =>
      '레시피 카드, 요리책 페이지 또는 스크린샷을 향해 조준하세요. 프레임에 맞춰 흔들리지 않게 고정하세요.';

  @override
  String get recipeImportAlignRecipeInsideFrame => '프레임 안에 레시피 맞추기';

  @override
  String get recipeImportChooseFromGalleryInstead => '대신 갤러리에서 선택';

  @override
  String get recipeImportFailed => '실패';

  @override
  String get recipeImportImportFromUrl => 'URL에서 가져오기';

  @override
  String get recipeImportImportRecipe => '레시피 가져오기';

  @override
  String get recipeImportParseText => '텍스트 분석';

  @override
  String get recipeImportPasteARecipeTitle => '레시피 붙여넣기 (제목, 재료, 단계)…';

  @override
  String get recipeImportPhoto => '사진';

  @override
  String get recipeImportReviewSave => '검토 및 저장';

  @override
  String recipeImportScreenConfidence(Object confidence) {
    return '신뢰도: $confidence%';
  }

  @override
  String get recipeImportTapTheLargeWhite => '아래의 큰 흰색 원을 눌러 촬영하세요';

  @override
  String get recipeImportText => '텍스트';

  @override
  String get recipePreferencesPreferencesSaved => '환경설정이 저장되었습니다!';

  @override
  String get recipePreferencesRecipePreferences => '레시피 환경설정';

  @override
  String get recipePreferencesSelectCuisinesYouEnjoy => '좋아하는 요리 선택 (탭하여 전환)';

  @override
  String get recipePreferencesYourBodyTypeHelps =>
      '체형 정보를 바탕으로 신진대사에 최적화된 레시피를 추천해 드립니다';

  @override
  String recipeSaveJobsListenerCouldnTSaveRecipe(Object job) {
    return '레시피를 저장할 수 없습니다: $job';
  }

  @override
  String recipeSaveJobsListenerCouldnTSchedule(Object job, Object mealName) {
    return '\'$mealName\' 일정을 예약할 수 없습니다: $job';
  }

  @override
  String recipeSaveJobsListenerIsAlreadyInYour(Object mealName) {
    return '\'$mealName\'은(는) 이미 내 레시피에 있습니다';
  }

  @override
  String recipeSaveJobsListenerNextAt(Object cadenceLabel, Object fmt) {
    return '$cadenceLabel — 다음 예정: $fmt';
  }

  @override
  String recipeSaveJobsListenerSavedToYourRecipes(Object mealName) {
    return '\'$mealName\'이(가) 내 레시피에 저장되었습니다';
  }

  @override
  String get recipeSaveJobsView => '보기';

  @override
  String get recipeScheduleAddASlotFor => '먹을 계획인 각 분량에 대해 슬롯을 추가하세요';

  @override
  String get recipeScheduleAddSlot => '슬롯 추가';

  @override
  String get recipeScheduleBatchCookOnce => '대량 조리 (한 번 조리)';

  @override
  String get recipeScheduleCounter1d => '실온 (1일)';

  @override
  String get recipeScheduleFreezer30d => '냉동 (30일)';

  @override
  String get recipeScheduleFridge3d => '냉장 (3일)';

  @override
  String get recipeScheduleRecurring => '반복';

  @override
  String get recipeScheduleSaving => '저장 중…';

  @override
  String get recipeScheduleSchedule => '일정';

  @override
  String recipeScheduleScreenSlots(Object _batchSlots, Object _portionsMade) {
    return '슬롯: $_batchSlots / $_portionsMade';
  }

  @override
  String recipeScheduleScreenValue(Object servings) {
    return '×$servings';
  }

  @override
  String get recipeScheduleSilentAutoLogAdvanced => '자동 기록 (고급)';

  @override
  String get recipeSearchBarRecentSearches => '최근 검색';

  @override
  String get recipeSearchBarSearchYourRecipesIngredien => '레시피, 재료, 태그 검색…';

  @override
  String get recipeShareCopiedToClipboard => '클립보드에 복사됨';

  @override
  String get recipeShareGenerateShareLink => '공유 링크 생성';

  @override
  String get recipeShareRecipeIsPublic => '공개된 레시피';

  @override
  String get recipeShareSharePublicly => '공개적으로 공유';

  @override
  String recipeShareSheetAnyoneWithTheLink(Object saveCount, Object viewCount) {
    return '링크가 있는 누구나 볼 수 있습니다. 라이브러리 저장: $saveCount · 조회수: $viewCount';
  }

  @override
  String get recipeShareStopSharing => '공유 중단';

  @override
  String recipeSuggestionCardCal(Object calories) {
    return '$calories cal';
  }

  @override
  String get recipeSuggestionCardCookAgain => '다시 요리하기';

  @override
  String get recipeSuggestionCardIMadeThis => '직접 요리함';

  @override
  String get recipeSuggestionCardIngredients => '재료';

  @override
  String get recipeSuggestionCardInstructions => '조리 방법';

  @override
  String get recipeSuggestionCardMatchAnalysis => '일치 분석';

  @override
  String get recipeSuggestionCardRateThisRecipe => '레시피 평가하기';

  @override
  String get recipeSuggestionCardSaveRecipe => '레시피 저장';

  @override
  String get recipeSuggestionCardSaved => '저장됨';

  @override
  String recipeSuggestionCardServings(Object servings) {
    return '$servings인분';
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
      '특별한 요구사항이 있나요? (예: 400칼로리 미만, 고식이섬유)';

  @override
  String get recipeSuggestionsGenerateSuggestions => '추천 생성';

  @override
  String get recipeSuggestionsGenerating => '생성 중...';

  @override
  String get recipeSuggestionsMarkedAsCooked => '요리 완료로 표시됨!';

  @override
  String get recipeSuggestionsNoSavedRecipes => '저장된 레시피 없음';

  @override
  String get recipeSuggestionsNoSuggestionsYet => '아직 추천 없음';

  @override
  String get recipeSuggestionsRecipeSuggestions => '레시피 추천';

  @override
  String get recipeSuggestionsSaveRecipesYouLike =>
      '좋아하는 레시피를 저장하면 나중에 여기서 확인할 수 있습니다';

  @override
  String get recipeSuggestionsSaved => '저장됨';

  @override
  String recipeSuggestionsScreenRecipeSavedXpFirst(Object xpAwarded) {
    return '레시피 저장 완료! 첫 레시피 보너스로 $xpAwarded XP 획득!';
  }

  @override
  String get recipeSuggestionsSuggestions => '추천';

  @override
  String get recipeSuggestionsTapGenerateSuggestionsTo =>
      '\"추천 생성\"을 탭하여 선호도에 기반한 AI 레시피 아이디어를 확인하세요.';

  @override
  String get recipeSuggestionsWhatMealAreYou => '어떤 식사를 계획 중이신가요?';

  @override
  String get recipesBuild => '만들기';

  @override
  String get recipesChooseFromGallery => '갤러리에서 선택';

  @override
  String get recipesComingUpToday => '오늘 예정된 식사';

  @override
  String get recipesCookedDish => '조리된 요리';

  @override
  String get recipesDeleteRecipe => '레시피를 삭제할까요?';

  @override
  String get recipesExpired => '만료됨';

  @override
  String get recipesFavorites => '즐겨찾기';

  @override
  String get recipesFavorites2 => '⭐ 즐겨찾기';

  @override
  String get recipesFilters => '필터';

  @override
  String get recipesFridge => '냉장고';

  @override
  String get recipesHasLeftovers => '🍱 남은 음식 있음';

  @override
  String get recipesImport => '가져오기';

  @override
  String get recipesLeftovers => '남은 음식';

  @override
  String get recipesLists => '목록';

  @override
  String get recipesMultiSelectSupported => '다중 선택 지원';

  @override
  String get recipesNoRecipesYet => '아직 레시피가 없습니다';

  @override
  String get recipesOpen => '열기';

  @override
  String get recipesPlanDay => '하루 계획하기';

  @override
  String get recipesRecipeDeleted => '레시피가 삭제되었습니다';

  @override
  String get recipesScanYourFridge => '냉장고 스캔';

  @override
  String get recipesScheduledMeal => '예정된 식사';

  @override
  String get recipesSortRecipes => '레시피 정렬';

  @override
  String recipesTabAreYouSureYou(Object name) {
    return '\"$name\"을(를) 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String recipesTabCouldnTLoadRecipes(Object message) {
    return '레시피를 불러올 수 없습니다: $message';
  }

  @override
  String recipesTabOfLeft(Object portionsMade, Object portionsRemaining) {
    return '$portionsMade개 중 $portionsRemaining개 남음';
  }

  @override
  String recipesTabServing(Object servings) {
    return '$servings 인분';
  }

  @override
  String recipesTabValue(Object timeLabel, Object value) {
    return '$timeLabel · $value';
  }

  @override
  String get recipesTakePhoto => '사진 촬영';

  @override
  String get recipesTapBuildToCreate =>
      '만들기를 탭하여 첫 번째 레시피를 생성하거나, 위의 냉장고/가져오기 기능을 사용해 보세요.';

  @override
  String get recipesUpTo5Photos => '최대 5장의 사진 — 냉장고, 식료품 저장소, 냉동실';

  @override
  String get recommendationExplainGotIt => '확인';

  @override
  String recommendationExplainSheetRankOf(Object rank, Object totalAccepted) {
    return '$totalAccepted개 중 $rank위';
  }

  @override
  String recommendationExplainSheetWhy(Object name) {
    return '왜 $name인가요?';
  }

  @override
  String get recordAssessmentAnyNotesAboutThis => '이 평가에 대한 메모...';

  @override
  String get recordAssessmentEnterMeasurement => '측정값 입력';

  @override
  String get recordAssessmentNotesOptional => '메모 (선택 사항)';

  @override
  String get recordAssessmentQuickInstructions => '간단한 지침';

  @override
  String get recordAssessmentRecordAssessment => '평가 기록';

  @override
  String recordAssessmentSheetTop(Object assessment) {
    return '상위 $assessment%';
  }

  @override
  String get recordAssessmentTips => '팁';

  @override
  String get recordAssessmentU2022 => '• ';

  @override
  String get recordAssessmentYourMeasurement => '내 측정값';

  @override
  String get recordAttemptCurrentBest => '현재 최고 기록';

  @override
  String recordAttemptDialogAdd(Object unit) {
    return '$unit 추가';
  }

  @override
  String recordAttemptDialogAdd2(Object unit) {
    return '$unit 추가';
  }

  @override
  String recordAttemptDialogCompleted(Object unit) {
    return '$unit 완료';
  }

  @override
  String recordAttemptDialogToAdd(Object unit) {
    return '추가할 $unit';
  }

  @override
  String get recordAttemptHowDidItFeel => '느낌이 어땠나요?';

  @override
  String get recordAttemptNotesOptional => '메모 (선택 사항)';

  @override
  String get recordAttemptPersonalBest => '개인 최고 기록';

  @override
  String get recordAttemptPleaseEnterAValid => '유효한 숫자를 입력하세요';

  @override
  String get recordAttemptRecordAttempt => '기록 저장';

  @override
  String get recordAttemptTotalSoFar => '현재까지 총합';

  @override
  String get recordsCardBestPr => '최고 PR';

  @override
  String get recordsCardPersonalRecords => '개인 기록';

  @override
  String get recovery1rmCalculatorPlayground => '1RM 계산기';

  @override
  String get recoveryColorCodedRed40 =>
      '색상 코드: 빨간색 <40% | 노란색 40-70% | 녹색 >70%';

  @override
  String get recoveryCompareEpleyBrzyckiAnd => 'Epley, Brzycki, Mayhew 추정치 비교';

  @override
  String get recoveryLabel => '회복';

  @override
  String get recoveryPerMuscleExponentialDecay => '근육별 지수 감쇠율 (k 값)';

  @override
  String get recoveryPerMuscleRecoveryGrid => '근육별 회복 그리드';

  @override
  String recoveryPillsRowValue(Object scorePct) {
    return '$scorePct%';
  }

  @override
  String get recoveryRecoveryConstantsEditor => '회복 상수 편집기';

  @override
  String get recoveryReps => '횟수';

  @override
  String get recoveryReset => '초기화';

  @override
  String recoverySectionKg(Object value) {
    return '$value kg';
  }

  @override
  String recoverySectionValue(Object score) {
    return '$score%';
  }

  @override
  String get recoveryWeightKg => '무게 (kg)';

  @override
  String get referralsAbc123 => 'ABC123';

  @override
  String get referralsAllRewardTiers => '모든 보상 등급';

  @override
  String get referralsApplyCode => '코드 적용';

  @override
  String get referralsApplying => '적용 중...';

  @override
  String get referralsCodeCopied => '코드가 복사되었습니다!';

  @override
  String get referralsFailedToLoadReferrals => '추천 정보를 불러오지 못했습니다';

  @override
  String get referralsHaveACodeFrom => '친구에게 받은 코드가 있나요?';

  @override
  String get referralsHowItWorks => '작동 방식';

  @override
  String get referralsInviteFriends => '친구 초대';

  @override
  String get referralsMaxTierReached => '최대 등급 도달';

  @override
  String get referralsPending => '대기 중';

  @override
  String get referralsQualified => '자격 충족';

  @override
  String get referralsRedeemItHereBoth =>
      '여기서 코드를 입력하세요. 두 분 모두 XP와 상자를 받을 수 있습니다.';

  @override
  String referralsScreenMoreQualifiedReferral(Object neededForNext) {
    return '유효한 추천 $neededForNext명 더 필요';
  }

  @override
  String referralsScreenNextFree(Object nextMerchDisplayName) {
    return '다음: 무료 $nextMerchDisplayName';
  }

  @override
  String referralsScreenQualifiedReferrals(Object threshold) {
    return '유효한 추천 $threshold명';
  }

  @override
  String referralsScreenToUnlock(Object summary) {
    return '잠금 해제까지 $summary';
  }

  @override
  String get referralsYouVeUnlockedEvery => '모든 추천 보상을 잠금 해제했습니다. 전설적이네요.';

  @override
  String get referralsYourReferralCode => '내 추천 코드';

  @override
  String get refuelWindowCardAskCoachAboutRecovery =>
      '회복을 위한 영양 섭취에 대해 코치에게 물어보세요';

  @override
  String get refuelWindowCardCarbs => '탄수화물';

  @override
  String get refuelWindowCardLogMeal => '식사 기록';

  @override
  String get refuelWindowCardProtein => '단백질';

  @override
  String get refuelWindowCardRecoveryWindow => '🥤 회복 골든타임';

  @override
  String get refuelWindowCardWater => '수분';

  @override
  String get regenerateSheetAddingVariety => '다양성 추가 중';

  @override
  String get regenerateSheetAiGenerationTakes => 'AI 생성에는 보통 15~30초가 소요됩니다';

  @override
  String get regenerateSheetAiSuggestions => 'AI 추천';

  @override
  String get regenerateSheetAlmostThere => '거의 다 되었습니다…';

  @override
  String get regenerateSheetAnalyzingYourPreferences => '사용자 선호도 분석 중…';

  @override
  String get regenerateSheetApply => '적용';

  @override
  String get regenerateSheetApplyThisWorkout => '이 운동 적용하기';

  @override
  String get regenerateSheetBalancingMuscleGroups => '근육 그룹 균형 맞추는 중';

  @override
  String get regenerateSheetBootingUpTheAi => 'AI 시작 중';

  @override
  String get regenerateSheetBuildingYourPlan => '플랜 구성 중';

  @override
  String get regenerateSheetBuildingYourWorkout => '운동 구성 중…';

  @override
  String get regenerateSheetCheckingEquipment => '장비 확인 중';

  @override
  String get regenerateSheetCheckingPreferences => '환경 설정 확인 중';

  @override
  String get regenerateSheetConnectingToTheAi => 'AI에 연결 중';

  @override
  String get regenerateSheetConsideringFocusAreas => '집중 부위 고려 중';

  @override
  String get regenerateSheetCustomize => '사용자 지정';

  @override
  String get regenerateSheetCustomizeOrLetAi => '직접 지정하거나 AI에게 추천받으세요';

  @override
  String get regenerateSheetCustomizeOrLetAiSuggest => '직접 설정하거나 AI에 맡기기';

  @override
  String get regenerateSheetDescribeYourIdealWorkout => '이상적인 운동을 설명해주세요';

  @override
  String get regenerateSheetDesigningYourWorkout => '운동 설계 중';

  @override
  String get regenerateSheetDialingInSetsAndReps => '세트 및 횟수 조정 중';

  @override
  String get regenerateSheetDoThisToday => '오늘 수행';

  @override
  String get regenerateSheetEnterAPrompt => '프롬프트 입력';

  @override
  String get regenerateSheetEnterAPromptAbove => '위에서 프롬프트를 입력하세요…';

  @override
  String get regenerateSheetFilteringByEquipment => '장비 필터링 중';

  @override
  String get regenerateSheetFilteringByYourEquipment => '보유 장비로 필터링 중';

  @override
  String get regenerateSheetFinalizingDetails => '세부 사항 마무리 중…';

  @override
  String get regenerateSheetFinalizingYourWorkout => '운동 마무리 중';

  @override
  String get regenerateSheetFineTuningTheDetails => '세부 사항 조정 중';

  @override
  String regenerateSheetGeneratingElapsed(Object arg0) {
    return '생성 중… $arg0';
  }

  @override
  String get regenerateSheetGeneratingSuggestions => '추천 생성 중…';

  @override
  String get regenerateSheetGetSuggestions => '추천 받기';

  @override
  String get regenerateSheetGettingCreative => '창의적인 구성 중';

  @override
  String get regenerateSheetGettingReady => '준비 중';

  @override
  String get regenerateSheetHoldingYourSchedule => '일정 유지 중';

  @override
  String get regenerateSheetKeepCurrent => '현재 상태 유지';

  @override
  String regenerateSheetKeepDate(Object day, Object month, Object weekday) {
    return '$month월 $day일 $weekday 유지';
  }

  @override
  String get regenerateSheetLoadingInjuriesAndGoals => '부상 및 목표 불러오는 중';

  @override
  String get regenerateSheetLoadingPreferences => '환경 설정 불러오는 중';

  @override
  String get regenerateSheetLoadingYourProfile => '프로필 불러오는 중';

  @override
  String get regenerateSheetMatchingIntensity => '강도 맞추는 중';

  @override
  String get regenerateSheetMatchingYourFitnessLevel => '피트니스 레벨 맞추는 중';

  @override
  String get regenerateSheetNoSuggestionsYet => '아직 추천 없음';

  @override
  String get regenerateSheetOptimizingForYourGoals => '목표에 맞게 최적화 중';

  @override
  String get regenerateSheetPairingPushAndPull => '밀기 및 당기기 조합 중';

  @override
  String get regenerateSheetPersonalizingExercises => '운동 개인화 중';

  @override
  String get regenerateSheetPickingYourExercises => '운동 선택 중';

  @override
  String get regenerateSheetPreparingYourRequest => '요청 준비 중';

  @override
  String get regenerateSheetPrimingTheEngine => '엔진 예열 중';

  @override
  String get regenerateSheetPullingYourGoals => '목표 불러오는 중';

  @override
  String get regenerateSheetReadingYourProfile => '프로필 읽는 중';

  @override
  String get regenerateSheetRegenerateCurrentWorkout => '현재 운동 재생성';

  @override
  String get regenerateSheetRegenerateWorkout => '운동 재생성';

  @override
  String get regenerateSheetRegenerationComplete => '재생성 완료!';

  @override
  String get regenerateSheetReset => '재설정';

  @override
  String get regenerateSheetRespectingYourInjuryList => '부상 목록 반영 중';

  @override
  String get regenerateSheetRestoredFromLastRegen => '마지막 재생성에서 복구됨';

  @override
  String get regenerateSheetRestoredFromLastRegeneration => '마지막 재생성 상태로 복구됨';

  @override
  String get regenerateSheetSavingToYourPlan => '플랜에 저장 중';

  @override
  String get regenerateSheetScanningTheExerciseLibrary => '운동 라이브러리 스캔 중';

  @override
  String get regenerateSheetSchedulingYourWorkout => '운동 일정 잡는 중';

  @override
  String get regenerateSheetSequencingCompoundLifts => '복합 관절 운동 순서 정하는 중';

  @override
  String get regenerateSheetShapingTheSession => '세션 구성 중';

  @override
  String get regenerateSheetStartingRegeneration => '재생성 시작 중…';

  @override
  String regenerateSheetStepOf(Object current, Object total) {
    return '$current / $total 단계';
  }

  @override
  String get regenerateSheetTodayNotInSchedule => '오늘은 평소 운동하는 날이 아닙니다';

  @override
  String get regenerateSheetTodayNotInUsualDays => '오늘은 평소 운동 요일이 아님';

  @override
  String get regenerateSheetTuningRestPeriods => '휴식 시간 조정 중';

  @override
  String get regenerateSheetUpdatingYourSchedule => '일정 업데이트 중';

  @override
  String get regenerateSheetUseThisSuggestion => '이 제안 사용';

  @override
  String get regenerateSheetWarmingUp => '웜업 중';

  @override
  String get regenerateSheetWhen => '언제?';

  @override
  String get regenerateWithNewContinueCurrent => '현재 유지';

  @override
  String get regenerateWithNewEitherWayFutureWorkouts =>
      '어느 쪽이든, 향후 운동은 업데이트된 장비를 기준으로 생성됩니다.';

  @override
  String get regenerateWithNewEquipmentUpdated => '장비 업데이트 완료';

  @override
  String get regenerateWithNewRegenerateThisWorkout => '이 운동 다시 생성';

  @override
  String get regenerateWorkoutSheetAiGenerationTypicallyTakes =>
      'AI 생성에는 보통 15-30초가 소요됩니다';

  @override
  String get regenerateWorkoutSheetAiSuggestions => 'AI 추천';

  @override
  String get regenerateWorkoutSheetApplyThisWorkout => '이 운동 적용하기';

  @override
  String get regenerateWorkoutSheetCouldnTKeepYour =>
      '기존 운동을 유지할 수 없습니다. 새 운동만 표시됩니다.';

  @override
  String get regenerateWorkoutSheetCustomize => '사용자 지정';

  @override
  String get regenerateWorkoutSheetCustomizeOrLetAi => '사용자 지정하거나 AI에게 추천받으세요';

  @override
  String get regenerateWorkoutSheetDefaultedToReplaceYour =>
      '대체로 설정되었습니다. 이전 운동이 덮어쓰기되었습니다.';

  @override
  String get regenerateWorkoutSheetDescribeYourIdealWorkout =>
      '이상적인 운동을 설명해주세요';

  @override
  String get regenerateWorkoutSheetDoThisToday => '오늘 이 운동 하기';

  @override
  String get regenerateWorkoutSheetEGAQuick => '예: \"장비 없이 하는 빠른 상체 운동\"';

  @override
  String get regenerateWorkoutSheetEnterAPromptAbove =>
      '위 프롬프트를 입력하거나 새로고침을 눌러 AI 기반 운동 추천을 받으세요';

  @override
  String get regenerateWorkoutSheetGeneratingSuggestions => '추천 생성 중...';

  @override
  String get regenerateWorkoutSheetGetSuggestions => '추천 받기';

  @override
  String get regenerateWorkoutSheetNoSuggestionsYet => '아직 추천이 없습니다';

  @override
  String
  regenerateWorkoutSheetPartRegenerateWorkoutSheetStateExtFailedToApplySuggestion(
    Object message,
  ) {
    return '제안 적용 실패: $message';
  }

  @override
  String
  regenerateWorkoutSheetPartRegenerateWorkoutSheetStateExtFailedToApplySuggestion2(
    Object e,
  ) {
    return '제안 적용 실패: $e';
  }

  @override
  String
  regenerateWorkoutSheetPartRegenerateWorkoutSheetStateExtFailedToRegenerate(
    Object message,
  ) {
    return '재생성 실패: $message';
  }

  @override
  String
  regenerateWorkoutSheetPartRegenerateWorkoutSheetStateExtFailedToRegenerate2(
    Object e,
  ) {
    return '재생성 실패: $e';
  }

  @override
  String get regenerateWorkoutSheetPreviewNotSupportedBy =>
      '서버에서 미리보기를 지원하지 않습니다. 앱을 업데이트하거나 고객 지원에 문의하세요.';

  @override
  String get regenerateWorkoutSheetRegenerateCurrentWorkout => '현재 운동 다시 생성';

  @override
  String get regenerateWorkoutSheetRegenerateWorkout => '운동 다시 생성';

  @override
  String get regenerateWorkoutSheetReset => '재설정';

  @override
  String get regenerateWorkoutSheetRestoredFromYourLast => '마지막 생성 시점으로 복원됨';

  @override
  String get regenerateWorkoutSheetTodayIsnTIn =>
      '오늘은 평소 운동하는 날이 아니지만, 그래도 추가하겠습니다.';

  @override
  String get regenerateWorkoutSheetWhen => '언제?';

  @override
  String get regionVariantDropdownCouldNotSwapVariant =>
      '변형을 교체할 수 없습니다. 다시 시도해주세요.';

  @override
  String regionVariantDropdownKcalG(Object v) {
    return '$v kcal/100g';
  }

  @override
  String get regionVariantDropdownRegion => '지역';

  @override
  String get renewalReminderBannerDismiss => '닫기';

  @override
  String get renewalReminderBannerManage => '관리';

  @override
  String renewalReminderBannerRenewsOn(Object formattedRenewalDate) {
    return '$formattedRenewalDate에 갱신';
  }

  @override
  String get repPreferencesAvoidHighRepSets => '고반복 세트 피하기';

  @override
  String get repPreferencesChooseYourPrimaryTraining => '주요 훈련 목표를 선택하세요';

  @override
  String get repPreferencesConfigureYourSetVolume => '세트 볼륨 구성';

  @override
  String get repPreferencesEnforceRepCeiling => '반복 횟수 상한 적용';

  @override
  String get repPreferencesHowShouldWeProgress => '운동 강도를 어떻게 높일까요?';

  @override
  String get repPreferencesPreventBoring15Rep => '지루한 15회 이상 반복 세트 방지';

  @override
  String get repPreferencesProgressionStyle => '점진적 과부하 방식';

  @override
  String get repPreferencesRepProgressionPreferences => '반복 횟수 및 점진적 과부하 설정';

  @override
  String get repPreferencesRepRange => '반복 횟수 범위';

  @override
  String get repPreferencesSectionConfigureYourSetVolume =>
      '각 운동의 세트 볼륨을 구성하세요';

  @override
  String get repPreferencesSectionEndurance1520 => '지구력 (15-20)';

  @override
  String get repPreferencesSectionHighVolume36 => '고볼륨 (3-6)';

  @override
  String get repPreferencesSectionHypertrophy812 => '근비대 (8-12)';

  @override
  String get repPreferencesSectionMax => '최대';

  @override
  String get repPreferencesSectionMaxSets => '최대 세트 수';

  @override
  String get repPreferencesSectionMaximumNumberOfSets => '각 운동당 최대 세트 수';

  @override
  String get repPreferencesSectionMin => '최소';

  @override
  String get repPreferencesSectionMinSets => '최소 세트 수';

  @override
  String get repPreferencesSectionMinimal12 => '최소 (1-2)';

  @override
  String get repPreferencesSectionMinimumSetsToEnsure =>
      '적절한 볼륨을 보장하기 위한 최소 세트 수';

  @override
  String repPreferencesSectionPartTrainingFocusOptionTileMaximumSets(
    Object maxSets,
  ) {
    return '최대 세트: $maxSets';
  }

  @override
  String repPreferencesSectionPartTrainingFocusOptionTileMinimumSets(
    Object minSets,
  ) {
    return '최소 세트: $minSets';
  }

  @override
  String get repPreferencesSectionRecommended => '권장';

  @override
  String get repPreferencesSectionRepRangePreference => '반복 횟수 범위 선호도';

  @override
  String get repPreferencesSectionSetYourPreferredReps =>
      '선호하는 세트당 반복 횟수를 설정하세요';

  @override
  String get repPreferencesSectionSetsPerExercise => '운동당 세트 수';

  @override
  String get repPreferencesSectionStandard24 => '표준 (2-4)';

  @override
  String get repPreferencesSectionStrength15 => '근력 (1-5)';

  @override
  String get repPreferencesSectionTheAiWillGenerate =>
      'AI가 이 세트 범위 내에서 운동을 생성합니다. 세트가 많을수록 볼륨이 커지고 근육 자극이 강해집니다.';

  @override
  String get repPreferencesSectionTheAiWillTry =>
      'AI는 중량을 조정하거나 점진적 과부하를 제안하여 운동을 이 범위 내로 유지하려고 합니다.';

  @override
  String get repPreferencesSetsPerExercise => '운동당 세트 수';

  @override
  String get repPreferencesStrictlyEnforceYourMaximum => '최대 반복 횟수 제한을 엄격히 적용';

  @override
  String get repPreferencesTrainingFocus => '훈련 초점';

  @override
  String get repPreferencesYourPreferredRepsPer => '선호하는 세트당 반복 횟수';

  @override
  String get repProgressionCardFineTuneRepRanges =>
      '반복 횟수 범위 및 점진적 과부하 방식 미세 조정';

  @override
  String get repProgressionCardRepProgression => '반복 횟수 및 점진적 과부하';

  @override
  String repProgressionCardReps(
    Object preferredMaxReps,
    Object preferredMinReps,
  ) {
    return '$preferredMinReps-$preferredMaxReps회';
  }

  @override
  String get reportInjuryAdditionalNotesOptional => '추가 참고 사항 (선택 사항)';

  @override
  String get reportInjuryCurrentPainLevel => '현재 통증 수준';

  @override
  String get reportInjuryDescribeHowTheInjury => '부상이 어떻게 발생했는지, 증상 등을 설명해주세요.';

  @override
  String get reportInjuryInjuryReportedSuccessfully => '부상 보고가 완료되었습니다';

  @override
  String get reportInjuryInjuryTypeOptional => '부상 유형 (선택 사항)';

  @override
  String get reportInjuryNoPain => '통증 없음';

  @override
  String get reportInjuryNotSure => '확실하지 않음';

  @override
  String get reportInjuryPleaseSelectABody => '신체 부위를 선택해주세요';

  @override
  String get reportInjuryReportInjury => '부상 보고';

  @override
  String reportInjuryScreenFailedToReportInjury(Object e) {
    return '부상 보고 실패: $e';
  }

  @override
  String get reportInjurySelectInjuryType => '부상 유형 선택';

  @override
  String get reportInjurySeverity => '심각도';

  @override
  String get reportInjuryThisIsForTracking =>
      '이 정보는 추적 목적으로만 사용됩니다. 정확한 진단과 치료를 위해 의료 전문가와 상담하세요.';

  @override
  String get reportInjuryWhenDidItOccur => '언제 발생했나요?';

  @override
  String get reportMessageAdditionalDetailsOptional => '추가 세부 정보 (선택 사항)';

  @override
  String get reportMessageHelpUsImproveOur => 'AI 코치 개선을 도와주세요';

  @override
  String get reportMessageReportSubmittedThankYou =>
      '보고서가 제출되었습니다. 피드백을 주셔서 감사합니다!';

  @override
  String get reportMessageReportThisResponse => '이 응답 신고하기';

  @override
  String reportMessageSheetFailedToSubmitReport(Object e) {
    return '보고서 제출 실패: $e';
  }

  @override
  String get reportMessageSubmitReport => '보고서 제출';

  @override
  String get reportMessageTellUsMoreAbout => '문제에 대해 더 자세히 알려주세요...';

  @override
  String get reportMessageWhatSWrongWith => '이 응답에 어떤 문제가 있나요?';

  @override
  String get reportNewspaperTemplateExclusiveReport => '독점 보고서';

  @override
  String get reportNewspaperTemplateNo01 => 'NO. 01';

  @override
  String get reportNewspaperTemplateTheZealovaTimes => 'THE ZEALOVA TIMES';

  @override
  String reportNewspaperTemplateValue(Object title) {
    return '— $title';
  }

  @override
  String get reportPainCouldNotSavePlease => '저장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get reportPainPainOnThisExercise => '이 운동에서 통증이 느껴지나요?';

  @override
  String get reportPainSkipAvoid => '건너뛰기 및 제외';

  @override
  String get reportPainSkipThisExercise => '이 운동 건너뛰기';

  @override
  String get reportReceiptTemplateCustomer => '고객';

  @override
  String get reportReceiptTemplateReport => '리포트';

  @override
  String reportReceiptTemplateReportReceipt(Object periodLabel) {
    return '보고서 영수증 · $periodLabel';
  }

  @override
  String reportReceiptTemplateTotal(Object unit) {
    return '합계 $unit';
  }

  @override
  String get reportReceiptTemplateZealovaGym => 'ZEALOVA GYM';

  @override
  String get reportShareCopyLink => '링크 복사';

  @override
  String get reportShareInstagram => 'Instagram';

  @override
  String reportShareSheetShare(Object title) {
    return '$title 공유';
  }

  @override
  String get reportShareShowWatermark => '워터마크 표시';

  @override
  String get reportStrainAiWillSuggestLighter => 'AI가 더 가벼운 운동을 제안합니다';

  @override
  String get reportStrainReportStrain => '부상 보고';

  @override
  String get reportStrainRequestRestDay => '휴식일 요청';

  @override
  String get reportStrainSelectAtLeastOne => '최소 하나의 근육 그룹을 선택하세요';

  @override
  String get reportStrainStrainReportSubmitted => '부상 보고서가 제출되었습니다';

  @override
  String get reportStrainSubmitReport => '보고서 제출';

  @override
  String get reportWrappedTemplateLifter => '리프터';

  @override
  String get reportWrappedTemplateWrapped => 'WRAPPED';

  @override
  String get reportsHub1RepMaxes => '1RM';

  @override
  String get reportsHubBadgesUnlockedAlongYour => '운동 여정에서 획득한 배지';

  @override
  String get reportsHubBodyMeasurements => '신체 측정';

  @override
  String get reportsHubBodyRecovery => '신체 및 회복';

  @override
  String reportsHubCouldntBuildShare(Object error) {
    return '공유 항목을 생성할 수 없습니다 — $error';
  }

  @override
  String get reportsHubDetail => '상세';

  @override
  String get reportsHubEstimated1rmsForEvery => '모든 주요 리프트의 예상 1RM';

  @override
  String get reportsHubEveryLiftPrYou => '기록된 모든 리프트 PR 순위';

  @override
  String get reportsHubExerciseHistory => '운동 기록';

  @override
  String get reportsHubLifestyle => '라이프스타일';

  @override
  String get reportsHubMacrosCaloriesAdherence => '매크로, 칼로리, 준수도';

  @override
  String get reportsHubMilestones => '마일스톤';

  @override
  String get reportsHubMuscleStrength => '근력';

  @override
  String reportsHubNoDataForMonth(Object month, Object reportName) {
    return '$month에 대한 $reportName 데이터가 없습니다. 다른 달을 선택해 보세요.';
  }

  @override
  String get reportsHubNotEnoughDataYet =>
      '데이터가 충분하지 않습니다. 다음 운동 후에 다시 시도해주세요.';

  @override
  String get reportsHubPeriodInsights => '기간별 인사이트';

  @override
  String get reportsHubPersonalRecords => '개인 최고 기록';

  @override
  String get reportsHubProgressCharts => '진행 상황 차트';

  @override
  String get reportsHubProgressionCurveForEvery => '수행한 모든 운동의 진행 곡선';

  @override
  String get reportsHubReadinessRecovery => '준비 상태 및 회복';

  @override
  String get reportsHubReportsInsights => '리포트 및 인사이트';

  @override
  String get reportsHubScorePerMuscleGroup => '근육 그룹별 점수, 추세 및 히트맵';

  @override
  String reportsHubScreenEverythingYouVeEarned(Object appName) {
    return '$appName에서 달성한 모든 것';
  }

  @override
  String get reportsHubSleepFatigueStressReadin => '수면, 피로, 스트레스, 준비 상태 점수';

  @override
  String get reportsHubTraining => '트레이닝';

  @override
  String get reportsHubViewReport => '리포트 보기';

  @override
  String get reportsHubVolumeStrengthAndConsiste => '시간에 따른 볼륨, 근력 및 일관성';

  @override
  String get reportsHubWeightBodyFatCircumferenc => '체중, 체지방, 신체 치수 추세';

  @override
  String get reportsHubWorkoutsTimeCaloriesBy =>
      '운동, 시간, 칼로리 (1주 / 1개월 / 3개월 / 6개월 / 1년 / 연초 대비 / 사용자 지정)';

  @override
  String get requestRefundAdditionalCommentsOptional => '추가 의견 (선택 사항)';

  @override
  String get requestRefundCheckYourEmail => '이메일을 확인하세요';

  @override
  String get requestRefundOneTime => '일회성';

  @override
  String get requestRefundOneTime2 => '일회성';

  @override
  String get requestRefundPleaseSelectTheReason => '상황을 가장 잘 설명하는 사유를 선택해주세요';

  @override
  String get requestRefundReasonForRefund => '환불 사유';

  @override
  String get requestRefundRefundPolicy => '환불 정책';

  @override
  String get requestRefundRefundRequestSubmitted => '환불 요청이 제출되었습니다';

  @override
  String get requestRefundRefundRequestsAreTypically =>
      '환불 요청은 일반적으로 영업일 기준 5-7일 이내에 처리됩니다. 요청이 검토되면 이메일로 확인 안내를 보내드립니다.';

  @override
  String get requestRefundRequestId => '요청 ID';

  @override
  String get requestRefundRequestRefund => '환불 요청';

  @override
  String get requestRefundSaveThisIdFor => '기록을 위해 이 ID를 저장해두세요';

  @override
  String requestRefundScreenPer(Object _billingPeriod) {
    return '$_billingPeriod당';
  }

  @override
  String requestRefundScreenWeHaveReceivedYour(Object planName) {
    return '$planName에 대한 환불 요청이 접수되었습니다.';
  }

  @override
  String get requestRefundSubmitRefundRequest => '환불 요청 제출';

  @override
  String get requestRefundSubscriptionBeingRefunded => '환불 처리 중인 구독';

  @override
  String get requestRefundTellUsMoreAbout => '경험에 대해 더 자세히 알려주세요...';

  @override
  String get requestRefundWeWillSendYou =>
      '환불 요청에 대한 세부 정보가 포함된 확인 이메일을 보내드립니다. 처리에는 일반적으로 영업일 기준 5-7일이 소요됩니다.';

  @override
  String get rescheduleFailedToLoadSuggestions => '제안을 불러오지 못했습니다';

  @override
  String get rescheduleFailedToRescheduleWorkout => '운동 일정 변경에 실패했습니다';

  @override
  String get reschedulePickADifferentDay => '다른 날짜를 선택하세요';

  @override
  String get rescheduleRescheduleWorkout => '운동 일정 변경';

  @override
  String rescheduleSheetSwapsWith(Object swapWorkoutName) {
    return '교체 대상: $swapWorkoutName';
  }

  @override
  String get rescheduleWorkoutSwappedSuccessfully => '운동이 성공적으로 변경되었습니다';

  @override
  String get restRateLastSet => '마지막 세트 평가';

  @override
  String get restRateLastSetOptional => '선택 사항';

  @override
  String get restSuggestionAiRestCoach => 'AI 휴식 코치';

  @override
  String get restSuggestionCalculatingOptimalRestTime => '최적의 휴식 시간 계산 중';

  @override
  String get restSuggestionCardAiRestCoach => 'AI 휴식 코치';

  @override
  String get restSuggestionCardCalculatingOptimalRestTime =>
      '최적의 휴식 시간을 계산 중입니다...';

  @override
  String get restSuggestionCardQuickRest => '빠른 휴식';

  @override
  String get restSuggestionCardSuggested => '제안됨';

  @override
  String get restSuggestionCardUseSuggested => '제안된 시간 사용';

  @override
  String get restSuggestionQuick => '빠른';

  @override
  String get restSuggestionQuickRest => '빠른 휴식';

  @override
  String restSuggestionSaveTime(Object arg0) {
    return '$arg0 단축';
  }

  @override
  String get restSuggestionSuggested => '추천';

  @override
  String get restSuggestionUseSuggested => '추천 휴식 사용';

  @override
  String get restTimerCardBaseRest => '기본 휴식';

  @override
  String get restTimerCardControlRestPeriodsBetween => '세트 간 휴식 시간 제어';

  @override
  String get restTimerCardCustomRestTimer => '사용자 지정 휴식 타이머';

  @override
  String get restTimerCardFormula => '공식';

  @override
  String get restTimerCardLivePreview => '실시간 미리보기';

  @override
  String get restTimerCardMultiplier => '배수';

  @override
  String get restTimerCardRestBaserestRpe7 => '휴식 = BaseRest * (RPE / 7)';

  @override
  String restTimerCardS(Object value) {
    return '$value초';
  }

  @override
  String restTimerCardS2(Object restTimerBaseRest) {
    return '$restTimerBaseRest초';
  }

  @override
  String restTimerCardS3(Object s) {
    return '$s초';
  }

  @override
  String get restTimerCardVariablesBaseRpeMultipli => '변수: 기본, RPE, 배수, 등급';

  @override
  String restTimerCardX(Object restTimerMultiplier) {
    return '${restTimerMultiplier}x';
  }

  @override
  String get restTimerOverlayAiWeightCoach => 'AI WEIGHT COACH';

  @override
  String get restTimerOverlayAnalyzingYourPerformance => '성과 분석 중...';

  @override
  String restTimerOverlayAsk(Object coachName) {
    return '$coachName에게 물어보기';
  }

  @override
  String get restTimerOverlayCoachReview => 'COACH REVIEW';

  @override
  String get restTimerOverlayGetTipsForYour => '다음 세트를 위한 팁 확인하기';

  @override
  String get restTimerOverlayGotIt => '확인';

  @override
  String get restTimerOverlayLog1rm => '1RM 기록';

  @override
  String get restTimerOverlayNextSet => '다음 세트';

  @override
  String get restTimerOverlayNextUp => '다음 운동';

  @override
  String get restTimerOverlayRateLastSet => '마지막 세트 평가';

  @override
  String get restTimerOverlayRirRepsInReserve => 'RIR (Reps in Reserve)';

  @override
  String get restTimerOverlayRpeRateOfPerceived =>
      'RPE (Rate of Perceived Exertion)';

  @override
  String restTimerOverlayS(Object restSecondsRemaining) {
    return '$restSecondsRemaining초';
  }

  @override
  String get restTimerOverlaySkipRest => '휴식 건너뛰기';

  @override
  String get restTimerOverlayTrackYourMax => '최대 중량 추적';

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
    return '$reps회';
  }

  @override
  String restTimerOverlayUiUseKg(Object suggestedWeight) {
    return '$suggestedWeight kg 사용';
  }

  @override
  String get restTimerRest => '휴식';

  @override
  String get restTimerSkipRest => '휴식 건너뛰기';

  @override
  String get retro80sTemplateCalories => '칼로리';

  @override
  String get retro80sTemplateVolume => '볼륨';

  @override
  String get retuneProposalApplyChanges => '변경 사항 적용';

  @override
  String get retuneProposalApplying => '적용 중...';

  @override
  String get retuneProposalDismiss => '닫기';

  @override
  String get retuneProposalDismissing => '닫는 중...';

  @override
  String get retuneProposalMuscleFocusShifts => '근육 타겟 변경:';

  @override
  String get retuneProposalPreviewNextWeek => '다음 주 미리보기';

  @override
  String get retuneProposalPreviewUnavailable => '미리보기를 사용할 수 없습니다.';

  @override
  String get retuneProposalProgramRetunedNextPlan =>
      '프로그램이 재조정되었습니다. 다음 플랜에 변경 사항이 반영됩니다.';

  @override
  String get retuneProposalRetuneProposal => '재조정 제안';

  @override
  String retuneProposalSheetValue(Object after, Object before) {
    return '$before  →  $after';
  }

  @override
  String get rewardsAvailable => '사용 가능';

  @override
  String get rewardsClaim => '받기';

  @override
  String get rewardsClaimed => '받음';

  @override
  String get rewardsConfirm => '확인';

  @override
  String get rewardsKeepLevelingUpTo => '레벨을 올려 보상을 잠금 해제하세요!';

  @override
  String get rewardsNoRewardsAvailableYet => '아직 사용 가능한 보상이 없습니다';

  @override
  String get rewardsRewards => '보상';

  @override
  String rewardsScreenTotalXp(Object totalXp) {
    return '총 XP $totalXp';
  }

  @override
  String get rewardsYourEmailExampleCom => 'your.email@example.com';

  @override
  String get ringCatalogCycleDay => '주기 일차';

  @override
  String get ringCatalogHeartRate => '심박수';

  @override
  String get ringCatalogHydration => '수분 섭취';

  @override
  String get ringCatalogMove => '활동';

  @override
  String get ringCatalogNourish => '영양';

  @override
  String get ringCatalogSleep => '수면';

  @override
  String get ringCatalogStress => '스트레스';

  @override
  String get ringCatalogTrain => '운동';

  @override
  String get ringCatalogWeight => '체중';

  @override
  String get ringLabelCycleDay => '주기 일차';

  @override
  String get ringLabelHeartRate => '심박수';

  @override
  String get ringLabelHrv => 'HRV';

  @override
  String get ringLabelHydration => '수분 섭취';

  @override
  String get ringLabelMove => '활동';

  @override
  String get ringLabelNourish => '영양';

  @override
  String get ringLabelRecovery => '회복';

  @override
  String get ringLabelSleep => '수면';

  @override
  String get ringLabelStress => '스트레스';

  @override
  String get ringLabelTrain => '운동';

  @override
  String get ringLabelWeight => '체중';

  @override
  String get roiSummaryCardCalories => '칼로리';

  @override
  String get roiSummaryCardCompleteYourFirstWorkout =>
      '첫 번째 운동을 완료하고 진행 상황을 추적해보세요!';

  @override
  String get roiSummaryCardInvested => '투자함';

  @override
  String get roiSummaryCardLoadingYourProgress => '진행 상황 불러오는 중...';

  @override
  String get roiSummaryCardStartYourJourney => '여정 시작하기';

  @override
  String roiSummaryCardYouReSinceYou(Object strengthIncreaseText) {
    return '시작한 이후로 $strengthIncreaseText!';
  }

  @override
  String get routeMapOpenstreetmapContributors => '© OpenStreetMap 기여자';

  @override
  String get rpeCardAutomaticallyAdjustBasedOn => 'RPE 피드백을 기반으로 자동 조정';

  @override
  String get rpeCardRpeAutoRegulation => 'RPE 자동 조절';

  @override
  String get rpeCardRpePromptFrequency => 'RPE 알림 빈도';

  @override
  String get rpeCardSensitivity => '민감도';

  @override
  String get rpeEasy => '쉬움';

  @override
  String get rpeFailure => '실패';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get rpeLight => '가벼움';

  @override
  String get rpeOneRepLeft => '1회 남음';

  @override
  String get rpePillRpeRateOfPerceived =>
      'RPE — 자각도(Rate of Perceived Exertion)';

  @override
  String get rpeRirHelpsAdjustNextSet => '다음 세트 조정에 도움';

  @override
  String get rpeRirHowHardWasThatSet => '이번 세트 강도는 어땠나요?';

  @override
  String get rpeRirRateOfPerceivedExertion => '주관적 운동 강도 (RPE)';

  @override
  String get rpeRirRepsInReserve => '잔여 반복 횟수 (RIR)';

  @override
  String get rpeRirRir => 'RIR';

  @override
  String get rpeRirRpe => 'RPE';

  @override
  String get rpeTwoRepsLeft => '2회 남음';

  @override
  String get rtpAdvancePhase => '마일스톤 달성';

  @override
  String get rtpDisclaimer => '셀프 가이드 프레임워크. 각 단계로 진행하기 전에 의료 제공자의 승인이 필요합니다.';

  @override
  String get rtpGraduated => '졸업';

  @override
  String get rtpTitle => '복귀 프로그램';

  @override
  String get safetyDisclaimerBannerDismissDisclaimer => '면책 조항 닫기';

  @override
  String safetyDisclaimerBannerInjuriesFlagged(Object arg0) {
    return '부상 $arg0건 표시됨';
  }

  @override
  String get safetyDisclaimerBannerInjuryBody => '부상 부위';

  @override
  String get safetyDisclaimerBannerLearnMore => '더 알아보기';

  @override
  String safetyDisclaimerBannerMore(Object overflow) {
    return '+$overflow개 더';
  }

  @override
  String get safetyDisclaimerBannerSafetyModeActive => '안전 모드 활성화됨';

  @override
  String get safetyDisclaimerBannerSafetyModeBody => '안전 모드 본문';

  @override
  String get saunaCustomDuration => '사용자 지정 시간';

  @override
  String saunaDialogLogMinSauna(Object selectedMinutes) {
    return '사우나 $selectedMinutes분 기록';
  }

  @override
  String saunaDialogMin(Object minutes) {
    return '$minutes분';
  }

  @override
  String get saunaLogSaunaTime => '사우나 시간 기록';

  @override
  String get savedHubCheckYourConnectionAnd => '연결 상태를 확인하고 다시 시도하세요.';

  @override
  String get savedHubCouldnTLoadYour => '저장된 항목을 불러올 수 없습니다.';

  @override
  String get savedHubNothingSavedYet => '아직 저장된 항목이 없습니다';

  @override
  String get savedHubSaveAMealOr => '식단 기록에서 식사나 음식을 저장하여 나중에 빠르게 추가하세요.';

  @override
  String get savedHubSaved => '저장됨';

  @override
  String get savedHubScanARestaurantMenu =>
      '식당 메뉴나 뷔페를 스캔하세요. 스캔한 항목이 여기에 저장됩니다.';

  @override
  String get savedHubSignInToSee => '로그인하여 저장된 레시피를 확인하세요.';

  @override
  String get savedHubSignInToSee2 => '로그인하여 저장된 음식을 확인하세요.';

  @override
  String get savedHubTapOnAnyRecipe =>
      'Discover나 라이브러리에서 레시피의 ♥를 눌러 여기에 저장하세요.';

  @override
  String get savedHubTryAgain => '다시 시도';

  @override
  String get scheduleGenerateThisWeek => '이번 주 생성';

  @override
  String scheduleItemCardMin(Object durationMinutes) {
    return '$durationMinutes분';
  }

  @override
  String get scheduleMealDays => '요일';

  @override
  String get scheduleMealEndDate => '종료일';

  @override
  String get scheduleMealInterval => '간격';

  @override
  String get scheduleMealPickACadenceWe => '주기를 선택하시면 AI가 레시피 저장을 도와드립니다.';

  @override
  String get scheduleMealPickADate => '날짜 선택';

  @override
  String get scheduleMealPickAnEndDate => '종료일 선택';

  @override
  String get scheduleMealPickAtLeastOne => '최소 하루를 선택하세요';

  @override
  String get scheduleMealSchedule => '일정';

  @override
  String get scheduleMealScheduleThisMeal => '이 식사 일정 잡기';

  @override
  String scheduleMealSheetDays(Object i) {
    return '$i일';
  }

  @override
  String scheduleMealSheetEveryDays(Object _intervalDays) {
    return '$_intervalDays일마다';
  }

  @override
  String get scheduleMealTime => '시간';

  @override
  String get scheduleMismatchConfirm => '확인';

  @override
  String scheduleMismatchDialogAiWillSwitchTo(Object compatibleSplitName) {
    return 'AI가 $compatibleSplitName(으)로 변경합니다';
  }

  @override
  String scheduleMismatchDialogRequiresDaysPerWeek(
    Object currentDayCount,
    Object requiredDays,
    Object splitName,
  ) {
    return '$splitName은(는) 주 $requiredDays일 운동이 필요하지만, 현재 $currentDayCount일이 선택되어 있습니다.';
  }

  @override
  String scheduleMismatchDialogUpdateToSchedule(Object splitName) {
    return '$splitName 스케줄로 업데이트';
  }

  @override
  String scheduleMismatchDialogUseTheFullDay(Object requiredDays) {
    return '$requiredDays일 전체 프로그램 사용';
  }

  @override
  String get scheduleMismatchKeepMyCurrentDays => '현재 요일 유지';

  @override
  String get scheduleMismatchRecommended => '추천';

  @override
  String get scheduleMismatchScheduleMismatch => '일정 불일치';

  @override
  String get scheduleNoItemsScheduled => '예정된 항목 없음';

  @override
  String get scheduleRestDay => '휴식일';

  @override
  String get scheduleSchedule => '일정';

  @override
  String scheduleScreenFailedToLoad(Object error) {
    return '로드 실패: $error';
  }

  @override
  String scheduleScreenFailedToLoadTimeline(Object error) {
    return '타임라인 로드 실패: $error';
  }

  @override
  String scheduleScreenGeneratedOfWorkouts(Object length, Object successCount) {
    return '$length개 중 $successCount개의 운동 생성됨';
  }

  @override
  String scheduleScreenGenerating(
    Object _generatedCount,
    Object _totalToGenerate,
  ) {
    return '생성 중 $_generatedCount/$_totalToGenerate...';
  }

  @override
  String get scheduleScreenPartMon => '월';

  @override
  String get scheduleScreenPartStrength => 'STRENGTH';

  @override
  String get scheduleScreenPartSun => '일';

  @override
  String get scheduleScreenPartThisWeek => '이번 주';

  @override
  String scheduleScreenPartWeekSelectorEx(Object exerciseCount) {
    return '운동 $exerciseCount개';
  }

  @override
  String scheduleScreenPartWeekSelectorMin(Object bestDurationMinutes) {
    return '$bestDurationMinutes분';
  }

  @override
  String get scheduleToday => '오늘';

  @override
  String get scheduleWorkoutCheckingSchedule => '일정 확인 중...';

  @override
  String scheduleWorkoutDialogFailedToScheduleWorkout(Object e) {
    return '운동 예약 실패: $e';
  }

  @override
  String scheduleWorkoutDialogScheduleFor(Object workoutName) {
    return '\"$workoutName\" 일정 설정:';
  }

  @override
  String scheduleWorkoutDialogWorkoutSAlreadyOn(Object length) {
    return '해당 날짜에 $length개의 운동이 이미 예정되어 있습니다';
  }

  @override
  String scheduleWorkoutDialogWorkoutScheduledFor(Object day, Object month) {
    return '$month월 $day일로 운동이 예약되었습니다!';
  }

  @override
  String get scheduleWorkoutSchedule => '일정';

  @override
  String get scheduleWorkoutScheduleWorkout => '운동 일정 잡기';

  @override
  String get scheduleWorkoutSchedulingWorkout => '운동 일정 잡는 중...';

  @override
  String get scheduleWorkoutThisWorkoutWillBe => '이 운동이 함께 추가됩니다.';

  @override
  String get scoreBreakdownConsistency => '일관성';

  @override
  String get scoreBreakdownReadiness => '준비도';

  @override
  String get scoreBreakdownScoreBreakdown => '점수 분석';

  @override
  String get scoreBreakdownStrength => '근력';

  @override
  String get scoreChangeAnnouncementGotIt => '확인';

  @override
  String get scoreChangeAnnouncementMove => '활동';

  @override
  String get scoreChangeAnnouncementNourish => '영양';

  @override
  String scoreChangeAnnouncementSheetValue(Object label, Object weight) {
    return '$label · $weight%';
  }

  @override
  String get scoreChangeAnnouncementSleep => '수면';

  @override
  String get scoreChangeAnnouncementSleepNowCountsToward =>
      '이제 수면이 일일 점수에 반영됩니다.';

  @override
  String get scoreChangeAnnouncementTrain => '운동';

  @override
  String get scoreChangeAnnouncementWhatSNew => '새로운 기능';

  @override
  String get scoreColorsExcellent => '우수';

  @override
  String get scoreExplain03AntiInflammatory => '0 – 3 항염증';

  @override
  String get scoreExplain13Poor => '1 – 3 나쁨';

  @override
  String get scoreExplain46Average => '4 – 6 보통';

  @override
  String get scoreExplain46NeutralMild => '4 – 6 중립 / 경미함';

  @override
  String get scoreExplain710GoodExcellent => '7 – 10 좋음 / 우수';

  @override
  String get scoreExplain710HighlyInflammatory => '7 – 10 고염증성';

  @override
  String get scoreExplainAddedSugar => '첨가당';

  @override
  String get scoreExplainAddedSugarIsThe =>
      '첨가당은 서구식 식단에서 대사 증후군을 예측하는 가장 강력한 단일 지표입니다.';

  @override
  String scoreExplainAddedSugarValue(Object value) {
    return '첨가당: $value';
  }

  @override
  String get scoreExplainAiPicksATrafficLight =>
      'AI가 사용자의 개인 건강 목표에 따라 각 식단에 신호등 등급을 부여합니다.';

  @override
  String get scoreExplainAimForADailyAverage =>
      '일일 평균 4점 미만을 목표로 하세요. 항염증 식품은 1~3점, 고염증 식품은 7~10점입니다.';

  @override
  String get scoreExplainCertainPortionsOfAvocado =>
      '아보카도, 고구마, 아몬드의 특정 분량 — 소량은 괜찮으나 다량은 부담될 수 있음.';

  @override
  String get scoreExplainChronicLowGradeInflammation =>
      '식단으로 인한 만성 저강도 염증은 대사 질환, 관절 통증 및 인지 기능 저하와 관련이 있습니다.';

  @override
  String get scoreExplainCurrentLabelAntiInfl => '항염증';

  @override
  String get scoreExplainCurrentLabelAverage => '평균';

  @override
  String get scoreExplainCurrentLabelGood => 'GOOD';

  @override
  String get scoreExplainCurrentLabelHigh => 'HIGH';

  @override
  String get scoreExplainCurrentLabelLow => 'LOW';

  @override
  String get scoreExplainCurrentLabelMedium => '중간';

  @override
  String get scoreExplainCurrentLabelMild => 'MILD';

  @override
  String get scoreExplainCurrentLabelModerate => '보통';

  @override
  String get scoreExplainCurrentLabelNova4 => 'NOVA 4';

  @override
  String get scoreExplainCurrentLabelPoor => 'POOR';

  @override
  String get scoreExplainCurrentLabelSkip => 'SKIP';

  @override
  String get scoreExplainCurrentLabelWhole => 'WHOLE';

  @override
  String get scoreExplainDailyAverageAbove6 =>
      '일일 평균 6점 이상은 장기적인 대사 건강 개선과 관련이 있습니다.';

  @override
  String get scoreExplainDessertsSugaryDrinksCandy =>
      '디저트, 가당 음료, 사탕, 대부분의 아침 시리얼. 인슐린 수치를 급격히 높이고 에너지를 저하시킴.';

  @override
  String get scoreExplainEachMealGets =>
      '각 식사는 영양 밀도, 가공 수준, 목표 부합도를 기준으로 1~10점의 건강 점수를 받습니다.';

  @override
  String get scoreExplainEngineeredFoodProductsChip =>
      '가공식품: 감자칩, 탄산음료, 인스턴트 라면, 포장 과자, 대부분의 패스트푸드.';

  @override
  String get scoreExplainFodmapRating => 'FODMAP 등급';

  @override
  String get scoreExplainFodmapsAreShortChain =>
      'FODMAP은 장내 박테리아에 의해 발효되고 흡수가 잘 되지 않는 단쇄 탄수화물입니다.';

  @override
  String get scoreExplainFriedFoodsProcessedMeats =>
      '튀긴 음식, 가공육, 당분이 많은 음료, 정제된 씨앗유, 포장된 간식.';

  @override
  String get scoreExplainGlycemicLoadCombines =>
      '혈당 부하는 탄수화물의 양과 질을 결합한 지표입니다. 식사 후 혈당이 얼마나 상승할지 예측합니다.';

  @override
  String scoreExplainGlycemicLoadValue(Object v) {
    return '혈당 부하: $v';
  }

  @override
  String get scoreExplainGood => '좋음';

  @override
  String get scoreExplainHealthScore => '건강 점수';

  @override
  String scoreExplainHealthScoreValue(Object v) {
    return '건강 점수: $v / 10';
  }

  @override
  String get scoreExplainHigh => '높음';

  @override
  String get scoreExplainHigh15G => '높음 (15 g 이상)';

  @override
  String get scoreExplainHigh20 => '높음 (20 이상)';

  @override
  String get scoreExplainHighInflammationUltraProce =>
      '높은 염증 유발, 초가공식품 또는 매크로와 크게 벗어남. 가능하다면 좋은 옵션으로 교체하세요.';

  @override
  String get scoreExplainHighProteinOrFiber =>
      '높은 단백질 또는 식이섬유, 자연식품, 낮은 당류, 항염증 성분.';

  @override
  String get scoreExplainHitsYourGoalMacros =>
      '목표 매크로 충족, 대부분 자연식품, 낮거나 적당한 염증 유발. 자유롭게 선택하세요.';

  @override
  String get scoreExplainHowThisDishRates => '이 음식의 평가';

  @override
  String get scoreExplainImportantIfYouHaveDiabetes =>
      '당뇨병, 인슐린 저항성이 있거나 에너지 레벨을 관리 중인 경우 중요합니다.';

  @override
  String scoreExplainInflammationScoreValue(Object v) {
    return '염증 점수: $v / 10';
  }

  @override
  String get scoreExplainLargePopulationStudies =>
      '대규모 인구 연구에 따르면 초가공식품 섭취는 암, 심혈관 질환 및 조기 사망과 관련이 있습니다.';

  @override
  String get scoreExplainLeafyGreensBerriesWild =>
      '잎채소, 베리류, 자연산 연어, 강황, 엑스트라 버진 올리브유, 견과류, 콩류.';

  @override
  String get scoreExplainLow => '낮음';

  @override
  String get scoreExplainLowUnder10 => '낮음 (10 미만)';

  @override
  String get scoreExplainLowUnder5G => '낮음 (5 g 미만)';

  @override
  String get scoreExplainMeatEggsRiceOats =>
      '고기, 달걀, 쌀, 귀리, 유당 제거 유제품, 당근, 애호박, 시금치, 베리류, 오렌지.';

  @override
  String get scoreExplainMedium => '중간';

  @override
  String get scoreExplainMedium1019 => '중간 (10 – 19)';

  @override
  String get scoreExplainMinimalBloodSugarSpike =>
      '혈당 상승 최소화. 비전분 채소, 달걀, 고기, 베리류, 대부분의 유제품.';

  @override
  String get scoreExplainModerate => '보통';

  @override
  String get scoreExplainModerate514G => '보통 (5 – 14 g)';

  @override
  String get scoreExplainModerateSpikeOatsWhole =>
      '적당한 혈당 상승. 귀리, 통밀빵, 바나나, 고구마, 바스마티 쌀.';

  @override
  String get scoreExplainMostSavouryDishesPlain =>
      '대부분의 요리, 플레인 유제품, 통과일. 혈당에 큰 영향 없음.';

  @override
  String get scoreExplainOnionGarlicWheatRye =>
      '양파, 마늘, 밀, 호밀, 우유/아이스크림, 사과, 배, 꿀, 콩, 콜리플라워.';

  @override
  String get scoreExplainOnlyRelevantIfYouHaveIbs =>
      'IBS(과민성 대장 증후군) 또는 진단받은 장 질환이 있는 경우에만 관련이 있습니다. 그 외에는 무시해도 좋습니다.';

  @override
  String get scoreExplainRatingsArePersonalised =>
      '등급은 사용자의 목표, 알레르기, 식습관 기록에 맞춰 개인화됩니다.';

  @override
  String get scoreExplainRawOrBasicCooked =>
      '원재료 또는 기본 조리 식품: 고기, 달걀, 채소, 플레인 요거트, 치즈, 통곡물.';

  @override
  String get scoreExplainReasonableChoiceCouldBe =>
      '합리적인 선택 — 한두 가지 측면(식이섬유 증가, 가공 최소화)에서 개선 가능.';

  @override
  String get scoreExplainReasonableChoiceWithA =>
      '절충안이 있는 합리적인 선택 — 분량을 조절하거나 더 건강한 사이드 메뉴와 함께 드세요.';

  @override
  String get scoreExplainScoreDetailUnavailable =>
      '이 식단에 대한 점수 상세 정보를 사용할 수 없습니다.';

  @override
  String get scoreExplainSkip => '건너뛰기';

  @override
  String get scoreExplainSteepSpikeCrashWhite =>
      '급격한 혈당 상승 및 저하. 흰 쌀밥, 가당 음료, 페이스트리, 많은 양의 파스타.';

  @override
  String get scoreExplainSweetenedYogurtASmall =>
      '가당 요거트, 작은 페이스트리, 스포츠 음료 반 병. 가끔은 괜찮은 간식 — 매일은 금물.';

  @override
  String scoreExplainThatIsAboutPctDay(Object pctDay) {
    return '이는 WHO 권장 일일 제한량 25g의 약 $pctDay%입니다. 첨가당은 충치, 인슐린 급증 및 비알코올성 지방간 질환의 원인이 됩니다.';
  }

  @override
  String get scoreExplainUltraProcessed => '초가공식품';

  @override
  String get scoreExplainUltraProcessedDeepFried =>
      '초가공, 튀김, 낮은 식이섬유, 또는 매우 높은 당류/나트륨 함량.';

  @override
  String get scoreExplainUltraProcessedNova4 => '초가공식품 (NOVA 4)';

  @override
  String get scoreExplainWeUseTheNovaClassification =>
      '상파울루 대학교에서 개발한 NOVA 분류 체계를 사용합니다.';

  @override
  String get scoreExplainWhiteRicePlainEggs => '흰 쌀밥, 플레인 달걀, 단단한 치즈, 소량의 살코기.';

  @override
  String get scoreExplainWhoRecommendsAdults =>
      'WHO는 성인의 첨가당 섭취량을 하루 25g 미만(총 에너지의 5%)으로 제한할 것을 권장합니다.';

  @override
  String get scoreExplainWholeMinimallyProcessed => '자연식품 / 최소 가공식품';

  @override
  String get scoreExplainWhyThisScore => '이 점수의 이유';

  @override
  String get scoringCard6FactorWeightedSelection => '6요소 가중치 선택 알고리즘';

  @override
  String get scoringCardExerciseScoringBreakdown => '운동 점수 분석';

  @override
  String get scoringCardNormalize => '정규화';

  @override
  String get scoringCardOver100 => '100% 초과';

  @override
  String get scoringCardReset => '초기화';

  @override
  String scoringCardTotal(Object totalPct) {
    return '합계: $totalPct%';
  }

  @override
  String get scoringCardUnder90 => '90% 미만';

  @override
  String scoringCardValue(Object key, Object pct) {
    return '$key: $pct%';
  }

  @override
  String scoringCardValue2(Object pct) {
    return '$pct%';
  }

  @override
  String get scoringFitnessScore => '피트니스 점수';

  @override
  String get scoringHowScoresAreCalculated => '점수 산정 방식';

  @override
  String get scoringYourOverallFitnessScore =>
      '전반적인 피트니스 점수는 이러한 요소들을 종합하여 피트니스 여정을 한눈에 보여줍니다.';

  @override
  String get sectionHeaderWhatSThis => '이게 무엇인가요?';

  @override
  String get sectionedHeroAreaCalendarDisplayOptions => '캘린더 표시 옵션';

  @override
  String get sectionedHeroAreaMon => '월';

  @override
  String get sectionedHeroAreaShowSyncedWorkouts => '동기화된 운동 표시';

  @override
  String get sectionedHeroAreaStartWeekOnMonday => '월요일부터 한 주 시작';

  @override
  String get sectionedHeroAreaStartWeekOnSunday => '일요일부터 한 주 시작';

  @override
  String get sectionedHeroAreaSun => '일';

  @override
  String get selectableChipOther => '기타';

  @override
  String get seniorButtonRecommended => '추천';

  @override
  String seniorCardExercisesMin(Object durationMinutes, Object exerciseCount) {
    return '$exerciseCount개 운동  •  $durationMinutes분';
  }

  @override
  String get seniorCardLoading => '불러오는 중...';

  @override
  String get seniorCardStartWorkout => '운동 시작';

  @override
  String get seniorCardTodaySWorkout => '오늘의 운동';

  @override
  String get seniorFitnessAgeAdaptedWorkouts => '연령 맞춤형 운동';

  @override
  String get seniorFitnessRestBetweenSets => '세트 간 휴식';

  @override
  String get seniorFitnessSaveSettings => '설정 저장';

  @override
  String seniorFitnessScreenS(Object restBetweenSets) {
    return '$restBetweenSets초';
  }

  @override
  String get seniorFitnessSeniorFitness => '시니어 피트니스';

  @override
  String get seniorFitnessSettingsSaved => '설정이 저장되었습니다';

  @override
  String get seniorFitnessTheseSettingsHelpCustomize =>
      '이 설정은 더 긴 회복 시간과 관절 친화적인 운동을 포함하여 시니어 피트니스 요구에 맞게 운동을 조정하는 데 도움을 줍니다.';

  @override
  String get seniorNavFood => '식단';

  @override
  String get sessionDetailReps => '횟수';

  @override
  String get sessionDetailSet => '세트';

  @override
  String sessionDetailSetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count세트',
    );
    return '$_temp0 · 최고 세트 강조됨';
  }

  @override
  String get sessionDetailTime => '시간';

  @override
  String get sessionDetailWeight => '중량';

  @override
  String get setAdjustmentAdditionalNotesOptional => '추가 메모 (선택 사항)';

  @override
  String get setAdjustmentConfirm => '확인';

  @override
  String get setAdjustmentEGShoulderFeels => '예: 어깨가 뻐근함...';

  @override
  String get setAdjustmentSheet1Set => '+1 세트';

  @override
  String get setAdjustmentSheet1Set2 => '-1 세트';

  @override
  String get setAdjustmentSheetAdditionalNotesOptional => '추가 메모 (선택 사항)';

  @override
  String get setAdjustmentSheetApply => '적용';

  @override
  String get setAdjustmentSheetCopyLast => '마지막 복사';

  @override
  String get setAdjustmentSheetDoneWithThisExercise => '이 운동을 마치셨나요?';

  @override
  String get setAdjustmentSheetEditSets => '세트 편집';

  @override
  String setAdjustmentSheetPartInWorkoutSetEditingSheetStateAdded(
    Object originalSetCount,
  ) {
    return '$originalSetCount개 추가됨';
  }

  @override
  String setAdjustmentSheetPartInWorkoutSetEditingSheetStateDone(
    Object completedCount,
  ) {
    return '$completedCount개 완료';
  }

  @override
  String setAdjustmentSheetPartInWorkoutSetEditingSheetStateRemaining(
    Object remainingCount,
  ) {
    return '$remainingCount개 남음';
  }

  @override
  String setAdjustmentSheetPartInWorkoutSetEditingSheetStateRemoved(
    Object length,
  ) {
    return '$length개 삭제됨';
  }

  @override
  String setAdjustmentSheetPartSetAdjustmentReasonOfPlanned(Object totalSets) {
    return '/ $totalSets 계획됨';
  }

  @override
  String setAdjustmentSheetPartSetAdjustmentReasonSetsCompleted(
    Object completedSets,
  ) {
    return '$completedSets세트 완료';
  }

  @override
  String get setAdjustmentSheetReps => '횟수';

  @override
  String get setAdjustmentSheetSaveChanges => '변경 사항 저장';

  @override
  String get setAdjustmentSheetSkipContinue => '건너뛰고 계속';

  @override
  String get setAdjustmentSheetWeight => '무게';

  @override
  String get setAdjustmentSheetWhyAreYouReducing => '세트를 줄이는 이유는 무엇인가요?';

  @override
  String get setAdjustmentSheetWhyAreYouStopping => '운동을 일찍 종료하는 이유는 무엇인가요?';

  @override
  String get setAdjustmentWhyAreYouAdjusting => '조정하는 이유는 무엇인가요?';

  @override
  String get setLoggingMixinReps => '횟수';

  @override
  String get setLoggingMixinRirRepsInReserve => 'RIR (Reps in Reserve)';

  @override
  String get setLoggingMixinSetTargetRir => '목표 RIR 설정';

  @override
  String setRailInternalsMoreSets(Object count) {
    return '$count 세트 더';
  }

  @override
  String setRailInternalsValue(Object count) {
    return '+$count';
  }

  @override
  String get setRailOverflowAllSets => '모든 세트';

  @override
  String setRailOverflowRowSet(Object displayIndex) {
    return '세트 $displayIndex';
  }

  @override
  String setRailOverflowSheetTotal(Object length) {
    return '총 $length개';
  }

  @override
  String get setRowHidePrevious => '이전 기록 숨기기';

  @override
  String setRowNReps(Object count) {
    return '$count회';
  }

  @override
  String get setRowPartHide => '숨기기';

  @override
  String get setRowPartHidePrevious => '이전 기록 숨기기';

  @override
  String get setRowPartHowHardWasThat => '이번 세트의 강도는 어땠나요?';

  @override
  String get setRowPartRateOfPerceivedExertion => 'RPE (자각 인지 강도)';

  @override
  String get setRowPartRepsInReserve => 'RIR (Reps in Reserve)';

  @override
  String get setRowPartRirHowManyMore => 'RIR = 몇 번의 횟수를 더 할 수 있었나요?';

  @override
  String get setRowPartRpeMeasuresHowHard => 'RPE는 세트의 강도를 6-10 단계로 측정합니다:';

  @override
  String setRowPartRpeRirSelectorStateLeft(Object value) {
    return '$value 남음';
  }

  @override
  String get setRowPartThisHelpsUsAdjust => '다음 세트를 조정하는 데 도움이 됩니다';

  @override
  String setRowPartWeightIncrementsValue(Object actualPercent) {
    return '$actualPercent%';
  }

  @override
  String get setRowPartWhatSThis => '이게 무엇인가요?';

  @override
  String setRowPrevKg(Object setData) {
    return '이전: $setData kg';
  }

  @override
  String setRowPrevReps(Object previousReps) {
    return '이전: $previousReps회';
  }

  @override
  String setRowPreviousData(Object reps, Object unit, Object weight) {
    return '이전: $weight $unit × $reps회';
  }

  @override
  String setRowRm(Object oneRM) {
    return '(1RM: $oneRM)';
  }

  @override
  String setRowSetN(Object n) {
    return '세트 $n';
  }

  @override
  String setRowSetNCompact(Object n) {
    return '세트 $n';
  }

  @override
  String setRowTarget(Object targetPercent) {
    return '목표: $targetPercent%';
  }

  @override
  String setRowValue(Object actualPercent) {
    return '→ $actualPercent%';
  }

  @override
  String get setRowVisualsEdited => '수정됨';

  @override
  String get setRowVisualsGotIt => '확인';

  @override
  String get setRowVisualsStarterWeight => '시작 무게';

  @override
  String get setTrackingExerciseComplete => '운동 완료!';

  @override
  String get setTrackingNext => '다음:';

  @override
  String get setTrackingOverlayAnalytics => '분석';

  @override
  String get setTrackingOverlayBackToCurrentExercise => '현재 운동으로 돌아가기';

  @override
  String get setTrackingOverlayEffectiveSets => '유효 세트';

  @override
  String get setTrackingOverlayHide => '숨기기';

  @override
  String get setTrackingOverlayIncrement => '증가';

  @override
  String get setTrackingOverlayProgression => '진행 상황';

  @override
  String get setTrackingOverlaySet => '+ 세트';

  @override
  String get setTrackingOverlaySetType => '세트 유형:';

  @override
  String get setTrackingOverlayShow => '표시';

  @override
  String get setTrackingOverlayStraight => '스트레이트';

  @override
  String get setTrackingOverlayTapToAddNotes => '탭하여 메모 추가...';

  @override
  String get setTrackingOverlayTarget => '목표';

  @override
  String setTrackingOverlayUi1Of(Object totalExercises, Object widget) {
    return '$widget / $totalExercises개';
  }

  @override
  String setTrackingOverlayUi1Value(Object warmupReps, Object warmupWeight) {
    return '$warmupWeight × $warmupReps';
  }

  @override
  String get setTrackingOverlayView => '보기';

  @override
  String get setTrackingOverlayViewPr => 'PR 보기';

  @override
  String get setTrackingOverlayWarmupSets => '웜업 세트';

  @override
  String setTrackingSectionExerciseOf(Object totalExercises, Object widget) {
    return '운동 $widget/$totalExercises';
  }

  @override
  String setTrackingSectionSetTapToExpand(
    Object currentSetNumber,
    Object totalSets,
  ) {
    return '세트 $currentSetNumber/$totalSets • 탭하여 펼치기';
  }

  @override
  String setTrackingSectionSets(Object widget) {
    return '$widget 세트';
  }

  @override
  String setTrackingSectionSetsCompleted(Object length) {
    return '$length 세트 완료';
  }

  @override
  String get setTrackingSheetsAmountToAdjustWeight => '무게 조정량';

  @override
  String get setTrackingSheetsDropSet => '드롭 세트';

  @override
  String get setTrackingSheetsExerciseHistory => '운동 기록';

  @override
  String get setTrackingSheetsGotIt => '확인';

  @override
  String get setTrackingSheetsImmediatelyReduceWeightAfte =>
      '실패 지점 도달 후 즉시 무게를 줄이고 계속 운동하세요. 근성장에 효과적입니다!';

  @override
  String get setTrackingSheetsLastSession => '지난 세션';

  @override
  String get setTrackingSheetsLightWeightToPrepare =>
      '근육 준비를 위한 가벼운 무게입니다. 운동 볼륨에는 포함되지 않습니다.';

  @override
  String get setTrackingSheetsMarkWhenYouCouldn =>
      '목표 횟수를 완료하지 못했을 때 표시하세요. 강도를 추적하는 데 도움이 됩니다.';

  @override
  String get setTrackingSheetsPersonalRecord => '개인 최고 기록 (PR)';

  @override
  String get setTrackingSheetsRateOfPerceivedExertion =>
      'RPE(자각 인지 강도)는 세트의 강도를 측정합니다:';

  @override
  String get setTrackingSheetsReps => '횟수';

  @override
  String get setTrackingSheetsSaveTarget => '목표 저장';

  @override
  String get setTrackingSheetsSetTarget => '목표 설정';

  @override
  String get setTrackingSheetsSetTypes => '세트 유형';

  @override
  String get setTrackingSheetsTargetRir => '목표 RIR';

  @override
  String get setTrackingSheetsWarmup => '웜업';

  @override
  String get setTrackingSheetsWeightIncrement => '중량 증분';

  @override
  String get setTrackingSheetsWeightKg => '중량 (kg)';

  @override
  String get setTrackingSheetsWeightLbs => '중량 (lbs)';

  @override
  String get setTrackingSheetsWhatIsRpe => 'RPE란 무엇인가요?';

  @override
  String get setTrackingTableALowerRir0 =>
      '낮은 RIR(0–1)은 한계까지 밀어붙였음을 의미합니다. 높은 RIR(4–6 이상)은 세트가 비교적 쉬웠고 여력이 충분했음을 의미합니다.';

  @override
  String get setTrackingTableALowerRir02 =>
      '낮은 RIR(0–1)은 한계에 가깝게 밀어붙였음을 의미합니다. 높은 RIR(3–4)은 더 수행할 수 있는 여력이 있었음을 의미합니다.';

  @override
  String get setTrackingTableAddSet => '세트 추가';

  @override
  String get setTrackingTableBeginnersGetExtraBuffer =>
      '초보자는 자세 학습을 위해 추가적인 여유가 필요합니다. 숙련자는 더 안전하게 실패 지점까지 밀어붙일 수 있습니다.';

  @override
  String get setTrackingTableCompoundLiftsSquatsPresse =>
      '복합 관절 운동(스쿼트, 프레스)은 고립 운동(컬, 레이즈)보다 보수적으로 유지합니다. 근비대 훈련은 근력 훈련보다 실패 지점에 더 가깝게 수행합니다.';

  @override
  String get setTrackingTableEasiest => '가장 쉬움';

  @override
  String get setTrackingTableEquipmentSafety => '장비 안전성';

  @override
  String get setTrackingTableHardest => '가장 힘듦';

  @override
  String get setTrackingTableHowYourTargetRir => '목표 RIR 계산 방식';

  @override
  String get setTrackingTableLeft => '왼쪽';

  @override
  String get setTrackingTableMachinesCablesAreSafer =>
      '머신과 케이블은 강도 높게 훈련하기에 더 안전합니다. 바벨과 케틀벨은 부상 위험 때문에 더 많은 여유가 필요합니다.';

  @override
  String get setTrackingTableManyRepsInReserve => '많은 반복 횟수 여유';

  @override
  String get setTrackingTableNoRepsInReserve => '반복 횟수 여유 없음';

  @override
  String setTrackingTablePartSetNumberBadgeRir(Object previousRir) {
    return 'RIR $previousRir';
  }

  @override
  String setTrackingTablePartSetNumberBadgeRir2(Object displayRir) {
    return 'RIR $displayRir';
  }

  @override
  String get setTrackingTablePrevious => '이전';

  @override
  String get setTrackingTableRight => '오른쪽';

  @override
  String get setTrackingTableRirDecreasesAcrossSets =>
      '세트가 진행될수록 RIR은 감소합니다. 마지막 세트에서 가장 강도 높게 수행하고 이전 세트들은 빌드업합니다.';

  @override
  String get setTrackingTableRirStandsForReps =>
      'RIR은 Reps in Reserve의 약자로, 세트가 얼마나 힘들었는지 나타내는 간단한 방법입니다.';

  @override
  String get setTrackingTableSet => '세트';

  @override
  String get setTrackingTableTarget => '목표';

  @override
  String get setTrackingTableTrainingGoalExerciseType => '훈련 목표 + 운동 유형';

  @override
  String get setTrackingTableWhatIsRir => 'RIR이란 무엇인가요?';

  @override
  String get setTrackingTableWhatYouSeeAbove => '위에서 보시는 것은 RIR 척도입니다';

  @override
  String get setTrackingTableYouAreNotRequired =>
      'RIR을 반드시 기록할 필요는 없지만 강력히 권장합니다. 실패 지점과의 거리를 이해하면 앱이 현재 근력 수준과 피로도를 더 잘 파악할 수 있습니다.';

  @override
  String get setTrackingTableYourFitnessLevel => '당신의 피트니스 레벨';

  @override
  String get setTrackingTableYourRirTargetIs =>
      '당신의 목표 RIR은 세 가지 요소를 사용하여 개인화됩니다:';

  @override
  String get settings24UpcomingFeatures => '24가지 예정된 기능';

  @override
  String get settingsAboutSection => '정보';

  @override
  String get settingsAccount => '계정';

  @override
  String get settingsAccountSection => '계정';

  @override
  String get settingsAppSection => '앱';

  @override
  String get settingsAppearance => '테마';

  @override
  String get settingsAppleHealth => 'Apple Health';

  @override
  String get settingsBeastMode => '비스트 모드';

  @override
  String settingsCardAvoided(Object length) {
    return '$length개 제외됨';
  }

  @override
  String settingsCardBodyWorkout(Object bodyUnit, Object workoutUnit) {
    return '신체 $bodyUnit · 운동 $workoutUnit';
  }

  @override
  String get settingsCardChangingDaysWillReschedule =>
      '요일을 변경하면 예정된 운동 일정이 자동으로 다시 조정됩니다.';

  @override
  String settingsCardExercises(Object length) {
    return '운동 $length개';
  }

  @override
  String settingsCardExercises2(Object length) {
    return '운동 $length개';
  }

  @override
  String get settingsCardFailedToUpdate => '업데이트 실패';

  @override
  String get settingsCardHowMuchExerciseVariety => '매주 얼마나 다양한 운동을 하시겠습니까?';

  @override
  String settingsCardLifts(Object length) {
    return '리프트 $length개';
  }

  @override
  String get settingsCardMonday => '월요일';

  @override
  String settingsCardNDaysSelected(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n일 선택됨',
      one: '1일 선택됨',
    );
    return '$_temp0';
  }

  @override
  String get settingsCardNoChanges => '변경 사항 없음';

  @override
  String settingsCardPartAccentColorGridLvl(Object unlockLevel) {
    return '레벨 $unlockLevel';
  }

  @override
  String settingsCardPartAccentColorGridSelected(Object length) {
    return '$length개 선택됨';
  }

  @override
  String settingsCardPartAccentColorGridUnlocksAtLevelKeep(Object unlockLevel) {
    return '레벨 $unlockLevel에서 잠금 해제됩니다 — 계속 힘내세요!';
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
      '요일을 변경하면 예정된 운동이 자동으로 재조정됩니다.';

  @override
  String get settingsCardPartClearAll => '모두 지우기';

  @override
  String get settingsCardPartForLearning => '학습용';

  @override
  String get settingsCardPartFri => '금';

  @override
  String get settingsCardPartFriday => '금요일';

  @override
  String get settingsCardPartMon => '월';

  @override
  String get settingsCardPartMonday => '월요일';

  @override
  String get settingsCardPartMyEquipment => '내 장비';

  @override
  String get settingsCardPartNoChanges => '변경 없음';

  @override
  String get settingsCardPartRecommended => '권장';

  @override
  String get settingsCardPartSat => '토';

  @override
  String get settingsCardPartSaturday => '토요일';

  @override
  String get settingsCardPartSaveChanges => '변경사항 저장';

  @override
  String get settingsCardPartSaveEquipment => '장비 저장';

  @override
  String get settingsCardPartSearchEquipment => '장비 검색...';

  @override
  String get settingsCardPartSelectAllEquipmentYou => '사용 가능한 모든 장비를 선택하세요';

  @override
  String get settingsCardPartSelectWhichDaysYou => '운동할 요일을 선택하세요';

  @override
  String get settingsCardPartSun => '일';

  @override
  String get settingsCardPartSunday => '일요일';

  @override
  String get settingsCardPartThu => '목';

  @override
  String get settingsCardPartThursday => '목요일';

  @override
  String get settingsCardPartTue => '화';

  @override
  String get settingsCardPartTuesday => '화요일';

  @override
  String get settingsCardPartWed => '수';

  @override
  String get settingsCardPartWednesday => '수요일';

  @override
  String get settingsCardPartWorkoutDays => '운동 요일';

  @override
  String get settingsCardPleaseSelectAtLeastOne => '최소 하루 이상의 운동 요일을 선택해 주세요';

  @override
  String settingsCardQueued(Object length) {
    return '대기 중 $length개';
  }

  @override
  String get settingsCardSaveChanges => '변경 사항 저장';

  @override
  String get settingsCardSelectWhichDaysYou => '운동할 요일을 선택하세요';

  @override
  String get settingsCardSunday => '일요일';

  @override
  String get settingsCardUiAccentColor => '강조 색상';

  @override
  String get settingsCardUiBodyMeasurements => '신체 치수';

  @override
  String get settingsCardUiBodyWeight => '체중';

  @override
  String get settingsCardUiChooseAnAccentColor => '버튼과 강조 표시에 사용할 색상을 선택하세요';

  @override
  String get settingsCardUiChooseHowToStructure => '주간 운동 구성 방식을 선택하세요';

  @override
  String get settingsCardUiChooseTimezone => '시간대 선택';

  @override
  String get settingsCardUiExerciseConsistency => '운동 일관성';

  @override
  String get settingsCardUiForLoggingLiftsSets => '리프팅, 세트, 운동 중량 기록용';

  @override
  String get settingsCardUiForWaistChestHips => '허리, 가슴, 엉덩이, 팔, 다리 측정용';

  @override
  String get settingsCardUiForWeighingYourselfBmi => '체중 측정 및 BMI 계산용';

  @override
  String get settingsCardUiHowFastShouldWe => '중량을 얼마나 빠르게 증량할까요?';

  @override
  String get settingsCardUiHowHardShouldYour => '운동 강도는 어느 정도로 설정할까요?';

  @override
  String get settingsCardUiHowShouldTheAi => 'AI가 운동을 어떻게 선택하도록 할까요?';

  @override
  String get settingsCardUiProgressionPace => '진행 속도';

  @override
  String get settingsCardUiTrainingIntensity => '운동 강도';

  @override
  String get settingsCardUiTrainingSplit => '운동 분할';

  @override
  String get settingsCardUiUnits => '단위';

  @override
  String get settingsCardUiWeightWorkoutAndBody => '체중, 운동 및 신체 측정 단위';

  @override
  String get settingsCardUiWhatTypeOfWorkouts => '어떤 유형의 운동을 선호하시나요?';

  @override
  String get settingsCardUiWorkoutType => '운동 유형';

  @override
  String get settingsCardUiWorkoutWeight => '운동 중량';

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
    return '동영상 $cachedVideoCount개';
  }

  @override
  String get settingsCardWeeklyVariety => '주간 다양성';

  @override
  String get settingsCardWorkoutDays => '운동 요일';

  @override
  String settingsCardWorkoutDaysUpdatedTo(Object days) {
    return '운동 요일이 $days로 업데이트되었습니다';
  }

  @override
  String get settingsComingSoon => '준비 중';

  @override
  String get settingsConnections => '연동';

  @override
  String get settingsContactSupport => '고객 지원 문의';

  @override
  String get settingsDeleteAccount => '계정 삭제';

  @override
  String get settingsEquipment => '장비';

  @override
  String get settingsExercisePrefs => '운동 설정';

  @override
  String get settingsFavoritesAvoidedQueue => '즐겨찾기, 제외 및 대기열';

  @override
  String get settingsHealthConnect => 'Health Connect';

  @override
  String get settingsHealthDevices => '건강 및 기기';

  @override
  String get settingsHelpSection => '도움말';

  @override
  String get settingsHelpSupport => '도움말 및 지원';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageSubtitle => '선호 언어를 선택하세요';

  @override
  String get settingsLogout => '로그아웃';

  @override
  String get settingsMealReminders => '식사 알림';

  @override
  String get settingsMyGyms => '내 헬스장';

  @override
  String get settingsNutritionSection => '영양';

  @override
  String get settingsPersonalization => '개인화';

  @override
  String get settingsPowerUserTools => '파워 유저 도구';

  @override
  String get settingsPrivacyData => '개인정보 및 데이터';

  @override
  String get settingsPrivacyPolicy => '개인정보 처리방침';

  @override
  String get settingsPrivacySection => '개인정보';

  @override
  String get settingsRateApp => '앱 평가하기';

  @override
  String get settingsRecipeSchedulesSharingV => '레시피 일정 + 공유 + 버전 관리';

  @override
  String get settingsReplayToursOrReset => '투어 다시 보기 또는 인라인 힌트 초기화';

  @override
  String get settingsResearchScience => '연구 및 과학';

  @override
  String settingsScreenAbout(Object appName) {
    return '$appName 정보';
  }

  @override
  String settingsScreenCouldNotOpen(Object url) {
    return '$url을(를) 열 수 없습니다';
  }

  @override
  String get settingsScreenExtANoteFromChetan => 'Chetan의 메시지';

  @override
  String get settingsScreenExtInlineHints => '인라인 힌트';

  @override
  String get settingsScreenExtReplay => '다시 보기';

  @override
  String get settingsScreenExtReplayIndividualTours => '개별 투어 다시 보기';

  @override
  String get settingsScreenExtReplayOnboardingWalkthrough => '온보딩 가이드 다시 보기';

  @override
  String get settingsScreenExtReplayTheOnboardingWalkthro =>
      '온보딩 가이드, 개별 화면 투어를 다시 보거나 인라인 힌트를 초기화합니다.';

  @override
  String get settingsScreenExtResetInlineHints => '인라인 힌트 초기화';

  @override
  String get settingsScreenExtSearchSettings => '설정 검색...';

  @override
  String get settingsScreenExtSmallEmptyStateHints =>
      '앱 곳곳에 있는 작은 빈 상태 힌트입니다. 도움말 텍스트를 다시 보려면 초기화하세요.';

  @override
  String get settingsScreenExtTutorialsHints => '튜토리얼 및 힌트';

  @override
  String settingsScreenExtVersion(Object buildNumber, Object version) {
    return '버전 $version ($buildNumber)';
  }

  @override
  String settingsScreenExtWhyIBuilt(Object appName) {
    return '$appName을 만든 이유';
  }

  @override
  String get settingsScreenExtYourAiPoweredPersonal =>
      'Zealova는 AI 기반 개인 피트니스 코치입니다. 맞춤형 운동 계획을 받고 진행 상황을 추적하여 피트니스 목표를 달성하세요.';

  @override
  String settingsScreenMailtoSubjectSupportRequest(
    Object appName,
    Object supportEmail,
  ) {
    return 'mailto:$supportEmail?subject=$appName 지원 요청';
  }

  @override
  String settingsScreenUBDays(Object daysPerWeek, Object splitName) {
    return '$splitName · $daysPerWeek 일';
  }

  @override
  String get settingsScreenUiNoSettingsFound => '설정을 찾을 수 없습니다';

  @override
  String get settingsScreenUiTryDifferentKeywordsLike =>
      '\"테마\", \"알림\", \"AI 음성\" 같은 다른 키워드로 검색해 보세요';

  @override
  String settingsScreenV(Object appName, Object version) {
    return '$appName v$version';
  }

  @override
  String get settingsSearchSettings => '설정 검색';

  @override
  String get settingsSetProgressionResearch => '진행 및 연구 설정';

  @override
  String get settingsSharingExportEmail => '공유, 내보내기, 이메일';

  @override
  String get settingsSingleLevelWithCrate => '단일 레벨, 상자 보상 포함';

  @override
  String get settingsSoundNotifs => '소리 및 알림';

  @override
  String get settingsSubscription => '구독';

  @override
  String get settingsTermsOfService => '서비스 이용약관';

  @override
  String get settingsTestLevelUpLevel => '레벨업 테스트 (레벨 2→3)';

  @override
  String get settingsTestLevelUpLevel2 => '레벨업 테스트 (레벨 10→11)';

  @override
  String get settingsTestMultiLevel1 => '멀티 레벨 테스트 (1→5)';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsThemeMode => '테마';

  @override
  String get settingsThemeSystem => '시스템';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsTitleChangeBeginnerNovic => '타이틀 변경: 초보자 → 입문자';

  @override
  String get settingsTraining => '트레이닝';

  @override
  String get settingsTrainingMethods => '트레이닝 방법';

  @override
  String get settingsTrainingSection => '트레이닝';

  @override
  String get settingsTutorialsHints => '튜토리얼 및 힌트';

  @override
  String get settingsVoiceAudioReminders => '음성, 오디오, 알림';

  @override
  String get settingsVoicePersonality => '음성 및 개성';

  @override
  String get settingsWithCascadeOverlayDialog => '캐스케이드 오버레이 + 다이얼로그 포함';

  @override
  String get settingsWorkoutMode => '운동 모드';

  @override
  String get settingsWorkoutSettings => '운동 설정';

  @override
  String get shareArtifactCardCopyShare => '복사 및 공유';

  @override
  String get shareableGallerySortDefault => '기본값';

  @override
  String get shareableGallerySortFavorites => '즐겨찾기 먼저';

  @override
  String get shareableGallerySortRecents => '최근순';

  @override
  String get shareableGallerySortTooltip => '템플릿 정렬';

  @override
  String get shareArtifactCardCouldNotCreateShare => '공유 링크를 생성할 수 없습니다.';

  @override
  String get shareArtifactCardOpenInApp => '앱에서 열기';

  @override
  String get shareBodyAnalyzerBodyFat => '체지방';

  @override
  String get shareBodyAnalyzerMuscleMass => '근육량';

  @override
  String get shareBodyAnalyzerShareFailed => '공유 실패';

  @override
  String get shareBodyAnalyzerShareImage => '이미지 공유';

  @override
  String shareBodyAnalyzerSheetBodyAnalyzer(Object appName) {
    return '@$appName · 신체 분석기';
  }

  @override
  String get shareBodyAnalyzerSymmetry => '대칭';

  @override
  String shareBreakdownNExercises(Object count) {
    return '운동 $count개';
  }

  @override
  String shareBreakdownNMore(Object count) {
    return '외 $count개';
  }

  @override
  String shareBreakdownNSets(Object count) {
    return '$count 세트';
  }

  @override
  String get shareBreakdownTodaysLifts => '오늘의 리프트';

  @override
  String get shareCoachWorkoutReview => '코치 운동 리뷰';

  @override
  String get shareInsightsShareReport => '리포트 공유';

  @override
  String shareInsightsSheetMyReport(Object appName, Object periodName) {
    return '내 $appName $periodName 리포트';
  }

  @override
  String shareInsightsSheetMyReport2(Object appName) {
    return '내 $appName 리포트';
  }

  @override
  String get shareMotivationalCompleted => '완료';

  @override
  String get sharePrNewPr => '신기록 PR';

  @override
  String get shareStatsCalories => '칼로리';

  @override
  String get shareStatsDuration => '운동 시간';

  @override
  String get shareStatsEliteTemplate => 'ELITE 템플릿';

  @override
  String get shareStatsExercises => '운동';

  @override
  String get shareStatsInstagram => 'Instagram';

  @override
  String get shareStatsLogAWorkoutTo => '운동을 기록하고 공유 템플릿을 잠금 해제하세요.';

  @override
  String get shareStatsSaveOnly => '저장만 하기';

  @override
  String get shareStatsShareYourStats => '통계 공유하기';

  @override
  String shareStatsSheetUnlocksAtLevelLevels(Object levelsToGo) {
    return '레벨 75에서 잠금 해제 · $levelsToGo 레벨 남음';
  }

  @override
  String get shareStatsShowWatermark => '워터마크 표시';

  @override
  String get shareStatsVolume => '볼륨';

  @override
  String get shareStatsWorkoutComplete => '운동 완료';

  @override
  String get shareStrengthFocusAreas => '집중 영역';

  @override
  String get shareStrengthInstagram => 'Instagram';

  @override
  String get shareStrengthMuscleBreakdown => '근육 분석';

  @override
  String get shareStrengthSaveToGallery => '갤러리에 저장';

  @override
  String get shareStrengthShareStrength => '근력 공유';

  @override
  String shareStrengthSheetMuscleGroups(Object length) {
    return '근육 그룹 $length개';
  }

  @override
  String get shareStrengthShowWatermark => '워터마크 표시';

  @override
  String get shareStrengthStrengthScore => '근력 점수';

  @override
  String get shareStrengthTopMuscles => '주요 근육';

  @override
  String get shareStrengthTopScores => '최고 점수';

  @override
  String get shareTemplateInstagram => 'Instagram';

  @override
  String get shareTemplateSaveOnly => '저장만 하기';

  @override
  String get shareTemplateShowWatermark => '워터마크 표시';

  @override
  String get shareWeeklySummaryShareYourWeek => '이번 주 활동 공유';

  @override
  String shareWeeklySummarySheetMyWeek(Object appName, Object dateRange) {
    return '나의 $appName 주간 기록 — $dateRange';
  }

  @override
  String shareWeeklySummarySheetMyWeeklyReport(Object appName) {
    return '나의 $appName 주간 리포트';
  }

  @override
  String get shareWorkoutAddYourPhoto => '사진 추가';

  @override
  String get shareWorkoutAiCaption => 'AI 캡션';

  @override
  String get shareWorkoutChangePhoto => '사진 변경';

  @override
  String get shareWorkoutEditImage => '이미지 편집';

  @override
  String get shareWorkoutInstagram => 'Instagram';

  @override
  String get shareWorkoutSaveOnly => '저장만 하기';

  @override
  String get shareWorkoutShareYourWorkout => '운동 공유';

  @override
  String get shareWorkoutSheetBrightness => '밝기';

  @override
  String get shareWorkoutSheetContrast => '대비';

  @override
  String shareWorkoutSheetCopied(Object caption) {
    return '복사됨: \"$caption\"';
  }

  @override
  String get shareWorkoutSheetEditImage => '이미지 편집';

  @override
  String shareWorkoutSheetPartSimplePhotoEditorFailedToShare(Object e) {
    return '공유 실패: $e';
  }

  @override
  String get shareWorkoutSheetPinchToZoomTap => '핀치로 확대 • 아무 곳이나 탭하여 닫기';

  @override
  String get shareWorkoutSheetReset => '재설정';

  @override
  String get shareWorkoutSheetTapToPreview => '탭하여 미리보기';

  @override
  String get shareWorkoutShowWatermark => '워터마크 표시';

  @override
  String get shareWorkoutWriting => '작성 중...';

  @override
  String get sharedWorkoutDetailAcceptChallenge => '챌린지 수락';

  @override
  String get sharedWorkoutDetailExerciseDetailsNotAvailable =>
      '운동 상세 정보를 사용할 수 없습니다';

  @override
  String get sharedWorkoutDetailScheduleForLater => '나중에 하기';

  @override
  String sharedWorkoutDetailScreenBy(Object _actionVerb, Object posterName) {
    return '$posterName님이 $_actionVerb';
  }

  @override
  String sharedWorkoutDetailScreenExercises(Object _exercises) {
    return '운동 $_exercises개';
  }

  @override
  String sharedWorkoutDetailScreenMin(Object _duration) {
    return '$_duration분';
  }

  @override
  String get sharedWorkoutDetailStarting => '시작 중...';

  @override
  String get sharedWorkoutDetailU2022 => '  •  ';

  @override
  String get sharedWorkoutDetailWorkoutDetails => '운동 상세 정보';

  @override
  String get signInReady => '준비 완료';

  @override
  String signInScreenSupportIsNowYour(Object appName) {
    return '$appName 지원팀이 여러분의 친구가 되어드립니다. 언제든 도움이 필요하면 연락주세요!';
  }

  @override
  String signInScreenValue(Object progressPercent) {
    return '$progressPercent%';
  }

  @override
  String signInScreenWelcomeTo(Object appName) {
    return '$appName에 오신 것을 환영합니다!';
  }

  @override
  String signInScreenYourPlanDaysWeek(Object goalDisplay, Object quizData) {
    return '$goalDisplay 플랜 · 주 $quizData일';
  }

  @override
  String get signInSigningIn => '로그인 중...';

  @override
  String skillProgressSummaryCardTotalPracticeSessions(Object totalAttempts) {
    return '총 $totalAttempts회의 연습 세션';
  }

  @override
  String get skillProgressSummaryMastered => '마스터함';

  @override
  String get skillProgressSummarySkillsStarted => '시작한 스킬';

  @override
  String get skillProgressSummaryStepsUnlocked => '잠금 해제된 단계';

  @override
  String get skillProgressSummaryYourProgress => '나의 진행 상황';

  @override
  String get skillProgressionsActiveProgressions => '진행 중인 스킬';

  @override
  String get skillProgressionsAllSkills => '모든 스킬';

  @override
  String get skillProgressionsBrowseSkills => '스킬 탐색';

  @override
  String get skillProgressionsChooseASkillProgression =>
      '스킬 단계를 선택하여 맨몸 운동을 단계별로 마스터하세요.';

  @override
  String get skillProgressionsDiscoverMoreSkills => '더 많은 스킬 발견하기';

  @override
  String get skillProgressionsMasterBodyweightSkillsStep =>
      '맨몸 운동 스킬을 단계별로 마스터하세요';

  @override
  String get skillProgressionsMyProgress => '나의 진행 상황';

  @override
  String get skillProgressionsNoSkillsInThis => '이 카테고리에 스킬이 없습니다';

  @override
  String get skillProgressionsSkillProgressions => '스킬 단계';

  @override
  String get skillProgressionsSomethingWentWrong => '문제가 발생했습니다';

  @override
  String get skillProgressionsStartYourJourney => '여정 시작하기';

  @override
  String get skillProgressionsTryAgain => '다시 시도';

  @override
  String get skillsMasterBodyweightSkillsStep =>
      '가이드가 포함된 단계별 과정을 통해 맨몸 운동 스킬을 마스터하세요.';

  @override
  String get skillsSkillProgressions => '스킬 단계';

  @override
  String sleepCorrelationCardPairedSessionsR(Object n, Object r) {
    return '$n개의 페어링된 세션 · r=$r';
  }

  @override
  String get sleepCorrelationCardSleepPace => '수면 × 페이스';

  @override
  String get sleepDetail30DayTrend => '30일 추세';

  @override
  String get sleepDetailAvgNight => '일일 평균';

  @override
  String get sleepDetailBestNight => '최고의 수면';

  @override
  String get sleepDetailCoachingTips => '코칭 팁';

  @override
  String get sleepDetailConnectHealth => '건강 앱 연결';

  @override
  String get sleepDetailConnectHealthToSee => '건강 앱을 연결하여 수면 데이터를 확인하세요';

  @override
  String get sleepDetailCouldNotLoadSleep =>
      '수면 데이터를 불러올 수 없습니다. 아래로 당겨 다시 시도하세요.';

  @override
  String get sleepDetailCouldNotSaveSleep => '수면 목표를 저장할 수 없습니다.';

  @override
  String get sleepDetailCustomTrends => '맞춤 추세';

  @override
  String get sleepDetailDebtRegularity => '수면 부채 및 규칙성';

  @override
  String get sleepDetailEfficiency => '효율성';

  @override
  String get sleepDetailFellAsleepIn => '입면 시간';

  @override
  String get sleepDetailLast7Nights => '지난 7일';

  @override
  String get sleepDetailMonthlySummary => '월간 요약';

  @override
  String get sleepDetailNap => '낮잠';

  @override
  String get sleepDetailNightsWithNaps => '낮잠을 잔 밤';

  @override
  String get sleepDetailNoSleepTrackedIn => '지난 7일간 기록된 수면이 없습니다.';

  @override
  String get sleepDetailRegularity => '규칙성';

  @override
  String get sleepDetailSaving => '저장 중...';

  @override
  String sleepDetailScreenAcrossTrackedNights(Object nightCount) {
    return '총 $nightCount일의 수면 기록.';
  }

  @override
  String sleepDetailScreenHM(Object summary, Object summary1) {
    return '$summary시간 $summary1분';
  }

  @override
  String sleepDetailScreenHM2(Object summary, Object summary1) {
    return '$summary시간 $summary1분';
  }

  @override
  String sleepDetailScreenHM3(Object summary, Object summary1) {
    return '$summary시간 $summary1분';
  }

  @override
  String sleepDetailScreenMin(Object latencyMinutes) {
    return '$latencyMinutes 분';
  }

  @override
  String sleepDetailScreenNaps(Object length) {
    return '$length 회 낮잠';
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
  String get sleepDetailShortestNight => '최단 수면';

  @override
  String get sleepDetailSleep => '수면';

  @override
  String get sleepDetailSleepDebt14d => '수면 부채 (14일)';

  @override
  String get sleepDetailSleepGoal => '수면 목표';

  @override
  String get sleepDetailTrendUnavailable => '추세를 사용할 수 없습니다.';

  @override
  String get sleepDetailTwoOrMoreSynced =>
      '추세를 차트로 보려면 2일 이상의 동기화된 수면 데이터가 필요합니다.';

  @override
  String get sleepHypnogramAwake => '깨어 있음';

  @override
  String get sleepHypnogramDeep => '깊은 수면';

  @override
  String get slowLoadIndicatorTryAgain => '다시 시도';

  @override
  String smartInsightCardDays(Object n) {
    return '$n일';
  }

  @override
  String get smartInsightCardSmartInsight => '스마트 인사이트';

  @override
  String get snappedEquipmentCouldnTReuseThat =>
      '해당 스냅을 재사용할 수 없습니다. 다시 시도하세요.';

  @override
  String get snappedEquipmentNoMatchingExercisesFor => '이 장비와 일치하는 운동이 없습니다.';

  @override
  String get snappedEquipmentNoSnappedEquipmentYet => '아직 스냅된 장비가 없습니다';

  @override
  String get snappedEquipmentTapTheCameraButton => '카메라 버튼을 눌러 눈앞의 장비를 식별하세요.';

  @override
  String get socialAutoScrollFeed => '피드 자동 스크롤';

  @override
  String get socialAutoScrollStories => '스토리 자동 스크롤';

  @override
  String get socialFeedOptions => '피드 옵션';

  @override
  String get socialFindFriends => '친구 찾기';

  @override
  String get socialMessages => '메시지';

  @override
  String get socialMyPostsOnly => '내 게시물만 보기';

  @override
  String get socialPrivacyAllowChallengeInvites => '챌린지 초대 허용';

  @override
  String get socialPrivacyAllowFriendRequests => '친구 요청 허용';

  @override
  String get socialPrivacyAllowGeneratingShareableWor =>
      '누구나 열 수 있는 운동 공유 URL 생성 허용';

  @override
  String get socialPrivacyAppearInPublicAnd => '공개 및 친구 리더보드에 표시';

  @override
  String get socialPrivacyChallengeInvites => '챌린지 초대';

  @override
  String get socialPrivacyComments => '댓글';

  @override
  String get socialPrivacyFriendActivity => '친구 활동';

  @override
  String get socialPrivacyFriendRequests => '친구 요청';

  @override
  String get socialPrivacyLetOthersInviteYou => '다른 사용자가 나를 챌린지에 초대하도록 허용';

  @override
  String get socialPrivacyLetOthersSeeWhen => '다른 사용자가 내 메시지 읽음 여부를 확인하도록 허용';

  @override
  String get socialPrivacyLetOthersSendYou => '다른 사용자가 나에게 친구 요청을 보내도록 허용';

  @override
  String get socialPrivacyPrivateAccount => '비공개 계정';

  @override
  String get socialPrivacyPublicShareLinks => '공개 공유 링크';

  @override
  String get socialPrivacyReactions => '반응';

  @override
  String get socialPrivacyReadReceipts => '읽음 확인';

  @override
  String get socialPrivacyRequireApprovalForFollow => '팔로우 요청 승인 필요';

  @override
  String get socialPrivacyShowOnLeaderboards => '리더보드에 표시';

  @override
  String get socialPrivacySocialNotifications => '소셜 알림';

  @override
  String get socialPrivacySocialPrivacy => '소셜 및 개인정보 보호';

  @override
  String get socialPrivacyWhenFriendsCompleteWorkouts =>
      '친구가 운동을 완료하거나 목표를 달성했을 때';

  @override
  String get socialPrivacyWhenSomeoneCommentsOn => '누군가 내 게시물에 댓글을 달았을 때';

  @override
  String get socialPrivacyWhenSomeoneInvitesYou => '누군가 나를 챌린지에 초대했을 때';

  @override
  String get socialPrivacyWhenSomeoneReactsTo => '누군가 내 게시물에 반응했을 때';

  @override
  String get socialPrivacyWhenSomeoneSendsYou => '누군가 나에게 친구 요청을 보냈을 때';

  @override
  String get socialRanks => '랭크';

  @override
  String get socialScreenPartEnterAGroupName => '그룹 이름을 입력하고 최소 2명의 멤버를 선택하세요';

  @override
  String get socialScreenPartFailedToCreateGroup => '그룹 생성 실패';

  @override
  String get socialScreenPartFailedToLoad => '불러오기 실패';

  @override
  String get socialScreenPartFailedToLoadFriends => '친구 목록 불러오기 실패';

  @override
  String get socialScreenPartFailedToStartConversation => '대화 시작 실패';

  @override
  String get socialScreenPartGroupName => '그룹 이름';

  @override
  String get socialScreenPartMessages => '메시지';

  @override
  String socialScreenPartMessagesScreenGroupCreated(Object name) {
    return '그룹 \"$name\" 생성됨';
  }

  @override
  String socialScreenPartMessagesScreenSelectMembersSelected(Object length) {
    return '멤버 선택 ($length개 선택됨)';
  }

  @override
  String get socialScreenPartNewGroup => '새 그룹';

  @override
  String get socialScreenPartNewMessage => '새 메시지';

  @override
  String get socialScreenPartNoConversationsFound => '대화 내역이 없습니다';

  @override
  String get socialScreenPartNoFriendsToAdd => '추가할 친구가 없습니다';

  @override
  String get socialScreenPartNoFriendsToMessage => '메시지를 보낼 친구가 없습니다';

  @override
  String get socialScreenPartNotLoggedIn => '로그인되지 않음';

  @override
  String get socialSocial => '소셜';

  @override
  String get socialSortBy => '정렬 기준';

  @override
  String get socialSortRecent => '최신순';

  @override
  String get socialSortTop => '인기순';

  @override
  String get socialSortTrending => '트렌드';

  @override
  String get socialUserIdCopied => '사용자 ID 복사됨';

  @override
  String socialUsernameCopied(Object username) {
    return '사용자 이름 복사됨: @$username';
  }

  @override
  String get sortOptionsClear => '지우기';

  @override
  String get sortOptionsHighLow => '높은 순 → 낮은 순';

  @override
  String get sortOptionsLowHigh => '낮은 순 → 높은 순';

  @override
  String get sortOptionsRemoveFromSort => '정렬에서 제거';

  @override
  String get sortOptionsSortMenu => '정렬 메뉴';

  @override
  String get sortOptionsTapAFieldTo => '정렬할 항목을 탭하세요.';

  @override
  String get soundNotificationsSoundNotifications => '사운드 및 알림';

  @override
  String get soundSettingsCountdownSounds => '카운트다운 사운드';

  @override
  String get soundSettingsCustomizeWorkoutSounds => '운동 사운드 사용자 지정';

  @override
  String get soundSettingsExerciseCompletion => '운동 완료';

  @override
  String get soundSettingsPlaySoundWhenAll => '운동의 모든 세트 완료 시 사운드 재생';

  @override
  String get soundSettingsPlaySoundWhenEntire => '전체 운동 종료 시 사운드 재생';

  @override
  String get soundSettingsPlaySoundWhenRest => '휴식 시간 종료 시 사운드 재생';

  @override
  String get soundSettingsPlaySoundsDuringCountdown =>
      '카운트다운(3, 2, 1) 중 사운드 재생';

  @override
  String get soundSettingsRestTimerEnd => '휴식 타이머 종료';

  @override
  String get soundSettingsSound => '사운드';

  @override
  String get soundSettingsSoundEffects => '효과음';

  @override
  String get soundSettingsSoundVolume => '사운드 볼륨';

  @override
  String get soundSettingsTapToSelectLong => '탭하여 선택하세요. 길게 누르면 미리듣기가 가능합니다.';

  @override
  String get soundSettingsWorkoutCompletion => '운동 완료';

  @override
  String get splitsChartSplits => '스플릿';

  @override
  String stackedBannerPanelCrateOpenedYouGot(Object rewardName) {
    return '🎁 상자를 열었습니다! $rewardName 획득';
  }

  @override
  String stackedBannerPanelCratesAvailable(Object displayCount) {
    return '사용 가능한 상자 $displayCount개!';
  }

  @override
  String stackedBannerPanelCratesReadyToOpen(Object displayCount) {
    return '열 수 있는 상자 $displayCount개';
  }

  @override
  String get stackedBannerPanelDismissAll => '모두 닫기';

  @override
  String get stackedBannerPanelDismissAnyway => '닫기';

  @override
  String get stackedBannerPanelFailedToClaimCrate => '상자 수령 실패';

  @override
  String get stackedBannerPanelFollowUsOnInstagram => 'Instagram에서 팔로우하세요';

  @override
  String get stackedBannerPanelGetHelpShareWins =>
      'Discord에서 도움을 받고, 성과를 공유하고, 기능을 요청하세요';

  @override
  String get stackedBannerPanelJoinTheCommunity => '커뮤니티 참여하기';

  @override
  String get stackedBannerPanelKeepItUp => '계속 힘내세요!';

  @override
  String stackedBannerPanelLbs(Object exerciseName, Object weightLbs) {
    return '$exerciseName: $weightLbs lbs';
  }

  @override
  String stackedBannerPanelMinExercises(
    Object durationMinutes,
    Object exercisesCount,
    Object missedDescription,
  ) {
    return '$missedDescription · $durationMinutes분 · 운동 $exercisesCount개';
  }

  @override
  String get stackedBannerPanelNewPr => '새로운 PR!';

  @override
  String get stackedBannerPanelNoCratesAvailableRight => '현재 사용 가능한 상자가 없습니다';

  @override
  String get stackedBannerPanelOpenAll => '모두 열기';

  @override
  String get stackedBannerPanelOpenThemBeforeDismissing => '닫기 전에 상자를 열까요?';

  @override
  String get stackedBannerPanelOpeningCrate => '상자 여는 중...';

  @override
  String stackedBannerPanelRenewsInDaysFor(
    Object days,
    Object formattedAmount,
    Object tierLabel,
  ) {
    return '$tierLabel $days일 후 $formattedAmount에 갱신';
  }

  @override
  String get stackedBannerPanelSubscriptionRenewing => '구독 갱신 중';

  @override
  String get stackedBannerPanelTapToRevisitYour => '탭하여 나의 짐 퍼스널리티를 다시 확인하세요';

  @override
  String stackedBannerPanelValue(Object eventName, Object timeStr) {
    return '$eventName · $timeStr';
  }

  @override
  String stackedBannerPanelWorkoutTipsMealIdeas(Object marketingDomain) {
    return '운동 팁, 식단 아이디어, 커뮤니티 하이라이트 @$marketingDomain';
  }

  @override
  String stackedBannerPanelWorkoutsLifted(
    Object totalWorkouts,
    Object volumeStr,
  ) {
    return '운동 $totalWorkouts회 · $volumeStr 중량';
  }

  @override
  String stackedBannerPanelWrapped(Object period) {
    return '/wrapped/$period';
  }

  @override
  String stackedBannerPanelWrapped2(Object month) {
    return '$month Wrapped';
  }

  @override
  String stackedBannerPanelWrapped3(Object period) {
    return '/wrapped/$period';
  }

  @override
  String stackedBannerPanelXXpActive(Object xpMultiplier) {
    return '${xpMultiplier}x XP 활성화';
  }

  @override
  String get stackedBannerPanelYouHaveUnopenedCrates => '열지 않은 상자가 있습니다!';

  @override
  String stackedBannerPanelYouReAwayFrom(Object remaining, Object workoutWord) {
    return '주간 목표까지 $workoutWord $remaining개 남았습니다';
  }

  @override
  String stackedBannerPanelYourWrappedIsHere(Object month) {
    return '$month Wrapped가 도착했습니다';
  }

  @override
  String get stapleChoiceAddAs => '추가하기';

  @override
  String get stapleChoiceAdvancedOptional => '고급 (선택 사항)';

  @override
  String get stapleChoiceAllProfiles => '모든 프로필';

  @override
  String get stapleChoiceBand => '밴드';

  @override
  String get stapleChoiceCustom => '사용자 지정';

  @override
  String get stapleChoiceCustomizeOptional => '사용자 지정 (선택 사항)';

  @override
  String get stapleChoiceDiscard => '취소';

  @override
  String get stapleChoiceDiscardSelection => '선택을 취소할까요?';

  @override
  String get stapleChoiceDistance => '거리';

  @override
  String get stapleChoiceDotsYourWorkoutDays => '점 = 운동하는 날';

  @override
  String get stapleChoiceDuration => '시간';

  @override
  String get stapleChoiceEGFocusOn => '예: 상단에서 쥐어짜기, 천천히 이완하기';

  @override
  String get stapleChoiceEveryDay => '매일';

  @override
  String get stapleChoiceGoBack => '뒤로 가기';

  @override
  String get stapleChoiceHoldDuration => '유지 시간';

  @override
  String get stapleChoiceIncline => '경사도';

  @override
  String get stapleChoiceMoreOptional => '더 보기 (선택 사항)';

  @override
  String get stapleChoiceNextWorkout => '다음 운동';

  @override
  String get stapleChoiceNotes => '메모';

  @override
  String get stapleChoiceReplaceAnExerciseIn => '오늘 운동의 운동 하나를 교체하세요';

  @override
  String get stapleChoiceReps => '횟수';

  @override
  String get stapleChoiceRest => '휴식';

  @override
  String get stapleChoiceRpeEffort => 'RPE (강도)';

  @override
  String get stapleChoiceSets => '세트';

  @override
  String get stapleChoiceSheetCardioSettings => '유산소 설정';

  @override
  String get stapleChoiceSheetCouldNotLoadWorkout => '운동을 불러올 수 없습니다';

  @override
  String get stapleChoiceSheetDistance => '거리';

  @override
  String get stapleChoiceSheetDuration => '시간';

  @override
  String get stapleChoiceSheetIncline => '경사도';

  @override
  String get stapleChoiceSheetNoExercisesInWorkout => '운동에 포함된 운동이 없습니다';

  @override
  String get stapleChoiceSheetNoWorkoutAvailable => '사용 가능한 운동이 없습니다';

  @override
  String get stapleChoiceSheetResistance => '저항';

  @override
  String get stapleChoiceSheetSpeed => '속도';

  @override
  String get stapleChoiceSheetStrokeRate => '스트로크 속도';

  @override
  String get stapleChoiceSpeed => '속도';

  @override
  String get stapleChoiceSwapWithExercise => '운동 교체';

  @override
  String get stapleChoiceTargetDays => '목표 요일';

  @override
  String get stapleChoiceTempo => '템포';

  @override
  String get stapleChoiceWeight => '무게';

  @override
  String get stapleChoiceWhenToApply => '적용 시기';

  @override
  String get stapleChoiceWhichGymProfile => '어떤 짐 프로필인가요?';

  @override
  String get stapleChoiceWorkoutDays => '운동 요일';

  @override
  String get stapleChoiceYourExerciseWonT => '운동이 스테이플로 저장되지 않습니다.';

  @override
  String get stapleExercisesBikeSettings => '바이크 설정';

  @override
  String get stapleExercisesCardioSettings => '유산소 설정';

  @override
  String get stapleExercisesDuration => '시간';

  @override
  String get stapleExercisesDurationSetsRest => '시간 / 세트 / 휴식';

  @override
  String get stapleExercisesEG812 => '예: 8-12';

  @override
  String get stapleExercisesEllipticalSettings => '일립티컬 설정';

  @override
  String get stapleExercisesHighlightedYourWorkoutDay => '강조 표시 = 운동하는 날';

  @override
  String get stapleExercisesIncline => '경사도';

  @override
  String get stapleExercisesRemove => '삭제';

  @override
  String get stapleExercisesRemoveStaple => '스테이플을 삭제할까요?';

  @override
  String get stapleExercisesReps => '횟수';

  @override
  String get stapleExercisesResistance => '저항';

  @override
  String get stapleExercisesRest => '휴식';

  @override
  String get stapleExercisesRowerSettings => '로잉머신 설정';

  @override
  String get stapleExercisesSaveChanges => '변경 사항 저장';

  @override
  String stapleExercisesScreenAddedAsAStaple(Object exerciseName) {
    return '\"$exerciseName\"이(가) 기본 운동으로 추가되었습니다';
  }

  @override
  String stapleExercisesScreenAddedAsAStaple2(Object name) {
    return '\"$name\"을(를) 고정 운동으로 추가했습니다';
  }

  @override
  String get stapleExercisesScreenAllProfiles => '모든 프로필';

  @override
  String stapleExercisesScreenEdit(Object exerciseName) {
    return '\"$exerciseName\" 편집';
  }

  @override
  String stapleExercisesScreenIsAlreadyAStaple(Object name) {
    return '\"$name\"은(는) 이미 고정 운동입니다';
  }

  @override
  String get stapleExercisesScreenRemove => '삭제';

  @override
  String stapleExercisesScreenRemoveFromYourStaples(Object exerciseName) {
    return '\"$exerciseName\"을(를) 고정 운동에서 삭제할까요? 향후 운동 루틴에서 제외될 수 있습니다.';
  }

  @override
  String get stapleExercisesScreenStretch => '스트레칭';

  @override
  String stapleExercisesScreenUpdated(Object exerciseName) {
    return '\"$exerciseName\" 업데이트 완료';
  }

  @override
  String get stapleExercisesScreenWarmup => '웜업';

  @override
  String get stapleExercisesSection => '섹션';

  @override
  String get stapleExercisesSets => '세트';

  @override
  String get stapleExercisesSpeed => '속도';

  @override
  String get stapleExercisesStapleExercises => '스테이플 운동';

  @override
  String get stapleExercisesStrokeRate => '스트로크 속도';

  @override
  String get stapleExercisesTargetDays => '목표 요일';

  @override
  String get stapleExercisesTheseCoreLiftsWill =>
      '이 핵심 운동들은 다양성 설정과 관계없이 운동 루틴에서 절대 빠지지 않습니다.';

  @override
  String get stapleExercisesTreadmillSettings => '트레드밀 설정';

  @override
  String get stapleExercisesWeight => '무게';

  @override
  String get stapleExercisesWeightSetsRepsRest => '무게 / 세트 / 횟수 / 휴식';

  @override
  String get startFast12h => '12h';

  @override
  String get startFastAdvanced => '고급';

  @override
  String get startFastChooseAPlan => '플랜 선택';

  @override
  String get startFastChooseProtocolStartTime => '프로토콜 및 시작 시간 선택';

  @override
  String get startFastDuration => '기간';

  @override
  String get startFastExtendedFasts24h => '장기 단식 (24시간 이상)';

  @override
  String get startFastOrPickAProtocol => '또는 프로토콜 선택';

  @override
  String startFastSheetHours(Object _customHours) {
    return '$_customHours시간';
  }

  @override
  String get startFastStartAFast => '단식 시작';

  @override
  String get startFastStartFastNow => '지금 단식 시작';

  @override
  String get startFastStartNow => '지금 시작';

  @override
  String get startFastStartTime => '시작 시간';

  @override
  String get statsAchievementsTemplateAchievements => '업적';

  @override
  String get statsAchievementsTemplateAchievementsUnlocked => '잠금 해제된 업적';

  @override
  String get statsAchievementsTemplateDayStreak => '연속 기록';

  @override
  String get statsLevelUpExperience => '경험치';

  @override
  String get statsLevelUpStreak => '연속 기록';

  @override
  String statsOverviewTemplateDayStreak(Object currentStreak) {
    return '$currentStreak일 연속';
  }

  @override
  String get statsOverviewTemplateMyStats => '내 통계';

  @override
  String get statsOverviewTemplateStreak => '연속 기록';

  @override
  String get statsOverviewTemplateThisWeek => '이번 주';

  @override
  String get statsOverviewTemplateTotalTime => '총 시간';

  @override
  String get statsOverviewTemplateWorkouts => '운동';

  @override
  String get statsPrsTemplateKeepPushingToSet => '계속 노력해서 기록을 경신하세요!';

  @override
  String get statsPrsTemplateNoPrsYet => '아직 기록이 없습니다';

  @override
  String get statsPrsTemplatePersonalRecords => '개인 최고 기록';

  @override
  String statsPrsTemplatePrs(Object totalPRCount) {
    return 'PR $totalPRCount개';
  }

  @override
  String get statsRewardsBuildATrend => '트렌드 만들기';

  @override
  String get statsRewardsCollectibles => '수집품';

  @override
  String get statsRewardsCustomTrends => '맞춤형 트렌드';

  @override
  String get statsRewardsInsights => '인사이트';

  @override
  String get statsRewardsInventory => '보관함';

  @override
  String get statsRewardsItems => '아이템';

  @override
  String get statsRewardsLeaderboard => '리더보드';

  @override
  String get statsRewardsOverlayAnyTwoMetrics => '두 가지 지표를 겹쳐서 상관관계를 확인하세요';

  @override
  String get statsRewardsProgress => '진행 상황';

  @override
  String get statsRewardsRecapsPerks => '요약 및 혜택';

  @override
  String get statsRewardsRecognition => '인증';

  @override
  String get statsRewardsRewards => '보상';

  @override
  String get statsRewardsSocial => '소셜';

  @override
  String statsRewardsTabActive(Object activeChains) {
    return '$activeChains개 활성';
  }

  @override
  String statsRewardsTabDone(Object completedChains) {
    return '$completedChains개 완료';
  }

  @override
  String statsRewardsTabEarned(Object achievementsEarned) {
    return '$achievementsEarned개 획득';
  }

  @override
  String statsRewardsTabPrsLastWeek(Object prs) {
    return '지난주 PR $prs개';
  }

  @override
  String statsRewardsTabPts(Object achievementsPoints) {
    return '$achievementsPoints점';
  }

  @override
  String statsRewardsTabReady(Object unclaimedRewards) {
    return '$unclaimedRewards개 준비됨';
  }

  @override
  String statsRewardsTabWorkouts(Object workouts) {
    return '운동 $workouts회';
  }

  @override
  String get statsStreakFireDayStreak => '연속 기록';

  @override
  String get statsStreakFireLongest => '최장 기록';

  @override
  String get statsStreakFireTotal => '총 기록';

  @override
  String get statsTemplateCalories => '칼로리';

  @override
  String get statsTemplateDuration => '기간';

  @override
  String get statsTemplateVolume => '볼륨';

  @override
  String get statsTemplateWorkoutComplete => '운동 완료';

  @override
  String get statsWeeklyReportCompleted => '완료';

  @override
  String get statsWeeklyReportCompletion => '완료율';

  @override
  String get statsWeeklyReportReportCard => '리포트 카드';

  @override
  String get statsWeeklyReportStreak => '연속 기록';

  @override
  String statsWeeklyReportTemplateDays(Object currentStreak) {
    return '$currentStreak일';
  }

  @override
  String statsWeeklyReportTemplateValue(Object _completionPercent) {
    return '$_completionPercent%';
  }

  @override
  String statsWeeklyReportTemplateWorkouts(Object totalWorkouts) {
    return '운동 $totalWorkouts회';
  }

  @override
  String get statsWeeklyReportWeekly => '주간';

  @override
  String get stepGoalCardGoalReached => '목표 달성';

  @override
  String get stepGoalCardGoalReachedGreatJob => '목표 달성! 잘하셨어요!';

  @override
  String stepGoalCardStepGoalProgressOf(
    Object currentSteps,
    Object goalSteps,
    Object percentage,
  ) {
    return '걸음 수 목표 달성도: $goalSteps보 중 $currentSteps보, $percentage% 완료';
  }

  @override
  String get stepGoalCardSteps => '걸음 수';

  @override
  String stepGoalCardValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String get stepGoalEditorAutomaticallyIncreasesYourG =>
      '실력이 향상됨에 따라 목표가 자동으로 증가합니다';

  @override
  String get stepGoalEditorQuickSelect => '빠른 선택';

  @override
  String get stepGoalEditorSaveGoal => '목표 저장';

  @override
  String get stepGoalEditorSetStepGoal => '걸음 수 목표 설정';

  @override
  String stepGoalEditorSheetSaveGoalOfSteps(Object _selectedGoal) {
    return '$_selectedGoal 걸음 목표 저장';
  }

  @override
  String stepGoalEditorSheetSelectedGoalSteps(Object _selectedGoal) {
    return '선택된 목표: $_selectedGoal 걸음';
  }

  @override
  String stepGoalEditorSheetStepGoalSliderFrom(
    Object _maxGoal,
    Object _minGoal,
  ) {
    return '걸음 목표 슬라이더, $_minGoal에서 $_maxGoal 걸음 사이';
  }

  @override
  String stepGoalEditorSheetSteps(Object _selectedGoal) {
    return '$_selectedGoal 걸음';
  }

  @override
  String get stepGoalEditorStepsPerDay => '일일 걸음 수';

  @override
  String get stepGoalEditorUseProgressiveGoal => '점진적 목표 사용';

  @override
  String get stepGoalEditorWhenYouHitYour =>
      '5일 연속 목표를 달성하면 500걸음이 추가됩니다. 3일 연속 달성하지 못하면 기본 목표로 초기화됩니다.';

  @override
  String stepsCounterCardConnect(Object sourceLabel) {
    return '$sourceLabel 연결';
  }

  @override
  String stepsCounterCardDailyGoalReachedVia(Object sourceLabel) {
    return '일일 목표 달성 🎉 · $sourceLabel 기준';
  }

  @override
  String get storiesRingYourStory => '내 스토리';

  @override
  String get storyCreateAddACaption => '캡션 추가...';

  @override
  String get storyCreateCamera => '카메라';

  @override
  String get storyCreateGallery => '갤러리';

  @override
  String get storyCreateNewStory => '새 스토리';

  @override
  String get storyCreateShareAMoment => '순간 공유';

  @override
  String get storyCreateShareStory => '스토리 공유';

  @override
  String get storyCreateUploading => '업로드 중...';

  @override
  String get storyCreateYourStoryWillBe => '스토리는 24시간 동안 표시됩니다';

  @override
  String get storyViewerNoStories => '스토리 없음';

  @override
  String get strainCoachCardConnect => '연결';

  @override
  String get strainCoachCardConnectHealthForAn => '강도 분석을 위해 건강 데이터를 연결하세요.';

  @override
  String get strainCoachCardTodaySIntensity => '오늘의 강도';

  @override
  String get strainDashboardCompleteSomeWorkoutsTo =>
      '운동을 완료하고 스트레인 예방 인사이트를 확인하세요.';

  @override
  String get strainDashboardFailedToLoadData => '데이터 로드 실패';

  @override
  String get strainDashboardNoStrainDataYet => '아직 스트레인 데이터 없음';

  @override
  String get strainDashboardOverallStatus => '전체 상태';

  @override
  String get strainDashboardStrainPrevention => '스트레인 예방';

  @override
  String get strainDashboardViewHistory => '기록 보기';

  @override
  String get strainDashboardVolumeAlerts => '볼륨 알림';

  @override
  String strainRiskCardKg(Object currentVolumeKg) {
    return '$currentVolumeKg kg';
  }

  @override
  String strainRiskCardOfKgCap(Object volumeCapKg) {
    return '$volumeCapKg kg 한도 중';
  }

  @override
  String strainRiskCardPercentOverCap(Object percent) {
    return '제한치 대비 $percent% 초과';
  }

  @override
  String strainRiskCardPercentVsLastWeek(Object signedPercent) {
    return '지난주 대비 $signedPercent%';
  }

  @override
  String get strainRiskCardTooFast => '너무 빠름';

  @override
  String streakBadgesBestDays(Object longestStreak) {
    return '최고 기록: $longestStreak일';
  }

  @override
  String streakBadgesDayStreak(Object currentStreak) {
    return '$currentStreak일 연속';
  }

  @override
  String get streakBadgesHitYourGoalTo => '목표를 달성하고 연속 기록을 시작하세요!';

  @override
  String streakBadgesMoreDaysToBronze(Object currentStreak) {
    return '브론즈까지 $currentStreak일 남았습니다!';
  }

  @override
  String get streakBadgesNewBest => '새로운 기록!';

  @override
  String get streakExplainerGotIt => '확인';

  @override
  String get streakExplainerHowTheStreakWorks => '스트릭 작동 방식';

  @override
  String get streakExplainerStreakFreezes => '스트릭 프리즈';

  @override
  String get streakExplainerUseFreeze => '프리즈 사용';

  @override
  String get streakExplainerYourStreak => '나의 스트릭';

  @override
  String get streakMilestoneDays => 'DAYS';

  @override
  String streakMilestoneDaysToGo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 남음!',
    );
    return '$_temp0';
  }

  @override
  String get streakMilestoneKeepTheStreakGoing => '스트릭을 유지하세요!';

  @override
  String streakMilestoneNextBadgeName(Object name) {
    return '다음: $name';
  }

  @override
  String streakMilestonePreviewDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
    );
    return '$_temp0';
  }

  @override
  String get streakMilestoneRare => 'RARE';

  @override
  String get streakMilestoneRewards => '보상';

  @override
  String get streakMilestoneStreakMilestone => '스트릭 마일스톤!';

  @override
  String get streakMilestoneYouVeReachedThe => '최고의 스트릭 마일스톤에 도달했습니다!';

  @override
  String streakSavedDialogWeUsedStreakShield(Object savedStreakCount) {
    return '스트릭 실드 1개를 사용하여 $savedStreakCount일 연속 기록을 유지했습니다.';
  }

  @override
  String get streakSavedKeepItGoing => '계속 유지하세요';

  @override
  String get streakSavedStreakSaved => '스트릭 저장됨!';

  @override
  String get strengthBestLift => '최고 기록';

  @override
  String get strengthChartStrengthTrends => '근력 추이';

  @override
  String get strengthContributionToScore => '점수 기여도';

  @override
  String get strengthExercisesPrs => '운동 및 PR';

  @override
  String get strengthFitnessScore => '피트니스 점수';

  @override
  String get strengthMuscleAnalytics => '근육 분석';

  @override
  String get strengthOverviewCardCheckIn => '체크인';

  @override
  String get strengthOverviewCardCompleteWorkoutsWithResista =>
      '저항 운동을 완료하여\n근력 향상을 추적하세요.';

  @override
  String get strengthOverviewCardDragU2630ToReorder =>
      '☰을 드래그하여 재정렬 · 핀을 탭하여 상단에 고정';

  @override
  String get strengthOverviewCardHowAreYouFeeling => '오늘 컨디션은 어떠신가요?';

  @override
  String get strengthOverviewCardHowScoresWork => '점수 산정 방식';

  @override
  String get strengthOverviewCardHowStrengthScoresWork => '근력 점수 산정 방식';

  @override
  String get strengthOverviewCardLevels => '레벨';

  @override
  String get strengthOverviewCardMax => '최대';

  @override
  String get strengthOverviewCardMin => '최소';

  @override
  String get strengthOverviewCardMuscle => '근육';

  @override
  String get strengthOverviewCardNoStrengthDataYet => '아직 근력 데이터가 없습니다';

  @override
  String get strengthOverviewCardOptimal => '최적';

  @override
  String get strengthOverviewCardOverallScoreHeroRing => '종합 점수 (히어로 링)';

  @override
  String get strengthOverviewCardReadiness => '준비도';

  @override
  String get strengthOverviewCardRecalculate => '재계산';

  @override
  String get strengthOverviewCardScoreIsCalculatedFrom =>
      '점수는 최근 90일간 각 근육 그룹별 최고의 세트(중량 x 횟수)를 기준으로 계산됩니다. 체중 대비 비율이 높을수록 점수가 높습니다.';

  @override
  String get strengthOverviewCardScoresUpdateAutomaticallyAf =>
      '점수는 매 운동 후 자동으로 업데이트됩니다. 추적된 저항 운동만 반영되며, 가져온 유산소 운동은 점수에 영향을 주지 않습니다.';

  @override
  String get strengthOverviewCardStrengthScore => '근력 점수';

  @override
  String get strengthOverviewCardTheRingDisplaysA =>
      '링은 모든 근육 그룹 점수의 가중 평균을 표시합니다. 1RM은 최근 90일간 기록된 최고의 세트를 기준으로 Brzycki/Epley/Lombardi 공식 평균을 사용하여 추정됩니다.';

  @override
  String get strengthOverviewCardTrainingStatus => '훈련 상태';

  @override
  String strengthOverviewCardUiMuscleGroups(Object length) {
    return '근육 그룹 $length개';
  }

  @override
  String get strengthOverviewCardValuesAreForIntermediate =>
      '값은 중급자를 기준으로 하며 훈련 수준에 따라 자동으로 조정됩니다. 상태에는 준비도 체크인 결과도 반영됩니다.';

  @override
  String get strengthOverviewCardVolumeGuidelinesSetsWeek => '볼륨 가이드라인 (세트/주)';

  @override
  String get strengthOverviewCardYourOverallFitnessScore =>
      '종합 피트니스 점수 가중치:\n근력 40% + 일관성 30% + 영양 20% + 준비도 10%';

  @override
  String get strengthOverviewCardYourStrengthScore0 =>
      '근력 점수(0-100)는 확립된 기준과 비교하여 체중 대비 얼마나 들어 올릴 수 있는지를 측정합니다.';

  @override
  String get strengthRecentPersonalRecords => '최근 개인 기록';

  @override
  String get strengthScoreCardTitle => '근력 점수';

  @override
  String get stretchControllerComplete => '완료';

  @override
  String get stretchControllerCoolDown => '쿨다운';

  @override
  String get stretchControllerPause => '일시정지';

  @override
  String get stretchControllerResume => '재개';

  @override
  String get stretchControllerSkipAll => '모두 건너뛰기';

  @override
  String get stretchControllerStartTimer => '타이머 시작';

  @override
  String get stretchControllerUpNext => '다음 순서';

  @override
  String get stretchPhaseCoolDown => '쿨다운';

  @override
  String get stretchPhaseFinish => '종료';

  @override
  String get stretchPhaseGreatJobTimeTo => '수고하셨습니다! 이제 스트레칭으로 회복할 시간입니다.';

  @override
  String get stretchPhasePause => '일시정지';

  @override
  String stretchPhaseScreenSec(Object duration) {
    return '$duration초';
  }

  @override
  String get stretchPhaseSkipAll => '모두 건너뛰기';

  @override
  String get stretchPhaseUpNext => '다음 순서';

  @override
  String get subscriptionManagementBillingInformation => '결제 정보';

  @override
  String get subscriptionManagementCouldNotOpenSubscription =>
      '구독 설정을 열 수 없습니다';

  @override
  String get subscriptionManagementFailedToLoadSubscription =>
      '구독 정보를 불러오지 못했습니다';

  @override
  String get subscriptionManagementGetUnlimitedWorkoutsAi =>
      '무제한 운동, AI 코칭 등을 이용하세요';

  @override
  String get subscriptionManagementManageSubscription => '구독 관리';

  @override
  String get subscriptionManagementNoBillingInformationAvailab =>
      '결제 정보를 사용할 수 없습니다';

  @override
  String get subscriptionManagementPurchasesRestoredSuccessfull =>
      '구매 항목이 성공적으로 복원되었습니다';

  @override
  String get subscriptionManagementRequestRefund => '환불 요청';

  @override
  String get subscriptionManagementRestorePurchases => '구매 복원';

  @override
  String get subscriptionManagementScreenAccessNeverExpires =>
      '액세스 권한은 만료되지 않습니다';

  @override
  String get subscriptionManagementScreenCancelAutoRenewal => '자동 갱신 취소';

  @override
  String get subscriptionManagementScreenCancelSubscription => '구독 취소';

  @override
  String subscriptionManagementScreenFailedToPauseSubscription(Object e) {
    return '구독 일시 중지 실패: $e';
  }

  @override
  String subscriptionManagementScreenFailedToResumeSubscription(Object e) {
    return '구독 재개 실패: $e';
  }

  @override
  String get subscriptionManagementScreenLeftInTrial => '남은 체험 기간';

  @override
  String get subscriptionManagementScreenLifetime => '평생 이용권';

  @override
  String get subscriptionManagementScreenManageSubscription => '구독 관리';

  @override
  String get subscriptionManagementScreenPauseSubscription => '구독 일시정지';

  @override
  String get subscriptionManagementScreenResumeSubscription => '구독 재개';

  @override
  String get subscriptionManagementScreenStartBillingAgain => '결제 재개';

  @override
  String subscriptionManagementScreenSubscriptionPausedForDays(
    Object durationDays,
  ) {
    return '$durationDays일 동안 구독 일시 중지됨';
  }

  @override
  String get subscriptionManagementScreenTakeABreakFor => '최대 3개월간 휴식';

  @override
  String get subscriptionManagementScreenTrialEnded => '체험 기간 종료';

  @override
  String get subscriptionManagementSubmitARefundRequest => '환불 요청 제출';

  @override
  String get subscriptionManagementSubscriptionPaused => '구독 일시정지됨';

  @override
  String get subscriptionManagementSubscriptionResumedSuccessfu =>
      '구독이 성공적으로 재개되었습니다';

  @override
  String get subscriptionManagementSyncWithAppStore =>
      'App Store / Play Store와 동기화';

  @override
  String get subscriptionManagementUnknownError => '알 수 없는 오류';

  @override
  String get subscriptionManagementUpgradeToPremium => '프리미엄으로 업그레이드';

  @override
  String get subscriptionManagementViewPlans => '플랜 보기';

  @override
  String get suggestFeatureCategory => '카테고리';

  @override
  String get suggestFeatureDescribeYourFeatureIdea => '기능 아이디어를 자세히 설명해주세요...';

  @override
  String get suggestFeatureDescription => '설명';

  @override
  String get suggestFeatureEGSocialWorkout => '예: 소셜 운동 공유';

  @override
  String get suggestFeatureFeatureSuggestionSubmittedS =>
      '기능 제안이 성공적으로 제출되었습니다!';

  @override
  String get suggestFeatureFeatureTitle => '기능 제목';

  @override
  String suggestFeatureSheetYouVeUsedAll(Object used) {
    return '제안 횟수 $used회를 모두 사용하셨습니다. 기존 기능에 투표해 주세요!';
  }

  @override
  String get suggestFeatureSubmitSuggestion => '제안 제출';

  @override
  String get suggestFeatureSuggestAFeature => '기능 제안하기';

  @override
  String get suggestFeatureYouHaveReachedThe => '최대 2개의 기능 제안 한도에 도달했습니다';

  @override
  String get suggestedReplyChipsBodyweightVersion => '맨몸 운동 버전';

  @override
  String get suggestedReplyChipsCycleadjusted => 'cycleAdjusted';

  @override
  String get suggestedReplyChipsHowShouldITrain => '이 단계는 어떻게 훈련해야 하나요?';

  @override
  String get suggestedReplyChipsILlDoIt => '오늘 밤에 할게요';

  @override
  String get suggestedReplyChipsKeepPlanned => '계획 유지';

  @override
  String get suggestedReplyChipsLogASnack => '간식 기록';

  @override
  String get suggestedReplyChipsLogBreakfast => '아침 식사 기록';

  @override
  String get suggestedReplyChipsLogWater => '물 섭취 기록';

  @override
  String get suggestedReplyChipsMoveToTomorrow => '내일로 미루기';

  @override
  String get suggestedReplyChipsPlanTomorrow => '내일 계획하기';

  @override
  String get suggestedReplyChipsPreworkoutfuelgap => 'preWorkoutFuelGap';

  @override
  String get suggestedReplyChipsQuickCheck => '빠른 확인';

  @override
  String get suggestedReplyChipsRecapDetails => '요약 세부 정보';

  @override
  String get suggestedReplyChipsRecoverylighter => 'recoveryLighter';

  @override
  String get suggestedReplyChipsStartAnyway => '어쨌든 시작';

  @override
  String get suggestedReplyChipsSwitchToLighter => '더 가볍게 변경';

  @override
  String get suggestedReplyChipsWhatSNext => '다음은 무엇인가요?';

  @override
  String get suggestedReplyChipsWhy => '왜 그런가요?';

  @override
  String get suggestedReplyChipsWindDown => '마무리';

  @override
  String get suggestionCardAccept => '수락';

  @override
  String get suggestionCardAcceptGoal => '목표 수락';

  @override
  String get suggestionCardNotNow => '나중에';

  @override
  String get suggestionCardTarget => '목표';

  @override
  String get suggestionCardWhyThisGoal => '왜 이 목표인가요?';

  @override
  String get suggestionCarouselCouldNotLoadSuggestions => '제안을 불러올 수 없습니다';

  @override
  String get suggestionCarouselSuggestedGoals => '제안된 목표';

  @override
  String get summaryAiBreathingGuide => '호흡 가이드';

  @override
  String get summaryAiCoachOpened => '코치 열기';

  @override
  String get summaryAiCoachTips => '코치 팁';

  @override
  String get summaryAiExerciseSwaps => '운동 교체';

  @override
  String get summaryAiFatigueAlerts => '피로 알림';

  @override
  String get summaryAiInfoOpened => '정보 열기';

  @override
  String get summaryAiInteractions => 'AI 상호작용';

  @override
  String get summaryAiMessagesSent => '메시지 전송';

  @override
  String get summaryAiRestSuggestions => '휴식 제안';

  @override
  String get summaryAiTipsDismissed => '팁 닫기';

  @override
  String get summaryAiVideosWatched => '시청한 영상';

  @override
  String get summaryAiWeightSuggestions => '무게 제안';

  @override
  String get summaryAllExercisesCompleted => '모든 운동 완료';

  @override
  String get summaryAtlasBack => 'BACK';

  @override
  String get summaryAtlasFront => 'FRONT';

  @override
  String get summaryAvgExercises => '평균 (운동)';

  @override
  String get summaryAvgRir => '평균 RIR';

  @override
  String get summaryAvgRpe => '평균 RPE';

  @override
  String get summaryAvgSets => '평균 (세트)';

  @override
  String summaryBestSet(Object reps, Object weight) {
    return '최고 세트: $weight lb x $reps';
  }

  @override
  String get summaryCardBestStreak => '최고 연속 기록';

  @override
  String get summaryCardHours => '시간';

  @override
  String get summaryCardPrs => 'PRs';

  @override
  String get summaryCardShareYourWrapped => 'Wrapped 공유하기';

  @override
  String get summaryCardVolumeLbs => '볼륨 (lbs)';

  @override
  String get summaryCardYourMonthInReview => '이번 달 요약';

  @override
  String get summaryCardioSession => '유산소 세션';

  @override
  String get summaryCardsPrs => 'PRs';

  @override
  String get summaryCardsStreak => '연속 기록';

  @override
  String get summaryCardsVolume => '볼륨';

  @override
  String get summaryCoachLabel => 'COACH';

  @override
  String get summaryColPrev => '이전';

  @override
  String get summaryColReps => '횟수';

  @override
  String get summaryColRir => 'RIR';

  @override
  String get summaryColRpe => 'RPE';

  @override
  String get summaryColSet => '세트';

  @override
  String get summaryColTarget => '목표';

  @override
  String get summaryColWeight => '무게';

  @override
  String get summaryDonutIntensity => '강도';

  @override
  String get summaryDonutOnTarget => '목표 달성';

  @override
  String get summaryDonutPlanAdherence => '계획 준수도';

  @override
  String get summaryDonutRestCompliance => '휴식 준수도';

  @override
  String get summaryDuration => '운동 시간';

  @override
  String get summaryEpleyFormula => '최고 세트 기준 Epley 공식 적용';

  @override
  String summaryEquipmentIncrement(Object name) {
    return '$name 증분';
  }

  @override
  String summaryEst1RM(Object value) {
    return '추정 1RM: $value lb';
  }

  @override
  String get summaryEstimated1RM => '예상 1RM';

  @override
  String get summaryEverySetRated => '모든 세트 평가 완료';

  @override
  String get summaryExerciseOrderAndTime => '운동 순서 및 시간';

  @override
  String get summaryExerciseTableNoNotesOrPhotos => '이 세트에 저장된 메모나 사진이 없습니다.';

  @override
  String get summaryExerciseTableNoNotesSavedOn => '이 세트에 저장된 메모가 없습니다.';

  @override
  String summaryExerciseTableNotes(Object n) {
    return '메모 $n개';
  }

  @override
  String get summaryExerciseTablePrevious => '이전';

  @override
  String get summaryExerciseTableReps => '횟수';

  @override
  String get summaryExerciseTableSet => '세트';

  @override
  String summaryExerciseTableSetNotes(Object setNumber) {
    return '$setNumber세트 메모';
  }

  @override
  String get summaryExerciseTableSkipped => '건너뜀';

  @override
  String get summaryExerciseTableTarget => '목표';

  @override
  String get summaryExitExercisesDone => '완료한 운동';

  @override
  String get summaryExitProgress => '진행률';

  @override
  String get summaryExitTimeSpent => '소요 시간';

  @override
  String get summaryFeedbackConfidence => '자신감';

  @override
  String get summaryFeedbackEnergy => '에너지';

  @override
  String get summaryFeedbackFeelingStronger => '강해지는 느낌';

  @override
  String get summaryFeedbackMood => '기분';

  @override
  String get summaryHideDetails => '상세 숨기기';

  @override
  String get summaryHowYouFelt => '운동 느낌';

  @override
  String get summaryHydration => '수분 섭취';

  @override
  String get summaryHydrationLabel => '수분 섭취';

  @override
  String get summaryIntensityAnalysis => '강도 분석';

  @override
  String get summaryIntensityEasy => '쉬움';

  @override
  String get summaryIntensityHard => '힘듦';

  @override
  String get summaryIntensityMaximal => '최대 강도';

  @override
  String get summaryIntensityModerate => '보통';

  @override
  String get summaryIntensityVeryHard => '매우 힘듦';

  @override
  String get summaryMoreDetails => '상세 보기';

  @override
  String get summaryMuscleMapNotApplicable => '근육 지도 적용 불가';

  @override
  String get summaryMusclesHit => '타겟 근육';

  @override
  String summaryNSets(Object count) {
    return '$count세트';
  }

  @override
  String summaryNSkipped(Object count) {
    return '$count개 건너뜀';
  }

  @override
  String get summaryNoCompletedSets => '이 운동에 완료된 세트 기록이 없습니다.';

  @override
  String get summaryNoDetailedData => '이 운동에 대한 상세 기록이 없습니다.';

  @override
  String get summaryNoPlanData => '계획 데이터 없음';

  @override
  String get summaryNoRestData => '휴식 데이터 없음';

  @override
  String get summaryNoRirLogged => '기록된 RIR 없음';

  @override
  String get summaryNoVolumeData => '볼륨 데이터 없음';

  @override
  String get summaryNoWorkingSets => '본 세트 없음';

  @override
  String get summaryOutOf100 => '100점 만점';

  @override
  String get summaryPeakRpe => '최대 RPE';

  @override
  String get summaryPerExercise => '운동별';

  @override
  String get summaryPerExerciseDeepDive => '운동별 상세 분석';

  @override
  String get summaryPerExerciseDeepDiveLabel => '운동별 상세 분석';

  @override
  String get summaryPerformanceComparison => '성과 비교';

  @override
  String get summaryReps => '횟수';

  @override
  String summaryRepsLeft(Object count) {
    return '$count회 남음';
  }

  @override
  String get summaryRestAnalysis => '휴식 분석';

  @override
  String get summaryRingEffort => '노력';

  @override
  String get summaryRingPlan => '계획';

  @override
  String get summaryRingRest => '휴식';

  @override
  String get summaryRpeDistribution => 'RPE 분포';

  @override
  String get summarySessionScore => '세션 점수';

  @override
  String get summarySessionTimeline => '세션 타임라인';

  @override
  String get summarySetTypeDistribution => '세트 유형 분포';

  @override
  String get summarySets => '세트';

  @override
  String get summarySettingsUsed => '사용된 설정';

  @override
  String get summaryStretching => '스트레칭';

  @override
  String get summarySupersetDetails => '슈퍼세트 상세';

  @override
  String summarySupersetN(Object id) {
    return '슈퍼세트 $id';
  }

  @override
  String summaryTagMuscles(Object exercises) {
    return '근육 태그 · $exercises';
  }

  @override
  String get summaryTiming => '타이밍';

  @override
  String get summaryTotalRest => '총 휴식 시간';

  @override
  String get summaryTotalVolumeLabel => '총 볼륨: ';

  @override
  String get summaryVolume => '볼륨';

  @override
  String get summaryVolumeBreakdown => '볼륨 분석';

  @override
  String summaryVsDaysAgo(Object days) {
    return '$days일 전 대비';
  }

  @override
  String get summaryWarmup => '웜업';

  @override
  String get summaryWarmupStretching => '웜업 및 스트레칭';

  @override
  String get summaryWeightUnit => '무게 단위';

  @override
  String get summaryWorkoutEndedEarly => '운동 조기 종료';

  @override
  String get supersetAlgorithmCardAddFavoritePair => '즐겨찾는 조합 추가';

  @override
  String get supersetAlgorithmCardAddPair => '조합 추가';

  @override
  String get supersetAlgorithmCardAddYourGoTo => '자주 사용하는 운동 조합을 추가하세요';

  @override
  String get supersetAlgorithmCardEGBenchPress => '예: 벤치 프레스';

  @override
  String get supersetAlgorithmCardEGBentOver => '예: 벤트 오버 로우';

  @override
  String get supersetAlgorithmCardEnterTwoExercisesYou =>
      '슈퍼세트로 묶을 두 가지 운동을 입력하세요';

  @override
  String get supersetAlgorithmCardFavoritePairs => '즐겨찾는 조합';

  @override
  String get supersetAlgorithmCardFineTuneSupersetGeneration => '슈퍼세트 생성 미세 조정';

  @override
  String get supersetAlgorithmCardFirstExercise => '첫 번째 운동';

  @override
  String get supersetAlgorithmCardNoFavoritePairsYet => '아직 즐겨찾는 조합이 없습니다';

  @override
  String supersetAlgorithmCardSaved(Object length) {
    return '$length개 저장됨';
  }

  @override
  String get supersetAlgorithmCardSecondExercise => '두 번째 운동';

  @override
  String get supersetAlgorithmCardSupersetAlgorithm => '슈퍼세트 알고리즘';

  @override
  String get supersetCreate => '슈퍼세트 생성';

  @override
  String get supersetCreatePair => '슈퍼세트 만들기';

  @override
  String supersetExerciseN(Object n) {
    return '운동 $n';
  }

  @override
  String get supersetExercisePickerAddExercisesToYour => '먼저 운동에 운동을 추가하세요';

  @override
  String get supersetExercisePickerSearchExercises => '운동 검색...';

  @override
  String get supersetIndicatorBreak => '휴식';

  @override
  String get supersetIndicatorCreateSuperset => '슈퍼세트 만들기';

  @override
  String get supersetIndicatorNoRestBetween => '사이 휴식 없음';

  @override
  String get supersetIndicatorSelectTwoExercisesTo => '묶을 두 가지 운동을 선택하세요';

  @override
  String supersetIndicatorSs(Object groupNumber) {
    return 'SS$groupNumber';
  }

  @override
  String supersetIndicatorSuperset(Object groupNumber) {
    return '슈퍼세트 $groupNumber';
  }

  @override
  String get supersetIndicatorSwap => '교체';

  @override
  String get supersetIndicatorTapTheFirstExercise => '첫 번째 운동을 탭하세요';

  @override
  String get supersetPairSheetClear => '지우기';

  @override
  String get supersetPairSheetCreateSuperset => '슈퍼세트 만들기';

  @override
  String get supersetPairSheetCreateSupersetPair => '슈퍼세트 조합 만들기';

  @override
  String get supersetPairSheetPairTwoExercisesFor => '효율적인 훈련을 위해 두 운동을 묶으세요';

  @override
  String supersetPairSheetPartSupersetPairSheetStateValue(
    Object name,
    Object name1,
  ) {
    return '$name + $name1';
  }

  @override
  String get supersetPairSheetRestAfterSuperset => '슈퍼세트 후 휴식';

  @override
  String get supersetPairSheetRestBetweenExercises => '운동 간 휴식';

  @override
  String get supersetPairSheetRestSettings => '휴식 설정';

  @override
  String get supersetPairSheetReuseThisPairIn => '향후 운동에서 이 조합 재사용';

  @override
  String get supersetPairSheetSaveToFavorites => '즐겨찾기에 저장';

  @override
  String get supersetPairSheetSelectExercise1 => '운동 1 선택';

  @override
  String get supersetPairSheetSelectExercise2 => '운동 2 선택';

  @override
  String get supersetPairSheetSuggestedPairs => '추천 슈퍼세트';

  @override
  String get supersetPairSheetSupersetType => '슈퍼세트 유형';

  @override
  String get supersetPairSheetTapToSelect => '탭하여 선택';

  @override
  String get supersetPairSubtitle => '두 운동을 묶어 최소한의 휴식으로 번갈아 수행하세요';

  @override
  String get supersetReorderASupersetNeedsAt => '슈퍼세트는 최소 2개의 운동이 필요합니다';

  @override
  String get supersetReorderApplyChanges => '변경 사항 적용';

  @override
  String get supersetReorderDragToReorderSwipe => '드래그하여 순서 변경, 왼쪽으로 밀어 삭제';

  @override
  String get supersetReorderNoChanges => '변경 사항 없음';

  @override
  String get supersetReorderNoRestBetween => '휴식 없음';

  @override
  String get supersetReorderRemove => '삭제';

  @override
  String get supersetReorderReset => '초기화';

  @override
  String supersetReorderSheetEdit(
    Object _originalTypeLabel,
    Object groupNumber,
  ) {
    return '$_originalTypeLabel $groupNumber 편집';
  }

  @override
  String get supersetRestAfter => '슈퍼세트 후 휴식';

  @override
  String get supersetRestBetween => '운동 간 휴식';

  @override
  String get supersetRestSettings => '휴식 설정';

  @override
  String get supersetSaveToFavorites => '즐겨찾기에 저장';

  @override
  String get supersetSaveToFavoritesSubtitle => '이 조합을 저장하여 빠르게 다시 사용하세요';

  @override
  String get supersetSettingsAutoGenerateSupersets => '슈퍼세트 자동 생성';

  @override
  String get supersetSettingsChestBackBicepsTriceps => '가슴/등, 이두/삼두 조합';

  @override
  String get supersetSettingsControlHowSupersetsAre => '운동 중 슈퍼세트 생성 방식 제어';

  @override
  String get supersetSettingsIncludeSupersetPairsIn => 'AI 생성 운동에 슈퍼세트 포함';

  @override
  String get supersetSettingsPreferAntagonistPairs => '길항근 조합 선호';

  @override
  String get supersetSettingsSupersetSettings => '슈퍼세트 설정';

  @override
  String get supersetSuggestedPairs => '추천 조합';

  @override
  String get supersetTapToSelect => '탭하여 선택';

  @override
  String get supersetType => '유형';

  @override
  String get syncDetailsAllSynced => '모두 동기화됨!';

  @override
  String get syncDetailsDiscard => '삭제';

  @override
  String get syncDetailsDiscardThisChange => '이 변경 사항을 삭제할까요?';

  @override
  String get syncDetailsDiscarded => '삭제됨';

  @override
  String get syncDetailsExport => '내보내기';

  @override
  String get syncDetailsNoFailedSyncItems => '동기화 실패 항목이 없습니다.';

  @override
  String get syncDetailsRetryAll => '모두 재시도';

  @override
  String get syncDetailsRetrying => '재시도 중...';

  @override
  String syncDetailsScreenLatest(Object first) {
    return '최신: $first';
  }

  @override
  String syncDetailsScreenRetries(Object retryCount) {
    return '$retryCount회 재시도';
  }

  @override
  String get syncDetailsSyncDetails => '동기화 세부 정보';

  @override
  String get syncDetailsThisErrorWonT =>
      '이 오류는 재시도로 해결되지 않습니다. 편집 후 다시 로그인하거나 삭제하세요.';

  @override
  String get syncStatusSyncNow => '지금 동기화';

  @override
  String get syncStatusSyncing => '동기화 중...';

  @override
  String get syncedSummaryAvgHr => '평균 심박수';

  @override
  String get syncedSummaryCalories => '칼로리';

  @override
  String get syncedSummaryDistance => '거리';

  @override
  String get syncedSummaryDuration => '시간';

  @override
  String get syncedSummaryMaxHr => '최대 심박수';

  @override
  String get syncedSummaryNoActivityMetricsWere => '이 세션에 대한 활동 지표가 없습니다.';

  @override
  String get syncedSummarySyncedActivity => '동기화된 활동';

  @override
  String syncedSummaryViewActivity(Object platform) {
    return '$platform 활동';
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
    return '$duration분';
  }

  @override
  String syncedSummaryViewSessionsOpenOnYour(Object platform) {
    return '세션 — 기기에서 $platform을(를) 열어 ';
  }

  @override
  String syncedSummaryViewSyncedFrom(Object platform) {
    return '$platform에서 동기화됨';
  }

  @override
  String syncedSummaryViewThisWorkoutWasImported(Object platform) {
    return '이 운동은 $platform에서 가져왔습니다. Zealova ';
  }

  @override
  String get syncedWorkoutDetailActiveCal => '활동 칼로리';

  @override
  String get syncedWorkoutDetailAvg => '평균';

  @override
  String get syncedWorkoutDetailBodySignals => '신체 신호';

  @override
  String get syncedWorkoutDetailBodyTemp => '체온';

  @override
  String get syncedWorkoutDetailBodyWt => '체중';

  @override
  String get syncedWorkoutDetailBreathing => '호흡';

  @override
  String get syncedWorkoutDetailCadence => '케이던스';

  @override
  String get syncedWorkoutDetailCapturedAroundYourSession => '세션 전후로 측정됨';

  @override
  String get syncedWorkoutDetailDate => '날짜';

  @override
  String get syncedWorkoutDetailDeleteThisSyncedWorkout => '이 동기화된 운동을 삭제할까요?';

  @override
  String get syncedWorkoutDetailDistance => '거리';

  @override
  String get syncedWorkoutDetailDuplicateOfAnotherImport =>
      '다른 데이터와 중복됨 — 기본 소스가 우선입니다.';

  @override
  String get syncedWorkoutDetailDuration => '시간';

  @override
  String get syncedWorkoutDetailElevGain => '상승 고도';

  @override
  String get syncedWorkoutDetailFlights => '오른 층수';

  @override
  String get syncedWorkoutDetailHeartRate => '심박수';

  @override
  String get syncedWorkoutDetailHowDidItFeel => '느낌이 어땠나요?';

  @override
  String get syncedWorkoutDetailHowDidThisSession => '이번 세션은 어땠나요?';

  @override
  String get syncedWorkoutDetailHrvPost => 'HRV (운동 후)';

  @override
  String get syncedWorkoutDetailHrvPre => 'HRV (운동 전)';

  @override
  String get syncedWorkoutDetailItWillReAppear =>
      'Health Connect와 다음 동기화 시 다시 나타납니다.';

  @override
  String get syncedWorkoutDetailManage => '관리';

  @override
  String get syncedWorkoutDetailMetrics => '지표';

  @override
  String get syncedWorkoutDetailMin => '최소';

  @override
  String get syncedWorkoutDetailNotes => '메모';

  @override
  String get syncedWorkoutDetailPace => '페이스';

  @override
  String get syncedWorkoutDetailPeak => '최고';

  @override
  String get syncedWorkoutDetailPullingRicherDataFrom =>
      'Health Connect에서 상세 데이터를 가져오는 중...';

  @override
  String get syncedWorkoutDetailRestingHr => '안정 시 심박수';

  @override
  String get syncedWorkoutDetailRpeRateOfPerceived => 'RPE · 자각 인지 강도';

  @override
  String syncedWorkoutDetailScreenAppDetailedSamplesMay(Object sourceApp) {
    return '앱, 상세 샘플은 $sourceApp에 도달하지 않을 수 있습니다.';
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
    return '코치: $_insight';
  }

  @override
  String syncedWorkoutDetailScreenIn(Object stride) {
    return '$stride in';
  }

  @override
  String syncedWorkoutDetailScreenKg(Object bodyKg) {
    return '$bodyKg kg';
  }

  @override
  String syncedWorkoutDetailScreenM(Object elev) {
    return '$elev m';
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
    return '$sourceApp에서 요약 정보만 공유되었습니다';
  }

  @override
  String syncedWorkoutDetailScreenSpm(Object cadence) {
    return '$cadence spm';
  }

  @override
  String syncedWorkoutDetailScreenTrimpFromHrReserve(Object trimp) {
    return 'TRIMP $trimp · HR reserve, 지속 시간 및 회복 기준';
  }

  @override
  String syncedWorkoutDetailScreenValue2(Object spo2) {
    return '$spo2%';
  }

  @override
  String get syncedWorkoutDetailSessionInfo => '세션 정보';

  @override
  String get syncedWorkoutDetailSpeed => '속도';

  @override
  String get syncedWorkoutDetailSplits => '구간 기록';

  @override
  String get syncedWorkoutDetailSpoAvg => '평균 SpO₂';

  @override
  String get syncedWorkoutDetailSteps => '걸음 수';

  @override
  String get syncedWorkoutDetailStride => '보폭';

  @override
  String get syncedWorkoutDetailTapToAddNotes => '탭하여 메모 추가';

  @override
  String get syncedWorkoutDetailTotalCal => '총 칼로리';

  @override
  String get syncedWorkoutDetailTrainingEffect => '훈련 효과';

  @override
  String get syncedWorkoutDetailZones => '구간';

  @override
  String get syncedWorkoutsHistoryActive => '활동';

  @override
  String get syncedWorkoutsHistoryAll => '전체';

  @override
  String get syncedWorkoutsHistoryBiggestClimb => '최대 상승';

  @override
  String get syncedWorkoutsHistoryBreakdown => '분석';

  @override
  String get syncedWorkoutsHistoryCalories => '칼로리';

  @override
  String get syncedWorkoutsHistoryFastestMile => '최고 속도 마일';

  @override
  String get syncedWorkoutsHistoryHardestSession => '가장 강도 높은 세션';

  @override
  String get syncedWorkoutsHistoryLast90Days => '최근 90일';

  @override
  String get syncedWorkoutsHistoryLess => '간략히';

  @override
  String get syncedWorkoutsHistoryLongestHike => '최장 하이킹';

  @override
  String get syncedWorkoutsHistoryLongestRide => '최장 라이딩';

  @override
  String get syncedWorkoutsHistoryLongestSession => '최장 세션';

  @override
  String get syncedWorkoutsHistoryLongestWalk => '최장 걷기';

  @override
  String get syncedWorkoutsHistoryMiles => '마일';

  @override
  String get syncedWorkoutsHistoryNoSyncedWorkoutsYet => '동기화된 운동이 없습니다';

  @override
  String syncedWorkoutsHistoryScreenM(Object bestElev) {
    return '$bestElev m';
  }

  @override
  String syncedWorkoutsHistoryScreenMi(Object miles) {
    return '$miles mi';
  }

  @override
  String syncedWorkoutsHistoryScreenMi2(Object miles) {
    return '$miles mi';
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
  String get syncedWorkoutsHistorySessions => '세션';

  @override
  String get syncedWorkoutsHistorySyncedWorkouts => '동기화된 운동';

  @override
  String get syncedWorkoutsHistoryYourRecords => '나의 기록';

  @override
  String get syncedWorkoutsSummary1SyncedWorkout => '1개의 동기화된 운동';

  @override
  String syncedWorkoutsSummaryCardCal(Object calories) {
    return '$calories cal';
  }

  @override
  String syncedWorkoutsSummaryCardFrom(Object platformLabel) {
    return '$platformLabel에서 가져옴';
  }

  @override
  String syncedWorkoutsSummaryCardM(Object duration) {
    return '$duration분';
  }

  @override
  String syncedWorkoutsSummaryCardSteps(Object steps) {
    return '$steps 걸음';
  }

  @override
  String syncedWorkoutsSummaryCardSynced(Object day, Object month) {
    return '$month/$day 동기화됨';
  }

  @override
  String syncedWorkoutsSummaryCardSyncedWorkouts(Object count) {
    return '동기화된 운동 $count회';
  }

  @override
  String syncedWorkoutsSummaryCardViewAll(Object count) {
    return '$count개 모두 보기';
  }

  @override
  String get syncedWorkoutsSummarySynced => '동기화됨';

  @override
  String get syncedWorkoutsSummaryTodaySSyncedWorkouts => '오늘 동기화된 운동';

  @override
  String get tappableCellSelectBias => '편향 선택';

  @override
  String get templateAddOneOrUse => '하나를 추가하거나 아래의 사전 설정 템플릿을 사용하세요';

  @override
  String get templateEditorAddTemplate => '템플릿 추가';

  @override
  String get templateEditorEditTemplate => '템플릿 편집';

  @override
  String get templateEditorNewTemplate => '새 템플릿';

  @override
  String get templateEditorSaveChanges => '변경사항 저장';

  @override
  String get templateEditorSupersets => '슈퍼세트';

  @override
  String get templateListAMondayInThe => '프로그램의 월요일이 다음 주 월요일에 시작됩니다.';

  @override
  String get templateListAddYourWarmUp => '각 세션에 웜업 및 스트레칭 루틴을 추가하세요.';

  @override
  String get templateListAlignToCalendarWeekdays => '캘린더 요일에 맞추기';

  @override
  String get templateListApplyMyStaples => '기본 루틴 적용';

  @override
  String get templateListCouldNotDeletePlease => '삭제할 수 없습니다. 다시 시도해주세요.';

  @override
  String get templateListCouldNotSchedulePlease => '일정을 잡을 수 없습니다. 다시 시도해주세요.';

  @override
  String get templateListCreateAProgram => '프로그램 만들기';

  @override
  String get templateListDay1OfThe => '프로그램의 1일 차가 선택한 날짜에 시작됩니다.';

  @override
  String get templateListDeleteProgram => '프로그램을 삭제할까요?';

  @override
  String get templateListMyPrograms => '나의 프로그램';

  @override
  String get templateListNewProgram => '새 프로그램';

  @override
  String get templateListNoSavedProgramsYet => '저장된 프로그램이 없습니다.';

  @override
  String get templateListScheduleThis => '일정 잡기';

  @override
  String get templateListScheduling => '일정 잡는 중...';

  @override
  String templateListScreenAllDays(Object _defaultTime) {
    return '모든 요일: $_defaultTime';
  }

  @override
  String templateListScreenAlreadyExisted(Object skippedExisting) {
    return '($skippedExisting개는 이미 존재함)';
  }

  @override
  String templateListScreenDeleted(Object name) {
    return '\"$name\" 삭제됨';
  }

  @override
  String templateListScreenRemoveWorkoutsAlreadyOn(Object name) {
    return '\"$name\"을(를) 삭제할까요? 캘린더에 이미 있는 운동입니다.';
  }

  @override
  String templateListScreenSchedule(Object name) {
    return '\"$name\" 일정 잡기';
  }

  @override
  String templateListScreenWorkoutsAdded(Object workoutsCreated) {
    return '운동 $workoutsCreated개 추가됨';
  }

  @override
  String templateListScreenWorkoutsAddedToYour(Object workoutsCreated) {
    return '캘린더에 운동 $workoutsCreated개가 추가되었습니다.';
  }

  @override
  String get templateListStartDay1On => '시작일에 1일 차 시작';

  @override
  String get templateListTapADayTo => '요일을 탭하여 다른 시간을 설정하세요.';

  @override
  String get templateListWeCouldNotLoad => '프로그램을 불러올 수 없습니다.';

  @override
  String get templateMyTemplates => '나의 템플릿';

  @override
  String get templateNew => '새로 만들기';

  @override
  String get templateNoCustomTemplatesYet => '사용자 지정 템플릿이 없습니다';

  @override
  String get templatePickerFailedToLoadTemplates => '템플릿을 불러오지 못했습니다';

  @override
  String templatePickerSheetTheOriginalHomeScreen(Object appName) {
    return '기존 $appName 홈 화면 경험';
  }

  @override
  String get templatePickerStartWithAPre => '사전 설계된 레이아웃으로 시작하세요';

  @override
  String get templatePickerTemplates => '템플릿';

  @override
  String get templatePickerUseThisTemplate => '이 템플릿 사용';

  @override
  String get templatePreBuiltTemplates => '사전 설정 템플릿';

  @override
  String get tierComparisonAdv => '고급';

  @override
  String get tierComparisonAdvanced => '고급';

  @override
  String get tierComparisonFeature => '기능';

  @override
  String get tierComparisonLongPressTheEasy =>
      'Easy / Advanced 버튼을 길게 누르면 언제든 다시 열 수 있습니다.';

  @override
  String get tierComparisonWhichTierIsRight => '나에게 맞는 티어는 무엇인가요?';

  @override
  String get tierExcellent => '우수';

  @override
  String get tierFair => '보통';

  @override
  String get tierGood => '좋음';

  @override
  String get tierLow => '낮음';

  @override
  String get tileFactoryFoodPatterns => '식단 패턴';

  @override
  String get tileFactorySeeWhichFoodsFuel => '나에게 에너지를 주는 음식과 지치게 하는 음식을 확인하세요';

  @override
  String get tilePickerAdd => '추가';

  @override
  String get tilePickerAddTile => '타일 추가';

  @override
  String get timeCardMostActiveDay => '가장 활동적인 날';

  @override
  String get timeCardPeakHour => '피크 시간';

  @override
  String get timeCardSpentWorkingOut => '운동 시간';

  @override
  String get timeCardYourTime => '나의 시간';

  @override
  String get timedExerciseTimerComplete => '완료';

  @override
  String get timedExerciseTimerPaused => '일시정지';

  @override
  String get timedExerciseTimerReset => '재설정';

  @override
  String get timedExerciseTimerRunning => '진행 중';

  @override
  String timedExerciseTimerSetOf(Object setNumber, Object totalSets) {
    return '$totalSets세트 중 $setNumber세트';
  }

  @override
  String get timedExerciseTimerTapPauseToRest => '일시정지를 눌러 휴식 후 재개하세요';

  @override
  String get timelineBusy => '바쁨';

  @override
  String get timelineCloseSearch => '검색 닫기';

  @override
  String get timelineCouldnTLoadTimeline => '타임라인을 불러올 수 없습니다.';

  @override
  String get timelineEntryDetailDeleted => '삭제됨 ✓';

  @override
  String get timelineEntryDetailEditDurationMin => '지속 시간 편집 (분)';

  @override
  String get timelineEntryDetailFailedToDeleteRefresh =>
      '삭제 실패 — 새로고침 후 다시 시도하세요.';

  @override
  String get timelineEntryDetailFailedToUpdate => '업데이트 실패';

  @override
  String get timelineEntryDetailReLog => '다시 기록';

  @override
  String get timelineEntryDetailReLogQueuedComing => '다시 기록 대기 중 — 곧 반영됩니다';

  @override
  String get timelineEntryDetailRefresh => '새로고침';

  @override
  String get timelineEntryDetailRelog => '다시 기록';

  @override
  String get timelineEntryDetailShareSheetComingSoon => '공유 기능 곧 추가 예정';

  @override
  String get timelineEntryDetailUpdated => '업데이트 완료 ✓';

  @override
  String timelineEntryTileValue(Object coachNote) {
    return '💬 $coachNote';
  }

  @override
  String get timelineLoadEarlierDays => '이전 기록 불러오기';

  @override
  String get timelineLogYourFirstWorkout =>
      '채팅이나 + 버튼을 사용하여 첫 운동, 식사 또는 수분을 기록하세요. 여기에 표시됩니다.';

  @override
  String get timelineNothingLogged => '기록된 내용이 없습니다.';

  @override
  String get timelineRefresh => '새로고침';

  @override
  String get timelineSearchTimeline => '타임라인 검색';

  @override
  String get timelineSearchTitleOrNotes => '제목 또는 메모 검색…';

  @override
  String timelineSummaryCardDay(Object streakDay) {
    return '$streakDay일차';
  }

  @override
  String timelineSummaryCardHabits(Object habitsCompleted) {
    return '$habitsCompleted개 습관';
  }

  @override
  String timelineSummaryCardKcalIn(Object caloriesEaten) {
    return '$caloriesEaten kcal 섭취';
  }

  @override
  String timelineSummaryCardM(Object workoutsTotalMinutes) {
    return '$workoutsTotalMinutes분';
  }

  @override
  String timelineSummaryCardMl(Object waterGoalMl, Object waterMl) {
    return '$waterMl/$waterGoalMl ml';
  }

  @override
  String timelineSummaryCardMood(Object mood) {
    return '기분: $mood';
  }

  @override
  String get timelineSummaryCardNetKcal => '순 칼로리';

  @override
  String timelineSummaryCardSteps(Object steps) {
    return '$steps 걸음';
  }

  @override
  String timelineSummaryCardXp(Object xpEarned) {
    return '$xpEarned XP';
  }

  @override
  String get timelineTodaySJournal => '오늘의 일지';

  @override
  String get timelineYourDayStartsHere => '당신의 하루가 여기서 시작됩니다';

  @override
  String get timerRestMixinAccept => '수락';

  @override
  String get timerRestMixinGotIt => '확인';

  @override
  String get timerRestMixinRateOfPerceivedExertion =>
      'RPE는 세트가 얼마나 힘들었는지 측정합니다:';

  @override
  String get timerRestMixinWhatIsRpe => 'RPE란 무엇인가요?';

  @override
  String get todayCycleLengthLastCycles => '지난 주기';

  @override
  String get todayCycleLengthLog2CyclesTo => '차트를 보려면 2주기를 기록하세요';

  @override
  String todayCycleLengthSparklineD(Object last) {
    return '$last일';
  }

  @override
  String get todayFertilityWindowFertilityWindow => '가임기';

  @override
  String get todayFertilityWindowLowConfidenceEstimate => '낮은 신뢰도 · 추정치';

  @override
  String get todayScoreCardConnect => '연결';

  @override
  String get todayScoreCardCustomize => '사용자 지정';

  @override
  String get todayScoreCardToday => '오늘';

  @override
  String todayScoreDetailDown(Object arg0) {
    return '▼ 오늘 아침보다 $arg0 하락';
  }

  @override
  String todayScoreDetailEarnedPts(Object arg0, Object arg1) {
    return '$arg0 / $arg1 pt';
  }

  @override
  String get todayScoreDetailHowItWorks => '작동 방식';

  @override
  String todayScoreDetailInactiveExplanation(Object arg0, int arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '집계되지 않습니다',
      one: '집계되지 않습니다',
    );
    return '$arg0은(는) 오늘 $_temp0. 그래서 나머지가 100점 만점을 나눠 가집니다. 점수는 항상 오늘 실제로 해당하는 항목만 반영합니다.';
  }

  @override
  String todayScoreDetailMomentumWithAvg(Object arg0, Object arg1) {
    return '$arg0  ·  7일 평균 $arg1';
  }

  @override
  String get todayScoreDetailNotCounted => '집계되지 않음';

  @override
  String get todayScoreDetailSetupText => '설정 텍스트';

  @override
  String get todayScoreDetailSteady => '안정적';

  @override
  String get todayScoreDetailTodayScore => '오늘의 점수';

  @override
  String todayScoreDetailUp(Object arg0) {
    return '▲ 오늘 아침보다 $arg0 상승';
  }

  @override
  String get todayScoreSetupAddAWorkoutPlan => '운동 계획 추가';

  @override
  String todayScoreSetupCardContinue(Object label) {
    return '계속하기: $label';
  }

  @override
  String todayScoreSetupCardGetStarted(Object completedCount, Object length) {
    return '시작하기 · $completedCount/$length';
  }

  @override
  String get todayScoreSetupTrackYourFirstSleep => '첫 수면 기록하기';

  @override
  String get todayScoreSetupYouReAllSet => '모두 준비되었습니다';

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
  String get todayWorkoutCardCouldNotLoadWorkout => '운동을 불러올 수 없습니다';

  @override
  String get todayWorkoutCardGenerateAWorkoutProgram => '운동 프로그램을 생성하여 시작하세요!';

  @override
  String get todayWorkoutCardGenerateWorkouts => '운동 생성';

  @override
  String todayWorkoutCardInDays(Object daysUntilNext) {
    return '$daysUntilNext일 후';
  }

  @override
  String get todayWorkoutCardLoadingTodaySWorkout => '오늘의 운동 불러오는 중...';

  @override
  String todayWorkoutCardNext(Object name) {
    return '다음: $name';
  }

  @override
  String get todayWorkoutCardNoWorkoutsScheduled => '예정된 운동 없음';

  @override
  String get todayWorkoutCardRestDay => '휴식일';

  @override
  String get todayWorkoutCardStartWorkout => '운동 시작';

  @override
  String get todayWorkoutCardTakeItEasyToday => '오늘은 쉬어가세요! 근육이 회복 중입니다.';

  @override
  String get todayWorkoutCardViewUpcoming => '예정된 운동 보기';

  @override
  String get todaysHealthCardActiveEnergy => '활동 에너지';

  @override
  String get todaysHealthCardAvgHr => '평균 심박수';

  @override
  String get todaysHealthCardConnect => '연결';

  @override
  String get todaysHealthCardConnectHealth => '건강 데이터 연결';

  @override
  String get todaysHealthCardHrRange => '심박수 범위';

  @override
  String get todaysHealthCardRestingHr => '안정 시 심박수';

  @override
  String get todaysHealthCardSyncStepsHeartRate => '걸음 수, 심박수 및 수면 동기화';

  @override
  String get todaysHealthCardTodaySHealth => '오늘의 건강';

  @override
  String get trainingFocusAllocateUpTo5 =>
      '최대 5개의 집중 포인트를 할당하여 특정 근육 그룹을 우선순위에 두세요';

  @override
  String get trainingFocusFocusPoints => '집중 포인트';

  @override
  String get trainingFocusMuscleFocusPoints => '근육 집중 포인트';

  @override
  String get trainingFocusPrimaryTrainingGoal => '주요 훈련 목표';

  @override
  String trainingFocusScreenAvailable(
    Object availablePoints,
    Object maxTotalPoints,
  ) {
    return '$availablePoints/$maxTotalPoints 사용 가능';
  }

  @override
  String trainingFocusScreenFailedToSave(Object e) {
    return '저장 실패: $e';
  }

  @override
  String get trainingFocusTrainingFocus => '훈련 집중';

  @override
  String get trainingFocusTrainingFocusUpdated => '훈련 집중이 업데이트되었습니다';

  @override
  String get trainingLoadAcute7d => '급성 (7일)';

  @override
  String get trainingLoadAskCoachAboutYour => '코치에게 훈련 부하에 대해 물어보세요';

  @override
  String get trainingLoadChartBuildingBaseline => '기준점 구축 중';

  @override
  String trainingLoadChartCouldNotLoadTraining(Object e) {
    return '훈련 부하를 불러올 수 없습니다: $e';
  }

  @override
  String get trainingLoadChartNoCardioActivityYet =>
      '아직 유산소 활동이 없습니다. 달리기, 라이딩 또는 로잉을 기록하여 기준점을 구축하세요.';

  @override
  String get trainingLoadChronic28d => '만성 (28일)';

  @override
  String trainingLoadScreenCouldNotLoadTraining(Object message) {
    return '훈련 부하를 불러올 수 없습니다: $message';
  }

  @override
  String get trainingLoadTrainingLoad => '훈련 부하';

  @override
  String trainingMethodsScreenRest(Object restDisplayHint) {
    return '휴식: $restDisplayHint';
  }

  @override
  String get trainingMethodsTrainingMethods => '훈련 방법';

  @override
  String get trainingPreferencesAddPastWorkoutsFor =>
      '더 정확한 AI 중량 설정을 위해 과거 운동 추가';

  @override
  String get trainingPreferencesBoostedInSelectionCan => '선택 시 가중치 부여, 교체 가능';

  @override
  String get trainingPreferencesCustomizeHowWorkoutsAre => '운동 생성 방식 사용자 지정';

  @override
  String get trainingPreferencesEquipmentAvailableForWorkou =>
      '운동에 사용할 수 있는 장비';

  @override
  String get trainingPreferencesExerciseConsistency => '운동 일관성';

  @override
  String get trainingPreferencesExerciseQueue => '운동 대기열';

  @override
  String get trainingPreferencesExercisesToAvoid => '제외할 운동';

  @override
  String get trainingPreferencesFavoriteExercises => '즐겨찾는 운동';

  @override
  String get trainingPreferencesFirstDayOfThe => '달력의 한 주 시작 요일';

  @override
  String get trainingPreferencesGuaranteedNeverRotateOut => '보장됨, 절대 교체되지 않음';

  @override
  String get trainingPreferencesHowFastToIncrease => '중량 증가 속도';

  @override
  String get trainingPreferencesHowMuchExercisesChange => '매주 운동이 변경되는 정도';

  @override
  String get trainingPreferencesImportWorkoutHistory => '운동 기록 가져오기';

  @override
  String get trainingPreferencesMusclesToAvoid => '제외할 근육';

  @override
  String get trainingPreferencesMy1rms => '나의 1RM';

  @override
  String get trainingPreferencesMyEquipment => '나의 장비';

  @override
  String get trainingPreferencesProgressCharts => '진행 상황 차트';

  @override
  String get trainingPreferencesProgressionPace => '진행 속도';

  @override
  String get trainingPreferencesPushPullLegsFull => '밀기/당기기/하체, 전신 등';

  @override
  String get trainingPreferencesQueueExercisesForNext => '다음 운동을 위한 운동 대기열';

  @override
  String get trainingPreferencesSkipOrReduceMuscle => '근육 그룹 건너뛰기 또는 줄이기';

  @override
  String get trainingPreferencesSkipSpecificExercises => '특정 운동 건너뛰기';

  @override
  String get trainingPreferencesStapleExercises => '필수 운동';

  @override
  String get trainingPreferencesStrengthCardioOrMixed => '근력, 유산소 또는 혼합';

  @override
  String get trainingPreferencesTraining => '트레이닝';

  @override
  String get trainingPreferencesTrainingIntensity => '트레이닝 강도';

  @override
  String get trainingPreferencesTrainingSplit => '트레이닝 분할';

  @override
  String get trainingPreferencesVaryOrKeepSame => '운동 다양화 또는 유지';

  @override
  String get trainingPreferencesViewAndEditYour => '최대 중량 확인 및 수정';

  @override
  String get trainingPreferencesVisualizeStrengthVolumeOv =>
      '시간에 따른 근력 및 볼륨 시각화';

  @override
  String get trainingPreferencesWeekStartsOn => '한 주의 시작 요일';

  @override
  String get trainingPreferencesWeeklyVariety => '주간 다양성';

  @override
  String get trainingPreferencesWhereYouTrain => '운동 장소';

  @override
  String get trainingPreferencesWhichDaysYouTrain => '운동 요일';

  @override
  String get trainingPreferencesWorkAtAPercentage => '최대 중량의 퍼센트로 운동';

  @override
  String get trainingPreferencesWorkoutDays => '운동 일수';

  @override
  String get trainingPreferencesWorkoutEnvironment => '운동 환경';

  @override
  String get trainingPreferencesWorkoutType => '운동 유형';

  @override
  String get trainingProgramSelectorChooseYourTrainingSplit => '트레이닝 분할 선택';

  @override
  String get trainingProgramSelectorCustomProgram => '맞춤형 프로그램';

  @override
  String get trainingProgramSelectorDescribeWhatYouWant =>
      '원하는 운동 목표를 설명하면 AI가 개인화된 프로그램을 생성합니다.';

  @override
  String get trainingProgramSelectorEGTrainFor => '예: \"HYROX 대회 준비\"';

  @override
  String get trainingProgramSelectorExamples => '예시';

  @override
  String get trainingProgramSelectorSaveCustomProgram => '맞춤형 프로그램 저장';

  @override
  String get trainingProgramSelectorTrainingProgram => '트레이닝 프로그램';

  @override
  String get trainingSetupCardAddEquipmentNotIn => '목록에 없는 장비 추가';

  @override
  String get trainingSetupCardEnvironment => '환경';

  @override
  String get trainingSetupCardEquipment => '장비';

  @override
  String get trainingSetupCardExperience => '경험';

  @override
  String get trainingSetupCardFocusAreas => '집중 부위';

  @override
  String get trainingSetupCardHowMuchExerciseVariety => '매주 얼마나 다양한 운동을 원하시나요?';

  @override
  String get trainingSetupCardMyCustomEquipment => '나의 맞춤 장비';

  @override
  String get trainingSetupCardNotSet => '설정 안 됨';

  @override
  String get trainingSetupCardTrainingSetup => '트레이닝 설정';

  @override
  String get trainingSetupCardTrainingSplit => '트레이닝 분할';

  @override
  String trainingSetupCardValue(Object label, Object value) {
    return '$label ($value%)';
  }

  @override
  String get trainingSetupCardWeeklyVariety => '주간 다양성';

  @override
  String get trainingSetupCardWorkoutDays => '운동 일수';

  @override
  String get transitionCountdownOverlayGetReady => '준비하세요';

  @override
  String get transitionCountdownOverlayNextExerciseStartingSoon =>
      '다음 운동이 곧 시작됩니다';

  @override
  String get transitionCountdownOverlayStartNow => '지금 시작';

  @override
  String get transitionCountdownOverlayUpNext => '다음 순서';

  @override
  String get trendAiInsightAiInsight => 'AI 인사이트';

  @override
  String get trendAiInsightCouldnTGenerateAn => '현재 인사이트를 생성할 수 없습니다.';

  @override
  String get trendAiInsightReadingYourTrends => '트렌드 분석 중…';

  @override
  String get trendChartNoDataInThis => '해당 기간에 데이터가 없습니다';

  @override
  String get trendChartPinchToZoomTap => '핀치로 확대 · 탭하여 초기화';

  @override
  String get trendChartTryAWiderTime => '더 넓은 기간을 선택하거나 새로운 기록을 추가하세요';

  @override
  String get trialProgress1DayLeft => '1일 남음';

  @override
  String get trialProgressGoal => '목표: ';

  @override
  String trialProgressWidgetDaysLeft(Object daysRemaining) {
    return '$daysRemaining일 남음';
  }

  @override
  String trialProgressWidgetTrialDay(Object dayOfTrial) {
    return '체험 · $dayOfTrial / 7일차';
  }

  @override
  String get trophiesCardKeepShowingUpBadges =>
      '꾸준히 운동하세요. 마일스톤 달성 시 배지가 잠금 해제됩니다.';

  @override
  String trophiesCardNewBadgesThisPeriod(Object length) {
    return '이번 기간에 획득한 새로운 배지 $length개';
  }

  @override
  String get trophiesCardNoNewBadgesThis => '이번 기간에 획득한 새 배지가 아직 없습니다.';

  @override
  String trophiesCardWrapped(Object appName) {
    return '$appName 연말 결산';
  }

  @override
  String get trophiesCardYourBadges => '나의 배지';

  @override
  String get trophiesEarnedAchievementsUnlocked => '잠금 해제된 업적';

  @override
  String get trophiesEarnedAllMilestonesCleared => '모든 마일스톤 달성';

  @override
  String get trophiesEarnedAllTime => '전체 기간';

  @override
  String get trophiesEarnedCardioAchievements => '유산소 업적';

  @override
  String get trophiesEarnedDayStreak => '연속 운동 일수';

  @override
  String get trophiesEarnedFirstTime => '첫 달성!';

  @override
  String get trophiesEarnedMilestoneReached => '마일스톤 도달';

  @override
  String get trophiesEarnedMilestoneReachedNice => '마일스톤 달성 — 멋져요!';

  @override
  String get trophiesEarnedMilestones => '마일스톤';

  @override
  String trophiesEarnedNewBadges(Object arg0) {
    return '새 배지 $arg0개';
  }

  @override
  String trophiesEarnedNewCardioPRs(Object arg0) {
    return '새 유산소 PR $arg0개';
  }

  @override
  String get trophiesEarnedNewPR => '신기록 PR';

  @override
  String trophiesEarnedNewPRs(Object arg0) {
    return '새 PR $arg0개!';
  }

  @override
  String get trophiesEarnedNewPr => '새로운 PR';

  @override
  String get trophiesEarnedNextMilestones => '다음 마일스톤';

  @override
  String get trophiesEarnedNoNewRecords => '새로운 기록 없음';

  @override
  String get trophiesEarnedNoNewRecordsThis =>
      '이번 세션에 새로운 기록은 없지만, 다음 목표를 향해 나아가고 있습니다:';

  @override
  String get trophiesEarnedPersonalRecords => '개인 기록';

  @override
  String trophiesEarnedRemainingToUnlock(Object arg0, Object arg1) {
    return '잠금 해제까지 $arg1 $arg0개 더';
  }

  @override
  String get trophiesEarnedSessionHighlights => '세션 하이라이트';

  @override
  String trophiesEarnedSheetPts(Object points) {
    return '+$points pts';
  }

  @override
  String trophiesEarnedSheetX(Object reps) {
    return ' x $reps';
  }

  @override
  String get trophiesEarnedTitle => '제목';

  @override
  String get trophiesEarnedTotalWorkouts => '총 운동 횟수';

  @override
  String get trophiesEarnedTrophiesAchievements => '트로피 및 업적';

  @override
  String get trophiesEarnedViewAllCardioPRs => '모든 유산소 PR 보기';

  @override
  String get trophiesEarnedViewAllCardioPrs => '모든 유산소 PR 보기';

  @override
  String get trophiesEarnedYouVeClearedEvery =>
      '모든 마일스톤을 달성했습니다. 꾸준히 유지하면 새로운 마일스톤이 나타날 거예요!';

  @override
  String get trophiesEarnedYourFitnessJourney => '나의 피트니스 여정';

  @override
  String get trophiesEarnedYourSessionHighlights => '이번 세션 하이라이트';

  @override
  String get trophyCardMerch => '굿즈';

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
    return '$currentStreak일 연속 달성!';
  }

  @override
  String get trophyCelebrationOverlayKeepTheMomentumGoing => '지금의 기세를 이어가세요';

  @override
  String get trophyCelebrationOverlayMilestoneReached => '마일스톤 달성!';

  @override
  String get trophyCelebrationOverlayTapAnywhereToContinue =>
      '계속하려면 아무 곳이나 탭하세요';

  @override
  String get trophyCelebrationOverlayTrophiesEarned => '트로피 획득!';

  @override
  String trophyCelebrationOverlayWorkoutsCompleted(Object workoutMilestone) {
    return '운동 $workoutMilestone회 완료';
  }

  @override
  String get trophyCeremonyOverlayCongratsOnEarningThis =>
      '이 트로피를 획득하신 것을 축하합니다!';

  @override
  String trophyCeremonyOverlayLv(Object level) {
    return 'Lv.$level';
  }

  @override
  String get trophyCeremonyOverlayPlayBonusRound => '보너스 라운드 시작';

  @override
  String get trophyFilterFilterTrophies => '트로피 필터';

  @override
  String get trophyFilterReset => '초기화';

  @override
  String trophyFilterSheetApplyFilters(Object activeFilterCount) {
    return '$activeFilterCount개의 필터 적용';
  }

  @override
  String get trophyRoomEarned => '획득함';

  @override
  String get trophyRoomLocked => '잠김';

  @override
  String get trophyRoomMystery => '미스터리';

  @override
  String get trophyRoomMysteryTrophies => '미스터리 트로피';

  @override
  String get trophyRoomPoints => '포인트';

  @override
  String trophyRoomScreenPartTrophyCardComplete(Object progressPercentage) {
    return '$progressPercentage% 완료';
  }

  @override
  String trophyRoomScreenPartTrophyCardValue(Object progressPercentage) {
    return '$progressPercentage%';
  }

  @override
  String get trophyRoomScreenProgressHiddenUntilDiscover => '발견 전까지 진행 상황 숨김';

  @override
  String get trophyRoomScreenTrophyRoom => '트로피 룸';

  @override
  String get trophyRoomSearchTrophies => '트로피 검색...';

  @override
  String get trustAndExpectationsABitOfHonesty => '솔직하게 말씀드리면';

  @override
  String get trustAndExpectationsBeforeWeBuildYour => '계획을 세우기 전에';

  @override
  String get trustAndExpectationsDeleteAnythingAnytime => '언제든지 삭제하세요.';

  @override
  String get trustAndExpectationsEncryptedInTransitAnd => '전송 및 저장 시 암호화됩니다.';

  @override
  String get trustAndExpectationsReadOurFullPrivacy => '개인정보 처리방침 전문 읽기';

  @override
  String get trustAndExpectationsRealChangeShowsUp => '진정한 변화는 3주 차에 나타납니다.';

  @override
  String get trustAndExpectationsSoundsGood => '좋아요';

  @override
  String get trustAndExpectationsTls13Aes =>
      'TLS 1.3 + AES-256. 은행과 동일한 보안 표준입니다.';

  @override
  String get trustAndExpectationsTwoThingsYouShould => '꼭 알아두셔야 할 두 가지.';

  @override
  String get trustAndExpectationsWeNeverSellYour => '데이터를 절대 판매하지 않습니다.';

  @override
  String get trustAndExpectationsWeWonTSugarcoat => '미화하지 않고 말씀드리겠습니다.';

  @override
  String get trustAndExpectationsWeek1WillFeel => '1주 차는 느리게 느껴질 것입니다.';

  @override
  String typingIndicatorIsTyping(Object agentName) {
    return '$agentName 입력 중';
  }

  @override
  String typingIndicatorIsTyping2(Object userName) {
    return '$userName 입력 중';
  }

  @override
  String typingIndicatorIsTyping3(Object agentName) {
    return '$agentName 입력 중...';
  }

  @override
  String get unifiedHomeWidgetsActivity => '활동';

  @override
  String unifiedHomeWidgetsBreakfastLogged(Object arg0) {
    return '최근 7일 중 $arg0일 아침에 아침 식사를 기록함';
  }

  @override
  String get unifiedHomeWidgetsBreakfastSuggestion => '아침 식사 추천';

  @override
  String get unifiedHomeWidgetsCarbs => '탄수화물';

  @override
  String get unifiedHomeWidgetsConnect => '연결';

  @override
  String get unifiedHomeWidgetsConnectAppleHealth => 'Apple Health 연결';

  @override
  String unifiedHomeWidgetsCups(Object cupGoal, Object cups) {
    return '$cups / $cupGoal 컵';
  }

  @override
  String unifiedHomeWidgetsCupsToday(Object arg0, Object arg1) {
    return '오늘 $arg0컵 ($arg1)';
  }

  @override
  String get unifiedHomeWidgetsDrink16ozPostWorkout => '운동 후 16oz 수분 섭취';

  @override
  String unifiedHomeWidgetsEndTheDayAtGoal(Object arg0) {
    return '목표 달성으로 하루 마무리: $arg0';
  }

  @override
  String get unifiedHomeWidgetsFasting => '단식';

  @override
  String get unifiedHomeWidgetsFat => '지방';

  @override
  String unifiedHomeWidgetsG(Object eaten, Object goal) {
    return '$eaten / $goal g';
  }

  @override
  String get unifiedHomeWidgetsKcal => ' kcal';

  @override
  String unifiedHomeWidgetsKcalBurned(Object arg0) {
    return '$arg0 kcal 소모';
  }

  @override
  String get unifiedHomeWidgetsKcalLeft => ' kcal 남음';

  @override
  String get unifiedHomeWidgetsLastNight => '지난밤';

  @override
  String get unifiedHomeWidgetsLog16oz => '16oz 기록';

  @override
  String get unifiedHomeWidgetsNoData => '데이터 없음';

  @override
  String get unifiedHomeWidgetsNoWorkoutWasScheduled => '예정된 운동 없음';

  @override
  String get unifiedHomeWidgetsNutrition => '영양';

  @override
  String get unifiedHomeWidgetsOver => '초과';

  @override
  String get unifiedHomeWidgetsOvernightWaterReset => '수분 섭취량 초기화';

  @override
  String get unifiedHomeWidgetsProtein => '단백질';

  @override
  String get unifiedHomeWidgetsQuickLog => '빠른 기록';

  @override
  String get unifiedHomeWidgetsRefuelHydration => '수분 보충';

  @override
  String get unifiedHomeWidgetsRestDayNoWorkoutScheduled => '휴식일: 예정된 운동 없음';

  @override
  String get unifiedHomeWidgetsRestDayNothingScheduled => '휴식일: 예정된 일정 없음';

  @override
  String get unifiedHomeWidgetsSeeYourStepsCalories =>
      '홈 화면에서 걸음 수, 칼로리, 수면을 확인하세요';

  @override
  String get unifiedHomeWidgetsSleep => '수면';

  @override
  String get unifiedHomeWidgetsStartAFast => '단식 시작 →';

  @override
  String get unifiedHomeWidgetsWakeHydration => '기상 후 수분 섭취';

  @override
  String get unifiedHomeWidgetsWater => '물';

  @override
  String get unifiedHomeWidgetsWorkoutCompleteGreatJob => '운동 완료, 잘하셨습니다!';

  @override
  String get unresolvedExercisesApplyMapping => '매핑 적용';

  @override
  String get unresolvedExercisesBulkFixUnresolvedExercises => '미해결 운동 수정';

  @override
  String get unresolvedExercisesBulkMapRawNamesFrom =>
      '가져온 원본 이름을 라이브러리 운동에 매핑하세요.';

  @override
  String get unresolvedExercisesBulkMore => '더 보기…';

  @override
  String get unresolvedExercisesBulkNoAutoSuggestionOpen =>
      '자동 제안 없음 — 직접 선택하세요.';

  @override
  String get unresolvedExercisesBulkNothingToFixEvery =>
      '수정할 항목 없음 — 모든 가져온 운동이 매핑되었습니다!';

  @override
  String unresolvedExercisesBulkSheetCouldNotLoad(Object error) {
    return '불러올 수 없음: $error';
  }

  @override
  String unresolvedExercisesBulkSheetMap(Object canonicalName) {
    return '매핑 → $canonicalName';
  }

  @override
  String unresolvedExercisesBulkSheetMappedRowsTo(
    Object canonicalName,
    Object rowsAffected,
  ) {
    return '$rowsAffected개 행을 \"$canonicalName\"(으)로 매핑했습니다.';
  }

  @override
  String unresolvedExercisesBulkSheetRevertedRows(Object rowsAffected) {
    return '$rowsAffected개 행을 되돌렸습니다.';
  }

  @override
  String unresolvedExercisesBulkSheetRows(Object rowCount) {
    return '$rowCount개 행';
  }

  @override
  String get unresolvedExercisesBulkUndo => '실행 취소';

  @override
  String get unresolvedExercisesEGBarbellBack => '예: Barbell Back Squat';

  @override
  String get unresolvedExercisesMapExercise => '운동 매핑';

  @override
  String get unresolvedExercisesNoAutomaticSuggestionsFor =>
      '이 이름에 대한 자동 제안이 없습니다.';

  @override
  String get unresolvedExercisesOrTypeACanonical => '또는 표준 이름을 입력하세요';

  @override
  String get unresolvedExercisesSearchLibrary => '라이브러리 검색…';

  @override
  String unresolvedExercisesSheetValue(Object pct, Object source) {
    return '$pct% · $source';
  }

  @override
  String get unresolvedExercisesSuggestions => '제안';

  @override
  String get upNextCardCouldNotLoadSchedule => '일정을 불러올 수 없습니다';

  @override
  String get upNextCardNoUpcomingItemsTap => '예정된 항목이 없습니다. +를 눌러 일정을 추가하세요';

  @override
  String get upNextCardTapToRetry => '탭하여 재시도';

  @override
  String get upNextCardUpNext => '다음 일정';

  @override
  String get upNextCardViewFullSchedule => '전체 일정 보기';

  @override
  String upcomingWorkoutCardMExercises(Object exerciseCount, Object workout) {
    return '$workout분 - 운동 $exerciseCount개';
  }

  @override
  String get upcomingWorkoutsAiWillCreateYour => 'AI가 운동을 생성합니다';

  @override
  String get upcomingWorkoutsCreatingYourPersonalizedWor => '맞춤형 운동 생성 중';

  @override
  String get upcomingWorkoutsEditGymProfile => '헬스장 프로필 수정';

  @override
  String get upcomingWorkoutsGenerating => '생성 중...';

  @override
  String get upcomingWorkoutsLater => '나중에';

  @override
  String get upcomingWorkoutsNoWorkoutDaysScheduled => '예정된 운동일이 없습니다';

  @override
  String get upcomingWorkoutsNotEnoughEquipment => '장비 부족';

  @override
  String upcomingWorkoutsSheetFailedToGenerateWorkout(Object message) {
    return '운동 생성 실패: $message';
  }

  @override
  String upcomingWorkoutsSheetFailedToGenerateWorkout2(Object e) {
    return '운동 생성 실패: $e';
  }

  @override
  String get upcomingWorkoutsTapADateTo => '날짜를 탭하여 운동 생성';

  @override
  String get upcomingWorkoutsTapToGenerate => '탭하여 생성';

  @override
  String get upcomingWorkoutsUpcomingWorkouts => '예정된 운동';

  @override
  String get upcomingWorkoutsUpdateYourWorkoutSchedule => '설정에서 운동 일정을 업데이트하세요';

  @override
  String get upgradePromptDismiss => '닫기';

  @override
  String get upgradePromptLimitReached => '제한 도달';

  @override
  String get upgradePromptSeePremiumPlans => '프리미엄 플랜 보기';

  @override
  String upgradePromptSheetYouVeUsedAll(Object featureName) {
    return '이번 기간 동안 무료 $featureName 사용 횟수를 모두 소진했습니다.';
  }

  @override
  String usageCounterStripLeft(Object displayCount) {
    return '$displayCount개 남음';
  }

  @override
  String userSearchResultCardValue(Object username) {
    return '@$username';
  }

  @override
  String userSearchResultCardWorkouts(Object totalWorkouts) {
    return '운동 $totalWorkouts회';
  }

  @override
  String get vacationModeClear => '지우기';

  @override
  String get vacationModeEndDate => '종료일';

  @override
  String get vacationModeLeaveEmptyForOpen => '무기한 휴가는 비워두세요';

  @override
  String get vacationModeLeaveEmptyToStart => '즉시 시작하려면 비워두세요';

  @override
  String get vacationModeNoChanges => '변경 사항 없음';

  @override
  String vacationModePageFailedToSave(Object e) {
    return '저장 실패: $e';
  }

  @override
  String get vacationModeSaveChanges => '변경 사항 저장';

  @override
  String get vacationModeStartDate => '시작일';

  @override
  String get vacationModeSuppressingNonCriticalNotif => '중요하지 않은 알림 억제 중';

  @override
  String get vacationModeVacationMode => '휴가 모드';

  @override
  String get vacationModeVacationModeSettingsSaved => '휴가 모드 설정이 저장되었습니다';

  @override
  String get vacationModeVacationStartMustBe => '휴가 시작일은 종료일 이전이어야 합니다';

  @override
  String get vacationModeWhatVacationModeDoes => '휴가 모드 기능 안내';

  @override
  String viralExtrasW(Object marketingDomain, Object shortId) {
    return '$marketingDomain/w/$shortId';
  }

  @override
  String get vo2maxDetail30DayAvg => '30일 평균';

  @override
  String get vo2maxDetailAllTimeBest => '역대 최고 기록';

  @override
  String get vo2maxDetailAskCoach => '코치에게 문의';

  @override
  String get vo2maxDetailCurrent => '현재';

  @override
  String get vo2maxDetailLast180Days => '최근 180일';

  @override
  String get vo2maxDetailLatestVo2max => '최신 VO2max';

  @override
  String get vo2maxDetailMlKgMin => 'ml/kg/min';

  @override
  String get vo2maxDetailNoVo2maxYet => '아직 VO2max 기록 없음';

  @override
  String vo2maxDetailScreenAsOf(Object whenStr) {
    return '$whenStr 기준';
  }

  @override
  String vo2maxDetailScreenCouldNotLoadVo(Object error) {
    return 'VO2max를 불러올 수 없습니다.\n$error';
  }

  @override
  String vo2maxDetailScreenFitnessAge(Object fitnessAge) {
    return '신체 나이 $fitnessAge';
  }

  @override
  String vo2maxDetailScreenPts(Object length) {
    return '$length pts';
  }

  @override
  String get vo2maxDetailTrendWillAppearAfter => '측정 기록이 몇 번 쌓이면 추세가 나타납니다.';

  @override
  String get vo2maxDetailVo2max => 'VO2max';

  @override
  String get voiceAnnouncementsAnnouncingExerciseNamesDuri =>
      '운동 전환 시 운동 이름 안내';

  @override
  String get voiceAnnouncementsMicFabOnActive =>
      '운동 중 마이크 FAB 활성화 — \"225 for 5\"';

  @override
  String get voiceAnnouncementsTestVoice => '음성 테스트';

  @override
  String get voiceAnnouncementsVoiceAnnouncements => '음성 안내';

  @override
  String get voiceAnnouncementsVoiceAnnouncements2 => '음성 안내';

  @override
  String get voiceAnnouncementsVoiceSetLogging => '음성 세트 기록';

  @override
  String get voiceAnnouncementsWhenEnabledYouWill => '활성화 시 다음 내용을 듣게 됩니다:';

  @override
  String get voiceMicFabHearing => '듣는 중…';

  @override
  String get volumeAlertCardAcknowledge => '확인';

  @override
  String volumeAlertCardIncrease(
    Object formattedIncrease,
    Object muscleGroupDisplay,
  ) {
    return '$muscleGroupDisplay: $formattedIncrease 증가';
  }

  @override
  String get volumeAlertCardVolumeAlert => '볼륨 알림';

  @override
  String volumeAlertCardVolumeAlerts(Object length) {
    return '볼륨 알림 $length개';
  }

  @override
  String get volumeCardTotalVolumeLifted => '총 들어 올린 볼륨';

  @override
  String get volumeChartAverage => '평균';

  @override
  String get volumeChartCompleteSomeWorkoutsTo => '운동을 완료하여 볼륨 추세를 확인하세요.';

  @override
  String get volumeChartDangerousIncrease => '위험한 증가';

  @override
  String get volumeChartLogAFewWeighted => '중량 세트를 몇 번 기록하여 볼륨 추세를 확인하세요.';

  @override
  String volumeChartMuscleGroupVolume(Object muscleGroup) {
    return '$muscleGroup 볼륨';
  }

  @override
  String volumeChartNRisky(Object count) {
    return '$count건 위험';
  }

  @override
  String get volumeChartNoVolumeData => '볼륨 데이터 없음';

  @override
  String get volumeChartNoWeightedVolumeYet => '아직 중량 볼륨 기록 없음';

  @override
  String get volumeChartPeak => '최고치';

  @override
  String get volumeChartVolume => '볼륨';

  @override
  String get volumeChartVolumeTrends => '볼륨 추세';

  @override
  String get volumeChartWeeklyVolumeTrend => '주간 볼륨 추이';

  @override
  String get volumeChartWeeks => '주';

  @override
  String get volumeHeroTemplateExercises => '운동';

  @override
  String volumeHeroTemplateThatS(Object comparison) {
    return '— $comparison —';
  }

  @override
  String get volumeHistoryCompleteWorkoutsToSee => '운동을 완료하여 볼륨 추세 확인';

  @override
  String get volumeHistoryFailedToLoad => '불러오기 실패';

  @override
  String get volumeHistoryNoHistoryYet => '아직 기록 없음';

  @override
  String volumeHistoryScreenSets(Object totalSets) {
    return '$totalSets세트';
  }

  @override
  String volumeHistoryScreenValue(Object key, Object value) {
    return '$key: $value';
  }

  @override
  String get volumeHistoryTotalVolume => '총 볼륨';

  @override
  String get volumeHistoryVolumeHistory => '볼륨 기록';

  @override
  String get volumeProgressionCardDefineCustomProgressionVia =>
      'JSON을 통해 사용자 지정 점진적 과부하 정의 (고급)';

  @override
  String get volumeProgressionCardHowTrainingVolumeIncreases =>
      '시간에 따른 훈련 볼륨 증가 방식';

  @override
  String volumeProgressionCardValue(Object v) {
    return '$v%';
  }

  @override
  String get volumeProgressionCardVolumeProgressionCurves => '볼륨 점진적 과부하 곡선';

  @override
  String volumeProgressionCardW(Object v) {
    return '$v주차';
  }

  @override
  String get volumeProgressionCardWavePatternVolumeCycles =>
      '웨이브 패턴: 주간 볼륨 주기 반복';

  @override
  String get warmupControllerPause => '일시정지';

  @override
  String get warmupControllerSkipWarmup => '웜업 건너뛰기';

  @override
  String get warmupControllerStartWorkout => '운동 시작';

  @override
  String get warmupControllerUpNext => '다음 순서';

  @override
  String get warmupControllerWarmUp => '웜업';

  @override
  String get warmupCooldownCard1Min => '1분';

  @override
  String warmupCooldownCardMin(Object warmupDurationMinutes) {
    return '$warmupDurationMinutes분';
  }

  @override
  String get warmupCooldownCardPreciseDurationControl1 => '정밀한 시간 조절 (1-15분)';

  @override
  String get warmupCooldownCardWarmupCooldown => '웜업 및 쿨다운';

  @override
  String get warmupPhaseIncline => '경사도';

  @override
  String get warmupPhaseIntervals => '인터벌';

  @override
  String get warmupPhasePause => '일시정지';

  @override
  String warmupPhaseScreenSec(Object duration) {
    return '$duration초';
  }

  @override
  String get warmupPhaseSkipWarmup => '웜업 건너뛰기';

  @override
  String get warmupPhaseSpeed => '속도';

  @override
  String get warmupPhaseStartWorkout => '운동 시작';

  @override
  String get warmupPhaseUpNext => '다음 순서';

  @override
  String get warmupPhaseWarmUp => '웜업';

  @override
  String get warmupSettingsCooldownStretchDuration => '쿨다운 스트레칭 시간';

  @override
  String get warmupSettingsEnableCooldownStretch => '쿨다운 스트레칭 활성화';

  @override
  String get warmupSettingsEnableWarmupPhase => '웜업 단계 활성화';

  @override
  String get warmupSettingsHowLongToStretch => '운동 후 스트레칭 시간';

  @override
  String get warmupSettingsHowLongToWarm => '운동 전 웜업 시간';

  @override
  String get warmupSettingsIncompleteExerciseWarning => '미완료 운동 경고';

  @override
  String warmupSettingsSectionMin(Object label, Object minutes) {
    return '$label ($minutes분)';
  }

  @override
  String get warmupSettingsShowStretchScreenAfter => '운동 후 스트레칭 화면 표시';

  @override
  String get warmupSettingsShowWarmupScreenBefore => '운동 전 웜업 화면 표시';

  @override
  String get warmupSettingsTipsForEffectiveWarm => '효과적인 웜업 팁:';

  @override
  String get warmupSettingsWarmupCooldown => '웜업 및 쿨다운';

  @override
  String get warmupSettingsWarmupDuration => '웜업 시간';

  @override
  String get warmupSettingsWarnBeforeFinishingWith =>
      '기록되지 않은 세트가 있을 때 종료 전 경고';

  @override
  String get watchInstallBannerCouldNotOpenPlay =>
      '워치에서 Play 스토어를 열 수 없습니다. 수동으로 설치해 주세요.';

  @override
  String get watchInstallBannerFailedToConnectTo =>
      '워치 연결에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get watchInstallBannerInstallOnWatch => '워치에 설치';

  @override
  String get watchInstallBannerNotNow => '나중에';

  @override
  String get watchInstallBannerTrackWorkoutsFromYour => '손목에서 바로 운동 기록';

  @override
  String get watchInstallBannerWatchDetected => '워치 감지됨';

  @override
  String get wearOsAutomaticDataSync => '자동 데이터 동기화';

  @override
  String get wearOsComingFeatures => '출시 예정 기능:';

  @override
  String get wearOsLogSetsDirectlyFromWatch => '워치에서 직접 세트 기록';

  @override
  String get wearOsQuickFoodLoggingViaVoice => '음성으로 빠른 음식 기록';

  @override
  String get wearOsRealTimeHeartRateTracking => '실시간 심박수 추적';

  @override
  String get wearOsSmartwatch => '스마트워치';

  @override
  String get wearOsTrackWorkoutsFromYour => '손목에서 바로 운동 기록';

  @override
  String get wearOsWearOs => 'WEAR OS';

  @override
  String get week1TipBannerTryIt => '시도해 보기';

  @override
  String get weekChangesCardConsistent => '일관성 유지';

  @override
  String get weekChangesCardLastWeek => '지난주';

  @override
  String weekChangesCardMoreNewExercises(Object newExercises) {
    return '새로운 운동 $newExercises개 추가';
  }

  @override
  String get weekChangesCardNewThisWeek => '이번 주 새로 추가됨';

  @override
  String get weekChangesCardRotatedOut => '제외됨';

  @override
  String get weekChangesCardThisWeek => '이번 주';

  @override
  String get weekChangesCardThisWeekSChanges => '이번 주의 변경 사항';

  @override
  String get weekChangesCardWeekComparison => '주간 비교';

  @override
  String get weekChangesCardYourFirstWeek => '첫 번째 주';

  @override
  String get weekDurationSelectorCustomizeDuration => '기간 맞춤 설정';

  @override
  String get weekDurationSelectorDuration => '기간';

  @override
  String get weekDurationSelectorSessionsWeek => '주간 세션 수';

  @override
  String weekDurationSelectorW(Object first) {
    return '$first주';
  }

  @override
  String weekDurationSelectorWeeks(Object selectedWeeks) {
    return '$selectedWeeks주';
  }

  @override
  String weekDurationSelectorWk(Object spw) {
    return '주 $spw회';
  }

  @override
  String weekProgressStripCompletedCount(Object arg0, Object arg1) {
    return '$arg1개 중 $arg0개 운동 완료';
  }

  @override
  String get weekProgressStripCouldNotLoadProgress => '진행 상황을 불러올 수 없습니다';

  @override
  String get weekProgressStripLoading => '불러오는 중...';

  @override
  String get weekProgressStripNoWorkoutsScheduled => '예정된 운동 없음';

  @override
  String get weekProgressStripThisWeek => '이번 주';

  @override
  String get weekProgressStripViewAll => '모두 보기';

  @override
  String get weeklyCalendarTileThisWeek => '이번 주';

  @override
  String get weeklyCheckinAnalyzingYourProgress => '진행 상황 분석 중...';

  @override
  String get weeklyCheckinAppearsOnceAWeek => '매주 1회 표시';

  @override
  String get weeklyCheckinApplyChanges => '변경 사항 적용';

  @override
  String get weeklyCheckinConservativeModerateOrAgg =>
      '보수적, 보통, 공격적 — 각각 다른 칼로리 목표와 예상 주간 변화량을 제공합니다.';

  @override
  String get weeklyCheckinDisable => '비활성화';

  @override
  String get weeklyCheckinDisableWeeklyCheckIn => '주간 체크인을 비활성화할까요?';

  @override
  String get weeklyCheckinDonTShowThis => '다시 보지 않기';

  @override
  String get weeklyCheckinGotIt => '확인';

  @override
  String get weeklyCheckinGotItShowMy => '확인 — 체크인 보기';

  @override
  String get weeklyCheckinKeepCurrent => '현재 상태 유지';

  @override
  String get weeklyCheckinKeepIt => '유지하기';

  @override
  String get weeklyCheckinPickAPlanTo =>
      '목표를 업데이트할 플랜을 선택하거나 건너뛰어 현재 상태를 유지하세요. 자동으로 변경되는 것은 없습니다.';

  @override
  String get weeklyCheckinPleaseTryAgainLater => '나중에 다시 시도해주세요';

  @override
  String get weeklyCheckinReviewProgressChooseYour => '진행 상황 검토 및 경로 선택';

  @override
  String get weeklyCheckinSheetAdherence => '준수도';

  @override
  String get weeklyCheckinSheetAdherenceSustainability => '준수도 및 지속 가능성';

  @override
  String get weeklyCheckinSheetAvgCalories => '평균 칼로리';

  @override
  String get weeklyCheckinSheetAvgProtein => '평균 단백질';

  @override
  String get weeklyCheckinSheetBasedOnActualIntake => '실제 섭취량 및 체중 변화 기준';

  @override
  String get weeklyCheckinSheetBuildingYourProfile => '프로필 생성 중';

  @override
  String get weeklyCheckinSheetCalories => '칼로리';

  @override
  String get weeklyCheckinSheetCaloriesDay => 'kcal/일';

  @override
  String get weeklyCheckinSheetCarbs => '탄수화물';

  @override
  String get weeklyCheckinSheetChooseYourPath => '경로 선택';

  @override
  String get weeklyCheckinSheetComplete => '완료!';

  @override
  String get weeklyCheckinSheetConfidenceRange => '신뢰 구간';

  @override
  String get weeklyCheckinSheetDataQuality => '데이터 품질';

  @override
  String get weeklyCheckinSheetDaysLogged => '기록된 일수';

  @override
  String get weeklyCheckinSheetEmaSmoothedCalculation => 'EMA 평활화 계산';

  @override
  String weeklyCheckinSheetEveryWeekAnalysesYour(Object appName) {
    return '매주 $appName이(가) 귀하의 식단 기록을 분석하여 실제 소모 칼로리를 계산하고, 진행 상황에 맞춰 더 스마트한 칼로리 및 매크로 목표를 제안합니다.';
  }

  @override
  String get weeklyCheckinSheetFat => '지방';

  @override
  String get weeklyCheckinSheetFoodLogging => '식단 기록';

  @override
  String get weeklyCheckinSheetKeepLogging => '계속 기록하세요!';

  @override
  String get weeklyCheckinSheetKeepLoggingYourMeals =>
      '식단과 체중을 계속 기록하여 개인 맞춤형 TDEE 계산을 잠금 해제하세요.';

  @override
  String get weeklyCheckinSheetLogMealsConsistentlyFor =>
      '최상의 결과를 위해 꾸준히 식단을 기록하세요';

  @override
  String get weeklyCheckinSheetMetabolicAdaptationDetected => '대사 적응 감지됨';

  @override
  String get weeklyCheckinSheetNeed60DataQuality =>
      '정확한 계산을 위해 60% 이상의 데이터 품질이 필요합니다';

  @override
  String get weeklyCheckinSheetNewTargets => '새로운 목표';

  @override
  String weeklyCheckinSheetPartRecommendationOptionCardCal(Object calories) {
    return '$calories cal';
  }

  @override
  String weeklyCheckinSheetPartRecommendationOptionCardDays(
    Object current,
    Object target,
  ) {
    return '$target일 중 $current일';
  }

  @override
  String weeklyCheckinSheetPartRecommendationOptionCardGC(Object carbsG) {
    return '${carbsG}g 탄수화물';
  }

  @override
  String weeklyCheckinSheetPartRecommendationOptionCardGF(Object fatG) {
    return '${fatG}g 지방';
  }

  @override
  String weeklyCheckinSheetPartRecommendationOptionCardGP(Object proteinG) {
    return '${proteinG}g 단백질';
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
    return '체중 추이: $formattedWeeklyRate';
  }

  @override
  String get weeklyCheckinSheetPlateauDetected => '정체기 감지됨';

  @override
  String get weeklyCheckinSheetProtein => '단백질';

  @override
  String get weeklyCheckinSheetRecommended => '권장';

  @override
  String get weeklyCheckinSheetRecommendedAdjustment => '권장 조정';

  @override
  String get weeklyCheckinSheetSelectARecommendationBased =>
      '선호도에 따라 권장 사항을 선택하세요';

  @override
  String weeklyCheckinSheetSuggestedAction(Object action) {
    return '제안: $action';
  }

  @override
  String get weeklyCheckinSheetSustainability => '지속 가능성';

  @override
  String weeklyCheckinSheetSustainabilityRating(Object rating) {
    return '$rating 지속 가능성';
  }

  @override
  String get weeklyCheckinSheetThisWeek => '이번 주';

  @override
  String get weeklyCheckinSheetTipsForBetterResults => '더 나은 결과를 위한 팁';

  @override
  String get weeklyCheckinSheetWeNeedABit =>
      '개인 맞춤형 TDEE를 계산하려면 데이터가 조금 더 필요합니다.';

  @override
  String get weeklyCheckinSheetWeightChange => '체중 변화';

  @override
  String get weeklyCheckinSheetWeightLogs => '체중 기록';

  @override
  String get weeklyCheckinSheetYouReOnTrack => '잘하고 계십니다!';

  @override
  String get weeklyCheckinSheetYourAdaptiveTdee => '나의 적응형 TDEE';

  @override
  String get weeklyCheckinSheetYourCurrentTargetsAre =>
      '현재 목표는 진행 상황과 잘 맞습니다. 지금처럼 계속 노력하세요!';

  @override
  String get weeklyCheckinSkipThisWeek => '이번 주 건너뛰기';

  @override
  String get weeklyCheckinTryAgain => '다시 시도';

  @override
  String get weeklyCheckinUnableToLoadData => '데이터를 불러올 수 없습니다';

  @override
  String get weeklyCheckinWeAnalyseYourWeek => '한 주를 분석합니다';

  @override
  String get weeklyCheckinWeeklyCheckIn => '주간 체크인';

  @override
  String get weeklyCheckinWhatHappensEachWeek => '매주 진행되는 과정';

  @override
  String get weeklyCheckinWhatIsThis => '이게 무엇인가요?';

  @override
  String get weeklyCheckinWhatIsWeeklyCheck => '주간 체크인이란 무엇인가요?';

  @override
  String get weeklyCheckinYouCanReEnable => '영양 설정에서 언제든지 다시 활성화할 수 있습니다.';

  @override
  String get weeklyCheckinYouCanTurnThis =>
      '영양 설정 → 주간 체크인 알림에서 언제든지 끌 수 있습니다.';

  @override
  String get weeklyCheckinYouChooseOrSkip => '직접 선택하거나 건너뛰세요';

  @override
  String get weeklyCheckinYouLlMissOut => '다음 혜택을 놓치게 됩니다:';

  @override
  String get weeklyCheckinYouSee23 => '2~3가지 플랜 옵션 확인';

  @override
  String get weeklyCheckinYourLoggedMealsAnd =>
      '기록된 식단과 체중 데이터는 어떤 공식보다 정확한 실제 TDEE를 계산하는 데 사용됩니다.';

  @override
  String weeklyGoalsCardNewPr(Object prsThisWeek) {
    return '🏆 이번 주 $prsThisWeek개의 새로운 PR 달성!';
  }

  @override
  String get weeklyGoalsCardSetAChallengeTo => '한계를 뛰어넘을 챌린지를 설정하세요!';

  @override
  String get weeklyGoalsCardWeeklyGoals => '주간 목표';

  @override
  String get weeklyHighlightsTemplateAiHighlights => 'AI 하이라이트';

  @override
  String get weeklyHighlightsTemplateAnotherWeekInThe =>
      '또 한 주가 지났습니다. 꾸준함이 진짜 실력입니다.';

  @override
  String get weeklyHighlightsTemplateThisWeek => '이번 주';

  @override
  String weeklyPercentileHeroOfActiveUsersTap(
    Object totalActive,
    Object yourRank,
  ) {
    return '활성 사용자 $totalActive명 중 #$yourRank위 · 탭하여 둘러보기';
  }

  @override
  String weeklyPercentileHeroTopThisWeek(Object topPct) {
    return '이번 주 상위 $topPct%';
  }

  @override
  String get weeklyPlanCardCreateYourWeeklyPlan => '주간 플랜 만들기';

  @override
  String get weeklyPlanCardGetAHolisticPlan =>
      '운동, 영양, 단식을 조율하는 종합적인 플랜을 받아보세요';

  @override
  String get weeklyPlanCardTodaySPlan => '오늘의 플랜';

  @override
  String get weeklyPlanCardWeeklyPlan => '주간 계획';

  @override
  String get weeklyPlanCreateAHolisticPlan =>
      '운동, 영양, 단식 일정을 조율하여 일주일간의 종합적인 계획을 세워보세요.';

  @override
  String get weeklyPlanErrorLoadingPlan => '계획을 불러오는 중 오류가 발생했습니다';

  @override
  String get weeklyPlanGenerateMyPlan => '내 계획 생성하기';

  @override
  String get weeklyPlanGeneratePlan => '계획 생성하기';

  @override
  String get weeklyPlanNoWeeklyPlanYet => '아직 주간 계획이 없습니다';

  @override
  String get weeklyPlanWeeklyPlan => '주간 계획';

  @override
  String weeklyProgressCardOfWorkouts(Object completed, Object total) {
    return '운동 $total개 중 $completed개 완료';
  }

  @override
  String get weeklyPrsTemplate1Pr => '1 PR';

  @override
  String weeklyPrsTemplateMore(Object length) {
    return '+ $length개 더';
  }

  @override
  String get weeklyPrsTemplateNoPrsThisWeek => '이번 주에 달성한 PR이 없습니다';

  @override
  String get weeklyPrsTemplatePersonalRecords => '개인 최고 기록 (PR)';

  @override
  String weeklyPrsTemplatePrs(Object count) {
    return 'PR $count개';
  }

  @override
  String get weeklyPrsTemplateShowingUpIsThe =>
      '꾸준히 하는 것이 곧 승리입니다. 다음 주도 힘내세요.';

  @override
  String get weeklyRecap => '🛡️';

  @override
  String get weeklyRecapBonusRound => '보너스 라운드';

  @override
  String get weeklyRecapCatchNutrientsWinBonus => '영양소를 챙기고 보너스 XP를 획득하세요';

  @override
  String weeklyRecapDialogRankShieldsActivated(Object count) {
    return '랭크 보호막 $count개 활성화됨';
  }

  @override
  String weeklyRecapDialogValue(Object rank) {
    return '#$rank';
  }

  @override
  String weeklyRecapDialogWeekIn(Object tierLabel, Object weeks) {
    return '$tierLabel $weeks주차';
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
  String get weeklyRecapEarnedLastWeek => '지난주 획득';

  @override
  String get weeklyRecapLastWeek => '지난주';

  @override
  String get weeklyRecapPassed => '통과';

  @override
  String get weeklyRecapPassedBy => '추월당함';

  @override
  String get weeklyRecapRankShieldActivatedStreak => '랭크 쉴드 활성화됨 — 연속 기록 유지';

  @override
  String get weeklyRecapRewardsUnlocked => '보상 잠금 해제';

  @override
  String get weeklyRecapStartThisWeek => '이번 주 시작하기 →';

  @override
  String get weeklyRecapTemplatePrs => 'PR';

  @override
  String get weeklyRecapTemplateStreak => '연속 기록';

  @override
  String weeklyRecapTemplateValue(Object pct) {
    return '$pct%';
  }

  @override
  String get weeklyRecapTemplateWorkouts => '운동';

  @override
  String get weeklyRecapWeeklyRecap => '주간 요약';

  @override
  String weeklyReportCardDayStreak(Object streak) {
    return '$streak일 연속 달성';
  }

  @override
  String weeklyReportCardOfWorkoutsThisWeek(
    Object completed,
    Object scheduled,
  ) {
    return '이번 주 운동 $scheduled회 중 $completed회 완료';
  }

  @override
  String get weeklyReportCardReportsInsights => '리포트 및 인사이트';

  @override
  String weeklyReportCardValue(Object pct) {
    return '$pct%';
  }

  @override
  String get weeklyReportCardViewReport => '리포트 보기';

  @override
  String get weeklySummaryAiSummary => 'AI 요약';

  @override
  String get weeklySummaryGenerateSummary => '요약 생성하기';

  @override
  String get weeklySummaryGenerateYourFirstWeekly =>
      '첫 주간 요약을 생성하여 AI 기반 인사이트로 진행 상황을 확인해보세요';

  @override
  String get weeklySummaryHighlights => '하이라이트';

  @override
  String get weeklySummaryNoSummariesYet => '아직 요약이 없습니다';

  @override
  String weeklySummaryScreenDayStreak(Object streak) {
    return '$streak일 연속';
  }

  @override
  String weeklySummaryScreenPrs(Object count) {
    return 'PR $count개';
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
    return '운동 $workoutsCompleted/$workoutsScheduled회 완료';
  }

  @override
  String get weeklySummaryShareReport => '리포트 공유하기';

  @override
  String get weeklySummaryTapToViewDetails => '탭하여 상세 정보 보기';

  @override
  String get weeklySummaryTipsForNextWeek => '다음 주를 위한 팁';

  @override
  String get weeklySummaryWeeklySummaries => '주간 요약';

  @override
  String get weeklySummaryWeeklySummaryGenerated => '주간 요약이 생성되었습니다!';

  @override
  String get weeklyVolumeBarsWeeklyVolumePerMuscle => '근육별 주간 볼륨';

  @override
  String get weeklyWrappedFromYourCoach => '코치의 메시지';

  @override
  String get weeklyWrappedNoWorkoutsScheduledYet =>
      '아직 예정된 운동이 없습니다. 홈 화면에서 계획을 생성하세요.';

  @override
  String get weeklyWrappedPrs => 'PR';

  @override
  String get weeklyWrappedSets => '세트';

  @override
  String get weeklyWrappedStreak => '연속 기록';

  @override
  String get weeklyWrappedYourWeek => '이번 주 요약';

  @override
  String get weightFastingChartNoWeightDataAvailable => '체중 데이터가 없습니다';

  @override
  String get weightFastingChartWeightTrends => '체중 변화 추이';

  @override
  String get weightIncrementsBarbell => '바벨';

  @override
  String get weightIncrementsBasedOnStandardCommercial => '표준 상업용 헬스장 장비 기준:';

  @override
  String get weightIncrementsCardConfigureIncrements => '증분 설정';

  @override
  String get weightIncrementsCardCustomizeStepPerEquipme => '장비 유형별 +/- 단위 설정';

  @override
  String get weightIncrementsCardWeightIncrements => '중량 증분';

  @override
  String get weightIncrementsCustomIncrement => '사용자 지정 증분';

  @override
  String get weightIncrementsCustomizeStepSizePer => '장비별 +/- 단위 크기 설정';

  @override
  String get weightIncrementsEG25 => '예: 2.5';

  @override
  String get weightIncrementsGotIt => '확인';

  @override
  String get weightIncrementsPerSide => '한쪽당';

  @override
  String get weightIncrementsSet => '설정';

  @override
  String weightIncrementsSheetSide(Object unit) {
    return '한쪽당 $unit';
  }

  @override
  String weightIncrementsSheetTotal(Object unit) {
    return '총 $unit';
  }

  @override
  String get weightIncrementsSourcesRogueLifeFitness =>
      '출처: Rogue, Life Fitness, Eleiko';

  @override
  String get weightIncrementsUseDefaults => '기본값 사용';

  @override
  String get weightIncrementsWeightIncrements => '중량 증분';

  @override
  String get weightProjectionCurrent => '현재';

  @override
  String get weightProjectionHowFastDoYou => '얼마나 빠르게 감량하고 싶으신가요?';

  @override
  String get weightProjectionPerWeek => '주당';

  @override
  String get weightProjectionSafeRate05 =>
      '권장 속도: 주당 0.5–1kg. Zealova의 계획은 과학적 가이드라인을 따릅니다.';

  @override
  String get weightProjectionScreenContinueToYourPlan => '계획 계속하기';

  @override
  String weightProjectionScreenDaysWk(Object workoutDays) {
    return '주 $workoutDays일';
  }

  @override
  String get weightProjectionScreenLetSKeepYou =>
      '현재 상태를 유지하세요! 전반적인 체력, 근력 및 에너지 수준을 향상시키면서 현재의 체형을 유지하는 데 집중할 것입니다.';

  @override
  String get weightProjectionScreenYouReAtYour => '이상적인 체중입니다!';

  @override
  String get weightProjectionToGain => '증량 목표';

  @override
  String get weightProjectionToLose => '감량 목표';

  @override
  String get weightTrackingCardHighest => '최고';

  @override
  String get weightTrackingCardLowest => '최저';

  @override
  String get weightTrackingCardRecentEntries => '최근 기록';

  @override
  String get weightTrackingCardSeeAll => '모두 보기';

  @override
  String weightTrackingCardValue(Object label, Object value) {
    return '$value · $label';
  }

  @override
  String get weightTrackingCardWeightTracking => '체중 기록';

  @override
  String weightTrendCardDownThisWeek(Object arg0) {
    return '이번 주 $arg0 감량!';
  }

  @override
  String weightTrendCardDownVsLastCycle(Object arg0) {
    return '지난달 같은 주기일 대비 $arg0 lbs 감량';
  }

  @override
  String get weightTrendCardLoadingWeight => '체중 불러오는 중...';

  @override
  String get weightTrendCardLogYourWeightTo => '체중을 기록하여 변화를 확인하세요';

  @override
  String get weightTrendCardMaintaining => '유지 중';

  @override
  String get weightTrendCardNoChange => '변화 없음';

  @override
  String get weightTrendCardNoData => '데이터 없음';

  @override
  String get weightTrendCardOnTrack => '목표 달성 중';

  @override
  String get weightTrendCardReviewGoals => '목표 검토';

  @override
  String get weightTrendCardSameAsLastCycle => '지난 주기와 동일';

  @override
  String get weightTrendCardTapToLogWeight => '탭하여 체중 기록하기';

  @override
  String get weightTrendCardTargetHeld => '목표 유지';

  @override
  String weightTrendCardTargetHeldWindow(Object arg0) {
    return '목표 유지 $arg0 — 황체기 수분 보정';
  }

  @override
  String weightTrendCardUpThisWeek(Object arg0) {
    return '이번 주 $arg0 증가';
  }

  @override
  String weightTrendCardUpVsLastCycle(Object arg0) {
    return '지난달 같은 주기일 대비 $arg0 lbs 증가';
  }

  @override
  String get weightTrendCardWeightStableThisWeek => '이번 주 체중 안정';

  @override
  String get weightTrendCardWeightTrends => '체중 변화 추이';

  @override
  String get welcomeAffirmationGreatChoice => '탁월한 선택입니다.';

  @override
  String get welcomeAffirmationLetSBegin => '시작해봅시다';

  @override
  String get welcomeAffirmationMostUsersHitTheir =>
      '대부분의 사용자가 30일 이내에 첫 번째 마일스톤을 달성합니다';

  @override
  String get welcomeAffirmationYouReAboutTo => '당신도 곧 그렇게 될 것입니다.';

  @override
  String get welcomeAffirmationYouReInThe => '잘 찾아오셨습니다.\n함께 계획을 세워봅시다.';

  @override
  String get wellnessCheckinCardAddANoteOptional => '메모 추가 (선택 사항)';

  @override
  String get wellnessCheckinCardCheckedInU2713 => '체크인 완료 ✓';

  @override
  String get wellnessCheckinCardDailyWellnessCheckIn => '일일 웰니스 체크인';

  @override
  String wellnessCheckinCardEnergy(Object energyLevel) {
    return '에너지 $energyLevel  ';
  }

  @override
  String get wellnessCheckinCardEnergyLevel => '에너지 레벨';

  @override
  String get wellnessCheckinCardHowSYourMood => '오늘 기분은 어떠신가요?';

  @override
  String get wellnessCheckinCardMuscleSoreness => '근육통';

  @override
  String wellnessCheckinCardSleep(Object sleepQuality) {
    return '수면 $sleepQuality  ';
  }

  @override
  String get wellnessCheckinCardSleepQuality => '수면 품질';

  @override
  String wellnessCheckinCardSoreness(Object muscleSoreness) {
    return '근육통 $muscleSoreness  ';
  }

  @override
  String wellnessCheckinCardStress(Object stressLevel) {
    return '스트레스 $stressLevel  ';
  }

  @override
  String get wellnessCheckinCardStressLevel => '스트레스 레벨';

  @override
  String get wellnessCheckinCardU1f9d8 => '🧘';

  @override
  String get workoutActionsChangeWorkoutDate => '운동 날짜 변경';

  @override
  String get workoutActionsCompleteTheWorkoutFirst =>
      '공유 링크를 생성하려면 먼저 운동을 완료하세요';

  @override
  String get workoutActionsCoolDownStretches => '쿨다운 스트레칭';

  @override
  String get workoutActionsCouldNotCreateShare => '공유 링크를 생성할 수 없습니다';

  @override
  String get workoutActionsCreateCoolDownStretches => '쿨다운 스트레칭 생성';

  @override
  String get workoutActionsCreateWarmupExercises => '웜업 운동 생성';

  @override
  String get workoutActionsCurrent => '현재의';

  @override
  String get workoutActionsDeleteWorkout => '운동 삭제';

  @override
  String get workoutActionsDeleteWorkout2 => '운동을 삭제하시겠습니까?';

  @override
  String get workoutActionsFailedToGenerateStretches => '스트레칭 생성 실패';

  @override
  String get workoutActionsFailedToGenerateWarmup => '웜업 생성 실패';

  @override
  String get workoutActionsFailedToRegenerateWorkout => '운동 재생성 실패';

  @override
  String get workoutActionsFailedToRescheduleWorkout => '운동 일정 변경 실패';

  @override
  String get workoutActionsFinishThisWorkoutTo => '공유하려면 이 운동을 완료하세요';

  @override
  String get workoutActionsGenerateStretches => '스트레치 생성';

  @override
  String get workoutActionsGenerateWarmup => '워밍업 생성';

  @override
  String get workoutActionsLinkCopiedToClipboard => '링크가 클립보드에 복사되었습니다';

  @override
  String get workoutActionsNoVersionHistory => '버전 기록 없음';

  @override
  String get workoutActionsRegenerate => '재생성';

  @override
  String get workoutActionsRegenerateWorkout => '운동을 재생성하시겠습니까?';

  @override
  String get workoutActionsRemoveThisWorkout => '이 운동 삭제';

  @override
  String get workoutActionsReschedule => '일정 변경';

  @override
  String get workoutActionsRevert => '돌아가는 것';

  @override
  String get workoutActionsRevertToThisVersion => '이 버전으로 되돌리시겠습니까?';

  @override
  String get workoutActionsShareWorkout => '운동 공유';

  @override
  String workoutActionsSheetGetALinkFor(Object marketingDomain) {
    return '친구를 위한 $marketingDomain 링크 가져오기';
  }

  @override
  String workoutActionsSheetRestore(Object name) {
    return '\"$name\"을(를) 복원할까요?';
  }

  @override
  String workoutActionsSheetS(Object duration) {
    return '$duration초';
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
    return '$appName 운동';
  }

  @override
  String get workoutActionsThisActionCannotBe => '이 작업은 취소할 수 없습니다.';

  @override
  String get workoutActionsThisWillCreateA =>
      '그러면 오늘의 새로운 운동 계획이 만들어집니다. 현재 운동은 버전 기록에 저장됩니다.';

  @override
  String get workoutActionsThisWorkoutCannotBe => '이 운동은 아직 공유할 수 없습니다';

  @override
  String get workoutActionsVersionHistory => '버전 기록';

  @override
  String get workoutActionsViewAndRestorePrevious => '이전 버전 보기 및 복원';

  @override
  String get workoutActionsWarmupExercises => '워밍업 운동';

  @override
  String get workoutActionsWorkoutDeleted => '운동이 삭제되었습니다';

  @override
  String get workoutActionsWorkoutOptions => '운동 옵션';

  @override
  String get workoutActionsWorkoutRegenerated => '운동이 재생성되었습니다';

  @override
  String get workoutActionsWorkoutRescheduled => '운동 일정이 변경되었습니다';

  @override
  String get workoutAiCoachAddAMessageOptional => '메시지 추가(선택사항)...';

  @override
  String get workoutAiCoachAskMeAnythingAbout => '운동에 관해 무엇이든 물어보세요!';

  @override
  String get workoutAiCoachChangeCoach => '코치 변경';

  @override
  String get workoutAiCoachFailedToLoadChat => '채팅 기록을 불러오지 못했습니다';

  @override
  String get workoutAiCoachForm => '형태';

  @override
  String get workoutAiCoachRest => '나머지';

  @override
  String get workoutAiCoachSets => '세트';

  @override
  String workoutAiCoachSheetCheckMyFormOn(Object name) {
    return '$name 자세 확인하기';
  }

  @override
  String workoutAiCoachSheetHowLongShouldI(Object name) {
    return '$name 세트 사이에는 얼마나 쉬어야 하나요?';
  }

  @override
  String workoutAiCoachSheetHowManySetsShould(Object name) {
    return '최고의 결과를 위해 $name은 몇 세트 하는 것이 좋나요?';
  }

  @override
  String workoutAiCoachSheetWhatAreSomeAlternative(Object name) {
    return '$name 대신 할 수 있는 대체 운동은 무엇인가요?';
  }

  @override
  String workoutAiCoachSheetWhatAreTheKey(Object name) {
    return '$name 운동 시 올바른 자세를 위한 핵심 팁은 무엇인가요?';
  }

  @override
  String get workoutAiCoachSwaps => '스왑';

  @override
  String get workoutBottomBarInstructions => '지침';

  @override
  String get workoutBottomBarSkip => '건너뛰기';

  @override
  String get workoutCompleteAdding => '첨가...';

  @override
  String get workoutCompleteDoMore => '더 많은 일을 하세요';

  @override
  String get workoutCompleteGiveDetailedFeedback => '자세한 피드백 제공';

  @override
  String get workoutCompleteHowWasTheDifficulty => '어려움은 어땠나요?';

  @override
  String get workoutCompleteHowWasYourWorkout => '운동은 어땠나요?';

  @override
  String get workoutCompleteJustRight => '딱 맞아';

  @override
  String get workoutCompleteLess => '더 적은';

  @override
  String get workoutCompleteLogWater => '통나무 물';

  @override
  String get workoutCompleteMoreActions => '추가 작업';

  @override
  String get workoutCompleteRateExercises => '운동 평가하기';

  @override
  String get workoutCompleteSauna => '사우나';

  @override
  String get workoutCompleteScreenCal => '칼';

  @override
  String get workoutCompleteScreenDuration => '지속';

  @override
  String get workoutCompleteScreenEnergy => '에너지';

  @override
  String get workoutCompleteScreenExerciseProgress => '운동 진행';

  @override
  String workoutCompleteScreenExt1AddedMoreExercises(Object length) {
    return '$length개의 운동이 추가되었습니다!';
  }

  @override
  String workoutCompleteScreenExt1ErrorCompletingChallenge(Object e) {
    return '챌린지 완료 오류: $e';
  }

  @override
  String workoutCompleteScreenExt1GreatWillBeIncluded(
    Object suggestedNextVariant,
  ) {
    return '좋아요! $suggestedNextVariant은(는) 향후 운동에 포함될 것입니다.';
  }

  @override
  String workoutCompleteScreenExt2OfRated(Object length, Object length1) {
    return '$length / $length1개 평가됨';
  }

  @override
  String workoutCompleteScreenExt2PrKg(Object maxWeight) {
    return 'PR: $maxWeight kg';
  }

  @override
  String get workoutCompleteScreenFailedToExtendWorkout =>
      '운동을 연장하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get workoutCompleteScreenFeelingStrongerToday => '오늘은 더 강해진 기분!';

  @override
  String get workoutCompleteScreenGoBack => '돌아가기';

  @override
  String get workoutCompleteScreenHard => '딱딱한';

  @override
  String get workoutCompleteScreenHeartRateAnalysis => '심박수 분석';

  @override
  String get workoutCompleteScreenHeartRateMetrics => '심박수 지표';

  @override
  String get workoutCompleteScreenHideDetails => '상세 정보 숨기기';

  @override
  String get workoutCompleteScreenHowDoYouFeel => '지금 기분이 어떤가요?';

  @override
  String get workoutCompleteScreenLevelUp => '레벨 업';

  @override
  String workoutCompleteScreenMin(Object _saunaMinutes) {
    return '$_saunaMinutes분';
  }

  @override
  String workoutCompleteScreenMinSaunaCal(
    Object _saunaCalories,
    Object _saunaMinutes,
  ) {
    return '사우나 $_saunaMinutes분 · 약 $_saunaCalories kcal';
  }

  @override
  String get workoutCompleteScreenMood => '분위기';

  @override
  String get workoutCompleteScreenNewPersonalRecords => '새로운 개인 기록!';

  @override
  String get workoutCompleteScreenNoData => '데이터 없음';

  @override
  String get workoutCompleteScreenNoWorkoutDataTo => '아직 공유할 운동 데이터가 없습니다';

  @override
  String get workoutCompleteScreenNotYet => '아직 아님';

  @override
  String get workoutCompleteScreenNoticeImprovementsInYour =>
      '근력이나 지구력이 향상되었나요?';

  @override
  String get workoutCompleteScreenPleaseRateYourWorkout => '운동을 평가해주세요';

  @override
  String get workoutCompleteScreenRateIndividualExercises => '개별 운동 평가';

  @override
  String get workoutCompleteScreenRatingsHelpOurAi =>
      '평가는 AI가 더 나은 운동을 생성하는 데 도움이 됩니다. 그래도 건너뛰시겠습니까?';

  @override
  String get workoutCompleteScreenReadyToLevelUp => '레벨업 준비 완료!';

  @override
  String get workoutCompleteScreenReps => '담당자';

  @override
  String get workoutCompleteScreenSets => '세트';

  @override
  String get workoutCompleteScreenShowAllStats => '모든 통계 보기';

  @override
  String get workoutCompleteScreenSkipRating => '평가를 건너뛰시겠습니까?';

  @override
  String get workoutCompleteScreenTime => '시간';

  @override
  String get workoutCompleteScreenTotalReps => '총 담당자';

  @override
  String get workoutCompleteScreenTotalWorkout => '총 운동';

  @override
  String get workoutCompleteScreenTrackYourMoodTo => '기분을 기록하고 진행 상황을 확인하세요';

  @override
  String get workoutCompleteScreenTrophiesEarned => '트로피를 획득했습니다!';

  @override
  String get workoutCompleteScreenTrophiesMilestones => '트로피 및 마일스톤';

  @override
  String get workoutCompleteScreenU1f4aa => '💪';

  @override
  String workoutCompleteScreenUi1DayStreakTotalWorkouts(
    Object streak,
    Object totalWorkouts,
  ) {
    return '$streak일 연속, 총 운동 $totalWorkouts회';
  }

  @override
  String workoutCompleteScreenUi1MarkedAsTooEasy(
    Object consecutiveEasySessions,
  ) {
    return '\"너무 쉬움\"으로 $consecutiveEasySessions회 연속 표시됨';
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
    return '$exComp kg x $currentReps회';
  }

  @override
  String workoutCompleteScreenUi2SetsReps(
    Object currentReps,
    Object currentSets,
  ) {
    return '$currentSets세트, $currentReps회';
  }

  @override
  String get workoutCompleteScreenUnableToChallengeFriends =>
      '현재 친구에게 도전할 수 없습니다';

  @override
  String get workoutCompleteScreenUnableToExtendWorkout => '운동을 연장할 수 없습니다';

  @override
  String get workoutCompleteScreenViewAllMetrics => '모든 지표 보기';

  @override
  String get workoutCompleteScreenViewGoals => '목표 보기';

  @override
  String get workoutCompleteScreenVolume => '용량';

  @override
  String workoutCompleteScreenWorkout(Object appName) {
    return '$appName 운동';
  }

  @override
  String get workoutCompleteScreenYouDonTHave => '아직 친구가 없습니다. 먼저 친구를 추가하세요!';

  @override
  String get workoutCompleteScreenYouVeMasteredThese =>
      '당신은 이 연습을 마스터했습니다. 더 어려운 변형을 시도해 보시겠습니까?';

  @override
  String get workoutCompleteSkipRating => '평가 건너뛰기';

  @override
  String get workoutCompleteSummary => '요약';

  @override
  String get workoutCompleteThisWeek => '이번 주';

  @override
  String get workoutCompleteTooEasy => '너무 쉬움';

  @override
  String get workoutCompleteTooHard => '너무 어렵다';

  @override
  String get workoutCompleteWorkoutComplete => '운동 완료!';

  @override
  String get workoutCompleteYourRatingsHelpUs =>
      '귀하의 평가는 향후 운동을 개인화하는 데 도움이 됩니다';

  @override
  String get workoutDayDetailAvgHr => '평균 HR';

  @override
  String get workoutDayDetailAvgRpe => '평균 RPE';

  @override
  String get workoutDayDetailBestSet => '베스트 세트';

  @override
  String get workoutDayDetailCalories => '칼로리';

  @override
  String get workoutDayDetailCoachFeedback => '코치 피드백';

  @override
  String get workoutDayDetailDistance => '거리';

  @override
  String get workoutDayDetailDuration => '지속 시간';

  @override
  String get workoutDayDetailFailedToLoadDetails => '상세 정보를 불러오지 못했습니다';

  @override
  String get workoutDayDetailMaxHr => '최대 심박수';

  @override
  String get workoutDayDetailMusclesWorked => '근육이 일했다';

  @override
  String get workoutDayDetailRecoveryIsJustAs =>
      '회복은 훈련만큼 중요합니다. 근육은 휴식 중에 성장합니다!';

  @override
  String get workoutDayDetailRestDay => '휴일';

  @override
  String workoutDayDetailSheetScheduled(Object workoutName) {
    return '예정: $workoutName';
  }

  @override
  String workoutDayDetailSheetSource(Object sourceApp) {
    return '출처: $sourceApp';
  }

  @override
  String get workoutDayDetailSyncedFromHealth => '건강에서 동기화됨';

  @override
  String get workoutDayDetailVolume => '용량';

  @override
  String get workoutDayDetailWorkoutMissed => '운동을 놓쳤습니다';

  @override
  String get workoutDaysChangingWorkoutDaysWill =>
      '운동 요일을 변경하면 일정이 업데이트됩니다. 향후 운동이 다시 생성됩니다.';

  @override
  String get workoutDaysSelectWhichDaysYou => '운동할 요일을 선택하세요';

  @override
  String workoutDaysSelectorDaysWeek(Object length) {
    return '주 $length일';
  }

  @override
  String get workoutDaysSelectorSelectWhichDaysYou => '운동할 요일을 선택하세요';

  @override
  String get workoutDaysSelectorWorkoutDays => '운동일';

  @override
  String workoutDaysSheetFailedToUpdateWorkout(Object e) {
    return '운동 일자 업데이트 실패: $e';
  }

  @override
  String get workoutDaysWorkoutDays => '운동 요일';

  @override
  String get workoutDetailAddSaunaTime => '사우나 시간 추가';

  @override
  String get workoutDetailAiAiGenerationParameters => 'AI 생성 매개변수';

  @override
  String get workoutDetailAiAiInsights => 'AI 인사이트';

  @override
  String get workoutDetailAiExerciseSelection => '운동 선택';

  @override
  String get workoutDetailAiGeneratingInsights => '통계 생성 중...';

  @override
  String get workoutDetailAiGeneratingNewInsights => '새로운 인사이트 생성 중...';

  @override
  String workoutDetailAiInsightsMin(Object durationMinutes) {
    return '$durationMinutes분';
  }

  @override
  String workoutDetailAiInsightsMin2(Object params) {
    return '$params분';
  }

  @override
  String workoutDetailAiInsightsMoreExercises(Object exerciseReasoning) {
    return '+ $exerciseReasoning개의 운동 추가...';
  }

  @override
  String get workoutDetailAiLoadingAiReasoning => 'AI 추론 불러오는 중...';

  @override
  String get workoutDetailAiProgramPreferences => '프로그램 환경설정';

  @override
  String get workoutDetailAiRegenerateInsights => '인사이트 재생성';

  @override
  String get workoutDetailAiTapToSeeAi => '탭하여 운동 선택에 대한 AI 추론 보기';

  @override
  String get workoutDetailAiTheseParametersWereUsed =>
      '이 매개변수는 귀하의 체력 수준, 목표 및 사용 가능한 장비에 맞는 맞춤형 운동을 생성하기 위해 AI가 사용했습니다.';

  @override
  String get workoutDetailAiUserProfile => '사용자 프로필';

  @override
  String get workoutDetailAiViewAllParametersSent => 'AI로 전송된 모든 매개변수 보기';

  @override
  String get workoutDetailAiWhyTheseExercises => '왜 이 운동인가요?';

  @override
  String get workoutDetailAiWorkoutDesign => '운동 설계';

  @override
  String get workoutDetailAiWorkoutSpecifics => '운동 세부 사항';

  @override
  String get workoutDetailCoolDownStretches => '쿨다운 스트레칭';

  @override
  String get workoutDetailDifficulty => '어려움';

  @override
  String get workoutDetailEquipment => '장비';

  @override
  String get workoutDetailExercises => '수업 과정';

  @override
  String get workoutDetailFailedToLoadWorkout => '운동을 불러오지 못했습니다';

  @override
  String get workoutDetailHelpersHell => '지옥';

  @override
  String get workoutDetailHelpersUpdatingExercises => '운동 업데이트';

  @override
  String get workoutDetailMoreInfo => '추가 정보';

  @override
  String get workoutDetailProgram => '프로그램';

  @override
  String workoutDetailReplacingExercises(Object arg0) {
    return '사용 가능한 장비에 맞게 $arg0개 운동 교체 중…';
  }

  @override
  String get workoutDetailRevert => '돌아가는 것';

  @override
  String get workoutDetailScreenBreakSuperset => '슈퍼세트를 해제하시겠습니까?';

  @override
  String workoutDetailScreenCalBurned(Object estimatedCalories) {
    return '약 $estimatedCalories kcal 소모';
  }

  @override
  String get workoutDetailScreenCannotMergeSupersets => '상위 집합을 병합할 수 없습니다.';

  @override
  String get workoutDetailScreenCannotRemoveTheLast => '마지막 운동은 삭제할 수 없습니다';

  @override
  String get workoutDetailScreenChallenge => '챌린지';

  @override
  String get workoutDetailScreenDiscardTheEquipmentChange =>
      '장비 변경 사항을 완전히 폐기합니다.';

  @override
  String get workoutDetailScreenEquipmentUpdated => '장비가 업데이트되었습니다';

  @override
  String get workoutDetailScreenFailedToBlockExercise => '운동 차단 실패';

  @override
  String get workoutDetailScreenFailedToRemoveExercise => '운동 삭제 실패';

  @override
  String get workoutDetailScreenFailedToUpdateFavorite => '즐겨찾기 업데이트 실패';

  @override
  String get workoutDetailScreenKeepThisSessionUnchanged =>
      '이 세션을 변경하지 않고 유지합니다. 새로운 장비는 향후 운동에 적용됩니다.';

  @override
  String get workoutDetailScreenLetSGo => '갑시다';

  @override
  String workoutDetailScreenMinSauna(Object durationMinutes) {
    return '사우나 $durationMinutes분';
  }

  @override
  String get workoutDetailScreenNeverRecommend => '절대 추천하지 않음';

  @override
  String get workoutDetailScreenNoThanks => '아니요';

  @override
  String workoutDetailScreenProgressionFrom(Object progressionFrom) {
    return '$progressionFrom에서 진행';
  }

  @override
  String get workoutDetailScreenRemoveExercise => '운동 삭제';

  @override
  String get workoutDetailScreenReplaceNow => '지금 교체';

  @override
  String get workoutDetailScreenRevertToOriginal => '원래대로 되돌릴까요?';

  @override
  String get workoutDetailScreenSaveForNextWorkout => '다음 운동을 위해 저장';

  @override
  String get workoutDetailScreenSaveToProfile => '프로필에 저장하시겠습니까?';

  @override
  String get workoutDetailScreenSupersetCreated => '슈퍼세트가 생성되었습니다!';

  @override
  String get workoutDetailScreenSwapThoseExercisesIn =>
      '이번 세션에서는 해당 운동을 바꿔보세요. 완료된 세트는 기록된 상태로 유지됩니다.';

  @override
  String get workoutDetailScreenTapAnotherExerciseTo =>
      '다른 운동을 탭하여 슈퍼세트로 연결하세요';

  @override
  String get workoutDetailScreenThisIsAnOptional =>
      '이는 선택적 고급 연습입니다. 준비가 되었다고 생각되면 시도해 보세요!';

  @override
  String get workoutDetailScreenThisWillRestoreAll =>
      '장비 변경 사항이 적용되기 전의 모든 운동 상태로 복원됩니다.';

  @override
  String get workoutDetailScreenThisWillUnlinkThese =>
      '이렇게 하면 이러한 운동의 연결이 해제되어 별도로 수행됩니다.';

  @override
  String workoutDetailScreenUi1AddToCreateA(Object name, Object newSetType) {
    return '\"$name\"을(를) 추가하여 $newSetType을(를) 생성할까요?';
  }

  @override
  String workoutDetailScreenUi1AndAreAlreadyIn(Object name, Object name1) {
    return '\"$name\"과(와) \"$name1\"은(는) 이미 다른 슈퍼세트에 포함되어 있습니다.\n\n새로운 조합을 만들려면 기존 슈퍼세트를 먼저 해제하세요.';
  }

  @override
  String workoutDetailScreenUi1Created(Object setType) {
    return '$setType 생성 완료!';
  }

  @override
  String workoutDetailScreenUi2BlockFromAllFuture(Object name) {
    return '앞으로의 모든 AI 추천에서 \"$name\"을(를) 차단할까요?\n\n';
  }

  @override
  String workoutDetailScreenUi2FailedToRemoveExercise(Object e) {
    return '운동 삭제 실패: $e';
  }

  @override
  String workoutDetailScreenUi2RemoveFromThisWorkout(Object name) {
    return '이 운동에서 \"$name\"을(를) 삭제할까요?';
  }

  @override
  String workoutDetailScreenUi2RemovedFromWorkout(Object name) {
    return '$name이(가) 운동에서 삭제되었습니다';
  }

  @override
  String workoutDetailScreenUi2WillNoLongerBe(Object name) {
    return '$name은(는) 더 이상 추천되지 않습니다';
  }

  @override
  String workoutDetailScreenUiSRest(Object restSeconds) {
    return '$restSeconds초 휴식';
  }

  @override
  String workoutDetailScreenUiValue(Object label) {
    return '$label: ';
  }

  @override
  String get workoutDetailScreenWouldYouLikeTo =>
      '이 장비 구성을 나중을 위해 프로필에 저장하시겠습니까?';

  @override
  String get workoutDetailScreenYesSave => '네, 저장합니다';

  @override
  String get workoutDetailTryAgain => '다시 시도';

  @override
  String get workoutDetailType => '유형';

  @override
  String get workoutDetailUpdatingExercises => '운동 업데이트 중';

  @override
  String get workoutDetailWantAChallenge => '도전하시겠습니까?';

  @override
  String get workoutDetailWarmUp => '워밍업';

  @override
  String get workoutFavourites => '즐겨찾기';

  @override
  String get workoutFlowMixinComplete => '완벽한';

  @override
  String get workoutFlowMixinCompleteWorkoutNow => '이제 운동을 완료하시겠습니까?';

  @override
  String get workoutFlowMixinKeepGoing => '계속하세요';

  @override
  String get workoutGalleryCompleteAWorkoutAnd => '운동을 완료하고 공유하여\n갤러리를 시작하세요';

  @override
  String get workoutGalleryDeleteImage => '이미지를 삭제할까요?';

  @override
  String get workoutGalleryNoImagesYet => '아직 이미지가 없습니다';

  @override
  String get workoutGalleryShareAgain => '다시 공유';

  @override
  String get workoutGalleryThisWillRemoveThe => '그러면 갤러리에서 이미지가 제거됩니다.';

  @override
  String get workoutGalleryWorkoutGallery => '운동 갤러리';

  @override
  String get workoutGalleryWorkoutRecap => '운동 요약';

  @override
  String get workoutGenerate => '운동 생성';

  @override
  String get workoutGenerationAnalyzingYourFitnessProfile => '피트니스 프로필 분석 중';

  @override
  String get workoutGenerationDesigningYourTrainingSplit => '트레이닝 분할 설계 중';

  @override
  String get workoutGenerationFinalizingYourPlan => '플랜 마무리 중';

  @override
  String get workoutGenerationGeneratingYourPersonalizedP => '맞춤형 플랜 생성 중';

  @override
  String get workoutGenerationGeneratingYourPlan => '플랜 생성 중';

  @override
  String get workoutGenerationGenerationFailed => '생성 실패';

  @override
  String get workoutGenerationOptimizingWorkoutStructure => '운동 구조 최적화 중';

  @override
  String get workoutGenerationSelectingExercisesForYour => '목표에 맞는 운동 선택 중';

  @override
  String get workoutGenerationSomethingWentWrong => '문제가 발생했습니다';

  @override
  String get workoutGenerationTryAgain => '다시 시도';

  @override
  String get workoutGenerationWorkoutReady => '운동 준비 완료!';

  @override
  String get workoutHistory => '기록';

  @override
  String get workoutHistoryImportAddExercise => '운동 추가';

  @override
  String get workoutHistoryImportAddToHistory => '기록에 추가';

  @override
  String get workoutHistoryImportAddYourPastWorkout =>
      '과거 운동 데이터를 추가하면 AI가 근력 수준에 맞는 가중치로 운동을 생성할 수 있습니다.';

  @override
  String get workoutHistoryImportAddYourPastWorkout2 =>
      '과거 운동 데이터를 추가하면 AI가 더 나은 운동을 생성하는 데 도움이 됩니다.';

  @override
  String get workoutHistoryImportAppleHealth => 'Apple 건강';

  @override
  String get workoutHistoryImportAutoDetect => '자동 감지';

  @override
  String get workoutHistoryImportBeforeWeParse => '분석하기 전에…';

  @override
  String get workoutHistoryImportChooseFile => '파일 선택';

  @override
  String get workoutHistoryImportCouldNotReadThat => '해당 파일을 읽을 수 없습니다.';

  @override
  String get workoutHistoryImportDeleteEntry => '항목을 삭제할까요?';

  @override
  String get workoutHistoryImportEG10 => '예: 10';

  @override
  String get workoutHistoryImportEG3 => '예: 3';

  @override
  String get workoutHistoryImportEG60 => '예: 60';

  @override
  String get workoutHistoryImportEGBenchPress => '예: 벤치프레스, 스쿼트';

  @override
  String get workoutHistoryImportEntryDeleted => '항목이 삭제되었습니다';

  @override
  String workoutHistoryImportError(Object error) {
    return '오류: $error';
  }

  @override
  String get workoutHistoryImportExerciseName => '운동명';

  @override
  String get workoutHistoryImportExportFromHevy =>
      'Hevy, Strong, Fitbod, Jeff Nippard, Renaissance Periodization, Wendler 5/3/1, Apple Health, Garmin, Strava, Peloton 등에서 내보내기 가능.';

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
    return '가져오기 실패: $error';
  }

  @override
  String get workoutHistoryImportImportFromFile => '파일에서 가져오기';

  @override
  String get workoutHistoryImportImportWorkoutHistory => '운동 기록 가져오기';

  @override
  String get workoutHistoryImportInvalid => '유효하지 않음';

  @override
  String get workoutHistoryImportJeffNippard => '제프 니퍼드';

  @override
  String get workoutHistoryImportJefit => 'Jefit';

  @override
  String get workoutHistoryImportKilogramsKg => '킬로그램(kg)';

  @override
  String workoutHistoryImportMaxWeightKg(Object weight) {
    return '최대: $weight kg';
  }

  @override
  String workoutHistoryImportNSessions(Object count, Object sourceDescription) {
    return '$sourceDescription  •  $count 세션';
  }

  @override
  String get workoutHistoryImportNoWorkoutHistoryYet => '아직 운동 기록이 없습니다';

  @override
  String get workoutHistoryImportNsuns => 'nSuns';

  @override
  String get workoutHistoryImportOtherGenericSpreadsheet => '기타 / 일반 스프레드시트';

  @override
  String get workoutHistoryImportPeloton => 'Peloton';

  @override
  String get workoutHistoryImportPleaseEnterExerciseName => '운동 이름을 입력해 주세요';

  @override
  String get workoutHistoryImportPoundsLb => '파운드(lb)';

  @override
  String get workoutHistoryImportPreviewImport => '가져오기 미리보기';

  @override
  String get workoutHistoryImportRecentImports => '최근 수입품';

  @override
  String workoutHistoryImportRemoveExercise(Object exerciseName) {
    return '운동 기록에서 $exerciseName을(를) 삭제하시겠습니까?';
  }

  @override
  String get workoutHistoryImportRenaissancePeriodization => '르네상스 시대화';

  @override
  String get workoutHistoryImportReps => '담당자';

  @override
  String get workoutHistoryImportRequired => '필수';

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
    return '$sets세트 × $reps회 @ $weightKg kg';
  }

  @override
  String get workoutHistoryImportSets => '세트';

  @override
  String get workoutHistoryImportSourceApp => '소스 앱';

  @override
  String get workoutHistoryImportStartingStrength => '시작 강도';

  @override
  String get workoutHistoryImportStrava => 'Strava';

  @override
  String get workoutHistoryImportStrong => '강한';

  @override
  String get workoutHistoryImportStronglifts => 'StrongLifts';

  @override
  String get workoutHistoryImportSupportsCsvXlsxXlsm =>
      'CSV, XLSX, XLSM, JSON, Parquet, PDF, FIT, XML, ZIP을 지원합니다.';

  @override
  String get workoutHistoryImportTheAiUsesThis =>
      'AI는 이 데이터를 사용하여 적절한 중량을 설정합니다';

  @override
  String get workoutHistoryImportViewAll => '모두 보기';

  @override
  String get workoutHistoryImportWeightKg => '체중(kg)';

  @override
  String get workoutHistoryImportWeightUnit => '중량 단위';

  @override
  String get workoutHistoryImportWendler531 => '웬들러 5/3/1';

  @override
  String get workoutHistoryImportWhichUnitIsThe =>
      '중량란은 어느 단위인가요? 소스 앱을 알고 있는 경우 해당 앱을 선택하면 형제 형식(Hevy 및 Strong CSV)을 구분하는 데 도움이 됩니다.';

  @override
  String get workoutHistoryImportYourStrengthData => '귀하의 근력 데이터';

  @override
  String get workoutImportCalories => '칼로리';

  @override
  String get workoutImportCardio => '유산소';

  @override
  String get workoutImportCycling => '사이클링';

  @override
  String get workoutImportDistance => '거리';

  @override
  String get workoutImportDuration => '지속';

  @override
  String get workoutImportEasy => '쉬움';

  @override
  String get workoutImportFlexibility => '유연성';

  @override
  String workoutImportFromSource(Object arg0) {
    return '$arg0에서';
  }

  @override
  String get workoutImportHard => '어려움';

  @override
  String get workoutImportHiit => 'HIIT';

  @override
  String get workoutImportHowHardWasThis => '이번 운동은 얼마나 힘들었나요?';

  @override
  String get workoutImportImportAsSeparateWorkout => '별도의 운동으로 가져오기';

  @override
  String get workoutImportImportWorkout => '운동 가져오기';

  @override
  String get workoutImportMedium => '보통';

  @override
  String get workoutImportOther => '기타';

  @override
  String get workoutImportPreviewCardioRows => '유산소 행';

  @override
  String get workoutImportPreviewHeadsUp => '알림';

  @override
  String get workoutImportPreviewLooksRightImport => '맞는 것 같습니다 — 가져오기';

  @override
  String get workoutImportPreviewNo => '아니요';

  @override
  String get workoutImportPreviewNoSampleRowsProduced =>
      '샘플 행이 생성되지 않습니다(파일이 비어 있거나 인식되지 않을 수 있음).';

  @override
  String get workoutImportPreviewPreviewImport => '가져오기 미리보기';

  @override
  String get workoutImportPreviewSampleRows => '샘플 행';

  @override
  String workoutImportPreviewSheetMore(Object more) {
    return '+$more개 더 보기';
  }

  @override
  String workoutImportPreviewSheetValue(Object percent) {
    return '$percent%';
  }

  @override
  String workoutImportPreviewSheetValue2(Object w) {
    return '• $w';
  }

  @override
  String get workoutImportPreviewStrengthRows => '근력 운동 행';

  @override
  String get workoutImportPreviewTemplate => '주형';

  @override
  String get workoutImportPreviewTheseWillStillImport =>
      '이 항목들은 그대로 가져와집니다. 작업 완료 후 표준 이름으로 매핑할 수 있습니다.';

  @override
  String get workoutImportPreviewUnmatchedExercises => '일치하지 않는 운동';

  @override
  String get workoutImportProgressImportIsStillIn =>
      '가져오기가 아직 진행 중입니다. 잠시 기다려 주세요.';

  @override
  String get workoutImportProgressImportingWorkoutHistory => '운동 기록 가져오는 중';

  @override
  String workoutImportProgressSheetJobId(Object jobId) {
    return '작업 ID: $jobId';
  }

  @override
  String get workoutImportProgressThisUsuallyFinishesIn =>
      '이 작업은 일반적으로 10~30초 안에 완료됩니다.';

  @override
  String get workoutImportRunning => '러닝';

  @override
  String workoutImportScreenAvgBpm(Object avgHeartRate) {
    return '평균 $avgHeartRate bpm';
  }

  @override
  String workoutImportScreenM(Object workout) {
    return '$workout분';
  }

  @override
  String workoutImportScreenMaxBpm(Object maxHeartRate) {
    return '  |  최대 $maxHeartRate bpm';
  }

  @override
  String get workoutImportSkip => '건너뛰기';

  @override
  String get workoutImportStrengthTraining => '근력 운동';

  @override
  String get workoutImportSummaryActivateProgram => '프로그램 활성화';

  @override
  String get workoutImportSummaryCardioSessionsAdded => '유산소 세션 추가됨';

  @override
  String get workoutImportSummaryCreatorProgramDetected => '크리에이터 프로그램 감지됨';

  @override
  String get workoutImportSummaryDuplicatesSkipped => '중복 항목 건너뜀';

  @override
  String get workoutImportSummaryFixThese => '수정하기';

  @override
  String get workoutImportSummaryImportComplete => '가져오기 완료';

  @override
  String get workoutImportSummaryImportFailed => '가져오기 실패';

  @override
  String get workoutImportSummaryProgramTemplate => '프로그램 템플릿';

  @override
  String workoutImportSummarySheetMore(Object more) {
    return '+$more개 더';
  }

  @override
  String workoutImportSummarySheetValue(Object w) {
    return '•  $w';
  }

  @override
  String get workoutImportSummaryStrengthSetsAdded => '근력 세트 추가됨';

  @override
  String get workoutImportSummaryTheseRowsWereImported =>
      '이 행은 가져왔지만 아직 도서관 연습과 일치하지 않습니다. 매핑하면 가중치 제안 + 차트가 향상됩니다.';

  @override
  String get workoutImportSummaryUnknownErrorPleaseTry =>
      '알 수 없는 오류입니다. 다시 시도하거나 지원팀에 문의하세요.';

  @override
  String get workoutImportSummaryWarnings => '경고';

  @override
  String get workoutImportSummaryWeCouldnTFinish => '가져오기를 완료할 수 없습니다.';

  @override
  String get workoutImportSummaryWeParsedAMulti =>
      '우리는 몇 주간의 프로그램 템플릿을 분석했습니다. 활성화하면 다음 주 월요일부터 운동 일정이 예약됩니다.';

  @override
  String get workoutImportSummaryWeightSuggestionsAcrossThe =>
      '앱 전체의 체중 제안은 1분 이내에 이 기록을 반영하기 시작합니다.';

  @override
  String get workoutImportSwimming => '수영';

  @override
  String get workoutImportWalking => '걷기';

  @override
  String get workoutImportWeights => '웨이트';

  @override
  String get workoutImportWhatTypeOfExercise => '어떤 종류의 운동인가요?';

  @override
  String get workoutImportWorkout => '운동';

  @override
  String get workoutImportWorkoutDetected => '운동이 감지됨';

  @override
  String get workoutImportYoga => '요가';

  @override
  String get workoutListTitle => '운동';

  @override
  String get workoutLoadingBuildingYourPlan => '계획 세우기';

  @override
  String workoutLoadingScreenValue(Object percentage) {
    return '$percentage%';
  }

  @override
  String get workoutLoadingWorkoutReady => '운동 준비 완료!';

  @override
  String get workoutLoadingWorkoutReady2 => '운동 준비 완료!';

  @override
  String workoutMetricChartNotEnoughDataTo(Object label) {
    return '차트를 그릴 $label 데이터가 부족합니다.';
  }

  @override
  String get workoutMiniPlayerEndWorkout => '운동을 종료하시겠습니까?';

  @override
  String get workoutMiniPlayerEndWorkout2 => '운동 종료';

  @override
  String workoutMiniPlayerS(Object restSecondsRemaining) {
    return '$restSecondsRemaining초';
  }

  @override
  String get workoutMiniPlayerYourWorkoutProgressWill => '운동 진행 상황은 저장되지 않습니다.';

  @override
  String get workoutOptionsDismissQuickWorkout => '빠른 운동을 닫으시겠습니까?';

  @override
  String get workoutOptionsMarkAsDone => '완료로 표시하시겠습니까?';

  @override
  String workoutOptionsSheetExercises(Object exerciseCount) {
    return '운동 $exerciseCount개';
  }

  @override
  String workoutOptionsSheetMarkWorkoutForAs(Object dateLabel) {
    return '$dateLabel 운동을 완료로 표시할까요? 다음으로 표시됩니다: ';
  }

  @override
  String workoutOptionsSheetMoreExercises(Object exercises) {
    return '외 $exercises개 운동';
  }

  @override
  String workoutOptionsSheetSets(Object e) {
    return '$e 세트';
  }

  @override
  String workoutOptionsSheetValue(Object formattedDurationShort) {
    return '$formattedDurationShort • ';
  }

  @override
  String get workoutOptionsSkipWorkout => '운동을 건너뛰시겠습니까?';

  @override
  String get workoutOptionsThisWillMarkThe =>
      '이렇게 하면 추적 세트 없이 운동이 완료된 것으로 표시됩니다.';

  @override
  String get workoutOptionsThisWorkoutWillBe => '이 운동은 건너뛴 것으로 표시됩니다.';

  @override
  String get workoutPermissionsPrimeGotItLetU2019s => '알겠습니다, 시작하죠';

  @override
  String get workoutPermissionsPrimeLetsUsAutoConnect =>
      'BLE 심박수 스트랩이 근처에 있으면 자동으로 연결할 수 있습니다.';

  @override
  String get workoutPermissionsPrimeMicrophone => '마이크로폰';

  @override
  String get workoutPermissionsPrimeNearbyDevices => '주변 기기';

  @override
  String get workoutPermissionsPrimeTapTheMicMid =>
      '질문을 하거나 음성으로 메모를 기록하려면 세트 중간에 마이크를 탭하세요.';

  @override
  String get workoutPermissionsPrimeTwoQuickHeadsUps => '두 가지 빠른 알림';

  @override
  String get workoutPermissionsPrimeYouMaySeeThese =>
      '운동 중에 이러한 시스템 메시지가 나타날 수 있습니다. 둘 다 선택 사항입니다. 둘 중 하나를 건너뛰어도 운동은 계속 작동합니다.';

  @override
  String get workoutPlanDrawerAddExercise => '운동 추가';

  @override
  String get workoutPlanDrawerCurrent => '현재';

  @override
  String workoutPlanDrawerExerciseCount(Object arg0) {
    return '운동 $arg0개';
  }

  @override
  String get workoutPlanDrawerNow => '지금';

  @override
  String get workoutPlanDrawerRemove => '제거';

  @override
  String workoutPlanDrawerRemoveExercise(Object arg0) {
    return '$arg0을(를) 삭제할까요?';
  }

  @override
  String get workoutPlanDrawerRemoveExerciseTooltip => '운동 제거 툴팁';

  @override
  String workoutPlanDrawerSetsLogged(Object arg0) {
    return '기록된 세트가 $arg0개 있습니다. 삭제됩니다.';
  }

  @override
  String get workoutPlanDrawerSwapExercise => '운동 교체';

  @override
  String get workoutPlanDrawerTitle => '제목';

  @override
  String get workoutPlanDrawerWorkoutPlan => '운동 플랜';

  @override
  String get workoutPlannerCalendarDisplayOptions => '캘린더 표시 옵션';

  @override
  String get workoutPlannerMon => '월';

  @override
  String get workoutPlannerShowSyncedWorkouts => '동기화된 운동 보기';

  @override
  String get workoutPlannerStartWeekOnMonday => '월요일에 한 주 시작';

  @override
  String get workoutPlannerSun => '해';

  @override
  String get workoutPreferencesCardEditProgram => '프로그램 편집';

  @override
  String get workoutPreferencesCardEnvironment => '환경';

  @override
  String get workoutPreferencesCardExperience => '경험';

  @override
  String get workoutPreferencesCardFocusAreas => '중점 분야';

  @override
  String get workoutPreferencesCardFullBody => '전신';

  @override
  String get workoutPreferencesCardMotivation => '동기 부여';

  @override
  String get workoutPreferencesCardNotSet => '설정 안 됨';

  @override
  String get workoutPreferencesCardWeekStartsOn => '주가 시작되는 날짜';

  @override
  String get workoutPreferencesCardWorkoutDays => '운동일';

  @override
  String get workoutReviewAddExercise => '운동 추가';

  @override
  String get workoutReviewAdding => '추가 중...';

  @override
  String get workoutReviewApprovePlan => '계획 승인';

  @override
  String get workoutReviewClosing => '닫는 중...';

  @override
  String get workoutReviewNoExercisesYet => '아직 추가된 운동이 없습니다';

  @override
  String get workoutReviewReviewYourWorkout => '운동 검토';

  @override
  String get workoutReviewSaving => '절약...';

  @override
  String workoutReviewSheetExercises(Object exerciseCount) {
    return '운동 $exerciseCount개';
  }

  @override
  String get workoutReviewSwapExercise => '운동 교체';

  @override
  String get workoutReviewTryAgain => '다시 시도';

  @override
  String get workoutReviewYourWorkout => '나의 운동';

  @override
  String get workoutSettingsAddPastWorkoutsFor =>
      '더 정확한 AI 중량 설정을 위해 과거 운동 기록 추가';

  @override
  String get workoutSettingsAutoDeloadDeloadFrequency =>
      '자동 디로딩, 디로딩 빈도 및 진행 주수';

  @override
  String get workoutSettingsCustomizeWhichExercisesAppe =>
      '운동 목록에 표시할 운동 사용자 지정';

  @override
  String get workoutSettingsExercisePreferences => '연습 PR참고자료';

  @override
  String get workoutSettingsFatigueDetection => '피로 감지';

  @override
  String get workoutSettingsFavoritesAvoidedAndQueue => '즐겨찾기, 제외, 대기열';

  @override
  String get workoutSettingsHowFastToIncrease => '중량 증가 속도';

  @override
  String get workoutSettingsHowHeavyAndHow => '중량 및 진행 속도';

  @override
  String get workoutSettingsHowMuchExercisesChange => '매주 운동 변화량';

  @override
  String get workoutSettingsHowWeightsAreDisplayed => '중량 표시 및 기록 방식';

  @override
  String get workoutSettingsImportWorkoutHistory => '운동 기록 가져오기';

  @override
  String get workoutSettingsIncompleteExerciseWarning => '불완전한 운동 경고';

  @override
  String get workoutSettingsLiveCoaching => '라이브 코칭';

  @override
  String get workoutSettingsMy1rms => '내 1RMs';

  @override
  String get workoutSettingsMyExercises => '나의 운동';

  @override
  String workoutSettingsPageStepSizeTapTo(Object ref) {
    return '단계 크기: $ref · 탭하여 사용자 지정';
  }

  @override
  String get workoutSettingsPreSetInsights => '세트 전 인사이트';

  @override
  String get workoutSettingsProgram => 'PR그램';

  @override
  String get workoutSettingsProgressCharts => '진행 상황 차트';

  @override
  String get workoutSettingsProgressionDeload => '진행 및 디로딩';

  @override
  String get workoutSettingsProgressionLoad => 'PR오그레션 및 로드';

  @override
  String get workoutSettingsProgressionPace => '진행 속도';

  @override
  String get workoutSettingsPushPullLegsFull => '밀기/당기기/다리, 전신 등';

  @override
  String get workoutSettingsStrengthCardioOrMixed => '근력, 유산소 또는 혼합';

  @override
  String get workoutSettingsTrainingIntensity => '훈련 강도';

  @override
  String get workoutSettingsTrainingSplit => '운동 분할';

  @override
  String get workoutSettingsUnitForLoggingExercise => '운동 중 중량 기록 단위';

  @override
  String get workoutSettingsUnitsTracking => '단위 및 기록';

  @override
  String get workoutSettingsViewAndEditYour => '최대 중량 확인 및 수정';

  @override
  String get workoutSettingsVisualizeStrengthVolumeOv => '시간에 따른 근력 및 볼륨 시각화';

  @override
  String get workoutSettingsWeeklyVariety => '주간 버라이어티';

  @override
  String get workoutSettingsWeightIncrements => '무게 증가';

  @override
  String get workoutSettingsWhatHappensDuringA => '운동 중 진행 방식';

  @override
  String get workoutSettingsWhatYouTrainAnd => '운동 부위 및 일정';

  @override
  String get workoutSettingsWhichDaysYouTrain => '운동 요일';

  @override
  String get workoutSettingsWorkAtAPercentage => '최대 중량의 퍼센트로 운동';

  @override
  String get workoutSettingsWorkoutDays => '운동 요일';

  @override
  String get workoutSettingsWorkoutSettings => '운동 설정';

  @override
  String get workoutSettingsWorkoutType => '운동 유형';

  @override
  String get workoutSettingsWorkoutWeightUnit => '운동 체중 단위';

  @override
  String get workoutSheetsMixinAiCoachHiddenFor => '이 세션 동안 AI Coach 숨김';

  @override
  String get workoutSheetsMixinAiTargetsWillBe => 'AI 타겟은 귀하의 기록을 기반으로 생성됩니다.';

  @override
  String get workoutSheetsMixinBarType => '바 유형';

  @override
  String get workoutSheetsMixinBreakSuperset => '브레이크 슈퍼세트';

  @override
  String get workoutSheetsMixinChangeRepsProgression => '반복 횟수 진행 방식 변경';

  @override
  String get workoutSheetsMixinCreateSuperset => '슈퍼세트 생성';

  @override
  String get workoutSheetsMixinEnterReps => '반복 횟수 입력';

  @override
  String get workoutSheetsMixinHide => '숨기기';

  @override
  String get workoutSheetsMixinHideAiCoach => 'AI 코치를 숨기시겠습니까?';

  @override
  String get workoutSheetsMixinHowToCreateA => '슈퍼세트를 만드는 방법:';

  @override
  String get workoutSheetsMixinLastSession => '마지막 세션';

  @override
  String workoutSheetsMixinLoggedLocallySyncFailed(Object label) {
    return '$label 로컬에 기록됨 (동기화 실패)';
  }

  @override
  String workoutSheetsMixinMlLogged(Object amountMl, Object label) {
    return '${amountMl}ml $label 기록됨';
  }

  @override
  String workoutSheetsMixinMlLogged2(Object amountMl, Object label) {
    return '${amountMl}ml $label 기록됨';
  }

  @override
  String get workoutSheetsMixinNoPreviousDataFor => '이 연습에 대한 이전 데이터가 없습니다.';

  @override
  String get workoutSheetsMixinOrDragExercisesTogether => '또는 운동을 드래그하여 함께 추가';

  @override
  String get workoutSheetsMixinSelectTheTypeOf => '사용 중인 바 유형 선택';

  @override
  String get workoutSheetsMixinSetTargets => '목표 설정';

  @override
  String get workoutSheetsMixinSupersetRemoved => '슈퍼세트 제거됨';

  @override
  String get workoutSheetsMixinSupersetsHelpYouSave =>
      '슈퍼세트는 최소한의 휴식으로 운동을 번갈아 수행하여 시간을 절약하는 데 도움이 됩니다.';

  @override
  String get workoutSheetsMixinTheAiCoachWill =>
      '이 운동 세션에서는 AI 코치가 숨겨집니다. 설정에서 계속 액세스할 수 있습니다.';

  @override
  String workoutSheetsMixinUiChangedTo(Object displayName) {
    return '$displayName(으)로 변경됨';
  }

  @override
  String workoutSheetsMixinUiSupersetExercises(Object length) {
    return '슈퍼세트 (운동 $length개)';
  }

  @override
  String get workoutSheetsMixinUndo => '끄르다';

  @override
  String get workoutSheetsMixinWarmUp => '웜업';

  @override
  String get workoutSheetsMixinWarmingUpHelpsPrevent =>
      '웜업은 부상을 방지하고 수행 능력을 향상시킵니다.\n\n권장 사항: 본 세트 전 가벼운 무게로 1-2세트 수행.';

  @override
  String get workoutShowcase12450Lbs => '12,450 lbs';

  @override
  String get workoutShowcaseViralFormatsTap =>
      '운동과 식사용 인기 포맷 200개 이상 — 탭하면 미리보기';

  @override
  String get workoutShowcase1rmEstimate => '1RM 추정치';

  @override
  String get workoutShowcase252Lb => '252 lb';

  @override
  String get workoutShowcase3Prs14Day => '3 PR · 14일 연속 기록';

  @override
  String get workoutShowcase44Min => '44분';

  @override
  String get workoutShowcaseAdjust => '조정하다';

  @override
  String get workoutShowcaseAdvanced => '고급';

  @override
  String get workoutShowcaseAll3SetsDone => '3세트 모두 완료';

  @override
  String get workoutShowcaseAllSetsLogged => '✓ 모든 세트 기록 완료';

  @override
  String get workoutShowcaseAllSetsLoggedProgression =>
      '모든 세트 기록 완료 — 진행 상황 반영 중';

  @override
  String get workoutShowcaseAskCoach => '코치에게 물어보기';

  @override
  String get workoutShowcaseAutoDesc => '자동 설명';

  @override
  String get workoutShowcaseAutoLabel => '자동 라벨';

  @override
  String workoutShowcaseAutoProgressFlash(Object delta, Object unit) {
    return '무게 자동 증가 +$delta $unit — 점진적 과부하';
  }

  @override
  String get workoutShowcaseBarbellSquat => '바벨 스쿼트';

  @override
  String get workoutShowcaseBenchPress => '벤치 프레스';

  @override
  String get workoutShowcaseBoardingPass => '탑승권';

  @override
  String get workoutShowcaseBreathing => '호흡';

  @override
  String get workoutShowcaseCal => '칼로리';

  @override
  String get workoutShowcaseCalories => '칼로리';

  @override
  String get workoutShowcaseContinue => '계속';

  @override
  String get workoutShowcaseDuration => '시간';

  @override
  String get workoutShowcaseEasy => '쉬움';

  @override
  String get workoutShowcaseEpley2255Reps => 'Epley · 225 × 5회';

  @override
  String get workoutShowcaseEverySetYouLog => '기록하는 모든 세트';

  @override
  String get workoutShowcaseEveryWorkoutFlows => '모든 운동 흐름';

  @override
  String get workoutShowcaseFinishWorkout => '운동 완료';

  @override
  String get workoutShowcaseFormat1Rm => '1RM';

  @override
  String get workoutShowcaseFormatBoarding => '탑승권';

  @override
  String get workoutShowcaseFormatCard => '카드';

  @override
  String get workoutShowcaseFormatDiscord => 'Discord';

  @override
  String get workoutShowcaseFormatFull => '전체';

  @override
  String get workoutShowcaseFormatIgStory => 'Ig story';

  @override
  String get workoutShowcaseFormatNewspaper => '신문';

  @override
  String get workoutShowcaseFormatPassport => '여권';

  @override
  String get workoutShowcaseFormatPolaroid => '폴라로이드';

  @override
  String get workoutShowcaseFormatPrCard => 'PR 카드';

  @override
  String get workoutShowcaseFormatQuote => '인용구';

  @override
  String get workoutShowcaseFormatReceipt => '영수증';

  @override
  String get workoutShowcaseFormatTrading => '트레이딩';

  @override
  String get workoutShowcaseFormatTrophy => '트로피';

  @override
  String get workoutShowcaseFormatVinyl => '바이닐';

  @override
  String get workoutShowcaseFormatWrapped => '요약';

  @override
  String get workoutShowcaseHowYourWeightReps => '세트별 중량 + 반복 횟수 진행 방식.';

  @override
  String get workoutShowcaseInfo => '정보';

  @override
  String get workoutShowcaseInstructions => '지침';

  @override
  String get workoutShowcaseIntroSubtitle =>
      'Zealova가 모든 세트를 코치하고 무게도 자동으로 올려줘요 💪';

  @override
  String get workoutShowcaseIntroTitle => '첫 운동을 시작해요';

  @override
  String get workoutShowcaseLR => '좌/우';

  @override
  String get workoutShowcaseLinearDesc => '선형 설명';

  @override
  String get workoutShowcaseLinearLabel => '선형 라벨';

  @override
  String get workoutShowcaseLogAllSets => '모든 세트';

  @override
  String get workoutShowcaseLogDrink => '로그 드링크';

  @override
  String workoutShowcaseLogSet(Object arg0) {
    return '✓ 세트 $arg0 기록';
  }

  @override
  String get workoutShowcaseLogWater => '수분 섭취 기록';

  @override
  String get workoutShowcaseMovedThisSession => '이번 세션 이동량';

  @override
  String get workoutShowcaseNewPr => '새로운 PR';

  @override
  String workoutShowcaseNextTargetRaised(
    Object delta,
    Object set,
    Object weight,
  ) {
    return '$set세트 기록 완료 — 다음 목표 자동 상향 $weight lb (+$delta lb)';
  }

  @override
  String get workoutShowcaseNote => '메모';

  @override
  String get workoutShowcasePlan => '계획';

  @override
  String get workoutShowcasePlanAutoAdjustsNext =>
      '다음 세션 계획 자동 조정 — 실제 수행 능력을 바탕으로 중량 + 반복 횟수 재조정.';

  @override
  String get workoutShowcasePoweredByZealova => 'Powered by Zealova';

  @override
  String get workoutShowcaseProgressionModel => '진행 모델';

  @override
  String get workoutShowcasePyramidDesc => '피라미드 설명';

  @override
  String get workoutShowcasePyramidLabel => '피라미드 라벨';

  @override
  String get workoutShowcaseRare => '★ 희귀';

  @override
  String get workoutShowcaseReps => '회';

  @override
  String workoutShowcaseScreenDay(Object day) {
    return '$day일차';
  }

  @override
  String workoutShowcaseScreenDuration(Object duration) {
    return '시간: $duration';
  }

  @override
  String workoutShowcaseScreenPrsEntered(Object prs) {
    return '$prs PRS · 입력됨';
  }

  @override
  String workoutShowcaseScreenSession(Object title) {
    return '세션: $title';
  }

  @override
  String workoutShowcaseScreenTotalPrs(
    Object duration,
    Object prs,
    Object volume,
  ) {
    return '총합 $duration · $volume · $prs PRS';
  }

  @override
  String workoutShowcaseScreenValue(Object duration, Object volume) {
    return '$duration · $volume';
  }

  @override
  String workoutShowcaseScreenVolZealovaPress(Object day) {
    return 'VOL. $day · ZEALOVA PRESS';
  }

  @override
  String workoutShowcaseScreenVolume(Object volume) {
    return '볼륨: $volume';
  }

  @override
  String workoutShowcaseScreenYouDay(Object day) {
    return '@you · $day일차';
  }

  @override
  String get workoutShowcaseSet1 => '1세트';

  @override
  String get workoutShowcaseSet1Of4 => '1/4 세트';

  @override
  String get workoutShowcaseSet2 => '2세트';

  @override
  String get workoutShowcaseSet3 => '세트 3';

  @override
  String workoutShowcaseSetNOf3(Object arg0) {
    return '세트 $arg0/3';
  }

  @override
  String get workoutShowcaseShareYourWorkout => '운동 공유하기';

  @override
  String get workoutShowcaseSideA => 'SIDE A';

  @override
  String get workoutShowcaseSuperset => '슈퍼세트';

  @override
  String workoutShowcaseTapToLogSet(Object arg0) {
    return '탭하여 세트 $arg0 기록';
  }

  @override
  String get workoutShowcaseTheGainsGazette => 'THE GAINS GAZETTE';

  @override
  String get workoutShowcaseTime => '시간';

  @override
  String get workoutShowcaseUndulatingDesc => '파동형 설명';

  @override
  String get workoutShowcaseUndulatingLabel => '파동형 라벨';

  @override
  String get workoutShowcaseUpNextBenchPress => '다음 운동: 벤치 프레스';

  @override
  String get workoutShowcaseUpperBodyPush => 'UPPER BODY PUSH';

  @override
  String get workoutShowcaseVideo => '비디오';

  @override
  String get workoutShowcaseVolume => '볼륨';

  @override
  String get workoutShowcaseWarmup => '웜업';

  @override
  String get workoutShowcaseWeight => '중량';

  @override
  String get workoutShowcaseWorkoutComplete => '운동 완료';

  @override
  String get workoutShowcaseWorkoutLogged => '운동 기록됨';

  @override
  String get workoutShowcaseYou => '@you';

  @override
  String get workoutShowcaseZealova => 'ZEALOVA';

  @override
  String get workoutStateCardsAiPoweredPersonalizedProgra => 'AI 기반 맞춤형 프로그램';

  @override
  String get workoutStateCardsCreatingYourWorkouts => '운동 생성 중';

  @override
  String get workoutStateCardsGeneratingYourWorkouts => '운동을 생성하는 중입니다...';

  @override
  String get workoutStateCardsGetStarted => '시작하기';

  @override
  String get workoutStateCardsGetYourPersonalizedWorkout => '맞춤형 운동 계획 받기';

  @override
  String get workoutStateCardsReadyToStart => '시작할 준비가 되셨나요?';

  @override
  String get workoutStateCardsTryAgain => '다시 시도';

  @override
  String get workoutStateCardsYourPersonalizedWorkoutPlan =>
      '맞춤형 운동 계획을 생성하고 있습니다';

  @override
  String get workoutStatsStripCalories => '칼로리';

  @override
  String get workoutStatsStripDuration => '시간';

  @override
  String workoutStatsStripKcal(Object calories) {
    return '$calories kcal';
  }

  @override
  String get workoutStatsStripVolume => '볼륨';

  @override
  String get workoutSummaryAddASetOr => '세트를 추가하거나 운동을 수정하여 요약을 채워주세요.';

  @override
  String get workoutSummaryAddExercise => '운동 추가';

  @override
  String get workoutSummaryAdvancedAiInteractions => 'AI 상호작용';

  @override
  String get workoutSummaryAdvancedAvgEffort => '평균 노력도';

  @override
  String get workoutSummaryAdvancedAvgExercises => '평균 (운동)';

  @override
  String get workoutSummaryAdvancedAvgRir => '평균 RIR';

  @override
  String get workoutSummaryAdvancedAvgRpe => '평균 RPE';

  @override
  String get workoutSummaryAdvancedAvgSets => '평균 (세트)';

  @override
  String get workoutSummaryAdvancedBasedOnEpleyFormula => '최고 세트의 Epley 공식 기준';

  @override
  String get workoutSummaryAdvancedCardioSession => '유산소 세션';

  @override
  String get workoutSummaryAdvancedConfidence => '자신감';

  @override
  String get workoutSummaryAdvancedDetailedTrackingDataIs =>
      '이 운동에 대한 상세 추적 데이터를 사용할 수 없습니다.';

  @override
  String get workoutSummaryAdvancedDuration => '시간';

  @override
  String get workoutSummaryAdvancedEffort => '노력';

  @override
  String get workoutSummaryAdvancedEnergy => '에너지';

  @override
  String get workoutSummaryAdvancedEstimated1rm => '예상 1RM';

  @override
  String get workoutSummaryAdvancedExerciseOrderTime => '운동 순서 및 시간';

  @override
  String workoutSummaryAdvancedExercises(
    Object completedCount,
    Object totalPlanned,
  ) {
    return '운동 $completedCount / $totalPlanned개 완료';
  }

  @override
  String get workoutSummaryAdvancedExercisesDone => '완료한 운동';

  @override
  String get workoutSummaryAdvancedFeelingStronger => '더 강해진 느낌';

  @override
  String get workoutSummaryAdvancedHideDetails => '상세 정보 숨기기';

  @override
  String get workoutSummaryAdvancedHowYouFelt => '운동 느낌';

  @override
  String get workoutSummaryAdvancedHydration => '수분 섭취';

  @override
  String get workoutSummaryAdvancedHydration2 => '수분 섭취';

  @override
  String get workoutSummaryAdvancedIntensity => '강도';

  @override
  String get workoutSummaryAdvancedIntensityAnalysis => '강도 분석';

  @override
  String workoutSummaryAdvancedLb(Object totalVol) {
    return '$totalVol lb';
  }

  @override
  String workoutSummaryAdvancedLb2(Object value) {
    return '$value lb';
  }

  @override
  String workoutSummaryAdvancedLong(Object tooLong) {
    return '$tooLong 소요';
  }

  @override
  String workoutSummaryAdvancedMS(Object m, Object s) {
    return '$m분 $s초';
  }

  @override
  String get workoutSummaryAdvancedMood => '기분';

  @override
  String get workoutSummaryAdvancedMoreDetails => '상세 정보 더 보기';

  @override
  String get workoutSummaryAdvancedMuscleMapNotApplicable => '근육 지도를 사용할 수 없음';

  @override
  String get workoutSummaryAdvancedMusclesHit => '자극 근육';

  @override
  String workoutSummaryAdvancedNewThisSession(Object length) {
    return '이번 세션에서 $length개 새로 추가됨';
  }

  @override
  String get workoutSummaryAdvancedNo => '아니요';

  @override
  String get workoutSummaryAdvancedNoCompletedSetsLogged =>
      '이 운동에 완료된 세트가 기록되지 않았습니다.';

  @override
  String get workoutSummaryAdvancedNoVolumeDataYet => '아직 볼륨 데이터가 없습니다';

  @override
  String get workoutSummaryAdvancedOutOf100 => '100점 만점';

  @override
  String get workoutSummaryAdvancedPeakRpe => '최고 RPE';

  @override
  String get workoutSummaryAdvancedPerExercise => '운동별';

  @override
  String get workoutSummaryAdvancedPerExerciseDeepDive => '운동별 상세 분석';

  @override
  String get workoutSummaryAdvancedPerExerciseDeepDive2 => '운동별 상세 분석';

  @override
  String get workoutSummaryAdvancedPerformanceComparison => '성과 비교';

  @override
  String get workoutSummaryAdvancedPlan => '계획';

  @override
  String get workoutSummaryAdvancedPlanAdherence => '계획 준수율';

  @override
  String get workoutSummaryAdvancedPrev => '이전';

  @override
  String get workoutSummaryAdvancedPrsHit => 'PR 달성';

  @override
  String get workoutSummaryAdvancedReps => '횟수';

  @override
  String get workoutSummaryAdvancedRest => '휴식';

  @override
  String get workoutSummaryAdvancedRestAnalysis => '휴식 분석';

  @override
  String get workoutSummaryAdvancedRestCompliance => '휴식 준수율';

  @override
  String workoutSummaryAdvancedRir(Object rir) {
    return 'RIR $rir';
  }

  @override
  String get workoutSummaryAdvancedRpeDistribution => 'RPE 분포';

  @override
  String workoutSummaryAdvancedS(Object duration) {
    return '$duration초';
  }

  @override
  String get workoutSummaryAdvancedSessionScore => '세션 점수';

  @override
  String get workoutSummaryAdvancedSessionTimeline => '세션 타임라인';

  @override
  String get workoutSummaryAdvancedSet => '세트';

  @override
  String get workoutSummaryAdvancedSetTypeDistribution => '세트 유형 분포';

  @override
  String get workoutSummaryAdvancedSets => '세트';

  @override
  String get workoutSummaryAdvancedSettingsUsed => '사용된 설정';

  @override
  String get workoutSummaryAdvancedStretching => '스트레칭';

  @override
  String get workoutSummaryAdvancedSupersetDetails => '슈퍼세트 상세 정보';

  @override
  String get workoutSummaryAdvancedTarget => '목표';

  @override
  String get workoutSummaryAdvancedTimeSpent => '소요 시간';

  @override
  String get workoutSummaryAdvancedTiming => '타이밍';

  @override
  String get workoutSummaryAdvancedTop1rm => '최고 1RM';

  @override
  String get workoutSummaryAdvancedTotalRest => '총 휴식 시간';

  @override
  String get workoutSummaryAdvancedTotalVolume => '총 볼륨: ';

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
  String get workoutSummaryAdvancedVolume => '볼륨';

  @override
  String get workoutSummaryAdvancedVolume2 => '볼륨';

  @override
  String get workoutSummaryAdvancedVolumeBreakdown => '볼륨 상세 분석';

  @override
  String get workoutSummaryAdvancedWarmup => '웜업';

  @override
  String get workoutSummaryAdvancedWarmupStretching => '웜업 및 스트레칭';

  @override
  String get workoutSummaryAdvancedWeight => '중량';

  @override
  String get workoutSummaryAdvancedWeightSuggestions => '중량 추천';

  @override
  String get workoutSummaryAdvancedWorkoutEndedEarly => '운동 조기 종료';

  @override
  String get workoutSummaryAdvancedYesU2705 => '예 ✅';

  @override
  String get workoutSummaryBodyweightSession => '맨몸 운동 세션';

  @override
  String get workoutSummaryCollapseAll => '모두 접기';

  @override
  String get workoutSummaryExpandAll => '모두 펼치기';

  @override
  String get workoutSummaryFailedToLoadSummary => '요약 정보를 불러오지 못했습니다';

  @override
  String get workoutSummaryFailedToRevertWorkout => '운동 상태 되돌리기에 실패했습니다';

  @override
  String get workoutSummaryGeneralAiCoachReview => 'AI 코치 리뷰';

  @override
  String get workoutSummaryGeneralCalories => '칼로리';

  @override
  String get workoutSummaryGeneralConnectAHeartRate =>
      '심박수 모니터를 연결하여\n심박수 구간을 추적하세요';

  @override
  String get workoutSummaryGeneralDifficulty => '난이도';

  @override
  String get workoutSummaryGeneralDuration => '지속 시간';

  @override
  String get workoutSummaryGeneralEnergy => '에너지';

  @override
  String get workoutSummaryGeneralExercises => '운동';

  @override
  String get workoutSummaryGeneralHeartRate => '심박수';

  @override
  String workoutSummaryGeneralLbXReps(Object reps, Object weightLbs) {
    return '$weightLbs lb x $reps 회';
  }

  @override
  String workoutSummaryGeneralLibraryId(Object libraryId) {
    return '라이브러리 ID: $libraryId';
  }

  @override
  String get workoutSummaryGeneralMusclesWorked => '사용된 근육';

  @override
  String get workoutSummaryGeneralPersonalRecords => '개인 기록';

  @override
  String get workoutSummaryGeneralPostWorkoutFeedback => '운동 후 피드백';

  @override
  String get workoutSummaryGeneralRating => '평점';

  @override
  String get workoutSummaryGeneralReps => '횟수';

  @override
  String get workoutSummaryGeneralSets => '세트';

  @override
  String workoutSummaryGeneralSets2(Object setCount) {
    return '$setCount 세트';
  }

  @override
  String get workoutSummaryGeneralVolumeLb => '볼륨 (lb)';

  @override
  String get workoutSummaryManuallyMarkedDone => '수동으로 완료 표시됨';

  @override
  String get workoutSummaryNoSetsLoggedFor => '이 운동에 기록된 세트가 없습니다';

  @override
  String get workoutSummaryNoWorkoutDataTo => '공유할 운동 데이터가 아직 없습니다';

  @override
  String get workoutSummaryPleaseCheckYourConnection => '연결 상태를 확인하고 다시 시도하세요.';

  @override
  String get workoutSummaryRevertMarkAsNot => '되돌리기 - 미완료로 표시';

  @override
  String get workoutSummaryReverting => '되돌리는 중...';

  @override
  String get workoutSummaryScreenAllTime => '전체 기간';

  @override
  String get workoutSummaryScreenAreasToWatch => '주의가 필요한 부위';

  @override
  String get workoutSummaryScreenFailedToLoadSummary => '요약 정보를 불러오지 못했습니다';

  @override
  String get workoutSummaryScreenFirstTimePerformingThis => '이 유형의 운동은 처음입니다!';

  @override
  String get workoutSummaryScreenHighlights => '하이라이트';

  @override
  String get workoutSummaryScreenLoadingSummary => '요약 정보 불러오는 중...';

  @override
  String workoutSummaryScreenManuallyMarkedAsDone(Object formatted) {
    return '$formatted에 수동으로 완료 표시됨';
  }

  @override
  String get workoutSummaryScreenPleaseCheckYourConnection =>
      '연결 상태를 확인하고 다시 시도하세요.';

  @override
  String workoutSummaryScreenRepsAcrossSets(
    Object totalReps,
    Object totalSets,
  ) {
    return '$totalSets 세트 동안 $totalReps 회 반복';
  }

  @override
  String workoutSummaryScreenTotalKgLifted(Object volume) {
    return '총합: $volume kg 들어 올림';
  }

  @override
  String get workoutSummaryScreenU2022 => '  •  ';

  @override
  String workoutSummaryScreenUiImprovement(Object pr) {
    return '개선율 +$pr%';
  }

  @override
  String workoutSummaryScreenUiKgXRepsEst(
    Object estimated1rmKg,
    Object reps,
    Object weightKg,
  ) {
    return '$weightKg kg x $reps회  |  예상 1RM: $estimated1rmKg kg';
  }

  @override
  String workoutSummaryScreenUiValue(Object overallRating) {
    return '$overallRating/10';
  }

  @override
  String get workoutSummarySetsUpdatedSuccessfully => '세트가 성공적으로 업데이트되었습니다';

  @override
  String get workoutSummaryShareWorkout => '운동 공유';

  @override
  String get workoutSummaryTracked => '추적됨';

  @override
  String get workoutSummaryWorkoutSummary => '운동 요약';

  @override
  String get workoutTopBarCompleteWorkout => '운동 완료';

  @override
  String get workoutTopBarMore => '더 보기';

  @override
  String get workoutTopBarSkipExercise => '운동 건너뛰기';

  @override
  String get workoutTopOverlayPaused => '일시 정지';

  @override
  String get workoutTypeSelectorEnterCustomWorkoutType =>
      '사용자 지정 운동 유형 입력 (예: \"Mobility\")';

  @override
  String get workoutTypeSelectorHowYouWantTo =>
      '원하는 훈련 방식을 선택하세요. 아래의 목표 부위에서 신체 부위를 선택할 수 있습니다.';

  @override
  String get workoutTypeSelectorTrainingStyle => '훈련 스타일';

  @override
  String get workoutUiBuildersBreathing => '호흡';

  @override
  String get workoutUiBuildersConfirm => '확인';

  @override
  String get workoutUiBuildersDrink => '수분 섭취';

  @override
  String get workoutUiBuildersHeardRepsButNot =>
      '횟수는 인식했지만 중량을 인식하지 못했습니다. \"225 for 5\"와 같이 입력해 보세요.';

  @override
  String get workoutUiBuildersHowTo => '방법';

  @override
  String get workoutUiBuildersLoadingYourPersonalizedWarm =>
      '개인 맞춤형 웜업 운동을 불러오는 중';

  @override
  String workoutUiBuildersMixinUi2HeardKg(Object parsed) {
    return '인식됨: $parsed kg × ';
  }

  @override
  String workoutUiBuildersMixinUi2LoggedReps(
    Object reps,
    Object weightDisplay,
  ) {
    return '$weightDisplay × $reps회 기록됨';
  }

  @override
  String workoutUiBuildersMixinUi2LoggingAnyway(Object name) {
    return '\"$name\". 그대로 기록합니다.';
  }

  @override
  String workoutUiBuildersMixinUi2YouSaidCurrentExercise(Object liftHint) {
    return '\"$liftHint\"(이)라고 하셨습니다 — 현재 운동은 ';
  }

  @override
  String get workoutUiBuildersNote => '메모';

  @override
  String get workoutUiBuildersPreparingWarmup => '웜업 준비 중...';

  @override
  String get workoutUiBuildersSavingWorkout => '운동 저장 중...';

  @override
  String get workoutUiBuildersSkipWarmup => '웜업 건너뛰기';

  @override
  String get workoutUiBuildersSwap => '교체';

  @override
  String get workoutUiBuildersTapToReturn => '탭하여 돌아가기';

  @override
  String get workoutUiBuildersUndo => '실행 취소';

  @override
  String get workoutUiModeAdvanced => '고급';

  @override
  String get workoutUiModeEverythingWarmupStretchPh =>
      '모든 기능 포함 — 웜업/스트레칭 단계, RPE/RIR, 피라미드, 슈퍼세트, 드롭 세트, ±2.5kg 단위 증량, 원판 차트.';

  @override
  String get workoutUiModePickTheLevelOf =>
      '세트 기록 시 원하는 상세 수준을 선택하세요. 언제든지 변경할 수 있습니다.';

  @override
  String get workoutUiModePolishedDefaultSteppersAi =>
      '세련된 기본 모드. 스텝퍼, AI 코치, 휴식 타이머, 오디오/사진 메모, 이전 세트 탭하여 수정 기능. 대부분의 세션에 적합합니다.';

  @override
  String get workoutUiModeSelected => '선택됨';

  @override
  String workoutUiModeSheetMode(Object title) {
    return '$title 모드';
  }

  @override
  String get workoutUiModeWorkoutMode => '운동 모드';

  @override
  String get workoutsBenchSquatDeadliftBest =>
      '벤치, 스쿼트, 데드리프트 — 최고 기록 세트만 알고 있을 때 가장 좋습니다';

  @override
  String get workoutsCollapseWeekView => '주간 보기 접기';

  @override
  String get workoutsCompleteYourFirstWorkout => '첫 운동을 완료하고 여기서 확인하세요';

  @override
  String get workoutsCsvOrJsonFile => 'CSV 또는 JSON 파일';

  @override
  String get workoutsCustom => '사용자 지정';

  @override
  String get workoutsExpandWeekView => '주간 보기 펼치기';

  @override
  String get workoutsFavorites => '즐겨찾기';

  @override
  String get workoutsFloatingOptionsGym => '헬스장';

  @override
  String get workoutsFloatingOptionsManageGym => '헬스장 관리';

  @override
  String get workoutsGym => '헬스장';

  @override
  String get workoutsHealthConnectAppleHealth =>
      'Health Connect / Apple Health';

  @override
  String get workoutsHevyStrongLiftinFitbod =>
      'Hevy, Strong, Liftin\', Fitbod, Stronger by the Day, 사용자 지정 CSV';

  @override
  String get workoutsImportWorkouts => '운동 가져오기';

  @override
  String get workoutsLibrary => '라이브러리';

  @override
  String get workoutsMoreOptions => '추가 옵션';

  @override
  String get workoutsNoCompletedWorkoutsYet => '아직 완료한 운동이 없습니다';

  @override
  String get workoutsPlan => '플랜';

  @override
  String get workoutsPrograms => '프로그램';

  @override
  String workoutsScreenBringYourPastWorkouts(Object appName) {
    return '과거 운동 기록과 PR을 $appName로 가져오면 AI가 첫날부터 적절한 무게를 추천해 드립니다.';
  }

  @override
  String get workoutsStrength => '근력';

  @override
  String get workoutsSyncSessionsFromYour => '워치에서 세션 동기화 (백그라운드에서 동기화 중)';

  @override
  String get workoutsTourHitStartOnToday =>
      '오늘의 운동에서 \'시작\'을 눌러 세트, 횟수, 무게를 기록하고 휴식 타이머를 활용하세요.';

  @override
  String get workoutsTourMakeItYours => '나만의 운동 만들기';

  @override
  String get workoutsTourPinFavoritesHideExercises =>
      '즐겨찾기를 고정하고, 피하는 운동은 숨기거나 다음에 할 운동을 대기열에 추가하세요.';

  @override
  String get workoutsTourSetYourPreferences => '환경 설정';

  @override
  String get workoutsTourStartAWorkout => '운동 시작';

  @override
  String get workoutsTourUseCustomBrowseOr =>
      '사용자 지정, 탐색, 즐겨찾기를 사용하여 운동을 구성, 교체 또는 반복하세요.';

  @override
  String get workoutsTypeAFewPrs => '몇 가지 PR을 수동으로 입력';

  @override
  String get workoutsUpcoming => '예정된 운동';

  @override
  String get workoutsYouCanEditUndo =>
      '가져온 데이터는 나중에 언제든 수정, 취소 또는 재매핑할 수 있습니다. 데이터는 삭제되지 않습니다.';

  @override
  String get workoutsYourNextWorkoutIs => '다음 운동은 각 세션이 끝난 후 자동으로 생성됩니다';

  @override
  String get wrappedBannerTapToRevealYour => '탭하여 나의 헬스장 성향 확인하기';

  @override
  String get wrappedBannerViewMyWrapped => '나의 Wrapped 보기';

  @override
  String wrappedBannerWorkoutsSoFarKeep(Object workoutsSoFar) {
    return '현재까지 $workoutsSoFar회 운동  ·  계속 힘내세요!';
  }

  @override
  String wrappedBannerWrappedDropsIn(Object daysLabel, Object month) {
    return '$month Wrapped 공개까지 $daysLabel 남음';
  }

  @override
  String wrappedBannerYourWrappedIsHere(Object month) {
    return '$month WRAPPED가 도착했습니다';
  }

  @override
  String get wrappedShareCopyText => '텍스트 복사';

  @override
  String get wrappedShareInstagram => 'Instagram';

  @override
  String get wrappedShareSaveImage => '이미지 저장';

  @override
  String get wrappedShareShareWrapped => 'Wrapped 공유';

  @override
  String get wrappedShareShowWatermark => '워터마크 표시';

  @override
  String get wrappedSummaryShareYourWrapped => 'Wrapped 공유하기';

  @override
  String get wrappedSummaryStatBestStreak => '최고 연속 기록';

  @override
  String get wrappedSummaryStatExercises => '운동 종목';

  @override
  String get wrappedSummaryStatHours => '시간';

  @override
  String get wrappedSummaryStatPrs => 'PR';

  @override
  String get wrappedSummaryStatVolumeLbs => '볼륨 (lbs)';

  @override
  String get wrappedSummaryStatWorkouts => '운동';

  @override
  String get wrappedSummaryYourMonthInReview => '이번 달 요약';

  @override
  String wrappedTemplateSets(Object workoutName) {
    return '$workoutName 세트';
  }

  @override
  String get wrappedTemplateVolume => '볼륨';

  @override
  String get wrappedTemplateWrapped => 'WRAPPED';

  @override
  String get wrappedViewerFailedToLoadYour => 'Wrapped를 불러오지 못했습니다';

  @override
  String xpEarnedAnimationXp(Object xpAmount) {
    return '+$xpAmount XP';
  }

  @override
  String get xpGoalsDaily => '일일';

  @override
  String get xpGoalsDialog250LevelsAcross11Tiers => '11개 티어에 걸친 250개 레벨';

  @override
  String get xpGoalsDialogBeginnerToTranscendent => '초보자에서 초월자까지';

  @override
  String get xpGoalsDialogCompleteWorkoutXp => '운동 완료: +100 XP';

  @override
  String get xpGoalsDialogDailyGoals => '일일 목표';

  @override
  String get xpGoalsDialogFirstChatWithAiCoachXp => 'AI 코치와 첫 채팅: +15 XP';

  @override
  String get xpGoalsDialogFirstMealWeightMeasurementsXp =>
      '첫 식사/체중/측정: 각 +50 XP';

  @override
  String get xpGoalsDialogFirstPrXp => '첫 PR: +100 XP';

  @override
  String get xpGoalsDialogFirstProgressPhotoXp => '첫 진행 사진: +75 XP';

  @override
  String get xpGoalsDialogFirstProteinGoalXp => '첫 단백질 목표: +100 XP';

  @override
  String get xpGoalsDialogFirstWorkoutXp => '첫 운동: +150 XP';

  @override
  String get xpGoalsDialogHitProteinGoalXp => '단백질 목표 달성: +50 XP';

  @override
  String get xpGoalsDialogLevels => '레벨';

  @override
  String get xpGoalsDialogLogBodyMeasurementsXp => '신체 측정 기록: +20 XP';

  @override
  String get xpGoalsDialogLogMealXp => '식사 기록: +25 XP';

  @override
  String get xpGoalsDialogLogWeightXp => '체중 기록: +15 XP';

  @override
  String get xpGoalsDialogLoginXp => '로그인: +5 XP';

  @override
  String get xpGoalsDialogMilestoneRewards => '마일스톤 보상';

  @override
  String get xpGoalsFirstTimeBonuses => '첫 달성 보너스';

  @override
  String get xpGoalsGotIt => '확인했습니다!';

  @override
  String get xpGoalsHowXpWorks => 'XP 작동 방식';

  @override
  String get xpGoalsLoginStreak => '로그인 연속 기록';

  @override
  String get xpGoalsMonthly => '월간';

  @override
  String get xpGoalsScreenAllLevels => '모든 레벨';

  @override
  String get xpGoalsScreenBeginner => '초보자';

  @override
  String get xpGoalsScreenChatWithAiCoach => 'AI 코치와 대화하기';

  @override
  String get xpGoalsScreenCheckYourConnectionAnd => '연결 상태를 확인하고 다시 시도하세요';

  @override
  String get xpGoalsScreenComplete1Workout => '운동 1회 완료';

  @override
  String get xpGoalsScreenCompleteFirstWorkout => '첫 운동 완료';

  @override
  String get xpGoalsScreenConsumableLegend => '소모품 범례';

  @override
  String get xpGoalsScreenErrorLoadingMonthlyAchievem =>
      '월간 업적을 불러오는 중 오류가 발생했습니다';

  @override
  String get xpGoalsScreenErrorLoadingWeeklyProgress =>
      '주간 진행 상황을 불러오는 중 오류가 발생했습니다';

  @override
  String get xpGoalsScreenFailedToLoadLevels => '레벨을 불러오지 못했습니다';

  @override
  String get xpGoalsScreenHit10kSteps => '1만 걸음 달성';

  @override
  String get xpGoalsScreenHitCalorieGoal => '칼로리 목표 달성';

  @override
  String get xpGoalsScreenHitFirstProteinGoal => '첫 단백질 목표 달성';

  @override
  String get xpGoalsScreenHitHydrationGoal => '수분 섭취 목표 달성';

  @override
  String get xpGoalsScreenHitProteinGoal => '단백질 목표 달성';

  @override
  String get xpGoalsScreenInventory => '인벤토리';

  @override
  String get xpGoalsScreenLegendary => '전설';

  @override
  String xpGoalsScreenLevelCurrentTotal(Object arg0) {
    return '레벨 $arg0 • 총 249레벨';
  }

  @override
  String get xpGoalsScreenLevelProgress => '레벨 진행도';

  @override
  String get xpGoalsScreenLogBodyMeasurements => '신체 치수 기록';

  @override
  String get xpGoalsScreenLogFirstMeal => '첫 식사 기록';

  @override
  String get xpGoalsScreenLogFirstWeight => '첫 체중 기록';

  @override
  String get xpGoalsScreenLogInToday => '오늘 로그인';

  @override
  String get xpGoalsScreenLogWeight => '체중 기록';

  @override
  String get xpGoalsScreenMilestone => '마일스톤';

  @override
  String get xpGoalsScreenMilestoneLegend => '마일스톤 범례';

  @override
  String get xpGoalsScreenNoLevelsAvailable => '사용 가능한 레벨이 없습니다';

  @override
  String get xpGoalsScreenReward => '보상';

  @override
  String get xpGoalsScreenSetFirstPersonalRecord => '첫 개인 최고 기록(PR) 설정';

  @override
  String xpGoalsScreenUi1CheckpointsComplete(
    Object completedCount,
    Object length,
  ) {
    return '$length개 중 $completedCount개 체크포인트 완료';
  }

  @override
  String xpGoalsScreenUi1Complete(Object completedCount, Object length) {
    return '$length개 중 $completedCount개 완료';
  }

  @override
  String xpGoalsScreenUi1DaysRemaining(Object daysRemaining) {
    return '$daysRemaining일 남음';
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
  String get xpGoalsScreenViewAllLevelsRewards => '모든 레벨 및 보상 보기';

  @override
  String xpGoalsScreenXp(Object effectiveXP) {
    return '+$effectiveXP XP';
  }

  @override
  String get xpGoalsScreenXpBonusLegend => 'XP 보너스 범례';

  @override
  String get xpGoalsScreenYouBadge => '사용자 배지';

  @override
  String get xpGoalsTrophyRoom => '트로피 룸';

  @override
  String get xpGoalsU2022 => '• ';

  @override
  String get xpGoalsWeekly => '주간';

  @override
  String xpGoalsXpAvailable(Object arg0) {
    return '+$arg0 XP 획득 가능';
  }

  @override
  String xpGoalsXpEarnedToday(Object arg0) {
    return '오늘 +$arg0 XP 획득';
  }

  @override
  String get xpGoalsXpGoals => 'XP 목표';

  @override
  String xpGoalsXpMultiplierActive(Object arg0) {
    return '${arg0}x XP 활성화!';
  }

  @override
  String xpHeroTileDayStreak(Object streak) {
    return '$streak일 연속';
  }

  @override
  String xpHeroTileLv(Object level) {
    return 'Lv $level';
  }

  @override
  String xpHeroTileLv2(Object label, Object nextLevel) {
    return 'Lv $nextLevel → $label';
  }

  @override
  String get xpHeroTileThisWeek => '이번 주';

  @override
  String xpHeroTileValue(Object thisWeekXp) {
    return '+$thisWeekXp';
  }

  @override
  String get xpHeroTileVsLastWeek => '지난주 대비';

  @override
  String xpHeroTileXp(Object xpInLevel, Object xpToNext) {
    return '$xpInLevel / $xpToNext XP';
  }

  @override
  String get xpLeaderboardNoLeaderboardDataYet =>
      '아직 리더보드 데이터가 없습니다.\nXP를 획득하여 순위를 올려보세요!';

  @override
  String xpLeaderboardScreenLevel(Object currentLevel) {
    return '레벨 $currentLevel';
  }

  @override
  String xpLeaderboardScreenLvl(Object currentLevel) {
    return '레벨 $currentLevel';
  }

  @override
  String xpLeaderboardScreenValue(Object rank) {
    return '#$rank';
  }

  @override
  String xpLeaderboardScreenValue2(Object rank) {
    return '#$rank';
  }

  @override
  String get xpLeaderboardTotalXp => '총 XP';

  @override
  String get xpLeaderboardXpLeaderboard => 'XP 리더보드';

  @override
  String get xpLeaderboardYourRank => '내 순위';

  @override
  String get xpLevelBarLvl => '레벨';

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
  String get xpProgressCardDaily => '일일';

  @override
  String get xpProgressCardDays => '일';

  @override
  String get xpProgressCardLevel1Novice => '레벨 1 • 초보자';

  @override
  String xpProgressCardLevelN(Object level) {
    return '레벨 $level';
  }

  @override
  String get xpProgressCardLoadingXp => 'XP 불러오는 중...';

  @override
  String xpProgressCardLvl(Object currentLevel, Object displayName) {
    return 'Lv.$currentLevel $displayName';
  }

  @override
  String xpProgressCardLvlN(Object level) {
    return '레벨 $level';
  }

  @override
  String get xpProgressCardNextLevel => '다음 레벨';

  @override
  String get xpProgressCardNone => '없음';

  @override
  String get xpProgressCardNovice => '초보자';

  @override
  String xpProgressCardPercentToLevel(Object level, Object percent) {
    return '레벨 $level까지 $percent%';
  }

  @override
  String xpProgressCardPrestigeN(Object level) {
    return '프레스티지 $level';
  }

  @override
  String get xpProgressCardStartYourFitnessJourney => '피트니스 여정을 시작하세요!';

  @override
  String get xpProgressCardStreak => '연속 기록';

  @override
  String xpProgressCardValue(Object progressPercent) {
    return '$progressPercent%';
  }

  @override
  String get xpProgressCardWeekly => '주간';

  @override
  String xpProgressCardXpTotal(Object xp) {
    return '총 $xp XP';
  }

  @override
  String get youAchievements => '업적';

  @override
  String get youHubMiniGames => '미니 게임';

  @override
  String get youHubMiniGamesUnlocked => '🎮 미니 게임 잠금 해제!';

  @override
  String get youHubOverview => '개요';

  @override
  String youHubScreenMore(Object remaining) {
    return '$remaining개 더 보기…';
  }

  @override
  String get youHubStats => '통계';

  @override
  String get youHubStatsScores => '통계 및 점수';

  @override
  String get youSkills => '스킬';

  @override
  String get youTrophies => '트로피';

  @override
  String get youWrapped => '연말 결산';

  @override
  String chatLanguageChangedSystem(String nativeName) {
    return '🌐 AI Coach가 이제 $nativeName(으)로 응답합니다';
  }

  @override
  String get chatLanguageResetSystem => '🌐 AI Coach 언어가 초기화되었습니다. 앱 언어를 사용합니다';

  @override
  String get settingsChatLanguageTitle => 'AI Coach 언어';

  @override
  String get settingsChatLanguageDescription =>
      'AI Coach 응답 언어 설정 (앱 UI 언어와 별개)';

  @override
  String get settingsChatLanguageSameAsApp => '앱 언어와 동일';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNo => 'No';

  @override
  String get settingsImportsTitle => '수입품';

  @override
  String get settingsImportsSubtitle => '귀하가 Zealova에 공유한 모든 것';

  @override
  String get settingsCycleTrackingTitle => '주기 추적';

  @override
  String get settingsCycleTrackingSubtitle => '생리, 임신 가능성 및 예측';

  @override
  String settingsAboutBrand(Object appName) {
    return '$appName 정보';
  }

  @override
  String get vacationModeBannerActive => '휴가 모드가 활성화되었습니다.';

  @override
  String vacationModeBannerPausedUntil(Object endDate) {
    return '알림은 $endDate까지 일시중지됩니다.';
  }

  @override
  String get vacationModeBannerPausedNoEnd => '알림이 일시중지되었습니다. 재개하려면 언제든지 끄세요.';

  @override
  String get vacationModeBannerScheduled => '예정됨';

  @override
  String vacationModeBannerStartsOn(Object startDate) {
    return '$startDate에 시작됩니다.';
  }

  @override
  String get vacationModeBannerOn => '알림이 켜져 있습니다';

  @override
  String get vacationModeBannerOnSubtitle =>
      '중요하지 않은 알림을 일시중지하려면 아래에서 휴가 모드를 활성화하세요.';

  @override
  String get difficultyEasy => '초보자';

  @override
  String get difficultyMedium => '보통의';

  @override
  String get difficultyHard => '도전적이다';

  @override
  String get difficultyHell => '지옥';

  @override
  String get habitWorkouts => '운동';

  @override
  String get habitFoodLog => '음식 기록';

  @override
  String get habitWater => '물';

  @override
  String get importsAppBarTitle => '수입품';

  @override
  String get importsTooltipFormatsLimits => '지원되는 형식 및 제한';

  @override
  String get importsTooltipDone => '완료';

  @override
  String get importsTooltipSelect => '선택하다';

  @override
  String get importsSearchHint => '수입품 검색…';

  @override
  String get importsFilterAll => '모두';

  @override
  String get importsFilterAllFormats => '모든 형식';

  @override
  String get importsActionDelete => '삭제';

  @override
  String importsSelectedCount(Object count) {
    return '$count개 선택됨';
  }

  @override
  String get importsEmptyTitle => '아직 공유된 항목이 없습니다.';

  @override
  String get importsEmptyBody =>
      '사진, YouTube, ChatGPT, 음성 메모 등 어디에서나 공유를 누르면 여기에 자동으로 전송됩니다.';

  @override
  String get importsActionOpen => '열려 있는';

  @override
  String get importsActionRetry => '다시 해 보다';

  @override
  String get importsActionReclassify => '재분류';

  @override
  String get importsSnackRetrying => '가져오기 재시도 중…';

  @override
  String get importsSnackRetryFailed => '다시 시도할 수 없습니다. 나중에 다시 시도하세요.';

  @override
  String get importsSnackReclassifyQueued =>
      '대기 중인 재분류 - 항목을 다시 공유하여 경로를 재지정합니다.';

  @override
  String importsDeleteConfirmTitle(Object count) {
    return '$count개의 가져오기를 삭제하시겠습니까?';
  }

  @override
  String get importsDeleteConfirmBody =>
      '해당 기록은 수입 내역에서 제거됩니다. 가져온 운동/레시피/음식 로그 자체가 그대로 유지됩니다.';

  @override
  String get importsActionCancel => '취소';

  @override
  String get importsRowImportFailed => '가져오기 실패';

  @override
  String get importsTitleImportedWorkout => '가져온 운동';

  @override
  String get importsTitleImportedRecipe => '가져온 레시피';

  @override
  String get importsTitleImportedMealPlan => '수입 식사 계획';

  @override
  String get importsTitleLoggedMeal => '기록된 식사';

  @override
  String get importsTitleFormCheck => '양식 확인';

  @override
  String get importsTitleProgressPhoto => '진행상황 사진';

  @override
  String get importsTitleSavedTip => '저장된 팁';

  @override
  String get importsTitleImportDetail => '가져오기 세부정보';

  @override
  String importsDetailFrom(Object url) {
    return '보낸 사람: $url';
  }

  @override
  String importsDetailStatus(Object status) {
    return '상태: $status';
  }

  @override
  String importsDetailDetectedAs(Object intent) {
    return '다음으로 감지됨: $intent';
  }

  @override
  String get importsLimitsTitle => '공유할 수 있는 것';

  @override
  String get importsLimitsLimitsHeader => '제한';

  @override
  String get importsLimitsFooter =>
      '일일 한도는 모든 사람에게 동일합니다. 수입 품질을 높게 유지하고 폭주하는 비용으로부터 보호합니다.';

  @override
  String get importsPrivacySectionTitle => '수입품';

  @override
  String get importsPrivacyAlwaysAskTitle => '라우팅하기 전에 항상 물어보세요.';

  @override
  String get importsPrivacyAlwaysAskSubtitle =>
      '자동 경로 카운트다운을 건너뛰세요. 공유할 때마다 선택기가 열립니다.';

  @override
  String get importsPrivacyClearHistoryTitle => '공유 기록 지우기';

  @override
  String get importsPrivacyClearHistorySubtitle =>
      '가져오기 목록에서 모든 기록을 제거합니다. 가져온 운동, 레시피, 음식 로그는 그대로 유지됩니다.';

  @override
  String get importsPrivacyClearConfirmTitle => '공유 기록을 삭제하시겠습니까?';

  @override
  String get importsPrivacyClearConfirmBody =>
      '가져오기 목록의 모든 행이 제거됩니다. 가져온 운동, 레시피, 음식 기록은 그대로 유지됩니다.';

  @override
  String get importsPrivacyClearAction => '분명한';

  @override
  String get importsPrivacyClearedSnack => '공유 기록이 삭제되었습니다.';

  @override
  String get importsPrivacyClearFailedSnack => '삭제할 수 없습니다. 나중에 다시 시도해 주세요.';

  @override
  String get bottomNavLeaderboard => '랭킹';

  @override
  String get discoverBoardXp => 'XP';

  @override
  String get discoverResetsSunday => '일요일 초기화';

  @override
  String get discoverNoEntriesYet => '아직 기록 없음 · 이번 주 운동을 기록해 올라가세요';

  @override
  String get discoverViewTop10 => 'TOP 10 보기';

  @override
  String get discoverMovers => '상승세';

  @override
  String get heroModesPillLoading => '로딩 중';

  @override
  String get heroModesBodyLoading => '오늘의 계획을 준비하고 있어요…';

  @override
  String get heroModesPillOffline => '오프라인';

  @override
  String get heroModesBodyOffline => '오늘의 운동을 불러올 수 없어요. 다시 시도하려면 탭하세요.';

  @override
  String get heroModesActionRetry => '재시도';

  @override
  String get heroModesPillLive => '라이브';

  @override
  String get heroModesPillPaused => '일시중지';

  @override
  String get heroModesBodyPaused => '계획이 일시중지되었어요. 준비되면 다시 시작하세요.';

  @override
  String get heroModesPillWindDown => '내일 · 마무리';

  @override
  String get heroModesBodyWindDown => '먼저 자세요. 내일 세션이 기다릴게요.';

  @override
  String get heroModesPillLighter => '더 가볍게 권장';

  @override
  String get heroModesBodyLighter => '잠을 잘 못 잤어요. 오늘은 가벼운 버전을 시도할까요?';

  @override
  String get heroModesPillEquipmentGap => '장비 부족';

  @override
  String get heroModesBodyEquipmentGap => '현재 짐 프로필에 없는 장비가 있어요.';

  @override
  String get heroModesPillFasted => '공복 상태';

  @override
  String get heroModesBodyFasted => '공복 트레이닝 괜찮아요. 강도는 중간으로, 30분 안에 보충하세요.';

  @override
  String get heroModesPillFuelGap => '연료 부족';

  @override
  String get heroModesBodyFuelGap => '마지막 식사가 오래됐어요. 탄수화물 ~200kcal 드실래요?';

  @override
  String get heroModesPillComeback => '복귀';

  @override
  String get heroModesBodyComeback => '이 근육군의 첫 세션이 오랜만이에요. 천천히 시작해요.';

  @override
  String get heroModesPillPrWindow => 'PR 윈도우';

  @override
  String get heroModesBodyPrWindow => '오늘 기록에 가까워요. 도전할까요?';

  @override
  String get heroModesActionStart => '시작';

  @override
  String get heroModesPillBodyAsksRest => '몸이 휴식을 원해요';

  @override
  String get heroModesBodyBodyAsksRest => '힘든 5일, 수면 감소. 오늘은 다음 주를 위한 투자예요.';

  @override
  String get heroModesPillRefuelWindow => '재충전 윈도우';

  @override
  String get heroModesBodyRefuelWindow => '30분 재충전 창: 단백질 + 탄수화물이 성과를 굳혀요.';

  @override
  String get heroModesPillBonus => '보너스';

  @override
  String get heroModesBodyBonus => '20분 있어요? 빠른 세션을 끼워 넣어요.';

  @override
  String get heroModesPillYesterday => '어제';

  @override
  String get heroModesBodyYesterday => '어제 세션이 아직 열려 있어요. 오늘로 옮길까요?';

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
    return '~$minutes분 남음';
  }

  @override
  String quizStepOfTotal(int current, int total) {
    return '$total단계 중 $current단계';
  }

  @override
  String get quizAlmostDone => '거의 다 됐어요';

  @override
  String get introV7HeadlineLine1 => '당신의 코치는';

  @override
  String get introV7HeadlineAlready => '이미';

  @override
  String get introV7WordTyping => '입력 중.';

  @override
  String get introV7WordSpotting => '보조 중.';

  @override
  String get introV7WordCounting => '세는 중.';

  @override
  String get introV7WordChoosing => '고르는 중.';

  @override
  String get introV7BuildMyPlan => '내 플랜 만들기';

  @override
  String get introDemoLiveBadge => '라이브 데모';

  @override
  String get introDemoProgramBuilder => '프로그램 빌더';

  @override
  String get introDemoCoachName => '알렉스 코치';

  @override
  String get introDemoUserAsk => '주 4일 프로그램 만들어 줘 💪';

  @override
  String get introDemoPushDayMon => '푸시 데이 · 월';

  @override
  String get introDemoGoalChip => '📅 목표 달성 예상일: 8월 22일';

  @override
  String get introDemoUserReply => '가자 🔥';

  @override
  String get introDemoExerciseKicker => '푸시 데이 · 운동 1/5';

  @override
  String introDemoSetRow(int n) {
    return '세트 $n';
  }

  @override
  String get introDemoResting => '휴식 중…';

  @override
  String get introDemoPrChip => '🏆 새 PR · 225 lb';

  @override
  String get introDemoCoachPrLine => '코치: “225 — 10 lb PR이에요. 다음 주엔 230 갑니다.”';

  @override
  String get introDemoPhotoLogging => '사진 기록';

  @override
  String get introDemoLoggedLine => '✓ 오늘에 기록 완료 — 사진 1장, 2초';

  @override
  String get introDemoKcalChip => '540 kcal';

  @override
  String get introDemoProteinChip => '단백질 38g';

  @override
  String get introDemoCarbsChip => '탄수화물 52g';

  @override
  String get introDemoFatChip => '지방 18g';

  @override
  String get introDemoMenuTitle => '메뉴 분석';

  @override
  String get introDemoMenuMeta => '8개 항목 · 3개 섹션 · 2.4초';

  @override
  String get introDemoSortLabel => '정렬:';

  @override
  String get introDemoSortProtein => '단백질';

  @override
  String get introDemoSortCarbs => '탄수화물';

  @override
  String get introDemoSortInflammation => '염증';

  @override
  String get introDemoBadgeRecommended => '추천';

  @override
  String get introDemoBadgeOk => '괜찮음';

  @override
  String get introDemoBadgeAvoid => '피하기';

  @override
  String planAnalyzingReceiptGoals(String goal) {
    return '목표 검토 완료 — $goal';
  }

  @override
  String planAnalyzingReceiptBody(String body) {
    return '체형 매칭 완료 — $body';
  }

  @override
  String planAnalyzingReceiptSchedule(int days) {
    return '스케줄 설정 완료 — 주 $days일';
  }

  @override
  String get planAnalyzingSubtitleV7 => '~20초 · 코치가 모든 세트를 직접 고르고 있어요';

  @override
  String get signInV7DontLoseIt => '잃어버리지 마세요.';

  @override
  String get signInV7LetsGetStarted => '이제 시작해 볼까요.';

  @override
  String get signInV7KickerPlanBuilt => '플랜이 완성됐어요';

  @override
  String signInV7GoalDateChip(String date) {
    return '📅 목표: $date';
  }

  @override
  String get personalInfoConfirmedFromQuiz => '퀴즈에서 확인된 정보';

  @override
  String personalInfoGoalChip(String value) {
    return '목표 $value';
  }

  @override
  String coachSelectionTrainWith(String coachName) {
    return '$coachName와 함께 트레이닝하기';
  }

  @override
  String get paywallFounderKicker => '창업자의 메시지';

  @override
  String get paywallFounderHeadline => '제가 감당할 수 없었던 코치를 직접 만들었습니다.';

  @override
  String get paywallFounderQuote =>
      '“좋은 퍼스널 트레이너는 한 달에 \$400입니다. 그 돈을 쓸 수 없어서 2년에 걸쳐 직접 만들었습니다. 1,722개의 운동, 진짜 점진적 과부하 로직, 당신의 한 주를 실제로 들여다보는 코치. 저는 매일 쓰고 있습니다.”';

  @override
  String get paywallFounderName => 'Chetan · 창업자';

  @override
  String get paywallFounderSub => '첫날부터 Zealova와 함께 트레이닝 중';

  @override
  String get paywallTesterQuote =>
      '“제가 금요일 하체 운동을 늘 거른다는 걸 알아채더니 그냥… 토요일로 옮겨줬어요.”';

  @override
  String get paywallTesterName => 'Keertan · 초기 테스터';

  @override
  String get paywallEarlyAccess => '얼리 액세스 · 첫 1,000명의 멤버가 되어 보세요';

  @override
  String get paywallRemindMeCta => '알림 받기 🔔';

  @override
  String get paywallTrialToggleTitle => '무료 체험 활성화됨';

  @override
  String paywallTrialToggleOn(String price) {
    return '7일 무료, 이후 $price/년으로 자동 갱신';
  }

  @override
  String get paywallTrialToggleOff => '월간 플랜 — 오늘 시작, 체험 없음';

  @override
  String get paywallV7DownsellHeadline => '플랜이 삭제된다고요?';

  @override
  String get paywallV7DownsellSub =>
      '단 한 번뿐인 창립 멤버 가격, 동일한 7일 무료 체험. 이 혜택은 다시 오지 않습니다.';
}
