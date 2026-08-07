import 'package:flutter/material.dart';

import '../../../common/ui/demo_not_found_content.dart';

final class ScopedNotFoundScreen extends StatelessWidget {
  const ScopedNotFoundScreen({required this.onGoHome, super.key});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Not found')),
    body: DemoNotFoundContent(
      message: 'No scoped route matches this location.',
      onGoHome: onGoHome,
    ),
  );
}
