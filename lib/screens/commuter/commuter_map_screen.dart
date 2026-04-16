import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../services/routing_service.dart';
import '../../models/landmark.dart';

class CommuterMapScreen extends StatefulWidget {
  final LatLng? destination;
  final String? destinationName;

  const CommuterMapScreen({
    super.key,
    this.destination,
    this.destinationName,
  });

  @override
  State<CommuterMapScreen> createState() => _CommuterMapScreenState();
}

class _CommuterMapScreenState extends State<CommuterMapScreen> {
  List<Landmark> _landmarks = [];
  bool _isLoading = true;
  LatLng? _userLocation;
  Landmark? _selectedLandmark;
  List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();
  final RoutingService _routingService = RoutingService();

  @override
  void initState() {
    super.initState();
    _fetchLandmarks();
    _getUserLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh landmarks when returning to this screen
    _fetchLandmarks();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      final userLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _userLocation = userLatLng;
        });
        _mapController.move(userLatLng, 16);

        // Calculate route to destination if provided
        if (widget.destination != null) {
          await _calculateRouteToDestination(userLatLng, widget.destination!);
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _calculateRouteToDestination(LatLng start, LatLng end) async {
    try {
      final route = await _routingService.getRoute(start, end);
      if (mounted) {
        setState(() {
          _routePoints = route;
        });
        // Fit map to show both points
        _fitMapToBounds(start, end);
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
    }
  }

  void _fitMapToBounds(LatLng start, LatLng end) {
    final bounds = LatLngBounds(start, end);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _showLandmarkInfo(Landmark landmark) {
    setState(() {
      _selectedLandmark = landmark;
    });
  }

  void _closeLandmarkInfo() {
    setState(() {
      _selectedLandmark = null;
    });
  }

  Future<void> _fetchLandmarks() async {
    try {
      final apiService = ApiService();
      final landmarks = await apiService.getLandmarks();
      if (mounted) {
        setState(() {
          _landmarks = landmarks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching landmarks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLandmarks,
            tooltip: 'Refresh landmarks',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(14.4793, 121.0195),
              initialZoom: 12.0,
            ),
            children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.commuter_guide',
          ),
          // User location marker (red pin)
          if (_userLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _userLocation!,
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
              ],
            ),
          // Route polyline to destination
          if (_routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 5.0,
                  color: const Color(0xFF0F766E),
                ),
              ],
            ),
          // Destination marker
          if (widget.destination != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.destination!,
                  width: 48,
                  height: 48,
                  alignment: Alignment.topCenter,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
              ],
            ),
          // Landmark markers
          MarkerLayer(
            markers: _landmarks.map((landmark) {
              return Marker(
                point: LatLng(landmark.latitude, landmark.longitude),
                width: 48,
                height: 48,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () => _showLandmarkInfo(landmark),
                  child: const Icon(
                    Icons.flag,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      // Destination info card at top
      if (widget.destination != null && widget.destinationName != null)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: const Color(0xFF0F766E),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.navigation, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Directions to ${widget.destinationName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_routePoints.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.timeline, size: 16, color: Colors.white70),
                        SizedBox(width: 6),
                        Text(
                          'Route calculated from your location',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      // Landmark info card at top
      if (_selectedLandmark != null)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedLandmark!.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _closeLandmarkInfo,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        _selectedLandmark!.type,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  if (_selectedLandmark!.nearRoute.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.near_me, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Near: ${_selectedLandmark!.nearRoute}',
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
    ],
    ),
    );
  }
}
