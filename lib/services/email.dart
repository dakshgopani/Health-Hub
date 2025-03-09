import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static Future<void> sendEmail(String email, File pdfFile) async {
    // SMTP server settings
    String username = 'vinit06shah@gmail.com'; // Replace with your email
    String password = 'ehdi nwdh hwak milb'; // Replace with your app password

    final smtpServer = gmail(username, password);

    // Create the email
    final message = Message()
      ..from = Address(username, 'Health Hub Appointment Booking App')
      ..recipients.add(email)
      ..subject = 'Appointment Confirmation'
      ..text = 'Please find your appointment details attached.'
      ..attachments.add(FileAttachment(pdfFile));

    try {
      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Failed to send email: $e');
      throw e;
    }
  }
}
