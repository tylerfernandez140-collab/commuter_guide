import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/route_model.dart';
import '../../screens/login_screen.dart';
import 'route_details_screen.dart';
import 'commuter_map_screen.dart';

class CommuterHomeScreen extends StatefulWidget {
  const CommuterHomeScreen({super.key});

  @override
  State<CommuterHomeScreen> createState() => _CommuterHomeScreenState();
}

class _CommuterHomeScreenState extends State<CommuterHomeScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  List<RouteModel> _allRoutes = [];
  bool _isLoadingRoutes = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    try {
      final routes = await Provider.of<ApiService>(
        context,
        listen: false,
      ).getRoutes();
      if (mounted) {
        setState(() {
          _allRoutes = routes;
          _isLoadingRoutes = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading routes: $e');
      if (mounted) {
        setState(() => _isLoadingRoutes = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F766E),
              Color(0xFF2DD4BF),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hello, Commuter!',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.account_circle,
                            color: Colors.white,
                            size: 32,
                          ),
                          onSelected: (value) {
                            if (value == 'logout') {
                              _showLogoutDialog(context);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'logout',
                              child: Text('Logout'),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Where do you want to go today?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),

                    const SizedBox(height: 24),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        return RawAutocomplete<Object>(
                          textEditingController: _searchController,
                          focusNode: _focusNode,
                          optionsBuilder: (textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<Object>.empty();
                            }

                            final query = textEditingValue.text.toLowerCase();

                            final matches = _allRoutes.where((route) {
                              return route.routeName.toLowerCase().contains(query) ||
                                  route.startPoint.toLowerCase().contains(query) ||
                                  route.endPoint.toLowerCase().contains(query) ||
                                  route.landmarks.any(
                                    (l) => l.toLowerCase().contains(query),
                                  );
                            }).toList();

                            if (matches.isEmpty) {
                              return ['No route found'];
                            }

                            return matches;
                          },
                          displayStringForOption: (option) {
                            if (option is RouteModel) {
                              return option.routeName;
                            }
                            return option.toString();
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: 'Search routes, stops, or landmarks...',
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                width: constraints.maxWidth,
                                constraints: const BoxConstraints(maxHeight: 300),
                                color: Colors.white,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);

                                    if (option is String) {
                                      return ListTile(title: Text(option));
                                    }

                                    final route = option as RouteModel;

                                    return ListTile(
                                      title: Text(route.routeName),
                                      subtitle: Text('${route.startPoint} - ${route.endPoint}'),
                                      onTap: () => onSelected(route),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          onSelected: (selection) {
                            if (selection is RouteModel) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RouteDetailsScreen(route: selection),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: _isLoadingRoutes
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Popular Destinations',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                            children: [
                              _buildSuggestionCard('Baclaran Church', 'baclaran_church.jpg', const LatLng(14.5314, 120.9950)),
                              _buildSuggestionCard('Dream Play', 'dream_play.jpg', const LatLng(14.5246791, 120.9913930)),
                              _buildSuggestionCard('Okada Manila', 'okada_manila.jpg', const LatLng(14.5153, 120.9811)),
                              _buildSuggestionCard('Wetland Park', 'wetland_park.jpg', const LatLng(22.4701, 114.0066)),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(String title, String imageUrl, LatLng destination) {
    return GestureDetector(
      onTap: () {
        // Navigate to map with directions to this destination
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CommuterMapScreen(
              destination: destination,
              destinationName: title,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app,
                            color: Colors.tealAccent,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap for directions',
                            style: TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.black87)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: Text('Logout', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
