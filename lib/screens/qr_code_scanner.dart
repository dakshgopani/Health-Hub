import 'package:flutter/material.dart';
import 'package:mad_practice_one/screens/waiting_room.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanQRCodeScreen extends StatefulWidget {
  final String userId;

  const ScanQRCodeScreen({super.key, required this.userId});

  @override
  State<ScanQRCodeScreen> createState() => _ScanQRCodeScreenState();
}

class _ScanQRCodeScreenState extends State<ScanQRCodeScreen> {
  String scannedData = "";
  final MobileScannerController _mobileScannerController = MobileScannerController();
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code for Donation"),
      ),
      body: Column(
        children: [
          // Fixed-height Camera Scanner
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5, // 50% of the screen height
            child: Stack(
              children: [
                // Camera Scanner for live QR Code scanning
                MobileScanner(
                  controller: _mobileScannerController,
                  onDetect: (BarcodeCapture barcodeCapture) {
                    final barcode = barcodeCapture.barcodes.first;
                    if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                      _processScannedData(barcode.rawValue!);
                    }
                  },
                ),
                // Overlay to guide the user where to place the QR code
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 200, // Width of the QR code scan window
                    height: 200, // Height of the QR code scan window
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content below the camera
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (scannedData.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Scanned Data: $scannedData"),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _handleDonationProcess,
                            child: const Text("Proceed with Donation"),
                          ),
                        ],
                      ),
                    if (scannedData.isEmpty)
                      const Text("Scan a valid QR code to proceed."),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pickImageFromGallery,
                      child: const Text("Upload from Gallery"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        return AlertDialog(
          title: const Text("Scanned QR Code Details"),
          content: Text(scannedData),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final String imagePath = image.path;
        final scannedData = await _scanQRCodeFromImage(imagePath);

        if (scannedData != null && scannedData.isNotEmpty) {
          _processScannedData(scannedData);
        } else {
          _showSnackBar("No QR code found in the image.");
        }
      } else {
        _showSnackBar("No image was selected.");
      }
    } catch (e) {
      _showSnackBar("Failed to process the image: $e");
    }
  }

  Future<String?> _scanQRCodeFromImage(String imagePath) async {
    try {
      final barcodeCapture = await _mobileScannerController.analyzeImage(imagePath);

      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        final barcode = barcodeCapture.barcodes.first;
        return barcode.rawValue;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void _handleDonationProcess() async {
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
          return AlertDialog(
            title: const Text("Donation Request Details"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Request ID: $requestId"),
                Text("Scanned Count: $scannedCount"),
                Text("Required Quantity: $requiredQuantity"),
                Text("Waiting List Count: ${waitingList.length}"),
                Text("Donation List Count: ${donationList.length}"),
              ],
            ),
            actions: [
              if (scannedCount < requiredQuantity)
                TextButton(
                  onPressed: () async {
                    scannedCount++;
                    await FirebaseFirestore.instance
                        .collection('blood_requests')
                        .doc(requestId)
                        .update({
                      'scanned_count': scannedCount,
                      'donation_list': FieldValue.arrayUnion([userId]),
                    });

                    Navigator.pop(context);
                    _showSnackBar("Donation confirmed!");
                  },
                  child: const Text("Confirm Donation"),
                ),
              if (scannedCount >= requiredQuantity)
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('blood_requests')
                        .doc(requestId)
                        .update({
                      'waiting_list': FieldValue.arrayUnion([userId]),
                    });

                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WaitingRoomScreen(requestId: requestId),
                      ),
                    );
                  },
                  child: const Text("Join Waiting Room"),
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
            ],
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
