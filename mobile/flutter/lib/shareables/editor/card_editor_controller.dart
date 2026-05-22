/// Editing state for the Canva-style card editor — the working [CardDoc],
/// the current selection, and an undo/redo history kept as document
/// snapshots (cheap: a `CardDoc` is immutable value objects).
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';

class CardEditorController extends ChangeNotifier {
  CardEditorController(CardDoc initial) : _doc = initial {
    CardDoc.seedIdCounter(initial);
  }

  CardDoc _doc;
  CardDoc get doc => _doc;

  String? _selectedId;
  String? get selectedId => _selectedId;
  CardElement? get selected =>
      _selectedId == null ? null : _doc.elementById(_selectedId!);

  final List<CardDoc> _undo = [];
  final List<CardDoc> _redo = [];
  static const int _undoCap = 60;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  bool _gestureActive = false;

  void _snapshot() {
    _undo.add(_doc);
    if (_undo.length > _undoCap) _undo.removeAt(0);
    _redo.clear();
  }

  /// Applies a mutation as a single undo step.
  void _mutate(CardDoc Function(CardDoc) fn) {
    _snapshot();
    _doc = fn(_doc);
    notifyListeners();
  }

  // ─────────────────────────── Selection ─────────────────────────────────

  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  void deselect() => select(null);

  // ─────────────────────────── Gestures ──────────────────────────────────
  // A continuous drag / resize / rotate is ONE undo step: snapshot once on
  // begin, mutate live without snapshots, finish on end.

  void beginGesture() {
    if (_gestureActive) return;
    _gestureActive = true;
    _snapshot();
  }

  void endGesture() => _gestureActive = false;

  /// Live mutation of [id] during an active gesture (no extra snapshot).
  void updateElementLive(String id, CardElement Function(CardElement) fn) {
    _doc = _doc.withElement(id, fn);
    notifyListeners();
  }

  // ─────────────────────────── Element edits ─────────────────────────────

  /// Edits the selected element as a discrete undo step.
  void updateSelected(CardElement Function(CardElement) fn) {
    final id = _selectedId;
    if (id == null) return;
    _mutate((d) => d.withElement(id, fn));
  }

  void addElement(CardElement element) {
    _mutate((d) => d.addElement(element));
    _selectedId = element.id;
    notifyListeners();
  }

  void deleteSelected() {
    final id = _selectedId;
    if (id == null) return;
    _mutate((d) => d.removeElement(id));
    _selectedId = null;
    notifyListeners();
  }

  void duplicateSelected() {
    final el = selected;
    if (el == null) return;
    final t = el.transform;
    final copy = CardElement(
      id: CardDoc.newId(),
      type: el.type,
      transform: t.copyWith(
        position: Offset(
          (t.position.dx + 0.04).clamp(0.0, 1.0),
          (t.position.dy + 0.04).clamp(0.0, 1.0),
        ),
      ),
      hidden: el.hidden,
      locked: false,
      opacity: el.opacity,
      blendMode: el.blendMode,
      effects: el.effects,
      props: el.props,
    );
    _mutate((d) => d.addElement(copy));
    _selectedId = copy.id;
    notifyListeners();
  }

  // ─────────────────────────── Z-order ───────────────────────────────────

  void _reorderSelected(int target) {
    final id = _selectedId;
    if (id == null) return;
    _mutate((d) => d.reorder(id, target));
  }

  void bringSelectedToFront() => _reorderSelected(_doc.elements.length);
  void sendSelectedToBack() => _reorderSelected(0);

  void nudgeSelected(int delta) {
    final id = _selectedId;
    if (id == null) return;
    final idx = _doc.elements.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    _reorderSelected((idx + delta).clamp(0, _doc.elements.length - 1));
  }

  /// Moves [id] to [newIndex] (used by the layers panel's drag-reorder).
  void moveElement(String id, int newIndex) =>
      _mutate((d) => d.reorder(id, newIndex));

  void toggleHidden(String id) =>
      _mutate((d) => d.withElement(id, (e) => e.copyWith(hidden: !e.hidden)));

  void toggleLocked(String id) =>
      _mutate((d) => d.withElement(id, (e) => e.copyWith(locked: !e.locked)));

  // ─────────────────────────── Background ────────────────────────────────

  void setBackground(CardBackground background) =>
      _mutate((d) => d.copyWith(background: background));

  // ─────────────────────────── Aspect (magic resize) ─────────────────────

  /// Re-fits the whole document to a new aspect ratio, preserving every
  /// element's on-screen layout (see [CardDoc.resizedTo]).
  void setAspect(ShareableAspect aspect) {
    if (_doc.aspect == aspect) return;
    _mutate((d) => d.resizedTo(aspect));
  }

  // ─────────────────────────── Undo / redo ───────────────────────────────

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_doc);
    _doc = _undo.removeLast();
    if (_selectedId != null && _doc.elementById(_selectedId!) == null) {
      _selectedId = null;
    }
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_doc);
    _doc = _redo.removeLast();
    if (_selectedId != null && _doc.elementById(_selectedId!) == null) {
      _selectedId = null;
    }
    notifyListeners();
  }
}
