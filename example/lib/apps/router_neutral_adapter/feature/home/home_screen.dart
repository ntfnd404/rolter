import 'package:flutter/material.dart';

import '../../../../common/ui/demo_home_content.dart';

/// Home UI with no dependency on Rolter or another routing engine.
final class AdapterHomeScreen extends StatelessWidget {
  /// Creates the home screen.
  const AdapterHomeScreen({
    required this.onOpenActivity,
    required this.onOpenItems,
    super.key,
  });

  /// Application navigation action supplied by composition.
  final VoidCallback onOpenActivity;

  /// Opens the shared comparison flow through the application port.
  final VoidCallback onOpenItems;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Router-neutral modules')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DemoHomeContent(
          approach: 'Application destinations mapped by RolterAdapter',
          onOpenItems: onOpenItems,
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('Open adapter activity'),
            subtitle: const Text('Preserved router-neutral feature'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenActivity,
          ),
        ),
      ],
    ),
  );
}
