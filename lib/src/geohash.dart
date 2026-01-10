// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math' show cos, pi, acos, sin;
import 'utils.dart';

abstract class GeohashBase<T> {
  const GeohashBase();

  /// Encode a latitude and longitude to a geohash string of given
  /// [precision] (i.e. bit length).
  T encode(double lat, double lon, int precision);

  /// Returns a bounding box for a [geohash] as an annotated record.
  ///
  /// Note that for the same geohash precision, box dimensions in degrees
  /// are all the same, regardless of latitude. Meaning, you can calculate
  /// dimensions of adjacent boxes without having to calculate their geohashes.
  BoundsRecord bounds(T geohash);

  /// Returns the precision of [geohash].
  int precision(T geohash);

  /// The maximum precision allowed for this method of hashing.
  int get maxPrecision;

  /// Returns a single neighbour of the given [geohash] in the [direction].
  /// The default implementation relies on [bounds] and [encode] and may be
  /// slower than a custom algorithm.
  T adjacent(T geohash, Direction direction) {
    final b = bounds(geohash);
    (double, double) steps;
    switch (direction) {
      case Direction.north:
        steps = (1, 0);
      case Direction.northEast:
        steps = (1, 1);
      case Direction.northWest:
        steps = (1, -1);
      case Direction.east:
        steps = (0, 1);
      case Direction.west:
        steps = (0, -1);
      case Direction.southEast:
        steps = (-1, 1);
      case Direction.south:
        steps = (-1, 0);
      case Direction.southWest:
        steps = (-1, -1);
    }
    try {
      return encode(
        (b.minLat + b.maxLat) / 2 + steps.$1 * (b.maxLat - b.minLat),
        (b.minLon + b.maxLon) / 2 + steps.$2 * (b.maxLon - b.minLon),
        precision(geohash),
      );
    } on ArgumentError {
      throw OutOfWorldBoundsException();
    }
  }

  /// Decodes a [geohash] to a (latitude, longitude) record. The result
  /// is the exact center of the bounding box for the geohash, returned
  /// by [bounds] function.
  ({double lat, double lon}) decode(T geohash) {
    final b = bounds(geohash);
    return (lat: (b.minLat + b.maxLat) / 2, lon: (b.minLon + b.maxLon) / 2);
  }

  /// Returns all eight neighbours for the given [geohash] string. It does
  /// call [adjacent] eight times, so when you don't need every value, maybe
  /// you are better using that function. Although it's a little bit more
  /// efficient by not calculating an adjacent code twice for diagonal directions.
  ///
  /// When near the northern or southern world boundary, this function can
  /// return just five values.
  Map<Direction, T> neighbours(T geohash) {
    T? north;
    try {
      north = adjacent(geohash, Direction.north);
    } on OutOfWorldBoundsException {
      // keep null
    }

    T? south;
    try {
      south = adjacent(geohash, Direction.south);
    } on OutOfWorldBoundsException {
      // keep null
    }

    return {
      if (north != null) Direction.northWest: adjacent(north, Direction.west),
      if (north != null) Direction.north: north,
      if (north != null) Direction.northEast: adjacent(north, Direction.east),
      Direction.west: adjacent(geohash, Direction.west),
      Direction.east: adjacent(geohash, Direction.east),
      if (south != null) Direction.southWest: adjacent(south, Direction.west),
      if (south != null) Direction.south: south,
      if (south != null) Direction.southEast: adjacent(south, Direction.east),
    };
  }

  /// Returns a list of geohashes for the given bounding box. Those geohashes
  /// cover all four corners and everything inbetween. Adjust the [limit] to throw
  /// a [TooManyGeohashesException] when the bounds cover too many cells.
  List<T> forBounds(
    double minLat,
    double minLon,
    double maxLat,
    double maxLon,
    int precision, {
    int limit = 10000,
  }) {
    if (precision > maxPrecision || precision < 1) {
      throw ArgumentError('Precision should be between 1 and $maxPrecision');
    }

    if (minLat > maxLat) {
      (minLat, maxLat) = (maxLat, minLat);
    }

    if (minLat < -90 || maxLat > 90) {
      throw ArgumentError('Latitudes are out of bounds: $minLat, $maxLat');
    }

    if (minLon > maxLon) {
      (minLon, maxLon) = (maxLon, minLon);
    }

    while (minLon < -180) {
      minLon += 360;
      maxLon += 360;
    }
    while (minLon > 180) {
      minLon -= 360;
      maxLon -= 360;
    }

    if (maxLon > 180) {
      if (maxLon > minLon + 360) {
        // Since we're covering the globe, let's make it official.
        minLon = -180;
        maxLon = 180;
      } else {
        // Handle cross-180° parts
        return forBounds(minLat, minLon, maxLat, 180, precision) +
            forBounds(minLat, 0, maxLat, maxLon - 360, precision);
      }
    }

    // At this points latitudes and longitudes are ordered
    // and inside the world boundaries.

    final southWestHash = encode(minLat, minLon, precision);
    final northEastHash = encode(maxLat, maxLon, precision);

    final southWestBounds = bounds(southWestHash);
    final northEastBounds = bounds(northEastHash);

    final dLon = northEastBounds.maxLon - northEastBounds.minLon;
    final dLat = northEastBounds.maxLat - northEastBounds.minLat;
    final count = ((northEastBounds.maxLon - southWestBounds.minLon) /
            dLon *
            (northEastBounds.maxLat - southWestBounds.minLat) /
            dLat)
        .ceil();
    if (count > limit) {
      throw TooManyGeohashesException(count);
    }

    // The current implementation uses adjacent geohashes calculation.
    // The benchmarking has shown that using instead coordinate decoding
    // and encoding is almost twice as slow.

    final result = <T>[];

    // First prepare the top row.
    T topLeftHash = encode(maxLat, minLon, precision);
    final top = <T>[topLeftHash];
    while (topLeftHash != northEastHash) {
      topLeftHash = adjacent(topLeftHash, Direction.east);
      top.add(topLeftHash);
    }
    result.addAll(top);

    // Now start with bottom left and go bottom-top, column by column,
    // until we encounter the final top element.
    T geohashX = southWestHash;
    for (int i = 0; i < top.length; i++) {
      T geohash = geohashX;
      while (geohash != top[i]) {
        result.add(geohash);
        geohash = adjacent(geohash, Direction.north);
      }
      geohashX = adjacent(geohashX, Direction.east);
    }

    return result;
  }

