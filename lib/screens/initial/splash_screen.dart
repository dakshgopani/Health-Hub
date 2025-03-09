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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3)); // Simulate loading time

    // Check Firebase Authentication
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in
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
      // User is not logged in, check SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

      if (isFirstLaunch) {
        // First-time user, show onboarding
        prefs.setBool('isFirstLaunch', false); // Mark as completed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      } else {
        // Show Welcome/Login Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/logo/LOGO_HH.png',
              width: screenWidth * 0.7, // Responsive Image
              height: screenWidth * 0.7,
            ),
            const SizedBox(height: 20),
            Text(
              'Health Hub',
              style: TextStyle(
                // fontSize: 42,
                fontSize: MediaQuery.of(context).size.width *
                    0.1, // Adjust based on screen width
                fontWeight: FontWeight.bold,
                color: AppColors.deepPurple,
                fontFamily: 'Raleway',
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Your Health, Your Way',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 70),
            SizedBox(
              width: screenWidth * 0.5, // Responsive Progress Indicator
              child: const LinearProgressIndicator(
                backgroundColor: Color(0xFFD1C4E9),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
