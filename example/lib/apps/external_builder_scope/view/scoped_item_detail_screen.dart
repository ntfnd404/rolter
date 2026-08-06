import 'package:flutter/material.dart';

import '../../../common/ui/demo_item_detail_content.dart';
import '../../../common/ui/demo_item_view_data.dart';
import '../../../common/ui/demo_not_found_content.dart';
import '../dependency/scoped_catalog_repository.dart';

final class ScopedItemDetailScreen extends StatelessWidget {
  const ScopedItemDetailScreen({
    required this.repository,
    required this.id,
    required this.onGoHome,
    super.key,
  });

  final ScopedCatalogRepository repository;
  final int id;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final item = repository.byId(id);
    return Scaffold(
      appBar: AppBar(title: Text('Item #$id')),
      body: item == null
          ? DemoNotFoundContent(
              message: 'The requested demo item does not exist.',
              onGoHome: onGoHome,
            )
          : DemoItemDetailContent(
              item: DemoItemViewData(
                id: item.id,
                title: item.title,
                description: item.description,
              ),
            ),
    );
  }
}
