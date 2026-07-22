import '../../../../core/di/app_scope.dart';
import '../routing/items_nav.dart';
import '../../../../core/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Base of the Items tab's nested navigator. Content only — the shared AppBar
/// lives in `TabsShell`. Items come from the `ItemRepository` (via `AppScope`);
/// tapping pushes a detail onto the nested stack (URL gains `/.item~id=N`).
class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = AppScope.of(context).itemRepository.all();
    return ListView(
      children: [
        for (final item in items)
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(item.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.navigator.openItem(item.id),
          ),
      ],
    );
  }
}
