part of 'exercise_preferences_repository.dart';

/// Methods extracted from FavoriteExercise
extension _FavoriteExerciseExt on FavoriteExercise {

  const FavoriteExercise({
    required this.id,
    required this.exerciseName,
    this.exerciseId,
    required this.addedAt,
  });


  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise_name': exerciseName,
    'exercise_id': exerciseId,
    'added_at': addedAt.toIso8601String(),
  };

}
