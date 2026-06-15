import 'package:flutter/material.dart';

/// The Settings tab (a plain screen, no nested stack). Content only — the shared
/// AppBar lives in `TabsShell`.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings tab (state kept across switches).'),
    );
  }
}
