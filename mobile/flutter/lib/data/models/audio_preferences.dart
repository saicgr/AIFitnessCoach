/// Audio preferences model.
///
/// Represents user audio settings for managing background music,
/// voice announcements, and audio ducking during workouts.
class AudioPreferences {
  /// Unique identifier for the preferences record
  final String id;

  /// The user ID these preferences belong to
  final String userId;

  /// Whether to allow background music (e.g., Spotify) to continue playing
  /// When true, the app won't interrupt/pause other audio apps
  final bool allowBackgroundMusic;

  /// Volume level for text-to-speech announcements (0.0 to 1.0)
  final double ttsVolume;

  /// Whether to duck (lower) background music volume during voice announcements
  final bool audioDucking;

  /// Volume level to duck background music to (0.0 to 1.0)
  /// Only used when audioDucking is enabled
  final double duckVolumeLevel;

  /// Whether to mute voice announcements during exercise videos
  final bool muteDuringVideo;

  /// When the preferences were created
  final DateTime createdAt;

  /// When the preferences were last updated
  final DateTime updatedAt;

  const AudioPreferences({
    required this.id,
    required this.userId,
    this.allowBackgroundMusic = true,
    this.ttsVolume = 1.0,
    this.audioDucking = true,
    this.duckVolumeLevel = 0.3,
    this.muteDuringVideo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create default preferences for a new user
  factory AudioPreferences.defaults(String userId) {
    final now = DateTime.now();
    return AudioPreferences(
      id: '',
      userId: userId,
      allowBackgroundMusic: true,
      ttsVolume: 1.0,
      audioDucking: true,
      duckVolumeLevel: 0.3,
      muteDuringVideo: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from JSON response
  factory AudioPreferences.fromJson(Map<String, dynamic> json) {
    return AudioPreferences(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      allowBackgroundMusic: json['allow_background_music'] as bool? ?? true,
      ttsVolume: (json['tts_volume'] as num?)?.toDouble() ?? 1.0,
      audioDucking: json['audio_ducking'] as bool? ?? true,
      duckVolumeLevel: (json['duck_volume_level'] as num?)?.toDouble() ?? 0.3,
      muteDuringVideo: json['mute_during_video'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'allow_background_music': allowBackgroundMusic,
      'tts_volume': ttsVolume,
      'audio_ducking': audioDucking,
      'duck_volume_level': duckVolumeLevel,
      'mute_during_video': muteDuringVideo,
    };
  }

  /// Create a copy with updated fields
  AudioPreferences copyWith({
    String? id,
    String? userId,
    bool? allowBackgroundMusic,
    double? ttsVolume,
    bool? audioDucking,
    double? duckVolumeLevel,
    bool? muteDuringVideo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AudioPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      allowBackgroundMusic: allowBackgroundMusic ?? this.allowBackgroundMusic,
      ttsVolume: ttsVolume ?? this.ttsVolume,
      audioDucking: audioDucking ?? this.audioDucking,
      duckVolumeLevel: duckVolumeLevel ?? this.duckVolumeLevel,
      muteDuringVideo: muteDuringVideo ?? this.muteDuringVideo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if background music handling is fully enabled
  bool get isBackgroundMusicFullyEnabled =>
      allowBackgroundMusic && audioDucking;

  @override
  String toString() {
    return 'AudioPreferences(id: $id, userId: $userId, '
        'allowBackgroundMusic: $allowBackgroundMusic, ttsVolume: $ttsVolume, '
        'audioDucking: $audioDucking, duckVolumeLevel: $duckVolumeLevel, '
        'muteDuringVideo: $muteDuringVideo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioPreferences &&
        other.id == id &&
        other.userId == userId &&
        other.allowBackgroundMusic == allowBackgroundMusic &&
        other.ttsVolume == ttsVolume &&
        other.audioDucking == audioDucking &&
        other.duckVolumeLevel == duckVolumeLevel &&
        other.muteDuringVideo == muteDuringVideo;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      allowBackgroundMusic,
      ttsVolume,
      audioDucking,
      duckVolumeLevel,
      muteDuringVideo,
    );
  }
}
