import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/stats_service.dart';
import 'login_screen.dart';
import 'manage_routes_screen.dart';
import 'manage_landmarks_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats({bool forceRefresh = false}) async {
    final dashboardStats = await StatsService.getDashboardStats(forceRefresh: forceRefresh);
    setState(() {
      stats = dashboardStats;
      isLoading = false;
    });
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
            return RefreshIndicator(
              onRefresh: () async {
                setState(() => isLoading = true);
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
                            (isLoading
                              ? _buildSkeletonGrid(constraints)
                              : GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  crossAxisCount: constraints.maxWidth < 330 ? 1 : 2,
                                  childAspectRatio: 1.05,
                                  children: [
                                    _buildDashboardCard(
                                      context,
                                      'Manage Routes',
                                      '${stats['routes']} Active',
                                      Icons.map_outlined,
                                      const Color(0xFF0F766E),
                                      ManageRoutesScreen(),
                                    ),
                                    _buildDashboardCard(
                                      context,
                                      'Manage Landmarks',
                                      '${stats['landmarks']} Location${stats['landmarks'] == 1 ? '' : 's'}',
                                      Icons.place_outlined,
                                      const Color(0xFFF59E0B),
                                      ManageLandmarksScreen(),
                                    ),
                                    _buildDashboardCard(
                                      context,
                                      'Review Suggestions',
                                      '${stats['pendingSuggestions']} Pending${stats['pendingSuggestions'] == 1 ? '' : 's'}',
                                      Icons.rate_review_outlined,
                                      const Color(0xFF2DD4BF),
                                      SuggestionsReviewScreen(),
                                    ),
                                    _buildStatCard(
                                      context,
                                      'Total Users',
                                      '${stats['users']}',
                                      Icons.people_outline,
                                      const Color(0xFF0F766E),
                                    ),
                                  ],
                                )),
                            const SizedBox(height: 16),
                            Text(
                              'Quick Actions',
                              style: GoogleFonts.poppins(
                                fontSize: MediaQuery.textScalerOf(context).scale(18),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ManageRoutesScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.add_road),
                                  label: Text('Add Route', style: GoogleFonts.poppins()),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F766E),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ManageLandmarksScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.add_location_alt),
                                  label: Text('Add Landmark', style: GoogleFonts.poppins()),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Broadcast coming soon', style: GoogleFonts.poppins())),
                                    );
                                  },
                                  icon: const Icon(Icons.campaign),
                                  label: Text('Broadcast Notice', style: GoogleFonts.poppins()),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2DD4BF),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
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
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
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
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () {
                  _showLogoutDialog(context);
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                ),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: _gapSmall),
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: _gapSmall),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      color: Colors.white.withValues(alpha: 0.95),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        borderRadius: BorderRadius.circular(_radius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final iconSize = w >= 220 ? 40.0 : w >= 180 ? 36.0 : 32.0;
            final ts = MediaQuery.textScalerOf(context);
            final titleSize = ts.scale(w >= 220 ? 17.0 : w >= 180 ? 16.0 : 15.0);
            final subSize = ts.scale(w >= 220 ? 13.0 : w >= 180 ? 12.0 : 11.0);
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
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: subSize,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
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

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String count,
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
          return Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize, color: color),
                SizedBox(height: gap),
                Text(
                  count,
                  style: GoogleFonts.poppins(
                    fontSize: countSize,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  title,
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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
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
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
