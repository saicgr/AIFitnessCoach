import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../services/api_client.dart';

/// Library repository provider
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(ref.watch(apiClientProvider));
});

/// Exercise search state
class ExerciseSearchState {
  final bool isLoading;
  final String? error;
  final List<LibraryExerciseItem> exercises;
  final List<String> bodyParts;
  final String? selectedBodyPart;
  final String searchQuery;

  const ExerciseSearchState({
    this.isLoading = false,
    this.error,
    this.exercises = const [],
    this.bodyParts = const [],
    this.selectedBodyPart,
    this.searchQuery = '',
  });

  ExerciseSearchState copyWith({
    bool? isLoading,
    String? error,
    List<LibraryExerciseItem>? exercises,
    List<String>? bodyParts,
    String? selectedBodyPart,
    String? searchQuery,
  }) {
    return ExerciseSearchState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      exercises: exercises ?? this.exercises,
      bodyParts: bodyParts ?? this.bodyParts,
      selectedBodyPart: selectedBodyPart ?? this.selectedBodyPart,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Library exercise item
class LibraryExerciseItem {
  final String id;
  final String name;
  final String? bodyPart;
  final String? equipment;
  final String? targetMuscle;
  final String? gifUrl;
  final String? videoUrl;
  final String? imageUrl;
  final String? difficulty;
  final String? instructions;

  LibraryExerciseItem({
    required this.id,
    required this.name,
    this.bodyPart,
    this.equipment,
    this.targetMuscle,
    this.gifUrl,
    this.videoUrl,
    this.imageUrl,
    this.difficulty,
    this.instructions,
  });

  factory LibraryExerciseItem.fromJson(Map<String, dynamic> json) {
    return LibraryExerciseItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['exercise_name'] ?? '',
      bodyPart: json['body_part'],
      equipment: json['equipment'],
      targetMuscle: json['target_muscle'],
      gifUrl: json['gif_url'],
      videoUrl: json['video_url'],
      imageUrl: json['image_url'],
      difficulty: json['difficulty_level'] ?? json['difficulty'],
      instructions: json['instructions'],
    );
  }
}

/// Filter option with name and count
class FilterOption {
  final String name;
  final int count;

  const FilterOption({required this.name, required this.count});
}

/// Smart search exercise item with relevance scoring
class SmartSearchExerciseItem extends LibraryExerciseItem {
  final double relevanceScore;
  final List<String> matchSources;

  SmartSearchExerciseItem({
    required super.id,
    required super.name,
    super.bodyPart,
    super.equipment,
    super.targetMuscle,
    super.gifUrl,
    super.videoUrl,
    super.imageUrl,
    super.difficulty,
    super.instructions,
    this.relevanceScore = 0.0,
    this.matchSources = const [],
  });

  bool get isSemanticMatch => matchSources.contains('semantic');

