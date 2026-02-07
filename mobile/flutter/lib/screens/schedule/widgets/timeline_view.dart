import 'package:flutter/material.dart';
import '../../../data/models/schedule_item.dart';
import 'timeline_item_block.dart';

/// Vertical 24-hour scrollable timeline widget.
/// Displays hours 5AM-11PM in a left gutter, schedule items as positioned colored blocks,
/// Google Calendar busy times as semi-transparent grey overlays,
/// and a red current-time indicator line.
class TimelineView extends StatefulWidget {
  final List<ScheduleItem> items;
  final List<Map<String, dynamic>>? busyTimes;
  final Function(ScheduleItem)? onItemTap;
  final Function(String time)? onEmptyTap;
  final bool isDark;

  const TimelineView({
    super.key,
    required this.items,
    this.busyTimes,
    this.onItemTap,
    this.onEmptyTap,
    this.isDark = true,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  static const double _hourHeight = 60.0;
  static const double _gutterWidth = 48.0;
  static const int _startHour = 5;
  static const int _endHour = 23; // 11PM
  static const int _totalHours = _endHour - _startHour;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentTime());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    if (!_scrollController.hasClients) return;
    final now = DateTime.now();
    final hourOffset = now.hour - _startHour + (now.minute / 60);
    final scrollTarget = (hourOffset * _hourHeight - 100).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      scrollTarget,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalHeight = _totalHours * _hourHeight;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            // Hour grid lines and labels
            ..._buildHourRows(),
            // Google Calendar busy time overlays
            if (widget.busyTimes != null) ..._buildBusyTimeOverlays(),
            // Schedule items
            ..._buildItemBlocks(),
            // Current time indicator
            _buildCurrentTimeIndicator(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHourRows() {
    final widgets = <Widget>[];
    final lineColor = widget.isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200;
    final labelColor = widget.isDark ? Colors.white38 : Colors.black38;

    for (int h = 0; h < _totalHours; h++) {
      final hour = _startHour + h;
      final top = h * _hourHeight;
      final label = _formatHour(hour);

      // Tap target on empty space — pass "HH:MM" format for time prefill
      final hourStr = hour.toString().padLeft(2, '0');
      widgets.add(
        Positioned(
          top: top,
          left: _gutterWidth,
          right: 0,
          height: _hourHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => widget.onEmptyTap?.call('$hourStr:00'),
            child: const SizedBox.expand(),
          ),
        ),
      );

      // Hour label
      widgets.add(
        Positioned(
          top: top - 7,
          left: 4,
          width: _gutterWidth - 8,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ),
      );

      // Horizontal grid line
      widgets.add(
        Positioned(
          top: top,
          left: _gutterWidth,
          right: 0,
          child: Container(height: 0.5, color: lineColor),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildBusyTimeOverlays() {
    final widgets = <Widget>[];
    if (widget.busyTimes == null) return widgets;

    for (final busy in widget.busyTimes!) {
      final start = busy['start'] as String?;
      final end = busy['end'] as String?;
      if (start == null || end == null) continue;

      final startMinutes = _parseTimeToMinutes(start);
      final endMinutes = _parseTimeToMinutes(end);
      if (startMinutes == null || endMinutes == null) continue;

      final top = _minutesToOffset(startMinutes);
      final height = ((endMinutes - startMinutes) / 60 * _hourHeight).clamp(4.0, double.infinity);

      widgets.add(
        Positioned(
          top: top,
          left: _gutterWidth + 4,
          right: 4,
          height: height,
          child: Container(
            decoration: BoxDecoration(
              color: (widget.isDark ? Colors.white : Colors.grey).withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (widget.isDark ? Colors.white : Colors.grey).withOpacity(0.1),
              ),
            ),
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(4),
            child: Text(
              'Busy',
              style: TextStyle(
                fontSize: 10,
                color: widget.isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildItemBlocks() {
    final widgets = <Widget>[];

    for (final item in widget.items) {
      final startMinutes = _parseTimeToMinutes(item.startTime);
      if (startMinutes == null) continue;

      final top = _minutesToOffset(startMinutes);
      final duration = item.durationMinutes ?? 30;
      final height = (duration / 60 * _hourHeight).clamp(30.0, double.infinity);

      widgets.add(
        Positioned(
          top: top,
          left: _gutterWidth + 4,
          right: 4,
          height: height,
          child: TimelineItemBlock(
            item: item,
            hourHeight: _hourHeight,
            isDark: widget.isDark,
            onTap: () => widget.onItemTap?.call(item),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildCurrentTimeIndicator() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final top = _minutesToOffset(currentMinutes);

    if (top < 0 || top > _totalHours * _hourHeight) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: top - 5,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) => Row(
          children: [
            // Pulsing red dot with glow
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.4 * _pulseAnimation.value),
                    blurRadius: 6 * _pulseAnimation.value,
                    spreadRadius: 1 * _pulseAnimation.value,
                  ),
                ],
              ),
            ),
            // Red line
            Expanded(
              child: Container(
                height: 2,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _minutesToOffset(int totalMinutes) {
    final minutesFromStart = totalMinutes - (_startHour * 60);
    return minutesFromStart / 60 * _hourHeight;
  }

  int? _parseTimeToMinutes(String time) {
    // Supports "HH:MM" format
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }
}
