import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Focus type for the home screen hero area
enum HomeFocus { forYou, workout, nutrition, fasting }

/// Provider to persist the user's home focus preference (session-level).
/// Defaults to workout since workouts are the primary feature.
final homeFocusProvider = StateProvider<HomeFocus>((ref) => HomeFocus.workout);
