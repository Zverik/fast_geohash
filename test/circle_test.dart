import 'package:fast_geohash/fast_geohash_str.dart';
import 'package:test/test.dart';

void main() {
  test('Radius zero', () {
    expect(
        geohash.forCircle(34, -140.0, 0, 5), [geohash.encode(34, -140.0, 5)]);
    expect(geohash.forCircle(89, 14, 0, 4, latLimit: 80),
        [geohash.encode(89, 14, 4)]);
  });

  test('Circle errors', () {
    expect(() => geohash.forCircle(10, 10, -5, 1), throwsArgumentError);
  });
}
