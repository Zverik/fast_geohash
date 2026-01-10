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

  test('Neighbours', () {
    expect(geohash.neighbours(4), {
      Direction.northWest: 7,
      Direction.north: 5,
      Direction.northEast: 7,
      Direction.west: 6,
      Direction.east: 6,
    });

    expect(geohash.neighbours(8), {
      Direction.west: 13,
      Direction.east: 9,
      Direction.northWest: 15,
      Direction.north: 10,
      Direction.northEast: 11,
    });

    expect(geohash.neighbours(27), {
      Direction.northWest: 28,
      Direction.north: 30,
      Direction.northEast: 20,
      Direction.west: 25,
      Direction.east: 17,
      Direction.southWest: 24,
      Direction.south: 26,
      Direction.southEast: 16,
    });

    expect(geohash.neighbours(5437), {
      Direction.northWest: 5474,
      Direction.north: 5480,
      Direction.northEast: 5482,
      Direction.west: 5431,
      Direction.east: 5439,
      Direction.southWest: 5430,
      Direction.south: 5436,
      Direction.southEast: 5438,
    });
  });
}
