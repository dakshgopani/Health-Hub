import 'dart:async';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'video_call_page.dart';

class VideoCallIndexPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => VideoCallIndexPageState();
}

class VideoCallIndexPageState extends State<VideoCallIndexPage> {
  final _channelController = TextEditingController();
  bool _validateError = false;
  ClientRole _role = ClientRole.Broadcaster; // Fixed role for one-to-one calls

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
          weight: 900,
          size: 26,
        ),
        title: Text(
          'Doctor-Patient Call',
          style: AppTextStyles.whiteHeading.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: AppColors.deepPurple,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),

              // Header illustration with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.deepPurple, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepPurple.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.video_call_rounded,
                  size: 100,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // Title and subtitle
              Text(
                'Start Your Consultation',
                style: AppTextStyles.heading.copyWith(fontSize: 24,fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Enter a channel name to begin your secure video consultation.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),

              // Channel input field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _channelController,
                  style: AppTextStyles.body.copyWith(fontSize: 16),
                  decoration: InputDecoration(
                    errorText: _validateError ? 'Channel name is mandatory' : null,
                    errorStyle: const TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                    border: InputBorder.none,
                    hintText: 'Enter Channel Name (e.g., doctor123)',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Raleway',
                    ),
                    prefixIcon: const Icon(
                      Icons.videocam_rounded,
                      color: AppColors.deepPurple,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Start Call button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepPurple,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_call_rounded, size: 24,color: Colors.white,),
                      SizedBox(width: 10),
                      Text(
                        'Start Video Call',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Help text
              const Text(
                'Make sure you have a stable internet connection',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Raleway',
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 30),

              // Secure call info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(
                      Icons.security_rounded,
                      size: 20,
                      color: AppColors.deepPurple,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Your call is secure and private',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Raleway',
                        color: AppColors.deepPurple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onJoin() async {
    setState(() {
      _channelController.text.isEmpty ? _validateError = true : _validateError = false;
    });
    if (_channelController.text.isNotEmpty) {
      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPage(
            channelName: _channelController.text,
            role: _role, // Always Broadcaster
          ),
        ),
      );
    }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }
}
