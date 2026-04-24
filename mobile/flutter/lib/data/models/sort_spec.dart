/// Sort fields + multi-sort specification for the Menu Analysis sheet.
///
/// Replaces the old single-enum sort with a SQL-style ORDER BY list so
/// users can express "cheap AND high-protein" (price asc, protein desc)
/// rather than picking one dimension at a time. Max depth enforced at
/// [kMaxSortDepth] to keep the pill UI readable.
library;

enum SortField {
  calories,
  protein,
  carbs,
  fat,
  health,
  inflammation,
  glycemicLoad,
  fodmap,
  addedSugar,
  ultraProcessed,
  price,
  weight;

  String get label {
    switch (this) {
      case SortField.calories: return 'Calories';
      case SortField.protein: return 'Protein';
      case SortField.carbs: return 'Carbs';
      case SortField.fat: return 'Fat';
      case SortField.health: return 'Health';
      case SortField.inflammation: return 'Inflammation';
      case SortField.glycemicLoad: return 'Blood sugar';
      case SortField.fodmap: return 'FODMAP';
      case SortField.addedSugar: return 'Added sugar';
      case SortField.ultraProcessed: return 'Ultra-processed';
      case SortField.price: return 'Price';
      case SortField.weight: return 'Weight';
    }
  }

  /// Default direction when a user taps a fresh pill. Macros + health
  /// default DESC (more/better is better); health-cost dimensions
  /// (inflammation / GL / FODMAP / added sugar / ultra-processed / price /
  /// weight) default ASC so "less is better" lands at the top.
  SortDirection get defaultDirection {
    switch (this) {
      case SortField.inflammation:
      case SortField.glycemicLoad:
      case SortField.fodmap:
      case SortField.addedSugar:
      case SortField.ultraProcessed:
      case SortField.price:
      case SortField.weight:
        return SortDirection.asc;
      case SortField.calories:
      case SortField.protein:
      case SortField.carbs:
      case SortField.fat:
      case SortField.health:
        return SortDirection.desc;
    }
  }
}

enum SortDirection {
  asc,
  desc;

  SortDirection get reversed =>
      this == SortDirection.asc ? SortDirection.desc : SortDirection.asc;
}

/// Single (field, direction) pair. Equal when field matches — direction
/// is mutated in-place via copyWith so the UI can flip arrows without
/// disturbing list order.
class SortSpec {
  final SortField field;
  final SortDirection direction;

  const SortSpec(this.field, this.direction);

  SortSpec copyWith({SortDirection? direction}) =>
      SortSpec(field, direction ?? this.direction);

  @override
  bool operator ==(Object other) =>
      other is SortSpec && other.field == field && other.direction == direction;

  @override
  int get hashCode => Object.hash(field, direction);
}

const int kMaxSortDepth = 3;

/// Immutable ordered list of sort specs. Provides mutation helpers that
/// enforce `kMaxSortDepth` + uniqueness-by-field + "one-tap keeps legacy
/// behavior" semantics from the plan.
class SortSpecList {
  final List<SortSpec> specs;

  const SortSpecList(this.specs);

  static const empty = SortSpecList(<SortSpec>[]);

  bool get isEmpty => specs.isEmpty;
  int get length => specs.length;

  /// Find an existing spec for [field], or null.
  SortSpec? _find(SortField f) {
    for (final s in specs) {
      if (s.field == f) return s;
    }
    return null;
  }

  /// Three-state cycle when the user keeps tapping the same primary pill:
  ///
  ///   off → default direction → reversed direction → off
  ///
  /// Lets the user disable a sort without having to find a separate
  /// "clear" affordance. Tapping a different field resets to a single
  /// entry with `field` as the new primary.
  SortSpecList tap(SortField field) {
    if (specs.isNotEmpty && specs.first.field == field) {
      final current = specs.first.direction;
      final isDefault = current == field.defaultDirection;
      if (isDefault) {
        // Second tap: flip to the reversed direction.
        return SortSpecList([
          specs.first.copyWith(direction: current.reversed),
          ...specs.skip(1),
        ]);
      }
      // Third tap: drop the primary. Tiebreakers (if any) get promoted.
      return SortSpecList(specs.skip(1).toList());
    }
    return SortSpecList([SortSpec(field, field.defaultDirection)]);
  }

  /// Add as a tiebreaker at the end without promoting. Ignored if the
  /// field is already in the list or the list is full.
  SortSpecList addTiebreaker(SortField field) {
    if (_find(field) != null) return this;
    if (specs.length >= kMaxSortDepth) return this;
    return SortSpecList([...specs, SortSpec(field, field.defaultDirection)]);
  }

  /// Promote `field` to primary. If already present, move to index 0;
  /// otherwise insert at 0 (trim tail to maxDepth).
  SortSpecList promote(SortField field) {
    final existing = _find(field);
    final rest = specs.where((s) => s.field != field).toList();
    final promoted = existing ?? SortSpec(field, field.defaultDirection);
    final next = [promoted, ...rest];
    if (next.length > kMaxSortDepth) next.removeLast();
    return SortSpecList(next);
  }

  SortSpecList remove(SortField field) =>
      SortSpecList(specs.where((s) => s.field != field).toList());

  /// Drag-and-drop reorder (used by the "Reorder sorts" sheet).
  SortSpecList reorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return this;
    final next = [...specs];
    final item = next.removeAt(oldIndex);
    next.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    return SortSpecList(next);
  }

  /// Index of `field` in the sort list (0-based). Returns -1 if absent.
  /// Used by UI to render the little "1" / "2" / "3" rank badges on pills.
  int indexOf(SortField field) {
    for (int i = 0; i < specs.length; i++) {
      if (specs[i].field == field) return i;
    }
    return -1;
  }

  /// Returns the current direction for `field`, or null if not active.
  SortDirection? directionOf(SortField field) => _find(field)?.direction;

  /// Build a comparator that folds over every spec in priority order,
  /// returning the first non-zero comparison. Callers pass a field
  /// extractor that knows how to read the sorted value off a model.
  int Function(T, T) comparator<T>(
    Comparable<dynamic>? Function(T item, SortField field) extractor,
  ) {
    return (T a, T b) {
      for (final spec in specs) {
        final va = extractor(a, spec.field);
        final vb = extractor(b, spec.field);
        if (va == null && vb == null) continue;
        if (va == null) return spec.direction == SortDirection.asc ? 1 : -1;
        if (vb == null) return spec.direction == SortDirection.asc ? -1 : 1;
        final cmp = Comparable.compare(va, vb);
        if (cmp != 0) {
          return spec.direction == SortDirection.asc ? cmp : -cmp;
        }
      }
      return 0;
    };
  }
}
