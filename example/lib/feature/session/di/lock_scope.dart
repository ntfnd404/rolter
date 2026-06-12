import 'package:example/feature/session/di/lock_controller.dart';
import 'package:flutter/widgets.dart';

/// Exposes [LockController] above `MaterialApp.router`, like `NavigatorScope`.
class LockScope extends InheritedWidget {
  const LockScope({required this.controller, required super.child, super.key});

  final LockController controller;

  static LockController of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LockScope>();
    if (scope == null) {
      throw FlutterError('LockScope not found above MaterialApp.router');
    }
    return scope.controller;
  }

  @override
  bool updateShouldNotify(LockScope oldWidget) =>
      controller != oldWidget.controller;
}
