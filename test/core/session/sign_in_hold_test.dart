import 'dart:async';

import 'package:ecoeats/core/session/sign_in_hold.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // testWidgets runs on a fake clock, so the limit passes without waiting.
  testWidgets('nothing held lets the move happen at once', (tester) async {
    var moved = false;
    unawaited(SignInHold().wait().then((_) => moved = true));
    await tester.pump();
    expect(moved, isTrue);
  });

  testWidgets('a hold lasts until it is released', (tester) async {
    final hold = SignInHold()..hold();
    var moved = false;
    unawaited(hold.wait().then((_) => moved = true));

    await tester.pump(const Duration(seconds: 2));
    expect(moved, isFalse);

    hold.release();
    await tester.pump();
    expect(moved, isTrue);
  });

  testWidgets('a hold never released gives way after the limit', (
    tester,
  ) async {
    final hold = SignInHold()..hold();
    var moved = false;
    unawaited(hold.wait().then((_) => moved = true));

    await tester.pump(SignInHold.limit - const Duration(milliseconds: 1));
    expect(moved, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(moved, isTrue);
  });

  testWidgets('releasing twice or holding again is harmless', (tester) async {
    final hold = SignInHold()
      ..hold()
      ..release()
      ..release()
      ..hold();
    var moved = false;
    unawaited(hold.wait().then((_) => moved = true));
    await tester.pump();
    expect(moved, isFalse);

    hold.release();
    await tester.pump();
    expect(moved, isTrue);
  });
}
