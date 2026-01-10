Geohashing is turning latitude and longitude pairs into a single string
or number. This library implements the oldest popular geohashing algorithm,
invented in 2008 by Gustavo Niemeyer.

Some base code was translated from the MIT-licensed
[latlon-geohash](https://github.com/chrisveness/latlon-geohash)
by  Chris Veness, the author of the [Movable Type blog](https://www.movable-type.co.uk/scripts/geohash.html).
Integer geohash code is inspired by [node-geohash](https://github.com/sunng87/node-geohash) by Ning Sun,
also MIT-licensed.

This library is built to replace [geohash](https://pub.dev/packages/geohash),
[dart_geohash](https://pub.dev/packages/dart_geohash),
[proximity_hash](https://pub.dev/packages/proximity_hash), and others.

Unlike other packages, this one is actively used in a popular project, is written
in pure Dart, made with performance in mind, and does not depend on anything.

## Usage

Import either the string or the integer part of the library. Either contains
a single constant named `geohash` with all the methods:

```dart
import 'package:fast_geohash/fast_geohash_str.dart';

void main() {
  // Encode a latitude and a longitude into a string.
  print(geohash.encode(78.220864, 15.643212, 7)); // "umghgzx"
  
  // Decode a string into a coordinate record.
  final ll = geohash.decode("6q2cgc");
  print("${ll.lat}, ${ll.lon}"); // "-9.52789306640625, -77.5250244140625"
  
  // Find all geohashes covering a circle with the given centre and radius in meters.
  final hashes = geohash.forCircle(-1.279488, 36.816839, 200, 7);
  print(hashes); // [kzf0tz1, kzf0tz0, kzf0txp, kzf0tz4]
}
```

Integer geohashes might be faster to work with, since they are easier to index,
and they fit into 64 bits. Note that the top bit is always set to record the geohash
precision, and that a character in the string geohash is equivalent to 5 bits.

```dart
import 'package:fast_geohash/fast_geohash_int.dart';

void main() {
  print(geohash.encode(78.220864, 15.643212,  7).toRadixString(2)); // 11101010
  print(geohash.encode(78.220864, 15.643212, 12).toRadixString(2)); // 1110101001101

  final hashes = geohash.forBounds(45.818, 5.9559, 47.8084, 10.4921, 15);
  print(hashes.map((h) => h.toRadixString(8)));
  // (164022, 164023, 164026, 164027, 164020, 164021, 164024, 164025)
}
```

## See Also

For other hashing algorithms, see:

* H3: Uber's complex hashing implemented in [h3_dart](https://pub.dev/packages/h3_dart)
  and [h3_flutter](https://pub.dev/packages/h3_flutter).
* S2: Google's cells, see [s2geometry_dart](https://pub.dev/packages/s2geometry_dart).
* Hilbert's curves, which are akin to Geohash, but with a better curve:
  [hilbert_geohash](https://pub.dev/packages/hilbert_geohash).