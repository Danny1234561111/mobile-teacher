// pages/add_communication_page.dart
import 'package:flutter/material.dart';
import '../models/communication.dart';

class AddCommunicationPage extends StatefulWidget {
  final int studentId;
  final String studentName;
  final Function(Map<String, dynamic>) onAdd;

  const AddCommunicationPage({
    required this.studentId,
    required this.studentName,
    required this.onAdd,
    Key? key,
  }) : super(key: key);

  @override
  _AddCommunicationPageState createState() => _AddCommunicationPageState();
}

class _AddCommunicationPageState extends State<AddCommunicationPage> {
  final _formKey = GlobalKey<FormState>();
  String _communicationType = 'call';
  String _status = 'completed';
  DateTime _dateTime = DateTime.now();
  int? _durationMinutes;
  final _notesController = TextEditingController();

  final List<String> _communicationTypes = ['call', 'meeting', 'email', 'message'];
  final List<String> _statuses = ['completed', 'planned', 'cancelled'];

  Future<void> _selectDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dateTime),
      );
      
      if (time != null) {
        setState(() {
          _dateTime = DateTime(
            date.year, date.month, date.day,
            time.hour, time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить коммуникацию'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // pages/add_communication_page.dart (продолжение)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Студент',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.studentName),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _communicationType,
                decoration: const InputDecoration(
                  labelText: 'Тип коммуникации*',
                  border: OutlineInputBorder(),
                ),
                items: _communicationTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          type == 'call' ? Icons.call :
                          type == 'meeting' ? Icons.group :
                          type == 'email' ? Icons.email : Icons.message,
                          size: 20,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type == 'call' ? 'Звонок' :
                          type == 'meeting' ? 'Встреча' :
                          type == 'email' ? 'Email' : 'Сообщение',
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _communicationType = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Статус*',
                  border: OutlineInputBorder(),
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status == 'completed' ? 'Завершено' :
                      status == 'planned' ? 'Запланировано' : 'Отменено',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              InkWell(
                onTap: _selectDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Дата и время*',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_dateTime.day}.${_dateTime.month}.${_dateTime.year} ${_dateTime.hour.toString().padLeft(2, '0')}:${_dateTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Длительность (минуты)',
                  border: OutlineInputBorder(),
                  hintText: 'Например: 15',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _durationMinutes = value.isNotEmpty ? int.tryParse(value) : null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Заметки*',
                  border: OutlineInputBorder(),
                  hintText: 'Опишите детали разговора...',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите заметки о коммуникации';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final data = {
                      'communication_type': _communicationType,
                      'status': _status,
                      'date_time': _dateTime.toIso8601String(),
                      if (_durationMinutes != null) 'duration_minutes': _durationMinutes,
                      'notes': _notesController.text,
                    };
                    
                    widget.onAdd(data);
                    Navigator.pop(context);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text('Сохранить', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 10),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text('Отмена'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
       