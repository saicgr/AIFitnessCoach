/// Glass-blur centered modal that explains a [ContextualNudge] to the user
/// when they tap the row's text area. The CTA pill on the row remains a
/// direct shortcut and never opens this modal.
///
/// Contents (in order):
///   * `×` close button (top-right)
///   * Large icon (the same emoji the row uses, sized up)
///   * Title (matches the row title)
///   * Long-form explainer — server-provided override if present, else the
///     deterministic local string keyed by [NudgeId], else the short row
///     body as a last-resort fallback (the sheet is never empty).
///   * "Why this fired" line — short sentence describing the trigger.
///   * Primary `[Got it]` (close only) + `[Snooze 4h]` (snooze via
///     `nudgeSnoozeProvider`).
///   * A second row of quiet text actions: `Hide for today` (marks the
///     dedupKey shown via `subCardShownTodayProvider`) and `Always hide`
///     (permanent per-type mute via `coachUiSettingsProvider`). `Always
///     hide` is omitted for health-alert tier nudges so a genuine safety
///     alert can never be permanently silenced.
///   * Tap outside the card = close, no side effect.
///
/// Backdrop: `BackdropFilter` blur 16 + black opacity 0.3.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/models/contextual_nudge.dart';
import '../../data/providers/ai_settings_provider.dart';
import '../../data/providers/nudge_snooze_provider.dart';
import '../../data/providers/sub_card_shown_today_provider.dart';

/// Long-form per-nudge copy. The body is 2–3 sentences explaining the
/// "why" of the nudge; the trigger line is one short sentence describing
/// what made it fire. Copy is deliberately evergreen (no hard numbers) so it
/// never contradicts the live figure shown on the row itself.
class _NudgeExplainerCopy {
  final String body;
  final String trigger;
  const _NudgeExplainerCopy({required this.body, required this.trigger});
}

