part of 'demo_active_workout_screen.dart';


/// Workout phases for demo
enum DemoWorkoutPhase {
  warmup,
  active,
  stretch,
  complete,
}


/// Warmup exercise data for demo
class DemoWarmupExercise {
  final String name;
  final int duration;
  final IconData icon;
  final String tip;

  const DemoWarmupExercise({
    required this.name,
    required this.duration,
    required this.icon,
    required this.tip,
  });
}


/// Stretch exercise data for demo
class DemoStretchExercise {
  final String name;
  final int duration;
  final IconData icon;
  final String benefit;

  const DemoStretchExercise({
    required this.name,
    required this.duration,
    required this.icon,
    required this.benefit,
  });
}

