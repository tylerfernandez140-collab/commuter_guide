import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/route_model.dart';
import 'route_details_screen.dart';

class CommuterHomeScreen extends StatefulWidget {
  const CommuterHomeScreen({Key? key}) : super(key: key);

  @override
  _CommuterHomeScreenState createState() => _CommuterHomeScreenState();
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
      setState(() {
        _allRoutes = routes;
        _isLoadingRoutes = false;
      });
    } catch (e) {
      print('Error loading routes: $e');
      setState(() => _isLoadingRoutes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hello, Commuter!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () {
                          Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).logout();
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Where do you want to go today?',
                    style: TextStyle(fontSize: 16, color: Colors.teal.shade50),
                  ),
                  const SizedBox(height: 24),

                  // Search Bar inside Header
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return RawAutocomplete<Object>(
                        textEditingController: _searchController,
                        focusNode: _focusNode,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Object>.empty();
                          }
                          final query = textEditingValue.text.toLowerCase();
                          final matches = _allRoutes.where((route) {
                            return route.routeName.toLowerCase().contains(
                                  query,
                                ) ||
                                route.startPoint.toLowerCase().contains(
                                  query,
                                ) ||
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
                        displayStringForOption: (Object option) {
                          if (option is RouteModel) {
                            return option.routeName;
                          }
                          return option.toString();
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              return CompositedTransformTarget(
                                link: _layerLink,
                                child: TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search routes, stops, or landmarks...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Colors.teal,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: CompositedTransformFollower(
                              link: _layerLink,
                              showWhenUnlinked: false,
                              targetAnchor: Alignment.bottomLeft,
                              offset: const Offset(0, 5),
                              child: Material(
                                elevation: 8.0,
                                borderRadius: BorderRadius.circular(15),
                                clipBehavior: Clip.antiAlias,
                                child: Container(
                                  width: constraints.maxWidth,
                                  color: Colors.white,
                                  constraints: const BoxConstraints(
                                    maxHeight: 300,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final option = options.elementAt(index);

                                      if (option is String) {
                                        return ListTile(
                                          title: Text(
                                            option,
                                            style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        );
                                      }

                                      final route = option as RouteModel;
                                      return ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.directions_bus,
                                            color: Colors.teal,
                                          ),
                                        ),
                                        title: Text(
                                          route.routeName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${route.startPoint} - ${route.endPoint}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () {
                                          onSelected(route);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        onSelected: (Object selection) {
                          if (selection is RouteModel) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RouteDetailsScreen(route: selection),
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

            // Body Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingRoutes)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Popular Destinations',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Implement view all logic if needed
                          },
                          child: const Text('View All'),
                        ),
                      ],
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
                        _buildSuggestionCard(
                          'SM Sucat',
                          'https://images.unsplash.com/photo-1569388330292-7a6a84165c6c?q=80&w=400&auto=format&fit=crop',
                        ),
                        _buildSuggestionCard(
                          'NAIA Terminal 1',
                          'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?q=80&w=400&auto=format&fit=crop',
                        ),
                        _buildSuggestionCard(
                          'City Hall',
                          'https://images.unsplash.com/photo-1577493340887-b7bfff550145?q=80&w=400&auto=format&fit=crop',
                        ),
                        _buildSuggestionCard(
                          'Baclaran',
                          'https://images.unsplash.com/photo-1548625361-987702f30b92?q=80&w=400&auto=format&fit=crop',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(String title, String imageUrl) {
    return GestureDetector(
      onTap: () {
        // Try to find a matching route
        try {
          final match = _allRoutes.firstWhere(
            (r) =>
                r.routeName.toLowerCase().contains(title.toLowerCase()) ||
                r.endPoint.toLowerCase().contains(title.toLowerCase()) ||
                r.landmarks.any(
                  (l) => l.toLowerCase().contains(title.toLowerCase()),
                ),
          );

          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RouteDetailsScreen(route: match)),
          );
        } catch (e) {
          // If no direct match found, fill search
          _searchController.text = title;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
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
              Image.network(
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
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
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
                        children: const [
                          Icon(
                            Icons.location_on,
                            color: Colors.tealAccent,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tap to view',
                            style: TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 10,
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
