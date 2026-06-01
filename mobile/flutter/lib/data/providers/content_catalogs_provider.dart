/// Content-catalog providers — daily lesson, knowledge cards, daily
/// meditation, sleep story, and premium-preview rotation.
///
/// Each provider hits the matching read-only endpoint in
/// `backend/api/v1/content_catalogs.py`. All payloads are tiny (one to three
/// short records) so the providers are `autoDispose` — they refresh on
/// re-watch when the home screen rebuilds.
///
/// No fallback / mock data: if the call fails the provider surfaces the
/// error and the consuming tile renders `SizedBox.shrink()` — matches the
/// project rule "never silently degrade".
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

// ---------------------------------------------------------------------------
// Daily lesson
// ---------------------------------------------------------------------------

class DailyLessonApi {
  final String id;
  final String slug;
  final String title;
  final String body;
  final int readMin;
  final String category;

  const DailyLessonApi({
    required this.id,
    required this.slug,
    required this.title,
    required this.body,
    required this.readMin,
    required this.category,
  });

  factory DailyLessonApi.fromJson(Map<String, dynamic> j) => DailyLessonApi(
        id: (j['id'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        readMin: (j['read_min'] as num?)?.toInt() ?? 3,
        category: (j['category'] ?? '').toString(),
      );

  String get readMinutesLabel => '$readMin min read';

  /// First sentence (or up to ~140 chars) of the body, suitable as the
  /// preview line under the title in the card.
  String get preview {
    if (body.isEmpty) return '';
    final first = body.split('. ').first.trim();
    if (first.length <= 140) {
      return first.endsWith('.') || first.endsWith('!') || first.endsWith('?')
          ? first
          : '$first.';
    }
    return '${first.substring(0, 139).trimRight()}…';
  }
}

final dailyLessonProvider =
    FutureProvider.autoDispose<DailyLessonApi>((ref) async {
  ref.keepAlive();
  final api = ref.read(apiClientProvider);
  final res =
      await api.get<Map<String, dynamic>>('/discover/daily-lesson');
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    throw StateError('daily-lesson: unexpected payload shape');
  }
  return DailyLessonApi.fromJson(data);
});

// ---------------------------------------------------------------------------
// Knowledge cards (carousel of 3)
// ---------------------------------------------------------------------------

class KnowledgeCardApi {
  final String id;
  final String slug;
  final String title;
  final String tagline;
  final String category;
  final int readMin;

  const KnowledgeCardApi({
    required this.id,
    required this.slug,
    required this.title,
    required this.tagline,
    required this.category,
    required this.readMin,
  });

