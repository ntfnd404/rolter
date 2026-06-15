/// Whether a guard lets navigation proceed or cancels it.
enum NavDecision {
  /// Proceed with the (possibly rewritten) requested stack.
  proceed,

  /// Cancel navigation and keep the current stack.
  cancel,
}
