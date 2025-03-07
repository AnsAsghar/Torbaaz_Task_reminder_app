class SubTask {
  String title;
  bool isCompleted;

  SubTask({
    required this.title,
    this.isCompleted = false,
  });

  SubTask.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        isCompleted = json['isCompleted'] ?? false;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['isCompleted'] = isCompleted;
    return data;
  }
}

class Task {
  int? id;
  late String title;
  late String note;
  int? isCompleted;
  String? date;
  String? startTime;
  String? endTime;
  int? color;
  int? remind;
  String? repeat;
  String? completedAt;
  String? createdAt;
  String? updatedAt;
  bool isUrgent;
  List<SubTask> subtasks;
  int progress;

  Task({
    this.id,
    required this.title,
    required this.note,
    this.isCompleted,
    this.date,
    this.startTime,
    this.endTime,
    this.color,
    this.remind,
    this.repeat,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.isUrgent = false,
    this.subtasks = const [],
    this.progress = 0,
  });

  Task.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        note = json['note'],
        isCompleted = json['isCompleted'],
        date = json['date'],
        startTime = json['startTime'],
        endTime = json['endTime'],
        color = json['color'],
        remind = json['remind'],
        repeat = json['repeat'],
        completedAt = json['completedAt'],
        createdAt = json['createdAt'],
        updatedAt = json['updatedAt'],
        isUrgent = json['isUrgent'] ?? false,
        subtasks = json['subtasks'] != null
            ? List<SubTask>.from(
                (json['subtasks'] as List).map((x) => SubTask.fromJson(x)))
            : [],
        progress = json['progress'] ?? 0;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['note'] = note;
    data['isCompleted'] = isCompleted;
    data['date'] = date;
    data['startTime'] = startTime;
    data['endTime'] = endTime;
    data['color'] = color;
    data['remind'] = remind;
    data['repeat'] = repeat;
    data['completedAt'] = completedAt;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['isUrgent'] = isUrgent;
    data['subtasks'] = subtasks.map((x) => x.toJson()).toList();
    data['progress'] = progress;
    return data;
  }
}
