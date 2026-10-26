import 'package:ecoeats/design/painters/plate_illustration.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/rating_stars.dart';
import 'package:ecoeats/design/widgets/segmented_pills.dart';
import 'package:ecoeats/design/widgets/toast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {Brightness brightness = .light}) => MaterialApp(
  theme: ecoTheme(brightness),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('SegmentedPills', () {
    testWidgets('a tap reports its value', (tester) async {
      String? chosen;
      await tester.pumpWidget(
        _app(
          SegmentedPills<String>(
            values: const ['all', 'featured', 'light'],
            selected: 'all',
            labelOf: (value) => value.toUpperCase(),
            onChanged: (value) => chosen = value,
          ),
        ),
      );
      await tester.tap(find.text('FEATURED'));
      expect(chosen, 'featured');
    });

    testWidgets('the selected pill says so to accessibility', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          SegmentedPills<String>(
            values: const ['all', 'featured'],
            selected: 'featured',
            labelOf: (value) => value,
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('featured')),
        isSemantics(label: 'featured', isButton: true, isSelected: true),
      );
      expect(
        tester.getSemantics(find.text('all')),
        isSemantics(label: 'all', isButton: true, isSelected: false),
      );
      semantics.dispose();
    });
  });

  testWidgets('4.5 stars fill four and half of the fifth', (tester) async {
    await tester.pumpWidget(
      _app(const RatingStars(rating: 4.5, semanticLabel: '4,5 de 5')),
    );
    final fills = tester
        .widgetList<Align>(
          find.descendant(
            of: find.byType(RatingStars),
            matching: find.byType(Align),
          ),
        )
        .map((align) => align.widthFactor);
    expect(fills, [1, 1, 1, 1, 0.5]);
    expect(find.bySemanticsLabel('4,5 de 5'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('drawings render in ${brightness.name}', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            mainAxisSize: .min,
            children: [
              PlateSpinner(),
              PlateSpinner(progress: 0.4),
              PlateIllustration(),
              RatingStars(rating: 3.2),
            ],
          ),
          brightness: brightness,
        ),
      );
      await tester.pump(const Duration(milliseconds: 450));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a toast appears on top and leaves on its own', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Toast.show(context, 'Tu sesión venció.'),
            child: const Text('show'),
          ),
        ),
        brightness: .dark,
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Tu sesión venció.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Tu sesión venció.'), findsNothing);
  });
}
