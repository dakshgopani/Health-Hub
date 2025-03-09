import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile_scanner;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as ml_kit;
import 'dart:ui';
import 'waiting_room.dart';

class ScanQRCodeScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ScanQRCodeScreen(
      {Key? key, required this.userId, required this.userName})
      : super(key: key);

  @override
  State<ScanQRCodeScreen> createState() => _ScanQRCodeScreenState();
}

class _ScanQRCodeScreenState extends State<ScanQRCodeScreen> {
  String scannedData = "";
  final mobile_scanner.MobileScannerController _mobileScannerController =
      mobile_scanner.MobileScannerController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDECF4),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Scan QR Code for Donation",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Raleway', // Applying Raleway font
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEDECF4),
        ),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Stack(
                children: [
                  mobile_scanner.MobileScanner(
                    controller: _mobileScannerController,
                    onDetect: (mobile_scanner.BarcodeCapture barcodeCapture) {
                      for (final barcode in barcodeCapture.barcodes) {
                        if (barcode.rawValue != null &&
                            barcode.rawValue!.isNotEmpty) {
                          _processScannedData(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 3),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _selectedImage == null
                          ? Container()
                          : Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                child: Image.file(
                                  File(_selectedImage!.path),
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (scannedData.isNotEmpty)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF432C81),
                                          Color(0xFF6546A0),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "Scanned QR Code",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Raleway',
                                          // backgroundColor: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F7FC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFF432C81),
                                            width: 1.5),
                                      ),
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Text(
                                          scannedData,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Raleway',
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildStyledButton(
                                      label: "Proceed with Donation",
                                      onPressed: _handleDonationProcess,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (scannedData.isEmpty)
                        const Center(
                          child: const Text(
                            "Scan a valid QR code to proceed.",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Raleway',
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      _buildStyledButton(
                        label: "Upload from Gallery",
                        // style:
                        onPressed: _pickImageFromGallery,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledButton(
      {required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF432C81),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        elevation: 5,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'Raleway',
          color: Colors.white,
        ),
      ),
    );
  }

  void _processScannedData(String rawData) {
    setState(() {
      scannedData = rawData;
    });

    _showScannedDataDialog();
  }

  void _showScannedDataDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Automatically close the dialog after 10 seconds
        Future.delayed(const Duration(seconds: 10), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gradient Header with Deep Purple
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF432C81), Color(0xFF6546A0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              "Scanned QR Code Details",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Raleway',
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // **Scanned Data**
                        Text(
                          scannedData,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Close Button (Styled)
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.grey[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                            ),
                            child: const Text("Close"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });

        final File imageFile = File(image.path);

        print("Image picked: ${image.path}");
        print("File size: ${await imageFile.length()} bytes");

        // Decode QR code using ML Kit
        final String? qrData = await _decodeQRCode(imageFile);
        if (qrData != null) {
          setState(() {
            scannedData = qrData;
          });
          _showScannedDataDialog();
        } else {
          _showSnackBar("Failed to detect QR code.\nTry a clearer image.");
        }
      } else {
        _showSnackBar("No image was selected.");
      }
    } catch (e) {
      print("Error in _pickImageFromGallery: $e");
      _showSnackBar("Error processing image: $e");
    }
  }

  Future<String?> _decodeQRCode(File imageFile) async {
    final ml_kit.InputImage inputImage = ml_kit.InputImage.fromFile(imageFile);
    final ml_kit.BarcodeScanner barcodeScanner = ml_kit.BarcodeScanner();

    final List<ml_kit.Barcode> barcodes =
        await barcodeScanner.processImage(inputImage);

    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        return rawValue;
      }
    }
    return null;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline, // Icon indicating info
              color: Colors.white,
            ),
            const SizedBox(width: 8), // Space between the icon and text
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.bold, // Make text bold for emphasis
                  fontSize: 16, // Slightly larger font size
                  fontFamily: 'Raleway',
                ),
                overflow: TextOverflow.ellipsis, // Prevent text overflow
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF432C81),
        // Deep purple background
        behavior: SnackBarBehavior.floating,
        // Change to floating behavior
        duration: const Duration(seconds: 3),
        // Duration for the SnackBar
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        margin: const EdgeInsets.all(16),
        // Margin around the SnackBar
        elevation: 6, // Slight elevation for a 3D effect
      ),
    );
  }

  Future<void> _handleDonationProcess() async {
    final requestId = _extractRequestId(scannedData);
    final userId = widget.userId;

    DocumentSnapshot requestDoc = await FirebaseFirestore.instance
        .collection('blood_requests')
        .doc(requestId)
        .get();

    if (requestDoc.exists) {
      var scannedCount = requestDoc['scanned_count'];
      var requiredQuantity = requestDoc['required_quantity'];
      var waitingList = requestDoc['waiting_list'] ?? [];
      var donationList = requestDoc['donation_list'] ?? [];

      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(4, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gradient Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF432C81), Color(0xFF6546A0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                "Donation Request Details",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Raleway',
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // **Request Details** with improved styling
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Request ID: $requestId",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Raleway', // Stylish Font
                                  color: Color(0xFF432C81), // Deep Purple
                                ),
                              ),
                              const SizedBox(height: 4), // Spacing between text

                              Text(
                                "Scanned Count: $scannedCount",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Raleway',
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                "Required Quantity: $requiredQuantity",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Raleway',
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                "Donation List Count: ${donationList.length}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Raleway',
                                  color:
                                      Colors.green, // Green for donation count
                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                "Waiting List Count: ${waitingList.length}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Raleway',
                                  color: Colors.red, // Red for waiting count
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (scannedCount < requiredQuantity)
                                ElevatedButton(
                                  onPressed: () async {
                                    bool userAlreadyInDonationList =
                                        donationList.any((user) =>
                                            user['user_id'] == userId);

                                    if (!userAlreadyInDonationList) {
                                      await FirebaseFirestore.instance
                                          .collection('blood_requests')
                                          .doc(requestId)
                                          .update({
                                        'scanned_count':
                                            FieldValue.increment(1),
                                        'donation_list': FieldValue.arrayUnion([
                                          {
                                            'user_id': userId,
                                            'user_name': widget.userName,
                                            'status': 'donated'
                                          }
                                        ]),
                                      });

                                      Navigator.pop(context);
                                      _showSnackBar("Donation confirmed!");
                                    } else {
                                      Navigator.pop(context);
                                      _showSnackBar(
                                          "You have already donated!");
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xFF432C81),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 20),
                                  ),
                                  child: const Text("Confirm Donation"),
                                ),

                              // Only allow users to join the waiting room if scannedCount >= requiredQuantity AND they haven’t donated yet
                              if (scannedCount >= requiredQuantity &&
                                  !donationList
                                      .any((user) => user['user_id'] == userId))
                                ElevatedButton(
                                  onPressed: () async {
                                    bool userAlreadyInWaitingList =
                                        waitingList.any((user) =>
                                            user['user_id'] == userId);

                                    if (!userAlreadyInWaitingList) {
                                      await FirebaseFirestore.instance
                                          .collection('blood_requests')
                                          .doc(requestId)
                                          .update({
                                        'waiting_list': FieldValue.arrayUnion([
                                          {
                                            'user_id': userId,
                                            'user_name': widget.userName,
                                            'status': 'waiting'
                                          }
                                        ]),
                                      });

                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WaitingRoomScreen(
                                                  requestId: requestId,
                                                  userName: widget.userName),
                                        ),
                                      );
                                      _showSnackBar(
                                          "You are added to the waiting list.");
                                    } else {
                                      // Directly navigate to the WaitingRoomScreen
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WaitingRoomScreen(
                                            requestId: requestId,
                                            userName: widget.userName,
                                          ),
                                        ),
                                      );
                                      _showSnackBar(
                                          "You are already in the waiting list.");
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 20),
                                  ),
                                  child: const Text("Join Waiting Room"),
                                ),

                              // Cancel Button
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.grey[600],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 20),
                                ),
                                child: const Text("Cancel"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      _showSnackBar("Invalid donation request!");
    }
  }

  String _extractRequestId(String scannedData) {
    final requestData = scannedData.split("\n");
    return requestData[0].split(": ")[1];
  }
}
