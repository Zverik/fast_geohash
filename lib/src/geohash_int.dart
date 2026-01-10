import 'geohash.dart';
import 'utils.dart';

class GeohashInt extends GeohashBase<int> {
  const GeohashInt();

  @override
  int precision(int geohash) => geohash.bitLength - 1;

  @override
  int get maxPrecision => 62;

  /// Encode a latitude and longitude to a geohash string of given
  /// [precision] (that is, bit length). To match the precision of
  /// string-based geohashes, keep in mind that every character is 5 bits.
  ///
  /// Given the integer precision in Dart is 64 bits, the limit here
  /// is 62 bits: we use the highest bit to track the precision.
  /// Note that for the web, the limit must be 50 bits due to the JavaScript
  /// number representation.
  @override
  int encode(double lat, double lon, int precision) {
    if (precision > maxPrecision || precision < 1) {
      throw ArgumentError(
          'Precision should be between 1 and $maxPrecision bits');
    }

    if (lat < -90 || lat > 90) {
      throw ArgumentError('Latitude is out of bounds: $lat');
    }

    while (lon < -180) lon += 360;
    while (lon > 180) lon -= 360;

    double minLat = -90;
    double maxLat = 90;
    double minLon = -180;
    double maxLon = 180;

    int geohash = 1;
    for (int i = 0; i < precision; i++) {
      geohash <<= 1;
      if (i & 1 == 0) {
        final midLon = (minLon + maxLon) / 2;
        if (lon >= midLon) {
          geohash |= 1;
          minLon = midLon;
        } else {
          maxLon = midLon;
        }
      } else {
        final midLat = (minLat + maxLat) / 2;
        if (lat >= midLat) {
          geohash |= 1;
          minLat = midLat;
        } else {
          maxLat = midLat;
        }
      }
    }

    return geohash;
  }

  @override
  BoundsRecord bounds(int geohash) {
    if (geohash == 0) {
      throw ArgumentError('Geohash cannot be empty');
    }

    double minLat = -90;
    double maxLat = 90;
    double minLon = -180;
    double maxLon = 180;
    bool evenBit = true;
    int bit = 1 << (geohash.bitLength - 2);

    while (bit > 0) {
      if (evenBit) {
        final midLon = (minLon + maxLon) / 2;
        if (geohash & bit > 0) {
          minLon = midLon;
        } else {
          maxLon = midLon;
        }
      } else {
        final midLat = (minLat + maxLat) / 2;
        if (geohash & bit > 0) {
          minLat = midLat;
        } else {
          maxLat = midLat;
        }
      }

      bit >>= 1;
      evenBit = !evenBit;
    }

    return (minLat: minLat, minLon: minLon, maxLat: maxLat, maxLon: maxLon);
  }

  /// Returns a single neighbour of the given [geohash] in the [direction].
  /// For diagonal directions, runs the processing twice.
  int adjacentTodo(int geohash, Direction direction) {
    if (geohash == 0) {
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

    throw UnimplementedError();
  }
}
