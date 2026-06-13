import 'package:example/di/app_dependencies.dart';
import 'package:example/di/app_scope.dart';
import 'package:example/feature/home/routing/home_route.dart';
import 'package:example/feature/items/data/data_sources/item_local_data_source_impl.dart';
import 'package:example/feature/items/data/repositories/item_repository_impl.dart';
import 'package:example/feature/mailbox/data/data_sources/mail_local_data_source_impl.dart';
import 'package:example/feature/mailbox/data/repositories/mail_repository_impl.dart';
import 'package:example/feature/session/di/lock_controller.dart';
import 'package:example/feature/session/routing/lock_guard.dart';
import 'package:example/feature/session/di/lock_scope.dart';
import 'package:example/routing/app_navigator.dart';
import 'package:example/routing/app_registry.dart';
import 'package:example/routing/app_route.dart';
import 'package:example/routing/nav_log_guard.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Root of the rolter example — the composition root. Builds the engine pieces
/// over [AppRoute] and aggregates each feature's decoders via [appRegistry].
///
/// `NavigatorScope` sits ABOVE `MaterialApp.router` (read by `buildPage` via the
/// delegate context). `AppScope` + `LockScope` sit in the router's `builder:` —
/// below `MaterialApp` (so the DI graph has `Theme`/`MediaQuery`) and above the
/// `Navigator`.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  // Composition root: the dependency graph (data source -> repository) is wired
  // here once, then exposed app-wide via AppScope — never in a route or screen.
  final AppDependencies _dependencies = const AppDependencies(
    mailRepository: MailRepositoryImpl(MailLocalDataSourceImpl()),
    itemRepository: ItemRepositoryImpl(ItemLocalDataSourceImpl()),
  );
  late final LockController _lock;
  late final LockGuard _lockGuard;
  late final NavigationLogGuard _navLogGuard;
  late final RoutesState<AppRoute> _state;
  late final AppNavigator _navigator;
  late final RoutingDelegate<AppRoute> _delegate;
  late final RoutingInformationParser<AppRoute> _parser;

  @override
  void initState() {
    super.initState();
    _lock = LockController();
    _lockGuard = LockGuard(_lock);
    _navLogGuard = NavigationLogGuard();
    final pipeline = GuardedPipeline<AppRoute>(
      guards: <RouteGuard<AppRoute>>[_navLogGuard, _lockGuard],
      normalize: normalizeAppStack,
      currentStack: () => _state.root,
    );
    _state = RoutesState<AppRoute>(const [HomeRoute()], pipeline.call);
    pipeline.refresh.addListener(_state.reevaluate);
    _navigator = AppNavigator(_state);
    _delegate = RoutingDelegate<AppRoute>(_state);
    _parser = RoutingInformationParser<AppRoute>(
      TreeUrlCodec<AppRoute>(appRegistry),
    );
  }

  @override
  void dispose() {
    _delegate.dispose();
    _state.dispose();
    _lockGuard.dispose();
    _navLogGuard.dispose();
    _lock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorScope<AppNavigator>(
      navigator: _navigator,
      child: MaterialApp.router(
        title: 'rolter example',
        routerDelegate: _delegate,
        routeInformationParser: _parser,
        builder: (context, child) => AppScope(
          dependencies: _dependencies,
          child: LockScope(controller: _lock, child: child!),
        ),
      ),
    );
  }
}
