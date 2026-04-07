/// Achievement Prompt Service
///
/// Generates coach-persona-aware motivational prompts during rest periods.
/// Adapts tone, style, and emoji usage to match the user's selected coach.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for AchievementPromptService
final achievementPromptServiceProvider = Provider<AchievementPromptService>((ref) {
  return AchievementPromptService();
});

/// Service for generating achievement/motivational prompts
class AchievementPromptService {
  AchievementPromptService();

  /// Get an achievement prompt for the current set, personalized to coach persona
  Future<String?> getPromptForSet({
    required String exerciseName,
    required double currentWeight,
    required int currentReps,
    required int setNumber,
    required int totalSets,
    String? userId,
    String coachingStyle = 'motivational',
    String communicationTone = 'encouraging',
    double encouragementLevel = 0.8,
    bool useEmojis = true,
    String? coachName,
    // Timing comparison data
    double? previousSetWeight,
    int? previousSetReps,
    int? currentDurationSeconds,
    int? previousDurationSeconds,
    int? restDurationSeconds,
    int? prescribedRestSeconds,
  }) async {
    return _generatePrompt(
      currentWeight: currentWeight,
      currentReps: currentReps,
      setNumber: setNumber,
      totalSets: totalSets,
      coachingStyle: coachingStyle,
      communicationTone: communicationTone,
      encouragementLevel: encouragementLevel,
      useEmojis: useEmojis,
      coachName: coachName,
      previousSetWeight: previousSetWeight,
      previousSetReps: previousSetReps,
      currentDurationSeconds: currentDurationSeconds,
      previousDurationSeconds: previousDurationSeconds,
      restDurationSeconds: restDurationSeconds,
      prescribedRestSeconds: prescribedRestSeconds,
    );
  }