  static const _kEarthRadius = 6371008; // mean radius

  /// Returns a list of geohashes for a circle with a given centre location
  /// and a radius in meters. Assumes the latitude and longitude to be
  /// in EPSG:4326 projection. Will trim the circle if it goes outside the
  /// EPSG:3857 projection boundaries.
  ///
  /// Note that this by default uses an equirectangular approximation for
  /// distances. It works well on distances under a couple hundred kilometers.
  /// If you need higher precision and bigger distances, set [precise]
  /// to true. It will slow down processing approximately by 2.75 times
  /// (still a fraction of a millisecond).
  ///
  /// Keep in mind that a notion of a circle on a sphere is
  /// a bit complex, so the result can still be incorrect.
  ///
  /// Adjust the [limit] to throw [TooManyGeohashesException] when there
  /// are too many cells covered. To guard against geohashes expanding
  /// around poles, set [latLimit] to cut off processing behind those latitudes.
  List<T> forCircle(double lat, double lon, double radius, int precision,
      {int limit = 10000, int latLimit = 86, bool precise = false}) {
    if (precision > maxPrecision || precision < 1) {
      throw ArgumentError('Precision should be between 1 and $maxPrecision');
    }

    if (radius < 0) {
      throw ArgumentError('Radius should be a positive number');
    }

    if (latLimit < 80 || latLimit > 90) {
      throw ArgumentError('Latitude limit should be between 80° and 90°.');
    }

    if (lat < -90 || lat > 90) {
      throw ArgumentError('Latitude is out of bounds: $lat');
    }

    while (lon < -180) lon += 360;
    while (lon > 180) lon -= 360;

    final rRadius = radius / _kEarthRadius;
    final rRadiusSq = rRadius * rRadius;
    final rLat = lat / 180 * pi;
    final rLon = lon / 180 * pi;
    final rLatLimit = latLimit / 180 * pi;
    final cosLat = cos(rLat);

    final centre = encode(lat, lon, precision);
    final b = bounds(centre); // to not re-encode every geohash
    final dLat = (b.maxLat - b.minLat) / 180 * pi;
    final dLon = (b.maxLon - b.minLon) / 180 * pi;
    final rLeftLon = b.minLon / 180 * pi;
    final rRightLon = b.maxLon / 180 * pi;
    final result = <T>[centre];

    /// We don't start this entire thing when we're already over the limit.
    if (lat < -latLimit || lat > latLimit) return result;

    /// Calculates distance **in radians** from the circle centre to the given
    /// location (also in radians). Returns true if the location is strictly
    /// inside the radius.
    bool inside(double toLat, double toLon) {
      final dy = toLat - rLat;
      if (precise) {
        return acos(sin(rLon) * sin(toLon) + cos(rLon) * cos(toLon) * cos(dy)) <
            rRadius;
      } else {
        final dx = (toLon - rLon) * cosLat;
        return dx * dx + dy * dy < rRadiusSq;
      }
    }

    /// Starting with the centre geohash (not added to the result), step left
    /// or right while the distance to the far corner of the geohash bounds
    /// (baseLat, sideLon) is inside the radius. All angles are in radians.
    void traverseRow(T geohash, double baseLat) {
      // First go left.
      double sideLon = rLeftLon;
      T current = geohash;
      while (inside(baseLat, sideLon) && sideLon > rLon - pi) {
        sideLon -= dLon;
        current = adjacent(current, Direction.west);
        result.add(current);
      }

      // And then go right.
      sideLon = rRightLon;
      current = geohash;
      while (inside(baseLat, sideLon) && sideLon < rLon + pi) {
        sideLon += dLon;
        current = adjacent(current, Direction.east);
        result.add(current);
      }

      if (result.length > limit) {
        throw TooManyGeohashesException(result.length);
      }
    }

    // Left and right.
    traverseRow(centre, rLat);

    // Go up while we can and also venture left and right.
    double baseLat = b.maxLat / 180 * pi;
    T current = centre;
    while (inside(baseLat, rLon) && baseLat < rLatLimit) {
      baseLat += dLat;
      current = adjacent(current, Direction.north);
      traverseRow(current, baseLat);
    }

    // And now go down doing the same thing.
    baseLat = b.minLat / 180 * pi;
    current = centre;
    while (inside(baseLat, rLon) && baseLat > -rLatLimit) {
      baseLat -= dLat;
      current = adjacent(current, Direction.south);
      traverseRow(current, baseLat);
    }

    return result;
  }
}
