/// `dataGapsProvider` — fetches the cross-source missing-signal summary
/// from `GET /api/v1/home/data-gaps`. Feeds the F3.68 MissingDataChip on
/// the home screen.
///
/// On any network/auth failure resolves to an empty result (no gaps known)
/// rather than throwing — the chip self-collapses when no gaps are reported.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../services/api_client.dart';

/// One missing-data source row from the backend.
class DataGap {
  /// `activity` | `heart_rate` | `sleep` | `weight`
  final String source;
  final String? lastDataAt;
  final int? hoursSince;

  const DataGap({
    required this.source,
    required this.lastDataAt,
    required this.hoursSince,
  });

  factory DataGap.fromJson(Map<String, dynamic> json) => DataGap(
        source: (json['source'] as String?) ?? 'unknown',
        lastDataAt: json['last_data_at'] as String?,
        hoursSince: (json['hours_since'] as num?)?.toInt(),
      );

  /// Human label for the F3.68 chip — kept here so the widget stays dumb.
  String get displayLabel {
    switch (source) {
      case 'activity':
        return 'Connect Health Connect to track steps and activity';
      case 'heart_rate':
        return 'No recent heart-rate data — open your wearable app to sync';
      case 'sleep':
        return 'No recent sleep data — connect Health Connect or Apple Health';
      case 'weight':
        return 'No recent weight log — add one to keep nutrition adaptive';
      default:
        return 'Missing data from a connected source';
    }
  }

  /// Where the chip should route on tap.
  String get deepLink {
    switch (source) {
      case 'weight':
        return '/profile?tab=measurements';
      default:
        return '/settings?tab=integrations';
    }
  }
}

/// Result wrapper — top-of-list gap (used by the home chip) + the full list
/// + the convenience `anyGaps` flag.
class DataGapsResult {
  final List<DataGap> gaps;
  final bool anyGaps;

  const DataGapsResult({required this.gaps, required this.anyGaps});

  static const DataGapsResult empty =
      DataGapsResult(gaps: <DataGap>[], anyGaps: false);

  /// First (highest-priority) gap for the single-line chip. Priority order:
  /// activity → sleep → heart_rate → weight. Falls through to first-in-list.
  DataGap? get primary {
    if (gaps.isEmpty) return null;
    const order = ['activity', 'sleep', 'heart_rate', 'weight'];
    for (final src in order) {
      final hit = gaps.where((g) => g.source == src);
      if (hit.isNotEmpty) return hit.first;
    }
    return gaps.first;
  }
}

final dataGapsProvider =
    FutureProvider.autoDispose<DataGapsResult>((ref) async {
  if (Supabase.instance.client.auth.currentSession == null) {
    return DataGapsResult.empty;
  }
  final api = ref.read(apiClientProvider);
  try {
    final res = await api.get<Map<String, dynamic>>('/home/data-gaps');
    final data = res.data;
    if (data is! Map<String, dynamic>) return DataGapsResult.empty;
    final list = (data['gaps'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DataGap.fromJson)
        .toList();
    return DataGapsResult(
      gaps: list,
      anyGaps: (data['any_gaps'] as bool?) ?? list.isNotEmpty,
    );
  } catch (_) {
    return DataGapsResult.empty;
  }
});