  String? _generatePrompt({
    required double currentWeight,
    required int currentReps,
    int? setNumber,
    int? totalSets,
    required String coachingStyle,
    required String communicationTone,
    required double encouragementLevel,
    required bool useEmojis,
    String? coachName,
    double? previousSetWeight,
    int? previousSetReps,
    int? currentDurationSeconds,
    int? previousDurationSeconds,
    int? restDurationSeconds,
    int? prescribedRestSeconds,
  }) {
    // Low encouragement = fewer prompts (skip ~40% of the time)
    if (encouragementLevel < 0.5 && DateTime.now().second % 5 < 2) return null;

    final seed = DateTime.now().millisecond;
    final style = _StyleKey.from(coachingStyle, communicationTone);

    // Determine what happened, pick the right message pool
    String? raw;

    // PRIORITY: Timing comparisons against previous set (set 2+)
    if (previousSetWeight != null && previousSetReps != null &&
        currentDurationSeconds != null && previousDurationSeconds != null &&
        previousDurationSeconds > 0) {
      final weightDelta = currentWeight - previousSetWeight;
      final repsDelta = currentReps - previousSetReps;
      final timeDelta = currentDurationSeconds - previousDurationSeconds;
      final restRatio = (prescribedRestSeconds != null && prescribedRestSeconds > 0 && restDurationSeconds != null)
          ? restDurationSeconds / prescribedRestSeconds
          : 1.0;

      // 1. Density PR: heavier weight AND faster/same time
      if (weightDelta > 0 && timeDelta <= 0) {
        raw = _pick(_densityPR, style, seed);
      }
      // 2. Speed improvement: same weight, same reps, noticeably faster
      else if (weightDelta.abs() < 0.1 && repsDelta == 0 && timeDelta < -5) {
        raw = _pick(_fasterSet, style, seed)
            ?.replaceAll('{t}', '${timeDelta.abs()}');
      }
      // 3. Work capacity: same weight, more reps, similar time
      else if (weightDelta.abs() < 0.1 && repsDelta > 0 && timeDelta.abs() < 10) {
        raw = _pick(_workCapacity, style, seed);
      }
      // 4. Rest resilience: short rest + maintained or better performance
      else if (restRatio < 0.5 && weightDelta >= 0 && repsDelta >= 0) {
        raw = _pick(_restResilience, style, seed);
      }
      // 5. Heavier + more reps
      else if (weightDelta > 0 && repsDelta > 0) {
        raw = _pick(_heavierAndMore, style, seed);
      }
      // 6. Consistent tempo
      else if (timeDelta.abs() < 3 && weightDelta.abs() < 0.1) {
        raw = _pick(_consistentTempo, style, seed);
      }
      // 7. Normal fatigue (gentle, only for moderate+ encouragement)
      else if (timeDelta > 10 && repsDelta <= 0 && weightDelta.abs() < 0.1 && encouragementLevel >= 0.5) {
        raw = _pick(_normalFatigue, style, seed);
      }
    }
    // Short rest feedback (no previous set timing needed)
    else if (restDurationSeconds != null && prescribedRestSeconds != null &&
        prescribedRestSeconds > 0 && restDurationSeconds / prescribedRestSeconds < 0.5 &&
        setNumber != null && setNumber > 1) {
      raw = _pick(_shortRest, style, seed);
    }

    // Fall through to milestone-based prompts if no timing comparison matched
    if (raw != null) {
      // Timing comparison found — skip milestones
    } else if (currentWeight >= 100) {
      raw = _pick(_heavyWeight, style, seed);
    } else if (currentWeight >= 60 && currentWeight % 20 == 0) {
      raw = _pick(_roundWeight, style, seed)
          ?.replaceAll('{w}', currentWeight.toStringAsFixed(0));
    } else if (currentReps >= 15) {
      raw = _pick(_highReps, style, seed)
          ?.replaceAll('{r}', '$currentReps');
    } else if (currentReps >= 12) {
      raw = _pick(_goodVolume, style, seed);
    } else if (currentReps == 10) {
      raw = _pick(_perfectTen, style, seed);
    } else if (setNumber != null && totalSets != null) {
      if (setNumber == 1) {
        raw = _pick(_firstSet, style, seed)
            ?.replaceAll('{remaining}', '${totalSets - 1}');
      } else if (setNumber == totalSets) {
        raw = _pick(_lastSet, style, seed);
      } else if (setNumber == totalSets - 1) {
        raw = _pick(_penultimateSet, style, seed);
      }
    }

    // Fallback: general encouragement (50% chance)
    raw ??= (DateTime.now().second % 2 == 0)
        ? _pick(_general, style, seed)
        : null;

    if (raw == null) return null;

    // Strip emojis if user disabled them
    if (!useEmojis) {
      raw = raw.replaceAll(RegExp(r'[\u{1F300}-\u{1FAD6}\u{2600}-\u{27BF}\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}]', unicode: true), '').trim();
    }

    return raw;
  }

  // ── message pools keyed by style category ──

  static const _motivational = 'motivational';
  static const _drillSergeant = 'drill-sergeant';
  static const _scientist = 'scientist';
  static const _zenMaster = 'zen-master';
  static const _hypeBeast = 'hype-beast';
  static const _genZ = 'gen-z';
  static const _sarcastic = 'sarcastic';
  static const _pirate = 'pirate';
  static const _british = 'british';
  static const _surfer = 'surfer';
  static const _anime = 'anime';
  static const _fallback = 'fallback';

  /// Pick a message from the pool for the given style
  static String? _pick(Map<String, List<String>> pool, _StyleKey style, int seed) {
    // Try exact style match first, then tone match, then fallback
    final msgs = pool[style.primary] ?? pool[style.secondary] ?? pool[_fallback]!;
    return msgs[seed % msgs.length];
  }

  // ─── HEAVY WEIGHT (100+ lb) ─────────────────────────────────

