import 'package:fast_geohash/fast_geohash_str.dart';
import 'package:test/test.dart';

void main() {
  test('Neighbours precision 1', () {
    expect(geohash.neighbours('r'), {
      Direction.northWest: 'w',
      Direction.north: 'x',
      Direction.northEast: '8',
      Direction.west: 'q',
      Direction.east: '2',
      Direction.southWest: 'n',
      Direction.south: 'p',
      Direction.southEast: '0',
    });
  });

  test('Neighbours precision 2 simple', () {
    expect(geohash.neighbours('r7'), {
      Direction.northWest: 'rh',
      Direction.north: 'rk',
      Direction.northEast: 'rs',
      Direction.west: 'r5',
      Direction.east: 're',
      Direction.southWest: 'r4',
      Direction.south: 'r6',
      Direction.southEast: 'rd',
    });
  });

  test('Neighbours precision 7', () {
    expect(geohash.neighbours("9v6kn85"), {
      Direction.north: '9v6kn87',
      Direction.northEast: '9v6kn8k',
      Direction.northWest: '9v6kn86',
      Direction.east: '9v6kn8h',
      Direction.west: '9v6kn84',
      Direction.southEast: '9v67yxu',
      Direction.south: '9v67yxg',
      Direction.southWest: '9v67yxf',
    });
  });

  test('Neighbours partial', () {
    expect(geohash.neighbours('f').length, equals(5));
    expect(geohash.neighbours('52h0').length, equals(5));
    expect(geohash.neighbours('uxfzur').length, equals(5));
  });

  test('Neighbours errors', () {
    expect(() => geohash.neighbours(''), throwsArgumentError);
    expect(() => geohash.adjacent('f', Direction.north),
        throwsA(isA<OutOfWorldBoundsException>()));
  });
}
