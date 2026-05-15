// Weekly training volume recommendations per muscle group.
//
// Built on two evidence bases:
//   1. Schoenfeld, Ogborn, Krieger (2017) meta-analysis showing a dose-response
//      relationship between weekly set volume and hypertrophy. Roughly 10-20
//      hard sets per muscle per week covers the productive range for most
//      lifters.
//   2. Renaissance Periodization volume landmarks (Israetel, Hoffmann, Smith
//      2017) which split volume into four bands: MV, MEV, MAV, MRV.
//
// MV  = Maintenance Volume. The floor needed to retain current muscle.
// MEV = Minimum Effective Volume. The least amount that still produces growth.
// MAV = Maximum Adaptive Volume. Sweet spot for most lifters most of the time.
// MRV = Maximum Recoverable Volume. The ceiling before recovery breaks down.
//
// References:
//   Schoenfeld BJ, Ogborn D, Krieger JW (2017). Dose-response relationship
//     between weekly resistance training volume and increases in muscle mass.
//     Journal of Sports Sciences 35(11): 1073-1082.
//   Israetel M, Hoffmann J, Smith CW (2017). Scientific Principles of
//     Hypertrophy Training. Renaissance Periodization.

export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced';

export interface MuscleVolumeLandmarks {
  muscle: string;
  mv: number;          // Maintenance Volume (sets/wk)
  mev: number;         // Minimum Effective Volume
  mavLow: number;      // Maximum Adaptive Volume (low end)
  mavHigh: number;     // Maximum Adaptive Volume (high end)
  mrv: number;         // Maximum Recoverable Volume
  notes?: string;
}

// Base landmarks calibrated for an intermediate lifter. Beginner and advanced
// scaling is applied at calculation time.
export const BASE_VOLUME_LANDMARKS: MuscleVolumeLandmarks[] = [
  { muscle: 'Chest', mv: 6, mev: 10, mavLow: 12, mavHigh: 20, mrv: 22 },
  { muscle: 'Back', mv: 6, mev: 10, mavLow: 14, mavHigh: 22, mrv: 25 },
  { muscle: 'Shoulders (side delts)', mv: 8, mev: 12, mavLow: 16, mavHigh: 22, mrv: 26 },
  { muscle: 'Biceps', mv: 5, mev: 8, mavLow: 14, mavHigh: 20, mrv: 26 },
  { muscle: 'Triceps', mv: 4, mev: 6, mavLow: 10, mavHigh: 14, mrv: 18 },
  { muscle: 'Quads', mv: 6, mev: 8, mavLow: 12, mavHigh: 18, mrv: 20 },
  { muscle: 'Hamstrings', mv: 4, mev: 6, mavLow: 10, mavHigh: 16, mrv: 20 },
  { muscle: 'Glutes', mv: 0, mev: 4, mavLow: 8, mavHigh: 12, mrv: 16 },
  { muscle: 'Calves', mv: 6, mev: 8, mavLow: 12, mavHigh: 16, mrv: 20 },
  { muscle: 'Abs', mv: 0, mev: 0, mavLow: 12, mavHigh: 20, mrv: 25 },
  { muscle: 'Forearms', mv: 2, mev: 4, mavLow: 6, mavHigh: 12, mrv: 16 },
];

export const EXPERIENCE_MULTIPLIER: Record<ExperienceLevel, number> = {
  beginner: 0.7,      // less work needed to drive adaptation
  intermediate: 1.0,
  advanced: 1.1,      // slightly higher tolerance and need for stimulus
};

export interface AdjustedVolume extends MuscleVolumeLandmarks {
  experience: ExperienceLevel;
  multiplier: number;
}

// Scale every landmark by the experience multiplier. Round to whole sets,
// keep MV at zero if the base muscle has zero MV (glutes, abs).
export function adjustForExperience(
  landmarks: MuscleVolumeLandmarks,
  experience: ExperienceLevel,
): AdjustedVolume {
  const m = EXPERIENCE_MULTIPLIER[experience];
  const scale = (v: number): number => Math.round(v * m);
  return {
    ...landmarks,
    mv: landmarks.mv === 0 ? 0 : scale(landmarks.mv),
    mev: landmarks.mev === 0 ? 0 : scale(landmarks.mev),
    mavLow: scale(landmarks.mavLow),
    mavHigh: scale(landmarks.mavHigh),
    mrv: scale(landmarks.mrv),
    experience,
    multiplier: m,
  };
}

export function calculateAllVolumes(experience: ExperienceLevel): AdjustedVolume[] {
  return BASE_VOLUME_LANDMARKS.map((l) => adjustForExperience(l, experience));
}

// Quick reference: format a landmark row as a single human-readable string.
export function describeRange(v: AdjustedVolume): string {
  return `MV ${v.mv} / MEV ${v.mev} / MAV ${v.mavLow}-${v.mavHigh} / MRV ${v.mrv}`;
}
