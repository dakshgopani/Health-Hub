import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:qr/qr.dart';

class PdfService {
  static Future<File> generateAppointmentPdf({
    required String email,
    required String doctorName,
    required String appointmentDate,
    required String appointmentTime,
  }) async {
    final pdf = pw.Document();

    // Generate QR code data
    final qrData =
        "Email: $email\nDoctor: $doctorName\nDate: $appointmentDate\nTime: $appointmentTime";
    final qrCode = QrCode(10, QrErrorCorrectLevel.L)..addData(qrData);
    final qrImage = QrImage(qrCode);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue, width: 2),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildAppointmentDetails(
                  email, doctorName, appointmentDate, appointmentTime),
              pw.SizedBox(height: 20),
              _buildQrCode(qrData),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/appointment.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      color: PdfColors.blue,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'HealthHub',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Appointment Confirmation',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAppointmentDetails(
    String email,
    String doctorName,
    String appointmentDate,
    String appointmentTime,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Email', email),
          _buildDetailRow('Doctor', doctorName),
          _buildDetailRow('Date', appointmentDate),
          _buildDetailRow('Time', appointmentTime),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  static pw.Widget _buildQrCode(String qrData) {
    return pw.Column(
      children: [
        pw.Text(
          'Scan this QR code at the venue',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
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
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text(
        'Please arrive 10 minutes early for your scheduled appointment.',
        style: pw.TextStyle(
          fontSize: 12,
          color: PdfColors.grey,
          fontStyle: pw.FontStyle.italic,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
