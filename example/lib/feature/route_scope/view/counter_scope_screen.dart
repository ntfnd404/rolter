import 'package:example/feature/route_scope/controller/counter_controller.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

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
