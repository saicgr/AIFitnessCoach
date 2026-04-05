part of 'food_browser_panel.dart';

/// Methods extracted from _NLItemSectionState
extension __NLItemSectionStateExt on _NLItemSectionState {

  Widget _buildAlternativesList(Color textPrimary, Color textMuted, Color teal, Color glassSurface) {
    // Loading shimmer
    if (_altsLoading) {
      return Column(
        children: List.generate(3, (_) => Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: glassSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
        )),
      );
    }

    // Error state
    if (_altsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: textMuted),
            const SizedBox(width: 6),
            Text(_altsError!, style: TextStyle(fontSize: 12, color: textMuted)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _fetchAlternatives(widget.item.name),
              child: Text('Retry', style: TextStyle(fontSize: 12, color: teal, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    // Build list: original item first as radio, then alternatives
    final hasAlts = _alternatives.isNotEmpty;
    final isOriginalSelected = _selectedAlt == null;

    return GestureDetector(
      onTap: () {}, // absorb taps so list doesn't collapse
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original parsed item (always shown as first radio option)
          _buildAltRow(
            name: widget.item.name,
            calPer100g: _getOriginalCalPer100g(),
            isSelected: isOriginalSelected,
            onTap: _onOriginalSelected,
            textPrimary: textPrimary,
            textMuted: textMuted,
            teal: teal,
          ),
          // Alternative items from search
          if (hasAlts)
            ...(_alternatives.take(6).map((alt) => _buildAltRow(
              name: alt.name,
              calPer100g: alt.calories,
              isSelected: _selectedAlt?.id == alt.id,
              onTap: () => _onAltSelected(alt),
              textPrimary: textPrimary,
              textMuted: textMuted,
              teal: teal,
              subtitle: alt.brand,
            )))
          else if (_altsFetched && !_altsLoading)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'Only match found',
                style: TextStyle(fontSize: 11, color: textMuted.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }


  // ── Modifier section ──

  Widget _buildModifierSection(Color textPrimary, Color textMuted, Color teal, Color glassSurface, Color elevated) {
    // Backend-provided modifiers (excluding doneness/cooking from defaults)
    final backendModifiers = <search.FoodModifier>[...widget.item.modifiers];
    // Include user-added modifiers from search
    for (final entry in _modifierStates.entries) {
      final isOriginal = widget.item.modifiers.any((m) => m.phrase == entry.key);
      if (!isOriginal) {
        final addedMod = _modSearchResults.where((m) => m.phrase == entry.key).firstOrNull;
        if (addedMod != null) backendModifiers.add(addedMod);
      }
    }

    if (backendModifiers.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {}, // absorb tap
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (backendModifiers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('Modifiers', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ),
            // Backend-provided modifiers (addons, removals, doneness, cooking, etc.)
            ...backendModifiers.map((mod) => _buildModifierControl(mod, textPrimary, textMuted, teal, glassSurface)),
          ],
          const SizedBox(height: 8),
          // Modifier search bar
          SizedBox(
            height: 34,
            child: TextField(
              controller: _modSearchCtrl,
              style: TextStyle(fontSize: 12, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Add modifier...',
                hintStyle: TextStyle(fontSize: 12, color: textMuted.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.add_circle_outline, size: 16, color: textMuted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                filled: true,
                fillColor: glassSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              onChanged: _onModifierSearch,
              onTap: () {},
            ),
          ),
          if (_modSearchLoading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: teal)),
            ),
          if (_modSearchResults.isNotEmpty && _modSearchCtrl.text.isNotEmpty)
            ..._modSearchResults.where((m) => !_modifierStates.containsKey(m.phrase)).take(6).map((mod) =>
              GestureDetector(
                onTap: () => _addModifierFromSearch(mod),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 14, color: teal),
                      const SizedBox(width: 6),
                      Expanded(child: Text(mod.displayLabel ?? mod.phrase.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' '), style: TextStyle(fontSize: 12, color: textPrimary))),
                      Text('${(mod.delta['calories']?.round() ?? 0) >= 0 ? "+" : ""}${mod.delta['calories']?.round() ?? 0}', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500)),
                      Text(' kcal', style: TextStyle(fontSize: 10, color: textMuted.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildAddonControl(search.FoodModifier mod, _ModifierState state, Color textPrimary, Color textMuted, Color teal, Color glassSurface) {
    final calDelta = _calcModifierCalDelta(mod, state);
    final label = mod.displayLabel ?? mod.phrase.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w500))),
              Text('${calDelta >= 0 ? "+" : ""}$calDelta', style: TextStyle(fontSize: 11, color: calDelta >= 0 ? teal : Colors.orange, fontWeight: FontWeight.w600)),
              Text(' kcal', style: TextStyle(fontSize: 10, color: textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Weight stepper
              _buildMiniStepper(
                value: '${state.weightG?.round() ?? 0}',
                label: 'g',
                onDecrease: () {
                  final newW = (state.weightG ?? 0) - 5;
                  if (newW < 0) return;
                  setState(() {
                    state.weightG = newW;
                    if (mod.weightPerUnitG != null && mod.weightPerUnitG! > 0) {
                      state.count = (newW / mod.weightPerUnitG!).round();
                    }
                  });
                  widget.onStateChanged();
                },
                onIncrease: () {
                  setState(() {
                    state.weightG = (state.weightG ?? 0) + 5;
                    if (mod.weightPerUnitG != null && mod.weightPerUnitG! > 0) {
                      state.count = (state.weightG! / mod.weightPerUnitG!).round();
                    }
                  });
                  widget.onStateChanged();
                },
                glassSurface: glassSurface,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              // Count stepper (only for countable addons)
              if (mod.weightPerUnitG != null) ...[
                const SizedBox(width: 12),
                _buildMiniStepper(
                  value: '${state.count ?? 0}',
                  label: mod.unitName ?? 'pc',
                  onDecrease: () {
                    final newC = (state.count ?? 0) - 1;
                    if (newC < 0) return;
                    setState(() {
                      state.count = newC;
                      state.weightG = newC * (mod.weightPerUnitG ?? 0);
                    });
                    widget.onStateChanged();
                  },
                  onIncrease: () {
                    setState(() {
                      state.count = (state.count ?? 0) + 1;
                      state.weightG = state.count! * (mod.weightPerUnitG ?? 0);
                    });
                    widget.onStateChanged();
                  },
                  glassSurface: glassSurface,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

}
