import 'package:flutter/material.dart';

import '../../../common/ui/demo_not_found_content.dart';

/// Safe adapter-level fallback UI.
final class AdapterNotFoundScreen extends StatelessWidget {
  const AdapterNotFoundScreen({required this.onGoHome, super.key});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Not found')),
    body: DemoNotFoundContent(
      message: 'Adapter route not found',
      onGoHome: onGoHome,
    ),
  );
}
