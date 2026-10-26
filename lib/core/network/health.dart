import 'package:dio/dio.dart';

/// Wakes the API while the session restores, so the first real request is not
/// the slow one.
///
/// The answer is ignored on purpose: production reports `503 DOWN` because of
/// its S3 bucket even when every endpoint the app uses works.
Future<void> warmUp(Dio dio) async {
  try {
    await dio.get<Object?>(
      '/health',
      options: Options(validateStatus: (_) => true),
    );
  } on DioException {
    // A cold or unreachable API shows up later, in the request that matters.
  }
}
