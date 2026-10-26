import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/widgets/eco_text_field.dart';
import 'package:ecoeats/design/widgets/mask_reveal_text.dart';
import 'package:ecoeats/design/widgets/shake.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: ecoTheme(.light),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(24), child: child),
  ),
);

/// Records the haptics the widgets ask the platform for.
List<String> _recordHaptics(WidgetTester tester) {
  final haptics = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return haptics;
}

double _shakeOffset(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(of: find.byType(Shake), matching: find.byType(Transform)),
    )
    .transform
    .getTranslation()
    .x;

EcoUnderlinePainter _underline(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is CustomPaint &&
                    widget.painter is EcoUnderlinePainter,
              ),
            )
            .painter!
        as EcoUnderlinePainter;

void main() {
  group('EcoTextField', () {
    testWidgets('shows its label and error', (tester) async {
      await tester.pumpWidget(
        _app(const EcoTextField(label: 'Correo', error: 'Revisa el correo.')),
      );
      await tester.pumpAndSettle();
      expect(find.text('CORREO'), findsOneWidget);
      expect(find.text('Revisa el correo.'), findsOneWidget);
    });

    testWidgets('the label rests on the line and rises with focus or text', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const EcoTextField(label: 'Correo')));
      await tester.pumpAndSettle();
      final input = tester.getRect(find.byType(EditableText));
      final resting = tester.getRect(find.text('CORREO'));
      expect(resting.top, greaterThanOrEqualTo(input.top));

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      final risen = tester.getRect(find.text('CORREO'));
      expect(risen.bottom, lessThanOrEqualTo(input.top));
      expect(risen.height, lessThan(resting.height));
      expect(tester.getRect(find.byType(EditableText)), input);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('CORREO')), resting);

      await tester.enterText(find.byType(EditableText), 'ana@ecoeats.co');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('CORREO')), risen);
      expect(tester.getRect(find.byType(EditableText)), input);
    });

    testWidgets('the underline draws itself in ink while focused', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const EcoTextField(label: 'Correo')));
      await tester.pumpAndSettle();
      expect(_underline(tester).progress, 0);

      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_underline(tester).progress, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(_underline(tester).progress, 1);
      expect(_underline(tester).active, EcoPalette.mantel.ink);
      expect(_underline(tester).base, EcoPalette.mantel.line);
    });

    testWidgets('an error slides in under the line and leaves again', (
      tester,
    ) async {
      Widget field(String? error) =>
          _app(EcoTextField(label: 'Correo', error: error));
      await tester.pumpWidget(field(null));
      await tester.pumpAndSettle();
      final input = tester.getRect(find.byType(EditableText));

      await tester.pumpWidget(field('Revisa el correo.'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final arriving = tester.getRect(find.text('Revisa el correo.'));
      await tester.pumpAndSettle();
      final settled = tester.getRect(find.text('Revisa el correo.'));
      expect(arriving.top, lessThan(settled.top));
      expect(_underline(tester).base, EcoPalette.mantel.achiote);
      expect(
        tester.widget<Text>(find.text('CORREO')).style?.color,
        EcoPalette.mantel.achiote,
      );
      expect(tester.getRect(find.byType(EditableText)), input);

      await tester.pumpWidget(field(null));
      await tester.pumpAndSettle();
      expect(find.text('Revisa el correo.'), findsNothing);
      expect(_underline(tester).base, EcoPalette.mantel.line);
    });

    testWidgets('with reduced motion the label jumps to its place', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const EcoTextField(label: 'Correo'), reduceMotion: true),
      );
      await tester.pumpAndSettle();
      final input = tester.getRect(find.byType(EditableText));
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(
        tester.getRect(find.text('CORREO')).bottom,
        lessThanOrEqualTo(input.top),
      );
      expect(_underline(tester).progress, 1);
    });

    testWidgets('an obscured field hides what is typed', (tester) async {
      await tester.pumpWidget(
        _app(const EcoTextField(label: 'Contraseña', obscureText: true)),
      );
      await tester.enterText(find.byType(EditableText), 'secreta1');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
    });
  });

  testWidgets('Shake moves when its trigger changes and comes to rest', (
    tester,
  ) async {
    Widget shake(int attempt) =>
        _app(Shake(trigger: attempt, child: const Text('panel')));

    await tester.pumpWidget(shake(0));
    expect(_shakeOffset(tester), 0);

    await tester.pumpWidget(shake(1));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_shakeOffset(tester), isNot(0));

    await tester.pumpAndSettle();
    expect(_shakeOffset(tester), 0);
  });

  testWidgets('Shake swings several times, each weaker, with a haptic', (
    tester,
  ) async {
    final haptics = _recordHaptics(tester);
    Widget shake(int attempt) =>
        _app(Shake(trigger: attempt, child: const Text('panel')));

    await tester.pumpWidget(shake(0));
    await tester.pumpWidget(shake(1));
    expect(haptics, ['HapticFeedbackType.mediumImpact']);

    final offsets = <double>[];
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 10));
      offsets.add(_shakeOffset(tester));
    }
    var turns = 0;
    for (var i = 1; i < offsets.length; i++) {
      if (offsets[i].sign != 0 && offsets[i].sign == -offsets[i - 1].sign) {
        turns++;
      }
    }
    expect(turns, greaterThanOrEqualTo(4));
    double strongest(Iterable<double> values) =>
        values.map((value) => value.abs()).reduce((a, b) => a > b ? a : b);
    expect(
      strongest(offsets.sublist(30, 45)),
      lessThan(strongest(offsets.sublist(0, 15)) / 2),
    );

    await tester.pumpAndSettle();
    expect(_shakeOffset(tester), 0);
  });

  testWidgets('with reduced motion Shake only plays its haptic', (
    tester,
  ) async {
    final haptics = _recordHaptics(tester);
    Widget shake(int attempt) => _app(
      Shake(trigger: attempt, child: const Text('panel')),
      reduceMotion: true,
    );

    await tester.pumpWidget(shake(0));
    await tester.pumpWidget(shake(1));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_shakeOffset(tester), 0);
    expect(haptics, ['HapticFeedbackType.mediumImpact']);
  });

  testWidgets('MaskRevealText ends with every line in place', (tester) async {
    await tester.pumpWidget(
      _app(const MaskRevealText(lines: ['Comida colombiana,', 'sin afán.'])),
    );
    await tester.pumpAndSettle();
    expect(find.text('Comida colombiana,'), findsOneWidget);
    expect(find.text('sin afán.'), findsOneWidget);
    for (final slide in tester.widgetList<SlideTransition>(
      find.descendant(
        of: find.byType(MaskRevealText),
        matching: find.byType(SlideTransition),
      ),
    )) {
      expect(slide.position.value, Offset.zero);
    }
  });
}
