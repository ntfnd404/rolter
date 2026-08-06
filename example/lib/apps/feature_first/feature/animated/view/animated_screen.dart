import 'package:flutter/material.dart';

/// Target of the custom-transition demo. Pushed with a `TransitionPage`, so it
/// slides up while fading in instead of the default platform transition.
class AnimatedScreen extends StatelessWidget {
  const AnimatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom transition')),
      body: const Center(
        child: Text('Arrived via a slide-up + fade (TransitionPage).'),
      ),
    );
  }
}
