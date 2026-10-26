import 'dart:async';

import 'package:ecoeats/app.dart';
import 'package:ecoeats/core/format/formatters.dart';
import 'package:ecoeats/core/network/dio_provider.dart';
import 'package:ecoeats/core/network/health.dart';
import 'package:ecoeats/core/network/retry.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/features/profile/application/locale_controller.dart';
import 'package:ecoeats/features/profile/application/theme_mode_controller.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await initFormatters();
  await LocaleSettings.useDeviceLocale();

  final container = ProviderContainer(retry: retryPolicy);
  unawaited(warmUp(container.read(dioProvider)));

  // The splash stays up until the stored session, appearance and language are
  // known, so the first frame is already the right screen in the right theme
  // and language. Without stored choices, both follow the device.
  await Future.wait([
    container.read(sessionControllerProvider.future),
    container.read(themeModeControllerProvider.future),
    container.read(localeControllerProvider.future),
  ]).then<void>((_) {}, onError: (_) {});
  FlutterNativeSplash.remove();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(child: const App()),
    ),
  );
}
