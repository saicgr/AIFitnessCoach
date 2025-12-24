import '../../../data/models/exercise.dart';

/// Pagination limit for exercises - load 100 at a time for faster initial load
const int exercisesPageSize = 100;

/// State class for paginated exercises
class ExercisesState {
  final List<LibraryExercise> exercises;
  final bool isLoading;
  final bool hasMore;
  final int offset;
  final String? error;

  const ExercisesState({
    this.exercises = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.offset = 0,
    this.error,
  });

  ExercisesState copyWith({
    List<LibraryExercise>? exercises,
    bool? isLoading,
    bool? hasMore,
    int? offset,
    String? error,
  }) {
    return ExercisesState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExercisesState &&
        other.isLoading == isLoading &&
        other.hasMore == hasMore &&
        other.offset == offset &&
        other.error == error &&
        _listEquals(other.exercises, exercises);
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      exercises.hashCode ^
      isLoading.hashCode ^
      hasMore.hashCode ^
      offset.hashCode ^
      error.hashCode;
}
