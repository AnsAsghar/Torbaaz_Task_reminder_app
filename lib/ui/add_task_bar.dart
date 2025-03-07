import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:torbaaz_reminder_app/controllers/device_info.dart';
import 'package:torbaaz_reminder_app/controllers/task.controller.dart';
import 'package:torbaaz_reminder_app/models/task.dart';
import 'package:torbaaz_reminder_app/theme/theme.dart';
import 'package:torbaaz_reminder_app/ui/widgets/button.dart';
import 'package:torbaaz_reminder_app/ui/widgets/input_field.dart';

class AddTaskPage extends StatefulWidget {
  final Task? task;

  const AddTaskPage({Key? key, this.task}) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  String? deviceName;

  final TaskController _taskController = Get.put(TaskController());
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _subtaskController = TextEditingController();

  List<SubTask> _subtasks = [];

  DateTime _selectedDate = DateTime.now();
  String _startTime = DateFormat("hh:mm a")
      .format(DateTime.now().add(const Duration(minutes: 2)))
      .toString();
  String _endTime = DateFormat("hh:mm a")
      .format(DateTime.now().add(const Duration(minutes: 10)))
      .toString();

  int _selectedRemind = 0;
  List<int> remindList = [0, 5, 10, 15, 20, 25, 30];

  String _selectedRepeat = "None";
  List<String> repeatList = ["None", "Daily", "Weekly", "Monthly"];

  int _selectedColor = 0;

  bool _isUrgent = false;

  @override
  void initState() {
    super.initState();

    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _noteController.text = widget.task!.note;
      _selectedDate = DateFormat.yMd().parse(widget.task!.date!);
      _startTime = widget.task!.startTime!;
      _endTime = widget.task!.endTime!;
      _selectedRemind = widget.task!.remind!;
      _selectedRepeat = widget.task!.repeat!;
      _selectedColor = widget.task!.color!;
      _isUrgent = widget.task!.isUrgent;
      _subtasks = List.from(widget.task!.subtasks);
    }

