import 'package:example/feature/session/di/lock_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:rolter/rolter.dart';

/// Exposes [LockController] above `MaterialApp.router`, like `NavigatorScope`.
class LockScope extends InheritedWidget {
  const LockScope({required this.controller, required super.child, super.key});

  final LockController controller;

  static LockController of(BuildContext context) => context
      .readScopeOrThrow<LockScope>(
        'LockScope not found above MaterialApp.router',
      )
      .controller;

  @override
  bool updateShouldNotify(LockScope oldWidget) =>
      controller != oldWidget.controller;
}
