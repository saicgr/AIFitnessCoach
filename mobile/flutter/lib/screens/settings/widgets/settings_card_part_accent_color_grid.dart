part of 'settings_card.dart';


/// Simple 4x3 grid of preset accent colors.
/// Colors with a `gatingCosmeticId` show a lock icon until the user owns
/// the corresponding cosmetic (unlocked via level-up).
class _AccentColorGrid extends ConsumerWidget {
  final AccentColor currentAccent;
  final ValueChanged<AccentColor> onColorSelected;
  const _AccentColorGrid({required this.currentAccent, required this.onColorSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cosmeticsState = ref.watch(cosmeticsProvider);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: AccentColor.values.length,
      itemBuilder: (context, index) {
        final accent = AccentColor.values[index];
        final isSelected = accent == currentAccent;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final gatingId = accent.gatingCosmeticId;
        final isLocked = gatingId != null && !cosmeticsState.ownsCosmetic(gatingId);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            if (isLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unlocks at Level ${accent.unlockLevel} — keep going!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            onColorSelected(accent);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: isLocked ? 0.4 : 1.0,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.previewColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected ? [BoxShadow(color: accent.previewColor.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)] : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 24) : null,
                    ),
                  ),
                  if (isLocked)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, color: Colors.white, size: 14),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isLocked ? 'Lvl ${accent.unlockLevel}' : accent.displayName,
                style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}


/// A tile for timezone selection in the bottom sheet.
class _TimezoneOptionTile extends StatelessWidget {
  final TimezoneData timezone;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimezoneOptionTile({
    required this.timezone,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timezone.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    ),
                  ),
                  Text(
                    '${timezone.region} • ${timezone.currentOffset}',
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}


/// A tile for progression pace selection in the bottom sheet.
class _ProgressionPaceOptionTile extends StatelessWidget {
  final ProgressionPace pace;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProgressionPaceOptionTile({
    required this.pace,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (pace) {
      case ProgressionPace.slow:
        return Icons.slow_motion_video;
      case ProgressionPace.medium:
        return Icons.speed;
      case ProgressionPace.fast:
        return Icons.flash_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cyan.withValues(alpha: 0.15) : AppColorsLight.cyan.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              color: isSelected ? AppColors.cyan : textMuted,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pace.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pace.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pace.bestFor,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}


/// A tile for workout type selection in the bottom sheet.
class _WorkoutTypeOptionTile extends StatelessWidget {
  final WorkoutType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _WorkoutTypeOptionTile({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case WorkoutType.strength:
        return Icons.fitness_center;
      case WorkoutType.cardio:
        return Icons.directions_run;
      case WorkoutType.mixed:
        return Icons.sports_gymnastics;
      case WorkoutType.mobility:
        return Icons.self_improvement;
      case WorkoutType.recovery:
        return Icons.spa;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cyan.withValues(alpha: 0.15) : AppColorsLight.cyan.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              color: isSelected ? AppColors.cyan : textMuted,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                      if (type == WorkoutType.mixed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyan,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}


/// A bottom sheet for selecting equipment.
class _EquipmentSelectorSheet extends StatefulWidget {
  final List<String> initialEquipment;
  final ValueChanged<List<String>> onSave;

  const _EquipmentSelectorSheet({
    required this.initialEquipment,
    required this.onSave,
  });

  @override
  State<_EquipmentSelectorSheet> createState() => _EquipmentSelectorSheetState();
}


class _EquipmentSelectorSheetState extends State<_EquipmentSelectorSheet> {
  late Set<String> _selectedEquipment;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedEquipment = Set.from(widget.initialEquipment);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredEquipment {
    if (_searchQuery.isEmpty) {
      return commonEquipmentOptions;
    }
    return commonEquipmentOptions
        .where((e) => getEquipmentDisplayName(e).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleEquipment(String equipment) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedEquipment.contains(equipment)) {
        _selectedEquipment.remove(equipment);
      } else {
        _selectedEquipment.add(equipment);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'My Equipment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select all equipment you have access to',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search equipment...',
                  prefixIcon: Icon(Icons.search, color: textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.cyan),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.pureBlack.withValues(alpha: 0.3) : Colors.grey[100],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Selected count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedEquipment.length} selected',
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                  if (_selectedEquipment.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _selectedEquipment.clear()),
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Equipment grid
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredEquipment.length,
                itemBuilder: (context, index) {
                  final equipment = _filteredEquipment[index];
                  final isSelected = _selectedEquipment.contains(equipment);
                  return _EquipmentOptionTile(
                    equipment: equipment,
                    isSelected: isSelected,
                    onTap: () => _toggleEquipment(equipment),
                  );
                },
              ),
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(_selectedEquipment.toList());
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Equipment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// A tile for equipment selection.
class _EquipmentOptionTile extends StatelessWidget {
  final String equipment;
  final bool isSelected;
  final VoidCallback onTap;

  const _EquipmentOptionTile({
    required this.equipment,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cyan.withValues(alpha: 0.15) : AppColorsLight.cyan.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? AppColors.cyan : textMuted,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                getEquipmentDisplayName(equipment),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// A tile for consistency mode selection in the bottom sheet.
class _ConsistencyModeOptionTile extends StatelessWidget {
  final ConsistencyMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConsistencyModeOptionTile({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (mode) {
      case ConsistencyMode.vary:
        return Icons.shuffle;
      case ConsistencyMode.consistent:
        return Icons.repeat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cyan.withValues(alpha: 0.15) : AppColorsLight.cyan.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              color: isSelected ? AppColors.cyan : textMuted,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        mode.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                      if (mode == ConsistencyMode.consistent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'For Learning',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}


/// A bottom sheet for selecting workout days with quick change capability.
class _WorkoutDaysSelectorSheet extends ConsumerStatefulWidget {
  final List<int> initialDays;
  final String userId;
  final String? activeProfileId;

  const _WorkoutDaysSelectorSheet({
    required this.initialDays,
    required this.userId,
    this.activeProfileId,
  });

  @override
  ConsumerState<_WorkoutDaysSelectorSheet> createState() =>
      _WorkoutDaysSelectorSheetState();
}

