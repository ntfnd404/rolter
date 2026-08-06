import 'package:example/apps/feature_first/composition/app_route_page_catalog.dart';
import 'package:example/apps/feature_first/feature/mailbox/domain/entities/mail.dart';
import 'package:example/apps/feature_first/feature/mailbox/domain/repositories/mail_repository.dart';
import 'package:example/apps/feature_first/feature/mailbox/page_composition/mailbox_pages.dart';
import 'package:example/apps/feature_first/feature/mailbox/routing/mailbox_route.dart';
import 'package:example/apps/feature_first/feature/mailbox/view/mailbox_screen.dart';
import 'package:example/apps/feature_first/navigation/app_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

@immutable
final class _FirstRoute extends AppRoute {
  const _FirstRoute();

  @override
  LocalKey get pageKey => const ValueKey('first');

  @override
  String get name => 'shared';

  @override
  Map<String, String> toParams() => const {};
}

@immutable
final class _SecondRoute extends AppRoute {
  const _SecondRoute();

  @override
  LocalKey get pageKey => const ValueKey('second');

  @override
  String get name => 'shared';

  @override
  Map<String, String> toParams() => const {};
}

final class _MailRepository implements MailRepository {
  @override
  List<Mail> all() => const [];

  @override
  Mail? byId(int? id) => null;
}

AppRoutePageDefinition _definition<R extends AppRoute>(String label) =>
    TypedAppRoutePageDefinition<R>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: Text(label),
      ),
    );

void main() {
  test('rejects duplicate route-type definitions without route data', () {
    expect(
      () => AppRoutePageCatalog([
        _definition<_FirstRoute>('first'),
        _definition<_FirstRoute>('duplicate'),
      ]),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(contains('$_FirstRoute'), isNot(contains('shared'))),
        ),
      ),
    );
  });

  testWidgets('rejects a missing typed definition safely', (tester) async {
    final catalog = AppRoutePageCatalog(const []);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(
      () => catalog.build(context, const _FirstRoute()),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(contains('$_FirstRoute'), isNot(contains('shared'))),
        ),
      ),
    );
  });

  testWidgets('rejects an incompatible typed definition with types only', (
    tester,
  ) async {
    final definition = _definition<_FirstRoute>('first');
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(
      () => definition.build(
        context,
        const _SecondRoute(),
        (_, _) => throw UnimplementedError(),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('$_FirstRoute'),
            contains('$_SecondRoute'),
            isNot(contains('shared')),
          ),
        ),
      ),
    );
  });

  testWidgets('dispatches equal wire names by route type', (tester) async {
    final catalog = AppRoutePageCatalog([
      _definition<_FirstRoute>('first'),
      _definition<_SecondRoute>('second'),
    ]);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    final first = catalog.build(context, const _FirstRoute());
    final second = catalog.build(context, const _SecondRoute());

    expect((first as MaterialPage<Object?>).child, isA<Text>());
    expect(((first.child as Text).data), 'first');
    expect((second as MaterialPage<Object?>).child, isA<Text>());
    expect(((second.child as Text).data), 'second');
  });

  testWidgets('supplies the complete catalog as the nested builder', (
    tester,
  ) async {
    Page<Object?>? nestedPage;
    final catalog = AppRoutePageCatalog([
      TypedAppRoutePageDefinition<_FirstRoute>(
        pageFactory: (context, route, nestedPageBuilder) {
          nestedPage = nestedPageBuilder(context, const _SecondRoute());
          return MaterialPage<Object?>(
            key: route.pageKey,
            child: const SizedBox(),
          );
        },
      ),
      _definition<_SecondRoute>('nested'),
    ]);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    catalog.build(context, const _FirstRoute());

    expect(nestedPage, isA<MaterialPage<Object?>>());
    expect((nestedPage! as MaterialPage<Object?>).child, isA<Text>());
  });

  testWidgets('feature definition preserves repository identity', (
    tester,
  ) async {
    final repository = _MailRepository();
    final definition = buildMailboxPageDefinition(repository: repository);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    final page = definition.build(
      context,
      const MailboxRoute(),
      (_, _) => throw UnimplementedError(),
    );
    final screen = (page as MaterialPage<Object?>).child as MailboxScreen;

    expect(screen.repository, same(repository));
  });
}
