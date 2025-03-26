import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Add this
import '../../services/notification_service.dart';
import '../../widgets/menu_card.dart';
import '../chatbot.dart';
import '../disease_prediction.dart';
import '../doctor_dashboard_screen.dart';
import '../doctor_page.dart';
import '../emergency_services_screen.dart';
import '../medical_history.dart';
import '../medicine_page.dart';
import '../settings_page.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const HomePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _page = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeContent(userId: widget.userId, userName: widget.userName),
      MedicinePage(),
      EmergencyServicesScreen(
          userId: widget.userId,
          userName: widget.userName,
          userEmail: widget.userEmail),
      SettingsPage(),
    ];

    _showNotificationOnce();
  }

  Future<void> _showNotificationOnce() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasShownNotification = prefs.getBool('notificationShown') ?? false;

    if (!hasShownNotification) {
      await NotificationService.showNotification();
      await prefs.setBool('notificationShown', true); // ✅ Save status
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_page],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: const Color(0xFF432C81),
        buttonBackgroundColor: const Color(0xFF6B4EFF),
        height: 60,
        animationDuration: const Duration(milliseconds: 300),
        index: _page,
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
        items: const [
          Icon(Icons.grid_view, color: Colors.white),
          Icon(Icons.medical_services, color: Colors.white),
          Icon(Icons.emergency_outlined, color: Colors.white),
          Icon(Icons.settings, color: Colors.white),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final String userId;
  final String userName;

  const HomeContent({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const HealthChatbotScreen()),
          );
        },
        backgroundColor: const Color(0xFF432C81),
        child: Image.asset(
          "assets/images/home_page/robot.png",
          width: 30, // Adjust as needed
          height: 30,
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    '👋 Hi $userName!',
                    style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF432C81)),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.purple[100],
                    child: const Icon(Icons.person, color: Colors.purple),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  MenuCard(
                    title:
                        'Symptoms Analysis & Early Stage\nDisease Prediction',
                    imagePath: 'assets/images/home_page/symptoms_analysis.png',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DiseasePredictionPage()),
                    ),
                  ),
                  MenuCard(
                    title: 'Medical History',
                    imagePath: 'assets/images/home_page/medical_history.png',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MedicalHistoryPage()),
                    ),
                  ),
                  MenuCard(
                    title: 'Doctor Finding, Booking &\nTelemedicine',
                    imagePath: 'assets/images/home_page/telemedicine.png',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DoctorPage()),
                    ),
                  ),
                  MenuCard(
                    title: 'Doctor Dashboard',
                    imagePath: 'assets/images/home_page/wellness.png',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DoctorDashboard()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
