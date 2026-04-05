import 'package:json_annotation/json_annotation.dart';


part 'scores_part_readiness_level.dart';
part 'scores_part_fitness_score_data.dart';


/// Strength level classification
enum StrengthLevel {
  @JsonValue('beginner')
  beginner,
  @JsonValue('novice')
  novice,
  @JsonValue('intermediate')
  intermediate,
  @JsonValue('advanced')
  advanced,
  @JsonValue('elite')
  elite,
}

// ============================================================================
// Readiness Models
// ============================================================================

/// Request model for daily readiness check-in
@JsonSerializable()

/// Response model for readiness data
@JsonSerializable()

/// Response model for readiness history
@JsonSerializable()

// ============================================================================
// Strength Score Models
// ============================================================================

/// Response model for muscle group strength score
@JsonSerializable()

/// Response model for all strength scores
@JsonSerializable()

/// Response model for detailed muscle group strength
@JsonSerializable()

// ============================================================================
// Personal Records Models
// ============================================================================

/// Response model for a personal record
@JsonSerializable()

/// Response model for PR statistics
@JsonSerializable()

// ============================================================================
// DOTS / Wilks Score Model
// ============================================================================

@JsonSerializable()

@JsonSerializable()

// ============================================================================
// Overview/Dashboard Model
// ============================================================================

/// Combined dashboard response
@JsonSerializable()

// ============================================================================
// Nutrition Score Models
// ============================================================================

/// Response model for weekly nutrition score
@JsonSerializable()

// ============================================================================
// Fitness Score Models
// ============================================================================

/// Response model for overall fitness score
@JsonSerializable()

/// Response model for fitness score with breakdown
@JsonSerializable()
