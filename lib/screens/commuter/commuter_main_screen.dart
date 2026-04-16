import 'package:flutter/material.dart';
import 'commuter_home_screen.dart';
import 'commuter_map_screen.dart';
import 'chat_screen.dart';
import 'suggest_landmark_screen.dart';

class CommuterMainScreen extends StatefulWidget {
  final int initialIndex;

  const CommuterMainScreen({super.key, this.initialIndex = 0});

  @override
  State<CommuterMainScreen> createState() => _CommuterMainScreenState();
}

class _CommuterMainScreenState extends State<CommuterMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const CommuterHomeScreen(),
    const CommuterMapScreen(),
    const ChatScreen(),
    const SuggestLandmarkScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If not on Search tab, switch to it instead of popping
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false; // Don't pop
        }
        return true; // Allow pop if already on Search tab
      },
      child: Scaffold(
        body: _screens[_currentIndex],
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
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_location_alt),
              label: 'Suggest',
            ),
          ],
        ),
      ),
      ),
    );
  }
}
