// pages/add_communication_page.dart
import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../models/communication.dart';

const Color accentBlue = Color(0xFF0088FF);
const Color borderColor = Color(0xFFC5C6D0);
const Color successGreen = Color(0xFF34C759);
const Color errorRed = Color(0xFFFF383C);
const Color warningOrange = Color(0xFFFF9800);
const Color neutralGray = Color(0xFFA0A0A0);

class AddCommunicationPage extends StatefulWidget {
  final int studentId;
  final String studentName;
  final Communication? communication;
  final VoidCallback onSuccess;

  const AddCommunicationPage({
    required this.studentId,
    required this.studentName,
    this.communication,
    required this.onSuccess,
    Key? key,
  }) : super(key: key);

  @override
  _AddCommunicationPageState createState() => _AddCommunicationPageState();
}

class _AddCommunicationPageState extends State<AddCommunicationPage> {
  final _formKey = GlobalKey<FormState>();
  late String _communicationType;
  late String _status;
  late DateTime _dateTime;
  int? _durationMinutes;
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditMode = false;
  
  final StudentService _studentService = StudentService();

  final List<String> _communicationTypes = ['call', 'meeting', 'email', 'message'];
  final List<String> _statuses = ['completed', 'planned', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.communication != null;
    
    if (_isEditMode) {
      _communicationType = widget.communication!.communicationType;
      _status = widget.communication!.status;
      _dateTime = widget.communication!.dateTime ?? DateTime.now();
      _durationMinutes = widget.communication!.durationMinutes;
      _notesController.text = widget.communication!.notes;
    } else {
      _communicationType = 'call';
      _status = 'completed';
      _dateTime = DateTime.now();
      _durationMinutes = null;
    }
  }

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final data = {
      'communication_type': _communicationType,
      'status': _status,
      'date_time': _dateTime.toIso8601String(),
      if (_durationMinutes != null && _durationMinutes! > 0) 'duration_minutes': _durationMinutes,
      'notes': _notesController.text,
    };
    
    try {
      if (_isEditMode) {
        await _studentService.updateCommunication(widget.communication!.id, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Коммуникация обновлена'), backgroundColor: successGreen),
          );
        }
      } else {
        await _studentService.createCommunication(widget.studentId, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Коммуникация добавлена'), backgroundColor: successGreen),
          );
        }
      }
      widget.onSuccess();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: errorRed),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление'),
        content: const Text('Вы уверены, что хотите удалить эту коммуникацию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: errorRed)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _studentService.deleteCommunication(widget.communication!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Коммуникация удалена'), backgroundColor: successGreen),
          );
        }
        widget.onSuccess();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e'), backgroundColor: errorRed),
          );
        }
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
        title: Text(
          _isEditMode ? 'Редактировать коммуникацию' : 'Добавить коммуникацию',
          style: const TextStyle(color: accentBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFECF5FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accentBlue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete, color: errorRed),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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

                    DropdownButtonFormField<String>(
                      value: _communicationType,
                      decoration: const InputDecoration(
                        labelText: 'Тип коммуникации *',
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

                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Статус *',
                        border: OutlineInputBorder(),
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

                    TextFormField(
                      initialValue: _durationMinutes?.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Длительность (минуты)',
                        border: OutlineInputBorder(),
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
                        labelText: 'Заметки *',
                        border: OutlineInputBorder(),
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

                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isEditMode ? 'Сохранить изменения' : 'Добавить',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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