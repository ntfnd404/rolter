import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

/// A screen node rendered by the test page builder.
@immutable
class _Screen implements RouteNode {
  const _Screen(this.name);

  @override
  final String name;

  @override
  List<RouteNode> get children => const [];

  @override
  LocalKey get pageKey => ValueKey(name);

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) => other is _Screen && other.name == name;
}

Page<Object?> _buildScreenPage(BuildContext context, _Screen route) =>
    MaterialPage<Object?>(
      key: route.pageKey,
      child: Scaffold(
        appBar: AppBar(title: Text('${route.name}-title')),
        body: Center(child: Text('${route.name}-body')),
      ),
    );

void main() {
  testWidgets(
    'guard cancelling a system-back removal re-syncs (page stays)',
    (tester) async {
      late RoutesState<_Screen> state;
      var veto = true;
      // Veto any shrink of the stack (a removal) while [veto] is on.
      List<_Screen> pipeline(List<_Screen> requested) =>
          veto && requested.length < state.root.length ? state.root : requested;

      state = RoutesState<_Screen>(
        const [_Screen('home'), _Screen('detail')],
        pipeline,
      );
      addTearDown(state.dispose);
      final delegate = RoutingDelegate<_Screen>(
        state,
        pageBuilder: _buildScreenPage,
      );
      addTearDown(delegate.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: delegate,
          backButtonDispatcher: RootBackButtonDispatcher(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('detail-body'), findsOneWidget);

      // Press the AppBar back button -> route pops -> onDidRemovePage -> commit
      // -> guard cancels. Before the fix the navigator dropped the page while
      // state kept it (divergence); now state re-syncs the navigator.
      await tester.tap(find.byType(BackButton));
      await state.processingCompleted;
      await tester.pumpAndSettle();

      expect(find.text('detail-body'), findsOneWidget, reason: 'page vetoed');
      expect(state.root.map((r) => r.name), ['home', 'detail']);

      // With the veto off, the same gesture pops normally.
      veto = false;
      await tester.tap(find.byType(BackButton));
      await state.processingCompleted;
      await tester.pumpAndSettle();

      expect(find.text('detail-body'), findsNothing);
      expect(state.root.map((r) => r.name), ['home']);
    },
  );
}
