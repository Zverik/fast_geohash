import 'package:fast_geohash/fast_geohash.dart';
import 'package:test/test.dart';

void main() {
  test('Encode', () {
    expect(encode(42.6, -5.6, 12), equals('ezs42e44yx96'));
    expect(encode(42.6, -5.6, 5), equals('ezs42'));
    expect(encode(0.0, -5.6, 5), equals('ebh00'));
    expect(encode(-15.5, 167.5, 1), equals('r'));
    expect(encode(30.23710012435913, -97.79499292373657, 12), "9v6kn87zgs00");
    expect(encode(32, 117, 3), equals('wte'));
  });

  test('Encode precision errors', () {
    expect(() => encode(-15.5, 167.5, 0), throwsArgumentError);
    expect(() => encode(30.23710012435913, -97.79499292373657, 20),
        throwsArgumentError);
  });

  test('Encode wrapping', () {
    expect(() => encode(-111, 45, 5), throwsArgumentError);
    expect(encode(45, 195, 8), equals(encode(45, -165, 8)));
    expect(encode(45, -195, 8), equals(encode(45, 165, 8)));
  });

  test('Decode', () {
    final ll = decode('ww8p1r4t8');
    expect(ll.lat, closeTo(37.8324, 1e-4));
    expect(ll.lon, closeTo(112.5584, 1e-4));

    expect(decode('ebh00'), equals(decode('EBH00')));
  });

  test('Decode errors', () {
    expect(() => decode(''), throwsArgumentError);
    expect(() => decode('abcdef'), throwsArgumentError);
  });

  test('Neighbours precision 1', () {
    expect(neighbours('r'), {
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
    expect(neighbours('r7'), {
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
    expect(neighbours("9v6kn85"), {
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
    expect(neighbours('f').length, equals(5));
    expect(neighbours('52h0').length, equals(5));
    expect(neighbours('uxfzur').length, equals(5));
  });

  test('Neighbours errors', () {
    expect(() => neighbours(''), throwsArgumentError);
    expect(() => adjacent('f', Direction.north), throwsArgumentError);
  });
}
