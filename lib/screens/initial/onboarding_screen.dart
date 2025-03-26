import 'dart:async'; // Import the Timer class
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _pageTimer;

  @override
  void initState() {
    super.initState();
    _startAutoPageSwitching();
  }

  // Start auto-scrolling every 3 seconds, stopping after the last page
  void _startAutoPageSwitching() {
    _pageTimer?.cancel(); // Cancel any existing timer

    _pageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < 2) {
        // Stop after page 2
        setState(() {
          _currentPage++;
        });
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800), // Smooth transition
          curve: Curves.easeInOut, // Smooth curve
        );
      } else {
        timer.cancel(); // Stop the timer after the last page
      }
    });
  }

  @override
  void dispose() {
    _pageTimer?.cancel(); // Cancel the timer to prevent memory leaks
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });

                  // Restart auto-scrolling when the user comes back to page 0
                  if (_currentPage == 0) {
                    _startAutoPageSwitching();
                  }
                },
                physics: const BouncingScrollPhysics(), // Smooth scroll effect
                children: [
                  _buildOnboardingPage(
                    imagePath:
                        'assets/images/onboarding_img/onboarding_img_1.png',
                    title: 'Symptoms analysis &\nDisease Prediction',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus lacinia libero ut metus convallis tempor. Vestibulum consequat, tortor mattis consequat',
                  ),
                  _buildOnboardingPage(
                    imagePath:
                        'assets/images/onboarding_img/onboarding_img_2.png',
                    title: 'Discover Top Doctors \n in your locality',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus lacinia libero ut metus convallis tempor. Vestibulum consequat, tortor mattis consequat',
                  ),
                  _buildOnboardingPage(
                    imagePath:
                        'assets/images/onboarding_img/onboarding_img_3.png',
                    title: 'Wellness & Lifestyle \n for everybody',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus lacinia libero ut metus convallis tempor. Vestibulum consequat, tortor mattis consequat',
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _completeOnboarding,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Skip Tour',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF82799D),
                    fontFamily: 'Raleway',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String imagePath,
    required String title,
    required String description,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height *
                  0.05, // Scales with screen height
            ),
            child: Image.asset(imagePath),
          ),

          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3, // Number of onboarding screens
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                height: MediaQuery.of(context).size.width * 0.02,
                width: _currentPage == index
                    ? MediaQuery.of(context).size.width * 0.04
                    : MediaQuery.of(context).size.width * 0.02,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFF432C81)
                      : const Color(0xFF82799D),
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize:
                  MediaQuery.of(context).size.width * 0.08, // Dynamic font size
              fontWeight: FontWeight.w900,
              color: Color(0xFF432C81),
              fontFamily: 'Raleway',
            ),
          ),

          const SizedBox(height: 16),
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.08,
              ),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width *
                      0.045, // Scales dynamically
                  color: Colors.black87,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),
          const Spacer(),
        ],
      ),
    );
  }
}
