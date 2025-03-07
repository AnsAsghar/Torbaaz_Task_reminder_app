import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:todo_apps/models/task.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:todo_apps/ui/notification_detail_page.dart';

class NotifyHelper {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  initializeNotification() async {
    await _configureLocalTimezone();
    print("Initializing notifications");

    // Android Initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    // For on tap notification
    void onDidReceiveNotificationResponse(
        NotificationResponse notificationResponse) async {
      final String? payload = notificationResponse.payload;
      print("Notification payload: $payload");
      if (notificationResponse.payload != null) {
        debugPrint('notification payload: $payload');

        // Check if this is a task alarm notification
        if (payload!.contains("ALARM:")) {
          // Extract task data and show full-screen alarm
          final taskData = payload.split("ALARM:")[1].split("|");
          if (taskData.length >= 3) {
            final task = Task(
              id: int.tryParse(taskData[0]),
              title: taskData[1],
              note: taskData[2],
              color: int.tryParse(taskData.length > 3 ? taskData[3] : "0") ?? 0,
            );

            // Show the full-screen alarm via a callback to HomePage
            Get.toNamed('/fullScreenAlarm', arguments: task);
          }
        } else {
          // Regular notification, show detail page
          Get.to(() => NotificationDetailPage(
                label: payload,
              ));
        }
      }
    }

    // iOS Initialization
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        // Display a dialog with the notification details
        Get.dialog(
          AlertDialog(
            title: Text(title ?? 'ToDo Apps'),
            content: Text(body ?? 'Welcome to flutter apps'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // Close the dialog
                },
                child: const Text('Ok'),
              ),
            ],
          ),
        );
      },
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    print("Notifications initialized successfully");
  }

  // Request Permissions for iOS
  void requestIOSPermissions() {
    // Skip for web platform
  }

  // Request Permissions for Android
  Future<void> requestAndroidPermissions() async {
    print("Requesting Android permissions");
    try {
      // Request the required permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.notification,
        Permission.scheduleExactAlarm,
        // Add other permissions as needed
      ].request();

      // Check if the permissions are granted
      if (statuses[Permission.notification] == PermissionStatus.granted &&
          statuses[Permission.scheduleExactAlarm] == PermissionStatus.granted) {
        print("Android permissions granted");
      } else {
        print("Android permissions denied");
        Get.snackbar("Permission Denied",
            "Please allow Notification permission from settings",
            backgroundColor: Colors.redAccent, colorText: Colors.white);

        // If permissions are denied, we cannot continue the app
        await [
          Permission.notification,
          Permission.scheduleExactAlarm,
        ].request();
      }
    } catch (e) {
      print("Error requesting Android permissions: $e");
    }
  }

  Future<bool> requestScheduleExactAlarmPermission() async {
    try {
      if (await Permission.scheduleExactAlarm.request().isGranted) {
        // Either the permission was already granted before or the user just granted it.
        print("Schedule exact alarm permission granted");
        return true;
      } else {
        print("Schedule exact alarm permission denied");
        await Permission.scheduleExactAlarm.isDenied.then((value) {
          if (value) {
            Permission.scheduleExactAlarm.request();
          }
        });
        return false;
      }
    } catch (e) {
      print("Error requesting schedule exact alarm permission: $e");
      return false;
    }
  }

  // Immediate Notification
  Future<void> displayNotification(
      {required String title, required String body}) async {
    print("Displaying notification: $title - $body");
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        playSound: true,
        icon: 'app_icon',
        sound: RawResourceAndroidNotificationSound('mixkit_urgen_loop'),
        largeIcon: DrawableResourceAndroidBitmap('app_icon'),
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: "$title | $body |",
      );
      print("Notification displayed successfully");
    } catch (e) {
      print("Error displaying notification: $e");
    }
  }

  //  Scheduled Notification
  Future<void> scheduledNotification(int hour, int minutes, Task task) async {
    print("Scheduling notification for task: ${task.title} at $hour:$minutes");
    try {
      String msg = "🔴Now your task starting⏰.";

      tz.TZDateTime scheduledDate = await _convertTime(hour, minutes);
      print("Scheduled date: $scheduledDate");

      // Also schedule a full-screen alarm notification
      await scheduleAlarmNotification(hour, minutes, task);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id!.toInt(),
        "🔴${task.title}",
        task.note,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'your channel id',
            'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
            playSound: true,
            icon: 'app_icon',
            sound:
                const RawResourceAndroidNotificationSound('mixkit_urgen_loop'),
            // largeIcon: const DrawableResourceAndroidBitmap('app_icon'),
            subText: msg,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: "${task.title}|${task.note}|${task.startTime}|",
      );
      print("Notification scheduled successfully");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  // Schedule a full-screen alarm notification
  Future<void> scheduleAlarmNotification(
      int hour, int minutes, Task task) async {
    print(
        "Scheduling alarm notification for task: ${task.title} at $hour:$minutes");
    try {
      tz.TZDateTime scheduledDate = await _convertTime(hour, minutes);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id!.toInt() + 1000, // Use a different ID to avoid conflicts
        "⏰ TASK ALARM: ${task.title}",
        "It's time for your task! ${task.note}",
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            'Task Alarms',
            channelDescription: 'Full screen alarms for tasks',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true, // Make it a full-screen intent
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('alarm_sound'),
            icon: 'app_icon',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: "ALARM:${task.id}|${task.title}|${task.note}|${task.color}",
      );
      print("Alarm notification scheduled successfully");
    } catch (e) {
      print("Error scheduling alarm notification: $e");
    }
  }

  Future<void> remindNotification(int hour, int minutes, Task task) async {
    print(
        "Scheduling reminder notification for task: ${task.title} at $hour:$minutes");
    try {
      tz.TZDateTime scheduledDate = await _convertTime(hour, minutes);
      print("Reminder scheduled date: $scheduledDate");

      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id!.toInt() + 1,
        "⚠️ Don't forget to complete your task.",
        "At ${task.startTime}🔴${task.title}",
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'channel id',
            'channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
            playSound: true,
            icon: 'app_icon',
            largeIcon: const DrawableResourceAndroidBitmap('app_icon'),
            subText: "⏰ ${task.remind} minute's remaining",
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("Reminder notification scheduled successfully");
    } catch (e) {
      print("Error scheduling reminder notification: $e");
    }
  }

  Future<void> cancelNotification(int notificationId) async {
    print("Cancelling notification with ID: $notificationId");
    try {
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      print("Notification cancelled successfully");
    } catch (e) {
      print("Error cancelling notification: $e");
    }
  }

  Future<tz.TZDateTime> _convertTime(int hour, int minutes) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    print("Current time: $now");

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minutes,
    );
    print("Initial scheduled date: $scheduledDate");

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print("Adjusted scheduled date: $scheduledDate");
    }

    return scheduledDate;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      tz.initializeTimeZones();
      final String timeZone = await FlutterTimezone.getLocalTimezone();
      print("Local timezone: $timeZone");
      try {
        tz.setLocalLocation(tz.getLocation(timeZone));
        print("Local timezone set successfully");
      } catch (e) {
        // If the location is not found, set a default location
        print("Error setting local timezone: $e");
        tz.setLocalLocation(tz.getLocation('UTC'));
        print("Default timezone set to UTC");
      }
    } catch (e) {
      print("Error configuring local timezone: $e");
    }
  }
}