const Map<NudgeId, _NudgeExplainerCopy> _kNudgeExplainers = {
  // ── Hydration ────────────────────────────────────────────────────────
  NudgeId.hydration: _NudgeExplainerCopy(
    body:
        'Your body loses close to a litre of water overnight through breath '
        'and sweat. Drinking a tall glass before coffee rehydrates faster '
        'than caffeine and tends to lift morning energy more than a second '
        'cup.',
    trigger: 'You have not logged water yet this morning.',
  ),
  NudgeId.hydrationMidday: _NudgeExplainerCopy(
    body:
        'Most people drift behind on water by early afternoon, and mild '
        'dehydration reads as fatigue and a foggy head long before thirst '
        'kicks in. A glass now keeps focus steady through the back half of '
        'the day.',
    trigger: 'Your intake is trailing your daily target at midday.',
  ),
  NudgeId.hydrationLateDay: _NudgeExplainerCopy(
    body:
        'Topping up earlier in the evening lets you hit your hydration goal '
        'without the late glass that interrupts sleep. Front-loading fluids '
        'now is the gentler way to finish the day even.',
    trigger: 'You are short of your water goal with the evening closing in.',
  ),
  NudgeId.hydrationHeat: _NudgeExplainerCopy(
    body:
        'Heat pushes sweat rate up sharply, so your usual intake falls short '
        'on hot days. Drinking ahead of thirst protects training quality and '
        'keeps your heart rate from creeping during easy effort.',
    trigger: 'It is warm where you are and your intake is below target.',
  ),
  NudgeId.electrolyteTile: _NudgeExplainerCopy(
    body:
        'Plain water alone can dilute sodium when you sweat heavily, which is '
        'why a long hot session can leave you flat even when you drank '
        'plenty. A pinch of salt or an electrolyte mix restores the balance '
        'that plain water misses.',
    trigger: 'A sweaty session plus warm conditions raised your electrolyte need.',
  ),
  // ── Meals ────────────────────────────────────────────────────────────
  NudgeId.breakfast: _NudgeExplainerCopy(
    body:
        'A protein-forward first meal blunts the mid-morning crash and sets '
        'the day up to hit your protein target without a rushed evening '
        'top-up.',
    trigger: 'Breakfast is not logged for today.',
  ),
  NudgeId.lunch: _NudgeExplainerCopy(
    body:
        'Lunch is the swing meal. Hit your protein here and dinner can be '
        'lighter and earlier, which also lines up better with sleep.',
    trigger: 'Lunch is not logged for today.',
  ),
  NudgeId.dinner: _NudgeExplainerCopy(
    body:
        'A balanced dinner with most of your remaining protein helps '
        'overnight muscle repair. Heavy carbs late tend to push sleep '
        'efficiency down.',
    trigger: 'Dinner is not logged for today.',
  ),
  NudgeId.missedMealCatchup: _NudgeExplainerCopy(
    body:
        'A skipped meal usually shows up later as a bigger, less balanced '
        'one. Logging something now, even small, keeps your energy and your '
        'protein on track and steadies the rest of the day.',
    trigger: 'A meal slot passed today without anything logged.',
  ),
  // ── Workout ──────────────────────────────────────────────────────────
  NudgeId.workout: _NudgeExplainerCopy(
    body:
        "Today's workout is queued up. Starting earlier in the day preserves "
        'evening recovery and leaves a buffer if the session runs long.',
    trigger: 'Your scheduled workout has not started yet.',
  ),
  NudgeId.chronotypeMorning: _NudgeExplainerCopy(
    body:
        'For morning types, strength, coordination and drive peak in the '
        'first half of the day. Putting your hardest set here means you lift '
        'when the body is most ready, not when willpower is doing the work.',
    trigger: 'You train best in the morning and you are inside that window.',
  ),
  NudgeId.chronotypeEvening: _NudgeExplainerCopy(
    body:
        'For evening types, core temperature and power output crest later in '
        'the day. Slotting your top set into this window tends to add reps '
        'and load with no extra effort.',
    trigger: 'You train best in the evening and you are inside that window.',
  ),
  NudgeId.windDown: _NudgeExplainerCopy(
    body:
        'A short journal entry an hour before bed lowers cognitive load and '
        'improves sleep onset. It also gives the coach context for '
        "tomorrow's brief.",
    trigger: "Today's workout is done and you are inside the wind-down window.",
  ),
  // ── Pre-workout band ──────────────────────────────────────────────────
  NudgeId.preWorkoutFuel: _NudgeExplainerCopy(
    body:
        'A light, mostly-carb snack an hour or two before training tops up '
        'the fuel your muscles reach for first. It usually means stronger '
        'late sets without the heaviness of a full meal.',
    trigger: 'A workout is coming up and you have not eaten recently.',
  ),
  NudgeId.preWorkoutFuelMacro: _NudgeExplainerCopy(
    body:
        'Carbs before training are the fast fuel; a little protein alongside '
        'primes repair to start the moment you finish. Skewing the pre-set '
        'snack toward carbs is what tends to move performance most.',
    trigger: 'Your pre-workout window is open and your fuel mix can be tuned.',
  ),
  NudgeId.preWorkoutHydrate: _NudgeExplainerCopy(
    body:
        'Going into a session even slightly low on fluid drags down power '
        'and pushes heart rate higher for the same effort. A glass now, well '
        'before you start, sidesteps that.',
    trigger: 'A workout is near and your hydration is on the low side.',
  ),
  NudgeId.preWorkoutHydration: _NudgeExplainerCopy(
    body:
        'Topping up fluids ahead of your session protects strength and keeps '
        'perceived effort down. It is easier to start hydrated than to chase '
        'it mid-workout.',
    trigger: 'Your scheduled workout is approaching and intake is behind.',
  ),
  NudgeId.preWorkoutWarmup: _NudgeExplainerCopy(
    body:
        'A few minutes of warm-up raises muscle temperature and wakes up the '
        'nervous system, which sharpens the first working sets and lowers '
        'strain on cold tissue.',
    trigger: 'You are about to start without a warm-up logged.',
  ),
  NudgeId.preWorkoutVariantSwap: _NudgeExplainerCopy(
    body:
        'Based on how recovered you look today, a swapped variant keeps the '
        'stimulus while easing a joint or muscle that needs a lighter touch. '
        'Same goal, smarter path in.',
    trigger: "Today's readiness suggests a gentler variant fits better.",
  ),
  NudgeId.preWorkoutMoodCheckin: _NudgeExplainerCopy(
    body:
        'How you feel walking in shapes the right session. A quick check-in '
        'lets the coach dial intensity up on a good day or pull it back on a '
        'flat one, so the workout matches the human doing it.',
    trigger: 'A workout is queued and a quick mood read helps tune it.',
  ),
  NudgeId.preWorkoutCaffeineTiming: _NudgeExplainerCopy(
    body:
        'Caffeine takes roughly half an hour to come on and peaks around the '
        'hour mark. Timing it just before you head in lines the boost up '
        'with your hardest sets instead of your cool-down.',
    trigger: 'Your workout is close enough that caffeine timing matters.',
  ),
  NudgeId.preWorkoutDurationPreview: _NudgeExplainerCopy(
    body:
        "Knowing how long today's session runs lets you pace it and protect "
        'the back end. A quick preview avoids the rushed, half-finished '
        'workouts that come from misjudging the clock.',
    trigger: 'Your next session is scheduled and a time preview is ready.',
  ),
  // ── Post-workout band ────────────────────────────────────────────────
  NudgeId.postWorkoutRefuel: _NudgeExplainerCopy(
    body:
        'The hour after training is when muscle is most primed to take up '
        'protein and rebuild. A protein-forward meal or shake now turns the '
        'work you just did into actual adaptation.',
    trigger: 'You finished a workout and the refuel window is open.',
  ),
  NudgeId.postWorkoutProtein: _NudgeExplainerCopy(
    body:
        'Repair starts the moment you rack the last set, and protein is the '
        'raw material it runs on. Getting a solid serving in soon after '
        'training is one of the simplest levers on recovery and strength.',
    trigger: 'You just trained and your post-workout protein window is open.',
  ),
  NudgeId.postWorkoutProteinGrams: _NudgeExplainerCopy(
    body:
        'A meaningful dose of protein after training does more for repair '
        'than a token amount. Aiming for a full palm-sized serving, rather '
        'than a few bites, is what actually moves recovery.',
    trigger: 'Your logged post-workout protein is below the useful range.',
  ),
  NudgeId.postWorkoutPrChip: _NudgeExplainerCopy(
    body:
        'You set a personal record this session. Logging it locks the new '
        'baseline so future workouts build from today instead of repeating '
        'an old number.',
    trigger: 'A lift today beat your previous best for that movement.',
  ),
  NudgeId.postWorkoutKudosLoop: _NudgeExplainerCopy(
    body:
        'Naming what went well right after a session strengthens the habit '
        'loop that brings you back. A quick note of a win makes the next '
        'workout easier to start.',
    trigger: 'You just finished a session worth marking.',
  ),
  // ── Mood / mental ─────────────────────────────────────────────────────
  NudgeId.moodCheckin: _NudgeExplainerCopy(
    body:
        'A few seconds naming how you feel gives the coach signal to adjust '
        'tone, intensity and reminders. Over time the pattern also helps you '
        'spot what lifts or drains you.',
    trigger: 'You have not checked in on mood today.',
  ),
  NudgeId.breathwork: _NudgeExplainerCopy(
    body:
        'A couple of minutes of slow breathing shifts you out of fight-or-'
        'flight and into rest, which steadies focus and lowers stress load. '
        'It is one of the fastest resets available, anywhere.',
    trigger: 'A natural break in your day is a good moment to reset.',
  ),
  NudgeId.gratitudePrompt: _NudgeExplainerCopy(
    body:
        'Noting one thing that went right nudges attention toward progress '
        'instead of gaps. Done regularly it is quietly one of the most '
        'reliable mood levers there is.',
    trigger: 'A short gratitude prompt is due in your routine.',
  ),
  NudgeId.sleepStory: _NudgeExplainerCopy(
    body:
        'A calm audio wind-down gives your mind something low-stakes to '
        'follow, which eases the racing-thought loop that delays sleep '
        'onset. It is a softer off-ramp than scrolling.',
    trigger: 'You are inside your wind-down window.',
  ),
  // ── Movement ──────────────────────────────────────────────────────────
  NudgeId.hourlyStand: _NudgeExplainerCopy(
    body:
        'Standing and moving for even a minute each hour keeps circulation '
        'and metabolism ticking that long sitting shuts down. Small breaks '
        'add up to more daily movement than a single workout.',
    trigger: 'You have been seated for a while.',
  ),
  NudgeId.walkBreak: _NudgeExplainerCopy(
    body:
        'A short walk resets posture, loosens hips and shoulders, and clears '
        'the head between focused blocks. The break tends to pay for itself '
        'in the work that follows.',
    trigger: 'A good window for a quick walk is open right now.',
  ),
  NudgeId.longSitWalk: _NudgeExplainerCopy(
    body:
        'After a long stretch of sitting, a brief walk reverses the stiffness '
        'and sluggish circulation that build up. It is the cheapest way to '
        'feel sharper for the next stretch of work.',
    trigger: 'You have been sitting for an extended block.',
  ),
  NudgeId.activeCalorieRingClose: _NudgeExplainerCopy(
    body:
        'You are within reach of your movement goal for the day, and a short '
        'walk closes the gap. Finishing the ring keeps the daily-movement '
        'habit, and the streak behind it, intact.',
    trigger: 'You are close to, but short of, your active-calorie goal.',
  ),
  // ── Sleep ─────────────────────────────────────────────────────────────
  NudgeId.bedtimeWindow: _NudgeExplainerCopy(
    body:
        'Going to bed near the same time each night anchors your body clock, '
        'which improves both how fast you fall asleep and how rested you '
        'wake. Catching your window tonight protects tomorrow.',
    trigger: 'Your target bedtime is approaching.',
  ),
  NudgeId.blueLightCutoff: _NudgeExplainerCopy(
    body:
        'Bright screen light in the last hour before bed suppresses melatonin '
        'and pushes sleep later. Dimming or switching to warm tones now lets '
        'the natural wind-down signal through.',
    trigger: 'You are inside the hour before your usual bedtime.',
  ),
  // ── Schedule / planning ───────────────────────────────────────────────
  NudgeId.tomorrowPreview: _NudgeExplainerCopy(
    body:
        "Glancing at tomorrow's session tonight lets you pack a bag, plan "
        'fuel, or shift the time before the day gets away from you. A little '
        'foresight is most of what keeps a plan on the rails.',
    trigger: 'Tomorrow has a session worth previewing.',
  ),
  // ── Fasting band ──────────────────────────────────────────────────────
  NudgeId.fastingApproachingEnd: _NudgeExplainerCopy(
    body:
        'Your fast is nearly complete. Planning the first meal now keeps you '
        'from grabbing whatever is closest and lets you break the fast on '
        'protein and fibre instead.',
    trigger: 'You are close to the end of your fasting window.',
  ),
  NudgeId.fastingRefeed: _NudgeExplainerCopy(
    body:
        'How you break a fast shapes how you feel for hours after. Easing in '
        'with protein and something gentle on the gut avoids the spike-and-'
        'crash a heavy first meal can bring.',
    trigger: 'Your eating window just opened.',
  ),
  NudgeId.fastingPreCountdown: _NudgeExplainerCopy(
    body:
        'Your eating window is about to close. A last balanced bite now means '
        'you head into the fast satisfied rather than fighting hunger an hour '
        'in.',
    trigger: 'Your fasting window starts soon.',
  ),
  NudgeId.fastingExtend: _NudgeExplainerCopy(
    body:
        'You are feeling steady near your usual end time, so stretching the '
        'fast a little is an option, not an obligation. Only push it if '
        'energy and mood are genuinely fine.',
    trigger: 'You reached your fasting goal and still feel good.',
  ),
  NudgeId.fastingPostFastGuidance: _NudgeExplainerCopy(
    body:
        'The meal that breaks a longer fast lands best when it is moderate '
        'and protein-led. Going slow here protects digestion and keeps the '
        'benefit of the fast you just finished.',
    trigger: 'You just ended a longer fast.',
  ),
  NudgeId.fastedTrainingWarning: _NudgeExplainerCopy(
    body:
        'Training hard on an empty tank can sap strength and make late sets '
        'feel heavier than they are. If today is a tough session, a few '
        'quick carbs first usually serve you better than going fully fasted.',
    trigger: 'A demanding workout is scheduled inside your fasting window.',
  ),
  NudgeId.fastDayProteinShift: _NudgeExplainerCopy(
    body:
        'A shorter eating window leaves less room to hit your protein, so it '
        'helps to front-load it in the first meal. Protecting protein on '
        'fast days is what keeps muscle while you cut.',
    trigger: 'Today is a fasting day with a compressed eating window.',
  ),
  NudgeId.fastBrokeEarlyAck: _NudgeExplainerCopy(
    body:
        'Ending a fast early is a data point, not a failure. Noting it lets '
        'the plan adapt and keeps one off day from snowballing into a '
        'narrative about willpower.',
    trigger: "You ended today's fast ahead of your target.",
  ),
  // ── Nutrition gaps ────────────────────────────────────────────────────
  NudgeId.proteinGapMeal: _NudgeExplainerCopy(
    body:
        'Spreading protein across meals does more for muscle than saving it '
        'for one big dinner. Adding some at your next meal keeps the day on '
        'pace without a stressful evening top-up.',
    trigger: 'Your protein is trailing pace for this point in the day.',
  ),
  NudgeId.fiberGapMeal: _NudgeExplainerCopy(
    body:
        'Fibre steadies blood sugar, feeds gut bacteria and keeps you full '
        'between meals, and most days fall short. Adding vegetables or whole '
        'grains at your next meal is the easy fix.',
    trigger: 'Your fibre is running low for the day so far.',
  ),
  NudgeId.sodiumWatch: _NudgeExplainerCopy(
    body:
        'Sodium adds up fast in packaged and restaurant food, and a high day '
        'shows up as bloating and a jumpy scale the next morning. Leaning on '
        'whole foods for the rest of the day rebalances it.',
    trigger: 'Your sodium is on the high side for today.',
  ),
  NudgeId.hiddenSugar: _NudgeExplainerCopy(
    body:
        'A lot of added sugar hides in sauces, drinks and snacks that do not '
        'taste especially sweet. Spotting it lets you trade a few sources '
        'and free up room for food that keeps you fuller.',
    trigger: 'Added sugar is climbing from sources that are easy to miss.',
  ),
  NudgeId.caffeineCutoff: _NudgeExplainerCopy(
    body:
        'Caffeine lingers for hours, so an afternoon cup can still be in your '
        'system at bedtime, thinning deep sleep even if you fall asleep fine. '
        'Calling it for the day now protects tonight.',
    trigger: 'You are past the hour where caffeine starts costing sleep.',
  ),
  NudgeId.lateSnackAlternative: _NudgeExplainerCopy(
    body:
        'Late hunger is often thirst or habit rather than real need. If you '
        'do want something, a light protein or fruit option satisfies '
        'without the heavy, sleep-disrupting late meal.',
    trigger: 'It is late and a snack is on your mind.',
  ),
  NudgeId.adaptiveCalorieAdjust: _NudgeExplainerCopy(
    body:
        'Your body adapts as weight and activity shift, so a target set weeks '
        'ago drifts out of date. A small nudge based on your recent trend '
        'keeps progress steady without a big swing.',
    trigger: 'Your two-week trend suggests a small target adjustment.',
  ),
  NudgeId.refeedDay: _NudgeExplainerCopy(
    body:
        'A planned higher-carb day during a deficit tops up muscle glycogen '
        'and gives hormones a breather, which can refresh training and '
        'mood. It is a strategic part of the plan, not a slip.',
    trigger: 'Today is scheduled as a refeed in your plan.',
  ),
  // ── Recovery / wearable ───────────────────────────────────────────────
  NudgeId.readinessAlert: _NudgeExplainerCopy(
    body:
        'Your recovery markers came in lower than usual, which is the body '
        'asking for an easier day. Dialing volume or intensity back now '
        'protects the harder sessions later in the week.',
    trigger: 'Your readiness score is below your normal range.',
  ),
  NudgeId.hrvDrop: _NudgeExplainerCopy(
    body:
        'A dip in heart-rate variability often shows up a day before you feel '
        'run down, flagging accumulated stress or the start of illness. '
        'Treating today as lighter is the cheap insurance.',
    trigger: 'Your heart-rate variability dropped against your baseline.',
  ),
  NudgeId.rhrAnomaly: _NudgeExplainerCopy(
    body:
        'An elevated resting heart rate is one of the earliest signs of '
        'under-recovery, stress or a coming cold. Easing off today usually '
        'beats pushing through and paying for it later.',
    trigger: 'Your resting heart rate is above your usual baseline.',
  ),
  NudgeId.respRateAnomaly: _NudgeExplainerCopy(
    body:
        'A higher overnight breathing rate can be an early signal of strain '
        'or illness, often before symptoms appear. A lighter day gives the '
        'body room to sort it out.',
    trigger: 'Your overnight respiratory rate ran above normal.',
  ),
  NudgeId.sleepEfficiencyDrop: _NudgeExplainerCopy(
    body:
        'When more of your time in bed is spent awake or restless, recovery '
        'and next-day focus take the hit even if total hours look fine. A '
        'tighter wind-down tonight is the lever.',
    trigger: 'Your sleep efficiency dipped below your usual range.',
  ),
  NudgeId.remDeepLow: _NudgeExplainerCopy(
    body:
        'Deep sleep does the physical repair and REM does the mental '
        'consolidation, so a short night on both blunts recovery and mood. '
        'An earlier, calmer wind-down is the most direct fix.',
    trigger: 'Both deep and REM sleep came in under your recent average.',
  ),
  NudgeId.skinTempShift: _NudgeExplainerCopy(
    body:
        'A rise in overnight skin temperature can precede a cold or signal '
        'extra strain. Logging how you feel and keeping today easy helps the '
        'plan respond before it becomes a lost week.',
    trigger: 'Your overnight skin temperature ran above baseline.',
  ),
  // ── Cycle / hormonal ──────────────────────────────────────────────────
  NudgeId.pmsPrep: _NudgeExplainerCopy(
    body:
        'In the days before your period, energy, cravings and sleep often '
        'shift. Knowing it is coming lets you plan gentler sessions and '
        'steadier meals instead of reading the dip as backsliding.',
    trigger: 'You are entering the pre-menstrual phase of your cycle.',
  ),
  NudgeId.ovulationPeak: _NudgeExplainerCopy(
    body:
        'Around ovulation many people feel a natural lift in strength and '
        'drive. It is a good window to chase a heavier session or a personal '
        'best while the body is primed for it.',
    trigger: 'You are near the ovulation peak in your cycle.',
  ),
  NudgeId.ovulationStrengthWindow: _NudgeExplainerCopy(
    body:
        'Strength tends to crest in the days around ovulation thanks to the '
        'hormonal backdrop. Scheduling your heaviest lifts here often turns '
        'into easy progress on the bar.',
    trigger: 'You are in the higher-strength window of your cycle.',
  ),
  NudgeId.periodPredict: _NudgeExplainerCopy(
    body:
        'A heads-up that your period is due soon helps you plan training, '
        'fuel and rest around it. Anticipating the shift beats being '
        'surprised by it mid-week.',
    trigger: 'Your next period is predicted to start soon.',
  ),
  NudgeId.periodSymptom: _NudgeExplainerCopy(
    body:
        'Logging symptoms sharpens future predictions and helps the coach '
        'adjust intensity to how you actually feel. Over a few cycles the '
        'pattern becomes genuinely useful guidance.',
    trigger: 'You are in a phase where symptom tracking adds the most signal.',
  ),
  NudgeId.pregnancyModeGuard: _NudgeExplainerCopy(
    body:
        'With pregnancy mode on, the plan favours safe ranges over personal '
        'bests and flags movements worth modifying. The aim is to keep you '
        'moving comfortably, not chasing numbers.',
    trigger: "Pregnancy mode is active and today's plan was adjusted for it.",
  ),
  NudgeId.perimenopauseCue: _NudgeExplainerCopy(
    body:
        'Shifting hormones can change recovery, sleep and how the body holds '
        'strength. Leaning into resistance work and protein during this '
        'phase protects muscle and bone where it matters most.',
    trigger: 'Your profile indicates a perimenopausal phase worth supporting.',
  ),
  // ── Habit / gamification ──────────────────────────────────────────────
  NudgeId.habitStack: _NudgeExplainerCopy(
    body:
        'Anchoring a new habit to one you already do, like a glass of water '
        'with your morning coffee, makes it stick far better than willpower '
        'alone. The existing routine does the remembering for you.',
    trigger: 'A habit you are building lines up with this moment.',
  ),
  NudgeId.achievementNearUnlock: _NudgeExplainerCopy(
    body:
        'You are one small action from unlocking this. The pull of a nearly-'
        'finished goal is real, and finishing it now banks the win and the '
        'momentum.',
    trigger: 'You are close to unlocking an achievement.',
  ),
  NudgeId.kudosBadge: _NudgeExplainerCopy(
    body:
        'You earned this. Marking the milestone is a small thing that keeps '
        'the longer effort feeling worth it, which is most of what keeps '
        'people going.',
    trigger: 'You hit a milestone worth celebrating.',
  ),
  // ── Streak ────────────────────────────────────────────────────────────
  NudgeId.streakAtRisk: _NudgeExplainerCopy(
    body:
        'Your streak is about to lapse, and a streak is mostly valuable for '
        'the consistency it represents. One small action today keeps the '
        'chain, and the identity behind it, intact.',
    trigger: 'Your active streak will break without an action today.',
  ),
  // ── Goal / milestone ──────────────────────────────────────────────────
  NudgeId.goalHalfway: _NudgeExplainerCopy(
    body:
        'You are halfway to your goal. The midpoint is where motivation '
        'often sags, so it is worth a deliberate look back at how far you '
        'have come before pushing through the second half.',
    trigger: 'You reached the halfway mark on a goal.',
  ),
  NudgeId.goalSlipping: _NudgeExplainerCopy(
    body:
        'Recent days have drifted off the line toward your goal. Catching it '
        'now, with a small correction, is far easier than a big rescue '
        'later. No drama, just a nudge back on course.',
    trigger: 'Your recent trend is drifting away from your goal pace.',
  ),
  NudgeId.raceCountdown: _NudgeExplainerCopy(
    body:
        'With your event approaching, the smart moves shift from building to '
        'sharpening and resting. A countdown keeps taper, fuel and logistics '
        'from sneaking up on you.',
    trigger: 'Your race or event is coming up soon.',
  ),
  // ── Travel ────────────────────────────────────────────────────────────
  NudgeId.jetLag: _NudgeExplainerCopy(
    body:
        'Light exposure and meal timing are the fastest ways to drag your '
        'body clock onto the new zone. A small plan for the first day or two '
        'shortens the groggy stretch considerably.',
    trigger: 'You crossed time zones recently.',
  ),
  NudgeId.hotelGym: _NudgeExplainerCopy(
    body:
        'Travel is where routines quietly die. A short adapted session with '
        'whatever the hotel has keeps the habit alive, and the habit matters '
        'more than the perfect workout.',
    trigger: 'You are away from your usual training setup.',
  ),
  // ── Social ────────────────────────────────────────────────────────────
  NudgeId.friendActivity: _NudgeExplainerCopy(
    body:
        'Seeing someone you know stay active is a gentle, proven pull to do '
        'the same. A little friendly momentum makes showing up easier.',
    trigger: 'Someone in your circle logged activity recently.',
  ),
  NudgeId.partnerCheckin: _NudgeExplainerCopy(
    body:
        'A quick check-in with a training partner adds the light '
        'accountability that turns intentions into sessions. Shared goals '
        'tend to outlast solo ones.',
    trigger: 'A check-in with your partner is due.',
  ),
  // ── Subscription ──────────────────────────────────────────────────────
  NudgeId.usageBasedUpsell: _NudgeExplainerCopy(
    body:
        'You are leaning on the features that get the most out of the app. '
        'This is just a heads-up on what else is included, in case something '
        'fits how you already train.',
    trigger: 'Your usage suggests features you may not have explored.',
  ),
  // ── Educational ───────────────────────────────────────────────────────
  NudgeId.dailyLesson: _NudgeExplainerCopy(
    body:
        'A one-minute lesson a day compounds into a real working knowledge '
        'of training and nutrition over a few months. Small, steady learning '
        'is how the guesswork drops out.',
    trigger: "Today's lesson is ready.",
  ),
  NudgeId.weeklyDigest: _NudgeExplainerCopy(
    body:
        'A short weekly recap turns scattered days into a pattern you can '
        'actually act on. Seeing the week whole is where the useful '
        'adjustments come from.',
    trigger: 'Your weekly summary is ready to review.',
  ),
  NudgeId.discoveryInsight: _NudgeExplainerCopy(
    body:
        'A pattern in your own data is far more convincing than a generic '
        'tip. This one surfaced because it showed up clearly in how you have '
        'been training or eating.',
    trigger: 'A noteworthy pattern emerged in your recent data.',
  ),
  // ── Wearable status ───────────────────────────────────────────────────
  NudgeId.wearableBatteryLow: _NudgeExplainerCopy(
    body:
        'If your wearable dies overnight you lose the sleep and recovery data '
        "that drives tomorrow's guidance. A quick top-up charge keeps the "
        'picture complete.',
    trigger: 'Your connected wearable is low on battery.',
  ),
  NudgeId.scaleSyncPrompt: _NudgeExplainerCopy(
    body:
        'Regular weigh-ins, read as a trend rather than a single number, are '
        'what let the plan adapt accurately. Syncing keeps that trend line '
        'honest.',
    trigger: 'Your scale has readings that have not synced yet.',
  ),
  // ── Cooking / pantry ──────────────────────────────────────────────────
  NudgeId.leftoverCountdown: _NudgeExplainerCopy(
    body:
        'You have batch-cooked portions waiting, and they are best eaten '
        'before they turn. Reaching for them first saves money and spares '
        'you a decision when hunger hits.',
    trigger: 'You have cooked portions approaching their use-by.',
  ),
  NudgeId.groceryGeofence: _NudgeExplainerCopy(
    body:
        'You are near a store and a short list keeps the trip focused on '
        'what your plan actually needs. A little structure here is what '
        "makes the week's meals fall into place.",
    trigger: 'You are close to a grocery store with items to restock.',
  ),
  // ── Calendar ──────────────────────────────────────────────────────────
  NudgeId.meetingHeavyLighter: _NudgeExplainerCopy(
    body:
        'Your calendar is packed today, so a shorter, simpler session is the '
        'realistic win. A workout that fits the day beats an ambitious one '
        'that gets skipped.',
    trigger: 'Today is meeting-heavy with little open time.',
  ),
  NudgeId.freeWindowHold: _NudgeExplainerCopy(
    body:
        'There is an open block in your day that fits a workout. Holding it '
        'now, before it fills, is most of how a session actually happens.',
    trigger: 'An open window in your schedule suits a session.',
  ),
  // ── Misc ──────────────────────────────────────────────────────────────
  NudgeId.weighInReminder: _NudgeExplainerCopy(
    body:
        'Weighing in at the same time, ideally first thing, keeps the number '
        'comparable day to day. Consistency in when you weigh matters more '
        'than the reading on any single morning.',
    trigger: 'A weigh-in is due to keep your trend current.',
  ),
  NudgeId.birthday: _NudgeExplainerCopy(
    body:
        'Happy birthday. A good day to look back at the year of work and set '
        'the tone for the next one.',
    trigger: "It's your birthday.",
  ),
  NudgeId.appAnniversary: _NudgeExplainerCopy(
    body:
        'You have been at this for a while now, and that consistency is the '
        'whole game. Worth a moment to notice how far the small daily efforts '
        'have carried you.',
    trigger: 'It is your anniversary with the app.',
  ),
  NudgeId.firstOfMonth: _NudgeExplainerCopy(
    body:
        'A fresh month is a natural checkpoint to set an intention and review '
        'what worked last month. These small resets are where momentum gets '
        'renewed.',
    trigger: 'It is the first of the month.',
  ),
};

