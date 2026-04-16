import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/landmark.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'manage_routes_screen.dart';
import 'add_edit_landmark_screen.dart';
import 'manage_users_screen.dart';
import '../widgets/shimmer.dart';

class ManageLandmarksScreen extends StatefulWidget {
  final bool openAdd;
  const ManageLandmarksScreen({super.key, this.openAdd = false});

  @override
  State<ManageLandmarksScreen> createState() => _ManageLandmarksScreenState();
}

class _ManageLandmarksScreenState extends State<ManageLandmarksScreen> {
  late Future<List<Landmark>> _landmarksFuture;
  bool _isLoading = false;
  DateTime? _skeletonUntil;
  static const Duration _minSkeleton = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _refreshLandmarks();
    _skeletonUntil = DateTime.now().add(_minSkeleton);
    Future.delayed(_minSkeleton, () {
      if (mounted) setState(() {});
    });
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final created = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const AddEditLandmarkScreen()),
        );
        if (created == true && mounted) {
          _refreshLandmarks();
        }
      });
    }
  }

  void _refreshLandmarks() {
    setState(() {
      _landmarksFuture = Provider.of<ApiService>(
        context,
        listen: false,
      ).getLandmarks();
    });
  }

  Future<void> _deleteLandmark(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this landmark?'),
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
        if (!mounted) return;
        final api = Provider.of<ApiService>(context, listen: false);
        await api.deleteLandmark(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Landmark deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _refreshLandmarks();
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
                  _landmarksFuture = Provider.of<ApiService>(
                    context,
                    listen: false,
                  ).getLandmarks(forceRefresh: true);
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
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                              )
                            : FutureBuilder<List<Landmark>>(
                                future: _landmarksFuture,
                                builder: (context, snapshot) {
                                  final showSkeleton = snapshot.connectionState == ConnectionState.waiting ||
                                      (_skeletonUntil != null && DateTime.now().isBefore(_skeletonUntil!));
                                  if (showSkeleton) {
                                    final expected = ApiService.landmarksCachedCount ?? 6;
                                    return _buildLandmarkSkeletonList(expected);
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: Colors.red[300],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Error: ${snapshot.error}',
                                            style: GoogleFonts.poppins(color: Colors.white),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: _refreshLandmarks,
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return _buildEmptyState();
                                  }
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      final landmark = snapshot.data![index];
                                      return _buildLandmarkCard(landmark);
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
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddEditLandmarkScreen()),
          );
          if (created == true) {
            _refreshLandmarks();
          }
        },
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
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
          currentIndex: 2,
          onTap: (i) {
            switch (i) {
              case 0:
                Navigator.pushReplacementNamed(context, '/dashboard');
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageRoutesScreen()),
                );
                break;
              case 2:
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
                'Manage Landmarks',
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
              'Add, edit, or remove map locations.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No landmarks yet',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add one.',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildLandmarkCard(Landmark landmark) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2DD4BF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconForType(landmark.type),
            color: const Color(0xFF0F766E),
            size: 28,
          ),
        ),
        title: Text(
          landmark.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(landmark.type, style: GoogleFonts.poppins(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.near_me, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Near: ${landmark.nearRoute}',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
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
                      builder: (context) => AddEditLandmarkScreen(landmark: landmark),
                    ),
                  );
                  _refreshLandmarks();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteLandmark(landmark.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandmarkSkeletonList([int count = 6]) {
    return Column(
      children: List.generate(count, (index) {
        return Card(
          elevation: 8,
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Shimmer(
              child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            ),
            title: Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Shimmer(
                  child: Container(
                  width: 160,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                ),
                const SizedBox(height: 6),
                Shimmer(
                  child: Container(
                  width: 220,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                ),
              ],
            ),
            trailing: Padding(
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
          ),
        );
      }),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'terminal':
        return Icons.directions_bus;
      case 'mall':
        return Icons.shopping_bag;
      case 'school':
        return Icons.school;
      case 'hospital':
        return Icons.local_hospital;
      case 'park':
        return Icons.park;
      default:
        return Icons.place;
    }
  }
}
