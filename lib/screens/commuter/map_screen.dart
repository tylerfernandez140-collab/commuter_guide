import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:latlong2/latlong.dart' as latlong;

class MapScreen extends StatefulWidget {
  final List<dynamic>? routeCoordinates;
  final List<dynamic>? landmarks;
  final String? routeName;

  const MapScreen({
    Key? key,
    this.routeCoordinates,
    this.landmarks,
    this.routeName,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  double _routeDistance = 0.0; // Distance in kilometers

  // Parañaque Coordinates
  static const LatLng _paranaqueCenter = LatLng(14.4793, 121.0195);

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _calculateRouteDistance();
    // Use WidgetsBinding to adjust camera after the map is built if coordinates are present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.routeCoordinates != null &&
          widget.routeCoordinates!.isNotEmpty) {
        _fitCameraToRoute();
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _calculateRouteDistance() {
    print('Calculating distance for coordinates: ${widget.routeCoordinates}');
    
    if (widget.routeCoordinates == null || widget.routeCoordinates!.isEmpty) {
      print('No coordinates found');
      setState(() {
        _routeDistance = 0.0;
      });
      return;
    }

    List<LatLng> points = [];
    
    // Handle different coordinate formats
    for (var coord in widget.routeCoordinates!) {
      print('Processing coordinate: $coord');
      
      double lat = 0.0;
      double lng = 0.0;
      
      if (coord is Map<String, dynamic>) {
        lat = (coord['lat'] as num?)?.toDouble() ?? 0.0;
        lng = (coord['lng'] as num?)?.toDouble() ?? 0.0;
      } else if (coord is List && coord.length >= 2) {
        lat = (coord[0] as num?)?.toDouble() ?? 0.0;
        lng = (coord[1] as num?)?.toDouble() ?? 0.0;
      } else {
        print('Unknown coordinate format: $coord');
        continue;
      }
      
      // Only add valid coordinates
      if (lat != 0.0 && lng != 0.0) {
        points.add(LatLng(lat, lng));
      }
    }

    print('Converted to ${points.length} valid LatLng points');

    if (points.length < 2) {
      print('Not enough valid points for distance calculation');
      setState(() {
        _routeDistance = 0.0;
      });
      return;
    }

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      double segmentDistance = latlong.Distance().as(
        LengthUnit.Kilometer,
        points[i],
        points[i + 1],
      );
      totalDistance += segmentDistance;
      print('Segment $i distance: ${segmentDistance.toStringAsFixed(3)} km');
    }

    print('Total distance: ${totalDistance.toStringAsFixed(3)} km');
    setState(() {
      _routeDistance = totalDistance;
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get current position
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    // Start listening to updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
            });
          },
        );
  }

  void _centerOnUser() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    } else {
      _determinePosition();
    }
  }

  void _fitCameraToRoute() {
    if (widget.routeCoordinates == null || widget.routeCoordinates!.isEmpty)
      return;

    List<LatLng> points = widget.routeCoordinates!.map((coord) {
      return LatLng(
        (coord['lat'] as num).toDouble(),
        (coord['lng'] as num).toDouble(),
      );
    }).toList();

    if (points.isEmpty) return;

    // Calculate bounds
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(50.0),
      ),
    );
  }

  List<Polyline> _buildPolylines() {
    if (widget.routeCoordinates == null || widget.routeCoordinates!.isEmpty) {
      return [];
    }

    List<LatLng> points = widget.routeCoordinates!.map((coord) {
      return LatLng(
        (coord['lat'] as num).toDouble(),
        (coord['lng'] as num).toDouble(),
      );
    }).toList();

    return [Polyline(points: points, color: Colors.red, strokeWidth: 5.0)];
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Current Location Marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.my_location, color: Colors.blue, size: 20),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.routeCoordinates != null &&
        widget.routeCoordinates!.isNotEmpty) {
      // Start Point
      var start = widget.routeCoordinates!.first;
      markers.add(
        Marker(
          point: LatLng(start['lat'], start['lng']),
          width: 80,
          height: 80,
          child: Column(
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 40),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(blurRadius: 2, color: Colors.black26),
                  ],
                ),
                child: const Text(
                  "Start",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );

      // End Point
      var end = widget.routeCoordinates!.last;
      markers.add(
        Marker(
          point: LatLng(end['lat'], end['lng']),
          width: 80,
          height: 80,
          child: Column(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 40),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(blurRadius: 2, color: Colors.black26),
                  ],
                ),
                child: const Text(
                  "End",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName ?? 'Map'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _paranaqueCenter,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.commuter_guide',
              ),
              PolylineLayer(polylines: _buildPolylines()),
              MarkerLayer(markers: _buildMarkers()),
            ],
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
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.straighten, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_routeDistance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${(_routeDistance / 0.4 * 60).round()} min',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _centerOnUser,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
