import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:torbaaz_reminder_app/models/task.dart';
import 'package:torbaaz_reminder_app/theme/theme.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final Function(Task)? onProgressIncrease;
  final Function(Task)? onProgressDecrease;

  const TaskTile(
    this.task, {
    super.key,
    this.onProgressIncrease,
    this.onProgressDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _getBGClr(task.color ?? 0),
          border: task.isUrgent == true
              ? Border.all(color: Colors.red, width: 2)
              : null,
        ),
        child: Column(
          children: [
            // First row with task details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: GoogleFonts.lato(
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          if (task.isUrgent == true)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: Colors.grey[200],
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${task.startTime}  -  ${task.endTime}",
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(
                                  fontSize: 13, color: Colors.grey[100]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Chip(
                            label: Text(
                              "${task.repeat}",
                              style: GoogleFonts.lato(
                                textStyle: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[100],
                                ),
                              ),
                            ),
                            backgroundColor: _getBGClr(task.color ?? 0),
                            clipBehavior: Clip.antiAlias,
                            shadowColor: Colors.grey,
                            padding: const EdgeInsets.only(
                              top: 0,
                              bottom: 0,
                              left: 4,
                              right: 4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        task.note,
                        style: GoogleFonts.lato(
                          textStyle:
                              TextStyle(fontSize: 15, color: Colors.grey[100]),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  height: task.isCompleted == 1 ? 105 : 90,
                  width: 0.9,
                  color: Colors.white.withOpacity(0.8),
                ),
                RotatedBox(
                  quarterTurns: 3,
                  child: Row(
                    children: [
                      task.isCompleted == 1
                          ? const Icon(Icons.done_rounded)
                          : Container(),
                      Text(
                        task.isCompleted == 1 ? "COMPLETED" : "TODO",
                        style: GoogleFonts.lato(
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Add progress indicator
            if (task.isCompleted == 0) // Only show for incomplete tasks
              Column(
                children: [
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Text(
                        "Progress: ${task.progress}%",
                        style: GoogleFonts.lato(
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Decrease progress button
                      InkWell(
                        onTap: () {
                          if (task.progress > 0 && onProgressDecrease != null) {
                            onProgressDecrease!(task);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Increase progress button
                      InkWell(
                        onTap: () {
                          if (onProgressIncrease != null) {
                            onProgressIncrease!(task);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearPercentIndicator(
                    lineHeight: 10.0,
                    percent: task.progress / 100,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    progressColor: Colors.white,
                    barRadius: const Radius.circular(10),
                    animation: true,
                    animationDuration: 1000,
                  ),
                ],
              ),

            // Show subtasks if available
            if (task.subtasks.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  Text(
                    "Subtasks:",
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  ...task.subtasks
                      .map((subtask) => Row(
                            children: [
                              Icon(
                                subtask.isCompleted
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                subtask.title,
                                style: GoogleFonts.lato(
                                  textStyle: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    decoration: subtask.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  _getBGClr(int no) {
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
}
