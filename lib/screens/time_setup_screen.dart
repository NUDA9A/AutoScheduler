import 'package:flutter/material.dart';

class TimeSetupScreen extends StatefulWidget {
  final Function(TimeOfDay wakeUpTime, TimeOfDay sleepTime) onSave;

  const TimeSetupScreen({super.key, required this.onSave});

  @override
  _TimeSetupScreenState createState() => _TimeSetupScreenState();
}

class _TimeSetupScreenState extends State<TimeSetupScreen> {
  TimeOfDay wakeUpTime = TimeOfDay(hour: 7, minute: 0);
  TimeOfDay sleepTime = TimeOfDay(hour: 22, minute: 0);

  Future<void> _selectWakeUpTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: wakeUpTime,
    );
    if (picked != null && picked != wakeUpTime) {
      setState(() {
        wakeUpTime = _convertTo24HourFormat(picked);
      });
    }
  }

  Future<void> _selectSleepTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: sleepTime,
    );
    if (picked != null && picked != sleepTime) {
      setState(() {
        sleepTime = _convertTo24HourFormat(picked);
      });
    }
  }

  TimeOfDay _convertTo24HourFormat(TimeOfDay time) {
    int hour = time.hour;
    if (time.period == DayPeriod.pm && hour != 12) {
      hour += 12;
    } else if (time.period == DayPeriod.am && hour == 12) {
      hour = 0;
    }
    return TimeOfDay(hour: hour, minute: time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Настройка времени')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите время подъема и отхода ко сну',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            ListTile(
              title: Text('Время подъема'),
              subtitle: Text(wakeUpTime.format(context)),
              trailing: Icon(Icons.alarm),
              onTap: () => _selectWakeUpTime(context),
            ),
            ListTile(
              title: Text('Время отхода ко сну'),
              subtitle: Text(sleepTime.format(context)),
              trailing: Icon(Icons.bedtime),
              onTap: () => _selectSleepTime(context),
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(wakeUpTime, sleepTime);
                },
                child: Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}