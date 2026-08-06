import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

void main() {
  testWidgets('custom pages preserve themselves as route settings', (
    tester,
  ) async {
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

    final pages = <Page<Object?>>[
      const TransparentPage<Object?>(
        key: ValueKey<String>('transparent'),
        child: SizedBox(),
      ),
      TransitionPage<Object?>(
        key: const ValueKey<String>('transition'),
        child: const SizedBox(),
        transitionDuration: const Duration(milliseconds: 125),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      const NoAnimationPage<Object?>(
        key: ValueKey<String>('none'),
        child: SizedBox(),
      ),
    ];

    final routes = <Route<Object?>>[
      for (final page in pages) page.createRoute(context),
    ];

    for (var index = 0; index < pages.length; index++) {
      expect(routes[index].settings, same(pages[index]));
    }
    expect(routes[0], isA<PageRouteBuilder<Object?>>());
    expect(
      (routes[1] as PageRouteBuilder<Object?>).transitionDuration,
      const Duration(milliseconds: 125),
    );
    expect(routes[2], isA<PageRoute<Object?>>());
    expect((routes[2] as PageRoute<Object?>).transitionDuration, Duration.zero);
  });
}
