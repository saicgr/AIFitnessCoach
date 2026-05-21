import 'package:dio/dio.dart';

/// One GIF result from GIPHY — a small preview rendition for the picker
/// grid and a larger rendition for the placed editor layer.
class GiphyGif {
  final String previewUrl;
  final String fullUrl;
  const GiphyGif({required this.previewUrl, required this.fullUrl});
}

/// GIPHY GIF search backing the food editor's sticker picker.
///
/// [_apiKey] is a GIPHY *client* key — GIPHY keys are designed to ship
/// inside client apps (read-only, rate-limited search) and cannot be kept
/// secret in a mobile binary regardless. Free tier, registered at
/// developers.giphy.com. Swap it via [_apiKey] if it is ever rotated.
class GiphyService {
  GiphyService._();

  static const String _apiKey = 'GUyG2xSANSz2e9WZSqYLzaCsZ6jUrANo';
  static const String _base = 'https://api.giphy.com/v1/gifs';
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  /// True when a usable key is configured — the editor hides the GIF tool
  /// otherwise rather than showing an empty picker.
  static bool get isConfigured =>
      _apiKey.isNotEmpty && _apiKey != 'YOUR_GIPHY_KEY';

  static Future<List<GiphyGif>> trending({int limit = 24}) {
    return _fetch('$_base/trending', {'limit': '$limit', 'rating': 'pg'});
  }

  static Future<List<GiphyGif>> search(String query, {int limit = 24}) {
    final q = query.trim();
    if (q.isEmpty) return trending(limit: limit);
    return _fetch('$_base/search', {
      'q': q,
      'limit': '$limit',
      'rating': 'pg',
    });
  }

  static Future<List<GiphyGif>> _fetch(
    String url,
    Map<String, String> params,
  ) async {
    if (!isConfigured) return const [];
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: {'api_key': _apiKey, ...params},
      );
      final data = res.data?['data'];
      if (data is! List) return const [];
      final out = <GiphyGif>[];
      for (final item in data) {
        if (item is! Map) continue;
        final images = item['images'];
        if (images is! Map) continue;
        final preview = _urlOf(images['fixed_width_small']) ??
            _urlOf(images['fixed_width']) ??
            _urlOf(images['downsized']);
        final full = _urlOf(images['downsized']) ??
            _urlOf(images['fixed_width']) ??
            _urlOf(images['original']);
        if (preview != null && full != null) {
          out.add(GiphyGif(previewUrl: preview, fullUrl: full));
        }
      }
      return out;
    } catch (_) {
      // Network / rate-limit failure — the picker shows an empty state.
      return const [];
    }
  }

  static String? _urlOf(dynamic rendition) {
    if (rendition is! Map) return null;
    final url = rendition['url'];
    return (url is String && url.isNotEmpty) ? url : null;
  }
}
