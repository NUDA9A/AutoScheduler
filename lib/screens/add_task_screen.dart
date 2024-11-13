import 'package:flutter/material.dart';

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  DateTime? _deadline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить задачу'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Название задачи'),
            ),
            TextField(
              controller: _durationController,
              decoration: InputDecoration(labelText: 'Время на выполнение (часы)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  _deadline == null
                      ? 'Выберите дедлайн'
                      : 'Дедлайн: ${_deadline!.toLocal()}'.split(' ')[0],
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _deadline = picked;
                      });
                    }
                  },
                  child: Text('Выбрать дату'),
                ),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _addTask,
              child: Text('Добавить задачу'),
            ),
          ],
        ),
      ),
    );
  }

  void _addTask() {
    final title = _titleController.text;
    final duration = int.tryParse(_durationController.text) ?? 0;

    if (title.isEmpty || duration <= 0 || _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    Navigator.of(context).pop({
      'title': title,
      'duration': duration,
      'deadline': _deadline,
    });
  }
}