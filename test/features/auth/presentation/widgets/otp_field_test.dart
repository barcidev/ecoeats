import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/features/auth/presentation/widgets/otp_field.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late List<String> completed;
  late List<MethodCall> platformCalls;

  setUp(() {
    completed = [];
    platformCalls = [];
  });

  Future<void> pumpField(
    WidgetTester tester, {
    bool error = false,
    bool enabled = true,
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OtpField(
              onCompleted: completed.add,
              semanticsLabel: 'Código de 6 dígitos',
              error: error,
              enabled: enabled,
            ),
          ),
        ),
      ),
    );
    // Autofocus lands one frame after the first build.
    await tester.pump();
  }

  List<String> digits(WidgetTester tester) => [
    for (var i = 0; i < OtpField.length; i++)
      ...tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(OtpField.boxKey(i)),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data ?? ''),
  ];

  Color borderOf(WidgetTester tester, int index) {
    final box = tester.widget<AnimatedContainer>(
      find.byKey(OtpField.boxKey(index)),
    );
    final shape = (box.decoration! as ShapeDecoration).shape;
    return (shape as OutlinedBorder).side.color;
  }

  bool caretIn(int index) => find
      .descendant(
        of: find.byKey(OtpField.boxKey(index)),
        matching: find.byKey(OtpField.caretKey),
      )
      .evaluate()
      .isNotEmpty;

  testWidgets('typing fills the boxes in order and moves the caret', (
    tester,
  ) async {
    await pumpField(tester);
    expect(caretIn(0), isTrue);

    await tester.enterText(find.byType(TextField), '123');
    await tester.pumpAndSettle();

    expect(digits(tester), ['1', '2', '3']);
    expect(caretIn(3), isTrue);
    expect(completed, isEmpty);
  });

  testWidgets('the sixth digit reports the code once', (tester) async {
    await pumpField(tester);

    await tester.enterText(find.byType(TextField), '12345');
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    expect(completed, ['123456']);
    expect(digits(tester), ['1', '2', '3', '4', '5', '6']);
  });

  testWidgets('a paste keeps only the first six digits', (tester) async {
    await pumpField(tester);

    await tester.enterText(find.byType(TextField), 'Tu código: 482 913 7');
    await tester.pumpAndSettle();

    expect(completed, ['482913']);
    expect(digits(tester), ['4', '8', '2', '9', '1', '3']);
  });

  testWidgets('letters are dropped', (tester) async {
    await pumpField(tester);

    await tester.enterText(find.byType(TextField), '12ab');
    await tester.pumpAndSettle();

    expect(digits(tester), ['1', '2']);
  });

  testWidgets('an error clears the field, plays a haptic and stays until '
      'the user types', (tester) async {
    await pumpField(tester);
    await tester.enterText(find.byType(TextField), '111111');
    await tester.pumpAndSettle();

    await pumpField(tester, error: true);
    await tester.pumpAndSettle();

    expect(digits(tester), isEmpty);
    expect(
      platformCalls.map((call) => call.method),
      contains('HapticFeedback.vibrate'),
    );
    expect(borderOf(tester, 0), EcoPalette.mantel.achiote);

    await tester.enterText(find.byType(TextField), '1');
    await tester.pumpAndSettle();

    expect(borderOf(tester, 0), isNot(EcoPalette.mantel.achiote));
    expect(digits(tester), ['1']);
  });

  testWidgets('a new rejection clears the field again', (tester) async {
    await pumpField(tester, error: true);
    await tester.enterText(find.byType(TextField), '222222');
    await pumpField(tester);
    await pumpField(tester, error: true);
    await tester.pumpAndSettle();

    expect(digits(tester), isEmpty);
    expect(completed, ['222222']);
  });

  testWidgets('a disabled field takes no input', (tester) async {
    await pumpField(tester, enabled: false);

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(caretIn(0), isFalse);
  });

  testWidgets('screen readers hear one labelled field', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpField(tester);

    expect(find.bySemanticsLabel('Código de 6 dígitos'), findsOneWidget);
    semantics.dispose();
  });
}
