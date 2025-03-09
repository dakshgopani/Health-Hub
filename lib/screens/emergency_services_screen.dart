import 'package:flutter/material.dart';
import 'ambulance_booking_screen.dart';
import 'blood_donation_page_screen.dart';
import 'nearby_hospitals_screen.dart';

class EmergencyServicesScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const EmergencyServicesScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  _EmergencyServicesScreenState createState() =>
      _EmergencyServicesScreenState();
}

class _EmergencyServicesScreenState extends State<EmergencyServicesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 10),

            // 🆘 Emergency Services Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Emergency\nServices",
                    style: TextStyle(
                      color: Color(0xFF432C81),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Raleway', // Applying Raleway font
                    ),
                  ),
                  Image.asset(
                    'assets/emergency_icon.png', // Replace with your asset path
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🏥 Emergency Options List
            _buildEmergencyOption("Contact Nearby Hospitals", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HospitalLocator(),
                ),
              );
            }),
            _buildEmergencyOption("Book Ambulance", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AmbulanceBookingScreen(),
                ),
              );
            }),
            _buildEmergencyOption("Donate blood to needy nearby", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BloodDonationPage(
                    userId: widget.userId,
                    userName: widget.userName,
                    userEmail: widget.userEmail,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// ✅ Reusable Emergency Option Widget
  Widget _buildEmergencyOption(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.deepPurple[50],
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
             BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap, // Action when clicked
          borderRadius: BorderRadius.circular(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF432C81),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Raleway',
                ),
              ),
              IconButton(
                icon: Image.asset(
                  'assets/icons/arrow_next_page.png', // Path to your icon
                ),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
