import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/session/session.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/painters/logo_mark.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/features/auth/presentation/auth_pages.dart';
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

const _ajiaco = 'assets/photos/ajiaco.jpg';
const _sancocho = 'assets/photos/sancocho.jpg';

void main() {
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  // The backdrop never stops moving, so these tests pump fixed durations
  // instead of waiting for the screen to settle.
  Future<void> pumpShell(
    WidgetTester tester, {
    bool reduced = false,
    Duration settle = Motion.signature,
  }) async {
    if (reduced) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
    }
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
              deepLinkBuilder: (_) => const DeepLink([AuthShellRoute()]),
            ),
          ),
        ),
      ),
    );
    await settleFor(tester, settle);
  }

  double photoOpacity(WidgetTester tester, String photo) =>
      tester.widget<Opacity>(find.byKey(ValueKey(photo))).opacity;

  double scaleOf(WidgetTester tester, Finder finder) =>
      tester.widget<Transform>(finder).transform.storage[0];

  double photoScale(WidgetTester tester) =>
      scaleOf(tester, find.byKey(AuthShellPage.photoKey));

  double kenBurns(WidgetTester tester, String photo) => scaleOf(
    tester,
    find
        .descendant(
          of: find.byKey(ValueKey(photo)),
          matching: find.byType(Transform),
        )
        .first,
  );

  Future<void> openLogin(WidgetTester tester) async {
    await tester.tap(find.text('Entrar').last);
    await settleFor(tester, Motion.slow * 2);
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Volver'));
    await settleFor(tester, Motion.slow * 2);
  }

  testWidgets('the photos zoom slowly and hand over to the next one', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(photoOpacity(tester, _ajiaco), 1);
    expect(photoOpacity(tester, _sancocho), 0);

    final start = kenBurns(tester, _ajiaco);
    await settleFor(tester, const Duration(seconds: 3));
    expect(kenBurns(tester, _ajiaco), greaterThan(start));

    await settleFor(tester, const Duration(seconds: 5));
    expect(photoOpacity(tester, _sancocho), 1);
  });

  testWidgets('after two rounds the first photo rests and the screen settles', (
    tester,
  ) async {
    await pumpShell(tester);

    await settleFor(tester, const Duration(seconds: 43));
    await tester.pumpAndSettle();

    expect(photoOpacity(tester, _ajiaco), 1);
    expect(photoOpacity(tester, _sancocho), 0);
  });

  testWidgets('the backdrop keeps its state from the welcome to login and '
      'back', (tester) async {
    await pumpShell(tester);
    final backdrop = tester.state(find.byKey(AuthShellPage.backdropKey));

    await openLogin(tester);
    expect(find.text('Hola otra vez.'), findsOneWidget);
    expect(tester.state(find.byKey(AuthShellPage.backdropKey)), backdrop);

    await goBack(tester);
    expect(tester.state(find.byKey(AuthShellPage.backdropKey)), backdrop);
  });

  testWidgets('a panel sends the photo back and returning brings it forward', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(photoScale(tester), 1);

    await openLogin(tester);
    expect(photoScale(tester), moreOrLessEquals(0.94));
    expect(
      tester.widget<ColoredBox>(find.byKey(AuthShellPage.shadeKey)).color.a,
      greaterThan(0),
    );

    await goBack(tester);
    expect(photoScale(tester), 1);
  });

  testWidgets('with reduced motion the photo darkens without moving', (
    tester,
  ) async {
    await pumpShell(tester, reduced: true);
    final start = kenBurns(tester, _ajiaco);
    await settleFor(tester, const Duration(seconds: 3));
    expect(kenBurns(tester, _ajiaco), start);

    await openLogin(tester);
    expect(photoScale(tester), 1);
    expect(
      tester.widget<ColoredBox>(find.byKey(AuthShellPage.shadeKey)).color.a,
      greaterThan(0),
    );
  });

  group('welcome', () {
    double logoProgress(WidgetTester tester) =>
        tester.widget<LogoMark>(find.byType(LogoMark)).progress;

    double actionsOpacity(WidgetTester tester) => tester
        .widget<FadeTransition>(find.byKey(WelcomePage.actionsKey))
        .opacity
        .value;

    testWidgets('draws its logo, then reveals the headline and the actions', (
      tester,
    ) async {
      await pumpShell(tester, settle: const Duration(milliseconds: 200));
      expect(logoProgress(tester), lessThan(1));
      expect(actionsOpacity(tester), 0);

      await settleFor(tester, const Duration(milliseconds: 1400));
      expect(logoProgress(tester), 1);
      expect(actionsOpacity(tester), 1);
      expect(find.text('Comida colombiana,'), findsOneWidget);
      expect(find.text('sin afán.'), findsOneWidget);
      expect(find.bySemanticsLabel('Comida colombiana, sin afán.'), findsOne);
    });

    testWidgets('opens login and registration', (tester) async {
      await pumpShell(tester, settle: const Duration(milliseconds: 1600));

      await tester.tap(find.text('Entrar'));
      await settleFor(tester, Motion.slow * 2);
      expect(find.text('Hola otra vez.'), findsOneWidget);

      await goBack(tester);
      await tester.tap(find.text('Crear cuenta'));
      await settleFor(tester, Motion.slow * 2);
      expect(find.text('Crea tu cuenta.'), findsOneWidget);
    });

    testWidgets('with reduced motion it shows at once', (tester) async {
      await pumpShell(
        tester,
        reduced: true,
        settle: const Duration(milliseconds: 200),
      );

      expect(logoProgress(tester), 1);
      expect(actionsOpacity(tester), 1);
      expect(find.text('sin afán.'), findsOneWidget);
    });
  });
}

/// Pumps frames for [duration] in steps, as a moving screen never settles.
Future<void> settleFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
    await tester.pump(step);
  }
}
