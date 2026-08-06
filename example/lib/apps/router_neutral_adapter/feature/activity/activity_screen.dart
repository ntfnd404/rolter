import 'package:flutter/material.dart';

import '../../application/app_navigation_controller.dart';
import 'activity_repository.dart';

/// Activity UI depending only on application contracts.
final class AdapterActivityScreen extends StatelessWidget {
  /// Creates the activity screen with explicit narrow dependencies.
  const AdapterActivityScreen({
    required this.sequence,
    required this.repository,
    required this.navigator,
    super.key,
  });

  /// URL-backed sequence displayed by the screen.
  final int sequence;

  /// Exact feature dependency captured by its Page definition.
  final ActivityRepository repository;

  /// Router-neutral navigation port.
  final AppNavigationController navigator;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Activity #$sequence'),
      leading: BackButton(onPressed: navigator.pop),
    ),
    body: Center(child: Text(repository.labelFor(sequence))),
  );
}
