import 'package:flutter/material.dart';

import 'demo_item_view_data.dart';

/// Shared content for one item detail destination.
final class DemoItemDetailContent extends StatelessWidget {
  /// Creates item detail content.
  const DemoItemDetailContent({required this.item, super.key});

  /// Presentation data resolved by the owning application.
  final DemoItemViewData item;

  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey<String>('demo-item-detail-${item.id}'),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(item.description),
      ],
    ),
  );
}
