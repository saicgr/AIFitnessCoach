part of 'exercise_preferences_repository.dart';

/// Methods extracted from FavoriteExercise
extension FavoriteExerciseJsonExt on FavoriteExercise {

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise_name': exerciseName,
    'exercise_id': exerciseId,
    'added_at': addedAt.toIso8601String(),
  };

}
