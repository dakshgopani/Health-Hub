import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/background_task.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase(); // Firebase initialization

  // Initialize Notification Service
  await NotificationService.initialize();

  // Request notification permissions before showing a notification
  await NotificationService.requestPermissions();

  runApp(MyApp());

  // Initialize Background Task for WorkManager (run after UI starts)
  await initializeBackgroundTask();
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // for platform-specific options
  );
}
