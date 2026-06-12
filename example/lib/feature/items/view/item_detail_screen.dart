import 'package:flutter/material.dart';

/// A detail pushed inside the Items tab's nested navigator. Content only — the
/// shared AppBar (titled "Item #N" here) lives in `TabsShell`.
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Nested detail for item #$id.'));
  }
}
