import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/week_start_provider.dart';

import 'doc/card_doc.dart';
import 'shareable_data.dart';
import 'templates/achievement_hero_template.dart';
// --- Editable-card doc-builders (one per migrated template) ---
import 'templates/achievement_hero_doc.dart';
import 'templates/activity_overview_doc.dart';
// --- New editable-engine food formats ---
import 'templates/macro_receipt_doc.dart';
import 'templates/meal_trading_card_doc.dart';
import 'templates/wrapped_calorie_doc.dart';
import 'templates/plate_spotlight_doc.dart';
import 'templates/macro_donut_hero_doc.dart';
import 'templates/meal_boarding_pass_doc.dart';
import 'templates/this_or_that_doc.dart';
import 'templates/meal_newspaper_doc.dart';
import 'templates/macro_tier_list_doc.dart';
import 'templates/before_after_plate_doc.dart';
import 'templates/stat_strip_photo_doc.dart';
import 'templates/meal_streak_doc.dart';
import 'templates/recipe_card_doc.dart';
import 'templates/goal_progress_bars_doc.dart';
import 'templates/day_in_meals_doc.dart';
import 'templates/minimal_quote_meal_doc.dart';
import 'templates/meal_scoreboard_doc.dart';
import 'templates/meal_passport_doc.dart';
import 'templates/calorie_calendar_doc.dart';
import 'templates/meal_coupon_doc.dart';
import 'templates/meal_id_badge_doc.dart';
import 'templates/neon_meal_doc.dart';
import 'templates/mesh_big_number_doc.dart';
import 'templates/macro_split_block_doc.dart';
// --- Editable-engine food formats, wave 2 ---
import 'templates/candid_meal_doc.dart';
import 'templates/meal_timeline_doc.dart';
import 'templates/snack_plate_doc.dart';
import 'templates/meal_rating_doc.dart';
import 'templates/pov_meal_doc.dart';
import 'templates/protein_hero_doc.dart';
import 'templates/calorie_gauge_doc.dart';
import 'templates/macro_sparkline_doc.dart';
import 'templates/macro_compare_doc.dart';
import 'templates/macro_dashboard_doc.dart';
import 'templates/macro_export_doc.dart';
import 'templates/meal_meme_doc.dart';
import 'templates/meal_achievement_doc.dart';
import 'templates/meal_chat_doc.dart';
import 'templates/meal_review_doc.dart';
import 'templates/meal_tabloid_doc.dart';
import 'templates/candy_heart_doc.dart';
import 'templates/meal_flat_lay_doc.dart';
import 'templates/editorial_split_doc.dart';
import 'templates/swiss_grid_doc.dart';
import 'templates/duotone_poster_doc.dart';
import 'templates/soft_card_doc.dart';
import 'templates/diner_menu_doc.dart';
import 'templates/cassette_meal_doc.dart';
import 'templates/activity_rings_doc.dart';
import 'templates/boarding_pass_doc.dart';
import 'templates/calendar_heatmap_doc.dart';
import 'templates/chat_bubble_doc.dart';
import 'templates/coach_review_doc.dart';
import 'templates/daily_workout_card_doc.dart';
import 'templates/discord_doc.dart';
import 'templates/elite_doc.dart';
import 'templates/exercise_showcase_doc.dart';
import 'templates/food_collage_doc.dart';
import 'templates/food_magazine_doc.dart';
import 'templates/food_photo_macros_doc.dart';
import 'templates/food_polaroid_doc.dart';
import 'templates/food_receipt_doc.dart';
import 'templates/food_score_card_doc.dart';
import 'templates/instagram_story_doc.dart';
import 'templates/level_up_doc.dart';
import 'templates/macro_bars_card_doc.dart';
import 'templates/macro_numbers_card_doc.dart';
import 'templates/macro_pie_card_doc.dart';
import 'templates/macro_plate_card_doc.dart';
import 'templates/macro_rings_card_doc.dart';
import 'templates/macro_waffle_card_doc.dart';
import 'templates/magazine_cover_doc.dart';
import 'templates/minimal_doc.dart';
import 'templates/muscle_map_doc.dart';
import 'templates/news_doc.dart';
import 'templates/now_playing_doc.dart';
import 'templates/nutrition_facts_card_doc.dart';
import 'templates/one_rm_doc.dart';
import 'templates/passport_doc.dart';
import 'templates/photo_before_after_doc.dart';
import 'templates/photo_lockscreen_doc.dart';
import 'templates/photo_magazine_doc.dart';
import 'templates/photo_quote_doc.dart';
import 'templates/photo_split_doc.dart';
import 'templates/photo_stats_doc.dart';
import 'templates/polaroid_doc.dart';
import 'templates/pr_prediction_doc.dart';
import 'templates/prs_doc.dart';
import 'templates/quote_doc.dart';
import 'templates/receipt_doc.dart';
import 'templates/smart_insight_doc.dart';
import 'templates/stat_brag_doc.dart';
import 'templates/stat_grid_doc.dart';
import 'templates/streak_fire_doc.dart';
import 'templates/strength_radar_doc.dart';
import 'templates/trading_card_doc.dart';
import 'templates/trading_card_gold_doc.dart';
import 'templates/vinyl_doc.dart';
import 'templates/volume_bars_doc.dart';
import 'templates/weekly_report_doc.dart';
import 'templates/weight_graph_doc.dart';
import 'templates/what_i_ate_card_doc.dart';
import 'templates/widget_doc.dart';
import 'templates/workout_details_doc.dart';
import 'templates/workout_plan_doc.dart';
import 'templates/workout_muscle_card_doc.dart';
import 'templates/workout_program_doc.dart';
import 'templates/workout_score_doc.dart';
import 'templates/workout_summary_doc.dart';
import 'templates/wrapped_doc.dart';
import 'templates/activity_overview.dart';
import 'templates/activity_rings_template.dart';
import 'templates/boarding_pass_template.dart';
import 'templates/calendar_heatmap_template.dart';
import 'templates/chat_bubble_template.dart';
import 'templates/daily_workout_card_template.dart';
import 'templates/monthly_plan_grid_template.dart';
import 'templates/weekly_plan_grid_template.dart';
import 'templates/coach_review_template.dart';
import 'templates/elite_template.dart';
import 'templates/exercise_showcase_template.dart';
import 'templates/level_up_template.dart';
import 'templates/magazine_cover_template.dart';
import 'templates/minimal_template.dart';
import 'templates/muscle_map_template.dart';
import 'templates/news_template.dart';
import 'templates/now_playing_template.dart';
import 'templates/photo_before_after_template.dart';
import 'templates/photo_lockscreen_template.dart';
import 'templates/photo_magazine_template.dart';
import 'templates/photo_quote_template.dart';
import 'templates/photo_split_template.dart';
import 'templates/photo_stats_template.dart';
import 'templates/polaroid_template.dart';
import 'templates/pr_prediction_template.dart';
import 'templates/prs_template.dart';
import 'templates/quote_template.dart';
import 'templates/receipt_template.dart';
import 'templates/smart_insight_template.dart';
import 'templates/stat_brag_template.dart';
import 'templates/stat_grid_template.dart';
import 'templates/streak_fire_template.dart';
import 'templates/strength_radar_template.dart';
import 'templates/trading_card_template.dart';
import 'templates/volume_bars_template.dart';
import 'templates/weekly_report_template.dart';
import 'templates/weight_graph_template.dart';
import 'templates/widget_template.dart';
// New viral formats ported from the onboarding demo's share gallery.
import 'templates/discord_template.dart';
import 'templates/instagram_story_template.dart';
import 'templates/vinyl_template.dart';
import 'templates/passport_template.dart';
import 'templates/one_rm_template.dart';
import 'templates/trading_card_gold_template.dart';
import 'templates/workout_details_template.dart';
import 'templates/workout_muscle_card_template.dart';
import 'templates/workout_program_template.dart';
import 'templates/workout_score_template.dart';
import 'templates/workout_summary_template.dart';
import 'templates/wrapped_template.dart';
// --- Food / nutrition share templates ---
import 'templates/food_collage_template.dart';
import 'templates/food_magazine_template.dart';
import 'templates/food_photo_macros_template.dart';
import 'templates/food_polaroid_template.dart';
import 'templates/food_receipt_template.dart';
import 'templates/food_score_card_template.dart';
import 'templates/macro_bars_card_template.dart';
import 'templates/macro_numbers_card_template.dart';
import 'templates/macro_pie_card_template.dart';
import 'templates/macro_plate_card_template.dart';
import 'templates/macro_rings_card_template.dart';
import 'templates/macro_waffle_card_template.dart';
import 'templates/nutrition_facts_card_template.dart';
import 'templates/what_i_ate_card_template.dart';
// --- 117 newly-authored share templates (social / ai / collectible / ios / ticket / meaningful / data) ---
// --- Social share templates ---
import 'templates/social_bereal_dual_doc.dart';
import 'templates/social_calendar_invite_doc.dart';
import 'templates/social_chat_convo_doc.dart';
import 'templates/social_comment_thread_doc.dart';
import 'templates/social_dm_doc.dart';
import 'templates/social_fb_memory_doc.dart';
import 'templates/social_group_chat_doc.dart';
import 'templates/social_ig_carousel_doc.dart';
import 'templates/social_ig_post_doc.dart';
import 'templates/social_ig_reel_cover_doc.dart';
import 'templates/social_ig_story_poll_doc.dart';
import 'templates/social_linkedin_post_doc.dart';
import 'templates/social_pinterest_pin_doc.dart';
import 'templates/social_quote_tweet_doc.dart';
import 'templates/social_reddit_post_doc.dart';
import 'templates/social_snap_streak_doc.dart';
import 'templates/social_threads_doc.dart';
import 'templates/social_tiktok_post_doc.dart';
import 'templates/social_venmo_payment_doc.dart';
import 'templates/social_youtube_shorts_doc.dart';
import 'templates/social_youtube_thumb_doc.dart';
// --- AI share templates ---
import 'templates/ai_agent_log_doc.dart';
import 'templates/ai_avatar_doc.dart';
import 'templates/ai_calorie_scan_doc.dart';
import 'templates/ai_caption_doc.dart';
import 'templates/ai_coach_chat_doc.dart';
import 'templates/ai_confidence_doc.dart';
import 'templates/ai_diffusion_params_doc.dart';
import 'templates/ai_grid_doc.dart';
import 'templates/ai_imagined_doc.dart';
import 'templates/ai_model_card_doc.dart';
import 'templates/ai_neural_analysis_doc.dart';
import 'templates/ai_next_workout_doc.dart';
import 'templates/ai_pose_check_doc.dart';
import 'templates/ai_prompt_plan_doc.dart';
import 'templates/ai_rep_counter_doc.dart';
import 'templates/ai_roast_doc.dart';
import 'templates/ai_strength_curve_doc.dart';
import 'templates/ai_summary_doc.dart';
import 'templates/ai_vibe_check_doc.dart';
import 'templates/ai_voice_orb_doc.dart';
import 'templates/ai_wrapped_doc.dart';
// --- Collectible share templates ---
import 'templates/collectible_banknote_doc.dart';
import 'templates/collectible_battle_card_doc.dart';
import 'templates/collectible_casino_chip_doc.dart';
import 'templates/collectible_certificate_doc.dart';
import 'templates/collectible_dog_tag_doc.dart';
import 'templates/collectible_fortune_doc.dart';
import 'templates/collectible_gift_card_doc.dart';
import 'templates/collectible_holo_card_doc.dart';
import 'templates/collectible_license_plate_doc.dart';
import 'templates/collectible_loyalty_card_doc.dart';
import 'templates/collectible_medal_doc.dart';
import 'templates/collectible_nft_card_doc.dart';
import 'templates/collectible_race_bib_doc.dart';
import 'templates/collectible_scratch_ticket_doc.dart';
import 'templates/collectible_trophy_shelf_doc.dart';
import 'templates/collectible_watch_face_doc.dart';
import 'templates/collectible_wristband_doc.dart';
// --- iOS share templates ---
import 'templates/ios_activity_rings_doc.dart';
import 'templates/ios_billboard_doc.dart';
import 'templates/ios_comic_panel_doc.dart';
import 'templates/ios_departure_board_doc.dart';
import 'templates/ios_dynamic_island_doc.dart';
import 'templates/ios_glass_widget_doc.dart';
import 'templates/ios_lock_screen_doc.dart';
import 'templates/ios_magazine_cover_doc.dart';
import 'templates/ios_mesh_gradient_doc.dart';
import 'templates/ios_movie_poster_doc.dart';
import 'templates/ios_museum_label_doc.dart';
import 'templates/ios_neon_sign_doc.dart';
import 'templates/ios_notification_stack_doc.dart';
import 'templates/ios_periodic_element_doc.dart';
import 'templates/ios_vinyl_record_doc.dart';
import 'templates/ios_weather_widget_doc.dart';
// --- Ticket share templates ---
import 'templates/ticket_boarding_pass_doc.dart';
import 'templates/ticket_cinema_doc.dart';
import 'templates/ticket_coupon_doc.dart';
import 'templates/ticket_event_doc.dart';
import 'templates/ticket_gym_receipt_doc.dart';
import 'templates/ticket_lanyard_doc.dart';
import 'templates/ticket_parking_doc.dart';
import 'templates/ticket_passport_doc.dart';
import 'templates/ticket_raffle_doc.dart';
import 'templates/ticket_scratch_doc.dart';
import 'templates/ticket_wristband_doc.dart';
// --- Meaningful share templates ---
import 'templates/meaningful_before_after_doc.dart';
import 'templates/meaningful_comeback_doc.dart';
import 'templates/meaningful_dear_past_me_doc.dart';
import 'templates/meaningful_grind_doc.dart';
import 'templates/meaningful_hundred_workouts_doc.dart';
import 'templates/meaningful_identity_doc.dart';
import 'templates/meaningful_journey_doc.dart';
import 'templates/meaningful_letter_doc.dart';
import 'templates/meaningful_milestone_doc.dart';
import 'templates/meaningful_one_year_doc.dart';
import 'templates/meaningful_quiet_wins_doc.dart';
import 'templates/meaningful_showed_up_doc.dart';
import 'templates/meaningful_transformation_timeline_doc.dart';
import 'templates/meaningful_why_i_train_doc.dart';
// --- Data share templates ---
import 'templates/data_box_score_doc.dart';
import 'templates/data_bracket_doc.dart';
import 'templates/data_captcha_doc.dart';
import 'templates/data_error_404_doc.dart';
import 'templates/data_infographic_doc.dart';
import 'templates/data_leaderboard_doc.dart';
import 'templates/data_magic_8ball_doc.dart';
import 'templates/data_odometer_doc.dart';
import 'templates/data_pie_breakdown_doc.dart';
import 'templates/data_recovery_ring_doc.dart';
import 'templates/data_rx_label_doc.dart';
import 'templates/data_scoreboard_doc.dart';
import 'templates/data_stock_chart_doc.dart';
import 'templates/data_strength_radar_doc.dart';
import 'templates/data_tier_list_doc.dart';
import 'templates/data_volume_bars_doc.dart';
import 'templates/data_volume_line_doc.dart';

