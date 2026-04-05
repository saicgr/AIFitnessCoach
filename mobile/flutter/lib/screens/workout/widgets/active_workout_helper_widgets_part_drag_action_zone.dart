part of 'active_workout_helper_widgets.dart';


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
  State<_DragActionZone> createState() => DragActionZoneState();
}

