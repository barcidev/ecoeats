import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/router/guards.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockResolver extends Mock implements NavigationResolver;

class _MockRouter extends Mock implements StackRouter;

const _welcome = PageRouteInfo<void>('AuthShellRoute');
const _home = PageRouteInfo<void>('HomeRoute');

void main() {
  late _MockResolver resolver;
  late _MockRouter router;

  setUpAll(() {
    registerFallbackValue(_home);
    registerFallbackValue(<PageRouteInfo>[]);
  });

  setUp(() {
    resolver = _MockResolver();
    router = _MockRouter();
    when(() => resolver.isReevaluating).thenReturn(false);
    when(() => router.replaceAll(any())).thenAnswer((_) async {});
  });

  group('AuthGuard', () {
    test('lets a signed-in user through', () {
      AuthGuard(
        isSignedIn: () => true,
        welcome: _welcome,
      ).onNavigation(resolver, router);
      verify(() => resolver.next()).called(1);
      verifyNever(() => resolver.redirectUntil(any()));
    });

    test('sends a guest to the welcome in place of the page', () {
      AuthGuard(
        isSignedIn: () => false,
        welcome: _welcome,
      ).onNavigation(resolver, router);
      verify(() => resolver.redirectUntil(_welcome, replace: true)).called(1);
      verifyNever(() => resolver.next());
    });
  });

  group('GuestGuard', () {
    test('lets a guest through', () {
      GuestGuard(
        isSignedIn: () => false,
        home: _home,
      ).onNavigation(resolver, router);
      verify(() => resolver.next()).called(1);
    });

    test('keeps a signed-in user on Home', () {
      GuestGuard(
        isSignedIn: () => true,
        home: _home,
      ).onNavigation(resolver, router);
      verify(() => resolver.next(false)).called(1);
      verify(() => router.replaceAll([_home])).called(1);
    });

    test('while re-evaluating it only steps aside', () {
      when(() => resolver.isReevaluating).thenReturn(true);
      GuestGuard(
        isSignedIn: () => true,
        home: _home,
      ).onNavigation(resolver, router);
      verify(() => resolver.next(false)).called(1);
      verifyNever(() => router.replaceAll(any()));
    });
  });
}
