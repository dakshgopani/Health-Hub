import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_form_widgets.dart';
import '../home/home_page.dart';
import '../profile_setup.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  final TextEditingController _emailController =
      TextEditingController(); // Email controller
  final TextEditingController _passwordController =
      TextEditingController(); // Password controller
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // Confirm password controller
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
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

          // Check if the user exists in Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            // User already exists, show message or redirect to HomePage
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('You already have an account. Redirecting to Home.'),
              ),
            );

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
          } else {
            // New user, navigate to Profile Setup Page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileSetupPage(userId: user.uid),
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

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Email and Password cannot be empty.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Register the user with Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final User? user = userCredential.user;

      if (user != null) {
        // Check if the user is new
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          // If the user is new, navigate to Profile Setup
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetupPage(userId: user.uid),
            ),
          );
        } else {
          // If the user is existing, navigate directly to HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                // userName: user.displayName ?? "User",
                userId: FirebaseAuth.instance.currentUser!.uid,
                userName:
                    FirebaseAuth.instance.currentUser!.displayName ?? "User",
                userEmail: FirebaseAuth.instance.currentUser!.email ?? "Email",
              ),
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account already exists for that email.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is invalid.';
            break;
          default:
            errorMessage = 'Sign-up failed. Please try again later.';
        }
      } else {
        errorMessage = 'An unknown error occurred.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const Text(
                'Heyy there 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Raleway',
                  color: Color(0xFF432C81),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 32,
                  fontFamily: 'Raleway',
                  color: Color(0xFF432C81),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/images/auth/login_signup_img.png',
                  height: 200,
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

              const SizedBox(height: 16),

              CustomPasswordField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  icon: Icons.lock),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Handle forgot password
                  },
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
                  onPressed: _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF432C81),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
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
                    'Already have an account? ',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: 'Raleway',
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF6B4CE6),
                        fontWeight: FontWeight.bold,
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