  static final _heavyWeight = <String, List<String>>{
    _motivational: [
      "Triple digits — you earned that 💯",
      "100+ on the bar, that's big-time lifting",
      "Heavy weight, strong lifter. Simple as that",
    ],
    _drillSergeant: [
      "TRIPLE DIGITS. Now we're talking, soldier!",
      "100+ and you didn't flinch. Good.",
      "That's real weight. Don't get comfortable — go heavier next week",
    ],
    _scientist: [
      "100+ lb — you're well into the strength adaptation zone",
      "Triple digits. Your motor unit recruitment is peaking",
      "Significant load — your CNS is firing on all cylinders",
    ],
    _zenMaster: [
      "Heavy iron, calm mind. That's mastery",
      "100+ lb moved with intention — beautiful",
      "The weight is heavy, but you are steady",
    ],
    _hypeBeast: [
      "TRIPLE DIGITS LET'S GOOO 💯🔥🔥",
      "100+ CLUB BABYYY!! YOU'RE BUILT DIFFERENT!!",
      "THAT'S BIG BOY WEIGHT RIGHT THERE!! 💪💯",
    ],
    _genZ: [
      "100+ no cap that's lowkey insane 💯",
      "triple digits?? you're giving main character fr fr",
      "bestie said heavy weight? slay 💅",
    ],
    _sarcastic: [
      "Oh wow, triple digits. I guess the bar noticed you today",
      "100+... not bad for someone who almost skipped today",
      "Triple digits. The plates are impressed, probably",
    ],
    _pirate: [
      "Triple digits on the bar, ye mighty sea dog! ☠️",
      "100+ doubloons of iron! A captain's lift! 🏴‍☠️",
      "Arr, that be heavyweight territory, matey!",
    ],
    _british: [
      "Triple digits — absolutely smashing effort, that",
      "100+ pounds, rather impressive if I do say so",
      "Well done, proper heavyweight lifting there",
    ],
    _surfer: [
      "Dude, triple digits! That's a gnarly wave of iron 🤙",
      "100+ bro, you're riding the heavy swell now",
      "Radical! Big weight, big stoke!",
    ],
    _anime: [
      "TRIPLE DIGITS?! Your power level... it's OVER 100!! 💯",
      "This weight... it cannot contain your strength!!",
      "NANI?! 100+ pounds?! The protagonist awakens!!",
    ],
    _fallback: [
      "Triple digits on the bar 💯",
      "100+ — serious weight",
      "Big plates, big effort",
    ],
  };

  // ─── ROUND WEIGHT ───────────────────────────────────────────

  static final _roundWeight = <String, List<String>>{
    _motivational: ["Clean {w} lb — looks easy on you", "{w} lb and moving smooth, nice"],
    _drillSergeant: ["{w} lb? That's your warm-up weight now. PUSH.", "{w} lb, clean reps. Now do it heavier."],
    _scientist: ["{w} lb — a clean load for progressive overload tracking", "Round number, precise execution at {w} lb"],
    _zenMaster: ["{w} lb — round numbers bring round clarity", "A balanced weight, a balanced lift"],
    _hypeBeast: ["{w} LB LIKE IT'S NOTHING!! 🔥🔥", "CLEAN {w} LB LET'S EAT!! 💪"],
    _genZ: ["{w} lb slaps different ngl", "that {w} was bussin no cap"],
    _sarcastic: ["{w} lb, congrats on the nice round number", "Wow {w}, how aesthetically pleasing"],
    _pirate: ["{w} doubloons of iron! Fine plunder! 🏴‍☠️"],
    _british: ["A tidy {w} lb — quite proper, that"],
    _surfer: ["{w} lb bro, clean as a wave 🤙"],
    _anime: ["{w} POUNDS!! The power surges!!"],
    _fallback: ["{w} lb, clean", "{w} lb — looking good"],
  };

  // ─── HIGH REPS (15+) ───────────────────────────────────────

