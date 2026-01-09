import 'dart:math' show cos, pi, Random, max, min;

import 'package:benchmarking/benchmarking.dart';

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

class TooManyGeohashesException implements Exception {
  final int count;

  TooManyGeohashesException(this.count);

  @override
  String toString() => 'Requested too many geohashes: $count';
}

const _kBase32 = '0123456789bcdefghjkmnpqrstuvwxyz';

final _kCodeUnitToInt = {
  for (final c in _kBase32.codeUnits.asMap().entries) c.value: c.key,
};

const _kNeighbours = {
  Direction.north: [
    'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
    'bc01fg45238967deuvhjyznpkmstqrwx',
  ],
  Direction.south: [
    '14365h7k9dcfesgujnmqp0r2twvyx8zb',
    '238967debc01fg45kmstqrwxuvhjyznp',
  ],
  Direction.east: [
    'bc01fg45238967deuvhjyznpkmstqrwx',
    'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
  ],
  Direction.west: [
    '238967debc01fg45kmstqrwxuvhjyznp',
    '14365h7k9dcfesgujnmqp0r2twvyx8zb',
  ],
};

const _kBorders = {
  Direction.north: ['prxz', 'bcfguvyz'],
  Direction.south: ['028b', '0145hjnp'],
  Direction.east: ['bcfguvyz', 'prxz'],
  Direction.west: ['0145hjnp', '028b'],
};

// _kBase32[_kNeighbours[direction]![type].indexOf(last)];
final _kNeighbourUnits = <Direction, List<Map<int, String>>>{
  for (final direction in _kNeighbours.keys)
    direction: [
      for (int i = 0; i < 2; i++)
        {
          for (final unit
              in _kNeighbours[direction]![i].codeUnits.asMap().entries)
            unit.value: _kBase32[unit.key],
        }
    ],
};

final _kBorderUnits = {
  for (final direction in _kBorders.keys)
    direction: [
      for (int i = 0; i < 2; i++) _kBorders[direction]![i].codeUnits.toSet(),
    ],
};

/// Encode a latitude and longitude to a geohash string of given
/// [precision] (i.e. character length). To get a rough estimation
/// on the required precision, the Movable Type blog offers this table
/// ("note that the cell width reduces moving away from the equator"):
///
/// * Geohash length 	Cell width 	Cell height
/// * 1 	≤ 5,000km 	× 	5,000km
/// * 2 	≤ 1,250km 	× 	625km
/// * 3 	≤ 156km 	× 	156km
/// * 4 	≤ 39.1km 	× 	19.5km
/// * 5 	≤ 4.89km 	× 	4.89km
/// * 6 	≤ 1.22km 	× 	0.61km
/// * 7 	≤ 153m 	× 	153m
/// * 8 	≤ 38.2m 	× 	19.1m
/// * 9 	≤ 4.77m 	× 	4.77m
/// * 10 	≤ 1.19m 	× 	0.596m
/// * 11 	≤ 149mm 	× 	149mm
/// * 12 	≤ 37.2mm 	× 	18.6mm
String encode(double lat, double lon, int precision) {
  if (precision > 12 || precision < 1) {
    throw ArgumentError('Precision should be between 1 and 12');
  }

  if (lat < -90 || lat > 90) {
    throw ArgumentError('Latitude is out of bounds: $lat');
  }

  while (lon < -180) lon += 360;
  while (lon > 180) lon -= 360;

  int idx = 0;
  int bit = 0;
  bool evenBit = true;
  final geohash = StringBuffer();

  double minLat = -90;
  double maxLat = 90;
  double minLon = -180;
  double maxLon = 180;

  while (geohash.length < precision) {
    idx <<= 1;
    if (evenBit) {
      final midLon = (minLon + maxLon) / 2;
      if (lon >= midLon) {
        idx |= 1;
        minLon = midLon;
      } else {
        maxLon = midLon;
      }
    } else {
      final midLat = (minLat + maxLat) / 2;
      if (lat >= midLat) {
        idx |= 1;
        minLat = midLat;
      } else {
        maxLat = midLat;
      }
    }

    evenBit = !evenBit;
    bit += 1;

    if (bit == 5) {
      geohash.write(_kBase32[idx]);
      bit = 0;
      idx = 0;
    }
  }

  return geohash.toString();
}

