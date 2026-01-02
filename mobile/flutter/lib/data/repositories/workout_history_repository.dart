import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

/// Repository for managing workout history imports.
/// Allows users to manually enter past workout data to seed AI learning.
class WorkoutHistoryRepository {
  final ApiClient _apiClient;

  WorkoutHistoryRepository(this._apiClient);

  /// Import a single workout history entry.
  Future<ImportSummary> importSingleEntry({
    required String userId,
    required String exerciseName,
    required double weightKg,
    required int reps,
    int sets = 1,
    DateTime? performedAt,
    String? notes,
  }) async {
    try {
      debugPrint('📥 [WorkoutHistory] Importing: $exerciseName @ ${weightKg}kg');

      final response = await _apiClient.post(
        '/workout-history/import',
        data: {
          'user_id': userId,
          'exercise_name': exerciseName,
          'weight_kg': weightKg,
          'reps': reps,
          'sets': sets,
          if (performedAt != null) 'performed_at': performedAt.toIso8601String(),
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [WorkoutHistory] Import successful');
        return ImportSummary.fromJson(data);
      }

      throw Exception('Failed to import workout history');
    } catch (e) {
      debugPrint('❌ [WorkoutHistory] Import error: $e');
      rethrow;
    }
  }

  /// Bulk import multiple workout history entries.
  Future<ImportSummary> bulkImport({
    required String userId,
    required List<WorkoutHistoryEntry> entries,
    String source = 'manual',
  }) async {
    try {
      debugPrint('📥 [WorkoutHistory] Bulk importing ${entries.length} entries');

      final response = await _apiClient.post(
        '/workout-history/import/bulk',
        data: {
          'user_id': userId,
          'entries': entries.map((e) => e.toJson()).toList(),
          'source': source,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [WorkoutHistory] Bulk import: ${data['imported_count']} imported');
        return ImportSummary.fromJson(data);
      }

      throw Exception('Failed to bulk import workout history');
    } catch (e) {
      debugPrint('❌ [WorkoutHistory] Bulk import error: $e');
      rethrow;
    }
  }

  /// Get user's imported workout history.
  Future<List<WorkoutHistoryRecord>> getHistory({
    required String userId,
    String? exerciseName,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (exerciseName != null) {
        queryParams['exercise_name'] = exerciseName;
      }

      final response = await _apiClient.get(
        '/workout-history/user/$userId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((e) => WorkoutHistoryRecord.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ [WorkoutHistory] Get history error: $e');
      return [];
    }
  }

  /// Get aggregated strength summary from all sources.
  Future<List<StrengthSummary>> getStrengthSummary({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/workout-history/user/$userId/strength-summary',
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((e) => StrengthSummary.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ [WorkoutHistory] Get strength summary error: $e');
      return [];
    }
  }

  /// Delete a single history entry.
  Future<bool> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/workout-history/user/$userId/entry/$entryId',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [WorkoutHistory] Delete error: $e');
      return false;
    }
  }

  /// Clear all imported history for a user.
  Future<int> clearAllHistory({required String userId}) async {
    try {
      final response = await _apiClient.delete(
        '/workout-history/user/$userId/clear',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['deleted_count'] as int? ?? 0;
      }

      return 0;
    } catch (e) {
      debugPrint('❌ [WorkoutHistory] Clear history error: $e');
      return 0;
    }
  }
}

/// Entry for bulk import.
class WorkoutHistoryEntry {
  final String exerciseName;
  final double weightKg;
  final int reps;
  final int sets;
  final DateTime? performedAt;
  final String? notes;

  WorkoutHistoryEntry({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    this.sets = 1,
    this.performedAt,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'exercise_name': exerciseName,
        'weight_kg': weightKg,
        'reps': reps,
        'sets': sets,
        if (performedAt != null) 'performed_at': performedAt!.toIso8601String(),
        if (notes != null) 'notes': notes,
      };
}

/// Summary of import operation.
class ImportSummary {
  final int importedCount;
  final int failedCount;
  final List<String> exercisesAffected;
  final String message;

  ImportSummary({
    required this.importedCount,
    required this.failedCount,
    required this.exercisesAffected,
    required this.message,
  });

  factory ImportSummary.fromJson(Map<String, dynamic> json) {
    return ImportSummary(
      importedCount: json['imported_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
      exercisesAffected: (json['exercises_affected'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      message: json['message'] as String? ?? '',
    );
  }
}

/// A single workout history record.
class WorkoutHistoryRecord {
  final String id;
  final String exerciseName;
  final double weightKg;
  final int reps;
  final int sets;
  final DateTime performedAt;
  final String? notes;
  final String source;
  final DateTime createdAt;

  WorkoutHistoryRecord({
    required this.id,
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.sets,
    required this.performedAt,
    this.notes,
    required this.source,
    required this.createdAt,
  });

  factory WorkoutHistoryRecord.fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryRecord(
      id: json['id'] as String,
      exerciseName: json['exercise_name'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      reps: json['reps'] as int,
      sets: json['sets'] as int,
      performedAt: DateTime.parse(json['performed_at'] as String),
      notes: json['notes'] as String?,
      source: json['source'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Aggregated strength summary for an exercise.
class StrengthSummary {
  final String exerciseName;
  final double maxWeightKg;
  final double lastWeightKg;
  final int totalSessions;
  final DateTime lastPerformed;
  final String source; // "imported", "completed_workouts", or "both"

  StrengthSummary({
    required this.exerciseName,
    required this.maxWeightKg,
    required this.lastWeightKg,
    required this.totalSessions,
    required this.lastPerformed,
    required this.source,
  });

  factory StrengthSummary.fromJson(Map<String, dynamic> json) {
    return StrengthSummary(
      exerciseName: json['exercise_name'] as String,
      maxWeightKg: (json['max_weight_kg'] as num).toDouble(),
      lastWeightKg: (json['last_weight_kg'] as num).toDouble(),
      totalSessions: json['total_sessions'] as int,
      lastPerformed: DateTime.parse(json['last_performed'] as String),
      source: json['source'] as String,
    );
  }

  /// Returns a user-friendly description of the data source.
  String get sourceDescription {
    switch (source) {
      case 'imported':
        return 'From imported history';
      case 'completed_workouts':
        return 'From completed workouts';
      case 'both':
        return 'From workouts & imports';
      default:
        return source;
    }
  }
}
