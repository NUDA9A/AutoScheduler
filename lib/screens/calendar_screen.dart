import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import './add_task_screen.dart';
import '../settings_service.dart';
import '../task.dart';

class CalendarScreen extends StatelessWidget {
  final TimeOfDay wakeUpTime;
  final TimeOfDay sleepTime;
  final SettingsService _settingsService = SettingsService();

  CalendarScreen({super.key, required this.wakeUpTime, required this.sleepTime});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        itemBuilder: (context, index) {
          DateTime currentDate = DateTime.now().add(Duration(days: index));
          String dayOfWeek = DateFormat('E').format(currentDate);
          String formattedDate = DateFormat('dd.MM').format(currentDate);

          return Scaffold(
            appBar: AppBar(
              title: Text('$dayOfWeek, $formattedDate'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => AddTaskScreen()),
                    );

                    if (result != null) {
                      final title = result['title'];
                      final duration = result['duration'];
                      final deadline = result['deadline'];
                      _settingsService.addTaskAutomatically(title, duration, deadline);
                    }
                  },
                ),
              ],
            ),
            body: DailySchedule(
              date: currentDate,
              wakeUpTime: wakeUpTime,
              sleepTime: sleepTime,
            ),
          );
        },
      ),
    );
  }
}

class DailySchedule extends StatefulWidget {
  final DateTime date;
  final TimeOfDay wakeUpTime;
  final TimeOfDay sleepTime;

  DailySchedule({required this.date, required this.wakeUpTime, required this.sleepTime});

  @override
  _DailyScheduleState createState() => _DailyScheduleState();
}

class _DailyScheduleState extends State<DailySchedule> {
  final double hourHeight = 100.0;
  List<Task> tasks = [];
  final SettingsService settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _initializeTasks();
  }

  Future<void> _initializeTasks() async {
    final dateKey = widget.date.toIso8601String().substring(0, 10);
    final loadedTasks = await settingsService.loadTasksForDay(dateKey);

    setState(() {
      tasks = loadedTasks.isNotEmpty ? loadedTasks : _defaultTasks();
    });
  }

  List<Task> _defaultTasks() {
    return [
      Task(title: 'Подъем', startTime: widget.wakeUpTime, duration: Duration(hours: 1)),
      Task(title: 'Отход ко сну', startTime: widget.sleepTime, duration: Duration(hours: 1)),
    ];
  }

  void _saveTasks() {
    final dateKey = widget.date.toIso8601String().substring(0, 10);
    settingsService.saveTasksForDay(dateKey, tasks);
  }

  void _updateTaskTime(Task task, double dy) {
    final newTop = _calculateTaskTopPosition(task.startTime) + dy;
    final newStartTime = _getTimeFromPosition(newTop);

    setState(() {
      task.startTime = newStartTime;
    });
    _saveTasks();
  }

  double _calculateTaskTopPosition(TimeOfDay time) {
    final startHour = widget.wakeUpTime.hour;
    return ((time.hour - startHour) * hourHeight) + (time.minute / 60 * hourHeight);
  }

  TimeOfDay _getTimeFromPosition(double topPosition) {
    final startHour = widget.wakeUpTime.hour;
    int hour = startHour + (topPosition / hourHeight).floor();
    int minute = ((topPosition % hourHeight) / hourHeight * 60).round();
    return TimeOfDay(hour: hour % 24, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final startHour = widget.wakeUpTime.hour;
    final endHour = widget.sleepTime.hour + 1;
    final itemsCount = (endHour >= startHour) ? endHour - startHour : 24 - startHour + endHour;

    return ListView.builder(
      itemCount: itemsCount,
      itemBuilder: (context, index) {
        final displayHour = (startHour + index) % 24;
        final task = tasks.firstWhere(
              (task) => task.startTime.hour == displayHour,
          orElse: () => Task(title: '', startTime: TimeOfDay(hour: displayHour, minute: 0), duration: Duration(hours: 1)),
        );

        return Container(
          height: hourHeight,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 16),
              Text(
                '${displayHour.toString().padLeft(2, '0')}:00',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              if (task.title.isNotEmpty) // Если это задача, добавляем ее с поддержкой перетаскивания
                Expanded(
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      _updateTaskTime(task, details.delta.dy);
                    },
                    child: Container(
                      height: hourHeight,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text(task.title)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}