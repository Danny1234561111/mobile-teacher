// pages/edit_student_page.dart
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/student_service.dart';

class EditStudentPage extends StatefulWidget {
  final Student student;
  final Function(Student) onUpdate;

  const EditStudentPage({
    required this.student,
    required this.onUpdate,
    Key? key,
  }) : super(key: key);

  @override
  _EditStudentPageState createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  // Статусы (можно редактировать)
  late String _selectedStatus;
  late String _selectedApplicationStatus;
  late String _selectedContactStatus;
  late String _selectedContactType;
  late bool _consentStatus;
  late String _priorContact;
  
  bool _isLoading = false;
  final StudentService _studentService = StudentService();

  // Опции для выпадающих списков
  final List<String> _statusOptions = ['active', 'inactive', 'enrolled', 'withdrawn'];
  final List<String> _applicationStatusOptions = ['pending', 'accepted', 'rejected', 'paid'];
  final List<String> _contactStatusOptions = [
    'new', 
    'met', 
    'interested', 
    'original_submitted', 
    'waiting_original', 
    'not_interested'
  ];
  final List<String> _contactTypeOptions = ['call', 'message', 'meeting'];
  final List<String> _priorContactOptions = ['telegram', 'vk', 'messages', 'phone'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.fullName);
    _phoneController = TextEditingController(text: widget.student.phone);
    
    _selectedStatus = widget.student.status ?? 'active';
    _selectedApplicationStatus = widget.student.applicationStatus ?? 'pending';
    _selectedContactStatus = widget.student.contactStatus ?? 'new';
    _selectedContactType = widget.student.contactType ?? 'call';
    _consentStatus = widget.student.consentStatus ?? false;
    _priorContact = widget.student.priorContact ?? 'telegram';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Только те поля, которые можно редактировать
      final updates = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'status': _selectedStatus,
        'application_status': _selectedApplicationStatus,
        'contact_status': _selectedContactStatus,
        'contact_type': _selectedContactType,
        'consent_status': _consentStatus,
        'prior_contact': _priorContact,
      };

      print('🔄 Отправка обновлений: $updates');

      final updatedStudent = await _studentService.updateStudent(
        widget.student.id, 
        updates
      );
      
      widget.onUpdate(updatedStudent);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Данные сохранены'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: Text(
              'Сохранить',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Академическая информация (ТОЛЬКО ДЛЯ ПРОСМОТРА) =====
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Академическая информация',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _buildReadOnlyRow(
                            'ID студента', 
                            widget.student.russianStudentId.toString(),
                            Icons.badge,
                          ),
                          const Divider(height: 16),
                          
                          _buildReadOnlyRow(
                            'Направление', 
                            widget.student.departmentName ?? 'Не указано',
                            Icons.school,
                          ),
                          const Divider(height: 16),
                          
                          _buildReadOnlyRow(
                            'Специальность', 
                            widget.student.specialityName ?? 'Не указано',
                            Icons.work,
                          ),
                          const Divider(height: 16),
                          
                          _buildReadOnlyRow(
                            'Профиль', 
                            widget.student.profileName ?? 'Не указано',
                            Icons.person_outline,
                          ),
                          const Divider(height: 16),
                          
                          _buildReadOnlyRow(
                            'Уровень обучения', 
                            widget.student.studyLevel ?? 'Не указано',
                            Icons.school,
                          ),
                          const Divider(height: 16),
                          
                          _buildReadOnlyRow(
                            'Форма обучения', 
                            widget.student.studyForm ?? 'Не указано',
                            Icons.date_range,
                          ),
                          const Divider(height: 16),
                          
                          _buildReadOnlyRow(
                            'Основа обучения', 
                            widget.student.studyBasis ?? 'Не указано',
                            Icons.attach_money,
                          ),
                          const Divider(height: 16),
                          
                          _buildReadOnlyRow(
                            'Баллы', 
                            widget.student.totalScore?.toString() ?? 'Не указано',
                            Icons.score,
                            valueColor: _getScoreColor(widget.student.totalScore),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // ===== Основная информация (МОЖНО РЕДАКТИРОВАТЬ) =====
                    const Text(
                      'Основная информация',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'ФИО *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите ФИО';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Телефон *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        hintText: '+79991234567',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите телефон';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _priorContact,
                      decoration: const InputDecoration(
                        labelText: 'Приоритетный контакт',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.star),
                      ),
                      items: _priorContactOptions.map((contact) {
                        return DropdownMenuItem(
                          value: contact,
                          child: Text(
                            contact == 'telegram' ? 'Telegram' :
                            contact == 'vk' ? 'ВКонтакте' :
                            contact == 'messages' ? 'Сообщения' : 'Звонок',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _priorContact = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // ===== Статусы (МОЖНО РЕДАКТИРОВАТЬ) =====
                    const Text(
                      'Статусы',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Общий статус',
                        border: OutlineInputBorder(),
                      ),
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_getStatusDisplayName(status)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedApplicationStatus,
                      decoration: const InputDecoration(
                        labelText: 'Статус заявления',
                        border: OutlineInputBorder(),
                      ),
                      items: _applicationStatusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getApplicationStatusColor(status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_getApplicationStatusDisplayName(status)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedApplicationStatus = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedContactStatus,
                      decoration: const InputDecoration(
                        labelText: 'Статус контакта',
                        border: OutlineInputBorder(),
                      ),
                      items: _contactStatusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getContactStatusColor(status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_getContactStatusDisplayName(status)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedContactStatus = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedContactType,
                      decoration: const InputDecoration(
                        labelText: 'Тип контакта',
                        border: OutlineInputBorder(),
                      ),
                      items: _contactTypeOptions.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type == 'call' ? 'Звонок' :
                            type == 'message' ? 'Сообщение' : 'Встреча',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedContactType = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SwitchListTile(
                        title: const Text('Согласие на зачисление'),
                        value: _consentStatus,
                        onChanged: (value) {
                          setState(() {
                            _consentStatus = value;
                          });
                        },
                        secondary: Icon(
                          _consentStatus ? Icons.check_circle : Icons.cancel,
                          color: _consentStatus ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  // Цвета для статусов
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'enrolled':
        return Colors.blue;
      case 'withdrawn':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'active':
        return 'Активный';
      case 'inactive':
        return 'Неактивный';
      case 'enrolled':
        return 'Зачислен';
      case 'withdrawn':
        return 'Отчислен';
      default:
        return status;
    }
  }

  Color _getApplicationStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'paid':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getApplicationStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Ожидает';
      case 'accepted':
        return 'Принято';
      case 'rejected':
        return 'Отклонено';
      case 'paid':
        return 'Оплачено';
      default:
        return status;
    }
  }

  Color _getContactStatusColor(String? status) {
    switch (status) {
      case 'new':
        return Colors.grey;
      case 'met':
        return Colors.green;
      case 'interested':
        return Colors.lightGreen;
      case 'original_submitted':
        return Colors.blue;
      case 'waiting_original':
        return Colors.orange;
      case 'not_interested':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getContactStatusDisplayName(String status) {
    switch (status) {
      case 'new':
        return 'Новый';
      case 'met':
        return 'Был на встрече';
      case 'interested':
        return 'Заинтересован';
      case 'original_submitted':
        return 'Подан оригинал';
      case 'waiting_original':
        return 'Ждем оригинал';
      case 'not_interested':
        return 'Не заинтересован';
      default:
        return status;
    }
  }

  Color _getScoreColor(int? score) {
    if (score == null) return Colors.grey;
    if (score >= 250) return Colors.green;
    if (score >= 200) return Colors.lightGreen;
    if (score >= 150) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}