({double lat, double lon}) decode(String geohash) {
  final b = bounds(geohash);
  return (lat: (b.minLat + b.maxLat) / 2, lon: (b.minLon + b.maxLon) / 2);
}

({double minLat, double minLon, double maxLat, double maxLon}) bounds(
  String geohash,
) {
  double minLat = -90;
  double maxLat = 90;
  double minLon = -180;
  double maxLon = 180;
  bool evenBit = true;

  if (geohash.isEmpty) {
    throw ArgumentError('Geohash cannot be empty');
  }

  for (final char in geohash.toLowerCase().codeUnits) {
    final idx = _kCodeUnitToInt[char];
    if (idx == null) {
      throw ArgumentError('Invalid characters in the geohash: "$geohash"');
    }

    for (int bit = 4; bit >= 0; bit--) {
      final v = (idx >> bit) & 1;
      if (evenBit) {
        final midLon = (minLon + maxLon) / 2;
        if (v == 1) {
          minLon = midLon;
        } else {
          maxLon = midLon;
        }
      } else {
        final midLat = (minLat + maxLat) / 2;
        if (v == 1) {
          minLat = midLat;
        } else {
          maxLat = midLat;
        }
      }
      evenBit = !evenBit;
    }
  }

  return (minLat: minLat, minLon: minLon, maxLat: maxLat, maxLon: maxLon);
}

/// Returns a single neighbour of the given [geohash] in the [direction].
/// For diagonal directions, runs the processing twice.
///
/// This implementation uses character matching. I have benchmarked it
/// against another implementation with decoding-encoding, and it was
/// 2.5 times faster.
String adjacent(String geohash, Direction direction) {
  if (geohash.isEmpty) {
    throw ArgumentError('Geohash cannot be empty');
  }

  // Support the diagonal directions.
  if (direction == Direction.northWest) {
    geohash = adjacent(geohash, Direction.north);
    direction = Direction.west;
  } else if (direction == Direction.northEast) {
    geohash = adjacent(geohash, Direction.north);
    direction = Direction.east;
  } else if (direction == Direction.southWest) {
    geohash = adjacent(geohash, Direction.south);
    direction = Direction.west;
  } else if (direction == Direction.southEast) {
    geohash = adjacent(geohash, Direction.south);
    direction = Direction.east;
  }

  final last = geohash.codeUnitAt(geohash.length - 1);
  String parent = geohash.substring(0, geohash.length - 1);
  final type = geohash.length % 2;

  if (_kBorderUnits[direction]![type].contains(last)) {
    if (parent.isNotEmpty) {
      parent = adjacent(parent, direction);
    } else if (direction == Direction.north || direction == Direction.south) {
      throw ArgumentError('Cannot go over the north or south boundary');
    }
  }

  final newLast = _kNeighbourUnits[direction]![type][last];
  if (newLast == null) {
    throw ArgumentError('Wrong characters in geohash "$geohash"');
  }

  return parent + newLast;
}

