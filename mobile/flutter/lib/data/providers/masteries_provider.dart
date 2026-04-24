import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../services/api_client.dart';

/// One row in the MASTERIES grid of the Badge Hub.
class MasteryEntry {
  final String key;
  final String label;
  final String icon;              // Material icon key
  final String unit;              // 'steps' | 'calories' | ...
  final int level;
  final int currentValue;
  final int? nextThreshold;       // null if at cap
  final double progressToNext;    // 0.0–1.0

  const MasteryEntry({
    required this.key,
    required this.label,
    required this.icon,
    required this.unit,
    required this.level,
    required this.currentValue,
    required this.nextThreshold,
    required this.progressToNext,
  });

  factory MasteryEntry.fromJson(Map<String, dynamic> json) {
    return MasteryEntry(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'emoji_events_rounded',
      unit: json['unit']?.toString() ?? 'sessions',
      level: (json['level'] as num?)?.toInt() ?? 0,
      currentValue: (json['current_value'] as num?)?.toInt() ?? 0,
      nextThreshold: (json['next_threshold'] as num?)?.toInt(),
      progressToNext:
          ((json['progress_to_next'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
    );
  }
}


/// Fetches the levelled-badge grid. autoDispose so pushing away from the
/// Badge Hub doesn't hold the response in memory — it's a read-mostly
/// screen and re-fetching on return is fine.
final masteriesProvider = FutureProvider.autoDispose<List<MasteryEntry>>((ref) async {
  final userId = ref.watch(authStateProvider).user?.id;
  if (userId == null) return const [];

  final api = ref.watch(apiClientProvider);
  try {
    final resp = await api.get('/masteries/$userId');
    if (resp.statusCode == 200 && resp.data is Map) {
      final data = (resp.data as Map).cast<String, dynamic>();
      final rawList = (data['masteries'] as List?) ?? const [];
      return rawList
          .whereType<Map>()
          .map((m) => MasteryEntry.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
  } catch (e) {
    debugPrint('masteriesProvider error: $e');
  }
  return const [];
});
