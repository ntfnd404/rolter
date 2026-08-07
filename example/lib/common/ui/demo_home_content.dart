import 'package:flutter/material.dart';

/// Shared content that opens the comparable Items flow.
///
/// The owning application provides navigation through [onOpenItems] and owns
/// the surrounding Scaffold and any approach-specific scenarios.
final class DemoHomeContent extends StatelessWidget {
  /// Creates the common home content.
  const DemoHomeContent({
    required this.approach,
    required this.onOpenItems,
    super.key,
  });

  /// Human-readable name of the architecture being demonstrated.
  final String approach;

  /// Opens the application's Items destination.
  final VoidCallback onOpenItems;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Shared comparison flow',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('$approach keeps its own routing and dependencies.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey<String>('open-demo-items'),
            onPressed: onOpenItems,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Browse demo items'),
          ),
        ],
      ),
    ),
  );
}
