import 'package:ecoeats/app.dart';
import 'package:ecoeats/core/format/formatters.dart';
import 'package:ecoeats/core/session/session.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/core/session/token_store.dart';
import 'package:ecoeats/features/dishes/data/dish_repository.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'dish_fixtures.dart';

class FakeSession extends SessionController {
  new({this.initial});

  final Session? initial;

  @override
  Future<Session?> build() async => initial;

  @override
  Future<void> logout() async => state = const AsyncData(null);
}

class MemoryTokenStore implements TokenStore {
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

class MockDishRepository extends Mock implements DishRepository;

Session signedIn({String? firstNames = 'Jorge', DateTime? now}) => Session(
  token: 'jwt',
  userId: 'u1',
  email: 'jorge@example.com',
  firstNames: firstNames,
  expiresAt: (now ?? DateTime.now()).add(const Duration(hours: 20)),
);

/// Runs the real app, router included, over a fake session, a fake catalog
/// and a fixed clock, the way `main.dart` starts it.
Future<ProviderContainer> bootApp(
  WidgetTester tester, {
  Session? session,
  List<Dish>? dishes,
  DishRepository? repository,
  DateTime? now,
  AppLocale locale = AppLocale.es,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await initFormatters();
    await LocaleSettings.setLocale(locale);
  });
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

  final catalog = repository ?? MockDishRepository();
  if (repository == null) {
    when((catalog as MockDishRepository).fetchAll)
        .thenAnswer((_) async => dishes ?? sampleDishes);
  }
  final clock = now ?? DateTime(2026, 10, 24, 9);
  final container = ProviderContainer.test(
    // Failures stay visible: the app's own policy retries only transient
    // ones, and tests drive retries by hand.
    retry: (_, _) => null,
    overrides: [
      sessionControllerProvider.overrideWith(
        () => FakeSession(initial: session ?? signedIn(now: clock)),
      ),
      tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
      dishRepositoryProvider.overrideWithValue(catalog),
      clockProvider.overrideWithValue(() => clock),
    ],
  );
  await container.read(sessionControllerProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(child: const App()),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return container;
}
