import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/landmark.dart';
import '../models/route_model.dart';
import '../services/api_service.dart';

class AddEditLandmarkScreen extends StatefulWidget {
  final Landmark? landmark;
  const AddEditLandmarkScreen({super.key, this.landmark});

  @override
  State<AddEditLandmarkScreen> createState() => _AddEditLandmarkScreenState();
}

class _AddEditLandmarkScreenState extends State<AddEditLandmarkScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _nearRouteController;
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();

  static const LatLng _defaultCenter = LatLng(14.4793, 121.0195);

  bool _isSaving = false;
  List<RouteModel> _routes = [];
  RouteModel? _selectedRoute;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.landmark?.name ?? '');
    _typeController = TextEditingController(text: widget.landmark?.type ?? '');
    _nearRouteController = TextEditingController(text: widget.landmark?.nearRoute ?? '');
    if (widget.landmark != null) {
      _selectedLocation = LatLng(widget.landmark!.latitude, widget.landmark!.longitude);
    }
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final routes = await api.getRoutes();
      setState(() => _routes = routes ?? []);
      // If editing and has near route, select it
      if (widget.landmark?.nearRoute != null && widget.landmark!.nearRoute.isNotEmpty) {
        final matching = _routes.where((r) => r.routeName == widget.landmark!.nearRoute).toList();
        if (matching.isNotEmpty) {
          _selectRoute(matching.first);
        }
      }
    } catch (e) {
      debugPrint('Error fetching routes: $e');
      setState(() => _routes = []);
    }
  }

  void _selectRoute(RouteModel route) {
    setState(() {
      _selectedRoute = route;
      _nearRouteController.text = route.routeName ?? '';
      _routePoints = [];
      if (route.coordinates.isNotEmpty) {
        for (var c in route.coordinates) {
          if (c['lat'] != null && c['lng'] != null) {
            _routePoints.add(LatLng(c['lat']!, c['lng']!));
          }
        }
      }
    });
    // Fit bounds to show route
    if (_routePoints.isNotEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
      });
    }
  }

  void _fitBounds() {
    if (_routePoints.isEmpty) return;
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (var p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  void _showRoutePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
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
                    'Select Near Route',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_routes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No routes available'),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _routes.length,
                      itemBuilder: (context, index) {
                        final route = _routes[index];
                        final isSelected = _selectedRoute?.id == route.id;
                        return ListTile(
                          leading: Icon(
                            Icons.directions_bus,
                            color: isSelected ? const Color(0xFF0F766E) : Colors.grey,
                          ),
                          title: Text(route.routeName ?? 'Unnamed Route'),
                          subtitle: Text('${route.startPoint ?? '-'} - ${route.endPoint ?? '-'}'),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Color(0xFF0F766E))
                              : null,
                          onTap: () {
                            _selectRoute(route);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _nearRouteController.dispose();
    super.dispose();
  }

  void _handleMapTap(LatLng point) {
    setState(() => _selectedLocation = point);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap on the map to set landmark location'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final lm = Landmark(
        id: widget.landmark?.id ?? '',
        name: _nameController.text,
        type: _typeController.text,
        nearRoute: _nearRouteController.text,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );
      final api = Provider.of<ApiService>(context, listen: false);
      if (widget.landmark == null) {
        await api.createLandmark(lm);
      } else {
        await api.updateLandmark(widget.landmark!.id, lm);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.landmark == null ? 'Landmark created' : 'Landmark updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.landmark == null ? 'New Landmark' : 'Edit Landmark';
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
                      'Tap map to set landmark location',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Map Section
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ?? _defaultCenter,
                    initialZoom: 14,
                    onTap: (tapPosition, point) => _handleMapTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.commuter_guide',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 4.0,
                            color: const Color(0xFF0F766E),
                          ),
                        ],
                      ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.flag, color: Colors.green, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Form Section
              Container(
                height: 280,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildTextField(_nameController, 'Name', Icons.label_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_typeController, 'Type', Icons.category_outlined),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _showRoutePicker,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Near Route',
                                  labelStyle: const TextStyle(color: Colors.black87),
                                  floatingLabelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                                  prefixIcon: const Icon(Icons.alt_route, size: 20, color: Colors.black54),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                child: Text(
                                  _nearRouteController.text.isEmpty ? 'Select route' : _nearRouteController.text,
                                  style: TextStyle(
                                    color: _nearRouteController.text.isEmpty ? Colors.black54 : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _save,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.save, size: 20),
                                label: Text(
                                  'Save',
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
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
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

}
