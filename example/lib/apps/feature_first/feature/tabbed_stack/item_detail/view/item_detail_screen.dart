import '../../shared/domain/repositories/item_repository.dart';
import 'package:flutter/material.dart';

import '../../../../../../common/ui/demo_item_detail_content.dart';
import '../../../../../../common/ui/demo_item_view_data.dart';

/// A detail pushed inside the Items tab's nested navigator. Content only — the
/// shared AppBar (titled "Item #N") lives in `TabsShell`. Looks the item up in
/// the `ItemRepository` by [id].
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({
    required this.repository,
    required this.id,
    super.key,
  });

  final ItemRepository repository;
  final int id;

  @override
  Widget build(BuildContext context) {
    final item = repository.byId(id);
    if (item == null) {
      return const Center(child: Text('Item not found.'));
    }

    return DemoItemDetailContent(
      item: DemoItemViewData(
        id: item.id,
        title: item.title,
        description: item.description,
      ),
    );
  }
}
