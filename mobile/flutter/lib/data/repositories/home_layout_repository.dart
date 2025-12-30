import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_layout.dart';
import '../services/api_client.dart';

/// Home layout repository provider
final homeLayoutRepositoryProvider = Provider<HomeLayoutRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeLayoutRepository(apiClient);
});

/// Repository for home screen layout customization API calls
class HomeLayoutRepository {
  final ApiClient _apiClient;

  HomeLayoutRepository(this._apiClient);

  /// Get all layouts for a user
  Future<List<HomeLayout>> getLayouts(String userId) async {
    try {
      debugPrint('🔍 [Layouts] Fetching layouts for user $userId');

      final response = await _apiClient.get('/layouts/user/$userId');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final layouts = data
            .map((json) => HomeLayout.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [Layouts] Fetched ${layouts.length} layouts');
        return layouts;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Layouts] Error fetching layouts: $e');
      rethrow;
    }
  }

  /// Get the active layout for a user (creates default if none exists)
  Future<HomeLayout> getActiveLayout(String userId) async {
    try {
      debugPrint('🔍 [Layouts] Fetching active layout for user $userId');

      final response = await _apiClient.get('/layouts/user/$userId/active');

      if (response.statusCode == 200) {
        final layout =
            HomeLayout.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [Layouts] Fetched active layout: ${layout.name}');
        return layout;
      }

      throw Exception('Failed to get active layout');
    } catch (e) {
      debugPrint('❌ [Layouts] Error fetching active layout: $e');
      rethrow;
    }
  }

  /// Create a new layout
  Future<HomeLayout> createLayout({
    required String userId,
    required String name,
    required List<HomeTile> tiles,
    String? templateId,
  }) async {
    try {
      debugPrint('🔍 [Layouts] Creating layout: $name');

      final response = await _apiClient.post(
        '/layouts/user/$userId',
        data: {
          'name': name,
          'tiles': tiles.map((t) => t.toJson()).toList(),
          'template_id': templateId,
        },
      );

      if (response.statusCode == 201) {
        debugPrint('✅ [Layouts] Layout created successfully');
        return HomeLayout.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Failed to create layout');
    } catch (e) {
      debugPrint('❌ [Layouts] Error creating layout: $e');
      rethrow;
    }
  }

  /// Update an existing layout
  Future<HomeLayout> updateLayout({
    required String layoutId,
    required String userId,
    String? name,
    List<HomeTile>? tiles,
  }) async {
    try {
      debugPrint('🔍 [Layouts] Updating layout $layoutId');

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (tiles != null) data['tiles'] = tiles.map((t) => t.toJson()).toList();

      final response = await _apiClient.put(
        '/layouts/$layoutId',
        data: data,
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Layouts] Layout updated successfully');
        return HomeLayout.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Failed to update layout');
    } catch (e) {
      debugPrint('❌ [Layouts] Error updating layout: $e');
      rethrow;
    }
  }

  /// Delete a layout
  Future<void> deleteLayout({
    required String layoutId,
    required String userId,
  }) async {
    try {
      debugPrint('🔍 [Layouts] Deleting layout $layoutId');

      final response = await _apiClient.delete(
        '/layouts/$layoutId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Layouts] Layout deleted successfully');
        return;
      }

      throw Exception('Failed to delete layout');
    } catch (e) {
      debugPrint('❌ [Layouts] Error deleting layout: $e');
      rethrow;
    }
  }

  /// Activate a layout (deactivates all others)
  Future<HomeLayout> activateLayout({
    required String layoutId,
    required String userId,
  }) async {
    try {
      debugPrint('🔍 [Layouts] Activating layout $layoutId');

      final response = await _apiClient.post(
        '/layouts/$layoutId/activate',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Layouts] Layout activated successfully');
        return HomeLayout.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Failed to activate layout');
    } catch (e) {
      debugPrint('❌ [Layouts] Error activating layout: $e');
      rethrow;
    }
  }

  /// Get all system templates
  Future<List<HomeLayoutTemplate>> getTemplates() async {
    try {
      debugPrint('🔍 [Layouts] Fetching layout templates');

      final response = await _apiClient.get('/layouts/templates');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final templates = data
            .map((json) =>
                HomeLayoutTemplate.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [Layouts] Fetched ${templates.length} templates');
        return templates;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Layouts] Error fetching templates: $e');
      rethrow;
    }
  }

  /// Create a layout from a template
  Future<HomeLayout> createFromTemplate({
    required String userId,
    required String templateId,
    String? name,
  }) async {
    try {
      debugPrint('🔍 [Layouts] Creating layout from template $templateId');

      final queryParams = <String, dynamic>{};
      if (name != null) queryParams['name'] = name;

      final response = await _apiClient.post(
        '/layouts/user/$userId/from-template/$templateId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 201) {
        debugPrint('✅ [Layouts] Layout created from template successfully');
        return HomeLayout.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Failed to create layout from template');
    } catch (e) {
      debugPrint('❌ [Layouts] Error creating layout from template: $e');
      rethrow;
    }
  }
}
