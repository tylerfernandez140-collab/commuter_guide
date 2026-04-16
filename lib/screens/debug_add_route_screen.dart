import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DebugAddRouteScreen extends StatelessWidget {
  const DebugAddRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Add Route', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF0F766E),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_road,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Debug Add Route Screen',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'If you can see this, the navigation works!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
