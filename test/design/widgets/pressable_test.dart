import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: ecoTheme(.light),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(body: Center(child: child)),
);

double _pressScale(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byType(Pressable),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    // The x scale: Transform.scale leaves the z axis at 1.
    .entry(0, 0);

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

/// The button in a 300 px wide slot, so its full width is known.
Widget _button({
  bool loading = false,
  bool success = false,
  VoidCallback? onPressed,
  VoidCallback? onSuccess,
  bool reduceMotion = false,
}) => _app(
  SizedBox(
    width: 300,
    child: EcoButton(
      label: 'Entrar',
      loading: loading,
      success: success,
      onPressed: onPressed,
      onSuccess: onSuccess,
    ),
  ),
  reduceMotion: reduceMotion,
);

Size _shape(WidgetTester tester) =>
    tester.getSize(find.byKey(EcoButton.shapeKey));

double _opacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(EcoButton),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

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

    testWidgets('sinks while held and springs back to rest on release', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      var taps = 0;
      await tester.pumpWidget(
        _app(Pressable(onPressed: () => taps++, child: const Text('Tap'))),
      );
      final press = await tester.startGesture(
        tester.getCenter(find.text('Tap')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_pressScale(tester), lessThan(0.99));
      expect(taps, 0);

      await press.up();
      await tester.pump();
      expect(taps, 1);
      expect(haptics, ['HapticFeedbackType.selectionClick']);
      await tester.pumpAndSettle();
      expect(_pressScale(tester), 1);
    });

    testWidgets('with reduced motion it never scales', (tester) async {
      await tester.pumpWidget(
        _app(
          Pressable(onPressed: () {}, child: const Text('Tap')),
          reduceMotion: true,
        ),
      );
      final press = await tester.startGesture(
        tester.getCenter(find.text('Tap')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_pressScale(tester), 1);
      await press.up();
      await tester.pumpAndSettle();
      expect(_pressScale(tester), 1);
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
    testWidgets('without a callback it is faded and disabled', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_button());
      await tester.pumpAndSettle();
      expect(_opacity(tester), 0.4);
      expect(
        tester.getSemantics(find.byType(Pressable)),
        isSemantics(
          label: 'Entrar',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('loading narrows it into a circle in the same slot', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(_button(onPressed: () => taps++));
      await tester.pumpAndSettle();
      expect(_shape(tester), const Size(300, EcoButton.height));

      await tester.pumpWidget(_button(loading: true, onPressed: () => taps++));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(_shape(tester), const Size.square(EcoButton.height));
      expect(tester.getSize(find.byType(EcoButton)).width, 300);
      expect(find.byType(PlateSpinner), findsOneWidget);
      expect(_opacity(tester), 1);
      await tester.tap(find.byKey(EcoButton.shapeKey));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 0);
    });

    testWidgets('after loading without success it widens back to its label', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(_button(loading: true, onPressed: () => taps++));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpWidget(_button(onPressed: () => taps++));
      await tester.pumpAndSettle();
      expect(_shape(tester), const Size(300, EcoButton.height));
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.byType(PlateSpinner), findsNothing);
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('success widens it, draws a check and then tells once', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      var taps = 0;
      var successes = 0;
      await tester.pumpWidget(_button(loading: true, onPressed: () => taps++));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpWidget(
        _button(
          loading: true,
          success: true,
          onPressed: () => taps++,
          onSuccess: () => successes++,
        ),
      );
      await tester.pump();
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      expect(successes, 0);

      await tester.pumpAndSettle();
      expect(_shape(tester), const Size(300, EcoButton.height));
      expect(find.byKey(EcoButton.checkKey), findsOneWidget);
      expect(find.byType(PlateSpinner), findsNothing);
      expect(successes, 1);

      await tester.tap(find.byKey(EcoButton.shapeKey));
      await tester.pumpAndSettle();
      expect(taps, 0);
      expect(successes, 1);
    });

    testWidgets('with reduced motion it keeps its width and still succeeds', (
      tester,
    ) async {
      var successes = 0;
      await tester.pumpWidget(_button(loading: true, reduceMotion: true));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_shape(tester), const Size(300, EcoButton.height));
      expect(find.byType(PlateSpinner), findsOneWidget);

      await tester.pumpWidget(
        _button(
          loading: true,
          success: true,
          onSuccess: () => successes++,
          reduceMotion: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(_shape(tester), const Size(300, EcoButton.height));
      expect(find.byKey(EcoButton.checkKey), findsOneWidget);
      expect(successes, 1);
    });
  });
}
