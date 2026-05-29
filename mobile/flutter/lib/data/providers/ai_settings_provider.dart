/// AI Settings provider — single source of truth for user-controllable AI /
/// coach preferences. Replaces the previously-nested
/// `Settings → AI Coach → click in for more` IA. Now everything lives flat
/// in one screen (see `ai_settings_screen.dart`).
///
/// Persisted to SharedPreferences keyed by user id so the prefs travel with
/// the account.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contextual_nudge.dart' show NudgeCategory, NudgeId;
import '../repositories/auth_repository.dart' show authStateProvider;

/// Default priority order for sub-card nudge categories. Mirrors the
/// industry pyramid in `docs/planning/home-screen-surfaces.md` §4.
///
/// Lower index = higher priority. The SubCardRanker re-orders eligible
/// candidates so categories higher in this list win ties.
const List<NudgeCategory> kDefaultNudgeCategoryOrder = [
  NudgeCategory.healthAlert,
  NudgeCategory.timeSensitive,
  NudgeCategory.streak,
  NudgeCategory.habit,
  NudgeCategory.educational,
  NudgeCategory.social,
];

@immutable
class CoachUiSettings {
  /// User-overridden category ordering. Empty list = use default.
  final List<NudgeCategory> categoryOrder;

  /// Hide the YOUR COACH card entirely on Home.
  final bool coachCardHidden;

  /// Per-feature AI opt-ins.
  final bool aiCoachEnabled;
  final bool ragEnabled;
  final bool aiFormAnalysisEnabled;
  final bool aiMealScanEnabled;
  final bool voiceCoachEnabled;

  /// Nudge types the user permanently muted ("Always hide this"). Stored as
  /// [NudgeId] `name` strings so the set survives enum reordering and any
  /// id no longer in the enum is simply ignored on load. The
  /// `contextualNudgeProvider` filters these out before ranking, so a muted
  /// type never appears and never consumes a daily sub-card slot.
  final Set<String> mutedNudgeIds;

  const CoachUiSettings({
    this.categoryOrder = const [],
    this.coachCardHidden = false,
    this.aiCoachEnabled = true,
    this.ragEnabled = true,
    this.aiFormAnalysisEnabled = true,
    this.aiMealScanEnabled = true,
    this.voiceCoachEnabled = true,
    this.mutedNudgeIds = const {},
  });

  /// Effective category order — caller-facing helper. If the user has
  /// reordered, return their order; otherwise the default pyramid.
  List<NudgeCategory> get effectiveCategoryOrder =>
      categoryOrder.isEmpty ? kDefaultNudgeCategoryOrder : categoryOrder;

  /// Priority rank of a category — lower = higher priority.
  int priorityOf(NudgeCategory cat) {
    final order = effectiveCategoryOrder;
    final idx = order.indexOf(cat);
    return idx < 0 ? order.length : idx;
  }

