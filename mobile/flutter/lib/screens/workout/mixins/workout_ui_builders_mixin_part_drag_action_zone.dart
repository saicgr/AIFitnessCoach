part of 'workout_ui_builders_mixin.dart';


/// A drag target zone that appears at the top of the screen during thumbnail drag.
/// Accepts [int] data (exercise index) from [LongPressDraggable].
class _DragActionZone extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final void Function(int exerciseIndex) onAccept;

  const _DragActionZone({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onAccept,
  });

  @override
  State<_DragActionZone> createState() => _DragActionZoneState();
}


class _DragActionZoneState extends State<_DragActionZone> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        if (!_isHovering) {
          setState(() => _isHovering = true);
          HapticFeedback.selectionClick();
        }
        return true;
      },
      onLeave: (_) {
        setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        HapticFeedback.heavyImpact();
        widget.onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = _isHovering && candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          decoration: BoxDecoration(
            color: isActive
                ? widget.color.withValues(alpha: 0.35)
                : widget.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? widget.color
                  : widget.color.withValues(alpha: 0.5),
              width: isActive ? 2.5 : 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: isActive ? Colors.white : widget.color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : widget.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

