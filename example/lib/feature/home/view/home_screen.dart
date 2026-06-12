import 'package:example/feature/home/routing/home_nav.dart';
import 'package:example/feature/home/view/demo_title.dart';
import 'package:example/feature/items/routing/items_nav.dart';
import 'package:example/feature/mailbox/routing/mailbox_nav.dart';
import 'package:example/feature/overlays/routing/overlays_nav.dart';
import 'package:example/feature/scope/routing/scope_nav.dart';
import 'package:example/feature/session/di/lock_scope.dart';
import 'package:example/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Landing dashboard linking to every routing scenario. As a navigation hub it
/// imports several feature nav extensions — natural for a landing screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.navigator;
    return Scaffold(
      appBar: AppBar(title: const Text('rolter example')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          DemoTile(
            icon: Icons.article_outlined,
            title: 'Flat detail',
            subtitle: 'Typed param + deep link — /home/detail~id=5',
            onTap: () => nav.toDetail(5),
          ),
          DemoTile(
            icon: Icons.animation,
            title: 'Custom transition',
            subtitle: 'Bespoke slide-up + fade via TransitionPage',
            onTap: nav.toAnimated,
          ),
          DemoTile(
            icon: Icons.email_outlined,
            title: 'Mailbox (master-detail)',
            subtitle: 'Split on wide / push on narrow; selection in the URL',
            onTap: nav.toMailbox,
          ),
          DemoTile(
            icon: Icons.tab,
            title: 'Tabs + nested stack (guarded)',
            subtitle: 'IndexedStack tabs, nested back, protected by a guard',
            onTap: nav.toTabs,
          ),
          DemoTile(
            icon: Icons.palette_outlined,
            title: 'Pick a color',
            subtitle: 'Push-for-result (pushForResult / popWith)',
            onTap: () async {
              final color = await nav.pickColor();
              if (color != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Picked'),
                    backgroundColor: color,
                  ),
                );
              }
            },
          ),
          DemoTile(
            icon: Icons.help_outline,
            title: 'Confirm dialog',
            subtitle: 'Dialog-as-route (TransparentPage), returns a result',
            onTap: () async {
              final confirmed = await nav.confirm('Proceed with the action?');
              if ((confirmed ?? false) && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Confirmed')));
              }
            },
          ),
          DemoTile(
            icon: Icons.exposure,
            title: 'Per-route scope',
            subtitle:
                'A controller created/disposed with the page (RouteScope)',
            onTap: nav.toScope,
          ),
          const Divider(),
          DemoTile(
            icon: Icons.lock_outline,
            title: 'Lock session',
            subtitle: 'Then open Tabs → redirected to unlock, then restored',
            onTap: () => LockScope.of(context).lock(),
          ),
        ],
      ),
    );
  }
}
