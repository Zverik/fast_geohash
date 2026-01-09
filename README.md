Geohashing is turning latitude and longitude pairs into a single string
or number. This library implements the oldest popular base32-based geohashing algorithm,
invented in 2008 by Gustavo Niemeyer.

Most of the code came from the MIT-licensed
[latlon-geohash](https://github.com/chrisveness/latlon-geohash)
by the author of the [Movable Type blog](https://www.movable-type.co.uk/scripts/geohash.html).

This library is built to replace [geohash](https://pub.dev/packages/geohash),
[dart_geohash](https://pub.dev/packages/dart_geohash),
[proximity_hash](https://pub.dev/packages/proximity_hash).
It is inspired or takes hints from all of those, and is permissively licensed just like those.

Unlike other packages, this one is actively used in a popular project, is written
in pure Dart, made with performance in mind, and does not depend on anything.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder. 

```dart
const like = 'sample';
```

## Additional information

For other hashing algorithms, see:

* H3: Uber's complex hashing implemented in [h3_dart](https://pub.dev/packages/h3_dart)
  and [h3_flutter](https://pub.dev/packages/h3_flutter).
* S2: Google's cells, see [s2geometry_dart](https://pub.dev/packages/s2geometry_dart).
* Hilbert's curves, which are akin to Geohash, but with a better curve:
  [hilbert_geohash](https://pub.dev/packages/hilbert_geohash).