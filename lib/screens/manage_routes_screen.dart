import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/route_model.dart';
import '../services/api_service.dart';
import 'add_edit_route_screen.dart';
import 'manage_landmarks_screen.dart';
import 'manage_users_screen.dart';
import '../widgets/shimmer.dart';

class ManageRoutesScreen extends StatefulWidget {
  const ManageRoutesScreen({super.key});
  @override
  State<ManageRoutesScreen> createState() => _ManageRoutesScreenState();
}

class _ManageRoutesScreenState extends State<ManageRoutesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<RouteModel>> _routesFuture;
  DateTime? _skeletonUntil;
  static const Duration _minSkeleton = Duration(seconds: 1);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshRoutes();
    _skeletonUntil = DateTime.now().add(_minSkeleton);
    Future.delayed(_minSkeleton, () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _refreshRoutes() async {
    setState(() {
      _isLoading = true;
    });
    ApiService.clearRoutesCache();
    await _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _routesFuture = _apiService.getRoutes();
    });
  }

  Future<void> _deleteRoute(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _apiService.deleteRoute(id);
        _refreshRoutes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Route deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
              color: Colors.black,
              onRefresh: () async {
                _skeletonUntil = DateTime.now().add(_minSkeleton);
                Future.delayed(_minSkeleton, () {
                  if (mounted) setState(() {});
                });
                setState(() {
                  _routesFuture = _apiService.getRoutes(forceRefresh: true);
                });
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      _buildHeader(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: FutureBuilder<List<RouteModel>>(
                          future: _routesFuture,
                          builder: (context, snapshot) {
                            final showSkeleton = snapshot.connectionState == ConnectionState.waiting ||
                                (_skeletonUntil != null && DateTime.now().isBefore(_skeletonUntil!));
                            if (showSkeleton) {
                              final expected = ApiService.routesCachedCount ?? 6;
                              return _buildRouteSkeletonList(expected);
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: GoogleFonts.poppins(color: Colors.white),
                                ),
                              );
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Text(
                                  'No routes found',
                                  style: GoogleFonts.poppins(color: Colors.white),
                                ),
                              );
                            }
                            final routes = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: routes.length,
                              itemBuilder: (context, index) {
                                final route = routes[index];
                                return Card(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      route.routeName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${route.startPoint} - ${route.endPoint}',
                                      style: GoogleFonts.poppins(color: Colors.grey[700]),
                                    ),
                                    trailing: Padding(
                                      padding: const EdgeInsets.only(right: 48),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Color(0xFF0F766E)),
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AddEditRouteScreen(route: route),
                                                ),
                                              );
                                              _refreshRoutes();
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteRoute(route.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditRouteScreen()),
          );
          _refreshRoutes();
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          currentIndex: 1,
          onTap: (i) {
            switch (i) {
              case 0:
                Navigator.pushReplacementNamed(context, '/dashboard');
                break;
              case 1:
                break;
              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageLandmarksScreen()),
                );
                break;
              case 3:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.alt_route), label: 'Routes'),
            BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Landmarks'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSkeletonList([int count = 6]) {
    return Column(
      children: List.generate(count, (index) {
        return Card(
          color: Colors.white.withValues(alpha: 0.95),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer(
                        child: Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer(
                        child: Container(
                        width: 180,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 48),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Shimmer(
                        child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      ),
                      const SizedBox(width: 8),
                      Shimmer(
                        child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
              ),
              const SizedBox(width: 8),
              Text(
                'Manage Routes',
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
              'Add, edit, or remove commute routes.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
