import 'package:flutter/material.dart';

class Task {
  String title;
  TimeOfDay startTime;
  Duration duration;

  Task({required this.title, required this.startTime, required this.duration});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'] ?? 'Unnamed Task',
      startTime: TimeOfDay(hour: json['hour'] ?? 0, minute: json['minute'] ?? 0),
      duration: Duration(minutes: json['duration'] ?? 60),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'hour': startTime.hour,
      'minute': startTime.minute,
      'duration': duration.inMinutes,
    };
  }
}