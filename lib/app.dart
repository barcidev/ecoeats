import 'dart:async';

import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/core/session/sign_in_hold.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/toast.dart';
import 'package:ecoeats/features/profile/application/theme_mode_controller.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:ecoeats/router/app_router.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class App extends ConsumerWidget {
  const new({super.key});

  // A context below the app's own overlay, so app-wide toasts outlive the
  // route changes that often come with them (an expired session, for one).
  static final GlobalKey _overlayAnchor = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    bool signedIn(AsyncValue<Object?> session) => session.value != null;

    // The one place that moves the user when a session starts or ends.
    ref
      ..listen(sessionControllerProvider.select(signedIn), (previous, next) {
        if (previous == next) return;
        final hold = ref.read(signInHoldProvider);
        unawaited(() async {
          // A sign-in screen may still be celebrating; Home waits for it.
          if (next) await hold.wait();
          await router.replaceAll([
            if (next) const HomeRoute() else const AuthShellRoute(),
          ]);
        }());
      })
      ..listen(sessionExpiredProvider, (_, _) {
        final anchor = _overlayAnchor.currentContext;
        if (anchor == null) return;
        Toast.show(anchor, anchor.t.errors.sessionExpired, tone: .alert);
      });

    return MaterialApp.router(
      title: 'EcoEats',
      debugShowCheckedModeBanner: false,
      theme: ecoTheme(.light),
      darkTheme: ecoTheme(.dark),
      themeMode: ref.watch(themeModeControllerProvider).value ?? .system,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router.config(
        deepLinkBuilder: (link) => startingLink(
          link,
          signedIn: signedIn(ref.read(sessionControllerProvider)),
        ),
      ),
      builder: (context, child) => _SystemBars(
        child: _AppOverlay(anchor: _overlayAnchor, child: child!),
      ),
    );
  }
}

/// An overlay above the navigator for app-wide toasts. Its single entry is
/// rebuilt with each new child: `Overlay` reads its entries only once.
class _AppOverlay extends StatefulWidget {
  const new({required this.anchor, required this.child});

  final GlobalKey anchor;
  final Widget child;

  @override
  State<_AppOverlay> createState() => _AppOverlayState();
}

class _AppOverlayState extends State<_AppOverlay> {
  late final _entry = OverlayEntry(
    builder: (_) => KeyedSubtree(key: widget.anchor, child: widget.child),
  );

  @override
  void didUpdateWidget(_AppOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}

/// Edge to edge: transparent bars whose icons follow the theme.
class _SystemBars extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == .light;
    final style = light
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
