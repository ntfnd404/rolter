import '../../shell/routing/mt_tab.dart';
import '../../shell/view/mt_tab_presentation.dart';
import 'package:flutter/material.dart';

/// A detail page living on one tab's nested stack. Switch tabs while it is open
/// — it stays put on its own stack (and in the URL).
class MtDetailScreen extends StatelessWidget {
  const MtDetailScreen({required this.tab, required this.id, super.key});

  final MtTab tab;
  final int id;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tab.icon, size: 48),
          const SizedBox(height: 12),
          Text(
            '${tab.label} · item #$id',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Switch tabs — this detail stays on its own stack.'),
        ],
      ),
    );
  }
}
