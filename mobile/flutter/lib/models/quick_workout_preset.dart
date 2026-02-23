import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/local/database.dart';
import 'equipment_item.dart';

/// App-facing model for a quick workout preset.
class QuickWorkoutPreset {
  final String id;
  final int duration;
  final String? focus;
  final String? difficulty;
  final String? goal;
  final String? mood;
  final bool useSupersets;
  final List<String> equipment;
  final List<String> injuries;
  final Map<String, EquipmentItem>? equipmentDetails;
  final int useCount;
  final bool isFavorite;
  final bool isAiGenerated;
  final DateTime createdAt;

  const QuickWorkoutPreset({
    required this.id,
    required this.duration,
    this.focus,
    this.difficulty,
    this.goal,
    this.mood,
    this.useSupersets = true,
    this.equipment = const ['Bodyweight'],
    this.injuries = const [],
    this.equipmentDetails,
    this.useCount = 0,
    this.isFavorite = false,
    this.isAiGenerated = false,
    required this.createdAt,
  });

  /// Create a new preset with a generated UUID.
  factory QuickWorkoutPreset.create({
    required int duration,
    String? focus,
    String? difficulty,
    String? goal,
    String? mood,
    bool useSupersets = true,
    List<String> equipment = const ['Bodyweight'],
    List<String> injuries = const [],
    Map<String, EquipmentItem>? equipmentDetails,
    bool isAiGenerated = false,
  }) {
    return QuickWorkoutPreset(
      id: const Uuid().v4(),
      duration: duration,
      focus: focus,
      difficulty: difficulty,
      goal: goal,
      mood: mood,
      useSupersets: useSupersets,
      equipment: equipment,
      injuries: injuries,
      equipmentDetails: equipmentDetails,
      isAiGenerated: isAiGenerated,
      createdAt: DateTime.now(),
    );
  }

  // ── Display helpers ──

  /// Short label like "15m Full Body" or "10m Cardio"
  String get label {
    final focusLabel = _focusDisplayName(focus);
    return '${duration}m $focusLabel';
  }

  /// Subtitle from equipment list, e.g. "Dumbbells + Barbell"
  String get subtitle {
    final filtered = equipment.where((e) => e != 'Bodyweight').toList();
    if (filtered.isEmpty) return 'Bodyweight';
    if (filtered.length <= 2) return filtered.join(' + ');
    return '${filtered.first} +${filtered.length - 1}';
  }

  /// Icon from focus type.
  IconData get icon {
    switch (focus) {
      case 'cardio':
        return Icons.local_fire_department;
      case 'strength':
        return Icons.fitness_center;
      case 'stretch':
        return Icons.self_improvement;
      case 'full_body':
        return Icons.accessibility_new;
      case 'upper_body':
        return Icons.sports_martial_arts;
      case 'lower_body':
        return Icons.directions_walk;
      case 'core':
        return Icons.circle_outlined;
      case 'emom':
        return Icons.timer;
      case 'amrap':
        return Icons.repeat;
      default:
        return Icons.flash_on;
    }
  }

  /// Color from focus type.
  Color get color {
    switch (focus) {
      case 'cardio':
        return Colors.orange;
      case 'strength':
        return Colors.red;
      case 'stretch':
        return Colors.teal;
      case 'upper_body':
        return Colors.blue;
      case 'lower_body':
        return Colors.green;
      case 'core':
        return Colors.purple;
      case 'emom':
        return Colors.deepPurple;
      case 'amrap':
        return Colors.teal;
      default:
        return Colors.cyan;
    }
  }

  // ── Drift conversion ──

  /// Convert to Drift companion for insert/update.
  CachedQuickPresetsCompanion toCompanion(String userId) {
    return CachedQuickPresetsCompanion(
      id: Value(id),
      userId: Value(userId),
      duration: Value(duration),
      focus: Value(focus),
      difficulty: Value(difficulty),
      goal: Value(goal),
      mood: Value(mood),
      useSupersets: Value(useSupersets),
      equipment: Value(jsonEncode(equipment)),
      injuries: Value(jsonEncode(injuries)),
      equipDetails: Value(equipmentDetails != null
          ? jsonEncode(equipmentDetails!.map(
              (k, v) => MapEntry(k, v.toJson()),
            ))
          : null),
      useCount: Value(useCount),
      isFavorite: Value(isFavorite),
      isAiGenerated: Value(isAiGenerated),
      createdAt: Value(createdAt),
    );
  }

  /// Create from a Drift row.
  factory QuickWorkoutPreset.fromRow(CachedQuickPreset row) {
    List<String> equipmentList;
    try {
      equipmentList = (jsonDecode(row.equipment) as List)
          .map((e) => e.toString())
          .toList();
    } catch (_) {
      equipmentList = ['Bodyweight'];
    }

    List<String> injuriesList;
    try {
      injuriesList = (jsonDecode(row.injuries) as List)
          .map((e) => e.toString())
          .toList();
    } catch (_) {
      injuriesList = [];
    }

    Map<String, EquipmentItem>? details;
    if (row.equipDetails != null) {
      try {
        final decoded =
            jsonDecode(row.equipDetails!) as Map<String, dynamic>;
        details = decoded.map(
          (k, v) => MapEntry(k, EquipmentItem.fromJson(v as Map<String, dynamic>)),
        );
      } catch (_) {
        details = null;
      }
    }

    return QuickWorkoutPreset(
      id: row.id,
      duration: row.duration,
      focus: row.focus,
      difficulty: row.difficulty,
      goal: row.goal,
      mood: row.mood,
      useSupersets: row.useSupersets,
      equipment: equipmentList,
      injuries: injuriesList,
      equipmentDetails: details,
      useCount: row.useCount,
      isFavorite: row.isFavorite,
      isAiGenerated: row.isAiGenerated,
      createdAt: row.createdAt,
    );
  }

  /// Config-level equality (ignores mood, useCount, timestamps, favorite).
  /// Used for dedup — two presets with same config should not duplicate.
  bool matchesConfig(QuickWorkoutPreset other) {
    return duration == other.duration &&
        focus == other.focus &&
        difficulty == other.difficulty &&
        goal == other.goal &&
        useSupersets == other.useSupersets &&
        _listEquals(equipment, other.equipment) &&
        _listEquals(injuries, other.injuries);
  }

  QuickWorkoutPreset copyWith({
    int? useCount,
    bool? isFavorite,
  }) {
    return QuickWorkoutPreset(
      id: id,
      duration: duration,
      focus: focus,
      difficulty: difficulty,
      goal: goal,
      mood: mood,
      useSupersets: useSupersets,
      equipment: equipment,
      injuries: injuries,
      equipmentDetails: equipmentDetails,
      useCount: useCount ?? this.useCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isAiGenerated: isAiGenerated,
      createdAt: createdAt,
    );
  }

  static String _focusDisplayName(String? focus) {
    switch (focus) {
      case 'cardio':
        return 'Cardio';
      case 'strength':
        return 'Strength';
      case 'stretch':
        return 'Stretch';
      case 'full_body':
        return 'Full Body';
      case 'upper_body':
        return 'Upper';
      case 'lower_body':
        return 'Lower';
      case 'core':
        return 'Core';
      case 'emom':
        return 'EMOM';
      case 'amrap':
        return 'AMRAP';
      default:
        return 'Quick';
    }
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sortedA = List<String>.from(a)..sort();
    final sortedB = List<String>.from(b)..sort();
    for (var i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }
}
