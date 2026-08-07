import 'package:flutter/material.dart';

/// Shared safe error content used by every comparison flow.
final class DemoNotFoundContent extends StatelessWidget {
  /// Creates safe not-found content.
  const DemoNotFoundContent({
    required this.message,
    required this.onGoHome,
    super.key,
  });

  /// Safe, application-provided explanation shown to the user.
  final String message;

  /// Returns to the owning application's Home destination.
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) => Center(
    key: const ValueKey<String>('demo-not-found-content'),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onGoHome, child: const Text('Go home')),
        ],
      ),
    ),
  );
}
