import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/session/session.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:ecoeats/router/app_router.dart';
import 'package:ecoeats/router/guards.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Guest extends SessionController {
  @override
  Future<Session?> build() async => null;
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));

  testWidgets('a panel opened over another keeps the one beneath painted, '
      'shrunk behind it', (tester) async {
    final router = AppRouter(
      authGuard: AuthGuard(isSignedIn: () => false),
      guestGuard: GuestGuard(isSignedIn: () => false),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionControllerProvider.overrideWith(_Guest.new)],
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: ecoTheme(.light),
            routerConfig: router.config(
              deepLinkBuilder: (_) => const DeepLink([
                AuthShellRoute(children: [WelcomeRoute(), LoginRoute()]),
              ]),
            ),
          ),
        ),
      ),
    );
    // The auth backdrop keeps moving, so frames are pumped, not settled.
    Future<void> frames() async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await frames();
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await frames();

    expect(find.text('Recupera tu contraseña.'), findsOneWidget);
    // Offstage widgets are not found: the login is still painted.
    expect(find.text('Hola otra vez.'), findsOneWidget);
    final scales = tester
        .widgetList<Transform>(
          find.ancestor(
            of: find.text('Hola otra vez.'),
            matching: find.byType(Transform),
          ),
        )
        .map((transform) => transform.transform.storage[0]);
    expect(scales, contains(moreOrLessEquals(0.94)));
  });
}
