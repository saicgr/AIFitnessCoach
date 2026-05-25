// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Zealova';

  @override
  String get navHome => '홈';

  @override
  String get navWorkouts => '운동';

  @override
  String get navNutrition => '영양';

  @override
  String get navProgress => '진행';

  @override
  String get navProfile => '프로필';

  @override
  String get buttonStart => '시작';

  @override
  String get buttonSave => '저장';

  @override
  String get buttonCancel => '취소';

  @override
  String get buttonDelete => '삭제';

  @override
  String get buttonRetry => '다시 시도';

  @override
  String get buttonContinue => '계속';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageSubtitle => '선호 언어를 선택하세요';

  @override
  String get equipmentCalibrationTitle => '장비 보정';

  @override
  String get equipmentCalibrationIntroTitle => '실제 장비를 알려주세요';

  @override
  String get equipmentCalibrationIntroBody =>
      '원판 제안과 중량 추천이 실제 보유 장비와 일치합니다. 바벨 무게, 머신 슬레지 무게, 케이블 핀 증가량, 원판/덤벨 재고를 설정하세요.';

  @override
  String get recoveryLabel => '회복';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get rpeFailure => '실패';

  @override
  String get rpeOneRepLeft => '1회 남음';

  @override
  String get rpeTwoRepsLeft => '2회 남음';

  @override
  String get rpeEasy => '쉬움';

  @override
  String get rpeLight => '가벼움';

  @override
  String get strengthScoreCardTitle => '근력 점수';

  @override
  String get strengthBestLift => '최고 기록';

  @override
  String get strengthContributionToScore => '점수 기여도';

  @override
  String get journalTitle => '트레이닝 일지';

  @override
  String get journalSearchHint => '운동, 음식, 사진 검색…';

  @override
  String get journalEmpty => '일지가 비어 있습니다. 타임라인을 시작하려면 운동을 기록하세요.';

  @override
  String get challengeCreateTitle => '챌린지 만들기';

  @override
  String get challengeCreateFieldTitle => '제목';

  @override
  String get challengeCreateFieldGoal => '목표';

  @override
  String get challengeCreateFieldEnds => '종료';

  @override
  String get challengeCreateInviteFriends => '친구 초대';

  @override
  String get challengePublicToggle => '공개';

  @override
  String get challengeCreateButton => '챌린지 만들기';

  @override
  String get rtpTitle => '복귀 프로그램';

  @override
  String get rtpDisclaimer => '셀프 가이드 프레임워크. 각 단계로 진행하기 전에 의료 제공자의 승인이 필요합니다.';

  @override
  String get rtpAdvancePhase => '마일스톤 달성';

  @override
  String get rtpGraduated => '졸업';

  @override
  String get morningRecoveryNudgeTitle => '오늘은 천천히 가세요';

  @override
  String get morningRecoveryNudgeBody =>
      '오늘 컨디션이 낮습니다. 볼륨을 줄입니다 — 재생성하려면 앱을 여세요.';
}
