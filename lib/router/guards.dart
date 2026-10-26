import 'dart:async';

import 'package:auto_route/auto_route.dart';

/// Keeps private pages for signed-in users.
///
/// A guest is redirected to the welcome until the redirect resolves: when the
/// session appears, the router re-evaluates this guard, it lets the original
/// navigation through and the welcome leaves the stack. The redirect replaces
/// the page, so back never returns to it after a logout.
class AuthGuard extends AutoRouteGuard {
  new({required this.isSignedIn, required this.welcome});

  final bool Function() isSignedIn;
  final PageRouteInfo welcome;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (isSignedIn()) {
      resolver.next();
    } else {
      resolver.redirectUntil(welcome, replace: true);
    }
  }
}

/// Keeps signed-in users out of the auth pages.
class GuestGuard extends AutoRouteGuard {
  new({required this.isSignedIn, required this.home});

  final bool Function() isSignedIn;
  final PageRouteInfo home;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (!isSignedIn()) {
      resolver.next();
      return;
    }
    resolver.next(false);
    // A re-evaluation after login is already on its way to Home through the
    // AuthGuard's pending redirect; navigating again would race it.
    if (!resolver.isReevaluating) unawaited(router.replaceAll([home]));
  }
}
