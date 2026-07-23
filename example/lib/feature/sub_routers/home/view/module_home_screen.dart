import '../../shell/routing/demo_module.dart';
import '../../shell/routing/modules_nav.dart';
import '../../shell/view/demo_module_presentation.dart';
import '../../../../core/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Root of a module's stack — owns its own `Scaffold`/`AppBar`.
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
