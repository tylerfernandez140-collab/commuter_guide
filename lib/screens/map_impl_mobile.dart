import 'package:flutter/material.dart';
import 'maplibre_screen_simple.dart';

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
    return MapLibreScreen(
      routeCoordinates: routeCoordinates,
      landmarks: landmarks,
      routeName: routeName,
    );
  }
}
