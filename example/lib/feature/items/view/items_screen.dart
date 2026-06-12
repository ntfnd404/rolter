import 'package:example/feature/items/routing/items_nav.dart';
import 'package:example/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Base of the Items tab's nested navigator. Content only — the shared AppBar
/// lives in `TabsShell`. Tapping an item pushes a detail onto the nested stack
/// (URL gains `/.item~id=N`); back pops within this tab.
class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (var id = 1; id <= 3; id++)
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text('Item #$id'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.navigator.openItem(id),
          ),
      ],
    );
  }
}
