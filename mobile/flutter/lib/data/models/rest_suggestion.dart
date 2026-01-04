/// Rest Suggestion Model
///
/// Represents an AI-powered rest time suggestion during active workouts.
/// Contains the suggested rest duration, personalized reasoning,
/// and a quick option for time-pressed users.
library;

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rest_suggestion.g.dart';

/// Rest duration category
enum RestCategory {
  short,    // <= 60 seconds
  moderate, // 61-120 seconds
  long,     // 121-180 seconds
  extended, // > 180 seconds
}

/// AI-generated rest time suggestion
@JsonSerializable()
class RestSuggestion extends Equatable {
  /// Recommended rest duration in seconds
  @JsonKey(name: 'suggested_seconds')
  final int suggestedSeconds;

  /// Personalized explanation for the suggestion
  final String reasoning;

  /// Shorter rest option for time-pressed users
  @JsonKey(name: 'quick_option_seconds')
  final int quickOptionSeconds;

  /// Category of rest duration (short, moderate, long, extended)
  @JsonKey(name: 'rest_category')
  final String restCategory;

  /// Whether this suggestion was powered by AI
  @JsonKey(name: 'ai_powered')
  final bool aiPowered;

  const RestSuggestion({
    required this.suggestedSeconds,
    required this.reasoning,
    required this.quickOptionSeconds,
    required this.restCategory,
    this.aiPowered = true,
  });

  factory RestSuggestion.fromJson(Map<String, dynamic> json) =>
      _$RestSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$RestSuggestionToJson(this);

  /// Get the rest category as enum
  RestCategory get category {
    switch (restCategory.toLowerCase()) {
      case 'short':
        return RestCategory.short;
      case 'moderate':
        return RestCategory.moderate;
      case 'long':
        return RestCategory.long;
      case 'extended':
        return RestCategory.extended;
      default:
        return RestCategory.moderate;
    }
  }

  /// Format suggested seconds as display string (e.g., "2:30" or "90s")
  String get suggestedDisplay {
    if (suggestedSeconds >= 60) {
      final minutes = suggestedSeconds ~/ 60;
      final seconds = suggestedSeconds % 60;
      if (seconds > 0) {
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
      return '${minutes}m';
    }
    return '${suggestedSeconds}s';
  }

  /// Format quick option as display string
  String get quickOptionDisplay {
    if (quickOptionSeconds >= 60) {
      final minutes = quickOptionSeconds ~/ 60;
      final seconds = quickOptionSeconds % 60;
      if (seconds > 0) {
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
      return '${minutes}m';
    }
    return '${quickOptionSeconds}s';
  }

  /// Get a user-friendly category label
  String get categoryLabel {
    switch (category) {
      case RestCategory.short:
        return 'Quick Recovery';
      case RestCategory.moderate:
        return 'Standard Rest';
      case RestCategory.long:
        return 'Full Recovery';
      case RestCategory.extended:
        return 'Extended Rest';
    }
  }

  /// Check if there's a meaningful difference between suggested and quick option
  bool get hasQuickOption =>
      quickOptionSeconds < suggestedSeconds &&
      (suggestedSeconds - quickOptionSeconds) >= 15;

  /// Get the time saved by choosing quick option
  int get timeSavedSeconds => suggestedSeconds - quickOptionSeconds;

  /// Format time saved as display string
  String get timeSavedDisplay {
    final saved = timeSavedSeconds;
    if (saved >= 60) {
      final minutes = saved ~/ 60;
      final seconds = saved % 60;
      if (seconds > 0) {
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
      return '${minutes}m';
    }
    return '${saved}s';
  }

  @override
  List<Object?> get props => [
        suggestedSeconds,
        reasoning,
        quickOptionSeconds,
        restCategory,
        aiPowered,
      ];

  RestSuggestion copyWith({
    int? suggestedSeconds,
    String? reasoning,
    int? quickOptionSeconds,
    String? restCategory,
    bool? aiPowered,
  }) {
    return RestSuggestion(
      suggestedSeconds: suggestedSeconds ?? this.suggestedSeconds,
      reasoning: reasoning ?? this.reasoning,
      quickOptionSeconds: quickOptionSeconds ?? this.quickOptionSeconds,
      restCategory: restCategory ?? this.restCategory,
      aiPowered: aiPowered ?? this.aiPowered,
    );
  }
}
