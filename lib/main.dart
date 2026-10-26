import 'dart:async';

import 'package:ecoeats/app.dart';
import 'package:ecoeats/core/format/formatters.dart';
import 'package:ecoeats/core/network/dio_provider.dart';
import 'package:ecoeats/core/network/health.dart';
import 'package:ecoeats/core/network/retry.dart';
import 'package:ecoeats/core/session/session_controller.dart';
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

  // The splash stays up until the stored session is known, so the first frame
  // is already the right screen instead of a flash of the welcome.
  await container
      .read(sessionControllerProvider.future)
      .then<void>((_) {}, onError: (_) {});
  FlutterNativeSplash.remove();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(child: const App()),
    ),
  );
}
