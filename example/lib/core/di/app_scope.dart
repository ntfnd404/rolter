import 'app_dependencies.dart';
import 'package:flutter/widgets.dart';

/// Exposes the single [AppDependencies] container to the whole app.
///
/// Placed in `MaterialApp.router`'s `builder:` (below `MaterialApp`, above the
/// `Navigator`), so the dependency graph it carries is built in a context that
/// has `Theme`/`MediaQuery`/`Localizations`, and every screen can read it.
class AppScope extends InheritedWidget {
  const AppScope({required this.dependencies, required super.child, super.key});

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw FlutterError('AppScope not found above this widget.');
    }
    return scope.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
