import '../bloc/lock_bloc.dart';
import '../bloc/lock_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shown by the guard when a protected route is requested while locked.
class UnlockScreen extends StatelessWidget {
  const UnlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locked')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 16),
            const Text('Session is locked'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  context.read<LockBloc>().add(const UnlockRequested()),
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
