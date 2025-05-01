import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/email_service.dart';
import '../../services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting
import 'package:confetti/confetti.dart';
import '../../theme/colors.dart';
import 'rewards_screen.dart';

class DonationSuccessScreen extends StatefulWidget {
  final String userId;
  final String? requestId;
  final String hospitalName;
  final String hospitalLocation;
  final String userEmail;

  const DonationSuccessScreen(
      {super.key,
        required this.userId,
        required this.requestId,
        required this.hospitalName,
        required this.hospitalLocation,
        required this.userEmail});

  @override
  State<DonationSuccessScreen> createState() => _DonationSuccessScreenState();
}

class _DonationSuccessScreenState extends State<DonationSuccessScreen> {
  bool _hasDonated = false;
  bool _showCertificate = false;
  String _userName = "";
  bool _isLoading = true; // ✅ Added for loader
  bool _scratchCardTriggered = false; // Ensures scratch card shows only once
  bool _rewardGiven = false; // Ensure the reward logic executes only once.
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _checkDonationStatus();
  }

  Future<void> _checkDonationStatus() async {
    try {
      // ✅ Ensure requestId is valid
      if (widget.requestId == null || widget.requestId!.isEmpty) {
        print("⚠️ requestId is NULL. Cannot verify donation.");
        setState(() {
          _hasDonated = false;
          _showCertificate = false;
          _isLoading = false;
        });
        return;
      }

      // ✅ Fetch the donation request from Firestore
      final requestDoc = await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(widget.requestId)
          .get();

      if (!requestDoc.exists) {
        print("❌ No document found with RequestId: ${widget.requestId}");
        setState(() {
          _hasDonated = false;
          _showCertificate = false;
          _isLoading = false;
        });
        return;
      }

      print("📜 Blood Request Document Data: ${requestDoc.data()}");

      // ✅ Extract hospital details
      String requestHospitalName =
          requestDoc.data()?['hospitalName'] ?? 'Unknown Hospital';
      String requestHospitalLocation =
          requestDoc.data()?['hospitalLocation'] ?? 'Unknown Location';

      print("🔍 Checking if hospital matches:");
      print("Clicked: ${widget.hospitalName}, ${widget.hospitalLocation}");
      print("Firestore: $requestHospitalName, $requestHospitalLocation");

      if (widget.hospitalName != requestHospitalName ||
          widget.hospitalLocation != requestHospitalLocation) {
        print("❌ Hospital/Location mismatch. No certificate!");
        setState(() {
          _hasDonated = false;
          _showCertificate = false;
          _isLoading = false;
        });
        return;
      }

      // ✅ Extract donation list safely
      var donationList =
          requestDoc.data()?['donation_list'] as List<dynamic>? ?? [];

      print(
          "📝 Donation List for Request ID ${widget.requestId}: $donationList");

      // ✅ Check if the user has donated
      bool userHasDonated = donationList.any((donation) {
        if (donation is Map<String, dynamic>) {
          print("🔍 Checking donation entry: $donation");
          return donation['user_id'] == widget.userId &&
              donation['status'] == 'donated';
        }
        return false;
      });

      print(
          "✅ User Has Donated in Request ${widget.requestId}: $userHasDonated");

      if (userHasDonated) {
        await _fetchUserName(widget.userId);

        // ✅ Update UI and show certificate
        setState(() {
          _hasDonated = true;
          _showCertificate = true;
          _isLoading = false;
        });

        // ✅ Play confetti and trigger reward logic
        _confettiController.play();

        // ✅ Show scratch card after 10 seconds (Only if not triggered)
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && !_scratchCardTriggered) {
            setState(() {
              _scratchCardTriggered = true;
            });
            RewardsSystem.showScratchCardPopup(
                context, widget.userId, widget.requestId ?? "unknow");
          }
        });
      } else {
        setState(() {
          _hasDonated = false;
          _showCertificate = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error in _checkDonationStatus: $e");
      setState(() {
        _hasDonated = false;
        _showCertificate = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print("No user document found with UserId: $userId");
        setState(() {
          _userName = 'Unknown User';
          _showCertificate = false;
        });
        return;
      }

      print("User Document Data: ${userDoc.data()}");

      setState(() {
        _userName = userDoc.data()?['name'] ?? 'Unknown User';
        _showCertificate = true;
      });
    } catch (e) {
      print("Error in _fetchUserName: $e");
      setState(() {
        _userName = 'Unknown User';
        _showCertificate = false;
      });
    }
  }

  Future<void> _sendDonationEmail() async {
    try {
// Get today's date in "15 July 2023" format
      String todayDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

      final pdfFile = await PdfService.generateDonationCertificate(
        userName: _userName,
        hospitalName: widget.hospitalName,
        hospitalAddress: widget.hospitalLocation,
        donationDate: todayDate, // Pass today's date
      );

      await EmailService.sendEmail(widget.userEmail, pdfFile);
      print("✅ Email sent successfully!");
    } catch (e) {
      print("❌ Failed to send email: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDECF4),
      appBar: AppBar(
        title: const Text(
          "Donation Status",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'Raleway',
            color: Colors.white,// Applying Raleway font
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          weight: 900,
          size: 26,
        ),
        centerTitle: true,
        backgroundColor: AppColors.deepPurple,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        elevation: 0,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator() // ✅ Show loader while checking donation status
            : _hasDonated
            ? (_showCertificate
            ? _buildCertificate() // ✅ Show certificate if donation is verified
            : const CircularProgressIndicator()) // (Fallback, should not trigger)
            : _buildNotDonatedYet(),
      ),
    );
  }

  Widget _buildNotDonatedYet() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text(
                    "Donation Not Found",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Raleway',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Icon(Icons.bloodtype_outlined, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "We couldn't verify your donation",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                  fontFamily: 'Raleway',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Your blood donation at this hospital hasn't been recorded in our system yet. "
                    "If you've already donated, please allow some time for the records to update.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Raleway',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_hospital, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        widget.hospitalName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Raleway',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        widget.hospitalLocation,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Raleway',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text(
                      "Go Back",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Raleway',
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 140,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _checkDonationStatus(); // Refresh and check again
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      "Retry",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Raleway',
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificate() {
    if (_hasDonated) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('donation_rewards')
          .doc(widget.requestId)
          .get()
          .then((doc) {
        if (!doc.exists) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('donation_rewards')
              .doc(widget.requestId)
              .set({'rewardGiven': true});

          _rewardGiven = true;
          _confettiController.play();
          _sendDonationEmail();
          Future.delayed(const Duration(seconds: 10), () {
            if (!_scratchCardTriggered) {
              setState(() {
                _scratchCardTriggered = true;
              });
              RewardsSystem.showScratchCardPopup(
                  context, widget.userId, widget.requestId ?? "unknown");
            }
          });
        }
      });
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 50),
                      SizedBox(height: 10),
                      Text(
                        "Donation Certificate",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Raleway',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Congratulations, $_userName!",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                      fontFamily: 'Raleway',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "You have successfully donated blood and made a valuable contribution to saving lives. "
                        "Your kindness and generosity are truly appreciated!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Raleway',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_hospital, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            widget.hospitalName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Raleway'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            widget.hospitalLocation,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Raleway',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Date: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Raleway',
                  ),
                ),
                const SizedBox(height: 30),

                /// 🚀 Buttons: "Go Back" & "Share"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// 🔙 Go Back Button
                    SizedBox(
                      width: 140,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        label: const Text(
                          "Go Back",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Raleway',
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    /// 📤 Share Button
                    SizedBox(
                      width: 140,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _shareCertificate();
                        },
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text(
                          "Share",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Raleway',
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        /// 🎊 Confetti Animation
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.3,
        ),
      ],
    );
  }

  Future<void> _shareCertificate() async {
    try {
      // Get today's date
      String todayDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

      // Generate the PDF Certificate
      final pdfFile = await PdfService.generateDonationCertificate(
        userName: _userName,
        hospitalName: widget.hospitalName,
        hospitalAddress: widget.hospitalLocation,
        donationDate: todayDate,
      );

      // Define a custom message
      String message = """
🎉 I just donated blood and received my Donation Certificate! 🩸🏥
A small act can save a life. 💖
Join the cause and make a difference! 💪🔥
#BloodDonation #SaveLives #BeAHero
    """;

      // Share the file with the custom message
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: message,
      );

      print("✅ Certificate shared successfully!");
    } catch (e) {
      print("❌ Error sharing certificate: $e");
    }
  }
}
