import 'dart:math' show pow;

import 'package:fast_geohash/fast_geohash_int.dart';
import 'package:test/test.dart';

void main() {
  test('Encode', () {
    final enc = geohash.encode(42.6, -5.6, 12);
    expect(enc, equals(5887));
    expect(geohash.precision(enc), equals(12));

    expect(geohash.encode(37.8324, 112.5584, 52),
        equals(4064984913515641 + pow(2, 52)));
  });

  test('Decode', () {
    final ll = geohash.decode((4064984913515641 + pow(2, 52)).toInt());
    expect(ll.lat, closeTo(37.8324, 1e-4));
    expect(ll.lon, closeTo(112.5584, 1e-4));
  });

  test('Decode-encode roundtrip', () {
    final values = [2, 5, 12, 543, 99473, 98235678, 34234, 123, 5454];
    for (final v in values) {
      final ll = geohash.decode(v);
      expect(geohash.encode(ll.lat, ll.lon, geohash.precision(v)), equals(v),
          reason: v.toString());
    }
  });
}
