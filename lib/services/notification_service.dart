import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static List<Map<String, String>> _predefinedMessages = [];

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInitialize =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidInitialize);

    await _notificationsPlugin.initialize(initializationSettings);

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Load predefined messages from JSON
    await _loadPredefinedMessages();
  }

  static Future<void> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }


  static Future<void> _loadPredefinedMessages() async {
    try {
      final String response =
      await rootBundle.loadString('assets/json/health_tips.json');
      List<dynamic> jsonData = json.decode(response);

      _predefinedMessages = jsonData.map((item) {
        return {
          "title": item["title"].toString(),
          "body": item["body"].toString()
        };
      }).toList();
    } catch (e) {
      print("Error loading predefined messages: $e");
    }
  }

  static Future<void> showNotification() async {
    Random random = Random();

    if (_predefinedMessages.isEmpty) {
      await _loadPredefinedMessages();
    }

    Map<String, String> tip =
    _predefinedMessages[random.nextInt(_predefinedMessages.length)];

    AndroidNotificationDetails androidDetails = const AndroidNotificationDetails(
      'channel_id',
      'Healthcare Notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // App logo on right side
    );

    NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      Random().nextInt(1000), // Unique ID
      tip["title"]!,
      tip["body"]!,
      details,
    );
  }
}
