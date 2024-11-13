import 'dart:convert';
import './task.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SettingsService {
  Future<File> _getSettingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/settings.json');
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    final file = await _getSettingsFile();
    if (await file.exists()) {
      final contents = await file.readAsString();
      return json.decode(contents);
    } else {
      return {"isFirstLaunch": true};
    }
  }

  Future<void> addTaskAutomatically(String title, int durationHours, DateTime deadline) async {
    List<Task> tasksToAdd = [];

    if (durationHours > 3) {
      int fullParts = durationHours ~/ 2;
      int lastPartDuration = durationHours % 2 == 0 ? 2 : 3;

      for (int i = 0; i < fullParts; i++) {
        tasksToAdd.add(Task(title: title, startTime: TimeOfDay(hour: 0, minute: 0), duration: Duration(hours: 2)));
      }
      tasksToAdd.add(Task(title: title, startTime: TimeOfDay(hour: 0, minute: 0), duration: Duration(hours: lastPartDuration)));
    } else {
      tasksToAdd.add(Task(title: title, startTime: TimeOfDay(hour: 0, minute: 0), duration: Duration(hours: durationHours)));
    }

    DateTime currentDate = DateTime.now();
    while (currentDate.isBefore(deadline) || currentDate.isAtSameMomentAs(deadline)) {
      List<Task> dailyTasks = await loadTasksForDay(currentDate.toIso8601String().substring(0, 10));
      dailyTasks.sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));

      for (var task in tasksToAdd) {
        bool added = false;
        for (int i = 0; i < dailyTasks.length - 1; i++) {
          final endOfCurrentTask = dailyTasks[i].startTime.hour * 60 + dailyTasks[i].startTime.minute + dailyTasks[i].duration.inMinutes;
          final startOfNextTask = dailyTasks[i + 1].startTime.hour * 60 + dailyTasks[i + 1].startTime.minute;

          if ((startOfNextTask - endOfCurrentTask) >= task.duration.inMinutes) {
            task.startTime = TimeOfDay(hour: endOfCurrentTask ~/ 60, minute: endOfCurrentTask % 60);
            dailyTasks.insert(i + 1, task);
            added = true;
            break;
          }
        }

        if (!added) continue;
        await saveTasksForDay(currentDate.toIso8601String().substring(0, 10), dailyTasks);
      }

      currentDate = currentDate.add(Duration(days: 1));
    }
  }

  Future<void> _saveSettings(Map<String, dynamic> settings) async {
    final file = await _getSettingsFile();
    await file.writeAsString(json.encode(settings));
  }

  Future<bool> isFirstLaunch() async {
    final settings = await _loadSettings();
    return settings["isFirstLaunch"] ?? true;
  }

  Future<void> setFirstLaunchCompleted() async {
    final settings = await _loadSettings();
    settings["isFirstLaunch"] = false;
    await _saveSettings(settings);
  }

  Future<void> saveWakeUpAndSleepTime(TimeOfDay wakeUp, TimeOfDay sleep) async {
    final settings = await _loadSettings();
    settings["wakeUpTime"] = {"hour": wakeUp.hour, "minute": wakeUp.minute};
    settings["sleepTime"] = {"hour": sleep.hour, "minute": sleep.minute};
    await _saveSettings(settings);
  }

  Future<Map<String, TimeOfDay>> loadWakeUpAndSleepTime() async {
    final settings = await _loadSettings();
    final wakeUpData = settings["wakeUpTime"];
    final sleepData = settings["sleepTime"];

    return {
      "wakeUpTime": wakeUpData != null
          ? TimeOfDay(hour: wakeUpData["hour"], minute: wakeUpData["minute"])
          : TimeOfDay(hour: 7, minute: 0), // Значение по умолчанию
      "sleepTime": sleepData != null
          ? TimeOfDay(hour: sleepData["hour"], minute: sleepData["minute"])
          : TimeOfDay(hour: 22, minute: 0), // Значение по умолчанию
    };
  }

  Future<List<Task>> loadTasksForDay(String date) async {
    final settings = await _loadSettings();
    if (settings.containsKey(date)) {
      return (settings[date] as List).map((task) => Task.fromJson(task)).toList();
    } else {
      return [];
    }
  }

  Future<void> deletePastDays() async {
    final file = await _getSettingsFile();

    if (await file.exists()) {
      final jsonContent = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonContent);

      final now = DateTime.now();

      data.removeWhere((dateKey, tasksJson) {
        List<Task> tasks = (tasksJson as List).map((json) => Task.fromJson(json)).toList();

        tasks.sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));

        final lastTask = tasks.last;
        final endOfLastTask = DateTime(
          now.year,
          now.month,
          now.day,
          lastTask.startTime.hour + lastTask.duration.inHours,
          lastTask.startTime.minute,
        );

        if (endOfLastTask.isBefore(now) || endOfLastTask.isAtSameMomentAs(now)) {
          return true;
        }
        return false;
      });

      await file.writeAsString(json.encode(data));
    }
  }

  Future<void> saveTasksForDay(String date, List<Task> tasks) async {
    final settings = await _loadSettings();
    settings[date] = tasks.map((task) => task.toJson()).toList();
    await _saveSettings(settings);
  }
}