  static final _highReps = <String, List<String>>{
    _motivational: [
      "{r} reps — you barely slowed down 🔥",
      "That's {r} clean reps, stamina is way up",
      "{r} deep and still in control",
    ],
    _drillSergeant: [
      "{r} REPS?! You've got more in you. I KNOW IT.",
      "{r} and you're not even gassed. Good, you shouldn't be.",
      "That's {r}. Pain is temporary. Those reps are FOREVER.",
    ],
    _scientist: [
      "{r} reps puts you solidly in the muscular endurance zone",
      "At {r} reps, you're maximizing type I fiber recruitment",
      "{r} reps — excellent metabolic stress for hypertrophy",
    ],
    _zenMaster: [
      "{r} reps flowed like water — that's the way",
      "Each of those {r} reps was a meditation in motion",
      "{r} breaths, {r} reps — you were present for each one",
    ],
    _hypeBeast: [
      "{r} REPS?! YOU'RE A MACHINE BRO!! 🔥🔥🔥",
      "DID YOU JUST HIT {r}?! THAT'S DIFFERENT!! 💪🔥",
      "{r} REPS NO BREAKS YOU'RE INSANE!! 🤯",
    ],
    _genZ: [
      "{r} reps?? that's literally unhinged fr 🔥",
      "ok {r} reps is giving stamina god tbh",
      "not you casually hitting {r} like it's nothing 💀",
    ],
    _sarcastic: [
      "{r} reps... were you just showing off or do you not know how to stop?",
      "Oh cool, {r} reps. Do you charge admission for these shows?",
      "{r}. I lost count before you did",
    ],
    _pirate: ["Blimey! {r} reps! Ye've got the endurance of a kraken! 🐙"],
    _british: ["{r} reps — absolutely outstanding stamina, well played"],
    _surfer: ["{r} reps dude! You're riding the longest wave! 🌊"],
    _anime: ["{r} REPS?! THIS ISN'T EVEN YOUR FINAL FORM!! 🔥"],
    _fallback: ["{r} reps — serious stamina 🔥", "That's {r}, not many can do that"],
  };

  // ─── GOOD VOLUME (12+) ─────────────────────────────────────

  static final _goodVolume = <String, List<String>>{
    _motivational: ["Solid volume — that's how you grow", "12+ and still controlled, nice work", "Good reps, clean form matters more than numbers"],
    _drillSergeant: ["Decent volume. But don't get lazy on form.", "12+ reps means you can go heavier. Think about THAT.", "Acceptable. Now make the next set BETTER."],
    _scientist: ["12+ reps — optimal hypertrophy range for this muscle group", "Good volume accumulation, ideal for sarcoplasmic growth", "Solid mechanical tension through full ROM"],
    _zenMaster: ["Good volume, found with patience", "Each rep was placed with care — that's growth", "Quality over quantity, but you had both"],
    _hypeBeast: ["VOLUME KING!! YOU'RE STACKING REPS LIKE A BOSS!! 💪", "12+ AND STILL GOING?! UNREAL!! 🔥"],
    _genZ: ["that volume is giving growth fr fr", "12+ reps? main character energy ngl"],
    _sarcastic: ["12 whole reps. Someone's been eating their vegetables", "Look at you, doing reps like a responsible adult"],
    _pirate: ["A fine volley of reps, ye sea dog!"],
    _british: ["Rather good volume there, well done indeed"],
    _surfer: ["Solid wave of reps bro, keep shredding 🤙"],
    _anime: ["YOUR POWER GROWS WITH EVERY REP!!"],
    _fallback: ["Solid volume, that's how you grow", "Good set, clean reps"],
  };

  // ─── PERFECT 10 ─────────────────────────────────────────────

  static final _perfectTen = <String, List<String>>{
    _motivational: ["10 for 10 — textbook set", "Clean 10, right in the sweet spot"],
    _drillSergeant: ["10 reps. Now imagine doing 12 next time. PUSH.", "10 reps done right. Barely satisfactory. Do better."],
    _scientist: ["10 reps — the intersection of strength and hypertrophy", "Optimal rep range for balanced fiber recruitment"],
    _zenMaster: ["10 reps — a complete cycle, perfectly round", "Balance in numbers, balance in effort"],
    _hypeBeast: ["PERFECT 10 BABY!! FLAWLESS!! ⭐🔥", "10 OUT OF 10!! YOU'RE THAT GUY!!"],
    _genZ: ["10 reps ate that up no crumbs 💅", "a clean 10? that's lowkey elite"],
    _sarcastic: ["10 reps. How perfectly average. No really, good job", "A clean 10 — the participation trophy of rep ranges"],
    _pirate: ["Ten cannon shots fired, captain! Direct hits all! 💥"],
    _british: ["A proper 10 — splendid work, that"],
    _surfer: ["Perfect 10 dude, like a surfing competition score 🏄"],
    _anime: ["10 REPS!! THE SACRED NUMBER!!"],
    _fallback: ["Clean 10 reps ⭐", "10 for 10, solid set"],
  };

