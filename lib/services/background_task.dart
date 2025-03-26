import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await NotificationService.showNotification();
    return Future.value(true);
  });
}

Future<void> initializeBackgroundTask() async {
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Register periodic task for notifications every 15 minutes
  Workmanager().registerPeriodicTask(
    "task-1",
    "showNotificationTask",
    frequency: Duration(minutes: 60),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}
