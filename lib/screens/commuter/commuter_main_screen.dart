import 'package:flutter/material.dart';
import 'commuter_home_screen.dart';
import '../google_maps_screen.dart';
import 'chat_screen.dart';
import 'suggest_landmark_screen.dart';

class CommuterMainScreen extends StatefulWidget {
  const CommuterMainScreen({super.key});

  @override
  State<CommuterMainScreen> createState() => _CommuterMainScreenState();
}

class _CommuterMainScreenState extends State<CommuterMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CommuterHomeScreen(),
    const GoogleMapsScreen(),
    const ChatScreen(),
    const SuggestLandmarkScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
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
    );
  }
}
