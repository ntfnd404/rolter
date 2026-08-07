import '../../shell/routing/demo_module.dart';
import '../../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';

/// A module's home (route name `home`, local to the module's registry).
final class ModuleHomeRoute extends AppRoute {
  const ModuleHomeRoute(this.module);

  final DemoModule module;

  @override
  LocalKey get pageKey => ValueKey('${module.wire}/home');

  @override
  String get name => 'home';

  @override
  Map<String, String> toParams() => const {};
}