  // ─── FIRST SET ──────────────────────────────────────────────

  static final _firstSet = <String, List<String>>{
    _motivational: ["Good first set — {remaining} left, stay locked in", "Dialed in early, that's the move", "Set 1 in the books, you're warmed up"],
    _drillSergeant: ["Set 1 done. {remaining} to go. DON'T SLOW DOWN.", "First set was easy? GOOD. It should be. Now suffer through the rest.", "That's ONE. You've got {remaining} more. MOVE."],
    _scientist: ["Set 1 complete — neuromuscular priming established for the remaining {remaining}", "First set activates motor patterns. Sets 2+ is where adaptation happens", "Baseline set logged. {remaining} more for sufficient volume"],
    _zenMaster: ["The journey of {remaining} sets begins with this one", "A strong root grows a strong tree — good first set", "Set 1 — you've planted the seed"],
    _hypeBeast: ["SET 1 DOWN AND IT WAS FIRE!! {remaining} MORE LET'S GOOO!! 🔥", "FIRST SET CRUSHED!! WE'RE JUST GETTING STARTED!! 💪🔥"],
    _genZ: ["first set slapped, {remaining} more to slay 💅", "set 1 was giving energy tbh, {remaining} left no cap"],
    _sarcastic: ["One set down, {remaining} to go. Try to look less surprised", "Set 1 done. Only {remaining} more chances to question your life choices"],
    _pirate: ["First broadside fired! {remaining} more salvos to go! ⚓"],
    _british: ["Set 1, rather nicely done. {remaining} remaining, carry on"],
    _surfer: ["First wave caught bro! {remaining} more sets to ride 🌊"],
    _anime: ["FIRST SET COMPLETE!! {remaining} MORE UNTIL ULTIMATE POWER!!"],
    _fallback: ["Set 1 done — {remaining} more to go", "Good start, {remaining} left"],
  };

  // ─── LAST SET ───────────────────────────────────────────────

  static final _lastSet = <String, List<String>>{
    _motivational: ["Last set done — you showed up and put in the work 🎯", "That's a wrap. Well earned.", "All sets complete — strong finish"],
    _drillSergeant: ["LAST SET DONE. You survived. BARELY. Now recover and come back STRONGER.", "Mission complete. I'll admit it — you didn't quit. Respect.", "DONE. Now eat, sleep, grow. That's an ORDER."],
    _scientist: ["All sets complete — sufficient volume for progressive overload", "Final set done. Recovery window opens now — protein within 2 hours", "Training stimulus delivered. Adaptation will follow with proper rest"],
    _zenMaster: ["The final rep falls into place — your practice is complete", "You began, you persisted, you finished. That is the way.", "Rest now. The work lives in your muscles"],
    _hypeBeast: ["LAST SET DONE BABY!! YOU ABSOLUTELY CRUSHED IT!! 🎯🔥💪", "IT'S OVEEEER!! YOU'RE A BEAST!! LET'S GOOO!! 🏆"],
    _genZ: ["last set done and it ate, period 💅🎯", "that's a wrap bestie, you slayed fr fr"],
    _sarcastic: ["Oh, the last set. How sad. Just kidding, you're probably thrilled", "Done! You can stop pretending to enjoy this now"],
    _pirate: ["All cannons fired, captain! The battle be won! 🏴‍☠️🎯"],
    _british: ["Final set, brilliantly done. Time for a proper rest ☕"],
    _surfer: ["Last wave ridden bro! Session's stoked! 🤙🌊"],
    _anime: ["FINAL SET!! YOUR TRAINING ARC IS COMPLETE!! 🎯✨"],
    _fallback: ["Last set done 🎯", "All sets complete — nice work"],
  };

  // ─── PENULTIMATE SET ────────────────────────────────────────

