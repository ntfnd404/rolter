import 'package:flutter/material.dart';

import '../../../common/ui/demo_not_found_content.dart';

final class CentralizedErrorScreen extends StatelessWidget {
  const CentralizedErrorScreen({
    required this.message,
    required this.onGoHome,
    super.key,
  });

  final String message;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Not found')),
    body: DemoNotFoundContent(message: message, onGoHome: onGoHome),
  );
}
