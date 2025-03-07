import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:todo_apps/db/db.helper.dart';
import 'package:todo_apps/models/task.dart';

class TaskController extends GetxController {
  var taskList = <Task>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    getTasks();
  }

  Future<int> addTask({Task? task}) async {
    int id = await DBHelper.insert(task!);
    getTasks(); // Refresh the task list after adding a new task
    return id;
  }

  void getTasks() async {
    isLoading.value = true;
    try {
      List<Map<String, dynamic>> tasks = await DBHelper.query();
      taskList.assignAll(tasks.map((data) => Task.fromJson(data)).toList());
    } catch (e) {
      print("Error fetching tasks: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void deleteTask(int id) async {
    await DBHelper.delete(id);
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.cancel(id);
    flutterLocalNotificationsPlugin
        .cancel(id + 1); // Cancel reminder notification too
    flutterLocalNotificationsPlugin
        .cancel(id + 1000); // Cancel alarm notification too
    getTasks(); // Refresh the task list after deleting a task
  }

  void markTaskAsCompleted(int id, bool isCompleted) async {
    await DBHelper.updateTask(id, isCompleted);
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    if (isCompleted) {
      flutterLocalNotificationsPlugin.cancel(id);
      flutterLocalNotificationsPlugin
          .cancel(id + 1); // Cancel reminder notification too
      flutterLocalNotificationsPlugin
          .cancel(id + 1000); // Cancel alarm notification too
    }
    getTasks(); // Refresh the task list after marking a task as completed
  }

  Future<void> updateTaskInfo(Task task) async {
    await DBHelper.updateTaskInfo(task);
    getTasks(); // Refresh the task list after updating a task
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    await DBHelper.initDb(); // Ensure database is initialized
    getTasks(); // Fetch all tasks when the controller is ready
  }
}
