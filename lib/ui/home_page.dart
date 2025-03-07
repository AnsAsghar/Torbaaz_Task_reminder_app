import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:torbaaz_reminder_app/controllers/device_info.dart';
import 'package:torbaaz_reminder_app/controllers/task.controller.dart';
import 'package:torbaaz_reminder_app/models/task.dart';
import 'package:torbaaz_reminder_app/services/csv_services.dart';
import 'package:torbaaz_reminder_app/services/excel_services.dart';
import 'package:torbaaz_reminder_app/services/notification_services.dart';
import 'package:torbaaz_reminder_app/services/pdf_services.dart';
import 'package:torbaaz_reminder_app/services/theme_services.dart';
import 'package:torbaaz_reminder_app/theme/theme.dart';
import 'package:torbaaz_reminder_app/ui/add_task_bar.dart';
import 'package:torbaaz_reminder_app/ui/widgets/button.dart';
import 'package:torbaaz_reminder_app/ui/widgets/task_tile.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TaskController _taskController = Get.put(TaskController());
  List<Task> filterTaskList = [];

  double? width;
  double? height;

  // ignore: prefer_typing_uninitialized_variables
  var notifyHelper;
  String? deviceName;
  bool shorted = false;

  // User name storage
  final _storage = GetStorage();
  String _userName = "";

  DateTime _selectedDate = DateTime.now();

  // Add a notifications enabled flag
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();

    // Initialize the task controller and get tasks
    _taskController.getTasks();
    filterTaskList = _taskController.taskList;

    // Check if user name exists in storage
    _getUserName();

    notifyHelper = NotifyHelper();
    notifyHelper.initializeNotification();
    notifyHelper.requestIOSPermissions();
    notifyHelper.requestAndroidPermissions();

    // Schedule daily reminder notification
    _scheduleDailyTaskReminder();
  }

  // Method to get user name from storage or prompt user
  void _getUserName() async {
    if (_storage.hasData('user_name')) {
      setState(() {
        _userName = _storage.read('user_name') ?? "";
      });
    } else {
      // Show dialog to get user name
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNameInputDialog();
      });
    }
  }

  // Method to show dialog for user name input
  void _showNameInputDialog() {
    final TextEditingController nameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text("Welcome to Task Reminder!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please enter your name:"),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: "Your Name",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                _storage.write('user_name', nameController.text.trim());
                setState(() {
                  _userName = nameController.text.trim();
                });
                Get.back();
              } else {
                Get.snackbar(
                  "Empty Name",
                  "Please enter your name",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
      barrierDismissible: false, // User must provide a name
    );
  }

  // Schedule daily reminder for all tasks
  void _scheduleDailyTaskReminder() {
    // Schedule a daily notification at 8:00 AM
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 8, 0);

    // Get difference to next 8:00 AM
    var difference = scheduledTime.difference(now);
    if (difference.isNegative) {
      difference = difference + const Duration(days: 1);
    }

    // Schedule the daily reminder
    Future.delayed(difference, () {
      _sendDailyTaskReminder();
      // Reschedule for next day
      _scheduleDailyTaskReminder();
    });
  }

  // Send daily reminder notification
  void _sendDailyTaskReminder() {
    final tasks = _taskController.taskList;
    if (tasks.isEmpty) {
      notifyHelper.displayNotification(
        title: "Daily Reminder",
        body: "You have no tasks scheduled for today. Plan your day!",
      );
      return;
    }

    final tasksForToday = tasks.where((task) {
      final selectedDateStr = DateFormat('M/d/yyyy').format(DateTime.now());

      return task?.date == selectedDateStr ||
          task?.repeat == "Daily" ||
          (task?.repeat == "Weekly" &&
              DateFormat('EEEE').format(DateTime.now()) ==
                  DateFormat('EEEE')
                      .format(DateFormat('M/d/yyyy').parse(task?.date ?? "")));
    }).toList();

    if (tasksForToday.isEmpty) {
      notifyHelper.displayNotification(
        title: "Daily Task Reminder",
        body: "No tasks scheduled for today. Have a great day!",
      );
    } else {
      final taskTitles = tasksForToday.map((t) => t?.title).join(", ");
      notifyHelper.displayNotification(
        title: "Daily Task Reminder",
        body: "You have ${tasksForToday.length} tasks today: $taskTitles",
      );
    }
  }

  // Sorting function
  List<Task> _shortNotesByModifiedDate(List<Task> taskList) {
    taskList.sort((a, b) => a.updatedAt!.compareTo(b.updatedAt!));

    if (shorted) {
      taskList = List.from(taskList.reversed);
    } else {
      taskList = List.from(taskList.reversed);
    }

    shorted = !shorted;

    return taskList;
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return GetBuilder<ThemeServices>(
      init: ThemeServices(),
      builder: (themeServices) => Scaffold(
        backgroundColor: context.theme.colorScheme.background,
        appBar: _appBar(themeServices),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _greetingBar(),
              _taskProgress(),
              _addTaskBar(),
              _dateBar(),
              const SizedBox(height: 10),
              _showTasks(),
              _buildUrgentTasksSection(),
            ],
          ),
        ),
      ),
    );
  }

  _greetingBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi, ${_userName.isEmpty ? "there" : _userName}",
                style: headingStyle.copyWith(fontSize: width! * .06),
              ),
              Text(
                "Be productive today",
                style: subHeadingStyle.copyWith(fontSize: width! * .049),
              )
            ],
          ),
          IconButton(
            icon: Icon(
              notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              size: 30,
              color: notificationsEnabled ? primaryColor : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                notificationsEnabled = !notificationsEnabled;
                if (notificationsEnabled) {
                  notifyHelper.displayNotification(
                    title: "Notifications Enabled",
                    body: "You will now receive task reminders",
                  );
                } else {
                  notifyHelper.displayNotification(
                    title: "Notifications Disabled",
                    body: "You will not receive task reminders",
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  _taskProgress() {
    return Obx(() {
      final tasks = _taskController.taskList;
      int totalTasks = tasks.length;
      int completedTasks = tasks.where((task) => task?.isCompleted == 1).length;
      double progress =
          totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Task Progress",
                  style: subHeadingStyle.copyWith(color: Colors.white),
                ),
                Text(
                  "$completedTasks/$totalTasks tasks done",
                  style: subTitleStyle.copyWith(color: Colors.white),
                ),
                if (completedTasks > 0)
                  Text(
                    DateFormat.MMMd().format(DateTime.now()),
                    style: subTitleStyle.copyWith(
                        color: Colors.white.withOpacity(0.7)),
                  ),
              ],
            ),
            CircularPercentIndicator(
              radius: 40.0,
              lineWidth: 8.0,
              percent: progress / 100,
              center: Text(
                "${progress.toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              progressColor: Colors.white,
              backgroundColor: Colors.blueAccent.shade700,
              animation: true,
              animationDuration: 1000,
            ),
          ],
        ),
      );
    });
  }

  _urgentTasks() {
    List<Task> urgentTasks = filterTaskList
        .where((task) => task.remind != null && task.remind! <= 5)
        .toList();

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Urgent tasks",
            style: headingStyle,
          ),
          const SizedBox(height: 10),
          ...urgentTasks.map((task) => TaskTile(task)).toList(),
        ],
      ),
    );
  }

  _addTaskBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat("EEE, d MMM yyyy").format(DateTime.now()),
                style: subHeadingStyle.copyWith(fontSize: width! * .049),
              ),
              Text(
                "Today",
                style: headingStyle.copyWith(fontSize: width! * .06),
              )
            ],
          ),
          MyButton(
            label: "+ Add Task",
            onTap: () async {
              await Get.to(() => const AddTaskPage());
              _taskController.getTasks();
            },
          )
        ],
      ),
    );
  }

  AppBar _appBar(ThemeServices themeServices) {
    return AppBar(
      systemOverlayStyle: Get.isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      backgroundColor: context.theme.colorScheme.background,
      elevation: 0,
      leading: GestureDetector(
        onTap: () {
          themeServices.switchTheme();
          notifyHelper.displayNotification(
              title: "Theme Changed",
              body: Get.isDarkMode
                  ? "Light Theme Activated"
                  : "Dark Theme Activated");
        },
        child: themeServices.icon,
      ),
      actions: [
        IconButton(
          padding: const EdgeInsets.all(0),
          onPressed: () {
            _shareProgressReport();
          },
          tooltip: "Share Progress Report",
          icon: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Get.isDarkMode
                  ? Colors.grey.shade800.withOpacity(.8)
                  : Colors.grey[300],
            ),
            child: Icon(
              Icons.share,
              size: 26,
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        IconButton(
          padding: const EdgeInsets.all(0),
          onPressed: () {
            setState(() {
              filterTaskList = _shortNotesByModifiedDate(filterTaskList);
            });
          },
          icon: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Get.isDarkMode
                  ? Colors.grey.shade800.withOpacity(.8)
                  : Colors.grey[300],
            ),
            child: Icon(
              shorted ? Icons.filter_alt : Icons.filter_alt_off_sharp,
              size: 26,
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, 25),
          icon: const Icon(Icons.more_vert),
          padding: const EdgeInsets.symmetric(horizontal: 0),
          tooltip: "More",
          onSelected: (value) async {
            if (value == "Export to CSV") {
              // Export the taskList to CSV
              await exportTasksToCSV(filterTaskList);
            } else if (value == "Export to Excel") {
              // Export the taskList to Excel
              await exportTasksToExcel(filterTaskList);
            } else if (value == "Save as PDF") {
              // Export the taskList to PDF
              await exportTasksToPDF(filterTaskList);
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem(
                value: "Export to CSV",
                child: Text("Export to CSV"),
              ),
              const PopupMenuItem(
                value: "Export to Excel",
                child: Text("Export to Excel"),
              ),
              const PopupMenuItem(
                value: "Save as PDF",
                child: Text("Save as PDF"),
              ),
            ];
          },
        ),
      ],
    );
  }

  _dateBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 10),
      child: DatePicker(
        DateTime.now(),
        height: 125,
        width: 80,
        initialSelectedDate: DateTime.now(),
        selectionColor: primaryColor,
        selectedTextColor: Colors.white,
        onDateChange: (date) {
          // New date selected
          setState(() {
            _selectedDate = date;
          });
        },
        monthTextStyle: GoogleFonts.lato(
          textStyle: TextStyle(
            fontSize: width! * 0.039,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        dateTextStyle: GoogleFonts.lato(
          textStyle: TextStyle(
            fontSize: width! * 0.037,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        dayTextStyle: GoogleFonts.lato(
          textStyle: TextStyle(
            fontSize: width! * 0.030,
            fontWeight: FontWeight.normal,
            color: Get.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  _showTasks() {
    return Obx(() {
      List<Task> tasksForSelectedDate = [];

      // _selectedDate is already a DateTime object, no need to parse it
      DateTime selectedDate = _selectedDate;

      // First, filter tasks specifically for the selected date
      for (var task in _taskController.taskList) {
        // Parse the task date string to DateTime
        DateTime taskDate;
        try {
          taskDate = DateFormat('M/d/yyyy').parse(task?.date ?? "");
        } catch (e) {
          try {
            taskDate = DateFormat('MM/dd/yyyy').parse(task?.date ?? "");
          } catch (e) {
            print("Error parsing date: ${task?.date}, error: ${e}");
            continue; // Skip this task if date can't be parsed
          }
        }

        bool shouldInclude = false;

        // Exact date match - compare year, month, and day
        if (taskDate.year == selectedDate.year &&
            taskDate.month == selectedDate.month &&
            taskDate.day == selectedDate.day) {
          shouldInclude = true;
        }
        // Check for repeating tasks
        else if (task?.repeat != "None") {
          if (task?.repeat == "Daily") {
            shouldInclude = true;
          } else if (task?.repeat == "Weekly" &&
              selectedDate.weekday == taskDate.weekday) {
            shouldInclude = true;
          } else if (task?.repeat == "Monthly" &&
              selectedDate.day == taskDate.day) {
            shouldInclude = true;
          }
        }

        // Add task if it matches criteria
        if (shouldInclude && !tasksForSelectedDate.contains(task)) {
          tasksForSelectedDate.add(task);
        }
      }

      // Sort tasks by time
      tasksForSelectedDate.sort((a, b) {
        DateTime aTime = DateFormat('HH:mm').parse(a?.startTime ?? "");
        DateTime bTime = DateFormat('HH:mm').parse(b?.startTime ?? "");
        return aTime.compareTo(bTime);
      });

      // If no tasks, show empty state
      if (tasksForSelectedDate.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy,
                size: 100,
                color: primaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                "No tasks for ${DateFormat('EEEE, MMM d').format(selectedDate)}",
                style: subTitleStyle.copyWith(fontSize: 20),
              ),
            ],
          ),
        );
      }

      // Return task list
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tasksForSelectedDate.length,
        itemBuilder: (_, index) {
          Task task = tasksForSelectedDate[index];

          DateTime date = _parseDateTime(task.startTime ?? "");
          var myTime = DateFormat.Hm().format(date);

          var remind = DateFormat.Hm()
              .format(date.subtract(Duration(minutes: task?.remind ?? 0)));

          int mainTaskNotificationId = task.id!.toInt();

          if (task?.remind != null && task.remind! > 0) {
            notifyHelper.remindNotification(
              int.parse(remind.toString().split(":")[0]),
              int.parse(remind.toString().split(":")[1]),
              task,
            );
          }

          notifyHelper.scheduledNotification(
            int.parse(myTime.toString().split(":")[0]),
            int.parse(myTime.toString().split(":")[1]),
            task,
          );

          return AnimationConfiguration.staggeredList(
            position: index,
            child: SlideAnimation(
              child: FadeInAnimation(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showBottomSheet(context, task);
                      },
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        Get.to(
                          () => AddTaskPage(task: task),
                        );
                      },
                      child: TaskTile(
                        task,
                        onProgressIncrease: (task) {
                          _handleProgressIncrease(task);
                        },
                        onProgressDecrease: (task) {
                          _handleProgressDecrease(task);
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  DateTime _parseDateTime(String timeString) {
    // Split the timeString into components (hour, minute, period)
    List<String> components = timeString.split(' ');

    // Extract and parse the hour and minute
    List<String> timeComponents = components[0].split(':');
    int hour = int.parse(timeComponents[0]);
    int minute = int.parse(timeComponents[1]);

    // If the time string contains a period (AM or PM),
    //adjust the hour for 12-hour format
    if (components.length > 1) {
      String period = components[1];
      if (period.toLowerCase() == 'pm' && hour < 12) {
        hour += 12;
      } else if (period.toLowerCase() == 'am' && hour == 12) {
        hour = 0;
      }
    }

    return DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, hour, minute);
  }

  void _showBottomSheet(BuildContext context, Task task) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        // Increase height even more to avoid overflow
        height: task?.isCompleted == 1
            ? MediaQuery.of(context).size.height * 0.40
            : MediaQuery.of(context).size.height * 0.45,
        color: Get.isDarkMode ? darkGreyColor : Colors.white,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 6,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                ),
              ),
              const SizedBox(height: 20),
              _bottomSheetButton(
                label: " Update Task",
                color: Colors.green[400]!,
                onTap: () {
                  Get.back();
                  Get.to(() => AddTaskPage(task: task));
                },
                context: context,
                icon: Icons.update,
              ),
              task?.isCompleted == 1
                  ? Container()
                  : _bottomSheetButton(
                      label: "Task Completed",
                      color: primaryColor,
                      onTap: () {
                        Get.back();
                        _taskController.markTaskAsCompleted(task.id!, true);
                        _taskController.getTasks();
                      },
                      context: context,
                      icon: Icons.check,
                    ),
              _bottomSheetButton(
                label: "Delete Task",
                color: Colors.red[400]!,
                onTap: () {
                  Get.back();
                  showDialog(
                      context: context,
                      builder: (_) => _alertDialogBox(context, task));
                },
                context: context,
                icon: Icons.delete,
              ),
              const SizedBox(height: 15),
              _bottomSheetButton(
                label: "Close",
                color: Colors.grey.shade400,
                isClose: true,
                onTap: () {
                  Get.back();
                },
                context: context,
                icon: Icons.close,
              ),
            ],
          ),
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  _alertDialogBox(BuildContext context, Task task) {
    return AlertDialog(
      backgroundColor: context.theme.colorScheme.background,
      icon: const Icon(Icons.warning, color: Colors.red),
      title: const Text("Are you sure you want to delete?"),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () {
              Get.back();
              _taskController.deleteTask(task.id!);
              // Cancel delete notification
              if (task?.remind != null && task.remind! > 4) {
                notifyHelper.cancelNotification(task.id! + 1);
              }
              _showTasks();
            },
            child: const SizedBox(
              width: 60,
              child: Text(
                "Yes",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Get.back();
            },
            child: const SizedBox(
              width: 60,
              child: Text(
                "No",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _bottomSheetButton(
      {required String label,
      required BuildContext context,
      required Color color,
      required Function()? onTap,
      IconData? icon,
      bool isClose = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 7),
        height: 55,
        width: MediaQuery.of(context).size.width * 0.9,

        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: isClose
                ? Get.isDarkMode
                    ? Colors.grey[700]!
                    : Colors.grey[300]!
                : color,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isClose ? Colors.transparent : color,
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon != null
                ? Icon(
                    icon,
                    color: isClose
                        ? Get.isDarkMode
                            ? Colors.white
                            : Colors.black
                        : Colors.white,
                    size: 30,
                  )
                : const SizedBox(),
            Text(
              label,
              style: titleStyle.copyWith(
                fontSize: 18,
                color: isClose
                    ? Get.isDarkMode
                        ? Colors.white
                        : Colors.black
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Task> getTasksCompletedToday(List<Task> taskList) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    return taskList.where((task) {
      if (task.completedAt == null) {
        return false;
      }

      DateTime completedDate = DateTime.parse(task.completedAt!);
      completedDate = DateTime(
        completedDate.year,
        completedDate.month,
        completedDate.day,
      );

      return completedDate == today;
    }).toList();
  }

  _buildUrgentTasksSection() {
    return Obx(() {
      // Get all urgent tasks regardless of date
      List<Task> urgentTasks = _taskController.taskList
          .where((task) => task?.isUrgent ?? false)
          .toList();

      if (urgentTasks.isEmpty) {
        return Container(); // No urgent tasks, return empty container
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.priority_high, color: Colors.red),
                  const SizedBox(width: 10),
                  Text(
                    "Urgent Tasks",
                    style: headingStyle.copyWith(
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: urgentTasks.length,
              itemBuilder: (_, index) {
                Task task = urgentTasks[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  child: SlideAnimation(
                    child: FadeInAnimation(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _showBottomSheet(context, task);
                            },
                            onLongPress: () {
                              HapticFeedback.mediumImpact();
                              Get.to(() => AddTaskPage(task: task));
                            },
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width -
                                  40, // Constrain width
                              child: Stack(
                                children: [
                                  TaskTile(
                                    task,
                                    onProgressIncrease: (task) {
                                      _handleProgressIncrease(task);
                                    },
                                    onProgressDecrease: (task) {
                                      _handleProgressDecrease(task);
                                    },
                                  ),
                                  Positioned(
                                    right: 40,
                                    top: 30,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.priority_high,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "URGENT",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  void _shareProgressReport() {
    if (filterTaskList.isEmpty) {
      Get.snackbar(
        "No Tasks",
        "There are no tasks to share.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    int totalTasks = filterTaskList.length;
    int completedTasks =
        filterTaskList.where((task) => task?.isCompleted == 1).length;
    double overallProgress =
        totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

    // Create the progress report
    String report = "TASK PROGRESS REPORT\n";
    report +=
        "Date: ${DateFormat('EEEE, MMM d, yyyy').format(DateTime.now())}\n";
    report +=
        "Overall Progress: ${overallProgress.toInt()}% (${completedTasks}/${totalTasks} tasks completed)\n\n";
    report += "TASKS:\n";

    for (int i = 0; i < filterTaskList.length; i++) {
      Task task = filterTaskList[i];
      report += "${i + 1}. ${task.title} - ${task.progress}% complete";

      if (task?.isCompleted == 1) {
        report += " (COMPLETED)";
      } else if (task?.isUrgent ?? false) {
        report += " (URGENT)";
      }

      report += "\n";
      report +=
          "   Due: ${task.date ?? 'No date'} at ${task.startTime ?? 'No time'}\n";

      if (task?.subtasks.isNotEmpty ?? false) {
        report += "   Subtasks:\n";
        for (int j = 0; j < (task?.subtasks.length ?? 0); j++) {
          SubTask subtask = task!.subtasks[j];
          report += "   - ${subtask.title}";
          if (subtask.isCompleted) {
            report += " (done)";
          }
          report += "\n";
        }
      }

      report += "\n";
    }

    // Show dialog with share options
    Get.dialog(
      AlertDialog(
        title: const Text("Progress Report"),
        content: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: SingleChildScrollView(
            child: Text(report),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report));
              Get.back();
              Get.snackbar(
                "Copied to Clipboard",
                "Progress report has been copied to clipboard",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text("Copy to Clipboard"),
          ),
        ],
      ),
    );
  }

  // Show full screen alarm for a task
  void _showFullScreenAlarm(Task task) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: _getBGClr(task.color ?? 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.alarm,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                "TIME'S UP!",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                task.note,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Play alarm sound
                  HapticFeedback.heavyImpact();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  "DISMISS",
                  style: TextStyle(
                    color: _getBGClr(task.color ?? 0),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Color _getBGClr(int no) {
    switch (no) {
      case 0:
        return bluishColor;
      case 1:
        return pinkColor;
      case 2:
        return yellowishColor;
      default:
        return greenColor;
    }
  }

  void _handleProgressIncrease(Task task) {
    int newProgress = task.progress + 10 > 100 ? 100 : task.progress + 10;
    int newIsCompleted = newProgress >= 100 ? 1 : 0;
    String? newCompletedAt = newProgress >= 100
        ? DateTime.now().toIso8601String()
        : task.completedAt;

    // Create a copy of the task with updated progress
    Task updatedTask = Task(
      id: task.id,
      title: task.title,
      note: task.note,
      date: task.date,
      startTime: task.startTime,
      endTime: task.endTime,
      remind: task.remind,
      repeat: task.repeat,
      color: task.color,
      isCompleted: newIsCompleted,
      createdAt: task.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      completedAt: newCompletedAt,
      isUrgent: task.isUrgent,
      subtasks: task.subtasks,
      progress: newProgress,
    );

    _taskController.updateTaskInfo(updatedTask);
  }

  void _handleProgressDecrease(Task task) {
    int newProgress = task.progress - 10 < 0 ? 0 : task.progress - 10;

    // Create a copy of the task with updated progress
    Task updatedTask = Task(
      id: task.id,
      title: task.title,
      note: task.note,
      date: task.date,
      startTime: task.startTime,
      endTime: task.endTime,
      remind: task.remind,
      repeat: task.repeat,
      color: task.color,
      isCompleted: task.isCompleted,
      createdAt: task.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      completedAt: task.completedAt,
      isUrgent: task.isUrgent,
      subtasks: task.subtasks,
      progress: newProgress,
    );

    _taskController.updateTaskInfo(updatedTask);
  }
}
