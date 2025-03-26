import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../auth/welcome_screen.dart';
import '../home/home_page.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 5)); // Simulate loading time

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            userId: FirebaseAuth.instance.currentUser!.uid,
            userName: FirebaseAuth.instance.currentUser!.displayName ?? "User",
            userEmail: FirebaseAuth.instance.currentUser!.email ?? "Email",
          ),
        ),
      );
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

      if (isFirstLaunch) {
        prefs.setBool('isFirstLaunch', false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white, // Keep background white
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Logo without shadow
              Image.asset(
                'assets/logo/LOGO_HH.png',
                width: screenWidth * 0.7,
                height: screenWidth * 0.7,
              ),
              const SizedBox(height: 20),
              // App Name in Deep Purple
              Text(
                'Health Hub',
                style: TextStyle(
                  fontSize: screenWidth * 0.1,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepPurple,
                  // Deep purple text
                  fontFamily: 'Raleway',
                  shadows: [
                    Shadow(
                      color: AppColors.deepPurple.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              // Tagline in lighter purple accent
              Text(
                'Your Health, Your Way',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.deepPurple.withOpacity(0.8),
                  // Lighter purple accent
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 70),
              // Progress Indicator with purple accents
              SizedBox(
                width: screenWidth * 0.5,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.deepPurple.withOpacity(0.2),
                  // Light purple background
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.deepPurple),
                  // Solid deep purple
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
