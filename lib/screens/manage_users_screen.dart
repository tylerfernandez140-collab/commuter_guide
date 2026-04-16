import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import 'manage_routes_screen.dart';
import 'manage_landmarks_screen.dart';
import '../widgets/shimmer.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  late Future<List<User>> _usersFuture;
  User? _currentUser;
  DateTime? _skeletonUntil;
  static const Duration _minSkeleton = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _currentUser = auth.user;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentUser == null || _currentUser?.role != 'admin') {
        Navigator.pushReplacementNamed(context, '/commuter-home');
      }
    });
    _refreshUsers();
    _skeletonUntil = DateTime.now().add(_minSkeleton);
    Future.delayed(_minSkeleton, () {
      if (mounted) setState(() {});
    });
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = Provider.of<ApiService>(context, listen: false).getUsers();
    });
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
                    _usersFuture = Provider.of<ApiService>(context, listen: false)
                        .getUsers(forceRefresh: true);
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
                          child: FutureBuilder<List<User>>(
                            future: _usersFuture,
                            builder: (context, snapshot) {
                              final showSkeleton = snapshot.connectionState == ConnectionState.waiting ||
                                  (_skeletonUntil != null && DateTime.now().isBefore(_skeletonUntil!));
                              if (showSkeleton) {
                                final expected = ApiService.usersCachedCount ?? 8;
                                return _buildUserSkeletonList(expected);
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
                                    'No users found',
                                    style: GoogleFonts.poppins(color: Colors.white),
                                  ),
                                );
                              }
                              final users = snapshot.data!
                                  .where((u) =>
                                      (_currentUser == null || u.id != _currentUser!.id) &&
                                      u.role != 'admin')
                                  .toList();
                              if (users.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No users found',
                                    style: GoogleFonts.poppins(color: Colors.white),
                                  ),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(0),
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final u = users[index];
                                  return Card(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFF0F766E),
                                        foregroundColor: Colors.white,
                                        child: Text(
                                          u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(
                                        u.fullName,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(u.email, style: GoogleFonts.poppins(color: Colors.grey[700])),
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.badge, size: 14, color: Color(0xFF0F766E)),
                                              const SizedBox(width: 4),
                                              Text(
                                                u.role.toUpperCase(),
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF0F766E),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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
          currentIndex: 3,
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageLandmarksScreen()),
                );
                break;
              case 3:
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

  Widget _buildUserSkeletonList([int count = 8]) {
    return Column(
      children: List.generate(count, (index) {
        return Card(
          color: Colors.white.withValues(alpha: 0.95),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Shimmer(
              child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE0E0E0),
                shape: BoxShape.circle,
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
                const SizedBox(height: 4),
                Shimmer(
                  child: Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Shimmer(
                      child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    ),
                    const SizedBox(width: 6),
                    Shimmer(
                      child: Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    ),
                  ],
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
                'Manage Users',
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
              'View registered users.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
