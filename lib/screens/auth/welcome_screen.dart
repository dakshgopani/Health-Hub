import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome text
                const Spacer(flex: 1),
                const Text(
                  "Welcome to",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF432C81),
                      fontFamily: 'Raleway'),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  "Health Hub",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF432C81),
                      fontFamily: 'Raleway'),
                ),
                const SizedBox(height: 24.0),

                // Illustration
                Container(
                  height: 390, // Ensure it matches your design size
                  child: Image.asset(
                    'assets/images/auth/welcome_screen_img.png',
                    // Replace with your image path
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32.0),

                // Sign Up Button (Full width)
                SizedBox(
                  width: double.infinity, // Makes the button block width
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF432C81),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Raleway',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Login Button (Full width)
                SizedBox(
                  width: double.infinity, // Makes the button block width
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      side: const BorderSide(color: Color(0xFF432C81)),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF432C81),
                          fontFamily: 'Raleway'),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
