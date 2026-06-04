import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/gym_progress_filter_provider.dart';
import '../../../data/repositories/exercise_history_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Reusable per-gym progress filter — a horizontal chip row of
/// "All gyms" + one chip per gym (colored dot + name; archived gyms carry a
/// subtle "Archived" marker).
///
/// Selecting a chip updates [gymProgressFilterProvider] (keyed by [surfaceKey])
/// and fires [onChanged] so the host can refetch. It NEVER touches the active
/// workout gym — it's purely a read-time view filter.
///
/// HIDDEN entirely (renders `SizedBox.shrink`) when ≤1 gym is relevant:
/// fewer than 2 live gym profiles AND fewer than 2 gyms in the supplied
/// [breakdown]. This matches the "only one gym → no clutter" rule.
class GymProgressFilter extends ConsumerWidget {
  /// Opaque key identifying the host surface (e.g. `'exercise:Cable Row'`,
  /// `'strength'`). Drives the per-surface selection + persisted last-pick.
  final String surfaceKey;

  /// Called after the selection changes so the host can refetch. The new
  /// [GymProgressSelection] is already committed to the provider.
  final ValueChanged<GymProgressSelection>? onChanged;

  /// Optional per-exercise gym breakdown (from `ExerciseHistoryResult`). Used
  /// to (a) decide visibility when only some gyms have history and (b) surface
  /// archived gyms that still hold history.
  final List<GymBreakdownEntry> breakdown;

  /// When false, the "All gyms" option is hidden (rare; defaults to true).
  final bool showAllGymsOption;

  /// Horizontal padding around the row.
  final EdgeInsetsGeometry padding;

  const GymProgressFilter({
    super.key,
    required this.surfaceKey,
    this.onChanged,
    this.breakdown = const [],
    this.showAllGymsOption = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveProfiles =
        ref.watch(gymProfilesProvider).valueOrNull ?? const <GymProfile>[];
    final allProfilesAsync = ref.watch(gymProgressProfilesProvider);
    final allProfiles = allProfilesAsync.valueOrNull ?? liveProfiles;

    // Visibility gate: hide unless ≥2 gyms are relevant. Count distinct gyms
    // that either are live profiles OR appear in the per-exercise breakdown.
    final breakdownGymCount =
        breakdown.where((b) => b.gymProfileId != null).length;
    final relevantGymCount =
        liveProfiles.length >= 2 ? liveProfiles.length : breakdownGymCount;
    if (relevantGymCount <= 1) {
      return const SizedBox.shrink();
    }

    final options = buildGymFilterOptions(
      liveProfiles: liveProfiles,
      allProfiles: allProfiles,
      breakdown: breakdown,
    );
    if (options.isEmpty) return const SizedBox.shrink();

    final selection = ref.watch(gymProgressFilterProvider(surfaceKey));
    final notifier = ref.read(gymProgressFilterProvider(surfaceKey).notifier);

    final liveOptions = options.where((o) => !o.isArchived).toList();
    final archivedOptions = options.where((o) => o.isArchived).toList();

    // F3B — when a travel/bodyweight gym is selected, surface a one-line caption
    // that its bodyweight progress is pooled across gyms (not gym-specific).
    final selectedGymId = selection.isAllGyms ? null : selection.gymProfileId;
    final selectedIsBodyweight = selectedGymId != null &&
        _isBodyweightGym(
          allProfiles.where((p) => p.id == selectedGymId).firstOrNull,
        );

    final chipRow = SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [
          if (showAllGymsOption)
            _AllGymsChip(
              selected: selection.isAllGyms,
              onTap: () {
                HapticService.light();
                notifier.selectAllGyms();
                onChanged?.call(GymProgressSelection.allGyms);
              },
            ),
          for (final option in liveOptions)
            _GymChip(
              option: option,
              selected:
                  !selection.isAllGyms && selection.gymProfileId == option.id,
              onTap: () {
                HapticService.light();
                notifier.selectGym(option.id);
                onChanged?.call(GymProgressSelection.gym(option.id));
              },
            ),
          if (archivedOptions.isNotEmpty)
            _ArchivedGroup(
              options: archivedOptions,
              selectedId:
                  selection.isAllGyms ? null : selection.gymProfileId,
              onSelect: (id) {
                HapticService.light();
                notifier.selectGym(id);
                onChanged?.call(GymProgressSelection.gym(id));
              },
            ),
        ],
      ),
    );

