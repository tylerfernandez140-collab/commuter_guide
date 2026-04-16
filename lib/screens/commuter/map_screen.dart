import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/api_service.dart';
import '../../models/landmark.dart';

class MapScreen extends StatefulWidget {
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
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Landmark> _allLandmarks = [];
  Landmark? _selectedLandmark;

  @override
  void initState() {
    super.initState();
    _fetchLandmarks();
  }

  Future<void> _fetchLandmarks() async {
    try {
      final apiService = ApiService();
      final landmarks = await apiService.getLandmarks();
      if (mounted) {
        setState(() {
          _allLandmarks = landmarks;
        });
      }
    } catch (e) {
      debugPrint('Error fetching landmarks: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    // Convert coordinates
    final List<LatLng> points = widget.routeCoordinates?.map((coord) {
      final lat = coord['lat'] ?? coord['latitude'];
      final lng = coord['lng'] ?? coord['longitude'];
      return LatLng(lat, lng);
    }).toList() ?? [];

    // Calculate center
    LatLng center = const LatLng(14.4793, 121.0195);
    if (points.isNotEmpty) {
      center = points.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName ?? 'Map'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
            ),
            children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.commuter_guide',
          ),
          // Route polyline
          if (points.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 5.0,
                  color: const Color(0xFF0F766E),
                ),
              ],
            ),
          // Start and end markers
          MarkerLayer(
            markers: [
              if (points.isNotEmpty)
                Marker(
                  point: points.first,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                ),
              if (points.length > 1)
                Marker(
                  point: points.last,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
            ],
          ),
          // Landmark markers - always show all landmarks
          if (_allLandmarks.isNotEmpty)
            MarkerLayer(
              markers: _allLandmarks.map((landmark) {
                return Marker(
                  point: LatLng(landmark.latitude, landmark.longitude),
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => _showLandmarkInfo(landmark),
                    child: const Icon(Icons.flag, color: Colors.green, size: 36),
                  ),
                );
              }).toList(),
            ),
        ],
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
