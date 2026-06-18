import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import '../services/api_client.dart';

/// Workstream F AI share features (cost-gated) — F1 photo restyle, F2 insight
/// line, F3 Day in Proof. Backend: backend/api/v1/share_ai.py.
///
/// Cost discipline lives server-side (kill-switch flags, per-user daily cap,
/// sha256(photo)+style cache, deterministic-first insight). This repository is
/// a thin typed client over those endpoints.

/// AI restyle preset styles. Wire values match _STYLE_PROMPTS in
/// backend/services/share_ai_service.py.
enum RestyleStyle { figurine, anime, comic, tradingCard }

extension RestyleStyleWire on RestyleStyle {
  String get wire {
    switch (this) {
      case RestyleStyle.figurine:
        return 'figurine';
      case RestyleStyle.anime:
        return 'anime';
      case RestyleStyle.comic:
        return 'comic';
      case RestyleStyle.tradingCard:
        return 'trading_card';
    }
  }

  String get label {
    switch (this) {
      case RestyleStyle.figurine:
        return 'Figurine';
      case RestyleStyle.anime:
        return 'Anime';
      case RestyleStyle.comic:
        return 'Comic';
      case RestyleStyle.tradingCard:
        return 'Trading Card';
    }
  }
}

/// Result of an F1 AI restyle. [watermark]/[disclosure] MUST be rendered on the
/// image (AI-edit transparency). [cached] true = served free from cache.
@immutable
class RestyleResult {
  final String url; // presigned S3 GET URL (24h)
  final String s3Key;
  final String style;
  final bool cached;
  final String? model;
  final String disclosure;
  final bool watermark;
  final RestyleQuota quota;

  const RestyleResult({
    required this.url,
    required this.s3Key,
    required this.style,
    required this.cached,
    required this.disclosure,
    required this.watermark,
    required this.quota,
    this.model,
  });

  factory RestyleResult.fromJson(Map<String, dynamic> j) => RestyleResult(
        url: j['url'] as String,
        s3Key: j['s3_key'] as String,
        style: j['style'] as String,
        cached: j['cached'] as bool? ?? false,
        model: j['model'] as String?,
        disclosure: j['disclosure'] as String? ?? 'AI-generated style',
        watermark: j['watermark'] as bool? ?? true,
        quota: RestyleQuota.fromJson(
            (j['quota'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}

@immutable
class RestyleQuota {
  final int usedToday;
  final int dailyCap;
  final int remaining;
  final bool enabled;

  const RestyleQuota({
    required this.usedToday,
    required this.dailyCap,
    required this.remaining,
    required this.enabled,
  });

  factory RestyleQuota.fromJson(Map<String, dynamic> j) => RestyleQuota(
        usedToday: j['used_today'] as int? ?? 0,
        dailyCap: j['daily_cap'] as int? ?? 0,
        remaining: j['remaining'] as int? ?? 0,
        enabled: j['enabled'] as bool? ?? false,
      );
}

/// An F2 insight line + its source (cache / coach_insight / deterministic /
/// ai_flash / none). [line] may be empty when the day has no data — show no row.
@immutable
class InsightLine {
  final String line;
  final String tone;
  final String source;
  final bool cached;

  const InsightLine({
    required this.line,
    required this.tone,
    required this.source,
    required this.cached,
  });

  bool get isEmpty => line.trim().isEmpty;

  factory InsightLine.fromJson(Map<String, dynamic> j) => InsightLine(
        line: j['line'] as String? ?? '',
        tone: j['tone'] as String? ?? 'supportive',
        source: j['source'] as String? ?? 'none',
        cached: j['cached'] as bool? ?? false,
      );
}

final shareAiRepositoryProvider = Provider<ShareAiRepository>((ref) {
  return ShareAiRepository(ref.watch(apiClientProvider));
});

class ShareAiRepository {
  final ApiClient _client;

  ShareAiRepository(this._client);

  /// F1 — transform a chosen photo into [style]. Explicit user trigger only.
  /// Throws on 429 (daily cap) / 503 (feature disabled) — surface to the user.
  Future<RestyleResult> aiRestyle({
    required String userId,
    required RestyleStyle style,
    Uint8List? imageBytes,
    String? imageKey,
    String filename = 'photo.jpg',
    String contentType = 'image/jpeg',
  }) async {
    assert(imageBytes != null || imageKey != null,
        'Provide imageBytes or imageKey');
    final form = FormData.fromMap({
      'user_id': userId,
      'style': style.wire,
      if (imageKey != null) 'image_key': imageKey,
      if (imageBytes != null)
        'file': MultipartFile.fromBytes(imageBytes,
            filename: filename, contentType: MediaType.parse(contentType)),
    });
    try {
      final res = await _client.post('/share/ai-restyle', data: form);
      return RestyleResult.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [ShareAI] restyle failed: $e');
      rethrow;
    }
  }

  /// F1 — read-only quota snapshot (used today / cap / remaining / enabled).
  Future<RestyleQuota> restyleQuota() async {
    final res = await _client.get('/share/ai-restyle/quota');
    return RestyleQuota.fromJson(res.data as Map<String, dynamic>);
  }

  /// F2 — one-liner for a workout card. [tone] = 'supportive' | 'savage'.
  Future<InsightLine> insightLineForWorkout(
      {required String workoutId, String tone = 'supportive'}) async {
    final res = await _client.get('/share/insight-line', queryParameters: {
      'workout_id': workoutId,
      'tone': tone,
    });
    return InsightLine.fromJson(res.data as Map<String, dynamic>);
  }

  /// F2 — one-liner for a single food log or a whole day.
  Future<InsightLine> insightLineForFood({
    String? foodLogId,
    String? date, // YYYY-MM-DD
    String tone = 'supportive',
  }) async {
    assert(foodLogId != null || date != null, 'Provide foodLogId or date');
    final res = await _client.get('/share/insight-line', queryParameters: {
      if (foodLogId != null) 'food_log_id': foodLogId,
      if (date != null) 'date': date,
      'tone': tone,
    });
    return InsightLine.fromJson(res.data as Map<String, dynamic>);
  }

  /// F3 — Day in Proof card data (PR + meal grade + streak + cached line).
  /// Returns the raw map; render directly (see backend share_data_service.day_in_proof).
  Future<Map<String, dynamic>> dayInProof({String? date}) async {
    final res = await _client.get('/share/day-in-proof', queryParameters: {
      if (date != null) 'date': date,
    });
    return (res.data as Map).cast<String, dynamic>();
  }
}
