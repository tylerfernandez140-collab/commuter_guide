import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../models/route_model.dart';
import '../services/api_service.dart';
import '../services/routing_service.dart';

class AddEditRouteScreen extends StatefulWidget {
  final RouteModel? route;

  const AddEditRouteScreen({super.key, this.route});

  @override
  State<AddEditRouteScreen> createState() => _AddEditRouteScreenState();
}

class _AddEditRouteScreenState extends State<AddEditRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final RoutingService _routingService = RoutingService();
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _fareController;
  late TextEditingController _discountedFareController;
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

  // Cached display route to avoid rebuild churn
  List<LatLng> _displayRoute = [];

  static const LatLng _paranaqueCenter = LatLng(14.4793, 121.0195);
  bool _isRouting = false;
  String _statusMessage = "Calculating route...";
  bool _isProgrammaticTextUpdate = false;

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
      text: widget.route?.regularFare?.toString() ?? widget.route?.fare?.toString() ?? '',
    );
    _discountedFareController = TextEditingController(
      text: widget.route?.discountedFare?.toString() ?? '',
    );
    _timeController = TextEditingController(
      text: widget.route?.estimatedTime.toString() ?? '',
    );

    // Add listeners for auto-geocoding with debounce
    _startController.addListener(_onStartPointChanged);
    _endController.addListener(_onEndPointChanged);

    if (widget.route != null) {
      _vehicleType = widget.route!.vehicleType;
      // Load existing coordinates
      if (widget.route!.coordinates.isNotEmpty) {
        // Treat existing route as one big segment
        final points = widget.route!.coordinates
            .map((c) => LatLng(c['lat']!, c['lng']!))
            .toList();

        _segments.add(points);
        _displayRoute = List<LatLng>.from(points);

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
    _discountedFareController.dispose();
    _timeController.dispose();
    _startFocusNode.dispose();
    _endFocusNode.dispose();
    super.dispose();
  }

  // Debounce methods for auto-geocoding
  void _onStartPointChanged() {
    if (_isProgrammaticTextUpdate) return;
    _startGeocodeTimer?.cancel();
    _startGeocodeTimer = Timer(const Duration(milliseconds: 1000), () {
      _geocodeAndSetStart();
    });
  }

  void _onEndPointChanged() {
    if (_isProgrammaticTextUpdate) return;
    _endGeocodeTimer?.cancel();
    _endGeocodeTimer = Timer(const Duration(milliseconds: 1000), () {
      _geocodeAndSetEnd();
    });
  }

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
      _isProgrammaticTextUpdate = true;
      _startController.text = address;
      _isProgrammaticTextUpdate = false;
    }

    if (_startLocation != null && _endLocation != null) {
      _calculateRoute();
    }
  }

  Future<void> _setEndPoint(LatLng point) async {
    setState(() {
      _endLocation = point;
      _updateWaypointsList();
    });

    // Reverse geocode
    final address = await _routingService.getAddressFromCoordinates(point);
    if (address != null && mounted) {
      _isProgrammaticTextUpdate = true;
      _endController.text = address;
      _isProgrammaticTextUpdate = false;
    }

    if (_startLocation != null && _endLocation != null) {
      _calculateRoute();
    }
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
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _mapController.move(point, 15);
          });
        }
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
        _segments
          ..clear()
          ..add(path);
        _displayRoute = List<LatLng>.from(path);
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

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _mapController.fitCamera(
              CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
            );
          });
        }
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
      final fallbackPath = [_startLocation!, _endLocation!];
      setState(() {
        _segments
          ..clear()
          ..add(fallbackPath);
        _displayRoute = List<LatLng>.from(fallbackPath);
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
      _displayRoute.clear();
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
        _displayRoute.clear();
      });
    } else if (_startLocation != null) {
      setState(() {
        _startLocation = null;
        _startController.clear();
        _updateWaypointsList();
        _displayRoute.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.route == null ? 'New Route' : 'Edit Route';
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
                  ),
                  borderRadius: BorderRadius.zero,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap map to set start and end points',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Map Section (takes remaining space)
              Expanded(
                child: _buildMapSection(),
              ),
              // Form Card
              Container(
                height: 280,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: _buildForm(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Stack(
      children: [
        FlutterMap(
          key: const ValueKey('route_map'),
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _waypoints.isNotEmpty
                ? _waypoints.first
                : _paranaqueCenter,
            initialZoom: 13.5,
            onTap: (tapPosition, point) => _handleMapTap(point),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.commuter_guide',
            ),
            if (_displayRoute.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _displayRoute,
                    strokeWidth: 5.0,
                    color: Theme.of(context).primaryColor,
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
                    child: const Icon(
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
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
              ],
            ),
          ],
        ),
        // Overlay widgets wrapped in IgnorePointer to prevent mouse tracker conflicts
        IgnorePointer(
          ignoring: false,
          child: Stack(
            children: [
              // Loading Indicator
              if (_isRouting) _buildLoadingIndicator(),
              // Map Controls
              _buildMapControls(),
              // Instructions Overlay
              if (_waypoints.isEmpty) _buildInstructions(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Positioned(
      top: 16,
      left: 16,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(_statusMessage, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            FloatingActionButton.small(
              heroTag: "undo",
              onPressed: _undoPoint,
              backgroundColor: Colors.white,
              child: const Icon(Icons.undo, color: Colors.black87),
              tooltip: 'Undo last point',
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: "clear",
              onPressed: _clearPoints,
              backgroundColor: Colors.white,
              child: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Clear route',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            "Tap map to start drawing route",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTextField(_nameController, 'Route Name', Icons.directions_bus),
          const SizedBox(height: 16),
          _buildDropdown(),
          const SizedBox(height: 16),
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _discountedFareController,
                  'Discounted Fare',
                  Icons.payments,
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  _fareController,
                  'Regular Fare',
                  Icons.payments,
                  isNumber: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _timeController,
                  'Time (min)',
                  Icons.timer,
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveRoute,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save, size: 20),
                    label: Text(
                      'Save Route',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
        labelStyle: const TextStyle(color: Colors.black87),
        floatingLabelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, size: 20, color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown() {
    return InkWell(
      onTap: _showVehicleTypeBottomSheet,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Vehicle Type',
          labelStyle: const TextStyle(color: Colors.black87),
          floatingLabelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          prefixIcon: const Icon(Icons.directions_car, size: 20, color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_vehicleType.toUpperCase(), style: const TextStyle(color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  void _showVehicleTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Vehicle Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...['jeepney', 'minibus', 'ejeepney'].map((type) {
                return ListTile(
                  leading: Icon(
                    Icons.directions_car,
                    color: _vehicleType == type
                        ? const Color(0xFF0F766E)
                        : Colors.grey,
                  ),
                  title: Text(type.toUpperCase()),
                  trailing: _vehicleType == type
                      ? const Icon(Icons.check, color: Color(0xFF0F766E))
                      : null,
                  onTap: () {
                    setState(() => _vehicleType = type);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_waypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mark at least 2 points on the map'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newRoute = RouteModel(
        id: widget.route?.id ?? '',
        routeName: _nameController.text,
        vehicleType: _vehicleType,
        startPoint: _startController.text,
        endPoint: _endController.text,
        regularFare: double.parse(_fareController.text),
        discountedFare: double.tryParse(_discountedFareController.text) ?? 0.0,
        fare: double.parse(_fareController.text), // Legacy
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

      if (widget.route == null) {
        await _apiService.createRoute(newRoute);
      } else {
        await _apiService.updateRoute(newRoute.id, newRoute);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.route == null ? 'Route created' : 'Route updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}