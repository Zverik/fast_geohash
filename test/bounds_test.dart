import 'package:fast_geohash/fast_geohash_str.dart';
import 'package:test/test.dart';

void main() {
  test('Point bounds', () {
    expect(geohash.forBounds(42.6, -5.6, 42.6, -5.6, 5), ['ezs42']);
  });

  test('Some plain bounds', () {
    final c1 = geohash.decode('tvh');
    final c2 = geohash.decode('tuf');
    expect(geohash.forBounds(c1.lat, c1.lon, c2.lat, c2.lon, 3).toSet(),
        {'tuf', 'tug', 'tuu', 'tv4', 'tv5', 'tvh'});
  });

  test('Too many cells', () {
    expect(() => geohash.forBounds(-80, -100, 80, 100, 4),
        throwsA(isA<TooManyGeohashesException>()));
    expect(() => geohash.forBounds(-80, -130, 80, 130, 1, limit: 20),
        throwsA(isA<TooManyGeohashesException>()));
  });
}
