/// Sound preferences model for customizable workout sounds.
///
/// This addresses user feedback about cheesy sounds being customizable.
/// NOTE: No "applause" option available - user specifically didn't want it.
library;

/// Available countdown sound types
enum CountdownSoundType {
  beep,
  chime,
  voice,
  tick,
  none,
}

/// Available completion sound types (NO APPLAUSE)
enum CompletionSoundType {
  chime,
  bell,
  success,
  fanfare,
  none,
}

class SoundPreferences {
  /// Whether to play countdown sounds (3, 2, 1)
  final bool countdownSoundEnabled;

  /// Type of countdown sound
  final CountdownSoundType countdownSoundType;

  /// Whether to play completion sounds
  final bool completionSoundEnabled;

  /// Type of completion sound (NO APPLAUSE)
  final CompletionSoundType completionSoundType;

  /// Whether to play rest timer sounds
  final bool restTimerSoundEnabled;

  /// Type of rest timer sound
  final CountdownSoundType restTimerSoundType;

  /// Volume for sound effects (0.0 to 1.0)
  final double soundEffectsVolume;

  const SoundPreferences({
    this.countdownSoundEnabled = true,
    this.countdownSoundType = CountdownSoundType.beep,
    this.completionSoundEnabled = true,
    this.completionSoundType = CompletionSoundType.chime,
    this.restTimerSoundEnabled = true,
    this.restTimerSoundType = CountdownSoundType.beep,
    this.soundEffectsVolume = 0.8,
  });

  SoundPreferences copyWith({
    bool? countdownSoundEnabled,
    CountdownSoundType? countdownSoundType,
    bool? completionSoundEnabled,
    CompletionSoundType? completionSoundType,
    bool? restTimerSoundEnabled,
    CountdownSoundType? restTimerSoundType,
    double? soundEffectsVolume,
  }) {
    return SoundPreferences(
      countdownSoundEnabled: countdownSoundEnabled ?? this.countdownSoundEnabled,
      countdownSoundType: countdownSoundType ?? this.countdownSoundType,
      completionSoundEnabled: completionSoundEnabled ?? this.completionSoundEnabled,
      completionSoundType: completionSoundType ?? this.completionSoundType,
      restTimerSoundEnabled: restTimerSoundEnabled ?? this.restTimerSoundEnabled,
      restTimerSoundType: restTimerSoundType ?? this.restTimerSoundType,
      soundEffectsVolume: soundEffectsVolume ?? this.soundEffectsVolume,
    );
  }

  factory SoundPreferences.fromJson(Map<String, dynamic> json) {
    return SoundPreferences(
      countdownSoundEnabled: json['countdown_sound_enabled'] as bool? ?? true,
      countdownSoundType: _countdownSoundTypeFromString(
        json['countdown_sound_type'] as String?,
      ),
      completionSoundEnabled: json['completion_sound_enabled'] as bool? ?? true,
      completionSoundType: _completionSoundTypeFromString(
        json['completion_sound_type'] as String?,
      ),
      restTimerSoundEnabled: json['rest_timer_sound_enabled'] as bool? ?? true,
      restTimerSoundType: _countdownSoundTypeFromString(
        json['rest_timer_sound_type'] as String?,
      ),
      soundEffectsVolume: (json['sound_effects_volume'] as num?)?.toDouble() ?? 0.8,
    );
  }

  Map<String, dynamic> toJson() => {
        'countdown_sound_enabled': countdownSoundEnabled,
        'countdown_sound_type': countdownSoundType.name,
        'completion_sound_enabled': completionSoundEnabled,
        'completion_sound_type': completionSoundType.name,
        'rest_timer_sound_enabled': restTimerSoundEnabled,
        'rest_timer_sound_type': restTimerSoundType.name,
        'sound_effects_volume': soundEffectsVolume,
      };

  static CountdownSoundType _countdownSoundTypeFromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'beep':
        return CountdownSoundType.beep;
      case 'chime':
        return CountdownSoundType.chime;
      case 'voice':
        return CountdownSoundType.voice;
      case 'tick':
        return CountdownSoundType.tick;
      case 'none':
        return CountdownSoundType.none;
      default:
        return CountdownSoundType.beep;
    }
  }

  static CompletionSoundType _completionSoundTypeFromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'chime':
        return CompletionSoundType.chime;
      case 'bell':
        return CompletionSoundType.bell;
      case 'success':
        return CompletionSoundType.success;
      case 'fanfare':
        return CompletionSoundType.fanfare;
      case 'none':
        return CompletionSoundType.none;
      default:
        return CompletionSoundType.chime;
    }
  }
}

extension CountdownSoundTypeExtension on CountdownSoundType {
  String get displayName {
    switch (this) {
      case CountdownSoundType.beep:
        return 'Beep';
      case CountdownSoundType.chime:
        return 'Chime';
      case CountdownSoundType.voice:
        return 'Voice';
      case CountdownSoundType.tick:
        return 'Tick';
      case CountdownSoundType.none:
        return 'None';
    }
  }

  String get description {
    switch (this) {
      case CountdownSoundType.beep:
        return 'Simple beep sound';
      case CountdownSoundType.chime:
        return 'Soft chime tone';
      case CountdownSoundType.voice:
        return 'Voice countdown';
      case CountdownSoundType.tick:
        return 'Clock tick sound';
      case CountdownSoundType.none:
        return 'No sound';
    }
  }
}

extension CompletionSoundTypeExtension on CompletionSoundType {
  String get displayName {
    switch (this) {
      case CompletionSoundType.chime:
        return 'Chime';
      case CompletionSoundType.bell:
        return 'Bell';
      case CompletionSoundType.success:
        return 'Success';
      case CompletionSoundType.fanfare:
        return 'Fanfare';
      case CompletionSoundType.none:
        return 'None';
    }
  }

  String get description {
    switch (this) {
      case CompletionSoundType.chime:
        return 'Gentle completion chime';
      case CompletionSoundType.bell:
        return 'Clear bell tone';
      case CompletionSoundType.success:
        return 'Achievement sound';
      case CompletionSoundType.fanfare:
        return 'Brief fanfare';
      case CompletionSoundType.none:
        return 'No sound';
    }
  }
}