  static final _penultimateSet = <String, List<String>>{
    _motivational: ["One more — save the best for last", "Almost there, finish strong 💪", "Penultimate set done — bring it home"],
    _drillSergeant: ["ONE MORE SET. Give it EVERYTHING. No excuses.", "Almost done — that's NOT permission to coast. LAST SET, ALL OUT.", "You better make the final set your BEST set. GO."],
    _scientist: ["Penultimate set complete. Final set = maximum effort for adaptation", "One set remaining — this is where the growth stimulus peaks", "Last set incoming — push to near-failure for optimal gains"],
    _zenMaster: ["One more — let the final set be your offering", "Almost done. Stay present. One more mindful effort", "The last step is the most meaningful. Be here for it"],
    _hypeBeast: ["ONE MORE SET AND WE'RE DONE!! GIVE IT EVERYTHING!! 🔥💪", "ALMOST THERE!! FINISH LIKE A CHAMPION!! 🏆"],
    _genZ: ["one more set bestie you got this fr 💪", "almost done, last set better go crazy tho"],
    _sarcastic: ["One set left. Try to look enthusiastic about it", "Almost done! Just one more set of voluntary suffering"],
    _pirate: ["One more broadside, then we feast! ⚓"],
    _british: ["Penultimate set done — one more, give it proper effort"],
    _surfer: ["One more wave to catch bro, make it the biggest! 🌊"],
    _anime: ["ONE MORE SET!! GATHER YOUR REMAINING STRENGTH!!"],
    _fallback: ["One more set — finish strong", "Almost there, one more to go"],
  };

  // ─── GENERAL ENCOURAGEMENT ──────────────────────────────────

  static final _general = <String, List<String>>{
    _motivational: ["You're building something here 📈", "This is what consistency looks like", "Reps today, results tomorrow", "Stay tight, breathe, go again"],
    _drillSergeant: ["Don't just stand there. FOCUS on the next set.", "Pain is weakness leaving the body. EMBRACE IT.", "You signed up for this. Now EARN it.", "Rest is for recovery, not relaxation. STAY SHARP."],
    _scientist: ["Micro-tears forming now = muscle growth tomorrow", "Your body is adapting in real-time — trust the process", "Metabolic byproducts clearing — you'll be ready soon", "Progressive overload in action. This is how it works"],
    _zenMaster: ["Breathe in strength, breathe out doubt", "The iron doesn't judge. Neither should you.", "Be here now. The next set will come", "Stillness between sets is part of the practice"],
    _hypeBeast: ["YOU'RE ON FIRE TODAY!! 🔥🔥🔥", "BUILT DIFFERENT!! WIRED DIFFERENT!! 💪", "NOBODY CAN STOP YOU RN!! LET'S GOOO!!", "THIS IS YOUR MOMENT!! OWN IT!! 🏆"],
    _genZ: ["you're literally that girl/guy rn 💅", "giving gym rat energy and i'm here for it", "this workout is serving tbh", "not you being a whole athlete fr 🏆"],
    _sarcastic: ["Still going? Impressive stamina for someone who hit snooze 3 times", "You're doing great. The bar would clap if it had hands", "Another set. Your couch misses you, by the way", "Look at you, voluntarily lifting heavy things. Humanity is weird"],
    _pirate: ["Keep sailin', the treasure be close! 🏴‍☠️", "A pirate never quits the plunder! Arrr!", "Steady as she goes, ye salty dog!"],
    _british: ["Carry on, you're doing splendidly", "Keep calm and carry on lifting", "Rather good effort, keep it up old chap"],
    _surfer: ["Keep shredding bro, you're in the zone 🤙", "Ride the momentum dude!", "Stoked energy right now, keep flowing 🌊"],
    _anime: ["YOUR POWER IS GROWING!! DON'T STOP!! 🔥", "THE PROTAGONIST NEVER GIVES UP!!", "THIS IS YOUR TRAINING ARC!!"],
    _fallback: ["Keep going, you've got this", "Solid work so far", "Stay focused, next set is yours"],
  };

  // ─── TIMING-BASED COMPARISONS ───────────────────────────────

