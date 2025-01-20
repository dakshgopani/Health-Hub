import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_page.dart'; // Import your HomePage
import 'firebase_options.dart'; // Import the generated file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase(); // Use your custom Firebase initialization
  runApp(MyApp());
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use platform-specific options
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-screen App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Set the initial route to WelcomeScreen
      routes: {
        '/': (context) => WelcomeScreen(), // Welcome Screen (initial screen)
        '/login': (context) => LoginScreen(), // Login screen
        '/signup': (context) => SignUpScreen(), // Sign-up screen
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>; // Accept arguments
          final userId = args['userId'] as String; // Ensure you're extracting the correct data
          final userName = args['userName'] as String? ?? 'User'; // Fallback to 'User' if no name provided

          return MaterialPageRoute(
            builder: (context) => HomePage(
              userId: userId,
              // userName: userName, // Pass the userName argument
            ),
          );
        }
        return null; // Return null for unknown routes
      },
    );
  }
}
