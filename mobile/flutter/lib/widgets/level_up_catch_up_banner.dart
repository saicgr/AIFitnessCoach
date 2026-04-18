import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/models/level_up_event.dart';
import '../data/providers/level_up_events_provider.dart';
import '../data/services/haptic_service.dart';

/// Persistent "You leveled up while away!" banner. Shown anywhere you want
/// users to never miss a level-up reward — home screen, inventory, XP goals.
///
/// - Hides itself when there are no unacked level-up events.
/// - Tap → opens the catch-up sheet that walks through every unacked level,
///   then acknowledges all of them so the banner disappears.
class LevelUpCatchUpBanner extends ConsumerStatefulWidget {
  final EdgeInsetsGeometry margin;
  const LevelUpCatchUpBanner({super.key, this.margin = EdgeInsets.zero});

  @override
  ConsumerState<LevelUpCatchUpBanner> createState() => _LevelUpCatchUpBannerState();
}

class _LevelUpCatchUpBannerState extends ConsumerState<LevelUpCatchUpBanner> {
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(levelUpEventsProvider.notifier).load().then((_) {
        if (mounted) setState(() => _loadedOnce = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(levelUpEventsProvider);
    if (!_loadedOnce || state.events.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    final count = state.events.length;
    final highestLevel = state.events.map((e) => e.levelReached).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: widget.margin,
      child: InkWell(
        onTap: () {
          HapticService.success();
          _openCatchUpSheet(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent,
                accent.withValues(alpha: 0.7),
                Colors.amber.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🎉', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? 'You leveled up to Level $highestLevel!'
                          : 'You gained $count levels (up to L$highestLevel)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to see your rewards',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'REVEAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textColor == Colors.white ? Colors.white : Colors.black87,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCatchUpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LevelUpCatchUpSheet(events: ref.read(levelUpEventsProvider).events),
    );
  }
}

class _LevelUpCatchUpSheet extends ConsumerWidget {
  final List<LevelUpEvent> events;
  const _LevelUpCatchUpSheet({required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          events.length == 1
                              ? 'Level ${events.first.levelReached} unlocked!'
                              : 'You leveled up ${events.length} times',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Your rewards are already in your Inventory',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: events.length,
                itemBuilder: (_, i) => _EventCard(
                  event: events[i],
                  elevated: elevated,
                  border: border,
                  textColor: textColor,
                  textMuted: textMuted,
                  accent: accent,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 12,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(levelUpEventsProvider.notifier).acknowledge();
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Awesome — got it',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

class _EventCard extends StatelessWidget {
  final LevelUpEvent event;
  final Color elevated, border, textColor, textMuted, accent;
  const _EventCard({
    required this.event,
    required this.elevated,
    required this.border,
    required this.textColor,
    required this.textMuted,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final hasMerch = event.merchType != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: event.isMilestone ? accent.withValues(alpha: 0.5) : border,
          width: event.isMilestone ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${event.levelReached}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${event.levelReached}${event.isMilestone ? ' · Milestone' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (hasMerch)
                      Text(
                        'Includes a FREE physical reward — claim in Merch Rewards',
                        style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (event.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: event.items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        item.type == 'merch'
                            ? 'FREE ${item.displayName}'
                            : '${item.quantity}× ${item.displayName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
