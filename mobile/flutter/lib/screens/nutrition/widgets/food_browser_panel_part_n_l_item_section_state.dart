part of 'food_browser_panel.dart';


class _NLItemSectionState extends State<_NLItemSection> {
  // Selection
  search.FoodSearchResult? _selectedAlt;
  List<search.FoodSearchResult> _alternatives = [];
  bool _altsLoading = false;
  String? _altsError;
  bool _altsFetched = false;

  // Qty / weight
  late int _qty;
  late double _weightG;
  late TextEditingController _qtyCtrl;
  late TextEditingController _weightCtrl;

  // Mini search
  late TextEditingController _searchCtrl;
  Timer? _searchDebounce;

  // Modifier controls
  final Map<String, _ModifierState> _modifierStates = {};
  late TextEditingController _modSearchCtrl;
  Timer? _modSearchDebounce;
  List<search.FoodModifier> _modSearchResults = [];
  bool _modSearchLoading = false;

  int _parseOriginalQty = 1;
  double? _originalPieceWeight;

  @override
  void initState() {
    super.initState();
    // Parse qty from amount string (e.g. "5×" or "5 pieces" or "2 cups")
    _parseOriginalQty = _parseQtyFromAmount(widget.item.amount);
    _qty = _parseOriginalQty;
    _weightG = widget.item.weightG ?? 100.0;
    _originalPieceWeight = _qty > 0 ? _weightG / _qty : null;

    _qtyCtrl = TextEditingController(text: _qty.toString());
    _weightCtrl = TextEditingController(text: _weightG.round().toString());
    _searchCtrl = TextEditingController();
    _modSearchCtrl = TextEditingController();
    // Initialize modifier states from item's detected modifiers
    for (final mod in widget.item.modifiers) {
      _initModifierState(mod);
    }
  }

  void _initModifierState(search.FoodModifier mod) {
    switch (mod.type) {
      case search.FoodModifierType.addon:
        final weight = mod.defaultWeightG;
        int? count;
        if (mod.weightPerUnitG != null && weight != null) {
          count = (weight / mod.weightPerUnitG!).round();
        }
        _modifierStates[mod.phrase] = _ModifierState(weightG: weight, count: count, enabled: true);
        break;
      case search.FoodModifierType.sizePortion:
        // Pre-select the size whose label/phrase actually matches the
        // user's typed query. Without this the dropdown defaulted to
        // whatever `mod.phrase` happened to be (often "M"), so a search
        // for "large coffee" rendered Medium highlighted. Scan group
        // options for the strongest keyword hit; fall back to mod.phrase
        // only when nothing matches.
        final initial = _matchSizeFromQuery(widget.item.name, mod) ?? mod.phrase;
        _modifierStates[mod.phrase] = _ModifierState(selectedPhrase: initial, enabled: true);
        break;
      case search.FoodModifierType.doneness:
      case search.FoodModifierType.cookingMethod:
        _modifierStates[mod.phrase] = _ModifierState(selectedPhrase: mod.phrase, enabled: true);
        break;
      case search.FoodModifierType.removal:
        _modifierStates[mod.phrase] = _ModifierState(enabled: true);
        break;
      default:
        _modifierStates[mod.phrase] = _ModifierState(enabled: true);
    }
  }

