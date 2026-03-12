import 'package:flutter/material.dart';
import 'google_maps_screen.dart';

class MapScreenImpl extends StatelessWidget {
  final List<dynamic>? routeCoordinates;
  final List<dynamic>? landmarks;
  final String? routeName;

  const MapScreenImpl({
    super.key,
    this.routeCoordinates,
    this.landmarks,
    this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMapsScreen(
      routeCoordinates: routeCoordinates,
      landmarks: landmarks,
      routeName: routeName,
    );
  }
}
