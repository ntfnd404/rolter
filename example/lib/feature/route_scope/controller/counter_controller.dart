import 'package:flutter/foundation.dart';

/// A per-route controller. Created by `RouteScope` when the route is pushed and
/// disposed when it is popped (watch the debugPrint in the console).
class CounterController extends ChangeNotifier {
  CounterController() {
    debugPrint('CounterController created');
  }

  int _value = 0;

  int get value => _value;

  void increment() {
    _value++;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('CounterController disposed');
    super.dispose();
  }
}
