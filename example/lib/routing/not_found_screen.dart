import 'package:example/feature/home/routing/home_nav.dart';
import 'package:example/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Shown for an unknown URL (the route is `HistoryExcluded`).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({required this.attempted, super.key});

  final Uri attempted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text('No route for "$attempted"'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: context.navigator.toHome,
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}