    if (!selectedIsBodyweight) return chipRow;

    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chipRow,
        Padding(
          padding: padding.add(const EdgeInsets.only(top: 6, bottom: 2)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.all_inclusive_rounded,
                  size: 13, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Bodyweight is combined across gyms',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// True when a gym profile's progress is the universal bodyweight set: the
  /// dedicated Travel profile, or a hotel/home/outdoor profile with only
  /// portable equipment. Null profile → false.
  static bool _isBodyweightGym(GymProfile? profile) {
    if (profile == null) return false;
    if (profile.isTravelManaged) return true;
    final env = profile.workoutEnvironment.toLowerCase();
    if (!{'hotel', 'home', 'outdoors'}.contains(env)) return false;
    final equipment = profile.equipment.map((e) => e.toLowerCase()).toSet();
    if (equipment.isEmpty) return true;
    const portable = {'bodyweight', 'resistance_bands', 'pull_up_bar'};
    return equipment.every(portable.contains);
  }
}

/// "All gyms" pooled chip.
class _AllGymsChip extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _AllGymsChip({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: _ChipShell(
        selected: selected,
        selectedColor: accent,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.all_inclusive_rounded,
              size: 14,
              color: selected ? accent : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'All gyms',
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single gym chip with its own colored dot.
class _GymChip extends StatelessWidget {
  final GymFilterOption option;
  final bool selected;
  final VoidCallback onTap;

  const _GymChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dotColor = GymProfileColors.fromHex(option.colorHex);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: _ChipShell(
        selected: selected,
        selectedColor: dotColor,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colored dot — disambiguates two same-named gyms by color + id.
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: option.isArchived
                    ? Border.all(
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                        width: 1,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              option.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? dotColor : colorScheme.onSurface,
              ),
            ),
            if (option.isArchived) ...[
              const SizedBox(width: 5),
              _ArchivedBadge(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Collapses archived gyms behind a single "Archived" affordance that opens a
/// menu — keeps the row uncluttered while still surfacing historical gyms.
/// When an archived gym is already selected, the affordance shows it inline.
class _ArchivedGroup extends StatelessWidget {
  final List<GymFilterOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _ArchivedGroup({
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedArchived = options.where((o) => o.id == selectedId).toList();
    final isSelected = selectedArchived.isNotEmpty;
    final Color selectedColor = isSelected
        ? GymProfileColors.fromHex(selectedArchived.first.colorHex)
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: PopupMenuButton<String>(
        tooltip: 'Archived gyms',
        onSelected: onSelect,
        itemBuilder: (context) => options
            .map(
              (o) => PopupMenuItem<String>(
                value: o.id,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: GymProfileColors.fromHex(o.colorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(o.name),
                    const SizedBox(width: 6),
                    Icon(Icons.inventory_2_outlined,
                        size: 13, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            )
            .toList(),
        child: _ChipShell(
          selected: isSelected,
          selectedColor: selectedColor,
          onTap: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 13, color: selectedColor),
              const SizedBox(width: 5),
              Text(
                isSelected ? selectedArchived.first.name : 'Archived',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? selectedColor : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down,
                  size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny "Archived" pill marker shown next to an archived gym chip.
class _ArchivedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Archived',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Shared chip container: rounded, tinted when selected.
class _ChipShell extends StatelessWidget {
  final bool selected;
  final Color selectedColor;
  final VoidCallback? onTap;
  final Widget child;

  const _ChipShell({
    required this.selected,
    required this.selectedColor,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? selectedColor.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? selectedColor.withValues(alpha: 0.6)
              : colorScheme.outline.withValues(alpha: 0.15),
          width: selected ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );

    if (onTap == null) return content;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
