import 'package:flutter/material.dart';

import 'package:rolter/rolter.dart';

/// A per-route controller. Created by `RouteScope` when the route is pushed and
/// disposed when it is popped (watch the debugPrint in the console).
class CounterController extends ChangeNotifier {
  CounterController() {
    debugPrint('CounterController created');
  }

  int _value = 0;

  int get value => _value;

  void increment() {
    _value++;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('CounterController disposed');
    super.dispose();
  }
}

/// Reads its [CounterController] from the enclosing `RouteScope`, proving the
/// controller lives exactly as long as this page.
class CounterScopeScreen extends StatelessWidget {
  const CounterScopeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = RouteScope.of<CounterController>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Per-route scope')),
      body: Center(
        child: ListenableBuilder(
          listenable: counter,
          builder: (context, _) => Text(
            'Count: ${counter.value}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: counter.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
