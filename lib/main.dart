import 'dart:async';

import 'package:autoscheduler/screens/time_setup_screen.dart';
import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/calendar_screen.dart';
import 'settings_service.dart';

void main() => runApp(const AutoSchedulerApp());

class AutoSchedulerApp extends StatefulWidget {
  const AutoSchedulerApp({super.key});

  @override
  _AutoSchedulerAppState createState() => _AutoSchedulerAppState();
}

class _AutoSchedulerAppState extends State<AutoSchedulerApp> {
  bool isFirstLaunch = true;
  TimeOfDay? wakeUpTime;
  TimeOfDay? sleepTime;
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(hours: 1), (timer) async {
      await _settingsService.deletePastDays();
    });
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    isFirstLaunch = await _settingsService.isFirstLaunch();

    if (!isFirstLaunch) {
      final times = await _settingsService.loadWakeUpAndSleepTime();
      setState(() {
        wakeUpTime = times["wakeUpTime"];
        sleepTime = times["sleepTime"];
      });
    }
    setState(() {});
  }

  Future<void> _saveTimeSettings(TimeOfDay wakeUp, TimeOfDay sleep) async {
    await _settingsService.setFirstLaunchCompleted();
    await _settingsService.saveWakeUpAndSleepTime(wakeUp, sleep);

    setState(() {
      wakeUpTime = wakeUp;
      sleepTime = sleep;
      isFirstLaunch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: isFirstLaunch
          ? WelcomeScreen(
        onContinue: () {
          setState(() {
            isFirstLaunch = false;
          });
        },
      )
          : (wakeUpTime == null || sleepTime == null)
          ? TimeSetupScreen(
        onSave: (wakeUp, sleep) {
          _saveTimeSettings(wakeUp, sleep);
        },
      )
          : CalendarScreen(
        wakeUpTime: wakeUpTime!,
        sleepTime: sleepTime!,
      ),
    );
  }
}