import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class MapLibreScreen extends StatefulWidget {
  final List<dynamic>? routeCoordinates;
  final List<dynamic>? landmarks;
  final String? routeName;

  const MapLibreScreen({
    super.key,
    this.routeCoordinates,
    this.landmarks,
    this.routeName,
  });

  @override
  State<MapLibreScreen> createState() => _MapLibreScreenState();
}

class _MapLibreScreenState extends State<MapLibreScreen> {
  MapLibreMapController? mapController;
  LatLng userLocation = const LatLng(14.5995, 120.9842); // Manila default
  double _routeDistance = 0.0;
  List<Line> routeLines = [];
  List<Symbol> landmarkSymbols = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _calculateRouteDistance();
  }

  void _onMapCreated(MapLibreMapController controller) {
    mapController = controller;
    _addRoutePolylines();
    _addLandmarkMarkers();
    
    // Set initial camera position based on route or user location
    if (widget.routeCoordinates != null && widget.routeCoordinates!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _fitCameraToRoute();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        mapController?.animateCamera(
          CameraUpdate.newLatLng(userLocation),
        );
      });
    }
  }

  void _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        userLocation = newLocation;
      });

      // Move camera to user location
      mapController?.animateCamera(
        CameraUpdate.newLatLng(newLocation),
      );
    });
  }

  void _addRoutePolylines() async {
    if (mapController == null || widget.routeCoordinates == null) return;

    final List<LatLng> coordinates = widget.routeCoordinates!
        .map((coord) => LatLng(coord['lat'], coord['lng']))
        .toList();

    if (coordinates.isEmpty) return;

    try {
      final line = await mapController!.addLine(
        LineOptions(
          geometry: coordinates,
          lineColor: "#3b82f6", // Blue color
          lineWidth: 5.0,
          lineOpacity: 0.8,
        ),
      );
      routeLines.add(line);
    } catch (e) {
      debugPrint('Error adding polyline: $e');
    }
  }

  void _addLandmarkMarkers() async {
    if (mapController == null || widget.landmarks == null) return;

    for (final landmark in widget.landmarks!) {
      try {
        final symbol = await mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(landmark['latitude'], landmark['longitude']),
            iconSize: 1.2,
            textField: landmark['name'],
            textSize: 12.0,
            textAnchor: "top",
          ),
        );
        landmarkSymbols.add(symbol);
      } catch (e) {
        debugPrint('Error adding landmark marker: $e');
      }
    }
  }

  void _fitCameraToRoute() {
    if (mapController == null || widget.routeCoordinates == null) return;

    final List<LatLng> coordinates = widget.routeCoordinates!
        .map((coord) => LatLng(coord['lat'], coord['lng']))
        .toList();

    if (coordinates.isEmpty) return;

    // Calculate bounds
    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (final coord in coordinates) {
      minLat = math.min(minLat, coord.latitude);
      maxLat = math.max(maxLat, coord.latitude);
      minLng = math.min(minLng, coord.longitude);
      maxLng = math.max(maxLng, coord.longitude);
    }

    // Add padding
    final padding = 0.01;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Use the correct API for newLatLngBounds
    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds),
    );
  }

  void _calculateRouteDistance() {
    if (widget.routeCoordinates == null || widget.routeCoordinates!.length < 2) return;

    double totalDistance = 0.0;
    for (int i = 0; i < widget.routeCoordinates!.length - 1; i++) {
      final coord1 = widget.routeCoordinates![i];
      final coord2 = widget.routeCoordinates![i + 1];
      final distance = Geolocator.distanceBetween(
        coord1['lat'],
        coord1['lng'],
        coord2['lat'],
        coord2['lng'],
      );
      totalDistance += distance;
    }

    setState(() {
      _routeDistance = totalDistance / 1000; // Convert to kilometers
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName ?? 'Map'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          MapLibreMap(
            styleString: "https://demotiles.maplibre.org/style.json",
            initialCameraPosition: const CameraPosition(
              target: LatLng(14.5995, 120.9842), // Default to Manila
              zoom: 16.0,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: false,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            rotateGesturesEnabled: true,
          ),
          // Distance and Time Info Card
          if (_routeDistance > 0)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Distance: ${_routeDistance.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Est. Time: ${(_routeDistance * 2).toStringAsFixed(0)} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Floating action button to recenter
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              child: const Icon(Icons.navigation, color: Colors.white),
              onPressed: () {
                if (widget.routeCoordinates != null && widget.routeCoordinates!.isNotEmpty) {
                  _fitCameraToRoute();
                } else {
                  mapController?.animateCamera(
                    CameraUpdate.newLatLng(userLocation),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up map elements
    for (final line in routeLines) {
      mapController?.removeLine(line);
    }
    for (final symbol in landmarkSymbols) {
      mapController?.removeSymbol(symbol);
    }
    super.dispose();
  }
}