  factory KnowledgeCardApi.fromJson(Map<String, dynamic> j) => KnowledgeCardApi(
        id: (j['id'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        tagline: (j['tagline'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        readMin: (j['read_min'] as num?)?.toInt() ?? 3,
      );

  /// Best-effort topical emoji (server doesn't return one — the carousel
  /// renders an emoji so we map from the category here).
  String get emoji {
    switch (category) {
      case 'nutrition':
        return '🥗';
      case 'training':
        return '🏋️';
      case 'recovery':
        return '😴';
      case 'cardio':
        return '🫀';
      case 'progress':
        return '📈';
      default:
        return '📖';
    }
  }
}

final knowledgeCardsProvider =
    FutureProvider.autoDispose<List<KnowledgeCardApi>>((ref) async {
  ref.keepAlive();
  final api = ref.read(apiClientProvider);
  final res =
      await api.get<Map<String, dynamic>>('/discover/knowledge-cards');
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    throw StateError('knowledge-cards: unexpected payload shape');
  }
  final raw = data['cards'];
  if (raw is! List) {
    throw StateError('knowledge-cards: missing "cards" list');
  }
  return raw
      .whereType<Map<String, dynamic>>()
      .map(KnowledgeCardApi.fromJson)
      .toList(growable: false);
});

// ---------------------------------------------------------------------------
// Daily meditation
// ---------------------------------------------------------------------------

class MeditationPickApi {
  final String id;
  final String slug;
  final String title;
  final String description;
  final int durationMin;
  final String audioUrl;

  const MeditationPickApi({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.durationMin,
    required this.audioUrl,
  });

  factory MeditationPickApi.fromJson(Map<String, dynamic> j) =>
      MeditationPickApi(
        id: (j['id'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        durationMin: (j['duration_min'] as num?)?.toInt() ?? 5,
        audioUrl: (j['audio_url'] ?? '').toString(),
      );
}

final dailyMeditationProvider =
    FutureProvider.autoDispose<MeditationPickApi>((ref) async {
  ref.keepAlive();
  final api = ref.read(apiClientProvider);
  final res = await api.get<Map<String, dynamic>>('/meditation/today');
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    throw StateError('meditation/today: unexpected payload shape');
  }
  return MeditationPickApi.fromJson(data);
});

// ---------------------------------------------------------------------------
// Sleep story (today)
// ---------------------------------------------------------------------------

class SleepStoryApi {
  final String id;
  final String slug;
  final String title;
  final String description;
  final int durationMin;
  final String audioUrl;

  const SleepStoryApi({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.durationMin,
    required this.audioUrl,
  });

  factory SleepStoryApi.fromJson(Map<String, dynamic> j) => SleepStoryApi(
        id: (j['id'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        durationMin: (j['duration_min'] as num?)?.toInt() ?? 15,
        audioUrl: (j['audio_url'] ?? '').toString(),
      );
}

final sleepStoryTodayProvider =
    FutureProvider.autoDispose<SleepStoryApi>((ref) async {
  ref.keepAlive();
  final api = ref.read(apiClientProvider);
  final res =
      await api.get<Map<String, dynamic>>('/sleep-stories/today');
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    throw StateError('sleep-stories/today: unexpected payload shape');
  }
  return SleepStoryApi.fromJson(data);
});

// ---------------------------------------------------------------------------
// Premium preview rotation
// ---------------------------------------------------------------------------

class PremiumPreviewApi {
  final String id;
  final String slug;
  final String title;
  final String previewBody;
  final String lockedFeatureKey;
  final String route;

  const PremiumPreviewApi({
    required this.id,
    required this.slug,
    required this.title,
    required this.previewBody,
    required this.lockedFeatureKey,
    required this.route,
  });

  factory PremiumPreviewApi.fromJson(Map<String, dynamic> j) =>
      PremiumPreviewApi(
        id: (j['id'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        previewBody: (j['preview_body'] ?? '').toString(),
        lockedFeatureKey: (j['locked_feature_key'] ?? '').toString(),
        route: (j['route'] ?? '/paywall').toString(),
      );
}

/// Wrapper that distinguishes "no rotation slot" (free tier, empty catalog
/// or paying user with the tile suppressed) from "loading" / "error". Tiles
/// render `SizedBox.shrink()` when [entry] is null.
class PremiumPreviewRotationApi {
  final PremiumPreviewApi? entry;
  final String tier;

  const PremiumPreviewRotationApi({required this.entry, required this.tier});
}

final premiumPreviewRotationProvider =
    FutureProvider.autoDispose<PremiumPreviewRotationApi>((ref) async {
  ref.keepAlive();
  final api = ref.read(apiClientProvider);
  final res =
      await api.get<Map<String, dynamic>>('/home/premium-preview-rotation');
  final data = res.data;
  if (data is! Map<String, dynamic>) {
    throw StateError(
        'home/premium-preview-rotation: unexpected payload shape');
  }
  final entry = data['entry'];
  return PremiumPreviewRotationApi(
    entry: entry is Map<String, dynamic>
        ? PremiumPreviewApi.fromJson(entry)
        : null,
    tier: (data['tier'] ?? 'free').toString(),
  );
});
