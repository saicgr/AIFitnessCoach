// Deload week recommender.
//
// Inputs are subjective and objective fatigue markers gathered from the lifter.
// Output is a yes/no recommendation, an urgency tier, and a suggested deload
// format. The thresholds come from a synthesis of:
//   Helms ER, Cronin J, Storey A, Zourdos MC (2014). Application of the
//     Repetitions-in-Reserve-Based Rating of Perceived Exertion scale for
//     resistance training. Strength and Conditioning Journal 38(4): 42-49.
//   Smith I et al. Training load monitoring literature (subjective wellness
//     scores predict overreaching ~5-7 days in advance).

export interface DeloadInputs {
  weeksSinceDeload: number;
  averageRpeLast2Weeks: number;     // 0-10 RPE scale
  sleepQuality: number;             // 1-10 self-report
  motivation: number;               // 1-10 self-report
  jointsHurting: number;            // count of joints with persistent pain
}

export type DeloadUrgency = 'none' | 'low' | 'medium' | 'high';
export type DeloadFormat = 'volume' | 'intensity' | 'active-recovery';

export interface DeloadRecommendation {
  shouldDeload: boolean;
  urgency: DeloadUrgency;
  reasons: string[];
  format: DeloadFormat;
  formatDescription: string;
  score: number;                    // internal 0-10 fatigue score
}

// Each signal contributes points to a fatigue score. Score >= 6 triggers a
// deload. Score 4-5 is borderline; we still recommend if any single hard
// signal trips (weeks >= 6, joints >= 2).
export function recommendDeload(inputs: DeloadInputs): DeloadRecommendation {
  const reasons: string[] = [];
  let score = 0;

  if (inputs.weeksSinceDeload >= 8) {
    score += 4;
    reasons.push(`${inputs.weeksSinceDeload} weeks since last deload. Past the standard 4-6 week ceiling.`);
  } else if (inputs.weeksSinceDeload >= 6) {
    score += 3;
    reasons.push(`${inputs.weeksSinceDeload} weeks since last deload. Time to schedule one.`);
  } else if (inputs.weeksSinceDeload >= 4) {
    score += 1;
    reasons.push(`${inputs.weeksSinceDeload} weeks since deload. Approaching the typical window.`);
  }

  if (inputs.averageRpeLast2Weeks >= 9.5) {
    score += 3;
    reasons.push(`Average RPE ${inputs.averageRpeLast2Weeks.toFixed(1)} is near-maximal every session.`);
  } else if (inputs.averageRpeLast2Weeks >= 9) {
    score += 2;
    reasons.push(`Average RPE ${inputs.averageRpeLast2Weeks.toFixed(1)} for two weeks is a strong fatigue signal.`);
  }

  if (inputs.sleepQuality < 6 && inputs.motivation < 6) {
    score += 2;
    reasons.push(`Sleep ${inputs.sleepQuality}/10 and motivation ${inputs.motivation}/10 together suggest systemic fatigue.`);
  } else if (inputs.sleepQuality < 5) {
    score += 1;
    reasons.push(`Sleep ${inputs.sleepQuality}/10 is low enough to impair recovery.`);
  } else if (inputs.motivation < 5) {
    score += 1;
    reasons.push(`Motivation ${inputs.motivation}/10 is a leading indicator of overreaching.`);
  }

  if (inputs.jointsHurting >= 2) {
    score += 3;
    reasons.push(`${inputs.jointsHurting} joints with persistent pain. Deload now.`);
  } else if (inputs.jointsHurting === 1) {
    score += 1;
    reasons.push('One joint flaring. Watch the next session and consider a deload.');
  }

  const shouldDeload = score >= 6 || inputs.weeksSinceDeload >= 6 || inputs.jointsHurting >= 2;
  let urgency: DeloadUrgency = 'none';
  if (score >= 8) urgency = 'high';
  else if (score >= 6) urgency = 'medium';
  else if (score >= 3) urgency = 'low';

  if (!shouldDeload && reasons.length === 0) {
    reasons.push('No strong fatigue signals. Keep accumulating volume.');
  }

  const { format, formatDescription } = chooseFormat(inputs);

  return { shouldDeload, urgency, reasons, format, formatDescription, score };
}

function chooseFormat(inputs: DeloadInputs): {
  format: DeloadFormat;
  formatDescription: string;
} {
  // Joint pain or very high RPE means intensity is the problem. Drop weights.
  if (inputs.jointsHurting >= 2 || inputs.averageRpeLast2Weeks >= 9.5) {
    return {
      format: 'active-recovery',
      formatDescription:
        'Active recovery deload. 30% of normal volume, 60% of normal weight. Goal is blood flow, not stimulus.',
    };
  }
  if (inputs.averageRpeLast2Weeks >= 9) {
    return {
      format: 'intensity',
      formatDescription:
        'Intensity deload. Keep your normal set count. Drop weight to 70% of working sets. RPE 5-6.',
    };
  }
  return {
    format: 'volume',
    formatDescription:
      'Volume deload. Cut sets by 50%, keep intensity normal. Preserves the strength stimulus while letting tissues recover.',
  };
}
