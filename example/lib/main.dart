import 'package:fast_geohash/fast_geohash_str.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Geohash Demo', home: const MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> hashes = [];
  LatLngBounds? box;
  (LatLng, double)? circle;
  int precision = 7;
  final controller = MapController();

  bool makeCircle = true;
  bool preciseCircle = false;

  static const _kZoomPrecision = {
    1: 2,
    2: 2,
    3: 2,
    4: 3,
    5: 3,
    6: 3,
    7: 4,
    8: 4,
    9: 4,
    10: 5,
    11: 5,
    12: 5,
    13: 6,
    14: 6,
    15: 7,
    16: 7,
    17: 7,
    18: 8,
    19: 8,
    20: 9,
  };

  void updateHashes() {
    try {
      if (box != null) {
        hashes = geohash.forBounds(
          box!.south,
          box!.west,
          box!.north,
          box!.east,
          precision,
        );
      } else if (circle != null) {
        hashes = geohash.forCircle(
          circle!.$1.latitude,
          circle!.$1.longitude,
          circle!.$2,
          precision,
          precise: preciseCircle,
        );
      } else {
        hashes = [];
      }
    } on TooManyGeohashesException {
      hashes = [];
    }
    setState(() {});
  }

  void repaint([MapCamera? camera]) {
    camera ??= controller.camera;
    precision = _kZoomPrecision[camera.zoom.round()] ?? 5;
    final vb = camera.visibleBounds;
    final center = vb.simpleCenter;
    if (makeCircle) {
      final d = DistanceHaversine();
      final radius = d.distance(center, LatLng(center.latitude, vb.west));
      circle = (center, radius * 0.7);
      box = null;
    } else {
      final Rect rect = camera.pixelBounds;
      final delta = Offset(rect.width / 6, rect.height / 6);

      box = LatLngBounds(
        camera.unprojectAtZoom(rect.topLeft + delta),
        camera.unprojectAtZoom(rect.bottomRight - delta),
      );
      circle = null;
    }
    updateHashes();
  }

  void onMapEvent(MapEvent event) {
    if (event.source == MapEventSource.mapController) return;
    if (event is MapEventWithMove) {
      repaint(event.camera);
    }
  }

  List<LatLng> hashPolygon(String hash) {
    final b = geohash.bounds(hash);
    return [
      LatLng(b.minLat, b.minLon),
      LatLng(b.minLat, b.maxLon),
      LatLng(b.maxLat, b.maxLon),
      LatLng(b.maxLat, b.minLon),
    ];
  }

  List<LatLng> circlePolyline(LatLng center, double radius) {
    final d = DistanceHaversine();
    final result = <LatLng>[];
    const steps = 40;
    for (int i = 0; i <= steps; i++) {
      double angle = i * (360 / steps);
      while (angle > 180) {
        angle -= 360;
      }
      result.add(d.offset(center, radius, angle));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Circles:'),
              Checkbox(
                value: makeCircle,
                onChanged: (s) {
                  makeCircle = s ?? true;
                  repaint();
                },
              ),
              Text('Precise:'),
              Checkbox(
                value: preciseCircle,
                onChanged: (s) {
                  preciseCircle = s ?? false;
                  repaint();
                },
              ),
            ],
          ),
          Expanded(
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(
                minZoom: 5,
                maxZoom: 19,
                onMapEvent: onMapEvent,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                PolygonLayer(
                  polygons: [
                    for (final hash in hashes)
                      Polygon(
                        points: hashPolygon(hash),
                        borderStrokeWidth: 2,
                        borderColor: Colors.orange,
                        color: Colors.yellow.withValues(alpha: 0.5),
                      ),
                    if (box != null)
                      Polygon(
                        points: [
                          box!.northEast,
                          box!.northWest,
                          box!.southWest,
                          box!.southEast,
                          box!.northEast,
                        ],
                        borderStrokeWidth: 2,
                        borderColor: Colors.blue.shade700,
                      ),
                  ],
                ),
                if (circle != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: circlePolyline(circle!.$1, circle!.$2),
                        color: Colors.blue.shade700,
                        strokeWidth: 2,
                      ),
                    ],
                  ),
                Builder(
                  builder: (context) =>
                      Text(MapCamera.of(context).zoom.toString()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
