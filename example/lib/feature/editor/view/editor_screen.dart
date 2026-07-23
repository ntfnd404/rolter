import '../../../core/routing/app_navigator.dart';
import 'package:flutter/material.dart';

/// Confirm-on-leave demo.
///
/// The idiomatic Navigator-2.0 veto point is [PopScope] on the screen: the
/// route guard pipeline runs *after* a page is removed (`onDidRemovePage`), so
/// it cannot pre-empt a back gesture — but [PopScope] can. While the field is
/// dirty, `canPop` is false: the AppBar back button and the system/predictive
/// back gesture are blocked, [PopScope.onPopInvokedWithResult] fires, and the
/// screen decides whether to actually leave (via `context.navigator.pop()`).
///
/// (A route guard's `cancel` is the *programmatic* safety net — the engine
/// re-syncs the navigator to the tree when a guard reverts a removal — but a
/// per-screen confirm dialog belongs in `PopScope`, not a guard.)
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _dirty = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes in the editor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if ((leave ?? false) && mounted) {
      context.navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Editor (confirm on leave)')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _dirty
                    ? 'Unsaved changes — back asks to confirm.'
                    : 'Type something to make the editor dirty.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                onChanged: (_) {
                  if (!_dirty) {
                    setState(() => _dirty = true);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Draft',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
