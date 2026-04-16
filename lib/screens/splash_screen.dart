import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    // Start the animation immediately for the fallback
    _controller.repeat();
    // Start checking auth after a delay to let animation play
    Future.delayed(const Duration(milliseconds: 500), _checkAuth);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final seenOnboarding = prefs.getBool('onboarding_done') ?? false;
    if (!seenOnboarding) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = await authProvider.tryAutoLogin();
    if (!mounted) return;

    if (isAuthenticated) {
      if (authProvider.user?.role == 'admin') {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/commuter-home');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use the correct travel_icon_map animation for splash screen
            Lottie.asset(
              'travel_icon_map.json',
              controller: _controller,
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              onLoaded: (composition) {
                print('Travel icon map animation loaded successfully');
                _controller
                  ..duration = composition.duration
                  ..repeat();
              },
              errorBuilder: (context, error, stackTrace) {
                print('Travel icon map Lottie error: $error');
                // Fallback to a simple animated container
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _controller.value * 2 * 3.14159,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.map,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
