import 'package:example/feature/animated/routing/animated_nav.dart';
import 'package:example/feature/confirm/routing/confirm_nav.dart';
import 'package:example/feature/detail/routing/detail_nav.dart';
import 'package:example/feature/editor/routing/editor_nav.dart';
import 'package:example/feature/home/view/widgets/home_tile.dart';
import 'package:example/feature/mailbox/routing/mailbox_nav.dart';
import 'package:example/feature/sub_routers/shell/routing/demo_module.dart';
import 'package:example/feature/sub_routers/shell/routing/modules_nav.dart';
import 'package:example/feature/independent_tab_stacks/shell/routing/multitabs_nav.dart';
import 'package:example/feature/picker/routing/picker_nav.dart';
import 'package:example/feature/route_scope/routing/scope_nav.dart';
import 'package:example/feature/session/bloc/lock_bloc.dart';
import 'package:example/feature/session/bloc/lock_event.dart';
import 'package:example/feature/tabbed_stack/shell/routing/tabs_nav.dart';
import 'package:example/core/routing/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          HomeTile(
            icon: Icons.article_outlined,
            title: 'Flat detail',
            subtitle: 'Typed param + deep link — /home/detail~id=5',
            onTap: () => nav.toDetail(5),
          ),
          HomeTile(
            icon: Icons.animation,
            title: 'Custom transition',
            subtitle: 'Bespoke slide-up + fade via TransitionPage',
            onTap: nav.toAnimated,
          ),
          HomeTile(
            icon: Icons.email_outlined,
            title: 'Mailbox (master-detail)',
            subtitle: 'Split on wide / push on narrow; selection in the URL',
            onTap: nav.toMailbox,
          ),
          HomeTile(
            icon: Icons.tab,
            title: 'Tabs + nested stack (guarded)',
            subtitle: 'IndexedStack tabs, nested back, protected by a guard',
            onTap: nav.toTabs,
          ),
          HomeTile(
            icon: Icons.dynamic_feed,
            title: 'Multi-tab independent stacks',
            subtitle: 'Each tab keeps its own stack — all of it in the URL',
            onTap: nav.toMultiTabs,
          ),
          HomeTile(
            icon: Icons.account_tree_outlined,
            title: 'Feature sub-routers',
            subtitle: 'Shop & Blog own their registries; both reuse "detail"',
            onTap: () => nav.toModule(DemoModule.shop),
          ),
          HomeTile(
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
          HomeTile(
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
          HomeTile(
            icon: Icons.exposure,
            title: 'Per-route scope',
            subtitle:
                'A controller created/disposed with the page (RouteScope)',
            onTap: nav.toScope,
          ),
          HomeTile(
            icon: Icons.edit_note,
            title: 'Confirm on leave',
            subtitle: 'Block back with unsaved changes (PopScope)',
            onTap: nav.toEditor,
          ),
          const Divider(),
          HomeTile(
            icon: Icons.lock_outline,
            title: 'Lock session',
            subtitle: 'Then open Tabs → redirected to unlock, then restored',
            onTap: () => context.read<LockBloc>().add(const LockRequested()),
          ),
        ],
      ),
    );
  }
}
