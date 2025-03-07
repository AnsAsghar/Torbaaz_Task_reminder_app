import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:todo_apps/controllers/task.controller.dart';
import 'package:todo_apps/models/task.dart';
import 'package:todo_apps/theme/theme.dart';

class FullScreenAlarm extends StatefulWidget {
  final Task task;

  const FullScreenAlarm({Key? key, required this.task}) : super(key: key);

  @override
  State<FullScreenAlarm> createState() => _FullScreenAlarmState();
}

class _FullScreenAlarmState extends State<FullScreenAlarm>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Setup vibration and animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    // Vibrate the device to alert the user
    HapticFeedback.heavyImpact();
    _startVibration();
  }

  void _startVibration() async {
    // Vibrate multiple times
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(seconds: 1));
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: _getBGClr(widget.task.color ?? 0),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_animationController.value * 0.2),
                    child: Icon(
                      Icons.alarm,
                      size: 80,
                      color: Colors.white.withOpacity(
                          0.8 + (_animationController.value * 0.2)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              Text(
                "TIME'S UP!",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.task.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      widget.task.note,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Mark task as complete
                      final taskController = Get.find<TaskController>();
                      if (widget.task.id != null) {
                        taskController.markTaskAsCompleted(
                            widget.task.id!, true);
                      }
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    child: const Text(
                      "COMPLETE TASK",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    child: Text(
                      "DISMISS",
                      style: TextStyle(
                        color: _getBGClr(widget.task.color ?? 0),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
