import 'geohash.dart';
import 'utils.dart';

class GeohashString extends GeohashBase<String> {
  static const _kBase32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  static final _kCodeUnitToInt = {
    for (final c in _kBase32.codeUnits.asMap().entries) c.value: c.key,
  };

  static const _kNeighbours = {
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

  static const _kBorders = {
    Direction.north: ['prxz', 'bcfguvyz'],
    Direction.south: ['028b', '0145hjnp'],
    Direction.east: ['bcfguvyz', 'prxz'],
    Direction.west: ['0145hjnp', '028b'],
  };

  // _kBase32[_kNeighbours[direction]![type].indexOf(last)];
  static final _kNeighbourUnits = <Direction, List<Map<int, String>>>{
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

  static final _kBorderUnits = {
    for (final direction in _kBorders.keys)
      direction: [
        for (int i = 0; i < 2; i++) _kBorders[direction]![i].codeUnits.toSet(),
      ],
  };

  const GeohashString();

  @override
  int precision(String geohash) => geohash.length;

  @override
  int get maxPrecision => 12;

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
  @override
  String encode(double lat, double lon, int precision) {
    if (precision > maxPrecision || precision < 1) {
      throw ArgumentError('Precision should be between 1 and $maxPrecision');
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

  @override
  BoundsRecord bounds(String geohash) {
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
  @override
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

    // This implementation uses character matching. I have benchmarked it
    // against another implementation with decoding-encoding, and it was
    // 2.5 times faster.
    geohash = geohash.toLowerCase();
    final last = geohash.codeUnitAt(geohash.length - 1);
    String parent = geohash.substring(0, geohash.length - 1);
    final type = geohash.length % 2;

    final newLast = _kNeighbourUnits[direction]![type][last];
    if (newLast == null) {
      throw ArgumentError('Wrong characters in geohash "$geohash"');
    }

    if (_kBorderUnits[direction]![type].contains(last)) {
      if (parent.isNotEmpty) {
        parent = adjacent(parent, direction);
      } else if (direction == Direction.north || direction == Direction.south) {
        throw OutOfWorldBoundsException();
      }
    }

    return parent + newLast;
  }
}
