import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/features/auth/presentation/widgets/auth_panel.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late DateTime now;

  setUp(() => now = DateTime.utc(2026, 10, 25, 12));

  Widget host(Widget child) => ProviderScope(
    overrides: [clockProvider.overrideWithValue(() => now)],
    child: TranslationProvider(
      child: MaterialApp(theme: ecoTheme(.light), home: child),
    ),
  );

  group('AuthPanel', () {
    testWidgets('shows its overline, title, subtitle, content and footer', (
      tester,
    ) async {
      var backs = 0;
      await tester.pumpWidget(
        host(
          AuthPanel(
            overline: 'Paso 1 de 2',
            title: 'Crea tu cuenta.',
            subtitle: 'Primero, cuéntanos quién eres.',
            onBack: () => backs++,
            footer: const Text('¿Ya tienes cuenta?'),
            children: const [Text('contenido')],
          ),
        ),
      );

      expect(find.text('PASO 1 DE 2'), findsOneWidget);
      expect(find.text('Crea tu cuenta.'), findsOneWidget);
      expect(find.text('Primero, cuéntanos quién eres.'), findsOneWidget);
      expect(find.text('contenido'), findsOneWidget);
      expect(find.text('¿Ya tienes cuenta?'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Volver'));
      expect(backs, 1);
    });
  });

  testWidgets('the password toggle says what it will do and flips', (
    tester,
  ) async {
    var hidden = true;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => Center(
            child: PasswordToggle(
              hidden: hidden,
              onToggle: () => setState(() => hidden = !hidden),
            ),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Mostrar contraseña'), findsOneWidget);
    expect(find.byIcon(EcoIcons.eye), findsOneWidget);

    await tester.tap(find.byType(PasswordToggle));
    await tester.pump();

    expect(hidden, isFalse);
    expect(find.bySemanticsLabel('Ocultar contraseña'), findsOneWidget);
    expect(find.byIcon(EcoIcons.eyeSlash), findsOneWidget);
  });

  group('Countdown', () {
    test('formats minutes and seconds, rounding up', () {
      expect(Countdown.format(const Duration(seconds: 42)), '0:42');
      expect(Countdown.format(const Duration(milliseconds: 41200)), '0:42');
      expect(
        Countdown.format(const Duration(minutes: 14, seconds: 59)),
        '14:59',
      );
      expect(Countdown.format(const Duration(minutes: 15)), '15:00');
      expect(Countdown.format(Duration.zero), '0:00');
      expect(Countdown.format(const Duration(seconds: -3)), '0:00');
    });

    testWidgets('counts down each second and reports the end once', (
      tester,
    ) async {
      var done = 0;
      await tester.pumpWidget(
        host(
          Countdown(
            until: now.add(const Duration(seconds: 2)),
            onDone: () => done++,
            builder: (context, left) => Text(Countdown.format(left)),
          ),
        ),
      );
      expect(find.text('0:02'), findsOneWidget);

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0:01'), findsOneWidget);

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('0:00'), findsOneWidget);
      expect(done, 1);

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(done, 1);
    });
  });
}
