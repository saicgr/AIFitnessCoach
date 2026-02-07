import 'package:flutter/material.dart';
import '../../../data/models/schedule_item.dart';

/// Individual schedule item block rendered on the timeline.
/// Height is proportional to duration, with a minimum of 30px.
/// Includes tap scale animation and entrance fade.
class TimelineItemBlock extends StatefulWidget {
  final ScheduleItem item;
  final double hourHeight;
  final Function()? onTap;
  final bool isDark;

  const TimelineItemBlock({
    super.key,
    required this.item,
    this.hourHeight = 60,
    this.onTap,
    this.isDark = true,
  });

  @override
  State<TimelineItemBlock> createState() => _TimelineItemBlockState();
}

class _TimelineItemBlockState extends State<TimelineItemBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hourHeight = widget.hourHeight;
    final color = item.typeColor;
    final isCompleted = item.status == ScheduleItemStatus.completed;
    final duration = item.durationMinutes ?? 30;
    final blockHeight = (duration / 60 * hourHeight).clamp(30.0, double.infinity);
    final isCompact = blockHeight < 50;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) {
        _tapController.forward();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        _tapController.reverse();
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () {
        _tapController.reverse();
        setState(() => _isPressed = false);
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isCompleted ? 0.6 : 1.0,
        child: Container(
          height: blockHeight,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: color, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: isCompact ? _buildCompactLayout(color, isCompleted) : _buildFullLayout(color, isCompleted),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCompactLayout(Color color, bool isCompleted) {
    final isDark = widget.isDark;
    return Row(
      children: [
        if (isCompleted)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.check_circle, size: 14, color: color),
          ),
        Expanded(
          child: Text(
            widget.item.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          _formatTimeRange(),
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildFullLayout(Color color, bool isCompleted) {
    final isDark = widget.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            if (isCompleted)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.check_circle, size: 14, color: color),
              ),
            Expanded(
              child: Text(
                widget.item.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(widget.item.typeIcon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              _formatTimeRange(),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const Spacer(),
            _buildStatusBadge(isCompleted, color),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isCompleted, Color color) {
    final label = isCompleted
        ? 'Done'
        : widget.item.status == ScheduleItemStatus.skipped
            ? 'Skipped'
            : '';
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
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
