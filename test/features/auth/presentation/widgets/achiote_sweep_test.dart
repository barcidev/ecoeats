import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/features/auth/presentation/widgets/achiote_sweep.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  // Like the app, an overlay above the navigator hosts what must outlive a
  // route change.
  Future<void> pumpHost(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        theme: ecoTheme(.light),
        builder: (context, child) =>
            Overlay(initialEntries: [OverlayEntry(builder: (_) => child!)]),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  AchioteSweep.play(context, origin: const Offset(200, 600));
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('Home')),
                    ),
                  );
                },
                child: const Text('Entrar'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double sweepOpacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find.descendant(
          of: find.byKey(AchioteSweep.key),
          matching: find.byType(Opacity),
        ),
      )
      .opacity;

  testWidgets('covers the app over the route change and then leaves', (
    tester,
  ) async {
    await pumpHost(tester);
    await tester.tap(find.text('Entrar'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(AchioteSweep.key), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Home'), findsOneWidget);
    expect(find.byKey(AchioteSweep.key), findsOneWidget);
    expect(sweepOpacity(tester), 1);

    await tester.pumpAndSettle();
    expect(find.byKey(AchioteSweep.key), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('reduced motion skips it', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await pumpHost(tester);
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.byKey(AchioteSweep.key), findsNothing);
  });
}
