import 'package:flutter/material.dart';

import '../../../common/ui/demo_home_content.dart';
import '../dependency/scoped_catalog_repository.dart';

final class ScopedHomeScreen extends StatelessWidget {
  const ScopedHomeScreen({
    required this.repository,
    required this.onOpenItems,
    super.key,
  });

  final ScopedCatalogRepository repository;
  final VoidCallback onOpenItems;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('External builder + Scope.of')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(repository.sourceLabel, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        DemoHomeContent(
          approach: 'The builder reads one narrow repository scope',
          onOpenItems: onOpenItems,
        ),
      ],
    ),
  );
}
