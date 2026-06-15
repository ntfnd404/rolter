import 'package:flutter/foundation.dart';

/// Demo session lock. When locked, `LockGuard` redirects protected routes to
/// `UnlockScreen`; unlocking reruns the guards and restores the intended route.
class LockController extends ChangeNotifier {
  bool _locked = false;

  bool get isLocked => _locked;

  void lock() {
    if (!_locked) {
      _locked = true;
      notifyListeners();
    }
  }

  void unlock() {
    if (_locked) {
      _locked = false;
      notifyListeners();
    }
  }
}
