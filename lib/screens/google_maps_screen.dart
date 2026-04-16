import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../models/landmark.dart';

class GoogleMapsScreen extends StatefulWidget {
  final List<dynamic>? routeCoordinates;
  final List<Landmark>? landmarks;
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
  gmap.LatLng? userLocation; // null until GPS is obtained
  gmap.LatLng? sourceLocation;
  gmap.LatLng? destination;
  Set<gmap.Polyline> _polylines = {};
  List<gmap.LatLng> routePoints = [];
  double _routeDistance = 0.0;
  bool _is3DView = true;
  double _currentZoom = 18.0;
  bool _hasUserLocation = false;
  List<Landmark> _allLandmarks = [];
  bool _isLoadingLandmarks = true;
  gmap.BitmapDescriptor? _landmarkIcon;
  bool _iconsLoaded = false;
  final GlobalKey _iconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _calculateRouteDistance();
    _addRoutePolylines();
    _fetchLandmarks();
    _loadLandmarkIcon();
  }

  Future<void> _loadLandmarkIcon() async {
    try {
      final icon = await _createFlagMarkerBitmap();
      if (mounted) {
        setState(() {
          _landmarkIcon = icon;
          _iconsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading landmark icon: $e');
      // Fallback to default green marker
      if (mounted) {
        setState(() {
          _landmarkIcon = gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueGreen);
          _iconsLoaded = true;
        });
      }
    }
  }

  Future<gmap.BitmapDescriptor> _createFlagMarkerBitmap() async {
    // Draw flag matching Material Icons.flag - small size like default Google Maps pins
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 32.0; // Match standard Google Maps location pin size

    // Flag dimensions - rectangle with triangle notch on right
    final poleX = size * 0.2;
    final poleY = size * 0.1;
    final poleBottom = size * 0.9;
    
    final flagLeft = poleX;
    final flagTop = poleY;
    final flagWidth = size * 0.5;
    final flagHeight = size * 0.35;
    final flagRight = flagLeft + flagWidth;
    final flagBottom = flagTop + flagHeight;
    final centerY = (flagTop + flagBottom) / 2;

    // Draw pole
    final polePaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(poleX, poleY),
      Offset(poleX, poleBottom),
      polePaint,
    );

    // Draw flag: rectangle with inward triangle notch
    final flagPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(flagLeft, flagTop)
      ..lineTo(flagRight, flagTop)
      ..lineTo(flagRight, centerY - 1)
      ..lineTo(flagRight - size * 0.18, centerY)
      ..lineTo(flagRight, centerY + 1)
      ..lineTo(flagRight, flagBottom)
      ..lineTo(flagLeft, flagBottom)
      ..close();

    canvas.drawPath(path, flagPaint);

    // Convert
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) throw Exception('Failed to create marker');
    return gmap.BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  Future<void> _fetchLandmarks({bool forceRefresh = false}) async {
    try {
      // Show loading if not initial load
      if (_allLandmarks.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refreshing landmarks...'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF0F766E),
          ),
        );
      }
      
      // If landmarks were passed in, use those
      if (widget.landmarks != null) {
        if (mounted) {
          setState(() {
            _allLandmarks = widget.landmarks!;
            _isLoadingLandmarks = false;
          });
        }
        return;
      }
      
      // Fetch fresh landmarks from API
      final apiService = ApiService();
      final landmarks = await apiService.getLandmarks(forceRefresh: forceRefresh);
      
      if (mounted) {
        setState(() {
          _allLandmarks = landmarks;
          _isLoadingLandmarks = false;
        });
        
        // Show success message with count
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_allLandmarks.length} landmarks loaded'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching landmarks: $e');
      if (mounted) {
        setState(() => _isLoadingLandmarks = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        userLocation = gmap.LatLng(position.latitude, position.longitude);
        _hasUserLocation = true;
      });
      // Move camera to user location
      _mapController?.animateCamera(
        gmap.CameraUpdate.newLatLngZoom(userLocation!, _currentZoom),
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
    } else {
      // Clear route data when no route is provided
      setState(() {
        sourceLocation = null;
        destination = null;
        routePoints = [];
        _polylines = {};
        _routeDistance = 0.0;
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

  @override
  Widget build(BuildContext context) {
    // Hidden widget to capture the icon
    final iconWidget = Offstage(
      offstage: true,
      child: RepaintBoundary(
        key: _iconKey,
        child: const Icon(Icons.flag, color: Colors.green, size: 48),
      ),
    );
    
    return Stack(
      children: [
        iconWidget,
        Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName ?? 'Map'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchLandmarks(forceRefresh: true),
            tooltip: 'Refresh landmarks',
          ),
          IconButton(
            icon: Icon(_is3DView ? Icons.view_in_ar : Icons.map),
            onPressed: _toggle3DView,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
          ),
        ),
        child: Stack(
          children: [
            gmap.GoogleMap(
            initialCameraPosition: gmap.CameraPosition(
              target: sourceLocation ?? userLocation ?? const gmap.LatLng(14.4793, 121.0195),
              zoom: _currentZoom,
            ),
            myLocationEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              // If we already have user location, move camera there
              if (_hasUserLocation && userLocation != null) {
                _mapController?.animateCamera(
                  gmap.CameraUpdate.newLatLngZoom(userLocation!, _currentZoom),
                );
              }
            },
            markers: _buildMarkers(),
            polylines: _polylines,
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
          ),

          // My Location Button
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: "my_location",
              onPressed: () {
                if (_hasUserLocation && userLocation != null) {
                  _mapController?.animateCamera(
                    gmap.CameraUpdate.newLatLngZoom(userLocation!, 18),
                  );
                } else {
                  // Try to get location again
                  _getUserLocation();
                }
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.teal),
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
      ),
    ),
      ],
    );
  }

  Set<gmap.Marker> _buildMarkers() {
    final markers = <gmap.Marker>{};
    
    // Debug: print what markers we're building
    debugPrint('_buildMarkers: hasUserLocation=$_hasUserLocation, userLocation=$userLocation');
    debugPrint('_buildMarkers: routeCoordinates=${widget.routeCoordinates}, landmarks=${widget.landmarks}');
    
    // User location marker (blue dot) - only show when GPS is obtained
    if (_hasUserLocation && userLocation != null) {
      markers.add(
        gmap.Marker(
          markerId: const gmap.MarkerId('user'),
          position: userLocation!,
          icon: gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueBlue),
          infoWindow: const gmap.InfoWindow(title: 'Your Location'),
        ),
      );
    }
    
    // Only show route markers when viewing a specific route
    if (widget.routeCoordinates != null) {
      // Route start marker (green)
      if (sourceLocation != null) {
        markers.add(
          gmap.Marker(
            markerId: const gmap.MarkerId('source'),
            position: sourceLocation!,
            icon: gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueGreen),
          ),
        );
      }
      // Route end marker (red)
      if (destination != null) {
        markers.add(
          gmap.Marker(
            markerId: const gmap.MarkerId('destination'),
            position: destination!,
            icon: gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueRed),
          ),
        );
      }
    }
    
    // Landmark markers - show green flag icon for all landmarks
    for (final landmark in _allLandmarks) {
      markers.add(
        gmap.Marker(
          markerId: gmap.MarkerId('lm_${landmark.latitude}_${landmark.longitude}'),
          position: gmap.LatLng(landmark.latitude, landmark.longitude),
          icon: _landmarkIcon ?? gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueGreen),
          anchor: const Offset(0.2, 0.9), // Anchor at bottom of pole
          infoWindow: gmap.InfoWindow(
            title: landmark.name,
            snippet: landmark.type.isNotEmpty ? landmark.type : null,
          ),
        ),
      );
    }

    return markers;
  }
}
