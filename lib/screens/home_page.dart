import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mad_practice_one/screens/qr_code_scanner.dart';
import 'package:mad_practice_one/screens/waiting_room.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'profile_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';



class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Blood donation request details
  String bloodGroup = "A+";
  String requiredQuantity = "2 units";
  String hospitalName = "City Hospital";
  String hospitalLocation = "Downtown, XYZ";
  String qrCodeData = ""; // Holds the QR data to display
  Map<String, dynamic> parsedData = {};  // Holds parsed data from QR code

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildUserNameStream(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to Profile Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _buildDonationCard(), // Display donation details
            const SizedBox(height: 30),
            if (qrCodeData.isNotEmpty)
              Column(
                children: [
                  const Text(
                    "Your Donation QR Code",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: qrCodeData,
                    version: QrVersions.auto,
                    size: 200.0,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveQRCodeToGallery,  // Save QR code to gallery
                    child: const Text("Save to Gallery"),
                  ),
                ],
              )
            else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Extracted StreamBuilder for User Name
  Widget _buildUserNameStream() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('User not found');
        }

        String userName = snapshot.data?.get('name') ?? 'User';
        return Text('Welcome, $userName');
      },
    );
  }

  Future<void> checkPermissions() async {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      // Permissions already granted, proceed with accessing photos
    } else {
      // Request permissions
      var statusRequest = await Permission.storage.request();
      if (statusRequest.isGranted) {
        // Permissions granted, proceed with accessing photos
      } else {
        // Handle permission denied
        print("Permission denied");
      }
    }
  }

  Future<void> requestStoragePermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      print("Storage permission granted");
      // Proceed with accessing storage
    } else if (status.isDenied) {
      print("Storage permission denied");
      // Handle permission denial
    } else if (status.isPermanentlyDenied) {
      print("Storage permission permanently denied. Open app settings.");
      await openAppSettings();
    }
  }

  Future<void> _requestGalleryPermission() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gallery access permission denied")),
      );
    }
  }

  Future<void> _requestStoragePermission() async {
    // Check if permission to access the photos has been granted
    final permissionStatus = await Permission.photos.request();

    if (permissionStatus.isGranted) {
      // Permission granted, proceed to save QR code
      print("Gallery permission granted");
    } else if (permissionStatus.isDenied) {
      // Permission denied, show a message or handle denial
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gallery access permission denied")),
      );
    } else if (permissionStatus.isPermanentlyDenied) {
      // Open app settings to allow users to grant the permission manually
      await openAppSettings();
    }
  }


  Future<void> _saveQRCodeToGallery() async {
    try {
      // Request permission before attempting to save the image
      final permissionStatus = await Permission.photos.request();

      if (!permissionStatus.isGranted) {
        // Handle permission denied case
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gallery access permission denied")),
        );
        return;
      }

      // Proceed with saving the QR code image after permission is granted
      final qrCode = QrPainter(
        data: qrCodeData,
        version: QrVersions.auto,
        gapless: false,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      final tempDir = await getTemporaryDirectory();
      final qrFile = File('${tempDir.path}/qr_code.png');
      final pictureRecorder = PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = Size(200, 200); // Size of the QR code image
      qrCode.paint(canvas, size);
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      await qrFile.writeAsBytes(buffer);

      // Save the image to the gallery using photo_manager
      final assetEntity = await PhotoManager.editor.saveImage(
        buffer,
        title: "qr_code_${DateTime.now().millisecondsSinceEpoch}.png",
        filename: 'qrCode.png',
      );

      if (assetEntity != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QR Code saved to gallery!")),
        );
      } else {
        throw Exception("Failed to save the QR Code.");
      }
    } catch (e) {
      print("Error saving image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }







  /// Modernized Donation Details Card
  Widget _buildDonationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Blood Donation Request",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 10),
            Text("Blood Group: $bloodGroup",
                style: const TextStyle(fontSize: 16)),
            Text("Required Quantity: $requiredQuantity",
                style: const TextStyle(fontSize: 16)),
            Text("Hospital: $hospitalName",
                style: const TextStyle(fontSize: 16)),
            Text("Location: $hospitalLocation",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _showDonationDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Donate Blood"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle the submission logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Submitted"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show Donation Details Dialog
  void _showDonationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Blood Donation Details"),
          content: _buildDialogContent(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            if (qrCodeData.isEmpty)
              ElevatedButton(
                onPressed: () {
                  _donateBlood();
                  Navigator.of(context).pop();
                },
                child: const Text("Donate"),
              ),
            if (qrCodeData.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close"),
              ),
          ],
        );
      },
    );
  }

  /// Dialog Content for Donation Details
  /// Dialog Content for Donation Details
  Widget _buildDialogContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Blood Group: $bloodGroup"),
        Text("Required Quantity: $requiredQuantity"),
        Text("Hospital: $hospitalName"),
        Text("Location: $hospitalLocation"),
        const SizedBox(height: 20),
        if (qrCodeData.isNotEmpty) // Show only when QR code data is present
          Center(
            child: Column(
              children: parsedData.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "${entry.key}: ${entry.value}",
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  /// Generate QR Data (Formatted Human-readable String)
  String _generateQRData({bool encryptData = true}) {
    final requestData = [
      "Request ID: req_12345",
      "Donor ID: ${widget.userId}",
      "Hospital ID: hospital_98765",
      "Timestamp: ${DateTime.now().toIso8601String()}",
      "Blood Group: $bloodGroup",
      "Required Quantity: $requiredQuantity",
      "Hospital: $hospitalName",
      "Location: $hospitalLocation",
    ];

    // Concatenate all information into a single string with line breaks or separators
    return requestData.join("\n");
  }


  void _donateBlood() {
    // Check if a QR code already exists
    if (qrCodeData.isNotEmpty) {
      _showConfirmationDialog();
    } else {
      // Generate new QR code with minimal information
      setState(() {
        qrCodeData = _generateQRData();
      });

      // Provide user feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR Code generated successfully!")),
      );
    }
  }

  /// Show Confirmation Dialog for Regeneration
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Regenerate QR Code?"),
          content: const Text(
            "A QR code already exists. Do you want to regenerate it?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog

                // Regenerate the QR code
                setState(() {
                  qrCodeData = _generateQRData();
                  parsedData = jsonDecode(qrCodeData); // Parse the QR code data
                });

                // Provide user feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("QR Code regenerated successfully!")),
                );
              },
              child: const Text("Regenerate"),
            ),
          ],
        );
      },
    );
  }
}