  factory SmartSearchExerciseItem.fromJson(Map<String, dynamic> json) {
    return SmartSearchExerciseItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      bodyPart: json['body_part'],
      equipment: json['equipment'],
      targetMuscle: json['target_muscle'],
      gifUrl: json['gif_url'],
      videoUrl: json['video_url'],
      imageUrl: json['image_url'],
      difficulty: json['difficulty_level']?.toString(),
      instructions: json['instructions'],
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
      matchSources: (json['match_sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// Response wrapper for smart search
class SmartSearchResponse {
  final List<SmartSearchExerciseItem> results;
  final String query;
  final int total;
  final double searchTimeMs;
  final bool cacheHit;
  final String? correction;

  const SmartSearchResponse({
    required this.results,
    required this.query,
    required this.total,
    required this.searchTimeMs,
    required this.cacheHit,
    this.correction,
  });

  factory SmartSearchResponse.fromJson(Map<String, dynamic> json) {
    return SmartSearchResponse(
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => SmartSearchExerciseItem.fromJson(e))
              .toList() ??
          [],
      query: json['query'] ?? '',
      total: json['total'] as int? ?? 0,
      searchTimeMs: (json['search_time_ms'] as num?)?.toDouble() ?? 0.0,
      cacheHit: json['cache_hit'] as bool? ?? false,
      correction: json['correction'] as String?,
    );
  }
}

/// Exercise search provider
final exerciseSearchProvider =
    StateNotifierProvider<ExerciseSearchNotifier, ExerciseSearchState>((ref) {
  return ExerciseSearchNotifier(ref.watch(libraryRepositoryProvider));
});

/// Exercise search notifier
class ExerciseSearchNotifier extends StateNotifier<ExerciseSearchState> {
  final LibraryRepository _repository;

  ExerciseSearchNotifier(this._repository) : super(const ExerciseSearchState()) {
    loadBodyParts();
  }

  Future<void> loadBodyParts() async {
    try {
      final bodyParts = await _repository.getBodyParts();
      state = state.copyWith(bodyParts: bodyParts);
    } catch (e) {
      debugPrint('❌ Error loading body parts: $e');
    }
  }

  Future<void> searchExercises({String? query, String? bodyPart}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: query ?? state.searchQuery,
      selectedBodyPart: bodyPart,
    );

    try {
      final exercises = await _repository.searchExercises(
        query: query ?? state.searchQuery,
        bodyPart: bodyPart ?? state.selectedBodyPart,
      );
      state = state.copyWith(isLoading: false, exercises: exercises);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearSearch() {
    state = const ExerciseSearchState();
    loadBodyParts();
  }
}

/// Library repository
class LibraryRepository {
  final ApiClient _client;

  LibraryRepository(this._client);

  /// Get all body parts
  Future<List<String>> getBodyParts() async {
    try {
      final response = await _client.get('${ApiConstants.library}/exercises/body-parts');
      if (response.statusCode == 200) {
        return List<String>.from(response.data as List);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting body parts: $e');
      return [];
    }
  }

  /// Search exercises
  Future<List<LibraryExerciseItem>> searchExercises({
    String? query,
    String? bodyPart,
    String? equipment,
    String? exerciseTypes,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit};
      if (query != null && query.isNotEmpty) {
        params['search'] = query;
      }
      if (bodyPart != null && bodyPart.isNotEmpty) {
        params['body_parts'] = bodyPart;
      }
      if (equipment != null && equipment.isNotEmpty) {
        params['equipment'] = equipment;
      }
      if (exerciseTypes != null && exerciseTypes.isNotEmpty) {
        params['exercise_types'] = exerciseTypes;
      }

      final response = await _client.get(
        '${ApiConstants.library}/exercises',
        queryParameters: params,
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => LibraryExerciseItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // Silently ignore cancelled requests
      if (e is DioException && e.type == DioExceptionType.cancel) {
        return [];
      }
      debugPrint('❌ Error searching exercises: $e');
      return [];
    }
  }

  /// Get filter options (body parts, equipment, exercise types with counts)
  Future<Map<String, List<FilterOption>>> getFilterOptions() async {
    try {
      final response = await _client.get(
        '${ApiConstants.library}/exercises/filter-options',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = <String, List<FilterOption>>{};

        for (final key in ['body_parts', 'equipment', 'exercise_types']) {
          if (data[key] != null) {
            result[key] = (data[key] as List)
                .map((item) => FilterOption(
                      name: item['name']?.toString() ?? '',
                      count: item['count'] as int? ?? 0,
                    ))
                .where((f) => f.name.isNotEmpty)
                .toList();
          }
        }
        return result;
      }
      return {};
    } catch (e) {
      debugPrint('❌ Error getting filter options: $e');
      return {};
    }
  }

  /// Get exercise by ID
  Future<LibraryExerciseItem?> getExercise(String exerciseId) async {
    try {
      final response = await _client.get('${ApiConstants.library}/exercises/$exerciseId');
      if (response.statusCode == 200) {
        return LibraryExerciseItem.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting exercise: $e');
      return null;
    }
  }

  /// Smart search exercises (hybrid fuzzy + semantic)
  Future<SmartSearchResponse> smartSearchExercises({
    required String query,
    String? equipment,
    String? bodyParts,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final params = <String, dynamic>{
        'q': query,
        'limit': limit,
      };
      if (equipment != null && equipment.isNotEmpty) {
        params['equipment'] = equipment;
      }
      if (bodyParts != null && bodyParts.isNotEmpty) {
        params['body_parts'] = bodyParts;
      }

      final response = await _client.get(
        '${ApiConstants.library}/exercises/smart-search',
        queryParameters: params,
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        return SmartSearchResponse.fromJson(response.data);
      }
      return SmartSearchResponse(
        results: [],
        query: query,
        total: 0,
        searchTimeMs: 0,
        cacheHit: false,
      );
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        return SmartSearchResponse(
          results: [],
          query: query,
          total: 0,
          searchTimeMs: 0,
          cacheHit: false,
        );
      }
      debugPrint('Error in smart search: $e');
      return SmartSearchResponse(
        results: [],
        query: query,
        total: 0,
        searchTimeMs: 0,
        cacheHit: false,
      );
    }
  }

  /// Get exercises grouped by body part
  Future<Map<String, List<LibraryExerciseItem>>> getExercisesGrouped() async {
    try {
      final response = await _client.get('${ApiConstants.library}/exercises/grouped');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(
              key,
              (value as List).map((e) => LibraryExerciseItem.fromJson(e)).toList(),
            ));
      }
      return {};
    } catch (e) {
      debugPrint('❌ Error getting grouped exercises: $e');
      return {};
    }
  }
}
