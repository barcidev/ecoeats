import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/gallery/design_gallery_page.dart';
import 'package:ecoeats/features/auth/presentation/auth_pages.dart';
import 'package:ecoeats/features/auth/presentation/auth_transitions.dart';
import 'package:ecoeats/features/discover/presentation/discover_page.dart';
import 'package:ecoeats/features/discover/presentation/discover_route.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/features/dishes/presentation/detail/dish_detail_page.dart';
import 'package:ecoeats/features/dishes/presentation/dish_transitions.dart';
import 'package:ecoeats/features/dishes/presentation/home/home_page.dart';
import 'package:ecoeats/router/guards.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';
part 'app_router.gr.dart';

@Riverpod(keepAlive: true)
AppRouter appRouter(Ref ref) {
  bool isSignedIn() => ref.read(sessionControllerProvider).value != null;
  return AppRouter(
    authGuard: AuthGuard(isSignedIn: isSignedIn),
    guestGuard: GuestGuard(isSignedIn: isSignedIn),
  );
}

/// Where the app opens: the requested link for a signed-in user (Home if it
/// points at the auth pages), the welcome for a guest.
DeepLink startingLink(PlatformDeepLink link, {required bool signedIn}) {
  if (!signedIn) return const DeepLink([AuthShellRoute()]);
  if (!link.isValid || link.path.startsWith('/auth')) {
    return const DeepLink([HomeRoute()]);
  }
  return link;
}

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  new({required this.authGuard, required this.guestGuard});

  final AuthGuard authGuard;
  final GuestGuard guestGuard;

  @override
  List<AutoRoute> get routes => [
    CustomRoute<void>(
      page: HomeRoute.page,
      path: '/',
      initial: true,
      guards: [authGuard],
      transitionsBuilder: dishFadeTransition,
    ),
    // Not opaque, so Home stays painted behind while the detail is dragged
    // down to close.
    CustomRoute<void>(
      page: DishDetailRoute.page,
      path: '/dish/:id',
      guards: [authGuard],
      opaque: false,
      transitionsBuilder: dishFadeTransition,
    ),
    CustomRoute<void>(
      page: DiscoverRoute.page,
      path: '/discover',
      guards: [authGuard],
      customRouteBuilder: _discoverRoute,
    ),
    CustomRoute<void>(
      page: AuthShellRoute.page,
      path: '/auth',
      guards: [guestGuard],
      transitionsBuilder: TransitionsBuilders.fadeIn,
      children: [
        CustomRoute<void>(
          page: WelcomeRoute.page,
          path: '',
          transitionsBuilder: authPanelTransition,
        ),
        CustomRoute<void>(
          page: LoginRoute.page,
          path: 'login',
          transitionsBuilder: authPanelTransition,
        ),
        CustomRoute<void>(
          page: RegisterRoute.page,
          path: 'register',
          transitionsBuilder: authPanelTransition,
        ),
        CustomRoute<void>(
          page: RecoverRoute.page,
          path: 'recover',
          transitionsBuilder: authPanelTransition,
        ),
      ],
    ),
    if (kDebugMode) AutoRoute(page: DesignGalleryRoute.page, path: '/_gallery'),
  ];
}

Route<T> _discoverRoute<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page,
) {
  final args = page.routeData.argsAs<DiscoverRouteArgs>(
    orElse: DiscoverRouteArgs.new,
  );
  return revealRoute<T>(
    settings: page,
    child: child,
    origin: args.revealOrigin,
  );
}