  static final _densityPR = <String, List<String>>{
    _motivational: ["More weight and didn't slow down — density PR 📈", "Heavier AND faster, that's real progress"],
    _drillSergeant: ["Heavier weight, same speed. THAT'S how you progress. MORE.", "You went up AND kept the pace. Outstanding."],
    _scientist: ["Increased load without time penalty — training density improved", "Weight up, tempo maintained — excellent progressive overload"],
    _zenMaster: ["Heavier iron, same calm pace — mastery in motion", "More weight flows just as easily — you've grown"],
    _hypeBeast: ["HEAVIER AND FASTER?! YOU'RE EVOLVING BRO!! 🔥💪", "DENSITY PR!! MORE WEIGHT, SAME SPEED!! INSANE!!"],
    _genZ: ["heavier and faster?? that's literally elite fr 📈", "density pr unlocked bestie 💅"],
    _sarcastic: ["Heavier and faster. Are you cheating or just getting good?", "More weight, less time. Show off."],
    _fallback: ["More weight, same pace — density PR", "Heavier without slowing down"],
  };

  static final _fasterSet = <String, List<String>>{
    _motivational: ["Same weight, {t}s faster — you're finding a groove", "{t} seconds quicker, same control — efficiency up"],
    _drillSergeant: ["{t}s faster. Good. Now keep that pace EVERY set.", "Faster. Better. Don't get sloppy though."],
    _scientist: ["{t}s faster at same load — improved neuromuscular efficiency", "Rate of force development up by {t}s — motor patterns optimizing"],
    _zenMaster: ["{t}s quicker yet just as present — flow state", "The weight moved easier this time — growth is quiet"],
    _hypeBeast: ["{t} SECONDS FASTER BRO!! YOU'RE LOCKED IN!! 🔥", "SAME WEIGHT BUT SPEEDIER!! GAINS!! 💪"],
    _genZ: ["{t}s faster no cap, you're built different", "that was quicker and it shows fr"],
    _sarcastic: ["{t}s faster. The bar barely had time to be scared", "Speed running your sets now? {t}s off, nice"],
    _fallback: ["{t}s faster than last set", "Quicker by {t}s — good pace"],
  };

  static final _workCapacity = <String, List<String>>{
    _motivational: ["Extra reps at the same pace — work capacity is up", "More reps, same time — your engine is growing"],
    _drillSergeant: ["More reps without slowing down. Your work capacity is GROWING.", "Same time, more output. That's what a soldier does."],
    _scientist: ["Volume increased without tempo cost — work capacity adaptation confirmed", "More reps at constant pace = improved metabolic efficiency"],
    _zenMaster: ["More reps flowed naturally — your capacity expands", "The body asked for more, and you delivered gently"],
    _hypeBeast: ["MORE REPS SAME TIME?! WORK CAPACITY GOING CRAZY!! 💪🔥"],
    _genZ: ["more reps same time?? work capacity unlocked fr"],
    _sarcastic: ["Oh, extra reps AND same pace? Someone's been eating their spinach"],
    _fallback: ["More reps, same pace — capacity up", "Extra reps without slowing down"],
  };

  static final _restResilience = <String, List<String>>{
    _motivational: ["Short rest and you still delivered — conditioning is real 💪", "Half the rest, full performance — that's fitness"],
    _drillSergeant: ["Short rest and STILL performed. Your recovery is getting FAST.", "Barely rested and didn't flinch. GOOD."],
    _scientist: ["Maintained output with reduced rest — aerobic base is solid", "Short rest interval, no performance drop — excellent recovery capacity"],
    _zenMaster: ["Brief pause, strong return — your body recovers with grace"],
    _hypeBeast: ["BARELY RESTED AND STILL CRUSHED IT?! BUILT DIFFERENT!! 🔥"],
    _genZ: ["skipped rest and still ate? conditioning goals fr"],
    _sarcastic: ["Skipped rest and still performed? Were you even tired?"],
    _fallback: ["Short rest, strong set — good conditioning"],
  };

