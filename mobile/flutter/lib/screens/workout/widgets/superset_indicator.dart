import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';

/// A reusable widget for displaying superset indicators and connectors.
///
/// This widget provides visual elements for:
/// - Superset header badges (SUPERSET 1, SUPERSET 2, etc.)
/// - Connector lines between superset exercises
/// - Inline superset badges (SS1, SS2, etc.)
/// - "No rest" indicators between superset pairs
class SupersetIndicator extends StatelessWidget {
  /// The superset group number
  final int groupNumber;

  /// Whether to show as a header (SUPERSET X) or inline badge (SSX)
  final bool isHeader;

  /// Whether this is the first exercise in the superset pair
  final bool isFirst;

  /// Whether to show the connector line below
  final bool showConnector;

  /// Optional custom color (defaults to purple)
  final Color? color;

  /// Whether the superset is currently active (being worked on)
  final bool isActive;

  const SupersetIndicator({
    super.key,
    required this.groupNumber,
    this.isHeader = false,
    this.isFirst = true,
    this.showConnector = false,
    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.purple;

    if (isHeader) {
      return _buildHeader(themeColor);
    }

    return _buildInlineBadge(themeColor);
  }

  /// Build the header version (SUPERSET X) with icon
  Widget _buildHeader(Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(isActive ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: themeColor.withOpacity(isActive ? 0.5 : 0.3),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link_rounded,
            size: 14,
            color: themeColor,
          ),
          const SizedBox(width: 6),
          Text(
            'SUPERSET $groupNumber',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: themeColor,
              letterSpacing: 0.8,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build the inline badge version (SSX) for compact display
  Widget _buildInlineBadge(Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 10, color: themeColor),
          const SizedBox(width: 3),
          Text(
            'SS$groupNumber',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// A connector line widget for visually linking superset exercises
class SupersetConnector extends StatelessWidget {
  /// Whether to show the "No rest" text
  final bool showNoRestLabel;

  /// Whether the superset is currently active
  final bool isActive;

  /// Custom color for the connector
  final Color? color;

  /// Height of the connector line
  final double height;

  /// Left offset for alignment with exercise cards
  final double leftOffset;

  const SupersetConnector({
    super.key,
    this.showNoRestLabel = true,
    this.isActive = false,
    this.color,
    this.height = 24,
    this.leftOffset = 48,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.purple;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: leftOffset),
          // Vertical connector line - THICKER and more visible
          Container(
            width: 3, // Thicker line (was 2)
            height: height,
            decoration: BoxDecoration(
              color: themeColor, // Full opacity (was 0.5-0.7)
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (showNoRestLabel) ...[
            const SizedBox(width: 12),
            // "No rest" label with arrow
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: themeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'No rest between',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A grouped card wrapper for displaying superset exercises together (supports 2+ exercises)
/// Uses the user's accent color for prominent visibility
class SupersetGroupCard extends ConsumerWidget {
  /// All exercises in this superset (ordered by supersetOrder)
  final List<Widget> exercises;

  /// The superset group number
  final int groupNumber;

  /// Whether this superset is currently active
  final bool isActive;

  /// Callback when the superset header is tapped
  final VoidCallback? onHeaderTap;

  /// Callback when "Break Superset" is triggered
  final VoidCallback? onBreakSuperset;

  /// Callback when "Swap Order" is triggered (only for 2 exercises)
  final VoidCallback? onSwapOrder;

  /// Callback when "Reorder" is triggered (for 3+ exercises)
  final VoidCallback? onReorderExercises;

  /// Index for ReorderableListView - if provided, drag handle enables reordering
  final int? reorderIndex;

  const SupersetGroupCard({
    super.key,
    required this.exercises,
    required this.groupNumber,
    this.isActive = false,
    this.onHeaderTap,
    this.onBreakSuperset,
    this.onSwapOrder,
    this.onReorderExercises,
    this.reorderIndex,
  });

  /// Get the display label based on exercise count
  String get _typeLabel {
    return switch (exercises.length) {
      2 => 'SUPERSET',
      3 => 'TRI-SET',
      _ => 'GIANT SET',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    // Determine text color based on accent brightness
    final isLightAccent = ref.watch(accentColorProvider).isLightColor;
    final headerTextColor = isLightAccent ? Colors.black87 : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Reduced from 16
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14), // Slightly smaller radius
        border: Border.all(
          color: accentColor, // SOLID accent color border
          width: 2.5, // Slightly thinner but still visible
        ),
        color: accentColor.withOpacity(0.06), // Subtle tinted background
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Superset header with SOLID accent background - MORE COMPACT
          Material(
            color: accentColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(11.5), // Account for border width
            ),
            child: InkWell(
              onTap: onHeaderTap,
              onLongPress: () {
                // Haptic feedback for long press
                HapticFeedback.mediumImpact();
                onBreakSuperset?.call();
              },
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11.5),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // More compact
                child: Row(
                  children: [
                    // Drag handle icon for reordering - wrapped with ReorderableDragStartListener if reorderIndex provided
                    if (reorderIndex != null)
                      ReorderableDragStartListener(
                        index: reorderIndex!,
                        child: Icon(
                          Icons.drag_handle,
                          size: 16,
                          color: headerTextColor.withOpacity(0.7),
                        ),
                      )
                    else
                      Icon(
                        Icons.drag_handle,
                        size: 16,
                        color: headerTextColor.withOpacity(0.7),
                      ),
                    const SizedBox(width: 6),
                    // Link icon - smaller
                    Icon(
                      Icons.link_rounded,
                      size: 14,
                      color: headerTextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_typeLabel $groupNumber',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: headerTextColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: headerTextColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Swap order button - only for 2 exercises
                    if (exercises.length == 2 && onSwapOrder != null)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onSwapOrder?.call();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: headerTextColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swap_vert,
                                size: 12,
                                color: headerTextColor.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Swap',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: headerTextColor.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Edit button - for 3+ exercises (reorder & remove)
                    if (exercises.length >= 3 && onReorderExercises != null)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onReorderExercises?.call();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: headerTextColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 12,
                                color: headerTextColor.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: headerTextColor.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if ((exercises.length == 2 && onSwapOrder != null) ||
                        (exercises.length >= 3 && onReorderExercises != null))
                      const SizedBox(width: 6),
                    // Break superset button - tap icon for break
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onBreakSuperset?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: headerTextColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link_off,
                              size: 12,
                              color: headerTextColor.withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Break',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: headerTextColor.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Render all exercises with connectors between them
          for (int i = 0; i < exercises.length; i++) ...[
            exercises[i],
            // Add connector between exercises (not after the last one)
            if (i < exercises.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SupersetConnector(
                  color: accentColor,
                  isActive: isActive,
                  leftOffset: 28,
                  height: 18, // Shorter connector
                ),
              ),
          ],

          // Minimal bottom padding
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// A floating action button for creating supersets
class CreateSupersetFab extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isVisible;

  const CreateSupersetFab({
    super.key,
    required this.onPressed,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppColors.purple,
      icon: const Icon(Icons.link, color: Colors.white),
      label: const Text(
        'Create Superset',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A bottom sheet for selecting exercises to pair in a superset
class SupersetPairingSheet extends StatefulWidget {
  /// List of available exercises to choose from
  final List<String> exerciseNames;

  /// Index of the exercise being paired (already selected)
  final int? selectedIndex;

  /// Callback when a pair is selected
  final void Function(int firstIndex, int secondIndex)? onPairSelected;

  const SupersetPairingSheet({
    super.key,
    required this.exerciseNames,
    this.selectedIndex,
    this.onPairSelected,
  });

  @override
  State<SupersetPairingSheet> createState() => _SupersetPairingSheetState();
}

class _SupersetPairingSheetState extends State<SupersetPairingSheet> {
  int? _firstSelection;
  int? _secondSelection;

  @override
  void initState() {
    super.initState();
    if (widget.selectedIndex != null) {
      _firstSelection = widget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: AppColors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Superset',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Select two exercises to pair',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Selection hint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.cyan.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.cyan,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _firstSelection == null
                        ? 'Tap the first exercise'
                        : _secondSelection == null
                            ? 'Now tap the second exercise'
                            : 'Tap "Create" to confirm',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Exercise list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.exerciseNames.length,
              itemBuilder: (context, index) {
                final isFirst = _firstSelection == index;
                final isSecond = _secondSelection == index;
                final isSelected = isFirst || isSecond;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_firstSelection == null) {
                        _firstSelection = index;
                      } else if (_firstSelection == index) {
                        _firstSelection = null;
                        _secondSelection = null;
                      } else if (_secondSelection == null) {
                        _secondSelection = index;
                      } else if (_secondSelection == index) {
                        _secondSelection = null;
                      } else {
                        // Both selected, replace second
                        _secondSelection = index;
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.purple.withOpacity(0.15)
                          : AppColors.elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.purple.withOpacity(0.5)
                            : AppColors.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Selection number
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.purple
                                : AppColors.glassSurface,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isSelected
                                ? Text(
                                    isFirst ? '1' : '2',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.exerciseNames[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.purple,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _firstSelection != null && _secondSelection != null
                  ? () {
                      widget.onPairSelected?.call(
                        _firstSelection!,
                        _secondSelection!,
                      );
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                disabledBackgroundColor: AppColors.glassSurface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _firstSelection != null && _secondSelection != null
                        ? 'Create Superset'
                        : 'Select Two Exercises',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
