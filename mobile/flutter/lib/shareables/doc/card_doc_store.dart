/// Persistence for editable share cards.
///
///  - **Drafts** — the customization a user applied to a specific share,
///    keyed by a stable share hash, so backing out and reopening the sheet
///    restores their edits. LRU-capped.
///  - **Saved templates** — cards the user explicitly saved as reusable
///    "My Templates".
///
/// Both are stored in `SharedPreferences` as JSON and are fail-soft: a corrupt
/// or missing blob simply yields null / an empty list (mirrors the project's
/// `ShareSettingsStore` pattern).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shareable_data.dart';
import 'card_doc.dart';

/// Summary + payload of a user-saved custom card.
@immutable
class SavedCard {
  final String id;
  final String name;
  final String? presetId;
  final DateTime updatedAt;
  final CardDoc doc;

  const SavedCard({
    required this.id,
    required this.name,
    required this.presetId,
    required this.updatedAt,
    required this.doc,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        if (presetId != null) 'presetId': presetId,
        'updatedAt': updatedAt.toIso8601String(),
        'doc': doc.toJson(),
      };

  static SavedCard? fromJson(Object? v) {
    if (v is! Map) return null;
    final docRaw = v['doc'];
    if (docRaw is! Map) return null;
    try {
      return SavedCard(
        id: v['id'] as String? ?? '',
        name: v['name'] as String? ?? 'Untitled',
        presetId: v['presetId'] as String?,
        updatedAt: DateTime.tryParse(v['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        doc: CardDoc.fromJson(docRaw.cast<String, Object?>()),
      );
    } catch (e) {
      debugPrint('[CardDocStore] SavedCard decode failed: $e');
      return null;
    }
  }
}

/// Load / save helper for [CardDoc] drafts and saved templates.
class CardDocStore {
  CardDocStore._();

  static const _draftPrefix = 'card_doc_draft_';
  static const _draftIndexKey = 'card_doc_draft_index';
  static const _savedKey = 'card_doc_saved_v1';
  static const _maxDrafts = 12;
  static const _maxSaved = 60;

  /// A stable identity for a share — drafts are keyed by this so the same
  /// log + template restores its customization.
  static String shareHash(Shareable data, {String? presetId}) {
    final raw = '${data.kind.name}|${data.title}|${data.periodLabel}'
        '|${presetId ?? ''}';
    // Compact, collision-resistant-enough deterministic hash.
    var hash = 0x811c9dc5;
    for (final unit in raw.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  // ─────────────────────────── Drafts ──────────────────────────────────────

  /// Persists [doc] as the draft for [shareHash]. Fire-and-forget.
  static Future<void> saveDraft(String shareHash, CardDoc doc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_draftPrefix$shareHash', doc.encode());
      // Maintain an LRU index; evict the oldest beyond the cap.
      final index = prefs.getStringList(_draftIndexKey) ?? <String>[];
      index.remove(shareHash);
      index.insert(0, shareHash);
      while (index.length > _maxDrafts) {
        final evicted = index.removeLast();
        await prefs.remove('$_draftPrefix$evicted');
      }
      await prefs.setStringList(_draftIndexKey, index);
    } catch (e) {
      debugPrint('[CardDocStore] saveDraft failed: $e');
    }
  }

  /// Returns the draft for [shareHash], or null when none / unreadable.
  static Future<CardDoc?> loadDraft(String shareHash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return CardDoc.decode(prefs.getString('$_draftPrefix$shareHash'));
    } catch (e) {
      debugPrint('[CardDocStore] loadDraft failed: $e');
      return null;
    }
  }

  /// Removes the draft for [shareHash] (e.g. after the user resets the card).
  static Future<void> clearDraft(String shareHash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_draftPrefix$shareHash');
      final index = prefs.getStringList(_draftIndexKey) ?? <String>[];
      index.remove(shareHash);
      await prefs.setStringList(_draftIndexKey, index);
    } catch (e) {
      debugPrint('[CardDocStore] clearDraft failed: $e');
    }
  }

  // ─────────────────────────── Saved templates ────────────────────────────

  /// Every user-saved custom card, most-recently-updated first.
  static Future<List<SavedCard>> listSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_savedKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final cards = <SavedCard>[];
      for (final entry in decoded) {
        final card = SavedCard.fromJson(entry);
        if (card != null) cards.add(card);
      }
      cards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return cards;
    } catch (e) {
      debugPrint('[CardDocStore] listSaved failed: $e');
      return const [];
    }
  }

  /// Saves [doc] as a reusable custom template named [name]. Returns its id.
  static Future<String> saveAs(CardDoc doc, String name) async {
    final id = 'saved_${DateTime.now().microsecondsSinceEpoch}';
    final card = SavedCard(
      id: id,
      name: name.trim().isEmpty ? 'My card' : name.trim(),
      presetId: doc.presetId,
      updatedAt: DateTime.now(),
      doc: doc,
    );
    try {
      final current = await listSaved();
      final next = [card, ...current].take(_maxSaved).toList();
      await _writeSaved(next);
    } catch (e) {
      debugPrint('[CardDocStore] saveAs failed: $e');
    }
    return id;
  }

  /// Deletes the saved template with [id].
  static Future<void> deleteSaved(String id) async {
    try {
      final current = await listSaved();
      await _writeSaved(current.where((c) => c.id != id).toList());
    } catch (e) {
      debugPrint('[CardDocStore] deleteSaved failed: $e');
    }
  }

  static Future<void> _writeSaved(List<SavedCard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _savedKey,
      jsonEncode(cards.map((c) => c.toJson()).toList()),
    );
  }
}
