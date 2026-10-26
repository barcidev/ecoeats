import 'package:ecoeats/design/painters/plate_illustration.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/design/widgets/rating_stars.dart';
import 'package:ecoeats/design/widgets/segmented_pills.dart';
import 'package:ecoeats/design/widgets/toast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(
  Widget child, {
  Brightness brightness = .light,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: ecoTheme(brightness),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(body: Center(child: child)),
);

void _expectRect(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 0.5));
  expect(actual.top, closeTo(expected.top, 0.5));
  expect(actual.width, closeTo(expected.width, 0.5));
  expect(actual.height, closeTo(expected.height, 0.5));
}

void main() {
  group('SegmentedPills', () {
    const filters = ['Todos', 'Destacados', 'Altos en proteína', 'Ligeros'];

    Widget pills(
      String selected, {
      double width = 600,
      bool reduceMotion = false,
    }) => _app(
      SizedBox(
        width: width,
        child: SegmentedPills<String>(
          values: filters,
          selected: selected,
          labelOf: (value) => value,
          onChanged: (_) {},
          padding: EdgeInsets.zero,
        ),
      ),
      reduceMotion: reduceMotion,
    );

    Rect indicator(WidgetTester tester) =>
        tester.getRect(find.byKey(SegmentedPills.indicatorKey));

    Rect pill(WidgetTester tester, String label) => tester.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(Pressable)),
    );

    testWidgets('one indicator slides and stretches to the picked pill', (
      tester,
    ) async {
      await tester.pumpWidget(pills('Todos'));
      await tester.pumpAndSettle();
      _expectRect(indicator(tester), pill(tester, 'Todos'));

      await tester.pumpWidget(pills('Ligeros'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final moving = indicator(tester);
      expect(moving.left, greaterThan(pill(tester, 'Todos').left));
      expect(moving.left, lessThan(pill(tester, 'Ligeros').left));

      await tester.pumpAndSettle();
      _expectRect(indicator(tester), pill(tester, 'Ligeros'));
    });

    testWidgets('the picked pill scrolls into view', (tester) async {
      await tester.pumpWidget(pills('Todos', width: 200));
      await tester.pumpAndSettle();
      await tester.pumpWidget(pills('Ligeros', width: 200));
      await tester.pumpAndSettle();
      final row = tester.getRect(find.byType(SingleChildScrollView));
      final picked = pill(tester, 'Ligeros');
      expect(picked.left, greaterThanOrEqualTo(row.left));
      expect(picked.right, lessThanOrEqualTo(row.right));
      _expectRect(indicator(tester), picked);
    });

    testWidgets('with reduced motion the indicator jumps', (tester) async {
      await tester.pumpWidget(pills('Todos', reduceMotion: true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(pills('Ligeros', reduceMotion: true));
      await tester.pump();
      await tester.pump();
      _expectRect(indicator(tester), pill(tester, 'Ligeros'));
    });

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
