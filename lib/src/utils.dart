/// A shorthand for the big annotated record for bounding bounds.
typedef BoundsRecord = ({
  double minLat,
  double minLon,
  double maxLat,
  double maxLon,
});

/// A cardinal direction for calculating an adjacent geohash.
/// See [adjacent].
enum Direction {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest,
}

/// Thrown when trying to calculate a geohash behind the 90° latitude.
class OutOfWorldBoundsException implements Exception {}

/// Thrown when batch geohash calculation returned too many geohashes.
class TooManyGeohashesException implements Exception {
  /// How many hashes were calculated, or planned to be calculated.
  /// This number is always over the given limit.
  final int count;

  TooManyGeohashesException(this.count);

  @override
  String toString() => 'Requested too many geohashes: $count';
}
