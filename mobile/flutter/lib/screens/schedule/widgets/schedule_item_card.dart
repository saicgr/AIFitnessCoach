import 'package:flutter/material.dart';
import '../../../data/models/schedule_item.dart';

/// Card for agenda view of schedule items.
/// Shows a left color bar, icon, title, time range, and status badge.
/// Includes slide-in and scale entrance animation.
class ScheduleItemCard extends StatefulWidget {
  final ScheduleItem item;
  final Function()? onTap;
  final Function()? onComplete;
  final bool isDark;
  final int animationIndex;

  const ScheduleItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onComplete,
    this.isDark = true,
    this.animationIndex = 0,
  });

  @override
  State<ScheduleItemCard> createState() => _ScheduleItemCardState();
}

class _ScheduleItemCardState extends State<ScheduleItemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Staggered delay based on index
    Future.delayed(Duration(milliseconds: widget.animationIndex * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;
    final onTap = widget.onTap;
    final onComplete = widget.onComplete;
    final color = item.typeColor;
    final isCompleted = item.status == ScheduleItemStatus.completed;
    final bgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isCompleted ? 0.65 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left color bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.typeIcon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 13,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimeRange(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                            if (item.durationMinutes != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${item.durationMinutes} min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Status badge + complete button
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusBadge(color, isCompleted),
                      if (!isCompleted && onComplete != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: onComplete,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check, size: 16, color: color),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    ),
    ),
    );
  }

  Widget _buildStatusBadge(Color color, bool isCompleted) {
    String label;
    Color badgeColor;

    switch (widget.item.status) {
      case ScheduleItemStatus.completed:
        label = 'Done';
        badgeColor = const Color(0xFF22C55E);
        break;
      case ScheduleItemStatus.skipped:
        label = 'Skipped';
        badgeColor = const Color(0xFFF97316);
        break;
      case ScheduleItemStatus.missed:
        label = 'Missed';
        badgeColor = const Color(0xFFEF4444);
        break;
      case ScheduleItemStatus.inProgress:
        label = 'Active';
        badgeColor = color;
        break;
      case ScheduleItemStatus.scheduled:
        label = 'Scheduled';
        final brightness = Theme.of(context).brightness;
        badgeColor = brightness == Brightness.dark ? Colors.white38 : Colors.black26;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  String _formatTimeRange() {
    final start = widget.item.startTime;
    if (widget.item.endTime != null) {
      return '$start - ${widget.item.endTime}';
    }
    return start;
  }
}