/// Every template the unified sheet can render. Order here is also the
/// default render order in the gallery.
enum ShareableTemplate {
  activityOverview,
  minimal,
  wrapped,
  news,
  receipt,
  tradingCard,
  statGrid,
  streakFire,
  prs,
  weeklyReport,
  levelUp,
  elite,
  workoutDetails,
  workoutPlan,
  workoutMuscleCard,
  workoutProgram,
  workoutSummary,
  dailyWorkoutCard,
  weeklyPlanGrid,
  monthlyPlanGrid,
  // --- New viral formats ---
  magazineCover,
  widget,
  achievementHero,
  calendarHeatmap,
  activityRings,
  polaroid,
  quote,
  chatBubble,
  statBrag,
  exerciseShowcase,
  boardingPass,
  nowPlaying,
  // --- Spark (intelligence-driven, icon-only pill) ---
  coachReview,
  smartInsight,
  prPrediction,
  workoutScore,
  muscleMap,
  // --- Graph (chart-heavy templates) ---
  weightGraph,
  volumeBars,
  strengthRadar,
  // --- Studio (custom user upload — photo-driven, icon-only pill) ---
  photoStats,
  photoQuote,
  photoBeforeAfter,
  photoSplit,
  photoMagazine,
  photoLockscreen,
  // --- Onboarding-demo ports (viral formats) ---
  discord,
  instagramStory,
  vinyl,
  passport,
  oneRm,
  tradingCardGold,
  // --- Food / nutrition (ShareableKind.foodLog) ---
  foodPhotoMacros,
  foodPolaroid,
  foodMagazine,
  foodCollage,
  macroRingsCard,
  macroNumbersCard,
  macroPieCard,
  macroPlateCard,
  whatIAteCard,
  macroWaffleCard,
  macroBarsCard,
  nutritionFactsCard,
  foodReceipt,
  foodScoreCard,
  // --- New editable-engine food formats ---
  macroReceipt,
  mealTradingCard,
  wrappedCalorie,
  plateSpotlight,
  macroDonutHero,
  mealBoardingPass,
  thisOrThat,
  mealNewspaper,
  macroTierList,
  beforeAfterPlate,
  statStripPhoto,
  mealStreak,
  recipeCard,
  goalProgressBars,
  dayInMeals,
  minimalQuoteMeal,
  mealScoreboard,
  mealPassport,
  calorieCalendar,
  mealCoupon,
  mealIdBadge,
  neonMeal,
  meshBigNumber,
  macroSplitBlock,
  // --- Editable-engine food formats, wave 2 ---
  candidMeal,
  mealTimeline,
  snackPlate,
  mealRating,
  povMeal,
  proteinHero,
  calorieGauge,
  macroSparkline,
  macroCompare,
  macroDashboard,
  macroExport,
  mealMeme,
  mealAchievement,
  mealChat,
  mealReview,
  mealTabloid,
  candyHeart,
  mealFlatLay,
  editorialSplit,
  swissGrid,
  duotonePoster,
  softCard,
  dinerMenu,
  cassetteMeal,
  // --- Social (21) ---
  socialBerealDual,
  socialCalendarInvite,
  socialChatConvo,
  socialCommentThread,
  socialDm,
  socialFbMemory,
  socialGroupChat,
  socialIgCarousel,
  socialIgPost,
  socialIgReelCover,
  socialIgStoryPoll,
  socialLinkedinPost,
  socialPinterestPin,
  socialQuoteTweet,
  socialRedditPost,
  socialSnapStreak,
  socialThreads,
  socialTiktokPost,
  socialVenmoPayment,
  socialYoutubeShorts,
  socialYoutubeThumb,
  // --- AI (21) ---
  aiAgentLog,
  aiAvatar,
  aiCalorieScan,
  aiCaption,
  aiCoachChat,
  aiConfidence,
  aiDiffusionParams,
  aiGrid,
  aiImagined,
  aiModelCard,
  aiNeuralAnalysis,
  aiNextWorkout,
  aiPoseCheck,
  aiPromptPlan,
  aiRepCounter,
  aiRoast,
  aiStrengthCurve,
  aiSummary,
  aiVibeCheck,
  aiVoiceOrb,
  aiWrapped,
  // --- Collectible (17) ---
  collectibleBanknote,
  collectibleBattleCard,
  collectibleCasinoChip,
  collectibleCertificate,
  collectibleDogTag,
  collectibleFortune,
  collectibleGiftCard,
  collectibleHoloCard,
  collectibleLicensePlate,
  collectibleLoyaltyCard,
  collectibleMedal,
  collectibleNftCard,
  collectibleRaceBib,
  collectibleScratchTicket,
  collectibleTrophyShelf,
  collectibleWatchFace,
  collectibleWristband,
  // --- iOS (16) ---
  iosActivityRings,
  iosBillboard,
  iosComicPanel,
  iosDepartureBoard,
  iosDynamicIsland,
  iosGlassWidget,
  iosLockScreen,
  iosMagazineCover,
  iosMeshGradient,
  iosMoviePoster,
  iosMuseumLabel,
  iosNeonSign,
  iosNotificationStack,
  iosPeriodicElement,
  iosVinylRecord,
  iosWeatherWidget,
  // --- Ticket (11) ---
  ticketBoardingPass,
  ticketCinema,
  ticketCoupon,
  ticketEvent,
  ticketGymReceipt,
  ticketLanyard,
  ticketParking,
  ticketPassport,
  ticketRaffle,
  ticketScratch,
  ticketWristband,
  // --- Meaningful (14) ---
  meaningfulBeforeAfter,
  meaningfulComeback,
  meaningfulDearPastMe,
  meaningfulGrind,
  meaningfulHundredWorkouts,
  meaningfulIdentity,
  meaningfulJourney,
  meaningfulLetter,
  meaningfulMilestone,
  meaningfulOneYear,
  meaningfulQuietWins,
  meaningfulShowedUp,
  meaningfulTransformationTimeline,
  meaningfulWhyITrain,
  // --- Data (17) ---
  dataBoxScore,
  dataBracket,
  dataCaptcha,
  dataError404,
  dataInfographic,
  dataLeaderboard,
  dataMagic8ball,
  dataOdometer,
  dataPieBreakdown,
  dataRecoveryRing,
  dataRxLabel,
  dataScoreboard,
  dataStockChart,
  dataStrengthRadar,
  dataTierList,
  dataVolumeBars,
  dataVolumeLine,
}