    DeviceInfo deviceInfo = DeviceInfo();
    deviceInfo.getDeviceName().then((value) {
      setState(() {
        deviceName = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.colorScheme.background,
      appBar: _appBar(context),
      body: Container(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titleBar(),
              _inputField(),
              _urgentCheckbox(),
              const SizedBox(height: 15),
              _buildSubtasksSection(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      systemOverlayStyle: Get.isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      backgroundColor: context.theme.colorScheme.background,
      elevation: 0,
      leading: GestureDetector(
        onTap: () {
          Get.back();
        },
        child: Icon(
          Icons.arrow_back_ios,
          size: 20,
          color: Get.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      actions: [
        // const CircleAvatar(
        //   backgroundImage: AssetImage("images/avatar.png"),
        // ),
        InputChip(
          padding: const EdgeInsets.all(0),
          label: Text(
            deviceName ?? "Unknown",
            style: subTitleStyle,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.more_vert,
            size: 20,
            color: Get.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  _titleBar() {
    return Text(widget.task == null ? "Add Task" : "Update Task",
        style: headingStyle);
  }

  _getDateFromUser() async {
    DateTime? pickerDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 4)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 8)),
    );

    if (pickerDate != null) {
      setState(() {
        _selectedDate = pickerDate;
      });
    } else {
      Get.snackbar(
        "Error Occured!",
        "Date is not selected",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  _getTimeFromUser({required bool isStartTime}) async {
    var pickTime = await _showTimePicker();

    if (pickTime != null) {
      // ignore: use_build_context_synchronously
      String formatedTime = pickTime.format(context);

      setState(() {
        if (isStartTime) {
          _startTime = formatedTime;
        } else {
          _endTime = formatedTime;
        }
      });
    } else {
      Get.snackbar(
        "Error Occured!",
        "Time is not selected",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  _showTimePicker() {
    return showTimePicker(
      initialEntryMode: TimePickerEntryMode.dial,
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_startTime.split(":")[0]),
        minute: int.parse(_startTime.split(":")[1].split(" ")[0]),
      ),
    );
  }

  _inputField() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          MyInputField(
            title: "Title",
            hint: "Enter your title",
            controller: _titleController,
          ),
          MyInputField(
            title: "Note",
            hint: "Enter your note",
            controller: _noteController,
          ),
          MyInputField(
            title: "Date",
            hint: DateFormat.yMd().format(_selectedDate),
            widget: IconButton(
              onPressed: () => {
                _getDateFromUser(),
              },
              icon: const Icon(
                Icons.calendar_month_outlined,
                color: Colors.grey,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: MyInputField(
                  title: "Start Time",
                  hint: _startTime,
                  widget: IconButton(
                    onPressed: () => {
                      _getTimeFromUser(isStartTime: true),
                    },
                    icon: const Icon(
                      Icons.access_time_rounded,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: MyInputField(
                  title: "End Time",
                  hint: _endTime,
                  widget: IconButton(
                    onPressed: () => {
                      _getTimeFromUser(isStartTime: false),
                    },
                    icon: const Icon(
                      Icons.access_time_rounded,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
          MyInputField(
            title: "Remind",
            hint: "$_selectedRemind minutes early",
            widget: DropdownButton(
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
              ),
              iconSize: 32,
              elevation: 4,
              padding: const EdgeInsets.only(right: 5),
              style: subTitleStyle,
              underline: Container(
                height: 0,
                color: Colors.transparent,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRemind = int.parse(newValue!);
                });
              },
              items: remindList.map<DropdownMenuItem<String>>((int value) {
                return DropdownMenuItem<String>(
                  value: value.toString(),
                  child: Text(
                    "$value minutes early",
                    style: subTitleStyle,
                  ),
                );
              }).toList(),
            ),
          ),
          MyInputField(
            title: "Repeat",
            hint: _selectedRepeat,
            widget: DropdownButton(
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
              ),
              iconSize: 32,
              elevation: 4,
              padding: const EdgeInsets.only(right: 5),
              style: subTitleStyle,
              underline: Container(
                height: 0,
                color: Colors.transparent,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRepeat = newValue!;
                });
              },
              items: repeatList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: subTitleStyle,
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _colorPallet(),
              MyButton(
                label: widget.task == null ? "Create Task" : "Update Task",
                onTap: () => _validateData(),
              ),
            ],
          )
        ],
      ),
    );
  }

  _validateData() {
    if (_titleController.text.isNotEmpty && _noteController.text.isNotEmpty) {
      // Add to database
      _addTaskToDb();
      Get.back();
    } else if (_titleController.text.isEmpty || _noteController.text.isEmpty) {
      Get.snackbar(
        "Required",
        "All field is required!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.isDarkMode ? Colors.white : Colors.grey,
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
          size: 35,
        ),
        colorText: Colors.red,
      );
    }
  }

  _colorPallet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Color",
          style: titleStyle,
        ),
        Wrap(
          children: List<Widget>.generate(4, (int index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = index;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 8),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: index == 0
                      ? primaryColor
                      : index == 1
                          ? pinkColor
                          : index == 2
                              ? yellowishColor
                              : greenColor,
                  child: Icon(
                    _selectedColor == index ? Icons.done : null,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  _urgentCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _isUrgent,
          onChanged: (value) {
            setState(() {
              _isUrgent = value!;
            });
          },
        ),
        const Text('Mark as Urgent'),
      ],
    );
  }

  Widget _buildSubtasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Subtasks",
          style: titleStyle,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _subtaskController,
                decoration: InputDecoration(
                  hintText: "Add a subtask",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                if (_subtaskController.text.isNotEmpty) {
                  setState(() {
                    _subtasks.add(SubTask(title: _subtaskController.text));
                    _subtaskController.clear();
                  });
                }
              },
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (_subtasks.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subtasks.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Checkbox(
                      value: _subtasks[index].isCompleted,
                      onChanged: (value) {
                        setState(() {
                          _subtasks[index].isCompleted = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(_subtasks[index].title),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _subtasks.removeAt(index);
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          )
        else
          const Text("No subtasks added yet"),
      ],
    );
  }

  void _addTaskToDb() async {
    Task task = Task(
      id: widget.task?.id,
      title: _titleController.text,
      note: _noteController.text,
      date: DateFormat('M/d/yyyy').format(_selectedDate),
      startTime: _startTime,
      endTime: _endTime,
      remind: _selectedRemind,
      repeat: _selectedRepeat,
      color: _selectedColor,
      isCompleted: widget.task?.isCompleted ?? 0,
      createdAt: widget.task?.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      completedAt: widget.task?.completedAt,
      isUrgent: _isUrgent,
      subtasks: _subtasks,
      progress: widget.task?.progress ?? 0,
    );

    print("Adding/updating task: ${task.title}");
    print(
        "Date: ${task.date}, Start time: ${task.startTime}, End time: ${task.endTime}");
    print("Remind: ${task.remind}, Repeat: ${task.repeat}");

    if (widget.task == null) {
      // Add a new task to the database
      int id = await _taskController.addTask(task: task);
      print("Task added with ID: $id");

      // Show success message
      Get.snackbar(
        "Success",
        "Task added successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      // Update the existing task in the database
      await _taskController.updateTaskInfo(task);
      print("Task updated with ID: ${task.id}");

      // Show success message
      Get.snackbar(
        "Success",
        "Task updated successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }

    // Refresh the task list
    _taskController.getTasks();

    // Navigate back to the task list
    Get.back();
  }
}
