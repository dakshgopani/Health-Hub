import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_form_widgets.dart';
import "../home/home_page.dart";
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  final TextEditingController _emailController =
      TextEditingController(); // Controller for email TextField
  final TextEditingController _passwordController =
      TextEditingController(); // Controller for password TextField
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _emailController
        .dispose(); // Dispose of the controller to avoid memory leaks
    _passwordController.dispose();
    super.dispose();
  }

  void _showCreateAccountPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Rounded corners
          ),
          backgroundColor: AppColors.scaffoldBackground,
          // Light purple background
          title: const Text(
            'Create an Account',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Raleway',
              color: AppColors.deepPurple, // Use your theme color
            ),
          ),
          content: const Text(
            'It seems you don\'t have an account. Would you like to create one?',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Raleway',
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600], // Subtle grey tone
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignUpScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepPurple, // Primary button color
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text for contrast
                ),
              ),
            ),
          ],
        );
      },
    );
  }

// Google sign-in function
  Future<void> _handleGoogleSignIn() async {
    try {
      // Ensure previous account session is signed out
      await _googleSignIn.signOut();

      // Attempt to disconnect the account and handle potential errors gracefully
      try {
        await _googleSignIn.disconnect();
      } catch (error) {
        print('Failed to disconnect: $error');
      }

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication googleAuth =
            await account.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in with the credential
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          print('User signed in: ${user.uid}');
          print('User name: ${user.displayName}');
          print('User email: ${user.email}');

          // Check if the user is new or existing
          if (userCredential.additionalUserInfo?.isNewUser ?? false) {
            // If the user is new, show prompt to create a new account
            _showCreateAccountPrompt();
          } else {
            // If the user is existing, navigate directly to HomePage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  userId: FirebaseAuth.instance.currentUser!.uid,
                  userName:
                      FirebaseAuth.instance.currentUser!.displayName ?? "User",
                  userEmail:
                      FirebaseAuth.instance.currentUser!.email ?? "Email",
                ),
              ),
            );
          }
        }
      }
    } catch (error) {
      print('Google sign-in error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $error')),
      );
    }
  }

  // Facebook sign-in function
  Future<void> _handleFacebookSignIn() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final credential = FacebookAuthProvider.credential(accessToken.token);
        await _auth.signInWithCredential(credential);
        // Redirect to another screen
      } else {
        print('Facebook sign-in error: ${result.message}');
      }
    } catch (error) {
      print('Facebook sign-in error: $error');
    }
  }

  void _showSnackbar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(5),
        elevation: 10,
      ),
    );
  }

  // Email/Password sign-in function
  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Email and Password cannot be empty.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                userId: FirebaseAuth.instance.currentUser!.uid,
                userName:
                    FirebaseAuth.instance.currentUser!.displayName ?? "User",
                userEmail: FirebaseAuth.instance.currentUser!.email ?? "Email",
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignUpScreen(),
            ),
          );
        }
      }
    } catch (e) {
      print('Email sign-in error: $e');
      // Show an error message to the user
      _showSnackbar('Invalid email or password.', Colors.red);
    } finally {
      setState(() {
        _isLoading = false; // Stop loading after the process
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              // Centered Welcome Back and Login text
              const Center(
                child: Column(
                  children: [
                    Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 24,
                        color: Color(0xFF432C81),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 32,
                        fontFamily: 'Raleway',
                        color: Color(0xFF432C81),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/images/auth/login_signup_img.png',
                  height: 250,
                  // height: 220,
                ),
              ),
              const SizedBox(height: 30),

              CustomTextField(
                label: "Email",
                controller: _emailController,
                icon: Icons.email,
                onClear: () {
                  setState(() {
                    _emailController.clear();
                  });
                },
              ),

              const SizedBox(height: 16),

              // Password TextBox
              CustomPasswordField(
                label: "Password",
                controller: _passwordController,
                icon: Icons.lock,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF432C81),
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF432C81),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Raleway',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF432C81),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Raleway',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SocialLoginButton(
                    onTap: _handleGoogleSignIn,
                    assetPath: 'assets/icons/google.jpg', // Google Image
                  ),
                  const SizedBox(width: 16),
                  SocialLoginButton(
                    onTap: () {},
                    icon: FontAwesomeIcons.facebook,
                    iconColor: Colors.blue, // Facebook Color
                  ),
                  const SizedBox(width: 16),
                  SocialLoginButton(
                    onTap: () {},
                    icon: FontAwesomeIcons.apple,
                    iconColor: Colors.black, // Apple Color
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
