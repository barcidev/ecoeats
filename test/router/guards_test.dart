import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/router/guards.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockResolver extends Mock implements NavigationResolver;

class _MockRouter extends Mock implements StackRouter;

void main() {
  late _MockResolver resolver;
  late _MockRouter router;

  setUp(() {
    resolver = _MockResolver();
    router = _MockRouter();
  });

  group('AuthGuard', () {
    test('lets a signed-in user through', () {
      AuthGuard(isSignedIn: () => true).onNavigation(resolver, router);
      verify(() => resolver.next()).called(1);
    });

    test('refuses a guest without navigating elsewhere', () {
      AuthGuard(isSignedIn: () => false).onNavigation(resolver, router);
      verify(() => resolver.next(false)).called(1);
      verifyZeroInteractions(router);
    });
  });

  group('GuestGuard', () {
    test('lets a guest through', () {
      GuestGuard(isSignedIn: () => false).onNavigation(resolver, router);
      verify(() => resolver.next()).called(1);
    });

    test('refuses a signed-in user without navigating elsewhere', () {
      GuestGuard(isSignedIn: () => true).onNavigation(resolver, router);
      verify(() => resolver.next(false)).called(1);
      verifyZeroInteractions(router);
    });
  });
}
