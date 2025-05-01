import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;

class PdfService {
  static Future<File> generateAppointmentPdf({
    required String email,
    required String doctorName,
    required String appointmentDate,
    required String appointmentTime,
  }) async {
    final pdf = pw.Document();

    // Load custom Raleway fonts
    final ralewayRegular =
    pw.Font.ttf(await rootBundle.load("assets/fonts/Raleway-SemiBold.ttf"));
    final ralewayBold =
    pw.Font.ttf(await rootBundle.load("assets/fonts/Raleway-Bold.ttf"));
    final ralewayExtraBold = pw.Font.ttf(
        await rootBundle.load("assets/fonts/Raleway-ExtraBold.ttf"));

    // Load images
    final ByteData certFirstImgData = await rootBundle
        .load("assets/images/certificate_img/cert_first_img.png");
    final ByteData certSecImgData =
    await rootBundle.load("assets/images/certificate_img/cert_sec_img.png");
    final ByteData certThirdImgData = await rootBundle
        .load("assets/images/certificate_img/cert_third_img.png");

    final Uint8List certFirstImgBytes = certFirstImgData.buffer.asUint8List();
    final Uint8List certSecImgBytes = certSecImgData.buffer.asUint8List();
    final Uint8List certThirdImgBytes = certThirdImgData.buffer.asUint8List();

    final pw.ImageProvider certFirstImg = pw.MemoryImage(certFirstImgBytes);
    final pw.ImageProvider certSecImg = pw.MemoryImage(certSecImgBytes);
    final pw.ImageProvider certThirdImg = pw.MemoryImage(certThirdImgBytes);

    // Load HealthHub Logo (If Available)
    pw.ImageProvider? healthHubLogo;
    try {
      final ByteData logoData =
      await rootBundle.load("assets/logo/LOGO_HH.png");
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      healthHubLogo = pw.MemoryImage(logoBytes);
    } catch (e) {
      print("HealthHub logo not found, skipping...");
    }

    // Generate QR code data
    final qrData =
        "Email: $email\nDoctor: $doctorName\nDate: $appointmentDate\nTime: $appointmentTime";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // 🔴 Header with Red Background
            pw.Container(
              width: double.infinity,
              color: PdfColors.red,
              padding: const pw.EdgeInsets.all(15),
              child: pw.Column(
                children: [
                  pw.Text(
                    "Appointment Confirmation",
                    style: pw.TextStyle(
                        fontSize: 24,
                        font: ralewayExtraBold,
                        color: PdfColors.white),
                  ),
                  pw.Text(
                    "HealthHub Medical Services",
                    style: pw.TextStyle(
                        fontSize: 18,
                        font: ralewayRegular,
                        color: PdfColors.white),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // 🎉 Welcome Message
            pw.Text(
              "Appointment Details",
              style: pw.TextStyle(
                fontSize: 22,
                font: ralewayBold,
                color: PdfColors.black,
              ),
            ),
            pw.Text(
              "Thank you for choosing HealthHub!",
              style: pw.TextStyle(
                  fontSize: 14, font: ralewayRegular, color: PdfColors.grey),
            ),

            pw.SizedBox(height: 25),

            // 🏥 Appointment Details
            _buildDetailRow(
                "Email", email, certFirstImg, ralewayBold, ralewayRegular),
            _buildDetailRow(
                "Doctor", doctorName, certSecImg, ralewayBold, ralewayRegular),
            _buildDetailRow("Date", appointmentDate, certThirdImg, ralewayBold,
                ralewayRegular),
            _buildDetailRow("Time", appointmentTime, certThirdImg, ralewayBold,
                ralewayRegular),

            pw.SizedBox(height: 40),

            // 📱 QR Code
            pw.Column(
              children: [
                pw.Text(
                  "Scan QR Code at Check-in",
                  style: pw.TextStyle(
                      fontSize: 14, font: ralewayBold, color: PdfColors.black),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: 150,
                  height: 150,
                  child: pw.BarcodeWidget(
                    data: qrData,
                    barcode: pw.Barcode.qrCode(),
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // 👏 Footer Message
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              color: PdfColors.grey200,
              child: pw.Text(
                "Please arrive 10 minutes early for your appointment",
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    fontSize: 14, font: ralewayBold, color: PdfColors.black),
              ),
            ),

            pw.SizedBox(height: 10),

            // 🏛️ Copyright Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "© Copyright HealthHub - All Rights Reserved",
                  style: pw.TextStyle(
                    fontSize: 10,
                    font: ralewayRegular,
                    color: PdfColors.grey600,
                  ),
                ),
                if (healthHubLogo != null) pw.Image(healthHubLogo, width: 40),
              ],
            ),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/appointment.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildDetailRow(String label, String value,
      pw.ImageProvider icon, pw.Font boldFont, pw.Font regularFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        children: [
          pw.Image(icon, width: 20),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 14, font: boldFont, color: PdfColors.black)),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 14, font: regularFont, color: PdfColors.black)),
            ],
          ),
        ],
      ),
    );
  }
}
