import 'package:flutter/material.dart';

import '../../../common/ui/demo_item_view_data.dart';
import '../../../common/ui/demo_items_content.dart';

final class CentralizedItemsScreen extends StatelessWidget {
  const CentralizedItemsScreen({
    required this.items,
    required this.onOpenItem,
    super.key,
  });

  final List<DemoItemViewData> items;
  final ValueChanged<int> onOpenItem;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Demo items')),
    body: DemoItemsContent(items: items, onOpenItem: onOpenItem),
  );
}
