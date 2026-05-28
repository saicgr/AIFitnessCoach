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

import '../models/contextual_nudge.dart' show NudgeCategory;
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

  const CoachUiSettings({
    this.categoryOrder = const [],
    this.coachCardHidden = false,
    this.aiCoachEnabled = true,
    this.ragEnabled = true,
    this.aiFormAnalysisEnabled = true,
    this.aiMealScanEnabled = true,
    this.voiceCoachEnabled = true,
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
      };

  static CoachUiSettings fromJson(Map<String, dynamic> json) {
    final raw = json['categoryOrder'] as List<dynamic>? ?? const [];
    final byName = {for (final c in NudgeCategory.values) c.name: c};
    final order = raw
        .whereType<String>()
        .map((s) => byName[s])
        .whereType<NudgeCategory>()
        .toList(growable: false);
    return CoachUiSettings(
      categoryOrder: order,
      coachCardHidden: json['coachCardHidden'] as bool? ?? false,
      aiCoachEnabled: json['aiCoachEnabled'] as bool? ?? true,
      ragEnabled: json['ragEnabled'] as bool? ?? true,
      aiFormAnalysisEnabled: json['aiFormAnalysisEnabled'] as bool? ?? true,
      aiMealScanEnabled: json['aiMealScanEnabled'] as bool? ?? true,
      voiceCoachEnabled: json['voiceCoachEnabled'] as bool? ?? true,
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
}

final coachUiSettingsProvider =
    StateNotifierProvider<CoachUiSettingsNotifier, CoachUiSettings>((ref) {
  final uid = ref.watch(authStateProvider).user?.id;
  return CoachUiSettingsNotifier(uid);
});
