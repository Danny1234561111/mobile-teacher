// pages/add_communication_page.dart
import 'package:flutter/material.dart';

// Цвета из Figma
const Color accentBlue = Color(0xFF0088FF);
const Color borderColor = Color(0xFFC5C6D0);
const Color successGreen = Color(0xFF34C759);
const Color errorRed = Color(0xFFFF383C);
const Color warningOrange = Color(0xFFFF9800);
const Color neutralGray = Color(0xFFA0A0A0);

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

  String _getCommunicationTypeName(String type) {
    switch (type) {
      case 'call': return 'Звонок';
      case 'meeting': return 'Встреча';
      case 'email': return 'Email';
      case 'message': return 'Сообщение';
      default: return type;
    }
  }

  String _getStatusName(String status) {
    switch (status) {
      case 'completed': return 'Завершено';
      case 'planned': return 'Запланировано';
      case 'cancelled': return 'Отменено';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF5FD),
      appBar: AppBar(
        title: const Text(
          'Добавить коммуникацию',
          style: TextStyle(color: accentBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFECF5FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accentBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Студент (простой текст, без карточки)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Студент: ',
                      style: TextStyle(fontSize: 14, color: neutralGray),
                    ),
                    Expanded(
                      child: Text(
                        widget.studentName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(color: borderColor),
              
              const SizedBox(height: 8),

              // Тип коммуникации
              DropdownButtonFormField<String>(
                value: _communicationType,
                decoration: const InputDecoration(
                  labelText: 'Тип коммуникации *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                          color: accentBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(_getCommunicationTypeName(type)),
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

              // Статус
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Статус *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: status == 'completed' ? successGreen :
                                   status == 'planned' ? accentBlue : errorRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_getStatusName(status)),
                      ],
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

              // Дата и время
              InkWell(
                onTap: _selectDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Дата и время *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_dateTime.day}.${_dateTime.month}.${_dateTime.year} ${_dateTime.hour.toString().padLeft(2, '0')}:${_dateTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Длительность
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

              // Заметки
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Заметки *',
                  border: OutlineInputBorder(),
                  hintText: 'Опишите детали разговора...',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите заметки о коммуникации';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Кнопка сохранения
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: neutralGray,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: borderColor),
                ),
                child: const Text('Отмена', style: TextStyle(fontSize: 16)),
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