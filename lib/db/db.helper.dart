import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:torbaaz_reminder_app/models/task.dart';
import 'package:get_storage/get_storage.dart';

class DBHelper {
  static Database? _database;
  static const int _version = 1;
  static const String _tableName = 'tasks';
  static const String _dbName = 'todo.db';
  static final GetStorage _webStorage = GetStorage('tasks_storage');
  static int _idCounter = 0;

  static Future<void> initDb() async {
    if (kIsWeb) {
      print("Running on web platform, using GetStorage instead of SQLite");
      // Initialize web storage
      await GetStorage.init('tasks_storage');
      // Initialize the ID counter based on existing tasks
      List<Map<String, dynamic>> tasks = await query();
      if (tasks.isNotEmpty) {
        _idCounter = tasks
                .map((task) => task['id'] as int)
                .reduce((a, b) => a > b ? a : b) +
            1;
      }
      return;
    }

    if (_database != null) {
      return;
    }

    try {
      if (Platform.isWindows || Platform.isLinux) {
        // Initialize FFI for desktop platforms
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      String path = await getDatabasesPath() + '/' + _dbName;
      print("Database path: $path");

      _database = await openDatabase(
        path,
        version: _version,
        onCreate: (db, version) {
          print('Creating table name ->  $_tableName');
          return db.execute(
            'CREATE TABLE $_tableName (id INTEGER PRIMARY KEY AUTOINCREMENT, title STRING, note TEXT, date STRING, startTime STRING, endTime STRING, remind INTEGER, repeat STRING, color INTEGER, isCompleted INTEGER, completedAt STRING, createdAt STRING, updatedAt STRING)',
          );
        },
      );
      print("Database initialized successfully");
    } catch (e) {
      print("Error initializing database: $e");
    }
  }

  static Future<int> insert(Task task) async {
    print('Inserting data to $_tableName');
    try {
      // Set default values for task fields if they are null
      task.isCompleted ??= 0;
      task.color ??= 0;
      task.remind ??= 5;
      task.repeat ??= "None";
      task.createdAt ??= DateTime.now().toIso8601String();
      task.updatedAt ??= DateTime.now().toIso8601String();

      if (kIsWeb) {
        // For web, use GetStorage
        task.id = _idCounter++;
        List<Map<String, dynamic>> tasks = await query();
        tasks.add(task.toJson());
        await _webStorage.write('tasks', tasks);
        print("Task inserted in web storage with ID: ${task.id}");
        return task.id!;
      } else {
        // For mobile/desktop, use SQLite
        if (_database == null) {
          await initDb();
        }
        print(task.toJson());
        return await _database!.insert(_tableName, task.toJson());
      }
    } catch (e) {
      print("Error inserting task: $e");
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> query() async {
    print('Querying data from $_tableName');
    try {
      if (kIsWeb) {
        // For web, use GetStorage
        final List<dynamic>? storedTasks = _webStorage.read('tasks');
        if (storedTasks == null) {
          print("No tasks found in web storage");
          return [];
        }
        print("Retrieved ${storedTasks.length} tasks from web storage");
        return List<Map<String, dynamic>>.from(storedTasks);
      } else {
        // For mobile/desktop, use SQLite
        if (_database == null) {
          await initDb();
        }
        return await _database!.query(_tableName);
      }
    } catch (e) {
      print("Error querying tasks: $e");
      return [];
    }
  }

  static Future<int> delete(int id) async {
    print('Deleting data from $_tableName with id ===> $id');
    try {
      if (kIsWeb) {
        // For web, use GetStorage
        List<Map<String, dynamic>> tasks = await query();
        tasks.removeWhere((task) => task['id'] == id);
        await _webStorage.write('tasks', tasks);
        print("Task deleted from web storage");
        return 1;
      } else {
        // For mobile/desktop, use SQLite
        if (_database == null) {
          await initDb();
        }
        return await _database!.delete(
          _tableName,
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      print("Error deleting task: $e");
      return 0;
    }
  }

  static Future<int> updateTask(int id, bool isCompleted) async {
    print('Updating data from $_tableName with id ===> $id');

    int isComplete = isCompleted ? 1 : 0;
    try {
      if (kIsWeb) {
        // For web, use GetStorage
        List<Map<String, dynamic>> tasks = await query();
        for (int i = 0; i < tasks.length; i++) {
          if (tasks[i]['id'] == id) {
            tasks[i]['isCompleted'] = isComplete;
            tasks[i]['completedAt'] =
                isCompleted ? DateTime.now().toIso8601String() : null;
            tasks[i]['updatedAt'] = DateTime.now().toIso8601String();
            break;
          }
        }
        await _webStorage.write('tasks', tasks);
        print("Task updated in web storage");
        return 1;
      } else {
        // For mobile/desktop, use SQLite
        if (_database == null) {
          await initDb();
        }
        return await _database!.rawUpdate('''
        UPDATE $_tableName 
        SET isCompleted = ?, completedAt = ?, updatedAt = ?
        WHERE id = ?
      ''', [
          isComplete,
          isCompleted ? DateTime.now().toIso8601String() : null,
          DateTime.now().toIso8601String(),
          id
        ]);
      }
    } catch (e) {
      print("Error updating task completion status: $e");
      return 0;
    }
  }

  static Future<int> updateTaskInfo(Task task) async {
    print('Updating data from $_tableName with id ===> ${task.id}');
    try {
      // Update the updatedAt timestamp
      task.updatedAt = DateTime.now().toIso8601String();

      if (kIsWeb) {
        // For web, use GetStorage
        List<Map<String, dynamic>> tasks = await query();
        for (int i = 0; i < tasks.length; i++) {
          if (tasks[i]['id'] == task.id) {
            tasks[i] = task.toJson();
            break;
          }
        }
        await _webStorage.write('tasks', tasks);
        print("Task info updated in web storage");
        return 1;
      } else {
        // For mobile/desktop, use SQLite
        if (_database == null) {
          await initDb();
        }

        return await _database!.rawUpdate(
          '''
        UPDATE $_tableName
        SET title = ?, note = ?, date = ?, startTime = ?, endTime = ?, remind = ?, repeat = ?, color = ?, isCompleted = ?, createdAt = ?, updatedAt = ?, completedAt = ?
        WHERE id = ?
        ''',
          [
            task.title,
            task.note,
            task.date,
            task.startTime,
            task.endTime,
            task.remind,
            task.repeat,
            task.color,
            task.isCompleted,
            task.createdAt,
            task.updatedAt,
            task.completedAt,
            task.id
          ],
        );
      }
    } catch (e) {
      print("Error updating task info: $e");
      return 0;
    }
  }
}
