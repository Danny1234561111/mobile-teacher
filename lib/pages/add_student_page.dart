import 'package:flutter/material.dart';
import '../../models/student.dart';

class AddStudentPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const AddStudentPage({required this.onAdd, Key? key}) : super(key: key);

  @override
  _AddStudentPageState createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _russianIdController = TextEditingController();
  final _additionalContactController = TextEditingController();
  final _directionController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _priorityController = TextEditingController();
  
  List<String> _additionalContacts = [];
  DateTime? _selectedDate;

  void _addAdditionalContact() {
    if (_additionalContactController.text.isNotEmpty) {
      setState(() {
        _additionalContacts.add(_additionalContactController.text);
        _additionalContactController.clear();
      });
    }
  }

  void _removeAdditionalContact(int index) {
    setState(() {
      _additionalContacts.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить студента'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _russianIdController,
                decoration: InputDecoration(
                  labelText: 'Российский ID абитуриента*',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: '1234567890',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите российский ID абитуриента';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'ФИО студента*',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите ФИО студента';
                  }
                  if (value.length < 2) {
                    return 'ФИО слишком короткое';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _selectedDate != null
                          ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                          : '',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Дата рождения',
                      prefixIcon: const Icon(Icons.cake),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: 'student@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Введите корректный email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Номер телефона*',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: '+79991234567',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер телефона';
                  }
                  if (!RegExp(r'^[\d\s\-\+\(\)]{10,}$').hasMatch(value)) {
                    return 'Введите корректный номер телефона';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _directionController,
                decoration: InputDecoration(
                  labelText: 'Направление',
                  prefixIcon: const Icon(Icons.school),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _specialtyController,
                decoration: InputDecoration(
                  labelText: 'Специальность',
                  prefixIcon: const Icon(Icons.work),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _priorityController,
                decoration: InputDecoration(
                  labelText: 'Место по приоритетам',
                  prefixIcon: const Icon(Icons.format_list_numbered),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Дополнительные контакты',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _additionalContactController,
                              decoration: const InputDecoration(
                                labelText: 'Telegram, VK и т.д.',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _addAdditionalContact,
                            child: const Icon(Icons.add),
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_additionalContacts.isNotEmpty) ...[
                        const Text('Добавленные контакты:',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: List.generate(
                            _additionalContacts.length,
                            (index) => Chip(
                              label: Text(_additionalContacts[index]),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _removeAdditionalContact(index),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Форматируем дату рождения для API
                    String? dateOfBirth;
                    if (_selectedDate != null) {
                      dateOfBirth = _selectedDate!.toIso8601String().split('T')[0];
                    }
                    
                    // Форматируем номер телефона
                    String phone = _phoneController.text.trim();
                    if (!phone.startsWith('+')) {
                      if (phone.startsWith('8')) {
                        phone = '+7${phone.substring(1)}';
                      } else if (phone.startsWith('7')) {
                        phone = '+$phone';
                      }
                    }
                    
                    // Подготавливаем данные для отправки
                    final studentData = {
                      'russian_student_id': _russianIdController.text.trim(),
                      'full_name': _nameController.text.trim(),
                      'phone': phone,
                      'email': _emailController.text.trim().isNotEmpty
                          ? _emailController.text.trim()
                          : null,
                      'date_of_birth': dateOfBirth,
                      'direction': _directionController.text.trim().isNotEmpty
                          ? _directionController.text.trim()
                          : null,
                      'specialty': _specialtyController.text.trim().isNotEmpty
                          ? _specialtyController.text.trim()
                          : null,
                      'priority_place': _priorityController.text.trim().isNotEmpty
                          ? int.tryParse(_priorityController.text.trim())
                          : null,
                      'additional_contacts': _additionalContacts,
                      'status': 'active',
                    };
                    
                    // Удаляем null значения
                    studentData.removeWhere((key, value) => value == null);
                    
                    try {
                      await widget.onAdd(studentData);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'Добавить студента',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text('Отмена'),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _russianIdController.dispose();
    _directionController.dispose();
    _specialtyController.dispose();
    _priorityController.dispose();
    _additionalContactController.dispose();
    super.dispose();
  }
}