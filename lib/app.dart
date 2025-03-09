import 'package:flutter/material.dart';
import 'screens/blood_donation_page_screen.dart';
import 'screens/initial/onboarding_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_page.dart';
import 'screens/initial/splash_screen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Hub',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      // Set the initial route to WelcomeScreen
      routes: {
        '/': (context) => SplashScreen(), // Welcome Screen (initial screen)
        '/onboarding': (context) => OnboardingScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(), // Login screen
        '/signup': (context) => SignUpScreen(), // Sign-up screen
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args =
              settings.arguments as Map<String, dynamic>; // Accept arguments
          final userId = args['userId']
              as String; // Ensure you're extracting the correct data
          final userName = args['userName'] as String? ??
              'User'; // Fallback to 'User' if no name provided
          final userEmail =
              args['userEmail'] as String? ?? 'No Email'; // Extract userEmail

          return MaterialPageRoute(
            builder: (context) => HomePage(
              userId: userId,
              userName: userName,
              userEmail: userEmail,
            ),
          );
        }
        return null; // Return null for unknown routes
      },
    );
  }
}
