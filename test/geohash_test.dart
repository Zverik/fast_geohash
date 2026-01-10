import 'package:fast_geohash/fast_geohash_str.dart';
import 'package:test/test.dart';

String encode(double lat, double lon, int precision) =>
    geohash.encode(lat, lon, precision);

({double lat, double lon}) decode(String g) => geohash.decode(g);

void main() {
  test('Encode', () {
    expect(encode(42.6, -5.6, 12), equals('ezs42e44yx96'));
    expect(encode(42.6, -5.6, 5), equals('ezs42'));
    expect(encode(0.0, -5.6, 5), equals('ebh00'));
    expect(encode(-15.5, 167.5, 1), equals('r'));
    expect(encode(30.23710012435913, -97.79499292373657, 12), "9v6kn87zgs00");
    expect(encode(32, 117, 3), equals('wte'));
  });

  test('Encode precision errors', () {
    expect(() => encode(-15.5, 167.5, 0), throwsArgumentError);
    expect(() => encode(30.23710012435913, -97.79499292373657, 20),
        throwsArgumentError);
  });

  test('Encode wrapping', () {
    expect(() => encode(-111, 45, 5), throwsArgumentError);
    expect(encode(45, 195, 8), equals(encode(45, -165, 8)));
    expect(encode(45, -195, 8), equals(encode(45, 165, 8)));
  });

  test('Decode', () {
    final ll = decode('ww8p1r4t8');
    expect(ll.lat, closeTo(37.8324, 1e-4));
    expect(ll.lon, closeTo(112.5584, 1e-4));

    expect(decode('ebh00'), equals(decode('EBH00')));
  });

  test('Decode errors', () {
    expect(() => decode(''), throwsArgumentError);
    expect(() => decode('abcdef'), throwsArgumentError);
  });
}
