import 'dart:math' show sin, cos, acos, pi, min;

import 'package:fast_geohash/fast_geohash_str.dart';
import 'package:test/test.dart';

double distance(double lat, double lon, double lat2, double lon2) {
  const kEarthRadius = 6371008; // mean radius
  final rLat = lat / 180 * pi;
  final toLat = lat2 / 180 * pi;
  final dx = (lon2 - lon) / 180 * pi;
  return acos(sin(rLat) * sin(toLat) + cos(rLat) * cos(toLat) * cos(dx)) *
      kEarthRadius;
}

double geohashDistance(double lat, double lon, String hash) {
  final b = geohash.bounds(hash);
  double r1 = distance(lat, lon, b.minLat, b.minLon);
  r1 = min(r1, distance(lat, lon, b.maxLat, b.minLon));
  r1 = min(r1, distance(lat, lon, b.minLat, b.maxLon));
  r1 = min(r1, distance(lat, lon, b.maxLat, b.maxLon));
  return r1;
}

void testBig(double lat, double lon, double radius, int precision) {
  final hashes = geohash.forCircle(lat, lon, radius, precision, precise: true);
  final box = geohash.forCircle(lat, lon, radius, precision, asBox: true);
  expect(hashes.length, equals(hashes.toSet().length),
      reason: 'no duplicates in circle');
  expect(hashes.length, lessThan(box.length),
      reason: 'circle is less than box');
  expect(hashes.every((h) => box.contains(h)), isTrue,
      reason: 'box contains circle');
  expect(hashes.where((h) => geohashDistance(lat, lon, h) > radius), isEmpty,
      reason: 'no hashes farther than radius');
}

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

  test('At a corner', () {
    expect(geohash.forCircle(30.915527, 81.540527, 10000, 4), hasLength(4));
  });

  test('1, 4, 9', () {
    expect(geohash.forCircle(30.234375, 80.859375, 60000, 3), hasLength(1));
    expect(geohash.forCircle(30.234375, 80.859375, 70000, 3), hasLength(3));
    expect(geohash.forCircle(30.234375, 80.859375, 80000, 3), hasLength(5));
    expect(geohash.forCircle(30.234375, 80.859375, 130000, 3), hasLength(9));
  });

  test('Really big', () {
    testBig(30.234, 70.5543, 1000, 7);
  });
}
