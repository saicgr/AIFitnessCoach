import 'package:json_annotation/json_annotation.dart';


part 'scores_part_readiness_level.dart';
part 'scores_part_fitness_score_data.dart';
part 'scores.g.dart';


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

