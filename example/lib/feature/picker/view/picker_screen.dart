import '../../../core/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Full-screen picker pushed for a result. Tapping a color returns it with
/// `popWith`; system / app-bar back returns null.
class PickerScreen extends StatelessWidget {
  const PickerScreen({super.key});

  static const List<(String, Color)> _colors = <(String, Color)>[
    ('Red', Colors.red),
    ('Green', Colors.green),
    ('Blue', Colors.blue),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick a color')),
      body: ListView(
        children: [
          for (final (name, color) in _colors)
            ListTile(
              leading: CircleAvatar(backgroundColor: color),
              title: Text(name),
              onTap: () => context.navigator.popWith<Color>(color),
            ),
        ],
      ),
    );
  }
}
