/// Deterministic, day-seeded sleep coaching tips for the Sleep detail screen.
///
/// Each pattern has a pool of ≥4 grounded variants (CDC / Sleep Foundation
/// guidance) per `feedback_dynamic_copy_not_robotic.md`. The variant is
/// picked by a day-seed so a tip is stable within a day but rotates across
/// days — never a single robotic template string.
///
/// Tips are chosen from the night's actual metrics; with no data the caller
/// shows nothing rather than a generic filler tip.
library;

/// One coaching tip — a short title + a one-line actionable body.
class SleepTip {
  final String title;
  final String body;

  const SleepTip(this.title, this.body);
}

/// Variant pools keyed by pattern. The day-seed picks one per pattern.
const Map<String, List<SleepTip>> _tipPools = {
  // Short duration vs goal.
  'short_duration': [
    SleepTip('Aim for an earlier bedtime',
        'You came up short of your sleep goal. Shifting lights-out 30 minutes earlier tonight closes most of the gap.'),
    SleepTip('Protect your wind-down',
        'A short night usually starts with a late start. Block the last hour before bed for low-stimulation activity.'),
    SleepTip('Bank a little extra',
        'Last night ran short of your target. An extra 20-30 minutes tonight helps clear the building debt.'),
    SleepTip('Anchor your wake time',
        'Keeping a fixed wake time and going to bed when sleepy is the most reliable way to lengthen sleep.'),
  ],
  // Low efficiency — lots of time in bed, less asleep.
  'low_efficiency': [
    SleepTip('Reserve the bed for sleep',
        'Efficiency was low — time in bed well above time asleep. Use the bed only for sleep so the association stays strong.'),
    SleepTip('Get up if sleep won\'t come',
        'If you are awake more than 20 minutes, leave the bed and return when drowsy. It rebuilds the sleep cue.'),
    SleepTip('Cool, dark, quiet',
        'Fragmented sleep often traces to the environment. A cooler, darker room raises efficiency.'),
    SleepTip('Trim the time in bed',
        'Spending less time in bed can paradoxically deepen sleep — match time in bed closer to time actually asleep.'),
  ],
  // Long sleep latency.
  'high_latency': [
    SleepTip('Wind down screens earlier',
        'It took a while to fall asleep. Dimming screens an hour before bed lets melatonin rise on schedule.'),
    SleepTip('Try a fixed pre-sleep routine',
        'A short, repeatable routine signals the body it is time to sleep and shortens the time to drift off.'),
    SleepTip('Watch late caffeine',
        'Caffeine can delay sleep onset for six hours or more. An earlier last cup helps you fall asleep faster.'),
    SleepTip('Park the to-do list',
        'A long latency often means a busy mind. Jotting tomorrow\'s tasks before bed clears it.'),
  ],
  // Irregular schedule — low regularity.
  'irregular': [
    SleepTip('Steady your sleep window',
        'Your bed and wake times drifted this week. A consistent schedule, even on weekends, is the strongest lever for quality.'),
    SleepTip('Pick one wake time',
        'Locking a single wake time every day pulls your whole schedule into a stable rhythm.'),
    SleepTip('Limit weekend drift',
        'Large weekend shifts act like jet lag. Keeping within an hour of your weekday times avoids the Monday slump.'),
    SleepTip('Morning light helps',
        'Getting daylight soon after waking strengthens your body clock and makes a regular schedule easier to hold.'),
  ],
  // Carrying meaningful sleep debt.
  'sleep_debt': [
    SleepTip('Chip away at the debt',
        'You are carrying a sleep deficit. A few consecutive nights slightly longer than usual repays it best.'),
    SleepTip('Consistency over catch-up',
        'One long lie-in won\'t fully clear debt. Several normal-but-on-target nights work better.'),
    SleepTip('Guard the next few nights',
        'With a deficit building, protecting bedtime for the next week matters more than any single night.'),
    SleepTip('Small, steady repayment',
        'Adding 20-30 minutes a night gradually clears accumulated debt without disrupting your rhythm.'),
  ],
  // A solid night — reinforce.
  'on_track': [
    SleepTip('Nice night — keep the rhythm',
        'You hit your sleep goal with good quality. Holding this schedule is what makes the gains stick.'),
    SleepTip('That\'s the pattern to repeat',
        'Solid duration and composition last night. Same bedtime tonight keeps the streak going.'),
    SleepTip('Recovery banked',
        'A full, efficient night like this is exactly what supports training and focus the next day.'),
    SleepTip('Consistency is paying off',
        'This is a strong night. Keeping your wake time fixed protects results like it.'),
  ],
};

/// Pick the coaching tips for a night, given its derived metrics.
///
/// Returns up to [maxTips] tips, most actionable first. Empty when there is
/// nothing meaningful to say (the caller then shows no tips section).
///
/// * [asleepMinutes] / [goalMinutes] — duration vs target.
/// * [efficiency] — 0.0-1.0 asleep/in-bed, or null when unknown.
/// * [latencyMinutes] — time to fall asleep, or null when unknown.
/// * [regularityScore] — 0-100 schedule consistency, or null with no history.
/// * [sleepDebtMinutes] — rolling deficit.
/// * [daySeed] — a stable per-day integer (e.g. days-since-epoch) so the
///   chosen variant rotates daily but is stable within a day.
List<SleepTip> sleepCoachingTips({
  required int asleepMinutes,
  required int goalMinutes,
  double? efficiency,
  int? latencyMinutes,
  int? regularityScore,
  required int sleepDebtMinutes,
  required int daySeed,
  int maxTips = 2,
}) {
  if (asleepMinutes <= 0) return const [];
  final goal = goalMinutes > 0 ? goalMinutes : 480;

  // Score each candidate pattern; higher = more worth surfacing.
  final candidates = <_Candidate>[];

  if (asleepMinutes < goal - 45) {
    candidates.add(_Candidate('short_duration', goal - asleepMinutes));
  }
  if (efficiency != null && efficiency < 0.82) {
    candidates.add(
        _Candidate('low_efficiency', ((0.82 - efficiency) * 1000).round()));
  }
  if (latencyMinutes != null && latencyMinutes > 30) {
    candidates.add(_Candidate('high_latency', latencyMinutes));
  }
  if (regularityScore != null && regularityScore < 70) {
    candidates.add(_Candidate('irregular', 70 - regularityScore));
  }
  if (sleepDebtMinutes > 120) {
    candidates.add(_Candidate('sleep_debt', sleepDebtMinutes));
  }

  // Nothing flagged → a single positive reinforcement tip.
  if (candidates.isEmpty) {
    final pool = _tipPools['on_track']!;
    return [pool[daySeed % pool.length]];
  }

  candidates.sort((a, b) => b.weight.compareTo(a.weight));
  final tips = <SleepTip>[];
  for (final c in candidates.take(maxTips)) {
    final pool = _tipPools[c.pattern]!;
    tips.add(pool[daySeed % pool.length]);
  }
  return tips;
}

class _Candidate {
  final String pattern;
  final int weight;
  const _Candidate(this.pattern, this.weight);
}
