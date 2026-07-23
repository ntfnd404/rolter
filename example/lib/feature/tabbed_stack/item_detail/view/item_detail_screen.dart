import '../../../../core/di/app_scope.dart';
import 'package:flutter/material.dart';

/// A detail pushed inside the Items tab's nested navigator. Content only — the
/// shared AppBar (titled "Item #N") lives in `TabsShell`. Looks the item up in
/// the `ItemRepository` by [id].
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) {
    final item = AppScope.of(context).itemRepository.byId(id);
    if (item == null) {
      return const Center(child: Text('Item not found.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(item.description),
        ],
      ),
    );
  }
}
