import 'package:fast_geohash/src/geohash_str.dart';
import 'package:test/test.dart';

void main() {
  test('Point bounds', () {
    expect(forBounds(42.6, -5.6, 42.6, -5.6, 5), ['ezs42']);
  });

  test('Some plain bounds', () {
    final c1 = decode('tvh');
    final c2 = decode('tuf');
    expect(
        forBounds(c1.lat, c1.lon, c2.lat, c2.lon, 3).toSet(),
        {'tuf', 'tug', 'tuu', 'tv4', 'tv5', 'tvh'});
  });

  test('Too many cells', () {
    expect(() => forBounds(-80, -100, 80, 100, 4),
        throwsA(isA<TooManyGeohashesException>()));
    expect(() => forBounds(-80, -130, 80, 130, 1, limit: 20),
        throwsA(isA<TooManyGeohashesException>()));
  });
}
