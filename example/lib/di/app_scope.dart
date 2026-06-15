import 'package:example/di/app_dependencies.dart';
import 'package:flutter/widgets.dart';
import 'package:rolter/rolter.dart';

/// Exposes the single [AppDependencies] container to the whole app.
///
/// Placed in `MaterialApp.router`'s `builder:` (below `MaterialApp`, above the
/// `Navigator`), so the dependency graph it carries is built in a context that
/// has `Theme`/`MediaQuery`/`Localizations`, and every screen can read it.
class AppScope extends InheritedWidget {
  const AppScope({required this.dependencies, required super.child, super.key});

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) => context
      .readScopeOrThrow<AppScope>('AppScope not found above this widget.')
      .dependencies;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
