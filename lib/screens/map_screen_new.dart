import 'package:flutter/material.dart';
import '../screens/map_impl_mobile.dart'
    if (dart.library.html) '../screens/map_impl_web.dart';

class MapScreen extends StatelessWidget {
  final List<dynamic>? routeCoordinates;
  final List<dynamic>? landmarks;
  final String? routeName;

  const MapScreen({
    super.key,
    this.routeCoordinates,
    this.landmarks,
    this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commuter Guide'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: MapScreenImpl(
              routeCoordinates: routeCoordinates,
              landmarks: landmarks,
              routeName: routeName,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: const Text(
              'MapLibre GL Implementation\n'
              '• Better performance than flutter_map\n'
              '• Hardware acceleration\n'
              '• 3D terrain support\n'
              '• Smooth animations\n'
              '• Route polylines and landmarks\n'
              '• Distance calculation',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
