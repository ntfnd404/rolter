import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

void main() {
  group('StreamListenable', () {
    test('fires its listeners on each stream event', () async {
      final controller = StreamController<bool>();
      addTearDown(controller.close);
      final listenable = StreamListenable(controller.stream);
      addTearDown(listenable.dispose);

      var fired = 0;
      listenable.addListener(() => fired++);

      controller.add(true);
      controller.add(false);
      await pumpEventQueue();

      expect(fired, 2);
    });

    test('a removed listener stops receiving events', () async {
      final controller = StreamController<int>();
      addTearDown(controller.close);
      final listenable = StreamListenable(controller.stream);
      addTearDown(listenable.dispose);

      var fired = 0;
      void listener() => fired++;
      listenable.addListener(listener);

      controller.add(1);
      await pumpEventQueue();
      listenable.removeListener(listener);
      controller.add(2);
      await pumpEventQueue();

      expect(fired, 1);
    });

    test('dispose cancels the subscription — no more notifications', () async {
      final controller = StreamController<int>();
      addTearDown(controller.close);
      final listenable = StreamListenable(controller.stream);

      var fired = 0;
      listenable.addListener(() => fired++);

      listenable.dispose();
      controller.add(1);
      await pumpEventQueue();

      expect(fired, 0);
      expect(controller.hasListener, isFalse);
    });

    test('is a Listenable — usable wherever the pipeline expects one', () {
      final controller = StreamController<int>();
      addTearDown(controller.close);
      final listenable = StreamListenable(controller.stream);
      addTearDown(listenable.dispose);

      expect(listenable, isA<Listenable>());
    });
  });
}
