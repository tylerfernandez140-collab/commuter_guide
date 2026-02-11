import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../models/route_model.dart';
import '../services/api_service.dart';
import '../services/routing_service.dart';

class AddEditRouteScreen extends StatefulWidget {
  final RouteModel? route;

  AddEditRouteScreen({this.route});

  @override
  _AddEditRouteScreenState createState() => _AddEditRouteScreenState();
}

class _AddEditRouteScreenState extends State<AddEditRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final RoutingService _routingService = RoutingService();

  late TextEditingController _nameController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _fareController;
  late TextEditingController _timeController;

  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _endFocusNode = FocusNode();

  String _vehicleType = 'jeepney';

  // Map state
  final MapController _mapController = MapController();

  // _waypoints: The specific points the user tapped (Start, stops, End)
  List<LatLng> _waypoints = [];

  // Track start/end specifically for logic
  LatLng? _startLocation;
  LatLng? _endLocation;

  // _segments: The detailed road paths between waypoints
  // Segment[i] connects Waypoint[i] to Waypoint[i+1]
  List<List<LatLng>> _segments = [];

  static const LatLng _paranaqueCenter = LatLng(14.4793, 121.0195);
  bool _isRouting = false;
  String _statusMessage = "Calculating route...";

  // Debounce timers for auto-geocoding
  Timer? _startGeocodeTimer;
  Timer? _endGeocodeTimer;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.route?.routeName ?? '',
    );
    _startController = TextEditingController(
      text: widget.route?.startPoint ?? '',
    );
    _endController = TextEditingController(text: widget.route?.endPoint ?? '');
    _fareController = TextEditingController(
      text: widget.route?.fare.toString() ?? '',
    );
    _timeController = TextEditingController(
      text: widget.route?.estimatedTime.toString() ?? '',
    );

    // Add listeners for auto-geocoding with debounce
    _startController.addListener(_onStartPointChanged);
    _endController.addListener(_onEndPointChanged);

    // Listen to focus changes to know which field to update on map tap
    _startFocusNode.addListener(() {
      setState(() {}); // Rebuild to show active field visually if needed
    });
    _endFocusNode.addListener(() {
      setState(() {});
    });

    if (widget.route != null) {
      _vehicleType = widget.route!.vehicleType;
      // Load existing coordinates
      if (widget.route!.coordinates.isNotEmpty) {
        // Treat existing route as one big segment
        final points = widget.route!.coordinates
            .map((c) => LatLng(c['lat']!, c['lng']!))
            .toList();

        _segments.add(points);

        // Recover start and end waypoints
        if (points.isNotEmpty) {
          _startLocation = points.first;
          _waypoints.add(points.first);
        }
        if (points.length > 1) {
          _endLocation = points.last;
          _waypoints.add(points.last);
        }
      }
    }
  }

  @override
  void dispose() {
    _startGeocodeTimer?.cancel();
    _endGeocodeTimer?.cancel();
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _fareController.dispose();
    _timeController.dispose();
    _startFocusNode.dispose();
    _endFocusNode.dispose();
    super.dispose();
  }

  // Debounce methods for auto-geocoding
  void _onStartPointChanged() {
    _startGeocodeTimer?.cancel();
    _startGeocodeTimer = Timer(const Duration(milliseconds: 1000), () {
      _geocodeAndSetStart();
    });
  }

  void _onEndPointChanged() {
    _endGeocodeTimer?.cancel();
    _endGeocodeTimer = Timer(const Duration(milliseconds: 1000), () {
      _geocodeAndSetEnd();
    });
  }

  // Flatten segments for display and saving
  List<LatLng> get _displayRoute => _segments.expand((s) => s).toList();

  Future<void> _handleMapTap(LatLng point) async {
    if (_isRouting) return;

    // Determine which point to set based on focus or state
    bool updateStart = _startFocusNode.hasFocus;
    bool updateEnd = _endFocusNode.hasFocus;

    // If neither is focused, use logic:
    // If Start is missing, set Start.
    // Else if End is missing, set End.
    // Else (both exist), default to updating End (or could clear).
    if (!updateStart && !updateEnd) {
      if (_startLocation == null) {
        updateStart = true;
      } else {
        updateEnd = true; // Default to moving end point or setting it
      }
    }

    if (updateStart) {
      await _setStartPoint(point);
    } else if (updateEnd) {
      await _setEndPoint(point);
    }
  }

  Future<void> _setStartPoint(LatLng point) async {
    setState(() {
      _startLocation = point;
      _updateWaypointsList();
    });

    // Reverse geocode
    final address = await _routingService.getAddressFromCoordinates(point);
    if (address != null && mounted) {
      setState(() {
        _startController.text = address;
      });
    }

    _calculateRoute();
  }

  Future<void> _setEndPoint(LatLng point) async {
    setState(() {
      _endLocation = point;
      _updateWaypointsList();
    });

    // Reverse geocode
    final address = await _routingService.getAddressFromCoordinates(point);
    if (address != null && mounted) {
      setState(() {
        _endController.text = address;
      });
    }

    _calculateRoute();
  }

  void _updateWaypointsList() {
    _waypoints.clear();
    if (_startLocation != null) _waypoints.add(_startLocation!);
    if (_endLocation != null) _waypoints.add(_endLocation!);
  }

  Future<void> _geocodeAndSetStart() async {
    final query = _startController.text;
    if (query.isEmpty) return;

    final point = await _routingService.getCoordinatesFromAddress(query);
    if (point != null) {
      setState(() {
        _startLocation = point;
        _updateWaypointsList();
        _mapController.move(point, 15);
      });
      _calculateRoute();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Start location not found')));
    }
  }

  Future<void> _geocodeAndSetEnd() async {
    final query = _endController.text;
    if (query.isEmpty) return;

    final point = await _routingService.getCoordinatesFromAddress(query);
    if (point != null) {
      setState(() {
        _endLocation = point;
        _updateWaypointsList();
        // Don't necessarily move map if we want to see the whole route,
        // but moving to end point is okay.
        // Better: fit bounds if route calculated.
      });
      _calculateRoute();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('End location not found')));
    }
  }

  Future<void> _calculateRoute() async {
    if (_startLocation == null || _endLocation == null) return;
    if (_isRouting) return;

    setState(() => _isRouting = true);

    try {
      final path = await _routingService.getRoute(
        _startLocation!,
        _endLocation!,
      );

      setState(() {
        _segments.clear();
        _segments.add(path);
        _isRouting = false;
      });

      // Fit bounds
      if (path.isNotEmpty) {
        // Simple bounds calculation
        double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
        for (var p in path) {
          if (p.latitude < minLat) minLat = p.latitude;
          if (p.latitude > maxLat) maxLat = p.latitude;
          if (p.longitude < minLng) minLng = p.longitude;
          if (p.longitude > maxLng) maxLng = p.longitude;
        }

        // Add padding
        final bounds = LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        );

        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)),
        );
      }
    } catch (e) {
      print("Route error: $e");

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Routing failed: $e. using straight line.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );

      // Fallback to straight line
      setState(() {
        _segments.clear();
        _segments.add([_startLocation!, _endLocation!]);
        _isRouting = false;
      });
    }
  }

  void _clearPoints() {
    setState(() {
      _startLocation = null;
      _endLocation = null;
      _waypoints.clear();
      _segments.clear();
      _startController.clear();
      _endController.clear();
    });
  }

  void _undoPoint() {
    // Basic undo logic
    if (_endLocation != null) {
      setState(() {
        _endLocation = null;
        _endController.clear();
        _updateWaypointsList();
        _segments.clear();
      });
    } else if (_startLocation != null) {
      setState(() {
        _startLocation = null;
        _startController.clear();
        _updateWaypointsList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route == null ? 'New Route' : 'Edit Route'),
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 800;

          if (isWide) {
            // Desktop/Web Layout (Side-by-Side)
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.all(24),
                    color: Colors.grey[50],
                    child: _buildForm(context),
                  ),
                ),
                Expanded(flex: 2, child: _buildMapSection()),
              ],
            );
          } else {
            // Mobile Layout (Vertical Stack)
            return Column(
              children: [
                // Map takes top 45%
                Expanded(flex: 9, child: _buildMapSection()),
                // Form takes bottom 55%
                Expanded(
                  flex: 11,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: _buildForm(context),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMapSection() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _waypoints.isNotEmpty
                ? _waypoints.first
                : _paranaqueCenter,
            initialZoom: 13.5,
            onTap: (tapPosition, point) => _handleMapTap(point),
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.commuter_guide',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _displayRoute,
                  strokeWidth: 5.0,
                  color: Theme.of(context).primaryColor,
                  isDotted: false,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                if (_waypoints.isNotEmpty)
                  Marker(
                    point: _waypoints.first,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                if (_waypoints.length > 1)
                  Marker(
                    point: _waypoints.last,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ..._waypoints
                    .skip(1)
                    .take(_waypoints.length > 1 ? _waypoints.length - 2 : 0)
                    .map(
                      (point) => Marker(
                        point: point,
                        width: 12,
                        height: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ],
        ),
        // Loading Indicator
        if (_isRouting)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(_statusMessage, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        // Map Controls
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: "undo",
                onPressed: _undoPoint,
                backgroundColor: Colors.white,
                child: Icon(Icons.undo, color: Colors.black87),
                tooltip: 'Undo last point',
              ),
              SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: "clear",
                onPressed: _clearPoints,
                backgroundColor: Colors.white,
                child: Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Clear route',
              ),
            ],
          ),
        ),
        // Instructions Overlay
        if (_waypoints.isEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "Tap map to start drawing route",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text(
            "Route Details",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildTextField(_nameController, 'Route Name', Icons.directions_bus),
          SizedBox(height: 16),
          _buildDropdown(),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _startController,
                  'Start Point',
                  Icons.my_location,
                  focusNode: _startFocusNode,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  _endController,
                  'End Point',
                  Icons.flag,
                  focusNode: _endFocusNode,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _fareController,
                  'Fare (₱)',
                  Icons.payments,
                  isNumber: true,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  _timeController,
                  'Time (min)',
                  Icons.timer,
                  isNumber: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveRoute,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 2,
              ),
              child: Text(
                'Save Route',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    FocusNode? focusNode,
    VoidCallback? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _vehicleType,
      decoration: InputDecoration(
        labelText: 'Vehicle Type',
        prefixIcon: Icon(Icons.directions_car, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: ['jeepney', 'minibus', 'ejeepney']
          .map(
            (type) =>
                DropdownMenuItem(value: type, child: Text(type.toUpperCase())),
          )
          .toList(),
      onChanged: (val) => setState(() => _vehicleType = val!),
    );
  }

  Future<void> _saveRoute() async {
    if (_formKey.currentState!.validate()) {
      if (_waypoints.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please mark at least 2 points on the map'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final newRoute = RouteModel(
        id: widget.route?.id ?? '',
        routeName: _nameController.text,
        vehicleType: _vehicleType,
        startPoint: _startController.text,
        endPoint: _endController.text,
        fare: double.parse(_fareController.text),
        estimatedTime: int.parse(_timeController.text),
        landmarks: widget.route?.landmarks ?? [],
        coordinates: _displayRoute
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
        startLatLng: _startLocation != null
            ? [_startLocation!.latitude, _startLocation!.longitude]
            : null,
        endLatLng: _endLocation != null
            ? [_endLocation!.latitude, _endLocation!.longitude]
            : null,
      );

      try {
        if (widget.route == null) {
          await _apiService.createRoute(newRoute);
        } else {
          await _apiService.updateRoute(newRoute.id, newRoute);
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
