import 'app_destination.dart';

/// Smallest router-neutral navigation port required by this flat example.
abstract interface class AppNavigationController {
  /// Adds [destination] to the root stack.
  void push(AppDestination destination);

  /// Removes the current destination when possible.
  void pop();
}
