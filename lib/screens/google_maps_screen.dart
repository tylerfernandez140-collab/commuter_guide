import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class GoogleMapsScreen extends StatefulWidget {
  final List<dynamic>? routeCoordinates;
  final List<dynamic>? landmarks;
  final String? routeName;

  const GoogleMapsScreen({
    super.key,
    this.routeCoordinates,
    this.landmarks,
    this.routeName,
  });

  @override
  State<GoogleMapsScreen> createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  gmap.GoogleMapController? _mapController;
  gmap.LatLng userLocation = const gmap.LatLng(14.5995, 120.9842); // Manila default
  gmap.LatLng? sourceLocation;
  gmap.LatLng? destination;
  Set<gmap.Polyline> _polylines = {};
  List<gmap.LatLng> routePoints = [];
  double _routeDistance = 0.0;
  bool _is3DView = true;
  double _currentZoom = 18.0;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _calculateRouteDistance();
    _addRoutePolylines();
    _addLandmarkMarkers();
  }

  void _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        userLocation = gmap.LatLng(position.latitude, position.longitude);
      });
      _mapController?.moveCamera(
        gmap.CameraUpdate.newCameraPosition(
          gmap.CameraPosition(target: userLocation, zoom: _currentZoom),
        ),
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  void _addRoutePolylines() {
    if (widget.routeCoordinates != null) {
      final points = widget.routeCoordinates!
          .map((coord) => gmap.LatLng(coord['lat'], coord['lng']))
          .toList();
      setState(() {
        routePoints = points;
        if (points.isNotEmpty) {
          sourceLocation = points.first;
          destination = points.length > 1 ? points.last : null;
          _polylines = {
            gmap.Polyline(
              polylineId: const gmap.PolylineId('route'),
              points: points,
              width: 5,
              color: Colors.blue,
            ),
          };
        }
      });
    }
  }

  void _addLandmarkMarkers() {
    // Landmarks are handled in the build method
  }

  void _calculateRouteDistance() {
    if (routePoints.isEmpty) return;

    double totalDistance = 0.0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
    }

    setState(() {
      _routeDistance = totalDistance / 1000; // Convert to kilometers
    });
  }

  void _toggle3DView() {
    setState(() {
      _is3DView = !_is3DView;
    });
  }

  void _moveForward() {
    final newLat = userLocation.latitude + 0.001;
    final newLng = userLocation.longitude;
    final newPosition = gmap.LatLng(newLat, newLng);
    
    setState(() {
      userLocation = newPosition;
    });

    _mapController?.moveCamera(
      gmap.CameraUpdate.newLatLngZoom(userLocation, _currentZoom),
    );
  }

  void _moveBackward() {
    final newLat = userLocation.latitude - 0.001;
    final newLng = userLocation.longitude;
    final newPosition = gmap.LatLng(newLat, newLng);
    
    setState(() {
      userLocation = newPosition;
    });

    _mapController?.moveCamera(
      gmap.CameraUpdate.newLatLngZoom(userLocation, _currentZoom),
    );
  }

  void _moveLeft() {
    final newLat = userLocation.latitude;
    final newLng = userLocation.longitude - 0.001;
    final newPosition = gmap.LatLng(newLat, newLng);
    
    setState(() {
      userLocation = newPosition;
    });

    _mapController?.moveCamera(
      gmap.CameraUpdate.newLatLngZoom(userLocation, _currentZoom),
    );
  }

  void _moveRight() {
    final newLat = userLocation.latitude;
    final newLng = userLocation.longitude + 0.001;
    final newPosition = gmap.LatLng(newLat, newLng);
    
    setState(() {
      userLocation = newPosition;
    });

    _mapController?.moveCamera(
      gmap.CameraUpdate.newLatLngZoom(userLocation, _currentZoom),
    );
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = math.min(_currentZoom + 1, 18);
      _mapController?.moveCamera(
        gmap.CameraUpdate.newLatLngZoom(userLocation, _currentZoom),
      );
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = math.max(_currentZoom - 1, 2);
      _mapController?.moveCamera(
        gmap.CameraUpdate.newLatLngZoom(userLocation, _currentZoom),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName ?? 'Map'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(_is3DView ? Icons.view_in_ar : Icons.map),
            onPressed: _toggle3DView,
          ),
        ],
      ),
      body: Stack(
        children: [
          gmap.GoogleMap(
            initialCameraPosition: gmap.CameraPosition(
              target: sourceLocation ?? userLocation,
              zoom: _currentZoom,
            ),
            myLocationEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
            markers: _buildMarkers(),
            polylines: _polylines,
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          // Navigation Controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                // Zoom controls
                FloatingActionButton(
                  heroTag: "zoom_in",
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "zoom_out",
                  onPressed: _zoomOut,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
                const SizedBox(height: 8),
                // Direction controls
                FloatingActionButton(
                  heroTag: "up",
                  onPressed: _moveForward,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.keyboard_arrow_up, color: Colors.black),
                ),
                const SizedBox(height: 8),
                // Left and Right
                Row(
                  children: [
                    FloatingActionButton(
                      heroTag: "left",
                      onPressed: _moveLeft,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.keyboard_arrow_left, color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      heroTag: "right",
                      onPressed: _moveRight,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.keyboard_arrow_right, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "down",
                  onPressed: _moveBackward,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                ),
              ],
            ),
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estimated time: ${(_routeDistance / 20 * 60).round()} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Set<gmap.Marker> _buildMarkers() {
    final markers = <gmap.Marker>{};
    markers.add(
      gmap.Marker(
        markerId: const gmap.MarkerId('user'),
        position: userLocation,
        icon: gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueAzure),
      ),
    );
    if (sourceLocation != null) {
      markers.add(
        gmap.Marker(
          markerId: const gmap.MarkerId('source'),
          position: sourceLocation!,
          icon: gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueGreen),
        ),
      );
    }
    if (destination != null) {
      markers.add(
        gmap.Marker(
          markerId: const gmap.MarkerId('destination'),
          position: destination!,
          icon: gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueRed),
        ),
      );
    }
    // Landmark markers
    for (final landmark in (widget.landmarks ?? [])) {
      markers.add(
        gmap.Marker(
          markerId: gmap.MarkerId('lm_${landmark['name'] ?? landmark['latitude']}'),
          position: gmap.LatLng(landmark['latitude'], landmark['longitude']),
          icon: gmap.BitmapDescriptor.defaultMarker,
        ),
      );
    }
    return markers;
  }
}
