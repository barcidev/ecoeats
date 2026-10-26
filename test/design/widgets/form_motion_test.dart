import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/eco_text_field.dart';
import 'package:ecoeats/design/widgets/mask_reveal_text.dart';
import 'package:ecoeats/design/widgets/shake.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: ecoTheme(.light),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(24), child: child),
  ),
);

double _shakeOffset(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(of: find.byType(Shake), matching: find.byType(Transform)),
    )
    .transform
    .getTranslation()
    .x;

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
