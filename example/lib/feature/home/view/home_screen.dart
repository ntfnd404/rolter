import 'package:example/feature/home/routing/home_nav.dart';
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
          _DemoTile(
            icon: Icons.article_outlined,
            title: 'Flat detail',
            subtitle: 'Typed param + deep link — /home/detail~id=5',
            onTap: () => nav.toDetail(5),
          ),
          _DemoTile(
            icon: Icons.animation,
            title: 'Custom transition',
            subtitle: 'Bespoke slide-up + fade via TransitionPage',
            onTap: nav.toAnimated,
          ),
          _DemoTile(
            icon: Icons.email_outlined,
            title: 'Mailbox (master-detail)',
            subtitle: 'Split on wide / push on narrow; selection in the URL',
            onTap: nav.toMailbox,
          ),
          _DemoTile(
            icon: Icons.tab,
            title: 'Tabs + nested stack (guarded)',
            subtitle: 'IndexedStack tabs, nested back, protected by a guard',
            onTap: nav.toTabs,
          ),
          _DemoTile(
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
          _DemoTile(
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
          _DemoTile(
            icon: Icons.exposure,
            title: 'Per-route scope',
            subtitle:
                'A controller created/disposed with the page (RouteScope)',
            onTap: nav.toScope,
          ),
          const Divider(),
          _DemoTile(
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

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