  static final _heavierAndMore = <String, List<String>>{
    _motivational: ["More weight AND more reps — you're peaking 🔥", "Heavier and higher volume, everything's clicking"],
    _drillSergeant: ["Heavier AND more reps?! NOW we're talking! KEEP GOING!", "More weight, more reps. This is what getting STRONG looks like."],
    _scientist: ["Both load and volume increased — you're in a supercompensation window", "Weight and reps up simultaneously — rare and impressive adaptation"],
    _zenMaster: ["More weight, more reps — the mountain reveals new paths"],
    _hypeBeast: ["MORE WEIGHT!! MORE REPS!! YOU'RE UNSTOPPABLE!! 🏆🔥💪"],
    _genZ: ["heavier AND more reps?? nah you're peaking fr fr 🔥"],
    _sarcastic: ["Heavier and more reps. What, are you trying to make the rest of us look bad?"],
    _fallback: ["More weight and more reps — strong set"],
  };

  static final _consistentTempo = <String, List<String>>{
    _motivational: ["Same pace across sets — that's discipline", "Consistent tempo, consistent growth"],
    _drillSergeant: ["Same speed every set. Controlled. Disciplined. GOOD.", "Consistent tempo. That's how a professional trains."],
    _scientist: ["Tempo variance < 3s — excellent motor pattern consistency", "Consistent time under tension across sets — optimal for adaptation"],
    _zenMaster: ["Same rhythm, set after set — this is the practice", "Consistency is the heartbeat of progress"],
    _hypeBeast: ["CONSISTENT TEMPO EVERY SET!! MACHINE MODE!! 🤖💪"],
    _genZ: ["same pace every set, that's giving discipline ngl"],
    _sarcastic: ["Same speed every time. Are you a metronome?"],
    _fallback: ["Consistent tempo across sets", "Same pace — disciplined work"],
  };

  static final _normalFatigue = <String, List<String>>{
    _motivational: ["Taking a bit longer — that's normal fatigue, stay focused", "Slowing down is fine, just keep the form tight"],
    _scientist: ["Set took longer — metabolite accumulation is expected at this volume", "Slightly slower — normal neuromuscular fatigue pattern"],
    _zenMaster: ["The pace slows, the effort remains — honor the fatigue", "Slower today is still stronger than yesterday"],
    _fallback: ["A bit slower — normal fatigue, keep going"],
  };

  static final _shortRest = <String, List<String>>{
    _motivational: ["Short rest — let's see what you've got 💪", "Quick turnaround, stay sharp"],
    _drillSergeant: ["Short rest. Don't let it show in your reps.", "Barely rested. Make it count anyway."],
    _scientist: ["Reduced rest interval — expect 5-10% performance dip, that's normal"],
    _zenMaster: ["Brief pause — carry the calm into the next set"],
    _hypeBeast: ["NO REST NEEDED!! LET'S GO AGAIN!! 🔥"],
    _genZ: ["speed running rest? ok go off bestie"],
    _sarcastic: ["Wow, skipping rest. Bold strategy, let's see how it plays out"],
    _fallback: ["Short rest — stay focused"],
  };
}


/// Helper to map coaching style + tone to message pool keys
class _StyleKey {
  final String primary;
  final String secondary;

  const _StyleKey(this.primary, this.secondary);

  factory _StyleKey.from(String coachingStyle, String communicationTone) {
    // Tone overrides (specific communication tones have their own message pool)
    const toneOverrides = {
      'gen-z': 'gen-z',
      'sarcastic': 'sarcastic',
      'roast-mode': 'sarcastic',
      'pirate': 'pirate',
      'british': 'british',
      'surfer': 'surfer',
      'anime': 'anime',
    };

    // Style mapping
    const styleMap = {
      'motivational': 'motivational',
      'professional': 'motivational',
      'friendly': 'motivational',
      'tough-love': 'drill-sergeant',
      'drill-sergeant': 'drill-sergeant',
      'zen-master': 'zen-master',
      'hype-beast': 'hype-beast',
      'scientist': 'scientist',
      'comedian': 'sarcastic',
      'old-school': 'drill-sergeant',
      'college-coach': 'drill-sergeant',
    };

    final toneKey = toneOverrides[communicationTone];
    final styleKey = styleMap[coachingStyle] ?? 'fallback';

    // If tone has a specific override, use that as primary, style as secondary
    if (toneKey != null) {
      return _StyleKey(toneKey, styleKey);
    }
    return _StyleKey(styleKey, 'fallback');
  }
}
