import 'package:example/feature/sub_routers/shell/routing/demo_module.dart';
import 'package:example/feature/sub_routers/shell/view/demo_module_presentation.dart';
import 'package:flutter/material.dart';

/// A module detail — owns its own `Scaffold`; `detail` is resolved by the
/// module's own sub-registry.
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
