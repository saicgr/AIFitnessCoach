part of 'home_screen.dart';


/// Dummy animation controller for backwards compatibility with deprecated edit mode code
class _DummyAnimationController extends ChangeNotifier {
  void repeat({bool reverse = false}) {}
  void stop() {}
  void reset() {}
  double get value => 0.0;
}

