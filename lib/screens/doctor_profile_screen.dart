import 'package:flutter/material.dart';
import 'package:mad_practice_one/screens/video_call_index_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/doctor_data_model.dart';
import 'doctor_appointment_booking/appointment_booking.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;
  final String imageUrl; // Add this to receive the image URL

  const DoctorProfileScreen({Key? key, required this.doctor, required this.imageUrl}) : super(key: key);

  @override
  _DoctorProfileScreenState createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      var status = await Permission.phone.status;

      if (status.isDenied || status.isRestricted) {
        status = await Permission.phone.request();
      }

      if (status.isGranted) {
        final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
        if (await canLaunchUrl(launchUri)) {
          await launchUrl(launchUri);
        } else {
          throw 'Could not launch $phoneNumber';
        }
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
        throw 'Phone call permission permanently denied. Enable it from settings.';
      } else {
        throw 'Phone call permission denied';
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f3ff),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimationLimiter(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 375),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: widget,
                        ),
                      ),
                      children: [
                        _buildProfileInfo(),
                        const SizedBox(height: 24),
                        _buildDetailCard(
                            "Specialist in", widget.doctor.specialization),
                        _buildDetailCard("Hospital", widget.doctor.hospital),
                        _buildDetailCard("Rating", "${widget.doctor.rating} ⭐"),
                        _buildDetailCard("Consultation Fee", widget.doctor.fee),
                        _buildDetailCard(
                            "Experience", "${widget.doctor.experience} years"),
                        _buildDetailCard("Languages", widget.doctor.languages),
                        _buildDetailCard("Reviews", widget.doctor.reviews,
                            isMultiline: true),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFf5f3ff),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.black,
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                widget.doctor.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Raleway',
                  color: Color(0xFF432C81),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.phone),
              color: const Color(0xFF432C81),
              onPressed: () => _makePhoneCall(widget.doctor.contactNumber),
            ),
            IconButton(
              icon: const Icon(Icons.video_call),
              color: const Color(0xFF432C81),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => VideoCallIndexPage(
                     // Always Broadcaster
                  ),
                ),);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Center(
          child: Hero(
            tag: 'doctor_avatar_${widget.doctor.doctorId}', // Unique tag matching _buildDoctorCard
            child: ClipOval(
              child: Container(
                width: 100, // Adjusted size for profile page
                height: 100,
                child: Image.network(
                  widget.imageUrl, // Use the passed imageUrl
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF432C81),
                      child: Text(
                        widget.doctor.name[4].toUpperCase(), // Fallback to initial
                        style: const TextStyle(
                          fontSize: 50,
                          color: Colors.white,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.doctor.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: 'Raleway',
            color: Color(0xFF432C81),
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          widget.doctor.specialization,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailCard(String title, String value,
      {bool isMultiline = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF432C81),
                fontFamily: 'Raleway',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentBookingScreen(
                  selectedDoctor: widget.doctor,
                  fee: double.parse(
                      widget.doctor.fee.replaceAll(RegExp(r'[^\d.]'), '')),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF432C81),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Book Appointment',
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w900),
          ),
        ),

      ],
    );
  }
}
