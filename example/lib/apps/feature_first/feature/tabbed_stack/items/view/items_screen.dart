import '../../shared/domain/repositories/item_repository.dart';
import '../routing/items_nav.dart';
import '../../../../navigation/app_navigator.dart';
import 'package:flutter/material.dart';

import '../../../../../../common/ui/demo_item_view_data.dart';
import '../../../../../../common/ui/demo_items_content.dart';

/// Base of the Items tab's nested navigator. Content only — the shared AppBar
/// lives in `TabsShell`. Items come from the injected `ItemRepository`;
/// tapping pushes a detail onto the nested stack (URL gains `/.item~id=N`).
class ItemsScreen extends StatelessWidget {
  const ItemsScreen({required this.repository, super.key});

  final ItemRepository repository;

  @override
  Widget build(BuildContext context) {
    final items = repository.all();
    return DemoItemsContent(
      items: [
        for (final item in items)
          DemoItemViewData(
            id: item.id,
            title: item.title,
            description: item.description,
          ),
      ],
      onOpenItem: context.navigator.openItem,
    );
  }
}
