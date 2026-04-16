import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/stats_service.dart';
import 'login_screen.dart';
import '../widgets/shimmer.dart';
import 'manage_routes_screen.dart';
import 'add_edit_route_screen.dart';
import 'manage_landmarks_screen.dart';
import 'add_edit_landmark_screen.dart';
import 'suggestions_review_screen.dart';
import 'manage_users_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> stats = {
    'routes': 0,
    'landmarks': 0,
    'pendingSuggestions': 0,
    'users': 0,
  };
  bool isLoading = true;
  static const double _radius = 28.0;
  static const double _gapSmall = 12.0;
  int _currentTab = 0;
  DateTime? _skeletonUntil;
  static const Duration _minSkeleton = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _loadStats();
    _skeletonUntil = DateTime.now().add(_minSkeleton);
    Future.delayed(_minSkeleton, () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadStats({bool forceRefresh = false}) async {
    final dashboardStats = await StatsService.getDashboardStats(forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        stats = dashboardStats;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F766E),
                Color(0xFF2DD4BF),
              ],
            ),
          ),
          child: LayoutBuilder(
          builder: (context, constraints) {
            final showSkeleton = isLoading || (_skeletonUntil != null && DateTime.now().isBefore(_skeletonUntil!));
            return RefreshIndicator(
              color: Colors.black,
              onRefresh: () async {
                _skeletonUntil = DateTime.now().add(_minSkeleton);
                Future.delayed(_minSkeleton, () {
                  if (mounted) setState(() {});
                });
                if (mounted) setState(() => isLoading = true);
                await _loadStats(forceRefresh: true);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overview',
                              style: GoogleFonts.poppins(
                                fontSize: MediaQuery.textScalerOf(context).scale(20),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            (showSkeleton
                              ? _buildSkeletonGrid(constraints)
                              : GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  crossAxisCount: constraints.maxWidth < 330 ? 1 : 2,
                                  childAspectRatio: 1.05,
                                  children: [
                                    _buildOverviewInfoCard(
                                      context,
                                      title: 'Routes',
                                      count: stats['routes'] ?? 0,
                                      singular: 'Route',
                                      plural: 'Routes',
                                      icon: Icons.map_outlined,
                                      color: const Color(0xFF0F766E),
                                    ),
                                    _buildOverviewInfoCard(
                                      context,
                                      title: 'Landmarks',
                                      count: stats['landmarks'] ?? 0,
                                      singular: 'Location',
                                      plural: 'Locations',
                                      icon: Icons.place_outlined,
                                      color: const Color(0xFFF59E0B),
                                    ),
                                    _buildOverviewInfoCard(
                                      context,
                                      title: 'Suggestions',
                                      count: stats['pendingSuggestions'] ?? 0,
                                      singular: 'Pending',
                                      plural: 'Pendings',
                                      icon: Icons.rate_review_outlined,
                                      color: const Color(0xFF2DD4BF),
                                      zeroAsSingular: true,
                                    ),
                                    _buildStatCard(
                                      context,
                                      'User',
                                      stats['users'] ?? 0,
                                      Icons.people_outline,
                                      const Color(0xFF0F766E),
                                    ),
                                  ],
                                )),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Actions',
                                  style: GoogleFonts.poppins(
                                    fontSize: MediaQuery.textScalerOf(context).scale(18),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                (showSkeleton
                                  ? _buildQuickActionsSkeletonGrid()
                                  : GridView.count(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1,
                                      children: [
                                        _quickActionCard(
                                          context,
                                          label: 'Add Route',
                                          icon: Icons.add_road,
                                          color: const Color(0xFF0F766E),
                                          onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const AddEditRouteScreen()),
                                        );
                                          },
                                        ),
                                        _quickActionCard(
                                          context,
                                          label: 'Add Landmark',
                                          icon: Icons.add_location_alt,
                                          color: const Color(0xFFF59E0B),
                                          onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const AddEditLandmarkScreen()),
                                        );
                                          },
                                        ),
                                        _quickActionCard(
                                          context,
                                          label: 'Review Suggestions',
                                          icon: Icons.rate_review,
                                          color: const Color(0xFF60A5FA),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => SuggestionsReviewScreen()),
                                            );
                                          },
                                        ),
                                        _quickActionCard(
                                          context,
                                          label: 'Broadcast Notice',
                                          icon: Icons.campaign,
                                          color: const Color(0xFFA78BFA),
                                          onTap: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Broadcast coming soon', style: GoogleFonts.poppins())),
                                            );
                                          },
                                        ),
                                      ],
                                    )),
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
          },
        ),
      ),
      ),
      bottomNavigationBar: Container(
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
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          currentIndex: _currentTab,
          onTap: (i) {
            setState(() => _currentTab = i);
            if (i == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ManageRoutesScreen()),
              );
            } else if (i == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ManageLandmarksScreen()),
              );
            } else if (i == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
              );
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
 
  Widget _quickActionCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final iconSize = w >= 220 ? 40.0 : w >= 180 ? 36.0 : 32.0;
            final ts = MediaQuery.textScalerOf(context);
            final titleSize = ts.scale(w >= 220 ? 17.0 : w >= 180 ? 16.0 : 15.0);
            final pad = w >= 220 ? 16.0 : 14.0;
            final gap = w >= 220 ? 14.0 : 12.0;
            return Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: iconSize, color: color),
                  ),
                  SizedBox(height: gap),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  Widget _buildHeader(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final titleSize = width < 360 ? 22.0 : 28.0;
    final subtitleSize = width < 360 ? 14.0 : 16.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 56),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Welcome, Admin!',
                        style: GoogleFonts.poppins(
                          fontSize: MediaQuery.textScalerOf(context).scale(titleSize),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Profile',
                icon: const Icon(Icons.account_circle, color: Colors.white, size: 32),
                onPressed: () => _showProfileDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your transport system efficiently.',
            style: GoogleFonts.poppins(
              fontSize: MediaQuery.textScalerOf(context).scale(subtitleSize), 
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

 
 
  Widget _buildSkeletonGrid(BoxConstraints constraints) {
    final cols = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth < 330 ? 1 : 2;
    final items = List.generate(4, (_) => _buildSkeletonCard());
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: cols,
      crossAxisSpacing: 16,
      mainAxisSpacing: 12,
      childAspectRatio: constraints.maxWidth < 360
          ? 0.88
          : constraints.maxWidth < 480
              ? 1.0
              : constraints.maxWidth < 900
                  ? 1.12
                  : 1.15,
      children: items,
    );
  }

  Widget _buildQuickActionsSkeletonGrid() {
    final items = List.generate(4, (_) => _buildQuickActionSkeletonCard());
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
      children: items,
    );
  }

  Widget _buildQuickActionSkeletonCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Shimmer(
              child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            ),
            const SizedBox(height: 12),
            Shimmer(
              child: Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

 
  Widget _buildSkeletonCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Shimmer(
              child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            ),
            const SizedBox(height: _gapSmall),
            Shimmer(
              child: Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            ),
            const SizedBox(height: _gapSmall),
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
      ),
    );
  }

 

  Widget _buildOverviewInfoCard(
    BuildContext context, {
    required String title,
    required int count,
    required String singular,
    required String plural,
    required IconData icon,
    required Color color,
    bool zeroAsSingular = false,
  }) {
    final label = (count == 1 || (zeroAsSingular && count == 0)) ? singular : plural;
    final ts = MediaQuery.textScalerOf(context);
    final subSize = ts.scale(13.0);
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      color: Colors.white.withValues(alpha: 0.95),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final iconSize = w >= 220 ? 40.0 : w >= 180 ? 36.0 : 32.0;
          final titleSize = ts.scale(w >= 220 ? 17.0 : w >= 180 ? 16.0 : 15.0);
          final pad = w >= 220 ? 16.0 : 14.0;
          final gap = w >= 220 ? 14.0 : 12.0;
          return Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: iconSize, color: color),
                ),
                SizedBox(height: gap),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$count',
                        style: GoogleFonts.poppins(
                          fontSize: subSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                      TextSpan(
                        text: ' $label',
                        style: GoogleFonts.poppins(
                          fontSize: subSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String titleBase,
    int count,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      color: Colors.white.withValues(alpha: 0.95),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final iconSize = w >= 220 ? 42.0 : w >= 180 ? 38.0 : 36.0;
          final ts = MediaQuery.textScalerOf(context);
          final countSize = ts.scale(w >= 220 ? 26.0 : 24.0);
          final titleSize = ts.scale(w >= 220 ? 13.0 : 12.0);
          final pad = w >= 220 ? 18.0 : 16.0;
          final gap = w >= 220 ? 14.0 : 12.0;
          final displayTitle = 'Total ${count == 1 ? titleBase : '${titleBase}s'}';
          return Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize, color: color),
                SizedBox(height: gap),
                Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: countSize,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  displayTitle,
                  style: GoogleFonts.poppins(
                    fontSize: titleSize,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
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
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text('Logout', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Color(0xFF0F766E), size: 24),
            ),
            const SizedBox(width: 12),
            Text('Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProfileItem(Icons.badge, 'Name', user?.fullName ?? 'Admin'),
              const Divider(height: 24),
              _buildProfileItem(Icons.email, 'Email', user?.email ?? '-'),
              const Divider(height: 24),
              _buildProfileItem(Icons.admin_panel_settings, 'Role', 'System Administrator'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Future.delayed(const Duration(milliseconds: 100), () {
                _showLogoutDialog(context);
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout, size: 18, color: Colors.red),
                const SizedBox(width: 4),
                Text('Logout', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
              Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}
