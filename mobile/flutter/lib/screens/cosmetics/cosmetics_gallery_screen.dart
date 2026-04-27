import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/cosmetic.dart';
import '../../data/providers/cosmetics_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/cosmetics/cosmetic_badge.dart';
import '../../widgets/cosmetics/framed_avatar.dart';
import '../../widgets/glass_back_button.dart';

/// Cosmetics gallery — browse all badges / frames / etc., equip what's owned,
/// see locked items with the level they unlock at.
class CosmeticsGalleryScreen extends ConsumerStatefulWidget {
  const CosmeticsGalleryScreen({super.key});

  @override
  ConsumerState<CosmeticsGalleryScreen> createState() => _CosmeticsGalleryScreenState();
}

class _CosmeticsGalleryScreenState extends ConsumerState<CosmeticsGalleryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(cosmeticsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cosmeticsProvider);
    final currentLevel = ref.watch(xpProvider).userXp?.currentLevel ?? 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(cosmeticsProvider.notifier).load(),
            color: accent,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  backgroundColor: bg,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: EdgeInsets.fromLTRB(
                        16, MediaQuery.of(context).padding.top + 56, 16, 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [elevated, bg],
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 28, color: accent),
                          const SizedBox(width: 12),
                          Text(
                            'Cosmetics',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (state.loading && state.catalog.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.error != null && state.catalog.isEmpty)
                  SliverFillRemaining(
                    child: _buildError(state.error!, textColor, textMuted, accent),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildCurrentLoadout(state, textColor, textMuted, elevated, border, accent),
                        const SizedBox(height: 20),
                        ..._buildTypeSections(state, currentLevel, textColor, textMuted, elevated, border, accent),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GlassBackButton(onTap: () => context.pop()),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLoadout(
    CosmeticsState state,
    Color textColor,
    Color textMuted,
    Color elevated,
    Color border,
    Color accent,
  ) {
    final equippedBadge = state.equippedOfType(CosmeticType.badge);
    final equippedFrame = state.equippedOfType(CosmeticType.frame);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          FramedAvatar(
            frame: equippedFrame,
            size: 72,
            child: Container(
              color: accent.withValues(alpha: 0.15),
              alignment: Alignment.center,
              child: Icon(Icons.person, color: accent, size: 36),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your loadout',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (equippedBadge != null)
                  CosmeticBadgePill(cosmetic: equippedBadge, height: 24)
                else
                  Text(
                    'No badge equipped',
                    style: TextStyle(color: textMuted, fontSize: 13),
                  ),
                const SizedBox(height: 6),
                Text(
                  equippedFrame != null
                      ? '${equippedFrame.displayName} frame'
                      : 'No frame equipped',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTypeSections(
    CosmeticsState state,
    int currentLevel,
    Color textColor,
    Color textMuted,
    Color elevated,
    Color border,
    Color accent,
  ) {
    // Render order — visible types first, deferred types last (so users can see they exist)
    const typeOrder = [
      CosmeticType.badge,
      CosmeticType.frame,
      CosmeticType.chatTitle,
      CosmeticType.theme,
      CosmeticType.coachVoice,
      CosmeticType.statsCard,
    ];

    final grouped = state.catalogByType;
    final sections = <Widget>[];
    for (final type in typeOrder) {
      final items = grouped[type];
      if (items == null || items.isEmpty) continue;
      sections.add(
        _buildTypeSection(
          type: type,
          items: items,
          state: state,
          currentLevel: currentLevel,
          textColor: textColor,
          textMuted: textMuted,
          elevated: elevated,
          border: border,
          accent: accent,
        ),
      );
      sections.add(const SizedBox(height: 20));
    }
    return sections;
  }

  Widget _buildTypeSection({
    required CosmeticType type,
    required List<Cosmetic> items,
    required CosmeticsState state,
    required int currentLevel,
    required Color textColor,
    required Color textMuted,
    required Color elevated,
    required Color border,
    required Color accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              type.label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((c) => _CosmeticRow(
              cosmetic: c,
              owned: state.ownsCosmetic(c.id),
              equipped: state.owned[c.id]?.isEquipped ?? false,
              currentLevel: currentLevel,
              visibleType: true,
              elevated: elevated,
              border: border,
              textColor: textColor,
              textMuted: textMuted,
              accent: accent,
              onEquip: () async {
                HapticService.light();
                try {
                  await ref.read(cosmeticsProvider.notifier).equip(c.id);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              },
              onUnequip: () async {
                HapticService.light();
                try {
                  await ref.read(cosmeticsProvider.notifier).unequip(c.id);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              },
            )),
      ],
    );
  }

  Widget _buildError(Object error, Color textColor, Color textMuted, Color accent) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 40, color: textMuted),
          const SizedBox(height: 8),
          Text('Failed to load cosmetics', style: TextStyle(color: textColor)),
          const SizedBox(height: 4),
          Text('$error',
              style: TextStyle(fontSize: 12, color: textMuted), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.read(cosmeticsProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: accent),
          ),
        ],
      ),
    );
  }
}

class _CosmeticRow extends StatelessWidget {
  final Cosmetic cosmetic;
  final bool owned;
  final bool equipped;
  final int currentLevel;
  final bool visibleType;
  final Color elevated, border, textColor, textMuted, accent;
  final VoidCallback onEquip;
  final VoidCallback onUnequip;

  const _CosmeticRow({
    required this.cosmetic,
    required this.owned,
    required this.equipped,
    required this.currentLevel,
    required this.visibleType,
    required this.elevated,
    required this.border,
    required this.textColor,
    required this.textMuted,
    required this.accent,
    required this.onEquip,
    required this.onUnequip,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !owned;
    final levelsToGo = cosmetic.unlockLevel != null
        ? (cosmetic.unlockLevel! - currentLevel).clamp(0, 999)
        : 0;

    Widget preview;
    if (cosmetic.type == CosmeticType.frame) {
      preview = FramedAvatar(
        frame: cosmetic,
        size: 52,
        child: Container(
          color: (cosmetic.color ?? accent).withValues(alpha: 0.15),
          alignment: Alignment.center,
          child: Icon(Icons.person, color: cosmetic.color ?? accent, size: 26),
        ),
      );
    } else if (cosmetic.type == CosmeticType.badge) {
      preview = CosmeticBadgePill(cosmetic: cosmetic, height: 28);
    } else {
      preview = Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: (cosmetic.color ?? textMuted).withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: (cosmetic.color ?? textMuted).withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            cosmetic.emoji ?? '✨',
            style: const TextStyle(fontSize: 22),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: equipped ? accent : border,
          width: equipped ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Opacity(opacity: locked ? 0.4 : 1.0, child: preview),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cosmetic.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: locked ? textMuted : textColor,
                  ),
                ),
                if (cosmetic.description != null)
                  Text(
                    cosmetic.description!,
                    style: TextStyle(fontSize: 12, color: textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (locked && cosmetic.unlockLevel != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 12, color: textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Unlocks at Level ${cosmetic.unlockLevel}'
                        '${levelsToGo > 0 ? " · $levelsToGo to go" : ""}',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (owned)
            equipped
                ? OutlinedButton(
                    onPressed: onUnequip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Equipped'),
                  )
                : ElevatedButton(
                    onPressed: onEquip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Equip'),
                  )
          else
            Icon(Icons.lock_outline, color: textMuted, size: 20),
        ],
      ),
    );
  }
}
