import 'package:example/feature/sub_routers/shell/routing/demo_module.dart';
import 'package:example/core/routing/app_navigator.dart';
import 'package:example/core/routing/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rolter/rolter.dart';

/// Hosts a module's own nested stack — *just* the nested host, no `Scaffold`.
///
/// Each inner screen ([ModuleHomeScreen]/[ModuleDetailScreen]) owns its own
/// `Scaffold` + `AppBar`, so wrapping the host in another `Scaffold` would only
/// add an empty outer layer and make `Scaffold.of(context)` ambiguous. (For
/// SnackBars use `ScaffoldMessenger.of(context)`, which targets the app-level
/// messenger regardless.)
class ModuleShell extends StatelessWidget {
  const ModuleShell({required this.module, super.key});

  final DemoModule module;

  @override
  Widget build(BuildContext context) {
    final nav = context.navigator;

    return NestedNavigatorHost<AppRoute>(
      service: nav,
      path: [module.wire],
      onBackButtonPressed: (navigator) {
        if (navigator.canPop()) {
          return navigator.maybePop();
        }
        nav.pop();

        return SynchronousFuture<bool>(true);
      },
    );
  }
}
