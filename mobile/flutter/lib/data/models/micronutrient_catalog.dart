import 'package:flutter/material.dart';

/// One customizable micronutrient tile in the Hero Nutrition carousel.
///
/// Pure presentation + reference goal — the per-day VALUE is read separately
/// from the day's logged meals (see `_microValue` in hero_nutrition_card.dart),
/// so this catalog stays a plain const list that the visibility provider and
/// the customize sheet can both reference without pulling in the totals model.
///
/// Goals are FDA Daily Values (Omega-3 uses the 1.6 g adequate-intake
/// reference). They are NOT per-user editable — the customize control only
/// toggles/reorders which tiles appear (home-deck style).
class MicroCatalogEntry {
  /// Stable slug used for persistence + value lookup. Never rename — a changed
  /// id silently drops the tile from a user's persisted order.
  final String id;
  final String name;
  final double goal;
  final String unit;
  final String emoji;
  final Color color;

  /// Decimal places when displaying the value (0 for whole mg/µg, 1 for small
  /// quantities like B12 / omega-3 that would round to 0).
  final int fixed;

  const MicroCatalogEntry({
    required this.id,
    required this.name,
    required this.goal,
    required this.unit,
    required this.emoji,
    required this.color,
    required this.fixed,
  });
}

/// The full ordered micronutrient catalog. The DEFAULT visible order is exactly
/// this list (matching the old hard-coded pages 2-5, minus Hydration which now
/// has its own dedicated tracker on the Daily tab). The customize sheet lets a
/// user hide / reorder any of these.
const List<MicroCatalogEntry> kMicroCatalog = [
  // ── former page 2 ──────────────────────────────────────────────────────
  MicroCatalogEntry(id: 'fiber', name: 'Fiber', goal: 28, unit: 'g', emoji: '🥦', color: Color(0xFF3F8F5F), fixed: 0),
  MicroCatalogEntry(id: 'sugar', name: 'Sugar', goal: 50, unit: 'g', emoji: '🍬', color: Color(0xFFB65689), fixed: 0),
  MicroCatalogEntry(id: 'sodium', name: 'Sodium', goal: 2300, unit: 'mg', emoji: '🧂', color: Color(0xFF5560BF), fixed: 0),
  MicroCatalogEntry(id: 'potassium', name: 'Potassium', goal: 4700, unit: 'mg', emoji: '🍌', color: Color(0xFFCC8A2A), fixed: 0),
  MicroCatalogEntry(id: 'cholesterol', name: 'Cholesterol', goal: 300, unit: 'mg', emoji: '🧈', color: Color(0xFFCF5F4A), fixed: 0),
  MicroCatalogEntry(id: 'calcium', name: 'Calcium', goal: 1300, unit: 'mg', emoji: '🥛', color: Color(0xFF3A9A9A), fixed: 0),
  // ── former page 3 ──────────────────────────────────────────────────────
  MicroCatalogEntry(id: 'iron', name: 'Iron', goal: 18, unit: 'mg', emoji: '🩸', color: Color(0xFF8C5BB0), fixed: 0),
  MicroCatalogEntry(id: 'vitamin_c', name: 'Vitamin C', goal: 90, unit: 'mg', emoji: '🍊', color: Color(0xFFC79520), fixed: 0),
  MicroCatalogEntry(id: 'vitamin_a', name: 'Vitamin A', goal: 900, unit: 'µg', emoji: '🥕', color: Color(0xFFD9802E), fixed: 0),
  MicroCatalogEntry(id: 'vitamin_d', name: 'Vitamin D', goal: 800, unit: 'IU', emoji: '☀️', color: Color(0xFFCFA62A), fixed: 0),
  MicroCatalogEntry(id: 'sat_fat', name: 'Sat. Fat', goal: 20, unit: 'g', emoji: '🧀', color: Color(0xFFCF5F4A), fixed: 0),
  // ── former page 4 ──────────────────────────────────────────────────────
  MicroCatalogEntry(id: 'magnesium', name: 'Magnesium', goal: 420, unit: 'mg', emoji: '🪨', color: Color(0xFF5F8F6B), fixed: 0),
  MicroCatalogEntry(id: 'zinc', name: 'Zinc', goal: 11, unit: 'mg', emoji: '⚙️', color: Color(0xFF7A8CA3), fixed: 0),
  MicroCatalogEntry(id: 'vitamin_b12', name: 'Vitamin B12', goal: 2.4, unit: 'µg', emoji: '🐟', color: Color(0xFFB5604A), fixed: 1),
  MicroCatalogEntry(id: 'folate', name: 'Folate', goal: 400, unit: 'µg', emoji: '🥬', color: Color(0xFF4F9E5A), fixed: 0),
  MicroCatalogEntry(id: 'vitamin_e', name: 'Vitamin E', goal: 15, unit: 'mg', emoji: '🥜', color: Color(0xFFC7902A), fixed: 1),
  MicroCatalogEntry(id: 'omega_3', name: 'Omega-3', goal: 1.6, unit: 'g', emoji: '🐠', color: Color(0xFF3F8FA3), fixed: 1),
  // ── former page 5 ──────────────────────────────────────────────────────
  MicroCatalogEntry(id: 'vitamin_k', name: 'Vitamin K', goal: 120, unit: 'µg', emoji: '🥦', color: Color(0xFF3F8F5F), fixed: 0),
  MicroCatalogEntry(id: 'vitamin_b6', name: 'Vitamin B6', goal: 1.7, unit: 'mg', emoji: '🍗', color: Color(0xFFB07A4A), fixed: 1),
  MicroCatalogEntry(id: 'phosphorus', name: 'Phosphorus', goal: 1250, unit: 'mg', emoji: '🦴', color: Color(0xFF8A8FA8), fixed: 0),
  MicroCatalogEntry(id: 'selenium', name: 'Selenium', goal: 55, unit: 'µg', emoji: '🌰', color: Color(0xFF9A6F3A), fixed: 0),
  MicroCatalogEntry(id: 'copper', name: 'Copper', goal: 0.9, unit: 'mg', emoji: '🟫', color: Color(0xFFB5733A), fixed: 1),
  MicroCatalogEntry(id: 'manganese', name: 'Manganese', goal: 2.3, unit: 'mg', emoji: '🧱', color: Color(0xFF9A5F4A), fixed: 1),
];

/// Canonical default visible order — every catalog tile, in catalog order.
List<String> get kDefaultMicroOrder =>
    kMicroCatalog.map((e) => e.id).toList(growable: false);

/// Lookup by id (null when an id is unknown — e.g. a stale persisted slug).
MicroCatalogEntry? microEntryById(String id) {
  for (final e in kMicroCatalog) {
    if (e.id == id) return e;
  }
  return null;
}
