import 'dart:async';

import 'package:ecoeats/app.dart';
import 'package:ecoeats/core/session/session.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/core/session/token_store.dart';
import 'package:ecoeats/features/dishes/data/dish_repository.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:ecoeats/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

final _session = Session(
  token: 'jwt',
  userId: 'u1',
  email: 'jorge@example.com',
  expiresAt: DateTime.now().add(const Duration(hours: 20)),
);

const _ajiaco = Dish(
  id: 'a',
  name: 'Ajiaco santafereño',
  description: '',
  image: '',
  thumbnail: '',
  price: 26000,
  carbohydrates: 40,
  proteins: 30,
  rating: 4.8,
  ingredients: '',
  featured: true,
);

class _FakeSession extends SessionController {
  new({this.initial});

  final Session? initial;

  @override
  Future<Session?> build() async => initial;

  @override
  Future<void> login({required String email, required String password}) async {
    state = AsyncData(_session);
  }

  @override
  Future<void> logout() async => state = const AsyncData(null);
}

class _MemoryTokenStore implements TokenStore {
  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> writeToken(String token) async {}

  @override
  Future<void> deleteToken() async {}

  @override
  Future<String?> readFirstNames(String email) async => null;

  @override
  Future<void> writeFirstNames(String email, String firstNames) async {}
}

class _MockDishRepository extends Mock implements DishRepository;

/// Boots the app the way `main.dart` does: the session is known before the
/// first frame.
Future<ProviderContainer> _boot(WidgetTester tester, {Session? session}) async {
  final dishes = _MockDishRepository();
  when(dishes.fetchAll).thenAnswer((_) async => [_ajiaco]);
  final container = ProviderContainer.test(
    overrides: [
      sessionControllerProvider.overrideWith(
        () => _FakeSession(initial: session),
      ),
      tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
      dishRepositoryProvider.overrideWithValue(dishes),
    ],
  );
  await container.read(sessionControllerProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(child: const App()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

const _headline = 'Comida colombiana, sin afán.';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));

  testWidgets('a guest starts on the welcome', (tester) async {
    await _boot(tester);
    expect(find.text(_headline), findsOneWidget);
  });

  testWidgets('a stored session starts on Home', (tester) async {
    await _boot(tester, session: _session);
    expect(find.text('Ajiaco santafereño'), findsOneWidget);
  });

  testWidgets('logging in lands on Home', (tester) async {
    await _boot(tester);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(EditableText).at(0),
      'jorge@example.com',
    );
    await tester.enterText(find.byType(EditableText).at(1), 'secreta1');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Ajiaco santafereño'), findsOneWidget);
    expect(find.text(_headline), findsNothing);
  });

  testWidgets('logging out goes back to the welcome for good', (tester) async {
    final container = await _boot(tester, session: _session);
    await container.read(sessionControllerProvider.notifier).logout();
    await tester.pumpAndSettle();
    expect(find.text(_headline), findsOneWidget);

    final router = container.read(appRouterProvider);
    expect(router.stack.map((route) => route.name), ['AuthShellRoute']);
  });

  testWidgets('a rejected token ends on the welcome with a toast', (
    tester,
  ) async {
    final container = await _boot(tester, session: _session);
    container.read(sessionControllerProvider.notifier).onUnauthorized();
    await tester.pumpAndSettle();
    expect(find.text(_headline), findsOneWidget);
    expect(
      find.text('Tu sesión venció. Entra de nuevo para seguir.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('a guest cannot reach a private page', (tester) async {
    final guest = await _boot(tester);
    unawaited(guest.read(appRouterProvider).pushPath('/dish/a'));
    await tester.pumpAndSettle();
    expect(find.text(_headline), findsOneWidget);
  });

  testWidgets('a signed-in user cannot reach the auth pages', (tester) async {
    final member = await _boot(tester, session: _session);
    unawaited(member.read(appRouterProvider).pushPath('/auth/login'));
    await tester.pumpAndSettle();
    expect(find.text('Ajiaco santafereño'), findsOneWidget);
    expect(find.text('Hola otra vez.'), findsNothing);
  });

  testWidgets('English and dark mode reach every layer', (tester) async {
    // English is a deferred library, which loads outside the fake clock.
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await _boot(tester);
    expect(find.text('Colombian food, unhurried.'), findsOneWidget);
    final context = tester.element(find.text('Colombian food, unhurried.'));
    expect(MaterialLocalizations.of(context).closeButtonLabel, 'Close');
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
