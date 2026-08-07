import 'package:flutter/material.dart';

import 'demo_item_view_data.dart';

/// Shared item-list content with application-owned navigation callbacks.
final class DemoItemsContent extends StatelessWidget {
  /// Creates the list content.
  const DemoItemsContent({
    required this.items,
    required this.onOpenItem,
    super.key,
  });

  /// Presentation values supplied by the owning application.
  final List<DemoItemViewData> items;

  /// Opens the selected application-owned item destination.
  final ValueChanged<int> onOpenItem;

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey<String>('demo-items-content'),
    children: [
      for (final item in items)
        ListTile(
          key: ValueKey<String>('demo-item-${item.id}'),
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text(item.title),
          subtitle: Text(item.description),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onOpenItem(item.id),
        ),
    ],
  );
}
