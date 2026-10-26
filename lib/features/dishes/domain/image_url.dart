const _buckets = [400, 800, 1200, 1600];

/// Asks Unsplash for a photo as wide as it will be drawn, rounded up to a few
/// fixed widths so the cache shares files between screens.
///
/// Presigned URLs are signed as they are (changing a parameter breaks them)
/// and other hosts ignore these parameters, so both come back untouched.
String sizedImageUrl(
  String url, {
  required double logicalWidth,
  required double devicePixelRatio,
}) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != 'images.unsplash.com') return url;
  final presigned = uri.queryParameters.keys.any(
    (key) => key.toLowerCase().startsWith('x-amz-'),
  );
  if (presigned) return url;

  final needed = logicalWidth * devicePixelRatio;
  final width = _buckets.firstWhere(
    (bucket) => bucket >= needed,
    orElse: () => _buckets.last,
  );
  return uri
      .replace(
        queryParameters: {
          ...uri.queryParameters,
          'w': '$width',
          'q': '75',
          'auto': 'format',
        },
      )
      .toString();
}