  @override
  void didUpdateWidget(_NLItemSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-fetch alternatives on first expand
    if (widget.isExpanded && !oldWidget.isExpanded && !_altsFetched) {
      _fetchAlternatives(widget.item.name);
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _weightCtrl.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    _modSearchCtrl.dispose();
    _modSearchDebounce?.cancel();
    super.dispose();
  }

  /// Return the phrase of the group option that best matches a size
  /// keyword in the user's free-text food query, or null if no signal.
  /// Order matters — check long forms before single-letter aliases so
  /// "extra large" wins over "large", "large" wins over "l", etc.
  static String? _matchSizeFromQuery(String query, search.FoodModifier mod) {
    if (mod.groupOptions.isEmpty) return null;
    final q = query.toLowerCase();
    // Ordered (keyword, ranked size aliases). Longer/more specific first.
    const sizeAliases = <String, List<String>>{
      'extra large': ['extra large', 'xl', 'xtra large', 'jumbo', 'large'],
      'jumbo':       ['jumbo', 'extra large', 'xl', 'large'],
      'xl':          ['xl', 'extra large', 'jumbo', 'large'],
      'large':       ['large', 'big', 'l', 'lg'],
      'big':         ['big', 'large', 'l', 'lg'],
      'medium':      ['medium', 'm', 'med', 'regular', 'standard'],
      'regular':     ['regular', 'medium', 'm'],
      'small':       ['small', 's', 'sm', 'mini', 'kids'],
      'mini':        ['mini', 'small', 's'],
      'kids':        ['kids', 'kid', 'child', 'small', 's'],
    };
    String? matchedAlias;
    for (final keyword in sizeAliases.keys) {
      // word-boundary match so "ml" doesn't trip the "l" alias
      final re = RegExp(r'\b' + RegExp.escape(keyword) + r'\b');
      if (re.hasMatch(q)) {
        matchedAlias = keyword;
        break;
      }
    }
    if (matchedAlias == null) return null;
    final candidates = sizeAliases[matchedAlias]!;
    // Find the group option whose label or phrase matches any candidate.
    for (final cand in candidates) {
      final candLower = cand.toLowerCase();
      for (final opt in mod.groupOptions) {
        if (opt.label.toLowerCase() == candLower ||
            opt.phrase.toLowerCase() == candLower) {
          return opt.phrase;
        }
      }
      for (final opt in mod.groupOptions) {
        if (opt.label.toLowerCase().contains(candLower) ||
            opt.phrase.toLowerCase().contains(candLower)) {
          return opt.phrase;
        }
      }
    }
    return null;
  }

  int _parseQtyFromAmount(String? amount) {
    if (amount == null || amount.isEmpty) return 1;
    final match = RegExp(r'(\d+)').firstMatch(amount);
    if (match != null) {
      final n = int.tryParse(match.group(1)!);
      if (n != null && n > 0) return n;
    }
    return 1;
  }

  /// Calories: per-serving cal * weightG / servingWeight + modifier deltas
  int get displayCalories {
    int baseCal;
    if (_selectedAlt != null) {
      final altBaseWeight = _selectedAlt!.servingWeightG ?? _selectedAlt!.weightPerUnitG ?? 100.0;
      baseCal = (_selectedAlt!.calories * _weightG / altBaseWeight).round();
    } else {
      final origW = widget.item.weightG;
      if (origW != null && origW > 0) {
        final calPer100 = widget.item.calories / _parseOriginalQty / origW * 100;
        baseCal = (calPer100 * _weightG / 100).round();
      } else {
        baseCal = (widget.item.calories / _parseOriginalQty * _qty).round();
      }
    }
    // Add modifier deltas
    int modifierTotal = 0;
    for (final mod in widget.item.modifiers) {
      final state = _modifierStates[mod.phrase];
      if (state == null) continue;
      modifierTotal += _calcModifierCalDelta(mod, state);
    }
    // Also add any user-added modifiers not in original list
    for (final entry in _modifierStates.entries) {
      final isOriginal = widget.item.modifiers.any((m) => m.phrase == entry.key);
      if (!isOriginal) {
        final addedMod = _modSearchResults.where((m) => m.phrase == entry.key).firstOrNull;
        if (addedMod != null) {
          modifierTotal += _calcModifierCalDelta(addedMod, entry.value);
        }
      }
    }
    return baseCal + modifierTotal;
  }

  int _calcModifierCalDelta(search.FoodModifier mod, _ModifierState state) {
    if (!state.enabled) return 0;
    switch (mod.type) {
      case search.FoodModifierType.addon:
        if (mod.perGram != null && state.weightG != null) {
          return (mod.perGram!.calories * state.weightG!).round();
        }
        return mod.delta['calories']?.round() ?? 0;
      case search.FoodModifierType.doneness:
      case search.FoodModifierType.cookingMethod:
      case search.FoodModifierType.sizePortion:
        if (mod.groupOptions.isNotEmpty && state.selectedPhrase != null) {
          final opt = mod.groupOptions.where((o) => o.phrase == state.selectedPhrase).firstOrNull;
          if (opt != null) return opt.calDelta;
        }
        return mod.delta['calories']?.round() ?? 0;
      case search.FoodModifierType.removal:
        return state.enabled ? (mod.delta['calories']?.round() ?? 0) : 0;
      default:
        return 0;
    }
  }

  String get displayName => _selectedAlt?.name ?? widget.item.name;

  void _openFlagDialog() {
    showFoodReportDialog(
      context,
      apiClient: widget.apiClient,
      foodName: displayName,
      originalCalories: displayCalories,
      originalProtein: widget.item.proteinG,
      originalCarbs: widget.item.carbsG,
      originalFat: widget.item.fatG,
      dataSource: 'ai_analysis',
    );
  }

  String get _displayAmount {
    if (_qty > 1) return '$_qty×';
    return '';
  }

  String buildDescription() {
    final name = displayName;
    final modParts = <String>[];
    for (final mod in widget.item.modifiers) {
      final state = _modifierStates[mod.phrase];
      if (state == null) continue;
      if (mod.type == search.FoodModifierType.doneness ||
          mod.type == search.FoodModifierType.cookingMethod ||
          mod.type == search.FoodModifierType.sizePortion) {
        modParts.add(state.selectedPhrase ?? mod.phrase);
      } else if (mod.type == search.FoodModifierType.addon && state.enabled) {
        final w = state.weightG?.round() ?? mod.defaultWeightG?.round();
        modParts.add('${w}g ${mod.displayLabel ?? mod.phrase}');
      } else if (mod.type == search.FoodModifierType.removal && state.enabled) {
        modParts.add(mod.phrase);
      }
    }
    // Include user-added modifiers
    for (final entry in _modifierStates.entries) {
      final isOriginal = widget.item.modifiers.any((m) => m.phrase == entry.key);
      if (!isOriginal && entry.value.enabled) {
        final w = entry.value.weightG?.round();
        modParts.add(w != null ? '${w}g ${entry.key}' : entry.key);
      }
    }
    final modStr = modParts.isNotEmpty ? ' (${modParts.join(", ")})' : '';
    if (_qty > 1) return '$_qty x $name$modStr, ${_weightG.round()}g';
    return '$name$modStr, ${_weightG.round()}g';
  }

  Future<void> _fetchAlternatives(String query) async {
    setState(() {
      _altsLoading = true;
      _altsError = null;
    });
    try {
      final results = await widget.searchService.searchAlternatives(query, widget.userId);
      if (!mounted) return;
      setState(() {
        _alternatives = results;
        _altsLoading = false;
        _altsFetched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _altsLoading = false;
        _altsError = 'Couldn\'t load alternatives';
        _altsFetched = true;
      });
    }
  }

  void _onAltSelected(search.FoodSearchResult alt) {
    final oldPieceWeight = _selectedAlt?.weightPerUnitG ?? _originalPieceWeight;
    setState(() {
      _selectedAlt = alt;
      // Auto-adjust weight if piece weight differs
      if (alt.weightPerUnitG != null && alt.weightPerUnitG! > 0) {
        _weightG = _qty * alt.weightPerUnitG!;
        _weightCtrl.text = _weightG.round().toString();
      } else if (oldPieceWeight != null && oldPieceWeight > 0) {
        // Keep same total weight pattern
      }
    });
    widget.onStateChanged();
  }

  void _onOriginalSelected() {
    setState(() {
      _selectedAlt = null;
      // Restore original weight
      _weightG = widget.item.weightG ?? 100.0;
      _weightCtrl.text = _weightG.round().toString();
    });
    widget.onStateChanged();
  }

  void _onMiniSearch(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      // Revert to original alternatives
      _fetchAlternatives(widget.item.name);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchAlternatives(query.trim());
    });
  }

  void _updateQty(int newQty) {
    if (newQty < 1 || newQty > 99) return;
    final pieceWeight = _selectedAlt?.weightPerUnitG ?? _originalPieceWeight;
    setState(() {
      _qty = newQty;
      _qtyCtrl.text = newQty.toString();
      // Auto-adjust total weight if we know piece weight
      if (pieceWeight != null && pieceWeight > 0) {
        _weightG = newQty * pieceWeight;
        _weightCtrl.text = _weightG.round().toString();
      }
    });
    widget.onStateChanged();
  }

  void _updateWeight(double newWeight) {
    if (newWeight < 1 || newWeight > 9999) return;
    setState(() {
      _weightG = newWeight;
      _weightCtrl.text = newWeight.round().toString();
    });
    widget.onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final glassSurface = widget.isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: widget.isExpanded ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: widget.isExpanded ? elevated : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: widget.isExpanded
              ? Border.all(color: widget.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row (always visible) ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_displayAmount.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(_displayAmount, style: TextStyle(color: textMuted, fontSize: 12)),
                ],
                const SizedBox(width: 10),
                Text(
                  '$displayCalories',
                  style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(' kcal', style: TextStyle(color: textMuted, fontSize: 11)),
                const SizedBox(width: 4),
                _FlagIconButton(
                  isDark: widget.isDark,
                  onTap: () => _openFlagDialog(),
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: widget.isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, size: 18, color: textMuted.withValues(alpha: 0.6)),
                ),
              ],
            ),

            // ── Divider for collapsed rows ──
            if (!widget.isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Divider(
                  height: 1, thickness: 0.5,
                  color: widget.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                ),
              ),

            // ── Expanded section ──
            if (widget.isExpanded) ...[
              const SizedBox(height: 10),

              // Qty + Weight steppers
              Row(
                children: [
                  _buildStepper(
                    controller: _qtyCtrl,
                    label: 'qty',
                    onDecrease: () => _updateQty(_qty - 1),
                    onIncrease: () => _updateQty(_qty + 1),
                    onSubmitted: (v) {
                      final n = int.tryParse(v);
                      if (n != null) _updateQty(n);
                    },
                    fieldWidth: 36,
                    glassSurface: glassSurface,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  const SizedBox(width: 12),
                  _buildStepper(
                    controller: _weightCtrl,
                    label: 'g',
                    onDecrease: () => _updateWeight(_weightG - 10),
                    onIncrease: () => _updateWeight(_weightG + 10),
                    onSubmitted: (v) {
                      final n = double.tryParse(v);
                      if (n != null) _updateWeight(n);
                    },
                    fieldWidth: 46,
                    glassSurface: glassSurface,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  const Spacer(),
                  // Log this item button
                  _buildLogButton(teal),
                ],
              ),

              const SizedBox(height: 10),

              // ── Modifier controls ──
              if (widget.item.modifiers.isNotEmpty || _modifierStates.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildModifierSection(textPrimary, textMuted, teal, glassSurface, elevated),
                ),

              // ── Mini search bar ──
              GestureDetector(
                onTap: () {}, // absorb tap so it doesn't collapse
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(fontSize: 13, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search alternatives...',
                      hintStyle: TextStyle(fontSize: 13, color: textMuted.withValues(alpha: 0.5)),
                      prefixIcon: Icon(Icons.search, size: 18, color: textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: glassSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _onMiniSearch,
                    onTap: () {}, // prevent parent GestureDetector
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Alternatives list ──
              _buildAlternativesList(textPrimary, textMuted, teal, glassSurface),

              // Hint text
              if (widget.showHint) ...[
                const SizedBox(height: 6),
                Text(
                  'Tap items to adjust or pick alternatives',
                  style: TextStyle(fontSize: 11, color: textMuted.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  int _getOriginalCalPer100g() {
    final w = widget.item.weightG;
    if (w != null && w > 0) {
      return (widget.item.calories / _parseOriginalQty / w * 100).round();
    }
    return widget.item.calories;
  }

  Widget _buildAltRow({
    required String name,
    required int calPer100g,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textMuted,
    required Color teal,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 18,
              color: isSelected ? teal : textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? textPrimary : textMuted,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: 10, color: textMuted.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$calPer100g cal/100g',
              style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper({
    required TextEditingController controller,
    required String label,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
    required ValueChanged<String> onSubmitted,
    required double fieldWidth,
    required Color glassSurface,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return GestureDetector(
      onTap: () {}, // absorb tap so it doesn't collapse
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrease,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
              child: Icon(Icons.remove, size: 14, color: textMuted),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: fieldWidth,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                filled: true,
                fillColor: glassSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 12, color: textMuted)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onIncrease,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
              child: Icon(Icons.add, size: 14, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierControl(search.FoodModifier mod, Color textPrimary, Color textMuted, Color teal, Color glassSurface) {
    final state = _modifierStates[mod.phrase];
    if (state == null) return const SizedBox.shrink();

    switch (mod.type) {
      case search.FoodModifierType.addon:
        return _buildAddonControl(mod, state, textPrimary, textMuted, teal, glassSurface);
      case search.FoodModifierType.doneness:
        return _buildDonenessControl(mod, state, textPrimary, textMuted, teal, glassSurface);
      case search.FoodModifierType.cookingMethod:
      case search.FoodModifierType.sizePortion:
        return _buildDropdownControl(mod, state, textPrimary, textMuted, teal, glassSurface);
      case search.FoodModifierType.removal:
        return _buildRemovalControl(mod, state, textPrimary, textMuted, teal);
      case search.FoodModifierType.qualityLabel:
      case search.FoodModifierType.stateTemp:
        return _buildInfoTag(mod, textMuted);
    }
  }

  Widget _buildDonenessControl(search.FoodModifier mod, _ModifierState state, Color textPrimary, Color textMuted, Color teal, Color glassSurface) {
    if (mod.groupOptions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Doneness', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: mod.groupOptions.map((opt) {
              final isSelected = state.selectedPhrase == opt.phrase;
              return GestureDetector(
                onTap: () {
                  setState(() => state.selectedPhrase = opt.phrase);
                  widget.onStateChanged();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? teal.withValues(alpha: 0.15) : glassSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? teal : Colors.transparent, width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(opt.label, style: TextStyle(fontSize: 11, color: isSelected ? teal : textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                      Text('${opt.calDelta >= 0 ? "+" : ""}${opt.calDelta}', style: TextStyle(fontSize: 9, color: textMuted)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownControl(search.FoodModifier mod, _ModifierState state, Color textPrimary, Color textMuted, Color teal, Color glassSurface) {
    if (mod.groupOptions.isEmpty) return const SizedBox.shrink();
    final calDelta = _calcModifierCalDelta(mod, state);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(mod.type == search.FoodModifierType.cookingMethod ? Icons.local_fire_department : Icons.straighten, size: 14, color: textMuted),
          const SizedBox(width: 4),
          Text(mod.type == search.FoodModifierType.cookingMethod ? 'Cooking' : 'Size', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(6)),
            child: DropdownButton<String>(
              value: state.selectedPhrase,
              underline: const SizedBox.shrink(),
              isDense: true,
              style: TextStyle(fontSize: 12, color: textPrimary),
              dropdownColor: glassSurface,
              items: mod.groupOptions.map((opt) => DropdownMenuItem(
                value: opt.phrase,
                child: Text('${opt.label} (${opt.calDelta >= 0 ? "+" : ""}${opt.calDelta})', style: TextStyle(fontSize: 12, color: textPrimary)),
              )).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => state.selectedPhrase = v);
                widget.onStateChanged();
              },
            ),
          ),
          const Spacer(),
          Text('${calDelta >= 0 ? "+" : ""}$calDelta', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500)),
          Text(' kcal', style: TextStyle(fontSize: 10, color: textMuted.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildRemovalControl(search.FoodModifier mod, _ModifierState state, Color textPrimary, Color textMuted, Color teal) {
    final calDelta = state.enabled ? (mod.delta['calories']?.round() ?? 0) : 0;
    final label = mod.displayLabel ?? mod.phrase.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20, height: 20,
            child: Checkbox(
              value: state.enabled,
              onChanged: (v) {
                setState(() => state.enabled = v ?? false);
                widget.onStateChanged();
              },
              activeColor: teal,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: textPrimary))),
          Text('$calDelta', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500)),
          Text(' kcal', style: TextStyle(fontSize: 10, color: textMuted)),
        ],
      ),
    );
  }

  Widget _buildInfoTag(search.FoodModifier mod, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.label_outline, size: 14, color: textMuted.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(mod.displayLabel ?? mod.phrase, style: TextStyle(fontSize: 11, color: textMuted, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildMiniStepper({
    required String value,
    required String label,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
    required Color glassSurface,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDecrease,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
            child: Icon(Icons.remove, size: 12, color: textMuted),
          ),
        ),
        const SizedBox(width: 3),
        Container(
          constraints: const BoxConstraints(minWidth: 30),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
          child: Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 10, color: textMuted)),
        const SizedBox(width: 3),
        GestureDetector(
          onTap: onIncrease,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
            child: Icon(Icons.add, size: 12, color: textMuted),
          ),
        ),
      ],
    );
  }

  void _onModifierSearch(String query) {
    _modSearchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _modSearchResults = [];
        _modSearchLoading = false;
      });
      return;
    }
    setState(() => _modSearchLoading = true);
    _modSearchDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await widget.searchService.searchModifiers(query.trim(), widget.userId);
        if (!mounted) return;
        setState(() {
          _modSearchResults = results;
          _modSearchLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _modSearchLoading = false);
      }
    });
  }

  void _addModifierFromSearch(search.FoodModifier mod) {
    setState(() {
      _modifierStates[mod.phrase] = _ModifierState(
        weightG: mod.defaultWeightG,
        count: mod.weightPerUnitG != null && mod.defaultWeightG != null
            ? (mod.defaultWeightG! / mod.weightPerUnitG!).round()
            : null,
        enabled: true,
        selectedPhrase: mod.groupOptions.isNotEmpty ? mod.phrase : null,
      );
      _modSearchCtrl.clear();
    });
    widget.onStateChanged();
  }

  Widget _buildLogButton(Color teal) {
    if (widget.logState == _LogState.loading) {
      return SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: teal));
    }
    if (widget.logState == _LogState.done) {
      return Icon(Icons.check_circle, color: teal, size: 26);
    }
    return GestureDetector(
      onTap: () => widget.onLog(buildDescription()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: teal),
            const SizedBox(width: 2),
            Text('Log', style: TextStyle(fontSize: 12, color: teal, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

