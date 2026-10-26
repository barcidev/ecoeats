import 'package:auto_route/auto_route.dart';

// Where a session change sends the user is decided in one place, the app's
// session listener (and the starting link at launch). The guards only refuse
// what does not fit the current session, so no two navigations race.

/// Keeps private pages for signed-in users.
class AuthGuard extends AutoRouteGuard {
  new({required this.isSignedIn});

  final bool Function() isSignedIn;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) =>
      resolver.next(isSignedIn());
}

/// Keeps signed-in users out of the auth pages.
class GuestGuard extends AutoRouteGuard {
  new({required this.isSignedIn});

  final bool Function() isSignedIn;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) =>
      resolver.next(!isSignedIn());
}
