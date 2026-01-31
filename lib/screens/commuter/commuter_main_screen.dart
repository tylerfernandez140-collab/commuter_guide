import 'package:flutter/material.dart';
import 'commuter_home_screen.dart';
import 'map_screen.dart';
import 'chat_screen.dart';
import 'suggest_landmark_screen.dart';
import '../login_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class CommuterMainScreen extends StatefulWidget {
  const CommuterMainScreen({Key? key}) : super(key: key);

  @override
  _CommuterMainScreenState createState() => _CommuterMainScreenState();
}

class _CommuterMainScreenState extends State<CommuterMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CommuterHomeScreen(),
    const MapScreen(),
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
