import 'dart:math';

import '../data/models/mood.dart';
import '../data/models/workout.dart';
import '../data/models/workout_style.dart';

/// Decorates a freshly-generated [Workout] with mood-appropriate flavoring:
///
///   • Mood-themed workout name (e.g. "Fury Unleashed" for Angry + Hell)
///   • Opening quote shown on the workout start screen
///   • Music vibe caption
///   • Breath prompt config (for pre-start screen to consume)
///   • Optional cooldown finisher for high-intensity moods
///   • Optional gratitude closer for calm/restorative moods
///
/// All of this is persisted inside `generationMetadata` so the active
/// workout screen can read it without needing a new column.
class MoodWorkoutWrapper {
  static final _rand = Random();

  /// Apply mood-specific decorations to [workout]. Returns a copy; never
  /// mutates the input.
  static Workout decorate(
    Workout workout, {
    required Mood mood,
    required WorkoutStyle style,
    required String difficulty,
  }) {
    final name = _pickName(mood, style, difficulty);
    final quote = _pickQuote(mood);
    final musicVibe = _musicVibeFor(mood);
    final breath = _breathConfig(mood);
    final wantsCooldown = _wantsCooldown(mood, difficulty);
    final wantsGratitude = _wantsGratitude(mood);

    return workout.copyWith(
      name: name,
      generationMetadata: {
        ...?workout.generationMetadata,
        'mood_name': name,
        'mood_quote': quote,
        'mood_music_vibe': musicVibe,
        if (breath != null) 'mood_breath_prompt': breath,
        'mood_include_cooldown': wantsCooldown,
        'mood_include_gratitude': wantsGratitude,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Naming
  // ---------------------------------------------------------------------------

  static const _namesByMood = <Mood, List<String>>{
    Mood.great: [
      'Peak Energy Surge',
      'On-Fire Session',
      'Full Throttle',
      'Peak Output',
      'Go Mode',
    ],
    Mood.good: [
      'Steady Climb',
      'Quality Session',
      'Clean Work',
      'Dialed In',
      'Balanced Build',
    ],
    Mood.motivated: [
      'Beast Mode',
      'Send It',
      'Heavy Hands',
      'Progress Push',
      'Lift Heavy Live Well',
    ],
    Mood.angry: [
      'Fury Unleashed',
      'Burn It Off',
      'Scorched Earth',
      'Rage Release',
      'Blow the Steam',
      'Red Line Run',
    ],
    Mood.calm: [
      'Quiet Flow',
      'Peaceful Power',
      'Still Water',
      'Gentle Rhythm',
      'Unhurried Session',
    ],
    Mood.stressed: [
      'Stress Release Flow',
      'Down-Regulate',
      'Wind Down',
      'Softening Session',
      'Exhale Hour',
    ],
    Mood.anxious: [
      'Settle the System',
      'Steady Pace',
      'Ground and Flow',
      'Smooth Reset',
      'Low and Slow',
    ],
    Mood.tired: [
      'Gentle Recovery',
      'Light Touch',
      'Easy Mover',
      'Recharge Flow',
      'Rest-Day Ready',
    ],
    Mood.low: [
      'Small Wins',
      'Showed Up',
      'Kind Effort',
      'One Brick at a Time',
      'Foot Forward',
    ],
    Mood.focused: [
      'Deep Work Session',
      'Dial In',
      'Precision Mode',
      'Locked In',
      'Structured Session',
    ],
  };

  static String _pickName(Mood mood, WorkoutStyle style, String difficulty) {
    final pool = _namesByMood[mood] ?? const ['Mood Session'];
    return pool[_rand.nextInt(pool.length)];
  }

  // ---------------------------------------------------------------------------
  // Quotes
  // ---------------------------------------------------------------------------

  static const _quotesByMood = <Mood, List<String>>{
    Mood.great: [
      'Ride the momentum.',
      'Strike while it\'s hot.',
      'Peak state — spend it.',
    ],
    Mood.good: [
      'Show up today. Compound tomorrow.',
      'Steady beats sporadic.',
      'Reps, not heroics.',
    ],
    Mood.motivated: [
      'Strong today, stronger tomorrow.',
      'The bar is neutral. You decide the story.',
      'Lift heavy. Live light.',
    ],
    Mood.angry: [
      'Channel it into the work.',
      'Don\'t fight it — spend it.',
      'Turn the fire into fuel.',
    ],
    Mood.calm: [
      'Move like the breath.',
      'You don\'t have to rush anything today.',
      'Slow is smooth. Smooth is strong.',
    ],
    Mood.stressed: [
      'One long exhale at a time.',
      'Less grip, more flow.',
      'Your nervous system will thank you.',
    ],
    Mood.anxious: [
      'Settle in. Steady on.',
      'You don\'t have to outpace anything.',
      'The next breath is always easier.',
    ],
    Mood.tired: [
      'Rest is part of the work.',
      'Gentle counts.',
      'Low is still forward.',
    ],
    Mood.low: [
      'You showed up. That\'s the win.',
      'Small moves matter.',
      'Kind to yourself, and forward.',
    ],
    Mood.focused: [
      'One rep at a time. One set at a time.',
      'Attention is the work.',
      'Stay with it.',
    ],
  };

  static String _pickQuote(Mood mood) {
    final pool = _quotesByMood[mood] ?? const ['Let\'s go.'];
    return pool[_rand.nextInt(pool.length)];
  }

  // ---------------------------------------------------------------------------
  // Music / breath / wrappers
  // ---------------------------------------------------------------------------

  static String _musicVibeFor(Mood mood) {
    switch (mood) {
      case Mood.great:
      case Mood.motivated:
        return 'Upbeat 140+ BPM — pump-up';
      case Mood.angry:
        return 'Hard-hitting 150+ BPM — release';
      case Mood.good:
      case Mood.focused:
        return 'Deep focus instrumental';
      case Mood.calm:
      case Mood.stressed:
        return 'Ambient / lo-fi';
      case Mood.anxious:
        return 'Slow-tempo instrumental';
      case Mood.tired:
        return 'Chill acoustic';
      case Mood.low:
        return 'Warm and uplifting';
    }
  }

  /// Breath-pattern config consumed by the pre-start screen. Returns null
  /// when no breath prompt is recommended for the mood.
  static Map<String, Object>? _breathConfig(Mood mood) {
    switch (mood) {
      case Mood.anxious:
        return const {
          'pattern': 'box_4_4_4_4',
          'label': 'Box breath',
          'inhale_s': 4,
          'hold1_s': 4,
          'exhale_s': 4,
          'hold2_s': 4,
          'duration_s': 30,
        };
      case Mood.stressed:
        return const {
          'pattern': 'four_seven_eight',
          'label': '4-7-8 breath',
          'inhale_s': 4,
          'hold1_s': 7,
          'exhale_s': 8,
          'hold2_s': 0,
          'duration_s': 30,
        };
      case Mood.angry:
        return const {
          'pattern': 'power_breath',
          'label': 'Power breath',
          'inhale_s': 4,
          'hold1_s': 0,
          'exhale_s': 6,
          'hold2_s': 0,
          'duration_s': 30,
        };
      default:
        return null;
    }
  }

  static bool _wantsCooldown(Mood mood, String difficulty) {
    // Append a light cooldown for high-intensity moods so users don't
    // "stew in cortisol" after a hard session.
    if (mood == Mood.angry) return true;
    if (mood == Mood.great && (difficulty == 'hard' || difficulty == 'hell')) {
      return true;
    }
    if (mood == Mood.motivated && difficulty == 'hell') return true;
    return false;
  }

  static bool _wantsGratitude(Mood mood) {
    return mood == Mood.calm || mood == Mood.stressed || mood == Mood.low;
  }
}
