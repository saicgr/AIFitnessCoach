import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/providers/schedule_provider.dart';
import '../../../../data/models/schedule_item.dart';

/// Card showing the next 2-3 upcoming scheduled items on the home screen
class UpNextCard extends ConsumerStatefulWidget {
  final bool isDark;

  const UpNextCard({super.key, required this.isDark});

  @override
  ConsumerState<UpNextCard> createState() => _UpNextCardState();
}

class _UpNextCardState extends ConsumerState<UpNextCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get isDark => widget.isDark;

  @override
  Widget build(BuildContext context) {
    final upNextAsync = ref.watch(upNextScheduleProvider);
    final elevatedColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;
    final textMuted = isDark ? Colors.white60 : Colors.black54;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.schedule,
                  color: AppColors.cyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Up Next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          upNextAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (error, _) => _buildErrorState(context, ref, textMuted),
            data: (upNext) {
              if (upNext.items.isEmpty) {
                return _buildEmptyState(context, textMuted);
              }
              return _buildItemsList(
                context,
                upNext.items.take(3).toList(),
                textColor,
                textMuted,
              );
            },
          ),

          // View Full Schedule link
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/schedule'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Full Schedule',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.cyan,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          'No upcoming items. Tap + to add to your schedule',
          style: TextStyle(
            fontSize: 13,
            color: textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Column(
          children: [
            Text(
              'Could not load schedule',
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => ref.invalidate(upNextScheduleProvider),
              child: Text(
                'Tap to retry',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.cyan,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    List<ScheduleItem> items,
    Color textColor,
    Color textMuted,
  ) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        // Staggered animation for each item row
        final delay = 200 + (index * 120); // ms delay per item
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 80)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Time
              SizedBox(
                width: 52,
                child: Text(
                  item.startTime,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Type icon with color
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.typeIcon,
                  size: 16,
                  color: item.typeColor,
                ),
              ),
              const SizedBox(width: 10),
              // Title
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          ),
        );
      }).toList(),
    );
  }
}