/// Show the explainer modal. Returns once the modal is closed.
Future<void> showCoachNudgeExplainer(
  BuildContext context, {
  required ContextualNudge nudge,
  required WidgetRef ref,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.30),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: _CoachNudgeExplainerCard(nudge: nudge, parentRef: ref),
        ),
      );
    },
  );
}

class _CoachNudgeExplainerCard extends StatelessWidget {
  final ContextualNudge nudge;
  final WidgetRef parentRef;
  const _CoachNudgeExplainerCard({
    required this.nudge,
    required this.parentRef,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final copy = _kNudgeExplainers[nudge.id] ??
        const _NudgeExplainerCopy(
          body: '',
          trigger: '',
        );
    // Fallback chain: server override → local long-form copy → the short row
    // body. The row body is always non-empty, so the sheet never renders
    // blank even for a nudge id added later without explainer copy.
    final override = nudge.explainerOverride?.trim();
    final longBody = (override != null && override.isNotEmpty)
        ? override
        : (copy.body.isNotEmpty ? copy.body : nudge.body.trim());

    // Health-alert nudges can be hidden for today but never permanently
    // muted — a genuine safety signal should always be able to resurface.
    final canMute = nudge.priorityTier != NudgePriorityTier.healthAlert;

    // Cap the card height so a long explainer scrolls on small screens (SE)
    // instead of throwing a vertical render overflow.
    final maxH = MediaQuery.of(context).size.height * 0.8;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 340, maxHeight: maxH),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
                decoration: BoxDecoration(
                  color: c.elevated.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(nudge.icon,
                            style: const TextStyle(fontSize: 30)),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: c.textMuted),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Scrollable middle so long copy never overflows; the
                    // header and the action buttons stay pinned.
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nudge.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (longBody.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                longBody,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.45,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                            if (copy.trigger.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                'Why this fired',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: c.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                copy.trigger,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.accent,
                              foregroundColor: c.accentContrast,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Got it'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              parentRef
                                  .read(nudgeSnoozeProvider.notifier)
                                  .snooze(nudge.id);
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: c.textPrimary,
                              side: BorderSide(color: c.cardBorder),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Snooze 4h'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Quiet, keyboard/screen-reader-reachable equivalents of
                    // the swipe gestures. "Always hide" is omitted for
                    // health alerts (see canMute above).
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            parentRef
                                .read(subCardShownTodayProvider.notifier)
                                .markShown(nudge.effectiveDedupKey);
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: c.textMuted,
                            minimumSize: const Size(0, 32),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Hide for today'),
                        ),
                        if (canMute)
                          TextButton(
                            onPressed: () {
                              parentRef
                                  .read(coachUiSettingsProvider.notifier)
                                  .muteNudge(nudge.id);
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: c.textMuted,
                              minimumSize: const Size(0, 32),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Always hide'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
