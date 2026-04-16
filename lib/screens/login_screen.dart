import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _lottieError = false;

  void _login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      if (authProvider.user?.role == 'admin') {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/commuter-home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
      );
    }
  }

  void _showPolicySheet(String title, List<Widget> children) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.85,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0F766E),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPrivacy() {
    _showPolicySheet('Privacy Policy', [
      _paragraph('Byahero values your privacy. This Privacy Policy explains how we collect, use, and protect your information when you use the application.'),
      _sectionTitle('1. Information We Collect'),
      _paragraph('When you create an account, the app may collect basic information such as your name, email address, and account credentials. This information is used solely for authentication and account management within the system.'),
      _sectionTitle('2. How We Use Your Information'),
      _paragraph('The information collected is used to:'),
      _bullet('Provide access to the application\'s features'),
      _bullet('Improve system functionality'),
      _bullet('Manage user suggestions and feedback'),
      _sectionTitle('3. Data Protection'),
      _paragraph('We take reasonable steps to protect your personal information from unauthorized access, misuse, or disclosure.'),
      _sectionTitle('4. Third-Party Services'),
      _paragraph('This application does not sell, trade, or share your personal information with third parties.'),
      _sectionTitle('5. User Suggestions'),
      _paragraph('If you submit route or landmark suggestions, the information you provide may be reviewed by administrators to improve the commuter guide system.'),
      _sectionTitle('6. Changes to This Policy'),
      _paragraph('This privacy policy may be updated when system features change. Continued use of the app indicates acceptance of the updated policy.'),
      _sectionTitle('7. Contact'),
      _paragraph('For questions regarding this policy, please contact the application administrator.'),
    ]);
  }

  void _openTerms() {
    _showPolicySheet('Terms and Conditions', [
      _paragraph('By accessing and using the Byahero application, you agree to the following terms.'),
      _sectionTitle('1. Use of the Application'),
      _paragraph('This application is designed to help users explore transportation routes, landmarks, and commuter information.'),
      _sectionTitle('2. User Responsibility'),
      _paragraph('Users agree to provide accurate information when creating an account and to use the application responsibly.'),
      _sectionTitle('3. User Suggestions'),
      _paragraph('Users may submit suggestions for routes or landmarks. These submissions are subject to review by administrators and may be approved or rejected.'),
      _sectionTitle('4. System Availability'),
      _paragraph('While we aim to keep the system accessible at all times, temporary interruptions may occur due to maintenance or technical issues.'),
      _sectionTitle('5. Limitation of Liability'),
      _paragraph('The application provides route information for guidance purposes only. The developers are not responsible for delays, route changes, or inaccuracies in transportation schedules.'),
      _sectionTitle('6. Prohibited Use'),
      _paragraph('Users must not misuse the application, attempt unauthorized access, or interfere with system operations.'),
      _sectionTitle('7. Acceptance of Terms'),
      _paragraph('By continuing to use the application, you acknowledge that you have read and agree to these Terms and Conditions.'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F766E), // Deep Teal
              Color(0xFF2DD4BF), // Soft Teal
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                // Lottie Animation with overlapping text
                SizedBox(
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animation
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: _lottieError
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.directions_bus,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                )
                              : Lottie.asset(
                                  'bus_transport.json',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) {
                                        setState(() {
                                          _lottieError = true;
                                        });
                                      }
                                    });
                                    return const SizedBox.shrink();
                                  },
                                ),
                        ),
                      ),
                      // Overlapping Text
                      Positioned(
                        bottom: -5,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              final fs = w >= 420 ? 32.0 : (w >= 360 ? 30.0 : 26.0);
                              return Text(
                                'Welcome to Byahero!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: fs,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                Text( 
                  'Your journey starts here',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 25),

                // Form Card
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final double maxCardWidth = screenWidth < 360
                        ? 340.0
                        : (screenWidth < 480 ? 380.0 : 420.0);
                    return Container(
                      constraints: BoxConstraints(maxWidth: maxCardWidth),
                      width: double.infinity,
                  child: Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                      color: Colors.white.withValues(alpha: 0.95),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                      child: Column(
                        children: [
                          // Email Field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: const TextStyle(color: Colors.black87),
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: Color(0xFFF59E0B), // Bus Yellow
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.black87),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFFF59E0B), // Bus Yellow
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: authProvider.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF0F766E), // Deep Teal
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF0F766E), // Deep Teal
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'LOGIN',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.poppins(color: Colors.black87),
                              children: [
                                TextSpan(
                                  text: 'By continuing you agree to our\n',
                                  style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
                                ),
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  recognizer: TapGestureRecognizer()..onTap = _openTerms,
                                ),
                                TextSpan(
                                  text: ' and ',
                                  style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
                                ),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  recognizer: TapGestureRecognizer()..onTap = _openPrivacy,
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

                const SizedBox(height: 15),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        "Don't have an account?",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Register',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ), // Container closing bracket
  ));
  }
}