/// User-facing grouping (Tier 3 in the nested pill selector).
///
/// Layout target: 4 text pills + 2 icon-only pills fit on a typical phone
/// without horizontal scrolling. To preserve that:
///   - `cards` (was `classic` + `rich` merged) — single text pill for all
///     non-photo, non-chart, non-editorial templates.
///   - `editorial`, `playful`, `graph` — text pills.
///   - `spark` — pure-icon pill (sparkle glyph).
///   - `studio` — pure-icon pill (camera glyph) for photo-driven uploads.
///
/// `rich` is kept in the enum for backwards compatibility (older spec
/// entries still reference it) — it's treated as an alias of `cards` in
/// the UI so it renders into the same pill, never showing "Rich" as a
/// separate option.
enum ShareableCategory { classic, rich, editorial, playful, graph, spark, studio }

extension ShareableCategoryMeta on ShareableCategory {
  /// The pill we surface this category under in the UI. `rich` aliases to
  /// `classic` so the merged "Cards" pill picks up old spec entries
  /// without us having to mass-edit the registry.
  ShareableCategory get effective =>
      this == ShareableCategory.rich ? ShareableCategory.classic : this;

  String get label {
    switch (this) {
      case ShareableCategory.classic:
      case ShareableCategory.rich:
        return 'Cards';
      case ShareableCategory.editorial:
        return 'Editorial';
      case ShareableCategory.playful:
        return 'Playful';
      case ShareableCategory.graph:
        return 'Graph';
      case ShareableCategory.spark:
        return 'Spark';
      case ShareableCategory.studio:
        return 'Studio';
    }
  }

  /// Leading icon for the pill. Spark + Studio render icon-only (see
  /// [iconOnly]) so the glyph carries the meaning. Other categories
  /// return null and use text labels.
  IconData? get icon {
    switch (this) {
      case ShareableCategory.spark:
        return Icons.auto_awesome;
      case ShareableCategory.studio:
        return Icons.camera_alt_outlined;
      case ShareableCategory.graph:
        return Icons.show_chart_rounded;
      default:
        return null;
    }
  }

  /// True for categories that render as a pure-icon pill (no label text).
  /// Spark + Studio use this — the sparkle / camera glyph signals the
  /// category without consuming horizontal space, so the four text pills
  /// (Cards / Editorial / Playful / Graph) plus these two icon pills all
  /// fit on a single row without scrolling.
  bool get iconOnly =>
      this == ShareableCategory.spark || this == ShareableCategory.studio;
}

typedef ShareableTemplateBuilder = Widget Function(
  Shareable data,
  bool showWatermark,
);

/// Builds the editable [CardDoc] preset for a template. A spec that supplies
/// one is "editable" — the share sheet renders it via `CardDocRenderer` and
/// the Customize editor can edit every element. Until a template is migrated
/// its `docBuilder` is null and the legacy [ShareableTemplateBuilder] is used.
typedef CardDocBuilder = CardDoc Function(
  Shareable data,
  ShareableAspect aspect,
);

class ShareableTemplateSpec {
  final ShareableTemplate template;
  final String name;
  final ShareableCategory category;
  final Set<ShareableKind> kinds;
  final int minHighlights;
  final Set<ShareableAspect> aspects;
  final bool requiresExercises;
  final bool requiresStreak;
  final bool requiresWeeklyVector;

