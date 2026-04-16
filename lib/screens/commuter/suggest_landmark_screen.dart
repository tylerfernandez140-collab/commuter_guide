import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'commuter_main_screen.dart';

class SuggestLandmarkScreen extends StatefulWidget {
  const SuggestLandmarkScreen({super.key});

  @override
  State<SuggestLandmarkScreen> createState() => _SuggestLandmarkScreenState();
}

class _SuggestLandmarkScreenState extends State<SuggestLandmarkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();

  static const LatLng _defaultCenter = LatLng(14.4793, 121.0195);

  bool _isLoading = false;

  void _handleMapTap(LatLng point) {
    setState(() => _selectedLocation = point);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap on the map to set landmark location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<ApiService>(context, listen: false).submitSuggestion(
        _nameController.text,
        _typeController.text,
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestion submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _nameController.clear();
        _typeController.clear();
        setState(() => _selectedLocation = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            // Go back to Search tab (index 0) instead of popping
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const CommuterMainScreen(initialIndex: 0)),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Suggest a Landmark',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap on the map to set landmark location',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Map Section
              Expanded(
                flex: 2,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _defaultCenter,
                    initialZoom: 14,
                    onTap: (tapPosition, point) => _handleMapTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.commuter_guide',
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
                height: 200,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Info note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your suggestion will be reviewed by an admin before appearing on the map.',
                                style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Landmark Name',
                          labelStyle: const TextStyle(color: Colors.black87),
                          floatingLabelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                          prefixIcon: const Icon(Icons.place, size: 20, color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      // Type field and Submit button
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _typeController,
                              decoration: InputDecoration(
                                labelText: 'Type',
                                hintText: 'e.g., Church, Mall, Park',
                                labelStyle: const TextStyle(color: Colors.black87),
                                floatingLabelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                                prefixIcon: const Icon(Icons.category, size: 20, color: Colors.black54),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _submit,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.send, size: 20),
                                label: Text(
                                  'Submit',
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
}
