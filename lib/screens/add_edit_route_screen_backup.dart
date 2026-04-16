import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../models/route_model.dart';
import '../services/api_service.dart';
import '../services/routing_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui' as ui;

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
  
  // Track UI interaction to disable map gestures
  bool _isInteractingWithUI = false;
  bool _isScrolling = false;

  late TextEditingController _nameController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _fareController;
  late TextEditingController _timeController;

  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _endFocusNode = FocusNode();
  late VoidCallback _startFocusListener;
  late VoidCallback _endFocusListener;

  String _vehicleType = 'jeepney';

  gmap.GoogleMapController? _gmapController;
  final MapController _fallbackMapController = MapController();

  bool get _useGoogleMaps {
    if (kIsWeb) return true;
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  // _waypoints: The specific points the user tapped (Start, stops, End)
  final List<LatLng> _waypoints = [];

  // Track start/end specifically for logic
  LatLng? _startLocation;
  LatLng? _endLocation;

  // _segments: The detailed road paths between waypoints
  // Segment[i] connects Waypoint[i] to Waypoint[i+1]
  final List<List<LatLng>> _segments = [];

  static const LatLng _paranaqueCenter = LatLng(14.4793, 121.0195);
  bool _isRouting = false;
  final String _statusMessage = "Calculating route...";

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
      text: widget.route?.fare?.toString() ?? '',
    );
    _timeController = TextEditingController(
      text: widget.route?.estimatedTime?.toString() ?? '',
    );

    // Add listeners for auto-geocoding with debounce
    _startController.addListener(_onStartPointChanged);
    _endController.addListener(_onEndPointChanged);

    // Listen to focus changes to know which field to update on map tap
    _startFocusListener = () {
      if (!mounted) return;
      setState(() {});
    };
    _endFocusListener = () {
      if (!mounted) return;
      setState(() {});
    };
    _startFocusNode.addListener(_startFocusListener);
    _endFocusNode.addListener(_endFocusListener);

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
    _startFocusNode.removeListener(_startFocusListener);
    _endFocusNode.removeListener(_endFocusListener);
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

  // Check if any input field has focus
  bool get _hasInputFocus => 
      _startFocusNode.hasFocus || 
      _endFocusNode.hasFocus ||
      FocusScope.of(context).hasFocus && 
      FocusScope.of(context).focusedChild != null;

  // Check if map gestures should be disabled
  bool get _shouldDisableMapGestures => _isScrolling || _hasInputFocus;

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
    if (mounted) {
      setState(() {
        _startLocation = point;
        _updateWaypointsList();
      });
    }

    // Reverse geocode
    final address = await _routingService.getAddressFromCoordinates(
      LatLng(point.latitude, point.longitude)
    );
    if (address != null && mounted) {
      setState(() {
        _startController.text = address;
      });
    }

    _calculateRoute();
  }

  Future<void> _setEndPoint(LatLng point) async {
    if (mounted) {
      setState(() {
        _endLocation = point;
        _updateWaypointsList();
      });
    }

    // Reverse geocode
    final address = await _routingService.getAddressFromCoordinates(
      LatLng(point.latitude, point.longitude)
    );
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
    
    debugPrint('Waypoints updated: ${_waypoints.length} points');
    for (int i = 0; i < _waypoints.length; i++) {
      debugPrint('  Waypoint $i: ${_waypoints[i].latitude}, ${_waypoints[i].longitude}');
    }
  }


  Future<void> _geocodeAndSetStart() async {
    final query = _startController.text;
    if (query.isEmpty) return;

    final point = await _routingService.getCoordinatesFromAddress(query);
    if (point != null) {
      if (mounted) {
        setState(() {
          _startLocation = LatLng(point.latitude, point.longitude);
          _updateWaypointsList();
        if (_useGoogleMaps) {
          _gmapController?.animateCamera(
            gmap.CameraUpdate.newLatLngZoom(
              gmap.LatLng(point.latitude, point.longitude),
              15,
            ),
          );
        } else {
          _fallbackMapController.move(LatLng(point.latitude, point.longitude), 15);
        }
      });
      _calculateRoute();
    } else {
      if (!mounted) return;
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
      if (mounted) {
        setState(() {
          _endLocation = LatLng(point.latitude, point.longitude);
          _updateWaypointsList();
        });
        // Don't necessarily move map if we want to see the whole route,
        // but moving to end point is okay.
        // Better: fit bounds if route calculated.
        _calculateRoute();
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('End location not found')));
    }
  }

  Future<void> _calculateRoute() async {
    if (_startLocation == null || _endLocation == null) return;
    if (_isRouting) return;

    debugPrint('=== Calculating Route ===');
    debugPrint('Start: ${_startLocation!.latitude}, ${_startLocation!.longitude}');
    debugPrint('End: ${_endLocation!.latitude}, ${_endLocation!.longitude}');
    debugPrint('Waypoints: ${_waypoints.length} points');

    if (mounted) setState(() => _isRouting = true);

    try {
      final path = await _routingService.getRoute(
        LatLng(_startLocation!.latitude, _startLocation!.longitude),
        LatLng(_endLocation!.latitude, _endLocation!.longitude),
      );

      debugPrint('Route received: ${path.length} points');
      
      if (mounted) {
        setState(() {
          _segments.clear();
          _segments.add(path);
          _isRouting = false;
        });
      }
      
      debugPrint('Segments updated: ${_segments.length} segments');
      debugPrint('Display route: ${_displayRoute.length} points');

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

        if (_displayRoute.isNotEmpty) {
          if (_useGoogleMaps) {
            final gbounds = gmap.LatLngBounds(
              southwest: gmap.LatLng(minLat, minLng),
              northeast: gmap.LatLng(maxLat, maxLng),
            );
            _gmapController?.animateCamera(
              gmap.CameraUpdate.newLatLngBounds(gbounds, 50),
            );
          } else {
            final fbounds = LatLngBounds(
              LatLng(minLat, minLng),
              LatLng(maxLat, maxLng),
            );
            _fallbackMapController.fitCamera(
              CameraFit.bounds(bounds: fbounds, padding: EdgeInsets.all(50)),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Route error: $e");

      // Show error to user
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Routing failed: $e. using straight line.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );

      // Fallback to straight line
      if (mounted) {
        setState(() {
          _segments.clear();
          _segments.add([_startLocation!, _endLocation!]);
          _isRouting = false;
        });
      }
    }
  }

  void _clearPoints() {
    if (mounted) {
      setState(() {
        _startLocation = null;
        _endLocation = null;
        _waypoints.clear();
        _segments.clear();
        _startController.clear();
        _endController.clear();
      });
    }
  }

  void _undoPoint() {
    // Basic undo logic
    if (_endLocation != null) {
      if (mounted) {
        setState(() {
          _endLocation = null;
          _endController.clear();
          _updateWaypointsList();
          _segments.clear();
        });
      }
    } else if (_startLocation != null) {
      if (mounted) {
        setState(() {
          _startLocation = null;
          _startController.clear();
          _updateWaypointsList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map as background
          Container(
            child: _buildMapSection(),
          ),
          // Header overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {}, // Consume the tap
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  // Invisible barrier to block clicks
                  Container(
                    height: 120, // Match header height
                    color: Colors.transparent,
                  ),
                  // Header content
                  _buildHeader(),
                ],
              ),
            ),
          ),
          // Form overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollStartNotification) {
                  if (mounted) setState(() => _isScrolling = true);
                } else if (scrollNotification is ScrollEndNotification) {
                  if (mounted) setState(() => _isScrolling = false);
                }
                return false; // Don't consume the notification
              },
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 800;

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: EdgeInsets.all(24),
                            color: Colors.white,
                            child: _buildForm(context),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(), // Empty space for wide view
                        ),
                      ],
                    );
                  } else {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: _buildForm(context),
                    );
                  }
                },
              ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveRoute,
        icon: const Icon(Icons.save),
        label: Text('Save Route', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
    );
  }

  // Helper Methods - moved before build to fix declaration order
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E).withValues(alpha: 0.9), 
            Color(0xFF2DD4BF).withValues(alpha: 0.9)
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
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
                  widget.route == null ? 'New Route' : 'Edit Route',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                'Draw the path and fill in route details.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildMapSection() {
    // Check if ORS API key is available
    final hasApiKey = dotenv.env['ORS_API_KEY'] != null && dotenv.env['ORS_API_KEY']!.isNotEmpty;
    
    return Stack(
      children: [
        Container(
          child: hasApiKey
              ? _useGoogleMaps
                  ? gmap.GoogleMap(
                initialCameraPosition: gmap.CameraPosition(
                  target: _waypoints.isNotEmpty
                      ? gmap.LatLng(_waypoints.first.latitude, _waypoints.first.longitude)
                      : gmap.LatLng(_paranaqueCenter.latitude, _paranaqueCenter.longitude),
                  zoom: 13.5,
                ),
                onMapCreated: (c) => _gmapController = c,
                onTap: (pos) => _handleMapTap(LatLng(pos.latitude, pos.longitude)),
                minMaxZoomPreference: const gmap.MinMaxZoomPreference(2.0, 18.0),
                // Disable gestures when scrolling or input fields have focus
                scrollGesturesEnabled: !_shouldDisableMapGestures,
                zoomGesturesEnabled: !_shouldDisableMapGestures,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                markers: {
                  if (_waypoints.isNotEmpty)
                    gmap.Marker(
                      markerId: const gmap.MarkerId('start'),
                      position: gmap.LatLng(_waypoints.first.latitude, _waypoints.first.longitude),
                      icon: gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueGreen),
                    ),
                  if (_waypoints.length > 1)
                    gmap.Marker(
                      markerId: const gmap.MarkerId('end'),
                      position: gmap.LatLng(_waypoints.last.latitude, _waypoints.last.longitude),
                      icon: gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueRed),
                    ),
                },
                polylines: {
                  if (_displayRoute.isNotEmpty)
                    gmap.Polyline(
                      polylineId: const gmap.PolylineId('route'),
                      points: _displayRoute
                          .map((p) => gmap.LatLng(p.latitude, p.longitude))
                          .toList(),
                      color: Theme.of(context).primaryColor,
                      width: 5,
                    ),
                },
                compassEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                myLocationEnabled: false,
              )
              : FlutterMap(
            mapController: _fallbackMapController,
            options: MapOptions(
              initialCenter: _waypoints.isNotEmpty ? _waypoints.first : _paranaqueCenter,
              initialZoom: 13.5,
              onTap: (tapPosition, point) => _handleMapTap(point),
              minZoom: 2.0,
              maxZoom: 18.0,
              // Disable gestures when scrolling or input fields have focus
              interactionOptions: InteractionOptions(
                flags: _shouldDisableMapGestures
                    ? InteractiveFlag.none
                    : InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.byahero',
              ),
              PolylineLayer(
                polylines: [
                  if (_displayRoute.isNotEmpty)
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  if (_waypoints.length > 1)
                    Marker(
                      point: _waypoints.last,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          )
              : Container(
                color: Colors.grey[100],
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Map Unavailable',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ORS API Key is missing. Please add ORS_API_KEY to your .env file.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Go Back', style: GoogleFonts.poppins()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ),
        // Loading Indicator
        if (_isRouting)
          Positioned(
            top: 200, // Move even further below the header container
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
          top: 200, // Position well below the header container
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: "undo",
                onPressed: _undoPoint,
                backgroundColor: Colors.white,
                tooltip: 'Undo last point',
                child: Icon(Icons.undo, color: Colors.black87),
              ),
              SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: "clear",
                onPressed: _clearPoints,
                backgroundColor: Colors.white,
                tooltip: 'Clear route',
                child: Icon(Icons.delete_outline, color: Colors.red),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Route Details",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
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
                    _fareController,
                    'Fare (₱)',
                    Icons.payments,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 80),
          ],
        ),
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
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          width: constraints.maxWidth,
          expandedInsets: EdgeInsets.zero,
          initialSelection: _vehicleType,
          enableSearch: false,
          requestFocusOnTap: false,
          enableFilter: false,
          leadingIcon: Icon(
            _vehicleType == 'jeepney'
                ? Icons.directions_bus
                : _vehicleType == 'minibus'
                    ? Icons.airport_shuttle
                    : Icons.electric_car,
            size: 18,
            color: const Color(0xFF0F766E),
          ),
          label: Text(
            'Vehicle Type',
            style: GoogleFonts.poppins(color: Colors.grey[700]),
          ),
          textStyle: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
          onSelected: (val) {
            if (val != null && mounted) setState(() => _vehicleType = val);
          },
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          menuStyle: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.white),
            elevation: const WidgetStatePropertyAll(6),
            padding:
                const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
            fixedSize: WidgetStatePropertyAll(
              Size.fromWidth(constraints.maxWidth),
            ),
          ),
          dropdownMenuEntries: ['jeepney', 'minibus', 'ejeepney']
              .map(
                (type) => DropdownMenuEntry<String>(
                  value: type,
                  label: type.toUpperCase(),
                  leadingIcon: Icon(
                    type == 'jeepney'
                        ? Icons.directions_bus
                        : type == 'minibus'
                            ? Icons.airport_shuttle
                            : Icons.electric_car,
                    size: 18,
                    color: const Color(0xFF0F766E),
                  ),
                ),
              )
              .toList(),
        );
      },
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
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
