import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:ui';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class QRCodeScreen extends StatefulWidget {
  final String qrCodeData;

  const QRCodeScreen({required this.qrCodeData, Key? key}) : super(key: key);

  @override
  _QRCodeScreenState createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  bool _isSaving = false;
  bool _hasSavedQRCode = false;

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

  Future<void> _saveQRCodeToGallery() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final permissionStatus = await Permission.photos.request();
      if (!permissionStatus.isGranted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Gallery access permission denied")),
        // );
        _showSnackBar("Gallery access permission denied");

        setState(() {
          _isSaving = false;
        });
        return;
      }

      final qrCode = QrPainter(
        data: widget.qrCodeData,
        version: QrVersions.auto,
        gapless: false,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      final tempDir = await getTemporaryDirectory();
      final qrFile = File('${tempDir.path}/qr_code.png');

      final pictureRecorder = PictureRecorder();
      final canvas = Canvas(pictureRecorder);

      const double qrSize = 300;
      const double padding = 50;
      const double totalSize = qrSize + (2 * padding);

      final paint = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, totalSize, totalSize), paint);
      canvas.translate(padding, padding);
      qrCode.paint(canvas, const Size(qrSize, qrSize));

      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(totalSize.toInt(), totalSize.toInt());
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      await qrFile.writeAsBytes(buffer);

      final assetEntity = await PhotoManager.editor.saveImage(
        buffer,
        title: "qr_code_${DateTime.now().millisecondsSinceEpoch}.png",
        filename: 'qrCode.png',
      );

      if (assetEntity != null) {
        setState(() {
          _hasSavedQRCode = true;
        });
        _showSnackBar("QR Code saved to gallery!");

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("QR Code saved to gallery!")),
        // );
      } else {
        _showSnackBar("Failed to save the QR Code.");
      }
    } catch (e) {
      print("Error saving image: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Error: $e")),
      // );
      _showSnackBar("Error : $e");
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _goBack() async {
    // Close only the current screen if possible
  }

  Future<void> _confirmExit() async {
    if (_hasSavedQRCode) {
      Navigator.pop(context, true);
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }

    bool? shouldExit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF432C81), Color(0xFF6546A0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(
                child: Text(
                  "Exit without Saving?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Raleway',
                  ),
                ),
              ),
            ),

            // Body Text
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Are you sure you want to exit without saving the QR code?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Raleway',
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // ✅ Save QR Code First
                        await _saveQRCodeToGallery();

                        Navigator.pop(context, true);
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text("Save & Exit"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF432C81),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // ✅ Close all dialogs and navigate back
                        Navigator.pop(context, true);
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.exit_to_app, color: Colors.white),
                      label: const Text("Exit"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (shouldExit == true) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _confirmExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEDECF4),
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(
            color: Colors.white,
            weight: 900,
            size: 26,
          ),
          title: Text(
            "Your QR Code",
            style: AppTextStyles.whiteHeading.copyWith(fontWeight: FontWeight.w900),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _confirmExit,
          ),
          backgroundColor: AppColors.deepPurple,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Image
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF432C81), Colors.deepPurpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    "assets/qr_scan_img.png",
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // QR Code Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF432C81).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: -5,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          "Your Donation QR Code",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Raleway'),
                        ),
                        const SizedBox(height: 20),
                        QrImageView(
                          data: widget.qrCodeData,
                          version: QrVersions.auto,
                          size: 200.0,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveQRCodeToGallery,
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text("Save to Gallery"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF432C81),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _confirmExit,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text("Go Back"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
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
