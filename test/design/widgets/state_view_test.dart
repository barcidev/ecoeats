import 'package:ecoeats/design/painters/plate_illustration.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/skeleton.dart';
import 'package:ecoeats/design/widgets/state_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {Brightness brightness = .light}) => MaterialApp(
  theme: ecoTheme(brightness),
  home: Scaffold(body: child),
);

String _wait(Duration remaining) =>
    'Intenta en 0:${remaining.inSeconds.toString().padLeft(2, '0')}';

void main() {
  testWidgets('shows its illustration, texts and footnote', (tester) async {
    await tester.pumpWidget(
      _app(
        const StateView(
          kind: .error,
          title: 'Algo se nos quemó en la cocina.',
          message: 'Vuelve a intentarlo en un momento.',
          footnote: 'Ref. ab12',
        ),
      ),
    );
    expect(find.byType(PlateIllustration), findsOneWidget);
    expect(find.text('Algo se nos quemó en la cocina.'), findsOneWidget);
    expect(find.text('Vuelve a intentarlo en un momento.'), findsOneWidget);
    expect(find.text('Ref. ab12'), findsOneWidget);
    expect(find.byType(EcoButton), findsNothing);
  });

  testWidgets('a cooldown counts down and then enables the action', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _app(
        StateView(
          kind: .rateLimited,
          title: 'Vas muy rápido.',
          actionLabel: 'Reintentar',
          onAction: () => retries++,
          cooldown: const Duration(seconds: 3),
          cooldownLabel: _wait,
        ),
      ),
    );
    expect(find.text('Intenta en 0:03'), findsOneWidget);
    await tester.tap(find.byType(EcoButton));
    expect(retries, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Intenta en 0:02'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
  });

  testWidgets('without a cooldown the action is ready', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _app(
        StateView(
          kind: .offline,
          title: 'Sin conexión.',
          actionLabel: 'Reintentar',
          onAction: () => retries++,
        ),
      ),
    );
    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
  });

  for (final brightness in Brightness.values) {
    testWidgets('skeletons render in ${brightness.name}', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [Skeleton(width: 120, height: 16), Skeleton(height: 200)],
          ),
          brightness: brightness,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Skeleton), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
}
