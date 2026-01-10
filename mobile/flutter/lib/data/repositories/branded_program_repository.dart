import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../models/branded_program.dart';
import '../services/api_client.dart';

/// Branded program repository provider
final brandedProgramRepositoryProvider = Provider<BrandedProgramRepository>((ref) {
  return BrandedProgramRepository(ref.watch(apiClientProvider));
});

/// Repository for branded program API operations
class BrandedProgramRepository {
  final ApiClient _client;

  BrandedProgramRepository(this._client);

  /// Get all branded programs
  Future<List<BrandedProgram>> getBrandedPrograms({
    String? category,
    String? difficulty,
    int? limit,
    int? offset,
  }) async {
    try {
      debugPrint('🔍 [BrandedProgram] Fetching branded programs...');

      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _client.get(
        '${ApiConstants.library}/branded-programs',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final programs = data
            .map((json) => BrandedProgram.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [BrandedProgram] Fetched ${programs.length} programs');
        return programs;
      }

      debugPrint('❌ [BrandedProgram] Failed with status: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ [BrandedProgram] Error fetching programs: $e');
      rethrow;
    }
  }

  /// Get featured programs
  Future<List<BrandedProgram>> getFeaturedPrograms() async {
    try {
      debugPrint('🔍 [BrandedProgram] Fetching featured programs...');

      final response = await _client.get(
        '${ApiConstants.library}/branded-programs/featured',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final programs = data
            .map((json) => BrandedProgram.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [BrandedProgram] Fetched ${programs.length} featured programs');
        return programs;
      }

      return [];
    } catch (e) {
      debugPrint('❌ [BrandedProgram] Error fetching featured programs: $e');
      rethrow;
    }
  }

  /// Get program categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _client.get(
        '${ApiConstants.library}/branded-programs/categories',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((e) => e.toString()).toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ [BrandedProgram] Error fetching categories: $e');
      return [];
    }
  }

  /// Get a single branded program by ID
  Future<BrandedProgram?> getProgram(String programId) async {
    try {
      debugPrint('🔍 [BrandedProgram] Fetching program: $programId');

      final response = await _client.get(
        '${ApiConstants.library}/branded-programs/$programId',
      );

      if (response.statusCode == 200) {
        return BrandedProgram.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      debugPrint('❌ [BrandedProgram] Error fetching program: $e');
      rethrow;
    }
  }

  /// Assign a program to the current user
  Future<UserProgram?> assignProgram({
    required String userId,
    required String programId,
    String? customName,
  }) async {
    try {
      debugPrint('🔍 [BrandedProgram] Assigning program $programId to user $userId');

      final response = await _client.post(
        '${ApiConstants.library}/branded-programs/assign',
        data: {
          'user_id': userId,
          'program_id': programId,
          if (customName != null && customName.isNotEmpty)
            'custom_name': customName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [BrandedProgram] Program assigned successfully');
        return UserProgram.fromJson(response.data as Map<String, dynamic>);
      }

      debugPrint('❌ [BrandedProgram] Failed to assign: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [BrandedProgram] Error assigning program: $e');
      rethrow;
    }
  }

  /// Get user's current active program
  Future<UserProgram?> getCurrentProgram({required String userId}) async {
    try {
      debugPrint('🔍 [BrandedProgram] Fetching current program for user $userId');

      final response = await _client.get(
        '${ApiConstants.library}/branded-programs/current',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ [BrandedProgram] Got current program');
        return UserProgram.fromJson(response.data as Map<String, dynamic>);
      }

      debugPrint('ℹ️ [BrandedProgram] No current program found');
      return null;
    } on DioException catch (e) {
      // 404 is expected when user has no current program - not an error
      if (e.response?.statusCode == 404) {
        debugPrint('ℹ️ [BrandedProgram] No current program (404)');
        return null;
      }
      debugPrint('❌ [BrandedProgram] Error fetching current program: $e');
      return null;
    } catch (e) {
      debugPrint('❌ [BrandedProgram] Error fetching current program: $e');
      return null;
    }
  }

  /// Rename the user's current program
  Future<UserProgram?> renameProgram({
    required String userId,
    required String newName,
  }) async {
    try {
      debugPrint('🔍 [BrandedProgram] Renaming program for user $userId to "$newName"');

      final response = await _client.patch(
        '${ApiConstants.library}/branded-programs/current/rename',
        data: {
          'user_id': userId,
          'custom_name': newName,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [BrandedProgram] Program renamed successfully');
        return UserProgram.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      debugPrint('❌ [BrandedProgram] Error renaming program: $e');
      rethrow;
    }
  }

  /// End/deactivate the user's current program
  Future<bool> endProgram({required String userId}) async {
    try {
      debugPrint('🔍 [BrandedProgram] Ending program for user $userId');

      final response = await _client.delete(
        '${ApiConstants.library}/branded-programs/current',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ [BrandedProgram] Program ended successfully');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [BrandedProgram] Error ending program: $e');
      return false;
    }
  }

  /// Get user's program history
  Future<List<UserProgram>> getProgramHistory({required String userId}) async {
    try {
      final response = await _client.get(
        '${ApiConstants.library}/branded-programs/history',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data
            .map((json) => UserProgram.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ [BrandedProgram] Error fetching program history: $e');
      return [];
    }
  }
}
