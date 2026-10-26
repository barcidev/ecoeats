import 'package:ecoeats/features/dishes/domain/image_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const unsplash =
      'https://images.unsplash.com/photo-1599655722738-ae7a40b0b994?w=600&fit=crop';

  test('Unsplash photos get the smallest bucket that covers the screen', () {
    final uri = Uri.parse(
      sizedImageUrl(unsplash, logicalWidth: 180, devicePixelRatio: 3),
    );
    expect(uri.queryParameters['w'], '800');
    expect(uri.queryParameters['q'], '75');
    expect(uri.queryParameters['auto'], 'format');
    expect(uri.queryParameters['fit'], 'crop');
    expect(uri.path, '/photo-1599655722738-ae7a40b0b994');
  });

  test('buckets go from 400 to 1600 px', () {
    String width(double logical, double ratio) => Uri.parse(
      sizedImageUrl(unsplash, logicalWidth: logical, devicePixelRatio: ratio),
    ).queryParameters['w']!;
    expect(width(100, 2), '400');
    expect(width(400, 2), '800');
    expect(width(390, 3), '1200');
    expect(width(430, 3), '1600');
    expect(width(1200, 3), '1600');
  });

  test('presigned and foreign URLs stay as they are', () {
    const presigned =
        'https://images.unsplash.com/photo-1?X-Amz-Signature=abc&X-Amz-Expires=86400';
    const s3 = 'https://storage.example.com/ecoeats/dishes/1.jpg?w=600';
    expect(
      sizedImageUrl(presigned, logicalWidth: 200, devicePixelRatio: 3),
      presigned,
    );
    expect(sizedImageUrl(s3, logicalWidth: 200, devicePixelRatio: 3), s3);
    expect(sizedImageUrl('', logicalWidth: 200, devicePixelRatio: 3), '');
  });
}
