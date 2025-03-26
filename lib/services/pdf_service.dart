import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;

class PdfService {
  static Future<File> generateDonationCertificate({
    required String userName,
    required String hospitalName,
    required String hospitalAddress,
    required String donationDate,
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
    final ByteData medalData =
    await rootBundle.load("assets/images/certificate_img/medal.png");
    final ByteData certFirstImgData = await rootBundle
        .load("assets/images/certificate_img/cert_first_img.png");
    final ByteData certSecImgData =
    await rootBundle.load("assets/images/certificate_img/cert_sec_img.png");
    final ByteData certThirdImgData = await rootBundle
        .load("assets/images/certificate_img/cert_third_img.png");

    final Uint8List medalBytes = medalData.buffer.asUint8List();
    final Uint8List certFirstImgBytes = certFirstImgData.buffer.asUint8List();
    final Uint8List certSecImgBytes = certSecImgData.buffer.asUint8List();
    final Uint8List certThirdImgBytes = certThirdImgData.buffer.asUint8List();

    final pw.ImageProvider medalImage = pw.MemoryImage(medalBytes);
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

    // Load Signature Image (If Available)
    pw.ImageProvider? signatureImage;
    try {
      final ByteData signatureData =
      await rootBundle.load("assets/images/certificate_img/cert_signature.jpg");
      final Uint8List signatureBytes = signatureData.buffer.asUint8List();
      signatureImage = pw.MemoryImage(signatureBytes);
    } catch (e) {
      print("Signature image not found, skipping...");
    }

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
                    "Certificate of Appreciation",
                    style: pw.TextStyle(
                        fontSize: 24,
                        font: ralewayExtraBold,
                        color: PdfColors.white),
                  ),
                  pw.Text(
                    "For Blood Donation",
                    style: pw.TextStyle(
                        fontSize: 18,
                        font: ralewayRegular,
                        color: PdfColors.white),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // 🏅 Medal Icon
            pw.Image(medalImage, width: 60),

            pw.SizedBox(height: 15),

            // 🎉 Congratulations Message
            pw.Text(
              "Congratulations, $userName!",
              style: pw.TextStyle(
                fontSize: 22,
                font: ralewayBold,
                color: PdfColors.black,
              ),
            ),
            pw.Text(
              "Your selfless act of donating blood has made a difference.",
              style: pw.TextStyle(
                  fontSize: 14, font: ralewayRegular, color: PdfColors.grey),
            ),

            pw.SizedBox(height: 25),

            // 🏥 Donation Details
            _buildDetailRow("Donation Location", hospitalName, certFirstImg,
                ralewayBold, ralewayRegular),
            _buildDetailRow("Hospital Address", hospitalAddress, certSecImg,
                ralewayBold, ralewayRegular),
            _buildDetailRow("Date of Donation", donationDate, certThirdImg,
                ralewayBold, ralewayRegular),

            pw.SizedBox(height: 40),

            // 🖊️ Signature & Verification
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    if (signatureImage != null) pw.Image(signatureImage, width: 80),
                    pw.Container(
                      width: 80,
                      height: 2,
                      color: PdfColors.black,
                    ),
                    pw.Text(
                      "Authorized Signature",
                      style: pw.TextStyle(
                          fontSize: 12,
                          font: ralewayRegular,
                          color: PdfColors.grey700),
                    ),
                  ],
                ),
                if (healthHubLogo != null) pw.Image(healthHubLogo, width: 60),
              ],
            ),

            pw.SizedBox(height: 20),

            // 👏 Footer Appreciation Message
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              color: PdfColors.grey200,
              child: pw.Text(
                "Thank you for your contribution to saving lives!",
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    fontSize: 14, font: ralewayBold, color: PdfColors.black),
              ),
            ),

            pw.SizedBox(height: 10),

            // 🏛️ Copyright Footer
            pw.Text(
              "© Copyright HealthHub - All Rights Reserved",
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 10,
                font: ralewayRegular,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );

    // Save PDF file
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/donation_certificate.pdf");
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildDetailRow(
      String label,
      String value,
      pw.ImageProvider icon,
      pw.Font boldFont,
      pw.Font regularFont) {
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