  CoachUiSettings copyWith({
    List<NudgeCategory>? categoryOrder,
    bool? coachCardHidden,
    bool? aiCoachEnabled,
    bool? ragEnabled,
    bool? aiFormAnalysisEnabled,
    bool? aiMealScanEnabled,
    bool? voiceCoachEnabled,
    Set<String>? mutedNudgeIds,
  }) {
    return CoachUiSettings(
      categoryOrder: categoryOrder ?? this.categoryOrder,
      coachCardHidden: coachCardHidden ?? this.coachCardHidden,
      aiCoachEnabled: aiCoachEnabled ?? this.aiCoachEnabled,
      ragEnabled: ragEnabled ?? this.ragEnabled,
      aiFormAnalysisEnabled:
          aiFormAnalysisEnabled ?? this.aiFormAnalysisEnabled,
      aiMealScanEnabled: aiMealScanEnabled ?? this.aiMealScanEnabled,
      voiceCoachEnabled: voiceCoachEnabled ?? this.voiceCoachEnabled,
      mutedNudgeIds: mutedNudgeIds ?? this.mutedNudgeIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryOrder': categoryOrder.map((e) => e.name).toList(),
        'coachCardHidden': coachCardHidden,
        'aiCoachEnabled': aiCoachEnabled,
        'ragEnabled': ragEnabled,
        'aiFormAnalysisEnabled': aiFormAnalysisEnabled,
        'aiMealScanEnabled': aiMealScanEnabled,
        'voiceCoachEnabled': voiceCoachEnabled,
        'mutedNudgeIds': mutedNudgeIds.toList(),
      };

  static CoachUiSettings fromJson(Map<String, dynamic> json) {
    final raw = json['categoryOrder'] as List<dynamic>? ?? const [];
    final byName = {for (final c in NudgeCategory.values) c.name: c};
    final order = raw
        .whereType<String>()
        .map((s) => byName[s])
        .whereType<NudgeCategory>()
        .toList(growable: false);
    // Muted ids default to empty for users whose stored JSON predates the
    // field. Keep only names that still map to a live NudgeId so a renamed
    // or removed enum value can't strand a permanently-hidden nudge.
    final validIds = {for (final id in NudgeId.values) id.name};
    final mutedRaw = json['mutedNudgeIds'] as List<dynamic>? ?? const [];
    final muted = mutedRaw
        .whereType<String>()
        .where(validIds.contains)
        .toSet();
    return CoachUiSettings(
      categoryOrder: order,
      coachCardHidden: json['coachCardHidden'] as bool? ?? false,
      aiCoachEnabled: json['aiCoachEnabled'] as bool? ?? true,
      ragEnabled: json['ragEnabled'] as bool? ?? true,
      aiFormAnalysisEnabled: json['aiFormAnalysisEnabled'] as bool? ?? true,
      aiMealScanEnabled: json['aiMealScanEnabled'] as bool? ?? true,
      voiceCoachEnabled: json['voiceCoachEnabled'] as bool? ?? true,
      mutedNudgeIds: muted,
    );
  }
}

class CoachUiSettingsNotifier extends StateNotifier<CoachUiSettings> {
  CoachUiSettingsNotifier(this._userId) : super(const CoachUiSettings()) {
    if (_userId != null) {
      unawaited(_load());
    }
  }

  final String? _userId;

  String get _key => 'ai_settings_${_userId ?? "anon"}';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = CoachUiSettings.fromJson(decoded);
    } catch (e) {
      debugPrint('[CoachUiSettings] _load failed: $e');
    }
  }

  Future<void> _persist() async {
    if (_userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('[CoachUiSettings] _persist failed: $e');
    }
  }

  Future<void> setCategoryOrder(List<NudgeCategory> order) async {
    state = state.copyWith(categoryOrder: order);
    await _persist();
  }

  Future<void> resetCategoryOrder() async {
    state = state.copyWith(categoryOrder: const []);
    await _persist();
  }

  Future<void> setCoachCardHidden(bool v) async {
    state = state.copyWith(coachCardHidden: v);
    await _persist();
  }

  Future<void> setAiCoachEnabled(bool v) async {
    state = state.copyWith(aiCoachEnabled: v);
    await _persist();
  }

  Future<void> setRagEnabled(bool v) async {
    state = state.copyWith(ragEnabled: v);
    await _persist();
  }

  Future<void> setAiFormAnalysisEnabled(bool v) async {
    state = state.copyWith(aiFormAnalysisEnabled: v);
    await _persist();
  }

  Future<void> setAiMealScanEnabled(bool v) async {
    state = state.copyWith(aiMealScanEnabled: v);
    await _persist();
  }

  Future<void> setVoiceCoachEnabled(bool v) async {
    state = state.copyWith(voiceCoachEnabled: v);
    await _persist();
  }

  /// Permanently hide a nudge type ("Always hide this"). No-op if already
  /// muted so we don't churn state or persistence.
  Future<void> muteNudge(NudgeId id) async {
    if (state.mutedNudgeIds.contains(id.name)) return;
    state = state.copyWith(mutedNudgeIds: {...state.mutedNudgeIds, id.name});
    await _persist();
  }

  /// Restore a single muted nudge type.
  Future<void> unmuteNudge(NudgeId id) async {
    if (!state.mutedNudgeIds.contains(id.name)) return;
    state = state.copyWith(
      mutedNudgeIds: {...state.mutedNudgeIds}..remove(id.name),
    );
    await _persist();
  }

  /// Restore every muted nudge type.
  Future<void> clearMutedNudges() async {
    if (state.mutedNudgeIds.isEmpty) return;
    state = state.copyWith(mutedNudgeIds: const {});
    await _persist();
  }
}

final coachUiSettingsProvider =
    StateNotifierProvider<CoachUiSettingsNotifier, CoachUiSettings>((ref) {
  final uid = ref.watch(authStateProvider).user?.id;
  return CoachUiSettingsNotifier(uid);
});
