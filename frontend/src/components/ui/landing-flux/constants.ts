// Per-row [speed, direction] config
export const ROW_CONFIGS: [number, number][] = [
  [0.9, 0.1],
  [0.2, -0.05],
  [0.1, 0.4],
  [0.4, 0.05],
  [0.12, 0.1],
  [0.12, 0.07],
  [0.6, -0.03],
  [0.7, -0.01],
];

export const INTER_ELEMENT_GAP = 16;
export const BAR_WIDTH = 2.5;
export const PILL_WIDTH = 80;
export const BROKEN_WIDTH = 5;

export const POSITIVE_LABELS = [
  'Correct tool selected',
  'Accurate response',
  'Helpful suggestion',
  'Clear explanation',
  'Good form detected',
  'On-target macros',
  'Consistent progress',
  'Optimal rest time',
];

export const NEGATIVE_LABELS = [
  'Hallucinated order status',
  'Incorrect calculation',
  'Missed context',
  'Off-topic response',
  'Poor form detected',
  'Missing nutrients',
  'Skipped rest day',
  'Overtraining risk',
];
