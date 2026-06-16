import 'package:example/feature/independent_tab_stacks/shell/routing/mt_tab.dart';
import 'package:example/feature/independent_tab_stacks/shell/routing/multitabs_nav.dart';
import 'package:example/feature/independent_tab_stacks/shell/view/mt_tab_presentation.dart';
import 'package:example/core/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Root page of a tab's stack. The shell provides the AppBar/NavigationBar, so
/// this is bare content. Opening an item pushes a detail onto *this* tab.
class MtListScreen extends StatelessWidget {
  const MtListScreen({required this.tab, super.key});

  final MtTab tab;

  @override
  Widget build(BuildContext context) {
    final nav = context.navigator;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '${tab.label}: open an item, switch tabs — each tab keeps its own '
            'stack, and the whole thing is in the URL.',
          ),
        ),
        for (var id = 1; id <= 3; id++)
          ListTile(
            leading: Icon(tab.icon),
            title: Text('${tab.label} item #$id'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => nav.openMtItem(tab, id),
          ),
      ],
    );
  }
}
