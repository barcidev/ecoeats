import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock.g.dart';

typedef Clock = DateTime Function();

/// The current time behind every auth deadline; tests override it so a
/// countdown never has to wait.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => DateTime.now;
