import 'package:flutter/material.dart';

import '../../../common/ui/demo_home_content.dart';

/// Home UI for the centralized route-owned application.
final class CentralizedHomeScreen extends StatelessWidget {
  const CentralizedHomeScreen({
    required this.onOpenItems,
    required this.onOpenDetail,
    super.key,
  });

  final VoidCallback onOpenItems;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Centralized route-owned')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DemoHomeContent(
          approach: 'Route-owned Page composition',
          onOpenItems: onOpenItems,
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('Original standalone detail'),
            subtitle: const Text('Preserved route-owned scenario'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenDetail,
          ),
        ),
      ],
    ),
  );
}
