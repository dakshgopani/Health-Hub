import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static Future<void> sendEmail(String email, File pdfFile) async {
    String username = 'vinit06shah@gmail.com';
    String password = 'ehdi nwdh hwak milb';

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Health Hub - Blood Donation')
      ..recipients.add(email)
      ..subject = 'Blood Donation Certificate'
      ..text = 'Dear Donor,\n\nThank you for donating blood. Please find your certificate attached.'
      ..attachments.add(FileAttachment(pdfFile));

    try {
      await send(message, smtpServer);
      print('✅ Email sent successfully!');
    } catch (e) {
      print('❌ Email sending failed: $e');
      throw e;
    }
  }
}
