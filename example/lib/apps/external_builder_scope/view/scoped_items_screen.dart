import 'package:flutter/material.dart';

import '../../../common/ui/demo_item_view_data.dart';
import '../../../common/ui/demo_items_content.dart';
import '../dependency/scoped_catalog_repository.dart';

final class ScopedItemsScreen extends StatelessWidget {
  const ScopedItemsScreen({
    required this.repository,
    required this.onOpenItem,
    super.key,
  });

  final ScopedCatalogRepository repository;
  final ValueChanged<int> onOpenItem;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Demo items')),
    body: DemoItemsContent(
      items: [
        for (final item in repository.all())
          DemoItemViewData(
            id: item.id,
            title: item.title,
            description: item.description,
          ),
      ],
      onOpenItem: onOpenItem,
    ),
  );
}