  /// True when this template renders [Shareable.planDays] (the week / month
  /// grids). The catalog declines to offer it when `planDays` is null or
  /// every day in it is a rest day — so an empty plan never shows a blank grid.
  final bool requiresPlanDays;

  final bool cosmeticGated;

  /// Minimum number of `foodImageUrls` the payload must carry for this
  /// template to be offered — photo food templates set this so a barcode /
  /// text log (no photo) never shows a blank-photo card. 0 = no requirement.
  final int requiresPhotoCount;

  /// Legacy widget builder. Null for templates authored directly on the
  /// editable-card engine (which only need [docBuilder]).
  final ShareableTemplateBuilder? builder;

  /// Editable-document builder. Every template has one; it is the render
  /// path for the preview, gallery, editor and capture.
  final CardDocBuilder? docBuilder;

  const ShareableTemplateSpec({
    required this.template,
    required this.name,
    required this.category,
    required this.kinds,
    this.builder,
    this.docBuilder,
    this.minHighlights = 0,
    this.aspects = const {
      ShareableAspect.story,
      ShareableAspect.portrait,
      ShareableAspect.square,
    },
    this.requiresExercises = false,
    this.requiresStreak = false,
    this.requiresWeeklyVector = false,
    this.requiresPlanDays = false,
    this.cosmeticGated = false,
    this.requiresPhotoCount = 0,
  });

  /// True when this template has been migrated to the editable-card engine.
  bool get isEditable => docBuilder != null;

  bool isAvailableFor(Shareable data, {bool ownsCosmetic = false}) {
    if (cosmeticGated && !ownsCosmetic) return false;
    // Food shares are a closed gallery — only templates that explicitly
    // list `foodLog` (the 14 food templates) qualify. Without this branch
    // the `statsOverview`-wildcard below would leak every generic
    // workout-shaped template into the food gallery.
    if (data.kind == ShareableKind.foodLog) {
      if (!kinds.contains(ShareableKind.foodLog)) return false;
    } else if (!kinds.contains(data.kind) &&
        !kinds.contains(ShareableKind.statsOverview)) {
      // Templates whose kinds set lists explicit allowlist must match,
      // unless the catalog entry uses an "all kinds" wildcard via
      // listing every value (handled in the registry below).
      if (!kinds.contains(data.kind)) return false;
    }
    if (!aspects.contains(data.aspect)) return false;
    final populated =
        data.highlights.where((h) => h.isPopulated).length;
    if (populated < minHighlights) return false;
    if (requiresExercises) {
      final ex = data.exercises;
      if (ex == null || ex.isEmpty) return false;
      final anyLogged = ex.any((e) => e.sets.isNotEmpty);
      if (!anyLogged) return false;
    }
    if (requiresStreak) {
      final hasStreak = data.highlights.any(
        (h) => h.label.toUpperCase().contains('STREAK'),
      );
      if (!hasStreak) return false;
    }
    if (requiresWeeklyVector) {
      final hasWeekly = data.subMetrics.length >= 7;
      if (!hasWeekly) return false;
    }
    if (requiresPlanDays) {
      final days = data.planDays;
      if (days == null || days.isEmpty) return false;
      // Decline an all-rest plan — there's no workout to put in the grid.
      if (days.every((d) => d.isRestDay)) return false;
    }
    if (requiresPhotoCount > 0) {
      final photos = data.foodImageUrls?.length ?? 0;
      if (photos < requiresPhotoCount) return false;
    }
    return true;
  }
}

/// Set containing every kind — used by templates that work everywhere
/// (Activity Overview, Minimal, Wrapped, News, Receipt, Stat Grid).
const Set<ShareableKind> _allKinds = {
  ShareableKind.periodInsights,
  ShareableKind.personalRecords,
  ShareableKind.muscleAnalytics,
  ShareableKind.oneRm,
  ShareableKind.exerciseHistory,
  ShareableKind.milestones,
  ShareableKind.progressCharts,
  ShareableKind.bodyMeasurements,
  ShareableKind.nutrition,
  ShareableKind.achievements,
  ShareableKind.statsOverview,
  ShareableKind.weeklyProgress,
  ShareableKind.streak,
  ShareableKind.workoutComplete,
  ShareableKind.wrapped,
  ShareableKind.insights,
  ShareableKind.weeklySummary,
  ShareableKind.strength,
  ShareableKind.weeklyPlan,
  ShareableKind.monthlyPlan,
};

/// Single source of truth for the template registry. Phase 2 will fill in
/// the actual `builder` widgets — for now, the registry is shape-only so
/// the sheet + pill selector can compile.
class ShareableCatalog {
  static List<ShareableTemplateSpec>? _entries;

  static List<ShareableTemplateSpec> all() {
    return _entries ??= _build();
  }

