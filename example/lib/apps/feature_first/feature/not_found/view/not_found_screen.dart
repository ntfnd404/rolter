import '../../home/routing/home_nav.dart';
import '../../../navigation/app_navigator.dart';
import 'package:flutter/material.dart';

import '../../../../../common/ui/demo_not_found_content.dart';

/// Shown for an unknown URL (the route is `HistoryExcluded`).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({required this.attempted, super.key});

  final Uri attempted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: DemoNotFoundContent(
        message: 'No route for "$attempted"',
        onGoHome: context.navigator.toHome,
      ),
    );
  }
}
