import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:torbaaz_reminder_app/controllers/task.controller.dart';
import 'package:torbaaz_reminder_app/db/db.helper.dart';
import 'package:torbaaz_reminder_app/models/task.dart';
import 'package:torbaaz_reminder_app/services/theme_services.dart';
import 'package:torbaaz_reminder_app/theme/theme.dart';
import 'package:torbaaz_reminder_app/ui/home_page.dart';
import 'package:torbaaz_reminder_app/ui/full_screen_alarm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await DBHelper.initDb();
  Get.put(TaskController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Task Reminder',
      debugShowCheckedModeBanner: false,
      theme: Themes.light,
      darkTheme: Themes.dark,
      themeMode: ThemeServices().theme,
      home: const HomePage(),
      getPages: [
        GetPage(
          name: '/',
          page: () => const HomePage(),
        ),
        GetPage(
          name: '/fullScreenAlarm',
          page: () => FullScreenAlarm(task: Get.arguments as Task),
          transition: Transition.fade,
        ),
      ],
    );
  }
}
