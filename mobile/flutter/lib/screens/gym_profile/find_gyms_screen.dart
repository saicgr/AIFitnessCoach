import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/providers/community_gyms_provider.dart';
import '../../data/providers/gym_profile_provider.dart';
import '../../data/services/community_gyms_service.dart';
import '../../data/services/haptic_service.dart';
import '../../models/equipment_item.dart';
import '../../widgets/glass_sheet.dart';
import '../home/widgets/gym_equipment_sheet.dart';
import '../common/app_refresh_indicator.dart';

/// Find gyms near me (Feature 3B).
///
/// Picker → tap a gym → consensus equipment (confirmed / unconfirmed pills) →
/// "Adopt this gym" (create a profile prefilled from consensus) OR "Report
/// equipment" (reuse [GymEquipmentSheet], persist via /community-gyms/report).
///
/// When the backend returns `catalog_only` (Places key unconfigured / down),
/// the screen surfaces a "search by name" field and shows the nearby canonical
/// catalog. NO mock data — an empty catalog renders a real empty state.
class FindGymsScreen extends ConsumerStatefulWidget {
  const FindGymsScreen({super.key});

  @override
  ConsumerState<FindGymsScreen> createState() => _FindGymsScreenState();
}

class _FindGymsScreenState extends ConsumerState<FindGymsScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// The committed query string driving [nearbyGymsProvider]. Empty = unfiltered.
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final q = _searchController.text.trim();
    if (q == _query) return;
    setState(() => _query = q);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);
    final nearbyAsync = ref.watch(nearbyGymsProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find gyms near me'),
      ),
      body: Column(
        children: [
          _SearchField(
            controller: _searchController,
            onSubmitted: (_) => _submitSearch(),
            onClear: () {
              _searchController.clear();
              if (_query.isNotEmpty) setState(() => _query = '');
            },
          ),
          Expanded(
            child: nearbyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorOrLocationState(
                error: err,
                onRetry: () => ref.invalidate(nearbyGymsProvider(_query)),
              ),
              data: (result) {
                if (result.catalogOnly && result.gyms.isEmpty && _query.isEmpty) {
                  return _CatalogOnlyEmptyState(
                    onSearchHint: () => FocusScope.of(context).requestFocus(FocusNode()),
                  );
                }
                if (result.gyms.isEmpty) {
                  return _EmptyState(query: _query, catalogOnly: result.catalogOnly);
                }
                return AppRefreshIndicator(
                  onRefresh: () async => ref.invalidate(nearbyGymsProvider(_query)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: result.gyms.length + (result.catalogOnly ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (result.catalogOnly && index == 0) {
                        return _CatalogOnlyBanner(colors: colors);
                      }
                      final gym = result.gyms[
                          result.catalogOnly ? index - 1 : index];
                      return _GymRow(
                        gym: gym,
                        onTap: () => _openGymDetail(context, gym),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openGymDetail(BuildContext context, CommunityGym gym) {
    HapticService.light();
    showGlassSheet(
      context: context,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_) => _GymDetailSheet(gym: gym),
    );
  }
}

// =============================================================================
// Search field
// =============================================================================

class _SearchField extends ConsumerWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by name',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClear,
                ),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Gym list row
// =============================================================================

class _GymRow extends ConsumerWidget {
  final CommunityGym gym;
  final VoidCallback onTap;

  const _GymRow({required this.gym, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    final accent = colors.accent;
    final subtitle = [
      if (gym.city != null && gym.city!.isNotEmpty) gym.city!
      else if (gym.address != null && gym.address!.isNotEmpty) gym.address!,
      if (gym.distanceLabel.isNotEmpty) gym.distanceLabel,
    ].join(' · ');

    return Material(
      color: colors.elevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.storefront_outlined, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gym.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: colors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: colors.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Gym detail sheet (consensus + adopt + report)
// =============================================================================

class _GymDetailSheet extends ConsumerWidget {
  final CommunityGym gym;

  const _GymDetailSheet({required this.gym});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    final detailAsync = ref.watch(communityGymDetailProvider(gym.placeId));

    return GlassSheet(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 24 + MediaQuery.of(context).padding.bottom),
        child: detailAsync.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => SizedBox(
            height: 220,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: colors.textMuted, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    "Couldn't load this gym. Pull to retry.",
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(communityGymDetailProvider(gym.placeId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (detail) => _GymDetailBody(gym: gym, detail: detail),
        ),
      ),
    );
  }
}

class _GymDetailBody extends ConsumerWidget {
  final CommunityGym gym;
  final GymDetail detail;

  const _GymDetailBody({required this.gym, required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    final accent = colors.accent;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gym.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          if ((gym.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(gym.address!,
                style: TextStyle(fontSize: 13, color: colors.textMuted)),
          ],
          const SizedBox(height: 16),

          // Consensus equipment.
          if (detail.confirmed.isEmpty && detail.reported.isEmpty)
            _NoReportsYet(colors: colors)
          else ...[
            if (detail.confirmed.isNotEmpty) ...[
              _SectionLabel(
                label:
                    'Confirmed (${detail.consensusMinReporters}+ members agree)',
                color: colors.textSecondary,
              ),
              const SizedBox(height: 8),
              _EquipmentPills(
                items: detail.confirmed,
                confirmed: true,
                accent: accent,
                colors: colors,
              ),
              const SizedBox(height: 16),
            ],
            if (detail.reported.isNotEmpty) ...[
              _SectionLabel(
                label: 'Reported (not confirmed yet)',
                color: colors.textSecondary,
              ),
              const SizedBox(height: 8),
              _EquipmentPills(
                items: detail.reported,
                confirmed: false,
                accent: accent,
                colors: colors,
              ),
              const SizedBox(height: 16),
            ],
          ],

          // Actions.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _adopt(context, ref),
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Adopt this gym'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _report(context, ref),
              icon: const Icon(Icons.checklist_rounded),
              label: const Text('Report equipment'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _adopt(BuildContext context, WidgetRef ref) async {
    HapticService.medium();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please sign in to adopt a gym.')),
      );
      return;
    }
    try {
      final service = ref.read(communityGymsServiceProvider);
      final profile = await service.adopt(placeId: gym.placeId, userId: userId);
      // Refresh the gym profile list so the new profile appears in the switcher.
      await ref.read(gymProfilesProvider.notifier).refresh();
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Added "${profile.name}" to your gyms')),
      );
    } catch (e) {
      debugPrint('❌ [FindGyms] adopt failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't adopt this gym. Please try again.")),
      );
    }
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    HapticService.light();
    // Prefill the equipment sheet with what's already on consensus so the user
    // confirms/extends rather than starting from scratch.
    final prefill = detail.allEquipmentNames;
    final messenger = ScaffoldMessenger.of(context);

    await showGlassSheet(
      context: context,
      builder: (_) => GymEquipmentSheet(
        title: 'What\'s at ${gym.name}?',
        selectedEquipment: prefill,
        equipmentDetails: prefill
            .map((name) => EquipmentItem(name: name, displayName: name))
            .toList(),
        onSave: (equipment, equipmentDetails) async {
          try {
            final service = ref.read(communityGymsServiceProvider);
            await service.report(
              placeId: gym.placeId,
              equipment: equipment,
              equipmentDetails: equipmentDetails,
              name: gym.name,
              address: gym.address,
              city: gym.city,
              latitude: gym.latitude,
              longitude: gym.longitude,
            );
            // Refresh consensus so the pills update with this report.
            ref.invalidate(communityGymDetailProvider(gym.placeId));
            messenger.showSnackBar(
              const SnackBar(content: Text('Thanks! Your report helps everyone.')),
            );
          } catch (e) {
            debugPrint('❌ [FindGyms] report failed: $e');
            messenger.showSnackBar(
              const SnackBar(
                  content: Text("Couldn't save your report. Please try again.")),
            );
          }
        },
      ),
    );
  }
}

// =============================================================================
// Small presentational helpers
// =============================================================================

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: color,
      ),
    );
  }
}

class _EquipmentPills extends StatelessWidget {
  final List<ConsensusEquipment> items;
  final bool confirmed;
  final Color accent;
  final ThemeColors colors;

  const _EquipmentPills({
    required this.items,
    required this.confirmed,
    required this.accent,
    required this.colors,
  });

  String _pretty(String name) =>
      name.replaceAll('_', ' ').replaceFirstMapped(
            RegExp(r'^\w'),
            (m) => m.group(0)!.toUpperCase(),
          );

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final base = confirmed ? accent : colors.textMuted;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: base.withValues(alpha: confirmed ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: base.withValues(alpha: confirmed ? 0.5 : 0.25),
              width: confirmed ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (confirmed) ...[
                Icon(Icons.check_circle_rounded, size: 13, color: accent),
                const SizedBox(width: 5),
              ],
              Text(
                _pretty(item.equipment),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: confirmed ? FontWeight.w700 : FontWeight.w500,
                  color: confirmed ? accent : colors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${item.reporterCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: (confirmed ? accent : colors.textMuted)
                      .withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _NoReportsYet extends StatelessWidget {
  final ThemeColors colors;

  const _NoReportsYet({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.textMuted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No equipment reported yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to report what\'s here. Three members agreeing confirms an item for everyone.',
            style: TextStyle(fontSize: 12, color: colors.textMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Empty / error / catalog-only states
// =============================================================================

class _CatalogOnlyBanner extends StatelessWidget {
  final ThemeColors colors;

  const _CatalogOnlyBanner({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing gyms members have added. Search by name to find more.',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogOnlyEmptyState extends ConsumerWidget {
  final VoidCallback onSearchHint;

  const _CatalogOnlyEmptyState({required this.onSearchHint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Search for a gym by name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No member-added gyms near you yet. Search by name, then report the equipment you see to grow the catalog.',
              style: TextStyle(fontSize: 13, color: colors.textMuted, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final String query;
  final bool catalogOnly;

  const _EmptyState({required this.query, required this.catalogOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    final hasQuery = query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No gyms match "$query"' : 'No gyms found nearby',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try a different name, or widen your search.'
                  : 'No gyms in the catalog near you yet. Search by name to find one.',
              style: TextStyle(fontSize: 13, color: colors.textMuted, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorOrLocationState extends ConsumerWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorOrLocationState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    final isLocation = error is NoLocationException;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocation
                  ? Icons.location_off_rounded
                  : Icons.error_outline_rounded,
              size: 48,
              color: colors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              isLocation
                  ? 'Location needed to find gyms'
                  : "Couldn't load gyms nearby",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isLocation
                  ? 'Enable location access so we can show gyms near you.'
                  : 'Something went wrong. Pull to retry.',
              style: TextStyle(fontSize: 13, color: colors.textMuted, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
