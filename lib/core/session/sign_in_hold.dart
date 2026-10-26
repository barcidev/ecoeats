import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_hold.g.dart';

@Riverpod(keepAlive: true)
SignInHold signInHold(Ref ref) => SignInHold();

/// Lets a sign-in screen finish its celebration (the button's check and the
/// sweep born from it) before the app moves to Home, which it would
/// otherwise do the moment the session starts.
///
/// The screen holds before sending the credentials and releases once its
/// celebration covers the app, or when the attempt fails.
class SignInHold {
  /// How long the move waits at most, counted from when the session starts,
  /// so a lost release never strands anyone on the sign-in screen.
  static const limit = Duration(seconds: 3);

  Completer<void>? _pending;

  void hold() {
    release();
    _pending = Completer<void>();
  }

  void release() {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  /// Completes at once when nothing holds, on release, or after [limit].
  Future<void> wait() {
    final pending = _pending;
    if (pending == null) return Future.value();
    return pending.future.timeout(limit, onTimeout: () {});
  }
}
