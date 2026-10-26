import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: ecoTheme(.light),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('plateSpinnerArc', () {
    test(
      'grows while the head runs ahead and shrinks as the tail catches up',
      () {
        final start = plateSpinnerArc(0).sweep;
        final quarter = plateSpinnerArc(0.25).sweep;
        final half = plateSpinnerArc(0.5).sweep;
        final threeQuarters = plateSpinnerArc(0.75).sweep;
        expect(quarter, greaterThan(start));
        expect(half, greaterThan(quarter));
        expect(threeQuarters, lessThan(half));
        expect(half, greaterThan(start * 5));
      },
    );

    test('a cycle ends exactly where the next one starts', () {
      final first = plateSpinnerArc(0);
      final last = plateSpinnerArc(0.99999);
      expect(last.sweep, closeTo(first.sweep, 1e-3));
      // Angles in turns: only the fraction of a turn is visible.
      expect(
        (last.start - first.start) % 1,
        anyOf(closeTo(0, 1e-3), closeTo(1, 1e-3)),
      );
    });
  });

  testWidgets('it keeps turning while it spins', (tester) async {
    await tester.pumpWidget(_app(const PlateSpinner()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('with progress it holds still', (tester) async {
    await tester.pumpWidget(_app(const PlateSpinner(progress: 0.4)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