  static List<ShareableTemplateSpec> _build() {
    return [
      ShareableTemplateSpec(
        template: ShareableTemplate.activityOverview,
        name: 'Overview',
        category: ShareableCategory.classic,
        kinds: _allKinds,
        minHighlights: 3,
        builder: (d, w) => ActivityOverviewTemplate(data: d, showWatermark: w),
        docBuilder: activityOverviewDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.minimal,
        name: 'Minimal',
        category: ShareableCategory.classic,
        kinds: _allKinds,
        builder: (d, w) => MinimalTemplate(data: d, showWatermark: w),
        docBuilder: minimalDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.wrapped,
        name: 'Wrapped',
        category: ShareableCategory.editorial,
        kinds: _allKinds,
        minHighlights: 3,
        builder: (d, w) => WrappedTemplate(data: d, showWatermark: w),
        docBuilder: wrappedDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.news,
        name: 'News',
        category: ShareableCategory.editorial,
        kinds: _allKinds,
        minHighlights: 2,
        builder: (d, w) => NewsTemplate(data: d, showWatermark: w),
        docBuilder: newsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.receipt,
        name: 'Receipt',
        category: ShareableCategory.rich,
        kinds: _allKinds,
        minHighlights: 3,
        builder: (d, w) => ReceiptTemplate(data: d, showWatermark: w),
        docBuilder: receiptDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.tradingCard,
        name: 'Card',
        category: ShareableCategory.rich,
        kinds: const {
          ShareableKind.personalRecords,
          ShareableKind.milestones,
          ShareableKind.achievements,
          ShareableKind.statsOverview,
          ShareableKind.workoutComplete,
        },
        minHighlights: 2,
        builder: (d, w) => TradingCardTemplate(data: d, showWatermark: w),
        docBuilder: tradingCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.statGrid,
        name: 'Grid',
        category: ShareableCategory.rich,
        kinds: _allKinds,
        minHighlights: 4,
        builder: (d, w) => StatGridTemplate(data: d, showWatermark: w),
        docBuilder: statGridDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.streakFire,
        name: 'Streak',
        category: ShareableCategory.playful,
        kinds: const {
          ShareableKind.streak,
          ShareableKind.statsOverview,
          ShareableKind.periodInsights,
        },
        requiresStreak: true,
        builder: (d, w) => StreakFireTemplate(data: d, showWatermark: w),
        docBuilder: streakFireDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.prs,
        name: 'PRs',
        category: ShareableCategory.playful,
        kinds: const {
          ShareableKind.personalRecords,
          ShareableKind.workoutComplete,
        },
        minHighlights: 1,
        builder: (d, w) => PRsTemplate(data: d, showWatermark: w),
        docBuilder: prsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.weeklyReport,
        name: 'Weekly Bars',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.weeklyProgress,
          ShareableKind.weeklySummary,
          ShareableKind.periodInsights,
        },
        requiresWeeklyVector: true,
        builder: (d, w) => WeeklyReportTemplate(data: d, showWatermark: w),
        docBuilder: weeklyReportDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.levelUp,
        name: 'Level Up',
        category: ShareableCategory.playful,
        kinds: const {
          ShareableKind.milestones,
          ShareableKind.achievements,
        },
        builder: (d, w) => LevelUpTemplate(data: d, showWatermark: w),
        docBuilder: levelUpDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.elite,
        name: 'Elite',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview},
        minHighlights: 3,
        cosmeticGated: true,
        builder: (d, w) => EliteTemplate(data: d, showWatermark: w),
        docBuilder: eliteDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.workoutDetails,
        name: 'Workout',
        category: ShareableCategory.rich,
        kinds: const {ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        requiresExercises: true,
        builder: (d, w) => WorkoutDetailsTemplate(data: d, showWatermark: w),
        docBuilder: workoutDetailsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.workoutPlan,
        name: 'Plan',
        category: ShareableCategory.rich,
        kinds: const {ShareableKind.workoutComplete},
        aspects: const {
          ShareableAspect.story,
          ShareableAspect.portrait,
          ShareableAspect.square,
        },
        requiresExercises: true,
        docBuilder: workoutPlanDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.workoutMuscleCard,
        name: 'Muscles',
        category: ShareableCategory.rich,
        kinds: const {ShareableKind.workoutComplete},
        requiresExercises: true,
        builder: (d, w) =>
            WorkoutMuscleCardTemplate(data: d, showWatermark: w),
        docBuilder: workoutMuscleCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.workoutProgram,
        name: 'Program',
        category: ShareableCategory.rich,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.wrapped},
        aspects: const {ShareableAspect.story},
        requiresExercises: true,
        builder: (d, w) => WorkoutProgramTemplate(data: d, showWatermark: w),
        docBuilder: workoutProgramDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.workoutSummary,
        name: 'Watch Summary',
        category: ShareableCategory.rich,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.statsOverview,
        },
        minHighlights: 2,
        builder: (d, w) =>
            WorkoutSummaryTemplate(data: d, showWatermark: w),
        docBuilder: workoutSummaryDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dailyWorkoutCard,
        name: 'Day',
        category: ShareableCategory.rich,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.weeklyPlan,
          ShareableKind.monthlyPlan,
        },
        builder: (d, w) =>
            DailyWorkoutCardTemplate(data: d, showWatermark: w),
        docBuilder: dailyWorkoutCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.weeklyPlanGrid,
        name: 'Week Grid',
        category: ShareableCategory.rich,
        kinds: const {ShareableKind.weeklyPlan, ShareableKind.weeklySummary},
        minHighlights: 2,
        requiresPlanDays: true,
        builder: (d, w) =>
            WeeklyPlanGridTemplate(data: d, showWatermark: w),
        // docBuilder intentionally null: the card-doc engine has no planDays
        // binding, so its placeholder grid would ship an empty share image.
        // TemplateView falls back to the rich WeeklyPlanGridTemplate widget
        // (which binds real planDays + thumbnails + sets/reps). isEditable=false
        // is correct here — a plan grid can't be represented in the doc editor.
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.monthlyPlanGrid,
        name: 'Month Grid',
        category: ShareableCategory.rich,
        kinds: const {
          ShareableKind.monthlyPlan,
          ShareableKind.wrapped,
        },
        minHighlights: 2,
        requiresPlanDays: true,
        builder: (d, w) =>
            MonthlyPlanGridTemplate(data: d, showWatermark: w),
        // docBuilder intentionally null (see weeklyPlanGrid above): render the
        // rich MonthlyPlanGridTemplate widget with real planDays, not the
        // placeholder doc grid.
      ),
      // ─────────── New viral formats ───────────
      ShareableTemplateSpec(
        template: ShareableTemplate.magazineCover,
        name: 'Cover',
        category: ShareableCategory.editorial,
        kinds: _allKinds,
        builder: (d, w) => MagazineCoverTemplate(data: d, showWatermark: w),
        docBuilder: magazineCoverDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.widget,
        name: 'Widget',
        category: ShareableCategory.classic,
        kinds: _allKinds,
        builder: (d, w) => WidgetTemplate(data: d, showWatermark: w),
        docBuilder: widgetDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.achievementHero,
        name: 'Trophy',
        category: ShareableCategory.playful,
        kinds: const {
          ShareableKind.achievements,
          ShareableKind.milestones,
          ShareableKind.statsOverview,
        },
        builder: (d, w) =>
            AchievementHeroTemplate(data: d, showWatermark: w),
        docBuilder: achievementHeroDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.calendarHeatmap,
        name: 'Heatmap',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.weeklyProgress,
          ShareableKind.streak,
          ShareableKind.statsOverview,
          ShareableKind.wrapped,
          ShareableKind.periodInsights,
        },
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        builder: (d, w) => Consumer(
          builder: (_, ref, __) => CalendarHeatmapTemplate(
            data: d,
            showWatermark: w,
            weekStartsSunday: ref.watch(weekStartsSundayProvider),
          ),
        ),
        docBuilder: calendarHeatmapDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.activityRings,
        name: 'Rings',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.weeklyProgress,
          ShareableKind.statsOverview,
          ShareableKind.streak,
          ShareableKind.workoutComplete,
        },
        builder: (d, w) =>
            ActivityRingsTemplate(data: d, showWatermark: w),
        docBuilder: activityRingsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.polaroid,
        name: 'Polaroid',
        category: ShareableCategory.playful,
        kinds: _allKinds,
        builder: (d, w) => PolaroidTemplate(data: d, showWatermark: w),
        docBuilder: polaroidDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.quote,
        name: 'Quote',
        category: ShareableCategory.editorial,
        kinds: _allKinds,
        builder: (d, w) => QuoteTemplate(data: d, showWatermark: w),
        docBuilder: quoteDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.chatBubble,
        name: 'iMessage',
        category: ShareableCategory.playful,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.personalRecords,
          ShareableKind.milestones,
        },
        builder: (d, w) => ChatBubbleTemplate(data: d, showWatermark: w),
        docBuilder: chatBubbleDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.statBrag,
        name: 'Brag',
        category: ShareableCategory.classic,
        kinds: _allKinds,
        builder: (d, w) => StatBragTemplate(data: d, showWatermark: w),
        docBuilder: statBragDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.exerciseShowcase,
        name: 'Showcase',
        category: ShareableCategory.rich,
        kinds: const {ShareableKind.workoutComplete},
        requiresExercises: true,
        builder: (d, w) =>
            ExerciseShowcaseTemplate(data: d, showWatermark: w),
        docBuilder: exerciseShowcaseDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.boardingPass,
        name: 'Boarding',
        category: ShareableCategory.editorial,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.milestones,
          ShareableKind.weeklyProgress,
          ShareableKind.statsOverview,
        },
        builder: (d, w) => BoardingPassTemplate(data: d, showWatermark: w),
        docBuilder: boardingPassDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.nowPlaying,
        name: 'Playing',
        category: ShareableCategory.classic,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.statsOverview,
          ShareableKind.personalRecords,
        },
        builder: (d, w) => NowPlayingTemplate(data: d, showWatermark: w),
        docBuilder: nowPlayingDoc,
      ),
      // ─────────── Spark (intelligence-driven) ───────────
      ShareableTemplateSpec(
        template: ShareableTemplate.coachReview,
        name: 'Coach Review',
        category: ShareableCategory.spark,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.weeklyProgress,
          ShareableKind.statsOverview,
        },
        builder: (d, w) => CoachReviewTemplate(data: d, showWatermark: w),
        docBuilder: coachReviewDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.smartInsight,
        name: 'Insight',
        category: ShareableCategory.graph,
        kinds: _allKinds,
        builder: (d, w) => SmartInsightTemplate(data: d, showWatermark: w),
        docBuilder: smartInsightDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.prPrediction,
        name: 'Projection',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.personalRecords,
          ShareableKind.statsOverview,
          ShareableKind.strength,
        },
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        builder: (d, w) => PRPredictionTemplate(data: d, showWatermark: w),
        docBuilder: prPredictionDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.workoutScore,
        name: 'Score',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.weeklyProgress,
          ShareableKind.statsOverview,
          ShareableKind.streak,
          ShareableKind.workoutComplete,
        },
        builder: (d, w) => WorkoutScoreTemplate(data: d, showWatermark: w),
        docBuilder: workoutScoreDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.muscleMap,
        name: 'Muscle Map',
        category: ShareableCategory.spark,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.muscleAnalytics,
          ShareableKind.weeklyProgress,
          ShareableKind.statsOverview,
          ShareableKind.weeklySummary,
        },
        builder: (d, w) => MuscleMapTemplate(data: d, showWatermark: w),
        docBuilder: muscleMapDoc,
      ),
      // ─────────── Graph (chart-heavy) ───────────
      ShareableTemplateSpec(
        template: ShareableTemplate.weightGraph,
        name: 'Weight Trend',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.bodyMeasurements,
          ShareableKind.progressCharts,
          ShareableKind.statsOverview,
          ShareableKind.personalRecords,
          ShareableKind.strength,
          ShareableKind.oneRm,
          ShareableKind.weeklyProgress,
        },
        builder: (d, w) => WeightGraphTemplate(data: d, showWatermark: w),
        docBuilder: weightGraphDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.volumeBars,
        name: 'Volume Bars',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.weeklyProgress,
          ShareableKind.weeklySummary,
          ShareableKind.statsOverview,
          ShareableKind.periodInsights,
          ShareableKind.workoutComplete,
        },
        builder: (d, w) => VolumeBarsTemplate(data: d, showWatermark: w),
        docBuilder: volumeBarsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.strengthRadar,
        name: 'Radar',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.muscleAnalytics,
          ShareableKind.statsOverview,
          ShareableKind.strength,
          ShareableKind.weeklySummary,
          ShareableKind.workoutComplete,
        },
        builder: (d, w) => StrengthRadarTemplate(data: d, showWatermark: w),
        docBuilder: strengthRadarDoc,
      ),
      // ─────────── Studio (custom user upload — photo-driven) ───────────
      ShareableTemplateSpec(
        template: ShareableTemplate.photoStats,
        name: 'Stat Overlay',
        category: ShareableCategory.studio,
        kinds: _allKinds,
        builder: (d, w) => PhotoStatsTemplate(data: d, showWatermark: w),
        docBuilder: photoStatsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.photoQuote,
        name: 'Quote Overlay',
        category: ShareableCategory.studio,
        kinds: _allKinds,
        builder: (d, w) => PhotoQuoteTemplate(data: d, showWatermark: w),
        docBuilder: photoQuoteDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.photoBeforeAfter,
        name: 'Before / After',
        category: ShareableCategory.studio,
        kinds: const {
          ShareableKind.bodyMeasurements,
          ShareableKind.weeklyProgress,
          ShareableKind.milestones,
          ShareableKind.statsOverview,
          ShareableKind.progressCharts,
        },
        builder: (d, w) =>
            PhotoBeforeAfterTemplate(data: d, showWatermark: w),
        docBuilder: photoBeforeAfterDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.photoSplit,
        name: 'Split',
        category: ShareableCategory.studio,
        kinds: _allKinds,
        builder: (d, w) => PhotoSplitTemplate(data: d, showWatermark: w),
        docBuilder: photoSplitDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.photoMagazine,
        name: 'Cover Story',
        category: ShareableCategory.studio,
        kinds: _allKinds,
        builder: (d, w) =>
            PhotoMagazineTemplate(data: d, showWatermark: w),
        docBuilder: photoMagazineDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.photoLockscreen,
        name: 'Lockscreen',
        category: ShareableCategory.studio,
        kinds: _allKinds,
        builder: (d, w) =>
            PhotoLockscreenTemplate(data: d, showWatermark: w),
        docBuilder: photoLockscreenDoc,
      ),
      // ── Onboarding-demo ports — six viral formats sourced from the
      // pre-signup share gallery in `workout_showcase_screen.dart`.
      ShareableTemplateSpec(
        template: ShareableTemplate.discord,
        name: 'Discord',
        category: ShareableCategory.editorial,
        kinds: _allKinds,
        minHighlights: 2,
        builder: (d, w) => DiscordTemplate(data: d, showWatermark: w),
        docBuilder: discordDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.instagramStory,
        name: 'IG Story',
        category: ShareableCategory.playful,
        kinds: _allKinds,
        builder: (d, w) =>
            InstagramStoryTemplate(data: d, showWatermark: w),
        docBuilder: instagramStoryDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.vinyl,
        name: 'Vinyl',
        category: ShareableCategory.playful,
        kinds: _allKinds,
        builder: (d, w) => VinylTemplate(data: d, showWatermark: w),
        docBuilder: vinylDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.passport,
        name: 'Passport',
        category: ShareableCategory.editorial,
        kinds: _allKinds,
        minHighlights: 1,
        builder: (d, w) => PassportTemplate(data: d, showWatermark: w),
        docBuilder: passportDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.oneRm,
        name: '1RM',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.personalRecords,
          ShareableKind.statsOverview,
          ShareableKind.workoutComplete,
        },
        minHighlights: 1,
        builder: (d, w) => OneRmTemplate(data: d, showWatermark: w),
        docBuilder: oneRmDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.tradingCardGold,
        name: 'Gold Card',
        category: ShareableCategory.playful,
        kinds: const {
          ShareableKind.personalRecords,
          ShareableKind.milestones,
          ShareableKind.achievements,
          ShareableKind.statsOverview,
          ShareableKind.workoutComplete,
        },
        minHighlights: 2,
        builder: (d, w) =>
            TradingCardGoldTemplate(data: d, showWatermark: w),
        docBuilder: tradingCardGoldDoc,
      ),
      // ─────────── Food / nutrition (ShareableKind.foodLog) ───────────
      ShareableTemplateSpec(
        template: ShareableTemplate.foodPhotoMacros,
        name: 'Photo',
        category: ShareableCategory.studio,
        kinds: const {ShareableKind.foodLog},
        requiresPhotoCount: 1,
        builder: (d, w) => FoodPhotoMacrosTemplate(data: d, showWatermark: w),
        docBuilder: foodPhotoMacrosDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.foodPolaroid,
        name: 'Polaroid',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        requiresPhotoCount: 1,
        builder: (d, w) => FoodPolaroidTemplate(data: d, showWatermark: w),
        docBuilder: foodPolaroidDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.foodMagazine,
        name: 'Cover',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        requiresPhotoCount: 1,
        builder: (d, w) => FoodMagazineTemplate(data: d, showWatermark: w),
        docBuilder: foodMagazineDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.foodCollage,
        name: 'Collage',
        category: ShareableCategory.studio,
        kinds: const {ShareableKind.foodLog},
        requiresPhotoCount: 2,
        builder: (d, w) => FoodCollageTemplate(data: d, showWatermark: w),
        docBuilder: foodCollageDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroRingsCard,
        name: 'Rings',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        builder: (d, w) => MacroRingsCardTemplate(data: d, showWatermark: w),
        docBuilder: macroRingsCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroNumbersCard,
        name: 'Numbers',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        builder: (d, w) => MacroNumbersCardTemplate(data: d, showWatermark: w),
        docBuilder: macroNumbersCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroPieCard,
        name: 'Pie',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        builder: (d, w) => MacroPieCardTemplate(data: d, showWatermark: w),
        docBuilder: macroPieCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroPlateCard,
        name: 'Plate',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        builder: (d, w) => MacroPlateCardTemplate(data: d, showWatermark: w),
        docBuilder: macroPlateCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.whatIAteCard,
        name: 'What I Ate',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        builder: (d, w) => WhatIAteCardTemplate(data: d, showWatermark: w),
        docBuilder: whatIAteCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroWaffleCard,
        name: 'Waffle',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.foodLog},
        builder: (d, w) => MacroWaffleCardTemplate(data: d, showWatermark: w),
        docBuilder: macroWaffleCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroBarsCard,
        name: 'Bars',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.foodLog},
        builder: (d, w) => MacroBarsCardTemplate(data: d, showWatermark: w),
        docBuilder: macroBarsCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.nutritionFactsCard,
        name: 'Facts',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        builder: (d, w) =>
            NutritionFactsCardTemplate(data: d, showWatermark: w),
        docBuilder: nutritionFactsCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.foodReceipt,
        name: 'Receipt',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        builder: (d, w) => FoodReceiptTemplate(data: d, showWatermark: w),
        docBuilder: foodReceiptDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.foodScoreCard,
        name: 'Score',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        builder: (d, w) => FoodScoreCardTemplate(data: d, showWatermark: w),
        docBuilder: foodScoreCardDoc,
      ),
      // ─── New editable-engine food formats (no legacy widget) ───
      ShareableTemplateSpec(
        template: ShareableTemplate.macroReceipt,
        name: 'Receipt',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        docBuilder: macroReceiptDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealTradingCard,
        name: 'Card',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealTradingCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.wrappedCalorie,
        name: 'Wrapped',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: wrappedCalorieDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.plateSpotlight,
        name: 'Spotlight',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: plateSpotlightDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroDonutHero,
        name: 'Donut',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: macroDonutHeroDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealBoardingPass,
        name: 'Pass',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealBoardingPassDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.thisOrThat,
        name: 'This or That',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: thisOrThatDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealNewspaper,
        name: 'News',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealNewspaperDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroTierList,
        name: 'Tier List',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: macroTierListDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.beforeAfterPlate,
        name: 'Before/After',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: beforeAfterPlateDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.statStripPhoto,
        name: 'Stat Strip',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: statStripPhotoDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealStreak,
        name: 'Streak',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealStreakDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.recipeCard,
        name: 'Recipe',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        docBuilder: recipeCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.goalProgressBars,
        name: 'Goals',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: goalProgressBarsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dayInMeals,
        name: 'Day Grid',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: dayInMealsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.minimalQuoteMeal,
        name: 'Quote',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: minimalQuoteMealDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealScoreboard,
        name: 'Scoreboard',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealScoreboardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealPassport,
        name: 'Passport',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealPassportDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.calorieCalendar,
        name: 'Calendar',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: calorieCalendarDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealCoupon,
        name: 'Coupon',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealCouponDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealIdBadge,
        name: 'ID Badge',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealIdBadgeDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.neonMeal,
        name: 'Neon',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: neonMealDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meshBigNumber,
        name: 'Big Number',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: meshBigNumberDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroSplitBlock,
        name: 'Split',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: macroSplitBlockDoc,
      ),
      // ─── Editable-engine food formats, wave 2 ───
      ShareableTemplateSpec(
        template: ShareableTemplate.candidMeal,
        name: 'Candid',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: candidMealDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealTimeline,
        name: 'Timeline',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealTimelineDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.snackPlate,
        name: 'Snack Plate',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: snackPlateDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealRating,
        name: 'Rating',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealRatingDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.povMeal,
        name: 'POV',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: povMealDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.proteinHero,
        name: 'Protein',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: proteinHeroDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.calorieGauge,
        name: 'Gauge',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: calorieGaugeDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroSparkline,
        name: 'Trend',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.foodLog},
        docBuilder: macroSparklineDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroCompare,
        name: 'Compare',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.foodLog},
        docBuilder: macroCompareDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroDashboard,
        name: 'Dashboard',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: macroDashboardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.macroExport,
        name: 'Export',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        docBuilder: macroExportDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealMeme,
        name: 'Meme',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealMemeDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealAchievement,
        name: 'Unlocked',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealAchievementDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealChat,
        name: 'Chat',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealChatDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealReview,
        name: 'Review',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealReviewDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealTabloid,
        name: 'Tabloid',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealTabloidDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.candyHeart,
        name: 'Candy',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: candyHeartDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.mealFlatLay,
        name: 'Flat Lay',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        docBuilder: mealFlatLayDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.editorialSplit,
        name: 'Editorial',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        docBuilder: editorialSplitDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.swissGrid,
        name: 'Swiss',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        docBuilder: swissGridDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.duotonePoster,
        name: 'Duotone',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        docBuilder: duotonePosterDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.softCard,
        name: 'Soft',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.foodLog},
        docBuilder: softCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dinerMenu,
        name: 'Diner',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.foodLog},
        docBuilder: dinerMenuDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.cassetteMeal,
        name: 'Cassette',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.foodLog},
        docBuilder: cassetteMealDoc,
      ),
      // ─── Social ───
      ShareableTemplateSpec(
        template: ShareableTemplate.socialBerealDual,
        name: 'Bereal Dual',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialBerealDualDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialCalendarInvite,
        name: 'Calendar Invite',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialCalendarInviteDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialChatConvo,
        name: 'Chat Convo',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialChatConvoDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialCommentThread,
        name: 'Comment Thread',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialCommentThreadDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialDm,
        name: 'Dm',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialDmDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialFbMemory,
        name: 'Fb Memory',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialFbMemoryDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialGroupChat,
        name: 'Group Chat',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialGroupChatDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialIgCarousel,
        name: 'Ig Carousel',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialIgCarouselDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialIgPost,
        name: 'Ig Post',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialIgPostDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialIgReelCover,
        name: 'Ig Reel Cover',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialIgReelCoverDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialIgStoryPoll,
        name: 'Ig Story Poll',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialIgStoryPollDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialLinkedinPost,
        name: 'Linkedin Post',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialLinkedinPostDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialPinterestPin,
        name: 'Pinterest Pin',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialPinterestPinDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialQuoteTweet,
        name: 'Quote Tweet',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialQuoteTweetDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialRedditPost,
        name: 'Reddit Post',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialRedditPostDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialSnapStreak,
        name: 'Snap Streak',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialSnapStreakDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialThreads,
        name: 'Threads',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialThreadsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialTiktokPost,
        name: 'Tiktok Post',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialTiktokPostDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialVenmoPayment,
        name: 'Venmo Payment',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialVenmoPaymentDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialYoutubeShorts,
        name: 'Youtube Shorts',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialYoutubeShortsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.socialYoutubeThumb,
        name: 'Youtube Thumb',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: socialYoutubeThumbDoc,
      ),
      // ─── AI ───
      ShareableTemplateSpec(
        template: ShareableTemplate.aiAgentLog,
        name: 'Agent Log',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiAgentLogDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiAvatar,
        name: 'Avatar',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiAvatarDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiCalorieScan,
        name: 'Calorie Scan',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiCalorieScanDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiCaption,
        name: 'Caption',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiCaptionDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiCoachChat,
        name: 'Coach Chat',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiCoachChatDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiConfidence,
        name: 'Confidence',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiConfidenceDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiDiffusionParams,
        name: 'Diffusion Params',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiDiffusionParamsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiGrid,
        name: 'Grid',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiGridDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiImagined,
        name: 'Imagined',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiImaginedDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiModelCard,
        name: 'Model Card',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiModelCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiNeuralAnalysis,
        name: 'Neural Analysis',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiNeuralAnalysisDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiNextWorkout,
        name: 'Next Workout',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiNextWorkoutDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiPoseCheck,
        name: 'Pose Check',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiPoseCheckDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiPromptPlan,
        name: 'Prompt Plan',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiPromptPlanDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiRepCounter,
        name: 'Rep Counter',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiRepCounterDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiRoast,
        name: 'Roast',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiRoastDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiStrengthCurve,
        name: 'Strength Curve',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiStrengthCurveDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiSummary,
        name: 'Summary',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiSummaryDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiVibeCheck,
        name: 'Vibe Check',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiVibeCheckDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiVoiceOrb,
        name: 'Voice Orb',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiVoiceOrbDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.aiWrapped,
        name: 'Wrapped',
        category: ShareableCategory.spark,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: aiWrappedDoc,
      ),
      // ─── Collectible ───
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleBanknote,
        name: 'Banknote',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleBanknoteDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleBattleCard,
        name: 'Battle Card',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleBattleCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleCasinoChip,
        name: 'Casino Chip',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleCasinoChipDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleCertificate,
        name: 'Certificate',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleCertificateDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleDogTag,
        name: 'Dog Tag',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleDogTagDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleFortune,
        name: 'Fortune',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleFortuneDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleGiftCard,
        name: 'Gift Card',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleGiftCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleHoloCard,
        name: 'Holo Card',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleHoloCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleLicensePlate,
        name: 'License Plate',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleLicensePlateDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleLoyaltyCard,
        name: 'Loyalty Card',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleLoyaltyCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleMedal,
        name: 'Medal',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleMedalDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleNftCard,
        name: 'Nft Card',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleNftCardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleRaceBib,
        name: 'Race Bib',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleRaceBibDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleScratchTicket,
        name: 'Scratch Ticket',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleScratchTicketDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleTrophyShelf,
        name: 'Trophy Shelf',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleTrophyShelfDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleWatchFace,
        name: 'Watch Face',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleWatchFaceDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.collectibleWristband,
        name: 'Wristband',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview, ShareableKind.personalRecords},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: collectibleWristbandDoc,
      ),
      // ─── iOS ───
      ShareableTemplateSpec(
        template: ShareableTemplate.iosActivityRings,
        name: 'Activity Rings',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosActivityRingsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosBillboard,
        name: 'Billboard',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosBillboardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosComicPanel,
        name: 'Comic Panel',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosComicPanelDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosDepartureBoard,
        name: 'Departure Board',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosDepartureBoardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosDynamicIsland,
        name: 'Dynamic Island',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosDynamicIslandDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosGlassWidget,
        name: 'Glass Widget',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosGlassWidgetDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosLockScreen,
        name: 'Lock Screen',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosLockScreenDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosMagazineCover,
        name: 'Magazine Cover',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosMagazineCoverDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosMeshGradient,
        name: 'Mesh Gradient',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosMeshGradientDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosMoviePoster,
        name: 'Movie Poster',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosMoviePosterDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosMuseumLabel,
        name: 'Museum Label',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosMuseumLabelDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosNeonSign,
        name: 'Neon Sign',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosNeonSignDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosNotificationStack,
        name: 'Notification Stack',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosNotificationStackDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosPeriodicElement,
        name: 'Periodic Element',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosPeriodicElementDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosVinylRecord,
        name: 'Vinyl Record',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosVinylRecordDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.iosWeatherWidget,
        name: 'Weather Widget',
        category: ShareableCategory.classic,
        kinds: const {ShareableKind.statsOverview, ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: iosWeatherWidgetDoc,
      ),
      // ─── Ticket ───
      ShareableTemplateSpec(
        template: ShareableTemplate.ticketBoardingPass,
        name: 'Boarding Pass',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: ticketBoardingPassDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.ticketCinema,
        name: 'Cinema',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: ticketCinemaDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.ticketCoupon,
        name: 'Coupon',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: ticketCouponDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.ticketEvent,
        name: 'Event',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: ticketEventDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.ticketGymReceipt,
        name: 'Gym Receipt',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: ticketGymReceiptDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.ticketLanyard,
        name: 'Lanyard',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: ticketLanyardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.ticketParking,
        name: 'Parking',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: ticketParkingDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.ticketPassport,
        name: 'Passport',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: ticketPassportDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.ticketRaffle,
        name: 'Raffle',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: ticketRaffleDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.ticketScratch,
        name: 'Scratch',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: ticketScratchDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.ticketWristband,
        name: 'Wristband',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: ticketWristbandDoc,
      ),
      // ─── Meaningful ───
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulBeforeAfter,
        name: 'Before After',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulBeforeAfterDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulComeback,
        name: 'Comeback',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulComebackDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulDearPastMe,
        name: 'Dear Past Me',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulDearPastMeDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulGrind,
        name: 'Grind',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulGrindDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulHundredWorkouts,
        name: 'Hundred Workouts',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulHundredWorkoutsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulIdentity,
        name: 'Identity',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulIdentityDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulJourney,
        name: 'Journey',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulJourneyDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulLetter,
        name: 'Letter',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulLetterDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulMilestone,
        name: 'Milestone',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulMilestoneDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulOneYear,
        name: 'One Year',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulOneYearDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulQuietWins,
        name: 'Quiet Wins',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulQuietWinsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulShowedUp,
        name: 'Showed Up',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulShowedUpDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulTransformationTimeline,
        name: 'Transformation Timeline',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulTransformationTimelineDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.meaningfulWhyITrain,
        name: 'Why I Train',
        category: ShareableCategory.editorial,
        kinds: const {ShareableKind.milestones, ShareableKind.statsOverview},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        docBuilder: meaningfulWhyITrainDoc,
      ),
      // ─── Data ───
      ShareableTemplateSpec(
        template: ShareableTemplate.dataBoxScore,
        name: 'Box Score',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataBoxScoreDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataBracket,
        name: 'Bracket',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataBracketDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataCaptcha,
        name: 'Captcha',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataCaptchaDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataError404,
        name: 'Error 404',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataError404Doc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataInfographic,
        name: 'Infographic',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataInfographicDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataLeaderboard,
        name: 'Leaderboard',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataLeaderboardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataMagic8ball,
        name: 'Magic 8ball',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataMagic8ballDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataOdometer,
        name: 'Odometer',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataOdometerDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataPieBreakdown,
        name: 'Pie Breakdown',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataPieBreakdownDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataRecoveryRing,
        name: 'Recovery Ring',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataRecoveryRingDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataRxLabel,
        name: 'Rx Label',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataRxLabelDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataScoreboard,
        name: 'Scoreboard',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataScoreboardDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataStockChart,
        name: 'Stock Chart',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataStockChartDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataStrengthRadar,
        name: 'Strength Radar',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataStrengthRadarDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataTierList,
        name: 'Tier List',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataTierListDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataVolumeBars,
        name: 'Volume Bars',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataVolumeBarsDoc,
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dataVolumeLine,
        name: 'Volume Line',
        category: ShareableCategory.graph,
        kinds: const {ShareableKind.statsOverview, ShareableKind.weeklyProgress},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait, ShareableAspect.square},
        docBuilder: dataVolumeLineDoc,
      ),
    ];
  }

  /// Used in tests + Phase 2 when each template's real builder lands.
  @visibleForTesting
  static void overrideEntries(List<ShareableTemplateSpec> entries) {
    _entries = entries;
  }

  static List<ShareableTemplateSpec> availableFor(
    Shareable data, {
    bool ownsCosmetic = false,
  }) {
    return all()
        .where((spec) => spec.isAvailableFor(data, ownsCosmetic: ownsCosmetic))
        .toList();
  }

  static List<ShareableCategory> categoriesFor(
    Shareable data, {
    bool ownsCosmetic = false,
  }) {
    final available = availableFor(data, ownsCosmetic: ownsCosmetic);
    // `rich` aliases to `classic` post-merge — collapse via [effective]
    // so we never surface two pills with the same "Cards" label.
    final cats = available.map((e) => e.category.effective).toSet().toList();
    cats.sort((a, b) => a.index.compareTo(b.index));
    return cats;
  }

  static List<ShareableTemplateSpec> templatesInCategory(
    Shareable data,
    ShareableCategory category, {
    bool ownsCosmetic = false,
  }) {
    return all()
        .where((spec) =>
            spec.category.effective == category.effective &&
            spec.isAvailableFor(data, ownsCosmetic: ownsCosmetic))
        .toList();
  }

  static ShareableTemplateSpec specFor(ShareableTemplate t) {
    return all().firstWhere((s) => s.template == t);
  }

  /// Returns the canonical "hero" template for a given share kind so
  /// callers don't need to thread an `initialTemplate` through. Used by
  /// `ShareableSheet` when no explicit template is requested — the sheet
  /// auto-lands on the most-relevant asset for what the user is sharing
  /// (weight log → Weight Trend, workout → Workout Details, streak →
  /// Streak Fire, etc.) instead of always starting on the registry's
  /// first entry.
  ///
  /// Returns null when no specific default applies; callers should then
  /// fall back to `availableFor(data).first`.
  static ShareableTemplate? defaultTemplateForKind(ShareableKind kind) {
    switch (kind) {
      case ShareableKind.workoutComplete:
        return ShareableTemplate.workoutDetails;
      case ShareableKind.bodyMeasurements:
      case ShareableKind.progressCharts:
      case ShareableKind.oneRm:
      case ShareableKind.exerciseHistory:
        return ShareableTemplate.weightGraph;
      case ShareableKind.personalRecords:
        return ShareableTemplate.prs;
      case ShareableKind.streak:
        return ShareableTemplate.streakFire;
      case ShareableKind.milestones:
        return ShareableTemplate.levelUp;
      case ShareableKind.achievements:
        return ShareableTemplate.achievementHero;
      case ShareableKind.wrapped:
        return ShareableTemplate.wrapped;
      case ShareableKind.weeklyProgress:
      case ShareableKind.weeklySummary:
        return ShareableTemplate.weeklyReport;
      case ShareableKind.muscleAnalytics:
        return ShareableTemplate.muscleMap;
      case ShareableKind.statsOverview:
        return ShareableTemplate.activityOverview;
      case ShareableKind.nutrition:
        return ShareableTemplate.statGrid;
      case ShareableKind.insights:
        return ShareableTemplate.smartInsight;
      case ShareableKind.strength:
        return ShareableTemplate.strengthRadar;
      case ShareableKind.periodInsights:
        return ShareableTemplate.calendarHeatmap;
      case ShareableKind.weeklyPlan:
        return ShareableTemplate.weeklyPlanGrid;
      case ShareableKind.monthlyPlan:
        return ShareableTemplate.monthlyPlanGrid;
      case ShareableKind.foodLog:
        return ShareableTemplate.foodPhotoMacros;
    }
  }
}
