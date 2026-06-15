import 'package:example/feature/modules/routing/modules_nav.dart';
import 'package:example/feature/modules/routing/modules_routes.dart';
import 'package:example/routing/app_navigator.dart';
import 'package:example/routing/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Hosts a module's own nested stack. The shell carries no AppBar; each inner
/// screen owns its own.
class ModuleShell extends StatelessWidget {
  const ModuleShell({required this.module, super.key});

  final DemoModule module;

  @override
  Widget build(BuildContext context) {
    final nav = context.navigator;

    return Scaffold(
      body: NestedNavigatorHost<AppRoute>(
        service: nav,
        path: [module.wire],
        onBackButtonPressed: (navigator) {
          if (navigator.canPop()) {
            return navigator.maybePop();
          }
          nav.pop();

          return SynchronousFuture<bool>(true);
        },
      ),
    );
  }
}

/// Root of a module's stack.
class ModuleHomeScreen extends StatelessWidget {
  const ModuleHomeScreen({required this.module, super.key});

  final DemoModule module;

  @override
  Widget build(BuildContext context) {
    final nav = context.navigator;

    return Scaffold(
      appBar: AppBar(
        title: Text('${module.label} (sub-router)'),
        leading: BackButton(onPressed: nav.pop),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'The "${module.wire}" feature owns its own registry. Its `home` / '
            '`detail` route names are local to it — ${module.other.label} reuses '
            '`detail` without colliding.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => nav.openModuleItem(module, 1),
            child: Text('Open a ${module.label} item'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => nav.toModule(module.other),
            child: Text('Go to ${module.other.label}'),
          ),
        ],
      ),
    );
  }
}

/// A module detail — `detail` resolved by the module's own sub-registry.
class ModuleDetailScreen extends StatelessWidget {
  const ModuleDetailScreen({required this.module, required this.id, super.key});

  final DemoModule module;
  final int id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${module.label} item #$id')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'URL: /${module.wire}/.home/..detail~id=$id\n\n'
            '"detail" here is resolved by the ${module.wire} sub-registry, '
            'isolated from ${module.other.wire}.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