/// Returns all eight neighbours for the given [geohash] string. It does
/// call [adjacent] eight times, so when you don't need every value, maybe
/// you are better using that function. Although it's a little bit more
/// efficient by not calculating an adjacent code twice for diagonal directions.
///
/// When near the northern or southern world boundary, this function can
/// return just five values.
Map<Direction, String> neighbours(String geohash) {
  String? north;
  try {
    north = adjacent(geohash, Direction.north);
  } on ArgumentError {}

  String? south;
  try {
    south = adjacent(geohash, Direction.south);
  } on ArgumentError {}

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
List<String> forBounds(
    double minLat, double minLon, double maxLat, double maxLon, int precision,
    {int limit = 100000}) {
  // Keeping the alternative code just in case, but a benchmarking has shown
  // that using adjacent() is almost twice as fast.
  bool byCoords = false;

  if (precision > 12 || precision < 1) {
    throw ArgumentError('Precision should be between 1 and 12');
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

  final result = <String>[];

  if (byCoords) {
    for (double lat = (southWestBounds.minLat + southWestBounds.maxLat) / 2;
        lat < northEastBounds.maxLat;
        lat += dLat) {
      for (double lon = (southWestBounds.minLon + southWestBounds.maxLon) / 2;
          lon < northEastBounds.maxLon;
          lon += dLon) {
        result.add(encode(lat, lon, precision));
      }
    }
  } else {
    // First prepare the top row.
    String topLeftHash = encode(maxLat, minLon, precision);
    final top = <String>[topLeftHash];
    while (topLeftHash != northEastHash) {
      topLeftHash = adjacent(topLeftHash, Direction.east);
      top.add(topLeftHash);
    }
    result.addAll(top);

    // Now start with bottom left and go bottom-top, column by column,
    // until we encounter the final top element.
    String geohashX = southWestHash;
    for (int i = 0; i < top.length; i++) {
      String geohash = geohashX;
      while (geohash != top[i]) {
        result.add(geohash);
        geohash = adjacent(geohash, Direction.north);
      }
      geohashX = adjacent(geohashX, Direction.east);
    }
  }

  return result;
}

const _kEarthRadius = 6371008; // mean radius

/// Returns a list of geohashes for a circle with a given centre location
/// and a radius in meters. Assumes the latitude and longitude to be
/// in EPSG:4326 projection. Will trim the circle if it goes outside the
/// EPSG:3857 projection boundaries.
///
/// Note that this by default uses an equirectangular approximation for
/// distances. It works well on distances under a couple hundred kilometers.
/// If you need higher precision and bigger distances, set [precise]
/// to true. Keep in mind that the notion of a circle on a sphere is
/// a bit complex, so the result can still be incorrect.
///
/// To speed this up, set [asBox] to true: it will return geohashes not in a circle,
/// but in a box with the requested radius. Meaning, it will include geohashes
/// that are [radius] * 1.44 meters away from the centre. Note that [asBox]
/// only works when [precise] is false.
List<String> forCircle(double lat, double lon, double radius, int precision,
    {bool asBox = false, bool precise = false}) {
  if (asBox && precise) {
    throw ArgumentError('Cannot use boxes for precise distance calculations');
  }

  if (precision > 12 || precision < 1) {
    throw ArgumentError('Precision should be between 1 and 12');
  }

  if (lat < -90 || lat > 90) {
    throw ArgumentError('Latitude is out of bounds: $lat');
  }

  while (lon < -180) lon += 360;
  while (lon > 180) lon -= 360;

  if (asBox) {
    // Calculate the boundaries and call another function.
    double rLon = radius / _kEarthRadius / cos(lat / 180 * pi) * 180 / pi;
    double rLat = radius / _kEarthRadius * 180 / pi;

    return forBounds(max(-90, lat - rLat), lon - rLon, min(90, lat + rLat),
        lon + rLon, precision);
  }

  final centre = encode(lat, lon, precision);
  final b = bounds(centre); // to not re-encode every geohash
  final result = <String>[];

  // TODO: ???

  return result;
}

void main() {
  final r = Random();
  final calls = List.generate(1000, (i) => i).map((_) => (
        r.nextDouble() * 180 - 90,
        r.nextDouble() * 360 - 180,
        r.nextDouble() * 100000
      ));

  syncBenchmark('as box', () {
    for (final c in calls) {
      try {
        forCircle(c.$1, c.$2, c.$3, 5, asBox: true);
      } on TooManyGeohashesException {
        // do nothing
      }
    }
  }).report();

  syncBenchmark('regular', () {
    for (final c in calls) {
      try {
        forCircle(c.$1, c.$2, c.$3, 5);
      } on TooManyGeohashesException {
        // do nothing
      }
    }
  }).report();

  syncBenchmark('precise', () {
    for (final c in calls) {
      try {
        forCircle(c.$1, c.$2, c.$3, 5, precise: true);
      } on TooManyGeohashesException {
        // do nothing
      }
    }
  }).report();
}
