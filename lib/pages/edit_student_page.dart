// pages/edit_student_page.dart
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/student_service.dart';

// Цвета из Figma (единый стиль)
const Color accentBlue = Color(0xFF0088FF);
const Color borderColor = Color(0xFFC5C6D0);
const Color successGreen = Color(0xFF34C759);
const Color errorRed = Color(0xFFFF383C);
const Color warningOrange = Color(0xFFFF9800);
const Color neutralGray = Color(0xFFA0A0A0);

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
  
  // Дополнительные контакты
  late TextEditingController _telegramController;
  late TextEditingController _urlController;
  late TextEditingController _otherController;
  late Map<String, String> _additionalContacts;
  
  // Статусы
  late String _selectedStatus;
  late String _selectedApplicationStatus;
  late String _selectedContactStatus;
  late String _selectedContactType;
  late bool _consentStatus;
  late String _priorContact;
  
  // Новые статусы (добавленные как на веб-сайте)
  late String _selectedMeetingStatus;
  late String _selectedCallStatus;
  late String _selectedDecisionStatus;
  late String _selectedDocumentsStatus;
  
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
  
  // ИСПРАВЛЕНО: используем английские значения для dropdown
  final List<String> _priorContactOptions = ['', 'TELEGRAM', 'MESSAGES', 'PHONE', 'URL'];
  
  // Новые опции для статусов
  final List<String> _meetingStatusOptions = ['met', 'not_met'];
  final List<String> _callStatusOptions = ['reached', 'not_reached'];
  final List<String> _decisionStatusOptions = ['decided', 'thinking'];
  final List<String> _documentsStatusOptions = [
    'not_submitted', 
    'original_submitted', 
    'waiting_original', 
    'enrolled'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.fullName);
    _phoneController = TextEditingController(text: widget.student.phone);
    
    // Инициализация дополнительных контактов
    _additionalContacts = Map.from(widget.student.additionalContacts ?? {});
    _telegramController = TextEditingController(text: _additionalContacts['telegram'] ?? '');
    _urlController = TextEditingController(text: _additionalContacts['url'] ?? '');
    _otherController = TextEditingController(text: _additionalContacts['other'] ?? '');
    
    _selectedStatus = widget.student.status ?? 'active';
    _selectedApplicationStatus = widget.student.applicationStatus ?? 'pending';
    _selectedContactStatus = widget.student.contactStatus ?? 'new';
    _selectedContactType = widget.student.contactType ?? 'call';
    _consentStatus = widget.student.consentStatus ?? false;
    
    // Инициализация новых статусов
    _selectedMeetingStatus = widget.student.meetingStatus?.toLowerCase() ?? 'not_met';
    _selectedCallStatus = widget.student.callStatus?.toLowerCase() ?? 'not_reached';
    _selectedDecisionStatus = widget.student.decisionStatus?.toLowerCase() ?? 'thinking';
    _selectedDocumentsStatus = widget.student.documentsStatus?.toLowerCase() ?? 'not_submitted';
    
    // ИСПРАВЛЕНО: конвертируем в английские значения для dropdown
    _priorContact = _convertToEnglishPriorContact(widget.student.priorContact);
  }

  String _convertToEnglishPriorContact(String? value) {
    if (value == null || value.isEmpty) return '';
    
    final lowerValue = value.toLowerCase();
    
    if (lowerValue == 'telegram' || lowerValue == 'телеграмм') {
      return 'TELEGRAM';
    }
    if (lowerValue == 'messages' || lowerValue == 'sms' || lowerValue == 'просто сообщения') {
      return 'MESSAGES';
    }
    if (lowerValue == 'phone' || lowerValue == 'call' || lowerValue == 'звонок') {
      return 'PHONE';
    }
    if (lowerValue == 'url' || lowerValue == 'ссылка') {
      return 'URL';
    }
    
    return '';
  }

  String _getPriorContactDisplayName(String? priorContact) {
    if (priorContact == null || priorContact.isEmpty) return 'Не указан';
    
    switch (priorContact) {
      case 'TELEGRAM': return 'Telegram';
      case 'MESSAGES': return 'SMS';
      case 'PHONE': return 'Звонок';
      case 'URL': return 'Ссылка';
      default: return priorContact;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'active': return 'Активный';
      case 'inactive': return 'Неактивный';
      case 'enrolled': return 'Зачислен';
      case 'withdrawn': return 'Отчислен';
      default: return status;
    }
  }

  String _getApplicationStatusDisplayName(String status) {
    switch (status) {
      case 'pending': return 'Ожидает';
      case 'accepted': return 'Принято';
      case 'rejected': return 'Отклонено';
      case 'paid': return 'Оплачено';
      default: return status;
    }
  }

  String _getContactStatusDisplayName(String status) {
    switch (status) {
      case 'new': return 'Новый';
      case 'met': return 'Был на встрече';
      case 'interested': return 'Заинтересован';
      case 'original_submitted': return 'Подан оригинал';
      case 'waiting_original': return 'Ждем оригинал';
      case 'not_interested': return 'Не заинтересован';
      default: return status;
    }
  }

  String _getMeetingStatusDisplayName(String status) {
    switch (status) {
      case 'met': return 'Был на сборе';
      case 'not_met': return 'Не был на сборе';
      default: return status;
    }
  }

  String _getCallStatusDisplayName(String status) {
    switch (status) {
      case 'reached': return 'Дозвонились';
      case 'not_reached': return 'Не дозвонились';
      default: return status;
    }
  }

  String _getDecisionStatusDisplayName(String status) {
    switch (status) {
      case 'decided': return 'Решил поступать';
      case 'thinking': return 'Думает';
      default: return status;
    }
  }

  String _getDocumentsStatusDisplayName(String status) {
    switch (status) {
      case 'original_submitted': return 'Подан оригинал';
      case 'waiting_original': return 'Ждем оригинал';
      case 'enrolled': return 'Зачислен';
      case 'not_submitted': return 'Нет заявл.';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return successGreen;
      case 'inactive': return errorRed;
      case 'enrolled': return accentBlue;
      case 'withdrawn': return warningOrange;
      default: return neutralGray;
    }
  }

  Color _getApplicationStatusColor(String status) {
    switch (status) {
      case 'pending': return warningOrange;
      case 'accepted': return successGreen;
      case 'rejected': return errorRed;
      case 'paid': return accentBlue;
      default: return neutralGray;
    }
  }

  Color _getMeetingStatusColor(String status) {
    switch (status) {
      case 'met': return successGreen;
      case 'not_met': return errorRed;
      default: return neutralGray;
    }
  }

  Color _getCallStatusColor(String status) {
    switch (status) {
      case 'reached': return successGreen;
      case 'not_reached': return errorRed;
      default: return neutralGray;
    }
  }

  Color _getDecisionStatusColor(String status) {
    switch (status) {
      case 'decided': return successGreen;
      case 'thinking': return warningOrange;
      default: return neutralGray;
    }
  }

  Color _getDocumentsStatusColor(String status) {
    switch (status) {
      case 'original_submitted': return successGreen;
      case 'waiting_original': return warningOrange;
      case 'enrolled': return accentBlue;
      default: return neutralGray;
    }
  }

  Future<void> _saveChanges() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    // Собираем дополнительные контакты
    final Map<String, String> additionalContacts = {};
    if (_telegramController.text.trim().isNotEmpty) {
      additionalContacts['telegram'] = _telegramController.text.trim();
    }
    if (_urlController.text.trim().isNotEmpty) {
      additionalContacts['url'] = _urlController.text.trim();
    }
    if (_otherController.text.trim().isNotEmpty) {
      additionalContacts['other'] = _otherController.text.trim();
    }
    
    // Функция конвертации английского значения в русское для API
    String? _convertToRussianPriorContact(String? value) {
      if (value == null || value.isEmpty) return null;
      
      switch (value) {
        case 'TELEGRAM':
          return 'телеграмм';
        case 'MESSAGES':
          return 'просто сообщения';
        case 'PHONE':
          return 'звонок';
        case 'URL':
          return 'ссылка';
        default:
          return null;
      }
    }
    
    // ИСПРАВЛЕНО: конвертируем английское значение в русское для отправки
    final String? priorContactValue = _convertToRussianPriorContact(_priorContact);
    
    final updates = {
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'status': _selectedStatus,
      'application_status': _selectedApplicationStatus,
      'contact_status': _selectedContactStatus,
      'contact_type': _selectedContactType,
      'consent_status': _consentStatus,
      'meeting_status': _selectedMeetingStatus.toUpperCase(),
      'call_status': _selectedCallStatus.toUpperCase(),
      'decision_status': _selectedDecisionStatus.toUpperCase(),
      'documents_status': _selectedDocumentsStatus.toUpperCase(),
      if (priorContactValue != null) 'prior_contact': priorContactValue,
      if (additionalContacts.isNotEmpty) 'additional_contacts': additionalContacts,
    };

    print('🔄 Отправка обновлений: $updates');
    print('📝 Приоритетный контакт (русский): $priorContactValue');

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
          backgroundColor: successGreen,
        ),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: errorRed,
        ),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF5FD),
      appBar: AppBar(
        title: const Text(
          'Редактирование',
          style: TextStyle(color: accentBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFECF5FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accentBlue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: Text(
              'Сохранить',
              style: TextStyle(
                color: _isLoading ? neutralGray : accentBlue,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Академическая информация (ТОЛЬКО ДЛЯ ПРОСМОТРА) =====
                    _buildInfoCard(
                      title: 'Академическая информация',
                      icon: Icons.school,
                      children: [
                        _buildReadOnlyRow(
                          'ID студента', 
                          widget.student.russianStudentId?.toString() ?? '—',
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
                    
                    const SizedBox(height: 16),
                    
                    // ===== Основная информация =====
                    _buildEditCard(
                      title: 'Основная информация',
                      icon: Icons.person,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'ФИО *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person, color: accentBlue),
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
                            prefixIcon: Icon(Icons.phone, color: accentBlue),
                            hintText: '+79991234567',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите телефон';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ===== Дополнительные контакты =====
                    _buildEditCard(
                      title: 'Дополнительные контакты',
                      icon: Icons.contact_phone,
                      subtitle: 'Эти контакты будут доступны в списке способов связи',
                      children: [
                        TextFormField(
                          controller: _telegramController,
                          decoration: const InputDecoration(
                            labelText: 'Telegram',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.telegram, color: Color(0xFF26A5E4)),
                            hintText: '@username или номер телефона',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'Ссылка (URL)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.link, color: Colors.purple),
                            hintText: 'https://...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _otherController,
                          decoration: const InputDecoration(
                            labelText: 'Другой контакт',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.contact_phone, color: warningOrange),
                            hintText: 'Другой способ связи',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ===== Приоритетный контакт =====
                    _buildEditCard(
                      title: 'Приоритетный контакт',
                      icon: Icons.star,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _priorContact.isEmpty ? null : _priorContact,
                          decoration: const InputDecoration(
                            labelText: 'Выберите приоритетный контакт',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.star, color: Colors.amber),
                          ),
                          hint: const Text('Не указан'),
                          items: _priorContactOptions.map((contact) {
                            if (contact.isEmpty) {
                              return const DropdownMenuItem(
                                value: '',
                                child: Text('Не указан'),
                              );
                            }
                            IconData icon;
                            Color color;
                            switch (contact) {
                              case 'TELEGRAM':
                                icon = Icons.telegram;
                                color = const Color(0xFF26A5E4);
                                break;
                              case 'MESSAGES':
                                icon = Icons.sms;
                                color = accentBlue;
                                break;
                              case 'PHONE':
                                icon = Icons.phone;
                                color = successGreen;
                                break;
                              case 'URL':
                                icon = Icons.link;
                                color = Colors.purple;
                                break;
                              default:
                                icon = Icons.help;
                                color = neutralGray;
                            }
                            return DropdownMenuItem(
                              value: contact,
                              child: Row(
                                children: [
                                  Icon(icon, size: 20, color: color),
                                  const SizedBox(width: 8),
                                  Text(_getPriorContactDisplayName(contact)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _priorContact = value ?? '';
                            });
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ===== Статусы (как на веб-сайте) =====
                    _buildEditCard(
                      title: 'Статусы абитуриента',
                      icon: Icons.track_changes,
                      children: [
                        // Статус документов
                        DropdownButtonFormField<String>(
                          value: _selectedDocumentsStatus,
                          decoration: const InputDecoration(
                            labelText: 'Статус документов',
                            border: OutlineInputBorder(),
                          ),
                          items: _documentsStatusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getDocumentsStatusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_getDocumentsStatusDisplayName(status)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDocumentsStatus = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Был на сборе
                        DropdownButtonFormField<String>(
                          value: _selectedMeetingStatus,
                          decoration: const InputDecoration(
                            labelText: 'Был на сборе',
                            border: OutlineInputBorder(),
                          ),
                          items: _meetingStatusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getMeetingStatusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_getMeetingStatusDisplayName(status)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMeetingStatus = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Дозвонились
                        DropdownButtonFormField<String>(
                          value: _selectedCallStatus,
                          decoration: const InputDecoration(
                            labelText: 'Дозвонились',
                            border: OutlineInputBorder(),
                          ),
                          items: _callStatusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getCallStatusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_getCallStatusDisplayName(status)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCallStatus = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Решение
                        DropdownButtonFormField<String>(
                          value: _selectedDecisionStatus,
                          decoration: const InputDecoration(
                            labelText: 'Решение',
                            border: OutlineInputBorder(),
                          ),
                          items: _decisionStatusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getDecisionStatusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_getDecisionStatusDisplayName(status)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDecisionStatus = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Общий статус
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
                        
                        // Статус контакта
                        DropdownButtonFormField<String>(
                          value: _selectedContactStatus,
                          decoration: const InputDecoration(
                            labelText: 'Статус контакта',
                            border: OutlineInputBorder(),
                          ),
                          items: _contactStatusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(_getContactStatusDisplayName(status)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedContactStatus = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Тип контакта
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
                        
                        // Согласие на зачисление
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
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
                              color: _consentStatus ? successGreen : errorRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildEditCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentBlue,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accentBlue),
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
          const Icon(Icons.lock_outline, size: 16, color: neutralGray),
        ],
      ),
    );
  }

  Color _getScoreColor(int? score) {
    if (score == null) return neutralGray;
    if (score >= 250) return successGreen;
    if (score >= 200) return Colors.lightGreen;
    if (score >= 150) return warningOrange;
    return errorRed;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    _urlController.dispose();
    _otherController.dispose();
    super.dispose();
  }
}