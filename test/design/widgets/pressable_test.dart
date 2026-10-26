import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: ecoTheme(.light),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('Pressable', () {
    testWidgets('runs its callback once per tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(Pressable(onPressed: () => taps++, child: const Text('Tap'))),
      );
      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('without a callback it is a disabled button', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(const Pressable(semanticLabel: 'Nada', child: Text('Tap'))),
      );
      await tester.tap(find.text('Tap'), warnIfMissed: false);
      expect(
        tester.getSemantics(find.byType(Pressable)),
        isSemantics(
          label: 'Nada',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      semantics.dispose();
    });
  });

  group('EcoButton', () {
    testWidgets('a tap runs its callback', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(EcoButton(label: 'Entrar', onPressed: () => taps++)),
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('loading swaps the label for a spinner and blocks taps', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          EcoButton(label: 'Entrar', loading: true, onPressed: () => taps++),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PlateSpinner), findsOneWidget);
      expect(find.text('Entrar'), findsNothing);
      await tester.tap(find.byType(EcoButton));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 0);
    });
  });
}
